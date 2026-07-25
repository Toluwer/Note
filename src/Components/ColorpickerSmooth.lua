local Utilities = require("src/Core/Utilities")
local Colorpicker = require("src/Components/Colorpicker")

local ColorpickerSmooth = {}

function ColorpickerSmooth.new(section, config)
    local picker = Colorpicker.new(section, config or {})
    local originalOpen = picker.Open

    picker.Open = function(self)
        if self._destroyed or self._popup or self.Disabled then
            return self
        end

        originalOpen(self)
        local popup = self._popup
        if not popup then
            return self
        end

        local height = self.AllowAlpha and 392 or 352
        self.Library.Animation:Cancel(popup)
        popup.Size = UDim2.fromOffset(320, height)
        self.Window.ThemeManager:Apply(popup, true)

        local scale = popup:FindFirstChild("SmoothScale")
        if not scale then
            scale = Utilities.Create("UIScale", {
                Name = "SmoothScale",
                Scale = 0.97,
                Parent = popup,
            })
        else
            scale.Scale = 0.97
        end
        self._smoothScale = scale
        self.Library.Animation:Cancel(scale)
        self.Library.Animation:Tween(
            scale,
            { Scale = 1 },
            self.Library.Tokens.Animation.Normal,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )
        return self
    end

    picker.Close = function(self)
        if not self._popup then
            return self
        end

        local popup = self._popup
        local popupMaid = self._popupMaid
        self._popup = nil
        self._popupMaid = nil

        if popupMaid then
            popupMaid:Remove(popup)
            popupMaid:Destroy()
        end

        self.Library.Animation:Cancel(popup)
        if self._smoothScale then
            self.Library.Animation:Cancel(self._smoothScale)
        end

        local parent = popup.Parent
        local wrapper = Utilities.Create("CanvasGroup", {
            Name = "ColorpickerClosing",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = popup.AnchorPoint,
            Position = popup.Position,
            Size = popup.Size,
            GroupTransparency = 0,
            ZIndex = popup.ZIndex,
            Parent = parent,
        })
        local scale = Utilities.Create("UIScale", {
            Scale = 1,
            Parent = wrapper,
        })

        popup.Parent = wrapper
        popup.AnchorPoint = Vector2.new(0, 0)
        popup.Position = UDim2.fromScale(0, 0)
        popup.Size = UDim2.fromScale(1, 1)

        local duration = self.Library.Tokens.Animation.Normal
        local fade = self.Library.Animation:Tween(
            wrapper,
            { GroupTransparency = 1 },
            duration,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.InOut
        )
        self.Library.Animation:Tween(
            scale,
            { Scale = 0.97 },
            duration,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.InOut
        )

        local finalized = false
        local function finalize()
            if finalized then
                return
            end
            finalized = true
            if wrapper and wrapper.Parent then
                wrapper:Destroy()
            end
        end

        if fade then
            local connection
            connection = fade.Completed:Connect(function()
                if connection then
                    connection:Disconnect()
                end
                finalize()
            end)
        end
        task.delay(duration + 0.05, finalize)

        self._smoothScale = nil
        self._fields = nil
        self._alphaGradient = nil
        self._alphaBar = nil
        self._alphaCursor = nil
        return self
    end

    return picker
end

return ColorpickerSmooth
