# Troubleshoot RidgeCast

## The application cannot open a window

Confirm that current graphics drivers and a desktop session are available.
RidgeCast cannot display its native UI directly in a headless shell or container.

## The map or an overlay is blank

Open **Downloads** and check whether **Work Offline** is enabled. Offline mode
also blocks uncached basemap tiles. Otherwise, try another basemap or overlay and
inspect failed downloads.

## A calculation appears to be waiting

Open **Calculation Progress**. Terrain, land cover, and optional LiDAR may need
to finish before propagation can run. The current phase distinguishes downloads
from profile preparation and solving.

## Coverage or Site Finder takes too long

Reduce the visible area or range, then choose a coarser resolution. Confirm the
area with **Draft** or **Fast Scout** before refining it.

## The cache is too large or on the wrong disk

Follow [Work offline and manage cached data](work-offline-and-manage-caches.md).

If RidgeCast shows **Cache limits are disabled**, it could not read or parse
`cache_budget_config.json`. The warning names the file and the error. Choose
**Open cache settings**, or open **Settings → Terrain & Geodata Settings →
Geodata Disk Cache**; the failure stays visible there after dismissal. Back up
the file at the shown location, choose the wanted category limits, then finish
editing a limit or choose **Save current budgets**. Enforcement stays disabled
until that save succeeds. If **Settings were not saved** appears, check disk
space and configuration-directory permissions, then choose **Retry**. You can
also repair the file while RidgeCast is closed and restart. See
[Data and caching](../data-and-caching.md#2-where-things-land) for configuration
locations; these are separate from the large cache root.

## Settings could not be saved

If RidgeCast shows **Settings were not saved**, the named preferences are still
active for this session but may be lost at restart. Check that the destination
disk has space and that RidgeCast can write to it, then choose **Retry**. The
retry saves the current settings. You can also choose **Dismiss** to close the
message without retrying. Applying a new cache directory prepares that location
in the background; the caches restart after it is ready.

When repairing an unreadable cache-budget file, limits stay disabled until the
save succeeds. A failed repair keeps both the proposed limits and the warning
in **Terrain & Geodata Settings**, so **Retry** can save the current choices.

## A project save failed

**Save failed** means the project file was not updated. Your current work stays
open. Hover the status for the error, check disk space and destination
permissions, then choose **Retry Save** or **File → Save As…** to select a
writable location. A failed or canceled save during New, Open, Quit, or another
document transition leaves the current document open.

**Unsaved changes** after a successful save can mean you edited the document
while its snapshot was being written. Save again to include those newer edits.
**Finishing saves…** during close means RidgeCast is waiting for pending writes.
If shutdown reports an error, the document remains open so you can retry.

## Unsaved work needs recovery

After an interrupted session, use the **Recover Unsaved Work** startup dialog
or **File → Recover Unsaved Work…**. Compare the listed path and capture time,
choose **Recover**, inspect the result, then Save or Save As. **Later** keeps
the snapshot; **Discard Recovery** deletes it without changing the project file.
Recovery may lag the last edit and does not preserve undo history.

**Recovery failed** means the current work may not have an up-to-date recovery
copy. Hover the status for the error and save the project explicitly. Check disk
space and write permissions in the [recovery directory](../reference/files-and-formats.md#recovery-snapshots).
An unreadable or unsupported recovery record is retained with a warning naming
the file. Back it up before attempting a manual repair or removing it; valid
records remain available for recovery.

Older versions wrote `network.json` and `network.yaml` in the working directory.
Keep copies before attempting legacy recovery. Current startup reopens your most
recent network instead, and only tries the newest valid default file when no
remembered network survives; open another copy with **Open Network…** if it
contains the edits you want, then save to a chosen project file. Current
background recovery does not update those legacy defaults.

## An import did not replace the network

Node-source downloads are staged. Choose **Use Imported Network** after the
download, then answer the unsaved-work prompt. A failed, canceled, or empty
import keeps the current document; inspect the source errors and filters before
retrying. If you edited the network while a merge was being prepared, its
result is rejected to preserve your edits. Retry against the current document.

## Radio Mobile import reports missing files

Keep the matching `_Unit.csv`, `_System.csv`, and `_NetData.csv` files together
and select the `_Unit.csv` file. All three filename prefixes must match.

## An older LiDAR surface is not reused

Current surfaces store height above ground rather than paired elevation rasters.
Older layouts are ignored and rebuilt from cached point clouds, so the original
LiDAR normally does not need to be downloaded again. Superseded files are
removed by the ordinary cache sweep.
