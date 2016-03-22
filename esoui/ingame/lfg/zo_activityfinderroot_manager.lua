local GROUP_TYPE_TO_MAX_SIZE =
{
    [LFG_GROUP_TYPE_REGULAR] = SMALL_GROUP_SIZE_THRESHOLD,
    [LFG_GROUP_TYPE_MEDIUM] = RAID_GROUP_SIZE_THRESHOLD,
    [LFG_GROUP_TYPE_LARGE] = GROUP_SIZE_MAX,
}

local function LFGLevelSort(entry1, entry2)
    if entry1.veteranRankMin ~= entry2.veteranRankMin then
        return entry1.veteranRankMin < entry2.veteranRankMin
    elseif entry1.levelMin ~= entry2.levelMin then
        return entry1.levelMin < entry2.levelMin
    elseif entry1.veteranRankMax ~= entry2.veteranRankMax then
        return entry1.veteranRankMax < entry2.veteranRankMax
    elseif entry1.levelMax ~= entry2.levelMax then
        return entry1.levelMax < entry2.levelMax
    else
        return entry1.rawName < entry2.rawName
    end
end

local function GetLFGEntryStringKeyboard(rawName, activityType)
    if activityType == LFG_ACTIVITY_MASTER_DUNGEON then
        return zo_iconTextFormat(GetVeteranRankIcon(), "100%", "100%", rawName)
    else
        return zo_strformat(SI_LFG_ACTIVITY_NAME, rawName)
    end
end

local function GetLFGEntryStringGamepad(rawName, activityType)
    if activityType == LFG_ACTIVITY_MASTER_DUNGEON then
        return zo_strformat(GetString(SI_GAMEPAD_ACTIVITY_FINDER_VETERAN_LOCATION_FORMAT), rawName)
    else
        return zo_strformat(SI_LFG_ACTIVITY_NAME, rawName)
    end
end

local function GetLevelRankRequirementText(levelMin, levelMax, rankMin, rankMax)
    local playerRank = GetUnitVeteranRank("player")
    
    if playerRank > 0 or levelMin == GetMaxLevel() then
        if playerRank < rankMin then
            return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_RANK_REQUIREMENT, rankMin)
        elseif playerRank > rankMax then
            return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MAX_RANK_REQUIREMENT, rankMax)
        end
    else
        local playerLevel = GetUnitLevel("player")
    
        if playerLevel < levelMin then
            return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_LEVEL_REQUIREMENT, levelMin)
        elseif playerLevel > levelMax then
            return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MAX_LEVEL_REQUIREMENT, levelMax)
        end
    end
end

local function IsPreferredRoleSelected()
    local isDPS, isHeal, isTank = GetPlayerRoles()
    return isDPS or isHeal or isTank
end

local function CreateLocationData(activityType, lfgIndex)
    local name, levelMin, levelMax, veteranRankMin, veteranRankMax, groupType, minNumMembers, description = GetLFGOption(activityType, lfgIndex)
    local descriptionTextureSmallKeyboard, descriptionTextureLargeKeyboard = GetLFGOptionKeyboardDescriptionTextures(activityType, lfgIndex)
    local descriptionTextureGamepad = GetLFGOptionGamepadDescriptionTexture(activityType, lfgIndex)
    local requiredCollectible = GetRequiredLFGCollectibleId(activityType, lfgIndex)

    return
    {
        activityType = activityType,
        lfgIndex = lfgIndex,
        nameKeyboard = GetLFGEntryStringKeyboard(name, activityType),
        nameGamepad = GetLFGEntryStringGamepad(name, activityType),
        rawName = name,
        description = description,
        descriptionTextureSmallKeyboard = descriptionTextureSmallKeyboard,
        descriptionTextureLargeKeyboard = descriptionTextureLargeKeyboard,
        descriptionTextureGamepad = descriptionTextureGamepad,
        levelMin = levelMin,
        levelMax = levelMax,
        veteranRankMin = veteranRankMin,
        veteranRankMax = veteranRankMax,
        groupType = groupType,
        minGroupSize = minNumMembers,
        maxGroupSize = GetGroupSizeFromLFGGroupType(groupType),
        requiredCollectible = requiredCollectible,
    }
