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

    local narrationInfo =
    {
        canNarrate = function()
            return not control:IsHidden()
        end,
        headerNarrationFunction = function()
            return ZO_GamepadGenericHeader_GetNarrationText(header, headerData)
        end,
        selectedNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_ControllerDisconnect_GetMessageText())
        end,
        --Because this message box can pop up basically anywhere, we want to ignore the narration for the keybind strip itself
        overrideInputNarrationFunction = function()
            local narrationData = {}
            table.insert(narrationData, interactKeybindControl:GetKeybindButtonNarrationData())
            return narrationData
        end,
        --Because this message box can pop up basically anywhere, we want to ignore all tooltip narration
        canNarrateTooltips = false,
        --Treat this as an alert so it takes priority over everything else
        narrationType = NARRATION_TYPE_ALERT,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("controllerDisconnect", narrationInfo)
end

function ZO_ControllerDisconnect_GetMessageText()
    local name = GetOnlineIdForActiveProfile()
    if name == "" then
        --There is no currently active profile, do not show the controller disconnected message.
        return ""
    else
        local message
        if ZO_IsPlaystationPlatform() then
            message = GetString(SI_GAMEPAD_DISCONNECTED_PLAYSTATION_TEXT)
        else
            message = GetString(SI_GAMEPAD_DISCONNECTED_XBOX_TEXT)
        end

        message = zo_strformat(message, name)
        return message
    end
end

function ZO_ControllerDisconnect_ShowPopup()
    local message = ZO_ControllerDisconnect_GetMessageText()
    if message == "" then
        --There is no message to show.
        return
    end

    local mainText = ZO_ControllerDisconnect:GetNamedChild("ContainerScrollChildMainText")
    mainText:SetText(message)
    mainText:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    ZO_ControllerDisconnect:SetHidden(false)
    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("controllerDisconnect", NARRATE_HEADER)
end

function ZO_ControllerDisconnect_DismissPopup()
    ZO_ControllerDisconnect:SetHidden(true)
end