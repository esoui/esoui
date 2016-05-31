local SETTING_FORMAT = "TrialAccountType%iSeenVersion"

function ZO_TrialAccount_GetInfo()
    local accountTypeId, title, description, currentVersion = GetTrialInfo()
    local seenVersion = 0
    if accountTypeId > 0 then
        local settingName = string.format(SETTING_FORMAT, accountTypeId)
        seenVersion = GetCVar(settingName)

        --If the setting has not been created in GameSettings.xml, we must add it if we want to be able to see the pop-up
        --Otherwise we just pretend like we've seen it
        if seenVersion == "" then
            seenVersion = currentVersion
        else
            seenVersion = tonumber(seenVersion)
        end
    end
    return accountTypeId, title, description, currentVersion, seenVersion
end

function ZO_TrialAccount_SetSeenVersion(accountTypeId, seenVersion)
    local settingName = string.format(SETTING_FORMAT, accountTypeId)
    SetCVar(settingName, seenVersion)
end