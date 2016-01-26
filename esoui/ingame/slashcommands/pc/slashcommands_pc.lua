local function DoLogout()
	if IsFeedbackGatheringEnabled() then
		ZO_FEEDBACK:Logout(false)
	else 
	    Logout()
	end
end

SLASH_COMMANDS[GetString(SI_SLASH_LOGOUT)] = function (txt)
    DoLogout()
end

SLASH_COMMANDS[GetString(SI_SLASH_CAMP)] = function (txt)
	DoLogout()
end

SLASH_COMMANDS[GetString(SI_SLASH_QUIT)] = function (txt)
	if IsFeedbackGatheringEnabled() then
		ZO_FEEDBACK:Logout(true)
	else 
		Quit()
	end
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

SLASH_COMMANDS[GetString(SI_SLASH_STUCK)] = function(txt)
    STUCK:ShowConfirmDialog()
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_BUG)] = function(args) 
    ZO_FEEDBACK:OpenBrowserByType(BROWSER_TYPE_BUG)
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_FEEDBACK)] = function(args) 
    ZO_FEEDBACK:OpenBrowserByType(BROWSER_TYPE_USER_FEEDBACK)
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_HELP)] = function(args) 
    ZO_FEEDBACK:OpenBrowserByType(BROWSER_TYPE_USER_HELP)
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_CHAT)] = function(args) 
    ZO_FEEDBACK:OpenBrowserByType(BROWSER_TYPE_USER_CHAT)
end