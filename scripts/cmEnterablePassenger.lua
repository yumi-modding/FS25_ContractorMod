cmEnterablePassenger = {}

-- Activate passenger enterable for vehicles with passenger seats
function cmEnterablePassenger:onLoad(superFunc, savegame)
  if ContractorMod.debug then print("cmEnterablePassenger:onLoad") end
  superFunc(self, savegame)
  -- Force available to true if there are passenger seats (bypass multiplayer check)
  local spec = self.spec_enterablePassenger
  if spec ~= nil and #spec.passengerSeats > 0 then
      spec.available = true
    --   spec.allowInSingleplayer = true
    --   spec.allowPassengerOnly = true
    --   spec.allowVehicleControl = true
      -- Subscribe to message center since available is now true
      if not spec.messageSubscribed then
          g_messageCenter:subscribe(MessageType.PLAYER_STYLE_CHANGED, self.onPassengerPlayerStyleChanged, self)
          spec.messageSubscribed = true
      end
  end
end
EnterablePassenger.onLoad = Utils.overwrittenFunction(EnterablePassenger.onLoad, cmEnterablePassenger.onLoad)

-- Value worker.currentSeat when entering/exiting as passenger to keep track of occupied seats
function cmEnterablePassenger:setPassengerSeatCharacter(superfunc, seatIndex, playerStyle)
    if ContractorMod.debug then print(string.format("cmEnterablePassenger:setPassengerSeatCharacter seatIndex=%s playerStyle=%s", tostring(seatIndex), tostring(playerStyle))) end
    if ContractorMod.switching and playerStyle == nil then
        if ContractorMod.debug then print("switching from passenger so keep passenger seat character") end
        local workerPlayerStyle = nil
        for _, worker in pairs(ContractorMod.workers) do
            if worker.currentSeat == seatIndex and ContractorMod:getWorkerVehicle(worker) == self then
                workerPlayerStyle = worker.playerStyle
                break
            end
        end
        -- Force setting character to prevent it disappear
        superfunc(self, seatIndex, workerPlayerStyle)
    else
        if ContractorMod.debug then print("not switching or switching to passenger so set passenger seat character") end
        local worker = ContractorMod.workers[ContractorMod.currentID]
        if playerStyle ~= nil then
            worker.currentSeat = seatIndex
        else
            if ContractorMod.debug then print("Leaving passenger seat, clear currentSeat for worker "..worker.name) end
            worker.currentSeat = nil
        end
        superfunc(self, seatIndex, playerStyle)
    end
    if ContractorMod.debug then print(string.format("setPassengerSeatCharacter active camera %s", tostring(self.spec_enterable.activeCamera))) end
end
EnterablePassenger.setPassengerSeatCharacter = Utils.overwrittenFunction(EnterablePassenger.setPassengerSeatCharacter, cmEnterablePassenger.setPassengerSeatCharacter)

-- Enable to enter as passenger if vehicle has free passenger seats
function cmEnterablePassenger:getIsInteractive(superfunc, superFunc)
    if ContractorMod.enablePassenger then
        if not ContractorMod:isControlledByWorker(self) then
            return superfunc(self, superFunc)
        else
            -- if ContractorMod.debug then print("cmEnterablePassenger:getIsInteractive: true") end
            return ContractorMod:getFirstFreeSeat(self) > 0 --ContractorMod:hasPassengerSeats(self)
        end
    else
        return superfunc(self, superFunc)
    end


    --     -- If controlled by worker, only allow passenger entry if it has passenger seats
    --     if ContractorMod.enablePassenger and ContractorMod:isControlledByWorker(self) then
    --         return ContractorMod:hasPassengerSeats(self)
    --     end
    
    -- -- Not controlled by worker, use normal flow
    -- return superFunc(self)
end
EnterablePassenger.getIsInteractive = Utils.overwrittenFunction(EnterablePassenger.getIsInteractive, cmEnterablePassenger.getIsInteractive)

-- Prevent to switch seat for now since not working correctly and can lead to bugs, to investigate
function cmEnterablePassenger:actionEventSwitchSeat(superfunc, actionName, inputValue, callbackState, isAnalog, isMouse)
    if ContractorMod.enablePassenger then
        print("Switching seat is disabled with ContractorMod to prevent bugs for now")
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("ContractorMod_SEAT_SWITCH_DISABLED"))
        -- TODO: to implement
    else
        superfunc(self, actionName, inputValue, callbackState, isAnalog, isMouse)
    end
end
EnterablePassenger.actionEventSwitchSeat = Utils.overwrittenFunction(EnterablePassenger.actionEventSwitchSeat, cmEnterablePassenger.actionEventSwitchSeat)

