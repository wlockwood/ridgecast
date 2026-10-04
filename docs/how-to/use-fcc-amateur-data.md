# Use FCC amateur-license data

Use this guide to display nearby FCC amateur records, search the local catalog,
and create planning nodes from license entries.

**Privacy before you begin:** RidgeCast stores the downloaded public catalog
locally. To place nearby records on the map, it can send batches derived from
nearby licensee mailing addresses to the U.S. Census geocoder. Do not enable
that step for an area whose location or address data you cannot disclose.

1. In Map Settings, enable **Amateur licenses**. If the local FCC catalog is empty,
   RidgeCast downloads it in the background and shows its progress below the
   checkbox. If the download fails, open **Config** to see the error and retry.
2. Select **Config** to refresh the FCC ULS amateur catalog later or import local
   FCC files.
3. Choose the license statuses and operator classes to display. Optionally limit
   results to licenses first observed within a recent number of years.
4. Pan to the planning area and, if the disclosure described above is
   acceptable, select **Find hams in current view** in **Config**. This submits
   nearby ungeocoded records to the U.S. Census batch geocoder. Until you do
   this, a newly downloaded catalog may have no locations to show on the map.
5. Use **Control+F** to search by callsign, name, address, city, state, or ZIP.
6. Select a result and use **Create Node here** when it should become a planning
   node.
7. Choose the RF system used for created nodes and amateur-link analysis before
   calculating links or coverage from selected amateur locations.

RidgeCast does not geocode the complete national catalog. It processes nearby
addresses in batches and caches the results. Dense views cluster only after more
than 500 filtered licenses are visible; co-located licenses remain one link or
coverage endpoint.

### Ham colors modes

The side panel offers three coloring modes for amateur markers:

- **License class**: Colors individual licenses by FCC operator class: Technician
  (blue), General (green), Amateur Extra (purple), Advanced (orange), Novice
  (gray), and Technician Plus (cyan). Grouped markers use a neutral cluster color.
- **Site Finder score**: Colors licenses from red (low) to green (high) using the
  Site Finder score of the grid cell at their location. Markers outside currently
  loaded Site Finder results are gray.
- **Link count**: Colors licenses from red (lone / few connections) to green
  (well-connected) by the number of modeled candidate links they have to other
  nearby amateur stations under the selected RF system profile.

**Site Finder score** and **Link count** colors are prepared in the background.
After changing the view, results, or color mode, markers can briefly appear gray
while their new colors are prepared. Selection, grouped-license browsing, and
node creation remain available. Score tooltips show when preparation or scoring
is still running; completed scores and link counts use the same color scale.

When no score batch is running, newly loaded terrain or land-cover data refreshes
cached amateur scores. A running batch finishes against the live data managers
and acknowledges tiles loaded during that work, avoiding repeated restarts. An
external data update during a batch can be included in that acknowledgement;
the batch is not an immutable snapshot of terrain and land cover. Changes to
settings, the network document, or data managers cancel obsolete batches.

FCC records contain public mailing addresses. Do not commit the downloaded
archive, extracted records, SQLite database, write-ahead log, or exports that
contain licensee addresses.
