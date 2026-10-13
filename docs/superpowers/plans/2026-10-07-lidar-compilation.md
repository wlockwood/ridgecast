# Adaptive LiDAR Compilation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking. Planning does not authorize production implementation or commits; preserve the shared checkout's concurrent edits.

**Goal:** Reduce long LiDAR preparation batches using a verified CPU/GPU pipeline and teach the computer benchmark to select and estimate that work on each machine.

**Architecture:** Extract a shared production compiler behind existing surface-build entry points, ship a stronger CPU baseline, then introduce GPU compilation and bounded overlap. Add a separate typed LiDAR calibration to the existing application-owned performance service; use complete-pipeline measurements for backend selection and preparation ETA.

**Tech Stack:** Existing Rust, Rayon, wgpu/WGSL, LAS/LAZ native reader, Serde, zstd, background-job channels and atomic cache publication. No new runtime dependency is planned.

**Spec:** [Adaptive LiDAR compilation design](../specs/2026-10-07-lidar-compilation-design.md). Read both documents. The standalone `tools/lidar-surface-bench/` remains feasibility evidence until it calls the production compiler.

## Global constraints

- No expensive I/O, device probing, shader creation, device polling, array copies, or compilation on the UI thread; every interactive control has a tooltip.
- Exact masks/support/classification/provenance, GPU numeric error at most 0.001 m, bounded native-reader allocation, node rollback, and conservative source completeness remain mandatory.
- Keep cancellation, immutable plans, frozen coverage cache-hit contexts, generations, atomic publication, and persistent prepared-cache reuse.
- Auto defaults to CPU; GPU needs five complete paired trials and a conservative 15% full-path benefit. Quick/Extended measurement targets remain 30/120 s; insufficient samples mean unavailable recommendations.
- Grid classes 256/1024/2048 at 0.9144 m; Extended workers clipped/deduplicated from 1/4/8/16/N, Quick one/N. N is the captured CPU allowance bounded by available parallelism and 64, rather than the development run's sixteen workers. Six-job measured cohorts; one queued pipeline item with byte admission; initial surface GPU allocation budget 256 MiB plus actual binding/dispatch limits.
- Scratch files at most 256 MiB on the active cache filesystem; no OS cache flushing. Reopen cache state must be honest. Separate warm and first-use measurements.
- Existing propagation calibration remains compatible; maximum 64 LiDAR and 128 propagation records, file bound 1 MiB. Unknown storage identity prevents reuse of disk measurements across sessions.
- No automatic increase in concurrency to chase utilization, no general terrain compression-policy change, and no prepared-cache invalidation solely due to backend availability.

## Review focus

1. Ground classification first appears in a later/disjoint node: earlier unclassified ground candidates disappear across the acquisition (Tasks 2-3).
2. A corrupt node fails after valid chunks were read: no node measurements survive; replacement retry and failure support remain correct (Tasks 2-3).
3. A small-memory computer or small GPU cannot hold the pipeline: admission precedes allocation and a sequential CPU path remains usable (Tasks 3, 6).
4. Device loss, cancellation, and competing generation changes arrive during a blocked stage: no stale publication, leaks, or CPU timing mislabeled GPU (Tasks 3-6).
5. New hardware, CPU worker policy, cache volume, unknown OS cache state, or noisy samples: old calibration never becomes a confident new recommendation (Tasks 4-5, 7).

## File and interface map

Existing owners: `src/engine/lidar/surface.rs` owns validated extraction and SurfacePair; `surface/memory.rs` owns allocation accounting; `src/engine/itm_dsm.rs` owns reuse/publication and request progress; `src/performance.rs` owns asynchronous service and persisted propagation records; `src/engine/gpu.rs` owns initialized compute device; `src/link_solve.rs` owns the displayed link preparation status.

Create focused children rather than extending these large files with entire subsystems:

