"""FastMCP server exposing Unreal Engine 5 Editor automation tools."""

from __future__ import annotations

import json
from typing import Any

from mcp.server.fastmcp import FastMCP

from .unreal_client import UnrealRemoteClient, UnrealRemoteError

mcp = FastMCP("unreal-mcp")


def main() -> None:
    """Run the MCP server over stdio transport."""

    mcp.run(transport="stdio")


def _client() -> UnrealRemoteClient:
    return UnrealRemoteClient.from_env()


def _tool_error(exc: Exception, *, base_url: str | None = None) -> dict[str, Any]:
    data: dict[str, Any] = {
        "ok": False,
        "error": str(exc),
        "error_type": exc.__class__.__name__,
    }
    if base_url:
        data["base_url"] = base_url
    return data


def _run_structured_python(code: str) -> dict[str, Any]:
    """Run editor Python and flatten structured result dictionaries."""

    try:
        client = _client()
        execution = client.run_python(code)
    except UnrealRemoteError as exc:
        return _tool_error(exc)

    if not execution.get("ok", False):
        return {
            "ok": False,
            "error": execution.get("error") or "Unreal Python code failed.",
            "traceback": execution.get("traceback"),
            "stdout": execution.get("stdout", ""),
            "raw_response": execution.get("raw_response"),
        }

    result = execution.get("result")
    if isinstance(result, dict):
        merged = dict(result)
        merged.setdefault("ok", True)
        if execution.get("stdout"):
            merged.setdefault("stdout", execution["stdout"])
        return merged

    return {
        "ok": True,
        "result": result,
        "stdout": execution.get("stdout", ""),
    }


def _normalize_vector(
    values: list[float] | None,
    *,
    length: int,
    default: list[float],
    name: str,
) -> list[float]:
    if values is None:
        values = default

    if not isinstance(values, (list, tuple)) or len(values) != length:
        raise ValueError(f"{name} must be a list of {length} numbers.")

    try:
        return [float(value) for value in values]
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{name} must contain only numbers.") from exc


def _normalize_wait_seconds(value: float, *, name: str = "wait_seconds") -> float:
    try:
        seconds = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{name} must be a number of seconds.") from exc

    if seconds < 0:
        raise ValueError(f"{name} must be greater than or equal to 0.")
    return seconds


def _poll_local_screenshot_file(
    paths: list[str] | None,
    wait_seconds: float,
    *,
    glob_patterns: list[str] | None = None,
    modified_after: float | None = None,
) -> tuple[str | None, int]:
    import glob
    import os
    import time

    deadline = time.monotonic() + max(0.0, wait_seconds)

    def candidates() -> list[str]:
        seen: set[str] = set()
        items: list[str] = []

        for path in paths or []:
            if path and path not in seen:
                seen.add(path)
                items.append(path)

        for pattern in glob_patterns or []:
            for path in glob.glob(pattern):
                if path and path not in seen:
                    seen.add(path)
                    items.append(path)

        return items

    while True:
        for path in candidates():
            try:
                if not os.path.isfile(path):
                    continue
                if modified_after is not None and os.path.getmtime(path) < modified_after - 1.0:
                    continue

                size_1 = os.path.getsize(path)
                if size_1 <= 0:
                    continue

                time.sleep(0.05)
                size_2 = os.path.getsize(path)
                if size_2 > 0 and size_1 == size_2:
                    return path, int(size_2)
            except OSError:
                continue

        if time.monotonic() >= deadline:
            return None, 0

        time.sleep(min(0.1, max(0.0, deadline - time.monotonic())))


def _move_local_file_to_path(source_path: str, output_path: str) -> str:
    import os
    import shutil

    source_abs = os.path.abspath(source_path)
    output_abs = os.path.abspath(output_path)

    if os.path.normcase(source_abs) == os.path.normcase(output_abs):
        return output_abs

    os.makedirs(os.path.dirname(output_abs), exist_ok=True)

    try:
        if os.path.exists(output_abs):
            os.remove(output_abs)
        os.replace(source_abs, output_abs)
    except OSError:
        shutil.copy2(source_abs, output_abs)
        try:
            os.remove(source_abs)
        except OSError:
            pass

    return output_abs


