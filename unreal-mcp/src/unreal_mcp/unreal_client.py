"""HTTP client for Unreal Engine Remote Control API.

The client intentionally stays small: it wraps the Remote Control HTTP
endpoints, normalizes common failure modes, and provides a structured Python
execution helper through PythonScriptPlugin.ExecutePythonCommandEx.
"""

from __future__ import annotations

import json
import os
import re
import textwrap
from dataclasses import dataclass
from typing import Any, Iterator

import httpx

DEFAULT_BASE_URL = "http://127.0.0.1:30010"
DEFAULT_TIMEOUT = 15.0

PYTHON_LIBRARY_OBJECT = "/Script/PythonScriptPlugin.Default__PythonScriptLibrary"
_RESULT_START = "__UNREAL_MCP_RESULT_START__"
_RESULT_END = "__UNREAL_MCP_RESULT_END__"
_RESULT_RE = re.compile(
    re.escape(_RESULT_START) + r"(.*?)" + re.escape(_RESULT_END),
    re.DOTALL,
)


class UnrealRemoteError(RuntimeError):
    """Base exception for Unreal Remote Control failures."""


class UnrealConfigurationError(UnrealRemoteError):
    """Raised when unreal-mcp configuration is invalid."""


class UnrealConnectionError(UnrealRemoteError):
    """Raised when the Unreal Remote Control server cannot be reached."""


class UnrealHTTPError(UnrealRemoteError):
    """Raised when Unreal Remote Control returns a non-success status code."""

    def __init__(self, status_code: int, response_text: str, url: str) -> None:
        self.status_code = status_code
        self.response_text = response_text
        self.url = url
        super().__init__(
            f"Unreal Remote Control returned HTTP {status_code} for {url}: "
            f"{_trim(response_text)}"
        )


class UnrealPythonExecutionError(UnrealRemoteError):
    """Raised when editor-side Python reports an execution error."""


@dataclass(frozen=True)
class UnrealRemoteConfig:
    """Configuration for connecting to the Unreal Remote Control API."""

    base_url: str = DEFAULT_BASE_URL
    timeout: float = DEFAULT_TIMEOUT

    @classmethod
    def from_env(cls) -> "UnrealRemoteConfig":
        """Build configuration from environment variables."""

        base_url = os.getenv("UNREAL_RC_HTTP_URL", DEFAULT_BASE_URL).strip()
        if not base_url:
            raise UnrealConfigurationError("UNREAL_RC_HTTP_URL cannot be empty.")

        timeout_raw = os.getenv("UNREAL_RC_TIMEOUT", str(DEFAULT_TIMEOUT)).strip()
        try:
            timeout = float(timeout_raw)
        except ValueError as exc:
            raise UnrealConfigurationError(
                f"UNREAL_RC_TIMEOUT must be a number of seconds, got {timeout_raw!r}."
            ) from exc

        if timeout <= 0:
            raise UnrealConfigurationError("UNREAL_RC_TIMEOUT must be greater than 0.")

        return cls(base_url=base_url.rstrip("/"), timeout=timeout)


