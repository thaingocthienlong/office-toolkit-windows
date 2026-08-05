[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$setup = Join-Path $repoRoot 'setup.ps1'
$pluginRoot = Join-Path $repoRoot 'plugins\office-toolkit-windows'
$wrapper = Join-Path $pluginRoot 'scripts\invoke-officecli.ps1'
$pipeline = Join-Path $pluginRoot 'skills\pdf-scan-to-docx\scripts\pipeline.py'
$stateRoot = Join-Path $env:LOCALAPPDATA 'Codex\office-toolkit-windows'
$python = Join-Path $stateRoot 'venv\Scripts\python.exe'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testRoot = Join-Path $tempRoot ('office-toolkit-smoke-' + [guid]::NewGuid().ToString('N'))

function Invoke-NativeChecked([string]$FilePath, [string[]]$Arguments) {
    $output = & $FilePath @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "$FilePath failed with exit code ${LASTEXITCODE}: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function Invoke-PowerShellChecked([string]$ScriptPath, [string[]]$Arguments) {
    $nativeArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + @($Arguments)
    return Invoke-NativeChecked 'powershell.exe' $nativeArguments
}

function Assert-NativeFailure([string]$FilePath, [string[]]$Arguments, [string]$ExpectedText) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -eq 0) { throw "Expected failure from $FilePath" }
    if (($output -join "`n") -notmatch [regex]::Escape($ExpectedText)) {
        throw "Failure did not contain '$ExpectedText': $($output -join [Environment]::NewLine)"
    }
}

New-Item -ItemType Directory -Path $testRoot | Out-Null
$originalPath = $env:PATH
try {
    & $setup
    & $setup
    & $setup -Check

    if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw "Setup did not create $python" }
    $pluginList = Invoke-NativeChecked 'codex.cmd' @('plugin', 'list', '--marketplace', 'office-toolkit-windows')
    if (($pluginList -join "`n") -notmatch 'office-toolkit-windows@office-toolkit-windows \(installed, enabled\)') {
        throw 'Codex does not report the plugin as installed and enabled'
    }

    $bundled = Join-Path $pluginRoot 'assets\vendor\xu-ly-van-phong-cli\resources\bin\officecli.exe'
    $pathCli = Join-Path $testRoot 'path-officecli'
    New-Item -ItemType Directory -Path $pathCli | Out-Null
    Copy-Item -LiteralPath $bundled -Destination (Join-Path $pathCli 'officecli.exe')
    $env:PATH = "$pathCli;$originalPath"
    $version = Invoke-PowerShellChecked $wrapper @('--version')
    if (($version -join "`n") -notmatch '1\.0\.135') { throw 'Supported PATH OfficeCLI was not usable' }

    $oldCli = Join-Path $testRoot 'old-officecli'
    New-Item -ItemType Directory -Path $oldCli | Out-Null
    [IO.File]::WriteAllText((Join-Path $oldCli 'officecli.cmd'), "@echo off`r`necho officecli 1.0.0`r`n")
    $env:PATH = "$oldCli;$originalPath"
    $version = Invoke-PowerShellChecked $wrapper @('--version')
    if (($version -join "`n") -notmatch '1\.0\.135') { throw 'Bundled OfficeCLI fallback was not usable' }
    $env:PATH = $originalPath

    $officeRoot = Join-Path $testRoot 'office'
    New-Item -ItemType Directory -Path $officeRoot | Out-Null
    foreach ($extension in 'docx', 'pptx', 'xlsx') {
        $document = Join-Path $officeRoot "smoke.$extension"
        try {
            Invoke-PowerShellChecked $wrapper @('create', $document) | Out-Null
            Invoke-PowerShellChecked $wrapper @('get', $document, '/', '--json') | Out-Null
            Invoke-PowerShellChecked $wrapper @('validate', $document, '--json') | Out-Null
            if (-not (Test-Path -LiteralPath $document -PathType Leaf)) { throw "OfficeCLI did not create $document" }
        } finally {
            if (Test-Path -LiteralPath $document -PathType Leaf) {
                Invoke-PowerShellChecked $wrapper @('close', $document) | Out-Null
            }
        }
    }

    $workspace = Join-Path $testRoot 'pdf-workspace'
    Invoke-NativeChecked $python @($pipeline, 'prepare', $workspace) | Out-Null
    $source = Join-Path $workspace '01.input\scan-viet.pdf'
    $scanScript = @'
import sys
from PIL import Image, ImageDraw, ImageFont

