ZO_TRIBUTE_FINDER_MATCH_WON = 1
ZO_TRIBUTE_FINDER_MATCH_LOSS = 2
ZO_TRIBUTE_FINDER_MATCH_EMPTY = 3

ZO_TributeSummary = ZO_InitializingObject:Subclass()

local END_OF_GAME_FANFARE_TRIGGER_COMMANDS =
{
    BEGIN = "Begin",
    NEXT = "Next",
    ANIMATION_COMPLETE = "AnimationComplete",
    PARTIAL_ANIMATION_COMPLETE = "PartialAnimationComplete", -- For use in the animation event count trigger where we expect more than one call before we count all animations as complete and move on
}

local END_OF_GAME_STATISTICS_BACKDROPS =
{
    VICTORY = "EsoUI/Art/Tribute/tributeEndOfGameStatsBackdrop_Victory.dds",
    DEFEAT = "EsoUI/Art/Tribute/tributeEndOfGameStatsBackdrop_Defeat.dds",
}

local END_OF_GAME_RESULT_BANNERS =
{
    VICTORY = "EsoUI/Art/Tribute/tributeEndOfGameBanner_Victory.dds",
    DEFEAT = "EsoUI/Art/Tribute/tributeEndOfGameBanner_Defeat.dds",
}

local ANIMATE_INSTANTLY = true
local ANIMATE_FULLY = false
local WRAP = false
local NO_WRAP = true
local REWARDS_MATCH_KEY = 1
local REWARDS_RANK_UP_KEY = 2

function ZO_TributeSummary:Initialize(control)
    self.control = control

    TRIBUTE_SUMMARY_FRAGMENT = ZO_SimpleSceneFragment:New(self.control)
    TRIBUTE_SUMMARY_FRAGMENT:SetHideOnSceneHidden(true)
    TRIBUTE_SUMMARY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_HIDDEN then
            self.fanfareStateMachine:SetCurrentState("INACTIVE")
        end
    end)

    self:InitializeControls()
    self:InitializeStateMachine()

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end)
end

function ZO_TributeSummary:InitializeControls()
    self.modalUnderlay = self.control:GetNamedChild("ModalUnderlay")
    self.modalUnderlayTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeModalUnderlayFade", self.modalUnderlay)

    -- Control style templating
    local function MarkStyleDirty(control)
        control.isStyleDirty = true
        if not control:IsHidden() then
            control:CleanStyle()
        end
    end

    local function CleanStyle(control)
        if control.isStyleDirty then
            ApplyTemplateToControl(control, ZO_GetPlatformTemplate(control.styleTemplateBase))
            control.isStyleDirty = false
        end
    end

    local function SetupControlStyleTemplating(control, styleTemplateBase)
        control.MarkStyleDirty = MarkStyleDirty
        control.CleanStyle = CleanStyle
        control.styleTemplateBase = styleTemplateBase
        control.isStyleDirty = true -- When first created they won't have the platform style applied yet
    end

    --Keybind
    self.keybindDescriptor =
    {
        keybind = "UI_SHORTCUT_PRIMARY",
        name = GetString(SI_TRIBUTE_SUMMARY_CONTINUE),
        ethereal = true, -- Specifically for the keybind strip
        callback = function()
            self:HandleCommand(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
        end,
    }
    self.keybindButton = self.control:GetNamedChild("Keybind")
    self.keybindButton:SetKeybindButtonDescriptor(self.keybindDescriptor)
    self.keybindTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.keybindButton)

    -- Match Statistics
    self.statisticsControl = self.control:GetNamedChild("Statistics")

    self.statisticsBackdrop = self.statisticsControl:GetNamedChild("Backdrop")
    self.statisticsDuration = self.statisticsBackdrop:GetNamedChild("Duration")
    self.statisticsPrestige = self.statisticsBackdrop:GetNamedChild("PrestigeIcon"):GetNamedChild("Text")
    self.statisticsGold = self.statisticsBackdrop:GetNamedChild("GoldIcon"):GetNamedChild("Text")
    self.statisticsCards = self.statisticsBackdrop:GetNamedChild("CardsIcon"):GetNamedChild("Text")
    self.statisticsInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.statisticsControl)
    self.statisticsOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.statisticsControl)

    -- Match summary
    self.summaryControl = self.control:GetNamedChild("Status")

    self.summaryBanner = self.summaryControl:GetNamedChild("Banner")
    self.summaryHeaderLabel = self.summaryBanner:GetNamedChild("Text")
    self.summaryIcon = self.summaryControl:GetNamedChild("Icon")
    self.summaryPlayerLabel = self.summaryControl:GetNamedChild("PlayerLabel")
    self.summaryOpponentLabel = self.summaryControl:GetNamedChild("OpponentLabel")
    self.summaryPrestige = self.summaryControl:GetNamedChild("Prestige")
    self.summaryPlayerValue = self.summaryPrestige:GetNamedChild("PlayerValue")
    self.summaryOpponentValue = self.summaryPrestige:GetNamedChild("OpponentValue")
    self.summaryPatrons = self.summaryControl:GetNamedChild("Patrons")
    self.summaryInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.summaryControl)
    self.summaryOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.summaryControl)

    -- Rewards
    self.rewardsControl = self.control:GetNamedChild("Rewards")
    self.rewardsOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.rewardsControl)

    self.rewardsHeader = self.rewardsControl:GetNamedChild("Header")
    self.rewardsHeaderInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.rewardsHeader)

    self.clubRankContainer = self.rewardsControl:GetNamedChild("ClubRank")
    self.clubRankLabel = self.clubRankContainer:GetNamedChild("Rank")
    self.clubRankBarControl = self.clubRankContainer:GetNamedChild("Bar")
    local function OnBarRankChanged(_, rank)
        self.clubRankLabel:SetText(rank + 1)
    end
    ZO_StatusBar_SetGradientColor(self.clubRankBarControl, ZO_XP_BAR_GRADIENT_COLORS)
    self.clubRankBar = ZO_WrappingStatusBar:New(self.clubRankBarControl, OnBarRankChanged)
    self.rewardItemsControl = self.rewardsControl:GetNamedChild("MatchItems")
    self.rewardRowControlPool = ZO_ControlPool:New("ZO_TributeRewardRowContainer_Control", self.rewardItemsControl)
    self.rewardRowControlPool:AcquireObject(REWARDS_MATCH_KEY)
    self.rewardsControlPool = ZO_ControlPool:New("ZO_TributeRewardItem_Control")
    self.rewardsControlPool:SetCustomFactoryBehavior(function(control)
        control.iconTexture = control:GetNamedChild("Icon")
        control.stackCountLabel = control.iconTexture:GetNamedChild("StackCount")
        control.nameLabel = control:GetNamedChild("Name")

        SetupControlStyleTemplating(control, "ZO_TributeRewardItem_Control")
    end)
    self.rewardsControlPool:SetCustomAcquireBehavior(function(control)
        control:CleanStyle()
    end)

        -- Season progression
    self.progressionControl = self.control:GetNamedChild("Progression")
    self.progressionLabel = self.progressionControl:GetNamedChild("Text")
    local offsetX = 0
    local offsetY = 240
    self.progressionLabel:SetAnchor(TOP, self.rewardsHeader, BOTTOM, offsetX, offsetY)

    self.progressionLeaderboardLabel = self.progressionControl:GetNamedChild("LeaderboardLabel")
    self.progressionLeaderboardLabel:SetMaskAnchor(TOPLEFT, BOTTOMLEFT)
    self.progressionRankChange = self.progressionControl:GetNamedChild("RankChange")
    self.progressionProgressBarControl = self.progressionControl:GetNamedChild("ProgressBar")
    self.progressionProgressBar = ZO_WrappingStatusBar:New(self.progressionProgressBarControl)
    local ANIMATION_TIME_MS = 500
    self.progressionProgressBar:SetAnimationTime(ANIMATION_TIME_MS)
    self.progressionProgressBarFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionProgressBarControl)
    self.progressionCurrentRankIcon = self.progressionProgressBarControl:GetNamedChild("CurrentRankIcon")
    self.progressionCurrentRankLabel = self.progressionCurrentRankIcon:GetNamedChild("CurrentRankLabel")
    self.progressionNextRankIcon = self.progressionProgressBarControl:GetNamedChild("NextRankIcon")
    self.progressionNextRankLabel = self.progressionNextRankIcon:GetNamedChild("NextRankLabel")
    self.progressionRankUpIndicator = self.progressionControl:GetNamedChild("RankUpIndicator")

    self.progressionPlacementBarControl = self.progressionControl:GetNamedChild("PlacementBarPrevious")
    self.progressionPlacementBarNewControl = self.progressionControl:GetNamedChild("PlacementBarNew")

    self.progressionInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionControl)
    self.progressionPlacementBarNewFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionPlacementBarNewControl)
    self.progressionPlacementBarFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionPlacementBarControl)
    self.progressionPlacementBarNewFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionPlacementBarNewControl)
    self.progressionRankChangeUpTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeRankChangeUp", self.progressionRankChange)
    self.progressionRankChangeUpTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.progressionRankChangeFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeRankChangeFadeOut", self.progressionRankChange)
    self.progressionLeaderboardWipeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeLeaderboardWipeIn", self.progressionLeaderboardLabel)
    self.progressionLeaderboardWipeInTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.progressionLeaderboardLabel:SetAnimation(self.progressionLeaderboardWipeInTimeline:GetAnimation(1))
    self.progressionLeaderboardLossBounceTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeLeaderboardLossBounce", self.progressionLeaderboardLabel)
    self.progressionLeaderboardWinBounceTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeLeaderboardWinBounce", self.progressionLeaderboardLabel)
    self.progressionNextRankBounceTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeNextRankBounce", self.progressionNextRankIcon)
    self.progressionRankUpScaleTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeRankUpScale", self.progressionRankUpIndicator)
    self.progressionRankUpScaleTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.progressionRankUpFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionRankUpIndicator)
    self.progressionCurrentRankFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionCurrentRankIcon)
    self.progressionNextRankFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionNextRankIcon)
    self.progressionCurrentRankFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionCurrentRankIcon)
    self.progressionNextRankFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionNextRankIcon)