def _extract_property_value(response: dict[str, Any]) -> Any:
    for key in ("propertyValue", "PropertyValue", "value", "Value"):
        if key in response:
            return response[key]

    if len(response) == 1:
        return next(iter(response.values()))

    return None


def _engine_version_from_info(info: dict[str, Any]) -> Any:
    for key in (
        "EngineVersion",
        "engineVersion",
        "engine_version",
        "Version",
        "version",
    ):
        if key in info:
            return info[key]
    return None


@mcp.tool()
def unreal_health() -> dict[str, Any]:
    """Check whether the Unreal Editor Remote Control API is reachable.

    Returns reachability, configured base URL, best-effort engine version, and
    the raw /remote/info response.
    """

    try:
        client = _client()
        info = client.info()
        return {
            "ok": True,
            "reachable": True,
            "base_url": client.base_url,
            "engine_version": _engine_version_from_info(info),
            "info": info,
        }
    except UnrealRemoteError as exc:
        return _tool_error(exc)


@mcp.tool()
def unreal_run_python(code: str) -> dict[str, Any]:
    """Execute Python inside the running Unreal Editor.

    Args:
        code: Python source code. If the final statement is an expression, its
            value is returned as result. Otherwise set result or _mcp_result.
    """

    try:
        client = _client()
        return client.run_python(code)
    except UnrealRemoteError as exc:
        return _tool_error(exc)


@mcp.tool()
def unreal_call_function(
    object_path: str,
    function_name: str,
    parameters: dict[str, Any] | None = None,
    generate_transaction: bool = True,
) -> dict[str, Any]:
    """Call an arbitrary UFUNCTION through /remote/object/call.

    Args:
        object_path: UObject path, for example /Script/Package.Default__Class.
        function_name: UFUNCTION name to invoke.
        parameters: JSON object passed as the function parameters.
        generate_transaction: Whether Unreal should create an undo transaction.
    """

    try:
        client = _client()
        response = client.call_function(
            object_path=object_path,
            function_name=function_name,
            parameters=parameters or {},
            generate_transaction=generate_transaction,
        )
        return {"ok": True, "response": response}
    except UnrealRemoteError as exc:
        return _tool_error(exc)


@mcp.tool()
def unreal_get_property(object_path: str, property_name: str) -> dict[str, Any]:
    """Read a UObject property through /remote/object/property.

    Args:
        object_path: UObject path to inspect.
        property_name: Property name to read.
    """

    try:
        client = _client()
        response = client.get_property(object_path, property_name)
        return {
            "ok": True,
            "value": _extract_property_value(response),
            "response": response,
        }
    except UnrealRemoteError as exc:
        return _tool_error(exc)


@mcp.tool()
def unreal_set_property(object_path: str, property_name: str, value: Any) -> dict[str, Any]:
    """Write a UObject property through /remote/object/property.

    Args:
        object_path: UObject path to modify.
        property_name: Property name to write.
        value: JSON-serializable property value.
    """

    try:
        client = _client()
        response = client.set_property(object_path, property_name, value)
        return {"ok": True, "response": response}
    except UnrealRemoteError as exc:
        return _tool_error(exc)


@mcp.tool()
def unreal_console_command(command: str) -> dict[str, Any]:
    """Run an Unreal editor or console command via editor-side Python.

    Args:
        command: Console command text, for example stat fps or HighResShot 2.
    """

    code = f"""
import unreal

command = {json.dumps(command)}
world = None

try:
    editor_subsystem = unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem)
    if editor_subsystem:
        world = editor_subsystem.get_editor_world()
except Exception:
    world = None

unreal.SystemLibrary.execute_console_command(world, command)
_mcp_result = {{"command": command, "executed": True}}
"""
    return _run_structured_python(code)


