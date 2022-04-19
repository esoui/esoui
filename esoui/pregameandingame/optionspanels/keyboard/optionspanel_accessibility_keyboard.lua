local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_ACCESSIBILITY)

---------------------------
-- Accessibility -> Main --
---------------------------
panelBuilder:AddSetting({
    controlName = "Options_Accessibility_AccessibilityMode",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_VoiceChatAccessibility",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_VOICE_CHAT_ACCESSIBILITY,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_TextChatAccessibility",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_TEXT_CHAT_ACCESSIBILITY,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
})