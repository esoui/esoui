local function SetControlActiveFromPredicate(control, predicate)
    if predicate() then
        ZO_Options_SetOptionActive(control)
    else
        ZO_Options_SetOptionInactive(control)
    end
end

local function AreNameplatesEnabled()
    return tonumber(GetSetting(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_NAMEPLATES)) ~= 0
end

local function AreHealthbarsEnabled()
    return tonumber(GetSetting(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_HEALTHBARS)) ~= 0
end

local function CreateNameplateShownOption(option, stringsPrefix, ...)
    local settingData = 
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_NAMEPLATES,
        panel = SETTING_PANEL_NAMEPLATES,
        settingId = option,
        text = _G["SI_INTERFACE_OPTIONS_NAMEPLATES_"..stringsPrefix],
        tooltipText = _G["SI_INTERFACE_OPTIONS_NAMEPLATES_"..stringsPrefix.."_TOOLTIP"],
        valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
        valid = { ... },
        gamepadIsEnabledCallback = AreNameplatesEnabled,
        gamepadHasEnabledDependencies = true,
        eventCallbacks =
        {
            ["AllNameplates_Off"]   = ZO_Options_SetOptionInactive,
            ["AllNameplates_On"]    = ZO_Options_SetOptionActive,
        },
    }

    settingData.events = {}
    local optionEventName = string.format("NameplateType%d_Changed", option)
    for _, optionChoice in ipairs(settingData.valid) do
        settingData.events[optionChoice] = optionEventName
    end

    return settingData
end

local function CreateNameplateDimmingOption(option, stringsPrefix, dependsOnOption, ...)
    local function IsDimmingOptionEnabled()
        return AreNameplatesEnabled() and tonumber(GetSetting(SETTING_TYPE_NAMEPLATES, dependsOnOption)) ~= NAMEPLATE_CHOICE_NEVER
    end
    
    local function SetupDimmingOptionEnabled(control)
         SetControlActiveFromPredicate(control, IsDimmingOptionEnabled)
    end

    local dependsOnOptionEventName = string.format("NameplateType%d_Changed", dependsOnOption)

    local settingData =
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_NAMEPLATES,
        panel = SETTING_PANEL_NAMEPLATES,
        settingId = option,
        text = _G["SI_INTERFACE_OPTIONS_NAMEPLATES_HIGHLIGHT_"..stringsPrefix],
        tooltipText = _G["SI_INTERFACE_OPTIONS_NAMEPLATES_HIGHLIGHT_"..stringsPrefix.."_TOOLTIP"],
        valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
        valid = { ... },
        gamepadIsEnabledCallback = IsDimmingOptionEnabled,
        eventCallbacks =
        {
            ["AllNameplates_Off"] = SetupDimmingOptionEnabled,
            ["AllNameplates_On"] = SetupDimmingOptionEnabled,
            [dependsOnOptionEventName] = SetupDimmingOptionEnabled,
        },
    }

    return settingData
end

local function CreateHealthbarShownOption(option, stringsPrefix, ...)
    local settingData = 
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_NAMEPLATES,
        settingId = option,
        panel = SETTING_PANEL_NAMEPLATES,
        text = _G["SI_INTERFACE_OPTIONS_HEALTHBARS_"..stringsPrefix],
        tooltipText = _G["SI_INTERFACE_OPTIONS_HEALTHBARS_"..stringsPrefix.."_TOOLTIP"],
        valid = { ... },
        valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
        eventCallbacks =
        {
            ["AllHealthBars_Off"] = ZO_Options_SetOptionInactive,
            ["AllHealthBars_On"] = ZO_Options_SetOptionActive,
        },
        gamepadIsEnabledCallback = AreHealthbarsEnabled,
        gamepadHasEnabledDependencies = true,
    }

    settingData.events = {}
    local optionEventName = string.format("HealthbarType%d_Changed", option)
    for _, optionChoice in ipairs(settingData.valid) do
        settingData.events[optionChoice] = optionEventName
    end

    return settingData
end

