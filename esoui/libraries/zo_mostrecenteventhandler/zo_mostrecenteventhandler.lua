ZO_MostRecentEventHandler = ZO_Object:Subclass()

function ZO_MostRecentEventHandler:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

--equalityFunction: determines if a new event should replace and old event with new info
--handlerFunction: executes code for the most recent events 
function ZO_MostRecentEventHandler:Initialize(namespace, event, equalityFunction, handlerFunction)
    self.namespace = namespace
    self.event = event
    self.events = {}
    self.equalityFunction = equalityFunction
    self.handlerFunction = handlerFunction
    EVENT_MANAGER:RegisterForEvent(namespace, event, function(_, ...) self:OnEvent(...) end)
    EVENT_MANAGER:RegisterForUpdate(namespace, 0, function() self:OnUpdate() end)
end

function ZO_MostRecentEventHandler:AddFilterForEvent(...)
    EVENT_MANAGER:AddFilterForEvent(self.namespace, self.event, ...)
end

function ZO_MostRecentEventHandler:OnEvent(...)
    for _, eventInfo in ipairs(self.events) do
        if self.equalityFunction(eventInfo, ...) then
            local numEventFields = select("#", ...)
            for fieldIndex = 1, numEventFields do
                eventInfo[fieldIndex] = select(fieldIndex, ...)
            end
            return
        end
    end
    table.insert(self.events, { ... })
end

function ZO_MostRecentEventHandler:OnUpdate()
    for i, eventInfo in ipairs(self.events) do
        self.handlerFunction(unpack(eventInfo))
    end
    ZO_ClearNumericallyIndexedTable(self.events)
end