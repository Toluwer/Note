local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local TextMeasure = require("src/Internal/TextMeasure")

local Paragraph = {}
Paragraph.__index = Paragraph
setmetatable(Paragraph, { __index = BaseComponent })

function Paragraph.new(section, config)
    config = config or {}
    local titleText = tostring(config.Title or config.Name or "Paragraph")
    local contentText = tostring(config.Content or "")
    local width = math.max(section.Content.AbsoluteSize.X - 48, 260)
    local bodyHeight = math.max(34, TextMeasure.Get(contentText, 12, Enum.Font.Gotham, width).Y + 4)
    local self = BaseComponent.new(section, "Paragraph", { Name = titleText, Description = contentText }, bodyHeight + 42)
    setmetatable(self, Paragraph)
    self.Content = contentText

    local title = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 9),
        Size = UDim2.new(1, -24, 0, 20),
        Font = Enum.Font.GothamMedium,
        Text = titleText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Frame,
    })
    local body = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 30),
        Size = UDim2.new(1, -24, 0, bodyHeight),
        Font = Enum.Font.Gotham,
        Text = contentText,
        TextSize = 12,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Frame,
    })
    self.Window.ThemeManager:Bind(title, { TextColor3 = "Text" })
    self.Window.ThemeManager:Bind(body, { TextColor3 = "TextSecondary" })
    self.TitleLabel = title
    self.BodyLabel = body
    return self
end

function Paragraph:SetContent(content)
    self.Content = tostring(content or "")
    self.Description = self.Content
    self.BodyLabel.Text = self.Content
    return self
end

function Paragraph:SetValue(value)
    return self:SetContent(value)
end

function Paragraph:GetValue()
    return self.Content
end

return Paragraph
