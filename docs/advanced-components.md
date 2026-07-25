# Advanced components

## Progress bar

```lua
local Progress = Section:CreateProgressBar({
    Name = "Build Progress",
    Description = "Current build completion.",
    Minimum = 0,
    Maximum = 100,
    Value = 35,
    Prefix = "",
    Suffix = "%",
    ShowValue = true,
    Indeterminate = false,
    Status = "",
    Flag = "buildProgress",
    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
Progress:SetValue(75)
Progress:GetValue()
Progress:SetRange(0, 200)
Progress:SetIndeterminate(true)
Progress:SetStatus("Compiling")
Progress:SetVisible(true)
Progress:SetDisabled(false)
Progress:Destroy()
```

`Section:CreateProgress(config)` is an alias of `CreateProgressBar`.

## Data table

```lua
local Table = Section:CreateDataTable({
    Name = "Players",
    Description = "Sortable and selectable rows.",
    Columns = {
        { Key = "name", Name = "Name", Width = 1.5 },
        { Key = "team", Name = "Team", Width = 1 },
        { Key = "ping", Name = "Ping", Width = 0.6 },
    },
    Rows = {
        { id = 1, name = "PlayerOne", team = "Red", ping = 42 },
        { id = 2, name = "PlayerTwo", team = "Blue", ping = 57 },
    },
    RowKey = "id",
    PageSize = 5,
    Sortable = true,
    Selectable = true,
    MultiSelect = false,
    EmptyText = "No players",
    Callback = function(selected, row, index)
        print(selected, row, index)
    end,
})
```

Column options:

- `Key` — value key read from each row
- `Name` — displayed header
- `Width` — relative column width
- `Sortable` — allow header sorting
- `Align` — `Enum.TextXAlignment`
- `Format(value, row, index)` — custom displayed value

Methods:

```lua
Table:SetRows(rows)
Table:GetRows()
Table:SetColumns(columns)
Table:SortBy("ping", true)
Table:SetPage(2)
Table:GetPage()
Table:GetSelected()
Table:ClearSelection()
Table:Destroy()
```

`Section:CreateTable(config)` is an alias of `CreateDataTable`.

## Context menu

```lua
local Menu = Section:CreateContextMenu({
    Name = "Actions",
    Description = "Contextual actions for the selected item.",
    Width = 220,
    MaxHeight = 320,
    CloseOnSelect = true,
    Items = {
        { Name = "Copy", Icon = "copy", Shortcut = "Ctrl C", Callback = copy },
        { Name = "Pinned", Checkable = true, Checked = false },
        { Type = "Divider" },
        { Name = "Delete", Icon = "trash-2", Destructive = true, Callback = remove },
    },
})
```

Item options:

- `Name`, `Icon`, and `Shortcut`
- `Disabled`
- `Destructive`
- `Checkable` and `Checked`
- `KeepOpen`
- `Callback(item, index)`
- `{ Type = "Divider" }`

Methods:

```lua
Menu:Open()
Menu:OpenAt(Vector2.new(x, y))
Menu:Close()
Menu:Toggle()
Menu:SetItems(items)
Menu:Bind(guiObject)
Menu:Destroy()
```

Calling `Bind(guiObject)` opens the menu at the pointer when that object receives a right-click. The component's own button remains available as a normal anchored trigger.

## Command palette

```lua
local Palette = Section:CreateCommandPalette({
    Name = "Command Palette",
    Description = "Search and execute interface commands.",
    OpenKey = Enum.KeyCode.F12,
    Modifier = false,
    Shortcut = "F12",
    Placeholder = "Search commands",
    CloseOnExecute = true,
    Commands = {
        {
            Name = "Toggle interface",
            Description = "Show or hide the window.",
            Icon = "panel-left",
            Shortcut = "RightShift",
            Keywords = { "window", "visibility" },
            Callback = function()
                Window:Toggle()
            end,
        },
    },
})
```

Command options:

- `Name`, `Description`, `Category`, and `Keywords`
- `Icon` and `Shortcut`
- `Disabled`
- `KeepOpen`
- `Callback(command, index)`

Methods:

```lua
Palette:Open()
Palette:Close()
Palette:Toggle()
Palette:Execute(1)
Palette:SetCommands(commands)
Palette:GetCommands()
Palette:Destroy()
```

The default shortcut is `F12`. While open, use Up and Down to move through results, Enter to execute, and Escape to close.
