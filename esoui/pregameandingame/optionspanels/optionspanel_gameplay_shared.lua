local ZO_OptionsPanel_Gameplay_ControlData =
{
    [SETTING_TYPE_GAMEPAD] =
    {
        --Options_Gamepad_Vibration
        [GAMEPAD_SETTING_VIBRATION] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_VIBRATION,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_GAMEPAD_OPTIONS_CAMERA_VIBRATION,
        },
        --Options_Gamepad_Deadzone_Inner_Right_Stick
        [GAMEPAD_SETTING_DEADZONE_INNER_RIGHT_STICK] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_DEADZONE_INNER_RIGHT_STICK,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_GAMEPAD_OPTIONS_DEADZONE_INNER_RIGHT_STICK,
            tooltipText = SI_GAMEPAD_OPTIONS_DEADZONE_INNER_RIGHT_STICK_TOOLTIP,
            minValue = 0.15,
            maxValue = 0.99,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 15,
            showValueMin = 20,
            showValueMax = 100,
        },
        --Options_Gamepad_Deadzone_Outer_Right_Stick
        [GAMEPAD_SETTING_DEADZONE_OUTER_RIGHT_STICK] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_DEADZONE_OUTER_RIGHT_STICK,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_GAMEPAD_OPTIONS_DEADZONE_OUTER_RIGHT_STICK,
            tooltipText = SI_GAMEPAD_OPTIONS_DEADZONE_OUTER_RIGHT_STICK_TOOLTIP,
            minValue = 0.15,
            maxValue = 0.99,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 100,
            showValueMin = 20,
            showValueMax = 100,
        },
        --Options_Gamepad_Deadzone_Inner_Left_Stick
        [GAMEPAD_SETTING_DEADZONE_INNER_LEFT_STICK] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_DEADZONE_INNER_LEFT_STICK,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_GAMEPAD_OPTIONS_DEADZONE_INNER_LEFT_STICK,
            tooltipText = SI_GAMEPAD_OPTIONS_DEADZONE_INNER_LEFT_STICK_TOOLTIP,
            minValue = 0.15,
            maxValue = 0.99,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 25,
            showValueMin = 15,
            showValueMax = 100,
        },
        --Options_Gamepad_Deadzone_Outer_Left_Stick
        [GAMEPAD_SETTING_DEADZONE_OUTER_LEFT_STICK] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_DEADZONE_OUTER_LEFT_STICK,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_GAMEPAD_OPTIONS_DEADZONE_OUTER_LEFT_STICK,
            tooltipText = SI_GAMEPAD_OPTIONS_DEADZONE_OUTER_LEFT_STICK_TOOLTIP,
            minValue = 0.15,
            maxValue = 0.99,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 100,
            showValueMin = 15,
            showValueMax = 100,
        },
        --Options_Gamepad_Deadzone_Trigger
        [GAMEPAD_SETTING_DEADZONE_TRIGGERS] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_DEADZONE_TRIGGERS,
            panel = SETTING_PANEL_GAMEPLAY,
            text = ZO_IsPlaystationPlatform() and GetString(SI_PS_GAMEPAD_OPTIONS_DEADZONE_TRIGGERS) or GetString(SI_GAMEPAD_OPTIONS_DEADZONE_TRIGGERS),
            tooltipText = ZO_IsPlaystationPlatform() and GetString(SI_PS_GAMEPAD_OPTIONS_DEADZONE_TRIGGERS_TOOLTIP) or GetString(SI_GAMEPAD_OPTIONS_DEADZONE_TRIGGERS_TOOLTIP),
            minValue = 0.15,
            maxValue = 0.85,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 50,
            showValueMin = 15,
            showValueMax = 85,
        },
    },
}

local function IsAccessibilityModeEnabled()
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE)
end

local function IsInputPreferredSettingKeyboard()
    return tonumber(GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE)) == INPUT_PREFERRED_MODE_ALWAYS_KEYBOARD
end

local function IsInputPreferredSettingGamepad()
    return tonumber(GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE)) == INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD
end

