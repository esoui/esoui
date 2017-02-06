--constants
local TRACKED = true
local NOT_TRACKED = false

local MOUSE_ENTER = 1
local MOUSE_EXIT = 2

local DEAULT_STYLE = 1
local HINT_STYLE = 2

local QUEST_STATUS_AND                  = 1
local QUEST_STATUS_AND_COMPLETE         = 2
local QUEST_STATUS_OR                   = 3
local QUEST_STATUS_OR_COMPLETE          = 4
local QUEST_STATUS_OPTIONAL             = 5
local QUEST_STATUS_OPTIONAL_COMPLETE    = 6
local QUEST_STATUS_END                  = 7
local QUEST_STATUS_TIMER                = 8

local QUEST_TRACKER_TREE_HEADER                 = 1
local QUEST_TRACKER_TREE_CONDITION              = 2
local QUEST_TRACKER_TREE_SUBCATEGORY_TITLE      = 3
local QUEST_TRACKER_TREE_SUBCATEGORY_CONDITION  = 4

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

    HEADER_INHERIT_ALPHA = false,
    TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,

    QUEST_LINE_MAX_WIDTH = 350,

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

local LEAVE_ASSISTED = true
local CLEAR_ASSISTED = false

local function ApplyStyle(label, style)
    if style == HINT_STYLE then
        label:SetColor(ZO_HINT_TEXT:UnpackRGBA())
    else
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

    if control.questType or control.instanceDisplayType then
        local icon = control.icon
        local questJournalObject = SYSTEMS:GetObject("questJournal")
        local iconTexture = questJournalObject:GetIconTexture(control.questType, control.instanceDisplayType)
        icon:SetTexture(iconTexture)
    end

    if control.m_TreeNode then
        control.m_TreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[QUEST_TRACKER_TREE_HEADER])
    end

    control.extraWidth = constants.DISTANCE_BUTTON_TO_HEADER 
end

local function ApplyPlatformStyleToCondition(control)
    local constants = GetPlatformConstants()
    control:SetDimensions(constants.QUEST_LINE_BASE_WIDTH, constants.QUEST_LINE_BASE_HEIGHT)
    control:SetDimensionConstraints(constants.QUEST_LINE_MIN_WIDTH, constants.QUEST_LINE_MIN_HEIGHT, constants.QUEST_LINE_MAX_WIDTH, constants.QUEST_LINE_MAX_HEIGHT)
    control:SetFont(constants.FONT_GENERAL)
    if control.m_TreeNode then
        control.m_TreeNode:SetOffsetY(constants.QUEST_TRACKER_TREE_LINE_SPACING[control.entryType])
    end
end

local function ApplyPlatformStyleToStepDescription(control)
    local constants = GetPlatformConstants()
    control:SetDimensions(constants.QUEST_LINE_BASE_WIDTH, constants.QUEST_LINE_BASE_HEIGHT)
    control:SetFont(constants.FONT_SUBCATEGORY)
    control:SetVerticalAlignment(constants.QUEST_TRACKER_TREE_SUBCATEGORY_VERTICAL_ALIGNMENT)
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

local function AreHelpTooltipsShowing()
    return GetSetting_Bool(SETTING_TYPE_TOOLTIPS, TOOLTIP_SETTING_QUEST_PANEL_CATEGORY)
end

local function IsQuestTrackerVisible()
    return false
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

--
-- Tracker
--        

ZO_Tracker = ZO_CallbackObject:Subclass()

