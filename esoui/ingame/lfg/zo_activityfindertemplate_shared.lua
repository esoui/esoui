local MAX_ITEM_REWARDS = 3
ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_X = 20
ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_Y = 10

------------------
--Initialization--
------------------

ZO_ActivityFinderTemplate_Shared = ZO_Object:Subclass()

function ZO_ActivityFinderTemplate_Shared:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_ActivityFinderTemplate_Shared:Initialize(control, dataManager, categoryData, categoryPriority)
    self.control = control
    self.dataManager = dataManager
    self.categoryData = categoryData
    self.categoryPriority = categoryPriority
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
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnUpdateLocationData", function()
        self:RefreshView()
    end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", function(status) self:OnActivityFinderStatusUpdate(status) end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnHandleLFMPromptResponse", function() self:OnHandleLFMPromptResponse() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", function() self:RefreshFilters() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnCooldownsUpdate", function() self:OnCooldownsUpdate() end)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnCurrentCampaignChanged", function()
        self:RefreshFilters()
    end)
end

function ZO_ActivityFinderTemplate_Shared:InitializeSingularPanelControls(rewardsTemplate)
    local panel = self.control:GetNamedChild("SingularSection")

    self.backgroundTexture = panel:GetNamedChild("Background")
    self.titleLabel = panel:GetNamedChild("Title")
    self.descriptionLabel = panel:GetNamedChild("Description")
    self.setTypesSectionControl = panel:GetNamedChild("SetTypesSection")
    self.groupSizeRangeLabel = panel:GetNamedChild("GroupSizeLabel")
    
    local rewardsSection = panel:GetNamedChild("RewardsSection")
    self.rewardsHeader = rewardsSection:GetNamedChild("Header")
    local rewardsEntries = rewardsSection:GetNamedChild("Entries")
    self.rewardEntryPaddingControl = rewardsEntries:GetNamedChild("Padding")
    self.itemRewardControls = {}
    for i = 1, MAX_ITEM_REWARDS do
        local itemRewardControl = CreateControlFromVirtual("$(parent)ItemReward" .. i, rewardsEntries, "ZO_ActivityFinderTemplateRewardTemplate_Shared")
        ApplyTemplateToControl(itemRewardControl, rewardsTemplate)
        table.insert(self.itemRewardControls, itemRewardControl)
    end

    local xpRewardControl = rewardsEntries:GetNamedChild("XPReward")
    self.xpRewardLabel = xpRewardControl:GetNamedChild("Text")
    ApplyTemplateToControl(xpRewardControl, rewardsTemplate)
    self.xpRewardControl = xpRewardControl

    self.rewardsSection = rewardsSection
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
    local DAILY_HEADER = GetString(SI_ACTIVITY_FINDER_DAILY_REWARD_HEADER)
    local STANDARD_HEADER = GetString(SI_ACTIVITY_FINDER_STANDARD_REWARD_HEADER)

    local g_previousControl = nil
    local g_nextControlOnSameLine = false

    local function AnchorRewardControl(rewardControl)
        rewardControl:ClearAnchors()
        if g_previousControl then
            if g_nextControlOnSameLine then
                rewardControl:SetAnchor(LEFT, g_previousControl, RIGHT, ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_X, 0)
            else
                rewardControl:SetAnchor(TOPLEFT, g_previousControl, BOTTOMLEFT, 0, ZO_ACTIVITY_FINDER_REWARD_ENTRY_PADDING_Y)
            end
        else
            rewardControl:SetAnchor(TOPLEFT)
        end

        g_nextControlOnSameLine = not g_nextControlOnSameLine
        if g_nextControlOnSameLine then
            g_previousControl = rewardControl
        end
    end

    local g_rewardControlsToAnchor = {}

    function ZO_ActivityFinderTemplate_Shared:RefreshRewards(location)
        local currentSelectionHasRewardsData = location:HasRewardData()
        local hideRewards = true
        local description = ""
        if currentSelectionHasRewardsData then
            local rewardUIDataId, xpReward = location:GetRewardData()
            ZO_ClearNumericallyIndexedTable(g_rewardControlsToAnchor)

            local numShownItemRewardNodes = 0
            if rewardUIDataId ~= 0 then
                numShownItemRewardNodes = GetNumLFGActivityRewardUINodes(rewardUIDataId)

                assert(numShownItemRewardNodes <= MAX_ITEM_REWARDS) --If we've allowed for more nodes in the def, we haven't accounted for it in the UI

                for nodeIndex = 1, numShownItemRewardNodes do
                    local displayName, icon, textColorRed, textColorBlue, textColorGreen = GetLFGActivityRewardUINodeInfo(rewardUIDataId, nodeIndex)

                    local itemRewardControl = self.itemRewardControls[nodeIndex]
                    itemRewardControl.icon:SetTexture(icon)
                    itemRewardControl.text:SetText(displayName)
                    itemRewardControl.text:SetColor(textColorRed, textColorBlue, textColorGreen)
                    itemRewardControl:SetHidden(false)
                    table.insert(g_rewardControlsToAnchor, itemRewardControl)
                    hideRewards = false
                end

                description = GetLFGActivityRewardDescriptionOverride(rewardUIDataId)
            end

            for nodeIndex = numShownItemRewardNodes + 1, MAX_ITEM_REWARDS do
                self.itemRewardControls[nodeIndex]:SetHidden(true)
            end

            if xpReward > 0 then
                self.xpRewardLabel:SetText(zo_strformat(SI_ACTIVITY_FINDER_REWARD_XP_FORMAT, ZO_CommaDelimitNumber(xpReward)))
                self.xpRewardControl:SetHidden(false)
                local xpIndex = #g_rewardControlsToAnchor > 0 and 2 or 1 -- Design always wants XP to be the second thing in the left-to right/top to bottom grid (unless it's the only thing)
                table.insert(g_rewardControlsToAnchor, xpIndex, self.xpRewardControl)
                hideRewards = false
            else
                self.xpRewardControl:SetHidden(true)
            end
            
            g_previousControl = nil
            g_nextControlOnSameLine = false
            for _, control in ipairs(g_rewardControlsToAnchor) do
                AnchorRewardControl(control)
            end
        end

        if description == "" then
            description = location:GetDescription()
        end

        self.descriptionLabel:SetText(description)

        if hideRewards then
            self.rewardsSection:SetHidden(true)
        else
            self.rewardsHeader:SetText(location:IsEligibleForDailyReward() and DAILY_HEADER or STANDARD_HEADER)
            self.rewardsSection:SetHidden(false)
        end
    end
