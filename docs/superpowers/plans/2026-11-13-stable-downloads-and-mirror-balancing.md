# Stable Downloads and Mirror Balancing Implementation Plan

> **For agentic workers:** Use the existing Rust/egui implementation and execute the two independent changes with focused regression tests.

**Goal:** Keep download activity and statistics readable and distribute requests across healthy equivalent dataset mirrors.

**Design:** The user selected equivalent dataset mirrors, preserving survey and canonical cache identity. Native EPT prefers the least-loaded healthy backend and rotates ties; generic assets use canonical object affinity to retain transfer coalescing. S3 URL aliases share one backend. Existing network admission, cooldowns, cancellation and immutable-object checks remain authoritative. Shared batches aggregate active request phases, prioritizing receiving over connection waits, and publish readable snapshots at a bounded rate. Fixed responsive UI columns and reserved activity rows prevent changing labels from moving statistics.

**Alternatives:** First-mirror-only fallback leaves alternate capacity idle. Switching to unrelated LiDAR providers can change surveys and resolution and was declined. Increasing concurrency per S3 alias would multiply traffic against the same backend and is not used.

## Tasks

- [x] Reproduce row movement with headless egui geometry tests; stabilize columns, clipping and activity/stall rows.
- [x] Add deterministic scheduler tests for least-load selection, fairness, shared-backend aliases, failures and refusal handling; integrate EPT and generic object readers.
- [x] Add batch activity tests for simultaneous receiving/connecting/waiting workers and bounded updates.
- [x] Update source/mirror documentation and validate relevant tests, formatting, build and strict Clippy.
- [x] Review and commit only task-owned changes, preserving the shared dirty checkout.

Generic asset readers use deterministic canonical-object affinity, including whole
archives, so existing delivery-bound in-flight coalescing still shares downloads.
Native EPT chooses the least-busy backend inside its canonical asset coordinator.
Ranged readers pin the endpoint that supplied their verified entity and update the
pin only after a fallback passes all validator and body checks.

## Verification

Validated a HEAD-based export containing only the scoped changes: `cargo test`
passed 2,682 tests, with 42 ignored; `cargo check`, formatting, strict Clippy
across all targets/features and documentation links passed. Focused tests cover
concurrent mirror scheduling, alias admission, phase priority, dwell time,
failover pinning, shared whole-asset transfers, cancellation/offline behavior,
cache reuse and exact UI geometry at multiple widths and font sizes.

The initial shared-tree LiDAR suite encountered three COPC memory-test failures
in unrelated modified files; the isolated suite passed without those edits.
Independent source review found and closed the failback-validator and activity
aggregation-cost issues. No desktop/GPU appearance or live-provider throughput
measurement was performed. Default USGS aliases alone add no independent capacity.
