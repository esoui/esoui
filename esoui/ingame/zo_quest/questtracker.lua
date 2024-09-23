--Constants

local MOUSE_ENTER = 1
local MOUSE_EXIT = 2

local DEFAULT_STYLE = 1
local HINT_STYLE = 2

local QUEST_TRACKER_TREE_HEADER                 = 1
local QUEST_TRACKER_TREE_CONDITION              = 2
local QUEST_TRACKER_TREE_SUBCATEGORY_TITLE      = 3
local QUEST_TRACKER_TREE_SUBCATEGORY_CONDITION  = 4


--Style

local KEYBOARD_CONSTANTS =
{
    CONTAINER_ANCHOR_POINT = TOPLEFT,
    CONTAINER_ANCHOR_RELATIVE_POINT = BOTTOMLEFT,
    CONTAINER_OFFSET_X = 35,
    CONTAINER_OFFSET_Y = 5,

    QUEST_TIMER_ANCHOR_POINT = TOPLEFT,
    QUEST_TIMER_OFFSET_X = 10,
    QUEST_TIMER_OFFSET_Y = 0,

    FONT_HEADER = "ZoFontGameShadow",
    FONT_SUBCATEGORY = "ZoFontGameShadow",
    FONT_GENERAL = "ZoFontGameShadow",

    STEP_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_LEFT,
    CONDITION_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_LEFT,

    HEADER_INHERIT_ALPHA = true,
    TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_NONE,

    QUEST_LINE_BASE_WIDTH = 212,
    QUEST_LINE_HEADER_WIDTH = 222,
    QUEST_LINE_HEADER_ICON_WIDTH_AND_HEIGHT = 22,
    QUEST_TRACKER_TREE_INDENT = 10,
    QUEST_TRACKER_TREE_ANCHOR_POINT = TOPLEFT,
    QUEST_TRACKER_TREE_RELATIVE_POINT = BOTTOMLEFT,

    QUEST_TRACKER_TREE_LINE_SPACING = {
        [QUEST_TRACKER_TREE_HEADER] = 18,
        [QUEST_TRACKER_TREE_CONDITION] = 2,
        [QUEST_TRACKER_TREE_SUBCATEGORY_TITLE] = 2,
        [QUEST_TRACKER_TREE_SUBCATEGORY_CONDITION] = 2,
    },

    QUEST_TRACKER_TREE_SUBCATEGORY_VERTICAL_ALIGNMENT = TEXT_ALIGN_TOP,

    ASSISTED_TEXTURE_ANCHOR_POINT = TOPRIGHT,
    ASSISTED_TEXTURE_RELATIVE_POINT = TOPLEFT,
    ASSISTED_TEXTURE_OFFSET_X = 0,
    ASSISTED_TEXTURE_OFFSET_Y = -7,

    HIDE_HEADER_TEXTURES = true,
}

local GAMEPAD_CONSTANTS =
{
    CONTAINER_ANCHOR_POINT = TOPRIGHT,
    CONTAINER_ANCHOR_RELATIVE_POINT = BOTTOMRIGHT,
    CONTAINER_OFFSET_X = -44,
    CONTAINER_OFFSET_Y = 15,

    QUEST_TIMER_ANCHOR_POINT = TOPRIGHT,
    QUEST_TIMER_OFFSET_X = 29,
    QUEST_TIMER_OFFSET_Y = 0,

    FONT_HEADER = "ZoFontGamepadBold27",
    FONT_SUBCATEGORY = "ZoFontGamepadBold22",
    FONT_GENERAL = "ZoFontGamepad34",

    STEP_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_RIGHT,
    CONDITION_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_RIGHT,

    HEADER_INHERIT_ALPHA = false,
    TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,

    QUEST_LINE_BASE_WIDTH = 350,

    QUEST_LINE_HEADER_ICON_WIDTH_AND_HEIGHT = 48,
    QUEST_HEADER_BASE_HEIGHT = 28,
    QUEST_TRACKER_TREE_INDENT = 0,
    QUEST_TRACKER_TREE_ANCHOR_POINT = TOPRIGHT,
    QUEST_TRACKER_TREE_RELATIVE_POINT = BOTTOMRIGHT,
    QUEST_TRACKER_TREE_SUBCATEGORY_VERTICAL_ALIGNMENT = TEXT_ALIGN_BOTTOM,

    QUEST_TRACKER_TREE_LINE_SPACING = {
        [QUEST_TRACKER_TREE_HEADER] = 0,
        [QUEST_TRACKER_TREE_CONDITION] = 16,
        [QUEST_TRACKER_TREE_SUBCATEGORY_TITLE] = 16,
        [QUEST_TRACKER_TREE_SUBCATEGORY_CONDITION] = 6,
    },

    QUEST_TRACKER_EXTRA_STEP_OFFSET_Y = 6,

    ASSISTED_TEXTURE_ANCHOR_POINT = RIGHT,
    ASSISTED_TEXTURE_RELATIVE_POINT = LEFT,
    ASSISTED_TEXTURE_OFFSET_X = -5,
    ASSISTED_TEXTURE_OFFSET_Y = 5,

    HIDE_HEADER_TEXTURES = false,

    DISTANCE_BUTTON_TO_HEADER = 45,
}

local function ApplyStyle(label, style)
    if style == HINT_STYLE then
        label:SetColor(ZO_HINT_TEXT:UnpackRGBA())
    elseif style == DEFAULT_STYLE then
        label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end
end

local function GetPlatformConstants()
    return IsInGamepadPreferredMode() and GAMEPAD_CONSTANTS or KEYBOARD_CONSTANTS
end

