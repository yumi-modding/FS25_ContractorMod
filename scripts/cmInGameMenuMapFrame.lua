cmInGameMenuMapFrame = {}

function cmInGameMenuMapFrame:onSwitchVehicle(superfunc, value, direction)
  if ContractorMod.debug then print("cmInGameMenuMapFrame:onSwitchVehicle") end
  print("We might prevent to switch vehicle from the map menu")
  superfunc(self, value, direction)
end
InGameMenuMapFrame.onSwitchVehicle = Utils.overwrittenFunction(InGameMenuMapFrame.onSwitchVehicle, cmInGameMenuMapFrame.onSwitchVehicle)
