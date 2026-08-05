$repoRoot = Split-Path -Parent $PSScriptRoot
$wrapper = Join-Path $repoRoot 'plugins\office-toolkit-windows\scripts\invoke-officecli.ps1'

Describe 'invoke-officecli' {
    BeforeEach {
        $script:oldPath = $env:PATH
        $env:PATH = $TestDrive
    }

    AfterEach {
        $env:PATH = $script:oldPath
    }

    It 'uses a supported PATH OfficeCLI and preserves raw streams and exit code' {
        $fake = Join-Path $TestDrive 'officecli.cmd'
        [IO.File]::WriteAllText($fake, "@echo off`r`nif `"%~1`"==`"--version`" (echo 1.0.135 & exit /b 0)`r`necho OUT:%~1`r`necho ERR:%~2 1>&2`r`nexit /b 23`r`n")

        $result = & $wrapper '--sentinel' 'x with spaces' 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        $exitCode | Should Be 23
        $result | Should Match 'OUT:--sentinel'
        $result | Should Match 'ERR:x with spaces'
    }

    It 'rejects an old PATH OfficeCLI and uses the verified bundled executable' {
        $fake = Join-Path $TestDrive 'officecli.cmd'
        [IO.File]::WriteAllText($fake, "@echo off`r`nif `"%~1`"==`"--version`" (echo 1.0.134 & exit /b 0)`r`necho PATH-TOOL`r`nexit /b 0`r`n")

        $result = & $wrapper '--version' 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        $exitCode | Should Be 0
        $result.Trim() | Should Match '(?m)1\.0\.135\s*$'
    }
}
