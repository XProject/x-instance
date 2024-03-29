---@type xInstances[]
local instances = {}

---@type xInstancedPlayers[]
local instancedPlayers = {}

---@type xInstancedVehicles[]
local instancedVehicles = {}

do
    for index = 1, #Config.Instances do
        instances[Config.Instances[index]] = {}
    end
end

local function syncInstances()
    GlobalState:set(Shared.State.globalInstancedPlayers, instancedPlayers, true)
    GlobalState:set(Shared.State.globalInstancedVehicles, instancedVehicles, true)
    GlobalState:set(Shared.State.globalInstances, instances, true)
end
CreateThread(syncInstances)

local function resetPlayerStateBag(source)
    local allPlayers = source and {source} or GetPlayers()
    for index = 1, #allPlayers do
        Player(allPlayers[index]).state:set(Shared.State.playerInstance, nil, true)
    end
end

local function resetVehicleStateBag(vehicleNetId)
    local allVehicles = vehicleNetId and {NetworkGetEntityFromNetworkId(vehicleNetId)} or GetAllVehicles()
    for index = 1, #allVehicles do
        Entity(allVehicles[index]).state:set(Shared.State.vehicleInstance, nil, true)
    end
end

---@param instanceName string
---@return boolean
local function doesInstanceExist(instanceName)
    return instances[instanceName] and true or false
end
exports("doesInstanceExist", doesInstanceExist)

---@param instanceName string
---@param instanceHost number
---@return boolean
local function doesInstanceHostExist(instanceName, instanceHost)
    return instances[instanceName]?[instanceHost] and true or false
