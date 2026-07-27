local Lighting = game:GetService("Lighting")

local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Icons = require("src/Core/Icons")

local Dialog = {}
Dialog.__index = Dialog

local function clampBlurSize(value)
    return math.clamp(tonumber(value) or 14, 0, 56)
end

function Dialog:_acquireBlur(config)
    if config.Blur == false then
        return
    end

    local targetSize = clampBlurSize(config.BlurSize)
    if targetSize <= 0 then
        return
    end

    local library = self.Library
    library._dialogBlurRevision = (library._dialogBlurRevision or 0) + 1

    local blur = library._dialogBlur
    if not blur or not blur.Parent then
        blur = Instance.new("BlurEffect")
        blur.Name = "NoteDialogBlur"
        blur.Size = 0
        blur.Enabled = true
        blur.Parent = Lighting
        library._dialogBlur = blur
    end

    self._usesBlur = true
    library.Animation:Cancel(blur)
    library.Animation:Tween(
        blur,
        { Size = targetSize },
        library.Tokens.Animation.Normal,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )
end

function Dialog:_releaseBlur(immediate)
    if not self._usesBlur then
        return
    end
    self._usesBlur = false

    local library = self.Library
    local blur = library._dialogBlur
    if not blur then
        return
    end

    library._dialogBlurRevision = (library._dialogBlurRevision or 0) + 1
    local revision = library._dialogBlurRevision
    library.Animation:Cancel(blur)

    local function destroyOwnedBlur()
        if library._dialogBlurRevision ~= revision or library._dialogBlur ~= blur then
            return
        end
        if blur.Parent then
            blur:Destroy()
        end
        library._dialogBlur = nil
    end

    if immediate then
        destroyOwnedBlur()
        return
    end

    local duration = library.Tokens.Animation.Fast
    library.Animation:Tween(
        blur,
        { Size = 0 },
        duration,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.In
    )
    task.delay(duration + 0.05, destroyOwnedBlur)
end

