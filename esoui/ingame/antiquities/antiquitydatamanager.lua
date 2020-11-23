ZO_AntiquityDataManager = ZO_CallbackObject:Subclass()

ZO_ANTIQUITY_TYPE_INDIVIDUAL = 1
ZO_ANTIQUITY_TYPE_SET = 2

function ZO_AntiquityDataManager:New(...)
    ANTIQUITY_DATA_MANAGER = ZO_CallbackObject.New(self)
    ANTIQUITY_DATA_MANAGER:Initialize(...)
    return ANTIQUITY_DATA_MANAGER
end

function ZO_AntiquityDataManager:Initialize()
    self.antiquities = {}
    self.antiquityCategories = {}
    self.antiquitySets = {}
    self.topLevelCategories = {}

    self.highestScryableDifficulty = GetHighestScryableDifficulty()

    self:InitializeEventHandlers()
    self:RebuildAntiquities()
end

function ZO_AntiquityDataManager:InitializeEventHandlers()
    local function OnAntiquitiesUpdated()
        self:RefreshAll()
    end

    local function OnSingleAntiquityUpdated(event, antiquityId)
        self:RefreshAntiquity(antiquityId)
    end

    local function OnSingleAntiquityDigSitesUpdated(event, antiquityId)
        self:OnSingleAntiquityDigSitesUpdated(antiquityId)
    end

    local function OnAntiquitySearchResultsReady()
        self:UpdateSearchResults()
    end

    local function OnSkillsUpdated()
        self:OnSkillsUpdated()
    end

    local function OnAntiquityLeadAcquired(event, antiquityId)
        self:OnSingleAntiquityLeadAcquired(antiquityId)
    end

    local function OnAntiquityShowCodexEntry(event, antiquityId)
        self:OnAntiquityShowCodexEntry(antiquityId)
    end

    EVENT_MANAGER:RegisterForEvent("AntiquityDataManager", EVENT_ANTIQUITIES_UPDATED, OnAntiquitiesUpdated)
    EVENT_MANAGER:RegisterForEvent("AntiquityDataManager", EVENT_ANTIQUITY_UPDATED, OnSingleAntiquityUpdated)
    EVENT_MANAGER:RegisterForEvent("AntiquityDataManager", EVENT_ANTIQUITY_DIG_SITES_UPDATED, OnSingleAntiquityDigSitesUpdated)
    EVENT_MANAGER:RegisterForEvent("AntiquityDataManager", EVENT_ANTIQUITY_SEARCH_RESULTS_READY, OnAntiquitySearchResultsReady)
    EVENT_MANAGER:RegisterForEvent("AntiquityDataManager", EVENT_ANTIQUITY_LEAD_ACQUIRED, OnAntiquityLeadAcquired)
    EVENT_MANAGER:RegisterForEvent("AntiquityDataManager", EVENT_ANTIQUITY_SHOW_CODEX_ENTRY, OnAntiquityShowCodexEntry)
    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", OnSkillsUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineAdded", OnSkillsUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineRankUpdated", OnSkillsUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillProgressionUpdated", OnSkillsUpdated)
end

do
    local filterFunctions = {
        [ANTIQUITY_FILTER_SHOW_ALL] = nil,
        [ANTIQUITY_FILTER_SHOW_COMPLETED] = function(antiquityData, antiquitySetData)
            if antiquitySetData then
                return antiquitySetData:HasRecovered()
            else
                return antiquityData:HasRecovered()
            end
        end,
        [ANTIQUITY_FILTER_SHOW_IN_PROGRESS] = function(antiquityData, antiquitySetData)
            if antiquitySetData then
                return antiquitySetData:HasDiscoveredDigSites()
            else
                return antiquityData:HasDiscoveredDigSites()
            end
        end,
        [ANTIQUITY_FILTER_SHOW_NOT_STARTED] = function(antiquityData, antiquitySetData)
            if antiquitySetData then
                return antiquitySetData:HasNoDiscoveredDigSites() and not antiquitySetData:HasRecovered()
            else
                return antiquityData:HasNoDiscoveredDigSites() and not antiquityData:HasRecovered()
            end
        end,
    }

    function ZO_AntiquityDataManager:GetAntiquityFilterFunction(antiquityFilter)
        return filterFunctions[antiquityFilter]
    end
