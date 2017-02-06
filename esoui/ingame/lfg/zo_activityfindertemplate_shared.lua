ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING = 20

------------------
--Initialization--
------------------

ZO_ActivityFinderTemplate_Shared = ZO_Object:Subclass()

function ZO_ActivityFinderTemplate_Shared:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_ActivityFinderTemplate_Shared:Initialize(control, dataManager, categoryData)
    self.control = control
    self.dataManager = dataManager
    self.categoryData = categoryData
    self.categoryData.activityFinderObject = self

    self:InitializeControls()
    self:RegisterEvents()
end

function ZO_ActivityFinderTemplate_Shared:InitializeControls(rewardsTemplate)
    self:InitializeSingularPanelControls(rewardsTemplate)
    self:InitializeFragment()
    self:InitializeFilters()
end

function ZO_ActivityFinderTemplate_Shared:InitializeFilters()
    --Meant to be overriden
end

function ZO_ActivityFinderTemplate_Shared:InitializeFragment()
    --Meant to be overriden
end

function ZO_ActivityFinderTemplate_Shared:RegisterEvents()
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnUpdateLocationData", function() self:RefreshView() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", function(status) self:OnActivityFinderStatusUpdate(status) end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnHandleLFMPromptResponse", function() self:OnHandleLFMPromptResponse() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", function() self:RefreshFilters() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnCooldownsUpdate", function() self:OnCooldownsUpdate() end)
end

function ZO_ActivityFinderTemplate_Shared:InitializeSingularPanelControls(rewardsTemplate)
    local panel = self.control:GetNamedChild("SingularSection")

    self.backgroundTexture = panel:GetNamedChild("Background")
    self.titleLabel = panel:GetNamedChild("Title")
    self.descriptionLabel = panel:GetNamedChild("Description")
    self.groupSizeRangeLabel = panel:GetNamedChild("GroupSizeLabel")
    
    local rewardsSection = panel:GetNamedChild("RewardsSection")
    self.rewardsHeader = rewardsSection:GetNamedChild("Header")
    local rewardsEntries = rewardsSection:GetNamedChild("Entries")
    self.rewardEntryPaddingControl = rewardsEntries:GetNamedChild("Padding")
    local itemRewardControl = rewardsEntries:GetNamedChild("ItemReward")
    local xpRewardControl = rewardsEntries:GetNamedChild("XPReward")

    ApplyTemplateToControl(itemRewardControl, rewardsTemplate)
    ApplyTemplateToControl(xpRewardControl, rewardsTemplate)
    self.itemRewardLabel = itemRewardControl:GetNamedChild("Text")
    self.itemRewardIcon = itemRewardControl:GetNamedChild("Icon")
    self.xpRewardLabel = xpRewardControl:GetNamedChild("Text")
    self.xpRewardIcon = xpRewardControl:GetNamedChild("Icon")
    self.xpRewardLabel:SetText(zo_strformat(SI_ACTIVITY_FINDER_RANDOM_REWARD_XP_FORMAT, ZO_CommaDelimitNumber(0))) --TODO: Implement XP reward hook
    self.itemRewardControl = itemRewardControl
    self.xpRewardControl = xpRewardControl

    self.singularSection = panel
end

function ZO_ActivityFinderTemplate_Shared:RefreshView()
    assert(false) --Must override
end

function ZO_ActivityFinderTemplate_Shared:RefreshFilters()
    assert(false) --Must override
end

function ZO_ActivityFinderTemplate_Shared:OnActivityFinderStatusUpdate(status)
    assert(false) --Must override
end

function ZO_ActivityFinderTemplate_Shared:OnHandleLFMPromptResponse()
    --Can be overriden
end

function ZO_ActivityFinderTemplate_Shared:OnCooldownsUpdate()
    assert(false) --Must override
end

