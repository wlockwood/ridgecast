# Analyze network resilience

Use this guide after RidgeCast has calculated the network's directed links. A
directed link is a predicted one-way radio path; both directions may differ.
After importing or changing sites, choose **Analysis → Recalculate → All Links** and
wait for **Calculation Progress** to finish before running an analysis.

A **Backbone Hub** is a gateway or central site the rest of the network should
reach. A **Risk Group** is a label shared by sites that can fail together, such
as those on one tower or power source.

1. Edit at least one central node and enable **Backbone Hub**.
2. Add **Risk Groups** to nodes that share a tower, power source, backhaul, or
   another failure domain.
3. Choose **Analysis → Analysis Results** and review the assumptions: minimum link
   margin (dB), direction requirement, PHY rate (kbit/s), route objective,
   independence mode, and failure-sweep scope. Name the analysis profile to
   identify these saved assumptions in exported results. For latency routing,
   enable the assumed delay in ms/hop or author directed delays.
   Set PHY rate for throughput estimates; it is not needed for the connectivity
   and node-failure steps below.
4. Choose **Analysis → Network Health → Backbone Connectivity** to establish
   the current service state. Its result appears in **Analysis Results**.
5. Choose **Analysis → Network Health → Critical Nodes / Articulation Points**
   for structural cut points.
6. Choose **Analysis → Network Health → Single-Node Failure Sweep (N-1)** to rank
   individual node losses.
7. Select exactly two nodes before running route or end-to-end throughput
   analyses.
8. Re-run an analysis after changing the network; old results are marked stale.

For service and population impact, first calculate coverage in **Best Unit**
mode. Treat success probabilities and throughput as scenario results derived
from the displayed assumptions, not field measurements.

To check a clinic, shelter, or other critical facility, expand **Assumptions**
in **Analysis Results**, then import a facility JSON file or edit the authored
inventory. Attach each facility to a graph node or supply an RF receiver
profile. Select one node, then run **Analysis → Failure & Service Impact → Critical Facility Service**
to compare its failure with the baseline. Unknown RF
inputs remain unknown in the table and CSV.

To compare relay sites, model and calculate links for each candidate, select
those nodes, then run **Analysis → Planning → Rank Candidate Sites**. Set the
optional fixed route pair and dimension weights in **Assumptions**. Each
candidate is added alone to a baseline that excludes all candidates. Coverage
is optional; raw resilience, route, and known facility gains appear beside the
score. Compare scores within the same run.

See [Network-analysis commands](../reference/network-analysis.md) for exact
requirements and [Network analysis](../concepts/network-analysis.md) for the
graph model and interpretation.
