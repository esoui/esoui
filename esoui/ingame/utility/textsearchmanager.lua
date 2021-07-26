
function ZO_FilterTargetDescriptor_GetQuestItemIdList()
    local questItemList = {}
    for questIndex = 1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(questIndex) then
            for toolIndex = 1, GetQuestToolCount(questIndex) do
                local questItemId = select(5, GetQuestToolInfo(questIndex, toolIndex))
                if questItemId ~= 0 then
                    table.insert(questItemList, questItemId)
                end
            end

            for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
                for conditionIndex = 1, GetJournalQuestNumConditions(questIndex, stepIndex) do
                    local questItemId = select(4, GetQuestItemInfo(questIndex, stepIndex, conditionIndex))
                    if questItemId ~= 0 then
                        table.insert(questItemList, questItemId)
                    end
                end
            end
        end
    end
    return questItemList
end

--
--[[ Text Search Manager ]]--
--

ZO_TextSearchManager = ZO_InitializingCallbackObject:Subclass()

function ZO_TextSearchManager:Initialize()
    self.contextSearches = {}
    self.pendingContextSearches = {}

    local function OnTextSearchFilterComplete(eventId, ...)
        self:OnBackgroundListFilterComplete(...)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_TextSearchManager", EVENT_BACKGROUND_LIST_FILTER_COMPLETE, OnTextSearchFilterComplete)
end

function ZO_TextSearchManager.CanFilterByText(text)
    -- Very broad searches have bad performance implications: The search itself is asynchronous (and snappy), but updating UI to reflect the search is not
    return text ~= nil and ZoUTF8StringLength(text) >= 2
end

--[[
    Expected format for filterTargetDescriptors:
    filterTargetDescriptors =
    {
        [<FilterTarget>] =
        {
            searchFilterList =
            {
                BACKGROUND_LIST_FILTER_TYPE_<FilterType>,
                ...
            },
            primaryKeys =
            {
                <List of keys> (ie. BAG_BACKPACK, BAG_BANK for FILTER_TARGET_BAG_SLOT or filterFunction() for filter like slottable in FILTER_TARGET_COLLECTIBLE)
            },
        },
    }
    This function will also override the filter target descriptors for a context that already exists.
]]--
function ZO_TextSearchManager:SetupContextTextSearch(context, filterTargetDescriptors)
    local contextSearch = self.contextSearches[context]
    if not contextSearch then
        contextSearch = {}
        self.contextSearches[context] = contextSearch
    end

    contextSearch.filterTargetDescriptors = filterTargetDescriptors

    contextSearch.isDirty = true
    contextSearch.isActive = false
    contextSearch.searchText = ""
    contextSearch.inProgressSearchTasks = {}
    contextSearch.searchResults = {}
end

function ZO_TextSearchManager:ActivateTextSearch(context)
    if context == nil then
        return
    end

    for currentContext, contextSearch in pairs(self.contextSearches) do
        if contextSearch.isActive and currentContext ~= context then
            internalassert(false, string.format("Activating text search %s, but text search %s is already active, there should only ever be one context search active at a time!", context, currentContext))
        end
    end

    if self.contextSearches[context] and not self.contextSearches[context].isActive then
        self.contextSearches[context].isActive = true
        self:CleanSearch(context)
        return true
    else
        return false
    end
end

function ZO_TextSearchManager:DeactivateTextSearch(context)
    if self:IsActiveTextSearch(context) then
        self.contextSearches[context].isActive = false
        return true
    else
        return false
    end
end

function ZO_TextSearchManager:IsActiveTextSearch(context)
    return self.contextSearches[context] and self.contextSearches[context].isActive
end

function ZO_TextSearchManager:IsFilterTargetInContext(context, filterTarget)
    local contextSearch = self.contextSearches[context]
    if contextSearch then
        return contextSearch.filterTargetDescriptors[filterTarget] ~= nil
    end
    return false
end

function ZO_TextSearchManager:GetSearchText(context)
    return self.contextSearches[context] and self.contextSearches[context].searchText or ""
end

function ZO_TextSearchManager:SetSearchText(context, searchText)
    local contextSearch = self.contextSearches[context]
    if contextSearch then
        searchText = searchText or ""
        if contextSearch.searchText ~= searchText then
            contextSearch.searchText = searchText
            contextSearch.isDirty = true

            if self:IsActiveTextSearch(context) then
                self:ExecuteSearch(context)
            end
        end
    end
end

function ZO_TextSearchManager:MarkDirtyByFilterTargetAndPrimaryKey(filterTarget, primaryKey, shouldSuppressSearchUpdate)
    for context, contextSearch in pairs(self.contextSearches) do
        local filterTargetData = contextSearch.filterTargetDescriptors[filterTarget]
        if filterTargetData then
            local primaryKeys = filterTargetData.primaryKeys
            if type(primaryKeys) == "function" then
                primaryKeys = primaryKeys()
            end

            for _, key in ipairs(primaryKeys) do
                if key == primaryKey then
                    contextSearch.isDirty = true
                    self:CleanSearch(context, shouldSuppressSearchUpdate)
                    break
                end
            end
        end
    end
end

