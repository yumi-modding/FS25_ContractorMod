cmEnterable = {}

-- @doc Set mapping between savegame vehicle id and vehicle network id when vehicle is loaded
cmEnterable.app_OnLoad = function(self, savegame)
  if ContractorMod.debug then print("cmEnterable.app_OnLoad") end
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
    -- DebugUtil.printTableRecursively(ContractorMod.mapVehicleLoad, " ", 1, 2)
  end
end
Enterable.onLoad = Utils.appendedFunction(Enterable.onLoad, cmEnterable.app_OnLoad)

-- @doc Prevent from removing driver character when leaving vehicle if switching between workers
function cmEnterable:getDisableVehicleCharacterOnLeave(superfunc)
  if ContractorMod.debug then print("cmEnterable:getDisableVehicleCharacterOnLeave") end
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
Enterable.getDisableVehicleCharacterOnLeave = Utils.overwrittenFunction(Enterable.getDisableVehicleCharacterOnLeave, cmEnterable.getDisableVehicleCharacterOnLeave)
