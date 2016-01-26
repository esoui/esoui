----------------------------------------
--Gamepad Menu Sound Fragment
----------------------------------------

ZO_GamepadMenuSoundFragment = ZO_SceneFragment:Subclass()

function ZO_GamepadMenuSoundFragment:New()
    local fragment = ZO_SceneFragment.New(self)
    fragment:SetForceRefresh(true)
    return fragment
end

local OPEN_SOUND_SCENES = {
    ["hudui"] = true,
    ["hud"] = true,
    ["gamepadInteract"] = true,
}
function ZO_GamepadMenuSoundFragment:Show()
    local previousSceneName = SCENE_MANAGER:GetPreviousSceneName()
    
    if OPEN_SOUND_SCENES[previousSceneName] then
        PlaySound(SOUNDS.GAMEPAD_OPEN_WINDOW)
    elseif SCENE_MANAGER:IsSceneOnStack(previousSceneName) then
        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    end

    self:OnShown()
end

function ZO_GamepadMenuSoundFragment:Hide()
    local currentSceneName = SCENE_MANAGER:GetCurrentSceneName()

    if SCENE_MANAGER:IsShowingBaseSceneNext() then
        PlaySound(SOUNDS.GAMEPAD_CLOSE_WINDOW)
    elseif not SCENE_MANAGER:IsSceneOnStack(currentSceneName) then
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    end

    self:OnHidden()
end

GAMEPAD_MENU_SOUND_FRAGMENT = ZO_GamepadMenuSoundFragment:New()

--Gamepad fragments
function ZO_CreateQuadrantConveyorFragment(control, alwaysAnimate)
   return ZO_ConveyorSceneFragment:New(control, alwaysAnimate)
end