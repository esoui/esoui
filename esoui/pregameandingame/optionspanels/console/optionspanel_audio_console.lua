local ZO_OptionsPanel_Audio_ControlData =
{
    [AUDIO_SETTING_VOICE_CHAT_VOLUME] =
    {
        system = SETTING_TYPE_AUDIO,
        settingId = AUDIO_SETTING_VOICE_CHAT_VOLUME,
        controlType = OPTIONS_SLIDER,
        panel = SETTING_PANEL_DEBUG,
        text = SI_GAMEPAD_AUDIO_OPTIONS_VOICECHAT_VOLUME,
        minValue = 40,
        maxValue = 75,
        },
}

SYSTEMS:GetObject("options"):AddTableToSystem(SETTING_PANEL_AUDIO, SETTING_TYPE_AUDIO, ZO_OptionsPanel_Audio_ControlData)