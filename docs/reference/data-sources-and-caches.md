# Data sources and caches

RidgeCast downloads public data on demand and stores it locally. Built-in
sources require no API keys.

## Data providers

| Data | Default providers |
| --- | --- |
| Basemaps | OpenStreetMap, OpenTopoMap, Esri World Imagery |
| Elevation | USGS 3DEP, Copernicus GLO-30, legacy Skadi/SRTM HGT |
| Land cover | MRLC/NLCD; registered ESA WorldCover crops |
| Water outlines and candidate placement | Regional OpenFreeMap / OpenMapTiles water polygons from OpenStreetMap; cached land cover and bundled Natural Earth provide fallback |
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
  download additional tiles while online. It is unavailable while the
  application benchmark runs; the offer stays open until the benchmark ends.
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

## Elevation source cascade

Every elevation lookup (a profile point, a coverage sample, a map readout) walks
the same ordered list of sources and returns the first one that answers. The
order is fixed; only which sources are *enabled* is configurable.

| Order | Source | Enabled by default | Used when |
| --- | --- | --- | --- |
| 1 | Registered local bare-earth DEM | yes, if **Prefer local DEM before built-in terrain** is on (default) | the point lies inside a valid, non-NoData pixel of an enabled local DEM. With the preference off, local DEMs are tried *last* instead (step 6) |
| 2 | USGS 3DEP dynamic service (`Us3dep`), at the target resolution (3 m default) | **no** (opt-in) | only inside the 3DEP coverage rectangles below |
| 3 | 3DEP static 10 m tiles from the ordered S3 mirror list (`Us3depS3`) | yes | only inside the 3DEP rectangles; this is the normal United States source |
| 4 | Copernicus GLO-30 (`Glo30`) | yes | anywhere |
| 5 | Legacy Skadi/SRTM `.hgt` | no | anywhere |
| 6 | Local DEMs, when they were not preferred | | |
| 7 | The constant **fallback elevation** (100 m default) | always | nothing above answered |

The 3DEP rectangles (`is_probably_3dep_coverage`) are the contiguous United
States (-125 to -66 longitude, 24 to 50 latitude), Alaska (-170 to -129, 51 to
72.5), Hawaii (-161 to -154, 18 to 23), Puerto Rico and the Virgin Islands
(-68.5 to -64, 17 to 19), Guam and the Marianas (144 to 146.5, 13 to 22) and
American Samoa (-172 to -168, -15 to -10). They are deliberately generous
rectangles, not national borders, which is why a 3DEP tile can still contain
NoData (for example, the Canadian side of a border tile).

The elevation each source returns has its own configurable vertical offset
(3DEP and GLO-30; local DEMs carry their own per-source offset).

### NoData gap-fill chain

NoData is handled per *pixel*, not per tile. A source that has the tile but a
NoData pixel at the point does not answer, and the lookup continues down the
list. The chain therefore reads: dynamic 3DEP, then the 3DEP S3 mirror, then
GLO-30, then SRTM, then the fallback constant. Elevation values are also
sanitised on decode: the SRTM void value (-32768) and anything below -1,000,000
or above 10,000,000 m (and any non-finite value) become NoData, and bilinear
sampling drops NoData neighbours and re-weights the rest, so a hole shrinks
rather than poisoning a whole sample.

Two rules limit downloads in this chain. The 3DEP S3 mirror's tiles are large
(about 400 MB for 1 degree), so it may *start a download* for a point only when
the dynamic service is disabled, or has returned NoData or failed for that
point; while the dynamic service is merely still downloading its own tile the
mirror answers from cache only. And a **confirmed-missing** GLO-30 tile (the
provider has no tile over open ocean) is treated as 0 m when **Assume missing
GLO-30 tiles are ocean** is on (default); a tile that merely failed or is still
pending is never assumed to be ocean.

Coverage runs prepare terrain before computing. For each 1-degree cell they
queue a job for the preferred source, then, only if that tile has any NoData
pixels not already filled, the lower-priority enabled sources in the same
order. A cell already covered completely by an enabled local DEM, or already
decoded or confirmed absent, needs no acquisition. Outside the 3DEP rectangles
the global source (GLO-30, or Skadi if GLO-30 is off) is the preferred one.

### Mirror failover

