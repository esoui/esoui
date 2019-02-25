ZO_SceneFragment = ZO_CallbackObject:Subclass()

SCENE_FRAGMENT_SHOWN = "shown"
SCENE_FRAGMENT_HIDDEN = "hidden"
SCENE_FRAGMENT_SHOWING = "showing"
SCENE_FRAGMENT_HIDING = "hiding"

function ZO_SceneFragment:New(...)
    local fragment = ZO_CallbackObject.New(self)
    fragment:Initialize(...)
    return fragment
end

function ZO_SceneFragment:Initialize()
    self.state = SCENE_FRAGMENT_HIDDEN
    self.allowShowHideTimeUpdates = false
end

function ZO_SceneFragment:IsValidSceneManagerChange(newSceneManager)
    -- Instead of there being at most 1 scenemanager, there are now N scenemanagers with N active scenes.
    -- Since a fragment can be owned by only 1 scene manager at a time, we need to make sure we aren't constructing a state where two scenes are both visible and sharing the same fragment.
    local oldSceneManager = self.sceneManager
    if oldSceneManager == nil or oldSceneManager == newSceneManager then
        -- no change
        return true
    end

    local oldParentScene = oldSceneManager:GetParentScene()
    if oldParentScene ~= nil and oldParentScene:GetState() == SCENE_HIDDEN then
        -- If the old scene manager is parented to a scene, but that scene is hidden, then the subscene is effectively hidden.
        return true
    end

    local oldCurrentScene = oldSceneManager:GetCurrentScene()
    if oldCurrentScene == nil or oldCurrentScene:GetState() == SCENE_HIDDEN then
        -- the old scene is either hidden or nonexistent, we can safely steal this fragment from it
        return true
    end

    if oldCurrentScene:HasFragment(self) then
        local assertString = "Trying to change scene managers, but the old scene manager (%s, state:%s) still contains this fragment"
        internalassert(false, string.format(assertString, oldCurrentScene:GetName(), oldCurrentScene:GetState()))
        return false
    end

    return true
end

function ZO_SceneFragment:SetSceneManager(newSceneManager)
    if self:IsValidSceneManagerChange(newSceneManager) then
        self.sceneManager = newSceneManager
    end
end

function ZO_SceneFragment:GetCategory()
    return self.category
end

function ZO_SceneFragment:SetCategory(category)
    self.category = category
end

--Force Refresh causes a fragment to hide and show again even if it is part of the next scene.

function ZO_SceneFragment:GetForceRefresh()
    return self.forceRefresh
end

function ZO_SceneFragment:SetForceRefresh(forceRefresh)
    self.forceRefresh = forceRefresh
end

function ZO_SceneFragment:AddDependency(fragment)
    if(not self.dependencies) then
        self.dependencies = {}
    end
    self.dependencies[fragment] = true
end

function ZO_SceneFragment:AddDependencies(...)
    for i = 1, select("#", ...) do
        self:AddDependency(select(i, ...))
    end
end

function ZO_SceneFragment:IsDependentOn(fragment)
    if(self.dependencies) then
        return self.dependencies[fragment] == true
    end
    return false
end

function ZO_SceneFragment:HasDependencies()
    return self.dependencies ~= nil
end

function ZO_SceneFragment:GetHideOnSceneHidden()
    return self.hideOnSceneHidden
end

function ZO_SceneFragment:SetHideOnSceneHidden(hideOnSceneHidden)
    self.hideOnSceneHidden = hideOnSceneHidden
end

--Show and Hide will be called by the scene management system. They should not be called directly by code.
function ZO_SceneFragment:Show()
    self:OnShown()
end

function ZO_SceneFragment:Hide()
    self:OnHidden()
end

function ZO_SceneFragment:GetState()
    return self.state
end

function ZO_SceneFragment:IsShowing()
    return self.state == SCENE_FRAGMENT_SHOWING or self.state == SCENE_FRAGMENT_SHOWN
end

function ZO_SceneFragment:IsHidden()
    return self.state == SCENE_FRAGMENT_HIDDEN
