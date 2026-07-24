local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:RegisterTheme("Midnight", {
    Inherits = "Dark",
    Name = "Midnight",
    Background = Color3.fromRGB(13, 14, 18),
    Surface = Color3.fromRGB(20, 21, 27),
    SurfaceElevated = Color3.fromRGB(24, 25, 32),
    SurfaceHover = Color3.fromRGB(28, 29, 37),
    Border = Color3.fromRGB(42, 44, 55),
    Text = Color3.fromRGB(240, 241, 245),
    TextSecondary = Color3.fromRGB(185, 188, 198),
    TextMuted = Color3.fromRGB(145, 148, 162),
    Accent = Color3.fromRGB(176, 176, 180),
})

local Window = Note:CreateWindow({
    Title = "Theme Lab",
    Subtitle = "Dark, light, accent, and inheritance",
    Icon = "palette",
    Theme = "Dark",
    Accent = Color3.fromRGB(176, 176, 180),
    Size = UDim2.fromOffset(620, 450),
})

local Appearance = Window:CreateTab({
    Name = "Appearance",
    Icon = "paintbrush",
})

local Theme = Appearance:CreateSection({
    Name = "Theme",
    Description = "Changes every bound visual token at runtime.",
})

Theme:CreateButton({
    Name = "Use Dark Theme",
    Icon = "moon",
    Callback = function()
        Window:SetTheme("Dark")
    end,
})

Theme:CreateButton({
    Name = "Use Light Theme",
    Icon = "sun",
    Callback = function()
        Window:SetTheme("Light")
    end,
})

Theme:CreateButton({
    Name = "Use Midnight Theme",
    Icon = "palette",
    Callback = function()
        Window:SetTheme("Midnight")
    end,
})

Theme:CreateColorpicker({
    Name = "Accent Color",
    Description = "Applies a custom per-window accent.",
    Default = Color3.fromRGB(176, 176, 180),
    Callback = function(color)
        Window:SetAccent(color)
    end,
})