function ZO_Tracker:New(trackerPanel, trackerControl)
    local tracker = ZO_CallbackObject.New(self)

    local stepDescriptionResetFunction = function(control)
                                            control:SetText("")
                                            control.m_TreeNode = nil
                                         end
							
	local conditionResetFunction =	function(control)
										control:SetText("")
                                        control.isGroupCreditShared = false
                                        control.m_TreeNode = nil
									end
    
    local headerResetFunction =	function(control)
									if(control.m_ChildConditionControls)
									then
										tracker:RemoveAndReleaseConditionsFromHeader(control)
									end
	                                
									if(control.m_StepDescriptionControls)
									then
										for _, control in ipairs(control.m_StepDescriptionControls) do
											tracker.stepDescriptionPool:ReleaseObject(control.key)
											tracker.treeView:RemoveNode(control.treeNode)
										end										
									end                                
	                                
                                    control:SetText("")
									control.m_StepDescriptionControls = nil
									control.m_BGStorage = nil
									control.m_TreeNode = nil
                                    control.headerText = nil
                                    control.questType = nil
                                    control.instanceDisplayType = nil
								end

    trackerControl:GetParent().tracker = tracker            
    tracker.trackerControl = trackerControl
    tracker.trackerPanel = trackerPanel
    tracker.timerControl = GetControl(trackerPanel, "TimerAnchor")
    
    tracker.headerPool = ZO_ControlPool:New("ZO_TrackedHeader", trackerControl, "TrackedHeader")
    tracker.conditionPool = ZO_ControlPool:New("ZO_QuestCondition", trackerControl, "QuestCondition")
    tracker.stepDescriptionPool = ZO_ControlPool:New("ZO_QuestStepDescription", trackerControl, "QuestStepDescription")

    tracker.headerPool:SetCustomResetBehavior(headerResetFunction)
    tracker.conditionPool:SetCustomResetBehavior(conditionResetFunction)
    tracker.stepDescriptionPool:SetCustomResetBehavior(stepDescriptionResetFunction)

    tracker.headerPool:SetCustomAcquireBehavior(ApplyPlatformStyleToHeader)
    tracker.conditionPool:SetCustomAcquireBehavior(ApplyPlatformStyleToCondition)
    tracker.stepDescriptionPool:SetCustomAcquireBehavior(ApplyPlatformStyleToStepDescription)

    tracker:CreatePlatformAnchors()
    
    local constants = GetPlatformConstants()
    tracker.treeView = ZO_TreeControl:New(constants.QUEST_TRACKER_TREE_ANCHOR, constants.QUEST_TRACKER_TREE_INDENT)
    
    tracker.tracked = {}
    tracker.MAX_TRACKED = MAX_JOURNAL_QUESTS -- never allow more than this many quests...this is only controlled by the UI, not the client
    tracker.isMouseInside = false
    tracker.assistedTexture = GetControl(trackerControl, "Assisted")
    
    local function OnAddOnLoaded(eventCode, addOnName)
        if(addOnName == "ZO_Ingame") then
            tracker:UpdateVisibility()

            local function OnInterfaceSettingChanged(eventCode, settingType, settingId)
                if settingType == SETTING_TYPE_UI then
                    if settingId == UI_SETTING_SHOW_QUEST_TRACKER then
                        tracker:UpdateVisibility()
                    end
                end
            end

            trackerPanel:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)

            --Events
            self:RegisterCallback("QuestTrackerAssistStateChanged", function(unassistedQuestIndex, questIndex, questIndexIsAssisted) tracker:OnQuestAssistStateChanged(unassistedQuestIndex, questIndex, questIndexIsAssisted) end)

            trackerPanel:RegisterForEvent(EVENT_QUEST_CONDITION_COUNTER_CHANGED,  function(_, index) tracker:OnQuestConditionUpdated(index) end)
            trackerPanel:RegisterForEvent(EVENT_QUEST_ADVANCED,                   function(_, questIndex, questName, isPushed, isComplete, mainStepChanged) tracker:OnQuestAdvanced(questIndex, questName, isPushed, isComplete, mainStepChanged) end)
            trackerPanel:RegisterForEvent(EVENT_QUEST_ADDED,                      function(_, questIndex) tracker:OnQuestAdded(questIndex) end)   
            trackerPanel:RegisterForEvent(EVENT_QUEST_REMOVED,                    function(_, completed, questIndex, questName, zoneIndex, poiIndex, questID) tracker:OnQuestRemoved(questIndex, completed, questID) end)
            trackerPanel:RegisterForEvent(EVENT_LEVEL_UPDATE,                     function(_, tag, level) tracker:OnLevelUpdated(tag) end)
            trackerPanel:RegisterForEvent(EVENT_TRACKING_UPDATE,                  function() tracker:InitialTrackingUpdate() end)
            trackerPanel:RegisterForEvent(EVENT_QUEST_LIST_UPDATED,               function() tracker:InitialTrackingUpdate() end)
            trackerPanel:RegisterForEvent(EVENT_PLAYER_ACTIVATED,                 function() tracker:InitialTrackingUpdate() end)

            INTERACT_WINDOW:RegisterCallback("Hidden", function() tracker.assistedQuestCompleted = false end)

            tracker:InitialTrackingUpdate()
            trackerPanel:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    trackerPanel:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
       
    return tracker
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
end

