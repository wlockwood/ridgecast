# Evaluate a radio link

Use Link Profile to inspect the path, compare the two radio directions, and review
antenna-height proposals before changing your network. A positive modeled margin
or clear Fresnel zone does not guarantee a working field link.

## Open and check the endpoints

1. Configure the intended radios, frequency, gains, losses, receiver bandwidth,
   noise figure and antenna mounting heights.
2. Select the first site, then **Shift-click** the second to preview a path.
3. Right-click the link or provisional path and choose **Show Link Profile**.
4. Wait for the background terrain and optional LiDAR preparation. **Cancel
   preparation** stops the request; **Refresh profile** retries it.

The initially selected source is **A**, at distance zero. The target is **B**, at
the path end. Cyan **A** and magenta **B** endpoint cards identify each site,
even when names match. Cards show mounting height in the preferred unit; hover a
card for its equivalent unit and ground, surface and antenna elevations. The
plot labels keep each endpoint identity beside its marker when it is in view.

Mounting heights are **above ground** or **above surface**, according to each
site's configured reference. For example, a 3 m Surface mounting height on a
20 m roof above 100 m ground places the antenna at 123 m elevation; the same
Ground mounting height places it at 103 m. Equal mounting heights do not imply
equal antenna elevations.

## Read geometry and the plot key

The plot keeps an always-visible, noninteractive key for marks currently drawn.
Open the default-collapsed **Legend & layers** drawer for checkboxes for
all layers, including hidden ones. Ground, obstacle surface, line of sight and
the 60% boundary start visible. Full Fresnel, beams and sea level start off. A
proposed-height overlay appears when available. Unsupported beam shapes explain
why they cannot be shown. Beam edges show −3 dB boundaries and a dashed
boresight; the small fan at an antenna shows the true angle. The plot can
exaggerate vertical distances, so use the fan or equal scale to read angles.
Faint beam edges indicate that the antenna's azimuth points away from the path.

The obstacle surface uses a neutral band by default. Enable **Land-cover colors**
in **Legend & layers** to color it by class and reveal the class key. Surface
colors identify land-cover class, not measured-versus-estimated provenance.

The direct ray and Fresnel clearance answer different questions. A path can have
an unobstructed direct ray and still miss the 60% Fresnel target. Geometry uses
the existing 4/3 effective-Earth assumption. Zero-radius endpoints are excluded
from Fresnel ratios and checked separately for antenna placement. Invalid or
incomplete numeric profiles cannot claim clear geometry.

Click the plot to pin a sample in **Path**. Inspect distance from both endpoints,
physical ground and surface elevations, class, direct-ray gap and signed 60%
boundary gap. Negative gap means intrusion. **Go to limiting obstruction**
frames the smallest signed 60% boundary gap, shown by the diamond. **Go to
minimum ratio** targets the sample with the lowest clearance ratio; the two
locations can differ. **Select exact sample** contains the numeric sample
control. Point-level measurement provenance is not retained in the profile.

## Compare both radio directions

Use the separate **A → B** and **B → A** buttons to inspect received level, the
labeled receiver reference and predicted margin for each direction. Radios,
alignment, model terminal behavior and receiver noise can make one direction
weaker. The receiver reference distinguishes modeled noise, measured noise,
receiver baseline and an explicit rated-sensitivity comparison. Environmental
noise penalties explain the retained floor and are not subtracted again from its
margin.

**Unknown** margin means a required receiver or propagation input is unavailable.
One direction can be Unknown while the other direction and the plot remain
usable. Missing requested noise does not silently substitute rated sensitivity.
Use your radio's requirements and field measurements to judge acceptable margin;
there is no universal positive-margin pass rule.

## Inspect frozen data and refresh

The bordered **Path**, **Heights** and **Inputs** tabs organize inspection and
actions. **Budget breakdown** and **Endpoint installation** are separate detail
disclosures; **Compare antenna heights** opens the Heights tab.

Open **Inputs**, or choose **Details**, to inspect the retained DEM source summary,
LiDAR ground policy, structured availability counts, preparation failures, source
reports, radios, model and receiver-noise explanations. Bare-ground DEM coverage
and LiDAR obstacle-surface availability are separate. Usable probe counts describe
sample availability, not survey confidence or an exact percentage of path length.
Unavailable LiDAR cells use categorical land-cover clutter estimates.

Geometry, budgets, heights, beams and CSV export share one accepted profile and
its frozen inputs. Background cache arrivals do not change that displayed result.
**Refresh profile** starts a new generation to include newly available data. A
retained prior result is explicitly read-only while refreshing. Changed radios,
sources, policies or document ownership invalidate pending results and height
proposals; late completions cannot replace the newer request.

## Compare and apply antenna heights

Open **Heights** and choose Source/A, Target/B, Both equal or Both independent.
The search may lower an existing mounting height; raise-only and separate endpoint
limits are not included in this release.

1. Select **60% Fresnel clearance** for the geometry target, or **Forward margin:
   A → B** for the captured forward receiver reference. Margin solving is
   unavailable when its required budget is Unknown; clearance solving remains
   available. Forward-margin solving does not guarantee the reverse direction.
2. Set the maximum mounting height relative to each site's Ground or Surface
   reference, then choose **Solve heights**. **Cancel search** discards pending work.
3. Review current/proposed/change values, resolved antenna elevations, both
   proposed margins and **Preview proposed geometry**. The current geometry
   remains faintly visible behind the proposed ray and 60% boundary.
4. Choose **Apply heights to network** as a separate action. Only the endpoints
   owned by that reviewed request change. Undo with **Control+Z**.

The finite search reports the lowest satisfying **tested candidate** in its search
order, not an exact continuous optimum. Single/equal modes use 0.5 m steps through
a maximum of 60 m, and 1 m above that. Independent mode uses 1 m through 40 m and
2 m above that, testing minimum total height first. The actual step is shown.
**Target not reached within these limits** reports the best tested proposal.
Changing goals, endpoint choice, limits, inputs or refresh invalidates the proposal.

## View, export and guide

**View…** switches between **Straight ray / curved terrain** and **True terrain
elevations / curved ray**, or enables **Equal horizontal and vertical scale**.
The elevation y-axis labels display stacked units without decimals, with your
currently selected units on top and the equivalent units below.
These display changes do not rerun propagation. **Fit path** and double-click
restore framing. Wide windows place the Path/Heights/Inputs inspector beside the
plot; narrow windows place a scrolling drawer below it.

**Export… → Copy profile CSV** copies the accepted profile on a background worker.
Its columns are `distance_m,ground_elevation_m,clutter_height_m,surface_elevation_m,land_cover_class,drawn_ground_m`.
Physical ground/surface values are invariant across projections; only
`drawn_ground_m` follows the view. Image/report exports and comparisons are not
included in this release.

**Guide** opens the nonmodal Link Profile Guide alongside the window, in the
largest free space that leaves Link Profile uncovered, and keeps it there as you
move Link Profile. Drag the guide to place it yourself; reopening it returns it
beside the window. **Show guide when Link Profile
opens** is a separate saved preference. Dismissal lasts for that opening,
including pair changes and refresh. Closing Link Profile closes its guide.

Estimated clutter and incomplete surface data can miss local obstacles. Confirm
important paths using installation details and field measurements. See
[Propagation settings](../reference/propagation-settings.md),
[Choosing a propagation model](../concepts/propagation-models.md), and
[From transmit power to fade margin](../concepts/link-budget-and-noise.md).
