-------------
-- Request --
-------------

ZO_GuildHistoryRequest = ZO_InitializingObject:Subclass()

function ZO_GuildHistoryRequest:Initialize(guildId, eventCategory, newestTimeS, oldestTimeS)
    self.guildId = guildId
    self.eventCategory = eventCategory
    self.newestTimeS = newestTimeS
    self.oldestTimeS = oldestTimeS
    self.requestId = CreateGuildHistoryRequest(guildId, eventCategory, newestTimeS, oldestTimeS)
end

function ZO_GuildHistoryRequest:GetRequestId()
    return self.requestId
end

function ZO_GuildHistoryRequest:IsValid()
    return self.requestId ~= 0
end

function ZO_GuildHistoryRequest:GetFlags()
    return GetGuildHistoryRequestFlags(self.requestId)
end

function ZO_GuildHistoryRequest:IsComplete()
    return IsGuildHistoryRequestComplete(self.requestId)
end

function ZO_GuildHistoryRequest:IsRequestQueued()
    return ZO_FlagHelpers.MaskHasFlag(self:GetFlags(), GUILD_HISTORY_REQUEST_FLAG_QUEUED)
end

function ZO_GuildHistoryRequest:IsRequestQueuedFromAddon()
    return ZO_FlagHelpers.MaskHasFlag(self:GetFlags(), GUILD_HISTORY_REQUEST_FLAG_QUEUED_FROM_ADDON)
end

function ZO_GuildHistoryRequest:IsRequestResponsePending()
    return ZO_FlagHelpers.MaskHasFlag(self:GetFlags(), GUILD_HISTORY_REQUEST_FLAG_RESPONSE_PENDING)
end

function ZO_GuildHistoryRequest:RequestMoreEvents(queueRequestIfOnCooldown)
    local guildHistoryDataReadyState = RequestMoreGuildHistoryEvents(self.requestId, queueRequestIfOnCooldown)
    return guildHistoryDataReadyState
end

---------------------
-- Event Data Base --
---------------------

local REDACTED_TEXT = "--"

local function GetContrastTextColor(isGamepad)
    return isGamepad and ZO_SELECTED_TEXT or ZO_SECOND_CONTRAST_TEXT
end

ZO_GuildHistoryEventData_Base = ZO_InitializingObject:Subclass()

function ZO_GuildHistoryEventData_Base:Initialize(pool, eventIndex)
    self.categoryData = pool.categoryData
    self.eventIndex = eventIndex
    self.eventInfo = {}
    self.platformText = {}
end

function ZO_GuildHistoryEventData_Base:Dirty()
    self.eventInfo.dirty = true
end

function ZO_GuildHistoryEventData_Base:Clean()
    -- The relationship between index and event id got shifted, invalidate eventInfo
    if self.eventInfo.dirty and self.eventInfo.eventId and self.eventInfo.eventId ~= GetGuildHistoryEventId(self:GetGuildId(), self:GetEventCategory(), self.eventIndex) then
        self:ResetEventInfo()
    end
    self.eventInfo.dirty = nil
end

function ZO_GuildHistoryEventData_Base:ResetEventInfo()
    ZO_ClearTable(self.eventInfo)
    ZO_ClearTable(self.platformText)
end

function ZO_GuildHistoryEventData_Base:GetEventIndex()
    return self.eventIndex
end

function ZO_GuildHistoryEventData_Base:GetEventInfo()
    self:Clean()
    if not self.eventInfo.eventId then
        self:InternalRefreshEventInfo()
    end
    return self.eventInfo
end

function ZO_GuildHistoryEventData_Base:GetEventId()
    return self:GetEventInfo().eventId
end

function ZO_GuildHistoryEventData_Base:GetEventType()
    return self:GetEventInfo().eventType
end

function ZO_GuildHistoryEventData_Base:GetEventTimestampS()
    return self:GetEventInfo().timestampS
end

function ZO_GuildHistoryEventData_Base:IsRedacted()
    return self:GetEventInfo().isRedacted
end

function ZO_GuildHistoryEventData_Base:GetGuildId()
    return self.categoryData:GetGuildData():GetId()
end

function ZO_GuildHistoryEventData_Base:GetEventCategory()
    return self.categoryData:GetEventCategory()
end

