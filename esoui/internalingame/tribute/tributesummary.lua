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
local PROGRESS_TRANSLATION_ANIMATION_TIME_MS = 500
local REWARD_WIPE_PER_ITEM_DURATION_MS = 300
local REWARD_ROW_OFFSET_Y = 40

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
    self.statisticsPrestige = self.statisticsBackdrop:GetNamedChild("PrestigeLabel")
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
    self.clubRankIcon = self.clubRankContainer:GetNamedChild("Icon")
    self.clubRankTypeLabel = self.clubRankContainer:GetNamedChild("RankType")
    self.clubRankBarControl = self.clubRankContainer:GetNamedChild("Bar")
    local function OnBarRankChanged(_, rank)
        self.clubRankLabel:SetText(rank + 1)
        self.clubRankTypeLabel:SetText(zo_strformat(GetString("SI_TRIBUTECLUBRANK", rank)))
        self.clubRankIcon:SetTexture(string.format("EsoUI/Art/Tribute/tributeClubRank_%d.dds", rank))
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
        control.mailIndicatorIcon = control.iconTexture:GetNamedChild("MailIndicator")
        control.nameLabel = control:GetNamedChild("Name")

        SetupControlStyleTemplating(control, "ZO_TributeRewardItem_Control")
    end)
    self.rewardsControlPool:SetCustomResetBehavior(function(control)
        control.mailIndicatorIcon:SetHidden(true)
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

    self.progressionLeaderboardBackdrop = self.progressionControl:GetNamedChild("LeaderboardBackdrop")
    self.progressionLeaderboardBackdrop:SetMaskAnchor(TOPLEFT, BOTTOMLEFT)
    self.progressionRankChange = self.progressionControl:GetNamedChild("RankChange")
    self.progressionProgressBarControl = self.progressionControl:GetNamedChild("ProgressBar")
    self.progressionProgressBar = ZO_WrappingStatusBar:New(self.progressionProgressBarControl)
    self.progressionProgressNumber = self.progressionProgressBarControl:GetNamedChild("ProgressNumber")
    self.progressionProgressNumberTranslateTimeline = ANIMATION_MANAGER:CreateTimeline()
    self.progressionProgressNumberTranslateAnimation = self.progressionProgressNumberTranslateTimeline:InsertAnimation(ANIMATION_TRANSLATE, self.progressionProgressNumber)
    local progressNumberTranslateY = 20
    self.progressionProgressNumberTranslateAnimation:SetStartOffsetY(progressNumberTranslateY)
    self.progressionProgressNumberTranslateAnimation:SetEndOffsetY(progressNumberTranslateY)
    self.progressionProgressNumberFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionProgressNumber)
    self.progressionProgressNumberFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionProgressNumber)
    self.progressionProgressBar:SetAnimationTime(PROGRESS_TRANSLATION_ANIMATION_TIME_MS)
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
    self.progressionLeaderboardWipeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeLeaderboardWipeIn", self.progressionLeaderboardBackdrop)
    self.progressionLeaderboardWipeInTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.progressionLeaderboardBackdrop:SetAnimation(self.progressionLeaderboardWipeInTimeline:GetAnimation(1))
    self.progressionLeaderboardLossBounceTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeLeaderboardLossBounce", self.progressionLeaderboardBackdrop)
    self.progressionLeaderboardWinBounceTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeLeaderboardWinBounce", self.progressionLeaderboardBackdrop)
    self.progressionNextRankBounceTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeNextRankBounce", self.progressionNextRankIcon)
    self.progressionRankUpScaleTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeRankUpScale", self.progressionRankUpIndicator)
    self.progressionRankUpScaleTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.progressionRankUpFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionRankUpIndicator)
    self.progressionCurrentRankFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionCurrentRankIcon)
    self.progressionNextRankFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeOut", self.progressionNextRankIcon)
    self.progressionCurrentRankFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionCurrentRankIcon)
    self.progressionNextRankFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeEndOfGameFadeIn", self.progressionNextRankIcon)

    self:InitializeParticleSystems()
end

function ZO_TributeSummary:InitializeParticleSystems()
    local particleR, particleG, particleB = ZO_OFF_WHITE:UnpackRGB()
    local FULL_CIRCLE_RADIANS = math.rad(360)

    local nextRankParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    nextRankParticleSystem:SetParentControl(self.progressionNextRankIcon:GetNamedChild("NextRankIconFlareContainer"))
    nextRankParticleSystem:SetParticlesPerSecond(20)
    nextRankParticleSystem:SetStartPrimeS(2)
    nextRankParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/Miscellaneous/lensflare_star_256.dds")
    nextRankParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    nextRankParticleSystem:SetParticleParameter("StartAlpha", 0)
    nextRankParticleSystem:SetParticleParameter("EndAlpha", 1)
    nextRankParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    nextRankParticleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1.5, 1.8))
    nextRankParticleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(1.05, 1.5))
    nextRankParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 2))
    nextRankParticleSystem:SetParticleParameter("StartColorR", particleR)
    nextRankParticleSystem:SetParticleParameter("StartColorG", particleG)
    nextRankParticleSystem:SetParticleParameter("StartColorB", particleB)
    nextRankParticleSystem:SetParticleParameter("StartRotationRadians", ZO_UniformRangeGenerator:New(0, FULL_CIRCLE_RADIANS))
    local MIN_ROTATION_SPEED = math.rad(1.5)
    local MAX_ROTATION_SPEED = math.rad(3)
    local headerStarbustRotationSpeedGenerator = ZO_WeightedChoiceGenerator:New(
        MIN_ROTATION_SPEED , 0.25,
        MAX_ROTATION_SPEED , 0.25,
        -MIN_ROTATION_SPEED, 0.25,
        -MAX_ROTATION_SPEED, 0.25)

    nextRankParticleSystem:SetParticleParameter("RotationSpeedRadians", headerStarbustRotationSpeedGenerator)
    nextRankParticleSystem:SetParticleParameter("Size", 256)
    nextRankParticleSystem:SetParticleParameter("DrawLevel", 0)

    self.nextRankParticleSystem = nextRankParticleSystem

    local rankUpParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    rankUpParticleSystem:SetParentControl(self.progressionRankUpIndicator:GetNamedChild("RankUpFlareContainer"))
    rankUpParticleSystem:SetParticlesPerSecond(20)
    rankUpParticleSystem:SetStartPrimeS(2)
    rankUpParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/Miscellaneous/lensflare_star_256.dds")
    rankUpParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    rankUpParticleSystem:SetParticleParameter("StartAlpha", 0)
    rankUpParticleSystem:SetParticleParameter("EndAlpha", 1)
    rankUpParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    rankUpParticleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1.5, 1.8))
    rankUpParticleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(1.05, 1.5))
    rankUpParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 2))
    rankUpParticleSystem:SetParticleParameter("StartColorR", particleR)
    rankUpParticleSystem:SetParticleParameter("StartColorG", particleG)
    rankUpParticleSystem:SetParticleParameter("StartColorB", particleB)
    rankUpParticleSystem:SetParticleParameter("StartRotationRadians", ZO_UniformRangeGenerator:New(0, FULL_CIRCLE_RADIANS))
    rankUpParticleSystem:SetParticleParameter("RotationSpeedRadians", headerStarbustRotationSpeedGenerator)
    rankUpParticleSystem:SetParticleParameter("Size", 256)
    rankUpParticleSystem:SetParticleParameter("DrawLevel", 0)

    self.rankUpParticleSystem = rankUpParticleSystem

    local leaderboardParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    leaderboardParticleSystem:SetParentControl(self.progressionControl:GetNamedChild("LeaderboardFlareContainer"))
    leaderboardParticleSystem:SetParticlesPerSecond(5)
    leaderboardParticleSystem:SetStartPrimeS(2)
    leaderboardParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/Miscellaneous/lensflare_burst_512.dds")
    leaderboardParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    leaderboardParticleSystem:SetParticleParameter("StartAlpha", 0)
    leaderboardParticleSystem:SetParticleParameter("EndAlpha", 1)
    leaderboardParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    leaderboardParticleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1.5, 1.8))
    leaderboardParticleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(1.05, 1.5))
    leaderboardParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 2))
    leaderboardParticleSystem:SetParticleParameter("StartColorR", particleR)
    leaderboardParticleSystem:SetParticleParameter("StartColorG", particleG)
    leaderboardParticleSystem:SetParticleParameter("StartColorB", particleB)
    leaderboardParticleSystem:SetParticleParameter("StartRotationRadians", 0)--FULL_CIRCLE_RADIANS / 2))
    local MIN_ROTATION_SPEED = math.rad(1.5)
    local MAX_ROTATION_SPEED = math.rad(3)
    local headerStarbustRotationSpeedGenerator = ZO_WeightedChoiceGenerator:New(
        MIN_ROTATION_SPEED , 0.25,
        MAX_ROTATION_SPEED , 0.25,
        -MIN_ROTATION_SPEED, 0.25,
        -MAX_ROTATION_SPEED, 0.25)

    leaderboardParticleSystem:SetParticleParameter("RotationSpeedRadians", headerStarbustRotationSpeedGenerator)
    leaderboardParticleSystem:SetParticleParameter("Width", 512)
    leaderboardParticleSystem:SetParticleParameter("Height", 128)
    leaderboardParticleSystem:SetParticleParameter("DrawLevel", 0)

    self.leaderboardParticleSystem = leaderboardParticleSystem
