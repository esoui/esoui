do
    local ORIGIN_COLOR =
    {
        [SCENE_MANAGER_MESSAGE_ORIGIN_PREGAME] = ZO_ColorDef:New(1, 0.6, 0.6),
        [SCENE_MANAGER_MESSAGE_ORIGIN_INGAME] = ZO_ColorDef:New(0.6, 1, 0.6),
        [SCENE_MANAGER_MESSAGE_ORIGIN_INTERNAL] = ZO_ColorDef:New(0.6, 0.6, 1),
    }

    function ZO_Scene_GetOriginColor()
        return ORIGIN_COLOR[ZO_REMOTE_SCENE_CHANGE_ORIGIN]
    end
end

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

local g_loggingEnabled = false

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
    self.restoresHUDSceneToggleUIMode = false
    self.restoresHUDSceneToggleGameMenu = false
    self.disallowEvaluateTransitionCompleteCount = 0

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
            self.stackFragmentGroups[#self.stackFragmentGroups] = nil
            if #self.stackFragmentGroups > 0 then
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

function ZO_Scene:IsHiding()
    return self.state == SCENE_HIDING or self.state == SCENE_HIDDEN
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
        self:Log(string.format("Scene %s", newState))
        local oldState = self.state
        --Making a local for the scene name so it appears in the traceback in case of errors
        local name = self.name
        self.sceneManager:OnPreSceneStateChange(self, oldState, newState)
        self.state = newState
        if self.state == SCENE_SHOWING then
            self.wasShownInGamepadPreferredMode = IsInGamepadPreferredMode()
            self:UpdateFragmentsToCurrentSceneManager()
        end
        --We will DetermineIfTransitionIsComplete when calling RefreshFragments below. Allowing DetermineIfTransitionIsComplete before then will not have allowed the fragments to react the scene state change which
        --can cause the scene to finish the transition before some fragments even got a chance to try hiding or showing. The specific case that triggered this was removing a temporary fragment in the scene hiding callback.
        self:DisallowEvaluateTransitionComplete()
        self:FireCallbacks("StateChange", oldState, newState)
        self.sceneManager:OnSceneStateChange(self, oldState, newState)
        if self.state == SCENE_HIDDEN then
            self:RemoveTemporaryFragments()
            if not SCENE_MANAGER:IsSceneOnStack(self.name) then
                self:RemoveStackFragmentGroups()
            end
        end
        self:AllowEvaluateTransitionComplete()
        local AS_A_RESULT_OF_SCENE_STATE_CHANGE = true
        self:RefreshFragments(AS_A_RESULT_OF_SCENE_STATE_CHANGE)
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
        for stackFragmentGroupIndex, stackFragmentGroup in ipairs(self.stackFragmentGroups) do
            stackFragmentGroup:SetActive(false)
            local fragments = stackFragmentGroup:GetFragments()
            for fragmentIndex, fragment in ipairs(fragments) do
                self:RemoveFragment(fragment)
                fragment:Refresh()
            end
        end
        ZO_ClearNumericallyIndexedTable(self.stackFragmentGroups)
    end
end

function ZO_Scene:RefreshFragmentsHelper(asAResultOfSceneStateChange, ...)
    local NO_CUSTOM_SHOW_PARAMETER = nil
    local NO_CUSTOM_HIDE_PARAMETER = nil
    for i = 1, select("#", ...) do
        local fragment = select(i, ...)
        fragment:Refresh(NO_CUSTOM_SHOW_PARAMETER, NO_CUSTOM_HIDE_PARAMETER, asAResultOfSceneStateChange, self)
    end
end

function ZO_Scene:RefreshFragments(asAResultOfSceneStateChange)
    --wait until after we have refreshed all fragments to evaluate if we're done 
    self:DisallowEvaluateTransitionComplete()
    --Protect against fragments being added or removed during iteration by unpacking onto the stack
    self:RefreshFragmentsHelper(asAResultOfSceneStateChange, unpack(self.fragments))
    self:AllowEvaluateTransitionComplete()
    self:DetermineIfTransitionIsComplete()
end

function ZO_Scene:UpdateFragmentsToCurrentSceneManager()
    for _, fragment in ipairs(self.fragments) do
        fragment:SetSceneManager(self.sceneManager)
    end
end

function ZO_Scene:OnSceneFragmentStateChange(fragment, oldState, newState)
    self:DetermineIfTransitionIsComplete()
end

function ZO_Scene:HideAllHideOnSceneHiddenFragments(...)
    local allHiddenImmediately = true
    for i = 1, select("#", ...) do
        local fragment = select(i, ...)
        if fragment:GetHideOnSceneHidden() and not fragment:ComputeIfFragmentShouldShow() then
            fragment:Hide()
            if fragment:GetState() ~= SCENE_FRAGMENT_HIDDEN then
                allHiddenImmediately = false
            end
        end
    end
    return allHiddenImmediately
end

function ZO_Scene:IsTransitionComplete()
    local hasHideOnSceneHiddenFragments = false
    if self.state == SCENE_SHOWING or self.state == SCENE_HIDING then
        for _, fragment in ipairs(self.fragments) do
            local fragmentState = fragment:GetState()
            if self.state == SCENE_SHOWING then
                --If we waited for a fragment with a conditional to show before considering the scene shown we may wait forever,
                --because the conditional may not be true. So we just ignore them on show.
                if not fragment:HasConditional() and fragmentState ~= SCENE_FRAGMENT_SHOWN then
                    return false
                end
            elseif self.state == SCENE_HIDING then
                if fragmentState == SCENE_FRAGMENT_HIDING then
                    if fragment:GetHideOnSceneHidden() then
                        hasHideOnSceneHiddenFragments = true
                    else
                        return false
                    end
                end
            end
        end
    end

    if hasHideOnSceneHiddenFragments then
        --dont evaluate whether we should transition as a result of hiding a fragment here
        --since we're already evaluating that right now and will return the correct result
        self:DisallowEvaluateTransitionComplete()
        --Protect against fragments being added or removed during iteration by unpacking onto the stack
        local allHiddenImmediately = self:HideAllHideOnSceneHiddenFragments(unpack(self.fragments))
        self:AllowEvaluateTransitionComplete()
        return allHiddenImmediately
    end

    return true
end

function ZO_Scene:AllowEvaluateTransitionComplete()
    self.disallowEvaluateTransitionCompleteCount = self.disallowEvaluateTransitionCompleteCount - 1
end

function ZO_Scene:DisallowEvaluateTransitionComplete()
    self.disallowEvaluateTransitionCompleteCount = self.disallowEvaluateTransitionCompleteCount + 1
end

function ZO_Scene:DetermineIfTransitionIsComplete()
    if self.disallowEvaluateTransitionCompleteCount ~= 0 then
        return
    end

    local nextState = nil
    if self.state == SCENE_SHOWING then
        nextState = SCENE_SHOWN
    elseif self.state == SCENE_HIDING then
        nextState = SCENE_HIDDEN
    end

    if not nextState then
        return
    end

    if self:IsTransitionComplete() then
        self:OnTransitionComplete(nextState)
    end
end

function ZO_Scene:OnTransitionComplete(nextState)
    self:SetState(nextState)
end

function ZO_Scene:GetSceneGroup()
    return self.sceneGroup
end

function ZO_Scene:SetSceneGroup(sceneGroup)
    self.sceneGroup = sceneGroup
end

function ZO_Scene:SetHideSceneConfirmationCallback(callback)
    self.hideSceneConfirmationCallback = callback
end

function ZO_Scene:HasHideSceneConfirmation()
    return self.hideSceneConfirmationCallback ~= nil
end

function ZO_Scene:ConfirmHideScene(nextSceneName, push, nextSceneClearsSceneStack, numScenesNextScenePops, bypassHideSceneConfirmationReason)
    self.hideSceneConfirmationNextSceneName = nextSceneName
    self.hideSceneConfirmationPush = push
    self.hideSceneConfirmationNextSceneClearsSceneStack = nextSceneClearsSceneStack
    self.hideSceneConfirmationNumScenesNextScenePops = numScenesNextScenePops
    self.hideSceneConfirmationCallback(self, nextSceneName, bypassHideSceneConfirmationReason)
end

local function ClearHideSceneConfirmationState(self)
    self.hideSceneConfirmationNextSceneName = nil
    self.hideSceneConfirmationPush = nil
    self.hideSceneConfirmationNextSceneClearsSceneStack = nil
    self.hideSceneConfirmationNumScenesNextScenePops = nil
    self:UnregisterAllCallbacks("HideSceneConfirmationResult")
end

function ZO_Scene:AcceptHideScene()
    local nextSceneName = self.hideSceneConfirmationNextSceneName
    local push = self.hideSceneConfirmationPush
    local nextSceneClearsSceneStack = self.hideSceneConfirmationNextSceneClearsSceneStack
    local numScenesNextScenePops = self.hideSceneConfirmationNumScenesNextScenePops
    self:FireCallbacks("HideSceneConfirmationResult", true)
    ClearHideSceneConfirmationState(self)
    SCENE_MANAGER:Show(nextSceneName, push, nextSceneClearsSceneStack, numScenesNextScenePops, ZO_BHSCR_ALREADY_SEEN)
end

function ZO_Scene:RejectHideScene()
    self:FireCallbacks("HideSceneConfirmationResult", false)
    ClearHideSceneConfirmationState(self)
end

function ZO_Scene:WasShownInGamepadPreferredMode()
    return self.wasShownInGamepadPreferredMode
end

function ZO_Scene:IsRemoteScene()
    return false
end

function ZO_Scene:DoesSceneRestoreHUDSceneFromToggleUIMode()
    return self.restoresHUDSceneToggleUIMode
end

function ZO_Scene:DoesSceneRestoreHUDSceneFromToggleGameMenu()
    return self.restoresHUDSceneToggleGameMenu
end

function ZO_Scene:SetSceneRestoreHUDSceneToggleUIMode(restoreScene)
    self.restoresHUDSceneToggleUIMode = restoreScene
end

function ZO_Scene:SetSceneRestoreHUDSceneToggleGameMenu(restoreScene)
    self.restoresHUDSceneToggleGameMenu = restoreScene
end

function ZO_Scene:Log(message)
    if WriteToInterfaceLog and g_loggingEnabled then
        WriteToInterfaceLog(string.format("%s - %s - %s", ZO_Scene_GetOriginColor():Colorize(GetString("SI_SCENEMANAGERMESSAGEORIGIN", ZO_REMOTE_SCENE_CHANGE_ORIGIN)), self.name, message))
    end
end

----------
--Remote Scene
----------

ZO_RemoteScene = ZO_Scene:Subclass()

function ZO_RemoteScene:New(...)
    return ZO_Scene.New(self, ...)
end

function ZO_RemoteScene:Initialize(name, sceneManager)
    ZO_Scene.Initialize(self, name, sceneManager)

    self.waitingOnRemoteFragmentTransition = false
    self.fragmentsFinishedTransition = false
end

function ZO_RemoteScene:SetState(newState)
    if self.state ~= newState then
        if newState == SCENE_HIDING or newState == SCENE_SHOWING then
            self.waitingOnRemoteFragmentTransition = true
            self.fragmentsFinishedTransition = false
        else
            self.waitingOnRemoteFragmentTransition = false
        end

        -- call parent SetState after we send out message because it could
        -- trigger another call to SetState and the events would be out of order
        ZO_Scene.SetState(self, newState)
    end
end

function ZO_RemoteScene:OnTransitionComplete(nextState)
    self.fragmentsFinishedTransition = true
    self:Log("Local Fragments Done Transitioning")
    SCENE_MANAGER:SendFragmentCompleteMessage()

    -- we are done, but some remote scene might not have reported that it is also done
    -- only set the state if both scenes have completed their transition
    if not self.waitingOnRemoteFragmentTransition then
        ZO_Scene.OnTransitionComplete(self, nextState)
    end
end

function ZO_RemoteScene:IsRemoteScene()
    return true
end

function ZO_RemoteScene:SetSequenceNumber(sequenceNumber)
    self.sequenceNumber = sequenceNumber
end

function ZO_RemoteScene:GetSequenceNumber()
    return self.sequenceNumber
end

function ZO_RemoteScene:AreFragmentsDoneTransitioning()
    return self.fragmentsFinishedTransition
end

function ZO_RemoteScene:OnRemoteSceneFinishedFragmentTransition(sequenceNumber)
    if self.waitingOnRemoteFragmentTransition then
        self:Log("Was Notified Remote Fragments Complete")
        if self:GetSequenceNumber() == sequenceNumber then
            self.waitingOnRemoteFragmentTransition = false
            self:DetermineIfTransitionIsComplete()
        else
            self:Log(string.format("Sequence Numbers did not match. Expected %d, got %d", self:GetSequenceNumber(), sequenceNumber))
        end
    end
end
