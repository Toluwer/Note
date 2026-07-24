local FocusManager = {}
FocusManager.__index = FocusManager

function FocusManager.new()
    return setmetatable({
        Current = nil,
        _destroyed = false,
    }, FocusManager)
end

function FocusManager:Set(gui)
    if self._destroyed or self.Current == gui then
        return
    end
    if self.Current and self.Current.Parent and self.Current:IsA("TextBox") then
        self.Current:ReleaseFocus()
    end
    self.Current = gui
end

function FocusManager:Clear(gui)
    if gui == nil or self.Current == gui then
        self.Current = nil
    end
end

function FocusManager:Destroy()
    self._destroyed = true
    self:Clear()
end

return FocusManager
