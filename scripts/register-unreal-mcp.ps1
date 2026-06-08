param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$python = Join-Path $RepoRoot "unreal-mcp\.venv\Scripts\python.exe"

if (-not (Test-Path $python)) {
    Write-Host "unreal-mcp venv not found: $python"
    Write-Host "Install it first with:"
    Write-Host "  cd $RepoRoot"
    Write-Host "  python -m venv unreal-mcp\.venv"
    Write-Host "  unreal-mcp\.venv\Scripts\python.exe -m pip install -e .\unreal-mcp"
    exit 1
}

& $python -c "import unreal_mcp.server; print('unreal_mcp import: OK')"

# Re-register cleanly (idempotent). The native 'claude' exit code does not trip
# $ErrorActionPreference, so a missing prior registration here is harmless.
claude mcp remove unreal -s local

# UNREAL_RC_TIMEOUT=60: heavier tools (e.g. unreal_inventory, which loads data
# assets) can exceed the 15s default Remote Control timeout.
claude mcp add unreal -e UNREAL_RC_TIMEOUT=60 -- $python -m unreal_mcp
claude mcp get unreal
