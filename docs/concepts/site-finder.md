# Finding sites: how Site Finder scores ground

*An explanation of the question Site Finder answers, how a location gets a
number, what the sampling and suppression controls actually do, and where the
score should not be trusted. Written for someone who has never seen the code and
does not need to.*

---

## 1. The opposite question

Coverage takes a site you have already chosen and asks *what can it reach*. Site
Finder inverts that: it takes an area and asks **which location in it would make
the best site**.

That inversion is expensive. Coverage evaluates one node against many points.
Site Finder evaluates *many candidate nodes* against many points each — every
hexagonal cell in the visible map becomes a hypothetical transmitter, and each
one gets a full radial scan of its own.

**Scan tile radius** is the nominal distance from a candidate
hexagon's center to one of its corners. It describes the size of the candidate
cell, not the spacing of receiver samples along each radio ray. Adjacent cell
centers are farther apart than this radius.

Use it when you know roughly where you need coverage but not where to put the
radio: which knoll, which ridge, which of the four water towers.

## 2. How one cell gets a score

The transmitter and reference receiver are independent, fully resolved scan
inputs. The legacy preset preserves historical results; saved systems can
replace either endpoint. Geographic antenna bearings stay fixed during the
sweep, and vertical response uses each modeled ray's geometric elevation.
Height, EIRP, receive gain/loss, operating threshold, noise figure, bandwidth,
and propagation settings are captured at scan start and reused by refinements.
New settings use a Basic transmitter and the built-in Pocket Node receiver at
62.5 kHz; legacy saved inputs retain their original values. Unsupported inputs
disable Fast with an explanation. **Full quality (CPU)** retains the selected
propagation model, including full ITM, for every candidate. **Fast (CPU + GPUs)**
uses a matching approximation across CPU workers and available GPUs; CPU fallback
within Fast retains that approximation. Fast does not implement full ITM and may
rank sites differently. Saved scans and refinements retain their original mode.
Missing terrain or required land-cover
samples contribute to an explicit unavailable count, not successful coverage.

For every candidate cell, Site Finder:

1. Places a hypothetical transmitter somewhere in that cell (§3 decides where).
2. Casts **360 rays** outward, one per degree, out to the configured range.
3. Generates a terrain profile along each ray — **64 points**, so 63 evaluated
   sample points per ray, evenly spaced from the site out to the range limit.
   Each of those sample points is treated as a hypothetical **receiver**.
4. Computes path loss to each sample point, adds any clutter penalty, and turns
   the result into an SNR against the assumed noise floor. That floor is uniform
   for the candidate's sweep: the selected receiver threshold (−100 dBm in the
   legacy preset), optionally raised by the
   candidate site's environmental noise (§2 below).
5. Grades every sample point against the fade-margin bands and accumulates.

> **SNR and fade margin are the same number.** RidgeCast uses both names — "SNR"
> for what it is, "fade margin" for what it is for — and the bands in **Settings
> → Fade Margin Settings** are thresholds on it, in dB. See **[From transmit
> power to fade margin](link-budget-and-noise.md)** for where the number comes
> from.

The accumulation is deliberately simple:

| Sample point grades as | Contributes (Land) | Contributes (Water, default 10%) |
| --- | --- | --- |
| **Good** (default ≥ 20 dB) | **+1.0** | **+0.1** |
| **Fair** (default ≥ 10 dB) | **+0.5** | **+0.05** |
| **Marginal** (default ≥ 0 dB) | **+0.1** | **+0.01** |
| **None** | **−0.1** | **−0.1** |

The bands are the ones in **Settings → Fade Margin Settings**, shared with links
and coverage.

- **Water coverage is discounted by default.** To keep large bodies of water
  (oceans, lakes) from artificially dominating terrestrial candidate rankings,
  water cells contribute a fraction (default 10% / 0.1×) of normal points. This
  weight is adjustable via the **Water Area Value** slider in the Site Finder
  window. Water is detected via NLCD `Open Water` (class 11), with a sea-level
  elevation fallback (≤ 0 m) when land cover is unavailable.
  This NLCD source covers the contiguous United States; registered WorldCover
  crops can supply classifications elsewhere. Without available land cover,
  the elevation fallback can misclassify dry land below sea level and miss lakes
  above sea level. Regional polygon outlines used for display and placement
  eligibility do not replace this RF scoring classification; review water-heavy
  rankings accordingly.
