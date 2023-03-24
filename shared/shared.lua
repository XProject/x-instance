Shared = {}

Shared.currentResourceName = GetCurrentResourceName()

Shared.State = {}

Shared.State.globalInstances = ("%s_globalInstances"):format(Shared.currentResourceName)

Shared.State.globalInstancedPlayers = ("%s_globalInstancedPlayers"):format(Shared.currentResourceName)

Shared.State.globalInstancedVehicles = ("%s_globalInstancedVehicles"):format(Shared.currentResourceName)

Shared.State.playerInstance = ("%s_playerInstance"):format(Shared.currentResourceName)

Shared.State.vehicleInstance = ("%s_vehicleInstance"):format(Shared.currentResourceName)

Shared.Event = {}

Shared.Event.playerEnteredScope = ("%s:playerEnteredScope"):format(Shared.currentResourceName)

---@alias playerSource number
---@alias instanceName string
---@alias hostSource playerSource
---@alias vehicleNetId number

---@class xInstanceData
---@field players playerSource[]
---@field vehicles vehicleNetId[]

---@class xInstances
---@field [instanceName] table<hostSource, xInstanceData[]>

---@class xInstancedPlayer
---@field instance instanceName
---@field host hostSource

---@class xInstancedPlayers
---@field [playerSource] xInstancedPlayer

---@class xInstancedVehicle
---@field instance instanceName
---@field host hostSource

---@class xInstancedVehicles
---@field [vehicleNetId] xInstancedVehicle

function dumpTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = '{\n'
        for k, v in pairs(table) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '[' .. k .. '] = ' .. dumpTable(v, nb + 1) .. ',\n'
        end

        for i = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. '}'
    else
        return tostring(table)
    end
end
