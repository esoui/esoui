ZO_TextSearchObject = ZO_InitializingObject:Subclass()

function ZO_TextSearchObject:Initialize(searchContext, searchEditBox)
    self.searchContext = searchContext
    self.searchEditBox = searchEditBox

    self:SetupContextTextSearch()
    self:SetupOnTextChangedHandler()
end

function ZO_TextSearchObject:SetupContextTextSearch()
    -- Can be overridden
    -- Context can be setup elsewhere in the code to be used here.
    -- The TEXT_SEARCH_MANAGER function will override the filter target descriptors for a context that already exists.
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

        TEXT_SEARCH_MANAGER:SetupContextTextSearch(self.searchContext, filterTargetDescriptor)
    ]]--
end

function ZO_TextSearchObject:SetupOnTextChangedHandler()
    local currentSearchEditBox = self:GetSearchEditBox()
    if currentSearchEditBox then
        local function OnTextSearchTextChanged(editBox)
            self:OnTextSearchTextChanged(editBox)
        end
        currentSearchEditBox:SetHandler("OnTextChanged", OnTextSearchTextChanged)
    end
end

function ZO_TextSearchObject:SetTextSearchContext(context)
    self.searchContext = context
end

function ZO_TextSearchObject:SetSearchEditBox(searchEditBox)
    self.searchEditBox = searchEditBox
    self:SetupOnTextChangedHandler()
end

function ZO_TextSearchObject:GetSearchEditBox()
    return self.searchEditBox
end

function ZO_TextSearchObject:SetSearchCriteria(filterType, context, editBox)
    local previousContextActive = TEXT_SEARCH_MANAGER:IsActiveTextSearch(self.searchContext)
    if previousContextActive then
        self:DeactivateTextSearch()
    end
    self.searchFilterType = filterType
    self.searchContext = context
    if editBox then
        self:SetSearchEditBox(editBox)
    end
    if previousContextActive then
        self:ActivateTextSearch()
    end
end

function ZO_TextSearchObject:OnTextSearchTextChanged(editBox)
    if self.searchContext then
        TEXT_SEARCH_MANAGER:SetSearchText(self.searchContext, editBox:GetText())
    end
end

function ZO_TextSearchObject:OnUpdateSearchResults()
    -- To be overridden
end

function ZO_TextSearchObject:SetSearchText()
    if self.searchContext then
        TEXT_SEARCH_MANAGER:SetSearchText(self.searchContext, self:GetTextSearchText())
    end
end

function ZO_TextSearchObject:GetTextSearchText()
    local searchEditBox = self:GetSearchEditBox()
    if searchEditBox then
        return searchEditBox:GetText()
    end
    return ""
end

function ZO_TextSearchObject:UpdateSearchText()
    if self.searchEditBox and self.searchContext then
        self.searchEditBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(self.searchContext))
    end
end

function ZO_TextSearchObject:ActivateTextSearch()
    if self.searchContext and not TEXT_SEARCH_MANAGER:IsActiveTextSearch(self.searchContext) then
        self:UpdateSearchText()

        local function OnTextSearchResults()
            self.dirty = true
            self:OnUpdateSearchResults()
        end
        self.onTextSearchResults = OnTextSearchResults

        TEXT_SEARCH_MANAGER:ActivateTextSearch(self.searchContext)
        TEXT_SEARCH_MANAGER:RegisterCallback("UpdateSearchResults", OnTextSearchResults)
    end
end

function ZO_TextSearchObject:DeactivateTextSearch()
    if self.searchContext then
        TEXT_SEARCH_MANAGER:DeactivateTextSearch(self.searchContext)
        TEXT_SEARCH_MANAGER:UnregisterCallback("UpdateSearchResults", self.onTextSearchResults)
    end
end

function ZO_TextSearchObject:HasSearchFilter()
    return TEXT_SEARCH_MANAGER:HasSearchFilter(self.searchContext)
end

function ZO_TextSearchObject:SetSearchFilterType(searchFilterType)
    self.searchFilterType = searchFilterType
end

function ZO_TextSearchObject:IsDataInSearchTextResults(dataId)
    if self.searchContext and self.searchFilterType then
        return TEXT_SEARCH_MANAGER:IsDataInSearchTextResults(self.searchContext, self.searchFilterType, dataId)
    end
    -- Return true for every result if we don't have a context search
    return true
end