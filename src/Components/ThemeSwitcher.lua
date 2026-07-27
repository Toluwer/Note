local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")

local ThemeSwitcher = {}
ThemeSwitcher.__index = ThemeSwitcher
setmetatable(ThemeSwitcher, { __index = BaseComponent })

local function resolveThemes(library, configured)
    if configured ~= nil then
        assert(type(configured) == "table" and #configured > 0, "[Note] ThemeSwitcher Themes must be a non-empty array")
        return table.clone(configured)
    end
    if type(library.GetThemeNames) == "function" then
        return library:GetThemeNames()
    end
    return { "Dark", "Light" }
end

local function chooseColumns(width, configured, count)
    if configured then
        return math.clamp(math.floor(tonumber(configured) or 1), 1, math.max(1, count))
    end
    if width < 300 then return math.min(2, count) end
    if width < 460 then return math.min(3, count) end
    if width < 660 then return math.min(4, count) end
    return math.min(5, count)
end

function ThemeSwitcher.new(section, config)
    config = config or {}
    local themes = resolveThemes(section.Window.Library, config.Themes)
    local hasDescription = tostring(config.Description or "") ~= ""
    local self = BaseComponent.new(section, "ThemeSwitcher", config, 120)
    setmetatable(self, ThemeSwitcher)
    self.Themes = themes
    self.Value = self.Window.ThemeManager.Name or themes[1]
    self.Buttons = {}
    self.Columns = config.Columns
    self.Gap = math.max(4, tonumber(config.Gap) or 6)
    self:AddTextBlock(-12)

    for _, themeName in ipairs(self.Themes) do
        assert(self.Library.Themes[themeName], string.format('[Note] Unknown theme "%s"', tostring(themeName)))
    end

    local groupY = hasDescription and 52 or 38
    local group = Utilities.Create("Frame", {
        Name = "ThemeButtons",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, groupY),
        Size = UDim2.new(1, -20, 0, 0),
        Parent = self.Frame,
    })

    local grid = Utilities.Create("UIGridLayout", {
        CellPadding = UDim2.fromOffset(self.Gap, self.Gap),
        CellSize = UDim2.fromOffset(120, 34),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 4,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        Parent = group,
    })

    for index, themeName in ipairs(self.Themes) do
        local preset = self.Library.Themes[themeName]
        local button = Utilities.Create("TextButton", {
            Name = "Theme_" .. themeName,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            LayoutOrder = index,
            Text = "",
            Parent = group,
        })
        Utilities.Corner(button, self.Library.Tokens.Radius.Medium)
        local stroke = Utilities.Stroke(button, Color3.new(), 1, 0)

        local swatch = Utilities.Create("Frame", {
            Name = "Swatch",
            BackgroundColor3 = preset.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            Parent = button,
        })
        Utilities.Corner(swatch, 999)
        local swatchStroke = Utilities.Stroke(swatch, Color3.new(), 1, 0.25)

        local label = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(30, 0),
            Size = UDim2.new(1, -38, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = themeName,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = button,
        })

        self.Window.ThemeManager:Bind(button, {
            BackgroundColor3 = function(theme)
                return self.Value == themeName and theme.Accent or theme.SurfaceElevated
            end,
            BackgroundTransparency = function(theme)
                return self.Value == themeName
                    and (theme.SelectedTransparency or 0.08)
                    or (theme.ElevatedTransparency or 0.14)
            end,
        })
        self.Window.ThemeManager:Bind(stroke, {
            Color = function(theme)
                return self.Value == themeName and theme.Accent or theme.Border
            end,
            Transparency = "BorderTransparency",
        })
        self.Window.ThemeManager:Bind(label, {
            TextColor3 = function(theme)
                return self.Value == themeName and theme.AccentForeground or theme.TextSecondary
            end,
        })
        self.Window.ThemeManager:Bind(swatchStroke, {
            Color = function(theme)
                return self.Value == themeName and theme.AccentForeground or theme.Border
            end,
            Transparency = "BorderTransparency",
        })

        self.Maid:Give(button.Activated:Connect(function()
            if not self.Disabled then
                self:SetValue(themeName)
            end
        end))
        self.Buttons[themeName] = {
            Button = button,
            Stroke = stroke,
            SwatchStroke = swatchStroke,
            Label = label,
        }
    end

    local function updateLayout()
        if self._destroyed or not self.Frame or not self.Frame.Parent then return end
        local width = math.max(1, self.Frame.AbsoluteSize.X - 20)
        local columns = chooseColumns(width, self.Columns, #self.Themes)
        local gap = self.Gap
        local cellWidth = math.max(76, math.floor((width - gap * math.max(0, columns - 1)) / columns))
        local rows = math.ceil(#self.Themes / columns)
        local gridHeight = rows * 34 + math.max(0, rows - 1) * gap

        grid.FillDirectionMaxCells = columns
        grid.CellSize = UDim2.fromOffset(cellWidth, 34)
        grid.CellPadding = UDim2.fromOffset(gap, gap)
        group.Size = UDim2.new(1, -20, 0, gridHeight)
        self.Frame.Size = UDim2.new(1, 0, 0, groupY + gridHeight + 10)

        if self.Section and self.Section.Tab then
            self.Section.Tab:_refreshLayout()
        end
    end

    self.Group = group
    self.Grid = grid
    self._updateThemeLayout = updateLayout
    self.Maid:Give(self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout))
    task.defer(updateLayout)

    self.Maid:Give(self.Window.ThemeManager.Changed:Connect(function(_, name)
        self.Value = name
        self:_refresh(true)
    end))

    if config.Default and config.Default ~= self.Value then
        self:SetValue(config.Default, true)
    else
        self:_refresh(false)
    end
    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    return self
end

function ThemeSwitcher:_refresh(animate)
    for _, entry in pairs(self.Buttons) do
        self.Window.ThemeManager:Apply(entry.Button, animate)
        self.Window.ThemeManager:Apply(entry.Stroke, animate)
        self.Window.ThemeManager:Apply(entry.SwatchStroke, animate)
        self.Window.ThemeManager:Apply(entry.Label, animate)
    end
end

function ThemeSwitcher:SetValue(themeName, silent)
    if self._destroyed then return self end
    assert(type(themeName) == "string" and self.Library.Themes[themeName], string.format('[Note] Unknown theme "%s"', tostring(themeName)))
    self.Value = themeName
    self.Window:SetTheme(themeName)
    self:_refresh(true)
    if self.Flag then
        self.Library.Flags[self.Flag] = themeName
    end
    if not silent then
        self:_fire(themeName)
    end
    return self
end

function ThemeSwitcher:GetValue()
    return self.Value
end

return ThemeSwitcher
