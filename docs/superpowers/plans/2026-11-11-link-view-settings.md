# Link view settings implementation plan

**Goal:** Keep selected-node links above other links and expose understandable per-mode styling and filtering under View → Links.

**Design:** Keep existing mode choices and add a separator followed by Link View Settings. A nonmodal, scrolling window contains all four modes; opening it resets expansion to the current mode only. Each visible mode owns its filters and palette. Fade Margin offers quality bands or a smooth scale; Distance and Fortuity offer fixed or filtered-network-relative scales. Fortuity retains the bounded product heuristic, with adjustable positive distance/margin references and two illustrated boundary links. Settings follow the existing session-scoped link view selection. Hidden explains its behavior.

**Approach:** Share a small display model between map and export, rather than duplicating filtering and normalization. Preserve map geometry and selection emphasis; partition links into ordinary and selected-node passes in linear time. No terrain work, file I/O, or propagation runs are introduced in the UI. Existing unrelated checkout changes must be preserved.

- [x] Add focused regression tests for filtering, non-finite metrics, flat ranges, selection order and Fortuity references/boundaries.
- [x] Implement the shared link display model and integrate map/export, preserving default coloring where possible.
- [x] Add the menu entry, collapsible settings UI, illustrative samples and descriptive tooltips on every control.
- [x] Document the heuristic and controls; run formatting, check, strict Clippy, tests and doc links.

**Validation limits:** Automated egui frames can exercise the window and its controls; desktop/GPU appearance requires a live application check.

**Completed validation:** `cargo check`; strict Clippy with all targets/features; full `cargo test` (2,509 passed, 39 ignored); local documentation links; `git diff --check`; focused rustfmt on all feature files. Eight focused tests cover the display model and rendered window, including reopening every mode and preserving US-customary conversions. A separate source review found terminology and palette-label issues, now corrected.

**Repository-wide formatting:** `cargo fmt --all -- --check` reports an unrelated existing/concurrent formatting difference in `src/coverage_run.rs` around the merged-cell iterator. It was left untouched. Desktop appearance was not manually checked.

**Compatibility decision:** Explicit image export's Include Links option retains its historical Fade Margin fallback while the map mode is Hidden, applying the new Fade Margin palette and filters. The window, export tooltip, and user docs explain this.
