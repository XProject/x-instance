local instances = {}

do
    for key in pairs(Config.Instances) do
        instances[key] = {}
    end
end

local function syncInstances()
    GlobalState:set(Shared.State.globalInstances, instances, true)
end

CreateThread(syncInstances)

local function doesInstanceExist(instanceName)
    return instances[instanceName] and true or false
end
exports("doesInstanceExist", doesInstanceExist)

local function addInstanceType(instanceName)
    if not instanceName then return false, "instance_not_valid" end

    if doesInstanceExist(instanceName) then return false, "instance_exists" end

    instances[instanceName] = {}

    syncInstances()

    return true, "successful"
end
exports("addInstanceType", addInstanceType)

local function removeInstanceType(instanceName)
    if not instanceName then return false, "instance_not_valid" end

    if not doesInstanceExist(instanceName) then return false, "instance_not_exist" end

    instances[instanceName] = nil

    syncInstances()

    return true, "successful"
end
exports("removeInstanceType", removeInstanceType)

local function addToInstance(source, instanceName)
    if not doesInstanceExist(instanceName) then return false, Player(source).state:set(Shared.State.playerInstance, nil, true) end

    table.insert(instances[instanceName], source)

    syncInstances()
end
exports("addToInstance", addToInstance)

AddStateBagChangeHandler(Shared.State.playerInstance, nil, function(bagName, _, value)
    local source = GetPlayerFromStateBagName(bagName)

    if not source or source == 0 or not value then return end

    addToInstance(source, value)
end)

RegisterCommand("addInstanceType", function(source, args)
    addInstanceType(args[1])
end, false)