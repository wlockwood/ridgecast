# Coverage cache scheduling

Approved in conversation on 2026-11-10: use tile-aware greedy scheduling with bounded preparation.

Coverage nodes should reuse decoded terrain and land-cover tiles instead of alternating between unrelated working sets. This is a heuristic for the job sequencing and tool switching problem, not a promise of a globally optimal ordering.

Enumerate full nominal terrain dependencies without decoding them. Keep acquisition/fallback validation separate and run it only for admitted work. Include possible enabled terrain fallbacks in footprint estimates without downloading them speculatively. Use resident dependencies first, then prefer the least additional decoded bytes, with shared future dependencies and original node position breaking ties. Admit at most four outstanding uncached nodes, constrained by the union of their footprints: Automatic uses the combined terrain allowance; Manual uses separate source allowances; NLCD retains its existing 32-tile capacity. One node exceeding an allowance must still make progress by running alone.

Preparation runs on background workers. As each node finishes, release its reservation and admit more work. Deduplicate in-flight dependencies, but revalidate tiles used by later windows because earlier preparation is not proof of continued residency. Ready admitted nodes and completed coverage-cache hits may overtake downloads. Preserve cancellation, source priority, missing-data behavior, stable original node identities, deterministic result ties, and frozen surface contexts. Existing LiDAR planning/context memory admission and terrain eviction grace remain in force; this is not a hard process-memory cap.

Alternatives considered: geographic sorting is cheap but only approximates tile reuse; exact/global search adds cost and relies on an imperfect cache model. The selected greedy approach is deterministic, inexpensive, and can react to the real resident set.

Keep the existing oversized-run confirmation: scheduling improves an authorized large run without silently changing its radius or removing the warning. Document the order and its limits. Verify cold and warm shared footprints, source budgets, oversized nodes, refill after completion, cancellation, disk-only tiles, unchanged numerical results, and existing cache-hit context regressions. Real-machine speedups require separate representative measurements.

Research: https://arxiv.org/html/1910.10021v1, https://arxiv.org/abs/2207.02004, https://arxiv.org/abs/1506.07905.
