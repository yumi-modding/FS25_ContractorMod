cmPlayer = {}

function cmPlayer:onLeaveVehicle(superfunc, vehicle, noEventSend)
    if ContractorMod.debug then print("cmPlayer.onLeaveVehicle") end
    local currentVehicle = g_localPlayer:getCurrentVehicle()
    if currentVehicle then
        cmPlayer:ManageLeaveVehicle(currentVehicle)
    end
    superfunc(self, vehicle, noEventSend)
end
Player.leaveVehicle = Utils.overwrittenFunction(Player.leaveVehicle, cmPlayer.onLeaveVehicle)

-- @doc Make some checks before leaving a vehicle to manage passengers and hired worker
function cmPlayer:ManageLeaveVehicle(controlledVehicle)
    if ContractorMod.debug then print("cmPlayer:ManageLeaveVehicle") end
    
    if controlledVehicle ~= nil then
        if ContractorMod.shouldStopWorker then
            if controlledVehicle:getIsAIActive() then
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("ContractorMod_WORKER__STOP"))
                controlledVehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
            end
        end
    end

end

function cmPlayer:teleportToExitPoint(superfunc, vehicle, noEventSend)
    if ContractorMod.debug then print("cmPlayer:teleportToExitPoint") end
    -- printCallstack()
    -- Prevent to teleport to exit point when switching between workers
    if not ContractorMod.switching then
        superfunc(self, vehicle, noEventSend)
    end
end
Player.teleportToExitPoint = Utils.overwrittenFunction(Player.teleportToExitPoint, cmPlayer.teleportToExitPoint)

-- FOR DEBUGGING
-- function cmPlayer:teleportTo(superfunc, x, y, z, setNodeTranslation, noEventSend)
--     if ContractorMod.debug then print(string.format("cmPlayer:teleportTo %d, %d, %d", x, y, z)) end
--     printCallstack()
--     superfunc(self, x, y, z, setNodeTranslation, noEventSend)
-- end
-- Player.teleportTo = Utils.overwrittenFunction(Player.teleportTo, cmPlayer.teleportTo)

-- function cmPlayer:hide(superfunc, ...)
--     if ContractorMod.debug then print("cmPlayer:hide") end
--     printCallstack()
--     superfunc(self, ...)
-- end
-- Player.hide = Utils.overwrittenFunction(Player.hide, cmPlayer.hide)

-- PlayerTeleportEvent.run = Utils.overwrittenFunction(PlayerTeleportEvent.run, function(self, superfunc, ...)
--     if ContractorMod.debug then print("PlayerTeleportEvent:run") end
--     printCallstack()
--     superfunc(self, ...)
-- end)