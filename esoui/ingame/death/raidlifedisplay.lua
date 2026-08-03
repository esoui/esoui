local RaidLifeDisplay = ZO_InitializingObject:Subclass()

local RECENT_CHANGE_DURATION = 7000
local SCORE_ANIMATION_TIME_MS = 200
local SCORE_ANIMATION_UPDATE_DURATION_MS = 15000

function RaidLifeDisplay:Initialize(control)
    self.control = control
    self.reviveCounter = control:GetNamedChild("ReviveCounter")
    self.totalScoreLabel = control:GetNamedChild("TotalScore")
    self.scoreLabel = control:GetNamedChild("ScoreLabel")
    self.trialProgressionLabel = control:GetNamedChild("TrialProgressionLabel")
    self.trialProgressionPointsControl = control:GetNamedChild("TrialProgressionPoints")
    self.icon = control:GetNamedChild("Icon")
    self.hudElementRef = control:GetNamedChild("HUDElementRef")
    self.totalScore = -1
    self.trialProgressionPoints = -1
    self.hiddenReasons = ZO_HiddenReasons:New()
    self.updateRegistrationName = self.control:GetName().."Update"
    self.updateCallback = function()
        self:OnRecentlyChangedExpired()
    end

    control:RegisterForEvent(EVENT_RAID_REVIVE_COUNTER_UPDATE, function() self:OnRaidLifeCounterChanged() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_SCORE_UPDATE, function() self:OnRaidLifeCounterChanged() end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_RAID_TIMER_STATE_UPDATE, function() self:OnRaidTimerStateUpdate() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_SCORE_UPDATE, function() self:OnRaidScoreUpdate() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_COMPLETE, function() self:OnRaidTrialComplete() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_FAILED, function() self:OnRaidScoreUpdate() end)
    control:RegisterForEvent(EVENT_TRIAL_PROGRESSION_POINTS_CHANGED, function() self:OnTrialProgressionPointsChanged() end)
    control:RegisterForEvent(EVENT_TRIAL_PROGRESSION_ATTUNEMENT_CHANGED, function() self:OnTrialProgressionAttunementChanged() end)

    local KEYBOARD_STYLE =
    {
        containerAnchor = ZO_Anchor:New(BOTTOMRIGHT),
    }
    local GAMEPAD_STYLE =
    {
        containerAnchor = ZO_Anchor:New(BOTTOMLEFT),
    }

    local KEYBOARD_CONFIG =
    {
        defaultAnchor = KEYBOARD_STYLE.containerAnchor,
    }
    local GAMEPAD_CONFIG =
    {
        defaultAnchor = GAMEPAD_STYLE.containerAnchor,
    }

    local RAID_LIFE_OPTIONS =
    {
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.ENUM,
            name = GetString(SI_INTERFACE_OPTIONS_SHOW_RAID_LIVES),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_SHOW_RAID_LIVES_TOOLTIP),
            key = "ShowLives",
            valueStringPrefix = "SI_RAIDLIFEVISIBILITYCHOICE",
            values = { RAID_LIFE_VISIBILITY_CHOICE_OFF, RAID_LIFE_VISIBILITY_CHOICE_AUTOMATIC, RAID_LIFE_VISIBILITY_CHOICE_ON, },
            defaultValue = function()
                return tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RAID_LIVES))
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RAID_LIVES, tostring(value))
                end
            end,
        },
    }

    local DISPLAY_NAME = GetString(SI_HUD_EDITOR_TRIAL_SCORE)
    HUD_MANAGER:RegisterKeyboardElement(control, DISPLAY_NAME, KEYBOARD_CONFIG, RAID_LIFE_OPTIONS)
    HUD_MANAGER:RegisterGamepadElement(control, DISPLAY_NAME, GAMEPAD_CONFIG, RAID_LIFE_OPTIONS)

    ZO_PlatformStyle:New(function(...) self:ApplyPlatformStyle(...) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

    self:RefreshApplicable()
end

function RaidLifeDisplay:SetAnimatedShowHide(animatedShowHide)
    self.animatedShowHide = animatedShowHide
end

function RaidLifeDisplay:SetShowOnChange(showOnChange)
    self.showOnChange = showOnChange
    if showOnChange then
        self.hiddenReasons:AddShowReason("recentlyChanged")
    else
        self.hiddenReasons:RemoveShowReason("recentlyChanged")
        EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
    end
    self:RefreshVisible("initializeRecentlyChanged")
end

function RaidLifeDisplay:SetHiddenForReason(reason, hidden)
    if self.hiddenReasons:SetHiddenForReason(reason, hidden) then
        self:RefreshVisible(reason)
    end
end

function RaidLifeDisplay:SetShownForReason(reason, shown)
    if self.hiddenReasons:SetShownForReason(reason, shown) then
        self:RefreshVisible(reason)
    end
end

function RaidLifeDisplay:RefreshVisible(reason)
    local hidden = self.hiddenReasons:IsHidden()
    if hidden ~= self.hidden then
        self.hidden = hidden

        if not hidden then
            PlaySound(SOUNDS.RAID_LIFE_DISPLAY_SHOWN)
            self:UpdateTrialProgressionLabel()
            self:UpdateTrialProgressionControl()
        end

        if self.animatedShowHide and (reason == "applicable" or reason == "recentlyChanged" or reason == "reticleOverDeadPlayer") then
            if not self.alphaTimeline then
                self.alphaTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_RaidLifeAlphaAnimation", self.control)
            end
            if hidden then
                if self.alphaTimeline:IsPlaying() then
                    self.alphaTimeline:PlayBackward()
                else
                    self.alphaTimeline:PlayFromEnd()
                end
            else
                if self.alphaTimeline:IsPlaying() then
                    self.alphaTimeline:PlayForward()
                else
                    self.alphaTimeline:PlayFromStart()
                end
            end
        else
            if self.alphaTimeline then
                self.alphaTimeline:Stop()
            end
            self.control:SetAlpha(1)
            self.control:SetHidden(hidden)
        end

        -- Allow the whole element to fade out before we re-evaluate whether or not to specifically
        -- hide the Trial Progression labels
        if hidden then
            self:UpdateTrialProgressionLabel()
            self:UpdateTrialProgressionControl()
        end
    end
end

function RaidLifeDisplay:RefreshApplicable()
    local applicable = IsPlayerInReviveCounterRaid() and (IsRaidInProgress() or HasRaidEnded())
    if self.hiddenReasons:SetHiddenForReason("applicable", not applicable) then
        self:RefreshVisible("applicable")
    end
end

function RaidLifeDisplay:GetRaidReviveCount()
    return GetRaidReviveCountersRemaining() or 0
end

function RaidLifeDisplay:GetRaidBonusScore()
    return (GetRaidReviveCountersRemaining() or 0) * GetRaidBonusMultiplier()
end

function RaidLifeDisplay:GetPartyTotalScore()
    return GetCurrentRaidScore()
end

function RaidLifeDisplay:GetPlayerCurrentTrialProgressionPoints()
    return GetPointsInTrialProgressionTrackByIndex(GetCurrentlyAttunedTrialProgressionTrack())
end

function RaidLifeDisplay:RefreshCountInstantly()
    self.count =  self:GetRaidReviveCount()
    self:RefreshDisplay()
end

function RaidLifeDisplay:RefreshDisplay()
    local maxCount = GetCurrentRaidStartingReviveCounters()
    self.reviveCounter:SetText(zo_strformat(SI_REVIVE_COUNTER_REVIVES_USED, self.count, maxCount))
    self:UpdateTotalScore()
    if self.count == 0 then
        self.reviveCounter:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        self.icon:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
    else
        self.reviveCounter:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        self.icon:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    end
end

function RaidLifeDisplay:UpdateTotalScore()
    local previousScore = self.totalScore
    local currentScore = self:GetPartyTotalScore()

    if previousScore == currentScore then
        return 
    end

    self.totalScore = currentScore
    ZO_CraftingResults_Base_PlayPulse(self.totalScoreLabel)
    self.totalScoreLabel:SetText(currentScore)
end

function RaidLifeDisplay:UpdateTrialProgressionLabel()
    if GetCurrentlyAttunedTrialProgressionTrack() then
        self.trialProgressionLabel:SetText(GetTrialProgressionHUDLabel())
        self.trialProgressionLabel:SetHidden(false)
    else
        self.trialProgressionLabel:SetHidden(true)
        self.trialProgressionLabel:SetText("")
    end
end

function RaidLifeDisplay:UpdateTrialProgressionControl()
    if GetCurrentlyAttunedTrialProgressionTrack() then
        local previousPoints = self.trialProgressionPoints
        local currentPoints = self:GetPlayerCurrentTrialProgressionPoints()

        if previousPoints == currentPoints then
            self.trialProgressionPointsControl:SetHidden(false)
            return
        end

        self.trialProgressionPoints = currentPoints
        if ZO_CraftingResults_Base_PlayPulse then
            ZO_CraftingResults_Base_PlayPulse(self.trialProgressionPointsControl)
        end
        self.trialProgressionPointsControl:SetText(currentPoints)
        self.trialProgressionPointsControl:SetHidden(false)
    else
        self.trialProgressionPointsControl:SetHidden(true)
        self.trialProgressionPointsControl:SetText("")
    end
end

function RaidLifeDisplay:RefreshCountAnimated()
    local count = self:GetRaidReviveCount()
    if count ~= self.count then
        self.count = count
        self:UpdateTotalScore()
    end
end

function RaidLifeDisplay:OnEffectivelyShown()
    self:RefreshCountInstantly()
end

--Events

function RaidLifeDisplay:OnPlayerActivated()
    self:RefreshApplicable()
    if IsPlayerInReviveCounterRaid() then
        self:RefreshCountInstantly()
    end
end

function RaidLifeDisplay:OnRecentlyChangedExpired()
    EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
    self:SetShownForReason("recentlyChanged", false)
end

function RaidLifeDisplay:OnRaidLifeCounterChanged()
    if not self.control:IsHidden() then
        self:RefreshCountAnimated()
    end

    self.mostRecentChangeTime = GetFrameTimeSeconds()
    EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
    EVENT_MANAGER:RegisterForUpdate(self.updateRegistrationName, RECENT_CHANGE_DURATION, self.updateCallback)
    self.count = self:GetRaidReviveCount()
    self:UpdateTotalScore()
    self:RefreshDisplay()
    self:SetShownForReason("recentlyChanged", true)
end

function RaidLifeDisplay:OnRaidTimerStateUpdate()
    self:OnRaidScoreUpdate()
    self.scoreLabel:SetText(GetString(SI_REVIVE_COUNTER_SCORE))
end

function RaidLifeDisplay:OnRaidScoreUpdate()
    self:RefreshCountInstantly()
    self:RefreshApplicable()
end

function RaidLifeDisplay:OnRaidTrialComplete()
    self:OnRaidScoreUpdate()
    self.scoreLabel:SetText(GetString(SI_REVIVE_COUNTER_FINAL_SCORE))
end

function RaidLifeDisplay:OnTrialProgressionPointsChanged()
    self:UpdateTrialProgressionControl()
end

function RaidLifeDisplay:OnTrialProgressionAttunementChanged()
    self:UpdateTrialProgressionLabel()
    self:UpdateTrialProgressionControl()
end

function RaidLifeDisplay:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_RaidLifeDisplay"))
    style.containerAnchor:Set(self.hudElementRef)
    self:UpdateTrialProgressionLabel()
end

--Global XML

function ZO_RaidLifeDisplay_OnEffectivelyShown(self)
    self.object:OnEffectivelyShown()
end

function ZO_RaidLifeDisplay_OnInitialized(self)
    self.object = RaidLifeDisplay:New(self)
end