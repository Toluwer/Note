# Split tab layout

Note tabs use the existing single-column section layout by default. Split layout is optional and does not remove or replace the normal narrow layout.

## Keep the normal single-column layout

```lua
local General = Window:CreateTab({
    Name = "General",
    Icon = "settings",
})

local Main = General:CreateSection({
    Name = "Main",
})
```

No layout option is required. Every section uses the full tab width.

## Enable left and right columns

```lua
local Split = Window:CreateTab({
    Name = "Split",
    Icon = "panel-left",
    Layout = "Split",
    SplitGap = 12,
    StackAt = nil,
})

local Left = Split:CreateSection({
    Name = "Left",
    Side = "Left",
})

local Right = Split:CreateSection({
    Name = "Right",
    Side = "Right",
})
```

`StackAt = nil` is the default. The tab stays split even when the window is narrow, so both columns simply become narrower.

## Optional responsive stacking

Set a breakpoint only when the two columns should become one vertical stack below a specific content width:

```lua
local Split = Window:CreateTab({
    Name = "Responsive Split",
    Layout = "Split",
    StackAt = 520,
})
```

At or above 520 pixels, the tab uses left and right columns. Below 520 pixels, the right column is placed beneath the left column.

## Runtime methods

```lua
Tab:SetLayout("Single")
Tab:SetLayout("Split")
Tab:GetLayout()
Tab:SetSplitEnabled(true)
Tab:SetSplitEnabled(false)
Tab:SetStackBreakpoint(520)
Tab:SetStackBreakpoint(nil)
Tab:IsStacked()

Section:SetSide("Left")
Section:SetSide("Right")
Section:GetSide()
```

Changing a tab between single and split mode reparents existing sections without recreating them. A section can also remember its side while the tab is in single-column mode; the stored side is used if split mode is enabled later.

## Layout behavior

- Single-column layout remains the default.
- Split columns maintain independent vertical stacks.
- Search visibility and collapsible-section height changes update the scroll canvas.
- Split mode remains enabled at narrow widths unless `StackAt` is explicitly configured.
- `SplitGap` controls the space between columns and is clamped to at least 4 pixels.
