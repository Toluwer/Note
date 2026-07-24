local Utilities = require("src/Core/Utilities")

local Icons = {}
local Registry = {
    ["x"] = { Id = 16898613869, Offset = Vector2.new(869, 906), Size = Vector2.new(48, 48) },
    ["minus"] = { Id = 16898613613, Offset = Vector2.new(771, 196), Size = Vector2.new(48, 48) },
    ["check"] = { Id = 16898612819, Offset = Vector2.new(710, 869), Size = Vector2.new(48, 48) },
    ["chevron-down"] = { Id = 16898612819, Offset = Vector2.new(196, 918), Size = Vector2.new(48, 48) },
    ["chevron-up"] = { Id = 16898612819, Offset = Vector2.new(710, 918), Size = Vector2.new(48, 48) },
    ["chevron-left"] = { Id = 16898612819, Offset = Vector2.new(404, 967), Size = Vector2.new(48, 48) },
    ["chevron-right"] = { Id = 16898612819, Offset = Vector2.new(869, 759), Size = Vector2.new(48, 48) },
    ["search"] = { Id = 16898613699, Offset = Vector2.new(918, 857), Size = Vector2.new(48, 48) },
    ["settings"] = { Id = 16898613777, Offset = Vector2.new(771, 257), Size = Vector2.new(48, 48) },
    ["sun"] = { Id = 16898613777, Offset = Vector2.new(967, 453), Size = Vector2.new(48, 48) },
    ["moon"] = { Id = 16898613613, Offset = Vector2.new(306, 918), Size = Vector2.new(48, 48) },
    ["info"] = { Id = 16898613509, Offset = Vector2.new(612, 869), Size = Vector2.new(48, 48) },
    ["menu"] = { Id = 16898613613, Offset = Vector2.new(49, 820), Size = Vector2.new(48, 48) },
    ["panel-left"] = { Id = 16898613613, Offset = Vector2.new(967, 453), Size = Vector2.new(48, 48) },
    ["panel-right"] = { Id = 16898613613, Offset = Vector2.new(820, 857), Size = Vector2.new(48, 48) },
    ["maximize-2"] = { Id = 16898613613, Offset = Vector2.new(820, 514), Size = Vector2.new(48, 48) },
    ["minimize-2"] = { Id = 16898613613, Offset = Vector2.new(967, 0), Size = Vector2.new(48, 48) },
    ["bell"] = { Id = 16898612819, Offset = Vector2.new(820, 257), Size = Vector2.new(48, 48) },
    ["circle-alert"] = { Id = 16898612819, Offset = Vector2.new(918, 808), Size = Vector2.new(48, 48) },
    ["circle-check"] = { Id = 16898612819, Offset = Vector2.new(869, 955), Size = Vector2.new(48, 48) },
    ["copy"] = { Id = 16898613044, Offset = Vector2.new(918, 612), Size = Vector2.new(48, 48) },
    ["trash-2"] = { Id = 16898613869, Offset = Vector2.new(257, 918), Size = Vector2.new(48, 48) },
    ["plus"] = { Id = 16898613699, Offset = Vector2.new(257, 918), Size = Vector2.new(48, 48) },
    ["eye"] = { Id = 16898613353, Offset = Vector2.new(771, 563), Size = Vector2.new(48, 48) },
    ["eye-off"] = { Id = 16898613353, Offset = Vector2.new(820, 514), Size = Vector2.new(48, 48) },
    ["keyboard"] = { Id = 16898613509, Offset = Vector2.new(453, 820), Size = Vector2.new(48, 48) },
    ["mouse-pointer-2"] = { Id = 16898613613, Offset = Vector2.new(820, 661), Size = Vector2.new(48, 48) },
    ["grip-horizontal"] = { Id = 16898613509, Offset = Vector2.new(49, 820), Size = Vector2.new(48, 48) },
    ["palette"] = { Id = 16898613613, Offset = Vector2.new(453, 918), Size = Vector2.new(48, 48) },
    ["paintbrush"] = { Id = 16898613613, Offset = Vector2.new(918, 453), Size = Vector2.new(48, 48) },
    ["refresh-cw"] = { Id = 16898613699, Offset = Vector2.new(404, 869), Size = Vector2.new(48, 48) },
    ["external-link"] = { Id = 16898613353, Offset = Vector2.new(257, 820), Size = Vector2.new(48, 48) },
    ["lock"] = { Id = 16898613509, Offset = Vector2.new(918, 857), Size = Vector2.new(48, 48) },
    ["unlock"] = { Id = 16898613869, Offset = Vector2.new(771, 710), Size = Vector2.new(48, 48) },
}

local IconObject = {}
IconObject.__index = IconObject

function IconObject:SetIcon(name)
    local asset = Registry[name]
    assert(asset, string.format('[Note] Unknown Lucide icon "%s".', tostring(name)))
    self.Name = name
    self.Instance.Image = "rbxassetid://" .. tostring(asset.Id)
    self.Instance.ImageRectOffset = asset.Offset
    self.Instance.ImageRectSize = asset.Size
    return self
end

function IconObject:SetSize(size)
    self.Instance.Size = UDim2.fromOffset(size, size)
    return self
end

function IconObject:SetColor(color)
    self.Instance.ImageColor3 = color
    return self
end

function IconObject:SetTransparency(value)
    self.Instance.ImageTransparency = value
    return self
end

function IconObject:SetVisible(value)
    self.Instance.Visible = value
    return self
end

function IconObject:Destroy()
    if self.Instance then
        self.Instance:Destroy()
        self.Instance = nil
    end
end

function Icons.Has(name)
    return Registry[name] ~= nil
end

function Icons.Get(name)
    return Registry[name]
end

function Icons.Names()
    local names = {}
    for name in pairs(Registry) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function Icons.Create(config)
    config = config or {}
    local name = config.Name or "info"
    local size = config.Size or 18
    local instance = Utilities.Create("ImageLabel", {
        Name = "Icon_" .. name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(size, size),
        ImageColor3 = config.Color or Color3.new(1, 1, 1),
        ImageTransparency = config.Transparency or 0,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = config.ZIndex or 1,
        Parent = config.Parent,
    })
    local object = setmetatable({
        Instance = instance,
        Name = name,
    }, IconObject)
    object:SetIcon(name)
    return object
end

Icons.Registry = Registry
Icons.LucideVersion = "0.363.0"
Icons.AtlasProvider = "latte-soft/lucide-roblox 0.1.3"

return Icons
