param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$RemoteControlUrl = "http://127.0.0.1:30010"
)

$ErrorActionPreference = "Stop"

$python = Join-Path $RepoRoot "unreal-mcp\.venv\Scripts\python.exe"
$serverReadme = Join-Path $RepoRoot "unreal-mcp\README.md"

Write-Host "Repo: $RepoRoot"
Write-Host "MCP Python: $python"

if (-not (Test-Path $python)) {
    Write-Host "unreal-mcp venv: MISSING"
    Write-Host "Run: python -m pip install -e .\unreal-mcp"
    exit 1
}

& $python -c "import unreal_mcp.server; print('unreal_mcp import: OK')"
& $python -m pip show unreal-mcp mcp httpx | Select-String -Pattern "Name:|Version:|Editable project location"

Write-Host ""
Write-Host "Claude MCP registration:"
try {
    claude mcp get unreal
} catch {
    Write-Host "claude mcp get unreal failed: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "UE Remote Control: $RemoteControlUrl/remote/info"
try {
    $info = Invoke-RestMethod -Uri "$RemoteControlUrl/remote/info" -TimeoutSec 3
    $info | ConvertTo-Json -Depth 8
    Write-Host "UE Remote Control: REACHABLE"

    Write-Host ""
    Write-Host "UE Python execution:"
    $pythonProbe = @'
from unreal_mcp.unreal_client import UnrealRemoteClient

code = """
import unreal
subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
actors = subsystem.get_all_level_actors() if subsystem else []
result = {
    "engine_version": unreal.SystemLibrary.get_engine_version(),
    "actor_count": len(actors),
}
"""

client = UnrealRemoteClient()
print(client.run_python(code))
'@
    $pythonProbe | & $python -
} catch {
    Write-Host "UE Remote Control: UNREACHABLE"
    Write-Host "Reason: $($_.Exception.Message)"
    Write-Host "Open UE5 and enable Remote Control API + Python Editor Script Plugin."
    Write-Host "See: $serverReadme"
}
