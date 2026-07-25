local BaseComponent = require("src/Internal/BaseComponent")
local Utilities = require("src/Core/Utilities")
local Icons = require("src/Core/Icons")
local Maid = require("src/Core/Maid")

local DataTable = {}
DataTable.__index = DataTable
setmetatable(DataTable, { __index = BaseComponent })

local function cloneArray(array)
    local result = {}
    for index, value in ipairs(array or {}) do
        result[index] = value
    end
    return result
end

local function normalizeColumns(columns)
    local normalized = {}
    for index, column in ipairs(columns or {}) do
        if type(column) == "string" then
            normalized[index] = { Key = column, Name = column, Width = 1 }
        elseif type(column) == "table" then
            local key = column.Key or column.Name or index
            normalized[index] = {
                Key = key,
                Name = tostring(column.Name or key),
                Width = math.max(0.05, tonumber(column.Width) or 1),
                Sortable = column.Sortable ~= false,
                Align = column.Align,
                Format = column.Format,
            }
        end
    end
    return normalized
end

function DataTable.new(section, config)
    config = config or {}
    local self = BaseComponent.new(section, "DataTable", config, 220)
    setmetatable(self, DataTable)

    self.Columns = normalizeColumns(config.Columns)
    self.Rows = cloneArray(config.Rows)
    self.PageSize = math.max(1, math.floor(tonumber(config.PageSize) or 5))
    self.Page = 1
    self.Sortable = config.Sortable ~= false
    self.Selectable = config.Selectable ~= false
    self.MultiSelect = config.MultiSelect == true or config.Multi == true
    self.RowKey = config.RowKey
    self.EmptyText = tostring(config.EmptyText or "No rows")
    self._selected = {}
    self._sortKey = nil
    self._sortAscending = true
    self._renderMaid = nil

    self:AddTextBlock(-12)

    local tableSurface = Utilities.Create("Frame", {
        Name = "TableSurface",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, self.Description ~= "" and 50 or 38),
        Size = UDim2.new(1, -20, 0, 0),
        Parent = self.Frame,
    })

    local header = Utilities.Create("Frame", {
        Name = "Header",
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = tableSurface,
    })
    Utilities.Corner(header, self.Library.Tokens.Radius.Small)
    self.Window.ThemeManager:Bind(header, {
        BackgroundColor3 = "SurfaceElevated",
        BackgroundTransparency = "ElevatedTransparency",
    })

    local rows = Utilities.Create("Frame", {
        Name = "Rows",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 0, 0),
        Parent = tableSurface,
    })
    Utilities.List(rows, Enum.FillDirection.Vertical, 4)

    local footer = Utilities.Create("Frame", {
        Name = "Footer",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = tableSurface,
    })

    self.TableSurface = tableSurface
    self.Header = header
    self.RowsFrame = rows
    self.Footer = footer
    self:_render()
    return self
end

function DataTable:_rowKey(row, index)
    if type(self.RowKey) == "function" then
        local ok, value = pcall(self.RowKey, row, index)
        if ok and value ~= nil then return value end
    elseif type(self.RowKey) == "string" and type(row) == "table" and row[self.RowKey] ~= nil then
        return row[self.RowKey]
    end
    return row
end

function DataTable:_cellValue(row, column, rowIndex)
    local value
    if type(row) == "table" then
        value = row[column.Key]
    else
        value = row
    end
    if type(column.Format) == "function" then
        local ok, formatted = pcall(column.Format, value, row, rowIndex)
        if ok then value = formatted end
    end
    return value == nil and "—" or tostring(value)
end

function DataTable:_columnMetrics()
    local total = 0
    for _, column in ipairs(self.Columns) do
        total += column.Width
    end
    if total <= 0 then total = 1 end

    local metrics = {}
    local cursor = 0
    for index, column in ipairs(self.Columns) do
        local width = column.Width / total
        metrics[index] = { Position = cursor, Width = width }
        cursor += width
    end
    return metrics
end

