local Utilities = require("src/Core/Utilities")
local Layout = require("src/Core/Layout")

local ScrollContainer = {}

function ScrollContainer.Create(config, maid)
    config = config or {}
    local scrolling = Utilities.Create("ScrollingFrame", {
        Name = config.Name or "ScrollContainer",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = config.Size or UDim2.fromScale(1, 1),
        Position = config.Position or UDim2.new(),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = config.ScrollBarThickness or 3,
        ScrollBarImageTransparency = config.ScrollBarImageTransparency or 0.10,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
        Parent = config.Parent,
    })
    Utilities.Padding(scrolling, config.PaddingLeft or 0, config.PaddingRight or 0, config.PaddingTop or 0, config.PaddingBottom or 0)
    local list = Utilities.List(scrolling, Enum.FillDirection.Vertical, config.Spacing or 8)
    Layout.BindCanvas(scrolling, list, maid, config.ExtraCanvas or 0)
    return scrolling, list
end

return ScrollContainer
