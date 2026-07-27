local Note = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Note/main/main.lua"
))()

Note:Init({
    Theme = "Dark",
    FrostedGlass = true,
})

local Window = Note:CreateWindow({
    Title = "Note",
    Subtitle = "Component Showcase",
    Icon = "panel-left",
    Theme = "Dark",
    Size = UDim2.fromOffset(680, 500),
    MinimumSize = Vector2.new(480, 320),
    MaximumSize = Vector2.new(940, 720),
    Draggable = true,
    Resizable = true,
    Search = true,
    ToggleKey = Enum.KeyCode.RightShift,
})

local General = Window:CreateTab({
    Name = "General",
    Icon = "settings",
})

local Actions = General:CreateSection({
    Name = "Actions",
    Description = "Buttons, status, modal actions, and smooth section collapsing.",
    Icon = "mouse-pointer-2",
    Collapsible = true,
})

Actions:CreateButton({
    Name = "Run Action",
    Description = "Executes a protected callback.",
    Icon = "mouse-pointer-2",
    Style = "Primary",
    Callback = function()
        Window:Notify({
            Title = "Action complete",
            Content = "The callback executed successfully.",
            Type = "Success",
        })
    end,
})

Actions:CreateButton({
    Name = "Open Dialog",
    Description = "Shows a modal confirmation with temporary scene blur.",
    Icon = "circle-alert",
    Style = "Secondary",
    Callback = function()
        Window:Dialog({
            Title = "Reset settings?",
            Content = "This demonstration does not change any external state.",
            Icon = "circle-alert",
            Blur = true,
            BlurSize = 14,
            Buttons = {
                { Name = "Cancel", Style = "Secondary" },
                {
                    Name = "Reset",
                    Style = "Destructive",
                    Callback = function()
                        Note:SetFlag("enabled", false)
                        Note:SetFlag("amount", 50)
                    end,
                },
            },
        })
    end,
})

Actions:CreateDivider({ Text = "State" })

Actions:CreateToggle({
    Name = "Enabled",
    Description = "Animated switch with central flag state.",
    Flag = "enabled",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})

Actions:CreateSlider({
    Name = "Amount",
    Description = "Mouse and touch dragging with increment rounding.",
    Flag = "amount",
    Minimum = 0,
    Maximum = 100,
    Default = 50,
    Increment = 1,
    Suffix = "%",
    Callback = function(value)
        print("Amount:", value)
    end,
})

local Data = General:CreateSection({
    Name = "Data Entry",
    Description = "Inputs and searchable choices.",
    Collapsible = true,
})

Data:CreateInput({
    Name = "Username",
    Description = "The error clears as soon as three characters are entered.",
    Flag = "username",
    Placeholder = "Username",
    CharacterLimit = 24,
    ClearButton = true,
    Validate = function(value)
        return #value == 0 or #value >= 3, "Use at least three characters."
    end,
    Changed = function(value)
        print("Changed:", value)
    end,
    Callback = function(value)
        print("Submitted:", value)
    end,
})

Data:CreateInput({
    Name = "Password",
    Description = "Password errors also clear immediately once valid.",
    Placeholder = "Password",
    Password = true,
    CharacterLimit = 32,
    Validate = function(value)
        return #value >= 3, "Use at least three characters."
    end,
})

Data:CreateInput({
    Name = "Port",
    Description = "Numeric input uses the existing input component.",
    Placeholder = "8080",
    Numeric = true,
    Default = "8080",
    CharacterLimit = 5,
})

