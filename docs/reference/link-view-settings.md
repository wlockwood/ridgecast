# Link View Settings

Open **View → Links → Link View Settings…** to choose what calculated link
colors mean and which results to display. Only the active view starts expanded.
Expand other sections to edit them, then press **Use this view** to switch the
map. **Using this view** identifies the active section.

The **Guide** button opens nonmodal help beside this window. Like other tool
guides, it opens on request and has its own saved **Show guide when this tool
opens** preference. The view settings themselves last for the application session.

## Choose the question

| View | What a high value means | Main controls |
| --- | --- | --- |
| **Fade Margin** | More predicted signal headroom above the effective noise floor | Distance/margin filters, color endpoints, quality bands or smooth colors |
| **Distance** | A longer geographic path | Distance/margin filters, relative colors or a fixed distance scale |
| **Long and Strong (Fortuity)** | A path that earns both distance and fade-margin credit | Distance/margin filters, two score references, relative or fixed colors |
| **Connectivity Potential** | Substantial nearby network connectivity on both sides | Hop retention, minimum potential, relative or fixed colors |
| **Hidden** | No calculated map links are drawn | The view-selection button |

Fade margin is stored in decibels (dB) as received signal level minus the
receiver's effective noise floor. A larger number means more predicted
headroom. These colors are planning aids; they do not establish a receiver's
decoding threshold or a measured link-success probability.

## Filters, scales, and examples

Fade Margin, Distance, and Fortuity have inclusive minimum/maximum distance and
minimum fade-margin filters. The effective margin minimum is the higher of the
section's value and the **global minimum fade margin** shown at the top of the
window. Change that global value through **Settings → Fade Margin Settings →
Visible Link Threshold**. Connectivity Potential uses that global threshold for
its graph and has a separate minimum-potential filter; it has no distance or
per-view fade-margin controls. For example, a section minimum of 0 dB and a
global threshold of 8 dB produce an effective minimum of 8 dB: a 5 dB link stays
hidden, while an 8 dB link passes the margin test.

Per-view filters affect drawing and picking, including link colors in coverage image
exports. They do not change calculated budgets, routing, node health, or coverage.
Lowering a display filter cannot recover links omitted by the calculation cutoff.
Link calculations retain margins at or above **Marginal (dB)** in **Settings →
Fade Margin Settings**. To retain weaker paths, lower that control, run
**Analysis → Recalculate → All Links**, then lower the global and per-view display
minima as needed. Marginal also affects coverage grading, so check coverage
settings after changing it. This calculation cutoff is separate from the
link view's Marginal color band; changing link-color endpoints does not change
which results calculations retain. Hidden-node links and non-finite distance/margin
results are not drawn.

Distance, Fortuity, and Connectivity Potential offer **Stretch colors across
links passing these filters**. Fade Margin always uses its numeric margin
endpoints and has no relative-color checkbox. With stretching checked, the lowest
value gets the Low color and the highest gets High. Offscreen links count;
hidden-node links do not. The numeric midpoint between the lowest and highest
values uses Middle. Colors can therefore
change after another link or a filter changes. High can mean best in a weak
group. A group with one distinct value uses Low uniformly.

Uncheck that box for a fixed scale. The reference then keeps the same numeric
color meaning across groups. Color examples use the same scale as the map;
their drawn lengths are swatches, not geographic distances. With no qualifying
real links, relative-color samples use Low. **Reset this mode** restores only that section.
Selected-node links keep their view color and draw wider, above unrelated links.

## Fade Margin

The initial margin endpoints are **0 dB** and **20 dB**. The fair-band boundary
is their midpoint, **10 dB**. In quality-band mode:

| Margin | Initial color |
| --- | --- |
| At or below 0 dB | Low: red |
| Above 0 dB and below 10 dB | Marginal: orange |
| At least 10 dB and below 20 dB | Middle / fair: yellow |
| At least 20 dB | High / good: green |

The table describes colors before visibility filters are applied. For example,
a global minimum of 10 dB hides all of the initial red and orange bands.

