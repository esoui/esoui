local function GetValueOrExecute(value, ...)
    if type(value) == "function" then
        return value(...)
    end
    return value
end

local function DefaultCompareNilable(first, second)
    if first and second then
        return first < second
    elseif first then
        return true
    else
        return false
    end
end

------------------
-- Pins Manager --
------------------

ZO_WorldMapPins_Manager = ZO_ObjectPool:Subclass()

function ZO_WorldMapPins_Manager:Initialize(parentControl)
    local mouseInputGroup = ZO_MouseInputGroup:New(parentControl)

    local function CreatePin(pool)
        local pin = ZO_MapPin:New(parentControl)
        mouseInputGroup:Add(pin:GetControl(), ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
        return pin
    end

    local function ResetPin(pin)
        self:OnMouseOverPinReset(pin)
        pin:Reset()
    end

    ZO_ObjectPool.Initialize(self, CreatePin, ResetPin)

    self.mouseInputGroup = mouseInputGroup

    -- Each of these tables holds a method of mapping pin lookup indices to the actual object pool keys needed to release the pins later
    -- The reason this exists is because the game events will hold info like "remove this specific quest index", and at that point we
    -- need to be able to lookup a pin for game-event data rather than pinTag data, without iterating over every single pin in the
    -- active objects list.
    self.m_keyToPinMapping =
    {
        ["poi"] = {},       -- { [zone index 1] = { [objective index 1] = pinKey1, [objective index 2] = pinKey2,  ... }, ... }
        ["loc"] = {},
        ["quest"] = {},     -- { [quest index 1] = { [quest pin tag 1] = pinKey1, [quest pin tag 2] = pinKey2, ... }, ... }
        ["objective"] = {},
        ["keep"] = {},
        ["pings"] = {},
        ["killLocation"] = {},
        ["fastTravelKeep"] = {},
        ["fastTravelWayshrine"] = {},
        ["forwardCamp"] = {},
        ["AvARespawn"] = {},
        ["group"] = {},
        ["restrictedLink"] = {},
        ["suggestion"] = {},
        ["worldEventUnit"] = {},
        ["worldEventPOI"] = {},
        ["antiquityDigSite"] = {},
        ["companion"] = {},
        ["skyshard"] = {},
    }

    self.nextCustomPinType = MAP_PIN_TYPE_INVALID
    self.customPins = {}
    self.objectiveMovingPins = {}
    self.movingPins = {}
    self.currentMouseOverPins = {}
    self.previousMouseOverPins = {}
    self.mousedOverPinWasReset = false
    self.invalidateTooltip = false
    self.mouseExitPins = {}
    self.foundTooltipMouseOverPins = {}

    self.pinBlobPool = ZO_ControlPool:New("ZO_PinBlob", parentControl, "PinBlob")

    self.pinBlobPool:SetCustomResetBehavior(function(blobControl)
        blobControl:SetAlpha(1)
    end)

    self.pinPolygonBlobPool = ZO_ControlPool:New("ZO_PinPolygonBlob", parentControl, "PinPolygonBlob")

    self.pinPolygonBlobPool:SetCustomFactoryBehavior(function(blobControl)
        mouseInputGroup:Add(blobControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    end)

    self.pinPolygonBlobPool:SetCustomResetBehavior(function(blobControl)
        blobControl:SetHandler("OnMouseUp", nil)
        blobControl:SetHandler("OnMouseDown", nil)
        blobControl:SetAlpha(1)
    end)

    self.pinFadeInAnimationPool = ZO_AnimationPool:New("ZO_WorldMapPinFadeIn")

    local function OnAnimationTimelineStopped(timeline)
        self.pinFadeInAnimationPool:ReleaseObject(timeline.key)
    end

    local function SetupTimeline(timeline)
        timeline:SetHandler("OnStop", OnAnimationTimelineStopped)
    end

    self.pinFadeInAnimationPool:SetCustomFactoryBehavior(SetupTimeline)

    local function ResetTimeline(animationTimeline)
        local pinAnimation = animationTimeline:GetAnimation(1)
        pinAnimation:SetAnimatedControl(nil)

        local areaAnimation = animationTimeline:GetAnimation(2)
        areaAnimation:SetAnimatedControl(nil)
    end

    self.pinFadeInAnimationPool:SetCustomResetBehavior(ResetTimeline)

    --Wait until the map mode has been set before fielding these updates since adding a pin depends on the map having a mode.
    local OnWorldMapModeChanged
    OnWorldMapModeChanged = function(modeData)
        if modeData then
            WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback("QuestAvailable", function(...) self:OnQuestAvailable(...) end)
            WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback("QuestRemoved", function(...) self:OnQuestRemoved(...) end)
            CALLBACK_MANAGER:UnregisterCallback("OnWorldMapModeChanged", OnWorldMapModeChanged)
        end
    end
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", OnWorldMapModeChanged)

    FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", function(...) self:OnAssistStateChanged(...) end)
end

function ZO_WorldMapPins_Manager:AcquirePinBlob()
    return self.pinBlobPool:AcquireObject()
end

function ZO_WorldMapPins_Manager:ReleasePinBlob(pinBlobKey)
    self.pinBlobPool:ReleaseObject(pinBlobKey)
end

function ZO_WorldMapPins_Manager:AcquirePinPolygonBlob()
    return self.pinPolygonBlobPool:AcquireObject()
end

function ZO_WorldMapPins_Manager:ReleasePinPolygonBlob(pinBlobKey)
    self.pinPolygonBlobPool:ReleaseObject(pinBlobKey)
end

function ZO_WorldMapPins_Manager:AcquirePinFadeInAnimation()
    local animation, key = self.pinFadeInAnimationPool:AcquireObject()
    animation.key = key
    return animation
end

function ZO_WorldMapPins_Manager:OnQuestAvailable(questIndex)
    self:AddQuestPin(questIndex)
end

function ZO_WorldMapPins_Manager:OnQuestRemoved(questIndex)
    self:RemovePins("quest", questIndex)
    local questPingData = ZO_WorldMap_GetQuestPingData()
    if questPingData and questPingData.questIndex == questIndex then
         self:RemovePins("pings", MAP_PIN_TYPE_QUEST_PING)
    end
end

function ZO_WorldMapPins_Manager:OnAssistStateChanged(unassistedData, assistedData)
    if unassistedData then
        self:SetQuestPinsAssisted(unassistedData:GetJournalIndex(), false)
    end
    if assistedData then
        self:SetQuestPinsAssisted(assistedData:GetJournalIndex(), true)
    end
    self:InvalidateTooltip()
end

function ZO_WorldMapPins_Manager:SetQuestPinsAssisted(questIndex, assisted)
    local pins = self:GetActiveObjects()

    for pinKey, pin in pairs(pins) do
        local currentIndex = pin:GetQuestIndex()
        if currentIndex == questIndex then
            local currentPinType = pin:GetPinType()
            local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, questIndex)
            local newPinType = GetQuestPinTypeForTrackingLevel(currentPinType, trackingLevel)
            pin:ChangePinType(newPinType)
        end
    end
end

function ZO_WorldMapPins_Manager:PingQuest(questIndex, animation)
    local pins = self:GetActiveObjects()

    for pinKey, pin in pairs(pins) do
        local pinQuestIndex = pin:GetQuestIndex()
        if pinQuestIndex > -1 then
            if pinQuestIndex == questIndex then
                pin:PingMapPin(animation)
            else
                pin:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_HIDE_CONTROL)
            end
        end
    end
