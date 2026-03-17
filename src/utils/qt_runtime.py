"""
Qt runtime bootstrap helpers.

Keeps Qt Quick startup choices deterministic and testable across platforms.
"""

from __future__ import annotations

import ctypes
import os
import sys
from collections.abc import MutableMapping
from dataclasses import dataclass


SAFE_HIDPI_SCALE_THRESHOLD = 125
_GRAPHICS_OVERRIDE_KEYS = (
    "QSG_RHI_BACKEND",
    "QT_OPENGL",
    "QSG_RHI_PREFER_SOFTWARE_RENDERER",
    "QT_QUICK_BACKEND",
)
_PLATFORM_OVERRIDE_KEY = "QT_QPA_PLATFORM"
_PLATFORM_HINT_KEY = "RENLOCALIZER_QT_PLATFORM_HINT"
_RECOVERY_ATTEMPT_KEY = "RENLOCALIZER_QT_RECOVERY_ATTEMPT"
_VALID_RENDER_MODES = {"auto", "native", "opengl", "software"}
_VALID_PLATFORM_MODES = {
    "auto",
    "native",
    "xcb",
    "wayland",
    "xcb;wayland",
    "wayland;xcb",
    "offscreen",
    "minimal",
    "cocoa",
}


@dataclass(frozen=True)
class QtGraphicsBootstrapResult:
    """Describes the effective Qt graphics bootstrap decision."""

    mode: str
    scale_percent: int
    applied: dict[str, str]
    reason: str
    graphics_api: str | None = None
    platform_plugin: str | None = None


def detect_windows_scale_percent() -> int:
    """Return the system DPI scale percentage on Windows."""
    if sys.platform != "win32":
        return 100

    try:
        user32 = ctypes.windll.user32
        if hasattr(user32, "GetDpiForSystem"):
            dpi = int(user32.GetDpiForSystem())
            if dpi > 0:
                return max(100, round((dpi / 96) * 100))

        hdc = user32.GetDC(0)
        try:
            if hdc:
                gdi32 = ctypes.windll.gdi32
                log_pixels_x = 88
                dpi = int(gdi32.GetDeviceCaps(hdc, log_pixels_x))
                if dpi > 0:
                    return max(100, round((dpi / 96) * 100))
        finally:
            if hdc:
                user32.ReleaseDC(0, hdc)
    except Exception:
        return 100

    return 100


def _normalize_requested_mode(requested_mode: str | None) -> str:
    normalized_mode = (requested_mode or "auto").strip().lower()
    if normalized_mode not in _VALID_RENDER_MODES:
        return "auto"
    return normalized_mode


def _normalize_requested_platform(requested_platform: str | None) -> str:
    normalized_platform = (requested_platform or "auto").strip().lower()
    if normalized_platform not in _VALID_PLATFORM_MODES:
        return "auto"
    return normalized_platform


def select_qt_render_mode(
    platform_name: str,
    scale_percent: int,
    requested_mode: str | None = None,
) -> str:
    """Choose the safest render mode for the current platform and environment."""
    normalized_mode = _normalize_requested_mode(requested_mode)
    if normalized_mode != "auto":
        return normalized_mode

    if platform_name == "win32":
        if scale_percent >= SAFE_HIDPI_SCALE_THRESHOLD:
            return "software"
        return "opengl"

    return "native"


def select_windows_qt_render_mode(scale_percent: int, requested_mode: str | None = None) -> str:
    """Choose the safest render mode for the current Windows DPI environment."""
    return select_qt_render_mode(
        platform_name="win32",
        scale_percent=scale_percent,
        requested_mode=requested_mode,
    )


