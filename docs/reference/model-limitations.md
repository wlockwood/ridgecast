# Model limitations

RidgeCast is a planning tool, not a substitute for field surveys, regulatory
review, frequency coordination, or safety analysis.

- Terrain and land-cover data can be missing, stale, generalized, or inaccurate.
- FCC mailing addresses and ZIP centroids are not necessarily transmitter
  locations.
- ITM defaults to the historical typical-ground, continental-temperate,
  vertical, 50/50 preset. Advanced settings change environment and statistical
  loss percentiles, not observed availability. Nonlegacy inputs use CPU and
  bypass unproven optimistic pruning.
- The native terrain-diffraction path is P.1812-inspired, not a complete P.1812
  implementation. It omits clutter loss, complete delta-Bullington diffraction,
  troposcatter, anomalous propagation, and variability.
- The separate complete outdoor P.1812-7 mode uses ITU's advised troposcatter
  correction, explicit refractivity and uniform climatic-zone assumptions,
  physical terminal heights and representative clutter. It excludes optional
  indoor building-entry loss; [its scientific contract and validation](scientific-models.md)
  do not establish geographic data certainty or measured service availability.
- GPU propagation is an interactive approximation, applies only with ITM mode,
  and does not reproduce every CPU ITM effect.
- Measured public surfaces depend on LiDAR coverage and acquisition dates.
  Registered aligned DSM/DTM surveys can supply local heights; they require
  matching metre grids and a declared vertical datum. The selected DEM remains
  authoritative, and no vertical conversion or RF density inference is performed.
  Missing measured samples fall back to categorical land-cover clutter.
- ESA WorldCover 2021 v200 crops supply categorical data outside NLCD coverage.
  Their documented RF crosswalk approximates forest type, urban intensity and
  moss/lichen treatment. Unknown classes remain unknown; this does not establish
  equivalent accuracy or resolution to NLCD.
- LiDAR return-density ratios are retained for diagnostics but do not alter RF
  attenuation; they are not pulse-penetration measurements.
- Antenna patterns, local obstructions, feed-line details, interference, and
  regulatory constraints require independent verification.
  Optional analytic vertical taper and imported separable cuts affect RF
  budgets. Separable cuts are not full 3D patterns; the display wedge does not
  plot measured sidelobes or nulls.
- WorldPop 2020 UN-adjusted constrained population is limited to mapped settlements.
  Missing settlement footprints can omit residents; national adjustments and
  ~100 m cells do not establish local accuracy or reflect changes since 2020.
- NLCD and population are proxies for how built up a site is, not measurements of
  what is transmitting there. They drive all three noise mechanisms.
- On shared bands (902–928, 863–870, 433 MHz), the in-band traffic term is the
  largest contributor and the least defensible: it is a seed level scaled by
  development density, with no survey behind it. It cannot see one busy gateway
  next door, an unusual duty cycle, or a locally quiet band.
- Adjacent-band desense defaults to 6 dB at full urban density, which assumes an
  unfiltered receiver front end. RidgeCast cannot see your hardware; a filtered
  module deserves far less. Set it to 0 in **Settings → Ambient Noise Settings** if that is your case.
- Named co-channel sources can be evaluated in an explicit bounded
  [interference scenario](interference-scenarios.md), with selected-background
  policy to avoid double counting measurements. Adjacent-channel interference,
  receiver capture, overload and intermodulation remain unmodeled.
- Below 30 MHz, the displayed man-made-noise term is incomplete until
  atmospheric noise is modeled. The optional pinned P.372 component covers
  20–30 MHz, requires month/time/location and omits galactic noise and ionospheric
  propagation. Prefer compatible field measurements where they
  are available.
- Site Finder scores rank candidates under the selected assumptions; they are
  not propagation guarantees.
- Network success probabilities and throughput values depend on configured
  assumptions and are not observed service-level measurements.

See [Choosing a propagation model](../concepts/propagation-models.md),
[From transmit power to fade margin](../concepts/link-budget-and-noise.md), and
[Network analysis](../concepts/network-analysis.md) for interpretation.
