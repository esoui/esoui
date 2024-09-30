ZO_ACTIVITY_FINDER_SORT_PRIORITY =
{
    GROUP = 0,
    PROMOTIONAL_EVENTS = 100,
    GROUP_FINDER = 200,
    TIMED_ACTIVITIES = 300,
    ZONE_STORIES = 400,
    DUNGEONS = 500,
    BATTLEGROUNDS = 600,
    TRIBUTE = 700,
    HOUSE_TOURS = 800,
}

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

local function GetLevelOrChampionPointsRequirementText(levelMin, levelMax, pointsMin, pointsMax)
    local playerChampionPoints = GetUnitChampionPoints("player")
    
    if playerChampionPoints > 0 or levelMin == GetMaxLevel() then
        if playerChampionPoints < pointsMin then
            return ZO_CachedStrFormat(SI_LFG_LOCK_REASON_PLAYER_MIN_CHAMPION_REQUIREMENT, pointsMin)
        elseif playerChampionPoints > pointsMax then
            return ZO_CachedStrFormat(SI_LFG_LOCK_REASON_PLAYER_MAX_CHAMPION_REQUIREMENT, pointsMax)
        end
    else
        local playerLevel = GetUnitLevel("player")
    
        if playerLevel < levelMin then
            return ZO_CachedStrFormat(SI_LFG_LOCK_REASON_PLAYER_MIN_LEVEL_REQUIREMENT, levelMin)
        elseif playerLevel > levelMax then
            return ZO_CachedStrFormat(SI_LFG_LOCK_REASON_PLAYER_MAX_LEVEL_REQUIREMENT, levelMax)
        end
    end
end

function ZO_IsActivityTypeDungeon(activityType)
    return activityType == LFG_ACTIVITY_MASTER_DUNGEON or activityType == LFG_ACTIVITY_DUNGEON
end

function ZO_IsActivityTypeBattleground(activityType)
    return activityType == LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL or activityType == LFG_ACTIVITY_BATTLE_GROUND_CHAMPION or activityType == LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION
end

function ZO_DoesActivityTypeRequireRoles(activityType)
    return activityType == LFG_ACTIVITY_MASTER_DUNGEON or activityType == LFG_ACTIVITY_DUNGEON
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
        [LFG_COOLDOWN_BATTLEGROUND_DESERTED_QUEUE] =
        {
            isOnCooldown = false,
            expiresAtS = 0,
            conciseFormatter = SI_LFG_LOCK_REASON_LEFT_BATTLEGROUND_EARLY_CONCISE,
            verboseFormatter = SI_LFG_LOCK_REASON_LEFT_BATTLEGROUND_EARLY_VERBOSE,
        },
        [LFG_COOLDOWN_TRIBUTE_DESERTED] =
        {
            isOnCooldown = false,
            expiresAtS = 0,
            conciseFormatter = SI_LFG_LOCK_REASON_LEFT_TRIBUTE_EARLY_CONCISE,
            verboseFormatter = SI_LFG_LOCK_REASON_LEFT_TRIBUTE_EARLY_VERBOSE,
        },
    }

    self:InitializeLocationData()
    self:RegisterForEvents()
end

