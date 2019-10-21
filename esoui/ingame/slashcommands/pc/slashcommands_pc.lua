SLASH_COMMANDS[GetString(SI_SLASH_QUIT)] = function (txt)
    Quit()
end

SLASH_COMMANDS[GetString(SI_SLASH_FPS)] = function(txt)
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE) then
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE, "false")
    else
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE, "true")
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_LATENCY)] = function(txt)
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY) then
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY, "false")
    else
        SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY, "true")
    end
end
