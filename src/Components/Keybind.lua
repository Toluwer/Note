local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")

local Keybind = {}
Keybind.__index = Keybind
setmetatable(Keybind, { __index = BaseComponent })

local function displayKey(key)
    if not key then return "None" end
    if typeof(key) == "EnumItem" then
        return key.Name
    end
    return tostring(key)
end

function Keybind.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "Keybind", config, 56)
    setmetatable(self, Keybind)
    self.Value = config.Default or Enum.KeyCode.Unknown
    self.Mode = config.Mode or (config.Hold and "Hold" or config.Toggle and "Toggle" or "Press")
    self.ChangedCallback = config.Changed
    self:AddTextBlock(-138)

    local button = Utilities.Create("TextButton", {
        Name = "Capture",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(112, 32),
        Font = Enum.Font.GothamMedium,
        Text = displayKey(self.Value),
        TextSize = 11,
        Parent = self.Frame,
    })
    Utilities.Corner(button, self.Library.Tokens.Radius.Medium)
    local stroke = Utilities.Stroke(button, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(button, { BackgroundColor3 = "Input", TextColor3 = "TextSecondary" })
    self.Window.ThemeManager:Bind(stroke, { Color = "Border" })
    local icon = Icons.Create({ Name = "keyboard", Size = 14, Parent = button })
    icon.Instance.AnchorPoint = Vector2.new(0, 0.5)
    icon.Instance.Position = UDim2.new(0, 8, 0.5, 0)
    self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextMuted" })
    self.Maid:Give(icon)
    button.TextXAlignment = Enum.TextXAlignment.Right
    Utilities.Padding(button, 0, 10, 0, 0)

    self.Button = button
    self._binding = self.Library.InputManager:RegisterKeybind(self.Value, function(state)
        if self.Disabled or self._capturing then return end
        Utilities.SafeCallback(self.Type, self.Name, self.Callback, state)
    end, {
        Mode = self.Mode,
        Enabled = function()
            return not self._destroyed and not self.Disabled and self.Frame.Visible
        end,
    })
    self.Maid:Give(self._binding)

    self.Maid:Give(button.Activated:Connect(function()
        if self.Disabled or self._capturing then return end
        self._capturing = true
        button.Text = "Press a key"
        self.Library.InputManager:Capture(function(input, cancelled)
            self._capturing = false
            if cancelled or not input then
                button.Text = displayKey(self.Value)
                return
            end
            local value = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
            self:SetValue(value)
        end)
    end))
    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    return self
end

function Keybind:SetValue(value, silent)
    if self._destroyed then return self end
    if typeof(value) ~= "EnumItem" then
        error("[Note] Keybind value must be an EnumItem", 2)
    end
    self.Value = value
    self.Button.Text = displayKey(value)
    self._binding:SetKey(value)
    if self.Flag then
        self.Library.Flags[self.Flag] = value
    end
    if not silent then
        Utilities.SafeCallback(self.Type, self.Name .. " Changed", self.ChangedCallback, value)
        self.Changed:Fire(value)
    end
    return self
end

function Keybind:GetValue()
    return self.Value
end

function Keybind:Clear()
    return self:SetValue(Enum.KeyCode.Unknown)
end

return Keybind