end

function ZO_SceneFragment:SetConditional(conditional)
    self.conditional = conditional
end

function ZO_SceneFragment:HasConditional()
    return self.conditional ~= nil
end

--If true, Show and Hide will be called even if the fragment is already in the Showing or Hiding state.
function ZO_SceneFragment:SetAllowShowHideTimeUpdates(allow)
    self.allowShowHideTimeUpdates = allow
end

function ZO_SceneFragment:SetState(newState)
    if(newState ~= self.state) then
        local oldState = self.state
        self.state = newState
        self:FireCallbacks("StateChange", oldState, newState)
        local currentScene = self.sceneManager:GetCurrentScene()
        if(currentScene) then
            currentScene:OnSceneFragmentStateChange(self, oldState, newState)
        end
    end
end

function ZO_SceneFragment:OnShown()
    self:SetState(SCENE_FRAGMENT_SHOWN)
end

function ZO_SceneFragment:OnHidden()
    self:SetState(SCENE_FRAGMENT_HIDDEN)
end

function ZO_SceneFragment:ShouldBeShown(customShowParam)
    if(self.state ~= SCENE_FRAGMENT_SHOWN and (self.allowShowHideTimeUpdates == true or self.state ~= SCENE_FRAGMENT_SHOWING)) then
        self:SetState(SCENE_FRAGMENT_SHOWING)
        self:Show(customShowParam)
    end
end

function ZO_SceneFragment:ShouldBeHidden(customHideParam)
    if(self.state ~= SCENE_FRAGMENT_HIDDEN and (self.allowShowHideTimeUpdates == true or self.state ~= SCENE_FRAGMENT_HIDING)) then
        self:SetState(SCENE_FRAGMENT_HIDING)
        if(not self.hideOnSceneHidden) then
            self:Hide(customHideParam)
        end
    end
end

function ZO_SceneFragment:ComputeIfFragmentShouldShow()
    if self.sceneManager then
        local sceneManagerParentScene = self.sceneManager:GetParentScene()
        if sceneManagerParentScene and sceneManagerParentScene:IsHiding() then
            return false
        end

        local currentScene = self.sceneManager:GetCurrentScene()
        local nextScene = self.sceneManager:GetNextScene()
        if currentScene and currentScene:HasFragment(self) then
            if self.conditional == nil or self.conditional() then
                local currentSceneState = currentScene:GetState()
                if nextScene then
                    if currentSceneState == SCENE_HIDING or currentSceneState == SCENE_HIDDEN then
                        if nextScene:HasFragment(self) then
                            if self.forceRefresh then
                                -- always hide on a force refresh
                                return false
                            elseif self:HasDependencies() then
                                for dependencyFragment in pairs(self.dependencies) do
                                    local currentHasDependency = currentScene:HasFragment(dependencyFragment)
                                    local nextHasDependency = nextScene:HasFragment(dependencyFragment)
                                    if currentHasDependency ~= nextHasDependency then
                                        return false
                                    end
                                end
                                return true
                            else
                                -- next scene has this fragment so we should show
                                return true
                            end
                        else
                            -- next scene does not have this fragment, so we should hide
                            return false
                        end
                    end
                else
                    if currentSceneState == SCENE_SHOWING or currentSceneState == SCENE_SHOWN then
                        return true
                    end
                end
            else
                -- the fragment failed its conditional, so we shouldn't show
                return false
            end
        else
            -- Either we have no current scene or the current scene doesn't have this fragment, we shouldn't be showing
            return false
        end
    end

    return false
end

function ZO_SceneFragment:Refresh(customShowParam, customHideParam, asAResultOfSceneStateChange, refreshedForScene)
    local oldState = self.state
    if self:ComputeIfFragmentShouldShow() then
        self:ShouldBeShown(customShowParam)
    else
        self:ShouldBeHidden(customHideParam)
    end
    self:FireCallbacks("Refreshed", oldState, self.state, asAResultOfSceneStateChange, refreshedForScene)
end