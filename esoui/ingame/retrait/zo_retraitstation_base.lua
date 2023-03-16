ZO_RETRAIT_MODE_ROOT = 0
ZO_RETRAIT_MODE_RETRAIT = 1
ZO_RETRAIT_MODE_RECONSTRUCT = 2

ZO_RetraitStation_Base = ZO_InitializingObject:Subclass()

function ZO_RetraitStation_Base:Initialize(control, interactSceneName)
    self.control = control
    self.retraitStationInteraction =
    {
        type = "Retrait Station",
        OnInteractSwitch = function()
            internalassert(false, "OnInteractSwitch is being called.")
            SCENE_MANAGER:ShowBaseScene()
        end,
        interactTypes = {INTERACTION_RETRAIT},
    }

    self.interactScene = ZO_InteractScene:New(interactSceneName, SCENE_MANAGER, self.retraitStationInteraction)
    self.interactScene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            TriggerTutorial(TUTORIAL_TRIGGER_RETRAIT_STATION_OPENED)
            self:OnInteractSceneShowing()
        elseif newState == SCENE_HIDING then
            self:OnInteractSceneHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnInteractSceneHidden()
        end
    end)

    ZO_RETRAIT_STATION_MANAGER:RegisterRetraitScene(interactSceneName)
end

function ZO_RetraitStation_Base:OnInteractSceneShowing()
    -- Optional override.
end

function ZO_RetraitStation_Base:OnInteractSceneHiding()
    -- Optional override.
end

function ZO_RetraitStation_Base:OnInteractSceneHidden()
    -- Optional override.
end