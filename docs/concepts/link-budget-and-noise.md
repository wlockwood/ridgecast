# From transmit power to fade margin

*An explanation of the chain RidgeCast walks to decide whether a link works —
what leaves the transmitter, what arrives at the receiver, what the receiver has
to hear it over, and what "fade margin" is a margin against. Written for someone
who has never seen the code and does not need to.*

---

## 1. The chain

Every link, every coverage cell, and every site score in RidgeCast comes down to
one comparison:

> Is the signal arriving here **louder than the noise already here**, and by how
> much?

That "by how much" is the **fade margin**, measured in decibels, and it is the
single number RidgeCast colors links by, grades coverage on, and thresholds
every network analysis against. Everything else is machinery for computing its
two halves.

The chain has four steps:

```
  EIRP            what actually leaves the antenna          (§2)
   − path loss    what the world between them costs         (§3)
  = RSL           what arrives at the receiver              (§4)
   − noise floor  what it has to be heard over              (§5–§8)
  = fade margin   how much room is left                     (§10)
```

**Fade margin and SNR are the same number in RidgeCast**, and both names appear
in the interface. "SNR" (signal-to-noise ratio) is what it *is*; "fade margin" is
what it is *for* — the headroom available to absorb rain, foliage, and everything
the model does not know about. Wherever this document says one, the other would
have been equally correct.

### A note on decibels

Everything here is in decibels, and three notations appear:

- **dB** is a *ratio* — a gain or a loss. "20 dB of loss" means the power came out
  a hundredth of what went in.
- **dBm** is an *absolute power*, referenced to one milliwatt. 0 dBm is 1 mW,
  30 dBm is 1 W, −100 dBm is a ten-billionth of a milliwatt.
- **dBi** is an *antenna gain*, referenced to a theoretical antenna radiating
  equally in every direction. A 2 dBi antenna concentrates its best direction to
  about 1.6× that ideal; a 10 dBi antenna, about 10×. An antenna does not amplify
  — it only redirects — so gain in one direction is paid for by loss in another.

You may add a dB or a dBi to a dBm (22 dBm plus 2 dBi of gain is 24 dBm) but you
may not meaningfully add two dBm figures as if they were numbers — that is §8's
problem.

The scale is logarithmic: 10 dB is a factor of ten in power, 20 dB a hundredfold,
60 dB a millionfold. Losses along a path *add* in dB while the corresponding
powers *multiply*, which is the entire reason the industry works in dB at all.

## 2. What leaves the antenna

**EIRP** — Effective Isotropic Radiated Power — is what the antenna radiates in
its best direction, as if it were a perfect point source:

```
EIRP = transmit power + antenna gain − system loss
```

All three come from the node's **system profile** — a named set of shared radio
parameters (power, sensitivity, antenna, heights) that any number of nodes can
inherit from, so a fleet of identical radios is described once. Any node can
override individual fields.

RidgeCast's stock defaults are 22 dBm (about 160 mW), 2 dBi of antenna gain, and
0 dB of system loss — so 24 dBm of EIRP.

"System loss" is the catch-all for everything between the radio and the
antenna: feedline, connectors, duplexers, a lightning arrestor. RidgeCast does
not model any of those individually; you enter the total.

### Direction

By default antennas are omnidirectional, and EIRP is the same on every bearing.

A system or an individual node can instead declare a **directional** antenna with
an azimuth and a **front-to-back ratio**.

Two terms there. The **boresight** is the direction the antenna is aimed — the
one direction its rated gain applies to. The **front-to-back ratio** is how many
decibels *weaker* the antenna is directly behind the boresight than along it: a
20 dB front-to-back ratio on a 10 dBi antenna means the back of the antenna
behaves like −10 dBi.

RidgeCast applies the rated gain along the boresight and tapers it to the
front-to-back figure directly behind. This is a two-point pattern, not a measured
one: RidgeCast knows the gain forward and the gain backward and interpolates
between them. A real antenna pattern has sidelobes and nulls that this will not
reproduce.

An azimuth can be **locked onto another node**, in which case it is recomputed
whenever either node moves. Both ends of a link are evaluated along the
end-to-end bearing.

An antenna also carries a **tilt**: where its main lobe points in elevation,
positive above the horizon and negative below. Tilt is aiming information only —
it is shown against each path but is not charged against any computed loss.

### Beamwidth

RidgeCast never asks for a beamwidth, but the link profile plot draws one for
each end, because the numbers you do enter imply it.

Each antenna's beam is drawn **twice**, because one chart cannot show both things
at once:

- Its two −3 dB **edges** run the length of the path with a dashed boresight
  between them, against the terrain, so a far end sitting above or below the beam
  is visible rather than arithmetic. This answers *where the beam goes*.
- A small shaded **fan** at the antenna, drawn at a fixed size on screen, answers
  *how wide the beam is*.

The fan exists because a profile chart stretches height against distance, often
by ten to one, so nothing drawn in its coordinates can be read as an angle — the
line of sight on a typical path descends under two degrees and looks like twenty,
and a 9° beam is drawn looking like 70°. The key under the plot names the
stretch factor for the current view. The fan is immune to it, and to zooming.

Tick **True Scale** to remove the stretch instead: one meter of height is then
drawn the same size as one meter of distance, the fan and the edges agree, and
every angle on the chart is the angle it claims to be. The cost is that terrain
flattens — twenty kilometers of path against a few hundred meters of relief
leaves the ground nearly level — so it is a check to reach for rather than a view
to live in. Zooming into a stretch of the path brings the detail back without
giving up the true angles.

