--------------------------------------------------------------------------------
-- VoiceChat HUD Loading Screen Console
--  App version of the Voice Chat HUD for display on the loading screen.
--------------------------------------------------------------------------------

ZO_VoiceChatHUDLoadingScreen_Console = {}


--XML Calls
function ZO_VoiceChatHUDLoadingScreenConsole_OnInitialize(control)
    zo_mixin(control, ZO_VoiceChatHUD, ZO_VoiceChatHUDLoadingScreen_Console)
    control:Initialize(control)

    local function OnLogoutSuccessful()
        control.speakerData = {}
        control.delayedClears = {}
        control:Update()
    end

    control:RegisterForEvent(EVENT_LOGOUT_SUCCESSFUL, OnLogoutSuccessful)
end

function ZO_VoiceChatHUDLoadingScreenConsole_OnUpdate(control)
	control:Update()
end