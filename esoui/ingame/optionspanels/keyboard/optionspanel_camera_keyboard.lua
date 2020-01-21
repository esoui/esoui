local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_CAMERA)

----------------------
-- Camera -> Global --
----------------------
panelBuilder:AddSetting({
    controlName = "Options_Camera_Smoothing",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_SMOOTHING,
    header = SI_CAMERA_OPTIONS_GLOBAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_InvertY",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_INVERT_Y,
    header = SI_CAMERA_OPTIONS_GLOBAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_FOVChangesAllowed",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_FOV_CHANGES_ALLOWED,
    header = SI_CAMERA_OPTIONS_GLOBAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_AssassinationCamera",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_ASSASSINATION_CAMERA,
    header = SI_CAMERA_OPTIONS_GLOBAL,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_ScreenShake",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_SCREEN_SHAKE,
    header = SI_CAMERA_OPTIONS_GLOBAL,
})

----------------------------
-- Camera -> First Person --
----------------------------
panelBuilder:AddSetting({
    controlName = "Options_Camera_CameraSensitivityFirstPerson",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_SENSITIVITY_FIRST_PERSON,
    header = SI_CAMERA_OPTIONS_FIRST_PERSON,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_FirstPersonFieldOfView",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_FIRST_PERSON_FIELD_OF_VIEW,
    header = SI_CAMERA_OPTIONS_FIRST_PERSON,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_FirstPersonHeadBob",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_FIRST_PERSON_HEAD_BOB,
    header = SI_CAMERA_OPTIONS_FIRST_PERSON,
})

----------------------------
-- Camera -> Third Person --
----------------------------
panelBuilder:AddSetting({
    controlName = "Options_Camera_CameraSensitivityThirdPerson",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_SENSITIVITY_THIRD_PERSON,
    header = SI_CAMERA_OPTIONS_THIRD_PERSON,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_ThirdPersonFieldOfView",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW,
    header = SI_CAMERA_OPTIONS_THIRD_PERSON,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_ThirdPersonHorizontalPositionMutliplier",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER,
    header = SI_CAMERA_OPTIONS_THIRD_PERSON,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_ThirdPersonHorizontalOffset",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_OFFSET,
    header = SI_CAMERA_OPTIONS_THIRD_PERSON,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_ThirdPersonVerticalOffset",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_THIRD_PERSON_VERTICAL_OFFSET,
    header = SI_CAMERA_OPTIONS_THIRD_PERSON,
})

panelBuilder:AddSetting({
    controlName = "Options_Camera_SiegeWeaponry",
    settingType = SETTING_TYPE_CAMERA,
    settingId = CAMERA_SETTING_THIRD_PERSON_SIEGE_WEAPONRY,
    header = SI_CAMERA_OPTIONS_THIRD_PERSON,
})
