# Dual-mode Site Finder implementation plan

Spec: [approved behavior](../specs/2026-10-08-site-finder-dual-mode.md).

Status: implemented and independently reviewed. Build, format, strict Clippy,
2,191 passing tests (32 ignored) and documentation links passed. Matching-model
hardware compute qualification passed 175 trials; whole-scan timing is not
established. See [measurements and limits](../../reference/site-finder-fast-benchmark.md).

## Task 1: matching CPU approximation and mixed-device engine

Implement explicit scan execution with separate full CPU and approximate fast
modes in engine/site_finder.rs and suitable new engine modules. Preserve the
existing run_site_finder signature if practical with an execution wrapper or
compatible selection mechanism; expose a typed mode usable by UI and refinement.
Provide CPU radial approximation matching shader f32 geometry, clutter endpoint
subtraction, Deygout diffraction and two-ray calculation. Fast CPU plus independent
physical GPU queues dynamically claim bounded batches; use one shared Rayon pool.
On GPU failure use matching fast CPU evaluation. No full ITM call inside Fast.
No approximation call inside Full. Add backward-compatible saved model identity.
Write behavioral tests first and verify failure before implementation. Include
full CPU model preservation, shader parity, queue coverage, failure/cancellation.
Add an offline example benchmark if practical, capture actual hardware results.

## Task 2: user actions and saved refinement

Connect Full quality (CPU) and Fast (CPU + GPUs) actions to execution. Explain
approximation and show it in status/saved assumptions. Refinement uses retained
mode. Preserve legacy imports and existing API call sites. Do not misapply full
CPU calibration to approximate CPU or mixed timing. Give all controls tooltips.
Document both modes in reachable user docs and README. Add UI/regression tests.

## Task 3: qualification, review and integration

Independently review scientific separation, frozen inputs, device failure,
cancellation, publication and UI meaning. Address findings. Run check, format,
strict all-target/all-feature Clippy, tests and docs links. Benchmark matching
models at multiple worker allowances and available GPU combinations without
competing build jobs. Record limitations honestly. Commit scoped files and merge
the isolated branch to main without altering unrelated edits.
