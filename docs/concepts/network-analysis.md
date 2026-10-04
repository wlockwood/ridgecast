# Network analysis: reachability, redundancy, and what a failure costs

*An explanation of what RidgeCast's **Analysis** menu measures, what graph it
measures it on, and which numbers are predictions rather than measurements.
Written for someone who has never seen the code and does not need to.*

---

## 1. A different kind of question

Everything else in RidgeCast asks a question about *radio*: will these two
antennas hear each other, how far does this site reach, where should the next
tower go. Network analysis asks a question about the *network* those links add
up to:

- Is everything I think is on the network actually on it?
- If I lose one site, what breaks?
- Is the redundancy I think I have real redundancy?
- Can this path carry the traffic I intend to put on it?

None of those can be answered by looking at one link. They are properties of the
whole set of links at once, which is why they live in their own menu, their own
results window, and their own set of stated assumptions.

Some vocabulary, used consistently below.

- A **node** is one radio installation — an antenna at a place, at a height.
  RidgeCast models one radio per node, so "node" and "radio" are effectively
  interchangeable here.
- A **marker node** is an annotation on the map that carries no radio at all. It
  is excluded from every analysis.
- A **link** is a calculated path between two nodes that came out usable.
- A **hop** is one link as traversed by traffic; a **route** is a sequence of
  hops from a source node to a destination node.
- The **backbone** is the set of nodes you have marked as the network's core, by
  ticking **Backbone Hub** in a node's edit window (§2). Those two names refer to
  the same thing: the hubs are the backbone.
- A **coverage cell** is one cell of the hexagonal grid a coverage calculation
  paints — a patch of ground, not a cellular base station. Several analyses count
  them and the people under them.

### The one number everything thresholds on

**Fade margin** is how many decibels the signal arriving at a receiver sits
*above* the minimum that receiver needs to hear it. Twelve dB of margin means the
signal is about sixteen times stronger than the floor; 0 dB means it is exactly
at the floor and any rain, foliage, or misalignment takes the link down;
a negative margin means no link at all.

RidgeCast reports the same quantity as **SNR** in some places and **fade margin**
in others — including "RF margin" in Best Route's bottleneck list (§7). **They
are all the same number.** Where it comes from is the subject of **[From
transmit power to fade margin](link-budget-and-noise.md)**; for this document, it
is the single scalar per link that every analysis in the menu gates on.

## 2. What has to exist first

Analysis does not calculate links. It reads links that already exist, so three
things must be true before it will do anything useful.

**Links must already be calculated.** If the map is not drawing links, there is
nothing to analyze. Every analysis command needs at least two enabled nodes with
calculated links between them.

**At least one node must be ticked as a Backbone Hub**, in that node's edit
window. This is not a formality. Half of what this menu measures is *reachability
against the backbone* — "can this node get to the core of the network" — and
without a backbone there is no core to measure against. RidgeCast will not guess
one for you; the commands that measure reachability against the backbone —
Backbone Connectivity, Critical Nodes, the N-1 sweep, node-failure simulation,
Population Service, and candidate ranking — stay disabled, and the menu says why
on hover. The route and throughput commands do not need one.

Pick the nodes that are genuinely the core: the internet gateways, the sites
everything else is supposed to reach. In a small network this is often one node.
That is fine, and it will honestly dominate the failure rankings, because losing
your only gateway really does disconnect everyone.

**Risk Groups are optional but change one answer entirely.** The same node edit
window accepts arbitrary labels such as `tower:beacon` or `power:feed-2`. They
mean "these nodes fail together". Nothing derives them — they encode knowledge
only you have, like which two sites are on the same generator or the same tower.
They are read by exactly one analysis (shared-risk route independence), and that
analysis is only ever as good as the labels you entered. When no node in the
network carries any, results say so.

Every menu command lists its own full requirements on hover, each item marked met
or unmet, whether or not the command is currently available. Nothing has to be
discovered by trial and error.