Hovering any part of a drawn beam names it: the fan, either −3 dB edge, and the
boresight each report what they are and the angle they leave the antenna at.

The beams are painted over the chart rather than plotted on it, so they never
influence how the view is framed and they always run to the edge of whatever is
on screen. **Reset View** returns the plot to the view it opened with, framing
the whole path, which is also what double-clicking it does.

An antenna aimed away from the path in azimuth is drawn faintly: its elevation
cut is still true, but it is a cut through a direction that antenna is not
covering.

The **azimuth beamwidth** is exactly where the front-to-back taper above passes
3 dB below the boresight, so it is the true half-power width of the pattern the
link budget uses — not a separate estimate. It works out to
`2 · arccos(1 − 6 / front_to_back)`: a 20 dB front-to-back ratio is 91° wide, 30 dB
is 74°, and 40 dB is 64°. A ratio below 3 dB never drops half its power anywhere,
so it reports the full circle, as does every omni.

The **elevation beamwidth** has nothing behind it in the stored parameters, so it
is inferred from the power budget instead. Gain and the two half-power widths are
tied together by `gain ≈ 32400 / (azimuth_width · elevation_width)` in degrees, so
an antenna concentrating its rated gain into the azimuth width above has to be
about that many degrees tall. This is why an omni still reports one: a 6 dBi omni
radiates the same power as an isotropic antenna but squashed into roughly 23° of
elevation. Where the rated gain is too low to imply anything narrower than the
sky, the beamwidth is reported as an em dash instead.

Treat the drawn beam as a sanity check on aim, not a measured pattern. It assumes
a single well-behaved main lobe and says nothing about sidelobes, nulls, or the
difference between a corner reflector and a long Yagi of the same gain. A beam
wider than 120° in elevation gets a fan but no edges: they would leave the chart
within a few hundred meters of the antenna.

Bear in mind how far a beam reaches. Half-power width is an angle, so its
footprint grows with distance: a 9° beam is ±1.5 km tall twenty kilometers out,
which is more vertical room than most paths have terrain. On a link like that the
edges will run off the top and bottom of the chart almost at once, and that is
itself the answer — the beam is nowhere near being the constraint. Beams narrow
enough to matter, from a dish or a long Yagi, stay on the chart and can be read
against the ground.

