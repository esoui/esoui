local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_NAMEPLATES)

------------------------------
-- Nameplates -> Nameplates --
------------------------------
panelBuilder:AddSetting({
    controlName = "Options_Nameplates_AllNameplates",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ALL_NAMEPLATES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_ShowPlayerTitles",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_SHOW_PLAYER_TITLES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_ShowPlayerGuilds",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_SHOW_PLAYER_GUILDS,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_Player",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_PLAYER_NAMEPLATE,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_PlayerDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_PLAYER_NAMEPLATE_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_GroupMember",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_GroupMemberDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyNPC",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyNPCDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyPlayer",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyPlayerDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_NeutralNPC",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_NeutralNPCDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyNPC",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyNPCDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyPlayer",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyPlayerDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_NAMEPLATES,
    indentLevel = 1,
})

------------------------------
-- Nameplates -> Healthbars --
------------------------------
panelBuilder:AddSetting({
    controlName = "Options_Nameplates_AllHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ALL_HEALTHBARS,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_HealthbarAlignment",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_HEALTHBAR_ALIGNMENT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_HealthbarChaseBar",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_HEALTHBAR_CHASE_BAR,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_HealthbarFrameBorder",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_HEALTHBAR_FRAME_BORDER,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_PlayerHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_PLAYER_HEALTHBAR,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_PlayerHBDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_PLAYER_HEALTHBAR_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_GroupMemberHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_GroupMemberHBDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyNPCHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyNPCHBDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyPlayerHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FriendlyPlayerHBDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_NeutralNPCHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_NeutralNPCHBDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyNPCHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyNPCHBDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyPlayerHB",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_EnemyPlayerHBDimmed",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS_HIGHLIGHT,
    header = SI_INTERFACE_OPTIONS_HEALTHBARS,
    indentLevel = 1,
})

------------------------------
-- Nameplates -> Indicators --
------------------------------
panelBuilder:AddSetting({
    controlName = "Options_Nameplates_AllianceIndicators",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_ALLIANCE_INDICATORS,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_GroupIndicators",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_GROUP_INDICATORS,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_TargetMarkers",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_TARGET_MARKERS,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_TargetMarkerSize",
    settingType = SETTING_TYPE_IN_WORLD,
    settingId = IN_WORLD_UI_SETTING_TARGET_MARKER_SIZE,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_ResurrectIndicators",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_RESURRECT_INDICATORS,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_FollowerIndicators",
    settingType = SETTING_TYPE_NAMEPLATES,
    settingId = NAMEPLATE_TYPE_FOLLOWER_INDICATORS,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_GlowThickness",
    settingType = SETTING_TYPE_IN_WORLD,
    settingId = IN_WORLD_UI_SETTING_GLOW_THICKNESS,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_TargetGlowCheck",
    settingType = SETTING_TYPE_IN_WORLD,
    settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_TargetGlowIntensity",
    settingType = SETTING_TYPE_IN_WORLD,
    settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_InteractableGlowCheck",
    settingType = SETTING_TYPE_IN_WORLD,
    settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
})

panelBuilder:AddSetting({
    controlName = "Options_Nameplates_InteractableGlowIntensity",
    settingType = SETTING_TYPE_IN_WORLD,
    settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_INTENSITY,
    header = SI_INTERFACE_OPTIONS_INDICATORS,
    indentLevel = 1,
})