end

------------------
--Initialization--
------------------

ActivityFinderRoot_Manager = ZO_CallbackObject:Subclass()

function ActivityFinderRoot_Manager:New(...)
    local singleton = ZO_CallbackObject.New(self)
    singleton:Initialize(...)
    return singleton
end

function ActivityFinderRoot_Manager:Initialize()
    self.groupSize = 0
    self:InitializeLocationData()
    self:RegisterForEvents()
end

function ActivityFinderRoot_Manager:RegisterForEvents()
    local function ClearSelections()
        self:ClearSelections()
    end

    local function ClearAndUpdate()
        self:ClearAndUpdate()
    end

    function UpdateGroupStatus()
        self:UpdateGroupStatus()
    end

    function OnLevelUpdate(eventCode, unitTag)
        if unitTag == "player" or ZO_Group_IsGroupUnitTag(unitTag) then
            self:ClearAndUpdate()
            self:FireCallbacks("OnLevelUpdate")
        end
    end

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_ACTIVITY_FINDER_STATUS_UPDATE, function(eventCode, ...) self:OnActivityFinderStatusUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_ACTIVITY_FINDER_COOLDOWNS_UPDATE, function() self:FireCallbacks("OnCooldownsUpdate") end)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_CURRENT_CAMPAIGN_CHANGED, ClearAndUpdate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_COLLECTION_UPDATED, ClearAndUpdate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_COLLECTIBLE_UPDATED, ClearAndUpdate)

    --We should clear selections when switching filters, but we won't necessarily clear them when closing scenes
    --However, we can't ensure that gamepad and keyboard will stay on the same filter, so we'll clear selections when switching between modes
    --This won't require rechecking lock statuses
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, ClearSelections)

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_LEVEL_UPDATE, OnLevelUpdate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_VETERAN_RANK_UPDATE, OnLevelUpdate)
    
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_PLAYER_ACTIVATED, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GROUP_MEMBER_LEFT, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_UNIT_CREATED, function(eventCode, unitTag) 
        if ZO_Group_IsGroupUnitTag(unitTag) then
            self:UpdateGroupStatus()
        end
    end)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GROUP_UPDATE, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_LEADER_UPDATE, UpdateGroupStatus)
end

function ActivityFinderRoot_Manager:InitializeLocationData()
    local locationsLookupData = {}
    local sortedLocationsData = {}
    local randomActivityTypeGroupSizeRanges = {}

    for activityType = LFG_ACTIVITY_MIN_VALUE, LFG_ACTIVITY_MAX_VALUE do
        local numOptions = GetNumLFGOptions(activityType)
        if numOptions > 0 then
            local lookupActivityData = {}
            local sortedActivityData = {}
            local minGroupSize, maxGroupSize

            for lfgIndex = 1, numOptions do
                local data = CreateLocationData(activityType, lfgIndex)
                table.insert(lookupActivityData, data)
                table.insert(sortedActivityData, data)
                if not minGroupSize or minGroupSize > data.minGroupSize then
                    minGroupSize = data.minGroupSize
                end

                if not maxGroupSize or maxGroupSize < data.maxGroupSize then
                    maxGroupSize = data.maxGroupSize
                end
            end
        
            table.sort(sortedActivityData, LFGLevelSort)
            locationsLookupData[activityType] = lookupActivityData
            sortedLocationsData[activityType] = sortedActivityData
            randomActivityTypeGroupSizeRanges[activityType] = { min = minGroupSize, max = maxGroupSize }
        end
    end

    self.sortedLocationsData = sortedLocationsData
    self.locationsLookupData = locationsLookupData
    self.randomActivityTypeGroupSizeRanges = randomActivityTypeGroupSizeRanges
    self.numSelected = 0
    self.randomActivityTypeLockReasons = {}
    self.randomActivitySelections = {}
end

-----------
--Updates--
-----------

