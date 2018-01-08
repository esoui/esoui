local function LFGSort(entry1, entry2)
    if entry1:GetEntryType() ~= entry2:GetEntryType() then
        return entry1:GetEntryType() < entry2:GetEntryType()
    elseif entry1:GetSortOrder() ~= entry2:GetSortOrder() then
        return entry1:GetSortOrder() > entry2:GetSortOrder()
    end

    local entry1LevelMin, entry1LevelMax = entry1:GetLevelRange()
    local entry1ChampionPointsMin, entry1ChampionPointsMax = entry1:GetChampionPointsRange()
    local entry2LevelMin, entry2LevelMax = entry1:GetLevelRange()
    local entry2ChampionPointsMin, entry2ChampionPointsMax = entry1:GetChampionPointsRange()

    if entry1ChampionPointsMin ~= entry2ChampionPointsMin then
        return entry1ChampionPointsMin < entry2ChampionPointsMin
    elseif entry1LevelMin ~= entry2LevelMin then
        return entry1LevelMin < entry2LevelMin
    elseif entry1ChampionPointsMax ~= entry2ChampionPointsMax then
        return entry1ChampionPointsMax < entry2ChampionPointsMax
    elseif entry1LevelMax ~= entry2LevelMax then
        return entry1LevelMax < entry2LevelMax
    else
        return entry1:GetRawName() < entry2:GetRawName()
    end
end

local function GetLFGEntryStringKeyboard(rawName, activityType)
    if activityType == LFG_ACTIVITY_MASTER_DUNGEON then
        return zo_iconTextFormat(GetVeteranIcon(), "100%", "100%", rawName)
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

local function GetLevelOrChampionPointsRequirementText(levelMin, levelMax, pointsMin, pointsMax)
    local playerChampionPoints = GetUnitChampionPoints("player")
    
    if playerChampionPoints > 0 or levelMin == GetMaxLevel() then
        if playerChampionPoints < pointsMin then
            return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_CHAMPION_REQUIREMENT, pointsMin)
        elseif playerChampionPoints > pointsMax then
            return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MAX_CHAMPION_REQUIREMENT, pointsMax)
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

function ZO_IsActivityTypeAvA(activityType)
    return activityType == LFG_ACTIVITY_AVA
end

function ZO_IsActivityTypeDungeon(activityType)
    return activityType == LFG_ACTIVITY_MASTER_DUNGEON or activityType == LFG_ACTIVITY_DUNGEON
end

function ZO_IsActivityTypeHomeShow(activityType)
    return activityType == LFG_ACTIVITY_HOME_SHOW
end

function ZO_IsActivityTypeBattleground(activityType)
    return activityType == LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL or activityType == LFG_ACTIVITY_BATTLE_GROUND_CHAMPION or activityType == LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION
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
    self.cooldowns = 
    {
        [LFG_COOLDOWN_ACTIVITY_STARTED] =
        {
            isOnCooldown = false,
            expiresAtS = 0,
            conciseFormatter = SI_LFG_LOCK_REASON_QUEUE_COOLDOWN_CONCISE,
            verboseFormatter = SI_LFG_LOCK_REASON_QUEUE_COOLDOWN_VERBOSE,
        },
        [LFG_COOLDOWN_BATTLEGROUND_DESERTED] =
        {
            isOnCooldown = false,
            expiresAtS = 0,
            conciseFormatter = SI_LFG_LOCK_REASON_LEFT_BATTLEGROUND_EARLY_CONCISE,
            verboseFormatter = SI_LFG_LOCK_REASON_LEFT_BATTLEGROUND_EARLY_VERBOSE,
        },
    }

    self:InitializeLocationData()
    self:RegisterForEvents()
end

