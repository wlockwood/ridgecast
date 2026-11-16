# Partial link cache in network files

Store an optional versioned sparse ledger in network JSON/YAML, with the solver input identity and cutoff. Each directed pair records a passing calculation, a below-margin calculation, a pruning reason, or unavailable/invalid evidence. Absence means unknown, never an inferred failure or pruning result. Persist finite directional budgets and provenance. Legacy network files continue loading.

The ledger uses immutable bounded batches with shared ownership: document captures stay cheap and applying worker batches does not copy all earlier results. Serialization, validation, resume indexing and file I/O remain on workers. Keep derived cache changes outside authored dirty tracking. Explicit saves and recovery captures include the current partial ledger.

On open, matching sparse records resume individually; retry unknown or unavailable pairs. A completed legacy positive-only disk cache or file can seed passing records, without implying outcomes for missing pairs. Explicit recalculation refreshes results. Input identity includes RF/model/version/cutoff assumptions; mismatches start a new ledger. Share path preparation while retaining independent directional evaluations and the existing 128-link publication contract.

- [x] Add ledger types, sparse lookup/validation, structural-sharing and JSON/YAML round-trip tests.
- [x] Integrate incremental evaluation/pruning publication and partial resume in the solver.
- [x] Save/load the ledger in network and recovery files, keeping change detection authored-only; preserve partial headless results on cancellation under existing revision/generation guards.
- [x] Exercise interruption/resume, input invalidation, missing data, asymmetric outcomes, legacy files and publication ordering; update user docs and run project checks.

Review fixes: aggregate prune evidence across calls into 128-record messages; flush completed interruption tails; take surface cache eligibility once per run; throttle derived recovery checkpoints independently of authored dirtiness; protect restored cache evidence until saved; compact retry history before resume; bound actual project/recovery serialization and trim optional evidence while preserving live cache and authored data. Last-owner cache retirement runs off the application main thread.

Validation: full `cargo test` passed (2,531 passed, 39 ignored), `cargo check`, formatting, strict all-target/all-feature Clippy, documentation links (71 Markdown files), and `git diff --check`. A separate reviewer confirmed the persistence, recovery, cancellation, bounded-publication, and size-path fixes by source inspection. Desktop interaction was not manually exercised.
