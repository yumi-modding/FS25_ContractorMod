cmInGameMenuMapFrame = {}

function cmInGameMenuMapFrame:onSwitchVehicle(superfunc, value, direction)
  if ContractorMod.debug then print("cmInGameMenuMapFrame:onSwitchVehicle") end
  print("We might prevent to switch vehicle from the map menu")
  superfunc(self, value, direction)
end
InGameMenuMapFrame.onSwitchVehicle = Utils.overwrittenFunction(InGameMenuMapFrame.onSwitchVehicle, cmInGameMenuMapFrame.onSwitchVehicle)

function cmInGameMenuMapFrame:onClickVisitPlace(superfunc)
  if ContractorMod.debug then print("cmInGameMenuMapFrame:onClickVisitPlace") end
	if self.currentHotspot ~= nil then
		if self.currentHotspot:isa(NPCHotspot) then
			local npc = self.currentHotspot:getNPC()
			if npc ~= nil then
        if string.sub(npc.name, 1, 6) == "HELPER" and len(npc.name) > 6 then
          local workerId = tonumber(string.sub(npc.name, 7))
          if workerId ~= nil then
            local worker = ContractorMod.workers[workerId]
            if worker ~= nil then
              ContractorMod:setCurrentContractorModWorker(workerId)
            else
              print("Worker not found for id "..tostring(workerId))
            end
          else
            print("Invalid worker id in npc name "..npc.name)
          end
        else
          print("Not a worker npc "..npc.name)
				-- self.onClickBackCallback()
				-- if g_localPlayer:getCurrentVehicle() ~= nil then
				-- 	g_localPlayer:leaveVehicle()
				-- end
				-- g_localPlayer:teleportToNPC(npc)
          superfunc(self)
        end
			end
    else
      superfunc(self)
		end
  end
	return true
end
InGameMenuMapFrame.onClickVisitPlace = Utils.overwrittenFunction(InGameMenuMapFrame.onClickVisitPlace, cmInGameMenuMapFrame.onClickVisitPlace)