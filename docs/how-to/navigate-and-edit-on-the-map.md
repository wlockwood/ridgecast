# Navigate and edit on the map

The main viewport is RidgeCast's primary interactive canvas for inspecting
terrain, arranging radio sites, analyzing microwave and VHF/UHF paths, exploring
predicted signal coverage, and taking physical measurements. Use pointer gestures
and keyboard shortcuts to navigate and edit your network efficiently.

## Quick start

1. **Pan and zoom**: Click and drag empty map space with the primary mouse button
   to pan. Roll the mouse wheel to zoom toward the pointer.
2. **Select a node**: Click any node to select it. Click empty map space to clear
   the selection.
3. **Multi-select nodes**: Hold **Control** and click multiple nodes (or FCC
   amateur markers) to add or remove them from the active selection.
4. **Lasso-select**: Hold **Control** and drag a freehand polygon across the map
   to select all enclosed nodes and markers. Hold **Control+Shift** and drag to
   append to the existing selection.
5. **Move a node**: Hold **Shift** and drag a node to reposition it. A live
   hexagonal preview tracks the node as you drag; releasing the mouse button
   commits the move and updates dependent links and coverage.
6. **Edit site settings**: Double-click a node (or click an already-selected
   single node) to open the Node Editor dialog.
7. **Inspect link profiles**: Select one node, then **Shift-click** another to
   display a provisional path preview. Right-click any link or provisional path
   and choose **Show Link Profile** to open an interactive 2D elevation
   cross-section with Fresnel zones and clearance metrics.
8. **Measure distances**: Right-click empty map space and choose **Start Ruler
   Here** to measure multi-point routes and view elevation profiles.
9. **Companion Guide**: Click **Guide** in the map header toolbar (beside
   **Layers** and **Fit**) or choose **Help → Main Viewport Guide** for
   secondary, nonmodal assistance.

## Navigation and framing

| Action | Gesture or shortcut |
| --- | --- |
| Pan across the terrain | Drag empty map space with the primary (left) mouse button |
| Zoom in or out | Roll the mouse wheel over the target location |
| Fit all active network nodes | **Fit → Fit to Active Nodes** in the map header, or **View → Fit to Active Nodes** |
| Fit coverage evaluation range | **Fit → Fit to Evaluation Range** in the map header, or **View → Fit to Evaluation Range** |
| Fit visible coverage cells | **Fit → Fit to Visible Coverage** in the map header, or **View → Fit to Visible Coverage** |
| Center map on a site | Double-click the site's row in the **Network** list panel |

The **Fit** menu in the top-left map toolbar provides quick framing options.
Fitting active nodes includes all enabled, visible radio nodes (falling back to
all nodes if none are active). Fitting evaluation range frames the calculated
downlink footprint of selected sites, and fitting visible coverage frames only the
hexels or radial sectors currently visible above the fade-margin display thresholds.

## Selection and multi-selection

RidgeCast supports both point-and-click selection and freeform polygonal lasso
selection.

| Action | Control |
| --- | --- |
| Select a single node or marker | Click it |
| Toggle item in/out of selection | Hold **Control** and click the node or amateur marker |
| Freeform lasso selection | Hold **Control** and drag the primary mouse button across the map |
| Append with freeform lasso | Hold **Control+Shift** and drag the primary mouse button |
| Select all non-hidden nodes | **Control+A** or **Edit → Select All Non-Hidden Nodes** |
| Select visible non-hidden nodes | **Control+Shift+A** or **Edit → Select Non-Hidden Nodes in Map View** |
| Clear selection | Click empty map space |

### Lasso selection

Lasso selection lets you quickly gather a cluster of sites without individually
clicking each one:

1. Press and hold **Control** (or **Command** on macOS).
2. Click and hold the primary mouse button on an open area of the map.
3. Drag the cursor in a freeform loop around the nodes or FCC amateur stations
   you wish to select. A semi-transparent cyan boundary visualizes the selection
   polygon as you draw.
4. Release the mouse button. All non-hidden nodes and markers within the polygon
   become selected, replacing any previous selection.
5. To **add** more nodes to an already selected set, hold **Control+Shift**
   before dragging the lasso.

## Moving and editing nodes

| Action | Control |
| --- | --- |
| Move / reposition a node | Hold **Shift** and drag the node with the primary mouse button |
| Open Node Editor dialog | Double-click the node, or click an already selected single node |
| Delete selected nodes | Press **Delete** or choose **Edit → Delete Selected Nodes** |
| Undo last node move or edit | Press **Control+Z** or choose **Edit → Undo** |
| Redo last undone edit | Press **Control+Y** or **Control+Shift+Z**, or choose **Edit → Redo** |

### Shift-dragging nodes

When you hold **Shift** and drag a node:
- Normal map panning is suspended.
- As the cursor moves across the map, a live coverage preview indicates the
  current hexagonal grid cell under evaluation.
- When you release the mouse button, the node is dropped at its new geographic
  coordinates. Connected links, path elevations, and coverage overlays
  recalculate automatically.
- If the move was accidental, press **Control+Z** to immediately restore the
  node to its original position.

Deleting multiple nodes presents a confirmation prompt showing the exact count
of affected sites. Deletions are fully recorded in the undo stack.

## Link profiles and provisional paths

