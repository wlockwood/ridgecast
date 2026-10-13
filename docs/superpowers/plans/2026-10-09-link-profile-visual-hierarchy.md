# Link Profile Visual Hierarchy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans after the user chooses the visual direction. Use bounded GPT-6 Luna contracts for the leaf presentation components. This document is a design revision, not an execution request.

**Goal:** Make the existing Link Profile readable through endpoint anchors, distinct result groups, a chart-local legend and clearly identifiable layer controls.

**Architecture:** Keep the implemented immutable profile, worker budgets, geometry, solver and undo unchanged. Reorganize their presentation using the existing link_profile UI modules and shared styles. A compact noninteractive key describes drawn marks; a labeled collapsed Legend & layers panel owns checkbox controls.

**Tech Stack:** Existing Rust, egui 0.36.2 and egui_plot 0.37.0; existing headless egui frame harness; no dependency or modeling changes.

**Spec:** The Presentation brief in this document amends the presentation requirements in [the original design](../specs/2026-10-07-link-profile-workbench-design.md). [The original implementation plan](2026-10-07-link-profile-workbench.md) records the completed foundational work and must not be restarted.

## Global constraints

- Planning artifacts only in this pass; do not change application code or commit without a subsequent execution request. Preserve current dirty files.
- Preserve result semantics, frozen inputs, forward-only margin solving, reference-dependent mounting heights, cancellation, generation rejection, apply/undo and export invariants.
- All layer checkboxes live in one Legend & layers control panel; ordinary legend labels do not toggle layers. Projection/scale stays in View as a separate drawing concern.
- Keep enough always-visible key to identify drawn colors without opening the controls or experimentally switching layers. Hidden layers do not occupy the everyday key.
- Never hide a meaningful unavailable-input/preparation warning. Compact data status remains visible and opens Inputs.
- Every interactive control has a tooltip, keyboard focus and an obvious interactive shape. Preserve accessibility in short/narrow/high-DPI layouts.
- The supplied screenshot is current native evidence. The new HTML prototype uses approximate terrain and copied readouts: it is illustrative, not evidence that native layout has improved.

## Review focus

1. Collapsing layer controls must leave every visible line/mark identifiable and every hidden layer discoverable.
2. Endpoint color/text stays bound to A/B when inspecting reverse budgets; geometry amber is not an overall radio-link failure verdict.
3. Partial LiDAR, unknown receiver reference and failed preparation remain visible even after secondary detail is moved.
4. Long names, US/metric units and a short/narrow viewport must not turn endpoint cards, key or numeric columns into clipped strings.
5. Minimum clearance ratio and minimum physical gap may identify different samples; their labels and navigation must retain that distinction.

## Presentation brief

The October 9 screenshot exposes a hierarchy problem in the first design: tools precede the title, metadata/readouts use nearly identical text weight, endpoint information repeats in long inline strings, the complete legend dominates the header, and inspector numbers lack column alignment. The existing capability inventory should stay; the grouping should change.

### Primary anchors

1. A compact title row: Link Profile, with Guide/Export/Close grouped on the right.
2. Endpoint bridge: distinct cyan A and magenta B badges, larger site names, mounting height/reference underneath, and distance/frequency between them. Use the preferred display unit in compact readouts; show its equivalent in hover/focus details. Preserve full dual-unit formatting in detailed inspectors.
3. Result band: separate geometry status from two directional predicted margins. Amber labels a missed clearance target; it does not claim an overall unusable link. Show Unknown explicitly. Large margin values are readouts, not whole-row blue selection controls. Direction inspection uses a separate compact A→B / B→A selector.
4. Plot frame: a modest Terrain profile heading with View and Fit path. Keep the chart dominant, its grid quieter than its data, and endpoint names/markers adjacent to their actual positions.
5. Inspector: retain Path/Heights/Inputs, but use a clearance group, labeled numeric rows and short disclosures. A clear Compare antenna heights action opens the existing Heights tab. Endpoint installation and detailed budget rows are secondary disclosures.
6. Data-status strip: partial-surface count and method stay visible near the plot; Details opens Inputs. Keep a strong warning for failed/unavailable required data rather than treating every technical cache note as the principal link result.

### Legend and controls

