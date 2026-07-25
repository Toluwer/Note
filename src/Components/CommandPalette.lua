local UserInputService = game:GetService("UserInputService")

local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")
local Maid = require("src/Core/Maid")

local CommandPalette = {}
CommandPalette.__index = CommandPalette
setmetatable(CommandPalette, { __index = BaseComponent })

local function shortcutText(config)
    if config.Shortcut then return tostring(config.Shortcut) end
    local key = config.OpenKey or Enum.KeyCode.P
    local modifier = config.Modifier
    if modifier == false then return key.Name end
    return "Ctrl + " .. key.Name
end

local function commandSearchText(command)
    local keywords = command.Keywords
    if type(keywords) == "table" then
        keywords = table.concat(keywords, " ")
    end
    return table.concat({
        tostring(command.Name or ""),
        tostring(command.Description or ""),
        tostring(command.Category or ""),
        tostring(keywords or ""),
    }, " ")
end

function CommandPalette.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "CommandPalette", config, 58)
    setmetatable(self, CommandPalette)

    self.Commands = table.clone(config.Commands or {})
    self.Placeholder = tostring(config.Placeholder or "Search commands")
    self.EmptyText = tostring(config.EmptyText or "No matching commands")
    self.OpenKey = config.OpenKey or Enum.KeyCode.P
    self.Modifier = config.Modifier
    if self.Modifier == nil then self.Modifier = Enum.KeyCode.LeftControl end
    self.Shortcut = shortcutText(config)
    self.CloseOnExecute = config.CloseOnExecute ~= false
    self._isOpen = false
    self._popupRevision = 0
    self._selectedIndex = 1
    self._filtered = {}
    self._resultRows = {}
    self:AddTextBlock(-170)

    local action = Utilities.Create("TextButton", {
        Name = "OpenPalette",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(134, 34),
        Text = "",
        Parent = self.Frame,
    })
    Utilities.Corner(action, self.Library.Tokens.Radius.Medium)
    local actionStroke = Utilities.Stroke(action, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(action, {
        BackgroundColor3 = "SurfaceElevated",
        BackgroundTransparency = "ElevatedTransparency",
    })
    self.Window.ThemeManager:Bind(actionStroke, {
        Color = "Border",
        Transparency = "BorderTransparency",
    })

    local searchIcon = Icons.Create({ Name = config.Icon or "search", Size = 15, Parent = action })
    searchIcon.Instance.AnchorPoint = Vector2.new(0, 0.5)
    searchIcon.Instance.Position = UDim2.new(0, 10, 0.5, 0)
    self.Window.ThemeManager:Bind(searchIcon.Instance, { ImageColor3 = "TextSecondary" })
    self.Maid:Give(searchIcon)

    local shortcut = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.Code,
        Text = self.Shortcut,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = action,
    })
    self.Window.ThemeManager:Bind(shortcut, { TextColor3 = "TextMuted" })

    self.Action = action
    self.Maid:Give(action.Activated:Connect(function()
        if not self.Disabled then self:Toggle() end
    end))

    self.Maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
        if self._destroyed then return end
        if self._isOpen then
            if input.KeyCode == Enum.KeyCode.Up then
                self:_setSelected(self._selectedIndex - 1)
            elseif input.KeyCode == Enum.KeyCode.Down then
                self:_setSelected(self._selectedIndex + 1)
            elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
                self:Execute(self._selectedIndex)
            end
            return
        end
        if processed or self.Disabled or input.KeyCode ~= self.OpenKey then return end
        local modifierMatches = self.Modifier == false
        if not modifierMatches then
            if self.Modifier == Enum.KeyCode.LeftControl or self.Modifier == Enum.KeyCode.RightControl then
                modifierMatches = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                    or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            else
                modifierMatches = UserInputService:IsKeyDown(self.Modifier)
            end
        end
        if modifierMatches then self:Open() end
    end))
    return self
end

function CommandPalette:_matches(command, query)
    local normalized = Utilities.NormalizeSearch(query)
    if normalized == "" then return true end
    return string.find(Utilities.NormalizeSearch(commandSearchText(command)), normalized, 1, true) ~= nil
