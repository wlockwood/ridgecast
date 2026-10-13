# Concepts

In-depth explanations of how RidgeCast models the world, written to be read
without opening the source. Task and reference pages tell you *which switch to
flick*; these tell you *what it is doing and why*.

## A two-minute orientation

A **node** is one proposed radio installation. A **link** is RidgeCast's
prediction of the radio path from one node to another; it can differ in the
opposite direction when the equipment differs. **Coverage** repeats that
prediction from a node to a hypothetical far-end radio across an area. The main
quality number is **fade margin** (also called SNR here), measured in dB: more
positive margin means more modeled headroom above the configured noise floor.
In RidgeCast this is the received signal minus that floor; `0 dB` means they are
equal, not that every radio application will work. These are planning estimates,
not a field test or a guarantee of service.

You do not need to read every page before using the application. Start with the
tutorial for a guided first run, or use the [glossary](../glossary.md) whenever
a term below is unfamiliar.

## Read in this order

The documents build on each other. The order below is useful for a deeper first
read; after that, jump to the question in front of you.

| Document | What it covers |
| --- | --- |
| [Choosing a propagation model](propagation-models.md) | The three pieces of code that turn a terrain profile into a path-loss number — bundled ITM/Longley–Rice, the P.1812-inspired terrain approximation, and the GPU approximation — what each actually computes, what each fixes or omits, and how to choose. |
| [Clutter, LiDAR, and canopy density](clutter-and-lidar.md) | What sits between two radios and why it matters; the difference between terrain and clutter; the DEM, NLCD, and LiDAR data sources; and how point clouds are fetched, filtered, and turned into measured obstruction surfaces. |
| [From transmit power to fade margin](link-budget-and-noise.md) | The whole chain: EIRP, path loss, received level, the receiver's own thermal floor, the NLCD-derived environmental noise prior, measured overrides, and the fade-margin bands everything else is graded on. |
| [Coverage maps](coverage.md) | What is at the far end of every coverage calculation, the two grid algorithms, TX versus RX, the four merge modes and why **Best Unit** is special, the per-node cache, and what makes a run slow. |
| [Finding sites](site-finder.md) | The inverse of coverage: how a candidate location gets a score, where in a cell the antenna is assumed to stand, recursive refinement, cluster suppression and "jealousy", and what a site score is not. |
| [Network analysis](network-analysis.md) | Properties of the whole network rather than one link: backbone reachability, articulation points, N-1 failure sweeps, routes, route independence, multi-hop throughput, service impact, and the assumptions every result carries. |
| [Application concurrency](app-concurrency.md) | For contributors: how the desktop application keeps work off the UI thread, the save queue, crash-recovery snapshots, stale-reply tokens, and the background-cache pattern. |

## Where else to look

- **[RidgeCast documentation](../README.md)** — tutorials, task guides, and
  reference material for the settings these concepts sit behind.
- **[`docs/glossary.md`](../glossary.md)** — every term used across these
  documents, the interface, and the source, defined in one place.
- **[`docs/data-and-caching.md`](../data-and-caching.md)** — where the data comes
  from, how much of it there is, how the caches are bounded, and working offline.
- **[`docs/propagation-model-decisions.md`](../propagation-model-decisions.md)**
  — the engineering decision record. Narrower and more technical than these
  documents: it says what was chosen, what was rejected, and what broke first.
- **[`CONTRIBUTING.md`](../../CONTRIBUTING.md)** — working on the code itself.

## Adding to this folder

These are explanations, not reference material and not decision records. A good
one is readable start to finish by someone who does not have the repository open,
defines its terms before using them, and prefers a worked example over a precise
abstraction. Numbers should be real ones from the application, and limitations
belong in the document rather than in the reader's eventual disappointment.

Reference material — term lists, source catalogs, settings, formats, and limits
— goes in `docs/reference/`. Operational procedures go in `docs/how-to/`, and a
guided learning experience goes in `docs/tutorials/`.
