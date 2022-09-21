TUTORIAL_SYSTEM = nil

local function AreTutorialsEnabled()
    return GetSetting_Bool(SETTING_TYPE_TUTORIAL, TUTORIAL_ENABLED_SETTING_ID)
end

ZO_Tutorials = ZO_InitializingObject:Subclass()

function ZO_Tutorials:Initialize(control)
    self.control = control

    self.tutorialHandlers = {}
    self.tutorialQueue = {}

    -- Events that have no TutorialTriggerHandler

    local function OnDisplayTutorial(eventCode, ...)
        self:DisplayOrQueueTutorial(...)
    end

    control:RegisterForEvent(EVENT_DISPLAY_TUTORIAL, OnDisplayTutorial)
    control:RegisterForEvent(EVENT_DISPLAY_TUTORIAL_WITH_ANCHOR, OnDisplayTutorial)
    control:RegisterForEvent(EVENT_REMOVE_TUTORIAL, function(eventCode, ...) self:OnRemoveTutorial(...) end)
    control:RegisterForEvent(EVENT_TUTORIAL_SYSTEM_ENABLED_STATE_CHANGED, function(eventCode, enabled) self:OnTutorialEnabledStateChanged(enabled) end)

    do
        local triggerHandlers = ZO_Tutorial_GetTriggerHandlers()

        local function OnTriggeredEvent(eventCode, ...)
            local tutorialTypeToTrigger = triggerHandlers[eventCode](...)
            if tutorialTypeToTrigger then
                TriggerTutorial(tutorialTypeToTrigger)
            end
        end

        -- Unfortunate events that overlap with tutorial triggers
        local hasPlayerActivatedEvent = triggerHandlers[EVENT_PLAYER_ACTIVATED] ~= nil
        control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function(...)
            if hasPlayerActivatedEvent then
                OnTriggeredEvent(...)
            end

            -- Dequeue tutorial display events
            local nextTutorialCallback = table.remove(self.tutorialQueue, 1)
            while nextTutorialCallback do
                nextTutorialCallback()
                nextTutorialCallback = table.remove(self.tutorialQueue, 1)
            end
        end)

        for event in pairs(triggerHandlers) do
            if event ~= EVENT_PLAYER_ACTIVATED then -- Handled above
                control:RegisterForEvent(event, OnTriggeredEvent)
            end
        end
    end

    self:AddTutorialHandler(ZO_BriefHudTutorial:New(control))
    self:AddTutorialHandler(ZO_HudInfoTutorial:New(control))
    self:AddTutorialHandler(ZO_UiInfoBoxTutorial:New(control))
    if IsKeyboardUISupported() then
        self:AddTutorialHandler(ZO_PointerBoxTutorial:New(control))
    end
end

function ZO_Tutorials:DisplayOrQueueTutorial(tutorialIndex, ...)
    local currentScene = SCENE_MANAGER:GetCurrentScene()
    if currentScene == nil then
        -- Queue Tutorial
        local optionalParameters = {...}
        table.insert(self.tutorialQueue, function() self:OnDisplayTutorial(tutorialIndex, unpack(optionalParameters)) end)
    else
        self:OnDisplayTutorial(tutorialIndex, ...)
    end
end

function ZO_Tutorials:AddTutorialHandler(handler)
    self.tutorialHandlers[handler:GetTutorialType()] = handler
end

function ZO_Tutorials:SuppressTutorialType(tutorialType, suppress, reason)
    if self.tutorialHandlers[tutorialType] then
        self.tutorialHandlers[tutorialType]:SuppressTutorials(suppress, reason)
    end
end

function ZO_Tutorials:RegisterTriggerLayoutInfo(tutorialType, ...)
    if self.tutorialHandlers[tutorialType] then
        self.tutorialHandlers[tutorialType]:RegisterTriggerLayoutInfo(...)
    end
end

function ZO_Tutorials:RemoveTutorialByTrigger(tutorialType, tutorialTrigger)
    if self.tutorialHandlers[tutorialType] then
        self.tutorialHandlers[tutorialType]:RemoveTutorialByTrigger(tutorialTrigger)
    end
end

function ZO_Tutorials:OnTutorialEnabledStateChanged(enabled)
    if not enabled then
        for type, handler in pairs(self.tutorialHandlers) do
            handler:ClearAll()
        end
    end
end

function ZO_Tutorials:ForceRemoveAll()
    for type, handler in pairs(self.tutorialHandlers) do
        local tutorialIndex = handler:GetCurrentlyDisplayedTutorialIndex()
        if tutorialIndex then
            handler:OnRemoveTutorial(tutorialIndex)
        end
    end
end

function ZO_Tutorials:OnDisplayTutorial(tutorialIndex, ...)
    local tutorialType = GetTutorialType(tutorialIndex)
    if self.tutorialHandlers[tutorialType] then
        local priority = GetTutorialDisplayPriority(tutorialIndex)
        self.tutorialHandlers[tutorialType]:OnDisplayTutorial(tutorialIndex, priority, ...)
    end
end

function ZO_Tutorials:OnRemoveTutorial(tutorialIndex)
    local tutorialType = GetTutorialType(tutorialIndex)
    if self.tutorialHandlers[tutorialType] then
        self.tutorialHandlers[tutorialType]:OnRemoveTutorial(tutorialIndex)
    end
end

function ZO_Tutorials:ShowHelp()
    for type, handler in pairs(self.tutorialHandlers) do
        if handler:ShowHelp() then
            return true
        end
    end
    return false
end

function ZO_Tutorials:TriggerTutorialWithDeferredAction(triggerType, tutorialCompletedCallback)
    local triggerEventTag = "ZO_TutorialTrigger"..triggerType
    
    local function OnTutorialTriggerCompleted(eventCode, completedTriggerType)
        if completedTriggerType == triggerType then
            EVENT_MANAGER:UnregisterForEvent(triggerEventTag, EVENT_TUTORIAL_TRIGGER_COMPLETED)
            tutorialCompletedCallback()
        end
    end
    EVENT_MANAGER:RegisterForEvent(triggerEventTag, EVENT_TUTORIAL_TRIGGER_COMPLETED, OnTutorialTriggerCompleted)

    TriggerTutorial(triggerType)
end

function ZO_Tutorial_Initialize(control)
    TUTORIAL_SYSTEM = ZO_Tutorials:New(control)
end