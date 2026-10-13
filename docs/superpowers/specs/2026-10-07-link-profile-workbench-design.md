# Link Profile workbench design

Presentation amendment, October 9: [Visual hierarchy revision](../plans/2026-10-09-link-profile-visual-hierarchy.md) proposes grouped endpoint/results, a compact active key, and a collapsed Legend & layers panel with explicit checkboxes. It supersedes the original always-visible off-entry/clickable-label requirements below for the next visual iteration; drawer/sidebar placement is still under review. The original workbench implementation evidence remains in its implementation plan.

Status: planning only. The user requested an implementation plan after the in-chat redesign proposal, explicitly adding clear endpoint labels and a legend. This document records that proposal and those amendments for an executor. It does not authorize implementation or commits.

## Purpose and scope

Help a planner identify the endpoints and assumptions, inspect what obstructs a path, compare both radio directions, and preview antenna-height changes before applying them to the network.

The first release includes the responsive workbench, coherent retained results, endpoint annotations, persistent legend, obstruction/sample inspection, bidirectional budget display, existing solver with before/after preview, clearer data status, CSV action, and Companion Guide. Preserve existing solver modes and undo. Separate endpoint limits, raise-only solving, a both-directions margin objective, image/report exports, retained comparisons, 3D, custom obstacles, throughput, and availability estimates are deferred; do not imply they are present.

## Window and information hierarchy

- Keep one Link Profile owner window through preparing, ready, canceled, and failed states. Default logical size 1100 x 760; clamp to the available screen. Never require a window larger than its viewport.
- Header: `Link Profile: A name ↔ B name`, `Export…`, `Guide`, and a tooltip-equipped close action.
- Compact summary: distance, frequency, prediction method, direct-ray status, 60% Fresnel target status, and both directional received-level/reference/margin rows. Highlight the weaker available direction without inventing a universal pass/fail margin.
- Data-status strip: readable availability/failure warning, `Details` (opens Inputs), `Refresh profile` or `Cancel preparation`. Full source reports live in Inputs.
- Body at >= 900 logical pixels available width: large plot and right inspector. Inspector default width 320, draggable within 280..420 and leaving at least 420 for the plot.
- Below 900: plot above a bounded inspector drawer. Path/Heights/Inputs remain accessible. Inspector content scrolls independently; active solver actions remain reachable.
- Plot fills remaining height rather than imposing a 2:1 window aspect. Reserve actual measured header/legend/footer sizes. On very short displays, use a bounded scroll fallback with all actions reachable; never allocate negative dimensions.
- Inspector tabs: `Path`, `Heights`, `Inputs`. Hiding the inspector leaves summary, endpoint captions, legend, `View…`, and `Fit path` available.

## Endpoint labels: required

- The initially selected source is A at distance 0; the initially selected target is B at the path end. Selecting a reverse budget does not flip the plot, relabel sites, or change solver endpoint ownership.
- Always show endpoint captions adjacent to the plot: `A · <site name>` and `B · <site name>`, configured mounting height, and `above ground` or `above surface`.
- Draw masts and distinguishable A/B antenna markers at the resolved antenna positions. Use the same projection transform as the rays. Use endpoint identity and shape/text, not color alone.
- Panning an endpoint offscreen removes its in-plot marker but retains its external caption; do not pin a false endpoint at the viewport edge. Long or identical names remain distinguishable through A/B and full-name hover/focus details.
- Path inspector shows each endpoint's configured height/reference, bare-ground elevation, obstacle surface elevation, resolved antenna elevation, system and alignment. Configured height is not universally AGL: Surface adds composed surface height before deriving antenna elevation.

## Legend and visual styles: required

