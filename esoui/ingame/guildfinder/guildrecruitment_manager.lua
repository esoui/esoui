------------------
-- Guild Finder: Guild Recruitment Manager --
--
-- Manages Guild Recruitment data in lua
------------------

ZO_GuildRecruitment_Manager = ZO_CallbackObject:Subclass()

function ZO_GuildRecruitment_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_GuildRecruitment_Manager:Initialize()
    local function OnGuildFinderApplicationsReceived(event, guildId)
        self:FireCallbacks("GuildApplicationResultsReady", guildId)
    end

    local function OnGuildFinderBlacklistReceived()
        self:FireCallbacks("GuildBlacklistResultsReady")
    end

    local function OnGuildPermissionsReceived(event, guildId)
        self:FireCallbacks("GuildPermissionsChanged", guildId)
    end

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local defaults = { guildResponseTexts = {} }
            self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "ZO_GuildRecruitment_ResponseMessage", defaults)
            EVENT_MANAGER:UnregisterForEvent("ZO_GuildRecruitment_Manager", EVENT_ADD_ON_LOADED)
        end
    end

    local function OnBlacklistResponse(event, guildId, accountName, result)
        local guildName = GetGuildName(guildId)
        if not ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(result) then
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { result } })
        elseif ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(result) then
            local displayName = ZO_FormatUserFacingDisplayName(accountName)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_RECRUITMENT_ADDED_TO_BLACKLIST_ALERT, displayName, guildName))
        end
    end

    local function OnGuildMembershipChanged()
        self:FireCallbacks("GuildMembershipChanged", guildId)
    end

    local function OnProcessApplicationResponse(event, guildId, accountName, result)
        local guildName = GetGuildName(guildId) or ""
        if result == GUILD_PROCESS_APP_RESPONSE_APPLICATION_PROCESSED_ACCEPT then
            local displayName = ZO_FormatUserFacingDisplayName(accountName)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_RECRUITMENT_APPLICATION_ACCEPTED_ALERT, displayName, guildName))
        elseif result == GUILD_PROCESS_APP_RESPONSE_APPLICATION_PROCESSED_DECLINE then
            local displayName = ZO_FormatUserFacingDisplayName(accountName)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_RECRUITMENT_APPLICATION_DECLINED_ALERT, displayName, guildName))
        elseif result == GUILD_PROCESS_APP_RESPONSE_APPLICATION_PROCESSED_RESCIND then
            -- No alert needed for rescind
        else
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_PROCESS_APPLICATION_FAILED", nil, { mainTextParams = { result } })
        end
    end

    local function OnUpdatedGuildInfoReceived(event, guildId, result)
        self:FireCallbacks("GuildInfoChanged", guildId)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_APPLICATION_RESULTS_GUILD, OnGuildFinderApplicationsReceived)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_GUILD_NEW_APPLICATIONS, OnGuildFinderApplicationsReceived)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_BLACKLIST_RESULTS, OnGuildFinderBlacklistReceived)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_RANK_CHANGED, OnGuildPermissionsReceived)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_BLACKLIST_RESPONSE, OnBlacklistResponse)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_MEMBER_ADDED, OnGuildMembershipChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_MEMBER_REMOVED, OnGuildMembershipChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_PLAYER_RANK_CHANGED, OnGuildPermissionsReceived)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_PROCESS_APPLICATION_RESPONSE, OnProcessApplicationResponse)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_RECRUITMENT_INFO_UPDATED, OnUpdatedGuildInfoReceived)
end

function ZO_GuildRecruitment_Manager.IsBlacklistResultSuccessful(result)
     return result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_ADDED or
            result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_REMOVED or
            result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_EDITTED
end

function ZO_GuildRecruitment_Manager.IsAddedToBlacklistSuccessful(result)
     return result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_ADDED
end

function ZO_GuildRecruitment_Manager:GetSavedApplicationsDefaultMessage(guildId)
    return self.savedVars.guildResponseTexts[guildId]
end

function ZO_GuildRecruitment_Manager:SetSavedApplicationsDefaultMessage(guildId, text)
    self.savedVars.guildResponseTexts[guildId] = text
    ZO_SavePlayerConsoleProfile()
end

function ZO_GuildRecruitment_Manager.PopulateDropdown(dropDownControl, iterBegin, iterEnd, stringBase, selectionFunction, data, omittedIndex)
    dropDownControl:ClearItems()

    if type(omittedIndex) == "function" then
        omittedIndex = omittedIndex()
    end
    
    local selectedEntryIndex
    local currentIndex = 1

    local function AddEntry(value)
        if value ~= omittedIndex then
            local entry = dropDownControl:CreateItemEntry(GetString(stringBase, value), selectionFunction)
            entry.value = value
            if data.currentValue == value then
                selectedEntryIndex = currentIndex
            end
            dropDownControl:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
            currentIndex = currentIndex + 1
        end
    end

    for i = iterBegin, iterEnd do
        AddEntry(i)
    end

    if data.extraValues then
        for _, value in ipairs(data.extraValues) do
            AddEntry(value)
        end
    end

    local IGNORE_CALLBACK = true
    if selectedEntryIndex then
        dropDownControl:SelectItemByIndex(selectedEntryIndex, IGNORE_CALLBACK)
    else
        dropDownControl:SetSelectedItemText(GetString(SI_GUILD_RECRUITMENT_DEFAULT_SELECTION_TEXT))
    end
end

GUILD_RECRUITMENT_MANAGER = ZO_GuildRecruitment_Manager:New()