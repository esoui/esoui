local LevelUpRewardData = ZO_RewardData:Subclass()

function LevelUpRewardData:New(...)
    return ZO_RewardData.New(self, ...)
end

function LevelUpRewardData:SetIsAttributePoint()
    self.isAttributePoint = true
end

function LevelUpRewardData:SetIsSkillPoint()
    self.isSkillPoint = true
end

function LevelUpRewardData:SetIsAdditionalUnlock(description)
    self.isAdditionalUnlock = true
    self.description = description
end

function LevelUpRewardData:IsAttributePoint()
    return self.isAttributePoint
end

function LevelUpRewardData:IsSkillPoint()
    return self.isSkillPoint
end

function LevelUpRewardData:IsAdditionalUnlock()
    return self.isAdditionalUnlock
end

function LevelUpRewardData:GetDescription()
    return self.description
end

-----------------------------
-- Level Up Rewards Manager
-----------------------------

local LevelUpRewardsManager = ZO_CallbackObject:Subclass()

function LevelUpRewardsManager:New(...)
    local obj = ZO_CallbackObject.New(self)
    obj:Initialize(...)
    return obj
end

function LevelUpRewardsManager:Initialize()
    self:RegisterForEvents()
end

function LevelUpRewardsManager:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent("LevelUpRewardsManager", EVENT_LEVEL_UP_REWARD_UPDATED, function(eventCode) self:OnLevelUpRewardsUpdated() end)
    EVENT_MANAGER:RegisterForEvent("LevelUpRewardsManager", EVENT_LEVEL_UP_REWARD_CHOICE_UPDATED, function(eventCode) self:OnLevelUpRewardsChoiceUpdated() end)
    local function OnPlayerActivated()
        self:UpdatePendingLevelUpRewards()
    end
    EVENT_MANAGER:RegisterForEvent("LevelUpRewardsManager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function LevelUpRewardsManager:OnLevelUpRewardsUpdated()
    self:UpdatePendingLevelUpRewards()

    self:FireCallbacks("OnLevelUpRewardsUpdated")
end

function LevelUpRewardsManager:OnLevelUpRewardsChoiceUpdated()
    for index, entryInfo in ipairs(self.pendingLevelUpRewards) do
        if entryInfo.choices then
            for choiceIndex, choiceEntryInfo in ipairs(entryInfo.choices) do
                choiceEntryInfo.isSelectedChoice = IsLevelUpRewardChoiceSelected(entryInfo.rewardId, choiceEntryInfo.rewardId)
            end
        end
    end

    self:FireCallbacks("OnLevelUpRewardsChoiceUpdated")
end

function LevelUpRewardsManager:UpdatePendingLevelUpRewards()
    local NO_PARENT_CHOICE = nil
    self.pendingRewardLevel = GetPendingLevelUpRewardLevel()
    if self.pendingRewardLevel then
        local numRewards = GetNumRewardsForLevel(self.pendingRewardLevel)
        self.pendingLevelUpRewards = {}
        for rewardIndex = 1, numRewards do
            local rewardId, quantity = GetRewardInfoForLevel(self.pendingRewardLevel, rewardIndex)
            local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, quantity, NO_PARENT_CHOICE, IsLevelUpRewardValidForPlayer, IsLevelUpRewardChoiceSelected)
            table.insert(self.pendingLevelUpRewards, rewardData)
        end
        self:GetAdditionalUnlocksForLevel(self.pendingRewardLevel, self.pendingLevelUpRewards)
        table.sort(self.pendingLevelUpRewards, function(...) return self:SortRewardAndAdditionalUnlockEntries(...) end)
    else
        self.pendingLevelUpRewards = nil
    end

    self.upcomingRewardLevel = GetUpcomingLevelUpRewardLevel()
    if self.upcomingRewardLevel then
        local numRewards = GetNumRewardsForLevel(self.upcomingRewardLevel)
        self.upcomingLevelUpRewards = {}
        for rewardIndex = 1, numRewards do
            local rewardId, quantity = GetRewardInfoForLevel(self.upcomingRewardLevel, rewardIndex)
            local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, quantity, NO_PARENT_CHOICE, IsLevelUpRewardValidForPlayer, IsLevelUpRewardChoiceSelected)
            table.insert(self.upcomingLevelUpRewards, rewardData)
        end
        self:GetAdditionalUnlocksForLevel(self.upcomingRewardLevel, self.upcomingLevelUpRewards)
        table.sort(self.upcomingLevelUpRewards, function(...) return self:SortRewardAndAdditionalUnlockEntries(...) end)
    else
        self.upcomingLevelUpRewards = nil
    end

    local nextMilestoneRewardLevel = GetNextLevelUpRewardMilestoneLevel()
    if nextMilestoneRewardLevel and nextMilestoneRewardLevel ~= self.upcomingRewardLevel then
        self.upcomingMilestoneRewardLevel = nextMilestoneRewardLevel
        local numRewards = GetNumRewardsForLevel(self.upcomingMilestoneRewardLevel)
        self.upcomingMilestoneLevelUpRewards = {}
        for rewardIndex = 1, numRewards do
            local rewardId, quantity = GetRewardInfoForLevel(self.upcomingMilestoneRewardLevel, rewardIndex)
            local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, quantity, NO_PARENT_CHOICE, IsLevelUpRewardValidForPlayer, IsLevelUpRewardChoiceSelected)
            table.insert(self.upcomingMilestoneLevelUpRewards, rewardData)
        end
        self:GetAdditionalUnlocksForLevel(self.upcomingMilestoneRewardLevel, self.upcomingMilestoneLevelUpRewards)
        table.sort(self.upcomingMilestoneLevelUpRewards, function(...) return self:SortRewardAndAdditionalUnlockEntries(...) end)
    else
        self.upcomingMilestoneRewardLevel = nil
        self.upcomingMilestoneLevelUpRewards = nil
    end
