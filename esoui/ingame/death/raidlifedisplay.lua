local RaidLifeDisplay = ZO_Object:Subclass()

local RECENT_CHANGE_DURATION = 3000

function RaidLifeDisplay:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end 

function RaidLifeDisplay:Initialize(control)
    self.control = control
    self.lifeCountLabel = control:GetNamedChild("Label")
    self.hiddenReasons = ZO_HiddenReasons:New()
    self.updateRegistrationName = self.control:GetName().."Update"
    self.updateCallback = function()
        self:OnRecentlyChangedExpired()
    end
    self.reticleTargetChangedCallback = function()
        self:OnReticleTargetChanged()
    end

    control:RegisterForEvent(EVENT_RAID_REVIVE_COUNTER_UPDATE, function() self:OnRaidLifeCounterChanged() end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_RAID_TIMER_STATE_UPDATE, function() self:OnRaidTimerStateUpdate() end)

    ZO_PlatformStyle:New(function() self:ApplyPlatformStyle() end)

    self.labelTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_RaidLifeChangeAnimation", self.lifeCountLabel)
    local labelAnim = self.labelTimeline:GetAnimation(1)
    labelAnim:SetHandler("OnPlay", function()
        self.lifeCountLabel:SetText(self.count)
        PlaySound(SOUNDS.RAID_LIFE_DISPLAY_CHANGED)
    end)
    self.labelTimeline:SetHandler("OnStop", function()
        self.lifeCountLabel:SetText(self.count)
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

function RaidLifeDisplay:SetShowOnReticleOverDeadPlayer(showOnReticleOverDeadPlayer)
    if(showOnReticleOverDeadPlayer) then
        self.hiddenReasons:AddShowReason("reticleOverDeadPlayer")
        self.control:RegisterForEvent(EVENT_RETICLE_TARGET_PLAYER_CHANGED, self.reticleTargetChangedCallback)
    else
        self.hiddenReasons:RemoveShowReason("reticleOverDeadPlayer")
        self.control:UnregisterForEvent(EVENT_RETICLE_TARGET_PLAYER_CHANGED)
    end
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

function RaidLifeDisplay:GetRaidLifeCount()
    return GetRaidReviveCounterInfo() or 0
end

function RaidLifeDisplay:RefreshCountInstantly()
    if(not self.labelTimeline:IsPlaying()) then
        local count = self:GetRaidLifeCount()
        self.lifeCountLabel:SetText(count)
        self.count = count
    end
end

function RaidLifeDisplay:RefreshCountAnimated()
    local count = self:GetRaidLifeCount()
    if(count ~= self.count) then
        self.count = count
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

--Events

function RaidLifeDisplay:OnPlayerActivated()
    self:RefreshApplicable()
    self:RefreshCountInstantly()
end

function RaidLifeDisplay:OnRecentlyChangedExpired()
    EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
    self:SetShownForReason("recentlyChanged", false)
end

function RaidLifeDisplay:OnReticleTargetChanged()
    local overDeadUnit = DoesUnitExist("reticleOver") and IsUnitDead("reticleOver")
    local raidLifeRequired = ZO_Death_DoesReviveCostRaidLife()
    self:SetShownForReason("reticleOverDeadPlayer", overDeadUnit and raidLifeRequired)
end

function RaidLifeDisplay:OnRaidLifeCounterChanged()
    if(not self.control:IsHidden()) then
        self:RefreshCountAnimated()
    end

    if(self.showOnChange) then
        self.mostRecentChangeTime = GetFrameTimeSeconds()
        EVENT_MANAGER:UnregisterForUpdate(self.updateRegistrationName)
        EVENT_MANAGER:RegisterForUpdate(self.updateRegistrationName, RECENT_CHANGE_DURATION, self.updateCallback)
        self.count = self:GetRaidLifeCount()
        self:SetShownForReason("recentlyChanged", true)
    end
end

function RaidLifeDisplay:OnRaidTimerStateUpdate()
    self:RefreshCountInstantly()
    self:RefreshApplicable()
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