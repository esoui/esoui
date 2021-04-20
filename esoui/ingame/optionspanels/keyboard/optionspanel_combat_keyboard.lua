local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_COMBAT)

-------------------
-- Combat -> HUD --
-------------------
panelBuilder:AddSetting({
    controlName = "Options_Combat_ShowActionBar",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_ACTION_BAR,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_ShowActionBarTimers",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_ACTION_BAR_TIMERS,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_ShowActionBarBackRow",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_ACTION_BAR_BACK_ROW,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_ShowResourceBars",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_SHOW_RESOURCE_BARS,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_ResourceNumbers",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_RESOURCE_NUMBERS,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_ActiveCombatTips",
    settingType = SETTING_TYPE_ACTIVE_COMBAT_TIP,
    settingId = 0, -- TODO: make an enum for this, or merge it with another setting type
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_UltimateNumber",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_ULTIMATE_NUMBER,
    header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
})

-------------------
-- Combat -> HUD --
-------------------
panelBuilder:AddSetting({
    controlName = "Options_Combat_EncounterLogAppearAnonymous",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_ENCOUNTER_LOG_APPEAR_ANONYMOUS,
    header = SI_INTERFACE_OPTIONS_ENCOUNTER_LOG,
})

-------------------
-- Combat -> SCT --
-------------------
panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCROLLING_COMBAT_TEXT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
})

-- outgoing
panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingDamageEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_DAMAGE_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingDoTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_DOT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingHealingEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_HEALING_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingHoTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_HOT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingStatusEffectsEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_STATUS_EFFECTS_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingPetDamageEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_PET_DAMAGE_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingPetDoTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_PET_DOT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingPetHealingEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_PET_HEALING_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTOutgoingPetHoTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_OUTGOING_PET_HOT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

-- incoming
panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingDamageEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_DAMAGE_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingDoTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_DOT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingHealingEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_HEALING_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingHoTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_HOT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingStatusEffectsEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_STATUS_EFFECTS_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingPetDamageEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_PET_DAMAGE_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTIncomingPetDoTEnabled",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_INCOMING_PET_DOT_ENABLED,
    header = SI_INTERFACE_OPTIONS_SCT,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_SCTShowOverHeal",
    settingType = SETTING_TYPE_COMBAT,
    settingId = COMBAT_SETTING_SCT_SHOW_OVER_HEAL,
    header = SI_INTERFACE_OPTIONS_SCT,
})

---------------------------
-- Combat -> Buff/Debuff --
---------------------------

panelBuilder:AddSetting({
    controlName = "Options_Combat_Buffs_AllEnabled",
    settingType = SETTING_TYPE_BUFFS,
    settingId = BUFFS_SETTING_ALL_ENABLED,
    header = SI_BUFFS_OPTIONS_SECTION_TITLE,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_Buffs_SelfBuffs",
    settingType = SETTING_TYPE_BUFFS,
    settingId = BUFFS_SETTING_BUFFS_ENABLED_FOR_SELF,
    header = SI_BUFFS_OPTIONS_SECTION_TITLE,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_Buffs_SelfDebuffs",
    settingType = SETTING_TYPE_BUFFS,
    settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_SELF,
    header = SI_BUFFS_OPTIONS_SECTION_TITLE,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_Buffs_TargetDebuffs",
    settingType = SETTING_TYPE_BUFFS,
    settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET,
    header = SI_BUFFS_OPTIONS_SECTION_TITLE,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Option_Combat_Buffs_Debuffs_Enabled_For_Target_From_Others",
    settingType = SETTING_TYPE_BUFFS,
    settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS,
    header = SI_BUFFS_OPTIONS_SECTION_TITLE,
    indentLevel = 2,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_Buffs_LongEffects",
    settingType = SETTING_TYPE_BUFFS,
    settingId = BUFFS_SETTING_LONG_EFFECTS,
    header = SI_BUFFS_OPTIONS_SECTION_TITLE,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Combat_Buffs_PermanentEffects",
    settingType = SETTING_TYPE_BUFFS,
    settingId = BUFFS_SETTING_PERMANENT_EFFECTS,
    header = SI_BUFFS_OPTIONS_SECTION_TITLE,
    indentLevel = 1,
})
