[CmdletBinding()]
param(
    [switch]$NoHtml
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$flutterDir = Join-Path $projectRoot "flutter_app"

if (-not (Test-Path $flutterDir)) {
    Write-Error "flutter_app not found at $flutterDir"
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "flutter not found in PATH"
    exit 1
}

Push-Location $flutterDir
try {
    $coverageDir = Join-Path (Get-Location) "coverage"
    if (-not (Test-Path $coverageDir)) {
        New-Item -ItemType Directory -Path $coverageDir | Out-Null
    }

    $machineLog = Join-Path $coverageDir "test-machine.jsonl"
    $errorLog = Join-Path $coverageDir "test-machine.stderr.log"
    if (Test-Path $machineLog) { Remove-Item $machineLog -Force }
    if (Test-Path $errorLog) { Remove-Item $errorLog -Force }

    Write-Host "Running flutter tests with coverage..."
    $process = Start-Process -FilePath "flutter" -ArgumentList @("test", "--coverage", "--machine") `
        -NoNewWindow -RedirectStandardOutput $machineLog -RedirectStandardError $errorLog -PassThru -Wait
    $exitCode = $process.ExitCode

    $total = 0
    $passed = 0
    $failed = 0
    $skipped = 0

    foreach ($line in Get-Content -Path $machineLog) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $evt = $line | ConvertFrom-Json -ErrorAction Stop
        } catch {
            continue
        }

        if ($evt.type -eq "testDone") {
            $total++
            switch ($evt.result) {
                "success" { $passed++ }
                "failure" { $failed++ }
                "error" { $failed++ }
                "skipped" { $skipped++ }
            }
        }
    }

    $executed = $passed + $failed
    $successRate = if ($executed -gt 0) { [math]::Round(($passed / $executed) * 100, 2) } else { 0 }

    Write-Host ""
    Write-Host "Test Summary"
    Write-Host "Total tests: $total"
    Write-Host "Executed:    $executed"
    Write-Host "Passed:      $passed"
    Write-Host "Failed:      $failed"
    Write-Host "Skipped:     $skipped"
    Write-Host "Success %:   $successRate`%"

    if ($exitCode -ne 0 -and (Test-Path $errorLog)) {
        if ((Get-Item $errorLog).Length -gt 0) {
            Write-Warning "flutter test reported errors. See $errorLog"
        }
    }

    if (-not $NoHtml) {
        $lcovFile = Join-Path $coverageDir "lcov.info"
        if (Test-Path $lcovFile) {
            $genhtml = Get-Command genhtml -ErrorAction SilentlyContinue
            if ($null -ne $genhtml) {
                $htmlDir = Join-Path $coverageDir "html"
                if (Test-Path $htmlDir) {
                    Remove-Item $htmlDir -Recurse -Force
                }

                & genhtml $lcovFile -o $htmlDir | Out-Null
                Write-Host "HTML coverage: $htmlDir"
            } else {
                Write-Warning "genhtml not found. Install lcov to generate HTML."
            }
        } else {
            Write-Warning "coverage/lcov.info not found."
        }
    }

    exit $exitCode
} finally {
    Pop-Location
}