def select_qt_platform_plugin(
    env: MutableMapping[str, str],
    platform_name: str,
    requested_platform: str | None = None,
    frozen: bool = False,
) -> str | None:
    """Choose a conservative Qt platform plugin override when beneficial."""
    normalized_platform = _normalize_requested_platform(requested_platform)
    if normalized_platform == "native":
        return None
    if normalized_platform != "auto":
        return normalized_platform

    if platform_name != "linux":
        return None

    has_display = bool(env.get("DISPLAY"))
    has_wayland = bool(env.get("WAYLAND_DISPLAY")) or env.get("XDG_SESSION_TYPE", "").lower() == "wayland"

    # AppImages commonly trip over Wayland/EGL. Prefer XWayland first when both
    # transports are available, but stay native on pure X11 or pure Wayland.
    if has_display and has_wayland and frozen:
        return "xcb;wayland"

    return None


def resolve_qt_graphics_api(platform_name: str, mode: str) -> str | None:
    """Map the selected mode to the early QQuickWindow graphics API override."""
    if mode == "native":
        return None

    if mode == "opengl":
        return "opengl"

    if mode != "software":
        return None

    if platform_name == "win32":
        # Windows HiDPI fallback intentionally keeps using OpenGL, but with the
        # software rasterizer DLL path for black-window resilience.
        return "opengl"

    return "software"


def _apply_qt_debug_settings(
    env: MutableMapping[str, str],
    applied: dict[str, str],
) -> None:
    if env.get("RENLOCALIZER_QT_DEBUG", "0") == "1" and not env.get("QSG_INFO"):
        env["QSG_INFO"] = "1"
        applied["QSG_INFO"] = "1"


def configure_qt_graphics_environment(
    env: MutableMapping[str, str] | None = None,
    platform_name: str | None = None,
    scale_percent: int | None = None,
    frozen: bool | None = None,
) -> QtGraphicsBootstrapResult:
    """
    Apply conservative Qt Quick rendering defaults across supported platforms.

    Strategy:
    - Respect explicit Qt rendering overrides from the environment.
    - Default to OpenGL on Windows to avoid D3D11-specific black window issues.
    - Escalate to software OpenGL on HiDPI Windows systems where the issue is
      most common.
    - Keep Linux/macOS native by default, but allow conservative platform/plugin
      overrides and a true software scene graph fallback when requested.
    """
    target_env = env if env is not None else os.environ
    effective_platform = platform_name or sys.platform
    effective_frozen = bool(getattr(sys, "frozen", False)) if frozen is None else frozen
    actual_scale = scale_percent if scale_percent is not None else detect_windows_scale_percent()
    applied: dict[str, str] = {}

    existing_platform_plugin = target_env.get(_PLATFORM_OVERRIDE_KEY)

    if any(target_env.get(key) for key in _GRAPHICS_OVERRIDE_KEYS):
        _apply_qt_debug_settings(target_env, applied)
        return QtGraphicsBootstrapResult(
            mode="native",
            scale_percent=actual_scale,
            applied=applied,
            reason="qt graphics env already overridden",
            graphics_api=None,
            platform_plugin=existing_platform_plugin,
        )

    requested_mode = target_env.get("RENLOCALIZER_QT_RENDER_MODE", "")
    requested_platform = target_env.get("RENLOCALIZER_QT_PLATFORM", "")
    requested_platform_hint = target_env.get(_PLATFORM_HINT_KEY, "")
    effective_requested_platform = requested_platform or requested_platform_hint
    effective_mode = select_qt_render_mode(
        platform_name=effective_platform,
        scale_percent=actual_scale,
        requested_mode=requested_mode,
    )
    platform_plugin = existing_platform_plugin or select_qt_platform_plugin(
        env=target_env,
        platform_name=effective_platform,
        requested_platform=effective_requested_platform,
        frozen=effective_frozen,
    )
    graphics_api = resolve_qt_graphics_api(
        platform_name=effective_platform,
        mode=effective_mode,
    )

    if not existing_platform_plugin and platform_plugin:
        target_env[_PLATFORM_OVERRIDE_KEY] = platform_plugin
        applied[_PLATFORM_OVERRIDE_KEY] = platform_plugin

    if graphics_api == "opengl":
        target_env["QSG_RHI_BACKEND"] = "opengl"
        applied["QSG_RHI_BACKEND"] = "opengl"
        if effective_platform == "win32" and effective_mode == "software":
            target_env["QT_OPENGL"] = "software"
            applied["QT_OPENGL"] = "software"
    elif graphics_api == "software":
        target_env["QT_QUICK_BACKEND"] = "software"
        applied["QT_QUICK_BACKEND"] = "software"

    _apply_qt_debug_settings(target_env, applied)

    return QtGraphicsBootstrapResult(
        mode=effective_mode,
        scale_percent=actual_scale,
        applied=applied,
        reason=(
            "automatic safe graphics bootstrap"
            if _normalize_requested_mode(requested_mode) == "auto"
            and _normalize_requested_platform(requested_platform) == "auto"
            else "requested render mode"
        ),
        graphics_api=graphics_api,
        platform_plugin=platform_plugin,
    )


