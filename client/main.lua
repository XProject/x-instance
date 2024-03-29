---@type xInstances[]
local instances = GlobalState[Shared.State.globalInstances]
---@type xInstancedPlayers[]
local instancedPlayers = GlobalState[Shared.State.globalInstancedPlayers]
---@type xInstancedVehicles[]
local instancedVehicles = GlobalState[Shared.State.globalInstancedVehicles]
local currentInstance = nil
local currentHost = nil
local PLAYER_ID = PlayerId()
local PLAYER_SERVER_ID = GetPlayerServerId(PLAYER_ID)

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

---@param source? number
---@return string | nil
local function getPlayerInstance(source)
    return instancedPlayers[source]?.instance or (source == nil and instancedPlayers[PLAYER_SERVER_ID]?.instance) or nil
end
exports("getPlayerInstance", getPlayerInstance)

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

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.globalInstances, nil, function(_, _, value)
    instances = value --[[@as xInstances[] ]]
    print(dumpTable(instances))
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.globalInstancedPlayers, nil, function(_, _, value)
    instancedPlayers = value --[[@as xInstancedPlayers[] ]]
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.globalInstancedVehicles, nil, function(_, _, value)
    instancedVehicles = value --[[@as xInstancedVehicles[] ]]
end)

local function updateInstanceData(instanceName, instanceHost)
    local instanceData = getInstanceData(instanceName, instanceHost)
    for key, tableOfData in pairs(instanceData) do
        if key == "players" then
            for i = 1, #tableOfData do
                local playerServerId = tableOfData[i]

                if playerServerId ~= PLAYER_SERVER_ID then
                    local player = GetPlayerFromServerId(playerServerId)

                    if player ~= -1 and NetworkIsPlayerActive(player) then
                        local conceal = not (instanceName == currentInstance and instanceHost == currentHost) and (instancedPlayers[playerServerId] ~= nil)
                        NetworkConcealPlayer(player, conceal, conceal)
                    end
                end
            end
        elseif key == "vehicles" then
            for i = 1, #tableOfData do
                local vehicleNetId = tableOfData[i]

                if NetworkDoesEntityExistWithNetworkId(vehicleNetId) then
                    local vehicleEntity = NetToVeh(vehicleNetId)

                    if DoesEntityExist(vehicleEntity) then
                        local conceal = not (instanceName == currentInstance and instanceHost == currentHost) and (instancedVehicles[vehicleNetId] ~= nil)
                        NetworkConcealEntity(vehicleEntity, conceal)
                    end
                end
            end
        end
    end
end

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.playerInstance, nil, function(bagName, _, value)
    local playerHandler = GetPlayerFromStateBagName(bagName)
    if not playerHandler or playerHandler == 0 then return end

    local source = tonumber(bagName:gsub("player:", ""), 10)
    if source ~= PLAYER_SERVER_ID then
        local conceal = value and not (value.instance == currentInstance and value.host == currentHost) or false
        NetworkConcealPlayer(playerHandler, conceal, conceal)
        return
    end

    local previousInstance = currentInstance
    local previousHost = currentHost
    currentInstance = value?.instance
    currentHost = value?.host

    updateInstanceData(previousInstance, previousHost)
    updateInstanceData(currentInstance, currentHost)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.vehicleInstance, nil, function(bagName, _, value)
    local entityHandler = GetEntityFromStateBagName(bagName)
    if not entityHandler or entityHandler == 0 then return end

    local conceal = value and not (value.instance == currentInstance and value.host == currentHost) or false
    NetworkConcealEntity(entityHandler, conceal)
end)

RegisterNetEvent(Shared.Event.playerEnteredScope, function(playerServerId)
    if GetInvokingResource() or playerServerId == PLAYER_SERVER_ID then return end
    local player = GetPlayerFromServerId(playerServerId)
    print("here", playerServerId, player, NetworkIsPlayerActive(player))
    if player ~= -1 and NetworkIsPlayerActive(player) then
        print("here2")
        if instancedPlayers[playerServerId] then
            local instanceName, instanceHost = instancedPlayers[playerServerId].instance, instancedPlayers[playerServerId].host
            local conceal = not (instanceName == currentInstance and instanceHost == currentHost)
            print("Player", playerServerId , "is", conceal and "concealed" or "not concealed")
            NetworkConcealPlayer(player, conceal, conceal)
        elseif not instancedPlayers[playerServerId] and NetworkIsPlayerConcealed(player) then -- this elseif should not technically be needed because everytime a player joins another player's scope, since a new player is being created, the players is not concealed anyway...(OneSync baby)
            NetworkConcealPlayer(player, false, false)
        end
    end
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName then return end
    for playerServerId in pairs(instancedPlayers) do
        if playerServerId ~= PLAYER_SERVER_ID then
            local player = GetPlayerFromServerId(playerServerId)

            if player ~= -1 and NetworkIsPlayerActive(player) then
                NetworkConcealPlayer(player, false, false)
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)