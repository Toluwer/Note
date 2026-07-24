#!/usr/bin/env python3
# Regenerate Note's small Lucide registry from the pinned Roblox atlas manifest.

from __future__ import annotations

from pathlib import Path
import json
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
PINNED_COMMIT = "11213a3a4938c5594e0765d8671f2af52c5ab47e"
SOURCE = (
    "https://raw.githubusercontent.com/latte-soft/lucide-roblox/"
    f"{PINNED_COMMIT}/lib/Icons.luau"
)
LUCIDE_VERSION = "0.363.0"
ATLAS_PROVIDER = "latte-soft/lucide-roblox 0.1.3"
ICON_NAMES = [
    "x", "minus", "check", "chevron-down", "chevron-up", "chevron-left",
    "chevron-right", "search", "settings", "sun", "moon", "info", "menu",
    "panel-left", "panel-right", "maximize-2", "minimize-2", "bell",
    "circle-alert", "circle-check", "copy", "trash-2", "plus", "eye",
    "eye-off", "keyboard", "mouse-pointer-2", "grip-horizontal", "palette",
    "paintbrush", "refresh-cw", "external-link", "lock", "unlock",
]

ENTRY = re.compile(
    r'(?:\["(?P<quoted>[^"]+)"\]|(?P<bare>[A-Za-z0-9_-]+))='
    r'\{(?P<id>\d+),\{48,48\},\{(?P<x>\d+),(?P<y>\d+)\}\}'
)

def fetch() -> str:
    request = urllib.request.Request(SOURCE, headers={"User-Agent": "Note UI bundler"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")

def parse(source: str) -> dict[str, dict[str, int]]:
    registry = {}
    for match in ENTRY.finditer(source):
        name = match.group("quoted") or match.group("bare")
        registry[name] = {
            "id": int(match.group("id")),
            "x": int(match.group("x")),
            "y": int(match.group("y")),
            "width": 48,
            "height": 48,
        }
    missing = [name for name in ICON_NAMES if name not in registry]
    if missing:
        raise SystemExit("Missing icons in pinned atlas: " + ", ".join(missing))
    return {name: registry[name] for name in ICON_NAMES}

def render_luau(registry: dict[str, dict[str, int]]) -> str:
    rows = []
    for name, icon in registry.items():
        rows.append(
            f'    ["{name}"] = {{ Id = {icon["id"]}, '
            f'Offset = Vector2.new({icon["x"]}, {icon["y"]}), '
            'Size = Vector2.new(48, 48) },'
        )
    body = "\n".join(rows)
    template = '''local Utilities = require("src/Core/Utilities")

local Icons = {}
local Registry = {
__ROWS__
}

local IconObject = {}
IconObject.__index = IconObject

function IconObject:SetIcon(name)
    local data = Registry[name]
    assert(data, string.format('[Note] Unknown Lucide icon "%s"', tostring(name)))
    self.Name = name
    self.Instance.Name = "Icon_" .. name
    self.Instance.Image = "rbxassetid://" .. data.Id
    self.Instance.ImageRectOffset = data.Offset
    self.Instance.ImageRectSize = data.Size
    return self
end

function IconObject:SetSize(size)
    self.Instance.Size = UDim2.fromOffset(size, size)
    return self
end

function IconObject:SetColor(color)
    self.Instance.ImageColor3 = color
    return self
end

function IconObject:SetTransparency(value)
    self.Instance.ImageTransparency = value
    return self
end

function IconObject:SetVisible(value)
    self.Instance.Visible = value
    return self
end

function IconObject:Destroy()
    if self.Instance then
        self.Instance:Destroy()
        self.Instance = nil
    end
end

function Icons.Has(name)
    return Registry[name] ~= nil
end

function Icons.Get(name)
    return Registry[name]
end

function Icons.Names()
    local names = {}
    for name in pairs(Registry) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function Icons.Create(config)
    config = config or {}
    local name = config.Name or "info"
    local size = config.Size or 18
    local instance = Utilities.Create("ImageLabel", {
        Name = "Icon_" .. name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size, size),
        ImageColor3 = config.Color or Color3.new(1, 1, 1),
        ImageTransparency = config.Transparency or 0,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = config.ZIndex or 1,
        Parent = config.Parent,
    })
    local object = setmetatable({
        Instance = instance,
        Name = name,
    }, IconObject)
    object:SetIcon(name)
    return object
end

Icons.Registry = Registry
Icons.LucideVersion = "__LUCIDE_VERSION__"
Icons.AtlasProvider = "__ATLAS_PROVIDER__"

return Icons
'''
    return (
        template.replace("__ROWS__", body)
        .replace("__LUCIDE_VERSION__", LUCIDE_VERSION)
        .replace("__ATLAS_PROVIDER__", ATLAS_PROVIDER)
    )

def main() -> None:
    registry = parse(fetch())
    manifest = {
        "lucideVersion": LUCIDE_VERSION,
        "atlasProvider": ATLAS_PROVIDER,
        "atlasCommit": PINNED_COMMIT,
        "slotSize": 48,
        "icons": registry,
    }
    (ROOT / "assets/lucide/manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    (ROOT / "src/Core/Icons.lua").write_text(render_luau(registry), encoding="utf-8")
    print(f"Wrote {len(registry)} icon entries")

if __name__ == "__main__":
    main()
