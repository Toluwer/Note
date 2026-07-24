local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Icons = require("src/Core/Icons")

local Dialog = {}
Dialog.__index = Dialog

function Dialog.new(library, config, themeManager)
    config = config or {}
    local self = setmetatable({
        Library = library,
        ThemeManager = themeManager or library.GlobalThemeManager,
        Maid = Maid.new(),
        ResultCallback = config.Callback,
        _destroyed = false,
    }, Dialog)

    local layer = library.Overlay:GetLayer("Dialogs")
    local dim = Utilities.Create("TextButton", {
        Name = "DialogDim",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 500,
        Parent = layer,
    })
    local panel = Utilities.Create("Frame", {
        Name = "Dialog",
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(410, 220),
        ZIndex = 510,
        Parent = layer,
    })
    Utilities.Corner(panel, library.Tokens.Radius.Window)
    local stroke = Utilities.Stroke(panel, Color3.new(), 1, 0)
    stroke.ZIndex = 511
    self.ThemeManager:Bind(panel, { BackgroundColor3 = "SurfaceElevated" })
    self.ThemeManager:Bind(stroke, { Color = "Border" })

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
        self.ThemeManager:Bind(icon.Instance, { ImageColor3 = config.Destructive and "Destructive" or "Accent" })
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
        local background = style == "Primary" and "Accent" or style == "Destructive" and "Destructive" or "SurfaceSelected"
        local foreground = style == "Secondary" and "Text" or "AccentForeground"
        self.ThemeManager:Bind(button, { BackgroundColor3 = background, TextColor3 = foreground })
        self.Maid:Give(button.Activated:Connect(function()
            if buttonConfig.Callback then
                Utilities.SafeCallback("Dialog", tostring(config.Title or "Dialog"), buttonConfig.Callback)
            end
            self:Close(buttonConfig.Name)
        end))
    end

    self.Dim = dim
    self.Panel = panel
    self.Maid:Give(dim)
    self.Maid:Give(panel)
    self.Maid:Give(closeIcon)
    self.Maid:Give(close.Activated:Connect(function() self:Close(nil) end))
    if config.CloseOnBackdrop then
        self.Maid:Give(dim.Activated:Connect(function() self:Close(nil) end))
    end
    self._popEscape = library.InputManager:PushEscape(function() self:Close(nil) end)
    self.Maid:Give(self._popEscape)
    panel.Size = UDim2.fromOffset(380, 190)
    panel.BackgroundTransparency = 1
    library.Animation:Tween(panel, {
        Size = UDim2.fromOffset(410, 220),
        BackgroundTransparency = 0,
    }, library.Tokens.Animation.Normal)
    return self
end

function Dialog:Close(result)
    if self._destroyed then return end
    self._destroyed = true
    if self.ResultCallback then
        Utilities.SafeCallback("Dialog", "Result", self.ResultCallback, result)
    end
    local panel = self.Panel
    self.Library.Animation:Tween(panel, {
        Size = UDim2.fromOffset(380, 190),
        BackgroundTransparency = 1,
    }, self.Library.Tokens.Animation.Fast)
    self.Library:_removeDialog(self)
    task.delay(self.Library.Tokens.Animation.Fast, function()
        self.Maid:Destroy()
        if panel and panel.Parent then
            panel:Destroy()
        end
    end)
end

function Dialog:Destroy()
    self:Close(nil)
end

return Dialog
