# Mixed CPU and GPU benchmark experiment

The desktop [computer benchmark](../how-to/benchmark-this-computer.md) measures
individual devices. The `lidar_mixed_bench` development example tests whether
adding one or more GPUs improves total surface-build throughput on a particular
computer. It does not change the application's selected GPU or saved calibration.
See the [development-computer qualification](mixed-device-qualification.md) for
measured results and their limits.

Run from a RidgeCast source checkout, with other calculations and builds stopped:

```powershell
cargo run --release --example lidar_mixed_bench -- --cache-directory D:/ridgecast-cache --workers 1,8,32
```

It prefers Vulkan hardware enumeration, deduplicating known physical PCI
addresses. If Vulkan has no hardware adapters, it tries DirectX, Metal and OpenGL
in order. It uses that single backend, avoiding duplicate Vulkan
and DirectX representations of a card. Software adapters are excluded. Use
repeatable `--adapter SUBSTRING` filters to select a subset, or `--cpu-only`.
Adapters that cannot initialize are reported as unavailable. Identical physical
cards with different Vulkan PCI addresses remain separate queues even when their
names match. Repeated same-model fallback adapters have ambiguous physical
identity and are explicitly unavailable rather than counted as extra GPUs. This tests
all hardware GPUs exposed by that backend; a card exposed only through a different
backend may be omitted. Cross-backend physical-card matching is not implemented.

The default fixture is a sparse 1024×1024 surface with six builds and five warm
observations. `--dense`, `--side 256|1024|2048`, `--jobs 6..128`, `--trials 5..15`
and `--budget-seconds 600` control the experiment. Worker counts are clipped to
available CPU parallelism and 64. Test several allowances: a machine with a
different CPU-to-GPU balance can choose differently.

CPU-only cohorts use one through the maximum admitted build-slot count. Mixed
cohorts use one CPU queue plus a queue per selected GPU, with the same CPU worker
pool as the corresponding CPU-only cohort. Fast queues claim more work; each
queue starts a job. Check actual job counts in each observation to see whether a
slow GPU contributes enough to compensate for its CPU and transfer costs.

All configurations share a 2 GiB host budget, a conservative aggregate 256 MiB
device-buffer budget and a 256 MiB scratch-file cap. Each slot receives an equal
host allowance. Scratch combinations that cannot fit are explicitly unavailable,
not silently measured with lower concurrency. Publication writes the real
obstruction, decimated-ground, density, support and manifest files, reloads them
and checks all planes against a populated CPU reference. Scratch files are owned
by a temporary directory; completed runs remove it. No survey download is needed.

JSON on stdout contains adapter identities, fixture checksum, build identity,
storage scope, actual workers/slots, first observations, complete warm cohorts,
per-queue job counts, individual stage spans and unavailable reasons. Progress
goes to stderr. Order rotates between observations. Inactive GPU buffers are
released between cohorts so an idle card cannot prevent another card's memory
admission. Kernels and OS cache can be warm while a card's buffers need allocating
again. Compare the slowest mixed
observation with the fastest CPU-only observation across the available worker
counts and concurrency levels. A small or noisy median gain is insufficient
evidence to enable production routing.

First observations are not physical cold-cache measurements. The budget is
checked between complete cohorts; fixture setup, device initialization and the
last admitted cohort can extend total runtime. Windows process counters report
CPU seconds and process I/O bytes, including file and device traffic. They do
not establish physical NVMe saturation or GPU utilization. Other platforms
report these optional counters as unavailable. Stage spans overlap and must not
be added to wall time. Use a hardware monitor alongside the experiment if GPU
busy time or physical disk activity is needed.

## Site Finder model requirements

Current CPU and GPU Site Finder evaluation both use 360 rays and 64 terrain
points. CPU evaluation invokes the captured propagation model, including full
configured ITM. The GPU shader combines free-space loss, up to three diffraction
edges and a two-ray floor. It does not implement full ITM, and its existing test
tolerances do not establish score equivalence. Terminal height conventions can
also differ under clutter.

A future mixed-device Site Finder must use the same model and terminal
conventions for every candidate in a ranked set. A CPU reference for the GPU
approximation would permit comparable CPU/GPU scores, while retaining an explicit
approximate mode. Another experiment could screen on GPUs and rescore a broad
shortlist with CPU ITM; shortlist recall must be measured against exhaustive CPU
evaluation, since approximate screening can omit strong full-ITM candidates.

A full-quality GPU ITM implementation needs the complete horizon, terrain
irregularity, line-of-sight, diffraction, troposcatter and variability algorithms,
plus supported environment settings and error/warning behavior. Validate it
against the local C++ implementation across propagation regimes and threshold
boundaries. The [official NTIA ITM](https://github.com/NTIA/itm) examples provide
cross-checks; they are not comprehensive validation. This benchmark does not
implement or enable a new Site Finder model.
