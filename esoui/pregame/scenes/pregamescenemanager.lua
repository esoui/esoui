ZO_REMOTE_SCENE_CHANGE_ORIGIN = SCENE_MANAGER_MESSAGE_ORIGIN_PREGAME

local ZO_PregameSceneManager = ZO_SceneManager_Leader:Subclass()

function ZO_PregameSceneManager:New(...)
    return ZO_SceneManager_Leader.New(self, ...)
end

function ZO_PregameSceneManager:OnScenesLoaded()
    self:SetBaseScene("empty")
    self:Show("empty")
end

function ZO_PregameSceneManager:HideTopLevel(top)
    top:SetHidden(true)
end

SCENE_MANAGER = ZO_PregameSceneManager:New()