-- Normally this would be the responsibility of a UI screen, not the data object, but this is an optimization
-- so as not to need to constantly recalculate this as the UI constantly recycles entry data wrappers
function ZO_GuildHistoryEventData_Base:GetUISubcategoryIndex()
    local eventInfo = self:GetEventInfo()
    if not eventInfo.uiSubcategoryIndex then
        eventInfo.uiSubcategoryIndex = ZO_GuildHistory_Manager.ComputeEventSubcategory(self:GetEventCategory(), self:GetEventType())
    end
    return eventInfo.uiSubcategoryIndex
end

function ZO_GuildHistoryEventData_Base:GetText(isGamepad)
    local eventInfo = self:GetEventInfo()
    if eventInfo.isRedacted then
        return REDACTED_TEXT
    end
    if isGamepad == nil then
        isGamepad = IsInGamepadPreferredMode()
    end
    self:Clean()
    if self.platformText[isGamepad] then
        return self.platformText[isGamepad]
    end
    self:InternalRefreshText(isGamepad)
    return self.platformText[isGamepad]
end

--Events that need to do a special narration should override this function
function ZO_GuildHistoryEventData_Base:GetNarrationText()
    --In practice isGamepad will always be true, since narration is gamepad only
    local isGamepad = IsInGamepadPreferredMode()
    return self:GetText(isGamepad)
end

function ZO_GuildHistoryEventData_Base:GetFormattedTime()
    return ZO_FormatDurationAgo(GetTimeStamp32() - self:GetEventTimestampS())
end

do
    local colorizedParams = {}
    function ZO_GuildHistoryEventData_Base:InternalRefreshText(isGamepad, enumPrefix, ...)
        internalassert(enumPrefix, "InternalRefreshText must be overriden to pass appropriate string args")
        local eventInfo = self:GetEventInfo()
        if eventInfo.isRedacted then
            self.platformText[isGamepad] = REDACTED_TEXT
            return
        end
        local formatString = GetString(enumPrefix, eventInfo.eventType)
        local numArgs = select('#', ...)
        if numArgs > 0 then
            local contrastColor = GetContrastTextColor(isGamepad)
            ZO_ClearNumericallyIndexedTable(colorizedParams)
            for i = 1, numArgs do
                local param = select(i, ...)
                if param and param ~= "" then
                    table.insert(colorizedParams, contrastColor:Colorize(param))
                end
            end

            self.platformText[isGamepad] = zo_strformat(formatString, unpack(colorizedParams))
        else
            self.platformText[isGamepad] = formatString
        end
    end
end

ZO_GuildHistoryEventData_Base:MUST_IMPLEMENT("InternalRefreshEventInfo")

--------------------------------
-- Event Data Derived Classes --
--------------------------------

-- ROSTER

ZO_GuildHistoryRosterEventData = ZO_GuildHistoryEventData_Base:Subclass()

function ZO_GuildHistoryRosterEventData:InternalRefreshEventInfo()
    local eventInfo = self.eventInfo
    local guildId = self:GetGuildId()
    eventInfo.eventId, eventInfo.timestampS, eventInfo.isRedacted, eventInfo.eventType, eventInfo.actingDisplayName, eventInfo.targetDisplayName, eventInfo.rankId = GetGuildHistoryRosterEventInfo(guildId, self.eventIndex)
    if eventInfo.rankId then
        eventInfo.rankIndex = GetGuildRankIndex(guildId, eventInfo.rankId)
        if eventInfo.rankIndex then
            eventInfo.rankName = GetFinalGuildRankName(guildId, eventInfo.rankIndex)
        end

        if not eventInfo.rankName or eventInfo.rankName == "" then
            eventInfo.rankName = GetString(SI_GUILD_HISTORY_DEFAULT_PARSED_TEXT)
        end
    end
end

function ZO_GuildHistoryRosterEventData:InternalRefreshText(isGamepad)
    local eventInfo = self:GetEventInfo()
    ZO_GuildHistoryEventData_Base.InternalRefreshText(self, isGamepad, "SI_GUILDHISTORYROSTEREVENT", ZO_FormatUserFacingDisplayName(eventInfo.actingDisplayName), ZO_FormatUserFacingDisplayName(eventInfo.targetDisplayName), eventInfo.rankName)
end

-- BANKED_ITEM

ZO_GuildHistoryBankedItemEventData = ZO_GuildHistoryEventData_Base:Subclass()

