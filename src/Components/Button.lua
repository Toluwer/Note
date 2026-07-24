local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")

local Button = {}
Button.__index = Button
setmetatable(Button, { __index = BaseComponent })

local styleTokens = {
    Primary = { Background = "Accent", Text = "AccentForeground" },
    Secondary = { Background = "SurfaceElevated", Text = "Text" },
    Destructive = { Background = "Destructive", Text = "AccentForeground" },
}

function Button.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "Button", config, 58)
    setmetatable(self, Button)
    self.Style = config.Style or "Secondary"
    self.Confirm = config.Confirm
    self.Loading = false
    self:AddTextBlock(-170)

    local action = Utilities.Create("TextButton", {
        Name = "Action",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(124, 34),
        Text = "",
        Parent = self.Frame,
    })
    Utilities.Corner(action, self.Library.Tokens.Radius.Medium)
    local actionStroke = Utilities.Stroke(action, Color3.new(), 1, 0)
    local style = styleTokens[self.Style] or styleTokens.Secondary
    self.Window.ThemeManager:Bind(action, { BackgroundColor3 = style.Background })
    self.Window.ThemeManager:Bind(actionStroke, { Color = self.Style == "Secondary" and "Border" or style.Background })

    local text = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, config.Icon and -32 or -16, 1, 0),
        Position = UDim2.fromOffset(config.Icon and 30 or 8, 0),
        Font = Enum.Font.GothamMedium,
        Text = config.ButtonText or self.Name,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = action,
    })
    self.Window.ThemeManager:Bind(text, { TextColor3 = style.Text })

    if config.Icon then
        self.OriginalIcon = config.Icon
        local icon = Icons.Create({
            Name = config.Icon,
            Size = 16,
            Parent = action,
        })
        icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
        icon.Instance.Position = UDim2.new(0, 10, 0.5, 0)
        self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = style.Text })
        self.ActionIcon = icon
        self.Maid:Give(icon)
    end

    self.Action = action
    self.ActionText = text

    self.Maid:Give(action.MouseEnter:Connect(function()
        if self.Disabled or self.Loading then return end
        self.Library.Animation:Tween(action, { BackgroundTransparency = 0.08 }, self.Library.Tokens.Animation.Fast)
    end))
    self.Maid:Give(action.MouseLeave:Connect(function()
        self.Library.Animation:Tween(action, { BackgroundTransparency = 0 }, self.Library.Tokens.Animation.Fast)
    end))
    self.Maid:Give(action.MouseButton1Down:Connect(function()
        if self.Disabled or self.Loading then return end
        self.Library.Animation:Tween(action, { Size = UDim2.fromOffset(120, 32) }, self.Library.Tokens.Animation.Fast)
    end))
    self.Maid:Give(action.MouseButton1Up:Connect(function()
        self.Library.Animation:Tween(action, { Size = UDim2.fromOffset(124, 34) }, self.Library.Tokens.Animation.Fast)
    end))
    self.Maid:Give(action.Activated:Connect(function()
        self:Fire()
    end))
    return self
end

function Button:SetLoading(value)
    if self._destroyed then return self end
    self.Loading = value == true
    self.ActionText.Text = self.Loading and "Working…" or self.Name
    if self.ActionIcon then
        self.ActionIcon:SetIcon(self.Loading and "refresh-cw" or self.OriginalIcon)
    end
    return self
end

function Button:Fire()
    if self._destroyed or self.Disabled or self.Loading then
        return
    end
    local function run()
        self:SetLoading(true)
        local ok = Utilities.SafeCallback(self.Type, self.Name, self.Callback)
        self:SetLoading(false)
        return ok
    end
    if self.Confirm then
        local confirm = type(self.Confirm) == "table" and self.Confirm or {}
        self.Window:Dialog({
            Title = confirm.Title or ("Confirm " .. self.Name),
            Content = confirm.Content or "Are you sure you want to continue?",
            Icon = confirm.Icon or "circle-alert",
            Buttons = {
                { Name = confirm.CancelText or "Cancel", Style = "Secondary" },
                { Name = confirm.ConfirmText or "Continue", Style = confirm.Destructive and "Destructive" or "Primary", Callback = run },
            },
        })
    else
        run()
    end
end

function Button:SetName(name)
    BaseComponent.SetName(self, name)
    if self.ActionText and not self.Loading then
        self.ActionText.Text = self.Name
    end
    return self
end

return Button
