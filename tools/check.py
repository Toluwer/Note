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
