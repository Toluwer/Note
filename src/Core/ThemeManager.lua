local Signal = require("src/Core/Signal")
local Utilities = require("src/Core/Utilities")

local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager.new(library, theme, accent)
    local self = setmetatable({
        Library = library,
        Name = nil,
        Theme = nil,
        Accent = accent,
        _accentOverride = accent ~= nil,
        Bindings = setmetatable({}, { __mode = "k" }),
        Changed = Signal.new(),
        _destroyed = false,
    }, ThemeManager)
    self:SetTheme(theme or library.DefaultTheme or "Dark", false)
    if accent then
        self:SetAccent(accent, false)
    end
    return self
end

function ThemeManager:Resolve(theme)
    if type(theme) == "string" then
        local registered = self.Library.Themes[theme]
        assert(registered, string.format('[Note] Unknown theme "%s"', theme))
        return Utilities.DeepCopy(registered), theme
    elseif type(theme) == "table" then
        local parentName = theme.Inherits or self.Library.DefaultTheme or "Dark"
        local parent = self.Library.Themes[parentName] or self.Library.Themes.Dark
        local resolved = Utilities.Merge(parent, theme)
        return resolved, resolved.Name or "Custom"
    end
    error("[Note] Theme must be a registered theme name or table", 3)
end

function ThemeManager:Get(token)
    if token == "Accent" and self.Accent then
        return self.Accent
    end
    return self.Theme[token]
end

function ThemeManager:Bind(instance, propertyMap)
    if self._destroyed or not instance then
        return
    end
    self.Bindings[instance] = propertyMap
    self:Apply(instance, false)
end

function ThemeManager:Unbind(instance)
    self.Bindings[instance] = nil
end

function ThemeManager:Apply(instance, animate)
    local map = self.Bindings[instance]
    if not map or not instance.Parent then
        return
    end
    local properties = {}
    for property, token in pairs(map) do
        local value
        if type(token) == "function" then
            value = token(self.Theme, self.Accent or self.Theme.Accent)
        else
            value = self:Get(token)
        end
        if value ~= nil then
            properties[property] = value
        end
    end
    if animate and self.Library.Animation then
        self.Library.Animation:Tween(instance, properties, self.Library.Tokens.Animation.Normal)
    else
        for property, value in pairs(properties) do
            local ok, err = pcall(function()
                instance[property] = value
            end)
            if not ok then
                warn("[Note] Theme binding failed:", err)
            end
        end
    end
end

function ThemeManager:ApplyAll(animate)
    for instance in pairs(self.Bindings) do
        self:Apply(instance, animate)
    end
end

function ThemeManager:SetTheme(theme, animate)
    if self._destroyed then
        return
    end
    local resolved, name = self:Resolve(theme)
    self.Theme = resolved
    self.Name = name
    if not self._accentOverride then
        self.Accent = resolved.Accent
    end
    self:ApplyAll(animate ~= false)
    self.Changed:Fire(self.Theme, self.Name)
end

function ThemeManager:SetAccent(color, animate)
    assert(typeof(color) == "Color3", "[Note] Accent must be a Color3")
    if self._destroyed then
        return
    end
    self.Accent = color
    self._accentOverride = true
    self:ApplyAll(animate ~= false)
    self.Changed:Fire(self.Theme, self.Name)
end

function ThemeManager:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    table.clear(self.Bindings)
    self.Changed:Destroy()
end

return ThemeManager
