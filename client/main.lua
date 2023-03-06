local instances = GlobalState[Shared.State.globalInstances]
local currentInstance = nil
local playerId = PlayerId()
local playerServerId = GetPlayerServerId(playerId)

AddStateBagChangeHandler(Shared.State.globalInstances, nil, function(_, _, value)
    instances = value
end)

local function enterInstance(instanceName)
    if not instanceName then return false, "instance_not_valid" end

    if not instances[instanceName] then return false, "instance_exists" end

    LocalPlayer.state:set(Shared.State.playerInstance, instanceName, true)

    return true, "successful"
end
exports("enterInstance", enterInstance)

local function runInstanceThread()
    if currentInstance then return end
    CreateThread(function()
        local localPlayerPed = PlayerPedId()
        NetworkSetEntityInvisibleToNetwork(localPlayerPed, true) -- hide your ped for everyone
        while currentInstance do
            localPlayerPed = PlayerPedId()
            SetLocalPlayerVisibleLocally(true)  -- show your ped for to yourself
            for instanceName, instancePlayers in pairs(instances) do
                if instanceName ~= currentInstance then
                    for i = 1, #instancePlayers do
                        local player = GetPlayerFromServerId(instancePlayers[i])
                        if player and NetworkIsPlayerActive(player) then
                            local playerPed = GetPlayerPed(player)
                            SetEntityNoCollisionEntity(playerPed, localPlayerPed, true)
                        end
                    end
                else
                    for i = 1, #instancePlayers do
                        local player = GetPlayerFromServerId(instancePlayers[i])
                        if player and NetworkIsPlayerActive(player) then
                            local playerPed = GetPlayerPed(player)
                            -- SetEntityLocallyVisible(playerPed)
                            SetPlayerVisibleLocally(playerPed, true)
                        end
                    end
                end
            end
            Wait(0)
        end
        NetworkSetEntityInvisibleToNetwork(localPlayerPed, false) -- show your ped for everyone
    end)
end
--[[
local function runInstanceThread()
    if currentInstance then return end
    CreateThread(function()
        local localPlayerPed = PlayerPedId()
        NetworkSetEntityInvisibleToNetwork(localPlayerPed, true) -- hide your ped for everyone
        while currentInstance do
            localPlayerPed = PlayerPedId()
            SetLocalPlayerVisibleLocally(true)  -- show your ped for to yourself
            for instanceName, instancePlayers in pairs(instances) do
                for i = 1, #instancePlayers do
                    local player = GetPlayerFromServerId(instancePlayers[i])
                    if player and NetworkIsPlayerActive(player) then
                        local playerPed = GetPlayerPed(player)
                        if instanceName ~= currentInstance then
                            SetEntityNoCollisionEntity(playerPed, localPlayerPed, true)
                        else
                            -- SetEntityLocallyVisible(playerPed)
                            SetPlayerVisibleLocally(playerPed, true)
                        end
                    end
                end
            end
            Wait(0)
        end
        NetworkSetEntityInvisibleToNetwork(localPlayerPed, false) -- show your ped for everyone
    end)
end
]]

AddStateBagChangeHandler(Shared.State.playerInstance, ("player:%s"):format(playerServerId), function(bagName, _, value)
    local source = GetPlayerFromStateBagName(bagName)

    if not source or source == 0 or source ~= playerServerId then return end

    if not value then currentInstance = value return end

    runInstanceThread()
end)