end

-- ZO_AntiquityCategory

function ZO_AntiquityDataManager:AntiquityCategoryIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.antiquityCategories, filterFunctions)
end

function ZO_AntiquityDataManager:ClearAntiquityCategories()
    ZO_ClearTable(self.antiquityCategories)
end

function ZO_AntiquityDataManager:ClearTopLevelCategories()
    ZO_ClearNumericallyIndexedTable(self.topLevelCategories)
end

function ZO_AntiquityDataManager:GetAntiquityCategoryData(antiquityCategoryId)
    return self.antiquityCategories[antiquityCategoryId]
end

-- Internal function
function ZO_AntiquityDataManager:GetOrCreateAntiquityCategoryData(antiquityCategoryId)
    if antiquityCategoryId and antiquityCategoryId ~= ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID then
        local antiquityCategoryData = self:GetAntiquityCategoryData(antiquityCategoryId)
        if not antiquityCategoryData then
            antiquityCategoryData = ZO_AntiquityCategory:New(antiquityCategoryId)
            self.antiquityCategories[antiquityCategoryId] = antiquityCategoryData
            if not antiquityCategoryData:GetParentCategoryData() then
                table.insert(self.topLevelCategories, antiquityCategoryData)
            end
        end
        return antiquityCategoryData
    end
end

function ZO_AntiquityDataManager:TopLevelAntiquityCategoryIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.topLevelCategories, filterFunctions)
end

function ZO_AntiquityDataManager:SortTopLevelAntiquityCategories()
    table.sort(self.topLevelCategories, ZO_AntiquityCategory.CompareTo)
    for _, antiquityCategoryData in ipairs(self.topLevelCategories) do
        antiquityCategoryData:SortAntiquities()
        antiquityCategoryData:SortSubcategories()
    end
end

-- ZO_AntiquitySet

function ZO_AntiquityDataManager:AntiquitySetIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.antiquitySets, filterFunctions)
end

function ZO_AntiquityDataManager:ClearAntiquitySets()
    ZO_ClearTable(self.antiquitySets)
end

function ZO_AntiquityDataManager:GetAntiquitySetData(antiquitySetId)
    return self.antiquitySets[antiquitySetId]
end

function ZO_AntiquityDataManager:GetOrCreateAntiquitySetData(antiquitySetId)
    if antiquitySetId and antiquitySetId ~= 0 then
        local antiquitySetData = self:GetAntiquitySetData(antiquitySetId)
        if not antiquitySetData then
            antiquitySetData = ZO_AntiquitySet:New(antiquitySetId)
            self.antiquitySets[antiquitySetId] = antiquitySetData
        end
        return antiquitySetData
    end
end

-- ZO_Antiquity

function ZO_AntiquityDataManager:AntiquityIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.antiquities, filterFunctions)
end

function ZO_AntiquityDataManager:ClearAntiquities()
    ZO_ClearTable(self.antiquities)
end

function ZO_AntiquityDataManager:GetAntiquityData(antiquityId)
    return self.antiquities[antiquityId]
end

function ZO_AntiquityDataManager:GetOrCreateAntiquityData(antiquityId)
    if antiquityId and antiquityId ~= 0 then
        local antiquityData = self:GetAntiquityData(antiquityId)
        if not antiquityData then
            antiquityData = ZO_Antiquity:New(antiquityId)
            self.antiquities[antiquityId] = antiquityData
        end
        return antiquityData
    end
end

function ZO_AntiquityDataManager:RefreshAntiquity(antiquityId)
    local antiquityData = self:GetAntiquityData(antiquityId)
    if antiquityData then
        antiquityData:Refresh()
        self:SortTopLevelAntiquityCategories()
        self:FireCallbacks("SingleAntiquityUpdated", antiquityData)
    else
        internalassert(false, string.format("Invalid antiquityId (%s)", tostring(antiquityId) or "nil"))
    end
end

function ZO_AntiquityDataManager:OnSingleAntiquityDigSitesUpdated(antiquityId)
    local antiquityData = self:GetAntiquityData(antiquityId)
    if antiquityData then
        antiquityData:OnDigSitesUpdated()
        self:SortTopLevelAntiquityCategories()
        self:FireCallbacks("SingleAntiquityDigSitesUpdated", antiquityData)
    else
        internalassert(false, string.format("Invalid antiquityId (%s)", tostring(antiquityId) or "nil"))
    end