@mcp.tool()
def unreal_list_actors(name_contains: str = "", class_name: str = "") -> dict[str, Any]:
    """List actors in the current editor level.

    Args:
        name_contains: Optional case-insensitive substring filter against actor
            label, object name, or object path.
        class_name: Optional case-insensitive substring filter against class
            name or class path.
    """

    code = f"""
import unreal

name_filter = {json.dumps(name_contains or "")}.lower()
class_filter = {json.dumps(class_name or "")}.lower()

subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
if not subsystem:
    raise RuntimeError("EditorActorSubsystem is unavailable.")

def vec3(value):
    return [
        float(getattr(value, "x", getattr(value, "X", 0.0))),
        float(getattr(value, "y", getattr(value, "Y", 0.0))),
        float(getattr(value, "z", getattr(value, "Z", 0.0))),
    ]

def rot3(value):
    return [
        float(getattr(value, "pitch", getattr(value, "Pitch", 0.0))),
        float(getattr(value, "yaw", getattr(value, "Yaw", 0.0))),
        float(getattr(value, "roll", getattr(value, "Roll", 0.0))),
    ]

items = []
for actor in subsystem.get_all_level_actors():
    if actor is None:
        continue

    label = actor.get_actor_label() if hasattr(actor, "get_actor_label") else actor.get_name()
    name = actor.get_name()
    path = actor.get_path_name()
    actor_class = actor.get_class()
    actor_class_name = actor_class.get_name() if actor_class else ""
    actor_class_path = actor_class.get_path_name() if actor_class else ""

    name_haystack = " ".join([label, name, path]).lower()
    class_haystack = " ".join([actor_class_name, actor_class_path]).lower()

    if name_filter and name_filter not in name_haystack:
        continue
    if class_filter and class_filter not in class_haystack:
        continue

    items.append({{
        "label": label,
        "name": name,
        "path": path,
        "class_name": actor_class_name,
        "class_path": actor_class_path,
        "location": vec3(actor.get_actor_location()),
        "rotation": rot3(actor.get_actor_rotation()),
        "hidden": bool(actor.is_hidden_ed()) if hasattr(actor, "is_hidden_ed") else None,
    }})

_mcp_result = {{
    "count": len(items),
    "actors": items,
    "filters": {{
        "name_contains": name_filter,
        "class_name": class_filter,
    }},
}}
"""
    return _run_structured_python(code)


