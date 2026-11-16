# LiDAR source catalog

RidgeCast's [`lidar_sources.json`](../../lidar_sources.json) records point-cloud,
surface and companion ground data with their coverage, access requirements,
delivery hosts and evidence. The source picker offers surface-clutter inputs:
point clouds, surface/height rasters and mixed collections that include them.
Standalone DEM/DTM products are hidden in every geographic filter. Catalog
membership does not make a source usable for radio calculations.

The configured terrain source continues to supply propagation's bare-earth
profile. Ground records remain available as internal companion metadata where
a supplied DSM needs a matching ground reference to calculate clutter height.
That dependency does not make the LiDAR ground raster a terrain-source choice.

The **LiDAR clutter source** dropdown selects registered acquisition routes.
Readers support EPT, spatial COPC ranges, bounded LAS/LAZ files and archives,
numeric GeoTIFF/COG crops, and paired ArcGIS ImageServer exports. Discovery
includes STAC APIs and static catalogs, ArcGIS tile indexes, S3 and HTTP
inventories, and provider-specific state services. The browser explains any
source that cannot be selected, including account requirements, an unbound
delivery inventory, or a missing matching ground product.

A registered reader does not guarantee coverage at a particular location.
Unknown CRS or vertical units, changing remote objects, incomplete inventories,
unsupported raster encodings and oversized non-spatial downloads produce
explicit errors. RidgeCast does not substitute a different source silently.

| Integration status | Meaning |
| --- | --- |
| `native` | A registered acquisition adapter can discover and process this route. Coverage, numerical metadata and access still need to be valid for the requested area. |
| `manual_import` | A local import workflow is documented. Any necessary conversion, reprojection and preparation must happen externally first. |
| `adapter_required` | Provider data is useful, but its discovery, authentication, reading or processing needs implementation. |
| `discovery_only` | A catalog, frontend or processing service is a research route rather than an automatic RF data source. |
| `excluded` | The route is intentionally outside the automatic source set, for the stated reason. |

## Browse by state

Choose a state to show its listed regional sources. The national-source
visibility toggle adds the national routes associated with that state. Source
order remains the catalog order. With no state selected, the browser shows all
clutter-source entries regardless of the national toggle.

Choose **National sources only** in the same dropdown to hide state and
regional collections. This includes shared national feeds and catalog entries
without a regional restriction. State-specific research examples do not remove
a shared feed from this list. The **Include national sources** checkbox applies
only when a specific state is selected.

The supplied state inventory covers the **50 states**, excluding Washington,
DC and US territories. It combines statewide programs, partial county or
research footprints, and national services with state examples. A state entry
does not establish statewide coverage, two independent full-state copies, or
native RidgeCast support. Read each record's coverage and verification notes.
The USGS EPT example attached to a state is research metadata; it is not an
automatically chosen acquisition for every location in that state.

## File locations and reload

The application starts with an embedded copy of the catalog. In a background
worker it looks for an override in this order:

1. `lidar_sources.json` next to the running executable.
2. In a debug build, `lidar_sources.json` in the build's source checkout.
3. The embedded catalog when neither override exists.

The source browser's reload action rereads the override. Files are limited to
**2 MiB** and must be UTF-8 JSON. An invalid or unreadable override produces a
visible warning and keeps the last valid catalog. A newer reload takes
precedence over an older worker that finishes later. Source browsing reads an
in-memory snapshot; it does not read the disk on the UI thread.

The catalog controls acquisition discovery endpoints and default delivery mirrors.
Saved user mirror preferences (`ItmDsmSettings.source_mirrors`) override the
catalog's endpoint order and enablement. Raw tile cache identities retain the
original canonical asset URL when a mirror serves the bytes. Editing this file
does not establish that an endpoint is fast or available. Source and companion
configuration changes receive distinct prepared-surface identities. Display
labels and mirror order do not invalidate otherwise identical measured data.
Discovery catalogs are memoized by their root URL. Custom discovery roots also
have separate persistent acquisition-selection caches, so a complete selection
from the previous root cannot bypass discovery at the new endpoint. The shipped
default roots retain their existing persistent keys for offline compatibility.
Raw point tiles and prepared surfaces retain their original cache identities;
reloading metadata does not force all measured data to refresh.

