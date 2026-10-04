# Propagation settings

## Advanced ITM inputs

**Advanced ITM environment and statistics** sets relative permittivity (>1),
conductivity (positive S/m), sea-level surface refractivity (250–400 N-units),
one of seven climates, vertical/horizontal polarization, and independent
statistical confidence/reliability (1–99%). **Restore legacy ITM preset** sets
15, 0.005, 301, continental temperate, vertical, and 50/50 exactly. Older files
use this preset. RF jobs snapshot the inputs; coverage identity includes them.
Nonlegacy inputs use CPU and bypass pruning checked only against the old
preset. See [statistical conventions](../concepts/propagation-models.md).
MCP **change_settings** accepts an optional complete `itm` object; settings
reports expose exact inputs and requested percentages.

Choose the application-wide propagation model under **Settings → Application Preferences → Propagation**.
The selection applies consistently to calculated network links, coverage, Site
Finder, previews, amateur links, and diagnostics. Changing it invalidates
affected results; persistent coverage cache entries remain separated by model.

## Propagation models

| Model | Behavior |
| --- | --- |
| **ITM / Longley–Rice** | Default terrain-aware model using the bundled C++ implementation. Supports the optional measured-surface scopes and GPU-assisted interactive approximation. |
| **Terrain diffraction (P.1812-inspired)** | Native free-space plus dominant-edge terrain approximation. It does not implement complete P.1812 or clutter loss and runs on the CPU profile path. |
| **P.1812-7 outdoor (ITU troposcatter correction)** | Separate complete outdoor CPU method with explicit environment and genuine time/location percentages. See [scientific contract and validation](scientific-models.md#complete-outdoor-p1812). |

The inspired model's stored P.1812 time percentage remains normalized to 50%.
The complete model has independent genuine time/location settings. Expand
**Complete P.1812 outdoor assumptions** to enter DN, N0, uniform radio-climatic zone,
time/location percentages, polarization, prediction resolution and optional
coast distances. Its selector remains disabled until required inputs validate.
Missing terrain or required clutter makes a prediction unavailable. MCP
`change_settings` accepts `propagation_model: "p1812_complete"` and a complete
`p1812_complete` object; `describe_settings` reports the revision and inputs.

## Optional ITM measured surfaces

Both scopes are disabled by default.

| Setting | Default | Valid range | Effect |
| --- | ---: | ---: | --- |
| DSM inside node land-cover blobs | Off | On/off | Replaces categorical height inside the bounded connected NLCD component containing each node. |
| DSM along eligible links | Off | On/off | Replaces categorical height in a narrow corridor after the pair passes the free-space reachability gate. |
| LiDAR ground policy | Conservative v1 for new settings | Conservative v1 / Legacy minimum return v1 | Requires bounded classified-ground support, or explicitly allows the earlier unclassified minimum-return estimator. |
| LiDAR source | USGS 3DEP | USGS 3DEP or NOAA Digital Coast | Chooses the public point-cloud catalog. |
| Blob maximum range | 1,000 m | 30–1,000 m | Bounds a node's connected land-cover component. |
| Link half-width | 3 m | 1–25 m | Sets the corridor width on each side of the link centerline. |
| Surface context | 250 m | 25–500 m | Adds context around a node-blob envelope. |
| DSM resolution | 1 m | 0.5–5 m | Sets the derived measured-surface raster resolution. |

Measured data supplies obstruction height above ground. RidgeCast keeps the
selected DEM authoritative for bare-earth elevation instead of splicing raw
LiDAR elevations into it. Stored return-density ratios are diagnostic metadata;
categorical land cover remains the attenuation-density input.

Conservative v1 requires observed classified ground or classified inference
within a 300 m inherited source-cell bound, and observed DSM or filling within
two diagonal cells plus 0.1 m rounding tolerance. Both policies reject failed
source support and retain real classified zero. For a roof-only unclassified
20 m return, legacy estimates ground at 20 m and obstruction at 0 m; conservative
retains the configured categorical height (for example 20 m). Rejected cells
continue to older usable acquisitions before categorical fallback.

Old saved explicit `itm_dsm` objects lacking `ground_policy` deserialize as
`legacy_minimum_return_v1`, preserving their numeric behavior. An absent
`itm_dsm` object keeps DSM disabled. New settings and newly enabled absent
objects use `conservative_v1`. Saved policies are explicit; changing one
invalidates prediction caches while reusing the same supported surface data.
Old derived surfaces lacking support are rebuilt, with raw point clouds reused.
Headless/MCP `change_settings` accepts `lidar_ground_policy` with those same two
versioned strings; `describe_settings` reports the selected policy. Each headless
Engine supplies its own captured policy to point, profile, link and height
requests, even if process-wide compatibility defaults later change.
The map's diagnostic hillshade may still display estimates rejected for RF.
Point reports retain those estimates in `lidar_surface`; the compatibility
`measured_obstruction_height_m` field is populated only for policy-usable data.
`lidar_support` also reports evidence where missing ground or surface prevents
a numeric obstruction height.

Registered local DSM/DTM pairs remain usable under both LiDAR ground policies,
in their configured priority. Point reports retain `lidar_surface` with an
explicit `origin` (`supplied_raster` or `native_lidar`); supplied rasters have
`support: null` and `lidar_support: null`, because native return evidence is
unavailable. `measured_obstruction_height_m` remains the policy-usable numeric
field. A rejected native estimate stays visible in `lidar_surface` while that
compatibility field is empty. Engine queries and map point details use their
own full settings snapshot, including the registered pair list.

Individual link profiles and antenna-height solves explicitly prepare enabled
surfaces in the background. Their status distinguishes measured, partial, and
categorical data, cold/warm cache, and offline operation. **Cancel preparation**
stops a selected profile; **Refresh profile** captures newly available data.
See [Evaluate a radio link](../how-to/evaluate-a-radio-link.md). Each calculation
retains its geometry, source, settings, and rasters for its lifetime. Changing
the selected propagation model affects new calculations; a running network,
coverage, link, or height calculation continues with its captured model. Frozen
contexts retain at most 256 crops and obey the configured decoded-surface memory
budget; a limit is reported and omitted cells use categorical clutter.

Headless link, terrain-profile, and height-solve reports include `surface_status`
with the captured ground policy, usable/total centerline-probe counts,
observed/inferred/estimated ground counts, surface support and rejected/missing
counts, plus preparation/cache state. The older `measured_probes` field is
retained as an alias for `policy_usable_probes`; neither is a survey-confidence
score. Their
cancellable worker APIs accept a caller-owned cancellation flag. Point hover
and broad candidate searches stay cache-only for LiDAR; coverage previews use
categorical clutter. The headless signal-at-point diagnostic also stays
cache-only and includes `surface_status` for each evaluated serving or rejected
node. A rejection before evaluation, such as a node outside its configured
range, has no surface status. P.1812 does not acquire these ITM overlays.

## Ambient noise settings

Ambient noise floor terms are configured per-network under **Settings → Ambient
Noise Settings** (or via **Configure Ambient Noise…** under Propagation in
Application Preferences). Changes are fully undoable (`Ctrl+Z`) and invalidate
affected link evaluations and coverage cache entries:

| Setting | Default | Valid range | Effect |
| --- | ---: | ---: | --- |
| **Model in-band traffic** | On | On/off | Enables or disables modeled unlicensed in-band traffic across all shared spectrum bands. |
| **433 MHz ISM occupancy reference** | 10.0 dB | 0.0–30.0 dB | In-band traffic reference seed in dB above kTB at density index 1.0 (433.05–434.79 MHz). |
| **863–870 MHz SRD occupancy reference** | 8.0 dB | 0.0–30.0 dB | In-band traffic reference seed in dB above kTB at density index 1.0 (863.0–870.0 MHz). |
| **902–928 MHz ISM occupancy reference** | 12.0 dB | 0.0–30.0 dB | In-band traffic reference seed in dB above kTB at density index 1.0 (902.0–928.0 MHz). |
| **Receiver desense** | 6.0 dB | 0.0–20.0 dB | Receiver desensitization from nearby high-power transmitters at density index 1.0; set to 0.0 dB for filtered receivers. |
| **Population weight** | 0.20 | 0.0–1.0 | WorldPop population density contribution to source density index vs NLCD land cover. |
| **Reference density** | 3,000 | 500–10,000 | People/km² mapping to 1.0 source density index (dense urban). |

The in-band traffic and adjacent-band desense terms apply only when the chosen
frequency is inside one of the three listed shared-band ranges. Selection is
by frequency, not license status: an amateur channel inside a listed range gets
that branch too. Outside those ranges, the P.372 man-made-noise term remains
separate, but the shared-band terms are absent. Occupancy seeds are assumptions,
not measured traffic; see [In-band traffic on shared bands](../concepts/link-budget-and-noise.md#mechanism-2-in-band-traffic-on-shared-bands).

See [Choosing a propagation model](../concepts/propagation-models.md),
[From transmit power to fade margin](../concepts/link-budget-and-noise.md), and
[Clutter, LiDAR, and canopy density](../concepts/clutter-and-lidar.md).

In **Ambient Noise Settings**, expand **Atmospheric noise (20–30 MHz)** and
choose **Prepare bundled P.372 atmospheric data**. Set calendar month and UTC
hour; receiver coordinates come from each evaluated location. **Disable
atmospheric component** restores the legacy floor. Pinned offline coefficients
are verified on the worker. Compatible measured floors retain precedence.

MCP `configure_atmospheric_noise` accepts `session_id`, `enabled`, `month` and
`utc_hour`. See [atmospheric assumptions](scientific-models.md#p372-atmospheric-noise-at-2030-mhz).
