# LiDAR Retrieval Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove cache traversal from tile downloads, report individual tile progress, and bound provider failures.

**Architecture:** Keep a persistent local file index and shared in-memory storage reservations in the disk-cache service. One background worker loads and reconciles the index and enforces limits. LiDAR workers publish individual outcomes while bounded transport retries unhealthy endpoints with cooldowns.

**Tech Stack:** Rust, existing Serde/reqwest/Tokio infrastructure, local HTTP fixtures.

**Spec:** The approved design in the conversation: canonical file identity and sizes, shared reservations, atomic publication and updates, background reconciliation, per-tile progress, bounded provider concurrency/backoff preserving survey provenance.

## Global Constraints

- Preserve existing checkout changes and serialized configuration compatibility.
- No filesystem work or long-held cache-index locks on UI paths.
- Preserve cancellation, offline/pause controls, active leases and canonical survey identity.
- Existing source aliases remain ordered fallbacks; they are not independent surveys.
- Do not add new data adapters or silently change survey quality.

## Review Focus

- Startup with no index, corrupt index, changed roots or files changed outside the app must recover.
- Concurrent reservations, failed publication and replacement must not double-count or exceed capacity.
- A scan concurrent with publication/deletion must not overwrite newer accounting.
- Silent/rate-limited providers must release concurrency slots, observe cancellation, and use finite retry budgets.
- One slow tile must not hide completed peers; failures must remain distinguishable from ready tiles.

### Task 1: Indexed storage accounting

**Files:** `src/engine/disk_cache.rs`, new `src/engine/disk_cache/index.rs`, tile/publication hooks in `src/engine/lidar/cache.rs` and source writers.

- [x] Write and run regression tests for reservation races, replacement/rollback, persistence, stale scan overlays and corrupt/foreign snapshots.
- [x] Implement bounded inventory loading, in-memory file totals, RAII reservations and background reconciliation/persistence.
- [x] Replace per-tile synchronous scans with indexed admission and update successful writes/removals.
- [x] Run focused disk-cache and LiDAR cache tests.

### Task 2: Provider resilience and live progress

**Files:** `src/engine/lidar/net.rs`, `mirrors.rs`, `surface.rs`, `plan.rs`, `src/engine/download_tracker.rs`, `src/app/ui/windows.rs`, `src/link_solve.rs`.

- [x] Write and run local-server tests for incremental tile completion, silent providers, transient errors, refusal handling and endpoint cooldowns.
- [x] Bound global/per-host transfers and pending bytes; add finite retries, backoff and cooldowns without retrying refusals/resource limits.
- [x] Report per-tile outcomes and visible transfer/wait/retry/cache activity; preserve task cancellation in parallel workers.
- [x] Run focused transport, mirror, surface and progress tests.

### Task 3: Documentation and verification

**Files:** relevant user docs, this plan.

- [x] Document automatic indexing, first-use reconciliation, visible progress and provider behavior.
- [x] Run Cargo check, format check, strict Clippy, tests, documentation link checks and scoped diff checks; record failures separately below.
- [x] Run a read-only warm-index admission benchmark against the diagnosed workload.
- [x] Obtain fresh code review, resolve substantive findings and record remaining validation limits.

## Review remediation

Fresh independent reviews identified and resolved these issues:

- Preserve explicit Retry-After deadlines across failure backoff and sibling successes; recheck cooldown after queued connection admission.
- Flush throttled readiness during silent transfers instead of waiting for another completion.
- Poll cancellation while acquiring storage leases and withdraw abandoned eviction headroom.
- Update inventory at surface generation publication, rollback and retirement; serialize and validate compaction against replacement.
- Count repeated snapshot paths once and clear removed entries even when replacement publication fails.

## Verification record

The commit was checked in a separate HEAD-based source export, excluding concurrent source-adapter and link-result-cache work. Cargo check, strict all-target/all-feature Clippy, formatting and documentation links passed for that export. The complete test run passed: 2,570 tests, zero failures, 39 ignored; binary and documentation test targets also passed. Local documentation links were checked in 71 Markdown files. Desktop behavior and live provider throughput were not exercised during this review.

Read-only inventory benchmark: scanning the actual 152,797-file cache took 7.624 seconds. With a warm index, 64,000 reservations across 32 competing threads during a background rebuild and SQLite checkpoint measured p50 0.700 microseconds, p99 161.200 microseconds and maximum 0.504 milliseconds. This measures indexed accounting, not end-to-end retrieval. The probe wrote only diagnostic metadata under `target/lidar-investigation`.
