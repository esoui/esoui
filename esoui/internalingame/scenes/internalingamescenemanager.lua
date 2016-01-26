ZO_REMOTE_SCENE_CHANGE_ORIGIN = REMOTE_SCENE_STATE_CHANGE_ORIGIN_INTERNAL

local ZO_InternalIngameSceneManager = ZO_SceneManager:Subclass()

function ZO_InternalIngameSceneManager:New(...)
    local manager = ZO_SceneManager.New(self, ...)
    return manager
end

function ZO_InternalIngameSceneManager:Initialize()
    ZO_SceneManager.Initialize(self)
    self.topLevelWindows = {}
    self.numTopLevelShown = 0
end

function ZO_InternalIngameSceneManager:OnRemoteSceneSwap(sceneName)
    -- we'll just let the ingame GUI tell us if we should show or not
end

function ZO_InternalIngameSceneManager:OnRemoteScenePush(sceneName)
    -- we don't keep a stack so ignore
end

function ZO_InternalIngameSceneManager:OnScenesLoaded()
    self:SetBaseScene("empty")
    self:Show("empty")
end

function ZO_InternalIngameSceneManager:Push(sceneName)
    local scene = self:GetScene(sceneName)
    local isRemoteScene = scene and scene:IsRemoteScene()

    if isRemoteScene then
        scene:PushRemoteScene()
    end

    -- we need the ingame GUI to tell us whether we actually get to show or not
    -- so do nothing here
end

function ZO_InternalIngameSceneManager:SwapCurrentScene(newCurrentScene)
    local scene = self:GetScene(newCurrentScene)
    local isRemoteScene = scene and scene:IsRemoteScene()

    if isRemoteScene then
        scene:SwapRemoteScene()
    end
end

--Top Levels

function ZO_InternalIngameSceneManager:RegisterTopLevel(topLevel, locksUIMode)
    topLevel.locksUIMode = locksUIMode
    self.topLevelWindows[topLevel] = true
end

function ZO_InternalIngameSceneManager:HideTopLevel(topLevel)
    if(not topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true) then
        topLevel:SetHidden(true)
        self.numTopLevelShown = self.numTopLevelShown - 1
    end
end

function ZO_InternalIngameSceneManager:ShowTopLevel(topLevel)
    if(topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true) then
        topLevel:SetHidden(false)
        self.numTopLevelShown = self.numTopLevelShown + 1
    end    
end

function ZO_InternalIngameSceneManager:ToggleTopLevel(topLevel)
    if(topLevel:IsControlHidden()) then
        self:ShowTopLevel(topLevel)
    else
        self:HideTopLevel(topLevel)
    end
end

function ZO_InternalIngameSceneManager:HideTopLevels()
    local topLevelHidden = false
    for topLevel, _ in pairs(self.topLevelWindows) do
        if(not topLevel:IsControlHidden()) then
            self:HideTopLevel(topLevel)
            topLevelHidden = true
        end
    end

    return topLevelHidden
end

SCENE_MANAGER = ZO_InternalIngameSceneManager:New()