@mcp.tool()
def unreal_spawn_actor(
    actor_class: str,
    location: list[float] | None = None,
    rotation: list[float] | None = None,
) -> dict[str, Any]:
    """Spawn an actor in the current editor level.

    Args:
        actor_class: Unreal Python class name, native class path, or Blueprint
            asset/generated class path.
        location: [x, y, z] in Unreal units.
        rotation: [pitch, yaw, roll] in degrees.
    """

    try:
        loc = _normalize_vector(location, length=3, default=[0.0, 0.0, 0.0], name="location")
        rot = _normalize_vector(rotation, length=3, default=[0.0, 0.0, 0.0], name="rotation")
    except ValueError as exc:
        return _tool_error(exc)

    code = f"""
import unreal

actor_class_spec = {json.dumps(actor_class)}
location_values = {json.dumps(loc)}
rotation_values = {json.dumps(rot)}

def resolve_actor_class(spec):
    if not spec:
        raise RuntimeError("actor_class is required.")

    if hasattr(unreal, spec):
        candidate = getattr(unreal, spec)
        try:
            if issubclass(candidate, unreal.Actor):
                return candidate
        except TypeError:
            pass

    candidates = [spec]
    if spec.startswith("/Game/"):
        asset_name = spec.rsplit("/", 1)[-1]
        if "." not in asset_name:
            candidates.append(spec + "." + asset_name + "_C")
            candidates.append(spec + "_C")
        elif not spec.endswith("_C"):
            candidates.append(spec + "_C")

    for candidate_path in candidates:
        try:
            loaded_class = unreal.load_class(None, candidate_path)
        except Exception:
            loaded_class = None
        if loaded_class:
            return loaded_class

    if hasattr(unreal, "EditorAssetLibrary"):
        try:
            blueprint_class = unreal.EditorAssetLibrary.load_blueprint_class(spec)
        except Exception:
            blueprint_class = None
        if blueprint_class:
            return blueprint_class

    raise RuntimeError("Could not resolve actor class: " + spec)

subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
if not subsystem:
    raise RuntimeError("EditorActorSubsystem is unavailable.")

resolved_class = resolve_actor_class(actor_class_spec)
spawn_location = unreal.Vector(location_values[0], location_values[1], location_values[2])
spawn_rotation = unreal.Rotator(rotation_values[0], rotation_values[1], rotation_values[2])

actor = subsystem.spawn_actor_from_class(resolved_class, spawn_location, spawn_rotation)
if actor is None:
    raise RuntimeError("spawn_actor_from_class returned None.")

actor_class_obj = actor.get_class()
_mcp_result = {{
    "actor": {{
        "label": actor.get_actor_label() if hasattr(actor, "get_actor_label") else actor.get_name(),
        "name": actor.get_name(),
        "path": actor.get_path_name(),
        "class_name": actor_class_obj.get_name() if actor_class_obj else "",
        "class_path": actor_class_obj.get_path_name() if actor_class_obj else "",
        "location": location_values,
        "rotation": rotation_values,
    }}
}}
"""
    return _run_structured_python(code)


@mcp.tool()
def unreal_destroy_actor(actor_label_or_name: str) -> dict[str, Any]:
    """Destroy one actor by exact label, object name, or path.

    If no exact match exists, a single substring match is accepted. Multiple
    substring matches fail with a clear error to avoid accidental deletion.
    """

    code = f"""
import unreal

target = {json.dumps(actor_label_or_name or "")}
target_lower = target.lower().strip()
if not target_lower:
    raise RuntimeError("actor_label_or_name is required.")

subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
if not subsystem:
    raise RuntimeError("EditorActorSubsystem is unavailable.")

def actor_info(actor):
    actor_class = actor.get_class()
    return {{
        "label": actor.get_actor_label() if hasattr(actor, "get_actor_label") else actor.get_name(),
        "name": actor.get_name(),
        "path": actor.get_path_name(),
        "class_name": actor_class.get_name() if actor_class else "",
        "class_path": actor_class.get_path_name() if actor_class else "",
    }}

actors = [actor for actor in subsystem.get_all_level_actors() if actor is not None]
exact_matches = []
contains_matches = []

for actor in actors:
    info = actor_info(actor)
    values = [info["label"], info["name"], info["path"]]
    lowered = [value.lower() for value in values]

    if target_lower in lowered:
        exact_matches.append(actor)
    elif any(target_lower in value for value in lowered):
        contains_matches.append(actor)

if exact_matches:
    selected = exact_matches[0]
elif len(contains_matches) == 1:
    selected = contains_matches[0]
elif len(contains_matches) > 1:
    preview = [actor_info(actor) for actor in contains_matches[:10]]
    raise RuntimeError(
        "Multiple actors matched. Use an exact label, name, or path. Matches: "
        + repr(preview)
    )
else:
    raise RuntimeError("No actor matched: " + target)

info = actor_info(selected)
destroyed = bool(subsystem.destroy_actor(selected))
_mcp_result = {{
    "destroyed": destroyed,
    "actor": info,
}}
"""
    return _run_structured_python(code)


