ZO_InteractScene = ZO_Scene:Subclass()

function ZO_InteractScene:New(name, sceneManager, interactionInfo)
    local scene = ZO_Scene.New(self, name, sceneManager)
    scene.interactionInfo = interactionInfo
    return scene
end

function ZO_InteractScene:GetInteractionInfo()
    return self.interactionInfo
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