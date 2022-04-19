local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_AUDIO)

------------------------
-- Audio -> Subtitles --
------------------------
panelBuilder:AddSetting({
    controlName = "Options_Audio_SubtitlesEnabledForNPCs",
    settingType = SETTING_TYPE_SUBTITLES,
    settingId = SUBTITLE_SETTING_ENABLED_FOR_NPCS,
    header = SI_AUDIO_OPTIONS_SUBTITLES,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_SubtitlesEnabledForVideos",
    settingType = SETTING_TYPE_SUBTITLES,
    settingId = SUBTITLE_SETTING_ENABLED_FOR_VIDEOS,
    header = SI_AUDIO_OPTIONS_SUBTITLES,
})

----------------------
-- Audio -> General --
----------------------
panelBuilder:AddSetting({
    controlName = "Options_Audio_MasterVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_AUDIO_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_MusicEnabled",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_MUSIC_ENABLED,
    header = SI_AUDIO_OPTIONS_GENERAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_MusicVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_MUSIC_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_IntroMusic",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_INTRO_MUSIC,
    header = SI_AUDIO_OPTIONS_GENERAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_SoundEnabled",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_SOUND_ENABLED,
    header = SI_AUDIO_OPTIONS_GENERAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_AmbientVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_AMBIENT_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_SFXVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_SFX_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_FootstepsVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_FOOTSTEPS_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_VOVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_VO_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_UISoundVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_UI_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_VideoSoundVolume",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_VIDEO_VOLUME,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Audio_CombatMusicMode",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_COMBAT_MUSIC_MODE,
    header = SI_AUDIO_OPTIONS_GENERAL,
    indentLevel = 1,
})

----------------------
-- Audio -> Output  --
----------------------
panelBuilder:AddSetting({
    controlName = "Options_Audio_BackgroundAudio",
    settingType = SETTING_TYPE_AUDIO,
    settingId = AUDIO_SETTING_BACKGROUND_AUDIO,
    header = SI_AUDIO_OPTIONS_OUTPUT,
})
