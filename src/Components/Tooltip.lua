local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Layout = require("src/Core/Layout")

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
    local openToken = 0

    local function close()
        openToken += 1
        if popup then
            library.Animation:Cancel(popup)
            popup:Destroy()
            popup = nil
        end
    end

    local function open()
        if popup or not target.Parent or tostring(text or "") == "" then
            return
        end
        popup = Utilities.Create("Frame", {
            Name = "Tooltip",
            BackgroundColor3 = Color3.new(),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0),
            ZIndex = 310,
            Parent = library.Overlay:GetLayer("Tooltips"),
        })
        Utilities.Corner(popup, library.Tokens.Radius.Small)
        Utilities.Padding(popup, 9, 9, 6, 6)
        local stroke = Utilities.Stroke(popup, Color3.new(), 1, 0)
        local label = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            Font = Enum.Font.Gotham,
            Text = tostring(text),
            TextSize = 11,
            TextWrapped = true,
            Size = UDim2.fromOffset(options.MaxWidth or 220, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 311,
            Parent = popup,
        })
        themeManager:Bind(popup, { BackgroundColor3 = "SurfaceElevated" })
        themeManager:Bind(stroke, { Color = "Border" })
        themeManager:Bind(label, { TextColor3 = "Text" })
        popup.BackgroundTransparency = 1
        label.TextTransparency = 1
        task.defer(function()
            if popup and popup.Parent then
                Layout.PositionOverlay(target, popup, library.Overlay.Root)
                library.Animation:Tween(popup, { BackgroundTransparency = 0 }, library.Tokens.Animation.Fast)
                library.Animation:Tween(label, { TextTransparency = 0 }, library.Tokens.Animation.Fast)
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
