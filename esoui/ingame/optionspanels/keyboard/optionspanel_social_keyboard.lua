local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_SOCIAL)

-----------------------------
-- Social -> Chat settings --
-----------------------------
panelBuilder:AddSetting({
    controlName = "Options_Social_TextSize",
    template = "ZO_Options_Slider",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_TEXT_SIZE,
    header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_MinAlpha",
    template = "ZO_Options_Slider",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_MIN_ALPHA,
    header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_UseProfanityFilter",
    settingType = SETTING_TYPE_LANGUAGE,
    settingId = LANGUAGE_SETTING_USE_PROFANITY_FILTER,
    header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ReturnCursorOnChatFocus",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_RETURN_CURSOR_ON_CHAT_FOCUS,
    header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
})

-----------------------------
-- Social -> Notifications --
-----------------------------
panelBuilder:AddSetting({
    controlName = "Options_Social_LeaderboardsNotification",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_LEADERBOARD_NOTIFICATIONS,
    header = SI_SOCIAL_OPTIONS_NOTIFICATIONS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_AutoDeclineDuelInvites",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_AUTO_DECLINE_DUEL_INVITES,
    header = SI_SOCIAL_OPTIONS_NOTIFICATIONS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_AutoDeclineTributeInvites",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_AUTO_DECLINE_TRIBUTE_INVITES,
    header = SI_SOCIAL_OPTIONS_NOTIFICATIONS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_AvANotifications",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_AVA_NOTIFICATIONS,
    header = SI_SOCIAL_OPTIONS_NOTIFICATIONS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_GuildKeepNotices",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_GUILD_KEEP_NOTICES,
    header = SI_SOCIAL_OPTIONS_NOTIFICATIONS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_PvPKillFeedNotifications",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_PVP_KILL_FEED_NOTIFICATIONS,
    header = SI_SOCIAL_OPTIONS_NOTIFICATIONS,
})

---------------------------
-- Social -> Chat Colors --
---------------------------
panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Say",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_SAY,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Yell",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_YELL,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_WhisperIncoming",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_WHISPER_INC,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_WhisperOutgoing",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_WHISPER_OUT,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Group",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GROUP,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Zone",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

for language = OFFICIAL_LANGUAGE_ITERATION_BEGIN, OFFICIAL_LANGUAGE_ITERATION_END do
    local chatInfo = ZO_OFFICIAL_LANGUAGE_TO_CHAT_INFO[language]
    panelBuilder:AddSetting({
        controlName = chatInfo.chatColorCustomSettingControlName,
        settingType = SETTING_TYPE_CUSTOM,
        settingId = chatInfo.chatColorCustomSetting,
        header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
    })
end

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_NPC",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_NPC,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Emote",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_EMOTE,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_System",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_SYSTEM,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_Guild1Title",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD1,
    template = "ZO_Options_Social_GuildLabel",
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Guild1",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD1,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Officer1",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER1,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_Guild2Title",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD2,
    template = "ZO_Options_Social_GuildLabel",
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Guild2",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD2,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Officer2",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER2,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_Guild3Title",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD3,
    template = "ZO_Options_Social_GuildLabel",
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Guild3",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD3,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Officer3",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER3,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_Guild4Title",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD4,
    template = "ZO_Options_Social_GuildLabel",
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Guild4",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD4,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Officer4",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER4,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_Guild5Title",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD5,
    template = "ZO_Options_Social_GuildLabel",
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Guild5",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD5,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Social_ChatColor_Officer5",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER5,
    header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
})