- **Grade by Population.** When enabled in Site Finder, scores use sampled
  WorldPop population values. These are ranking values, not counts of distinct
  people served. Site Finder reports raster availability and offers
  **Load / Retry Population Data** by country code. Missing data is not evidence
  of zero population; see the [loading workflow](../how-to/find-and-validate-a-site.md#grade-by-population).
  **View → Node Colors → Site Score (Population Weighted)** separately colors existing nodes.

Fully water placement is excluded by default for new scans, independently of
water coverage value. The scan freezes available detailed regional water
geometry. Only a whole candidate footprint confirmed as water is excluded;
valid polygons showing land keep it eligible. Unknown regional coverage can
fall back to known all-water cached land cover. Mixed or incomplete footprints
remain eligible, and generalized Natural Earth display outlines never establish
placement eligibility. Missing water does not delay a scan; new geometry is used
by a new scan rather than changing retained results.

Population scoring records area-weighted density sums: `P = Good + 0.5×Fair +
0.1×Marginal`, then `Raw = P + 0.001×G`, where G is the geographic weighted score.
Unavailable population uses the geographic fallback. Score hovers show recorded
weighted contributions and diversity math; legacy results identify unavailable
breakdowns.

The candidate list and hover details show **Adjusted score** (used for ranking
after cluster suppression) alongside **Raw score** (before suppression). This
lets you distinguish a weaker signal prediction from a candidate that has been
down-ranked because a better site is nearby. Suppression leaves signal-band
counts unchanged.

Three consequences fall straight out of this arithmetic and are worth carrying
around:

- **The score is bounded.** 360 rays × 63 points = 22,680 sample points, so the
  maximum possible score is 22,680 (everything Good) and the minimum is −2,268
  (everything None). These bounds apply only with **Grade by Population** off.
  Population-graded scores use sampled people-per-pixel values and cannot be
  compared numerically with ungraded scores; neither is a count of distinct
  people served.
- **Unreachable ground is penalised, not ignored.** A site with a good view in
  one direction and a mountain in the other is charged for the mountain. This is
  intentional: it prefers sites with all-round reach over sites with one
  spectacular corridor.
- **A "fair" point is worth half a "good" point, and ten "marginal" points are
  worth one "good" one.** The weights are a stated editorial choice about what
  makes a site valuable, not a physical quantity.

The result is also reported as four raw counts — Good / Fair / Marginal / None
sample points — alongside the composite. Those counts are what to read when you
want to know *why* one site beat another.

### Water bodies and coastline attenuation

Sites overlooking large bodies of water (oceans, large lakes) can score deceptively
high due to unobstructed line of sight, even when no users exist out on open water.
Site Finder addresses this in two ways:

- **Water Area Value floor** (default 10%): Covered water samples receive a fractional
  weight instead of the full 1.0 land weight. At 0%, water contributes no positive score;
  at 100%, water is treated identically to land.
- **Coastline Distance Attenuation** (default enabled, 3.0 km falloff): Rather than a
  flat discount across all water, nearshore waters (harbors, bays, coastal waterways)
  retain near-full value, while open ocean coverage decays exponentially toward the
  floor:
  $$\text{weight}(d) = w_{\text{floor}} + (1 - w_{\text{floor}}) \cdot e^{-d / d_0}$$
  where $d$ is the distance to the nearest shoreline along the line-of-sight ray transect
  and $d_0$ is the configurable falloff distance.

Water is detected using NLCD Open Water land-cover data (class 11), falling back to
sea-level elevation (≤ 0 m) when land-cover tiles are not loaded.

### Sample spacing matters more than it looks

Each ray uses a fixed 64-point profile stretched across the whole range,
regardless of what that range is. At 5 km the sample points are 79 m apart; at
20 km they are 317 m apart. The scan does not become finer when you scan closer,
and it does not become coarser in a way that is flagged when you scan further.

Likewise, rays are always 360 at 1° spacing. At 20 km, adjacent rays are 350 m
apart at the outer edge. Site Finder samples a *sparse star*, not an area. It is
a comparative instrument for ranking cells against each other, and it should not
be read as a coverage map. That is what coverage is for.

### The noise floor Site Finder assumes

Site Finder has its own transmitter and reference receiver configuration,
independent of coverage's Test Node. With the legacy preset, it uses a
**−100 dBm baseline scoring floor**. Changing the reference receiver threshold
changes that baseline. Evaluating the noise at thousands of radial sample points
individually would be prohibitively expensive.

However, candidate site locations themselves often differ wildly in ambient RF noise:
a rooftop in a noisy downtown commercial district faces a much higher noise floor
than an equivalent tower on a quiet forested ridgeline.

To account for this, Site Finder provides the **Factor in Environmental Noise** toggle:

- **Off (default)**: every candidate is scored against the selected receiver
  threshold, −100 dBm in the legacy preset.
- **On**: each candidate cell is sampled once — land cover (NLCD) over the
  configured local circle and context ring, population density (WorldPop) over the
  local circle — and the site's external man-made noise power ($F_{am}$) is computed
  from ITU-R P.372 / Hagn/NTIA. The **penalty** that noise imposes on a real
  receiver, using the selected bandwidth and noise figure, is then added to that
  baseline. Candidates in noisy or densely
  populated areas end up with a higher floor, so signals must be stronger to reach
  the Good/Fair/Marginal thresholds, and quiet terrain is favoured.

Both the sweep and the per-node scores in the node inspector use the same noise
sampler. Their scores can differ because node-specific radio settings and
sampling geometry differ from the candidate scan. The settings
under **Ambient Noise** in the network configuration — sampling radii, land-cover
weights, the population blend and reference density — apply here too.

The optional [P.372 atmospheric component](../reference/scientific-models.md)
changes this sampling policy: noise is evaluated at each actual receiving point
on CPU, using the frozen receiver inputs and compatible measured-floor override.
Unavailable requested components produce unknown samples instead of successful
coverage; the verified atmospheric range is 20–30 MHz. Leaving it disabled retains
the candidate-origin proxy and historical defaults.

**Three mechanisms, not one.** Unintentional noise (ignition, power lines,
switching supplies) fades to near-nothing by 900 MHz. On a shared band —
902–928 MHz, 863–870 MHz, 433 MHz — two others take over: the in-band traffic of
every other radio around, and desensitization of a poorly filtered receiver by
the high-power licensed services next door. Both track development density the
same way land cover does, so one sampling pass drives all three.

**The spread stays useful across bands.** Between a dense-urban and a forested
candidate, the reference receiver's floor moves about 10.6 dB at 146 MHz and about
9.0 dB at 915 MHz — different mechanisms doing the work, comparable result.
Expect it to reorder a shortlist, not merely break ties. Turning it on makes a
scan slower and may download land-cover and population tiles.

**Ranking is sounder than the absolute number.** The in-band traffic figure is a
seed calibrated to put dense urban near —111 dBm, not a measurement. Candidates
are compared on equal terms, but do not read a candidate's floor as what a
receiver there would actually measure without checking it against one.

See **[From transmit power to fade margin](link-budget-and-noise.md)** for how the
environmental noise model works in detail, and why the reference receiver's noise
figure is what decides whether any of this is visible.

## 3. Where in the cell the antenna stands

A hexagonal cell 100 m across is not a point, and the highest ground in it can be
several meters above the lowest. **Site sampling strategy** decides which point
inside the cell the hypothetical antenna stands on:

| Strategy | Sampled base for the antenna height |
| --- | --- |
| **Height at Hex Center** (default) | a single elevation sample at the cell center |
| **Average Height in Hex** | the cell's mean ground height, antenna at the center |
| **Highest Point in Hex** | the highest ground point found in the cell |
| **Highest Point on Land Cover** | the top of the tallest ground-plus-clutter in the cell |

The last two model *"put the tower on the best spot in this cell"* rather than on
an arbitrary point in it, which is usually the honest question — you are not
going to build on the exact centroid.

The non-center strategies sample a 5×5 grid across the cell, keeping only the
points that actually fall inside the hexagon, and pick from those. So they cost
extra elevation lookups per cell, and they are less exact than the phrase
"highest point" suggests: the true summit can sit between grid samples.

The scan adds its selected transmitter height `h` above the sampled base.
The legacy preset uses `h = 10 m`:

| Strategy | Antenna elevation used by the scan |
| --- | --- |
| Height at Hex Center | Center ground elevation + h |
| Average Height in Hex | Mean sampled ground elevation + h |
| Highest Point in Hex | Highest sampled ground elevation + h |
| Highest Point on Land Cover | Highest sampled ground-plus-clutter elevation + h |

For example, with a 10 m transmitter height, 100 m ground plus 20 m canopy puts
the land-cover strategy's antenna at 130 m above sea level, not at the 120 m
canopy top. It answers
"how good could this cell be with a mast above that surface"; use it only when
that mounting height is plausible.

## 4. Filtering out what you already have

**Existing-coverage filtering** takes the coverage your network already provides
and **skips every sample point already served** at or above a cutoff SNR. Skipped
points contribute nothing at all — not the positive of being covered, not the
negative of being missed.

The scan therefore ranks candidate sites by **what they would add**, not by their
raw reach. A site in the middle of your existing footprint scores near zero
however commanding its view is, which is exactly the ranking you want when
choosing where to expand.

Turn it on with **Skip Existing Coverage** in the Site Finder window. The
**Already Served At** choice sets the cutoff to one of your network's coverage
color thresholds:

- **Marginal or better** skips any usable coverage, so only true gaps score.
- **Fair or better** (the default) still rewards sites that would strengthen
  weak Marginal fringes.
- **Good only** also rewards sites that would strengthen Fair areas.

Because the cutoff follows the network's thresholds, "served" means the same
thing it means on the coverage map.

The comparison is made against the coverage currently on the map, binned to the
coverage resolution, keeping the strongest SNR in each cell. It covers whichever
nodes that coverage run included, so calculate coverage for the whole network
first if you want to rank against all of it. With no coverage calculated,
nothing is skipped. A scan started while coverage is still calculating skips
only the part that has finished. The setting applies to the next scan; it does
not rescore existing results. The FCC license overlay's **Site Finder score**
coloring honors it too. Scores shown for your existing nodes ignore it, because each
node's own coverage would otherwise hide it.

## 5. Refining without paying for it everywhere

Fine resolution over a whole map is quadratically expensive: halving the cell
size quadruples the cell count. **Recursive refinement** avoids paying it
everywhere.

After a pass, the **top ten cells by post-suppression score** are subdivided and
rescanned at **half** the resolution. Ten, not a percentile and not a threshold —
and *post*-suppression deliberately, so the seeds are ten distinct local peaks
rather than ten near-identical neighbours from the same plateau (§6).

The subdivision is a seven-cell cluster: one child centered on the parent plus its
six immediate neighbours. Together they cover the parent hexagon and extend
slightly beyond its boundary.
Adjacent parents overlap at their shared boundary children, which are
deduplicated by grid coordinate. So each recursion level adds at most 70 cells,
usually fewer — a bounded, cheap step regardless of how large the original scan
was.

A coarse pass therefore finds the *region* and a fine pass finds the *knoll*
inside it, without a fine pass over the valley floor. Recursion is capped at 5
levels, and the child resolution derives from the finished scan rather than from
the resolution slider, which recursion never modifies.

## 6. Cluster suppression, and "jealousy"

One good ridge does not produce one good cell. It produces a blob of dozens of
high-scoring cells that all see the same thing, and a top-ten list made of ten
points along one ridge tells you nothing you did not already know.

**Cluster suppression** fixes that. Every site keeps its raw score unless a
higher-scoring site sits within the **cluster radius** — counted in hex steps at
that scan's own resolution, default 3. (Because recursion halves the resolution,
"3 cells" is a different physical distance at each tier, which is why tiers are
suppressed independently: hex adjacency only means something within one
resolution.)

