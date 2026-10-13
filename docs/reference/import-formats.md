# Import formats and limits

What RidgeCast accepts when you import a network, overlay, node source, or FCC
data, exactly how each file is read, and where it stops. For the steps, see the
task guides: [Import a Radio Mobile network](../how-to/import-radio-mobile-network.md),
[Import vector overlays and export GIS data](../how-to/import-overlays-and-export-gis.md),
[Configure network nodes](../how-to/configure-network-nodes.md) and
[Use FCC amateur-license data](../how-to/use-fcc-amateur-data.md). Exported and
saved formats are in [Files and interchange formats](files-and-formats.md).

All imports run on background workers and can be canceled or fail without
changing the open network, except where noted.

## Radio Mobile CSV

A Radio Mobile export is a set of files that share a prefix:

| File | Required | Used for |
| --- | --- | --- |
| `<prefix>_Unit.csv` | yes | node name, enabled flag, position |
| `<prefix>_System.csv` | yes | system profiles |
| `<prefix>_NetData.csv` | yes | which system, height and role each unit has in each net |
| `<prefix>_Network.csv` | no | which nets are marked visible |

You may select any of the four files; RidgeCast strips a trailing `_Unit`,
`_System`, `_NetData` or `_Network` from the file name and looks for the others
in the same directory. If a required file is missing the import stops before
changing anything.

Each file is a series of `$Block` sections (a line starting with `$`) followed
by a header row and data rows. Quoted CSV with ragged rows is accepted. Only
these blocks are read: `$Unit`, `$System`, `$NetRole`, `$NetSystem`,
`$NetAntHeight`, and `$Net` in the network file (to find the `Net ID` and
`Visible` columns). Other blocks are ignored.

**Units** (`$Unit`): columns by position are Unit ID, name, Enabled, Latitude,
Longitude. Rows with fewer than five columns are skipped. A latitude outside
-90 to 90 or a longitude outside -180 to 180 (or one that does not parse)
**aborts the import** with the unit's name; systems and nodes imported before
the bad row may already have been applied. `Enabled` of `0` or `false` imports
the node disabled and hidden. Elevation, icon and colour columns are ignored.

**Systems** (`$System`): columns by position are System ID, name, Tx power (W),
line loss (dB), (supplemental loss, ignored), (antenna type, ignored), antenna
gain (dBi), antenna height (m), Rx threshold (dBm). Rows with fewer than nine
columns are skipped. Unparseable numbers fall back to defaults: 1 W when the
power is missing or not positive, 0 dB line loss, 2.1 dBi, 2 m, -100 dBm. Power
is converted to dBm as `10 log10(W) + 30`. A system is stored under its **name**;
if a second system in the same file has the same name, the CSV ID is appended
(`Name (7)`) so the two stay distinct. Every imported system is written,
overwriting a stored system of the same ID; the import result counts those that
were new or different.

**Which system a unit gets** (`$NetRole`, `$NetSystem`, `$NetAntHeight`): the
`NetData` file holds one grid per block, with unit IDs across the top and net
IDs down the side. For each unit RidgeCast considers the nets in which it has a
system and a role that is not `0` (a missing role counts as present). It picks:

1. the first such net that is marked visible in `_Network.csv`, else
2. the lowest-numbered such net, else
3. the lowest-numbered net it appears in at all.

Net IDs are compared numerically; non-numeric IDs sort last. The selected net
supplies the unit's system and antenna height. A unit that has *different*
systems in different eligible nets is imported with the chosen one and listed in
the result as having multiple systems.

**Visibility.** If `_Network.csv` marks any net visible, units that are in no
visible net are imported **hidden**. If the file is absent or marks none, no
visibility filtering is done.

**Matching existing nodes.** A unit matches an existing node when its name,
latitude and longitude are all identical. An identical node is counted as
unchanged. A node that matches but differs (system, height, enabled/hidden
state) is not applied; it is returned as a **collision** so you can choose which
side wins. Anything else is added as a new node with a 10 m coverage resolution.

