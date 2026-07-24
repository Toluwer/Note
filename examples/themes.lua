local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:Init({
    Theme = "Dark",
    FrostedGlass = true,
    BlurSize = 14,
})

local Window = Note:CreateWindow({
    Title = "Theme Lab",
    Subtitle = "Frosted neutral dark and light themes",
    Icon = "palette",
    Theme = "Dark",
    Size = UDim2.fromOffset(620, 450),
    Draggable = true,
    Resizable = true,
})

local Appearance = Window:CreateTab({
    Name = "Appearance",
    Icon = "paintbrush",
})

local Theme = Appearance:CreateSection({
    Name = "Theme",
    Description = "Switch every theme token or choose an optional custom accent.",
})

Theme:CreateThemeButtons({
    Name = "Interface Theme",
    Description = "Dark and Light reset the complete palette, including the accent.",
    Themes = { "Dark", "Light" },
    ResetAccent = true,
})

Theme:CreateColorpicker({
    Name = "Accent Color",
    Description = "The picker remains available for an optional custom accent.",
    Default = Color3.fromRGB(190, 190, 194),
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

Theme:CreateButton({
    Name = "Reset Theme Accent",
    Icon = "rotate-ccw",
    Callback = function()
        Window:ClearAccent()
    end,
})

Theme:CreateParagraph({
    Title = "Frosted glass",
    Content = "Note uses translucent theme surfaces plus an owned BlurEffect. Call Note:SetFrostedGlass(false) to disable it.",
})
