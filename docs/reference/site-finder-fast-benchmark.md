# Fast Site Finder compute benchmark

Run `cargo run --release --example site_mixed_bench -- 32 5` to compare the
versioned Fast approximation at several CPU worker allowances, with CPU alone
and with each available GPU or all available GPUs. This offline synthetic
fixture uses 360 rays and 64 profile points per candidate. Each configuration
warms once before the requested measured cohorts.

The benchmark includes input packing, dynamic batch scheduling, approximate CPU
evaluation and GPU upload/readback. It excludes terrain and land-cover loading,
origin sampling, candidate scoring, result publication, adapter initialization
and UI. A compute-stage speedup is not a measured whole-scan speedup.

GPU loss must match the f32 CPU reference within 0.01 dB on the fixture before
timing is admissible. Site Finder additionally uses the CPU approximation near
grade boundaries to keep tiny device rounding differences from changing grades.
Full quality is a separate CPU calculation using the captured propagation model;
this experiment never measures approximation as full ITM.

The rows report worker allowance, device combination, median/minimum/maximum
milliseconds and completed work. CPU fallback must be identified rather than
counted as successful GPU evaluation. Measurements depend on the CPU/GPU ratio,
candidate count, batch size and terrain profile. They do not calibrate the
application's Fast estimate or change automatic model selection.

Discovery uses one compute backend, preferring Vulkan, to avoid counting the
same physical card through several APIs. Only hardware adapters exposed by that
backend are available in this version. Ambiguous duplicate identities and
failed adapter initialization are reported as unavailable.

## Development-computer measurements, 2026-10-08

Ryzen 9 9950X (16 cores, 32 logical processors), RTX 4070 Ti and integrated AMD
Radeon Graphics, both exposed through Vulkan. Thirty-two candidates, one warmup
and five measured trials per configuration: 35 configurations and 175 measured
trials. No competing compiler or RidgeCast process was present at the preflight
or final check. All trials had zero CPU fallback and maximum CPU/GPU loss
difference below 0.0001 dB.

| CPU workers | CPU-only median (ms) |
| --- | ---: |
| 1 | 143.247 |
| 4 | 38.193 |
| 8 | 21.601 |
| 16 | 16.245 |
| 32 | 17.266 |

| Devices, 32-worker allowance | Median (ms) |
| --- | ---: |
| NVIDIA GPU | 2.946 |
| AMD GPU | 11.898 |
| Both GPUs | 3.315 |
| CPU + NVIDIA | 3.021 |
| CPU + AMD | 7.956 |
| CPU + both GPUs | 3.480 |

This small compute fixture favors the discrete GPU alone. Giving a slower device
an initial batch can extend the final batch tail, so adding every device does
not guarantee lower latency. The CPU + both-GPU compute result is about 4.7 times
faster than the best CPU-only configuration here; this excludes preparation and
scoring and is not a measured whole-scan speedup. Wider worker/batch/input sweeps
and full-pipeline calibration remain necessary before choosing a preferred
device combination automatically.

Raw cohorts, CSV, source hashes and the frozen tested executable are retained in
the checkout's ignored `.feature-work/site-finder-mixed/` evidence directory.
The benchmark binary SHA-256 is
`0da2b15c28c9bc6cf6ad2ad5d92cbea337c31b6cf28544c8929fc2343d581bc5`.
The measured source was the isolated dual-mode implementation based on d72b9448;
the metadata records exact hashes, including the production approximation and
shader. Its build identifier predates the integration commits.

See [the Site Finder workflow](../how-to/find-and-validate-a-site.md) and
[computer calibration](../how-to/benchmark-this-computer.md).
