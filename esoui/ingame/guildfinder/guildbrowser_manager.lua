------------------
-- Guild Finder: Guild Browser Manager --
--
-- Manages Guild Browser data in lua
------------------

ZO_GUILD_BROWSER_META_DATA_ATTRIBUTES =
{
    GUILD_META_DATA_ATTRIBUTE_NAME,
    GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_MESSAGE,
    GUILD_META_DATA_ATTRIBUTE_LANGUAGES,
    GUILD_META_DATA_ATTRIBUTE_ACTIVITIES,
    GUILD_META_DATA_ATTRIBUTE_PERSONALITIES,
    GUILD_META_DATA_ATTRIBUTE_ALLIANCE,
    GUILD_META_DATA_ATTRIBUTE_SIZE,
    GUILD_META_DATA_ATTRIBUTE_KIOSK,
    GUILD_META_DATA_ATTRIBUTE_HERALDRY,
    GUILD_META_DATA_ATTRIBUTE_FOUNDED_DATE,
    GUILD_META_DATA_ATTRIBUTE_PRIMARY_FOCUS,
    GUILD_META_DATA_ATTRIBUTE_SECONDARY_FOCUS,
    GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP,
    GUILD_META_DATA_ATTRIBUTE_ROLES,
    GUILD_META_DATA_ATTRIBUTE_START_TIME,
    GUILD_META_DATA_ATTRIBUTE_END_TIME,
    GUILD_META_DATA_ATTRIBUTE_HEADER_MESSAGE,
}

ZO_GuildBrowser_Manager = ZO_CallbackObject:Subclass()

function ZO_GuildBrowser_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_GuildBrowser_Manager:Initialize()
    self.currentFoundGuilds = {}
    self.guildDataList = {}
    self.guildDataRequestQueue = {}
    self.currentApplications = {}
    self.searchState = GUILD_FINDER_SEARCH_STATE_NONE

    local function CreateGuildData(objectPool)
        return 
        {
            initialized = {},
        }
    end

    local function ResetGuildData(object)
        object = 
        {
            initialized = {},
        }
    end

    RequestGuildFinderAccountApplications()

    self.guildDataPool = ZO_ObjectPool:New(CreateGuildData, ResetGuildData)

    local function OnGuildDataRequestComplete(eventId, guildId)
        local requestedGuildId = table.remove(self.guildDataRequestQueue, 1)
        if guildId == requestedGuildId then
            local hasGuildData = DoesGuildDataHaveInitializedAttributes(guildId, unpack(ZO_GUILD_BROWSER_META_DATA_ATTRIBUTES))
            if hasGuildData then
                self:PopulateGuildData(requestedGuildId)
            end
            self:FireCallbacks("OnGuildDataReady", requestedGuildId)
        end
    end

    local function OnGuildFinderSearchComplete(eventId, searchId)
        if self.searchState == GUILD_FINDER_SEARCH_STATE_QUEUED or searchId ~= self.currentSearchId then
            return -- Don't update when the search complete is not for our current search or we are waiting to do a new search immediately
        end

        self:ClearCurrentFoundGuilds()

        local numResults = GuildFinderGetNumSearchResults()
        for i = 1, numResults do
            local foundGuildId = GuildFinderGetSearchResultGuildId(i)
            table.insert(self.currentFoundGuilds, foundGuildId)
        end

        self:SetSearchState(GUILD_FINDER_SEARCH_STATE_COMPLETE)

        self:FireCallbacks("OnGuildFinderSearchResultsReady")
    end

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local defaults = { applicationText = "", reportedGuilds = {} }
            self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "ZO_GuildBrowser_ApplicationMessage", defaults)
            EVENT_MANAGER:UnregisterForEvent("ZO_GuildBrowser_Manager", EVENT_ADD_ON_LOADED)
        end
    end

    local function OnGuildFinderSearchCooldownUpdate(event, cooldownTimeMs)
        if self:IsSearchStateReady() and cooldownTimeMs > 0 then
            self:SetSearchState(GUILD_FINDER_SEARCH_STATE_WAITING)
        elseif self.searchState == GUILD_FINDER_SEARCH_STATE_QUEUED and cooldownTimeMs == 0 then
            self:ExecuteSearchInternal()
        end
    end

    local function OnGuildFinderApplicationResults()
        self:BuildApplications()
        self:FireCallbacks("OnApplicationsChanged")
    end

    local function OnApplicationResponse(event, guildId, result)
        if result == GUILD_APP_RESPONSE_APPLICATION_SENT then
            local guildData = self:GetGuildData(guildId)
            local guildName = ZO_WHITE:Colorize(guildData.guildName)
            local decoratedGuildName = ZO_AllianceIconNameFormatter(guildData.alliance, guildName)
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_SUBMITTED", nil, { mainTextParams = { decoratedGuildName } })
        else
            ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_APPLICATION_FAILED", nil, { mainTextParams = { GetString("SI_GUILDAPPLICATIONRESPONSE", result) } })
        end
    end

    EVENT_MANAGER:RegisterForEvent("ZO_GuildBrowser_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildBrowser_Manager", EVENT_GUILD_INFO_REQUEST_COMPLETE, OnGuildDataRequestComplete)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildBrowser_Manager", EVENT_GUILD_FINDER_SEARCH_COMPLETE, OnGuildFinderSearchComplete)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildBrowser_Manager", EVENT_GUILD_FINDER_SEARCH_COOLDOWN_UPDATE, OnGuildFinderSearchCooldownUpdate)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildBrowser_Manager", EVENT_GUILD_FINDER_APPLICATION_RESULTS_PLAYER, OnGuildFinderApplicationResults)
    EVENT_MANAGER:RegisterForEvent("ZO_GuildBrowser_Manager", EVENT_GUILD_FINDER_APPLICATION_RESPONSE, OnApplicationResponse)
