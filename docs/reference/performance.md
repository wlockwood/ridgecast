# Performance and optimization

RidgeCast improves performance by reusing completed work, sharing decoded data,
running independent jobs concurrently, and using GPU compute where the complete
workload benefits. Full quality CPU propagation remains available independently
of the faster approximation.

Today, LiDAR preparation uses one or two build slots and selects GPU finishing
only when matching saved calibration qualifies it. Full quality Site Finder uses
CPU; Fast uses CPU plus the available GPUs with a matching approximate model.
These are the current application choices; the experiments below also test
configurations that production does not select.

Here, **LiDAR compilation** means converting point returns into surface-height
and ground-height rasters and their cached supporting files, the work shown as
"Building LiDAR surfaces." A build queue/slot permits one independent build to
run at a time. **Fast** is an approximate radio-loss calculation; Full quality
uses the selected propagation model. Their mechanisms are explained below.

This page describes the implemented optimizations and the development-computer
measurements recorded on **2026-10-08**. The measurements use synthetic inputs;
they do not predict every survey or measure RF accuracy. Detailed benchmark
reports linked below retain the tested scope, source identity and validation.

## Measured differences

The development computer has a Ryzen 9 9950X with 16 cores / 32 logical processors,
an NVIDIA RTX 4070 Ti, integrated AMD Radeon Graphics, and a WD_BLACK SN850X NVMe.
Both GPUs were exposed through Vulkan. Timings below are medians of five warm
trials after an initial observation or warmup. Smaller times are better.

### Fast Site Finder compute

This comparison evaluates the **same Fast approximation** on every device:
32 candidates, each with 360 rays and 64 terrain-profile points. The timed work
includes input packing, scheduling, propagation, GPU transfers and readback. It
excludes terrain/land-cover loading, origin sampling, candidate scoring, result
publication, adapter initialization and UI.

The CPU worker allowance configures the approximate CPU evaluator, including its
fallback pool. During successful execution, "GPU only" assigns no candidates to
CPU propagation; CPU still packs inputs, schedules work and manages transfers.
A device failure may retry propagation on CPU. The allowance is a limit, not a
claim that all those workers were busy.

| Execution | CPU worker allowance | Median time (ms) |
| --- | ---: | ---: |
| CPU only | 1 | 143.247 |
| CPU only | 4 | 38.193 |
| CPU only | 8 | 21.601 |
| CPU only, best measured CPU configuration | 16 | 16.245 |
| CPU only | 32 | 17.266 |
| NVIDIA GPU only | 32 | 2.946 |
| AMD GPU only | 32 | 11.898 |
| Both GPUs | 32 | 3.315 |
| CPU + NVIDIA | 32 | 3.021 |
| CPU + AMD | 32 | 7.956 |
| CPU + both GPUs | 32 | 3.480 |

For this fixture, CPU + both GPUs completed compute **4.7 times faster** than the
best CPU-only configuration (16.245 / 3.480). NVIDIA alone was fastest, about
**5.5 times faster** than that CPU baseline. All 175 measured trials across 35
configurations had zero GPU-to-CPU fallback; the maximum CPU/GPU loss difference
was below 0.0001 dB, where dB is the decibel unit used for radio loss.

These are compute-stage results, **not measured whole-scan speedups**. If loading
and scoring take most of a real scan, faster propagation improves only the
remaining portion. This also does not compare Fast with full CPU ITM: those use
different propagation models. See the [Fast compute benchmark](site-finder-fast-benchmark.md).

### Complete LiDAR compilation experiment

Each trial builds six 1024×1024 surfaces with a 32-worker CPU allowance. Times
include native compressed-point decoding, coordinate projection, raster
finishing, required CPU evidence work, cache encoding/writes, manifest
publication, reload and index insertion. Downloads and application-wide surface
planning are excluded. Sparse and dense fixtures contain different numbers of
returns per cell.