do
    local ITEM_REWARD_COLOR_MAP =
    {
        [LFG_ITEM_REWARD_TYPE_STANDARD] = GetItemQualityColor(ITEM_QUALITY_MAGIC),
        [LFG_ITEM_REWARD_TYPE_DAILY] = GetItemQualityColor(ITEM_QUALITY_ARCANE),
    }

    local DAILY_HEADER = GetString(SI_ACTIVITY_FINDER_RANDOM_DAILY_REWARD_HEADER)
    local STANDARD_HEADER = GetString(SI_ACTIVITY_FINDER_RANDOM_STANDARD_REWARD_HEADER)

    function ZO_ActivityFinderTemplate_Shared:RefreshRewards(currentSelectionIsRandom, activityType)
        local hideItemReward = true
        local hideXPReward = true
        if currentSelectionIsRandom then
            local itemRewardType, xpReward = GetLFGActivityRewardData(activityType)
            if itemRewardType ~= LFG_ITEM_REWARD_TYPE_NONE then
                self.itemRewardLabel:SetText(GetString("SI_LFGITEMREWARDTYPE", itemRewardType))
                self.itemRewardLabel:SetColor(ITEM_REWARD_COLOR_MAP[itemRewardType]:UnpackRGBA())
                hideItemReward = false
            end

            if xpReward > 0 then
                self.xpRewardLabel:SetText(zo_strformat(SI_ACTIVITY_FINDER_RANDOM_REWARD_XP_FORMAT, ZO_CommaDelimitNumber(xpReward)))
                hideXPReward = false
            end
        end

        self.itemRewardLabel:SetHidden(hideItemReward)
        self.itemRewardIcon:SetHidden(hideItemReward)
        self.rewardEntryPaddingControl:SetWidth(hideItemReward and 0 or ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING)
        self.xpRewardLabel:SetHidden(hideXPReward)
        self.xpRewardIcon:SetHidden(hideXPReward)
        if hideItemReward and hideXpReward then
            self.rewardsHeader:SetHidden(true)
        else
            self.rewardsHeader:SetText(IsEligibleForDailyActivityReward() and DAILY_HEADER or STANDARD_HEADER)
            self.rewardsHeader:SetHidden(false)
        end
        self.rewardsHeader:SetHidden(hideItemReward and hideXPReward)
    end
end

function ZO_ActivityFinderTemplate_Shared.SetGroupSizeRangeText(labelControl, entryData, groupIconFormat)
    if entryData.minGroupSize ~= entryData.maxGroupSize then
        labelControl:SetText(zo_strformat(SI_ACTIVITY_FINDER_GROUP_SIZE_RANGE_FORMAT, entryData.minGroupSize, entryData.maxGroupSize, groupIconFormat))
    else
        labelControl:SetText(zo_strformat(SI_ACTIVITY_FINDER_GROUP_SIZE_SIMPLE_FORMAT, entryData.minGroupSize, groupIconFormat))
    end
end

function ZO_ActivityFinderTemplate_Shared:GetLFMPromptInfo()
    local shouldShowLFMPrompt = false
    local lfmPromptActivityName
    if CanSendLFMRequest() then
        local activityType, activityIndex = GetCurrentLFGActivity()
        local modes = self.dataManager:GetFilterModeData()
        if ZO_IsElementInNumericallyIndexedTable(modes:GetActivityTypes(), activityType) then
            shouldShowLFMPrompt = true
            lfmPromptActivityName = GetLFGOption(activityType, activityIndex)
        end
    end
    return shouldShowLFMPrompt, lfmPromptActivityName
end