end

function ZO_GuildBrowser_Manager:BuildApplications()
    ZO_ClearNumericallyIndexedTable(self.currentApplications)
    local numApps = GetGuildFinderNumAccountApplications()
    for i = 1, numApps do
        local guildId, level, championPoints, alliance, classId, guildName, guildAlliance, accountName, characterName, achievementPoints, applicationMessage = GetGuildFinderAccountApplicationInfo(i)
        local timeRemainingS = GetGuildFinderAccountApplicationDuration(i)
        local applicationData = 
        {
            index = i,
            guildId = guildId,
            name = accountName,
            characterName = characterName,
            guildName = guildName,
            guildAlliance = guildAlliance,
            level = level,
            class = classId,
            alliance = alliance,
            championPoints = championPoints,
            achievementPoints = achievementPoints,
            message = applicationMessage,
            durationS = timeRemainingS,
        }
        table.insert(self.currentApplications, applicationData)
    end
end

function ZO_GuildBrowser_Manager:HasGuildData(guildId)
    return self.guildDataList[guildId] ~= nil
end

do
    local function SetupHeraldryData(guildData)
        -- Retrieve Heraldry Info
        local bgCategory, bgStyle, backgroundPrimaryColorIndex, backgroundSecondaryColorIndex, crestCategoryIndex, crestStyleIndex, crestColorIndex = GetGuildHeraldryAttribute(guildData.guildId)
        local bgCategoryIconPath = GetHeraldryGuildFinderBackgroundCategoryIcon(bgCategory)
        local bgStyleIconPath = GetHeraldryGuildFinderBackgroundStyleIcon(bgCategory, bgStyle)
        local crestIconPath = GetHeraldryGuildFinderCrestStyleIcon(crestCategoryIndex, crestStyleIndex)
        local _, _, crestR, crestG, crestB = GetHeraldryColorInfo(crestColorIndex)
        local _, _, backgroundPrimaryR, backgroundPrimaryG, backgroundPrimaryB = GetHeraldryColorInfo(backgroundPrimaryColorIndex)
        local _, _, backgroundSecondaryR, backgroundSecondaryG, backgroundSecondaryB = GetHeraldryColorInfo(backgroundSecondaryColorIndex)

        guildData.heraldry = {}
        guildData.heraldry.hasHeraldry = not (backgroundPrimaryColorIndex == 1 and backgroundSecondaryColorIndex == 1 and crestCategoryIndex == 1 and crestStyleIndex == 1 and crestColorIndex == 1)
        guildData.heraldry.bgCategoryIconPath = bgCategoryIconPath
        guildData.heraldry.bgStyleIconPath = bgStyleIconPath
        guildData.heraldry.crestIconPath = crestIconPath
        guildData.heraldry.crestColor = { crestR, crestG, crestB }
        guildData.heraldry.primaryBackgroundColor = { backgroundPrimaryR, backgroundPrimaryG, backgroundPrimaryB }
        guildData.heraldry.secondaryBackgroundColor = { backgroundSecondaryR, backgroundSecondaryG, backgroundSecondaryB }
    end

    local function SetupRoleData(guildData)
        guildData.roles = {}
        local guildId = guildData.guildId
        for i, role in ipairs(ZO_GUILD_FINDER_ROLE_ORDER) do
            if DoesGuildHaveRoleAttribute(guildId, role) then
                table.insert(guildData.roles, role)
            end
        end
    end

    local GUILD_BROWSER_DISPLAY_ATTRIBUTE_FUNCTION =
    {
        [GUILD_META_DATA_ATTRIBUTE_NAME] = function(guildData) guildData.guildName = GetGuildNameAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_MESSAGE] = function(guildData) guildData.recruitmentMessage = GetGuildRecruitmentMessageAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_LANGUAGES] = function(guildData) guildData.language = GetGuildLanguageAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_ACTIVITIES] = function(guildData) guildData.activitiesText = ZO_GuildFinder_Manager.GetAttributeCommaFormattedList(guildData.guildId, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_END, DoesGuildHaveActivityAttribute, "SI_GUILDACTIVITYATTRIBUTEVALUE") end,
        [GUILD_META_DATA_ATTRIBUTE_PERSONALITIES] = function(guildData) guildData.personality = GetGuildPersonalityAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_ALLIANCE] = function(guildData) guildData.alliance = GetGuildAllianceAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_SIZE] = function(guildData) guildData.size = GetGuildSizeAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_KIOSK] = function(guildData) guildData.guildTraderText = GetGuildKioskAttribute(guildData.guildId) or GetString(SI_GUILD_FINDER_GUILD_INFO_DEFAULT_ATTRIBUTE_VALUE) end,
        [GUILD_META_DATA_ATTRIBUTE_HERALDRY] = SetupHeraldryData,
        [GUILD_META_DATA_ATTRIBUTE_FOUNDED_DATE] = function(guildData) guildData.foundedDateText = GetGuildFoundedDateAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_PRIMARY_FOCUS] = function(guildData) guildData.primaryFocus = GetGuildPrimaryFocusAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_SECONDARY_FOCUS] = function(guildData) guildData.secondaryFocus = GetGuildSecondaryFocusAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP] = function(guildData) guildData.minimumCP = GetGuildMinimumCPAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_ROLES] = SetupRoleData,
        [GUILD_META_DATA_ATTRIBUTE_START_TIME] = function(guildData) guildData.startTimeHour = GetGuildLocalStartTimeAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_END_TIME] = function(guildData) guildData.endTimeHour = GetGuildLocalEndTimeAttribute(guildData.guildId) end,
        [GUILD_META_DATA_ATTRIBUTE_HEADER_MESSAGE] = function(guildData) guildData.headerMessage = GetGuildHeaderMessageAttribute(guildData.guildId) end,
    }

    function ZO_GuildBrowser_Manager:PopulateGuildData(guildId)
        if not self.guildDataList[guildId] then
            self.guildDataList[guildId] = self.guildDataPool:AcquireObject()
            self.guildDataList[guildId].guildId = guildId
        end

        local guildData = self.guildDataList[guildId]
        for _, data in ipairs(ZO_GUILD_BROWSER_META_DATA_ATTRIBUTES) do
            GUILD_BROWSER_DISPLAY_ATTRIBUTE_FUNCTION[data](guildData)
        end
    end
