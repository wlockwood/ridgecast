# Site Finder remediation implementation plan

**Goal:** Implement the approved Site Finder correctness and performance fixes and regional vector water acquisition for terrain rendering and conservative candidate exclusion.

**Architecture:** Publish immutable result chunks through a bounded latest-value mailbox, retain compact results with shared explanation data, and reuse source-specific decoded caches while freezing scan configuration. A shared vector water service downloads validated OpenMapTiles water polygons on workers, persists them for offline reuse, and provides display masks and conservative candidate classification.

**Tech stack:** Rust, egui, rayon, reqwest, serde, existing terrain and download services.

**Spec:** Approved remediation in the conversation and `docs/superpowers/specs/2026-10-06-vector-water-design.md`.

## Global constraints

- Preserve cancellation, scan provenance, saved refinement checks and existing JSON result shape.
- Keep network, disk decoding, candidate classification and whole-result processing off the UI thread.
- Keep source/configuration snapshots immutable, including download mirror lists.
- Vector water: two acquisition workers; queue at most 64 source tiles; managed decoded geometry cache at most 64 MiB, with a frozen scan retaining at most another 64 MiB; metadata at most 256 KiB; compressed tile at most 8 MiB; decompressed tile at most 32 MiB; vertices at most one million; topology comparisons at most eight million per tile.
- Water rendering respects polygon holes and unions, and valid detailed vector tiles take precedence over land-cover and bundled overview data. Candidate filtering retains unknown/mixed cells.
- The user requested focused commits after implementation. Work in the approved current branch and preserve other edits.
- Developer instruction limits tests to an explicit user request. The user subsequently requested geometry, acquisition, terrain integration, appearance and full Cargo verification; that verification is included below.

## Review focus

- Minimized consumers must retain bounded publications and a reliable final state.
- Continuous result arrivals must permit useful previews to finish.
- Failed preparation must not prevent later new scans, and partial failures must remain usable.
- Source edits must not mutate a running scan or weaken persistent link-cache freshness.
- Shorelines, islands, tile boundaries and high latitudes must keep possible land origins eligible.

## Tasks

1. [x] Result pipeline and compact explanation storage (`jobs`, `site_finder`, app result consumers, export): immutable append chunks, latest mailbox, 200 ms cadence, compatible serde and stable candidate keys.
2. [x] Source cache reuse (`terrain`, providers/fetcher, landcover, population): share managed decoded payloads for scan forks, freeze mirrors, retain link cache isolation and source identities.
3. [x] Vector water service (`map/water_vector*`, map registration, cache manager): bounded MVT decoder, workers, metadata/cache, offline/control integration and geometry queries. This independent module can be delegated while task 1 runs.
4. [x] Scan correctness (`site_finder`, assumptions, headless): actual captured source provenance for fresh scans, conservative batch footprint classification with progress, partial failure outcomes and remove redundant late configuration check.
5. [x] UI/render integration (`site_suppression`, UI/map and window, SRTM): reuse valid suppression, refresh selections, borrow assumptions, finish compatible previews and consume vector water without blocking.
6. [x] Documentation and verification: update user docs, attribution and approved design status; run `cargo check`, `cargo fmt --all -- --check`, strict Clippy and documentation links; independent read-only final review and address material findings.

## Execution record

The user approved the remediation and requested implementation. Continue without an additional plan approval. Independent delegated modules have disjoint ownership; the main agent owns integration and all shared files. Compilation gates may wait for dependent module interfaces to land.

Implemented on 2026-10-07 in `codex/sidebar-workbench`. The user subsequently requested focused commits; their source and documentation scopes exclude concurrent map-guide and link-profile work.

The independent source review found and resolved these follow-up issues:

- Repeated refinement at the same resolution must invalidate suppression for the combined tier, rather than stamp only the new subset as valid.
- Water tile arrivals must invalidate only affected terrain tiles and let an active compatible renderer finish, preserving its last painted fallback.
- Visible geometry evicted from the water cache must become loadable again without cycling an oversized visible working set.
- The manually painted terrain overlay needs an explicit OpenMapTiles/OpenStreetMap attribution footer; exported Site Finder PNGs retain provider credit.
- Imported scans with no vector water identity must retain that absence on refinement. A nonempty identity requires its exact retained snapshot, and fresh scans/imports/clearing create a new publication slot. An active frozen scan keeps its slot when ambient-noise settings change.

