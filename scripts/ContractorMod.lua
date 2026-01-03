source(Utils.getFilename("scripts/cmAIHotspot.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmEnterable.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmFSBaseMission.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmInGameMenuMapFrame.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmMission00.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmPlayer.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmPlayerInputComponent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmSavegameController.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmShopOthersFrame.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmVehicle.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/cmWardrobeScreen.lua", g_currentModDirectory))
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
    ContractorMod.currentID = 1
    ContractorMod.numWorkers = 2
    ContractorMod.workers = {}
    ContractorMod.shouldStopWorker = true
    ContractorMod.switching = false
    ContractorMod.displayPlayerNames = true
    ContractorMod.wageSettings = {}
    ContractorMod.wageSettings.defaultMonthlyWage = 0
    ContractorMod.wageSettings.hourlyWageFactor = 1.0
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onDayChanged, self)

    self:registerXmlSchema()

    local savegameDir
    if g_currentMission.missionInfo.savegameDirectory then
      savegameDir = g_currentMission.missionInfo.savegameDirectory
    end
    if not savegameDir and g_careerScreen.currentSavegame and g_careerScreen.currentSavegame.savegameIndex then
      savegameDir = ('%ssavegame%d'):format(getUserProfileAppPath(), g_careerScreen.currentSavegame.savegameIndex)
    end
    if not savegameDir and g_currentMission.missionInfo.savegameIndex ~= nil then
      savegameDir = ('%ssavegame%d'):format(getUserProfileAppPath(), g_careerScreen.missionInfo.savegameIndex)
    end
    ContractorMod.savegameFolderPath = savegameDir
    ContractorMod.ContractorModXmlFilePath = ContractorMod.savegameFolderPath .. '/ContractorMod.xml'

    -- Try to load from savegame, else create default workers
    if not self:initFromSave() then
        table.insert(ContractorMod.workers, ContractorModWorker:new("Alex", 1, g_localPlayer.graphicsComponent:getStyle()))
        local brendaStyle = g_helperManager:getRandomHelperStyle()
        while brendaStyle:getIsMale() do
            brendaStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("Brenda", 2, brendaStyle))
        table.insert(ContractorMod.workers, ContractorModWorker:new("Chris", 3, g_helperManager:getRandomHelperStyle()))
        local davidStyle = g_helperManager:getRandomHelperStyle()
        while davidStyle:getIsMale() == false do
            davidStyle = g_helperManager:getRandomHelperStyle()
        end
        table.insert(ContractorMod.workers, ContractorModWorker:new("David", 4, davidStyle))
        ContractorMod.numWorkers = #ContractorMod.workers
        ContractorMod.displaySettings = {
            characterName = {
                x = 0.9828,
                y = 0.90,
                size = 0.024
            }
        }
    end

    print(ContractorMod.wageSettings.hourlyWageFactor)
    for _, w in pairs(ContractorMod.workers) do
        print(w.name .. ": " .. w.wage)
    end

    self:extendWageFunctions()

    g_currentMission.nickname = ContractorMod.workers[ContractorMod.currentID].name
end

function ContractorMod:extendWageFunctions()
    for _, jt in g_currentMission.aiJobTypeManager.jobTypes do
        jt_class = jt.classObject
        jt_class.getPricePerMs = Utils.overwrittenFunction(jt_class.getPricePerMs, ContractorMod.getPricePerMs)
    end
end

function ContractorMod.getPricePerMs(self, superFunc, ...)
    return superFunc() * ContractorMod.wageSettings.hourlyWageFactor
end

function ContractorMod:onDayChanged()
    local farm = g_farmManager:getFarmById(1)
    for _, w in pairs(self.workers) do
        farm:changeBalance(-w.wage, MoneyType.AI)
        g_currentMission:addMoneyChange(-w.wage, 1, MoneyType.AI, true)
    end
end

