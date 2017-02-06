function ZO_ControllerDisconnect_Initialize(self)
    CONTROLLER_DISCONNECT_FRAGMENT = ZO_FadeSceneFragment:New(self)

	local headerData = {}
	local header = self:GetNamedChild("HeaderContainer").header
	headerData.titleTextAlignment = TEXT_ALIGN_CENTER
	headerData.titleText = GetString(SI_GAMEPAD_DISCONNECTED_TITLE)
	ZO_GamepadGenericHeader_Initialize(header)
	ZO_GamepadGenericHeader_Refresh(header, headerData)

    self:GetNamedChild("InteractKeybind"):SetText(zo_strformat(SI_GAMEPAD_DISCONNECTED_CONTINUE_TEXT, ZO_Keybindings_GetKeyText(KEY_GAMEPAD_BUTTON_1)))
end

function ZO_ControllerDisconnect_ShowPopup()
    local name = GetOnlineIdForActiveProfile()
    if name == "" then
        --There is no currently active profile, do not show the controller disconnected message.
        return
    end

    local message
    if GetUIPlatform() == UI_PLATFORM_PS4 then 
        message = GetString(SI_GAMEPAD_DISCONNECTED_PS4_TEXT)
    else
        message = GetString(SI_GAMEPAD_DISCONNECTED_XBOX_TEXT)
    end

    message = zo_strformat(message, name)

    local mainText = ZO_ControllerDisconnect:GetNamedChild("ContainerScrollChildMainText")
    mainText:SetText(message)
    mainText:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    ZO_ControllerDisconnect:SetHidden(false)
end

function ZO_ControllerDisconnect_DismissPopup()
    ZO_ControllerDisconnect:SetHidden(true)
end