Before the first acquisition, a worker completes the initial sidecar load even
when desktop startup is still loading it asynchronously. Headless requests
use the same initial-load path. Later acquisitions reuse the loaded snapshot;
an explicit reload is required to reread an edited catalog.

## Catalog fields

The companion [`lidar_sources.schema.json`](../../lidar_sources.schema.json)
documents the complete version 1 structure. An editor can use the top-level
`$schema` reference for validation. The application also checks identifiers,
references, supported native bindings, URL transport and saved credentials.

| Field | Contents |
| --- | --- |
| `schema_version`, `catalog_id`, `updated_on` | File version, stable catalog identity and metadata revision date. Version 1 is currently supported. |
| `default_source_id` | A reference to a supported native source. It does not override the provider saved in an existing document. |
| `states` | Optional state records with a two-letter uppercase `code`, readable `name`, regional `source_ids`, optional-display `national_source_ids`, and preserved `usgs_ept_example` metadata. References must resolve to catalog source IDs. |
| `id`, `name`, `provider`, `description` | Stable source identity and readable labels. IDs use lowercase ASCII letters, digits and hyphens and must be unique. |
| `product`, `formats` | Point cloud, DSM, DTM, height above ground or mixed products, with known formats. Empty formats mean the exact format remains unverified. |
| `coverage` | Countries, regions, optional WGS84 `[west,south,east,north]` bounds and qualifications. A national label is not a completeness claim. |
| `discovery` | Interface type, canonical URL, collection IDs, asset keys and provider-specific parameters consumed by a registered adapter. Arbitrary parameters cannot register a new protocol. |
| `delivery` | Actual host group, independence classification, spatial-read evidence, mirror templates and qualifications. |
| `access` | Cost, authentication, licensing, documentation and an optional unsigned token-service endpoint. |
| `quality` | Resolution, CRS, vertical units/datum, acquisition years and surface-generation semantics. Null resolution or years mean unknown or variable values. |
| `ground` | Whether point classification, a paired DTM or an already-normalized height product is required, plus a companion source reference when known. |
| `integration` | Support level, optional registered adapter and the concrete reason for that level. Adapter identifiers are enumerated in the schema. |
| `verification`, `cautions` | Check date, evidence level, evidence URLs, limits and unresolved issues. |
| `implementation` | Optional additive metadata describing the pipeline version and reader-test scope. This does not replace endpoint verification. |

Registered adapter names group acquisition protocols rather than storage
formats. `stac`, `s3`, `inventory`, `arcgis_index`, `portal_item` and
`direct_asset` feed the numerical readers. `raster` handles ImageServer pairs;
`usgs_staged`, `noaa_mission`, `opentopography`, `neon`, `washington`, `alaska`,
`colorado`, `texas`, `minnesota`, `ohio`, `north_dakota`, `louisiana`, `montana`,
`vermont`, `wisconsin`, `indiana` and `south_dakota` bind provider-specific indexes. `usgs_ept` and
`noaa_ept` preserve the original provider settings and
cache identities. Account-based downloads and Requester Pays signing are not
implemented by declaring one of these adapters in JSON.

Discovery is bounded to 256 pages, 64 MiB of metadata, 16,384 assets and 2,048
header probes per query. Hitting a limit reports incomplete discovery or an
explicit size error. COPC uses only intersecting hierarchy nodes; large plain
LAS/LAZ and ZIP downloads can exceed the bounded whole-file reader limits.
Choose a spatial delivery route for those datasets instead of expecting an
unlimited statewide download. ArcGIS exports request numerical floating-point
pixels without a display renderer. Unverified ground epochs and visual RGB
rasters cannot be used to derive clutter.

Numerical raster extraction is limited to four million output cells per
acquisition request. For larger node areas, choose a coarser **LiDAR cell size**
or reduce node context. This output limit is separate from the source's native
resolution; finer resampling cannot create finer source detail.

Wisconsin queries the official county acquisition layer, then reads bounded
delivery tile-index shapefiles to select intersecting point files. Vermont
uses spatial tile records and pairs surface and ground products by tile ID,
year and resolution. Louisiana's original raw and edited CSV ZIP files have
separate roles: raw observations supply surface heights and edited bare-earth
observations supply ground. They do not acquire invented LAS classifications
or canopy-density measurements.

