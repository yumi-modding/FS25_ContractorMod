source(Utils.getFilename("scripts/ContractorModWorker.lua", g_currentModDirectory))

ContractorMod = {}
ContractorMod.debug = false --true --

-- Create multiple players and add them to the PlayerSystem
--local player1 = Player.new(...)
--local player2 = Player.new(...)
--g_playerSystem:addPlayer(player1)
--g_playerSystem:addPlayer(player2)


-- Switch control
-- g_playerSystem:setLocalPlayer(player2) -- Now you control player2

function ContractorMod:init()
  if ContractorMod.debug then print("ContractorMod:init()") end
    self.currentID = 1
    self.numWorkers = 2
    self.workers = {}
    ContractorMod.displayPlayerNames = true

    local savegameDir;
    if g_currentMission.missionInfo.savegameDirectory then
      savegameDir = g_currentMission.missionInfo.savegameDirectory;
    end;
    if not savegameDir and g_careerScreen.currentSavegame and g_careerScreen.currentSavegame.savegameIndex then
      savegameDir = ('%ssavegame%d'):format(getUserProfileAppPath(), g_careerScreen.currentSavegame.savegameIndex);
    end;
    if not savegameDir and g_currentMission.missionInfo.savegameIndex ~= nil then
      savegameDir = ('%ssavegame%d'):format(getUserProfileAppPath(), g_careerScreen.missionInfo.savegameIndex);
    end;
    self.savegameFolderPath = savegameDir;
    self.ContractorModXmlFilePath = self.savegameFolderPath .. '/ContractorMod.xml';

    -- Try to load from savegame, else create default workers
    if not self:initFromSave() then
        table.insert(self.workers, ContractorModWorker:new("Alex", 1, g_helperManager:getRandomHelperStyle()))
        table.insert(self.workers, ContractorModWorker:new("Brenda", 2, g_helperManager:getRandomHelperStyle()))
        table.insert(self.workers, ContractorModWorker:new("Chris", 3, g_helperManager:getRandomHelperStyle()))
        table.insert(self.workers, ContractorModWorker:new("David", 4, g_helperManager:getRandomHelperStyle()))
        self.numWorkers = #self.workers
        self.displaySettings = {}
        self.displaySettings.characterName = {}
        self.displaySettings.characterName.x = 0.9828
        self.displaySettings.characterName.y = 0.90
        self.displaySettings.characterName.size = 0.024
    end
end

function ContractorMod:initFromSave()
  if ContractorMod.debug then print("ContractorMod:initFromSave()") end
    -- Minimal: load worker name, position, style from XML
    local savePath = g_currentMission.missionInfo.savegameDirectory .. "/ContractorMod.xml"
    if not fileExists(savePath) then return false end
    local xml = XMLFile.load("ContractorMod", savePath)
    local num = xml:getInt("ContractorMod.workers#numWorkers") or 0
    for i = 1, num do
        local key = string.format("ContractorMod.workers.worker(%d)", i-1)
        local name = xml:getString(key.."#name")
        local pos = xml:getString(key.."#position")
        local rot = xml:getString(key.."#rotation")
        local style = PlayerStyle.new()
        -- style:loadFromXMLFile(xml, key..".style")
        local worker = ContractorModWorker:new(name, i, style)
        if ContractorMod.debug then print(pos) end
        local posVector = string.getVector(pos);
        if ContractorMod.debug then print("posVector "..tostring(posVector)) end
        local rotVector = string.getVector(rot);
        worker.x = posVector[1]
        worker.y = posVector[2]
        worker.z = posVector[3]
        worker.dx = rotVector[1]
        worker.dy = rotVector[2]
        worker.rotY = rotVector[2]
        worker.dz = rotVector[3]
        local vehicleID = xml:getString(key.."#vehicleID");
        if vehicleID ~= "0" then
          if ContractorMod.mapVehicleLoad ~= nil then
            -- map savegame vehicle id and network id
            local saveId = ContractorMod.mapVehicleLoad[vehicleID]
            local vehicle = NetworkUtil.getObject(tonumber(saveId))
            if vehicle ~= nil then
              if ContractorMod.debug then print("ContractorMod: vehicle not nil") end
              worker.currentVehicle = vehicle
              local currentSeat = xml:getInt(key.."#currentSeat");
              if currentSeat ~= nil then
                worker.currentSeat = currentSeat
              end
            end
          end
        end
        table.insert(self.workers, worker)
    end
    xmlKey = "ContractorMod.displaySettings.characterName"
    self.displaySettings = {}
    self.displaySettings.characterName = {}
    local x = xml:getFloat(xmlKey .. string.format("#x"));
    if x == nil then
      x = 0.9828
    end
    self.displaySettings.characterName.x = x
    local y = xml:getFloat(xmlKey .. string.format("#y"));
    if y == nil then
      y = 0.90
    end
    self.displaySettings.characterName.y = y
    local size = xml:getFloat(xmlKey .. string.format("#size"));
    if size == nil then
      size = 0.024
    end
    self.displaySettings.characterName.size = size
    xmlKey = "ContractorMod.displaySettings.playerName"
    ContractorMod.displayPlayerNames = Utils.getNoNil(xml:getBool(xmlKey .. string.format("#displayPlayerNames")), true);
    self.numWorkers = #self.workers
    xml:delete()
    return self.numWorkers > 0
