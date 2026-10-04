<#
.SYNOPSIS
    Package constrained WorldPop 2020 tiles and publish them as GitHub Release assets.
.DESCRIPTION
    Requires PowerShell 7.2+, Python 3.9+, an existing GitHub repository, and an authenticated
    GitHub CLI (gh auth login). Numbered 7z volumes are the default; -RawTiff
    uploads the original TIFFs instead. Only exact constrained filenames in
    InputDir are selected, without searching subdirectories.

    New releases stay drafts until all uploads succeed. Existing assets are
    never replaced. -SkipExisting requires matching sizes and SHA-256 digests
    from GitHub. Use a new tag when changing input data
    or archive settings. -WhatIf validates inputs and prints the plan without
    running gh or 7z, creating files, or contacting GitHub.
.EXAMPLE
    .\tools\Publish-WorldPopRelease.ps1 -Repository YOUR-ACCOUNT/worldpop-mirror -Countries AUS, CAN
.EXAMPLE
    .\tools\Publish-WorldPopRelease.ps1 -Repository YOUR-ACCOUNT/worldpop-mirror -WhatIf
.EXAMPLE
    .\tools\Publish-WorldPopRelease.ps1 -Repository YOUR-ACCOUNT/worldpop-mirror -RawTiff -SkipExisting
#>
#requires -Version 7.2
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$')]
    [string]$Repository,

    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._/-]*$')]
    [string]$Tag = 'v2020',

    [string]$InputDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'worldpop_tiles'),

    [ValidatePattern('^[A-Za-z]{3}$')]
    [string[]]$Countries,

    [switch]$RawTiff,

    # 7z's m suffix uses MiB. Stay comfortably below GitHub's 2 GiB limit.
    [ValidateRange(1, 2047)]
    [int]$VolumeSizeMB = 1900,

    [ValidateRange(0, 9)]
    [int]$CompressionLevel = 5,

    [string]$SevenZipPath = '7z',

    # Python's standard library validates TIFF metadata without loading pixels.
    [string]$PythonPath = 'python',

    [switch]$SkipExisting,

    # Keep a new or already-draft release unpublished after uploading.
    [switch]$Draft,

    [ValidateNotNullOrEmpty()]
    [string]$Title = 'WorldPop 2020 UN-adjusted constrained'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Check native exit codes ourselves, including an expected missing release.
$PSNativeCommandUseErrorActionPreference = $false
$githubRepository = "github.com/$Repository"

function Invoke-GitHub([string[]]$Arguments, [switch]$AllowNotFound) {
    $result = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $resultText = ($result | ForEach-Object { "$_" }) -join "`n"
    if ($exitCode -ne 0) {
        if ($AllowNotFound -and $resultText.Trim() -eq 'release not found') { return $null }
        throw "gh $($Arguments[0]) failed (exit $exitCode): $resultText"
    }
    return $resultText
}

$directory = Get-Item -LiteralPath $InputDir
if (-not $directory.PSIsContainer) { throw "InputDir must be a directory: $InputDir" }
$tiles = if ($Countries) {
    foreach ($country in ($Countries | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique)) {
        Get-Item -LiteralPath (Join-Path $directory.FullName "${country}_ppp_2020_UNadj_constrained.tif")
    }
}
else {
    Get-ChildItem -LiteralPath $directory.FullName -File |
        Where-Object { $_.Name -cmatch '^[a-z]{3}_ppp_2020_UNadj_constrained\.tif$' } |
        Sort-Object Name
}
$tiles = @($tiles)
if ($tiles.Count -eq 0) { throw "No constrained WorldPop TIFFs found in $($directory.FullName)." }
if ($Tag.Contains('..') -or @($Tag.Split('/') | Where-Object {
    $_.Length -eq 0 -or $_.StartsWith('.') -or $_.EndsWith('.') -or $_.EndsWith('.lock')
}).Count -gt 0) {
    throw "Invalid Git release tag: $Tag"
}
if (-not (Get-Command $PythonPath -ErrorAction SilentlyContinue)) {
    throw 'Python 3.9+ is required for TIFF compatibility checks. Install it or supply -PythonPath.'
}
$validator = Join-Path $PSScriptRoot 'validate_worldpop_tiff.py'
foreach ($tile in $tiles) {
    if ($tile.PSIsContainer -or $tile.Length -eq 0 -or
        $tile.Name -cnotmatch '^[a-z]{3}_ppp_2020_UNadj_constrained\.tif$') {
        throw "Expected a nonempty constrained WorldPop TIFF: $($tile.FullName)"
    }
    if ($RawTiff -and $tile.Length -ge 2GB) {
        throw "$($tile.Name) exceeds GitHub's raw asset size limit. Omit -RawTiff to split it into 7z volumes."
    }
    $validation = & $PythonPath $validator $tile.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Incompatible WorldPop TIFF $($tile.Name): $($validation -join "`n")"
    }
    Write-Verbose ($validation -join "`n")
}

