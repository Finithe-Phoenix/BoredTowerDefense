[CmdletBinding()]
param(
    [switch]$NoHtml,
    [switch]$UseDocker
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$flutterDir = Join-Path $projectRoot "flutter_app"
$coverageDir = Join-Path $flutterDir "coverage"
$machineLog = Join-Path $coverageDir "test-machine.jsonl"
$errorLog = Join-Path $coverageDir "test-machine.stderr.log"

if (-not (Test-Path $flutterDir)) {
    Write-Error "flutter_app not found at $flutterDir"
    exit 1
}

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
$useDockerMode = $UseDocker.IsPresent

if (-not $flutterCmd) {
    $useDockerMode = $true
}

if ($useDockerMode -and -not $dockerCmd) {
    Write-Error "docker not found in PATH"
    exit 1
}

if (-not $useDockerMode -and -not $flutterCmd) {
    Write-Error "flutter not found in PATH"
    exit 1
}

if (-not (Test-Path $coverageDir)) {
    New-Item -ItemType Directory -Path $coverageDir | Out-Null
}

if (Test-Path $machineLog) { Remove-Item $machineLog -Force }
if (Test-Path $errorLog) { Remove-Item $errorLog -Force }

if ($useDockerMode) {
    $composeFile = Join-Path $flutterDir "docker-compose.yml"
    if (-not (Test-Path $composeFile)) {
        Write-Error "docker-compose.yml not found at $composeFile"
        exit 1
    }

    Write-Host "Running flutter tests with coverage (docker)..."
    $process = Start-Process -FilePath "docker" -ArgumentList @(
        "compose", "-f", $composeFile, "run", "--rm", "flutter-dev",
        "flutter", "test", "--coverage", "--machine"
    ) -NoNewWindow -RedirectStandardOutput $machineLog -RedirectStandardError $errorLog -PassThru -Wait
    $exitCode = $process.ExitCode
} else {
    Write-Host "Running flutter tests with coverage (local)..."
    Push-Location $flutterDir
    try {
        $process = Start-Process -FilePath "flutter" -ArgumentList @("test", "--coverage", "--machine") `
            -NoNewWindow -RedirectStandardOutput $machineLog -RedirectStandardError $errorLog -PassThru -Wait
        $exitCode = $process.ExitCode
    } finally {
        Pop-Location
    }
}

$total = 0
$passed = 0
$failed = 0
$skipped = 0

if (Test-Path $machineLog) {
    foreach ($line in Get-Content -Path $machineLog) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $evt = $line | ConvertFrom-Json -ErrorAction Stop
        } catch {
            continue
        }

        if ($evt.PSObject.Properties["type"] -and $evt.type -eq "testDone") {
            $total++
            switch ($evt.result) {
                "success" { $passed++ }
                "failure" { $failed++ }
                "error" { $failed++ }
                "skipped" { $skipped++ }
            }
        }
    }
} else {
    Write-Warning "machine log not found at $machineLog"
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
        $htmlDir = Join-Path $coverageDir "html"
        if (Test-Path $htmlDir) {
            Remove-Item $htmlDir -Recurse -Force
        }

        $genhtml = Get-Command genhtml -ErrorAction SilentlyContinue
        if ($null -ne $genhtml) {
            & genhtml $lcovFile -o $htmlDir | Out-Null
            Write-Host "HTML coverage: $htmlDir"
        } elseif ($dockerCmd) {
            $coveragePath = (Resolve-Path $coverageDir).Path
            Write-Host "Generating HTML coverage with docker..."
            $htmlProcess = Start-Process -FilePath "docker" -ArgumentList @(
                "run", "--rm", "-v", "$($coveragePath):/cov", "ubuntu:22.04",
                "bash", "-lc", "apt-get update >/dev/null && apt-get install -y lcov >/dev/null && genhtml /cov/lcov.info -o /cov/html"
            ) -NoNewWindow -PassThru -Wait
            if ($htmlProcess.ExitCode -eq 0) {
                Write-Host "HTML coverage: $htmlDir"
            } else {
                Write-Warning "Failed to generate HTML coverage with docker."
            }
        } else {
            Write-Warning "genhtml not found and docker unavailable."
        }
    } else {
        Write-Warning "coverage/lcov.info not found."
    }
}

exit $exitCode
