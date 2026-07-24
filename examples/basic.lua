local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:Init({
    Theme = "Dark",
    FrostedGlass = true,
})

local Window = Note:CreateWindow({
    Title = "Note",
    Subtitle = "Basic example",
    Icon = "panel-left",
    Theme = "Dark",
    Size = UDim2.fromOffset(620, 450),
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
    Description = "A minimal Note window.",
    Collapsible = true,
})

Main:CreateButton({
    Name = "Run Action",
    Icon = "mouse-pointer-2",
    Callback = function()
        Window:Notify({
            Title = "Action",
            Content = "The button callback ran.",
            Type = "Success",
        })
    end,
})

Main:CreateToggle({
    Name = "Enabled",
    Description = "Stores its value under Note.Flags.enabled.",
    Flag = "enabled",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})

Main:CreateButton({
    Name = "Destroy Interface",
    Icon = "trash-2",
    Style = "Destructive",
    Confirm = {
        Title = "Destroy Note?",
        Content = "This removes the entire Note interface.",
        Destructive = true,
    },
    Callback = function()
        Note:Destroy()
    end,
})
