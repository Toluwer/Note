# Note

Note is a polished, reusable client-side UI library for Roblox Luau. It is designed for LocalScript-style execution and remote loading, while keeping the development source modular and the public distribution in one generated `main.lua`.

```lua
local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()
```

## Features

- Frosted neutral dark and light themes with animated runtime switching
- Built-in theme buttons, optional per-window accent colors, inherited custom themes, and theme signals
- Draggable, optionally resizable windows with real icon-based minimize and close controls
- Tabs, smoothly animated collapsible sections, live search, scrolling, responsive viewport clamping
- Button, toggle, slider, input, searchable dropdown, keybind, color picker, label, paragraph, and divider controls
- Shared overlay system for dropdowns, color pickers, tooltips, notifications, and dialogs
- Centralized input management, callback protection, cleanup ownership, and signals
- Flags and serializable configuration import/export
- Feature-detected GUI protection, `gethui`, `cloneref`, and optional filesystem APIs
- Official Lucide artwork through the pinned `latte-soft/lucide-roblox` atlas
- Deterministic bundler that generates the committed single-file distribution

`Dark` and `Light` intentionally use neutral grayscale defaults. Accent color is opt-in through `Window:SetAccent` or a color picker; the color picker remains a supported built-in component.

## Installation

No Studio package, Rojo project, server script, RemoteEvent, or ReplicatedStorage module is required. Load the generated distribution from a client-side script:

```lua
local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()
```

`main.lua` returns one Note library instance. It initializes its root GUI lazily when the first window, notification, or dialog is created. Explicit initialization is also supported:

```lua
Note:Init({
    Name = "NoteUI",
    Parent = nil,
    ReuseExisting = false,
    DisplayOrder = 1000,
    Theme = "Dark",
    FrostedGlass = true,
    BlurSize = 14,
})
```

## Basic example

```lua
local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

local Window = Note:CreateWindow({
    Title = "Note",
    Subtitle = "Basic example",
    Icon = "panel-left",
    Theme = "Dark",
    Size = UDim2.fromOffset(620, 450),
    MinimumSize = Vector2.new(460, 300),
    Draggable = true,
    Resizable = true,
    ToggleKey = Enum.KeyCode.RightShift,
})

local General = Window:CreateTab({
    Name = "General",
    Icon = "settings",
})

local Main = General:CreateSection({
    Name = "Main",
    Description = "Common controls.",
    Collapsible = true,
})

Main:CreateButton({
    Name = "Run Action",
    Icon = "mouse-pointer-2",
    Callback = function()
        print("Clicked")
    end,
})

Main:CreateToggle({
    Name = "Enabled",
    Flag = "enabled",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

See `examples/showcase.lua` for every component.

## Window API

Create a window with `Note:CreateWindow(config)`.

Common configuration:

| Key | Type | Purpose |
| --- | --- | --- |
| `Title` | `string` | Window title |
| `Subtitle` | `string?` | Secondary title |
| `Icon` | `string?` | Registered Lucide icon |
| `Theme` | `string \| table` | Theme name or custom theme |
| `Accent` | `Color3?` | Per-window accent |
| `Size` | `UDim2` | Initial size |
| `Position` | `UDim2?` | Initial position |
| `MinimumSize` | `Vector2` | Resize lower bound |
| `MaximumSize` | `Vector2` | Resize upper bound |
| `Draggable` | `boolean` | Enable title-bar dragging |
| `Resizable` | `boolean` | Enable lower-right resize handle |
| `MinimizeButton` | `boolean` | Show minimize control |
| `CloseButton` | `boolean` | Show close control |
| `ToggleKey` | `Enum.KeyCode?` | Show/hide key |

Methods:

```lua
Window:CreateTab(config)
Window:SetSearch(query)
Window:SetTitle(text)
Window:SetSubtitle(text)
Window:SetIcon(name)
Window:SetTheme(nameOrTable)
Window:SetAccent(color)
Window:Show()
Window:Hide()
Window:Toggle()
Window:Minimize()
Window:Restore()
Window:ToggleMinimized()
Window:SetSize(size)
Window:SetPosition(position)
Window:Notify(config)
Window:Dialog(config)
Window:ExportConfig()
Window:ImportConfig(config, options)
Window:Close()
Window:Destroy()
```

Signals:

```lua
Window.Closed
Window.Destroyed
Window.ThemeChanged
Window.VisibilityChanged
Window.MinimizedChanged
```

## Tabs

```lua
local Tab = Window:CreateTab({
    Name = "Appearance",
    Icon = "palette",
    Disabled = false,
    Visible = true,
})
```

Methods:

```lua
Tab:CreateSection(config)
Tab:Select()
Tab:SetName(text)
Tab:SetIcon(name)
Tab:SetDisabled(boolean)
Tab:SetVisible(boolean)
Tab:Destroy()
```

Only one valid tab is selected at a time. Destroying the active tab selects another visible, enabled tab when possible.

## Sections

```lua
local Section = Tab:CreateSection({
    Name = "Player",
    Description = "General options.",
    Icon = "settings",
    Collapsible = true,
})
```

Methods:

```lua
Section:SetName(text)
Section:SetDescription(text)
Section:SetCollapsed(boolean)
Section:Toggle()
Section:SetVisible(boolean)
Section:CreateButton(config)
Section:CreateToggle(config)
Section:CreateSlider(config)
Section:CreateInput(config)
Section:CreateDropdown(config)
Section:CreateKeybind(config)
Section:CreateColorpicker(config)
Section:CreateLabel(config)
Section:CreateParagraph(config)
Section:CreateDivider(config)
Section:CreateThemeButtons(config)
Section:CreateThemeSwitcher(config)
Section:Destroy()
```

## Shared component methods

Relevant components inherit:

```lua
Component:SetVisible(boolean)
Component:SetDisabled(boolean)
Component:SetName(text)
Component:SetDescription(text)
Component:SetCallback(callback)
Component:Matches(query)
Component:Destroy()
```

Value controls also expose `SetValue` and `GetValue`.

### Button

```lua
Section:CreateButton({
    Name = "Delete",
    Description = "Runs a protected callback.",
    Icon = "trash-2",
    Style = "Destructive", -- Primary, Secondary, Destructive
    Disabled = false,
    Confirm = {
        Title = "Delete item?",
        Content = "This action cannot be undone.",
        Destructive = true,
    },
    Callback = function() end,
})
```

Methods: `Fire()`, `SetLoading(boolean)`, plus shared methods.

### Toggle

```lua
local Toggle = Section:CreateToggle({
    Name = "Enabled",
    Default = false,
    Flag = "enabled",
    Callback = function(value) end,
})