local function ApplyPlatformStyleToHeader(control)
    local constants = GetPlatformConstants()

    control:ClearAnchors()
    control:SetDimensions(constants.QUEST_LINE_HEADER_WIDTH, constants.QUEST_HEADER_BASE_HEIGHT)
    control.icon:SetDimensions(constants.QUEST_LINE_HEADER_ICON_WIDTH_AND_HEIGHT, constants.QUEST_LINE_HEADER_ICON_WIDTH_AND_HEIGHT)
    control:SetFont(constants.FONT_HEADER)
    control:SetModifyTextType(constants.TEXT_TYPE_HEADER)
    --Text needs to be reset on the text type changing
    if control.headerText then
        control:SetText(control.headerText)
    end
    control:SetInheritAlpha(constants.HEADER_INHERIT_ALPHA)

    -- control.instanceDisplayType is deprecated, included here for addon backwards compatibility
    local displayType = control.displayType or control.instanceDisplayType
    if control.questType or displayType then
        local icon = control.icon
        local questJournalObject = SYSTEMS:GetObject("questJournal")
        local iconTexture = questJournalObject:GetIconTexture(control.questType, displayType)
        icon:SetTexture(iconTexture)
    end

    if control.m_TreeNode then
        control.m_TreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[QUEST_TRACKER_TREE_HEADER])
    end

    control.extraWidth = constants.DISTANCE_BUTTON_TO_HEADER 
end

local UNCONSTRAINED_HEIGHT = 0

local function ApplyPlatformStyleToCondition(control)
    local constants = GetPlatformConstants()
    control:SetDimensions(constants.QUEST_LINE_BASE_WIDTH, UNCONSTRAINED_HEIGHT)
    control:SetFont(constants.FONT_GENERAL)
    control:SetHorizontalAlignment(constants.CONDITION_HORIZONTAL_ALIGNMENT)
    if control.m_TreeNode then
        control.m_TreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[control.entryType])
    end
end

local function ApplyPlatformStyleToStepDescription(control)
    local constants = GetPlatformConstants()
    control:SetDimensions(constants.QUEST_LINE_BASE_WIDTH, UNCONSTRAINED_HEIGHT)
    control:SetFont(constants.FONT_SUBCATEGORY)
    control:SetVerticalAlignment(constants.QUEST_TRACKER_TREE_SUBCATEGORY_VERTICAL_ALIGNMENT)
    control:SetHorizontalAlignment(constants.STEP_HORIZONTAL_ALIGNMENT)
    if control.m_TreeNode then
        control.m_TreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[QUEST_TRACKER_TREE_SUBCATEGORY_TITLE])
    end
end

local function ApplyPlatformStyleToAssistedTexture(assistedTexture, assistedHeader)
    local constants = GetPlatformConstants()
    assistedTexture:ClearAnchors()
    local targetRelativeTo = assistedHeader
    if assistedHeader.isUsingIcon then
        targetRelativeTo = assistedHeader.icon
    end
    assistedTexture:SetAnchor(constants.ASSISTED_TEXTURE_ANCHOR_POINT, targetRelativeTo, constants.ASSISTED_TEXTURE_RELATIVE_POINT, constants.ASSISTED_TEXTURE_OFFSET_X, constants.ASSISTED_TEXTURE_OFFSET_Y)
    assistedTexture:SetInheritAlpha(constants.HEADER_INHERIT_ALPHA)
end

--
-- Tracked Data
--

ZO_TrackedData = ZO_Object:Subclass()

function ZO_TrackedData:New(trackType, arg1, arg2)
    local data = ZO_Object.New(self)
    
    data.trackType = trackType
    data.arg1 = arg1
    data.arg2 = arg2
    
    return data
end

function ZO_TrackedData:GetJournalIndex()
    return (self.trackType == TRACK_TYPE_QUEST and self.arg1) or nil
end

function ZO_TrackedData:Equals(trackType, arg1, arg2)
    return (self.trackType == trackType and self.arg1 == arg1 and self.arg2 == arg2)
end

function ZO_TrackedData:EqualsTrackedData(trackedData)
    if trackedData == nil then
        return false
    end
    return (self.trackType == trackedData.trackType and self.arg1 == trackedData.arg1 and self.arg2 == trackedData.arg2)
end

--
-- Tracker
--        

ZO_Tracker = ZO_CallbackObject:Subclass()

function ZO_Tracker:New(...)
    local tracker = ZO_CallbackObject.New(self)
    tracker:Initialize(...)
    return tracker
end

