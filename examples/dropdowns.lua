local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:Init({
    Theme = "Dark",
    FrostedGlass = true,
})

local Window = Note:CreateWindow({
    Title = "Dropdowns",
    Subtitle = "Smooth reversible overlay animations",
    Icon = "list-filter",
    Theme = "Dark",
    Size = UDim2.fromOffset(600, 440),
    Draggable = true,
    Resizable = true,
})

local Demo = Window:CreateTab({
    Name = "Demo",
    Icon = "list-filter",
})

local Controls = Demo:CreateSection({
    Name = "Dropdown Controls",
    Description = "Open and close repeatedly to test interruption-safe animation.",
})

local Mode = Controls:CreateDropdown({
    Name = "Mode",
    Description = "Searchable single-select dropdown.",
    Options = {
        "Standard",
        "Advanced",
        "Expert",
        "Developer",
        "Experimental",
    },
    Default = "Standard",
    Searchable = true,
    Callback = function(value)
        print("Mode:", value)
    end,
})

Controls:CreateDropdown({
    Name = "Features",
    Description = "Searchable multi-select dropdown using the same animation.",
    Options = {
        "Search",
        "Themes",
        "Notifications",
        "Dialogs",
        "Configuration",
    },
    Default = { "Search", "Themes" },
    Searchable = true,
    Multi = true,
    Callback = function(values)
        print("Features:", table.concat(values, ", "))
    end,
})

Controls:CreateButton({
    Name = "Open Mode",
    ButtonText = "Open",
    Callback = function()
        Mode:Open()
    end,
})

Controls:CreateButton({
    Name = "Close Mode",
    ButtonText = "Close",
    Callback = function()
        Mode:Close()
    end,
})

Controls:CreateButton({
    Name = "Rapid Reverse Test",
    ButtonText = "Run Test",
    Callback = function()
        Mode:Open()
        task.delay(0.05, function()
            Mode:Close()
        end)
        task.delay(0.10, function()
            Mode:Open()
        end)
    end,
})
