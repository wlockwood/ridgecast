# Import vector overlays and export GIS data

## Import reference overlays

Before importing, reproject data to WGS 84 geographic coordinates (EPSG:4326)
with longitude first and latitude second, expressed in decimal degrees. RidgeCast
can recognize some out-of-range Web Mercator (EPSG:3857) coordinates and convert
them, but that fallback is not a replacement for checking the layer's CRS and
placement in your GIS.
Automatic conversion is a fallback for some out-of-range coordinates, not a
general CRS detector. A wrong or mixed CRS may import in the wrong place.

1. Choose **File → Import → Vector Overlays (KML, GeoJSON, GPX)…**.
2. Select one or more KML, KMZ, GeoJSON, or GPX files.
3. Open the **Vector Layers** section of the **Layers** drawer.
4. Confirm the layer appears at the expected location on the map, then set
   visibility, stroke color, stroke width, and fill color. If placement is
   wrong, reproject the source in your GIS and import it again.
5. Choose whether the geometry is embedded in the project or referenced by its
   external path.

Embed a small layer when the project must travel as one file. Keep a reference
when the source layer is large or maintained elsewhere; copy that external file
alongside any project backup or share, and repair the reference if it moves.

Layers retain their source path when you switch **Embed in Project** on and
off. Embedded geometry, name, visibility, outline/fill colors, and stroke width
travel in the native network file. References within the project's directory
are saved relative to that file, so moving the whole directory preserves them.
Opening another network replaces the layer list; a new network starts empty.

A missing reference remains listed with an error. Choose **Relink source…** in
**Vector Layers** and select its new file. Relinking keeps the layer's name,
style, and visibility. Import and relink run in the background; **Cancel layer
import** stops them. Inputs are limited to 64 files per import, 50 MiB per file,
and 100,000 features per layer. Layer changes participate in Undo/Redo.

RidgeCast expects geographic WGS84 coordinates. When GeoJSON or KML coordinates
are outside geographic bounds, it attempts to unproject Web Mercator
(EPSG:3857) coordinates automatically.

## Export network and coverage data

1. Calculate the links or coverage you want to publish.
2. Choose **File → Export → GIS Data (KML, GeoJSON, GeoTIFF)…**.
3. Select KML, KMZ, GeoJSON, or GeoTIFF output.
4. Choose whether to include custom vector reference layers.
5. Enable **Export Selected Nodes & Links Only** when the topology export should
   be restricted to the current selection. Coverage and vector layers are not
   filtered by this option.
6. Choose a destination and wait for the background export to complete.

**Cancel export** stops the active GIS job. **Close** only hides the dialog;
reopen it to see the same job and its eventual result. Writers stage complete
files before publishing them. Cancellation removes staging files and preserves
previous destinations, including rollback when a multi-file publication has
already started.

Use KML/KMZ for Google Earth-style map exchange, GeoJSON for vector features and
their RF attributes, and GeoTIFF for a coverage raster. GeoTIFF exports coverage
only: `Color Categories` preserves the on-map bands and `Fade Margin (dB)`
stores retained margins. `Receive Power (dBm; unavailable)` writes NoData;
absolute received powers are not retained in coverage cells.
Each TIFF embeds WGS84 (EPSG:4326), north-up placement, and area-registered
pixels, following the [OGC GeoTIFF standard](https://docs.ogc.org/is/19-008r4/19-008r4.html).
It opens in its geographic position without a sidecar. RidgeCast also writes a
matching `.tfw` world file using pixel-center coordinates for older readers.
Unavailable numeric pixels carry an explicit `-9999` NoData tag; unavailable
color pixels are transparent.

See [Files and interchange formats](../reference/files-and-formats.md) for the
contents and limitations of each format.