- A custom persistent legend names every plotted line and overlay; do not rely solely on egui_plot's legend, because beams and sea level are painter overlays and clutter consists of many polygons.
- Line entries: Ground terrain; Line of sight; First Fresnel zone (100%); 60% Fresnel boundary; A antenna beam; B antenna beam; Sea-level reference; Proposed height geometry when a preview exists. Symbol entries: A endpoint and B endpoint (triangles), Selected point (circle) and Limiting obstruction (diamond) when present.
- Full Fresnel upper/lower boundaries share one explicitly explained envelope entry. Each beam entry shows its endpoint color plus solid -3 dB edges and dashed boresight; the existing angle fan and exaggeration explanation are preserved. Unsupported beam shapes say unavailable rather than implying a drawn beam.
- Surface-color entries name every distinct effective land-cover class used by the retained profile and the neutral unknown-class surface color when present. Precompute the set once on a worker; show compact wrapped/swipable or scrollable rows, never LC polygon IDs. A class color identifies land cover, not measured-vs-estimated provenance.
- Fixed layer entries remain visible when off and say `off`; swatches retain their identifying color. Visibility toggles occur only in this legend. Beams may be one grouped toggle with separate A/B entries. Sea level is controlled here, not repeated in View.
- One shared style definition supplies rendering and legend swatches. Ground: RGB 166,124,82, solid; LOS: RGB 225,229,235, solid; full Fresnel: RGB 225,199,90, solid; 60% boundary: RGB 244,153,66, dashed; A beam: existing cyan style; B beam: existing magenta style; sea level: existing blue style; proposal: RGB 130,183,255, dashed. Keep existing land-cover class colors.
- Default visible: terrain, obstacle surface, LOS, 60% boundary. Default off: full Fresnel, beams, sea level. Legend is always visible; no Summary Bar toggle. Display-only changes never rerun propagation.
- `View…`: `Straight ray / curved terrain` (default), `True terrain elevations / curved ray`, and `Equal horizontal and vertical scale`. `Fit path` and double-click reset framing. Name curvature-adjusted plotted elevation correctly; numeric inspection retains unadjusted physical values.

## Inspection and result semantics

- Hover reads sample distance from both endpoints, ground/surface height, land-cover class, available provenance, LOS gap, and gap to the lower 60% boundary. Click pins the sample in Path; keyboard-accessible sample selection supplies the same information.
- `Go to limiting obstruction` selects and frames the minimum 60% boundary gap, not simply the highest terrain. Report signed gap in display units; negative means intrusion. Calculate minimum clearance ratio separately: its limiting sample can differ from the minimum absolute gap.
- Geometry uses the same 4/3 effective-Earth assumption already shared by plot/solver. Optical/direct-ray obstruction and full/60% Fresnel clearance are distinct. Exclude zero-radius Fresnel endpoints from ratio calculations, while separately checking antenna placement against endpoint obstacles. Invalid/short/incomplete numeric profiles produce Unknown, not a clear verdict.
- Budgets, geometry, endpoints, beams, solver preview, and export consume one frozen result. Capture radios, frequency, model, clutter configuration, ambient-noise configuration and evaluation identity; retain the actual prepared profile and noise explanations. Do not splice in independently cached network-link or ambient-noise rows.
- Compute both directions with direction-specific terminal/model behavior. Model output unavailable in one direction does not erase the other direction or the plot. Missing requested noise yields Unknown margin; do not silently substitute sensitivity. Explicit sensitivity comparison in existing headless APIs remains supported and labeled.
- Receiver reference labels distinguish modeled noise, measured noise, baseline noise, and rated sensitivity. Environmental penalty is an explanation of the retained floor, not an additional subtraction from an already computed margin.
- Surface summary uses structured SurfaceStatus fields. Probe availability is not confidence or an exact fraction of path length. Distinguish DEM source coverage from LiDAR surface availability. Do not claim point-level measurement provenance unless it was actually retained.

## Height solver

- Keep Source/Target/BothEqual/BothIndependent search behavior; expose endpoint names A/B and actual configured height references. Goals remain 60% Fresnel clearance and forward-direction target margin; clearly name that direction. Reverse-budget inspection does not silently retarget the search.
- Search uses the retained profile/noise/settings. Show current/proposed/change for each configured mounting height and resolved reference. State the actual tested height step: current single/equal modes use 0.5 m up to 60 m maximum and 1 m above; independent mode uses 1 m up to 40 m and 2 m above.
- Preview retains current geometry faintly and adds proposed geometry with legend identification; compute both proposed directional budgets before claiming their results. A geometry solution can still be shown if a budget is unavailable, with margin Unknown.
- A solved result means the lowest satisfying tested candidate according to the existing search order, not an exact continuous optimum. State `Target not reached within these limits` with best tested result when unsuccessful.
- `Apply heights to network` is a separate undoable action. Apply only the endpoints permitted by the frozen solve request. Editing goals, endpoint choice, limits, selected pair, radio/model/noise inputs, or refreshing cancels or invalidates the proposal; stale results cannot be applied.