The whole rule, for one cell with raw score `s`:

```
for each better-scoring neighbour at distance d within the radius n:
    t        = 1 − d / (n + 1)
    falloff  = t² · (3 − 2t)                    # smoothstep: 1 nearby → 0 at the edge
    gap      = (s_neighbour − s) / s_neighbour  # 0 for a tie, → 1 for a much better site
    contrast = gap + jealousy · (1 − gap)       # jealousy blends gap-proportional → 1

suppression = the largest falloff · contrast over all such neighbours
final score = s · (1 − suppression)
```

Three things fall out of that, and they are what you actually need:

**Distance** eases the effect smoothly, from full strength at an adjacent cell to
zero just past the radius. The smoothness matters — a hard cutoff would draw
visible rings. Only the *strongest single* suppressor applies, which keeps the
result continuous where two peaks' neighbourhoods meet.

**Jealousy** (0 to 1, default 0.75) sets *what it takes* to suppress a neighbour,
interpolating linearly between the two ends:

- **At 0**, `contrast = gap`: suppression is proportional to the relative score
  gap. Real scans often score neighbouring cells within a fraction of a percent
  of each other, so this end barely changes the picture at all.
- **At 1**, `contrast = 1` regardless of gap: winner-take-all. *Any* better site
  within the radius suppresses this one by the full distance falloff, however
  small the gap. Only each neighbourhood's single best cell keeps its score, so
  true peaks pop out of an otherwise uniform "goodish" plateau.