function ZO_Tracker:InitialTrackingUpdate()
    self.disableAudio = true
    local numTracked = GetNumTracked()
    self:ClearTracker()
    for i=1, numTracked do
        local trackType, arg1, arg2 = GetTrackedByIndex(i)
        --quests only have one argument, which means the second one should be nil in lua, but it comes from c++ as 0
        if(trackType == TRACK_TYPE_QUEST) then
            self:BeginTracking(trackType, arg1)
        end      
        if(GetTrackedIsAssisted(trackType, arg1, arg2)) then
            local header = self:GetHeaderForIndex(trackType, arg1, (arg2 ~= 0) and arg2 or nil)
            self:SetAssisted(header, true)
        end
    end
    self.disableAudio = false
    self:FireCallbacks("QuestTrackerInitialUpdate")
end

function ZO_Tracker:SetEnabled(enabled)
    self.enabled = enabled
    self:UpdateVisibility()
end

function ZO_Tracker:UpdateVisibility()
    if(self:GetNumTracked() == 0 or not self.enabled or not IsQuestTrackerVisible()) then
        self.trackerControl:SetHidden(true)
    else
        self.trackerControl:SetHidden(false)
    end
end

function ZO_Tracker:SetTracked(questIndex, tracked)
    if(tracked) then
        self:BeginTracking(TRACK_TYPE_QUEST, questIndex)
    else
        self:StopTracking(TRACK_TYPE_QUEST, questIndex)
    end
end

function ZO_Tracker:ToggleTracking(questIndex)
    local tracked = GetIsTracked(TRACK_TYPE_QUEST, questIndex)
    local addToTracker = not tracked
    
    if(addToTracker == false or not self:IsFull())
    then
        self:SetTracked(questIndex, addToTracker)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_ERROR_QUEST_TRACKER_FULL_REMOVE_SOMETHING_FIRST))
    end
end

function ZO_Tracker:ForceAssist(questIndex)
    local tracked = GetIsTracked(TRACK_TYPE_QUEST, questIndex)
    if(not tracked) then
        if(self:IsFull()) then
            self:SetTracked(self.tracked[1]:GetJournalIndex(), false)
        end
        self:SetTracked(questIndex, true)
    end
    local header = self:GetHeaderForIndex(TRACK_TYPE_QUEST, questIndex)
    if(header) then
        self:SetAssisted(header, true)
    end
end

function ZO_Tracker:AssistClosestTracked()
    local foundValidCondition, nextQuestToAssist = GetNearestQuestCondition(QUEST_ASSIST_CONSIDER_ONLY_TRACKED_QUESTS)            
    if foundValidCondition then
        local questHeader = self:GetHeaderForIndex(TRACK_TYPE_QUEST, nextQuestToAssist)
        if questHeader then
            self.disableAudio = true
            self:SetAssisted(questHeader, true)
            self.disableAudio = false
        end
    else
        --Even if we can't find a quest to path to, let's assist whatever other quests we might have in the journal instead
        self:AssistNext()
    end
end

