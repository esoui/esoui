-- XML CONSTANTS
GAMEPAD_FQT_TEXT_MIN_ALPHA = 0.3
GAMEPAD_FQT_ANIMATION_FADE_IN_MS = 300
GAMEPAD_FQT_ANIMATION_FADE_OUT_MS = 2000

ZO_FocusedQuestTracker = ZO_Tracker:Subclass()

function ZO_FocusedQuestTracker:New(...)
    local tracker = ZO_Tracker.New(self, ...)
    tracker:InitializeFadeAnimations()
    tracker:RegisterCallbacks()
    tracker:ApplyPlatformStyle()
    FOCUSED_QUEST_TRACKER_FRAGMENT = ZO_HUDFadeSceneFragment:New(tracker.trackerPanel:GetNamedChild("Container"))
    return tracker
end

function ZO_FocusedQuestTracker:RegisterCallbacks()
    CALLBACK_MANAGER:RegisterCallback("GamepadChatSystemActiveOnScreen", function() self:TryFadeOut() end)
    QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", function() self:InitialTrackingUpdate() end)
    QUEST_TRACKER:RegisterCallback("QuestTrackerReactivate", function() self:TryFadeIn() end)
    self.trackerControl:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function ZO_FocusedQuestTracker:InitialTrackingUpdate()
    local numTracked = GetNumTracked()
    self:ClearTracker()
    for i=1, numTracked do
        local trackType, arg1, arg2 = GetTrackedByIndex(i)
        if(GetTrackedIsAssisted(trackType, arg1, arg2)) then
            if(trackType == TRACK_TYPE_QUEST) then
                self:BeginTracking(trackType, arg1)
            end      
            local header = self:GetHeaderForIndex(trackType, arg1, (arg2 ~= 0) and arg2 or nil)
            self:SetAssisted(header, true)
        end
    end
    self:UpdateAssistedVisibility()
    self:FireCallbacks("QuestTrackerInitialUpdate")
end

local function IsFocusQuestTrackerVisible()
    return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER)
end

