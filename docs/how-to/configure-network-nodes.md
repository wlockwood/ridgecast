# Configure network nodes

Use this guide to configure radio equipment, antenna height and patterns, coverage range, network roles, and visual range circles for individual sites or across bulk selections in RidgeCast.

## Overview

In RidgeCast, each radio node represents a transmitter, repeater, gateway, or client terminal placed on the map. Nodes inherit their baseline radio parameters from a shared [Radio System Profile](../reference/nodes-and-systems.md#systems), but can specify site-specific overrides for antenna height, transmit power, receiver sensitivity, antenna gain, radiation patterns, or coverage limits without altering the shared system.

You can edit nodes in two modes:
- **Single Node Editor**: Opens when double-clicking a node on the map, right-clicking and choosing **Edit Node**, or selecting a single node and choosing **Edit selected…** in the Network panel. Edits write through live to the active mesh and coalesce into a single undoable step when the window closes.
- **Bulk Node Editor**: Opens when two or more nodes are selected and you choose **Edit selected…** or pick **Edit** from the node context menu. Each property is gated by an **Apply** checkbox so only desired properties are changed across the selection, leaving other settings untouched.

Both editor windows include an integrated **Companion Guide** button that opens nonmodal, step-by-step guidance alongside the editor.

---

## Open the Node Editor

| Method | Action | Target |
| --- | --- | --- |
| **Double-Click** | Double-click any node on the map | Opens Single Node Editor |
| **Context Menu** | Right-click a node on the map → **Edit Node** | Opens Single Node Editor (or Bulk Editor if multiple selected) |
| **Network Panel** | Select site(s) in right panel → Click **Edit selected…** | Opens Single or Bulk Node Editor |
| **Menu Bar** | Choose **Edit → Node Editor Guide** or **Help → Node Editor Guide** | Opens editor for selection and displays Companion Guide |

---

## Single Node Editor

### 1. Identity, naming, and roles

- **Name**: The full descriptive name of the station or site (e.g., `Lookout Mountain Repeater`).
- **Shortname**: A compact abbreviation displayed on map labels and compact diagrams. Leave blank to automatically generate a shortname from the name according to project rules, or type a custom shortname. If an abbreviation exceeds the project's target length, a character count warning indicates the excess.
- **Enabled**: When checked, the node participates in RF link budget calculations, best-path analysis, and coverage overlays. Uncheck to temporarily take the station offline without removing it from the network.
- **Hidden**: Suppresses the node from the map viewport and coverage rendering. Hidden nodes remain in the network list.
- **Node Role**:
  - **Repeater**: Central relay station capable of linking to other repeaters, gateways, and user terminals.
  - **User**: Subscriber or client station. User nodes link only to Repeaters, never directly to other User nodes.
  - **Gateway**: Ingress/egress bridge linking the radio network to external infrastructure.
  - **Marker**: Non-RF map annotation. Markers do not calculate links or evaluate coverage. Choose from several visual icons including **Pin**, **Tower**, **Vehicle**, **House**, **Flag**, or **Star**.

### 2. Coordinates and clipboard exchange

- **Latitude & Longitude**: Decimal degree coordinates with interactive drag controls (0.0001° steps).
- **Copy**: Copies current coordinates formatted as `latitude, longitude` to the system clipboard.
- **Paste**: Reads coordinates from the system clipboard. Accepts decimal degrees (`45.95278, -123.93854`) or degrees-minutes-seconds (`45°57'10.00"N 123°56'18.73"W`).

### 3. System profile inheritance vs. site overrides

Nodes inherit radio parameters from their assigned **System Profile**:
- **System Profile**: Choose an existing network system or a built-in profile (e.g., *Basic - Single-Story*, *Moderate - Second Story*, *Tower*, *Pocket Node*). Selecting a built-in automatically materializes an editable copy in your network document.
- **Transmit Power (TX Power)**: Check **Override** to set site-specific transmitter output power in dBm (0 to 50 dBm). The editor calculates and displays the equivalent wattage or milliwatts live.
- **Receiver Sensitivity (RX Sensitivity)**: Check **Override** to set minimum received power in dBm (-120 to 0 dBm) required for successful reception.
- **Antenna Gain**: Check **Override** to configure peak antenna gain in isotropic decibels (0 to 30 dBi).

### 4. Antenna height, reference datum, and tilt

- **Antenna Height**: Check **Override** to specify mast height (1 to 100 m, or feet depending on display units).
- **Measured from (Height Reference Datum)**:
  - **Ground (AGL)**: Height above bare-earth terrain.
  - **Surface**: Height above ground plus clutter/canopy models or surveyed DSM surfaces (e.g., mounted on a rooftop).
  - *Note*: The height reference datum has its own independent override checkbox. A site can inherit the system mast height while pinning its datum to Ground or Surface.
- **Antenna Tilt**: Mechanical or electrical elevation angle from -90° (downward tilt) to +90° (upward tilt), ideal for summit repeaters serving valleys.
- **Antenna Vertical Response**: Displays vertical radiation pattern curves and elevation angle attenuation.

### 5. Directional antennas and target aiming

- **Antenna Pattern**: Check **Override** to toggle between omnidirectional and directional antenna patterns:
  - **Azimuth**: Compass bearing in degrees (0–359°) indicating beam direction.
  - **Aim Target**: Dropdown listing all other network nodes. Choosing a target automatically computes and continuously tracks the exact great-circle bearing from this station to the target site.
  - **Front-to-Back Ratio**: Ratio in dB (0 to 40 dB) between main lobe gain and reverse radiation.

### 6. Analysis and network health

- **Backbone Hub**: Marks this station as a primary root or hub for connectivity analysis, routing trees, and reachability metrics.
- **Risk Groups**: Comma-separated list of common failure domains (e.g., `Grid-A, Mount-Hood-Tower`). Nodes sharing a risk group are modeled as failing together during resilience and single-point-of-failure analyses.

### 7. Coverage limits and concentric range circles

- **Coverage Range**: Check **Override** to set a custom maximum evaluation distance (100 m to 500 km) for this node, overriding the global network setting.
- **Range Circles**: Draw concentric distance rings on the map centered on this station:
  - **Spacing**: Distance between successive concentric rings.
  - **Max Distance**: Radius of the outermost range circle.
  - **Distance Labels**: Display readouts in **Kilometers**, **Miles**, or **Nautical Miles**, or select **None** for unlabelled rings.
  - **Text Size**: Font size for viewport distance readouts.
  - **Line Weight & Outline Weight**: Pixel widths for ring strokes and contrasting outlines.
  - **Circle Color & Outline Color**: RGBA color pickers with opacity/transparency controls.

### 8. Removing a node

- Click **Remove Node** at the bottom of the editor to permanently delete the station and all attached links. This action is fully undoable with **Control+Z**.

---

## Bulk Node Editor

When multiple nodes are selected, the Bulk Node Editor lets you batch-modify parameters across every chosen station in a single operation.

1. **Selection**: Select multiple nodes by Control-clicking, dragging a lasso with Control-drag, or using **Control+A**.
2. **Apply Checkboxes**: Every setting row features an individual **Apply** checkbox:
   - Only rows with **Apply checked** are written to the selected nodes.
   - Unchecked rows are left untouched on each node, preserving heterogeneous values across the network.
3. **Mixed Value Indicators**: When selected nodes have differing values for a setting, a `(mixed)` indicator appears. Checking **Apply** will overwrite all nodes with the value you select.
4. **Batch Commit**: Click **Apply** at the bottom to commit all changes across all selected nodes as a single atomic undoable command (`MultipleNodesEdited`). Click **Cancel** or close the window to discard pending edits.

---

## In-App Companion Guide

RidgeCast includes an interactive **Companion Guide** built into the Node Editor:

1. Click the **Guide** button in the header of the Single Node Editor or Bulk Node Editor.
2. The nonmodal guide window opens alongside the editor, detailing each step of the configuration process, equipment inheritance rules, and calculation impacts.
3. Check **Show guide when the node editor opens** in the guide footer to automatically display guidance whenever you open an editor window.
4. Click **Configure network nodes** at the bottom of the guide to open this comprehensive offline documentation in your system viewer.

---

## Background execution and undo safety

- **Non-blocking recalculation**: Modifying RF properties (power, frequency, antenna height, or directivity) automatically triggers background propagation and link recalculation off the UI thread without freezing map navigation.
- **Coalesced Undo**: Changes made throughout a Single Node Editor session coalesce into a single undo step when the editor closes. Press **Control+Z** to revert all edits from that session, or **Control+Y** (**Control+Shift+Z**) to redo.
