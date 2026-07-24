local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

local Window = Note:CreateWindow({
    Title = "Theme Lab",
    Subtitle = "Neutral dark and light themes",
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
    Description = "Switch between the neutral built-in themes or choose an accent color.",
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

Theme:CreateColorpicker({
    Name = "Accent Color",
    Description = "Accent colors are optional; the default themes remain neutral.",
    Default = Color3.fromRGB(176, 176, 180),
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

Theme:CreateParagraph({
    Title = "Theme behavior",
    Content = "Dark and Light use grayscale surfaces by default. The color picker changes only the optional accent color.",
})