- `src/engine/lidar/surface/compiler.rs`: input transactions, execution configuration, stage timing, backend interface.
- `src/engine/lidar/surface/compiler/cpu.rs`: parallel node staging and deterministic CPU merge/finish.
- `src/engine/lidar/surface/compiler/gpu.rs` and `src/engine/shaders/lidar_surface.wgsl`: GPU numeric/support operations and admitted buffer lifecycle.
- `src/engine/lidar/surface/runtime.rs`: CPU pool, GPU handle, byte reservations, bounded execution context.
- `src/engine/itm_dsm/build_coordinator.rs`: per-key single-flight preparation, shared admission, bounded preparation batches.
- `src/performance/lidar.rs`, `src/performance/lidar/fixture.rs`, `src/performance/lidar/storage.rs`, `src/performance/lidar/tests.rs`: typed calibration/policy, reproducible fixtures, storage evidence, deterministic tests.
- `src/engine/lidar/surface/compiler/tests.rs` and `src/engine/itm_dsm/build_coordinator/tests.rs`: correctness and lifecycle coverage. Declare modules from their existing parent files.

Proposed interfaces below are crate-internal. Resolve existing SurfacePair private fields through parent/child access rather than widening public APIs.

## Task 1: Measure the production preparation path

**Files:** Create `surface/compiler.rs`; modify `surface.rs`, `surface/memory.rs`, `src/engine/itm_dsm.rs`; create `compiler/tests.rs` (paths under the file map above).

**Interfaces:** Produce `BuildStage` (Read, DecodeProject, Aggregate, Fill, Support, Upload, DispatchReadback, EncodeCompress, Write, ValidatePublish), `BuildTimings { stages: Vec<StageTiming>, wall: Duration }`, and `StageTiming { stage: BuildStage, elapsed: Duration, bytes: u64, items: u64 }`. Add optional timing collection to the new compiler context; existing public build entry points retain their signatures and default CPU behavior.

- [ ] Add tests `timings_keep_overlap_separate_from_wall`, `timing_collection_preserves_build_outputs`, and `failed_build_never_reports_successful_publication`: overlapping 10 ms stages with 12 ms wall stay 12 ms; instrumented/uninstrumented outputs are identical; failing publication emits no success.
- [ ] Run `cargo test --lib timings_` and the two named behavior tests; observe the new behavior tests fail before implementation.
- [x] Add monotonic timing spans around actual native decode, compiler, encoding, writes and `publish_surface` validation/reload. Count bytes at existing boundaries without rescanning files. Optional collection uses no filesystem/platform probing on UI paths and distinguishes acquisition time.
- [ ] Run the focused tests and `cargo check`; retain a full-path baseline on representative cached data, including the current writer and metadata.
- [ ] Deliver a reviewable instrumentation change; stage only these owned files if commits are subsequently authorized.

## Task 2: Shared compiler and faster CPU baseline

**Files:** Create `compiler/cpu.rs`, `surface/runtime.rs`; modify `surface.rs`, `surface/memory.rs`, `src/engine/lidar/plan.rs`; extend `compiler/tests.rs`.

**Interfaces:** `CompileConfig { backend: SurfaceBackend, workers: usize }`; `SurfaceBackend::{Cpu,Gpu,Auto}`; `CompileContext { config: CompileConfig, runtime: Arc<CompileRuntime>, cancel: Arc<AtomicBool>, generation: u64 }`; `CompileRuntime` owns a capped Rayon pool and shared `BuildBudget`. `NodeAggregate` carries node identity, accepted-point count and sparse per-crop extrema/count/support records with classified and fallback ground kept separately. Produce `stage_node(input: ValidatedNodeInput<'_>, context: &CompileContext) -> SurfaceResult<NodeAggregate>` and `compile_cpu(nodes: &[NodeAggregate], context: &CompileContext) -> SurfaceResult<Vec<SurfacePair>>`. `ValidatedNodeInput` borrows the existing frozen plan and candidate; native-reader validation still occurs before a stage can succeed.