Colors are editable. Let `m` be fade margin, `L` the low endpoint, and `H` the
high endpoint, with `H > L`. For smooth colors the normalized color position is:

```text
t = clamp((m − L) / (H − L), 0, 1)
```

Here `clamp(x, 0, 1)` limits a value to that interval. The palette goes from Low
at `t = 0`, through Middle at `0.5`, to High at `1`. Band mode uses `L`,
`(L + H) / 2`, and `H` as the boundaries shown above. Its Marginal color is unused
when **Smooth gradient instead of quality bands** is checked.

These are link-color settings; coverage's fade-margin colors have separate controls.

## Distance

Distance is the geographic endpoint-to-endpoint path length, calculated using
the haversine formula on a spherical Earth. The view uses either the relative
scale above or a fixed scale with **Distance at high color**, initially 50 km
(31.07 miles). That reference is separate from the maximum-distance filter.

For latitudes `φ1`, `φ2` and longitudes `λ1`, `λ2` converted to radians:

```text
a = sin²((φ2 − φ1)/2) + cos(φ1) × cos(φ2) × sin²((λ2 − λ1)/2)
d = 2R × atan2(√a, √(1 − a)), with R = 6,371,000 meters
```

For fixed colors, with distance `d` and positive reference `D` in the same units:

```text
t = clamp(d / D, 0, 1)
```

Zero gets Low, `D/2` gets Middle, and `D` or longer gets High. A high distance
color means long, rather than strong or reliable.

## Long and Strong (Fortuity)

Fortuity defaults to a **1–500 mile** display range and **at least 0 dB** fade
margin, subject to the global minimum. The metric equivalents are 1.609344 km
and 804.672 km. **Full distance credit** starts at **500 miles**; **Full
fade-margin credit** starts at **30 dB**. Both score references must be positive.

The filters decide which links are shown. The references decide how much credit
each shown link earns. A minimum of 0 dB admits a zero-margin link, but that link
earns zero strength credit; setting a minimum is different from choosing a divisor.

For distance `d`, fade margin `m`, distance reference `D`, and margin reference `M`:

```text
distance_credit = clamp(d / D, 0, 1)
margin_credit   = clamp(m / M, 0, 1)
F               = distance_credit × margin_credit
```

Use the same distance units for `d` and `D`; use dB for `m` and `M`. Fixed colors
use `t = F`. Relative colors stretch the displayed scores instead.

These are raw scores; display filters can hide a row. In particular, the
zero-margin example is visible only when the global minimum also allows 0 dB.

| Distance and margin, with the defaults | Score F |
| --- | --- |
| 250 miles, 15 dB | 0.25 |
| 250 miles, 30 dB | 0.5 |
| 500 miles, 15 dB | 0.5 |
| 500 miles, 30 dB | 1 |
| 500 miles, 0 dB | 0 |

Each factor saturates at its reference, so longer or stronger inputs can tie.
Different combinations can also share a product. The dB margin is used directly
as a ranking input; it is not converted to linear power or a probability. Negative
distance or margin earns zero credit. Non-finite inputs or invalid references
score zero; invalid link metrics are excluded from display.

The two sample links sit at different filter boundaries. **At minimum distance**
uses the distance minimum and at least the full-credit margin. **At minimum fade
margin** uses the effective margin minimum and a distance at the full-credit
reference, constrained by the distance filters. The first sample can be red
because 1 mile earns little distance credit; the second scores zero when its
effective minimum is 0 dB. The labels give both inputs and the resulting score.

## Connectivity Potential

This view compares recursive network connections, not path length or signal
strength. It shows **Credit retained per extra hop**, **Minimum potential score**,
and the palette controls. Unchecking relative colors also shows **Potential at
high color**, initially **100**. The initial minimum score is **0**, which admits
all scored connections because every valid potential score is at least 1.