function ZO_Tracker:AssistNext(ignoreSceneRestriction)
    local isShowingBase = SCENE_MANAGER:IsShowingBaseScene()
    if((ignoreSceneRestriction or isShowingBase) and #self.tracked > 0) then
        if isShowingBase and self.isFaded then
            self:FireCallbacks("QuestTrackerReactivate")
        else
            local assistIndex = 1
            if self.assistedData then
                local nextQuestIndex = SYSTEMS:GetObject("questJournal"):GetNextSortedQuestForQuestIndex(self.assistedData.arg1)
                for i = 1, #self.tracked do
                    if self.tracked[i]:GetJournalIndex() == nextQuestIndex then
                        assistIndex = i
                        break
                    end
                end
            end

            local newAssistData = self.tracked[assistIndex]
            if(newAssistData) then
                local journalIndex = newAssistData:GetJournalIndex()
                local questHeader = self:GetHeaderForIndex(TRACK_TYPE_QUEST, journalIndex)
                if(questHeader) then
                    self:SetAssisted(questHeader, true)
                    CALLBACK_MANAGER:FireCallbacks("QuestTrackerUpdatedOnScreen")
                end
            end
        end
    end
end

function ZO_Tracker:SetFaded(faded)
    self.isFaded = faded
end

function ZO_Tracker:GetFaded()
    return self.isFaded
end

--
-- Pins
--

function ZO_Tracker:RefreshQuestPins(journalIndex, tracked)
    -- Do not use GetMapQuestPinsAssisted to find whether or not the pin was assisted, it causes eso-56564.
    local wasAssisted = GetTrackedIsAssisted(TRACK_TYPE_QUEST, journalIndex)
    
    RemoveMapQuestPins(journalIndex)
    AddMapQuestPins(journalIndex)
    
    if(wasAssisted) then
        SetMapQuestPinsAssisted(journalIndex, true)
    end

    self:FireCallbacks("QuestTrackerRefreshedMapPins", journalIndex)
end

--
-- Header Management
--

function ZO_Tracker:CreateQuestHeader(data, questName, questType, isComplete, instanceDisplayType)
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

    self:InitializeQuestHeader(questName, questType, questHeader, isComplete, instanceDisplayType)

    return questHeader, treeNode
end

function ZO_Tracker:InitializeQuestHeader(questName, questType, questHeader, isComplete, instanceDisplayType)
    questHeader:SetColor(GetConColor(questHeader.m_Data.level))
    questHeader:SetText(questName)
    -- add icon here
    local icon = questHeader.icon
    local questJournalObject = SYSTEMS:GetObject("questJournal")
    local iconTexture = questJournalObject:GetIconTexture(questType, instanceDisplayType)
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
    questHeader.instanceDisplayType = instanceDisplayType
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
    local style = visibility == QUEST_STEP_VISIBILITY_HINT and HINT_STYLE or DEFAULT_STYLE
    
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
    
    local conditionIconType = QUEST_STATUS_END
    
    if(isOptionalStep) then
        conditionIconType = QUEST_STATUS_OPTIONAL
    elseif(stepType == QUEST_STEP_TYPE_AND) then
        conditionIconType = QUEST_STATUS_AND
    elseif(stepType == QUEST_STEP_TYPE_OR) then
        conditionIconType = QUEST_STATUS_OR
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
	                conditionIconType = conditionIconType + 1 -- move to complete
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
                elseif conditionsAreOR then
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
    for stepIndex = 2, GetJournalQuestNumSteps(questIndex) do
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
    if(self:IsOnTracker(TRACK_TYPE_QUEST, questIndex))
    then
        self:RebuildConditions(questIndex)        
        self:RefreshQuestPins(questIndex, true)       
    end
end

function ZO_Tracker:OnQuestAdded(questIndex)
    if(not self:IsFull())
    then
        self:BeginTracking(TRACK_TYPE_QUEST, questIndex)
    end
end

function ZO_Tracker:OnQuestRemoved(questIndex, completed, questID)
    if(GetIsTrackedForContentId(TRACK_TYPE_QUEST, questID)) then
        self:StopTracking(TRACK_TYPE_QUEST, questIndex, nil, completed)
    end
end

function ZO_Tracker:OnQuestAdvanced(questIndex, questName, isPushed, isComplete, mainStepChanged)
    if(self:IsOnTracker(TRACK_TYPE_QUEST, questIndex))
    then
        self:SetTrackedQuestComplete(questIndex, isComplete)
        
        local questHeader = self:GetHeaderForIndex(TRACK_TYPE_QUEST, questIndex)
        if(questHeader)
        then
            local questType = GetJournalQuestType(questIndex)
            local instanceDisplayType = GetJournalInstanceDisplayType(questIndex)
            self:InitializeQuestHeader(questName, questType, questHeader, isComplete, instanceDisplayType)
        end
        
        self:RebuildConditions(questIndex)       
        self:RefreshQuestPins(questIndex, true)        
    end
end

function ZO_Tracker:OnQuestAssistStateChanged(unassistedData, assistedData, applyPlatformConstants)
    if(unassistedData) then
        self.assistedTexture:SetHidden(true)
    end

    if(assistedData) then
        local assistedTexture = self.assistedTexture
        assistedTexture:SetHidden(false)
        local assistedHeader = self:GetHeaderForIndex(assistedData.trackType, assistedData.arg1, assistedData.arg2)

        if applyPlatformConstants then
            ApplyPlatformStyleToAssistedTexture(assistedTexture, assistedHeader)
        else
            assistedTexture:ClearAnchors()
            assistedTexture:SetAnchor(RIGHT, assistedHeader, LEFT, -3, -1)
        end
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
   
    for k, header in pairs(headerList)
    do
        if(header.m_Data:Equals(trackType, arg1, arg2))
        then
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
    
    if(count > 0)
    then
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
    if(trackType == TRACK_TYPE_QUEST) then
        SetMapQuestPinsAssisted(arg1, show)

        if(show and not self.disableAudio) then
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
        
        if(trackedData:Equals(trackType, arg1, arg2))
        then    
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
            if(trackedData:GetJournalIndex() == questIndex)
            then
                trackedData.isComplete = isComplete
                return
            end
        end
    end
end

function ZO_Tracker:IsOnTracker(trackType, arg1, arg2)
    for i = 1, #self.tracked do
        local trackedData = self.tracked[i]
        if(trackedData:Equals(trackType, arg1, arg2))
        then
            return true
        end
    end
    
    return false
end

function ZO_Tracker:AddQuest(data)
    local questIndex = data:GetJournalIndex()
    local questName, _, _, stepType, stepTrackerText, isComplete, tracked, _, _, questType, instanceDisplayType = GetJournalQuestInfo(questIndex)
    
    -- This line prevents quests from being tracked multiple times but allows quests to be properly tracked
    -- when the UI is reloaded.
    
    --if this quest isnt on the c++ tracker or it isnt on the lua tracker then give up
    if((not tracked) or (not self:IsOnTracker(TRACK_TYPE_QUEST, questIndex))) then return end
    
    local questHeader, treeNode = self:CreateQuestHeader(data, questName, questType, isComplete, instanceDisplayType)

    self:PopulateQuestConditions(questIndex, questName, stepType, stepTrackerText, isComplete, tracked, questHeader, treeNode)    
    
    return questHeader
end


function ZO_Tracker:BeginTracking(trackType, arg1, arg2)
    if(self:IsOnTracker(trackType, arg1, arg2)) 
    then
        -- This quest is already tracked
        return     
    end           
    
    if(self:IsFull())
    then 
        return 
    end

    if(not SetTracked(trackType, true, arg1, arg2)) then
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
    
    --add pins
    if(trackType == TRACK_TYPE_QUEST) then
        AddMapQuestPins(arg1)
    end
    
    if(header) then
        trackedData.header = header
        self:UpdateTreeView()
        self:UpdateVisibility()
    end

     --if nothing is being assisted, or the player just finished their assisted quest, assist this
    if(self.assistedQuestCompleted or self.assistedData == nil) then
        self:SetAssisted(header, true)
    end

    self.assistedQuestCompleted = false

    self:FireCallbacks("QuestTrackerTrackingStateChanged", self, true, trackType, arg1, arg2)
end

function ZO_Tracker:StopTracking(trackType, arg1, arg2, completed)
    local wasAssisted = false
    if(GetTrackedIsAssisted(trackType, arg1, arg2))
    then
        local header = self:GetHeaderForIndex(trackType, arg1, arg2)
        if(header)
        then
            self:SetAssisted(header, false)
            wasAssisted = true

            if completed and INTERACT_WINDOW:IsInteracting()
            then
                self.assistedQuestCompleted = true
            end
        end
    end
 
    if(not SetTracked(trackType, false, arg1, arg2)) then
        return
    end

    for i = 1, #self.tracked
    do
        local trackedData = self.tracked[i]
        if(trackedData:Equals(trackType, arg1, arg2))
        then
            table.remove(self.tracked, i)
            break
        end
    end
    
    -- NOTE: This does not look at self.tracked, it looks at self.headerPool (which is a container of controls!)
    local removedHeader = self:GetHeaderForIndex(trackType, arg1, arg2)

    if(removedHeader)
    then
        self.treeView:RemoveNode(removedHeader.m_TreeNode)        
        self.headerPool:ReleaseObject(removedHeader.m_ObjectKey)        
    end
    
    self:UpdateTreeView()
    self:UpdateVisibility()
    
    --remove pins
    if(trackType == TRACK_TYPE_QUEST) then
        RemoveMapQuestPins(arg1)
    end   
    
    self:FireCallbacks("QuestTrackerTrackingStateChanged", self, false, trackType, arg1, arg2)

    if(wasAssisted) then
        self:AssistClosestTracked()
    end
end

function ZO_Tracker:ClearTracker()
    self.treeView:Clear()
    self.headerPool:ReleaseAllObjects()
    self.assistedTexture:SetHidden(true)

    for i = 1, #self.tracked
    do
        local trackedData = self.tracked[i]
        if(trackedData.trackType == TRACK_TYPE_QUEST) then
            RemoveMapQuestPins(trackedData.arg1)
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

function ZO_Tracker:SetAssisted(header, showArrows)
    local data = header.m_Data
    
    if((showArrows and self.assistedData ~= data) or (not showArrows and self.assistedData == data)) then
        --unassist the assisted quest
        local unassistedData
        if(self.assistedData) then
            unassistedData = self.assistedData
            self:SetTrackTypeAssisted(unassistedData.trackType, false, unassistedData.arg1, unassistedData.arg2)
            self.assistedData = nil
        end
    
        --if we're assisting a new quest, assist that
        if(showArrows) then
            self.assistedData = data
            self:SetTrackTypeAssisted(data.trackType, true, data.arg1, data.arg2)   
        end        

        self:FireCallbacks("QuestTrackerAssistStateChanged", unassistedData, self.assistedData)
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

local function ToggleGuideArrow(header)
	local statusButton = GetControl(header, "Status")
	local trackType = header.m_Data.trackType
    if(trackType == TRACK_TYPE_QUEST) then
        local questTrackerControl = header:GetParent():GetParent()
        local isAssisted = GetTrackedIsAssisted(TRACK_TYPE_QUEST, header.m_Data:GetJournalIndex())
        if(not isAssisted) then
            questTrackerControl.tracker:SetAssisted(header, true)
        end
    end
end

local function UntrackThis(header)
	local data = header.m_Data
	local questIndex = header.m_Data:GetJournalIndex()	
    local questTrackerControl = header:GetParent():GetParent()
    questTrackerControl.tracker:StopTracking(header.m_Data.trackType, header.m_Data.arg1, header.m_Data.arg2)
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

	if(not GetTrackedIsAssisted(TRACK_TYPE_QUEST, header.m_Data:GetJournalIndex())) then
		AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_SHOW_ARROW), function() ToggleGuideArrow(header) end)
	end
	
	if(header.m_Data.trackType == TRACK_TYPE_QUEST) then		
        AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_SHOW_IN_JOURNAL), function() ShowQuestInJournal(header) end)
		AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_SHOW_ON_MAP), function() ZO_WorldMap_ShowQuestOnMap(header.m_Data:GetJournalIndex()) end)
		if(GetIsQuestSharable(header.m_Data:GetJournalIndex()) and IsUnitGrouped("player")) then
			AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_SHARE), function() ShareTrackedQuest(header) end)
		end
        if(GetJournalQuestType(header.m_Data:GetJournalIndex()) ~= QUEST_TYPE_MAIN_STORY) then
            AddMenuItem(GetString(SI_QUEST_TRACKER_MENU_ABANDON), function() AbandonTrackedQuest(header) end)
        end
	end
	
	ShowMenu(header)