end

-- @doc Will call dedicated save method
SavegameController.onSaveComplete = Utils.prependedFunction(SavegameController.onSaveComplete, function(self)
    -- if self.isValid and self.xmlKey ~= nil then
    ContractorMod:onSaveCareerSavegame()
    -- end
end);

-- @doc store savegame vehicle id if worker is in this vehicle
function ContractorMod:mapVehicleSave(vehicle, saveId)
  if ContractorMod.debug then print("ContractorMod:mapVehicleSave ") end
  if self.workers ~= nil then
    if #self.workers > 0 then
      for i = 1, self.numWorkers do
        local worker = self.workers[i]
        if worker ~= nil and worker.currentVehicle ~= nil then
          if vehicle == worker.currentVehicle then
            -- store savegame vehicle id 
            worker.saveId = saveId
          end
        end
      end
    end
  end
end

-- @doc Set mapping between savegame vehicle id and vehicle network id when vehicle is saved
function ContractorMod:preVehicleSave(xmlFile, key, usedModNames)
  if ContractorMod.debug then print("ContractorMod:preVehicleSave ") end
  -- key is something like vehicles.vehicle(saveId)
  local saveId = 1 + tonumber(string.sub(key, string.find(key, '(', 1, true) + 1, string.find(key, ')', 1, true) - 1))
  if SpecializationUtil.hasSpecialization(Enterable, self.specializations) then
    ContractorMod:mapVehicleSave(self, tostring(saveId))
  end
end
Vehicle.saveToXMLFile = Utils.prependedFunction(Vehicle.saveToXMLFile, ContractorMod.preVehicleSave);

