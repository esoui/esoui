Compass = ZO_Object:Subclass()

function Compass:New(...)
    local compass = ZO_Object.New(self)
    compass:Initialize(...)
    return compass
end

local function IsPlayerInsideJournalQuestConditionGoalArea(journalIndex, stepIndex, conditionIndex)
    journalIndex = journalIndex - 1
    stepIndex = stepIndex - 1
    conditionIndex = conditionIndex - 1
    return IsPlayerInsidePinArea(MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION, journalIndex, stepIndex, conditionIndex)
        or IsPlayerInsidePinArea(MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION, journalIndex, stepIndex, conditionIndex)
        or IsPlayerInsidePinArea(MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION, journalIndex, stepIndex, conditionIndex)
        or IsPlayerInsidePinArea(MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION, journalIndex, stepIndex, conditionIndex)
        or IsPlayerInsidePinArea(MAP_PIN_TYPE_TRACKED_QUEST_CONDITION, journalIndex, stepIndex, conditionIndex)
        or IsPlayerInsidePinArea(MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION, journalIndex, stepIndex, conditionIndex)
        or IsPlayerInsidePinArea(MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION, journalIndex, stepIndex, conditionIndex)
        or IsPlayerInsidePinArea(MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION, journalIndex, stepIndex, conditionIndex)
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

    self:InitializeCenterOveredPins()
    self:InitializePoiPins()
    self:InitializeQuestPins()

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

    return self:SetAreaTexturePlatformTextures(texture, pinType)
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

    return pinTypeAssisted
end

function Compass:InitializeQuestPins()
    local function ResetAreaTexture(areaTexture)
        areaTexture:SetHidden(true)
        areaTexture:ClearAnchors()
    end

    local areaTexturePinPool
    local function OnAreaTextureInOnStop(animationOut)
        areaTexturePinPool:ReleaseObject(animationOut.areaTexture.key)
    end
    
    local function CreateAreaTexture(objectPool)
        local areaTexture = ZO_ObjectPool_CreateControl("ZO_CompassAreaTexture", objectPool, self.control)

        areaTexture.animationIn = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassAreaTextureAnimationIn")
        areaTexture.animationIn:GetAnimation(1):SetAnimatedControl(areaTexture.left)
        areaTexture.animationIn:GetAnimation(2):SetAnimatedControl(areaTexture.right)
        areaTexture.animationIn:GetAnimation(3):SetAnimatedControl(areaTexture.center)

        for i=4, areaTexture.animationIn:GetNumAnimations() do
            areaTexture.animationIn:GetAnimation(i):SetAnimatedControl(areaTexture)
        end

        areaTexture.resetAlphaAnimation = areaTexture.animationIn:GetLastAnimation()
        areaTexture.resetAlphaAnimation:SetEndAlpha(IsInGamepadPreferredMode() and AREA_TEXTURE_RESTING_ALPHA_GAMEPAD or AREA_TEXTURE_RESTING_ALPHA_KEYBOARD)

        areaTexture.animationOut = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassAreaTextureAnimationOut", areaTexture)
        areaTexture.animationOut:SetHandler("OnStop", OnAreaTextureInOnStop)
        areaTexture.animationOut.areaTexture = areaTexture

        return areaTexture
    end
    
    areaTexturePinPool = ZO_ObjectPool:New(CreateAreaTexture, ResetAreaTexture)

    local function OnAreaAnimationStarted(animationTimeline)
        local pin = animationTimeline:GetFirstAnimation():GetAnimatedControl()
        animationTimeline.pin = pin

        local areaTexture, key = areaTexturePinPool:AcquireObject()
        local pinTypeAssited = self:ApplyTemplateToAreaTexture(areaTexture, IsInGamepadPreferredMode() and "ZO_CompassAreaTexture_Gamepad_Template" or "ZO_CompassAreaTexture_Keyboard_Template", nil, self.currentlyAnimatingAreaPinType)
        areaTexture.key = key
        animationTimeline.areaTexture = areaTexture
        areaTexture.pin = pin

        if pinTypeAssited then
            pin:SetTexture("EsoUI/Art/Compass/quest_icon_assisted.dds")
        else
            pin:SetTexture("EsoUI/Art/Compass/quest_icon.dds")
        end

        areaTexture:SetAlpha(self.refreshingJournalIndex and 1 or pin:GetAlpha())
        areaTexture:SetHidden(false)
        areaTexture.animationIn:PlayFromStart(self.refreshingJournalIndex and 350 or 0)
    end
    local function OnAreaAnimationStopped(animationTimeline)
        self.areaAnimationPool:ReleaseObject(animationTimeline.key)
        animationTimeline.areaTexture.animationIn:Stop()
        animationTimeline.areaTexture.animationOut:PlayFromStart()
    end
    local function CreateAreaAnimationTimeline()
        local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CompassAreaPinAnimationOut")
        timeline.owner = self
        timeline:SetHandler("OnPlay", OnAreaAnimationStarted)
        timeline:SetHandler("OnStop", OnAreaAnimationStopped)
        return timeline
    end
    self.areaAnimationPool = ZO_ObjectPool:New(CreateAreaAnimationTimeline, function() end)

    local function OnQuestAreaGoalStateChanged(journalIndex, stepIndex, conditionIndex, playerIsInside)
        if playerIsInside and IsQuestVisible(journalIndex) then
            self:PlayAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
        else
            self:StopAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
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
    end

    local function OnPlayerInPinAreaChanged(eventCode, pinType, param1, param2, param3, playerIsInside)
        local isAreaPin = ZO_MapPin.QUEST_CONDITION_PIN_TYPES[pinType]
        if isAreaPin then
            OnQuestAreaGoalStateChanged(param1 + 1, param2 + 1, param3 + 1, playerIsInside)
        end
    end

    self.control:RegisterForEvent(EVENT_PLAYER_IN_PIN_AREA_CHANGED, OnPlayerInPinAreaChanged)

    local function OnQuestRemovedOrChanged(eventCode, journalIndex)
        self:RemoveAreaPinsByQuest(journalIndex)
    end
    self.control:RegisterForEvent(EVENT_QUEST_ADVANCED, OnQuestRemovedOrChanged)
    self.control:RegisterForEvent(EVENT_QUEST_REMOVED, OnQuestRemovedOrChanged)

    local function OnPlayerActivated()
        self:PerformFullAreaQuestUpdate()
        COMPASS_FRAME:SetCompassReady(true)
        self:OnZoneChanged()
    end
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:PerformFullAreaQuestUpdate() end)

    self:PerformFullAreaQuestUpdate()

    QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", function(assisted, unassisted) self:PerformFullAreaQuestUpdate() end)
    QUEST_TRACKER:RegisterCallback("QuestTrackerRefreshedMapPins", function() self.refreshingJournalIndex = true self:PerformFullAreaQuestUpdate() self.refreshingJournalIndex = false end)
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
                        self:PlayAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
                    else
                        self:StopAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
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
    if not StartMapPinAnimation(animation, PIN_ANIMATION_TARGET_MAP, CT_COMPASS, pinType, zoneIndex - 1, poiIndex - 1) then
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
function Compass:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, pinType)
    local animation, key = self.areaAnimationPool:AcquireObject()
    self.currentlyAnimatingAreaPinType = pinType
    if not StartMapPinAnimation(animation, PIN_ANIMATION_TARGET_MAP, CT_COMPASS, pinType, journalIndex - 1, stepIndex - 1, conditionIndex - 1, nil, IGNORE_BREADCRUMBS) then
        self.areaAnimationPool:ReleaseObject(key)
        self.currentlyAnimatingAreaPinType = nil
        return false
    else
        animation.key = key
        self:StoreAreaPinAnimation(journalIndex, stepIndex, conditionIndex, animation)
        self.currentlyAnimatingAreaPinType = nil
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

