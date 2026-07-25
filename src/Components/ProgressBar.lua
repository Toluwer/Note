local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")

local ProgressBar = {}
ProgressBar.__index = ProgressBar
setmetatable(ProgressBar, { __index = BaseComponent })

local function clampValue(value, minimum, maximum)
    return Utilities.Clamp(tonumber(value) or minimum, minimum, maximum)
end

function ProgressBar.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "ProgressBar", config, 70)
    setmetatable(self, ProgressBar)

    self.Minimum = tonumber(config.Minimum) or 0
    self.Maximum = tonumber(config.Maximum) or 100
    if self.Maximum <= self.Minimum then
        self.Maximum = self.Minimum + 1
    end
    self.Value = clampValue(config.Value ~= nil and config.Value or config.Default, self.Minimum, self.Maximum)
    self.ShowValue = config.ShowValue ~= false
    self.Prefix = tostring(config.Prefix or "")
    self.Suffix = tostring(config.Suffix or "")
    self.Indeterminate = config.Indeterminate == true
    self.Status = tostring(config.Status or "")
    self._indeterminateRevision = 0

    self:AddTextBlock(-118)

    local valueLabel = Utilities.Create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, self.Description ~= "" and 9 or 8),
        Size = UDim2.fromOffset(96, 18),
        Font = Enum.Font.GothamMedium,
        Text = "",
        TextSize = self.Library.Tokens.Typography.Small,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Frame,
    })
    self.Window.ThemeManager:Bind(valueLabel, { TextColor3 = "TextSecondary" })

    local track = Utilities.Create("Frame", {
        Name = "Track",
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -20),
        Size = UDim2.new(1, -24, 0, 8),
        ClipsDescendants = true,
        Parent = self.Frame,
    })
    Utilities.Corner(track, 4)
    self.Window.ThemeManager:Bind(track, {
        BackgroundColor3 = "Input",
        BackgroundTransparency = "InputTransparency",
    })

    local fill = Utilities.Create("Frame", {
        Name = "Fill",
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    })
    Utilities.Corner(fill, 4)
    self.Window.ThemeManager:Bind(fill, { BackgroundColor3 = "Accent" })

    self.ValueLabel = valueLabel
    self.Track = track
    self.Fill = fill
    self:_refresh(false)

    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    if self.Indeterminate then
        self:_startIndeterminate()
    end
    return self
end

function ProgressBar:_formatValue()
    if self.Status ~= "" then
        return self.Status
    end
    return self.Prefix .. Utilities.FormatNumber(self.Value, 1) .. self.Suffix
end

function ProgressBar:_refresh(animate)
    if self._destroyed then return end
    self.ValueLabel.Visible = self.ShowValue or self.Status ~= ""
    self.ValueLabel.Text = self.Indeterminate and (self.Status ~= "" and self.Status or "Working…") or self:_formatValue()
    if self.Indeterminate then return end

    local percent = (self.Value - self.Minimum) / (self.Maximum - self.Minimum)
    local target = { Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(percent, 1) }
    if animate ~= false then
        self.Library.Animation:Tween(self.Fill, target, self.Library.Tokens.Animation.Normal, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    else
        self.Fill.Position = target.Position
        self.Fill.Size = target.Size
    end
end

function ProgressBar:_startIndeterminate()
    self._indeterminateRevision += 1
    local revision = self._indeterminateRevision
    self.Library.Animation:Cancel(self.Fill)
    self.Fill.Size = UDim2.fromScale(0.34, 1)
    self.Fill.Position = UDim2.fromScale(-0.34, 0)

    local function cycle()
        if self._destroyed or not self.Indeterminate or revision ~= self._indeterminateRevision then return end
        self.Fill.Position = UDim2.fromScale(-0.34, 0)
        local tween = self.Library.Animation:Tween(
            self.Fill,
            { Position = UDim2.fromScale(1, 0) },
            0.9,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.InOut
        )
        if tween then
            local connection
            connection = tween.Completed:Connect(function()
                if connection then connection:Disconnect() end
                task.defer(cycle)
            end)
        end
    end
    cycle()
end

function ProgressBar:SetValue(value, silent)
    if self._destroyed then return self end
    self.Value = clampValue(value, self.Minimum, self.Maximum)
    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    self:_refresh(true)
    if not silent then
        self:_fire(self.Value)
    end
    return self
end

function ProgressBar:GetValue()
    return self.Value
end

function ProgressBar:SetRange(minimum, maximum)
    minimum = tonumber(minimum)
    maximum = tonumber(maximum)
    if not minimum or not maximum or maximum <= minimum then
        error("[Note] ProgressBar:SetRange expected maximum to be greater than minimum", 2)
    end
    self.Minimum = minimum
    self.Maximum = maximum
    self.Value = clampValue(self.Value, minimum, maximum)
    self:_refresh(false)
    return self
end

function ProgressBar:SetIndeterminate(value)
    if self._destroyed then return self end
    value = value == true
    if self.Indeterminate == value then return self end
    self.Indeterminate = value
    self._indeterminateRevision += 1
    self.Library.Animation:Cancel(self.Fill)
    if value then
        self:_startIndeterminate()
    else
        self:_refresh(false)
    end
    return self
end

function ProgressBar:SetStatus(status)
    self.Status = tostring(status or "")
    self:_refresh(false)
    return self
end

function ProgressBar:Destroy()
    self._indeterminateRevision += 1
    if self.Fill then self.Library.Animation:Cancel(self.Fill) end
    BaseComponent.Destroy(self)
end

return ProgressBar