## 3. The graph being analyzed

Before any command runs, RidgeCast takes an immutable **snapshot** of the
network: nodes, links, margins, and the assumptions in force at that moment.
Everything then runs on a worker thread against that snapshot. Three consequences
follow, and all three are deliberate:

- Analyses never block the interface, however long they take.
- Nothing an analysis does can modify your project. A failure simulation is an
  overlay computed against a copy; there is nothing to undo afterwards.
- A result is marked **stale** the moment the network changes underneath it,
  rather than silently continuing to describe a network that no longer exists.

### The graph is directed, and that matters more than it sounds

An RF link is not symmetric. A hilltop repeater running 40 W into a high-gain
antenna can be *heard by* a handheld that cannot be *heard back*. Nothing about
that is exotic — it is the normal case whenever power, antenna gain, or receiver
sensitivity differ between the two ends, which is most real networks.

So RidgeCast's graph has directed edges, and it never averages the two directions
into a single "connected". A node is classified as one of four states, not two:

| State | Meaning |
| --- | --- |
| **Two-way** | The backbone can reach it *and* it can reach the backbone. |
| **Downlink-only** | The backbone can reach it; it cannot answer. |
| **Uplink-only** | It can reach the backbone; the backbone cannot reach it. |
| **Disconnected** | Neither direction. |

The two one-way states are the interesting ones, because a network diagram will
happily draw them as ordinary lines.

### Which links count as usable

Two settings in **Assumptions** decide which edges the graph even contains:

- **Minimum link margin** — links with less fade margin than this are treated as
  unusable by every analysis. The default is 0 dB, meaning "every link the map is
  drawing". Raising it to a realistic operating margin frequently changes which
  nodes are reachable and which routes exist, which is the point of having it.
- **Service requires** — whether a node counts as connected when the backbone can
  reach it (downlink), it can reach the backbone (uplink), or both. Two-way is
  the default, because that is what traffic needs.

Marker nodes carry no radio and are excluded. Disabled nodes are excluded; hidden
nodes are not, because hiding is a display choice rather than a statement about
the network.

### Which graph each command uses

Because direction matters, it matters which graph a command runs on:

- **Critical Nodes** works on the **mutual-link graph** — only links usable in
  both directions — because "splits the network" is a claim about two-way
  traffic (§5).
- **Backbone Connectivity**, the **N-1 sweep**, **node-failure simulation**, and
  **Population Service** run on the **directed** graph, and honour the *Service
  requires* setting when deciding whether a node counts as connected.
- **Best Route**, **Independent Routes**, and **Throughput** run on the
  **directed** graph, following edges in the direction traffic would travel. A
  route from A to B may therefore be different from the route from B to A, which
  is correct and occasionally surprising.

## 4. Is everything actually connected?

**Backbone Connectivity** classifies every node into the four states above and
reports its hop count to the nearest backbone hub.

Use it after adding sites, or after changing power, antennas, or the minimum
margin, to confirm that everything you believe is on the network is on it. It is
the cheapest command in the menu and the one worth running first, because a
surprising number of "why is this analysis empty" questions are answered by
discovering that a third of the network is uplink-only.

*Requires a backbone hub.*

## 5. Where does the network break?

**Critical Nodes / Articulation Points** finds the nodes and links whose loss
would split the network in two.

It works on the **mutual-link graph** — only links usable in both directions —
because "splits the network" is a statement about two-way traffic. A one-way link
does not hold a network together.

Each node it finds is labelled one of two ways, and the distinction is the whole
value of the command:

- **Backbone-critical** — its failure costs some other node its path to the
  backbone. This is a real operational risk.
- **Topology articulation point** — its failure only divides a component that had
  no backbone service to lose. It looks alarming on a graph and costs nothing in
  practice.

Use it to decide where redundancy is worth paying for.

*Requires a backbone hub.*

## 6. Which loss hurts most?