- Always-visible compact key names the marks currently drawn, including optional full Fresnel, beams, proposal, selected-point and sea-level marks when enabled/present. Reuse mark_style; do not duplicate colors or dash conventions.
- `Legend & layers ▸` is a bordered disclosure control with an expanded/collapsed state. Default collapsed. Its open panel contains actual egui checkboxes, each with its swatch and a short label. Whole row may be clickable through checkbox behavior, but the checkbox shape/state is always visible.
- The control panel lists all available layers, including unchecked ones. An unavailable beam has a disabled checkbox with an explanation. Keep the current grouped beam flag unless a later request changes endpoint-specific visibility.
- Do not use clickable legend labels with no checkbox. Class swatches identify categories; they do not independently toggle the entire Surface layer.
- Recommend a bottom drawer: two/three-column checkbox rows expand beneath the key. It preserves horizontal room because a task inspector already occupies the right side.
- Alternative: a chart-local Legend & layers sidebar, collapsed by default and clearly titled when expanded. It must be mutually exclusive with the drawer; no duplicate controls. At narrow widths it becomes the drawer. Compare both with the same content and at the supplied screenshot's approximate width before selecting a placement.
- The user proposed a collapsed sidebar, then explicitly invited alternatives. Placement remains a review choice; collapsed default and unambiguous controls are requirements.

### Surface color density

The default inspection view should use a neutral obstacle-surface band with a visible top, preserving the underlying terrain/clutter heights. Add `Land-cover colors` as a presentation option, default off. When enabled, keep the full current class palette and a bounded readable class key; do not conflate land-cover colors with measured-source provenance. Per-point inspection remains available in either rendering. This is a proposed display change for review, not a change to calculated clutter.

This revision supersedes the old requirement to show every off layer and every class at all times, and the requirement that ordinary legend labels perform visibility toggling. It preserves the requirement that a person can identify every visible mark without toggling it experimentally.

## Review artifacts

- Interactive comparison: [HTML mockup](../../../output/link-profile-hierarchy-review/index.html). The header's Compare legend selector is a review-only control, not a proposed app feature.
- Renderer/check script: `output/link-profile-hierarchy-review/render-and-check.mjs`. Captures compare collapsed, expanded drawer, expanded sidebar and narrow layouts.
- Only legend visibility, drawer/sidebar placement, budget selection and task navigation are simulated. Other illustrative actions explain that they do not perform RF calculations or network edits.

## Task 1: Hierarchy and endpoint presentation — main integrator

**Files:** Modify only the relevant portions of `src/app/ui/link_profile/window.rs`, `annotations.rs`, `mod.rs` and `tests.rs`; preserve unrelated current edits. The root prepares leaf interfaces before Luna dispatch.

**Interfaces:** Add `legend_open: bool` (default false) and `landcover_colors: bool` (default false) to ProfileUiState. If sidebar is chosen, add `LegendPlacement::{Drawer, Sidebar}` as a presentation preference with narrow fallback. Add `primary_height(units: UnitSystem, meters: f64) -> String` and `primary_distance(units: UnitSystem, meters: f64) -> String` locally to annotations; use UnitSystem's existing conversion/unit methods without changing its global formatting.

- [ ] Inspect current diffs and freeze chosen placement; do not rebuild already implemented budgets/diagnostics/jobs.
- [ ] Add frame/interaction tests for distinct A/B names/reference captions, Unknown statuses, separate geometry/margin groups, reverse inspection identity, primary/equivalent-unit availability and narrow/short reachability. Confirm relevant regressions fail on the current presentation.
- [ ] Implement title, endpoint bridge, result band, plot frame and compact visible data status. Use restrained background/stroke/padding groups rather than decorative boxes for every metric. Native egui frames/styles must retain the intended hierarchy; HTML CSS is illustrative only.
- [ ] Preserve accepted snapshots/proposals and route actions after rendering as today. Verify no model/recalculation triggered by display controls. Root alone wires the leaf modules and source changes.

## Task 2: Explicit checkbox controls and active key — GPT-6 Luna

**Owned file:** `src/app/ui/link_profile/legend.rs` and its colocated tests only. Root owns state/layout integration.