function ContractorMod:initFromSave()
  if ContractorMod.debug then print("ContractorMod:initFromSave()") end
    -- Copy ContractorMod.xml from zip to modSettings dir
    ContractorMod:CopyContractorModXML()
    -- Minimal: load worker name, position, style from XML
    if ContractorMod.savegameFolderPath and ContractorMod.ContractorModXmlFilePath then
      createFolder(ContractorMod.savegameFolderPath)
      local xml
      if fileExists(ContractorMod.ContractorModXmlFilePath) then
        xml = XMLFile.load('ContractorMod', ContractorMod.ContractorModXmlFilePath, ContractorMod.xmlSchema)
      else
        xml = XMLFile.create('ContractorMod', ContractorMod.ContractorModXmlFilePath, 'ContractorMod', ContractorMod.xmlSchema)
        xml:save()
        xml:delete()
        return false
      end

      ContractorMod.wageSettings.defaultMonthlyWage = xml:getInt("ContractorMod.wageSettings.monthlyWage#default") or 0
      ContractorMod.wageSettings.hourlyWageFactor = xml:getFloat("ContractorMod.wageSettings.hourlyWage#factor") or 1.0

      print(ContractorMod.wageSettings.defaultMonthlyWage)
      print(ContractorMod.wageSettings.hourlyWageFactor)

      local num = xml:getInt("ContractorMod.workers#numWorkers") or 0
      for i = 1, num do
          local key = string.format("ContractorMod.workers.worker(%d)", i-1)
          if xml:getString(key.."#name") ~= nil then
            local name = xml:getString(key.."#name")
            local wage = xml:getFloat(key.."#wage") or ContractorMod.wageSettings.defaultMonthlyWage
            local pos = xml:getString(key.."#position")
            local rot = xml:getString(key.."#rotation")
            local style = PlayerStyle.new()
            style:loadFromXMLFile(xml, key..".style")
            local worker = ContractorModWorker:new(name, i, style)
            if ContractorMod.debug then print(pos) end
            local posVector = string.getVector(pos)
            if ContractorMod.debug then print("posVector "..tostring(posVector)) end
            local rotVector = string.getVector(rot)
            worker.wage = wage
            worker.x = posVector[1]
            worker.y = posVector[2]
            worker.z = posVector[3]
            worker.dx = rotVector[1]
            worker.dy = rotVector[2]
            worker.rotY = rotVector[2]
            worker.dz = rotVector[3]
            local vehicleID = xml:getString(key.."#vehicleID")
            if vehicleID ~= "0" then
              if ContractorMod.mapVehicleLoad ~= nil then
                -- map savegame vehicle id and network id
                local saveId = ContractorMod.mapVehicleLoad[vehicleID]
                local vehicle = NetworkUtil.getObject(tonumber(saveId))
                if vehicle ~= nil then
                  if ContractorMod.debug then print("ContractorMod: vehicle not nil") end
                  worker.currentVehicle = vehicle
                  local currentSeat = xml:getInt(key.."#currentSeat")
                  if currentSeat ~= nil then
                    worker.currentSeat = currentSeat
                  end
                end
              end
            end
            table.insert(ContractorMod.workers, worker)
          else
            local workerStyle = g_helperManager:getRandomHelperStyle()
            table.insert(ContractorMod.workers, ContractorModWorker:new("Worker" .. i, i, workerStyle))
          end
      end


    xmlKey = "ContractorMod.displaySettings.characterName"
    ContractorMod.displaySettings = {}
    ContractorMod.displaySettings.characterName = {}
    local x = xml:getFloat(xmlKey .. string.format("#x"))
    if x == nil then
      x = 0.9828
    end
    ContractorMod.displaySettings.characterName.x = x
    local y = xml:getFloat(xmlKey .. string.format("#y"))
    if y == nil then
      y = 0.90
    end
    ContractorMod.displaySettings.characterName.y = y
    local size = xml:getFloat(xmlKey .. string.format("#size"))
    if size == nil then
      size = 0.024
    end
    ContractorMod.displaySettings.characterName.size = size
    xmlKey = "ContractorMod.displaySettings.playerName"
    ContractorMod.displayPlayerNames = Utils.getNoNil(xml:getBool(xmlKey .. string.format("#displayPlayerNames")), true)
    ContractorMod.numWorkers = #ContractorMod.workers
    xml:delete()
    return ContractorMod.numWorkers > 0
  end
end

-- @doc Copy default parameters from mod mod zip file to mods directory so end-user can edit it
function ContractorMod:CopyContractorModXML()
  if ContractorMod.debug then print("ContractorMod:CopyContractorModXML") end
  if g_currentMission ~= nil and g_currentMission:getIsServer() then
    if ContractorMod.myCurrentModDirectory then
      local modSettingsDir = ContractorMod.myCurrentModDirectory .. "../../modSettings"
      local xmlFilePath = modSettingsDir.."/ContractorMod.xml"
      if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_1") end
      local xmlFile
      if not fileExists(xmlFilePath) then
        if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_2") end
        local xmlSourceFilePath = ContractorMod.myCurrentModDirectory .. "ContractorMod.xml"
        local xmlSourceFile
        if fileExists(xmlSourceFilePath) then
          if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_3") end
          xmlSourceFile = loadXMLFile('ContractorMod', xmlSourceFilePath)
          createFolder(modSettingsDir)
          saveXMLFileTo(xmlSourceFile, xmlFilePath)
          if ContractorMod.debug then print("ContractorMod:CopyContractorModXML_4") end
        end
      end
    end
  end
