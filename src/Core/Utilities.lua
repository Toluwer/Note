local HttpService = game:GetService("HttpService")

local Utilities = {}

function Utilities.Create(className, properties, children)
    local instance = Instance.new(className)
    if properties then
        local parent = properties.Parent
        for property, value in pairs(properties) do
            if property ~= "Parent" then
                instance[property] = value
            end
        end
        if children then
            for _, child in ipairs(children) do
                child.Parent = instance
            end
        end
        instance.Parent = parent
    elseif children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    return instance
end

function Utilities.Corner(parent, radius)
    return Utilities.Create("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    })
end

function Utilities.Stroke(parent, color, thickness, transparency)
    return Utilities.Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or Color3.new(1, 1, 1),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = parent,
    })
end

function Utilities.Padding(parent, left, right, top, bottom)
    return Utilities.Create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
        Parent = parent,
    })
end

function Utilities.List(parent, direction, padding, alignment)
    return Utilities.Create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, padding or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
        Parent = parent,
    })
end

function Utilities.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function Utilities.RoundToIncrement(value, increment)
    if increment <= 0 then
        return value
    end
    local rounded = math.floor((value / increment) + 0.5) * increment
    local decimals = math.max(0, math.ceil(-math.log10(increment)))
    local multiplier = 10 ^ decimals
    return math.floor(rounded * multiplier + 0.5) / multiplier
end

function Utilities.FormatNumber(value, increment)
    local decimals = 0
    if increment and increment < 1 then
        decimals = math.max(0, math.ceil(-math.log10(increment)))
    end
    return string.format("%." .. decimals .. "f", value)
end

function Utilities.SafeCallback(componentType, componentName, callback, ...)
    if type(callback) ~= "function" then
        return true
    end
    local args = table.pack(...)
    local results = table.pack(xpcall(function()
        return callback(table.unpack(args, 1, args.n))
    end, debug.traceback))
    if not results[1] then
        warn(string.format(
            '[Note] %s "%s" callback failed:\n%s',
            componentType,
            componentName,
            tostring(results[2])
        ))
    end
    return table.unpack(results, 1, results.n)
end

function Utilities.Merge(base, override)
    local result = {}
    for key, value in pairs(base or {}) do
        result[key] = value
    end
    for key, value in pairs(override or {}) do
        result[key] = value
    end
    return result
end

function Utilities.DeepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[Utilities.DeepCopy(key, seen)] = Utilities.DeepCopy(child, seen)
    end
    return copy
end

function Utilities.Serialize(value)
    local kind = typeof(value)
    if kind == "Color3" then
        return {
            __type = "Color3",
            r = math.floor(value.R * 255 + 0.5),
            g = math.floor(value.G * 255 + 0.5),
            b = math.floor(value.B * 255 + 0.5),
        }
    elseif kind == "EnumItem" then
        return {
            __type = "EnumItem",
            enum = tostring(value.EnumType),
            name = value.Name,
        }
    elseif type(value) == "table" then
        local result = {}
        for key, child in pairs(value) do
            result[key] = Utilities.Serialize(child)
        end
        return result
    end
    return value
end

function Utilities.Deserialize(value)
    if type(value) ~= "table" then
        return value
    end
    if value.__type == "Color3" then
        return Color3.fromRGB(
            Utilities.Clamp(tonumber(value.r) or 0, 0, 255),
            Utilities.Clamp(tonumber(value.g) or 0, 0, 255),
            Utilities.Clamp(tonumber(value.b) or 0, 0, 255)
        )
    elseif value.__type == "EnumItem" and type(value.enum) == "string" and type(value.name) == "string" then
        local enumName = string.match(value.enum, "^Enum%.(.+)$")
        local enumType = enumName and Enum[enumName]
        return enumType and enumType[value.name] or nil
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = Utilities.Deserialize(child)
    end
    return result
end

function Utilities.EncodeConfig(config)
    return HttpService:JSONEncode(Utilities.Serialize(config))
end

function Utilities.DecodeConfig(json)
    return Utilities.Deserialize(HttpService:JSONDecode(json))
end

function Utilities.PointInGui(point, gui)
    if not gui or not gui.Parent or not gui.Visible then
        return false
    end
    local position = gui.AbsolutePosition
    local size = gui.AbsoluteSize
    return point.X >= position.X
        and point.Y >= position.Y
        and point.X <= position.X + size.X
        and point.Y <= position.Y + size.Y
end

function Utilities.NormalizeSearch(value)
    return string.lower(tostring(value or "")):gsub("%s+", " ")
end

function Utilities.ColorToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

function Utilities.HexToColor(value)
    local cleaned = tostring(value or ""):gsub("#", "")
    if #cleaned == 3 then
        cleaned = cleaned:sub(1, 1):rep(2) .. cleaned:sub(2, 2):rep(2) .. cleaned:sub(3, 3):rep(2)
    end
    if not cleaned:match("^[%x]+$") or #cleaned ~= 6 then
        return nil
    end
    return Color3.fromRGB(
        tonumber(cleaned:sub(1, 2), 16),
        tonumber(cleaned:sub(3, 4), 16),
        tonumber(cleaned:sub(5, 6), 16)
    )
end

return Utilities