@mcp.tool()
def unreal_list_assets(
    directory: str = "/Game",
    recursive: bool = True,
    class_name: str = "",
) -> dict[str, Any]:
    """List assets using Unreal's Asset Registry.

    Args:
        directory: Content path such as /Game or /Game/Props.
        recursive: Whether to include child directories.
        class_name: Optional case-insensitive class filter.
    """

    code = f"""
import unreal

directory = {json.dumps(directory or "/Game")}
recursive = {repr(bool(recursive))}
class_filter = {json.dumps(class_name or "")}.lower()

registry = unreal.AssetRegistryHelpers.get_asset_registry()
asset_data_items = registry.get_assets_by_path(directory, recursive=recursive)

assets = []
for asset_data in asset_data_items:
    asset_name = str(asset_data.asset_name)
    package_name = str(asset_data.package_name)
    object_path = str(getattr(asset_data, "object_path", "")) or (package_name + "." + asset_name)

    class_path = str(getattr(asset_data, "asset_class_path", ""))
    legacy_class = str(getattr(asset_data, "asset_class", ""))
    class_haystack = " ".join([class_path, legacy_class]).lower()

    if class_filter and class_filter not in class_haystack:
        continue

    assets.append({{
        "asset_name": asset_name,
        "package_name": package_name,
        "object_path": object_path,
        "class_name": legacy_class,
        "class_path": class_path,
    }})

_mcp_result = {{
    "directory": directory,
    "recursive": recursive,
    "class_name": class_filter,
    "count": len(assets),
    "assets": assets,
}}
"""
    return _run_structured_python(code)


@mcp.tool()
def unreal_take_screenshot(
    filename: str = "mcp_shot.png",
    resolution: list[float] | None = None,
    wait_seconds: float = 10,
) -> dict[str, Any]:
    """Take a high-resolution scene screenshot and return the resolved PNG path.

    Captures the rendered 3D scene ONLY (no Slate/UMG, no DrawDebug). Use
    unreal_screenshot_ui for the HUD/overlay. Most reliable during PIE.

    Args:
        filename: Output filename or absolute path.
        resolution: [width, height] in pixels.
        wait_seconds: How long the server polls for the PNG to appear.
    """

    try:
        width, height = [
            int(value)
            for value in _normalize_vector(
                resolution,
                length=2,
                default=[1920.0, 1080.0],
                name="resolution",
            )
        ]
        if width <= 0 or height <= 0:
            raise ValueError("resolution values must be greater than 0.")
        wait = _normalize_wait_seconds(wait_seconds)
    except ValueError as exc:
        return _tool_error(exc)

    code = f"""
import glob
import os
import sys
import time
import unreal

filename = {json.dumps(filename or "mcp_shot.png")}
width = int({width})
height = int({height})

def full_path(path):
    try:
        return os.path.normpath(unreal.Paths.convert_relative_path_to_full(path))
    except Exception:
        return os.path.abspath(path)

def with_png_extension(path):
    root, ext = os.path.splitext(path)
    if ext.lower() == ".png":
        return path
    if ext:
        return root + ".png"
    return path + ".png"

def platform_dir_name():
    if os.name == "nt":
        return "WindowsEditor"
    if sys.platform == "darwin":
        return "MacEditor"
    return "LinuxEditor"

def pie_state():
    try:
        level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        if level_subsystem and hasattr(level_subsystem, "is_in_play_in_editor"):
            return bool(level_subsystem.is_in_play_in_editor())
    except Exception:
        pass
    return None

saved_dir = full_path(unreal.Paths.project_saved_dir())
screenshots_root = os.path.join(saved_dir, "Screenshots")
platform_dir = os.path.join(screenshots_root, platform_dir_name())

filename = with_png_extension(filename)
if os.path.isabs(filename):
    output_path = os.path.normpath(filename)
    screenshot_argument = output_path
    relative_name = os.path.basename(output_path)
else:
    relative_name = filename.lstrip("/\\\\")
    output_path = os.path.normpath(os.path.join(platform_dir, relative_name))
    screenshot_argument = relative_name.replace("\\\\", "/")

os.makedirs(os.path.dirname(output_path), exist_ok=True)
try:
    if os.path.exists(output_path):
        os.remove(output_path)
except OSError:
    pass

candidate_paths = [output_path]
for path in glob.glob(os.path.join(screenshots_root, "*", relative_name)):
    if path not in candidate_paths:
        candidate_paths.append(os.path.normpath(path))

method = None
task_info = None
request_time = time.time()

try:
    try:
        task = unreal.AutomationLibrary.take_high_res_screenshot(
            width,
            height,
            screenshot_argument,
            force_game_view=True,
        )
    except TypeError:
        task = unreal.AutomationLibrary.take_high_res_screenshot(width, height, screenshot_argument)

    method = "AutomationLibrary.take_high_res_screenshot"
    task_info = repr(task)
except Exception as first_error:
    world = None
    try:
        editor_subsystem = unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem)
        if editor_subsystem and hasattr(editor_subsystem, "get_game_world"):
            world = editor_subsystem.get_game_world()
        if world is None and editor_subsystem and hasattr(editor_subsystem, "get_editor_world"):
            world = editor_subsystem.get_editor_world()
    except Exception:
        world = None

    console_path = output_path.replace("\\\\", "/").replace('"', '\\\\"')
    command = 'HighResShot {{}}x{{}} filename="{{}}"'.format(width, height, console_path)
    unreal.SystemLibrary.execute_console_command(world, command)
    method = "HighResShot console fallback"
    task_info = "AutomationLibrary failed: " + repr(first_error)

_mcp_result = {{
    "filename": filename,
    "resolution": [width, height],
    "method": method,
    "task": task_info,
    "output_path": output_path,
    "candidate_paths": candidate_paths,
    "request_time": request_time,
    "is_in_play_in_editor": pie_state(),
    "note": "High-res screenshot writes asynchronously and captures the 3D scene only; call during PIE for reliable output in this UE build.",
}}
"""
    result = _run_structured_python(code)
    if not result.get("ok", False):
        return result

    import os

    output_path = result.get("output_path")
    candidate_paths = [output_path] + list(result.get("candidate_paths") or [])

    glob_patterns: list[str] = []
    for path in candidate_paths:
        if path:
            root, _ = os.path.splitext(path)
            glob_patterns.append(root + "*.png")

    found_path, size = _poll_local_screenshot_file(
        candidate_paths,
        wait,
        glob_patterns=glob_patterns,
        modified_after=result.get("request_time"),
    )

    result["wait_seconds"] = wait
    result["found"] = bool(found_path)
    result["exists"] = bool(found_path)
    result["size"] = size
    if found_path:
        result["output_path"] = found_path

    return result