function ZO_TextSearchManager:CleanSearch(context, shouldSuppressSearchUpdate)
    local contextSearch = self.contextSearches[context]
    if not contextSearch then
        return
    end

    if contextSearch.isDirty and self:IsActiveTextSearch(context) then
        if not shouldSuppressSearchUpdate then
            self:ExecuteSearch(context)
        else
            self.pendingContextSearches[context] = true
        end
    end
end

function ZO_TextSearchManager:ClearPendingContextSearches()
    self.pendingContextSearches = {}
end

function ZO_TextSearchManager:ExecutePendingContextSearches()
    for context, _ in pairs(self.pendingContextSearches) do
         self:ExecuteSearch(context)
    end
    self:ClearPendingContextSearches()
end

function ZO_TextSearchManager:ExecuteSearch(context)
    local contextSearch = self.contextSearches[context]
    if not contextSearch then
        return
    end

    --Cancel any in progress filtering so we can do a new one
    for _, searchTaskId in pairs(contextSearch.inProgressSearchTasks) do
        DestroyBackgroundListFilter(searchTaskId)
    end
    ZO_ClearTable(contextSearch.inProgressSearchTasks)

    ZO_ClearTable(contextSearch.searchResults)

    --If we have filter text then create the tasks
    if ZO_TextSearchManager.CanFilterByText(contextSearch.searchText) then
        for filterTarget, filterData in pairs(contextSearch.filterTargetDescriptors) do
            local searchTaskId = CreateBackgroundListFilter(filterTarget, contextSearch.searchText)
            for _, searchFilter in ipairs(filterData.searchFilterList) do
                AddBackgroundListFilterType(searchTaskId, searchFilter)
            end
            contextSearch.inProgressSearchTasks[filterTarget] = searchTaskId

            local primaryKeys = filterData.primaryKeys
            if type(filterData.primaryKeys) == "function" then
                primaryKeys = filterData.primaryKeys()
            end

            for _, primaryKey in ipairs(primaryKeys) do
                if filterTarget == BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT then
                    -- Filter Target is a Bag Slot Filter, primary key is a bagId
                    for slotIndex in ZO_IterateBagSlots(primaryKey) do
                        AddBackgroundListFilterEntry(searchTaskId, primaryKey, slotIndex)
                    end
                elseif filterTarget == BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID then
                    -- Filter Target is a Quest Item Filter, primary key is a questItemId
                    AddBackgroundListFilterEntry(searchTaskId, primaryKey)
                elseif filterTarget == BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID then
                    -- Filter Target is a Collections Filter, primary key is a collectibleId
                    AddBackgroundListFilterEntry(searchTaskId, primaryKey)
                end
            end
        end

        for _, searchTaskId in pairs(contextSearch.inProgressSearchTasks) do
            StartBackgroundListFilter(searchTaskId)
        end
    else
        contextSearch.isDirty = false
        self:FireCallbacks("UpdateSearchResults", context)
    end
end

function ZO_TextSearchManager:GetInProgressTaskInfoById(taskId)
    for context, searchData in pairs(self.contextSearches) do
        for filterTarget, searchTaskId in pairs(searchData.inProgressSearchTasks) do
            if searchTaskId == taskId then
                return context, filterTarget
            end
        end
    end

    return nil
end

function ZO_TextSearchManager:OnBackgroundListFilterComplete(taskId)
    local context, filterTarget = self:GetInProgressTaskInfoById(taskId)
    local contextSearch = self.contextSearches[context]
    if contextSearch then
        --Mark that it was completed.
        contextSearch.inProgressSearchTasks[filterTarget] = nil

        local searchResults = contextSearch.searchResults[filterTarget]
        if not searchResults then
            searchResults = {}
            contextSearch.searchResults[filterTarget] = searchResults
        end

        for filterResultIndex = 1, GetNumBackgroundListFilterResults(taskId) do
            local primaryKey, secondaryKey = GetBackgroundListFilterResult(taskId, filterResultIndex)

            if filterTarget == BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT then
                if not searchResults[primaryKey] then
                    searchResults[primaryKey] = {}
                end

                searchResults[primaryKey][secondaryKey] = true
            elseif filterTarget == BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID then
                searchResults[primaryKey] = true
            elseif filterTarget == BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID then
                searchResults[primaryKey] = true
            end
        end

        if ZO_IsTableEmpty(contextSearch.inProgressSearchTasks) then
            contextSearch.isDirty = false
            self:FireCallbacks("UpdateSearchResults", context)
        end

        DestroyBackgroundListFilter(taskId)
    end
end

function ZO_TextSearchManager:IsItemInSearchTextResults(context, filterTarget, primaryKey, secondaryKey)
    local contextSearch = self.contextSearches[context]
    if not contextSearch or not ZO_TextSearchManager.CanFilterByText(contextSearch.searchText) then
        return true
    end

    local searchResults = contextSearch.searchResults[filterTarget]
    if searchResults then
        if primaryKey and secondaryKey then
            return searchResults[primaryKey] and searchResults[primaryKey][secondaryKey]
        elseif primaryKey then
            return searchResults[primaryKey]
        end
    end

    return false
end

TEXT_SEARCH_MANAGER = ZO_TextSearchManager:New()
