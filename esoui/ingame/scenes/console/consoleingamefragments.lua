local function ChatVisibilityConditional()
    return IsChatSystemAvailableForCurrentPlatform() and CHAT_SYSTEM:IsHUDEnabled()
end

GAMEPAD_TEXT_CHAT_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadTextChat)
GAMEPAD_TEXT_CHAT_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_TEXT_CHAT_FRAGMENT:SetConditional(ChatVisibilityConditional)