3DEP static and GLO-30 tiles are fetched from an ordered list of editable URL
templates (see [Mirrors and the fallback chain](../data-and-caching.md#4-mirrors-and-the-fallback-chain)).
Only `https://` templates are used. Within one tile download:

- there are at most **3 attempts**, and attempt *n* uses mirror *n* (wrapping
  around), so a three-mirror list tries each mirror once before any is retried;
- the wait before attempt *n* is *n* - 1 seconds (a 1 s base);
- HTTP 404 ends the fetch immediately as NoData (the provider has no such
  tile), without trying other mirrors; any other non-success status is
  retryable, and a download whose declared size exceeds 2 GiB is refused;
- if the last attempt failed on connectivity (a network error, a 5xx status or
  429), a circuit breaker defers all downloads from that source for 60 seconds;
  otherwise, after the final attempt the tile is marked failed and not retried
  for 300 seconds. Work Offline refuses the download without recording a
  failure.

The dynamic 3DEP service is a different path: it is not mirrored, and its
two-step ArcGIS export result is accepted only if the returned file URL has the
same origin as the service.

## Local raster registration

Registered local rasters (see [Register local terrain, surveyed surfaces, and
global land cover](../how-to/register-local-raster-sources.md)) are validated at
import:

| Limit | Value |
| --- | --- |
| File size | 128 MiB |
| Pixels per raster | 16,000,000 |
| Decoded rasters held at once, per store | 16 |
| Decoded memory, per store | 256 MiB |
| Registered bare-earth DEMs | 16 |
| Registered DSM/DTM pairs | 8 |
| Registered WorldCover crops | 16 |

A DSM/DTM pair keeps two decoded rasters in the surface store (the derived
obstruction height and the DTM), so eight pairs exactly fill its 16 slots.
Replacing the whole set is all-or-nothing: if the new set exceeds the count or
memory budget the existing set is left untouched.

Every source records a **role**: `BareEarthDem`, `SurfaceDsm`, `SurfaceDtm`,
`EsaWorldCover2021`, or `ObstructionHeight` (derived: `max(DSM - DTM, 0)`). The
role is stored in the manifest under those names and fixes validation: all
roles except WorldCover must be in metres with a non-empty declared vertical
datum, and only `SurfaceDsm`/`SurfaceDtm` can form a pair. Each source is
identified by the SHA-256 of its bytes; a cached copy whose hash or georeference
no longer matches is refused on restore rather than used.

## Regional water

While online, RidgeCast acquires regional water polygons from
[OpenFreeMap](https://openfreemap.org/), using the
[OpenMapTiles](https://openmaptiles.org/) `water` layer derived from
[OpenStreetMap](https://www.openstreetmap.org/copyright). No API key is needed.
Terrain rendering uses detailed cached polygons, including island holes and
fractional shoreline transparency. A valid tile with no water polygons is known
land; it does not fall back to a coarse ocean mask.

At overview zooms below 6, the display uses its bundled Natural Earth fallback.
Above the source's published maximum zoom, it reuses that source's parent tile.
Missing or unusable regional tiles fall back to available cached land cover and
Natural Earth for display. The bundled mask is display-only. Site Finder can
exclude a candidate only from a complete, detailed cached polygon footprint or
known all-water cached land cover; missing and mixed footprints remain eligible.
These outlines do not change RF water weights, clutter classes, or elevation.

Raw vector tiles and source metadata persist under `water_vector/` in the active
cache root, sharing the **Map tiles** disk budget and clear action with basemaps.
Acquisition uses two workers and a queue of at most 64 tiles; the service's
managed decoded geometry cache is limited to 64 MiB. Offline, pause and cancel
controls apply. An area request can queue water asynchronously, but a running
Site Finder scan freezes the currently available cached geometry and does not
wait for missing water. See [water provenance](water-mask-provenance.md) and
[offline preparation](../how-to/work-offline-and-manage-caches.md).

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

- Terrain, land-cover, surface, FCC, geocoding, node-source, and coverage data
  have separate storage. Basemaps and regional water share **Map tiles**.
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
node-source, basemap, and regional water requests. Cached content remains usable.

For operational steps, see [Work offline and manage cached data](../how-to/work-offline-and-manage-caches.md).
LiDAR preparation calibration uses bounded, temporary files on the active cache
volume and preserves production cache entries. It scopes filesystem timings to
the actual volume identity when available; unknown identity is session-only.
See [Benchmark this computer](../how-to/benchmark-this-computer.md#lidar-preparation)
for CPU/GPU selection, complete pipeline timings and warm-cache storage limits.
For mirror layouts, egress hostnames, budget semantics, and administration, see
[Data, caches, mirrors, and working offline](../data-and-caching.md).
