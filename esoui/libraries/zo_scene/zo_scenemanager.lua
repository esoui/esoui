ZO_SceneManager = ZO_CallbackObject:Subclass()

function ZO_SceneManager:New()
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize()
    return manager
end

function ZO_SceneManager:Initialize()
    self.scenes = {}
    self.sceneGroups = {}
    self.previousSceneStack = {}
    self.sceneStack = {}
    self.callWhen = {}

    EVENT_MANAGER:RegisterForEvent("SceneManager", EVENT_REMOTE_SCENE_STATE_CHANGE, function(eventId, ...) self:OnRemoteSceneChange(...) end)
    EVENT_MANAGER:RegisterForEvent("SceneManager", EVENT_SHOW_REMOTE_BASE_SCENE, function(eventId, ...) self:ShowBaseScene(...) end)
end

function ZO_SceneManager:OnRemoteSceneChange(sceneName, sceneChangeType, sceneChangeOrigin)
    local scene = self:GetScene(sceneName)
    if scene and (sceneChangeOrigin ~= ZO_REMOTE_SCENE_CHANGE_ORIGIN) then
        if sceneChangeType == REMOTE_SCENE_STATE_CHANGE_TYPE_SWAP then
            self:OnRemoteSceneSwap(sceneName)
        else
            
            if self:IsShowing(sceneName) then
                if sceneChangeType == REMOTE_SCENE_STATE_CHANGE_TYPE_HIDE then
                    scene:SetSendsStateChanges(false)
                    self:OnRemoteSceneHide(sceneName)
                    scene:SetSendsStateChanges(true)
                end
            else
                if sceneChangeType == REMOTE_SCENE_STATE_CHANGE_TYPE_PUSH then
                    -- we need to send events on push because the result isn't known ahead of time
                    -- we need to inform remote scenes if we actually show as a result of the push
                    self:OnRemoteScenePush(sceneName)
                elseif sceneChangeType == REMOTE_SCENE_STATE_CHANGE_TYPE_SHOW then
                    -- we send events on show, because whatever requested us to show needs to know
                    -- what to do when we perform the show on our main stack
                    self:OnRemoteSceneShow(sceneName)
                end
            end
            
        end
    end
end

function ZO_SceneManager:OnRemoteSceneSwap(sceneName)
    self:SwapCurrentScene(sceneName)
end

function ZO_SceneManager:OnRemoteSceneHide(sceneName)
    self:Hide(sceneName)
end

function ZO_SceneManager:OnRemoteScenePush(sceneName)
    self:Push(sceneName)
end

function ZO_SceneManager:OnRemoteSceneShow(sceneName)
    self:Show(sceneName)
end

function ZO_SceneManager:Add(scene)
    local name = scene:GetName()
    self.scenes[name] = scene
end

function ZO_SceneManager:GetScene(sceneName)
    return self.scenes[sceneName]
end

function ZO_SceneManager:AddSceneGroup(sceneGroupName, sceneGroup)
    self.sceneGroups[sceneGroupName] = sceneGroup
end

function ZO_SceneManager:GetSceneGroup(sceneGroupName)
    return self.sceneGroups[sceneGroupName]
end

function ZO_SceneManager:IsSceneGroupShowing(sceneGroupName)
    local sceneGroup = self:GetSceneGroup(sceneGroupName)
    if sceneGroup then
        return sceneGroup:IsShowing()
    end

    return false
end

function ZO_SceneManager:SetBaseScene(sceneName)
    self.baseScene = self.scenes[sceneName]
end

function ZO_SceneManager:AddFragment(fragment)
    if(self.currentScene) then
        local state = self.currentScene:GetState()
        if(state == SCENE_SHOWING or state == SCENE_SHOWN) then
            self.currentScene:AddTemporaryFragment(fragment)
        end
    end
end

function ZO_SceneManager:RemoveFragment(fragment)
    if(self.currentScene) then
        local state = self.currentScene:GetState()
        if(state == SCENE_SHOWING or state == SCENE_SHOWN) then
            self.currentScene:RemoveTemporaryFragment(fragment)
        end
    end
end

function ZO_SceneManager:AddFragmentGroup(fragmentGroup)
    for i = 1, #fragmentGroup do
        self:AddFragment(fragmentGroup[i])
    end
end

function ZO_SceneManager:RemoveFragmentGroup(fragmentGroup)
    for i = 1, #fragmentGroup do
        self:RemoveFragment(fragmentGroup[i])
    end
end

function ZO_SceneManager:IsSceneOnStack(sceneName)
    if self.currentScene and self.nextScene and self.nextScenePushed and self.currentScene:GetName() == sceneName then
        return true
    end

    for i, currentSceneName in ipairs(self.sceneStack) do
        if(currentSceneName == sceneName) then
            return true
        end
    end
    return false
end

function ZO_SceneManager:WasSceneOnStack(sceneName)
    for i, currentSceneName in ipairs(self.previousSceneStack) do
        if(currentSceneName == sceneName) then
            return true
        end
    end
    return false
end

