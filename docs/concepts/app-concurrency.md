# How the desktop application keeps work off the UI thread

*An explanation of the concurrency patterns used by the desktop application:
how saves are queued, how crash-recovery snapshots work, how a worker's reply is
recognised as stale, and the shape shared by the background caches. Written for
a contributor who is about to add a new background job or persisted setting.*

The rule behind all of it comes from `CLAUDE.md`: nothing that touches the disk,
the network, terrain, or propagation may block the egui frame. The UI thread
only captures cheap state, hands it to a worker, and polls a channel each frame.
Everything below is about doing that without applying a stale answer.

---

## 1. Stale replies: epoch, revision, generation

The open document has several counters (`NetworkDocumentState`,
`src/app/network_document.rs`). Every worker is handed the ones it needs and
sends them back with its reply; the UI thread compares them to the current
values before applying anything.

| Counter | Bumped when | A reply carrying an older value is... |
| --- | --- | --- |
| `epoch` | the document is replaced (New, Open, Recover) and when shutdown seals the document | ignored: it belongs to a document that no longer exists |
| `revision` | anything changes, including a save landing or a newly solved coverage selection | ignored if it is a "has this changed" assessment, so the check reruns |
| `authored_revision` | only a user edit | a **load or import** started before the edit is refused rather than overwriting it |

Loads also carry a `generation`. Choosing a second file supersedes the first
(`begin_load`) without changing the document's identity; the older worker's
cancel flag is set and its reply no longer matches. `NetworkLoadRequest` bundles
the three values; `accepts_load` is the single test.

Save ordering uses another token, the **write id**. It is allocated when a save
is *requested*, not when its worker runs, so two saves of the same file are
ordered by intent. Each worker writes under a global lock and records the
highest write id that reached each canonical path; a worker holding an older id
returns `Ok(false)` and writes nothing, which the UI reports as "a newer save
superseded this operation". On the document, `saved()` rejects a write id older
than the baseline already accepted, and only the newest *explicit* write id
(`latest_explicit_write_id`) may switch the document to a new file path
(`activate_save`), so an autosave to the previous file cannot undo a Save As.

## 2. The save queue

Settings files (window layout, map settings, Site Finder settings, cache
budgets, recent networks, and so on) go through `LatestConfigSave`
(`src/app/actions.rs`), a **coalescing** queue. There is one static queue per
file, so a slow write never delays an unrelated one.

- `schedule(save)` never blocks. It replaces whatever was pending, bumps a
  generation, and starts a worker thread only if none is running.
- The worker waits until the queue has been quiet for the queue's debounce
  (150 ms for the network recovery snapshot, terrain configuration and Best Unit
  palette; none for the rest), then runs only the newest pending closure. A
  closure whose generation was superseded is skipped.
- `flush_pending()` runs the pending closure *now*, on the calling thread, under
  the same write lock, and bumps the generation so the worker does not run it a
  second time.
- On shutdown, `flush_persistence_queues()` flushes every queue in turn from the
  shutdown worker while the event loop stays responsive.

Explicit saves of the project file are different: they are not coalesced. Each
runs on its own thread (which also hosts the native Save dialog), serialized by
`NETWORK_SAVE_LOCK` and ordered by write id as in section 1. Writes use the
shared atomic-write helper, so a crash leaves either the old or the new file.

## 3. Crash-recovery snapshots

Recovery records are separate from project files and never touch them
(`src/network_recovery.rs`, `src/app/document_save.rs`).

- **Where:** one `<document id>.json` per open document under the per-user local
  data directory, in `recovery/` (falling back to the system temp directory).
  The id is `<pid>-<time>-<counter>`; only ASCII letters, digits and `-` up to
  128 characters are accepted, which keeps an id from escaping the directory.
- **What:** `RecoveryRecord` version 1: the unsaved authored state, the last
  saved state (so a restored document still knows what is unsaved), the
  original project path and a capture time. Computed links are not stored.
- **When:** every frame `observe_document` compares the document's
  `(epoch, revision)` with the last one it examined. If different and no
  assessment is running, it captures the document (cheap, on the UI thread) and
  spawns a worker that decides whether the document differs from the saved
  baseline. Only one assessment runs at a time and only the latest revision's
  result is used. A dirty document queues a snapshot write on the 150 ms
  coalescing queue; a document identical to its baseline queues removal of its
  record instead, so a clean document leaves no record.