- [ ] Add tests `cpu_parallel_nodes_match_serial_contract`, `later_ground_resets_disjoint_fallbacks`, `late_corrupt_node_discards_all_contributions`, `cpu_worker_count_is_clipped_and_accounted`, and `node_staging_too_large_uses_journal_path`. Compare masks, support/density/counts, classification and numeric values against the existing sequential path, including worker counts 1/4/8/16. Pin saturation at existing counter limits, and native codec allowance for every simultaneous reader.
- [ ] Run `cargo test --lib cpu_parallel_nodes_` and each new named test to establish failures.
- [x] Extract transactions with separately tracked classified/minimum-return candidates. Stage a bounded wave of independent nodes; collect within the admitted wave and merge in plan order. Preserve reader cancellation, cache lease lifetime, corruption retry and failure-region support. Keep large nodes on the existing bounded chunk/journal path when complete transactional staging exceeds admission. Explicitly install remaining memory allowance and download/control context in every worker; TLS state is not inherited automatically.
- [x] Implement `BuildBudget::try_reserve(&self, host_bytes: u64, device_bytes: u64) -> SurfaceResult<BuildReservation>` with RAII release and checked aggregate accounting. Model staged nodes, native codecs, pairs, support, encoder and reload lifetimes. Host maximum is the existing per-build limit plus the enclosing calculation's remaining admission; device limits are validated before buffers exist.
- [ ] Run `cargo test --lib engine::lidar::surface`, `cargo test --lib engine::itm_dsm`, and full-path CPU benchmarks. Keep the faster complete-time configuration for each class; the optimized CPU is the baseline for all GPU comparisons.
- [ ] Deliver the CPU improvement separately from GPU enablement; retain serial execution for low-memory cases and single-stream decoding.

## Task 3: Production GPU compiler with complete metadata parity

**Files:** Create `compiler/gpu.rs`, `src/engine/shaders/lidar_surface.wgsl`; modify `src/engine/gpu.rs`, `compiler.rs`, `surface/runtime.rs`, `surface/memory.rs`; extend `compiler/tests.rs`.

**Interfaces:** Add `GpuEngine::compute_device(&self) -> ComputeDevice`, a crate-only cloned-handle value containing device, queue, identity and limits. `GpuSurfaceCompiler::new(device: ComputeDevice) -> Result<Self, SurfaceGpuFailure>` initializes lazily on a worker; `compile(&mut self, nodes: &[NodeAggregate], context: &CompileContext) -> Result<Vec<SurfacePair>, SurfaceGpuFailure>` returns the same product contract as Task 2. `SurfaceGpuFailure` distinguishes unavailable/limits/precision/device failure from cancellation for routing and carries an existing sanitized SurfaceError; translate at public boundaries.

- [ ] Port the prototype's five numeric correctness checks into production tests, then add `gpu_support_and_density_match_cpu`, `gpu_failed_regions_and_donors_match_cpu`, `gpu_precision_or_limits_refuse_before_allocation`, and `gpu_device_loss_releases_reservations`. Exact masks, evidence and counts; numeric error <=0.001 m; out-of-envelope values refuse GPU; cancellation never becomes fallback success. Reuse existing sentinel, noise/withheld, classification and native corruption fixtures.
- [ ] Run the CPU/mock lifecycle tests and explicitly invoked release GPU tests on both available adapters. Unavailable hardware is an explicit unavailable result, never a GPU pass.
- [x] Port the kernels using CPU-computed cell indices and finite representable elevations. Keep global classified-ground policy from Task 2. Implement support/density updates in the GPU path or deterministic CPU donor replay, counting that replay in total time. Preserve CPU donor ordering, failed-source propagation and saturated counters. GPU-only numeric output cannot pass qualification.
- [x] Validate optional timestamp capabilities, binding/dispatch limits and memory before allocation; use error scopes and bounded submissions/readback. Reuse buffers between crops. A canceled dispatch may finish physically, but its result is discarded and the worker checks cancellation during waits. Retain sufficient immutable host input for admitted CPU retry.
- [ ] Run production CPU/GPU parity including native read, support, GeoTIFF/support serialization and staged reopen. Record raw full-path results; leave Auto on CPU until calibration and routing land.
- [ ] Deliver the GPU compiler as a separately reviewable, explicitly selected internal path.

## Task 4: Reproducible LiDAR and storage calibration

**Files:** Create `src/performance/lidar.rs`, `lidar/fixture.rs`, `lidar/storage.rs`, `lidar/tests.rs`; modify `src/performance.rs`; migrate `tools/lidar-surface-bench/bench.rs` and `run.ps1` to call the production engine when available (a small Cargo example under `examples/lidar_surface_bench.rs` may replace direct rustc compilation).

