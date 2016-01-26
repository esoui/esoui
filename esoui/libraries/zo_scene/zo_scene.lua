-----------------------
--Scene Stack Fragments
-----------------------

ZO_StackFragmentGroup = ZO_Object:Subclass()

function ZO_StackFragmentGroup:New(fragment, object)
    local group = ZO_Object.New(self)
    group.fragments = {}
    group.objects = {}
    group.activateAll = false
    group:Add(fragment, object)
    return group
end

function ZO_StackFragmentGroup:Add(fragment, object)
    if(fragment) then
        table.insert(self.fragments, fragment)
        table.insert(self.objects, object or false)
    end
end

function ZO_StackFragmentGroup:SetOnActivatedCallback(onActivatedCallback)
    self.onActivatedCallback = onActivatedCallback
end

function ZO_StackFragmentGroup:SetOnDeactivatedCallback(onDeactivatedCallback)
    self.onDeactivatedCallback = onDeactivatedCallback
end

function ZO_StackFragmentGroup:SetActivateAll(activateAll)
    self.activateAll = activateAll
end

function ZO_StackFragmentGroup:GetFragments()
    return self.fragments
end

function ZO_StackFragmentGroup:SetActive(active)
    for i, object in ipairs(self.objects) do
        if(object) then
            object:SetActive(active)
            if(not self.activateAll) then
                break
            end
        end
    end

    if active then
        if self.onActivatedCallback then
            self.onActivatedCallback()
        end
    else
        if self.onDeactivatedCallback then
            self.onDeactivatedCallback()
        end
    end
end

----------
--Scene
----------

ZO_Scene = ZO_CallbackObject:Subclass()

SCENE_SHOWN = "shown"
SCENE_HIDDEN = "hidden"
SCENE_SHOWING = "showing"
SCENE_HIDING = "hiding"

function ZO_Scene:New(...)
    local scene = ZO_CallbackObject.New(self)
    scene:Initialize(...)
    return scene
end

function ZO_Scene:Initialize(name, sceneManager)
    self.name = name
    self.state = SCENE_HIDDEN
    self.sceneManager = sceneManager
    self.fragments = {}

    sceneManager:Add(self)
end

function ZO_Scene:AddFragment(fragment)
    if not self:HasFragment(fragment) then
        table.insert(self.fragments, fragment)
        fragment:SetSceneManager(self.sceneManager)
        fragment:Refresh()
    end
end

function ZO_Scene:RemoveFragment(fragment)
    for i = 1, #self.fragments do
        if(self.fragments[i] == fragment) then
            table.remove(self.fragments, i)
            fragment:Refresh()
            break
        end
    end
end

function ZO_Scene:HasFragment(fragment)
    for i = 1, #self.fragments do
        if(self.fragments[i] == fragment) then
            return true
        end
    end
    return false
end

function ZO_Scene:AddTemporaryFragment(fragment)
    if not self:HasFragment(fragment) then
        if(not self.temporaryFragments) then
            self.temporaryFragments = {}
        end
        self.temporaryFragments[fragment] = true
        self:AddFragment(fragment)
        fragment:SetSceneManager(self.sceneManager)
        fragment:Refresh()
    end
end

function ZO_Scene:RemoveTemporaryFragment(fragment)
    if self.temporaryFragments and self.temporaryFragments[fragment] then
        self.temporaryFragments[fragment] = nil
        self:RemoveFragment(fragment)
        fragment:Refresh()
    end
end

function ZO_Scene:HasStackFragmentGroup(stackFragmentGroup)
    if(self.stackFragmentGroups) then
        for i = 1, #self.stackFragmentGroups do
            if(self.stackFragmentGroups[i] == stackFragmentGroup) then
                return true
            end
        end
    end
    return false
end

