local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local function blend(base, tint, amount)
    return Color3.new(
        base.R + (tint.R - base.R) * amount,
        base.G + (tint.G - base.G) * amount,
        base.B + (tint.B - base.B) * amount
    )
end

local function foregroundFor(accent)
    local luminance = accent.R * 0.299 + accent.G * 0.587 + accent.B * 0.114
    return luminance >= 0.62 and rgb(18, 18, 20) or rgb(250, 250, 252)
end

local function makeDark(name, accent, strength)
    strength = strength or 1
    local function tint(base, amount)
        return blend(base, accent, math.clamp(amount * strength, 0, 0.32))
    end

    return {
        Name = name,
        Background = tint(rgb(17, 17, 19), 0.075),
        SecondaryBackground = tint(rgb(23, 23, 26), 0.085),
        Surface = tint(rgb(29, 29, 33), 0.10),
        SurfaceElevated = tint(rgb(36, 36, 40), 0.12),
        Input = tint(rgb(25, 25, 29), 0.09),
        SurfaceHover = tint(rgb(42, 42, 47), 0.14),
        SurfaceSelected = tint(rgb(49, 49, 55), 0.19),
        Border = tint(rgb(76, 76, 86), 0.24),
        Text = tint(rgb(246, 246, 248), 0.025),
        TextSecondary = tint(rgb(198, 198, 204), 0.04),
        TextMuted = tint(rgb(145, 145, 154), 0.06),
        Accent = accent,
        AccentForeground = foregroundFor(accent),
        Destructive = rgb(218, 72, 82),
        Warning = rgb(205, 148, 61),
        Success = rgb(63, 160, 107),
        Scrollbar = tint(rgb(112, 112, 122), 0.20),
        Shadow = rgb(0, 0, 0),
        WindowTransparency = 0.14,
        SecondaryTransparency = 0.22,
        SurfaceTransparency = 0.20,
        ElevatedTransparency = 0.14,
        InputTransparency = 0.24,
        HoverTransparency = 0.18,
        SelectedTransparency = 0.10,
        BorderTransparency = 0.34,
        DisabledTransparency = 0.58,
    }
end

local function makeLight(name, accent, tintColor)
    tintColor = tintColor or accent
    return {
        Name = name,
        Background = blend(rgb(250, 250, 251), tintColor, 0.025),
        SecondaryBackground = blend(rgb(244, 244, 246), tintColor, 0.035),
        Surface = blend(rgb(255, 255, 255), tintColor, 0.018),
        SurfaceElevated = blend(rgb(252, 252, 253), tintColor, 0.025),
        Input = blend(rgb(247, 247, 249), tintColor, 0.03),
        SurfaceHover = blend(rgb(238, 238, 241), tintColor, 0.05),
        SurfaceSelected = blend(rgb(229, 229, 233), tintColor, 0.08),
        Border = blend(rgb(184, 184, 191), tintColor, 0.10),
        Text = rgb(27, 27, 30),
        TextSecondary = rgb(76, 76, 82),
        TextMuted = rgb(116, 116, 124),
        Accent = accent,
        AccentForeground = foregroundFor(accent),
        Destructive = rgb(190, 48, 58),
        Warning = rgb(157, 101, 20),
        Success = rgb(34, 126, 76),
        Scrollbar = blend(rgb(134, 134, 142), tintColor, 0.08),
        Shadow = rgb(28, 28, 30),
        WindowTransparency = 0.16,
        SecondaryTransparency = 0.20,
        SurfaceTransparency = 0.14,
        ElevatedTransparency = 0.10,
        InputTransparency = 0.18,
        HoverTransparency = 0.14,
        SelectedTransparency = 0.08,
        BorderTransparency = 0.28,
        DisabledTransparency = 0.62,
    }
end

local palette = {
    { "Black", rgb(210, 210, 216), 0.22 },
    { "White", rgb(35, 35, 39), "light" },
    { "Graphite", rgb(142, 142, 151), 0.45 },
    { "Slate", rgb(148, 163, 184), 0.62 },
    { "Silver", rgb(192, 192, 201), 0.46 },
    { "Red", rgb(239, 68, 68), 0.82 },
    { "Scarlet", rgb(244, 63, 54), 0.82 },
    { "Crimson", rgb(220, 20, 60), 0.80 },
    { "Maroon", rgb(153, 27, 27), 0.92 },
    { "Coral", rgb(244, 114, 104), 0.68 },
    { "Orange", rgb(249, 115, 22), 0.78 },
    { "Tangerine", rgb(251, 146, 60), 0.70 },
    { "Amber", rgb(245, 158, 11), 0.70 },
    { "Gold", rgb(212, 175, 55), 0.66 },
    { "Yellow", rgb(234, 179, 8), 0.58 },
    { "Olive", rgb(132, 143, 45), 0.82 },
    { "Lime", rgb(132, 204, 22), 0.66 },
    { "Green", rgb(34, 197, 94), 0.72 },
    { "Forest", rgb(22, 101, 52), 0.98 },
    { "Emerald", rgb(16, 185, 129), 0.72 },
    { "Jade", rgb(0, 168, 107), 0.78 },
    { "Mint", rgb(110, 231, 183), 0.56 },
    { "Teal", rgb(20, 184, 166), 0.72 },
    { "Turquoise", rgb(45, 212, 191), 0.62 },
    { "Cyan", rgb(6, 182, 212), 0.72 },
    { "Aqua", rgb(34, 211, 238), 0.60 },
    { "Sky", rgb(56, 189, 248), 0.62 },
    { "Blue", rgb(59, 130, 246), 0.78 },
    { "Navy", rgb(30, 64, 175), 0.98 },
    { "Indigo", rgb(99, 102, 241), 0.82 },
    { "Periwinkle", rgb(129, 140, 248), 0.68 },
    { "Violet", rgb(139, 92, 246), 0.82 },
    { "Purple", rgb(168, 85, 247), 0.82 },
    { "Lavender", rgb(196, 181, 253), 0.54 },
    { "Lilac", rgb(192, 132, 252), 0.66 },
    { "Fuchsia", rgb(217, 70, 239), 0.78 },
    { "Magenta", rgb(219, 39, 119), 0.82 },
    { "Pink", rgb(236, 72, 153), 0.76 },
    { "Rose", rgb(244, 63, 94), 0.78 },
    { "Plum", rgb(126, 34, 206), 0.94 },
    { "Peach", rgb(251, 146, 120), 0.62 },
    { "Brown", rgb(166, 123, 91), 0.78 },
    { "Copper", rgb(184, 115, 51), 0.78 },
    { "Bronze", rgb(160, 112, 55), 0.82 },
}

local themes = {}
local order = {}

for _, entry in ipairs(palette) do
    local name, accent, mode = entry[1], entry[2], entry[3]
    themes[name] = mode == "light"
        and makeLight(name, accent, rgb(210, 210, 216))
        or makeDark(name, accent, mode)
    table.insert(order, name)
end

return {
    Themes = themes,
    Order = order,
}
