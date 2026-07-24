local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")

local Divider = {}
Divider.__index = Divider
setmetatable(Divider, { __index = BaseComponent })

function Divider.new(section, config)
    config = config or {}
    local hasText = config.Text ~= nil and tostring(config.Text) ~= ""
    local spacing = math.max(0, tonumber(config.Spacing) or 0)
    local height = (hasText and 28 or 16) + spacing * 2
    local self = BaseComponent.new(section, "Divider", { Name = config.Text or "Divider" }, height)
    setmetatable(self, Divider)
    self.Frame.BackgroundTransparency = 1
    self.Stroke.Transparency = 1
    local line = Utilities.Create("Frame", {
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self.Frame,
    })
    self.Window.ThemeManager:Bind(line, { BackgroundColor3 = "Border" })
    if hasText then
        local label = Utilities.Create("TextLabel", {
            BackgroundColor3 = Color3.new(),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(math.max(64, #tostring(config.Text) * 7 + 20), 22),
            Font = Enum.Font.Gotham,
            Text = tostring(config.Text),
            TextSize = 11,
            Parent = self.Frame,
        })
        self.Window.ThemeManager:Bind(label, { BackgroundColor3 = "Background", TextColor3 = "TextMuted" })
    end
    return self
end

return Divider
