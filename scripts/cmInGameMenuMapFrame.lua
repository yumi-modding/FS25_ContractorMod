cmInGameMenuMapFrame = {}

function cmInGameMenuMapFrame:onClickSwitchWorker()
  if ContractorMod.debug then print("cmInGameMenuMapFrame:onClickSwitchWorker") end
	if self.currentHotspot ~= nil then
		if self.currentHotspot:isa(NPCHotspot) then
			local npc = self.currentHotspot:getNPC()
			if npc ~= nil then
				self.onClickBackCallback()
        local worker = ContractorMod:getWorkerFromNPC(npc)
        if worker ~= nil then
            ContractorMod:setCurrentContractorModWorker(worker.index)
        end
			end
		end
  end
end

function cmInGameMenuMapFrame:onClickActiveWorker()
  if ContractorMod.debug then print("cmInGameMenuMapFrame:onClickActiveWorker") end
	if self.currentHotspot ~= nil then
		if self.currentHotspot:isa(NPCHotspot) then
			local npc = self.currentHotspot:getNPC()
			if npc ~= nil then
				self.onClickBackCallback()
        local worker = ContractorMod:getWorkerFromNPC(npc)
        if worker ~= nil then
            worker:setActive(true)
        end
			end
		end
  end
end

function cmInGameMenuMapFrame:onClickInactiveWorker()
  if ContractorMod.debug then print("cmInGameMenuMapFrame:onClickInactiveWorker") end
	if self.currentHotspot ~= nil then
		if self.currentHotspot:isa(NPCHotspot) then
			local npc = self.currentHotspot:getNPC()
			if npc ~= nil then
				self.onClickBackCallback()
        local worker = ContractorMod:getWorkerFromNPC(npc)
        if worker ~= nil then
            worker:setActive(false)
        end
			end
		end
  end
end

function cmInGameMenuMapFrame:setMapInputContext(superfunc, canEnter, canReset, canSellVehicle, canVisit, canSetMarker, removeMarker, canBuy, canSell, canManage)  
  if ContractorMod.debug then print("cmInGameMenuMapFrame:setMapInputContext") end
  superfunc(self, canEnter, canReset, canSellVehicle, canVisit, canSetMarker, removeMarker, canBuy, canSell, canManage)
    -- DebugUtil.printTableRecursively(g_gui.frames.ingameMenuMapOverview.target.contextActions, " ", 1, 2)
    print("Current hotspot: "..tostring(self.currentHotspot))
    -- DebugUtil.printTableRecursively(self.contextActions, " ", 1, 2)

    self.ACTIONS["SWITCH_WORKER"] = 15
    self.contextActions[InGameMenuMapFrame.ACTIONS.SWITCH_WORKER] = {
        ["text"] = "button_select",
        ["callback"] = cmInGameMenuMapFrame.onClickSwitchWorker,
        ["isActive"] = false
    }
    self.ACTIONS["ACTIVE_WORKER"] = 16
    self.contextActions[InGameMenuMapFrame.ACTIONS.ACTIVE_WORKER] = {
        ["text"] = "ui_gpsInactive",
        ["callback"] = cmInGameMenuMapFrame.onClickActiveWorker,
        ["isActive"] = false
    }
    self.ACTIONS["INACTIVE_WORKER"] = 17
    self.contextActions[InGameMenuMapFrame.ACTIONS.INACTIVE_WORKER] = {
        ["text"] = "ui_gpsActive",
        ["callback"] = cmInGameMenuMapFrame.onClickInactiveWorker,
        ["isActive"] = false
    }
    self.contextActions[InGameMenuMapFrame.ACTIONS.SWITCH_WORKER].isActive = false
    self.contextActions[InGameMenuMapFrame.ACTIONS.ACTIVE_WORKER].isActive = false
    self.contextActions[InGameMenuMapFrame.ACTIONS.INACTIVE_WORKER].isActive = false
    -- Enable SWITCH_WORKER only for NPCs
    if self.currentHotspot ~= nil and self.currentHotspot:isa(NPCHotspot) then
			local npc = self.currentHotspot:getNPC()
			if npc ~= nil then
        local worker = ContractorMod:getWorkerFromNPC(npc)
        if worker ~= nil then
          self.contextActions[InGameMenuMapFrame.ACTIONS.SWITCH_WORKER].isActive = worker.active
          self.contextActions[InGameMenuMapFrame.ACTIONS.ACTIVE_WORKER].isActive = worker.active == false
          self.contextActions[InGameMenuMapFrame.ACTIONS.INACTIVE_WORKER].isActive = worker.active
        end
      end
    end
end

InGameMenuMapFrame.setMapInputContext = Utils.overwrittenFunction(InGameMenuMapFrame.setMapInputContext, cmInGameMenuMapFrame.setMapInputContext)
