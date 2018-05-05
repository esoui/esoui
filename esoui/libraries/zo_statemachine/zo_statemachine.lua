------------
--Triggers--
------------

--Base--
ZO_StateMachine_TriggerBase = ZO_Object:Subclass()

function ZO_StateMachine_TriggerBase:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_StateMachine_TriggerBase:Initialize()
    self.registeredEdge = nil
    self.defaultTriggerFunction = function() self:Trigger() end
end

function ZO_StateMachine_TriggerBase:RegisterEdge(edge)
    --A trigger can't be registered to more than one edge at a time, lest madness occur
    assert(self.registeredEdge == nil)
    self.registeredEdge = edge
end

function ZO_StateMachine_TriggerBase:UnregisterEdge()
    self.registeredEdge = nil
end

function ZO_StateMachine_TriggerBase:Trigger()
    if self.registeredEdge then
        self.registeredEdge:Trigger()
    end
end

--Keybind--
ZO_StateMachine_TriggerKeybind = ZO_StateMachine_TriggerBase:Subclass()

function ZO_StateMachine_TriggerKeybind:New(...)
    return ZO_StateMachine_TriggerBase.New(self, ...)
end

function ZO_StateMachine_TriggerKeybind:Initialize(keybindDescriptor)
    ZO_StateMachine_TriggerBase.Initialize(self)

    self.keybindDescriptor = keybindDescriptor
end

function ZO_StateMachine_TriggerKeybind:RegisterEdge(edge)
    ZO_StateMachine_TriggerBase.RegisterEdge(self, edge)

    self.keybindDescriptor.callback = self.defaultTriggerFunction
    KEYBIND_STRIP:AddKeybindButton(self.keybindDescriptor)
end

function ZO_StateMachine_TriggerKeybind:UnregisterEdge()
    ZO_StateMachine_TriggerBase.UnregisterEdge(self)

    KEYBIND_STRIP:RemoveKeybindButton(self.keybindDescriptor)
end

--State Callback--
ZO_StateMachine_TriggerStateCallback = ZO_StateMachine_TriggerBase:Subclass()

function ZO_StateMachine_TriggerStateCallback:New(...)
    return ZO_StateMachine_TriggerBase.New(self, ...)
end

function ZO_StateMachine_TriggerStateCallback:Initialize(eventName)
    ZO_StateMachine_TriggerBase.Initialize(self)

    self.eventName = eventName
    self.eventCountOrCallback = nil
    self.triggerFunction = function()
        if self.eventCountNeeded then
            self.eventCountNeeded = self.eventCountNeeded - 1
            if self.eventCountNeeded > 0 then
                return
            end
        end
        self.defaultTriggerFunction()
    end
end

function ZO_StateMachine_TriggerStateCallback:RegisterEdge(edge)
    ZO_StateMachine_TriggerBase.RegisterEdge(self, edge)
    
    if self.eventCountOrCallback then
        if type(self.eventCountOrCallback) == "function" then
            self.eventCountNeeded = self.eventCountOrCallback()
        else
            self.eventCountNeeded = self.eventCountOrCallback
        end
    end

    edge:GetParentMachine():RegisterCallback(self.eventName, self.triggerFunction)
end

function ZO_StateMachine_TriggerStateCallback:UnregisterEdge()
    self.registeredEdge:GetParentMachine():UnregisterCallback(self.eventName, self.triggerFunction)

    self.eventCountNeeded = nil

    ZO_StateMachine_TriggerBase.UnregisterEdge(self)
end

--Use this if you want to wait until a dynamic number of the specified events gets called before triggering
function ZO_StateMachine_TriggerStateCallback:SetEventCount(countOrCallback)
    self.eventCountOrCallback = countOrCallback
end

--Event Manager--
ZO_StateMachine_TriggerEventManager = ZO_StateMachine_TriggerBase:Subclass()

function ZO_StateMachine_TriggerEventManager:New(...)
    return ZO_StateMachine_TriggerBase.New(self, ...)
end