end

function CommandPalette:_setSelected(index)
    local count = #self._filtered
    if count == 0 then
        self._selectedIndex = 0
        return
    end
    self._selectedIndex = Utilities.Clamp(index, 1, count)
    for rowIndex, row in ipairs(self._resultRows) do
        self.Window.ThemeManager:Apply(row, true)
        local title = row:FindFirstChild("Title")
        if title then self.Window.ThemeManager:Apply(title, true) end
    end
    if self._results then
        local top = (self._selectedIndex - 1) * 52
        local bottom = top + 48
        local viewTop = self._results.CanvasPosition.Y
        local viewBottom = viewTop + self._results.AbsoluteWindowSize.Y
        if top < viewTop then
            self._results.CanvasPosition = Vector2.new(0, top)
        elseif bottom > viewBottom then
            self._results.CanvasPosition = Vector2.new(0, math.max(0, bottom - self._results.AbsoluteWindowSize.Y))
        end
    end
end

function CommandPalette:_rebuildResults(query)
    if not self._results then return end
    for _, child in ipairs(self._results:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    table.clear(self._filtered)
    table.clear(self._resultRows)

    for commandIndex, command in ipairs(self.Commands) do
        if self:_matches(command, query) then
            local filteredIndex = #self._filtered + 1
            table.insert(self._filtered, { Command = command, Index = commandIndex })
            local disabled = command.Disabled == true
            local row = Utilities.Create("TextButton", {
                Name = "Command_" .. tostring(command.Name or commandIndex),
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -2, 0, 48),
                Text = "",
                Parent = self._results,
            })
            Utilities.Corner(row, self.Library.Tokens.Radius.Small)
            self.Window.ThemeManager:Bind(row, {
                BackgroundColor3 = "SurfaceSelected",
                BackgroundTransparency = function(theme)
                    if disabled then return theme.DisabledTransparency or 0.58 end
                    return self._selectedIndex == filteredIndex and (theme.SelectedTransparency or 0.08) or 1
                end,
            })

            local left = 12
            if command.Icon then
                local icon = Icons.Create({ Name = command.Icon, Size = 16, Parent = row, ZIndex = 314 })
                icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
                icon.Instance.Position = UDim2.new(0, 11, 0.5, 0)
                self.Window.ThemeManager:Bind(icon.Instance, {
                    ImageColor3 = disabled and "TextMuted" or "TextSecondary",
                })
                left = 38
            end

            local title = Utilities.Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(left, command.Description and 6 or 0),
                Size = UDim2.new(1, -left - 104, 0, command.Description and 19 or 48),
                Font = Enum.Font.GothamMedium,
                Text = tostring(command.Name or "Command"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 314,
                Parent = row,
            })
            self.Window.ThemeManager:Bind(title, {
                TextColor3 = disabled and "TextMuted" or "Text",
            })

            if command.Description then
                local description = Utilities.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(left, 25),
                    Size = UDim2.new(1, -left - 104, 0, 16),
                    Font = Enum.Font.Gotham,
                    Text = tostring(command.Description),
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 314,
                    Parent = row,
                })
                self.Window.ThemeManager:Bind(description, { TextColor3 = "TextMuted" })
            end

            if command.Shortcut then
                local key = Utilities.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -11, 0.5, 0),
                    Size = UDim2.fromOffset(88, 22),
                    Font = Enum.Font.Code,
                    Text = tostring(command.Shortcut),
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 314,
                    Parent = row,
                })
                self.Window.ThemeManager:Bind(key, { TextColor3 = "TextMuted" })
            end

            row.MouseEnter:Connect(function()
                if not disabled then self:_setSelected(filteredIndex) end
            end)
            row.Activated:Connect(function()
                if not disabled then self:Execute(filteredIndex) end
            end)
            table.insert(self._resultRows, row)
        end
    end

    if #self._filtered == 0 then
        self._selectedIndex = 0
        local empty = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -2, 0, 80),
            Font = Enum.Font.Gotham,
            Text = self.EmptyText,
            TextSize = 11,
            ZIndex = 314,
            Parent = self._results,
        })
        self.Window.ThemeManager:Bind(empty, { TextColor3 = "TextMuted" })
    else
        self._selectedIndex = Utilities.Clamp(self._selectedIndex, 1, #self._filtered)
    end
end

function CommandPalette:_createPopup()
    local rootSize = self.Library.Overlay.Root.AbsoluteSize
    local width = math.min(560, math.max(280, rootSize.X - 24))
    local height = math.min(430, math.max(260, rootSize.Y - 24))
    local maid = Maid.new()

    local blocker = Utilities.Create("TextButton", {
        Name = "CommandPaletteBlocker",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Active = true,
        ZIndex = 300,
        Parent = self.Library.Overlay:GetLayer("Modals"),
    })
    maid:Give(blocker)

    local surface = Utilities.Create("CanvasGroup", {
        Name = "CommandPalette",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.44),
        Size = UDim2.fromOffset(width, height),
        GroupTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 305,
        Parent = blocker,
    })
    Utilities.Corner(surface, self.Library.Tokens.Radius.Large)
    local stroke = Utilities.Stroke(surface, Color3.new(), 1, 0)
    stroke.ZIndex = 306
    self.Window.ThemeManager:Bind(surface, {
        BackgroundColor3 = "SurfaceElevated",
        BackgroundTransparency = "ElevatedTransparency",
    })
    self.Window.ThemeManager:Bind(stroke, {
        Color = "Border",
        Transparency = "BorderTransparency",
    })

    local scale = Utilities.Create("UIScale", { Scale = 0.965, Parent = surface })
    local searchFrame = Utilities.Create("Frame", {
        Name = "Search",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 0, 42),
        ZIndex = 308,
        Parent = surface,
    })
    Utilities.Corner(searchFrame, self.Library.Tokens.Radius.Medium)
    local searchStroke = Utilities.Stroke(searchFrame, Color3.new(), 1, 0)
    searchStroke.ZIndex = 309
    self.Window.ThemeManager:Bind(searchFrame, {
        BackgroundColor3 = "Input",
        BackgroundTransparency = "InputTransparency",
    })
    self.Window.ThemeManager:Bind(searchStroke, {
        Color = "Border",
        Transparency = "BorderTransparency",
    })

    local icon = Icons.Create({ Name = "search", Size = 16, Parent = searchFrame, ZIndex = 310 })
    icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
    icon.Instance.Position = UDim2.new(0, 12, 0.5, 0)
    self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextMuted" })
    maid:Give(icon)

    local searchBox = Utilities.Create("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Position = UDim2.fromOffset(39, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = self.Placeholder,
        Text = "",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 310,
        Parent = searchFrame,
    })
    self.Window.ThemeManager:Bind(searchBox, {
        TextColor3 = "Text",
        PlaceholderColor3 = "TextMuted",
    })

    local separator = Utilities.Create("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 65),
        Size = UDim2.new(1, -24, 0, 1),
        ZIndex = 309,
        Parent = surface,
    })
    self.Window.ThemeManager:Bind(separator, {
        BackgroundColor3 = "Border",
        BackgroundTransparency = "BorderTransparency",
    })

    local results = Utilities.Create("ScrollingFrame", {
        Name = "Results",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 75),
        Size = UDim2.new(1, -20, 1, -113),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always,
        ZIndex = 312,
        Parent = surface,
    })
    local layout = Utilities.List(results, Enum.FillDirection.Vertical, 4)
    maid:Give(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        results.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
    end))
    self.Window.ThemeManager:Bind(results, { ScrollBarImageColor3 = "Scrollbar" })

    local hint = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 1, -31),
        Size = UDim2.new(1, -28, 0, 20),
        Font = Enum.Font.Code,
        Text = "↑ ↓ navigate    Enter select    Esc close",
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 309,
        Parent = surface,
    })
    self.Window.ThemeManager:Bind(hint, { TextColor3 = "TextMuted" })

    self._blocker = blocker
    self._surface = surface
    self._scale = scale
    self._searchBox = searchBox
    self._results = results
    self._popupMaid = maid
    self._selectedIndex = 1
    self:_rebuildResults("")

    maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self._selectedIndex = 1
        self:_rebuildResults(searchBox.Text)
    end))
    maid:Give(blocker.Activated:Connect(function()
        self:Close()
    end))
    maid:Give(self.Library.InputManager:PushEscape(function()
        self:Close()
    end))
