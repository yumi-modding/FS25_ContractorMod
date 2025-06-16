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
