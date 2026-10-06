# Coverage modes

Coverage evaluates a configured **Test Node** at cells around one or more
selected radio nodes. The Test Node is the hypothetical radio at the far end of
each map cell; configure its power, receiver sensitivity, antenna, height, and
system loss under **Coverage → Edit test radio**. Signal-quality thresholds come from **Settings → Fade
Margin Settings**. A fade margin is measured in dB; a larger value means more
modeled headroom above the effective noise floor.

## Fade margin settings

Open **Settings → Fade Margin Settings** to choose the visible-link threshold,
coverage quality thresholds, and the minimum margin for Best Unit ownership.
Every control has a tooltip explaining its effect.

**Smooth coverage colors** is enabled by default and saved with the network.
Each hex keeps one solid fill, interpolated between orange at **Marginal**,
yellow at **Fair**, and green at **Good**. Below Marginal, the fill blends toward
red, reaching red 10 dB below that threshold; at or above Good it stays green.
Turn the toggle off to restore distinct green, yellow, orange, and red bands.
Smooth mode interpolates in a perceptual color space to give more even-looking
transitions between the same anchors. It preserves each hex's opacity and does
not blur neighboring cells or soften the coverage cutoff.
Equal thresholds collapse a transition, with the stronger color taking priority
at the shared value.

Smoothing applies to coverage colored by fade margin, including single-node
Best Unit and Unique Coverage, and the colors carried into exported maps. It
does not change predicted margins, coverage quality counts, visibility rules,
multi-node owner colors, or Redundancy colors. Color calculation happens on the
coverage worker; panning and zooming use the same cached geometry in either mode.

Good and Fair include values exactly at their thresholds. Marginal includes
values strictly above its threshold but below Fair; values at or below Marginal
count as Poor unless they also meet Fair or Good. With distinct thresholds, a
hex exactly at Marginal still counts as Poor when smoothing makes it orange.

## Visual settings

Under **Layers → Coverage appearance**, **Blur Radius (Heatmap)** ranges from **0 to 20**,
and **Min Cluster Size** ranges from **1 to 20**. Both default to **1**.
Blur Radius averages fade margins over existing neighboring hexes within the
selected number of steps, then colors each hex from that averaged margin using
the configured smooth scale or discrete bands. Missing neighbors at the coverage
boundary do not contribute zeros. For multi-node ownership and Redundancy,
the categorical colors are averaged instead. Cell transparency is averaged too,
so blurred transitions retain their partial opacity. The **Opacity** slider
scales that stored cell opacity: 100% preserves it, and 0% hides the fill.
A radius of 0 displays each hex's
own prediction without spatial blurring. This display processing leaves raw
predictions and coverage statistics unchanged. Min
Cluster Size hides connected groups with fewer than the selected number of
hexes, including the hex itself; at 1, all groups remain visible. Adjacency for
both controls uses the grid actually calculated, even when cell limits make
its hexes larger than the requested resolution. These settings are saved with
the network.

## Presets

| Preset | Hex resolution | Angular step | Intended use |
| --- | ---: | ---: | --- |
| **Draft** | 200 m | 5.0° | Quick exploration |
| **Planning** | 50 m | 1.0° | Normal planning |
| **Detailed** | 15 m | 0.5° | Small-area detailed work |

Hex resolution is the approximate center-to-center spacing of the evaluated
cells. Angular step applies only to Radial Sweep: smaller degrees place more
rays. The range, resolution, angular step, number of evaluated nodes, data
availability, and selected model all affect runtime. Lower cell sizes increase
the cell count approximately with area.

## Algorithms

Open **Coverage → Calculation options** for exact hex spacing, algorithm,
and Radial Sweep angular step.

| Algorithm | Behavior |
| --- | --- |
| **Vertex Grid** | Evaluates a hexagonal grid for continuous output. |
| **Radial Sweep** | Casts rays outward. It is faster, but gaps can appear at long range where rays diverge. |

## Direction

| Direction | Question answered |
| --- | --- |
| **TX** | `selected node → Test Node`: where can the selected node or nodes be heard? |
| **RX** | `Test Node → selected node`: from where can the selected node or nodes hear the Test Node? |
| **Two-way** | Both directions must qualify through the same serving site. Each site's margin is its lower TX/RX margin; the best qualifying site wins. |

TX and RX results differ when power, antenna gain, height, or receiver noise is
asymmetric.

Two-way mode evaluates exact TX and RX grids separately on the CPU and uses
their distinct cache identities. It joins margins by serving site and cell
before merging. A good downlink from site A plus a good uplink to site B does
not create two-way service. Raw margins for both directions, failures, and
missing-direction values remain available in retained artifacts and GeoJSON.
Missing terrain remains unavailable, and ownership/statistics use the combined
margin. The job publishes completion only after both directional runs finish.

## Merge and display modes

| Mode | Availability | Meaning |
| --- | --- | --- |
| **Strongest signal / fade margin** | One or more nodes | Each cell shows the strongest fade margin from any evaluated node. |
| **Best serving site** | Multiple nodes | Each cell is colored by its strongest serving node. Retains per-node serving margins. |
| **Coverage redundancy** | Multiple nodes | Each cell is colored by how many evaluated nodes qualify. Retains per-node serving margins. |
| **Unique contribution of one site** | One node | Evaluates that node against the rest of the enabled, visible radio network, then shows its exclusive cells. Retains per-node serving margins for the evaluated nodes. |

The **Best Unit threshold** (default 10 dB) is an absolute minimum fade margin
for these three modes, not the difference between a winner and runner-up. The
Marginal threshold also affects visible and counted coverage.

The **Coverage question** menu always shows all four choices. Best serving site
and redundancy require at least two eligible sites, including selected amateur
locations. Unique contribution requires exactly one selected network radio and
no selected amateur locations; unavailable choices explain their requirements.
Use **Strongest signal / fade margin** (Max Fade Margin) for that site's total map;
its whole-image export stats card can show area and loaded WorldPop population. It does
not retain the serving margins needed for per-site captions or coverage-weighted
network analysis. Unique Coverage answers a different question—what that site
alone contributes—and evaluates other network nodes as comparisons. For the
usual network service analysis, select multiple sites and choose **Best serving site** (Best Unit).

Coverage is cached persistently per node. Adding a node to a selection normally
calculates only that node; removing a node normally calculates nothing. Changing
radio inputs, propagation settings, range, or resolution can invalidate the
affected cache entry. A wide merged result can be drawn on a coarser grid than
the individual cached node results to remain within the display cell budget.

See [Coverage maps](../concepts/coverage.md) for interpretation and
[Generate and export a coverage map](../how-to/generate-and-export-coverage.md)
for a task-oriented procedure.