end

function ContractorMod:registerXmlSchema()
  if ContractorMod.debug then print("ContractorMod:registerXMLPaths ") end
  ContractorMod.xmlSchema = XMLSchema.new("ContractorMod")
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers#numWorkers", "Number of workers", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers.worker(?)#name", "Name of worker", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers.worker(?)#wage", "Monthly Wage of worker", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.workers.worker(?)#vehicleID", "ID of vehicle if any", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.wageSettings.monthlyWage#default", "Default Wage of new workers", nil, true)
  ContractorMod.xmlSchema:register(XMLValueType.STRING, "ContractorMod.wageSettings.hourlyWage#factor", "Factor Applied to hourly cost of all workers", nil, true)
  PlayerStyle.registerSavegameXMLPaths(ContractorMod.xmlSchema, "ContractorMod.workers.worker(?).style")
end

function ContractorMod:onSwitchWorker(action)
  if ContractorMod.debug then print("ContractorMod:onSwitchWorker()") end
  ContractorMod.switching = true
  if action == "SWITCH_VEHICLE" then
    if ContractorMod.debug then print('ContractorMod_NEXTWORKER pressed') end
    local nextID = 0
    if ContractorMod.debug then print("ContractorMod: ContractorMod.currentID " .. tostring(ContractorMod.currentID)) end
    if ContractorMod.debug then print("ContractorMod: ContractorMod.numWorkers " .. tostring(ContractorMod.numWorkers)) end
    if ContractorMod.currentID < ContractorMod.numWorkers then
      nextID = ContractorMod.currentID + 1
    else
      nextID = 1
    end
    if ContractorMod.debug then print("ContractorMod: nextID " .. tostring(nextID)) end
    self:setCurrentContractorModWorker(nextID)
  elseif action == "SWITCH_VEHICLE_BACK" then
    if ContractorMod.debug then print('ContractorMod_PREVWORKER pressed') end
    local prevID = 0
    if ContractorMod.currentID > 1 then
      prevID = ContractorMod.currentID - 1
    else
      prevID = ContractorMod.numWorkers
    end
    self:setCurrentContractorModWorker(prevID)
  end
end

-- @doc Switch directly to another worker
function ContractorMod:activateWorker(actionName, keyStatus)
	if ContractorMod.debug then print("ContractorMod:activateWorker") end
  if ContractorMod.debug then print("actionName "..tostring(actionName)) end
  if string.sub(actionName, 1, 20) == "ContractorMod_WORKER" then
    local workerIndex = tonumber(string.sub(actionName, -1))
    if ContractorMod.numWorkers >= workerIndex and workerIndex ~= ContractorMod.currentID then
      self:setCurrentContractorModWorker(workerIndex)
    end
  end
end

-- @doc Change active worker
function ContractorMod:setCurrentContractorModWorker(setID)
  if ContractorMod.debug then print("ContractorMod:setCurrentContractorModWorker(setID) " .. tostring(setID) .. " - " .. tostring(ContractorMod.currentID)) end
  local currentWorker = ContractorMod.workers[ContractorMod.currentID]
  if currentWorker ~= nil then
    ContractorMod.shouldStopWorker = false
    ContractorMod.switching = true
    currentWorker:beforeSwitch()
  end
  ContractorMod.currentID = setID
  currentWorker = ContractorMod.workers[ContractorMod.currentID]
  if currentWorker ~= nil then
    currentWorker:afterSwitch()
    ContractorMod.shouldStopWorker = true
    ContractorMod.switching = false
  end
  --DebugUtil.printTableRecursively(ContractorMod.workers, " ", 1, 3)
end

-- @doc Draw worker name and hotspots on map
function ContractorMod:draw()
  --if ContractorModWorker.debug then print("ContractorMod:draw()") end
  --Display current worker name
  if ContractorMod.workers ~= nil then
    if #ContractorMod.workers > 0 and g_currentMission.hud.isVisible then
      local currentWorker = ContractorMod.workers[ContractorMod.currentID]
      if currentWorker ~= nil then
        --Display current worker name
        currentWorker:displayName(self)
      end
    end
  end
end

addModEventListener(ContractorMod);