function ActivityFinderRoot_Manager:UpdateGroupStatus()
    local wasGrouped = self.playerIsGrouped
    local wasLeader = self.playerIsLeader
    self.playerIsGrouped = IsUnitGrouped("player")
    self.playerIsLeader = IsUnitGroupLeader("player")
    self.groupSize = GetGroupSize()
    local groupStateChanged = wasGrouped ~= self.playerIsGrouped or wasLeader ~= self.playerIsLeader
    if groupStateChanged then
        self:FireCallbacks("OnUpdateGroupStatus", wasGrouped, self.playerIsGrouped, wasLeader, self.playerIsLeader)
    end
    self:ClearAndUpdate()
end

function ActivityFinderRoot_Manager:GetGroupStatus()
    return self.playerIsGrouped, self.playerIsLeader, self.groupSize
end

function ActivityFinderRoot_Manager:UpdateLocationData()
    --Determine lock status for each location
    local inAGroup = IsUnitGrouped("player")
    local isLeader = IsUnitGroupLeader("player")
    local isRoleSelected = IsPreferredRoleSelected()
    ZO_ClearTable(self.randomActivityTypeLockReasons)

    for activityType, locationsByActivity in pairs(self.locationsLookupData) do
        if locationsByActivity then
            local activityIsAvA = activityType == LFG_ACTIVITY_AVA
            local anyEligible = false
            local anyLockReason = nil

            for index, location in ipairs(locationsByActivity) do
                location.isLocked = true

                if inAGroup and not isLeader then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_NOT_LEADER)
                elseif not isRoleSelected then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_NO_ROLES_SELECTED)
                elseif activityIsAvA and not IsInAvAZone() then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_NOT_IN_AVA)
                elseif not activityIsAvA and IsInAvAZone() then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_IN_AVA)
                else
                    location.playerMeetsLevelRequirements = DoesPlayerMeetLFGLevelRequirements(activityType, index)
                    location.groupMeetsLevelRequirements = DoesGroupMeetLFGLevelRequirements(activityType, index)
    
                    local groupTooLarge = self.groupSize > GROUP_TYPE_TO_MAX_SIZE[location.groupType]

                    if groupTooLarge then
                        location.lockReasonText = GetString(SI_LFG_LOCK_REASON_GROUP_TOO_LARGE)
                    elseif not location.playerMeetsLevelRequirements then
                        location.lockReasonText = GetLevelRankRequirementText(location.levelMin, location.levelMax, location.veteranRankMin, location.veteranRankMax)
                    elseif not location.groupMeetsLevelRequirements and inAGroup then
                        location.lockReasonText = GetString(SI_LFG_LOCK_REASON_GROUP_LOCATION_LEVEL_REQUIREMENTS)
                    elseif location.requiredCollectible ~= 0 and not IsCollectibleUnlocked(location.requiredCollectible) then
                        location.lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_DLC_NOT_UNLOCKED, GetCollectibleName(location.requiredCollectible))
                    else
                        location.isLocked = false
                        location.lockReasonText = ""
                        anyEligible = true
                    end
                end

                if location.lockReasonText ~= "" then
                    anyLockReason = location.lockReasonText
                end
            end

            if anyEligible then
                self.randomActivityTypeLockReasons[activityType] = nil
            else
                self.randomActivityTypeLockReasons[activityType] = anyLockReason
            end
        end
    end

    self:FireCallbacks("OnUpdateLocationData")
end

function ActivityFinderRoot_Manager:ClearSelections()
    for activityType, locationsByActivity in pairs(self.locationsLookupData) do
        self.randomActivitySelections[activityType] = false

        for index, location in ipairs(locationsByActivity) do
            location.isSelected = false
        end
    end
    
    self.numSelected = GetNumLFGRequests()

    for i = 1, self.numSelected do
        local activityType, index = GetLFGRequestInfo(i)
        local location = self.locationsLookupData[activityType][index]
        location.isSelected = true
    end
end

function ActivityFinderRoot_Manager:ClearAndUpdate()
    --A clear and update is required when the selections may change due to requirement changes. (Ex: a group member
    --joins that doesn't meet the level requirement of a location already selected. The location needs to be unselected
    --and locked, and then all other locations need to be refreshed again in case they are now unlocked. Instead of
    --nesting refreshes, just clear and update when an event occurs that can lead to this.)

    self:ClearSelections()
    self:UpdateLocationData()
end

function ActivityFinderRoot_Manager:OnActivityFinderStatusUpdate(status)
    self.activityFinderStatus = status
    self:FireCallbacks("OnActivityFinderStatusUpdate", status)
