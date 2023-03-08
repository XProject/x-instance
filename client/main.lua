local instances = GlobalState[Shared.State.globalInstances]
local instancePlayers = GlobalState[Shared.State.globalInstancePlayers]
local currentInstance = nil
local currentHost = nil
local PLAYER_ID = PlayerId()
local PLAYER_SERVER_ID = GetPlayerServerId(PLAYER_ID)
local isThreadRunning = false
local playerPedId, playerPedCoords = nil, nil

local function overrideVoiceProximityCheck(reset)
    pcall(function()
        if reset then return exports["pma-voice"]:resetProximityCheck() end

        exports["pma-voice"]:overrideProximityCheck(function(player)
            local targetPlayerServerId = GetPlayerServerId(player)
            local targetPlayerInstance = instancePlayers[targetPlayerServerId]?.instance
            local targetPlayerInstanceHost = instancePlayers[targetPlayerServerId]?.host
            if targetPlayerInstance ~= currentInstance or targetPlayerInstanceHost ~= currentHost then return false end
            local targetPed = GetPlayerPed(player)
            local voiceRange = GetConvar("voice_useNativeAudio", "false") == "true" and MumbleGetTalkerProximity() * 3 or MumbleGetTalkerProximity()
            local distance = #((playerPedCoords or GetEntityCoords(PlayerPedId())) - GetEntityCoords(targetPed))
            return distance < voiceRange, distance
        end)
    end)
end

local function runInstanceThread()
    if isThreadRunning or not currentInstance then return end
    isThreadRunning = true

    CreateThread(function()
        local count = 0
        while isThreadRunning do
            playerPedId = PlayerPedId()
            playerPedCoords = GetEntityCoords(playerPedId)
            Wait(1000)
        end
    end)

    CreateThread(function()
        SetEntityVisible(PlayerPedId(), false, false) -- hide your ped from everyone
        overrideVoiceProximityCheck()

        while isThreadRunning and currentInstance do
            for hostSource, players in pairs(instances[currentInstance]) do
                local targetPlayer = GetPlayerFromServerId(players[i])
                local targetPlayerPed = GetPlayerPed(targetPlayer)
                if hostSource == currentHost then
                    for _ = 1, #players do
                        SetEntityLocallyVisible(targetPlayerPed) -- show hidden peds that are in same instance as you
                    end
                else
                    for _ = 1, #players do
                        SetEntityNoCollisionEntity(targetPlayerPed, playerPedId, true) -- disable collision with other hidden peds who are in an instance but NOT in a same one as you
                    end
                end
            end
            Wait(0)
        end

        isThreadRunning = false
        playerPedId, playerPedCoords, allPlayers = nil, nil, nil
        SetEntityVisible(PlayerPedId(), true, false) -- show your ped to everyone
        overrideVoiceProximityCheck(true)
    end)
end

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
---@return table<number, playerSource> | table<hostSource, table<number, playerSource>> | nil
local function getInstancePlayers(instanceName, hostSource)
    return hostSource and instances[instanceName][hostSource] or instances[instanceName]
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

AddStateBagChangeHandler(Shared.State.playerInstance, ("player:%s"):format(PLAYER_SERVER_ID), function(bagName, _, value)
    local playerHandler = GetPlayerFromStateBagName(bagName)
    local source = tonumber(bagName:gsub("player:", ""), 10)
    if not playerHandler or playerHandler == 0 or source ~= PLAYER_SERVER_ID then return end

    currentInstance = value?.instance
    currentHost = value?.host

    runInstanceThread()
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName or not currentInstance then return end
    SetEntityVisible(PlayerPedId(), true, false)
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)

if Config.OverrideVoiceProximityCheckByDefault then
    overrideVoiceProximityCheck()
    function overrideVoiceProximityCheck(_) return end
end

if Config.Debug then
    -- FOR NOW, enterInstance EXPORT MUST NOT BE USED - USE SERVER-SIDE EXPORTS INSTEAD
    RegisterCommand("enterInstance", function(source, args)
        local success, message = exports[Shared.currentResourceName]:enterInstance(args[1])
        print(success, message)
    end, false)
end