end

function ZO_TributeSummary:InitializeStateMachine()
    local fanfareStateMachine = ZO_StateMachine_Base:New("TRIBUTE_FANFARE_STATE_MACHINE")
    self.fanfareStateMachine = fanfareStateMachine
    local IGNORE_ANIMATION_CALLBACKS = true

    -- States
    do
        local state = fanfareStateMachine:AddState("INACTIVE")
        state:RegisterCallback("OnActivated", function()
            self.hasRankUpRewards = false
            local headerControl = self.rewardsControl:GetNamedChild("Header")
            local offsetX = 0
            local offsetY = 440
            self.rewardItemsControl:SetAnchor(TOP, headerControl, BOTTOM, offsetX, offsetY)
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
            self.clubRankContainer:SetHidden(true)
            self.rewardItemsControl:SetHidden(true)
            self.progressionControl:SetHidden(true)
            self.progressionLeaderboardBackdrop:SetHidden(true)
            self.progressionRankChange:SetHidden(true)
            self.progressionRankUpIndicator:SetHidden(true)
            self.nextRankParticleSystem:Stop()
            self.rankUpParticleSystem:Stop()
            self.leaderboardParticleSystem:Stop()
            self.rewardsControlPool:ReleaseAllObjects()
        end)
    end

    do
        local state = fanfareStateMachine:AddState("BEGIN")
        state:RegisterCallback("OnActivated", function()
            self.modalUnderlayTimeline:PlayFromStart()
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
            if self.victory then
                PlaySound(SOUNDS.TRIBUTE_SUMMARY_BEGIN_VICTORY)
            else
                PlaySound(SOUNDS.TRIBUTE_SUMMARY_BEGIN_DEFEAT)
            end
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
                if self.playerClubXP > 0 then
                    currentClubExperienceForRank = currentClubExperienceForRank + self.playerClubXP
                    if currentClubExperienceForRank > maxClubExperienceForRank then
                        currentClubExperienceForRank = currentClubExperienceForRank - maxClubExperienceForRank
                        clubRank = clubRank + 1
                        local clubExperienceForNextRank = GetTributeClubRankExperienceRequirement(clubRank + 1)
                        if clubExperienceForNextRank ~= 0 then
                            maxClubExperienceForRank = clubExperienceForNextRank - GetTributeClubRankExperienceRequirement(clubRank)
                        else
                            maxClubExperienceForRank = 0
                        end
                        if maxClubExperienceForRank == 0 then
                            self.clubRankBar:SetValue(clubRank, 1, 1, NO_WRAP, ANIMATE_FULLY)
                        else
                            self.clubRankBar:SetValue(clubRank, currentClubExperienceForRank, maxClubExperienceForRank, WRAP, ANIMATE_FULLY)
                        end
                    else
                        self.clubRankBar:SetValue(clubRank, currentClubExperienceForRank, maxClubExperienceForRank, NO_WRAP, ANIMATE_FULLY)
                    end
                end
            end
            self.rewardsControl:SetHidden(false)
            self.clubRankContainer:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            self.rewardsHeaderInTimeline:PlayFromStart()
            self.statisticsInTimeline:PlayFromStart()
            self.matchRewardItemsInTimeline:PlayFromStart()
            if self.hasRankUpRewards then
                self.rankUpItemsInTimeline:SetAllAnimationOffsets(self.rewardsHeaderInTimeline:GetDuration())
                self.rewardRowControlPool:GetActiveObject(REWARDS_RANK_UP_KEY):SetHidden(false)
                self.rankUpItemsInTimeline:PlayFromStart()
            end
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
            if self.hasRankUpRewards and self.rankUpItemsInTimeline:IsPlaying() then
                self.rankUpItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
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
            if self.hasRankUpRewards then
                self.rewardRowControlPool:GetActiveObject(REWARDS_RANK_UP_KEY):SetHidden(false)
                self.rankUpItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
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
            self.rewardItemsControl:SetAnchor(TOP, self.progressionControl:GetNamedChild("Divider"), BOTTOM, offsetX, REWARD_ROW_OFFSET_Y)

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
                self.nextRankParticleSystem:Start()
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
            local playerCampaignXPNext = self.playerRankNextRequiredXP
            local wrapType = WRAP
            local animationType = ANIMATE_FULLY
            if self.rankUp then
                playerCampaignXPNew = self.playerRankNextRequiredXP
            elseif self.playerRankCurrent == TRIBUTE_TIER_PLATINUM then
                playerCampaignXPNew = 1
                playerCampaignXPNext = 1
                wrapType = NO_WRAP
                animationType = ANIMATE_INSTANTLY
            end

            if self.playerRankCurrent == TRIBUTE_TIER_UNRANKED then
                self.progressionPlacementBarNewFadeInTimeline:PlayFromStart()
                if self.victory then
                    PlaySound(SOUNDS.TRIBUTE_SUMMARY_PLACEMENT_MATCH_SEGMENT_FILL_VICTORY)
                else
                    PlaySound(SOUNDS.TRIBUTE_SUMMARY_PLACEMENT_MATCH_SEGMENT_FILL_DEFEAT)
                end
            else
                self.progressionProgressNumberTranslateTimeline:PlayFromStart()
                self.progressionProgressBar:SetValue(self.playerRankCurrent, playerCampaignXPNew, playerCampaignXPNext, wrapType, animationType)
                -- If we don't animate the bar, we need to trigger the animation completion manually.
                if animationType == ANIMATE_INSTANTLY then
                    fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
                else
                    -- Only play the bar fill sound when we actually animate bar progress.
                    if self.playerCampaignXPDelta > 0 then
                        PlaySound(SOUNDS.TRIBUTE_SUMMARY_PROGRESS_BAR_INCREASE)
                    elseif self.playerCampaignXPDelta < 0 then
                        PlaySound(SOUNDS.TRIBUTE_SUMMARY_PROGRESS_BAR_DECREASE)
                    end
                end
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("RANK_UP_IN")
        state:RegisterCallback("OnActivated", function()
            self.progressionRankUpIndicator:SetTexture(self.playerRankNewRewardsData:GetTierIcon())
            self.progressionRankUpIndicator:GetNamedChild("NewRankLabel"):SetText(self.playerRankNewRewardsData:GetTierName())
            self.progressionRankUpIndicator:SetHidden(false)
            self.progressionRankUpScaleTimeline:PlayFromStart()
            self.rankUpParticleSystem:Start()
            if self.playerRankNew == TRIBUTE_TIER_PLATINUM then
                PlaySound(SOUNDS.TRIBUTE_SUMMARY_RANK_CHANGE_LEADERBOARD)
            else
                PlaySound(SOUNDS.TRIBUTE_SUMMARY_RANK_CHANGE)
            end
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
            self.progressionProgressNumberFadeOutTimeline:PlayFromStart()
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
            if self.progressionProgressNumberFadeOutTimeline:IsPlaying() then
                self.progressionProgressNumberFadeOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("NEW_RANKS_FADE_IN")
        state:RegisterCallback("OnActivated", function()
            self.nextRankParticleSystem:Stop()
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
                local playerXP = self.playerCampaignXP + GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent, self.campaignKey) - GetTributeCampaignRankExperienceRequirement(self.playerRankNew, self.campaignKey)
                local requiredXP = zo_max(1, GetTributeCampaignRankExperienceRequirement(self.playerRankNew + 1, self.campaignKey) - GetTributeCampaignRankExperienceRequirement(self.playerRankNew, self.campaignKey))
                self.progressionProgressNumber:SetText(string.format("%d / %d", playerXP, self.playerRankNextRequiredXP))
                self.progressionProgressNumberTranslateAnimation:SetStartOffsetX(0)
                self.progressionProgressNumberTranslateAnimation:SetEndOffsetX(playerXP / requiredXP * self.progressionProgressBarControl:GetWidth())
            end

            if self.playerRankNext == TRIBUTE_TIER_PLATINUM then
                self.progressionNextRankIcon:SetHidden(true)
                self.progressionNextRankLabel:SetHidden(true)
            end

            self.progressionProgressBarFadeInTimeline:PlayFromStart()
            self.progressionCurrentRankFadeInTimeline:PlayFromStart()
            self.progressionNextRankFadeInTimeline:PlayFromStart()
            self.progressionProgressNumberTranslateTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.progressionProgressNumberFadeInTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.progressionProgressBarFadeInTimeline:IsPlaying() then
                self.progressionProgressBarFadeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionCurrentRankFadeInTimeline:IsPlaying() then
                self.progressionCurrentRankFadeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionNextRankFadeInTimeline:IsPlaying() then
                self.progressionNextRankFadeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            if self.progressionProgressNumberFadeInTimeline:IsPlaying() then
                self.progressionProgressNumberFadeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("NEW_RANK_PROGRESS_BAR_IN")
        state:RegisterCallback("OnActivated", function()
            self.playerCampaignXP = zo_max(0, self.playerCampaignXP + GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent) - GetTributeCampaignRankExperienceRequirement(self.playerRankNew))
            local playerCampaignXPNew = self.playerCampaignXP

            self.playerRankCurrent = self.playerRankNew
            if self.playerRankNew ~= TRIBUTE_TIER_PLATINUM then
                self.playerRankNext = self.playerRankNew + 1
            end

            self.playerRankNextRequiredXP = GetTributeCampaignRankExperienceRequirement(self.playerRankNext) - GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent)
            local playerCampaignXPNext = self.playerRankNextRequiredXP
            if self.playerRankNew == TRIBUTE_TIER_PLATINUM then
                playerCampaignXPNew = 1
                playerCampaignXPNext = 1
            end
            self.progressionProgressBar:SetValue(self.playerRankCurrent, playerCampaignXPNew, playerCampaignXPNext, WRAP, ANIMATE_FULLY)
            self.progressionProgressNumberTranslateTimeline:PlayFromStart()
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

                self.playerCampaignXP = zo_max(0, self.playerCampaignXP + GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent) - GetTributeCampaignRankExperienceRequirement(self.playerRankNew))
                self.playerRankCurrent = self.playerRankNew
                if self.playerRankNew ~= TRIBUTE_TIER_PLATINUM then
                    self.playerRankNext = self.playerRankNew + 1
                else
                    self.progressionNextRankIcon:SetHidden(true)
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
            self.rewardItemsControl:SetAnchor(TOP, self.progressionControl:GetNamedChild("Divider"), BOTTOM, offsetX, REWARD_ROW_OFFSET_Y)

            self.progressionProgressBar:SetValue(self.playerRankCurrent, self.playerCampaignXP, self.playerRankNextRequiredXP, NO_WRAP, ANIMATE_INSTANTLY)

            self.rewardsControl:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            local rankUpRewardsRow = self.rewardRowControlPool:GetActiveObject(REWARDS_RANK_UP_KEY)
            if rankUpRewardsRow then
                rankUpRewardsRow:SetHidden(false)
                self.rankUpItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            self.nextRankParticleSystem:Stop()
            self.progressionControl:SetHidden(false)
            self.progressionRankChange:SetHidden(self.rankUp or self.playerRankCurrent == TRIBUTE_TIER_UNRANKED)
            self.progressionRankUpIndicator:SetHidden(not self.rankUp)
            local progressFinal = self.playerCampaignXP / zo_max(1, self.playerRankNextRequiredXP)
            self.progressionProgressNumber:SetText(string.format("%d / %d", self.playerCampaignXP, self.playerRankNextRequiredXP))
            local width = self.progressionProgressBarControl:GetWidth()
            local xFinal = progressFinal * width
            self.progressionProgressNumberTranslateAnimation:SetEndOffsetX(xFinal)
            self.progressionProgressNumberTranslateTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionProgressNumber:SetHidden(self.playerRankCurrent == TRIBUTE_TIER_UNRANKED)
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
            self.progressionLeaderboardBackdrop:SetHidden(false)
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
                self.leaderboardParticleSystem:Start()
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
            local offsetX = 0
            self.rewardItemsControl:SetAnchor(TOP, self.progressionControl:GetNamedChild("Divider"), BOTTOM, offsetX, REWARD_ROW_OFFSET_Y)

            self.rewardsControl:SetHidden(false)
            self.statisticsControl:SetHidden(false)
            self.rewardItemsControl:SetHidden(false)
            self.progressionNextRankIcon:SetHidden(true)
            self.rewardRowControlPool:GetActiveObject(REWARDS_MATCH_KEY):SetHidden(false)
            local rankUpRewardsRow = self.rewardRowControlPool:GetActiveObject(REWARDS_RANK_UP_KEY)
            if rankUpRewardsRow then
                rankUpRewardsRow:SetHidden(false)
                self.rankUpItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            self.nextRankParticleSystem:Stop()
            self.progressionControl:SetHidden(false)
            self.progressionRankChange:SetHidden(true)
            self.progressionProgressBar:SetValue(self.playerRankCurrent, 1, 1, NO_WRAP, ANIMATE_INSTANTLY)
            self.progressionLeaderboardBackdrop:SetHidden(false)
            self.progressionLeaderboardWipeInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.rewardsHeaderInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.statisticsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.matchRewardItemsInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionInTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            self.progressionRankChangeUpTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            if self.victory then
                self.progressionLeaderboardLossBounceTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
                self.leaderboardParticleSystem:Start()
            else
                self.progressionLeaderboardWinBounceTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    do
        local state = fanfareStateMachine:AddState("QUIT")
        state:RegisterCallback("OnActivated", function()
            SCENE_MANAGER:RequestShowLeaderBaseScene()
        end)
    end

    -- Edges
    do
        fanfareStateMachine:AddEdgeAutoName("INACTIVE", "BEGIN")
        fanfareStateMachine:AddEdgeAutoName("BEGIN", "SUMMARY_IN")
        fanfareStateMachine:AddEdgeAutoName("SUMMARY_IN", "SUMMARY")
        fanfareStateMachine:AddEdge("SUMMARY_IN_TO_SUMMARY_SKIP", "SUMMARY_IN", "SUMMARY")
        fanfareStateMachine:AddEdgeAutoName("SUMMARY", "SUMMARY_OUT")
        local summaryToQuitInEdge = fanfareStateMachine:AddEdgeAutoName("SUMMARY_OUT", "QUIT")
        summaryToQuitInEdge:SetConditional(function()
            return not (self.hasRewards or self.isRanked)
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
        local progressionInRankUpRewardsInEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_IN", "RANK_UP_REWARDS_IN")
        progressionInRankUpRewardsInEdge:SetConditional(function()
            return self.hasRankUpRewards and not self.rankUp
        end)
        local progressionInRankChangeInEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_IN", "RANK_CHANGE_IN")
        progressionInRankChangeInEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_UNRANKED and not (self.hasRankUpRewards and not self.rankUp)
        end)
        local progressionInProgressBarInEdge = fanfareStateMachine:AddEdgeAutoName("PROGRESSION_IN", "PROGRESSION_PROGRESS_BAR_IN")
        progressionInProgressBarInEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_UNRANKED and not (self.hasRankUpRewards and not self.rankUp)
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
            return (not self.rankUp) and self.playerRankCurrent == TRIBUTE_TIER_PLATINUM
        end)
        local rankChangeLeaderboardSkipEdge = fanfareStateMachine:AddEdge("RANK_CHANGE_OUT_TO_LEADERBOARD_SKIP", "RANK_CHANGE_OUT", "LEADERBOARD")
        rankChangeLeaderboardSkipEdge:SetConditional(function()
            return (not self.rankUp) and self.playerRankCurrent == TRIBUTE_TIER_PLATINUM
        end)
        local rankChangeRankUpInEdge = fanfareStateMachine:AddEdgeAutoName("RANK_CHANGE_OUT", "RANK_UP_IN")
        rankChangeRankUpInEdge:SetConditional(function()
            return self.rankUp
        end)
        local rankChangeRankUpSkipEdge = fanfareStateMachine:AddEdgeAutoName("RANK_CHANGE_OUT", "RANK_UP_SKIP")
        rankChangeRankUpSkipEdge:SetConditional(function()
            return self.rankUp
        end)
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_IN", "RANK_UP_REWARDS_IN")
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_IN", "RANK_UP_SKIP")
        local rankUpRewardsInRankChangeInEdge = fanfareStateMachine:AddEdgeAutoName("RANK_UP_REWARDS_IN", "RANK_CHANGE_IN")
        rankUpRewardsInRankChangeInEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_UNRANKED and not self.rankUp
        end)
        local rankUpRewardsInProgressBarInEdge = fanfareStateMachine:AddEdgeAutoName("RANK_UP_REWARDS_IN", "PROGRESSION_PROGRESS_BAR_IN")
        rankUpRewardsInProgressBarInEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_UNRANKED and not self.rankUp
        end)
        local rankUpRewardsInOldRanksFadeOutEdge = fanfareStateMachine:AddEdgeAutoName("RANK_UP_REWARDS_IN", "OLD_RANKS_FADE_OUT")
        rankUpRewardsInOldRanksFadeOutEdge:SetConditional(function()
            return self.rankUp
        end)
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_REWARDS_IN", "RANK_UP_SKIP")
        fanfareStateMachine:AddEdgeAutoName("OLD_RANKS_FADE_OUT", "NEW_RANKS_FADE_IN")
        fanfareStateMachine:AddEdgeAutoName("OLD_RANKS_FADE_OUT", "RANK_UP_SKIP")
        fanfareStateMachine:AddEdgeAutoName("NEW_RANKS_FADE_IN", "NEW_RANK_PROGRESS_BAR_IN")
        fanfareStateMachine:AddEdgeAutoName("NEW_RANKS_FADE_IN", "RANK_UP_SKIP")
        local newProgressBarInRankUpOutEdge = fanfareStateMachine:AddEdgeAutoName("NEW_RANK_PROGRESS_BAR_IN", "RANK_UP_OUT")
        newProgressBarInRankUpOutEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_PLATINUM or (self.rankUp and self.playerRankNew == TRIBUTE_TIER_PLATINUM)
        end)
        local newProgressBarInNoLeaderboardEdge = fanfareStateMachine:AddEdgeAutoName("NEW_RANK_PROGRESS_BAR_IN", "NO_LEADERBOARD")
        newProgressBarInNoLeaderboardEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM and not (self.rankUp and self.playerRankNew == TRIBUTE_TIER_PLATINUM)
        end)
        local newProgressBarInNoLeaderboardSkipEdge = fanfareStateMachine:AddEdge("NEW_RANK_PROGRESS_BAR_IN_TO_NO_LEADERBOARD_SKIP", "NEW_RANK_PROGRESS_BAR_IN", "NO_LEADERBOARD")
        newProgressBarInNoLeaderboardSkipEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM and not (self.rankUp and self.playerRankNew == TRIBUTE_TIER_PLATINUM)
        end)
        local rankUpSkipNoLeaderboardEdge = fanfareStateMachine:AddEdgeAutoName("RANK_UP_SKIP", "NO_LEADERBOARD")
        rankUpSkipNoLeaderboardEdge:SetConditional(function()
            return self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM and not (self.rankUp and self.playerRankNew == TRIBUTE_TIER_PLATINUM)
        end)
        local rankUpSkipLeaderboardEdge = fanfareStateMachine:AddEdgeAutoName("RANK_UP_SKIP", "LEADERBOARD")
        rankUpSkipLeaderboardEdge:SetConditional(function()
            return self.playerRankCurrent == TRIBUTE_TIER_PLATINUM or (self.rankUp and self.playerRankNew == TRIBUTE_TIER_PLATINUM)
        end)
        fanfareStateMachine:AddEdgeAutoName("RANK_UP_OUT", "LEADERBOARD_IN")
        fanfareStateMachine:AddEdge("RANK_UP_OUT_TO_LEADERBOARD_SKIP", "RANK_UP_OUT", "LEADERBOARD")
        fanfareStateMachine:AddEdgeAutoName("LEADERBOARD_IN", "LEADERBOARD_BOUNCE_IN")
        fanfareStateMachine:AddEdge("LEADERBOARD_IN_TO_LEADERBOARD_SKIP", "LEADERBOARD_IN", "LEADERBOARD")
        fanfareStateMachine:AddEdgeAutoName("LEADERBOARD_BOUNCE_IN", "LEADERBOARD")
        fanfareStateMachine:AddEdge("LEADERBOARD_BOUNCE_IN_TO_LEADERBOARD_SKIP", "LEADERBOARD_BOUNCE_IN", "LEADERBOARD")
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
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "PROGRESSION_IN_TO_RANK_UP_REWARDS_IN")
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
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LEADERBOARD_TRANSITORY_STATE_TO_LEADERBOARD")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LEADERBOARD_TRANSITORY_STATE_TO_NO_LEADERBOARD")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_UP_SKIP_TO_NO_LEADERBOARD")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_UP_SKIP_TO_LEADERBOARD")

    -- The player has just attained leaderboard rank
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "RANK_UP_OUT_TO_LEADERBOARD_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_UP_OUT_TO_LEADERBOARD_SKIP")

    -- The player is already on the leaderboard
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "RANK_CHANGE_OUT_TO_LEADERBOARD_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "RANK_CHANGE_OUT_TO_LEADERBOARD_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "LEADERBOARD_IN_TO_LEADERBOARD_BOUNCE_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LEADERBOARD_IN_TO_LEADERBOARD_SKIP")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "LEADERBOARD_BOUNCE_IN_TO_LEADERBOARD")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LEADERBOARD_BOUNCE_IN_TO_LEADERBOARD_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LEADERBOARD_TO_QUIT")

    -- Animation callbacks --
    local function OnCompleteFireTrigger(_, completedPlaying)
        if completedPlaying then
            fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
        end
    end

    local function OnProgressBarCompleteFireTrigger()
        fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
    end

    self.summaryInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.summaryOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.rewardsOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionRankChangeUpTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionRankChangeFadeOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionProgressBar:SetOnCompleteCallback(OnProgressBarCompleteFireTrigger)
    self.progressionPlacementBarNewFadeInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionLeaderboardWipeInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionLeaderboardLossBounceTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionLeaderboardWinBounceTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionRankUpScaleTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionCurrentRankFadeOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionCurrentRankFadeInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.progressionRankUpFadeOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)

    -- Reset state machine
    self.fanfareStateMachine:SetCurrentState("INACTIVE")
