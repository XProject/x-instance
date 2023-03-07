---@alias playerSource number
---@type { [string]: table<number, playerSource> }
local instances = {}

do
    for index = 1, #Config.Instances do
        instances[Config.Instances[index]] = {}
    end
end

local function syncInstances()
    GlobalState:set(Shared.State.globalInstances, instances, true)
end
CreateThread(syncInstances)

local function resetPlayersStateBags()
    local allPlayers = GetPlayers()
    for index = 1, #allPlayers do
        Player(allPlayers[index]).state:set(Shared.State.playerInstance, nil, true)
    end
end
CreateThread(resetPlayersStateBags)

---@param instanceName string
---@return boolean
local function doesInstanceExist(instanceName)
    return instances[instanceName] and true or false
end
exports("doesInstanceExist", doesInstanceExist)

---@param instanceName string
---@return boolean, string
local function addInstanceType(instanceName)
    if not instanceName then return false, "instance_not_valid" end

    if doesInstanceExist(instanceName) then return false, "instance_exists" end

    instances[instanceName] = {}

    syncInstances()

    return true, "successful"
end
exports("addInstanceType", addInstanceType)

---@param instanceName string
---@param forceRemovePlayers boolean?
---@return boolean, string
local function removeInstanceType(instanceName, forceRemovePlayers)
    if not instanceName then return false, "instance_not_valid" end

    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    local instancePlayersCount = #instances[instanceName]

    if not forceRemovePlayers then
        if instancePlayersCount > 0 then return false, "instance_is_occupied" end
    end

    for index = 1, instancePlayersCount do
        Player(instances[instanceName][index]).state:set(Shared.State.playerInstance, nil, true)
    end

    instances[instanceName] = nil

    syncInstances()

    return true, "successful"
end
exports("removeInstanceType", removeInstanceType)

---@param source number
---@param instanceName string
---@return boolean, string
local function addToInstance(source, instanceName)
    if not doesInstanceExist(instanceName) then Player(source).state:set(Shared.State.playerInstance, nil, true) return false, "instance_not_exist" end

    if GetInvokingResource() then Player(source).state:set(Shared.State.playerInstance, instanceName, true) end -- got call through exports on server

    for index = 1, #instances[instanceName] do
        if instances[instanceName][index] == source then
            return false, "player_already_instance"
        end
    end

    table.insert(instances[instanceName], source)

    syncInstances()

    return true, "successful"
end
exports("addToInstance", addToInstance)

---@param source number
---@param instanceName string?
---@return boolean, string
local function removeFromInstance(source, instanceName)
    instanceName = instanceName or Player(source).state[Shared.State.playerInstance] --[[@as string]]
    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    local isSourceInInstance = false

    for index = 1, #instances[instanceName] do
        if instances[instanceName][index] == source then
            isSourceInInstance = true
            table.remove(instances[instanceName], index)
            break
        end
    end

    if not isSourceInInstance then return false, "source_not_in_instance" end

    Player(source).state:set(Shared.State.playerInstance, nil, true)

    syncInstances()

    return true, "successful"
end
exports("removeFromInstance", removeFromInstance)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.playerInstance, nil, function(bagName, _, value)
    local source = GetPlayerFromStateBagName(bagName)

    if not source or source == 0 or not value then return end
    if GetInvokingResource() then return end -- got call through exports on server

    addToInstance(source, value)
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName then return end
    GlobalState:set(Shared.State.globalInstances, {}, true)
    resetPlayersStateBags()
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)

AddEventHandler("playerJoining", function()
    Player(source).state:set(Shared.State.playerInstance, nil, true)
end)

if Config.Debug then
    RegisterCommand("addInstanceType", function(source, args)
        local success, message = exports[Shared.currentResourceName]:addInstanceType(args[1])
        print(success, message)
    end, false)

    RegisterCommand("addToInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:addToInstance(source, args[1])
        print(success, message)
    end, false)

    RegisterCommand("removeFromInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:removeFromInstance(source)
        print(success, message)
    end, false)
end