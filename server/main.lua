---@type xInstances[]
local instances = {}

---@type xInstancePlayers[]
local instancePlayers = {}

do
    for index = 1, #Config.Instances do
        instances[Config.Instances[index]] = {}
    end
end

local function syncInstances()
    GlobalState:set(Shared.State.globalInstancePlayers, instancePlayers, true)
    GlobalState:set(Shared.State.globalInstances, instances, true)
end
CreateThread(syncInstances)

local function resetStateBag(source)
    local allPlayers = source and {source} or GetPlayers()
    for index = 1, #allPlayers do
        Player(allPlayers[index]).state:set(Shared.State.playerInstance, nil, true)
    end
end
CreateThread(resetStateBag)

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
---@param forceRemovePlayers? boolean
---@return boolean, string
local function removeInstanceType(instanceName, forceRemovePlayers)
    if not instanceName then return false, "instance_not_valid" end

    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    local instanceToRemove = instances[instanceName]

    if not forceRemovePlayers then
        for _, players in pairs(instanceToRemove) do
            if #players > 0 then return false, "instance_is_occupied" end
        end
    end

    for _, players in pairs(instanceToRemove) do
        for index = 1, #players do
            local source = players[index]
            instancePlayers[source] = nil
            Player(source).state:set(Shared.State.playerInstance, nil, true)
        end
    end

    instances[instanceName] = nil

    syncInstances()

    return true, "successful"
end
exports("removeInstanceType", removeInstanceType)

---@param source number
---@param instanceName string
---@param instanceHost? number
---@param forceAddPlayer? boolean
---@return boolean, string
local function addToInstance(source, instanceName, instanceHost, forceAddPlayer)
    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    instanceHost = instanceHost or source
    instances[instanceName][instanceHost] = instances[instanceName][instanceHost] or {}
    local instanceToJoinPlayers = instances[instanceName][instanceHost]

    for index = 1, #instanceToJoinPlayers do
        local playerSource = instanceToJoinPlayers[index]
        if playerSource == source then
            return false, "player_already_in_instance"
        end
    end

    local currentInstanceName = instancePlayers[source]?.instance
    local currentInstanceHost = instancePlayers[source]?.host
    local currentInstancePlayers = (currentInstanceName and currentInstanceHost) and instances[currentInstanceName]?[currentInstanceHost]

    if currentInstancePlayers then
        for index = 1, #currentInstancePlayers do
            local playerSource = currentInstancePlayers[index]
            if playerSource == source then
                if forceAddPlayer then
                    table.remove(currentInstancePlayers, index)
                    break
                else
                    return false, "player_in_another_instance"
                end
            end
        end

        if #currentInstancePlayers < 1 then
            currentInstancePlayers = nil
        end

        instances[currentInstanceName][currentInstanceHost] = currentInstancePlayers
    end

    instancePlayers[source] = {instance = instanceName, host = instanceHost}
    table.insert(instanceToJoinPlayers, source)

    if GetInvokingResource() then -- got call through exports on server
        Player(source).state:set(Shared.State.playerInstance, instancePlayers[source], true)
    end

    syncInstances()

    return true, "successful"
end
exports("addToInstance", addToInstance)

---@param source number
---@param instanceName? string
---@return boolean, string
local function removeFromInstance(source, instanceName)
    instanceName = instanceName or instancePlayers[source]?.instance
    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    local isSourceInInstance = instancePlayers[source] and true or false

    if not isSourceInInstance then return false, "player_not_in_instance" end

    local currentInstanceHost = instancePlayers[source]?.host
    instancePlayers[source] = nil

    Player(source).state:set(Shared.State.playerInstance, nil, true)

    local currentInstancePlayers = (instanceName and currentInstanceHost) and instances[instanceName]?[currentInstanceHost]

    if currentInstancePlayers then
        for index = 1, #currentInstancePlayers do
            local playerSource = currentInstancePlayers[index]
            if playerSource == source then
                table.remove(currentInstancePlayers, index)
                break
            end
        end

        if #currentInstancePlayers < 1 then
            currentInstancePlayers = nil
        end

        instances[instanceName][currentInstanceHost] = currentInstancePlayers
    end

    syncInstances()

    return true, "successful"
end
exports("removeFromInstance", removeFromInstance)

---@param instanceName string
---@param hostSource? number
---@return table<number, playerSource> | table<hostSource, table<number, playerSource>> | nil
local function getInstancePlayers(instanceName, hostSource)
    return hostSource and instances[instanceName][hostSource] or instances[instanceName]
end
exports("getInstancePlayers", getInstancePlayers)

---@param source number
---@return string | nil
local function getPlayerInstance(source)
    return instancePlayers[source]?.instance
end
exports("getPlayerInstance", getPlayerInstance)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.playerInstance, nil, function(bagName, _, value)
    local source = GetPlayerFromStateBagName(bagName)

    if not source or source == 0 or not value then return end

    if GetInvokingResource() then return end -- got call through exports on server

    addToInstance(source, value)
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName then return end
    GlobalState:set(Shared.State.globalInstancePlayers, {}, true)
    GlobalState:set(Shared.State.globalInstances, {}, true)
    resetStateBag()
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)

AddEventHandler("playerJoining", function()
    resetStateBag(source)
end)

if Config.Debug then
    RegisterCommand("addInstanceType", function(source, args)
        local success, message = exports[Shared.currentResourceName]:addInstanceType(args[1])
        print(success, message)
    end, false)

    RegisterCommand("removeInstanceType", function(source, args)
        local success, message = exports[Shared.currentResourceName]:removeInstanceType(args[1], args[2])
        print(success, message)
    end, false)

    RegisterCommand("addToInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:addToInstance(source, args[1], tonumber(args[2]), args[3] and true)
        print(success, message)
    end, false)

    RegisterCommand("removeFromInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:removeFromInstance(source, args[1])
        print(success, message)
    end, false)

    -- populate instances table for testing the execution time of iterating over it in client
    --[[
    math.randomseed()
    function randomString(length)
        local res = ""
        for i = 1, length do
            res = res .. string.char(math.random(97, 122))
        end
        return res
    end

    for _ = 1, 2 do
        instances[randomString(10)] = {}
    end

    local count = 0
    local jj = 0
    for key in pairs(instances) do
        local host = 10
        jj = host
        for _ = 1, 100 do
            instances[key][host] = {}
            for j = 10, 15 do
                table.insert(instances[key][host], j)
            end
            host += 1
        end
        count = count + 1
    end
    print(dumpTable(instances), "count:", count)

    syncInstances()
    ]]
end