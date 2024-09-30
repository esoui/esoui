ZO_ACTIVITY_FINDER_GENERALIZED_ACTIVITY_DESCRIPTORS =
{
    [LFG_ACTIVITY_DUNGEON] = GetString(SI_DUNGEON_FINDER_GENERAL_ACTIVITY_DESCRIPTOR),
    [LFG_ACTIVITY_MASTER_DUNGEON] = GetString(SI_DUNGEON_FINDER_GENERAL_ACTIVITY_DESCRIPTOR),
    [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = GetString(SI_BATTLEGROUND_FINDER_GENERAL_ACTIVITY_DESCRIPTOR),
    [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = GetString(SI_BATTLEGROUND_FINDER_GENERAL_ACTIVITY_DESCRIPTOR),
    [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = GetString(SI_BATTLEGROUND_FINDER_GENERAL_ACTIVITY_DESCRIPTOR),
    [LFG_ACTIVITY_TRIBUTE_COMPETITIVE] = GetString(SI_TRIBUTE_FINDER_GENERAL_ACTIVITY_DESCRIPTOR),
    [LFG_ACTIVITY_TRIBUTE_CASUAL] = GetString(SI_TRIBUTE_FINDER_GENERAL_ACTIVITY_DESCRIPTOR),
}

----------
-- Base --
----------

ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE =
{
    SPECIFIC = 1,
    SET = 2,
}

ZO_ActivityFinderLocation_Base = ZO_Object:Subclass()

function ZO_ActivityFinderLocation_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ActivityFinderLocation_Base:Initialize(activityType, id, rawName, description, levelMin, levelMax, championPointsMin, championPointsMax, minGroupSize, maxGroupSize, sortOrder, descriptionTextureSmallKeyboard, descriptionTextureLargeKeyboard, descriptionTextureGamepad, forceFullPanelKeyboard)
    self.activityType = activityType
    self.id = id
    self.rawName = rawName
    self.description = description
    self.levelMin = levelMin
    self.levelMax = levelMax
    self.championPointsMin = championPointsMin
    self.championPointsMax = championPointsMax
    self.minGroupSize = minGroupSize
    self.maxGroupSize = maxGroupSize
    self.sortOrder = sortOrder
    self.descriptionTextureSmallKeyboard = descriptionTextureSmallKeyboard
    self.descriptionTextureLargeKeyboard = descriptionTextureLargeKeyboard
    self.descriptionTextureGamepad = descriptionTextureGamepad
    self.forceFullPanelKeyboard = forceFullPanelKeyboard

    self:InitializeFormattedNames()
end

function ZO_ActivityFinderLocation_Base:InitializeFormattedNames()
    local basicFormattedName =  zo_strformat(SI_LFG_ACTIVITY_NAME, self.rawName)
    self.nameKeyboard = basicFormattedName
    self.nameGamepad = basicFormattedName
end

function ZO_ActivityFinderLocation_Base:IsTributeActivity()
    return self.activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE or self.activityType == LFG_ACTIVITY_TRIBUTE_CASUAL
end

ZO_ActivityFinderLocation_Base.AddActivitySearchEntry = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

do
    local TEAM_BASED_ACTIVITY_TYPES =
    {
        [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = true,
        [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = true,
        [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = true,
    }

    function ZO_ActivityFinderLocation_Base:SetGroupSizeRangeText(labelControl, groupIconFormat)
        if self.activityType ~= LFG_ACTIVITY_TRIBUTE_COMPETITIVE and self.activityType ~= LFG_ACTIVITY_TRIBUTE_CASUAL then
            local minGroupSize, maxGroupSize = self:GetGroupSizeRange()
            if TEAM_BASED_ACTIVITY_TYPES[self.activityType] then
                labelControl:SetText(zo_strformat(SI_ACTIVITY_FINDER_GROUP_SIZE_TEAM_FORMAT, maxGroupSize, groupIconFormat))
            elseif minGroupSize ~= maxGroupSize then
                labelControl:SetText(zo_strformat(SI_ACTIVITY_FINDER_GROUP_SIZE_RANGE_FORMAT, minGroupSize, maxGroupSize, groupIconFormat))
            else
                labelControl:SetText(zo_strformat(SI_ACTIVITY_FINDER_GROUP_SIZE_SIMPLE_FORMAT, minGroupSize, groupIconFormat))
            end
        else
            labelControl:SetText("")
        end
    end
end

do
    local DUNGEON_COOLDOWNS =
    {
        queueCooldownType = LFG_COOLDOWN_ACTIVITY_STARTED,
        dailyRewardCooldownType = LFG_COOLDOWN_DUNGEON_REWARD_GRANTED,
    }

    local BATTLEGROUND_COOLDOWNS =
    {
        queueCooldownType = LFG_COOLDOWN_BATTLEGROUND_DESERTED_QUEUE,
        dailyRewardCooldownType = LFG_COOLDOWN_BATTLEGROUND_REWARD_GRANTED,
    }

    local TRIBUTE_COOLDOWNS =
    {
        queueCooldownType = LFG_COOLDOWN_TRIBUTE_DESERTED,
        dailyRewardCooldownType = LFG_COOLDOWN_TRIBUTE_REWARD_GRANTED,
    }

    local ACTIVITY_TYPE_APPLICABLE_COOLDOWN_TYPES =
    {
        [LFG_ACTIVITY_DUNGEON] = DUNGEON_COOLDOWNS,
        [LFG_ACTIVITY_MASTER_DUNGEON] = DUNGEON_COOLDOWNS,
        [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = BATTLEGROUND_COOLDOWNS,
        [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = BATTLEGROUND_COOLDOWNS,
        [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = BATTLEGROUND_COOLDOWNS,
        [LFG_ACTIVITY_TRIBUTE_COMPETITIVE] = TRIBUTE_COOLDOWNS,
        [LFG_ACTIVITY_TRIBUTE_CASUAL] = TRIBUTE_COOLDOWNS,
    }

    function ZO_ActivityFinderLocation_Base:GetApplicableCooldownTypes()
        return ACTIVITY_TYPE_APPLICABLE_COOLDOWN_TYPES[self.activityType]
    end
end

-- Static data --

function ZO_ActivityFinderLocation_Base:GetActivityType()
    return self.activityType
end

function ZO_ActivityFinderLocation_Base:GetId()
    return self.id
end

function ZO_ActivityFinderLocation_Base:GetRawName()
    return self.rawName
end

function ZO_ActivityFinderLocation_Base:SetNameKeyboard(nameKeyboard)
    self.nameKeyboard = nameKeyboard
end

function ZO_ActivityFinderLocation_Base:GetNameKeyboard()
    return self.nameKeyboard
end

function ZO_ActivityFinderLocation_Base:SetNameGamepad(nameGamepad)
    self.nameGamepad = nameGamepad
end

function ZO_ActivityFinderLocation_Base:GetNameGamepad()
    return self.nameGamepad
end

function ZO_ActivityFinderLocation_Base:GetLevelMin()
    return self.levelMin
end

function ZO_ActivityFinderLocation_Base:GetLevelMax()
    return self.levelMax
end

function ZO_ActivityFinderLocation_Base:GetLevelRange()
    return self.levelMin, self.levelMax
end

function ZO_ActivityFinderLocation_Base:GetChampionPointsMin()
    return self.championPointsMin
end

function ZO_ActivityFinderLocation_Base:GetChampionPointsMax()
    return self.championPointsMax
end

function ZO_ActivityFinderLocation_Base:GetChampionPointsRange()
    return self.championPointsMin, self.championPointsMax
end

function ZO_ActivityFinderLocation_Base:GetMinGroupSize()
    return self.minGroupSize
end

function ZO_ActivityFinderLocation_Base:GetMaxGroupSize()
    return self.maxGroupSize
end

function ZO_ActivityFinderLocation_Base:GetGroupSizeRange()
    return self.minGroupSize, self.maxGroupSize
end

function ZO_ActivityFinderLocation_Base:GetDescription()
    return self.description
end

function ZO_ActivityFinderLocation_Base:GetSortOrder()
    return self.sortOrder
end

function ZO_ActivityFinderLocation_Base:GetDescriptionTextureSmallKeyboard()
    return self.descriptionTextureSmallKeyboard
end

function ZO_ActivityFinderLocation_Base:GetDescriptionTextureLargeKeyboard()
    return self.descriptionTextureLargeKeyboard
end

function ZO_ActivityFinderLocation_Base:GetDescriptionTextureGamepad()
    return self.descriptionTextureGamepad
end

function ZO_ActivityFinderLocation_Base:ShouldForceFullPanelKeyboard()
    return self.forceFullPanelKeyboard
end

ZO_ActivityFinderLocation_Base.IsLockedByPlayerLocation = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

ZO_ActivityFinderLocation_Base.IsLockedByCollectible = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

ZO_ActivityFinderLocation_Base.GetFirstLockingCollectible = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

ZO_ActivityFinderLocation_Base.IsLockedByAvailablityRequirementList = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

ZO_ActivityFinderLocation_Base.GetEntryType = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

ZO_ActivityFinderLocation_Base.GetZoneId = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

ZO_ActivityFinderLocation_Base.IsDisabled = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

function ZO_ActivityFinderLocation_Base:IsSpecificEntryType()
    return self:GetEntryType() == ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SPECIFIC
end

function ZO_ActivityFinderLocation_Base:IsSetEntryType()
    return self:GetEntryType() == ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SET
end

-- Dynamic Data --

function ZO_ActivityFinderLocation_Base:SetSelected(isSelected)
    self.isSelected = isSelected
end

function ZO_ActivityFinderLocation_Base:IsSelected()
    return self.isSelected
end

function ZO_ActivityFinderLocation_Base:SetLocked(isLocked)
    self.isLocked = isLocked
end

function ZO_ActivityFinderLocation_Base:IsLocked()
    return self.isLocked
end

function ZO_ActivityFinderLocation_Base:SetActive(isActive)
    self.isActive = isActive
end

function ZO_ActivityFinderLocation_Base:IsActive()
    return self.isActive
end

function ZO_ActivityFinderLocation_Base:SetLockReasonText(lockReasonTextOrStringId)
    if type(lockReasonTextOrStringId) == "number" then
        self.lockReasonText = GetString(lockReasonTextOrStringId)
    else
        self.lockReasonText = lockReasonTextOrStringId
    end
end

function ZO_ActivityFinderLocation_Base:GetLockReasonText()
    return self.lockReasonText
end

ZO_ActivityFinderLocation_Base.GetQuestToUnlock = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

function ZO_ActivityFinderLocation_Base:SetLockReasonTextOverride(lockReasonTextOverride)
    self.lockReasonTextOverride = lockReasonTextOverride
end

function ZO_ActivityFinderLocation_Base:GetLockReasonTextOverride()
    return self.lockReasonTextOverride
end

function ZO_ActivityFinderLocation_Base:SetCountsForAverageRoleTime(countsForAverageRoleTime)
    self.countsForAverageRoleTime = countsForAverageRoleTime
end

function ZO_ActivityFinderLocation_Base:CountsForAverageRoleTime()
    return self.countsForAverageRoleTime
end

ZO_ActivityFinderLocation_Base.DoesPlayerMeetLevelRequirements = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

ZO_ActivityFinderLocation_Base.DoesGroupMeetLevelRequirements = ZO_ActivityFinderLocation_Base:MUST_IMPLEMENT()

-----------------------
-- Specific Activity --
-----------------------

ZO_ActivityFinderLocation_Specific = ZO_ActivityFinderLocation_Base:Subclass()

function ZO_ActivityFinderLocation_Specific:New(...)
    return ZO_ActivityFinderLocation_Base.New(self, ...)
end

function ZO_ActivityFinderLocation_Specific:Initialize(activityType, index)
    local activityId = GetActivityIdByTypeAndIndex(activityType, index)
    local rawName, levelMin, levelMax, championPointsMin, championPointsMax, groupType, minGroupSize, description, sortOrder = GetActivityInfo(activityId)
    local maxGroupSize = GetGroupSizeFromLFGGroupType(groupType)
    local descriptionTextureSmallKeyboard, descriptionTextureLargeKeyboard = GetActivityKeyboardDescriptionTextures(activityId)
    local descriptionTextureGamepad = GetActivityGamepadDescriptionTexture(activityId)
    self.requiredCollectible = GetRequiredActivityCollectibleId(activityId)
    local forceFullPanelKeyboard = ShouldActivityForceFullPanelKeyboard(activityId)
    self.zoneId = GetActivityZoneId(activityId)

    ZO_ActivityFinderLocation_Base.Initialize(self, activityType, activityId, rawName, description, levelMin, levelMax, championPointsMin, championPointsMax, minGroupSize, maxGroupSize, sortOrder, descriptionTextureSmallKeyboard, descriptionTextureLargeKeyboard, descriptionTextureGamepad, forceFullPanelKeyboard)
end

function ZO_ActivityFinderLocation_Specific:InitializeFormattedNames()
    if self:GetActivityType() == LFG_ACTIVITY_MASTER_DUNGEON then
        self:SetNameKeyboard(zo_iconTextFormat(ZO_GetVeteranIcon(), "100%", "100%", self:GetRawName()))
        self:SetNameGamepad(zo_strformat(GetString(SI_GAMEPAD_ACTIVITY_FINDER_VETERAN_LOCATION_FORMAT), self:GetRawName()))
    else
        ZO_ActivityFinderLocation_Base.InitializeFormattedNames(self)
    end
end

function ZO_ActivityFinderLocation_Specific:AddActivitySearchEntry()
    AddActivityFinderSpecificSearchEntry(self:GetId())
end

function ZO_ActivityFinderLocation_Specific:DoesPlayerMeetLevelRequirements()
    return DoesPlayerMeetActivityLevelRequirements(self:GetId())
end

function ZO_ActivityFinderLocation_Specific:DoesGroupMeetLevelRequirements()
    return DoesGroupMeetActivityLevelRequirements(self:GetId())
end

function ZO_ActivityFinderLocation_Specific:IsLockedByPlayerLocation()
    return not IsActivityAvailableFromPlayerLocation(self:GetId())
end

function ZO_ActivityFinderLocation_Specific:IsLockedByCollectible()
    if self.requiredCollectible ~= 0 then
        return not IsCollectibleUnlocked(self.requiredCollectible)
    end
    return false
end

function ZO_ActivityFinderLocation_Specific:GetFirstLockingCollectible()
    if self:IsLockedByCollectible() then
        return self.requiredCollectible
    end

    return 0
end

function ZO_ActivityFinderLocation_Specific:IsLockedByAvailablityRequirementList()
    return false -- Not currently supported for specifics
end

function ZO_ActivityFinderLocation_Specific:GetQuestToUnlock()
    return 0 -- Not currently supported for specifics, as an optimization
end

function ZO_ActivityFinderLocation_Specific:HasRewardData()
    return false -- Presently, specifics can't grant rewards
end

function ZO_ActivityFinderLocation_Specific:HasMMR()
    return false
end

function ZO_ActivityFinderLocation_Specific:GetEntryType()
    return ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SPECIFIC
end

function ZO_ActivityFinderLocation_Specific:GetZoneId()
    return self.zoneId
end

function ZO_ActivityFinderLocation_Specific:IsDisabled()
    return IsLFGActivityDisabled(self.id)
end

------------------
-- Activity Set --
------------------

ZO_ActivityFinderLocation_Set = ZO_ActivityFinderLocation_Base:Subclass()

function ZO_ActivityFinderLocation_Set:New(...)
    return ZO_ActivityFinderLocation_Base.New(self, ...)
end

function ZO_ActivityFinderLocation_Set:Initialize(activityType, index)
    self.activities = {}
    self.requiredCollectibles = {}
    local hasActivityWithNoCollectibleRestriction = false

    local activitySetId = GetActivitySetIdByTypeAndIndex(activityType, index)

    local minGroupSize, maxGroupSize
    local levelMin, levelMax
    local championPointsMin, championPointsMax

    for activityIndex = 1, GetNumActivitySetActivities(activitySetId) do
        local activityId = GetActivitySetActivityIdByIndex(activitySetId, activityIndex)

        local _, locationLevelMin, locationLevelMax, locationChampionPointsMin, locationChampionPointsMax, groupType, locationMinGroupSize = GetActivityInfo(activityId)
        local locationMaxGroupSize = GetGroupSizeFromLFGGroupType(groupType)

        if not minGroupSize or minGroupSize > locationMinGroupSize then
            minGroupSize = locationMinGroupSize
        end

        if not maxGroupSize or maxGroupSize < locationMaxGroupSize then
            maxGroupSize = locationMaxGroupSize
        end

        if not levelMin or levelMin > locationLevelMin then
            levelMin = locationLevelMin
        end

        if not levelMax or levelMax < locationLevelMax then
            levelMax = locationLevelMax
        end

        if not championPointsMin or championPointsMin > locationChampionPointsMin then
            championPointsMin = locationChampionPointsMin
        end

        if not championPointsMax or championPointsMax < locationChampionPointsMax then
            championPointsMax = locationChampionPointsMax
        end

        -- We only care if everything in this set is locked by a collectible,
        -- Otherwise collectbiles do not restrict the ability to queue for this set, just which activities you'll get matched for
        if not hasActivityWithNoCollectibleRestriction then
            local collectibleId = GetRequiredActivityCollectibleId(activityId)
            if collectibleId ~= 0 then
                table.insert(self.requiredCollectibles, collectibleId)
            else
                ZO_ClearNumericallyIndexedTable(self.requiredCollectibles)
                hasActivityWithNoCollectibleRestriction = true
            end
        end

        table.insert(self.activities, activityId)
    end

    local rawName, description, sortOrder = GetActivitySetInfo(activitySetId)
    local descriptionTextureSmallKeyboard, descriptionTextureLargeKeyboard = GetActivitySetKeyboardDescriptionTextures(activitySetId)
    local descriptionTextureGamepad = GetActivitySetGamepadDescriptionTexture(activitySetId)
    local forceFullPanelKeyboard = ShouldActivitySetForceFullPanelKeyboard(activitySetId)
    self.icon = GetActivitySetIcon(activitySetId)
    self.hasRewardData = DoesActivitySetHaveRewardData(activitySetId) 
    self.hasAvailabilityRequirementList = DoesActivitySetHaveAvailablityRequirementList(activitySetId)

    ZO_ActivityFinderLocation_Base.Initialize(self, activityType, activitySetId, rawName, description, levelMin, levelMax, championPointsMin, championPointsMax, minGroupSize, maxGroupSize, sortOrder, descriptionTextureSmallKeyboard, descriptionTextureLargeKeyboard, descriptionTextureGamepad, forceFullPanelKeyboard)
end

function ZO_ActivityFinderLocation_Set:InitializeFormattedNames()
    if self:GetActivityType() == LFG_ACTIVITY_BATTLE_GROUND_CHAMPION then
        self:SetNameKeyboard(zo_iconTextFormat(ZO_GetChampionPointsIcon(), "100%", "100%", self:GetRawName()))
        self:SetNameGamepad(zo_iconTextFormat(ZO_GetGamepadChampionPointsIcon(), "100%", "100%", self:GetRawName()))
    else
        ZO_ActivityFinderLocation_Base.InitializeFormattedNames(self)
    end
end

function ZO_ActivityFinderLocation_Set:AddActivitySearchEntry()
    AddActivityFinderSetSearchEntry(self:GetId())
end

function ZO_ActivityFinderLocation_Set:DoesPlayerMeetLevelRequirements()
    for _, activityId in ipairs(self.activities) do
        if DoesPlayerMeetActivityLevelRequirements(activityId) then
            return true
        end
    end

    return false
end

function ZO_ActivityFinderLocation_Set:DoesGroupMeetLevelRequirements()
    for _, activityId in ipairs(self.activities) do
        if DoesGroupMeetActivityLevelRequirements(activityId) then
            return true
        end
    end

    return false
end

function ZO_ActivityFinderLocation_Set:IsLockedByPlayerLocation()
    for _, activityId in ipairs(self.activities) do
        if IsActivityAvailableFromPlayerLocation(activityId) then
            return false
        end
    end

    return true
end

function ZO_ActivityFinderLocation_Set:IsLockedByCollectible()
    for _, collectibleId in ipairs(self.requiredCollectibles) do
        if IsCollectibleUnlocked(collectibleId) then
            -- Any unlocked collectible is enough to queue with a set
            return false
        end
    end
    return #self.requiredCollectibles ~= 0
end

function ZO_ActivityFinderLocation_Set:GetFirstLockingCollectible()
    for _, collectibleId in ipairs(self.requiredCollectibles) do
        if not IsCollectibleUnlocked(collectibleId) then
            return collectibleId
        end
    end

    return 0
end

function ZO_ActivityFinderLocation_Set:GetQuestToUnlock()
    local questId = GetActivityTypeGatingQuest(self.activityType)
    if questId ~= 0 and not HasCompletedQuest(questId) then
        return questId
    end
    return 0
end

function ZO_ActivityFinderLocation_Set:IsLockedByAvailablityRequirementList()
    if self.hasAvailabilityRequirementList then
        local isAvailable, errorStringId = DoesActivitySetPassAvailablityRequirementList(self:GetId())
        return not isAvailable, errorStringId
    end
    return false
end

function ZO_ActivityFinderLocation_Set:GetEntryType()
    return ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SET
end

function ZO_ActivityFinderLocation_Set:GetActivities()
    return self.activities
end

function ZO_ActivityFinderLocation_Set:HasRewardData()
    return self.hasRewardData
end

function ZO_ActivityFinderLocation_Set:GetRewardData()
    return GetActivitySetRewardData(self:GetId())
end

function ZO_ActivityFinderLocation_Set:HasMMR()
    return DoesActivitySetHaveMMR(self:GetId())
end

function ZO_ActivityFinderLocation_Set:GetMMR()
    return GetPlayerMMRByType(self:GetActivityType())
end

function ZO_ActivityFinderLocation_Set:IsEligibleForDailyReward()
    if self.hasRewardData then
        return IsActivityEligibleForDailyReward(self.activityType)
    end
    return false
end

function ZO_ActivityFinderLocation_Set:ShouldForceFullPanelKeyboard()
    return self.forceFullPanelKeyboard or self.hasRewardData
end

do
    local g_battlegroundTypes = {}
    local g_battlegroundTypeNames = {}

    local function GetBattlegroundSetTypesListText(setData)
        local activities = setData:GetActivities()
        ZO_ClearTable(g_battlegroundTypes)
        ZO_ClearNumericallyIndexedTable(g_battlegroundTypeNames)
        for _, activityId in ipairs(activities) do
            local battlegroundId = GetActivityBattlegroundId(activityId)
            local battlegroundGameType = GetBattlegroundGameType(battlegroundId)
            if battlegroundGameType ~= BATTLEGROUND_GAME_TYPE_NONE then
                if not g_battlegroundTypes[battlegroundGameType] then
                    g_battlegroundTypes[battlegroundGameType] = true
                    table.insert(g_battlegroundTypeNames, GetString("SI_BATTLEGROUNDGAMETYPE", battlegroundGameType))
                end
            end
        end

        return ZO_GenerateCommaSeparatedListWithoutAnd(g_battlegroundTypeNames)
    end

    local ACTIVITY_SET_TYPES_HEADERS =
    {
        [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = GetString(SI_BATTLEGROUND_FINDER_SET_TYPES_HEADER),
        [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = GetString(SI_BATTLEGROUND_FINDER_SET_TYPES_HEADER),
        [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = GetString(SI_BATTLEGROUND_FINDER_SET_TYPES_HEADER),
    }

    local ACTIVITY_SET_TYPES_LIST_BUILDERS =
    {
        [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = GetBattlegroundSetTypesListText,
        [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = GetBattlegroundSetTypesListText,
        [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = GetBattlegroundSetTypesListText,
    }

    function ZO_ActivityFinderLocation_Set:GetSetTypesHeaderText()
        return ACTIVITY_SET_TYPES_HEADERS[self:GetActivityType()] or ""
    end

    function ZO_ActivityFinderLocation_Set:GetSetTypesListText()
        local builderFunction = ACTIVITY_SET_TYPES_LIST_BUILDERS[self:GetActivityType()]
        return builderFunction and builderFunction(self) or ""
    end
end

function ZO_ActivityFinderLocation_Set:GetZoneId()
    return 0
end

function ZO_ActivityFinderLocation_Set:IsDisabled()
    return IsLFGActivitySetDisabled(self.id)
end