def configure_windows_qt_graphics_environment(
    env: MutableMapping[str, str] | None = None,
    platform_name: str | None = None,
    scale_percent: int | None = None,
    frozen: bool | None = None,
) -> QtGraphicsBootstrapResult:
    """Backward-compatible wrapper around the platform-generic bootstrap."""
    return configure_qt_graphics_environment(
        env=env,
        platform_name=platform_name,
        scale_percent=scale_percent,
        frozen=frozen,
    )


def should_attempt_qt_safe_relaunch(
    env: MutableMapping[str, str] | None = None,
    platform_name: str | None = None,
    bootstrap: QtGraphicsBootstrapResult | None = None,
) -> bool:
    """Return whether the launcher should try a one-shot safe-mode relaunch."""
    target_env = env if env is not None else os.environ
    effective_platform = platform_name or sys.platform
    auto_applied_keys = set(bootstrap.applied) if bootstrap else set()

    if effective_platform not in {"linux", "darwin"}:
        return False

    if target_env.get(_RECOVERY_ATTEMPT_KEY) == "1":
        return False

    if any(target_env.get(key) for key in _GRAPHICS_OVERRIDE_KEYS if key not in auto_applied_keys):
        return False

    if target_env.get(_PLATFORM_OVERRIDE_KEY) and _PLATFORM_OVERRIDE_KEY not in auto_applied_keys:
        return False

    if _normalize_requested_mode(target_env.get("RENLOCALIZER_QT_RENDER_MODE")) != "auto":
        return False

    if _normalize_requested_platform(target_env.get("RENLOCALIZER_QT_PLATFORM")) != "auto":
        return False

    if bootstrap and bootstrap.graphics_api == "software":
        return False

    return True


def build_qt_safe_relaunch_env(
    env: MutableMapping[str, str] | None = None,
    platform_name: str | None = None,
) -> dict[str, str]:
    """Build a sanitized environment for a one-shot Qt safe-mode relaunch."""
    source_env = env if env is not None else os.environ
    effective_platform = platform_name or sys.platform
    safe_env = dict(source_env)

    for key in (*_GRAPHICS_OVERRIDE_KEYS, _PLATFORM_OVERRIDE_KEY, "QSG_INFO"):
        safe_env.pop(key, None)

    safe_env[_RECOVERY_ATTEMPT_KEY] = "1"
    safe_env["RENLOCALIZER_QT_RENDER_MODE"] = "software"
    safe_env.pop("RENLOCALIZER_QT_PLATFORM", None)
    safe_env.pop(_PLATFORM_HINT_KEY, None)

    if effective_platform == "linux":
        if source_env.get("DISPLAY"):
            safe_env[_PLATFORM_OVERRIDE_KEY] = "xcb"
        elif source_env.get("WAYLAND_DISPLAY") or source_env.get("XDG_SESSION_TYPE", "").lower() == "wayland":
            safe_env[_PLATFORM_OVERRIDE_KEY] = "wayland"

    return safe_env
