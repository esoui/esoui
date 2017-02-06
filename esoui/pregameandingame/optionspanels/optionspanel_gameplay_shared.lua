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
    },
}

SYSTEMS:GetObject("options"):AddTableToPanel(SETTING_PANEL_GAMEPLAY, ZO_OptionsPanel_Gameplay_ControlData)