function ZO_StateMachine_TriggerEventManager:Initialize(eventId)
    ZO_StateMachine_TriggerBase.Initialize(self)

    self.eventId = eventId
    self.edgeName = nil
    self.filterCallback = nil
    self.triggerFunction = function(...)
        if not self.filterCallback or self.filterCallback(...) then
            self.defaultTriggerFunction()
        end
    end
end

function ZO_StateMachine_TriggerEventManager:RegisterEdge(edge)
    ZO_StateMachine_TriggerBase.RegisterEdge(self, edge)

    self.edgeName = edge:GetEdgeName()
    EVENT_MANAGER:RegisterForEvent(self.edgeName, self.eventId, self.triggerFunction)
end

function ZO_StateMachine_TriggerEventManager:UnregisterEdge()
    EVENT_MANAGER:UnregisterForEvent(self.edgeName, self.eventId)
    self.edgeName = nil

    ZO_StateMachine_TriggerBase.UnregisterEdge(self)
end

--Use this if you want to run verification checks on the event params before accepting the event as a trigger
function ZO_StateMachine_TriggerEventManager:SetFilterCallback(callback)
    self.filterCallback = callback
end

--Anim Note Event Manager--
ZO_StateMachine_TriggerAnimNote = ZO_StateMachine_TriggerEventManager:Subclass()

function ZO_StateMachine_TriggerAnimNote:New(...)
    return ZO_StateMachine_TriggerEventManager.New(self, ...)
end

function ZO_StateMachine_TriggerAnimNote:Initialize(expectedNote)
    ZO_StateMachine_TriggerEventManager.Initialize(self, EVENT_ANIMATION_NOTE)

    local function FilterCallback(eventCode, eventNote)
        return expectedNote == eventNote
    end

    self:SetFilterCallback(FilterCallback)
end


--Multi-Trigger
--Used when you need to get one edge to proc on a number of triggers being hit
ZO_StateMachine_MultiTrigger = ZO_StateMachine_TriggerBase:Subclass()

function ZO_StateMachine_MultiTrigger:New(...)
    return ZO_StateMachine_TriggerBase.New(self, ...)
end

function ZO_StateMachine_MultiTrigger:Initialize(...)
    ZO_StateMachine_TriggerBase.Initialize(self)

    self.triggerList = {}
    self.pendingTriggers = {}

    local function OnTrigger(trigger)
        self.pendingTriggers[trigger] = nil
        
        if NonContiguousCount(self.pendingTriggers) == 0 then
            self.defaultTriggerFunction()
        end
    end

    for i = 1, select("#", ...) do
        local trigger = select(i, ...)
        trigger.Trigger = OnTrigger
        table.insert(self.triggerList, trigger)
    end
end

function ZO_StateMachine_MultiTrigger:RegisterEdge(edge)
    ZO_StateMachine_TriggerBase.RegisterEdge(self, edge)

    for _, trigger in ipairs(self.triggerList) do
        trigger:RegisterEdge(edge)
        self.pendingTriggers[trigger] = true
    end
end

function ZO_StateMachine_MultiTrigger:UnregisterEdge()
    ZO_ClearTable(self.pendingTriggers)
    for _, trigger in ipairs(self.triggerList) do
        trigger:UnregisterEdge()
    end

    ZO_StateMachine_TriggerBase.UnregisterEdge(self)
end

--------
--Edge--
--------

ZO_StateMachine_Edge = ZO_CallbackObject:Subclass()

function ZO_StateMachine_Edge:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_StateMachine_Edge:Initialize(fromState, toState)
    -- Don't draw a bridge across machines
    assert(fromState:GetParentMachine() == toState:GetParentMachine())

    self.parentMachine = fromState:GetParentMachine()
    self.fromState = fromState
    self.toState = toState
    self.triggers = {}
    self.active = false

    fromState:AddEdge(self)
end

function ZO_StateMachine_Edge:GetParentMachine()
    return self.parentMachine
end

function ZO_StateMachine_Edge:GetEdgeName()
    return self.fromState:GetFullName() .. self.toState:GetName()
end

function ZO_StateMachine_Edge:SetConditional(conditionalCallback)
    self.conditionalCallback = conditionalCallback
