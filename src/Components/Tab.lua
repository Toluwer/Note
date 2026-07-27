local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Signal = require("src/Core/Signal")
local Icons = require("src/Core/Icons")
local Section = require("src/Components/Section")

local Tab = {}
Tab.__index = Tab

local function normalizeLayout(value)
    return string.lower(tostring(value or "Single")) == "split" and "Split" or "Single"
end

local function normalizeSide(value)
    return string.lower(tostring(value or "Left")) == "right" and "Right" or "Left"
end

function Tab.new(window, config)
    config = config or {}
    local self = setmetatable({
        Window = window,
        Library = window.Library,
        Name = tostring(config.Name or "Tab"),
        Icon = config.Icon,
        Layout = normalizeLayout(config.Layout or (config.Split and "Split" or "Single")),
        StackAt = tonumber(config.StackAt),
        SplitGap = math.max(4, tonumber(config.SplitGap) or 12),
        Disabled = config.Disabled == true,
        Visible = config.Visible ~= false,
        Selected = Signal.new(),
        Destroyed = Signal.new(),
        Sections = {},
        Maid = Maid.new(),
        _layoutOrder = 0,
        _stacked = false,
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
    self.Window.ThemeManager:Bind(button, {
        BackgroundColor3 = function(theme)
            return self.Window.ActiveTab == self and theme.SurfaceSelected or theme.SurfaceHover
        end,
        BackgroundTransparency = function(theme)
            if self.Disabled then
                return theme.DisabledTransparency or 0.62
            elseif self.Window.ActiveTab == self then
                return theme.SelectedTransparency or 0.08
            elseif self._hovered then
                return theme.HoverTransparency or 0.14
            end
            return 1
        end,
    })
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
                if self.Disabled then return theme.TextMuted end
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
            if self.Disabled then return theme.TextMuted end
            return self.Window.ActiveTab == self and theme.Text or theme.TextSecondary
        end,
    })

    local page = Utilities.Create("ScrollingFrame", {
        Name = "Page_" .. self.Name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.new(1, -6, 1, -12),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.10,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = window.Pages,
    })
    self.Window.ThemeManager:Bind(page, { ScrollBarImageColor3 = "Scrollbar" })

    local content = Utilities.Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.new(1, -28, 0, 0),
        Parent = page,
    })

    local singleColumn = Utilities.Create("Frame", {
        Name = "SingleColumn",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = self.Layout == "Single",
        Parent = content,
    })
    local singleList = Utilities.List(singleColumn, Enum.FillDirection.Vertical, 12)

    local splitRoot = Utilities.Create("Frame", {
        Name = "SplitColumns",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = self.Layout == "Split",
        Parent = content,
    })

    local leftColumn = Utilities.Create("Frame", {
        Name = "LeftColumn",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0.5, -6, 0, 0),
        Parent = splitRoot,
    })
    local leftList = Utilities.List(leftColumn, Enum.FillDirection.Vertical, 12)

    local rightColumn = Utilities.Create("Frame", {
        Name = "RightColumn",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 6, 0, 0),
        Size = UDim2.new(0.5, -6, 0, 0),
        Parent = splitRoot,
    })
    local rightList = Utilities.List(rightColumn, Enum.FillDirection.Vertical, 12)

    local function updatePageLayout()
        if self._destroyed then return end

        local height = 0
        local split = self.Layout == "Split"
        singleColumn.Visible = not split
        splitRoot.Visible = split

        if not split then
            height = math.max(0, singleList.AbsoluteContentSize.Y)
            singleColumn.Position = UDim2.fromOffset(0, 0)
            singleColumn.Size = UDim2.new(1, 0, 0, height)
            self._stacked = false
        else
            local gap = self.SplitGap
            local leftHeight = math.max(0, leftList.AbsoluteContentSize.Y)
            local rightHeight = math.max(0, rightList.AbsoluteContentSize.Y)
            local availableWidth = math.max(0, content.AbsoluteSize.X)
            local stacked = self.StackAt ~= nil and self.StackAt > 0 and availableWidth < self.StackAt
            self._stacked = stacked

            if stacked then
                local between = leftHeight > 0 and rightHeight > 0 and gap or 0
                leftColumn.Position = UDim2.fromOffset(0, 0)
                leftColumn.Size = UDim2.new(1, 0, 0, leftHeight)
                rightColumn.Position = UDim2.fromOffset(0, leftHeight + between)
                rightColumn.Size = UDim2.new(1, 0, 0, rightHeight)
                height = leftHeight + between + rightHeight
            else
                local halfGap = gap * 0.5
                leftColumn.Position = UDim2.fromOffset(0, 0)
                leftColumn.Size = UDim2.new(0.5, -halfGap, 0, leftHeight)
                rightColumn.Position = UDim2.new(0.5, halfGap, 0, 0)
                rightColumn.Size = UDim2.new(0.5, -halfGap, 0, rightHeight)
                height = math.max(leftHeight, rightHeight)
            end

            splitRoot.Size = UDim2.new(1, 0, 0, height)
        end

        content.Size = UDim2.new(1, -28, 0, height)
        page.CanvasSize = UDim2.fromOffset(0, height + 28)
    end

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
    self.PageContent = singleColumn
    self.ContentRoot = content
    self.SingleColumn = singleColumn
    self.SplitRoot = splitRoot
    self.LeftColumn = leftColumn
    self.RightColumn = rightColumn
    self.PageList = singleList
    self.LeftList = leftList
    self.RightList = rightList
    self.EmptyState = empty
    self._updatePageLayout = updatePageLayout

    self.Maid:Give(button)
    self.Maid:Give(page)
    self.Maid:Give(self.Selected)
    self.Maid:Give(self.Destroyed)
    self.Maid:Give(page:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePageLayout))
    self.Maid:Give(singleList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageLayout))
    self.Maid:Give(leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageLayout))
    self.Maid:Give(rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageLayout))
    self.Maid:Give(button.Activated:Connect(function()
        self:Select()
    end))
    self.Maid:Give(button.MouseEnter:Connect(function()
        self._hovered = true
        self.Window.ThemeManager:Apply(button, true)
    end))
    self.Maid:Give(button.MouseLeave:Connect(function()
        self._hovered = false
        self.Window.ThemeManager:Apply(button, true)
    end))

    task.defer(updatePageLayout)
    window:_registerTab(self)
    return self