end

function ZO_TributeSummary:ApplyPlatformStyle()
    ApplyTemplateToControl(self.statisticsControl, ZO_GetPlatformTemplate("ZO_TributeSummary_Statistics"))
    ApplyTemplateToControl(self.keybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    ApplyTemplateToControl(self.summaryControl, ZO_GetPlatformTemplate("ZO_TributeSummary_TributeStatus"))
    ApplyTemplateToControl(self.rewardsControl, ZO_GetPlatformTemplate("ZO_TributeSummary_TributeReward"))
    ApplyTemplateToControl(self.progressionControl, ZO_GetPlatformTemplate("ZO_TributeSummary_TributeProgression"))

    -- We have to rebuild the placement match bars from scratch if we change style templates.
    if self.progressionPlacementBar and not self.progressionPlacementBarControl:IsHidden() then
        local numRequiredPlacementMatches = GetNumRequiredPlacementMatches(self.campaignKey)
        self.progressionPlacementBar:SetSegmentTemplate(ZO_GetPlatformTemplate("ZO_TributeSummary_ArrowStatusBar"))
        self.progressionPlacementBar:SetMaxSegments(numRequiredPlacementMatches)
        self.progressionPlacementBarNew:SetSegmentTemplate(ZO_GetPlatformTemplate("ZO_TributeSummary_ArrowStatusBar"))
        self.progressionPlacementBarNew:SetMaxSegments(numRequiredPlacementMatches)
        for i = 1, numRequiredPlacementMatches do
            self.progressionPlacementBar:AddSegment()
            self.progressionPlacementBarNew:AddSegment()
        end
    end

    for _, reward in self.rewardsControlPool:ActiveAndFreeObjectIterator() do
        reward:MarkStyleDirty()
    end

    -- Reset the text here to handle the force uppercase on gamepad
    self.keybindButton:SetText(GetString(SI_TRIBUTE_SUMMARY_CONTINUE))
end

local function AreRewardsEqual(reward1, reward2)
    local rewardType1 = reward1:GetRewardType()
    local rewardType2 = reward2:GetRewardType()

    if rewardType1 ~= rewardType2 then
        return false
    end

    if rewardType1 == REWARD_ENTRY_TYPE_TRIBUTE_CLUB_EXPERIENCE then
        return true
    elseif rewardType1 == REWARD_ENTRY_TYPE_ADD_CURRENCY then
        return reward1:GetCurrencyType() == reward2:GetCurrencyType()
    elseif rewardType1 == REWARD_ENTRY_TYPE_COLLECTIBLE then
        local collectibleId1 = GetCollectibleRewardCollectibleId(reward1:GetRewardId())
        local collectibleId2 = GetCollectibleRewardCollectibleId(reward2:GetRewardId())
        return collectibleId1 == collectibleId2
    elseif rewardType1 == REWARD_ENTRY_TYPE_ITEM then
        local rewardItemId1 = GetItemLinkItemId(reward1:GetItemLink())
        local rewardItemId2 = GetItemLinkItemId(reward2:GetItemLink())
        return rewardItemId1 == rewardItemId2 and reward1:GetItemDisplayQuality() == reward2:GetItemDisplayQuality() and reward1:GetItemFunctionalQuality() == reward2:GetItemFunctionalQuality()
    elseif rewardType1 == REWARD_ENTRY_TYPE_TRIBUTE_CARD_UPGRADE then
        return false -- Tribute card upgrades don't stack
    elseif rewardType1 == REWARD_ENTRY_TYPE_MAIL_ITEM then
        return false -- System mails don't stack
    elseif rewardType1 == ZO_REWARD_CUSTOM_ENTRY_TYPE.LFG_ACTIVITY then
        return false -- These custom entries don't stack
    else
        internalassert(false, "Unexpected Tribute match reward type")
    end
end

function ZO_TributeSummary:BeginEndOfGameFanfare()
    SCENE_MANAGER:AddFragment(TRIBUTE_SUMMARY_FRAGMENT)

    self.campaignKey = GetTributeMatchCampaignKey()
    local matchType = GetTributeMatchType()
    local victor, victoryType = GetTributeResultsWinnerInfo()
    self.victory = victor == TRIBUTE_PLAYER_PERSPECTIVE_SELF
    self.victoryType = victoryType
    self.hasRewards = matchType ~= TRIBUTE_MATCH_TYPE_PRIVATE and (victoryType ~= TRIBUTE_VICTORY_TYPE_EARLY_CONCESSION or self.victory)
    self.isRanked = matchType == TRIBUTE_MATCH_TYPE_COMPETITIVE
    self.playerPrestige = GetTributePlayerPerspectiveResource(TRIBUTE_PLAYER_PERSPECTIVE_SELF, TRIBUTE_RESOURCE_PRESTIGE)
    self.opponentPrestige = GetTributePlayerPerspectiveResource(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT, TRIBUTE_RESOURCE_PRESTIGE)

    if self.victory and (matchType == TRIBUTE_MATCH_TYPE_COMPETITIVE or matchType == TRIBUTE_MATCH_TYPE_CASUAL) then
        TRIBUTE:QueueVictoryTutorial()
    end

    self.playerRankCurrent = GetTributePlayerCampaignRank()
    if self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM then
        self.playerRankNext = self.playerRankCurrent + 1
        self.progressionNextRankIcon:SetHidden(false)
    else
        self.playerRankNext = self.playerRankCurrent
        self.progressionNextRankIcon:SetHidden(true)
    end
    -- Rarely (esp. when completing placement matches) the player's new rank may not actually be the next rank (i.e. they can skip over ranks)
    self.playerRankNew = GetNewTributeCampaignRank()

    -- We create the placement bars even if we're not going to use them to avoid a bunch of nil checks in the states later.
    local function UpdateBarVisualDisplay(control, segmentIndex, handleNewMatch)
        local overlayControl = control:GetNamedChild("Overlay")
        local leftControl = overlayControl:GetNamedChild("Left")
        local rightControl = overlayControl:GetNamedChild("Right")
        local middleControl = overlayControl:GetNamedChild("Middle")

        local numRequiredMatches = GetNumRequiredPlacementMatches(self.campaignKey)
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
    if not self.progressionPlacementBarNew then
        self.progressionPlacementBarNew = ZO_MultiSegmentProgressBar:New(self.progressionPlacementBarNewControl, ZO_GetPlatformTemplate("ZO_TributeSummary_ArrowStatusBar"), UpdateBarVisualDisplayNew)
    end

    -- We can avoid doing this if we're not going to use the placement bars.
    if self.playerRankCurrent == TRIBUTE_TIER_UNRANKED then
        self.matchResults = {}
        self.matchResultsNew = {}
        local hasUpdatedCurrentMatch = false
        local numRequiredPlacementMatches = GetNumRequiredPlacementMatches(self.campaignKey)
        local winCount = 0
        local lossCount = 0
        for i = 1, numRequiredPlacementMatches do
            local hasRecord, wasAWin = GetCampaignMatchResultFromHistoryByMatchIndex(i, self.campaignKey)
            if hasRecord then
                if wasAWin then
                    table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_WON)
                    table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_WON)
                    winCount = winCount + 1
                else
                    table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_LOSS)
                    table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_LOSS)
                    lossCount = lossCount + 1
                end
            elseif not hasUpdatedCurrentMatch then
                if self.victory then
                    table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
                    table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_WON)
                    winCount = winCount + 1
                else
                    table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
                    table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_LOSS)
                    lossCount = lossCount + 1
                end
                hasUpdatedCurrentMatch = true
            else
                table.insert(self.matchResults, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
                table.insert(self.matchResultsNew, ZO_TRIBUTE_FINDER_MATCH_EMPTY)
            end
        end

        local matchRecordLabel = self.progressionPlacementBarNewControl:GetNamedChild("MatchRecordText")
        local formattedRecord = zo_strformat(SI_TRIBUTE_FINDER_PLACEMENT_STATUS, winCount, lossCount)
        local offsetX = 0
        if numRequiredPlacementMatches ~= 0 then
            offsetX = (winCount + lossCount) / numRequiredPlacementMatches * self.progressionPlacementBarNewControl:GetWidth()
        else
            assert(false)
        end
        local offsetY = 20
        matchRecordLabel:SetText(formattedRecord)
        matchRecordLabel:SetAnchor(TOP, nil, BOTTOMLEFT, offsetX, offsetY)

        self.progressionPlacementBar:SetSegmentationUniformity(true)
        self.progressionPlacementBar:SetProgressBarGrowthDirection(ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT)
        self.progressionPlacementBar:SetPreviousSegmentUnderneathOverlap(-32)

        self.progressionPlacementBarNew:SetSegmentationUniformity(true)
        self.progressionPlacementBarNew:SetProgressBarGrowthDirection(ZO_PROGRESS_BAR_GROWTH_DIRECTION_LEFT_TO_RIGHT)
        self.progressionPlacementBarNew:SetPreviousSegmentUnderneathOverlap(-32)
        self.progressionPlacementBarNew.handleNewMatch = true

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

    self.progressionProgressBar:Reset()
    self.playerClubXP = GetPendingTributeClubExperience()
    self.playerRankNextRequiredXP = GetTributeCampaignRankExperienceRequirement(self.playerRankNext, self.campaignKey) - GetTributeCampaignRankExperienceRequirement(self.playerRankCurrent, self.campaignKey)
    local currentXPForRank = GetTributePlayerExperienceInCurrentCampaignRank(self.campaignKey)
    self.playerCampaignXP = zo_max(0, currentXPForRank)
    self.playerCampaignXPDelta = GetPendingTributeCampaignExperience(self.campaignKey)
    self.progressionRankChange:SetText(string.format("%+d", self.playerCampaignXPDelta))
    self.rankUp = self.playerRankNew > self.playerRankCurrent
    self.progressionProgressBar:SetValue(self.playerRankCurrent, self.playerCampaignXP, self.playerRankNextRequiredXP, WRAP, ANIMATE_INSTANTLY)
    self.playerCampaignXP = self.playerCampaignXP + self.playerCampaignXPDelta
    if self.playerRankCurrent ~= TRIBUTE_TIER_UNRANKED and self.playerRankCurrent ~= TRIBUTE_TIER_PLATINUM then
        local playerXP = self.rankUp and self.playerRankNextRequiredXP or self.playerCampaignXP
        self.progressionProgressNumber:SetText(string.format("%d / %d", playerXP, self.playerRankNextRequiredXP))
        local progressInitial = (self.playerCampaignXP - self.playerCampaignXPDelta) /  zo_max(1, self.playerRankNextRequiredXP)
        local progressFinal = self.rankUp and 1 or self.playerCampaignXP / zo_max(1, self.playerRankNextRequiredXP)
        local width = self.progressionProgressBarControl:GetWidth()
        local xInitial = progressInitial * width
        local xFinal = progressFinal * width
        self.progressionProgressNumberTranslateAnimation:SetStartOffsetX(xInitial)
        self.progressionProgressNumberTranslateAnimation:SetEndOffsetX(xFinal)
        self.progressionProgressNumberTranslateAnimation:SetDuration(PROGRESS_TRANSLATION_ANIMATION_TIME_MS)
        self.progressionProgressNumberTranslateTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
        self.progressionProgressNumber:SetHidden(false)
    else
        self.progressionProgressNumber:SetHidden(true)
    end

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
            local indicator = patron:GetNamedChild("Indicator")
            local nameLabel = patron:GetNamedChild("Label")
            patron:SetTexture(patronData:GetPatronLargeIcon())
            indicator:SetTexture(patronData:GetPatronLargeRingIcon())
            nameLabel:SetText(patronData:GetFormattedName())
            if self.victory then
                indicator:SetTransformRotation(0, 0, ZO_PI)
            end
        end
    end

    -- Match statistics
    local matchDurationMS, goldAccumulated, cardsAcquired = GetTributeMatchStatistics()
    self.statisticsDuration:SetText(ZO_FormatTimeMilliseconds(matchDurationMS, DESCRIPTIVE_MINIMAL_HIDE_ZEROES))
    self.statisticsBackdrop:SetTexture(self.victory and END_OF_GAME_STATISTICS_BACKDROPS.VICTORY or END_OF_GAME_STATISTICS_BACKDROPS.DEFEAT)
    self.statisticsPrestige:SetText(string.format("%d - %d", self.playerPrestige, self.opponentPrestige))
    self.statisticsGold:SetText(goldAccumulated)
    self.statisticsCards:SetText(cardsAcquired)

    -- Summary
    local headerText = self.victory and GetString(SI_TRIBUTE_MATCH_RESULT_VICTORY) or GetString(SI_TRIBUTE_MATCH_RESULT_DEFEAT)
    self.summaryHeaderLabel:SetText(headerText)
    self.summaryBanner:SetTexture(self.victory and END_OF_GAME_RESULT_BANNERS.VICTORY or END_OF_GAME_RESULT_BANNERS.DEFEAT)
    local playerName = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_SELF)
    playerName = ZO_FormatUserFacingDisplayName(playerName)
    local opponentName, playerType = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)
    opponentName = playerType ~= TRIBUTE_PLAYER_TYPE_NPC and ZO_FormatUserFacingDisplayName(opponentName) or opponentName
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
    -- Club rank points don't get to us via reward list defs, so we have to create the reward item for it ourselves
    -- to display it as a reward.
    local clubXPReward = ZO_RewardData:New()
    clubXPReward:SetRewardType(REWARD_ENTRY_TYPE_TRIBUTE_CLUB_EXPERIENCE)
    clubXPReward:SetQuantity(self.playerClubXP)

    local mailedReward = ZO_RewardData:New()
    mailedReward:SetRewardType(REWARD_ENTRY_TYPE_MAIL_ITEM)

    local standardRewardListId = GetTributeGeneralMatchRewardListId()
    local lfgRewardUiDataId = GetTributeGeneralMatchLFGRewardUIDataId()
    local matchStandardRewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(standardRewardListId)
    if REWARDS_MANAGER:DoesRewardListContainMailItems(standardRewardListId) then
        table.insert(matchStandardRewards, 1, mailedReward)
    end
    if self.playerClubXP > 0 then
        table.insert(matchStandardRewards, 1, clubXPReward)
    end
    local matchLFGRewards = REWARDS_MANAGER:GetAllRewardInfoForLFGActivityRewardUIData(lfgRewardUiDataId)
    local rankUpMailedRewards = false
    local rankUpRewards = {}

    local function IsRewardAcquired(reward)
        local rewardId = reward:GetRewardId()
        if rewardId then
            if HasClaimedAccountReward(rewardId) then
                return true
            end
            if reward:GetRewardType() == REWARD_ENTRY_TYPE_COLLECTIBLE then
                local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
                if not CanAcquireCollectibleByDefId(collectibleId) then
                    return true
                end
            end
        end
        return false
    end

    if self.rankUp then
        for rank = self.playerRankCurrent, self.playerRankNew do
            local rankUpRewardListId = GetActiveTributeCampaignTierRewardListId(rank)
            local rankUpRewardList = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rankUpRewardListId)
            if REWARDS_MANAGER:DoesRewardListContainMailItems(rankUpRewardListId) then
                rankUpMailedRewards = true
            end
            if next(rankUpRewardList) then
                for _, reward in ipairs(rankUpRewardList) do
                    if not IsRewardAcquired(reward) then
                        local stackableRewardAlreadyExists = false
                        for _, innerReward in ipairs(rankUpRewards) do
                            if AreRewardsEqual(reward, innerReward) then
                                innerReward:SetQuantity(innerReward:GetQuantity() + reward:GetQuantity())
                                stackableRewardAlreadyExists = true
                                break
                            end
                        end
                        if not stackableRewardAlreadyExists then
                            table.insert(rankUpRewards, reward)
                        end
                    end
                end
            end
        end
    end
    local numClubRankRewardLists = GetNumTributeClubRankRewardLists()
    if numClubRankRewardLists > 0 then
        for clubRankRewardListIndex = 1, numClubRankRewardLists do
            local clubRankRewardListId = GetTributeClubRankRewardListIdByIndex(clubRankRewardListIndex)
            local clubRankRewardList = REWARDS_MANAGER:GetAllRewardInfoForRewardList(clubRankRewardListId)
            if REWARDS_MANAGER:DoesRewardListContainMailItems(clubRankRewardListId) then
                rankUpMailedRewards = true
            end
            if next(clubRankRewardList) then
                for _, reward in ipairs(clubRankRewardList) do
                    if not IsRewardAcquired(reward) then
                        local stackableRewardAlreadyExists = false
                        for _, innerReward in ipairs(rankUpRewards) do
                            if AreRewardsEqual(reward, innerReward) then
                                innerReward.quantity = innerReward.quantity + reward.quantity
                                stackableRewardAlreadyExists = true
                                break
                            end
                        end
                        if not stackableRewardAlreadyExists then
                            table.insert(rankUpRewards, reward)
                        end
                    end
                end
            end
        end
    end
    if rankUpMailedRewards then
        table.insert(rankUpRewards, 1, mailedReward)
    end

    local matchCombinedRewards = {}
    ZO_CombineNumericallyIndexedTables(matchCombinedRewards, matchStandardRewards, matchLFGRewards)
    for index = #matchCombinedRewards, 1, -1 do
        local reward = matchCombinedRewards[index]
        if IsRewardAcquired(reward) then
            table.remove(matchCombinedRewards, index)
        else
            for innerIndex = 1, 1, index do
                local innerReward = matchCombinedRewards[innerIndex]
                if AreRewardsEqual(reward, innerReward) then
                    innerReward:SetQuantity(innerReward:GetQuantity() + reward:GetQuantity())
                    table.remove(matchCombinedRewards, index)
                end
            end
        end
    end

    local MAX_REWARDS_PER_ROW = 4

    local function SetUpRewardsRow(rewardsTable, rowControl, rewardsControlPool)
        local previousControl = nil
        local overflow = #rewardsTable > MAX_REWARDS_PER_ROW
        for rewardIndex, reward in ipairs(rewardsTable) do
            local control = rewardsControlPool:AcquireObject()
            if not overflow or rewardIndex < MAX_REWARDS_PER_ROW then
                local rewardType = reward:GetRewardType()
                local name = reward:GetFormattedName()
                local icon = reward:GetKeyboardIcon()
                local qualityColorDef = nil
                local countText = ""
                local quantity = reward:GetQuantity()
                if rewardType == REWARD_ENTRY_TYPE_TRIBUTE_CLUB_EXPERIENCE then
                    name = zo_strformat(SI_TRIBUTE_CLUB_EXPERIENCE, self.playerClubXP)
                    icon = "EsoUI/Art/Tribute/tributeRankPoints.dds"
                    if quantity > 1 then
                        countText = quantity
                    end
                elseif rewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
                    local currencyType = reward:GetCurrencyType()
                    name = zo_strformat(SI_CURRENCY_CUSTOM_TOOLTIP_FORMAT, ZO_Currency_GetAmountLabel(currencyType))
                    icon = ZO_Currency_GetPlatformCurrencyLootIcon(currencyType)
                    local USE_SHORT_FORMAT = true
                    countText = ZO_CurrencyControl_FormatAndLocalizeCurrency(quantity, USE_SHORT_FORMAT)
                elseif rewardType == REWARD_ENTRY_TYPE_COLLECTIBLE then
                    -- No extra steps needed
                elseif rewardType == REWARD_ENTRY_TYPE_ITEM then
                    qualityColorDef = GetItemQualityColor(reward:GetItemDisplayQuality())

                    if quantity > 1 then
                        countText = quantity
                    end
                elseif rewardType == REWARD_ENTRY_TYPE_TRIBUTE_CARD_UPGRADE then
                    qualityColorDef = GetItemQualityColor(reward:GetItemDisplayQuality())
                elseif rewardType == REWARD_ENTRY_TYPE_MAIL_ITEM then
                    name = GetString(SI_TRIBUTE_SUMMARY_REWARD_MAIL)
                    icon = "EsoUI/Art/Icons/Quest_Container_001.dds"
                    control.mailIndicatorIcon:SetHidden(false)
                elseif rewardType == ZO_REWARD_CUSTOM_ENTRY_TYPE.LFG_ACTIVITY then
                    qualityColorDef = reward:GetColor()
                else
                    internalassert(false, "Unexpected Tribute match reward type")
                end

                if qualityColorDef then
                    name = qualityColorDef:Colorize(name)
                end

                control.nameLabel:SetText(name)
                control.iconTexture:SetTexture(icon)
                control.stackCountLabel:SetText(countText)
            else
                local genericItemTexture = "EsoUI/Art/Tribute/tributeEndOfGameReward_overflow.dds"
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
    local matchRewardWipeDuration = REWARD_WIPE_PER_ITEM_DURATION_MS * zo_min(MAX_REWARDS_PER_ROW, #matchCombinedRewards)
    self.matchRewardItemsInTimeline:GetAnimation(1):SetDuration(matchRewardWipeDuration)

    local function OnCompleteFireTrigger(_, completedPlaying)
        if completedPlaying then
            self.fanfareStateMachine:FireCallbacks(END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
        end
    end
    matchRewardsRowControl:SetMaskAnchor(TOPLEFT, BOTTOMLEFT)
    matchRewardsRowControl:SetAnimation(self.matchRewardItemsInTimeline:GetAnimation(1))
    matchRewardsRowControl.maskSimulator:SetScale(0)
    matchRewardsRowControl:SetHidden(true)

    if next(rankUpRewards) then
        self.hasRankUpRewards = true
        local rankUpRewardsRowControl = self.rewardRowControlPool:AcquireObject(REWARDS_RANK_UP_KEY)
        rankUpRewardsRowControl:SetAnchor(TOP, matchRewardsRowControl, BOTTOM, 0, 10)
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
        local rankUpItemsWipeDuration = REWARD_WIPE_PER_ITEM_DURATION_MS * zo_min(MAX_REWARDS_PER_ROW, #rankUpRewards)
        self.rankUpItemsInTimeline:GetAnimation(1):SetDuration(rankUpItemsWipeDuration)
        rankUpRewardsRowControl:SetMaskAnchor(TOPLEFT, BOTTOMLEFT)
        rankUpRewardsRowControl:SetAnimation(self.rankUpItemsInTimeline:GetAnimation(1))
        rankUpRewardsRowControl.maskSimulator:SetScale(0)
        rankUpRewardsRowControl:SetHidden(true)
    end

    -- In unranked matches that have rank up rewards, we don't want the matchRewardItemsInTimeline to trigger the state transition
    if self.isRanked or not self.hasRankUpRewards then
        self.matchRewardItemsInTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    end

    -- Progression
    self.progressionCurrentRankIcon:SetTexture(self.playerRankCurrentRewardsData:GetTierIcon())
    self.progressionCurrentRankLabel:SetText(self.playerRankCurrentRewardsData:GetTierName())
    self.progressionNextRankIcon:SetTexture(self.playerRankNextRewardsData:GetTierIcon())
    self.progressionNextRankLabel:SetText(self.playerRankNextRewardsData:GetTierName())

    if self.playerRankCurrent == TRIBUTE_TIER_PLATINUM or (self.rankUp and self.playerRankNew == TRIBUTE_TIER_PLATINUM) then
        local leaderboardRank, leaderboardSize = GetTributeLeaderboardRankInfo()
        local percentile = leaderboardSize == 0 and 100 or leaderboardRank * 100 / leaderboardSize
        local labelString = leaderboardRank ~= 0 and zo_strformat(SI_TRIBUTE_SUMMARY_LEADERBOARD_LABEL, leaderboardRank) or zo_strformat(SI_TRIBUTE_SUMMARY_LEADERBOARD_NO_RANK)
        self.leaderboardRank = leaderboardRank
        self.progressionLeaderboardBackdrop:GetNamedChild("LeaderboardLabel"):SetText(labelString)
        if percentile > 0 and percentile <= 2 then
            self.leaderboardTier = TRIBUTE_LEADERBOARD_TIER_TOP_2
            self.progressionLeaderboardBackdrop:SetTexture("EsoUI/Art/Tribute/tributeEndOfGameLeaderboardBackdrop_top2.dds")
        elseif percentile > 0 and percentile <= 10 then
            self.leaderboardTier = TRIBUTE_LEADERBOARD_TIER_TOP_10
            self.progressionLeaderboardBackdrop:SetTexture("EsoUI/Art/Tribute/tributeEndOfGameLeaderboardBackdrop_top10.dds")
        else
            self.leaderboardTier = TRIBUTE_LEADERBOARD_TIER_NONE
            self.progressionLeaderboardBackdrop:SetTexture("EsoUI/Art/Tribute/tributeEndOfGameLeaderboardBackdrop_standard.dds")
        end
    end

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
        local newClubXP = TRIBUTE_SUMMARY.playerClubXP or 0
        if newClubXP > 0 then
            currentClubExperienceForRank = currentClubExperienceForRank + newClubXP
            if currentClubExperienceForRank > maxClubExperienceForRank then
                currentClubExperienceForRank = currentClubExperienceForRank - maxClubExperienceForRank
                clubRank = clubRank + 1
                local clubExperienceForNextRank = GetTributeClubRankExperienceRequirement(clubRank + 1)
                if clubExperienceForNextRank ~= 0 then
                    maxClubExperienceForRank = clubExperienceForNextRank - GetTributeClubRankExperienceRequirement(clubRank)
                else
                    maxClubExperienceForRank = 0
                end
            end
        end

        InitializeTooltip(InformationTooltip, control, TOP, 0, 10)
        SetTooltipText(InformationTooltip, GetString("SI_TRIBUTECLUBRANK", clubRank))
        --If the maximum club experience for this rank is 0, then we are maxed out
        if maxClubExperienceForRank == 0 then
            InformationTooltip:AddLine(GetString(SI_TRIBUTE_CLUB_EXPERIENCE_LIMIT_REACHED))
        else
            local percentageXp = zo_floor(currentClubExperienceForRank / maxClubExperienceForRank * 100)
            local clubExperienceRatioText = zo_strformat(SI_TRIBUTE_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(currentClubExperienceForRank), ZO_CommaDelimitNumber(maxClubExperienceForRank), percentageXp)
            InformationTooltip:AddLine(zo_strformat(SI_TRIBUTE_CLUB_EXPERIENCE_TOOLTIP_FORMATTER, clubExperienceRatioText))
        end
    end
end

function ZO_TributeSummary_ClubRankProgressBar_Keyboard_OnMouseExit()
    ClearTooltip(InformationTooltip)
end