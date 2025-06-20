cmWardrobeScreen = {}

function cmWardrobeScreen:app_onItemSelectionConfirmed()
  if ContractorMod.debug then print("cmWardrobeScreen:app_onItemSelectionConfirmed") end
  ContractorMod.workers[ContractorMod.currentID].playerStyle:copyFrom(self.currentPlayerStyle)
end
WardrobeScreen.onItemSelectionConfirmed = Utils.appendedFunction(WardrobeScreen.onItemSelectionConfirmed, cmWardrobeScreen.app_onItemSelectionConfirmed)
