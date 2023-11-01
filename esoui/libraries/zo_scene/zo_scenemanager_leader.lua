ZO_SceneManager_Leader = ZO_SceneManager_Base:Subclass()

--static

ZO_SceneManager_Leader.bypassHideSceneConfirmationReason = 0

function ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason(name)
    ZO_SceneManager_Leader.bypassHideSceneConfirmationReason = ZO_SceneManager_Leader.bypassHideSceneConfirmationReason + 1
    local reasonName = "ZO_BHSCR_"..name
    internalassert(_G[reasonName] == nil)
    _G[reasonName] = ZO_SceneManager_Leader.bypassHideSceneConfirmationReason
end

ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason("ALREADY_SEEN")
ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason("INTERACT_ENDED")

--class

function ZO_SceneManager_Leader:Initialize(...)
    ZO_SceneManager_Base.Initialize(self, ...)

    self.sceneStack = {}
    self.previousSceneStack = {}
    self.remoteSceneSequenceNumber = 0

    EVENT_MANAGER:RegisterForEvent("SceneManager", EVENT_REMOTE_SCENE_REQUEST, function(eventId, ...) self:OnRemoteSceneRequest(...) end)
end

-- sequence number

function ZO_SceneManager_Leader:GetNextSequenceNumber()
    self.remoteSceneSequenceNumber = self.remoteSceneSequenceNumber + 1
    return self.remoteSceneSequenceNumber
end

function ZO_SceneManager_Leader:OnRemoteSceneRequest(messageOrigin, requestType, sceneName)
    if messageOrigin ~= ZO_REMOTE_SCENE_CHANGE_ORIGIN then
        if requestType == REMOTE_SCENE_REQUEST_TYPE_SHOW_BASE_SCENE then
            self:ShowBaseScene()
            return
        end

        local scene = self:GetScene(sceneName)
        if scene then
            if requestType == REMOTE_SCENE_REQUEST_TYPE_SWAP then
                self:SwapCurrentScene(sceneName)
            else
                if self:IsShowing(sceneName) then
                    if requestType == REMOTE_SCENE_REQUEST_TYPE_HIDE then
                        self:Hide(sceneName)
                    end
                else
                    if requestType == REMOTE_SCENE_REQUEST_TYPE_PUSH then
                        self:Push(sceneName)
                    elseif requestType == REMOTE_SCENE_REQUEST_TYPE_SHOW then
                        self:Show(sceneName)
                    end
                end
            end
        end
    end
end

-- scene stack

function ZO_SceneManager_Leader:IsSceneOnStack(sceneName)
    if self.currentScene and self.nextScene and self.nextScenePushed and self.currentScene:GetName() == sceneName then
        return true
    end

    for i, currentSceneName in ipairs(self.sceneStack) do
        if currentSceneName == sceneName then
            return true
        end
    end

    return false
end

