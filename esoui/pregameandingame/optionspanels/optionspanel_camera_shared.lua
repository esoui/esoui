local ZO_OptionsPanel_Camera_ControlData =
{
    --Gamepad
    [SETTING_TYPE_GAMEPAD] =
    {
        --Options_Gamepad_CameraSensitivity
        [GAMEPAD_SETTING_CAMERA_SENSITIVITY_X] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_CAMERA_SENSITIVITY_X,
            panel = SETTING_PANEL_CAMERA,
            text = SI_GAMEPAD_OPTIONS_CAMERA_SENSITIVITY_X,
            minValue = 0.65,
            maxValue = 1.05,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 0.85,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Gamepad_CameraSensitivityY
        [GAMEPAD_SETTING_CAMERA_SENSITIVITY_Y] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_CAMERA_SENSITIVITY_Y,
            panel = SETTING_PANEL_CAMERA,
            text = SI_GAMEPAD_OPTIONS_CAMERA_SENSITIVITY_Y,
            minValue = 0.65,
            maxValue = 1.05,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 0.85,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Gamepad_InvertY
        [GAMEPAD_SETTING_INVERT_Y] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_INVERT_Y,
            panel = SETTING_PANEL_CAMERA,
            text =  ZO_IsConsolePlatform() and SI_GAMEPAD_OPTIONS_INVERT_Y or SI_GAMEPAD_OPTIONS_INVERT_Y_PC,
        },
        --Options_Gamepad_InvertX
        [GAMEPAD_SETTING_INVERT_X] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_INVERT_X,
            panel = SETTING_PANEL_CAMERA,
            text =  ZO_IsConsolePlatform() and SI_GAMEPAD_OPTIONS_INVERT_X or SI_GAMEPAD_OPTIONS_INVERT_X_PC,
        },
    },
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_CAMERA, ZO_OptionsPanel_Camera_ControlData)