The analysis graph contains enabled, non-hidden radio nodes. Two nodes form one
logical connection only if both calculated directions have finite fade margin
at or above the global minimum. Reciprocal records count as one connection.
Passing this signal cutoff does not establish decoding success or reliability.
Markers, self-links, and duplicate records add no credit. Per-view filters and
selection do not change this graph. Changing the global **Visible Link Threshold**
does change the graph and reruns scoring.

For the connection being scored, remove it in both directions and run
breadth-first searches from its endpoints, called A and B. Each search visits
a node once, at its shortest hop distance; cycles cannot create repeated visits.

For every other logical connection `e` with endpoints `u` and `v`, define:

```text
hA(e) = min(shortest_hops(A, u), shortest_hops(A, v))
hB(e) = min(shortest_hops(B, u), shortest_hops(B, v))
credit(e) = β ^ min(hA(e), hB(e))
```

An unreachable endpoint has infinite distance. Ignore connections unreachable
from both roots. Assign each connection's credit to the nearer root; split ties
equally. `β` is **Credit retained per extra hop**, entered as a fraction from
**0.00 to 1.00**, initially **0.50**. A value of 0.50 retains half the credit per
extra hop. Directly
incident connections are at depth 0 and earn 1; subsequent layers earn 0.5,
0.25, and so on. At `β = 0`, only depth 0 counts; at `β = 1`, all assigned
connections count fully. There is no fixed hop limit.

Start each side total at 1 for the connection being scored, then add its
assigned credits. Call the totals `a` and `b`. The potential is their harmonic mean:

```text
P = 2 × a × b / (a + b)
```

For the star-shaped examples below, the tested connection joins the two hubs.
Each hub's 99 other connections go to its own separate leaf nodes, with no other
connections between any of these leaves. The leaf-to-hub example likewise has
only the listed direct connections.

| Example | Side totals a, b | Potential P |
| --- | --- | --- |
| Isolated pair | 1, 1 | 1 |
| Two hubs, each with 99 other direct connections | 100, 100 | 100 |
| Leaf connected to a hub with 99 other direct connections | 1, 100 | About 1.98 |

The harmonic mean favors support on both sides. The two sample lines illustrate
scores 1 and 100. **Minimum potential score** hides lower scores without removing
connections from the analysis graph. For fixed colors, with positive high-color
reference `K`, the color position is `t = clamp(P / K, 0, 1)`.

Changing hop retention reruns background analysis. Links are neutral gray while
scores update; one-way pairs have no score and are omitted once analysis is ready.
Both directions of a qualifying connection share its score. High potential can
include redundant connections; it does not measure construction cost, new
coverage, or newly served population. Incomplete calculated networks can change
the ranking as more results arrive. See [connectivity and construction
priorities](../concepts/connectivity-priorities.md) for related node metrics.

## Hidden and image export

Hidden removes calculated link lines from the map while keeping nodes and other
layers. It has no palette or filters. In coverage image export, the explicit
**Show links** option uses Fade Margin settings when Hidden is selected. In other
views it uses that view's palette and filters; Connectivity Potential export
waits for current scores. Hiding map links does not delete calculated results.

## Shared color math

For relative colors, let `x` be the view value (`d`, `F`, or `P`) and let `xmin`
and `xmax` be the smallest and largest values passing its display filters:

```text
t = clamp((x − xmin) / (xmax − xmin), 0, 1)
```

If all real values are equal, they all get Low. The implementation uses a padded
span of 1 above the common value for that flat range. For example, if every real
potential score is 10, they all use Low; hypothetical samples at 10.5 use Middle
and at 11 or above use High. An empty range maps all examples to Low.

Let `C0`, `C1`, and `C2` be the Low, Middle, and High RGB colors. The palette is:

```text
if t ≤ 0.5: C = (1 − 2t) × C0 + 2t × C1
otherwise: C = (2 − 2t) × C1 + (2t − 1) × C2
```

Interpolation is component by component in RGB; each result is rounded to an
8-bit channel value. The default palette is red → yellow → green. These colors
express the selected metric; a high color is not a general approval of a path.