end

function LevelUpRewardsManager:GetPendingRewardLevel()
    return self.pendingRewardLevel
end

function LevelUpRewardsManager:GetPendingLevelUpRewards()
    return self.pendingLevelUpRewards
end

function LevelUpRewardsManager:GetUpcomingRewardLevel()
    return self.upcomingRewardLevel
end

function LevelUpRewardsManager:GetUpcomingLevelUpRewards()
    return self.upcomingLevelUpRewards
end

function LevelUpRewardsManager:GetUpcomingMilestoneRewardLevel()
    return self.upcomingMilestoneRewardLevel
end

function LevelUpRewardsManager:GetUpcomingMilestoneLevelUpRewards()
    return self.upcomingMilestoneLevelUpRewards
end

function LevelUpRewardsManager:GetAdditionalUnlocksForLevel(level, rewardInfoTable)
    local additionalUnlocks = rewardInfoTable or {}
    local numAdditionalUnlocks = GetNumAdditionalLevelUpUnlocks(level)

    for index = 1, numAdditionalUnlocks do
        local formattedDisplayName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetAdditionalLevelUpUnlockDisplayName(level, index))
        local additionalReward = LevelUpRewardData:New()
        additionalReward:SetFormattedName(formattedDisplayName)
        additionalReward:SetIcon(GetAdditionalLevelUpUnlockKeyboardIcon(level, index), GetAdditionalLevelUpUnlockGamepadIcon(level, index))
        additionalReward:SetIsAdditionalUnlock(GetAdditionalLevelUpUnlockDescription(level, index))
        table.insert(additionalUnlocks, additionalReward)
    end

    return additionalUnlocks
end

function LevelUpRewardsManager:GetPlatformAttributePointIcon()
        return "EsoUI/Art/LevelUpRewards/levelup_attribute_64.dds"
    end

function LevelUpRewardsManager:GetPlatformSkillPointIcon()
        return "EsoUI/Art/LevelUpRewards/levelup_skillpt_64.dds"
    end

function LevelUpRewardsManager:GetAttributePointEntryInfo(attributePoints)
    local attributeReward = LevelUpRewardData:New()
    attributeReward:SetFormattedName(zo_strformat(SI_LEVEL_UP_REWARDS_ATTRIBUTE_POINTS_ENTRY_FORMATTER, ZO_SELECTED_TEXT:Colorize(attributePoints)))
    attributeReward:SetIcon(self:GetPlatformAttributePointIcon())
    attributeReward:SetIsAttributePoint()

    return attributeReward
end

function LevelUpRewardsManager:GetSkillPointEntryInfo(skillPoints)
    local skillPointReward = LevelUpRewardData:New()
    skillPointReward:SetFormattedName(zo_strformat(SI_LEVEL_UP_REWARDS_SKILL_POINTS_ENTRY_FORMATTER, ZO_SELECTED_TEXT:Colorize(skillPoints)))
    skillPointReward:SetIcon(self:GetPlatformSkillPointIcon())
    skillPointReward:SetIsSkillPoint()

    return skillPointReward
end

