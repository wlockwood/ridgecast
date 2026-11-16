# Proto-link horizon pruning implementation plan

> **For agentic workers:** Execute inline with `superpowers:executing-plans`; request one independent final review.

**Goal:** Reject implausibly distant network proto-links before terrain corridors or measured-surface planning, using each antenna's actual elevation plus 50 m.

**Architecture:** A run-owned gate lazily samples each participating endpoint once after the existing bidirectional FSPL gate. It sums both smooth-Earth radio horizons (k=4/3, R=6371 km) without an x2 multiplier. The antenna height is actual configured AGL plus the 50 m allowance; it is not a 50 m minimum. Surface-referenced antennas include known categorical clutter, and bypass screening when measured-surface height or classification is not known. The initial scope is median/default ITM, matching the qualification; other propagation settings retain full evaluation.

**Tech Stack:** Rust, existing TerrainManager/LandCoverManager, unit/integration fixtures, Cargo checks.

**Spec:** User request in this conversation; empirical evidence in `.superpowers/horizon-evaluation/heights/`. The additive implementation is more permissive than the already qualified 50 m floor for this file's 12.192 m antennas.

## Constraints and review focus

- Preserve unrelated changes in this shared dirty checkout; no commits, publication, application termination, or configuration edits.
- All endpoint reads stay in the existing LinkSolve background worker. Cache hits must bypass new terrain work.
- Cancellation is checked before/between endpoint reads; do not cache missing endpoint data as a zero-height site.
- Missing/invalid terrain or uncertain antenna height keeps the pair. Existing fallback handling and cache eligibility still apply when retained pairs are actually sampled.
- Use the same gate before measured-surface planning and the actual directed evaluation; maintain target scope and progress totals.
- Preserve high tower/tree height and both mountaintop elevations. Do not use inflated heights in propagation itself.
- Advance completed-link calculation identity to invalidate old disk and saved-network results; single-link inspection remains available without this network heuristic.

## Implementation

- [x] Add failing geometry and worker regressions for additive tower height, mountain-to-mountain geometry, missing data, cancellation, and pre-corridor pruning.
- [x] Implement `src/link_solve/proto_links.rs`, lazily sample endpoints and wire both network loops after FSPL; record screening counts in performance telemetry.
- [x] Advance the link calculation version; preserve unrelated cacheability fixtures by keeping their corridors within the new horizon.
- [x] Document the approximation, additive allowance, eligible model/settings and fail-open behavior in reachable user docs and README.
- [x] Recheck the additive rule against the existing network qualification, run focused and full project checks, obtain independent review, and build a separate reviewable executable.