function ZO_FocusedQuestTracker:UpdateVisibility()
    FOCUSED_QUEST_TRACKER_FRAGMENT:SetHiddenForReason("NoTrackedQuests", self:GetNumTracked() == 0, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
    FOCUSED_QUEST_TRACKER_FRAGMENT:SetHiddenForReason("DisabledBySetting", not IsFocusQuestTrackerVisible())
end

function ZO_FocusedQuestTracker:BeginTracking(trackType, arg1, arg2)
    if(self:IsOnTracker(trackType, arg1, arg2) or not GetTrackedIsAssisted(trackType, arg1, arg2)) then
        return     
    end
    
    local trackedData = ZO_TrackedData:New(trackType, arg1, arg2)
    
    --setup specific data
    if(trackType == TRACK_TYPE_QUEST) then
        trackedData.isComplete = GetJournalQuestIsComplete(arg1)
        trackedData.level = GetJournalQuestLevel(arg1)
    end
    
    table.insert(self.tracked, trackedData)
   
    --build visuals
    local header = nil
    if(trackType == TRACK_TYPE_QUEST) then
        header = self:AddQuest(trackedData)
    end
    
    if(header) then
        trackedData.header = header
        self:UpdateTreeView()
        self:UpdateVisibility()

        self:SetAssisted(header, true)
    end

    self.assistedQuestCompleted = false
    self:UpdateAssistedVisibility()

    self:FireCallbacks("QuestTrackerTrackingStateChanged", self, true, trackType, arg1, arg2)
end

function ZO_FocusedQuestTracker:OnQuestAdded(questIndex)
    ZO_Tracker.OnQuestAdded(self, questIndex)
    self:UpdateAssistedVisibility()
end

function ZO_FocusedQuestTracker:OnQuestRemoved(questIndex, completed)
    ZO_Tracker.OnQuestRemoved(self, questIndex, completed)
    self:UpdateAssistedVisibility()
end

function ZO_FocusedQuestTracker:StopTracking(trackType, arg1, arg2, completed)

end

function ZO_FocusedQuestTracker:SetTrackTypeAssisted(trackType, show, arg1, arg2)
    -- nothing
end

local APPLY_PLATFORM_CONSTANTS = true

function ZO_FocusedQuestTracker:OnQuestAssistStateChanged(unassistedData, assistedData)
    ZO_Tracker.OnQuestAssistStateChanged(self, unassistedData, assistedData, APPLY_PLATFORM_CONSTANTS)

    self:UpdateAssistedVisibility()
end

function ZO_FocusedQuestTracker:UpdateAssistedVisibility()
    self.assistedTexture:SetAlpha(GetNumJournalQuests() == 1 and 0 or 1)
end

function ZO_FocusedQuestTracker:RefreshQuestPins(journalIndex, tracked)
    self:FireCallbacks("QuestTrackerRefreshedMapPins", journalIndex)
end

function ZO_FocusedQuestTracker:ClearTracker()
    self.treeView:Clear()
    self.headerPool:ReleaseAllObjects()
    self.assistedTexture:SetHidden(true)
    
    self.tracked = {}   
    self.assistedData = nil
    self:UpdateTreeView() 
    self:UpdateVisibility()
end

function ZO_FocusedQuestTracker:GetContainerControl()
    return self.trackerControl
end

function ZO_FocusedQuestTracker:ApplyPlatformStyle()
    ZO_Tracker.ApplyPlatformStyle(self)
    ApplyTemplateToControl(self.assistedTexture, ZO_GetPlatformTemplate("ZO_KeybindButton"))
end

do
    local ANIMATION_HOLD_TIME_MS = 8000
    local FADE_OUT_OFFSET = GAMEPAD_FQT_ANIMATION_FADE_IN_MS + ANIMATION_HOLD_TIME_MS

    function ZO_FocusedQuestTracker:OnGamepadPreferredModeChanged()
        self:ApplyPlatformStyle()
    end

    local function OnFadeInAnimationStop(animation, control)
        control.isFaded = false
    end

    local function OnFadeOutAnimationStop(animation)
        animation.control.isFaded = true
        QUEST_TRACKER:SetFaded(true)
        CALLBACK_MANAGER:FireCallbacks("QuestTrackerFadedOutOnScreen")
    end

    local function SetupAnimationTimeline(control, fadeAnimationName, setHandlers)
        local fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(fadeAnimationName, control)
        local fadeInAnimation = fadeTimeline:GetAnimation(1)
        local fadeOutAnimation = fadeTimeline:GetAnimation(2)

        if setHandlers then
            fadeInAnimation:SetHandler("OnStop", OnFadeInAnimationStop)
            fadeTimeline:SetHandler("OnStop", OnFadeOutAnimationStop)
        end

        fadeTimeline:SetAnimationOffset(fadeOutAnimation, FADE_OUT_OFFSET)

        fadeTimeline.control = control
        control.fadeTimeline = fadeTimeline
    end

    function ZO_FocusedQuestTracker:InitializeFadeAnimations()
        local SET_FADE_HANDLERS = true
        SetupAnimationTimeline(self.trackerControl, "FocusedQuestTrackerFadeGamepad", SET_FADE_HANDLERS)
    end

    function ZO_FocusedQuestTracker:TryFadeOut()
        if self:IsOverlappingTextChat() then
            local trackerControl = self.trackerControl

            if FOCUSED_QUEST_TRACKER_FRAGMENT:IsShowing() then
                if not trackerControl.isFaded then
                    local fadeTimeline = trackerControl.fadeTimeline
                    fadeTimeline:Stop()
                    fadeTimeline:PlayFromStart(FADE_OUT_OFFSET)
                end
            else
                trackerControl:SetAlpha(GAMEPAD_FQT_TEXT_MIN_ALPHA)
            end
        end
    end

    function ZO_FocusedQuestTracker:TryFadeIn()
        QUEST_TRACKER:SetFaded(false)
        CALLBACK_MANAGER:FireCallbacks("QuestTrackerUpdatedOnScreen")
    end
end

do
    local function GetDimensions(control)
        local width, height = 0, 0
        -- Start at the second child control because the first is the Assisted Keybind Face Button
        for i = 2, control:GetNumChildren() do
            local child = control:GetChild(i)
            local childWidth, childHeight = child:GetTextDimensions()

            if childHeight ~= 0 then
                height = height + childHeight
            end

            if child.extraWidth then
                childWidth = childWidth + child.extraWidth
            end

            width = zo_max(width, childWidth)
        end

        return width, height
    end

    local MAX_HEIGHT_NO_COLLISION = 300

    function ZO_FocusedQuestTracker:IsOverlappingTextChat()
        local _, height = GetDimensions(self.trackerControl)
        return height > MAX_HEIGHT_NO_COLLISION
    end
end

function ZO_FocusedQuestTracker_OnInitialized(control)
    FOCUSED_QUEST_TRACKER = ZO_FocusedQuestTracker:New(control, control:GetNamedChild("Container"):GetNamedChild("QuestContainer"))
end