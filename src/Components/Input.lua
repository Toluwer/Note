local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")

local Input = {}
Input.__index = Input
setmetatable(Input, { __index = BaseComponent })

function Input.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "Input", config, 82)
    setmetatable(self, Input)
    self.Value = tostring(config.Default or "")
    self.ChangedCallback = config.Changed
    self.Validator = config.Validation or config.Validate
    self.CharacterLimit = config.CharacterLimit
    self.NumericOnly = config.NumericOnly == true or config.Numeric == true
    self.ClearButton = config.ClearButton ~= false
    self.Password = config.Password == true
    self.Revealed = false
    self:AddTextBlock(-12)

    local boxFrame = Utilities.Create("Frame", {
        Name = "InputSurface",
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -38),
        Size = UDim2.new(1, -24, 0, 30),
        Parent = self.Frame,
    })
    Utilities.Corner(boxFrame, self.Library.Tokens.Radius.Medium)
    local stroke = Utilities.Stroke(boxFrame, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(boxFrame, { BackgroundColor3 = "Input" })
    self.Window.ThemeManager:Bind(stroke, { Color = "Border" })

    local textBox = Utilities.Create("TextBox", {
        Name = "TextBox",
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, self.Password and -68 or -38, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = config.Placeholder or "",
        Text = self.Value,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = boxFrame,
    })
    textBox.TextEditable = not self.Disabled
    self.Window.ThemeManager:Bind(textBox, {
        TextColor3 = "Text",
        PlaceholderColor3 = "TextMuted",
    })

    local clear = Utilities.Create("TextButton", {
        Name = "Clear",
        Visible = self.ClearButton,
        BackgroundTransparency = 1,
        Text = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        Parent = boxFrame,
    })
    local clearIcon = Icons.Create({ Name = "x", Size = 14, Parent = clear })
    clearIcon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
    clearIcon.Instance.Position = UDim2.fromScale(0.5, 0.5)
    self.Window.ThemeManager:Bind(clearIcon.Instance, { ImageColor3 = "TextMuted" })
    self.Maid:Give(clearIcon)

    if self.Password then
        local reveal = Utilities.Create("TextButton", {
            Name = "Reveal",
            BackgroundTransparency = 1,
            Text = "",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -34, 0.5, 0),
            Size = UDim2.fromOffset(26, 26),
            Parent = boxFrame,
        })
        local revealIcon = Icons.Create({ Name = "eye-off", Size = 15, Parent = reveal })
        revealIcon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
        revealIcon.Instance.Position = UDim2.fromScale(0.5, 0.5)
        self.Window.ThemeManager:Bind(revealIcon.Instance, { ImageColor3 = "TextMuted" })
        self.Maid:Give(revealIcon)
        self.Maid:Give(reveal.Activated:Connect(function()
            self.Revealed = not self.Revealed
            textBox.TextTransparency = self.Revealed and 0 or 1
            revealIcon:SetIcon(self.Revealed and "eye" or "eye-off")
        end))
        self.PasswordMask = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = textBox.Position,
            Size = textBox.Size,
            Font = textBox.Font,
            Text = string.rep("•", #self.Value),
            TextSize = textBox.TextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = boxFrame,
        })
        self.Window.ThemeManager:Bind(self.PasswordMask, { TextColor3 = "Text" })
        textBox.TextTransparency = 1
    end

    local errorLabel = Utilities.Create("TextLabel", {
        Name = "Error",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 1, -4),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
        Parent = self.Frame,
    })
    self.Window.ThemeManager:Bind(errorLabel, { TextColor3 = "Destructive" })

    self.TextBox = textBox
    self.InputStroke = stroke
    self.ErrorLabel = errorLabel

    local mutating = false
    self.Maid:Give(textBox:GetPropertyChangedSignal("Text"):Connect(function()
        if mutating then return end
        local value = textBox.Text
        if self.NumericOnly then
            value = value:gsub("[^%d%.%-]", "")
        end
        if self.CharacterLimit and #value > self.CharacterLimit then
            value = value:sub(1, self.CharacterLimit)
        end
        if value ~= textBox.Text then
            mutating = true
            textBox.Text = value
            mutating = false
        end
        self.Value = value
        if self.PasswordMask then
            self.PasswordMask.Text = string.rep("•", #value)
        end
        if self.Flag then
            self.Library.Flags[self.Flag] = value
        end
        Utilities.SafeCallback(self.Type, self.Name .. " Changed", self.ChangedCallback, value)
    end))
    self.Maid:Give(textBox.FocusLost:Connect(function(enterPressed)
        local valid = true
        local message
        if type(self.Validator) == "function" then
            local ok, result, validationMessage = Utilities.SafeCallback(
                self.Type,
                self.Name .. " Validation",
                self.Validator,
                self.Value
            )
            valid = ok and result ~= false
            message = validationMessage
        end
        self:SetError(valid and nil or (message or "Invalid value"))
        if valid then
            self:_fire(self.Value)
        end
    end))
    self.Maid:Give(clear.Activated:Connect(function()
        if not self.Disabled then
            self:Clear()
        end
    end))
    if self.Flag then
        self.Library.Flags[self.Flag] = self.Value
    end
    return self
end

function Input:SetError(message)
    if self._destroyed then return self end
    local hasError = message ~= nil and tostring(message) ~= ""
    self.Error = hasError and tostring(message) or nil
    self.ErrorLabel.Text = self.Error or ""
    self.ErrorLabel.Visible = hasError
    self.InputStroke.Color = self.Window.ThemeManager:Get(hasError and "Destructive" or "Border")
    self.Frame.Size = UDim2.new(1, 0, 0, hasError and 100 or 82)
    return self
end

function Input:SetValue(value, silent)
    if self._destroyed then return self end
    value = tostring(value or "")
    if self.NumericOnly then
        value = value:gsub("[^%d%.%-]", "")
    end
    if self.CharacterLimit then
        value = value:sub(1, self.CharacterLimit)
    end
    if self.Value == value then
        return self
    end
    self.Value = value
    self.TextBox.Text = value
    if self.PasswordMask then
        self.PasswordMask.Text = string.rep("•", #value)
    end
    if self.Flag then
        self.Library.Flags[self.Flag] = value
    end
    if not silent then
        self:_fire(value)
    end
    return self
end

function Input:GetValue()
    return self.Value
end

function Input:Clear()
    return self:SetValue("")
end

function Input:Focus()
    if not self.Disabled and self.TextBox then
        self.TextBox:CaptureFocus()
    end
    return self
end

return Input
