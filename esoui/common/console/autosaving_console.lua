ZO_AutoSaving_Console = ZO_Object:Subclass()
local AUTO_SAVING_UPDATE_TIME_S = 60
local TIME_AFTER_SAVE_COMPLETE_TO_FADE_S = 0.5

function ZO_AutoSaving_Console:New(...)
    local autoSaving = ZO_Object.New(self)
    autoSaving:Initialize(...)
    return autoSaving
end

function ZO_AutoSaving_Console:Initialize(control)
    self.timeSavedCompleteS = 0
    self.control = control

    local spinner = control:GetNamedChild("Spinner")

    self.spinnerFadeAnimation = GetAnimationManager():CreateTimelineFromVirtual("AutoSaveFade", spinner)
    self.spinnerFadeAnimation:SetHandler("OnStop", function(timeline, completed) self:HideAutoSavingAnimComplete(timeline, completed) end)

    self.spinnerSpinAnimation = GetAnimationManager():CreateTimelineFromVirtual("AutoSaveSpin", spinner)
    
    control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds) self:OnUpdate(currentFrameTimeSeconds) end)

    EVENT_MANAGER:RegisterForEvent("AutoSaving", EVENT_SAVE_DATA_START, function() self:ShowAutoSaving() end)
    EVENT_MANAGER:RegisterForEvent("AutoSaving", EVENT_SAVE_DATA_COMPLETE, function() self:LogSaveCompleted() end)

    self.timeTilNextAutoSaveS = GetFrameTimeSeconds() + AUTO_SAVING_UPDATE_TIME_S
end

function ZO_AutoSaving_Console:ShowAutoSaving()
    self.spinnerFadeAnimation:PlayFromStart()
    self.spinnerSpinAnimation:PlayFromStart()
    self.timeSavedCompleteS = 0
end

function ZO_AutoSaving_Console:OnUpdate(currentFrameTimeSeconds)
    if self.timeSavedCompleteS ~= 0 then
        if (self.timeSavedCompleteS + TIME_AFTER_SAVE_COMPLETE_TO_FADE_S) < currentFrameTimeSeconds then
            self:HideAutoSaving()
            self.timeSavedCompleteS = 0
        end
    end

    --Autosave every minute if dirty
    if self.timeTilNextAutoSaveS < currentFrameTimeSeconds then
        self.timeTilNextAutoSaveS = currentFrameTimeSeconds + AUTO_SAVING_UPDATE_TIME_S
        if self.isDirty then
            ZO_SavePlayerConsoleProfile()
            self.isDirty = false
        end
    end
end

function ZO_AutoSaving_Console:LogSaveCompleted()
    self.timeSavedCompleteS = GetFrameTimeSeconds()
end

function ZO_AutoSaving_Console:HideAutoSaving()
    self.spinnerFadeAnimation:PlayBackward() 
end

function ZO_AutoSaving_Console:HideAutoSavingAnimComplete(timeline, completed)
    if(completed) then
        if(timeline:IsPlayingBackward()) then
            self.spinnerSpinAnimation:Stop()    --stop spinning after fadeout
        end
    end
end


function ZO_AutoSaving_Console:MarkDirty()
    self.isDirty = true
end

function ZO_InitializeAutoSaving_Console(control)
    AUTO_SAVING = ZO_AutoSaving_Console:New(control)
end