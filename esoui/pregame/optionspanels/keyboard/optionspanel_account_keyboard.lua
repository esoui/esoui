function ZO_Options_Account_ChangeEmail_Dialog_Keyboard_OnInitialized(control)
    ZO_Dialogs_RegisterCustomDialog("ZO_OPTIONS_KEYBOARD_EDIT_EMAIL_DIALOG",
    {
        title =
        {
            text = SI_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_TITLE,
        },
        mainText =
        {
            text = SI_INTERFACE_OPTIONS_ACCOUNT_EMAIL_DIALOG_ENTRY_TITLE,
        },
        canQueue = true,
        customControl = control,
        setup = function(dialog)
            local newEmailEdit = dialog:GetNamedChild("NewEmailEntryEdit")
            local confirmNewEmailEdit = dialog:GetNamedChild("ConfirmNewEmailEntryEdit")

            local emailAccountText = ZO_OptionsPanel_GetAccountEmail()
            newEmailEdit:SetText(emailAccountText)
            confirmNewEmailEdit:SetText("")
        end,
        buttons =
        {
            -- Confirm Button
            {
                control = control:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                enabled = function(dialog)
                    local newEmailEdit = dialog:GetNamedChild("NewEmailEntryEdit")
                    local confirmNewEmailEdit = dialog:GetNamedChild("ConfirmNewEmailEntryEdit")

                    return newEmailEdit:GetText() == confirmNewEmailEdit:GetText()
                end,
                callback = function(dialog)
                    local newEmailEdit = dialog:GetNamedChild("NewEmailEntryEdit")
                    SetSecureSetting(SETTING_TYPE_ACCOUNT, ACCOUNT_SETTING_ACCOUNT_EMAIL, newEmailEdit:GetText())
                end,
            },
            -- Cancel Button
            {
                control = control:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
        finishedCallback = function()
            KEYBOARD_OPTIONS:UpdatePanelVisibilityIfShowing(SETTING_PANEL_ACCOUNT)
        end,
    })

    -- Edit Email Addresses
    local emailEditBox = control:GetNamedChild("NewEmailEntryEdit")
    ZO_PreHookHandler(emailEditBox, "OnTextChanged", function(editControl)
        ZO_EditDefaultText_OnTextChanged(editControl)
        ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(control)
    end)

    local confirmEmailEditBox = control:GetNamedChild("ConfirmNewEmailEntryEdit")
    ZO_PreHookHandler(confirmEmailEditBox, "OnTextChanged", function(editControl)
        ZO_EditDefaultText_OnTextChanged(editControl)
        ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(control)
    end)

    ZO_PreHookHandler(emailEditBox, "OnEnter", function(editControl)
        confirmEmailEditBox:TakeFocus()
    end)

    ZO_PreHookHandler(emailEditBox, "OnTab", function(editControl)
        confirmEmailEditBox:TakeFocus()
    end)

    ZO_PreHookHandler(confirmEmailEditBox, "OnEnter", function(editControl)
        if emailEditBox:GetText() == confirmEmailEditBox:GetText() then
            SetSecureSetting(SETTING_TYPE_ACCOUNT, ACCOUNT_SETTING_ACCOUNT_EMAIL, emailEditBox:GetText())
            ZO_Dialogs_ReleaseDialog("ZO_OPTIONS_KEYBOARD_EDIT_EMAIL_DIALOG")
        end
    end)

    ZO_PreHookHandler(confirmEmailEditBox, "OnTab", function(editControl)
        emailEditBox:TakeFocus()
    end)
end

function ZO_OptionsPanel_Account_InitializeEmailAddressLabel_Keyboard(control)
    ZO_OptionsPanel_Account_UpdateEmailAddressLabel_Keyboard()
end

function ZO_OptionsPanel_Account_UpdateEmailAddressLabel_Keyboard()
    local labelControl = Options_Account_DisplayEmailAddress:GetNamedChild("Content")

    local emailText = ZO_OptionsPanel_GetAccountEmail()
    if emailText == "" then
        emailText = GetString(SI_INTERFACE_OPTIONS_ACCOUNT_NO_EMAIL_TEXT)
    end

    labelControl:SetText(emailText)
end

function ZO_OptionsPanel_Account_InitializeSetting_Keyboard(control, settingType, settingId)
    if ZO_SharedOptions_SettingsData[SETTING_PANEL_ACCOUNT] ~= nil then
        control.data = KEYBOARD_OPTIONS:GetSettingsData(SETTING_PANEL_ACCOUNT, settingType, settingId)
        ZO_OptionsWindow_InitializeControl(control)
    else
        control:SetHidden(true)
    end
end