function ActivityFinderRoot_Manager:RegisterForEvents()
    local function ClearSelections()
        self:ClearSelections()
    end

    local function MarkDataDirty()
        self:MarkDataDirty()
    end

    function UpdateGroupStatus()
        self:UpdateGroupStatus()
    end

    function OnLevelUpdate(eventCode, unitTag)
        if unitTag == "player" or ZO_Group_IsGroupUnitTag(unitTag) then
            self:MarkDataDirty()
            self:FireCallbacks("OnLevelUpdate")
        end
    end

    function OnCooldownsUpdate()
        local dirty = false
        for cooldownType, cooldownData in pairs(self.cooldowns) do
            local wasOnCooldown = cooldownData.isOnCooldown
            local timeRemaining = GetLFGCooldownTimeRemainingSeconds(cooldownType)
            cooldownData.isOnCooldown = timeRemaining > 0
            cooldownData.expiresAtS = timeRemaining + GetFrameTimeSeconds()
            if wasOnCooldown ~= cooldownData.isOnCooldown then
                dirty = true
            end
        end

        if dirty then
            self:MarkDataDirty()
        end
        self:FireCallbacks("OnCooldownsUpdate")
    end

    function OnPlayerActivate()
        UpdateGroupStatus()
        OnCooldownsUpdate()
    end

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_ACTIVITY_FINDER_STATUS_UPDATE, function(eventCode, ...) self:OnActivityFinderStatusUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_ACTIVITY_FINDER_COOLDOWNS_UPDATE, OnCooldownsUpdate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_CURRENT_CAMPAIGN_CHANGED, MarkDataDirty)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", MarkDataDirty)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", MarkDataDirty)

    --We should clear selections when switching filters, but we won't necessarily clear them when closing scenes
    --However, we can't ensure that gamepad and keyboard will stay on the same filter, so we'll clear selections when switching between modes
    --This won't require rechecking lock statuses
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, ClearSelections)

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_LEVEL_UPDATE, OnLevelUpdate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_CHAMPION_POINT_UPDATE, OnLevelUpdate)
    
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_PLAYER_ACTIVATED, OnPlayerActivate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GROUP_MEMBER_LEFT, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_UNIT_CREATED, function(eventCode, unitTag) 
        if ZO_Group_IsGroupUnitTag(unitTag) then
            self:UpdateGroupStatus()
        end
    end)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GROUP_UPDATE, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_LEADER_UPDATE, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForUpdate("ActivityFinderRoot_Manager", 0, function() self:OnUpdate() end)
end

function ActivityFinderRoot_Manager:InitializeLocationData()
    local specificLocationsLookupData = {}
    local locationSetsLookupData = {}
    local sortedLocationsData = {}
    local randomActivityTypeGroupSizeRanges = {}

    for activityType = LFG_ACTIVITY_ITERATION_BEGIN, LFG_ACTIVITY_ITERATION_END do
        local numActivities = GetNumActivitiesByType(activityType)
        local numActivitySets = GetNumActivitySetsByType(activityType)
        local specificLookupActivityData = {}
        local setLookupActivityData = {}
        local sortedActivityData = {}
        local minGroupSize, maxGroupSize

        --Specific activities
        if numActivities > 0 then
            for activityIndex = 1, numActivities do
                local data = ZO_ActivityFinderLocation_Specific:New(activityType, activityIndex)
                specificLookupActivityData[data:GetId()] = data
                table.insert(sortedActivityData, data)
                local dataMinGroupSize, dataMaxGroupSize = data:GetGroupSizeRange()
                if not minGroupSize or minGroupSize > dataMinGroupSize then
                    minGroupSize = dataMinGroupSize
                end

                if not maxGroupSize or maxGroupSize < dataMaxGroupSize then
                    maxGroupSize = dataMaxGroupSize
                end
            end
        else
            minGroupSize = 1
            maxGroupSize = 1
        end

        specificLocationsLookupData[activityType] = specificLookupActivityData
        randomActivityTypeGroupSizeRanges[activityType] = { min = minGroupSize, max = maxGroupSize }

        --Activity sets
        for activitySetIndex = 1, numActivitySets do
            local data = ZO_ActivityFinderLocation_Set:New(activityType, activitySetIndex)
            setLookupActivityData[data:GetId()] = data
            table.insert(sortedActivityData, data)
            local dataMinGroupSize, dataMaxGroupSize = data:GetGroupSizeRange()
            if not minGroupSize or minGroupSize > dataMinGroupSize then
                minGroupSize = dataMinGroupSize
            end

            if not maxGroupSize or maxGroupSize < dataMaxGroupSize then
                maxGroupSize = dataMaxGroupSize
            end
        end

        locationSetsLookupData[activityType] = setLookupActivityData
        
        table.sort(sortedActivityData, LFGSort)
        sortedLocationsData[activityType] = sortedActivityData
    end

    self.sortedLocationsData = sortedLocationsData
    self.specificLocationsLookupData = specificLocationsLookupData
    self.locationSetsLookupData = locationSetsLookupData
    self.randomActivityTypeGroupSizeRanges = randomActivityTypeGroupSizeRanges
    self.numSelected = 0
    self.randomActivityTypeLockReasons = {}
    self.randomActivitySelections = {}
