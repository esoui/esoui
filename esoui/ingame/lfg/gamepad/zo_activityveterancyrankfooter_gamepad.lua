ZO_ActivityVeterancyRankFooter_Gamepad = ZO_InitializingObject:Subclass()

function ZO_ActivityVeterancyRankFooter_Gamepad:Initialize(control)
    self.control = control

    self.rankNameLabel = control:GetNamedChild("Name")
    self.rankLabel = control:GetNamedChild("Rank")
    self.iconTexture = control:GetNamedChild("Icon")
    self.xpBar = ZO_WrappingStatusBar:New(control:GetNamedChild("XPBar"))
    local statusBarControl = self.xpBar:GetControl()
    ZO_StatusBar_SetGradientColor(statusBarControl, ZO_SKILL_XP_BAR_GRADIENT_COLORS)
    self.glowContainer = statusBarControl:GetNamedChild("GlowContainer")

    GAMEPAD_ACTIVITY_VETERANCY_RANK_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_ACTIVITY_VETERANCY_RANK_FRAGMENT:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshVeterancyRank()
            end
        end
    )
end

function ZO_ActivityVeterancyRankFooter_Gamepad:RefreshVeterancyRank()
    ZO_VETERANCY_MANAGER:RefreshRankData()
    local veterancyRankData = ZO_VETERANCY_MANAGER:GetCurrentRankData()

    if veterancyRankData then
        if veterancyRankData == ZO_VETERANCY_MANAGER:GetRepeatableRankData() then
            local maxRankData = ZO_VETERANCY_MANAGER:GetRankDataByIndex(ZO_VETERANCY_MANAGER:GetNumRanks())
            if maxRankData then
                veterancyRankData = maxRankData
            end
        end

        self.rankLabel:SetText(veterancyRankData:GetIndex())
        self.rankNameLabel:SetText(veterancyRankData:GetFormattedName())
        self.iconTexture:SetTexture(veterancyRankData:GetIcon())
        self.xpBar:SetValue(veterancyRankData:GetIndex(), veterancyRankData:GetProgressPercent(), 1)
    end
end

function ZO_ActivityVeterancyRankFooter_Gamepad:IsShowing()
    return GAMEPAD_ACTIVITY_VETERANCY_RANK_FRAGMENT:IsShowing()
end

function ZO_ActivityVeterancyRankFooter_Gamepad.OnInitialized(self)
    GAMEPAD_ACTIVITY_VETERANCY_RANK = ZO_ActivityVeterancyRankFooter_Gamepad:New(self)
end