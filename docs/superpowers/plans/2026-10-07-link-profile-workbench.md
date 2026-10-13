# Link Profile Workbench Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Use superpowers:dispatching-parallel-agents for the independent GPT-6 Luna contracts below. Steps use checkbox syntax for tracking.

**Goal:** Implement a responsive Link Profile workbench with unmistakable endpoint labels, a persistent complete legend, coherent bidirectional results, obstruction inspection, reviewed height proposals and a Site Finder-style Companion Guide.

**Architecture:** Keep the desktop as a presentation layer over an immutable prepared profile and worker-built diagnostics/budgets. Extract rendering into focused Link Profile modules, with one style registry shared by plot and custom legend. The main agent owns scientific semantics, job identity, shared-file changes, solver integration and final verification; GPT-6 Luna owns bounded leaf components and documentation.

**Tech Stack:** Existing Rust/egui 0.36.2/egui_plot 0.37.0, Serde, Arc snapshots, existing cancellable background jobs and atomic settings persistence; no new dependencies.

**Spec:** [Link Profile workbench design](../specs/2026-10-07-link-profile-workbench-design.md). Read both documents before execution. The user's endpoint-label/legend amendment is mandatory, not an optional polish task.

## Global constraints

- Planning only at creation: do not start implementation or create commits without a subsequent execution request. The current workspace contains concurrent uncommitted changes; preserve them.
- No expensive I/O/computation/large array copying on UI paths. Retain cancellation and preparation/cache snapshot semantics. Do not reacquire egui Context inside Context accessor closures.
- Every control has a tooltip; docs remain reachable from docs/README.md. No new dependencies or public API/network schema breakage.
- A is the initially selected source at x=0; B is target at x=distance. Reverse budget selection does not reverse the plot or solver ownership.
- Default layers: ground, obstacle surface, LOS and 60% boundary on; full Fresnel, beams and sea level off. Legend and result summary cannot be hidden with a feature checkbox.
- Required colors/labels, 900 px responsive breakpoint, 1100x760 default size, inspector 320 default / 280..420 range, guide copy, unknown semantics and deferred features are fixed in the spec.
- Height solver remains forward-margin only in this release; independent endpoint limits, raise-only, both-direction margin solving, image/report export and comparisons are separate follow-ups.
- Only the integrator edits module declarations, existing shared files and app fields. Luna contracts own exclusively named new files or an explicitly assigned existing documentation file. Workers do not stage or commit.

## Review focus

1. A high roof with a Surface reference must put its antenna above the roof and label the configured mounting height correctly (Tasks 2, 6, 7).
2. Missing atmospheric noise or unsupported reverse propagation must yield Unknown for that direction while retaining usable geometry/other results (Tasks 3, 8).
3. Editing solve controls, refreshing, or replacing a document while work completes must never apply an old pair of heights (Tasks 1, 7, 8).
4. Duplicate/long names, narrow/short windows, high DPI and panned-offscreen endpoints must preserve distinguishable A/B labels, legend access and actions (Tasks 6, 8).
5. All class fills, painter overlays and proposed geometry must have accurate swatches; hiding a layer must not remove its identifying legend entry (Tasks 4, 6, 8).

## Execution and cost strategy

Use the main agent for Tasks 1-3, 7-8 and 10. Use `gpt-6-luna` for Tasks 4-6 and 9. Do not offload propagation, noise-reference decisions or stale-result ownership merely to save model cost.

Spawn Luna workers with `model: "gpt-6-luna"`, `fork_turns: "none"`, a self-contained task brief and only the spec sections/interfaces they need. Reference exact owned files and prohibit shared-file edits. Include task-specific input/output examples and acceptance checks. Require a file list, assumptions and actual verification evidence in their handoff. A report saying tests passed is not verification by the integrator.

Run at most two Luna implementers concurrently (root + two workers), reserving the fourth slot for focused review if needed. Do not repeatedly send full repo/conversation context. The root establishes compiling interfaces and module declarations before delegation, reviews returned patches, and runs shared Cargo verification serially to avoid workspace/target locks. A larger model reviews scientific boundaries and integration; use Luna for bounded visual/copy checks. Existing skill-required task reviews still apply; keep reviewer context restricted to the contract and patch.

Parallel wave A after Tasks 1-3: Tasks 4 (legend) and 5 (source summary). Wave B after Task 4: Task 6 (endpoint/plot overlays) can run while root implements Task 7. Wave C after the labels and lifecycle in Task 8 are stable: Task 9 guide and docs. Then Task 10. Do not parallelize writers of the same file.

Each task yields a focused patch. If commits are subsequently requested, inspect `git diff --cached --name-only` and `git diff --cached --check` per task/concern; never stage the whole dirty checkout. No commits are part of this planning request.

## File and interface map

These are proposed new interfaces, not claims that they already exist. Use `pub(crate)` for desktop/core implementation details unless preserving an existing public headless type requires `pub`. Types in this map are defined by Tasks 1-3 before dependent tasks begin.

