# MCP server

`ridgecast-mcp` exposes RidgeCast's planning engine over the
[Model Context Protocol](https://modelcontextprotocol.io). It runs headless and
shares the desktop application's caches. To set it up, see
[Drive RidgeCast from an AI assistant](../how-to/drive-ridgecast-from-an-ai-assistant.md).

Distances are metres, frequencies MHz, power dBm, gain dBi, and margins dB
throughout. Angles are degrees true.

`start_interference_scenario` runs a cancellable CPU job with up to 64 named
co-channel transmitters and explicit overlap/background assumptions, reporting
desired/background/source powers, legacy SNR and scenario SINR separately.
See [scenario inputs and policies](interference-scenarios.md). The ordinary
`evaluate_link` response remains unchanged.

`configure_atmospheric_noise(session_id, enabled, month, utc_hour)` selects
verified bundled P.372 14.3 atmospheric coefficients for 20–30 MHz with measured
floors retaining precedence. `change_settings` accepts
`propagation_model: "p1812_complete"` plus validated `p1812_complete` inputs for
the complete outdoor P.1812 CPU backend. Exact revisions, supported inputs and
scientific gates are documented in [optional scientific CPU models](scientific-models.md).

---

## Invocation

```
ridgecast-mcp [--cache-dir <PATH>] [--offline] [--gpu] [--limitation-log <PATH>]
```

| Option | Default | Effect |
| --- | --- | --- |
| `--cache-dir` | the desktop application's cache root | Terrain, land-cover and population cache root |
| `--offline` | off | Never download; uncached data is reported unavailable |
| `--gpu` | off | Use GPU acceleration where the propagation model allows it |
| `--limitation-log` | `docs/review/mcp-limitations.md` | Where `report_limitation` appends |

The limitation-log path is relative to the server's working directory, not the
executable. The same default applies to source and packaged servers. Parent
directories are created on first report; an unwritable path makes that report
fail. For a package or client launched elsewhere, set an absolute path in a
writable user-owned folder, for example
`--limitation-log C:/Users/YourName/RidgeCast/mcp-limitations.md` on Windows.

The protocol runs on standard input and output. Diagnostics go to standard
error, so nothing the engine prints can corrupt the protocol stream.

The server never calls `register_main_thread`. A thread registered there skips
terrain downloads and solves links serially, which would silently produce empty
results; see `src/engine/terrain/mod.rs`.

## Sessions

A session is one network held in memory, addressed by an opaque handle.

- **Nothing is opened implicitly.** There is no equivalent of the application's
  startup behaviour, which reopens the network the previous run had open.
- **Nothing is written implicitly.** Edits change memory only.
- Handles are strings such as `maplemesh-network-1`. Do not parse them.

| Tool | Arguments | Result |
| --- | --- | --- |
| `open_network` | `path` | Handle and summary. Notes when legacy string node IDs were migrated on load |
| `create_network` | `frequency_mhz?` | Handle for an empty network. Frequency 1–6000, default 910.525 |
| `list_sessions` | — | Summary of every open session |
| `describe_network` | `session_id`, `include_nodes?`, `include_links?` | Totals, extent, system profiles, and optionally nodes and links |
| `save_network` | `session_id`, `path`, `overwrite?` | Written path. Fails on an existing file unless `overwrite` is true |
| `close_session` | `session_id` | Whether unsaved changes were discarded |
| `merge_network` | `session_id`, `path` | Counts, plus notes on skipped names, renamed profiles and frequency mismatch |

`include_nodes` defaults to true; `include_links` to false. Opening a network
restores any directed links saved in that file. A newly created network has no
calculated links. Saved links may reflect older radio inputs or model settings;
solve again when those assumptions change.

Merging matches nodes by name. An incoming node whose name already exists is
skipped, never duplicated or overwritten. Imported nodes are modelled at the open
network's frequency, which the result states when the two differ.

## Nodes

Nodes are referred to by numeric ID, exact name, or shortname. An ambiguous name
is an error naming the candidates rather than a guess.

| Tool | Arguments | Result |
| --- | --- | --- |
| `add_nodes` | `session_id`, `nodes[]` | Assigned IDs and a description of each change |
| `update_node` | `session_id`, `node`, changed fields | Each change in words |
| `remove_nodes` | `session_id`, `nodes[]` | Removed nodes; every link touching them goes too |

Each entry in `nodes[]` needs `name`, `lat` and `lon`. Everything else is
optional and inherited from the system profile: `shortname`, `role`
(`repeater`, `user`, `marker`), `system`, `enabled`, `is_backbone`,
`tx_power_dbm`, `rx_sensitivity_dbm`, `antenna_gain_dbi`, `antenna_height_m`,
`antenna_height_reference` (`ground` or `surface`), `antenna_azimuth_deg`,
`coverage_range_m`, and `shared_risk_groups` (shared tower, generator, backhaul,
or other failure labels). Omission preserves existing risk labels on update;
an explicit empty array clears them.

Every node is validated before any is added, so a bad entry does not leave the
network partly edited. Antenna heights are limited to 0–1000 m and coverage
ranges to 100–500 000 m.

An empty patch is refused rather than silently doing nothing. Supplying
`antenna_azimuth_deg` also makes the antenna directional, and the bearing wraps
into 0–360.

Edits that change position or radio parameters clear the calculated links and
report `links_invalidated`. Label and visibility changes do not.

## Queries

| Tool | Arguments | Result |
| --- | --- | --- |
| `query_point` | `lat`, `lon`, `population_radius_m?` | Elevation and its source, land-cover class with clutter, cached measured surface, population density |
| `terrain_profile` | `from_lat`, `from_lon`, `to_lat`, `to_lon`, `samples?` | Per-step elevation, class and clutter, plus the highest point and source shares |
| `terrain_readiness` | area | Tiles still needed by resolution, and whether the area is ready offline |
| `resolve_place` | `query` | Candidates for a US street address, or an explicit unresolved result |

`population_radius_m` defaults to 1000; a point sample of a population raster is
noisy, so density is averaged over a circle.

`samples` accepts 2–2000 and defaults to roughly one sample per 30 m, matching
the coarsest terrain source. `terrain_profile` describes the ground only and says
nothing about whether a radio path works.

`elevation_source` reports which dataset answered. A value of
`fallback (no data)` means the number should not be trusted, and
`elevation_is_measured` is then false.

`surface_elevation_m` and `measured_obstruction_height_m` come from cached LiDAR
only. Absent values mean no surface has been prepared there, not that nothing is
standing there.

An area is either `bounds` (`min_lat`, `min_lon`, `max_lat`, `max_lon`) or all of
`centre_lat`, `centre_lon` and `radius_m`. A radius produces the enclosing square
box, not a circle, and is capped at 200 km. An under-specified area is refused
rather than defaulted.

For `terrain_readiness`, either of these is a complete arguments object. The
area fields are top-level; there is no enclosing `area` object:

```json
{"bounds":{"min_lat":47.3,"min_lon":-122.1,"max_lat":47.5,"max_lon":-121.9}}
```

```json
{"centre_lat":47.4,"centre_lon":-122.0,"radius_m":5000}
```

Other tools using this area shape can require additional fields, such as a
session ID. Use their argument tables alongside the area fields.

### Place resolution

`resolve_place` handles US street addresses, through the Census locator, plus a
table of US state centres for a two-letter abbreviation.

**Anything else is the caller's responsibility.** City names, businesses, parks and
landmarks return `resolved: false` and are not going to resolve: RidgeCast holds no
point-of-interest dataset and adding one would mean another outbound service to
cache, rate-limit and document, to do a job the calling agent is better placed to
do — it can ask the person to confirm, which this layer cannot.

Because that is a division of responsibility rather than a defect, an unresolvable
name **does not** set `limitation`, and a caller should not file one. Doing so every
time would bury the findings that matter. `limitation` is set only when the
geocoding service itself is unreachable, which is a genuine failure worth recording.

A state abbreviation resolves to a state centre, accurate to hundreds of kilometres.
It is useful for orienting a map and never for siting a radio.

## Link evaluation

| Tool | Arguments | Result |
| --- | --- | --- |
| `evaluate_link` | `session_id?`, `from`, `to`, `frequency_mhz?`, `reference?`, `endpoint_antenna_height_m?` | Full budget in both directions |
| `signal_at_point` | `session_id`, `lat`, `lon`, receiver overrides | Which nodes serve a point, and how well |
| `solve_antenna_height` | `session_id?`, `from`, `to`, a target, `raise?`, `max_height_m?`, `reference?` | The heights the path needs |

An endpoint is `{node}` (needing `session_id`) or `{lat, lon}`. A node reference
takes precedence when both are given.

Coordinate endpoints use the shared test radio: 1.5 m above ground, 22 dBm TX,
0 dBi antenna gain, −100 dBm sensitivity, and 2 dB system loss.
`endpoint_antenna_height_m` overrides their height; named nodes keep their own
resolved radio settings.

`reference` selects what the margin is measured against:

| Value | Meaning |
| --- | --- |
| `noise_floor` (default) | A modelled noise floor for the receiver's location and land cover |
| `sensitivity` | The receiver's rated figure, ignoring local noise. Optimistic wherever man-made noise exists |

`evaluate_link` reports `forward` and `reverse` separately. A link is usable only
when `link_closes_both_ways` is true: asymmetric antennas, system losses and noise
environments routinely make one direction fail.

`fresnel_clearance_ratio` below 0.6 is an obstructed path even when the budget
closes, and `fresnel_clearance_is_adequate` reflects that threshold.
`has_line_of_sight` requires a full clear zone.

`signal_at_point` considers the nearest 24 eligible enabled nodes with resolvable
radio profiles, then skips paths whose configured coverage ranges exclude the
point. It reports serving nodes and rejected nodes with reasons. Rejected nodes
include range skips and unavailable calculations as well as valid RF results
that fail to close. It returns a plain-language `verdict`, the
`receiver_description` it assumed, and an additive `evaluation_scope` object:

| Field in `evaluation_scope` | Meaning |
| --- | --- |
| `eligible_node_count` | Enabled nodes with resolvable radio profiles |
| `considered_node_count` | Nearest eligible nodes selected before range filtering |
| `node_limit` | Maximum number considered, currently 24 |
| `omitted_by_cap_count` | Eligible nodes outside that nearest subset |
| `skipped_by_range_count` | Considered nodes excluded by their configured ranges |
| `attempted_node_count` | Paths for which a calculation was attempted |
| `evaluated_node_count` | Paths returning a valid RF result, including ones that do not close |
| `unavailable_node_count` | Attempted paths with unavailable data or another calculation error |
| `all_eligible_nodes_evaluated` | Whether every eligible node returned a valid RF result |

Eligible nodes equal considered nodes plus cap omissions. Considered nodes equal
evaluated paths plus range skips plus unavailable paths; attempted paths equal
evaluated paths plus unavailable paths. An empty serving list rules out only
successfully evaluated paths, and cannot establish absence of service when paths
were omitted, skipped, or unavailable. If zero paths were evaluated, the result
gives no RF answer. Use explicit `evaluate_link` calls for other plausible nodes.

Receiver defaults are the shared test radio above; override
with `receiver_antenna_height_m`, `receiver_antenna_gain_dbi` and
`receiver_tx_power_dbm`.

This is the intended answer to "what coverage is there at one address", and is
seconds rather than the minutes a coverage map takes.

### Antenna heights

`solve_antenna_height` is the inverse of `evaluate_link`: instead of asking
whether a path closes at the heights given, it asks what heights would make it
close. It reuses one terrain profile across every height it tries, so it answers
inline.

Give exactly one target: `target_margin_db`, or `aim_for_fresnel: true` for 60%
first-Fresnel-zone clearance. A margin is usually the honest choice, since
closing a link is not the same as making it reliable.

| Argument | Default | Notes |
| --- | --- | --- |
| `raise` | `both_equal` | Also `source`, `target`, `both_independent` |
| `max_height_m` | 60 | 1–1000. A solve that cannot reach the target below this reports failure rather than proposing a mast nobody will build |
| `reference` | `noise_floor` | As for `evaluate_link` |

The result reports the proposed heights against the original ones, the margin and
clearance they achieve, and whether the target was met. The heights are what the
radio needs; whether a structure that tall can be built there is a separate
question, which the assumptions state.

## Links and analysis

A network file stores nodes and any saved directed links. Links are derived
results: opening restores them, but does not prove they match current inputs.
Call `solve_links` when they are absent or radio/model assumptions have changed,
then save explicitly to retain the refreshed results. Analyses require calculated
links; merely opening a file does not trigger a solve.

| Tool | Arguments | Result |
| --- | --- | --- |
| `solve_links` | `session_id` | Job handle. On success the session holds the links |
| `describe_links` | `session_id` | The links as a whole: counts, margins, extremes, connectivity |
| `analyze_network` | `session_id`, `analysis`, plus per-analysis arguments | A named result with the assumptions it used |

`solve_links` replaces whatever links the session held, because those were solved
against a network that may since have changed. It reports the directed links that
closed, split into pairs that close both ways and pairs that close one way only —
a one-way link is not a usable link. Expect minutes, and a LiDAR download first
where measured surfaces apply.

### Describing the links

`describe_links` answers the questions people ask about a network's links without
returning every one of them — a 70-node network has hundreds, and reading them is
not the same as understanding them. It reports:

| Field | Answers |
| --- | --- |
| `directed_links`, `two_way_pairs`, `one_way_pairs` | "How many links do we have?" |
| `margin_min_db`, `margin_median_db`, `margin_max_db`, `bands` | "How strong are our links?" |
| `strongest`, `weakest`, `longest` | The extremes, named rather than just measured |
| `most_marginal` | Where the network is closest to breaking, weakest first |
| `most_connected` | "What is our most connected node?" |
| `nodes_with_no_links` | Nodes nothing reaches |

`two_way_pairs` is the count that matters: a pair closing one way only looks like
connectivity on a map and is not, which is why `one_way_pairs` is reported
separately rather than folded into a total.

`most_connected` ranks by two-way neighbours first. A one-way neighbour is not
somewhere traffic can go, so it should not lift a node above one with real
connections.

Bands use the network's own thresholds, so "Good" here means the same as it does
on a coverage map of the same network.

### Analyses

| `analysis` | Answers | Needs |
| --- | --- | --- |
| `backbone_connectivity` | Which nodes have a two-way path to a hub, and how far | A backbone hub |
| `critical_nodes` | Nodes whose loss would split the network, worst first | A backbone hub |
| `critical_links` | Links whose loss alone would split the network, weakest first | A backbone hub |
| `best_route` | The single best route between two nodes | `source`, `destination` |
| `independent_routes` | Node, edge, or shared-risk independent routes and cuts | `source`, `destination` |
| `node_failure` | What losing one node would cut off | A backbone hub, `failed_node` |
| `full_n_minus_one` | Every node's failure in turn, ranked by impact | A backbone hub |
| `throughput` | End-to-end rate along the best route | `source`, `destination`, `phy_rate_bps` |
| `facility_service` | Named facility service before and after an optional node failure | A backbone hub, authored facility inventory |
| `rank_candidates` | Coverage, population, resilience, route, and facility gains from each candidate independently | A noncandidate backbone hub, `candidates` |

Shared arguments:

| Argument | Default | Notes |
| --- | --- | --- |
| `minimum_margin_db` | Saved profile, otherwise 0 | Fade margin a link needs to count as usable; raising it prunes marginal links |
| `route_goal` | Saved profile, otherwise `fewest_hops` | Also `highest_reliability`, `strongest_weakest_hop`, `lowest_latency`, `lowest_airtime`, `hybrid` |
| `route_limit` | 3 | 1–10 listed independent routes; the exact node/edge count is separate |
| `independence_mode` | Saved profile, otherwise `node` | `node`, `edge`, or `risk` |
| `ignore_endpoint_risk` | `true` | Routes inherently share endpoints; set false to include their risk labels |
| `risk_pool_cap` | 64 | 1–128 candidate routes for the bounded risk search |
| `phy_rate_bps` | Saved profile, otherwise unknown | Uniform fallback in bit/s; zero explicitly means unknown |
| `latency_ms_per_hop` | Saved profile, otherwise unknown | Uniform assumed delay in ms/hop; zero is a real zero cost |
| `latency_unknown` | `false` | Explicitly override saved uniform delay with unknown |
| `service_direction` | Saved profile, otherwise `two_way` | `two_way`, `downlink`, or `uplink` |
| `exact_contention`, `sweep_articulation_only` | Saved profile, otherwise false | Bounded exact contention and reduced failure-sweep scope |
| `coverage_id` | — | Measured coverage/population for `full_n_minus_one` or `rank_candidates` |
| `as_job` | `false` | Return a cancellable job handle; facility service and candidate ranking always run as jobs |

Explicit arguments override saved assumptions, including zero and false. The
report includes `resolved_profile` and the authored directed inputs, so its
assumptions can be reproduced. Poll jobs with `job_status` and cancel with
`cancel_job`; canceling leaves the session unchanged.

`independent_routes` returns `max_route_count`, `count_is_exact`, `truncated`,
node/edge cuts, shared intermediate nodes and risk labels. Node and edge counts
are exact even when the route list is capped. Risk counts are lower bounds;
`search_bound_reached` and warnings identify bounded searches.

### Authored analysis inputs

Use `edit_analysis_inputs` to persist a version 1 `analysis_profile`, replace a
`facilities` array, or patch `links`. These inputs survive link recalculation,
save/reopen, merge, and node ID compaction. Omitted fields preserve existing
values. `facilities: []` records an empty inventory; `clear_inventory: true`
records unavailable inventory. `clear_profile: true` restores legacy defaults.

```json
{
  "session_id": "SESSION",
  "analysis_profile": {"version": 1, "name": "Winter", "minimum_margin_db": 10, "direction": "two_way", "phy_rate_bps": 1200, "latency_ms_per_hop": 5},
  "links": [{"source": "Hill", "target": "Town", "channel_id": "primary", "radio_id_from": "radio-a", "radio_id_to": "radio-a", "phy_rate_bps": 600, "latency_ms": 8, "latency_provenance": "Assumed relay delay"}],
  "facilities": [{"id": "clinic", "name": "Town clinic", "lat": 40.0, "lon": -105.0, "service": {"mode": "graph_node", "node_id": 2}}]
}
```

Link `source` and `target` accept node IDs, names, or shortnames. Reverse links
need their own entry. Rates use bit/s and delays use milliseconds. Omitted
rate/delay fields preserve overrides; list them in `clear_fields` to restore
the uniform fallback. `remove: true` removes the pair's whole input record.
Radio labels are scoped to their endpoint node. Without labels RidgeCast
conservatively assumes a shared radio/medium.

An RF facility uses `service: {"mode":"rf_point", "receiver": <NodeProfile>,
"two_way":true}` with explicit receiver RF settings. Both directions must pass
at the same backbone-connected serving site. Missing RF inputs or terrain
remain unknown. See [facility JSON and service rules](network-analysis.md#authored-facility-inventory).

For `rank_candidates`, the baseline excludes every candidate, and each is added
alone. Resilience gain counts fewer disconnected surviving fixed noncandidate,
nonhub targets over identical baseline-node failures. Optional `source` and
`destination` enable exact node-disjoint route gain. Known facility inputs enable
facility gain; coverage data enables coverage/population. Scores normalize the
available dimensions within the run and use the saved profile's
`candidate_weights` (all default to one). Raw gains remain in each row. The
candidate cap is 512.

`coverage_id` annotates; it does not re-rank. Rows stay ordered by topological
severity — how many nodes a failure strands — so the failure that costs the most
*people* may not be first. Sort on `population_lost` when that is the question.

Without a `coverage_id` the population figures come back absent rather than zero.
That distinction is deliberate: an absent figure says nobody counted, where a
zero would claim the failure strands nobody.

Nodes are named in results, not indexed. Analyses that reason about reachability
are defined relative to the backbone, so with no node marked `is_backbone` they
report the missing precondition rather than an empty answer. Disabled nodes and
markers are excluded; hidden nodes are included, since hiding is a display
choice.

`strongest_weakest_hop` is usually what "most robust" means: it maximises the
margin of the route's weakest link rather than minimising hops.

Every route reports `weakest_hop` alongside `weakest_hop_margin_db`, naming the
two sites the bottleneck lies between. A margin with no hop attached cannot be
acted on.

`critical_links` is the link counterpart to `critical_nodes`, reported weakest
first: a link that is both the only path across a break *and* marginal is the one
to reinforce. `critical_nodes` reports a `bridge_count`; this names them.

#### The failure sweep

`full_n_minus_one` re-runs reachability once per candidate failure, so it scales
with the node count: expect tens of seconds on a network of any size. It returns
rows worst first, each reporting how many nodes lose backbone service, how the
network fragments, and a `severity` that exists only to give the table a default
order.

Note what it measures. Losing the *only* backbone hub strands everything that
depended on it, so on a network with one hub that hub tops the ranking — which is
correct, and different from an articulation-point analysis. Mark every real
gateway with `is_backbone` for the ranking to mean what you expect.

Pass a `coverage_id` to turn "how many nodes lose service" into "how many people
lose service", which is usually the number that decides anything. The coverage
must retain per-node margins: use `best_unit`, `redundancy`, or `unique`, and
check `has_node_margins`. A `max_margin` run lacks that record and is refused
rather than silently reporting no service loss.
`measured_service_loss` in the result says which of the two you got.

#### Throughput

`throughput` finds the best route and estimates what it carries, accounting for
hops sharing a medium. It needs `phy_rate_bps`; without one the estimate is
`null` rather than zero, because "the rate was never supplied" and "this route
carries nothing" are different claims. `limiting_hop` names the two sites the
bottleneck lies between.

## Coverage

| Tool | Arguments | Result |
| --- | --- | --- |
| `start_coverage` | `session_id`, plus the options below | Job handle; area and population reached per band |

| Argument | Default | Notes |
| --- | --- | --- |
| `nodes` | every enabled node | Transmitters to compute, by ID, name or shortname |
| `points` | — | Transmitters given as locations rather than nodes. See [Coverage from a place that is not a node](#coverage-from-a-place-that-is-not-a-node) |
| `resolution_m` | 100 | 10–5000. Cell size, and the dominant cost |
| `range_m` | 8000 | 500–500 000 |
| `angular_resolution_deg` | 1 | 0.1–30. Coarser leaves gaps between rays at long range |
| `direction` | `tx` | See [Transmit and receive coverage](#transmit-and-receive-coverage) |
| `merge_mode` | `max_margin` | Also `best_unit`, `redundancy`, `unique` |
| `receiver_antenna_height_m` | 1.5 | The assumed receiver, which changes the answer substantially |
| `receiver_antenna_gain_dbi` | 0 | Shared test receiver; system loss is 2 dB |
| `receiver_tx_power_dbm` | 22 | Shared test receiver power, used for uplink coverage |
| `accept_terrain_budget` | false | Proceed past the decoded-terrain budget |
| `include_cells` | false | Return every cell as well as the summary |

| Merge mode | Meaning | Retains serving margins for analysis? |
| --- | --- | --- |
| `max_margin` | Strongest fade margin from the evaluated transmitters at each cell | No |
| `best_unit` | Which evaluated transmitter has the strongest qualifying margin | Yes |
| `redundancy` | How many evaluated transmitters qualify at each cell | Yes |
| `unique` | Visible cells with exactly one qualifying evaluated transmitter | Yes |

Use `best_unit` to calculate a network's serving breakdown before a population
failure analysis; use `max_margin` for a strongest-margin map when that breakdown
is unnecessary. The Best Unit threshold is an absolute minimum margin for the
three modes that retain serving margins, not a winner-versus-runner-up gap.

| Tool | Arguments | Result |
| --- | --- | --- |
| `list_coverage` | — | Retained results, newest first, with the total cells held |
| `drop_coverage` | `coverage_id` | Frees one result's cells |

### Coverage from a place that is not a node

`points` computes coverage from somewhere that is not in the network: a candidate
site, a licensee address, a hilltop. Each entry takes `name`, `lat` and `lon`, and
optionally `antenna_height_m`, `tx_power_dbm` and `antenna_gain_dbi`. They can be
combined with `nodes` in one run.

This exists so that comparing candidate locations does not require editing the
network being asked about. The alternative — add a node, run coverage, remove it —
worked, but left a window in which a save would write an imaginary node into
someone's file.

A place uses the unassigned default node radio rather than the run's receiver.
It does not select or inherit a session system profile, so point candidates and
configured network nodes are comparable only when their radio assumptions match.

Specifically, a bare coverage point resolves the unassigned default node radio,
not a system chosen from the session: 22 dBm TX power, 2 dBi antenna gain, 6 m
height above ground, 0 dB system loss, and an omnidirectional antenna. Its receive
defaults are −100 dBm sensitivity, 125 kHz bandwidth, and an unset/inferred noise
figure. The run supplies frequency and environmental settings; a point can
override height, power, and gain. Supply those overrides when comparing with
sites that use a different system profile.

A run is refused before anything downloads if it would exceed 150 000 cells or
40 000 km², with the arithmetic and the advice to raise `resolution_m` or reduce
`range_m`.

### Retained results

A finished run keeps its cells and returns a `coverage_id`. Exporting a map,
ranking sites by the coverage they would *add*, and the coverage-index analyses all
need the cells rather than the summary, and recomputing minutes of work for each
would be absurd.

Retention is bounded by total cells held, not by a count of results: runs vary by
three orders of magnitude, so a count would either waste memory on large ones or
evict small ones needlessly. Past 600 000 cells the oldest are dropped. The result
just stored is never the one evicted, even if it alone exceeds the budget — a
caller that waited minutes for a run must get it back.

`has_node_margins` in a listing says whether a result can drive the analyses that
need a coverage index. Here the Best Unit family means `best_unit`, `redundancy`,
and `unique`. A `max_margin` run does not retain per-node margins, so check this
before calculating a run intended for a service analysis.

A retained result records the session it came from. A caller that has since edited
that network should recompute rather than reuse it.

The default answer is a summary, not the raster: cells per band, area per band,
population reached per band, the extent covered, and a count of cells that could
not be answered because terrain was missing while downloads were off. Those last
are holes in the map that are **not** necessarily uncovered ground. Pass
`include_cells` only when the raw map is needed; a run can produce 150 000 cells.

Areas are hexagonal cell counts times cell area, so they overstate a ragged edge
by up to one cell all round. A cell at or below the marginal threshold is not
counted as covered.

Exceeding the decoded-terrain budget stops the run and reports the size needed
against the budget, plus a `range_m` that would fit.

### Transmit and receive coverage

`direction` chooses which way the signal travels, and the two answers are not
interchangeable.

| Value | Also called | Asks |
| --- | --- | --- |
| `tx` (default) | forward coverage, transmit coverage, downlink | Where these nodes can be **heard** |
| `rx` | reverse coverage, receive coverage, uplink coverage | Where these nodes can **hear** a receiver |
| `two_way` | same-site two-way coverage | Both directions through the same serving node, using the lower directional margin |

They differ whenever the two ends differ in power, gain or antenna height, which
is almost always. A mast with a good antenna can be heard far beyond where it can
hear a handheld answering back — or the reverse, depending on the radios. On
MapleMesh one node's receive coverage reaches 4.36 km² against 2.29 km² transmit,
nearly double.

That matters because a network is only usable where **both** hold. Reporting
transmit coverage alone overstates what a user with a handheld will actually
experience, and nothing in a transmit-only figure reveals it. When someone asks
about coverage without saying which, they usually mean both: use `two_way`.
It computes exact separate TX/RX grids on the CPU, joins by serving site before
choosing the owner, and keeps both raw directional margins. Independent strongest
TX and RX owners cannot manufacture service. Missing directional data stays unknown.

### Mapping the gaps

| Tool | Arguments | Result |
| --- | --- | --- |
| `export_coverage_gaps` | `session_id`, `coverage_id`, area, `threshold_db?`, `output_dir`, `base_filename`, `geotiff?`, `overwrite?` | An inverted coverage map |

Writes `{stem}_gaps.geojson`: one polygon per cell that falls short, each tagged
with `gap_rank` matching `find_coverage_gaps`, its `fade_margin_db` and how far
below the threshold it is. A coverage layer shows where a network reaches; this
shows where it does not, which is the map wanted when the question is what to fix.

Cells with no prediction are not drawn, for the same reason they are not counted
as gaps: unknown ground is not a hole, and mapping it as one would show a problem
that may not exist.

## Jobs

Site scans and chain searches run for minutes, so they return a job handle.

| Tool | Arguments | Result |
| --- | --- | --- |
| `job_status` | `job_id` | State, phase, progress, and the result once finished |
| `list_jobs` | — | Running and recently finished jobs |
| `cancel_job` | `job_id` | Whether it was still running |

Job kinds: `solve_links`, `coverage`, `site_finder`, `repeater_chain`, `network_analysis`.

Handles are numbered within their kind, so the first scan is `site_finder-1`
whatever else has run. A retained coverage result is `covmap-N`, deliberately
unlike the `coverage-N` of the job that produced it: they are different handle
spaces and confusing them should not be possible.

States are `running`, `succeeded`, `failed` and `cancelled`. Cancellation is
cooperative, so a job can report `running` briefly after being cancelled. A panic
inside the engine becomes a failed job rather than ending the server.

The 32 most recent finished jobs are retained; older ones are dropped, since each
holds its whole result in memory.

### Site search

`start_site_finder` scores candidate cells by the usable coverage a transmitter
there would produce.

| Argument | Default | Notes |
| --- | --- | --- |
| area | required | `bounds`, or centre and radius |
| `resolution_m` | 100 | 10–5000. Dominates cost: halving it roughly quadruples the work |
| `range_m` | 8000 | 500–100 000. How far coverage is evaluated around each candidate |
| `frequency_mhz` | session's, else 910.525 | |
| `session_id` | — | Supplies frequency and the coverage thresholds |
| `transmitter_system_id` | Legacy transmitter | Copy a saved transmitter system by ID/name; requires `session_id` |
| `receiver_system_id` | Legacy receiver | Copy a saved reference receiver system by ID/name; requires `session_id` |
| `sample_mode` | `highest` | Also `centre`, `average`, `highest_land_cover` |
| `use_land_cover_clutter` | true | False makes every result optimistic |
| `grade_by_population` | false | Weights scores by population reached |
| `factor_in_noise` | false | Models each candidate's own noise environment |
| `water_weight` | 0 | 0–1, value of open water relative to land |
| `keep_best` | 15 | 1–200 results returned |
| `use_gpu` | false | Legacy ITM environment and compatible radio responses; unsupported inputs fall back to CPU |
| `exclude_coverage_from` | — | A `coverage_id`; ranks candidates by coverage **added** |
| `already_served_at` | `fair` | `marginal`, `fair` or `good` |

A scan is refused before anything downloads if it would evaluate more than
400 000 cells, with the count and the advice to raise `resolution_m`. The
coverage thresholds must decrease: good above fair above marginal.

Results carry `score`, per-band cell counts, `covered_fraction`, and a
`distinct_candidates` total. **Scores compare only within one scan**: they depend
on the thresholds and weights used and are not an absolute quality measure. The
same place reported in more than one streamed chunk is collapsed to one entry.

Every outcome includes an `assumptions` list. It states the spacing, range,
thresholds, transmitter placement, whether clutter was modelled, and whether
served ground was excluded. A ranking read without it is misleading.

#### Ranking by coverage added

By default a scan ranks candidates by the coverage they produce in total. On a
network that already serves a town, the winner is then a hill over that town —
true, and useless for deciding where to extend.

`exclude_coverage_from` takes a `coverage_id` from an earlier `start_coverage` run
and discounts ground that run already serves, so candidates rank by what they would
*add*. `already_served_at` decides how well-served counts as served, and its cutoff
comes from the band thresholds of the run that produced the cells — so "fair or
better" means what it meant when the coverage was computed, not what the scan would
have meant by it.

`transmitter_system_id` and `receiver_system_id` copy fully resolved saved
systems under the session lock. Candidate TX → reference RX is the only scan
direction; geographic azimuths and tilt remain fixed. Omitting both preserves
the historical 10 m TX, 2 m RX, 33 dBm EIRP, 5 dBi receive gain, 2 dB receive
loss, −100 dBm operating threshold, 6 dB noise figure, and 125 kHz bandwidth.
Noise factoring adds the existing environmental penalty to the selected RX
threshold; it does not add another gate. `scan_assumptions` records immutable
versioned inputs and the actual backend. Each candidate includes its evaluated
origin and unavailable sample count, separately from the hex-center coordinates.

With `session_id`, the scan also freezes that session's ambient-noise settings.
Environmental-noise factoring with the optional atmospheric component evaluates
each actual receiver location on CPU; compatible measurements keep precedence.
Unavailable requested atmospheric inputs, including unsupported frequencies,
produce unknown sample counts. A scan without a session uses legacy noise defaults.

The response reports `excluded_served_cells` so a caller can confirm the exclusion
actually took effect before waiting for the scan. `already_served_at` without
`exclude_coverage_from` is an error rather than a silent no-op.

### Repeater chains

`start_repeater_chain` proposes relay sites connecting two places that cannot
reach each other directly.

| Argument | Default | Notes |
| --- | --- | --- |
| `from`, `to` | required | Endpoint form as for `evaluate_link` |
| `session_id` | — | Supplies frequency, thresholds and named nodes |
| `max_hop_m` | 10 000 | 500–50 000. Shorter hops are more robust and widen the search |
| `minimum_margin_db` | 0 | −20 to 40, required in both directions |
| `exclude_land_cover` | — | Class labels or NLCD codes to keep relays off |
| `allow_land_cover` | — | Replaces the default set entirely |
| `relay_antenna_height_m` | the source's | 0–1000 |
| `frequency_mhz` | session's, else 910.525 | |
| `candidate_source` | `corridor` | `corridor` or `supplied` |
| `candidate_sites` | — | Explicit `{id,lat,lon,provenance?}` sites, combined with candidate nodes in supplied mode; at most 32 total |
| `candidate_nodes` | — | Session node/marker references; copies IDs and coordinates, requires `session_id` |
| `exclusion_polygons` | — | `{id,vertices:[[latitude,longitude],...]}`; at most 32 polygons, 256 vertices each |

By default, water, permanent ice, and wetlands are excluded, matching the
application. Supplying `allow_land_cover` replaces this default set entirely with
the explicit allow-list. Give `exclude_land_cover` or `allow_land_cover`, not
both. Classes are accepted as labels (`Evergreen Forest`) or codes.

A route needing more than 40 hops is refused with the arithmetic, since each hop
costs a terrain profile in a widening search.

Supplied mode searches a bounded general graph, so a valid detour may leave
the generated corridor or visit candidates in a different order. Candidate IDs
and provided provenance appear with relays. Explicit exclusions apply to
intermediate placements, including their boundaries. Missing land cover never
becomes an allowed site. A direct qualifying endpoint hop reports that no
repeater is needed.

The result lists relays in order with each hop's margin, the route length against
the straight-line distance, and the `limiting_margin_db` of the weakest hop. If
the endpoints already have a qualifying direct hop within `max_hop_m`, the search
returns an error stating that no repeater is needed. Proposed positions are
ground that works for RF; they carry no information about land ownership,
access, or permission to build, which the assumptions state.

## Export

| Tool | Arguments | Result |
| --- | --- | --- |
| `export_gis` | `session_id`, `output_dir`, `base_filename`, format flags, `coverage_id?`, `only_nodes?`, `overwrite?` | Paths and sizes written |
| `export_coverage` | `coverage_id`, `output_dir`, `base_filename`, `geojson?`, `geotiff?`, `geotiff_mode?`, `overwrite?` | A coverage result on its own |
| `export_links_csv` | `session_id`, `path`, `overwrite?` | Row count |
| `export_site_candidates` | `source_path`, `destination`, `format`, `scope?`, `top_k?`, `selected?`, `overwrite?` | Cancellable job exporting a retained Site Finder JSON scan |

`export_site_candidates` accepts `format: "csv"` or `"geojson"` and
`scope: "full"` (default), `"top_k"`, or `"selected"`. Selected scope uses
up to 10,000 `[latitude,longitude]` hex centers from the saved scan. Rankings
include refinement tiers and remain original ranks when exporting a subset.
Both formats include raw/adjusted scores, counts including unavailable samples,
per-result resolution, center and evaluated-origin coordinates, and original
provenance. Legacy unknown origins are explicitly marked; GeoJSON geometry
uses longitude then latitude. Provenance is stored once per output (the first
CSV row or the GeoJSON FeatureCollection) and referenced by its SHA-256 ID.
Parsing is bounded to 64 MiB and 500,000 candidates. Atomic publication keeps
an existing destination intact on failure or cancellation; use `cancel_job`
on its returned handle to stop it.

Formats: `kml`, `kmz`, `geojson`, `geotiff`. Naming any format replaces the
GeoJSON default rather than adding to it, so asking for KML alone does not also
write GeoJSON.

Filenames are derived from `base_filename`, and are not simply the stem plus an
extension:

| Format | Written as |
| --- | --- |
| KML | `{stem}.kml` |
| KMZ | `{stem}.kmz` |
| GeoJSON | `{stem}_coverage.geojson` and `{stem}_network.geojson` |
| GeoTIFF | `{stem}_coverage.tif` and a `{stem}_coverage.tfw` world file |

`base_filename` must be a filename rather than a path: a separator or `..` is
refused, since it would write outside `output_dir`.

A GeoTIFF is a coverage raster, so it needs `coverage_id` and is refused without
one rather than writing an empty file. `geotiff_mode` selects what each pixel
stores: `colors` (default, the map's own categories), `snr_db` or `rx_power_dbm`
as 32-bit floats.

Written paths are reported as they resolved, not as they were given: a relative
path, or a POSIX-style one passed to a Windows build, lands somewhere the caller
may not expect, and echoing back its own input would leave the file unfindable.

Existing files are never replaced unless `overwrite` is set. The check asks the
writers which paths they will produce rather than guessing, so it covers the
suffixed names above.

A network with no calculated links exports its nodes and says so in `notes`; run
`solve_links` first if the links were wanted.

`export_coverage` writes a retained coverage result on its own, needing only a
`coverage_id`. Use it when the question is "give me that coverage map";
`export_gis` is for when the network's nodes and links are wanted alongside it.
Both write the coverage to the same filenames, from one shared declaration, so
they cannot disagree about where it lands.

Cells with no prediction are reported in `notes`: they are holes in the raster
rather than ground known to be uncovered, and a reader of the file cannot tell the
difference.

**Not available headless:** PNG and animated GIF. RidgeCast renders their labels
through egui's font stack, so producing one would make this path depend on a font
rasterizer in order to draw a picture the calling agent cannot look at. Use the
desktop application.

## Amateur licenses

RidgeCast keeps a local SQLite copy of the FCC ULS amateur catalogue, so "who is
licensed near here" is answerable offline once it is imported.

| Tool | Arguments | Result |
| --- | --- | --- |
| `amateur_catalogue_status` | — | Counts, source date, import date |
| `amateur_licenses_in_bounds` | area, `include_inactive?`, `limit?` | Licenses in the area |
| `amateur_find_callsign` | `callsign` | One license, or not found |
| `refresh_amateur_catalogue` | — | Job handle; downloads and imports |

`limit` defaults to 100 and is capped at 500. The result reports `truncated` when
there are more, because a query over a wide area matches tens of thousands of rows
and a silently cut list reads as a complete one.

Inactive licenses — expired, cancelled, terminated — are excluded unless
`include_inactive` is set.

Two caveats the results carry, and which a caller should pass on:

- **A license address is where the licensee receives post, not where their antenna
  is.** For a club or a repeater trustee it is often a mailing address with no
  radio at it. Treat a license as evidence someone is nearby, not as a site.
- **Addresses without coordinates never appear in a bounds query.** Most of the
  catalogue is in this state, so an empty result is not proof that nobody is
  licensed there. `amateur_catalogue_status` reports how many are affected.

`location_quality` distinguishes an exact address match from a looser one; a
non-exact match can be some distance from the real address.

The catalogue is not shipped. `refresh_amateur_catalogue` downloads hundreds of
megabytes and imports it, so it is a job, and it is refused when the server is
running offline.

## Settings

Every prediction rests on these, and nothing in a result shows which settings
produced it, so two runs made under different settings are not comparable.

| Tool | Arguments | Result |
| --- | --- | --- |
| `describe_settings` | — | Model, clutter, surfaces, offline state, cache root |
| `change_settings` | any of the fields below | What changed, and whether earlier results are invalidated |

| Field | Notes |
| --- | --- |
| `propagation_model` | `itm` (default), `p1812` (existing inspired approximation), or `p1812_complete` (validated complete outdoor CPU method). GPU applies only to supported ITM settings. |
| `itm` | Complete explicit ITM ground, climate, polarization and confidence/reliability object; omission preserves current inputs. |
| `p1812_complete` | Complete versioned environment object: explicit DN/N0/zone, time/location percentages, polarization, resolution and optional coast distances. Missing required inputs prevent complete-model selection. See [scientific inputs](scientific-models.md). |
| `p1812_time_percent` | Input accepts 1–99 for compatibility, but the active approximation normalizes it to 50. It does not calculate time variability. |
| `measured_surfaces_enabled` | Use LiDAR surfaces instead of categorical clutter heights |
| `land_cover_clutter_enabled` | Off makes every prediction optimistic |
| `clutter_heights_m` | `[[class_code, height_m], …]` overrides |
| `offline` | Stop or resume downloads |

These configure process-wide defaults captured by subsequently started jobs.
Already running jobs retain their immutable settings snapshot; `invalidates_results`
reports that older results should be compared using their recorded assumptions.

`describe_settings` reports clutter heights for the classes where they matter most
— forest and developed land — rather than all twenty.

## Systems and imports

| Tool | Arguments | Result |
| --- | --- | --- |
| `upsert_system` | `session_id`, `id`, any radio fields | Created or replaced, with the nodes affected |
| `remove_system` | `session_id`, `id` | Removed |
| `import_radio_mobile` | `session_id`, `path` | Counts and collisions |

A system profile is the radio settings nodes inherit. Reusing an `id` edits that
profile and keeps whatever the call does not name, so a partial edit does not
silently reset the rest of the radio. Editing one changes every node inheriting
from it: `describe_network` reports `used_by_node_count` per profile, which is the
blast radius.

`remove_system` is refused while nodes still use the profile, naming them. Removing
it would make those nodes fall back to defaults, changing every prediction for them
with nothing in the output to show why.

`import_radio_mobile` takes the path prefix without an extension; the importer
reads the matching files beside it. It changes memory only.

## Weak spots in a service area

| Tool | Arguments | Result |
| --- | --- | --- |
| `find_coverage_gaps` | `session_id`, `coverage_id`, area, `threshold_db?` | Weak spots, largest first |

"How much do we cover" is a total and "where should we put a node" is a
recommendation. This is neither: it locates and ranks the problems, which is what
someone asks when they have a service area in mind — a town, a ZIP code, a valley
— and want to know what is wrong with their network now.

Each gap reports its extent, area, cell count, the population living in it, the
best and worst margin inside it, and the nearest existing node, which is usually
where a fix starts. Contiguous weak cells are clustered, so two weak patches
separated by served ground are reported as the two problems they are.

`threshold_db` decides what counts as served, defaulting to the network's own
"fair" band — the level its coverage map already calls usable.

**Ground the coverage never evaluated is not a gap.** An area reaching beyond the
coverage extent sets `area_partly_unevaluated` and says so in `notes`: the part
outside is unknown, and reporting it as a hole would invent a problem or hide a
real one behind a thorough-looking number. Cells whose terrain was unavailable are
counted separately again, as `no_data_cells`.

A service area that is not rectangular — most ZIP codes, towns and districts — has
to be approximated by a bounding box, which includes ground outside it. Resolving
the boundary is the caller's job, as with any place name, and the result should be
reported with that caveat.

## Finding nodes

| Tool | Arguments | Result |
| --- | --- | --- |
| `find_nodes` | `session_id`, `name_contains?`, `area?`, `limit?` | Matching nodes |

Use this rather than `describe_network` when looking for particular nodes. A
70-node network is 41 KB of JSON and a larger one is far more; reading all of it
to find one node wastes the context needed for the actual work. Reports `matched`
against `returned` so a truncated list is never mistaken for a complete one.

## Meta

| Tool | Arguments | Result |
| --- | --- | --- |
| `server_capabilities` | — | Version, cache root, GPU availability, propagation model, and current supported and unsupported lists |
| `report_limitation` | `kind`, `summary`, `request`, `attempted`, `missing`, `suggestion?` | Path written and total entries |

`kind` is one of:

| Kind | Meaning |
| --- | --- |
| `missing_capability` | RidgeCast cannot do this at all |
| `not_exposed` | RidgeCast can, but no tool reaches it |
| `missing_data` | Terrain, population or place data was unavailable |
| `suspect_result` | An answer that looks wrong |
| `awkward_interface` | Possible, but needlessly hard |
| `too_slow` | Worked, but unusably slow |

Entries append to a Markdown file, newest last, one `##` heading each with
labelled lines. An entry missing `summary`, `request`, `attempted` or `missing` is
refused: an entry that cannot be triaged is worse than none. Multi-line pasted
output is flattened so one entry cannot break the file's structure.

## Durable retained coverage

`save_coverage_artifact` accepts `coverage_id`, an explicit `.rccov` `path`, and
optional `overwrite: true`. It starts a cancelable job and publishes a complete
versioned archive atomically. It preserves numeric cells, original per-node
margins, raw directional margins/unknown directions, thresholds, grid settings,
receiver assumptions, propagation/terrain/clutter inputs and network identity.

`load_coverage_artifact` accepts `path` and optional `session_id`. Poll
`job_status` for its fresh `coverage_id`; normal retention and eviction budgets
apply. Loading validates the header/version, expanded/compressed bounds,
checksum, geometry and margin indices. Limits are 64 MiB compressed, 128 MiB
expanded and 150,000 cells. Canceling a load adds no retained result; canceling
a save preserves the previous destination.

Omitting `session_id` loads a historical artifact for standalone export. Passing
a session validates the authored network, node IDs, RF model and source cache
revisions. Analyses, service-loss calculations, gap finding and coverage-added
ranking also check this binding. Editing/compacting node IDs or changing the model
or data rejects reuse and asks for recalculation. Synthetic place transmitters
cannot bind their per-node margins to current network nodes. A historical image
or GIS export remains available without asserting it is current.

## Offline task jobs

`start_offline_task` accepts an explicit `requirements` object and optional
`prepare_online` (default `false`). Inspect-only mode reads source caches on a
worker without provider requests. Preparation visits selected bounded requirements,
then rechecks sampled source data. Poll and cancel it through the usual job tools.

Example terrain/clutter check for one link:

```json
{
  "requirements": {
    "geometry": {
      "task": "links",
      "pairs": [[{"lat":47.6,"lon":-122.3},{"lat":47.61,"lon":-122.31}]],
      "spacing_m": 50
    },
    "land_cover": true,
    "population": false,
    "ambient_noise": false,
    "measured_surfaces": false,
    "max_probes": 10000
  },
  "prepare_online": false
}
```

Other geometry variants use `task: "coverage"` with `centers`, `range_m` and
`resolution_m`, or `task: "site_finder"` with WGS84 `bounds` (`west`, `south`,
`east`, `north`), `range_m`, `resolution_m` and `refinement`. Optional
`basemap_zooms: [min,max]` is reported as unsupported for exact certification;
no all-zoom promise is made. Reports expose ready/missing/partial/unsupported/capped
states, valid probes, file inventory and rough download estimates separately from
calculation-cache reuse. See [offline tasks](../how-to/work-offline-and-manage-caches.md).

## Worker concurrency

Each RF job captures immutable propagation, radio and applicable source/noise
settings before execution. Later settings changes affect new jobs; captured jobs
can finish under their original model and report its provenance. At most four
worker jobs execute concurrently. Requests beyond that cap fail explicitly;
wait for a job to finish before starting another.

Retained coverage also checks model/source settings at completion. If those
settings change while calculation is running, the obsolete result is rejected;
start a new coverage job with the current settings.

Each session has its own lock, so work on one network does not block another. A
coverage run copies the network under that lock and then releases it, so a run
taking minutes does not block other requests against the same session — but it
also means edits made mid-run do not affect it.
Blocking engine work runs on plain threads outside the async runtime, because the
engine reaches the network through a blocking HTTP client that cannot run inside
one.

## Related pages

- [Drive RidgeCast from an AI assistant](../how-to/drive-ridgecast-from-an-ai-assistant.md)
- [Model limitations](model-limitations.md)
- [Propagation settings](propagation-settings.md)
- [Files and interchange formats](files-and-formats.md)
- [Data sources and caches](data-sources-and-caches.md)
