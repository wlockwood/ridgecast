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

**Coverage Owner Colors**, available under **View → Node Colors** and **Settings**,
edits the shared owner palette and opacity over the basemap for Best Unit and
Unique Coverage. It stays available in every mode; edits apply when an owner
mode is displayed. These are application display preferences, saved separately
from the network. Site Score entries color existing nodes; start a scan through
**Analysis → Planning → Site Finder**.

Short names use a node's custom shortname when one is set. Otherwise, RidgeCast
shortens its name to the **Target Shortname Length** in Settings. Names that fit
stay unchanged. Common word abbreviations apply only when they do not go below
the target length; any remaining characters are removed one at a time. The
shortener favors word initials and edges, keeps common digraphs together when
possible, and treats a final silent E as low value.

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

Map Settings separately controls the basemap, terrain and land-cover blending,
coverage presentation, cached DSM hillshade, vector layers, amateur-license
visibility, callsign labels, and license coloring (License Class, Site Finder
Score, or Link Count; see [Use FCC amateur-license data](../how-to/use-fcc-amateur-data.md)).


Terrain, land-cover and cached DSM opacity changes reuse recent tile colors
without sampling the source data again. Tiles briefly wait for the new opacity
before appearing; normal and Multiply blending use the same opacity precision
as before. Changing a source, shading mode or contour setting rebuilds the
relevant tiles. Recently used colors are retained within a fixed memory budget,
so returning to an evicted tile can require sampling again.
