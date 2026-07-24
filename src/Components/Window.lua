local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Maid = require("src/Core/Maid")
local Signal = require("src/Core/Signal")
local Utilities = require("src/Core/Utilities")
local Validation = require("src/Core/Validation")
local ThemeManager = require("src/Core/ThemeManager")
local Icons = require("src/Core/Icons")
local DragController = require("src/Internal/DragController")
local WindowControls = require("src/Components/WindowControls")
local Tab = require("src/Components/Tab")

local Window = {}
Window.__index = Window

function Window.new(library, config)
    config = Validation.Window(config or {})
    local self = setmetatable({
        Library = library,
        Maid = Maid.new(),
        Tabs = {},
        ActiveTab = nil,
        Notifications = {},
        Dialogs = {},
        Title = tostring(config.Title or "Note"),
        Subtitle = tostring(config.Subtitle or ""),
        Draggable = config.Draggable ~= false,
        Resizable = config.Resizable == true,
        MinimumSize = config.MinimumSize or Vector2.new(460, 300),
        MaximumSize = config.MaximumSize or Vector2.new(1000, 760),
        Visible = true,
        Minimized = false,
        Closed = Signal.new(),
        Destroyed = Signal.new(),
        ThemeChanged = Signal.new(),
        VisibilityChanged = Signal.new(),
        MinimizedChanged = Signal.new(),
        _tabOrder = 0,
        _destroyed = false,
    }, Window)

    self.ThemeManager = ThemeManager.new(library, config.Theme or library.DefaultTheme, config.Accent)
    self.Maid:Give(self.ThemeManager)
    self.Maid:Give(self.Closed)
    self.Maid:Give(self.Destroyed)
    self.Maid:Give(self.ThemeChanged)
    self.Maid:Give(self.VisibilityChanged)
    self.Maid:Give(self.MinimizedChanged)
    self.Maid:Give(self.ThemeManager.Changed:Connect(function(theme, name)
        self.ThemeChanged:Fire(theme, name)
    end))

    local requestedSize = config.Size or UDim2.fromOffset(620, 450)
    local viewport = library.Root.AbsoluteSize
    local width = requestedSize.X.Offset > 0 and requestedSize.X.Offset or 620
    local height = requestedSize.Y.Offset > 0 and requestedSize.Y.Offset or 450
    width = Utilities.Clamp(width, self.MinimumSize.X, math.min(self.MaximumSize.X, math.max(self.MinimumSize.X, viewport.X - 20)))
    height = Utilities.Clamp(height, self.MinimumSize.Y, math.min(self.MaximumSize.Y, math.max(self.MinimumSize.Y, viewport.Y - 20)))

    local main = Utilities.Create("Frame", {
        Name = "NoteWindow",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height),
        ClipsDescendants = true,
        Active = true,
        ZIndex = 1,
        Parent = library.Root,
    })
    Utilities.Corner(main, library.Tokens.Radius.Window)
    local mainStroke = Utilities.Stroke(main, Color3.new(), 1, 0)
    self.ThemeManager:Bind(main, { BackgroundColor3 = "Background" })
    self.ThemeManager:Bind(mainStroke, { Color = "Border" })

    local titleBar = Utilities.Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, library.Tokens.Size.TitleBar),
        Active = true,
        ZIndex = 100,
        Parent = main,
    })
    self.ThemeManager:Bind(titleBar, { BackgroundColor3 = "Surface" })

    local left = 14
    if config.Icon then
        local windowIcon = Icons.Create({ Name = config.Icon, Size = 18, Parent = titleBar, ZIndex = 103 })
        windowIcon.Instance.AnchorPoint = Vector2.new(0, 0.5)
        windowIcon.Instance.Position = UDim2.new(0, 14, 0.5, 0)
        self.ThemeManager:Bind(windowIcon.Instance, { ImageColor3 = "Accent" })
        self.WindowIcon = windowIcon
        self.Maid:Give(windowIcon)
        left = 42
    end

    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(left, self.Subtitle ~= "" and 6 or 0),
        Size = UDim2.new(1, -left - 100, 0, self.Subtitle ~= "" and 21 or library.Tokens.Size.TitleBar),
        Font = Enum.Font.GothamMedium,
        Text = self.Title,
        TextSize = library.Tokens.Typography.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 102,
        Parent = titleBar,
    })
    self.ThemeManager:Bind(title, { TextColor3 = "Text" })

    local subtitle
    if self.Subtitle ~= "" then
        subtitle = Utilities.Create("TextLabel", {
            Name = "Subtitle",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(left, 25),
            Size = UDim2.new(1, -left - 100, 0, 16),
            Font = Enum.Font.Gotham,
            Text = self.Subtitle,
            TextSize = library.Tokens.Typography.Small,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 102,
            Parent = titleBar,
        })
        self.ThemeManager:Bind(subtitle, { TextColor3 = "TextMuted" })
    end

    local controls = Utilities.Create("Frame", {
        Name = "WindowControls",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -7, 0, 7),
        Size = UDim2.fromOffset(76, 34),
        ZIndex = 105,
        Parent = titleBar,
    })
    local controlsList = Utilities.List(controls, Enum.FillDirection.Horizontal, 2, Enum.HorizontalAlignment.Right)
    controlsList.VerticalAlignment = Enum.VerticalAlignment.Center

    local minimizeButton
    if config.MinimizeButton ~= false then
        minimizeButton = WindowControls.Create(self, {
            Name = "Minimize",
            Icon = "minus",
            IconSize = 16,
            Tooltip = "Minimize",
            Parent = controls,
            Callback = function() self:ToggleMinimized() end,
        })
    end
    local closeButton
    if config.CloseButton ~= false then
        closeButton = WindowControls.Create(self, {
            Name = "Close",
            Icon = "x",
            IconSize = 17,
            Tooltip = "Close",
            Destructive = true,
            Parent = controls,
            Callback = function() self:Close() end,
        })
    end

    local divider = Utilities.Create("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, library.Tokens.Size.TitleBar - 1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 101,
        Parent = titleBar,
    })
    self.ThemeManager:Bind(divider, { BackgroundColor3 = "Border" })

    local body = Utilities.Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, library.Tokens.Size.TitleBar),
        Size = UDim2.new(1, 0, 1, -library.Tokens.Size.TitleBar),
        ZIndex = 2,
        Parent = main,
    })

    local sidebarWidth = config.CompactSidebar and 76 or library.Tokens.Size.Sidebar
    local sidebar = Utilities.Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        ZIndex = 2,
        Parent = body,
    })
    self.ThemeManager:Bind(sidebar, { BackgroundColor3 = "SecondaryBackground" })

    local sidebarDivider = Utilities.Create("Frame", {
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = sidebar,
    })
    self.ThemeManager:Bind(sidebarDivider, { BackgroundColor3 = "Border" })

    local searchTop = 10
    local searchHeight = config.Search == false and 0 or 34
    local searchFrame
    local searchBox
    if config.Search ~= false then
        searchFrame = Utilities.Create("Frame", {
            Name = "Search",
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.new(1, -20, 0, 34),
            Parent = sidebar,
        })
        Utilities.Corner(searchFrame, library.Tokens.Radius.Medium)
        local searchStroke = Utilities.Stroke(searchFrame, Color3.new(), 1, 0)
        self.ThemeManager:Bind(searchFrame, { BackgroundColor3 = "Input" })
        self.ThemeManager:Bind(searchStroke, { Color = "Border" })
        local searchIcon = Icons.Create({ Name = "search", Size = 14, Parent = searchFrame })
        searchIcon.Instance.AnchorPoint = Vector2.new(0, 0.5)
        searchIcon.Instance.Position = UDim2.new(0, 9, 0.5, 0)
        self.ThemeManager:Bind(searchIcon.Instance, { ImageColor3 = "TextMuted" })
        self.Maid:Give(searchIcon)
        searchBox = Utilities.Create("TextBox", {
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            Position = UDim2.fromOffset(31, 0),
            Size = UDim2.new(1, -38, 1, 0),
            Font = Enum.Font.Gotham,
            PlaceholderText = "Search",
            Text = "",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = searchFrame,
        })
        self.ThemeManager:Bind(searchBox, { TextColor3 = "Text", PlaceholderColor3 = "TextMuted" })
        searchTop = 52
    end

    local tabList = Utilities.Create("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, searchTop),
        Size = UDim2.new(1, -8, 1, -searchTop - 8),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2,
        Parent = sidebar,
    })
    Utilities.Padding(tabList, 0, 2, 0, 0)
    local tabLayout = Utilities.List(tabList, Enum.FillDirection.Vertical, 4)
    self.ThemeManager:Bind(tabList, { ScrollBarImageColor3 = "Scrollbar" })
    self.Maid:Give(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabList.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 8)
    end))

    local pages = Utilities.Create("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(sidebarWidth + 1, 0),
        Size = UDim2.new(1, -sidebarWidth - 1, 1, 0),
        ClipsDescendants = true,
        Parent = body,
    })

    local resizeHandle
    if self.Resizable then
        resizeHandle = Utilities.Create("TextButton", {
            Name = "ResizeHandle",
            BackgroundTransparency = 1,
            Text = "",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(library.Tokens.Size.ResizeHandle, library.Tokens.Size.ResizeHandle),
            ZIndex = 120,
            Parent = main,
        })
        local resizeIcon = Icons.Create({ Name = "grip-horizontal", Size = 14, Parent = resizeHandle, ZIndex = 121 })
        resizeIcon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
        resizeIcon.Instance.Position = UDim2.fromScale(0.5, 0.5)
        resizeIcon.Instance.Rotation = -45
        self.ThemeManager:Bind(resizeIcon.Instance, { ImageColor3 = "TextMuted" })
        self.Maid:Give(resizeIcon)
    end

    self.Main = main
    self.MainStroke = mainStroke
    self.TitleBar = titleBar
    self.Body = body
    self.Sidebar = sidebar
    self.TabList = tabList
    self.Pages = pages
    self.TitleLabel = title
    self.SubtitleLabel = subtitle
    self.Controls = controls
    self.MinimizeButton = minimizeButton
    self.CloseButton = closeButton
    self.SearchBox = searchBox
    self.ResizeHandle = resizeHandle
    self.Maid:Give(main)

    self.DragController = DragController.new(main, titleBar, {
        Enabled = self.Draggable,
        Ignore = { controls },
    })
    self.Maid:Give(self.DragController)

    if resizeHandle then
        self:_bindResize(resizeHandle)
    end

    if searchBox then
        self.Maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            self:SetSearch(searchBox.Text)
        end))
    end

    if config.ToggleKey then
        self.ToggleKey = config.ToggleKey
        self._toggleBinding = library.InputManager:RegisterKeybind(config.ToggleKey, function()
            self:Toggle()
        end, {
            Enabled = function() return not self._destroyed end,
        })
        self.Maid:Give(self._toggleBinding)
    end

    library:_registerWindow(self)
    return self
