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
    return Window.new(self, config or {})
end

function Note:_registerWindow(window)
    table.insert(self.Windows, window)
end

function Note:_unregisterWindow(window)
    removeFrom(self.Windows, window)
end

function Note:_registerFlag(flag, component)
    assert(type(flag) == "string" and flag ~= "", "[Note] Flag must be a non-empty string")
    local previous = self._flagBindings[flag]
    if previous and previous ~= component and not previous._destroyed then
        error(string.format('[Note] Flag "%s" is already registered', flag), 3)
    end
    self._flagBindings[flag] = component
    if type(component.GetValue) == "function" then
        self.Flags[flag] = component:GetValue()
    end
end

function Note:_unregisterFlag(flag, component)
    if self._flagBindings[flag] == component then
        self._flagBindings[flag] = nil
        self.Flags[flag] = nil
    end
end

function Note:SetFlag(flag, value, silent)
    local component = self._flagBindings[flag]
    if component and not component._destroyed and type(component.SetValue) == "function" then
        component:SetValue(value, silent == true)
        self.Flags[flag] = component:GetValue()
    else
        self.Flags[flag] = value
    end
    return self
end

function Note:GetFlag(flag)
    return self.Flags[flag]
end

function Note:Notify(config, themeManager)
    self:_ensureInitialized()
    local notification = Notification.new(self, config or {}, themeManager)
    table.insert(self.Notifications, notification)
    self:_layoutNotifications()
    return notification
end

function Note:_layoutNotifications()
    local visible = {}
    for _, notification in ipairs(self.Notifications) do
        if notification and not notification._destroyed and notification.Frame then
            table.insert(visible, notification)
        end
    end
    self.Notifications = visible
    local y = 16
    for _, notification in ipairs(visible) do
        self.Animation:Tween(notification.Frame, {
            Position = UDim2.new(1, -16, 0, y),
        }, self.Tokens.Animation.Normal)
        y += notification.Frame.AbsoluteSize.Y + 10
    end
end

function Note:_removeNotification(notification)
    removeFrom(self.Notifications, notification)
    for _, window in ipairs(self.Windows) do
        removeFrom(window.Notifications, notification)
    end
    self:_layoutNotifications()
end

function Note:Dialog(config, themeManager)
    self:_ensureInitialized()
    if self.ActiveDialog and not self.ActiveDialog._destroyed then
        self.ActiveDialog:Close(nil)
    end
    local dialog = Dialog.new(self, config or {}, themeManager)
    self.ActiveDialog = dialog
    table.insert(self.Dialogs, dialog)
    return dialog
end

function Note:_removeDialog(dialog)
    removeFrom(self.Dialogs, dialog)
    for _, window in ipairs(self.Windows) do
        removeFrom(window.Dialogs, dialog)
    end
    if self.ActiveDialog == dialog then
        self.ActiveDialog = nil
    end
end

function Note:ExportConfig()
    local config = {}
    for flag, value in pairs(self.Flags) do
        config[flag] = Utilities.Serialize(value)
    end
    return config
end

function Note:ImportConfig(config, options)
    assert(type(config) == "table", "[Note] ImportConfig expected a table")
    options = options or {}
    for flag, value in pairs(config) do
        local decoded = Utilities.Deserialize(value)
        if self._flagBindings[flag] or options.AllowUnknown then
            self:SetFlag(flag, decoded, options.Silent)
        end
    end
    return self
end

function Note:WriteConfig(path, config)
    local filesystem = Compatibility.GetFilesystem()
    assert(type(filesystem.writefile) == "function", "[Note] writefile is unavailable in this runtime")
    local encoded = HttpService:JSONEncode(config or self:ExportConfig())
    filesystem.writefile(path, encoded)
    return self
end

function Note:ReadConfig(path, options)
    local filesystem = Compatibility.GetFilesystem()
    assert(type(filesystem.readfile) == "function", "[Note] readfile is unavailable in this runtime")
    local decoded = HttpService:JSONDecode(filesystem.readfile(path))
    self:ImportConfig(decoded, options)
    return decoded
end

function Note:GetCapabilities()
    return Compatibility.Capabilities()
end

function Note:GetIcons()
    return Icons.Names()
end

function Note:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true

    for i = #self.Dialogs, 1, -1 do
        local dialog = self.Dialogs[i]
        if dialog and not dialog._destroyed then
            dialog:Destroy()
        end
    end
    for i = #self.Notifications, 1, -1 do
        local notification = self.Notifications[i]
        if notification and not notification._destroyed then
            notification:Destroy()
        end
    end
    for i = #self.Windows, 1, -1 do
        local window = self.Windows[i]
        if window and not window._destroyed then
            window:Destroy()
        end
    end

    if self.Tooltip then self.Tooltip:Destroy() end
    if self.GlobalThemeManager then self.GlobalThemeManager:Destroy() end
    if self.Overlay then self.Overlay:Destroy() end
    if self.InputManager then self.InputManager:Destroy() end
    if self.Animation then self.Animation:Destroy() end
    if self.ScreenGui then self.ScreenGui:Destroy() end

    table.clear(self.Windows)
    table.clear(self.Notifications)
    table.clear(self.Dialogs)
    table.clear(self.Flags)
    table.clear(self._flagBindings)
    self._initialized = false
end

return Note