local function CreateHealthbarDimmingOption(option, stringsPrefix, dependsOnOption, ...)
    local function IsDimmingOptionEnabled()
        return AreHealthbarsEnabled() and tonumber(GetSetting(SETTING_TYPE_NAMEPLATES, dependsOnOption)) ~= NAMEPLATE_CHOICE_NEVER
    end
    
    local function SetupDimmingOptionEnabled(control)
         SetControlActiveFromPredicate(control, IsDimmingOptionEnabled)
    end

    local dependsOnOptionEventName = string.format("HealthbarType%d_Changed", dependsOnOption)

    local settingData =
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_NAMEPLATES,
        panel = SETTING_PANEL_NAMEPLATES,
        settingId = option,
        text = _G["SI_INTERFACE_OPTIONS_HEALTHBARS_HIGHLIGHT_"..stringsPrefix],
        tooltipText = _G["SI_INTERFACE_OPTIONS_HEALTHBARS_HIGHLIGHT_"..stringsPrefix.."_TOOLTIP"],
        valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
        valid = { ... },
        gamepadIsEnabledCallback = IsDimmingOptionEnabled,
        eventCallbacks =
        {
            ["AllHealthBars_Off"] = SetupDimmingOptionEnabled,
            ["AllHealthBars_On"] = SetupDimmingOptionEnabled,
            [dependsOnOptionEventName] = SetupDimmingOptionEnabled,
        },
    }
    return settingData
end