font = ImageFont.truetype(r'C:\Windows\Fonts\arial.ttf', 42)
pages = []
for number, text in enumerate(('Trang một: Cộng hòa Xã hội Chủ nghĩa Việt Nam', 'Trang hai: Hồ sơ kiểm thử tiếng Việt'), 1):
    image = Image.new('RGB', (1240, 1754), 'white')
    draw = ImageDraw.Draw(image)
    draw.multiline_text((90, 180), f'{number}. {text}', fill='black', font=font, spacing=20)
    pages.append(image)
pages[0].save(sys.argv[1], 'PDF', save_all=True, append_images=pages[1:], resolution=150.0)
'@
    Invoke-NativeChecked $python @('-c', $scanScript, $source) | Out-Null

    $rendered = Invoke-NativeChecked $python @($pipeline, 'render', $workspace, $source)
    if (($rendered -join "`n") -notmatch 'rendered=2') { throw 'Expected two rendered PDF pages' }
    $resumed = Invoke-NativeChecked $python @($pipeline, 'render', $workspace, $source)
    if (($resumed -join "`n") -notmatch 'rendered=0') { throw 'PDF render resume did not skip completed pages' }
    $processed = Invoke-NativeChecked $python @($pipeline, 'preprocess', $workspace)
    if (($processed -join "`n") -notmatch 'preprocessed=2') { throw 'Expected two preprocessed PDF pages' }
    $resumed = Invoke-NativeChecked $python @($pipeline, 'preprocess', $workspace)
    if (($resumed -join "`n") -notmatch 'preprocessed=0') { throw 'PDF preprocess resume did not skip completed pages' }

    $ocr = Join-Path $workspace '02.process\ocr'
    New-Item -ItemType Directory -Path $ocr | Out-Null
    $utf8 = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Join-Path $ocr 'page-0001.md'), "# Trang một`n`n- Cộng hòa Xã hội Chủ nghĩa Việt Nam", $utf8)
    [IO.File]::WriteAllText((Join-Path $ocr 'page-0002.md'), "## Trang hai`n`n| Mục | Giá trị |`n| --- | --- |`n| QA | Đạt |", $utf8)
    Invoke-NativeChecked $python @($pipeline, 'merge', $workspace) | Out-Null
    Invoke-NativeChecked $python @($pipeline, 'export', $workspace) | Out-Null

    $markdown = Join-Path $workspace '03.output\scan-viet.md'
    $docx = Join-Path $workspace '03.output\scan-viet.docx'
    if ((Get-Content -LiteralPath $markdown -Raw) -notmatch 'Cộng hòa') { throw 'Merged Markdown lost Vietnamese text' }
    try {
        Invoke-PowerShellChecked $wrapper @('validate', $docx, '--json') | Out-Null
    } finally {
        if (Test-Path -LiteralPath $docx -PathType Leaf) {
            Invoke-PowerShellChecked $wrapper @('close', $docx) | Out-Null
        }
    }

    $outsidePdf = Join-Path $testRoot 'outside.pdf'
    Copy-Item -LiteralPath $source -Destination $outsidePdf
    Assert-NativeFailure $python @($pipeline, 'render', $workspace, $outsidePdf) 'must be a direct file inside'
    $wrongWorkspace = Join-Path $testRoot 'wrong-workspace'
    New-Item -ItemType Directory -Path $wrongWorkspace | Out-Null
    Assert-NativeFailure $python @($pipeline, 'cleanup', $wrongWorkspace, '--confirm') 'workspace marker'
    Assert-NativeFailure $python @($pipeline, 'cleanup', $workspace) 'requires --confirm'
    Invoke-NativeChecked $python @($pipeline, 'cleanup', $workspace, '--confirm') | Out-Null
    if ((Test-Path -LiteralPath (Join-Path $workspace '01.input')) -or (Test-Path -LiteralPath (Join-Path $workspace '02.process'))) {
        throw 'Cleanup left input or process directories behind'
    }
    if (-not (Test-Path -LiteralPath $markdown -PathType Leaf) -or -not (Test-Path -LiteralPath $docx -PathType Leaf)) {
        throw 'Cleanup removed completed outputs'
    }

    Write-Host 'SMOKE PASS: setup x2, OfficeCLI PATH/fallback, DOCX/PPTX/XLSX, PDF resume/export, and cleanup guards'
} finally {
    $env:PATH = $originalPath
    $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
    if (-not $resolvedTestRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe smoke cleanup path: $resolvedTestRoot"
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
