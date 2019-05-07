local CMapHandlers = ZO_CallbackObject:Subclass()

function CMapHandlers:New()
    local object = ZO_CallbackObject.New(self)
    object:Initialize()
    return object
end

function CMapHandlers:Initialize()
    self:InitializeRefresh()
    self:InitializeEvents()
end

function CMapHandlers:InitializeRefresh()
    self.refresh = ZO_Refresh:New()

    self.refresh:AddRefreshGroup("keep",
    {
        RefreshAll = function()
            self:RefreshKeeps()
        end,
        RefreshSingle = function(...)
            self:RefreshKeep(...)
        end,
    })
end

function CMapHandlers:InitializeEvents()
    local function RefreshKeep(_, keepId, bgContext)
        self.refresh:RefreshSingle("keep", keepId, bgContext)
    end
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_ALLIANCE_OWNER_CHANGED, RefreshKeep)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_UNDER_ATTACK_CHANGED, RefreshKeep)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_PASSABLE_CHANGED, RefreshKeep)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_PIECE_DIRECTIONAL_ACCESS_CHANGED, RefreshKeep)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_INITIALIZED, RefreshKeep)

    local function RefreshKeeps()
        self.refresh:RefreshAll("keep")
    end
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_GATE_STATE_CHANGED, RefreshKeeps)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEPS_INITIALIZED, RefreshKeeps)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_CURRENT_SUBZONE_LIST_CHANGED, RefreshKeeps)

    EVENT_MANAGER:RegisterForUpdate("CMapHandler", 100, function()
        self.refresh:UpdateRefreshGroups()
    end)

    local function RefreshSingleQuestPins(questIndex)
        self:RefreshSingleQuestPins(questIndex)
        self:FireCallbacks("RefreshedSingleQuestPins", questIndex)
    end

    local function RefreshAllQuestPins()
        self:RefreshAllQuestPins()
        self:FireCallbacks("RefreshedAllQuestPins")
    end

    local function OnQuestConditionCounterChanged(eventCode, questIndex, questName, conditionText, conditionType, curCondtionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isQuestComplete, isConditionComplete, isStepHidden, isConditionCompleteStatusChanged, isConditionCompletableBySiblingStatusChanged)
        -- Only refresh if the condition completed has changed but the quest is not complete since there is another event for a quest completing.
        -- This will reduce the number of times the pins are refreshed so that they are not refreshed unnecessarily.
        if not isQuestComplete and (isConditionCompleteStatusChanged or isConditionCompletableBySiblingStatusChanged) then 
            RefreshSingleQuestPins(questIndex) 
        end 
    end

    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_QUEST_ADVANCED, function(_, questIndex) RefreshSingleQuestPins(questIndex) end)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_QUEST_ADDED, RefreshAllQuestPins)   
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_QUEST_REMOVED, RefreshAllQuestPins)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_QUEST_LIST_UPDATED, RefreshAllQuestPins)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_QUEST_CONDITION_COUNTER_CHANGED, OnQuestConditionCounterChanged)

    local function OnQuestTrackerTrackingStateChanged(questTracker, tracked, trackType, arg1, arg2)
        if trackType == TRACK_TYPE_QUEST then
            local questIndex = arg1
            local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, questIndex)
            SetMapQuestPinsTrackingLevel(questIndex, trackingLevel)
        end
    end

    local function OnQuestTrackerAssistStateChanged(unassistedData, assistedData)
        if unassistedData then
            local questIndex = unassistedData:GetJournalIndex()
            if questIndex then
                local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, questIndex)
                SetMapQuestPinsTrackingLevel(questIndex, trackingLevel)
            end
        end
        if assistedData then
            local questIndex = assistedData:GetJournalIndex()
            if questIndex then
                local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, questIndex)
                SetMapQuestPinsTrackingLevel(questIndex, trackingLevel)
            end
        end
    end

    FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", OnQuestTrackerAssistStateChanged)
    FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerTrackingStateChanged", OnQuestTrackerTrackingStateChanged)

    self:RefreshAllQuestPins()

    local function RefreshZoneStory()
        self:RefreshZoneStory()
    end

    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_ZONE_STORY_ACTIVITY_TRACKING_INIT, RefreshZoneStory)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_ZONE_STORY_ACTIVITY_TRACKED, RefreshZoneStory)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_ZONE_STORY_ACTIVITY_UNTRACKED, RefreshZoneStory)

    local function RefreshBreadcrumbPins()
        RefreshAllQuestPins()
        RefreshZoneStory()
    end

    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_PATH_FINDING_NETWORK_LINK_CHANGED, RefreshBreadcrumbPins)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_LINKED_WORLD_POSITION_CHANGED, RefreshBreadcrumbPins)

    local function OnPlayerActivated()
        RefreshKeeps()
        RefreshZoneStory()
    end

    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function CMapHandlers:AddKeep(keepId, bgContext)
    local pinType = GetKeepPinInfo(keepId, bgContext)
    if pinType ~= MAP_PIN_TYPE_INVALID then
        if DoesKeepPassCompassVisibilitySubzoneCheck(keepId, bgContext) then
            self:AddMapPin(pinType, keepId)

            local keepUnderAttack = GetKeepUnderAttack(keepId, bgContext)
            if(keepUnderAttack) then
                local keepUnderAttackPinType = ZO_WorldMap_GetUnderAttackPinForKeepPin(pinType)
                self:AddMapPin(keepUnderAttackPinType, keepId)
            end
        end
    end
