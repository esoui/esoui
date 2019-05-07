Compass = ZO_Object:Subclass()

function Compass:New(...)
    local compass = ZO_Object.New(self)
    compass:Initialize(...)
    return compass
end

local QUEST_AREA_PIN_TYPES =
{
    MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION,
    MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION,
    MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION,
    MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_TRACKED_QUEST_CONDITION,
    MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION,
    MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION,
    MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_QUEST_CONDITION,
    MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION,
    MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION,
    MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION,
    MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION,
}

local SHOWN_AREA_PIN_TYPES_TO_ANIMATION_PIN_TEXTURE =
{
    [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon_assisted.dds",
    [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon_assisted.dds",
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_assisted.dds",
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_assisted.dds",
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_assisted.dds",
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_assisted.dds",
    [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
    [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
    [MAP_PIN_TYPE_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
    [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
    [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
    [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
    [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
    [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
}

local AREA_PIN_TYPE_NAME =
{
    QUEST_PINS = "areaQuestPins",
    ZONE_STORY_SUGGESTION_PINS = "areaZoneStorySuggestionPins",
}

local function IsPlayerInsideJournalQuestConditionGoalArea(journalIndex, stepIndex, conditionIndex)
    journalIndex = journalIndex - 1
    stepIndex = stepIndex - 1
    conditionIndex = conditionIndex - 1
    for _, pinType in ipairs(QUEST_AREA_PIN_TYPES) do
        if IsPlayerInsidePinArea(pinType, journalIndex, stepIndex, conditionIndex) then
            return true
        end
    end
    return false
end

local function IsQuestVisible(journalIndex)
    local visibilitySetting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_ACTIVE_QUESTS))
    if visibilitySetting == COMPASS_ACTIVE_QUESTS_CHOICE_ON then 
        return true
    elseif visibilitySetting == COMPASS_ACTIVE_QUESTS_CHOICE_OFF then 
        return false
    else
        return GetTrackedIsAssisted(TRACK_TYPE_QUEST, journalIndex)
    end
end

local function ShouldShowQuestArea(journalIndex, stepIndex, conditionIndex)
    if IsPlayerInsideJournalQuestConditionGoalArea(journalIndex, stepIndex, conditionIndex) then
        return IsQuestVisible(journalIndex)
    else
        return false
    end
end

function Compass:Initialize(control)
    self.control = control

    self.container = control:GetNamedChild("Container")
    self.areaOverride = control:GetNamedChild("AreaOverride")
    self.areaOverrideLabel = self.areaOverride:GetNamedChild("Label")
    self.areaOverrideAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassAreaOverrideLabelAnimation", self.areaOverride)

    self.areaOverrideAnimation:SetHandler("OnStop", function()
        self.currentOverrideJournalIndex = nil
        self.currentOverrideStepIndex = nil
        self.currentOverrideConditionIndex = nil

        while self.areaOverrideQueue do
            local nextOverride = table.remove(self.areaOverrideQueue, 1)
            if #self.areaOverrideQueue == 0 then
                self.areaOverrideQueue = nil
            end
            if ShouldShowQuestArea(nextOverride.journalIndex, nextOverride.stepIndex, nextOverride.conditionIndex) then
                self:PlayAreaOverrideAnimation(nextOverride.journalIndex, nextOverride.stepIndex, nextOverride.conditionIndex)
                break
            end
        end
        self.areaOverride:SetWidth(0)
        self.areaOverride:SetAlpha(1)
    end)

    self.container:SetHandler("OnUpdate", function() self:OnUpdate() end)

    self.areaAnimationPools = {}

    self:InitializeCenterOveredPins()
    self:InitializePoiPins()
    self:InitializeQuestPins()
    self:InitializeZoneStoryAreaPins()

    local function OnPlayerInPinAreaChanged(...)
        self:OnPlayerInQuestPinAreaChanged(...)
        self:OnPlayerInZoneStoryPinAreaChanged(...)
    end

    self.control:RegisterForEvent(EVENT_PLAYER_IN_PIN_AREA_CHANGED, OnPlayerInPinAreaChanged)

    self.nextLabelUpdateTime = 0

    self:OnGamepadPreferredModeChanged() -- Setup initial visual style based on current mode.
    self.control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function Compass:InitializeCenterOveredPins()
    self.centerOverPinLabel = self.control:GetNamedChild("CenterOverPinLabel")
    self.centerOverPinLabelAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassCenterOverPinAnimation", self.centerOverPinLabel)
end

function Compass:InitializePoiPins()
    local function OnPoiAnimationStopped(animation, control)
        self.poiAnimationPool:ReleaseObject(animation:GetTimeline().key)
        control:ClearAnchors()
        control:SetHidden(true)
    end
    local function CreatePoiAnimationTimeline()
        local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassPoiPinAnimationOut")
        timeline:GetFirstAnimation():SetHandler("OnStop", OnPoiAnimationStopped)
        return timeline
    end
    self.poiAnimationPool = ZO_ObjectPool:New(CreatePoiAnimationTimeline, function() end)

    self.control:RegisterForEvent(EVENT_ZONE_CHANGED, function() self:OnZoneChanged() end)
    self.control:RegisterForEvent(EVENT_QUEST_COMPLETE, function() self:OnZoneChanged() end)
end

function Compass:ApplyTemplateToAreaTexture(texture, template, restingAlpha, pinType)
    ApplyTemplateToControl(texture, template)

    if restingAlpha and texture.resetAlphaAnimation then
        texture.resetAlphaAnimation:SetEndAlpha(restingAlpha)
        if texture:GetAlpha() ~= 0 then
            texture:SetAlpha(restingAlpha)
        end
    end

    self:SetAreaTexturePlatformTextures(texture, pinType)
end

function Compass:OnPlayerInZoneStoryPinAreaChanged(eventCode, pinType, param1, param2, param3, playerIsInside)
    if pinType == MAP_PIN_TYPE_ZONE_STORY_SUGGESTED_AREA then
        local trackedZoneId, trackedZoneCompletionType, trackedActivityId = GetTrackedZoneStoryActivityInfo()
        if trackedZoneId == param1 and trackedZoneCompletionType == param2 and trackedActivityId == param3 then
            if playerIsInside then
                self:TryPlayingAnimationOnAreaPin(AREA_PIN_TYPE_NAME.ZONE_STORY_SUGGESTION_PINS, trackedZoneId, trackedZoneCompletionType, trackedActivityId, pinType)
            else
                self:StopAreaPinOutAnimation(AREA_PIN_TYPE_NAME.ZONE_STORY_SUGGESTION_PINS, trackedZoneId, trackedZoneCompletionType, trackedActivityId)
            end
            self:SetPlayerInside(AREA_PIN_TYPE_NAME.ZONE_STORY_SUGGESTION_PINS, trackedZoneId, trackedZoneCompletionType, trackedActivityId)
        end
    end
end

function Compass:InitializeZoneStoryAreaPins()
    local areaTexturePinPool
    local function ResetAreaTexture(areaTexture)
        Compass.ResetAreaTexture(areaTexture)
    end

    local function CreateAreaTexture(objectPool)
        return self:CreateAreaTexture(AREA_PIN_TYPE_NAME.ZONE_STORY_SUGGESTION_PINS, objectPool)
    end
    areaTexturePinPool = ZO_ObjectPool:New(CreateAreaTexture, ResetAreaTexture)

    local function OnAreaAnimationStarted(animationTimeline)
        local IGNORE_PIN_TEXTURE = true
        self:OnAreaAnimationStarted(animationTimeline, areaTexturePinPool, IGNORE_PIN_TEXTURE)
    end

    local function OnAreaAnimationStopped(animationTimeline)
        self:OnAreaAnimationStopped(animationTimeline, self.areaAnimationPools[AREA_PIN_TYPE_NAME.ZONE_STORY_SUGGESTION_PINS])
    end

    local function CreateAreaAnimationTimeline()
        return self:CreateAreaAnimationTimeline(OnAreaAnimationStarted, OnAreaAnimationStopped)
    end
    self.areaAnimationPools[AREA_PIN_TYPE_NAME.ZONE_STORY_SUGGESTION_PINS] = ZO_ObjectPool:New(CreateAreaAnimationTimeline, function() end)
end

local AREA_TEXTURE_RESTING_ALPHA_GAMEPAD = 1
local AREA_TEXTURE_RESTING_ALPHA_KEYBOARD = 0.85

function Compass:SetAreaTexturePlatformTextures(areaTexture, pinType)
    local platformModifier = IsInGamepadPreferredMode() and "Gamepad/gp_" or ""
    local pinType = pinType or areaTexture.pinType
    local pinTypeAssisted = ZO_MapPin.ASSISTED_PIN_TYPES[pinType]
    if pinTypeAssisted then
        areaTexture.left:SetTexture("EsoUI/Art/Compass/"..platformModifier.."areapin2frame_ends.dds")
        areaTexture.right:SetTexture("EsoUI/Art/Compass/"..platformModifier.."areapin2frame_ends.dds")
        areaTexture.center:SetTexture("EsoUI/Art/Compass/"..platformModifier.."area2frameAnim_centers.dds")
        areaTexture.pinType = pinType
    else
        areaTexture.left:SetTexture("EsoUI/Art/Compass/"..platformModifier.."area2frameAnim_standard_endcap.dds")
        areaTexture.right:SetTexture("EsoUI/Art/Compass/"..platformModifier.."area2frameAnim_standard_endcap.dds")
        areaTexture.center:SetTexture("EsoUI/Art/Compass/"..platformModifier.."area2frameAnim_standard_center.dds")
        areaTexture.pinType = pinType
    end
end

function Compass:SetPlayerInside(areaPinName, param1, param2, param3, playerIsInside)
    if not self.playerIsInsidePins then
        self.playerIsInsidePins = {}
    end

    if not self.playerIsInsidePins[areaPinName] then
        self.playerIsInsidePins[areaPinName] = {}
    end

    for i, pin in pairs(self.playerIsInsidePins[areaPinName]) do
        if pin.param1 == param1 and pin.param2 == param2 and pin.param3 == param3 then
            pin.playerIsInside = playerIsInside
            return
        end
    end

    if param1 and param2 and param3 then
        table.insert(self.playerIsInsidePins[areaPinName], { param1 = param1, param2 = param2, param3 = param3, playerIsInside = playerIsInside })
    end
end

function Compass:ClearPlayerInside(areaPinName, param1, param2, param3)
    if self.playerIsInsidePins and self.playerIsInsidePins[areaPinName] then
        for i, pin in pairs(self.playerIsInsidePins[areaPinName]) do
            if pin.param1 == param1 and (not param2 or pin.param2 == param2) and (not param3 or pin.param3 == param3) then
                table.remove(self.playerIsInsidePins[areaPinName], i)
            end
        end
    end
end

function Compass:IsPlayerInside(areaPinName, param1, param2, param3)
    if self.playerIsInsidePins and self.playerIsInsidePins[areaPinName] then
        for i, pin in pairs(self.playerIsInsidePins[areaPinName]) do
            if pin.param1 == param1 and pin.param2 == param2 and param3 == param3 then
                return pin.playerIsInside
            end
        end
    end

    return false
end

function Compass.ResetAreaTexture(areaTexture)
    areaTexture:SetHidden(true)
    areaTexture:ClearAnchors()
end

function Compass:CreateAreaTexture(areaPinName, objectPool)
    local areaTexture = ZO_ObjectPool_CreateNamedControl(areaPinName, "ZO_CompassAreaTexture", objectPool, self.control)

    areaTexture.animationIn = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassAreaTextureAnimationIn")
    areaTexture.animationIn:GetAnimation(1):SetAnimatedControl(areaTexture.left)
    areaTexture.animationIn:GetAnimation(2):SetAnimatedControl(areaTexture.right)
    areaTexture.animationIn:GetAnimation(3):SetAnimatedControl(areaTexture.center)

    for i = 4, areaTexture.animationIn:GetNumAnimations() do
        areaTexture.animationIn:GetAnimation(i):SetAnimatedControl(areaTexture)
    end

    areaTexture.resetAlphaAnimation = areaTexture.animationIn:GetLastAnimation()
    areaTexture.resetAlphaAnimation:SetEndAlpha(IsInGamepadPreferredMode() and AREA_TEXTURE_RESTING_ALPHA_GAMEPAD or AREA_TEXTURE_RESTING_ALPHA_KEYBOARD)

    local function OnAreaTextureInOnStop(animationOut)
        objectPool:ReleaseObject(animationOut.areaTexture.key)
    end

    areaTexture.animationOut = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassAreaTextureAnimationOut", areaTexture)
    areaTexture.animationOut:SetHandler("OnStop", OnAreaTextureInOnStop)
    areaTexture.animationOut.areaTexture = areaTexture

    return areaTexture
end

function Compass:OnAreaAnimationStarted(animationTimeline, areaTexturePinPool, ignorePinTexture, setAlphaFunction, setStartFrameFunction)
    local pin = animationTimeline:GetFirstAnimation():GetAnimatedControl()
    animationTimeline.pin = pin

    local areaTexture, key = areaTexturePinPool:AcquireObject()
    areaTexture.key = key
    animationTimeline.areaTexture = areaTexture
    areaTexture.pin = pin

    local animationPinType = animationTimeline.pinType
    if not animationPinType then
        return
    end

    local NO_RESTING_ALPHA = nil
    local compassAreaTextureTemplate = IsInGamepadPreferredMode() and "ZO_CompassAreaTexture_Gamepad_Template" or "ZO_CompassAreaTexture_Keyboard_Template"
    self:ApplyTemplateToAreaTexture(areaTexture, compassAreaTextureTemplate, NO_RESTING_ALPHA, animationPinType)
    if not ignorePinTexture then
        local pinTexture = SHOWN_AREA_PIN_TYPES_TO_ANIMATION_PIN_TEXTURE[animationPinType]
        internalassert(pinTexture ~= nil)
        pin:SetTexture(pinTexture)
    end

    areaTexture:SetAlpha(setAlphaFunction and setAlphaFunction(pin) or pin:GetAlpha())
    areaTexture:SetHidden(false)
    areaTexture.animationIn:PlayFromStart(setStartFrameFunction and setStartFrameFunction() or 0)
end

function Compass:OnAreaAnimationStopped(animationTimeline, areaAnimationPool)
    areaAnimationPool:ReleaseObject(animationTimeline.key)
    animationTimeline.areaTexture.animationIn:Stop()
    animationTimeline.areaTexture.animationOut:PlayFromStart()
end

function Compass:CreateAreaAnimationTimeline(OnAreaAnimationStarted, OnAreaAnimationStopped)
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassAreaPinAnimationOut")
    timeline.owner = self
    timeline:SetHandler("OnPlay", OnAreaAnimationStarted)
    timeline:SetHandler("OnStop", OnAreaAnimationStopped)
    return timeline
end

function Compass:OnQuestAreaGoalStateChanged(journalIndex, stepIndex, conditionIndex, playerIsInside)
    local _, _, _, isComplete = GetJournalQuestConditionValues(journalIndex, stepIndex, conditionIndex)
    if not isComplete and playerIsInside == self:IsPlayerInside(AREA_PIN_TYPE_NAME.QUEST_PINS, journalIndex, stepIndex, conditionIndex) then
        self.refreshingJournalIndex = true
    end

    if playerIsInside and IsQuestVisible(journalIndex) then
        self:PlayQuestAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
    else
        self:StopAreaPinOutAnimation(AREA_PIN_TYPE_NAME.QUEST_PINS, journalIndex - 1, stepIndex - 1, conditionIndex - 1)
        if self.areaOverrideQueue then
            for i=#self.areaOverrideQueue, 1, -1 do
                local nextOverride = self.areaOverrideQueue[i]
                if nextOverride.journalIndex == journalIndex and nextOverride.stepIndex == stepIndex and nextOverride.conditionIndex == conditionIndex then
                    table.remove(self.areaOverrideQueue, i)
                    if #self.areaOverrideQueue == 0 then
                        self.areaOverrideQueue = nil
                    end
                    break
                end
            end
        end
    end

    self:SetPlayerInside(AREA_PIN_TYPE_NAME.QUEST_PINS, journalIndex, stepIndex, conditionIndex, playerIsInside)
    self.refreshingJournalIndex = false
end

function Compass:OnPlayerInQuestPinAreaChanged(eventCode, pinType, param1, param2, param3, playerIsInside)
    local isAreaPin = ZO_MapPin.QUEST_CONDITION_PIN_TYPES[pinType]
    if isAreaPin then
        self:OnQuestAreaGoalStateChanged(param1 + 1, param2 + 1, param3 + 1, playerIsInside)
    end
end

function Compass:InitializeQuestPins()
    local areaTexturePinPool
    local function ResetAreaTexture(areaTexture)
        Compass.ResetAreaTexture(areaTexture)
    end

    local function CreateAreaTexture(objectPool)
        return self:CreateAreaTexture(AREA_PIN_TYPE_NAME.QUEST_PINS, objectPool)
    end

    areaTexturePinPool = ZO_ObjectPool:New(CreateAreaTexture, ResetAreaTexture)

    local function OnAreaAnimationStarted(animationTimeline)
        local USE_PIN_TEXTURE = false
        local function SetTextureAlpha(pin)
            return self.refreshingJournalIndex and 1 or pin:GetAlpha()
        end

        local function SetPlayFromFrame()
            return self.refreshingJournalIndex and 350 or 0
        end

        self:OnAreaAnimationStarted(animationTimeline, areaTexturePinPool, USE_PIN_TEXTURE, SetTextureAlpha, SetPlayFromFrame)
    end

    local function OnAreaAnimationStopped(animationTimeline)
        self:OnAreaAnimationStopped(animationTimeline, self.areaAnimationPools[AREA_PIN_TYPE_NAME.QUEST_PINS])
    end

    local function CreateAreaAnimationTimeline()
        return self:CreateAreaAnimationTimeline(OnAreaAnimationStarted, OnAreaAnimationStopped)
    end
    self.areaAnimationPools[AREA_PIN_TYPE_NAME.QUEST_PINS] = ZO_ObjectPool:New(CreateAreaAnimationTimeline, function() end)

    local function OnQuestTrackerTrackingStateChanged()
       local template = IsInGamepadPreferredMode() and "ZO_CompassAreaTexture_Gamepad_Template" or "ZO_CompassAreaTexture_Keyboard_Template"
       local restingAlpha = IsInGamepadPreferredMode() and AREA_TEXTURE_RESTING_ALPHA_GAMEPAD or AREA_TEXTURE_RESTING_ALPHA_KEYBOARD

       if self[AREA_PIN_TYPE_NAME.QUEST_PINS] then
            for _, journalEntry in pairs(self[AREA_PIN_TYPE_NAME.QUEST_PINS]) do
                for _, stepEntry in pairs(journalEntry) do
                    for _, animation in pairs(stepEntry) do
                        local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, animation.param1 + 1)
                        local newPinType = GetQuestPinTypeForTrackingLevel(animation.areaTexture.pinType, trackingLevel)

                        self:ApplyTemplateToAreaTexture(animation.areaTexture, template, restingAlpha, newPinType)
                    end
                end
            end
        end
    end

    FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerTrackingStateChanged", OnQuestTrackerTrackingStateChanged)

    local function OnQuestChanged(eventCode, journalIndex)
        self:RemoveAreaPinsByQuest(journalIndex)
    end

    local function OnQuestRemoved(eventCode, isCompleted, journalIndex)
        self:RemoveAreaPinsByQuest(journalIndex)
    end

    self.control:RegisterForEvent(EVENT_QUEST_ADVANCED, OnQuestChanged)
    self.control:RegisterForEvent(EVENT_QUEST_REMOVED, OnQuestRemoved)

    local function OnPlayerActivated()
        self.refreshingJournalIndex = true
        self:PerformFullAreaQuestUpdate()
        self.refreshingJournalIndex = false
        COMPASS_FRAME:SetCompassReady(true)
        self:OnZoneChanged()
    end
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:PerformFullAreaQuestUpdate() end)

    self:PerformFullAreaQuestUpdate()

    C_MAP_HANDLERS:RegisterCallback("RefreshedSingleQuestPins", function(questIndex) self:PerformFullAreaQuestUpdate() end)
    C_MAP_HANDLERS:RegisterCallback("RefreshedAllQuestPins", function() self.refreshingJournalIndex = true self:PerformFullAreaQuestUpdate() self.refreshingJournalIndex = false end)
end

function Compass:SetCardinalDirections(font)
    self.container:SetCardinalDirection(GetString(SI_COMPASS_NORTH_ABBREVIATION), font, CARDINAL_DIRECTION_NORTH)
    self.container:SetCardinalDirection(GetString(SI_COMPASS_EAST_ABBREVIATION), font, CARDINAL_DIRECTION_EAST)
    self.container:SetCardinalDirection(GetString(SI_COMPASS_WEST_ABBREVIATION), font, CARDINAL_DIRECTION_WEST)
    self.container:SetCardinalDirection(GetString(SI_COMPASS_SOUTH_ABBREVIATION), font, CARDINAL_DIRECTION_SOUTH)
end

function Compass:ApplyKeyboardStyle()
    ApplyTemplateToControl(self.control, "ZO_Compass_Keyboard_Template")
    self:ApplyTemplateToAreaTextures("ZO_CompassAreaTexture_Keyboard_Template", AREA_TEXTURE_RESTING_ALPHA_KEYBOARD)
    self:SetCardinalDirections("ZoFontHeader4")
end

function Compass:ApplyGamepadStyle()
    ApplyTemplateToControl(self.control, "ZO_Compass_Gamepad_Template")
    self:ApplyTemplateToAreaTextures("ZO_CompassAreaTexture_Gamepad_Template", AREA_TEXTURE_RESTING_ALPHA_GAMEPAD)
    self:SetCardinalDirections("ZoFontGamepadBold34")
end

function Compass:OnGamepadPreferredModeChanged()
    if IsInGamepadPreferredMode() then
        self:ApplyGamepadStyle()
    else
        self:ApplyKeyboardStyle()
    end
end

function Compass:PerformFullAreaQuestUpdate()
    for journalIndex = 1, MAX_JOURNAL_QUESTS  do
        if IsValidQuestIndex(journalIndex) then
            for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(journalIndex) do
                for conditionIndex = 1, GetJournalQuestNumConditions(journalIndex, stepIndex) do
                    if ShouldShowQuestArea(journalIndex, stepIndex, conditionIndex) then
                        self:PlayQuestAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
                    else
                        self:StopAreaPinOutAnimation(AREA_PIN_TYPE_NAME.QUEST_PINS, journalIndex - 1, stepIndex - 1, conditionIndex - 1)
                    end
                end
            end
        end
    end
end

function Compass:UpdateInsidePoiState()
    self.zoneIndex, self.poiIndex = GetCurrentSubZonePOIIndices()
end

function Compass:IsInsidePoi()
    return self.zoneIndex ~= nil
end

function Compass:OnZoneChanged()
    self:UpdateInsidePoiState()
    local isInPoi = self:IsInsidePoi()

    if isInPoi then
        self:PlayPoiPinOutAnimation()
    end
end

function Compass:TryPlayingAnimationOnSinglePoi(zoneIndex, poiIndex, pinType)
    local animation, key = self.poiAnimationPool:AcquireObject()
    if not StartMapPinAnimation(animation, PIN_ANIMATION_TARGET_MAP_ONLY, CT_COMPASS, pinType, zoneIndex - 1, poiIndex - 1) then
        self.poiAnimationPool:ReleaseObject(key)
    else
        animation.key = key
    end
end

function Compass:PlayPoiPinOutAnimation()
    self:TryPlayingAnimationOnSinglePoi(self.zoneIndex, self.poiIndex, MAP_PIN_TYPE_POI_SEEN)
    self:TryPlayingAnimationOnSinglePoi(self.zoneIndex, self.poiIndex, MAP_PIN_TYPE_POI_COMPLETE)
end

local IGNORE_BREADCRUMBS = true
function Compass:TryPlayingAnimationOnAreaPin(areaPinTypeName, param1, param2, param3, pinType)
    local animation, key = self.areaAnimationPools[areaPinTypeName]:AcquireObject()
    animation.pinType = pinType

    if not StartMapPinAnimation(animation, PIN_ANIMATION_TARGET_MAP_ONLY, CT_COMPASS, pinType, param1, param2, param3, nil, IGNORE_BREADCRUMBS) then
        self.areaAnimationPools[areaPinTypeName]:ReleaseObject(key)
        return false
    else
        animation.key = key
        animation.param1 = param1
        animation.param2 = param2
        animation.param3 = param3
        self:StoreAreaPinAnimation(areaPinTypeName, param1, param2, param3, animation)
        return true
    end
end

function Compass:PlayAreaOverrideAnimation(journalIndex, stepIndex, conditionIndex)
    local conditionText = GetJournalQuestConditionInfo(journalIndex, stepIndex, conditionIndex)

    self.areaOverrideLabel:SetText(conditionText)
    local desiredWidth = self.areaOverrideLabel:GetTextWidth() + 10
    local sizeAnimation = self.areaOverrideAnimation:GetFirstAnimation()

    sizeAnimation:SetStartAndEndWidth(0, desiredWidth)
    local currentAreaOverrideHeight = self.areaOverride:GetHeight()
    sizeAnimation:SetStartAndEndHeight(currentAreaOverrideHeight, currentAreaOverrideHeight) -- Make sure the height is the correct height for the current keyboard/gamepad template
    self.areaOverrideAnimation:PlayFromStart()

    self.currentOverrideJournalIndex = journalIndex
    self.currentOverrideStepIndex = stepIndex
    self.currentOverrideConditionIndex = conditionIndex
end

function Compass:PlayQuestAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
    local playedAnyAnimation = false
    for _, pinType in ipairs(QUEST_AREA_PIN_TYPES) do
        if self:TryPlayingAnimationOnAreaPin(AREA_PIN_TYPE_NAME.QUEST_PINS, journalIndex - 1, stepIndex - 1, conditionIndex - 1, pinType) then
            playedAnyAnimation = true
        end
    end

    if not self.refreshingJournalIndex and playedAnyAnimation and (self.currentOverrideJournalIndex ~= journalIndex or self.currentOverrideStepIndex ~= stepIndex or self.currentOverrideConditionIndex ~= conditionIndex) then
        if self.areaOverrideQueue then
            for i, nextOverride in ipairs(self.areaOverrideQueue) do
                if nextOverride.journalIndex == journalIndex and nextOverride.stepIndex == stepIndex and nextOverride.conditionIndex == conditionIndex then
                    return -- already queued
                end
            end
        end
        if self.areaOverrideAnimation:IsPlaying() then
            if not self.areaOverrideQueue then
                self.areaOverrideQueue = {}
            end
            self.areaOverrideQueue[#self.areaOverrideQueue + 1] = { journalIndex = journalIndex, stepIndex = stepIndex, conditionIndex = conditionIndex } 
        else
            self:PlayAreaOverrideAnimation(journalIndex, stepIndex, conditionIndex)
        end
    end
end

function Compass:StopAreaPinOutAnimation(areaPinTypeName, param1, param2, param3)
    local animation = self:GetAreaPinAnimationFromStorage(areaPinTypeName, param1, param2, param3)
    if animation then
        animation:Stop()
        self:RemoveAreaPinAnimationFromStorage(areaPinTypeName, param1, param2, param3)
    end
end

do
    local function CreatePath(t, ...)
        local current = t

        for i = 1, select("#", ...) do
            local key = select(i, ...)
            if not current[key] then
                current[key] = {}
            end
            current = current[key]
        end

        return current
    end

    function Compass:StoreAreaPinAnimation(areaPinTypeName, param1, param2, param3, animation)
        local path = CreatePath(self, areaPinTypeName, param1, param2)
        path[param3] = animation
    end

    function Compass:GetAreaPinAnimationFromStorage(areaPinTypeName, param1, param2, param3)
        local areaPinAnimations = self[areaPinTypeName]
        if areaPinAnimations then
            local areaPinAnimationsParam1 = areaPinAnimations[param1]
            if areaPinAnimationsParam1 then
                local areaPinAnimationsParam2 = areaPinAnimationsParam1[param2]
                if areaPinAnimationsParam2 then
                    return areaPinAnimationsParam2[param3]
                end
            end
        end
    end

    function Compass:RemoveAreaPinAnimationFromStorage(areaPinTypeName, param1, param2, param3)
        local areaPinAnimations = self[areaPinTypeName]
        if areaPinAnimations then
            local areaPinAnimationsParam1 = areaPinAnimations[param1]
            if areaPinAnimationsParam1 then
                local areaPinAnimationsParam2 = areaPinAnimationsParam1[param2]
                if areaPinAnimationsParam2 then
                    areaPinAnimationsParam2[param3] = nil
                end
            end
        end
    end

    function Compass:RemoveAreaPinsByQuest(journalIndex)
        local param1 = journalIndex - 1
        local questPinAreaAnimationPool = self.areaAnimationPools[AREA_PIN_TYPE_NAME.QUEST_PINS]
        if questPinAreaAnimationPool and questPinAreaAnimationPool[param1] then
            for i, step in ipairs(questPinAreaAnimationPool[param1]) do
                for j, animation in ipairs(step) do
                    animation:Stop()
                end
            end
            questPinAreaAnimationPool[param1] = nil
            self:ClearPlayerInside(AREA_PIN_TYPE_NAME.QUEST_PINS, journalIndex)
        end
    end

    function Compass:ApplyTemplateToAreaTextures(template, restingAlpha)
        for i, name in pairs(AREA_PIN_TYPE_NAME) do
            if self[name] then
                for _, param1Entry in pairs(self[name]) do
                    for _, param2Entry in pairs(param1Entry) do
                        for _, animation in pairs(param2Entry) do
                            self:ApplyTemplateToAreaTexture(animation.areaTexture, template, restingAlpha)
                        end
                    end
                end
            end
        end
    end
end

local function CalculateLayerInformedDistance(drawLayer, drawLevel)
    return (1.0 - (drawLevel / 0xFFFFFFFF)) - drawLayer
end 

do
    local pinTypeToFormatId =
    {
        [MAP_PIN_TYPE_POI_SEEN] = SI_COMPASS_LOCATION_NAME_FORMAT,
        [MAP_PIN_TYPE_POI_COMPLETE] = SI_COMPASS_LOCATION_NAME_FORMAT,
    }

    ZO_SetCachedStrFormatterOnlyStoreOne(SI_COMPASS_LOCATION_NAME_FORMAT)

    local TIME_BETWEEN_LABEL_UPDATES_MS = 100

    local bestPinIndices = {}
    local bestPinDistances = {}

    function Compass:OnUpdate()
        if self.areaOverrideAnimation:IsPlaying() then
            self.centerOverPinLabelAnimation:PlayBackward()
        elseif not self.centerOverPinLabelAnimation:IsPlaying() or not self.centerOverPinLabelAnimation:IsPlayingBackward() then
            local now = GetFrameTimeMilliseconds()
            if now < self.nextLabelUpdateTime then
                return
            end
            self.nextLabelUpdateTime = now + TIME_BETWEEN_LABEL_UPDATES_MS

            local bestPinDescription
            local bestPinType
            if not COMPASS_FRAME:GetBossBarActive() then
                ZO_ClearNumericallyIndexedTable(bestPinIndices)
                ZO_ClearNumericallyIndexedTable(bestPinDistances)
                for i = 1, self.container:GetNumCenterOveredPins() do
                    if not self.container:IsCenterOveredPinSuppressed(i) then
                        local drawLayer, drawLevel = self.container:GetCenterOveredPinLayerAndLevel(i)
                        local layerInformedDistance = CalculateLayerInformedDistance(drawLayer, drawLevel)
                        local insertIndex
                        for bestPinIndex = 1, #bestPinIndices do
                            if layerInformedDistance < bestPinDistances[bestPinIndex] then
                                insertIndex = bestPinIndex
                                break
                            end
                        end
                        if not insertIndex then
                            insertIndex = #bestPinIndices + 1
                        end

                        table.insert(bestPinIndices, insertIndex, i)
                        table.insert(bestPinDistances, insertIndex, layerInformedDistance)
                    end
                end

                for i, centeredPinIndex in ipairs(bestPinIndices) do
                    local description = self.container:GetCenterOveredPinDescription(centeredPinIndex)
                    if description ~= "" then
                        bestPinDescription = description
                        bestPinType = self.container:GetCenterOveredPinType(centeredPinIndex)
                        break
                    end
                end
            end

            if bestPinDescription then
                local formatId = pinTypeToFormatId[bestPinType]
                --The first 3 types are the player pins (self, group, leader)
                if bestPinType < 3 then
                    bestPinDescription = ZO_FormatUserFacingCharacterOrDisplayName(bestPinDescription)
                end
                if(formatId) then
                    self.centerOverPinLabel:SetText(ZO_CachedStrFormat(formatId, bestPinDescription))
                else
                    self.centerOverPinLabel:SetText(bestPinDescription)
                end

                self.centerOverPinLabelAnimation:PlayForward()
            else
                self.centerOverPinLabelAnimation:PlayBackward()
            end
        end
    end
end

function ZO_Compass_OnInitialize(control)
    COMPASS = Compass:New(control)
end

function ZO_CompassPoiPinAnimationOutUpdate(animation, progress, control)
    COMPASS:CompassPoiPinAnimationOutUpdate(animation, progress, control)
end

function ZO_Compass_AnimationIn_Size(control, animatingControl)
    local pinScale = animatingControl.pin:GetScale()
    local width, height = animatingControl:GetParent():GetDimensions()
    control:SetStartAndEndWidth(32 * pinScale, width + 36)
    control:SetStartAndEndHeight(32 * pinScale, height)
end

function ZO_Compass_AnimationIn_Translate(control, animatingControl)
    local parent = animatingControl:GetParent()
    local offsetX = animatingControl.pin:GetCenter() - parent:GetCenter()
    animatingControl:SetAnchor(CENTER, parent, CENTER, offsetX, 0)

    control:SetTranslateDeltas(-offsetX, 0)
end

function ZO_Compass_AnimationOut_Alpha(control, animatingControl)
    if control:GetTimeline().owner.refreshingJournalIndex then
        control:SetAlphaValues(0, 0)
    else
        control:SetAlphaValues(animatingControl:GetAlpha(), 0)
    end
end