function ZO_Tracker:Initialize(trackerPanel, trackerControl)
    local stepDescriptionResetFunction = function(control)
                                            control:SetText("")
                                            control.m_TreeNode = nil
                                         end

    local conditionResetFunction =  function(control)
                                        control:SetText("")
                                        control.isGroupCreditShared = false
                                        control.m_TreeNode = nil
                                    end
    
    local headerResetFunction = function(control)
                                    if control.m_ChildConditionControls then
                                        self:RemoveAndReleaseConditionsFromHeader(control)
                                    end

                                    if control.m_StepDescriptionControls then
                                        for _, stepControl in ipairs(control.m_StepDescriptionControls) do
                                            self.stepDescriptionPool:ReleaseObject(stepControl.key)
                                            self.treeView:RemoveNode(stepControl.treeNode)
                                        end
                                    end

                                    control:SetText("")
                                    control.m_StepDescriptionControls = nil
                                    control.m_BGStorage = nil
                                    control.m_TreeNode = nil
                                    control.headerText = nil
                                    control.questType = nil
                                    -- control.instanceDisplayType is deprecated, included here for addon backwards compatibility
                                    control.instanceDisplayType = nil
                                    control.displayType = nil
                                end

    trackerControl:GetParent().tracker = self
    self.trackerControl = trackerControl
    self.trackerPanel = trackerPanel
    self.timerControl = GetControl(trackerPanel, "TimerAnchor")
    
    self.headerPool = ZO_ControlPool:New("ZO_TrackedHeader", trackerControl, "TrackedHeader")
    self.conditionPool = ZO_ControlPool:New("ZO_QuestCondition", trackerControl, "QuestCondition")
    self.stepDescriptionPool = ZO_ControlPool:New("ZO_QuestStepDescription", trackerControl, "QuestStepDescription")

    self.headerPool:SetCustomResetBehavior(headerResetFunction)
    self.conditionPool:SetCustomResetBehavior(conditionResetFunction)
    self.stepDescriptionPool:SetCustomResetBehavior(stepDescriptionResetFunction)

    self.headerPool:SetCustomAcquireBehavior(ApplyPlatformStyleToHeader)
    self.conditionPool:SetCustomAcquireBehavior(ApplyPlatformStyleToCondition)
    self.stepDescriptionPool:SetCustomAcquireBehavior(ApplyPlatformStyleToStepDescription)

    self:CreatePlatformAnchors()
    
    local constants = GetPlatformConstants()
    self.treeView = ZO_TreeControl:New(constants.QUEST_TRACKER_TREE_ANCHOR, constants.QUEST_TRACKER_TREE_INDENT)
    
    self.tracked = {}
    self.MAX_TRACKED = 1 -- never allow more than this many quests...this is only controlled by the UI, not the client
    self.isMouseInside = false
    self.assistedTexture = GetControl(trackerControl, "Assisted")

    local function OnAddOnLoaded(eventCode, addOnName)
        if addOnName == "ZO_Ingame" then
            self:UpdateVisibility()

            local function OnInterfaceSettingChanged(eventCode, settingType, settingId)
                if settingType == SETTING_TYPE_UI then
                    if settingId == UI_SETTING_SHOW_QUEST_TRACKER then
                        self:UpdateVisibility()
                    end
                end
            end

            trackerPanel:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)

            local function OnZoneStoryQuestActivityTracked(eventId, questIndex)
                self:ForceAssist(questIndex)
                ZO_WorldMap_ShowQuestOnMap(questIndex)
            end

            trackerPanel:RegisterForEvent(EVENT_ZONE_STORY_QUEST_ACTIVITY_TRACKED, OnZoneStoryQuestActivityTracked)

            trackerPanel:RegisterForEvent(EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(_, index) self:OnQuestConditionUpdated(index) end)
            trackerPanel:RegisterForEvent(EVENT_QUEST_CONDITION_OVERRIDE_TEXT_CHANGED, function(_, index) self:OnQuestConditionUpdated(index) end)
            trackerPanel:RegisterForEvent(EVENT_QUEST_ADVANCED, function(_, questIndex, questName, isPushed, isComplete, mainStepChanged) self:OnQuestAdvanced(questIndex, questName, isPushed, isComplete, mainStepChanged) end)
            trackerPanel:RegisterForEvent(EVENT_QUEST_ADDED, function(_, questIndex) self:OnQuestAdded(questIndex) end)
            trackerPanel:RegisterForEvent(EVENT_QUEST_REMOVED, function(_, completed, questIndex, questName, zoneIndex, poiIndex, questID) self:OnQuestRemoved(questIndex, completed, questID) end)
            trackerPanel:RegisterForEvent(EVENT_LEVEL_UPDATE, function(_, tag, level) self:OnLevelUpdated(tag) end)
            trackerPanel:RegisterForEvent(EVENT_TRACKING_UPDATE, function() self:OnTrackingUpdate() end)

            trackerPanel:UnregisterForEvent(EVENT_ADD_ON_LOADED)

            self:InitialTrackingUpdate()
        end
    end

    trackerPanel:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    self:RegisterCallbacks()
    self:ApplyPlatformStyle()

    self.fragment = ZO_HUDFadeSceneFragment:New(self.trackerPanel:GetNamedChild("Container"))
    self.fragment:RegisterCallback("StateChange", function(oldState, newState) self:FireCallbacks("QuestTrackerFragmentStateChange", oldState, newState) end)

    FOCUSED_QUEST_TRACKER_FRAGMENT = self:GetFragment()
end

function ZO_Tracker:GetFragment()
    return self.fragment
end

function ZO_Tracker:RegisterCallbacks()
    self.trackerControl:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function ZO_Tracker:GetContainerControl()
    return self.trackerControl
end

function ZO_Tracker:CreatePlatformAnchors()
    local allConstants = { KEYBOARD_CONSTANTS, GAMEPAD_CONSTANTS }

    for _, constants in ipairs(allConstants) do
        constants.QUEST_TRACKER_TREE_ANCHOR = ZO_Anchor:New(constants.QUEST_TRACKER_TREE_ANCHOR_POINT, self.trackerControl, constants.QUEST_TRACKER_TREE_ANCHOR_POINT)
        constants.CONTAINER_ANCHOR = ZO_Anchor:New(constants.CONTAINER_ANCHOR_POINT, self.timerControl, constants.CONTAINER_ANCHOR_RELATIVE_POINT, constants.CONTAINER_OFFSET_X, constants.CONTAINER_OFFSET_Y)
        constants.QUEST_TIMER_ANCHOR = ZO_Anchor:New(constants.QUEST_TIMER_ANCHOR_POINT, self.trackerPanel, constants.QUEST_TIMER_ANCHOR_POINT, constants.QUEST_TIMER_OFFSET_X, constants.QUEST_TIMER_OFFSET_Y) 
    end
end

function ZO_Tracker:ApplyPlatformStyle()
    local constants = GetPlatformConstants()

    -- Reanchor quest timer
    self.timerControl:ClearAnchors()
    constants.QUEST_TIMER_ANCHOR:AddToControl(self.timerControl)

    -- Reanchor the container
    self.trackerControl:ClearAnchors()
    constants.CONTAINER_ANCHOR:AddToControl(self.trackerControl)

    -- Set the correct style for the controls
    local header = self.headerPool:GetActiveObjects()
    for _, headerEntry in pairs(header) do
        ApplyPlatformStyleToHeader(headerEntry)
    end

    local conditions = self.conditionPool:GetActiveObjects()
    for _, conditionEntry in pairs(conditions) do
        ApplyPlatformStyleToCondition(conditionEntry)
    end

    local stepDescriptions = self.stepDescriptionPool:GetActiveObjects()
    for _, stepDescriptionEntry in pairs(stepDescriptions) do
        ApplyPlatformStyleToStepDescription(stepDescriptionEntry)
    end

    -- Anchor the face button
    local assistedData = self.assistedData
    if assistedData then
        local assistedHeader = self:GetHeaderForIndex(assistedData.trackType, assistedData.arg1, assistedData.arg2)
        ApplyPlatformStyleToAssistedTexture(self.assistedTexture, assistedHeader)
    end

    -- Update the quest tree anchors
    self.treeView:SetIndent(constants.QUEST_TRACKER_TREE_INDENT)
    self.treeView:SetRelativePoint(constants.QUEST_TRACKER_TREE_RELATIVE_POINT)
    self:UpdateTreeView()

    ApplyTemplateToControl(self.assistedTexture, ZO_GetPlatformTemplate("ZO_KeybindButton"))
end