function ActivityFinderRoot_Manager:RegisterForEvents()
    local function ClearSelections()
        self:ClearSelections()
    end

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByUnlockState)
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
            self:MarkDataDirty()
        else
            for _, unlockStateTable in pairs(collectiblesByUnlockState) do
                for _, collectibleData in ipairs(unlockStateTable) do
                    if collectibleData:IsStory() then
                        self:MarkDataDirty()
                        return
                    end
                end
            end
        end
    end

    local function UpdateGroupStatus()
        self:UpdateGroupStatus()
    end

    local function OnLevelUpdate(eventCode, unitTag)
        if unitTag == "player" or ZO_Group_IsGroupUnitTag(unitTag) then
            self:MarkDataDirty()
            self:FireCallbacks("OnLevelUpdate")
        end
    end

    local function OnCooldownsUpdate()
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

    local function OnCurrentCampaignChanged()
        self:MarkDataDirty()
        self:FireCallbacks("OnCurrentCampaignChanged")
    end

    local function OnPlayerActivate()
        UpdateGroupStatus()
        OnCooldownsUpdate()
    end

    local function OnTributeClubDataInitialized()
        self:MarkDataDirty()
        self:FireCallbacks("OnTributeClubDataInitialized")
    end

    local function OnTributeCampaignDataInitialized()
        self:MarkDataDirty()
        self:FireCallbacks("OnTributeCampaignDataInitialized")
    end

    local function OnTributeClubRankDataChanged()
        self:MarkDataDirty()
        self:FireCallbacks("OnTributeClubRankDataChanged")
    end

    local function OnTributeCampaignDataChanged()
        self:MarkDataDirty()
        self:FireCallbacks("OnTributeCampaignDataChanged")
    end

    local function OnTributeLeaderboardRankChanged()
        self:MarkDataDirty()
        self:FireCallbacks("OnTributeLeaderboardRankChanged")
    end

    local function OnHolidaysChanged()
        self:MarkDataDirty()
        self:FireCallbacks("OnHolidaysChanged")
    end

    local function OnQuestsChanged()
        self:MarkDataDirty()
        self:FireCallbacks("OnQuestsChanged")
    end
    
    local function OnDisabledActivitiesUpdate()
        self:UpdateLocationData()
    end

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_ACTIVITY_FINDER_STATUS_UPDATE, function(eventCode, ...) self:OnActivityFinderStatusUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_ACTIVITY_FINDER_COOLDOWNS_UPDATE, OnCooldownsUpdate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_CURRENT_CAMPAIGN_CHANGED, OnCurrentCampaignChanged)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_TRIBUTE_CLUB_INIT, OnTributeClubDataInitialized)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_TRIBUTE_PLAYER_CAMPAIGN_INIT, OnTributeCampaignDataInitialized)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_TRIBUTE_CLUB_EXPERIENCE_GAINED, OnTributeClubRankDataChanged)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_TRIBUTE_CAMPAIGN_CHANGE, OnTributeCampaignDataChanged)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_TRIBUTE_LEADERBOARD_RANK_RECEIVED, OnTributeLeaderboardRankChanged)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)

    --We should clear selections when switching filters, but we won't necessarily clear them when closing scenes
    --However, we can't ensure that gamepad and keyboard will stay on the same filter, so we'll clear selections when switching between modes
    --This won't require rechecking lock statuses
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, ClearSelections)

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_LEVEL_UPDATE, OnLevelUpdate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_CHAMPION_POINT_UPDATE, OnLevelUpdate)

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_HOLIDAYS_CHANGED, OnHolidaysChanged)

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_QUEST_ADDED, OnQuestsChanged)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_QUEST_REMOVED, OnQuestsChanged)

    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_PLAYER_ACTIVATED, OnPlayerActivate)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GROUP_MEMBER_LEFT, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_UNIT_CREATED, function(eventCode, unitTag) 
        if ZO_Group_IsGroupUnitTag(unitTag) then
            self:UpdateGroupStatus()
        end
    end)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_GROUP_UPDATE, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_LEADER_UPDATE, UpdateGroupStatus)
    EVENT_MANAGER:RegisterForEvent("ActivityFinderRoot_Manager", EVENT_DISABLED_ACTIVITIES_UPDATE, OnDisabledActivitiesUpdate)
    EVENT_MANAGER:RegisterForUpdate("ActivityFinderRoot_Manager", 0, function() self:OnUpdate() end)
end

function ActivityFinderRoot_Manager:InitializeLocationData()
    local specificLocationsLookupData = {}
    local locationSetsLookupData = {}
    local sortedLocationsData = {}

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
    self.numSelected = 0
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
    local previousGroupSize = self.groupSize
    self.playerIsGrouped = IsUnitGrouped("player")
    self.playerIsLeader = IsUnitGroupLeader("player")
    self.groupSize = GetGroupSize()
    local groupStateChanged = wasGrouped ~= self.playerIsGrouped or wasLeader ~= self.playerIsLeader or previousGroupSize ~= self.groupSize
    if groupStateChanged then
        self:FireCallbacks("OnUpdateGroupStatus", wasGrouped, self.playerIsGrouped, wasLeader, self.playerIsLeader)
        self:MarkDataDirty()
    end
end

function ActivityFinderRoot_Manager:GetGroupStatus()
    return self.playerIsGrouped, self.playerIsLeader, self.groupSize
end

