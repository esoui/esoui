local RaidLifeDisplay = ZO_Object:Subclass()

local RECENT_CHANGE_DURATION = 7000
local SCORE_ANIMATION_TIME_MS = 200
local SCORE_ANIMATION_UPDATE_DURATION_MS = 15000

function RaidLifeDisplay:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end 

function RaidLifeDisplay:Initialize(control)
    self.control = control
    self.reviveCounter = control:GetNamedChild("ReviveCounter")
    self.totalScoreLabel = control:GetNamedChild("TotalScore")
    self.scoreLabel = control:GetNamedChild("ScoreLabel")
    self.icon = control:GetNamedChild("Icon")
    self.totalScore = -1
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

    ZO_PlatformStyle:New(function() self:ApplyPlatformStyle() end)

    self:RefreshApplicable()
end

function RaidLifeDisplay:SetAnimatedShowHide(animatedShowHide)
    self.animatedShowHide = animatedShowHide
end

function RaidLifeDisplay:SetShowOnChange(showOnChange)
    self.showOnChange = showOnChange
    if(showOnChange) then
        self.hiddenReasons:AddShowReason("recentlyChanged")
    else
        self.hiddenReasons:RemoveShowReason("recentlyChanged")
        EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
    end
    self:RefreshVisible("initializeRecentlyChanged")
end

function RaidLifeDisplay:SetHiddenForReason(reason, hidden)
    if(self.hiddenReasons:SetHiddenForReason(reason, hidden)) then
        self:RefreshVisible(reason)
    end
end

function RaidLifeDisplay:SetShownForReason(reason, shown)
    if(self.hiddenReasons:SetShownForReason(reason, shown)) then
        self:RefreshVisible(reason)
    end
end

function RaidLifeDisplay:RefreshVisible(reason)
    local hidden = self.hiddenReasons:IsHidden()
    if(hidden ~= self.hidden) then
        self.hidden = hidden

        if(not hidden) then
            PlaySound(SOUNDS.RAID_LIFE_DISPLAY_SHOWN)
        end

        if(self.animatedShowHide and (reason == "applicable" or reason == "recentlyChanged" or reason == "reticleOverDeadPlayer")) then
            if(not self.alphaTimeline) then
                self.alphaTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_RaidLifeAlphaAnimation", self.control)
            end
            if(hidden) then
                if(self.alphaTimeline:IsPlaying()) then
                    self.alphaTimeline:PlayBackward()
                else
                    self.alphaTimeline:PlayFromEnd()
                end
            else
                if(self.alphaTimeline:IsPlaying()) then
                    self.alphaTimeline:PlayForward()
                else
                    self.alphaTimeline:PlayFromStart()
                end
            end
        else
            if(self.alphaTimeline) then
                self.alphaTimeline:Stop()
            end
            self.control:SetAlpha(1)
            self.control:SetHidden(hidden)
        end
    end
end

function RaidLifeDisplay:RefreshApplicable()
    local applicable = IsPlayerInReviveCounterRaid() and (IsRaidInProgress() or HasRaidEnded())
    if(self.hiddenReasons:SetHiddenForReason("applicable", not applicable)) then
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
    local prevScore = self.totalScore
    local curScore = self:GetPartyTotalScore()

    if prevScore == curScore then
        return 
    end

    self.totalScore = curScore
    ZO_CraftingResults_Base_PlayPulse(self.totalScoreLabel)
    self.totalScoreLabel:SetText(curScore)
end

function RaidLifeDisplay:RefreshCountAnimated()
    local count = self:GetRaidReviveCount()
    if(count ~= self.count) then
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
    if(not self.control:IsHidden()) then
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

function RaidLifeDisplay:ApplyPlatformStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_RaidLifeDisplay"))
end

--Global XML

function ZO_RaidLifeDisplay_OnEffectivelyShown(self)
    self.object:OnEffectivelyShown()
end

function ZO_RaidLifeDisplay_OnInitialized(self)
    self.object = RaidLifeDisplay:New(self)
end