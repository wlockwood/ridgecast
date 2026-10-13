# Propose a repeater chain

Use this tool to find possible repeater positions between two existing network
nodes. It makes a bounded planning proposal; it cannot prove that no other route
exists outside the area it searches.

1. Load NLCD land-cover tiles for the area. The search only considers repeater
   sites in loaded tiles with a recognized class. [Prepare an area for offline
   work](work-offline-and-manage-caches.md) if needed.
   Use **Layers → Data preparation → Prepare Offline Area → Check Availability** for the
   corridor's bounds; download missing land-cover tiles and recheck before
   searching. A missing-data result means the candidate ground was unavailable,
   not that the radio budget failed.
2. Select exactly two enabled network nodes. Right-click the map and choose
   **Propose Repeater Chain**.
3. Set a **Maximum hop** distance, a **Minimum fade margin**, and the land-cover
   classes where a repeater may be placed. Missing tiles and NoData pixels can
   never be allowed by a class checkbox.
4. Choose **Search**. Read any missing-data or no-route message. A cyan line
   and circles preview a result; the window lists proposed coordinates and the
   lower of the two directional fade margins for each hop.
   Each hop must meet the larger of your requested **Minimum fade margin** and
   the network's Marginal SNR cutoff in both directions. For example, 8 dB
   forward and 12 dB reverse display as 8 dB; with a 0 dB network cutoff, that
   hop passes a 5 dB requirement but fails a 10 dB requirement.
5. Choose **Apply repeater nodes** only after reviewing the preview. This adds
   the nodes as one undoable step. Wait for network link recalculation, inspect each path,
   and confirm access, land ownership, power, antenna mounting, and regulations
   before treating the locations as usable.

The search samples three parallel candidate positions at each station across a
narrow corridor. It checks at most 24 station intervals and 1,200 potential
hops. A station is roughly 60% of the hop limit from the next one; side
candidates sit one quarter of the hop limit to either side. The shortest route
found through those candidates is proposed. Try another endpoint pair or a
different hop limit if the bounded search finds no route.

Enable **Use supplied candidate sites** to search an explicit list instead.
**Copy visible network markers as candidates** preserves marker IDs and coordinates.
Alternatively enter JSON such as
`[{"id":"tower-a","lat":47.0,"lon":-122.0,"provenance":"provided tower inventory"}]`.
Supply 1–32 unique candidates; the planner can use detours outside the generated
corridor and visit them in a different order. Supplied sites still require known
allowed land cover and qualifying RF hops. Missing tiles and NoData remain
unavailable. The search evaluates at most 1,200 candidate edges and preserves
candidate IDs and supplied provenance in the preview and applied nodes.

**Optional placement exclusion polygons** accepts
`[{"id":"no-mast","vertices":[[47.0,-122.0],[47.0,-121.9],[47.1,-122.0]]}]`.
Vertices are latitude then longitude, with at most 32 polygons and 256 vertices
per polygon. Interior and boundary candidates are excluded in either mode.
These are explicit placement constraints; land-cover classes do not imply
ownership, access permission, or construction feasibility. Existing endpoints
remain endpoints; exclusions apply to proposed intermediate placements.

For each possible hop, RidgeCast samples the terrain profile, applies the
selected propagation model and enabled categorical land-cover clutter, and
requires the requested fade margin and the network's SNR cutoff in both
directions. Receiver noise uses the same ambient-noise model and population
data as network link recalculation. A hop with missing terrain or required
land-cover data is reported as unavailable, rather than as a weak radio link.
The proposed repeaters copy the lower-ID endpoint's
effective radio settings, with an omnidirectional antenna. The search does not
build measured LiDAR surfaces, model access or construction feasibility, or
create links directly; it starts the normal network link recalculation after
the nodes are added. Calculated links can differ if measured LiDAR surfaces or
new data become available, so inspect the recalculated links.

## Search rules and limits

These are the exact rules behind the bounded search, for when a result surprises
you.

**Inputs.** **Maximum hop** must be 500 m to 50 km. The two endpoints must be
distinct and within 85 degrees of the equator, and the search does not cross the
date line. If the endpoints are already within the hop limit and a direct hop
meets the requirement, the search stops with "no repeater is needed".

**Corridor candidates.** The line between the endpoints is divided into
`ceil(distance / (0.6 x maximum hop))` sections, at least two. More than 24
sections is refused, so the longest section you can plan is about
`24 x 0.6 x maximum hop` (14.4 times the hop limit). At each interior station
there are three candidates: on the line and one quarter of the hop limit to
either side. A candidate is dropped, and counted, if it is inside an exclusion
polygon, its land-cover tile is not loaded (missing), its pixel is NoData, or
its class is not in the allowed list. A candidate may link to any later station,
not just the next one, if it is within the hop limit.

**Supplied candidates** are sorted by ID so the result is repeatable, and they
form a general graph: any candidate may link to any other within the hop limit,
in any order. A supplied site that coincides with an endpoint (within 1 m) is
rejected with an error rather than ignored.

**Hop checks.** Each candidate hop samples the terrain about every 30 m (at
least 10 and at most 600 points) and, if land-cover clutter is enabled, the
land-cover class along the same line. A hop is *unavailable* (not weak) if any
elevation came from the constant fallback rather than real terrain, any class is
NoData, or a receiver noise floor could not be computed. Otherwise both
directions are evaluated with each radio's antenna gain along the actual
bearing, and the hop's margin is the smaller of the two. It passes when it is at
least the larger of your **Minimum fade margin** and the network's Marginal SNR
cutoff. Radios must also be able to link (node types are compatible).

**Choosing the route.** Each hop costs 1 plus a tiebreak smaller than 0.01 that
favors a stronger margin, so the proposal always has the **fewest hops** that
works, and among equal-length chains the one with the stronger hops. Equal costs
in supplied mode prefer the earlier-sorted predecessor. At most 1,200 hops are
evaluated in total; reaching that limit ends the search with an error that says
so, which is different from "no route found" (whose message also reports how many
candidates lacked land cover, had NoData, and how many hops lacked data).

**If the settings change mid-search.** Changing the propagation settings, or
canceling, ends the search with "Search again" rather than returning a proposal
made under mixed assumptions.