@mcp.tool()
def unreal_screenshot_ui(
    filename: str = "mcp_ui.png",
    resolution: list[float] | None = None,
    wait_seconds: float = 15,
) -> dict[str, Any]:
    """Capture the composited PIE viewport INCLUDING Slate/UMG and DrawDebug.

    Uses the game viewport's `Shot SHOWUI` path (FScreenshotRequest with
    bShowUI=true), then polls from the MCP process after the HTTP exec returns
    so the editor can tick and finish the async write. Requires active PIE
    (call unreal_play_in_editor(mode="play") first).
    """

    try:
        requested_resolution = None
        if resolution is not None:
            width, height = [
                int(value)
                for value in _normalize_vector(
                    resolution,
                    length=2,
                    default=[0.0, 0.0],
                    name="resolution",
                )
            ]
            if width <= 0 or height <= 0:
                raise ValueError("resolution values must be greater than 0.")
            requested_resolution = [width, height]

        wait = _normalize_wait_seconds(wait_seconds)
    except ValueError as exc:
        return _tool_error(exc)

    code = f"""
import glob
import os
import sys
import time
import unreal

filename = {json.dumps(filename or "mcp_ui.png")}
requested_resolution = {repr(requested_resolution)}

def full_path(path):
    try:
        return os.path.normpath(unreal.Paths.convert_relative_path_to_full(path))
    except Exception:
        return os.path.abspath(path)

def with_png_extension(path):
    root, ext = os.path.splitext(path)
    if ext.lower() == ".png":
        return path
    if ext:
        return root + ".png"
    return path + ".png"

def platform_dir_name():
    if os.name == "nt":
        return "WindowsEditor"
    if sys.platform == "darwin":
        return "MacEditor"
    return "LinuxEditor"

level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
if not level_subsystem or not hasattr(level_subsystem, "is_in_play_in_editor"):
    raise RuntimeError("LevelEditorSubsystem.is_in_play_in_editor is unavailable.")

is_pie = bool(level_subsystem.is_in_play_in_editor())
if not is_pie:
    raise RuntimeError("unreal_screenshot_ui requires active PIE. Call unreal_play_in_editor(mode='play') first.")

editor_subsystem = unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem)
world = None
if editor_subsystem and hasattr(editor_subsystem, "get_game_world"):
    world = editor_subsystem.get_game_world()
if world is None and hasattr(unreal, "EditorLevelLibrary") and hasattr(unreal.EditorLevelLibrary, "get_game_world"):
    world = unreal.EditorLevelLibrary.get_game_world()
if world is None:
    raise RuntimeError("Could not resolve the PIE game world.")

saved_dir = full_path(unreal.Paths.project_saved_dir())
screenshots_root = os.path.join(saved_dir, "Screenshots")
platform_dir = os.path.join(screenshots_root, platform_dir_name())

filename = with_png_extension(filename)
if os.path.isabs(filename):
    output_path = os.path.normpath(filename)
else:
    output_path = os.path.normpath(os.path.join(platform_dir, filename.lstrip("/\\\\")))

os.makedirs(os.path.dirname(output_path), exist_ok=True)
try:
    if os.path.exists(output_path):
        os.remove(output_path)
except OSError:
    pass

search_dirs = [platform_dir]
if os.path.isdir(screenshots_root):
    for entry in os.listdir(screenshots_root):
        candidate = os.path.join(screenshots_root, entry)
        if os.path.isdir(candidate):
            search_dirs.append(os.path.normpath(candidate))
search_dirs.append(screenshots_root)

unique_search_dirs = []
for directory in search_dirs:
    if directory not in unique_search_dirs:
        unique_search_dirs.append(directory)

setres_command = None
if requested_resolution:
    setres_command = "SetRes {{}}x{{}}w".format(requested_resolution[0], requested_resolution[1])
    unreal.SystemLibrary.execute_console_command(world, setres_command)

request_time = time.time()
console_path = output_path.replace("\\\\", "/").replace('"', '\\\\"')
command = 'Shot SHOWUI filename="{{}}" -nosuffix'.format(console_path)
unreal.SystemLibrary.execute_console_command(world, command)

_mcp_result = {{
    "filename": filename,
    "output_path": output_path,
    "candidate_paths": [output_path],
    "search_dirs": unique_search_dirs,
    "request_time": request_time,
    "command": command,
    "setres_command": setres_command,
    "requested_resolution": requested_resolution,
    "is_in_play_in_editor": is_pie,
    "method": "SystemLibrary.execute_console_command: Shot SHOWUI filename=... -nosuffix",
    "note": "Shot SHOWUI routes through the game viewport screenshot request with bShowUI=true. The saved image is the current PIE viewport/window composite.",
}}
"""
    result = _run_structured_python(code)
    if not result.get("ok", False):
        return result

    import os

    output_path = result.get("output_path")
    candidate_paths = [output_path] + list(result.get("candidate_paths") or [])

    glob_patterns: list[str] = []
    if output_path:
        root, _ = os.path.splitext(output_path)
        glob_patterns.append(root + "*.png")

    for directory in result.get("search_dirs") or []:
        glob_patterns.append(os.path.join(directory, "ScreenShot*.png"))
        glob_patterns.append(os.path.join(directory, "Screenshot*.png"))

    found_path, size = _poll_local_screenshot_file(
        candidate_paths,
        wait,
        glob_patterns=glob_patterns,
        modified_after=result.get("request_time"),
    )

    result["wait_seconds"] = wait
    result["found"] = bool(found_path)
    result["exists"] = bool(found_path)
    result["size"] = size

    if found_path and output_path:
        original_found_path = found_path
        try:
            found_path = _move_local_file_to_path(found_path, output_path)
            size = os.path.getsize(found_path)
            result["output_path"] = found_path
            result["size"] = size
            if os.path.normcase(os.path.abspath(original_found_path)) != os.path.normcase(os.path.abspath(found_path)):
                result["moved_from"] = original_found_path
        except OSError as exc:
            result["output_path"] = original_found_path
            result["move_error"] = str(exc)

    return result


