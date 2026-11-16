# Terrain sub-tile access implementation plan

> **For agentic workers:** Use test-driven development; independent cache and geometry tasks may run in parallel, followed by integration and a fresh review.

**Goal:** Finish the approved lazy-terrain design with explicit storage, retryable block failures, eviction and pinned circle/corridor views, and whole-path profile results.

**Architecture:** TIFF decoding remains in raster coordinates. Terrain requests select blocks from captured source rasters and preserve provider order, interpolation and NoData semantics. Views retain block leases under a bounded byte allowance; oversized requests are exposed as bounded batches. Existing rendering remains cache-only on the UI thread.

**Tech stack:** Rust, existing TIFF/codec/Rayon dependencies, no new dependencies.

**Spec:** The user's approved design in this conversation: circle intersections plus interpolation support; profiles need sampling but no physical width; corridors use half-width in metres; typed dense/tiled storage; shared retryable block loading; block eviction; preparation retains useful decoded work.

## Global constraints

- Preserve Argon's current working-tree changes; no reset, stash or speculative commit.
- Keep all disk I/O, raster decoding and request planning off the UI thread.
- Preserve source fallback order, pixel-area registration, NoData reweighting and cancellation.
- Distinguish Pending, Canceled, transient errors and real NoData.
- Use stable opened file identities and bounded decoder scratch allocations.
- Count unique allocations, including data retained by active leases; evict only unpinned blocks.
- Handle edge blocks, antimeridian requests, high latitude, zero-length paths and invalid input explicitly.

## Review focus

1. A failed read is retried and cannot poison a block as permanent NoData.
2. Circle/corridor boundary intersections include interpolation neighbors.
3. Concurrent consumers share loads, and canceling one request does not poison another.
4. Prepared views preserve source identity and sample values after cache eviction or file replacement.
5. Large requests can be processed in bounded batches without an unbounded pinned working set.

## Tasks

### 1. Explicit raster storage and reads

- [x] Add behavior tests for dense/tiled sampling and materialization without magic pixel sentinels.
- [x] Replace the three-float lazy identifier with `TerrainStorage::{Dense,Tiled}` and ordinary Arc ownership.
- [x] Migrate dense raster constructors and pixel consumers; preserve local-raster hashing and nearest sampling.
- [x] Verify focused terrain/local-raster tests.

### 2. Robust block cache

- [x] Reproduce transient read poisoning, duplicate loads, boundary sampling, retained completeness data and pinned eviction.
- [x] Implement explicit loading/ready/error states, stable file reads, per-block leases and eviction.
- [x] Budget codec/input/output scratch and count pinned data correctly as cache ownership changes.
- [x] Verify focused TIFF/cache/memory tests.

### 3. Request geometry

- [x] Add independently checked circle, corridor, path, antimeridian, pole and invalid-input tests.
- [x] Implement validated geographic requests and block intersections with interpolation support.
- [x] Expose bounded batch selection, preserving the existing profile sampling convention.
- [x] Verify geometry tests.

### 4. Terrain views and integration

- [x] Add end-to-end tests using real synthetic TIFFs and overlapping sources/NoData.
- [x] Implement `prepare_circle`, `prepare_corridor`, and `sample_profile` with captured sources and block leases.
- [x] Integrate region-aware retained preparation into coverage and batching into profile consumers.
- [x] Preserve cancellation and explicit unavailable/source metadata in profile output.

### 5. Documentation and final verification

- [x] Document request/width/sampling contracts, limits, fallback and cache behavior in reachable user/reference docs and rustdoc.
- [x] Run formatting, all-target/all-feature checking, strict Clippy, full tests, document links and diff checks.
- [x] Obtain a fresh code review, address material findings and record any limitations.

## Execution record

- Ruling: work in place because the approved change extends Argon's uncommitted prototype; a clean worktree would omit it.
- Ruling: implement the design already approved by “Do all of that”; no additional approval checkpoint is needed.
- Verification: workspace tests passed 2,481 library tests (39 ignored), 32 MCP tests, and binary/doc targets. Formatting, all-target/all-feature check, strict Clippy, 66 Markdown link checks and diff checks passed.
- Real-data validation: the USGS 10812x10812 comparison passed all pixel checks. Its 500-point lazy profile retained about 20 MiB versus about 446 MiB for the full grid. Test-build timings under concurrent compilation are not release performance evidence.
- Final review: five Important findings received failing regressions and passing fixes: shared coverage-owner circles, extreme-coordinate acquisition, half-open source ownership, cross-group profile identities and eager input scratch. A further replacement regression verifies that fresh requests see new data while existing views retain their original generation.
- Ruling: new geographic APIs preserve straight latitude/longitude paths with shortest longitude wrapping. Existing live-profile configuration and ten-point cancellation semantics remain available. Link cache version advanced for the antimeridian change.
- Ruling: indivisible native allocations exceeding an allowance return an explicit error. Batches return Pending while the previous view remains alive.
- Remaining limits: wrapped/unsupported TIFFs retain full-raster fallback; explicit tiled materialization is a sequential diagnostic. No whole-raster speedup is claimed. Native desktop rendering was not manually exercised.
- Changes remain uncommitted for review; previously requested all-current-work commits are preserved.
