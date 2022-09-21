ZO_OptionsGamepad_EmailEditor = ZO_Object:Subclass()

function ZO_OptionsGamepad_EmailEditor:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_OptionsGamepad_EmailEditor:Initialize(control)
    local function ReleaseDialog()
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
        ZO_Dialogs_ReleaseDialogOnButtonPress("ZO_OPTIONS_GAMEPAD_EDIT_EMAIL_DIALOG")
    end

    ZO_Dialogs_RegisterCustomDialog("ZO_OPTIONS_GAMEPAD_EDIT_EMAIL_DIALOG",
    {
        blockDialogReleaseOnPress = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        setup = function(dialog, data)
            self.enteredText = ""

            if ZO_IsPlaystationPlatform() then
                local params = {
                    "DIALOG_TERTIARY",
                }
                local keybindIndex = 1
                GAMEPAD_TOOLTIPS:LayoutKeybindTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, SI_GAMEPAD_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_TOOLTIP_PLAYSTATION, params, keybindIndex)
            else
                local params = {
                    "DIALOG_TERTIARY",
                    ZO_GetPlatformStoreName(),
                }
                local keybindIndex = 1
                GAMEPAD_TOOLTIPS:LayoutKeybindTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, SI_GAMEPAD_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_TOOLTIP, params, keybindIndex)
            end

            dialog.info.finishedCallback = data.finishedCallback

            dialog:setupFunc()
        end,
        title =
        {
            text = SI_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_TITLE,
        },
        mainText =
        {
            text = ""
        },
        parametricList =
        {
            -- Text Entry
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                header = GetString(SI_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_ENTRY_TITLE),
                templateData =
                {
                    textChangedCallback = function(control)
                        local enteredText= control:GetText()
                        self.enteredText = enteredText
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
 
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        data.control = control
 
                        control.editBoxControl:SetDefaultText(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_ENTRY_DEFAULT))
                        control.editBoxControl:SetMaxInputChars(MAX_EMAIL_LENGTH)
                        if self.enteredText then
                            control.editBoxControl:SetText(self.enteredText)
                        end
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                    narrationTooltip = GAMEPAD_LEFT_TOOLTIP,
                },
            },
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData =
                {
                    text = GetString(SI_GAMEPAD_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_ACTION),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        SetSecureSetting(SETTING_TYPE_ACCOUNT, ACCOUNT_SETTING_ACCOUNT_EMAIL, self.enteredText)
                        ReleaseDialog()
                    end,
                },
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    data.callback(dialog)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ReleaseDialog()
                end,
            },
            {
                keybind = "DIALOG_TERTIARY",
                text = SI_GAMEPAD_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_AUTOFILL,
                visible = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    return data.control and data.control.editBoxControl or false
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    self.enteredText = GetUserEmailAddress()
                    targetControl.editBoxControl:SetText(self.enteredText)
                end,
            },
        },
    })
end

EMAIL_EDITOR_GAMEPAD = ZO_OptionsGamepad_EmailEditor:New()
