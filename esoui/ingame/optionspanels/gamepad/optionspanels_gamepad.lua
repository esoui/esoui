--Ingame Options table

local interfaceSettingsHUD = {
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_PRIMARY_PLAYER_NAME_GAMEPAD,
        header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_SHOW_ACTION_BAR,
    },
	{
		panel = SETTING_PANEL_INTERFACE,
		system = SETTING_TYPE_UI,
		settingId = UI_SETTING_RESOURCE_NUMBERS,
	},
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_SHOW_RAID_LIVES,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_ACTIVE_COMBAT_TIP,
        settingId = 0,
    },
	{
		panel = SETTING_PANEL_INTERFACE,
		system = SETTING_TYPE_UI,
		settingId = UI_SETTING_ULTIMATE_NUMBER,
	},
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_SHOW_QUEST_TRACKER,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_COMPASS_QUEST_GIVERS,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_COMPASS_ACTIVE_QUESTS,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_SHOW_WEAPON_INDICATOR,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_SHOW_ARMOR_INDICATOR,
    },
}

local interfaceSettingsChatBubbles = {
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CHAT_BUBBLE,
        settingId = CHAT_BUBBLE_SETTING_ENABLED,
        header = IsConsoleUI() and SI_INTERFACE_OPTIONS_QUICK_CHAT or SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CHAT_BUBBLE,
        settingId = CHAT_BUBBLE_SETTING_SPEED_MODIFIER,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CHAT_BUBBLE,
        settingId = CHAT_BUBBLE_SETTING_ENABLED_ONLY_FROM_CONTACTS,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CHAT_BUBBLE,
        settingId = CHAT_BUBBLE_SETTING_ENABLED_FOR_LOCAL_PLAYER,
    },
}
local interfaceSettingsScrollingCombatText = {
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCROLLING_COMBAT_TEXT_ENABLED,
        header = SI_INTERFACE_OPTIONS_SCT,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_DAMAGE_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_DOT_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_HEALING_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_HOT_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_STATUS_EFFECTS_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_PET_DAMAGE_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_PET_DOT_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_PET_HEALING_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_OUTGOING_PET_HOT_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_DAMAGE_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_DOT_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_HEALING_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_HOT_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_STATUS_EFFECTS_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_PET_DAMAGE_ENABLED,
    },
    {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_COMBAT,
        settingId = COMBAT_SETTING_SCT_INCOMING_PET_DOT_ENABLED,
    },
}

GAMEPAD_SETTINGS_DATA =
{
    [SETTING_PANEL_VIDEO] =
    {
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_GAMMA_ADJUST,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
        },
    },
    [SETTING_PANEL_CAMERA] =
    {
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_INVERT_Y,
        },
		{
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_ASSASSINATION_CAMERA,
        },
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_CAMERA_SENSITIVITY,
        },
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_FIRST_PERSON_FIELD_OF_VIEW,
        },
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_FIRST_PERSON_HEAD_BOB,
        },
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW,
        },
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER,
        },
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_OFFSET,
        },
    },
    [SETTING_PANEL_GAMEPLAY] =
    {
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_GAMEPAD_TEMPLATE,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_VIBRATION,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_ENABLED,
            header = SI_AUDIO_OPTIONS_COMBAT,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_QUICK_CAST_GROUND_ABILITIES,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_HIDE_HELM,
            header = SI_GAMEPLAY_OPTIONS_ITEMS,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_HIDE_MOUNT_STAMINA_UPGRADE,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_HIDE_MOUNT_SPEED_UPGRADE,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_HIDE_MOUNT_INVENTORY_UPGRADE,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AOE_LOOT,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AUTO_LOOT,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AUTO_LOOT_STOLEN,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AUTO_ADD_TO_CRAFT_BAG,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_LOOT_HISTORY,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_DEFAULT_SOUL_GEM,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_TUTORIAL,
            settingId = TUTORIAL_ENABLED_SETTING_ID,
            header = SI_GAMEPLAY_OPTIONS_TUTORIALS,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_TUTORIAL,
            settingId = OPTIONS_CUSTOM_SETTING_RESET_TUTORIALS,
        },
    },
    [SETTING_PANEL_AUDIO] =
    {
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_SUBTITLES,
            settingId = SUBTITLE_SETTING_ENABLED,
            header = SI_GAMEPLAY_OPTIONS_SUBTITLES,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_AUDIO_VOLUME,
            header = SI_AUDIO_OPTIONS_GENERAL,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_MUSIC_ENABLED,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_MUSIC_VOLUME,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_SOUND_ENABLED,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_AMBIENT_VOLUME,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_SFX_VOLUME,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_UI_VOLUME,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_VO_VOLUME,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_FOOTSTEPS_VOLUME,
        },
    },
    [SETTING_PANEL_SOCIAL] =
    {
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_LANGUAGE,
            settingId = LANGUAGE_SETTING_USE_PROFANITY_FILTER,
        },

        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_LEADERBOARD_NOTIFICATIONS,
            header = SI_SOCIAL_OPTIONS_NOTIFICATIONS,
        },

        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_AUTO_DECLINE_DUEL_INVITES,
        },
    },
    [SETTING_PANEL_INTERFACE] =
    {
        --dynamically created
    },
    [SETTING_PANEL_NAMEPLATES] =
    {
        --Nameplates
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALL_NAMEPLATES,
            header = SI_INTERFACE_OPTIONS_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_SHOW_PLAYER_TITLES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_SHOW_PLAYER_GUILDS,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_PLAYER_NAMEPLATE,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_PLAYER_NAMEPLATE_HIGHLIGHT,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_MEMBER_NAMEPLATES_HIGHLIGHT,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_NAMEPLATES_HIGHLIGHT,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_NAMEPLATES_HIGHLIGHT,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_NAMEPLATES_HIGHLIGHT,
            panel = SETTING_PANEL_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_NPC_NAMEPLATES_HIGHLIGHT,
            panel = SETTING_PANEL_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES,
            panel = SETTING_PANEL_NAMEPLATES,
        },
        {
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_NAMEPLATES_HIGHLIGHT,
            panel = SETTING_PANEL_NAMEPLATES,
        },

        --Healthbars
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALL_HEALTHBARS,
            header = SI_INTERFACE_OPTIONS_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_HEALTHBAR_ALIGNMENT,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_HEALTHBAR_CHASE_BAR,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_HEALTHBAR_FRAME_BORDER,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_PLAYER_HEALTHBAR,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_PLAYER_HEALTHBAR_HIGHLIGHT,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_MEMBER_HEALTHBARS_HIGHLIGHT,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS_HIGHLIGHT,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS_HIGHLIGHT,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_NEUTRAL_NPC_HEALTHBARS_HIGHLIGHT,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS_HIGHLIGHT,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS_HIGHLIGHT,
        },

        --Indicators
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALLIANCE_INDICATORS,
            header = SI_INTERFACE_OPTIONS_INDICATORS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_INDICATORS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_RESURRECT_INDICATORS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FOLLOWER_INDICATORS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_GLOW_THICKNESS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_INTENSITY,
        },
    },
}

