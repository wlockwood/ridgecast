# Nodes and systems

Directed channel/radio labels, assumed PHY rates in bit/s and measured/assumed
delays in ms belong to the network's saved analysis inputs, independently of
the RF radio profile and calculated links. Edit them in **Analysis Results →
Assumptions → Edit directed inputs and facility inventory**. Each ordered pair
has separate overrides; recalculation preserves them. See
[Network-analysis inputs](network-analysis.md#assumptions) for units, fallback
semantics and the distinction between contention labels and RF frequency.

## Systems

A system profile stores RF parameters shared by several nodes, including
transmit power, receive characteristics, antenna gain and height,
system losses, coverage settings, and an equipment-configuration identifier.
Editing a system updates nodes that inherit those values.

### Starter systems

A new network opens with three system profiles covering common install heights.
Every other parameter starts at the same defaults, and all three are ordinary
systems you can edit, rename, duplicate, or delete.

| System | TX power | Antenna gain | Antenna height AGL |
| --- | --- | --- | --- |
| **Basic - Single-Story** | 22 dBm | 2 dBi | 6 m (20 ft) |
| **Moderate - Second Story** | 28 dBm | 5 dBi | 8 m (26 ft) |
| **Tower** | 30 dBm | 8 dBi | 33 m (108 ft) |

Nodes that have no system assigned resolve against **Basic - Single-Story**.

All three start with −100 dBm receive sensitivity, 125 kHz noise-equivalent
bandwidth, 0 dB system loss, and an omnidirectional antenna. Noise figure is
initially unset; RidgeCast derives a legacy-equivalent value from sensitivity
and bandwidth, rather than assuming a measured receiver noise figure.
Frequency belongs to the network, not the system profile: a new network starts
at 910.525 MHz, editable under **Settings → Network Frequency…**. See
[From transmit power to fade margin](../concepts/link-budget-and-noise.md)
before relying on these receive defaults.

## Nodes

A radio node stores its location, identity, system assignment, enabled and
visibility state, and optional overrides. A marker node is an annotation and
does not participate in propagation or network analysis.

Node overrides take precedence over the assigned system. Use overrides for
site-specific values; use a system change when every inheriting node should
change.

### Node list and details

The right panel lists all nodes, including hidden and disabled nodes. Its sort
button cycles through alphabetical name, qualifying link count, and cached
terrain elevation. Select a row to show its details; Ctrl-click extends the
selection, double-click centers the map, and right-click opens node actions.
Click the blank space beneath the list to clear the selection.

Node ordering and the selected nodes' viable-link rows update in the background.
While a changed network, sort, threshold, or terrain source is being prepared,
the affected list shows **Updating node list…** or **Updating viable links…**.
Rows from an older network are not shown during that update. Selections remain
intact, and you can continue editing or selecting nodes on the map. Elevation
ordering uses available cached terrain, including local files; it does not
request downloads. The viable-link sort button cycles through SNR, distance,
and peer name. Arrows distinguish incoming and outgoing directed links.

## Antennas

Antennas are omnidirectional by default. A system or individual node can define
a directional antenna with an azimuth (degrees true) and front-to-back ratio
(dB), and any antenna can be given a tilt in degrees — positive above the
horizon, negative below. RidgeCast derives a half-power display beam from the
stored gain, azimuth taper, front-to-back ratio, and tilt; it is a simplified
pattern, not a measured manufacturer pattern. The link-profile plot draws that
beam for both ends of a link; see
[From transmit power to fade margin](../concepts/link-budget-and-noise.md#beamwidth).
Rated gain
applies on boresight and tapers toward the configured rear response.

An azimuth can be locked to another node. RidgeCast recomputes that bearing when
either endpoint moves.

## Other node properties

### Optional vertical response and measured cuts

In node/system antenna editors, **Local vertical RF taper** enables
`−min(Amax, 12 × ((ray elevation − stored tilt)/beamwidth)²)` dB. Supply full
half-power width in (0,180] degrees and finite maximum attenuation at least
3 dB. Half a width gives −3 dB; positive ray elevation and tilt are above the
horizon. Ray elevation uses bare-earth endpoint altitudes plus physical AGL
heights, including surface-reference offsets. This adds to horizontal response
once at each TX/RX. Legacy gain is unchanged when elevation options are absent.

**Import measured cuts (CSV)…** validates a bounded file on a worker. The
[CSV contract](files-and-formats.md#measured-antenna-cuts) supports periodic
azimuth and optional elevation with linear interpolation in dB and a normalized
0 dB peak relative to rated gain. Measured azimuth replaces cosine/omni response;
measured elevation replaces analytic taper. This is a separable-cut approximation,
not full 3D gain. Unset local responses inherit system responses. Changes
invalidate RF results/coverage identity and use CPU coverage prediction.
The shaded display wedge remains a simplified aiming aid.

| Property | Effect |
| --- | --- |
| **Backbone Hub** | Adds the node to the hub set used by reachability and resilience analyses. |
| **Risk Groups** | Labels shared failure domains for shared-risk route analysis. |
| **Range Circles** | Draws concentric planning-distance rings around the node with configurable spacing, colors, line and outline weights, and optional distance readouts (None, Metric, US Customary, or Both) with adjustable text size. |
| **Coverage range override** | Replaces the network-wide default coverage range for that node. |
| **Noise measurement** | Supplies a compatible measured receiver noise floor under the selected noise-floor mode. |

Selecting several nodes exposes **Edit N nodes**, which applies supported shared
changes as one undoable operation.
