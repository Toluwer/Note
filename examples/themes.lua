local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:Init({
    Theme = "Dark",
    FrostedGlass = true,
})

local Window = Note:CreateWindow({
    Title = "Theme Gallery",
    Subtitle = "Built-in fixed color themes",
    Icon = "palette",
    Theme = "Dark",
    Size = UDim2.fromOffset(760, 560),
    MinimumSize = Vector2.new(520, 360),
    MaximumSize = Vector2.new(980, 760),
    Draggable = true,
    Resizable = true,
    Search = true,
})

local Themes = Window:CreateTab({
    Name = "Themes",
    Icon = "paintbrush",
    Layout = "Split",
    SplitGap = 10,
    StackAt = 520,
})

local families = {
    {
        Name = "Neutral",
        Side = "Left",
        Themes = { "Dark", "Light", "Black", "White", "Graphite", "Slate", "Silver" },
    },
    {
        Name = "Red and Orange",
        Side = "Left",
        Themes = { "Red", "Scarlet", "Crimson", "Maroon", "Coral", "Orange", "Tangerine" },
    },
    {
        Name = "Yellow and Earth",
        Side = "Left",
        Themes = { "Amber", "Gold", "Yellow", "Olive", "Peach", "Brown", "Copper", "Bronze" },
    },
    {
        Name = "Green",
        Side = "Right",
        Themes = { "Lime", "Green", "Forest", "Emerald", "Jade", "Mint", "Teal", "Turquoise" },
    },
    {
        Name = "Blue",
        Side = "Right",
        Themes = { "Cyan", "Aqua", "Sky", "Blue", "Navy", "Indigo", "Periwinkle" },
    },
    {
        Name = "Purple and Pink",
        Side = "Right",
        Themes = { "Violet", "Purple", "Lavender", "Lilac", "Fuchsia", "Magenta", "Pink", "Rose", "Plum" },
    },
}

for _, family in ipairs(families) do
    local Section = Themes:CreateSection({
        Name = family.Name,
        Description = "Fixed built-in presets. These buttons exist only in this example.",
        Side = family.Side,
        Collapsible = true,
    })

    for _, themeName in ipairs(family.Themes) do
        Section:CreateButton({
            Name = themeName,
            ButtonText = "Apply",
            Style = "Secondary",
            Callback = function()
                Window:SetTheme(themeName)
            end,
        })
    end
end

local Information = Window:CreateTab({
    Name = "Information",
    Icon = "info",
})

local Details = Information:CreateSection({
    Name = "Theme behavior",
})

Details:CreateParagraph({
    Title = "No automatic theme controls",
    Content = "Choosing Theme = \"Pink\" or another preset applies it directly. Note never inserts theme buttons into ordinary scripts. The buttons in this gallery are normal CreateButton controls added only for testing.",
})

Details:CreateParagraph({
    Title = "Color picker separation",
    Content = "The color picker continues to return standalone Color3 values and does not modify the interface theme.",
})
