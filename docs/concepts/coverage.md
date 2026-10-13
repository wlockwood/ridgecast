# Coverage maps: what the colors mean

*An explanation of what RidgeCast is actually computing when it paints coverage
on the map — what is at the far end of every one of those calculations, how
several nodes' coverage is combined, why the cache behaves the way it does, and
what makes a run slow. Written for someone who has never seen the code and does
not need to.*

---

## If you just want a map

The short version, before any of the theory:

1. **Place your nodes.** Coverage does not need ordinary node-to-node links to
   finish first; it evaluates each selected node against the Test Node described
   below.
2. **Select the nodes** you want coverage for — click one on the map,
   Control-click to add more.
3. In **Coverage** in the right-hand panel, set the **coverage
   direction** (TX or RX, §4), the **Coverage question** (§6), and check the **Edit test radio** (§3) —
   the imaginary radio at the far end, which sets the scale of the whole map.
4. In **Coverage**, pick the **⚡ Draft** preset for a first pass.
   The pre-flight estimate shows the cell count and an approximate calculation
   time before you commit.
5. Selection and coverage-setting changes start or update the calculation
   automatically; there is no separate Run button. Watch each node's badge for
   downloading or calculating.
6. Confirm the area looks right, then re-run at **🎯 Planning** or **🔬 Detailed**.

Coverage hover details are prepared in the background. After moving the pointer
or receiving new cells, details may briefly be absent while the current snapshot
is checked. A menu opened during that pause says **Coverage lookup updating**;
reopen it when ready. While results stream, a new chunk or palette change may
wait briefly for a hover read to finish; the existing cells remain visible and
hoverable. Node, link, Site Finder, ruler, and amateur-marker actions keep working.

Two things worth knowing before your first run: **per-site population and service
analyses need retained serving margins** (§6), while a whole-image export stats
card can work in any mode; and the first run over new ground often spends most
of its time **downloading terrain**, not calculating (§9).

---

## 1. Coverage is a link calculation, repeated

A link calculation asks about one path between two known radios. A coverage map
asks the same question tens of thousands of times, between one known radio and
**a hypothetical one at every point on a grid**, and colors each point by the
answer.

That is the whole idea, and almost everything surprising about coverage follows
from one implication of it: *there has to be a radio at the far end*. A path loss
alone is not a color. To decide whether a cell is green you need to know what
transmit power, what antenna, and what receiver is standing there.

## 2. What the colors mean

Each cell is coloured by its **fade margin**: how many decibels the arriving
signal sits above the receiver's effective noise floor. It is the same quantity
RidgeCast elsewhere calls SNR — signal-to-noise ratio — and it is measured in
decibels (dB), a logarithmic scale where every 10 dB is another factor of ten in
power.

Four bands, set under **Settings → Fade Margin Settings**:

| Band | Default threshold | What it means on the ground |
| --- | --- | --- |
| **Good** | ≥ 20 dB | Signal power is at least 100 times the effective noise floor. More headroom for unmodeled losses; field validation is still needed. |
| **Fair** | ≥ 10 and < 20 dB | Signal power is 10 to less than 100 times the effective noise floor. |
| **Marginal** | > 0 and < 10 dB | Signal power is above the noise floor but less than 10 times it. Little headroom. |
| **Poor** | ≤ 0 dB | Signal power is at or below the effective noise floor. |

These are coverage-statistics bands, not measured reliability classes. Smooth
colors are enabled by default, so visible colors blend between the thresholds.
Site Finder uses its own Good/Fair/Marginal/None counts; see
[Coverage modes](../reference/coverage-modes.md) for exact coverage boundaries.

**Zero dB does not mean "works."** It means the signal exactly equals the noise
the receiver has to hear it over. Everything the model does not know about — rain,
foliage in leaf, a tree that grew, a vehicle in the way, an antenna a few degrees
off — comes out of your margin. That is what the word *margin* is doing in the
name, and it is why the Good band sits at 20 dB rather than at 1.

