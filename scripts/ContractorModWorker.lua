--
-- ContractorMod
-- Specialization for storing each character data
-- No event plugged, only called when interacting with ContractorMod
--
-- @author  yumi
-- free for noncommercial-usage
--

ContractorModWorker = {};
ContractorModWorker_mt = Class(ContractorModWorker);

ContractorModWorker.debug = false --true --

function ContractorModWorker:new(name, index, workerStyle)
  if ContractorModWorker.debug then print("ContractorModWorker:new()") end
  local self = {};
  setmetatable(self, ContractorModWorker_mt);

  self.name = name
  self.index = index
  self.currentVehicle = nil
  self.yaw = 0.0
  self.playerStyle = PlayerStyle.new()
  self.playerStyle:copyFrom(workerStyle)
  self.npc = g_npcManager:getNPCByName("HELPER" .. index)
  self.npc.playerGraphics:setIsFacialAnimationEnabled(false)
  self.npc.playerGraphics:setStyleAsync(workerStyle, self.npc.loadCharacterFinished, self.npc, {})
  self.npc.title = name
  self.npc.mapHotspot.icon:setColor(unpack(Farm.COLORS[index]))
  self.npc.mapHotspot.iconSmall:setColor(unpack(Farm.COLORS[index]))
  if workerStyle:getIsMale() then
    -- self.npc.mapHotspot.icon:setImageFilename(Utils.getFilename("images/maleHelper.png", g_currentModDirectory))
    self.npc.imageFilename = g_npcManager:getNPCByName("HELPER").imageFilename
  else
    -- self.npc.mapHotspot.icon:setImageFilename(Utils.getFilename("images/femaleHelper.png", g_currentModDirectory))
    self.npc.imageFilename = g_npcManager:getNPCByName("ANIMAL_DEALER").imageFilename
  end

  -- self.npc.isActive = true
  -- DebugUtil.printTableRecursively(self.npc, " ", 1, 1)

  self.color = Farm.COLORS[index]
  if g_localPlayer ~= nil then
    self.x, self.y, self.z, self.rotY = g_localPlayer:getPosition()
    self.x = self.x + (1 * index)
    self.yaw = g_localPlayer:getGraphicalYaw()
  end
  self.display_x, self.display_y, self.display_z = 0, 0, 0
  return self
end


function ContractorModWorker:displayName(contractorMod)
  --if ContractorModWorker.debug then print("ContractorModWorker:displayName()") end
  if self.name == "PLAYER" then return end
  setTextBold(true);
  setTextAlignment(RenderText.ALIGN_RIGHT);
  
  setTextColor(self.color[1], self.color[2], self.color[3], 1.0);
  local x = 0.9828
  local y = 0.45
  local size = 0.024
  if contractorMod.displaySettings ~= nil and contractorMod.displaySettings.characterName ~= nil then
    x = contractorMod.displaySettings.characterName.x
    y = contractorMod.displaySettings.characterName.y
    size = contractorMod.displaySettings.characterName.size
  end
  renderText(x, y, size, self.name);
  
  if ContractorModWorker.debug then
    if self.currentVehicle ~= nil then
      local vehicleName = ""
      if self.currentVehicle ~= nil then
        vehicleName = self.currentVehicle:getFullName()
      end
      renderText(0.9828, 0.43, 0.012, vehicleName);
      renderText(0.9828, 0.42, 0.012, "seat:" .. tostring(self.currentSeat) );
    end
    renderText(0.9828, 0.41, 0.012, self.name);
    renderText(0.9828, 0.40, 0.012, "x:" .. tostring(self.display_x) .. " y:" .. tostring(self.display_y) .. " z:" .. tostring(self.display_z));
    renderText(0.9828, 0.39, 0.012, "yaw:" .. tostring(self.yaw));
    -- renderText(0.9828, 0.37, 0.012, "graphicsRotY:" .. tostring(self.player.graphicsRotY));
    -- renderText(0.9828, 0.36, 0.012, "targetGraphicsRotY:" .. tostring(self.player.targetGraphicsRotY));
    renderText(0.9828, 0.35, 0.012, "shouldStopWorker:  " .. tostring(contractorMod.shouldStopWorker));
    renderText(0.9828, 0.33, 0.012, "switching:         " .. tostring(contractorMod.switching));
    renderText(0.9828, 0.31, 0.012, "passengerLeaving:  " .. tostring(contractorMod.passengerLeaving));
    renderText(0.9828, 0.29, 0.012, "passengerEntering: " .. tostring(contractorMod.passengerEntering));
  end
  -- Restore default alignment (to avoid impacting other mods like FarmingTablet)
  setTextAlignment(RenderText.ALIGN_LEFT);