- **At 0.75**, the default, a cell with a negligible gap is still suppressed to
  about three-quarters of the winner-take-all amount — closer to the aggressive
  end than the number suggests.

**Exact ties survive together** at any jealousy: neither is strictly better than
the other, so neither suppresses. Cells scoring zero or less are left alone.

Suppression is applied to a **stored raw score**, and recomputed from it. Moving
the radius or jealousy sliders automatically re-clusters the existing results
in a background worker without rescanning. Both the heatmap and Top 10 rankings
update from the latest slider values; changes during a scan or export wait until
it finishes. **Restore scan values** restores the completed scan's captured
values. Recursion tiers are suppressed independently of one another, because hex
adjacency only means something within a single resolution.

> **What jealousy is not.** It does not change which sites are good. It changes
> how aggressively near-equals are hidden so the good ones are visible. If you
> raise it and a site disappears, that site had a better neighbour.

## 7. CPU or GPU

Site Finder offers two explicit quality modes:

RidgeCast has an application-wide **propagation model** setting — **ITM**
(Longley–Rice, the default) or **terrain diffraction (P.1812-inspired)**. That is
the physics used to turn terrain into a path-loss number. Separately, Site Finder
offers **Full quality (CPU)** and **Fast (CPU + GPUs)**.

- **Full quality** evaluates every candidate with the selected CPU model and
  its captured settings. Selecting Fast never changes this full scan's accuracy.