function DataTable:_pageCount()
    return math.max(1, math.ceil(#self.Rows / self.PageSize))
end

function DataTable:_sortedRows()
    local rows = {}
    for index, row in ipairs(self.Rows) do
        rows[index] = { Row = row, Index = index }
    end
    if not self._sortKey then return rows end

    local key = self._sortKey
    local ascending = self._sortAscending
    table.sort(rows, function(a, b)
        local av = type(a.Row) == "table" and a.Row[key] or a.Row
        local bv = type(b.Row) == "table" and b.Row[key] or b.Row
        if type(av) == "number" and type(bv) == "number" then
            return ascending and av < bv or av > bv
        end
        av = string.lower(tostring(av == nil and "" or av))
        bv = string.lower(tostring(bv == nil and "" or bv))
        if av == bv then return a.Index < b.Index end
        return ascending and av < bv or av > bv
    end)
    return rows
end

function DataTable:_setSelected(row, index)
    if not self.Selectable or self.Disabled then return end
    local key = self:_rowKey(row, index)
    if self.MultiSelect then
        self._selected[key] = not self._selected[key] or nil
    else
        table.clear(self._selected)
        self._selected[key] = true
    end
    self:_render()
    self:_fire(self:GetSelected(), row, index)
end

function DataTable:_renderHeader(maid, metrics)
    for _, child in ipairs(self.Header:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    for index, column in ipairs(self.Columns) do
        local metric = metrics[index]
        local button = Utilities.Create("TextButton", {
            Name = "Column_" .. tostring(column.Key),
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(metric.Position, 0, 0, 0),
            Size = UDim2.new(metric.Width, 0, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = column.Name,
            TextSize = 11,
            TextXAlignment = column.Align or Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = self.Header,
        })
        Utilities.Padding(button, 9, self._sortKey == column.Key and 26 or 9, 0, 0)
        self.Window.ThemeManager:Bind(button, { TextColor3 = "TextSecondary" })

        if self._sortKey == column.Key then
            local icon = Icons.Create({
                Name = self._sortAscending and "chevron-up" or "chevron-down",
                Size = 13,
                Parent = button,
            })
            icon.Instance.AnchorPoint = Vector2.new(1, 0.5)
            icon.Instance.Position = UDim2.new(1, -8, 0.5, 0)
            self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextMuted" })
            maid:Give(icon)
        end

        if self.Sortable and column.Sortable ~= false then
            maid:Give(button.Activated:Connect(function()
                self:SortBy(column.Key)
            end))
        end
    end
end

function DataTable:_renderRows(maid, metrics)
    for _, child in ipairs(self.RowsFrame:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    local sorted = self:_sortedRows()
    local startIndex = (self.Page - 1) * self.PageSize + 1
    local endIndex = math.min(#sorted, startIndex + self.PageSize - 1)
    local visibleCount = math.max(0, endIndex - startIndex + 1)
    self.RowsFrame.Size = UDim2.new(1, 0, 0, visibleCount > 0 and (visibleCount * 34 + math.max(0, visibleCount - 1) * 4) or 46)

    if visibleCount == 0 then
        local empty = Utilities.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 46),
            Font = Enum.Font.Gotham,
            Text = self.EmptyText,
            TextSize = 11,
            Parent = self.RowsFrame,
        })
        self.Window.ThemeManager:Bind(empty, { TextColor3 = "TextMuted" })
        return
    end

    for position = startIndex, endIndex do
        local entry = sorted[position]
        local row = entry.Row
        local originalIndex = entry.Index
        local selected = self._selected[self:_rowKey(row, originalIndex)] == true
        local rowButton = Utilities.Create("TextButton", {
            Name = "Row_" .. tostring(originalIndex),
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Text = "",
            Parent = self.RowsFrame,
        })
        Utilities.Corner(rowButton, self.Library.Tokens.Radius.Small)
        self.Window.ThemeManager:Bind(rowButton, {
            BackgroundColor3 = selected and "SurfaceSelected" or "SurfaceElevated",
            BackgroundTransparency = selected and "SelectedTransparency" or function(theme)
                return math.min(1, (theme.ElevatedTransparency or 0.14) + 0.08)
            end,
        })

        for columnIndex, column in ipairs(self.Columns) do
            local metric = metrics[columnIndex]
            local cell = Utilities.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(metric.Position, 0, 0, 0),
                Size = UDim2.new(metric.Width, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = self:_cellValue(row, column, originalIndex),
                TextSize = 11,
                TextXAlignment = column.Align or Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = rowButton,
            })
            Utilities.Padding(cell, 9, 9, 0, 0)
            self.Window.ThemeManager:Bind(cell, { TextColor3 = selected and "Text" or "TextSecondary" })
        end

        maid:Give(rowButton.MouseEnter:Connect(function()
            if not selected then
                self.Library.Animation:Tween(rowButton, { BackgroundTransparency = 0.04 }, self.Library.Tokens.Animation.Fast)
            end
        end))
        maid:Give(rowButton.MouseLeave:Connect(function()
            self.Window.ThemeManager:Apply(rowButton, true)
        end))
        maid:Give(rowButton.Activated:Connect(function()
            self:_setSelected(row, originalIndex)
        end))
    end
end

function DataTable:_renderFooter(maid)
    for _, child in ipairs(self.Footer:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    local pages = self:_pageCount()
    self.Footer.Visible = pages > 1
    if pages <= 1 then return end

    local pageLabel = Utilities.Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(110, 24),
        Font = Enum.Font.Gotham,
        Text = string.format("Page %d of %d", self.Page, pages),
        TextSize = 10,
        Parent = self.Footer,
    })
    self.Window.ThemeManager:Bind(pageLabel, { TextColor3 = "TextMuted" })

    local function pager(name, iconName, x, callback)
        local button = Utilities.Create("TextButton", {
            Name = name,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, x, 0.5, 0),
            Size = UDim2.fromOffset(28, 24),
            Text = "",
            Parent = self.Footer,
        })
        Utilities.Corner(button, self.Library.Tokens.Radius.Small)
        self.Window.ThemeManager:Bind(button, {
            BackgroundColor3 = "SurfaceElevated",
            BackgroundTransparency = "ElevatedTransparency",
        })
        local icon = Icons.Create({ Name = iconName, Size = 13, Parent = button })
        icon.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Instance.Position = UDim2.fromScale(0.5, 0.5)
        self.Window.ThemeManager:Bind(icon.Instance, { ImageColor3 = "TextSecondary" })
        maid:Give(icon)
        maid:Give(button.Activated:Connect(callback))
    end

    pager("Previous", "chevron-left", -86, function() self:SetPage(self.Page - 1) end)
    pager("Next", "chevron-right", 86, function() self:SetPage(self.Page + 1) end)