function LevelUpRewardsManager:GetPlatformFormattedStackNameFromRewardData(rewardData)
    if IsInGamepadPreferredMode() then
        return rewardData:GetFormattedNameWithStackGamepad()
    else
        return rewardData:GetFormattedNameWithStack()
    end
end

function LevelUpRewardsManager:GetPendingRewardNameFromRewardData(rewardData)
    local name = rewardData:GetFormattedName()
    if not IsInGamepadPreferredMode() then
        if rewardData.rewardType and rewardData.rewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
            name = self:GetPlatformFormattedStackNameFromRewardData(rewardData)
        end
    end
    return name
end

function LevelUpRewardsManager:GetUpcomingRewardNameFromRewardData(rewardData)
    local name = self:GetPlatformFormattedStackNameFromRewardData(rewardData)

    if name == nil then
        name = rewardData:GetFormattedName()
    end
    return name
end

function LevelUpRewardsManager:SortRewardAndAdditionalUnlockEntries(data1, data2)
    -- entries with choices sort to the end
    local data1Choices = data1.choices
    local data2Choices = data2.choices

    if data1Choices ~= nil and data2Choices ~= nil then
        if #data1Choices ~= #data2Choices then
            return #data1Choices < #data2Choices
        end
    elseif data1Choices ~= data2Choices then
        return data1Choices == nil
    end

    if data1.isAdditionalUnlock ~= data2.isAdditionalUnlock then
        return not data1.isAdditionalUnlock
    elseif data1.isAdditionalUnlock then
        return data1.formattedName < data2.formattedName
    end

    return data1.rewardId < data2.rewardId
end

do
    local QuickBendEasing = ZO_GenerateCubicBezierEase(0.38, 0.21, 0.75, 0.24)
    local LateBendEasing = ZO_GenerateCubicBezierEase(0.38, 0.21, 0.84, 0.24)
    local sparkStartColorGenerator = ZO_WeightedChoiceGenerator:New(
        {0.7, 0.7, 0.4}, 0.1,
        {0.8, 0.3, 0.3}, 0.3,
        {1.0, 1.0, 0.0}, 0.3,
        {1.0, 0.5, 0.0}, 0.3)
        
    function LevelUpRewardsManager:CreateArtAreaParticleSystem(artControl)
        local halfArtWidth = artControl:GetWidth() * 0.5
        local artHeight = artControl:GetHeight()
        local halfArtHeight = artHeight * 0.5
        local particleSystem = ZO_ControlParticleSystem:New(ZO_BentArcParticle_Control)
        particleSystem:SetParentControl(artControl)
        particleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
        particleSystem:SetParticleParameter("BentArcElevationStartRadians", ZO_UniformRangeGenerator:New(0.3 * math.pi, 0.7 *math.pi))
        particleSystem:SetParticleParameter("BentArcElevationChangeRadians", ZO_UniformRangeGenerator:New(-0.8, 0.8))
        particleSystem:SetParticleParameter("BentArcAzimuthStartRadians", 0)
        particleSystem:SetParticleParameter("BentArcAzimuthChangeRadians", 0)
        particleSystem:SetParticleParameter("BentArcFinalMagnitude", artHeight * 1.3)
        particleSystem:SetParticleParameter("Size", 8)
        particleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1.1, 1.4))
        particleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(0.7, 1))
        particleSystem:SetParticleParameter("DurationS", 0.8)
        particleSystem:SetParticleParameter("StartAlpha", 0.4)
        particleSystem:SetParticleParameter("EndAlpha", 0.0)
        particleSystem:SetParticleParameter("StartColorR", "StartColorG", "StartColorB", sparkStartColorGenerator)
        particleSystem:SetParticleParameter("EndColorR", 0.6)
        particleSystem:SetParticleParameter("EndColorG", 0.6)
        particleSystem:SetParticleParameter("EndColorB", 1)
        particleSystem:SetParticleParameter("BentArcBendEasing", ZO_WeightedChoiceGenerator:New(QuickBendEasing, 0.4, LateBendEasing, 0.6))
        particleSystem:SetParticleParameter("StartOffsetX", "EndOffsetX", ZO_UniformRangeGenerator:New(-halfArtWidth, halfArtWidth, -halfArtWidth, halfArtWidth))
        particleSystem:SetParticleParameter("StartOffsetY", halfArtHeight)
        particleSystem:SetParticleParameter("EndOffsetY", halfArtHeight)
        particleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
        return particleSystem
    end
end

ZO_LEVEL_UP_REWARDS_MANAGER = LevelUpRewardsManager:New()
