ZO_REMOTE_SCENE_CHANGE_ORIGIN = SCENE_MANAGER_MESSAGE_ORIGIN_INTERNAL

local ZO_InternalIngameSceneManager = ZO_SceneManager_Follower:Subclass()

function ZO_InternalIngameSceneManager:New(...)
    return ZO_SceneManager_Follower.New(self, ...)
end

function ZO_InternalIngameSceneManager:Initialize(...)
    ZO_SceneManager_Follower.Initialize(self, ...)
    self.topLevelWindows = {}
    self.numTopLevelShown = 0
end

function ZO_InternalIngameSceneManager:OnScenesLoaded()
    self:Show("empty")
end

--Top Levels

function ZO_InternalIngameSceneManager:RegisterTopLevel(topLevel, locksUIMode)
    topLevel.locksUIMode = locksUIMode
    self.topLevelWindows[topLevel] = true
end

function ZO_InternalIngameSceneManager:IsInUIMode()
    if IsGameCameraActive() then
        return IsGameCameraUIModeActive()
    end

    return false
end

function ZO_InternalIngameSceneManager:HideTopLevel(topLevel)
    if not topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true then
        topLevel:SetHidden(true)
        self.numTopLevelShown = self.numTopLevelShown - 1
        ChangeRemoteTopLevel(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_REQUEST_TYPE_HIDE)
    end
end

function ZO_InternalIngameSceneManager:ShowTopLevel(topLevel)
    if topLevel:IsControlHidden() and self.topLevelWindows[topLevel] == true then
        topLevel:SetHidden(false)
        self.numTopLevelShown = self.numTopLevelShown + 1
        ChangeRemoteTopLevel(ZO_REMOTE_SCENE_CHANGE_ORIGIN, REMOTE_SCENE_REQUEST_TYPE_SHOW)
    end
end

function ZO_InternalIngameSceneManager:ToggleTopLevel(topLevel)
    if topLevel:IsControlHidden() then
        self:ShowTopLevel(topLevel)
    else
        self:HideTopLevel(topLevel)
    end
end

function ZO_InternalIngameSceneManager:HideTopLevels()
    local topLevelHidden = false
    for topLevel, _ in pairs(self.topLevelWindows) do
        if not topLevel:IsControlHidden() then
            self:HideTopLevel(topLevel)
            topLevelHidden = true
        end
    end

    return topLevelHidden
end

SCENE_MANAGER = ZO_InternalIngameSceneManager:New()
