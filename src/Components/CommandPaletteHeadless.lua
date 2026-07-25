local UserInputService = game:GetService("UserInputService")

local CommandPalette = require("src/Components/CommandPalette")

local CommandPaletteHeadless = {}

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

    palette.Maid:Give(UserInputService.InputBegan:Connect(function(input)
        if palette._destroyed or palette.Disabled or palette._isOpen then
            return
        end
        if input.KeyCode ~= palette.OpenKey then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if modifierMatches(palette) then
            palette:Open()
        end
    end))

    return palette
end

return CommandPaletteHeadless