end
exports("doesInstanceHostExist", doesInstanceHostExist)

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
---@param forceRemove? boolean
---@return boolean, string
local function removeInstanceType(instanceName, forceRemove)
    if not instanceName then return false, "instance_not_valid" end

    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    local instanceToRemove = instances[instanceName]

    if not forceRemove then
        for _, instanceData in pairs(instanceToRemove) do
            local instanceDataPlayers = instanceData?.players
            local instanceDataVehicles = instanceData?.vehicles
            if (instanceDataPlayers and #instanceDataPlayers > 0) or (instanceDataVehicles and #instanceDataVehicles > 0) then return false, "instance_is_occupied" end
        end
    end

    for _, instanceData in pairs(instanceToRemove) do
        local instanceDataPlayers = instanceData?.players
        if instanceDataPlayers then
            for index = 1, #instanceDataPlayers do
                local source = instanceDataPlayers[index]
                instancedPlayers[source] = nil
                Player(source).state:set(Shared.State.playerInstance, nil, true)
            end
        end

        local instanceDataVehicles = instanceData?.vehicles
        if instanceDataVehicles then
            for index = 1, #instanceDataVehicles do
                local vehicleId = instanceDataVehicles[index]
                instancedVehicles[vehicleId] = nil
                Entity(NetworkGetEntityFromNetworkId(vehicleId)).state:set(Shared.State.vehicleInstance, nil, true)
            end
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
local function addPlayerToInstance(source, instanceName, instanceHost, forceAddPlayer)
    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    instanceHost = instanceHost or source
    instances[instanceName][instanceHost] = instances[instanceName][instanceHost] or {}
    instances[instanceName][instanceHost].players = instances[instanceName][instanceHost].players or {}
    local instanceToJoinPlayers = instances[instanceName][instanceHost].players

    for index = 1, #instanceToJoinPlayers do
        local playerSource = instanceToJoinPlayers[index]
        if playerSource == source then
            return false, "player_already_in_instance"
        end
    end

    local currentInstanceName = instancedPlayers[source]?.instance
    local currentInstanceHost = instancedPlayers[source]?.host
    local currentInstancePlayers = (currentInstanceName and currentInstanceHost) and instances[currentInstanceName]?[currentInstanceHost]?.players

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

        instances[currentInstanceName][currentInstanceHost].players = currentInstancePlayers

        local instanceDataPlayers = instances[currentInstanceName][currentInstanceHost]?.players
        local instanceDataVehicles = instances[currentInstanceName][currentInstanceHost]?.vehicles
        if ((instanceDataPlayers and #instanceDataPlayers < 1) or not instanceDataPlayers) and ((instanceDataVehicles and #instanceDataVehicles < 1) or not instanceDataVehicles) then
            instances[currentInstanceName][currentInstanceHost] = nil
        end
    end

    instancedPlayers[source] = {instance = instanceName, host = instanceHost}
    table.insert(instanceToJoinPlayers, source)

    syncInstances()
    Player(source).state:set(Shared.State.playerInstance, instancedPlayers[source], true)

    return true, "successful"
end
exports("addPlayerToInstance", addPlayerToInstance)

---@param source number
---@return boolean, string
local function removePlayerFromInstance(source)
    local instanceName = instancedPlayers[source]?.instance
    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    local isSourceInInstance = instancedPlayers[source] and true or false

    if not isSourceInInstance then return false, "player_not_in_instance" end

    local currentInstanceHost = instancedPlayers[source]?.host
    instancedPlayers[source] = nil

    local currentInstancePlayers = (instanceName and currentInstanceHost) and instances[instanceName]?[currentInstanceHost]?.players

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

        instances[instanceName][currentInstanceHost].players = currentInstancePlayers

        local instanceDataPlayers = instances[instanceName]?[currentInstanceHost]?.players
        local instanceDataVehicles = instances[instanceName]?[currentInstanceHost]?.vehicles
        if ((instanceDataPlayers and #instanceDataPlayers < 1) or not instanceDataPlayers) and ((instanceDataVehicles and #instanceDataVehicles < 1) or not instanceDataVehicles) then
            instances[instanceName][currentInstanceHost] = nil
        end
    end

    syncInstances()
    Player(source).state:set(Shared.State.playerInstance, nil, true)

    return true, "successful"
end
exports("removePlayerFromInstance", removePlayerFromInstance)

---@param instanceName string
---@param hostSource? number
---@return xInstanceData | xInstances | table
local function getInstanceData(instanceName, hostSource)
    return instances[instanceName]?[hostSource] or (hostSource == nil and instances[instanceName]) or {}
end
exports("getInstanceData", getInstanceData)

---@param instanceName string
---@param hostSource number
---@return table<number, playerSource>
local function getInstancePlayers(instanceName, hostSource)
    return instances[instanceName]?[hostSource]?.players or {}
end
exports("getInstancePlayers", getInstancePlayers)

---@param source number
---@return string | nil
local function getPlayerInstance(source)
    return instancedPlayers[source]?.instance
end
exports("getPlayerInstance", getPlayerInstance)

---@param vehicleNetId number
---@param instanceName string
---@param instanceHost number
---@param forceAddVehicle? boolean
---@return boolean, string
local function addVehicleToInstance(vehicleNetId, instanceName, instanceHost, forceAddVehicle)
    local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)

    if not DoesEntityExist(vehicleEntity) then return false, "vehicle_not_exist" end
    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    instances[instanceName][instanceHost] = instances[instanceName][instanceHost] or {}
    instances[instanceName][instanceHost].vehicles = instances[instanceName][instanceHost].vehicles or {}
    local instanceToJoinVehicles = instances[instanceName][instanceHost].vehicles

    for index = 1, #instanceToJoinVehicles do
        local vehicleId = instanceToJoinVehicles[index]
        if vehicleId == vehicleNetId then
            return false, "vehicle_already_in_instance"
        end
    end

    local currentInstanceName = instancedVehicles[vehicleNetId]?.instance
    local currentInstanceHost = instancedVehicles[vehicleNetId]?.host
    local currentInstanceVehicles = (currentInstanceName and currentInstanceHost) and instances[currentInstanceName]?[currentInstanceHost]?.vehicles

    if currentInstanceVehicles then
        for index = 1, #currentInstanceVehicles do
            local vehicleId = currentInstanceVehicles[index]
            if vehicleId == vehicleNetId then
                if forceAddVehicle then
                    table.remove(currentInstanceVehicles, index)
                    break
                else
                    return false, "vehicle_in_another_instance"
                end
            end
        end

        if #currentInstanceVehicles < 1 then
            currentInstanceVehicles = nil
        end

        instances[currentInstanceName][currentInstanceHost].vehicles = currentInstanceVehicles

        local instanceDataPlayers = instances[currentInstanceName]?[currentInstanceHost]?.players
        local instanceDataVehicles = instances[currentInstanceName]?[currentInstanceHost]?.vehicles
        if ((instanceDataPlayers and #instanceDataPlayers < 1) or not instanceDataPlayers) and ((instanceDataVehicles and #instanceDataVehicles < 1) or not instanceDataVehicles) then
            instances[currentInstanceName][currentInstanceHost] = nil
        end
    end

    instancedVehicles[vehicleNetId] = {instance = instanceName, host = instanceHost}
    table.insert(instanceToJoinVehicles, vehicleNetId)

    syncInstances()
    Entity(vehicleEntity).state:set(Shared.State.vehicleInstance, instancedVehicles[vehicleNetId], true)

    return true, "successful"
end
exports("addVehicleToInstance", addVehicleToInstance)

---@param vehicleNetId number
---@return boolean, string
local function removeVehicleFromInstance(vehicleNetId)
    local instanceName = instancedVehicles[vehicleNetId]?.instance
    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    local isVehicleInInstance = instancedVehicles[vehicleNetId] and true or false

    if not isVehicleInInstance then return false, "vehicle_not_in_instance" end

    local currentInstanceHost = instancedVehicles[vehicleNetId]?.host
    instancedVehicles[vehicleNetId] = nil

    local currentInstanceVehicles = (instanceName and currentInstanceHost) and instances[instanceName]?[currentInstanceHost]?.vehicles

    if currentInstanceVehicles then
        for index = 1, #currentInstanceVehicles do
            local vehicleId = currentInstanceVehicles[index]
            if vehicleId == vehicleNetId then
                table.remove(currentInstanceVehicles, index)
                break
            end
        end

        if #currentInstanceVehicles < 1 then
            currentInstanceVehicles = nil
        end

        instances[instanceName][currentInstanceHost].vehicles = currentInstanceVehicles

        local instanceDataPlayers = instances[instanceName]?[currentInstanceHost]?.players
        local instanceDataVehicles = instances[instanceName]?[currentInstanceHost]?.vehicles
        if ((instanceDataPlayers and #instanceDataPlayers < 1) or not instanceDataPlayers) and ((instanceDataVehicles and #instanceDataVehicles < 1) or not instanceDataVehicles) then
            instances[instanceName][currentInstanceHost] = nil
        end
    end

    syncInstances()
    Entity(NetworkGetEntityFromNetworkId(vehicleNetId)).state:set(Shared.State.vehicleInstance, nil, true)

    return true, "successful"
end
exports("removeVehicleFromInstance", removeVehicleFromInstance)

---@param instanceName string
---@param hostSource number
---@return table<number, vehicleNetId>
local function getInstanceVehicles(instanceName, hostSource)
    return instances[instanceName]?[hostSource]?.vehicles or {}
end
exports("getInstanceVehicles", getInstanceVehicles)

---@param vehicleNetId number
---@return string | nil
local function getVehicleInstance(vehicleNetId)
    return instancedVehicles[vehicleNetId]?.instance
end
exports("getVehicleInstance", getVehicleInstance)

AddEventHandler("playerEnteredScope", function(data)
    local playerEntering, player = tonumber(data["player"]), tonumber(data["for"])
    print(("%s is entering %s's scope"):format(playerEntering, player))
    if not playerEntering or not player then return end
    Wait(1000) -- wait because sometimes once server thinks a player is entered another player's scope, the client is not aware of that yet!
    TriggerClientEvent(Shared.Event.playerEnteredScope, playerEntering, player)
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName then return end
    GlobalState:set(Shared.State.globalInstancedPlayers, {}, true)
    GlobalState:set(Shared.State.globalInstancedVehicles, {}, true)
    GlobalState:set(Shared.State.globalInstances, {}, true)
    resetPlayerStateBag()
    resetVehicleStateBag()
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)

AddEventHandler("playerJoining", function()
    resetPlayerStateBag(source)
end)

AddEventHandler("playerDropped", function()
    removePlayerFromInstance(source)
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

    RegisterCommand("addPlayerToInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:addPlayerToInstance(source, args[1], tonumber(args[2]), args[3] and true)
        print(success, message)
    end, false)

    RegisterCommand("removePlayerFromInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:removePlayerFromInstance(source, args[1])
        print(success, message)
    end, false)

    RegisterCommand("addVehicleToInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:addVehicleToInstance(tonumber(args[1]), args[2], tonumber(args[3]), args[3] and true)
        print(success, message)
    end, false)

    RegisterCommand("removeVehicleFromInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:removeVehicleFromInstance(tonumber(args[1]), args[2])
        print(success, message)
    end, false)
end