end

function DataTable:_render()
    if self._destroyed then return end
    self.Page = Utilities.Clamp(self.Page, 1, self:_pageCount())
    local maid = Maid.new()
    self.Maid:Replace("DataTableRender", maid)
    self._renderMaid = maid

    local metrics = self:_columnMetrics()
    self:_renderHeader(maid, metrics)
    self:_renderRows(maid, metrics)
    self:_renderFooter(maid)

    local footerHeight = self.Footer.Visible and 36 or 0
    local surfaceHeight = 38 + self.RowsFrame.Size.Y.Offset + footerHeight
    self.TableSurface.Size = UDim2.new(1, -20, 0, surfaceHeight)
    local top = self.Description ~= "" and 50 or 38
    self.Footer.Position = UDim2.fromOffset(0, 38 + self.RowsFrame.Size.Y.Offset + 4)
    self.Frame.Size = UDim2.new(1, 0, 0, top + surfaceHeight + 10)
end

function DataTable:SetRows(rows)
    if type(rows) ~= "table" then
        error("[Note] DataTable:SetRows expected an array", 2)
    end
    self.Rows = cloneArray(rows)
    self.Page = Utilities.Clamp(self.Page, 1, self:_pageCount())
    self:_render()
    return self
end

function DataTable:GetRows()
    return cloneArray(self.Rows)
end

function DataTable:SetColumns(columns)
    if type(columns) ~= "table" then
        error("[Note] DataTable:SetColumns expected an array", 2)
    end
    self.Columns = normalizeColumns(columns)
    self._sortKey = nil
    self:_render()
    return self
end

function DataTable:SortBy(key, ascending)
    if self._sortKey == key and ascending == nil then
        self._sortAscending = not self._sortAscending
    else
        self._sortKey = key
        self._sortAscending = ascending ~= false
    end
    self.Page = 1
    self:_render()
    return self
end

function DataTable:SetPage(page)
    self.Page = Utilities.Clamp(math.floor(tonumber(page) or 1), 1, self:_pageCount())
    self:_render()
    return self
end

function DataTable:GetPage()
    return self.Page, self:_pageCount()
end

function DataTable:GetSelected()
    local selected = {}
    for index, row in ipairs(self.Rows) do
        if self._selected[self:_rowKey(row, index)] then
            table.insert(selected, row)
        end
    end
    if self.MultiSelect then return selected end
    return selected[1]
end

function DataTable:ClearSelection(silent)
    table.clear(self._selected)
    self:_render()
    if not silent then self:_fire(self:GetSelected()) end
    return self
end

function DataTable:Matches(query)
    if BaseComponent.Matches(self, query) then return true end
    local normalized = Utilities.NormalizeSearch(query)
    for _, column in ipairs(self.Columns) do
        if string.find(Utilities.NormalizeSearch(column.Name), normalized, 1, true) then return true end
    end
    for rowIndex, row in ipairs(self.Rows) do
        for _, column in ipairs(self.Columns) do
            if string.find(Utilities.NormalizeSearch(self:_cellValue(row, column, rowIndex)), normalized, 1, true) then
                return true
            end
        end
    end
    return false
end

function DataTable:Destroy()
    BaseComponent.Destroy(self)
end

return DataTable