function ZO_SceneManager:IsSceneOnTopOfStack(sceneName)
    if self.currentScene and self.nextScene and self.nextScenePushed then
        return self.nextScene:GetName() == sceneName
    end
    return self.sceneStack[#self.sceneStack] == sceneName
end

function ZO_SceneManager:WasSceneOnTopOfStack(sceneName)
    if self.currentScene and self.nextScene and not self.nextSceneClearsSceneStack then
        return self.currentScene:GetName() == sceneName
    end
    return self.previousSceneStack[#self.previousSceneStack] == sceneName
end

function ZO_SceneManager:PushOnSceneStack(sceneName)
    if(sceneName ~= self.baseScene:GetName()) then
        self:CopySceneStackIntoPrevious()
        table.insert(self.sceneStack, sceneName)
    end
end

function ZO_SceneManager:PopScenesFromStack(numScenes)
    self:CopySceneStackIntoPrevious()
    for i = #self.sceneStack, #self.sceneStack - numScenes + 1, -1 do
        self.sceneStack[i] = nil
    end
end

function ZO_SceneManager:ClearSceneStack()
    self:CopySceneStackIntoPrevious()
    ZO_ClearNumericallyIndexedTable(self.sceneStack)
end


function ZO_SceneManager:ShowScene(scene)
    scene:SetState(SCENE_SHOWING)
    scene:DetermineIfTransitionIsComplete()
end

function ZO_SceneManager:HideScene(scene)
    scene:SetState(SCENE_HIDING)
    scene:DetermineIfTransitionIsComplete()
end

function ZO_SceneManager:SetNextScene(nextScene, push, nextSceneClearsSceneStack, numScenesNextScenePops)
    self.nextScene = nextScene
    self.nextScenePushed = push

    self.nextSceneClearsSceneStack = nextSceneClearsSceneStack
    self.numScenesNextScenePops = numScenesNextScenePops
end

function ZO_SceneManager:ClearNextScene()
    self.nextScene = nil
    self.nextScenePushed = nil
    self.nextSceneClearsSceneStack = nil
    self.numScenesNextScenePops = nil
end

function ZO_SceneManager:Push(sceneName)
    local scene = self:GetScene(sceneName)
    
    local isRemoteScene = scene and scene:IsRemoteScene()
    if isRemoteScene then
        scene:PushRemoteScene()
    end

    self:Show(sceneName, true)
end

-- Note that push, nextSceneClearsSceneStack and numScenesNextScenePops are meant to be INTERNAL parameters.  They should NOT
-- be used when calling Show from outside of this file
function ZO_SceneManager:Show(sceneName, push, nextSceneClearsSceneStack, numScenesNextScenePops)
    local currentScene = self.currentScene
    local nextScene = self.scenes[sceneName]

    if(nextScene) then
        if nextSceneClearsSceneStack == nil then
            nextSceneClearsSceneStack = true
        end
        if numScenesNextScenePops == nil then
            numScenesNextScenePops = 0
        end
        --if a scene exists
        if(currentScene) then
            if(nextScene ~= currentScene) then
                if(self.nextScene) then
                    if(nextScene ~= self.nextScene) then
                        local oldNextScene = self.nextScene
                        self:SetNextScene(nextScene, push, nextSceneClearsSceneStack, numScenesNextScenePops)
                        currentScene:RefreshFragments()
                        self:OnNextSceneRemovedFromQueue(oldNextScene, nextScene)
                    end
                else
                    self:SetNextScene(nextScene, push, nextSceneClearsSceneStack, numScenesNextScenePops)
                    self:HideScene(currentScene)
                end
            else
                if(currentScene:GetState() == SCENE_HIDING) then
                    self:ClearNextScene()
                    self:ShowScene(currentScene)
                end
            end
        else
            --otherwise, start showing this scene
            self.previousScene = self.currentScene
            self.currentScene = nextScene
            self:ShowScene(self.currentScene)
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
function ZO_SceneManager:SwapCurrentScene(newCurrentScene)
    if #self.sceneStack >= 1 then
        local NUMBER_OF_SCENES_TO_POP = 1
        self:PopScenesAndShow(NUMBER_OF_SCENES_TO_POP, newCurrentScene)
    else
        self:Show(newCurrentScene)
    end
end

function ZO_SceneManager:OnNextSceneRemovedFromQueue(oldNextScene, newNextScene)
    oldNextScene:OnRemovedFromQueue()
end

function ZO_SceneManager:Hide(sceneName)
    if(self.currentScene and self.currentScene:GetName() == sceneName and self.currentScene:GetState() ~= SCENE_HIDING) then
        self:PopScenes(1)
    end
end

function ZO_SceneManager:HideCurrentScene()
    if(self.currentScene) then
        self:Hide(self.currentScene:GetName())
    end
end

function ZO_SceneManager:PopScenes(numberOfScenes)
    if(self.currentScene and self.currentScene:GetState() ~= SCENE_HIDING) then
        local topSceneName
        if(#self.sceneStack >= numberOfScenes) then
            topSceneName = self.sceneStack[#self.sceneStack - numberOfScenes + 1]
        else
            topSceneName = self.baseScene:GetName()
        end

        local KEEP_SCENE_STACK = false
        self:Show(topSceneName, nil, KEEP_SCENE_STACK, numberOfScenes)
    end
end

function ZO_SceneManager:PopScenesAndShow(numberOfScenes, sceneToShow)
    if(self.currentScene and self.currentScene:GetState() ~= SCENE_HIDING) then
        if(#self.sceneStack >= numberOfScenes) then
            local KEEP_SCENE_STACK = false
            self:Show(sceneToShow, nil, KEEP_SCENE_STACK, numberOfScenes - 1)
        end
    end
end

function ZO_SceneManager:Toggle(sceneName)
    if(self.currentScene and self.currentScene:GetName() == sceneName and self:IsShowing(sceneName)) then
        self:ShowBaseScene()
    else
        self:Show(sceneName)
    end
end

function ZO_SceneManager:ShowBaseScene()
    if KEYBIND_STRIP then
        KEYBIND_STRIP:ClearKeybindGroupStateStack()
    end

    if(self.baseScene) then
        if(not self.currentScene or (self.currentScene ~= self.baseScene and self.nextScene ~= self.baseScene)) then
            self:Show(self.baseScene:GetName())
        end
    end
end

function ZO_SceneManager:IsShowing(sceneName)
    local currentScene = self.currentScene
    if(currentScene and currentScene:GetName() == sceneName and (currentScene:GetState() == SCENE_SHOWING or currentScene:GetState() == SCENE_SHOWN)) then
        return true
    else
        return false
    end
end

function ZO_SceneManager:IsShowingNext(sceneName)
    local nextScene = self.nextScene
    if(nextScene and nextScene:GetName() == sceneName) then
        return true
    else
        return false
    end
end

function ZO_SceneManager:GetBaseScene()
    return self.baseScene
end

function ZO_SceneManager:GetCurrentScene()
    return self.currentScene
end

function ZO_SceneManager:GetNextScene()
    return self.nextScene
end

function ZO_SceneManager:IsShowingBaseScene()
    if(self.baseScene) then
        return self:IsShowing(self.baseScene:GetName())
    end
    return false
end

function ZO_SceneManager:IsShowingBaseSceneNext()
    if(self.baseScene) then
        return self:IsShowingNext(self.baseScene:GetName())
    end
    return false
end

function ZO_SceneManager:CallWhen(sceneName, state, func)
    local sceneCallbackList = self.callWhen[sceneName]
    if(sceneCallbackList == nil) then
        sceneCallbackList = {}
        self.callWhen[sceneName] = sceneCallbackList
    end

    table.insert(sceneCallbackList, {state = state, func = func})
end

function ZO_SceneManager:TriggerCallWhens(sceneName, state)
    local sceneCallbackList = self.callWhen[sceneName]
    if(sceneCallbackList) then
        local i = 1
        while i <= #sceneCallbackList do
            local callWhenInfo = sceneCallbackList[i]
            if(callWhenInfo.state == state) then
                callWhenInfo.func()
                table.remove(sceneCallbackList, i)
            else
                i = i + 1
            end
        end
    end
end

function ZO_SceneManager:GetPreviousSceneName()
    if(self.previousScene) then
        return self.previousScene:GetName()
    end

    return nil
end

function ZO_SceneManager:GetCurrentSceneName()
    if(self.currentScene) then
        return self.currentScene:GetName()
    end

    return nil
end

function ZO_SceneManager:OnSceneStateChange(scene, oldState, newState)
    if(scene == self.currentScene) then
        if oldState == SCENE_HIDING and newState == SCENE_HIDDEN then
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
                    self.previousScene = self.currentScene
                end

                self.currentScene = currentNextScene
                self:ClearNextScene()
                self:ShowScene(self.currentScene, push)
            end
        elseif newState == SCENE_SHOWN then
            local sceneGroup = scene:GetSceneGroup()
            if sceneGroup then
                sceneGroup:SetState(SCENE_GROUP_SHOWN)
            end
        end
    end
    self:TriggerCallWhens(scene:GetName(), newState)
    self:FireCallbacks("SceneStateChanged", scene, oldState, newState)
end

function ZO_SceneManager:OnPreSceneStateChange(scene, currentState, nextState)

end

function ZO_SceneManager:CopySceneStackIntoPrevious()
    ZO_ClearNumericallyIndexedTable(self.previousSceneStack)
    for i, scene in ipairs(self.sceneStack) do
        self.previousSceneStack[i] = scene
    end
end

function ZO_SceneManager:IsCurrentSceneGamepad()
    if self.currentScene then
        return self.currentScene:WasShownInGamepadPreferredMode()
    else
        return false
    end
end

function ZO_SceneManager:CreateStackFromScratch(...)
    self:HideCurrentScene()
    self:ClearSceneStack()
    self:ShowBaseScene()
    self.dontAddCurrentSceneBackToStack = true
    local scenes = {...}
    local numScenes = select("#", ...)
    if numScenes > 0 then
        for i = 1, numScenes - 1 do
            self:PushOnSceneStack(select(i, ...))
        end
        self:Push(select(numScenes, ...))
    end
end