| Execution | Concurrent build queues | Sparse median (s) | Dense median (s) |
| --- | ---: | ---: | ---: |
| CPU only | 1 | 0.689 | 2.411 |
| CPU only | 2 | 0.426 | 1.695 |
| CPU only | 3 | 0.350 | 1.104 |
| CPU + NVIDIA | 2 | 0.483 | 1.766 |
| CPU + AMD | 2 | 0.469 | 1.747 |
| CPU + both GPUs | 3 | 0.363 | 1.176 |

Three CPU queues reduced median elapsed time by **18% for sparse surfaces and
35% for dense surfaces** compared with two. No tested GPU combination met the
conservative 15% improvement requirement against the strongest measured CPU-only
configuration at its worker allowance.

That experimental recommendation compares against the best CPU-only queue count,
including three queues. Production's automatic selection is narrower: CPU/GPU
calibration must have matching execution slots, currently one or two. Even with
two queues on both sides, the dense GPU combinations above were slower than
CPU only (1.766 / 1.747 seconds versus 1.695 seconds).

The three-queue result is an **experiment**, not a shipped three-slot setting.
Production preparation currently admits one or two simultaneous builds according
to memory and execution constraints. Some larger experimental combinations were
unavailable because they exceeded the benchmark's scratch limit. See the
[complete qualification report](mixed-device-qualification.md).

## Why low utilization can accompany a long wait

A surface build has several stages with different resource needs. Reading and
decompressing points, projecting coordinates, filling rasters, transferring GPU
buffers, encoding files and publishing results do not all run simultaneously.
Speeding up one stage helps only its share of elapsed time.

CPU utilization is usually averaged over logical processors. One fully occupied
logical processor on a 32-processor machine accounts for roughly 3% overall;
serialized decoding can therefore be busy while the total looks low. The dense
LiDAR experiment used about 1.0, 2.0 and 2.7 CPU-time equivalents with one, two
and three build queues despite allowing 32 workers. This is process CPU seconds
divided by elapsed seconds: 1.0 corresponds to one continuously busy logical
processor, not a count of physical cores. Decode/reprojection averaged about
0.41 seconds per dense build; adding workers within a build did not remove that
serialized stage.

A GPU utilization number also needs its engine and time interval. Rendering,
compute, transfers and CPU-only periods can appear in different counters. A
30% GPU reading alone cannot identify the stage delaying surface preparation.
The useful comparison is completed, verified work per elapsed second.

### Can NVMe still be the limiter?

Yes, particularly with cold files, many small files, snapshots, writes or
competing activity. A fast drive does not eliminate file-system overhead or CPU
decompression, and memory limits can prevent enough concurrent work to saturate
the drive.

The measured warm LiDAR fixtures did **not** show queue buildup on the monitored
NVMe.
Dense cohorts reported about 39 MiB of process read traffic, but the largest
sampled physical NVMe read rate was below 4 KiB/s because the operating system
served most reads from memory. Windows' average disk queue-length counter counts
outstanding requests averaged over each one-second sampling interval. For the
dense run, those samples averaged 0.0045 requests and the highest sample was
0.0072; fractional values mean the disk had no outstanding requests for most of
the interval, rather than a queue of fractional requests at an instant. Average
transfer latency was about 61 microseconds. These warm results do not establish
cold-survey performance. Process I/O counters also include device traffic and
cannot be treated as physical disk reads.

## Optimizations in the application

The mechanisms below are implemented. The tables above quantify only their
stated benchmark scopes; the other benefits have no whole-workflow speedup
measurement recorded here.

### Reuse results before starting expensive preparation

Persistent per-node Coverage grids let unchanged nodes reuse previous
calculations, including across application restarts. Each node's grid resolution
depends on that node rather than the selected group, so adding a distant node
does not invalidate every existing grid. Cache checks precede expensive terrain
and LiDAR preparation. Persistent network-link results similarly avoid repeating
unchanged link evaluations.