function ZO_Tracker:UpdateAssistedVisibility()
    self.assistedTexture:SetAlpha(GetNumJournalQuests() == 1 and 0 or 1)
end

function ZO_Tracker:OnTrackingUpdate()
    --Received when we get new tracking data from the server. Even if we were initialized we need to re-init.
    self.initialized = false
    self:InitialTrackingUpdate()
end

function ZO_Tracker:InitialTrackingUpdate()
    if not self.initialized and IsTrackingDataAvailable() then
        self.initialized = true

        local previouslyAssistedQuestIndex
        for i = 1, GetNumJournalQuests() do
            if GetTrackedIsAssisted(TRACK_TYPE_QUEST, i) then
                previouslyAssistedQuestIndex = i
                break
            end
        end

        self:ClearTracker()
    
        self.disableAudio = true
        if previouslyAssistedQuestIndex == nil or not self:BeginTracking(TRACK_TYPE_QUEST, previouslyAssistedQuestIndex) then
            local IGNORE_SCENE_RESTRICTION = true
            self:AssistNext(IGNORE_SCENE_RESTRICTION)
        end
        self.disableAudio = false

        self:UpdateAssistedVisibility()
        self:FireCallbacks("QuestTrackerInitialUpdate")
    end
end

function ZO_Tracker:SetEnabled(enabled)
    self.enabled = enabled
    self:UpdateVisibility()
end

function ZO_Tracker:UpdateVisibility()
    local numTrackedQuests = self:GetNumTracked()
    FOCUSED_QUEST_TRACKER_FRAGMENT:SetHiddenForReason("NoTrackedQuests", numTrackedQuests == 0, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)

    local isTrackerVisible = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER)
    FOCUSED_QUEST_TRACKER_FRAGMENT:SetHiddenForReason("DisabledBySetting", not isTrackerVisible, 0, 0)
end

function ZO_Tracker:ForceAssist(questIndex)
    self:BeginTracking(TRACK_TYPE_QUEST, questIndex)
end

function ZO_Tracker:AssistAnotherQuestWithTheSameQuestJournalCategory(questId)
    self.disableAudio = true
    local nextQuestToAssist = QUEST_JOURNAL_MANAGER:FindQuestWithSameCategoryAsCompletedQuest(questId)
    if not self:BeginTracking(TRACK_TYPE_QUEST, nextQuestToAssist) then
        --Even if we can't find a quest in the same quest journal category to, let's assist whatever other quests we might have in the journal instead
        local IGNORE_SCENE_RESTRICTION = true
        self:AssistNext(IGNORE_SCENE_RESTRICTION)
    end
    self.disableAudio = false
end

function ZO_Tracker:AssistNext(ignoreSceneRestriction)
    local isShowingBase = SCENE_MANAGER:IsShowingBaseScene()
    
    local wasZoneStoryAssisted = IsZoneStoryAssisted()
    if wasZoneStoryAssisted then
        ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted(false)
    end

    if ignoreSceneRestriction or isShowingBase then
        --if we are showing one quest now, find the next one to show ordered by the order they appear in the quest journal
        if self.assistedData then
            local nextQuestIndex, wasShowingLastQuest = QUEST_JOURNAL_MANAGER:GetNextSortedQuestForQuestIndex(self.assistedData.arg1)
            if wasShowingLastQuest then
                -- Looped past all the quests.  Check if we want to display a zone guide before displaying the first item.
               
                -- if the zone story was visible and we just closed it, don't reopen it.
                if not wasZoneStoryAssisted and IsZoneStoryTracked() then
                    ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted(true)
                    if not self.disableAudio then
                        PlaySound(SOUNDS.QUEST_FOCUSED)
                    end
                    return -- Don't advance the quest now, wait for the zone tracker to be hidden.
                end
            end

            if nextQuestIndex then
                if self:BeginTracking(TRACK_TYPE_QUEST, nextQuestIndex) then
                    CALLBACK_MANAGER:FireCallbacks("QuestTrackerUpdatedOnScreen")
                    return
                end
            end
        end

        --if we aren't showing any quest look for some quest to show
        for i = 1, MAX_JOURNAL_QUESTS do
            if IsValidQuestIndex(i) then
                if self:BeginTracking(TRACK_TYPE_QUEST, i) then
                    CALLBACK_MANAGER:FireCallbacks("QuestTrackerUpdatedOnScreen")
                    break
                end
            end
        end
    end
end

--
-- Header Management
--

function ZO_Tracker:CreateQuestHeader(data, questName, questType, isComplete, zoneDisplayType)
    local questHeader, questHeaderKey = self.headerPool:AcquireObject()
    
    local treeNode = self.treeView:AddChild(nil, questHeader)
    local constants = GetPlatformConstants()
    treeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[QUEST_TRACKER_TREE_HEADER])
    
    questHeader.m_TimerSlot = nil
    questHeader.m_Data = data
    questHeader.m_TreeNode = treeNode
    questHeader.m_ObjectKey = questHeaderKey
    questHeader.m_ChildConditionControls = {}           -- Stores interleaved ZO_QuestCondition/objectKey pairs in an array table (no nesting)
                                                        -- so that the child conditions can be correctly released when 
                                                        -- no longer tracking this quest
    questHeader.m_StepDescriptionControls = {}

    self:InitializeQuestHeader(questName, questType, questHeader, isComplete, zoneDisplayType)

    return questHeader, treeNode
end

function ZO_Tracker:InitializeQuestHeader(questName, questType, questHeader, isComplete, zoneDisplayType)
    questHeader:SetColor(GetConColor(questHeader.m_Data.level))
    questHeader:SetText(questName)
    -- add icon here
    local icon = questHeader.icon
    local questJournalObject = SYSTEMS:GetObject("questJournal")
    local iconTexture = questJournalObject:GetIconTexture(questType, zoneDisplayType)
    if iconTexture then
        icon:SetTexture(iconTexture)
        icon:SetHidden(false)
        questHeader.isUsingIcon = true
    else
        icon:SetHidden(true)
        questHeader.isUsingIcon = false
    end

    --save the text and icon data off so it can be easily reset on the style changing
    questHeader.headerText = questName
    questHeader.questType = questType
    -- questHeader.instanceDisplayType is deprecated, included here for addon backwards compatibility
    questHeader.instanceDisplayType = zoneDisplayType
    questHeader.displayType = zoneDisplayType