Indiana uses the official acquisition-date layer and verifies each delivery
branch's tile-grid convention against its numerical metadata before querying
nearby object prefixes. Returned geographic footprints are checked as well.
Unrecognized branches remain explicitly incomplete. South Dakota uses public
county survey archives; the ZIP reader selects LAS/LAZ member ranges and does
not download the entire county archive. ZIP metadata, member counts and
selected member sizes remain bounded, including ZIP64 packages.

## Routes that still require access or compatible data

The catalog keeps 13 clutter entries unavailable for automatic acquisition,
with a specific reason shown in the browser:

| Routes | Current requirement |
| --- | --- |
| USGS Requester Pays | AWS signing and billing credentials. The free public bucket remains separately selectable. |
| OpenTopography federal federation and Pima federation | An authenticated federal export binding; these are distinct from original-hosted bulk collections. |
| USA LiDAR frontend | An independent numerical delivery inventory rather than an application landing page. |
| Idaho project point clouds, Indiana Spatial Data Portal, North Carolina SDD | Their Globus or registered-account export workflows. Public state-hosted alternatives remain separate sources. |
| ORNL DAAC 2523 surface | Earthdata-authenticated assets and matching ground. |
| DOGAMI legacy surface and Tahoe raster collection | A verified numerical surface/ground pair; Esri GRID bundles and a point-cloud alternative do not establish that raster pair. |
| Kentucky Phase 2 and New Hampshire surfaces | Queryable, matching acquisition epochs. Advertised ground and surface mosaics cannot be assumed to match. |

Changing an integration label cannot satisfy these requirements. Ground-only
records remain hidden, including the terrain-only Earth Engine exclusion.

Unknown catalog, source and state metadata properties are accepted and retained
for forward evolution, including additive `research_handoff` information.
`discovery.parameters` and `usgs_ept_example` preserve their JSON metadata.
Unknown properties inside other typed metadata sections are currently ignored.
Required fields and known enum values remain validated. Changing a source's
`integration.status` to `native` cannot register an unsupported adapter.

Provider-specific `discovery.parameters` can override these unsigned discovery
bindings; omitted values use the reader's official endpoint. They are distinct
from equivalent-object delivery mirrors:

| Reader | Optional binding parameters |
| --- | --- |
| North Dakota | `portal_url` |
| Minnesota | `county_index_url` |
| Ohio, Vermont | `tile_index_url` |
| Montana | `project_index_url` |
| South Dakota | `county_index_url`, `archive_url` |
| Indiana | `bucket_url`, `acquisition_index_url` |

Generic S3 readers also accept `endpoint_url`/`s3_endpoint`, `bucket` and
`prefix`. These identify the same selected collection, not a substitute federal
dataset. Short-lived discovery responses are reused in bounded memory by full
URL, method and request body; pagination cursors and different search bodies
remain distinct. Reloading the catalog or changing discovery configuration
does not reuse another source's prepared products.

## Adding or updating a source

Copy a similar record and assign a new stable ID. Verify official discovery
and asset metadata; record the actual delivery host and whether the copy is
independent of existing storage. Use `adapter_required` or `discovery_only`
until the corresponding functionality exists. Record unknowns explicitly.
When a surface needs a separately listed terrain product, set
`ground.matching_source_id` to that record's ID. References must resolve; a
`paired_dtm` reference must identify a DTM or mixed-product entry.

To associate a source with a state, add its ID to that state's `source_ids`, or
to `national_source_ids` when it should follow the national visibility toggle.
Use each ID once across the two lists. New state records need a unique
two-letter uppercase code, name, both reference lists and an example object
(which may be empty when no example is verified). The `states` field is
optional so older catalogs remain usable. The schema does not require exactly
50 records or claim that every listed source covers an entire state.

General delivery mirrors use `{url}` for the full canonical asset URL or
`{path}` for its full object path without a leading slash. Legacy USGS mirrors
use `{dataset}` and `{path}`. Legacy NOAA mirrors use
`{path}`, the relative object path within its bucket. Preserve these
placeholders. A mirror must serve the same format and compatible object
layout; a different provider's catalog URL is not a replacement tile URL.
Edit these overrides under **LiDAR delivery mirrors** for the selected source.
Independent objects share healthy equivalent backends; byte-range readers keep
their successful delivery endpoint and source validator. AWS aliases for the
same bucket share admission limits and do not add independent capacity. List
order breaks equal-load ties and orders aliases of the same backend. An empty
enabled list disables its transfers. A cached canonical object
can still be read without the mirror that originally supplied it. All delivery
URLs must use HTTPS. Explicitly documented FTP references are
allowed only as non-native catalog information, never as native mirrors.

