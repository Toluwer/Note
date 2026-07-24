local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:Init({
    Theme = "Dark",
    FrostedGlass = true,
})

local Window = Note:CreateWindow({
    Title = "Notifications",
    Subtitle = "Stacking and dismissal",
    Icon = "bell",
    Theme = "Dark",
    Size = UDim2.fromOffset(560, 400),
    Draggable = true,
    Resizable = true,
})

local Demo = Window:CreateTab({
    Name = "Demo",
    Icon = "bell",
})

local Types = Demo:CreateSection({
    Name = "Notification Types",
})

for _, item in ipairs({
    { Name = "Info", Icon = "info" },
    { Name = "Success", Icon = "circle-check" },
    { Name = "Warning", Icon = "circle-alert" },
    { Name = "Error", Icon = "circle-alert" },
}) do
    Types:CreateButton({
        Name = item.Name,
        Icon = item.Icon,
        Callback = function()
            Note:Notify({
                Title = item.Name,
                Content = item.Name .. " notification from Note.",
                Type = item.Name,
                Duration = 5,
            })
        end,
    })
end

Types:CreateButton({
    Name = "Stack Four",
    Icon = "plus",
    Callback = function()
        for _, kind in ipairs({ "Info", "Success", "Warning", "Error" }) do
            Note:Notify({
                Title = kind,
                Content = "Stacked " .. string.lower(kind) .. " message.",
                Type = kind,
                Duration = 7,
            })
        end
    end,
})

Types:CreateButton({
    Name = "Manual Dismissal",
    Icon = "x",
    Callback = function()
        local notification = Note:Notify({
            Title = "Manual",
            Content = "This notification remains until its close control is pressed.",
            Type = "Info",
            Duration = 0,
        })
        print("Notification:", notification)
    end,
})


Types:CreateButton({
    Name = "Long Message",
    Icon = "align-left",
    Callback = function()
        Note:Notify({
            Title = "Compact notification",
            Content = "Longer notification text wraps onto additional lines and increases the card height instead of stretching across the screen.",
            Duration = 7,
        })
    end,
})