end

function CommandPalette:_destroyPopup()
    if self._popupMaid then self._popupMaid:Destroy() end
    self._blocker = nil
    self._surface = nil
    self._scale = nil
    self._searchBox = nil
    self._results = nil
    self._popupMaid = nil
    table.clear(self._filtered)
    table.clear(self._resultRows)
end

function CommandPalette:_animate(opening)
    if not self._surface or not self._scale then return end
    self.Library.Animation:Cancel(self._surface)
    self.Library.Animation:Cancel(self._scale)
    local duration = opening and self.Library.Tokens.Animation.Normal or self.Library.Tokens.Animation.Fast
    local fade = self.Library.Animation:Tween(
        self._surface,
        { GroupTransparency = opening and 0 or 1 },
        duration,
        Enum.EasingStyle.Quint,
        opening and Enum.EasingDirection.Out or Enum.EasingDirection.In
    )
    self.Library.Animation:Tween(
        self._scale,
        { Scale = opening and 1 or 0.965 },
        duration,
        Enum.EasingStyle.Quint,
        opening and Enum.EasingDirection.Out or Enum.EasingDirection.In
    )
    if not opening and fade then
        local revision = self._popupRevision
        local connection
        connection = fade.Completed:Connect(function()
            if connection then connection:Disconnect() end
            if revision == self._popupRevision and not self._isOpen then
                self:_destroyPopup()
            end
        end)
    end
