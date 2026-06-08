"""Optional Unreal Editor startup helper for unreal-mcp.

Place or run this script from an editor startup hook if you want a visible
confirmation that Remote Control is reachable from inside the editor process.
It does not replace enabling the Remote Control API plugin or the Python Editor
Script Plugin.
"""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request

RC_URL = os.getenv("UNREAL_RC_HTTP_URL", "http://127.0.0.1:30010").rstrip("/")


def _try_start_remote_control_server() -> None:
    """Best-effort attempt to start the Remote Control web server."""

    try:
        import unreal
    except Exception as exc:
        print("[unreal-mcp] Could not import unreal module: {}".format(exc))
        return

    try:
        unreal.SystemLibrary.execute_console_command(None, "WebControl.StartServer")
    except Exception as exc:
        print("[unreal-mcp] WebControl.StartServer was not accepted: {}".format(exc))


def _fetch_remote_info() -> dict | None:
    """Fetch /remote/info using only the Python standard library."""

    url = RC_URL + "/remote/info"
    request = urllib.request.Request(url, method="GET")

    try:
        with urllib.request.urlopen(request, timeout=2.0) as response:
            body = response.read().decode("utf-8", errors="replace")
    except urllib.error.URLError as exc:
        print("[unreal-mcp] Remote Control not reachable at {}: {}".format(url, exc))
        return None

    try:
        return json.loads(body)
    except json.JSONDecodeError:
        print("[unreal-mcp] Remote Control responded, but not with JSON: {}".format(body[:500]))
        return None


def main() -> None:
    """Print Remote Control status for the current editor session."""

    print("[unreal-mcp] Checking Unreal Remote Control at {}".format(RC_URL))
    _try_start_remote_control_server()

    info = None
    for _ in range(10):
        info = _fetch_remote_info()
        if info is not None:
            break
        time.sleep(0.5)

    if info is None:
        print(
            "[unreal-mcp] Remote Control is not reachable. Enable Remote Control API, "
            "enable the web server, and restart the editor if needed."
        )
        return

    version = (
        info.get("EngineVersion")
        or info.get("engineVersion")
        or info.get("Version")
        or info.get("version")
        or "unknown"
    )
    print("[unreal-mcp] Remote Control is reachable at {}".format(RC_URL))
    print("[unreal-mcp] Engine version: {}".format(version))


main()
