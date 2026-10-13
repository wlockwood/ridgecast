# Regional vector water for terrain display

Status: approved and implemented on 2026-10-07. Behavioral tests and geographic native GPU comparisons are recorded in the [remediation plan](../plans/2026-10-07-site-finder-remediation.md); they do not establish shoreline accuracy outside the captured areas.

## Intended result

The 2026-10-07 approval also includes Site Finder placement exclusion. Complete,
detailed cached vector geometry can certify an entire candidate footprint as
water. Workers freeze that geometry and record its payload manifest for saved
refinements. Mixed or unknown footprints remain eligible. Imported scans need
a new scan if their recorded vector snapshot is unavailable. Natural Earth
remains display-only, and RF sample water weighting keeps its existing inputs.

With Terrain overlay enabled, water should reveal the basemap along detailed,
antialiased shorelines. Coastlines, lakes, islands, ponds, and river areas should
remain recognizable at planning zooms. The user has approved regional downloads,
preferably vectors, with persistent offline reuse.

The independently approved renderer corrections remove the hidden default 50 m
contour interval, correct land-cover interpolation at tile edges, and rasterize
the existing water polygons as fractional pixel coverage. Those corrections do
not supply geographic detail absent from the bundled Natural Earth source.

## Source choice

| Approach | Advantages | Limits |
| --- | --- | --- |
| OpenFreeMap vector water tiles (recommended) | Regional requests, OSM water polygons, no account or API key, zoom-specific geometry | Public service dependency; detail is limited by the published maximum zoom |
| Existing bundled polygons and cached land cover | Immediately available offline; existing integration | Generalized coastlines and raster cell boundaries remain |
| User-imported regional vector water | User controls the source and detail | Requires users to acquire and identify complete water geometry for each region |

Use OpenFreeMap's TileJSON endpoint, `https://tiles.openfreemap.org/planet`,
and the published OpenMapTiles `water` polygon layer. It includes ocean, lake,
river, dock, pond, and swimming-pool polygons. Do not infer water widths from
the separate `waterway` centreline layer.

Read the tile template and zoom limits from TileJSON rather than permanently
embedding a dated tile URL. Live metadata checked on 2026-10-06 advertises zooms
0 through 14 and a versioned template. At display zooms above the advertised
maximum, reuse the containing maximum-zoom vector tile and rasterize its
geometry at the display tile's resolution. Below zoom 6, retain the bundled
overview mask; the remote schema also uses Natural Earth at broad scales.

Sources:

- [OpenFreeMap usage and attribution](https://openfreemap.org/)
- [OpenFreeMap integration](https://openfreemap.org/quick_start/)
- [OpenMapTiles water schema](https://github.com/openmaptiles/openmaptiles/blob/master/layers/water/water.yaml)

## Display precedence and geometry

A successfully decoded vector tile is authoritative for its covered area,
including a valid tile with no water polygons. Within that area, land-cover
water cells must not reintroduce a raster staircase or erase vector islands.
While vector data is unavailable, use cached land-cover classifications and
then the bundled Natural Earth polygons, as the current renderer does.

Decode only water polygons. Preserve feature exterior rings and holes, union
separate features, honor tile buffer coordinates, and clip coverage to the
requested display tile. Rasterize to fractional coverage at pixel centres in
Web Mercator, using the corrected renderer's antialiasing convention. Respect
the antimeridian and reuse parent geometry without raster magnification.

These polygons affect terrain display and conservative Site Finder placement
eligibility. Elevation, RF propagation, coverage, land-cover classification, and
RF sample weights retain their existing data.

## Acquisition and UI integration

Request vector data for the enabled Terrain overlay's visible viewport and
bounded Site Finder area preparation. Coalesce repeated requests, including multiple display
tiles sharing a maximum-zoom parent. Use two acquisition workers and a queue
bounded to 64 unique source tiles; prioritize the current viewport and drop
obsolete queued work. Keep terrain rendering separate from network waits.

The UI thread updates visibility and polls completed work; all HTTP, disk I/O,
protobuf decoding, and geometry processing happen on workers. Publish a data
revision only after a complete valid tile is available, invalidate affected
terrain content, and request a repaint. Existing fallback terrain stays visible
while detail arrives.

Register acquisition with the existing download tracker as an on-demand map
request. Honor Pause, Cancel All, and Work Offline, including requests that have
not started. Stop scheduling retries after cancellation until visibility or
download-control state changes. Back off failures for 30 seconds, increasing
to a maximum of five minutes. Failure must not cause a repaint/request loop.

## Persistent cache and freshness

Store raw vector tiles and validated TileJSON under a `water_vector` directory
inside the active cache root. Include that directory in the existing
Map Tiles category so its storage is counted, limited, and cleared normally.
Key tiles by provider template fingerprint, source tile ID, and cache format
version. Publish files atomically after complete download and validation.

Keep decoded geometry in a bounded 64 MiB memory LRU. A restart can decode the
persistent raw tiles again without downloading them. Refresh TileJSON on a
worker at most once every 24 hours while online. A changed source template uses
a separate cache namespace; older cached geometry remains a display fallback
until replacement tiles arrive and is reclaimed by normal cache eviction.
Offline operation continues to use valid cached metadata and tiles regardless
of metadata age. A failed refresh must not discard a usable cache.

Bound TileJSON to 256 KiB, each transferred tile to 8 MiB, and any decompressed
tile to 32 MiB. Limit decoded water geometry to one million vertices per source
tile and eight million topology comparisons; check cancellation between features
and geometry batches. Malformed,
truncated, or over-limit input falls back to existing water sources and is not
published as a valid cached tile. Only accept HTTPS templates for the configured
OpenFreeMap host. Validate coordinate arithmetic and polygon commands before
allocation or indexing.

Preserve isolated shared endpoints between an exterior and an enclosed island
hole for display. Those polygons cannot certify Site Finder exclusions. Reject
crossings, overlapping edges, self contacts and ambiguous hole/hole contacts.

## Attribution and documentation

Include OpenMapTiles and OpenStreetMap attribution when vector water is in use,
including with the None basemap and in terrain-containing image exports. Link
OpenFreeMap as the serving provider. Use the same authoritative/fallback rules
in any terrain export path that consumes these tiles.

Update the terrain controls, data-source/cache reference, water provenance,
README capability description, and third-party notices. Document the regional
downloads, cached offline behavior, source precedence, and maximum-zoom detail
limit. Keep any user-facing status anchored to Terrain overlay and give new
interactive controls tooltips.

## Validation

Use real, small MVT fixtures and a local HTTP fixture server to exercise the
decoder, acquisition, and persistent cache. Cover polygon holes, overlapping
features, river areas, empty water tiles, malformed geometry, byte/vertex limits,
parent-tile cropping, adjacent tile boundaries, dateline tiles, and cancellation.
Verify that a restart and Work Offline issue zero HTTP requests for cached tiles,
metadata failures preserve usable cached geometry, source updates invalidate
affected content, and cache accounting/clearing includes vector water.

Render comparisons of an irregular coastline, a lake with islands, and a river
at the same coordinates, terrain settings, and multiple zooms. Label downloaded
source versions and distinguish these renderer captures from RF validation.
Keep all existing terrain styles, opacity/blending, low-elevation land, contour
selection, and background-cancellation regressions passing. Run the repository's
Cargo checks and the documentation link checker.
