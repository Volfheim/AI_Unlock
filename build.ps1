param(
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath($PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Split-Path -Parent $root) 'AI_Unlock_v4.5.zip'
} else {
    $OutputPath = [IO.Path]::GetFullPath($OutputPath)
}

$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

if ($OutputPath.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Output ZIP must be outside the module source directory: $OutputPath"
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-RelativeArchivePath {
    param([string]$Path)

    $relative = $Path.Substring($root.Length).TrimStart([char[]]@('\', '/'))
    return $relative.Replace('\', '/')
}

function Add-FileToArchive {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$Path
    )

    $entryName = Get-RelativeArchivePath $Path
    $entry = $Archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $sourceStream = [IO.File]::OpenRead($Path)
    $archiveStream = $entry.Open()
    try {
        $sourceStream.CopyTo($archiveStream)
    } finally {
        $archiveStream.Dispose()
        $sourceStream.Dispose()
    }
}

$sourceRoots = @(
    'META-INF',
    'action.sh',
    'customize.sh',
    'module.prop',
    'scripts',
    'system'
)

$files = foreach ($sourceRoot in $sourceRoots) {
    $path = Join-Path $root $sourceRoot
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required module path is missing: $sourceRoot"
    }

    $item = Get-Item -LiteralPath $path
    if ($item.PSIsContainer) {
        Get-ChildItem -LiteralPath $path -File -Recurse
    } else {
        $item
    }
}

$files = @($files | Sort-Object { Get-RelativeArchivePath $_.FullName })
$archivePaths = @($files | ForEach-Object { Get-RelativeArchivePath $_.FullName })
if (($archivePaths | Select-Object -Unique).Count -ne $archivePaths.Count) {
    throw 'Duplicate archive paths detected.'
}

if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Force
}

$archive = [System.IO.Compression.ZipFile]::Open(
    $OutputPath,
    [System.IO.Compression.ZipArchiveMode]::Create
)
try {
    foreach ($file in $files) {
        Add-FileToArchive -Archive $archive -Path $file.FullName
    }
} finally {
    $archive.Dispose()
}

$verification = [System.IO.Compression.ZipFile]::OpenRead($OutputPath)
try {
    $actualPaths = @($verification.Entries | ForEach-Object { $_.FullName })
    $forbidden = @($actualPaths | Where-Object {
        $_ -match '(^|/)(tests|state)(/|$)' -or
        $_ -eq 'service.sh' -or
        $_ -eq 'updateJson' -or
        $_ -match '\.part$'
    })
    if ($forbidden.Count -gt 0) {
        throw "Forbidden files entered the ZIP: $($forbidden -join ', ')"
    }

    foreach ($requiredPath in $archivePaths) {
        if ($actualPaths -notcontains $requiredPath) {
            throw "Archive verification failed; missing: $requiredPath"
        }
    }
} finally {
    $verification.Dispose()
}

$hash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
Write-Output "Built: $OutputPath"
Write-Output "Files: $($archivePaths.Count)"
Write-Output "SHA256: $hash"