- **Fast** uses free-space loss, three-edge knife-edge diffraction and a two-ray
  floor. CPU workers and available GPUs share this approximation and dynamically
  claim batches. It can run without a GPU; device failure uses the same fast CPU
  calculation. Fast requires compatible legacy Longley–Rice settings and
  supported radio/noise inputs. Other settings retain Full quality.

Details of all three models are in **[Choosing a propagation
model](propagation-models.md)**.

Use Fast to explore an area, then validate promising candidates with Full quality
and ordinary CPU Coverage and links. Fast is an approximation, and it can miss
sites that full ITM would rank highly. An exhaustive Full quality scan remains
available when that matters.

## 8. Making a scan finish

Cost is driven almost entirely by **how many cells there are**, which grows
linearly with the area scanned and quadratically as the resolution becomes finer
— halving the cell size quadruples the count.

Range behaves differently, and counter-intuitively. Because each ray always uses
the same 64-point profile however far it reaches (§2), **doubling the range does
not double the work per cell**. What it does do is spread the same 22,680 samples
over four times the ground, and require terrain data over four times the area —
so a longer range costs mostly in *downloads* on a cold cache, and in accuracy,
rather than in computation.

Site Finder ships three intent presets:

| Preset | Resolution | Recursion | Notes |
| --- | --- | --- | --- |
| **Fast** | 200 m | 0 | A first look at a wide area |
| **Balanced** | 100 m | 1 | With land-cover clutter |
| **Detailed** | 30 m | 2 | With land-cover clutter |

