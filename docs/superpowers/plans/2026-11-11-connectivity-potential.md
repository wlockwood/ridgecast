# Connectivity potential implementation plan

**Goal:** Add cycle-safe recursive link opportunity coloring and a useful node connectivity ranking, without doing graph analysis on the UI thread.

**Design:** Connectivity Potential uses enabled, non-hidden radio nodes and one logical undirected connection per pair whose two directions have finite SNR at or above the global threshold. Self-links, reciprocal duplicates, markers and ineligible endpoints do not contribute. Display filters and selection do not redefine this analysis graph.

For each tested connection, remove it, BFS from both endpoints, and assign every other logical connection to the closer endpoint (using minimum endpoint hop distance); equal distances split its credit. A connection at hop depth h contributes beta^h, default beta=0.5, configurable 0..1. Each side starts with 1 for the tested connection. Score = harmonic mean of the two side totals, so a leaf cannot inherit a large region's full score. It is 1 for an isolated pair and 100 for two 100-link stars joined at their hubs. Cycles never create repeated credit. This is a custom neighborhood opportunity heuristic, distinct from bridge betweenness or actual next-build marginal benefit.

Node Harmonic Connectivity is the standard sum of 1/shortest-hop-distance over other reachable nodes, each counted once, unreachable zero. It gets a map view and a highest-first Network sort. This is a topology screen; population and unique area benefits remain separate, existing coverage-based scores. The research record explains why deployment ordering additionally needs built assets, costs, and unique service coverage.

**Execution:**
- [x] Pin isolated-pair, two-stars, cycles, long-chain leaves, graph eligibility, cancellation and cache invalidation behavior with tests.
- [x] Implement cancellable worker-side graph analysis and a versioned shared cache that rejects stale results.
- [x] Add link mode/settings, node mode/sort, numeric hover details, pending states and export integration.
- [x] Document exact formulas, assumptions, research and limits; run focused and full project checks.

**Constraints:** Preserve unrelated dirty-checkout work. Maintain selection draw order, per-mode filtering and full tooltips. Use neutral pending colors and no previous-document scores. Preserve the existing explicit Hidden export fallback. No terrain/population I/O or graph BFS on the UI thread.

**Review:** A separate research agent reviewed graph centralities and baseline-dependent service utility. A separate code reviewer identified graph capture retention during BFS; both link analysis and harmonic sorting now extract owned compact topology and release the shared graph before expensive searches. Storage-probe tests verify release and edit isolation. The reviewer verified the fix. Full link analysis starts only for the active mode or an expanded settings section.

**Measured scale check:** The 500-site / 2,299-logical-link regression completed in approximately 0.35–0.69 seconds in observed debug test runs. This is a focused worker measurement, not a desktop responsiveness qualification.

**Final verification:** `cargo check`, repository-wide formatting, strict all-target/all-feature Clippy, local documentation links, and `git diff --check` passed. Full `cargo test` passed: 2,521 tests passed, 39 ignored. This includes rendered settings-window coverage for all five modes and the new topology, sorter, worker-input ownership, display filtering, and cache regressions. Desktop appearance has not been manually inspected.
