-- Manage first worker when loading savegame
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, function()
    ContractorMod:init()
    DebugUtil.printTableRecursively(ContractorMod.workers, " ", 1, 2) 
    local firstWorker = ContractorMod.workers[1]
    if g_localPlayer and g_localPlayer ~= nil then
      g_localPlayer:teleportTo(firstWorker.x, firstWorker.y, firstWorker.z)
      if firstWorker.currentVehicle ~= nil then
        g_localPlayer:setSpawnVehicle(firstWorker.currentVehicle)
      end
    end
end)

-- Display a warning message in the log when loading savegame
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function()
    print("This is a development version of ContractorMod for FS25, which may and will contain errors, bugs.")
end)