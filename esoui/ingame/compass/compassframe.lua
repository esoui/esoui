ZO_COMPASS_FRAME_HEIGHT_KEYBOARD = 39
ZO_COMPASS_FRAME_HEIGHT_GAMEPAD = 24
ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD = 23

local CompassFrame = ZO_Object:Subclass()

function CompassFrame:New(...)
    local compassFrame = ZO_Object.New(self)
    compassFrame:Initialize(...)
    return compassFrame
end

function CompassFrame:Initialize(control)
    self.control = control
    self.compassHidden = false
    self.bossBarHiddenReasons = ZO_HiddenReasons:New()
    self.compassReady = false
    self.bossBarReady = false  

    COMPASS_FRAME_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:UpdateWidth() end)

    self:ApplyStyle() -- Setup initial visual style based on current mode.
    self.control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function CompassFrame:ApplyStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_CompassFrame"))

    local gamepadMode = IsInGamepadPreferredMode()
    local center = self.control:GetNamedChild("Center")
    center:GetNamedChild("TopMungeOverlay"):SetHidden(gamepadMode)
    center:GetNamedChild("BottomMungeOverlay"):SetHidden(gamepadMode)

    if gamepadMode then
        if self.bossBarReady and self.bossBarActive then
            local frame = self.control
            frame:SetHeight(ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD)
            frame:GetNamedChild("Left"):SetHeight(ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD)
            frame:GetNamedChild("Right"):SetHeight(ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD)
        end
    end
end

function CompassFrame:OnGamepadPreferredModeChanged()
    self:ApplyStyle()
end

local MIN_WIDTH = 400
local MAX_WIDTH = 800

function CompassFrame:UpdateWidth()
    local screenWidth = GuiRoot:GetWidth()
    self.control:SetWidth(zo_clamp(screenWidth * .35, MIN_WIDTH, MAX_WIDTH))
end

function CompassFrame:RefreshVisible()
    if(self.compassReady and self.bossBarReady) then
        local bossBarIsHidden = self.bossBarHiddenReasons:IsHidden() or not self.bossBarActive
        local compassIsHidden = self.compassHidden or not bossBarIsHidden
        
        local frameWasHidden = self.control:IsHidden()
        local frameIsHidden = bossBarIsHidden and compassIsHidden
        local frameChanged = frameWasHidden ~= frameIsHidden

        --if the frame is showing or hiding, or the frame isn't even shown, do the transition
        --between the boss bar and compass instantly
        if(frameChanged or frameIsHidden) then
            if(self.crossFadeTimeline) then
                self.crossFadeTimeline:Stop()
            end
            COMPASS_FRAME_FRAGMENT:SetHiddenForReason("contentsHidden", frameIsHidden)
            ZO_BossBar:SetAlpha(1)
            ZO_Compass:SetAlpha(1)
            ZO_BossBar:SetHidden(bossBarIsHidden)
            ZO_Compass:SetHidden(compassIsHidden)
        else
            --otherwise animate it if it changed
            local bossBarWasHidden = ZO_BossBar:IsHidden()
            local compassWasHidden = ZO_Compass:IsHidden()

            if(bossBarWasHidden ~= bossBarIsHidden or compassIsHidden ~= compassWasHidden) then
                if(not self.crossFadeTimeline) then
                    self.crossFadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_CompassFrameCrossFade")
                    self.crossFadeTimeline:GetAnimation(1):SetAnimatedControl(ZO_BossBar)
                    self.crossFadeTimeline:GetAnimation(2):SetAnimatedControl(ZO_Compass)
                end
                if(bossBarIsHidden) then
                    if(self.crossFadeTimeline:IsPlaying()) then
                        self.crossFadeTimeline:PlayForward()
                    else
                        self.crossFadeTimeline:PlayFromStart()
                    end
                else
                    if(self.crossFadeTimeline:IsPlaying()) then
                        self.crossFadeTimeline:PlayBackward()
                    else
                        self.crossFadeTimeline:PlayFromEnd()
                    end
                end
            end
        end        
    end
end

function CompassFrame:SetBossBarHiddenForReason(reason, hidden)
    if(self.bossBarHiddenReasons:SetHiddenForReason(reason, hidden)) then
        self:RefreshVisible()
    end
end

function CompassFrame:SetBossBarActive(active)
    self.bossBarActive = active
    self:ApplyStyle()
    self:RefreshVisible()
end

function CompassFrame:GetBossBarActive()
    return self.bossBarActive
end

function CompassFrame:SetCompassHidden(hidden)
    self.compassHidden = hidden
    self:RefreshVisible()
end

function CompassFrame:SetBossBarReady(ready)
    self.bossBarReady = ready
    ZO_BossBar:SetParent(self.control)
    self:RefreshVisible()
end

function CompassFrame:SetCompassReady(ready)
    self.compassReady = ready
    ZO_Compass:SetParent(self.control)
    self:RefreshVisible()
end

--Events

function CompassFrame:OnPlayerActivated()
    self:UpdateWidth()
    self:RefreshVisible()
end

--Global XML

function ZO_CompassFrame_OnInitialized(self)
    COMPASS_FRAME = CompassFrame:New(self)
end