**Interfaces:** `LidarProbeKey` contains machine/build, compiler/fixture revision, adapter identity, workers, dimensions, spacing, sparse/dense point class, cohort count, warm/first-use state and optional storage identity. `LidarProbe { key: LidarProbeKey, trials: Vec<LidarTrial>, measured_at_unix: u64 }`; `LidarTrial { cpu_wall_seconds: f64, gpu_wall_seconds: Option<f64>, stages: Vec<StageTimingRecord>, correctness_verified: bool }`, with serializable duration records in finite seconds. Add `#[serde(default)] lidar_measurements: Vec<LidarProbe>` to `CalibrationSnapshot`. `run_lidar_benchmark(request: LidarBenchmarkRequest, cancel: &AtomicBool, progress: &mut dyn FnMut(LidarBenchmarkProgress)) -> Result<Vec<LidarProbe>, String>` uses Tasks 1-3. Request captures active cache path and initialized compute handle on worker-safe boundaries.

- [ ] Add tests `old_calibration_keeps_propagation_and_defaults_lidar`, `lidar_records_reject_nonfinite_or_partial_trials`, `lidar_cancel_preserves_previous_snapshot`, `changed_volume_does_not_reuse_io_measurements`, `unknown_volume_is_session_only`, and `storage_reopen_never_claims_cold`. Pin five-trial qualification, caps 64/128, and the existing 1 MiB bounded loader/writer behavior. Exceeding the bound must trim valid old records deterministically before atomic save, not truncate JSON.
- [ ] Run `cargo test --lib performance` to establish the new failures while checking old calibration tests.
- [x] Generate deterministic compressed local fixtures once outside timed samples; record seed/version/checksum and validate against CPU. Quick uses one/N workers and Extended clipped 1/4/8/16/N; alternate paired order, measure first use separately, and collect complete six-job and isolated cohorts. Native-reader slots are separately bounded by shared memory, not equated to Rayon thread count. Budget exhaustion skips new cohorts and reports unavailable cells; canceled/failed runs publish no replacement calibration.
- [x] Measure actual filesystem reads and production artifacts in a unique at-most-256-MiB scratch directory on the cache volume. Separate cached-memory input and reopen tests, small-file counts, compression levels 3/9, writes and optional sync, validation/reload. Cleanup owns only the created scratch directory, including cancellation/error exits; never alter production cache entries. Store cache state and write semantics with each result.
- [x] Keep LiDAR eligibility independent of propagation-model GPU support. Existing propagation paths and record validation stay unchanged; typed LiDAR measurements must not enter `units_per_second` or Coverage propagation rates.
- [ ] Run `cargo test --lib performance`, CPU-only release calibration, both GPU adapters and worker sweeps. Save complete stage/wall results with unavailable/skipped cases explicit.
- [ ] Deliver calibration separately; selection remains opt-in internally until Task 5.

## Task 5: Per-machine backend and worker selection

**Files:** Extend `src/performance/lidar.rs` and `lidar/tests.rs`; modify `surface/runtime.rs`, `src/performance.rs`, `src/engine/itm_dsm.rs` and the captured preparation execution configuration.

**Interfaces:** `LidarWorkDescriptor` contains dimensions, spacing, point-density class or Unknown, remaining cohort count, available worker budget, storage identity and device-ready state. `LidarDecision { backend: SurfaceBackend, workers: usize, estimate: Option<Estimate>, reason: LidarDecisionReason }`. Produce `select_lidar_execution(probes: &[LidarProbe], work: &LidarWorkDescriptor) -> LidarDecision` and `observe_lidar_completion(observation: LidarObservation)` on the execution context. Unknown/extrapolated work returns CPU and an explicitly rough or absent estimate.

- [ ] Add table-driven tests: the same GPU with CPU/GPU cohort times 10/5 selects GPU, 4/5 selects CPU; fastest CPU 10 and slowest GPU 9 fails the 15% gate, 10/8 passes; fewer than five complete paired trials cannot select GPU. Adapter/build/worker/storage/fixture changes invalidate relevant matches. Device-not-ready initialization charged once can make a short batch CPU; already-ready execution does not pay startup twice. Test mixed/unknown classes and noisy overlapping ranges explicitly.
- [ ] Add `gpu_fallback_is_visible_and_not_calibration`, `cancellation_does_not_retry_cpu`, and `five_slow_observations_suspend_gpu_for_batch` with a mocked executor and known upper CPU baseline.
- [ ] Run the focused `performance::lidar` tests and establish failures.
- [x] Implement pure conservative selection from full-path trials; choose measured worker configuration within captured allowance. Apply startup to a first-use cohort, including support/I/O; CPU without qualified matches. Keep uncontrolled runtime observations separate. Disable session GPU on loss or qualification mismatch, and visibly retry CPU only for actual GPU failure after reservation release and input re-admission.
- [ ] Run deterministic policy/lifecycle tests and replay captured benchmark records for discrete, integrated and simulated CPU budgets. No vendor names or the development machine's ratio appear in selection logic.
- [ ] Deliver backend selection; GPU decisions are now eligible, while requests remain serial until Task 6.