end

function Window:_nextTabOrder()
    self._tabOrder += 1
    return self._tabOrder
end

function Window:_registerTab(tab)
    table.insert(self.Tabs, tab)
    if not self.ActiveTab and not tab.Disabled and tab.Visible then
        self:_selectTab(tab)
    end
end

function Window:_unregisterTab(tab)
    local index = table.find(self.Tabs, tab)
    if index then table.remove(self.Tabs, index) end
    if self.ActiveTab == tab then
        self.ActiveTab = nil
    end
end

function Window:_selectTab(tab)
    if self.ActiveTab == tab then return end
    local previous = self.ActiveTab
    self.ActiveTab = tab
    if previous then previous:_setSelected(false) end
    if tab then
        tab:_setSelected(true)
        tab:ApplySearch(self.SearchQuery or "")
    end
end

function Window:_selectFallbackTab(excluded)
    for _, tab in ipairs(self.Tabs) do
        if tab ~= excluded and tab.Visible and not tab.Disabled and not tab._destroyed then
            self:_selectTab(tab)
            return
        end
    end
    self.ActiveTab = nil
end

function Window:_bindResize(handle)
    self.Maid:Give(handle.InputBegan:Connect(function(input)
        if self.Minimized or not self.Resizable then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local startPointer = input.Position
        local startSize = self.Main.AbsoluteSize
        local startPosition = self.Main.Position
        self.Library.InputManager:BeginPointerDrag(function(point)
            local delta = point - startPointer
            local viewport = self.Library.Root.AbsoluteSize
            local maxWidth = math.min(self.MaximumSize.X, viewport.X - 8)
            local maxHeight = math.min(self.MaximumSize.Y, viewport.Y - 8)
            local width = Utilities.Clamp(startSize.X + delta.X, self.MinimumSize.X, maxWidth)
            local height = Utilities.Clamp(startSize.Y + delta.Y, self.MinimumSize.Y, maxHeight)
            local deltaSize = Vector2.new(width - startSize.X, height - startSize.Y)
            self.Main.Size = UDim2.fromOffset(math.floor(width + 0.5), math.floor(height + 0.5))
            self.Main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + math.floor(deltaSize.X / 2 + 0.5),
                startPosition.Y.Scale,
                startPosition.Y.Offset + math.floor(deltaSize.Y / 2 + 0.5)
            )
        end)
    end))
