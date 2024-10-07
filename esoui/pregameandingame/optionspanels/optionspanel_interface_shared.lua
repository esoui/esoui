local ZO_OptionsPanel_Interface_ControlData =
{
    --UI Settings
    [SETTING_TYPE_UI] =
    {
        [UI_SETTING_TEXT_LANGUAGE] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_INTERFACE,
            settingId = UI_SETTING_TEXT_LANGUAGE,
            text = SI_INTERFACE_OPTIONS_TEXT_LANGUAGE,
            tooltipText = SI_INTERFACE_OPTIONS_TEXT_LANGUAGE_TOOLTIP,
            valid = function()
                local validValues = {}
                for i = OFFICIAL_LANGUAGE_ITERATION_BEGIN, OFFICIAL_LANGUAGE_ITERATION_END do
                    if ZoIsOfficialLanguageSupported(i) then
                        table.insert(validValues, i)
                    end
                end
                return validValues
            end,
            valueStrings = function()
                local valueStrings = {}
                for i = OFFICIAL_LANGUAGE_ITERATION_BEGIN, OFFICIAL_LANGUAGE_ITERATION_END do
                    if ZoIsOfficialLanguageSupported(i) then
                        table.insert(valueStrings, function() return GetString("SI_OFFICIALLANGUAGE", i) end)
                    end
                end
                return valueStrings
            end,
            mustPushApply = true,
        },
    },
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_INTERFACE, ZO_OptionsPanel_Interface_ControlData)