local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")

local Label = {}
Label.__index = Label
setmetatable(Label, { __index = BaseComponent })

function Label.new(section, config)
    config = config or {}
    local text = tostring(config.Text or config.Name or "")
    local self = BaseComponent.new(section, "Label", { Name = text, Visible = config.Visible }, 32)
    setmetatable(self, Label)
    self.Text = text
    self.Label = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Font = config.Font or Enum.Font.Gotham,
        Text = text,
        TextSize = config.TextSize or 12,
        TextWrapped = config.Wrapped == true,
        TextXAlignment = config.Alignment or Enum.TextXAlignment.Left,
        AutomaticSize = config.Wrapped and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        Parent = self.Frame,
    })
    self.Frame.BackgroundTransparency = 1
    self.Stroke.Transparency = 1
    self.Window.ThemeManager:Bind(self.Label, { TextColor3 = config.Muted and "TextMuted" or "TextSecondary" })
    return self
end

function Label:SetText(text)
    self.Text = tostring(text)
    self.Name = self.Text
    self.Label.Text = self.Text
    return self
end

function Label:GetValue()
    return self.Text
end

function Label:SetValue(value)
    return self:SetText(value)
end

return Label
