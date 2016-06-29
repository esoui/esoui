local function DoLogout()
	Logout()
end

SLASH_COMMANDS[GetString(SI_SLASH_LOGOUT)] = function (txt)
    DoLogout()
end

SLASH_COMMANDS[GetString(SI_SLASH_CAMP)] = function (txt)
	DoLogout()
end

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

SLASH_COMMANDS[GetString(SI_SLASH_STUCK)] = function(txt)
	if IsInGamepadPreferredMode() then
		ShowGamepadHelpScreen()
	else
		HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD_FRAGMENT)
	end
end

if IsSubmitFeedbackSupported() then
    SLASH_COMMANDS[GetString(SI_SLASH_REPORT_BUG)] = function(args)
	    if IsInGamepadPreferredMode() then
		    ShowGamepadHelpScreen()
	    else
		    HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD_FRAGMENT)
	    end
    end

    SLASH_COMMANDS[GetString(SI_SLASH_REPORT_FEEDBACK)] = function(args)
	    if IsInGamepadPreferredMode() then
		    ShowGamepadHelpScreen()
	    else
		    HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD_FRAGMENT)
		    HELP_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_KEYBOARD:ClearFields()
	    end
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_HELP)] = function(args)
	if IsInGamepadPreferredMode() then
		ShowGamepadHelpScreen()
	else
		HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:OpenAskForHelp()
	end
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_CHAT)] = function(args)
	if IsInGamepadPreferredMode() then
		ShowGamepadHelpScreen()
	else
		HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:OpenAskForHelp(CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HARASSMENT)
	end
end
