local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Icons = require("src/Core/Icons")

local Notification = {}
Notification.__index = Notification

local typeIcons = {
    Info = "info",
    Success = "circle-check",
    Warning = "circle-alert",
    Error = "circle-alert",
}

local typeTokens = {
    Info = "Accent",
    Success = "Success",
    Warning = "Warning",
    Error = "Destructive",
}

function Notification.new(library, config, themeManager)
    config = config or {}
    local self = setmetatable({
        Library = library,
        ThemeManager = themeManager or library.GlobalThemeManager,
        Maid = Maid.new(),
        Duration = tonumber(config.Duration) or 4,
        _destroyed = false,
    }, Notification)

    local frame = Utilities.Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(330, 92),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 410,
        Parent = library.Overlay:GetLayer("Notifications"),
    })
    Utilities.Corner(frame, library.Tokens.Radius.Large)
    local stroke = Utilities.Stroke(frame, Color3.new(), 1, 0)
    self.ThemeManager:Bind(frame, { BackgroundColor3 = "SurfaceElevated" })
    self.ThemeManager:Bind(stroke, { Color = "Border" })

    local kind = config.Type or "Info"
    local icon = Icons.Create({
        Name = config.Icon or typeIcons[kind] or "info",
        Size = 19,
        Parent = frame,
        ZIndex = 411,
    })
    icon.Instance.Position = UDim2.fromOffset(14, 14)
    self.ThemeManager:Bind(icon.Instance, { ImageColor3 = typeTokens[kind] or "Accent" })

    local title = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(44, 10),
        Size = UDim2.new(1, -82, 0, 22),
        Font = Enum.Font.GothamMedium,
        Text = tostring(config.Title or kind),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 411,
        Parent = frame,
    })
    local content = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(44, 34),
        Size = UDim2.new(1, -60, 0, 38),
        Font = Enum.Font.Gotham,
        Text = tostring(config.Content or ""),
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 411,
        Parent = frame,
    })
    self.ThemeManager:Bind(title, { TextColor3 = "Text" })
    self.ThemeManager:Bind(content, { TextColor3 = "TextSecondary" })

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

    local progressBack = Utilities.Create("Frame", {
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -8),
        Size = UDim2.new(1, -24, 0, 3),
        ZIndex = 411,
        Parent = frame,
    })
    Utilities.Corner(progressBack, 999)
    self.ThemeManager:Bind(progressBack, { BackgroundColor3 = "SurfaceSelected" })
    local progress = Utilities.Create("Frame", {
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 412,
        Parent = progressBack,
    })
    Utilities.Corner(progress, 999)
    self.ThemeManager:Bind(progress, { BackgroundColor3 = typeTokens[kind] or "Accent" })

    self.Frame = frame
    self.Progress = progress
    self.Maid:Give(frame)
    self.Maid:Give(icon)
    self.Maid:Give(closeIcon)
    self.Maid:Give(closeButton.Activated:Connect(function() self:Dismiss() end))

    frame.Position = UDim2.new(1, 360, 0, 16)
    frame.BackgroundTransparency = 0.04
    library:_layoutNotifications()
    library.Animation:Tween(frame, {
        Position = UDim2.new(1, -16, 0, frame.Position.Y.Offset),
    }, library.Tokens.Animation.Slow, Enum.EasingStyle.Quint)

    if self.Duration > 0 then
        library.Animation:Tween(progress, { Size = UDim2.fromScale(0, 1) }, self.Duration, Enum.EasingStyle.Linear)
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
    self.Library.Animation:Tween(self.Frame, {
        Position = UDim2.new(1, 360, 0, self.Frame.Position.Y.Offset),
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
