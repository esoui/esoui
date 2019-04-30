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
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        RequestGuildFinderGuildApplications(guildId)
        RequestGuildBlacklist(guildId)
    end

    local function OnGuildFinderApplicationsRecieved(event, guildId)
        self:FireCallbacks("GuildApplicationResultsReady", guildId)
    end

    local function OnGuildFinderBlacklistRecieved()
        self:FireCallbacks("GuildBlacklistResultsReady")
    end

    local function OnGuildPermissionsRecieved(event, guildId)
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
        if not self:IsBlacklistResultSuccessful(result) then
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_BLACKLIST_FAILED", nil, { mainTextParams = { result } })
        elseif result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_ADDED then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_RECRUITMENT_ADDED_TO_BLACKLIST_ALERT, accountName, guildName))
        end
    end

    local function OnGuildMembershipChanged()
        self:FireCallbacks("GuildMembershipChanged", guildId)
    end

    local function OnProcessApplicationResponse(event, guildId, accountName, result)
        local guildName = GetGuildName(guildId) or ""
        if result == GUILD_PROCESS_APP_RESPONSE_APPLICATION_PROCESSED_ACCEPT then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_RECRUITMENT_APPLICATION_ACCEPTED_ALERT, accountName, guildName))
        elseif result == GUILD_PROCESS_APP_RESPONSE_APPLICATION_PROCESSED_DECLINE then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GUILD_RECRUITMENT_APPLICATION_DECLINED_ALERT, accountName, guildName))
        elseif result == GUILD_PROCESS_APP_RESPONSE_APPLICATION_PROCESSED_RESCIND then
            -- No alert needed for rescind
        else
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_PROCESS_APPLICATION_FAILED", nil, { mainTextParams = { result } })
        end
    end

    local function OnUpdatedGuildInfoRecieved(event, guildId, result)
        self:FireCallbacks("GuildInfoChanged", guildId)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_APPLICATION_RESULTS_GUILD, OnGuildFinderApplicationsRecieved)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_GUILD_NEW_APPLICATIONS, OnGuildFinderApplicationsRecieved)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_BLACKLIST_RESULTS, OnGuildFinderBlacklistRecieved)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_RANK_CHANGED, OnGuildPermissionsRecieved)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_BLACKLIST_RESPONSE, OnBlacklistResponse)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_MEMBER_ADDED, OnGuildMembershipChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_MEMBER_REMOVED, OnGuildMembershipChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_PLAYER_RANK_CHANGED, OnGuildPermissionsRecieved)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_FINDER_PROCESS_APPLICATION_RESPONSE, OnProcessApplicationResponse)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildRecruitment_Manager", EVENT_GUILD_RECRUITMENT_INFO_UPDATED, OnUpdatedGuildInfoRecieved)
end

function ZO_GuildRecruitment_Manager:IsBlacklistResultSuccessful(result)
     return result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_ADDED or
            result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_REMOVED or
            result == GUILD_BLACKLIST_RESPONSE_BLACKLIST_SUCCESSFULLY_EDITTED
end

function ZO_GuildRecruitment_Manager:GetSavedApplicationsDefaultMessage(guildId)
    return self.savedVars.guildResponseTexts[guildId]
end

function ZO_GuildRecruitment_Manager:SetSavedApplicationsDefaultMessage(guildId, text)
    self.savedVars.guildResponseTexts[guildId] = text
end

function ZO_GuildRecruitment_Manager.PopulateDropdown(dropDownControl, iterBegin, iterEnd, stringBase, selectionFunction, data, omittedIndex)
    dropDownControl:ClearItems()

    if omittedIndex and type(omittedIndex) == "function" then
        omittedIndex = omittedIndex()
    end

    local selectedEntryIndex
    local currentIndex = 1
    for i = iterBegin, iterEnd do
        if not omittedIndex or i ~= omittedIndex then
            local entry = dropDownControl:CreateItemEntry(GetString(stringBase, i), selectionFunction)
            entry.value = i
            if data.currentValue == i then
                selectedEntryIndex = currentIndex
            end
            dropDownControl:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
            currentIndex = currentIndex + 1
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