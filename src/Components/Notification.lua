local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Icons = require("src/Core/Icons")
local TextMeasure = require("src/Internal/TextMeasure")

local Notification = {}
Notification.__index = Notification

local function ceil(value)
    return math.ceil(value + 0.0001)
end

function Notification.new(library, config, themeManager)
    config = config or {}
    local kind = tostring(config.Type or "Info")
    local titleText = tostring(config.Title or kind)
    local contentText = tostring(config.Content or "")
    local minimumWidth = tonumber(config.MinWidth) or 220
    local maximumWidth = math.max(minimumWidth, tonumber(config.MaxWidth) or 380)

    local self = setmetatable({
        Library = library,
        ThemeManager = themeManager or library.GlobalThemeManager,
        Maid = Maid.new(),
        Duration = tonumber(config.Duration) or 4,
        _destroyed = false,
    }, Notification)

    local titleNatural = TextMeasure.Get(titleText, 13, Enum.Font.GothamMedium, 1000)
    local contentNatural = TextMeasure.Get(contentText, 11, Enum.Font.Gotham, 1000)
    local desiredTextWidth = math.max(titleNatural.X, math.min(contentNatural.X, maximumWidth - 28))
    local width = Utilities.Clamp(ceil(desiredTextWidth + 48), minimumWidth, maximumWidth)
    local titleWidth = width - 58
    local contentWidth = width - 28
    local titleMeasure = TextMeasure.Get(titleText, 13, Enum.Font.GothamMedium, titleWidth)
    local titleHeight = math.max(20, ceil(titleMeasure.Y))
    local contentMeasure = TextMeasure.Get(contentText, 11, Enum.Font.Gotham, contentWidth)
    local contentHeight = contentText ~= "" and math.max(16, ceil(contentMeasure.Y)) or 0
    local contentTop = 12 + titleHeight + 4
    local height = contentText ~= ""
        and math.max(54, contentTop + contentHeight + 12)
        or math.max(50, 12 + titleHeight + 12)

    local frame = Utilities.Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width, height),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 410,
        Parent = library.Overlay:GetLayer("Notifications"),
    })
    Utilities.Corner(frame, library.Tokens.Radius.Large)
    local stroke = Utilities.Stroke(frame, Color3.new(), 1, 0)
    self.ThemeManager:Bind(frame, {
        BackgroundColor3 = "SurfaceElevated",
        BackgroundTransparency = "ElevatedTransparency",
    })
    self.ThemeManager:Bind(stroke, {
        Color = "Border",
        Transparency = "BorderTransparency",
    })

    local title = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.fromOffset(titleWidth, titleHeight),
        Font = Enum.Font.GothamMedium,
        Text = titleText,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 411,
        Parent = frame,
    })
    self.ThemeManager:Bind(title, { TextColor3 = "Text" })

    if contentText ~= "" then
        local content = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, contentTop),
            Size = UDim2.fromOffset(contentWidth, contentHeight),
            Font = Enum.Font.Gotham,
            Text = contentText,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 411,
            Parent = frame,
        })
        self.ThemeManager:Bind(content, { TextColor3 = "TextSecondary" })
        self.ContentLabel = content
    end

    local closeButton = Utilities.Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.fromOffset(28, 28),
        ZIndex = 412,
        Parent = frame,
    })
    local closeIcon = Icons.Create({ Name = "x", Size = 14, Parent = closeButton, ZIndex = 413 })
    closeIcon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Instance.Position = UDim2.fromScale(0.5, 0.5)
    self.ThemeManager:Bind(closeIcon.Instance, { ImageColor3 = "TextMuted" })

    self.Frame = frame
    self.TitleLabel = title
    self.Width = width
    self.Maid:Give(frame)
    self.Maid:Give(closeIcon)
    self.Maid:Give(closeButton.Activated:Connect(function()
        self:Dismiss()
    end))

    local hiddenOffset = width + 24
    frame.Position = UDim2.new(1, hiddenOffset, 0, 16)
    library:_layoutNotifications()
    library.Animation:Tween(frame, {
        Position = UDim2.new(1, -16, 0, frame.Position.Y.Offset),
    }, library.Tokens.Animation.Slow, Enum.EasingStyle.Quint)

    if self.Duration > 0 then
        self._timer = task.delay(self.Duration, function()
            self:Dismiss()
        end)
        self.Maid:Give(self._timer)
    end
    return self
end

function Notification:Dismiss()
    if self._destroyed then return end
    self._destroyed = true
    local hiddenOffset = (self.Width or self.Frame.AbsoluteSize.X) + 24
    self.Library.Animation:Tween(self.Frame, {
        Position = UDim2.new(1, hiddenOffset, 0, self.Frame.Position.Y.Offset),
        BackgroundTransparency = 1,
    }, self.Library.Tokens.Animation.Normal)
    local frame = self.Frame
    local library = self.Library
    task.delay(self.Library.Tokens.Animation.Normal, function()
        self.Maid:Destroy()
        if frame and frame.Parent then
            frame:Destroy()
        end
    end)
    library:_removeNotification(self)
end

function Notification:Destroy()
    self:Dismiss()
end

return Notification
