local g_loggingEnabled = false

ZO_SceneManager_Follower = ZO_SceneManager_Base:Subclass()

function ZO_SceneManager_Follower:New(...)
    return ZO_SceneManager_Base.New(self, ...)
end

function ZO_SceneManager_Follower:Initialize(...)
    ZO_SceneManager_Base.Initialize(self, ...)

    ZO_Scene:New("empty", self)
    self:SetBaseScene("empty")

    EVENT_MANAGER:RegisterForEvent("SceneManager", EVENT_REMOTE_SCENE_SYNC, function(eventId, ...) self:OnRemoteSceneSync(...) end)
end

function ZO_SceneManager_Follower:OnRemoteSceneSync(messageOrigin, syncType, sceneName)
    if messageOrigin ~= ZO_REMOTE_SCENE_CHANGE_ORIGIN then
        local scene = self:GetScene(sceneName)
        if scene == nil and sceneName ~= ZO_REMOTE_SCENE_NO_SCENE_IDENTIFIER then
            -- it's likely we were told about a scene changing that we don't have in our SceneManager,
            -- so we will use our base scene (the empty scene) so we don't interfere with the unknown scene
            scene = self.baseScene
            sceneName = self.baseScene:GetName()
        end

        if syncType == REMOTE_SCENE_SYNC_TYPE_SHOW_SCENE then
            self:Log("Sync Show", sceneName)
            if scene == self.baseScene then
                self:ShowBaseScene()
            else
                self:ShowScene(scene)
            end
        elseif syncType == REMOTE_SCENE_SYNC_TYPE_HIDE_SCENE then
            -- don't bother hiding the base scene if we are going to show the base scene next
            if not (scene == self.baseScene and self:GetNextScene() == scene) then
                self:Log("Sync Hide", sceneName)
                self:HideScene(scene)
            end
        elseif syncType == REMOTE_SCENE_SYNC_TYPE_SET_CURRENT_SCENE then
            self:Log("Sync Current", sceneName)
            if sceneName == ZO_REMOTE_SCENE_NO_SCENE_IDENTIFIER then
                self:SetCurrentScene(nil)
            else
                self:SetCurrentScene(scene)
            end
        elseif syncType == REMOTE_SCENE_SYNC_TYPE_SET_NEXT_SCENE then
            self:Log("Sync Next", sceneName)
            if sceneName == ZO_REMOTE_SCENE_NO_SCENE_IDENTIFIER then
                self:SetNextScene(nil)
            else
                self:SetNextScene(scene)
            end
        end
    end
end

function ZO_SceneManager_Follower:OnSceneStateHidden(scene)
    local lastSceneGroup = scene:GetSceneGroup()
    local nextSceneGroup
    if self.nextScene then
        nextSceneGroup = self.nextScene:GetSceneGroup()
    end

    if lastSceneGroup ~= nextSceneGroup then
        if lastSceneGroup ~= nil then
            lastSceneGroup:SetState(SCENE_GROUP_HIDDEN)
        end
        if nextSceneGroup ~= nil then
            nextSceneGroup:SetState(SCENE_GROUP_SHOWING)
        end
    end
end

-- We don't have a stack, so we can only really check if it's the current scene
function ZO_SceneManager_Follower:IsSceneOnStack(sceneName)
    if self.currentScene and self.currentScene:GetName() == sceneName then
        return true
    end

    return false
end

-- Without our own stack we don't know if a scene was ever on it, so return false
function ZO_SceneManager_Follower:WasSceneOnStack(sceneName)
    return false
end

-- Without a stack we can only really check if the scene is the current scene
-- and is being replaced
function ZO_SceneManager_Follower:WasSceneOnTopOfStack(sceneName)
    if self.currentScene and self.nextScene then
        return self.currentScene:GetName() == sceneName
    end

    return false
end

function ZO_SceneManager_Follower:Push(sceneName)
    MakeRemoteSceneRequest(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_REQUEST_TYPE_PUSH, sceneName)
    self:Log("Request Remote Push", sceneName)
end

function ZO_SceneManager_Follower:SwapCurrentScene(newCurrentSceneName)
    MakeRemoteSceneRequest(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_REQUEST_TYPE_SWAP, newCurrentSceneName)
    self:Log("Request Remote Swap", newCurrentSceneName)
end

function ZO_SceneManager_Follower:Show(sceneName)
    MakeRemoteSceneRequest(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_REQUEST_TYPE_SHOW, sceneName)
    self:Log("Request Remote Show", sceneName)
end

function ZO_SceneManager_Follower:Hide(sceneName)
    MakeRemoteSceneRequest(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_REQUEST_TYPE_HIDE, sceneName)
    self:Log("Request Remote Hide", sceneName)
end

function ZO_SceneManager_Follower:RequestShowLeaderBaseScene()
    MakeRemoteSceneRequest(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_REQUEST_TYPE_SHOW_BASE_SCENE, "")
    self:Log("Request Remote Show Base Scene", "")
end

function ZO_SceneManager_Follower:Log(message, sceneName)
    if WriteToInterfaceLog and g_loggingEnabled then
        WriteToInterfaceLog(string.format("%s - %s - %s", GetString("SI_SCENEMANAGERMESSAGEORIGIN", ZO_REMOTE_SCENE_CHANGE_ORIGIN), sceneName, message))
    end
end