function Compass:PlayAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
    local playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION)
    playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION) or playedAnyAnimation
    playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION) or playedAnyAnimation
    playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION) or playedAnyAnimation
    playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_TRACKED_QUEST_CONDITION) or playedAnyAnimation
    playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION) or playedAnyAnimation
    playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION) or playedAnyAnimation
    playedAnyAnimation = self:TryPlayingAnimationOnAreaPin(journalIndex, stepIndex, conditionIndex, MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION) or playedAnyAnimation

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

function Compass:StopAreaPinOutAnimation(journalIndex, stepIndex, conditionIndex)
    local animation = self:GetAreaPinAnimationFromStorage(journalIndex, stepIndex, conditionIndex)
    if animation then
        animation:Stop()
        self:RemoveAreaPinAnimationFromStorage(journalIndex, stepIndex, conditionIndex)
    end
end

do
    local function CreatePath(t, ...)
        local current = t

        for i=1, select("#", ...) do
            local key = select(i, ...)
            if not current[key] then
                current[key] = {}
            end
            current = current[key]
        end

        return current
    end

    function Compass:StoreAreaPinAnimation(journalIndex, stepIndex, conditionIndex, animation)
        local path = CreatePath(self, "areaPinAnimations", journalIndex, stepIndex)
        path[conditionIndex] = animation
    end

    function Compass:GetAreaPinAnimationFromStorage(journalIndex, stepIndex, conditionIndex)
        if self.areaPinAnimations then
            if self.areaPinAnimations[journalIndex] then
                if self.areaPinAnimations[journalIndex][stepIndex] then
                    return self.areaPinAnimations[journalIndex][stepIndex][conditionIndex]
                end
            end
        end
    end

    function Compass:RemoveAreaPinAnimationFromStorage(journalIndex, stepIndex, conditionIndex)
        self.areaPinAnimations[journalIndex][stepIndex][conditionIndex] = nil
    end

    function Compass:RemoveAreaPinsByQuest(journalIndex)
        if self.areaPinAnimations and self.areaPinAnimations[journalIndex] then
            for i, step in ipairs(self.areaPinAnimations[journalIndex]) do
                for j, animation in ipairs(step) do
                    animation:Stop()
                end
            end
            self.areaPinAnimations[journalIndex] = nil
        end
    end

    function Compass:ApplyTemplateToAreaTextures(template, restingAlpha)
        if self.areaPinAnimations then
            for _, journalEntry in pairs(self.areaPinAnimations) do
                for _, stepEntry in pairs(journalEntry) do
                    for _, animation in pairs(stepEntry) do
                        self:ApplyTemplateToAreaTexture(animation.areaTexture, template, restingAlpha)
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
            if not (DoesUnitExist("boss1") or DoesUnitExist("boss2")) then
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
                    self.centerOverPinLabel:SetText(zo_strformat(formatId, bestPinDescription))
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
