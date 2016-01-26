-------------------
--Empty
-------------------

local empty = ZO_Scene:New("empty", SCENE_MANAGER)

-------------------
--Gamma Adjust
-------------------

local gammaAdjustScene = ZO_Scene:New("gammaAdjust", SCENE_MANAGER)
gammaAdjustScene:AddFragment(GAMMA_SCENE_FRAGMENT)
gammaAdjustScene:AddFragment(PREGAME_GAMMA_ADJUST_INTRO_ADVANCE_FRAGMENT)

SCENE_MANAGER:OnScenesLoaded()

