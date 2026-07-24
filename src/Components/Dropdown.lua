local RunService = game:GetService("RunService")
local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")
local Layout = require("src/Core/Layout")
local Maid = require("src/Core/Maid")
local Validation = require("src/Core/Validation")

local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = BaseComponent })

local function contains(array, value)
    return table.find(array, value) ~= nil
end

function Dropdown.new(section, config)
    config = config or {}
    Validation.Dropdown(config)
    local self = BaseComponent.new(section, "Dropdown", config, 82)
    setmetatable(self, Dropdown)
    self.Options = table.clone(config.Options or {})
    self.Searchable = config.Searchable ~= false
    self.Multi = config.Multi == true or config.MultiSelect == true
    self.Value = self.Multi and {} or config.Default
    if self.Multi and type(config.Default) == "table" then
        self.Value = table.clone(config.Default)
    elseif not self.Multi and self.Value == nil and config.AllowEmpty ~= true then
        self.Value = self.Options[1]
    end
    self:AddTextBlock(-12)

    local selectButton = Utilities.Create("TextButton", {
        Name = "Select",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -38),
        Size = UDim2.new(1, -24, 0, 30),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Frame,
    })
    Utilities.Corner(selectButton, self.Library.Tokens.Radius.Medium)
    local stroke = Utilities.Stroke(selectButton, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(selectButton, { BackgroundColor3 = "Input", BackgroundTransparency = "InputTransparency", TextColor3 = "Text" })
    self.Window.ThemeManager:Bind(stroke, { Color = "Border", Transparency = "BorderTransparency" })
    local selectedLabel = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -42, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = selectButton,
    })
    self.Window.ThemeManager:Bind(selectedLabel, { TextColor3 = "Text" })
    local chevron = Icons.Create({ Name = "chevron-down", Size = 15, Parent = selectButton })
    chevron.Instance.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Instance.Position = UDim2.new(1, -9, 0.5, 0)
    self.Window.ThemeManager:Bind(chevron.Instance, { ImageColor3 = "TextMuted" })
    self.Maid:Give(chevron)

    self.SelectButton = selectButton
    self.SelectedLabel = selectedLabel
    self.Chevron = chevron
    self.Maid:Give(selectButton.Activated:Connect(function()
        if not self.Disabled then
            self:Toggle()
        end
    end))
    self:_refreshLabel()
    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    return self
end

function Dropdown:_refreshLabel()
    if self.Multi then
        if #self.Value == 0 then
            self.SelectedLabel.Text = "Select…"
        elseif #self.Value == 1 then
            self.SelectedLabel.Text = tostring(self.Value[1])
        else
            self.SelectedLabel.Text = string.format("%d selected", #self.Value)
        end
    else
        self.SelectedLabel.Text = self.Value == nil and "Select…" or tostring(self.Value)
    end
end

function Dropdown:_select(option)
    if self.Multi then
        local values = table.clone(self.Value)
        local index = table.find(values, option)
        if index then
            table.remove(values, index)
        else
            table.insert(values, option)
        end
        self:SetValue(values)
        self:_rebuildOptions(self._searchText or "")
    else
        self:SetValue(option)
        self:Close()
    end
end

function Dropdown:_rebuildOptions(query)
    if not self._list then return end
    for _, child in ipairs(self._list:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    local normalized = Utilities.NormalizeSearch(query)
    local count = 0
    for _, option in ipairs(self.Options) do
        if normalized == "" or string.find(Utilities.NormalizeSearch(option), normalized, 1, true) then
            count += 1
            local selected = self.Multi and contains(self.Value, option) or self.Value == option
            local row = Utilities.Create("TextButton", {
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -2, 0, 32),
                Font = Enum.Font.Gotham,
                Text = tostring(option),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 212,
                Parent = self._list,
            })
            Utilities.Padding(row, 10, 34, 0, 0)
            Utilities.Corner(row, self.Library.Tokens.Radius.Small)
            self.Window.ThemeManager:Bind(row, {
                BackgroundColor3 = selected and "SurfaceSelected" or "Surface",
                BackgroundTransparency = selected and "SelectedTransparency" or "SurfaceTransparency",
                TextColor3 = "Text",
            })
            if selected then
                local check = Icons.Create({ Name = "check", Size = 14, Parent = row, ZIndex = 213 })
                check.Instance.AnchorPoint = Vector2.new(1, 0.5)
                check.Instance.Position = UDim2.new(1, -9, 0.5, 0)
                self.Window.ThemeManager:Bind(check.Instance, { ImageColor3 = "Accent" })
            end
            row.MouseEnter:Connect(function()
                self.Library.Animation:Tween(row, { BackgroundTransparency = math.max(0, row.BackgroundTransparency - 0.08) }, self.Library.Tokens.Animation.Fast)
            end)
            row.MouseLeave:Connect(function()
                self.Window.ThemeManager:Apply(row, true)
            end)
            row.Activated:Connect(function()
                self:_select(option)
            end)
        end
    end
    if count == 0 then
        local empty = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -2, 0, 44),
            Font = Enum.Font.Gotham,
            Text = #self.Options == 0 and "No options" or "No matches",
            TextSize = 11,
            ZIndex = 212,
            Parent = self._list,
        })
        self.Window.ThemeManager:Bind(empty, { TextColor3 = "TextMuted" })
    end
end