-- @doc Save workers info to restore them when starting game
function ContractorMod:onSaveCareerSavegame()
  if ContractorMod.debug then print("ContractorMod:onSaveCareerSavegame ") end
  if self.workers ~= nil then
    local xmlFile;
    if fileExists(self.ContractorModXmlFilePath) then
      xmlFile = XMLFile.load('ContractorMod', self.ContractorModXmlFilePath);
    else
      xmlFile = XMLFile.create('ContractorMod', self.ContractorModXmlFilePath, 'ContractorMod');
      xmlFile:save()
    end;

    if xmlFile ~= nil then
      local rootXmlKey = "ContractorMod"

      -- update current worker position
      local currentWorker = self.workers[self.currentID]
      if currentWorker ~= nil then
        currentWorker:beforeSwitch(true)
      end
      
      local workerKey = rootXmlKey .. ".workers"
      xmlFile:setInt(workerKey.."#numWorkers", self.numWorkers);
      for i = 1, self.numWorkers do
        local worker = self.workers[i]
        local key = string.format(rootXmlKey .. ".workers.worker(%d)", i - 1);
        xmlFile:setString(key.."#name", worker.name);
        local pos = Utils.getNoNil(worker.x, "0.")..' '..Utils.getNoNil(worker.y, "0.")..' '..Utils.getNoNil(worker.z, "0.")
        xmlFile:setString(key.."#position", pos);
        local rot = Utils.getNoNil(worker.dx, "0.")..' '..Utils.getNoNil(worker.dy, "0.")..' '..Utils.getNoNil(worker.dz, "0.")
        xmlFile:setString(key.."#rotation", rot);
        local vehicleID = "0"
        if worker.currentVehicle ~= nil then
          vehicleID = worker.saveId
        end
        xmlFile:setString(key.."#vehicleID", vehicleID);
      end
      -- currentWorker.player:moveToAbsoluteInternal(0, -200, 0);
      local xmlKey = rootXmlKey .. ".displaySettings.characterName"
      xmlFile:setFloat(xmlKey .. "#x", self.displaySettings.characterName.x);
      xmlFile:setFloat(xmlKey .. "#y", self.displaySettings.characterName.y);
      xmlFile:setFloat(xmlKey .. "#size", self.displaySettings.characterName.size);
      xmlKey = rootXmlKey .. ".displaySettings.playerName"
      xmlFile:setBool(xmlKey .. "#displayPlayerNames", ContractorMod.displayPlayerNames);
      xmlFile:save()
      xmlFile:delete()
    end
  end
end

function ContractorMod:saveToXML()
  if ContractorMod.debug then print("ContractorMod:saveToXML()") end
    local savePath = g_currentMission.missionInfo.savegameDirectory .. "/ContractorMod.xml"
    local xml = XMLFile.create("ContractorMod", savePath, "ContractorMod")
    xml:setInt("ContractorMod.workers#numWorkers", self.numWorkers)
    for i, worker in ipairs(self.workers) do
        local key = string.format("ContractorMod.workers.worker(%d)", i-1)
        xml:setString(key.."#name", worker.name)
        xml:setString(key.."#position", string.format("%f %f %f", worker.x, worker.y, worker.z))
        xml:setString(key.."#rotation", string.format("%f %f", worker.rotX, worker.rotY))
        -- worker.playerStyle:saveToXMLFile(xml, key..".style")
    end
    xml:save()
    xml:delete()
end
-- GameSettings.saveToXMLFile = Utils.prependedFunction(GameSettings.saveToXMLFile, ContractorMod.saveToXML)

-- @doc Set mapping between savegame vehicle id and vehicle network id when vehicle is loaded
ContractorMod.appEnterableOnLoad = function(self, savegame)
  if ContractorMod.debug then print("ContractorMod:appEnterableOnLoad ") end
  if savegame ~= nil then
    -- When loading savegame
    if ContractorMod.mapVehicleLoad == nil then
      ContractorMod.mapVehicleLoad = {}
    end
    local key = savegame.key
    -- key is something like vehicles.vehicle(saveId)
    local saveId = 1 + tonumber(string.sub(key, string.find(key, '(', 1, true) + 1, string.find(key, ')', 1, true) - 1))
    local vehicleID = self.id
    -- Set mapping between savegame vehicle id and vehicle network id once loaded
    ContractorMod.mapVehicleLoad[tostring(saveId)] = vehicleID
    -- DebugUtil.printTableRecursively(ContractorMod.mapVehicleLoad, " ", 1, 2);
  end
end
Enterable.onLoad = Utils.appendedFunction(Enterable.onLoad, ContractorMod.appEnterableOnLoad)


-- @doc Prevent from removing driver character
function ContractorMod:replaceGetDisableVehicleCharacterOnLeave(superfunc)
  if ContractorMod.debug then print("ContractorMod:replaceGetDisableVehicleCharacterOnLeave ") end
  if ContractorMod.switching then
    ContractorMod.switching = false
    if ContractorMod.debug then print("switching return false") end
    return false
  end
  if ContractorMod.passengerLeaving then
    ContractorMod.passengerLeaving = false
    if ContractorMod.debug then print("passengerLeaving return false") end
    return false
  end
  return true