end

-----------
--Updates--
-----------

function ActivityFinderRoot_Manager:OnUpdate()
    if self.dataDirty then
        self:ClearAndUpdate()
    end
end

function ActivityFinderRoot_Manager:MarkDataDirty()
    self.dataDirty = true
end

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
    self:MarkDataDirty()
end

function ActivityFinderRoot_Manager:GetGroupStatus()
    return self.playerIsGrouped, self.playerIsLeader, self.groupSize
end

local RANDOM_LOCK_REASON_PRIORITY =
{
    SELF_LEVEL = 10,
    GROUP_LEVEL = 20,
    NOT_LEADER = 30,
}

function ActivityFinderRoot_Manager:UpdateLocationData()
    --Determine lock status for each location
    local inAGroup = IsUnitGrouped("player")
    local isLeader = IsUnitGroupLeader("player")
    -- UI will only check local player roles.  Client and server will validate group member roles.
    -- This prevents group members disabling the leaders selections while they're trying to set up an activity and group member roles are being changed
    local isRoleDataValid = IsPreferredRoleSelected()

    ZO_ClearTable(self.randomActivityTypeLockReasons)

    for activityType, locationsByActivity in pairs(self.sortedLocationsData) do
        local isActivityAvA = ZO_IsActivityTypeAvA(activityType)
        local isActivityDungeon = ZO_IsActivityTypeDungeon(activityType)
        local isActivityHomeShow = ZO_IsActivityTypeHomeShow(activityType)
        local isActivityBattleground = ZO_IsActivityTypeBattleground(activityType)

        local activityRequiresRoles = isActivityDungeon
        local isGroupRelevant = inAGroup and not isActivityHomeShow
        local isPlayerInAvAWorld = IsPlayerInAvAWorld()
        local activityAvailableFromAvAWorld = isActivityAvA or isActivityBattleground
        local anyEligible = false
        local anyLockReasonData = {}
        local CONCISE_COOLDOWN_TEXT = false

        for index, location in ipairs(locationsByActivity) do
            location:SetLocked(true)
            location:SetCountsForAverageRoleTime(activityRequiresRoles)
            
            local cooldownText
            local applicableCooldowns = location:GetApplicableCooldownTypes()
            if applicableCooldowns then
                for _, cooldownType in ipairs(applicableCooldowns) do
                    cooldownText = self:GetLFGCooldownLockText(cooldownType, CONCISE_COOLDOWN_TEXT)
                    if cooldownText then
                        break
                    end
                end
            end

            if cooldownText then
                location:SetLockReasonText(cooldownText)
            elseif IsActiveWorldBattleground() then
                location:SetLockReasonText(SI_LFG_LOCK_REASON_IN_BATTLEGROUND)
            elseif isActivityAvA and not isPlayerInAvAWorld then
                location:SetLockReasonText(SI_LFG_LOCK_REASON_NOT_IN_AVA)
            elseif not activityAvailableFromAvAWorld and isPlayerInAvAWorld then
                location:SetLockReasonText(SI_LFG_LOCK_REASON_IN_AVA)
            elseif location:IsLockedByCollectible() then
                local collectibleId = location:GetFirstLockingCollectible()
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                local lockReasonText
                if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                    lockReasonText = GetString(SI_LFG_LOCK_REASON_CHAPTER_NOT_UNLOCKED)
                else
                    lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_DLC_NOT_UNLOCKED, collectibleData:GetName())
                end
                location:SetLockReasonText(lockReasonText)
                location:SetCountsForAverageRoleTime(false)
            elseif activityRequiresRoles and not isRoleDataValid then
                location:SetLockReasonText(SI_LFG_LOCK_REASON_NO_ROLES_SELECTED)
            else
                local groupTooLarge = isGroupRelevant and self.groupSize > location:GetMaxGroupSize()

                if groupTooLarge then
                    location:SetLockReasonText(SI_LFG_LOCK_REASON_GROUP_TOO_LARGE)
                elseif not location:DoesPlayerMeetLevelRequirements() then
                    local levelMin, levelMax = location:GetLevelRange()
                    local championPointsMin, championPointsMax = location:GetChampionPointsRange()
                    location:SetLockReasonText(GetLevelOrChampionPointsRequirementText(levelMin, levelMax, championPointsMin, championPointsMax))
                    location:SetRandomLockReasonPriority(RANDOM_LOCK_REASON_PRIORITY.SELF_LEVEL)
                    location:SetCountsForAverageRoleTime(false)
                elseif isGroupRelevant and not location:DoesGroupMeetLevelRequirements() then
                    location:SetLockReasonText(SI_LFG_LOCK_REASON_GROUP_LOCATION_LEVEL_REQUIREMENTS)
                    location:SetRandomLockReasonPriority(RANDOM_LOCK_REASON_PRIORITY.GROUP_LEVEL)
                elseif isGroupRelevant and not isLeader then
                    location:SetLockReasonText(SI_LFG_LOCK_REASON_NOT_LEADER)
                    location:SetRandomLockReasonPriority(RANDOM_LOCK_REASON_PRIORITY.NOT_LEADER)
                else
                    location:SetLocked(false)
                    location:SetLockReasonText("")
                    anyEligible = true
                end
            end

            if location:IsLocked() then
                -- ESO-538378: We do this because when there are more than one reason why random is unavailable, the broadest reason is usually the most accurate to show
                local locationPriority = location:GetRandomLockReasonPriority()
                local locationHasHigherPriority = locationPriority and (not anyLockReasonData.priority or anyLockReasonData.priority < locationPriority)
                if not anyLockReasonData.text or locationHasHigherPriority then
                    anyLockReasonData.text = location:GetLockReasonText()
                    anyLockReasonData.priority = locationPriority
                end
                self:SetLocationSelected(location, false)
            end
        end

        if anyEligible then
            self.randomActivityTypeLockReasons[activityType] = nil
        else
            self.randomActivityTypeLockReasons[activityType] = anyLockReasonData.text
        end
    end

    self:FireCallbacks("OnUpdateLocationData")
