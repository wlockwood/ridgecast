# Plan your first network

This tutorial requires a running source build and the sample Radio Mobile files
in the RidgeCast source checkout; the sample is not built into the application.
We will import those files, inspect a terrain-aware link, draw a coverage map,
and run a basic network-health analysis.
The result is a small working project that introduces the main RidgeCast
workflow without requiring you to design a network first.

Allow about 20 minutes after the application is built and running. The source
build itself can take longer and needs the prerequisites in the install guide.
Downloads can make the first
propagation calculation longer; repeating it is normally much faster because the
data is cached.

## Before we begin

You need a desktop graphics session and a RidgeCast build. If the application is
not running yet, follow [Install and run RidgeCast from source](../how-to/install-and-run.md),
then return here.

If `example-rm-imports/` is missing, download the source checkout before
continuing. Keep its three `maplenet_*.csv` files together.

Keep internet access enabled for this first run. RidgeCast may need terrain,
land-cover, basemap, or LiDAR data for the sample area.

## 1. Import the sample network

1. Choose **File → Import → Radio Mobile Units (CSV)…**.
2. Open `example-rm-imports/maplenet_Unit.csv` from the RidgeCast repository.
3. Choose **View → Fit to Active Nodes**.

You should now see several named nodes on the map. If none appear, check that you
selected `maplenet_Unit.csv` and that the three sample files are together.
RidgeCast found the matching
`_System.csv` and `_NetData.csv` files beside the selected file and imported them
as one network. It also starts calculating the imported network's directed links
in the background; the later network-health step uses those saved calculations.

If RidgeCast reports missing files, confirm that the three `maplenet_*.csv`
files remain together in `example-rm-imports/`.

## 2. Inspect a link

1. Click one node.
2. Hold **Shift** and click a second node.
3. Open the link profile from the map or its context menu if it is not already
   visible.

The profile should show the ground between the two sites, the radio path, and
Fresnel clearance. The map may temporarily label work as **Queued**,
**Fetching terrain**, **Fetching LiDAR**, or **Calculating**.

Open the **Downloads** or **Calculation Progress** window if you want to see
which stage is active. Wait until the link result replaces the provisional
dashed preview.

If the link stays queued or reports a failure, check **Calculation Progress**
and [Troubleshoot RidgeCast](../how-to/troubleshoot.md) before continuing.
Measured LiDAR surfaces are optional; the **Fetching LiDAR** stage appears only
when they are enabled and data is needed.

Notice that a link is directional: the two directions can have different fade
margins when the radios, antennas, or noise floors differ.

## 3. Draw coverage

1. Click empty map space to clear the selection, then select one radio node.
2. In the right-hand settings panel, open **Coverage** and choose the **Draft** preset.
3. Leave the algorithm at **Vertex Grid**, the direction at **TX**, and
   the display mode at **Strongest signal / fade margin**. The default **Test Node** represents
   a low-power handheld: this TX map asks where that hypothetical handheld can
   hear the selected site. For a different receiver, change **Coverage → Edit test radio** before judging the result.
4. Wait for the coverage overlay to appear.

You should see colored cells around the selected site. If none appear, check
**Calculation Progress** for unfinished or failed work, then check the selected
node, coverage range, and **Edit test radio** in the right-hand panel.
The completion summary
reports the elapsed time and number of evaluated cells. Selecting the same node
again with unchanged settings should reuse its persistent coverage cache.

The colors grade fade margin, not raw signal power. See
[Coverage maps](../concepts/coverage.md) when you are ready to understand the
Test Node, merge modes, and algorithms in detail.

## 4. Check network health

1. Double-click a node that should act as the network center.
2. Enable **Backbone Hub**, then save the edit.
3. Make sure at least two radio nodes are enabled and their background link
   calculations have finished. Open **Downloads** or **Calculation Progress**
   to check; after importing the sample, the application calculates links for
   the whole imported network, not just the pair from step 2.
4. Choose **Analysis → Network Health → Backbone Connectivity**.

The **Analysis Results** window should classify nodes as two-way,
downlink-only, uplink-only, or disconnected and show their hop distance from a
backbone hub. The result also records the assumptions used for the analysis.

## 5. Save the project

Choose **File → Save As…** and save the network in a dedicated project
directory. **Save As…** writes the chosen file but does not change the
application's working directory, where its default `network.json` and other
project settings are also saved. For later sessions, open a terminal in that
project directory and run
`cargo run --release --manifest-path /path/to/ridgecast/Cargo.toml`, replacing
the path with the source checkout's `Cargo.toml`. This starts RidgeCast with the
project directory as its working directory, so its default `network.json` and
project configuration files stay with this project. The chosen network file
contains nodes, systems, links, and the coverage selection and settings; local
download and calculation caches remain in this installation. Use **File → Open Network…**
to reopen the saved file; loading it alone does not move the working directory.

For example, save `first-network.yaml` in a folder named `Radio Projects/First
Network`. That file can be reopened by name; it does not have to be called
`network.json`. The saved network contains the coverage settings used here.
Keep adjacent configuration files as well when preserving data-source settings
or window layout; see [Files and interchange formats](../reference/files-and-formats.md).

You have now completed RidgeCast's basic working loop: load or place sites,
calculate links, inspect coverage, analyze the network, and save the result.

## Continue from here

- [Generate and export a coverage map](../how-to/generate-and-export-coverage.md)
- [Find and validate a candidate site](../how-to/find-and-validate-a-site.md)
- [Analyze network resilience](../how-to/analyze-network-resilience.md)
- For coverage-weighted failure-impact analyses, select multiple radio nodes
  and recalculate in **Best Unit** mode so each cell records its serving sites.
  A one-node coverage image can show population in its whole-image stats card
  without Best Unit; see [Coverage modes](../reference/coverage-modes.md).
- [Create and configure your own network](../how-to/create-and-configure-a-network.md)
- [Controls and shortcuts](../reference/controls-and-shortcuts.md)
