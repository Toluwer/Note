local Utilities = require("src/Core/Utilities")
local Maid = require("src/Core/Maid")
local Signal = require("src/Core/Signal")
local Icons = require("src/Core/Icons")

local Button = require("src/Components/Button")
local Toggle = require("src/Components/Toggle")
local Slider = require("src/Components/Slider")
local Input = require("src/Components/Input")
local Dropdown = require("src/Components/Dropdown")
local Keybind = require("src/Components/Keybind")
local Colorpicker = require("src/Components/Colorpicker")
local Label = require("src/Components/Label")
local Paragraph = require("src/Components/Paragraph")
local Divider = require("src/Components/Divider")

local Section = {}
Section.__index = Section

function Section.new(tab, config)
    config = config or {}
    local self = setmetatable({
        Tab = tab,
        Window = tab.Window,
        Library = tab.Window.Library,
        Name = tostring(config.Name or "Section"),
        Description = tostring(config.Description or ""),
        Collapsible = config.Collapsible == true,
        Collapsed = config.Collapsed == true,
        Visible = config.Visible ~= false,
        Components = {},
        Maid = Maid.new(),
        Destroyed = Signal.new(),
        _layoutOrder = 0,
        _destroyed = false,
    }, Section)

    local frame = Utilities.Create("Frame", {
        Name = "Section_" .. self.Name,
        BackgroundColor3 = Color3.new(),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Visible,
        LayoutOrder = tab:_nextLayoutOrder(),
        Parent = tab.PageContent,
    })
    Utilities.Corner(frame, self.Library.Tokens.Radius.Large)
    local stroke = Utilities.Stroke(frame, Color3.new(), 1, 0)
    self.Window.ThemeManager:Bind(frame, { BackgroundColor3 = "SecondaryBackground" })
    self.Window.ThemeManager:Bind(stroke, { Color = "Border" })

    local headerHeight = self.Description ~= "" and 58 or 46
    local header = Utilities.Create("TextButton", {
        Name = "Header",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.new(1, 0, 0, headerHeight),
        Parent = frame,
    })
    local leftOffset = 14
    if config.Icon then
        local icon = Icons.Create({ Name = config.Icon, Size = 17, Parent = header })
        icon.Instance.Position = UDim2.fromOffset(14, 14)
        self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextSecondary" })
        self.IconObject = icon
        self.Maid:Give(icon)
        leftOffset = 42
    end

    local title = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(leftOffset, self.Description ~= "" and 8 or 0),
        Size = UDim2.new(1, -leftOffset - 46, 0, self.Description ~= "" and 22 or headerHeight),
        Font = Enum.Font.GothamMedium,
        Text = self.Name,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = header,
    })
    self.Window.ThemeManager:Bind(title, { TextColor3 = "Text" })

    local description
    if self.Description ~= "" then
        description = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(leftOffset, 29),
            Size = UDim2.new(1, -leftOffset - 32, 0, 18),
            Font = Enum.Font.Gotham,
            Text = self.Description,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = header,
        })
        self.Window.ThemeManager:Bind(description, { TextColor3 = "TextMuted" })
    end

    if self.Collapsible then
        local chevron = Icons.Create({ Name = self.Collapsed and "chevron-down" or "chevron-up", Size = 15, Parent = header })
        chevron.Instance.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Instance.Position = UDim2.new(1, -14, 0.5, 0)
        self.Window.ThemeManager:Bind(chevron.Instance, { ImageColor3 = "TextMuted" })
        self.Chevron = chevron
        self.Maid:Give(chevron)
        self.Maid:Give(header.Activated:Connect(function()
            self:Toggle()
        end))
    end

    local divider = Utilities.Create("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, headerHeight - 1),
        Size = UDim2.new(1, -24, 0, 1),
        Parent = frame,
    })
    self.Window.ThemeManager:Bind(divider, { BackgroundColor3 = "Border" })

    local bodyClip = Utilities.Create("Frame", {
        Name = "BodyClip",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, headerHeight),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = frame,
    })
    local body = Utilities.Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = bodyClip,
    })
    Utilities.Padding(body, 10, 10, 10, 10)
    local bodyList = Utilities.List(body, Enum.FillDirection.Vertical, 8)

    self.Frame = frame
    self.Header = header
    self.TitleLabel = title
    self.DescriptionLabel = description
    self.BodyClip = bodyClip
    self.Content = body
    self.BodyList = bodyList
    self.Maid:Give(frame)
    self.Maid:Give(self.Destroyed)

    tab:_registerSection(self)
    if self.Collapsed then
        body.Visible = false
        bodyClip.AutomaticSize = Enum.AutomaticSize.None
        bodyClip.Size = UDim2.new(1, 0, 0, 0)
    end
    return self
