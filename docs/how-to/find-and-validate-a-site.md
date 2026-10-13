# Find and validate a candidate site

Site Finder ranks hypothetical transmitters across a search area. Use it to
build a shortlist, then validate sites with ordinary Coverage, surveyed heights
and installation/access information.

## Quick start

1. Frame the map and open **Analysis → Planning → Site Finder**.
2. Read the **Companion Guide**, then dismiss it. **Guide** reopens it.
3. **Lock current area** keeps the footprint while you pan. **Show boundary**
   fits the map to it; an unlocked scan uses the current view.
4. Choose **Scan tile radius** and **Geographic coverage / Population**.
5. Keep the **Basic transmitter / Pocket Node receiver** comparison baseline.
6. Choose **Full quality (CPU)** for the captured propagation model, or
   **Fast (CPU + GPUs)** for an approximate scan across CPU workers and available GPUs.
7. Select candidates to center the map on their evaluated origins, hover scores
   for the calculation and pin useful sites with the star.
8. Adjust **Neighborhood / Jealousy** to spread the shortlist without repeating
   propagation. Validate the selected locations with CPU Coverage.

Wide windows have controls and results side by side; narrow windows use
**Controls / Results** tabs. The window fits its visible content up to the
available screen height. Run controls remain below the scrolling panes.
Very small windows allow the whole body to scroll. Controls have explanatory
tooltips, including disabled actions.

## Search options

**Scan tile radius** is the center-to-corner hex radius, not receiver-sample
spacing. Neighbor centers are about √3 times the radius apart. Halving it creates
roughly four times as many candidates. The control follows display units and
accepts exact numeric entry.

| Quality | Radius | Automatic refinement | Land-cover clutter |
| --- | --- | --- | --- |
| Fast | 200 m | 0 levels | Off |
| Balanced | 100 m | 1 level | On |
| Detailed | 30 m | 2 levels | On |

Quality shortcuts preserve radios, objective, diversity and appearance.
**Reset search options** restores search settings while preserving radios,
live diversity and appearance.

**Geographic coverage** rewards weighted Good/Fair/Marginal samples and penalizes
unserved samples. **Population** rewards area-weighted WorldPop density with a
geographic tie-breaker. Objective changes affect the next scan.

### Grade by Population

Population exposes country readiness and **Load / Retry Population Data**.
Use a three-letter country code covering the receiver footprint, including the
evaluation range beyond the search boundary. Large country rasters take time
to download and decode. Missing data is not evidence of zero population;
candidates can record a geographic fallback. Check the saved availability note
and score hover. Population scores are ranking values, not distinct people
served: ray sectors overlap. See [data sources](../reference/data-sources-and-caches.md).

**Skip Existing Coverage** excludes receiver samples already served at the
selected fade-margin level by coverage on the map. Calculate existing nodes
first. The scan captures the coverage and cutoff as a fixed comparison baseline.

## Water

**Exclude fully water tiles** starts enabled for new searches. A candidate is
excluded only when its whole bounding footprint is confirmed as water by the
scan's frozen, detailed cached regional polygons, or by all-water cached land
cover when regional coverage is unknown. A valid regional tile with no water
polygons keeps the candidate eligible. Mixed shoreline/island footprints remain
eligible. If available fallback data cannot confirm the whole footprint, unknown
pixels, missing data and incomplete source coverage also keep it eligible.
Bundled Natural Earth outlines do not exclude candidates, and elevation alone
never proves an eligible footprint is water. Uncheck the option for intentional
offshore installations.

An online scan can request regional water asynchronously, but it captures the
geometry available for that scan and does not wait for missing water. To prepare
water detail, inspect the area while online and verify the intended viewport
before switching offline. Newly arriving polygons affect a new scan, preserving
the inputs of retained results.

