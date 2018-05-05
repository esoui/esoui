ZO_UPCOMING_LEVEL_UP_REWARDS_KEYBOARD_REWARD_ROW_HEIGHT = 40
ZO_UPCOMING_LEVEL_UP_REWARDS_KEYBOARD_REWARD_CONTAINER_SPACING = 20

ZO_UPCOMING_LEVEL_UP_REWARDS_KEYBOARD_SHOW_DURATION_MS = 1250

--The static part of the window (everything not including reward entries)
local WINDOW_HEIGHT_WITHOUT_DYNAMIC_CONTROLS = 380

ZO_LevelUpRewardsUpcoming_Keyboard = ZO_LevelUpRewardsUpcoming_Base:Subclass()

function ZO_LevelUpRewardsUpcoming_Keyboard:New(...)
    return ZO_LevelUpRewardsUpcoming_Base.New(self, ...)
end

function ZO_LevelUpRewardsUpcoming_Keyboard:Initialize(control)
    ZO_LevelUpRewardsUpcoming_Base.Initialize(self, control, "ZO_LevelUpRewards_UpcomingRewardRow")

    self.rewardContainerToLayout = {}

    self.fadeInContentsAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_UpcomingLevelUpRewardsFadeInContentsAnimation", self.scrollContainer)

    ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT:RegisterCallback("StateChange",
                                                function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        self:OnShowing()
                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                        self:OnHidden()
                                                    end
                                                end)
end

function ZO_LevelUpRewardsUpcoming_Keyboard:OnShowing()
    self:LayoutUpcomingRewards()
end

function ZO_LevelUpRewardsUpcoming_Keyboard:OnHidden()
    self:ReleaseAllRewardControls()
    self.fadeInContentsAnimationTimeline:Stop()
end

function ZO_LevelUpRewardsUpcoming_Keyboard:PlayFadeInContentsAnimation()
    self.fadeInContentsAnimationTimeline:PlayFromStart()
end

function ZO_LevelUpRewardsUpcoming_Keyboard:LayoutReward(rewardControl, data)
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

    local icon = data:GetKeyboardIcon()
    if icon then
        rewardControl.iconControl:SetTexture(icon)
        rewardControl.iconControl:SetHidden(false)
    else
        rewardControl.iconControl:SetHidden(true)
    end

    rewardControl.data = data
end

function ZO_LevelUpRewardsUpcoming_Keyboard:LayoutRewardsForLevel(level, levelRewards, rewardContainer)
    ZO_LevelUpRewardsUpcoming_Base.LayoutRewardsForLevel(self, level, levelRewards, rewardContainer)

    local layout = self.rewardContainerToLayout[rewardContainer]
    if not layout then
        layout = ZO_LevelUpRewardsLayout_Keyboard:New()
        self.rewardContainerToLayout[rewardContainer] = layout
    end

    local ANCHOR_TO_PARENT = nil
    layout:ResetAnchoring(ANCHOR_TO_PARENT)
    layout:StartSection()

    local attributePoints = GetAttributePointsAwardedForLevel(level)
    if attributePoints > 0 then
        local rewardControl = self:AcquireRewardControl()
        rewardControl:SetParent(rewardContainer.rewardsContainer)
        local attributeData = ZO_LEVEL_UP_REWARDS_MANAGER:GetAttributePointEntryInfo(attributePoints)
        self:LayoutReward(rewardControl, attributeData)
        layout:Anchor(rewardControl)
    end

    local skillPoints = GetSkillPointsAwardedForLevel(level)
    if skillPoints > 0 then
        local rewardControl = self:AcquireRewardControl()
        rewardControl:SetParent(rewardContainer.rewardsContainer)
        local skillPointData = ZO_LEVEL_UP_REWARDS_MANAGER:GetSkillPointEntryInfo(skillPoints)
        self:LayoutReward(rewardControl, skillPointData)
        layout:Anchor(rewardControl)
    end

    for i, rewardData in ipairs(levelRewards) do
        if rewardData:IsValidReward() then
            local rewardControl = self:AcquireRewardControl()
            rewardControl:SetParent(rewardContainer.rewardsContainer)
            self:LayoutReward(rewardControl, rewardData)
            layout:Anchor(rewardControl)
        end
    end
end

function ZO_LevelUpRewardsUpcoming_Keyboard:LayoutUpcomingRewards()
    ZO_LevelUpRewardsUpcoming_Base.LayoutUpcomingRewards(self)

    local totalDynamicHeight = 0
    for rewardContainer, layout in pairs(self.rewardContainerToLayout) do
        if not rewardContainer:IsControlHidden() then
            totalDynamicHeight = totalDynamicHeight + layout:GetTotalHeight()
        end
    end

    local staticHeight = WINDOW_HEIGHT_WITHOUT_DYNAMIC_CONTROLS
    if self.nextMilestoneContainer:IsControlHidden() then
        staticHeight = staticHeight - self.nextMilestoneContainer.frameTexture:GetHeight() - ZO_UPCOMING_LEVEL_UP_REWARDS_KEYBOARD_REWARD_CONTAINER_SPACING - ZO_LEVEL_UP_REWARDS_ART_REWARDS_SPACING
    end

    self.control:SetHeight(zo_min(staticHeight + totalDynamicHeight, ZO_LEVEL_UP_REWARDS_KEYBOARD_MAX_SCREEN_HEIGHT))
end

function ZO_LevelUpRewardsUpcoming_Keyboard:Show(fadeInContents)
    if not self:IsShowing() then
        SCENE_MANAGER:AddFragment(ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT)
        if fadeInContents then
            self:PlayFadeInContentsAnimation()
        end
    end
end

function ZO_LevelUpRewardsUpcoming_Keyboard:Hide()
    if self:IsShowing() then
        SCENE_MANAGER:RemoveFragment(ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT)
    end
end

function ZO_LevelUpRewardsUpcoming_Keyboard:IsShowing()
    return ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS_FRAGMENT:IsShowing()
end

--
--[[ XML Handlers ]]--
--

function ZO_LevelUpRewardsUpcoming_Keyboard_OnInitialized(control)
    ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS = ZO_LevelUpRewardsUpcoming_Keyboard:New(control)
end
