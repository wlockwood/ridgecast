<#
.SYNOPSIS
    Download WorldPop 2020 UN-adjusted constrained country rasters from WFP / Source Cooperative.
.DESCRIPTION
    Streams ~100 m Cloud-Optimized GeoTIFFs to worldpop_tiles by default.
    Keeps the exact ISO3 filename required by RidgeCast. Downloads go to a
    temporary file and are published only after the transfer is complete.
.EXAMPLE
    .\tools\Download-WorldPop2020.ps1 -Countries CAN, USA, MEX
.EXAMPLE
    .\tools\Download-WorldPop2020.ps1 -Countries AUS -OutputDir .\worldpop_tiles -Force
#>
[CmdletBinding()]
param(
    # Specify 3-letter ISO country codes (e.g. -Countries "CAN", "USA", "MEX")
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z]{3}$')]
    [string[]]$Countries,

    # Local output folder
    [string]$OutputDir = ".\worldpop_tiles",

    # Overwrite if file already exists locally
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$resolvedDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
if (-not (Test-Path -LiteralPath $resolvedDir)) {
    [System.IO.Directory]::CreateDirectory($resolvedDir) | Out-Null
}

# Source Cooperative / WFP high-speed mirror base URL
$baseUrl = "https://data.source.coop/wfp/wp-pop-icunadj"

$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [System.TimeSpan]::FromHours(2)

try {
    foreach ($c in $Countries) {
        $iso = $c.Trim().ToLowerInvariant()
        $fileName = "${iso}_ppp_2020_UNadj_constrained.tif"
        $fileUrl = "$baseUrl/$iso/$fileName"
        $destPath = Join-Path -Path $resolvedDir -ChildPath $fileName
        $temporaryPath = "$destPath.tmp"

        if ((Test-Path -LiteralPath $destPath) -and -not $Force) {
            $existingSize = (Get-Item -LiteralPath $destPath).Length
            if ($existingSize -gt 0) {
                Write-Host "[$($iso.ToUpper())] Skipping $fileName (Already exists: $([math]::Round($existingSize / 1MB, 2)) MB)" -ForegroundColor DarkGray
                continue
            }
        }

        Write-Host "[$($iso.ToUpper())] Connecting to cloud edge mirror..." -ForegroundColor Cyan

        $response = $httpClient.GetAsync($fileUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()

        try {
            $response.EnsureSuccessStatusCode() | Out-Null
            $totalBytes = $response.Content.Headers.ContentLength
            $inputStream = $null
            $outputStream = $null
            try {
                $inputStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
                $outputStream = [System.IO.File]::Create($temporaryPath)
                $buffer = [byte[]]::new(1048576) # 1 MB buffer for high-throughput S3 streams
                $bytesRead = 0
                $downloadedBytes = 0
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $lastReport = [System.DateTime]::MinValue

                while (($bytesRead = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $outputStream.Write($buffer, 0, $bytesRead)
                    $downloadedBytes += $bytesRead

                    if ($totalBytes -and ([System.DateTime]::UtcNow - $lastReport).TotalMilliseconds -gt 400) {
                        $percent = [math]::Round(($downloadedBytes / $totalBytes) * 100)
                        $mbps = [math]::Round(($downloadedBytes / 1MB) / [math]::Max($stopwatch.Elapsed.TotalSeconds, 0.001), 2)

                        Write-Progress -Activity "Streaming WorldPop COG" `
                            -Status "[$($iso.ToUpper())] $fileName ($([math]::Round($downloadedBytes / 1MB, 1)) /$([math]::Round($totalBytes / 1MB, 1)) MB at $mbps MB/s)" `
                            -PercentComplete $percent
                        $lastReport = [System.DateTime]::UtcNow
                    }
                }
                if ($downloadedBytes -eq 0 -or ($null -ne $totalBytes -and $downloadedBytes -ne $totalBytes)) {
                    throw "Incomplete download for ${fileName}: received $downloadedBytes bytes, expected $totalBytes."
                }
            }
            finally {
                if ($null -ne $outputStream) { $outputStream.Dispose() }
                if ($null -ne $inputStream) { $inputStream.Dispose() }
                Write-Progress -Activity "Streaming WorldPop COG" -Completed
            }
            Move-Item -LiteralPath $temporaryPath -Destination $destPath -Force
        }
        finally {
            $response.Dispose()
            if (Test-Path -LiteralPath $temporaryPath) {
                Remove-Item -LiteralPath $temporaryPath
            }
        }

        Write-Host "[$($iso.ToUpper())] Download complete: $fileName ($([math]::Round($downloadedBytes / 1MB, 2)) MB)" -ForegroundColor Green
    }
}
finally {
    $httpClient.Dispose()
}

Write-Host "`nAll transfers complete. Files saved to: $resolvedDir" -ForegroundColor Cyan