Raising these thresholds makes the whole application more conservative at once:
they color links on the map, grade Site Finder's results, and set the SNR bands
in GIS exports too.

Where the number itself comes from — transmit power, path loss, and the noise
floor at the receiver — is the subject of **[From transmit power to fade
margin](link-budget-and-noise.md)**.

## 3. The Test Node

RidgeCast's answer is the **Test Node** — a hypothetical station representing
"the thing you are trying to reach". Its assumptions are visible in the right-hand **Coverage** workbench.
Expand **Edit test radio** to change them. They default to a
handheld:

| Parameter | Default | In plain terms |
| --- | --- | --- |
| Transmit power | 22 dBm | About 160 mW — a low-power handheld, not a 5 W HT |
| Receive sensitivity | −100 dBm | The weakest signal it can use. Typical; a good radio does better |
| Antenna gain | 0 dBi | A plain whip. A decent mobile antenna is 3 dBi; a beam, 10 or more |
| Antenna height above ground | 1.5 m | Held at chest height. Not on a roof, not on a mast |
| System loss | 2 dB | Cable and connector losses between radio and antenna |

Those five numbers set the scale of every coverage map you will ever draw. A
coverage overlay computed against a 1.5 m handheld and one computed against a
10 m mast on a vehicle are different maps of the same network, and neither is
more correct — they answer different questions. **If your coverage looks
pessimistic, check these before you change anything else.**

The Test Node is part of the coverage cache key, so changing it recalculates. It
is not part of your network and never appears as a node.

## 4. Direction: TX or RX coverage

Because links are asymmetric, "coverage" is two different maps.

- **TX** — where the selected nodes can be *heard*. The node transmits;
  the Test Node receives.
- **RX** — where the selected nodes can *hear*. The Test Node transmits;
  the node receives.

These differ whenever power or antenna gain is asymmetric, which is most real
networks. A repeater with a high-gain antenna and 40 W will paint a much larger
TX map than RX map, and the RX map is the one that tells you where a handheld can
actually get into it. Planning a network from the TX map alone is the classic way
to build a system that everyone can hear and nobody can use.

## 5. Two algorithms

**Vertex Grid** lays a hexagonal lattice over the node's range and evaluates a
terrain profile from the node out to each cell. Output is continuous: every cell
inside the range gets an answer, and adjacent cells cannot disagree because a ray
happened to miss one.

**Radial Sweep** casts rays outward from the node at a fixed angular spacing and
evaluates points along each. It is faster — it reuses one profile for every point
along a ray — but rays *diverge with distance*. At 1° spacing, two adjacent rays
are 17 m apart at 1 km and 175 m apart at 10 km, so at long range the sweep
samples the ground more and more sparsely and can leave gaps between rays. The
**coverage angular resolution** setting controls that spacing. Because it only
affects this algorithm, it has no global slider: the intent presets in §9 set it,
and a node that needs a specific spacing gets it from **Edit Node** or from bulk
editing a selection.

Vertex Grid is the one to trust for a final map; Radial Sweep is for a fast look.

### What a hexagonal cell is

The unit RidgeCast evaluates on is a hexagon, informally called a **hexel**. Hex
grids are used rather than squares because every neighbour of a hexagon is the
same distance away, which makes a coverage boundary look like a boundary rather
than like a staircase.

The lattice is **global** — anchored once, worldwide, rather than laid out around
whichever node you happen to be looking at. That is what lets one node's cached
grid line up exactly with another's, so two overlapping nodes' coverage can be
merged cell for cell instead of being resampled.

Within one cell, a terrain profile is generated from the node to the cell,
sampled at roughly one point per 30 m of path, with at least 10 and at most 200
points. Short paths therefore get relatively fine sampling; a 10 km path gets one
sample every 50 m because 200 is the cap.

