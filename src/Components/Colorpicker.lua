local RunService = game:GetService("RunService")
local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Layout = require("src/Core/Layout")
local Maid = require("src/Core/Maid")

local Colorpicker = {}
Colorpicker.__index = Colorpicker
setmetatable(Colorpicker, { __index = BaseComponent })

function Colorpicker.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "Colorpicker", config, 56)
    setmetatable(self, Colorpicker)
    self.Value = typeof(config.Default) == "Color3" and config.Default or Color3.fromRGB(110, 125, 255)
    self.Default = self.Value
    self.Alpha = Utilities.Clamp(tonumber(config.Alpha) or 0, 0, 1)
    self.AllowAlpha = config.AllowAlpha == true or config.ShowAlpha == true
    self.Hue, self.Saturation, self.Brightness = self.Value:ToHSV()
    self:AddTextBlock(-84)

    local preview = Utilities.Create("TextButton", {
        Name = "Preview",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(52, 30),
        Text = "",
        Parent = self.Frame,
    })
    Utilities.Corner(preview, self.Library.Tokens.Radius.Medium)
    local stroke = Utilities.Stroke(preview, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(stroke, { Color = "Border" })
    self.Preview = preview
    self:_syncPreview()
    self.Maid:Give(preview.Activated:Connect(function()
        if not self.Disabled then self:Toggle() end
    end))
    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    return self
end

function Colorpicker:_syncPreview()
    if self.Preview then
        self.Preview.BackgroundColor3 = self.Value
        self.Preview.BackgroundTransparency = self.Alpha
    end
end

function Colorpicker:_syncPopup()
    if not self._popup then return end
    local hueColor = Color3.fromHSV(self.Hue, 1, 1)
    self._sv.BackgroundColor3 = hueColor
    self._svCursor.Position = UDim2.fromScale(self.Saturation, 1 - self.Brightness)
    self._hueCursor.Position = UDim2.fromScale(self.Hue, 0.5)
    self._currentPreview.BackgroundColor3 = self.Value
    self._oldPreview.BackgroundColor3 = self.Default
    local r = math.floor(self.Value.R * 255 + 0.5)
    local g = math.floor(self.Value.G * 255 + 0.5)
    local b = math.floor(self.Value.B * 255 + 0.5)
    self._fields.R.Text = tostring(r)
    self._fields.G.Text = tostring(g)
    self._fields.B.Text = tostring(b)
    self._fields.Hex.Text = Utilities.ColorToHex(self.Value)
    if self._alphaCursor then
        self._alphaCursor.Position = UDim2.fromScale(self.Alpha, 0.5)
        self._fields.Alpha.Text = tostring(math.floor((1 - self.Alpha) * 100 + 0.5))
    end
end

function Colorpicker:_updateFromHSV(h, s, v, throttled)
    self.Hue = (h or self.Hue) % 1
    self.Saturation = Utilities.Clamp(s or self.Saturation, 0, 1)
    self.Brightness = Utilities.Clamp(v or self.Brightness, 0, 1)
    self:SetValue(Color3.fromHSV(self.Hue, self.Saturation, self.Brightness), false, throttled)
end

function Colorpicker:_makeField(parent, name, position, width)
    local holder = Utilities.Create("Frame", {
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.fromOffset(width, 30),
        ZIndex = 213,
        Parent = parent,
    })
    Utilities.Corner(holder, self.Library.Tokens.Radius.Small)
    local stroke = Utilities.Stroke(holder, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(holder, { BackgroundColor3 = "Input" })
    self.Window.ThemeManager:Bind(stroke, { Color = "Border" })
    local label = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(7, 0),
        Size = UDim2.fromOffset(20, 30),
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 214,
        Parent = holder,
    })
    self.Window.ThemeManager:Bind(label, { TextColor3 = "TextMuted" })
    local box = Utilities.Create("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -31, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 214,
        Parent = holder,
    })
    self.Window.ThemeManager:Bind(box, { TextColor3 = "Text" })
    return box
end

