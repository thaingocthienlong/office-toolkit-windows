[CmdletBinding()]
param(
    [string]$OutputDirectory
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$OutputDirectory = if ($OutputDirectory) { $OutputDirectory } else { Join-Path $repoRoot 'dist' }
$pluginRoot = Join-Path $repoRoot 'plugins\office-toolkit-windows'
$manifestPath = Join-Path $pluginRoot '.codex-plugin\plugin.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$packageName = "$($manifest.name)-v$($manifest.version)"
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$stageRoot = Join-Path $tempRoot ('office-toolkit-package-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $outputRoot "$packageName.zip"
$hashPath = "$zipPath.sha256"

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
New-Item -ItemType Directory -Path $stageRoot | Out-Null
try {
    foreach ($relativePath in '.agents', 'plugins', 'setup.ps1', 'README.md') {
        Copy-Item -LiteralPath (Join-Path $repoRoot $relativePath) -Destination $stageRoot -Recurse -Force
    }

    Get-ChildItem -LiteralPath $stageRoot -Recurse -Force -Directory |
        Where-Object { $_.Name -in @('__pycache__', '.venv', 'node_modules', '.cache', 'dist') } |
        Sort-Object FullName -Descending |
        Remove-Item -Recurse -Force
    Get-ChildItem -LiteralPath $stageRoot -Recurse -Force -File |
        Where-Object { $_.Extension -in @('.pyc', '.pyo') } |
        Remove-Item -Force

    $forbidden = Get-ChildItem -LiteralPath $stageRoot -Recurse -Force -File | Where-Object {
        $_.Name -in @('.env', '.env.local', 'secrets.json') -or
        $_.Name -eq 'office-toolkit-windows.zip' -or
        $_.FullName -match '\\(__pycache__|\.venv|node_modules|\.cache|dist)(\\|$)'
    }
    if ($forbidden) { throw "Package contains forbidden files: $($forbidden.FullName -join ', ')" }

    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
    try {
        Get-ChildItem -LiteralPath $stageRoot -Recurse -Force -File | ForEach-Object {
            $entryName = $_.FullName.Substring($stageRoot.Length).TrimStart('\').Replace('\', '/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $_.FullName,
                $entryName,
                [IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    } finally {
        $archive.Dispose()
    }
    $hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText($hashPath, "$hash  $([IO.Path]::GetFileName($zipPath))`r`n", [Text.UTF8Encoding]::new($false))
    Write-Host "Created $zipPath"
    Write-Host "SHA-256 $hash"
} finally {
    $resolvedStage = [IO.Path]::GetFullPath($stageRoot)
    if (-not $resolvedStage.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe package staging path: $resolvedStage"
    }
    if (Test-Path -LiteralPath $resolvedStage) { Remove-Item -LiteralPath $resolvedStage -Recurse -Force }
}