end
Enterable.getDisableVehicleCharacterOnLeave = Utils.overwrittenFunction(Enterable.getDisableVehicleCharacterOnLeave, ContractorMod.replaceGetDisableVehicleCharacterOnLeave);

function ContractorMod:switchWorker(newID)
  if ContractorMod.debug then print("ContractorMod:switchWorker() " + string(newID)) end
    if newID == self.currentID or newID < 1 or newID > self.numWorkers then return end
    self.workers[self.currentID]:beforeSwitch()
    self.currentID = newID
    self.workers[self.currentID]:afterSwitch()
end

-- Hook into game events as needed (e.g., onStartMission, onSaveGame)
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


function ContractorMod:onSwitchVehicle(action)
  if ContractorMod.debug then print("ContractorMod:onSwitchVehicle()") end
  self.switching = true
  if action == "SWITCH_VEHICLE" then
    if ContractorMod.debug then print('ContractorMod_NEXTWORKER pressed') end
    local nextID = 0
    if ContractorMod.debug then print("ContractorMod: self.currentID " .. tostring(self.currentID)) end
    if ContractorMod.debug then print("ContractorMod: self.numWorkers " .. tostring(self.numWorkers)) end
    if self.currentID < self.numWorkers then
      nextID = self.currentID + 1
    else
      nextID = 1
    end
    if ContractorMod.debug then print("ContractorMod: nextID " .. tostring(nextID)) end
    self:setCurrentContractorModWorker(nextID)
  elseif action == "SWITCH_VEHICLE_BACK" then
    if ContractorMod.debug then print('ContractorMod_PREVWORKER pressed') end
    local prevID = 0
    if self.currentID > 1 then
      prevID = self.currentID - 1
    else
      prevID = self.numWorkers
    end    
    self:setCurrentContractorModWorker(prevID)
  end
end

-- @doc Change active worker
function ContractorMod:setCurrentContractorModWorker(setID)
  if ContractorMod.debug then print("ContractorMod:setCurrentContractorModWorker(setID) " .. tostring(setID) .. " - " .. tostring(self.currentID)) end
  local currentWorker = self.workers[self.currentID]
  if currentWorker ~= nil then
    self.shouldStopWorker = false
    self.switching = true
    currentWorker:beforeSwitch()
  end
  self.currentID = setID
  currentWorker = self.workers[self.currentID]
  if currentWorker ~= nil then
    currentWorker:afterSwitch()
    self.shouldStopWorker = true
    self.switching = false
  end
  --DebugUtil.printTableRecursively(self.workers, " ", 1, 3)
end

-- @doc Replace switch vehicle by switch worker
function ContractorMod:replaceOnSwitchVehicle(superfunc, action, direction)
  ContractorMod:onSwitchVehicle(action)
end
PlayerInputComponent.onInputSwitchVehicle = Utils.overwrittenFunction(PlayerInputComponent.onInputSwitchVehicle, ContractorMod.replaceOnSwitchVehicle);

function ContractorMod:preventOnSwitchVehicle(superfunc, value, direction)
  if ContractorMod.debug then print("ContractorMod:preventOnSwitchVehicle()") end
  print("We might prevent to switch vehicle from the map menu")
  superfunc(self, value, direction)
end
InGameMenuMapFrame.onSwitchVehicle = Utils.overwrittenFunction(InGameMenuMapFrame.onSwitchVehicle, ContractorMod.preventOnSwitchVehicle);

function ContractorMod:loadedMission() --[[----------------------------------------------------------------]] print("This is a development version of ContractorMod for FS25, which may and will contain errors, bugs.") end
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, ContractorMod.loadedMission)

-- @doc Draw worker name and hotspots on map
function ContractorMod:draw()
  --if ContractorModWorker.debug then print("ContractorMod:draw()") end
  --Display current worker name
  if self.workers ~= nil then
    if #self.workers > 0 and g_currentMission.hud.isVisible then
      local currentWorker = self.workers[self.currentID]
      if currentWorker ~= nil then
        --Display current worker name
        currentWorker:displayName(self)
      end
    end
  end
end

addModEventListener(ContractorMod);
