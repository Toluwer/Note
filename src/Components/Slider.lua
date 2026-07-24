local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Validation = require("src/Core/Validation")

local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = BaseComponent })

function Slider.new(section, config)
    config = config or {}
    local minimum, maximum, increment = Validation.Slider(config)
    local self = BaseComponent.new(section, "Slider", config, 78)
    setmetatable(self, Slider)
    self.Minimum = minimum
    self.Maximum = maximum
    self.Increment = increment
    self.Prefix = config.Prefix or ""
    self.Suffix = config.Suffix or ""
    self.Value = Utilities.Clamp(tonumber(config.Default) or minimum, minimum, maximum)
    self.Value = Utilities.RoundToIncrement(self.Value, increment)
    self:AddTextBlock(-94)

    local valueLabel = Utilities.Create(config.Editable and "TextBox" or "TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 8),
        Size = UDim2.fromOffset(74, 20),
        Font = Enum.Font.GothamMedium,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self.Frame,
    })
    if valueLabel:IsA("TextBox") then
        valueLabel.ClearTextOnFocus = false
        valueLabel.TextEditable = not self.Disabled
        self.Maid:Give(valueLabel.FocusLost:Connect(function()
            local numeric = tostring(valueLabel.Text):match("[-+]?%d*%.?%d+")
            self:SetValue(tonumber(numeric) or self.Value)
        end))
    end
    self.Window.ThemeManager:Bind(valueLabel, { TextColor3 = "TextSecondary" })

    local track = Utilities.Create("TextButton", {
        Name = "Track",
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -24),
        Size = UDim2.new(1, -24, 0, 8),
        Parent = self.Frame,
    })
    Utilities.Corner(track, 999)
    self.Window.ThemeManager:Bind(track, { BackgroundColor3 = "SurfaceSelected" })

    local fill = Utilities.Create("Frame", {
        Name = "Fill",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    })
    Utilities.Corner(fill, 999)
    self.Window.ThemeManager:Bind(fill, { BackgroundColor3 = "Accent" })
    local thumb = Utilities.Create("Frame", {
        Name = "Thumb",
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(16, 16),
        Parent = track,
    })
    Utilities.Corner(thumb, 999)
    local thumbStroke = Utilities.Stroke(thumb, Color3.new(), 2, 0)
    self.Window.ThemeManager:Bind(thumb, { BackgroundColor3 = "AccentForeground" })
    self.Window.ThemeManager:Bind(thumbStroke, { Color = "Accent" })

    self.Track = track
    self.Fill = fill
    self.Thumb = thumb
    self.ValueLabel = valueLabel

    local function updateFromPoint(point, final)
        local relative = Utilities.Clamp((point.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minimum + (maximum - minimum) * relative
        self:SetValue(raw, false, not final)
    end

    self.Maid:Give(track.InputBegan:Connect(function(input)
        if self.Disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            updateFromPoint(input.Position, false)
            self.Library.InputManager:BeginPointerDrag(function(point)
                updateFromPoint(point, false)
            end, function(point)
                updateFromPoint(point, true)
            end)
        end
    end))
    self:SetValue(self.Value, true)
    return self
end

function Slider:_ratio()
    return (self.Value - self.Minimum) / (self.Maximum - self.Minimum)
end

function Slider:SetValue(value, silent, throttled)
    if self._destroyed then return self end
    value = Utilities.Clamp(tonumber(value) or self.Minimum, self.Minimum, self.Maximum)
    value = Utilities.RoundToIncrement(value, self.Increment)
    if self.Value == value and not silent then
        return self
    end
    self.Value = value
    local ratio = self:_ratio()
    self.Library.Animation:Tween(self.Fill, { Size = UDim2.fromScale(ratio, 1) }, self.Library.Tokens.Animation.Fast)
    self.Library.Animation:Tween(self.Thumb, { Position = UDim2.fromScale(ratio, 0.5) }, self.Library.Tokens.Animation.Fast)
    self.ValueLabel.Text = self.Prefix .. Utilities.FormatNumber(value, self.Increment) .. self.Suffix
    if self.Flag then
        self.Library.Flags[self.Flag] = value
    end
    if not silent then
        if throttled then
            local now = os.clock()
            if not self._lastCallback or now - self._lastCallback >= 0.03 then
                self._lastCallback = now
                self:_fire(value)
            end
        else
            self:_fire(value)
        end
    end
    return self
end

function Slider:GetValue()
    return self.Value
end

function Slider:SetRange(minimum, maximum)
    if maximum <= minimum then
        error(string.format('[Note] Slider "%s": Maximum must be greater than Minimum.', self.Name), 2)
    end
    self.Minimum = minimum
    self.Maximum = maximum
    return self:SetValue(self.Value)
end

return Slider
