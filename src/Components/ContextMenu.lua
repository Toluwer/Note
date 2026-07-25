local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")
local Layout = require("src/Core/Layout")
local Maid = require("src/Core/Maid")

local ContextMenu = {}
ContextMenu.__index = ContextMenu
setmetatable(ContextMenu, { __index = BaseComponent })

local function itemHeight(item)
    return item.Type == "Divider" and 9 or 34
end

function ContextMenu.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "ContextMenu", config, 58)
    setmetatable(self, ContextMenu)

    self.Items = table.clone(config.Items or {})
    self.Width = math.max(170, tonumber(config.Width) or 220)
    self.MaxHeight = math.max(120, tonumber(config.MaxHeight) or 320)
    self.CloseOnSelect = config.CloseOnSelect ~= false
    self.Target = nil
    self._isOpen = false
    self._popupRevision = 0
    self:AddTextBlock(-160)

    local action = Utilities.Create("TextButton", {
        Name = "OpenMenu",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(124, 34),
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

    local icon = Icons.Create({ Name = config.Icon or "menu", Size = 15, Parent = action })
    icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
    icon.Instance.Position = UDim2.new(0, 10, 0.5, 0)
    self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextSecondary" })
    self.Maid:Give(icon)

    local label = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = config.ButtonText or "Open menu",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = action,
    })
    self.Window.ThemeManager:Bind(label, { TextColor3 = "TextSecondary" })

    self.Action = action
    self.Maid:Give(action.Activated:Connect(function()
        if not self.Disabled then self:Toggle() end
    end))

    if config.Target then
        self:Bind(config.Target)
    end
    return self
end

function ContextMenu:_popupHeight()
    local total = 12
    for _, item in ipairs(self.Items) do
        total += itemHeight(item)
    end
    return math.min(self.MaxHeight, math.max(46, total))
end

function ContextMenu:_positionAt(point)
    if not self._popup or not self._popup.Parent then return end
    local inset = select(1, GuiService:GetGuiInset())
    local rootSize = self.Library.Overlay.Root.AbsoluteSize
    local x = point.X - inset.X
    local y = point.Y - inset.Y
    x = Utilities.Clamp(x, 8, math.max(8, rootSize.X - self._popup.AbsoluteSize.X - 8))
    y = Utilities.Clamp(y, 8, math.max(8, rootSize.Y - self._popup.AbsoluteSize.Y - 8))
    self._popup.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
end

function ContextMenu:_invoke(item, index)
    if item.Disabled == true then return end
    if item.Checkable then
        item.Checked = not item.Checked
        self:_buildItems()
    end
    Utilities.SafeCallback("ContextMenu", tostring(item.Name or index), item.Callback, item, index)
    self:_fire(item, index)
    if self.CloseOnSelect and item.KeepOpen ~= true and not item.Checkable then
        self:Close()
    end
end

function ContextMenu:_buildItems()
    if not self._list then return end
    for _, child in ipairs(self._list:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    for index, item in ipairs(self.Items) do
        if item.Type == "Divider" then
            local divider = Utilities.Create("Frame", {
                Name = "Divider",
                BorderSizePixel = 0,
                Size = UDim2.new(1, -12, 0, 1),
                LayoutOrder = index,
                Parent = self._list,
            })
            self.Window.ThemeManager:Bind(divider, {
                BackgroundColor3 = "Border",
                BackgroundTransparency = "BorderTransparency",
            })
        else
            local disabled = item.Disabled == true
            local row = Utilities.Create("TextButton", {
                Name = "Item_" .. tostring(item.Name or index),
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 34),
                LayoutOrder = index,
                Text = "",
                Parent = self._list,
            })
            Utilities.Corner(row, self.Library.Tokens.Radius.Small)
            self.Window.ThemeManager:Bind(row, {
                BackgroundColor3 = "SurfaceElevated",
                BackgroundTransparency = function(theme)
                    return disabled and (theme.DisabledTransparency or 0.58) or 1
                end,
            })

            local left = 10
            if item.Icon then
                local itemIcon = Icons.Create({ Name = item.Icon, Size = 14, Parent = row, ZIndex = 213 })
                itemIcon.Instance.AnchorPoint = Vector2.new(0, 0.5)
                itemIcon.Instance.Position = UDim2.new(0, 9, 0.5, 0)
                self.Window.ThemeManager:Bind(itemIcon.Instance, {
                    ImageColor3 = item.Destructive and "Destructive" or (disabled and "TextMuted" or "TextSecondary"),
                })
                left = 32
            elseif item.Checkable then
                left = 32
            end

            if item.Checkable and item.Checked then
                local check = Icons.Create({ Name = "check", Size = 14, Parent = row, ZIndex = 213 })
                check.Instance.AnchorPoint = Vector2.new(0, 0.5)
                check.Instance.Position = UDim2.new(0, 9, 0.5, 0)
                self.Window.ThemeManager:Bind(check.Instance, { ImageColor3 = "Accent" })
            end

            local shortcutWidth = item.Shortcut and 82 or 12
            local text = Utilities.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(left, 0),
                Size = UDim2.new(1, -left - shortcutWidth, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(item.Name or "Item"),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 213,
                Parent = row,
            })
            self.Window.ThemeManager:Bind(text, {
                TextColor3 = item.Destructive and "Destructive" or (disabled and "TextMuted" or "Text"),
            })

            if item.Shortcut then
                local shortcut = Utilities.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -9, 0, 0),
                    Size = UDim2.fromOffset(72, 34),
                    Font = Enum.Font.Code,
                    Text = tostring(item.Shortcut),
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 213,
                    Parent = row,
                })
                self.Window.ThemeManager:Bind(shortcut, { TextColor3 = "TextMuted" })
            end

            row.MouseEnter:Connect(function()
                if not disabled then
                    self.Library.Animation:Tween(row, { BackgroundTransparency = 0 }, self.Library.Tokens.Animation.Fast)
                end
            end)
            row.MouseLeave:Connect(function()
                self.Window.ThemeManager:Apply(row, true)
            end)
            row.Activated:Connect(function()
                self:_invoke(item, index)
            end)
        end
    end