function ActivityFinderRoot_Manager:UpdateLocationData()
    --Determine lock status for each location
    local inAGroup = IsUnitGrouped("player")
    local isLeader = IsUnitGroupLeader("player")
    local tributeLockText = ZO_IsTributeLocked() and ZO_GetTributeLockReasonTooltipString() or nil

    for activityType, locationsByActivity in pairs(self.sortedLocationsData) do
        local activityRequiresRoles = ZO_DoesActivityTypeRequireRoles(activityType)
        local isGroupRelevant = inAGroup
        local CONCISE_COOLDOWN_TEXT = false

        for _, location in ipairs(locationsByActivity) do
            location:SetLocked(true)

            local isLockedByAvailabilityRequirement, availabilityRequirementErrorStringId = location:IsLockedByAvailablityRequirementList()
            if isLockedByAvailabilityRequirement then
                local lockReasonText = GetErrorString(availabilityRequirementErrorStringId)
                if lockReasonText == "" then
                    lockReasonText = GetString("SI_ACTIVITYQUEUERESULT", ACTIVITY_QUEUE_RESULT_DESTINATION_NO_LONGER_VALID)
                end
                location:SetLockReasonText(lockReasonText)
                location:SetCountsForAverageRoleTime(false)
                location:SetActive(false)
            else
                location:SetActive(true)
                location:SetCountsForAverageRoleTime(activityRequiresRoles)
                local cooldownText
                local applicableCooldowns = location:GetApplicableCooldownTypes()
                if applicableCooldowns and applicableCooldowns.queueCooldownType then
                    cooldownText = self:GetLFGCooldownLockText(applicableCooldowns.queueCooldownType, CONCISE_COOLDOWN_TEXT)
                end

                if cooldownText then
                    location:SetLockReasonText(cooldownText)
                elseif location:IsLockedByPlayerLocation() then
                    if IsActiveWorldBattleground() then
                        location:SetLockReasonText(SI_LFG_LOCK_REASON_IN_BATTLEGROUND)
                    elseif IsPlayerInAvAWorld() then
                        location:SetLockReasonText(SI_LFG_LOCK_REASON_IN_AVA)
                    else
                        location:SetLockReasonText(SI_LFG_LOCK_REASON_INVALID_AREA)
                    end
                elseif location:IsTributeActivity() and tributeLockText then
                    location:SetLockReasonText(tributeLockText)
                elseif location:IsLockedByCollectible() then
                    local collectibleId = location:GetFirstLockingCollectible()
                    local collectibleData = ZO_CollectibleData_Base.Acquire(collectibleId)
                    local lockReasonStringId = nil
                    if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                        lockReasonStringId = SI_LFG_LOCK_REASON_COLLECTIBLE_NOT_UNLOCKED_UPGRADE
                    elseif collectibleData:IsPurchasable() then
                        lockReasonStringId = SI_LFG_LOCK_REASON_COLLECTIBLE_NOT_UNLOCKED_CROWN_STORE
                    else
                        lockReasonStringId = SI_LFG_LOCK_REASON_COLLECTIBLE_NOT_UNLOCKED
                    end
                    local lockReasonText = zo_strformat(lockReasonStringId, collectibleData:GetName(), collectibleData:GetCategoryName())
                    location:SetLockReasonText(lockReasonText)
                    location:SetCountsForAverageRoleTime(false)
                    collectibleData:ReleaseObject()
                else
                    local groupTooLarge = isGroupRelevant and self.groupSize > location:GetMaxGroupSize()
                    if groupTooLarge then
                        location:SetLockReasonText(SI_LFG_LOCK_REASON_GROUP_TOO_LARGE)
                    elseif not location:DoesPlayerMeetLevelRequirements() then
                        local levelMin, levelMax = location:GetLevelRange()
                        local championPointsMin, championPointsMax = location:GetChampionPointsRange()
                        location:SetLockReasonText(GetLevelOrChampionPointsRequirementText(levelMin, levelMax, championPointsMin, championPointsMax))
                        location:SetCountsForAverageRoleTime(false)
                    elseif location:IsDisabled() then
                        location:SetLockReasonText(SI_ACTIVITY_FINDER_ACTIVITY_DISABLED)
                    elseif activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE and not HasActiveCampaignStarted() then
                        location:SetLockReasonText(SI_TRIBUTE_FINDER_LOCKED_NO_CAMPAIGN_TEXT)
                    elseif ZO_GroupFinder_IsGroupFinderInUse() then
                        location:SetLockReasonText(SI_ACTIVITY_FINDER_LOCKED_BY_GROUP_FINDER_TEXT)
                    elseif isGroupRelevant and not location:DoesGroupMeetLevelRequirements() then
                        location:SetLockReasonText(SI_LFG_LOCK_REASON_GROUP_LOCATION_LEVEL_REQUIREMENTS)
                    elseif isGroupRelevant and not isLeader then
                        location:SetLockReasonText(SI_LFG_LOCK_REASON_NOT_LEADER)
                    else
                        location:SetLocked(false)
                        location:SetLockReasonText("")
                    end
                end

                if location:IsLocked() then
                    self:SetLocationSelected(location, false)
                end
            end
        end
    end

    self:FireCallbacks("OnUpdateLocationData")
end

function ActivityFinderRoot_Manager:ClearSelections()
    local previousNumSelected = self.numSelected
    for _, locationsByActivity in pairs(self.sortedLocationsData) do
        for _, location in ipairs(locationsByActivity) do
            location:SetSelected(false)
        end
    end

    self.numSelected = 0

    if previousNumSelected > 0 then
        self:FireCallbacks("OnSelectionsChanged")
    end
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
    for _, locationsByActivity in pairs(self.specificLocationsLookupData) do
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
    for _, locationsByActivity in pairs(self.sortedLocationsData) do
        for _, location in ipairs(locationsByActivity) do
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

function ActivityFinderRoot_Manager:IsActivityTypeSelected(activityType)
    local locationsByActivity = self.sortedLocationsData[activityType]
    for _, location in ipairs(locationsByActivity) do
        if location:IsSelected() then
            return true
        end
    end
    return false
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
                    if location:GetEntryType() == entryType and location:IsActive() then
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

function ActivityFinderRoot_Manager:IsLockedByNotLeader()
    return self.playerIsGrouped and not self.playerIsLeader
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

    ClearActivityFinderSearch()

    --Add locations
    for _, locationsByActivity in pairs(self.sortedLocationsData) do
        for _, location in ipairs(locationsByActivity) do
            if location:IsSelected() then
                location:AddActivitySearchEntry()
            end
        end
    end

    local result = StartActivityFinderSearch()
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
