<#
.SYNOPSIS
    Uploads a file to a Cloudflare R2 storage bucket using the S3 compatibility API.

.DESCRIPTION
    Uploads a local file to Cloudflare R2 using AWS Signature Version 4 (SigV4)
    over HTTP PUT via .NET HttpClient. Operates completely standalone with zero
    external dependencies (does not require AWS CLI or AWSPowerShell module).
    Optionally supports delegating to the AWS CLI via -UseAwsCli if preferred.

.PARAMETER FilePath
    Path to the local file to upload. Can be piped from Get-ChildItem or string paths.

.PARAMETER Bucket
    The Cloudflare R2 bucket name. Can also be set via $env:R2_BUCKET.

.PARAMETER Key
    The destination object key (path) inside the bucket. Defaults to the local file name.
    Literal '.' and '..' path segments are rejected for both upload methods.

.PARAMETER AccountId
    Your Cloudflare Account ID (32-character hexadecimal string).
    Can also be set via $env:R2_ACCOUNT_ID or $env:CLOUDFLARE_ACCOUNT_ID.

.PARAMETER AccessKeyId
    The R2 S3 API Access Key ID.
    Can also be set via $env:R2_ACCESS_KEY_ID or $env:AWS_ACCESS_KEY_ID.

.PARAMETER SecretAccessKey
    The R2 S3 API Secret Access Key.
    Can also be set via $env:R2_SECRET_ACCESS_KEY or $env:AWS_SECRET_ACCESS_KEY.

.PARAMETER EndpointUrl
    Custom S3 endpoint URL. Defaults to 'https://<AccountId>.r2.cloudflarestorage.com'.
    Can also be set via $env:R2_ENDPOINT_URL.

.PARAMETER Region
    S3 region identifier. Cloudflare R2 uses 'auto' by default (accepts 'us-east-1' for compatibility).

.PARAMETER ContentType
    MIME type for the uploaded object. If omitted, the script automatically infers
    it from the file extension, falling back to 'application/octet-stream'.

.PARAMETER Metadata
    Optional hashtable of user-defined metadata to attach to the object (x-amz-meta-*).
    Native uploads trim values and collapse internal whitespace for SigV4.

.PARAMETER StorageClass
    Optional S3 storage class header (e.g., 'Standard').

.PARAMETER TimeoutSeconds
    HTTP request timeout in seconds. Defaults to 600 seconds (10 minutes).

.PARAMETER UseAwsCli
    Switch to delegate the upload to the AWS CLI ('aws s3 cp') instead of the native .NET HTTP client.

.PARAMETER PassThru
    Outputs a custom PowerShell object with upload details (Bucket, Key, ETag, Size, Url, Status).

.EXAMPLE
    .\tools\Upload-CloudflareR2.ps1 -FilePath "dist\app.zip" -Bucket "my-bucket"

.EXAMPLE
    $env:R2_ACCOUNT_ID = "0123456789abcdef0123456789abcdef"
    $env:R2_ACCESS_KEY_ID = "your_access_key"
    $env:R2_SECRET_ACCESS_KEY = "your_secret_key"
    .\tools\Upload-CloudflareR2.ps1 -FilePath "worldpop_tiles\usa_ppp_2020_UNadj_constrained.tif" -Bucket "worldpop-2020"

