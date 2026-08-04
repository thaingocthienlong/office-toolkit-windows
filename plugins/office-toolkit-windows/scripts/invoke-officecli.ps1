[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgumentList
)

$ErrorActionPreference = 'Stop'
$minimumVersion = [version]'1.0.135'
$bundledHash = '937DB176B585E874AA5BFF48D536BCE78037665CD862B5DEEFE56E79977E6588'

function Get-OfficeCliVersion([string]$Path) {
    try {
        $versionOutput = & $Path '--version' 2>&1
        if ($LASTEXITCODE -ne 0) { return $null }
        $match = [regex]::Match(($versionOutput -join "`n"), '(?<!\d)(\d+\.\d+\.\d+)(?!\d)')
        if ($match.Success) { return [version]$match.Groups[1].Value }
    } catch {
        return $null
    }
    return $null
}

$pathCommand = Get-Command officecli -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pathCommand -and (Get-OfficeCliVersion $pathCommand.Source) -ge $minimumVersion) {
    $officeCli = $pathCommand.Source
} else {
    $officeCli = Join-Path $PSScriptRoot '..\assets\vendor\xu-ly-van-phong-cli\resources\bin\officecli.exe'
    if (-not (Test-Path -LiteralPath $officeCli -PathType Leaf)) {
        throw "Bundled OfficeCLI is missing: $officeCli"
    }
    if ((Get-FileHash -LiteralPath $officeCli -Algorithm SHA256).Hash -ne $bundledHash) {
        throw "Bundled OfficeCLI SHA-256 mismatch: $officeCli"
    }
}

$ErrorActionPreference = 'Continue'
& $officeCli @ArgumentList
exit $LASTEXITCODE