**Consumes:** Existing ProfileLegendInput, ProfileLayers and mark_style, plus the selected drawer/sidebar parent allocation. **Produces:** `show_active_key(ui: &mut egui::Ui, input: &ProfileLegendInput<'_>, layers: &ProfileLayers)` and `show_layer_controls(ui: &mut egui::Ui, input: &ProfileLegendInput<'_>, layers: &mut ProfileLayers, landcover_colors: &mut bool)`. The key never mutates visibility; the controls do. The parent owns the Legend & layers disclosure.

- [ ] Replace the old off-entry/clickable-label assumptions with tests: unchecked layers absent from active key but still in checkbox list; enabled painted overlays and proposals named; disabled unavailable beam explained; class-label click does not change surface visibility.
- [ ] Implement swatch + native checkbox rows with hover text and Space activation. Provide bounded class explanations only when class colors are visible; preserve A/B beam and endpoint identity.
- [ ] Return a focused patch without editing shared layout/state or committing. Root runs focused `cargo test --lib link_profile_legend` and checks the registry-to-rendering correspondence.

## Task 3: Inspector structure and plot color option — bounded Luna contracts

**Owned files:** Inspector formatting is `window.rs` only when root has handed off a stable extracted `path_inspector` region, otherwise keep it with the integrator to avoid concurrent edits. Plot leaf owns only `plot.rs` surface presentation and its existing tests. These contracts are sequential if they touch shared code.

**Interfaces:** Existing path_inspector/render actions, ProfileSnapshot, ProfileUiState and plot::surface_style. Introduce no new model types. A plot surface color function may accept the new display flag; the root threads it through.

- [ ] Convert budget/endpoint readouts to stable labeled rows with right-aligned values. Preserve direction labels, height references and complete details behind disclosures. Sample navigation should name the location/distance, while an advanced exact sample-number control can remain available.
- [ ] Present the signed minimum-gap check and minimum-ratio check distinctly; each navigation targets its recorded index. Do not silently reinterpret the existing diamond as the minimum-ratio sample.
- [ ] Implement neutral default surface fill and optional class colors with identical vertices/heights. Reuse existing hover data. Tests compare geometry and retained budgets before/after the display change; changing color must not reconstruct profiles or run propagation.
- [ ] Root verifies focused tests and visual coherence with endpoint/key styles; no global style or UnitSystem changes.

## Task 4: Documentation, native validation and final review — root

**Files:** Relevant guide/documentation wording and `src/app/ui/link_profile/tests.rs`; preserve the original plan's execution evidence.

- [ ] Update Companion Guide and indexed Evaluate a radio link wording to explain the active key, Legend & layers panel and optional class-color view. Copy review can be contracted to Luna after labels are stable.
- [ ] Run `cargo check`, formatting, strict Clippy, appropriate focused tests and the full required test suite once integrated; run documentation-link and whitespace checks. No application checks are claimed by this planning pass.
- [ ] Capture native wide, sidebar/drawer-open, narrow, short and high-DPI screens with clear/obstructed/Unknown/partial-data examples. Check that plot space and readout grouping actually improve at the screenshot's size.
- [ ] Review every visible mark's identity, discoverability of collapsed controls, checkbox affordance/focus, source warnings, and marker/check agreement. Report native-runtime limits honestly; browser mockup checks are not egui validation.

## Current evidence

Implemented October 9 after the user's explicit go-ahead. The bottom drawer is the selected placement. Bounded GPT-6 Luna tasks delivered the legend, endpoint presentation and guide text; the main integrator completed the window, inspector, plot presentation and verification.

Validation: `cargo check`, format checking, strict Clippy across all targets/features, documentation links and whitespace checks passed. The focused Link Profile group passed 38 tests; full `cargo test` passed 2,215 library tests with 34 ignored. The opt-in capture test was run separately and passed. Seven captures under `output/link-profile-native/` exercise the native egui presentation with synthetic profiles and software rasterization; they are not desktop GPU screenshots or validation of field RF performance.

A fresh independent review identified and verified fixes for long endpoint-label overlap, narrow toolbar wrapping, expanded drawer reachability, matching radio-goal affordances and the missed-Fresnel amber cue. Its final scoped review found no remaining material issues. Existing calculation, worker, solver, frozen-input and undo behavior remains in place. Changes are uncommitted in the original checkout, with pre-existing edits preserved.
