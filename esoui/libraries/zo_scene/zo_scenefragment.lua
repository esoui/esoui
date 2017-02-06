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
    self.allShowHideTimeUpdates = false
end

function ZO_SceneFragment:SetSceneManager(sceneManager)
    self.sceneManager = sceneManager
end

function ZO_SceneFragment:GetCategory()
    return self.category
end

function ZO_SceneFragment:SetCategory(category)
    self.category = category
end

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
    self.allShowHideTimeUpdates = allow
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
    if(self.state ~= SCENE_FRAGMENT_SHOWN and (self.allShowHideTimeUpdates == true or self.state ~= SCENE_FRAGMENT_SHOWING)) then
        self:SetState(SCENE_FRAGMENT_SHOWING)
        self:Show(customShowParam)
    end
end

function ZO_SceneFragment:ShouldBeHidden(customHideParam)
    if(self.state ~= SCENE_FRAGMENT_HIDDEN and (self.allShowHideTimeUpdates == true or self.state ~= SCENE_FRAGMENT_HIDING)) then
        self:SetState(SCENE_FRAGMENT_HIDING)
        if(not self.hideOnSceneHidden) then
            self:Hide(customHideParam)
        end
    end
end

function ZO_SceneFragment:Refresh(customShowParam, customHideParam)
    if(self.sceneManager) then
        local currentScene = self.sceneManager:GetCurrentScene()
        local nextScene = self.sceneManager:GetNextScene()
        if(currentScene and currentScene:HasFragment(self)) then
            if(self.conditional == nil or self.conditional()) then
                local currentSceneState = currentScene:GetState()
                if(nextScene) then
                    if(currentSceneState == SCENE_HIDING) then
                        if(nextScene:HasFragment(self)) then
                            if(self.forceRefresh) then
                                self:ShouldBeHidden(customHideParam)
                            elseif(self:HasDependencies()) then
                                for dependencyFragmnent in pairs(self.dependencies) do
                                    local currentHasDependency = currentScene:HasFragment(dependencyFragmnent)
                                    local nextHasDependency = nextScene:HasFragment(dependencyFragmnent)
                                    if(currentHasDependency ~= nextHasDependency) then
                                        self:ShouldBeHidden(customHideParam)
                                        return
                                    end
                                end
                                self:ShouldBeShown(customShowParam)
                            else
                                self:ShouldBeShown(customShowParam)
                            end
                        else
                            self:ShouldBeHidden(customHideParam)
                        end
                    end
                else
                    if(currentSceneState == SCENE_SHOWING or currentSceneState == SCENE_SHOWN) then
                        self:ShouldBeShown(customShowParam)
                    end
                end
            else
                self:ShouldBeHidden(customHideParam)
            end
        else
            self:ShouldBeHidden(customHideParam)
        end
    else
        self:ShouldBeHidden(customHideParam)
    end
end