end

function ZO_Tracker:InitializeQuestCondition(questCondition, parentQuestHeader, questConditionKey, treeNode)
    table.insert(parentQuestHeader.m_ChildConditionControls, questCondition)
    table.insert(parentQuestHeader.m_ChildConditionControls, questConditionKey)
    
    questCondition.m_TreeNode = treeNode
    
    -- HACK?  Unsure of why this is needed, but it prevents the condition from flickering between
    -- shown and hidden when the tracked quest's tree node is collapsed.  The conditions are all
    -- shown properly when the tree node's expanded state is toggled.
    questCondition:SetHidden(parentQuestHeader.m_TreeNode:IsExpanded() == false)
end

local function InsertStepDescription(questTracker, questHeader, treeNode, text, style)
    local stepDescription, stepDescriptionKey = questTracker.stepDescriptionPool:AcquireObject()
    stepDescription:SetText(text)
    local constants = GetPlatformConstants()
    ApplyStyle(stepDescription, style)
    local stepDescriptionTreeNode = questTracker.treeView:AddChild(treeNode, stepDescription)
    stepDescription.m_TreeNode = stepDescriptionTreeNode
    stepDescriptionTreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[QUEST_TRACKER_TREE_SUBCATEGORY_TITLE])
    table.insert(questHeader.m_StepDescriptionControls, {control = stepDescription, key = stepDescriptionKey, treeNode = stepDescriptionTreeNode} )	
end

function ZO_Tracker:PopulateStepQuestConditions(questIndex, stepIndex, questHeader, treeNode, desiredVisibility, entryType)
    local _, visibility, stepType, stepOverrideText, conditionCount = GetJournalQuestStepInfo(questIndex, stepIndex)

    if((desiredVisibility ~= nil) and (desiredVisibility ~= visibility)) then
        return
    end

    local isOptionalStep = (stepIndex > 1)
    local style = DEFAULT_STYLE
    if visibility == QUEST_STEP_VISIBILITY_HINT then
        style = HINT_STYLE
    end
    
    -- Don't display endings of optional quest lines
    if(isOptionalStep) then
        if(stepType == QUEST_STEP_TYPE_END) then
            return
        else
            if(not questHeader.m_hasAddedSectionHeader) then
                questHeader.m_hasAddedSectionHeader = true
                
                if visibility == QUEST_STEP_VISIBILITY_HINT then
                    InsertStepDescription(self, questHeader, treeNode, GetString(SI_QUEST_HINT_STEP_HEADER), style)
                elseif visibility == QUEST_STEP_VISIBILITY_OPTIONAL then
                    InsertStepDescription(self, questHeader, treeNode, GetString(SI_QUEST_OPTIONAL_STEPS_DESCRIPTION), style)
                end
            end
        end
    end
    
    local constants = GetPlatformConstants()
        
    if(stepOverrideText ~= "") then
        -- Step override text condition
        local stepOverride, stepOverrideKey = self.conditionPool:AcquireObject()
        stepOverride.entryType = entryType
        
        if(stepType ~= QUEST_STEP_TYPE_END) then
            -- A step type of OR is implied here...it's not legal to have an AND step with override text.
            -- Do a quick check to see if any of the conditions have been completed to determine the icon type.
            
            for conditionIndex = 1, conditionCount do
                local currentValue, maximumValue, isFailCondition, isComplete, isGroupCreditShared = GetJournalQuestConditionValues(questIndex, stepIndex, conditionIndex)
                -- We're going to ignore the individual conditions' isVisible field here, since we have override text for the whole step which we always want to show

                if(not isFailCondition and isComplete) then
                    stepOverride.isGroupCreditShared = isGroupCreditShared
                    break -- done, at least one non-fail condition was complete
                end
            end
        end

        if visibility == QUEST_STEP_VISIBILITY_HINT then
            stepOverride:SetText(zo_strformat(SI_QUEST_HINT_STEP_FORMAT, stepOverrideText))
        else
            stepOverride:SetText(stepOverrideText)
        end

        ApplyStyle(stepOverride, style)

        --we don't hide complete override conditions. there is only one override line, so if it is complete, either:
        --1) the quest advances and it's gone anyway
        --2) it's an end step, so we need to show it until the quest is turned in
        local conditionTreeNode = self.treeView:AddChild(treeNode, stepOverride)
        stepOverride.m_TreeNode = conditionTreeNode
        conditionTreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[entryType])
        self:InitializeQuestCondition(stepOverride, questHeader, stepOverrideKey, conditionTreeNode)
    else
        -- Process the conditions as usual
        if(stepType == QUEST_STEP_TYPE_OR) then
            local visibleConditionFound = false
            for conditionIndex = 1, conditionCount do
                local isVisible = select(7, GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex))
                if isVisible then
                    if visibleConditionFound then
                        -- We've already found one visible condition, insert the "Choose one" step description and quit
                        InsertStepDescription(self, questHeader, treeNode, GetString(SI_QUEST_OR_DESCRIPTION))		
                        break
                    else
                        visibleConditionFound = true
                    end
                end
            end
        end

        for conditionIndex = 1, conditionCount do
            local conditionText, curCount, maxCount, isFailCondition, isComplete, isGroupCreditShared, isVisible = GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex)

            if((not isFailCondition) and (conditionText ~= "") and not isComplete and isVisible) then
                local questCondition, questConditionKey = self.conditionPool:AcquireObject()
                questCondition.entryType = entryType

                questCondition.isGroupCreditShared = isGroupCreditShared

                if visibility == QUEST_STEP_VISIBILITY_HINT then
                    questCondition:SetText(zo_strformat(SI_QUEST_HINT_STEP_FORMAT, conditionText))
                elseif stepType == QUEST_STEP_TYPE_OR then
                    questCondition:SetText(zo_strformat(SI_QUEST_OR_CONDITION_FORMAT, conditionText))
                else
                    questCondition:SetText(conditionText)
                end

                ApplyStyle(questCondition, style)

                local conditionTreeNode = self.treeView:AddChild(treeNode, questCondition)
                questCondition.m_TreeNode = conditionTreeNode
                conditionTreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[entryType])
                self:InitializeQuestCondition(questCondition, questHeader, questConditionKey, conditionTreeNode)
            end
        end
    end