| File | Responsibility / owner |
| --- | --- |
| `src/link_profile.rs` (new) | Snapshot, core geometry records, worker request/result types / root |
| `src/engine/path_budget.rs` (new) | Shared directional budget/reference calculation extracted from headless code / root |
| `src/app/link_profile_jobs.rs` (new) | Preparation/report/export orchestration and generation checks / root |
| `src/app/ui/link_profile/mod.rs` (new) | Presentation types, shared registry, layer options and workbench state / root |
| `src/app/ui/link_profile/window.rs` (new) | Responsive owner window and action routing / root |
| `src/app/ui/link_profile/plot.rs` (new) | Existing profile/beam projection rendering extracted before delegation / root |
| `src/app/ui/link_profile/legend.rs` (new) | Custom legend renderer / Luna |
| `src/app/ui/link_profile/inputs.rs` (new) | Structured availability summary and input inspector / Luna |
| `src/app/ui/link_profile/annotations.rs` (new) | Endpoint captions/markers, selection and obstruction markers / Luna |
| `src/app/ui/link_profile/heights.rs` (new) | Solver controls, before/after and preview actions / root |
| `src/app/ui/link_profile/guide.rs` (new) | LINK_PROFILE_GUIDE content / Luna |
| `src/app/ui/link_profile/tests.rs` (new) | Workbench interaction/layout regression tests / root |
| `src/app/ui/windows.rs`, `src/app/ui/mod.rs` | Move only Link Profile implementation; preserve ruler/other windows and migrate existing focused tests / root |
| `src/app/mod.rs`, `src/app/actions.rs`, `src/lib.rs`, `src/engine/mod.rs` | Fields, initialization, polling, declarations and persistence wiring / root |
| `src/config.rs`, `src/link_eval.rs`, `src/solve_height.rs`, `src/headless/link.rs` | Settings, prepared data sharing, solve semantics and shared budget reuse / root |
| `docs/how-to/evaluate-a-radio-link.md` | Rewrite indexed task guide / Luna |
| `docs/reference/controls-and-shortcuts.md`, `README.md` | Small final wording updates / root |

Core contract, defined in Task 1:

```rust
// src/link_profile.rs
struct ProfileSnapshot {
    input: crate::link_eval::ProfileInput,
    terrain_config: crate::engine::terrain::TerrainManagerConfig,
    ambient_noise: crate::engine::ambient_noise::AmbientNoiseConfig,
    evaluation: std::sync::Arc<crate::engine::parallel::LinkEvaluation>,
    geometry: ProfileGeometry,
    budgets: [Result<DirectionalBudget, String>; 2], // [A->B, B->A]
    surface_classes: Vec<u8>, // sorted unique effective classes; zero = unknown
}
struct ProfileEndpoint {
    node: crate::graph::models::ResolvedNodeProfile,
    ground_m: f64,
    surface_m: f64,
    antenna_m: f64,
}
struct ProfileSample {
    index: usize,
    distance_from_a_m: f64,
    ground_m: f64,
    surface_m: f64,
    los_gap_m: f64,
    fresnel60_gap_m: Option<f64>,
    clearance_ratio: Option<f64>,
    class: u8,
}
struct ProfileGeometry {
    endpoints: [ProfileEndpoint; 2],
    samples: Vec<ProfileSample>,
    direct_ray_clear: Option<bool>,
    minimum_clearance_ratio: Option<f64>,
    limiting_gap_index: Option<usize>,
    limiting_ratio_index: Option<usize>,
}
struct ProfileDiagnosticsRequest<'a> {
    evaluation: &'a crate::engine::parallel::LinkEvaluation,
    endpoints: &'a [crate::graph::models::ResolvedNodeProfile; 2],
    configured_heights_m: [f64; 2],
}
fn analyze_profile(
    request: ProfileDiagnosticsRequest<'_>, canceled: &dyn Fn() -> bool,
) -> Result<ProfileGeometry, String>;
```

`DirectionalBudget` is defined in Task 1 with `budget: crate::headless::link::PathBudget` and `noise: Option<crate::engine::ambient_noise::NoiseFloorExplanation>` so the initial types compile before Task 3. Task 3 moves/re-exports existing `PathBudget` and `ReferenceLevel` through `headless::link` without changing their public names or serialized fields, then implements budget construction. Directional failures are explicit Strings, not NaN-filled successful budgets.

`ProfileGeometrySummary`, defined in Task 2, has the same `endpoints`, `direct_ray_clear`, `minimum_clearance_ratio`, `limiting_gap_index`, and `limiting_ratio_index` fields/types as ProfileGeometry, without `samples`. The summary-only function avoids allocating full diagnostic arrays for every solver candidate.

Presentation contract, defined in Task 1:

