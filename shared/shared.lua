Shared = {}

Shared.currentResourceName = GetCurrentResourceName()

Shared.State = {}

Shared.State.globalInstances = ("%s_globalInstances"):format(Shared.currentResourceName)

Shared.State.playerInstance = ("%s_playerInstance"):format(Shared.currentResourceName)