end

-- @doc Capture worker position before switching to another one
function ContractorModWorker:beforeSwitch(noEventSend)
  if ContractorModWorker.debug then print("ContractorModWorker:beforeSwitch()") end
  self.currentVehicle = g_localPlayer:getCurrentVehicle()

  if self.currentVehicle == nil then
    -- Old passenger condition
    local passengerHoldingVehicle = g_currentMission.passengerHoldingVehicle;
    if passengerHoldingVehicle ~= nil then
      -- source worker is passenger in a vehicle
    else
      -- source worker is not in a vehicle
      local x, y, z = g_localPlayer:getPosition()
      local distance = MathUtil.vector3Length(self.x - x, self.y - y, self.z - z)
      -- print("ContractorModWorker: beforeSwitch distance "..tostring(distance))
      self.x, self.y, self.z, self.rotY = g_localPlayer:getPosition()
      self.yaw = g_localPlayer:getGraphicalYaw()
      if ContractorModWorker.debug then print(string.format("ContractorModWorker:beforeSwitch not in vehicle %d,%d,%d | %d", self.x, self.y, self.z, self.yaw)) end
      -- self.rotX = g_localPlayer.rotX;
      -- self.rotY = g_localPlayer.rotY;
-- self.player.isEntered = false
-- self.player:setStyleAsync(self.playerStyle, nil, noEventSend)
-- -- self.playerStyle:print()
-- if noEventSend == nil or noEventSend == false then
--   -- print("set visible 1: "..self.name)
--   self.player:setVisibility(true)
-- end
      -- if ContractorModWorker.debug then print("ContractorModWorker: moveTo "..tostring(self.player.model.style.playerName)); end

      -- local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.x, 300, self.z)
      -- self.y = math.max(terrainHeight + 0.1, self.y + 0.9)
    
      -- self.player:moveRootNodeToAbsolute(self.x, self.y, self.z)
-- self.player:moveTo(self.x, self.y-0.8, self.z, true, true)
      -- g_localPlayer:teleportTo(self.x, self.y, self.z)

      -- DebugUtil.printTableRecursively(self, " ", 1, 1)
      -- npc = g_npcManager:getNPCByName("HELPER" ..self.index)
      local spot = NPCSpot.create(tostring(g_time), self.npc, self.x, self.y, self.z, 0, 0, 0, false) --g_npcManager:getAvailableSpot(npc)
      spot:activate()
      spot.isAvailable = true
      -- spot.needsSaving = true
      g_npcManager:addSpot(spot)
      
      self.npc:setSpot(spot)
      self:setYawInstant(g_localPlayer:getGraphicalYaw())
-- self.npc.x = self.x
-- self.npc.y = self.y
-- self.npc.z = self.z
-- self.npc:raiseActive()
-- self.npc.needPositionUpdate = true
-- DebugUtil.printTableRecursively(self.npc, " ", 1, 1)
      -- local x, y, z = getWorldTranslation(spawnPoint)
      -- local dx, _, dz = localDirectionToWorld(spawnPoint, 0, 0, -1)
      -- local dx, _, dz = localDirectionToWorld(g_currentMission.player.rootNode, 0, 0, -1)
      -- local ry = MathUtil.getYRotationFromDirection(dx, dz)
      -- local y = math.max(self.y, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.x, 0, self.z) + 0.2)

      -- self.player:moveTo(self.x, y, self.z, true, true)
      -- self.player:setRotation(0, ry)
      --[[
      self.player.baseInformation.isOnGround = true
      self.player:moveToAbsoluteInternal(self.x, self.y, self.z)
    
      local dx, _, dz = localDirectionToWorld(g_currentMission.player.rootNode, 0, 0, -1)  --]]
      -- self.rotY = MathUtil.getYRotationFromDirection(dx, dz)
    
      -- setRotation(self.player.graphicsRootNode, 0, self.rotY + math.rad(180.0), 0)
      -- setRotation(self.player.cameraNode, self.rotX, self.rotY, 0)
    end
  else
    -- source worker is in a vehicle
    self.x, self.y, self.z = getWorldTranslation(self.currentVehicle.rootNode)
    self.y = self.y + 2 --to avoid being under the ground
    local dx, _, dz = localDirectionToWorld(self.currentVehicle.rootNode, 0, 0, 1)
    self.yaw = MathUtil.getYRotationFromDirection(dx, dz) or 0.0

    if noEventSend == nil or noEventSend == false then
      if ContractorModWorker.debug then print(string.format("ContractorModWorker: sendEvent(onLeaveVehicle %d, %d, %d", self.x, self.y, self.z)) end
      g_localPlayer:leaveVehicle()
    end
  end
