<h1 align="center"><b>X-INSTANCE</b></h1>

<h3 align="center">Player & Vehicle Instance System for FiveM's OneSync Infinity</h3>

<h4 align="center">While it may be easier to achieve instancing through routing buckets, I wanted to create a more immersive player experience by replicating Rockstar's instance system in which players can see others, cars, and their environment when viewing through ipl properties windows. I have taken steps to ensure that the system is well optimized, and is fully compatible with OneSync Infinity.</h3>



<hr>

## Client Exports
```lua
---@param instanceName string
---@return boolean
exports["x-instance"]:doesInstanceExist(instanceName)


---@param instanceName string
---@param instanceHost number
---@return boolean
exports["x-instance"]:doesInstanceHostExist(instanceName, instanceHost)


---@param instanceName string
---@param hostSource? number
---@return xInstanceData | xInstances | table
exports["x-instance"]:getInstanceData(instanceName, hostSource)


---@param instanceName string
---@param hostSource number
---@return table<number, playerSource>
exports["x-instance"]:getInstancePlayers(instanceName, hostSource)


---@param source? number
---@return string | nil
exports["x-instance"]:getPlayerInstance(source)


---@param instanceName string
---@param hostSource number
---@return table<number, vehicleNetId>
exports["x-instance"]:getInstanceVehicles(instanceName, hostSource)


---@param vehicleNetId number
---@return string | nil
exports["x-instance"]:getVehicleInstance(vehicleNetId)
```

## Server Exports
```lua
---@param instanceName string
---@return boolean
exports["x-instance"]:doesInstanceExist(instanceName)


---@param instanceName string
---@param instanceHost number
---@return boolean
exports["x-instance"]:doesInstanceHostExist(instanceName, instanceHost)


---@param instanceName string
---@param hostSource? number
---@return xInstanceData | xInstances | table
exports["x-instance"]:getInstanceData(instanceName, hostSource)


---@param instanceName string
---@param hostSource number
---@return table<number, playerSource>
exports["x-instance"]:getInstancePlayers(instanceName, hostSource)


---@param source? number
---@return string | nil
exports["x-instance"]:getPlayerInstance(source)


---@param instanceName string
---@param hostSource number
---@return table<number, vehicleNetId>
exports["x-instance"]:getInstanceVehicles(instanceName, hostSource)


---@param vehicleNetId number
---@return string | nil
exports["x-instance"]:getVehicleInstance(vehicleNetId)


---@param instanceName string
---@return boolean, string
exports["x-instance"]:addInstanceType(instanceName)


---@param instanceName string
---@param forceRemove? boolean
---@return boolean, string
exports["x-instance"]:removeInstanceType(instanceName, forceRemove)


---@param source number
---@param instanceName string
---@param instanceHost? number
---@param forceAddPlayer? boolean
---@return boolean, string
exports["x-instance"]:addPlayerToInstance(source, instanceName, instanceHost, forceAddPlayer)


---@param source number
---@return boolean, string
exports["x-instance"]:removePlayerFromInstance(source)


---@param vehicleNetId number
---@param instanceName string
---@param instanceHost number
---@param forceAddVehicle? boolean
---@return boolean, string
exports["x-instance"]:addVehicleToInstance(vehicleNetId, instanceName, instanceHost, forceAddVehicle)


---@param vehicleNetId number
---@return boolean, string
exports["x-instance"]:removeVehicleFromInstance(vehicleNetId)
```
<hr>