# Map views

View controls change how existing results are presented; they do not modify the
underlying network.

## Link display

| Mode | Meaning |
| --- | --- |
| **Fade Margin** | Colors links by the configured fade-margin quality bands. |
| **Distance** | Colors links by path length. |
| **Long and Strong (Fortuity)** | Emphasizes links that are both long and strong: distance normalized to 50 km multiplied by SNR normalized to 30 dB, with each factor clamped to 0–1. |
| **Hidden** | Hides link lines without deleting links. |

## Node labels and colors

| Control | Choices or effect |
| --- | --- |
| **View → Node Labels** | **Full Names**, **Short Names**, or **Icon Only** |
| **View → Node Colors** | **Connectivity Health**, **Site Score (All Nodes)**, **Site Score (Visible Nodes)**, **Site Score (Population Weighted)**, or **Hop Distance from Selected Node** |
| Best Unit / Unique Coverage | Uses coverage-owner colors while those coverage modes are active and disables conflicting icon-color choices. |
| **View → Independent Paths for Two Selected Nodes** | With exactly two nodes selected, draws up to three routes between them that share no intermediate node. See [Independent paths](#independent-paths). |

**Hop Distance** uses the fewest viable directed hops from the one selected
node. The source is white, reachable nodes use the relative hop-count palette,
and unreachable nodes are dark gray. After a selection, threshold, or network
change, the map shows **Updating hop distances…** while the new colors are
calculated in the background. During that update, other enabled nodes are
neutral gray; colors from the previous selection are not shown.

**Connectivity Health** colors nodes by their relative number of viable links.
With one node selected, other nodes use the existing multipath reliability
estimate from that source; the selected node keeps its link-count color.
After relevant network, selection, or threshold changes, enabled nodes are
neutral gray with **Updating connectivity colors…** until the new colors are
ready. Changing the node-list sort order does not recalculate these colors.

How the Connectivity Health color is computed:

- **Link count.** Each enabled, visible node is scored by the number of links
  with SNR at or above the global SNR threshold that touch it, counting both
  directions (a link between two nodes counts once for each end, a self-link
  once). The count is mapped to 0..1 across the lowest and highest counts among
  those nodes; if every node has the same count, or there are none, the range is
  widened by one so a flat network is colored uniformly at the red end rather
  than failing.
- **Reliability** (one node selected). For each other enabled, visible node, the
  estimate finds up to three disjoint routes from the selected node and
  treats each hop as succeeding with probability `SNR / 20 dB`, clamped to
  0..1, so a link at 20 dB or better counts as certain and a link at or below 0 dB
  as failing. A route's probability is the product of its hops, and the node's
  reliability is `1 - (product of each route's failure probability)`. Colors
  then map the lowest-to-highest reliability among the nodes, not 0 to 1, so
  the weakest node is red and the strongest green even when all are reliable;
  a flat set gets a small minimum span. The selected node itself has no
  reliability value and keeps its link-count color, as does any node without one.
- **Scale.** 0 is red, 0.5 yellow and 1 green. This is a relative display, not an
  absolute rating: the same node can change color when another node is added.

**Coverage Owner Colors**, available under **View → Node Colors** and **Settings**,
edits the shared owner palette and opacity over the basemap for Best Unit and
Unique Coverage. It stays available in every mode; edits apply when an owner
mode is displayed. These are application display preferences, saved separately
from the network. Site Score entries color existing nodes; start a scan through
**Analysis → Planning → Site Finder**.

Short names use a node's custom shortname when one is set. Otherwise, RidgeCast
shortens its name to the **Target Shortname Length** in Settings. Names that fit
stay unchanged. Spaces between words go first, then approved abbreviations
such as `Mountain` → `Mtn`. Numbers, call signs, `Alt` and directions are never
altered. If a name still doesn't fit, the closest version is shown unless you
choose a **Shortname Fallback**. See [Shortnames](shortnames.md) for the full
rules, the place-alias region, and where the abbreviations come from.

## Independent paths

The independent-paths overlay draws up to three routes between two nodes that
share no intermediate node: the best route as a solid yellow line, then up to two
alternates as dimmer dashed cyan and green lines. Each later route avoids every
relay the earlier ones used, so the overlay shows at a glance whether the pair
has backup routing or depends on one relay.

- **Follow the selection:** **View → Independent Paths for Two Selected Nodes**
  shows routes whenever exactly two nodes are selected. The node you selected
  first is the source.
- **Pin a pair:** right-click a selection of two nodes (on the map or in the node
  list) and choose **Show Independent Paths**. The pinned pair stays drawn
  whatever is selected, until you choose **Clear Independent Paths** from the
  map's right-click menu.

A hop counts only when its link works in both directions, and routes prefer hops
whose weaker direction has the higher fade margin. The search runs in the
background and is redone after any change to nodes or links. For edge-, node-,
or shared-risk-disjoint analysis with a report, use **Independent Routes** in
[Network analysis](network-analysis.md).

## Network overlays

| Overlay | Meaning |
| --- | --- |
| **Normal Network View** | Presents the network-wide map view. |
| **Connection Weakness Overlay** | Draws a visual triage halo based on link quality and count. It is not a substitute for the topology-aware Critical Nodes analysis. |

Connection-weakness scores refresh in a background worker after edits and link
calculation. Previous halos are cleared while refreshing, and results from a
replaced document are discarded.

## Map framing

- **View → Fit to Active Nodes** fits enabled, non-hidden nodes; if none are
  active, it fits all network nodes.
- **Fit to Evaluation Range** fits the coverage evaluation ranges of selected
  eligible nodes, or all eligible nodes with no selection. Unique Coverage uses
  all eligible nodes, and selected FCC stations are included. If none qualify,
  it falls back to all network nodes.
- **Fit to Visible Coverage** fits calculated cells visible under the current
  fade-margin thresholds. It requires calculated coverage.

The map’s **Layers** drawer controls the basemap, terrain and land-cover blending,
coverage presentation, cached DSM hillshade, vector layers, amateur-license
visibility, callsign labels, and license coloring (License Class, Site Finder
Score, or Link Count; see [Use FCC amateur-license data](../how-to/use-fcc-amateur-data.md)).


Terrain, land-cover and cached DSM opacity changes reuse recent tile colors
without sampling the source data again. Tiles briefly wait for the new opacity
before appearing; normal and Multiply blending use the same opacity precision
as before. Changing a source, shading mode or contour setting rebuilds the
relevant tiles. Recently used colors are retained within a fixed memory budget,
so returning to an evicted tile can require sampling again.
