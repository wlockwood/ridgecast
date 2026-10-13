# Files and interchange formats

## Project and configuration files

### Measured antenna cuts

Import UTF-8 CSV with this exact header and cut names:

```csv
cut,angle_deg,relative_gain_db
azimuth,0,0
azimuth,90,-6
azimuth,180,-30
azimuth,270,-6
elevation,-10,-12
elevation,0,0
elevation,10,-12
```

Limit: 1 MiB and 4096 samples per cut. Azimuth needs three unique angles;
elevation, when present, needs two. Angles/gains must be finite; raw gain lies
in −300..100 dB. Each cut's peak is subtracted on import; normalized gain must
remain in −300..0 dB. Azimuth accepts −180..360 degrees and wraps to [0,360);
do not supply both 0 and 360 or other duplicate equivalent angles. Elevation
accepts −180..180 degrees. Samples are sorted. Linear interpolation in dB joins
azimuth across north; elevation holds the nearest endpoint outside its span.
Use cuts covering elevations of interest. Embedded normalized samples and
name round-trip in node/system profiles; CSV paths are not needed on reopen.

The window title shows the RidgeCast version and the current network's filename,
for example `RidgeCast 0.1.0 — hilltop.yaml`. It updates after a successful load
(including the default network loaded at startup) or **Save As…**. A new
network shows `Untitled` until its first successful save. An appended `*` means
the current document has unsaved changes. The status bar reports explicit saves
and recovery snapshots separately.

**Save** writes the selected JSON or YAML project file; an untitled network's
first Save asks for a location. **Save As…** selects another destination.
Background recovery writes separate snapshots and does not update project files.

For a source build, make one project directory, open a terminal there, and run
`cargo run --release --manifest-path /path/to/ridgecast/Cargo.toml`. The running
application then reads its configuration and any legacy default project files
from that directory. At startup, RidgeCast reopens the most recent network from
**File → Recent Networks** that still exists on disk. If that file cannot be
read, startup reports the error rather than opening a different network. Only
when no remembered network survives does RidgeCast fall back to the newest valid
`network.json` or `network.yaml` in the working directory, trying the other file
if the newer one is unreadable. These legacy files are no longer written
automatically after edits.
**File → Open Network…** opens a chosen network file; it does not by itself move the
application's working directory.

| File | Contents |
| --- | --- |
| `.json` / `.yaml` / `.yml` network file | Authored nodes, systems, and project network state, including coverage range, resolution, selection, Test Node, and display settings. Saving also stores the calculated links. Opening reuses them when nodes, radio, propagation and noise settings still match what they were calculated for (the status line says **Reused links saved with this network**); otherwise links are recalculated. Use **Analysis → Recalculate → All Links** to refresh them against newly downloaded terrain or LiDAR. Numeric coverage grids are stored separately in the local cache. Openable with **File → Open Network…** and mergeable with **File → Import → Merge Network…**. Legacy defaults are named `network.json` and `network.yaml`. Files larger than 256 MiB are refused. |
| `terrain_config.json` | Terrain and geodata-source configuration |
| `landcover_sources.json` | Registered ESA WorldCover 2021 v200 crops and categorical model settings |
| `.rccov` | Versioned retained numeric coverage archive with per-node/directional margins and RF/network/source provenance; explicit MCP save/load jobs |
| `node_sources.json` | Configured JSON node-source APIs |
| `window_config.json` | Window layout |

Run RidgeCast from a dedicated directory for each project. Otherwise separate
projects can share configuration files and legacy startup defaults.

Serialized configuration is designed to remain backward compatible. A current
save can nevertheless contain fields that an older RidgeCast version does not
understand, so keep a backup before moving a project back to an earlier build.

For a portable backup, copy the network file and the adjacent configuration
files you need. Include embedded layers automatically; for a layer stored as an
external reference, copy that source file too. Numeric coverage grids live in
the local cache and are optional: omit them for a small backup, or preserve the
cache separately when reproducing completed calculations matters.

### Performance log

RidgeCast appends one line to `performance-log.jsonl` in its application
configuration folder for each network link solve, full coverage run, and Site
Finder scan, whether it finished, failed, or was canceled. Open the folder with
**Settings → Application Preferences → Open performance log folder**. Coverage
previews drawn while panning are not logged.

Each line is a JSON object with:

- `task`, `started` (UTC), `duration_s`, `outcome` (`finished`, `failed`, or
  `canceled`), and `app_version`.
- `phases_s`: seconds spent in each step a link solve reports, such as
  `PlanningLinks`, `FetchingLidar`, `BuildingSurfaces`,
  `PreparingLinkProfiles`, and `SolvingLinks`. A step marked `skipped` was not
  needed, for example after links were reused.
