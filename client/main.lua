local instances = GlobalState[Shared.State.globalInstances]
local currentInstance = nil
local playerId = PlayerId()
local playerServerId = GetPlayerServerId(playerId)
local isThreadRunning = false

local function runInstanceThread()
    if isThreadRunning or not currentInstance then return end

    isThreadRunning = true

    CreateThread(function()
        local localPlayerPed = PlayerPedId()
        NetworkSetEntityInvisibleToNetwork(localPlayerPed, true) -- hide your ped from everyone

        while isThreadRunning and currentInstance do
            localPlayerPed = PlayerPedId()

            SetLocalPlayerVisibleLocally(true)  -- show your ped to yourself

            for instanceName, instancePlayers in pairs(instances) do
                if instanceName ~= currentInstance then
                    for i = 1, #instancePlayers do
                        local player = GetPlayerFromServerId(instancePlayers[i])

                        if player and NetworkIsPlayerActive(player) then
                            local playerPed = GetPlayerPed(player)
                            SetEntityNoCollisionEntity(playerPed, localPlayerPed, true) -- disable collision with other hidden peds who are NOT in a same instance as you
                        end
                    end
                else
                    for i = 1, #instancePlayers do
                        local player = GetPlayerFromServerId(instancePlayers[i])

                        if player and NetworkIsPlayerActive(player) then
                            local playerPed = GetPlayerPed(player)
                            SetEntityLocallyVisible(playerPed) -- show hidden peds to you if you are in a same instance
                            -- SetPlayerVisibleLocally(playerPed, true) -- show hidden peds to you if you are in a same instance
                        end
                    end
                end
            end

            Wait(0)
        end

        NetworkSetEntityInvisibleToNetwork(localPlayerPed, false) -- show your ped to everyone
        isThreadRunning = false
    end)
end

---@param instanceName string
---@return boolean, string
local function enterInstance(instanceName)
    if not instanceName then return false, "instance_not_valid" end

    if not instances[instanceName] then return false, "instance_not_exist" end

    LocalPlayer.state:set(Shared.State.playerInstance, instanceName, true)

    return true, "successful"
end
exports("enterInstance", enterInstance)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.globalInstances, nil, function(_, _, value)
    instances = value
    
    runInstanceThread()
end)

AddStateBagChangeHandler(Shared.State.playerInstance, ("player:%s"):format(playerServerId), function(bagName, _, value)
    local playerHandler = GetPlayerFromStateBagName(bagName)
    local source = tonumber(bagName:gsub("player:", ""), 10)
    if not playerHandler or playerHandler == 0 or source ~= playerServerId then return end

    currentInstance = value
end)