end

function Window:CreateTab(config)
    return Tab.new(self, config)
end

function Window:SetSearch(query)
    self.SearchQuery = tostring(query or "")
    for _, tab in ipairs(self.Tabs) do
        tab:ApplySearch(self.SearchQuery)
    end
    return self
end

function Window:SetTitle(title)
    self.Title = tostring(title)
    self.TitleLabel.Text = self.Title
    return self
end

function Window:SetSubtitle(subtitle)
    self.Subtitle = tostring(subtitle or "")
    if self.SubtitleLabel then
        self.SubtitleLabel.Text = self.Subtitle
    end
    return self
end

function Window:SetIcon(icon)
    if self.WindowIcon then
        self.WindowIcon:SetIcon(icon)
    else
        local windowIcon = Icons.Create({ Name = icon, Size = 18, Parent = self.TitleBar, ZIndex = 103 })
        windowIcon.Instance.AnchorPoint = Vector2.new(0, 0.5)
        windowIcon.Instance.Position = UDim2.new(0, 14, 0.5, 0)
        self.ThemeManager:Bind(windowIcon.Instance, { ImageColor3 = "Accent" })
        self.WindowIcon = windowIcon
        self.Maid:Give(windowIcon)
        self.TitleLabel.Position = UDim2.fromOffset(42, self.Subtitle ~= "" and 6 or 0)
    end
    return self
