local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Maid = require("src/Core/Maid")
local Utilities = require("src/Core/Utilities")

local DragController = {}
DragController.__index = DragController

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
        _destroyed = false,
    }, DragController)

    self._maid:Give(handle.InputBegan:Connect(function(input)
        if not self.Enabled then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        for _, ignored in ipairs(self.Ignore) do
            if Utilities.PointInGui(input.Position, ignored) then
                return
            end
        end
        self._dragging = true
        self._input = input
        self._startPosition = input.Position
        self._startTarget = target.Position
    end))

    self._maid:Give(UserInputService.InputChanged:Connect(function(input)
        if not self._dragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local delta = input.Position - self._startPosition
        local newX = self._startTarget.X.Offset + delta.X
        local newY = self._startTarget.Y.Offset + delta.Y
        if self.Clamp and target.Parent then
            local viewport = target.Parent.AbsoluteSize
            local size = target.AbsoluteSize
            local inset = select(1, GuiService:GetGuiInset())
            newX = Utilities.Clamp(newX, -size.X + 80, viewport.X - 80)
            newY = Utilities.Clamp(newY, inset.Y - 4, viewport.Y - 40)
        end
        target.Position = UDim2.new(
            self._startTarget.X.Scale,
            math.floor(newX + 0.5),
            self._startTarget.Y.Scale,
            math.floor(newY + 0.5)
        )
    end))

    self._maid:Give(UserInputService.InputEnded:Connect(function(input)
        if self._dragging and (
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            self._dragging = false
            self._input = nil
        end
    end))

    return self
end

function DragController:SetEnabled(enabled)
    self.Enabled = enabled == true
    if not self.Enabled then
        self._dragging = false
    end
end

function DragController:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self._dragging = false
    self._maid:Destroy()
end

return DragController
