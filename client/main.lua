local instances = GlobalState[Shared.State.globalInstances] --[[ @as xInstances[] ]]
local instancePlayers = GlobalState[Shared.State.globalInstancePlayers] --[[ @as xInstancePlayers[] ]]
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

-- FOR NOW, enterInstance EXPORT MUST NOT BE USED - USE SERVER-SIDE EXPORTS INSTEAD
---@param instanceName string
---@return boolean, string
local function enterInstance(instanceName)
    if not instanceName then return false, "instance_not_valid" end

    if not instances[instanceName] then return false, "instance_not_exist" end

    LocalPlayer.state:set(Shared.State.playerInstance, instanceName, true)

    return true, "successful"
end
exports("enterInstance", enterInstance)

---@param instanceName string
---@param hostSource? number
---@return table<number, playerSource> | table<hostSource, table<number, playerSource>> | table
local function getInstancePlayers(instanceName, hostSource)
    return hostSource and instances[instanceName][hostSource] or instances[instanceName] or {}
end
exports("getInstancePlayers", getInstancePlayers)

---@param source? number
---@return string | nil
local function getPlayerInstance(source)
    return source and instancePlayers[source]?.instance or instancePlayers[PLAYER_SERVER_ID]?.instance
end
exports("getPlayerInstance", getPlayerInstance)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.globalInstances, nil, function(_, _, value)
    instances = value
    -- print(dumpTable(instances))
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.globalInstancePlayers, nil, function(_, _, value)
    instancePlayers = value
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.playerInstance, nil, function(bagName, _, value)
    local playerHandler = GetPlayerFromStateBagName(bagName)
    local source = tonumber(bagName:gsub("player:", ""), 10)

    if not playerHandler or playerHandler == 0 then return end

    if source ~= PLAYER_SERVER_ID then
        local state = value and not (value.instance == currentInstance and value.host == currentHost) or false
        NetworkConcealPlayer(playerHandler, state, state)
        return
    end

    local previousInstance = currentInstance

    currentInstance = value?.instance
    currentHost = value?.host

    local previousInstancePlayers = getInstancePlayers(previousInstance)

    for _, players in pairs(previousInstancePlayers) do
        for i = 1, #players do
            local playerServerId = players[i]

            if playerServerId ~= PLAYER_SERVER_ID then
                local player = GetPlayerFromServerId(playerServerId)

                if player ~= -1 and NetworkIsPlayerActive(player) then
                    local conceal = instancePlayers[playerServerId] and true or false
                    NetworkConcealPlayer(player, conceal, conceal)
                end
            end
        end
    end

    local currentInstancePlayers = getInstancePlayers(currentInstance)

    for hostSource, players in pairs(currentInstancePlayers) do
        for i = 1, #players do
            local playerServerId = players[i]

            if playerServerId ~= PLAYER_SERVER_ID then
                local player = GetPlayerFromServerId(playerServerId)

                if player ~= -1 and NetworkIsPlayerActive(player) then
                    local conceal = not (hostSource == currentHost)
                    NetworkConcealPlayer(player, conceal, conceal)
                end
            end
        end
    end
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName and not currentInstance then return end
    NetworkConcealPlayer(PLAYER_ID, false, false)
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)

if Config.Debug then
    -- FOR NOW, enterInstance EXPORT MUST NOT BE USED - USE SERVER-SIDE EXPORTS INSTEAD
    RegisterCommand("enterInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:enterInstance(args[1])
        print(success, message)
    end, false)
end