ZO_AddOnEulaDialog_Gamepad = ZO_InitializingObject:Subclass()

function ZO_AddOnEulaDialog_Gamepad:Initialize(control)
    self.control = control

    self:InitializeDialog(control)

    local keybindsContainer = control:GetNamedChild("Keybinds")
    self.acceptKeybindButton = keybindsContainer:GetNamedChild("AcceptKeybind")
    self.declineKeybindButton = keybindsContainer:GetNamedChild("DeclineKeybind")

    -- Accept EULA
    self.acceptKeybindDescriptor =
    {
        keybind = "DIALOG_PRIMARY",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 1,
        name = function()
            return select(2, GetEULADetails(EULA_TYPE_ADDON_EULA))
        end,
        clickSound = SOUNDS.DIALOG_ACCEPT,
        callback = function()
            AgreeToEULA(EULA_TYPE_ADDON_EULA)
            ZO_Dialogs_ReleaseDialogOnButtonPress("ADDON_EULA_GAMEPAD")
        end,
    }
    self.acceptKeybindButton:SetKeybindButtonDescriptor(self.acceptKeybindDescriptor)

    -- Decline EULA
    self.declineKeybindDescriptor =
    {
        keybind = "DIALOG_NEGATIVE",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 2,
        name = function()
            return select(3, GetEULADetails(EULA_TYPE_ADDON_EULA))
        end,
        clickSound = SOUNDS.DIALOG_DECLINE,
        callback = function()
            ZO_Dialogs_ReleaseDialogOnButtonPress("ADDON_EULA_GAMEPAD")
        end,
    }
    self.declineKeybindButton:SetKeybindButtonDescriptor(self.declineKeybindDescriptor)

    self:BuildDialogInfo()

    ZO_Dialogs_RegisterCustomDialog("ADDON_EULA_GAMEPAD", self.dialogInfo)
end

function ZO_AddOnEulaDialog_Gamepad:InitializeDialog(dialog)
    dialog.fragment = ZO_FadeSceneFragment:New(dialog)
    ZO_GenericGamepadDialog_OnInitialized(dialog)
end

function ZO_AddOnEulaDialog_Gamepad:BuildDialogInfo()
    self.dialogInfo =
    {
        setup = function(...) self:DialogSetupFunction(...) end,
        customControl = self.control,
        blockDialogReleaseOnPress = true,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        },
        title =
        {
            text = SI_WINDOW_TITLE_ADDON_EULA,
        },
        mainText =
        {
            text = function()
                local eulaText = GetEULADetails(EULA_TYPE_ADDON_EULA)
                return eulaText
            end,
        },
        finishedCallback = function(dialog)
            if dialog.data and dialog.data.finishedCallback then
                dialog.data.finishedCallback(dialog)
            end
        end,
        buttons =
        {
            self.acceptKeybindDescriptor,
            self.declineKeybindDescriptor,
        }
    }
end

function ZO_AddOnEulaDialog_Gamepad:DialogSetupFunction(dialog)
    dialog.headerData.titleTextAlignment = TEXT_ALIGN_CENTER
    ZO_GamepadGenericHeader_Refresh(dialog.header, dialog.headerData)
end

function ZO_AddOnEulaDialog_Gamepad.OnControlInitialized(control)
    ZO_ADDON_EULA_GAMEPAD_DIALOG = ZO_AddOnEulaDialog_Gamepad:New(control)
end