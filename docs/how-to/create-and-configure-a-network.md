# Create and configure a network

Use this guide to build a RidgeCast network from manually placed sites.

To start over, choose **File → New Network**. If the current network has unsaved
changes, choose **Save** to save it before continuing, **Don’t Save** to continue
without those changes, or **Cancel** to keep working. A canceled file chooser or
failed save keeps the current network open.

1. Start RidgeCast with a dedicated project directory as its working directory.
   For a source build, open a terminal in that directory and run
   `cargo run --release --manifest-path /path/to/ridgecast/Cargo.toml`.
2. Pan or zoom to the planning area.
3. Set the network's shared frequency under **Settings → Network Frequency…**.
   Then choose **Edit → Radio Systems Manager** and create its shared radio systems.
   Enter transmit power, antenna parameters,
   receiver bandwidth and noise figure, losses, and coverage defaults.
4. Right-click the map and choose **Add Node Here**, or use
   **Edit → Add Node at Coordinates** for a known latitude and longitude (in
   decimal degrees or degrees-minutes-seconds format like `45°57'10.00"N 123°56'18.73"W`), or
   **Edit → Bulk Add Nodes by Coordinates** to extract multiple nodes from
   pasted text, logs, or coordinate lists using patterns or regular expressions.
   Coordinate entry centers a single new node and shows its coverage range;
   bulk entry fits the combined ranges of all nodes added in that batch.
5. Name the node, assign its system, set its height, and enter only the overrides
   that differ from the shared system.
6. Repeat for the remaining sites.

A **system** is the shared radio configuration; nodes inherit its values until
you enter a site-specific override. All systems in a RidgeCast network use that
network's single frequency. Start with values from the radio and antenna
datasheets: frequency in MHz, power in dBm, antenna gain in dBi, antenna height
above ground in metres, and losses in dB. If you do not yet have real equipment
values, use the tutorial's sample network to learn the workflow rather than
treating defaults as a deployable design.

If your sites already live in a spreadsheet, step 4 can do steps 4–6 at once.
Most scalar settings in the node editor have a `$tag`, so a pattern such as
`$name, $lat, $lon, $system, $antenna_height, $tx_power` imports configured
nodes rather than bare coordinates. You do not have to write the pattern by
hand: paste the rows, open the **Column Picker**, and it splits the data on its
separator and matches a header row to tags for you — adjust any column from its
dropdown and choose **Apply to Pattern**. The **Tag Picker** lists every tag
with its unit and accepted values, and inserts one at the cursor when clicked.
See [Bulk add tags](../reference/controls-and-shortcuts.md#bulk-add-tags) for
the full vocabulary and for the few settings that have no tag.
7. Select two nodes and inspect the provisional or calculated path before
   committing to long coverage or network-analysis runs.
8. Mark one or more central sites as **Backbone Hub** if you intend to use
   network-health analyses. A hub is the site or gateway the rest of the
   network is expected to reach.
9. Choose **File → Save** and select a JSON or YAML destination.

Use multi-selection and **Edit N nodes** to apply the same change to several
sites as one undoable operation. Use marker nodes for annotations that should
not participate in RF calculations. For a comprehensive walkthrough of antenna
overrides, directivity, tilt, range circles, and bulk editing, see
[Configure network nodes](configure-network-nodes.md).

**Control+Z** walks back any of it — node edits, system changes, the network
frequency, an import. See
[Undo and redo](../reference/controls-and-shortcuts.md#undo-and-redo) for what
the history covers and for the few operations that clear it.

## Save and recover your work

Choose **File → Save** (**Control+S**) to save to the current project file. The
first Save of an untitled network asks for a location. **Save As…**
(**Control+Shift+S**) asks for a different destination. The file chooser and
writing run in the background; wait for the save to finish before relying on
the file as your latest copy. Edits made while saving remain unsaved if they
were not in the snapshot being written.

The window title adds `*` when the document has unsaved changes. The status bar
shows **Unsaved changes**, **Saving…**, **Saved**, or **Save failed**; a new empty
network shows **Untitled**. Undoing edits back to the last saved content clears
the unsaved state. Calculated links alone do not count as an authored edit.
Selecting sites only views the network: the selection is saved with your next
save, but changing it counts as unsaved only when the selection now shown had
its coverage newly calculated rather than loaded from the coverage cache.

The next time you start RidgeCast it reopens the network you had open last,
taking the newest entry in **File → Recent Networks** that still exists on disk.
If that file has been moved or deleted, the next surviving entry is used; if it
exists but cannot be read, startup reports the error instead of quietly opening
a different network.

RidgeCast also writes separate per-document recovery snapshots in the
[recovery directory](../reference/files-and-formats.md#recovery-snapshots).
**Recovery saved** means a snapshot was written; the project still has unsaved
changes until you choose Save. Background recovery does not overwrite your
project file or create working-directory `network.json` and `network.yaml`.

After an interrupted session, **Recover Unsaved Work** lists retained snapshots
with their original file path, if any, and capture time. Choose **Recover** to
open a snapshot as unsaved work, inspect it, and Save or Save As to preserve it.
Recovery itself leaves the original project file unchanged. **Discard Recovery**
deletes that snapshot, and **Later** keeps it for another time. Reopen the list
with **File → Recover Unsaved Work…**. Recovery can lag the latest edit; check
the recovered content before discarding backups.

The same **Save / Don’t Save / Cancel** decision protects **Open Network…**,
**Recent Networks**, **Quit**, the window close button, update installation,
and imports that replace the document. Live node and system edits are included
in the check. Changes arriving during a save are checked again before continuing.
A failed load or canceled choice retains the current document. Closing waits
for pending persistence writes to finish; the status shows **Finishing saves…**.

Node-source imports download before replacing anything. In the result window,
choose **Use Imported Network** to accept the fetched nodes, then decide what
to do with the current document's unsaved work. Failed or empty imports keep
the current network. Canceling replacement also keeps it.

## Merge another RidgeCast network into this one

Choose **File → Import → Merge Network…** and pick a `.json`,
`.yaml`, or `.yml` network file. Its nodes are added to the network you already
have open, rather than replacing it.

A merge only ever adds:

- A node whose name is already in the open network is left out, so your version
  of a shared site is never overwritten. Rename either node and import again if
  you want both.
- Node identifiers are renumbered on the way in, so the two files cannot
  collide. Antenna azimuth locks follow the renumbering; a lock aimed at a node
  that was not imported is dropped, and that antenna falls back to its stored
  azimuth.
- System profiles the imported nodes use come along too. If the open network
  already has a different system under the same ID, the incoming one is added
  beside it as `<name> (imported)` and its nodes are pointed at that copy.
- The open network keeps its own operating frequency, color and Best Unit
  thresholds, and coverage defaults. The imported nodes are modeled on them,
  and the report says so when the incoming file planned on another frequency.

A report afterwards lists what was added, what was already present, and anything
that had to be renamed. Links are recalculated against this network's settings.
The whole merge is a single undo step.

If you edit the document while a merge is being prepared, RidgeCast retains
your edits and asks you to retry the import against the current network.

See [Nodes and systems](../reference/nodes-and-systems.md) for inheritance,
directional antennas, and node behavior, and
[Coordinate entry](../reference/controls-and-shortcuts.md#coordinate-entry)
for accepted coordinate formats and hemisphere rules.
