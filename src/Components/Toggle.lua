local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")

local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = BaseComponent })

function Toggle.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "Toggle", config, 56)
    setmetatable(self, Toggle)
    self.Value = config.Default == true
    self:AddTextBlock(-84)

    local hitbox = Utilities.Create("TextButton", {
        Name = "Hitbox",
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        Parent = self.Frame,
    })
    local track = Utilities.Create("Frame", {
        Name = "Track",
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(46, 24),
        Parent = self.Frame,
    })
    Utilities.Corner(track, 999)
    local thumb = Utilities.Create("Frame", {
        Name = "Thumb",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(18, 18),
        Parent = track,
    })
    Utilities.Corner(thumb, 999)
    self.Window.ThemeManager:Bind(track, {
        BackgroundColor3 = function(theme, accent)
            return self.Value and accent or theme.SurfaceSelected
        end,
    })
    self.Window.ThemeManager:Bind(thumb, { BackgroundColor3 = "AccentForeground" })
    self.Track = track
    self.Thumb = thumb

    self.Maid:Give(hitbox.Activated:Connect(function()
        if not self.Disabled then
            self:Toggle()
        end
    end))
    self:SetValue(self.Value, true)
    return self
end

function Toggle:SetValue(value, silent)
    if self._destroyed then return self end
    value = value == true
    if self.Value == value and not silent then
        return self
    end
    self.Value = value
    self.Window.ThemeManager:Apply(self.Track, true)
    self.Library.Animation:Tween(self.Thumb, {
        Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
    }, self.Library.Tokens.Animation.Normal)
    if self.Flag then
        self.Library.Flags[self.Flag] = value
    end
    if not silent then
        self:_fire(value)
    end
    return self
end

function Toggle:GetValue()
    return self.Value
end

function Toggle:Toggle()
    return self:SetValue(not self.Value)
end

return Toggle