- **Validity:** a snapshot is validated (version, and that both states
  serialize) *before* the existing file is replaced, so an unreadable snapshot
  can never overwrite a good one.
- **The race it avoids:** all writes and deletes hold `RECOVERY_WRITER` and
  re-check a shared `RecoveryLifetime` (an `active` flag plus the newest
  `revision`) while holding it. A capture taken before the document was retired,
  or before a newer edit, therefore cannot recreate a record that was just
  deleted.
- **At startup:** after the first load completes, one worker reads every record,
  newest first. Unreadable, wrong-version, oversized (over 256 MiB), non-regular
  or mismatched-name files become warnings and are **left on disk**, never
  deleted. Records other than the current document's are offered for recovery.
  Recovering resolves referenced vector layers relative to the original project
  path on a worker; missing files remain relinkable errors.

### Save, shutdown, and discard lifecycle

- **New document:** `retire_recovery` clears `active` first, then queues the
  deletion under the writer lock; the document receives a fresh id and lifetime.
- **Explicit save success:** the baseline moves; the next assessment finds the
  document clean and removes the record.
- **Quit / update install:** `begin_document_shutdown` seals the document
  (epoch bump, imports canceled, UI edits stop), clears `active`, then on a
  worker flushes every persistence queue and deletes this document's record. A
  clean exit leaves none. If that fails, `active` is set again, the error is
  shown, and the application stays open with recovery working.

## 4. The background-cache pattern

Four per-frame lookups would otherwise be expensive on large data: the node
list order (`node_list`), pointer hit-testing over Site Finder cells
(`site_hover`), the Top 10 list (`site_rankings`), and cluster re-suppression
(`site_suppression`). They share one shape:

1. **A key** names exactly the inputs the result depends on, and only those. For
   the node list: the graph identity, `epoch`, document `revision`, topology
   revision, sort mode, and, only for modes that read them, the good-link
   threshold, terrain version, or Site Finder score generation. Floats are
   compared as bits so the key is `Eq`.
2. **Weak identities.** Keys hold `Weak` pointers to the shared inputs
   (terrain manager, result sets) and compare them with `ptr_eq`. A cache never
   keeps a replaced manager or a multi-million-row result set alive, and a
   reused address cannot be mistaken for the old object because the revision is
   compared as well.
3. **At most one worker and one pending request.** A new key supersedes the old
   request and cancels the running worker (a cancellation token, or an atomic
   whose value no longer equals the worker's revision). Dropping the active job
   cancels it.
4. **Cooperative cancellation.** The worker checks the token per row and before
   and after any uninterruptible step such as a sort, and returns `None` if it
   fired.
5. **Never blocks the frame.** The per-frame call returns the ready result or
   "pending", starts the worker on the rayon pool or a thread, and is woken
   (`Wake`) to repaint when the reply is available.
6. **Invalidate before in-place edits.** Code that edits a result set in place
   (for example streaming scan results) calls `invalidate()` first so a worker
   cannot publish a ranking of rows that have since changed.

Specifics: the Top 10 worker ranks with `top_site_results` and a limit of 10.
The hover index is a sorted array of `(resolution, q, r, ordinal)` entries
capped at 32 MiB (larger result sets skip the index and answer each query on a
worker by scanning); a pointer query costs one hex conversion per distinct
resolution, so queries run inline only up to 64 distinct resolutions. Where
cells overlap, the highest ordinal (drawn last) wins. Suppression re-runs
`apply_cluster_suppression` for new radius and jealousy values and returns
refreshed copies of the selected and shortlisted sites together with the new
result sets, tagged with the scan's `epoch` and `scan_version`.

## Where else to look

- **[Finding sites](site-finder.md)** — what is being ranked, hovered and
  re-suppressed.
- **[Files and interchange formats](../reference/files-and-formats.md)** — the
  project file the save path writes.
- **[`CONTRIBUTING.md`](../../CONTRIBUTING.md)** — conventions for new
  background work.