end

function CommandPalette:Open()
    if self._destroyed or self.Disabled or self._isOpen then return self end
    self._isOpen = true
    self._popupRevision += 1
    self:_createPopup()
    self:_animate(true)
    task.defer(function()
        if not self._destroyed and self._isOpen and self._searchBox and self._searchBox.Parent then
            self._searchBox:CaptureFocus()
        end
    end)
    return self
end

function CommandPalette:Close()
    if not self._isOpen then return self end
    self._isOpen = false
    self._popupRevision += 1
    if self._searchBox then self._searchBox:ReleaseFocus() end
    self:_animate(false)
    return self
end

function CommandPalette:Toggle()
    return self._isOpen and self:Close() or self:Open()
end

function CommandPalette:Execute(indexOrCommand)
    if #self._filtered == 0 then return self end
    local entry
    if type(indexOrCommand) == "number" then
        entry = self._filtered[indexOrCommand]
    elseif type(indexOrCommand) == "table" then
        for _, candidate in ipairs(self._filtered) do
            if candidate.Command == indexOrCommand then entry = candidate break end
        end
    end
    entry = entry or self._filtered[self._selectedIndex]
    if not entry or entry.Command.Disabled == true then return self end

    Utilities.SafeCallback("CommandPalette", tostring(entry.Command.Name or entry.Index), entry.Command.Callback, entry.Command, entry.Index)
    self:_fire(entry.Command, entry.Index)
    if self.CloseOnExecute and entry.Command.KeepOpen ~= true then
        self:Close()
    end
    return self
end

function CommandPalette:SetCommands(commands)
    if type(commands) ~= "table" then
        error("[Note] CommandPalette:SetCommands expected an array", 2)
    end
    self.Commands = table.clone(commands)
    if self._results then
        self._selectedIndex = 1
        self:_rebuildResults(self._searchBox and self._searchBox.Text or "")
    end
    return self
end

function CommandPalette:GetCommands()
    return table.clone(self.Commands)
end

function CommandPalette:Destroy()
    self._popupRevision += 1
    self._isOpen = false
    self:_destroyPopup()
    BaseComponent.Destroy(self)
end

return CommandPalette