## 6. Merging several nodes

Select several nodes and the overlay has to combine them. **Which combination**
is a real question with four different useful answers, and the choice changes
what the map means:

| Mode | Each cell shows | Use it to |
| --- | --- | --- |
| **Max Fade Margin** | the strongest signal any selected node delivers there | answer "where does this network reach" |
| **Best Unit** | *which* node serves it best | see service-area boundaries |
| **Redundancy** | *how many* nodes cover it | find single-covered ground |
| **Unique Coverage** | cells served by the one selected node with no qualifying backup in the rest of the enabled, visible network | see what would be lost with that site |

**Max Fade Margin** is the default and the everyday view.

**Redundancy** answers the resilience question directly: anywhere coloured
"1" goes dark if that one site fails.

**Unique Coverage** is Redundancy's complement and is the mode to reach for when
deciding whether a site is worth keeping. It hides everywhere that has a backup,
leaving only what would actually be lost.

**Best Unit**, **Redundancy**, and **Unique Coverage** record a per-cell serving
breakdown: which nodes reach each cell and their fade margins. Coverage-weighted
network analyses and per-site export figures read that record. **Max Fade
Margin** does not retain it, so those results can be *unavailable* rather than
zero. The whole-image export stats card can still report area and, with loaded
WorldPop data, population in any mode.

For a multi-node service analysis, choose **Best serving site** in **Coverage
question**. Best serving site and Coverage redundancy require multiple eligible
selected sites. With exactly one selected network radio and no amateur
locations, **Unique contribution of one site** becomes available. Strongest
signal / fade margin is always available (the Max Fade Margin calculation). Unique Coverage compares that site with the rest of the
network; it is not a substitute for that site's total coverage.

A separate **Best Unit threshold** (default 10 dB) is the minimum absolute fade
margin retained by Best Unit, Redundancy, and Unique Coverage. It is not a gap
between first and second place: if two nodes have 15 dB and 14 dB at a cell,
both qualify at the default threshold, and the 15 dB node is the Best Unit winner.
The Marginal threshold also affects visible and counted coverage.

## 7. The cache, and why selection changes are cheap

Coverage is cached to disk **persistently**, so unchanged areas survive across
application restarts. The design of that cache is worth understanding, because it
explains behavior that would otherwise look arbitrary.

**Each node's coverage is computed and cached as its own bounded part of the
same global lattice**, sized from that node's range and the coverage resolution
— and from nothing else. The shared lattice keeps independently calculated
nodes aligned; the per-node cache means a selection does not redefine an
existing node's calculation.

That is the key property. It means:

- Adding a node to a selection calculates **only the new node**.
- Removing a node from a selection calculates **nothing**.
- A node already on screen is never thrown away because you clicked a different
  one.

It was not always so. The per-node cell size used to be derived from the whole
run's bounding box and node count, so selecting or deselecting *any* node moved
the cell size of *every* node, every cached grid missed, and a run that should
have been instant recalculated coverage that was already drawn.

A cached node is recognized **before any LiDAR is planned**, so re-selecting one
draws immediately rather than waiting on a survey of data it does not need.

### What does invalidate a node's cache

Anything that changes what was computed:

- The node's position, transmit power, receive sensitivity, antenna gain, system
  loss, antenna height, and **height reference** — whether that height is
  measured from the ground or from the top of whatever is standing on it, which
  is the difference between a mast in a clearing and one in a forest.
- The node's **directional pattern**: whether the antenna is omnidirectional or
  aimed, and if aimed, at what bearing and with what front-to-back ratio.
- The network frequency.
- The **coverage range** — how far out from each node to evaluate, set globally as
  **Coverage → Default radius** (0.1–500 km) or overridden per node — and the
  coverage and angular resolutions.
- The algorithm (Vertex Grid / Radial Sweep) or the direction (TX / RX).
- The Test Node's parameters.
- The land-cover configuration.
- The propagation model, and the measured-surface settings.
- New terrain, land-cover, or surface data arriving for that area.

