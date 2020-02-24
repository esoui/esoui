ZO_Cutscene = ZO_Object:Subclass()

function ZO_Cutscene:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Cutscene:Initialize(control)
    self.control = control

    control:RegisterForEvent(EVENT_BEGIN_CUTSCENE, function() self:OnBeginCutscene() end)
    control:RegisterForEvent(EVENT_END_CUTSCENE, function() self:OnEndCutscene() end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_PLAYER_DEACTIVATED, function() self:OnPlayerDeactivated() end)
    local function OnVideoPlaybackComplete()
        self:OnVideoPlaybackComplete()
    end
    control:RegisterForEvent(EVENT_VIDEO_PLAYBACK_COMPLETE, OnVideoPlaybackComplete)
    control:RegisterForEvent(EVENT_VIDEO_PLAYBACK_ERROR, OnVideoPlaybackComplete)
end

function ZO_Cutscene:OnPlayerActivated()
    self:RefreshCutscene()
end

function ZO_Cutscene:OnPlayerDeactivated()
    AbortVideoPlayback()
end

function ZO_Cutscene:OnBeginCutscene()
    self:RefreshCutscene()
end

function ZO_Cutscene:RefreshCutscene()
    if IsCutsceneActive() then
        self.control:SetHidden(false)
        local videoDataId = GetActiveCutsceneVideoDataId()
        if videoDataId ~= 0 then
            local PLAY_IMMEDIATELY = true
            PlayVideoById(videoDataId, PLAY_IMMEDIATELY, VIDEO_SKIP_MODE_REQUIRE_CONFIRMATION_FOR_SKIP)
            SCENE_MANAGER:SetInUIMode(true)
        else
            RequestEndCutscene()
        end
    else
        self.control:SetHidden(true)
    end
end

function ZO_Cutscene:OnVideoPlaybackComplete()
    if IsCutsceneActive() then
        RequestEndCutscene()
    end
end

function ZO_Cutscene:OnEndCutscene()
    self:RefreshCutscene()
end

--Global XML

function ZO_Cutscene_OnInitialized(control)
    CUTSCENE = ZO_Cutscene:New(control)
end