end

function ZO_TributeSummary:InitializeStateMachine()
    local fanfareStateMachine = ZO_StateMachine_Base:New("TRIBUTE_FANFARE_STATE_MACHINE")
    self.fanfareStateMachine = fanfareStateMachine
    local IGNORE_ANIMATION_CALLBACKS = true

    -- States
    do
        local state = fanfareStateMachine:AddState("INACTIVE")
        state:RegisterCallback("OnActivated", function()
            self.modalUnderlayTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.keybindTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.statisticsInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.summaryInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.rewardsOutTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.rewardsHeaderInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.progressionInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.progressionPlacementBarNewFadeInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.progressionRankChangeUpTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.progressionLeaderboardWipeInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            -- The following timelines play to end because they're PING_PONG animations and end where they start.
            self.progressionLeaderboardLossBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionLeaderboardWinBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionNextRankBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionRankUpScaleTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.keybindButton:SetHidden(true)
            KEYBIND_STRIP:RemoveKeybindButton(self.keybindDescriptor)
            self.statisticsControl:SetHidden(true)
            self.summaryControl:SetHidden(true)
            self.rewardsControl:SetHidden(true)
            self.rewardItemsControl:SetHidden(true)
            self.progressionControl:SetHidden(true)
            self.progressionLeaderboardLabel:SetHidden(true)
            self.progressionRankChange:SetHidden(true)
            self.progressionRankUpIndicator:SetHidden(true)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("BEGIN")
        state:RegisterCallback("OnActivated", function()
            self.modalUnderlayTimeline:PlayFromStart()
            -- TODO Tribute: Animation timelines
            fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("SUMMARY_IN")
        state:RegisterCallback("OnActivated", function()
            KEYBIND_STRIP:AddKeybindButton(self.keybindDescriptor)
            self.keybindButton:SetHidden(false)
            self.statisticsControl:SetHidden(self.hasRewards)
            self.summaryControl:SetHidden(false)
            self.keybindTimeline:PlayFromStart()
            self.statisticsInTimeline:PlayFromStart()
            self.summaryInTimeline:PlayFromStart()
            -- This will be a fade in of all on-screen UI elements simultaneously
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.keybindTimeline:IsPlaying() then
                self.keybindTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.statisticsInTimeline:IsPlaying() then
                self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.summaryInTimeline:IsPlaying() then
                self.summaryInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("SUMMARY")
        state:RegisterCallback("OnActivated", function()
            -- We may have gotten here via a skip, which means we may never have even made it into the interstitial states
            -- So just ensure these animations are where we want them to be by this point in the flow
            self.keybindTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.summaryInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("SUMMARY_OUT")
        state:RegisterCallback("OnActivated", function()
            self.statisticsOutTimeline:PlayFromStart()
            self.summaryOutTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.statisticsOutTimeline:IsPlaying() then
                self.statisticsOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.summaryOutTimeline:IsPlaying() then
                self.summaryOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("REWARDS_IN")
        state:RegisterCallback("OnActivated", function()
            local clubRank = GetTributePlayerClubRank()
            local currentClubExperienceForRank, maxClubExperienceForRank = GetTributePlayerExperienceInCurrentClubRank()
            --If the maximum club experience for this rank is 0, then we are maxed out
            if maxClubExperienceForRank == 0 then
                self.clubRankBar:SetValue(clubRank, 1, 1, NO_WRAP, ANIMATE_INSTANTLY)
            else
                self.clubRankBar:SetValue(clubRank, currentClubExperienceForRank, maxClubExperienceForRank, NO_WRAP, ANIMATE_INSTANTLY)
            end
            self.rewardsControl:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            self.rewardsHeaderInTimeline:PlayFromStart()
            self.statisticsInTimeline:PlayFromStart()
            self.matchRewardItemsInTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.rewardsHeaderInTimeline:IsPlaying() then
                self.rewardsHeaderInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.statisticsInTimeline:IsPlaying() then
                self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.matchRewardItemsInTimeline:IsPlaying() then
                self.matchRewardItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("REWARDS")
        state:RegisterCallback("OnActivated", function()
            -- We may have gotten here via a skip, which means we may never have even made it into the interstitial states
            -- So just ensure these animations are where we want them to be by this point in the flow
            self.rewardsControl:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            self.rewardsHeaderInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.matchRewardItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("REWARDS_OUT")
        state:RegisterCallback("OnActivated", function()
            self.rewardsOutTimeline:PlayFromStart()
            self.statisticsOutTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.rewardsOutTimeline:IsPlaying() then
                self.rewardsOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.statisticsOutTimeline:IsPlaying() then
                self.statisticsOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("PROGRESSION_IN")
        state:RegisterCallback("OnActivated", function()
            local offsetX = 0
            local offsetY = 60
            self.rewardItemsControl:SetAnchor(TOP, self.progressionControl:GetNamedChild("Divider"), BOTTOM, offsetX, offsetY)

            self.rewardsControl:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            self.progressionControl:SetHidden(false)
            self.rewardsHeaderInTimeline:PlayFromStart()
            self.statisticsInTimeline:PlayFromStart()
            self.matchRewardItemsInTimeline:PlayFromStart()
            self.progressionInTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.rewardsHeaderInTimeline:IsPlaying() then
                self.rewardsHeaderInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.statisticsInTimeline:IsPlaying() then
                self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.matchRewardItemsInTimeline:IsPlaying() then
                self.matchRewardItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionInTimeline:IsPlaying() then
                self.progressionInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("RANK_CHANGE_IN")
        state:RegisterCallback("OnActivated", function()
            self.progressionRankChange:SetHidden(false)
            self.progressionRankChangeUpTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionRankChangeUpTimeline:IsPlaying() then
                self.progressionRankChangeUpTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("RANK_CHANGE_OUT")
        state:RegisterCallback("OnActivated", function()
            self.progressionRankChangeFadeOutTimeline:PlayFromStart()
            if self.rankUp then
                self.progressionNextRankBounceTimeline:PlayFromStart()
            end
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionRankChangeFadeOutTimeline:IsPlaying() then
                self.progressionRankChangeFadeOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionNextRankBounceTimeline:IsPlaying() then
                self.progressionNextRankBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("PROGRESSION_PROGRESS_BAR_IN")
        state:RegisterCallback("OnActivated", function()
            local playerCampaignXPNew = self.playerCampaignXP
            if self.rankUp then
                playerCampaignXPNew = self.playerRankNextRequiredXP
            end
            self.progressionPlacementBarNewFadeInTimeline:PlayFromStart()
            self.progressionProgressBar:SetValue(self.playerRankCurrent, playerCampaignXPNew, self.playerRankNextRequiredXP, WRAP, ANIMATE_FULLY)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("RANK_UP_IN")
        state:RegisterCallback("OnActivated", function()
            self.progressionRankUpIndicator:SetTexture(self.playerRankNewRewardsData:GetTierIcon())
            self.progressionRankUpIndicator:GetNamedChild("NewRankLabel"):SetText(self.playerRankNewRewardsData:GetTierName())
            self.progressionRankUpIndicator:SetHidden(false)
            self.progressionRankUpScaleTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionRankUpScaleTimeline:IsPlaying() then
                self.progressionRankUpScaleTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("RANK_UP_REWARDS_IN")
        state:RegisterCallback("OnActivated", function()
            self.rewardRowControlPool:GetActiveObject(REWARDS_RANK_UP_KEY):SetHidden(false)
            self.rankUpItemsInTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.rankUpItemsInTimeline:IsPlaying() then
                self.rankUpItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("OLD_RANKS_FADE_OUT")
        state:RegisterCallback("OnActivated", function()
            self.progressionCurrentRankFadeOutTimeline:PlayFromStart()
            self.progressionNextRankFadeOutTimeline:PlayFromStart()
            self.progressionPlacementBarFadeOutTimeline:PlayFromStart()
            self.progressionPlacementBarNewFadeOutTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionCurrentRankFadeOutTimeline:IsPlaying() then
                self.progressionCurrentRankFadeOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionNextRankFadeOutTimeline:IsPlaying() then
                self.progressionNextRankFadeOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionPlacementBarFadeOutTimeline:IsPlaying() then
                self.progressionPlacementBarFadeOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionPlacementBarNewFadeOutTimeline:IsPlaying() then
                self.progressionPlacementBarNewFadeOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("NEW_RANKS_FADE_IN")
        state:RegisterCallback("OnActivated", function()
            self.progressionPlacementBarControl:SetHidden(true)
            self.progressionPlacementBarNewControl:SetHidden(true)
            self.progressionProgressBarFadeInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.progressionProgressBarControl:SetHidden(false)
            self.progressionCurrentRankIcon:SetTexture(self.playerRankNewRewardsData:GetTierIcon())
            self.progressionCurrentRankLabel:SetText(self.playerRankNewRewardsData:GetTierName())
            if self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM then
                local newNextRankData = ZO_TributeRewardsData:New(TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS), self.playerRankNew + 1)
                self.progressionNextRankIcon:SetTexture(newNextRankData:GetTierIcon())
                self.progressionNextRankLabel:SetText(newNextRankData:GetTierName())
            end

            if self.playerRankNext == TRIBUTE_TIER_PLATINUM then
                self.progressionNextRankIcon:SetHidden(true)
                self.progressionNextRankLabel:SetHidden(true)
            end

            self.progressionProgressBarFadeInTimeline:PlayFromStart()
            self.progressionCurrentRankFadeInTimeline:PlayFromStart()
            self.progressionNextRankFadeInTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionCurrentRankFadeInTimeline:IsPlaying() then
                self.progressionCurrentRankFadeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionNextRankFadeInTimeline:IsPlaying() then
                self.progressionNextRankFadeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("NEW_RANK_PROGRESS_BAR_IN")
        state:RegisterCallback("OnActivated", function()
            self.playerCampaignXP = self.playerCampaignXP - self.playerRankNextRequiredXP
            self.playerRankCurrent = self.playerRankNew
            if self.playerRankNew ~= TRIBUTE_TIER_PLATINUM then
                self.playerRankNext = self.playerRankNew + 1
            end
            self.playerRankNextRequiredXP = GetTributeCampaignRankExperienceRequirement(self.playerRankNext) - GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent)
            self.progressionProgressBar:SetValue(self.playerRankCurrent, self.playerCampaignXP, self.playerRankNextRequiredXP, WRAP, ANIMATE_FULLY)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("RANK_UP_OUT")
        state:RegisterCallback("OnActivated", function()
            self.progressionRankUpFadeOutTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionRankUpFadeOutTimeline:IsPlaying() then
                self.progressionRankUpFadeOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("RANK_UP_SKIP")
        state:RegisterCallback("OnActivated", function()
            if self.rankUp then
                self.progressionRankUpIndicator:SetTexture(self.playerRankNewRewardsData:GetTierIcon())
                self.progressionRankUpIndicator:GetNamedChild("NewRankLabel"):SetText(self.playerRankNewRewardsData:GetTierName())

                self.progressionCurrentRankIcon:SetTexture(self.playerRankNewRewardsData:GetTierIcon())
                self.progressionCurrentRankLabel:SetText(self.playerRankNewRewardsData:GetTierName())
                if self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM then
                    local newNextRankData = ZO_TributeRewardsData:New(TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS), self.playerRankNew + 1)
                    self.progressionNextRankIcon:SetTexture(newNextRankData:GetTierIcon())
                    self.progressionNextRankLabel:SetText(newNextRankData:GetTierName())
                end

                self.playerCampaignXP = self.playerCampaignXP - self.playerRankNextRequiredXP
                self.playerRankCurrent = self.playerRankNew
                if self.playerRankNew ~= TRIBUTE_TIER_PLATINUM then
                    self.playerRankNext = self.playerRankNew + 1
                else
                    self.progressionNextRankIcon:SetHidden(true)
                    self.progressionNextRankLabel:SetHidden(true)
                end
                self.playerRankNextRequiredXP = GetTributeCampaignRankExperienceRequirement(self.playerRankNext) - GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent)
            end
            fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("LEADERBOARD_TRANSITORY_STATE")
        -- This state exists to be a unified state that prior states skip to that runs a conditional
        -- to proceed either to LEADERBOARD or NO_LEADERBOARD
        state:RegisterCallback("OnActivated", function()
            fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("NO_LEADERBOARD")
        state:RegisterCallback("OnActivated", function()
            -- We may have gotten here via a skip, which means we may never have even made it into the interstitial states
            -- So just ensure these animations are where we want them to be by this point in the flow
            local offsetX = 0
            local offsetY = 60
            self.rewardItemsControl:SetAnchor(TOP, self.progressionControl:GetNamedChild("Divider"), BOTTOM, offsetX, offsetY)

            self.progressionProgressBar:SetValue(self.playerRankCurrent, self.playerCampaignXP, self.playerRankNextRequiredXP, WRAP, ANIMATE_INSTANTLY)

            self.rewardsControl:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            local rankUpRewardsRow = self.rewardRowControlPool:GetActiveObject(REWARDS_RANK_UP_KEY)
            if rankUpRewardsRow then
                rankUpRewardsRow:SetHidden(false)
                self.rankUpItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            self.progressionControl:SetHidden(false)
            self.progressionRankChange:SetHidden(self.rankUp)
            self.progressionRankUpIndicator:SetHidden(not self.rankUp)
            self.rewardsHeaderInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.matchRewardItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionPlacementBarNewFadeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionRankChangeUpTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionRankUpScaleTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("LEADERBOARD_IN")
        state:RegisterCallback("OnActivated", function()
            self.progressionLeaderboardLabel:SetText("[DEBUG] Leaderboard Rank: 853")
            self.progressionLeaderboardLabel:SetHidden(false)
            self.progressionLeaderboardWipeInTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionLeaderboardWipeInTimeline:IsPlaying() then
                self.progressionLeaderboardWipeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("LEADERBOARD_BOUNCE_IN")
        state:RegisterCallback("OnActivated", function()
            if self.victory then
                self.progressionLeaderboardWinBounceTimeline:PlayFromStart()
            else
                self.progressionLeaderboardLossBounceTimeline:PlayFromStart()
            end
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionLeaderboardWinBounceTimeline:IsPlaying() then
                self.progressionLeaderboardWinBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionLeaderboardLossBounceTimeline:IsPlaying() then
                self.progressionLeaderboardLossBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("LEADERBOARD")
        state:RegisterCallback("OnActivated", function()
            -- We may have gotten here via a skip, which means we may never have even made it into the interstitial states
            -- So just ensure these animations are where we want them to be by this point in the flow
            self.rewardsControl:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            local rankUpRewardsRow = self.rewardRowControlPool:GetActiveObject(REWARDS_RANK_UP_KEY)
            if rankUpRewardsRow then
                rankUpRewardsRow:SetHidden(false)
                self.rankUpItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            self.progressionControl:SetHidden(false)
            self.progressionRankChange:SetHidden(true)
            self.progressionLeaderboardLabel:SetText("[DEBUG] Leaderboard Rank: 853")
            self.progressionLeaderboardLabel:SetHidden(false)
            self.rewardsHeaderInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.matchRewardItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionRankChangeUpTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            if self.victory then
                self.progressionLeaderboardLossBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            else
                self.progressionLeaderboardWinBounceTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("QUIT")
        state:RegisterCallback("OnActivated", function()
            SCENE_MANAGER:RequestShowLeaderBaseScene()
        end)
    end

    -- TODO Tribute: Add remaining states:

    -- Edges
    do
        fanfareStateMachine:AddEdgeAutoName("INACTIVE", "BEGIN")
        fanfareStateMachine:AddEdgeAutoName("BEGIN", "SUMMARY_IN")
        fanfareStateMachine:AddEdgeAutoName("SUMMARY_IN", "SUMMARY")
        fanfareStateMachine:AddEdge("SUMMARY_IN_TO_SUMMARY_SKIP", "SUMMARY_IN", "SUMMARY")
        fanfareStateMachine:AddEdgeAutoName("SUMMARY", "SUMMARY_OUT")
        local summaryToQuitInEdge = fanfareStateMachine:AddEdgeAutoName("SUMMARY_OUT", "QUIT")
        summaryToQuitInEdge:SetConditional(function()
            return not self.hasRewards
        end)
        local rewardsInEdge = fanfareStateMachine:AddEdgeAutoName("SUMMARY_OUT", "REWARDS_IN")
        rewardsInEdge:SetConditional(function()
            return self.hasRewards and not self.isRanked
        end)
        local rewardsSkipInEdge = fanfareStateMachine:AddEdge("SUMMARY_OUT_TO_REWARDS_SKIP", "SUMMARY_OUT", "REWARDS")
        rewardsSkipInEdge:SetConditional(function()
            return self.hasRewards and not self.isRanked
        end)
        fanfareStateMachine:AddEdgeAutoName("REWARDS_IN", "REWARDS")
        fanfareStateMachine:AddEdge("REWARDS_IN_TO_REWARDS_SKIP", "REWARDS_IN", "REWARDS")
        fanfareStateMachine:AddEdgeAutoName("REWARDS", "REWARDS_OUT")
        fanfareStateMachine:AddEdgeAutoName("REWARDS_OUT", "QUIT")
        fanfareStateMachine:AddEdge("REWARDS_OUT_TO_QUIT_SKIP", "REWARDS_OUT", "QUIT")
        local progressionInEdge = fanfareStateMachine:AddEdgeAutoName("SUMMARY_OUT", "PROGRESSION_IN")
        progressionInEdge:SetConditional(function()
            return self.isRanked
        end)
        local summaryOutLeaderboardSkipEdge = fanfareStateMachine:AddEdge("SUMMARY_OUT_TO_LEADERBOARD_TRANSITORY_STATE_SKIP", "SUMMARY_OUT", "LEADERBOARD_TRANSITORY_STATE")
        summaryOutLeaderboardSkipEdge:SetConditional(function()
            return self.isRanked
        end)
        local progressionInRankChangeInEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_IN", "RANK_CHANGE_IN")
        progressionInRankChangeInEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_UNRANKED
        end)
        local progressionInProgressBarInEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_IN", "PROGRESSION_PROGRESS_BAR_IN")
        progressionInProgressBarInEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_UNRANKED
        end)
        fanfareStateMachine:AddEdge("PROGRESSION_IN_TO_LEADERBOARD_TRANSITORY_STATE_SKIP", "PROGRESSION_IN", "LEADERBOARD_TRANSITORY_STATE")
        fanfareStateMachine:AddEdgeAutoName("RANK_CHANGE_IN", "PROGRESSION_PROGRESS_BAR_IN")
        fanfareStateMachine:AddEdge("RANK_CHANGE_IN_TO_LEADERBOARD_TRANSITORY_STATE_SKIP", "RANK_CHANGE_IN", "LEADERBOARD_TRANSITORY_STATE")
        local progressBarNoLeaderboardEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_PROGRESS_BAR_IN", "NO_LEADERBOARD")
        progressBarNoLeaderboardEdge:SetConditional(function()
            return (not self.rankUp) and self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM
        end)
        fanfareStateMachine:AddEdge("PROGRESSION_PROGRESS_BAR_IN_TO_LEADERBOARD_TRANSITORY_STATE_SKIP", "PROGRESSION_PROGRESS_BAR_IN", "LEADERBOARD_TRANSITORY_STATE")
        fanfareStateMachine:AddEdgeAutoName("NO_LEADERBOARD", "QUIT")
        local progressBarRankChangeOutEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_PROGRESS_BAR_IN", "RANK_CHANGE_OUT")
        progressBarRankChangeOutEdge:SetConditional(function()
            return (self.playerRankCurrent ~= TRIBUTE_TIER_UNRANKED and self.rankUp) or self.playerRankCurrent == TRIBUTE_TIER_PLATINUM
        end)
        local progressBarRankUpInEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_PROGRESS_BAR_IN", "RANK_UP_IN")
        progressBarRankUpInEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_UNRANKED and self.rankUp
        end)
        local rankChangeLeaderboardInEdge = fanfareStateMachine:AddEdgeAutoName("RANK_CHANGE_OUT", "LEADERBOARD_IN")
        rankChangeLeaderboardInEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_PLATINUM
        end)
        local rankChangeRankUpInEdge = fanfareStateMachine:AddEdgeAutoName("RANK_CHANGE_OUT", "RANK_UP_IN")
        rankChangeRankUpInEdge:SetConditional(function()
            return self.rankUp
        end)
        local rankChangeRankUpSkipEdge = fanfareStateMachine:AddEdgeAutoName("RANK_CHANGE_OUT", "RANK_UP_SKIP")
        rankChangeRankUpInEdge:SetConditional(function()
            return self.rankUp
        end)
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_IN", "RANK_UP_REWARDS_IN")
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_IN", "RANK_UP_SKIP")
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_REWARDS_IN", "OLD_RANKS_FADE_OUT")
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_REWARDS_IN", "RANK_UP_SKIP")
        fanfareStateMachine:AddEdgeAutoName("OLD_RANKS_FADE_OUT", "NEW_RANKS_FADE_IN")
        fanfareStateMachine:AddEdgeAutoName("OLD_RANKS_FADE_OUT", "RANK_UP_SKIP")
        fanfareStateMachine:AddEdgeAutoName("NEW_RANKS_FADE_IN", "NEW_RANK_PROGRESS_BAR_IN")
        fanfareStateMachine:AddEdgeAutoName("NEW_RANKS_FADE_IN", "RANK_UP_SKIP")
        local newProgressBarInRankUpOutEdge = fanfareStateMachine:AddEdgeAutoName("NEW_RANK_PROGRESS_BAR_IN", "RANK_UP_OUT")
        newProgressBarInRankUpOutEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_PLATINUM
        end)
        local newProgressBarInNoLeaderboardEdge = fanfareStateMachine:AddEdgeAutoName("NEW_RANK_PROGRESS_BAR_IN", "NO_LEADERBOARD")
        newProgressBarInNoLeaderboardEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM
        end)
        local newProgressBarInNoLeaderboardSkipEdge = fanfareStateMachine:AddEdge("NEW_RANK_PROGRESS_BAR_IN_TO_NO_LEADERBOARD_SKIP", "NEW_RANK_PROGRESS_BAR_IN", "NO_LEADERBOARD")
        newProgressBarInNoLeaderboardSkipEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM
        end)
        local rankUpSkipNoLeaderboardEdge = fanfareStateMachine:AddEdgeAutoName("RANK_UP_SKIP", "NO_LEADERBOARD")
        rankUpSkipNoLeaderboardEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM
        end)
        fanfareStateMachine:AddEdgeAutoName("LEADERBOARD_IN", "LEADERBOARD_BOUNCE_IN")
        fanfareStateMachine:AddEdgeAutoName("LEADERBOARD_BOUNCE_IN", "LEADERBOARD")
        fanfareStateMachine:AddEdgeAutoName("LEADERBOARD", "QUIT")

        local transitoryNoLeaderboardInEdge = fanfareStateMachine:AddEdgeAutoName("LEADERBOARD_TRANSITORY_STATE", "NO_LEADERBOARD")
        transitoryNoLeaderboardInEdge:SetConditional(function()
            return (not self.rankUp) and self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM
        end)
        local transitoryLeaderboardInEdge = fanfareStateMachine:AddEdgeAutoName("LEADERBOARD_TRANSITORY_STATE", "LEADERBOARD")
        transitoryLeaderboardInEdge:SetConditional(function()
            return (not self.rankUp) and self.playerRankCurrent == TRIBUTE_TIER_PLATINUM
        end)
        local transitoryRankUpInEdge = fanfareStateMachine:AddEdgeAutoName("LEADERBOARD_TRANSITORY_STATE", "RANK_UP_SKIP")
        transitoryRankUpInEdge:SetConditional(function()
            return self.rankUp
        end)
    end

    -- TODO Tribute: Add remaining edges

    -- Triggers
    fanfareStateMachine:AddTrigger("BEGIN", ZO_StateMachine_TriggerStateCallback, END_OF_GAME_FANFARE_TRIGGER_COMMANDS.BEGIN)
    fanfareStateMachine:AddTrigger("NEXT", ZO_StateMachine_TriggerStateCallback, END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
    fanfareStateMachine:AddTrigger("ANIMATION_COMPLETE", ZO_StateMachine_TriggerStateCallback, END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)

    -- Add triggers to edges
    -- Initial summary edges
    fanfareStateMachine:AddTriggerToEdge("BEGIN", "INACTIVE_TO_BEGIN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "BEGIN_TO_SUMMARY_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "SUMMARY_IN_TO_SUMMARY")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SUMMARY_IN_TO_SUMMARY_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SUMMARY_TO_SUMMARY_OUT")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "SUMMARY_OUT_TO_QUIT")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "SUMMARY_OUT_TO_REWARDS_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SUMMARY_OUT_TO_REWARDS_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "REWARDS_IN_TO_REWARDS")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "REWARDS_IN_TO_REWARDS_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "REWARDS_TO_REWARDS_OUT")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "REWARDS_OUT_TO_QUIT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "REWARDS_OUT_TO_QUIT_SKIP")

    -- Ranked match initial states
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "SUMMARY_OUT_TO_PROGRESSION_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SUMMARY_OUT_TO_LEADERBOARD_TRANSITORY_STATE_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "PROGRESSION_IN_TO_RANK_CHANGE_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "PROGRESSION_IN_TO_PROGRESSION_PROGRESS_BAR_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "PROGRESSION_IN_TO_LEADERBOARD_TRANSITORY_STATE_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "RANK_CHANGE_IN_TO_PROGRESSION_PROGRESS_BAR_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_CHANGE_IN_TO_LEADERBOARD_TRANSITORY_STATE_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "PROGRESSION_PROGRESS_BAR_IN_TO_NO_LEADERBOARD")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "PROGRESSION_PROGRESS_BAR_IN_TO_RANK_UP_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "PROGRESSION_PROGRESS_BAR_IN_TO_LEADERBOARD_TRANSITORY_STATE_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "NO_LEADERBOARD_TO_QUIT")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "PROGRESSION_PROGRESS_BAR_IN_TO_RANK_CHANGE_OUT")

    -- The player is not on the leaderboard
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "RANK_CHANGE_OUT_TO_RANK_UP_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_CHANGE_OUT_TO_RANK_UP_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "RANK_UP_IN_TO_RANK_UP_REWARDS_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_UP_IN_TO_RANK_UP_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "RANK_UP_REWARDS_IN_TO_OLD_RANKS_FADE_OUT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_UP_REWARDS_IN_TO_RANK_UP_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "OLD_RANKS_FADE_OUT_TO_NEW_RANKS_FADE_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "OLD_RANKS_FADE_OUT_TO_RANK_UP_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "NEW_RANKS_FADE_IN_TO_NEW_RANK_PROGRESS_BAR_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "NEW_RANKS_FADE_IN_TO_RANK_UP_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "NEW_RANK_PROGRESS_BAR_IN_TO_RANK_UP_OUT")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "NEW_RANK_PROGRESS_BAR_IN_TO_NO_LEADERBOARD")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "NEW_RANK_PROGRESS_BAR_IN_TO_NO_LEADERBOARD_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LEADERBOARD_TRANSITORY_STATE_TO_RANK_UP_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_UP_SKIP_TO_NO_LEADERBOARD")

    -- The player is already on the leaderboard
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "RANK_CHANGE_OUT_TO_LEADERBOARD_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "LEADERBOARD_IN_TO_LEADERBOARD_BOUNCE_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "LEADERBOARD_BOUNCE_IN_TO_LEADERBOARD")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LEADERBOARD_TO_QUIT")

    -- TODO Tribute: Add remaining triggers

    -- Animation callbacks --
    local function OnCompleteFireTrigger(_, completedPlaying)
        if completedPlaying then
            fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
        end
    end

    self.summaryInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.summaryOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.rewardsHeaderInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.rewardsOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionRankChangeUpTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionRankChangeFadeOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionProgressBar:SetOnCompleteCallback(OnCompleteFireTrigger)
    self.progressionLeaderboardWipeInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionLeaderboardLossBounceTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionLeaderboardWinBounceTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionRankUpScaleTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionCurrentRankFadeOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionCurrentRankFadeInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)

    -- Reset state machine
    self.fanfareStateMachine:SetCurrentState("INACTIVE")
end

function ZO_TributeSummary:ApplyPlatformStyle()
    ApplyTemplateToControl(self.statisticsControl, ZO_GetPlatformTemplate("ZO_TributeSummary_Statistics"))
    ApplyTemplateToControl(self.keybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    ApplyTemplateToControl(self.summaryControl, ZO_GetPlatformTemplate("ZO_TributeSummary_TributeStatus"))
    local numPatrons = self.summaryPatrons:GetNumChildren()
    for patronIndex = 1, numPatrons do
        local patron = self.summaryPatrons:GetChild(patronIndex)
        ApplyTemplateToControl(patron, ZO_GetPlatformTemplate("ZO_TributeSummary_Patron"))
    end
    ApplyTemplateToControl(self.rewardsControl, ZO_GetPlatformTemplate("ZO_TributeSummary_TributeReward"))
    ApplyTemplateToControl(self.progressionControl, ZO_GetPlatformTemplate("ZO_TributeSummary_TributeProgression"))

    -- We have to rebuild the placement match bars from scratch if we change style templates.
    if self.progressionPlacementBar then
        local numRequiredPlacementMatches = GetNumRequiredPlacementMatches(self.campaignId)
        self.progressionPlacementBar:SetSegmentTemplate(ZO_GetPlatformTemplate("ZO_TributeSummary_ArrowStatusBar"))
        self.progressionPlacementBar:SetMaxSegments(numRequiredPlacementMatches)
        self.progressionPlacementBarNew:SetSegmentTemplate(ZO_GetPlatformTemplate("ZO_TributeSummary_ArrowStatusBar"))
        self.progressionPlacementBarNew:SetMaxSegments(numRequiredPlacementMatches)
        for i = 1, numRequiredPlacementMatches do
            self.progressionPlacementBar:AddSegment()
            self.progressionPlacementBarNew:AddSegment()
        end
    end

    -- TODO Tribute: Other controls specific to this scene

    -- Reset the text here to handle the force uppercase on gamepad
    self.keybindButton:SetText(self.keybindButton.nameLabel:GetText())
end

function ZO_TributeSummary:BeginEndOfGameFanfare()
    SCENE_MANAGER:AddFragment(TRIBUTE_SUMMARY_FRAGMENT)

    local matchType = GetTributeMatchType()
    self.hasRewards = matchType ~= TRIBUTE_MATCH_TYPE_CASUAL
    self.isRanked = matchType == TRIBUTE_MATCH_TYPE_COMPETITIVE

    self.campaignId = GetTributeMatchCampaignId()

    local victor, victoryType = GetTributeResultsWinnerInfo()
    self.victory = victor == TRIBUTE_PLAYER_PERSPECTIVE_SELF
    self.victoryType = victoryType
    self.playerPrestige = GetTributePlayerPerspectiveResource(TRIBUTE_PLAYER_PERSPECTIVE_SELF, TRIBUTE_RESOURCE_PRESTIGE)
    self.opponentPrestige = GetTributePlayerPerspectiveResource(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT, TRIBUTE_RESOURCE_PRESTIGE)

    if self.victory and (matchType == TRIBUTE_MATCH_TYPE_COMPETITIVE or matchType == TRIBUTE_MATCH_TYPE_CASUAL) then
        TRIBUTE:QueueVictoryTutorial()
    end

    self.playerRankCurrent = GetTributePlayerCampaignRank()
    if self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM then
        self.playerRankNext = self.playerRankCurrent + 1
    else
        self.playerRankNext = self.playerRankCurrent
    end
    -- Rarely (esp. when completing placement matches) the player's new rank may not actually be the next rank (i.e. they can skip over ranks)
    self.playerRankNew = GetNewCampaignRank()

    self.matchResults = {}
    self.matchResultsNew = {}
    local hasUpdatedCurrentMatch = false
    local numRequiredPlacementMatches = GetNumRequiredPlacementMatches(self.campaignId)
    for i = 0, numRequiredPlacementMatches do
        local hasRecord, wasAWin = GetCampaignMatchResultFromHistoryByMatchNumber(i)
        if hasRecord then
            if wasAWin then
                table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_WON)
                table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_WON)
            else
                table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_LOSS)
                table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_LOSS)
            end
        elseif not hasUpdatedCurrentMatch then
            if self.victory then
                table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
                table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_WON)
            else
                table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
                table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_LOSS)
            end
            hasUpdatedCurrentMatch = true
        else
            table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
            table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
        end
    end

    local function UpdateBarVisualDisplay(control, segmentIndex, handleNewMatch)
        local overlayControl = control:GetNamedChild("Overlay")
        local leftControl = overlayControl:GetNamedChild("Left")
        local rightControl = overlayControl:GetNamedChild("Right")
        local middleControl = overlayControl:GetNamedChild("Middle")

        local numRequiredMatches = GetNumRequiredPlacementMatches(self.campaignId)
        local drawLevel = numRequiredMatches + 2 - segmentIndex
        leftControl:SetDrawLevel(drawLevel)
        rightControl:SetDrawLevel(drawLevel)
        middleControl:SetDrawLevel(drawLevel)

        local glossControl = control:GetNamedChild("Gloss")
        glossControl:SetDrawLevel(numRequiredMatches + 2 - segmentIndex)
        glossControl:SetHidden(false)

        local matchRecord = handleNewMatch and self.matchResultsNew or self.matchResults
        if segmentIndex <= numRequiredMatches then
            if matchRecord[segmentIndex] == ZO_TRIBUTE_FINDER_MATCH_WON then
                ZO_StatusBar_SetGradientColor(control, ZO_XP_BAR_GRADIENT_COLORS)
            elseif matchRecord[segmentIndex] == ZO_TRIBUTE_FINDER_MATCH_LOSS then
                ZO_StatusBar_SetGradientColor(control, ZO_LOSE_BAR_GRADIENT_COLORS)
            elseif matchRecord[segmentIndex] == ZO_TRIBUTE_FINDER_MATCH_EMPTY then
                control:SetColor(0, 0, 0, 1)
                glossControl:SetHidden(true)
            end
        end
    end
    local function UpdateBarVisualDisplayNew(control, segmentIndex)
        local handleNewMatch = true
        UpdateBarVisualDisplay(control, segmentIndex, handleNewMatch)
    end

    if not self.progressionPlacementBar then
        self.progressionPlacementBar = ZO_MultiSegmentProgressBar:New(self.progressionPlacementBarControl, ZO_GetPlatformTemplate("ZO_TributeSummary_ArrowStatusBar"), UpdateBarVisualDisplay)
    end
    self.progressionPlacementBar:SetSegmentationUniformity(true)
    self.progressionPlacementBar:SetProgressBarGrowthDirection(ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT)
    self.progressionPlacementBar:SetPreviousSegmentUnderneathOverlap(-32)
    if not self.progressionPlacementBarNew then
        self.progressionPlacementBarNew = ZO_MultiSegmentProgressBar:New(self.progressionPlacementBarNewControl, ZO_GetPlatformTemplate("ZO_TributeSummary_ArrowStatusBar"), UpdateBarVisualDisplayNew)
    end
    self.progressionPlacementBarNew:SetSegmentationUniformity(true)
    self.progressionPlacementBarNew:SetProgressBarGrowthDirection(ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT)
    self.progressionPlacementBarNew:SetPreviousSegmentUnderneathOverlap(-32)
    self.progressionPlacementBarNew.handleNewMatch = true

    if self.playerRankCurrent == TRIBUTE_TIER_UNRANKED then
        self.progressionProgressBarControl:SetHidden(true)
        self.progressionPlacementBarControl:SetHidden(false)
        self.progressionPlacementBarNewControl:SetHidden(false)
        self.progressionPlacementBar:Clear()
        self.progressionPlacementBar:SetMaxSegments(numRequiredPlacementMatches)
        self.progressionPlacementBarNew:Clear()
        self.progressionPlacementBarNew:SetMaxSegments(numRequiredPlacementMatches)
        for i = 1, numRequiredPlacementMatches do
            self.progressionPlacementBar:AddSegment()
            self.progressionPlacementBarNew:AddSegment()
        end
    else
        self.progressionProgressBarControl:SetHidden(false)
        self.progressionPlacementBarControl:SetHidden(true)
        self.progressionPlacementBarNewControl:SetHidden(true)
    end

    self.playerRankNextRequiredXP = GetTributeCampaignRankExperienceRequirement(self.playerRankNext, self.campaignId) - GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent, self.campaignId)
    self.playerCampaignXP = GetTributePlayerCampaignTotalExperience(self.campaignId) - GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent, self.campaignId)
    self.playerCampaignXPDelta = GetPendingCampaignExperience(self.campaignId)
    self.progressionRankChange:SetText(string.format("%+d", self.playerCampaignXPDelta))
    if self.playerRankNew > self.playerRankCurrent then
        self.rankUp = true
    end
    self.progressionProgressBar:SetValue(self.playerRankCurrent, self.playerCampaignXP, self.playerRankNextRequiredXP, WRAP, ANIMATE_INSTANTLY)
    self.playerCampaignXP = self.playerCampaignXP + self.playerCampaignXPDelta

    -- TODO Tribute: Get in-game stats from the game (gold acquired, cards acquired, duration)
    local DEBUG_GOLD_ACQUIRED = 10
    local DEBUG_CARDS_ACQUIRED = 5
    self.playerRankCurrentRewardsData = ZO_TributeRewardsData:New(TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS), self.playerRankCurrent)
    self.playerRankNextRewardsData = ZO_TributeRewardsData:New(TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS), self.playerRankNext)
    self.playerRankNewRewardsData = ZO_TributeRewardsData:New(TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS), self.playerRankNew)

    local numPatrons = self.summaryPatrons:GetNumChildren()
    local patronStalls = TRIBUTE:GetPatronStalls()
    local patronDisplayOrder =
    {
        TRIBUTE_PATRON_DRAFT_ID_FIRST_PLAYER_FIRST_PICK,
        TRIBUTE_PATRON_DRAFT_ID_SECOND_PLAYER_FIRST_PICK,
        TRIBUTE_PATRON_DRAFT_ID_SECOND_PLAYER_SECOND_PICK,
        TRIBUTE_PATRON_DRAFT_ID_FIRST_PLAYER_SECOND_PICK,
    }
    internalassert(numPatrons == #patronDisplayOrder, string.format("Ensure TributeSummary.xml contains the correct number of patrons."))
    for patronIndex = 1, numPatrons do
        local patronDraftId = patronDisplayOrder[patronIndex]
        local patronData = patronStalls[patronDraftId]:GetDataSource()
        if patronData then
            local patron = self.summaryPatrons:GetChild(patronIndex)
            local patronId = patronData.patronId
            local indicator = patron:GetNamedChild("Indicator")
            local nameLabel = patron:GetNamedChild("Label")
            patron:SetTexture(GetTributePatronLargeIcon(patronId))
            indicator:SetTexture(GetTributePatronLargeRingIcon(PatronId))
            nameLabel:SetText(GetTributePatronName(patronId))
            if self.victory then
                indicator:SetTransformRotation(0, 0, ZO_PI)
            end
        end
    end

    -- Match statistics
    self.statisticsDuration:SetText("[DEBUG] MM:ss")
    self.statisticsBackdrop:SetTexture(self.victory and END_OF_GAME_STATISTICS_BACKDROPS.VICTORY or END_OF_GAME_STATISTICS_BACKDROPS.DEFEAT)
    self.statisticsPrestige:SetText(string.format("%d - %d", self.playerPrestige, self.opponentPrestige))
    self.statisticsGold:SetText(DEBUG_GOLD_ACQUIRED)
    self.statisticsCards:SetText(DEBUG_CARDS_ACQUIRED)

    -- Summary
    local headerText = self.victory and GetString(SI_TRIBUTE_MATCH_RESULT_VICTORY) or GetString(SI_TRIBUTE_MATCH_RESULT_DEFEAT)
    self.summaryHeaderLabel:SetText(headerText)
    self.summaryBanner:SetTexture(self.victory and END_OF_GAME_RESULT_BANNERS.VICTORY or END_OF_GAME_RESULT_BANNERS.DEFEAT)
    local playerName = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_SELF)
    local opponentName = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
    self.summaryPlayerLabel:SetText(playerName)
    self.summaryOpponentLabel:SetText(opponentName)
    self.summaryPlayerValue:SetText(self.playerPrestige)
    self.summaryOpponentValue:SetText(self.opponentPrestige)
    local HIDE_PATRONS = self.victoryType ~= TRIBUTE_VICTORY_TYPE_PATRON
    -- If the victory is by concession, we treat it as a prestige victory for purposes of what to display
    local HIDE_PRESTIGE = self.victoryType == TRIBUTE_VICTORY_TYPE_PATRON
    self.summaryControl:GetNamedChild("Patrons"):SetHidden(HIDE_PATRONS)
    self.summaryControl:GetNamedChild("Prestige"):SetHidden(HIDE_PRESTIGE)

    -- Rewards
    local matchStandardRewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(GetTributeGeneralMatchRewardListId())
    local matchLFGRewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(GetTributeGeneralMatchLFGRewardListId())
    local rankUpRewards = {}
    if self.rankUp then
        for rank = self.playerRankCurrent, self.playerRankNew do
            local rankUpRewardList = REWARDS_MANAGER:GetAllRewardInfoForRewardList(GetActiveTributeCampaignTierRewardListId(rank))
            if next(rankUpRewardList) then
                for _, reward in ipairs(rankUpRewardList) do
                    table.insert(rankUpRewards, reward)
                end
            end
        end
    end
    local matchCombinedRewards = {}
    ZO_CombineNumericallyIndexedTables(matchCombinedRewards, matchStandardRewards, matchLFGRewards)
    local MAX_REWARDS_PER_ROW = 4

    local function SetUpRewardsRow(rewardsTable, rowControl, rewardsControlPool)
        local currentRowControl = nil
        local previousControl = nil
        local overflow = #rewardsTable > MAX_REWARDS_PER_ROW
        for rewardIndex, reward in ipairs(rewardsTable) do
            local control = rewardsControlPool:AcquireObject()
            if not overflow or rewardIndex < MAX_REWARDS_PER_ROW then
                local rewardType = reward.rewardType
                local name = reward.rawName
                local count = reward.quantity
                local qualityColorDef = nil
                local countText = ""
                if rewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
                    name = zo_strformat(SI_CURRENCY_CUSTOM_TOOLTIP_FORMAT, ZO_Currency_GetAmountLabel(id))
                    icon = ZO_Currency_GetPlatformCurrencyLootIcon(id)
                    local USE_SHORT_FORMAT = true
                    countText = ZO_CurrencyControl_FormatAndLocalizeCurrency(count, USE_SHORT_FORMAT)
                else
                    name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
                    qualityColorDef = GetItemQualityColor(reward.quality)

                    if count > 1 then
                        countText = tostring(count)
                    end
                end

                if qualityColorDef then
                    name = qualityColorDef:Colorize(name)
                end

                control.nameLabel:SetText(name)
                control.iconTexture:SetTexture(reward.icon)
                control.stackCountLabel:SetText(countText)
            else
                local genericItemTexture = "" --TODO Tribute: Get an actual texture path from Vince
                local numAdditionalRewards = #rewardsTable - (MAX_REWARDS_PER_ROW - 1)
                control.nameLabel:SetText(zo_strformat(SI_TRIBUTE_SUMMARY_REWARD_OVERFLOW, numAdditionalRewards))
                control.iconTexture:SetTexture(genericItemTexture)
            end

            control:SetParent(rowControl)

            --If this is not the first control, put it to the right of the previous control, otherwise anchor it to the top left of the row
            if previousControl then
                control:SetAnchor(TOPLEFT, previousControl, TOPRIGHT, 40, 0)
            else
                control:SetAnchor(TOPLEFT)
            end

            previousControl = control

            if rewardIndex >= MAX_REWARDS_PER_ROW then
                break
            end
        end
    end

    local matchRewardsRowControl = self.rewardRowControlPool:AcquireObject(REWARDS_MATCH_KEY)
    matchRewardsRowControl:SetAnchor(TOP, nil, TOP, 0, 0)
    SetUpRewardsRow(matchCombinedRewards, matchRewardsRowControl, self.rewardsControlPool)
    self.matchRewardItemsInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeRewardItemsWipeIn", matchRewardsRowControl)
    self.matchRewardItemsInTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.matchRewardItemsInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
    matchRewardsRowControl:SetMaskAnchor(TOPLEFT, BOTTOMLEFT)
    matchRewardsRowControl:SetAnimation(self.matchRewardItemsInTimeline:GetAnimation(1))
    matchRewardsRowControl.maskSimulator:SetScale(0)
    matchRewardsRowControl:SetHidden(true)

    if self.rankUp then
        local rankUpRewardsRowControl = self.rewardRowControlPool:AcquireObject(REWARDS_RANK_UP_KEY)
        rankUpRewardsRowControl:SetAnchor(TOP, matchRewardsRowControl, BOTTOM, 0, 20)
        SetUpRewardsRow(rankUpRewards, rankUpRewardsRowControl, self.rewardsControlPool)
        self.rankUpItemsInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeRewardItemsWipeIn", rankUpRewardsRowControl)
        self.rankUpItemsInTimeline:SetAllAnimationOffsets(0)
        self.rankUpItemsInTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
        local function OnCompleteFireTrigger(_, completedPlaying)
            if completedPlaying then
                self.fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
            end
        end
        self.rankUpItemsInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
        self.rankUpItemsInTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
        rankUpRewardsRowControl:SetMaskAnchor(TOPLEFT, BOTTOMLEFT)
        rankUpRewardsRowControl:SetAnimation(self.rankUpItemsInTimeline:GetAnimation(1))
        rankUpRewardsRowControl:SetHidden(true)
    end

    -- Progression
    self.progressionCurrentRankIcon:SetTexture(self.playerRankCurrentRewardsData:GetTierIcon())
    self.progressionCurrentRankLabel:SetText(self.playerRankCurrentRewardsData:GetTierName())
    self.progressionNextRankIcon:SetTexture(self.playerRankNextRewardsData:GetTierIcon())
    self.progressionNextRankLabel:SetText(self.playerRankNextRewardsData:GetTierName())

    self.fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.BEGIN)
