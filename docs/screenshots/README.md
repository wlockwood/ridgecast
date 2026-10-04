# RidgeCast screenshot checklist

**Status:** Three actual desktop captures are included in
[the visual tour](../visual-tour.md): the network overview, Fade Margin
Settings, and Radio Systems Manager. Unchecked items below are future gallery
suggestions, not existing illustrations.

The included captures use one synthetic six-site demonstration network with
illustrative saved link values, offline mode, and a plain basemap. They contain
no personal network data or amateur-license records. The images show the real
interface; their link colors do not validate an RF prediction.

The root README should open with one strong overview image and a short visual tour. A detailed gallery can show every mode and tool without making the project landing page slow or difficult to scan.

## Capture standards

- Use the same synthetic or intentionally public demo network throughout the gallery.
- Prefer a 16:10 window around 1440 × 900 pixels and save lossless PNG files.
- Use a consistent map region, zoom level, basemap, and window theme where practical.
- Keep map-provider attribution visible.
- Do not expose private node-source URLs, local paths, or personal network data.
- Avoid displaying FCC street addresses. Callsigns and approximate map locations should only be included when appropriate for the example.
- Crop empty desktop space, but retain enough application chrome to make the active mode or tool obvious.
- Provide useful alt text when each image is embedded in Markdown.

## Root README set

These images tell the story without requiring the reader to open the full gallery:

- [x] `overview.png` — normal network view with the side panel and illustrative directed links
- [ ] `coverage.png` — selected nodes with a representative coverage result
- [ ] `link-profile.png` — terrain, Fresnel clearance, land cover, and link-budget details
- [ ] `site-finder.png` — completed Site Finder overlay and ranked results
- [ ] `amateur-radio.png` — filtered amateur markers, a co-located group, and candidate links

Use `overview.png` as the hero image near the top of the root README. The remaining four work well as a two-column visual tour. Link that tour to a detailed `docs/visual-tour.md` gallery.

## Detailed mode gallery

### Network and link views

- [ ] `views/global-network.png`
- [ ] `views/vulnerability.png`
- [ ] `views/link-fade-margin.png`
- [ ] `views/link-distance.png`
- [ ] `views/link-fortuity.png`
- [ ] `views/connectivity-health.png`
- [ ] `views/site-ranking.png`
- [ ] `views/full-short-icon-labels.png` — one comparison image is sufficient

### Coverage

- [ ] `coverage/tx-vertex-grid.png`
- [ ] `coverage/rx-radial-sweep.png`
- [ ] `coverage/max-fade-margin.png`
- [ ] `coverage/best-unit.png`

### Map and data overlays

- [ ] `map/basemaps.png` — compare None, Road, Topographic, and Satellite in one image
- [ ] `map/terrain-normal.png`
- [ ] `map/terrain-multiply.png`
- [ ] `map/land-cover.png`
- [ ] `map/terrain-tile-status.png`

The six terrain draw styles can be presented as one labeled comparison rather than six full-window screenshots:

- [ ] `map/terrain-draw-styles.png` — Gray Scaled Slope, Colored Absolute, Colored Relative, X-Ray, X-Ray Inverted, and Rainbow

### Tools and dialogs

- [ ] `tools/add-node.png`
- [ ] `tools/node-editor.png`
- [x] `tools/systems-manager.png`
- [ ] `tools/link-details.png`
- [ ] `tools/link-profile.png`
- [ ] `tools/site-finder.png`
- [ ] `tools/node-sources.png`
- [ ] `tools/downloads.png`
- [ ] `tools/map-settings.png`
- [ ] `tools/land-cover-settings.png`
- [x] `tools/fade-margin-settings.png`
- [ ] `tools/global-frequency.png`
- [ ] `tools/application-preferences.png`

### Amateur-radio workflow

- [ ] `amateur/config-and-freshness.png`
- [ ] `amateur/license-class-colors.png`
- [ ] `amateur/site-score-colors.png`
- [ ] `amateur/callsign-labels.png`
- [ ] `amateur/callsign-search.png`
- [ ] `amateur/co-located-licenses.png`
- [ ] `amateur/lasso-selection.png`
- [ ] `amateur/candidate-links.png`
- [ ] `amateur/selected-coverage.png`

## Final image pass

Before committing captures:

1. Verify every image reflects the current labels and menu structure.
2. Check that no generated network, FCC database, or private address data is staged.
3. Compress PNG files with a lossless optimizer.
4. Confirm the README remains readable on a narrow browser window.
5. Add or update the corresponding image whenever a UI change makes an existing screenshot misleading.
