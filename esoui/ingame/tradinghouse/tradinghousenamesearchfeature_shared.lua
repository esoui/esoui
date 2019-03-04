ZO_TradingHouseNameSearchFeature_Shared = ZO_CallbackObject:Subclass()

function ZO_TradingHouseNameSearchFeature_Shared:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseNameSearchFeature_Shared:Initialize()
end

function ZO_TradingHouseNameSearchFeature_Shared:GetSearchText()
    assert(false, "override me")
end

function ZO_TradingHouseNameSearchFeature_Shared:SetSearchText(searchText)
    assert(false, "override me")
end

function ZO_TradingHouseNameSearchFeature_Shared:ResetSearch()
    self:SetSearchText("")
end

function ZO_TradingHouseNameSearchFeature_Shared:ApplyToSearch(search, isPerformingSearch)
    if not isPerformingSearch or self:IsSearchTextEmpty() then
        return
    end

    local numResults = GetNumMatchTradingHouseItemNamesResults(self.completedItemNameMatchId)
    if not numResults then
        return
    end

    local hashes = {}
    local maxExactTerms = GetMaxTradingHouseFilterExactTerms(TRADING_HOUSE_FILTER_TYPE_NAME_HASH)
    for hashIndex = 1, math.min(numResults, maxExactTerms) do
        local _, hash = GetMatchTradingHouseItemNamesResult(self.completedItemNameMatchId, hashIndex)
        hashes[hashIndex] = hash
    end
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_NAME_HASH, hashes)
end

function ZO_TradingHouseNameSearchFeature_Shared:SaveToTable(searchTable)
    searchTable["NameSearch"] = self:GetSearchText()
end

function ZO_TradingHouseNameSearchFeature_Shared:LoadFromTable(searchTable)
    local savedSearchText = searchTable["NameSearch"]
    if type(savedSearchText) == 'string' then
        self:SetSearchText(savedSearchText)
    end
end

function ZO_TradingHouseNameSearchFeature_Shared:GetDisplayName()
    return GetString("SI_TRADINGHOUSEFEATURECATEGORY", TRADING_HOUSE_FEATURE_CATEGORY_NAME_SEARCH)
end

function ZO_TradingHouseNameSearchFeature_Shared:GetDescriptionFromTable(searchTable)
    local savedSearchText = searchTable["NameSearch"]
    if type(savedSearchText) == 'string' and savedSearchText ~= "" then
        return searchTable["NameSearch"]
    end
    return nil
end

function ZO_TradingHouseNameSearchFeature_Shared:LoadFromItem(itemLink)
    local searchText = GetItemLinkTradingHouseItemSearchName(itemLink)
    if searchText ~= "" then
        searchText = ZO_TradingHouseNameSearchFeature_Shared.MakeExactSearchText(searchText)
        self:SetSearchText(searchText)
    end
end

function ZO_TradingHouseNameSearchFeature_Shared.MakeExactSearchText(searchText)
    return string.format("%s%s%s", GetString(SI_TRADING_HOUSE_EXACT_NAME_SEARCH_START_DELIMITER), searchText, GetString(SI_TRADING_HOUSE_EXACT_NAME_SEARCH_END_DELIMITER))
end

function ZO_TradingHouseNameSearchFeature_Shared:IsNameMatchTruncated()
    local numResults = GetNumMatchTradingHouseItemNamesResults(self.completedItemNameMatchId)
    local maxExactTerms = GetMaxTradingHouseFilterExactTerms(TRADING_HOUSE_FILTER_TYPE_NAME_HASH)
    return numResults ~= nil and numResults > maxExactTerms
end

function ZO_TradingHouseNameSearchFeature_Shared:IsNameMatchValid()
    if self:IsSearchTextEmpty() then
        -- no name match
        return true
    end

    if self:HasPendingNameMatch() then
        -- for now, assume the match is valid. We will try again after the match is complete
        return true
    end

    if not self:IsSearchTextLongEnough() then
        return false, TRADING_HOUSE_SEARCH_OUTCOME_NAME_SEARCH_TOO_SHORT
    end

    if not self:HasMatchedAtLeastOneName() then
        return false, TRADING_HOUSE_SEARCH_OUTCOME_NO_NAME_MATCHES
    end

    return true
end

function ZO_TradingHouseNameSearchFeature_Shared:HasPendingNameMatch()
    return self.pendingItemNameMatchId ~= nil
end

function ZO_TradingHouseNameSearchFeature_Shared:HasMatchedAtLeastOneName()
    local numResults = GetNumMatchTradingHouseItemNamesResults(self.completedItemNameMatchId)
    return numResults ~= nil and numResults ~= 0
end

function ZO_TradingHouseNameSearchFeature_Shared:GetCompletedItemNameMatchId()
    return self.completedItemNameMatchId
end

function ZO_TradingHouseNameSearchFeature_Shared:IsSearchTextEmpty()
    return self:GetSearchText() == ""
end

function ZO_TradingHouseNameSearchFeature_Shared:IsSearchTextLongEnough()
    local minLetters = GetMinLettersInTradingHouseItemNameForCurrentLanguage()
    local length = ZoUTF8StringLength(self:GetSearchText())
    return length >= minLetters
end

function ZO_TradingHouseNameSearchFeature_Shared:MarkFiltersDirty()
    self:CancelPendingNameMatch()
    self:ClearCompletedNameMatch()
    if self:IsSearchTextLongEnough() then
        self:StartNameMatch()
    end
end

function ZO_TradingHouseNameSearchFeature_Shared:StartNameMatch()
    self.pendingItemNameMatchId = MatchTradingHouseItemNames(self:GetSearchText())
end

function ZO_TradingHouseNameSearchFeature_Shared:CancelPendingNameMatch()
    if self.pendingItemNameMatchId then
        CancelMatchTradingHouseItemNames(self.pendingItemNameMatchId)
        self.pendingItemNameMatchId = nil
    end
end

function ZO_TradingHouseNameSearchFeature_Shared:ClearCompletedNameMatch()
    self.completedItemNameMatchId = nil
end

function ZO_TradingHouseNameSearchFeature_Shared:OnNameMatchComplete(id, numResults)
    if id == self.pendingItemNameMatchId then
        self.pendingItemNameMatchId = nil
        self.completedItemNameMatchId = id
        self:FireCallbacks("OnNameMatchComplete")
    else
        -- Clear existing name match: whenever a name match completes we
        -- destroy the data for the last completed name match, so it's no longer
        -- valid
        self:ClearCompletedNameMatch()
    end
end
