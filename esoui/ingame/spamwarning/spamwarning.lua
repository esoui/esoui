local SPAM_WARNING_PERIOD_SECONDS = 600
local g_lastSpamWarnings = {}

function OnSpamWarningReceived(eventCode, spamType)
    local currentTime = GetFrameTimeSeconds()
    local spamTypeTime = g_lastSpamWarnings[spamType]

    if spamTypeTime == nil or currentTime - spamTypeTime > SPAM_WARNING_PERIOD_SECONDS then
        ZO_Dialogs_ShowPlatformDialog("SPAM_WARNING")
        g_lastSpamWarnings[spamType] = currentTime
    end
end

EVENT_MANAGER:RegisterForEvent("SpamWarning", EVENT_SPAM_WARNING, OnSpamWarningReceived)