The edges follow whichever view the profile is drawn in — see
**[Curved or flat](#curved-or-flat)** below — so a beam edge aimed at the far
antenna arrives at it either way.

### Curved or flat

Radio does not travel in straight lines over a sphere and the ground does not sit
on a plane, so a flat chart has to bend one of the two. The link profile offers
both, through the **Flatten Earth** checkbox.

Unticked, the default, bends the ground: it is drawn bowed up onto the chord
between the two antennas, which leaves every radio path straight. This is how
path-profile charts are conventionally drawn, because clearance then reads by
eye — the line of sight, the Fresnel envelope, and each antenna's beam are all
straight lines, so anything poking through one of them is an obstruction.

Ticked, it bends the radio instead: the ground is drawn at its true elevation,
and the line of sight, Fresnel envelope, and beams all bow downward across the
path. Terrain heights then match a map or a GPS, at the cost of no longer being
able to judge clearance with a ruler.

Both views describe the same path and predict exactly the same loss; the setting
changes nothing that is calculated. The bow is the 4/3 effective Earth radius
standing in for atmospheric refraction, and it grows with the square of distance
— about 0.4 m over a 5 km path, 9 m over 25 km, 37 m over 50 km, and 147 m over
100 km. The setting reaches every part of the window, including the hover
readout and the CSV the **Copy to Clipboard** button produces, which carries the
drawn ground height alongside the true one.

## 3. What the path costs

Path loss is the large number in the chain — typically 100 to 160 dB — and it is
the part that needs terrain, land cover, and a propagation model. That is a
subject of its own; see **[Choosing a propagation model](propagation-models.md)**
for how ITM and P.1812 differ and what each assumes, and **[Clutter, LiDAR, and
canopy density](clutter-and-lidar.md)** for how the trees and buildings along the
path are accounted for.

For this document, one property is worth stating, because a great deal of
RidgeCast's efficiency rests on it: **free-space loss is a floor**. Terrain,
diffraction, and clutter can only ever add to it. The free-space figure follows
ITU-R P.525:

```
FSPL(dB) = 20·log10(distance_km) + 20·log10(frequency_MHz) + 32.44
```

Because it is a floor, a pair of nodes whose *best possible* signal — free space,
both antennas pointed straight at each other — still falls below the usable
threshold cannot be rescued by any amount of modeling. RidgeCast tests that
first and drops such pairs before they can trigger a terrain, land-cover, or
LiDAR download. A 1 dB slack is allowed, because ITM's median-deviation term can
land a fraction of a dB under free space.

## 4. What arrives

```
RSL = EIRP − path loss + receive antenna gain − receive system loss
```

**RSL** (received signal level) is in dBm, and for a working link it is a large
negative number — somewhere between −60 dBm for a short strong path and −120 dBm
for a marginal one.

## 5. What it must be heard over

Here is where RidgeCast differs from the simplest tools, and where most of the
rest of this document goes.

The naive approach is to compare RSL against a fixed **receiver sensitivity** —
one number per radio, typically around −100 dBm, taken from a datasheet. That is
what RidgeCast's stock system profile still shows, and it is what older networks
saved before this machinery existed.

The trouble is that receiver sensitivity is a property of the *radio*, and the
thing the signal actually competes with is a property of the *place*. A receiver
that hears −110 dBm on a bench hears nothing of the sort inside a city, where
switching supplies, LED drivers, vehicle ignition, and every other piece of
electrical infrastructure raise the ambient floor by tens of decibels at VHF. The
radio has not changed. The site has.

So RidgeCast builds an **effective noise floor** for each receiving node, from
two contributions:

1. The noise the **receiver itself** makes (§6) — thermal, unavoidable, a
   property of the radio.
2. The noise the **environment** delivers to the antenna (§7) — man-made,
   location-dependent, and the reason a hilltop above a town is not the same site
   as a hilltop above a forest.

Those two are combined in §8, and the result *replaces* the datasheet sensitivity
in the SNR calculation for network links.

### Where the radio's decode requirement goes

RidgeCast has no separate modulation-specific required-SNR input. Its reported
noise-floor margin is signal above the effective noise floor; it does not
subtract the SNR your modem needs to decode. With an explicit noise figure, a
datasheet sensitivity is therefore not automatically the pass/fail threshold.

For a hypothetical radio with −110 dBm sensitivity, 125 kHz noise bandwidth,
and 6 dB noise figure, the receiver baseline is about −117 dBm. Under those
datasheet conditions, decoding needs about 7 dB signal above noise. If you also
want 10 dB reserve, look for about 17 dB reported margin against the effective
noise floor. This inference assumes the sensitivity and noise figure describe
the same receiver mode, bandwidth, and test conditions; verify it for your radio.

Choose thresholds to express that requirement; RidgeCast does not infer it:

- **Fade Margin Settings → Good/Fair/Marginal** grade the result. Marginal also
  affects the network's calculated-link cutoff; Best Unit Threshold separately
  controls admission for serving-margin coverage modes.
- **Visible Link Threshold** filters drawn links and ordinary coverage; it is
  not a modem model.
- **Analysis Results → Minimum link margin** sets the analysis cutoff. It
  cannot recover links excluded by an earlier calculation cutoff.

For this example, 17 dB is a planning target, not a guarantee. A headless
`closes` flag at 0 dB likewise does not establish packet decoding at 7 dB.

## 6. The receiver's own floor

Every resistor, and every receiver front end, generates noise simply by being
warmer than absolute zero. That floor is set by physics and two receiver
parameters:

```
receiver reference (dBm) = −173.98 + 10·log10(noise-equivalent bandwidth in Hz)
                            + receiver noise figure (dB)
```

The constant −173.98 is **kTB expressed for one hertz of bandwidth**: Boltzmann's
constant *k*, times a reference temperature *T* of 290 K (about 17 °C, the
industry's standard stand-in for "ordinary outdoor temperature"), times a
bandwidth *B* of 1 Hz, converted to dBm. The `10·log10(bandwidth)` term is what
scales that one-hertz figure up to the bandwidth the receiver actually uses —
which is why the tables below label the combined figure "kTB".

The two inputs live on the system profile and can be overridden per node:

- **Noise-equivalent bandwidth (NEB)** — how much spectrum the receiver actually
  integrates noise over. Wider bandwidth admits proportionally more noise:
  doubling it costs 3 dB. RidgeCast's default is 125 kHz.
- **Receiver noise figure (NF)** — how much noise the receiver's own front end
  adds above the theoretical minimum. A good VHF/UHF receiver is 3–8 dB.

### The compatibility trick worth understanding

Networks saved before these fields existed have only a receive sensitivity. If
RidgeCast simply assumed a modern noise figure for them, every one of those
networks would silently change its answers on upgrade.

Instead, when no explicit noise figure is given, RidgeCast **derives the noise
figure that reproduces the stored sensitivity exactly**:

```
legacy-equivalent NF = stored sensitivity − (−173.98 + 10·log10(NEB))
```

Worked through with the stock defaults — −100 dBm sensitivity, 125 kHz NEB:

| Quantity | Value |
| --- | --- |
| kTB at 290 K over 125 kHz | −173.98 + 50.97 = **−123.01 dBm** |
| Derived legacy-equivalent NF | −100 − (−123.01) = **23.01 dB** |
| Receiver reference | −123.01 + 23.01 = **−100.00 dBm** |

The old number comes back out unchanged. The derived figure is retained until you
enter a real one — at which point the numbers move, because they should.

Note what a 23 dB noise figure means: it is not a description of any real
receiver. It is the noise figure a receiver would need for −100 dBm to be its
thermal floor, and it exists to keep old files honest. Entering your radio's
actual noise figure is the single highest-value change you can make to a
RidgeCast network's realism.

## 7. The environment's contribution

Where a receiver sits changes what it has to listen through. RidgeCast estimates
that from land cover and population, and the estimate is explicitly a
**low-confidence prior** — it is labelled as such in the interface and in every
explanation it produces — which a site measurement can always replace (§9).

The estimate is built in two stages, and it is worth keeping them apart:

1. **One number describes the place.** Land cover and population are combined
   into a single **source density index** between 0 and 1, where 1 is solid
   high-intensity urban development and near-0 is forest, water or ice. This is
   the only thing RidgeCast knows about the site.
2. **Three separate mechanisms consume that number.** They are genuinely
   different physics, they have very different sizes, and which of them matters
   depends entirely on your frequency:

   | Mechanism | What it is | Where it matters |
   | --- | --- | --- |
   | **Unintentional noise** | Ignition, power lines, switching supplies — things that radiate by accident | Strong at HF/VHF, nearly gone by 900 MHz |
   | **In-band traffic** | Other people's radios transmitting in a shared band | Only on unlicensed bands, where it is usually the largest of the three |
   | **Adjacent-band desense** | A strong licensed signal next door overwhelming a receiver with poor filtering | Only where such a neighbour exists, and only for cheap front ends |

The rest of this section builds the density index, then takes each mechanism in
turn.

### Land cover as a proxy for source density

Man-made noise comes from electrical activity, and electrical activity roughly
tracks development. RidgeCast has no census of switching supplies, but it does
have **NLCD** — the National Land Cover Database, a 30 m raster published by the
USGS and MRLC that labels every 30 m square of the United States with one of
about twenty land-cover classes (open water, deciduous forest, developed high
intensity, and so on). Each class carries a **normalized source-density weight**
between 0 and 1:

| NLCD class | Weight |
| --- | --- |
| Developed, high intensity (24) | 1.000 |
| Developed, medium intensity (23) | 0.650 |
| Developed, low intensity (22) | 0.400 |
| Developed, open space (21) | 0.180 |
| Cultivated crops (82) | 0.100 |
| Pasture/hay (81) | 0.050 |
| Grassland (71) | 0.015 |
| Deciduous forest (41) | 0.012 |
| Open water (11) | 0.003 |
| Perennial ice/snow (12) | 0.001 |

(The full table covers every NLCD class; these are the endpoints and the ones
that move an answer.)

### Two rings, blended

Noise is local but not *only* local. A quiet clearing in the middle of an
industrial park is not a quiet site. So RidgeCast area-weights NLCD pixels over
two regions around the receiving node:

- a **local circle**, 0–200 m, weighted **80%**
- a **context ring**, 200–1,000 m, weighted **20%**

Each region yields a **density index** — its area-weighted mean class weight —
and the two are blended 80/20 (local/context) into one number. The difference
between the two indices is reported as a **locality sensitivity** figure, which
tells you whether the answer would move much if the node were relocated a few
hundred meters.

**A note on the word "density," which this document unfortunately needs twice.**
The 0-to-1 number being built here is the *source density index*, also called the
density index or the site density depending on how much of the phrase fits. It is
always the same single number, and it is what all three mechanisms below consume.
**Population density** is a different quantity entirely — real people per square
kilometre — and it is one of the two *inputs* to the index, never the index
itself.

### Population density modulation (WorldPop)

**WorldPop** is an open dataset of gridded population estimates — a raster of how
many people live in each cell, published per country at roughly 100 m resolution
by the WorldPop project. Where NLCD describes what the ground is *used for*,
WorldPop counts who is actually *on* it, and unlike NLCD it covers most of the
world. RidgeCast uses the **2020 UN-adjusted constrained** variant: counts are
restricted to mapped settlements and country totals match UN estimates. Areas
missing from the settlement mapping can lack population values, so this remains
a proxy for electronics rather than a measurement of current activity.

When it is available for the area, RidgeCast blends it into the density index.
People are a direct proxy for active electronics — appliances, vehicles, phones,
and on a shared band, radios:

- The local population density (people per km²) is sampled within the **local circle** — the same 200 m radius the land-cover local region uses, not the 1 km context ring.
- Only raster pixels that carry a value count, and the people found are divided by the area *those pixels* cover. A circle that runs off the edge of the raster or over water is normalized against the part of it that was actually measured, so a coastal site is not reported as quiet simply because half its circle is ocean.
- Constrained rasters can also contain NoData outside mapped settlements. These
  pixels are excluded from the density denominator, so this is density over
  pixels with modeled counts, not an average over all ground in the circle.
  An entirely NoData circle is unavailable, rather than a measured zero, and
  uses the noise model's fallback. Overlapping country rasters are checked until
  one supplies usable counts.
- The density is normalized against an urban baseline reference (default 3,000 people/km²).
- When available, it is blended with the land-cover figure 80/20. This is a
  **second and completely separate blend** from the local/context one above, which
  has already finished by this point; the two merely happen to share the ratio.
  Land cover enters here as one settled number:
  `effective_density = 0.80 · nlcd_density + 0.20 · clamp(population_density / 3000, 0, 1)`,
  where `nlcd_density` is the local/context blend from above, and
  `clamp(x, 0, 1)` means "hold x between 0 and 1" so a city denser than the
  reference cannot push the index past 1.
- Where land-cover coverage falls below the minimum — outside the United States, NLCD simply does not exist — population becomes the **whole** density index rather than being discarded. Outside the US it is usually the only signal there is.
- If neither source has usable data for the region, RidgeCast falls back to the receiver's own noise floor and says so in the breakdown's warnings.

The breakdown in the node inspector and link profile window explicitly reports the
observed population density and its contribution.

### Mechanism 1: unintentional man-made noise

A warning about vocabulary before the physics: throughout this document and in
the interface, **"man-made noise" means this mechanism specifically** — the
accidental radiation covered by the ITU model below. Mechanism 2 is obviously
also made by people, but it is never called man-made noise here, because the
published model that phrase refers to does not include it.

The density index is turned into an actual noise power using the ITU-R **P.372**
city/business reference, or its **Hagn/NTIA** extension above 200 MHz. (P.372 is
the ITU recommendation on radio noise; NTIA is the U.S. National
Telecommunications and Information Administration, and Hagn is the author of the
extension above P.372's published range.)

Both are expressed as **`Fam`** — the conventional symbol for the *external
noise figure from man-made sources*, in decibels above the thermal floor for the
same bandwidth. An `Fam` of 16 dB means the environment delivers 16 dB more noise
than the receiver would generate on its own at absolute best.

| Frequency range | Reference `Fam` (dB above kTB) | Branch |
| --- | --- | --- |
| 0.3 – 200 MHz | `76.8 − 27.7·log10(f_MHz)` | P.372 |
| 200 – 1000 MHz | `49.2 − 15.8·log10(f_MHz)` | Hagn/NTIA |

Then:

```
Fam(site)      = Fam(city reference) + 10·log10(site density index)
man-made (dBm) = kTB + Fam(site)
```

`kTB` here and in every formula below is the receiver's own thermal floor over
**its** noise-equivalent bandwidth, exactly as computed in §6 — not over some
fixed reference bandwidth. Change the bandwidth and every term below moves
together.

The `10·log10(density)` term is what scales the city reference down to the site.
A density of 1.0 (solid high-intensity development) *is* the city reference. A
density of 0.1 is 10 dB quieter; 0.01 is 20 dB quieter.
At an index of zero, the logarithm is undefined. RidgeCast omits the modeled
man-made and in-band terms and uses the receiver baseline instead of taking the
logarithm of zero. Open water has a small nonzero land-cover weight, so it is not
the zero case by itself.

The branches very nearly meet at the 200 MHz handover: P.372 gives 13.06 dB and
Hagn/NTIA gives 12.84 dB, so crossing the boundary jumps the answer by about
0.2 dB. That is small enough to ignore in practice, but it is a jump, not a
perfectly smooth join.

**Notice how steeply this falls.** Using whichever branch applies: 16.9 dB at
146 MHz (P.372), 7.3 dB at 446 MHz and 2.4 dB at 915 MHz (Hagn/NTIA) — a drop
of about 16 dB per tenfold increase in frequency across the upper branch. That
collapse is real, and it is a property of the
*sources* — spark gaps and switching supplies radiate poorly at UHF. It says
nothing about how many radios are nearby, which is what the next mechanism is
about.

### Mechanism 2: in-band traffic on shared bands

On an unlicensed band, the thing most likely to be sitting on your noise floor is
not a power line. It is other people's radios.

(**ISM** — Industrial, Scientific and Medical — and **SRD** — Short Range Devices —
are regulatory labels for bands anyone may transmit in without a licence, subject
to power and duty-cycle limits. They are shared by everyone, which is exactly the
problem here.)

A dense suburb contains thousands of 900 MHz devices per square mile — smart
meters, tyre-pressure sensors, garage remotes, wireless doorbells, weather
stations, other mesh nodes. An empty forest contains approximately none. That
gap tracks development almost exactly, which means **the density index already
measures it**. What it must *not* inherit is P.372's frequency collapse: the
number of transmitters around you does not thin out because you tuned to
900 MHz. If anything the opposite, since that is where the cheap unlicensed
hardware lives.

So RidgeCast models in-band traffic as a **second, independent term** — same
density index, its own magnitude, no frequency slope at all:

```
occupancy (dBm) = kTB + occupancy reference + 10·log10(site density index)
```

Same `kTB` as above, and the same density index — only the reference level and the
absence of a frequency term differ.

The reference is per band, and is the level at a density index of 1.0:

| Band | Occupancy reference | Adjacent high-power service? |
| --- | --- | --- |
| 433.05–434.79 MHz ISM | +10 dB above kTB | No |
| 863–870 MHz SRD (Europe) | +8 dB above kTB | Yes — GSM-900 uplink from 880 MHz |
| 902–928 MHz ISM (US) | +12 dB above kTB | Yes — cellular below, SMR/paging above |

Europe's figure is lower because SRD rules cap duty cycle at around 1%; US ISM
has no such limit.

At 915 MHz in 125 kHz this puts a dense-urban site at about **−111 dBm** of
in-band traffic against **−121 dBm** of unintentional noise. The traffic term is
ten times the power of the one P.372 describes, and it is the reason the modeled
floor moves at all on a 900 MHz network.

**This is the least certain number in the whole model.** The land-cover weights
are at least anchored to a published raster; this reference is a seed chosen to
land dense-urban around −111 dBm and rural near thermal. Every explanation on a
shared band says so, and §9 explains how to displace it with a real measurement,
which is by far the better option. To retune the seed itself, see **Tuning the
model by hand** at the end of this section.

### Mechanism 3: adjacent-band desensitization

The third mechanism is not noise at all.

902–928 MHz has cellular downlink immediately below it (869–894 MHz) and
SMR/paging immediately above (928–941 MHz). Those are high-power licensed
services, and a cell site radiates orders of magnitude more power than anything
in the ISM band. A receiver with a good filter in front of it rejects that
energy — typically a **SAW filter** (surface acoustic wave), a small passive part
that passes the wanted band and rejects everything else. A cheap radio module
built without one does not: the strong neighbour drives its front end out of its
linear range, and the radio simply gets *worse* — its own noise figure degrades.

That is **blocking**, or desensitization, and it behaves differently from noise:

- Noise **adds power to the band**, so it is power-summed with everything else
  (§8).
- Blocking **degrades the receiver**, so it is charged against the receiver's own
  reference floor before anything is summed.

Cell sites are built where people are, so this also tracks the density index —
but linearly in dB rather than through a power law, because blocking is a
receiver property, not a power sum:

```
desense (dB) = configured desense at full density × site density index
```

The default is **6 dB at a density index of 1.0**, applied only on bands flagged
above as having a high-power neighbour. A dense-urban site takes the full 6 dB; a
suburb at 0.4 takes 2.4 dB; a forest takes essentially none. 433 MHz has no such
neighbour and never takes any.

**6 dB is a guess about your hardware, and RidgeCast cannot see your hardware.**
A module with a proper front-end filter deserves close to 0; a bare, unfiltered
LoRa transceiver board within sight of a cell tower could be worse than 6. Only a
blocking test on your own radio settles it. See **Tuning the model**
below for how to change or disable it.

### Tuning the model

Configure these parameters under **Settings → Ambient Noise Settings** in the top
menu bar (or via **Configure Ambient Noise…** in **Settings → Application Preferences**
under Propagation). Changes take effect immediately, are fully undoable (`Ctrl+Z`),
persist in your network file, and automatically update link evaluations and
coverage overlays without requiring any manual JSON editing:

| Control | Field | Default | What it does |
| --- | --- | ---: | --- |
| **Model in-band traffic** | `shared_band_occupancy_enabled` | `true` | Turns mechanism 2 off entirely across all shared spectrum bands |
| **In-band traffic seeds** | `shared_band_occupancy_db` | see band table | Per-band occupancy reference (dB above kTB at density index 1.0). Sliders and Reset buttons adjust each band |
| **Receiver desense** | `adjacent_band_desense_db` | `6.0 dB` | Desense at full density; `0.0 dB` disables mechanism 3 (for well-filtered radios) |
| **Population weight** | `population_blend` | `0.20` | WorldPop population's share of the density index vs NLCD land cover (0.0 = Land cover only, 1.0 = Population only) |
| **Reference density** | `population_reference_density` | `3000` | People/km² mapping to 1.0 density index (dense urban) |

Each slider includes an individual **Reset** button to return to its default, and
**Reset All to Defaults** restores the entire noise model. In saved `.json` network
files, values are stored in the `ambient_noise` object, where omitted fields keep
their defaults.

For example, when using radios with cavity filters in a quiet 900 MHz band: set
**902–928 MHz ISM** to `6.0 dB` and **Receiver desense** to `0.0 dB`.

The **receiver noise figure** is a different setting in a different place: it is
per-radio rather than per-network, and lives on the node or system profile as
`receiver_noise_figure_db`. §6 explains why setting it correctly matters more
than anything on this list.

### Where it refuses to answer

All three mechanisms depend on the density index, so where the index cannot be
computed, all three stop together and the receiver reference stands alone — with
a warning rather than a silent substitution. Three cases do that:

- **Frequency outside 0.3–1000 MHz.** The model is not extrapolated past the data
  behind it. (Every shared band in the table sits inside this range, so this case
  only ever silences mechanism 1.)
- **NLCD coverage below 90%** of the requested area *and* no population data for
  the site. Coverage is measured against the area actually requested, so a node
  near a coastline or outside the United States falls short on land cover alone —
  but if WorldPop covers it, the model runs on population instead of giving up.
- **A land-cover class with no configured weight.** An unknown class is treated
  like raster NoData rather than being quietly assigned a weight of zero, which
  would make unknown ground read as perfectly quiet.

That last point generalises: **NoData is excluded from the area weighting, never
counted as quiet land.** A cell with no measurement is not a cell measuring zero.

Below 30 MHz the ordinary floor carries an extra warning because natural noise can dominate. The optional [verified P.372 atmospheric component](../reference/scientific-models.md#p372-atmospheric-noise-at-2030-mhz) adds seasonal and geographic atmospheric power at 20–30 MHz after explicit preparation. Galactic noise remains unmodeled. Missing requested atmospheric inputs make modeled margins unavailable; a compatible measured total floor retains precedence.

## 8. Combining them

Blocking comes first, because it changes the receiver rather than the band:

```
degraded receiver (dBm) = receiver reference + desense
```

Then the two noise powers are **added in linear power**, not in decibels:

```
total = 10·log10( 10^(degraded receiver/10) + 10^(unintentional/10) + 10^(occupancy/10) )
```

Linear power addition is the only correct way to combine independent noise
sources, and it has a useful property: whichever term is largest dominates, and a
term 10 dB below its rival adds only about 0.4 dB. An environmental contribution
therefore matters exactly when it is comparable to or larger than the receiver's
own floor — and not otherwise. This single fact explains most of what follows.

The difference between the final floor and the receiver reference **as it would
have been without desense** is reported as the **environmental noise penalty** —
the number that tells you what this location is costing you. Measuring from the
undesensed reference is deliberate: desense is part of what the location costs
you, so it belongs inside the penalty. That is why the penalty can be non-zero
even where both noise terms are negligible.

### Two worked examples

Both examples use **a site density of 0.4**. That is what §7's machinery produces
for an ordinary suburb: a local circle that is mostly NLCD class 22, developed
low intensity, weight 0.400, with a context ring that is a mix of 22 and 23 and
some open space. Blended 80/20, the answer lands near 0.4. Nothing below depends
on that number being exactly right — the point is how much difference it makes.

**A 915 MHz mesh node in a suburb, realistic receiver.** 125 kHz NEB, 6 dB noise
figure, site density 0.4, all three mechanisms in play:

| Step | Value |
| --- | --- |
| kTB over 125 kHz | −123.01 dBm |
| Receiver reference | −123.01 + 6 = −117.01 dBm |
| Desense (6 dB × 0.4) | +2.40 dB → degraded receiver −114.61 dBm |
| Hagn/NTIA city reference at 915 MHz | 49.2 − 15.8·2.961 = 2.41 dB |
| Unintentional noise at density 0.4 | −123.01 + 2.41 − 3.98 = −124.58 dBm |
| In-band traffic at density 0.4 | −123.01 + 12 − 3.98 = −114.99 dBm |
| Combined floor | **−111.56 dBm** |
| **Environmental penalty** | **≈ 5.5 dB** |

Look at the ordering. In-band traffic (−114.99) is nearly **10 dB louder** than
the unintentional noise P.372 describes (−124.58), and the desense charged
against the receiver is worth more than the P.372 term too. On this band, the
mechanism that the classical model covers is the one that matters least.

Move the same radio to deciduous forest (density 0.012) and the penalty falls to
about **0.3 dB** — a swing of over 5 dB between suburb and forest, at the same
frequency with the same radio.

**The same site and the same radio, with stock defaults.** Everything is
identical — 915 MHz, 125 kHz, density 0.4 — except the noise figure. This is the
23.01 dB RidgeCast infers when a node declares a −100 dBm sensitivity and no
explicit noise figure:

| Step | Value |
| --- | --- |
| kTB over 125 kHz | −123.01 dBm |
| Receiver reference | −123.01 + 23.01 = −100.00 dBm |
| Desense (6 dB × 0.4) | +2.40 dB → degraded receiver −97.60 dBm |
| Unintentional noise at density 0.4 | −123.01 + 2.41 − 3.98 = −124.58 dBm |
| In-band traffic at density 0.4 | −123.01 + 12 − 3.98 = −114.99 dBm |
| Combined floor | **−97.51 dBm** |
| **Environmental penalty** | **≈ 2.5 dB** |

Both noise terms are *numerically identical to the previous example* — same site,
same band. Only the receiver changed.

Almost all of that 2.5 dB is desense, and both noise terms have vanished — they
are 15 dB and 25 dB below a receiver whose implied noise figure is 23 dB. This is
worth dwelling on, because it is a trap: **a receiver declared that noisy cannot
show you an environmental effect, no matter how noisy the environment is.** If
your nodes use the stock −100 dBm sensitivity with no explicit noise figure, set
a real `receiver_noise_figure_db` on the system profile before drawing
conclusions from this model. See §6.

**A 146 MHz VHF receiver.** 12.5 kHz NEB, 6 dB noise figure — a competent VHF
radio — same suburban density of 0.4. 2 m is not a shared band, so only
mechanism 1 applies: no in-band traffic term, no desense.

| Step | Value |
| --- | --- |
| kTB over 12.5 kHz | −133.01 dBm |
| Receiver reference | −133.01 + 6 = −127.01 dBm |
| P.372 city reference at 146 MHz | 76.8 − 27.7·2.164 = 16.85 dB |
| Site `Fam` at density 0.4 | 16.85 − 3.98 = 12.87 dB |
| Environmental noise power | −133.01 + 12.87 = −120.14 dBm |
| Combined floor | **−119.33 dBm** |
| **Environmental penalty** | **≈ 7.7 dB** |

Nearly 8 dB — a factor of six in power — lost purely to where the receiver sits,
from unintentional noise alone. Move the same radio to deciduous forest and the
penalty drops to about 0.6 dB.

### What actually decides whether any of this is visible

Two things, and neither of them is the environment:

- **Your receiver's noise figure.** Every mechanism here is judged against the
  receiver's own floor, so a receiver 23 dB above thermal hides all of them. This
  is the single most common reason the model appears to do nothing.
- **Your band.** Below 200 MHz, unintentional noise carries the result on its
  own. On 433/868/915 MHz it has faded to near-irrelevance and in-band traffic
  carries it instead. A model with only mechanism 1 would appear to do nothing at
  all on a 900 MHz network.

Put together: a 2 m FM network with real noise figures sees a large effect from
unintentional noise. A 915 MHz mesh with real noise figures sees a large effect
from in-band traffic and desense. A 915 MHz mesh with datasheet sensitivities
sees almost nothing from anything, because its declared receiver is already
noisier than any environment RidgeCast can model.

### The Site Finder's reference receiver

Site Finder scores hypothetical locations using its own transmitter and
reference receiver settings. Its legacy preset uses a 30 dBm transmitter,
5 dBi antenna and 10 m mast, and a receiver with a **6 dB noise figure** rather
than the 23.01 dB a −100 dBm sensitivity would imply. Choose systems or edit
these settings under **Candidate transmitter and reference receiver**; they
are separate from coverage's Test Node.

That distinction is the difference between "Factor in Environmental Noise" doing
something and doing nothing. A sensitivity figure is a demodulation threshold,
not a thermal noise floor; treating one as the other puts the reference front end
so far above thermal that no land cover or population anywhere could move it at
UHF. The worked examples above are exactly that comparison.

What Site Finder adds to its selected receiver threshold (−100 dBm in the
legacy preset) is therefore the
**penalty** — how much the environment raises a real receiver's floor — not an
absolute modeled floor. The penalty uses the selected receiver's noise figure
and bandwidth. With the toggle off, every candidate is scored against the
selected threshold. Grading is unchanged; only the spread between noisy and quiet
sites appears.

## 9. Overriding the model with a measurement

A modeled prior should always lose to a real measurement, and a node can store
measured noise floors — either an **exact-channel** measurement or a **band**
measurement covering a frequency range.

Three modes control how they are used:

| Mode | Behavior |
| --- | --- |
| **Automatic** (default) | Prefer the most specific compatible measurement; fall back to the model. |
| **Modeled only** | Ignore measurements entirely. |
| **Measured override** | Require a measurement; warn and fall back if none is compatible. |

A measurement is **compatible** only if all of these hold:

- It covers the frequency — an exact-channel measurement within 1 Hz of the
  network frequency, or a band measurement whose range contains it. Exact-channel
  wins over band; among equals, the most recent wins.
- Its **equipment configuration ID** matches the node's. This is the field that
  stops a measurement taken with one antenna and preamplifier from being applied
  to a different setup.
- It is within the configured maximum age, if one is set.
- Its bandwidth matches the receiver's to within 0.5% — **or** it is explicitly
  marked broadband/white-noise-like, in which case RidgeCast converts it by
  `10·log10(target NEB / measured NEB)`.

That last restriction is deliberate and worth dwelling on. Scaling a measurement
by bandwidth is only valid if the noise is spectrally flat across the range. A
measurement dominated by one carrier does not get ten times louder when you
listen ten times wider — it stays exactly as loud, and converting it would
overstate the floor badly. RidgeCast will not do the conversion unless you assert
the measurement is broadband.

When measurements exist but none is compatible, that is reported as a warning.
The node editor shows the effective value, the modeled alternative, the receiver
reference, the environmental penalty, the frequency branch, the density, the
coverage fraction, and any warnings — after link recalculation.

## 10. Fade margin, and the bands

Finally:

```
fade margin (dB) = RSL − effective noise floor
```

RidgeCast reports this as an SNR in dB, and grades it against three thresholds
configured under **Settings → Fade Margin Settings**:

| Band | Default threshold |
| --- | --- |
| **Good** | ≥ 20 dB |
| **Fair** | ≥ 10 dB |
| **Marginal** | > 0 and < 10 dB for coverage statistics |
| **Poor** | ≤ 0 dB for coverage statistics |

These thresholds drive link colors, coverage colors and quality counts, Site
Finder's Good/Fair/Marginal/None tallies, and GIS link colors. Exact boundary
classification differs: coverage counts a value exactly at Marginal as Poor,
while Site Finder counts it as Marginal. Smooth coverage colors blend between
the thresholds. See [Coverage modes](../reference/coverage-modes.md) and
[Finding sites](site-finder.md) for the relevant interpretation.

A separate **Best Unit threshold** (default 10 dB) is an absolute minimum fade
margin for retaining service in Best Unit, Redundancy, and Unique Coverage.
It does not compare the winner with the runner-up: at a 10 dB threshold, nodes
with 15 dB and 14 dB both qualify, and Best Unit chooses the stronger one.
See **[Coverage maps](coverage.md)**.

Note the precision on offer here is not the precision of the answer. The worked
figures above are quoted to a hundredth of a decibel because that is what the
arithmetic produces, but the environmental term feeding them is a **low-confidence
prior** built from a land-use raster: it is a median expectation for a class of
place, not a measurement of yours. Treat the modeled floor as good to within
several decibels at best, and prefer a site measurement (§9) whenever you have
one. That gap is exactly why §9's compatibility rules are as strict as they are.

Zero dB of margin does not mean "works". It means the signal equals the noise. A
real deployment wants margin for rain, foliage in leaf, seasonal variation,
antenna misalignment, and everything the model does not know about — which is
what the word *margin* is doing in the name.

## 11. Where this is not the whole story

- **Optional atmospheric noise has a limited range.** The verified P.372 component supports 20–30 MHz, actual receiver coordinates, an authored month and UTC hour. It remains disabled by default. Galactic and precipitation noise remain unmodeled, so this is not a complete expected HF floor.
- **NLCD is a proxy, not a survey.** It describes what the ground is used for,
  not what is plugged in. It is a median expectation, not a channel-occupancy
  model, and it cannot see a single loud offender — the failed streetlight
  ballast that dominates your actual noise floor is invisible to it.
- **Named interferers require an explicit scenario.** [Co-channel scenarios](../reference/interference-scenarios.md) evaluate bounded named transmitters through the shared CPU propagation and antenna paths, then report power contributions and SINR separately from ordinary SNR. The background policy states whether a measured floor already includes them. Adjacent-channel coupling is outside this scenario contract; aggregate shared-band traffic remains the separate prior in §7.
- **The in-band traffic term is a seed, not a survey.** It is the largest term on
  a shared band and the least defensible: no raster backs it, and it cannot see
  the one busy gateway next door, a duty cycle unlike the assumed one, or a band
  that is simply quieter where you are. Treat it as a prior to tune against a
  measurement, not a prediction. Every explanation on a shared band says so.
- **Desense is a guess about hardware RidgeCast cannot see.** 6 dB at full urban
  density is a plausible unfiltered module. A filtered one deserves near 0. Only
  a blocking test on your own radio settles it.
- **United States only.** NLCD covers the US; elsewhere the land-cover gate fails
  and WorldPop population carries the model on its own, or the receiver reference
  is used with a warning if neither is available.
- **The receive threshold used by Site Finder is not this one.** Site Finder
  scores thousands of hypothetical antenna positions that are not nodes, so it
  works from its selected receiver threshold (−100 dBm in the legacy preset)
  plus, optionally, the environmental penalty for
  each candidate. See **[Finding sites](site-finder.md)**.
- **Antenna patterns are two points.** A boresight gain and a front-to-back
  ratio. Real patterns have structure this does not reproduce.
- **Beamwidths are derived, and only the azimuth one is charged.** The azimuth
  width is the pattern's own −3 dB crossing; the elevation width is inferred from
  gain, and neither it nor antenna tilt changes any computed loss.
- **Feedline, duplexer, and connector losses are one number you enter.** Nothing
  is derived from cable type or run length.

---

## Where else to look

- **[Choosing a propagation model](propagation-models.md)** — where the path-loss
  term in §3 comes from, and how ITM and P.1812 differ.
- **[Clutter, LiDAR, and canopy density](clutter-and-lidar.md)** — how trees and
  buildings along the path are charged for.
- **[Coverage maps](coverage.md)** — the same chain, evaluated over an area
  instead of one path.
- **[Network analysis](network-analysis.md)** — what gets built on top of the
  fade margins this document produces.
- **[`docs/propagation-model-decisions.md`](../propagation-model-decisions.md)** —
  the engineering decision record behind these choices.
