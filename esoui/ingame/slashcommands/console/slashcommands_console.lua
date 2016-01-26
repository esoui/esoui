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
    -- This uses PC art / fonts.  Unsupported until those are updated.
end

SLASH_COMMANDS[GetString(SI_SLASH_LATENCY)] = function(txt)
    -- This uses PC art / fonts.  Unsupported until those are updated.
end

local function ShowConsoleHelpScreen()
    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "helpRootGamepad")
end

SLASH_COMMANDS[GetString(SI_SLASH_STUCK)] = function(txt)
    -- Bring up console unstuck dialog.
    -- Going to gamepad help root screen for all "help" functionality on console, OK-ed by design.
    ShowConsoleHelpScreen()
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_BUG)] = function(args) 
    -- Bring up console report bug dialog.
    ShowConsoleHelpScreen()
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_FEEDBACK)] = function(args) 
    -- Bring up console report feedback dialog.
    ShowConsoleHelpScreen()
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_HELP)] = function(args) 
    ShowConsoleHelpScreen()
end

SLASH_COMMANDS[GetString(SI_SLASH_REPORT_CHAT)] = function(args) 
    -- Bring up console agent chat dialog.
    ShowConsoleHelpScreen()
end