## Vector overlays

| Extension | Format | Geometry read |
| --- | --- | --- |
| `.geojson`, `.json` | GeoJSON | `Point`, `LineString`, `Polygon`, inside `FeatureCollection`, `Feature`, `GeometryCollection` or bare |
| `.kml` | KML | `Placemark` with `Polygon`, `LineString` or `Point` |
| `.kmz` | zipped KML | the first `.kml` entry in the archive |
| `.gpx` | GPX | `wpt` waypoints (points) and `trk` tracks (lines) |

Anything else is rejected as an unsupported extension.

**Limits.** At most 64 files per import (more than 64 imports none). Each file,
and a KMZ's inner KML, must be 50 MiB or smaller. A layer may hold at most
100,000 features. Text must be valid UTF-8. A file with no usable geometry is an
error, not an empty layer. These checks, and cancellation, are polled while
reading and parsing.

**Multi-part features.** GeoJSON `MultiPoint`, `MultiLineString` and
`MultiPolygon`, and every part of a KML `MultiGeometry`, are split into one
feature per part, each keeping the original name. Each feature counts toward the
100,000-feature limit.

**What is not read.** Other GeoJSON types are skipped. GPX routes (`rte`) are
not read, and all `trkpt` points of a track become one line, even across
separate track segments. A polygon needs at least three valid points, a line at
least two. Altitude is ignored.
Polygon holes are kept (GeoJSON interior rings, KML `innerBoundaryIs`; rings
under three points are dropped), though the map draws only outer rings.

**Names.** GeoJSON features take their name from the `name`, `title` or `label`
property, in that order; KML from `<name>`; GPX from `<name>`, with `GPX Track`
as the default for tracks. A KML file without `Placemark` tags falls back to
the first `<coordinates>` element and is read as a polygon (3+ points), line
(2) or point, named `KML Polygon`, `KML Line` or `KML Point`. The KML reader is a
case-insensitive tag scanner, not a full XML parser, so unusual markup (CDATA
tricks, namespaced tags) may be missed.

**Coordinates.** Expected as WGS 84 longitude, latitude (KML tuples are
`lon,lat[,alt]`). Any pair with an |x| above 180 or |y| above 90 is treated as
Web Mercator (EPSG:3857 metres) and converted; a pair that is then still out of
range is discarded individually, and a feature loses only the bad vertices.
Mercator coordinates within 180 by 90 metres of the origin would be read as
degrees; this heuristic is not a CRS detector.

**Identity.** An imported layer is named after the file, gets a unique id, and
starts as a *reference* to the file. Embedded layers store their features in the
project (see [Files and interchange formats](files-and-formats.md)); referenced
layers store only the path and reload from disk.

## Node-source JSON

The **Node Sources** window (**File → Import → Nodes from Online Sources…**) fetches a JSON document
from each enabled source URL. The two source types, `LetsMeshApi` and
`CoreScopeApi`, are parsed identically, so the type only labels the source.

**Document shape.** An object with a `nodes` array, or a bare array of nodes.

**Field aliases.** The first alias present is used:

| Value | Looked up, in order |
| --- | --- |
| id and merge key | `public_key`, `id`, `user.id`; otherwise `unknown` |
| name | `longName`, `name`, `user.longName`, `user.name`; otherwise the id |
| latitude | `lat`, `latitude`, `location.latitude` |
| longitude | `lon`, `longitude`, `location.longitude` |
| role | `role`, `user.role` |
| region | `region`, `user.region` |

A node with no finite, in-range position is dropped, but a coordinate of exactly
0 is kept. Node IDs are derived deterministically from the id string, so
re-importing the same feed yields the same node IDs. Nodes from different
sources with the same merge key are combined into one, the last one read
winning.