$format = if ($RawTiff) { 'raw TIFFs' } else { "7z volumes of at most $VolumeSizeMB MiB" }
Write-Host "Release ${Repository}@${Tag}: $($tiles.Count) country tile(s), $format."
foreach ($tile in $tiles) { Write-Host "  $($tile.Name) ($($tile.Length) bytes)" }
if (-not $PSCmdlet.ShouldProcess("${Repository}@${Tag}", "Prepare and upload $format; publish unless -Draft")) {
    return
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) was not found. Install it and run gh auth login.'
}
if (-not $RawTiff) {
    $sevenZip = Get-Command $SevenZipPath -ErrorAction SilentlyContinue
    # Windows Store aliases may be present even when they cannot be launched.
    if ($SevenZipPath -eq '7z' -and $IsWindows -and
        (Test-Path -LiteralPath 'C:\Program Files\7-Zip\7z.exe')) {
        $SevenZipPath = 'C:\Program Files\7-Zip\7z.exe'
    }
    elseif ($null -eq $sevenZip) {
        throw '7-Zip was not found. Install it, supply -SevenZipPath, or use -RawTiff.'
    }
    else { $SevenZipPath = $sevenZip.Source }
}

Invoke-GitHub @('repo', 'view', $githubRepository, '--json', 'nameWithOwner') | Out-Null
$encodedTag = [Uri]::EscapeDataString($Tag)
$releaseText = Invoke-GitHub -Arguments @('release', 'view', $Tag, '--repo', $githubRepository, '--json', 'databaseId,isDraft,isImmutable') -AllowNotFound
$release = if ($null -ne $releaseText) { $releaseText | ConvertFrom-Json } else { $null }
$existingAssets = @()
if ($null -ne $release) {
    if ($release.isImmutable) {
        throw 'This release is immutable. Use a new -Tag to upload tiles.'
    }
    $pages = Invoke-GitHub @('api', "repos/$Repository/releases/$($release.databaseId)/assets", '--hostname', 'github.com', '--paginate', '--slurp') | ConvertFrom-Json
    $existingAssets = @(foreach ($page in $pages) { foreach ($asset in $page) { $asset } })
}
$oppositeFormat = if ($RawTiff) { '^[a-z]{3}_ppp_2020_UNadj_constrained\.7z\.[0-9]+$' }
                  else { '^[a-z]{3}_ppp_2020_UNadj_constrained\.tif$' }
if (@($existingAssets | Where-Object { $_.name -cmatch $oppositeFormat }).Count -gt 0) {
    throw 'Cannot mix raw TIFFs and 7z country archives on one release. Use a new -Tag or the existing format.'
}

$temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$workingDir = Join-Path $temporaryRoot ('worldpop-release-' + [guid]::NewGuid().ToString('N'))
try {
    $assets = [Collections.Generic.List[IO.FileInfo]]::new()
    if ($RawTiff) {
        foreach ($tile in $tiles) { $assets.Add($tile) }
    }
    else {
        [void][IO.Directory]::CreateDirectory($workingDir)
        foreach ($tile in $tiles) {
            $stem = [IO.Path]::GetFileNameWithoutExtension($tile.Name)
            $archive = Join-Path $workingDir "$stem.7z"
            Write-Host "Packaging $($tile.Name)..."
            # Pass only the basename from its directory to keep the TIFF at archive root.
            Push-Location -LiteralPath $tile.DirectoryName
            try {
                & $SevenZipPath a -t7z "-mx=$CompressionLevel" "-v${VolumeSizeMB}m" -y $archive -- $tile.Name | Out-Host
                if ($LASTEXITCODE -ne 0) { throw "7z failed for $($tile.Name) (exit $LASTEXITCODE)." }
            }
            finally { Pop-Location }
            $parts = @(Get-ChildItem -LiteralPath $workingDir -File |
                Where-Object { $_.Name -cmatch "^$([regex]::Escape($stem))\.7z\.[0-9]+$" } |
                Sort-Object Name)
            if ($parts.Count -eq 0 -or $parts[0].Name -cne "$stem.7z.001") {
                throw "7z did not produce the expected numbered volumes for $($tile.Name)."
            }
            if ($parts.Count -gt 999 -or ($parts | Measure-Object -Property Length -Sum).Sum -gt 4GB) {
                throw "Archive for $($tile.Name) exceeds RidgeCast's 999-volume or 4 GiB download limit."
            }
            for ($index = 0; $index -lt $parts.Count; $index++) {
                $expectedName = '{0}.7z.{1:000}' -f $stem, ($index + 1)
                if ($parts[$index].Name -cne $expectedName) {
                    throw "Archive volumes are not contiguous: expected $expectedName."
                }
            }
            # Test the complete volume set, including the archived TIFF's CRC.
            & $SevenZipPath t $parts[0].FullName -y | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "7z integrity test failed for $($tile.Name) (exit $LASTEXITCODE)." }
            foreach ($part in $parts) { $assets.Add($part) }
        }
    }

    $uploads = [Collections.Generic.List[IO.FileInfo]]::new()
    foreach ($asset in $assets) {
        if ($asset.Length -eq 0 -or $asset.Length -ge 2GB) {
            throw "Invalid release asset size for $($asset.Name): $($asset.Length) bytes."
        }
        $matching = @($existingAssets | Where-Object { $_.name -ceq $asset.Name })
        if ($matching.Count -gt 0) {
            if (-not $SkipExisting) { throw "Asset $($asset.Name) already exists. Use -SkipExisting for unchanged inputs or a new -Tag." }
            if ($matching[0].size -ne $asset.Length) {
                throw "Existing asset $($asset.Name) has a different size. Use a new -Tag for changed inputs or archive settings."
            }
            if (-not $matching[0].PSObject.Properties['digest'] -or
                $matching[0].digest -cnotmatch '^sha256:[0-9a-f]{64}$') {
                throw "Existing asset $($asset.Name) has no verifiable SHA-256 checksum. Use a new -Tag."
            }
            if (-not $matching[0].PSObject.Properties['state'] -or $matching[0].state -ne 'uploaded') {
                throw "Existing asset $($asset.Name) is not a completed upload. Use a new -Tag."
            }
            $checksum = 'sha256:' + (Get-FileHash -LiteralPath $asset.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($matching[0].digest -cne $checksum) {
                throw "Existing asset $($asset.Name) has a different SHA-256 checksum. Use a new -Tag."
            }
            Write-Host "Skipping existing asset $($asset.Name) (size and SHA-256 checksum match)."
        }
        else { $uploads.Add($asset) }
    }
    # Extra volumes from an older archive could otherwise corrupt the download.
    foreach ($tile in $tiles) {
        $stem = [IO.Path]::GetFileNameWithoutExtension($tile.Name)
        $oldParts = @($existingAssets | Where-Object { $_.name -cmatch "^$([regex]::Escape($stem))\.7z\.[0-9]+$" })
        foreach ($oldPart in $oldParts) {
            if (-not $RawTiff -and $oldPart.name -cnotin $assets.Name) {
                throw "Release contains an extra archive volume $($oldPart.name). Use a new -Tag."
            }
        }
    }
    if ($existingAssets.Count + $uploads.Count -gt 1000) {
        throw 'The upload would exceed GitHub''s 1000 assets per release. Split countries across release tags.'
    }

    if ($null -eq $release) {
        if (-not $RawTiff) { $modeNote = 'Enable 7z parts for this GitHub Release source in RidgeCast.' }
        else { $modeNote = 'Disable 7z parts for this GitHub Release source in RidgeCast.' }
        # Use a file to preserve multiline attribution exactly across native invocation.
        [void][IO.Directory]::CreateDirectory($workingDir)
        $notesFile = Join-Path $workingDir 'release-notes.md'
        $notes = @"
WorldPop 2020 UN-adjusted constrained population counts (~100 m), mirrored for RidgeCast.

Source and dataset citations: https://source.coop/wfp/wp-pop-icunadj
Attribution: WorldPop and the contributors credited by the source collection.
License: Creative Commons Attribution 4.0, https://creativecommons.org/licenses/by/4.0/
The population values are unchanged; archives only repackage the source TIFFs.

$modeNote
"@
        [IO.File]::WriteAllText($notesFile, $notes, [Text.UTF8Encoding]::new($false))
        Invoke-GitHub @('release', 'create', $Tag, '--repo', $githubRepository, '--title', $Title, '--notes-file', $notesFile, '--draft', '--latest=false') | Out-Host
    }
    foreach ($asset in $uploads) {
        Write-Host "Uploading $($asset.Name)..."
        # gh treats # in a file argument as a label separator; pass the basename.
        Push-Location -LiteralPath $asset.DirectoryName
        try {
            Invoke-GitHub @('release', 'upload', $Tag, $asset.Name, '--repo', $githubRepository) | Out-Host
        }
        finally { Pop-Location }
    }
    if (-not $Draft -and ($null -eq $release -or $release.isDraft)) {
        Invoke-GitHub @('release', 'edit', $Tag, '--repo', $githubRepository, '--draft=false', '--latest=false') | Out-Host
    }
    Write-Host "Release: https://github.com/$Repository/releases/tag/$encodedTag"
    if ($Draft -and ($null -eq $release -or $release.isDraft)) {
        Write-Host 'Release remains a draft; publish it before configuring a public mirror.'
    }
    else {
        Write-Host "RidgeCast GitHub Release base URL: https://github.com/$Repository/releases/download/$encodedTag"
        Write-Host "7z parts: $(-not $RawTiff)"
    }
}
finally {
    if ((Test-Path -LiteralPath $workingDir) -and
        [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($workingDir)) -eq $temporaryRoot.TrimEnd('\', '/') -and
        [IO.Path]::GetFileName($workingDir).StartsWith('worldpop-release-')) {
        Remove-Item -LiteralPath $workingDir -Recurse -Force
    }
}