local ZO_OptionsPanel_Nameplates_ControlData =
{
    --Nameplates and Healthbars
    [SETTING_TYPE_NAMEPLATES] =
    {
        --Options_Nameplates_AllNameplates
        [NAMEPLATE_TYPE_ALL_NAMEPLATES] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_ALL,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_ALL_TOOLTIP,
            events = {[false] = "AllNameplates_Off", [true] = "AllNameplates_On",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Nameplates_ShowPlayerTitles
        [NAMEPLATE_TYPE_SHOW_PLAYER_TITLES] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_SHOW_PLAYER_TITLES,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_SHOW_PLAYER_TITLES,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_SHOW_PLAYER_TITLES_TOOLTIP,
            gamepadIsEnabledCallback = AreNameplatesEnabled,
            eventCallbacks =
            {
                ["AllNameplates_Off"]   = ZO_Options_SetOptionInactive,
                ["AllNameplates_On"]    = ZO_Options_SetOptionActive,
            },
        },
        --Options_Nameplates_ShowPlayerGuilds
        [NAMEPLATE_TYPE_SHOW_PLAYER_GUILDS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_SHOW_PLAYER_GUILDS,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_SHOW_PLAYER_GUILDS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_SHOW_PLAYER_GUILDS_TOOLTIP,
            gamepadIsEnabledCallback = AreNameplatesEnabled,
            eventCallbacks =
            {
                ["AllNameplates_Off"]   = ZO_Options_SetOptionInactive,
                ["AllNameplates_On"]    = ZO_Options_SetOptionActive,
            },
        },
        --Options_Nameplates_Player
        [NAMEPLATE_TYPE_PLAYER_NAMEPLATE] = CreateNameplateShownOption(NAMEPLATE_TYPE_PLAYER_NAMEPLATE, "PLAYER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_PlayerDimmed
        [NAMEPLATE_TYPE_PLAYER_NAMEPLATE_HIGHLIGHT] = CreateNameplateDimmingOption(NAMEPLATE_TYPE_PLAYER_NAMEPLATE_HIGHLIGHT, "PLAYER", NAMEPLATE_TYPE_PLAYER_NAMEPLATE, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_GroupMember
        [NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES] = CreateNameplateShownOption(NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES, "GROUP_MEMBER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_GroupMemberDimmed
        [NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES_HIGHLIGHT] = CreateNameplateDimmingOption(NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES_HIGHLIGHT, "GROUP_MEMBER", NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyNPC
        [NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES] = CreateNameplateShownOption(NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES, "FRIENDLY_NPC", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyNPCDimmed
        [NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES_HIGHLIGHT] = CreateNameplateDimmingOption(NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES_HIGHLIGHT, "FRIENDLY_NPC", NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyPlayer
        [NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES] = CreateNameplateShownOption(NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES, "FRIENDLY_PLAYER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyPlayerDimmed
        [NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES_HIGHLIGHT] = CreateNameplateDimmingOption(NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES_HIGHLIGHT, "FRIENDLY_PLAYER", NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_NeutralNPC
        [NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES] = CreateNameplateShownOption(NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES, "NEUTRAL_NPC", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_NeutralNPCDimmed
        [NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES_HIGHLIGHT] = CreateNameplateDimmingOption(NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES_HIGHLIGHT, "NEUTRAL_NPC", NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyNPC
        [NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES] = CreateNameplateShownOption(NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES, "ENEMY_NPC", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyNPCDimmed
        [NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES_HIGHLIGHT] = CreateNameplateDimmingOption(NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES_HIGHLIGHT, "ENEMY_NPC", NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyPlayer
        [NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES] = CreateNameplateShownOption(NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES, "ENEMY_PLAYER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyPlayerDimmed
        [NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES_HIGHLIGHT] = CreateNameplateDimmingOption(NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES_HIGHLIGHT, "ENEMY_PLAYER", NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_AllHB
        [NAMEPLATE_TYPE_ALL_HEALTHBARS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALL_HEALTHBARS,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_HEALTHBARS_ALL,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBARS_ALL_TOOLTIP,
            events = {[false] = "AllHealthBars_Off", [true] = "AllHealthBars_On", },
            gamepadHasEnabledDependencies = true,
        },
        --Options_Nameplates_HealthbarAlignment
        [NAMEPLATE_TYPE_HEALTHBAR_ALIGNMENT] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_HEALTHBAR_ALIGNMENT,
            text = SI_INTERFACE_OPTIONS_HEALTHBAR_ALIGNMENT,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBAR_ALIGNMENT_TOOLTIP,
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
            valid = { NAMEPLATE_CHOICE_LEFT, NAMEPLATE_CHOICE_CENTER },
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
        },
        --Options_Nameplates_HealthbarChaseBar
        [NAMEPLATE_TYPE_HEALTHBAR_CHASE_BAR] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_HEALTHBAR_CHASE_BAR,
            text = SI_INTERFACE_OPTIONS_HEALTHBAR_CHASE_BAR,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBAR_CHASE_BAR_TOOLTIP,
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
        },
        --Options_Nameplates_HealthbarFrameBorder
        [NAMEPLATE_TYPE_HEALTHBAR_FRAME_BORDER] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_HEALTHBAR_FRAME_BORDER,
            text = SI_INTERFACE_OPTIONS_HEALTHBAR_FRAME_BORDER,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBAR_FRAME_BORDER_TOOLTIP,
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
        },
        --Options_Nameplates_PlayerHB
        [NAMEPLATE_TYPE_PLAYER_HEALTHBAR] = CreateHealthbarShownOption(NAMEPLATE_TYPE_PLAYER_HEALTHBAR, "PLAYER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_PlayerHBDimmed
        [NAMEPLATE_TYPE_PLAYER_HEALTHBAR_HIGHLIGHT] = CreateHealthbarDimmingOption(NAMEPLATE_TYPE_PLAYER_HEALTHBAR_HIGHLIGHT, "PLAYER", NAMEPLATE_TYPE_PLAYER_HEALTHBAR, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_GroupMemberHB
        [NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS] = CreateHealthbarShownOption(NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS, "GROUP_MEMBER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_GroupMemberHBDimmed
        [NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS_HIGHLIGHT] = CreateHealthbarDimmingOption(NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS_HIGHLIGHT, "GROUP_MEMBER", NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyNPCHB
        [NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS] = CreateHealthbarShownOption(NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS, "FRIENDLY_NPC", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyNPCHBDimmed
        [NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS_HIGHLIGHT] = CreateHealthbarDimmingOption(NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS_HIGHLIGHT, "FRIENDLY_NPC", NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyPlayerHB
        [NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS] = CreateHealthbarShownOption(NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS, "FRIENDLY_PLAYER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_FriendlyPlayerHBDimmed
        [NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS_HIGHLIGHT] = CreateHealthbarDimmingOption(NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS_HIGHLIGHT, "FRIENDLY_PLAYER", NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_NeutralNPCHB
        [NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS] = CreateHealthbarShownOption(NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS, "NEUTRAL_NPC", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_NeutralNPCHBDimmed
        [NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS_HIGHLIGHT] = CreateHealthbarDimmingOption(NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS_HIGHLIGHT, "NEUTRAL_NPC", NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyNPCHB
        [NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS] = CreateHealthbarShownOption(NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS, "ENEMY_NPC", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyNPCHBDimmed
        [NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS_HIGHLIGHT] = CreateHealthbarDimmingOption(NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS_HIGHLIGHT, "ENEMY_NPC", NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyPlayerHB
        [NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS] = CreateHealthbarShownOption(NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS, "ENEMY_PLAYER", NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_EnemyPlayerHBDimmed
        [NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS_HIGHLIGHT] = CreateHealthbarDimmingOption(NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS_HIGHLIGHT, "ENEMY_PLAYER", NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS, NAMEPLATE_CHOICE_TARGETED, NAMEPLATE_CHOICE_INJURED, NAMEPLATE_CHOICE_INJURED_OR_TARGETED, NAMEPLATE_CHOICE_ALWAYS),
        --Options_Nameplates_AllianceIndicators
        [NAMEPLATE_TYPE_ALLIANCE_INDICATORS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALLIANCE_INDICATORS,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_ALLIANCE_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_ALLIANCE_INDICATORS_TOOLTIP,
            valid = {NAMEPLATE_CHOICE_NEVER, NAMEPLATE_CHOICE_ALLY, NAMEPLATE_CHOICE_ENEMY, NAMEPLATE_CHOICE_ALL},
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
        },
        --Options_Nameplates_GroupIndicators
        [NAMEPLATE_TYPE_GROUP_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_INDICATORS,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_GROUP_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_GROUP_INDICATORS_TOOLTIP,
        },
        --Options_Nameplates_ResurrectIndicators
        [NAMEPLATE_TYPE_RESURRECT_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_RESURRECT_INDICATORS,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_RESURRECT_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_RESURRECT_INDICATORS_TOOLTIP,
        },
        --Options_Nameplates_FollowerIndicators
        [NAMEPLATE_TYPE_FOLLOWER_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FOLLOWER_INDICATORS,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_FOLLOWER_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_FOLLOWER_INDICATORS_TOOLTIP,
        },
    },
    --UI
    [SETTING_TYPE_UI] =
    {
        --Options_Nameplates_QuestBestowers
        [UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_SHOW_QUEST_BESTOWERS,
            tooltipText = SI_INTERFACE_OPTIONS_SHOW_QUEST_BESTOWERS_TOOLTIP,
            events = {[true] = "Bestowers_On", [false] = "Bestowers_Off",},
            gamepadHasEnabledDependencies = true,
        },
    },
    --InWorld
    [SETTING_TYPE_IN_WORLD] =
    {
        --Options_Nameplates_GlowThickness
        [IN_WORLD_UI_SETTING_GLOW_THICKNESS] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_GLOW_THICKNESS,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_GLOWS_THICKNESS,
            tooltipText = SI_INTERFACE_OPTIONS_GLOWS_THICKNESS_TOOLTIP,
        
            valueFormat = "%f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Nameplates_TargetGlowCheck
        [IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED,
            text = SI_INTERFACE_OPTIONS_TARGET_GLOWS_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_TARGET_GLOWS_ENABLED_TOOLTIP,
            events = {[true] = "TargetGlowEnabled_On", [false] = "TargetGlowEnabled_Off",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Nameplates_TargetGlowIntensity
        [IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_TARGET_GLOWS_INTENSITY,
            tooltipText = SI_INTERFACE_OPTIONS_TARGET_GLOWS_INTENSITY_TOOLTIP,
        
            valueFormat = "%f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        
            eventCallbacks =
            {
                ["TargetGlowEnabled_On"]    = ZO_Options_SetOptionActive,
                ["TargetGlowEnabled_Off"]   = ZO_Options_SetOptionInactive,
            },
            gamepadIsEnabledCallback = function() 
                                            return tonumber(GetSetting(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED)) ~= 0
                                        end,
        },
        --Options_Nameplates_InteractableGlowCheck
        [IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED,
            text = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_ENABLED_TOOLTIP,
            events = {[true] = "InteractableGlowEnabled_On", [false] = "InteractableGlowEnabled_Off",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Nameplates_InteractableGlowIntensity
        [IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_INTENSITY] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_INTENSITY,
            panel = SETTING_PANEL_NAMEPLATES,
            text = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_INTENSITY,
            tooltipText = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_INTENSITY_TOOLTIP,
        
            valueFormat = "%f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        
            eventCallbacks =
            {
                ["InteractableGlowEnabled_On"]    = ZO_Options_SetOptionActive,
                ["InteractableGlowEnabled_Off"]   = ZO_Options_SetOptionInactive,
            },
            gamepadIsEnabledCallback = function() 
                                            return tonumber(GetSetting(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED)) ~= 0
                                        end,
        },
    },
}

SYSTEMS:GetObject("options"):AddTableToPanel(SETTING_PANEL_NAMEPLATES, ZO_OptionsPanel_Nameplates_ControlData)