Critical Nodes answers *whether* a node splits the graph. It does not answer *how
much that costs*. The **Single-Node Failure Sweep (N-1)** does.

"N-1" is borrowed from the power industry: it means surviving the loss of any one
component. The sweep removes each node in turn, recomputes the network without
it, and reports what that node's absence costs — how many other nodes lose their
path to the backbone, how the network fragments into pieces, and, when coverage
has been calculated, how much ground and how many people stop being served. One
row per node, worst first.

Three properties are worth knowing:

- It runs in parallel, with progress and cancellation.
- Its rows are ordered **deterministically regardless of thread count**, so two
  runs over the same network produce byte-identical output. A resilience summary
  in a report can be regenerated and diffed.
- The **articulation points and backbone only** option in Assumptions restricts
  the sweep to nodes that can actually strand another. It is much faster and
  loses nothing, because a node that strands nobody contributes a row of zeroes.

Expect the sole backbone hub to top the ranking. That is not a flaw in the sweep;
losing the only gateway does disconnect everyone.

*Requires a backbone hub. Coverage is optional and adds the population and
coverage-area columns.*

## 7. How does traffic actually cross the network?

**Best Route** finds a path between two selected nodes under one **objective**,
and then reports the weakest link along it four separate ways.

The objectives:

| Objective | Chooses the route that… |
| --- | --- |
| **Fewest hops** | crosses the fewest links, with stable node-order tie breaking. |
| **Best margin** | maximises the *worst* link's fade margin along the route. |
| **Most reliable** | maximises the product of the per-link success probabilities — a *modeled* figure derived from fade margin, not a measurement; see §12 before relying on it. |
| **Lowest latency** | minimizes accumulated explicit per-hop delay; unknown delays cannot form a latency route. |

The objective matters more than it looks. *Fewest hops* will happily take one
marginal 5 dB link; *best margin* will route around it over two solid ones. They
are different networks as far as traffic is concerned.

The four reported bottlenecks are **lowest RF margin** (the fade margin of §1),
**lowest success probability** (§12), **lowest PHY rate** (§9), and **highest
latency**. They are deliberately not collapsed into one score, because each
implies a different fix: a margin problem wants a better antenna or a better
site, a rate problem wants different modulation, a latency problem wants a
different path.

Two of those four depend on things this command does not require you to set. The
**PHY rate** bottleneck reads the assumed rate from Assumptions (§9); with no
rate set it reports zero and the result carries a missing-rate warning, so treat
that column as meaningful only once you have entered a rate. Latency totals are
available only when every hop in the returned route has an explicit delay.

