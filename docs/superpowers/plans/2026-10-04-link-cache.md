# Network Link Cache Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Reuse completed network link solves from disk without repeating LiDAR work.

**Architecture:** Add a worker-owned `LinkCache` with semantic keys and fresh
source validation. Integrate it into the shared `LinkSolve` path and existing
category-local disk maintenance.

**Tech Stack:** Rust, existing Serde, SHA-256, zstd, and egui progress channels.

**Spec:** [Link cache design](../specs/2026-10-04-link-cache-design.md).

## Global constraints

- No filesystem work on the UI thread; no new dependencies.
- Keys use frozen inputs and exclude names and display settings.
- Canceled, changing, incomplete, or invalid results are never published.
- Missing link budgets in old files mean unlimited; new configurations use 256 MiB.

## Review focus

- A fresh process must reuse unchanged files without relying on load counters.
- Failed source restoration must not reuse a previously complete calculation.
- Empty results must prevent repeated expensive negative evaluations.
- Corrupt or oversized data must cause a bounded miss without a panic.
- Concurrent writers and canceled publication must preserve complete entries.

## Task 1: Persistent results and source identity

Files: create `src/engine/link_cache.rs`; modify `src/engine/mod.rs` and
`src/engine/landcover.rs` for registered-source identity access.

Interfaces: `LinkCache::new(&Path)`, `read(key) -> Option<CachedLinks>`,
`write_if_current(key, &CachedLinks, current)`, semantic `LinkCacheInputs`, and
worker-only `source_fingerprint`.

- [x] Add failing restart, corruption, numeric-bit, freshness, and key tests.
- [x] Run focused tests and verify the missing behavior fails.
- [x] Implement bounded, checksummed, compressed atomic persistence and keys.
- [x] Add metadata and registered-source invalidation/cancellation tests.
- [x] Run focused tests.

## Task 2: Shared solver integration and managed storage

Files: modify `src/link_solve.rs`, desktop/headless `LinkSolve` builders and their
test fixtures, `src/engine/disk_cache.rs`, and relevant docs.

- [x] Add a solver regression showing a repeat solve skips expensive phases.
- [x] Integrate cache reads after fresh noise sampling, output through existing
      result channels, and writes after complete stable batches.
- [x] Reject incomplete terrain, clutter, propagation and LiDAR output for caching.
- [x] Add Links category/budget and verify it stays separate from coverage/data.
- [x] Document repeat reuse, invalidation, clear/eviction, and scope limitations.
- [x] Run application tests, strict Clippy, formatting, and doc-link checks.
- [x] Independently review the change and prepare the verified commit.

Validation uses an isolated copy of HEAD plus this change because other sessions
are editing shortnames, progress reporting, and screenshots in the shared tree.
The independent review covered source freshness, incomplete preparation, file
publication, and shared acquisition coordination.

Application validation passed 1,839 tests with 16 ignored. Cargo check,
Clippy (`--all-targets --all-features -- -D warnings`), formatting, and links
in 56 Markdown files passed against the isolated source. All 14 MCP member tests
also passed. No live large-network LiDAR timing benchmark was run.
