# Propagation model decisions

This record describes RidgeCast's supported propagation and measured-surface
workflows.

## Application-wide model selection

RidgeCast applies one propagation model to network links, coverage, Site Finder,
link previews, amateur-link analysis, and diagnostics:

- **ITM / Longley-Rice** is the default terrain model.
- **Terrain diffraction (P.1812-inspired)** provides a terrain-only comparison.

The selected model is process-wide. Coverage-cache entries include the effective
model and P.1812 time percentage, so cached results from one model cannot be
returned for the other.

The approximation uses physical antenna height above local ground and a
bare-earth profile. Endpoint clutter does not move the terminals or add a
separate loss. ITM retains its established clutter-effective endpoint-height
convention. Saved time-percentage values are normalized to 50% because the
approximation implements no variability mechanisms.

The MCP input still accepts values from 1 to 99 for compatibility, but configuring
the engine normalizes the effective value to 50; `describe_settings` reports
that normalized value. An input-change message can echo the requested percentage
without it changing the prediction. Use 50 explicitly; other percentages cannot
request reliability or time-availability scenarios from this approximation.

## Measured LiDAR surface tiles for ITM

ITM can optionally replace categorical land-cover clutter with measured LiDAR
surface data in either of two scopes:

- a bounded four-connected NLCD component around a node (same-class raster
  pixels joined through shared edges, not diagonal corners); and
- a narrow node-to-node corridor, prepared only after the pair clears the
  free-space admission gate.

The selected DEM remains the authoritative bare-earth elevation. LiDAR provides
an above-ground obstruction height, `max(DSM - DTM, 0)`, and a diagnostic return
density. Raw DSM elevations are never spliced into the DEM because the source
vertical datums and acquisition dates can differ.

NLCD determines clutter type and attenuation density; LiDAR determines measured
height. Its return-density ratio does not alter attenuation because return counts
are not pulse-penetration measurements. Missing LiDAR samples retain categorical
clutter rather than being interpreted as open space.

## Surface preparation and caching

LiDAR preparation runs outside UI and Rayon profile-evaluation paths. Surface
areas are content-addressed and stored under the managed `lidar` cache root,
with separate budgets for derived DSM/DTM surfaces and raw point clouds.

The cache key covers source, acquisition identity, geometry, resolution,
context margin, material mapping, and algorithm versions. It intentionally
excludes RF settings because changing power, gain, or sensitivity cannot change
the ground surface.

Link corridors use a local frame aligned to the path bearing, limiting the
raster area required for diagonal links. Node components use north-up local
frames so nearby requests can share cached surfaces. Cached areas may be reused
only when their complete preparation polygon contains the new request.

## Data quality and bounds

Surface preparation is bounded by the free-space gate, node-component radius,
corridor width, context margin, and decoded-memory cache limit. The process
keeps categorical clutter when data is unavailable; it does not invent measured
surface values.

DSM/DTM extraction is a preparation step rather than a propagation model. Once
a surface is cached, link evaluation and map rendering read the stored data and
do not perform further data extraction.
