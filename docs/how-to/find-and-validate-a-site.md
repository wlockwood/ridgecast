# Find and validate candidate radio sites with Site Finder

Site Finder inverts the standard coverage question: instead of asking where an
existing node can transmit, it systematically scans an entire geographic area
and ranks **which locations would make the best radio sites**.

Use the scan to shortlist locations, then validate them with your actual radio
settings. A high rank does not establish that your planned system will work.
Area scans have their own transmitter and reference receiver settings; changing
**Edit test radio** does not change them. Configure the scan under
**Candidate transmitter and reference receiver**. The defaults are listed under [Radio assumptions and
range](#radio-assumptions-and-range). Results sample rays rather than every
point in the area, so finer candidate cells do not remove gaps between rays.

---

## Quick start workflow

1. **Frame your target area:** Pan and zoom so the places where you could install
   an antenna fill the map. Each candidate hexagon represents one location to test.
   For example, frame a ridge to test transmitters on that ridge; towns outside
   the screen can still contribute to their scores if within the evaluation range.
2. **Open Site Finder:** Click **Analysis → Planning → Site Finder**.
3. **Choose an intent preset:**
   - **⚡ Fast Scout** (200 m resolution, 0 recursion): Fast overview across a wide region.
   - **🎯 Standard Prospect** (100 m resolution, 1 recursion): Balanced search with land-cover clutter.
   - **🔬 Deep Ridge Hunt** (30 m resolution, 2 recursions): Finer candidate placement on ridges and peaks, with aggressive suppression; its radio rays remain sparsely sampled at long range.
4. **Set shared inputs:** Enter your operating frequency in MHz (for example,
   146 for 146 MHz) under **Settings → Network Frequency…**
   and the evaluation distance under **Coverage → Default radius** in the right-hand workbench. Choose the distance to the farthest area you
   want each candidate to serve, in every direction. Choose the scan's radios
   under **Candidate transmitter and reference receiver**. The legacy preset
   uses a 30 dBm, 5 dBi transmitter at 10 m and a receiver at 2 m;
   **Edit test radio** does not replace these radios. See
   [Radio assumptions and range](#radio-assumptions-and-range) for losses and noise.
5. **Start the scan:** Use **Start CPU Scan** if unsure which button to choose.
   It uses the model selected under **Settings → Application Preferences → Propagation**. For faster
   exploratory Longley–Rice evaluation, use **Start GPU Scan**. If it reports
   **Error: GPU Engine Required**, use the CPU button. With other models, both
   buttons use the same CPU path, so the GPU button provides no speed benefit.
   Results stream onto the map.
6. **Inspect candidates:** When the scan completes, click a **Top 10 Sites**
   entry to center and highlight its cell. Hover over the cell for its metrics.
7. **Refine:** Right-click a result hexagon on the map and choose **Subdivide and Scan**.
8. **Place a node:** Right-click the intended antenna position and choose
   **Add Node Here**, then configure and validate the new node as described below.

After results change, map hover details and cell selection may briefly wait for
background preparation. During this pause, clicking the map preserves the current
site, node, and amateur selection and does not extend the ruler. Node, link, and
amateur-marker controls remain available. A right-click menu opened during the
pause says **Site lookup updating**; reopen it when ready for cell actions or
empty-map ruler actions. Very large imports may also need a short pause after
moving the pointer. Imported cells are still checked in full, in reverse drawing
order; overlapping cells are not resolved by score or cell size.

Check the cell-count, runtime, and terrain-download estimates before starting.
Runtime estimates depend on previous measurements and may not yet be available.
**Stop Scan** retains partial results. A new top-level scan replaces old results;
export first if needed. The visible bounds at scan start determine where
transmitters are tested; their evaluated coverage can extend beyond the viewport.

---

## Choosing search presets

| Preset | Grid Resolution | Recursions | Clutter | Best for |
| :--- | :--- | :--- | :--- | :--- |
| **⚡ Fast Scout** | 200 m | 0 | Off | Wide regional surveys, fast GPU sweeps |
| **🎯 Standard Prospect** | 100 m | 1 | On | General network expansion, balanced knoll identification |
| **🔬 Deep Ridge Hunt** | 30 m | 2 | On | Finer candidate placement in complex terrain; validate paths afterward |

> [!TIP]
> Cell count grows quadratically with finer resolution ($\text{Count} \propto 1/\text{resolution}^2$).
> Always use a coarse pass (**Fast Scout**) over broad viewports, then zoom in or use **Subdivide and Scan** for high-resolution refinement.

---

**Auto-Recursion Depth** is the number of automatic refinement passes. After a
pass completes, the top 10 candidates each receive seven child hexagons at half
the parent cell size. Overlapping children are deduplicated. Refinements overlay
the original grid without changing the Evaluation Resolution slider. Manual
subdivision adds the same kind of cluster around your chosen cell.

For example, Standard Prospect first scans 100 m cells, then refines its best
sites with 50 m cells. Deep Ridge Hunt starts at 30 m, then refines at 15 m and
7.5 m. The resolution is the hexagon's nominal center-to-corner size; the map
shows a labeled example when you change **Evaluation Resolution (m)**.

For scale, 100 m cells produce about four times as many candidates as 200 m cells
in the same viewport. Deep Ridge Hunt also sets **Best-Site Radius** to 8 and
**Jealousy** to 0.80; the other presets leave those settings unchanged. Presets do
not change **Site Sample Type**. Choose **Highest Point in Hex** explicitly for
hilltop sampling.

## Configuring scan parameters

### Radio assumptions and range

Under **Candidate transmitter and reference receiver**, choose a **Transmitter
system** and **Reference receiver system**, or edit each endpoint's height,
gain, and loss, plus transmitter power and receiver threshold, noise figure,
and bandwidth. Selecting a system copies its settings; later system edits do
not change the scan preset. **Use legacy preset** restores the defaults below.

The legacy preset uses a transmit antenna 10 m above ground, a receive antenna
2 m above ground, 30 dBm transmit power (1 watt),
5 dBi transmit antenna gain, and
2 dB transmit loss. Together these give 33 dBm effective isotropic radiated power
(EIRP). The receiver adds 5 dBi gain and subtracts 2 dB loss. Its scoring floor
starts at the selected receiver threshold, −100 dBm in this preset.
**Factor in Environmental Noise** (off by default)
adds one nonnegative modeled penalty sampled near each candidate and reuses it
for every receiver point on that candidate's rays. It uses the selected
receiver's bandwidth and noise figure, 125 kHz and 6 dB in the legacy preset;
the resulting floor can therefore exceed
−100 dBm. This is separate from the configurable coverage Test Node.

Here dBm expresses power relative to 1 milliwatt, dBi expresses antenna gain
relative to an ideal antenna radiating equally in all directions, and dB loss
is subtracted from the signal budget. The noise floor is the assumed background
level against which the received signal is compared.

Editing coverage's **Edit test radio** does not change the scan's separate
radio settings. The scan also uses network frequency,
global coverage range, and signal-band thresholds. Configure your actual radio
and antenna settings when validating a placed node.

Antenna heights are above ground, not elevations above sea level.
**Highest Point on Land Cover** instead places the transmitter above the modeled
clutter surface, such as a building or tree canopy: the selected transmitter
height (10 m in the legacy preset) is added above the sampled ground-plus-clutter
height, rather than above bare ground.

The global range is the maximum distance evaluated from each candidate; it does
not enlarge the area where transmitters are placed. Each candidate is evaluated
along 360 directions with samples at successive distances. These coverage
samples are separate from the candidate hexagons on the map.

### Terrain & Land Cover

- **Site Sample Type:** Decides where within each hexagonal cell the hypothetical antenna is mounted:
  - **Height at Hex Center (Default):** Samples elevation at the exact centroid of the hex.
  - **Average Height in Hex:** Computes the mean ground elevation across a 5×5 sample grid inside the hex.
  - **Highest Point in Hex:** Finds the highest ground elevation inside the hex (ideal for hilltop searches).
  - **Highest Point on Land Cover:** Evaluates ground plus tree canopy/building clutter height (ideal if planning a mast atop local structures/canopy).
- **Factor in Land Cover Clutter:** Incorporates modeled trees and buildings into
  path profiles and accounts for canopy attenuation. It can download land-cover
  tiles and increase runtime. NLCD means National Land Cover Database.

These are samples, so the highest point found is not guaranteed to be the exact
summit. The land-cover option models an antenna above the surface; it does not
establish that a building or canopy is a practical mounting location.
Terrain and land-cover availability affect predictions; see
[Work offline and manage caches](work-offline-and-manage-caches.md).

---

## Scoring adjustments: Water and Population

### Water Area Value & Coastline Attenuation (Discounting Water Bodies)

When searching coastal, island, or lakeside areas, raw geographic coverage can
cause candidate sites facing open ocean or large water bodies to score artificially
high, even when no terrestrial users exist there.

- **Water Area Value** displays a percentage: 10% is the default. With coastline
  attenuation off, it scales positive contributions from covered water samples
  relative to land: 0% earns no credit, and 100% earns the same credit as land.
  With attenuation on, it sets the offshore floor described below. Uncovered
  samples still incur the normal penalty described below.
- **Coastline Attenuation** (enabled by default) smoothly scales water value
  based on distance from the nearest shoreline along the line of sight. Nearshore
  waters (ports, bays, harbors, coastal shipping lanes) retain high value (approaching 100%),
  while coverage stretching out into open ocean falls off exponentially toward the
  configured Water Area Value floor.
- **Coast Falloff Distance** (default 3.0 km) sets the characteristic distance
  constant for shoreline attenuation. At 1× this distance from shore, water coverage
  retains ~37% of the difference between full value and the floor. With a 10%
  floor and 3 km falloff, a water sample 3 km from shore earns about 43% of land value.
- Detection uses loaded NLCD Open Water data (class 11). Without a usable class,
  it treats elevation at or below sea level as water. This fallback can mistake
  low-lying land for water and miss lakes above sea level.
- Enable land-cover clutter to request land-cover data during the scan, but do
  not assume classification is available everywhere. Use 100% to avoid a water
  discount where classification is uncertain.

### Grade by Population

When planning community broadband, emergency networks, or VHF/UHF repeaters,
reaching populated towns and settlements is often far more critical than covering
unpopulated wilderness.

Enable **Grade by Population** to weight covered samples by WorldPop population
raster values (estimated people per data pixel). Before cluster suppression:

`Score = Good population × 1.0 + Fair population × 0.5 + Marginal population × 0.1`

Uncovered samples contribute zero in this mode. Water Area Value does not scale
the population score. Treat it as a ranking measure, not a count of distinct
people served: values are sampled along the coverage rays.

When enabled, Site Finder shows **Population data** readiness for the visible
search area plus the evaluation range: **missing**, **partially available**,
**downloading / loading**, or **ready**. This checks loaded raster extents and
approximate country discovery, not every pixel or exact borders: no-data pixels
can still leave gaps. For recognized countries, storage rectangles wider than
180 degrees are checked against discovery so rasters crossing the antimeridian
do not stand in for unrelated search countries. Ordinary loaded rasters retain
an extent-based check, including islands outside the approximate discovery boxes.

Enter a three-letter **Country code** (for example **USA**, **CAN**, or **AUS**)
and click **Load / Retry Population Data**. The application loads the cached
WorldPop 2020 UN-adjusted constrained raster or downloads it from your configured population sources in the
background. Load each country needed by the scan. Failed or canceled loads can
be retried with the same button; cached data works offline.

Population scans cannot start while data is loading or when no loaded raster
overlaps the search area and range. Partial availability is reported but allows
a scan; missing pixels contribute zero. Turn off **Grade by Population** to use
geographic scoring without population data. A zero population score does not
prove nobody lives there. After loading data, start a new scan: existing
candidate scores do not update automatically.

**View → Node Colors → Site Score (Population Weighted)** is a separate coloring mode for
existing nodes; it does not enable population grading for candidate scans.

Changing water, population, sampling, or shared radio inputs requires a new scan
to evaluate candidates under the new assumptions.

### Factor in Environmental Noise

With environmental noise off, Site Finder uses the selected reference receiver
threshold across all candidate locations: −100 dBm in the legacy preset.

Enable **Factor in Environmental Noise** to sample each candidate site's surrounding
land cover (NLCD) and population density (WorldPop) once per candidate:
- Uses the ITU-R P.372 / Hagn/NTIA man-made noise models to compute external noise power.
- Blends human population density when loaded to account for active electronics and vehicle emissions.
- Adds the resulting penalty to the selected receiver threshold, −100 dBm in
  the legacy preset.
- Penalizes candidate sites located in noisy urban centers or industrial parks, favoring
  sites situated on quiet ridges, rural towers, or forested elevations where the real-world
  noise floor is substantially lower.
- Uses the radii, weights and population blend configured under **Ambient Noise** in the
  network settings, and applies to the per-node scores in the inspector as well as the sweep.

Population data is sampled whether or not **Grade by Population** is on — the two settings
answer different questions about the same raster.

The candidate transmits toward hypothetical receivers along its rays; this is
not a bidirectional link calculation. The environmental penalty is a site-local
ranking proxy reused at all those receiver points. CPU and GPU scans sample that
legacy proxy at the recorded candidate origin, which can differ from the cell
center under highest-point strategies. Validate placed nodes with actual TX and
RX coverage and links.

When the optional [atmospheric component](../reference/scientific-models.md#p372-atmospheric-noise-at-2030-mhz)
is enabled alongside environmental-noise factoring, the CPU scan evaluates noise
at each actual receiver point instead. Compatible measured floors keep precedence.
Missing requested atmospheric inputs or frequencies outside 20–30 MHz leave
those samples unknown, reported separately from failed coverage. The selected
noise configuration is frozen with the scan; this option disables GPU dispatch.

On a shared band (902–928, 863–870, 433 MHz) it also models the in-band traffic of
other radios and the desensitization a strong adjacent service causes in a poorly
filtered receiver. Between a dense-urban and a forested candidate the floor moves about
10.6 dB at 146 MHz and about 9.0 dB at 915 MHz, so it can genuinely reorder a shortlist.
Scans are slower with it on and may download tiles.

The absolute floors are priors, not measurements — the in-band traffic figure especially.
Use it to rank candidates, then verify the shortlist against a real noise measurement.

---

## Finding where to expand an existing network

A plain scan ranks sites by their total reach, so when you already have nodes the
top results tend to sit where you are already covered. **Skip Existing Coverage**
ranks sites by the coverage they would *add* instead.

1. **Calculate coverage for the nodes you already have.** Select them and run a
   coverage calculation, as described in
   [Generate and export a coverage map](generate-and-export-coverage.md). Site
   Finder filters against whatever coverage is currently shown on the map.
2. In the Site Finder window, enable **Skip Existing Coverage**.
3. Choose **Already Served At**: the coverage color band at which ground counts
   as already served:
   - **Marginal or better** skips everything your network reaches at all, so
     candidates are ranked purely by new ground.
   - **Fair or better** (the default) also gives candidates credit for shoring up
     Marginal areas.
   - **Good only** also rewards strengthening Fair and Marginal areas.

   The dB figure beside each choice comes from the network's coverage color
   thresholds.
4. Start a scan. A note under the control shows how many coverage cells the scan
   will filter against. If it says there is no coverage yet, nothing is skipped.

Skipped ground contributes nothing to a candidate's score, neither the reward for
covering it nor the penalty for missing it. A commanding hilltop in the middle of
your footprint therefore scores near zero, and the heatmap lights up the places
that would fill gaps. Scores are only comparable within one scan, so compare
filtered and unfiltered results by their ranking, not by their numbers.

Keep in mind:

- The setting applies to scans started after you change it, including
  **Subdivide and Scan** and automatic recursion. Existing results are not
  rescored.
- If coverage is still calculating when you start a scan, only the finished part
  is skipped.
- Recalculating or clearing coverage changes what later scans filter against.
- The Site Finder score view for FCC amateur records uses the same filter.
- Existing nodes' own site scores never use it, since every node covers its own
  surroundings.

After you pick a candidate, add it as a node and recalculate coverage to see what
it fills in. The next filtered scan then looks for the gaps that remain.

---

## Cluster suppression and jealousy

When scanning a prominent mountain ridge, dozens of adjacent hexagonal cells will
all yield similar high scores. Without filtering, your top-10 list would be filled
entirely by minor variations along that single ridge.

Site Finder applies **Cluster Suppression** to ensure diversity among top candidates:

- **Best-Site Radius (hexes ≈ … m):** Hexagonal neighborhood radius within which inferior
  cells are suppressed by a stronger peak.
- **Jealousy (0.0 to 1.0, default 0.75):** Controls how aggressively a higher-scoring
  peak suppresses nearby candidates:
  - **0.0 (Proportional):** Suppression is scaled strictly by score difference.
  - **1.0 (Winner-Take-All):** Any strictly higher neighbor suppresses lower cells
    across the full radius.
  - **0.75 (Default):** Surfaces distinct geographical summits and ridgelines while
    hiding redundant adjacent steps.

> [!NOTE]
> Changes to the sliders configure future scans. Choose **Apply current suppression**
> to recompute displayed rankings in a background worker, or **Use original suppression**
> to use the completed scan's captured values. Signal predictions are unchanged.

Set the radius to 0 to inspect raw scores without suppression. Increase radius
and jealousy if one ridge dominates the shortlist. The meter label describes
the base grid; refinement cells use the same hex count at their smaller size.

---

## Evaluating and shortlisting candidates

Results appear on the map during a scan; **Top 10 Sites** appears after completion.
The list briefly shows **Ranking sites…** while a background worker prepares the
current results. During that update, ranking buttons are hidden so an old list
cannot select an outdated candidate. Map interaction remains available. Changing
opacity or blend mode reuses the current ranking; completed scans, imports,
refinement results and applied suppression refresh it.
Hover over a result hexagon for its metrics. Compare candidates with the same
scan assumptions; there is no universal acceptable score.

### Candidate Metrics

- **Adjusted score / Raw score:** The Top 10 list and candidate hover details
  show both. Adjusted score ranks candidates after cluster suppression; raw score
  is the value before suppression. Changing suppression does not change signal
  predictions. With population
  grading off, each Good sample adds 1, Fair adds 0.5, Marginal adds 0.1, and None
  subtracts 0.1. Covered-water contributions use the water and coastline weighting
  described above.
  Negative scores are possible.
- **Good / Fair / Marg / None:** Counts and percentages of evaluated ray sample
  points, not people or square kilometers. Each point counts once; these raw
  percentages are not area-weighted. Bands use signal-to-noise ratio
  (SNR: received power above the assumed noise floor). Defaults are Good ≥ 20 dB,
  Fair ≥ 10 and < 20 dB, Marginal ≥ 0 and < 10 dB, and None < 0 dB. Review current
  thresholds under **Settings → Fade Margin Settings**. Despite that dialog's
  name, the area scan uses SNR against its baseline plus modeled environmental
  noise penalty.
- **Avg Elevation:** Average sampled ground elevation across the cell, not
  antenna height or necessarily the elevation of the sampled summit.
- **Fortuity Score:** `Score / max(Avg Elevation, 1)^2`, with elevation in meters.
  Elevation is clamped to at least 1 m before squaring, avoiding division by zero
  at zero or negative elevations. This favors lower-elevation sites relative to
  their score; it is a heuristic, not a physical efficiency measure or acceptance
  threshold. Use Score for the shortlist; Fortuity is optional context when
  looking for lower-elevation alternatives. Give particular care near sea level.
- **Existing node hover scores:** These use node-specific inputs and may still
  be calculating. Use them for context, not as a direct like-for-like comparison
  with the candidate scan unless their radio assumptions match.

---

## Refining and placing nodes

1. Click a **Top 10 Sites** entry to locate its evaluated origin; the outlined
   hexagon still marks the original scan cell. Right-click the hexagon
   and choose **Subdivide and Scan** for a finer search nearby.
2. Choose **Review node at evaluated origin…** from the result context menu, or
   use the selected site's origin controls. Review the frozen transmitter settings
   and choose **Confirm frozen radio and create node**. This creates one undoable
   node at the recorded sampled coordinates and starts validation with current
   terrain and propagation settings. Old results with an unknown origin cannot
   use this action. **Add Node Here** remains available for placing a default node
   at the pointer position.
3. Check the node's actual coordinates, system, antenna height above
   ground, power, gain, and losses. A recorded average or canopy-top elevation is
   a virtual scan assumption, not a surveyed ground elevation; current validation
   resolves the real terrain again. See
   [Create and configure a network](create-and-configure-a-network.md).
4. Choose a model under **Settings → Application Preferences → Propagation**. Longley–Rice (ITM, the
   Irregular Terrain Model) and **Terrain diffraction (P.1812-inspired)** model
   terrain effects. The latter is a terrain-only approximation without clutter
   loss, not a complete P.1812 implementation; read
   [Model limitations](../reference/model-limitations.md) before comparing them.
   GPU Longley–Rice is an approximation; use CPU calculations for follow-up checks
   with your intended node settings.
5. Select the new node, then Shift-click an existing site. Open its link profile
   and inspect clearance and predicted signal margin in both directions. Follow
   [Evaluate a radio link](evaluate-a-radio-link.md) for the detailed checks.
   If there is no second site yet, proceed to coverage validation; add a second
   configured node when you have an intended point-to-point path to test.
6. Calculate the node's coverage with the intended receiver settings using
   [Generate and export a coverage map](generate-and-export-coverage.md). Check
   the places you need to serve. Different radio assumptions and models can change
   results; there is no fixed acceptable discrepancy between scan score and validation.

Use the predictions to shortlist locations for field checks before committing
to an installation.

---

## Exporting results

Use these controls in the Site Finder window:

- **Export JSON...:** Choose a file to save the base grid and refinement results,
  including coordinates, cell sizes, raw/displayed scores, and band counts.
  Version 2 also retains the original resolved transmitter/reference receiver,
  propagation and source settings, bounds, thresholds, sampling/refinement,
  weighting, actual CPU/GPU backend, coverage-exclusion fingerprint, and
  suppression. Editing controls after completion does not rewrite these inputs.
  JSON imports and exports are bounded to 64 MiB and 500,000 candidates.
- **Import JSON...:** Choose a previously exported file. It replaces current
  results and their original displayed scores. Choose original or current
  suppression explicitly. Importing does not restore active network settings.
  Older files show unknown original assumptions and unknown evaluated origins.
  Refinement of a retained scan uses its frozen radio and propagation inputs;
  it still requires terrain data.
- **Export CSV… / Export GeoJSON…:** Choose **Full results**, **Top 10**, or
  **Selected site**. Base and refinement tiers share one stable ranking. Exports
  include adjusted/raw scores, per-band and unavailable counts, per-result
  resolution, hex centers, evaluated origins, and provenance. GeoJSON is WGS84
  longitude then latitude. Unknown legacy origins use the center with an
  explicit unknown flag. CSV stores full provenance in its first exported row;
  all rows refer to the same provenance hash. GeoJSON stores it once on the
  FeatureCollection. Both formats write atomically and support cancellation.
- **Export Image...:** Choose a PNG destination. The image includes the whole
  result set over basemap tiles at the map's current zoom. Set that zoom first;
  large extents reduce zoom automatically to fit the 8192-pixel image limit.
  **Cancel Site Finder export** stops the active export,
  preserving any previous destination. Work Offline prevents new tile requests;
  unavailable basemap tiles use a plain background. Closing Site Finder keeps
  the image export running, and reopening shows its separate export status.

Select a top site or use its map context menu to **Copy evaluated coordinates**
or **Create node at evaluated origin…**. Confirm the frozen transmitter radio
before creation; this records one undoable node addition. The hex center and
evaluated transmitter can differ. Average-terrain and canopy-top elevations
are virtual model inputs, not surveys: the created node recalculates local
terrain, and canopy-top placement uses a surface height reference to avoid
adding canopy height twice.

For network and node coverage GIS exports, see
[Import overlays and export GIS](import-overlays-and-export-gis.md).

---

## Related documentation

- [Finding sites: how Site Finder scores ground](../concepts/site-finder.md) — in-depth mathematical concepts, ray casting, and noise models.
- [Coverage maps](../concepts/coverage.md) — calculating and interpreting full node coverage.
- [Choosing a propagation model](../concepts/propagation-models.md) — differences between GPU approximation and full CPU ITM propagation.
- [From transmit power to fade margin](../concepts/link-budget-and-noise.md) — link budgets, SNR, and fade margin thresholds.