end

-------------
--Accessors--
-------------

function ActivityFinderRoot_Manager:GetLocationsData(activityType)
    if activityType then
        return self.sortedLocationsData[activityType]
    else
        return self.sortedLocationsData
    end
end

function ActivityFinderRoot_Manager:GetLocation(activityType, lfgIndex)
    local locationsByActivity = self.locationsLookupData[activityType]
    if locationsByActivity then
        local location = locationsByActivity[lfgIndex]
        if location then
            return location
        end
    end
    assert(false) --We should never be asking for a location using a bad activity or lfgIndex, fix the code that called this
end

function ActivityFinderRoot_Manager:GetIsCurrentlyInQueue()
    return self.activityFinderStatus == ACTIVITY_FINDER_STATUS_QUEUED
end

function ActivityFinderRoot_Manager:ToggleLocationSelected(location)
    self:SetLocationSelected(location, not location.isSelected)
end

function ActivityFinderRoot_Manager:SetLocationSelected(location, selected)
    if location.isLocked or IsCurrentlySearchingForGroup() or location.isSelected == selected then
        return
    end

    location.isSelected = selected
    local delta = location.isSelected and 1 or -1
    self.numSelected = self.numSelected + delta
    self:FireCallbacks("OnSelectionsChanged")
end

function ActivityFinderRoot_Manager:ToggleActivityTypeSelected(activityType)
    self:SetActivityTypeSelected(activityType, not self.randomActivitySelections[activityType])
end

function ActivityFinderRoot_Manager:SetActivityTypeSelected(activityType, selected)
    if not self:CanChooseRandomForActivityType(activityType) or IsCurrentlySearchingForGroup() or self.randomActivitySelections[activityType] == selected then
        return
    end

    self.randomActivitySelections[activityType] = selected
    local delta = selected and 1 or -1
    self.numSelected = self.numSelected + delta
    self:FireCallbacks("OnSelectionsChanged")
end

function ActivityFinderRoot_Manager:IsActivityTypeSelected(activityType)
    return self.randomActivitySelections[activityType]
end

function ActivityFinderRoot_Manager:IsAnyLocationSelected()
    return self.numSelected > 0
end

function ActivityFinderRoot_Manager:CanChooseRandomForActivityType(activityType)
    return self.randomActivityTypeLockReasons[activityType] == nil
end

function ActivityFinderRoot_Manager:GetLockReasonForActivityType(activityType)
    return self.randomActivityTypeLockReasons[activityType]
end

function ActivityFinderRoot_Manager:GetGroupSizeRangeForActivityType(activityType)
    local groupSizeRangeTable = self.randomActivityTypeGroupSizeRanges[activityType]
    return groupSizeRangeTable.min, groupSizeRangeTable.max
end

function ActivityFinderRoot_Manager:StartSearch()
    if IsCurrentlySearchingForGroup() then
        return
    end

    ClearGroupFinderSearch()

    if not IsPreferredRoleSelected() then
        ZO_AlertEvent(EVENT_ACTIVITY_QUEUE_RESULT, ACTIVITY_QUEUE_RESULT_NO_ROLES_SELECTED)
        return
    end

    --Add locations
    for activityType, locationsByActivity in pairs(self.locationsLookupData) do
        if self.randomActivitySelections[activityType] then
            AddGroupFinderSearchEntry(activityType)
        end

        for index, location in ipairs(locationsByActivity) do
            if location.isSelected then
                AddGroupFinderSearchEntry(activityType, index)
            end
        end
    end

    local result = StartGroupFinderSearch()
    if result ~= ACTIVITY_QUEUE_RESULT_SUCCESS then
        ZO_AlertEvent(EVENT_ACTIVITY_QUEUE_RESULT, result)
    end
end

function ActivityFinderRoot_Manager:HandleLFMPromptResponse(accept)
    --Any response should clear the prompt, but only acceptance sends the request
    if accept then
        SendLFMRequest()
    end
    self:FireCallbacks("OnHandleLFMPromptResponse")
end

 ZO_ACTIVITY_FINDER_ROOT_MANAGER = ActivityFinderRoot_Manager:New()