function ZO_Scene:PushStackFragmentGroup(stackFragmentGroup, isBase)
    if not self:HasStackFragmentGroup(stackFragmentGroup) then
        local fragments = stackFragmentGroup:GetFragments()
        for i, fragment in ipairs(fragments) do
            if self:HasFragment(fragment) then
                return
            end
        end

        if(not self.stackFragmentGroups) then
            self.stackFragmentGroups = {}
        end

        if(#self.stackFragmentGroups > 0) then
            self.stackFragmentGroups[#self.stackFragmentGroups]:SetActive(false)
        end
        table.insert(self.stackFragmentGroups, stackFragmentGroup)
        stackFragmentGroup:SetActive(true)

        if isBase then
            self.stackFragmentGroupBaseIndex = #self.stackFragmentGroups
        end
        
        for i, fragment in ipairs(fragments) do
            self:AddFragment(fragment)
            fragment:SetSceneManager(self.sceneManager)
            fragment:Refresh()
        end
    end
end

function ZO_Scene:PushBaseStackFragmentGroup(stackFragmentGroup)
    self:PushStackFragmentGroup(stackFragmentGroup, true)
end

function ZO_Scene:PopStackFragmentGroup()
    if(self.stackFragmentGroups and #self.stackFragmentGroups > 0) then
        local stackFragmentGroup = self.stackFragmentGroups[#self.stackFragmentGroups]
        stackFragmentGroup:SetActive(false)

        if self.stackFragmentGroupBaseIndex == #self.stackFragmentGroups then
            self.sceneManager:HideCurrentScene()
        else
            local fragments = stackFragmentGroup:GetFragments()
            for i, fragment in ipairs(fragments) do
                self:RemoveFragment(fragment)
                fragment:Refresh()
            end
            local hideCurrentSceneFromBaseFragment = self.stackFragmentGroupBaseIndex == #self.stackFragmentGroups
            self.stackFragmentGroups[#self.stackFragmentGroups] = nil
            if(#self.stackFragmentGroups > 0) then
                self.stackFragmentGroups[#self.stackFragmentGroups]:SetActive(true)
            end
        end
    else
        self.sceneManager:HideCurrentScene()
    end
end

function ZO_Scene:AddFragmentGroup(fragments)
    for _, fragment in pairs(fragments) do
        self:AddFragment(fragment)
    end
end

function ZO_Scene:RemoveFragmentGroup(fragments)
    for _, fragment in pairs(fragments) do
        self:RemoveFragment(fragment)
    end
end

function ZO_Scene:GetName()
    return self.name
end

function ZO_Scene:GetState()
    return self.state
end

function ZO_Scene:IsShowing()
    return self.state == SCENE_SHOWN or self.state == SCENE_SHOWING
end

function ZO_Scene:HasFragmentWithCategory(category)
    return self:GetFragmentWithCategory(category) ~= nil
end

function ZO_Scene:GetFragmentWithCategory(category)
    for _, fragment in ipairs(self.fragments) do
        local fragmentCategory = fragment:GetCategory()
        if(fragmentCategory == category) then
            return fragment
        end
    end
end

function ZO_Scene:SetState(newState)
    if self.state ~= newState then
        local oldState = self.state
        self.sceneManager:OnPreSceneStateChange(self, oldState, newState)
        self.state = newState
        if(self.state == SCENE_SHOWING) then
            self.wasShownInGamepadPreferredMode = IsInGamepadPreferredMode()
        end
        self:FireCallbacks("StateChange", oldState, newState)
        self.sceneManager:OnSceneStateChange(self, oldState, newState)
        if(self.state == SCENE_HIDDEN) then
            self:RemoveTemporaryFragments()
            if(not SCENE_MANAGER:IsSceneOnStack(self.name)) then
                self:RemoveStackFragmentGroups()
            end
        end
        self:RefreshFragments()
    end
end

function ZO_Scene:OnRemovedFromQueue()
    --Meant to be overriden
end

function ZO_Scene:RemoveTemporaryFragments()
    if(self.temporaryFragments) then
        for tempFragment in pairs(self.temporaryFragments) do
            self:RemoveFragment(tempFragment)
            tempFragment:Refresh()
        end
        self.temporaryFragments = nil
    end
end

function ZO_Scene:RemoveStackFragmentGroups()
    if(self.stackFragmentGroups) then
        for i, stackFragmentGroup in ipairs(self.stackFragmentGroups) do
            stackFragmentGroup:SetActive(false)
            local fragments = stackFragmentGroup:GetFragments()
            for i, fragment in ipairs(fragments) do
                self:RemoveFragment(fragment)
                fragment:Refresh()
            end
        end
        ZO_ClearNumericallyIndexedTable(self.stackFragmentGroups)
    end        
end

function ZO_Scene:RefreshFragmentsHelper(...)
    for i = 1, select("#", ...) do
        local fragment = select(i, ...)
        fragment:Refresh()
    end
end

function ZO_Scene:RefreshFragments()
    --wait until after we have refreshed all fragments to evaluate if we're done 
    self.allowEvaluateTransitionComplete = false
    --Protect against fragments being added or removed during iteration by unpacking onto the stack
    self:RefreshFragmentsHelper(unpack(self.fragments))
    self.allowEvaluateTransitionComplete = true
    self:DetermineIfTransitionIsComplete()
end

function ZO_Scene:OnSceneFragmentStateChange(fragment, oldState, newState)
    if(self.allowEvaluateTransitionComplete) then
        self:DetermineIfTransitionIsComplete()
    end
end

function ZO_Scene:HideAllHideOnSceneEndFragments(...)
    local allHiddenImmediately = true 
    for i = 1, select("#", ...) do
        local fragment = select(i, ...)
        if(fragment:GetHideOnSceneHidden()) then                
            fragment:Hide()
            if(fragment:GetState() ~= SCENE_FRAGMENT_HIDDEN) then
                allHiddenImmediately = false
            end
        end
    end
    return allHiddenImmediately
end

function ZO_Scene:IsTransitionComplete()
    local hasHideOnSceneHiddenFragments = false
    if(self.state == SCENE_SHOWING or self.state == SCENE_HIDING) then
        for _, fragment in ipairs(self.fragments) do
            local fragmentState = fragment:GetState()
            if(self.state == SCENE_SHOWING) then
                --If we waited for a fragment with a conditional to show before considering the scene shown we may wait forever,
                --because the conditional may not be true. So we just ignore them on show.
                if(not fragment:HasConditional() and fragmentState ~= SCENE_FRAGMENT_SHOWN) then
                    return false
                end
            elseif(self.state == SCENE_HIDING) then
                if(fragmentState == SCENE_FRAGMENT_HIDING) then
                    if(fragment:GetHideOnSceneHidden()) then
                        hasHideOnSceneHiddenFragments = true
                    else
                        return false
                    end
                end
            end
        end
    end

    if(hasHideOnSceneHiddenFragments) then
        --dont evaluate whether we should transition as a result of hiding a fragment here
        --since we're already evaluating that right now and will return the correct result
        self.allowEvaluateTransitionComplete = false
        --Protect against fragments being added or removed during iteration by unpacking onto the stack
        local allHiddenImmediately = self:HideAllHideOnSceneEndFragments(unpack(self.fragments))
        self.allowEvaluateTransitionComplete = true
        return allHiddenImmediately
    end

    return true
end

function ZO_Scene:DetermineIfTransitionIsComplete()
    if(self.state == SCENE_SHOWING) then
        if(self:IsTransitionComplete()) then
            self:SetState(SCENE_SHOWN)
        end
    elseif(self.state == SCENE_HIDING) then
        if(self:IsTransitionComplete()) then
            self:SetState(SCENE_HIDDEN)
        end
    end
end

function ZO_Scene:GetSceneGroup()
    return self.sceneGroup
end

function ZO_Scene:SetSceneGroup(sceneGroup)
    self.sceneGroup = sceneGroup
end

function ZO_Scene:WasShownInGamepadPreferredMode()
    return self.wasShownInGamepadPreferredMode
end

function ZO_Scene:IsRemoteScene()
    return false
end

----------
--Remote Scene
----------

ZO_RemoteScene = ZO_Scene:Subclass()

function ZO_RemoteScene:New(...)
    local scene = ZO_Scene.New(self, ...)
    return scene
end

function ZO_RemoteScene:Initialize(name, sceneManager)
    ZO_Scene.Initialize(self, name, sceneManager)
    self:SetSendsStateChanges(true)
end

function ZO_RemoteScene:SetState(newState)
    if self.state ~= newState then
        if self.sendStateChanges then
            if newState == SCENE_SHOWING then
                ChangeRemoteSceneVisibility(self.name, REMOTE_SCENE_STATE_CHANGE_TYPE_SHOW, ZO_REMOTE_SCENE_CHANGE_ORIGIN)
            elseif newState == SCENE_HIDING then
                ChangeRemoteSceneVisibility(self.name, REMOTE_SCENE_STATE_CHANGE_TYPE_HIDE, ZO_REMOTE_SCENE_CHANGE_ORIGIN)
            end
        end

        -- call parent SetState after we send out message becase it could
        -- trigger another call to SetState and the events would be out of order
        ZO_Scene.SetState(self, newState)
    end
end

function ZO_RemoteScene:SetSendsStateChanges(sendsState)
    self.sendStateChanges = sendsState
end

function ZO_RemoteScene:GetSendsStateChanges()
    return self.sendStateChanges
end

function ZO_RemoteScene:IsRemoteScene()
    return true
end

function ZO_RemoteScene:PushRemoteScene()
    if self.sendStateChanges then
        ChangeRemoteSceneVisibility(self.name, REMOTE_SCENE_STATE_CHANGE_TYPE_PUSH, ZO_REMOTE_SCENE_CHANGE_ORIGIN)
    end
end

function ZO_RemoteScene:SwapRemoteScene()
    if self.sendStateChanges then
        ChangeRemoteSceneVisibility(self.name, REMOTE_SCENE_STATE_CHANGE_TYPE_SWAP, ZO_REMOTE_SCENE_CHANGE_ORIGIN)
    end
end