end

function ZO_TrackedHeader_MouseUp(label, button, upInside)
    if(upInside) then
        PlaySound(SOUNDS.DEFAULT_CLICK)
        local header = label
        if(button == MOUSE_BUTTON_INDEX_LEFT) then
            ToggleGuideArrow(header)
        elseif(button == MOUSE_BUTTON_INDEX_RIGHT) then
            ShowTrackingMenu(header)
        end
    end   
end

function ZO_QuestTracker_ShowTrackedHeaderTooltip(trackedLabel)  
    if(AreHelpTooltipsShowing()) then
        local header = trackedLabel
        InitializeTooltip(InformationTooltip, header, TOPRIGHT, -40, 0)
        SetTooltipText(InformationTooltip, GetString(SI_QUEST_TRACKER_UBER_TIP), ZO_TOOLTIP_INSTRUCTIONAL_COLOR)
    end
        
    local trackerControl = trackedLabel:GetParent():GetParent()
    trackerControl.tracker:DoHeaderNameHighlight(trackedLabel, MOUSE_ENTER)
end

function ZO_QuestTracker_HideTrackedHeaderTooltip(trackedLabel)
    SetTooltipText(InformationTooltip)
    local trackerControl = trackedLabel:GetParent():GetParent()
    trackerControl.tracker:DoHeaderNameHighlight(trackedLabel, MOUSE_EXIT)
end

function ZO_QuestTracker_SetEnabled(enabled)
    QUEST_TRACKER:SetEnabled(enabled)
    FOCUSED_QUEST_TRACKER:SetEnabled(enabled)
end

function ZO_QuestTracker_OnInitialized(self)
    QUEST_TRACKER = ZO_Tracker:New(self, GetControl(self, "Container"))
    ZO_QuestTracker.tracker = QUEST_TRACKER
end
