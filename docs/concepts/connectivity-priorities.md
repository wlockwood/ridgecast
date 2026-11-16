# Prioritizing connectivity and construction

Connectivity opportunity and the benefit of building the next site answer
different planning questions. A candidate graph describes possible connections;
it does not say which sites are built, what they cost, or where service is missing.

## Link Connectivity Potential

Choose **View → Links → Connectivity Potential**. Links are colored by recursive
connectivity on both sides. Pending links are neutral gray while the worker runs;
hover a scored link to see its score and the two side totals.

The analysis graph contains enabled, non-hidden radio nodes. Each unordered pair
is one logical connection, qualifying only when **both directions** have finite
stored fade margin at or above the global minimum. RidgeCast also calls this
stored number SNR: received signal level minus the effective noise floor.
Find the global **Visible Link Threshold** in **Settings → Fade Margin Settings**.
Eligibility means passing this signal cutoff; it does not establish decoding
success or reliable communication. Marker nodes, self-links,
and duplicate directions contribute no extra credit. Map selection and mode
display filters do not change this analysis graph. Both drawn directions share
one score; one-way pairs are omitted after analysis completes.

For each tested connection:

1. Remove it in both directions, then run breadth-first searches from its ends.
   Each search visits a node once, at its shortest hop distance.
2. Consider each other logical connection once. Its distance from a root is the
   smaller hop count of its endpoints. Assign it to the closer root; split equal
   distances equally. Ignore connections unreachable from both ends.
3. Give a connection at depth `h` credit `β^h`. Default `β = 0.5` gives direct
   incident connections full credit, then 0.5, 0.25, etc. There is no fixed hop
   limit. At `β = 0` only direct connections count; `β = 1` counts all assigned
   connections fully. Cycles cannot add repeated credit.
4. Start each side at 1 for the tested connection. Combine side totals `A` and
   `B` using `2AB / (A+B)`, their harmonic mean.

In the star-shaped examples below, the tested connection joins the hubs. Each
hub has 99 connections to its own separate leaf nodes, and there are no other
connections. The leaf-to-hub example also has only the listed direct connections.

| Example | Side totals | Potential |
| --- | --- | --- |
| Isolated pair | 1 and 1 | 1 |
| Two hubs each with 99 other direct connections | 100 and 100 | 100 |
| Leaf connected to a hub with 99 other direct connections | 1 and 100 | About 1.98 |

This favors substantial support on **both** sides, keeping a leaf from inheriting
a large region's full value. Shared cyclic neighborhoods are partitioned by
shortest distance; ties split credit independently of import order.

In **View → Links → Link View Settings… → Connectivity Potential**, adjust hop
retention, minimum potential, palette, or fixed/relative coloring. Fixed coloring
defaults to a high-end reference of 100; samples illustrate scores 1 and 100.
Relative coloring stretches over scored links passing display filters; equal
scores use the low color. This section has no distance or per-view fade-margin
filters: use hop retention and minimum potential to focus on connectivity.
Changing hop retention reruns scoring; colors and the minimum-potential filter
reuse completed scores. The [Link View Settings reference](../reference/link-view-settings.md#connectivity-potential)
includes the full equations and window controls.
Image export uses the same scores and waits for the current analysis to finish.

This is a custom opportunity heuristic. A redundant connection inside a dense
region may score highly. A conventional alternative, **edge betweenness**, measures
the share of shortest paths using a connection and divides credit among alternate
paths. It addresses transit and bottleneck importance, a different question from
neighborhood richness. See the [NetworkX edge betweenness definition](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.centrality.edge_betweenness_centrality.html).

## Node Harmonic Connectivity

Choose **View → Node Colors → Harmonic Connectivity**, or **Harmonic connectivity**
in the Network list sort control for highest scores first. The map uses relative
colors over eligible radios; hover to see the raw score. Selection does not alter
it. Coverage's **Best serving site** (Best Unit) and **Unique contribution of one
site** (Unique Coverage) questions override node-icon colors, so the Node Colors
choices are disabled with an explanatory tooltip. To use Harmonic Connectivity,
choose **Strongest signal / fade margin** in the Coverage panel's question selector,
then **View → Node Colors → Harmonic Connectivity**.

For node `v`, the score is `Σ 1 / d(v,u)` over all other reachable radios `u`.
Distance `d` is the shortest hop count in the same threshold-qualified two-way graph. Each
node counts once; unreachable nodes contribute zero. Direct neighbors contribute
1, two-hop neighbors 0.5, three-hop neighbors 1/3, etc. Isolates score zero.
There is no dependence on link potential's adjustable hop retention.

This is standard harmonic centrality, chosen because it handles disconnected
networks and values breadth and short paths. It discounts long paths more slowly
than link potential's default exponential discount. Chain centers rank above
their leaves. A leaf beside a dense region can still have useful reach; a leaf
far down a chain receives much less credit for that region. See the
[harmonic centrality definition](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.centrality.harmonic_centrality.html)
and Boldi and Vigna's [Axioms for Centrality](https://arxiv.org/abs/1308.2140).

Existing **Connectivity Health** uses direct link counts or a reliability estimate
from one selected node. It does not provide this recursive ranking. Existing
area/population Site Score views and list sorts answer separate service-opportunity
questions and can be compared alongside connectivity.

## Population, land area, and actual build order

Construction decisions need an already-built baseline and a clear objective.
A next-build measure is `U(baseline + proposal) − U(baseline)`, optionally divided
by cost. Utility might be newly served population, newly covered land, newly
connected existing sites, or additional independent routes.

Population should use the **union of newly served coverage cells**, weighted by
residents per cell. Land area should likewise count unique cells at their physical
area. Multiplying centrality by a site's population total can repeatedly credit
the same residents and blend unlike quantities without an explicit objective.

RidgeCast's [candidate-site comparison](../reference/network-analysis.md) already
evaluates up to 512 sites independently against a baseline excluding the candidates,
with coverage, population, resilience, route, and facility ingredients. It requires
a non-candidate backbone. Its coverage credit is not gated on joining the backbone
and does not include all coverage made useful when other sites are reconnected
through a candidate. Use reported reachability and service dimensions together;
the combined score is not a complete construction schedule.

Two proposed relays can be useful only when built together. Such dependencies
need connected packages or construction stages, rather than a standalone node
color or greedy single-site ranking. Use the new topology views to shortlist
connectivity opportunities before those deployment studies.
