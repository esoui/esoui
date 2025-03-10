local function IsAccessibilityModeEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE)
end

local function IsTextChatNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION)
end

local function IsScreenNarrationEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SCREEN_NARRATION)
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
            enabled = IsAccessibilityModeEnabled,
            gamepadIsEnabledCallback = IsAccessibilityModeEnabled,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_VOICE_CHAT_ACCESSIBILITY_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
        -- Options_Accessibility_TextChatNarration
        [ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_TEXT_CHAT_NARRATION,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_TEXT_CHAT_NARRATION_TOOLTIP,
            events =
            {
                [true] = "OnTextChatNarrationEnabled",
                [false] = "OnTextChatNarrationDisabled",
            },
            gamepadHasEnabledDependencies = true,
            exists = IsChatSystemAvailableForCurrentPlatform,
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_UpdateOption,
                ["OnAccessibilityModeDisabled"] = ZO_Options_UpdateOption,
            },
            enabled = IsAccessibilityModeEnabled,
            gamepadIsEnabledCallback = IsAccessibilityModeEnabled,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_TEXT_CHAT_NARRATION_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
        -- Options_Accessibility_ZoneChatNarration
        [ACCESSIBILITY_SETTING_ZONE_CHAT_NARRATION] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_ZONE_CHAT_NARRATION,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_ZONE_CHAT_NARRATION,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_ZONE_CHAT_NARRATION_TOOLTIP,
            exists = IsChatSystemAvailableForCurrentPlatform,
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_UpdateOption,
                ["OnAccessibilityModeDisabled"] = ZO_Options_UpdateOption,
                ["OnTextChatNarrationEnabled"] = ZO_Options_UpdateOption,
                ["OnTextChatNarrationDisabled"] = ZO_Options_UpdateOption,
            },
            enabled = IsTextChatNarrationEnabled,
            gamepadIsEnabledCallback = IsTextChatNarrationEnabled,
            gamepadCustomTooltipFunction = function(tooltip)
                local shouldDisplayWarning = not IsAccessibilityModeEnabled() or not IsTextChatNarrationEnabled()
                local warningText = IsAccessibilityModeEnabled() and GetString(SI_OPTIONS_TEXT_CHAT_NARRATION_REQUIRED_WARNING) or GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_ZONE_CHAT_NARRATION_TOOLTIP), warningText, shouldDisplayWarning)
            end,
        },
        -- Options_Accessibility_ScreenNarration
        [ACCESSIBILITY_SETTING_SCREEN_NARRATION] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_SCREEN_NARRATION,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_SCREEN_NARRATION,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_SCREEN_NARRATION_TOOLTIP,
            events =
            {
                [true] = "OnScreenNarrationEnabled",
                [false] = "OnScreenNarrationDisabled",
            },
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_UpdateOption,
                ["OnAccessibilityModeDisabled"] = ZO_Options_UpdateOption,
            },
            enabled = IsAccessibilityModeEnabled,
            gamepadIsEnabledCallback = IsAccessibilityModeEnabled,
            gamepadHasEnabledDependencies = true,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_SCREEN_NARRATION_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
        -- Options_Accessibility_TextInputNarration
        [ACCESSIBILITY_SETTING_TEXT_INPUT_NARRATION] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_TEXT_INPUT_NARRATION,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_TEXT_INPUT_NARRATION,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_TEXT_INPUT_NARRATION_TOOLTIP,
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_UpdateOption,
                ["OnAccessibilityModeDisabled"] = ZO_Options_UpdateOption,
                ["OnScreenNarrationEnabled"] = ZO_Options_UpdateOption,
                ["OnScreenNarrationDisabled"] = ZO_Options_UpdateOption,
            },
            enabled = IsScreenNarrationEnabled,
            gamepadIsEnabledCallback = IsScreenNarrationEnabled,
            gamepadCustomTooltipFunction = function(tooltip)
                local shouldDisplayWarning = not IsAccessibilityModeEnabled() or not IsScreenNarrationEnabled()
                local warningText = IsAccessibilityModeEnabled() and GetString(SI_OPTIONS_SCREEN_NARRATION_REQUIRED_WARNING) or GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_TEXT_INPUT_NARRATION_TOOLTIP), warningText, shouldDisplayWarning)
            end,
        },
        -- Options_Accessibility_NarrationVolume
        [ACCESSIBILITY_SETTING_NARRATION_VOLUME] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_NARRATION_VOLUME,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_NARRATION_VOLUME,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_NARRATION_VOLUME_TOOLTIP,
            minValue = 0,
            maxValue = 100,
            showValue = true,
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_UpdateOption,
                ["OnAccessibilityModeDisabled"] = ZO_Options_UpdateOption,
            },
            enabled = IsAccessibilityModeEnabled,
            gamepadIsEnabledCallback = IsAccessibilityModeEnabled,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_NARRATION_VOLUME_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
        -- Options_Accessibility_NarrationVoiceSpeed
        [ACCESSIBILITY_SETTING_NARRATION_VOICE_SPEED] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_NARRATION_VOICE_SPEED,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_NARRATION_VOICE_SPEED,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_NARRATION_VOICE_SPEED_TOOLTIP,
            valid = {NARRATION_VOICE_SPEED_NORMAL, NARRATION_VOICE_SPEED_FAST, NARRATION_VOICE_SPEED_EXTRA_FAST, },
            valueStringPrefix = "SI_NARRATIONVOICESPEED",
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_UpdateOption,
                ["OnAccessibilityModeDisabled"] = ZO_Options_UpdateOption,
            },
            enabled = IsAccessibilityModeEnabled,
            gamepadIsEnabledCallback = IsAccessibilityModeEnabled,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_NARRATION_VOICE_SPEED_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
        -- Options_Accessibility_NarrationVoiceType
        [ACCESSIBILITY_SETTING_NARRATION_VOICE_TYPE] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_NARRATION_VOICE_TYPE,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_NARRATION_VOICE_TYPE,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_NARRATION_VOICE_TYPE_TOOLTIP,
            valid = { NARRATION_VOICE_TYPE_FEMALE, NARRATION_VOICE_TYPE_MALE, },
            valueStringPrefix = "SI_NARRATIONVOICETYPE",
            eventCallbacks =
            {
                ["OnAccessibilityModeEnabled"] = ZO_Options_UpdateOption,
                ["OnAccessibilityModeDisabled"] = ZO_Options_UpdateOption,
            },
            enabled = IsAccessibilityModeEnabled,
            gamepadIsEnabledCallback = IsAccessibilityModeEnabled,
            gamepadCustomTooltipFunction = function(tooltip)
                GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_ACCESSIBILITY_OPTIONS_NARRATION_VOICE_TYPE_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_REQUIRED_WARNING), not IsAccessibilityModeEnabled())
            end,
        },
        -- Options_Accessibility_AccessibleQuickwheels
        [ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_ACCESSIBLE_QUICKWHEELS,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_ACCESSIBLE_QUICKWHEELS_TOOLTIP,
        },
        -- Options_Accessibility_Waypoint_Color
        [ACCESSIBILITY_SETTING_PLAYER_WAYPOINT_ICON_COLOR] =
        {
            controlType = OPTIONS_COLOR,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_PLAYER_WAYPOINT_ICON_COLOR,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_PLAYER_WAYPOINT_COLOR,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_PLAYER_WAYPOINT_COLOR_TOOLTIP
        },
        --Options_Accessibility_GamepadAimAssistIntensity
        [ACCESSIBILITY_SETTING_GAMEPAD_AIM_ASSIST_INTENSITY] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_GAMEPAD_AIM_ASSIST_INTENSITY,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_GAMEPAD_AIM_ASSIST_INTENSITY,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_GAMEPAD_AIM_ASSIST_INTENSITY_TOOLTIP,
            minValue = 0,
            maxValue = 100,
            showValue = true,
            exists = function()
                return ZO_IsIngameUI()
            end,
        },
        --Options_Accessibility_MouseAimAssistIntensity
        [ACCESSIBILITY_SETTING_MOUSE_AIM_ASSIST_INTENSITY] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_MOUSE_AIM_ASSIST_INTENSITY,
            panel = SETTING_PANEL_ACCESSIBILITY,
            text = SI_ACCESSIBILITY_OPTIONS_MOUSE_AIM_ASSIST_INTENSITY,
            tooltipText = SI_ACCESSIBILITY_OPTIONS_MOUSE_AIM_ASSIST_INTENSITY_TOOLTIP,
            minValue = 0,
            maxValue = 100,
            showValue = true,
            exists = function()
                return not IsConsoleUI() and ZO_IsIngameUI()
            end,
        },
    }
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_ACCESSIBILITY, ZO_Panel_Accessibility_ControlData)