-- Compute distance to passenger seat to allow entering as passenger if free passenger seats and prevent entering as driver if driver seat occupied, to investigate if we can use it to prevent entering as passenger if no driver in the vehicle
-- TODO: OK for 1 passenger seat vehicles. Passenger cannot exit vehicle in some cases
function cmEnterablePassenger:getDistanceToNode(superfunc, superFunc, node)
    local superDistance = superfunc(self, superFunc, node)
    -- quick debug:
    -- if superDistance < 2 then
    --     print(("cmEnterablePassenger called for vehicle=%s, superDistance=%.3f"):format(tostring(self:getName()), superDistance))
    -- end
    local isControlledByWorker = ContractorMod and ContractorMod.isControlledByWorker and ContractorMod:isControlledByWorker(self)
    if self:getIsControlled() or self.spec_enterablePassenger.allowPassengerOnly or isControlledByWorker then
        local seatIndex, distance = self:getClosestSeatIndex(node)
        -- if ContractorMod:getFirstFreeSeat(self) == 0 then
        --     return math.huge  -- Block all entry
        -- end
        -- local seatIndex = ContractorMod:getFirstFreeSeat(self);
        -- local passengerSeat = self.spec_enterablePassenger.passengerSeats[seatIndex]
        -- local distance = calcDistanceFrom(node, passengerSeat.node)
        -- local spec = self.spec_enterablePassenger
        -- local minDistance = math.huge
		-- if distance >= spec.minEnterDistance or distance >= minDistance then
		-- 	continue
		-- end
		-- minDistance = distance --self:getClosestSeatIndex(node)
        -- print(("seatIndex=%s distance=%.3f isControlledByWorker=%s"):format(tostring(seatIndex), distance or 0, tostring(isControlledByWorker)))
        if seatIndex ~= nil and distance < superDistance then
            self.interactionFlag = Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER
            return distance
        end
        return math.huge  -- No seats available
    end
    return superDistance
end
EnterablePassenger.getDistanceToNode = Utils.overwrittenFunction(EnterablePassenger.getDistanceToNode, cmEnterablePassenger.getDistanceToNode)

-- Resolve a passengerSeat table entry to its seat index in spec.passengerSeats.
local function cmGetSeatIndexFromSeatEntry(vehicle, passengerSeat)
    local spec = vehicle.spec_enterablePassenger
    if spec == nil or spec.passengerSeats == nil then
        return nil
    end

    for seatIndex, seat in ipairs(spec.passengerSeats) do
        if seat == passengerSeat then
            return seatIndex
        end
    end

    return nil
end

-- Base game seat selection uses getIsPassengerSeatAvailable(passengerSeat), not the index-based variant.
function cmEnterablePassenger:getIsPassengerSeatAvailable(superfunc, passengerSeat)
    local seatAvailable = superfunc(self, passengerSeat)

    if not ContractorMod.enablePassenger then
        return seatAvailable
    end

    if not ContractorMod:isControlledByWorker(self) then
        return seatAvailable
    end

    if not seatAvailable then
        return false
    end

    local seatIndex = cmGetSeatIndexFromSeatEntry(self, passengerSeat)
    if seatIndex == nil then
        return false
    end

    for _, worker in pairs(ContractorMod.workers) do
        local currentVehicle = ContractorMod:getWorkerVehicle(worker)
        if currentVehicle == self and worker.currentSeat == seatIndex then
            return false
        end
    end

    return true
end
EnterablePassenger.getIsPassengerSeatAvailable = Utils.overwrittenFunction(EnterablePassenger.getIsPassengerSeatAvailable, cmEnterablePassenger.getIsPassengerSeatAvailable)

-- Take into account occupied seats by workers to determine if passenger seat is available or not
function cmEnterablePassenger:getIsPassengerSeatIndexAvailable(superfunc, seatIndex)
    local spec = self.spec_enterablePassenger
    local passengerSeat = spec ~= nil and spec.passengerSeats ~= nil and spec.passengerSeats[seatIndex] or nil

    if passengerSeat == nil then
        return false
    end

    return self:getIsPassengerSeatAvailable(passengerSeat)
end
EnterablePassenger.getIsPassengerSeatIndexAvailable = Utils.overwrittenFunction(EnterablePassenger.getIsPassengerSeatIndexAvailable, cmEnterablePassenger.getIsPassengerSeatIndexAvailable)

-- We don't want to block AIJob helper if passenger seat is occupied, so return false to not block it
function cmEnterablePassenger:getIsInUse(superfunc, superFunc, connection)
	local spec = self.spec_enterablePassenger
	if spec.available then
		for seatIndex = 1, #spec.passengerSeats do
			local passengerSeat = spec.passengerSeats[seatIndex]
			if not passengerSeat.isUsed then
				continue
			end
			return false    -- At least one passenger seat is occupied, so the enterable is in use but we don't want to prevent using AIJob helper for workers, so return false to not block it
		end
		return superfunc(self, superFunc, connection)
	else
		return superfunc(self, superFunc, connection)
	end
end
EnterablePassenger.getIsInUse = Utils.overwrittenFunction(EnterablePassenger.getIsInUse, cmEnterablePassenger.getIsInUse)


-- Was used to Prevent crash in Enterable:postUpdate -> spec.activeCamera:update(dt). Seems useless now.
function cmEnterablePassenger:leavePassengerSeat(superfunc, isOwner, seatIndex)
    print(string.format("cmEnterablePassenger:leavePassengerSeat isOwner=%s seatIndex=%s", tostring(isOwner), tostring(seatIndex)))
    superfunc(self, isOwner, seatIndex)
    local specEnterable = self.spec_enterable
    if specEnterable ~= nil and specEnterable.activeCamera == nil then
        -- Will set the exterior camera by default instead of last one.
        specEnterable:setActiveCameraIndex(1)
    end
end
-- EnterablePassenger.leavePassengerSeat = Utils.overwrittenFunction(EnterablePassenger.leavePassengerSeat, cmEnterablePassenger.leavePassengerSeat)
