local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _listeners = {},
        _destroyed = false,
        _nextId = 0,
    }, Signal)
end

function Signal:Connect(callback)
    assert(type(callback) == "function", "Signal:Connect expected a function")
    if self._destroyed then
        return { Disconnect = function() end, Connected = false }
    end

    self._nextId += 1
    local id = self._nextId
    self._listeners[id] = callback

    local connection = { Connected = true }
    function connection:Disconnect()
        if not self.Connected then
            return
        end
        self.Connected = false
        Signal._disconnect(self._signal, self._id)
    end
    connection._signal = self
    connection._id = id
    return connection
end

function Signal._disconnect(self, id)
    self._listeners[id] = nil
end

function Signal:Once(callback)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signal:Fire(...)
    if self._destroyed then
        return
    end
    local snapshot = {}
    for id, callback in pairs(self._listeners) do
        snapshot[id] = callback
    end
    for id, callback in pairs(snapshot) do
        if self._listeners[id] == callback then
            local ok, err = xpcall(callback, debug.traceback, ...)
            if not ok then
                warn("[Note] Signal listener failed:\n" .. tostring(err))
            end
        end
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    table.clear(self._listeners)
end

return Signal