Store canonical **unsigned** asset identities. Planetary Computer's SAS service
can issue temporary access credentials; save its service endpoint rather than
the credentials it returns. Signed Azure, AWS and Google asset URLs, access
tokens and API keys must not appear in this file. Account credentials belong
in an authentication mechanism, not in source metadata.

## Reproduce the state import

The original [`us-lidar-dsm-sources-by-state.json`](../../us-lidar-dsm-sources-by-state.json)
is a research input. [`tools/import-lidar-state-catalog.py`](../tools/import-lidar-state-catalog.py)
converts it into the runtime schema and merges it with an existing catalog.
The conversion runs offline and preserves attributed research evidence in
additive metadata; it does not repeat the original HTTP checks or promote
research entries to native adapters.

From the repository root, write a reviewable merged file:

```powershell
python tools/import-lidar-state-catalog.py us-lidar-dsm-sources-by-state.json --catalog lidar_sources.json --output lidar_sources.review.json
```

`--catalog` chooses the baseline catalog and `--output` chooses the destination.
Use `--check` to run the conversion and verify that repeated import adds no
further records, without writing a catalog:

```powershell
python tools/import-lidar-state-catalog.py us-lidar-dsm-sources-by-state.json --catalog lidar_sources.json --check
```

Keep the original research input intact. Review the merged source records,
state references and evidence qualifications before adopting the output as an
override or the shipped catalog.

## Surface and evidence semantics

A DSM includes vegetation and structures; a DTM represents ground. Height
above ground and canopy-height products already describe relative clutter
height. Absolute DSMs require a verified same-survey ground companion. Readers
check acquisition identity, grid compatibility, valid cells, CRS and vertical
units before deriving `max(surface - ground, 0)`. Relative heights are placed
over the configured terrain profile. Hillshade images are visualizations and
are never accepted as numerical clutter. Supplied rasters do not receive
invented point counts, classification support or canopy-density evidence.

Acquisition plans freeze the selected point payloads or numerical raster
chunks before prefetch. The network plan unions these canonical dependencies
across links. Raw point payloads, numerical TIFF range blocks and bounded
immutable export/archive snapshots share the **Point clouds** source-data
cache cap. Numerical clutter crops and manifests use the separate **LiDAR
surfaces** cap. Valid prepared crops are reused without retrieving their
source payload again. Cached objects are checked against their persisted identity;
a changed ETag or object size cannot reuse an old hierarchy or pixel selection.

Microsoft Planetary Computer supplies both `3dep-lidar-dsm` and
`3dep-lidar-dtm`. Inspected Washington items share a survey ID and 2 m grid,
but matching coverage and valid cells must be checked per tile. Its inspected
DSM uses IDW interpolation after noise exclusion; its DTM reclassifies ground
with SMRF. These semantics differ from retaining each cell's highest return
or using the original ground classification. Collection bounds do not prove
complete national inventory. Free access and redistribution licensing are
separate questions.

NOAA's EPT catalog currently publishes some obsolete nested item links.
Research verified flat `DigitalCoast_mission_<id>.json` items and their EPT
descriptors. The static STAC reader traverses NOAA COPC child collections.
Some NOAA portal records point to USGS-hosted
EPT, so inspect asset URLs before counting another storage fallback.

S3 hostname aliases for one bucket share the same backend. A NOAA bucket and a
USGS bucket are distinct repositories but still share AWS. Azure and the
OpenTopography original collections at SDSC add different hosting domains;
OpenTopography's federated federal layers may use the same federal backend.
These distinctions do not guarantee independent operations or better uptime.

Verification levels separate actual range reads, metadata checks, official
documentation and unverified leads. Notes distinguish fresh checks from the
research handoff. A successful header read establishes a working object and
range request at that moment; it does not prove full-file validity, survey
coverage, sustained throughput or RF behavior. Preserve acquisition identity,
dates, units and datum when comparing alternate routes.
