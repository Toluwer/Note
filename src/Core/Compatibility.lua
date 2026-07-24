local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Compatibility = {}

local function getEnvironment()
    local environment = {}
    if type(getgenv) == "function" then
        local ok, value = pcall(getgenv)
        if ok and type(value) == "table" then
            environment = value
        end
    end
    return environment
end

local function getOptional(name)
    local environment = getEnvironment()
    if environment[name] ~= nil then
        return environment[name]
    end
    return rawget(_G, name)
end

function Compatibility.GetService(name)
    local service = game:GetService(name)
    local cloneReference = getOptional("cloneref")
    if type(cloneReference) == "function" then
        local ok, cloned = pcall(cloneReference, service)
        if ok and cloned then
            return cloned
        end
    end
    return service
end

function Compatibility.ResolveParent(customParent)
    if customParent ~= nil then
        assert(typeof(customParent) == "Instance", "[Note] Parent must be an Instance")
        return customParent
    end

    local getHiddenUi = getOptional("gethui")
    if type(getHiddenUi) == "function" then
        local ok, parent = pcall(getHiddenUi)
        if ok and typeof(parent) == "Instance" then
            return parent
        end
    end

    return CoreGui
end

function Compatibility.GetPlayerGui()
    local player = Players.LocalPlayer
    if not player then
        return nil
    end
    return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
end

function Compatibility.ProtectGui(screenGui)
    local environment = getEnvironment()
    local protector = getOptional("protect_gui")
    if type(protector) ~= "function" and type(environment.syn) == "table" then
        protector = environment.syn.protect_gui
    end
    if type(protector) == "function" then
        pcall(protector, screenGui)
    end
end

function Compatibility.GetFilesystem()
    local environment = getEnvironment()
    local function pick(name)
        return environment[name] or rawget(_G, name)
    end
    return {
        writefile = pick("writefile"),
        readfile = pick("readfile"),
        isfile = pick("isfile"),
        makefolder = pick("makefolder"),
        isfolder = pick("isfolder"),
        getcustomasset = pick("getcustomasset") or pick("getsynasset"),
    }
end

function Compatibility.Capabilities()
    local fs = Compatibility.GetFilesystem()
    return {
        gethui = type(getOptional("gethui")) == "function",
        protectGui = type(getOptional("protect_gui")) == "function"
            or (type(getEnvironment().syn) == "table" and type(getEnvironment().syn.protect_gui) == "function"),
        cloneref = type(getOptional("cloneref")) == "function",
        filesystem = type(fs.writefile) == "function" and type(fs.readfile) == "function",
        customAsset = type(fs.getcustomasset) == "function",
    }
end

return Compatibility
