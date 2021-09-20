function ZO_ControllerDisconnect_Initialize(control)
    CONTROLLER_DISCONNECT_FRAGMENT = ZO_FadeSceneFragment:New(control)

    local headerData =
    {
        titleTextAlignment = TEXT_ALIGN_CENTER,
        titleText = GetString(SI_GAMEPAD_DISCONNECTED_TITLE),
    }

    local header = control:GetNamedChild("HeaderContainer").header
    ZO_GamepadGenericHeader_Initialize(header)
    ZO_GamepadGenericHeader_Refresh(header, headerData)

    local interactKeybindControl = control:GetNamedChild("InteractKeybind")
    ZO_KeybindButtonTemplate_Setup(interactKeybindControl, "DIALOG_PRIMARY", ZO_ControllerDisconnect_DismissPopup, GetString(SI_GAMEPAD_DISCONNECTED_CONTINUE_TEXT))
end

function ZO_ControllerDisconnect_ShowPopup()
    local name = GetOnlineIdForActiveProfile()
    if name == "" then
        --There is no currently active profile, do not show the controller disconnected message.
        return
    end

    local message
    if ZO_IsPlaystationPlatform() then
        message = GetString(SI_GAMEPAD_DISCONNECTED_PLAYSTATION_TEXT)
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