end

function ZO_GuildBrowser_Manager:GetGuildData(guildId)
    local hasGuildData = DoesGuildDataHaveInitializedAttributes(guildId, unpack(ZO_GUILD_BROWSER_META_DATA_ATTRIBUTES))
    if hasGuildData then
        self:PopulateGuildData(guildId)
        return self.guildDataList[guildId]
    end

    return nil
end

function ZO_GuildBrowser_Manager:RequestGuildData(guildId)
    if not self:GetGuildData(guildId) and not self:IsRequestingGuildData(guildId) then
        local didRequest = RequestGuildFinderAttributesForGuild(guildId)

        if didRequest then
            table.insert(self.guildDataRequestQueue, guildId)
        end

        return didRequest
    end

    return false
end

function ZO_GuildBrowser_Manager:IsRequestingGuildData(guildId)
    for i, requestedGuildId in ipairs(self.guildDataRequestQueue) do
        if requestedGuildId == guildId then
            return true
        end
    end

    return false
end

function ZO_GuildBrowser_Manager:HasCurrentFoundGuilds()
    return #self.currentFoundGuilds > 0
end

function ZO_GuildBrowser_Manager:ClearCurrentFoundGuilds()
    ZO_ClearNumericallyIndexedTable(self.currentFoundGuilds)
