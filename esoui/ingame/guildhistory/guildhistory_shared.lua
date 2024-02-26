local GUILD_EVENT_DATA = 1
local ENTRIES_PER_PAGE = 100

ZO_GuildHistory_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_GuildHistory_Shared:Initialize(control, alwaysAnimateFragment)
    self.control = control
    control.object = self

    ZO_DeferredInitializingObject.Initialize(self, ZO_FadeSceneFragment:New(control, alwaysAnimateFragment))
end

-- Begin overriden from ZO_DeferredInitializingObject --
function ZO_GuildHistory_Shared:OnDeferredInitialize()
    self.refreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_IMMEDIATELY)
    self.refreshGroup:AddDirtyState("ListData", function()
        self:RefreshData()
    end)
    self.refreshGroup:AddDirtyState("ListFilters", function()
        self:RefreshFilters()
    end)
    self.refreshGroup:SetActive(function()
        return self:IsShowing()
    end)

    self.entryDataPool = ZO_ObjectPool:New(ZO_EntryData, ZO_ObjectPool_DefaultResetObject)
    self.cachedEventIndicesByPage = {}
    self:InitializeControls()
    self:InitializeKeybindDescriptors()

    GUILD_HISTORY_MANAGER:RegisterCallback("CategoryUpdated", function(...) self:OnCategoryUpdated(...) end)
end

function ZO_GuildHistory_Shared:OnShowing()
    self.refreshGroup:TryClean()
    -- TODO Guild History: Implement
end

function ZO_GuildHistory_Shared:OnHiding()
    self:RemoveKeybinds()
end
-- End overriden from ZO_DeferredInitializingObject --

function ZO_GuildHistory_Shared:InitializeSortFilterList(rowTemplate, rowHeight)
    ZO_ScrollList_AddDataType(self.list, GUILD_EVENT_DATA, rowTemplate, rowHeight, function(...) self:SetupEventRow(...) end)
end

function ZO_GuildHistory_Shared:InitializeControls()
    local control = self.control
    self.footer = ZO_PagedListFooter:New(control:GetNamedChild("Footer"))
    self.loadingIcon = control:GetNamedChild("LoadingIcon")
end

ZO_GuildHistory_Shared:MUST_IMPLEMENT("InitializeKeybindDescriptors")

do
    local REQUEST_LOOKUP = {}

    local function GetRequest(guildId, eventCategory)
        local requestsByGuild = REQUEST_LOOKUP[guildId]
        if not requestsByGuild then
            requestsByGuild = {}
            REQUEST_LOOKUP[guildId] = requestsByGuild
        end

        local requestForEventCategory = requestsByGuild[eventCategory]
        if not requestForEventCategory then
            requestForEventCategory = ZO_GuildHistoryRequest:New(guildId, eventCategory)
            requestsByGuild[eventCategory] = requestForEventCategory
        end

        return requestForEventCategory
    end

    function ZO_GuildHistory_Shared:GetRequestForSelection()
        return GetRequest(self.guildId, self.selectedEventCategory)
    end
end

function ZO_GuildHistory_Shared:SetGuildId(guildId)
    if self.guildId ~= guildId then
        self.guildId = guildId
        if self.initialized then
            local SUPPRESS_REFRESH = true
            self:SetCurrentPage(1, SUPPRESS_REFRESH)
            self:SetEmptyText(ZO_GuildHistory_Manager.GetNoEntriesText(self.selectedEventCategory, self.selectedSubcategoryIndex, self.guildId))
            self.refreshGroup:MarkDirty("ListData")
        end
        return true
    end
    return false
end

function ZO_GuildHistory_Shared:SetSelectedEventCategory(eventCategory, subcategoryIndex)
    local oldSelectedCategory = self.selectedEventCategory
    self.selectedEventCategory = eventCategory
    self.selectedSubcategoryIndex = subcategoryIndex
    local SUPPRESS_REFRESH = true
    self:SetCurrentPage(1, SUPPRESS_REFRESH)

    self:SetEmptyText(ZO_GuildHistory_Manager.GetNoEntriesText(self.selectedEventCategory, self.selectedSubcategoryIndex, self.guildId))

    --if it's the same category we can just mess with the filter instead of rebuilding the whole list
    if oldSelectedCategory == self.selectedEventCategory then
        ZO_ClearTable(self.cachedEventIndicesByPage) -- Reset the cache because we've changed subcategory
        self.refreshGroup:MarkDirty("ListFilters")
    else
        self.refreshGroup:MarkDirty("ListData")
    end

    self:ResetToTop()
