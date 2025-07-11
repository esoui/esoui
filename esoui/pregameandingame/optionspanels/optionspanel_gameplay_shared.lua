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

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_GAMEPLAY, ZO_OptionsPanel_Gameplay_ControlData)