Toggle:SetValue(true)
Toggle:GetValue()
Toggle:Toggle()
```

### Slider

```lua
local Slider = Section:CreateSlider({
    Name = "Amount",
    Minimum = 0,
    Maximum = 100,
    Default = 50,
    Increment = 0.5,
    Prefix = "",
    Suffix = "%",
    Flag = "amount",
    Callback = function(value) end,
})

Slider:SetValue(75)
Slider:GetValue()
Slider:SetRange(0, 200)
```

Values are clamped and rounded to the configured increment.

### Input

```lua
local Input = Section:CreateInput({
    Name = "Username",
    Placeholder = "Username",
    Default = "",
    CharacterLimit = 24,
    Numeric = false,
    Password = false,
    ClearButton = true,
    Validate = function(value)
        return #value >= 3, "Use at least three characters."
    end,
    Changed = function(value) end,
    Callback = function(value) end,
})

Input:SetValue("Example")
Input:GetValue()
Input:Clear()
Input:Focus()
```

`Callback` runs on submission. `Changed` runs when accepted text changes.

### Dropdown

```lua
local Dropdown = Section:CreateDropdown({
    Name = "Mode",
    Options = { "Standard", "Advanced", "Expert" },
    Default = "Standard",
    Searchable = true,
    Multi = false,
    Callback = function(value) end,
})

Dropdown:SetValue("Advanced")
Dropdown:GetValue()
Dropdown:SetOptions({ "A", "B", "C" })
Dropdown:Open()
Dropdown:Close()
Dropdown:Toggle()
```

The popup is rendered through the shared overlay, tracks its anchor, opens above when required, and closes on outside input.

### Keybind

```lua
local Keybind = Section:CreateKeybind({
    Name = "Toggle Interface",
    Default = Enum.KeyCode.RightShift,
    Mode = "Press", -- Press, Hold, Toggle
    Callback = function(state) end,
    Changed = function(key) end,
})