end

function ZO_GuildHistory_Shared:SetCurrentPage(newCurrentPage, suppressRefresh)
    if self.currentPage ~= newCurrentPage then
        self.currentPage = newCurrentPage
        if not suppressRefresh then
            self.refreshGroup:MarkDirty("ListFilters")
            self:ResetToTop()
        end
        self.footer:SetPageText(newCurrentPage)
    end
end

function ZO_GuildHistory_Shared:ShowPreviousPage()
    if self.currentPage > 1 then
        self:SetCurrentPage(self.currentPage - 1)
    end
end

function ZO_GuildHistory_Shared:ShowNextPage()
    if self.hasNextPage then
        self:SetCurrentPage(self.currentPage + 1)
    end
end

ZO_GuildHistory_Shared:MUST_IMPLEMENT("ResetToTop")

function ZO_GuildHistory_Shared:OnCategoryUpdated(categoryData, flags)
    if self.selectedEventCategory == categoryData:GetEventCategory() then
        if ZO_FlagHelpers.MaskHasFlag(flags, GUILD_HISTORY_CATEGORY_UPDATE_FLAG_REFRESHED) then
            -- A change on the level of permissions happened, don't try to keep your place
            local SUPPRESS_REFRESH = true
            self:SetCurrentPage(1, SUPPRESS_REFRESH)
            self.refreshGroup:MarkDirty("ListData")
            self:ResetToTop()
        elseif ZO_FlagHelpers.MaskHasFlag(flags, GUILD_HISTORY_CATEGORY_UPDATE_FLAG_NEW_INFO) then
            -- New events came in, so we'll retain our page and scroll and move everything down as needed
            self.refreshGroup:MarkDirty("ListData")
        elseif ZO_FlagHelpers.MaskHasFlag(flags, GUILD_HISTORY_CATEGORY_UPDATE_FLAG_RESPONSE_RECEIVED) then
            local request = self:GetRequestForSelection()
            if not request:IsComplete() and self:IsShowing() then
                --We got a response to a manual request, but had no new events, so make another request
                local QUEUE_IF_ON_COOLDOWN = true
                local readyState = request:RequestMoreEvents(QUEUE_IF_ON_COOLDOWN)
            end
            self.refreshGroup:MarkDirty("ListFilters")
        end

        self:UpdateKeybinds()
    end
end

function ZO_GuildHistory_Shared:BuildMasterList()
    if self.guildId and self.selectedEventCategory then
        -- Even if we made the initial requests, we might have some info already from pushes, so show those right away
        local guildData = GUILD_HISTORY_MANAGER:GetGuildData(self.guildId)
        local eventCategoryData = guildData:GetEventCategoryData(self.selectedEventCategory)
        local oldestEventIndexWithoutGaps = eventCategoryData:GetOldestEventIndexForUpToDateEventsWithoutGaps()
        --Only pull events up to the first gap
        if oldestEventIndexWithoutGaps then
            self.masterList = eventCategoryData:GetEventsInIndexRange(1, oldestEventIndexWithoutGaps)
        else
            self.masterList = {}
        end
        ZO_ClearTable(self.cachedEventIndicesByPage) -- Always reset the cache when resetting the master list

        local request = self:GetRequestForSelection()
        --Make a request for more info if we dont have enough to fill the first page
        if #self.masterList < ENTRIES_PER_PAGE and not request:IsComplete() then
            -- Need to make a request,
            -- which will come back into BuildMasterList when the response comes.
            local QUEUE_IF_ON_COOLDOWN = true
            local readyState = request:RequestMoreEvents(QUEUE_IF_ON_COOLDOWN)

            --Since more events were requested, refresh the visibility of the loading spinner
            self:RefreshLoadingSpinner()
        end
    end
end

