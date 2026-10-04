# Display units

On the first launch of a new RidgeCast installation, choose **Metric** or
**US customary**. Change this later under **Settings → Application Preferences →
Distance and height units**.

Distance, height, area, and density readouts put the selected system first and
show the equivalent in parentheses. Distance and height sliders use convenient
steps in the selected system. Geodata source titles such as **3m** and **10m**
retain their names because those numbers identify the source data.

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