function Dropdown:Open()
    if self._destroyed or self._popup or self.Disabled then return self end
    local maid = Maid.new()
    self._popupMaid = maid
    local popup = Utilities.Create("Frame", {
        Name = "DropdownPopup",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(math.max(self.SelectButton.AbsoluteSize.X, 220), 236),
        ZIndex = 205,
        Parent = self.Library.Overlay:GetLayer("Popovers"),
    })
    Utilities.Corner(popup, self.Library.Tokens.Radius.Large)
    local popupStroke = Utilities.Stroke(popup, Color3.new(), 1, 0)
    popupStroke.ZIndex = 206
    self.Window.ThemeManager:Bind(popup, { BackgroundColor3 = "SurfaceElevated", BackgroundTransparency = "ElevatedTransparency" })
    self.Window.ThemeManager:Bind(popupStroke, { Color = "Border", Transparency = "BorderTransparency" })
    maid:Give(popup)

    local topOffset = 8
    if self.Searchable then
        local searchFrame = Utilities.Create("Frame", {
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.new(1, -16, 0, 32),
            ZIndex = 207,
            Parent = popup,
        })
        Utilities.Corner(searchFrame, self.Library.Tokens.Radius.Medium)
        local searchStroke = Utilities.Stroke(searchFrame, Color3.new(), 1, 0)
        self.Window.ThemeManager:Bind(searchFrame, { BackgroundColor3 = "Input", BackgroundTransparency = "InputTransparency" })
        self.Window.ThemeManager:Bind(searchStroke, { Color = "Border", Transparency = "BorderTransparency" })
        local icon = Icons.Create({ Name = "search", Size = 14, Parent = searchFrame, ZIndex = 209 })
        icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
        icon.Instance.Position = UDim2.new(0, 9, 0.5, 0)
        self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextMuted" })
        maid:Give(icon)
        local searchBox = Utilities.Create("TextBox", {
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            Position = UDim2.fromOffset(31, 0),
            Size = UDim2.new(1, -40, 1, 0),
            Font = Enum.Font.Gotham,
            PlaceholderText = "Search options",
            Text = "",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 209,
            Parent = searchFrame,
        })
        self.Window.ThemeManager:Bind(searchBox, { TextColor3 = "Text", PlaceholderColor3 = "TextMuted" })
        maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            self._searchText = searchBox.Text
            self:_rebuildOptions(searchBox.Text)
        end))
        topOffset = 48
        self._searchBox = searchBox
    end

    local list = Utilities.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, topOffset),
        Size = UDim2.new(1, -16, 1, -topOffset - 8),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ZIndex = 208,
        Parent = popup,
    })
    local listLayout = Utilities.List(list, Enum.FillDirection.Vertical, 4)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y)
    end)
    self.Window.ThemeManager:Bind(list, { ScrollBarImageColor3 = "Scrollbar" })
    self._popup = popup
    self._list = list
    self:_rebuildOptions("")
    self.Chevron:SetIcon("chevron-up")

    local function reposition()
        if popup.Parent and self.SelectButton.Parent then
            Layout.PositionOverlay(self.SelectButton, popup, self.Library.Overlay.Root)
        end
    end
    reposition()
    maid:Give(RunService.Heartbeat:Connect(reposition))
    maid:Give(self.Library.InputManager:RegisterOutside({ popup, self.SelectButton }, function()
        self:Close()
    end))
    maid:Give(self.Library.InputManager:PushEscape(function() self:Close() end))
    popup.BackgroundTransparency = 1
    popup.Size = UDim2.fromOffset(popup.Size.X.Offset, 206)
    self.Library.Animation:Tween(popup, {
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(popup.Size.X.Offset, 236),
    }, self.Library.Tokens.Animation.Normal)
    if self._searchBox then
        task.defer(function()
            if self._searchBox and self._searchBox.Parent then
                self._searchBox:CaptureFocus()
            end
        end)
    end
    return self
end

function Dropdown:Close()
    if not self._popup then return self end
    local popup = self._popup
    self._popup = nil
    self._list = nil
    self._searchBox = nil
    self.Chevron:SetIcon("chevron-down")
    self.Library.Animation:Tween(popup, {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(popup.Size.X.Offset, math.max(150, popup.Size.Y.Offset - 24)),
    }, self.Library.Tokens.Animation.Fast)
    local popupMaid = self._popupMaid
    self._popupMaid = nil
    task.delay(self.Library.Tokens.Animation.Fast, function()
        if popupMaid then
            popupMaid:Destroy()
        end
        if popup and popup.Parent then
            popup:Destroy()
        end
    end)
    return self
end

function Dropdown:Toggle()
    return self._popup and self:Close() or self:Open()
end

function Dropdown:SetValue(value, silent)
    if self._destroyed then return self end
    if self.Multi then
        if type(value) ~= "table" then
            error("[Note] Multi-select dropdown value must be a table", 2)
        end
        local filtered = {}
        for _, option in ipairs(value) do
            if table.find(self.Options, option) and not table.find(filtered, option) then
                table.insert(filtered, option)
            end
        end
        self.Value = filtered
    else
        if value ~= nil and not table.find(self.Options, value) then
            error(string.format('[Note] Dropdown "%s": value is not in Options.', self.Name), 2)
        end
        if self.Value == value and not silent then return self end
        self.Value = value
    end
    self:_refreshLabel()
    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    if not silent then
        self:_fire(self.Value)
    end
    return self
end

function Dropdown:GetValue()
    return self.Multi and table.clone(self.Value) or self.Value
end

function Dropdown:SetOptions(options)
    if type(options) ~= "table" then
        error("[Note] Dropdown:SetOptions expected an array", 2)
    end
    self.Options = table.clone(options)
    if self.Multi then
        self:SetValue(self.Value, true)
    elseif self.Value ~= nil and not table.find(self.Options, self.Value) then
        self:SetValue(self.Options[1], true)
    end
    if self._popup then self:_rebuildOptions(self._searchText or "") end
    return self
end

function Dropdown:Destroy()
    self:Close()
    BaseComponent.Destroy(self)
end

return Dropdown