function ZO_SceneManager_Leader:IsSceneOnTopOfStack(sceneName)
    if self.currentScene and self.nextScene and self.nextScenePushed then
        return self.nextScene:GetName() == sceneName
    end
    return self.sceneStack[#self.sceneStack] == sceneName
end

function ZO_SceneManager_Leader:WasSceneOnStack(sceneName)
    for i, currentSceneName in ipairs(self.previousSceneStack) do
        if currentSceneName == sceneName then
            return true
        end
    end
    return false
end

function ZO_SceneManager_Leader:WasSceneOnTopOfStack(sceneName)
    if self.currentScene and self.nextScene and not self.nextSceneClearsSceneStack then
        return self.currentScene:GetName() == sceneName
    end

    return self.previousSceneStack[#self.previousSceneStack] == sceneName
end

function ZO_SceneManager_Leader:PushOnSceneStack(sceneName)
    if sceneName ~= self.baseScene:GetName() then
        self:CopySceneStackIntoPrevious()
        table.insert(self.sceneStack, sceneName)
    end
end

function ZO_SceneManager_Leader:PopScenesFromStack(numScenes)
    self:CopySceneStackIntoPrevious()
    for i = #self.sceneStack, #self.sceneStack - numScenes + 1, -1 do
        self.sceneStack[i] = nil
    end
end

function ZO_SceneManager_Leader:ClearSceneStack()
    self:CopySceneStackIntoPrevious()
    ZO_ClearNumericallyIndexedTable(self.sceneStack)
end

function ZO_SceneManager_Leader:CopySceneStackIntoPrevious()
    ZO_ClearNumericallyIndexedTable(self.previousSceneStack)
    for i, scene in ipairs(self.sceneStack) do
        self.previousSceneStack[i] = scene
    end
end

function ZO_SceneManager_Leader:CreateStackFromScratch(...)
    self:HideCurrentScene()
    self:ClearSceneStack()
    self:ShowBaseScene()
    self.dontAddCurrentSceneBackToStack = true
    local numScenes = select("#", ...)
    if numScenes > 0 then
        for i = 1, numScenes - 1 do
            self:PushOnSceneStack(select(i, ...))
        end
        self:Push(select(numScenes, ...))
    end
end

-- next scene overrides

function ZO_SceneManager_Leader:SetNextScene(nextScene, push, nextSceneClearsSceneStack, numScenesNextScenePops)
    ZO_SceneManager_Base.SetNextScene(self, nextScene, push, nextSceneClearsSceneStack, numScenesNextScenePops)

    self.nextScenePushed = push
    self.nextSceneClearsSceneStack = nextSceneClearsSceneStack
    self.numScenesNextScenePops = numScenesNextScenePops
end

-- scene logic

function ZO_SceneManager_Leader:PopScenes(numberOfScenes)
    if self.currentScene and self.currentScene:GetState() ~= SCENE_HIDING then
        local topSceneName
        if #self.sceneStack >= numberOfScenes then
            topSceneName = self.sceneStack[#self.sceneStack - numberOfScenes + 1]
        else
            topSceneName = self.baseScene:GetName()
        end

        local KEEP_SCENE_STACK = false
        self:Show(topSceneName, nil, KEEP_SCENE_STACK, numberOfScenes)
    end
end

function ZO_SceneManager_Leader:PopScenesAndShow(numberOfScenes, sceneToShow)
    if self.currentScene and self.currentScene:GetState() ~= SCENE_HIDING then
        if #self.sceneStack >= numberOfScenes then
            local KEEP_SCENE_STACK = false
            self:Show(sceneToShow, nil, KEEP_SCENE_STACK, numberOfScenes - 1)
        end
    end
end

--[[
    Replace the current scene with a new scene while preserving the stack
      Current Stack      -->      New Stack

    | Current Scene |           | New Scene |
    |    Scene 2    |           |  Scene 2  |
    |    Scene 1    |           |  Scene 1  |

    If there isn't actually anything on the stack, Show is used to replace the scene
--]]
function ZO_SceneManager_Leader:SwapCurrentScene(newCurrentScene)
    if #self.sceneStack >= 1 then
        local NUMBER_OF_SCENES_TO_POP = 1
        self:PopScenesAndShow(NUMBER_OF_SCENES_TO_POP, newCurrentScene)
    else
        self:Show(newCurrentScene)
    end
end

function ZO_SceneManager_Leader:Push(sceneName)
    local IS_PUSH = true
    self:Show(sceneName, IS_PUSH)
end

function ZO_SceneManager_Leader:ShowWithFollowup(sceneName, resultCallback, push, nextSceneClearsSceneStack, numScenesNextScenePops, bypassHideSceneConfirmationReason)
    if self:WillCurrentSceneConfirmHide(bypassHideSceneConfirmationReason) then
        self.currentScene:RegisterCallback("HideSceneConfirmationResult", resultCallback)
        self:Show(sceneName, push, nextSceneClearsSceneStack, numScenesNextScenePops, bypassHideSceneConfirmationReason)
    else
        self:Show(sceneName, push, nextSceneClearsSceneStack, numScenesNextScenePops, bypassHideSceneConfirmationReason)
        local ALLOWED_TO_HIDE_CURRENT_SCENE = true
        resultCallback(ALLOWED_TO_HIDE_CURRENT_SCENE)
    end
end

-- Note that push, nextSceneClearsSceneStack, numScenesNextScenePops, and bypassHideSceneConfirmationReason are meant to be INTERNAL parameters. They should NOT
-- be used when calling Show from outside of this file. These same params should be passed to ConfirmHideScene.
function ZO_SceneManager_Leader:Show(sceneName, push, nextSceneClearsSceneStack, numScenesNextScenePops, bypassHideSceneConfirmationReason)
    local currentScene = self.currentScene
    local nextScene = self.scenes[sceneName]

    if nextScene == nil then
        internalassert(false, string.format("Missing scene: %q", sceneName or "missing scene name"))
        return
    end

    if nextSceneClearsSceneStack == nil then
        nextSceneClearsSceneStack = true
    end
    if numScenesNextScenePops == nil then
        numScenesNextScenePops = 0
    end
    self.sceneQueuedForLoadingScreenDrop = nil

    --if a scene exists
    if currentScene then
        if self:WillNextSceneConfirmHide(bypassHideSceneConfirmationReason) then
            return
        end

        if nextScene ~= currentScene then
            --If we need confirmation to hide this scene go request it unless we've already done that and this is the response
            if self:WillCurrentSceneConfirmHide(bypassHideSceneConfirmationReason) then
                return currentScene:ConfirmHideScene(sceneName, push, nextSceneClearsSceneStack, numScenesNextScenePops, bypassHideSceneConfirmationReason)
            end

            if self.nextScene then
                if nextScene ~= self.nextScene then
                    local oldNextScene = self.nextScene
                    self:SetNextScene(nextScene, push, nextSceneClearsSceneStack, numScenesNextScenePops)
                    currentScene:RefreshFragments()

                    local CURRENT_SCENE_IGNORED = ""
                    local NO_SEQUENCE_NUMBER = 0
                    local FRAGMENT_COMPLETE_STATE_IGNORED = false
                    local nextSceneName = self.nextScene and self.nextScene:GetName() or ZO_REMOTE_SCENE_NO_SCENE_IDENTIFIER                        
                    SendLeaderToFollowerSync(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_SYNC_TYPE_CHANGE_NEXT_SCENE, CURRENT_SCENE_IGNORED, nextSceneName, NO_SEQUENCE_NUMBER, FRAGMENT_COMPLETE_STATE_IGNORED)

                    self:OnNextSceneRemovedFromQueue(oldNextScene, nextScene)
                end
            else
                self:SetNextScene(nextScene, push, nextSceneClearsSceneStack, numScenesNextScenePops)
                self:HideScene(currentScene)
            end
        else
            if currentScene:GetState() == SCENE_HIDING then
                local oldNextScene = self.nextScene
                self:ClearNextScene()
                self:ShowScene(currentScene)
                if oldNextScene then
                    self:OnNextSceneRemovedFromQueue(oldNextScene, self.nextScene)
                end
            end
        end
    else
        --otherwise, start showing this scene
        self.previousScene = self.currentScene
        self:SetCurrentScene(nextScene)
        self:ShowScene(self.currentScene)
    end
end

function ZO_SceneManager_Leader:Hide(sceneName)
    if self.currentScene and self.currentScene:GetName() == sceneName and self.currentScene:GetState() ~= SCENE_HIDING then
        self:PopScenes(1)
    end
end

function ZO_SceneManager_Leader:WillCurrentSceneConfirmHide(bypassHideSceneConfirmationReason)
    local currentScene = self.currentScene
    return currentScene and currentScene:HasHideSceneConfirmation() and bypassHideSceneConfirmationReason ~= ZO_BHSCR_ALREADY_SEEN and currentScene:IsShowing()
end

function ZO_SceneManager_Leader:WillNextSceneConfirmHide(bypassHideSceneConfirmationReason)
    local nextScene = self.nextScene
    return nextScene and nextScene:HasHideSceneConfirmation() and bypassHideSceneConfirmationReason ~= ZO_BHSCR_ALREADY_SEEN
end

function ZO_SceneManager_Leader:ShowScene(scene)
    ZO_SceneManager_Base.ShowScene(self, scene, self:GetNextSequenceNumber())
end

function ZO_SceneManager_Leader:HideScene(scene)
    ZO_SceneManager_Base.HideScene(self, scene, self:GetNextSequenceNumber())
end

function ZO_SceneManager_Leader:SyncFollower()
    local currentScene = self:GetCurrentScene()
    local syncType = currentScene:IsShowing() and REMOTE_SCENE_SYNC_TYPE_SHOW_SCENE or REMOTE_SCENE_SYNC_TYPE_HIDE_SCENE
    local currentSceneName = currentScene:GetName()
    local sequenceNumber = 0
    local currentSceneTransitionComplete = true
    if currentScene:IsRemoteScene() then
        sequenceNumber = currentScene:GetSequenceNumber()
        if currentScene:GetState() == SCENE_SHOWING or currentScene:GetState() == SCENE_HIDING then
            currentSceneTransitionComplete = currentScene:AreFragmentsDoneTransitioning()
        end
    end
    local nextSceneName = self.nextScene and self.nextScene:GetName() or ZO_REMOTE_SCENE_NO_SCENE_IDENTIFIER
    SendLeaderToFollowerSync(ZO_REMOTE_SCENE_CHANGE_ORIGIN, syncType, currentSceneName, nextSceneName, sequenceNumber, currentSceneTransitionComplete)
end

function ZO_SceneManager_Leader:OnSceneStateChange(scene, oldState, newState)
    if scene == self:GetCurrentScene() then
        if newState == SCENE_HIDING or newState == SCENE_SHOWING then
            self:SyncFollower()
        end
    end

    ZO_SceneManager_Base.OnSceneStateChange(self, scene, oldState, newState)
end

-- override of ZO_SceneManager_Base:OnSceneStateHidden
function ZO_SceneManager_Leader:OnSceneStateHidden(scene)
    local lastSceneGroup = scene:GetSceneGroup()
    local nextSceneGroup
    local currentNextScene = self.nextScene
    if currentNextScene then
        nextSceneGroup = currentNextScene:GetSceneGroup()
    end

    if lastSceneGroup ~= nextSceneGroup then
        if lastSceneGroup ~= nil then
            lastSceneGroup:SetState(SCENE_GROUP_HIDDEN)
        end
        if nextSceneGroup ~= nil then
            nextSceneGroup:SetState(SCENE_GROUP_SHOWING)

            -- Check to see if self.nextScene has changed as a result of nextSceneGroup:SetState(SCENE_GROUP_SHOWING)
            if currentNextScene ~= self.nextScene then
                -- If self.nextScene has changed and currentNextScene's scene group is no longer showing, we set its state to SCENE_GROUP_HIDDEN
                local newNextSceneGroup = self.nextScene and self.nextScene:GetSceneGroup()
                if nextSceneGroup ~= newNextSceneGroup then
                    nextSceneGroup:SetState(SCENE_GROUP_HIDDEN)
                end

                -- Update currentNextScene to the new scene
                currentNextScene = self.nextScene
            end
        end
    end

    if currentNextScene then
        local push = self.nextScenePushed
        if push then
            if not self.dontAddCurrentSceneBackToStack then
                self:PushOnSceneStack(scene:GetName())
            end
        elseif self.nextSceneClearsSceneStack then
            self:ClearSceneStack()
        elseif self.numScenesNextScenePops > 0 then
            self:PopScenesFromStack(self.numScenesNextScenePops)
        end

        if self.dontAddCurrentSceneBackToStack then
            self.dontAddCurrentSceneBackToStack = false
        else
            self.previousScene = self:GetCurrentScene()
        end

        self:SetCurrentScene(currentNextScene)
        self:ClearNextScene()
        self:ShowScene(self:GetCurrentScene())
    end
end

function ZO_SceneManager_Leader:SendFragmentCompleteMessage()
    self:SyncFollower()
end

function ZO_SceneManager_Leader:RequestShowLeaderBaseScene(bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason then
        local DEFAULT_PUSH = nil
        local DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK = nil
        local DEFAULT_NUM_SCENES_NEXT_SCENE_POPS = nil
        self:Show(self:GetBaseScene():GetName(), DEFAULT_PUSH, DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK, DEFAULT_NUM_SCENES_NEXT_SCENE_POPS, bypassHideSceneConfirmationReason)
    else
        self:ShowBaseScene()
    end
end
