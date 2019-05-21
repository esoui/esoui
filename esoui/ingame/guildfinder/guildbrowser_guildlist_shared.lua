------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_GUILD_LIST_ENTRY_TYPE = 1

ZO_GuildBrowser_GuildList_Shared = ZO_GuildFinder_Panel_Shared:Subclass()

function ZO_GuildBrowser_GuildList_Shared:New(...)
    return ZO_GuildFinder_Panel_Shared.New(self, ...)
end

function ZO_GuildBrowser_GuildList_Shared:Initialize(control)
    ZO_GuildFinder_Panel_Shared.Initialize(self, control)
    self.list = control:GetNamedChild("List") 
    self.resultsLabel = control:GetNamedChild("Results")

    local function OnGuildFinderSearchResultsReady()
        if self.fragment:IsShowing() then
            self:RefreshList()
        end
    end

    GUILD_BROWSER_MANAGER:RegisterCallback("OnGuildFinderSearchResultsReady", OnGuildFinderSearchResultsReady)
    GUILD_BROWSER_MANAGER:RegisterCallback("OnSearchStateChanged", function(newState) self:OnSearchStateChanged(newState) end)
end

function ZO_GuildBrowser_GuildList_Shared:OnShowing()
    
end

function ZO_GuildBrowser_GuildList_Shared:OnHidden()
    
end

function ZO_GuildBrowser_GuildList_Shared:GetAllianceIcon(alliance)
    assert(false) -- must be overridden
end

function ZO_GuildBrowser_GuildList_Shared:RefreshSearchFilters()
    -- to be overridden
end

function ZO_GuildBrowser_GuildList_Shared:ResetFilters()
    -- to be overridden
end

function ZO_GuildBrowser_GuildList_Shared:PopulateList()
    ZO_ScrollList_ResetToTop(self.list)

    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, guildId in GUILD_BROWSER_MANAGER:CurrentFoundGuildsListIterator() do
        if not GUILD_BROWSER_MANAGER:IsGuildReported(guildId) then
            local guildMetaData = GUILD_BROWSER_MANAGER:GetGuildData(guildId)
            guildMetaData.formattedAllianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(guildMetaData.alliance))
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_GUILD_BROWSER_GUILD_LIST_ENTRY_TYPE, guildMetaData))
        end
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_GuildBrowser_GuildList_Shared:SetupRow(control, data)
    control.data = data

    control.guildNameLabel:SetText(data.guildName)

    control.guildAllianceTexture:SetTexture(self:GetAllianceIcon(data.alliance))

    GUILD_BROWSER_MANAGER:BuildGuildHeraldryControl(control.guildHeraldry, data)
    
    control.guildHeaderMessageLabel:SetText(data.headerMessage)
    self:SetupRowContextualInfo(control, data)
end

function ZO_GuildBrowser_GuildList_Shared:SetupRowContextualInfo(control, data)
    assert(false) -- must be overridden
end

function ZO_GuildBrowser_GuildList_Shared:GetRowContextualInfo(data)
    if self.focusType == GUILD_FOCUS_ATTRIBUTE_VALUE_TRADING then -- guild trader
        return  GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_KIOSK), data.guildTraderText
    elseif self.focusType == GUILD_FOCUS_ATTRIBUTE_VALUE_GROUP_PVE or self.focusType == GUILD_FOCUS_ATTRIBUTE_VALUE_PVP then -- minimum CP
        return  GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP), data.minimumCP
    elseif self.focusType == GUILD_FOCUS_ATTRIBUTE_VALUE_ROLEPLAYING or self.focusType == GUILD_FOCUS_ATTRIBUTE_VALUE_SOCIAL then -- personality
        return  GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PERSONALITIES), GetString("SI_GUILDPERSONALITYATTRIBUTEVALUE", data.personality)
    else -- default to playtime
        return GetString(SI_GUILD_FINDER_GUILD_INFO_PLAYTIME_HEADER), ZO_GuildFinder_Manager.CreatePlaytimeRangeText(data)
    end
end

function ZO_GuildBrowser_GuildList_Shared:OnSearchStateChanged(newState)
    local shouldShowEmptyList = newState == GUILD_FINDER_SEARCH_STATE_WAITING or newState == GUILD_FINDER_SEARCH_STATE_QUEUED
    if shouldShowEmptyList then
        ZO_ScrollList_ResetToTop(self.list)
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        ZO_ClearNumericallyIndexedTable(scrollData)
        ZO_ScrollList_Commit(self.list)
    end

    self:UpdateResultsLabel()
end

function ZO_GuildBrowser_GuildList_Shared:UpdateResultsLabel()
    self.resultsLabel:SetHidden(true)

    local currentSearchState = GUILD_BROWSER_MANAGER:GetSearchState()
    if currentSearchState == GUILD_FINDER_SEARCH_STATE_WAITING or currentSearchState == GUILD_FINDER_SEARCH_STATE_QUEUED then
        self.resultsLabel:SetText(GetString(SI_GUILD_BROWSER_GUILD_LIST_REFRESHING_RESULTS))
        self.resultsLabel:SetHidden(false)
        return
    end

    if currentSearchState == GUILD_FINDER_SEARCH_STATE_COMPLETE and not GUILD_BROWSER_MANAGER:HasCurrentFoundGuilds() then
        self.resultsLabel:SetText(GetString(SI_GUILD_BROWSER_GUILD_LIST_NO_RESULTS))
        self.resultsLabel:SetHidden(false)
        return
    end
end

function ZO_GuildBrowser_GuildList_Shared:RefreshList()
    if self.fragment:IsShowing() then
        self:PopulateList()
    end
end