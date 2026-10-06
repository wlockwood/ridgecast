# Data sources and caches

RidgeCast downloads public data on demand and stores it locally. Built-in
sources require no API keys.

## Data providers

| Data | Default providers |
| --- | --- |
| Basemaps | OpenStreetMap, OpenTopoMap, Esri World Imagery |
| Elevation | USGS 3DEP, Copernicus GLO-30, legacy Skadi/SRTM HGT |
| Land cover | MRLC/NLCD |
| Terrain-display water mask | Bundled Natural Earth ocean/lake polygons, refined by cached NLCD |
| LiDAR | USGS 3DEP and NOAA Digital Coast public point clouds |
| Population | WorldPop 2020 UN-adjusted constrained rasters via the RidgeCast mirror and WFP / Source Cooperative |
| Amateur licenses | FCC ULS bulk amateur archive |
| Geocoding | U.S. Census geocoder and postal-area data |
| Node sources | User-configured URLs |

Downloaded or queried data can disclose the geographic area being studied to
the selected provider. RidgeCast has no telemetry, analytics, crash reporting,
or update check.

## Missing terrain and disabled datasets

Both coverage calculations and the terrain display honor each raster's NoData
values. A blank pixel in a higher resolution dataset falls back to an enabled
lower resolution dataset, such as Copernicus GLO-30. A downloaded USGS tile can
contain blank areas outside its actual survey coverage; the tile's presence
does not mean every point has an elevation.

Coverage still renders the portions it can evaluate. **Purple cells with a `?`**
indicate missing terrain along a path, whether online or offline. They are
excluded from coverage and population totals, and incomplete per-node results
are not saved in the coverage calculation cache.

When a disabled dataset may fill those gaps, a completed calculation offers:

- **Enable dataset _dataset name_ and try again** — saves that dataset's enabled
  setting and recalculates the same coverage. It can use cached tiles and
  download additional tiles while online.
- **Continue without _dataset name_** — keeps the available coverage and leaves
  the dataset disabled.
- **Don't ask again** — disables these prompts for all terrain datasets and
  saves that preference, whichever action you choose.

The prompt is enabled by default. Restore or disable it with **Ask to enable
missing terrain datasets** under **Settings → Terrain & Geodata Settings →
Terrain Data Sources**, where you can also enable datasets yourself. The dialog
shows this location. Enabling a dataset does not override **Work Offline**;
only cached tiles can be used until you return online. A suggested dataset may
provide missing terrain, but its availability is not guaranteed.

The prompt also considers missing paths where another node supplies coverage.
Those cells keep their available result, but their serving-node or redundancy
result may be incomplete until all selected nodes can be evaluated.

## Testing mirrors and sources

Open **Settings → Terrain & Geodata Settings → Mirror Preferences** and click
**Test** beside a source, including a disabled source. Reorder sources with the
up/down buttons. Tests bypass cached files and contact only the selected source;
they download a sample, validate its GeoTIFF metadata, and decode a pixel block.
They do not populate the application cache. Only one test runs at a time.

Population tests try Switzerland, Belgium, the Netherlands, Denmark, then
Austria, stopping and reporting success as soon as one country works. GitHub
sources honor the **7z parts** setting and extract the expected constrained TIFF.
Terrain mirror tests read small HTTP ranges for representative US locations
(10 m) or European countries (GLO-30), stopping after the first valid sample.
The dynamic 3DEP test requests a small Seattle area at 3 m output spacing.

The **USGS 3DEP dynamic service** entry has no editable mirror list: it uses
USGS's multi-resolution elevation service rather than static country/tile files.
Enable it under **Terrain Data Sources** and select the target resolution there.
Requesting 3 m output spacing does not guarantee native 3 m detail everywhere;
USGS's available source resolution varies by location. The static USGS mirrors
listed separately supply approximately 10 m data.

Tests cap total population downloads at 64 MiB, archive extraction at 128 MiB,
and terrain range downloads at 8 MiB. Archive tests accept COPY, LZMA, and LZMA2
compression, limit headers to 64 KiB and dictionaries to 64 MiB per block, and
require the expected TIFF at the archive root. A test has a 90-second deadline; **Cancel**
or the deadline may take up to another 25 seconds to interrupt a pending request.
**Work Offline** and paused downloads disable testing. Editing or removing a
source cancels its current test and clears its prior result.

A failed test means none of these samples could be validated within the limits;
the source might still serve other areas. Hover the failure message for each
sample's error. A successful test confirms that sample, not the entire dataset.

## Default locations

Treat **Settings → Application Preferences** as authoritative because it shows a
custom or migrated cache root.

