local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local CommandPalette = require("src/Components/CommandPalette")

local CommandPaletteHeadless = {}
local nextBindingId = 0

local function modifierMatches(palette)
    if palette.Modifier == false then
        return true
    end
    if palette.Modifier == Enum.KeyCode.LeftControl or palette.Modifier == Enum.KeyCode.RightControl then
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    end
    return UserInputService:IsKeyDown(palette.Modifier)
end

local function getOpenKeys(palette)
    if palette.OpenKey == Enum.KeyCode.Comma or palette.OpenKey == Enum.KeyCode.LessThan then
        return { Enum.KeyCode.Comma, Enum.KeyCode.LessThan }
    end
    return { palette.OpenKey }
end

local function keyMatches(palette, keyCode)
    for _, openKey in ipairs(getOpenKeys(palette)) do
        if keyCode == openKey then
            return true
        end
    end
    return false
end

local function canOpen(palette, input)
    if palette._destroyed or palette.Disabled or palette._isOpen then
        return false
    end
    if input and not keyMatches(palette, input.KeyCode) then
        return false
    end
    if UserInputService:GetFocusedTextBox() then
        return false
    end
    return modifierMatches(palette)
end

function CommandPaletteHeadless.new(section, config)
    local palette = CommandPalette.new(section, config or {})

    palette.Visible = false
    palette.Frame.Visible = false
    palette.Frame.Size = UDim2.fromOffset(0, 0)
    if palette.Stroke then
        palette.Stroke.Enabled = false
    end

    palette.SetVisible = function(self, _value)
        self.Visible = false
        if self.Frame then
            self.Frame.Visible = false
        end
        return self
    end

    local function tryOpen(input)
        if canOpen(palette, input) then
            palette:Open()
            return true
        end
        return false
    end

    nextBindingId += 1
    local actionName = "NoteCommandPalette_" .. tostring(nextBindingId)
    local priority = Enum.ContextActionPriority.High.Value + 1000
    local openKeys = getOpenKeys(palette)
    local bound = pcall(function()
        ContextActionService:BindActionAtPriority(
            actionName,
            function(_, inputState, inputObject)
                if inputState ~= Enum.UserInputState.Begin then
                    return Enum.ContextActionResult.Pass
                end
                if tryOpen(inputObject) then
                    return Enum.ContextActionResult.Sink
                end
                return Enum.ContextActionResult.Pass
            end,
            false,
            priority,
            table.unpack(openKeys)
        )
    end)

    if bound then
        palette.Maid:Give(function()
            pcall(function()
                ContextActionService:UnbindAction(actionName)
            end)
        end)
    end

    palette.Maid:Give(UserInputService.InputBegan:Connect(function(input)
        tryOpen(input)
    end))

    return palette
end

return CommandPaletteHeadless
