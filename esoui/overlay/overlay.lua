local function SetSubtitle(eventcode, subTitle)
    if IsInGamepadPreferredMode() then
        OverlaySubtitle:SetFont("ZoFontGamepad34")
        OverlaySubtitle:SetText(subTitle)
    else
        OverlaySubtitle:SetFont("ZoFontHeader3")
        OverlaySubtitle:SetText(subTitle)
    end
end

local g_confirmStarted

local function ClearConfirmationUpdate(self)
    g_confirmStarted = nil
    self:SetHandler("OnUpdate", nil)
    ResetVideoCancelConfirmation()
end

local function UpdateConfirmation(self, currentTime)
    if(not g_confirmStarted) then
        g_confirmStarted = currentTime
        self.fadeTimeline:PlayFromStart()
    elseif((currentTime - g_confirmStarted) > 2.5) then
        ClearConfirmationUpdate(self)
        self.fadeTimeline:PlayFromEnd()
    end
end

local function OnConfirmCancel()
    OverlaySubtitle:SetHidden(true)
    OverlayConfirmSkipInstruction:SetHandler("OnUpdate", UpdateConfirmation)
    if IsInGamepadPreferredMode() then
        OverlayConfirmSkipInstruction:SetFont("ZoFontGamepad34")
        OverlayConfirmSkipInstruction:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        OverlayConfirmSkipInstruction:SetText(GetString(SI_GAMEPAD_VIDEO_PLAYBACK_CONFIRM_CANCEL))
    else
        OverlayConfirmSkipInstruction:SetFont("ZoFontHeader3")
        OverlayConfirmSkipInstruction:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
        OverlayConfirmSkipInstruction:SetText(GetString(SI_VIDEO_PLAYBACK_CONFIRM_CANCEL))
    end
end

local function OnPlaybackComplete()
    OverlayConfirmSkipInstruction.fadeTimeline:Stop()
    OverlayConfirmSkipInstruction:SetAlpha(0)
    ClearConfirmationUpdate(OverlayConfirmSkipInstruction)
end

local function OnCancelStarted()
    -- force confirm back to 0 so that the next update immediately begins to fade out
    g_confirmStarted = 0
end

function InitOverlay(self)
    self:RegisterForEvent(EVENT_SET_SUBTITLE, SetSubtitle)
    self:RegisterForEvent(EVENT_VIDEO_PLAYBACK_COMPLETE, OnPlaybackComplete)
    self:RegisterForEvent(EVENT_VIDEO_PLAYBACK_CONFIRM_CANCEL, OnConfirmCancel)
    self:RegisterForEvent(EVENT_VIDEO_PLAYBACK_CANCEL_STARTED, OnCancelStarted)
end