end

function Window:SetTheme(theme)
    self.ThemeManager:SetTheme(theme)
    return self
end

function Window:SetAccent(color)
    self.ThemeManager:SetAccent(color)
    return self
end

function Window:Show()
    if self._destroyed then return self end
    self.Visible = true
    self.Main.Visible = true
    self.VisibilityChanged:Fire(true)
    return self
end

function Window:Hide()
    if self._destroyed then return self end
    self.Visible = false
    self.Main.Visible = false
    self.VisibilityChanged:Fire(false)
    return self
end

function Window:Toggle()
    return self.Visible and self:Hide() or self:Show()
end

function Window:Minimize()
    if self._destroyed or self.Minimized then return self end
    self.Minimized = true
    self._restoreSize = self.Main.Size
    if self.ResizeHandle then self.ResizeHandle.Visible = false end
    local targetWidth = math.max(300, math.min(self.Main.AbsoluteSize.X, 420))
    self.Library.Animation:Tween(self.Main, {
        Size = UDim2.fromOffset(targetWidth, self.Library.Tokens.Size.TitleBar),
    }, self.Library.Tokens.Animation.Normal)
    task.delay(self.Library.Tokens.Animation.Normal * 0.7, function()
        if self.Main and self.Minimized then
            self.Body.Visible = false
        end
    end)
    self.MinimizedChanged:Fire(true)
    return self