- `details`: what the task was and what it reused. Link solves record `nodes`,
  `pairs`, `links`, `lidar_tiles_fetched`, and `links_from`
  (`saved_with_network`, `link_cache`, or `solved`). Coverage runs record
  `nodes`, `nodes_from_cache`, `nodes_solved`, and `cells`. Site Finder records
  `evaluated_cells`, `total_cells`, and `candidates`.
- `process_cache_activity`: terrain tiles decoded from disk and the time that
  took, and LiDAR surfaces served from memory, from disk, by a larger cached
  area, or newly built. These counts cover the whole application while the task
  ran, so tasks running at the same time share them.

The log rotates at 10 MB into `performance-log.1.jsonl`, replacing the previous
one. Deleting either file is safe.

### Recovery snapshots

Unsaved work is captured independently for each document in RidgeCast's local
application-data `recovery` directory. On Windows this is normally
`%LOCALAPPDATA%\ridgecast\ridgecast\data\recovery`; if an application-data
directory cannot be determined, RidgeCast uses `ridgecast-recovery` under the
system temporary directory. This storage is separate from the working directory
and the geodata cache.

Each `<document-id>.json` record uses recovery format version 1 and contains the
document identifier, original project path (or none for an untitled network),
capture timestamp, authored state, and last saved state when available. It does
not preserve calculated links, numeric coverage grids, or undo history.
Successful Save clears recovery once the document matches the saved content;
edits made during the save remain eligible for recovery. A completed document
replacement or normal close removes that document's recovery snapshot.