end

function ActivityFinderRoot_Manager:ClearSelections()
    for activityType, locationsByActivity in pairs(self.sortedLocationsData) do
        self.randomActivitySelections[activityType] = false

        for index, location in ipairs(locationsByActivity) do
            location:SetSelected(false)
        end
    end

    self.numSelected = 0
end

function ActivityFinderRoot_Manager:RebuildSelections(activityTypes)
    local activityTypeLookup = {}
    for _, activityType in ipairs(activityTypes) do
        activityTypeLookup[activityType] = true
    end

    local activeRequests = GetNumActivityRequests()
    for i = 1, activeRequests do
        local activityId, activitySetId = GetActivityRequestIds(i)
        if activitySetId ~= 0 then
            for activityType, locationSetsData in pairs(self.locationSetsLookupData) do
                if activityTypeLookup[activityType] then
                    local location = locationSetsData[activitySetId]
                    if location then
                        location:SetSelected(true)
                        self.numSelected = self.numSelected + 1
                    end
                end
            end
        else
            local activityType = GetActivityType(activityId)
            if activityTypeLookup[activityType] then
                local location = self.specificLocationsLookupData[activityType][activityId]
                location:SetSelected(true)
                self.numSelected = self.numSelected + 1
            end
        end
    end
end

function ActivityFinderRoot_Manager:ClearAndUpdate()
    --A clear and update is required when the selections may change due to requirement changes. (Ex: a group member
    --joins that doesn't meet the level requirement of a location already selected. The location needs to be unselected
    --and locked, and then all other locations need to be refreshed again in case they are now unlocked. Instead of
    --nesting refreshes, just clear and update when an event occurs that can lead to this.)

    self:ClearSelections()
    self:UpdateLocationData()
    self.dataDirty = false
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

function ActivityFinderRoot_Manager:GetSpecificLocation(activityId)
    for activityType, locationsByActivity in pairs(self.specificLocationsLookupData) do
        if locationsByActivity then
            local location = locationsByActivity[activityId]
            if location then
                return location
            end
        end
    end
    assert(false) --We should never be asking for a location using a bad activity or lfgIndex, fix the code that called this
end

