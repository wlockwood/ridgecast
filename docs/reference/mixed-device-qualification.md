# Mixed-device LiDAR qualification — 2026-10-08

The [mixed-device experiment](mixed-device-benchmark.md) found no conservative
15% mixed-GPU improvement over the strongest measured CPU-only configuration on
this development computer. More concurrent CPU builds were the useful direction.
These are generated-fixture measurements, not a guarantee for every real survey.

## Frozen scope and correctness

Source: `502e65e86651720e46bb1dd035cec35c67355bb9`, also recorded in the
development evidence's `source-commit.txt`. Compiler revision 1, fixture revision
3, optimized release executable.
Binary SHA-256:
`9fd99be5f3c61d852bdd4c5c652bb6c92434e0e67c95e09e207f2cd6bae47e4b`.
The embedded stamp reads `70628fe-dirty`, sampled before the discovery-fix commit
was made; no source files changed between that build and the valid measurements.

Hardware: 32 logical CPUs; NVIDIA GeForce RTX 4070 Ti and AMD Radeon(TM) Graphics,
both through Vulkan; cache scratch on a WD_BLACK SN850X HS 2000GB NVMe volume.
Known NVIDIA PCI address `0000:01:00.0` was unique. AMD's Vulkan PCI field was
empty, but its physical-device entry and vendor/model were distinct.

Sparse and dense 1024×1024 fixtures each completed all 18 configurations: worker
allowances 1, 8 and 32; CPU queues 1/2/3; CPU plus each GPU; CPU plus both GPUs.
Every configuration completed a first observation and five warm six-build
cohorts. A second sparse run also completed. The 2048 sparse fixture completed
four configurations; CPU-three-queue and all-GPU cases were explicitly
unavailable because three artifact sets exceeded the 256 MiB scratch cap.

Every timed job used native point-cloud decoding, real cache writers, manifest
publication, reload and isolated index insertion. Raw DSM/DTM matched the CPU
reference within 1 mm; masks, support, obstruction and density matched exactly;
decimated ground matched within 1 mm. GPU jobs included upload/dispatch stages,
and every cohort published each requested job exactly once. The scratch root was
empty after completion. The experiment bypasses application survey acquisition
and SurfacePlan orchestration; it never writes production calibration.

## Complete cohort timings

Median seconds for six builds at 32 CPU workers, five warm observations:

| Execution | Sparse 1024 | Dense 1024 |
|---|---:|---:|
| CPU, one queue | 0.689 | 2.411 |
| CPU, two queues | 0.426 | 1.695 |
| CPU, three queues | 0.350 | 1.104 |
| CPU + NVIDIA, two queues | 0.483 | 1.766 |
| CPU + AMD, two queues | 0.469 | 1.747 |
| CPU + both GPUs, three queues | 0.363 | 1.176 |

Three CPU queues reduced these medians by approximately 18% for sparse and 35%
for dense surfaces compared with two CPU queues. At one CPU worker, sparse mixed
execution showed small median gains but overlapping ranges; dense mixed
execution was slower. At eight workers, three CPU queues matched or beat mixed
execution. No GPU combination satisfied the conservative improvement gate at any
tested allowance. Comparisons include the fastest CPU-only configuration at that
allowance, not merely the CPU baseline with fewer queues.

For sparse 2048 grids, two CPU queues had a 1.50 s median; CPU+NVIDIA had 1.69 s
and CPU+AMD had 1.62 s. Both individual GPU comparisons were admitted after idle
GPU buffers were released, preventing order-dependent device-budget failures.

## CPU, GPU and storage interpretation

Dense builds averaged about 0.41 s in the decode/reprojection span per job. CPU
finishing was small; GPU jobs added upload, dispatch/readback and mandatory CPU
evidence replay. Dense CPU cohorts consumed roughly one core per active build:
about 1.0, 2.0 and 2.7 cores for one, two and three queues despite the 32-worker
allowance. Raising the per-build thread allowance alone did not remove that
serialized work. Stage spans overlap and are not exclusive CPU-time percentages.

Dense six-build cohorts reported about 39 MiB of process read traffic. Physical
NVMe reads were mostly served from cache: the dense run's largest sampled read
rate was under 4 KiB/s. Its disk queue averaged 0.0045 and peaked at 0.0072;
average transfer latency was about 61 microseconds. Across the valid sparse and
large-grid runs the largest sampled queue was below 0.025. There was no observed
physical-disk queue buildup during these warm fixtures. These buffered runs do
not establish performance on cold survey files or prove NVMe cannot limit other
workloads. Process I/O includes device traffic and is not disk-only accounting.

NVIDIA utilization and Windows per-process GPU-engine counters were captured
alongside physical-disk telemetry. Samples cover setup and CPU-only intervals as
well as GPU cohorts; their whole-run average is not a GPU throughput comparison.
Complete cohort times and verified queue work determine the recommendation.

## Next implementation priorities

1. Extend the CPU build-slot sweep beyond three, respecting native codec,
   retained-context, raster, encoder and publication peaks. Measure larger
   cohorts and representative cached surveys before widening production's
   two-job pipeline. Keep cancellation and frozen surface-context semantics.
2. Investigate parallel decode/reprojection where profiles show it dominates.
   Share the CPU budget across builds and inner work rather than creating a full
   thread pool for every tile. Keep GPU finishing opt-in unless matching
   full-path measurements justify it on the user's hardware.
3. For Site Finder, compare the same Fast approximation across devices using the
   [Fast Site Finder compute benchmark](site-finder-fast-benchmark.md).
   Do not mix full CPU ITM scores with the current GPU approximation.

## Evidence and validation

Development evidence is retained under `.feature-work/mixed-device/`: valid raw
JSON, per-run binary hashes, source identity, progress logs, NVIDIA CSV, Windows
counter JSONL and derived summaries. `sparse1024-repeat*` is a second sparse run;
it was initially named dense before a missing harness flag was corrected.
`invalid-discovery-*` is excluded: DirectX returned a duplicate NVIDIA adapter
and those mixed-device observations were not physical multi-GPU measurements.

Queue regressions failed before implementation and passed afterward. The
physical-PCI deduplication regression also failed before the correction and
passed afterward. Final `cargo test`: 2,175 library tests passed, 32 ignored;
other test targets and doc-tests passed with zero tests. `cargo check`, format
and strict all-target/all-feature Clippy passed. Hardware runs validated both
GPU compilers through full publication parity, independently of compilation.
