# Controls and shortcuts

## Map controls

| Action | Control |
| --- | --- |
| Select a node or amateur marker | Click it |
| Add an item to the selection | **Control-click** |
| Lasso-select | Hold **Control** and drag a freeform region |
| Append with the lasso | Hold **Control+Shift** and drag |
| Move a node | **Shift-drag** the node |
| Edit a node | Double-click the node |
| Clear the selection | Click empty map space |
| Replace selection with all non-hidden nodes, including offscreen nodes | **Control+A** |
| Replace selection with non-hidden nodes inside the map view | **Control+Shift+A** |
| Delete selected nodes | **Delete** or **Edit → Delete Selected Nodes** |
| Open a link profile | Select one node, then **Shift-click** another |
| Open a context menu | Right-click the map, a node, a link, or a Site Finder result |
| Open advanced search | **Control+F** |
| Undo the last network edit | **Control+Z** |
| Redo the last undone edit | **Control+Y** or **Control+Shift+Z** |

Menu shortcuts use **Command** on macOS instead of Control. Text fields keep
Delete, Select All, Undo, and Redo for text editing while focused. Search always
opens and focuses its input, including when the Search window is already open.
The menu bar does not provide native **Alt+letter** access keys; use the listed
command shortcuts or open menus with the pointer.

Deleting multiple nodes asks for confirmation. The confirmation applies to the
nodes captured when requested, even if selection changes, and becomes invalid
when another network replaces the document. Node deletion is undoable.

## Save and recovery controls

| Action | Control |
| --- | --- |
| Create an empty network | **File → New Network**, **Control+N** |
| Open a network, replacing the current document | **File → Open Network…**, **Control+O** |
| Save the current project; choose a location for an untitled document | **File → Save**, **Control+S** |
| Save to a different project file | **File → Save As…**, **Control+Shift+S** |
| Reopen the retained recovery-snapshot list | **File → Recover Unsaved Work…** |

The title's `*` and the persistent **Unsaved changes** status identify edits
that differ from the last saved content. The status changes to **Saving…** while
a save runs, **Saved** after the current content is saved, or **Save failed**
when it fails. A new empty document shows **Untitled**. **Recovery saved** and
**Recovery failed** report the independent recovery snapshot; recovery does not
make the project file current. Hover the status for the destination or error.