end

do
    local GLOBAL_MAPS =
    {
        [MAPTYPE_WORLD] = true,
        [MAPTYPE_COSMIC] = true,
    }

    function ZO_WorldMapPins_Manager.IsCurrentMapGlobal()
        return GLOBAL_MAPS[GetMapType()]
    end
end

function ZO_WorldMapPins_Manager:AddQuestPin(questIndex)
    if not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_QUESTS) then
        return
    end

    local questSteps = WORLD_MAP_QUEST_BREADCRUMBS:GetSteps(questIndex)
    if questSteps then
        local NO_RADIUS = nil
        local NO_BORDER_INFO = nil
        local IS_SYMBOLIC_LOCATION = true
        for stepIndex, questConditions in pairs(questSteps) do
            for conditionIndex, conditionData in pairs(questConditions) do
                local xLoc, yLoc = conditionData.xLoc, conditionData.yLoc
                if conditionData.insideCurrentMapWorld and ZO_WorldMap_IsNormalizedPointInsideMapBounds(xLoc, yLoc) then
                    local tag = ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
                    local areaRadius = self.IsCurrentMapGlobal() and 0 or conditionData.areaRadius
                    tag.isBreadcrumb = conditionData.isBreadcrumb
                    if not self.IsCurrentMapGlobal() or (FOCUSED_QUEST_TRACKER:IsOnTracker(TRACK_TYPE_QUEST, questIndex) and not IsZoneStoryAssisted()) then
                        local pin = self:CreatePin(conditionData.pinType, tag, xLoc, yLoc, areaRadius, NO_BORDER_INFO, conditionData.symbolicState == QUEST_PIN_STATE_IS_SYMBOLIC_POSITION)

                        if conditionData.symbolicState == QUEST_PIN_STATE_HAS_ADDITIONAL_SYMBOLIC_POSITION then
                            local additionalSymbolicLocX, additionalSymbolicLocY = conditionData.additionalSymbolicLocX, conditionData.additionalSymbolicLocY
                            local questPinTag = ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
                            self:CreatePin(conditionData.pinType, questPinTag, additionalSymbolicLocX, additionalSymbolicLocY, NO_RADIUS, NO_BORDER_INFO, IS_SYMBOLIC_LOCATION)
                        end

                        if pin:DoesQuestDataMatchQuestPingData() then
                            local questPinTag = ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
                            self:CreatePin(MAP_PIN_TYPE_QUEST_PING, questPinTag, xLoc, yLoc, NO_RADIUS, NO_BORDER_INFO, conditionData.symbolicState == QUEST_PIN_STATE_IS_SYMBOLIC_POSITION)
                        end
                    end
                elseif conditionData.symbolicState == QUEST_PIN_STATE_HAS_ADDITIONAL_SYMBOLIC_POSITION then
                    local additionalSymbolicLocX, additionalSymbolicLocY = conditionData.additionalSymbolicLocX, conditionData.additionalSymbolicLocY
                    local questPinTag = ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
                    self:CreatePin(conditionData.pinType, questPinTag, additionalSymbolicLocX, additionalSymbolicLocY, NO_RADIUS, NO_BORDER_INFO, IS_SYMBOLIC_LOCATION)
                end
            end
        end
    end
end

function ZO_WorldMapPins_Manager:GetNextCustomPinType()
    self.nextCustomPinType = self.nextCustomPinType + 1
    return self.nextCustomPinType
end

function ZO_WorldMapPins_Manager:CreateCustomPinType(pinTypeString)
    local pinTypeId = self:GetNextCustomPinType()
    _G[pinTypeString] = pinTypeId
    return pinTypeId
end

function ZO_WorldMapPins_Manager:AddCustomPin(pinTypeString, pinTypeAddCallback, pinTypeOnResizeCallback, pinLayoutData, pinTooltipCreator)
    if _G[pinTypeString] ~= nil then return end

    local pinTypeId = self:CreateCustomPinType(pinTypeString)

    self.m_keyToPinMapping[pinTypeString] = {}

    self.customPins[pinTypeId] =
    { 
        enabled = false,
        layoutCallback = pinTypeAddCallback,
        resizeCallback = pinTypeOnResizeCallback,
        pinTypeString = pinTypeString
    }
    ZO_MapPin.TOOLTIP_CREATORS[pinTypeId] = pinTooltipCreator
    ZO_MapPin.PIN_DATA[pinTypeId] = pinLayoutData
end

function ZO_WorldMapPins_Manager:SetCustomPinEnabled(pinType, enabled)
    local pinData = self.customPins[pinType]
    if pinData then
        pinData.enabled = enabled
    end
end

function ZO_WorldMapPins_Manager:IsCustomPinEnabled(pinType)
    local pinData = self.customPins[pinType]
    if pinData then
        return pinData.enabled
    end
end

function ZO_WorldMapPins_Manager:RefreshCustomPins(optionalPinType)
    for pinTypeId, pinData in pairs(self.customPins) do
        if optionalPinType == nil or optionalPinType == pinTypeId then
            self:RemovePins(pinData.pinTypeString)

            if pinData.enabled then
                pinData.layoutCallback(self)
            end
        end
    end
end

function ZO_WorldMapPins_Manager:MapPinLookupToPinKey(lookupType, majorIndex, keyIndex, pinKey)
    local lookupTable = self.m_keyToPinMapping[lookupType]

    local keys = lookupTable[majorIndex]
    if not keys then
        keys = {}
        lookupTable[majorIndex] = keys
    end

    keys[keyIndex] = pinKey
end

