# Register local terrain, surveys, and global land cover

Open **Settings → Local Terrain and Surface Sources**. Select the actual
source role before choosing a file. Import and decoding run on a cancelable
worker; the source list changes after successful validation. Imported files are
copied into a content-addressed local source directory. Keep the original survey
and its provenance separately.

RidgeCast currently accepts one-channel, north-up, geographic **EPSG:4326 WGS84**
GeoTIFFs with pixel-area registration. Rotated/sheared grids, projected CRSs and
pixel-point registration require conversion outside RidgeCast. Each raster is
limited to 128 MiB and 16 million pixels. The decoded local source budget is
256 MiB with at most 16 decoded rasters; a large survey may need smaller crops.
Missing/NoData pixels remain missing, including inside the raster footprint.

## Bare-earth DEM

Choose **Bare-earth DEM**, declare its vertical datum, and select a GeoTIFF whose
elevation samples are in **metres**. A DEM must represent bare earth; selecting a
DSM here would declare building/canopy tops to be ground and invalidate planning.
RidgeCast does not perform vertical-datum conversion. Declare the datum accurately
and use the explicit metre offset when you have an independently established
alignment to the other terrain sources.

Enable **Prefer local DEM before built-in terrain** to use the first valid local
sample before the usual provider cascade. **Earlier** changes the order of local
DEMs. Disable that preference to use local DEMs after built-in sources. A NoData
hole falls through to the next source. **Remove** unregisters the source and
changes RF cache identity; it retains the imported content copy. Profile summaries
name local DEM samples separately from public providers and fallback elevation.

The source manifest lives in `terrain_config.json`. Reopening checks the copied
content and georeference. A replaced/corrupt copy produces an error and keeps
normal missing-data fallback; re-import intentionally to accept changed data.

## Surveyed DSM/DTM pair

Choose **Surveyed DSM/DTM pair**, declare the shared vertical datum, then select
the DSM followed by its bare-earth DTM. Both must use metres and exactly matching
WGS84 bounds, dimensions and pixel registration. Align or reproject mismatched
surveys externally before importing them.

RidgeCast derives `max(DSM − DTM, 0)` at each valid paired pixel. If either input
is NoData, the obstruction height stays unknown. The original sources and derived
height raster have separate content identities. This height enters the existing
ITM measured-surface composition when the corresponding blob/corridor treatment
is enabled. The selected DEM still supplies the terrain profile. Categorical
clutter remains the fallback for missing surveyed pixels, with the existing
water/ice treatment. The import supplies no LiDAR return-density evidence, so
categorical density remains authoritative for attenuation.

Enable or remove a pair in the source window. The default public providers and
existing propagation defaults remain available. Local surveys are recorded in
`propagation_config.json` and can be restored from their copied content offline.

## ESA WorldCover 2021 v200 categorical crops

Choose **ESA WorldCover 2021 v200 crop** and select a geographic crop of its
categorical **Map** product. Use class-preserving cropping, without interpolation
of class codes. Full 3° product tiles exceed RidgeCast's current bounded import
size; crop the area you need externally. RGB renderings and the three-band quality
product are not categorical Map inputs.

The supported product is the 2021 v200 map. Its source schema has eleven classes,
approximately 10 m pixels at the equator, and geographic WGS84 delivery. Its
coverage excludes Antarctica and stops at 82.75° north. See the primary
[product manual, sections 3–4](https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/docs/WorldCover_PUM_V2.0.pdf)
for delivery and classification limitations.

WorldCover supplements NLCD; a valid NLCD category keeps priority. Original
WorldCover values, source content identity and mapping version remain available
through the typed categorical sample API. Unknown codes and NoData map to an
unknown category, never an open-land class. RF profiles, connected footprints and
noise histograms consume the mapped categories. This first crosswalk is an
explicit modeling approximation, with source version `2021 v200` separate from
RF mapping version `1`:

| Original code | RidgeCast RF category |
| --- | --- |
| 10 | Mixed forest |
| 20 | Shrub/scrub |
| 30 | Grass/herbaceous |
| 40 | Cultivated crops |
| 50 | Developed, medium intensity |
| 60 | Barren land |
| 70 | Persistent ice/snow |
| 80 | Open water |
| 90 | Herbaceous wetland |
| 95 | Woody wetland |
| 100 | Grass/herbaceous approximation for moss/lichen |

This mapping does not establish NLCD-equivalent accuracy, urban intensity,
canopy height, foliage density or acquisition freshness. Inspect the original
survey/classification and adjust RF assumptions to your planning context. The
registered crop manifest and category settings live in `landcover_sources.json`.
Sampling registered crops offline makes no provider requests.

WorldCover is available under **CC BY 4.0**. When publishing maps or products,
retain the required acknowledgement and dataset citation from the official
[data access and licensing page](https://esa-worldcover.org/en/data-access).
The map attribution is: © ESA WorldCover project 2021 / Contains modified
Copernicus Sentinel data (2021) processed by ESA WorldCover consortium.

## Share registered sources

[Project bundles](../reference/files-and-formats.md#portable-project-bundles)
include registered local content, derived survey heights, and explicit terrain,
clutter, propagation and Site Finder assumptions. Public download caches remain
excluded. Bundle limits are 64 MiB per entry and 256 MiB total, so use smaller
source crops when necessary. Import validates content before offering assumption
adoption; source paths are relocated to the extracted project directory.
