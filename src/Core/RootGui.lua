local CoreGui = game:GetService("CoreGui")

local Compatibility = require("src/Core/Compatibility")

local RootGui = {}

local function tryParent(screenGui, parent)
    local ok = pcall(function()
        screenGui.Parent = parent
    end)
    return ok and screenGui.Parent ~= nil
end

local function clearOwnedLayers(screenGui)
    for _, name in ipairs({ "Windows", "NoteOverlay" }) do
        local child = screenGui:FindFirstChild(name)
        if child then
            child:Destroy()
        end
    end
end

function RootGui.Create(config)
    config = config or {}
    local name = tostring(config.Name or "NoteUI")
    local preferredParent = Compatibility.ResolveParent(config.Parent)
    local screenGui

    local existing = preferredParent:FindFirstChild(name)
    if existing and existing:IsA("ScreenGui") and existing:GetAttribute("NoteOwned") == true then
        if config.ReuseExisting then
            screenGui = existing
            clearOwnedLayers(screenGui)
        else
            existing:Destroy()
        end
    end

    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = name
        screenGui:SetAttribute("NoteOwned", true)
        Compatibility.ProtectGui(screenGui)

        if not tryParent(screenGui, preferredParent) then
            local playerGui = Compatibility.GetPlayerGui()
            if not playerGui or not tryParent(screenGui, playerGui) then
                if preferredParent ~= CoreGui and not tryParent(screenGui, CoreGui) then
                    screenGui:Destroy()
                    error("[Note] Could not resolve a writable GUI parent", 3)
                end
            end
        end
    end

    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = false
    screenGui.DisplayOrder = tonumber(config.DisplayOrder) or 1000
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local windowLayer = Instance.new("Frame")
    windowLayer.Name = "Windows"
    windowLayer.BackgroundTransparency = 1
    windowLayer.BorderSizePixel = 0
    windowLayer.Size = UDim2.fromScale(1, 1)
    windowLayer.ClipsDescendants = false
    windowLayer.Active = false
    windowLayer.Parent = screenGui

    return screenGui, windowLayer
end

return RootGui