@mcp.tool()
def unreal_save_all() -> dict[str, Any]:
    """Save all dirty map and content packages in the editor."""

    code = """
import unreal

saved = unreal.EditorLoadingAndSavingUtils.save_dirty_packages(
    save_map_packages=True,
    save_content_packages=True,
)

_mcp_result = {
    "saved": bool(saved),
}
"""
    return _run_structured_python(code)


@mcp.tool()
def unreal_play_in_editor(mode: str = "play") -> dict[str, Any]:
    """Start Play In Editor or Simulate In Editor.

    Args:
        mode: "play" starts real PIE via editor_request_begin_play (spawns the
            GameMode PlayerController + HUD). "simulate" starts SIE via
            editor_play_simulate (no PlayerController/HUD).
    """

    normalized_mode = (mode or "play").strip().lower()
    if normalized_mode not in {"play", "simulate"}:
        return _tool_error(ValueError('mode must be either "play" or "simulate".'))

    code = f"""
import unreal

mode = {json.dumps(normalized_mode)}

level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
if not level_subsystem:
    raise RuntimeError("LevelEditorSubsystem is unavailable.")

if not hasattr(level_subsystem, "is_in_play_in_editor"):
    raise RuntimeError("LevelEditorSubsystem.is_in_play_in_editor is unavailable.")

was_in_play_in_editor = bool(level_subsystem.is_in_play_in_editor())
requested = False
method = None

if not was_in_play_in_editor:
    if mode == "play":
        method_name = "editor_request_begin_play"
    else:
        method_name = "editor_play_simulate"

    if not hasattr(level_subsystem, method_name):
        raise RuntimeError("LevelEditorSubsystem." + method_name + " is unavailable.")

    getattr(level_subsystem, method_name)()
    method = "LevelEditorSubsystem." + method_name
    requested = True

is_in_play_in_editor = bool(level_subsystem.is_in_play_in_editor())

_mcp_result = {{
    "mode": mode,
    "requested": requested,
    "started": bool(is_in_play_in_editor),
    "was_in_play_in_editor": was_in_play_in_editor,
    "is_in_play_in_editor": is_in_play_in_editor,
    "method": method,
    "note": "play uses editor_request_begin_play for real PIE; simulate uses editor_play_simulate for SIE.",
}}
"""
    return _run_structured_python(code)


@mcp.tool()
def unreal_stop_pie() -> dict[str, Any]:
    """Stop Play In Editor if it is currently running."""

    code = """
import unreal

method = None

try:
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
except Exception:
    level_subsystem = None

if level_subsystem and hasattr(level_subsystem, "editor_end_play"):
    level_subsystem.editor_end_play()
    method = "LevelEditorSubsystem.editor_end_play"
elif hasattr(unreal, "EditorLevelLibrary") and hasattr(unreal.EditorLevelLibrary, "editor_end_play"):
    unreal.EditorLevelLibrary.editor_end_play()
    method = "EditorLevelLibrary.editor_end_play"

if method is None:
    raise RuntimeError("No supported Stop PIE function was found.")

_mcp_result = {
    "stopped": True,
    "method": method,
}
"""
    return _run_structured_python(code)