Before replacing or closing unsaved work, **Save** writes it and continues only
after success, **Don’t Save** continues without saving it, and **Cancel** keeps
it open. A canceled save-file chooser also keeps the document open. During
shutdown, **Finishing saves…** means pending persistence writes are being
drained. See [saving and recovery](../how-to/create-and-configure-a-network.md#save-and-recover-your-work).

Selecting two nodes that do not have a calculated network link draws a dashed,
terrain-aware provisional preview. It is visual guidance, not a persisted link
result.

## Selection behavior

- **Edit → Select All Non-Hidden Nodes** and **Select Non-Hidden Nodes in Map View**
  replace the selection and exclude hidden nodes. Visible disabled nodes remain
  selectable for editing; solvers ignore them.
- Coverage uses selected enabled, visible radio nodes. An empty selection clears
  coverage; use **Control+A** to evaluate all eligible nodes.
- Route and throughput analyses require exactly two selected nodes.
- **Simulate Selected Node Failure** requires one selected node.
- **Export Selected Nodes & Links Only** retains a link only when both endpoints
  are selected. It does not filter coverage or vector layers.

## Map tools

| Tool | Location | Purpose |
| --- | --- | --- |
| Add Node at Coordinates | **Edit → Add Node at Coordinates…** | Create a single node at specific latitude and longitude coordinates in decimal degrees or degrees-minutes-seconds (DMS) markup (e.g. `45°57'10.00"N 123°56'18.73"W`), with or without hemisphere indicators. |
| Bulk Add Nodes | **Edit → Bulk Add Nodes by Coordinates…** | Extract multiple fully configured nodes from pasted text, spreadsheets, or logs using [tag patterns](#bulk-add-tags) (e.g. `$lat, $long`) or regex. |
| Multi-Point Ruler | Empty map right-click context menu | Measure multi-point distances and view an interactive terrain elevation profile along the measured line (**Start Ruler Here**, **Add Ruler Point Here**, **Show Ruler Profile**, and **Clear Ruler**). Drag anchor points to adjust or double-click empty map space to extend. |
| Tile Manager Mode | **Tools → Tile Manager Mode** | Inspect, select, and remove cached terrain, land-cover, and surface tiles on the map. |
| Site Finder | **Analysis → Planning → Site Finder** | Rank candidate radio locations in the visible area. |
| Advanced Search | **Control+F** | Search locations, FCC records, coordinates, or RidgeCast nodes. |

Advanced Search separates **Location** fields from the **Node** field. Textual
location criteria and latitude/longitude are mutually exclusive. Callsign and
name searches use the local FCC amateur database; location-only searches use
the internal cache and U.S. Census geocoder.

The checked **Tile Manager Mode** command enters or leaves that mode. The map
header also provides an exit. **Analysis → Recalculate** offers **All Links**,
**Coverage for All Active Radio Nodes**, and **All Links and Coverage**. These
commands ignore selection; coverage includes enabled, non-hidden radio nodes.
Running calculations disable these commands with an explanation.

Settings groups distinguish scope. **Application Preferences** contains the
application-wide propagation model, units, directories, and cache controls.
**Current Network** groups frequency, fade-margin thresholds, and ambient noise;
these parameters are saved with the network and their edits can be undone.
**Data Sources**, owner colors, and **Work Offline** configure the application.

**Help → User Guide**, **Getting Started**, and **Glossary** open local bundled
documentation (or checkout documentation during development) in the default
viewer. **About RidgeCast** shows version and build information. Third-party
license information is linked from the repository README.

## Terrain overlay and water

Enable **Terrain overlay** in the map settings panel to shade the loaded terrain.
Oceans and lakes show the basemap through in every terrain style, including
contours. Water is identified from a bundled worldwide ocean/lake mask, refined
by cached NLCD land-cover classes where available. No extra downloads are needed.

Transparency uses water classification, not an elevation threshold: land below
sea level remains visible, and lakes above sea level are transparent. Elevations
used for links, coverage, and terrain profiles stay unchanged. Contours use
narrow elevation bands on varying terrain, preserving shading between levels
on steep slopes. A flat surface at a contour level is not filled black.

The global mask uses [Natural Earth's 1:10 million polygons](https://www.naturalearthdata.com/downloads/10m-physical-vectors/).
Its shorelines are generalized; small ponds, narrow rivers, and tiny islands may
be absent where finer cached land-cover data is unavailable. Newly loaded
land-cover data refreshes the terrain overlay automatically.

## Coordinate entry

**Add Node at Coordinates** accepts separate latitude and longitude values, or
a pair pasted into the Latitude field while Longitude is empty. The **Paste**
button also accepts pairs. Use a comma, semicolon, slash, newline, or space
between coordinates; a comma makes degrees/minutes/seconds pairs easier to read.

Adding a node centers the map on it and zooms to show its coverage evaluation
range, using the network's default range.

| Format | Example pair |
| --- | --- |
| Decimal degrees | `45.8383, -120.333` |
| Decimal degrees with hemispheres | `45.8383S, 120.333E` |
| Degrees and decimal minutes | `45°30.5'N, 120°15.5'W` |
| Degrees, minutes, seconds | `45°30'30"N, 120°15'30"W` |
| Colon or letter units | `45:30:30, -120d15m30s` |

Without hemisphere letters, enter latitude first, then longitude. `N`/`S`
identify latitude and `E`/`W` identify longitude, so a labelled pair can be
entered in either order, even if only one coordinate is labelled. Full names
such as `south` or `west` also work, before or after the value. Southern
latitudes and western longitudes become negative. An explicit sign must agree
with the hemisphere: `-45S` is valid; `-45N` and `+45S` are errors.

Uppercase `S` always means South. A lowercase `s` after three angular components
is a seconds unit, as in `45d30m30s`; use `S` or `south` to make that coordinate
southern. Unicode degree, prime, and minus (`−`) marks are accepted. Decimal clipboard pairs
can also be quoted, wrapped in brackets, or included in prose or JSON containing
exactly two numbers.

Latitude must be between −90 and 90, and longitude between −180 and 180.
Minutes and seconds must be less than 60 and cannot be negative. Only the last
component may include a decimal fraction. Invalid numbers, conflicting
hemispheres, and malformed angular values are rejected instead of being used
to place a node at an unintended location.

## Bulk add tags

**Edit → Bulk Add Nodes by Coordinates…** matches pasted text against a
pattern. A pattern is written with `$tag` placeholders, and most scalar settings
in the node editor have a tag, so one row of a spreadsheet can carry the main
site rather than only its coordinates.

`$lat` and `$long` (or `$lon`) are required. Each tag may be used **once** per
pattern; `$skip` is the exception and steps over columns you do not want.
Values that a row leaves out simply keep the node default.

Pattern compilation and input text scanning occur asynchronously on a background
worker with exact revision caching. A brief "Parsing coordinates…" status is displayed
while scanning large logs or datasets, during which the Add button remains disabled until
the latest inputs have been completely parsed and validated.

After adding a batch, the map fits the combined coverage evaluation ranges of
the nodes created in that operation. Each node uses its imported range override
or the network's default range. Existing nodes and the current selection do not
affect this automatic framing. A batch containing one node centers it on the map.

| Group | Tags |
| --- | --- |
| Position | `$lat`, `$long` |
| Identity | `$name`, `$shortname` |
| Classification | `$node_type`, `$marker_icon`, `$system`, `$enabled`, `$hidden`, `$backbone`, `$risk_group` |
| Radio | `$tx_power`, `$rx_sensitivity`, `$noise_figure`, `$noise_bandwidth`, `$noise_floor_mode`, `$equipment_id`, `$system_loss` |
| Antenna | `$antenna_gain`, `$antenna_height`, `$antenna_height_ft`, `$height_ref`, `$directional`, `$azimuth`, `$azimuth_target`, `$front_to_back`, `$tilt` |
| Coverage | `$range_km`, `$range_mi`, `$range_m`, `$resolution`, `$angular_resolution` |
| Structure | `$skip` |

Most tags accept aliases, so a pattern can be written with your own column
headings — `$latitude`, `$power`, `$gain`, `$height_ft`, and
`$antenna_height_agl` all work. Hover any tag in the picker for its unit, its
accepted values, and its aliases.

Notes on particular tags:

- `$system` accepts a system's name or its ID. A value matching no system is
  reported after the import rather than applied.
- `$azimuth_target` names a node to keep the antenna aimed at, and resolves
  against nodes already in the network as well as other nodes in the same
  import.
- `$antenna_height_ft` and `$range_mi` convert on import. Use them *instead of*
  their metric counterparts, not alongside them.
- `$risk_group` takes several failure domains separated by semicolons.
- Yes/no tags accept `true`/`false`, `yes`/`no`, `on`/`off`, `y`/`n`, `1`/`0`.

Three node settings have no tag, because they are structured rather than a
single value: **range circles**, **measured noise floors**, and the
**azimuth lock by node ID** (use `$azimuth_target` and name the node instead).
Set those with the node editor or with **Edit N nodes** after importing.

### Tag Picker and Column Picker

Two tools in the dialog build patterns for you:

- **Tag Picker** lists every tag, grouped and filterable, with a tooltip
  explaining the field, its unit, its accepted values, and its aliases.
  Clicking a tag inserts it at the cursor in the pattern box, adding a
  separator when appending. Tags already in the pattern are highlighted.
- **Column Picker** splits your pasted data on its separator — detected
  automatically, and overridable — and gives each column a dropdown of tags.
  A header row is recognized and its headings are matched to tags for you.
  **Apply to Pattern** writes the resulting pattern, using `$skip` for the
  columns you left unassigned. A header row is never imported, because it has
  no coordinates to match.

The dialog previews the nodes it will create, along with the values captured
for each one, before anything is added. The whole import is a single undo step.

## Undo and redo

**Edit → Undo** (**Control+Z**) and **Edit → Redo** (**Control+Y**) step through
everything stored in the network file. The history holds the last 200 steps.

Undo covers:

- Adding, duplicating, moving, editing, and deleting nodes, including bulk adds,
  bulk edits, bulk deletes, and hide/enable changes made from a context menu.
  Everything typed into one node's edit window is one step, however the window
  is closed.
- Nodes created from Advanced Search results and from selected FCC amateur
  licences. A whole licence selection is one step.
- Radio Systems Manager changes: adding, duplicating, deleting, and editing a system.
  One gesture is one step; the change is recorded when the pointer is released
  and no field has keyboard focus, which is also when the network is re-solved.
  Dirty status and recovery capture include live field edits before that gesture
  settles.
- **Network Frequency**, **Fade Margin Settings** thresholds (including the Best Unit threshold), and **Ambient Noise Settings** (in-band traffic seeds, adjacent-band desense, and population density blending).
- Importing Radio Mobile units or networks, and the choices made in the import
  collision dialog.
- Merging another RidgeCast network file into the open one with
  **File → Import → Merge Network…**. The whole merge is one step.
- Clearing per-node coverage ranges, and shrinking coverage to fit.
- Authored coverage selections/order, algorithm, TX/RX direction, merge mode,
  Test Node profile (including its range/resolution), land cover, angular
  resolution, threshold, patterns, blur, cluster size, opacity, and blend mode.
  Pointer drags produce one history step. Display-only changes redraw retained
  coverage without recalculating RF paths. Removing a selected node restores
  its coverage selection with the node when undone.
- Importing, relinking, removing, styling, or changing storage/visibility of
  vector layers.

Undo does not cross the operations that replace the whole document, because
there is no earlier state left to return to. Each warns first, and each clears
the history:

- **File → New Network** and opening a network file.
  New, Load, Recent, Quit, native window close, and update installation share
  **Save / Don’t Save / Cancel** protection, including text still being edited.
- Accepting a downloaded node-source network with **Use Imported Network**.
  **Import (Use Cache)** / **Import (Force Fresh)** fetch first and leave the
  current document intact until acceptance; failed or empty imports retain it.
- **Compact Now** in the node ID limit warning, which renumbers every node.

Analysis output — coverage overlays, Site Finder results, routes, exports — is
not part of the network file and is not undoable. Re-run the analysis instead.

## Appendix: Why the menus are arranged this way

The menu layout applies the principle of least surprise: start with the task
you want to accomplish, then choose the command whose label describes its
effect. Familiar categories, explicit scope, and opportunities to cancel help
reduce surprises. This rationale draws on Nielsen's principles of consistency,
recognition, user control, and error prevention. See
[Nielsen's usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/).

### Familiar categories, with a place for radio planning

RidgeCast uses the following order:

| Menu | The question it answers | Examples |
| --- | --- | --- |
| **File** | What document or external file am I working with? | New Network, Open Network…, Save, Import, Export |
| **Edit** | What network content or selection do I want to change? | Undo, Add Node at Coordinates…, Radio Systems Manager, Delete Selected Nodes |
| **View** | How do I want to see or frame the network? | Link coloring, node labels, Connection Weakness Overlay, Fit to Visible Coverage |
| **Analysis** | What calculation or planning study do I want to run? | Recalculate, Network Health, Routes, Failure & Service Impact, Planning |
| **Settings** | What assumptions, sources, or preferences should apply? | Network Frequency…, Ambient Noise Settings, Application Preferences, Work Offline |
| **Tools** | What supporting data operation or working mode do I need? | Prepare Data for Offline Calculations…, FCC Amateur Licenses, Tile Manager Mode |
| **Help** | Where can I learn more or identify this installation? | User Guide, Getting Started, Glossary, About RidgeCast |

File, Edit, View, and Help provide familiar anchors; Analysis gives radio
planning its own home. Microsoft's classic menu guidance recommends standard
document menus while allowing categories based on an application's tasks.
That guide was written for Windows 7 and is historical guidance, rather than
a specification for current Windows or every platform. See
[Microsoft's menu organization guidance](https://learn.microsoft.com/en-us/windows/win32/uxguide/cmd-menus#standard-menus).

The boundaries follow the user's intent, rather than whether the implementation
does calculations:

- **View versus Analysis:** **View → Node Colors → Site Score (All Nodes)**
  colors existing sites by a score; **Analysis → Planning → Site Finder**
  searches for candidate locations. Displaying a score can require computation,
  but its purpose is to interpret the map. A planning search asks for a new study.
- **Settings versus Analysis:** **Settings → Network Frequency…** changes a
  saved network assumption; **Analysis → Recalculate → All Links** requests a
  solve. Changing an assumption can also trigger recalculation. Settings is not
  restricted to cosmetic or application-wide preferences: its **Current Network**
  group identifies network parameters separately from application preferences.
- **Settings versus File versus Tools:** register a local terrain source in
  Settings, import or export a file through File, and prepare cached requirements
  through Tools. **Prepare Data for Offline Calculations…** checks the needs of
  selected tasks; it is not a general command to download an arbitrary map area.

### Grouping keeps related choices together

New, Open, Save, and Save As are directly available in File. Format-specific
commands live in Import and Export submenus. Undo and Redo come first in Edit.
Analysis groups commands by the question being studied, such as routes or
failure impact. Separators distinguish groups without adding another menu level.
These choices apply Microsoft's recommendations to group related commands and
keep frequent commands out of unnecessary submenus. See
[Microsoft's menu guidelines](https://learn.microsoft.com/en-us/windows/win32/uxguide/cmd-menus#guidelines).

For example, **File → Open Network…** replaces the current document after
handling unsaved work; **File → Import → Merge Network…** adds content to it.
Their different locations and verbs distinguish two operations that both read
a RidgeCast network file. Likewise, **Legacy Site List…** imports node locations,
not a coverage result.

The menu bar exposes commands for the application as a whole. Map context menus
provide actions at the clicked node or location. This distinction follows the
modern Windows guidance that a context menu attaches secondary commands to a
particular element. See [Microsoft's menus and context menus guidance](https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/menus-and-context-menus).

### Labels explain scope and what happens next

Scope matters more than brevity when similar commands affect different nodes.
**Select All Non-Hidden Nodes** includes offscreen nodes; **Select Non-Hidden
Nodes in Map View** is restricted to the viewport. Both allow disabled nodes to
be selected for editing. **Coverage for All Active Radio Nodes** instead targets
enabled, non-hidden radio nodes regardless of selection. See
[selection behavior](#selection-behavior).

Domain terms remain available alongside explanations: **Long and Strong
(Fortuity)** describes the link-coloring idea before naming the metric, while
**Single-Node Failure Sweep (N-1)** describes the study before its shorthand.
**Connection Weakness Overlay** highlights nodes with few or weak incoming and
outgoing links. For topology bottlenecks, use **Analysis → Network Health →
Critical Nodes / Articulation Points**; for a failure scenario, use
**Analysis → Failure & Service Impact**.

An ellipsis normally signals that a command needs further choices. **Save As…**
asks for a destination; **Best 5 Routes…** opens the route-objective choices.
**Best Route** runs with the current assumptions. **About RidgeCast** needs no
ellipsis just because it opens a window, and submenu arrows already indicate
another choice. This convention comes from
[Microsoft's guidance on ellipses](https://learn.microsoft.com/en-us/windows/win32/uxguide/cmd-menus#using-ellipses).
It is a useful cue, not an absolute promise: **Save** may ask for a first filename,
and **Delete Selected Nodes** asks for confirmation when several nodes are selected.

### Stable commands and reversible actions

Commands with unmet prerequisites stay in place with an explanation on hover.
For example, route commands require exactly two selected nodes, and
**Links to CSV…** requires calculated links. Keeping unavailable commands visible preserves their location
and makes prerequisites discoverable. Independent switches, such as **Tile
Manager Mode**, use a checkmark; **Normal Network View** and **Connection
Weakness Overlay** are mutually exclusive choices. These follow
[Microsoft's guidance on menu states](https://learn.microsoft.com/en-us/windows/win32/uxguide/cmd-menus#guidelines).

Actions that could lose authored work have an escape route: document replacement
offers **Save / Don't Save / Cancel**, multiple-node deletion offers confirmation,
and network edits can be undone. These protections apply Nielsen's user-control
and error-prevention principles; see [the usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/),
[save and recovery](#save-and-recovery-controls), and [undo and redo](#undo-and-redo).

Keyboard shortcuts provide another route to common actions. Command replaces
Ctrl on macOS, and editing keys belong to a focused text field while typing.
RidgeCast uses a shared in-window menu bar: those shortcut substitutions do not
make it a native macOS menu layout. Native **Alt+letter** menu access keys are
also unavailable. The layout therefore adopts desktop conventions selectively;
the controls documented above describe the behavior you can rely on.