## Task 6: Bounded batches and narrower preparation ownership

**Files:** Create `src/engine/itm_dsm/build_coordinator.rs` and its `tests.rs`; modify `src/engine/itm_dsm.rs`, `surface/runtime.rs`, `src/engine/lidar/plan.rs`; extend existing `itm_dsm` cache regressions.

**Interfaces:** `BuildCoordinator::prepare_batch(&self, plan: &SurfacePlan, execution: Arc<PreparationExecution>, cancel: Arc<AtomicBool>, on_progress: &mut dyn FnMut(PrepareProgress)) -> Option<SurfaceContext>`; `PreparationExecution` owns Tasks 2/3 runtime and Task 5 decisions plus captured generation/control context. Per-key `BuildTicket` owns cancellation-safe single-flight result sharing. The coordinator owns one queued item and shared reservations; the immutable SurfacePlan/source selection remains authoritative.

- [ ] Add `same_key_builds_once_for_two_consumers`, `independent_keys_overlap_with_one_queued_item`, `memory_limit_runs_sequentially`, `cancel_blocked_producer_releases_every_reservation`, `cancel_one_waiter_does_not_cancel_other_owner`, `completed_surfaces_survive_later_cancel`, and `publication_order_keeps_frozen_coverage_hits`. Use barriers/mock stages to prove overlap and wakeups without timing-based sleep assertions.
- [ ] Run `cargo test --lib build_coordinator` and `cargo test --lib coverage_cache_hits_keep_their_preflight_surfaces_when_new_nodes_prepare` before changing the lock; new behavior tests fail, existing cache regression stays green.
- [x] Replace `PREPARE_LOCK` in both direct and planned preparation paths with per-key ownership. Recheck cache/covering hits after ownership; keep cache/index mutexes short and publication atomic per directory. Honor existing online/offline reuse policy and return previous valid generation on an unsuccessful refresh as currently permitted.
- [x] Pipeline CPU decode/aggregate of the next crop with GPU finish of the current crop; permit bounded encoding/publication overlap only when all live allocations are reserved. One CPU worker allowance covers decode, support and compression. Explicitly propagate download generation, active-task control, trigger and remaining-memory context to workers. Keep result/source ordering deterministic and canceled generations out of publication.
- [ ] Run `cargo test --lib engine::itm_dsm`, `cargo test --lib engine::lidar`, and full-path release batches of 1/6/100 requests under normal/restricted admission. Verify second run reuses prepared products without compilation and restart restores completed entries.
- [ ] Deliver the scheduler only with measured full-path gains and intact cache/cancellation behavior; do not add cross-request decoded-point caches in this task.

## Task 7: Benchmark results and useful preparation progress

**Files:** Modify `src/app/ui/performance_window.rs`, `src/performance.rs`, `src/app/mod.rs`, `src/engine/itm_dsm.rs`, `src/link_solve.rs`; inspect other `prepare_reporting` callers for equivalent background progress. Extend reachable benchmark/cache docs and `README.md`.

**Interfaces:** Extend `PrepareProgress` with reused, completed, failed, active-stage/backend and optional ETA range while retaining existing done/total meaning. Add a typed LiDAR workload selection to BenchmarkRequest; UI presents separate propagation and LiDAR results. `PerformanceService` continues background ownership when windows close, and generation-checked publication/persistence.

