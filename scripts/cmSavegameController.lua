
-- @doc Will call dedicated save method
SavegameController.onSaveComplete = Utils.prependedFunction(SavegameController.onSaveComplete, function(self)
  if ContractorMod.debug then print("cmSavegameController:pre_onSaveComplete") end
  if ContractorMod.workers ~= nil then
    local xmlFile
    if fileExists(ContractorMod.ContractorModXmlFilePath) then
      xmlFile = XMLFile.load('ContractorMod', ContractorMod.ContractorModXmlFilePath, ContractorMod.xmlSchema)
    else
      xmlFile = XMLFile.create('ContractorMod', ContractorMod.ContractorModXmlFilePath, 'ContractorMod', ContractorMod.xmlSchema)
      xmlFile:save()
    end

    if xmlFile ~= nil then
      local rootXmlKey = "ContractorMod"

      -- update current worker position
      local currentWorker = ContractorMod.workers[ContractorMod.currentID]
      if currentWorker ~= nil then
        currentWorker:beforeSwitch(true)
      end
      
      local workerKey = rootXmlKey .. ".workers"
      xmlFile:setInt(workerKey.."#numWorkers", ContractorMod.numWorkers)
      for i = 1, ContractorMod.numWorkers do
        local worker = ContractorMod.workers[i]
        local key = string.format(rootXmlKey .. ".workers.worker(%d)", i - 1)
        xmlFile:setString(key.."#name", worker.name)
        worker.playerStyle:saveToXMLFile(xmlFile, key .. ".style")
        local pos = Utils.getNoNil(worker.x, "0.")..' '..Utils.getNoNil(worker.y, "0.")..' '..Utils.getNoNil(worker.z, "0.")
        xmlFile:setString(key.."#position", pos)
        local rot = Utils.getNoNil(worker.dx, "0.")..' '..Utils.getNoNil(worker.dy, "0.")..' '..Utils.getNoNil(worker.dz, "0.")
        xmlFile:setString(key.."#rotation", rot)
        local vehicleID = "0"
        if worker.currentVehicle ~= nil then
          vehicleID = worker.saveId
        end
        xmlFile:setString(key.."#vehicleID", Utils.getNoNil(vehicleID, "0"))
      end
      -- currentWorker.player:moveToAbsoluteInternal(0, -200, 0)
      local xmlKey = rootXmlKey .. ".displaySettings.characterName"
      xmlFile:setFloat(xmlKey .. "#x", ContractorMod.displaySettings.characterName.x)
      xmlFile:setFloat(xmlKey .. "#y", ContractorMod.displaySettings.characterName.y)
      xmlFile:setFloat(xmlKey .. "#size", ContractorMod.displaySettings.characterName.size)
      xmlKey = rootXmlKey .. ".displaySettings.playerName"
      xmlFile:setBool(xmlKey .. "#displayPlayerNames", ContractorMod.displayPlayerNames)
      xmlFile:save()
      xmlFile:delete()
    end
  end
end)