end

function ZO_TributeSummary:HandleCommand(command)
    self.fanfareStateMachine:FireCallbacks(command)
end

function ZO_TributeSummary:OnUsePrimaryAction()
    if not self.keybindButton:IsHidden() then
        self.keybindButton:OnClicked()
    end
end

function ZO_TributeSummary_OnInitialized(control)
    TRIBUTE_SUMMARY = ZO_TributeSummary:New(control)
end

function ZO_TributeSummary_ClubRankProgressBar_Keyboard_OnMouseEnter(control)
    if not IsInGamepadPreferredMode() then
        local clubRank = GetTributePlayerClubRank()
        local currentClubExperienceForRank, maxClubExperienceForRank = GetTributePlayerExperienceInCurrentClubRank()
        InitializeTooltip(InformationTooltip, control, TOP, 0, 10)
        SetTooltipText(InformationTooltip, GetString("SI_TRIBUTECLUBRANK", clubRank))
        --If the maximum club experience for this rank is 0, then we are maxed out
        if maxClubExperienceForRank == 0 then
            InformationTooltip:AddLine(GetString(SI_TRIBUTE_CLUB_EXPERIENCE_LIMIT_REACHED))
        else
            local percentageXp = zo_floor(currentClubExperienceForRank / maxClubExperienceForRank * 100)
            InformationTooltip:AddLine(zo_strformat(SI_TRIBUTE_CLUB_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(currentClubExperienceForRank), ZO_CommaDelimitNumber(maxClubExperienceForRank), percentageXp))
        end
    end
end

function ZO_TributeSummary_ClubRankProgressBar_Keyboard_OnMouseExit()
    ClearTooltip(InformationTooltip)
end