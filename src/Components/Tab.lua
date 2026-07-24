local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Signal = require("src/Core/Signal")
local Icons = require("src/Core/Icons")
local Section = require("src/Components/Section")

local Tab = {}
Tab.__index = Tab

function Tab.new(window, config)
    config = config or {}
    local self = setmetatable({
        Window = window,
        Library = window.Library,
        Name = tostring(config.Name or "Tab"),
        Icon = config.Icon,
        Disabled = config.Disabled == true,
        Visible = config.Visible ~= false,
        Selected = Signal.new(),
        Destroyed = Signal.new(),
        Sections = {},
        Maid = Maid.new(),
        _layoutOrder = 0,
        _destroyed = false,
    }, Tab)

    local button = Utilities.Create("TextButton", {
        Name = "Tab_" .. self.Name,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 38),
        Text = "",
        Visible = self.Visible,
        LayoutOrder = window:_nextTabOrder(),
        Parent = window.TabList,
    })
    Utilities.Corner(button, self.Library.Tokens.Radius.Medium)
    local indicator = Utilities.Create("Frame", {
        Name = "Indicator",
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -9),
        Size = UDim2.fromOffset(3, 18),
        BackgroundTransparency = 1,
        Parent = button,
    })
    Utilities.Corner(indicator, 999)
    self.Window.ThemeManager:Bind(indicator, { BackgroundColor3 = "Accent" })

    local left = 12
    if self.Icon then
        local icon = Icons.Create({ Name = self.Icon, Size = 16, Parent = button })
        icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
        icon.Instance.Position = UDim2.new(0, 12, 0.5, 0)
        self.Window.ThemeManager:Bind(icon.Instance, {
            ImageColor3 = function(theme, accent)
                return self.Window.ActiveTab == self and accent or theme.TextSecondary
            end,
        })
        self.IconObject = icon
        self.Maid:Give(icon)
        left = 38
    end

    local label = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(left, 0),
        Size = UDim2.new(1, -left - 8, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = self.Name,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = button,
    })
    self.Window.ThemeManager:Bind(label, {
        TextColor3 = function(theme, accent)
            return self.Window.ActiveTab == self and theme.Text or theme.TextSecondary
        end,
    })

    local page = Utilities.Create("ScrollingFrame", {
        Name = "Page_" .. self.Name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = window.Pages,
    })
    self.Window.ThemeManager:Bind(page, { ScrollBarImageColor3 = "Scrollbar" })
    Utilities.Padding(page, 14, 14, 14, 14)
    local pageList = Utilities.List(page, Enum.FillDirection.Vertical, 12)
    self.Maid:Give(pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0, pageList.AbsoluteContentSize.Y + 28)
    end))

    local empty = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.48),
        Size = UDim2.new(1, -40, 0, 44),
        Font = Enum.Font.Gotham,
        Text = "No matching controls",
        TextSize = 12,
        Visible = false,
        Parent = page,
    })
    self.Window.ThemeManager:Bind(empty, { TextColor3 = "TextMuted" })

    self.Button = button
    self.Label = label
    self.Indicator = indicator
    self.Page = page
    self.PageContent = page
    self.PageList = pageList
    self.EmptyState = empty
    self.Maid:Give(button)
    self.Maid:Give(page)
    self.Maid:Give(self.Selected)
    self.Maid:Give(self.Destroyed)
    self.Maid:Give(button.Activated:Connect(function()
        self:Select()
    end))
    self.Maid:Give(button.MouseEnter:Connect(function()
        if self.Window.ActiveTab ~= self and not self.Disabled then
            self.Library.Animation:Tween(button, { BackgroundTransparency = 0.75 }, self.Library.Tokens.Animation.Fast)
            button.BackgroundColor3 = self.Window.ThemeManager:Get("SurfaceHover")
        end
    end))
    self.Maid:Give(button.MouseLeave:Connect(function()
        if self.Window.ActiveTab ~= self then
            self.Library.Animation:Tween(button, { BackgroundTransparency = 1 }, self.Library.Tokens.Animation.Fast)
        end
    end))

    window:_registerTab(self)
    return self
end

function Tab:_nextLayoutOrder()
    self._layoutOrder += 1
    return self._layoutOrder
end

function Tab:_registerSection(section)
    table.insert(self.Sections, section)
end

function Tab:_unregisterSection(section)
    local index = table.find(self.Sections, section)
    if index then table.remove(self.Sections, index) end
end

function Tab:Select()
    if self._destroyed or self.Disabled or not self.Visible then return self end
    self.Window:_selectTab(self)
    return self
end

function Tab:_setSelected(selected)
    self.Page.Visible = selected
    self.Button.BackgroundColor3 = self.Window.ThemeManager:Get(selected and "SurfaceSelected" or "SurfaceHover")
    self.Library.Animation:Tween(self.Button, {
        BackgroundTransparency = selected and 0 or 1,
    }, self.Library.Tokens.Animation.Fast)
    self.Library.Animation:Tween(self.Indicator, {
        BackgroundTransparency = selected and 0 or 1,
        Size = UDim2.fromOffset(3, selected and 18 or 8),
    }, self.Library.Tokens.Animation.Normal)
    self.Window.ThemeManager:Apply(self.Label, true)
    if self.IconObject then
        self.Window.ThemeManager:Apply(self.IconObject.Instance, true)
    end
    if selected then
        self.Selected:Fire()
    end
end

function Tab:ApplySearch(query)
    local any = false
    for _, section in ipairs(self.Sections) do
        any = section:ApplySearch(query) or any
    end
    self.EmptyState.Visible = query ~= "" and not any
end

function Tab:CreateSection(config)
    return Section.new(self, config)
end

function Tab:SetName(name)
    self.Name = tostring(name)
    self.Label.Text = self.Name
    return self
end

function Tab:SetIcon(name)
    self.Icon = name
    if self.IconObject then
        self.IconObject:SetIcon(name)
    elseif name then
        local icon = Icons.Create({ Name = name, Size = 16, Parent = self.Button })
        icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
        icon.Instance.Position = UDim2.new(0, 12, 0.5, 0)
        self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextSecondary" })
        self.IconObject = icon
        self.Label.Position = UDim2.fromOffset(38, 0)
        self.Label.Size = UDim2.new(1, -46, 1, 0)
        self.Maid:Give(icon)
    end
    return self
end

function Tab:SetDisabled(value)
    self.Disabled = value == true
    self.Button.Active = not self.Disabled
    self.Button.BackgroundTransparency = self.Disabled and 0.85 or (self.Window.ActiveTab == self and 0 or 1)
    return self
end

function Tab:SetVisible(value)
    self.Visible = value == true
    self.Button.Visible = self.Visible
    if not self.Visible and self.Window.ActiveTab == self then
        self.Window:_selectFallbackTab(self)
    end
    return self
end

function Tab:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    local wasActive = self.Window.ActiveTab == self
    for i = #self.Sections, 1, -1 do
        self.Sections[i]:Destroy()
    end
    self.Destroyed:Fire()
    self.Window:_unregisterTab(self)
    self.Maid:Destroy()
    if wasActive then
        self.Window:_selectFallbackTab(self)
    end
end

return Tab
