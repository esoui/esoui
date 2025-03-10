--Ingame Options table

local function Chat_Color_GetGuildText(data)
    local guildID = GetGuildId(data.guildIndex)
    local guildName = GetGuildName(guildID)

    if guildName ~= "" then
        return guildName
    else
        return zo_strformat(SI_EMPTY_GUILD_CHANNEL_NAME, data.guildIndex)
    end
end

GAMEPAD_SETTINGS_DATA =
{
    [SETTING_PANEL_VIDEO] =
    {
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_CONSOLE_ENHANCED_RENDER_QUALITY,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_GRAPHICS_MODE_PS5,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_GRAPHICS_MODE_XBSS,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_GRAPHICS_MODE_XBSX,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_FULLSCREEN,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_ACTIVE_DISPLAY,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_RESOLUTION,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_VSYNC,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_RENDERTHREAD,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_GAMMA_ADJUST,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SCREEN_ADJUST,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_USE_GAMEPAD_CUSTOM_SCALE,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_GAMEPAD_CUSTOM_SCALE,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SCREENSHOT_MODE,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_HDR_PEAK_BRIGHTNESS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_HDR_SCENE_BRIGHTNESS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_HDR_SCENE_CONTRAST,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_HDR_UI_BRIGHTNESS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_HDR_UI_CONTRAST,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_HDR_MODE,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_PRESETS,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_MIP_LOAD_SKIP_LEVELS,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_ANTIALIASING_TYPE,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_DLSS_MODE,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_FSR_MODE,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_SUB_SAMPLING,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_SHADOWS,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_SCREENSPACE_WATER_REFLECTION_QUALITY,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_PLANAR_WATER_REFLECTION_QUALITY,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_PFX_GLOBAL_MAXIMUM,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_PFX_SUPPRESS_DISTANCE,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_VIEW_DISTANCE,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_AMBIENT_OCCLUSION_TYPE,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_OCCLUSION_CULLING_ENABLED,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_CLUTTER_2D_QUALITY,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_DEPTH_OF_FIELD_MODE,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_CHARACTER_RESOLUTION,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_BLOOM,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_DISTORTION,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_GOD_RAYS,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
        },
        {
            panel = SETTING_PANEL_VIDEO,
            system = SETTING_TYPE_GRAPHICS,
            settingId = GRAPHICS_SETTING_SHOW_ADDITIONAL_ALLY_EFFECTS,
            header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
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
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_SCREEN_SHAKE,
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
            settingId = GAMEPAD_SETTING_INPUT_PREFERRED_MODE,
            header = SI_GAMEPAD_SECTION_HEADER,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_KEYBIND_DISPLAY_MODE,
            header = SI_GAMEPAD_SECTION_HEADER,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_USE_KEYBOARD_CHAT,
            header = SI_GAMEPAD_SECTION_HEADER,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_USE_KEYBOARD_LOGIN,
            header = SI_GAMEPAD_SECTION_HEADER,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_GAMEPAD_TEMPLATE,
            header = SI_GAMEPAD_SECTION_HEADER,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_GAMEPAD,
            settingId = GAMEPAD_SETTING_VIBRATION,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_RESET_GAMEPAD_CONTROLS,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_FOOT_INVERSE_KINEMATICS,
            header = SI_GAMEPLAY_OPTIONS_GENERAL,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_HIDE_POLYMORPH_HELM,
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
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_LIMIT_FOLLOWERS_IN_TOWNS,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_COMPANION_REACTION_FREQUENCY,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_COMPANION_PASSENGER_PREFERENCE,
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
            settingId = COMBAT_SETTING_MONSTER_TELLS_COLOR_SWAP_ENABLED,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_COLOR,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_BRIGHTNESS,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_MONSTER_TELLS_FRIENDLY_TEST,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_ENEMY_COLOR,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_ENEMY_BRIGHTNESS,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_MONSTER_TELLS_ENEMY_TEST,
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
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_ALLOW_COMPANION_AUTO_ULTIMATE,
        },
        {
            panel = SETTING_PANEL_GAMEPLAY,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AOE_LOOT,
            header = SI_GAMEPLAY_OPTIONS_ITEMS,
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
            settingId = LOOT_SETTING_PREVENT_STEALING_PLACED,
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
    [SETTING_PANEL_ACCESSIBILITY] =
    {
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_VOICE_CHAT_ACCESSIBILITY,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_ZONE_CHAT_NARRATION,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_SCREEN_NARRATION,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_TEXT_INPUT_NARRATION,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_NARRATION_VOLUME,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_NARRATION_VOICE_SPEED,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_NARRATION_VOICE_TYPE,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_ACCESSIBLE_QUICKWHEELS,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_PLAYER_WAYPOINT_ICON_COLOR,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_GAMEPAD_AIM_ASSIST_INTENSITY,
            header = SI_ACCESSIBILITY_OPTIONS_ARCANIST,
        },
        {
            panel = SETTING_PANEL_ACCESSIBILITY,
            system = SETTING_TYPE_ACCESSIBILITY,
            settingId = ACCESSIBILITY_SETTING_MOUSE_AIM_ASSIST_INTENSITY,
            header = SI_ACCESSIBILITY_OPTIONS_ARCANIST,
        },
    },
    [SETTING_PANEL_AUDIO] =
    {
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_SUBTITLES,
            settingId = SUBTITLE_SETTING_ENABLED_FOR_NPCS,
            header = SI_AUDIO_OPTIONS_SUBTITLES,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_SUBTITLES,
            settingId = SUBTITLE_SETTING_ENABLED_FOR_VIDEOS,
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
            settingId = AUDIO_SETTING_INTRO_MUSIC,
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
            settingId = AUDIO_SETTING_VIDEO_VOLUME,
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
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_VOICE_CHAT_VOLUME,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_COMBAT_MUSIC_MODE,
        },
        {
            panel = SETTING_PANEL_AUDIO,
            system = SETTING_TYPE_AUDIO,
            settingId = AUDIO_SETTING_BACKGROUND_AUDIO,
            header = SI_AUDIO_OPTIONS_OUTPUT,
        },
    },
    [SETTING_PANEL_SOCIAL] =
    {
        -- settings for the GamepadChatSystem
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_GAMEPAD_TEXT_SIZE,
            header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_GAMEPAD_CHAT_HUD_ENABLED,
            header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
        },
        -- Settings for the KeyboardChatSystem
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_MIN_ALPHA,
            header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_TEXT_SIZE,
            header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
        },
        -- Shared settings
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_LANGUAGE,
            settingId = LANGUAGE_SETTING_USE_PROFANITY_FILTER,
            header = SI_SOCIAL_OPTIONS_CHAT_SETTINGS,
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
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_AUTO_DECLINE_TRIBUTE_INVITES,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_AVA_NOTIFICATIONS,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_GUILD_KEEP_NOTICES,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_PVP_KILL_FEED_NOTIFICATIONS,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_SAY,
            header = SI_SOCIAL_OPTIONS_CHAT_COLORS,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_YELL,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_WHISPER_INC,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_WHISPER_OUT,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GROUP,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_ENG,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_FRA,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_GER,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_JPN,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_RUS,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_SPA,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_SCN,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_NPC,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_EMOTE,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_SYSTEM,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD1,
            header = Chat_Color_GetGuildText,
            guildIndex = 1,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER1,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD2,
            header = Chat_Color_GetGuildText,
            guildIndex = 2,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER2,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD3,
            header = Chat_Color_GetGuildText,
            guildIndex = 3,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER3,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD4,
            header = Chat_Color_GetGuildText,
            guildIndex = 4,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER4,
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD5,
            header = Chat_Color_GetGuildText,
            guildIndex = 5
        },
        {
            panel = SETTING_PANEL_SOCIAL,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER5,
        },
    },
    [SETTING_PANEL_INTERFACE] =
    {
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_TEXT_LANGUAGE,
            header = SI_INTERFACE_OPTIONS_LANGUAGE,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_PRIMARY_PLAYER_NAME_GAMEPAD,
            header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_RAID_LIVES,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_HOUSE_TRACKER,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_QUEST_TRACKER,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_AUTOMATIC_QUEST_TRACKING,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS,
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
            settingId = UI_SETTING_COMPASS_COMPANION,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_COMPASS_TARGET_MARKERS,
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
        -- shared chat bubbles
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
        -- non-console chat bubbles
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_SAY_ENABLED,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_YELL_ENABLED,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_WHISPER_ENABLED,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_GROUP_ENABLED,
        },
        {
            panel = SETTING_PANEL_INTERFACE,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_EMOTE_ENABLED,
        },
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
            settingId = NAMEPLATE_TYPE_TARGET_MARKERS,
        },
        {
            panel = SETTING_PANEL_NAMEPLATES,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_TARGET_MARKER_SIZE,
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
    [SETTING_PANEL_COMBAT] =
    {
        -- Hud Settings
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_ACTION_BAR,
            header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_ACTION_BAR_TIMERS,
            header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_ACTION_BAR_BACK_ROW,
            header = SI_INTERFACE_OPTIONS_HEADS_UP_DISPLAY,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_RESOURCE_BARS,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_RESOURCE_NUMBERS,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_ACTIVE_COMBAT_TIP,
            settingId = 0, -- TODO: make an enum for this, or merge it with another setting type
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_ULTIMATE_NUMBER,
        },

        -- Encounter log
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_ENCOUNTER_LOG_APPEAR_ANONYMOUS,
            header = SI_INTERFACE_OPTIONS_ENCOUNTER_LOG,
        },

        -- SCT
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCROLLING_COMBAT_TEXT_ENABLED,
            header = SI_INTERFACE_OPTIONS_SCT,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_DAMAGE_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_DOT_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_HEALING_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_HOT_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_STATUS_EFFECTS_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_PET_DAMAGE_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_PET_DOT_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_PET_HEALING_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_PET_HOT_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_DAMAGE_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_DOT_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_HEALING_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_HOT_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_STATUS_EFFECTS_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_PET_DAMAGE_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_PET_DOT_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_SHOW_OVER_HEAL,
        },

        -- Buff Debuff
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_ALL_ENABLED,
            header = SI_BUFFS_OPTIONS_SECTION_TITLE,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_BUFFS_ENABLED,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_BUFFS_ENABLED_FOR_SELF,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_SELF,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_LONG_EFFECTS,
        },
        {
            panel = SETTING_PANEL_COMBAT,
            system = SETTING_TYPE_BUFFS,
            settingId = BUFFS_SETTING_PERMANENT_EFFECTS,
        },
    },
    [SETTING_PANEL_ACCOUNT] =
    {
        -- Email Address
        {
            panel = SETTING_PANEL_ACCOUNT,
            system = SETTING_TYPE_ACCOUNT,
            settingId = ACCOUNT_SETTING_ACCOUNT_EMAIL,
            header = SI_INTERFACE_OPTIONS_ACCOUNT_EMAIL_HEADER,
        },
        {
            panel = SETTING_PANEL_ACCOUNT,
            system = SETTING_TYPE_CUSTOM,
            settingId = OPTIONS_CUSTOM_SETTING_RESEND_EMAIL_ACTIVATION,
            header = SI_INTERFACE_OPTIONS_ACCOUNT_EMAIL_HEADER,
        },
        -- Marketing Preferences
        {
            panel = SETTING_PANEL_ACCOUNT,
            system = SETTING_TYPE_ACCOUNT,
            settingId = ACCOUNT_SETTING_GET_UPDATES,
            header = SI_INTERFACE_OPTIONS_ACCOUNT_MARKETING_HEADER,
        },
    },
}
