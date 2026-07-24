local Utilities = require("src/Core/Utilities")

local RoundedContainer = {}

function RoundedContainer.Create(config)
    config = config or {}
    local frame = Utilities.Create("Frame", {
        Name = config.Name or "RoundedContainer",
        BackgroundColor3 = config.BackgroundColor3 or Color3.fromRGB(30, 30, 30),
        BackgroundTransparency = config.BackgroundTransparency or 0,
        BorderSizePixel = 0,
        ClipsDescendants = config.ClipsDescendants == true,
        Size = config.Size or UDim2.fromScale(1, 1),
        Position = config.Position or UDim2.new(),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None,
        ZIndex = config.ZIndex or 1,
        Parent = config.Parent,
    })
    local corner = Utilities.Corner(frame, config.Radius or 8)
    local stroke
    if config.Stroke ~= false then
        stroke = Utilities.Stroke(frame, config.StrokeColor, config.StrokeThickness or 1, config.StrokeTransparency or 0)
    end
    return frame, corner, stroke
end

return RoundedContainer