| Platform | Large cache root | Configuration directory |
| --- | --- | --- |
| Windows | `%LOCALAPPDATA%\ridgecast\ridgecast\cache` | `%APPDATA%\ridgecast\ridgecast\config` |
| macOS | `~/Library/Caches/com.ridgecast.ridgecast` | `~/Library/Application Support/com.ridgecast.ridgecast` |
| Linux | `~/.cache/ridgecast` or `$XDG_CACHE_HOME` | `~/.config/ridgecast` or `$XDG_CONFIG_HOME` |

The cache contains replaceable downloaded or derived data. Back up the project
working directory; the cache can be rebuilt.

## Cache behavior

- Terrain, land-cover, surface, basemap, FCC, geocoding, node-source, and
  coverage data are stored independently.
- Configured budgets are applied per category, so one category does not evict
  another.
- In-memory decoded terrain tile retention (used by propagation and coverage)
  is configured under **Settings → Terrain & Geodata Settings → Memory & Disk Budgets → Decoded Tile Memory** (512 MB – 32 GB, default 4 GB per source).
- WorldPop rasters and uncategorized files are not automatically evicted.
- Population cache loading requires `*_ppp_2020_UNadj_constrained.tif`; legacy
  unconstrained files are ignored. See [Acquire tiles and publish a mirror](../how-to/publish-a-worldpop-mirror.md)
  for the download/upload scripts and offline installation.
- **Compact** rewrites compatible raster caches in compressed form without
  deleting their contents.
- Changing the cache root redirects new work but does not migrate the old tree.
- Concurrent use of one cache root by several installations is unsupported.

### Coverage results

Completed per-node grids live in `coverage/` beneath the active cache root.
They use versioned, checksummed, losslessly compressed numeric values. Legacy
coverage `.bin` files are ignored and can be removed using **Clear Coverage**.
GPU previews are not cached.

Reuse requires matching radio settings, calculation/grid versions, and local
data fingerprints. Terrain and land-cover fingerprints use regional file names,
sizes, and modification times; measured node surfaces include their raster
contents. Reloading unchanged tiles into memory does not invalidate coverage.
Within a coverage run, validated cache hits keep the exact measured-surface
snapshot used for validation. Preparing an overlapping crop for a newly selected
node does not restart those completed nodes during that run.
Adding, replacing, deleting, or compacting relevant cached tiles can invalidate
it. Validation does not contact providers to check for remote dataset updates;
manually editing cache files while preserving their size and modification time
is unsupported.

If data changes during a solve, RidgeCast retries the node once. A second changing
pass is displayed but not cached. Canceled or incomplete writes are not published.
Missing or corrupt entries are treated as cache misses.

Coverage has its own disk budget (1 GiB for a new cache-budget configuration).
Existing configurations with no Coverage field retain unlimited coverage storage.
Reads update last-use tracking, including a best-effort filesystem access stamp
for later sessions. Cache removal leaves the saved network intact.

### Network link results

Completed network link solves are cached automatically under `links/` in the
active cache root. Re-evaluating an unchanged network, including after restart,
can restore the same numeric links while skipping terrain/LiDAR planning,
surface preparation, path sampling, and propagation. Receiver noise floors are
sampled fresh before checking reuse. The status line says **Reused cached network
links** on a hit. A complete result with no viable links is also reusable.

Reuse requires matching participating sites, radio settings, frequency, cutoff,
propagation and clutter settings, calculation versions, and local source data.
Renaming a site or changing map styling does not invalidate it. Metadata checks
do not contact providers. This first implementation conservatively includes the
whole local terrain, land-cover, and enabled LiDAR inventory; preparing data in
another area can therefore invalidate a saved solve. Each selection/target scope
has its own snapshot; changing a site's radio settings recalculates that scope.
Individual profile windows and antenna-height trials retain their existing caches.

Changing data during planning or evaluation prevents caching that pass. Once
downloads and surface preparation settle, a complete stable solve creates the
reusable result. Missing registered sources, sampled fallback terrain, unknown
clutter classes, failed propagation, incomplete/memory-limited LiDAR preparation,
or cancellation also prevent publication. Missing, corrupt, oversized, and stale
entries cause a normal recalculation.

**Settings → Terrain & Geodata Settings → Memory & Disk Budgets** exposes the
separate **Links** category, its usage, and clearing/eviction. New budget
configurations default to 256 MiB; older configurations without a Links field
retain unlimited link storage. Clearing Links leaves downloaded terrain/LiDAR,
coverage caches, and saved network files intact.

**Work Offline** blocks terrain, land cover, LiDAR, FCC, geocoding, population,
node-source, and basemap requests. Cached content remains usable.

For operational steps, see [Work offline and manage cached data](../how-to/work-offline-and-manage-caches.md).
For mirror layouts, egress hostnames, budget semantics, and administration, see
[Data, caches, mirrors, and working offline](../data-and-caching.md).
