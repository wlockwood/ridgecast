# Choosing a propagation model

*RidgeCast offers two selectable propagation models. Some tools also offer a
separate GPU approximation for faster exploratory work. This guide explains what
each computes, where it is used, and how to choose.*

---

## 1. What is being asked

Give a propagation model a frequency, two antenna heights, and a list of ground
elevations along the line between two points. Ask it: **how many decibels does a
signal lose getting from one end to the other?**

That question has no exact answer. Radio between two real points does not travel
one route — it goes over ridges, through vegetation, around buildings, and off
the troposphere, all at once, and the receiver adds up whatever arrives. Every
propagation model is a decision about which of those mechanisms to compute,
which to approximate, and which to ignore. Two models given identical input will
disagree, and neither is wrong in the sense that arithmetic can be wrong.

So the useful question is not "which model is correct" but **"what did this
number include, and what did it leave out"** — which is what this document is
for.

### The four words the rest of this depends on

**Diffraction** is the one that matters most. Radio does not stop at a ridge the
way light stops at a wall. When a wave passes an edge, part of it *bends around
it* and carries on into the shadow behind — weakened, but there. That bending is
diffraction, and it is why a valley behind a hill has any signal at all. Every
model below is, at its heart, a different way of computing how much signal
survives that bend.

A **knife edge** is the simplest thing you can bend a wave around: an
infinitesimally thin, perfectly sharp barrier. Real ridges are not knife edges,
but the mathematics for one is exact and closed-form, so the standard trick is to
approximate a ridge (or a rooftop, or a treeline) *as* a knife edge and accept the
error. When you see "knife-edge loss", read "the loss over one idealised sharp
obstacle".

The **Fresnel zone** is the volume around the straight line between two antennas
that actually carries the signal. It is not a line but an ellipsoid, fattest in
the middle, and its radius grows with wavelength and distance. What matters is
that an obstacle can degrade a path *without touching the line of sight at all* —
it only has to intrude into that ellipsoid. The **Fresnel parameter** (often
written ν) measures how deeply a given obstacle intrudes, in units scaled to the
zone's own size: strongly negative means well clear, zero means grazing the line
of sight, positive means blocking it. Higher parameter, more loss. It is the
number these models use to decide which terrain point is the *worst* obstacle on
a path.

**Median** means the middle outcome. A model that predicts a median loss is
saying half of real cases will be worse. That is not a defect, but it is
something to design margin around.

## 2. What every model gets

All three share the same front end, which matters: differences between them are
differences in the *physics*, not in the data.

**A terrain profile.** A list of bare-earth ground elevations sampled at regular
steps along the great-circle path, from RidgeCast's selected DEM source. **Bare
earth** — vegetation and buildings removed.

**Clutter, kept separate.** Trees and buildings are not added onto the terrain
profile as if they were ground. What happens to them differs by model (§4) and is
explained at length in **[Clutter, LiDAR, and canopy
density](clutter-and-lidar.md)**.

**Antenna heights above ground** at each end.

**One network-wide frequency.** RidgeCast models a single frequency per network,
not a per-radio channel plan.

Whatever comes out is then fed into the link budget — see **[From transmit power
to fade margin](link-budget-and-noise.md)** — which is where it becomes an SNR.

## 3. The models you choose between

