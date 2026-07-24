local GuiService = game:GetService("GuiService")
local Utilities = require("src/Core/Utilities")

local Layout = {}

function Layout.BindCanvas(scrollingFrame, listLayout, maid, extra)
    local function update()
        if scrollingFrame and scrollingFrame.Parent then
            scrollingFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + (extra or 0))
        end
    end
    maid:Give(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update))
    update()
end

function Layout.PositionOverlay(anchor, popup, root, preferredWidth)
    if not anchor or not anchor.Parent or not popup or not popup.Parent then
        return
    end
    local viewport = root.AbsoluteSize
    local insetTopLeft = select(1, GuiService:GetGuiInset())
    local absolute = anchor.AbsolutePosition - insetTopLeft
    local anchorSize = anchor.AbsoluteSize
    local popupSize = popup.AbsoluteSize
    local width = preferredWidth or math.max(anchorSize.X, popupSize.X)
    local x = Utilities.Clamp(absolute.X, 8, math.max(8, viewport.X - width - 8))
    local below = absolute.Y + anchorSize.Y + 6
    local above = absolute.Y - popupSize.Y - 6
    local y = below
    if below + popupSize.Y > viewport.Y - 8 and above >= 8 then
        y = above
    end
    popup.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
    popup.Size = UDim2.fromOffset(math.floor(width + 0.5), popup.Size.Y.Offset)
end

return Layout