function Colorpicker:Open()
    if self._destroyed or self._popup or self.Disabled then return self end
    local maid = Maid.new()
    self._popupMaid = maid
    local height = self.AllowAlpha and 392 or 352
    local popup = Utilities.Create("Frame", {
        Name = "ColorpickerPopup",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(320, height),
        ZIndex = 205,
        Parent = self.Library.Overlay:GetLayer("Popovers"),
    })
    Utilities.Corner(popup, self.Library.Tokens.Radius.Large)
    local popupStroke = Utilities.Stroke(popup, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(popup, { BackgroundColor3 = "SurfaceElevated" })
    self.Window.ThemeManager:Bind(popupStroke, { Color = "Border" })
    maid:Give(popup)

    local title = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 0, 22),
        Font = Enum.Font.GothamMedium,
        Text = self.Name,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 211,
        Parent = popup,
    })
    self.Window.ThemeManager:Bind(title, { TextColor3 = "Text" })

    local sv = Utilities.Create("Frame", {
        Name = "SaturationValue",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 38),
        Size = UDim2.new(1, -24, 0, 160),
        BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1),
        Active = true,
        ZIndex = 211,
        Parent = popup,
    })
    Utilities.Corner(sv, self.Library.Tokens.Radius.Medium)
    local white = Utilities.Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 212,
        Parent = sv,
    })
    Utilities.Corner(white, self.Library.Tokens.Radius.Medium)
    Utilities.Create("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = white,
    })
    local black = Utilities.Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 213,
        Parent = sv,
    })
    Utilities.Corner(black, self.Library.Tokens.Radius.Medium)
    Utilities.Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = black,
    })
    local svCursor = Utilities.Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        ZIndex = 215,
        Parent = sv,
    })
    Utilities.Corner(svCursor, 999)
    Utilities.Stroke(svCursor, Color3.new(0, 0, 0), 2, 0.25)

    local hue = Utilities.Create("Frame", {
        Name = "Hue",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 208),
        Size = UDim2.new(1, -24, 0, 16),
        Active = true,
        ZIndex = 211,
        Parent = popup,
    })
    Utilities.Corner(hue, 999)
    Utilities.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = hue,
    })
    local hueCursor = Utilities.Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 22),
        ZIndex = 214,
        Parent = hue,
    })
    Utilities.Corner(hueCursor, 999)
    Utilities.Stroke(hueCursor, Color3.new(0, 0, 0), 1, 0.25)

    local oldPreview = Utilities.Create("TextButton", {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 236),
        Size = UDim2.fromOffset(44, 30),
        Text = "",
        ZIndex = 212,
        Parent = popup,
    })
    Utilities.Corner(oldPreview, self.Library.Tokens.Radius.Small)
    local currentPreview = Utilities.Create("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(60, 236),
        Size = UDim2.fromOffset(44, 30),
        ZIndex = 212,
        Parent = popup,
    })
    Utilities.Corner(currentPreview, self.Library.Tokens.Radius.Small)
    local reset = Utilities.Create("TextButton", {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -86, 0, 236),
        Size = UDim2.fromOffset(74, 30),
        Font = Enum.Font.GothamMedium,
        Text = "Reset",
        TextSize = 11,
        ZIndex = 212,
        Parent = popup,
    })
    Utilities.Corner(reset, self.Library.Tokens.Radius.Small)
    self.Window.ThemeManager:Bind(reset, { BackgroundColor3 = "SurfaceSelected", TextColor3 = "Text" })

    self._fields = {}
    self._fields.R = self:_makeField(popup, "R", UDim2.fromOffset(12, 276), 68)
    self._fields.G = self:_makeField(popup, "G", UDim2.fromOffset(86, 276), 68)
    self._fields.B = self:_makeField(popup, "B", UDim2.fromOffset(160, 276), 68)
    self._fields.Hex = self:_makeField(popup, "#", UDim2.fromOffset(234, 276), 74)

    if self.AllowAlpha then
        local alpha = Utilities.Create("Frame", {
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 316),
            Size = UDim2.fromOffset(214, 14),
            Active = true,
            ZIndex = 211,
            Parent = popup,
        })
        Utilities.Corner(alpha, 999)
        local gradient = Utilities.Create("UIGradient", {
            Color = ColorSequence.new(self.Value, self.Value),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = alpha,
        })
        local alphaCursor = Utilities.Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(8, 20),
            ZIndex = 214,
            Parent = alpha,
        })
        Utilities.Corner(alphaCursor, 999)
        Utilities.Stroke(alphaCursor, Color3.new(0, 0, 0), 1, 0.25)
        self._fields.Alpha = self:_makeField(popup, "A", UDim2.fromOffset(234, 308), 74)
        self._alphaBar = alpha
        self._alphaGradient = gradient
        self._alphaCursor = alphaCursor
    end

    self._popup = popup
    self._sv = sv
    self._svCursor = svCursor
    self._hue = hue
    self._hueCursor = hueCursor
    self._currentPreview = currentPreview
    self._oldPreview = oldPreview
    self:_syncPopup()

    local function setSV(point, throttled)
        local x = Utilities.Clamp((point.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
        local y = Utilities.Clamp((point.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        self:_updateFromHSV(nil, x, 1 - y, throttled)
    end
    local function setHue(point, throttled)
        local x = Utilities.Clamp((point.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 1)
        self:_updateFromHSV(x, nil, nil, throttled)
    end
    local function beginDrag(gui, updater, input)
        updater(input.Position, true)
        self.Library.InputManager:BeginPointerDrag(function(point)
            updater(point, true)
        end, function(point)
            updater(point, false)
        end)
    end
    maid:Give(sv.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(sv, setSV, input)
        end
    end))
    maid:Give(hue.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(hue, setHue, input)
        end
    end))
    if self.AllowAlpha then
        local function setAlpha(point, throttled)
            self.Alpha = Utilities.Clamp((point.X - self._alphaBar.AbsolutePosition.X) / math.max(self._alphaBar.AbsoluteSize.X, 1), 0, 1)
            self:_syncPreview()
            self:_syncPopup()
            if not throttled then self:_fire(self.Value, self.Alpha) end
        end
        maid:Give(self._alphaBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setAlpha(input.Position, true)
                self.Library.InputManager:BeginPointerDrag(function(point) setAlpha(point, true) end, function(point) setAlpha(point, false) end)
            end
        end))
    end

    maid:Give(oldPreview.Activated:Connect(function() self:SetValue(self.Default) end))
    maid:Give(reset.Activated:Connect(function() self:SetValue(self.Default) end))
    local function applyRgb()
        local r = Utilities.Clamp(tonumber(self._fields.R.Text) or 0, 0, 255)
        local g = Utilities.Clamp(tonumber(self._fields.G.Text) or 0, 0, 255)
        local b = Utilities.Clamp(tonumber(self._fields.B.Text) or 0, 0, 255)
        self:SetValue(Color3.fromRGB(r, g, b))
    end
    for _, name in ipairs({ "R", "G", "B" }) do
        maid:Give(self._fields[name].FocusLost:Connect(applyRgb))
    end
    maid:Give(self._fields.Hex.FocusLost:Connect(function()
        local color = Utilities.HexToColor(self._fields.Hex.Text)
        if color then self:SetValue(color) else self:_syncPopup() end
    end))
    if self.AllowAlpha then
        maid:Give(self._fields.Alpha.FocusLost:Connect(function()
            local opacity = Utilities.Clamp(tonumber(self._fields.Alpha.Text) or 100, 0, 100) / 100
            self.Alpha = 1 - opacity
            self:_syncPreview()
            self:_syncPopup()
            self:_fire(self.Value, self.Alpha)
        end))
    end

    local function reposition()
        if popup.Parent and self.Preview.Parent then
            Layout.PositionOverlay(self.Preview, popup, self.Library.Overlay.Root, 320)
        end
    end
    reposition()
    maid:Give(RunService.Heartbeat:Connect(reposition))
    maid:Give(self.Library.InputManager:RegisterOutside({ popup, self.Preview }, function() self:Close() end))
    maid:Give(self.Library.InputManager:PushEscape(function() self:Close() end))
    popup.BackgroundTransparency = 1
    popup.Size = UDim2.fromOffset(300, height - 18)
    self.Library.Animation:Tween(popup, {
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(320, height),
    }, self.Library.Tokens.Animation.Normal)
    return self
end

function Colorpicker:Close()
    if not self._popup then return self end
    local popup = self._popup
    self._popup = nil
    self.Library.Animation:Tween(popup, {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(300, math.max(260, popup.Size.Y.Offset - 18)),
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
    self._fields = nil
    self._alphaGradient = nil
    return self
end

function Colorpicker:Toggle()
    return self._popup and self:Close() or self:Open()
end

function Colorpicker:SetValue(color, silent, throttled)
    if self._destroyed then return self end
    if typeof(color) ~= "Color3" then
        error("[Note] Colorpicker value must be a Color3", 2)
    end
    if self.Value == color and not silent then
        return self
    end
    self.Value = color
    self.Hue, self.Saturation, self.Brightness = color:ToHSV()
    self:_syncPreview()
    self:_syncPopup()
    if self._alphaGradient then
        self._alphaGradient.Color = ColorSequence.new(color, color)
    end
    if self.Flag then self.Library.Flags[self.Flag] = color end
    if not silent then
        if throttled then
            local now = os.clock()
            if not self._lastCallback or now - self._lastCallback >= 0.03 then
                self._lastCallback = now
                self:_fire(color, self.Alpha)
            end
        else
            self:_fire(color, self.Alpha)
        end
    end
    return self
end

function Colorpicker:GetValue()
    return self.Value, self.Alpha
end

function Colorpicker:Destroy()
    self:Close()
    BaseComponent.Destroy(self)
end

return Colorpicker
