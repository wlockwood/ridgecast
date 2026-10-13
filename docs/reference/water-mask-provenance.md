# Water sources and mask provenance

## Regional OpenStreetMap water

RidgeCast downloads regional vector tiles from
[OpenFreeMap](https://openfreemap.org/) using the
[OpenMapTiles](https://openmaptiles.org/) `water` polygon layer. The data comes
from [OpenStreetMap contributors](https://www.openstreetmap.org/copyright) and
is available under the Open Database License (ODbL). OpenFreeMap's software
license does not replace the map data's license.

The application keeps raw tiles and metadata in `water_vector/` beneath the
active cache root. This storage belongs to **Map tiles**, including its budget
and clear action. Source metadata supplies the available detail range; enlarged
views reuse parent tiles rather than requesting nonexistent zoom levels.
Decoded geometry preserves polygon holes. Fractional rasterization smooths
shoreline display, and valid empty tiles establish that their area contains no
mapped water.

Downloaded polygons undergo bounded topology validation. Invalid rings or tiles
that exceed the validation work limit leave the existing terrain fallback
visible; they cannot establish authoritative land or Site Finder water exclusion.
Polygons with an isolated tangent point between a shoreline and an island hole
remain drawable, but conservatively cannot exclude Site Finder candidates.

Site Finder uses a frozen identity of available detailed geometry to exclude
only whole candidate footprints confirmed as water. Missing, mixed or incomplete
footprints remain eligible. Regional outlines do not replace land-cover clutter
or the RF water scoring model. See [candidate water eligibility](../how-to/find-and-validate-a-site.md#water).

Attribution: [OpenFreeMap](https://openfreemap.org/),
[© OpenMapTiles](https://openmaptiles.org/),
[data © OpenStreetMap contributors — ODbL](https://www.openstreetmap.org/copyright).

Water credits appear in a small tag in the map's lower-right corner for five
seconds when Terrain is enabled. They then collapse to an **i** button; click
it to reopen the credits, and **×** to close them. Panning, zooming and ordinary
repaints do not restart the timer. The tag reserves no footer or map-layout
space. Basemap credits remain visible beside the button because individual
tile services can require continuous attribution: the [Road tile policy](https://operations.osmfoundation.org/policies/tiles/)
explicitly disallows hiding its credit behind a toggle.

[OpenStreetMap's interactive-map guidelines](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Interactive_maps)
permit collapse after five seconds with licence information still accessible.
The water tag initially displays linked OpenMapTiles and OpenStreetMap credits
and keeps both available through the corner button. OpenMapTiles uses
[CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/legalcode.en), whose
attribution conditions allow a reasonable linked presentation; its project
guidance recommends corner credits but does not explicitly describe timed
collapse. This presentation follows our interpretation of those conditions,
rather than an explicit OpenMapTiles five-second exemption.

OpenFreeMap remains identified here and in the water-credit tooltip; its visible provider
name is optional under [OpenFreeMap's attribution requirements](https://openfreemap.org/#attribution).
Image exports retain their source credits.

### Alternative datasets considered

The following source review was performed on 2026-10-11. These are suitability
assessments from source documentation, not measured shoreline comparisons.
RidgeCast retains the existing vector source because no replacement reviewed
combines its worldwide water coverage, planning-scale detail, and hosted
regional tile access without additional acquisition infrastructure or loss of
detail.

| Dataset | Suitability for replacing regional water |
| --- | --- |
| [USGS NHD / 3DHP](https://www.usgs.gov/3d-hydrography-program/access-3dhp-data-products) | Strongest regional alternative for U.S. water polygons. The [3DHP service metadata](https://3dhp.nationalmap.gov/arcgis/rest/services/usgs_3dhp_all/FeatureServer) states no use constraints and asks for voluntary acknowledgment. It combines new elevation-derived hydrography with legacy NHD where needed, but does not replace worldwide water. Requires a new feature-service adapter and coverage validation. |
| [Overture water](https://docs.overturemaps.org/guides/base/) | Worldwide polygons, but water features still come from OpenStreetMap and retain ODbL attribution. Distributed as GeoParquet rather than our regional vector tiles; does not remove the underlying data credit. |
| [Protomaps](https://docs.protomaps.com/basemaps/downloads) | Another packaging of OSM water, with a different schema and PMTiles access. Planet downloads must be copied to our own hosting rather than hotlinked. Could remove the OpenMapTiles dependency, but still requires OSM credit and a new acquisition path. |
| [GSHHG](https://github.com/GenericMappingTools/gshhg-gmt/blob/master/README.md) | Worldwide shoreline polygons under LGPL. Its maintainers document older, lower-quality inland geometry and offsets against modern positions at close zooms. Better considered as an overview fallback than an unvalidated planning-scale replacement. |
| [SRTM Water Body Dataset](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-shuttle-radar-topography-mission-water) | Vector outlines derived from approximately 30 m imagery, depicting water in February 2000 and using minimum capture criteria. Too old and selective to substitute for detailed contemporary ponds and river areas without geographic evaluation. |
| [HydroLAKES](https://www.hydrosheds.org/products/hydrolakes) | Global lake polygons, but only lakes of at least 10 hectares; does not replace oceans and river polygons. CC-BY 4.0 still requires attribution. |
| [JRC Global Surface Water](https://global-surface-water.appspot.com/download) | Satellite-derived raster water history rather than vector outlines. Published-map attribution remains required, and choosing observation dates and water thresholds would alter the mask's meaning. |
| [Natural Earth](https://www.naturalearthdata.com/about/terms-of-use/) | Public domain with no attribution requirement; already bundled as the fallback described below. Its generalized geometry loses small-water and close-zoom shoreline detail. |

## Bundled Natural Earth fallback

RidgeCast embeds `resources/water/natural-earth-water.bin.gz`, derived from
Natural Earth's 1:10 million ocean and lake polygons, including island holes.
It provides an offline terrain-display fallback, including overview zooms below
6. Cached land cover supplies additional fallback detail where available.
Natural Earth does not establish Site Finder placement eligibility and does not
change elevation, propagation, coverage, land-cover classes or scores.

Natural Earth is public domain. Its cartographic data is generalized: small
ponds, narrow rivers and shoreline detail may be absent. The display rasterizes
boundaries as fractional pixel coverage without changing the source geometry.

- [Ocean and lake data](https://www.naturalearthdata.com/downloads/10m-physical-vectors/)
- [Terms of use](https://www.naturalearthdata.com/about/terms-of-use/)
- [Pinned source repository](https://github.com/nvkelso/natural-earth-vector/tree/ca96624a56bd078437bca8184e78163e5039ad19/geojson)

## Pinned inputs and output

The source version is pinned to Natural Earth repository revision
`ca96624a56bd078437bca8184e78163e5039ad19`. These SHA-256 hashes are recorded
in the RidgeCast source checkout's `resources/water/sources.json`:

| File | SHA-256 |
| --- | --- |
| `ne_10m_ocean.geojson` | `f9696a1337c746a0f6c8c13bc60d0f230d2ef8d105198d5657726c8f8e763fc2` |
| `ne_10m_lakes.geojson` | `2d036f53dedec578001c5c30c2959ee7d4eebc1306900fa4367c49929ec8f2d9` |
| `natural-earth-water.bin.gz` | `8ea1df2ec955a6029971ae33822b6090a260133bc7ffbfef71a476d7589736f5` |

## Rebuild and binary format

From the root of a RidgeCast source checkout, run
`python tools/build_water_mask.py`. The script downloads its pinned inputs
only when explicitly run and records the source and output hashes in
`resources/water/sources.json`. Released application and documentation packages
contain the finished provenance; rebuilding requires the source checkout.

The gzip payload starts with `RCWATER1`, then a little-endian `u32` polygon
count. Each polygon contains a `u32` ring count; each ring has a `u32` point
count followed by longitude/latitude pairs as little-endian `f32` values.
Rings are closed and use even-odd filling to preserve islands.
