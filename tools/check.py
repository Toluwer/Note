#!/usr/bin/env python3
# Static consistency checks for the Note source tree and generated bundle.

from __future__ import annotations

import importlib.util
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
BUNDLE = ROOT / "main.lua"

REQUIRE = re.compile(r"require\(\s*['\"]([^'\"]+)['\"]\s*\)")
ASSET = re.compile(r'rbxassetid://(\d+)')


def fail(message: str) -> None:
    raise SystemExit(f"check failed: {message}")


def load_bundler():
    spec = importlib.util.spec_from_file_location("note_bundle", ROOT / "tools" / "bundle.py")
    if spec is None or spec.loader is None:
        fail("could not load tools/bundle.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> None:
    modules = {
        path.relative_to(ROOT).with_suffix("").as_posix(): path
        for path in SRC.rglob("*.lua")
    }
    if "src/init" not in modules:
        fail("src/init.lua is missing")

    for module, path in sorted(modules.items()):
        text = path.read_text(encoding="utf-8")
        for dependency in REQUIRE.findall(text):
            if dependency not in modules:
                fail(f"{module} requires missing module {dependency}")
        if "TODO" in text or "PSEUDOCODE" in text:
            fail(f"{module} contains unfinished marker")
        for asset in ASSET.findall(text):
            if not asset.isdigit() or int(asset) <= 0:
                fail(f"{module} contains invalid asset id {asset}")

    note_source = (SRC / "Note.lua").read_text(encoding="utf-8")
    required_note_methods = {
        "Note:CreateWindow",
        "Note:_registerWindow",
        "Note:_unregisterWindow",
        "Note:_registerFlag",
        "Note:_unregisterFlag",
        "Note:_layoutNotifications",
        "Note:_removeNotification",
        "Note:_removeDialog",
        "Note:ExportConfig",
        "Note:ImportConfig",
        "Note:Destroy",
    }
    missing_note_methods = sorted(
        method for method in required_note_methods
        if f"function {method}" not in note_source
    )
    if missing_note_methods:
        fail("src/Note.lua is missing runtime methods: " + ", ".join(missing_note_methods))
    if 'Version = "0.4.0"' not in note_source:
        fail("src/Note.lua is not version 0.4.0")

    section_source = (SRC / "Components" / "Section.lua").read_text(encoding="utf-8")
    required_section_factories = {
        "Section:CreateProgressBar",
        "Section:CreateDataTable",
        "Section:CreateContextMenu",
        "Section:CreateCommandPalette",
    }
    missing_factories = sorted(
        method for method in required_section_factories
        if f"function {method}" not in section_source
    )
    if missing_factories:
        fail("Section.lua is missing advanced factories: " + ", ".join(missing_factories))

    combined_source = "\n".join(
        path.read_text(encoding="utf-8") for path in SRC.rglob("*.lua")
    )
    showcase_source = (ROOT / "examples" / "showcase.lua").read_text(encoding="utf-8")

    forbidden_accent_api = {
        "SetAccent",
        "ClearAccent",
        "ResetAccent",
        "PreserveAccent",
        "config.Accent",
        "_accentOverride",
    }
    remaining_accent_api = sorted(
        token for token in forbidden_accent_api
        if token in combined_source or token in showcase_source
    )
    if remaining_accent_api:
        fail("runtime accent override API returned: " + ", ".join(remaining_accent_api))
    if "no connection to the interface theme" not in showcase_source:
        fail("showcase color input must remain separate from interface themes")
    if "ColorInput:CreateColorpicker" not in showcase_source:
        fail("showcase color picker is not owned by its standalone section")

    animation_guards = {
        SRC / "Components" / "Button.lua": ("pressScale", "UIScale"),
        SRC / "Components" / "Window.lua": ("_minimizeRevision", "PlaybackState.Completed"),
        SRC / "Components" / "Dropdown.lua": ("AnchorTracking", "_popupRevision"),
        SRC / "Components" / "ColorpickerSmooth.lua": ("CanvasGroup", "fade.Completed"),
        SRC / "Components" / "CommandPaletteHeadless.lua": (
            "BindActionAtPriority",
            "ContextActionService",
        ),
        SRC / "Components" / "ProgressBar.lua": (
            "_indeterminateRevision",
            "Animation:Cancel",
        ),
        SRC / "Components" / "Section.lua": (
            "_collapseRevision",
            "PlaybackState.Completed",
        ),
    }
    for path, required_tokens in animation_guards.items():
        text = path.read_text(encoding="utf-8")
        missing_tokens = [token for token in required_tokens if token not in text]
        if missing_tokens:
            fail(
                f"{path.relative_to(ROOT)} lost animation safety tokens: "
                + ", ".join(missing_tokens)
            )

    tab_source = (SRC / "Components" / "Tab.lua").read_text(encoding="utf-8")
    split_layout_tokens = {
        'Layout = normalizeLayout',
        'StackAt = tonumber',
        'LeftColumn',
        'RightColumn',
        'function Tab:SetLayout',
        'function Tab:SetSplitEnabled',
        'function Tab:SetStackBreakpoint',
        'function section:SetSide',
        'function section:GetSide',
    }
    missing_split_tokens = sorted(token for token in split_layout_tokens if token not in tab_source)
    if missing_split_tokens:
        fail("Tab.lua lost split-layout support: " + ", ".join(missing_split_tokens))

    split_example = (ROOT / "examples" / "split-layout.lua").read_text(encoding="utf-8")
    for token in ('Layout = "Split"', 'Side = "Left"', 'Side = "Right"', 'StackAt = nil'):
        if token not in split_example:
            fail(f"split-layout example is missing {token}")

    bundler = load_bundler()
    expected = bundler.build()
    before = BUNDLE.read_text(encoding="utf-8") if BUNDLE.exists() else None
    subprocess.run([sys.executable, str(ROOT / "tools" / "bundle.py")], check=True)
    after = BUNDLE.read_text(encoding="utf-8")
    if before is not None and before != after:
        fail("main.lua was stale; it has been regenerated")
    if after != expected:
        fail("main.lua does not match deterministic bundler output")

    source = bundler.build_source()
    if source.count('__modules["') != len(modules):
        fail("generated source module count does not match source tree")
    if 'return __require("src/init")' not in source:
        fail("generated source has no entry point")

    required = {
        "Button", "Toggle", "Slider", "Input", "Dropdown", "Keybind",
        "Colorpicker", "Label", "Paragraph", "Divider", "Notification",
        "Dialog", "Tooltip", "Window", "Tab", "Section", "ThemeSwitcher",
        "ProgressBar", "DataTable", "ContextMenu", "CommandPalette",
    }
    component_names = {path.stem for path in (SRC / "Components").glob("*.lua")}
    missing = required - component_names
    if missing:
        fail("missing components: " + ", ".join(sorted(missing)))

    print(
        f"OK: {len(modules)} modules, {len(source):,}-byte bundled source, "
        f"{len(after):,}-byte standalone distribution"
    )


if __name__ == "__main__":
    main()