Validation commands completed successfully:

```text
cargo check --message-format short
cargo fmt --all -- --check
cargo clippy --all-targets --all-features --message-format short -- -D warnings
pwsh -NoProfile -File tools/check-doc-links.ps1
git diff --check
```

Initial documentation links: 61 Markdown files checked. At that stage, existing test fixtures were adapted to the new result APIs and compiled by Clippy; tests and live visual validation had not been requested or performed.

## Requested water verification follow-up

The user then requested explicit behavioral and appearance verification before finishing the commits. Independent geometry and acquisition validation used an isolated copy of the reviewed source while the shared checkout contained active edits to unrelated guides.

Observed failing repros led to these fixes:

- Prepare both cache payload and integrity sidecar before publication; cancellation before publication preserves the previous usable pair. Publication still uses two atomic renames, so a process or disk failure between them causes an integrity-rejected cache miss on restart.
- Canceled or obsolete tile requests and canceled metadata refreshes no longer impose failure retry penalties.
- Validate layer metadata before treating a tile without water as authoritative land; reject self intersections, escaping/crossing/nested holes and adjacent backtracking edges.
- Bound polygon topology sweep and containment work to eight million comparisons per tile, with cancellation checkpoints. Limit exhaustion retains fallback, including for unusually complex valid geometry. Sorting the bounded edge index is not interruptible.
- A genuine provider tile exposed an isolated shared endpoint between its exterior and an island hole. A 13-vertex extracted fixture reproduced the rejection. Preserve those enclosed tangent polygons for display, but prohibit their use for Site Finder exclusion; continue rejecting crossings, overlaps, self contacts and hole/hole contacts. All 237 downloaded Seattle tiles decode with the final policy; one polygon uses this display-only rule.
- Add the OpenFreeMap serving-provider link to the viewport attribution and PNG export footer alongside OpenMapTiles and OpenStreetMap credits.

Initial focused verification passed 55 vector-water tests covering polygon holes, overlapping features, river areas, empty tiles, malformed data, parent crops, buffered seams, dateline snapshots, fractional coverage, worker/queue bounds, deduplication, cancellation, backoff, cache integrity, persistent accounting, restart reuse, offline zero requests and failed metadata refresh preservation. The geographic compatibility follow-up passed 37 decoder/geometry tests, including four additional tangent/escaped-hole cases, using the exact production modules in a scratch harness.

Three terrain integration tests passed across all six styles, covering authoritative vector precedence, fractional shores and island opacity, normal/multiply payloads, fallback retention during loading and selective tile refresh. Two cache-manager tests cover raw tiles, sidecars and metadata accounting, eviction and clearing without deleting terrain.

The explicit fixture capture produced nine PNG contact sheets in `output/site-finder-water-comparisons/`: three scenes at zooms 10, 12 and 14, with all six terrain styles and both blend modes. These use synthetic elevation and geometry with a neutral None basemap; they supplement geographic native GPU captures and do not establish live shoreline accuracy.

### Final Cargo and documentation gates

The isolated source contains the exact reviewed implementation, the final water
fixes, and the concurrently committed viewport/node guides. Byte comparison
confirmed all 14 water follow-up files match the working source. Full output is
retained in `output/site-finder-commit-check/`.

```text
cargo check --workspace --message-format short
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features --message-format short -- -D warnings
cargo test --workspace -- --test-threads=1
pwsh -NoProfile -File tools/check-doc-links.ps1
git diff --check
```

All passed. The commands used the isolated manifest and the shared build target.
The main library passed 2,039 tests and the MCP server passed 14, with zero
failures. The main suite ignored 20 tests. The current checkout's documentation
checker covered 67 Markdown files; the isolated documentation covered 63.
No timing benchmark was run.

All 297 application and MCP source files match the tested source copy after
normalizing Windows line endings.

### Native geographic appearance validation

Fifty native eframe 0.36.2 / egui-wgpu screenshots completed on an NVIDIA
GeForce RTX 4070 Ti using Vulkan. Each capture waited for all visible terrain
textures, no active/dirty renders, and two seconds of settled state. Every
after frame additionally required all visible vector water tiles to decode.
All captures passed these readiness gates, with no final cached-read/decode
errors.

