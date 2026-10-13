# Site Finder CPU and multi-GPU experiment

Status: matching CPU approximation and mixed execution are implemented in
the [approved dual-mode plan](2026-10-08-site-finder-dual-mode.md). The user requires
a complete CPU-only full-quality scan alongside the explicit mixed-device Fast
scan. Screening/recall research and full GPU ITM feasibility below remain future
experiments; neither can replace that full-quality option.

## Required invariant

Every candidate in a ranked result must use the same propagation model, terminal
conventions, captured terrain and scoring assumptions. A full-ITM CPU score and
the current GPU approximation are not interchangeable. Both Site Finder paths
already sample 360 rays and 64 points; the shader's missing ITM components are
the principal quality difference. The existing 25/40 dB obstructed/rough-profile
comparison tolerances establish neither score parity nor ranking parity.

## 1. Establish a matching approximate CPU reference

1. Freeze a standalone terrain-profile corpus containing smooth terrain, isolated
   ridges, multiple ridges, rough terrain, long paths and buried/cluttered
   terminals. Include samples near every SNR band boundary used by Site Finder.
2. Implement the existing shader's free-space, three-edge Deygout and two-ray
   formula on CPU using a clearly identified approximation. Resolve endpoint
   heights once for both backends: the current CPU clamp and GPU clutter
   subtraction differ. Keep full ITM available as its own model.
3. Compare per-path loss, SNR classifications, counts and complete candidate
   scores on identical inputs. Test all radio/noise/clutter settings supported
   by the experiment; reject unsupported combinations explicitly. A timing
   result is not admissible until the matching-model checks pass.

## 2. Benchmark matching-model execution

4. Add an offline fixture benchmark using the same CPU reference and existing
   GPU pipelines. Give each physical GPU a separate engine and work queue; use
   one bounded CPU pool for terrain preparation, approximate CPU evaluation and
   shared scoring. Enumerate a single backend initially and disclose its scope,
   following the LiDAR experiment's adapter and failure handling.
5. Compare CPU-only, each GPU, all GPUs and CPU plus GPUs at worker allowances
   1, 4, 8, 16 and the captured maximum. Vary candidate batch size and paths per
   candidate. Use matched concurrency, memory limits, frozen source/input hashes
   and at least five complete warm cohorts in alternating order. Report setup,
   upload/readback, CPU preparation, scoring and complete wall time separately.
6. Check cancellation, partial-device failure, once-only candidate publication
   and maximum host/device memory. Record each queue's completed work and
   capacity; a slow GPU should receive less work. Do not automatically enable
   production routing from a single development computer's result.

## 3. Preserve full-model ranking quality

7. Compare GPU approximate screening plus CPU full-model rescoring against
   exhaustive CPU evaluation. Sweep shortlist sizes on held-out mountainous,
   flat and coastal fixtures. Measure top-N recall and ranking changes, including
   near-cutoff candidates. Test population/water objectives and diversity
   suppression: shortlist quality must be measured against the final objective,
   not just the strongest raw RF score.
8. Keep screening and final scores separate and label their models. Freeze the
   full captured assumptions during rescoring. Cache keys and retained results
   must include the exact model and numerical implementation version. Screening
   has no guaranteed recall until a valid bound is demonstrated.

## 4. Full ITM GPU feasibility gate

9. Map the local C++ ITM implementation, including terrain horizons and
   irregularity, LOS/diffraction/troposcatter, environmental parameters,
   variability and warnings. Replace thread-local calculation state with
   invocation-local state. Evaluate portable FP32 and any adapter-supported
   native FP64 path separately; the WGSL shader is not a full ITM implementation.
10. Validate a port against the current C++ bridge across every supported
    configuration, propagation regime, invalid-input/warning status and RF
    threshold boundary. Cross-check official NTIA examples, which are not a
    comprehensive validation suite. Benchmark complete coverage after quality
    gates pass, including CPU terrain preparation and GPU transfer costs. Keep
    unsupported or unqualified settings on CPU.

See [the current mixed-device benchmark](../../reference/mixed-device-benchmark.md),
[official NTIA ITM](https://github.com/NTIA/itm) and the
[WGSL floating-point types](https://www.w3.org/TR/WGSL/#floating-point-types).