end

function ZO_Tracker:PopulateOptionalStepQuestConditionsForVisibility(questIndex, questHeader, treeNode, desiredVisibility, entryType)
    for stepIndex = QUEST_MAIN_STEP_INDEX + 1, GetJournalQuestNumSteps(questIndex) do
        self:PopulateStepQuestConditions(questIndex, stepIndex, questHeader, treeNode, desiredVisibility, entryType)
    end
    questHeader.m_hasAddedSectionHeader = nil
end

function ZO_Tracker:PopulateQuestConditions(questIndex, questName, stepType, stepTrackerText, isComplete, tracked, questHeader, treeNode)
    self:PopulateStepQuestConditions(questIndex, QUEST_MAIN_STEP_INDEX, questHeader, treeNode, nil, QUEST_TRACKER_TREE_CONDITION)
    self:PopulateOptionalStepQuestConditionsForVisibility(questIndex, questHeader, treeNode, QUEST_STEP_VISIBILITY_OPTIONAL, QUEST_TRACKER_TREE_SUBCATEGORY_CONDITION)
    self:PopulateOptionalStepQuestConditionsForVisibility(questIndex, questHeader, treeNode, QUEST_STEP_VISIBILITY_HINT, QUEST_TRACKER_TREE_SUBCATEGORY_CONDITION)
end

function ZO_Tracker:RebuildConditions(questIndex, questHeader, questName, stepType, stepTrackerText, isComplete, tracked)
    if(questHeader == nil) then
        questHeader = self:GetHeaderForIndex(TRACK_TYPE_QUEST, questIndex)
    end

    if(questName == nil) then
        local _
        questName, _, _, stepType, stepTrackerText, isComplete, tracked = GetJournalQuestInfo(questIndex)
    end

    if(questHeader and questName) then
        if(questHeader.m_ChildConditionControls) then
            -- first thing...remove all conditions from the tree...
            self:RemoveAndReleaseConditionsFromHeader(questHeader)
           
            -- then reset the condition table to an empty table
            questHeader.m_ChildConditionControls = {}
        end

        if(questHeader.m_StepDescriptionControls) then
            for _, control in ipairs(questHeader.m_StepDescriptionControls) do
                self.stepDescriptionPool:ReleaseObject(control.key)
                self.treeView:RemoveNode(control.treeNode)
            end
            
            questHeader.m_StepDescriptionControls = {}
        end

        -- then populate the conditions correctly
        self:PopulateQuestConditions(questIndex, questName, stepType, stepTrackerText, isComplete, tracked, questHeader, questHeader.m_TreeNode)

        if(questHeader.m_TreeNode:IsExpanded()) then
            self:UpdateTreeView()
        end
    end
end

function ZO_Tracker:RefreshHeaderConColors()
    local activeObjects = self.headerPool:GetActiveObjects()

    for _, questHeader in pairs(activeObjects) do
        questHeader:SetColor(GetConColor(questHeader.m_Data.level))
    end
end

function ZO_Tracker:RemoveAndReleaseConditionsFromHeader(questHeader)
    local childConditions = questHeader.m_ChildConditionControls
    local condition
    local owningTree = questHeader.m_TreeNode:GetOwningTree()
    
    for i = 1, #childConditions, 2 do
        -- NOTE: The childConditions include the timer if the quest was timed.
        -- It should be the first condition if it was present.
        
        -- [i] = control, [i + 1] = controlKey
        condition = childConditions[i]
        
        condition:SetHidden(true)
        condition:SetHandler("OnUpdate", nil)
        owningTree:RemoveNode(condition.m_TreeNode)
        self.conditionPool:ReleaseObject(childConditions[i + 1])
    end

    questHeader.m_ChildConditionControls = nil
    
    -- Reset any timer data...because timers are tracked like conditions, their tree nodes and pool objects
    -- have already been properly released, but the references to those objects on this quest header also need
    -- to be reset.
    questHeader.m_TimerSlot = nil
    questHeader.m_TimerKey = nil
end

--
--Events
--

function ZO_Tracker:OnQuestConditionUpdated(questIndex)
    if self:IsOnTracker(TRACK_TYPE_QUEST, questIndex) then
        self:RebuildConditions(questIndex)
    end
end

function ZO_Tracker:OnQuestAdded(questIndex)
    if self:GetNumTracked() == 0 or GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_AUTOMATIC_QUEST_TRACKING) then
        self:BeginTracking(TRACK_TYPE_QUEST, questIndex)
    end
    self:UpdateAssistedVisibility()
end

function ZO_Tracker:OnQuestRemoved(questIndex, completed, questId)
    if GetIsTrackedForContentId(TRACK_TYPE_QUEST, questId) then
        local DONT_UPDATE_VISIBILITY = false
        --Wait to see if we assist something to replace this before updating visibility
        self:StopTracking(TRACK_TYPE_QUEST, questIndex, nil, DONT_UPDATE_VISIBILITY)
        self:AssistAnotherQuestWithTheSameQuestJournalCategory(questId)
        self:UpdateVisibility()
    end
    self:UpdateAssistedVisibility()
end

function ZO_Tracker:OnQuestAdvanced(questIndex, questName, isPushed, isComplete, mainStepChanged)
    if self:IsOnTracker(TRACK_TYPE_QUEST, questIndex) then
        self:SetTrackedQuestComplete(questIndex, isComplete)
        
        local questHeader = self:GetHeaderForIndex(TRACK_TYPE_QUEST, questIndex)
        if questHeader then
            local questType = GetJournalQuestType(questIndex)
            local zoneDisplayType = GetJournalQuestZoneDisplayType(questIndex)
            self:InitializeQuestHeader(questName, questType, questHeader, isComplete, zoneDisplayType)
        end
        
        self:RebuildConditions(questIndex)
    end
end

function ZO_Tracker:OnLevelUpdated(tag)
    if(tag == "player") then
        self:RefreshHeaderConColors()
    end
end

--
-- Query
--

function ZO_Tracker:GetHeaderForIndex(trackType, arg1, arg2)
    local headerList = self.headerPool:GetActiveObjects()
   
    for k, header in pairs(headerList) do
        if header.m_Data:Equals(trackType, arg1, arg2) then
            return header
        end
    end
    
    return nil
