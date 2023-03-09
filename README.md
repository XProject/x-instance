<h1 align="center"><b>X-INSTANCE</b></h1>

<h3 align="center">Instance System for FiveM's OneSync Infinity</h3>

<h4 align="center">I know it's easier to achieve this using routing buckets, but for more enhanced & realistic player experience(seeing other players & environment while looking through ipl properties windows), I decided to write an instance system like old ESX instance, while ensuring performance optimization and compatibility with OneSync Infinity</h3>



<hr>

## Client Exports
```lua
---@param instanceName string
---@return boolean
exports["x-instance"]:doesInstanceExist(instanceName)


---@param instanceName string
---@param hostSource? number
---@return table<number, playerSource> | table<hostSource, table<number, playerSource>> | nil
exports["x-instance"]:getInstancePlayers(instanceName, hostSource)


---@param source? number
---@return string | nil
exports["x-instance"]:getPlayerInstance(source)
```

## Server Exports
```lua
---@param instanceName string
---@return boolean
exports["x-instance"]:doesInstanceExist(instanceName)


---@param instanceName string
---@return boolean, string
exports["x-instance"]:addInstanceType(instanceName)


---@param instanceName string
---@param forceRemovePlayers? boolean
---@return boolean, string
exports["x-instance"]:removeInstanceType(instanceName, forceRemovePlayers)


---@param source number
---@param instanceName string
---@param instanceHost? number
---@param forceAddPlayer? boolean
---@return boolean, string
exports["x-instance"]:addToInstance(source, instanceName, forceAddPlayer)


---@param source number
---@param instanceName? string
---@return boolean, string
exports["x-instance"]:removeFromInstance(source, instanceName)


---@param instanceName string
---@param hostSource? number
---@return table<number, playerSource> | table<hostSource, table<number, playerSource>> | nil
exports["x-instance"]:getInstancePlayers(instanceName, hostSource)


---@param source number
---@return string | nil
exports["x-instance"]:getPlayerInstance(source)
```
<hr>


## TODO
- [x] Find a way to prevent instanced players from hearing each other(possibly through pma-voice export).
- [x] Find a way to disable pvp between instanced players that are not in a same instance.
- [x] Find a way to disable gun shots to be heard by instanced players.
- [x] Optimize it more than its current state.