Placement eligibility is independent of **Water area value**, under **Advanced
search options**. Covered water normally receives 10% positive score weight;
unserved samples keep their penalty. **Coastline attenuation** restores more
nearshore value, decaying toward the floor over **Shore falloff distance**,
normally 3 km:

`water weight = floor + (1 − floor) × exp(−distance to sampled land / falloff)`

Scoring uses land-cover classification with an elevation fallback when it is
unavailable. Review water-heavy rankings against their available source data.

## Radios and advanced options

New Site Finder settings use **Basic - Single-Story** as TX and **Pocket Node**
as RX. Pocket Node is an application-wide built-in system: **0 dBi, 1 m AGL,
22 dBm conducted TX**, 0 dB loss, −100 dBm sensitivity and derived noise figure.
It is available in old networks and normal system pickers. All newly created
systems start at **62.5 kHz** bandwidth; explicit saved values and historical
missing-field interpretations remain unchanged. See [nodes and systems](../reference/nodes-and-systems.md).

The RX node's TX power does not affect this one-way score. Ordinary Coverage
has a separate **Test Node**.

**Change radios, range or model** contains system copies, height/reference,
power, gain, loss, sensitivity, noise figure, bandwidth, azimuth, front-to-back
ratio, elevation and antenna response. System selection copies resolved inputs
without changing the network profile. **Legacy radios** restores historical
10 m TX / 2 m RX, 33 dBm EIRP and 125 kHz receive inputs. Evaluation range is
shared with Coverage; frequency and model buttons open application settings.

**Advanced search options** contains refinement, clutter, environmental noise,
placement sampling and water options. Placement supports center, average terrain,
highest point and canopy top. Average/canopy origins are model inputs, not surveyed
tower locations. Environmental noise uses a candidate-local proxy; requested
atmospheric noise is evaluated at receiving samples on CPU. These are estimates.

Keep radios, range, model, thresholds and objective consistent across comparisons.
Retained candidates keep their original inputs; **Saved scan inputs** and the
pending-settings notice expose the difference from next-scan controls. New scans
record the active sources actually captured. If a requested WorldCover import is
unavailable, the saved availability note identifies that limitation.

## Live diversity and score math

**Neighborhood** compares raw scores within a hex-step radius in each resolution
tier. Zero disables suppression. **Jealousy** controls the strength of a better
neighbor's reduction. Both update retained rankings/map on workers without RF
rescanning; changes during a scan apply at completion. **Gentler / Stronger**
adjust jealousy by 0.1. **Restore scan values** restores its original settings.
**Appearance** changes opacity/blending without changing scores.

Hover **Adjusted / Raw** for recorded contributions, sample counts, water weights,
radio margin/thresholds, actual scoring-floor range and the strongest suppressing
neighbor:

```
G = Σ good weights + 0.5 × Σ fair weights + 0.1 × Σ marginal weights − 0.1 × unserved
P = good population + 0.5 × fair population + 0.1 × marginal population
Raw = G                          (geographic objective or unavailable population)
Raw = P + 0.001 × G               (available population objective)

gap = (better raw − candidate raw) / better raw
contrast = gap + jealousy × (1 − gap)
t = 1 − hex distance / (neighborhood radius + 1)
falloff = t² × (3 − 2t)
Adjusted = raw × (1 − strongest falloff × contrast)
```

Diversity applies to positive raw scores and uses the strongest single reduction.
Unavailable receiver samples contribute zero. Weighted totals explain the actual
score; grade counts alone cannot recover it. Legacy imports without these records
state that their calculation breakdown is unavailable.

Selection follows the same candidate through ranking changes. Pin sites and use
**Shortlist** to inspect them. **Raw score** reveals the unsuppressed column.
**Fit results** fits the saved area; legacy bounds are calculated on a worker.
The selected candidate's **Score details (full calculation)** keeps the same
explanation open in the scrollable pane when a hover is too tall for the screen.

## Refine and validate

