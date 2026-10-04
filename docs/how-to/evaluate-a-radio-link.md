# Evaluate a radio link

Use this guide to inspect whether two configured sites have a usable path under
the current model and assumptions, customize the link profile visualization, and
solve for the minimum antenna heights required to achieve line-of-sight clearance
or a target fade margin.

## Basic link evaluation

1. Confirm that both nodes have the intended system, antenna height, gain,
   power, losses, bandwidth, and noise figure.
2. Choose the application-wide model under **Settings → Application Preferences → Propagation**.
3. Select the first node, then **Shift-click** the second.
4. Wait for terrain, land-cover, and optional LiDAR work to finish.
5. Open the link profile window and inspect terrain, the line-of-sight ray,
   Fresnel zone boundaries, and antenna beam patterns.
6. Read each antenna's beam on the same plot. Its two −3 dB edges open along
   the path with a dashed boresight between them, so you can see whether the far
   end sits inside the beam or above or below it, and the small shaded fan at
   the antenna shows the beam's true width. Trust the fan, not the edges, for
   the angle: the chart stretches height against distance, so the edges look far
   wider than the beam is, and the key names the stretch factor. Edges drawn
   faintly mean that antenna's azimuth points away from this path, so the
   elevation cut is through a direction it is not covering. Either way the fix
   is usually a different azimuth or tilt rather than a different radio. Hover
   any part of a beam to have it name itself, or tick **True Scale** to redraw
   the chart with both axes at the same scale, where the edges can be read as
   angles directly. **Reset View** (or a double-click) puts the plot back to the
   whole path after zooming.
7. Tick **Flatten Earth** if you would rather read true terrain elevations
   than judge clearance by eye. It redraws the ground at its real height and
   bows the line of sight, Fresnel envelope, and antenna beams instead. Neither
   view changes anything that is calculated.
8. Compare both directions when the two nodes use different equipment or settings.
9. Review received level, effective noise floor, fade margin, warnings, and the
   prediction-method provenance before accepting the path.
10. Change one assumption at a time and recalculate when comparing systems or
    propagation models.

A dashed provisional link is visual guidance and is not a persisted calculated
network link. Field-check important paths and independently validate results
used for regulatory or safety decisions.

Selected and provisional map paths calculate every SNR point with the model
settings captured when their calculation is requested. They reuse cached LiDAR
and load cached land-cover classes before applying measured clutter, so water
keeps its categorical height even on the first calculation.

Opening an individual link profile prepares its enabled ITM LiDAR corridor and
node surfaces on a background worker. Use **Cancel preparation** to stop that
request, or **Refresh profile** to retry it. Changing either endpoint, radio
settings, or propagation settings supersedes the old request; an old completion
cannot replace the new profile. The height solver uses the same prepared profile.
Choosing **Show Link Profile** again for the same pair keeps the completed
profile visible. Use **Refresh profile** to prepare that path again.

The **Surface** line reports measured LiDAR, a partial measured/categorical mix,
or categorical clutter. These labels summarize valid measurements at the profile
probes; they are not survey-confidence estimates. **Cold cache** means at least
one required surface was initially unavailable; **warm cache** means preparation
reused existing surfaces. Offline mode is reported alongside either result, and
unavailable cells retain categorical clutter. A running or displayed calculation
keeps its original surfaces when another job adds cached data. Choose **Refresh
profile** to include that new data explicitly.

Network links, profiles, and terminal heights select overlapping crops in the
same order: finer resolution first, then link corridors before node blobs, then
smaller footprints, with a stable tie-breaker. A missing cell continues to the
next crop. Opening a profile can therefore improve a previously categorical
preview; the surface status makes that difference visible. Coverage previews
remain categorical, and Site Finder and repeater candidate searches do not
download LiDAR for each candidate. LiDAR preparation remains limited to ITM.

## Collapsible sidebar and feature controls

The link profile window includes a collapsible sidebar on the left side (toggle it
using the **Sidebar** button in the header bar):

- **Features**: Toggle individual visual elements on or off to focus on the layers
  relevant to your inspection:
  - **Ground Terrain**: Bare Earth elevation profile along the path.
  - **Land Cover / Clutter**: Land cover clutter height blocks and measured LiDAR surface elevation overlays.
  - **Line of Sight**: Direct optical ray between antenna phase centers.
  - **Fresnel Zone (100%)**: Outer boundary envelope of the first Fresnel zone.
  - **60% Fresnel Clearance**: The critical 0.6 × F1 inner clearance boundary; keeping terrain and clutter below this line prevents significant diffraction losses.
  - **Antenna Beams**: 3 dB beam edge boundaries and beam classification key.
  - **Sea Level Reference**: The 0 m elevation datum line.
  - **Summary Bar**: The top metrics banner showing path loss, path distance, RF frequency, received power, effective noise floor, and fade margin.
- **Projection**:
  - **Flatten Earth**: Toggles between curved Earth curvature bulge and flat ground projection.
  - **True Scale**: Sets a 1:1 vertical-to-horizontal aspect ratio for accurate beam launch angle reading.
  - **Reset View**: Reframes the entire link profile extent.

## Solve antenna heights

When a link is obstructed by terrain, clutter, or Earth bulge, or when fade margin
is insufficient, use the **Solve Height…** tool inside the sidebar to automatically
find the minimum required antenna heights:

1. **Pick which endpoint(s) may change**:
   - **Source only**: Keeps the target antenna at its current height and searches only for the minimum source antenna height.
   - **Target only**: Keeps the source antenna at its current height and searches only for the minimum target antenna height.
   - **Both (equal height)**: Varies both antenna heights together to find the lowest common height that satisfies the goal.
   - **Both (independent)**: Evaluates combinations of source and target heights to find the pair with the lowest combined tower height.
2. **Choose the target criterion**:
   - **≥60% Fresnel clearance**: Solves for the lowest antenna height(s) ensuring at least 60% first-Fresnel zone clearance over all terrain, clutter, and Earth bulge across the entire path.
   - **Target fade margin**: Uses the selected propagation model and radio budget to find the minimum height(s) achieving the specified fade margin in decibels (dB). The P.1812-inspired option is a terrain-only approximation, not a complete ITU-R P.1812 implementation.
3. **Set max height**: Enter the maximum allowable antenna height above ground level (AGL in meters) to bound the search.
4. **Run the search**: Click **Solve Height**. The search executes on a background worker thread without blocking the user interface. You can click **Cancel** at any time while the search is running.
5. **Review and apply**:
   - The tool reports the discovered minimum heights along with the resulting fade margin (dB) and Fresnel clearance percentage.
   - Click **Apply** to write the solved antenna height(s) directly to the node profiles in the network.
   - The application automatically triggers link recalculation. Applying solved heights is fully undoable via **Edit → Undo** (or `Ctrl+Z`).

Choose **Fresnel clearance** to solve a geometry question: how high must the
antennas be to keep obstacles out of the specified part of the path's radio
wave zone? Choose **Target fade margin** to solve a signal-budget question using
your radios and the selected model. Clearance alone does not establish that a
receiver can hear the signal, and neither target guarantees a working field link.

## Understanding the metrics

For a quick reading of the result: received level and effective noise floor are
both powers in dBm; their difference is fade margin/SNR in dB. A larger positive
margin is more modeled headroom, but it is not a universal pass/fail rule. Use
your radio's required performance, the configured margin bands, and field
validation to decide whether a path is acceptable.

See [Propagation settings](../reference/propagation-settings.md),
[Choosing a propagation model](../concepts/propagation-models.md), and
[From transmit power to fade margin](../concepts/link-budget-and-noise.md).
