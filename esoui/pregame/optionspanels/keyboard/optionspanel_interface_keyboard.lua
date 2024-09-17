local panelBuilder = ZO_KeyboardOptionsPanelBuilder:New(SETTING_PANEL_INTERFACE)

----------------------
-- Interface -> HUD --
----------------------
panelBuilder:AddSetting({
    controlName = "Options_Interface_TextLanguageKeyboard",
    settingType = SETTING_TYPE_UI,
    settingId = UI_SETTING_TEXT_LANGUAGE,
    header = SI_INTERFACE_OPTIONS_LANGUAGE,
})