At startup, **Recover Unsaved Work** lists valid retained snapshots. **Recover**
opens unsaved work without writing the original project, **Discard Recovery**
deletes the selected snapshot, and **Later** retains it. The File menu reopens
the list. Unreadable or unsupported records are retained and reported in a
warning. See [saving and recovery](../how-to/create-and-configure-a-network.md#save-and-recover-your-work)
for the workflow and [troubleshooting](../how-to/troubleshoot.md#unsaved-work-needs-recovery)
for recovery failures.

## Portable project bundles

**File → Export → Project Bundle…** writes a versioned `.rcbundle` ZIP containing
`manifest.json`, the native `network.json`, embedded vector geometry, and
 referenced vector source files under `layers/`, and registered local DEM,
 WorldCover, DSM/DTM and derived height files under `sources/`. It captures the
 live propagation, Site Finder radios/settings, categorical settings, and terrain
 model/source assumptions. A missing referenced layer or invalid local content
fails the export and preserves the previous archive. Download and numeric
caches are excluded; prepare the needed terrain/population data separately for
an offline recalculation.

Choose **File → Open Project Bundle…**, select an archive, and choose
its destination parent folder. RidgeCast extracts into a new `<bundle>-project`
directory and validates the version, size limits, and layer references before
opening it. It refuses an existing destination, traversal, absolute archive
paths, symlinks, duplicate entries, unsupported versions, and missing sources.
Canceling cleans temporary extraction files. Once validation finishes, the
extracted files remain available even if you keep the current document.

The import dialog offers **Adopt the project's propagation, Site Finder, and
terrain assumptions**. Adoption is an explicit choice and invalidates active
calculation jobs. It keeps the application's cache roots, cache budgets,
download limits, Work Offline policy, and display preferences. Opening the
network follows the same **Save / Don’t Save / Cancel** protection as ordinary Open.
Plain JSON/YAML networks remain supported.

## Network import

| Format | Use |
| --- | --- |
| RidgeCast JSON/YAML | Native network load and save |
| Radio Mobile CSV set | Imports matching `_Unit.csv`, `_System.csv`, and `_NetData.csv` files |
| Configured JSON node source | Imports nodes from a user-configured HTTP data source |
| Legacy site list | **File → Import → Legacy Site List…** reads comma-separated `name,latitude,longitude` rows as node locations, using decimal degrees. Extra columns are ignored; malformed locations are skipped. |
| Legacy BIL terrain | Imports legacy terrain data |

## Vector-overlay import

RidgeCast imports KML, KMZ, GeoJSON, and GPX reference layers. Layers can be
embedded in the project or retained as external file references. GeoJSON and KML
coordinates outside geographic bounds are treated as possible EPSG:3857 Web
Mercator coordinates and unprojected when valid.

An external reference on a network share, such as `\\server\share\roads.kml`,
is not read when the network opens. Opening a file on a share sends your Windows
credentials to whoever runs that server, and a shared network file could name
any server. The layer stays in the network and shows the reason as its load
error. Map the share to a drive letter, or embed the layer, to use it.

## GIS export

| Format | Output |
| --- | --- |
| KML | Nodes, links, coverage, and optional vector overlays for compatible GIS tools |
| KMZ | Compressed KML package with a `Vector Overlays` folder when overlays are included |
| GeoJSON | Vector features and RF attributes; included overlays are written to a separate `{base}_layers.geojson` file |
| GeoTIFF | Coverage Color Categories or retained Fade Margin (dB); Receive Power is NoData until absolute powers are available |
| CSV | Calculated link table |
| PNG | Coverage or Site Finder image output, depending on the export command |
| GIF | Animated transmitter coverage at successive antenna heights from Analysis → Planning → Transmitter Height Impact |
| JSON | Site Finder results |
| CSV / GeoJSON candidate points | Ranked Site Finder base/refinement results with sampled origins and immutable scan provenance; full, top-10, or selected scope |

**File → Export → Links to CSV…** writes one row per directed link. Its columns
are `source_id`, `target_id`, `path_loss_db`, `snr_db`, `rsl_dbm`, `receiver_noise`,
and `provenance`. The last two columns contain JSON (`null` for absent noise
metadata), quoted as CSV fields. A complete file is staged before replacing the
destination. The desktop and MCP link exports use the same format.

Every coverage GeoTIFF embeds WGS84 (EPSG:4326), a north-up pixel transform and
PixelIsArea registration, and is written with a matching `{base}_coverage.tfw`
ESRI world file. The raster remains geographically placed without its sidecar;
the sidecar describes the same top-left pixel center. Numeric NoData is `-9999`
with an explicit TIFF tag; unavailable color pixels are transparent.
The legacy `SnrDb` format identifier stores retained fade margins in dB.
Receive Power writes NoData because coverage cells do not retain absolute
received powers; it never labels a fade margin as dBm.
KML/KMZ link features use SNR quality colors. Node and link features
include RF and location properties appropriate to the format.

### GIS export staging and rollback

A GIS export writes several files (for example `{base}.kml`,
`{base}_coverage.geojson`, `{base}_network.geojson`, `{base}_layers.geojson`,
`{base}_coverage.tif` and `{base}_coverage.tfw`). It runs in two phases so a
failure or **Cancel export** never leaves a half-written set:

1. **Stage.** Every file is written into a hidden `.ridgecast-gis-*` directory
   created inside the output folder. Cancel, an error, or a full disk here
   leaves every destination file exactly as it was, and the staging directory is
   removed.
2. **Publish.** Files are then copied over their destinations one at a time. Before
   each file replaces an existing one, the old file is copied to a backup inside
   the staging directory, and each file is written through a temporary name and
   renamed into place. If any publish fails or is canceled, the files already
   published are restored from their backups in reverse order, and files that did
   not exist before are deleted. If restoring itself fails, the error lists which
   files could not be restored.

`base_filename` must be a bare name without a path separator or colon. The
GeoTIFF and its world file are skipped, not written empty, when there is no
coverage.

### How a GeoTIFF rasterizes hexagonal cells

Coverage is stored as hexagonal cells, but a GeoTIFF is a rectangular grid, so
the export resamples:

- The raster is always **512 by 512 pixels**, stretched over the bounding box of
  all cells in latitude and longitude. A pixel therefore covers the box's width
  divided by 512 in longitude and its height divided by 512 in latitude; pixels
  are not square on the ground, and a large coverage area gets coarser pixels than
  a small one. A single-point extent uses 0.0001 degree pixels.
- A pixel takes a cell's value when the pixel's **center lies inside the cell's
  hexagon** (an even-odd point-in-polygon test), so neighbouring hexagons claim
  disjoint pixels and the zigzag hexagon edges are approximated at pixel
  resolution; they are not drawn as rectangles. A hexagon smaller than a pixel
  contains no pixel center and instead claims the single pixel under its
  centroid, so no cell disappears from a coarse export. Where cells overlap a
  pixel, the later cell in the coverage list wins.
- Cells with no polygon, or whose terrain was unavailable offline, are left
  empty. Pixels outside every cell stay transparent (color mode) or `-9999`
  (numeric modes). In the numeric mode a cell with a non-finite signal is also
  left empty.
- The color mode stores the on-map RGBA color of each cell. The numeric mode
  stores the cell's fade margin in dB as a 32-bit float; Receive Power mode writes
  only NoData. The extent must be a valid WGS 84 range, or the export fails.

Because of this resampling, treat a GeoTIFF as a picture of the coverage, not as
a measurement at each pixel: a pixel's value is that of the nearest-covering
cell, and cell boundaries can shift by up to a pixel.

See [Import vector overlays and export GIS data](../how-to/import-overlays-and-export-gis.md).

