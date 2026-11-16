# Terrain blocks, circles and profiles

Large tiled terrain GeoTIFFs are opened as shared rasters. RidgeCast reads and
decodes their native blocks as needed instead of allocating a complete elevation
array for each source file. This applies to supported multi-block tiled TIFFs;
strip TIFFs, unsupported encodings and files with the cache's outer compression
wrapper retain the full-raster decoding path.

For example, a 10812 by 10812 elevation raster occupies about 446 MiB as floats.
A native 512 by 512 block occupies 1 MiB before bookkeeping. Savings depend on
the part of the raster actually needed; broad coverage can eventually touch most
of its blocks. Selective decoding does not itself reduce downloaded file sizes.

## Requests

The terrain service accepts geographic requests and keeps TIFF block numbers
inside the raster layer:

| Rust API | Meaning |
|---|---|
| `TerrainManager::prepare_circle(center, radius_m, active)` | Prepare the blocks intersecting a coverage circle and its interpolation support. |
| `TerrainManager::prepare_corridor(path, half_width_m, active)` | Prepare terrain within the stated distance on each side of a polyline, including its endpoints. |
| `TerrainManager::sample_profile(path, sampling, active)` | Return the entire ordered elevation profile, including position, distance, elevation, source and availability. |
| `TerrainManager::prepare_terrain(footprint, max_bytes, active)` | Prepare a view with an explicit allowance for pinned payloads. |
| `TerrainManager::terrain_batches(footprint, max_bytes, active)` | Process a larger request as geographic batches with the same source snapshot. |

These are worker APIs: calling them on the registered UI thread returns an
error. The `active` callback allows cancellation during planning, waiting and
preparation. It should remain cheap and return false when the operation stops.

A profile needs **sample count or maximum spacing**, not a physical width.
`ProfileSampling::Count(n)` includes both endpoints when `n` is at least two;
`Count(1)` returns the first point. `SpacingMeters(step)` retains
polyline vertices and keeps successive samples within the requested spacing.
Paths follow straight latitude/longitude segments with the shortest longitude
wrap at the antimeridian. Distances are measured along the sampled path.

Use a corridor when the calculation needs terrain beside the centerline, such as
cross-sections or a search for alternative routes. Its width is explicitly the
**half-width in metres**. A zero-width corridor selects the path and its sampling
support; a circle of radius zero selects the center's support.

Blocks intersecting a circle's boundary are included. Testing only block centers,
or requiring the entire block to lie inside the circle, would omit valid edge
terrain. Neighboring pixels required by bilinear interpolation are included
automatically. Corridor selection is conservative and may include extra blocks.

## Prepared views and memory

`PreparedTerrain` retains its captured source rasters and block leases. Sampling
the view cannot start a new source download or silently read unrelated terrain.
It rejects positions outside the requested footprint or the current batch.
Dropping the view releases its pins; the block cache can then evict those blocks
under memory pressure. Other views can share the same blocks without decoding
or accounting for their allocations twice.

Convenience circle and corridor requests use a 64 MiB allowance for pinned
payloads. An indivisible dense raster or native block that exceeds the allowance
returns `LimitExceeded`. Use an explicit suitable allowance where appropriate.
For large requests, call `next_batch` and drop each returned view before requesting
the next one. Keeping earlier views deliberately keeps their data pinned.
`next_batch` returns `Pending` while the preceding view remains alive, so the
iterator cannot silently accumulate an unbounded pinned working set.

This allowance is not a hard limit on total process memory. Source metadata,
existing cache residency, output profiles and other calculations also consume
memory. Decoder scratch has a separate aggregate bound; a corrupt header cannot
multiply a huge padded chunk allocation across workers. See
[data sources and caches](data-sources-and-caches.md) for overall retention budgets.
The fast decoder caps each block's compressed input, expanded bytes and float
output at 64 MiB, with a shared 128 MiB codec-scratch allowance. An outer compressed
TIFF envelope still unpacks as a whole under its existing 2 GiB limit. These are
separate limits; explicit full materialization still allocates the complete grid.

Coverage preparation selects and checks blocks supporting the admitted site's
circle. Checks retain useful decoded blocks in the bounded cache, so the later
solver can reuse them. Network link solving requests complete sampled profiles
in bounded groups and retains the existing calculation's source rules.

## Availability and source identity

A real NoData pixel is different from an unloaded block or failed read. Request
APIs return `Pending`, `Canceled`, I/O errors and limit errors explicitly. A failed
block read remains retryable; it is never permanently installed as an all-NoData
block. A successful sample reports its source. A configured constant fallback
reports `Fallback` rather than claiming measured terrain.

The existing source order, configured vertical offsets, NoData interpolation
weights and confirmed-ocean policy remain in effect. Tiled rasters use positioned
reads from the opened file handle, so atomic replacement of the path cannot mix
new file bytes with old TIFF offsets. Prepared views retain their captured data;
later requests can observe a newer file or configuration generation.

Link workers reuse a profile session within a calculation. The session retains
opened terrain sources while releasing each profile's decoded block leases;
a new calculation starts a fresh session. Persistent link results still require
matching source fingerprints before and after the run. Decoded blocks retain
their completeness flag, so checking an entire block does not rescan its pixels.

## Verification

Offline fixtures exercise block-boundary interpolation, real NoData, failed-read
repair, concurrent load deduplication, pinned eviction, file replacement, circle
and corridor edges, antimeridian/polar geometry, sampling distances and cancellation.
The TIFF comparison tests check decoded pixels against the reference decoder.
Run focused checks with:

```text
cargo test --lib engine::terrain
cargo test --lib link_solve
```

Performance depends on disk cache warmth, block layout, concurrency and request
shape. Earlier whole-raster timing does not establish the speed of these request
APIs or predict application-wide gains.