do
    local SYMBOLIC_PIN_SIZE = 28

    local function SortGroupPinsFunction(pinA, pinB)
        local pinTypeA = pinA:GetPinType()
        local pinTypeB = pinB:GetPinType()

        if pinTypeA == pinTypeB then
            return pinA:GetPinId() < pinB:GetPinId()
        end

        if pinA:IsQuest() and pinB:IsQuest() then
            return pinTypeA < pinTypeB
        elseif pinA:IsQuest() then
            return true
        elseif pinB:IsQuest() then
            return false
        end

        if pinTypeA == MAP_PIN_TYPE_PLAYER then
            return true
        elseif pinTypeB == MAP_PIN_TYPE_PLAYER then
            return false
        end

        if pinA:IsGroup() and pinB:IsGroup() then
            return pinTypeA == MAP_PIN_TYPE_GROUP_LEADER
        elseif pinA:IsGroup() then
            return false
        elseif pinB:IsGroup() then
            return true
        end

        return pinTypeA < pinTypeB
    end

    local PIN_TYPE_QUEST = 1
    local PIN_TYPE_PLAYER = 2
    local PIN_TYPE_GROUP = 3

    local function IsPlayerPin(pin)
        return pin:GetPinType() == MAP_PIN_TYPE_PLAYER
    end

    local function IsQuestPin(pin)
        return pin:IsQuest() or pin:GetPinType() == MAP_PIN_TYPE_QUEST_PING
    end

   local function IsGroupPin(pin)
        return pin:IsGroup()
    end

    local PIN_TYPE_FUNCTION =
    {
        [PIN_TYPE_QUEST] = IsQuestPin,
        [PIN_TYPE_PLAYER] = IsPlayerPin,
        [PIN_TYPE_GROUP] = IsGroupPin,
    }

    local function GetPinOverlapMultiplierX(pinIndex, totalPins)
        return ((totalPins - 1) * -0.5) + (pinIndex - 1)
    end

    local function GetPinOverlapMultiplierY(pinIndex, totalPins)
        return 0.5
    end

    function ZO_WorldMapPins_Manager:UpdateSymbolicPins()
        local symbolicPinsByLocation = {}
        for _, activePin in self:ActiveObjectIterator() do
            if activePin:IsSymbolicPosition() then
                local locationFound = false
                local originalX, originalY = activePin:GetOriginalPosition()
                for _, locationPins in ipairs(symbolicPinsByLocation) do
                    if locationPins.x == originalX and locationPins.y == originalY then
                        table.insert(locationPins.activePins, activePin)
                        locationFound = true
                    end
                end

                if not locationFound then
                    local locationData =
                    {
                        x = originalX,
                        y = originalY,
                        activePins = { activePin },
                    }
                    table.insert(symbolicPinsByLocation, locationData)
                end
            end
        end

        for _, locationData in pairs(symbolicPinsByLocation) do
            table.sort(locationData.activePins, SortGroupPinsFunction)

            local totalPinTypes = 0
            local pinsByType = {}
            for locationIndex, activePin in ipairs(locationData.activePins) do
                for pinTypeIndex = PIN_TYPE_QUEST, PIN_TYPE_GROUP do
                    if PIN_TYPE_FUNCTION[pinTypeIndex](activePin) then
                        if not pinsByType[pinTypeIndex] then
                            pinsByType[pinTypeIndex] = {}
                            totalPinTypes = totalPinTypes + 1
                        end
                        table.insert(pinsByType[pinTypeIndex], activePin)
                    end
                end
            end

            local index = 1
            for pinType, typePins in pairs(pinsByType) do
                local offsetMultiplierX = GetPinOverlapMultiplierX(index, totalPinTypes)
                local offsetMultiplierY = GetPinOverlapMultiplierY(index, totalPinTypes)
                local isFirstOfTypeShown = false
                for i, pin in ipairs(typePins) do
                    pin:SetOverlapOffsets(offsetMultiplierX * SYMBOLIC_PIN_SIZE, offsetMultiplierY * SYMBOLIC_PIN_SIZE)
                    pin:UpdateLocation()

                    if not isFirstOfTypeShown then
                        pin:GetControl():SetAlpha(1)
                        isFirstOfTypeShown = true
                    elseif pinType == PIN_TYPE_GROUP then
                        pin:GetControl():SetAlpha(0)
                    else
                        pin:GetControl():SetAlpha(1)
                    end
                end
                index = index + 1
            end
        end
    end

    function ZO_WorldMapPins_Manager:CreatePin(pinType, pinTag, xLoc, yLoc, radius, borderInformation, isSymbolicLoc)
        local pin, pinKey = self:AcquireObject()
        pin:SetData(pinType, pinTag)
        pin:SetOriginalPosition(xLoc, yLoc)
        pin:SetIsSymbolicPosition(isSymbolicLoc)
        pin:SetLocation(xLoc, yLoc, radius, borderInformation)

        self:UpdateSymbolicPins()

        if pinType == MAP_PIN_TYPE_PLAYER then
            pin:PingMapPin(ZO_MapPin.PulseAnimation)
            self.playerPin = pin
        end

        if not pin:ValidatePvPPinAllowed() then
            self:ReleaseObject(pinKey)
            return
        end

        if pin:IsPOI() then
            self:MapPinLookupToPinKey("poi", pin:GetPOIZoneIndex(), pin:GetPOIIndex(), pinKey)
        elseif pin:IsLocation() then
            self:MapPinLookupToPinKey("loc", pin:GetLocationIndex(), pin:GetLocationIndex(), pinKey)
        elseif pin:IsQuest() then
            self:MapPinLookupToPinKey("quest", pin:GetQuestIndex(), pinTag, pinKey)
        elseif pin:IsObjective() then
            self:MapPinLookupToPinKey("objective", pin:GetObjectiveKeepId(), pinTag, pinKey)
        elseif pin:IsKeepOrDistrict() then
            self:MapPinLookupToPinKey("keep", pin:GetKeepId(), pin:IsUnderAttackPin(), pinKey)
        elseif pin:IsMapPing() then
            self:MapPinLookupToPinKey("pings", pinType, pinTag, pinKey)
        elseif pin:IsKillLocation() then
            self:MapPinLookupToPinKey("killLocation", pinType, pinTag, pinKey)
        elseif pin:IsFastTravelKeep() then
            self:MapPinLookupToPinKey("fastTravelKeep", pin:GetFastTravelKeepId(), pin:GetFastTravelKeepId(), pinKey)
        elseif pin:IsFastTravelWayShrine() then
            self:MapPinLookupToPinKey("fastTravelWayshrine", pinType, pinTag, pinKey)
        elseif pin:IsForwardCamp() then
            self:MapPinLookupToPinKey("forwardCamp", pinType, pinTag, pinKey)
        elseif pin:IsAvARespawn() then
            self:MapPinLookupToPinKey("AvARespawn", pinType, pinTag, pinKey)
        elseif pin:IsGroup() then
            self:MapPinLookupToPinKey("group", pinType, pinTag, pinKey)
        elseif pin:IsRestrictedLink() then
            self:MapPinLookupToPinKey("restrictedLink", pinType, pinTag, pinKey)
        elseif pin:IsSuggestion() then
            self:MapPinLookupToPinKey("suggestion", pinType, pinTag, pinKey)
        elseif pin:IsWorldEventUnitPin() then
            self:MapPinLookupToPinKey("worldEventUnit", pin:GetWorldEventInstanceId(), pin:GetUnitTag(), pinKey)
        elseif pin:IsWorldEventPOIPin() then
            self:MapPinLookupToPinKey("worldEventPOI", pin:GetWorldEventInstanceId(), pinTag, pinKey)
        elseif pin:IsAntiquityDigSitePin() then
            self:MapPinLookupToPinKey("antiquityDigSite", pinType, pinTag, pinKey)
        elseif pin:IsCompanion() then
            self:MapPinLookupToPinKey("companion", pinType, pinTag, pinKey)
        elseif pin:IsSkyshard() then
            self:MapPinLookupToPinKey("skyshard", pinType, pinTag, pinKey)
        else
            local customPinData = self.customPins[pinType]
            if customPinData then
                self:MapPinLookupToPinKey(customPinData.pinTypeString, pinType, pinTag, pinKey)
            end
        end

        ZO_WorldMap_GetPanAndZoom():OnPinCreated()

        return pin
    end
end

function ZO_WorldMapPins_Manager:FindPin(lookupType, majorIndex, keyIndex)
    local lookupTable = self.m_keyToPinMapping[lookupType]
    local keys
    if majorIndex then
        keys = lookupTable[majorIndex]
    else
        keys = select(2, next(lookupTable))
    end

    if keys then
        local pinKey
        if keyIndex then
            pinKey = keys[keyIndex]
        else
            pinKey = select(2, next(keys))
        end

        if pinKey then
            return self:GetActiveObject(pinKey)
        end
    end
end

function ZO_WorldMapPins_Manager:AddPinsToArray(pins, lookupType, majorIndex)
    local lookupTable = self.m_keyToPinMapping[lookupType]

    local function AddPinsForKeys(keysTable)
        if keysTable then
            for _, pinKey in pairs(keysTable) do
                local pin = self:GetActiveObject(pinKey)
                if pin then
                    table.insert(pins, pin)
                end
            end
        end
    end

    if majorIndex then
        local keys = lookupTable[majorIndex]
        AddPinsForKeys(keys)
    else
        for _, keys in pairs(lookupTable) do
            AddPinsForKeys(keys)
        end
    end

    return pins
