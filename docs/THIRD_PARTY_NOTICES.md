# Third-party notices

RidgeCast depends on third-party Rust crates whose exact versions are recorded in `Cargo.lock`. Their source distributions contain their respective license terms.

## Unicode grapheme-break test data

`tests/fixtures/shortname/GraphemeBreakTest-17.0.0.txt` (SHA-256 `e2d134d2c52919bace503ebb6a551c1855fe1a1faec18478c78fff254a1793ec`) and `GraphemeBreakTest-18.0.0.txt` (SHA-256 `b0cf047ee94485bbdc846de2b902f5f8a815f6b674f9d04223cddadd91c9df31`) are unmodified Unicode Character Database files, retrieved on 2026-10-04. They are used only by the test suite and are not compiled into the application. They are © Unicode, Inc. and distributed under the [Unicode License v3](https://www.unicode.org/license.txt); see also the [Unicode terms of use](https://www.unicode.org/terms_of_use.html).

## USPS abbreviation conventions

The shortname dictionaries in `src/shortname/dictionaries/` restate factual word-to-abbreviation pairs from [USPS Publication 28](https://pe.usps.com/text/pub28/), Appendix B (state, possession and directional codes) and Appendix C1 (street suffixes), in label capitalization. No USPS text or table layout is reproduced. The selection and its review status are recorded in `src/shortname/dictionaries/sources.json`.

## Natural Earth water polygons

`resources/water/natural-earth-water.bin.gz` is derived from Natural Earth's
1:10 million ocean and lake polygons. The data is public domain and can be
modified and redistributed. RidgeCast converts the polygon coordinates into
a compressed binary mask source for terrain display. The pinned source
revision, hashes, format, and rebuild instructions are recorded in
[Natural Earth water mask provenance](reference/water-mask-provenance.md).

- [Natural Earth physical vectors](https://www.naturalearthdata.com/downloads/10m-physical-vectors/)
- [Natural Earth terms of use](https://www.naturalearthdata.com/about/terms-of-use/)

## Irregular Terrain Model

`cpp/ntia_itm.cpp` is derived from the U.S. National Telecommunications and Information Administration (NTIA), Institute for Telecommunication Sciences, `ITMDLL.cpp` release dated June 26, 2007. That code is a C++ translation of the Longley–Rice Irregular Terrain Model.

The original work was developed by U.S. Government employees and released as public-domain software in the United States. NTIA grants worldwide permission for the rights it may hold outside the United States and asks that derivative works acknowledge NTIA and describe their changes. The NTIA software is provided without warranty.

RidgeCast integrates the model through a Rust/C++ bridge and has modified the wrapper for portable calling conventions, non-Windows builds, and RAII-managed temporary storage. These changes were documented on July 28, 2026.

Authoritative project and terms:

- [NTIA ITS Irregular Terrain Model](https://github.com/NTIA/itm)
- [NTIA ITM software disclaimer and release terms](https://github.com/NTIA/itm/blob/master/LICENSE.md)

## CRC Canada complete outdoor P.1812

`cpp/third_party/crc_p1812` is from [crc-covlib revision 62e7b871e28db6aaa93ab2e3864d9f89dd147a68](https://github.com/ic-crc/crc-covlib/tree/62e7b871e28db6aaa93ab2e3864d9f89dd147a68). RidgeCast uses the outdoor P.1812-7 procedures with the ITU-advised P.1812-6 troposcatter correction. Changes on 2026-10-02 add a Rust/C++ bridge and two portability fixes (a string header and explicit constexpr lambda captures); equations remain unchanged. Source hashes and independent validation lineage are documented in [scientific model provenance](reference/scientific-models.md).

MIT License

Copyright (c) 2025 His Majesty the King in Right of Canada, as represented by the Minister of Industry through the Communications Research Centre Canada.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## ITU atmospheric radio-noise coefficients

The atmospheric-only embedded coefficient pack and Rust port derive from [ITU-R-HF revision 82017594a1c6cacfaa7e86954c4ae7b3a5825a3d](https://github.com/ITU-R-Study-Group-3/ITU-R-HF/tree/82017594a1c6cacfaa7e86954c4ae7b3a5825a3d), P372 software 14.3, developed collaboratively by ITU-R Study Group 3 participants. Its source notice permits implementing and revising the Recommendations free from copyright assertions and provides the software without warranties. RidgeCast acknowledges these contributors. Only atmospheric coefficient arrays are embedded; ionospheric data and the unrelated common header are not redistributed. The extracted pack, source hashes and implementation scope are recorded in [scientific model provenance](reference/scientific-models.md).