The window also shows candidate-count, terrain-readiness and a compatible
Full quality CPU runtime estimate. Fast is identified as not calibrated.
The [application-wide benchmark](../how-to/benchmark-this-computer.md) measures
real CPU Coverage and CPU/GPU Site Finder work, sharing persistent calibration
between both tools. Downloads are separate from measured computation time.

Stopping an in-progress scan **keeps everything computed so far**: partial results
are clustered and retained rather than discarded, so a scan that is taking too
long can be stopped and read rather than abandoned.

Scans run outside the UI thread and publish immutable result views assembled on
workers. The desktop consumes the latest bounded preview instead of accumulating
stale updates, keeping progress and map interaction independent of the full
retained result set. Matching scans reuse decoded source caches; acquisition and
missing inputs still add work.

## 9. Reading and sharing the results

- **Live vector overlays** draw the scored cells on the map as they arrive.
- **Top-site ranking** with click-to-center.
- **Fortuity** is a "punches above its height" figure: the site's score divided
  by the square of the cell's average ground elevation in meters, where that
  average is the mean of the cell's center and its six corners, floored at 1 m so
  a sea-level cell cannot divide by zero. Dividing by height *squared* penalises
  tall ground hard, which is the point — it surfaces modest hills that a raw
  ranking, which naturally favours mountains, would bury. It is shown on hover
  alongside the raw score and the average elevation it was computed from.
- **Population grading** (optional) uses area-weighted density sums under Good
  samples fully, Fair at half and Marginal at a tenth, plus 0.001 times the
  geographic score as a tie-breaker. Unserved samples contribute through that
  geographic tie-breaker. These are comparative ranking values, not distinct
  people served; sampled ray sectors overlap.
- **JSON import/export** retains original radio, model, sampling, and suppression
  assumptions. **CSV and GeoJSON** export ranked full, top-ten, or selected
  candidates, including raw scores, per-cell resolutions, and recorded origins.
  Refinement requires the original source inputs, coverage filter and frozen
  water geometry. JSON records water identity without embedding polygons; an
  unavailable original snapshot requires a new scan before refinement.
  Old imported files retain explicit unknown assumptions and origins. **PNG
  rendering** provides a visual summary for review and sharing.

## 10. What a site score is not

- **It is not a coverage map.** It is a sparse star of 360 rays sampled at 63
  points each. Use it to rank cells; use coverage to see what one of them
  actually reaches.
- **It is comparative, not absolute.** A score of 8,000 means something relative
  to the other cells in the same scan and very little on its own.
- **It ignores ambient noise unless you ask it not to** (§2). With **Factor in
  Environmental Noise** off, urban and rural candidates of identical geometry score
  identically; with it on, the candidate-local penalty can materially reorder
  shared-band UHF results. Unintentional man-made noise alone is smaller there;
  shared-band traffic and receiver desense add separate terms (§2).
- **It does not know whether you can build there.** Land ownership, access,
  power, backhaul, zoning, and whether the "highest point in hex" is somebody's
  roof are all outside the model. Site Finder produces a shortlist for a human to
  investigate.
- **It does not predict links.** A high-scoring cell has not been evaluated
  against your existing nodes. To answer that, model it as a node and calculate
  links — and see **[Network analysis](network-analysis.md)** for ranking
  candidates once you have.
- **The weights are an editorial choice** (§2), as is fortuity's division by the
  square of elevation. They are defensible, not derived.

---

## Scoring details for maintainers

These are the exact rules behind the numbers above. Source:
`src/engine/site_finder.rs` and `src/engine/site_assumptions.rs`.

