# Work offline and manage cached data

## Prepare a specific calculation task

Open **Tools → Prepare Data for Offline Calculations…**. Choose the selected link (or pairs of
selected nodes), coverage from selected enabled nodes, or Site Finder in the
current viewport. The request freezes its geometry, range, actual coverage/scan
resolution and refinement. Set profile spacing for link paths and choose optional
categorical clutter, population grading, ambient-noise inputs and measured
surfaces. Changing the network, selection or request invalidates an older report.

**Check task from disk** runs on a worker and contacts no providers. Each selected
requirement is reported as **ready**, **missing**, **partial**, **unsupported**,
or **capped**. Valid sampled elevations/classes/population/surface heights are
counted separately from file inventory. NoData, corruption, a disabled source,
or an extent without source coverage cannot establish readiness. RF calculation
cache reuse is explicitly separate from source-data availability.

The probe cap is at most 50,000, selected link pairs at most 256, preparation at
most 512 terrain tiles and population preparation at most 16 country products.
An exceeded cap is never a ready result. Narrow the requested task or use a
coarser actual calculation setting before preparing it. Download estimates are
rough planning figures; country files and public measured surfaces have variable
size. A report describes the requested sampling, rather than certifying every
pixel in a rectangular region.

While online, **Prepare selected requirements online** visits only the bounded
task requirements and checks them again after preparation. **Cancel task work**
cancels that worker and its logical download tickets while unrelated downloads
continue. A transfer already inside an HTTP call stops at its next bounded
timeout/checkpoint. Normal download pause, cancel and offline controls also apply.
Public measured-surface preparation follows selected link corridors and at most
16 coverage or Site Finder probe locations. Larger missing surface requirements
are reported as capped. Registered surveys and disk-cached public surfaces are
also checked. A missing measured sample keeps categorical fallback, and this flow
never promises global LiDAR.

The optional basemap zoom range is reported explicitly as **unsupported** for
certification: provider HTTP cache metadata cannot reliably establish exact
image availability. This does not imply that other zooms are cached. RF readiness
can be checked without selecting basemap certification. Inspect the map at the
needed zooms while online and verify it after switching offline.

[Registered local rasters](register-local-raster-sources.md) are restored from
their checked content copies. Corrupt or replaced copies are reported and require
an explicit re-import. Recheck the task after changing sources or preparing more
data, then enable **Downloads → Work offline** and run the intended calculation.

## Prepare an area for offline work

These steps prepare terrain and land cover only. They do not verify basemap,
LiDAR, population, or calculated-result caches. Run the specific links,
coverage, and data loads you will need while online, then verify them after
switching offline.

1. While online, open **Map Settings → Prepare Offline Area**.
   Enter the west, east, south, and north coordinates in decimal degrees, or
   choose **Use Visible Map** to copy the current map extent. You can edit the
   coordinates afterward; panning the map does not change the selected region.
2. Choose **Check Availability**. RidgeCast checks local terrain and land-cover
   files in the background and reports how many tiles are missing. If a count is
   capped, split the selected region into smaller parts.
3. Choose **Download Missing Tiles** while online. Watch the remaining counts
   and the **Downloads** window for transfer failures. Both counts must reach
   zero to establish file presence; use the task checker above to validate sampled
   data and NoData coverage. **Cancel Downloads**
   stops all active downloads, including those from other tasks.
4. Run the links and coverage you expect to use so their dependent data and
   persistent results are cached.
5. Open **Downloads** and wait for active transfers to finish.
6. Enable **Downloads → Work offline**.
7. Revisit the area and repeat the important calculations to verify that the
   required data is available.

Offline mode blocks every outbound request, including basemap tiles. Previously
cached data remains available; an area that was never downloaded can remain
blank. Downloads already under way are held at their next checkpoint and can
resume when **Work offline** is turned off; they are not discarded. Wait for
**Downloads** to show no active transfers before relying on offline mode for a
privacy-sensitive session.

## Move the cache to another disk

1. Open **Settings → Application Preferences**.
2. Choose a new cache directory.
3. Select **Apply & Restart Caches**.
4. Confirm that the dialog reports the new active root and that new work uses it.
5. Move or remove the old cache manually only after verifying the new location.

The old cache can reveal downloaded study areas and derived results. Treat it as
private project material: keep it in a protected location, or delete it only
when you no longer need its downloaded data and can afford to obtain it again.

Changing the setting redirects future cache use; it does not migrate the old
directory. A cache root is per-user and is not safe to share concurrently across
several RidgeCast installations.

## Reduce cache usage

Use **Application Preferences** to inspect each cache category and set or remove
its limit. **Compact** rewrites older uncompressed cached rasters without
deleting them. WorldPop rasters and uncategorized files are not automatically
evicted.

See [Data sources and caches](../reference/data-sources-and-caches.md) for paths,
categories, and network endpoints, and [the detailed data guide](../data-and-caching.md)
for mirror administration.
