# Coverage Cache Scheduling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce repeated terrain decoding when queued coverage nodes exceed cache capacity.

**Architecture:** A pure working-set scheduler admits a bounded group of nodes using full tile footprints and resident-cache metadata. The background preparation coordinator shares in-flight jobs and refills the group on solver completion. Terrain enumeration remains separate from disk validation and acquisition.

**Tech Stack:** Rust, existing Rayon download pool, Mutex/Condvar, existing terrain providers and coverage tests; no new dependencies.

**Spec:** ../specs/2026-11-10-coverage-cache-scheduling-design.md

## Global Constraints

- Preserve unrelated edits in the shared checkout; no staging, commit, branch switch, or publication is requested.
- Keep all planning, disk access, and cache scans off the UI thread.
- Keep cancellation and frozen surface contexts, original node identities, source fallback behavior, and existing oversized-run confirmation.
- Automatic uses one shared terrain allowance; Manual retains separate source allowances. NLCD retains 32 tiles. One oversized node progresses alone.
- At most four uncached nodes are admitted until calculation completion releases reservations.

## Review Focus

- A download stalls while another admitted node is ready: the ready node calculates.
- A tile was prepared in an earlier window but evicted: later nodes revalidate it.
- A node exceeds the entire budget: it progresses alone without admitting an unrelated footprint.
- Cached coverage and overlapping surfaces: preserve original context Arcs and result ties.
- Cancellation or worker failure during admission: no orphaned wait or stale publication.

### Task 1: Separate terrain footprints from preparation

**Files:** src/engine/terrain/mod.rs

**Interfaces:** Produce `coverage_dependency_jobs(discs, cancel_flag, version)` (full nominal preferred-source jobs), `coverage_job_footprint(job)` (preferred and possible fallback jobs), and resident metadata/budgets for scheduling. Existing `coverage_preparation_jobs` remains the validating interface for existing callers/tests.

- [x] Add and run a regression showing full dependency enumeration includes disk-cached/shared cells without decoding or downloading.
- [x] Extract geometric enumeration; retain existing cache validation in the old preparation method. Add footprint cost/source and residency helpers.
- [x] Run terrain preparation regressions.

### Task 2: Schedule and refill bounded preparation

**Files:** src/coverage_queue/scheduler.rs (new), src/coverage_queue.rs, src/coverage_run.rs, src/engine/landcover.rs

**Interfaces:** A pure scheduler consumes per-node interned tile IDs, costs, capacities, resident flags and completed node positions. It produces admitted node positions. `CoveragePreparation::finished(position)` releases reservations after the node's solve/merge; original positions stay unchanged.

- [x] Add failing behavior tests for grouping, weighted costs, resident preference, separate budgets, stalled/ready work, bounded refill, oversized work, empty and shared footprints, and cancellation.
- [x] Implement the scheduler; integrate a background coordinator, in-flight job ownership, readiness, and solve completion. Preserve global unique-dependency progress across repeat validation.
- [x] Verify grouped traces reduce simulated cache loads, existing handoff/context tests pass, and final coverage ownership is independent of execution order.

### Task 3: Document and verify

**Files:** docs/how-to/generate-and-export-coverage.md, docs/reference/data-sources-and-caches.md, README.md (bounded addition preserving existing edits)

- [x] Document cache-aware processing and preparation limits.
- [x] Run cargo check, cargo fmt --all -- --check, cargo clippy --all-targets --all-features -- -D warnings, cargo test, git diff --check, and tools/check-doc-links.ps1. Report unrelated failures separately.
- [x] Review the final scoped diff for cancellation, admission progress and source correctness; get one independent final code review, fix material findings, and leave changes uncommitted for review.