**Settings → Application Preferences → Propagation** offers ITM / Longley–Rice,
Terrain diffraction (P.1812-inspired), and the separately configured complete
**P.1812-7 outdoor** method. The complete method stays disabled until its explicit
inputs are validated; see the [propagation settings reference](../reference/propagation-settings.md#propagation-models).
The choice
applies everywhere at once: network links, coverage maps, **Site Finder** (the
tool that scores candidate locations for a new site), link previews, evaluation
of links between FCC amateur license holders, and diagnostics. It is deliberately
not a per-link setting, because a network whose links were computed under
different models cannot be compared with itself.

### ITM / Longley–Rice — the default

The **Irregular Terrain Model**, sometimes called Longley–Rice, is the
long-established terrain-aware model used across broadcast and land-mobile
planning since the 1960s. RidgeCast bundles the NTIA reference C++ implementation
and calls it through a Rust bridge — the model itself is not a reimplementation.

It computes free-space loss, terrain diffraction, and **tropospheric scatter** —
signal scattered forward off irregularities in the lower atmosphere, which is
what carries a path far beyond the horizon when nothing else can. It also has a
statistical layer: rather than one number, it can answer questions of the form
"what loss is exceeded no more than 10% of the time, at 50% of comparable
locations".

RidgeCast starts with the legacy preset below. **Settings → Application Preferences → Propagation → Advanced ITM environment and statistics** lets you supply explicit inputs:

| Parameter | Value | What it is, and where the scale runs |
| --- | --- | --- |
| Ground dielectric constant | 15 | How readily the ground stores electrical energy, which sets how much of a ground-reflected wave survives. Roughly 4 for very dry desert or poor rock, 15 for average moist soil, 25 for rich wet farmland, 81 for sea water. |
| Ground conductivity | 0.005 S/m | How readily the ground conducts, in siemens per meter. Roughly 0.001 for desert, 0.005 for average ground, 0.02 for marsh, 5.0 for sea water — a thousandfold range. |
| Surface refractivity | 301 N-units | How much the atmosphere bends radio downward at the surface, in "N-units". 301 is the sea-level standard; drier, higher, or hotter air runs lower (270–290), humid coastal air higher (340+). Higher bends more and therefore reaches further. |
| Radio climate | Continental temperate | One of ITM's seven climates. The others include equatorial, maritime temperate, and desert. |
| Polarization | Vertical | The orientation of the wave's electric field. Vertical is the norm for land-mobile and most mesh work; broadcast and some point-to-point links use horizontal. |
| Confidence / reliability | 50% / 50% | The median outcome — see below. |

These are reasonable defaults for most of the temperate world and wrong for some
of it. **A path over sea water is the clearest case**: its conductivity is a
thousand times the assumed value and its dielectric constant five times it, so
over-water paths behave quite differently from what RidgeCast will predict.
Desert, equatorial, and maritime climates are wrong in the other directions.
Enter explicit known conditions in the advanced panel; RidgeCast does not infer soil properties or weather.

**Statistical confidence** describes situation variability; **statistical
reliability** describes time variability within a situation. RidgeCast preserves
the bundled `point_to_point` contract: `mdvar=12`, location variability
eliminated, `avar(qerfi(reliability), 0, qerfi(confidence))`. Enter each percentage
in **1–99%**. These are loss non-exceedance targets; larger values generally
increase loss. **50/50 exactly preserves the historical median preset**. These
percentages differ from input-validity warnings and network-analysis success
probabilities. No selected percentage guarantees field uptime.

Relative permittivity must be finite and greater than 1, conductivity finite
and positive in S/m, and sea-level surface refractivity in 250–400 N-units.
Climate and polarization are explicit enums. See the [NTIA input
documentation](https://github.com/NTIA/itm#inputs). RidgeCast retains its bundled
2007 entry point rather than substituting a time/location/situation call.

ITM's valid range is 20 MHz to 20 GHz. Its C++ core returns error codes when
inputs stretch its assumptions; RidgeCast maps those onto a confidence marker
(1.0 for clean, down to 0.1 for badly out of range), separately from statistical
percentiles. Invalid bridge inputs produce unknown loss. RF jobs retain an
immutable settings snapshot; completed links retain requested assumptions.
Every environmental/statistical input participates in coverage identity.
Nonlegacy ITM inputs use CPU and bypass optimistic pruning whose bounds have
not been established for those inputs.

### Terrain diffraction — P.1812-inspired comparison

**P.1812** is an ITU recommendation for point-to-area terrestrial propagation
in the 30 MHz to 6 GHz range. RidgeCast does not implement that complete
recommendation. Its native Rust comparison model uses a small subset of the
same terrain geometry.

What the native kernel computes today is the **median terrain path**:

- free-space basic transmission loss (ITU-R P.525),
- terrain clearance against an **effective Earth radius** of 8,500 km — the
  standard trick for folding atmospheric refraction into flat geometry, so that
  a ray can be treated as straight over a slightly larger Earth,
- **dominant-edge knife-edge diffraction** over the most obstructing profile
  point.

It does **not** implement complete delta-Bullington diffraction, smooth-Earth
diffraction, time or location variability, anomalous propagation (ducting and
layer reflection), troposcatter, or P.1812's final combination of propagation
mechanisms. The persisted time-percentage setting is normalized to 50% and kept
only so old configuration files stay valid.

The missing competing mechanisms matter: a deep knife-edge shadow can be much
more pessimistic than complete P.1812, where troposcatter or anomalous propagation
may provide a lower-loss route. Do not interpret agreement with this approximation
as validation against the recommendation.

Inputs outside 30 MHz–6 GHz are clamped and the result's confidence marker is
lowered rather than the calculation being refused.

## 4. Endpoint clutter and profile contracts

The two models handle *the trees and buildings around each antenna* — as opposed
to along the path — in materially different ways, and this is where their answers
diverge most for a node that is not on a mast.

**ITM** uses RidgeCast's legacy treatment: a configurable **linear
dB-per-meter** penalty applied to a terminal sitting below the local clutter
height. Every meter of vegetation costs the same as the last. On a node under a
tall canopy this accumulates fast.

The **terrain-diffraction approximation** receives a bare-earth profile and the
physical antenna height above local ground. It does not move either endpoint by
the local clutter height and does not add a separate endpoint-clutter loss. An
older implementation did both, double-charging clutter and sometimes placing a
low antenna mathematically below the ground; that behavior was removed.

The approximation also does not put interior clutter into its diffraction
profile. It should therefore be treated as a terrain-only second opinion. A
complete P.1812 surface profile would retain bare-earth terminal points and add
representative clutter to appropriate interior points as part of a substantially
larger procedure.

There is a bookkeeping consequence too. ITM works in a *clutter-effective*
antenna height — the antenna's height relative to the top of the local clutter
rather than to the ground — and clamps that value to a minimum of 1 meter, which
destroys the original figure. The terrain approximation carries physical AGL
alongside, so it never has to reconstruct a real height from a clamped one. This
matters only in that the two models are not sharing a single mangled number; it
is not something you configure.

## 5. The third model, which you do not choose

There is a **GPU approximation**, and it is not in the model menu. It is selected
by turning on GPU execution for coverage or Site Finder, and it applies **only in
ITM mode** — terrain diffraction stays on the parallel CPU profile path, so one result never
silently mixes two models.

It is not ITM on a GPU. It is a separate, simpler model written to run thousands
of profiles per dispatch:

- **Free-space loss** (ITU-R P.525) as the base — what the path would cost with
  nothing in it at all.
- **Deygout diffraction with up to three knife edges.** Deygout's method is the
  standard way to handle a path with several obstacles without solving the whole
  thing at once: find the single worst obstacle, charge for it, then recurse into
  the two shorter paths on either side of it. Here that means the interior
  terrain point with the highest Fresnel parameter becomes the *principal* edge;
  if it obstructs, one secondary edge is sought on each side, measured against a
  line ending at the principal edge's top. Three edges total. Each edge's loss
  uses the ITU-R P.526 knife-edge approximation, applied down to grazing
  incidence — an edge just *below* the sightline still costs signal, because it
  intrudes on the Fresnel zone.
- **A two-ray ground-reflection floor.** On an open path, the receiver hears the
  direct wave *and* a wave bounced off the ground, and past a certain distance
  those two increasingly cancel. Beyond that point the median loss over ground
  follows plane-earth loss (40·log d — losing 12 dB per doubling of distance)
  rather than free-space (20·log d — 6 dB per doubling). Effective antenna
  heights are measured against the mean terrain along the path, so a terminal on
  high ground is not penalised as though it stood on a plain, but never below its
  structural height above ground.
- The two mechanisms are combined with **max()**, not by adding them. Obstructed
  paths take the diffraction loss; open low-antenna paths take the two-ray
  excess. Taking the larger keeps the transition continuous and avoids charging
  twice for what is really one effect.
- Earth curvature uses the same effective-radius trick as P.1812 — here the
  classic 4/3 × Earth radius, ≈ 8,493 km, against P.1812's 8,500 km. The two are
  the same convention and differ by less than 0.1%. ITM handles curvature
  internally with its own effective-Earth term derived from the surface
  refractivity in §3, which is why that parameter is in the table.

What it does not have: ITM's statistical layer, its ground constants, its climate
model, troposcatter, and its careful handling of the transition regions between
line-of-sight, diffraction, and scatter.

**Use it for a first sweep and confirm shortlisted results on the CPU.** It is
accurate enough to tell a ridge from a valley across a whole map in seconds, and
it is not the number to put in a report.

## 6. Choosing

| | **ITM / Longley–Rice** | **Terrain diffraction (P.1812-inspired)** |
| --- | --- | --- |
| Implementation | Bundled NTIA C++ reference | Native Rust approximation |
| Frequency range | 20 MHz – 20 GHz | 30 MHz – 6 GHz |
| Statistical output | Configurable confidence/reliability; legacy 50/50 default | Median only |
| Troposcatter | Yes | No |
| Earth curvature | Derived internally from surface refractivity | Fixed effective radius, 8,500 km |
| Time variability | Available but not used | Not implemented |
| Terminal clutter | Linear dB per meter, unbounded | Not modeled |
| Measured LiDAR surfaces | Yes (§7) | No |
| GPU acceleration | Yes (approximate, §5) | No — CPU profile path only |

Practical guidance:

- **Start with ITM.** It is the default, it is the long-established reference, it
  is the mode measured LiDAR surfaces work in, and it is the mode GPU
  acceleration works in.
- Use **terrain diffraction** when you want a terrain-only second opinion from
  an independent implementation. Do not use it to validate clutter losses.
- **Run both and compare on links you care about.** This is what the separate
  cache entries (§8) are for.
- **Neither is a field survey.** Validate anything regulatory or
  safety-critical independently.

## 7. Measured surfaces are an ITM feature

ITM mode can optionally replace assumed land-cover clutter heights with heights
measured from public LiDAR, in two independently switchable scopes — around each
node, and along eligible links. Terrain-diffraction mode does not use them.

That is a large subject with its own document: **[Clutter, LiDAR, and canopy
density](clutter-and-lidar.md)**. Stored LiDAR return-density ratios are
diagnostic metadata and do not currently modify RF attenuation.

## 8. Switching models does not corrupt your results

Changing the model invalidates propagation results, and each model writes to
**distinct persistent coverage-cache entries**. ITM and terrain-diffraction coverage for the
same node can therefore both be on disk at once, and switching back and forth
does not force a recalculation of the mode you left. Comparing the two is a
matter of flipping the setting, not of rebuilding one from scratch each time.

Every calculated result also records **which method produced it**.

## 9. What none of them know

- **ITM assumptions are user supplied**, not inferred field conditions or
  availability guarantees. The terrain-diffraction approximation remains
  median-only and does not model climate.
- **Nothing models interference.** Co-channel and adjacent-channel signals are
  outside both models. Ambient *noise* is modeled separately — see **[From
  transmit power to fade margin](link-budget-and-noise.md)**.
- **Antenna patterns are two points** — the gain along the direction the antenna
  is aimed (its *boresight*) and how many dB weaker it is directly behind (its
  *front-to-back ratio*) — not a measured pattern with real sidelobes and nulls.
- **The terrain data has its own errors.** A 10 m DEM does not know about the
  cutting, the embankment, or the building that went up last year. Model accuracy
  is bounded above by data accuracy.
- **Local obstructions near an antenna dominate and are invisible.** The tree
  five meters from the mast is not in a 10 m DEM, is barely in a 30 m land-cover
  raster, and may well decide the link.

---

## Where else to look

- **[From transmit power to fade margin](link-budget-and-noise.md)** — what
  happens to the path-loss number these models produce.
- **[Clutter, LiDAR, and canopy density](clutter-and-lidar.md)** — what the
  models are told is standing on the ground, and how measured surfaces change it.
- **[Coverage maps](coverage.md)** — running the chosen model over an area.
- **[`docs/propagation-model-decisions.md`](../propagation-model-decisions.md)** —
  the decision record: what was chosen, what was rejected, and what broke first.
