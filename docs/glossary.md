# Glossary

Terms used throughout RidgeCast's documentation, its interface, and its source.
Terms are grouped by subject. Everything in the final section, **RidgeCast-specific
terms**, is an invention of this application rather than general practice; a few
RidgeCast coinages sit in an earlier topical section because that is where you
would look for them, and those carry an explicit _(RidgeCast)_ tag.

Each definition is meant to stand on its own. Where a term needs more than a
paragraph, the entry points at the document that gives it one.

---

## Start here: the six words everything else uses

If you read nothing else on this page, read these. Every other entry is built on
top of them.

| Term | Meaning |
| ---- | ------- |
| **Node** | One radio installation — an antenna, at a place, at a height, with a power and a receiver. The basic object you place on the map. RidgeCast models one radio per node. A *marker* node is an annotation carrying no radio at all. "Site" and "terminal" mean the same as node; the interface uses all three. |
| **Link** | A predicted radio path between two nodes, and the numbers that describe it. Links are **directed**: A hearing B is a separate link from B hearing A, and they routinely differ, because power, antenna gain, and receiver sensitivity differ at the two ends. |
| **System profile** | A named, reusable set of radio parameters — power, sensitivity, antenna gain and height, system loss — that any number of nodes inherit from, so a fleet of identical radios is described once. Individual nodes can override any field. |
| **Coverage** | A map of predicted signal quality over an *area* rather than along one path: RidgeCast evaluates a link from a node to a hypothetical receiver (the [**Test Node**](#ridgecast-specific-terms)) at every cell of a grid, and colors each cell by the result. See [Coverage maps](concepts/coverage.md). |
| **Fade margin** / **SNR** | **The same number**, in decibels: how far the arriving signal sits above the noise the receiver has to hear it over. The single quantity links, coverage, Site Finder, and every network analysis are graded on. See [From transmit power to fade margin](concepts/link-budget-and-noise.md). |
| **Site Finder** | The tool that inverts the coverage question — instead of scoring one chosen site, it scores *every* location in the visible map by how good a site it would be, and ranks them. See [Finding sites](concepts/site-finder.md). |

Two more that recur constantly:

- A **terrain profile** is the list of ground elevations sampled at regular steps
  along the straight line between two points. It is what every propagation model
  is actually handed.
- A **cache** is data downloaded or computed once and kept on disk so it need not
  be fetched or recomputed. RidgeCast caches map tiles, terrain, land cover,
  LiDAR, population, and calculated coverage. See
  [`docs/data-and-caching.md`](data-and-caching.md).

---

## Elevation and surface data

| Term | Meaning |
| ---- | ------- |
| **3DEP** | USGS 3D Elevation Program: the United States national elevation and LiDAR program. RidgeCast uses its 1/3-arcsecond (~10 m) DEM tiles for terrain and its public point-cloud acquisitions for measured surfaces. A single 1° tile is roughly 400 MB. |
| **Bare earth** | The ground surface with vegetation, buildings, and other above-ground returns removed. What a DEM/DTM represents, and what ITM and P.1812 expect as their terrain profile. RidgeCast never splices measured LiDAR elevations into the DEM — the sources use different vertical datums and epochs. |
| **COG (Cloud Optimized GeoTIFF)** | A GeoTIFF laid out so a client can fetch only the byte ranges it needs over HTTP instead of downloading the whole raster. The Copernicus and 3DEP tiles RidgeCast fetches are COGs, and they arrive already compressed. |
| **Copernicus GLO-30** | The ESA Copernicus 30 m global DEM. RidgeCast's default elevation source outside the United States. Tiles are named `Copernicus_DSM_COG_10_...`; some mirrors drop the `COG_` segment, which is why the mirror URL schema is configurable. |
| **DEM (Digital Elevation Model)** | A raster of ground elevations. Used loosely for any elevation grid; in RidgeCast it always means bare-earth terrain, and it is the authoritative terrain source even when measured surfaces are enabled. |
| **DSM (Digital Surface Model)** | A raster of the *top* surface — treetops, rooftops, and the ground where nothing stands on it. Derived from **first returns**: a LiDAR pulse striking a tree reflects several times on its way down, and the first echo back is whatever it hit first, so first returns trace the top of everything. |
| **DTM (Digital Terrain Model)** | A raster of bare-earth ground elevation, derived from **ground-classified** returns — the echoes a survey has labelled as having reached actual soil rather than vegetation or a roof. Paired with a DSM, `max(DSM − DTM, 0)` gives measured obstruction height above ground. |
| **EPT (Entwine Point Tile)** | A cloud-native, HTTP-addressable octree format for LiDAR point clouds. Each dataset publishes an `ept.json` describing the octree; RidgeCast walks the hierarchy and fetches only the nodes covering a link corridor or node area. USGS 3DEP and NOAA coastal acquisitions are served this way. |
| **HGT** | The raw fixed-size SRTM elevation tile format (`N47W123.hgt`), served by Skadi-layout hosts. Supported as a legacy fallback source only. |
| **Hillshade** | A shaded-relief rendering of an elevation or surface raster. RidgeCast's **Cached DSM hillshade** draws exactly the measured surface areas already on disk and never triggers a download. |
| **LAS / LAZ** | The standard LiDAR point-cloud interchange format and its compressed variant. RidgeCast decodes them natively in Rust — no PDAL, LAStools, or Conda environment is required. LAZ is already entropy-coded, so cache compaction skips it. |
| **LiDAR** | Light Detection And Ranging: airborne laser scanning that returns a classified 3-D point cloud. RidgeCast uses public LiDAR to derive measured DSM/DTM surfaces rather than relying on categorical land-cover clutter heights. See [Clutter, LiDAR, and canopy density](concepts/clutter-and-lidar.md). |
| **NoData** | A raster cell with no valid measurement, distinct from a cell measuring zero. RidgeCast excludes NoData from area weighting instead of treating it as quiet land or open air, and reports coverage below 90% as a warning. |
| **Point cloud** | The unrasterized set of 3-D LiDAR returns, each with a classification (ground, vegetation, building, water). Rasterizing it produces the DSM and DTM. The largest thing RidgeCast downloads. |
| **Skadi** | The directory layout Mapzen/AWS used to serve SRTM `.hgt` tiles. Available in RidgeCast as the legacy 30–90 m elevation fallback. |
| **SRTM** | Shuttle Radar Topography Mission: the 2000-era global 30–90 m elevation dataset behind the legacy fallback source. |

## Formats, projections, and GIS

| Term | Meaning |
| ---- | ------- |
| **CRS** | Coordinate Reference System: the datum and projection a dataset's coordinates are expressed in. RidgeCast reprojects every LiDAR point from its source CRS through WGS84 into a local frame before binning, and treats an unrecognized CRS as a hard error rather than risking an empty raster. |
| **EPSG:3857 / Web Mercator** | The projected coordinate system used by web maps, in meters. Files exported by Mapbox, Leaflet, or ArcGIS Web often carry these coordinates; RidgeCast unprojects out-of-range vector coordinates on import rather than rejecting them. USGS 3DEP EPT data is also published in EPSG:3857. |
| **EPSG:4326 / WGS84** | The geographic latitude/longitude datum RidgeCast stores and displays everywhere. |
| **GeoJSON** | A JSON encoding of vector features with WGS84 coordinates. Supported for both vector-overlay import and GIS export, where RF values become feature properties. |
| **GeoTIFF** | A TIFF carrying georeferencing metadata. Used both for downloaded elevation rasters and for coverage export in Color Categories, SNR (dB), or Receive Power (dBm) encodings. |
| **GPX** | The GPS exchange format for tracks, routes, and waypoints. Supported as a vector-overlay import source. |
| **Geocoding** | Turning a postal address into coordinates. RidgeCast batches nearby ungeocoded FCC addresses to the U.S. Census geocoder and caches results by canonical address; it never geocodes the whole national catalog. |
| **ISO3** | The three-letter ISO 3166-1 country code used in WorldPop filenames, for example `usa_ppp_2020_UNadj_constrained.tif`. Mirrors must preserve it. |
| **KML** | Keyhole Markup Language, the XML format Google Earth reads. RidgeCast exports nodes, links, and coverage to it with an `<ExtendedData>` block of RF attributes, and imports it as vector overlays. |
| **KMZ** | A zipped KML, optionally bundling its resources. The usual Google Earth delivery format. |
| **Raster / vector** | A raster is a grid of cells (coverage, terrain, land cover); a vector is discrete geometry (nodes, links, imported overlays). RidgeCast exports both. |
| **R-tree** | A spatial index for bounding boxes. Backs viewport queries against the full national amateur-license table in SQLite. |
| **UTM** | Universal Transverse Mercator, a zoned metric projection. NOAA coastal LiDAR surveys commonly arrive in it and are reprojected on ingest. |
| **World file (`.tfw`)** | A small ESRI sidecar giving a raster's pixel size and top-left pixel center. Written next to every exported coverage GeoTIFF so QGIS, ArcGIS, and Global Mapper place it over the network instead of at `(0, 0)`. |

## Land cover, population, and licensing data

| Term | Meaning |
| ---- | ------- |
| **Clutter density** | The calibrated density associated with an NLCD or WorldCover land-cover class. RidgeCast uses it when calculating categorical RF attenuation. It is not a LiDAR measurement. |
| **LiDAR return density** | The share of available LiDAR returns in a cell that were not classified as bare surface. RidgeCast stores this as a diagnostic only; it does not scale RF attenuation because return counts depend on how the survey was collected. See [Clutter, LiDAR, and canopy density](concepts/clutter-and-lidar.md#5-return-density-diagnostic). |
| **Clutter** | Vegetation, buildings, and other above-ground obstruction near a terminal or along a path. RidgeCast derives it either categorically from NLCD or, where enabled, from measured LiDAR surfaces. Crucially, clutter is charged as *traversal loss* rather than being added onto the terrain profile as if it were opaque ground. |
| **Land-cover blob** _(RidgeCast)_ | The four-connected component of same-class NLCD pixels containing a node — the forest or urban patch the node actually sits in — capped at a 1 km radius. One of the **two scopes** that can request measured DSM data; the other is the **link corridor**, a narrow strip along an eligible node-to-node path. Either, both, or neither can be enabled. |
| **NLCD** | The USGS/MRLC National Land Cover Database: a 30 m categorical land-cover raster for the United States. RidgeCast uses it for clutter height and attenuation, and as a proxy for man-made noise source density. |
| **Source density index** _(RidgeCast)_ | The area-weighted man-made-noise weight around a node, from 0 (no modeled local sources) to 1 (high-intensity development). Open water has a small nonzero NLCD weight of 0.003. RidgeCast can also use population density when land-cover data is missing or blend both sources. The index scales the city reference down to the site. See [From transmit power to fade margin](concepts/link-budget-and-noise.md). |
| **ULS** | The Universal Licensing System of the FCC (the U.S. Federal Communications Commission), source of the bulk amateur-license archive RidgeCast downloads and normalizes into a local SQLite catalog. The archive and the resulting database contain public mailing addresses and are excluded from version control. |
| **WorldPop** | The open gridded population dataset used to estimate population under coverage: 2020 UN-adjusted constrained country rasters, ~100 m, people per pixel, CC-BY-4.0. UN-adjusted means adjusted to United Nations national totals; filenames use `UNadj`. Population is restricted to mapped settlements. Fetched from configurable mirrors and retained until cleared manually. |

## Propagation and RF (radio frequency)

| Term | Meaning |
| ---- | ------- |
| **dB / dBm** | A **dB** is a ratio — a gain or a loss. A **dBm** is an absolute power referenced to one milliwatt. 10 dB is a factor of ten in power, 20 dB a hundredfold. Losses along a path add in dB while the corresponding powers multiply. |
| **EIRP** | Effective Isotropic Radiated Power: transmit power + antenna gain − system loss. What the antenna radiates in its best direction. |
| **Fade margin** | RidgeCast's received level minus effective noise floor, in dB: the reported SNR does not automatically subtract a modem's required decode SNR. Quality bands are configured under **Settings → Fade Margin Settings**; coverage defaults are Good ≥ 20 dB, Fair ≥ 10 and < 20 dB, Marginal > 0 and < 10 dB, and Poor ≤ 0 dB. See the link-budget concept for translating radio requirements into planning thresholds. |
| **FSPL (free-space path loss)** | Loss over an unobstructed path with nothing in it, following ITU-R P.525: `20·log10(d_km) + 20·log10(f_MHz) + 32.44`. A **floor** — terrain, diffraction, and clutter can only add to it — which is what lets RidgeCast reject hopeless pairs before downloading any data for them. |
| **Diffraction** | The bending of a radio wave around an edge, which is why there is any signal at all in the shadow behind a ridge. Weakened, but present. Predicting a terrain path is largely a matter of predicting diffraction loss. |
| **Fresnel zone** | The ellipsoid around a line-of-sight path that actually carries the signal — fattest in the middle, widening with wavelength and distance. An obstacle intruding into it causes diffraction loss *even when the straight line to the antenna is clear*, which is why "line of sight" is not the same as "unobstructed". Link profiles report **clearance**: how far the terrain sits below that ellipsoid, so a positive clearance is good and a negative one means intrusion. |
| **Knife edge** | An idealised infinitely thin, perfectly sharp obstacle. Real ridges and rooftops are not knife edges, but the diffraction loss over one is exactly solvable, so models approximate obstacles as knife edges and accept the error. |
| **ITM / Longley–Rice** | The Irregular Terrain Model, a terrain-aware propagation model in use since the 1960s. RidgeCast bridges the bundled reference C++ implementation from the NTIA (the U.S. National Telecommunications and Information Administration) and uses it as the default. It is called with fixed inputs — average-ground electrical constants, continental-temperate climate, vertical polarization, and 50% confidence/reliability, meaning every result is the *median* outcome. See [Choosing a propagation model](concepts/propagation-models.md) for what each of those means and when they are wrong. |
| **ITU-R P.1812** | A point-to-area terrestrial propagation recommendation. RidgeCast's selectable **P.1812-inspired terrain-diffraction approximation** is not a complete implementation: it computes free-space plus dominant-edge terrain diffraction and omits clutter, complete delta-Bullington diffraction, variability, anomalous propagation, and troposcatter. |
| **Noise-equivalent bandwidth (NEB)** | How much spectrum a receiver integrates noise over. Doubling it costs 3 dB of noise floor. Held on the system profile and overridable per node; default 125 kHz. |
| **Noise figure (NF)** | How much noise a receiver's own front end adds above the theoretical minimum. A good VHF/UHF receiver is 3–8 dB. When none is given, RidgeCast derives the figure that reproduces the stored receive sensitivity exactly, so old networks keep their answers. |
| **P.372** | The ITU-R recommendation for radio noise, source of the city man-made noise reference RidgeCast applies from 0.3–200 MHz. Above that it uses the Hagn/NTIA extension to 1,000 MHz. |
| **PHY rate** | The physical-layer modulation rate assumed for airtime and throughput math. RidgeCast does not predict it per link, so it is an explicit assumption entered in kbit/s — and zero means *unavailable*, not *free*. |
| **RSL (received signal level)** | The power arriving at the receiver, in dBm: EIRP − path loss + receive gain − receive system loss. Also called **received level**, and exported as **Receive Power (dBm)** — three names, one quantity. Not to be confused with fade margin, which is this number *minus the noise floor*. |
| **SNR** | Signal-to-noise ratio, in dB. The quantity coverage cells and link colors are graded on. In RidgeCast it is the received signal minus the effective noise floor and is displayed as the same number as fade margin; it is a planning measure, not a guarantee that a particular receiver will decode the signal. See [From transmit power to fade margin](concepts/link-budget-and-noise.md). |

## RidgeCast-specific terms

| Term | Meaning |
| ---- | ------- |
| **Backbone hub** | A node ticked as part of the network's core — the gateways and sites everything else is supposed to reach. Reachability, criticality, and service analyses are all measured against this set, so those commands (Backbone Connectivity, Critical Nodes, the N-1 sweep, node-failure simulation, Population Service, candidate ranking) stay disabled until at least one hub exists. The route and throughput commands do not need one. |
| **Best Unit** | The coverage merge mode that colors each cell by *which* node serves it best. It retains per-cell serving margins, as do Redundancy and Unique Coverage, for coverage-weighted analyses and per-site figures. The Best Unit threshold (default 10 dB) is an absolute minimum fade margin, not the required gap between the strongest and second-strongest node. |
| **Contention domain** | A set of hops on a route that cannot transmit at the same time, because they share a node, a radio, or a channel. The **End-to-End Throughput** analysis's interference-aware estimate takes the tightest domain's capacity. |
| **Effective noise floor** | The receiver's own thermal floor and the modeled environmental noise, combined in linear power. Replaces the datasheet receive sensitivity in network link SNR. |
| **Fortuity** | Two ranking heuristics. As a **link view**, it is the product of distance normalized to 50 km and SNR normalized to 30 dB, with each factor clamped to 0–1, favoring links that are both long and strong. As a **Site Finder** figure, it is the site score divided by the square of the cell's average ground elevation in meters (the mean of the cell's center and its six corners, floored at 1 m), favoring high-scoring lower-elevation sites. |
| **Hexel** | One hexagonal cell of the Vertex Grid — the unit of evaluation for both coverage and Site Finder. Hexagons are used rather than squares because every neighbour of a hexagon is the same distance away, so a coverage boundary looks like a boundary instead of a staircase. The lattice is global, which is what lets separate nodes' cached grids line up cell for cell. In coverage, one terrain profile is run from the node to each cell. In Site Finder, the sampling strategy decides where inside the cell the hypothetical antenna stands. |
| **Jealousy** | The Site Finder cluster-suppression control that blends between damping a peak's neighbors in proportion to their score gap (0) and outright winner-take-all (1), so one good ridge yields one candidate instead of a blob. Default 0.75. |
| **N-1** | The power-industry term for surviving the loss of any single component. The **Single-Node Failure Sweep (N-1)** removes each node in turn and ranks what its loss costs, deterministically regardless of thread count. |
| **Radial Sweep** | The coverage algorithm that casts rays outward from a node. Faster than the Vertex Grid, but rays diverge with distance — 1° is 17 m apart at 1 km and 175 m at 10 km — and can leave gaps at long range. |
| **Range circles** | Configurable planning-distance rings drawn around a node. Purely visual; they do not change the node's RF model. |
| **Risk group** | An arbitrary label such as `tower:beacon` or `power:feed-2` marking nodes that fail together — same tower, same generator. Nothing infers them; they encode knowledge only you have. They are read by one analysis: **shared-risk-disjoint** route counting, which asks how many paths between two nodes share no failure domain, and is therefore only as good as the labels entered. |
| **Site score** | Site Finder's composite for one candidate cell: 360 rays × 63 sample points, each scoring +1 (Good), +0.5 (Fair), +0.1 (Marginal), or −0.1 (None). The scale therefore runs from −2,268 to 22,680. Comparative within one scan, not meaningful across scans. |
| **Test Node** | The hypothetical station at the far end of every coverage calculation, editable under **Global Coverage Settings → Test Node Parameters** in the right-hand panel. Defaults to a handheld: 22 dBm, −100 dBm sensitivity, 0 dBi, 1.5 m above ground, 2 dB system loss. Every coverage map is a map of what this station would experience. |
| **Vertex Grid** | The coverage algorithm that evaluates a hex grid of hexels for continuous output, as opposed to Radial Sweep. Slower, but it cannot leave gaps. |
| **Work Offline** | The setting that refuses new outbound requests and holds in-flight ones at their next checkpoint. Cached data stays available; areas never downloaded stay blank. |

---

## Where else to look

- **[RidgeCast documentation](README.md)** — tutorials, task guides, and
  reference material for using the application.
- **[`docs/concepts/`](concepts/)** — long-form explanations of the modeling
  behind these terms.
- **[`docs/data-and-caching.md`](data-and-caching.md)** — data sources, caches,
  mirrors, and offline operation.
- **[`docs/propagation-model-decisions.md`](propagation-model-decisions.md)** —
  the engineering decision record.