Data:CreateDropdown({
    Name = "Mode",
    Description = "Searchable overlay dropdown.",
    Flag = "mode",
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

Data:CreateDropdown({
    Name = "Features",
    Description = "Optional multi-select mode.",
    Flag = "features",
    Options = { "Search", "Themes", "Notifications", "Dialogs" },
    Default = { "Search", "Themes" },
    Searchable = true,
    Multi = true,
})

Data:CreateKeybind({
    Name = "Toggle Interface",
    Description = "Escape cancels key capture.",
    Default = Enum.KeyCode.RightShift,
    Mode = "Press",
    Callback = function()
        Window:Toggle()
    end,
    Changed = function(key)
        print("Key changed:", key)
    end,
})

local Advanced = General:CreateSection({
    Name = "Advanced",
    Description = "Commands, menus, progress, and structured data.",
    Icon = "menu",
    Collapsible = true,
})

local Progress = Advanced:CreateProgressBar({
    Name = "Build Progress",
    Description = "Determinate and indeterminate progress states.",
    Minimum = 0,
    Maximum = 100,
    Value = 68,
    Suffix = "%",
    ShowValue = true,
    Callback = function(value)
        print("Progress:", value)
    end,
})

Advanced:CreateContextMenu({
    Name = "Context Menu",
    Description = "Supports icons, shortcuts, checkable items, and destructive actions.",
    Items = {
        {
            Name = "Refresh",
            Icon = "refresh-cw",
            Shortcut = "Ctrl R",
            Callback = function()
                Progress:SetValue(100)
            end,
        },
        {
            Name = "Keep logs",
            Checkable = true,
            Checked = true,
        },
        { Type = "Divider" },
        {
            Name = "Clear output",
            Icon = "trash-2",
            Destructive = true,
            Callback = function()
                Progress:SetValue(0)
            end,
        },
    },
})

Advanced:CreateCommandPalette({
    Name = "Command Palette",
    Description = "Search and execute actions with the , / < key.",
    OpenKey = Enum.KeyCode.Comma,
    Shortcut = ", / <",
    Modifier = false,
    Commands = {
        {
            Name = "Toggle interface",
            Description = "Show or hide the Note window.",
            Icon = "panel-left",
            Shortcut = "RightShift",
            Keywords = { "window", "visibility" },
            Callback = function()
                Window:Toggle()
            end,
        },
        {
            Name = "Complete progress",
            Description = "Set build progress to 100 percent.",
            Icon = "check",
            Keywords = { "build", "progress" },
            Callback = function()
                Progress:SetValue(100)
            end,
        },
        {
            Name = "Switch to light theme",
            Description = "Apply the built-in light theme.",
            Icon = "sun",
            Callback = function()
                Window:SetTheme("Light")
            end,
        },
        {
            Name = "Switch to dark theme",
            Description = "Apply the built-in dark theme.",
            Icon = "moon",
            Callback = function()
                Window:SetTheme("Dark")
            end,
        },
    },
})

Advanced:CreateDataTable({
    Name = "Runtime Tasks",
    Description = "Sortable, selectable rows with built-in pagination.",
    Columns = {
        { Key = "name", Name = "Task", Width = 1.6 },
        { Key = "status", Name = "Status", Width = 1 },
        { Key = "duration", Name = "Time", Width = 0.7 },
    },
    Rows = {
        { id = 1, name = "Load modules", status = "Complete", duration = "18 ms" },
        { id = 2, name = "Bind themes", status = "Complete", duration = "7 ms" },
        { id = 3, name = "Create overlays", status = "Running", duration = "12 ms" },
        { id = 4, name = "Register input", status = "Pending", duration = "—" },
        { id = 5, name = "Restore flags", status = "Pending", duration = "—" },
        { id = 6, name = "Show window", status = "Pending", duration = "—" },
    },
    RowKey = "id",
    PageSize = 4,
    Sortable = true,
    Selectable = true,
    Callback = function(row)
        if row then print("Selected task:", row.name) end
    end,
})

local Appearance = Window:CreateTab({
    Name = "Appearance",
    Icon = "palette",
})

local Theme = Appearance:CreateSection({
    Name = "Theme",
    Description = "Switch between the built-in neutral themes.",
    Icon = "paintbrush",
})

Theme:CreateThemeButtons({
    Name = "Interface Theme",
    Description = "Switches every bound surface, text, icon, border, and selection token.",
    Themes = { "Dark", "Light" },
})

local ColorInput = Appearance:CreateSection({
    Name = "Color Input",
    Description = "Standalone color values with no connection to the interface theme.",
    Icon = "palette",
})

ColorInput:CreateColorpicker({
    Name = "Color Picker",
    Description = "Hue, saturation, value, RGB, hex, and alpha selection.",
    Flag = "selectedColor",
    Default = Color3.fromRGB(176, 176, 180),
    ShowAlpha = true,
    Callback = function(color, alpha)
        print("Selected color:", color, "alpha:", alpha)
    end,
})

local Typography = Appearance:CreateSection({
    Name = "Typography",
    Description = "Automatic wrapping and height.",
})

Typography:CreateLabel({
    Text = "Note uses centralized typography and spacing tokens.",
})

Typography:CreateParagraph({
    Title = "About Note",
    Content = "Note is a modular LocalScript UI library with a generated single-file distribution. Floating UI is rendered through a shared unclipped overlay.",
})

Typography:CreateDivider({
    Text = "Window State",
})

Typography:CreateButton({
    Name = "Minimize",
    Icon = "minus",
    Callback = function()
        Window:Minimize()
    end,
})

Typography:CreateButton({
    Name = "Restore",
    Icon = "maximize-2",
    Callback = function()
        Window:Restore()
    end,
})

local Diagnostics = Window:CreateTab({
    Name = "Diagnostics",
    Icon = "info",
})

local Runtime = Diagnostics:CreateSection({
    Name = "Runtime",
    Description = "Feature-detected optional capabilities.",
})

local capabilities = Note:GetCapabilities()
Runtime:CreateParagraph({
    Title = "Capabilities",
    Content = string.format(
        "gethui: %s\nprotect_gui: %s\ncloneref: %s\nfilesystem: %s\ncustom asset: %s",
        tostring(capabilities.gethui),
        tostring(capabilities.protectGui),
        tostring(capabilities.cloneref),
        tostring(capabilities.filesystem),
        tostring(capabilities.customAsset)
    ),
})

Runtime:CreateButton({
    Name = "Export Config",
    Icon = "copy",
    Callback = function()
        print(Window:ExportConfig())
    end,
})

Window:Notify({
    Title = "Loaded",
    Content = "Note loaded successfully. Press RightShift to toggle.",
    Type = "Success",
    Duration = 4,
})
