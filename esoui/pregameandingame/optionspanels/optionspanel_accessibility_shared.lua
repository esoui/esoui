local function IsAccessibilityModeEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE)
end

local ZO_Panel_Accessibility_ControlData =
{
    [SETTING_TYPE_ACCESSIBILITY] =
    {
        -- Options_Accessibility_AccessibilityMode
        [ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_ACCESSIBILITY_MODE,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_ACCESSIBILITY_MODE_TOOLTIP,
            events = 
            {
                [true] = "OnAccessibilityModeEnabled",
                [false] = "OnAccessibilityModeDisabled",
            },
            gamepadHasEnabledDependencies = true,
        },
        -- Options_Accessibility_VoiceChatAccessibility
        [ACCESSIBILITY_SETTING_VOICE_CHAT_ACCESSIBILITY] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_VOICE_CHAT_ACCESSIBILITY,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_VOICE_CHAT_ACCESSIBILITY,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_VOICE_CHAT_ACCESSIBILITY_TOOLTIP,
            exists = IsConsoleUI,
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_SetOptionActive,
                ["OnAccessibilityModeDisabled"] = ZO_Options_SetOptionInactive,
            },
            enabled = function()
                 return IsAccessibilityModeEnabled()
            end,
            gamepadIsEnabledCallback = function()
                 return IsAccessibilityModeEnabled()
            end,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_VOICE_CHAT_ACCESSIBILITY_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
        -- Options_Accessibility_TextChatAccessibility
        [ACCESSIBILITY_SETTING_TEXT_CHAT_ACCESSIBILITY] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_TEXT_CHAT_ACCESSIBILITY,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_TEXT_CHAT_ACCESSIBILITY,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_TEXT_CHAT_ACCESSIBILITY_TOOLTIP,
            exists = IsChatSystemAvailableForCurrentPlatform,
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_SetOptionActive,
                ["OnAccessibilityModeDisabled"] = ZO_Options_SetOptionInactive,
            },
            enabled = function()
                 return IsAccessibilityModeEnabled()
            end,
            gamepadIsEnabledCallback = function()
                 return IsAccessibilityModeEnabled()
            end,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_TEXT_CHAT_ACCESSIBILITY_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
    }
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_ACCESSIBILITY, ZO_Panel_Accessibility_ControlData)