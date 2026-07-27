local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:Init({
    Theme = "Dark",
    FrostedGlass = true,
})

local Window = Note:CreateWindow({
    Title = "Note",
    Subtitle = "Split Layout",
    Icon = "panel-left",
    Theme = "Dark",
    Size = UDim2.fromOffset(680, 500),
    MinimumSize = Vector2.new(460, 320),
    Draggable = true,
    Resizable = true,
})

local Single = Window:CreateTab({
    Name = "Single",
    Icon = "menu",
})

local NormalSection = Single:CreateSection({
    Name = "Normal Layout",
    Description = "Tabs remain single-column unless Split is enabled.",
})

NormalSection:CreateToggle({
    Name = "Enabled",
    Default = true,
})

local Split = Window:CreateTab({
    Name = "Split",
    Icon = "panel-left",
    Layout = "Split",
    SplitGap = 10,
    StackAt = nil,
})

local LeftMain = Split:CreateSection({
    Name = "Left Column",
    Description = "Split mode remains active even when the window is narrow.",
    Side = "Left",
    Collapsible = true,
})

LeftMain:CreateToggle({
    Name = "Enabled",
    Default = true,
})

LeftMain:CreateInput({
    Name = "Label",
    Placeholder = "Left column value",
})

local LeftSecondary = Split:CreateSection({
    Name = "Independent Stack",
    Description = "Each side stacks its own sections.",
    Side = "Left",
})

LeftSecondary:CreateButton({
    Name = "Move to Right",
    Callback = function()
        LeftSecondary:SetSide("Right")
    end,
})

local RightMain = Split:CreateSection({
    Name = "Right Column",
    Description = "Use StackAt only when automatic one-column stacking is wanted.",
    Side = "Right",
    Collapsible = true,
})

RightMain:CreateSlider({
    Name = "Amount",
    Minimum = 0,
    Maximum = 100,
    Default = 45,
    Suffix = "%",
})

RightMain:CreateDropdown({
    Name = "Mode",
    Options = { "Compact", "Balanced", "Detailed" },
    Default = "Balanced",
})

local RightResponsive = Split:CreateSection({
    Name = "Responsive Option",
    Description = "This button enables stacking below 520 pixels.",
    Side = "Right",
})

RightResponsive:CreateButton({
    Name = "Enable Responsive Stack",
    Callback = function()
        Split:SetStackBreakpoint(520)
    end,
})

RightResponsive:CreateButton({
    Name = "Keep Narrow Split",
    Callback = function()
        Split:SetStackBreakpoint(nil)
    end,
})