```rust
// src/app/ui/link_profile/mod.rs
enum ProfileLayer { Terrain, Surface, Los, Fresnel100, Fresnel60, Beams, SeaLevel }
enum ProfileMark {
    Terrain, Los, Fresnel100, Fresnel60, BeamA, BeamB, SeaLevel,
    EndpointA, EndpointB, Proposal, SelectedPoint, LimitingObstruction,
}
struct ProfileLayers {
    terrain: bool, surface: bool, los: bool, fresnel100: bool,
    fresnel60: bool, beams: bool, sea_level: bool,
}
// fn get(&self, layer: ProfileLayer) -> bool
// fn set(&mut self, layer: ProfileLayer, enabled: bool)
enum ProfileSymbol { None, Circle, Diamond, Triangle }
struct ProfileStyle {
    color: egui::Color32, width: f32, dashed: bool, symbol: ProfileSymbol,
}
fn mark_style(mark: ProfileMark) -> ProfileStyle;
struct SurfaceLegendEntry { class: u8, label: String, color: egui::Color32 }
struct ProfileLegendInput<'a> {
    endpoint_names: [&'a str; 2],
    surface_classes: &'a [SurfaceLegendEntry],
    beams_available: [bool; 2],
    has_proposal: bool, has_selected_point: bool, has_limiting_obstruction: bool,
}
enum InspectorTab { Path, Heights, Inputs }
struct ProfileUiState {
    layers: ProfileLayers, tab: InspectorTab, inspector_open: bool,
    inspector_width: f32, selected_sample: Option<usize>,
    guide: crate::app::ui::companion_guide::CompanionGuide,
    // existing projection/scale state and fit/select requests live here
}
```

Keep application actions separate from rendering responses. The root supplies exact operational responses where tasks define them below; worker-authored leaf components never mutate the network.

## Task 1: Define contracts and retained ownership — root

**Files:** Create `src/link_profile.rs`, `src/app/link_profile_jobs.rs`, `src/app/ui/link_profile/mod.rs`; modify `src/lib.rs`, `src/app/mod.rs`, `src/app/actions.rs`, `src/app/ui/mod.rs`, `src/config.rs`.

**Interfaces:** Produce the core/presentation types above; `ProfileJobToken { identity: LinkEvaluationIdentity, generation: u64 }` in the app job module; `accepts_result(pending: &ProfileJobToken, received: &ProfileJobToken, current: &LinkEvaluationIdentity) -> bool`; `LinkProfileSettings { guide_auto_show: bool }` with Serde default true and `load_link_profile_settings() -> std::io::Result<Option<LinkProfileSettings>>` / `save_link_profile_settings(settings: LinkProfileSettings) -> std::io::Result<()>`. Private path-based helpers `read_link_profile_settings_from(path: &std::path::Path) -> std::io::Result<Option<LinkProfileSettings>>` and `write_link_profile_settings_to(path: &std::path::Path, settings: LinkProfileSettings) -> std::io::Result<()>` permit isolated settings tests.

- [ ] Capture current `git status`, inspect applicable instructions and `.review/` constraints, and record existing changes before execution. Read `LinkEvaluationIdentity`, `ProfilePreparation`, `select_link_profile`, settings queues and solve invalidation.
- [ ] Add failing behavioral tests: `link_profile_rejects_old_refresh_generation` (same identity, different generation -> false), `link_profile_rejects_replaced_document` (different epoch -> false), `link_profile_accepts_matching_completion` (matching generation/identity/current -> true), and settings round-trip/missing-field tests (`{}` -> guide true; explicit false survives).

  Core assertions after arranging tokens/settings from this task's types:
  ```rust
  assert!(!accepts_result(&pending, &old_generation, &current));
  assert!(!accepts_result(&pending, &old_document, &current));
  assert!(accepts_result(&pending, &pending, &current));
  let defaults: LinkProfileSettings = serde_json::from_str("{}").unwrap();
  assert!(defaults.guide_auto_show);
  let explicit: LinkProfileSettings =
      serde_json::from_str(r#"{"guide_auto_show":false}"#).unwrap();
  assert!(!explicit.guide_auto_show);
  ```
- [ ] Run `cargo test --lib link_profile_` and the named settings tests; verify the new assertions fail for the missing behavior, without treating unrelated compile failures as the intended red state.
- [ ] Implement the types, defaults, generation acceptance and settings file `link_profile_config.json`. Implement ProfileLayers get/set/default and mark_style with the spec's colors; assign triangle symbols to EndpointA/B in their beam colors, circle to SelectedPoint and diamond to LimitingObstruction. Add `LINK_PROFILE_SETTINGS_SAVE`, `SettingsSaveKind::LinkProfile`, retry/error reporting and shutdown queue flushing using the existing LatestConfigSave pattern; settings writes happen on its worker, never in a UI closure. Do not put Link Profile preferences into SiteFinderSettings.
- [ ] Replace UI-owned large evaluation/proposal clones with Arc ownership while preserving public LinkEvaluation and old APIs. Keep a small token in replies; root alone updates shared app fields. Add generation invalidation for same-input Refresh, not only changed input identity. Bump the generation on terrain-source/vertical-offset or land-cover/population source configuration and offline-policy changes; route these changes through the existing configuration-apply actions. Add `link_profile_source_change_invalidates_pending_result`. Retain a cloned TerrainManagerConfig with accepted result inputs for Inputs display; it lacks PartialEq, so use change generation rather than assuming comparable manager settings. Background cache arrivals alone do not replace an accepted profile.
- [ ] Run `cargo check` and focused tests. Review public API compatibility and root-owned module registrations before exposing contracts to Luna. If commits are requested, concern: `refactor(link-profile): define retained workbench state`.

