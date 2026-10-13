# Site Finder workbench implementation plan

> **For agentic workers:** Use superpowers:executing-plans and superpowers:dispatching-parallel-agents to implement the independent components, then integrate and verify them together.

**Goal:** Implement the approved Site Finder workbench, application-wide Pocket Node and calibration, reusable Companion Guides, conservative water eligibility, and accurate candidate score explanations.

**Architecture:** Preserve immutable scan assumptions and the existing asynchronous live diversity controller. Keep the window as a presentation layer over worker jobs. Record score contributions in candidate results; never reconstruct weighted scores from grade counts. Application-owned calibration workers and storage serve both Coverage and Site Finder independently of tool windows.

**Tech Stack:** Rust, egui 0.36, wgpu, Serde, Rayon, existing asynchronous application workers.

**Spec:** The approved interactive design is in `output/site-finder-layout-review/revision-brief.md` and its control inventory in `review.md`. The latest user amendments take precedence: benchmark ownership is application-wide, every control receives an explanatory tooltip, and candidate score hovers expose the actual mathematics and inputs.

## Global constraints

- Preserve unrelated dirty files and existing live jealousy changes; do not commit without a request.
- No terrain, propagation, file I/O, calibration, or large result processing on the UI thread. Preserve cancellation.
- Existing explicit saved values and historical missing-field defaults remain compatible. New systems use 62.5 kHz.
- Saved scan radios and assumptions are separate from pending next-scan controls. GPU requests must never silently become CPU runs.
- Fully water exclusion requires affirmative water classification of the entire tile; mixed or unknown footprints remain eligible.
- Calibration uses workload-specific units; Coverage units and Site Finder candidates are not interchangeable. Cancellation preserves previous successful measurements.
- Every interactive control, including disabled actions, has a useful tooltip. Document features through the existing user docs index.

## Tasks

- [x] Add and test canonical Pocket Node, new-system bandwidth defaults, legacy deserialization, and built-in availability on existing networks. Integrate the application-wide system pickers and default scan receiver without opening-time network mutation.
- [x] Add and test reusable Companion Guide lifecycle, dismissal, auto-show preference, bounded placement, and Site Finder content.
- [x] Add and test application-owned benchmark/calibration workers, persistent workload/hardware keys, real CPU/GPU fixtures, independent cancellation and lifetime, and Coverage/Site Finder estimation interfaces.
- [x] Record and test raw grade contribution totals and live diversity factor/provenance in scan results. Preserve legacy results with unavailable breakdowns. Render a readable score hover with formulas and frozen inputs.
- [x] Implement conservative background fully-water candidate eligibility, default-on for new scans, saved in assumptions, with shoreline/unknown and cancellation tests.
- [x] Replace the monolithic Site Finder window with responsive Controls/Results panes, frequent controls first, scoped radio/advanced disclosures, distinct backend actions, retained-input inspection, export scopes and selected-site actions. Preserve all existing controls and tooltips.
- [x] Integrate the independent modules with app settings, job polling, performance entry points, Coverage estimates and system selection. Verify saved/partial/imported results and owner-window transitions.
- [x] Update user documentation and README. Run format, cargo check, focused and full tests, strict Clippy and documentation link checks. Request an independent review of the completed change and resolve substantive findings.

## Review focus

Check immutable score inputs, exact agreement of breakdown with the engine score, legacy import honesty, per-resolution diversity math, safe water eligibility, independent benchmark lifetime, calibration scope and restart compatibility, old/new radio defaults, all control tooltips, and wide/narrow usability. Hardware performance claims require an actual successful hardware run; report boundaries explicitly.

## Completion evidence

Implemented the tasks above, including immutable worker-built desktop result
publication, source-selection forks for comparable refinements, exact selected
export identities, preserved interrupted-scan provenance, and scrollable score
details alongside hover math. Independent implementation and UI reviews found
and resolved calibration-envelope, disabled-tooltip, lifecycle, selection,
export and retained-input defects.

Final validation: `cargo check`, `cargo fmt --all -- --check`,
`cargo clippy --workspace --all-targets --all-features -- -D warnings`,
`cargo test --workspace`, `git diff --check`, and the documentation link checker.
Workspace tests: 1,971 library and 14 MCP passed; 19 opt-in tests skipped by the
standard run. Both opt-in native benchmark tests passed separately, including
a real CPU/GPU Quick run (32.88 seconds in the debug test build). The remaining
17 opt-in tests were not run. Local links passed in 60 Markdown files.

Desktop interaction and Extended/release benchmark timing were not manually
exercised. The HTML design prototype is illustrative, not native runtime proof.
Unrelated existing water/provider edits and the active general review session
were preserved. No commit was requested or created.
