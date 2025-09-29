ZO_SpectacleEvents_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_SpectacleEvents_Manager:Initialize()
    self:InitializeEvents()
    self:UpdateActiveSpectacleEventId()
end

function ZO_SpectacleEvents_Manager:InitializeEvents()
    local function OnSpectacleEventUpdated(_, spectacleEventId)
        self:UpdateActiveSpectacleEventId()
    end

    EVENT_MANAGER:RegisterForEvent("ZO_SpectacleEvents_Manager", EVENT_SPECTACLE_EVENT_UPDATED, OnSpectacleEventUpdated)

    local function OnSpectacleEventPhaseUpdated(_, spectacleEventId, oldActivePhaseId, newActivePhaseId, isInitialUpdate)
        self:UpdateActiveSpectacleEventPhaseId(spectacleEventId, oldActivePhaseId, newActivePhaseId, isInitialUpdate)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_SpectacleEvents_Manager", EVENT_SPECTACLE_EVENT_PHASE_UPDATED, OnSpectacleEventPhaseUpdated)
end

function ZO_SpectacleEvents_Manager:GetActiveSpectacleEventId()
    return self.activeSpectacleEventId
end

function ZO_SpectacleEvents_Manager:IsAnySpectacleEventActive()
    return self.activeSpectacleEventId ~= nil and self.activeSpectacleEventId ~= 0
end

function ZO_SpectacleEvents_Manager:UpdateActiveSpectacleEventId()
    local previousActiveSpectacleEventId = self.activeSpectacleEventId
    if GetNumActiveSpectacleEvents() > 0 then
        self.activeSpectacleEventId = GetActiveSpectacleEventId(1)
    else
        self.activeSpectacleEventId = 0
    end

    if previousActiveSpectacleEventId ~= self.activeSpectacleEventId then
        self:FireCallbacks("ActiveSpectacleEventUpdated", self.activeSpectacleEventId)
    end
end

function ZO_SpectacleEvents_Manager:UpdateActiveSpectacleEventPhaseId(spectacleEventId, oldActivePhaseId, newActivePhaseId, isInitialUpdate)
    if oldActivePhaseId ~= newActivePhaseId then
        if oldActivePhaseId ~= 0 then
            self:FireCallbacks("ActiveSpectacleEventPhaseComplete", spectacleEventId, oldActivePhaseId, isInitialUpdate)
        end

        if newActivePhaseId ~= 0 then
            self:FireCallbacks("ActiveSpectacleEventPhaseStarted", spectacleEventId, newActivePhaseId, isInitialUpdate)
        end
    end
end

function ZO_SpectacleEvents_Manager:GetActiveSpectacleEventNextPhaseBeginsString(spectacleEventId)
    local secondsRemainingUntilStart = GetSecondsRemainingUntilNextActiveSpectacleEventPhase(spectacleEventId)
    local timeRemainingString
    if secondsRemainingUntilStart < ZO_ONE_MINUTE_IN_SECONDS then
        timeRemainingString = GetString(SI_STR_TIME_LESS_THAN_MINUTE_SHORT)
    else
        timeRemainingString = ZO_FormatTimeLargestTwo(secondsRemainingUntilStart, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES)
    end

    local currentPhase, numPhases = GetActiveSpectacleEventPhaseInfo(spectacleEventId)
    if currentPhase >= numPhases then
        -- There can be a phantom phase at the end of the event to allow for a more graceful ending
        -- In that case currentPhase == numPhases, but the server will have sent us a transition time
        if secondsRemainingUntilStart > 0 then
            return zo_strformat(SI_SPECTACLE_EVENTS_EVENT_ENDS_IN_FORMATTER, ZO_SELECTED_TEXT:Colorize(timeRemainingString))
        end

        return nil
    end

    local nextPhase = currentPhase + 1
    if not IsActiveSpectacleEventPhaseTransitionEnabled(spectacleEventId) then
        return zo_strformat(SI_SPECTACLE_EVENTS_PHASE_BEGINS_NEXT_UPDATE_FORMATTER, nextPhase)
    end

    if secondsRemainingUntilStart <= 0 then
        return zo_strformat(SI_SPECTACLE_EVENTS_PHASE_BEGINS_SOON_FORMATTER, nextPhase)
    end

    return zo_strformat(SI_SPECTACLE_EVENTS_PHASE_BEGINS_IN_FORMATTER, nextPhase, ZO_SELECTED_TEXT:Colorize(timeRemainingString))
end

SPECTACLE_EVENTS_MANAGER = ZO_SpectacleEvents_Manager:New()