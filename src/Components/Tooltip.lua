local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Layout = require("src/Core/Layout")
local TextMeasure = require("src/Internal/TextMeasure")

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(library)
    return setmetatable({
        Library = library,
        Maid = Maid.new(),
        _destroyed = false,
    }, Tooltip)
end

function Tooltip:Register(target, text, themeManager, options)
    if self._destroyed then
        return function() end
    end
    local binding = Tooltip.Bind(
        self.Library,
        target,
        text,
        themeManager or self.Library.GlobalThemeManager,
        options
    )
    self.Maid:Give(binding)
    return function()
        if self.Maid:Remove(binding) then
            binding:Destroy()
        end
    end
end

function Tooltip:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self.Maid:Destroy()
end

function Tooltip.Bind(library, target, text, themeManager, options)
    options = options or {}
    local maid = Maid.new()
    local popup
    local popupScale
    local openToken = 0

    local function close()
        openToken += 1
        if popup then
            library.Animation:Cancel(popup)
            if popupScale then
                library.Animation:Cancel(popupScale)
            end
            popup:Destroy()
            popup = nil
            popupScale = nil
        end
    end

    local function open()
        local tooltipText = tostring(text or "")
        if popup or not target.Parent or tooltipText == "" then
            return
        end

        local font = Enum.Font.Gotham
        local textSize = 11
        local horizontalPadding = 18
        local verticalPadding = 12
        local maxWidth = math.max(80, tonumber(options.MaxWidth) or 240)
        local minWidth = math.max(0, tonumber(options.MinWidth) or 0)
        local maxLabelWidth = math.max(1, maxWidth - horizontalPadding)
        local minLabelWidth = math.max(1, minWidth - horizontalPadding)
        local naturalSize = TextMeasure.Get(tooltipText, textSize, font, 10000)
        local labelWidth = math.clamp(math.ceil(naturalSize.X) + 2, minLabelWidth, maxLabelWidth)
        local measuredSize = TextMeasure.Get(tooltipText, textSize, font, labelWidth)
        local labelHeight = math.max(14, math.ceil(measuredSize.Y))
        local popupWidth = labelWidth + horizontalPadding
        local popupHeight = labelHeight + verticalPadding

        popup = Utilities.Create("CanvasGroup", {
            Name = "Tooltip",
            BackgroundColor3 = Color3.new(),
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(popupWidth, popupHeight),
            GroupTransparency = 1,
            ZIndex = 310,
            Parent = library.Overlay:GetLayer("Tooltips"),
        })
        Utilities.Corner(popup, library.Tokens.Radius.Small)
        local stroke = Utilities.Stroke(popup, Color3.new(), 1, 0)
        stroke.ZIndex = 311

        popupScale = Utilities.Create("UIScale", {
            Scale = 0.97,
            Parent = popup,
        })

        local label = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(horizontalPadding / 2, verticalPadding / 2),
            Size = UDim2.fromOffset(labelWidth, labelHeight),
            Font = font,
            Text = tooltipText,
            TextSize = textSize,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 312,
            Parent = popup,
        })

        themeManager:Bind(popup, {
            BackgroundColor3 = "SurfaceElevated",
            BackgroundTransparency = "ElevatedTransparency",
        })
        themeManager:Bind(stroke, {
            Color = "Border",
            Transparency = "BorderTransparency",
        })
        themeManager:Bind(label, { TextColor3 = "Text" })

        task.defer(function()
            if popup and popup.Parent then
                Layout.PositionOverlay(target, popup, library.Overlay.Root)
                library.Animation:Tween(
                    popup,
                    { GroupTransparency = 0 },
                    library.Tokens.Animation.Fast,
                    Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out
                )
                library.Animation:Tween(
                    popupScale,
                    { Scale = 1 },
                    library.Tokens.Animation.Fast,
                    Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out
                )
            end
        end)
    end

    maid:Give(target.MouseEnter:Connect(function()
        openToken += 1
        local token = openToken
        local thread = task.delay(options.Delay or 0.45, function()
            if token == openToken and target.Parent then
                open()
            end
        end)
        maid:Give(thread)
    end))
    maid:Give(target.MouseLeave:Connect(close))
    maid:Give(target.AncestryChanged:Connect(function(_, parent)
        if not parent then close() end
    end))
    maid:Give(close)
    return maid
end

return Tooltip