Keybind:SetValue(Enum.KeyCode.K)
Keybind:GetValue()
Keybind:Clear()
```

Escape cancels capture. Mouse movement and touch movement are not assignable.

### Color picker

```lua
local Picker = Section:CreateColorpicker({
    Name = "Accent",
    Default = Color3.fromRGB(176, 176, 180),
    Alpha = 0,
    ShowAlpha = true,
    Callback = function(color, alpha)
        Window:SetAccent(color)
    end,
})

Picker:SetValue(Color3.fromRGB(176, 176, 180))
Picker:GetValue()
Picker:Open()
Picker:Close()
Picker:Toggle()
```

The overlay includes saturation/value, hue, optional alpha, RGB and hex fields, reset, and outside-click closing.

### Label

```lua
local Label = Section:CreateLabel({
    Text = "A lightweight text row.",
    Style = "Body",
    Alignment = Enum.TextXAlignment.Left,
})

Label:SetText("Updated")
Label:SetValue("Updated")
Label:GetValue()
```

### Paragraph

```lua
local Paragraph = Section:CreateParagraph({
    Title = "About",
    Content = "Note is a modular LocalScript UI library written in Luau.",
})

Paragraph:SetContent("Updated body")
Paragraph:SetValue("Updated body")
Paragraph:GetValue()
```

### Divider

```lua
Section:CreateDivider({
    Text = "Advanced",
    Spacing = 8,
})
```

## Search

Set `Search = true` on a window to show its search field. Search matches component names, descriptions, and section names without changing component state:

```lua
Window:SetSearch("speed")
Window:SetSearch("")
```

## Themes

Built-in themes:

- `Dark` — neutral charcoal and gray surfaces
- `Light` — neutral white and gray surfaces

Both built-in themes avoid colored or neon surface treatments. Accent color changes are optional. `Window:SetTheme` resets the accent to the selected theme by default, so every token changes together. Pass `{ PreserveAccent = true }` only when a custom accent should remain.

Add ready-made theme buttons:

```lua
ThemeSection:CreateThemeButtons({
    Name = "Interface Theme",
    Themes = { "Dark", "Light" },
    ResetAccent = true,
})
```

```lua
Window:SetTheme("Light")
Window:SetTheme("Dark")
Window:SetAccent(Color3.fromRGB(176, 176, 180))
```

Register an inherited theme:

```lua
Note:RegisterTheme("Midnight", {
    Inherits = "Dark",
    Name = "Midnight",
    Background = Color3.fromRGB(13, 14, 18),
    Surface = Color3.fromRGB(20, 21, 27),
    SurfaceHover = Color3.fromRGB(28, 29, 37),
    Border = Color3.fromRGB(42, 44, 55),
    Text = Color3.fromRGB(240, 241, 245),
    TextMuted = Color3.fromRGB(155, 158, 171),
    Accent = Color3.fromRGB(176, 176, 180),
})

Window:SetTheme("Midnight")
```

A custom table can also be passed directly to `Window:SetTheme`. Missing tokens inherit from its `Inherits` theme or the default theme.

## Frosted glass

Frosted glass is enabled by default using translucent UI surfaces only. Note does not create a `BlurEffect`, modify `Lighting`, or blur the game view.

```lua
Note:SetFrostedGlass(true)
Note:SetFrostedGlass(false)
```

Set `FrostedGlass = false` during `Note:Init`, or call `Note:SetFrostedGlass(false)`, to make the glass surfaces opaque.

## Lucide icons

`src/Core/Icons.lua` contains a centralized registry for the icons used by Note. It uses exact atlas IDs and `ImageRectOffset` values from `latte-soft/lucide-roblox` 0.1.3, whose generated atlas is based on Lucide 0.363.0. The icon artwork remains official Lucide artwork; no text glyphs or imitations are used.

```lua
local names = Note:GetIcons()
```

An icon object supports:

```lua
Icon:SetIcon("moon")
Icon:SetSize(20)
Icon:SetColor(Color3.new(1, 1, 1))
Icon:SetTransparency(0.2)
Icon:SetVisible(true)
Icon:Destroy()
```

Licensing and source details are in `assets/lucide/`.

## Notifications

```lua
local Notification = Note:Notify({
    Title = "Loaded",
    Content = "Note loaded successfully.",
    Type = "Success", -- Info, Success, Warning, Error
    Duration = 4,
})

