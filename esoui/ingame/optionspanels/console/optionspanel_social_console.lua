local function OnScrollListChanged(selectedData)
    SetGamepadChatFontSize(selectedData.value)
    CHAT_SYSTEM:SetFontSize(selectedData.value)
end

local ZO_OptionsPanel_Social_UI_ControlData =
{
    [UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED] =
    {
        controlType = OPTIONS_CHECKBOX,
        panel = SETTING_PANEL_SOCIAL,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED,
        text = SI_SOCIAL_OPTIONS_GAMEPAD_CHAT_HUD_ENABLED,
        tooltipText = SI_SOCIAL_OPTIONS_GAMEPAD_CHAT_HUD_ENABLED_TOOLTIP,
    },
}

SYSTEMS:GetObject("options"):AddTableToSystem(SETTING_PANEL_SOCIAL, SETTING_TYPE_UI, ZO_OptionsPanel_Social_UI_ControlData)

local ZO_OptionsPanel_Social_Custom_ControlData =
{
    [OPTIONS_CUSTOM_SETTING_SOCIAL_GAMEPAD_TEXT_SIZE] =
    {
        controlType = OPTIONS_FINITE_LIST,
        panel = SETTING_PANEL_SOCIAL,
        text = SI_SOCIAL_OPTIONS_TEXT_SIZE,
        tooltipText = SI_SOCIAL_OPTIONS_TEXT_SIZE_TOOLTIP,
        valid = { GAMEPAD_CHAT_TEXT_SIZE_SETTING_SMALL, GAMEPAD_CHAT_TEXT_SIZE_SETTING_MEDIUM, GAMEPAD_CHAT_TEXT_SIZE_SETTING_LARGE, },
        valueStringPrefix = "SI_GAMEPADCHATTEXTSIZESETTING",
        GetSettingOverride = GetGamepadChatFontSize,
        scrollListChangedCallback = OnScrollListChanged,
    },
}

SYSTEMS:GetObject("options"):AddTableToSystem(SETTING_PANEL_SOCIAL, SETTING_TYPE_CUSTOM, ZO_OptionsPanel_Social_Custom_ControlData)