local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_GAMEPLAY)

-------------------------
-- Gameplay -> Gamepad --
-------------------------

panelBuilder:AddSetting({
    controlName = "Options_Gameplay_InputPreferredMode",
    settingType = SETTING_TYPE_GAMEPAD,
    settingId = GAMEPAD_SETTING_INPUT_PREFERRED_MODE,
    header = SI_GAMEPAD_SECTION_HEADER,
    template = "ZO_Options_Dropdown_DynamicWarning",
})

panelBuilder:AddSetting({
    controlName = "Options_Gameplay_KeybindDisplayMode",
    settingType = SETTING_TYPE_GAMEPAD,
    settingId = GAMEPAD_SETTING_KEYBIND_DISPLAY_MODE,
    header = SI_GAMEPAD_SECTION_HEADER,
    indentLevel = 1,
    template = "ZO_Options_Dropdown_DynamicWarning",
})

panelBuilder:AddSetting({
    controlName = "Options_Gameplay_UseKeyboardLogin",
    settingType = SETTING_TYPE_GAMEPAD,
    settingId = GAMEPAD_SETTING_USE_KEYBOARD_LOGIN,
    header = SI_GAMEPAD_SECTION_HEADER,
    indentLevel = 1,
    template = "ZO_Options_Checkbox_DynamicWarning",
})