.EXAMPLE
    Get-ChildItem -Path ./worldpop_tiles/*_ppp_2020_UNadj_constrained.tif | .\tools\Upload-CloudflareR2.ps1 -Bucket "worldpop-2020" -PassThru
#>
[CmdletBinding(DefaultParameterSetName = 'Native')]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('Path', 'FullName')]
    [string]$FilePath,

    [Parameter(Position = 1)]
    [string]$Bucket = $env:R2_BUCKET,

    [Parameter(Position = 2)]
    [string]$Key,

    [Parameter()]
    [string]$AccountId = $(if ($env:R2_ACCOUNT_ID) { $env:R2_ACCOUNT_ID } else { $env:CLOUDFLARE_ACCOUNT_ID }),

    [Parameter()]
    [string]$AccessKeyId = $(if ($env:R2_ACCESS_KEY_ID) { $env:R2_ACCESS_KEY_ID } else { $env:AWS_ACCESS_KEY_ID }),

    [Parameter()]
    [string]$SecretAccessKey = $(if ($env:R2_SECRET_ACCESS_KEY) { $env:R2_SECRET_ACCESS_KEY } else { $env:AWS_SECRET_ACCESS_KEY }),

    [Parameter()]
    [string]$EndpointUrl = $env:R2_ENDPOINT_URL,

    [Parameter()]
    [string]$Region = 'auto',

    [Parameter()]
    [string]$ContentType,

    [Parameter()]
    [hashtable]$Metadata,

    [Parameter()]
    [string]$StorageClass,

    [Parameter()]
    [int]$TimeoutSeconds = 600,

    [Parameter()]
    [switch]$UseAwsCli,

    [Parameter()]
    [switch]$PassThru
)

begin {
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest

    # Load required .NET assembly for Windows PowerShell 5.1 compatibility
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

    # Ensure Endpoint URL is populated
    if ([string]::IsNullOrWhiteSpace($EndpointUrl)) {
        if ([string]::IsNullOrWhiteSpace($AccountId)) {
            throw "Either -AccountId (or env:R2_ACCOUNT_ID) or -EndpointUrl (or env:R2_ENDPOINT_URL) must be provided."
        }
        $EndpointUrl = "https://$AccountId.r2.cloudflarestorage.com"
    }

    # Ensure credentials are provided
    if ([string]::IsNullOrWhiteSpace($AccessKeyId)) {
        throw "Cloudflare R2 Access Key ID is missing. Supply -AccessKeyId or set `$env:R2_ACCESS_KEY_ID / `$env:AWS_ACCESS_KEY_ID."
    }
    if ([string]::IsNullOrWhiteSpace($SecretAccessKey)) {
        throw "Cloudflare R2 Secret Access Key is missing. Supply -SecretAccessKey or set `$env:R2_SECRET_ACCESS_KEY / `$env:AWS_SECRET_ACCESS_KEY."
    }
    if ([string]::IsNullOrWhiteSpace($Bucket)) {
        throw "Bucket name is required. Supply -Bucket or set `$env:R2_BUCKET."
    }

    function Format-ByteSize([long]$Bytes) {
        if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
        if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
        if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
        return "$Bytes B"
    }

    function Get-FileSha256Hex([string]$Path) {
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $bytes = $hasher.ComputeHash($stream)
            return -join ($bytes | ForEach-Object { '{0:x2}' -f $_ })
        }
        finally {
            $stream.Dispose()
            $hasher.Dispose()
        }
    }

    function Get-Sha256HexFromBytes([byte[]]$Data) {
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        try {
            $bytes = $hasher.ComputeHash($Data)
            return -join ($bytes | ForEach-Object { '{0:x2}' -f $_ })
        }
        finally {
            $hasher.Dispose()
        }
    }

    function Get-HmacSha256Bytes([byte[]]$Key, [byte[]]$Data) {
        $hmac = [System.Security.Cryptography.HMACSHA256]::new($Key)
        try {
            return $hmac.ComputeHash($Data)
        }
        finally {
            $hmac.Dispose()
        }
    }

    function Get-MimeType([string]$Path) {
        $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
        $knownTypes = @{
            '.html'  = 'text/html; charset=utf-8'
            '.htm'   = 'text/html; charset=utf-8'
            '.css'   = 'text/css; charset=utf-8'
            '.js'    = 'application/javascript; charset=utf-8'
            '.mjs'   = 'application/javascript; charset=utf-8'
            '.json'  = 'application/json; charset=utf-8'
            '.xml'   = 'application/xml; charset=utf-8'
            '.txt'   = 'text/plain; charset=utf-8'
            '.md'    = 'text/markdown; charset=utf-8'
            '.csv'   = 'text/csv; charset=utf-8'
            '.png'   = 'image/png'
            '.jpg'   = 'image/jpeg'
            '.jpeg'  = 'image/jpeg'
            '.gif'   = 'image/gif'
            '.svg'   = 'image/svg+xml'
            '.webp'  = 'image/webp'
            '.tif'   = 'image/tiff'
            '.tiff'  = 'image/tiff'
            '.ico'   = 'image/x-icon'
            '.zip'   = 'application/zip'
            '.tar'   = 'application/x-tar'
            '.gz'    = 'application/gzip'
            '.pdf'   = 'application/pdf'
            '.wasm'  = 'application/wasm'
            '.bin'   = 'application/octet-stream'
            '.exe'   = 'application/vnd.microsoft.portable-executable'
        }

        if ($knownTypes.ContainsKey($ext)) {
            return $knownTypes[$ext]
        }

        try {
            $key = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($ext)
            if ($null -ne $key) {
                $regContentType = $key.GetValue('Content Type')
                $key.Dispose()
                if (-not [string]::IsNullOrWhiteSpace($regContentType)) {
                    return [string]$regContentType
                }
            }
        }
        catch {
            # Non-Windows or restricted registry access
        }

        return 'application/octet-stream'
    }

    function Format-UriPathSegment([string]$Segment) {
        $escaped = [System.Uri]::EscapeDataString($Segment)
        return $escaped -replace '\!', '%21' -replace '\*', '%2A' -replace '\(', '%28' -replace '\)', '%29' -replace "'", '%27'
    }

    function Format-CanonicalUriPath([string]$Path) {
        $clean = $Path.TrimStart('/')
        $segments = $clean.Split('/')
        $encodedSegments = foreach ($seg in $segments) {
            Format-UriPathSegment -Segment $seg
        }
        return '/' + ($encodedSegments -join '/')
    }
}

process {
    $resolvedFile = Resolve-Path -LiteralPath $FilePath -ErrorAction Stop
    $resolvedPath = $resolvedFile.Path

    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        throw "Target file does not exist or is a directory: $resolvedPath"
    }

    $fileInfo = Get-Item -LiteralPath $resolvedPath
    $fileSize = $fileInfo.Length

    # Default key to filename if unspecified
    $destinationKey = $Key
    if ([string]::IsNullOrWhiteSpace($destinationKey)) {
        $destinationKey = $fileInfo.Name
    }
    # Clean leading slashes
    $destinationKey = $destinationKey.TrimStart('/')
    # .NET normalizes these URI segments, changing the path used by SigV4.
    # Enforce the same key constraint when delegating to the AWS CLI.
    if (@($destinationKey.Split('/') | Where-Object { $_ -eq '.' -or $_ -eq '..' }).Count -gt 0) {
        throw "Object keys must not contain literal dot path segments ('.' or '..'): $destinationKey"
    }

    # Determine Content-Type
    $resolvedContentType = $ContentType
    if ([string]::IsNullOrWhiteSpace($resolvedContentType)) {
        $resolvedContentType = Get-MimeType -Path $resolvedPath
    }

    Write-Verbose "Preparing upload: '$resolvedPath' ($([string](Format-ByteSize $fileSize))) -> s3://$Bucket/$destinationKey"

    # Option 1: AWS CLI delegation if explicitly requested
    if ($UseAwsCli) {
        if (-not (Get-Command 'aws' -ErrorAction SilentlyContinue)) {
            throw "AWS CLI command ('aws') was not found on PATH. Install AWS CLI or omit -UseAwsCli to use the native .NET HTTP uploader."
        }

        $s3Uri = "s3://$Bucket/$destinationKey"
        Write-Host "Uploading '$resolvedPath' to $s3Uri via AWS CLI..." -ForegroundColor Cyan

        $envBackup = @{
            AWS_ACCESS_KEY_ID     = $env:AWS_ACCESS_KEY_ID
            AWS_SECRET_ACCESS_KEY = $env:AWS_SECRET_ACCESS_KEY
            AWS_DEFAULT_REGION    = $env:AWS_DEFAULT_REGION
            AWS_SESSION_TOKEN     = $env:AWS_SESSION_TOKEN
            AWS_SECURITY_TOKEN    = $env:AWS_SECURITY_TOKEN
        }
        $metadataFile = $null

        try {
            $env:AWS_ACCESS_KEY_ID = $AccessKeyId
            $env:AWS_SECRET_ACCESS_KEY = $SecretAccessKey
            $env:AWS_DEFAULT_REGION = $Region
            # R2 uses permanent credentials; AWS CLI also recognizes the
            # legacy token variable, so isolate both from an AWS STS session.
            $env:AWS_SESSION_TOKEN = $null
            $env:AWS_SECURITY_TOKEN = $null

            $cliArgs = @('s3', 'cp', $resolvedPath, $s3Uri, '--endpoint-url', $EndpointUrl)
            if ($resolvedContentType) {
                $cliArgs += @('--content-type', $resolvedContentType)
            }
            if ($StorageClass) {
                $cliArgs += @('--storage-class', $StorageClass)
            }
            if ($null -ne $Metadata -and $Metadata.Count -gt 0) {
                $cliMetadata = @{}
                foreach ($metaKey in $Metadata.Keys) {
                    $normalizedMetaKey = [string]$metaKey -replace '^x-amz-meta-', ''
                    $cliMetadata[$normalizedMetaKey] = [string]$Metadata[$metaKey]
                }
                # A JSON file avoids shorthand comma parsing and native-shell
                # quote handling, including on Windows PowerShell 5.1.
                $metadataJson = $cliMetadata | ConvertTo-Json -Compress
                # AWS CLI reads parameter files using the system locale.
                # ASCII JSON escapes preserve Unicode on every locale.
                $metadataJson = [regex]::Replace($metadataJson, '[^\x00-\x7f]', {
                    param($match)
                    '\u{0:x4}' -f [int][char]$match.Value
                })
                $metadataFile = [IO.Path]::GetTempFileName()
                [IO.File]::WriteAllText($metadataFile, $metadataJson, [Text.UTF8Encoding]::new($false))
                $cliArgs += @('--metadata', "file://$metadataFile")
            }

            & aws @cliArgs
            if ($LASTEXITCODE -ne 0) {
                throw "AWS CLI upload failed with exit code $LASTEXITCODE."
            }
        }
        finally {
            $env:AWS_ACCESS_KEY_ID = $envBackup.AWS_ACCESS_KEY_ID
            $env:AWS_SECRET_ACCESS_KEY = $envBackup.AWS_SECRET_ACCESS_KEY
            $env:AWS_DEFAULT_REGION = $envBackup.AWS_DEFAULT_REGION
            $env:AWS_SESSION_TOKEN = $envBackup.AWS_SESSION_TOKEN
            $env:AWS_SECURITY_TOKEN = $envBackup.AWS_SECURITY_TOKEN
            if ($null -ne $metadataFile) {
                Remove-Item -LiteralPath $metadataFile -Force
            }
        }

        if ($PassThru) {
            [PSCustomObject]@{
                Bucket      = $Bucket
                Key         = $destinationKey
                Size        = $fileSize
                ContentType = $resolvedContentType
                EndpointUrl = $EndpointUrl
                Method      = 'AWS-CLI'
                StatusCode  = 200
            }
        }
        return
    }

    # Option 2: Native S3 SigV4 HTTP PUT upload via .NET HttpClient
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Verbose "Computing SHA256 checksum of '$resolvedPath'..."
    $contentSha256 = Get-FileSha256Hex -Path $resolvedPath
    Write-Verbose "Payload SHA256: $contentSha256"

    # URL & Canonical Path setup
    $endpointUri = [System.Uri]::new($EndpointUrl)
    $hostName = $endpointUri.Authority

    # S3 path-style URL: /<bucket>/<key>
    $canonicalUri = Format-CanonicalUriPath -Path "$Bucket/$destinationKey"
    $requestUrl = "$($endpointUri.Scheme)://${hostName}${canonicalUri}"
    $canonicalQuery = ""

    # Timestamp setup (ISO 8601 basic in UTC)
    $utcNow = [DateTime]::UtcNow
    $amzDate = $utcNow.ToString('yyyyMMddTHHmmssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    $dateStamp = $utcNow.ToString('yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture)

    # Build Header Dictionary for SigV4
    $signHeaders = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $signHeaders['host'] = $hostName
    $signHeaders['x-amz-content-sha256'] = $contentSha256
    $signHeaders['x-amz-date'] = $amzDate

    if (-not [string]::IsNullOrWhiteSpace($StorageClass)) {
        $signHeaders['x-amz-storage-class'] = $StorageClass
    }

    if ($null -ne $Metadata) {
        foreach ($metaKey in $Metadata.Keys) {
            $normalizedMetaKey = [string]$metaKey
            if (-not $normalizedMetaKey.StartsWith('x-amz-meta-', [System.StringComparison]::OrdinalIgnoreCase)) {
                $normalizedMetaKey = "x-amz-meta-$normalizedMetaKey"
            }
            $signHeaders[$normalizedMetaKey.ToLowerInvariant()] = [string]$Metadata[$metaKey]
        }
    }

    # Sort headers alphabetically for Canonical Request
    $sortedHeaderKeys = $signHeaders.Keys | Sort-Object
    $canonicalHeaders = ""
    foreach ($hKey in $sortedHeaderKeys) {
        $lowerKey = $hKey.ToLowerInvariant()
        # SigV4 canonical values trim and collapse sequential whitespace.
        # Retain that value so the transmitted headers match the signature.
        $headerVal = [regex]::Replace($signHeaders[$hKey].Trim(), '\s+', ' ')
        $signHeaders[$hKey] = $headerVal
        $canonicalHeaders += "${lowerKey}:$headerVal`n"
    }
    $signedHeaders = ($sortedHeaderKeys | ForEach-Object { $_.ToLowerInvariant() }) -join ';'

    # Canonical Request
    $canonicalRequest = "PUT`n$canonicalUri`n$canonicalQuery`n$canonicalHeaders`n$signedHeaders`n$contentSha256"
    $hashedCanonicalRequest = Get-Sha256HexFromBytes ([System.Text.Encoding]::UTF8.GetBytes($canonicalRequest))

    # String to Sign
    $credentialScope = "$dateStamp/$Region/s3/aws4_request"
    $stringToSign = "AWS4-HMAC-SHA256`n$amzDate`n$credentialScope`n$hashedCanonicalRequest"

    # Derive SigV4 Signing Key
    $kSecret = [System.Text.Encoding]::UTF8.GetBytes("AWS4$SecretAccessKey")
    $kDate = Get-HmacSha256Bytes -Key $kSecret -Data ([System.Text.Encoding]::UTF8.GetBytes($dateStamp))
    $kRegion = Get-HmacSha256Bytes -Key $kDate -Data ([System.Text.Encoding]::UTF8.GetBytes($Region))
    $kService = Get-HmacSha256Bytes -Key $kRegion -Data ([System.Text.Encoding]::UTF8.GetBytes('s3'))
    $kSigning = Get-HmacSha256Bytes -Key $kService -Data ([System.Text.Encoding]::UTF8.GetBytes('aws4_request'))

    # Calculate Signature
    $signatureBytes = Get-HmacSha256Bytes -Key $kSigning -Data ([System.Text.Encoding]::UTF8.GetBytes($stringToSign))
    $signature = -join ($signatureBytes | ForEach-Object { '{0:x2}' -f $_ })

    # Assemble Authorization Header
    $authorizationHeader = "AWS4-HMAC-SHA256 Credential=$AccessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"

    # Prepare HTTP Request
    $httpClient = [System.Net.Http.HttpClient]::new()
    $httpClient.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)

    $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Put, $requestUrl)
    foreach ($hKey in $sortedHeaderKeys) {
        [void]$request.Headers.TryAddWithoutValidation($hKey, $signHeaders[$hKey])
    }
    [void]$request.Headers.TryAddWithoutValidation('Authorization', $authorizationHeader)

    # Open file stream for streaming upload (avoids buffering whole file into RAM)
    $fileStream = [System.IO.File]::OpenRead($resolvedPath)
    try {
        $content = [System.Net.Http.StreamContent]::new($fileStream)
        if (-not [string]::IsNullOrWhiteSpace($resolvedContentType)) {
            [void]$content.Headers.TryAddWithoutValidation('Content-Type', $resolvedContentType)
        }
        $request.Content = $content

        Write-Host "Uploading '$($fileInfo.Name)' ($(Format-ByteSize $fileSize)) to s3://$Bucket/$destinationKey..." -ForegroundColor Cyan
        $response = $httpClient.SendAsync($request).GetAwaiter().GetResult()
        $stopwatch.Stop()

        if (-not $response.IsSuccessStatusCode) {
            $errorBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $errorDetail = ""
            try {
                [xml]$xml = $errorBody
                if ($null -ne $xml.Error) {
                    $code = $xml.Error.Code
                    $msg = $xml.Error.Message
                    $errorDetail = " [${code}: $msg]"
                }
            }
            catch {
                $errorDetail = " - $errorBody"
            }

            throw "Failed to upload to Cloudflare R2 (HTTP $([int]$response.StatusCode) $($response.StatusCode)):$errorDetail"
        }

        # Retrieve ETag header if available
        $etag = ""
        if ($response.Headers.ETag) {
            $etag = $response.Headers.ETag.ToString().Trim('"')
        }
        elseif ($response.Headers.Contains('ETag')) {
            $etag = ($response.Headers.GetValues('ETag') -join '').Trim('"')
        }

        $elapsedSeconds = [Math]::Max(0.01, $stopwatch.Elapsed.TotalSeconds)
        $speedFormatted = Format-ByteSize ([long]($fileSize / $elapsedSeconds))

        Write-Host "Upload complete in $([Math]::Round($elapsedSeconds, 2))s ($speedFormatted/s). ETag: $etag" -ForegroundColor Green

        if ($PassThru) {
            [PSCustomObject]@{
                Bucket      = $Bucket
                Key         = $destinationKey
                ETag        = $etag
                Size        = $fileSize
                ContentType = $resolvedContentType
                Url         = $requestUrl
                StatusCode  = [int]$response.StatusCode
            }
        }
    }
    finally {
        $fileStream.Dispose()
        $request.Dispose()
        $httpClient.Dispose()
    }
}