function Dialog.new(library, config, themeManager)
    config = config or {}
    local self = setmetatable({
        Library = library,
        ThemeManager = themeManager or library.GlobalThemeManager,
        Maid = Maid.new(),
        ResultCallback = config.Callback,
        _usesBlur = false,
        _destroyed = false,
    }, Dialog)

    self:_acquireBlur(config)

    local layer = library.Overlay:GetLayer("Dialogs")
    local blocker = Utilities.Create("TextButton", {
        Name = "DialogBlocker",
        Active = true,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 500,
        Parent = layer,
    })
    local panel = Utilities.Create("CanvasGroup", {
        Name = "Dialog",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(410, 220),
        GroupTransparency = 1,
        ZIndex = 510,
        Parent = layer,
    })
    Utilities.Corner(panel, library.Tokens.Radius.Window)
    local stroke = Utilities.Stroke(panel, Color3.new(), 1, 0)
    stroke.ZIndex = 511
    self.ThemeManager:Bind(panel, {
        BackgroundColor3 = "SurfaceElevated",
        BackgroundTransparency = "ElevatedTransparency",
    })
    self.ThemeManager:Bind(stroke, {
        Color = "Border",
        Transparency = "BorderTransparency",
    })

    local panelScale = Utilities.Create("UIScale", {
        Scale = 0.96,
        Parent = panel,
    })

    local close = Utilities.Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 8),
        Size = UDim2.fromOffset(32, 32),
        ZIndex = 512,
        Parent = panel,
    })
    local closeIcon = Icons.Create({ Name = "x", Size = 16, Parent = close, ZIndex = 513 })
    closeIcon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Instance.Position = UDim2.fromScale(0.5, 0.5)
    self.ThemeManager:Bind(closeIcon.Instance, { ImageColor3 = "TextMuted" })

    if config.Icon then
        local icon = Icons.Create({ Name = config.Icon, Size = 24, Parent = panel, ZIndex = 512 })
        icon.Instance.Position = UDim2.fromOffset(20, 20)
        self.ThemeManager:Bind(icon.Instance, {
            ImageColor3 = config.Destructive and "Destructive" or "Accent",
        })
        self.Maid:Give(icon)
    end

    local textX = config.Icon and 56 or 20
    local title = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(textX, 16),
        Size = UDim2.new(1, -textX - 54, 0, 28),
        Font = Enum.Font.GothamMedium,
        Text = tostring(config.Title or "Confirm"),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 512,
        Parent = panel,
    })
    local content = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 60),
        Size = UDim2.new(1, -40, 0, 88),
        Font = Enum.Font.Gotham,
        Text = tostring(config.Content or ""),
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 512,
        Parent = panel,
    })
    self.ThemeManager:Bind(title, { TextColor3 = "Text" })
    self.ThemeManager:Bind(content, { TextColor3 = "TextSecondary" })

    local buttonBar = Utilities.Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 1, -56),
        Size = UDim2.new(1, -40, 0, 36),
        ZIndex = 512,
        Parent = panel,
    })
    local list = Utilities.List(buttonBar, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right)
    list.VerticalAlignment = Enum.VerticalAlignment.Center

    local buttons = config.Buttons or {
        { Name = "Cancel", Style = "Secondary" },
        { Name = "Confirm", Style = config.Destructive and "Destructive" or "Primary" },
    }
    for _, buttonConfig in ipairs(buttons) do
        local button = Utilities.Create("TextButton", {
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(math.max(88, #tostring(buttonConfig.Name or "Button") * 8 + 30), 34),
            Font = Enum.Font.GothamMedium,
            Text = tostring(buttonConfig.Name or "Button"),
            TextSize = 12,
            ZIndex = 513,
            Parent = buttonBar,
        })
        Utilities.Corner(button, library.Tokens.Radius.Medium)
        local style = buttonConfig.Style or "Secondary"
        local background = style == "Primary" and "Accent"
            or style == "Destructive" and "Destructive"
            or "SurfaceSelected"
        local foreground = style == "Secondary" and "Text" or "AccentForeground"
        self.ThemeManager:Bind(button, {
            BackgroundColor3 = background,
            TextColor3 = foreground,
        })
        self.Maid:Give(button.Activated:Connect(function()
            if buttonConfig.Callback then
                Utilities.SafeCallback("Dialog", tostring(config.Title or "Dialog"), buttonConfig.Callback)
            end
            self:Close(buttonConfig.Name)
        end))
    end

    self.Blocker = blocker
    self.Dim = blocker
    self.Panel = panel
    self.PanelScale = panelScale
    self.Maid:Give(blocker)
    self.Maid:Give(panel)
    self.Maid:Give(closeIcon)
    self.Maid:Give(close.Activated:Connect(function()
        self:Close(nil)
    end))
    if config.CloseOnBackdrop then
        self.Maid:Give(blocker.Activated:Connect(function()
            self:Close(nil)
        end))
    end

    self._popEscape = library.InputManager:PushEscape(function()
        self:Close(nil)
    end)
    self.Maid:Give(self._popEscape)

    library.Animation:Tween(
        panel,
        { GroupTransparency = 0 },
        library.Tokens.Animation.Normal,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )
    library.Animation:Tween(
        panelScale,
        { Scale = 1 },
        library.Tokens.Animation.Normal,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )
    return self
end

function Dialog:Close(result, immediate)
    if self._destroyed then
        return
    end
    self._destroyed = true

    if self.ResultCallback then
        Utilities.SafeCallback("Dialog", "Result", self.ResultCallback, result)
    end

    self:_releaseBlur(immediate == true)
    self.Library:_removeDialog(self)

    local panel = self.Panel
    local panelScale = self.PanelScale
    local duration = immediate and 0 or self.Library.Tokens.Animation.Fast

    if immediate then
        self.Maid:Destroy()
        return
    end

    self.Library.Animation:Cancel(panel)
    self.Library.Animation:Cancel(panelScale)

local fade = self.Library.Animation:Tween(
    panel,
    { GroupTransparency = 1 },
    duration,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.InOut
)
self.Library.Animation:Tween(
    panelScale,
    { Scale = 0.97 },
    duration,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.InOut
)
local finalized = false
local function finalize()
    if finalized then return end
    finalized = true
    self.Maid:Destroy()
end
if fade then
    local connection
    connection = fade.Completed:Connect(function()
        if connection then connection:Disconnect() end
        finalize()
    end)
end
task.delay(duration + 0.05, finalize)
end

function Dialog:Destroy()
    self:Close(nil, true)
end

return Dialog
