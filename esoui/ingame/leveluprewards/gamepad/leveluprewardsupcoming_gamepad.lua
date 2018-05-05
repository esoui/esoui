ZO_LevelUpRewardsUpcoming_Gamepad = ZO_LevelUpRewardsUpcoming_Base:Subclass()

function ZO_LevelUpRewardsUpcoming_Gamepad:New(...)
    return ZO_LevelUpRewardsUpcoming_Base.New(self, ...)
end

function ZO_LevelUpRewardsUpcoming_Gamepad:Initialize(control)
    ZO_LevelUpRewardsUpcoming_Base.Initialize(self, control, "ZO_UpcomingLevelUpRewards_GamepadRewardEntry")

    ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT:RegisterCallback("StateChange",
                                                function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        self:OnShowing()
                                                    end
                                                end)
end

function ZO_LevelUpRewardsUpcoming_Gamepad:OnShowing()
    self:LayoutUpcomingRewards()
end

function ZO_LevelUpRewardsUpcoming_Gamepad:LayoutReward(data, rewardContainer, previousControl)
    local rewardControl = self:AcquireRewardControl()
    local icon = data:GetGamepadIcon()
    if icon then
        rewardControl.iconControl:SetTexture(icon)
        rewardControl.iconControl:SetHidden(false)
    else
        rewardControl.iconControl:SetHidden(true)
    end

    local name = ZO_LEVEL_UP_REWARDS_MANAGER:GetUpcomingRewardNameFromRewardData(data)
    rewardControl.nameControl:SetText(name)
    local rewardType = data:GetRewardType()
    if rewardType then
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data:GetItemQuality())
        rewardControl.nameControl:SetColor(r, g, b, 1)
    else
        local r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
        rewardControl.nameControl:SetColor(r, g, b, 1)
    end

    rewardControl:SetParent(rewardContainer.rewardsContainer)
    if previousControl then
        rewardControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 5)
    else
        rewardControl:SetAnchor(TOPLEFT, rewardContainer.rewardsContainer, TOPLEFT, 0, 10)
    end
    return rewardControl
end

function ZO_LevelUpRewardsUpcoming_Gamepad:LayoutRewardsForLevel(level, levelRewards, rewardContainer)
    ZO_LevelUpRewardsUpcoming_Base.LayoutRewardsForLevel(self, level, levelRewards, rewardContainer)

    local previousControl = nil

    local attributePoints = GetAttributePointsAwardedForLevel(level)
    if attributePoints > 0 then
        local attributeData = ZO_LEVEL_UP_REWARDS_MANAGER:GetAttributePointEntryInfo(attributePoints)
        local attributeControl = self:LayoutReward(attributeData, rewardContainer, previousControl)
        previousControl = attributeControl
    end

    local skillPoints = GetSkillPointsAwardedForLevel(level)
    if skillPoints > 0 then
        local skillPointData = ZO_LEVEL_UP_REWARDS_MANAGER:GetSkillPointEntryInfo(skillPoints)
        local skillControl = self:LayoutReward(skillPointData, rewardContainer, previousControl)
        previousControl = skillControl
    end

    for i, reward in ipairs(levelRewards) do
        if reward:IsValidReward() then
            local rewardControl = self:LayoutReward(reward, rewardContainer, previousControl)
            previousControl = rewardControl
        end
    end
end

function ZO_LevelUpRewardsUpcoming_Gamepad:Show()
    if not self:IsShowing() then
        SCENE_MANAGER:AddFragment(ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT)
        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
    end
end

function ZO_LevelUpRewardsUpcoming_Gamepad:Hide()
    if self:IsShowing() then
        SCENE_MANAGER:RemoveFragment(ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)

        self:ReleaseAllRewardControls()
    end
end

function ZO_LevelUpRewardsUpcoming_Gamepad:IsShowing()
    return ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT:IsShowing()
end

--
--[[ XML Handlers ]]--
--

function ZO_LevelUpRewardsUpcoming_Gamepad_OnInitialized(control)
    ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS = ZO_LevelUpRewardsUpcoming_Gamepad:New(control)
end