end

function ZO_WorldMapPins_Manager:RemovePins(lookupType, majorIndex, keyIndex)
    local lookupTable = self.m_keyToPinMapping[lookupType]

    if majorIndex then
        local keys = lookupTable[majorIndex]
        if keys then
            if keyIndex then
                 --Remove a specific pin
                local pinKey = keys[keyIndex]
                if pinKey then
                    self:ReleaseObject(pinKey)
                    keys[keyIndex] = nil
                end
            else
                --Remove all pins in the major index
                for _, pinKey in pairs(keys) do
                    self:ReleaseObject(pinKey)
                end

                self.m_keyToPinMapping[lookupType][majorIndex] = {}
            end
        end
    else
        --Remove all pins of the lookup type
        for _, keys in pairs(lookupTable) do
            for _, pinKey in pairs(keys) do
                self:ReleaseObject(pinKey)
            end
        end

        self.m_keyToPinMapping[lookupType] = {}
    end
end

function ZO_WorldMapPins_Manager:UpdatePinsForMapSizeChange()
    local pins = self:GetActiveObjects()
    for pinKey, pin in pairs(pins) do
        pin:UpdateLocation()
        pin:UpdateSize()
    end

    for pinTypeId, pinData in pairs(self.customPins) do
        if pinData.enabled and pinData.resizeCallback then
            pinData.resizeCallback(self, ZO_MAP_CONSTANTS.MAP_WIDTH, ZO_MAP_CONSTANTS.MAP_HEIGHT)
        end
    end
end

function ZO_WorldMapPins_Manager:GetWayshrinePin(nodeIndex)
    local pins = self:GetActiveObjects()

    for pinKey, pin in pairs(pins) do
        local currentIndex = pin:GetFastTravelNodeIndex()
        if currentIndex == nodeIndex then
            return pin
        end
    end
end

function ZO_WorldMapPins_Manager:GetQuestConditionPin(questIndex)
    local pins = self:GetActiveObjects()

    for pinKey, pin in pairs(pins) do
        local currentIndex = pin:GetQuestIndex()
        if currentIndex == questIndex then
            return pin
        end
    end
end

function ZO_WorldMapPins_Manager:GetPlayerPin()
    return self.playerPin
end

do
    local function IsMapShowingBattlegroundContext(bgContext)
        local _, queryType = ZO_WorldMap_GetCampaign()
        return (queryType == BGQUERY_LOCAL and IsLocalBattlegroundContext(bgContext))
                or (queryType == BGQUERY_ASSIGNED_CAMPAIGN and IsAssignedBattlegroundContext(bgContext))
    end

    function ZO_WorldMapPins_Manager:RefreshObjectives()
        self:RemovePins("objective")
        ZO_ClearNumericallyIndexedTable(self.objectiveMovingPins)

        local mapFilterType = GetMapFilterType()
        if mapFilterType ~= MAP_FILTER_TYPE_AVA_CYRODIIL and mapFilterType ~= MAP_FILTER_TYPE_BATTLEGROUND then
            return
        end

        local numObjectives = GetNumObjectives()

        local worldMapAvAPinsShown = ZO_WorldMap_IsPinGroupShown(MAP_FILTER_AVA_OBJECTIVES)

        for i = 1, numObjectives do
            local keepId, objectiveId, bgContext = GetObjectiveIdsForIndex(i)
            local isEnabled = IsObjectiveEnabled(keepId, objectiveId, bgContext)

            if isEnabled then
                local isVisible = IsObjectiveObjectVisible(keepId, objectiveId, bgContext)
                if ZO_WorldMap_IsObjectiveShown(keepId, objectiveId, bgContext) and IsMapShowingBattlegroundContext(bgContext) then
                    --spawn locations
                    local spawnPinType, spawnX, spawnY = GetObjectiveSpawnPinInfo(keepId, objectiveId, bgContext)
                    if spawnPinType ~= MAP_PIN_TYPE_INVALID then
                        if worldMapAvAPinsShown then
                            if ZO_WorldMap_IsNormalizedPointInsideMapBounds(spawnX, spawnY) then
                                local spawnTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                                self:CreatePin(spawnPinType, spawnTag, spawnX, spawnY)
                            end
                        end
                    end

                    --return locations
                    local returnPinType, returnX, returnY, returnContinuousUpdate = GetObjectiveReturnPinInfo(keepId, objectiveId, bgContext)
                    if returnPinType ~= MAP_PIN_TYPE_INVALID then
                        local returnTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                        local returnPin = self:CreatePin(returnPinType, returnTag, returnX, returnY)

                        if returnContinuousUpdate then
                            table.insert(self.objectiveMovingPins, returnPin)
                        end
                    end

                    -- current locations
                    local pinType, currentX, currentY, continuousUpdate = GetObjectivePinInfo(keepId, objectiveId, bgContext)
                    if isVisible and pinType ~= MAP_PIN_TYPE_INVALID then
                        if worldMapAvAPinsShown then
                            if ZO_WorldMap_IsNormalizedPointInsideMapBounds(currentX, currentY) then
                                local objectiveTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                                local objectivePin = self:CreatePin(pinType, objectiveTag, currentX, currentY)

                                if objectivePin then
                                    local auraPinType = GetObjectiveAuraPinInfo(keepId, objectiveId, bgContext)
                                    local auraPin
                                    if auraPinType ~= MAP_PIN_TYPE_INVALID then
                                        local auraTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                                        auraPin = self:CreatePin(auraPinType, auraTag, currentX, currentY)
                                        objectivePin:AddScaleChild(auraPin)
                                    end

                                    if continuousUpdate then
                                        table.insert(self.objectiveMovingPins, objectivePin)
                                        if auraPin then
                                            table.insert(self.objectiveMovingPins, auraPin)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function ZO_WorldMapPins_Manager:RefreshGroupPins()
    self:RemovePins("group")

    if ZO_WorldMap_IsPinGroupShown(MAP_FILTER_GROUP_MEMBERS) then
        local isInDungeon = GetMapContentType() == MAP_CONTENT_DUNGEON
        local isInHouse = GetCurrentZoneHouseId() ~= 0
        for i = 1, MAX_GROUP_SIZE_THRESHOLD do
            local groupTag = ZO_Group_GetUnitTagForGroupIndex(i)
            local isBreadcrumbed = IsUnitWorldMapPositionBreadcrumbed(groupTag)
            if DoesUnitExist(groupTag) and not AreUnitsEqual("player", groupTag) and IsUnitOnline(groupTag) then
                local isGroupMemberHiddenByInstance = false
                -- If we're in an instance and it has its own map, it's going to be a dungeon map or house. Don't show on the map if we're on different instances/layers
                -- If it doesn't have its own map, we're okay to show the group member regardless of instance
                if DoesCurrentMapMatchMapForPlayerLocation() and IsGroupMemberInSameWorldAsPlayer(groupTag) and (isInDungeon or isInHouse) then
                    if not IsGroupMemberInSameInstanceAsPlayer(groupTag) then
                        -- We're in the same world as the group member, but a different instance
                        isGroupMemberHiddenByInstance = true
                    elseif not IsGroupMemberInSameLayerAsPlayer(groupTag) then
                        -- We're in the same instance as the group member, but a different layer
                        isGroupMemberHiddenByInstance = not isBreadcrumbed 
                    end
                end

                if not isGroupMemberHiddenByInstance then
                    local x, y, _, isInCurrentMap, isSymbolicLocation = GetMapPlayerPosition(groupTag)
                    if isInCurrentMap then
                        local isLeader = IsUnitGroupLeader(groupTag)
                        local tagData = groupTag
                        if isBreadcrumbed then
                            tagData =
                            {
                                groupTag = groupTag,
                                isBreadcrumb = true
                            }
                        end

                        local NO_RADIUS = nil
                        local NO_BORDER_INFO = nil
                        self:CreatePin(isLeader and MAP_PIN_TYPE_GROUP_LEADER or MAP_PIN_TYPE_GROUP, tagData, x, y, NO_RADIUS, NO_BORDER_INFO, isSymbolicLocation)
                    end
                end
            end
        end
    end
