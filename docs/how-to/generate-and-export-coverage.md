# Generate and export a coverage map

Use this guide to calculate coverage for one or more sites and export the result
for use in GIS software.

Coverage asks how a configured hypothetical far-end radio—the **Test Node**—would
fare around each selected site. Set its radio and antenna parameters under
**Edit test radio** inside **Coverage** in the right-hand
settings panel before calculating;
use **TX** when the selected site transmits to that radio, and **RX** for the
reverse direction.

## Calculate coverage

1. Select the radio nodes to evaluate. Use **Ctrl+A** to select all nodes;
   an empty selection clears the displayed coverage. Changing the selection
   starts or updates the background calculation automatically.
2. In the right-hand settings panel, open **Coverage** and set
   the coverage range for the area you actually need, then begin with **Draft**.
   The range is the radius evaluated
   around each selected node; start small and enlarge it only when needed.
3. Under **Calculation options**, choose **Vertex Grid** for continuous output or **Radial Sweep** for a faster
   exploratory result.
4. Choose **TX** (`selected node → Test Node`) to show where the
   selected nodes can be heard, or **RX** (`Test Node → selected node`)
   to show where they can hear the configured Test Node.
5. Use **Coverage question** to choose **Strongest signal / fade margin**,
   **Best serving site**, or **Coverage redundancy** for multiple sites.
   **Unique contribution of one site** compares one selected network radio with
   the rest of the network. Unavailable choices explain their selection requirements.
6. Watch **Calculation Progress** until its completion summary appears, then
   reduce the cell size or angular step only if the draft covers the intended
   area. Smaller cell sizes are finer map spacing; smaller angular steps add
   rays for Radial Sweep.

A successful run draws colored cells around the selected site. If no cells
appear, use **Calculation Progress** to identify unfinished or failed work,
then check that a radio node is selected and that its range and Test Node are
configured.

On a first run, RidgeCast queues missing terrain, land-cover, and enabled LiDAR
data for the full evaluation area. Overlapping sites share tile requests. Sites
with ready inputs calculate while other sites' downloads continue, so the status
may show **Calculating (CPU) · 3 waiting for downloads**. **Waiting for downloads**
means data has not arrived, **Queued** means a site is ready for a worker, and
**Preparing profiles** means it is reading the next batch of paths. Only
**Calculating** names active propagation work. Changing the selection or settings
cancels the previous run as usual.
The window's **Fetching terrain** and **Fetching LiDAR** steps can remain active
while **Sampling terrain** or **Solving coverage** progresses for ready sites.

