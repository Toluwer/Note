local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")

local ThemeSwitcher = {}
ThemeSwitcher.__index = ThemeSwitcher
setmetatable(ThemeSwitcher, { __index = BaseComponent })

function ThemeSwitcher.new(section, config)
    config = config or {}
    local themes = config.Themes or { "Dark", "Light" }
    assert(type(themes) == "table" and #themes > 0, "[Note] ThemeSwitcher Themes must be a non-empty array")

    local hasDescription = tostring(config.Description or "") ~= ""
    local self = BaseComponent.new(section, "ThemeSwitcher", config, hasDescription and 64 or 54)
    setmetatable(self, ThemeSwitcher)
    self.Themes = table.clone(themes)
    self.ResetAccent = config.ResetAccent ~= false
    self.Value = self.Window.ThemeManager.Name or themes[1]
    self.Buttons = {}
    self:AddTextBlock(-220)

    for _, themeName in ipairs(self.Themes) do
        assert(self.Library.Themes[themeName], string.format('[Note] Unknown theme "%s"', tostring(themeName)))
    end

    local group = Utilities.Create("Frame", {
        Name = "ThemeButtons",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(198, 34),
        Parent = self.Frame,
    })
    local layout = Utilities.List(group, Enum.FillDirection.Horizontal, 4)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    local buttonWidth = math.max(54, math.floor((198 - math.max(0, #self.Themes - 1) * 4) / #self.Themes))
    for index, themeName in ipairs(self.Themes) do
        local button = Utilities.Create("TextButton", {
            Name = "Theme_" .. themeName,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(buttonWidth, 34),
            LayoutOrder = index,
            Text = "",
            Parent = group,
        })
        Utilities.Corner(button, self.Library.Tokens.Radius.Medium)
        local stroke = Utilities.Stroke(button, Color3.new(), 1, 0)
        local label = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = Enum.Font.GothamMedium,
            Text = themeName,
            TextSize = 11,
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

        self.Maid:Give(button.Activated:Connect(function()
            if not self.Disabled then
                self:SetValue(themeName)
            end
        end))
        self.Buttons[themeName] = { Button = button, Stroke = stroke, Label = label }
    end

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
        self.Window.ThemeManager:Apply(entry.Label, animate)
    end
end

function ThemeSwitcher:SetValue(themeName, silent)
    if self._destroyed then return self end
    assert(type(themeName) == "string" and self.Library.Themes[themeName], string.format('[Note] Unknown theme "%s"', tostring(themeName)))
    self.Value = themeName
    self.Window:SetTheme(themeName, { PreserveAccent = not self.ResetAccent })
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
