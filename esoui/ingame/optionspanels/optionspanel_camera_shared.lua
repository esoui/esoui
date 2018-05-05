local ZO_OptionsPanel_Camera_ControlData =
{
    --Camera
    [SETTING_TYPE_CAMERA] =
    {
        --Options_Camera_Smoothing
        [CAMERA_SETTING_SMOOTHING] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_SMOOTHING,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_SMOOTHING,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_SMOOTHING_TOOLTIP,
        },
        --Options_Camera_InvertY
        [CAMERA_SETTING_INVERT_Y] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_INVERT_Y,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_INVERT_Y,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_INVERT_Y_TOOLTIP,
        },
        --Options_Camera_FOVChangesAllowed
        [CAMERA_SETTING_FOV_CHANGES_ALLOWED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_FOV_CHANGES_ALLOWED,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_FOV_CHANGES,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_FOV_CHANGES_TOOLTIP,
        },
		--Options_Camera_AssassinationCamera
        [CAMERA_SETTING_ASSASSINATION_CAMERA] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_ASSASSINATION_CAMERA,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_ASSASSINATION_CAMERA,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_ASSASSINATION_CAMERA_TOOLTIP,
        },
        --Options_Camera_ScreenShake
        [CAMERA_SETTING_SCREEN_SHAKE] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_SCREEN_SHAKE,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_SCREEN_SHAKE,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_SCREEN_SHAKE_TOOLTIP,
            minValue = 0.0,
            maxValue = 1.0,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 100,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Camera_CameraSensitivityFirstPerson
        [CAMERA_SETTING_SENSITIVITY_FIRST_PERSON] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_SENSITIVITY_FIRST_PERSON,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_SENSITIVITY_FIRST_PERSON,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_SENSITIVITY_FIRST_PERSON_TOOLTIP,
            minValue = 0.1,
            maxValue = 1.6,
            valueFormat = "%.2f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Camera_FirstPersonFieldOfView
        [CAMERA_SETTING_FIRST_PERSON_FIELD_OF_VIEW] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_FIRST_PERSON_FIELD_OF_VIEW,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_FIRST_PERSON_FOV,
            gamepadTextOverride = SI_GAMEPAD_OPTIONS_CAMERA_FIRST_PERSON_FOV,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_FIRST_PERSON_FOV_TOOLTIP,
            minValue = 35,
            maxValue = 65,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 50,
            showValueMin = 70,
            showValueMax = 130,
        },
        --Options_Camera_FirstPersonHeadBob
        [CAMERA_SETTING_FIRST_PERSON_HEAD_BOB] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_FIRST_PERSON_HEAD_BOB,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_FIRST_PERSON_BOB,
            gamepadTextOverride = SI_GAMEPAD_OPTIONS_CAMERA_FIRST_PERSON_BOB,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_FIRST_PERSON_BOB_TOOLTIP,
            minValue = 0.0,
            maxValue = 1.0,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 100,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Camera_CameraSensitivityThirdPerson
        [CAMERA_SETTING_SENSITIVITY_THIRD_PERSON] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_SENSITIVITY_THIRD_PERSON,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_SENSITIVITY_THIRD_PERSON,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_SENSITIVITY_THIRD_PERSON_TOOLTIP,
            minValue = 0.1,
            maxValue = 1.6,
            valueFormat = "%.2f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Camera_ThirdPersonHorizontalPositionMutliplier
        [CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER_TOOLTIP,
            minValue = -1.0,
            maxValue = 1.0,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 100,
            showValueMin = -100,
            showValueMax = 100,
        },
        --Options_Camera_ThirdPersonHorizontalOffset
        [CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_OFFSET] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_OFFSET,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_HORIZONTAL_OFFSET,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_HORIZONTAL_OFFSET_TOOLTIP,
            minValue = -1.0,
            maxValue = 1.0,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 0,
            showValueMin = -100,
            showValueMax = 100,
        },
        --Options_Camera_ThirdPersonVerticalOffset
        [CAMERA_SETTING_THIRD_PERSON_VERTICAL_OFFSET] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_VERTICAL_OFFSET,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_VERTICAL_OFFSET,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_VERTICAL_OFFSET_TOOLTIP,
            minValue = -0.3,
            maxValue = 0.5,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 0,
            showValueMin = -60,
            showValueMax = 100,
        },
        --Options_Camera_ThirdPersonFieldOfView
        [CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW,
            panel = SETTING_PANEL_CAMERA,
            text = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_FOV,
            gamepadTextOverride = SI_GAMEPAD_OPTIONS_CAMERA_THIRD_PERSON_FOV,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_FOV_TOOLTIP,
            minValue = 35,
            maxValue = 65,
            valueFormat = "%.2f",
            showValue = true,
            defaultMarker = 50, -- should match default from InterfaceSettingObject_Camera.cpp
            showValueMin = 70,
            showValueMax = 130,
        },
        --Options_Camera_ThirdPersonSiegeWeaponry
        [CAMERA_SETTING_THIRD_PERSON_SIEGE_WEAPONRY] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_CAMERA,
            panel = SETTING_PANEL_CAMERA,
            settingId = CAMERA_SETTING_THIRD_PERSON_SIEGE_WEAPONRY,
            text = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_SIEGE_WEAPONRY,
            tooltipText = SI_INTERFACE_OPTIONS_CAMERA_THIRD_PERSON_SIEGE_WEAPONRY_TOOLTIP,
            valid = {SIEGE_CAMERA_CHOICE_FREE, SIEGE_CAMERA_CHOICE_CONSTRAINED,},
            valueStringPrefix = "SI_SIEGECAMERACHOICE",
        },
    },
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_CAMERA, ZO_OptionsPanel_Camera_ControlData)