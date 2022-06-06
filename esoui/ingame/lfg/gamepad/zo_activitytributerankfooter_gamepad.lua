local ActivityTributeRank_Gamepad = ZO_InitializingObject:Subclass()

function ActivityTributeRank_Gamepad:Initialize(control)
    self.control = control

    local function OnXpBarLevelChanged(xpBar, level)
        -- TODO Tribute: determine if we need this
    end

    self.rankNameLabel = control:GetNamedChild("Name")
    self.rankLabel = control:GetNamedChild("Rank")
    self.iconTexture = control:GetNamedChild("Icon")
    self.xpBar = ZO_WrappingStatusBar:New(control:GetNamedChild("XPBar"), OnXpBarLevelChanged)
    local statusBarControl = self.xpBar:GetControl()
    ZO_StatusBar_SetGradientColor(statusBarControl, ZO_SKILL_XP_BAR_GRADIENT_COLORS)
    self.glowContainer = statusBarControl:GetNamedChild("GlowContainer")

    GAMEPAD_ACTIVITY_TRIBUTE_RANK_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_ACTIVITY_TRIBUTE_RANK_FRAGMENT:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshClubRank()
            end
        end
    )
end

function ActivityTributeRank_Gamepad:RefreshClubRank()
    local clubRank = GetTributePlayerClubRank()

    -- Display one higher than the clubRank used so we don't display 0 as the minimum
    self.rankLabel:SetText(clubRank + 1)
    self.rankNameLabel:SetText(zo_strformat(GetString("SI_TRIBUTECLUBRANK", clubRank)))
    self.iconTexture:SetTexture(string.format("EsoUI/Art/Tribute/tributeClubRank_%d.dds", clubRank))

    local currentClubExperienceForRank, maxClubExperienceForRank = GetTributePlayerExperienceInCurrentClubRank()
    self.xpBar:SetValue(clubRank, currentClubExperienceForRank, maxClubExperienceForRank)
end

function ActivityTributeRank_Gamepad:IsShowing()
    return GAMEPAD_ACTIVITY_TRIBUTE_RANK_FRAGMENT:IsShowing()
end

function ZO_ActivityTributeRankFooterGamepad_OnInitialized(self)
    GAMEPAD_ACTIVITY_TRIBUTE_RANK = ActivityTributeRank_Gamepad:New(self)
end