end

function Section:_nextLayoutOrder()
    self._layoutOrder += 1
    return self._layoutOrder
end

function Section:_registerComponent(component)
    table.insert(self.Components, component)
end

function Section:_unregisterComponent(component)
    local index = table.find(self.Components, component)
    if index then
        table.remove(self.Components, index)
    end
    self:_refreshVisibility()
end

function Section:_refreshVisibility()
    if self._searchActive then
        self:ApplySearch(self._searchQuery)
    end
end

function Section:ApplySearch(query)
    self._searchQuery = query
    self._searchActive = Utilities.NormalizeSearch(query) ~= ""
    local sectionMatch = string.find(
        Utilities.NormalizeSearch(self.Name .. " " .. self.Description),
        Utilities.NormalizeSearch(query),
        1,
        true
    ) ~= nil
    local any = false
    for _, component in ipairs(self.Components) do
        local match = query == "" or sectionMatch or component:Matches(query)
        component.Frame.Visible = component.Visible and match
        any = any or match
    end
    self.Frame.Visible = self.Visible and (query == "" or sectionMatch or any)
    return self.Frame.Visible
end

function Section:SetName(name)
    self.Name = tostring(name)
    self.TitleLabel.Text = self.Name
    return self
end

function Section:SetDescription(description)
    self.Description = tostring(description or "")
    if self.DescriptionLabel then
        self.DescriptionLabel.Text = self.Description
    end
    return self
end

function Section:SetCollapsed(value)
    if not self.Collapsible or self._destroyed then return self end
    value = value == true
    if self.Collapsed == value then return self end
    self.Collapsed = value
    if self.Chevron then
        self.Chevron:SetIcon(value and "chevron-down" or "chevron-up")
    end
    local targetHeight = self.BodyList.AbsoluteContentSize.Y + 20
    self.BodyClip.AutomaticSize = Enum.AutomaticSize.None
    if value then
        self.BodyClip.Size = UDim2.new(1, 0, 0, math.max(self.BodyClip.AbsoluteSize.Y, targetHeight))
        self.Library.Animation:Tween(self.BodyClip, { Size = UDim2.new(1, 0, 0, 0) }, self.Library.Tokens.Animation.Normal)
        task.delay(self.Library.Tokens.Animation.Normal, function()
            if self.BodyClip and self.Collapsed then
                self.Content.Visible = false
            end
        end)
    else
        self.Content.Visible = true
        self.BodyClip.Size = UDim2.new(1, 0, 0, 0)
        self.Library.Animation:Tween(self.BodyClip, { Size = UDim2.new(1, 0, 0, targetHeight) }, self.Library.Tokens.Animation.Normal)
        task.delay(self.Library.Tokens.Animation.Normal, function()
            if self.BodyClip and not self.Collapsed then
                self.BodyClip.AutomaticSize = Enum.AutomaticSize.Y
            end
        end)
    end
    return self
end

function Section:Toggle()
    return self:SetCollapsed(not self.Collapsed)
end

function Section:SetVisible(value)
    self.Visible = value == true
    self.Frame.Visible = self.Visible
    return self
end

function Section:CreateButton(config) return Button.new(self, config) end
function Section:CreateToggle(config) return Toggle.new(self, config) end
function Section:CreateSlider(config) return Slider.new(self, config) end
function Section:CreateInput(config) return Input.new(self, config) end
function Section:CreateDropdown(config) return Dropdown.new(self, config) end
function Section:CreateKeybind(config) return Keybind.new(self, config) end
function Section:CreateColorpicker(config) return Colorpicker.new(self, config) end
function Section:CreateLabel(config) return Label.new(self, config) end
function Section:CreateParagraph(config) return Paragraph.new(self, config) end
function Section:CreateDivider(config) return Divider.new(self, config) end

function Section:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for i = #self.Components, 1, -1 do
        self.Components[i]:Destroy()
    end
    self.Destroyed:Fire()
    self.Tab:_unregisterSection(self)
    self.Maid:Destroy()
    self.Frame = nil
end

return Section
