local Maid = require("src/Core/Maid")
local Signal = require("src/Core/Signal")
local Utilities = require("src/Core/Utilities")

local BaseComponent = {}
BaseComponent.__index = BaseComponent

local RESPONSIVE_CONTROLS = {
    Button = { Name = "Action", FullWidth = true, Breakpoint = 300 },
    ContextMenu = { Name = "OpenMenu", FullWidth = true, Breakpoint = 300 },
    Keybind = { Name = "Capture", FullWidth = true, Breakpoint = 280 },
    Toggle = { Name = "Track", FullWidth = false, Breakpoint = 210 },
    Colorpicker = { Name = "Preview", FullWidth = false, Breakpoint = 210 },
}

local function fixedHeight(size, fallback)
    if size.Y.Offset > 0 then
        return size.Y.Offset
    end
    return fallback
end

function BaseComponent.new(section, componentType, config, height)
    config = config or {}
    local self = setmetatable({
        Section = section,
        Window = section.Window,
        Library = section.Window.Library,
        Type = componentType,
        Name = tostring(config.Name or config.Text or componentType),
        Description = tostring(config.Description or ""),
        Callback = config.Callback,
        Flag = config.Flag,
        Disabled = config.Disabled == true,
        Visible = config.Visible ~= false,
        Responsive = config.Responsive ~= false,
        ResponsiveBreakpoint = tonumber(config.ResponsiveBreakpoint),
        Destroyed = Signal.new(),
        Changed = Signal.new(),
        Maid = Maid.new(),
        _destroyed = false,
        _compactLayout = false,
    }, BaseComponent)

    local frame = Utilities.Create("Frame", {
        Name = componentType .. "_" .. self.Name,
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or self.Library.Tokens.Size.Control),
        Visible = self.Visible,
        LayoutOrder = section:_nextLayoutOrder(),
        Parent = section.Content,
    })
    Utilities.Corner(frame, self.Library.Tokens.Radius.Medium)
    local stroke = Utilities.Stroke(frame, Color3.new(), 1, 0)
    self.Frame = frame
    self.Stroke = stroke
    self.Maid:Give(frame)
    self.Maid:Give(self.Destroyed)
    self.Maid:Give(self.Changed)

    self.Window.ThemeManager:Bind(frame, {
        BackgroundColor3 = "Surface",
        BackgroundTransparency = function(theme)
            return self.Disabled and (theme.DisabledTransparency or 0.58) or (theme.SurfaceTransparency or 0)
        end,
    })
    self.Window.ThemeManager:Bind(stroke, {
        Color = "Border",
        Transparency = "BorderTransparency",
    })

    section:_registerComponent(self)
    if self.Flag then
        self.Library:_registerFlag(self.Flag, self)
    end

    task.defer(function()
        if not self._destroyed then
            self:_bindResponsiveLayout()
        end
    end)

    return self
end

function BaseComponent:AddTextBlock(widthOffset)
    local tallControl = self.Description == "" and self.Frame.Size.Y.Offset >= 68
    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, self.Description ~= "" and 7 or (tallControl and 6 or 0)),
        Size = UDim2.new(
            1,
            widthOffset or -100,
            0,
            self.Description ~= "" and 20 or (tallControl and 20 or self.Frame.Size.Y.Offset)
        ),
        Font = Enum.Font.GothamMedium,
        Text = self.Name,
        TextSize = self.Library.Tokens.Typography.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Frame,
    })
    self.Window.ThemeManager:Bind(title, {
        TextColor3 = function(theme)
            return self.Disabled and theme.TextMuted or theme.Text
        end,
    })
    self.TitleLabel = title

    if self.Description ~= "" then
        local description = Utilities.Create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 27),
            Size = UDim2.new(1, widthOffset or -100, 0, 18),
            Font = Enum.Font.Gotham,
            Text = self.Description,
            TextSize = self.Library.Tokens.Typography.Small,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = self.Frame,
        })
        self.Window.ThemeManager:Bind(description, {
            TextColor3 = function(theme)
                return self.Disabled and theme.TextMuted or theme.TextMuted
            end,
        })
        self.DescriptionLabel = description
    end
    return title
end