end

function ZO_Tracker:GetNumTracked()
    return #self.tracked
end

function ZO_Tracker:IsFull()
    return self:GetNumTracked() >= self.MAX_TRACKED
end

function ZO_Tracker:GetTrackedByIndex(index)
    return self.tracked[index]
end

function ZO_Tracker:GetLastTracked()
    local count = #self.tracked

    if count > 0 then
        return self.tracked[count]
    end

    return nil
end

--
-- Tracking
--

function ZO_Tracker:IsTrackTypeAssisted(trackType, arg1, arg2)
    return GetTrackedIsAssisted(trackType, arg1, arg2)
end

function ZO_Tracker:SetTrackTypeAssisted(trackType, show, arg1, arg2)
    SetTrackedIsAssisted(trackType, show, arg1, arg2)
    if trackType == TRACK_TYPE_QUEST then
        if show and not self.disableAudio then
            PlaySound(SOUNDS.QUEST_FOCUSED)
        end
    end
end

function ZO_Tracker:GetTrackingIndex(trackType, arg1, arg2)
    -- This is used to compute the Lua-assigned value for the tracker index.  
    -- This logic needs to be run after quests are:
    -- 1. Added to the tracker
    -- 2. Removed from the tracker
    -- 3. Advanced because the player has done part of a quest
    -- 4. Abandoned
    -- 5. Completed
    
    for i = 1, #self.tracked do
        local trackedData = self.tracked[i]
        
        if trackedData:Equals(trackType, arg1, arg2) then
            return i
        end
    end

    return nil
end

function ZO_Tracker:SetTrackedQuestComplete(questIndex, isComplete)
    for i = 1, #self.tracked do
        local trackedData = self.tracked[i]
        
        if(trackedData.trackType == TRACK_TYPE_QUEST) then
            -- Found the quest, mark it complete.
            if trackedData:GetJournalIndex() == questIndex then
                trackedData.isComplete = isComplete
                return
            end
        end
    end
end

function ZO_Tracker:IsOnTracker(trackType, arg1, arg2)
    for i = 1, #self.tracked do
        local trackedData = self.tracked[i]
        if trackedData:Equals(trackType, arg1, arg2) then
            return true
        end
    end
    
    return false
end

function ZO_Tracker:AddQuest(data)
    local questIndex = data:GetJournalIndex()
    local questName, _, _, stepType, stepTrackerText, isComplete, tracked, _, _, questType, zoneDisplayType = GetJournalQuestInfo(questIndex)
    
    -- This line prevents quests from being tracked multiple times but allows quests to be properly tracked
    -- when the UI is reloaded.
    
    --if this quest isnt on the c++ tracker or it isnt on the lua tracker then give up
    if((not tracked) or (not self:IsOnTracker(TRACK_TYPE_QUEST, questIndex))) then return end
    
    local questHeader, treeNode = self:CreateQuestHeader(data, questName, questType, isComplete, zoneDisplayType)

    self:PopulateQuestConditions(questIndex, questName, stepType, stepTrackerText, isComplete, tracked, questHeader, treeNode)    
    
    return questHeader
end


function ZO_Tracker:BeginTracking(trackType, arg1, arg2)
    if not CanTrack(trackType, arg1, arg2) then
        return false
    end

    if #self.tracked > 0 then
        local previouslyTrackedData = self.tracked[1]

        --If we are already tracking this we are good to go
        if previouslyTrackedData:Equals(trackType, arg1, arg2) then
            return true
        end

        --We update visibility at the end of this. If we do it now we will trigger the fragment to start hiding
        local DONT_UPDATE_VISIBILITY = false
        self:StopTracking(previouslyTrackedData.trackType, previouslyTrackedData.arg1, previouslyTrackedData.arg2, DONT_UPDATE_VISIBILITY)
    end

    SetTracked(trackType, true, arg1, arg2)

    local header
    if not self:IsOnTracker(trackType, arg1, arg2) then
        local trackedData = ZO_TrackedData:New(trackType, arg1, arg2)
    
        --setup specific data
        if trackType == TRACK_TYPE_QUEST then
            trackedData.isComplete = GetJournalQuestIsComplete(arg1)
            trackedData.level = GetJournalQuestLevel(arg1)
        end
    
        table.insert(self.tracked, trackedData)
   
        --build visuals
        if trackType == TRACK_TYPE_QUEST then
            header = self:AddQuest(trackedData)

            if header then
                trackedData.header = header
                self:UpdateTreeView()
            end
        end
    else
        header = self:GetHeaderForIndex(trackType, arg1, arg2)
    end
    
    if header then
        self:SetAssisted(header.m_Data, true)
    end

    self:UpdateVisibility()
    self:UpdateAssistedVisibility()

    self:FireCallbacks("QuestTrackerTrackingStateChanged", self, true, trackType, arg1, arg2)

    return true
end

function ZO_Tracker:StopTracking(trackType, arg1, arg2, updateVisibility)
    if GetIsTracked(trackType, arg1, arg2) then
        if GetTrackedIsAssisted(trackType, arg1, arg2) then
            local header = self:GetHeaderForIndex(trackType, arg1, arg2)
            if header then
                self:SetAssisted(header.m_Data, false)
            end
        end
 
        SetTracked(trackType, false, arg1, arg2)

        for i, trackedData in ipairs(self.tracked) do
            if trackedData:Equals(trackType, arg1, arg2) then
                table.remove(self.tracked, i)
                break
            end
        end
    
        -- NOTE: This does not look at self.tracked, it looks at self.headerPool (which is a container of controls!)
        local removedHeader = self:GetHeaderForIndex(trackType, arg1, arg2)

        if removedHeader then
            self.treeView:RemoveNode(removedHeader.m_TreeNode)
            self.headerPool:ReleaseObject(removedHeader.m_ObjectKey)
        end
    
        self:UpdateTreeView()
        if updateVisibility == nil or updateVisibility == true then
            self:UpdateVisibility()
        end
    
        self:FireCallbacks("QuestTrackerTrackingStateChanged", self, false, trackType, arg1, arg2)

        return true
    end
    return false
end

