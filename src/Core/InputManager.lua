local UserInputService = game:GetService("UserInputService")
local Maid = require("src/Core/Maid")
local Utilities = require("src/Core/Utilities")

local InputManager = {}
InputManager.__index = InputManager

function InputManager.new()
    local self = setmetatable({
        _maid = Maid.new(),
        _keybinds = {},
        _escapeStack = {},
        _outside = {},
        _capture = nil,
        _nextId = 0,
        _destroyed = false,
    }, InputManager)

    self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
        self:_onInputBegan(input, processed)
    end))
    self._maid:Give(UserInputService.InputChanged:Connect(function(input, processed)
        if self._pointerDrag and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            self._pointerDrag.changed(input.Position, input)
        end
    end))
    self._maid:Give(UserInputService.InputEnded:Connect(function(input, processed)
        self:_onInputEnded(input, processed)
    end))
    return self
end

function InputManager:_onInputBegan(input, processed)
    if self._capture then
        local capture = self._capture
        if input.KeyCode == Enum.KeyCode.Escape then
            self._capture = nil
            capture.callback(nil, true)
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            return
        end
        self._capture = nil
        capture.callback(input, false)
        return
    end

    if input.KeyCode == Enum.KeyCode.Escape and #self._escapeStack > 0 then
        local entry = self._escapeStack[#self._escapeStack]
        if entry and entry.callback then
            entry.callback()
            return
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        local point = input.Position
        local outsideSnapshot = {}
        for id, entry in pairs(self._outside) do
            outsideSnapshot[id] = entry
        end
        for id, entry in pairs(outsideSnapshot) do
            if self._outside[id] == entry then
                local inside = false
                for _, gui in ipairs(entry.guis) do
                    if Utilities.PointInGui(point, gui) then
                        inside = true
                        break
                    end
                end
                if not inside then
                    entry.callback()
                end
            end
        end
    end

    for _, entry in pairs(self._keybinds) do
        if entry.enabled() and not processed then
            local matches = input.KeyCode == entry.key or input.UserInputType == entry.key
            if matches then
                if entry.mode == "Hold" then
                    entry.callback(true)
                elseif entry.mode == "Toggle" then
                    entry.state = not entry.state
                    entry.callback(entry.state)
                else
                    entry.callback()
                end
            end
        end
    end
end

function InputManager:_onInputEnded(input, processed)
    if self._pointerDrag and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local drag = self._pointerDrag
        self._pointerDrag = nil
        if drag.ended then
            drag.ended(input.Position, input)
        end
    end
    for _, entry in pairs(self._keybinds) do
        if entry.mode == "Hold" and entry.enabled() and not processed then
            if input.KeyCode == entry.key or input.UserInputType == entry.key then
                entry.callback(false)
            end
        end
    end
end

function InputManager:BeginPointerDrag(changed, ended)
    self._pointerDrag = {
        changed = changed,
        ended = ended,
    }
    return function()
        if self._pointerDrag and self._pointerDrag.changed == changed then
            self._pointerDrag = nil
        end
    end
end

function InputManager:RegisterKeybind(key, callback, options)
    self._nextId += 1
    local id = self._nextId
    options = options or {}
    self._keybinds[id] = {
        key = key,
        callback = callback,
        enabled = options.Enabled or function() return true end,
        mode = options.Mode or "Press",
        state = false,
    }
    return {
        Disconnect = function()
            self._keybinds[id] = nil
        end,
        SetKey = function(_, newKey)
            if self._keybinds[id] then
                self._keybinds[id].key = newKey
            end
        end,
    }
end

function InputManager:Capture(callback)
    self._capture = { callback = callback }
    return function()
        if self._capture and self._capture.callback == callback then
            self._capture = nil
        end
    end
end

function InputManager:PushEscape(callback)
    local entry = { callback = callback }
    table.insert(self._escapeStack, entry)
    return function()
        local index = table.find(self._escapeStack, entry)
        if index then
            table.remove(self._escapeStack, index)
        end
    end
end

function InputManager:RegisterOutside(guis, callback)
    self._nextId += 1
    local id = self._nextId
    self._outside[id] = { guis = guis, callback = callback }
    return function()
        self._outside[id] = nil
    end
end

function InputManager:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    table.clear(self._keybinds)
    table.clear(self._escapeStack)
    table.clear(self._outside)
    self._capture = nil
    self._pointerDrag = nil
    self._maid:Destroy()
end

return InputManager