## Task 2: Shared geometry, height references and sample diagnostics — root

**Files:** Implement `src/link_profile.rs`; modify `src/solve_height.rs`, `src/headless/link.rs`; tests colocated in the affected modules.

**Interfaces:** Implement `analyze_profile(...) -> Result<ProfileGeometry, String>` and `analyze_profile_summary(request: ProfileDiagnosticsRequest<'_>, canceled: &dyn Fn() -> bool) -> Result<ProfileGeometrySummary, String>`; add `ProfileEndpoint::configured_height_m() -> f64` and `ProfileEndpoint::height_reference() -> HeightReference`. Consumers use retained endpoints, never live mesh resolution.

- [ ] Add failing tests `link_profile_surface_mounting_reference` (ground 100, surface height 20, configured 3 -> antenna 123 for Surface and 103 for Ground), `link_profile_los_is_distinct_from_fresnel` (positive LOS gap but clearance ratio 0.3 -> LOS clear, 60% target false), and `link_profile_gap_and_ratio_can_limit_at_different_samples`.

  Assertions for the independently arranged Surface/Ground and partial-Fresnel fixtures:
  ```rust
  assert_eq!(surface_geometry.endpoints[0].antenna_m, 123.0);
  assert_eq!(ground_geometry.endpoints[0].antenna_m, 103.0);
  assert_eq!(partial_fresnel.direct_ray_clear, Some(true));
  assert!(partial_fresnel.minimum_clearance_ratio.unwrap() < 0.6);
  assert_ne!(different_limiters.limiting_gap_index,
             different_limiters.limiting_ratio_index);
  ```
- [ ] Add tests for a below-surface antenna, zero-radius endpoints, fewer than two samples, unequal array lengths, non-finite values and canceled diagnostics. Invalid geometry must not report clear; cancellation must terminate processing. Run `cargo test --lib link_profile_` and confirm intended failures.
- [ ] Compute samples in one cancellable worker pass, using resolved configured height references and the existing effective radius 8_493_000 m. Fresnel gap = LOS gap - 0.6 * radius. Tie-break limiting indices by first sample. Reject mismatched/non-finite input with an error; valid boundary contact is an obstruction for the direct-ray verdict. Endpoint checks are separate from interior Fresnel ratios.
- [ ] Have solver clearance and headless direct-ray reporting consume the shared analysis. Correct the existing headless `has_line_of_sight: clearance >= 1.0` discrepancy with an explicit regression; keep serialized field names. Prevent per-candidate construction of a full sample Vec in height searches: provide a summary-only `analyze_profile_summary(request, canceled) -> Result<ProfileGeometrySummary, String>` sharing the same loop, with endpoint/direct-ray/minimum/index fields but no samples.
- [ ] Run geometry, solver and headless report tests. Ensure the new meaning of direct-ray status is documented rather than silently redefining Fresnel results. If commits requested: `fix(link-profile): distinguish ray and Fresnel clearance`.

## Task 3: Coherent directional budgets and preparation publication — root

**Files:** Create `src/engine/path_budget.rs`; modify `src/engine/mod.rs`, `src/headless/link.rs`, `src/link_eval.rs`, `src/link_profile.rs`, `src/app/link_profile_jobs.rs`, `src/app/actions.rs`, `src/app/mod.rs`.

**Interfaces:** `BudgetContext<'a> { land_cover: &'a LandCoverManager, population: Option<&'a PopulationManager>, ambient_noise: &'a AmbientNoiseConfig, reference: ReferenceLevel, canceled: &'a dyn Fn() -> bool }`; `build_directional_budgets(evaluation: &LinkEvaluation, endpoints: &[ResolvedNodeProfile; 2], context: BudgetContext<'_>) -> [Result<DirectionalBudget, String>; 2]`. `ProfileSnapshot` is published as `Arc<ProfileSnapshot>` behind the Task 1 token.

