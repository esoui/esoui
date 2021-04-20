ZO_InteractScene_Mixin = {}

function ZO_InteractScene_Mixin:InitializeInteractInfo(interactionInfo)
    interactionInfo.OnInteractionCanceled = interactionInfo.OnInteractionCanceled or function()
        if self:IsShowing() then
            -- If the interact ended for reasons outside of our control, this scenes state is essentially no longer valid so we need to abort come back in anyway
            self.sceneManager:RequestShowLeaderBaseScene(ZO_BHSCR_INTERACT_ENDED)
        end
    end

    self.interactionInfo = interactionInfo
end

function ZO_InteractScene_Mixin:GetInteractionInfo()
    return self.interactionInfo
end

function ZO_InteractScene_Mixin:SetInteractionInfo(interactionInfo)
    self.interactionInfo = interactionInfo
end

function ZO_InteractScene_Mixin:OnRemovedFromQueue(newNextScene)
    if not INTERACT_WINDOW:IsInteracting(self.interactionInfo) then
        RemoveActionLayerByName("SceneChangeInterceptLayer")
        if not newNextScene.GetInteractionInfo or newNextScene:GetInteractionInfo() ~= self.interactionInfo then
            INTERACT_WINDOW:TerminateClientInteraction(self.interactionInfo)
        end
    end
end

function ZO_InteractScene_Mixin:OnSceneShowing()
    INTERACT_WINDOW:OnBeginInteraction(self.interactionInfo)
end

function ZO_InteractScene_Mixin:OnSceneHidden()
    local endInteraction = true

    local nextScene = self.sceneManager:GetNextScene()
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
        INTERACT_WINDOW:EndInteraction(self.interactionInfo)
    end
end

-- Interact Scene --

ZO_InteractScene = ZO_Scene:Subclass()
zo_mixin(ZO_InteractScene, ZO_InteractScene_Mixin)

function ZO_InteractScene:New(...)
    return ZO_Scene.New(self, ...)
end

function ZO_InteractScene:Initialize(name, sceneManager, interactionInfo)
    ZO_Scene.Initialize(self, name, sceneManager)

    self:InitializeInteractInfo(interactionInfo)
end

function ZO_InteractScene:SetState(newState)
    if newState == SCENE_SHOWING then
        self:OnSceneShowing()
    elseif newState == SCENE_HIDDEN then
        self:OnSceneHidden()
    end

    ZO_Scene.SetState(self, newState)
end

-- Remote Interact Scene --

ZO_RemoteInteractScene = ZO_RemoteScene:Subclass()
zo_mixin(ZO_RemoteInteractScene, ZO_InteractScene_Mixin)

function ZO_RemoteInteractScene:New(...)
    return ZO_RemoteScene.New(self, ...)
end

function ZO_RemoteInteractScene:Initialize(name, sceneManager, interactionInfo)
    ZO_RemoteScene.Initialize(self, name, sceneManager)

    self:InitializeInteractInfo(interactionInfo)
end

function ZO_RemoteInteractScene:SetState(newState)
    if newState == SCENE_SHOWING then
        self:OnSceneShowing()
    elseif newState == SCENE_HIDDEN then
        self:OnSceneHidden()
    end

    ZO_RemoteScene.SetState(self, newState)
end