Each of these is part of the cache's identity for that node — change any one and
the stored result no longer describes what you are asking for, so it is
recomputed. Anything *not* on this list, notably which other nodes are selected,
leaves the cache intact.

Each propagation model writes distinct cache entries, so ITM and P.1812 coverage
for the same node can both be on disk and switching between them does not force a
recalculation of the one you left.

### Reusing results after a restart

Each completed node grid is stored on disk with stable calculation and data
identities. Restarting the application or loading the same terrain into memory
again does not change those identities. Saved networks restore their coverage
selection and controls, then rebuild the merged map from matching grids in the
background. Display settings can change without repeating propagation.

Cached grids are disposable: a changed input, damaged entry, or disk-budget
eviction leads to a fresh calculation. See [Reopen coverage in a later
session](../how-to/generate-and-export-coverage.md#reopen-coverage-in-a-later-session)
for saving and cache controls.

### The merged map may be coarser than the nodes

Two separate limits are at work, and conflating them causes confusion.

**Per node**, a node's own grid may hold at most about 120,000 cells for its
range disc. Below that ceiling your requested resolution is honoured exactly;
above it, the cell size is floored so the grid fits. This bound is a pure
function of one node's range and resolution, which is what keeps it out of the
selection's business.

**Per run**, the merged overlay that is actually drawn has its own cell budget
across the whole selection's footprint. A wide selection can therefore be *drawn*
on a coarser grid than its nodes were *computed* on. Nothing is cached against
the merged resolution, so this never invalidates anything — it only affects what
you see. The merged grid is never finer than the coarsest node grid feeding it,
because a merged cell takes its value from the node cell its center falls in.

## 8. Population under coverage

Coverage runs estimate the population covered, using **WorldPop 2020**
UN-adjusted constrained population-count rasters at roughly 100 m resolution —
people per pixel, downloaded per country and cached. Here **UN-adjusted** means
adjusted to **United Nations** national population estimates, not unadjusted;
the source filename identifies that product with `UNadj`. Counts are restricted to
mapped settlements and adjusted to UN national estimates. Settlement mapping
can miss inhabited areas, and 2020 estimates do not track later population changes.
Population figures inherit every limitation of coverage: they are population
under *predicted* coverage, at the Test Node's parameters. Whole-image export
totals work in every mode; per-site figures and coverage-weighted network
analyses additionally need retained serving margins (§6).

For where those rasters come from and how to mirror them, see
**[`docs/data-and-caching.md`](../data-and-caching.md)**.

## 9. Making it finish

Runtime scales with **area × resolution⁻²**. Halving the cell size quadruples the
cells; doubling the range quadruples the area. Both at once is a factor of
sixteen. This is the single most common reason a RidgeCast run appears to hang.

Coverage therefore offers three intent presets:

| Preset | Resolution | Angular resolution |
| --- | --- | --- |
| **⚡ Draft** | 200 m | 5.0° |
| **🎯 Planning** | 50 m | 1.0° |
| **🔬 Detailed** | 15 m | 0.5° |

alongside a live pre-flight estimate of cell count and calculation time, such as
**Est. ~5s**, **Est. ~30s**, or **Est. ~5m**. It counts eligible selected nodes and selected
amateur-license locations, uses each node's range override, and applies the
engine's minimum cell size and per-node grid limit. Unique Coverage with one
selected node includes the other eligible nodes needed for comparison.
Overlapping nodes count separately, so the merged map may contain fewer cells.
An empty selection shows no workload; use Ctrl+A to select the network.

The ETA scales with effective cell size, path lengths, and algorithm: Vertex
Grid evaluates a profile per cell, while Radial Sweep repeatedly solves prefixes
of each ray. Before a measured run is available it uses a rough CPU-throughput
estimate. Completed calculations calibrate the rate on your machine for the
same algorithm, propagation model, clutter, and measured-surface settings for
the rest of the session. Cache hits, interactive GPU previews, and incomplete
offline calculations do not train that rate. The indicator is green below ten
seconds, yellow below a minute, and red for longer runs.

This estimates a fresh full CPU calculation with terrain available. Terrain,
land-cover, and LiDAR acquisition or surface preparation can add time; cached
coverage can finish much sooner. The tooltip states whether the estimate is
rough or calibrated. Completed runs report calculation duration, total cells
evaluated, and disk caching status.

The global coverage range and hex size (resolution) configured in this panel are
saved alongside the network (`network.json` / `network.yaml`), so opening or
switching to a network automatically restores the coverage settings last used on it.

**The presets do not choose an algorithm**, and the two columns do not both
apply to both. **Resolution** — the cell size — governs either algorithm.
**Angular resolution** sets the ray spacing and is used only by Radial Sweep; in
Vertex Grid it has no effect on the result, which is why the panel offers no
global slider for it — set it per node instead when a sweep needs a particular
spacing. It is nonetheless part of the cache identity in both modes, so changing
it will make a Vertex Grid node recalculate to the same answer. Pick the algorithm separately, and prefer Vertex Grid for
anything you intend to show someone.

The working method is: **start coarse, verify the area and the radio parameters,
then refine.** A Draft pass over a wide area tells you whether you are even
looking at the right ground, and costs a fraction of what a Detailed pass over
the same area does. Because each node's cache is independent, refining does not
throw away the nodes you have not changed — but changing the resolution does
invalidate every node, because resolution is part of what was computed.

A first run may also spend most of its time downloading rather than calculating.
Before solving, RidgeCast plans data for the full evaluation area around every
selected site, including terrain along the paths to its cells. It queues the
needed terrain, land-cover, and enabled LiDAR data together, and overlapping
sites share a single request for each missing tile. A site whose inputs are ready
can calculate while other sites' downloads continue.

Each node draws a badge naming what it is waiting on, so a slow network can be
told apart from a slow solve:

- **Waiting for downloads** — waiting for planned terrain or land-cover data.
  Bare-earth ground heights are always needed to decide whether a hill blocks
  the path.
- **Queued** — its data is ready; waiting for a calculation worker.
- **Fetching LiDAR** — downloading measured surface data, which refines what is
  *standing on* that ground (trees, buildings) rather than the ground itself.
  Optional, off unless you have enabled measured surfaces, and much larger.
- **Building surface** — cropping measured surface data for this site.
- **Preparing profiles** — reading terrain and land cover into the next batch
  of paths. A site can return to this stage between propagation batches.
- **Fetching terrain** — a profile pass is gathering ground heights and any
  missing tiles.
- **Calculating** — actually solving.

The **Calculation Progress** window breaks a run into its real steps: Fetching
terrain, Planning LiDAR, Fetching LiDAR, Building surfaces, Sampling terrain,
Solving coverage, and Assembling map. Steps can overlap: ready sites can prepare
profiles and solve while terrain or LiDAR downloads for other sites continue.
A step that has nothing to do is greyed rather than filled.
The overall status can show concurrent work, for example **Calculating (CPU) ·
3 waiting for downloads**. When every unfinished site is waiting for data, it
says **Waiting for downloads**. The CPU or GPU engine is named only while
propagation is being solved.

Coverage work runs on background threads with cancellation, so the interface stays
responsive and a run that is going the wrong way can be stopped.
Changing the selection or calculation settings still cancels the old run. A
failed download still allows a partial result from the data that is available;
inspect source failures in **Downloads**.

**Purple cells with a `?` are unevaluated**: required terrain is missing, so no
fade margin can be calculated there. This can happen online too when enabled
datasets have blank pixels. Enabled lower resolution terrain fills these gaps
where available, for both coverage and terrain display. Hover over a
cell for the explanation. These cells are different from evaluated places with
weak or no signal and are excluded from coverage and population totals.
Available coverage remains visible, and a completed run can offer to enable a
disabled dataset and try again. You can continue with the partial result or turn
off future prompts. See [Missing terrain and disabled datasets](../reference/data-sources-and-caches.md#missing-terrain-and-disabled-datasets)
for the dialog and Geodata control. An incomplete per-node result is not stored
in the coverage calculation cache.

## 10. What a coverage map is not

- **It is not a measurement.** It is a median prediction (see **[Choosing a
  propagation model](propagation-models.md)**), from terrain and land-cover data
  that can be stale, generalized, or simply wrong.
- **It is a map of one hypothetical receiver.** Change the Test Node and the map
  changes. There is no coverage without an assumed far end.
- **It does not know about local obstructions.** The tree next to the handheld,
  the building you are standing inside, and the vehicle you are in are all
  invisible to it. Indoor coverage is not modeled at all.
- **It does not model interference**, only noise — and the noise it models is a
  low-confidence prior. See **[From transmit power to fade
  margin](link-budget-and-noise.md)**.
- **GPU-assisted coverage is a different, simpler model**, available in ITM mode
  only, and meant for a first look rather than a final answer.
- **Coverage is not service.** Ground covered by a site that has been cut off from
  the backbone is coverage, not service, and the network analyses are careful
  about the difference. **Population Service**, the **N-1 failure sweep**, and
  **candidate-site ranking** — the three analyses that read the Best Unit
  breakdown (§6) — all apply that distinction. See **[Network
  analysis](network-analysis.md)**.

---

## Run internals and cache identity (for maintainers)

Source: `src/coverage_run.rs` (the run), `src/engine/coverage_cache.rs` (the
on-disk cache). This section is the maintained description of the cache; the
[implementation plan](../coverage-cache-implementation-plan.md) records only
how the work was sequenced.

### Shape of a run

1. Look up each node's cached grid; a node with a usable entry is skipped.
2. Estimate the decoded terrain the remaining nodes need. In the normal policy
   the run stops and asks for confirmation if the misses would exceed the cache
   budget; the budget-confirmed and recompute policies skip that check, and
   recompute also ignores cached grids.
3. Queue the missing terrain, land cover, and LiDAR on download workers, which
   are separate from calculation workers. Calculation workers read only what
   preparation already cached, so they never wait on the network.
4. Solve whichever nodes have their inputs ready while downloads continue, and
   merge each node's grid onto the output grid. Results are published in
   chunks of 1,000 cells so partial coverage appears while the rest computes.

A run carries a version and a shared cancel flag. Starting a newer run bumps
the flag and the older run abandons its work at its next check; completed cache
entries stay available.

### Node grid versus merged grid

- **Node grid** (`node_grid_resolution_m`): the requested resolution, at least
  10 m, raised only if the node's range disc would need more than 120,000 cells
  (`MAX_HEXES_PER_NODE`; a hexagon of radius `r` has area 2.598 `r`²). A pure
  function of one node's range and requested resolution. This value is part of
  the cache key.
- **Merged grid** (`merged_grid_resolution_m`): the requested resolution (at
  least 10 m), raised to fit the whole selection's bounding box within the run's
  cell budget, and never finer than the coarsest node grid. The budget is
  150,000 cells for a full run and 3,000 for a preview. For Best Unit,
  Redundancy and Unique Coverage it is also capped at
  4,000,000 / (selected nodes), because those modes retain one margin per
  reaching node per cell (`MAX_RETAINED_COVERAGE_MARGINS`).
- When the grids differ, each merged cell takes the value of the node cell its
  *center* falls in (a point sample). Averaging or max-holding would leave holes
  or count one node into a cell twice, which would inflate Redundancy counts.
- Radial Sweep uses `360 / angular resolution` rays, but no more than needed to
  keep rays about half a cell apart at the edge of range, and never more than
  720.

### Tie-breaking

When several nodes reach a cell, the owner is the one with the higher fade
margin. On an exact tie the node earlier in the selection order wins, so the
result does not depend on which node finished first or which download completed
first.

### Retry when data changes during a solve

The cache key (below) includes a fingerprint of the terrain and land-cover
files around the node. It is computed before the solve and again after it. If
the two differ, a download landed while the solve was running, so the grid may
describe a mixture of old and new data. The run solves that node once more. If
the second pass is still unstable, its result is displayed but **not** written
to the cache. A grid is also never written if any cell holds the
"terrain unavailable" marker (`f32::MAX`), or if measured-surface mode is
enabled but no compatible surface was prepared (surface revision 0), so that a
transient offline or catalog failure is retried on the next request instead of
being cached.

### Cache key

Each node's grid lives in one file, `<cache root>/coverage/<64 hex digits>.rcov`.
The name is the SHA-256 of the canonical JSON (object keys sorted, floats as
raw bit patterns) of:

- the calculation version (`CALCULATION_VERSION`, currently 7; bump it whenever
  propagation, grid enumeration, interpolation, or stored-value semantics
  change) and the backend, always `cpu` (the GPU is used only for uncached
  previews, and completed grids are always CPU results);
- the node's and the Test Node's radio fields: transmit power, sensitivity,
  gain, height and height reference, system loss, directional settings (azimuth,
  front-to-back, elevation, vertical response, measured pattern);
- node latitude and longitude, frequency, range, node grid resolution, angular
  resolution, algorithm, and mode (TX/RX);
- the land-cover configuration;
- the data fingerprint and the measured-surface revision;
- the propagation model, P.1812 time percentage, ITM settings, ITM-DSM
  settings and its `ALGORITHM_VERSION` / `COMPOSITION_VERSION`, complete-P.1812
  settings when present, and the ambient-noise configuration. Receiver-noise
  fields join the key only when atmospheric noise is enabled, so older keys are
  unchanged.

Rendering settings, the merged grid resolution, and which other nodes are
selected are deliberately **not** in the key.

**Data fingerprint.** For the box around the node (range plus 0.02 degrees; a
box that crosses the antimeridian widens to all longitudes), the fingerprint
lists every terrain and land-cover cache file that overlaps the box by name,
size, and modification time. All sources are included even if disabled, and
presence counts: a new higher-priority tile invalidates an earlier fallback
result. It reads metadata only, never decoding terrain.

### File format

Magic `RCCOV002`; the 32-byte key; the cell count (u64 little-endian); the
SHA-256 of the raw values; then the values as little-endian f32, zstd level 3.
Limits: at most 1,000,000 cells per file. Negative infinity is the stored
"no coverage" marker; NaN, +infinity and `f32::MAX` are rejected on read and
write. Any magic, key, size, or checksum mismatch is a plain cache miss. Writes
go to a `.rcov.tmp` file that is renamed into place, and a write is skipped if
the run was superseded in the meantime. Reads refresh the file's access time
for cache eviction. The Coverage cache category has its own capacity (default
1 GiB); see [Data, caching, and working offline](../data-and-caching.md).

---

## Where else to look

- **[From transmit power to fade margin](link-budget-and-noise.md)** — what each
  cell's color is computed from, and what the SNR bands mean.
- **[Choosing a propagation model](propagation-models.md)** — which physics is
  being run tens of thousands of times.
- **[Finding sites](site-finder.md)** — the inverse question: not "what does this
  site reach" but "which site would reach best".
- **[Network analysis](network-analysis.md)** — what reads the Best Unit serving
  breakdown, and why it needs it.
- **[`docs/data-and-caching.md`](../data-and-caching.md)** — where terrain, land
  cover, and population data come from, and how the caches are managed.
