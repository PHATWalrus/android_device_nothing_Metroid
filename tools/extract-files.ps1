[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Source
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$listPath = Join-Path $repoRoot 'proprietary-files.txt'
$destinationRoot = Join-Path $repoRoot 'proprietary'
$sourceRoot = (Resolve-Path -LiteralPath $Source).Path

$copied = 0
foreach ($rawLine in Get-Content -LiteralPath $listPath) {
    $line = $rawLine.Trim()
    if (-not $line -or $line.StartsWith('#')) {
        continue
    }

    $parts = $line.Split('|', 2)
    if ($parts.Count -ne 2) {
        throw "Malformed proprietary-files.txt entry: $line"
    }

    $relative = $parts[0].Replace('/', [IO.Path]::DirectorySeparatorChar)
    $expectedHash = $parts[1].ToLowerInvariant()
    $sourceFile = Join-Path $sourceRoot $relative
    $destinationFile = Join-Path $destinationRoot $relative

    if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
        throw "Missing firmware file: $sourceFile"
    }

    $actualHash = (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "Hash mismatch for $sourceFile`nexpected $expectedHash`nactual   $actualHash"
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationFile) | Out-Null
    Copy-Item -LiteralPath $sourceFile -Destination $destinationFile -Force
    $copied++
}

Write-Host "Extracted and verified $copied Metroid recovery blobs."