end

function ZO_GuildBrowser_Manager:CurrentFoundGuildsListIterator()
    return ipairs(self.currentFoundGuilds)
end

function ZO_GuildBrowser_Manager:GetCurrentApplicationsList()
    return self.currentApplications
end

function ZO_GuildBrowser_Manager:HasPendingApplicationToGuild(guildId)
    for i, application in ipairs(self.currentApplications) do
        if application.guildId == guildId then
            return true
        end
    end
    return false
end

function ZO_GuildBrowser_Manager:GetSavedApplicationMessage()
    return self.savedVars.applicationText
end

function ZO_GuildBrowser_Manager:SetSavedApplicationMessage(text)
    self.savedVars.applicationText = text
    ZO_SavePlayerConsoleProfile()
end

function ZO_GuildBrowser_Manager:AddReportedGuild(guildId)
    self.savedVars.reportedGuilds[guildId] = true
    ZO_SavePlayerConsoleProfile()
end

function ZO_GuildBrowser_Manager:IsGuildReported(guildId)
    return self.savedVars.reportedGuilds[guildId] == true
end

function ZO_GuildBrowser_Manager:ExecuteSearch()
    if self:CanSearchGuilds() then
        self:ExecuteSearchInternal()
    else
        self:SetSearchState(GUILD_FINDER_SEARCH_STATE_QUEUED)
    end
end

function ZO_GuildBrowser_Manager:ExecuteSearchInternal()
    local searchId = GuildFinderRequestSearch()
    if searchId ~= nil then
        self.currentSearchId = searchId
        self:SetSearchState(GUILD_FINDER_SEARCH_STATE_WAITING)
    end
end

function ZO_GuildBrowser_Manager:SetSearchState(searchState)
    if self.searchState ~= searchState then
        self.searchState = searchState
        self:FireCallbacks("OnSearchStateChanged", searchState)
    end
end

function ZO_GuildBrowser_Manager:GetSearchState()
    return self.searchState
end

function ZO_GuildBrowser_Manager:IsSearchStateReady()
    return self.searchState == GUILD_FINDER_SEARCH_STATE_NONE or self.searchState == GUILD_FINDER_SEARCH_STATE_COMPLETE
end

function ZO_GuildBrowser_Manager:CanSearchGuilds()
    return not GuildFinderIsSearchOnCooldown()
end

do
    local DEFAULT_BANNER_TEXTURE = "EsoUI/Art/GuildFinder/tabard_no_heraldry.dds"

    function ZO_GuildBrowser_Manager:BuildGuildHeraldryControl(guildHeraldry, guildData)
        local heraldryData = guildData.heraldry
        if heraldryData.hasHeraldry then
            guildHeraldry.banner:SetColor(unpack(heraldryData.primaryBackgroundColor))
            guildHeraldry.banner:SetTexture(heraldryData.bgCategoryIconPath)
            guildHeraldry.pattern:SetHidden(false)
            guildHeraldry.pattern:SetColor(unpack(heraldryData.secondaryBackgroundColor))
            guildHeraldry.pattern:SetTexture(heraldryData.bgStyleIconPath)
            guildHeraldry.crest:SetHidden(false)
            guildHeraldry.crest:SetColor(unpack(heraldryData.crestColor))
            guildHeraldry.crest:SetTexture(heraldryData.crestIconPath)
        else
            guildHeraldry.crest:SetHidden(true)
            guildHeraldry.pattern:SetHidden(true)
            guildHeraldry.banner:SetTexture(DEFAULT_BANNER_TEXTURE)
            guildHeraldry.banner:SetColor(ZO_WHITE:UnpackRGB())
        end
    end
end

-- Debug only command

function ZO_GuildBrowser_Manager:ClearReportedGuilds()
    ZO_ClearTable(self.savedVars.reportedGuilds)
    ZO_SavePlayerConsoleProfile()
end

function ZO_GuildBrowser_Manager:WipeAllData()
    self.guildDataPool:ReleaseAllObjects()
    self.guildDataList = {}
end

GUILD_BROWSER_MANAGER = ZO_GuildBrowser_Manager:New()