- [ ] Add `preparation_eta_weights_work_classes_and_excludes_reused`, `preparation_eta_marks_unmatched_work_rough`, `first_build_has_stage_progress`, and `lidar_gpu_controls_ignore_propagation_compatibility`. A 256-grid cached hit adds no build cost; 2048-grid pending work uses its own scope; absent matching samples never display a calibrated estimate. UI rendering tests cover unavailable GPU, unknown storage and long identity/result text without Context reentry.
- [ ] Run focused ETA, service and UI tests to establish new failures.
- [x] Add LiDAR selection/results to Performance & Calibration. Show total CPU versus hybrid wall-time ranges, worker configuration, adapter, single/batch and warm/first-use distinction, cache-volume evidence, recommendation/reason and unavailable combinations. Keep details separate from normal progress. CPU calibration works without GPU, and surfaces remain benchmarkable with non-GPU propagation models.
- [x] Replace the count-only status with compact counts, active stage/backend and ETA range when available; coalesce worker events to at most four updates/second except stage/completion changes. Keep download time separate and preserve responsive cancellation. Never compute averages, read disk, probe adapters or construct buffers inside UI closures.
- [x] Document backend adaptation, CPU/GPU overlap, calibration scope, warm-cache storage limits, fallback and persistent reuse on the reachable pages listed in the spec; update README benchmark/LiDAR capability text and review all added tooltips.
- [ ] Run focused tests, `pwsh -File tools/check-doc-links.ps1`, and a manual desktop check of progress during first/late builds and while closing/reopening benchmark/calculation windows.
- [ ] Deliver the user-facing change with actual screenshot/runtime evidence where available.

## Task 8: Qualification and evidence

**Files:** Add `tools/lidar-surface-bench/README.md`; retain machine-local raw reports under `.feature-work/lidar-gpu-bench/`; update this plan's checkboxes only for work actually completed.