function ZO_Tracker:ClearTracker()
    self.treeView:Clear()
    self.headerPool:ReleaseAllObjects()
    self.assistedTexture:SetHidden(true)

    --iterate backwards because SetTracked will change the tracked array size
    for i = GetNumTracked(), 1, -1  do
        local trackType, arg1, arg2 = GetTrackedByIndex(i)
        SetTracked(trackType, false, arg1, arg2)
    end

    for i = 1, #self.tracked do
        local trackedData = self.tracked[i]
        if(trackedData.trackType == TRACK_TYPE_QUEST) then
            SetMapQuestPinsTrackingLevel(trackedData.arg1, TRACKING_LEVEL_UNTRACKED)
        end
    end
    
    self.tracked = {}
    self.assistedData = nil
    self:UpdateTreeView()
    self:UpdateVisibility()
end

function ZO_Tracker:UpdateTreeView()
    if(self:GetNumTracked() > 0) then
        local constants = GetPlatformConstants()
        self.treeView:Update(nil, nil, ZO_Anchor:New(constants.QUEST_TRACKER_TREE_ANCHOR))

        local headerEntries = self.headerPool:GetActiveObjects()
        for _, header in pairs(headerEntries) do
            header:ClearAnchors()
            constants.QUEST_TRACKER_TREE_ANCHOR:AddToControl(header)
        end
    end
end

function ZO_Tracker:SetAssisted(data, assisted)
    local assistingDifferentQuest = assisted and not data:EqualsTrackedData(self.assistedData)
    local unassistingAssistedQuest = not assisted and self.assistedData and self.assistedData:EqualsTrackedData(data)

    if assistingDifferentQuest or unassistingAssistedQuest then
        --unassist the assisted quest
        local unassistedData
        if self.assistedData then
            unassistedData = self.assistedData
            self:SetTrackTypeAssisted(unassistedData.trackType, false, unassistedData.arg1, unassistedData.arg2)
            self.assistedData = nil
            self.assistedTexture:SetHidden(true)
        end

        --if we're assisting a new quest, assist that
        if assisted then
            self.assistedData = data
            self:SetTrackTypeAssisted(data.trackType, true, data.arg1, data.arg2)
            if data then
                local assistedTexture = self.assistedTexture
                assistedTexture:SetHidden(false)
                local assistedHeader = self:GetHeaderForIndex(data.trackType, data.arg1, data.arg2)
                ApplyPlatformStyleToAssistedTexture(assistedTexture, assistedHeader)
            end
        end

        self:FireCallbacks("QuestTrackerAssistStateChanged", unassistedData, self.assistedData)
    end
end

function ZO_Tracker:OnGamepadPreferredModeChanged()
    self:ApplyPlatformStyle()
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

    function ZO_Tracker:IsOverlappingTextChat()
        local _, height = GetDimensions(self.trackerControl)
        return height > MAX_HEIGHT_NO_COLLISION
    end
end

--
-- XML handlers
--

-- NOTE: This function takes a label because it is called from control script handlers...
function ZO_Tracker:DoHeaderNameHighlight(label, state)
    local data = label.m_Data
    if(state == MOUSE_ENTER) then
        label:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGBA())
    else
        label:SetColor(GetConColor(data.level))
    end
end

function ZO_TrackedHeader_MouseEnter(label)
    ZO_QuestTracker_ShowTrackedHeaderTooltip(label)  
end

function ZO_TrackedHeader_MouseExit(label)
    ZO_QuestTracker_HideTrackedHeaderTooltip(label)
end

local function ShowQuestInJournal(header)
    local questJournalObject = SYSTEMS:GetObject("questJournal")

    questJournalObject:FocusQuestWithIndex(header.m_Data:GetJournalIndex())
    SCENE_MANAGER:Show(questJournalObject:GetSceneName())
end

local function AbandonTrackedQuest(header)
    local questIndex = header.m_Data:GetJournalIndex()
    QUEST_JOURNAL_MANAGER:ConfirmAbandonQuest(questIndex)
end

local function ShareTrackedQuest(header)
    local questIndex = header.m_Data:GetJournalIndex()
    QUEST_JOURNAL_MANAGER:ShareQuest(questIndex)
end

local function ShowTrackingMenu(header)
    ClearMenu()

    if header.m_Data.trackType == TRACK_TYPE_QUEST then
        AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_SHOW_IN_JOURNAL), function() ShowQuestInJournal(header) end)
        AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_SHOW_ON_MAP), function() ZO_WorldMap_ShowQuestOnMap(header.m_Data:GetJournalIndex()) end)
        if GetIsQuestSharable(header.m_Data:GetJournalIndex()) and IsUnitGrouped("player") then
            AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_SHARE), function() ShareTrackedQuest(header) end)
        end
        if GetJournalQuestType(header.m_Data:GetJournalIndex()) ~= QUEST_TYPE_MAIN_STORY then
            AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_ABANDON), function() AbandonTrackedQuest(header) end)
        end
    end
    
    ShowMenu(header)
end

function ZO_TrackedHeader_MouseUp(label, button, upInside)
    if(upInside) then
        PlaySound(SOUNDS.DEFAULT_CLICK)
        local header = label
        if(button == MOUSE_BUTTON_INDEX_RIGHT) then
            ShowTrackingMenu(header)
        end
    end
end

function ZO_QuestTracker_ShowTrackedHeaderTooltip(trackedLabel)  
    local trackerControl = trackedLabel:GetParent():GetParent()
    trackerControl.tracker:DoHeaderNameHighlight(trackedLabel, MOUSE_ENTER)
end

function ZO_QuestTracker_HideTrackedHeaderTooltip(trackedLabel)
    SetTooltipText(InformationTooltip)
    local trackerControl = trackedLabel:GetParent():GetParent()
    trackerControl.tracker:DoHeaderNameHighlight(trackedLabel, MOUSE_EXIT)
end

function ZO_QuestTracker_SetEnabled(enabled)
    FOCUSED_QUEST_TRACKER:SetEnabled(enabled)
end

function ZO_FocusedQuestTracker_OnInitialized(control)
    FOCUSED_QUEST_TRACKER = ZO_Tracker:New(control, control:GetNamedChild("Container"):GetNamedChild("QuestContainer"))
end
