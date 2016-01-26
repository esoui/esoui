SCENE_GROUP_SHOWING = "scene_group_showing"
SCENE_GROUP_SHOWN = "scene_group_shown"
SCENE_GROUP_HIDDEN = "scene_group_hidden"

ZO_SceneGroup = ZO_CallbackObject:Subclass()

function ZO_SceneGroup:New(...)
    local group = ZO_CallbackObject.New(self)
    group:Initialize(...)
    return group
end

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

function ZO_SceneGroup:SetActiveScene(scene)
    self.activeScene = self:GetSceneIndexFromScene(scene) or 1
end

function ZO_SceneGroup:GetSceneIndexFromScene(scene)
    for i=1, #self.scenes do
        if self.scenes[i] == scene then
            return i
        end
    end
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