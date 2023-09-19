ZO_TradingHouseSearchCategoryFeature_Gamepad = ZO_TradingHouseSearchCategoryFeature_Shared:Subclass()

function ZO_TradingHouseSearchCategoryFeature_Gamepad:New(...)
    return ZO_TradingHouseSearchCategoryFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Gamepad:Initialize()
    self.headers = {}
    self.headerToCategoriesMap = {}
    self.featureKeyToFeatureObjectMap = {}

    self.selectedHeader = nil
    self.selectedCategoryParams = nil
    self.selectedSubcategoryKey = nil

    local lastHeader = nil
    for _, categoryParams in ipairs(ZO_TRADING_HOUSE_CATEGORY_PARAMS_LIST) do
        local header = categoryParams:GetHeader()
        if lastHeader ~= header then
            table.insert(self.headers, header)
            self.headerToCategoriesMap[header] = {}
            lastHeader = header
        end

        table.insert(self.headerToCategoriesMap[header], categoryParams)

        for _, featureKey in categoryParams:FeatureKeyIterator() do
            local feature = self.featureKeyToFeatureObjectMap[featureKey]
            if not feature then
                feature = ZO_TradingHouse_CreateGamepadFeature(featureKey)
                self.featureKeyToFeatureObjectMap[featureKey] = feature
            end
        end
    end
end

do
    local function GetCategoryNarrationText(entryData, entryControl)
        if entryData.dropDown then
            return entryData.dropDown:GetNarrationText()
        end
    end

    function ZO_TradingHouseSearchCategoryFeature_Gamepad:GetOrCreateHeaderEntryData()
        if self.headerEntryData then
            return self.headerEntryData
        end

        local function OnHeaderChanged(dropDown, entryName, entry, selectionChanged)
            if self.selectedHeader ~= entry.header then
                local headerFirstCategoryParams = self.headerToCategoriesMap[entry.header][1]
                local categoryFirstSubcategoryKey = headerFirstCategoryParams:GetSubcategoryKey(1)
                self:SelectCategoryParams(headerFirstCategoryParams, categoryFirstSubcategoryKey)
            end
        end

        local function MatchesSelectedHeader(entry)
            return entry.header == self.selectedHeader
        end

        local function SetupHeaderDropdown(dropdown)
            dropdown:ClearItems()

            for _, header in ipairs(self.headers) do
                local headerName = GetString("SI_TRADINGHOUSECATEGORYHEADER", header)
                local entry = dropdown:CreateItemEntry(headerName, OnHeaderChanged)
                entry.header = header
                dropdown:AddItem(entry)
            end

            if self.selectedHeader then
                dropdown:SetSelectedItemByEval(MatchesSelectedHeader)
            else
                dropdown:SelectFirstItem()
            end
        end

        local entryData = ZO_GamepadEntryData:New("GuildStoreHeader")
        entryData.setupCallback = SetupHeaderDropdown
        entryData:SetHeader(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_CATEGORY))
        entryData.narrationText = GetCategoryNarrationText
        self.headerEntryData = entryData
        return entryData
    end

    function ZO_TradingHouseSearchCategoryFeature_Gamepad:AddHeaderEntry(itemList)
        itemList:AddEntryWithHeader("ZO_GamepadGuildStoreBrowseDropdownTemplate", self:GetOrCreateHeaderEntryData())
    end

    function ZO_TradingHouseSearchCategoryFeature_Gamepad:GetOrCreateCategoryEntryData()
        if self.categoryEntryData then
            return self.categoryEntryData
        end

        local function OnCategorySelected(_, entryName, entry, _)
            if self.selectedCategoryParams ~= entry.categoryParams then
                local categoryFirstSubcategoryKey = entry.categoryParams:GetSubcategoryKey(1)
                self:SelectCategoryParams(entry.categoryParams, categoryFirstSubcategoryKey)
            end
        end

        local function MatchesSelectedCategory(entry)
            return entry.categoryParams == self.selectedCategoryParams
        end

        local function SetupCategoryComboBox(comboBox)
            comboBox:ClearItems()
            local selectOld = false
            local categories = self.headerToCategoriesMap[self.selectedHeader]
            for _, categoryParams in ipairs(categories) do
                local categoryName = categoryParams:GetFormattedName()
                local entry = comboBox:CreateItemEntry(categoryName, OnCategorySelected)
                entry.categoryParams = categoryParams
                if categoryParams == self.selectedCategoryParams then
                    selectOld = true
                end
                comboBox:AddItem(entry)
            end

            if selectOld then
                comboBox:SetSelectedItemByEval(MatchesSelectedCategory)
            else
                comboBox:SelectFirstItem()
            end
        end

        local entryData = ZO_GamepadEntryData:New("GuildStoreCategory")
        entryData.setupCallback = SetupCategoryComboBox
        entryData.narrationText = GetCategoryNarrationText
        self.categoryEntryData = entryData
        return entryData
    end

    function ZO_TradingHouseSearchCategoryFeature_Gamepad:AddCategoryEntry(itemList)
        local categories = self.headerToCategoriesMap[self.selectedHeader]

        if #categories > 1 then
            itemList:AddEntry("ZO_GamepadGuildStoreBrowseDropdownTemplate", self:GetOrCreateCategoryEntryData())
        else
            -- Since aren't creating the dropdown, we need to manually update the key to the correct value
            -- instead of relying on the OnCategorySelected callback
            self.selectedCategoryParams = categories[1]
        end
    end

    function ZO_TradingHouseSearchCategoryFeature_Gamepad:GetOrCreateSubcategoryEntryData(itemList)
        if self.subcategoryEntryData then
            return self.subcategoryEntryData
        end

        local function OnSubcategorySelected(_, entryName, entry, _)
            if self.selectedSubcategoryKey ~= entry.subcategoryKey then
                self:SelectCategoryParams(self.selectedCategoryParams, entry.subcategoryKey)
            end
        end

        local function MatchesSelectedSubcategory(entry)
            return entry.subcategoryKey == self.selectedSubcategoryKey
        end

        local function SetupSubcategory(dropdown)
            local categoryParams = self:GetCategoryParams()
            dropdown:ClearItems()
            local selectOld = false
            for subcategoryIndex = 1, categoryParams:GetNumSubcategories() do
                local key = categoryParams:GetSubcategoryKey(subcategoryIndex)
                local name = categoryParams:GetSubcategoryName(subcategoryIndex)

                local entry = dropdown:CreateItemEntry(name, OnSubcategorySelected)
                entry.subcategoryKey = key
                if key == self.selectedSubcategoryKey then
                    selectOld = true
                end
                dropdown:AddItem(entry)
            end

            if selectOld then
                dropdown:SetSelectedItemByEval(MatchesSelectedSubcategory)
            else
                dropdown:SelectFirstItem()
            end
        end

        local entryData = ZO_GamepadEntryData:New("GuildStoreSubcategory")
        entryData.setupCallback = SetupSubcategory
        entryData.narrationText = GetCategoryNarrationText
        self.subcategoryEntryData = entryData
        return entryData
    end
