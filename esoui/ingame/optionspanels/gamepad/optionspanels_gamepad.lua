--Ingame Options table

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
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_CAMERA_SENSITIVITY,
        },
        {
            panel = SETTING_PANEL_CAMERA,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW,
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
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_LEADERBOARD_NOTIFICATIONS,
        },
    },
    [SETTING_PANEL_INTERFACE] =
    {
        --Heads-up display--
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_ACTION_BAR,
            header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
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
        --Healthbars--
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALL_HEALTHBARS,
            header = SI_INTERFACE_OPTIONS_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_PLAYER_HEALTHBAR,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS,
        },
        --Chat Bubbles / Quick Chat--
        -- TODO: Change header based on platform
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_CHAT_BUBBLE,
            settingId = CHAT_BUBBLE_SETTING_ENABLED,
            header = SI_INTERFACE_OPTIONS_QUICK_CHAT,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_CHAT_BUBBLE,
            settingId = CHAT_BUBBLE_SETTING_SPEED_MODIFIER,
        },
        --Indicators--
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALLIANCE_INDICATORS,
            header = SI_INTERFACE_OPTIONS_INDICATORS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_INDICATORS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_RESURRECT_INDICATORS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FOLLOWER_INDICATORS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_GLOW_THICKNESS,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_INTENSITY,
        },
    }
}

--platform specific settings
if IsConsoleUI() then
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_AUDIO], {
        panel = SETTING_PANEL_AUDIO,
        system = SETTING_TYPE_AUDIO,
        settingId = AUDIO_SETTING_VOICE_CHAT_VOLUME,
    })
    table.insert(GAMEPAD_SETTINGS_DATA[SETTING_PANEL_VIDEO], {
        panel = SETTING_PANEL_VIDEO,
        system = SETTING_TYPE_CUSTOM,
        settingId = OPTIONS_CUSTOM_SETTING_SCREEN_ADJUST,
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
end