**Grade weights.** Each of the 22,680 sample points is graded once against the
captured Good / Fair / Marginal SNR thresholds and adds `+1`, `+0.5`, `+0.1`
(each times the sample's water weight) or, for None, a flat `−0.1`. The None
penalty is *not* scaled by the water weight, so open water that cannot be
reached still costs a full `0.1`. `SITE_SCORE_MAX` is 22,680 and
`SITE_SCORE_MIN` is −2,268.

**Population blend and tie-break.** With **Grade by Population** on and a
population raster loaded, each graded sample also records its location and its
annular area (radius × radial step × one degree). The three grade groups are
summed with area weighting, and the stored score is

```
score = (Good + 0.5·Fair + 0.1·Marginal)  +  0.001 × geographic score
```

where the three populations are the area-weighted sums per grade. The geographic
score is therefore only a tie-breaker: it moves a population-graded score by
at most about 22 points, and it matters only between candidates whose weighted
population is otherwise nearly equal. If no population raster is loaded the
geographic score is used unchanged.

**Global hex grid.** Candidate cells are cells of one pointy-top axial `(q, r)`
lattice anchored at latitude 0, longitude 0, with cell radius equal to the scan
resolution. The projection is a plain affine map with fixed scales
(111,320 m per degree of latitude; 111,320 × cos 45° m per degree of
longitude), *not* `cos(latitude)`. A latitude-dependent scale would shear the
lattice by many cells a few hundred kilometres from the origin and make cells
jitter. The consequence is that a cell's east–west ground width is
`cos(latitude) / cos(45°)` of its nominal width: roughly nominal in the
mid-latitudes, 1.41× at the equator and 0.71× at 60°. Cell outlines must come
from the lattice (`hex_cell_polygon`), not from a hexagon sized in meters.
Every scan, refinement, coverage filter, and cluster-suppression lookup uses
the same lattice, so they agree on which cell a point belongs to.
`scan_points_for_bounds` returns the cell centers inside a bounding box in
ascending `q`, then `r`, order.

**Refinement children.** A refined cell is replaced by seven children at half
the parent's radius (`SUBDIVISION_RESOLUTION_RATIO = 0.5`): one on the parent's
center and its six neighbours on the child lattice. Neighbouring parents share
boundary children, which are de-duplicated by child-lattice coordinate.

**Diversity (cluster-suppression) rules.** Suppression is recomputed from the
stored `base_score`. Per resolution tier it builds a dense grid over the tier's
bounding box (or a hash map when the box would exceed 8,000,000 cells), then
walks rings outward from each cell. For ring distance `d` the falloff is the
smoothstep of `t = 1 − d/(radius+1)`; the walk stops as soon as the next ring's
falloff cannot beat the suppression already found. Cells with a score of zero
or less, and a radius of 0, are left unchanged. The strongest single suppressor
is kept and recorded (neighbour hex, distance, falloff, contrast) so score
hovers can show the arithmetic.

**Ranking list.** The Top 10 list keeps the ten highest finite
*post-suppression* scores (the helper caps any request at 100). Candidates with
equal scores keep their input order, so the earlier result stays ahead.

**The Fast model identity.** A scan's frozen assumptions store its model as a
string: `cpu` (Full quality) or `fast_cpu_gpu_v1` (Fast). Older saved scans that
say `gpu` load as Fast. Any other value is rejected on load. The `_v1` suffix is
part of the saved format: changing the Fast arithmetic requires a new identity,
so a retained scan is never silently re-interpreted. Fast evaluates all 360
rays with the free-space, three-edge Deygout and two-ray model described in
[Choosing a propagation model](propagation-models.md#5-the-fast-approximation).
CPU workers and each GPU claim unique candidate ranges from a shared counter,
so a slow device only delays its own batch. A batch whose device fails is retried
once with the identical CPU approximation, and results from a superseded scan
generation are discarded. Where an SNR lands within 0.02 dB of a grade threshold,
the canonical f32 CPU loss is used instead of the GPU value, so device rounding
cannot change a grade.

---

## Where else to look

- **[Coverage maps](coverage.md)** — confirming a shortlisted site properly.
- **[From transmit power to fade margin](link-budget-and-noise.md)** — the bands
  Site Finder grades against, and the environmental noise model it can include.
- **[Choosing a propagation model](propagation-models.md)** — including the GPU
  approximation the fast path uses.
- **[Clutter, LiDAR, and canopy density](clutter-and-lidar.md)** — what the
  land-cover clutter option is charging for.
- **[Network analysis](network-analysis.md)** — ranking candidate sites that are
  already modeled as nodes.
