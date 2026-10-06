# Persistent network link results

The goal is to avoid repeating whole-network terrain and LiDAR work when a
network is evaluated again, including after restarting RidgeCast. Saved network
links remain authored document data; this cache is replaceable derived data.

Use a completed-network snapshot rather than caching only successful individual
links: an empty result is meaningful, and LiDAR preparation can combine overlays
from multiple participating sites. A whole snapshot can skip planning, surface
preparation, profile sampling, and propagation together. Per-path reuse after
radio edits is a possible later extension, requiring isolated surface dependencies.

The shared `LinkSolve` worker samples noise floors first, then checks the cache.
Keys include sorted resolved participants, target scope, frequency, cutoff,
ambient-noise configuration, frozen propagation/clutter settings, algorithm
versions, and source identity. Site names and display/coverage-grid settings do
not affect reuse. Cached receiver explanations are replaced by freshly sampled
noise selections. Desktop and headless solves use the same mechanism.

Source validation uses existing terrain/land-cover metadata fingerprints,
registered immutable raster digests, and a bounded metadata inventory of LiDAR
catalogs, surfaces, and raw tiles. It performs no provider requests and runs
solely on the solve worker. Initial validation and validation after reading must
agree. Capture again after surface preparation and compare after the final batch;
changing data prevents publication. Unavailable registered sources, missing
sampled terrain/classes, failed propagation, incomplete or resource-limited
LiDAR preparation, and canceled work must not create reusable snapshots.

Persistent workers use independent decoded terrain/NLCD stores while sharing
download claims, limits, and circuit breakers with the original managers. Clear
provider thread-local samples when creating the worker. Imported rasters share
immutable payloads and digests. WorldCover source publication uses a coherent
snapshot, and native surface eligibility checks the disk generation actually
decoded. A cold acquisition pass primes data; only a pass stable from its start
can publish results.

Files under `links/` have a versioned header, embedded key, bounded lengths,
checksum, and compressed payload. Numeric link values retain their exact bits.
Missing, malformed, oversized, or stale files are misses. Write via a unique
temporary file and atomic publication with cancellation/freshness checks. Cache
failures must never fail an otherwise successful calculation.

Links have a separate LRU disk-budget category, default 256 MiB for new budget
configurations; old configurations missing the field retain no limit. Existing
settings controls expose usage, eviction, and clearing automatically. Reads and
writes update use tracking. Cache removal never changes saved networks.

Validation covers restart reuse, identical cold/warm results (including empty
results), skipped expensive phases on hits, changed settings/data, cancellation,
corruption/oversize, exact numeric round trips, category separation, and the full
workspace checks. There are no new dependencies or network calls in validation.
