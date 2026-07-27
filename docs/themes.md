# Built-in themes

Note 0.5.0 includes a broad collection of complete, fixed interface themes. They are registered alongside `Dark` and `Light`; they are not components and they do not insert controls into a window.

## Apply a theme

Choose a theme while creating the library or window:

```lua
Note:Init({
    Theme = "Pink",
})

local Window = Note:CreateWindow({
    Title = "Example",
    Theme = "Pink",
})
```

Change it later through the window API:

```lua
Window:SetTheme("Blue")
Window:SetTheme("Emerald")
Window:SetTheme("Black")
```

No theme buttons appear automatically. A script must explicitly create its own button, dropdown, command, or other control when it wants users to change themes.

## Available names

### Neutral

- `Dark`
- `Light`
- `Black`
- `White`
- `Graphite`
- `Slate`
- `Silver`

### Red and orange

- `Red`
- `Scarlet`
- `Crimson`
- `Maroon`
- `Coral`
- `Orange`
- `Tangerine`

### Yellow and earth

- `Amber`
- `Gold`
- `Yellow`
- `Olive`
- `Peach`
- `Brown`
- `Copper`
- `Bronze`

### Green

- `Lime`
- `Green`
- `Forest`
- `Emerald`
- `Jade`
- `Mint`
- `Teal`
- `Turquoise`

### Blue

- `Cyan`
- `Aqua`
- `Sky`
- `Blue`
- `Navy`
- `Indigo`
- `Periwinkle`

### Purple and pink

- `Violet`
- `Purple`
- `Lavender`
- `Lilac`
- `Fuchsia`
- `Magenta`
- `Pink`
- `Rose`
- `Plum`

## Retrieve the registry

```lua
local names = Note:GetThemeNames()

for _, themeName in ipairs(names) do
    print(themeName)
end
```

Custom themes registered through `Note:RegisterTheme()` are appended to this list.

## Fixed palettes

Each preset contains its own background, surface, input, border, text, selection, scrollbar, status, and transparency values. The preset color is part of that complete named theme; it is not a runtime accent override.

The color picker remains a standalone `Color3` value control. Selecting a color does not alter the window theme.

See `examples/themes.lua` for a test gallery built entirely from ordinary `CreateButton` controls.