end

function ZO_WorldMapPins_Manager:UpdateMovingPins()
    do
        local playerPin = self:GetPlayerPin()
        local xLoc, yLoc, _, isShownInCurrentMap, isSymbolicLocation = GetMapPlayerPosition("player")
        playerPin:SetOriginalPosition(xLoc, yLoc)
        playerPin:SetIsSymbolicPosition(isSymbolicLocation)
        playerPin:SetLocation(xLoc, yLoc)
        if isShownInCurrentMap then
            playerPin:SetHidden(false)
            local rotation = isSymbolicLocation and 0 or GetPlayerCameraHeading()
            playerPin:SetRotation(rotation)
        else
            playerPin:SetHidden(true)
        end
    end

    local movingPins = self.movingPins
    self:AddPinsToArray(movingPins, "group")
    for _, groupPin in ipairs(movingPins) do
        local xLoc, yLoc = GetMapPlayerPosition(groupPin:GetUnitTag())
        groupPin:SetLocation(xLoc, yLoc)
    end
    ZO_ClearNumericallyIndexedTable(movingPins)

    local companionPin = self:FindPin("companion")
    if companionPin then
        local xLoc, yLoc = GetMapPlayerPosition(companionPin:GetUnitTag())
        companionPin:SetLocation(xLoc, yLoc)
    end

    for _, objectivePin in ipairs(self.objectiveMovingPins) do
        local _, currentX, currentY = GetObjectivePinInfo(objectivePin:GetObjectiveKeepId(), objectivePin:GetObjectiveObjectiveId(), objectivePin:GetBattlegroundContext())
        objectivePin:SetLocation(currentX, currentY)
    end

    self:AddPinsToArray(movingPins, "worldEventUnit")
    for _, worldEventPin in ipairs(movingPins) do
        local xLoc, yLoc = GetMapPlayerPosition(worldEventPin:GetUnitTag())
        worldEventPin:SetLocation(xLoc, yLoc)
    end
    ZO_ClearNumericallyIndexedTable(movingPins)

    self:UpdateSymbolicPins()
end

--[[
    Utilities to build lists of pins the mouse is currently over and was previously over so the world map knows how
    to properly call the OnMouseExit and OnMouseEnter events on the pins.
--]]

function ZO_WorldMapPins_Manager:BuildMouseOverPinLists(cursorPositionX, cursorPositionY)
    -- Determine if the mouse is even over the world map
    local isMouseOverWorldMap = ZO_WorldMap_IsMouseOverMap()

    -- Swap lists
    self.previousMouseOverPins, self.currentMouseOverPins = self.currentMouseOverPins, self.previousMouseOverPins
    local currentMouseOverPins = self.currentMouseOverPins

    -- Update any pins that were moused over in the current list that may no longer be in the active pins
    for pin, isMousedOver in pairs(currentMouseOverPins) do
        if isMousedOver then
            currentMouseOverPins[pin] = isMouseOverWorldMap and pin:MouseIsOver(cursorPositionX, cursorPositionY)
        end
    end

    local stickyPin = ZO_WorldMap_GetStickyPin()
    -- Update active list and determine the sticky pin!
    stickyPin:ClearNearestCandidate()

    local pins = self:GetActiveObjects()
    for _, pin in pairs(pins) do
        currentMouseOverPins[pin] = isMouseOverWorldMap and pin:MouseIsOver(cursorPositionX, cursorPositionY)
        stickyPin:ConsiderPin(pin, cursorPositionX, cursorPositionY)
    end

    stickyPin:SetStickyPinFromNearestCandidate()

    -- Determine which pins need to have their mouse enter called and which need to have their mouse exit called.
    -- Return whether or not the lists for current and previous changed so that nothing is updated unecessarily
    local wasPreviouslyMousedOver, doMouseEnter, doMouseExit
    local listsChanged = false
    local needsContinuousTooltipUpdates = false

    for pin, isMousedOver in pairs(currentMouseOverPins) do
        wasPreviouslyMousedOver = self.previousMouseOverPins[pin]
        doMouseEnter = isMousedOver and not wasPreviouslyMousedOver
        doMouseExit = not isMousedOver and wasPreviouslyMousedOver

        self.mouseExitPins[pin] = doMouseExit

        listsChanged = listsChanged or doMouseEnter or doMouseExit
        needsContinuousTooltipUpdates = needsContinuousTooltipUpdates or (isMousedOver and pin:NeedsContinuousTooltipUpdates())
    end

    return listsChanged, needsContinuousTooltipUpdates
end

function ZO_WorldMapPins_Manager:DoMouseExitForPin(pin)
    if pin:IsPOI() or pin:IsFastTravelWayShrine() then
        --reset the status to show what part of the map we're over (except if it's the name of this zone)
        local currentLocation = WORLD_MAP_MANAGER.mouseoverCurrentLocation
        if currentLocation ~= ZO_WorldMap.zoneName then
            ZO_WorldMapMouseoverName:SetText(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, currentLocation))
            ZO_WorldMapMouseoverName.owner = "map"
        else
            ZO_WorldMapMouseoverName:SetText("")
            ZO_WorldMapMouseoverName.owner = ""
        end

        ZO_WorldMapMouseOverDescription:SetText("")
    end

    local pinType = pin:GetPinType()
    WORLD_MAP_MANAGER:DoMouseExitForPinType(pinType)
end

function ZO_WorldMapPins_Manager:ResetMouseOverPins()
    for pin, mousedOver in pairs(self.currentMouseOverPins) do
        if mousedOver then
            pin:SetTargetScale(1)
        end
    end
    ZO_ClearTable(self.currentMouseOverPins)
    ZO_ClearTable(self.previousMouseOverPins)
end

function ZO_WorldMapPins_Manager:OnMouseOverPinReset(pin)
    if self.currentMouseOverPins[pin] then
        self.mousedOverPinWasReset = true
        self:DoMouseExitForPin(pin)
    end
    self.currentMouseOverPins[pin] = nil
    self.previousMouseOverPins[pin] = nil

    --If we are showing a menu to choose a pin action and one of those pins is removed from the map then we need to handle that here
    WORLD_MAP_CHOICE_DIALOG_GAMEPAD:OnPinRemovedFromMap(pin)
    if ZO_MapPin.pinsInKeyboardMapChoiceDialog and ZO_MapPin.pinsInKeyboardMapChoiceDialog[pin] then
        ClearMenu()
    end
end

function ZO_WorldMapPins_Manager:GetFoundTooltipMouseOverPins()
    return self.foundTooltipMouseOverPins
