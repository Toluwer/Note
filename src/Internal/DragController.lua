local UserInputService = game:GetService("UserInputService")
local Maid = require("src/Core/Maid")
local Utilities = require("src/Core/Utilities")

local DragController = {}
DragController.__index = DragController

local function toVector2(position)
    return Vector2.new(position.X, position.Y)
end

local function round(value)
    return math.floor(value + 0.5)
end

function DragController.new(target, handle, config)
    config = config or {}
    local self = setmetatable({
        Target = target,
        Handle = handle,
        Enabled = config.Enabled ~= false,
        Clamp = config.Clamp ~= false,
        Ignore = config.Ignore or {},
        _maid = Maid.new(),
        _dragging = false,
        _dragInput = nil,
        _pointerOffset = Vector2.zero,
        _destroyed = false,
    }, DragController)

    self._maid:Give(handle.InputBegan:Connect(function(input)
        if not self.Enabled or self._destroyed then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local point = toVector2(input.Position)
        for _, ignored in ipairs(self.Ignore) do
            if Utilities.PointInGui(point, ignored) then
                return
            end
        end

        self._dragging = true
        self._dragInput = input
        self._pointerOffset = point - target.AbsolutePosition
    end))

    self._maid:Give(UserInputService.InputChanged:Connect(function(input)
        if not self._dragging or self._destroyed or not target.Parent then
            return
        end

        local isMouseDrag = self._dragInput
            and self._dragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement
        local isTouchDrag = self._dragInput
            and self._dragInput.UserInputType == Enum.UserInputType.Touch
            and input == self._dragInput

        if not isMouseDrag and not isTouchDrag then
            return
        end

        local point = toVector2(input.Position)
        local topLeft = point - self._pointerOffset
        local parent = target.Parent

        if self.Clamp then
            local parentPosition = parent.AbsolutePosition
            local parentSize = parent.AbsoluteSize
            local targetSize = target.AbsoluteSize
            local visibleWidth = math.min(96, targetSize.X)
            local visibleHeight = math.min(handle.AbsoluteSize.Y, targetSize.Y)

            topLeft = Vector2.new(
                Utilities.Clamp(
                    topLeft.X,
                    parentPosition.X - targetSize.X + visibleWidth,
                    parentPosition.X + parentSize.X - visibleWidth
                ),
                Utilities.Clamp(
                    topLeft.Y,
                    parentPosition.Y,
                    parentPosition.Y + parentSize.Y - visibleHeight
                )
            )
        end

        local parentPosition = parent.AbsolutePosition
        local targetSize = target.AbsoluteSize
        local anchor = target.AnchorPoint
        local anchorPosition = topLeft - parentPosition + Vector2.new(
            targetSize.X * anchor.X,
            targetSize.Y * anchor.Y
        )

        target.Position = UDim2.fromOffset(round(anchorPosition.X), round(anchorPosition.Y))
    end))

    self._maid:Give(UserInputService.InputEnded:Connect(function(input)
        if not self._dragging then
            return
        end

        local endedMouse = self._dragInput
            and self._dragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1
        local endedTouch = self._dragInput
            and self._dragInput.UserInputType == Enum.UserInputType.Touch
            and input == self._dragInput

        if endedMouse or endedTouch then
            self._dragging = false
            self._dragInput = nil
        end
    end))

    return self
end

function DragController:SetEnabled(enabled)
    self.Enabled = enabled == true
    if not self.Enabled then
        self._dragging = false
        self._dragInput = nil
    end
end

function DragController:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self._dragging = false
    self._dragInput = nil
    self._maid:Destroy()
end

return DragController