function ZO_GuildHistoryBankedItemEventData:InternalRefreshEventInfo()
    local eventInfo = self.eventInfo
    eventInfo.eventId, eventInfo.timestampS, eventInfo.isRedacted, eventInfo.eventType, eventInfo.displayName, eventInfo.itemLink, eventInfo.quantity = GetGuildHistoryBankedItemEventInfo(self:GetGuildId(), self.eventIndex)
end

function ZO_GuildHistoryBankedItemEventData:InternalRefreshText(isGamepad)
    local eventInfo = self:GetEventInfo()
    ZO_GuildHistoryEventData_Base.InternalRefreshText(self, isGamepad, "SI_GUILDHISTORYBANKEDITEMEVENT", ZO_FormatUserFacingDisplayName(eventInfo.displayName), eventInfo.quantity, eventInfo.itemLink)
end

-- BANKED_CURRENCY

ZO_GuildHistoryBankedCurrencyEventData = ZO_GuildHistoryEventData_Base:Subclass()

function ZO_GuildHistoryBankedCurrencyEventData:InternalRefreshEventInfo()
    local eventInfo = self.eventInfo
    eventInfo.eventId, eventInfo.timestampS, eventInfo.isRedacted, eventInfo.eventType, eventInfo.displayName, eventInfo.currencyType, eventInfo.amount, eventInfo.kioskName = GetGuildHistoryBankedCurrencyEventInfo(self:GetGuildId(), self.eventIndex)
end

function ZO_GuildHistoryBankedCurrencyEventData:InternalRefreshText(isGamepad)
    local eventInfo = self:GetEventInfo()
    local DONT_USE_SHORT_FORMAT = false
    local amountText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(eventInfo.amount, DONT_USE_SHORT_FORMAT, eventInfo.currencyType, isGamepad)
    ZO_GuildHistoryEventData_Base.InternalRefreshText(self, isGamepad, "SI_GUILDHISTORYBANKEDCURRENCYEVENT", ZO_FormatUserFacingDisplayName(eventInfo.displayName), amountText, eventInfo.kioskName)
end

