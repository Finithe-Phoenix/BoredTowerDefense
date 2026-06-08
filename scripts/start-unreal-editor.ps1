param(
    [string]$UnrealEditor = "C:\Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe",
    [string]$Project = "C:\Users\daedg\OneDrive\Documentos\Unreal Projects\BoredTowerDefense\BoredTowerDefense.uproject",
    [switch]$ForceRestart
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $UnrealEditor)) {
    Write-Host "UnrealEditor.exe not found: $UnrealEditor"
    exit 1
}

if (-not (Test-Path $Project)) {
    Write-Host "Unreal project not found: $Project"
    exit 1
}

$escapedProject = [Regex]::Escape($Project)
$running = Get-CimInstance Win32_Process |
    Where-Object { $_.Name -eq "UnrealEditor.exe" -and $_.CommandLine -match $escapedProject }

if ($running -and -not $ForceRestart) {
    Write-Host "Unreal Editor is already running for this project."
    Write-Host "Close it and run this script again, or run with -ForceRestart after saving work."
    $running | Select-Object ProcessId,CommandLine | Format-List
    exit 0
}

if ($running -and $ForceRestart) {
    Write-Host "Stopping existing Unreal Editor process(es). Save work before using -ForceRestart."
    foreach ($process in $running) {
        Stop-Process -Id $process.ProcessId -Force
    }
    Start-Sleep -Seconds 3
}

# Only -RCWebControlEnable is needed: it starts the Remote Control HTTP API on
# :30010 that the unreal MCP talks to. We deliberately do NOT pass
# -RCWebInterfaceEnable (the optional Node.js web panel on :30000) because it
# throws "Cannot find module 'jsesc'" unless the engine WebApp has had npm
# install run, and we never use that panel.
$args = @(
    "`"$Project`"",
    "-RCWebControlEnable"
)

Start-Process -FilePath $UnrealEditor -ArgumentList $args
Write-Host "Started Unreal Editor with Remote Control flags."
Write-Host "After the editor finishes loading, run: .\scripts\unreal-health.ps1"
