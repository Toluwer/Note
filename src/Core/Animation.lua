local TweenService = game:GetService("TweenService")
local Maid = require("src/Core/Maid")

local Animation = {}
Animation.__index = Animation

function Animation.new(tokens)
    return setmetatable({
        Tokens = tokens,
        _active = setmetatable({}, { __mode = "k" }),
        _maid = Maid.new(),
        _destroyed = false,
    }, Animation)
end

function Animation:Tween(instance, properties, duration, easingStyle, easingDirection)
    if self._destroyed or not instance or not instance.Parent then
        return nil
    end
    local old = self._active[instance]
    if old then
        old:Cancel()
    end
    local info = TweenInfo.new(
        duration or self.Tokens.Animation.Normal,
        easingStyle or Enum.EasingStyle.Quint,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    self._active[instance] = tween
    local connection
    connection = tween.Completed:Connect(function()
        if connection then
            connection:Disconnect()
        end
        if self._active[instance] == tween then
            self._active[instance] = nil
        end
    end)
    tween:Play()
    return tween
end

function Animation:Cancel(instance)
    local tween = self._active[instance]
    if tween then
        tween:Cancel()
        self._active[instance] = nil
    end
end

function Animation:CancelTree(root)
    if not root then return end
    self:Cancel(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        self:Cancel(descendant)
    end
end

function Animation:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    for instance, tween in pairs(self._active) do
        tween:Cancel()
        self._active[instance] = nil
    end
    self._maid:Destroy()
end

return Animation