**Role codes.** A string role is upper-cased. Roles containing `REPEATER` or
`ROUTER` use the Repeater system choice, `ROOM` the Room choice, `COMPANION` the
Companion choice and `SENSOR` the Sensor choice. A numeric role maps 2, 3 and 4
to repeater and 6 to sensor; any other number, and any unrecognised or missing
role, is ignored. Each choice is a system profile, an empty choice (the default
profile), or `IGNORE`, which drops that role.

**Filters** are combined with OR: a node is kept if *any* enabled filter matches,
and always kept when none is enabled. The filters are the region list
(comma- or slash-separated, case-insensitive, matched against the node's
region codes, with an option to keep nodes that name no region), "within the
current viewport", and "within N km of the viewport's center".

**Fetching and caching.** Each source is fetched with a 15-second timeout and a
50 MiB cap on the reply; a larger or non-UTF-8 reply contributes nothing. The
reply is cached as `<host>_<hash>.json` in the node-source cache, where the hash
is of the full URL. A cached copy is used whenever it exists; only **Import (Force Fresh)** refreshes it. A source that fails to fetch or parse is
logged in the import window and skipped. Work Offline skips uncached sources.

## FCC amateur-license import

The FCC ULS amateur archive (`l_amat.zip`) is read from the downloaded ZIP or
from a directory of already extracted files. The tables are pipe-separated,
read with lossy UTF-8:

| File | Record | Used |
| --- | --- | --- |
| `HD.dat` | `HD` | ULS id (field 1), callsign (4), status (5), radio service (6), grant date (7), expiry (8). Must be read first. |
| `AM.dat` | `AM` | operator class (field 5) |
| `HS.dat` | `HS` | history dates (field 4); the earliest date seen becomes the license's *first seen* date |
| `EN.dat` | `EN` | entity name (7), street (15), city (16), state (17), ZIP (18) |
| `counts` | optional | the archive's creation date |

All four `.dat` files are required; a missing one fails the import. The new
table is built beside the old one inside one transaction and swapped in only at
the end, so a failed or canceled import leaves the previous catalog intact.
Addresses and geocodes already learned are kept. Addresses are deduplicated by a
normalised key (whitespace collapsed, upper-cased, prefixed `v1`). The database
is `amateur/amateur.sqlite` in the cache directory. ZIP entries that are read
whole (`counts`, the Census gazetteer) are capped at 256 MiB.

### Geocoding

Imported licenses have no coordinates. **Find hams in current view** geocodes
only the addresses near the map, in this order:

1. **Scope.** The view is widened by a margin (at most 500 km) and the request is
   refused if the view is wider than 20 degrees or taller than 15. An address is
   "nearby" when its ZIP's centroid lies in the widened area, or it shares a
   three-digit ZIP prefix with one that does (an intentional over-inclusion so PO
   boxes and postal-only ZIPs are still handled). Only addresses with a two-letter
   state and a street, matching the license status, class and recency filters,
   are sent.
2. **ZIP index.** If the local ZIP-centroid table is empty, the Census ZCTA
   gazetteer is downloaded once (capped at 256 MiB).
3. **Census batches.** Up to 10,000 addresses at a time are posted as CSV to the
   U.S. Census batch geocoder (benchmark `Public_AR_Current`, 300-second
   timeout). Each result is stored as `match`, `tie` or `no_match`; an address
   missing from the response is stored as `error` and is retried by the next
   run (not within the same run). Results are committed per batch, so an
   interruption keeps what finished.
4. **ZIP fallback.** Addresses still without coordinates (`no_match` or `tie`)
   get the centroid of their five-digit ZIP, or failing that the average
   centroid of their three-digit prefix, marked as a *ZIP-area centroid (not an
   address match)* or *ZIP-prefix centroid*. These are explicitly low accuracy.

Looking up one free-form US street address (for example an address given to the
headless place lookup) uses the same Census service. It returns a match, "no match" (cities, landmarks
and businesses are not street addresses) or "unreachable", which are reported
differently.