end

function ZO_ActivityFinderTemplate_Shared:GetLFMPromptInfo()
    local shouldShowLFMPrompt = false
    local lfmPromptActivityName
    if CanSendLFMRequest() then
        local activityId = GetCurrentLFGActivityId()
        local activityType = GetActivityType(activityId)
        local modes = self.dataManager:GetFilterModeData()
        if ZO_IsElementInNumericallyIndexedTable(modes:GetActivityTypes(), activityType) then
            shouldShowLFMPrompt = true
            lfmPromptActivityName = GetActivityName(activityId)
        end
    end
    return shouldShowLFMPrompt, lfmPromptActivityName
end

function ZO_ActivityFinderTemplate_Shared:GetLevelLockInfoByActivity(activityType)
    local isLevelLocked = false
    local lowestLevelLimit, highestLevelLimit, lowestChampionPointLimit, highestChampionPointLimit

    local maxLevel = GetMaxLevel()

    local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
    for _, location in ipairs(locationData) do
        local locationLevelMin = location:GetLevelMin()
        if locationLevelMin == maxLevel then --This is a veteran activity
            local locationChampionPointsMin = location:GetChampionPointsMin()
            local locationChampionPointsMax = location:GetChampionPointsMax()

            if not lowestChampionPointLimit or locationChampionPointsMin < lowestChampionPointLimit then
                lowestChampionPointLimit = locationChampionPointsMin
            end

            if not highestChampionPointLimit or locationChampionPointsMax > highestChampionPointLimit then
                highestChampionPointLimit = locationChampionPointsMax
            end
        else
            local locationLevelMax = location:GetLevelMax()

            if not lowestLevelLimit or locationLevelMin < lowestLevelLimit then
                lowestLevelLimit = locationLevelMin
            end

            if not highestLevelLimit or locationLevelMax > highestLevelLimit then
                highestLevelLimit = locationLevelMax
            end
        end
    end
    
    if lowestLevelLimit then
        local playerLevel = GetUnitLevel("player")
        if playerLevel < lowestLevelLimit or playerLevel > highestLevelLimit then
            isLevelLocked = true
        end
    elseif lowestChampionPointLimit then
        if not CanUnitGainChampionPoints("player") then
            isLevelLocked = true
        else
            local playerChampionPoints = GetPlayerChampionPointsEarned()
            if playerChampionPoints < lowestChampionPointLimit or playerChampionPoints > highestChampionPointLimit then
                isLevelLocked = true
            end
        end
    else
        -- No location data found for this activity type, so lock it down
        isLevelLocked = true
    end

    return isLevelLocked, lowestLevelLimit, lowestChampionPointLimit, highestLevelLimit, highestChampionPointLimit
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
        numLocations = numLocations + ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetNumLocationsByActivity(activityType, modes:GetVisibleEntryTypes())
    end

    return numLocations
end

function ZO_ActivityFinderTemplate_Shared:GetGlobalLockInfo()
    local isGloballyLocked = false
    local globalLockReasons =
    {
        isLockedByManager = self.dataManager:GetManagerLockInfo(),
        isLockedByNotLeader = ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLockedByNotLeader(),
        isActiveWorldBattleground = IsActiveWorldBattleground(),
    }

    for _, reason in pairs(globalLockReasons) do
        if reason == true then
            isGloballyLocked = true
            break
        end
    end

    return isGloballyLocked, globalLockReasons
end

function ZO_ActivityFinderTemplate_Shared:GetGlobalLockText()
    local isGloballyLocked, globalLockReasons = self:GetGlobalLockInfo()
    local lockReasonText
    if isGloballyLocked then
        if globalLockReasons.isActiveWorldBattleground then
            lockReasonText = GetString(SI_LFG_LOCK_REASON_IN_BATTLEGROUND)
        elseif globalLockReasons.isLockedByManager then
            lockReasonText = self.dataManager:GetManagerLockText()
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

function ZO_ActivityFinderTemplate_Shared.AppendSetDataToControl(setTypesSectionControl, setData)
    local hideControls = true
    local setTypesHeader = setTypesSectionControl:GetNamedChild("Header")
    local setTypesList = setTypesSectionControl:GetNamedChild("List")

    if setData:IsSetEntryType() then
        local setTypesHeaderText = setData:GetSetTypesHeaderText()
        local setTypesListText = setData:GetSetTypesListText()
        if setTypesHeaderText ~= "" and setTypesListText ~= "" then
            setTypesHeader:SetText(setTypesHeaderText)
            setTypesList:SetText(setTypesListText)
            hideControls = false
        end
    end

    setTypesHeader:SetHidden(hideControls)
    setTypesList:SetHidden(hideControls)
end