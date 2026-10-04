# Acquire constrained WorldPop tiles and publish a mirror

RidgeCast uses **WorldPop 2020 UN-adjusted constrained** population counts at
roughly 100 m resolution. These restrict population to mapped settlements and
adjust country totals to UN estimates. Keep the exact filename, for example
`usa_ppp_2020_UNadj_constrained.tif`; an unconstrained raster is a different
dataset and must not be renamed to match.

## Download country tiles

Use PowerShell 7 in a working directory containing a `tools/` folder. Download
the linked helpers below into that folder, keeping `Publish-WorldPopRelease.ps1`
and `validate_worldpop_tiff.py` together. Published Windows and documentation ZIPs
already include them in `docs/tools/`; after extracting either ZIP, open
PowerShell in its `docs/` directory to run the examples below. From a source
checkout, use the repository root.

The
[`tools/Download-WorldPop2020.ps1`](../tools/Download-WorldPop2020.ps1) script
downloads the constrained Cloud-Optimized GeoTIFFs from the
[WFP / Source Cooperative collection](https://source.coop/wfp/wp-pop-icunadj).
Specify three-letter ISO country codes:

```powershell
.\tools\Download-WorldPop2020.ps1 -Countries CAN, USA, MEX, AUS
```

Files land in `worldpop_tiles/` by default. Override the destination with
`-OutputDir`; use `-Force` to replace an existing file. Nonempty finished files
are skipped otherwise. Transfers stream to `.tmp` files, check the declared
length, and move to their final filename only after completion. Failed transfers
must be rerun; this acquisition script does not resume partial downloads.

The source URL for each country is:

```text
https://data.source.coop/wfp/wp-pop-icunadj/{iso3}/{iso3}_ppp_2020_UNadj_constrained.tif
```

Both occurrences of `{iso3}` are lowercase; `UNadj` is case-sensitive.
`worldpop_tiles/` is a staging directory, excluded from Git, rather than the
application's population cache. Keep legacy unconstrained files, including
anything in `archive-unconstrained/`, out of the upload set.

## Upload to Cloudflare R2 or another flat-file host

The [`tools/Upload-CloudflareR2.ps1`](../tools/Upload-CloudflareR2.ps1) script
uploads files to R2 using its S3 API. It streams the file and signs the request
with credentials supplied through parameters or environment variables. Set
`R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, and `R2_BUCKET` in
your shell, then upload only the constrained rasters:

```powershell
Get-ChildItem -Path .\worldpop_tiles\*_ppp_2020_UNadj_constrained.tif -File |
    .\tools\Upload-CloudflareR2.ps1 -PassThru
```

The default object key is the original filename, which is the required layout
at the bucket root. For a single country:

```powershell
.\tools\Upload-CloudflareR2.ps1 `
    -FilePath .\worldpop_tiles\usa_ppp_2020_UNadj_constrained.tif `
    -Bucket worldpop-2020 -TimeoutSeconds 3600 -PassThru
```

Increase `-TimeoutSeconds` for large transfers on slow connections. `-UseAwsCli`
delegates to an installed AWS CLI when needed. The upload script also supports
`-Key` for a prefix, but the configured mirror base URL must include that prefix.
Do not use one fixed `-Key` for a pipeline of countries: it would overwrite the
same object repeatedly.

Object keys cannot contain literal `.` or `..` slash-separated path segments;
ordinary dots in names such as `country.v1/tile.tif` are allowed. This constraint
applies to both upload methods. Native `-Metadata` values have surrounding
whitespace removed and internal whitespace collapsed to single spaces so the
sent headers agree with their signature. When using `-UseAwsCli`, unrelated AWS
session tokens are temporarily cleared and restored after success or failure.

Enable public HTTPS reads through your R2 bucket's public domain or a custom
domain. The authenticated `r2.cloudflarestorage.com` API endpoint is for uploads;
RidgeCast needs a public download URL. Preserve WorldPop attribution and
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) terms with the mirror,
including the constrained dataset citations listed by Source Cooperative.

For R2, S3, or another static host, add a **Flat GeoTIFF** population source in
**Settings → Terrain & Geodata Settings → Mirror Preferences**. Its base URL
must produce `{base}/{iso3}_ppp_2020_UNadj_constrained.tif`.

## Use the tiles locally or use the public fallback

RidgeCast tries its flat Cloudflare mirror first, then the WFP / Source
Cooperative country directory. A missing country on the project mirror falls
through automatically. To configure Source Cooperative yourself, use
**Source Cooperative country directory**, with base URL
`https://data.source.coop/wfp/wp-pop-icunadj`.

For offline use, close RidgeCast and copy the finished constrained TIFFs into
the `population/` directory beneath the active cache root shown in
**Settings → Application Preferences**, then restart. RidgeCast preloads these
files in the background. Old `*_ppp_2020.tif` files are ignored and can be removed
manually or through **Clear Population**. Do not rename them into the new format.

## Publish optional GitHub Release assets

GitHub Releases remains a configurable mirror layout. Use PowerShell 7.2+ and
Python 3.9+ (no Python packages are required), install
[GitHub CLI](https://cli.github.com/) and [7-Zip](https://www.7-zip.org/), then run
`gh auth login` with an account that can create releases in your mirror
repository. Create that repository first; it must be public for RidgeCast to
download its assets without authentication.

The [`tools/Publish-WorldPopRelease.ps1`](../tools/Publish-WorldPopRelease.ps1)
script selects finished constrained TIFFs directly from `worldpop_tiles/`,
packages each country into numbered 7z volumes, and uploads them to `v2020`:

```powershell
.\tools\Publish-WorldPopRelease.ps1 `
    -Repository YOUR-ACCOUNT/worldpop-mirror -Countries AUS, CAN -WhatIf
.\tools\Publish-WorldPopRelease.ps1 `
    -Repository YOUR-ACCOUNT/worldpop-mirror -Countries AUS, CAN
```

Omit `-Countries` to publish all matching TIFFs in the input directory. Use
`-InputDir` for another directory and `-Tag` for a different release tag.
`-WhatIf` validates the local selection and prints the plan without invoking
GitHub or 7-Zip. The script does not download missing tiles or search
subdirectories, so legacy archives and unconstrained filenames are excluded.
It runs the adjacent [`validate_worldpop_tiff.py`](../tools/validate_worldpop_tiff.py)
helper before contacting GitHub, including during `-WhatIf`. Use `-PythonPath`
if Python is not available as `python` on your PATH.

Validation accepts classic TIFF and BigTIFF in either byte order. It checks
the first image's dimensions, single float32 band, supported lossless
compression, WGS 84 coordinate keys, north-up georeferencing, roughly 100 m
resolution, and every declared pixel block's range within the file. This
catches renamed error pages, missing metadata, unsupported formats, and
truncated downloads. Source COG padding past the antimeridian is permitted.
These checks inspect metadata and storage ranges; they do not decode all
compressed TIFF pixels or prove that a renamed raster is the constrained
WorldPop dataset. Acquire the source tiles with the download script above.

Volumes default to 1900 MiB each, below GitHub's
[2 GiB per-asset limit](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas).
Use `-VolumeSizeMB` (1–2047 MiB), `-CompressionLevel` (0–9, default 5), or
`-SevenZipPath` to change packaging. The archive names are
`<iso3>_ppp_2020_UNadj_constrained.7z.001`, `.002`, and so on, including the USA;
each contains the expected TIFF at the archive root. Packaging uses temporary
disk space for all selected archives, which is removed after success or
failure. The source TIFFs are retained. The script also checks RidgeCast's
limit of 999 volumes and 4 GiB of compressed data per country, and GitHub's
limit of 1000 assets per release.
Every generated archive must have contiguous numbered volumes and pass a
complete `7z t` integrity check before any assets are uploaded. All prepared
asset sizes and the total asset count, including existing assets on the
release, are checked before creating or changing the release. GitHub does
not impose a total release-size or bandwidth quota; the 4 GiB country archive
limit comes from RidgeCast.

New releases include WorldPop attribution and a link to the source dataset
citations. They are created as drafts and published only after every upload
succeeds. A failed upload leaves the draft and any finished remote assets in
place. `-Draft` keeps a new or already-draft release unpublished; it does not
hide a previously published release. On a new release, a missing Git tag is
created from the mirror repository's default branch.

To rerun after an interruption, use the same inputs and packaging settings
with `-SkipExisting`. This skips only completed assets whose names, sizes,
and GitHub-provided SHA-256 digests match the local files. Older assets without
a digest cannot be skipped safely; use a new tag. Name collisions otherwise stop the
script. Different sizes or extra volumes from an older archive also stop it.
Use a new tag when changing data or packaging settings, or when the existing
release is immutable. The script never replaces or deletes remote assets.

For raw TIFF uploads, omit the 7-Zip dependency and use `-RawTiff`:

```powershell
.\tools\Publish-WorldPopRelease.ps1 `
    -Repository YOUR-ACCOUNT/worldpop-mirror -Countries AUS -RawTiff
```

Each raw TIFF must be smaller than 2 GiB. The script rejects mixing raw TIFFs
and country archives on the same release tag. In RidgeCast, add a **GitHub Releases**
population source with base URL
`https://github.com/YOUR-ACCOUNT/worldpop-mirror/releases/download/v2020`.
Enable **7z parts** for packaged volumes, or disable it for raw TIFFs. The
script prints this URL and the setting when the release is published.
Legacy `usa_worldpop.7z.*` archives and archives containing only an
unconstrained TIFF are not used.

## Verify in RidgeCast

Use a temporary cache root or clear only **Population**, then request population
through coverage or Site Finder. Inspect **Downloads** to confirm the selected
source and successful fetch. Confirm the constrained filename in the population
cache. For a split archive, verify every part is fetched and the expected TIFF
is extracted. Recalculate existing coverage and population-weighted site scores
after changing datasets.

See [Data, caches, mirrors, and working offline](../data-and-caching.md) for
cache locations, fallback behavior, and source layouts.
