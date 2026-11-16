# LiDAR CPU Scaling Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement each task and review the integrated result.

**Goal:** Let LiDAR preparation use every available CPU worker when independent work and the user's memory allowance permit it.

**Architecture:** One shared CPU pool, sized to available logical processors, runs decode, projection and raster work. Replace arbitrary two-job/eight-node limits and the fixed 2 GiB working-set ceiling with memory-admitted work sized from the existing configured decoded-memory budget. Retain bounded codec allocations, deterministic transactions, cancellation, provider concurrency and survey identity.

**Tech Stack:** Rust, Rayon, existing las/laz and decoded-memory accounting.

**Spec:** User requests all portions of the pipeline to be capable of using all cores and explicitly authorizes aggressive use on a 96 GB machine. This does not authorize unbounded allocation or changes to terrain, ground/support semantics or source selection. Memory and data dependencies may still limit instantaneous utilization.

## Global Constraints

- Preserve unrelated edits in this shared checkout; record initial bytes before editing. Prior in-place workflow remains in effect.
- No expensive work on the UI thread; poll cancellation during waits and long loops.
- Use one shared CPU allowance, including nested codec work, rather than one complete pool per job.
- Preserve existing output masks, classification, failure rollback and source-order publication.
- Honor configured memory limits and machine RAM headroom; do not hard-code this machine's 96 GB.
- Keep provider connection/rate limits separate from CPU concurrency.
- Invalidate incompatible calibration evidence when execution semantics change.
- Do not commit this follow-up without a new commit request.

## Review Focus

- Low RAM, a manual smaller allowance and a large encoded tile must fall back safely.
- Many jobs, one large file and fewer tiles than CPUs must all remain correct.
- Cancel/offline policy and thread-local context must survive parallel dispatch.
- Nested Rayon work must share the pool without deadlock or multiplication of budgets.
- Equivalence and throughput evidence must distinguish synthetic coverage from actual user workload.

### Task 1: Adaptive shared execution and memory admission

**Files:** `surface/runtime.rs`, `surface/memory.rs`, `itm_dsm.rs`, `performance/lidar.rs`, associated tests and mixed calibration helpers.

- [x] Add failing tests for more than two concurrent jobs, memory-limited waves and scaling above the old 2 GiB ceiling.
- [x] Replace fixed wave limits with CPU/memory-sized admission; retain explicit benchmark overrides.
- [x] Size process-wide working admission from the configured memory allowance; preserve bounded sharing and cancellation.
- [x] Update calibration identity, worker/slot validation and tests for the new architecture.

### Task 2: Wider EPT tile execution

**Files:** `surface.rs` EPT ingest scheduling, `compiler/cpu/ept.rs`, focused tests.

- [x] Add regression tests showing sufficient memory schedules more than eight independent tiles and small budgets remain bounded.
- [x] Remove the eight-tile cap; size actual waves and per-reader allowances from remaining work and memory.
- [x] Preserve transactional node merges, corrupt-cache recovery and serial fallback for oversized nodes.

### Task 3: Native decode and projection

**Files:** `surface/native.rs`, native helpers, `surface.rs` point streaming/projecting, Cargo feature configuration if needed.

- [x] Inspect optional parallel codec behavior and bound every additional buffer before enabling it.
- [x] Add red/green equivalence, cancellation and bounded-allocation tests.
- [x] Use shared-pool parallel projection and eligible chunk decompression; keep serial compatibility fallback for unsupported layouts.

### Task 4: Review, documentation and validation

- [x] Review integrated CPU, codec, memory and scheduler changes; remediate findings.
- [x] Run check, formatting, strict Clippy, appropriate tests and documentation-link checks.
- [x] Measure release CPU builds at one, two and available workers using the local fixtures; distinguish smoke coverage from survey qualification.
- [x] Document the new limits and report exact validation limits; preserve unrelated changes.

## Verification record

Fresh independent reviews covered byte admission, shared pools, ordered publication, cancellation, native codec allocations and calibration provenance. Review hardening included aggregate allocator overhead, actual direct-reader charges, a bounded compressed-window estimate for large LAZ sources and cancellation before an empty COPC wave.

The complete library run passed: 2,721 tests, zero failures, 42 ignored. Cargo check, strict all-target/all-feature Clippy, global formatting, local documentation links (77 Markdown files) and diff checks passed. Optimized native tests passed 5 tests; COPC checks passed 6 with 1 ignored. The release application was rebuilt at target/release/ridgecast.exe.

The optimized 100-product preparation smoke check passed with identical decoded payload hashes in every mode and all 100 products reused on reopen. One observation took 1.737 s with one worker, 1.199 s with two, and 0.650 s with 32; the widest case admitted 32 jobs. The configured automatic allowance was 20,111,017,574 bytes. These are small local fixtures, not a live survey, dense-cloud, cold-storage or desktop throughput qualification. Results are in .feature-work/lidar-cpu-scaling-2026-11-13/hundred-request-preparation.json.

The CPU changes remain uncommitted. Concurrent download/mirror work was committed separately as fc4278be; unrelated checkout edits remain intact.
