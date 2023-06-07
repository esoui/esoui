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

            newEmailEdit:SetText("")
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
        ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(control)
    end)

    local confirmEmailEditBox = control:GetNamedChild("ConfirmNewEmailEntryEdit")
    ZO_PreHookHandler(confirmEmailEditBox, "OnTextChanged", function(editControl)
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

function ZO_OptionsPanel_Account_SetupEmailLabel_Keyboard(control)
    local emailText = ZO_OptionsPanel_GetAccountEmail()
    if emailText == "" then
        emailText = GetString(SI_INTERFACE_OPTIONS_ACCOUNT_NO_EMAIL_TEXT)
    end

    control:SetText(emailText)
end

function ZO_OptionsPanel_Account_ShowEmailTooltip_Keyboard(control)
    local emailText = ZO_OptionsPanel_GetAccountEmail()
    if emailText ~= "" then
        InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
        SetTooltipText(InformationTooltip, emailText)
    end
end

function ZO_OptionsPanel_Account_HideEmailTooltip_Keyboard(control)
    ClearTooltip(InformationTooltip)
end

local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_ACCOUNT)

--------------------------------------
-- Account -> Marketing Preferences --
--------------------------------------
panelBuilder:AddSetting({
    controlName = "Options_Account_GetUpdates",
    settingType = SETTING_TYPE_ACCOUNT,
    settingId = ACCOUNT_SETTING_GET_UPDATES,
    header = SI_INTERFACE_OPTIONS_ACCOUNT_MARKETING_HEADER,
})
