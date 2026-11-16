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

A run whose LiDAR is already cached still has work to do before it can solve:
**Building surfaces** crops a surface model out of those cached tiles, one per
site or link corridor. The status bar counts the crops as they complete, and the
overall bar stays near zero until solving starts, because the bar tracks solved
links rather than preparation. On a network with many thousands of cached tiles
this step can run for several minutes.

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
active for this session but may be lost at restart. The dialog explains the
reported cause and shows the destination, failed operation, and original error
(including the OS error code when available). Settings are written to a temporary
file before replacing the destination, so a failed write leaves the previous
file intact.

Read the findings before choosing **Retry**:

- **File lock:** save work in any other RidgeCast windows, close them, and retry.
  Editors, sync tools, or antivirus scanners can also hold a file open. Another
  running copy alone does not prove that it caused the failure. On Windows,
  replacement of a locked file can report **Access denied**; the dialog also
  checks for a sharing lock that currently blocks replacement. This check does
  not modify the file or identify which program holds the lock.
- **Disk space or quota:** free space on the destination drive or check your
  account quota. The temporary copy needs space alongside the existing file.
  Less than 10 MiB available is flagged as low space; a high percentage used does
  not by itself explain why a small settings file could not be saved.
- **Access denied or read-only destination:** check the file's read-only attribute,
  folder permissions, and security software's blocked-app history. Replacement
  requires access to the containing folder as well as the file.
- **Unavailable destination or invalid path:** reconnect the drive or network
  share. A folder where a settings file should be is also reported; back it up
  and correct the path before retrying.
- **Settings could not be prepared:** copy the diagnostic details when reporting
  the problem; the failure may have happened before any file was written.

On Windows, the dialog automatically checks file attributes, available space for
your account on the destination volume, and other processes named `ridgecast.exe`
or matching the current executable's name (excluding this process). Different
renamed copies can be missed. Checks describe the state **after** the failure;
space and locks may have changed. A failed or unsupported check is reported as
unavailable, not as a clean result. Automatic disk-space and process checks are
currently Windows-only. All checks run in the background without writing probe
files or changing permissions.

**Retry** saves the current settings and refreshes the findings if saving fails
again. **Copy diagnostic details** copies the settings name, destination, checks,
and original error; it does not copy settings contents. **Dismiss** closes the
message without saving. The destination matters: some settings use the per-user
configuration directory while others use the workspace. See
[Data and caching](../data-and-caching.md#2-where-things-land) for locations.
Applying a new cache directory prepares that location in the background; a
failure keeps the previous location active.

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