- [ ] Add failing tests `link_profile_asymmetric_receiver_floors`, `link_profile_missing_noise_keeps_geometry`, `link_profile_reverse_model_failure_is_directional`, and `link_profile_budget_does_not_read_cached_network_link`. The snapshot result must be unchanged by mutation of an unrelated stored link/noise row; a missing complete floor must never become 0 dB or implicit sensitivity.
- [ ] Run the new tests and existing headless budget tests; confirm the intended failures.
- [ ] Extract the existing ray-aware EIRP/RX-gain/system-loss/reference calculation into the shared module. Preserve headless public re-exports and requested Sensitivity comparison. Desktop uses the captured NoiseFloor reference and retains its NoiseFloorExplanation; supported receiver baseline remains labeled baseline. A requested unavailable component yields an error for that direction.
- [ ] Evaluate reverse loss/clutter with the selected model's existing direction semantics using the same prepared arrays; do not assume all models are reciprocal or resample terrain/replace surfaces. Preserve accounting so already-inclusive clutter/noise penalties are not subtracted twice. Keep independent direction failures.
- [ ] Extend preparation/report orchestration to build geometry, effective surface-class set and budgets off-thread before publication. Preserve compatibility wrappers for existing ProfilePreparation/headless callers. Capture structured errors, shared arrays and source status; no cache reread on presentation. Add cancellation checks between preparation, each noise/budget direction and diagnostics.
- [ ] Run `cargo test --lib link_profile_`, existing headless/link preparation tests and `cargo check`. Verify old refresh completion cannot publish and that a report can complete without a persisted graph edge. If commits requested: `feat(link-profile): retain coherent directional results`.

## Task 4: Persistent complete legend — GPT-6 Luna, wave A

**Owned file:** Create only `src/app/ui/link_profile/legend.rs` with colocated tests. Root prepares mod declaration and shared styles before dispatch.

**Consumes:** Task 1 `ProfileLegendInput`, `ProfileLayers`, `ProfileMark`, `mark_style`. **Produces:** `show_legend(ui: &mut egui::Ui, input: ProfileLegendInput<'_>, layers: &mut ProfileLayers) -> egui::Response`. It mutates only display-layer flags. Add `legend_entries(input: &ProfileLegendInput<'_>, layers: &ProfileLayers) -> Vec<LegendEntry>` where `LegendEntry { label: String, mark: Option<ProfileMark>, surface_class: Option<u8>, enabled: bool, unavailable: bool }` is local to this module.

- [ ] Add behavioral tests `link_profile_legend_off_layers_keep_entries`, `link_profile_legend_endpoint_symbols`, `link_profile_legend_identical_beam_names`, `link_profile_legend_unavailable_beams`, `link_profile_legend_surface_classes`, and `link_profile_legend_proposal_presence`. Assert fixed entries remain with layers off, A/B endpoint symbols stay identified, identical names disambiguate, unavailable beams are labeled, supplied classes remain readable, and a proposal entry tracks preview presence. Use a small egui frame to confirm a legend click changes only its display flag.

  Assertions against entries returned from this task's `legend_entries`, with all layer flags false:
  ```rust
  assert!(entries.iter().any(|e| e.mark == Some(ProfileMark::Los) && !e.enabled));
  assert!(entries.iter().any(|e| e.mark == Some(ProfileMark::EndpointA)));
  assert!(entries.iter().any(|e| e.mark == Some(ProfileMark::EndpointB)));
  assert!(!entries.iter().any(|e| e.mark == Some(ProfileMark::Proposal)));
  ```
  Task 1 derives PartialEq/Eq on ProfileMark and ProfileLayer to support matching and semantic tests.
- [ ] Root runs `cargo test --lib link_profile_legend`; verify failures before implementation.
- [ ] Implement custom swatches and wrapped, bounded surface-class rows. Match each mark's color/stroke/dash/symbol, including painted overlays. Describe Fresnel upper/lower as one envelope. Preserve separate A/B beam entries even under a grouped beam toggle. Every interactive swatch/checkbox has explanatory hover text. Do not add the built-in legend's LC polygon IDs or a separate Features list.
- [ ] Keep full names accessible on focus/hover and expose surface classes without requiring toggling the plot. Off entries keep colored swatches and visible `off` text. Handle tiny available width without fixed-width overflow.
- [ ] Root runs focused tests and inspects the actual patch against rendered styles. If commits requested: `feat(link-profile): add persistent profile legend`.

## Task 5: Readable availability and Inputs inspector — GPT-6 Luna, wave A

**Owned file:** Create only `src/app/ui/link_profile/inputs.rs` with colocated tests.

**Consumes:** `ProfileSnapshot`, its structured SurfaceStatus and frozen ProfileInput/noise; UnitSystem. **Produces:** `surface_summary(status: &SurfaceStatus) -> SurfaceSummary`, local `SurfaceSummary { text: String, warning: bool }`; `show_inputs(ui: &mut egui::Ui, snapshot: &ProfileSnapshot, units: UnitSystem)`; `show_surface_status(ui: &mut egui::Ui, summary: &SurfaceSummary) -> egui::Response` (no I/O/actions).

- [ ] Add tests `link_profile_inputs_partial_surface`, `link_profile_inputs_lidar_disabled`, `link_profile_inputs_zero_probes_is_unknown`, and `link_profile_inputs_failure_without_offline_claim`. For 1 usable/90 total, describe samples and categorical fallback; never label it confidence, path-area percentage, or missing DEM coverage.
- [ ] Root runs `cargo test --lib link_profile_inputs`; verify intended failures.
- [ ] Render concise status plus structured source/policy/preparation/cache/offline details. Use SurfaceStatus directly; do not parse Display text. Keep raw failures inspectable in a bounded scroll region. Show model provenance and frozen radio/reference explanations, including environmental penalty as already reflected in the floor.
- [ ] Render unresolved point provenance honestly; effective class colors do not prove measured source. Inputs presents information and produces no node/settings changes.
- [ ] Root verifies tests and checks labels against actual fields. If commits requested: `feat(link-profile): explain retained surface and input status`.