**Refine using saved inputs** scans seven half-radius children with the saved
radio/model/objective, configured sources and coverage filter. It retains earlier
tiers and the original frozen water geometry. Restore original sources or start
a new scan if those sources changed or the required water snapshot is unavailable.
Automatic refinement uses the ten best adjusted candidates of the completed tier,
deduplicating overlapping children.

Legacy imports without original inputs cannot be refined comparably. JSON saves
a coverage-filter fingerprint, not the full original Coverage array; filtered
imports need a fresh scan before refinement. A JSON file recording a water
identity does not contain its polygon snapshot; if that original geometry cannot
be reconstructed, start a new scan before refining.

The inspector copies the evaluated coordinates or creates an undoable node after
confirmation of its frozen transmitter. Legacy candidates expose their hex center
when the evaluated origin is unknown. Confirm surveyed elevation, mounting,
access and permission, then calculate ordinary CPU Coverage and links.

## Run, benchmark and save

**Full quality (CPU)** evaluates every candidate with the selected propagation
model and captured settings, including full Longley–Rice ITM. It keeps the
existing CPU model's accuracy regardless of GPU availability.

**Fast (CPU + GPUs)** evaluates every candidate using the same free-space,
diffraction and two-ray approximation on CPU workers and available physical
GPUs. It can run on CPU alone. Faster queues claim more work, accommodating
different CPU/GPU performance ratios. GPUs are those exposed by the selected
compute backend; discovery uses one backend to avoid counting the same physical
card twice. A failed GPU falls back to the matching
fast CPU calculation. This preserves the fast model; it does not upgrade some
candidates to full ITM. Fast rankings can differ from full-quality rankings.
Unsupported model, radio or atmospheric-noise inputs disable Fast with an
explanation; Full quality remains available.

Saved inputs identify the scan mode, and refinement keeps that mode. Validate
promising sites with full-quality scans, ordinary Coverage and links. Existing
CPU/GPU calibration measures different workloads; Fast does not present those
measurements as a calibrated mixed-device estimate.

**Benchmark this computer…** opens application-wide **Performance & Calibration**,
also available in Settings and Coverage. Persistent measurements serve both
tools. Read [benchmark this computer](benchmark-this-computer.md) for scope,
Quick/Extended runs and estimate limits. Terrain readiness is separate from
compute time: downloads and cold caches can add time. Scans reuse managed decoded
terrain, land-cover and population caches when their source inputs match.

Live progress uses the latest available preview, so stale intermediate views do
not accumulate while you interact with the map.

**Stop and keep results** retains received candidates and known scan inputs,
then applies current diversity. Closing Site Finder hides it and its Companion
Guide while a scan can continue. Benchmarking has an independent lifetime.
Command-line and MCP searches returning partial candidates mark the result as
stopped early; failures also include a reason. Partial output is not a completed
scan.

**Results…** provides JSON save/import, PNG export and clear. A fresh scan replaces
retained candidates, so save first. JSON retains base/refinement grids, raw and
adjusted scores, recorded calculations and original inputs. Older files remain
readable with unknown data identified honestly.

CSV/GeoJSON offer **Full results / Top 10 / Selected site** and preserve original
ranking. Selected-site identity includes resolution, so a refinement at the same
center remains a separate candidate. GeoJSON uses longitude before latitude.
PNG uses current appearance/map zoom; large images reduce zoom to fit 8192 pixels.
File dialogs and exports run on workers. Status and cancellation stay visible
below the workbench.

## Companion Guide

A **Companion Guide** is secondary, nonmodal help associated with a tool window.
It opens with Site Finder, dismisses independently and closes with its owner.
Turn off **Show guide when Site Finder opens** to opt out of automatic help;
**Guide** remains available. Dismissal lasts for that opening, while the auto-show
preference is saved. The reusable component supports the same behavior for
future tool guides.

Read [how Site Finder scores ground](../concepts/site-finder.md) for sampling
limits and model details.