function ZO_GuildHistory_Shared:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)
    self.entryDataPool:ReleaseAllObjects()
    self.hasNextPage = false

    --Refresh the loading spinner whenever the filters are refreshed
    self:RefreshLoadingSpinner()

    if #self.masterList == 0 then
        return
    end

    local startIndex = 1
    local numEventsToSkip = 0
    local numEventsSkipped = 0
    local cachedPageEventIndices = self.cachedEventIndicesByPage[self.currentPage]
    if cachedPageEventIndices then
        -- We've already processed this page, so we know exactly what eventIndex to start with
        startIndex = cachedPageEventIndices.startIndex
    elseif self.currentPage > 1 then
        local previousCachedPageEventIndices = self.cachedEventIndicesByPage[self.currentPage - 1]
        if previousCachedPageEventIndices then
            -- We've already processed the previous page, so we know that had the right start and the right number of events,
            -- so we know we can at least start after the last event from that page to save loops
            startIndex = previousCachedPageEventIndices.endIndex + 1
        else
            -- We don't have enough cached information to start ahead, so instead we need to skip events based on what page we're on.
            -- This is because the page indices cache will get cleared if new events come in, but that doesn't mean we reset our current page
            numEventsToSkip = (self.currentPage - 1) * ENTRIES_PER_PAGE
        end
    end

    for i = startIndex, #self.masterList do
        local data = self.masterList[i]
        if self.selectedSubcategoryIndex == data:GetUISubcategoryIndex() then
            if numEventsSkipped == numEventsToSkip then
                if #scrollData == ENTRIES_PER_PAGE then
                    self.hasNextPage = true
                    break
                end
                local entryData = self.entryDataPool:AcquireObject()
                entryData:SetDataSource(data)
                entryData:SetupAsScrollListDataEntry(GUILD_EVENT_DATA)
                table.insert(scrollData, entryData)
            else
                numEventsSkipped = numEventsSkipped + 1
            end
        end
    end

    -- If we found no events for the filter, the cache won't matter because we won't be able to refresh the filters again anyway
    if not cachedPageEventIndices and #scrollData > 0 then
        cachedPageEventIndices =
        {
            startIndex = scrollData[1]:GetEventIndex(),
            endIndex = scrollData[#scrollData]:GetEventIndex(),
        }
        self.cachedEventIndicesByPage[self.currentPage] = cachedPageEventIndices
    end
end

function ZO_GuildHistory_Shared:SetupEventRow(control, eventData, isGamepad)
    local description = eventData:GetText(isGamepad)
    local formattedTime = eventData:GetFormattedTime()

    control.descriptionLabel:SetText(description)
    control.timeLabel:SetText(formattedTime)
end

function ZO_GuildHistory_Shared:TryShowMore()
    local request = self:GetRequestForSelection()
    local readyState = request:RequestMoreEvents()
    if readyState == GUILD_HISTORY_DATA_READY_STATE_ON_COOLDOWN then
        local alertText = zo_strformat(SI_GUILD_HISTORY_REQUEST_COOLDOWN_ALERT, ZO_FormatTimeMilliseconds(GetGuildHistoryRequestMinCooldownMs(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, alertText)
    end
    --Since more events were requested, refresh the visibility of the loading spinner
    self:RefreshLoadingSpinner()
end

function ZO_GuildHistory_Shared:CanShowMore()
    if self.selectedEventCategory and not self.hasNextPage then
        local request = self:GetRequestForSelection()
        --If the request is already queued or pending, do not display the "Show More" keybind
        if request:IsRequestQueued() or request:IsRequestResponsePending() then
            return false
        else
            return not request:IsComplete()
        end
    end
    return false
end

function ZO_GuildHistory_Shared:HasPermissionsForSelection()
    return ZO_GuildHistory_Manager.HasPermissionsForCategoryAndSubcategory(self.selectedEventCategory, self.selectedSubcategoryIndex, self.guildId)
end

function ZO_GuildHistory_Shared:RefreshLoadingSpinner()
    local showLoadingSpinner = false
    if self.guildId and self.selectedEventCategory then
        local request = self:GetRequestForSelection()
        --If the request is queued or pending, we want to show the loading spinner
        if request:IsRequestQueued() or request:IsRequestQueuedFromAddon() or request:IsRequestResponsePending() then
            showLoadingSpinner = true
        end
    end

    self:SetShowLoadingSpinner(showLoadingSpinner)
end

ZO_GuildHistory_Shared:MUST_IMPLEMENT("SetShowLoadingSpinner")