## Task 6: Endpoint annotations and plot selection — GPT-6 Luna, wave B

**Owned file:** Create only `src/app/ui/link_profile/annotations.rs` and its tests. Root extracts current ProfileFrame/beam/sea-level/clutter helpers into `plot.rs`, making needed types crate-visible and preserving existing tests before dispatch.

**Consumes:** `ProfileGeometry`, Task 1 styles, `plot::ProfileFrame` (existing `terrain_y`, `ray_y`) and egui_plot::PlotTransform. **Produces:** `show_endpoint_captions(ui: &mut egui::Ui, endpoints: &[ProfileEndpoint; 2], units: UnitSystem)`; `paint_endpoint_markers(ui: &egui::Ui, transform: &egui_plot::PlotTransform, frame: ProfileFrame, endpoints: &[ProfileEndpoint; 2])`; `paint_sample_markers(ui: &egui::Ui, transform: &egui_plot::PlotTransform, frame: ProfileFrame, geometry: &ProfileGeometry, selected: Option<usize>)`; `sample_at_distance(geometry: &ProfileGeometry, distance_m: f64) -> Option<usize>` (binary search retained monotonic samples, not a full scan per hover).

- [ ] Add tests `link_profile_annotations_ground_and_surface`, `link_profile_annotations_reverse_budget_keeps_a_left`, `link_profile_annotations_offscreen_caption_survives`, and long/identical-name frame tests in both UnitSystems. Assert mounting-reference text, A/B distinctions, projection-correct marker locations and clipping behavior.
- [ ] Root runs `cargo test --lib link_profile_annotations`; verify expected failures.
- [ ] Draw stable external captions plus clipped masts/markers. Full site names remain in captions/accessible details when shortened. Markers use the endpoint's actual resolved antenna elevation transformed into the current projection; do not recompute from live mesh values.
- [ ] Implement nearest-sample selection and selected/limiting symbols using shared registry styles. Root wires click, keyboard sample choice, inspector details and Go to limiting obstruction. Do not map arbitrary off-path pointer coordinates to an endpoint through unchecked casts.
- [ ] Root verifies styles against legend and reruns migrated beam/projection tests. If commits requested: `feat(link-profile): label endpoints and inspect path samples`.

## Task 7: Frozen solver requests and proposal preview — root

**Files:** Create `src/app/ui/link_profile/heights.rs`; modify `src/solve_height.rs`, `src/app/link_profile_jobs.rs`, `src/app/actions.rs`, `src/link_profile.rs`.

**Interfaces:** `HeightSolveRequest { token: ProfileJobToken, snapshot: Arc<ProfileSnapshot>, params: SolveHeightParams }`; `HeightProposal { request: HeightSolveRequest, result: SolveHeightResult, geometry: ProfileGeometry, budgets: [Result<DirectionalBudget, String>; 2], search_step_m: f64 }`. UI renderer `show_heights(ui: &mut egui::Ui, snapshot: &ProfileSnapshot, solve: &mut SolveHeightState, proposal: Option<&HeightProposal>, units: UnitSystem) -> HeightActions`, with `HeightActions { solve: bool, cancel: bool, apply: bool }`.

- [ ] Add failing tests `link_profile_apply_uses_frozen_endpoint_mode`, `link_profile_changed_solve_controls_invalidates_proposal`, `link_profile_preview_preserves_current_snapshot`, and `link_profile_surface_proposal_round_trip`. Apply must change only request-owned nodes; a result cannot be applied after mode/goal/limit edits. Applying Surface height must preserve the configured reference and resolve the pictured antenna position.
- [ ] Add tests for current search-step boundaries (single/equal max 60 -> 0.5; above -> 1; independent max 40 -> 1; above -> 2), canceled results, unavailable margin disabling only margin solving, and independent solve selected minimum total tested height. Run focused tests to establish intended failures.
- [ ] Use prepared arrays and the captured forward receiver reference. Keep 60% solving available when margin cannot be computed; report unknown margin rather than a made-up threshold. Do not add a both-directions goal in this task.
- [ ] Make a solved candidate's changed LinkEvaluation/profile and both proposed budgets on a worker, sharing original immutable surfaces and input assumptions. Recalculate candidate path loss instead of pairing proposed geometry with old current loss. Avoid quadratic full-array allocations per tested height; summary-only diagnostics serve the search.
- [ ] Present before/after/delta, exact search step and forward goal direction; route apply through existing undoable `apply_solved_heights` using frozen request ownership. Cancel/clear proposals when solve controls, pair, document, radio/model/noise or refresh generation changes. Treat an old visible snapshot as read-only during refresh; disable new solving/applying until its accepted replacement arrives.
- [ ] Root checks solver/headless regression tests, proposal legend agreement and undo. If commits requested: `feat(link-profile): preview frozen antenna height proposals`.

