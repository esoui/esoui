local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_INTERFACE)

----------------------
-- Interface -> HUD --
----------------------
panelBuilder:AddSetting({
    controlName = "Options_Interface_TextLanguageKeyboard",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_TEXT_LANGUAGE,
    header = SI_INTERFACE_OPTIONS_LANGUAGE,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_PrimaryPlayerNameKeyboard",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_PRIMARY_PLAYER_NAME_KEYBOARD,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ShowRaidLives",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_RAID_LIVES,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "UI_Settings_ShowHouseTracker",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_HOUSE_TRACKER,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "UI_Settings_ShowQuestTracker",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_QUEST_TRACKER,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "UI_Settings_AutomaticQuestTracking",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_AUTOMATIC_QUEST_TRACKING,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_QuestBestowerIndicators",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_CompassQuestGivers",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_COMPASS_QUEST_GIVERS,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_CompassActiveQuests",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_COMPASS_ACTIVE_QUESTS,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
    template = "ZO_Options_Dropdown_DynamicWarning",
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_CompassCompanion",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_COMPASS_COMPANION,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_CompassTargetMarkers",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_COMPASS_TARGET_MARKERS,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ShowWeaponIndicator",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_WEAPON_INDICATOR,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ShowArmorIndicator",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_ARMOR_INDICATOR,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

-------------------------------
-- Interface -> Chat Bubbles --
-------------------------------
panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesEnabled",
    settingType = SETTING_TYPE_CHAT_BUBBLE,
    settingId =  CHAT_BUBBLE_SETTING_ENABLED,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesSpeed",
    settingType = SETTING_TYPE_CHAT_BUBBLE,
    settingId =  CHAT_BUBBLE_SETTING_SPEED_MODIFIER,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
    template = "ZO_Options_Slider_VerticalLabel",
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesEnabledRestrictToContacts",
    settingType = SETTING_TYPE_CHAT_BUBBLE,
    settingId =  CHAT_BUBBLE_SETTING_ENABLED_ONLY_FROM_CONTACTS,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesEnabledForLocalPlayer",
    settingType = SETTING_TYPE_CHAT_BUBBLE,
    settingId =  CHAT_BUBBLE_SETTING_ENABLED_FOR_LOCAL_PLAYER,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesSayChannel",
    settingType = SETTING_TYPE_CUSTOM,
    settingId =  OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_SAY_ENABLED,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
    initializeControlFunction = ZO_OptionsPanel_Interface_ChatBubbleChannel_OnInitialized,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesYellChannel",
    settingType = SETTING_TYPE_CUSTOM,
    settingId =  OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_YELL_ENABLED,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
    initializeControlFunction = ZO_OptionsPanel_Interface_ChatBubbleChannel_OnInitialized,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesWhisperChannel",
    settingType = SETTING_TYPE_CUSTOM,
    settingId =  OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_WHISPER_ENABLED,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
    initializeControlFunction = ZO_OptionsPanel_Interface_ChatBubbleChannel_OnInitialized,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesGroupChannel",
    settingType = SETTING_TYPE_CUSTOM,
    settingId =  OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_GROUP_ENABLED,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
    initializeControlFunction = ZO_OptionsPanel_Interface_ChatBubbleChannel_OnInitialized,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_ChatBubblesEmoteChannel",
    settingType = SETTING_TYPE_CUSTOM,
    settingId =  OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_EMOTE_ENABLED,
    header = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    indentLevel = 1,
    initializeControlFunction = ZO_OptionsPanel_Interface_ChatBubbleChannel_OnInitialized,
})

------------------------------
-- Interface -> Performance --
------------------------------
panelBuilder:AddSetting({
    controlName = "Options_Interface_FramerateCheck",
    settingType = SETTING_TYPE_UI,
    settingId =  UI_SETTING_SHOW_FRAMERATE,
    header = SI_INTERFACE_OPTIONS_PERFORMANCE,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_LatencyCheck",
    settingType = SETTING_TYPE_UI,
    settingId =  UI_SETTING_SHOW_LATENCY,
    header = SI_INTERFACE_OPTIONS_PERFORMANCE,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_FramerateLatencyLockCheck",
    settingType = SETTING_TYPE_UI,
    settingId =  UI_SETTING_FRAMERATE_LATENCY_LOCK,
    header = SI_INTERFACE_OPTIONS_PERFORMANCE,
})

panelBuilder:AddSetting({
    controlName = "Options_Interface_FramerateLatencyResetPosition",
    settingType = SETTING_TYPE_CUSTOM,
    settingId =  OPTIONS_CUSTOM_SETTING_FRAMERATE_LATENCY_RESET_POSITION,
    header = SI_INTERFACE_OPTIONS_PERFORMANCE,
})