end

function Tab:_nextLayoutOrder()
    self._layoutOrder += 1
    return self._layoutOrder
end

function Tab:_normalizeSide(side)
    return normalizeSide(side)
end

function Tab:_getSectionParent(side)
    if self.Layout == "Split" then
        return normalizeSide(side) == "Right" and self.RightColumn or self.LeftColumn
    end
    return self.SingleColumn
end

function Tab:_refreshLayout()
    if self._updatePageLayout then
        task.defer(self._updatePageLayout)
    end
end

function Tab:_reparentSections()
    for _, section in ipairs(self.Sections) do
        if section.Frame and section.Frame.Parent then
            section.Frame.Parent = self:_getSectionParent(section.Side)
        end
    end
    self:_refreshLayout()
end

function Tab:_registerSection(section)
    table.insert(self.Sections, section)
    self:_refreshLayout()
end

function Tab:_unregisterSection(section)
    local index = table.find(self.Sections, section)
    if index then table.remove(self.Sections, index) end
    self:_refreshLayout()
end

function Tab:Select()
    if self._destroyed or self.Disabled or not self.Visible then return self end
    self.Window:_selectTab(self)
    return self
end

function Tab:_setSelected(selected)
    self.Page.Visible = selected
    self.Window.ThemeManager:Apply(self.Button, true)
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
        self:_refreshLayout()
    end
end

function Tab:ApplySearch(query)
    local any = false
    for _, section in ipairs(self.Sections) do
        any = section:ApplySearch(query) or any
    end
    self.EmptyState.Visible = query ~= "" and not any
    self:_refreshLayout()
end

function Tab:CreateSection(config)
    config = config or {}
    local side = normalizeSide(config.Side)
    local previousParent = self.PageContent
    self.PageContent = self:_getSectionParent(side)
    local ok, section = pcall(Section.new, self, config)
    self.PageContent = previousParent
    if not ok then
        error(section, 2)
    end

    section.Side = side

    function section:SetSide(newSide)
        if self._destroyed then return self end
        newSide = self.Tab:_normalizeSide(newSide)
        if self.Side == newSide then return self end
        self.Side = newSide
        if self.Frame and self.Frame.Parent then
            self.Frame.Parent = self.Tab:_getSectionParent(newSide)
        end
        self.Tab:_refreshLayout()
        return self
    end

    function section:GetSide()
        return self.Side
    end

    return section
end

function Tab:SetLayout(layout)
    layout = normalizeLayout(layout)
    if self.Layout == layout then return self end
    self.Layout = layout
    self:_reparentSections()
    return self
end

function Tab:GetLayout()
    return self.Layout
end

function Tab:SetSplitEnabled(value)
    return self:SetLayout(value == true and "Split" or "Single")
end

function Tab:SetStackBreakpoint(width)
    if width == nil or width == false then
        self.StackAt = nil
    else
        width = tonumber(width)
        if not width or width <= 0 then
            error("[Note] Tab:SetStackBreakpoint expected a positive number or nil", 2)
        end
        self.StackAt = width
    end
    self:_refreshLayout()
    return self
end

function Tab:IsStacked()
    return self._stacked == true
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
    self.Window.ThemeManager:Apply(self.Button, true)
    self.Window.ThemeManager:Apply(self.Label, true)
    if self.IconObject then self.Window.ThemeManager:Apply(self.IconObject.Instance, true) end
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
