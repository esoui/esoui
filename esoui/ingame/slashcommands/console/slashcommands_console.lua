local function DoLogout()
	Logout()
end

SLASH_COMMANDS[GetString(SI_SLASH_LOGOUT)] = function (txt)
    DoLogout()
end

SLASH_COMMANDS[GetString(SI_SLASH_CAMP)] = function (txt)
	DoLogout()
end

SLASH_COMMANDS[GetString(SI_SLASH_STUCK)] = function(txt)
    -- Bring up console unstuck dialog.
    -- Going to gamepad help root screen for all "help" functionality on console, OK-ed by design.
    ShowGamepadHelpScreen()
end

if IsSubmitFeedbackSupported() then
    SLASH_COMMANDS[GetString(SI_SLASH_REPORT_BUG)] = function(args) 
        -- Bring up console report bug dialog.
        ShowGamepadHelpScreen()
    end

    SLASH_COMMANDS[GetString(SI_SLASH_REPORT_FEEDBACK)] = function(args) 
        -- Bring up console report feedback dialog.
        ShowGamepadHelpScreen()
    end
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_HELP)] = function(args) 
    ShowGamepadHelpScreen()
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_CHAT)] = function(args) 
    -- Bring up console agent chat dialog.
    ShowGamepadHelpScreen()
end