## Task 8: Responsive workbench, lifecycle and export integration — root

**Files:** Implement `src/app/ui/link_profile/window.rs`, `plot.rs`, `tests.rs`; modify `src/app/ui/windows.rs`, `src/app/mod.rs`, `src/app/actions.rs`, `src/app/link_profile_jobs.rs`.

**Interfaces:** Keep the existing public app entry point `show_evaluated_link_window(&mut self, ui: &mut egui::Ui)` delegating to the extracted workbench. Define `ProfileWindowActions { close: bool, refresh: bool, cancel_preparation: bool, copy_csv: bool, open_guide: Option<egui::Id>, fit_path: bool, select_sample: Option<usize>, height: HeightActions }`; apply them after rendering/borrows finish. Small render responses contain no large copied result arrays.

- [ ] Add failing frame/interaction tests for required A/B captions and legend with inspector closed; all line/overlay swatches with layers enabled; selecting reverse budget leaves plot/solver ownership unchanged; 1100x760, 700x650 and 600x400 logical viewports; 2x DPI; long names; summary's weaker direction; guide/preparation/close lifecycle; and no recursive Context lock on opening. Avoid snapshot tests that merely duplicate current text layouts.
- [ ] Add job tests for cancel/retry and rapid consecutive Refresh with unchanged inputs. A generation that finishes late cannot clear/publish over the latest request. Add an invalid-input test that fails once with visible status rather than rescheduling every frame. Run the new tests to establish intended failures.
- [ ] Implement the spec's dimensions and independently scrolling inspector, measuring chrome/legend height. Remove duplicate projection/sidebar features and Summary Bar toggle; preserve Fit path/double-click, equal scale, beam fans, terrain/class hover and physical-vs-drawn elevation distinctions. Migrate old focused sidebar tests into tests for the new reachable solver controls; retain existing beam geometry coverage.
- [ ] Use one owner window during preparation/error/ready states. On Refresh show `Refreshing` and an explicitly labeled prior result if retained; invalidate solving/apply. Cancel rejects completion. Closing cancels owner-specific work, dismisses guide and clears pending proposal; no result is published into a later opening. If result reuse is retained, only identical accepted pair/inputs can reuse it.
- [ ] Wire Path/Heights/Inputs tabs, data Details, selected point keyboard control and Go to limiting obstruction. Do not let beam tooltip hits suppress pinned sample access. Plot construction consumes cached geometry/classes/styles rather than scanning classes or cloning arrays each frame.
- [ ] Move CSV formatting and clipboard access to an app-owned export worker using the accepted Arc snapshot. Header fields: `distance_m,ground_elevation_m,clutter_height_m,surface_elevation_m,land_cover_class,drawn_ground_m`. Ground/surface values stay invariant across projections; only explicitly named drawn_ground_m follows projection. Preserve existing data availability and show success/error status. No image/report export is implied by `Export…` in this release.
- [ ] Run focused workbench/jobs/export tests and `cargo check`; inspect diff for unrelated window/dirty-file edits. If commits requested: `feat(link-profile): integrate responsive path workbench`.

## Task 9: Companion Guide and indexed user documentation — GPT-6 Luna, wave C

**Owned files:** Create only `src/app/ui/link_profile/guide.rs`; modify only `docs/how-to/evaluate-a-radio-link.md`. Root owns shared component, settings/lifecycle and controls/README edits.

**Consumes:** Existing CompanionGuideSpec/CompanionGuideStep, exact spec copy and integrated control labels. **Produces:** `pub(crate) const LINK_PROFILE_GUIDE: CompanionGuideSpec`, route `docs/how-to/evaluate-a-radio-link.md`, title `Link Profile Guide`, preference `Show guide when Link Profile opens`.

- [ ] Luna implements the six specified steps/caveats and updates the existing indexed guide for legend, A/B labels, Surface/Ground references, direction comparison, frozen inputs, finite-step solver, preview/apply, projection and refresh. Remove claims that every solved height is AGL or an exact continuous minimum. Do not describe forward-only solving as a two-way guarantee.
- [ ] Root wires CompanionGuide::new("link-profile-workbench", "link-profile-guide") into workbench state and syncs lifecycle both before and after rendering. Dismissal persists through pair switching/refresh in the same opening; owner close dismisses. Opening docs resolves/launches on a background worker. Save auto-show changes via Task 1 settings queue.
- [ ] Root adds only necessary integration tests `link_profile_guide_dismissal_survives_pair_switch` and `link_profile_guide_closes_during_preparation_close`; reuse the component's existing focus/viewport tests. Settings default/round-trip already belongs to Task 1. Do not write tests mirroring guide sentences.
- [ ] Root runs guide lifecycle tests and `pwsh -File tools/check-doc-links.ps1`. Inspect rendered guide for scrolling/footer reachability and complete documentation link. Update controls reference and README wording only to describe implemented capabilities. If commits requested: `docs(link-profile): explain inspection and height workflow`.

