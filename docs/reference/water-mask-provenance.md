# Natural Earth water mask provenance

RidgeCast embeds `resources/water/natural-earth-water.bin.gz`, derived from
Natural Earth's 1:10 million ocean and lake polygons, including polygon holes
for islands. The application uses the mask offline to make water transparent
in the terrain overlay. It does not change elevation, propagation, coverage,
land-cover classes, or Site Finder scores.

Natural Earth is public domain. Its cartographic data is generalized: small
ponds, narrow rivers, and shoreline detail may be absent. Cached NLCD classes
take precedence where available.

- [Ocean and lake data](https://www.naturalearthdata.com/downloads/10m-physical-vectors/)
- [Terms of use](https://www.naturalearthdata.com/about/terms-of-use/)
- [Pinned source repository](https://github.com/nvkelso/natural-earth-vector/tree/ca96624a56bd078437bca8184e78163e5039ad19/geojson)

## Pinned inputs and output

The source version is pinned to Natural Earth repository revision
`ca96624a56bd078437bca8184e78163e5039ad19`. These SHA-256 hashes are recorded
in the RidgeCast source checkout's `resources/water/sources.json`:

| File | SHA-256 |
| --- | --- |
| `ne_10m_ocean.geojson` | `f9696a1337c746a0f6c8c13bc60d0f230d2ef8d105198d5657726c8f8e763fc2` |
| `ne_10m_lakes.geojson` | `2d036f53dedec578001c5c30c2959ee7d4eebc1306900fa4367c49929ec8f2d9` |
| `natural-earth-water.bin.gz` | `8ea1df2ec955a6029971ae33822b6090a260133bc7ffbfef71a476d7589736f5` |

## Rebuild and binary format

From the root of a RidgeCast source checkout, run
`python tools/build_water_mask.py`. The script downloads its pinned inputs
only when explicitly run and records the source and output hashes in
`resources/water/sources.json`. Released application and documentation packages
contain the finished provenance; rebuilding requires the source checkout.

The gzip payload starts with `RCWATER1`, then a little-endian `u32` polygon
count. Each polygon contains a `u32` ring count; each ring has a `u32` point
count followed by longitude/latitude pairs as little-endian `f32` values.
Rings are closed and use even-odd filling to preserve islands.
