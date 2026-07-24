local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")
local Tooltip = require("src/Components/Tooltip")

local WindowControls = {}

function WindowControls.Create(window, config)
    config = config or {}
    local button = Utilities.Create("TextButton", {
        Name = config.Name or "WindowControl",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(36, 34),
        ZIndex = 110,
        Parent = config.Parent,
    })
    Utilities.Corner(button, window.Library.Tokens.Radius.Medium)
    local icon = Icons.Create({
        Name = config.Icon,
        Size = config.IconSize or 16,
        Parent = button,
        ZIndex = 111,
    })
    icon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Instance.Position = UDim2.fromScale(0.5, 0.5)
    window.ThemeManager:Bind(icon.Instance, {
        ImageColor3 = config.Destructive and "TextSecondary" or "TextSecondary",
    })

    window.Maid:Give(button.MouseEnter:Connect(function()
        local color = window.ThemeManager:Get(config.Destructive and "Destructive" or "SurfaceHover")
        button.BackgroundColor3 = color
        window.Library.Animation:Tween(button, { BackgroundTransparency = config.Destructive and 0 or 0.08 }, window.Library.Tokens.Animation.Fast)
        if config.Destructive then
            icon:SetColor(window.ThemeManager:Get("AccentForeground"))
        end
    end))
    window.Maid:Give(button.MouseLeave:Connect(function()
        window.Library.Animation:Tween(button, { BackgroundTransparency = 1 }, window.Library.Tokens.Animation.Fast)
        window.ThemeManager:Apply(icon.Instance, true)
    end))
    window.Maid:Give(button.MouseButton1Down:Connect(function()
        icon:SetSize((config.IconSize or 16) - 1)
    end))
    window.Maid:Give(button.MouseButton1Up:Connect(function()
        icon:SetSize(config.IconSize or 16)
    end))
    window.Maid:Give(button.Activated:Connect(function()
        if config.Callback then
            config.Callback()
        end
    end))
    if config.Tooltip then
        window.Maid:Give(Tooltip.Bind(window.Library, button, config.Tooltip, window.ThemeManager))
    end
    window.Maid:Give(icon)
    return button, icon
end

return WindowControls
