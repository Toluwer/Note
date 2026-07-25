local HttpService = game:GetService("HttpService")

local Compatibility = require("src/Core/Compatibility")
local RootGui = require("src/Core/RootGui")
local Utilities = require("src/Core/Utilities")
local Tokens = require("src/Themes/Tokens")
local Dark = require("src/Themes/Dark")
local Light = require("src/Themes/Light")
local Animation = require("src/Core/Animation")
local InputManager = require("src/Core/InputManager")
local Overlay = require("src/Core/Overlay")
local ThemeManager = require("src/Core/ThemeManager")
local Window = require("src/Components/Window")
local Notification = require("src/Components/Notification")
local Dialog = require("src/Components/Dialog")
local Tooltip = require("src/Components/Tooltip")
local Icons = require("src/Core/Icons")

local Note = {}
Note.__index = Note

local function removeFrom(array, value)
    local index = table.find(array, value)
    if index then
        table.remove(array, index)
    end
end

function Note.new()
    return setmetatable({
        Version = "0.3.0",
        Tokens = Tokens,
        Themes = {
            Dark = Dark,
            Light = Light,
        },
        DefaultTheme = "Dark",
        Flags = {},
        Windows = {},
        Notifications = {},
        Dialogs = {},
        _flagBindings = {},
        _initialized = false,
        _destroyed = false,
    }, Note)
end

function Note:Init(config)
    if self._destroyed then
        error("[Note] This library instance was destroyed", 2)
    end
    if self._initialized then
        return self
    end

    config = config or {}
    self.DefaultTheme = config.Theme or self.DefaultTheme
    assert(self.Themes[self.DefaultTheme], string.format('[Note] Unknown default theme "%s"', tostring(self.DefaultTheme)))

    local screenGui, windowLayer = RootGui.Create(config)

    self.ScreenGui = screenGui
    self.Root = windowLayer
    self.Animation = Animation.new(self.Tokens)
    self.InputManager = InputManager.new()
    self.Overlay = Overlay.new(screenGui)
    self.GlobalThemeManager = ThemeManager.new(self, self.DefaultTheme, config.Accent)
    self.Tooltip = Tooltip.new(self)
    self.Capabilities = Compatibility.Capabilities()
    self._initialized = true
    self:_applyFrostedGlass(config.FrostedGlass ~= false)
    return self
end

function Note:_ensureInitialized()
    if not self._initialized then
        self:Init()
    end
end

function Note:_applyFrostedGlass(enabled)
    self.FrostedGlass = enabled == true
    if self.GlobalThemeManager then
        self.GlobalThemeManager:ApplyAll(true)
    end
    for _, window in ipairs(self.Windows) do
        if window and not window._destroyed and window.ThemeManager then
            window.ThemeManager:ApplyAll(true)
        end
    end
end

function Note:SetFrostedGlass(enabled)
    self:_ensureInitialized()
    self:_applyFrostedGlass(enabled ~= false)
    return self
end

function Note:RegisterTheme(name, theme)
    assert(type(name) == "string" and name ~= "", "[Note] Theme name must be a non-empty string")
    assert(type(theme) == "table", "[Note] Theme must be a table")
    local inherited = theme.Inherits or self.DefaultTheme
    local base = self.Themes[inherited] or self.Themes.Dark
    self.Themes[name] = Utilities.Merge(base, theme)
    self.Themes[name].Name = theme.Name or name
    return self
end

function Note:SetDefaultTheme(theme, accent)
    self:_ensureInitialized()
    self.GlobalThemeManager:SetTheme(theme)
    if accent then
        self.GlobalThemeManager:SetAccent(accent)
    end
    self.DefaultTheme = type(theme) == "string" and theme or self.DefaultTheme
    return self
end

function Note:CreateWindow(config)
    self:_ensureInitialized()
    local window = Window.new(self, config)
    table.insert(self.Windows, window)
    window.Destroyed:Connect(function()
        removeFrom(self.Windows, window)
    end)
    return window
end

function Note:Notify(config)
    self:_ensureInitialized()
    local notification = Notification.new(self, nil, config)
    table.insert(self.Notifications, notification)
    notification.Destroyed:Connect(function()
        removeFrom(self.Notifications, notification)
    end)
    return notification
end

function Note:Dialog(config)
    self:_ensureInitialized()
    local dialog = Dialog.new(self, nil, config)
    table.insert(self.Dialogs, dialog)
    dialog.Destroyed:Connect(function()
        removeFrom(self.Dialogs, dialog)
    end)
    return dialog
end

function Note:RegisterTooltip(guiObject, config)
    self:_ensureInitialized()
    return self.Tooltip:Register(guiObject, config)
end

function Note:GetFlag(flag)
    return self.Flags[flag]
end

function Note:SetFlag(flag, value, silent)
    local component = self._flagBindings[flag]
    if component and component.SetValue then
        component:SetValue(value, silent)
    else
        self.Flags[flag] = value
    end
    return self
end

function Note:_registerFlag(flag, component)
    self._flagBindings[flag] = component
    if component.GetValue then
        self.Flags[flag] = component:GetValue()
    end
end

function Note:_unregisterFlag(flag, component)
    if self._flagBindings[flag] == component then
        self._flagBindings[flag] = nil
    end
end

function Note:ExportConfig()
    local output = {}
    for flag, value in pairs(self.Flags) do
        output[flag] = Utilities.Serialize(value)
    end
    return HttpService:JSONEncode(output)
end

function Note:ImportConfig(json, silent)
    local decoded = HttpService:JSONDecode(json)
    for flag, value in pairs(decoded) do
        self:SetFlag(flag, Utilities.Deserialize(value), silent)
    end
    return self
end

function Note:GetCapabilities()
    self:_ensureInitialized()
    return Utilities.DeepCopy(self.Capabilities)
end

function Note:GetIconNames()
    return Icons.Names()
end

function Note:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    for i = #self.Dialogs, 1, -1 do
        self.Dialogs[i]:Destroy()
    end
    for i = #self.Notifications, 1, -1 do
        self.Notifications[i]:Destroy()
    end
    for i = #self.Windows, 1, -1 do
        self.Windows[i]:Destroy()
    end
    if self.Tooltip then self.Tooltip:Destroy() end
    if self.GlobalThemeManager then self.GlobalThemeManager:Destroy() end
    if self.InputManager then self.InputManager:Destroy() end
    if self.Overlay then self.Overlay:Destroy() end
    if self.Animation then self.Animation:Destroy() end
    if self.ScreenGui then self.ScreenGui:Destroy() end
    table.clear(self.Flags)
    table.clear(self._flagBindings)
end

return Note