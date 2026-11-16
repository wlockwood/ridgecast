# Map views

View controls change how existing results are presented; they do not modify the
underlying network.

## Link display

Open **View → Links → Link View Settings…** for per-view settings and its
**Guide** button. Expand a section, then press **Use this view**; **Using this
view** marks the active choice. Settings last for the application session.

| View | Meaning |
| --- | --- |
| **Fade Margin** | Colors predicted signal headroom above the receiver's effective noise floor, using quality bands or a smooth scale. |
| **Distance** | Colors geographic path length; a high value means longer. |
| **Long and Strong (Fortuity)** | Multiplies normalized distance by normalized fade margin. Defaults show 1–500 miles with at least 0 dB; full-credit references are 500 miles and 30 dB. |
| **Connectivity Potential** | Compares cycle-safe recursive connection counts on both sides, using hop retention and a minimum-potential filter. It has no distance or per-view fade-margin controls. |
| **Hidden** | Removes calculated map link lines while retaining nodes and results. Coverage image export's explicit Show links option uses Fade Margin settings. |

The [Link View Settings reference](link-view-settings.md) describes every
control, default, equation, and worked example, including fixed versus relative
colors. Find the global **Visible Link Threshold** in **Settings → Fade Margin
Settings**; its value is also shown at the top of Link View Settings. A section
minimum of 0 dB with a global minimum of 8 dB still hides a 5 dB link.

Links touching any selected node draw above unrelated links in both directions,
with the existing wider stroke and their view color. Unrelated links dim. Exact
picking ties favor the line drawn on top. Several selected nodes promote the
union of their incident links.

## Node labels and colors

| Control | Choices or effect |
| --- | --- |
| **View → Node Labels** | **Full Names**, **Short Names**, or **Icon Only** |
| **View → Node Colors** | **Connectivity Health**, **Harmonic Connectivity**, **Site Score (All Nodes)**, **Site Score (Visible Nodes)**, **Site Score (Population Weighted)**, or **Hop Distance from Selected Node** |
| **Harmonic Connectivity** | Recursive, cycle-safe two-way reach, with each reachable node contributing `1 / shortest hops`. Also available as a highest-first Network list sort; see [connectivity priorities](../concepts/connectivity-priorities.md). |
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
coverage presentation, cached LiDAR hillshade, vector layers, amateur-license
visibility, callsign labels, and license coloring (License Class, Site Finder
Score, or Link Count; see [Use FCC amateur-license data](../how-to/use-fcc-amateur-data.md)).


Blend controls for terrain, land cover, coverage, cached LiDAR, and Site Finder
default to **Multiply**. Explicitly saved blend choices are preserved; older
settings or coverage workspaces with no blend choice use Multiply.

Terrain, land-cover and cached LiDAR opacity changes reuse recent tile colors
without sampling the source data again. Tiles briefly wait for the new opacity
before appearing; normal and Multiply blending use the same opacity precision
as before. Changing a source, shading mode or contour setting rebuilds the
relevant tiles. Recently used colors are retained within a fixed memory budget,
so returning to an evicted tile can require sampling again.

These three overlays render independently on background CPU workers. Worker
counts adapt to the available logical processors, with at least one and at most
16 workers per layer. On a machine with 32 available logical processors, each
layer gets ten workers. Completed jobs count toward the limit until the UI
accepts them, and texture uploads are limited to four per layer per frame.

As terrain or land-cover data arrives, terrain shading keeps its last rendered
tiles visible until replacements are ready. Arrivals do not cancel active
terrain rendering jobs; overlapping refresh requests are combined. Changing
terrain settings or shading style still discards incompatible tiles immediately.

Panning away or finishing a zoom change keeps recent sampled tile colors within
the existing 16 MiB budget per layer. Returning to those tiles reuses the colors
and applies the current opacity instead of sampling terrain again. Offscreen
colors are evicted before visible colors when the budget fills. Source, style,
contour, and water changes still invalidate affected content; hiding a layer
releases its retained colors. Basemap download concurrency is unchanged.
