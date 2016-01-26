local ZO_GamepadKeybindStripFragment = ZO_TranslateFromBottomSceneFragment:Subclass()

function ZO_GamepadKeybindStripFragment:New(...)
    return ZO_TranslateFromBottomSceneFragment.New(self, ...)
end

function ZO_GamepadKeybindStripFragment:Show()
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    ZO_TranslateFromBottomSceneFragment.Show(self)
end

function ZO_GamepadKeybindStripFragment:Hide()
    ZO_TranslateFromBottomSceneFragment.Hide(self)
end

KEYBIND_STRIP_GAMEPAD_FRAGMENT = ZO_GamepadKeybindStripFragment:New(ZO_KeybindStripControl)
KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_KeybindStripGamepadBackground)