Reuse requires matching radio/model inputs and source identity. Surface changes
invalidate incompatible results. If Coverage used land-cover categories in place
of requested measured LiDAR, a later calculation must retry LiDAR rather than
treat that fallback as permanent. This reduces both compute and disk work while
preserving the meaning of a cached prediction. See
[data sources and caches](data-sources-and-caches.md).

### Share decoded rasters and freeze each calculation's inputs

Site Finder retains the managed terrain and land-cover decoded caches instead
of creating another full working set for each scan. Refinement retains the scan's
captured source and radio assumptions. Shared surface contexts also retain the
prepared rasters needed by their calculation, with memory accounting that counts
shared buffers once.

This avoids repeated decompression and allocation and reduces disk reads. It
also keeps settings changes from silently changing an existing scan's radio and
source configuration. Site Finder captures its water geometry and existing
coverage baseline: water polygons arriving afterward affect a new scan, rather
than rewriting the current scan or its refinement. These retained scan inputs
are separate from cache-validity checks for a new calculation. Decoded cache
misses and large data preparation still cost time and run on workers.

### Stream and overlap LiDAR builds within a memory budget

The native compiler decodes points in bounded chunks rather than retaining the
entire point cloud. Independent surface builds can overlap in a one- or two-slot
pipeline, allowing another build to make progress during serial work. Admission
includes retained rasters, codec buffers, finishing scratch and output encoding;
a large build can reduce concurrency to one slot.

CPU worker pools are reused. Build slots and workers inside a build are separate
resources: a 32-worker allowance does not mean 32 simultaneous decoders. This
explains both the low aggregate CPU utilization and why increasing independent
CPU queues helped the experiment. Widening production beyond two slots requires
further memory and representative-survey qualification.

### Accelerate LiDAR finishing without discarding evidence

The GPU compiler accelerates numeric raster finishing, including surface/ground
filling and bounded interpolation. Point decoding and coordinate projection
remain CPU work. GPU upload/readback, cache compression and publication remain
part of the complete job.

CPU replay repeats the filling/interpolation decisions on the already decoded
rasters. It reconstructs which neighboring cells support each filled cell,
support distances, missing-data masks and reference elevations; it does not
decode the point cloud again. GPU heights alone do not preserve the distinction
between measured returns and inferred ground: an interpolated gap must not
become observed ground and bypass the chosen ground-evidence policy. GPU results
must preserve missing-data masks and stay within the compiler's qualified 1 mm
elevation tolerance. Encoded obstacle heights used for clutter must also remain
consistent. Failed or unsupported device work falls back to CPU. On this machine
the finishing stage was too small to offset transfers and required CPU replay.

To supply calibration, open **Settings → Performance & Calibration**, select
**LiDAR preparation**, keep **CPU** selected, include **GPU** when available,
and start the benchmark after other calculations finish. Successful benchmark
records feed automatic selection for matching production builds; ordinary
calculations do not automatically run this comparison experiment. **Stages and
storage details** shows measured scopes and unavailable reasons, while LiDAR
build progress identifies the active backend/stage when available.

Automatic GPU use requires at least five matching complete paired trials and a
15% conservative advantage, comparing the fastest CPU time with the slowest GPU
time. Hardware, build, worker allowance, grid, return density, execution slots
and storage scope must match. RidgeCast checks these scopes automatically: build
means executable identity; grid includes dimensions and cell spacing; return
density uses supported sparse/dense classes based on accepted return counts.
The current probes cover square 256/1024/2048 grids at 0.9144 m spacing. Other
geometry or an unknown density class does not qualify. Result details show the
measured scopes, rather than a complete explanation of every production mismatch.
Unmatched or noisy measurements keep CPU execution.
This allows a different CPU/GPU ratio to produce a different decision without
assuming the development computer's result applies everywhere.

### Keep Full quality and Fast Site Finder separate