end

function ContextMenu:_createPopup()
    local maid = Maid.new()
    local popup = Utilities.Create("Frame", {
        Name = "ContextMenuRoot",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(self.Width, self:_popupHeight()),
        Active = true,
        ZIndex = 205,
        Parent = self.Library.Overlay:GetLayer("Popovers"),
    })
    maid:Give(popup)

    local surface = Utilities.Create("CanvasGroup", {
        Name = "ContextMenu",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 206,
        Parent = popup,
    })
    Utilities.Corner(surface, self.Library.Tokens.Radius.Large)
    local stroke = Utilities.Stroke(surface, Color3.new(), 1, 0)
    stroke.ZIndex = 207
    self.Window.ThemeManager:Bind(surface, {
        BackgroundColor3 = "SurfaceElevated",
        BackgroundTransparency = "ElevatedTransparency",
    })
    self.Window.ThemeManager:Bind(stroke, {
        Color = "Border",
        Transparency = "BorderTransparency",
    })

    local scale = Utilities.Create("UIScale", { Scale = 0.965, Parent = surface })
    local list = Utilities.Create("ScrollingFrame", {
        Name = "Items",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 1, -12),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ZIndex = 211,
        Parent = surface,
    })
    local layout = Utilities.List(list, Enum.FillDirection.Vertical, 0)
    maid:Give(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
    end))
    self.Window.ThemeManager:Bind(list, { ScrollBarImageColor3 = "Scrollbar" })

    self._popup = popup
    self._surface = surface
    self._scale = scale
    self._list = list
    self._popupMaid = maid
    self:_buildItems()

    maid:Give(self.Library.InputManager:RegisterOutside({ popup, self.Action, self.Target }, function()
        self:Close()
    end))
    maid:Give(self.Library.InputManager:PushEscape(function()
        self:Close()
    end))
end

function ContextMenu:_animate(opening)
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

function ContextMenu:_destroyPopup()
    if self._popupMaid then self._popupMaid:Destroy() end
    self._popup = nil
    self._surface = nil
    self._scale = nil
    self._list = nil
    self._popupMaid = nil
end

function ContextMenu:Open()
    if self._destroyed or self.Disabled or self._isOpen then return self end
    self._isOpen = true
    self._popupRevision += 1
    if not self._popup then self:_createPopup() end

    local anchor = self.Target or self.Action
    local function reposition()
        if self._popup and anchor and anchor.Parent then
            Layout.PositionOverlay(anchor, self._popup, self.Library.Overlay.Root, self.Width)
        end
    end
    reposition()
    self._popupMaid:Replace("AnchorTracking", RunService.Heartbeat:Connect(reposition))
    self:_animate(true)
    return self
end

function ContextMenu:OpenAt(point)
    if self._destroyed or self.Disabled then return self end
    if self._isOpen then self:_destroyPopup() end
    self._isOpen = true
    self._popupRevision += 1
    self:_createPopup()
    self:_positionAt(point)
    self:_animate(true)
    return self
end

function ContextMenu:Close()
    if not self._isOpen then return self end
    self._isOpen = false
    self._popupRevision += 1
    if self._popupMaid then self._popupMaid:Replace("AnchorTracking", nil) end
    self:_animate(false)
    return self
end

function ContextMenu:Toggle()
    return self._isOpen and self:Close() or self:Open()
end

function ContextMenu:SetItems(items)
    if type(items) ~= "table" then
        error("[Note] ContextMenu:SetItems expected an array", 2)
    end
    self.Items = table.clone(items)
    if self._popup then
        self._popup.Size = UDim2.fromOffset(self.Width, self:_popupHeight())
        self:_buildItems()
    end
    return self
end

function ContextMenu:Bind(target)
    if target ~= nil and typeof(target) ~= "Instance" then
        error("[Note] ContextMenu:Bind expected a GuiObject or nil", 2)
    end
    self.Target = target
    self.Maid:Replace("ContextTarget", nil)
    if target and target:IsA("GuiObject") then
        self.Maid:Replace("ContextTarget", target.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 and not self.Disabled then
                self:OpenAt(input.Position)
            end
        end))
    end
    return self
end

function ContextMenu:Destroy()
    self._popupRevision += 1
    self._isOpen = false
    self:_destroyPopup()
    BaseComponent.Destroy(self)
end

return ContextMenu