local ZO_SharedOptions_Gameplay_GamepadSettingsData =
{
    --Options_Gameplay_InputModePreferred
    [GAMEPAD_SETTING_INPUT_PREFERRED_MODE] =
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_GAMEPAD,
        panel = SETTING_PANEL_GAMEPLAY,
        settingId = GAMEPAD_SETTING_INPUT_PREFERRED_MODE,
        text = SI_GAMEPAD_OPTIONS_GAMEPAD_MODE,
        tooltipText = SI_GAMEPAD_OPTIONS_GAMEPAD_MODE_TOOLTIP,
        valid =
        {
            INPUT_PREFERRED_MODE_ALWAYS_KEYBOARD,
            INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD,
            INPUT_PREFERRED_MODE_AUTOMATIC,
        },
        events =
        {
            [INPUT_PREFERRED_MODE_ALWAYS_KEYBOARD] = "OnInputPreferredModeKeyboard",
            [INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD] = "OnInputPreferredModeGamepad",
            [INPUT_PREFERRED_MODE_AUTOMATIC] = "OnInputPreferredModeAutomatic",
        },
        eventCallbacks =
        {
            ["OnAccessibilityModeEnabled"] = function(control)
                ZO_Options_SetOptionInactive(control)
                ZO_Options_SetWarningText(control, SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING)
                ZO_Options_SetWarningTexture(control, ACCESSIBILITY_MODE_ICON_PATH)
            end,
            ["OnAccessibilityModeDisabled"] = function(control)
                ZO_Options_SetOptionActive(control)
                ZO_Options_HideAssociatedWarning(control)
            end,
        },
        visible = function()
            return not IsGameCoreUI()
        end,
        enabled = function()
             return not IsAccessibilityModeEnabled()
        end,
        gamepadIsEnabledCallback = function()
             return not IsAccessibilityModeEnabled()
        end,
        gamepadHasEnabledDependencies = true,
        gamepadCustomTooltipFunction = function(tooltip)
            GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_GAMEPAD_OPTIONS_GAMEPAD_MODE_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING), IsAccessibilityModeEnabled())
        end,
        exists = DoesPlatformAllowConfiguringAutomaticInputChanging,
        valueStringPrefix = "SI_INPUTPREFERREDMODE",
    },
    --Options_Gameplay_KeybindDisplayMode
    [GAMEPAD_SETTING_KEYBIND_DISPLAY_MODE] =
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_GAMEPAD,
        panel = SETTING_PANEL_GAMEPLAY,
        settingId = GAMEPAD_SETTING_KEYBIND_DISPLAY_MODE,
        text = SI_GAMEPAD_OPTIONS_KEYBIND_DISPLAY_MODE,
        tooltipText = SI_GAMEPAD_OPTIONS_KEYBIND_DISPLAY_MODE_TOOLTIP,
        valid =
        {
            KEYBIND_DISPLAY_MODE_ALWAYS_KEYBOARD,
            KEYBIND_DISPLAY_MODE_ALWAYS_GAMEPAD,
            KEYBIND_DISPLAY_MODE_AUTOMATIC,
        },
        eventCallbacks =
        {
            -- Input Preferred Mode callbacks
            ["OnInputPreferredModeKeyboard"] = ZO_Options_SetOptionInactive,
            ["OnInputPreferredModeGamepad"] = function(control)
                if not IsAccessibilityModeEnabled() then
                    ZO_Options_SetOptionActive(control)
                end
            end,
            ["OnInputPreferredModeAutomatic"] = ZO_Options_SetOptionInactive,
            -- Accessibility Mode callbacks
            ["OnAccessibilityModeEnabled"] = function(control)
                ZO_Options_SetOptionInactive(control)
                ZO_Options_SetWarningText(control, SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING)
                ZO_Options_SetWarningTexture(control, ACCESSIBILITY_MODE_ICON_PATH)
            end,
            ["OnAccessibilityModeDisabled"] = function(control)
                if IsInputPreferredSettingGamepad() then
                    ZO_Options_SetOptionActive(control)
                else
                    ZO_Options_SetOptionInactive(control)
                end
                ZO_Options_HideAssociatedWarning(control)
            end,
        },
        enabled = function()
             return not IsAccessibilityModeEnabled() and IsInputPreferredSettingGamepad()
        end,
        gamepadIsEnabledCallback = function()
             return not IsAccessibilityModeEnabled() and IsInputPreferredSettingGamepad()
        end,
        gamepadCustomTooltipFunction = function(tooltip)
            GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_GAMEPAD_OPTIONS_KEYBIND_DISPLAY_MODE_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING), IsAccessibilityModeEnabled())
        end,
        exists = ZO_IsPCUI,
        valueStringPrefix = "SI_KEYBINDDISPLAYMODE",
        initializeControlFunction = function(control)
            ZO_OptionsWindow_InitializeControl(control)
            EVENT_MANAGER:RegisterForEvent("ZO_OptionsPanel_Gameplay", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
                ZO_Options_UpdateOption(control)
            end)
        end,
    },
    --Options_Gameplay_UseKeyboardChat
    [GAMEPAD_SETTING_USE_KEYBOARD_CHAT] =
    {
        controlType = OPTIONS_CHECKBOX,
        system = SETTING_TYPE_GAMEPAD,
        panel = SETTING_PANEL_GAMEPLAY,
        settingId = GAMEPAD_SETTING_USE_KEYBOARD_CHAT,
        text = SI_GAMEPAD_OPTIONS_USE_KEYBOARD_CHAT,
        tooltipText = SI_GAMEPAD_OPTIONS_USE_KEYBOARD_CHAT_TOOLTIP,
        eventCallbacks =
        {
            -- Input Preferred Mode callbacks
            ["OnInputPreferredModeKeyboard"] = ZO_Options_SetOptionInactive,
            ["OnInputPreferredModeGamepad"] = function(control)
                if not IsAccessibilityModeEnabled() then
                    ZO_Options_SetOptionActive(control)
                end
            end,
            ["OnInputPreferredModeAutomatic"] = function(control)
                if not IsAccessibilityModeEnabled() then
                    ZO_Options_SetOptionActive(control)
                end
            end,
            -- Accessibility Mode callbacks
            ["OnAccessibilityModeEnabled"] = function(control)
                ZO_Options_SetOptionInactive(control)
                ZO_Options_SetWarningText(control, SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING)
                ZO_Options_SetWarningTexture(control, ACCESSIBILITY_MODE_ICON_PATH)
            end,
            ["OnAccessibilityModeDisabled"] = function(control)
                if not IsInputPreferredSettingKeyboard() then
                    ZO_Options_SetOptionActive(control)
                else
                    ZO_Options_SetOptionInactive(control)
                end
                ZO_Options_HideAssociatedWarning(control)
            end,
        },
        enabled = function()
            return not IsAccessibilityModeEnabled() and not IsInputPreferredSettingKeyboard()
        end,
        gamepadIsEnabledCallback = function()
            return not IsAccessibilityModeEnabled() and not IsInputPreferredSettingKeyboard()
        end,
        gamepadCustomTooltipFunction = function(tooltip)
            GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_GAMEPAD_OPTIONS_USE_KEYBOARD_CHAT_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING), IsAccessibilityModeEnabled())
        end,
        exists = ZO_IsPCUI,
        initializeControlFunction = function(control)
            ZO_OptionsWindow_InitializeControl(control)
            EVENT_MANAGER:RegisterForEvent("ZO_OptionsPanel_Gameplay", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
                ZO_Options_UpdateOption(control)
            end)
        end,
    },
    --Options_Gameplay_UseKeyboardLogin
    [GAMEPAD_SETTING_USE_KEYBOARD_LOGIN] =
    {
        controlType = OPTIONS_CHECKBOX,
        system = SETTING_TYPE_GAMEPAD,
        panel = SETTING_PANEL_GAMEPLAY,
        settingId = GAMEPAD_SETTING_USE_KEYBOARD_LOGIN,
        text = SI_GAMEPAD_OPTIONS_USE_KEYBOARD_LOGIN,
        tooltipText = SI_GAMEPAD_OPTIONS_USE_KEYBOARD_LOGIN_TOOLTIP,
        eventCallbacks =
        {
            -- Input Preferred Mode callbacks
            ["OnInputPreferredModeKeyboard"] = ZO_Options_SetOptionInactive,
            ["OnInputPreferredModeGamepad"] = function(control)
                if not IsAccessibilityModeEnabled() then
                    ZO_Options_SetOptionActive(control)
                end
            end,
            ["OnInputPreferredModeAutomatic"] = function(control)
                if not IsAccessibilityModeEnabled() then
                    ZO_Options_SetOptionActive(control)
                end
            end,
            -- Accessibility Mode callbacks
            ["OnAccessibilityModeEnabled"] = function(control)
                ZO_Options_SetOptionInactive(control)
                ZO_Options_SetWarningText(control, SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING)
                ZO_Options_SetWarningTexture(control, ACCESSIBILITY_MODE_ICON_PATH)
            end,
            ["OnAccessibilityModeDisabled"] = function(control)
                if not IsInputPreferredSettingKeyboard() then
                    ZO_Options_SetOptionActive(control)
                else
                    ZO_Options_SetOptionInactive(control)
                end
                ZO_Options_HideAssociatedWarning(control)
            end,
        },
        enabled = function()
            return not IsAccessibilityModeEnabled() and not IsInputPreferredSettingKeyboard() and not IsGameCoreUI()
        end,
        gamepadIsEnabledCallback = function()
            return not IsAccessibilityModeEnabled() and not IsInputPreferredSettingKeyboard() and not IsGameCoreUI()
        end,
        gamepadCustomTooltipFunction = function(tooltip)
            GAMEPAD_TOOLTIPS:LayoutSettingAccessibilityTooltipWarning(tooltip, GetString(SI_GAMEPAD_OPTIONS_USE_KEYBOARD_LOGIN_TOOLTIP), GetString(SI_OPTIONS_ACCESSIBILITY_MODE_ENABLED_WARNING), IsAccessibilityModeEnabled())
        end,
        exists = function()
            return ZO_IsPCUI() and not IsGameCoreUI()
        end,
        initializeControlFunction = function(control)
            ZO_OptionsWindow_InitializeControl(control)
            EVENT_MANAGER:RegisterForEvent("ZO_OptionsPanel_Gameplay", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
                ZO_Options_UpdateOption(control)
            end)
        end,
    },
    --Options_Gamepad_Template
    [GAMEPAD_SETTING_GAMEPAD_TEMPLATE] =
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_GAMEPAD,
        settingId = GAMEPAD_SETTING_GAMEPAD_TEMPLATE,
        panel = SETTING_PANEL_GAMEPLAY,
        text = SI_GAMEPAD_OPTIONS_TEMPLATES,
        valid = {GAMEPAD_TEMPLATE_DEFAULT, GAMEPAD_TEMPLATE_ALTERNATE_INTERACT, GAMEPAD_TEMPLATE_WEAPON_TRICKS,},
        valueStringPrefix = "SI_GAMEPADTEMPLATE",
        gamepadShowsControllerInfo = true,
    },
    [SETTING_TYPE_CUSTOM] =
    {
        --Options_Gamepad_Reset_Controls
        [OPTIONS_CUSTOM_SETTING_RESET_GAMEPAD_CONTROLS] =
        {
            controlType = OPTIONS_INVOKE_CALLBACK,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_RESET_GAMEPAD_CONTROLS,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_GAMEPAD_OPTIONS_RESET_CONTROLS,
            callback = function()
                ResetGamepadBindsToDefault()
            end,
        },
    },
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_GAMEPLAY, ZO_OptionsPanel_Gameplay_ControlData)
ZO_SharedOptions.AddTableToSystem(SETTING_PANEL_GAMEPLAY, SETTING_TYPE_GAMEPAD, ZO_SharedOptions_Gameplay_GamepadSettingsData)