function ActivityFinderRoot_Manager:GetAverageRoleTime(role)
    local lowestAverage
    for activityType, locationsByActivity in pairs(self.sortedLocationsData) do
        for index, location in ipairs(locationsByActivity) do
            if location:CountsForAverageRoleTime() then
                local dataFound, averageForLocation = GetActivityAverageRoleTime(location:GetId(), role)
                if dataFound then
                    if lowestAverage then
                        lowestAverage = zo_min(lowestAverage, averageForLocation)
                    else
                        lowestAverage = averageForLocation
                    end
                end
            end
        end
    end

    return lowestAverage or 0
end

function ActivityFinderRoot_Manager:GetIsCurrentlyInQueue()
    return self.activityFinderStatus == ACTIVITY_FINDER_STATUS_QUEUED or self.activityFinderStatus == ACTIVITY_FINDER_STATUS_READY_CHECK
end

function ActivityFinderRoot_Manager:ToggleLocationSelected(location)
    self:SetLocationSelected(location, not location:IsSelected())
end

function ActivityFinderRoot_Manager:SetLocationSelected(location, selected)
    if IsCurrentlySearchingForGroup() or location:IsSelected() == selected or (location:IsLocked() and selected) then
        return
    end

    location:SetSelected(selected)
    local delta = selected and 1 or -1
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

function ActivityFinderRoot_Manager:IsActivityTypeSelected(activityType, includeSpecificLocations)
    local anySelected = self.randomActivitySelections[activityType]
    if not anySelected and includeSpecificLocations then
        local locationsByActivity = self.sortedLocationsData[activityType]
        for index, location in ipairs(locationsByActivity) do
            if location:IsSelected() then
                anySelected = true
                break
            end
        end
    end
    return anySelected
end

function ActivityFinderRoot_Manager:IsAnyLocationSelected()
    return self.numSelected > 0
end

function ActivityFinderRoot_Manager:GetNumLocationsByActivity(activityType, visibleEntryTypes)
    local locationsByActivity = self.sortedLocationsData[activityType]
    if locationsByActivity then
        if not visibleEntryTypes then
            return #locationsByActivity
        else
            local numLocations = 0
            for _, location in ipairs(locationsByActivity) do
                for _, entryType in ipairs(visibleEntryTypes) do
                    if location:GetEntryType() == entryType then
                        numLocations = numLocations + 1
                        break
                    end
                end
            end
            return numLocations
        end
    end

    return 0
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

function ActivityFinderRoot_Manager:IsLockedByNotLeader()
    if self.playerIsGrouped and not self.playerIsLeader then
        --Home Show ignores the group
        local INCLUDE_SPECIFICS = true
        if ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsActivityTypeSelected(LFG_ACTIVITY_HOME_SHOW, INCLUDE_SPECIFICS) then
            return false
        end
        return true
    end
    return false
end

function ActivityFinderRoot_Manager:IsLFGCooldownTypeOnCooldown(cooldownType)
    local cooldownData = self.cooldowns[cooldownType]
    if cooldownData then
        return cooldownData.isOnCooldown
    end
    return false
end

function ActivityFinderRoot_Manager:GetLFGCooldownExpireTimeS(cooldownType)
    local cooldownData = self.cooldowns[cooldownType]
    if cooldownData then
        return cooldownData.expiresAtS
    end
    return 0
end

function ActivityFinderRoot_Manager:GetLFGCooldownLockText(cooldownType, verbose)
    local cooldownData = self.cooldowns[cooldownType]
    if cooldownData and cooldownData.isOnCooldown then
        if verbose then
            local expireTimeS = self:GetLFGCooldownExpireTimeS(cooldownType)
            local timeRemainingS = zo_max(expireTimeS - GetFrameTimeSeconds(), 0)
            local formattedTimeText = ZO_FormatTime(timeRemainingS, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            return zo_strformat(cooldownData.verboseFormatter, formattedTimeText)
        else
            return GetString(cooldownData.conciseFormatter)
        end
    end
    --If we're not on cooldown, we return nil because a nil lock text has meaning for activity finders
    return nil
end

function ActivityFinderRoot_Manager:StartSearch()
    if IsCurrentlySearchingForGroup() then
        return
    end

    ClearGroupFinderSearch()

    --Add locations
    for activityType, locationsByActivity in pairs(self.sortedLocationsData) do
        if self.randomActivitySelections[activityType] then
            AddActivityFinderRandomSearchEntry(activityType)
        end

        for index, location in ipairs(locationsByActivity) do
            if location:IsSelected() then
                location:AddActivitySearchEntry()
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