end

do
    local function TooltipPinSortFunction(firstPin, secondPin)
        local firstPinType = firstPin:GetPinType()
        local secondPinType = secondPin:GetPinType()

        local firstTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[firstPinType]
        local secondTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[secondPinType]

        -- If either tooltip info is nil, that pin has no tooltip, and we just need
        --  to make sure it sorts to a consistant place.
        if not firstTooltipInfo then
            return false
        elseif not secondTooltipInfo then
            return true
        end

        local firstCategoryId = GetValueOrExecute(firstTooltipInfo.categoryId, firstPin)
        local secondCategoryId = GetValueOrExecute(secondTooltipInfo.categoryId, secondPin)

        local compareResult = DefaultCompareNilable(firstCategoryId, secondCategoryId)
        if compareResult ~= nil then
            return compareResult
        end

        local firstEntryName = GetValueOrExecute(firstTooltipInfo.entryName, firstPin)
        local secondEntryName = GetValueOrExecute(secondTooltipInfo.entryName, secondPin)
        compareResult = DefaultCompareNilable(firstEntryName, secondEntryName)
        if compareResult ~= nil then
            return compareResult
        end

        return false
    end

    local function GamepadTooltipPinSortFunction(firstPin, secondPin)
        local firstPinType = firstPin:GetPinType()
        local secondPinType = secondPin:GetPinType()

        local firstTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[firstPinType]
        local secondTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[secondPinType]

        -- If either tooltip info is nil, that pin has no tooltip, and we just need
        --  to make sure it sorts to a consistant place.
        if not firstTooltipInfo then
            return false
        elseif not secondTooltipInfo then
            return true
        end

        local firstCategoryId = GetValueOrExecute(firstTooltipInfo.categoryId, firstPin) or GetValueOrExecute(firstTooltipInfo.gamepadCategory, firstPin)
        local secondCategoryId = GetValueOrExecute(secondTooltipInfo.categoryId, secondPin) or GetValueOrExecute(secondTooltipInfo.gamepadCategory, secondPin)

        local compareResult = DefaultCompareNilable(firstCategoryId, secondCategoryId)
        if compareResult ~= nil then
            return compareResult
        end

        local firstCategory = GetValueOrExecute(firstTooltipInfo.gamepadCategory, firstPin)
        local secondCategory = GetValueOrExecute(secondTooltipInfo.gamepadCategory, secondPin)
        compareResult = DefaultCompareNilable(firstCategory, secondCategory)
        if compareResult ~= nil then
            return compareResult
        end

        local firstEntryName = GetValueOrExecute(firstTooltipInfo.entryName, firstPin)
        local secondEntryName = GetValueOrExecute(secondTooltipInfo.entryName, secondPin)
        compareResult = DefaultCompareNilable(firstEntryName, secondEntryName)
        if compareResult ~= nil then
            return compareResult
        end

        return false
    end

    function ZO_WorldMapPins_Manager:UpdateMouseOverPins(usedTooltips)
        local isCurrentSceneGamepad = SCENE_MANAGER:IsCurrentSceneGamepad()
        local isInGamepadPreferredMode = IsInGamepadPreferredMode()
        local cursorPositionX
        local cursorPositionY
        if isCurrentSceneGamepad then
            cursorPositionX, cursorPositionY = ZO_WorldMapScroll:GetCenter()
        else
            cursorPositionX, cursorPositionY = GetUIMousePosition()
        end

        local mouseOverListChanged, needsContinuousTooltipUpdates = self:BuildMouseOverPinLists(cursorPositionX, cursorPositionY)
        local needsTooltipUpdate = mouseOverListChanged or self.mousedOverPinWasReset or needsContinuousTooltipUpdates or self.invalidateTooltip
        local needsTooltipScrollReset = mouseOverListChanged or self.mousedOverPinWasReset
        self.invalidateTooltip = false
        self.mousedOverPinWasReset = false

        if not needsTooltipUpdate then
            return false
        end

        ZO_WorldMap_HideAllTooltipsLater()

        -- Iterate over the current pins, using the key as the actual pin to facilitate looking up whether or not it's appropriate to call mouseEnter/mouseExit
        -- for the pins.
        local foundTooltipMouseOverPins = self.foundTooltipMouseOverPins
        ZO_ClearNumericallyIndexedTable(foundTooltipMouseOverPins)
        for pin, isMousedOver in pairs(self.currentMouseOverPins) do
            if pin then
                -- Do the exit pins first (so that ZO_WorldMapMouseoverName gets cleared then set in the correct order)
                if self.mouseExitPins[pin] then
                    self:DoMouseExitForPin(pin)
                end
            
                -- Verify that control is still moused over due to OnUpdate/OnShow handler issues (prevents tooltip popping)
                if isMousedOver and pin:MouseIsOver(cursorPositionX, cursorPositionY) then
                    table.insert(foundTooltipMouseOverPins, pin)
                else
                    pin:SetTargetScale(1)
                end
            end
        end

        if isInGamepadPreferredMode then
            table.sort(foundTooltipMouseOverPins, GamepadTooltipPinSortFunction)
        else
            table.sort(foundTooltipMouseOverPins, TooltipPinSortFunction)

            if #foundTooltipMouseOverPins > 0 then
                WORLD_MAP_MANAGER:HidePinPointerBox()
            end
        end

        local MAX_QUEST_PINS = 10
        local currentQuestPins = 0
        local missedQuestPins = 0
        local maxKeepTooltipPinLevel = 0
        local informationTooltipAppendedTo = false
        local lastGamepadCategory = nil
        local informationTooltip = isInGamepadPreferredMode and ZO_MapLocationTooltip_Gamepad or InformationTooltip
        local tooltipOrder = ZO_WORLD_MAP_TOOLTIP_ORDER

        for index, pin in ipairs(foundTooltipMouseOverPins) do
            local pinType = pin:GetPinType()
            local pinTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[pinType]

            if pinTooltipInfo then
                local layoutPinTooltip = true
                --always allow assisted pins through
                if pin:IsQuest() and not pin:IsAssisted() then
                    if currentQuestPins < MAX_QUEST_PINS then
                        currentQuestPins = currentQuestPins + 1
                    else
                        layoutPinTooltip = false
                        missedQuestPins = missedQuestPins + 1
                    end
                end

                if layoutPinTooltip then
                    if not pin:IsAreaPin() or pin:ShowsPinAndArea() then
                        pin:SetTargetScale(1.3)
                    end

                    local layoutTooltip = true
                    local usedTooltip = pinTooltipInfo.tooltip
                    if not isCurrentSceneGamepad and usedTooltip == ZO_MAP_TOOLTIP_MODE.KEEP then
                        local pinLevel = pin:GetLevel()
                        if pinLevel > maxKeepTooltipPinLevel then
                            maxKeepTooltipPinLevel = pinLevel
                        else
                            layoutTooltip = false
                        end
                    end

                    if layoutTooltip and pinTooltipInfo.hasTooltip then
                        layoutTooltip = pinTooltipInfo.hasTooltip(pin)
                    end

                    if layoutTooltip then
                        if usedTooltip then
                            if not isCurrentSceneGamepad then
                                for i = 1, #tooltipOrder do
                                    if tooltipOrder[i] == usedTooltip then
                                        if not usedTooltips[i] then
                                            usedTooltips[i] = true
                                            if usedTooltip == ZO_MAP_TOOLTIP_MODE.KEEP then
                                                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.KEEP):SetHidden(false)
                                            else
                                                InitializeTooltip(ZO_WorldMap_GetTooltipForMode(usedTooltip), pin:GetControl())
                                            end
                                        end
                                    end
                                end
                            else
                                if not ZO_WorldMap_IsWorldMapInfoShowing() and not ZO_WorldMap_IsKeepInfoShowing() then
                                    -- We'll fire the callback later
                                    local SUPPRESS_CALLBACK = true
                                    ZO_WorldMap_ShowGamepadTooltip(needsTooltipScrollReset, SUPPRESS_CALLBACK)
                                end
                            end
                        end

                        if isCurrentSceneGamepad then
                            local nextCategoryText = GetValueOrExecute(pinTooltipInfo.gamepadCategory, pin)
                            if type(nextCategoryText) == "number" then
                                nextCategoryText = GetString(nextCategoryText)
                            end

                            local nextCategory = nextCategoryText
                            if not nextCategory then
                                nextCategory = pinTooltipInfo.categoryId
                            end

                            local isDifferentCategory = (lastGamepadCategory ~= nextCategory)

                            if nextCategoryText and isDifferentCategory then
                                local categoryIcon = GetValueOrExecute(pinTooltipInfo.gamepadCategoryIcon, pin)
                                local titleStyleName = pinTooltipInfo.gamepadCategoryStyleName
                                titleStyleName = titleStyleName and informationTooltip.tooltip:GetStyle(titleStyleName)

                                local groupSection = informationTooltip.tooltip:AcquireSection(titleStyleName, informationTooltip.tooltip:GetStyle("mapKeepCategorySpacing"))
                                local mapIconTitleStyle = categoryIcon and informationTooltip.tooltip:GetStyle("mapIconTitle") or nil
                                informationTooltip:LayoutGroupHeader(groupSection, categoryIcon, nextCategoryText, titleStyleName, mapIconTitleStyle, informationTooltip.tooltip:GetStyle("mapTitle"))
                                informationTooltip.tooltip:AddSection(groupSection)
                            elseif pinTooltipInfo.gamepadSpacing or isDifferentCategory then
                                local groupSection = informationTooltip.tooltip:AcquireSection(informationTooltip.tooltip:GetStyle("mapKeepCategorySpacing"))
                                informationTooltip.tooltip:AddSectionEvenIfEmpty(groupSection)
                            end

                            lastGamepadCategory = nextCategory
                        end

                        pinTooltipInfo.creator(pin)

                        WORLD_MAP_MANAGER:DoMouseEnterForPinType(pinType)

                        --space out the appended lines in the information tooltip
                        if usedTooltip == ZO_MAP_TOOLTIP_MODE.INFORMATION and not isCurrentSceneGamepad then
                            informationTooltipAppendedTo = true
                            informationTooltip:AddVerticalPadding(5)
                        end
                    end
                end
            end
        
            -- For POIs, add name to the top of the map
            if pinType == MAP_PIN_TYPE_POI_COMPLETE or pinType == MAP_PIN_TYPE_POI_SEEN then
                local poiIndex = pin:GetPOIIndex()
                local zoneIndex = pin:GetPOIZoneIndex()

                local poiName, _, poiStartDesc, poiFinishedDesc = GetPOIInfo(zoneIndex, poiIndex)

                ZO_WorldMapMouseoverName.owner = "poi"
                ZO_WorldMapMouseoverName:SetText(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, poiName))

                if pinType == MAP_PIN_TYPE_POI_COMPLETE then
                    ZO_WorldMapMouseOverDescription:SetText(poiFinishedDesc)
                else
                    ZO_WorldMapMouseOverDescription:SetText(poiStartDesc)
                end
            end
        end

        if missedQuestPins > 0 then
            local text = string.format(zo_strformat(SI_TOOLTIP_MAP_MORE_QUESTS, missedQuestPins))
            if isInGamepadPreferredMode then
                local lineSection = informationTooltip.tooltip:AcquireSection(informationTooltip.tooltip:GetStyle("mapMoreQuestsContentSection"))
                lineSection:AddLine(text, informationTooltip.tooltip:GetStyle("mapLocationTooltipContentLabel"), informationTooltip.tooltip:GetStyle("gamepadElderScrollTooltipContent"))
                informationTooltip.tooltip:AddSection(lineSection)
            else
                informationTooltip:AddLine(text)
            end
        end

        --Remove the last bit of extra padding on the end
        if informationTooltipAppendedTo and not isCurrentSceneGamepad then
            informationTooltip:AddVerticalPadding(-5)
        end

        return true
    end
