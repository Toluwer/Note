local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({
        _tasks = {},
        _destroyed = false,
    }, Maid)
end

local function cleanTask(taskItem)
    local kind = typeof(taskItem)
    if kind == "RBXScriptConnection" then
        taskItem:Disconnect()
    elseif kind == "Instance" then
        taskItem:Destroy()
    elseif kind == "function" then
        taskItem()
    elseif type(taskItem) == "thread" then
        task.cancel(taskItem)
    elseif type(taskItem) == "table" then
        if type(taskItem.Destroy) == "function" then
            taskItem:Destroy()
        elseif type(taskItem.Disconnect) == "function" then
            taskItem:Disconnect()
        elseif type(taskItem.Cancel) == "function" then
            taskItem:Cancel()
        end
    end
end

function Maid:Give(taskItem)
    if taskItem == nil then
        return nil
    end
    if self._destroyed then
        pcall(cleanTask, taskItem)
        return taskItem
    end
    table.insert(self._tasks, taskItem)
    return taskItem
end

function Maid:Replace(key, taskItem)
    local old = self._tasks[key]
    if old ~= nil then
        pcall(cleanTask, old)
    end
    self._tasks[key] = taskItem
    return taskItem
end

function Maid:Remove(taskItem)
    for key, value in pairs(self._tasks) do
        if value == taskItem then
            self._tasks[key] = nil
            return true
        end
    end
    return false
end

function Maid:Cleanup()
    local tasks = self._tasks
    self._tasks = {}
    for key, taskItem in pairs(tasks) do
        tasks[key] = nil
        local ok, err = pcall(cleanTask, taskItem)
        if not ok then
            warn("[Note] Cleanup task failed:", err)
        end
    end
end

function Maid:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self:Cleanup()
end

return Maid
