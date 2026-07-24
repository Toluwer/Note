local Validation = {}

function Validation.Type(component, name, value, expected, optional)
    if value == nil and optional then
        return value
    end
    local actual = typeof(value)
    if actual ~= expected then
        error(string.format('[Note] %s "%s": expected %s, got %s.', component, name or "Unnamed", expected, actual), 3)
    end
    return value
end

function Validation.Callback(component, name, callback)
    if callback ~= nil and type(callback) ~= "function" then
        error(string.format('[Note] %s "%s": Callback must be a function.', component, name or "Unnamed"), 3)
    end
    return callback
end

function Validation.Window(config)
    config = config or {}
    if config.Size ~= nil and typeof(config.Size) ~= "UDim2" then
        error("[Note] Window Size must be a UDim2.", 3)
    end
    if config.MinimumSize ~= nil and typeof(config.MinimumSize) ~= "Vector2" then
        error("[Note] Window MinimumSize must be a Vector2.", 3)
    end
    if config.MaximumSize ~= nil and typeof(config.MaximumSize) ~= "Vector2" then
        error("[Note] Window MaximumSize must be a Vector2.", 3)
    end
    return config
end

function Validation.Slider(config)
    local minimum = tonumber(config.Minimum) or 0
    local maximum = tonumber(config.Maximum) or 100
    if maximum <= minimum then
        error(string.format('[Note] Slider "%s": Maximum must be greater than Minimum.', tostring(config.Name or "Unnamed")), 3)
    end
    local increment = tonumber(config.Increment) or 1
    if increment <= 0 then
        error(string.format('[Note] Slider "%s": Increment must be greater than zero.', tostring(config.Name or "Unnamed")), 3)
    end
    return minimum, maximum, increment
end

function Validation.Dropdown(config)
    if type(config.Options) ~= "table" then
        error(string.format('[Note] Dropdown "%s": Options must be an array.', tostring(config.Name or "Unnamed")), 3)
    end
    return config.Options
end

function Validation.Icon(icons, name)
    if name == nil then
        return nil
    end
    if type(name) ~= "string" or not icons.Has(name) then
        error(string.format('[Note] Unknown Lucide icon "%s".', tostring(name)), 3)
    end
    return name
end

return Validation