end

function ZO_WorldMapPins_Manager:InvalidateTooltip()
    self.invalidateTooltip = true
end

--[[
    Pin Click Handlers
--]]

do
    local function GetShownHandlersForPin(pin, mouseButton)
        if pin and ZO_MapPin.PIN_CLICK_HANDLERS[mouseButton] then
            local handlers = ZO_MapPin.PIN_CLICK_HANDLERS[mouseButton][pin:GetPinType()]
            if handlers then
                for i = 1, #handlers do
                    local handler = handlers[i]
                    if handler.show == nil or handler.show(pin) then
                        if handler.GetDynamicHandlers then
                            return handler.GetDynamicHandlers(pin)
                        else
                            return { handler }
                        end
                    end
                end
            end
        end

        return nil
    end

    local function GetFirstShownHandlerForPin(pin, mouseButton)
        local handlers = GetShownHandlersForPin(pin, mouseButton)
        if handlers then
            return handlers[1]
        end

        return nil
    end

    function ZO_WorldMapPins_Manager:WouldPinHandleClick(pinControl, button, ctrl, alt, shift)
        if ctrl or alt then
            return false
        end

        if pinControl then
            local pin = ZO_MapPin.GetMapPinForControl(pinControl)
            local validPinHandler = GetFirstShownHandlerForPin(pin, button)
            if validPinHandler then
                return true
            end
        end

        for pin, isMousedOver in pairs(self.currentMouseOverPins) do
            if isMousedOver then
                local validHandler = GetFirstShownHandlerForPin(pin, button)
                if validHandler then
                    return true
                end
            end
        end
    end

    function ZO_WorldMapPins_Manager:GetPinHandlers(mouseButton)
        local pinDatas = ZO_MapPin.pinDatas
        ZO_ClearNumericallyIndexedTable(pinDatas)

        for pin, isMousedOver in pairs(self.currentMouseOverPins) do
            if isMousedOver then
                local shownHandlers = GetShownHandlersForPin(pin, mouseButton)
                if shownHandlers then
                    for _, handler in ipairs(shownHandlers) do
                        local duplicate = false
                        local duplicatesFunction = handler.duplicates
                        if duplicatesFunction then
                            for _, pinData in ipairs(pinDatas) do
                                --if these handlers are of the same type
                                if handler == pinData.handler then
                                    if duplicatesFunction(pin, pinData.pin) then
                                        duplicate = true
                                        break
                                    end
                                end
                            end
                        end

                        if not duplicate then
                            table.insert(pinDatas, {handler = handler, pin = pin})
                        end
                    end
                end
            end
        end

        return pinDatas
    end
end