Notification:Dismiss()
```

Notifications size themselves from their title and content, wrap longer messages into additional height, stack inside the viewport, animate in and out, and support manual dismissal. They have no leading status icon or progress strip.

## Dialogs

```lua
Window:Dialog({
    Title = "Reset settings?",
    Content = "This action cannot be undone.",
    Icon = "circle-alert",
    Buttons = {
        { Name = "Cancel", Style = "Secondary" },
        {
            Name = "Reset",
            Style = "Destructive",
            Callback = function()
                print("Reset confirmed")
            end,
        },
    },
    Callback = function(result)
        print("Closed with:", result)
    end,
})
```

Only the active dialog captures interaction. Escape and the close icon dismiss it.

## Tooltips

Title-bar controls and icon-only elements use the centralized tooltip manager. Internal and custom targets can be registered with:

```lua
local unregister = Note.Tooltip:Register(guiObject, "Tooltip text", Window.ThemeManager)
unregister()
```

## Flags and configuration

```lua
Section:CreateToggle({
    Name = "Enabled",
    Flag = "enabled",
    Default = false,
})

print(Note.Flags.enabled)
Note:SetFlag("enabled", true)

local config = Window:ExportConfig()
Window:ImportConfig(config)
```

Serializable values include primitives, tables, `Color3`, and enum items. Callbacks are never exported.

Optional filesystem adapters are available only when the runtime provides compatible functions:

```lua
Note:WriteConfig("Note/config.json")
Note:ReadConfig("Note/config.json")
```

Check availability first:

```lua
local capabilities = Note:GetCapabilities()
print(capabilities.filesystem)
```

## Cleanup

Every major object owns its resources. Destruction is idempotent.

```lua
Component:Destroy()
Tab:Destroy()
Window:Destroy()
Note:Destroy()
```

Destroying Note removes every Note-owned window, overlay, notification, dialog, global input connection, theme binding, tween, and the owned root GUI.

## Compatibility

The compatibility layer feature-detects:

- `gethui`
- `protect_gui`
- `syn.protect_gui`
- `cloneref`
- `writefile`
- `readfile`
- `isfile`
- `isfolder`
- `makefolder`
- `getcustomasset` / `getsynasset`

A custom parent always takes precedence. Otherwise Note prefers `gethui`, attempts `CoreGui`, and falls back to the local player's `PlayerGui` when the preferred parent is not writable. Optional functions are never hard dependencies.

## Project structure

```text
Note/
├── main.lua
├── README.md
├── LICENSE
├── CHANGELOG.md
├── examples/
├── src/
│   ├── init.lua
│   ├── Note.lua
│   ├── Types.lua
│   ├── Core/
│   ├── Components/
│   ├── Internal/
│   └── Themes/
├── assets/lucide/
└── tools/
```

## Building `main.lua`

The modular source under `src/` is the source of truth.

```bash
python tools/bundle.py
```

The deterministic bundler:

1. Discovers every `.lua` file under `src/`.
2. Assigns each file its repository-relative module ID.
3. Wraps each module in an internal loader table.
4. Adds cached local `require` resolution.
5. Appends `return __require("src/init")`.
6. Applies deterministic LZSS packing and Base64 encoding.
7. Writes a small self-decoding Luau loader and the generated-file header to `main.lua`.

The compressed distribution still contains the entire bundled module graph and does not fetch or require repository files at runtime.

Check the generated build and module graph:

```bash
python tools/check.py
```

## Limitations

- Roblox GUI rendering controls antialiasing. Note uses `UICorner`, integer-conscious geometry, correct clipping, and atlas slicing; it does not claim custom per-pixel antialiasing.
- Atlas image availability is controlled by Roblox. Runtime visual verification is still required when Roblox changes asset delivery behavior.
- Touch interaction is supported for dragging, sliders, resizing, and picker controls where practical, but device-specific testing is recommended.
- Filesystem persistence is optional and unavailable in standard runtimes that do not expose compatible functions.
- This initial release is statically reviewed and bundled outside a live Roblox client; final behavior should be verified in the exact client runtime where it will be used.

## License

Note is released under the MIT License. Lucide artwork and atlas attribution are preserved separately under `assets/lucide/`.