end

function ZO_TradingHouseSearchCategoryFeature_Gamepad:AddSubcategoryEntry(itemList)
    if self.selectedCategoryParams and self.selectedCategoryParams:GetNumSubcategories() > 1 then
        itemList:AddEntry("ZO_GamepadGuildStoreBrowseDropdownTemplate", self:GetOrCreateSubcategoryEntryData())
    else
        -- Since aren't creating the dropdown, we need to manually update the key to the correct value
        -- instead of relying on the OnSubCategorySelected callback
        self.selectedSubcategoryKey = "AllSubcategories"
    end
end

function ZO_TradingHouseSearchCategoryFeature_Gamepad:AddEntries(itemList)
    self:AddHeaderEntry(itemList)
    self:AddCategoryEntry(itemList)

    local categoryParams = self.selectedCategoryParams

    if categoryParams then
        self:AddSubcategoryEntry(itemList)

        for _, featureKey in categoryParams:FeatureKeyIterator() do
            local feature = self.featureKeyToFeatureObjectMap[featureKey]
            feature:AddEntries(itemList)
        end
    end
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Gamepad:GetCategoryParams()
    return self.selectedCategoryParams
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Gamepad:GetSubcategoryKey()
    return self.selectedSubcategoryKey
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Gamepad:GetFeatureForKey(featureKey)
    return self.featureKeyToFeatureObjectMap[featureKey]
end

-- Override
function ZO_TradingHouseSearchCategoryFeature_Gamepad:SelectCategoryParams(categoryParams, subcategoryKey)
    if categoryParams then
        self.selectedHeader = categoryParams:GetHeader()
        self.selectedCategoryParams = categoryParams

        if subcategoryKey then
            self.selectedSubcategoryKey = subcategoryKey
        end

        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end
end
