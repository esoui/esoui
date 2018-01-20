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

        if syncType == REMOTE_SCENE_SYNC_TYPE_SHOW_SCENE then
            self:Log("Sync Show", sceneName)           
            if scene == nil then
                --It's likely we were told about a scene changing that we don't have in our SceneManager,
                --so we will use our base scene (the empty scene) so we don't interfere with the unknown scene.
                --This is basically deactivating the scene manager until we hear about something we know.           
                if not self.baseScene:IsShowing() then
                    self:Log(string.format("Sync Show Scene (%s) Unknown. Showing Base Scene", sceneName), self.baseScene:GetName())
                    self:ShowScene(self.baseScene)
                else
                    self:Log(string.format("Sync Show Scene (%s) Unknown. Base Scene Already Shown", sceneName), self.baseScene:GetName())
                end
            else
                --We were just told to show a scene we do know about. First get the base scene (the empty scene) out of the way
                --then show the requested scene. The empty scene will hide instantly. This is like reactivating the scene manager.
                if self.baseScene:IsShowing() then
                    self:HideScene(self.baseScene)
                end
                if not scene:IsShowing() then
                    self:ShowScene(scene)
                end
            end
        elseif syncType == REMOTE_SCENE_SYNC_TYPE_HIDE_SCENE then
           self:Log("Sync Hide", sceneName)
           if scene then
                if not scene:IsHiding() then
                    self:HideScene(scene)
                end
            else
                --Ignore any hides that we don't know about. The shows we don't know about control the activate/deactivate.
                self:Log(string.format("Sync Hide Scene (%s) Unknown. It had no effect!", sceneName)) 
            end
        elseif syncType == REMOTE_SCENE_SYNC_TYPE_SET_CURRENT_SCENE then
            self:Log("Sync Current", sceneName)
            if sceneName == ZO_REMOTE_SCENE_NO_SCENE_IDENTIFIER then
                self:SetCurrentScene(nil)
            else
                if scene == nil then
                    --if the current scene is a scene that we don't know then use the base scene instead
                    self:Log(string.format("Sync Current Scene (%s) Unknown. Setting Current to Base Scene", sceneName), self.baseScene:GetName())
                    scene = self.baseScene
                end
                self:SetCurrentScene(scene)
            end
        elseif syncType == REMOTE_SCENE_SYNC_TYPE_SET_NEXT_SCENE then
            self:Log("Sync Next", sceneName)
            if sceneName == ZO_REMOTE_SCENE_NO_SCENE_IDENTIFIER then
                self:SetNextScene(nil)
            else
                if scene == nil then
                    --if the next scene is a scene that we don't know then use the base scene instead
                    self:Log(string.format("Sync Next Scene (%s) Unknown. Setting Next to Base Scene", sceneName), self.baseScene:GetName())
                    scene = self.baseScene
                end
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
        if sceneName then
            WriteToInterfaceLog(string.format("%s - %s - %s", ZO_Scene_GetOriginColor():Colorize(GetString("SI_SCENEMANAGERMESSAGEORIGIN", ZO_REMOTE_SCENE_CHANGE_ORIGIN)), message, sceneName))
        else
            WriteToInterfaceLog(string.format("%s - %s", ZO_Scene_GetOriginColor():Colorize(GetString("SI_SCENEMANAGERMESSAGEORIGIN", ZO_REMOTE_SCENE_CHANGE_ORIGIN)), message))
        end
    end
end
