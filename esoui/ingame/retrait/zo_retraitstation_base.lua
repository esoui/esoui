ZO_RETRAIT_MODE_ROOT = 0
ZO_RETRAIT_MODE_RETRAIT = 1

ZO_RetraitStation_Base = ZO_Object:Subclass()

function ZO_RetraitStation_Base:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_RetraitStation_Base:Initialize(control, interactSceneName)
    self.control = control
    self.retraitStationInteraction =
    {
        type = "Retrait Station",
        End = function()
            SCENE_MANAGER:ShowBaseScene()
        end,
        interactTypes = { INTERACTION_RETRAIT },
    }

    self.interactScene = self:CreateInteractScene(interactSceneName)
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

    ZO_RETRAIT_STATION_MANAGER:RegisterCallback("OnRetraitDirtyEvent", function(...) self:HandleDirtyEvent(...) end)
end

function ZO_RetraitStation_Base:CreateInteractScene(sceneName)
    return ZO_InteractScene:New(sceneName, SCENE_MANAGER, self.retraitStationInteraction)
end

function ZO_RetraitStation_Base:IsItemAlreadySlottedToCraft(bag, slot)
    -- To be overridden
    return false
end

function ZO_RetraitStation_Base:CanItemBeAddedToCraft(bag, slot)
    -- To be overridden
    return false
end

function ZO_RetraitStation_Base:AddItemToCraft(bag, slot)
    -- To be overridden
end

function ZO_RetraitStation_Base:RemoveItemFromCraft(bag, slot)
    -- To be overridden
end

function ZO_RetraitStation_Base:OnRetraitResult(result)
    -- To be overridden
end

function ZO_RetraitStation_Base:HandleDirtyEvent()
    -- To be overridden
end

function ZO_RetraitStation_Base:OnInteractSceneShowing()
    -- Optional Override
end

function ZO_RetraitStation_Base:OnInteractSceneHiding()
    -- Optional Override
end

function ZO_RetraitStation_Base:OnInteractSceneHidden()
    -- Optional Override
end
