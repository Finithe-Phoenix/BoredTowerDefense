# unreal-mcp

`unreal-mcp` is a Python MCP server that lets an MCP client such as Claude Code control a running Unreal Engine 5 Editor through Unreal's Remote Control HTTP API.

It uses:

- Official MCP Python SDK: `mcp`
- `FastMCP`
- stdio transport
- `httpx` for HTTP
- Unreal Remote Control API, default `http://127.0.0.1:30010`
- Unreal Python Editor Script Plugin for higher-level editor automation

## Tools

Read-only or mostly read-only:

- `unreal_health`
- `unreal_run_python` depends on supplied code
- `unreal_call_function` depends on supplied function
- `unreal_get_property`
- `unreal_list_actors`
- `unreal_list_assets`

Mutating:

- `unreal_set_property`
- `unreal_console_command`
- `unreal_spawn_actor`
- `unreal_destroy_actor`
- `unreal_take_screenshot`
- `unreal_save_all`
- `unreal_play_in_editor`
- `unreal_stop_pie`

## Install

From the repository root:

```bash
python -m pip install -e ./unreal-mcp
```

Then verify the console script is available:

```bash
unreal-mcp
```

The process should start an MCP stdio server and wait for a client. It is normal for this command to appear idle when run directly.

## Unreal Engine 5 setup

1. Open the Unreal Engine 5 project in the Editor.

2. Enable these plugins:

   - Remote Control API
   - Python Editor Script Plugin

3. Restart the Editor after enabling plugins.

4. Turn on the Remote Control web server.

   Recommended options:

   - Project Settings > Remote Control
   - Or run this console command once:

     ```text
     WebControl.EnableServerOnStartup 1
     ```

   - Or launch the editor with:

     ```text
     -RCWebControlEnable -RCWebInterfaceEnable
     ```

5. Verify Remote Control is reachable:

   ```bash
   curl http://127.0.0.1:30010/remote/info
   ```

   A JSON response means the Remote Control server is up.

## Configuration

Environment variables:

| Variable | Default | Description |
| --- | --- | --- |
| `UNREAL_RC_HTTP_URL` | `http://127.0.0.1:30010` | Base URL for Unreal Remote Control HTTP API. |
| `UNREAL_RC_TIMEOUT` | `15` | HTTP timeout in seconds. Increase for slow editor operations. |

Example:

```bash
UNREAL_RC_HTTP_URL=http://127.0.0.1:30010 UNREAL_RC_TIMEOUT=30 unreal-mcp
```

On Windows PowerShell:

```powershell
$env:UNREAL_RC_HTTP_URL = "http://127.0.0.1:30010"
$env:UNREAL_RC_TIMEOUT = "30"
unreal-mcp
```

## Claude Code registration

If `unreal-mcp` is installed on PATH:

```bash
claude mcp add unreal -- unreal-mcp
```

Alternative using the Python module directly:

```bash
claude mcp add unreal -- python -m unreal_mcp
```

Example `.mcp.json`:

```json
{
  "mcpServers": {
    "unreal": {
      "command": "unreal-mcp",
      "env": {
        "UNREAL_RC_HTTP_URL": "http://127.0.0.1:30010",
        "UNREAL_RC_TIMEOUT": "15"
      }
    }
  }
}
```

Alternative `.mcp.json` using `python -m`:

```json
{
  "mcpServers": {
    "unreal": {
      "command": "python",
      "args": ["-m", "unreal_mcp"],
      "env": {
        "UNREAL_RC_HTTP_URL": "http://127.0.0.1:30010",
        "UNREAL_RC_TIMEOUT": "15"
      }
    }
  }
}
```

## How Python execution works

`unreal_run_python` calls this Remote Control function:

```text
/Script/PythonScriptPlugin.Default__PythonScriptLibrary.ExecutePythonCommandEx
```

The server sends a small wrapper script that captures:

- stdout
- stderr
- final expression result
- `result` or `_mcp_result` variables
- Python exceptions and traceback

Higher-level tools such as actor listing, spawning, asset queries, screenshots, saving, and PIE control are implemented with small editor-side Python snippets using the `unreal` module.

## Examples

List actors:

```json
{
  "name_contains": "light",
  "class_name": ""
}
```

Spawn a native actor:

```json
{
  "actor_class": "PointLight",
  "location": [0, 0, 300],
  "rotation": [0, 0, 0]
}
```

Spawn a Blueprint actor:

```json
{
  "actor_class": "/Game/Blueprints/BP_MyActor",
  "location": [100, 0, 100],
  "rotation": [0, 90, 0]
}
```

List static mesh assets:

```json
{
  "directory": "/Game",
  "recursive": true,
  "class_name": "StaticMesh"
}
```

Run Python:

```python
import unreal
_mcp_result = unreal.SystemLibrary.get_engine_version()
```

## Troubleshooting

### Connection refused or timeout

Check that:

- Unreal Editor is running.
- Remote Control API plugin is enabled.
- Remote Control web server is running.
- `UNREAL_RC_HTTP_URL` points to the right host and port.
- `curl http://127.0.0.1:30010/remote/info` returns JSON.

### HTTP 404

The Remote Control server may be running, but the API endpoint is unavailable. Verify the Remote Control API plugin is enabled, restart the editor, and re-check `/remote/info`.

### Python execution fails

Check that:

- Python Editor Script Plugin is enabled.
- The editor was restarted after enabling it.
- The Remote Control function `ExecutePythonCommandEx` is available.
- Your Python code imports `unreal` before using Unreal APIs.

### `unreal_spawn_actor` cannot resolve a class

Use one of:

- Native Unreal Python class name, for example `PointLight` or `StaticMeshActor`.
- Generated Blueprint class path, for example `/Game/Foo/BP_Bar.BP_Bar_C`.
- Blueprint asset path, for example `/Game/Foo/BP_Bar`.

### Screenshots do not appear where expected

Unreal screenshot commands may save relative filenames under the project `Saved/Screenshots` directory. Use an absolute path if the editor process has permission to write there.

### PIE controls do nothing

Some editor versions expose PIE controls on `LevelEditorSubsystem`; others expose them on `EditorLevelLibrary`. This server tries both. If neither is available, the tool returns a clear error.

## Security

Unreal Remote Control is intended for trusted local tooling. Treat it as unauthenticated control over the editor process. Do not bind it to a public interface, expose it through port forwarding, or allow untrusted MCP clients to connect.
