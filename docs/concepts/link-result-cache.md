# Partial link results in network files

Saving a network records an optional **network_link_cache** in JSON or YAML.
It preserves what is known about each directed radio pair, including negative
results. You can save during a calculation or after canceling it and reopen
that partial evidence later.

| Recorded state | Meaning |
| --- | --- |
| `passing` | Evaluated with a finite budget and margin at or above the calculation cutoff. |
| `below_margin` | Evaluated with a finite budget, but its margin is below that cutoff. |
| `pruned` | Skipped by an optimistic free-space or radio-horizon gate; the reason is stored. No detailed budget is implied. |
| `unavailable` | Work lacked complete input data or produced a non-finite calculation. It will be retried. |
| No entry | Unknown: there is no retained evaluation or pruning evidence for this direction. |

The reverse direction has its own entry. A passing A → B result says nothing
about B → A. Missing graph edges never imply a failed calculation, a pruning
decision, or a completed whole-network solve.

## Reopening and refreshing

On open, RidgeCast compares the saved input identity with the current nodes,
radio parameters, frequency, ambient-noise configuration, land-cover settings,
propagation settings, calculation versions, and calculation cutoff. Matching
passing, below-margin, and pruned records are reused individually. Unknown and
unavailable directions are evaluated; already resolved paths skip measured-surface
planning where possible. Receiving a partial list never marks the rest complete.

Evaluated records retain directional path loss, received level, margin, and model
provenance. Receiver-noise explanations are sampled from current inputs rather
than duplicated for every cached pair. The saved `cutoff_db` defines the passing
and below-margin labels; a stricter map display filter can still hide a passing
result. Changing a display filter does not change the stored calculation.

Changed RF/model inputs invalidate reuse. As with previously saved passing
links, the portable network identity deliberately omits the local terrain/data
inventory: opening the same project after unrelated downloads can retain its
results. Use **Analysis → Recalculate → All Links** to refresh against newly
downloaded or replaced terrain, land cover, or LiDAR. Explicit recalculation
starts new evidence rather than treating the old ledger as authoritative.

Older files remain readable. A legacy file or completed local disk cache that
contains only passing links can seed those results, but it supplies no evidence
for absent pairs. Unsupported or malformed optional cache data is ignored while
valid authored nodes and settings remain loadable.

## Saving, interruption, and recovery

**File → Save Network** captures the results received so far. Later worker results
belong to a later save. Both positive links and outcome records use bounded
publication batches; a worker interruption flushes its completed outcome tail
when its receiver is still available. Unpublished or omitted pairs remain unknown.

Recovery checkpoints also retain partial evidence, with cache-only checkpoint
attempts throttled to once every two seconds. Streaming results do not make the
authored network dirty or add an unsaved-edit marker. Recovered cache evidence
remains protected until saved; recovery can lag the latest results. Normal
shutdown retains the existing recovery-retirement behavior, so use **Save** to
keep calculated work in the project file.

Headless jobs retain partial evidence on cancellation or incomplete completion
only when the session topology and solve generation still match. A stale job
cannot attach its evidence to an edited network or replace a newer solve.

## Size and implementation limits

The ledger is sparse and capped at one million stored records. Resume compacts
duplicate history and reopens unavailable observations for retry, making room
for their new outcomes. A worker-side index handles lookup during resume;
immutable batches let saves share earlier evidence without copying it as new
results arrive.

Network files retain the 256 MiB limit. If optional evidence would push a save
over that limit, the save worker reduces the cached subset before writing.
The live cache and authored data remain unchanged; omitted records are unknown
on reopen. A file whose remaining network state still exceeds the limit is
refused, preserving the previous file. This cache is derived planning evidence,
not a guarantee of measured RF performance.
