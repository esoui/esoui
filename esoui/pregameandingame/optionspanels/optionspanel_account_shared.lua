-----------------------------------------
-- Shared Account Options Panel Functions and Data
-----------------------------------------

-------------------------
-- Utility Functions
-------------------------

local g_serviceType = GetPlatformServiceType()

function ZO_OptionsPanel_IsAccountManagementAvailable()
    if g_serviceType == PLATFORM_SERVICE_TYPE_DMM then
        return false
    end
    return ZO_IsConsolePlatform() or IsInUI("pregame")
end

local function HasActivatedEmail()
    if IsInUI("pregame") then
        return HasActivatedEmailInPregame()
    elseif ZO_IsConsolePlatform() then
        return HasActivatedEmailOnConsole()
    else
        return false
    end
end

function ZO_OptionsPanel_GetAccountEmail()
    if IsInUI("pregame") or ZO_IsConsolePlatform() then
        return GetSecureSetting(SETTING_TYPE_ACCOUNT, ACCOUNT_SETTING_ACCOUNT_EMAIL)
    else
        return ""
    end
end

function ZO_OptionsPanel_Account_CanResendActivation()
    return IsDeferredSettingLoaded(SETTING_TYPE_ACCOUNT, ACCOUNT_SETTING_ACCOUNT_EMAIL) and not HasActivatedEmail() and ZO_OptionsPanel_GetAccountEmail() ~= ""
end

-------------------------------------
-- Setup Account Settings Data
-------------------------------------
local ZO_Panel_Account_ControlData =
{
    [SETTING_TYPE_CUSTOM] =
    {
        [OPTIONS_CUSTOM_SETTING_RESEND_EMAIL_ACTIVATION] =
        {
            controlType = OPTIONS_INVOKE_CALLBACK,
            panel = SETTING_PANEL_ACCOUNT,
            text = SI_INTERFACE_OPTIONS_ACCOUNT_RESEND_ACTIVATION,
            gamepadCustomTooltipFunction = function(tooltip, text)
                GAMEPAD_TOOLTIPS:LayoutSettingAccountResendActivation(tooltip, HasActivatedEmail(), ZO_OptionsPanel_GetAccountEmail())
            end,
            callback = function()
                RequestResendAccountEmailVerification()
            end,
            exists = ZO_OptionsPanel_IsAccountManagementAvailable,
            visible = ZO_OptionsPanel_Account_CanResendActivation,
        },
    },

    [SETTING_TYPE_ACCOUNT] =
    {
        [ACCOUNT_SETTING_ACCOUNT_EMAIL] =
        {
            controlType = OPTIONS_INVOKE_CALLBACK,
            system = SETTING_TYPE_ACCOUNT,
            settingId = ACCOUNT_SETTING_ACCOUNT_EMAIL,
            panel = SETTING_PANEL_ACCOUNT,
            text = SI_INTERFACE_OPTIONS_ACCOUNT_CHANGE_EMAIL,
            gamepadCustomTooltipFunction = function(tooltip, text)
                GAMEPAD_TOOLTIPS:LayoutSettingAccountResendActivation(tooltip, HasActivatedEmail(), ZO_OptionsPanel_GetAccountEmail())
            end,
            -- If this setting doesn't exist, we won't attempt to load it, which would mean
            -- OPTIONS_CUSTOM_SETTING_RESEND_EMAIL_ACTIVATION could never be able to show
            exists = ZO_OptionsPanel_IsAccountManagementAvailable,
            visible = false,
            callback = function()
                if IsInGamepadPreferredMode() then
                    local data =
                    {
                        finishedCallback = function()
                            GAMEPAD_OPTIONS:RefreshOptionsList()
                        end,
                    }
                    ZO_Dialogs_ShowGamepadDialog("ZO_OPTIONS_GAMEPAD_EDIT_EMAIL_DIALOG", data)
                else
                    ZO_Dialogs_ShowDialog("ZO_OPTIONS_KEYBOARD_EDIT_EMAIL_DIALOG")
                end
            end,
        },
        [ACCOUNT_SETTING_GET_UPDATES] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCOUNT,
            settingId = ACCOUNT_SETTING_GET_UPDATES,
            panel = SETTING_PANEL_ACCOUNT,
            text = SI_INTERFACE_OPTIONS_ACCOUNT_GET_UPDATES,
            tooltipText = function()
                if not IsConsoleUI() then
                    if HasActivatedEmail() then
                        return GetString(SI_INTERFACE_OPTIONS_ACCOUNT_GET_UPDATES_TOOLTIP_TEXT)
                    else
                        return zo_strformat(SI_KEYBOARD_INTERFACE_OPTIONS_ACCOUNT_GET_UPDATES_TOOLTIP_WARNING_FORMAT, GetString(SI_INTERFACE_OPTIONS_ACCOUNT_GET_UPDATES_TOOLTIP_TEXT), GetString(SI_INTERFACE_OPTIONS_ACCOUNT_NEED_ACTIVE_ACCOUNT_WARNING))
                    end
                end
            end,
            exists = ZO_OptionsPanel_IsAccountManagementAvailable,
            SetSettingOverride = function(control, value)
                SetSecureSetting(control.data.system, control.data.settingId, tostring(value))
            end,
            GetSettingOverride = function(control)
                return GetSecureSetting_Bool(control.data.system, control.data.settingId)
            end,
            gamepadCustomTooltipFunction = function(tooltip, text)
                GAMEPAD_TOOLTIPS:LayoutSettingAccountGetUpdates(tooltip, HasActivatedEmail())
            end,
            enabled = function()
                return HasActivatedEmail()
            end,
            gamepadIsEnabledCallback = function()
                return HasActivatedEmail()
            end,
        }
    }
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_ACCOUNT, ZO_Panel_Account_ControlData)

------------------------------------------
-- Register for account settings events 
------------------------------------------
if ZO_OptionsPanel_IsAccountManagementAvailable() then
    local function OnAccountManagementRequestUnsuccessful(eventId, resultMessage)
        ZO_Dialogs_ShowPlatformDialog("ACCOUNT_MANAGEMENT_REQUEST_FAILED", { mainText = resultMessage })
    end

    EVENT_MANAGER:RegisterForEvent("AccountManagement", EVENT_UNSUCCESSFUL_REQUEST_RESULT, OnAccountManagementRequestUnsuccessful)

    local function OnAccountManagementActivationEmailSent(eventId, resultMessage)
        ZO_Dialogs_ShowPlatformDialog("ACCOUNT_MANAGEMENT_ACTIVATION_EMAIL_SENT")
    end

    EVENT_MANAGER:RegisterForEvent("AccountManagement", EVENT_ACCOUNT_EMAIL_ACTIVATION_EMAIL_SENT, OnAccountManagementActivationEmailSent)
end