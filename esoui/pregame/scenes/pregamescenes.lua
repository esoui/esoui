-------------------
-- Accessibility Mode
-------------------

local accessibilityModeScene = ZO_Scene:New("accessibilityModePrompt", SCENE_MANAGER)
accessibilityModeScene:AddFragment(ACCESSIBILITY_MODE_PROMPT_FRAGMENT)
accessibilityModeScene:AddFragment(ACCESSIBILITY_MODE_PROMPT_ACTION_LAYER_FRAGMENT)
accessibilityModeScene:AddFragment(PREGAME_ACCESSIBILITY_MODE_PROMPT_INTRO_ADVANCE_FRAGMENT)

-------------------
-- Gamma Adjust
-------------------

local gammaAdjustScene = ZO_Scene:New("gammaAdjust", SCENE_MANAGER)
gammaAdjustScene:AddFragment(GAMMA_SCENE_FRAGMENT)
gammaAdjustScene:AddFragment(PREGAME_GAMMA_ADJUST_INTRO_ADVANCE_FRAGMENT)

------------------------
-- Screen Adjust Scene
------------------------

local screenAdjustScene = ZO_Scene:New("screenAdjust", SCENE_MANAGER)
screenAdjustScene:AddFragment(SCREEN_ADJUST_SCENE_FRAGMENT)
screenAdjustScene:AddFragment(SCREEN_ADJUST_ACTION_LAYER_FRAGMENT)
screenAdjustScene:AddFragment(PREGAME_SCREEN_ADJUST_INTRO_ADVANCE_FRAGMENT)

SCENE_MANAGER:OnScenesLoaded()