Purple cells marked `?` mean required terrain was unavailable, not that the
signal failed. Offline cache misses require an online download; online source
failures need inspection in **Downloads**, and blank/NoData pixels may require
enabling a fallback terrain dataset. See
[Missing terrain and disabled datasets](../reference/data-sources-and-caches.md#missing-terrain-and-disabled-datasets)
before repeatedly recalculating.

Use **Best Unit** before analyses that require a serving-node breakdown. In the
finished map, fade margin/SNR is in dB and larger is more modeled headroom;
**Redundancy** counts nodes that meet the configured threshold. Fine resolution
and long range increase work quickly; refine the smallest useful area.

With GPU acceleration enabled in ITM mode, dragging a node shows an approximate
preview of the visible area. The preview uses at most 3,000 cells and may use
larger cells than your selected resolution to stay responsive. Moving the node
again cancels the previous preview; releasing it starts the full calculation at
the normal coverage settings. Clutter is still included in the preview.

## Reopen coverage in a later session

Completed coverage is cached automatically for each node. The working network
autosave remembers your selected network nodes, Test Node, coverage direction,
algorithm, merge mode, clutter settings, and display controls. **Save Network
As...** includes these settings in the file you choose. Reopening a saved network
restores the selection and loads matching grids in the background; missing or
outdated grids are calculated normally. Older files open with no selection.

Under **Settings → Application Preferences**, the **Coverage** cache category
shows disk usage and lets you change its budget or clear it. The initial budget
is 1 GiB on a new configuration. Existing cache-budget files retain their chosen
limits; an absent Coverage limit means unlimited.

The cache belongs to this installation. Copying a network file to another machine
copies its settings, and coverage is calculated there unless matching cached
grids are already present. Imported coverage images and temporary selections of
FCC records are not restored by this feature; add records as network nodes to
include them in the saved selection.

## Export GIS data

1. Choose **File → Export → GIS Data (KML, GeoJSON, GeoTIFF)…**.
2. Select the network objects and coverage output to include.
3. For GeoTIFF, choose **Color Categories**, **SNR (dB)**, or
   **Receive Power (dBm)**.
4. Optionally include enabled custom vector layers or restrict topology to the
   selected nodes and links.
5. Choose the destination and wait for the background export to finish.

Every coverage GeoTIFF is accompanied by an ESRI `.tfw` world file. Keep the two
files together when opening the raster in QGIS, ArcGIS, or Global Mapper.

## Export a coverage image (PNG/JPEG)

While a coverage image is rendering, **Cancel export** stops acquisition,
rasterization, statistics, and encoding. Existing image destinations remain
intact. Closing the dialog keeps the job running; reopening shows its progress
and result. Canceled jobs do not copy a newly rendered image to the clipboard.

1. Position and zoom the map to the desired geographic viewport. Use **Fit to Evaluation Range** (in the export dialog, in the map’s **Fit** menu, or under **View**) to zoom and pan the viewport to exactly fit the evaluation range of coverage nodes. Use **Fit to Visible Coverage** to zoom and pan the view to exactly fit all visible hexels of coverage according to the fade margin settings.
2. Choose **File → Export → Coverage Image…**.
3. Select an output resolution multiplier (**1x**, **2x**, **4x**, or **8x**).
4. Optionally toggle **Show links** to draw calculated directional network links
   over the coverage. Links use the current link color mode and fade-margin
   filter; links to hidden sites are omitted. If links are hidden under **View**,
   this option still draws them in fade-margin colors. Links crossing the image
   are included even when their sites are outside it.
5. Optionally toggle **Include site markers** to draw site dots with owner/status colors.
6. Optionally toggle **Include site labels** to draw site name labels below each marker, matching the active name mode (**Full Names** or **Short Names** configured under **View**).
7. Optionally toggle **Include site legend** to caption sites with their
   parameters. Under **Evaluation figures**, choose evaluated footprint and
   population figures. See
   [Caption sites with a legend](#caption-sites-with-a-legend) and
   [Report evaluated footprint and population](#report-evaluated-footprint-and-population)
   below.
8. Click **Export...** to choose a destination file path (`.png` or `.jpg`), or click **Copy to Clipboard** to render and copy the image directly to the system clipboard without saving a file to disk. Saving a file does not automatically copy it to the clipboard.
9. When the render finishes, **Open image** opens the file in your default image
   viewer, **Open containing folder** shows it in your file manager, and **Copy to clipboard** copies the exported image to the system clipboard at any time.

Site labels and legend text render newly encountered characters at the chosen
export scale, including 8x, without needing to display those names on the map
first. Character availability depends on the application's fonts.

See [Coverage modes](../reference/coverage-modes.md) for option definitions and
[Coverage maps](../concepts/coverage.md) for how the calculation works.

### Caption sites with a legend

**Include site legend** captions each site in the image with the parameters you
pick. It is available whenever there is at least one site to describe.

Which sites are captioned:

- If any sites are selected on the map, the legend describes the selection.
- With nothing selected, it describes every visible site inside the exported
  viewport.
- At most 24 sites are captioned. The dialog reports how many were found, so a
  larger network shows the cap before you export.

**Layout** chooses between the two shapes:

- **Single box** gathers every site into one card.
- **Callouts** give each site its own card with a line back to its marker.

Callouts are preselected when more than one site is being described and a single
box when there is only one. Moving the toggle yourself fixes the choice for the
rest of the session, so changing the map selection afterwards does not undo it.

**Show under each site name** picks the facts each caption carries, grouped as
Identity, Radio, and Antenna. **All**, **None**, and **Reset** set the whole
group at once. The site's own name is always the first line; with no facts
selected, the name is all a caption shows. A fact that does not apply to a site
is left out rather than printed empty — an omnidirectional antenna, for example,
has no azimuth, beamwidth, or front-to-back ratio to report. Values come from
each site's resolved profile, so system inheritance and azimuth locks are
already applied.

Cards are placed automatically wherever they hide the least coverage, counting
the ground a callout's leader line crosses as well as the card itself. Cards
never overlap each other, a site marker, or its name label. A card with nowhere
left to go is dropped and reported in the status line after the export, rather
than drawn over the map. A site outside the exported viewport gets no callout,
because there is no marker in the image to point at; a single box lists it
regardless.

### Report evaluated footprint and population

Two options under **Evaluation figures** report the footprint of the current
coverage run and the population inside it. Either or both can be on.

- **Add an evaluation stats card** adds a **Whole-run evaluation** card with
  **Evaluated footprint** and **Evaluated population** totals. It is placed
  wherever it hides the least coverage, like every other card. It claims its
  position before the site cards, so the two never overlap.
- **Add each site's winning footprint** appends the same figures to each
  captioned site, below the facts you picked. Each site gets the cells assigned
  to its recorded winning owner. Because the figures go into a site's caption,
  this one needs **Include site legend** on with at least one site to describe;
  the stats card works on its own, with the legend off or with no sites in the
  viewport.

**Detail** applies to both:

| Detail | Each figure reads |
| --- | --- |
| **Totals only** (default) | Evaluated footprint, then evaluated population. |
| **Totals with ratios** | Totals plus a percentage: whole-run cards use the free-space footprint; site captions use the network's evaluated total. See the example below. |
| **Per band** | A line for Good, Fair, Marginal, and Poor, matching the map's colors, then the totals. |

**Evaluated totals include Poor cells and hidden fills.** They sum cells with
usable terrain across the whole current coverage run, including cells outside
the exported image's viewport. These totals measure the evaluation footprint;
use the per-band figures to distinguish signal quality. For example, 10 km²
Good, 5 km² Fair, 3 km² Marginal, and 2 km² Poor produce a 20 km² evaluated
footprint, with 18 km² in the three positive coverage bands. Per-site figures
total that site's winning cells, rather than every cell the site can reach.

The larger options make taller cards, which leaves the placement search less
room to keep them off the coverage. A card that will not fit is dropped and
reported in the status line after the export.

Ratios use a different denominator depending on what is being described, and
each line names which:

- A **stats card** is reported against the **free-space footprint** — cells
  within the sites' evaluation ranges that pass the Marginal cutoff using the
  same radio budget with free-space path loss instead of terrain obstruction.
  Overlaps are counted once. The numerator also includes Poor cells, so both
  area and population ratios can exceed 100%. These ratios compare evaluated
  totals with a baseline under the chosen radio, range, and threshold
  assumptions; they do not measure usable service.
- A **site** is reported against the **network footprint** — the whole run's
  evaluated total. This is the share assigned to that site's winning cells.
  The free-space footprint is deduplicated across every site, so it cannot
  serve as a site's own free-space baseline.

For example, if the free-space footprint is 100 km² and the evaluated footprint
is 40 km², the stats card's area ratio is 40%. If one site's winning cells make
up 10 km² of those 40 km², its area share is 25%. Population shares use people
in the corresponding footprints rather than area, so they can differ from
area ratios. If the evaluated footprint is instead 120 km², its ratio to the
100 km² free-space footprint is 120%. A ratio is omitted when its denominator
is zero, independently for area and population.

Two limits are worth knowing before you rely on these figures:

- **Per-site figures need a merge mode that records who won each cell.**
  Calculate coverage with **Best Unit**, **Redundancy**, or **Unique
  Coverage**. **Max Fade Margin** keeps the strongest signal without recording
  whose it was, so per-site figures cannot be worked out and the option is
  disabled with a tooltip saying so. The stats card works in every mode.
- **Population needs a WorldPop raster to be loaded.** With none, the figures
  report land area only, and the dialog says so before you export. No
  population line is printed rather than a population of zero — over a populated
  area a confident "0" would be worse than saying nothing. See
  [Data, caches, mirrors, and working offline](../data-and-caching.md) for which
  countries download quickly.

Land area is measured from each drawn cell's own polygon, so cells at different
latitudes contribute the ground they actually cover. Cells whose terrain was
unavailable offline are left out of both figures, because nothing was computed
for that ground.

## Compare transmitter heights

1. Choose **Analysis → Planning → Transmitter Height Impact…** and select one enabled transmitter.
2. Enter a lower and higher antenna height in meters. These heights use the
   transmitter's configured height reference; its other radio settings and
   coverage range stay the same. The study uses TX Coverage from the chosen
   transmitter to the configured Test Node, regardless of the current map
   direction. Set the Test Node under **Coverage → Edit test radio** in the right-hand panel before running the study. The dialog
   shows the active Test Node and SNR threshold; the result retains the values
   used at calculation time.
3. Choose **Height impact map** and click **Calculate**. Green cells gain
   coverage at the higher height and red cells lose coverage. The current SNR
   threshold defines what counts as covered. The result reports gained, lost,
   and net area; clear **Show height impact on map** to return to the previous
   coverage view. **File → Export → Coverage Image…** exports the impact view as
   PNG or JPEG.
4. Choose **Animated GIF**, set a height step, and click **Calculate** to save
   an animation of coverage from the lower through the higher height. The
   higher endpoint is always included. Each frame displays its antenna height.
   Optionally include the current basemap and an SNR color legend. The basemap
   is fetched once before encoding and requires an active basemap and online
   mode. After either study, a chart shows covered area at each calculated
   height. The chart and gain/loss totals use the same cells with terrain
   available at every height.

The study runs in the background, leaves the network's stored antenna height
unchanged, and uses the current map viewport for GIF output. GIFs use a white
background unless **Include current basemap** is selected. They have a 4
megapixel viewport limit and a 20-frame limit. The SNR legend is omitted if
the viewport is too small, with a notice after export. Cells unavailable
offline are excluded from area totals and gain/loss comparisons. If coverage
settings change while the study runs, the study stops so its height frames
cannot use different assumptions. Use **Cancel**
to stop an in-progress study. If the required terrain exceeds the configured
cache budget, the study pauses for your decision before downloading it.