--Platform specific settings
if IsConsoleUI() then
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_AUDIO], {
        panel = SETTING_PANEL_AUDIO,
        system = SETTING_TYPE_AUDIO,
        settingId = AUDIO_SETTING_VOICE_CHAT_VOLUME,
    })
    if ZO_OptionsPanel_Video_HasConsoleRenderQualitySetting() then
        table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_VIDEO], 1, {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_CONSOLE_ENHANCED_RENDER_QUALITY,
        })
    end
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_VIDEO], {
        panel = SETTING_PANEL_VIDEO,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_SCREEN_ADJUST,
    })
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_SOCIAL], 1, {
        panel = SETTING_PANEL_SOCIAL,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_GAMEPAD_TEXT_SIZE,
        header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
    })
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_SOCIAL], 2, {
        panel = SETTING_PANEL_SOCIAL,
        system = SETTING_TYPE_UI,
        settingId = UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED,
    })
else
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_GAMEPLAY], 1, {
        panel = SETTING_PANEL_GAMEPLAY,
        system = SETTING_TYPE_GAMEPAD,
        settingId = GAMEPAD_SETTING_GAMEPAD_PREFERRED,
        header = SI_GAMEPAD_SECTION_HEADER,
    })
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_VIDEO], 1, {
        panel = SETTING_PANEL_VIDEO,
        system = SETTING_TYPE_GRAPHICS,
        settingId = GRAPHICS_SETTING_FULLSCREEN,
    })
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_VIDEO], 2, {
        panel = SETTING_PANEL_VIDEO,
        system = SETTING_TYPE_GRAPHICS,
        settingId = GRAPHICS_SETTING_RESOLUTION,
    })

    table.insert(interfaceSettingsChatBubbles, {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_SAY_ENABLED,
    })
    table.insert(interfaceSettingsChatBubbles, {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_YELL_ENABLED,
    })
    table.insert(interfaceSettingsChatBubbles, {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_WHISPER_ENABLED,
    })
    table.insert(interfaceSettingsChatBubbles, {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_GROUP_ENABLED,
    })
    table.insert(interfaceSettingsChatBubbles, {
        panel = SETTING_PANEL_INTERFACE,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_EMOTE_ENABLED,
    })
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_SOCIAL], 1, {
        panel = SETTING_PANEL_SOCIAL,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_MIN_ALPHA,
        header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
    })
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_SOCIAL], 2, {
        panel = SETTING_PANEL_SOCIAL,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_TEXT_SIZE,
    })
end

if IsSystemUsingHDR() then
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_VIDEO], {
        panel = SETTING_PANEL_VIDEO,
        system = SETTING_TYPE_GRAPHICS,
        settingId = GRAPHICS_SETTING_HDR_BRIGHTNESS,
    })
end

local function AddSettings(panel, settings)
    for _, entry in ipairs(settings) do
        table.insert(GAMEPAD_SETTINGS_DATA[panel], entry)
    end
end

AddSettings(SETTING_PANEL_INTERFACE, interfaceSettingsHUD)
AddSettings(SETTING_PANEL_INTERFACE, interfaceSettingsChatBubbles)
AddSettings(SETTING_PANEL_INTERFACE, interfaceSettingsScrollingCombatText)