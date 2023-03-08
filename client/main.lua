local instances = GlobalState[Shared.State.globalInstances]
local instancePlayers = GlobalState[Shared.State.globalInstancePlayers]
local currentInstance = nil
local PLAYER_ID = PlayerId()
local PLAYER_SERVER_ID = GetPlayerServerId(PLAYER_ID)
local isThreadRunning = false
local playerPedId = PlayerPedId()
local playerPedCoords = GetEntityCoords(playerPedId)
local allPlayers = GetActivePlayers()

local function overrideVoiceProximityCheck(reset)
    pcall(function()
        if reset then return exports["pma-voice"]:resetProximityCheck() end

        exports["pma-voice"]:overrideProximityCheck(function(player)
            local targetPedInstance = instancePlayers[GetPlayerServerId(player)] --[[Player(GetPlayerServerId(player)).state[Shared.State.playerInstance]]
            if not targetPedInstance or targetPedInstance ~= currentInstance then return false end
            local targetPed = GetPlayerPed(player)
            local voiceRange = GetConvar("voice_useNativeAudio", "false") == "true" and MumbleGetTalkerProximity() * 3 or MumbleGetTalkerProximity()
            local distance = #(playerPedCoords - GetEntityCoords(targetPed))
            return distance < voiceRange, distance
        end)
    end)
end

local function runInstanceThread()
    if isThreadRunning or not currentInstance then return end
    isThreadRunning = true

    CreateThread(function()
        while currentInstance do
            playerPedId = PlayerPedId()
            playerPedCoords = GetEntityCoords(playerPedId)
            allPlayers = GetActivePlayers()
            Wait(1000)
        end
    end)

    CreateThread(function()
        playerPedId = PlayerPedId()
        SetEntityVisible(playerPedId, false, false) -- hide your ped from everyone
        overrideVoiceProximityCheck()

        while isThreadRunning and currentInstance do

            for i = 1, #allPlayers do
                local targetPlayer = allPlayers[i]
                local targetPlayerServerId = GetPlayerServerId(targetPlayer)
                local targetPlayerInstance = instancePlayers[targetPlayerServerId] --[[Player(targetPlayerServerId).state[Shared.State.playerInstance]]

                if targetPlayerInstance then
                    local targetPlayerPed = GetPlayerPed(targetPlayer)

                    if targetPlayerInstance == currentInstance then
                        SetEntityLocallyVisible(targetPlayerPed) -- show hidden peds that are in same instance as you
                    else
                        SetEntityNoCollisionEntity(targetPlayerPed, playerPedId, true) -- disable collision with other hidden peds who are in an instance but NOT in a same one as you
                    end
                end
            end

            Wait(0)
        end

        isThreadRunning = false
        playerPedId = PlayerPedId()
        SetEntityVisible(playerPedId, true, false) -- show your ped to everyone
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
---@return table<number, playerSource> | nil
local function getInstancePlayers(instanceName)
    return instances[instanceName]
end
exports("getInstancePlayers", getInstancePlayers)

---@param source? string
---@return string | nil
local function getPlayerInstance(source)
    return source and instancePlayers[source] or instancePlayers[PLAYER_SERVER_ID]
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
    -- print(dumpTable(instancePlayers))
end)

AddStateBagChangeHandler(Shared.State.playerInstance, ("player:%s"):format(PLAYER_SERVER_ID), function(bagName, _, value)
    local playerHandler = GetPlayerFromStateBagName(bagName)
    local source = tonumber(bagName:gsub("player:", ""), 10)
    if not playerHandler or playerHandler == 0 or source ~= PLAYER_SERVER_ID then return end

    currentInstance = value

    runInstanceThread()
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName or not currentInstance then return end
    SetEntityVisible(PlayerPedId(), true, false)
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