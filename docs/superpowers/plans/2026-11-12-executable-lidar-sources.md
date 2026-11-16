# Executable LiDAR clutter sources implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Execute continuously through integration and validation.

**Goal:** Make the supplied national and state clutter sources executable, with concrete failures for unavailable delivery or missing credentials.

**Architecture:** Separate provider discovery from EPT/COPC/LAS and numeric-raster readers. Freeze source identity, canonical unsigned assets, CRS/units and dependencies per request. Preserve native EPT cache identities and supplied-raster provenance; the configured terrain source stays authoritative.

**Tech Stack:** Rust, controlled reqwest/download tracking, las/laz, tiff, proj4rs and managed caches.

**Spec:** The user's source-selection, mirror, state-filter and clutter-only requirements in this session, plus the supplied research handoffs.

## Global constraints

- No blocking UI work; every control has a tooltip.
- Preserve cancellation, Pause/Offline/Cancel All, bounded allocation and cache admission.
- Never treat ground or hillshade as clutter, fabricate point evidence for rasters, guess projected CRS, or equate catalog membership with adapter support.
- Preserve concurrent checkout changes and backward-compatible settings and default cache identities.

## Review focus

- Retain every intersecting small tile within a selected survey.
- Refuse ignored ranges, malformed/cyclic hierarchy pages and changing objects without oversized downloads or allocations.
- Keep signed URLs transient and redact credentials from persistent identities and diagnostics.
- Validate companion survey/grid/units when deriving height from absolute surfaces.
- Isolate source configurations while deduplicating canonical asset transfers across links.

## Tasks

- [x] Controlled range transport, entity validation, cache and transient signing; protocol/refusal/cancellation tests.
- [x] General EPSG transforms, bounded COPC and direct LAS readers; real fixture and malformed-input tests.
- [x] Lazy COG/GeoTIFF and ArcGIS numeric crops producing supplied clutter rasters; pairing and NoData tests.
- [x] Direct, STAC API/static, ArcGIS index, S3/HTTP inventory and provider JSON discovery; bind each relevant entry or document its concrete limitation.
- [x] Catalog source selection through settings, frozen requests, planning and persistent cache identity.
- [x] Integrated point/raster execution, shared dependencies, retained products and failure diagnostics.
- [x] Usable filtered source dropdown and user documentation.
- [x] Focused fixtures, bounded live probes, full check/fmt/Clippy/tests/doc links and integrated review.

## Validation result

The registry binds 90 clutter entries to acquisition readers; 13 retain concrete access or compatible-data blockers. Ground-only records stay hidden. Desktop tests: 2,693 passed, 42 intentionally ignored; MCP tests: 32 passed. Workspace/build, formatting, strict all-target/all-feature Clippy, catalog schema/import checks and documentation links passed. Live Microsoft point and raster crops passed; two raster requests shared 58 dependencies and warm persisted reuse fetched zero bytes. Wisconsin spatial inventory selected the requested tile. Desktop appearance and exhaustive vendor coverage were not manually qualified.