## Companion Guide

Use the existing CompanionGuide component and a separate Link Profile auto-show preference, default true. Sync owner lifecycle every frame, including preparation and closure. Dismissal lasts for that opening; switching pairs in the already-open tool does not resurrect dismissed help. Guide closes with its owner, never steals focus on automatic opening, and opens bundled docs off-thread.

Title: `Link Profile Guide`. Purpose: `Inspect the path between two sites, understand what limits it, and compare antenna heights before changing your network.`

1. **Check the endpoints and radios.** `A and B label the two ends of the plot. Confirm their sites, frequency, systems and mounting heights. Check whether each height is above ground or above the local surface; equal mounting heights do not imply equal antenna elevations.`
2. **Read the legend and path geometry.** `The legend names the lines, antenna beams and surface colors. Line of sight joins the antennas; the 60% Fresnel boundary shows the solver's clearance target. Surface above that boundary misses the target. Select a point or use Go to limiting obstruction to inspect the gap. Surface colors identify land cover, not measurement confidence.`
3. **Check the data used.** `Bare-ground terrain and obstacle surfaces can come from different sources. Missing LiDAR surface observations use land-cover clutter estimates. Usable sample counts describe availability, not survey confidence. Inspect Inputs and refresh to include newly available data.`
4. **Compare both directions.** `Read received level, the labeled receiver reference and predicted margin for A to B and B to A. Radios, alignment and receiver noise can make one direction weaker. Unknown margin means a required input is unavailable. Clearance and margin answer different questions; check both.`
5. **Compare antenna heights.** `Open Heights, choose which sites may change, select a clearance or forward-margin goal, and set the maximum mounting height. Review the proposed heights, their references, search step and preview before choosing Apply heights to network. This changes the nodes and can be undone.`
6. **Inspect assumptions and validate.** `Inputs records the model, radios, receiver references and source limitations. Layers, projection and scale change the view without changing the calculation. Confirm important paths with installation details and field measurements.`

Caveats: `A positive modeled margin or clear Fresnel zone does not guarantee a working field link.` and `Estimated clutter and incomplete surface data can miss local obstacles. The geometry uses RidgeCast's effective-Earth assumption, rather than every possible atmospheric condition.`

Documentation label: `Evaluate a radio link`; route: `docs/how-to/evaluate-a-radio-link.md`; preference label: `Show guide when Link Profile opens`.

## Constraints and acceptance

- No terrain/preparation, propagation, noise modeling, large array copies/scans, settings writes, clipboard/file operations, or doc opening on UI paths. Drawing bounded precomputed geometry is allowed. Preserve cancellation and source snapshots.
- Tooltips on every interactive control, disabled action, tab, legend toggle, splitter, plot and guide control. Full labels must remain available through focus/hover when truncated.
- Reuse current Rust, egui 0.36.2, egui_plot 0.37.0, Serde and asynchronous worker infrastructure; no new dependency required.
- Keep serialized networks and public headless APIs compatible. New LinkProfileSettings uses Serde defaults and the existing atomic settings writer on a queued background save path.
- Existing uncommitted workspace changes are unrelated work. Inspect current state before execution; the integrator alone edits shared files. Commit only if the user later requests it.
- Document the work in the indexed Evaluate a radio link guide and controls reference; update README capability wording only where the resulting capabilities warrant it.
- Acceptance: every visible mark can be named through the legend, A/B and mounting references are unmistakable, plot fills usable space, data/geometry/budget limitations are explicit, proposal/apply agree, and asynchronous changes cannot publish or apply stale results.
