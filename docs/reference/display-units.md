# Display units

On the first launch of a new RidgeCast installation, choose **Metric** or
**US customary**. Change this later under **Settings → Application Preferences →
Distance and height units**.

Distance, height, area, and density readouts put the selected system first and
show the equivalent in parentheses. Distance and height sliders use convenient
steps in the selected system. A slider rounds to its step only when you move
it, so opening a network never changes its stored values. Geodata source titles such as **3m** and **10m**
retain their names because those numbers identify the source data.

Radio and terrain controls follow the same choice:

- In **Complete P.1812 outdoor assumptions**, the prediction resolution and the
  TX and RX coast distance fields are shown and edited in your chosen unit
  (meters or feet for resolution, kilometers or miles for coast distance). The
  coast distances are still stored in kilometers, and a value changes only when
  you edit it.
- A terrain source's vertical offset, the Task Readiness profile spacing, and
  the Site Finder quality tooltips show your chosen unit.
- The Height Study range message ("Enter a lower height of at least ...") names
  the limits in your chosen unit first.
- System profile summaries, such as `20'/6m` (US customary) or `6m/20'`
  (metric), put the antenna height in your chosen unit first. Each height is
  rounded to a whole number in both units, so a 6 m antenna reads as `20'`
  although it is 19.7 ft. The summaries appear wherever you pick a system: the
  node editor, bulk edit, the node-source import role pickers, and the
  amateur-radio RF system selector, plus the Systems Manager headings and its
  **Add Built-in System…** menu.

RidgeCast stores network and calculation values in metric units regardless of
the display choice. When a network contains data, switching units asks for
confirmation. The switch rounds the global coverage range, hex resolution,
Site Finder resolution, and Test Node antenna height to convenient values in
the selected system. These
small changes can affect calculated results, so review those settings after
switching. Existing installations without a saved unit choice continue in
metric until you choose otherwise.

Network files and interchange fields with unit names in their format, such as
`coverage_range_m` or `$range_km`, retain those units. The display preference
does not rewrite the meaning of imported or exported data.
