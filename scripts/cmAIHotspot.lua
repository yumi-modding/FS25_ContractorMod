-- AIHotspot:setAIHelperName(name)
cmAIHotspot = {}

-- Append character name when worker is active
function cmAIHotspot:setAIHelperName(superfunc, name)
    local currentWorker = ContractorMod.workers[ContractorMod.currentID]
    local vehicle = self:getVehicle()
    if vehicle ~= nil then
        for _, worker in pairs(ContractorMod.workers) do
            local currentVehicle = ContractorMod:getWorkerVehicle(worker)
            if currentVehicle ~= nil and currentVehicle == vehicle and worker.currentSeat == nil then
                currentWorker = worker
                break
            end
        end
    end
    local _, textSize = getNormalizedScreenValues(0, 20)
    self.textSize = textSize
    self:setColor(unpack(currentWorker.color))
    self.name = name .. " (" .. currentWorker.name .. ")"
end
AIHotspot.setAIHelperName = Utils.overwrittenFunction(AIHotspot.setAIHelperName, cmAIHotspot.setAIHelperName);

