local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")

local Overlay = {}
Overlay.__index = Overlay

local layers = {
    Popovers = 200,
    Tooltips = 300,
    Notifications = 400,
    Dialogs = 500,
}

function Overlay.new(screenGui)
    local self = setmetatable({
        Maid = Maid.new(),
        Layers = {},
        _destroyed = false,
    }, Overlay)

    local root = Utilities.Create("Frame", {
        Name = "NoteOverlay",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        ClipsDescendants = false,
        Active = false,
        ZIndex = 200,
        Parent = screenGui,
    })
    self.Root = root
    self.Maid:Give(root)

    for name, zIndex in pairs(layers) do
        self.Layers[name] = Utilities.Create("Frame", {
            Name = name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ClipsDescendants = false,
            Active = false,
            ZIndex = zIndex,
            Parent = root,
        })
    end
    return self
end

function Overlay:GetLayer(name)
    local layer = self.Layers[name]
    assert(layer, string.format("[Note] Unknown overlay layer %s", tostring(name)))
    return layer
end

function Overlay:ClearLayer(name)
    local layer = self:GetLayer(name)
    for _, child in ipairs(layer:GetChildren()) do
        child:Destroy()
    end
end

function Overlay:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    table.clear(self.Layers)
    self.Maid:Destroy()
end

return Overlay
