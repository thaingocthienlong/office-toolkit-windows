[CmdletBinding()]
param(
    [switch]$Check
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$pluginName = 'office-toolkit-windows'
$repoRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$pluginRoot = Join-Path $repoRoot 'plugins\office-toolkit-windows'
$requirements = Join-Path $pluginRoot 'requirements.lock'
$manifest = Join-Path $pluginRoot '.codex-plugin\plugin.json'
$stateRoot = Join-Path $env:LOCALAPPDATA 'Codex\office-toolkit-windows'
$venvRoot = Join-Path $stateRoot 'venv'
$venvPython = Join-Path $venvRoot 'Scripts\python.exe'
$stampPath = Join-Path $stateRoot 'install.json'

function Invoke-Checked([string]$FilePath, [string[]]$Arguments) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "$FilePath failed with exit code ${exitCode}: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function Test-PythonRuntime([string]$FilePath, [string[]]$PrefixArguments) {
    $arguments = @($PrefixArguments) + @('-c', 'import struct, sys; print(sys.version_info.major); print(sys.version_info.minor); print(struct.calcsize(chr(80))*8)')
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @arguments 2>$null
        if ($LASTEXITCODE -ne 0) { return $false }
        $values = @($output | Select-Object -Last 3 | ForEach-Object { [int]$_ })
        return ($values.Count -eq 3 -and ($values[0] -gt 3 -or ($values[0] -eq 3 -and $values[1] -ge 11)) -and $values[2] -eq 64)
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Find-PythonLauncher {
    $candidates = @()
    $py = Get-Command py.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($py) {
        $candidates += [pscustomobject]@{ Path = $py.Source; Prefix = @('-3.11') }
        $candidates += [pscustomobject]@{ Path = $py.Source; Prefix = @('-3') }
    }
    $python = Get-Command python.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($python) {
        $candidates += [pscustomobject]@{ Path = $python.Source; Prefix = @() }
    }
    foreach ($candidate in $candidates) {
        if (Test-PythonRuntime $candidate.Path $candidate.Prefix) { return $candidate }
    }
    throw 'Python 3.11+ x64 was not found. Install it, then run setup.ps1 again.'
}

function Test-LockedDependencies([string]$PythonPath, [string[]]$Pins) {
    $probe = "import importlib.metadata as m, sys; bad=[]; [(bad.append(pin) if m.version(pin.split('==',1)[0]) != pin.split('==',1)[1] else None) for pin in sys.argv[1:]]; raise SystemExit(1 if bad else 0)"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $PythonPath '-c' $probe @Pins *> $null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Normalize-Path([string]$Path) {
    $value = $Path.Trim()
    if ($value.StartsWith('\\?\')) { $value = $value.Substring(4) }
    return [IO.Path]::GetFullPath($value).TrimEnd('\')
}

if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem) {
    throw 'office-toolkit-windows supports Windows 10/11 x64 only.'
}
if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is unavailable.' }
if (-not (Test-Path -LiteralPath $requirements -PathType Leaf)) { throw "Missing requirements lock: $requirements" }
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw "Missing plugin manifest: $manifest" }

$codexCommand = Get-Command codex.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $codexCommand) { throw 'codex.cmd was not found in PATH.' }
$codex = $codexCommand.Source
Invoke-Checked $codex @('--version') | Out-Null

if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
    if ($Check) { throw "Python environment is missing: $venvRoot" }
    $launcher = Find-PythonLauncher
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    Invoke-Checked $launcher.Path (@($launcher.Prefix) + @('-m', 'venv', $venvRoot)) | Out-Null
}
if (-not (Test-PythonRuntime $venvPython @())) {
    throw "Python environment must be Python 3.11+ x64: $venvPython"
}

$pins = @(Get-Content -LiteralPath $requirements | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
if (-not (Test-LockedDependencies $venvPython $pins)) {
    if ($Check) { throw 'Locked Python dependencies are missing or have unexpected versions.' }
    Invoke-Checked $venvPython @('-m', 'pip', 'install', '--disable-pip-version-check', '--only-binary=:all:', '--requirement', $requirements) | Out-Host
    if (-not (Test-LockedDependencies $venvPython $pins)) { throw 'Locked Python dependency verification failed after installation.' }
}

$marketplaceOutput = Invoke-Checked $codex @('plugin', 'marketplace', 'list')
$marketplaceLine = $marketplaceOutput | Where-Object { $_ -match "^$([regex]::Escape($pluginName))\s+(.+)$" } | Select-Object -First 1
$marketplaceMatches = $false
if ($marketplaceLine -and $marketplaceLine -match "^$([regex]::Escape($pluginName))\s+(.+)$") {
    $marketplaceMatches = (Normalize-Path $matches[1]) -eq (Normalize-Path $repoRoot)
}

if ($marketplaceLine -and -not $marketplaceMatches) {
    if ($Check) { throw "Marketplace '$pluginName' points to a different location." }
    $oldPlugins = Invoke-Checked $codex @('plugin', 'list', '--marketplace', $pluginName)
    if (($oldPlugins -join "`n") -match "$([regex]::Escape($pluginName))@$([regex]::Escape($pluginName)) \(installed") {
        Invoke-Checked $codex @('plugin', 'remove', "$pluginName@$pluginName") | Out-Null
    }
    Invoke-Checked $codex @('plugin', 'marketplace', 'remove', $pluginName) | Out-Null
    $marketplaceLine = $null
}
if (-not $marketplaceLine) {
    if ($Check) { throw "Marketplace '$pluginName' is not registered." }
    Invoke-Checked $codex @('plugin', 'marketplace', 'add', $repoRoot) | Out-Null
}

$pluginHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
$stampMatches = $false
if (Test-Path -LiteralPath $stampPath -PathType Leaf) {
    try {
        $stamp = Get-Content -LiteralPath $stampPath -Raw | ConvertFrom-Json
        $stampMatches = ($stamp.plugin_sha256 -eq $pluginHash -and (Normalize-Path $stamp.marketplace_path) -eq (Normalize-Path $repoRoot))
    } catch {
        $stampMatches = $false
    }
}
$pluginOutput = Invoke-Checked $codex @('plugin', 'list', '--marketplace', $pluginName)
$installed = ($pluginOutput -join "`n") -match "$([regex]::Escape($pluginName))@$([regex]::Escape($pluginName)) \(installed, enabled\)"
if (-not $installed -or -not $stampMatches) {
    if ($Check) { throw "Plugin '$pluginName' is missing, disabled, or not installed from this package revision." }
    if ($installed) { Invoke-Checked $codex @('plugin', 'remove', "$pluginName@$pluginName") | Out-Null }
    Invoke-Checked $codex @('plugin', 'add', "$pluginName@$pluginName") | Out-Null
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    $stampJson = [ordered]@{
        plugin_sha256 = $pluginHash
        marketplace_path = $repoRoot
    } | ConvertTo-Json
    $temporaryStamp = "$stampPath.tmp"
    [IO.File]::WriteAllText($temporaryStamp, $stampJson, [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryStamp -Destination $stampPath -Force
}

$finalPluginOutput = Invoke-Checked $codex @('plugin', 'list', '--marketplace', $pluginName)
if (($finalPluginOutput -join "`n") -notmatch "$([regex]::Escape($pluginName))@$([regex]::Escape($pluginName)) \(installed, enabled\)") {
    throw "Plugin '$pluginName' did not reach installed, enabled state."
}

$mode = if ($Check) { 'check' } else { 'setup' }
Write-Host "office-toolkit-windows $mode passed. Open a new Codex task to load the four skills."