end

-- @doc Teleport to target worker when switching
function ContractorModWorker:afterSwitch(noEventSend)
  if ContractorModWorker.debug then print("ContractorModWorker:afterSwitch()") end
  g_localPlayer:setStyleAsync(self.playerStyle, false, nil, true)
  g_currentMission.playerNickname = self.name
  g_localPlayer.playerHotspot:setColor(unpack(self.color))
  if self.currentVehicle == nil then
    -- target worker is not in a vehicle
    if g_localPlayer ~= nil then --g_currentMission.controlPlayer and 
      -- if ContractorModWorker.debug then print("ContractorModWorker: moveTo "..tostring(g_localPlayer.model.style.playerName)); end
      -- setTranslation(g_currentMission.player.rootNode, self.x, self.y, self.z);
      -- g_currentMission.player:moveRootNodeToAbsolute(self.x, self.y-0.2, self.z);
      local spot = self.npc:getSpot()
      self.npc:setSpot(nil)                     -- unset its spot
      g_npcManager:removeSpot(spot)        -- optionally remove that spot entirely
      g_currentMission.activatableObjectsSystem:removeActivatable(self.npc.activatable)
      -- optionally delete or unregister the npc if needed
      -- npc = g_npcManager:getNPCByName("HELPER" .. self.index)
      self.npc.x = 0
      self.npc.y = -200
      self.npc.z = 0
      self.npc.isActive = false  -- NPCManager.lua:250: attempt to index nil with 'getIsAvailable'
      self.npc:updateVisibility()
      -- self.npc:updatePosition()
      -- self.npc:raiseActive()
      -- self.npc.needPositionUpdate = true
      -- DebugUtil.printTableRecursively(self, " ", 1, 1)
      -- g_localPlayer:setRotation(self.rotX, self.rotY)
      -- self.player.isEntered = true
      -- self.player.isControlled = true
      -- self.player:moveToAbsoluteInternal(0, -200, 0); -- to avoid having player at the same location than current player
      if ContractorModWorker.debug then print("ContractorModWorker: set visible 0: "..self.name); end
      -- TODO --self.player:setVisibility(false)
      if ContractorModWorker.debug then
        print("ContractorModWorker: setStyleAsync ");
        -- DebugUtil.printTableRecursively(self.playerStyle, " ", 1, 3)
      end
      g_localPlayer:teleportTo(self.x, self.y, self.z, true, true)
      g_localPlayer.mover:setMovementYaw(self.yaw)
      -- g_localPlayer:setStyleAsync(self.playerStyle, nil, false)
    end

  else
    -- if self.isPassenger then
      -- target worker is passenger
    -- else
      -- target worker is in a vehicle
      if noEventSend == nil or noEventSend == false then
        if ContractorModWorker.debug then print("ContractorModWorker: sendEvent(VehicleEnterRequestEvent:" ) end
        -- g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent.new(self.currentVehicle, self.playerStyle, self.farmId));
        g_localPlayer:requestToEnterVehicle(self.currentVehicle)
        if ContractorModWorker.debug then print("ContractorModWorker: playerStyle "..tostring(self.playerStyle)) end
      end
    -- end
  end
end

function ContractorModWorker:setYawInstant(yaw)
	self.npc.rotY = yaw
	if self.npc.node ~= nil then
		setWorldRotation(self.npc.node, self.npc.rotX, yaw, self.npc.rotZ)
	end
	if self.npc.playerGraphics ~= nil then
		self.npc.playerGraphics:setModelYaw(yaw)
	end
	if self.npc.isServer then
		-- ensure clients are updated
		self.npc:raiseDirtyFlags(self.npc.dirtyFlag)
	end
end