function ZO_GuildHistoryBankedCurrencyEventData:GetNarrationText()
    local eventInfo = self:GetEventInfo()
    local amountNarration = ZO_Currency_FormatGamepad(eventInfo.currencyType, eventInfo.amount, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
    local formatString = GetString("SI_GUILDHISTORYBANKEDCURRENCYEVENT", eventInfo.eventType)
    return zo_strformat(formatString, ZO_FormatUserFacingDisplayName(eventInfo.displayName), amountNarration, eventInfo.kioskName)
end

-- TRADER

ZO_GuildHistoryTraderEventData = ZO_GuildHistoryEventData_Base:Subclass()

function ZO_GuildHistoryTraderEventData:InternalRefreshEventInfo()
    local eventInfo = self.eventInfo
    eventInfo.eventId, eventInfo.timestampS, eventInfo.isRedacted, eventInfo.eventType, eventInfo.sellerDisplayName, eventInfo.buyerDisplayName, eventInfo.itemLink, eventInfo.quantity, eventInfo.price, eventInfo.tax = GetGuildHistoryTraderEventInfo(self:GetGuildId(), self.eventIndex)
end

function ZO_GuildHistoryTraderEventData:InternalRefreshText(isGamepad)
    local eventInfo = self:GetEventInfo()
    local DONT_USE_SHORT_FORMAT = false
    local priceText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(eventInfo.price, DONT_USE_SHORT_FORMAT, CURT_MONEY, isGamepad)
    local taxText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(eventInfo.tax, DONT_USE_SHORT_FORMAT, CURT_MONEY, isGamepad)
    ZO_GuildHistoryEventData_Base.InternalRefreshText(self, isGamepad, "SI_GUILDHISTORYTRADEREVENT", ZO_FormatUserFacingDisplayName(eventInfo.sellerDisplayName), ZO_FormatUserFacingDisplayName(eventInfo.buyerDisplayName), eventInfo.quantity, eventInfo.itemLink, priceText, taxText)
end

function ZO_GuildHistoryTraderEventData:GetNarrationText()
    local eventInfo = self:GetEventInfo()
    local priceNarration = ZO_Currency_FormatGamepad(CURT_MONEY, eventInfo.price, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
    local taxNarration = ZO_Currency_FormatGamepad(CURT_MONEY, eventInfo.tax, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
    local formatString = GetString("SI_GUILDHISTORYTRADEREVENT", eventInfo.eventType)
    return zo_strformat(formatString, ZO_FormatUserFacingDisplayName(eventInfo.sellerDisplayName), ZO_FormatUserFacingDisplayName(eventInfo.buyerDisplayName), eventInfo.quantity, eventInfo.itemLink, priceNarration, taxNarration)
end

-- MILESTONE

ZO_GuildHistoryMilestoneEventData = ZO_GuildHistoryEventData_Base:Subclass()

function ZO_GuildHistoryMilestoneEventData:InternalRefreshEventInfo()
    local eventInfo = self.eventInfo
    eventInfo.eventId, eventInfo.timestampS, eventInfo.isRedacted, eventInfo.eventType = GetGuildHistoryMilestoneEventInfo(self:GetGuildId(), self.eventIndex)
end

function ZO_GuildHistoryMilestoneEventData:InternalRefreshText(isGamepad)
    ZO_GuildHistoryEventData_Base.InternalRefreshText(self, isGamepad, "SI_GUILDHISTORYMILESTONEEVENT")
end

-- ACTIVITY

ZO_GuildHistoryActivityEventData = ZO_GuildHistoryEventData_Base:Subclass()

function ZO_GuildHistoryActivityEventData:InternalRefreshEventInfo()
    local eventInfo = self.eventInfo
    eventInfo.eventId, eventInfo.timestampS, eventInfo.isRedacted, eventInfo.eventType, eventInfo.displayName = GetGuildHistoryActivityEventInfo(self:GetGuildId(), self.eventIndex)
end

function ZO_GuildHistoryActivityEventData:InternalRefreshText(isGamepad)
    local eventInfo = self:GetEventInfo()
    ZO_GuildHistoryEventData_Base.InternalRefreshText(self, isGamepad, "SI_GUILDHISTORYACTIVITYEVENT", ZO_FormatUserFacingDisplayName(eventInfo.displayName))
end

-- AVA_ACTIVITY

ZO_GuildHistoryAvAActivityEventData = ZO_GuildHistoryEventData_Base:Subclass()

function ZO_GuildHistoryAvAActivityEventData:InternalRefreshEventInfo()
    local eventInfo = self.eventInfo
    eventInfo.eventId, eventInfo.timestampS, eventInfo.isRedacted, eventInfo.eventType, eventInfo.displayName, eventInfo.keepId, eventInfo.campaignId = GetGuildHistoryAvAActivityEventInfo(self:GetGuildId(), self.eventIndex)
end

function ZO_GuildHistoryAvAActivityEventData:InternalRefreshText(isGamepad)
    local eventInfo = self:GetEventInfo()
    ZO_GuildHistoryEventData_Base.InternalRefreshText(self, isGamepad, "SI_GUILDHISTORYAVAACTIVITYEVENT", ZO_FormatUserFacingDisplayName(eventInfo.displayName), GetKeepName(eventInfo.keepId), GetCampaignName(eventInfo.campaignId))
end

-------------------------
-- Event Category Data --
-------------------------

ZO_GuildHistoryEventCategoryData = ZO_InitializingObject:Subclass()

do
    local EVENT_CATEGORY_TO_DATA_TYPE =
    {
        [GUILD_HISTORY_EVENT_CATEGORY_ROSTER] = ZO_GuildHistoryRosterEventData,
        [GUILD_HISTORY_EVENT_CATEGORY_BANKED_ITEM] = ZO_GuildHistoryBankedItemEventData,
        [GUILD_HISTORY_EVENT_CATEGORY_BANKED_CURRENCY] = ZO_GuildHistoryBankedCurrencyEventData,
        [GUILD_HISTORY_EVENT_CATEGORY_TRADER] = ZO_GuildHistoryTraderEventData,
        [GUILD_HISTORY_EVENT_CATEGORY_MILESTONE] = ZO_GuildHistoryMilestoneEventData,
        [GUILD_HISTORY_EVENT_CATEGORY_ACTIVITY] = ZO_GuildHistoryActivityEventData,
        [GUILD_HISTORY_EVENT_CATEGORY_AVA_ACTIVITY] = ZO_GuildHistoryAvAActivityEventData,
    }

    function ZO_GuildHistoryEventCategoryData:Initialize(guildData, eventCategory)
        self.guildData = guildData
        self.eventCategory = eventCategory
        self.events = ZO_ObjectPool:New(EVENT_CATEGORY_TO_DATA_TYPE[eventCategory], ZO_GuildHistoryEventData_Base.ResetEventInfo)
        self.events.categoryData = self
    end
end

function ZO_GuildHistoryEventCategoryData:GetGuildData()
    return self.guildData
end

function ZO_GuildHistoryEventCategoryData:GetEventCategory()
    return self.eventCategory
end

function ZO_GuildHistoryEventCategoryData:Dirty(fullReset)
    if fullReset then
        self.events:ReleaseAllObjects()
    else
        -- The relationship between index and eventId may or may not have shifted.
        -- Dirty so we check it once the next time someone needs info about the event.
        for _, event in ipairs(self.events:GetActiveObjects()) do
            event:Dirty()
        end
    end
end

function ZO_GuildHistoryEventCategoryData:OnCategoryUpdated(flags)
    if ZO_FlagHelpers.MaskHasFlag(flags, GUILD_HISTORY_CATEGORY_UPDATE_FLAG_REFRESHED) then
        local FULL_RESET = true
        self:Dirty(FULL_RESET)
    elseif ZO_FlagHelpers.MaskHasFlag(flags, GUILD_HISTORY_CATEGORY_UPDATE_FLAG_NEW_INFO) then
        self:Dirty()
    end
end

function ZO_GuildHistoryEventCategoryData:GetNumEvents()
    return GetNumGuildHistoryEvents(self.guildData:GetId(), self.eventCategory)
end

function ZO_GuildHistoryEventCategoryData:GetEvents()
    local numEvents = self:GetNumEvents()
    if self.events:GetActiveObjectCount() ~= numEvents then
        for eventIndex = 1, numEvents do
            self.events:AcquireObject(eventIndex)
        end
    end
    return self.events:GetActiveObjects()
end

function ZO_GuildHistoryEventCategoryData:GetEvent(eventIndex)
    if eventIndex > 0 and eventIndex <= self:GetNumEvents() then
        return self.events:AcquireObject(eventIndex)
    end
    return nil
end

function ZO_GuildHistoryEventCategoryData:GetOldestEventIndexForUpToDateEventsWithoutGaps()
    return GetOldestGuildHistoryEventIndexForUpToDateEventsWithoutGaps(self.guildData:GetId(), self.eventCategory)
end

function ZO_GuildHistoryEventCategoryData:GetOldestEventForUpToDateEventsWithoutGaps()
    local eventIndex = self:GetOldestEventIndexForUpToDateEventsWithoutGaps()
    if eventIndex then
        return self:GetEvent(eventIndex)
    end
    return nil
end

function ZO_GuildHistoryEventCategoryData:GetEventsInTimeRange(newestTimeS, oldestTimeS)
    local newestIndex, oldestIndex = GetGuildHistoryEventIndicesForTimeRange(self.guildData:GetId(), self.eventCategory, newestTimeS, oldestTimeS)
    return self:GetEventsInIndexRange(newestIndex, oldestIndex)
end

function ZO_GuildHistoryEventCategoryData:GetEventsInIndexRange(newestIndex, oldestIndex)
    local numEvents = self:GetNumEvents()
    assert((newestIndex <= oldestIndex) and (oldestIndex <= numEvents))
    local events = {}
    for eventIndex = newestIndex, oldestIndex do
        local event = self.events:AcquireObject(eventIndex)
        table.insert(events, event)
    end
    return events
end

----------------
-- Guild Data --
----------------

ZO_GuildHistoryGuildData = ZO_InitializingObject:Subclass()

function ZO_GuildHistoryGuildData:Initialize(guildId)
    self.guildId = guildId
    self.eventCategories = {}

    for eventCategory = GUILD_HISTORY_EVENT_CATEGORY_ITERATION_BEGIN, GUILD_HISTORY_EVENT_CATEGORY_ITERATION_END do
        self.eventCategories[eventCategory] = ZO_GuildHistoryEventCategoryData:New(self, eventCategory)
    end
end

function ZO_GuildHistoryGuildData:GetId()
    return self.guildId
end

function ZO_GuildHistoryGuildData:GetEventCategoryData(eventCategory)
    return self.eventCategories[eventCategory]
end