**Full quality (CPU)** evaluates the captured propagation model, including full
ITM when selected. **Fast (CPU + GPUs)** uses a separate versioned approximation:
free-space loss, up to three knife-edge diffraction contributions and a two-ray
loss floor. CPU workers and GPUs run matching Fast arithmetic. A Fast scan never
mixes full ITM scores with approximate scores, and choosing Fast does not change
the Full quality evaluator.

Fast has a shared CPU worker pool and an independent queue for each initialized,
distinct GPU exposed by the selected compute backend. Discovery prefers Vulkan
and avoids counting the same physical card through several APIs. CPU work claims
one candidate at a time; GPU queues claim batches of eight. Each queue claims
more work as it finishes, which adapts allocation to device throughput without
assuming a fixed CPU/GPU ratio.

Completed batches publish promptly; final tie ordering remains stable. Near
quality-grade boundaries, the matching CPU approximation resolves tiny GPU
rounding differences. Device failures retry the same sampled batch on CPU using
the same approximation. Unsupported Fast settings leave Full quality available.

Dynamic allocation cannot remove the last slow batch already claimed by a
device. The 32-candidate benchmark therefore favored the discrete GPU alone;
using every CPU core and GPU does not guarantee the shortest elapsed time.
Production Fast currently uses CPU plus available GPUs; automatic selection of
the best device combination still needs wider and whole-scan benchmarks. See
[Site Finder choices and limitations](../how-to/find-and-validate-a-site.md).

### Keep progress and interactive ranking off the critical UI path

Site Finder publishes immutable chunks of results through a mailbox retaining
the latest update, avoiding a growing backlog when workers outpace display.
The UI receives shared chunk handles rather than copying every candidate row.
Neighborhood/Jealousy changes recompute ranking from retained base scores on
workers, without repeating propagation. Superseded jobs check cancellation and
discard obsolete publications.

These changes improve responsiveness and avoid wasted work; they are not
additional measured propagation speedups.

### Calibrate complete workloads and explain benchmark blockers

**Settings → Performance & Calibration** is also reachable through the benchmark
actions in Tools, Coverage and Site Finder. Active link, Coverage or Site Finder
calculations block calibration; the dialog names the blocker and offers enabled
navigation to its progress. This avoids timing competing application work while
leaving the user a useful action.

Propagation and LiDAR are measured separately. LiDAR measurements include cache
writes, reload and publication, rather than timing only a shader. Bounded storage
diagnostics compare file operations and compression without changing production
compression policy or claiming to flush the OS cache. Hardware/build/model keys,
worker sweeps and recorded unavailable combinations prevent unsupported
extrapolation. The existing single-device propagation calibration does not yet
qualify Fast mixed-device whole-scan estimates. See
[benchmark this computer](../how-to/benchmark-this-computer.md).

## Calibration file and selection rules (for maintainers)

Source: `src/performance.rs`, `src/performance/lidar.rs`.

### `performance-calibration.json`

Saved benchmark results live in `performance-calibration.json` in the per-user
configuration directory, written atomically. It is a version 1 envelope around
two lists:

- `measurements` — propagation calibrations, one per (machine, backend, work
  family, fixture version, propagation settings). A work family is Coverage ·
  Vertex Grid, Coverage · Radial Sweep, or Site Finder (complete 360-ray,
  64-point candidates). Coverage units and Site Finder candidates are never
  interchangeable.
- `lidar_measurements` — LiDAR probes (below).

Limits: the file must be 1 MiB or smaller, with at most 128 propagation
measurements and 64 LiDAR probes; a larger or newer-version file is rejected with
an error and the app keeps working without calibration. When saving would exceed
1 MiB, the oldest measurement of either kind is dropped until it fits.

On load, records from another machine are discarded (machine identity is the
computer name, CPU identifier, logical processor count, and a build string that
includes the version, git hash, OS, architecture, debug/release and a SHA-256 of
the executable, so any new build starts without calibration). LiDAR probes that
carry no storage identity are kept only for the session that measured them.