The geographic inputs were real cached USGS 3DEP terrain and NLCD, plus 275
OpenFreeMap tiles fetched live using the application User-Agent. The native
application then read these integrity-checked files offline in an isolated
configuration and cache. Provider template:
`https://tiles.openfreemap.org/planet/20261004_113936_pt/{z}/{x}/{y}.pbf`.

| Capture group | Coverage |
| --- | --- |
| Puget Sound, Lake Washington/Mercer Island, Duwamish River | Before/after at zooms 12, 13 and 15, absolute elevation, Normal blend: 18 frames |
| Lake Washington/Mercer Island | Six styles, Normal and Multiply, before/after at zoom 13: 24 frames |
| Contour control | 10 m contours on/off with None basemap: 2 frames |
| Blakely Harbor coastal detail | Before/after at zooms 12, 13 and 15: 6 frames |

The comparison sheets show smoother coastline and river boundaries than the
square NLCD fallback, with Mercer Island and its channels retained. Provider
credits are visible. Contour-off matches the regular disabled-contour map
exactly outside the capture label; contour-on adds visible lines. The complete
style/blend matrix was exercised at lake zoom 13; the geographic scene/zoom
matrix used absolute elevation and Normal blend. The separate synthetic
contact sheets cover all styles/blends at all three fixture zooms.

Artifacts are retained in `output/site-finder-water-visual/`, including
`validation-report.txt`, comparison sheets, all 50 PNGs, readiness logs,
provider/source manifests and `capture-metadata.json`. Metadata SHA-256:
`890eb9357fe8846b181f4f6f993e594df68b51712279db71d9d295890c7a817a`.

The original black-water coordinates were not supplied, so that exact view
remains untested. The live native runs used None basemap and cached provider
files; Road compositing, successful HTTP acquisition within the running
application, interactive navigation and PNG export appearance were not
captured. Export attribution was inspected and included in the verified source.
Normal and Multiply can look alike over a white None basemap. Lake zooms 12/13
show the island in context; zoom 15 emphasizes the western channel, with Mercer
shoreline at the edge. The native lake includes one major island; multiple
island holes are covered by separate fixtures. The comparisons use the current
renderer with and without regional water, rather than a historical application
binary.

### Implementation commits

- `6873546`: reuse decoded source caches across Site Finder scans.
- `0aa9ccf`: persist regional vector water and integrate terrain rendering.
- `1aabf84`: bound result publications, retain frozen inputs and integrate Site Finder.
- `7256729`: geometry/cache cancellation fixes, provider compatibility, terrain/cache regression coverage and attribution.

### Tests ignored by the default suite

The suite reports 20 ignored tests. The fixture capture above was run separately and passed; the other 19 were not run in this follow-up. These require external datasets, live downloads, machine-specific caches, GPU measurement or a timing benchmark.

```text
amateur::tests::imports_checked_in_snapshot
engine::disk_cache::tests::the_real_cache_on_disk_is_accounted_for
engine::itm_dsm::live_plan::plans_a_real_network_without_downloading_point_clouds
engine::itm_dsm::live_plan::prefetch_downloads_missing_tiles_into_the_store
engine::landcover::tests::test_landcover_deduplication
engine::lidar::surface::tests::a_real_3dep_acquisition_produces_a_populated_surface
engine::population::tests::staged_constrained_cogs_decode
engine::source_probe::tests::source_probe_live_population
engine::source_probe::tests::source_probe_live_terrain
engine::terrain::blob::tests::real_cached_tiles_survive_compression_and_still_decode
engine::terrain::glo30::tests::test_mirror_failover_rolls_over
engine::terrain::tests::test_coverage_prefetch_downloads_missing_tiles
engine::terrain::us3dep::tests::test_maple_valley_12km_link
engine::terrain::us3dep::tests::test_us3dep_deduplication
engine::terrain::us3dep_s3::tests::test_decode_local_tiff
engine::terrain::us3dep_s3::tests::test_s3_tile_download_and_decode
map::srtm::tests::contour_render_timing
map::srtm::tests::vector_water_tests::capture_vector_water_terrain_comparisons
performance::tests::quick_benchmark_measures_selected_available_backends
performance::tests::real_gpu_fixture_produces_a_complete_site_result
```