end

function Window:Restore()
    if self._destroyed or not self.Minimized then return self end
    self.Minimized = false
    self.Body.Visible = true
    self.Library.Animation:Tween(self.Main, {
        Size = self._restoreSize or UDim2.fromOffset(620, 450),
    }, self.Library.Tokens.Animation.Normal)
    self.DragController:SetEnabled(self.Draggable)
    if self.ResizeHandle then self.ResizeHandle.Visible = true end
    self.MinimizedChanged:Fire(false)
    return self
end

function Window:ToggleMinimized()
    return self.Minimized and self:Restore() or self:Minimize()
end

function Window:SetSize(size)
    if typeof(size) ~= "UDim2" then error("[Note] SetSize expected a UDim2", 2) end
    local width = size.X.Offset
    local height = size.Y.Offset
    if width > 0 and height > 0 then
        width = Utilities.Clamp(width, self.MinimumSize.X, self.MaximumSize.X)
        height = Utilities.Clamp(height, self.MinimumSize.Y, self.MaximumSize.Y)
        self.Main.Size = UDim2.fromOffset(width, height)
    else
        self.Main.Size = size
    end
    return self
end

function Window:SetPosition(position)
    if typeof(position) ~= "UDim2" then error("[Note] SetPosition expected a UDim2", 2) end
    self.Main.Position = position
    return self
end

function Window:Notify(config)
    local notification = self.Library:Notify(config, self.ThemeManager)
    notification.Window = self
    table.insert(self.Notifications, notification)
    return notification
end

function Window:Dialog(config)
    local dialog = self.Library:Dialog(config, self.ThemeManager)
    dialog.Window = self
    table.insert(self.Dialogs, dialog)
    return dialog
end

function Window:ExportConfig()
    local config = {}
    for flag, component in pairs(self.Library._flagBindings) do
        if component.Window == self and type(component.GetValue) == "function" then
            config[flag] = Utilities.Serialize(component:GetValue())
        end
    end
    return config
end

function Window:ImportConfig(config, options)
    assert(type(config) == "table", "[Note] ImportConfig expected a table")
    options = options or {}
    for flag, value in pairs(config) do
        local component = self.Library._flagBindings[flag]
        if component and component.Window == self and type(component.SetValue) == "function" then
            local decoded = Utilities.Deserialize(value)
            local ok, err = pcall(function()
                component:SetValue(decoded, options.Silent == true)
            end)
            if not ok then
                warn(string.format('[Note] Failed to import flag "%s": %s', tostring(flag), tostring(err)))
            end
        elseif options.AllowUnknown then
            self.Library.Flags[flag] = Utilities.Deserialize(value)
        end
    end
    return self
end

function Window:Close()
    if self._destroyed then return end
    self.Closed:Fire()
    self:Destroy()
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for i = #self.Dialogs, 1, -1 do
        local dialog = self.Dialogs[i]
        if dialog and not dialog._destroyed then dialog:Destroy() end
    end
    for i = #self.Notifications, 1, -1 do
        local notification = self.Notifications[i]
        if notification and not notification._destroyed then notification:Destroy() end
    end
    for i = #self.Tabs, 1, -1 do
        self.Tabs[i]:Destroy()
    end
    self.Destroyed:Fire()
    self.Library:_unregisterWindow(self)
    self.Library.Animation:CancelTree(self.Main)
    self.Maid:Destroy()
    self.Main = nil
end

return Window
