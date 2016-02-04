local RaidLifeDisplay = ZO_Object:Subclass()

local RECENT_CHANGE_DURATION = 3000
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
    self.previousTotalScore = 0
    self.hiddenReasons = ZO_HiddenReasons:New()
    self.updateRegistrationName = self.control:GetName().."Update"
    self.updateCallback = function()
        self:OnRecentlyChangedExpired()
    end

    control:RegisterForEvent(EVENT_RAID_REVIVE_COUNTER_UPDATE, function() self:OnRaidLifeCounterChanged() end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_RAID_TIMER_STATE_UPDATE, function() self:OnRaidTimerStateUpdate() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_SCORE_UPDATE, function() self:OnRaidScoreUpdate() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_COMPLETE, function() self:OnRaidTrialComplete() end)
    control:RegisterForEvent(EVENT_RAID_TRIAL_FAILED, function() self:OnRaidScoreUpdate() end)

    self.raidScoreAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_RaidLifeScoreUpdateAnimation")
    self.raidScoreAnimation:GetAnimation(1):SetUpdateFunction(function(...) self:UpdateScoreAnimation(...) end)

    ZO_PlatformStyle:New(function() self:ApplyPlatformStyle() end)

    self.labelTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_RaidLifeChangeAnimation", self.reviveCounter)
    local labelAnim = self.labelTimeline:GetAnimation(1)
    labelAnim:SetHandler("OnPlay", function()
        self:RefreshDisplay()
        PlaySound(SOUNDS.RAID_LIFE_DISPLAY_CHANGED)
    end)
    self.labelTimeline:SetHandler("OnStop", function()
        self:RefreshDisplay()
    end)
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
            --pulse the label when we show the display because it's now applicable or the counter just changed
            if(reason == "applicable" or reason == "recentlyChanged") then
                local offset
                local isDisplayFullShown = self.control:GetAlpha() == 1 and not self.control:IsHidden()
                --if the display is fading in or hidden, with a bit to do the pulse
                if(not self.animatedShowHide or isDisplayFullShown) then
                    offset = 0
                else
                    offset = 500
                end

                self:PlayLabelAnimation(offset)
            end

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
    if(not self.labelTimeline:IsPlaying()) then
        self.count =  self:GetRaidReviveCount()
        self:RefreshDisplay()
    end
end

function RaidLifeDisplay:RefreshDisplay()
    local maxCount = GetCurrentRaidStartingReviveCounters()
    self.reviveCounter:SetText(zo_strformat(SI_REVIVE_COUNTER_REVIVES_USED, self.count, maxCount))
    self:UpdateTotalScore()
    if self.count == 0 then
        self.reviveCounter:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        self.icon:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
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

    if not self.raidScoreAnimation:IsPlaying() then
        self.previousTotalScore = prevScore
        self.progressCount = 0
        self.raidScoreAnimation:PlayFromStart()
    end
end

function RaidLifeDisplay:RefreshCountAnimated()
    local count = self:GetRaidReviveCount()
    if(count ~= self.count) then
        self.count = count
        self:UpdateTotalScore()
        self:PlayLabelAnimation(0)
    end
end

function RaidLifeDisplay:PlayLabelAnimation(offset)
    self.labelTimeline:Stop()
    for i = 1, self.labelTimeline:GetNumAnimations() do
        local anim = self.labelTimeline:GetAnimation(i)
        self.labelTimeline:SetAnimationOffset(anim, offset)
    end
    self.labelTimeline:PlayFromStart()
end

function RaidLifeDisplay:OnEffectivelyShown()
    self:RefreshCountInstantly()
end

do
    local SCORE_UPDATE_REFRESH_RATE = 3 --update the text every third frame
    function RaidLifeDisplay:UpdateScoreAnimation(animation, progress)
        self.progressCount = self.progressCount + 1
        if self.progressCount % SCORE_UPDATE_REFRESH_RATE == 1 or progress == 1 then
            local delta = (self.totalScore - self.previousTotalScore) * progress
            local nextValue = zo_floor(delta + self.previousTotalScore)
            self.totalScoreLabel:SetText(nextValue)
        end
    end
end

--Events

function RaidLifeDisplay:OnPlayerActivated()
    self:RefreshApplicable()
    self:RefreshCountInstantly()
end

function RaidLifeDisplay:OnRecentlyChangedExpired()
    EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
    self:SetShownForReason("recentlyChanged", false)
end

function RaidLifeDisplay:OnRaidLifeCounterChanged()
    if(not self.control:IsHidden()) then
        self:RefreshCountAnimated()
    end

    if(self.showOnChange) then
        self.mostRecentChangeTime = GetFrameTimeSeconds()
        EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
        EVENT_MANAGER:RegisterForUpdate(self.updateRegistrationName, RECENT_CHANGE_DURATION, self.updateCallback)
        self.count = self:GetRaidReviveCount()
        self:UpdateTotalScore()
        self:SetShownForReason("recentlyChanged", true)
    end
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