end

function ZO_StateMachine_Edge:AddTrigger(trigger)
    table.insert(self.triggers, trigger)
end

function ZO_StateMachine_Edge:Activate()
    if self.conditionalCallback and not self.conditionalCallback() then
        return
    end

    for _, trigger in ipairs(self.triggers) do
        trigger:RegisterEdge(self)
    end

    self.active = true
end

function ZO_StateMachine_Edge:Deactivate()
    if self.active then
        self.active = false

        for _, trigger in ipairs(self.triggers) do
            trigger:UnregisterEdge(self)
        end
    end
end

function ZO_StateMachine_Edge:Trigger()
    if self.parentMachine:GetDebugLoggingEnabled() then
        d("Triggering edge between " .. self.fromState:GetFullName() .. " and " .. self.toState:GetFullName())
    end

    self:FireCallbacks("OnTrigger")

    self.parentMachine:SetState(self.toState)

end

---------
--State--
---------

ZO_StateMachine_State = ZO_CallbackObject:Subclass()

function ZO_StateMachine_State:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

do
    local FULL_NAME_FORMAT = "%s_%s"

    function ZO_StateMachine_State:Initialize(parentMachine, name)
        self.name = name
        self.parentMachine = parentMachine
        self.fullName = string.format(FULL_NAME_FORMAT, self.parentMachine:GetName(), name)
        self.edges = {}
    end
end

function ZO_StateMachine_State:GetName()
    return self.name
end

function ZO_StateMachine_State:GetFullName()
    return self.fullName
end

function ZO_StateMachine_State:SetUpdate(updateCallback)
    assert(updateCallback ~= nil)

    self.updateName = self.fullName
    self.updateCallback = updateCallback
end

function ZO_StateMachine_State:AddEdge(edge)
    table.insert(self.edges, edge)
end

function ZO_StateMachine_State:GetParentMachine()
    return self.parentMachine
end

function ZO_StateMachine_State:Activate()
    for _, edge in ipairs(self.edges) do
        edge:Activate()
    end

    if self.parentMachine:GetDebugLoggingEnabled() then
        d(self.fullName .. " firing its OnActivated callbacks.")
    end

    self:FireCallbacks("OnActivated")

    if self.updateName then
        EVENT_MANAGER:RegisterForUpdate(self.updateName, 0, self.updateCallback)

        if self.parentMachine:GetDebugLoggingEnabled() then
            d(self.fullName .. " registered for an update.")
        end
    end
end

function ZO_StateMachine_State:Deactivate()
    if self.updateName then
        EVENT_MANAGER:UnregisterForUpdate(self.updateName)

        if self.parentMachine:GetDebugLoggingEnabled() then
            d(self.fullName .. " unregistered for an update.")
        end
    end
    
    if self.parentMachine:GetDebugLoggingEnabled() then
        d(self.fullName .. " firing its OnDeactivated callbacks.")
    end

    self:FireCallbacks("OnDeactivated")

    for _, edge in ipairs(self.edges) do
        edge:Deactivate()
    end
end

--------
--Base--
--------

ZO_StateMachine_Base = ZO_CallbackObject:Subclass()

function ZO_StateMachine_Base:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_StateMachine_Base:Initialize(name)
    self.name = name
    self.currentState = nil
end

function ZO_StateMachine_Base:GetName()
    return self.name
end

function ZO_StateMachine_Base:SetState(state)
    if state == self.currentState then
        return
    end

    if self.currentState then
        self.currentState:Deactivate()
    end

    self.currentState = state
    state:Activate()

    self:FireCallbacks("OnStateChange")
end

function ZO_StateMachine_Base:GetCurrentState()
    return self.currentState
end

function ZO_StateMachine_Base:Reset()
    if self.currentState then
        self.currentState:Deactivate()
        self.currentState = nil
    end
end

function ZO_StateMachine_Base:SetDebugLoggingEnabled(enabled)
    self.debugLoggingEnabled = enabled
end

function ZO_StateMachine_Base:GetDebugLoggingEnabled()
    return self.debugLoggingEnabled
end