- [x] Run `cargo check`, `cargo fmt --all -- --check`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test`, and `pwsh -File tools/check-doc-links.ps1`. Report concurrent-tree failures, ignored GPU/network tests and unavailable hardware rather than claiming them passed.
- [x] Explicitly run release GPU parity/benchmarks on the discrete and integrated adapters, CPU-only execution and worker allowances 1/4/8/16, plus constrained host/device memory. Retain compiler/build/fixture identities, raw paired trials, whole-path stage timings and recommendation decisions.
- [ ] Run a representative 100-request source-complete batch through real preparation with isolated benchmark outputs. Compare old CPU, optimized CPU and Auto complete elapsed time including artifacts and validation. Include differing crop sizes and warm/cold-or-unknown file-cache states. Do not extrapolate the numeric prototype's 2.154x gain into an application claim.
- [ ] Verify mid-batch cancel/restart keeps completed reusable surfaces; second run builds only actual misses; repeated-key consumers single-flight; five coverage cache hits plus a new overlapping request solve only the new node. Check sustained UI responsiveness during CPU/GPU and storage stages.
- [ ] Review complete-output parity and byte-accounting boundaries before enabling Auto recommendations. A class that does not clear its measured gate stays CPU even if other classes qualify. If write/validation dominates, use the measured level-3/9 comparison to decide a separate LiDAR-only compression change; retain mandatory validation and publish semantics.
- [x] Write benchmark instructions and an honest results/limitations note; inspect only task-owned paths before any authorized concern-based commits. No performance claim substitutes for passing correctness and lifecycle checks.

## Plan self-review

Every design requirement maps to Tasks 1-8: instrumentation/storage (1,4), CPU/GPU correctness and admission (2,3), machine-specific selection (4,5), large batches/cache safety (6), progress/docs (7), qualification (8). Review-focus inputs have named tests in their owning tasks. Shared configuration, node transaction, calibration and decision interfaces are defined before consumers. No product changes or commits are included in this planning deliverable.

## Execution evidence

The subsequent user request authorized implementation, separate worktrees, focused commits and integration into local `main`. LiDAR work is isolated on `codex/lidar-compilation`; Link Profile is on `codex/link-profile-workbench`. The planning-only boundary above describes the original planning turn.

Tasks 1–7 are implemented. Actual interfaces use focused compiler/runtime children and a cancellation-aware shared CPU stage around encoding and publication. Sparse native-node transactions merge in plan order; oversized nodes retain the bounded journal path. Two admitted jobs can overlap while sharing one CPU allowance, host/device reservations and per-key single-flight ownership. GPU numeric finishing retains CPU cell indexing and exact support/donor replay; canceled work does not retry, and device/qualification failures suspend GPU for the session. Calibration uses the production native reader, obstruction/decimated-ground/density/support writer, manifest, atomic publication, reload and isolated index insertion. Fixture revision 3 invalidates earlier diagnostic fixture revisions.

Five complete warm CPU trials are required for calibrated CPU worker selection and ETA, independently of GPU readiness. GPU selection requires five complete paired trials and the conservative 15% full-path gate against the strongest observed CPU configuration within the allowance. Unknown shapes, density, mixed cohorts or incomplete sources retain CPU; unmatched estimates remain rough. UI result rows are formatted on a worker and preparation progress carries stage, backend, slots and reused/completed/failed counts.

Independent source reviews found and resolved publication omissions in the initial benchmark, shared-pool lifetime/oversubscription, mixed cohort selection, rough ETA, duplicate egui IDs, CPU calibration incorrectly depending on GPU readiness, and a busy GPU mutex incorrectly looking uninitialized. Focused final performance checks passed 50 tests with four explicit budget/hardware tests ignored; the busy-compiler regression passed separately. Strict all-target/all-feature Clippy, `cargo check`, format and documentation-link checks passed before final hardware qualification. Full feature and combined-main qualification are recorded below when completed.

A release 100-request source-complete fixture published all 100 products: serial CPU 1.5018048 s, pipelined CPU 1.0530778 s, Auto 1.0648791 s. All outputs matched exactly across modes; restart reused all 100 without building. The original source published 95 and rejected five because manifest JSON parsing moved their f64 spacings by one ULP; a failing manifest roundtrip regression was fixed with `serde_json`'s `float_roundtrip` feature. The 95 successful original payloads match current payloads exactly. This is one small native fixture and one timing run, not a representative application-wide speedup or a GPU gain. Stage totals can overlap and exceed wall time. Raw reports are retained under `.feature-work/lidar-gpu-bench/`.

Native desktop interaction/screenshots and physical cold-disk/NVMe telemetry have not been obtained. Headless egui tests are separate evidence; reopen storage state is warm or unknown and writes use buffered production semantics. There is no general compression-policy change. Items requiring native interaction, differing real-world crop distributions or physical storage telemetry remain validation limits rather than checked acceptance claims.

Feature qualification at `7a98461b`: full `cargo test` passed 2,116 tests, zero failed, 32 ignored; binary and doc-test targets passed. The ignored tests include explicit GPU hardware, long calibration budgets, live providers and image capture. `cargo check`, `cargo fmt --all -- --check`, `cargo clippy --all-targets --all-features -- -D warnings`, the documentation checker (67 Markdown files) and `git diff --check` passed. Final release hardware measurements and combined-main checks remain pending at this checkpoint.

Explicit release hardware correctness checks at the same implementation commit passed on both NVIDIA and AMD adapters: 11 compiler tests per adapter, plus the complete-artifact fixture-3 publication/reload test per adapter (256 sparse, 1024 dense and 2048 sparse). No unavailable adapter was counted as a pass. Logs are `production-v3-{NVIDIA,AMD}-{parity,publication}.log` in the central report directory.

Final hardware timing qualification completed CPU-only Quick, NVIDIA and AMD Extended, and separate NVIDIA Quick allowances 1/4/8/16. No measured candidate cleared the conservative GPU gate; Auto retains CPU for these classes. Each report explicitly retains unmeasured and partial classes rather than qualifying them. The CPU-only report also shows per-class worker selection: dense 1024 single jobs favored one worker, whereas complete six-job evidence favored the full allowance. See [benchmark instructions and results](../../tools/lidar-surface-bench/README.md); the machine-local detailed evidence is `.feature-work/lidar-gpu-bench/production-v3-qualification.md` with raw JSON, test logs and `production-v3-summary.json`.

Both features merged cleanly into local `main` at `c8739738`. Combined-main verification passed `cargo check`, format, strict all-target/all-feature Clippy and full `cargo test`: 2,160 passed, zero failed, 32 ignored; binary/doc-test targets passed. The local documentation checker (67 Markdown files), whitespace checks and retained five-hit coverage-context regression passed. Final documentation-only evidence edits do not change the verified source. No remote is configured. Native desktop and physical cold-storage limitations above remain explicit.
