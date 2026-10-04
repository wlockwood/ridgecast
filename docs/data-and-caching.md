# Data, caches, mirrors, and working offline

*Where RidgeCast's data comes from, where it lands on disk, how much of it there
will be, how the caches are bounded, and how to work without a network — plus how
to publish a population mirror of your own.*

For concise procedures, use
[Work offline and manage cached data](how-to/work-offline-and-manage-caches.md) or
[Acquire constrained WorldPop tiles and publish a mirror](how-to/publish-a-worldpop-mirror.md). This page is the
detailed operator reference behind those tasks.

---

## 1. RidgeCast downloads a great deal

RidgeCast ships with no bundled elevation or basemap tiles. A small worldwide
ocean/lake mask is bundled for [terrain-display water transparency](reference/controls-and-shortcuts.md#terrain-overlay-and-water).
Data used for calculations is fetched on demand and cached locally: elevation, land cover,
LiDAR point clouds, population, basemap tiles, the FCC amateur catalog, and
geocoding results.

No API keys are required for any of the built-in sources. Internet access is
needed only when something is not already cached.

Almost all of it arrives as **rasters** — regular grids of values covering an
area, like a very large image whose pixels are ground heights or land-cover
classes rather than colors. They are big.

A single USGS 3DEP elevation tile — one degree of latitude by one of longitude,
roughly 110 km on a side — is about 400 MB. Constrained WorldPop country COGs
range from a few megabytes to hundreds of megabytes or more. Raw LiDAR point clouds are
the largest thing the application fetches, and a single suburban neighbourhood
can pull a few hundred megabytes of them. Planning for tens of gigabytes is
realistic; one real installation reached 164 GB before cache budgets existed.

## 2. Where things land

RidgeCast keeps two kinds of local state, and the distinction matters when you
back things up or move a project.

**Operating-system application directories** hold everything downloaded and every
persisted preference: map tiles, terrain, land cover, LiDAR point clouds and
derived surfaces, population rasters, node-source responses, the FCC catalog,
geocoding results, and the persisted map and Site Finder settings. Downloaded
caches use the **selected application cache root**; small preference files stay
in the operating system's standard config directory.

On a default install those are the platform's standard per-user locations for a
`ridgecast` application:

| Platform | Cache root (the large one) | Config directory |
| --- | --- | --- |
| **Windows** | `%LOCALAPPDATA%\ridgecast\ridgecast\cache` | `%APPDATA%\ridgecast\ridgecast\config` |
| **macOS** | `~/Library/Caches/com.ridgecast.ridgecast` | `~/Library/Application Support/com.ridgecast.ridgecast` |
| **Linux** | `~/.cache/ridgecast` (or `$XDG_CACHE_HOME`) | `~/.config/ridgecast` (or `$XDG_CONFIG_HOME`) |

Treat the dialog as authoritative rather than this table: **Settings →
Application Preferences** displays the currently active cache root, which is the
only place that accounts for a custom root set earlier or migrated from an older
layout.

**For backups: back up the working directory; treat the cache root as
disposable.** Everything under the cache root can be re-downloaded, and none of
it is yours. The project files below are the only irreplaceable state.

**The current working directory** holds the project itself:

| File | Contents |
| --- | --- |
| `network.json` / `network.yaml` | the network — nodes, systems, links |
| `terrain_config.json` | terrain and geodata source configuration |
| `node_sources.json` | configured JSON node-source APIs |
| `window_config.json` | window layout |

Because these are read and written relative to wherever the application was
started, **running RidgeCast from a dedicated project directory is
recommended** — otherwise two projects share one `network.json`.

The repository's `.gitignore` excludes runtime state, downloaded datasets,
generated networks, and diagnostic artifacts. This is load-bearing for the FCC
data in particular: the downloaded archive, the extracted records, the SQLite
database, and its write-ahead-log files contain **public mailing addresses** and
must not be committed.

### Moving the cache

**Settings → Application Preferences** lets you choose a cache directory, then
press **Apply & Restart Caches**. The dialog shows the currently active cache
root, which is the fastest way to answer "where did all my disk space go".

Two things to know before you do it:

- **It redirects; it does not migrate.** New downloads go to the new root and
  the old directory is left where it is. Move or delete the old tree yourself
  once you are satisfied the new root is working — nothing in it is
  irreplaceable, but nothing removes it for you either.
- **It is a per-user setting on one machine.** There is no shared-cache feature:
  RidgeCast does not coordinate concurrent access between installs, so a team of
  a dozen will download overlapping terrain a dozen times. Pointing several
  installs at one network share is not a supported configuration and is not
  guarded against concurrent writes.

## 3. Where the data comes from

| Data | Sources |
| --- | --- |
| Basemaps | OpenStreetMap, OpenTopoMap, Esri World Imagery |
| Elevation | USGS 3DEP (1/3 arcsecond, US), Copernicus GLO-30 (global), legacy Skadi/SRTM `.hgt` |
| Land cover | MRLC / NLCD (United States) |
| LiDAR | USGS 3DEP and NOAA Digital Coast public point clouds |
| Population | WorldPop 2020 UN-adjusted constrained country rasters |
| Amateur licenses | FCC ULS bulk amateur archive |
| Geocoding | U.S. Census geocoder and postal-area data |
| Node sources | whatever URLs you configure |

Elevation tiles can contain blank areas even when the tile downloads successfully.
RidgeCast honors each GeoTIFF's NoData marker and tries the next enabled terrain
source there. For example, a USGS tile extending into Canada can contain no
elevation data on the Canadian side; enable Copernicus GLO-30 to supply global
terrain for those areas. Existing downloaded tiles can be reused. Completed
coverage retains available results and can offer to enable a disabled dataset;
see [Missing terrain and disabled datasets](reference/data-sources-and-caches.md#missing-terrain-and-disabled-datasets)
for the dialog choices and the Geodata prompt control.

Use of these services is subject to their own availability, attribution,
licensing, and usage policies.

### Egress allowlist

Every hostname a default installation contacts, for building a firewall rule.
All are reached over HTTPS on port 443, and nothing else leaves the machine —
**RidgeCast has no telemetry, no analytics, no crash reporting, and no update
check.** The only outbound traffic is data fetches.

| Host | For |
| --- | --- |
| `tile.openstreetmap.org`, OpenTopoMap, and Esri World Imagery tile hosts | basemaps |
| `elevation.nationalmap.gov` | USGS 3DEP dynamic elevation exports |
| `prd-tnm.s3.amazonaws.com`, `prd-tnm.s3.us-west-2.amazonaws.com` | USGS 3DEP elevation |
| `rockyweb.usgs.gov` | USGS 3DEP elevation (fallback) |
| `copernicus-dem-30m.s3.amazonaws.com`, `copernicus-dem-30m.s3.eu-central-1.amazonaws.com` | Copernicus GLO-30 elevation |
| `opentopography.s3.sdsc.edu` | Copernicus GLO-30 elevation (fallback) |
| MRLC / NLCD land-cover host | land cover |
| `worldpop.ridgecast.org` | population (first mirror) |
| `data.source.coop` | population (WFP / Source Cooperative fallback) |
| USGS 3DEP and NOAA Digital Coast LiDAR hosts | point clouds |
| FCC ULS archive host | amateur licenses |
| `geocoding.geo.census.gov` and Census postal-area hosts | geocoding |

**Plus whatever you configure.** Node sources are user-supplied URLs and are
open-ended by design; so are the mirror templates in §4. An allowlist built from
this table will not cover a node source someone adds later. Mirror hostnames are
also editable, so confirm the active list in **Settings → Terrain & Geodata
Settings** before treating this table as complete for your install.

`worldpop.ridgecast.org` is operated by the RidgeCast project rather than by
WorldPop, and it is first in the order because it is fast and flat-file simple.
It carries no uptime guarantee. If you would rather not depend on it, disable it
and let the WFP / Source Cooperative collection serve instead —
the fallback chain is designed for exactly that.

The basemap endpoints in particular are **shared public services intended for
interactive viewing**. RidgeCast requests only the tiles needed for the current
view and does not prefetch or bulk-download them. Please do not work around that.

Cached third-party data is not part of this repository and carries its own
license terms — WorldPop, for instance, is CC-BY-4.0 and its attribution must
travel with any copy you redistribute.

## 4. Mirrors and the fallback chain

Mirror Preferences includes a **Test** button for each source and a separate test
for the dynamic USGS 3DEP service. Tests fetch fresh samples and stop after the
first valid raster. See [Testing mirrors and sources](reference/data-sources-and-caches.md#testing-mirrors-and-sources)
for sample locations, limits, and result meanings.

The configurable USGS mirrors below serve static ~10 m tiles. The finer target
(3 m by default) uses USGS's dynamic, multi-resolution elevation service, with
no configurable mirror list. Requested pixel spacing and available native
resolution are different: resampling to 3 m does not create finer source detail.

Several data types are fetched through an **ordered list of mirrors**. Each entry
has a label, a URL template, and an enabled flag; RidgeCast tries the enabled
entries in order and moves to the next when one fails.

Defaults ship for elevation:

**USGS 3DEP** (template placeholder `{tile}`)

1. AWS us-east-1 (The National Map)
2. USGS delivery host (`rockyweb.usgs.gov`)
3. AWS us-west-2

**Copernicus GLO-30** (placeholders `{cog}`, `{cop30}`)

1. AWS Open Data, us-east-1
2. AWS Open Data, eu-central-1
3. OpenTopography

A placeholder is substituted with the tile identifier before the request is made.
The first 3DEP entry above, with `{tile}` filled in for the tile covering
Seattle, becomes:

```
https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/13/TIFF/current/n48w123/USGS_13_n48w123.tif
```

The templates are editable, which is what makes a private or institutional mirror
possible — point one at your own host and keep the rest of the path identical.
Copernicus tiles are named `Copernicus_DSM_COG_10_...`, and some mirrors drop the
`COG_` segment; being able to change the schema is the reason this is
configurable rather than hard-coded.

### One rule that is not configurable: HTTPS only

**A mirror URL that is not `https://` is skipped.** This is deliberate and it is
not a preference. The refusal is written to standard error, so it is visible when
RidgeCast is launched from a terminal and easy to miss when it is launched from a
desktop icon — if a mirror you configured never seems to be used, check its
scheme first.

Everything a mirror serves is fed straight into a parser — and, for the
population GitHub layout, into an archive extractor — with **no signature checked
afterwards**. There is no integrity check downstream that would catch a modified
tile. A plaintext endpoint therefore hands an on-path attacker control of the
elevation, land cover, and population data the application acts on. Refusing the
fetch is the only defense available at that layer.

Endpoint lists arrive both from the settings UI and from configuration files that
can be shared between people, so nothing guarantees the scheme without this
check. The comparison is case-insensitive, because `HTTPS://` is typed often
enough to matter.

## 5. WorldPop population mirrors

Coverage population, Site Finder population weighting, and ambient-noise density
use WorldPop's **2020 UN-adjusted constrained** country rasters (~100 m,
people per pixel, WGS 84, CC-BY-4.0). Population is restricted to mapped
settlements and country totals are adjusted to UN estimates. The matching files
in `worldpop_tiles/` are named `<iso3>_ppp_2020_UNadj_constrained.tif`.

RidgeCast ships two sources tried in order:

| Order | Source | Layout | Multi-part |
| --- | --- | --- | --- |
| 1 | `worldpop.ridgecast.org` | Flat GeoTIFF — `{base}/{iso3}_ppp_2020_UNadj_constrained.tif` | no |
| 2 | [WFP / Source Cooperative](https://source.coop/wfp/wp-pop-icunadj) | Lowercase country directory — `{base}/{iso3}/{iso3}_ppp_2020_UNadj_constrained.tif` | no |

Order, enablement, URL, and expected path layout are all editable under
**Settings → Terrain & Geodata Settings → Mirror Preferences**.

The Source Cooperative base URL is
`https://data.source.coop/wfp/wp-pop-icunadj`. Its layout is **Source Cooperative
country directory**; both country codes in the path are lowercase. **WorldPop
country directory** remains available for custom hosts with uppercase country
directories. Every layout requests the constrained filename, preserving `UNadj`
case. `RIDGECAST_WORLDPOP_MIRROR` also uses the constrained filename with the
existing uppercase-directory convention (or a flat path for release URLs and
bases ending in `/flat`).

GitHub Releases remains an optional configurable source. With **7z parts**
enabled, RidgeCast fetches `<iso3>_ppp_2020_UNadj_constrained.7z.001`, `.002`,
and later parts, reassembles the archive, and extracts the exact expected TIFF.
All countries, including USA, use this basename. Old unconstrained archives
are not a fallback.

Population rasters are **retained until you clear them manually** — they are not
swept by ordinary cache eviction.

### Upgrading existing installations

Old `*_ppp_2020.tif` cache files are ignored, rather than relabeled or mixed with
constrained data. They remain on disk until removed manually or through **Clear
Population**. Constrained files can be copied into the `population/` cache while
RidgeCast is closed; the next startup preloads them on a worker.

Saved source order, labels, and enablement remain intact. The former built-in
unconstrained WorldPop upstream URL is automatically changed to the WFP / Source
Cooperative endpoint and layout. A saved GitHub source requests only the new
constrained assets; remove it if it still hosts only legacy archives. Fresh
installations use the two defaults above. Recalculate coverage and
population-weighted site results; the coverage calculation cache version has
changed to prevent reuse of the previous population model.

A country missing from the project mirror falls through to Source Cooperative.
Mirror contents can change independently of RidgeCast; inspect **Downloads**
for the source actually used. To acquire or publish additional countries, see
[Acquire constrained WorldPop tiles and publish a mirror](how-to/publish-a-worldpop-mirror.md).

### Interrupted downloads resume

A population download in progress is written to `<iso3>_ppp_2020_UNadj_constrained.tif.tmp` in the
population cache, beside a small `.tmp.source` file recording which URL those
bytes came from. If the transfer is interrupted — you cancel it, the connection
drops, or RidgeCast is closed — the partial is kept and the next attempt
continues from where it stopped with an HTTP range request, so a multi-gigabyte
raster does not start over.

A partial is only ever continued against the exact URL that produced it. Each
mirror serves its own byte stream for the same country, so when the fallback
chain moves to a different source the partial is discarded and the new source
starts from zero.

Resuming needs the host to honour `Range`. If a host returns the whole file when
a range was requested, **Downloads** reports the transfer as unresumable rather
than retrying it from the beginning. Split GitHub archives are re-fetched rather
than resumed. This describes RidgeCast's downloader; the acquisition script
below starts a fresh transfer when rerun.

A download that ends early is now rejected instead of being cached: RidgeCast
compares the bytes received against the length the server declared, so a
truncated raster never lands in the cache looking complete.

### Publishing a mirror for one country

From the repository root, download the constrained country TIFFs, then upload
them to a public flat-file mirror. The download and upload scripts are
[`tools/Download-WorldPop2020.ps1`](tools/Download-WorldPop2020.ps1) and
[`tools/Upload-CloudflareR2.ps1`](tools/Upload-CloudflareR2.ps1):

```powershell
.\tools\Download-WorldPop2020.ps1 -Countries CAN, USA, AUS
# Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, and R2_BUCKET first.
Get-ChildItem -Path .\worldpop_tiles\*_ppp_2020_UNadj_constrained.tif -File |
    .\tools\Upload-CloudflareR2.ps1 -PassThru
```

The download script defaults to `worldpop_tiles/`; the upload script preserves
each filename as its object key. Keep WorldPop attribution and CC-BY-4.0 terms
with any mirror. See the [acquisition and publishing guide](how-to/publish-a-worldpop-mirror.md)
for credentials, public R2 reads, offline cache installation, optional GitHub
archives, and verification.

## 6. Cache categories and budgets

The cache is divided into seven categories. Six are independently budgeted;
population is deliberately exempt.

| Category | Holds | Default cap |
| --- | --- | --- |
| **Map tiles** | basemap imagery | 2 GB |
| **Terrain** | elevation rasters (3DEP, GLO-30, legacy HGT) | 20 GB |
| **Land cover** | NLCD rasters | 4 GB |
| **LiDAR surfaces** | derived DSM/DTM products and resolved catalogs | 16 GB |
| **Point clouds** | raw LiDAR tiles exactly as served | 16 GB |
| **Coverage** | completed per-node coverage grids | 1 GB |
| **Population** | WorldPop country rasters | **none — never evicted** |

**Allow at least 59 GB for the default budgets.** The six capped categories
sum to 59 GB, and population is unbounded on top of that. There is no overall
total cap: RidgeCast enforces caps per category only, so the categories are the
budget. Add whatever population rasters your area of interest needs — 300–900 MB
per country — and leave headroom, because a category is trimmed *back* to its cap
rather than being prevented from reaching it.

Population is exempt on purpose. Re-fetching a 900 MB raster to reclaim a
gigabyte is a poor trade, so those files are removed only when you clear them
yourself. That exemption is enforced in two places — the limit is stripped when
budgets are normalised, and the eviction pass skips the category outright — so it
holds even if a configuration file names a population limit.

Each capped category is trimmed **independently**, and **one category never
evicts another**. The two LiDAR categories are separate for a specific reason:
point clouds are the largest thing downloaded, are shared by every surface that
overlaps them, and are the expensive item to re-fetch, while surfaces are small,
numerous, and cheap to rebuild from a cached cloud. Capping them together would
let a burst of surfaces evict the clouds that make the next surface cheap.

Eviction is least-recently-used and runs in the background. Map tiles rank by
write time rather than by use, because their content-addressed HTTP cache cannot
be hooked on read; removing a cached tile body is safe regardless, since the
reader treats an unreadable entry as a miss and re-downloads.

### How the defaults are applied — and when they are not

This is subtle and worth stating precisely. There are three states, not two:

- **No cache configuration file exists** — the defaults above are applied.
  Nothing was ever chosen, so nothing was ever enforced, and a cache that only
  grows is not a defensible default.
- **A configuration file exists** — it is honoured exactly as written, including
  categories you deliberately left uncapped. A field missing from a configuration
  you wrote means "no cap", and an upgrade must not start deleting your data
  behind your back.
- **A configuration file exists but is unreadable or malformed** — **no limits
  are enforced at all**, and the desktop shows **Cache limits are disabled**
  with the file location and the read or parse error. A file
  RidgeCast cannot parse is not consent to delete data, so enforcement stays off
  until you fix or replace it.

Choose **Open cache settings** in the warning, or open **Settings → Terrain &
Geodata Settings → Geodata Disk Cache**. The load failure remains visible there
even if you dismiss the startup warning. Back up `cache_budget_config.json` at
the shown location, choose the intended category limits, and finish editing a
limit or choose **Save current budgets**. Enforcement resumes after that save
succeeds. If the save fails, **Settings were not saved** offers **Retry**; check
configuration-directory permissions and free space first. You can also repair
the file while RidgeCast is closed and restart. The diagnostic is written to
standard error for headless and terminal-launched sessions.

**The file is written only when you save budgets in Settings → Terrain &
Geodata Settings.** It is not created on first run. Until you have saved once, your
install is in the first state, and a future release that changes the suggested
defaults would change your enforced caps with it. Saving once pins them.

**Settings → Terrain & Geodata Settings** measures every category and lets you
change or remove any limit.

Files in the cache folder that belong to **no** category — the amateur license
database, for instance — are measured and shown but **never deleted
automatically**.

### Compaction

**Compact** rewrites cached rasters in compressed form without deleting anything.
It typically reclaims about a third of the terrain cache.

Newly written rasters are compressed as they arrive, so this is only needed once,
for data cached by an earlier version. Files that are already compressed as tightly as
they will go are skipped, because wrapping them spends CPU to save nothing:
recompressing a LAZ point cloud was measured at 99.9% of its original size, which
is to say it saved nothing at all. A file currently in use is skipped rather than rewritten and will be
picked up on a later run.

## 7. Working offline

**Work Offline**, available from the Settings menu and from the Downloads window,
blocks outbound requests across every source: terrain, land cover, LiDAR
surfaces, point clouds, population, FCC, geocoding, and basemap tiles.

Precisely what it does:

- **New downloads are refused.** No new request is issued while it is on.
- **Downloads already in flight are held**, not killed, at their next checkpoint,
  and resume when you turn it off.
- **Cached data stays fully available.** Calculations that need nothing new run
  normally.
- **Basemap tiles already drawn keep rendering**, coarsening as you zoom past
  what is cached rather than disappearing.
- **Areas never downloaded are left blank** until downloads are re-enabled.

If the map, an overlay, or the basemap is unexpectedly blank, checking whether
Work Offline is on is the first thing to do — it blocks basemap tiles as well as
datasets.

## 8. The Downloads window

The Downloads window shows active work with per-file download rates (MB/s), total
network utilisation, and expandable URIs with copy and open controls. It provides
pause, cancel, retry, and the offline toggle.

Two things about it are more useful than they sound:

- **Each entry names what asked for it**, by node name — a specific node's
  coverage, or the corridor between two named nodes. A download is never an
  anonymous URL.
- **Show on map** centers and zooms on the thing that caused it: the two ends of
  a link corridor, every link of a node, or the downloaded tile itself, with the
  downloaded area outlined until you click elsewhere.

## 9. Privacy

Downloaded or queried data **may disclose the geographic area you are studying**
to the selected public providers. Every terrain tile, land-cover request, LiDAR
corridor, basemap tile, and geocoder batch is an observable request for a
specific place at a specific time.

If that matters for your work, the options are to prefetch an area in advance and
then work offline, or to run mirrors you control (§4–§5).

FCC records contain **public mailing addresses**. RidgeCast does not geocode the
entire national catalog; it selects ungeocoded addresses near the current
viewport, submits Census geocoder batches, and caches results by canonical
address. That still means the addresses near your viewport are sent to the Census
geocoder.

## 10. Cache troubleshooting

**"The cache is on the wrong disk."** Settings → Application Preferences, choose a
cache directory, then **Apply & Restart Caches**.

**"The cache has grown very large."** Check each category's measured size in
Application Preferences. If you have a configuration file with categories left
uncapped, they are uncapped on purpose (§6) — set limits explicitly. Run
**Compact** once if the data predates automatic compression.

**"LiDAR surfaces cached by a much earlier version are not reused."** Surfaces
are now stored as a height above ground rather than as a pair of elevation
rasters, which is about eight times smaller. Directories in the old layout are
ignored and rebuilt from the point clouds, which stay cached — so **no LiDAR is
downloaded again**. The superseded files are removed by the ordinary cache sweep.

**"A calculation appears to wait."** Terrain and land cover must be available
before full propagation can finish. The status bar distinguishes downloading,
profile generation, and RF calculation, and the Calculation Progress window shows
which step a run is actually in.

---

## Where else to look

- **[RidgeCast documentation](README.md)** — tutorials, operational guides, and
  reference pages for the features these caches support.
- **[Clutter, LiDAR, and canopy density](concepts/clutter-and-lidar.md)** — why
  point clouds are the largest download, and the two gates that decide how much
  of one is worth fetching.
- **[Coverage maps](concepts/coverage.md)** — the coverage cache, which is keyed
  and managed separately from the geodata caches described here.
- **[`SECURITY.md`](../SECURITY.md)** and
  **[`docs/security/THREAT_MODEL.md`](security/THREAT_MODEL.md)** — the full
  threat model behind the HTTPS-only rule and the input-validation policy.
