# Network-analysis commands

Graph analyses generally require at least two enabled radio nodes and calculated
directed links. The menu tooltips list each command's prerequisites and explain
why unavailable commands are disabled. Graph results appear in **Analysis
Results**, record their assumptions, and are marked stale when the network
changes. Transmitter Height Impact uses its own comparison window and requires
one enabled transmitter.

| Command | Result | Additional requirements |
| --- | --- | --- |
| **Backbone Connectivity** | Two-way, downlink-only, uplink-only, or disconnected state and hop distance from a hub | At least one Backbone Hub |
| **Critical Nodes / Articulation Points** | Nodes and links whose loss splits the network, including backbone-service impact | At least one Backbone Hub |
| **Single-Node Failure Sweep (N-1)** | Ranking of individual site failures by impact | At least one Backbone Hub; qualifying coverage adds population columns |
| **Best Route** | One route under the selected objective and its limiting factors | Exactly two selected nodes |
| **Best 5 Routes…** | Up to five distinct routes, ordered by fewest hops or highest estimated reliability chosen in the dialog | Exactly two selected nodes and calculated links |
| **Independent Routes** | Edge-, node-, or shared-risk-disjoint paths | Exactly two selected nodes |
| **End-to-End Throughput** | Multi-hop throughput estimates | Exactly two selected nodes and a nonzero assumed PHY rate |
| **Simulate Selected Node Failure** | Service effect of losing one chosen site | At least one Backbone Hub and exactly one selected node |
| **Population Service** | Coverage cells and population lost with a selected node | Backbone Hub, one selected node, and qualifying coverage |
| **Critical Facility Service** | Named facility status before and after a selected node failure | Backbone Hub, one selected node, and saved/imported facility inventory; RFPoint facilities require receiver settings and available RF data |
| **Rank Candidate Sites** | Independent coverage, population, resilience, route and facility gains | A noncandidate Backbone Hub and selected calculated candidate nodes; coverage/population, route pair and inventory enable their respective dimensions |
| **Transmitter Height Impact** | Gained, lost, and net covered area between two heights; area by height; or an animated GIF across a height range | One enabled transmitter |

Absent inventory reports unavailable; an explicitly empty inventory reports zero
facilities. An unavailable RF path produces an unknown facility status, never a
successful service claim.

**Analysis → Routes → Best 5 Routes…** asks for a route objective before running.
Distinct routes may share nodes and links; use **Independent Routes** when you
need disjoint alternatives. Other immediate analyses run with the assumptions
already set in **Analysis Results**. **Analysis → Planning → Site Finder** scans
potential locations rather than ranking existing candidate nodes.

## Assumptions

The analysis panel controls:

- Minimum usable link margin
- Required service direction: downlink, uplink, or both
- Assumed PHY rate, including MeshCore, Meshtastic LongFast, and APRS presets
- Route objective
- Route-independence definition
- N-1 sweep scope
- Exact contention mode
- Optional uniform assumed delay in ms/hop, including a genuine zero cost
- Named saved profile and candidate dimension weights
- Optional fixed source/destination pair for candidate route-count gains

The profile is stored with the network. Changing assumptions records an undoable
edit and cancels a running analysis. **Copy report JSON** includes the profile
identity, immutable assumptions and result table used by the worker.

Open **Assumptions → Edit directed inputs and facility inventory** to edit the
saved JSON arrays, or **Import facility JSON file…** to import an inventory on a
worker. Validation errors retain the existing inputs. Pair-keyed directed inputs
are independent of calculated links, so recalculation and temporary RF
unreachability preserve them. Undo, save/open, merges and ID compaction preserve
the authored inputs; merging retains the destination network's profile.

```json
[
  {"source_id": 1, "target_id": 2, "channel_id": "planning-channel-A",
   "radio_id_from": "radio0", "radio_id_to": "radio0",
   "phy_rate_bps": 1200, "latency_ms": 4.5,
   "latency_provenance": "measured round-trip / 2, 2026-10-01"}
]
```

Channel labels express an authored contention assumption; RF calculations still
use the network frequency. Radio labels are scoped by node and cannot make a
shared endpoint full duplex. Missing channels conservatively contend. An omitted
rate/delay uses its global fallback; rate zero explicitly means unknown. Delay
zero is a genuine cost, while missing delays remain unavailable and cannot act
as zero-cost shortcuts. Negative and nonfinite values are rejected by editors.

### Authored facility inventory

A facility array uses stable IDs, names and latitude/longitude in degrees:

```json
[
  {"id":"hospital","name":"Community Hospital","lat":47.4,"lon":-122.1,
   "service":{"mode":"graph_node","node_id":2}},
  {"id":"shelter","name":"Emergency Shelter","lat":47.42,"lon":-122.12,
   "service":{"mode":"rf_point","two_way":true,
              "receiver":{"id":0,"lat":0,"lon":0,"antenna_height_agl":2,
                          "tx_power_dbm":20,"rx_sensitivity_dbm":-110,
                          "antenna_gain_dbi":0,"system_loss_db":0}}}
]
```

GraphNode service follows the attached node's reachability under the selected
policy and direction. RFPoint uses the explicit receiver profile at the facility
coordinates: an enabled backbone-connected site must meet the minimum fade
margin. With `two_way:true`, both directional budgets must pass for that same
site. The receiver may select a saved `system_id`; missing systems/terrain report
unknown. Facilities CSV preserves named IDs, baseline/failure statuses and
unavailability reasons. `null` means no inventory; `[]` is an authored empty one.

Candidate ranking excludes every candidate from the baseline, then adds each
one separately. The fixed target set is enabled noncandidate nonhub RF nodes.
Resilience gain is the reduction in total backbone-disconnected surviving targets
across identical single-baseline-node failures. Route gain is an exact
node-disjoint count change for the selected pair. Facility gain counts known
unserved-to-served transitions; unknown facility inputs exclude that dimension.
Each measured dimension is normalized against its best candidate, then combined
with equal default weights over available dimensions. Zero weights exclude a
dimension. The worker is cancellable and limited to 512 candidate sites per run.

Per-link success probability is derived from fade margin by a logistic curve; it
is not a measured reliability value. Throughput is based on the assumed PHY
rate. When a required input is unavailable, RidgeCast reports it as unavailable
rather than substituting zero.

See [Analyze network resilience](../how-to/analyze-network-resilience.md) and
[Network analysis](../concepts/network-analysis.md).
