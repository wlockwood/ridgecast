# Coverage persistence implementation plan

Status: complete. Owner: Codex.

## Outcome

Reopening a network restores its coverage selection and display settings, reuses
completed per-node calculations when their inputs still match, and computes
missing results on the existing coverage worker. Cached data remains disposable.

## Work sequence

- [x] Replace process-local coverage identity with a versioned, stable input key
  and persistent fingerprints for relevant terrain, land-cover, and surfaces.
  Include the actual CPU/GPU method; keep rendering and selection out of keys.
- [x] Store bounded, checksummed, compressed f32 grids with explicit version and
  grid identity. Ignore legacy files and corrupt/incomplete entries. Publish only
  completed calculations, with all cache I/O off the UI thread.
- [x] Add a Coverage category to background cache maintenance, with configurable
  capacity (initial default 1 GiB) and access tracking across sessions.
- [x] Persist coverage workspace settings with backward-compatible defaults and
  restore through the existing asynchronous calculation/merge pipeline.
- [x] Document behavior and add focused regressions for restart reuse, input/data
  invalidation, backend separation, corruption, cancellation, and old projects.
- [x] Run formatting, check, clippy, tests, and documentation link checks. Record
  any environmental blockers and remaining work here.

## Design constraints

- Preserve existing uncommitted changes in this shared workspace.
- Per-node grids remain independent of the selected set and merged display grid.
- Stable data fingerprints must account for newly available fallback replacements.
  A conservative miss is preferable to silently reusing stale coverage.
- Data changing during computation must not produce a cache entry claiming a
  consistent snapshot that was never actually used.
- Cache validation does not fetch or decode terrain. Cancellation and incomplete
  surface preparation must remain effective.
- No approval is required to continue this authorized implementation.

## Progress and validation

- Initial inspection: current cache uses runtime load counters, DefaultHasher,
  unversioned f16 payloads, synchronous startup scanning, and a private 25 MiB cap.
- Existing coverage calculation already uses independent node grids and runs on
  a worker; reuse that path for restoration.
- Completed implementation uses a SHA-256 key over canonical JSON inputs and a
  data fingerprint built from relevant local terrain and land-cover files.
  Measured surfaces contribute their raster contents. A changing input retries
  once, then displays but does not persist the unstable pass.
- Validation: `cargo fmt --all -- --check`, strict Clippy, focused cache tests,
  full `cargo test` (682 passed, 10 explicitly ignored), and documentation link
  checks passed. The first full run exposed test-global offline state from the
  new fixture; the fixture now fingerprints directories directly and does not
  construct a terrain manager.
