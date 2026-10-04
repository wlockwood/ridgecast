# Save and Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement task-by-task.

**Goal:** Make saving understandable and prevent document loss.

**Architecture:** Extend the existing saved snapshot and transition gate with separate recovery storage and a save controller. Apply worker results only to matching documents and authored revisions.

**Tech Stack:** Rust, egui, serde, atomic persistence, mpsc workers.

**Spec:** [Approved behavior](../specs/2026-10-02-save-and-recovery.md)

## Global Constraints

- Preserve unrelated dirty work; do not stage or commit.
- No filesystem work, serialization, or blocking dialogs on UI paths.
- Compatible project serialization and tooltips on new controls.
- Test recovery only in temporary directories.

## Review Focus

- Edits during saves stay dirty; undo to the saved content becomes clean.
- Pending workers cannot recreate discarded recovery records.
- Failed/canceled replacement imports retain the current document.
- Quit after Save waits for completion and reports failures.
- Malformed recovery and competing legacy encodings preserve recoverable data.

## Tasks

- [x] Storage: add failing temp-directory tests; implement versioned recovery records, atomic persistence and baseline roundtrips in `src/network_recovery.rs` and `src/network_file.rs`; run focused tests.
- [x] Controller: add state tests for dirty/undo, save/edit races, recovery versus explicit baseline, cancellation and failures; implement `src/app/document_save.rs`; replace ordinary autosave with recovery; add async Save/Save As, status, title marker and shortcuts.
- [x] Transitions: gate pending saves, worker shutdown drain, recovery discard only after replacement success; stage source imports and reject stale merges; offer startup recovery and newest valid legacy default.
- [x] Verification: update user docs, run build/fmt/Clippy/offline tests, independent review and remediate findings.

Execution ruling: the user explicitly requested implementation of the reviewed
design. Work in the current dirty checkout, preserving its newer transition
code. Storage and docs run independently; primary agent integrates app changes.

Verified on 2026-10-02: cargo check, formatting check, full-target/all-feature
Clippy with warnings denied, and documentation links (52 files). Offline suite:
1,346 passed, 17 ignored, five network-dependent terrain/download tests skipped.
Save/recovery regressions passed again after final UI corrections. Independent
review found and verified fixes for shutdown/editor and late-worker races,
referenced-layer restoration, nonfinite numeric data, and UI baseline copying;
the final re-review reported no remaining actionable defects. Native GUI flows
were not manually exercised. Implementation left the changes uncommitted;
the user subsequently requested focused commits of this work.
