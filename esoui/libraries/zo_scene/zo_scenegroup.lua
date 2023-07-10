-- Alias
SCENE_GROUP_SHOWING = ZO_STATE.SHOWING
SCENE_GROUP_SHOWN = ZO_STATE.SHOWN
SCENE_GROUP_HIDING = ZO_STATE.HIDING
SCENE_GROUP_HIDDEN = ZO_STATE.HIDDEN

ZO_SceneGroup = ZO_InitializingCallbackObject:Subclass()

function ZO_SceneGroup:Initialize(...)
    self.state = SCENE_GROUP_HIDDEN
    self.scenes = {}
    for i = 1, select("#", ...) do
        self:AddScene(select(i, ...))
    end
    self.activeScene = 1
end

function ZO_SceneGroup:AddScene(sceneName)
    table.insert(self.scenes, sceneName)
    SCENE_MANAGER:GetScene(sceneName):SetSceneGroup(self)
end

function ZO_SceneGroup:GetNumScenes()
    return #self.scenes
end

function ZO_SceneGroup:GetSceneName(index)
    return self.scenes[index]
end

function ZO_SceneGroup:GetActiveScene()
    return self.scenes[self.activeScene]
end

function ZO_SceneGroup:SetActiveScene(sceneName)
    self.activeScene = self:GetSceneIndexFromScene(sceneName) or 1
end

function ZO_SceneGroup:GetSceneIndexFromScene(sceneName)
    for i=1, #self.scenes do
        if self.scenes[i] == sceneName then
            return i
        end
    end
end

function ZO_SceneGroup:HasScene(sceneName)
    return self:GetSceneIndexFromScene(sceneName) ~= nil
end

function ZO_SceneGroup:SetState(newState)
    if self.state ~= newState then
        local oldState = self.state
        self.state = newState
        self:FireCallbacks("StateChange", oldState, newState)
    end
end

function ZO_SceneGroup:GetState()
    return self.state
end

function ZO_SceneGroup:IsShowing()
    return (self.state == SCENE_GROUP_SHOWING) or (self.state == SCENE_GROUP_SHOWN)
end