A propagation record is trusted only if it passes strict checks, because the
file is user-editable: the fixture version matches (currently 2); it contains
exactly the three fixed probes for its family (3 km at 50 m grids, 5 km at 100 m,
10 km at 200 m; Site Finder probes have the ranges but no grid); each probe and
the total ran for at least 0.1 s with finite, positive, plausible rates (at most
10^12 units/s); the totals equal the sums of the probes; and the stored
range/grid envelope equals the probes'. A record that fails is ignored, not
repaired.

Benchmark time budgets are 30 s (Quick) and 120 s (Extended), split evenly
between the selected workloads.

### LiDAR probes and CPU/GPU selection

A probe is one measured workload class: grid side (256, 1024 or 2048 cells),
spacing, sparse or dense returns, cohort of 1 or 6 jobs, one or two pipeline
slots, worker count (1 to 64), GPU adapter name, storage identity, warm or
first-use, compiler version (currently 1) and fixture version (currently 3). It
holds up to 15 trials; each must have been correctness-verified against the CPU
reference and have finite, positive times. Quick runs gather 5 warm trials per
probe and Extended runs 7.

`select_lidar_execution` is deliberately conservative and uses no vendor or
utilisation heuristic:

1. Only probes that are valid, from this exact machine and build, measured with
   a worker count no larger than the current allowance, and matching the work's
   side, spacing, density class, cohort size (6 when six or more jobs remain,
   else 1), pipeline slots and storage identity are considered. Unknown density
   gives CPU and the reason `UnknownWork`.
2. The **CPU choice** needs at least **5 warm trials**, and a probe measured at
   the current worker allowance must exist; among qualifying probes the one with
   the lowest median CPU time sets the worker count and the time estimate
   (median, minimum and maximum scaled by the remaining jobs per cohort). Without
   it, the decision is `InsufficientEvidence` and the allowance is used.
3. The **GPU choice** also needs the work's adapter to match, the probe's warm
   state to match whether the device is ready, at least 5 trials that all have a
   GPU time, and **fastest CPU time over slowest GPU time of at least 1.15** (a
   15% margin). The fastest CPU time is taken from every matching warm probe,
   even one with fewer than 5 trials, so partial observations can veto a GPU
   gain. If several GPU probes qualify, the one with the lowest median GPU time
   wins. No adapter gives `DeviceUnavailable`.
4. **At run time** a batch's GPU use is suspended for the rest of the batch on
   any GPU failure or fallback, or once the median of the last 5 GPU completions
   is slower than the slowest qualifying CPU trial. Runtime observations never
   become calibration.

### Mixed-device diagnostics

`benchmark_mixed` (`src/performance/lidar/mixed.rs`) runs separate experiment
cohorts, never used for selection: CPU-only at 1 to N slots, each adapter paired
with a CPU lane, and, with two or more adapters, every device together. Inputs
are bounded: grid side 256, 1024 or 2048; 1 to 128 jobs, more than the number of
adapters; 5 to 15 warm trials; 1 to 64 workers. Lane `n` starts with job `n`
and later jobs are taken from a shared counter, so faster lanes do more work.
Each record has one first-use observation plus the warm trials, per-lane job
timings, process counters, and an `unavailable_reason` when it could not run;
a failing scenario marks only its own record. The report states the host
memory limit, the aggregate device limit and scratch limit it ran under. Host
memory for builds is divided evenly across lanes.

## Further work

The measurements support testing wider CPU build-slot counts and parallel
decode/reprojection before investing further in LiDAR GPU finishing. Those tests
need representative cached surveys, cold-file measurements, memory admission
and a shared CPU budget across builds and inner loops.

For Fast Site Finder, the next measurements should vary candidate counts, batch
sizes, worker allowances and CPU/GPU combinations, and include preparation and
scoring. A full-quality GPU propagation backend would require implementing and
validating the complete model independently. Current GPU knife-edge diffraction
does not provide full ITM. CPU Full quality preserves the selected complete
propagation model; these performance measurements do not establish either
mode's real-world prediction accuracy.
