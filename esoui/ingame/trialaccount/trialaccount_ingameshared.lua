local SETTING_FORMAT = "TrialAccountType%iSeenVersion"

function ZO_TrialAccount_GetInfo()
    local accountTypeId, title, description, currentVersion = GetTrialInfo()
    local seenVersion = 0
    if accountTypeId > 0 then
        local settingName = string.format(SETTING_FORMAT, accountTypeId)
        seenVersion = GetCVar(settingName)
        --If you hit this assert, it means we got an accountTypeId from services that corresponds to a def that we didn't add a setting for.
        --Add the setting in question to GameSettings.xml
        assert(seenVersion ~= "")
        seenVersion = tonumber(seenVersion)
    end
    return accountTypeId, title, description, currentVersion, seenVersion
end

function ZO_TrialAccount_SetSeenVersion(accountTypeId, seenVersion)
    local settingName = string.format(SETTING_FORMAT, accountTypeId)
    SetCVar(settingName, seenVersion)
end