**Lowest latency** minimizes explicit assumed/measured delays in milliseconds.
The optional uniform delay is a fallback for missing directed overrides. A
positive uniform cost selects the same minimum hop count; an all-zero model
ties all paths. Unknown delays cannot become zero-cost shortcuts: latency
routing uses only hops with known costs. These values do not predict queueing,
MAC contention or processing time; record their provenance in the directed
inputs editor. See [authored inputs](../reference/network-analysis.md#assumptions).

*Requires exactly two nodes selected on the map. No backbone hub is needed.*

## 8. Is the redundancy real?

Two routes drawn on a map can look independent and fail together. **Independent
Routes** counts how many genuinely independent paths exist between two nodes,
under one of three definitions, and shows the minimum cut that explains the
number.

| Mode | "Independent" means | Survives |
| --- | --- | --- |
| **Edge-disjoint** | no two routes share a link | one link failing |
| **Node-disjoint** | no two routes share an intermediate site | one site failing |
| **Shared-risk-disjoint** | no two routes share a failure domain | "both towers are on the same generator" |

They are not interchangeable, and RidgeCast will not merge them into a single
"redundancy" number. Two edge-disjoint routes through the same relay both die
with that relay.

There is one honest asymmetry in how they are computed. Edge- and node-disjoint
counts come from **max flow with unit capacities**, which is exact — the number
is the true maximum. Shared-risk independence is not exact: a route consumes a
whole *set* of failure groups, so picking the largest mutually risk-disjoint set
of routes is an independent-set problem, and RidgeCast solves it over a bounded
pool of candidate routes. The answer is a defensible lower bound rather than a
proof. Results always say which of the three they are.

In all three modes, any nodes and any risk groups the routes share are reported
anyway. Two routes that are graph-disjoint but both cross the same ridge tower
are flagged rather than quietly counted as real redundancy.

*Requires exactly two nodes selected. Shared-risk mode is only as good as the
Risk Groups you have entered.*

## 9. How much can a path carry?

**End-to-End Throughput** estimates multi-hop throughput three ways at once,
because no single number is honest about a half-duplex multi-hop radio network.

- **Bottleneck upper bound** — the slowest hop, as if hops never interfered with
  each other. Optimistic by construction. This is the number that makes a
  five-hop LoRa path look like it delivers the link rate. It does not.
- **Serial shared airtime** — every hop competes for one medium, so their
  airtimes add and the reciprocals of their goodputs sum. Correct for a
  single-radio, single-channel chain, and roughly the single-link rate divided by
  the hop count.
- **Interference-aware** — hops are grouped into **contention domains**, and the
  tightest domain governs. This sits between the other two whenever channel reuse
  or spatial separation lets some hops transmit at once.

### What a contention domain is

Two hops conflict if they cannot transmit simultaneously. RidgeCast tests three
conditions: they share a node, they share a radio, or they share a channel.

The middle one is currently redundant — RidgeCast models one radio per node, so
"shares a radio" can never fire where "shares a node" did not. The condition
exists because the machinery is built for a world where a node can host several
radios on different channels, and it is inert until that exists.

Hops are then grouped into overlapping sets of mutually conflicting hops, and
each set's capacity is computed as if its members took turns: their airtimes add,
so the reciprocals of their goodputs sum.

The default grouping is a polynomial approximation — the closed neighbourhoods of
the conflict graph, with any that are a strict subset of another dropped. It is
deterministic and **never optimistic** relative to the true answer. **Exact
contention mode** in Assumptions instead enumerates the true maximal cliques
(Bron–Kerbosch with pivoting). It is off by default because clique enumeration is
exponential; it is capped at 30 hops and a wall-clock budget, and falls back to
the approximation, with a warning, when it hits either.

With no authored channel plan, the interference-aware number equals serial
airtime. Directed channel labels permit contention reuse across unrelated hops;
missing channels still collide conservatively. Radio labels are scoped by node,
so unrelated `radio0` labels cannot collide accidentally. Sharing an endpoint
always conflicts, even if its labels differ: this increment does not enable
general multi-radio concurrency or multi-frequency RF calculations.

### The rate the whole thing rests on

RidgeCast predicts a received level and a fade margin. It has **no per-link
modulation rate of its own**, so throughput rests entirely on the **Assumed PHY
rate** you enter in Assumptions, in kbit/s, or a directed override in bit/s.
Each edge uses its authored rate first and the global fallback second. An
explicit directed zero means unknown; it does not inherit a plausible fallback.

A **Presets** list covers the stacks RidgeCast is usually used to plan. The two
LoRa entries are *computed* from their modulation parameters rather than written
down as constants:

```
Rb = SF × (BW / 2^SF) × 4/(4 + CR)
```

LoRa transmits by sweeping across its channel; one such sweep is a **chirp**, and
it carries `SF` bits, where **SF** is the *spreading factor*. A higher spreading
factor spends longer per chirp, which reaches further and carries less. `BW` is
the channel bandwidth, so `BW / 2^SF` is how many chirps fit into a second, and
`CR` is the *coding rate* denominator — the cost of the forward error correction
that lets a damaged frame still decode.

Hover text in the application shows those parameters, so a preset can be checked
against the settings on a radio's own screen instead of taken on trust:

| Preset | Modulation | Rate |
| --- | --- | --- |
| **MeshCore default** (the fresh-session default) | LoRa SF7, 50 kHz, CR 4/5 | ≈ 2.19 kbit/s |
| **Meshtastic LongFast** | LoRa SF11, 250 kHz, CR 4/5 | ≈ 1.07 kbit/s |
| **APRS 1200 baud** | AFSK | 1.2 kbit/s |
| **APRS 9600 baud** | FSK | 9.6 kbit/s |

MeshCore and Meshtastic take opposite trade-offs from the same modulation.
MeshCore uses a narrow channel and a low spreading factor, so each chirp is short
and carries little distance but they come fast; Meshtastic LongFast uses a wide
channel and a high spreading factor, so each chirp is long, robust, and slow. The
result is that MeshCore carries roughly twice the rate over a shorter usable
path.

Setting the rate to **zero** makes every throughput figure report *Not available*
rather than assuming one. That is the correct setting when you do not know.

Goodput is not the PHY rate. Each frame carries framing overhead and fixed
per-frame time that does not scale with the rate — preamble, acknowledgement
airtime, interframe spacing, and expected backoff. RidgeCast assumes a generic
profile for these (a 1500-byte payload with 64 bytes of overhead, and tens of
microseconds each of preamble, ack, interframe, and contention time). It does not
model any specific MAC, and every result carrying these figures is warned.

*Requires exactly two nodes selected, and an assumed PHY rate.*

## 10. Who stops being served?

**Simulate Selected Node Failure** shows what losing one specific site would
cost: which nodes are stranded, how the network fragments, and how many backbone
hubs remain. Use it when you are already worried about one particular site,
rather than sweeping all of them.

*Requires a backbone hub and exactly one node selected.*

**Population Service** adds demand to that picture: which coverage cells stop
being served, which drop from two serving sites to one, and how many people live
under the cells that go dark.

One rule in it is worth stating explicitly: **coverage from a site that has been
cut off from the backbone is not counted as service.** A repeater nobody can
reach is not serving anyone, however much ground its coverage overlay paints.

Use it to argue for a site in terms decision-makers care about — people, not
decibels.

*Requires a backbone hub, one node selected, and coverage calculated in **Best
Unit** merge mode. Without that coverage the demand columns report "Not
available" rather than zero.*

**Critical Facility Service** evaluates a saved/imported named inventory.
GraphNode facilities inherit their attached node's selected-policy reachability.
RFPoint facilities require an explicit receiver and an enabled backbone-connected
site meeting the chosen margin threshold; two-way service must use that same
site for both budgets. The result and CSV show baseline and failure statuses,
named losses and unknown data. Different strongest forward/reverse sites do not
count as two-way service. An absent inventory is unavailable; `[]` is known empty.
See the [inventory format](../reference/network-analysis.md#assumptions).

## 11. Where should the next site go?

**Rank Candidate Sites** ranks selected nodes by measured coverage, population,
resilience, route, and facility gains. Each is added alone to a baseline that
excludes all candidates. A site that duplicates existing coverage can still add
resilience; the raw gains show why it scored as it did.

Use it to choose between several possible sites once you have modeled each as a
node and calculated its links. Coverage enables the coverage/population dimensions.

Three limits are load-bearing:

- **Scores are normalized across the selected set.** Each candidate's coverage
  score is its added coverage as a fraction of the best candidate's added
  coverage. They compare candidates *within one run* and are meaningless across
  runs with different candidates. The raw cell and population counts are shown
  alongside for exactly that reason — those are comparable.
- **Every candidate is evaluated separately.** The baseline excludes all
  candidates. Resilience gain compares total disconnected surviving fixed
  noncandidate nonhub targets across identical baseline-node failures. Route
  gains use an exact node-disjoint count for an optional fixed pair. Facilities
  need an inventory with known service inputs. Available dimensions have equal
  default weights; users can change those weights, and raw gains remain visible.
- **It does not predict links from a site that is not already in the network.**
  A candidate has to be modeled as a node with calculated links first.

*Requires a noncandidate backbone hub and one or more calculated candidate nodes.
Coverage/population are optional measured dimensions; a route pair and facility
inventory enable their corresponding dimensions. Runs are limited to 512 candidates.*

## 12. Modeled, assumed, and unavailable

Every analysis is only as meaningful as its assumptions, so the **Assumptions**
section of the results window exposes them and every result repeats the ones it
used:

| Setting | What it changes |
| --- | --- |
| **Minimum link margin** | Links below this fade margin are unusable to every analysis. Default 0 dB. |
| **Service requires** | Downlink, uplink, or two-way. Default two-way. |
| **Assumed PHY rate** | The rate airtime and throughput are computed from. Zero means unavailable. |
| **Route objective** | Which path *Best Route* considers best. |
| **Independence** | Which of the three definitions *Independent Routes* counts by. |
| **N-1 sweep scope** | Every node, or only articulation points and backbone hubs. |
| **Exact contention mode** | Exact maximal-clique enumeration instead of the conservative approximation. |

Two figures in this menu rest on models rather than measurements, and both are
labelled as such wherever they are used:

**Per-link success probability** is *derived from fade margin by a logistic
curve*, not measured:

```
p = 1 / (1 + exp(-steepness * (margin_dB - midpoint_dB)))
```

with a midpoint of 3 dB and a steepness of 1. So a link with exactly 3 dB of
margin is assumed to succeed half the time, one with 10 dB about 99.9% of the
time, and one at 0 dB about 5% of the time. That puts the half-success point a
few dB above the receiver's threshold and reaches three nines by roughly 10 dB of
margin, which matches the usual engineering rule of thumb without claiming to be
a measured curve. It is what makes "most reliable" routing meaningful, and it is a
stated assumption, not a prediction of packet error rate. RidgeCast does not
predict packet error rate.

**Throughput** rests entirely on the assumed PHY rate, as described in §9.

And one rule runs through every result in the window: **an input that is
genuinely unavailable is reported as unavailable, never as a zero.** A population
figure of 0 means the analysis measured no affected population. It never means
the analysis could not measure. Coverage-weighted results read the last
calculated coverage and need the serving margins retained by **Best Unit**,
**Redundancy**, or **Unique Coverage**. **Max Fade Margin** does not retain them,
so those columns can report unavailable. Use Best Unit for the usual multi-node
service analysis. Unique Coverage also evaluates other eligible nodes for
comparison: the retained margins used by analysis are not restricted to the
exclusive cells visible on its map.

Any result table can be copied as CSV.

## 13. What this cannot tell you

- **It does not simulate traffic.** There is no packet-level model, no queueing,
  no MAC. Throughput is three closed-form bounds, not a simulation.
- **Channel plans are authored contention assumptions.** They do not change
  the single network-wide RF frequency or permit general multi-radio concurrency.
- **Latency is an explicit assumed/measured input** (§7), with no queueing or
  packet-level prediction.
- **Shared-risk independence is only as good as the labels you entered** (§8),
  and nothing infers them.
- **Every graph property inherits every propagation assumption.** If the link
  predictions are optimistic, the reachability, criticality, and service results
  built on them are optimistic in exactly the same way. Analysis measures the
  network RidgeCast predicted, not the network you will build.

---

## Where else to look

- **[Coverage maps](coverage.md)** — where the coverage that Population Service,
  the N-1 sweep, and candidate ranking read comes from, and why **Best Unit** is
  the merge mode they need.
- **[From transmit power to fade margin](link-budget-and-noise.md)** — where the
  fade margin every analysis thresholds on actually comes from.
- **[Finding sites](site-finder.md)** — choosing a location before it is a node,
  which is the question candidate ranking cannot answer.
- **[Network-analysis commands](../reference/network-analysis.md)** — the menu
  items, requirements, and controls these concepts sit behind.