end

function ZO_AntiquityDataManager:OnSingleAntiquityLeadAcquired(antiquityId)
    local antiquityData = self:GetAntiquityData(antiquityId)
    if antiquityData then
        antiquityData:OnLeadAcquired()
        self:SortTopLevelAntiquityCategories()
        self:FireCallbacks("SingleAntiquityLeadAcquired", antiquityData)
    else
        internalassert(false, string.format("Invalid antiquityId (%s)", tostring(antiquityId) or "nil"))
    end
end

function ZO_AntiquityDataManager:OnSingleAntiquityNewLeadCleared(antiquityId)
    local antiquityData = self:GetAntiquityData(antiquityId)
    if antiquityData then
        self:SortTopLevelAntiquityCategories()
        self:FireCallbacks("SingleAntiquityNewLeadCleared", antiquityData)
    else
        internalassert(false, string.format("Invalid antiquityId (%s)", tostring(antiquityId) or "nil"))
    end
end

function ZO_AntiquityDataManager:OnSkillsUpdated()
    local newHighestScryableDifficulty = GetHighestScryableDifficulty()
    if self.highestScryableDifficulty ~= newHighestScryableDifficulty then
        self:RefreshAll()
        self.highestScryableDifficulty = newHighestScryableDifficulty
    end
end

function ZO_AntiquityDataManager:OnAntiquityShowCodexEntry(antiquityId)
    if IsInGamepadPreferredMode() then
        local DONT_PUSH = false
        local antiquityData = self:GetAntiquityData(antiquityId)
        internalassert(antiquityData ~= nil)
        if antiquityData then
            ANTIQUITY_LORE_GAMEPAD:SetFromFanfare(true)
            ANTIQUITY_LORE_GAMEPAD:ShowAntiquityOrSet(antiquityData, DONT_PUSH)
        end
    else
        local categoryId = GetAntiquityCategoryId(antiquityId)
        ANTIQUITY_JOURNAL_KEYBOARD:ShowCategory(categoryId)
        ANTIQUITY_LORE_KEYBOARD:ShowAntiquity(antiquityId)
    end
end

function ZO_AntiquityDataManager:RefreshAll()
    for _, antiquityData in self:AntiquityIterator() do
        antiquityData:Refresh()
    end
    self:SortTopLevelAntiquityCategories()
    self:FireCallbacks("AntiquitiesUpdated")
end

function ZO_AntiquityDataManager:RebuildAntiquities()
    self:ClearAntiquities()
    self:ClearAntiquityCategories()
    self:ClearAntiquitySets()
    self:ClearTopLevelCategories()

    -- Load all Antiquities and their associated objects.
    local antiquityId = GetNextAntiquityId()
    while antiquityId do
        self:GetOrCreateAntiquityData(antiquityId)
        antiquityId = GetNextAntiquityId(antiquityId)
    end

    self:SortTopLevelAntiquityCategories()
    self:FireCallbacks("AntiquitiesUpdated")
end

function ZO_AntiquityDataManager:HasNewLead()
    for _, categoryData in ipairs(self.topLevelCategories) do
        if categoryData:HasNewLead() then
            return true
        end
    end
    return false
end

-- Search

function ZO_AntiquityDataManager:GetSearch()
    return self.search or ""
end

function ZO_AntiquityDataManager:GetSearchResults()
    return self.searchResults
end

function ZO_AntiquityDataManager:SetSearch(search)
    self.search = search
    StartAntiquitySearch(search)
end

function ZO_AntiquityDataManager:UpdateSearchResults()
    if #self:GetSearch() > 1 then
        local results = {}
        local numResults = GetNumAntiquitySearchResults()
        for resultIndex = 1, numResults do
            table.insert(results, GetAntiquitySearchResult(resultIndex))
        end
        self.searchResults = results
    else
        self.searchResults = nil
    end
    self:FireCallbacks("UpdateSearchResults")
end

-- Global singleton

-- The global singleton moniker is assigned by the Data Manager's constructor in order to
-- allow data objects to reference the singleton during their construction.
ZO_AntiquityDataManager:New()