end

function CMapHandlers:RefreshKeeps()
    RemoveMapPinsInRange(MAP_PIN_TYPE_KEEP_NEUTRAL, MAP_PIN_TYPE_KEEP_ATTACKED_SMALL)
    local numKeeps = GetNumKeeps()
    for i = 1, numKeeps do
        local keepId, bgContext = GetKeepKeysByIndex(i)
        if(IsLocalBattlegroundContext(bgContext)) then
            self:AddKeep(keepId, bgContext)
        end
    end
end

function CMapHandlers:RefreshKeep(keepId, bgContext)
    RemoveMapPinsInRange(MAP_PIN_TYPE_KEEP_NEUTRAL, MAP_PIN_TYPE_KEEP_ATTACKED_SMALL, keepId)
    if(IsLocalBattlegroundContext(bgContext)) then
        self:AddKeep(keepId, bgContext)
    end
end

function CMapHandlers:AddMapPin(pinType, param1, param2, param3)
    if self:ValidatePvPPinAllowed(pinType) then
        AddMapPin(pinType, param1, param2, param3)
    end
end

function CMapHandlers:ValidatePvPPinAllowed(pinType)
    local isAvARespawn = ZO_MapPin.AVA_RESPAWN_PIN_TYPES[pinType]
    local isForwardCamp = ZO_MapPin.FORWARD_CAMP_PIN_TYPES[pinType]
    local isFastTravelKeep = ZO_MapPin.FAST_TRAVEL_KEEP_PIN_TYPES[pinType]
    local isKeep = ZO_MapPin.KEEP_PIN_TYPES[pinType]
    local isDistrict = ZO_MapPin.DISTRICT_PIN_TYPES[pinType]

    if isAvARespawn or isForwardCamp or isFastTravelKeep or isKeep or isDistrict then
        if IsInCyrodiil() then
            return isAvARespawn or isForwardCamp or isFastTravelKeep or isKeep
        elseif IsInImperialCity() then
            return isDistrict or isAvARespawn
        end
        return false
    end
    return true
end

function CMapHandlers:RefreshSingleQuestPins(journalIndex)
    local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, journalIndex)
    
    RemoveMapQuestPins(journalIndex)
    AddMapQuestPins(journalIndex, trackingLevel)
end

function CMapHandlers:RefreshAllQuestPins()
    for i = 1, MAX_JOURNAL_QUESTS do
        self:RefreshSingleQuestPins(i)
    end
end

function CMapHandlers:RefreshZoneStory()
    RemoveMapZoneStoryPins()
    AddMapZoneStoryPins()
end

C_MAP_HANDLERS = CMapHandlers:New()