function BaseComponent:_bindResponsiveLayout()
    if not self.Responsive or not self.Frame or not self.Frame.Parent then
        return
    end

    local specification = RESPONSIVE_CONTROLS[self.Type]
    if not specification then
        return
    end

    local control = self.Frame:FindFirstChild(specification.Name)
    if not control or not control:IsA("GuiObject") then
        return
    end

    local original = {
        FrameSize = self.Frame.Size,
        ControlAnchorPoint = control.AnchorPoint,
        ControlPosition = control.Position,
        ControlSize = control.Size,
        TitlePosition = self.TitleLabel and self.TitleLabel.Position,
        TitleSize = self.TitleLabel and self.TitleLabel.Size,
        DescriptionPosition = self.DescriptionLabel and self.DescriptionLabel.Position,
        DescriptionSize = self.DescriptionLabel and self.DescriptionLabel.Size,
    }
    self._responsiveControl = control
    self._responsiveOriginal = original

    local breakpoint = self.ResponsiveBreakpoint or specification.Breakpoint

    local function apply()
        if self._destroyed or not self.Frame or not self.Frame.Parent or not control.Parent then
            return
        end

        local width = self.Frame.AbsoluteSize.X
        local compact = width > 0 and width < breakpoint
        if self._compactLayout == compact then
            return
        end
        self._compactLayout = compact

        if compact then
            local hasDescription = self.Description ~= ""
            local controlHeight = fixedHeight(original.ControlSize, 32)
            local controlY = hasDescription and 57 or 38
            local bottomPadding = 10

            if self.TitleLabel then
                self.TitleLabel.Position = UDim2.fromOffset(12, hasDescription and 7 or 6)
                self.TitleLabel.Size = UDim2.new(1, -24, 0, 20)
            end
            if self.DescriptionLabel then
                self.DescriptionLabel.Position = UDim2.fromOffset(12, 29)
                self.DescriptionLabel.Size = UDim2.new(1, -24, 0, 18)
            end

            if specification.FullWidth then
                control.AnchorPoint = Vector2.new(0, 0)
                control.Position = UDim2.fromOffset(12, controlY)
                control.Size = UDim2.new(1, -24, 0, controlHeight)
            else
                control.AnchorPoint = Vector2.new(1, 0)
                control.Position = UDim2.new(1, -12, 0, controlY)
                control.Size = original.ControlSize
            end

            self.Frame.Size = UDim2.new(
                original.FrameSize.X.Scale,
                original.FrameSize.X.Offset,
                0,
                controlY + controlHeight + bottomPadding
            )
        else
            self.Frame.Size = original.FrameSize
            control.AnchorPoint = original.ControlAnchorPoint
            control.Position = original.ControlPosition
            control.Size = original.ControlSize
            if self.TitleLabel and original.TitlePosition and original.TitleSize then
                self.TitleLabel.Position = original.TitlePosition
                self.TitleLabel.Size = original.TitleSize
            end
            if self.DescriptionLabel and original.DescriptionPosition and original.DescriptionSize then
                self.DescriptionLabel.Position = original.DescriptionPosition
                self.DescriptionLabel.Size = original.DescriptionSize
            end
        end

        if self.Section and self.Section.Tab then
            self.Section.Tab:_refreshLayout()
        end
    end

    self.Maid:Give(self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply))
    apply()
end

function BaseComponent:SetVisible(value)
    if self._destroyed then
        return self
    end
    self.Visible = value == true
    self.Frame.Visible = self.Visible
    self.Section:_refreshVisibility()
    return self
end

function BaseComponent:SetDisabled(value)
    if self._destroyed then
        return self
    end
    self.Disabled = value == true
    self.Frame.Active = not self.Disabled
    self.Window.ThemeManager:Apply(self.Frame, true)
    if self.TitleLabel then self.Window.ThemeManager:Apply(self.TitleLabel, true) end
    if self.DescriptionLabel then self.Window.ThemeManager:Apply(self.DescriptionLabel, true) end
    return self
end

function BaseComponent:SetName(name)
    if self._destroyed then
        return self
    end
    self.Name = tostring(name)
    if self.TitleLabel then
        self.TitleLabel.Text = self.Name
    end
    return self
end

function BaseComponent:SetDescription(description)
    if self._destroyed then
        return self
    end
    self.Description = tostring(description or "")
    if self.DescriptionLabel then
        self.DescriptionLabel.Text = self.Description
    end
    return self
end

function BaseComponent:SetCallback(callback)
    if callback ~= nil and type(callback) ~= "function" then
        error("[Note] SetCallback expected a function or nil", 2)
    end
    self.Callback = callback
    return self
end

function BaseComponent:Matches(query)
    query = Utilities.NormalizeSearch(query)
    if query == "" then
        return true
    end
    local haystack = Utilities.NormalizeSearch(self.Name .. " " .. self.Description)
    return string.find(haystack, query, 1, true) ~= nil
end

function BaseComponent:_fire(...)
    self.Changed:Fire(...)
    Utilities.SafeCallback(self.Type, self.Name, self.Callback, ...)
end

function BaseComponent:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    if self.Flag then
        self.Library:_unregisterFlag(self.Flag, self)
    end
    if self.Window and self.Window.ThemeManager and self.Frame then
        self.Window.ThemeManager:Unbind(self.Frame)
        if self.Stroke then
            self.Window.ThemeManager:Unbind(self.Stroke)
        end
    end
    if self.Section then
        self.Section:_unregisterComponent(self)
    end
    self.Destroyed:Fire()
    self.Maid:Destroy()
    self.Frame = nil
    self.Section = nil
    self.Window = nil
end

return BaseComponent