## Task 10: Integration review and evidence — root

**Files:** Review all task patches; record actual outcomes in this plan's Completion evidence section only after execution. Keep source screenshots illustrative until an actual runtime capture exists.

- [ ] Review every spec requirement against a task/result. Check legend-to-style correspondence for every rendered mark, frozen identity including refreshed surfaces, reverse direction behavior, actual height references, finite-step claims, export projection fields, failure states, and apply/undo.
- [ ] Run `cargo check`, `cargo fmt --all -- --check`, `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test`, `pwsh -File tools/check-doc-links.ps1`, and `git diff --check`. Report ignored/opt-in tests and failures caused by unrelated dirty files separately. Do not broaden external/live tests without a reason.
- [ ] Exercise native runtime fixtures: clear path, clutter obstruction, Surface roof, mixed categorical/LiDAR, offline/canceled preparation, asymmetric radios/noise, missing requested noise, unsupported reverse model, long/identical names and both UnitSystems. Verify window resize/DPI, guide focus/dismissal, pan/zoom labels, legend visibility, keyboard sample selection, preview/apply/undo and cancellation under input edits.
- [ ] Obtain an independent review of the scientific/lifecycle integration on the main capable model. Luna can separately check the visible legend/labels/guide against the supplied artifact without repo-wide context. Resolve material findings and rerun only checks justified by changed code.
- [ ] Capture representative native screenshots and document what was actually exercised. If no native runtime is available, report that limitation; headless frame tests are not runtime proof. Preserve all unrelated changes and do not stage/commit unless requested.

## Completion evidence

Executed in `codex/link-profile-workbench` at `D:/code/ridgecast/.feature-work/worktrees/link-profile`, isolated from the LiDAR implementation. The subsequent user execution request authorized implementation and focused commits, superseding the planning-only creation boundary.

Tasks 1–9 are implemented: immutable preparation generations, shared geometric diagnostics and directional budgets, persistent styled legend, structured Inputs, external A/B mounting-reference captions and clipped markers, retained sample inspection, frozen finite-step height proposals with request-owned undoable application, responsive owner/inspector/export lifecycle, persisted Companion Guide preference, and indexed user documentation. Public headless budget names and serialized fields remain compatible. The full test suite caught an atmospheric-error detail regression; its explanatory wording was restored.

Actual validation:

- Full `cargo test`: 2,082 passed, zero failed, 20 ignored; binary/doc-test targets also passed. Ignored live/download/timing/image-capture tests were not enabled.
- After independent review fixes, `cargo test --lib link_profile_`: 47 passed, zero failed. Coverage includes receiver asymmetry and missing requested noise, direction-local model failure, geometry versus Fresnel clearance, invalid/two-endpoint geometry, cancel/retry/rapid-refresh tokens, source/document identity, request-owned apply/undo edits, Surface-reference round trip, minimum total independent tested height, CSV physical invariance, legend clicks, guide lifetime, offscreen labels, fit bounds, and narrow/high-DPI frames in both UnitSystems.
- `cargo clippy --all-targets --all-features -- -D warnings` passed with an isolated target and four build jobs. `cargo check`, `cargo fmt --all -- --check`, the local documentation-link checker (67 Markdown files), and `git diff --check` passed.
- An independent capable-model source review identified missing painted-mast auto-bounds when LOS/Fresnel layers were off. A failing regression reproduced the issue, then passed after including current/proposed mast positions independently of display-layer visibility. The y axis explicitly distinguishes curvature-adjusted drawn elevation from the true-terrain projection.

Execution rulings: Luna delivered the legend leaf. Agent-thread limits prevented further planned leaf dispatch; the feature integrator implemented Inputs, annotations, guide/docs and their acceptance tests inline. Core identity/geometry and integration behavior had verified failing tests before implementation; later specialized acceptance tests supplemented that coverage. Ledger/logs remain local under `.superpowers/sdd/2026-10-07-link-profile-workbench/` and are not product artifacts.

Native runtime fixtures and screenshots were **not run**. Headless egui frames cover the specified viewport sizes, 2x DPI, long/identical names and both UnitSystems, but are not native runtime proof. Task 10's native interaction/capture acceptance remains an explicit validation limitation. Final cross-feature integration/review and merge to main are owned by the main integrator.

Final integration: Link Profile merged into local `main` at `faf79bda`; adaptive LiDAR subsequently merged cleanly at `c8739738`. The combined tree passed `cargo check`, `cargo fmt --all -- --check`, strict all-target/all-feature Clippy, and full `cargo test`: 2,160 passed, zero failed, 32 ignored; binary/doc-test targets passed. Documentation-link validation checked 67 Markdown files and whitespace checks passed. The independent scientific/lifecycle review and its mast-fit regression remain covered in the combined suite. Only documentation evidence changed after these checks. Native interaction/capture remains unrun; no remote is configured.