function ZO_WorldMapPins_Manager.ChoosePinOption(pin, handler)
    if handler.show and not handler.show(pin) then
        --If something changed and we shouldn't be showing this option anymore then...
        if handler.failedAfterBeingShownError then
            --If we have some error text for this case then show it in a dialog
            local text
            if type(handler.failedAfterBeingShownError) == "function" then
                text = handler.failedAfterBeingShownError(pin)
            else
                text = handler.failedAfterBeingShownError
            end
            ZO_Dialogs_ShowPlatformDialog("WORLD_MAP_CHOICE_FAILED", nil, { mainTextParams = { text } })
        end
        --Then skip doing the action
        return
    end
    handler.callback(pin)
end

do
    local function SortPinDatas(firstData, secondData)
        local firstEntryName = GetValueOrExecute(firstData.handler.name, firstData.pin)
        local secondEntryName = GetValueOrExecute(secondData.handler.name, secondData.pin)
        local compareResult = DefaultCompareNilable(firstEntryName, secondEntryName)
        if compareResult ~= nil then
            return compareResult
        end

        return false
    end

    local function OnMenuHiddenCallback()
        ZO_MapPin.pinsInKeyboardMapChoiceDialog = nil
    end

    function ZO_WorldMapPins_Manager:HandlePinClicked(pinControl, mouseButton, ctrl, alt, shift)
        if ctrl or alt then
            return
        end

        local pinDatas = self:GetPinHandlers(mouseButton)

        self:RemoveInvalidSpawnLocations(pinDatas)

        if #pinDatas == 1 then
            pinDatas[1].handler.callback(pinDatas[1].pin)
        elseif #pinDatas > 1 then
            if IsInGamepadPreferredMode() then
                ZO_Dialogs_ShowGamepadDialog("WORLD_MAP_CHOICE_GAMEPAD", { mouseOverPinHandlers = pinDatas })
            else
                ClearMenu()
                ZO_MapPin.pinsInKeyboardMapChoiceDialog = { }

                table.sort(pinDatas, SortPinDatas)

                for _, pinData in ipairs(pinDatas) do
                    local handler = pinData.handler
                    local pin = pinData.pin
                    local name = handler.name
                    if type(name) == "function" then
                        name = name(pin)
                    end
                    AddMenuItem(name, function()
                        self.ChoosePinOption(pin, handler)
                    end)
                    ZO_MapPin.pinsInKeyboardMapChoiceDialog[pin] = true
                end
                SetMenuHiddenCallback(OnMenuHiddenCallback)
                ShowMenu(pinControl)
            end
        end
    end
end

function ZO_WorldMapPins_Manager:RemoveInvalidSpawnLocations(pinDatas)
    for i, pinData in ZO_NumericallyIndexedTableReverseIterator(pinDatas) do
        if ZO_MapPin.IsReviveLocation(pinData.handler) and not ZO_MapPin.CanReviveAtPin(pinData.pin, pinData.handler) then
            table.remove(pinDatas, i)
        end
    end
end

-----------------------
-- Locations Manager --
-----------------------

-- Set up the place names text that appears on the map...
ZO_MapLocationPins_Manager = ZO_ControlPool:Subclass()

function ZO_MapLocationPins_Manager:Initialize(container)
    ZO_ControlPool.Initialize(self, "ZO_MapLocation", container, "Landmark")

    self.m_minFontSize = 17
    self.m_maxFontSize = 32
    self.m_cachedFontStrings = {}

    self:SetFontScale(1)
end

function ZO_MapLocationPins_Manager:SetFontScale(scale)
    if scale ~= self.m_fontScale then
        self.m_fontScale = scale
        self.m_cachedFontStrings = {}
    end
end

function ZO_MapLocationPins_Manager:GetFontString(size)
    -- apply scale to the (unscaled) input size, clamp it, and arive at final font string.
    -- unscale by global ui scale because we want the font to get a little bigger at smaller ui scales to approximately cover the same map area...
    local fontString = self.m_cachedFontStrings[size]
    if not fontString then
        fontString = string.format("$(BOLD_FONT)|%d|soft-shadow-thin", zo_round(size / GetUIGlobalScale()))
        self.m_cachedFontStrings[size] = fontString
    end

    return fontString
end

function ZO_MapLocationPins_Manager:AddLocation(locationIndex)
    if IsMapLocationVisible(locationIndex) then
        local icon, x, y = GetMapLocationIcon(locationIndex)

        if icon ~= "" and ZO_WorldMap_IsNormalizedPointInsideMapBounds(x, y) then
            local tag = ZO_MapPin.CreateLocationPinTag(locationIndex, icon)
            ZO_WorldMap_GetPinManager():CreatePin(MAP_PIN_TYPE_LOCATION, tag, x, y)
        end
    end
end

function ZO_MapLocationPins_Manager:RefreshLocations()
    self:ReleaseAllObjects()
    ZO_WorldMap_GetPinManager():RemovePins("loc")

    for i = 1, GetNumMapLocations() do
        self:AddLocation(i)
    end
end

----------------
-- Sticky Pin --
----------------

--[[
    Sticky Pin Utilities for gamepad map control (utilized by mouse over list construction)
--]]

local BASE_STICKY_DISTANCE_UNITS =
{
    MIN = 50,
    MAX = 75,
}

ZO_WorldMapStickyPin = ZO_InitializingObject:Subclass()

function ZO_WorldMapStickyPin:Initialize()
    self.thresholdDistanceSq = BASE_STICKY_DISTANCE_UNITS.MIN * BASE_STICKY_DISTANCE_UNITS.MIN
    self.enabled = true
end

function ZO_WorldMapStickyPin:SetEnabled(enabled)
    self.enabled = enabled
end

function ZO_WorldMapStickyPin:UpdateThresholdDistance(currentNormalizedZoom)
    local stickyDistance = zo_lerp(BASE_STICKY_DISTANCE_UNITS.MIN, BASE_STICKY_DISTANCE_UNITS.MAX, currentNormalizedZoom)
    self.thresholdDistanceSq = stickyDistance * stickyDistance
end

function ZO_WorldMapStickyPin:SetStickyPin(pin)
    self.pin = pin
end

function ZO_WorldMapStickyPin:GetStickyPin()
    return self.pin
end

function ZO_WorldMapStickyPin:ClearStickyPin(mover)
    if self.movingToPin and self:GetStickyPin() then
        mover:ClearTargetOffset()
    end

    self:SetStickyPin(nil)
end

function ZO_WorldMapStickyPin:MoveToStickyPin(mover)
    local movingToPin = self:GetStickyPin()
    if movingToPin then
        self.movingToPin = movingToPin
        local useCurrentZoom = true
        mover:PanToPin(movingToPin, useCurrentZoom)
    end
end

function ZO_WorldMapStickyPin:SetStickyPinFromNearestCandidate()
    self:SetStickyPin(self.nearestCandidate)
end

function ZO_WorldMapStickyPin:ClearNearestCandidate()
    self.nearestCandidate = nil
    self.nearestCandidateDistanceSq = 0
end

function ZO_WorldMapStickyPin:ConsiderPin(pin, x, y)
    if self.enabled then
        local pinGroup = pin:GetPinGroup()
        if pinGroup == nil or WORLD_MAP_MANAGER:AreStickyPinsEnabledForPinGroup(pinGroup) then
            local distanceSq = pin:DistanceToSq(x, y)
            if distanceSq < self.thresholdDistanceSq then
                if not self.nearestCandidate or distanceSq < self.nearestCandidateDistanceSq then
                    self.nearestCandidate = pin
                    self.nearestCandidateDistanceSq = distanceSq
                end
            end
        end
    end
end