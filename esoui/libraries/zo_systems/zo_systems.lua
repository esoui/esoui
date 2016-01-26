local ZO_Systems = ZO_Object:Subclass()

function ZO_Systems:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function ZO_Systems:Initialize()
    self.systems = {}
end

function ZO_Systems:GetSystem(systemName)
    local system = self.systems[systemName]
    if not system then
        system = {}
        self.systems[systemName] = system
    end
    return system
end

function ZO_Systems:RegisterKeyboardObject(systemName, object)
    self:GetSystem(systemName).keyboardObject = object
end

function ZO_Systems:RegisterGamepadObject(systemName, object)
    self:GetSystem(systemName).gamepadObject = object
end

function ZO_Systems:RegisterKeyboardRootScene(systemName, scene)
    self:GetSystem(systemName).keyboardRootScene = scene
end

function ZO_Systems:RegisterGamepadRootScene(systemName, scene)
    self:GetSystem(systemName).gamepadRootScene = scene
end

function ZO_Systems:GetKeyboardObject(systemName)
    return self:GetSystem(systemName).keyboardObject
end

function ZO_Systems:GetGamepadObject(systemName)
    return self:GetSystem(systemName).gamepadObject
end

function ZO_Systems:GetKeyboardRootScene(systemName)
    return self:GetSystem(systemName).keyboardRootScene
end

function ZO_Systems:GetGamepadRootScene(systemName)
    return self:GetSystem(systemName).gamepadRootScene
end

function ZO_Systems:GetObject(systemName)
    if IsInGamepadPreferredMode() then
        return self:GetGamepadObject(systemName)
    else
        return self:GetKeyboardObject(systemName)
    end
end

function ZO_Systems:GetObjectBasedOnCurrentScene(systemName)
    if SCENE_MANAGER:GetCurrentScene() then
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            return self:GetGamepadObject(systemName)
        else
            return self:GetKeyboardObject(systemName)
        end
    end
end

function ZO_Systems:GetRootScene(systemName)
    if IsInGamepadPreferredMode() then
        return self:GetGamepadRootScene(systemName)
    else
        return self:GetKeyboardRootScene(systemName)
    end
end

function ZO_Systems:GetRootSceneName(systemName)
    local rootScene = self:GetRootScene(systemName)
    if rootScene then
        return rootScene:GetName()
    else
        -- must be false, not nil, for some conditionals using this
        return false
    end
end

function ZO_Systems:ShowScene(systemName)
    local sceneName = self:GetRootSceneName(systemName)
    if sceneName then
        SCENE_MANAGER:Show(sceneName)
    end
end

function ZO_Systems:PushScene(systemName)
    local sceneName = self:GetRootSceneName(systemName)
    if sceneName then
        SCENE_MANAGER:Push(sceneName)
    end
end

function ZO_Systems:HideScene(systemName)
    local sceneName = self:GetRootSceneName(systemName)
    if sceneName then
        SCENE_MANAGER:Hide(sceneName)
    end
end

function ZO_Systems:IsShowing(systemName)
    local sceneName = self:GetRootSceneName(systemName)
    return sceneName and SCENE_MANAGER:IsShowing(self:GetRootScene(systemName):GetName())
end

SYSTEMS = ZO_Systems:New()