function ZO_ActivityFinderTemplate_Shared:GetLevelLockInfoByActivity(activityType)
    local isLevelLocked = false
    local lowestLevelLimit, lowestChampionPointLimit

    local maxLevel = GetMaxLevel()

    local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
    for _, location in ipairs(locationData) do
        if location.levelMin == maxLevel then --This is a veteran activity
            if not lowestChampionPointLimit or location.championPointsMin < lowestChampionPointLimit then
                lowestChampionPointLimit = location.championPointsMin
            end
        else
            if not lowestLevelLimit or location.levelMin < lowestLevelLimit then
                lowestLevelLimit = location.levelMin
            end
        end
    end
    
    if lowestLevelLimit then
        if GetUnitLevel("player") < lowestLevelLimit  then
            isLevelLocked = true
        end
    elseif lowestChampionPointLimit then
        if not CanUnitGainChampionPoints("player") or GetPlayerChampionPointsEarned() < lowestChampionPointLimit then
            isLevelLocked = true
        end
    end

    return isLevelLocked, lowestLevelLimit, lowestChampionPointLimit
end

function ZO_ActivityFinderTemplate_Shared:GetLevelLockInfo()
    local isLevelLocked = true
    local lowestLevelLimit, lowestChampionPointLimit

    local modes = self.dataManager:GetFilterModeData()
    for _, activityType in ipairs(modes:GetActivityTypes()) do
        local locked, level, championPoints = self:GetLevelLockInfoByActivity(activityType)
        if level and (not lowestLevelLimit or level < lowestLevelLimit) then
            lowestLevelLimit = level
        end

        if championPoints and (not lowestChampionPointLimit or championPoints < lowestChampionPointLimit) then
            lowestChampionPointLimit = championPoints
        end

        if not locked then
            isLevelLocked = false
        end
    end

    return isLevelLocked, lowestLevelLimit, lowestChampionPointLimit
end

function ZO_ActivityFinderTemplate_Shared:GetNumLocations()
    local numLocations = 0

    local modes = self.dataManager:GetFilterModeData()
    for _, activityType in ipairs(modes:GetActivityTypes()) do
        numLocations = numLocations + ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetNumLocationsByActivity(activityType)
    end

    return numLocations
end

function ZO_ActivityFinderTemplate_Shared:GetGlobalLockInfo()
    local isGloballyLocked = false
    local globalLockReasons =
    {
        isActivityQueueOnCooldown = ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsActivityQueueOnCooldown(),
        isLockedByNotLeader = ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLockedByNotLeader(),
    }

    for i, reason in pairs(globalLockReasons) do
        if reason == true then
            isGloballyLocked = true
            break
        end
    end

    return isGloballyLocked, globalLockReasons
end

local function ActivityQueueCooldownTextCallback()
    local expireTimeS = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetActivityQueueCooldownExpireTimeS()
    local timeRemainingS = zo_max(expireTimeS - GetFrameTimeSeconds(), 0)
    local formattedTimeText = ZO_FormatTime(timeRemainingS, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
    return zo_strformat(SI_LFG_LOCK_REASON_QUEUE_COOLDOWN_VERBOSE, formattedTimeText)
end

function ZO_ActivityFinderTemplate_Shared:GetGlobalLockText()
    local isGloballyLocked, globalLockReasons = self:GetGlobalLockInfo()
    local lockReasonText
    if isGloballyLocked then
        if globalLockReasons.isActivityQueueOnCooldown then
            lockReasonText = ActivityQueueCooldownTextCallback
        elseif globalLockReasons.isLockedByNotLeader then
            lockReasonText = GetString(SI_ACTIVITY_FINDER_LOCKED_NOT_LEADER_TEXT)
        end
    end
    return lockReasonText
end

function ZO_ActivityFinderTemplate_Shared:GetLevelLockTextByActivity(activityType)
    local isLocked, levelMin, championPointsMin = self:GetLevelLockInfoByActivity(activityType)
    local lockReasonText
    if isLocked then
        if levelMin then
            lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_LEVEL_REQUIREMENT, levelMin)
        elseif championPointsMin then
            lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_CHAMPION_REQUIREMENT, championPointsMin)
        end
    end
    return lockReasonText
end

function ZO_ActivityFinderTemplate_Shared:GetLockTextByActivity(activityType)
    local lockText = self:GetGlobalLockText()
    if not lockText then
        lockText = self:GetLevelLockTextByActivity(activityType)
    end
    return lockText
end