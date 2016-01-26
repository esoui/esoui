ZO_REMOTE_SCENE_CHANGE_ORIGIN = REMOTE_SCENE_STATE_CHANGE_ORIGIN_PREGAME

local ZO_PregameSceneManager = ZO_SceneManager:Subclass()

function ZO_PregameSceneManager:New()
    local manager = ZO_SceneManager.New(self)
    return manager
end

function ZO_PregameSceneManager:OnScenesLoaded()
    self:SetBaseScene("empty")
    self:Show("empty")
end

function ZO_PregameSceneManager:HideTopLevel(top)
    top:SetHidden(true)
end

SCENE_MANAGER = ZO_PregameSceneManager:New()