| Action | Control |
| --- | --- |
| Select a link | Click the link line |
| Provisional link preview | Select one node, then **Shift-click** another node |
| Open 2D Link Profile | Right-click the link line and choose **Show Link Profile** |

Selecting two nodes that do not share an established network link renders a
dashed, terrain-aware provisional path preview between them. Right-clicking the
provisional line and selecting **Show Link Profile** opens the interactive 2D path
profile window, displaying bare-earth DEM elevation, surface/canopy clutter,
direct line-of-sight rays, and the 1st Fresnel zone clearance ellipse across the
entire terrain profile.

## Multi-Point Ruler

The Multi-Point Ruler allows measuring complex multi-leg paths and inspecting
ground elevation along real-world traversal routes:

1. **Start measuring**: Right-click empty map space and choose **Start Ruler Here**.
2. **Add points**: Click anywhere on the map to place subsequent waypoints, or
   right-click and choose **Add Ruler Point Here**. Double-clicking empty map
   space also extends the ruler line.
3. **Adjust waypoints**: Drag any round waypoint anchor to fine-tune its position.
4. **Read distance**: The cumulative path distance is displayed beside the final
   waypoint in your configured display units (miles or kilometers).
5. **Inspect terrain profile**: Right-click empty map space and choose **Show
   Ruler Profile** to open an interactive 2D terrain elevation cross-section
   following the ruler's exact path.
6. **Clear the ruler**: Right-click empty space and choose **Clear Ruler** to
   remove all points and close the ruler profile window.

## Context menus

Right-clicking elements in the main viewport provides targeted actions:

### Empty map space
- **Start Ruler Here / Add Ruler Point Here**: Initiate or extend a multi-point
  measurement path.
- **Show Ruler Profile**: Open the 2D elevation cross-section along the ruler
  route (available when at least two ruler points exist).
- **Clear Ruler**: Remove all active ruler waypoints.
- **Add Node Here**: Create a new radio node at the clicked geographic coordinate.
- **Add Marker Here**: Place an informational visual annotation marker.
- **Copy Lat/Long**: Copy the clicked decimal degree coordinates to the clipboard.
- **Details at Point**: Submenu displaying the exact latitude, longitude, DEM
  bare-earth elevation, LiDAR surface/canopy height (when available), and
  land-cover classification.

### Node
- **Edit Node**: Open the comprehensive site parameters dialog.
- **Delete Node**: Remove the node from the network (undoable).
- **Set as Center**: Designate the node as the central hub for Star and Tree
  topologies and hop-distance analysis.
- **Duplicate Node**: Create a copy of the site at the same location.

### Link
- **Show Link Profile**: Open the 2D path profile dialog showing terrain
  obstructions, Fresnel zone clearance, and propagation loss breakdown.

### Site Finder candidate cell
- **Copy evaluated site coordinates**: Copy the exact transmitter coordinate
  evaluated during the scan.
- **Review node at evaluated origin…**: Open Site Finder to confirm candidate
  parameters and create a permanent network node.
- **Subdivide and Scan**: Trigger a 7-candidate sub-hex refinement scan around the
  selected candidate cell.

## Layers and appearance

The **Layers** button in the map header toggles the Layers drawer, which controls
how geospatial data and coverage results appear:

- **Basemap**: Select **Road** (OpenStreetMap), **Satellite**, or **Blank**
  canvas.
- **Terrain overlay**: Enable hillshading, slope visualization, and elevation
  contours (with configurable contour intervals from 10 m to 500 m).
- **Regional water**: Toggle detailed vector water bodies (lakes, rivers,
  reservoirs) and shoreline transparency smoothing.
- **Land cover & Clutter**: Visualize global land-cover classifications and
  clutter heights.
- **Coverage appearance**: Configure fade-margin color bands, blur smoothing,
  small-cluster speckle filtering, opacity, and blend modes (Normal, Multiply,
  Screen, Overlay).
- **Amateur radio**: Toggle FCC amateur station markers, callsign labels, and
  marker coloring (by license class, Site Finder score, or link count).
- **Drawer docking**: Click **Pin** in the Layers drawer header to reserve
  dedicated space beside the map, or **Unpin** to let it float.

## Tile Manager Mode

When **Tile Manager Mode** is active (via **Tools → Tile Manager Mode** or the
header button):
- Pointer interactions are redirected to managing cached terrain, land cover,
  and surface raster tiles.
- Node dragging and ordinary node selection are suspended so that clicking or
  dragging interacts exclusively with tile bounding boxes.
- Click or lasso-select tiles to inspect cache size or prune cached files from
  local disk.
- Exit Tile Manager Mode via the map header banner or menu item to restore normal
  node navigation and editing.

## Companion Guide

The **Main Viewport Guide** provides secondary, nonmodal help that floats over
the workspace:

- **Opening**: Click **Guide** in the map header toolbar (next to **Layers** and
  **Fit**), or choose **Help → Main Viewport Guide** or **View → Main Viewport
  Guide**.
- **Dismissing**: Click **Close** or **Dismiss guide**, or press **Escape** while
  interacting with the guide window. The guide dismisses without interrupting
  your work on the map.
- **Auto-show preference**: Toggle **Show guide when the map opens** at the
  bottom of the guide window. When enabled, the guide opens automatically whenever
  RidgeCast launches; turning it off preserves the setting while keeping the
  **Guide** button available whenever you need a quick reminder.
