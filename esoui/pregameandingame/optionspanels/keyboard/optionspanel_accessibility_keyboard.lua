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
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_TextChatNarration",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_ZoneChatNarration",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_ZONE_CHAT_NARRATION,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
    indentLevel = 2,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_ScreenNarration",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_SCREEN_NARRATION,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_TextInputNarration",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_TEXT_INPUT_NARRATION,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
    indentLevel = 2,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_NarrationVolume",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_NARRATION_VOLUME,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_NarrationVoiceSpeed",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_NARRATION_VOICE_SPEED,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_NarrationVoiceType",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_NARRATION_VOICE_TYPE,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_AccessibleQuickwheels",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_Waypoint_Color",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_PLAYER_WAYPOINT_ICON_COLOR,
    header = SI_ACCESSIBILITY_OPTIONS_GENERAL,
})
------------------------------------------
-- Accessibility -> Arcanist Aim Assist --
------------------------------------------
panelBuilder:AddSetting({
    controlName = "Options_Accessibility_GamepadAimAssistIntensity",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_GAMEPAD_AIM_ASSIST_INTENSITY,
    header = SI_ACCESSIBILITY_OPTIONS_ARCANIST,
    exists = function()
        return ZO_IsIngameUI()
    end,
})

panelBuilder:AddSetting({
    controlName = "Options_Accessibility_MouseAimAssistIntensity",
    settingType = SETTING_TYPE_ACCESSIBILITY,
    settingId = ACCESSIBILITY_SETTING_MOUSE_AIM_ASSIST_INTENSITY,
    header = SI_ACCESSIBILITY_OPTIONS_ARCANIST,
    exists = function()
        return ZO_IsIngameUI()
    end,
})
