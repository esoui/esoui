ZO_InteractScene = ZO_Scene:Subclass()

function ZO_InteractScene:New(...)
    return ZO_Scene.New(self, ...)
end

function ZO_InteractScene:Initialize(name, sceneManager, interactionInfo)
    ZO_Scene.Initialize(self, name, sceneManager)
    self.interactionInfo = interactionInfo

    local function OnGamepadPreferredModeChanged()
        if self:IsShowing() then
            sceneManager:ShowBaseScene()
        end
    end
    EVENT_MANAGER:RegisterForEvent(name .. "OnGamepadPreferredModeChanged", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadPreferredModeChanged)
end

function ZO_InteractScene:GetInteractionInfo()
    return self.interactionInfo
end

function ZO_InteractScene:SetInteractionInfo(interactionInfo)
    self.interactionInfo = interactionInfo
end

function ZO_InteractScene:OnRemovedFromQueue()
    if not INTERACT_WINDOW:IsInteracting(self.interactionInfo) then
        RemoveActionLayerByName("SceneChangeInterceptLayer")
        INTERACT_WINDOW:TerminateClientInteraction(self.interactionInfo)
    end
end

function ZO_InteractScene:SetState(newState)
    if(newState == SCENE_SHOWING) then
        INTERACT_WINDOW:OnBeginInteraction(self.interactionInfo)
    elseif(newState == SCENE_HIDDEN) then
        local endInteraction = true

        local nextScene = SCENE_MANAGER:GetNextScene()
        if nextScene then
            if nextScene.GetInteractionInfo ~= nil then
                local nextSceneInteractionInfo = nextScene:GetInteractionInfo()
                local nextSceneInteractTypes = nextSceneInteractionInfo.interactTypes

                -- see if ALL of my scene's interact types will be satisfied by the next scene
                local allTypesMatched = true
                local mySceneInteractTypes = self.interactionInfo.interactTypes
                for i = 1, #mySceneInteractTypes do
                    local typeMatch = false
                    for j = 1, #nextSceneInteractTypes do
                        if mySceneInteractTypes[i] == nextSceneInteractTypes[j] then
                            typeMatch = true
                            break
                        end
                    end

                    if not typeMatch then
                        allTypesMatched = false
                        break
                    end
                end

                if allTypesMatched then
                    endInteraction = false
                end
            end
        end

        if endInteraction then
            INTERACT_WINDOW:OnEndInteraction(self.interactionInfo)
        end
    end

    ZO_Scene.SetState(self, newState)
end