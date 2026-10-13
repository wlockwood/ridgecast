# Benchmark this computer

Open **Settings → Performance & Calibration**, or **Benchmark this computer…**
under **Tools**, Coverage or Site Finder. This application-wide service shares
computation estimates between both tools and saves successful measurements across restarts.
Closing a tool or the benchmark window does not cancel benchmarking.

Select **Propagation**, **LiDAR preparation**, or both, then choose **CPU**,
**GPU**, or both and **Quick · ~30s** or **Extended · ~2min**.
Finish other calculations first, then press **Start benchmark**.
The window names any running network link, Coverage or Site Finder calculation
that prevents benchmarking. **Show calculation progress** or **Show Site Finder**
opens its progress without closing the benchmark window. Start becomes available
when those calculations finish; **Cancel benchmark** appears only while a
benchmark is running. A completed Coverage run's additional-terrain offer does
not count as running computation, but its **try again** action waits until the
benchmark finishes or is canceled.

Workload families and backends run sequentially, with setup and warmup excluded
from measurement.
A selected family receives the whole budget; selecting both splits it between
them. Setup and an admitted batch can extend the approximate duration.
**Cancel benchmark** preserves the
previous successful calibration. Canceled/failed runs do not replace it. New
network calculation requests cancel calibration to avoid publishing results
distorted by competing application work.

Real engine jobs evaluate local synthetic hills, without terrain downloads.
CPU workloads include normal Vertex Grid and Radial Sweep Coverage and supported
Site Finder evaluation. GPU measures Site Finder's 360-ray/64-point workload on
the initialized adapter. Normal full Coverage remains a CPU workload. GPU requires
compatible settings. Complete P.1812 Coverage can be measured although its
Site Finder compatibility evaluator is unsupported.

Each workload measures **3, 5 and 10 km** ranges. Coverage pairs those with
**50, 100 and 200 m** grids; the radial fixture uses **10°** angular steps.
Saved records contain individual probes and a derived envelope. Rates pool
completed work units and measured time, excluding warmup. Work units differ by
family, so displayed rates are not direct speed comparisons. Batch spread is
observed variation, not a statistical confidence interval.

Benchmark calibration requires matching hardware, executable build, model
settings, workload and supported geometry inside the measured scope. Other
objectives, clutter or extrapolated geometry can use measured rates as a **rough
baseline**. Measured surfaces or missing calibration use fallback estimates.
Site Finder's Full quality CPU action uses its compatible CPU range. Fast uses
a separate approximation across CPU workers and available GPUs; the existing
single-device calibration does not qualify that mixed workload.
Developers can compare the matching approximation using the offline
[Fast compute benchmark](../reference/site-finder-fast-benchmark.md), whose
results exclude terrain preparation and candidate scoring.
Coverage also retains estimates
learned from completed calculations. Downloads, cold caches, data preparation,
other software and cached-result reuse can change elapsed time.

## LiDAR preparation

Keep **CPU** selected for the comparison baseline. RidgeCast generates compressed
local point clouds with known ground and roof returns, then uses its production
compiler, cache writers and readers. No survey download or developer dataset is
needed. LiDAR GPU comparisons do not depend on the selected propagation model.

Measurements distinguish 256×256, 1024×1024 and 2048×2048 grids at 0.9144 m,
sparse/dense returns, isolated builds and six-build cohorts. Quick measures one
worker and the captured CPU allowance on classes that fit its budget. Extended
also tries 4, 8 and 16 workers, clipped to that allowance. The allowed count is
bounded by available CPU parallelism and 64. Large cohorts use the same bounded
production scheduler; the results state whether one or two slots were admitted.
Unmeasured combinations remain unavailable.

The CPU and GPU ranges include decoding, required CPU support work, transfers,
the actual obstruction and decimated-ground cache layout, density/support
encoding, manifest publication, reload and index insertion. First-use samples
are separate from warm samples. **Stages and storage details** shows the adapter,
volume scope, unavailable reasons and individual stages. Stages may overlap and
must not be added to complete wall time.

Automatic GPU selection needs at least five complete paired trials and a
conservative improvement of 15%, comparing the fastest measured CPU time with
the slowest GPU time. It also requires matching build, hardware, worker allowance,
grid, return density, execution slots and storage scope. A strong CPU or a smaller
GPU may therefore favor CPU. Missing, noisy or unmatched measurements stay CPU.
A first build with unknown return density uses the captured CPU allowance for
decoding. Its finishing step can use GPU after identifying the class if that
isolated scope qualifies. Matching later builds can also select a measured
worker count; unknown classes keep rough or absent estimates. GPU failures
visibly fall back to CPU; canceled work does not become calibration.

Storage diagnostics create at most 256 MiB of temporary files on the active cache
filesystem and remove their own scratch directory afterward. They compare memory
copies, large and many-small-file reads, buffered writes, and verified zstd-3/9
envelopes containing elevation and support samples. The test does not change the
production compression policy. Reopened reads are **warm** or **cache state
unknown**; the OS cache is not flushed. These are file API measurements and do
not prove physical NVMe saturation. Unknown volume identity makes storage-scoped
calibration usable only in the current session.

CPU identity, GPU adapter/driver identity, workload, settings and fixture version
scope saved calibration. Updating RidgeCast or changing those inputs can make
older records inapplicable. Run again for fresh measurements. Synthetic benchmark
results estimate computation time; they do not establish RF prediction accuracy.

Return to [Site Finder](find-and-validate-a-site.md) or
[Coverage](generate-and-export-coverage.md) to use the estimates.
