local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_VIDEO)

----------------------
-- Video -> Display --
----------------------
panelBuilder:AddSetting({
    controlName = "Options_Video_DisplayMode",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_FULLSCREEN,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
    initializeControlFunction = function(control)
        ZO_OptionsWindow_InitializeControl(control)
        EVENT_MANAGER:RegisterForEvent("ZO_OptionsPanel_Video", EVENT_FULLSCREEN_MODE_CHANGED, function()
            ZO_Options_UpdateOption(control)
        end)
    end,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_ActiveDisplay",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_ACTIVE_DISPLAY,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
    initializeControlFunction = function(control)
        ZO_OptionsPanel_Video_InitializeDisplays(control)
        EVENT_MANAGER:RegisterForEvent("ZO_OptionsPanel_Video", EVENT_AVAILABLE_DISPLAY_DEVICES_CHANGED, function()
            ZO_OptionsPanel_Video_OnActiveDisplayChanged(control)
        end)
    end,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Resolution",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_RESOLUTION,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
    initializeControlFunction = function(control)
        ZO_OptionsPanel_Video_InitializeResolution(control)
        EVENT_MANAGER:RegisterForEvent("ZO_OptionsPanel_Video", EVENT_ACTIVE_DISPLAY_CHANGED, function()
            ZO_OptionsPanel_Video_OnDisplayResolutionChanged(control)
        end)
    end,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_VSync",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_VSYNC,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_RenderThread",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_RENDERTHREAD,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
    template = "ZO_Options_Video_Checkbox_IncludeRestartWarning",
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Use_Background_FPS_Limit",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_USE_BACKGROUND_FPS_LIMIT,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
}) 

panelBuilder:AddSetting({
    controlName = "Options_Video_Background_FPS_Limit",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_BACKGROUND_FPS_LIMIT,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

-- inline slider
panelBuilder:AddSetting({
    controlName = "Options_Video_Gamma_Adjustment",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_GAMMA_ADJUSTMENT,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

-- button to go to gamma adjustment screen
panelBuilder:AddSetting({
    controlName = "Options_Video_CalibrateGamma",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_GAMMA_ADJUST,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_HDR_Enabled",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_HDR_ENABLED,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
    template = "ZO_Options_Video_Checkbox_IncludeRestartWarning",
})

panelBuilder:AddSetting({
    controlName = "Options_Video_HDR_Peak_Brightness",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_HDR_PEAK_BRIGHTNESS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_HDR_Scene_Brightness",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_HDR_SCENE_BRIGHTNESS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_HDR_Scene_Contrast",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_HDR_SCENE_CONTRAST,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_HDR_UI_Brightness",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_HDR_UI_BRIGHTNESS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_HDR_UI_Contrast",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_HDR_UI_CONTRAST,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_HDR_Mode",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_HDR_MODE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_ScreenAdjust",
    settingType = SETTING_TYPE_CUSTOM,
    settingId = OPTIONS_CUSTOM_SETTING_SCREEN_ADJUST,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_DISPLAY,
})

------------------------
-- Video -> Interface --
------------------------
panelBuilder:AddSetting({
    controlName = "Options_Video_UseCustomScale",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_USE_CUSTOM_SCALE,
    header = SI_VIDEO_OPTIONS_INTERFACE,
    template = "ZO_Options_Checkbox_DynamicWarning",
})

panelBuilder:AddSetting({
    controlName = "Options_Video_CustomScale",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_CUSTOM_SCALE,
    header = SI_VIDEO_OPTIONS_INTERFACE,
    indentLevel = 1,
    template = "ZO_Options_Video_Slider_DynamicWarning",
})

------------------------
-- Video -> Graphics  --
------------------------
panelBuilder:AddSetting({
    controlName = "Options_Video_Graphics_Quality",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_PRESETS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    template = "ZO_Options_Video_Dropdown_IncludeApplyScreenWarning",
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Texture_Resolution",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_MIP_LOAD_SKIP_LEVELS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    template = "ZO_Options_Video_Dropdown_IncludeApplyScreenWarning",
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_AntiAliasing_Type",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_ANTIALIASING_TYPE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_DLSS_Mode",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_DLSS_MODE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_FSR_Mode",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_FSR_MODE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Sub_Sampling",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_SUB_SAMPLING,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Shadows",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_SHADOWS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    template = "ZO_Options_Video_Dropdown_IncludeApplyScreenWarning",
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Screenspace_Water_Reflection_Quality",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_SCREENSPACE_WATER_REFLECTION_QUALITY,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    template = "ZO_Options_Video_Dropdown_IncludeApplyScreenWarning",
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Planar_Water_Reflection_Quality",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_PLANAR_WATER_REFLECTION_QUALITY,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    template = "ZO_Options_Video_Dropdown_IncludeApplyScreenWarning",
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Maximum_Particle_Systems",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_PFX_GLOBAL_MAXIMUM,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
    template = "ZO_Options_Video_Slider_IncludeMaxParticleSystemsWarning",
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Particle_Suppression_Distance",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_PFX_SUPPRESS_DISTANCE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_View_Distance",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_VIEW_DISTANCE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Ambient_Occlusion",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_AMBIENT_OCCLUSION_TYPE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    template = "ZO_Options_Video_Dropdown_IncludeApplyScreenWarning",
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Occlusion_Culling_Enabled",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_OCCLUSION_CULLING_ENABLED,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    template = "ZO_Options_Video_Checkbox_IncludeApplyScreenWarning",
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Clutter_2D_Quality",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_CLUTTER_2D_QUALITY,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Depth_Of_Field_Mode",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_DEPTH_OF_FIELD_MODE,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Character_Resolution",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_CHARACTER_RESOLUTION,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Bloom",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_BLOOM,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Distortion",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_DISTORTION,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_God_Rays",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_GOD_RAYS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})

panelBuilder:AddSetting({
    controlName = "Options_Video_Show_Additional_Ally_Effects",
    settingType = SETTING_TYPE_GRAPHICS,
    settingId = GRAPHICS_SETTING_SHOW_ADDITIONAL_ALLY_EFFECTS,
    header = SI_GRAPHICS_OPTIONS_VIDEO_CATEGORY_GRAPHICS,
    indentLevel = 1,
})