class UnrealRemoteClient:
    """Small httpx wrapper around Unreal Engine Remote Control HTTP endpoints."""

    def __init__(self, base_url: str = DEFAULT_BASE_URL, timeout: float = DEFAULT_TIMEOUT) -> None:
        if not base_url:
            raise UnrealConfigurationError("Remote Control base URL cannot be empty.")
        if timeout <= 0:
            raise UnrealConfigurationError("Remote Control timeout must be greater than 0.")

        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    @classmethod
    def from_env(cls) -> "UnrealRemoteClient":
        """Create a client using UNREAL_RC_HTTP_URL and UNREAL_RC_TIMEOUT."""

        config = UnrealRemoteConfig.from_env()
        return cls(base_url=config.base_url, timeout=config.timeout)

    def info(self) -> dict[str, Any]:
        """Return GET /remote/info."""

        return self._request("GET", "/remote/info")

    def call_function(
        self,
        object_path: str,
        function_name: str,
        parameters: dict[str, Any] | None = None,
        generate_transaction: bool = True,
    ) -> dict[str, Any]:
        """Call a UFUNCTION through PUT /remote/object/call."""

        if not object_path:
            raise UnrealRemoteError("object_path is required.")
        if not function_name:
            raise UnrealRemoteError("function_name is required.")
        if parameters is None:
            parameters = {}
        if not isinstance(parameters, dict):
            raise UnrealRemoteError("parameters must be a JSON object.")

        body = {
            "objectPath": object_path,
            "functionName": function_name,
            "parameters": parameters,
            "generateTransaction": bool(generate_transaction),
        }
        return self._request("PUT", "/remote/object/call", json_body=body)

    def get_property(self, object_path: str, property_name: str) -> dict[str, Any]:
        """Read a UObject property through PUT /remote/object/property."""

        if not object_path:
            raise UnrealRemoteError("object_path is required.")
        if not property_name:
            raise UnrealRemoteError("property_name is required.")

        body = {
            "objectPath": object_path,
            "propertyName": property_name,
            "access": "READ_ACCESS",
        }
        return self._request("PUT", "/remote/object/property", json_body=body)

    def set_property(
        self,
        object_path: str,
        property_name: str,
        value: Any,
        generate_transaction: bool = True,
    ) -> dict[str, Any]:
        """Write a UObject property through PUT /remote/object/property."""

        if not object_path:
            raise UnrealRemoteError("object_path is required.")
        if not property_name:
            raise UnrealRemoteError("property_name is required.")

        body = {
            "objectPath": object_path,
            "propertyName": property_name,
            "access": "WRITE_ACCESS",
            "propertyValue": value,
            "generateTransaction": bool(generate_transaction),
        }
        return self._request("PUT", "/remote/object/property", json_body=body)

    def describe(self, object_path: str) -> dict[str, Any]:
        """Describe a UObject through PUT /remote/object/describe.

        Returns the object's name, class, full property list (name/type/
        container) and callable functions. This is the fastest way to discover
        an object's complete reflected surface without loading it editor-side.
        """

        if not object_path:
            raise UnrealRemoteError("object_path is required.")

        return self._request("PUT", "/remote/object/describe", json_body={"objectPath": object_path})

    def run_python(self, code: str) -> dict[str, Any]:
        """Execute Python in the Unreal Editor and return structured output.

        The code is wrapped editor-side so stdout, expression result, and
        traceback are serialized into a sentinel-delimited JSON payload. If the
        payload cannot be found, the raw Remote Control response is still
        returned with a warning.
        """

        if not isinstance(code, str):
            raise UnrealRemoteError("code must be a string.")

        wrapped_code = self._build_python_wrapper(code)
        parameters = {
            "PythonCommand": wrapped_code,
            "ExecutionMode": "ExecuteFile",
            "FileExecutionScope": "Public",
        }

        try:
            response = self.call_function(
                PYTHON_LIBRARY_OBJECT,
                "ExecutePythonCommandEx",
                parameters=parameters,
                generate_transaction=False,
            )
        except UnrealHTTPError as first_error:
            response = self._fallback_execute_python_command(wrapped_code, first_error)

        response_text = _collect_response_text(response)
        payload = _parse_execution_payload(response_text)
        if payload is not None:
            payload["raw_response"] = response
            return payload

        ok = _infer_command_succeeded(response)
        return {
            "ok": ok,
            "stdout": response_text,
            "result": _extract_return_value(response),
            "error": None
            if ok
            else "Python command did not report success. Inspect raw_response.",
            "traceback": None,
            "raw_response": response,
            "warning": (
                "Could not find the unreal-mcp execution payload in the Remote Control "
                "response. The command may have run, but stdout/result capture was unavailable."
            ),
        }

    def _fallback_execute_python_command(
        self, wrapped_code: str, first_error: UnrealHTTPError
    ) -> dict[str, Any]:
        """Fallback for older PythonScriptPlugin builds without ExecutePythonCommandEx."""

        try:
            return self.call_function(
                PYTHON_LIBRARY_OBJECT,
                "ExecutePythonCommand",
                parameters={"PythonCommand": wrapped_code},
                generate_transaction=False,
            )
        except UnrealRemoteError as fallback_error:
            raise UnrealRemoteError(
                "Failed to execute Python through ExecutePythonCommandEx "
                f"({first_error}) and fallback ExecutePythonCommand ({fallback_error}). "
                "Verify that the Python Editor Script Plugin is enabled and the editor was restarted."
            ) from fallback_error

    def _request(
        self,
        method: str,
        path: str,
        json_body: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Send one HTTP request and normalize Remote Control failures."""

        url = f"{self.base_url}{path}"
        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.request(method, url, json=json_body)
        except httpx.TimeoutException as exc:
            raise UnrealConnectionError(
                f"Timed out after {self.timeout:.1f}s talking to Unreal Remote Control at {url}. "
                "Check that the UE5 Editor is responsive and increase UNREAL_RC_TIMEOUT for slow operations."
            ) from exc
        except httpx.RequestError as exc:
            raise UnrealConnectionError(
                f"Could not reach Unreal Remote Control at {url}: {exc}. "
                "Verify the UE5 Editor is running, Remote Control API is enabled, "
                "and the web server is listening on the configured URL."
            ) from exc

        if response.status_code < 200 or response.status_code >= 300:
            raise UnrealHTTPError(response.status_code, response.text, url)

        if not response.content:
            return {}

        try:
            data = response.json()
        except json.JSONDecodeError:
            return {"text": response.text}

        if isinstance(data, dict):
            return data
        return {"data": data}

    @staticmethod
    def _build_python_wrapper(code: str) -> str:
        """Return editor-side Python that captures stdout, result, and traceback."""

        return textwrap.dedent(
            f"""
            import ast as __mcp_ast
            import contextlib as __mcp_contextlib
            import io as __mcp_io
            import json as __mcp_json
            import traceback as __mcp_traceback

            __mcp_code = {code!r}
            __mcp_stdout = __mcp_io.StringIO()
            __mcp_payload = None

            try:
                __mcp_globals = globals()
                __mcp_exec_globals = __mcp_globals.setdefault("__unreal_mcp_state__", {{}})
                __mcp_exec_globals.setdefault("__name__", "__unreal_mcp__")
                __mcp_exec_globals.setdefault("__builtins__", __builtins__)
                __mcp_exec_globals.pop("_mcp_result", None)
                __mcp_exec_globals.pop("result", None)

                with __mcp_contextlib.redirect_stdout(__mcp_stdout), __mcp_contextlib.redirect_stderr(__mcp_stdout):
                    __mcp_tree = __mcp_ast.parse(__mcp_code, "<unreal-mcp>", "exec")
                    __mcp_result = None

                    if __mcp_tree.body and isinstance(__mcp_tree.body[-1], __mcp_ast.Expr):
                        __mcp_expr = __mcp_tree.body.pop()
                        __mcp_ast.fix_missing_locations(__mcp_tree)
                        exec(compile(__mcp_tree, "<unreal-mcp>", "exec"), __mcp_exec_globals, __mcp_exec_globals)

                        __mcp_expr_tree = __mcp_ast.Expression(__mcp_expr.value)
                        __mcp_ast.fix_missing_locations(__mcp_expr_tree)
                        __mcp_result = eval(
                            compile(__mcp_expr_tree, "<unreal-mcp>", "eval"),
                            __mcp_exec_globals,
                            __mcp_exec_globals,
                        )
                    else:
                        exec(compile(__mcp_tree, "<unreal-mcp>", "exec"), __mcp_exec_globals, __mcp_exec_globals)
                        __mcp_result = __mcp_exec_globals.get(
                            "_mcp_result",
                            __mcp_exec_globals.get("result"),
                        )

                try:
                    __mcp_json.dumps(__mcp_result)
                    __mcp_serialized_result = __mcp_result
                except TypeError:
                    __mcp_serialized_result = repr(__mcp_result)

                __mcp_payload = {{
                    "ok": True,
                    "stdout": __mcp_stdout.getvalue(),
                    "result": __mcp_serialized_result,
                    "error": None,
                    "traceback": None,
                }}
            except Exception as __mcp_exc:
                __mcp_payload = {{
                    "ok": False,
                    "stdout": __mcp_stdout.getvalue(),
                    "result": None,
                    "error": type(__mcp_exc).__name__ + ": " + str(__mcp_exc),
                    "traceback": __mcp_traceback.format_exc(),
                }}

            print(
                "{_RESULT_START}"
                + __mcp_json.dumps(__mcp_payload, default=str)
                + "{_RESULT_END}"
            )
            """
        ).strip()


def _collect_response_text(value: Any) -> str:
    """Collect all strings from a JSON response into searchable text."""

    return "\n".join(_collect_strings(value))


def _collect_strings(value: Any) -> Iterator[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from _collect_strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from _collect_strings(item)


def _parse_execution_payload(text: str) -> dict[str, Any] | None:
    """Parse the last valid sentinel-delimited JSON payload from response text."""

    matches = _RESULT_RE.findall(text)
    for candidate in reversed(matches):
        try:
            payload = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        if isinstance(payload, dict) and "ok" in payload:
            return payload
    return None


def _extract_return_value(response: Any) -> Any:
    if isinstance(response, dict):
        for key in ("ReturnValue", "returnValue", "return_value", "result", "Result"):
            if key in response:
                return response[key]
    return response


def _infer_command_succeeded(response: Any) -> bool:
    text = _collect_response_text(response).lower()
    if "failed" in text or "failure" in text or "traceback" in text:
        return False
    return True


def _trim(text: str, limit: int = 2000) -> str:
    stripped = text.strip()
    if len(stripped) <= limit:
        return stripped
    return stripped[:limit] + "... [truncated]"
