---------------
-- Dropdown  --
---------------
ZO_TradingHouseDropDownFeature_Keyboard = ZO_TradingHouseDropDownFeature_Shared:Subclass()

function ZO_TradingHouseDropDownFeature_Keyboard:New(...)
    return ZO_TradingHouseDropDownFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHouseDropDownFeature_Keyboard:GetSelectedChoiceIndex()
    return self.selectedChoiceIndex
end

-- Override
function ZO_TradingHouseDropDownFeature_Keyboard:SelectChoice(newChoiceIndex, shouldIgnoreCallbacks)
    self.dropdown:SetSelectedItemByEval(function(entry)
        return entry.choiceIndex == newChoiceIndex
    end, shouldIgnoreCallbacks)
end

function ZO_TradingHouseDropDownFeature_Keyboard:AttachToControl(dropdownControl)
    local dropdown = ZO_ComboBox_ObjectFromContainer(dropdownControl)

    dropdown:SetFont("ZoFontWinT1")
    dropdown:SetSpacing(4)
    dropdown:SetSortsItems(false)

    dropdown:ClearItems()

    local function OnChoiceSelected(_, _, entry, selectionChanged)
        self.selectedChoiceIndex = entry.choiceIndex
        if selectionChanged then
            TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
        end
    end

    for choiceIndex = 1, self.featureParams:GetNumChoices() do
        local choiceDisplayName = self.featureParams:GetChoiceDisplayName(choiceIndex)
        local entry = dropdown:CreateItemEntry(choiceDisplayName, OnChoiceSelected)
        entry.choiceIndex = choiceIndex
        dropdown:AddItem(entry)
    end

    self.dropdown = dropdown
    self.control = dropdownControl
end

function ZO_TradingHouseDropDownFeature_Keyboard:CreateControl(parentControl, anchorControl)
    local dropdownControlName = string.format("$(parent)%sDropdown", self.featureParams:GetKey())
    local dropdownControl = CreateControlFromVirtual(dropdownControlName, parentControl, "TradingHouseDropDownFeatureControl")

    self:AttachToControl(dropdownControl)
end

function ZO_TradingHouseDropDownFeature_Keyboard:GetControl()
    return self.control
end

function ZO_TradingHouseDropDownFeature_Keyboard:Hide()
    self.control:SetHidden(true)
end

function ZO_TradingHouseDropDownFeature_Keyboard:Show()
    self.control:SetHidden(false)
end

---------------------------------
-- Level/Champion Point Range  --
---------------------------------
ZO_TradingHouseLevelRangeFeature_Keyboard = ZO_TradingHouseLevelRangeFeature_Shared:Subclass()

function ZO_TradingHouseLevelRangeFeature_Keyboard:New(...)
    return ZO_TradingHouseLevelRangeFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHouseLevelRangeFeature_Keyboard:Initialize(featureKey, searchCallback)
    ZO_TradingHouseLevelRangeFeature_Shared.Initialize(self, featureKey, searchCallback)
    self.minLevel, self.maxLevel, self.isChampionRank = nil, nil, false
end

-- Override
function ZO_TradingHouseLevelRangeFeature_Keyboard:GetLevelRange()
    return self.minLevel, self.maxLevel, self.isChampionRank
end

-- Override
function ZO_TradingHouseLevelRangeFeature_Keyboard:SetLevelRange(minLevel, maxLevel, isChampionRank)
    self.minLevel, self.maxLevel, self.isChampionRank = minLevel, maxLevel, isChampionRank
    self:Refresh()
    TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
end

function ZO_TradingHouseLevelRangeFeature_Keyboard:AttachToControl(levelRangeControl)
    local function ApplyLevel()
        self:Refresh()
        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end

    local function OnMinLevelChanged(minLevelEdit)
        self.minLevel = tonumber(minLevelEdit:GetText())
    end
    self.minLevelEdit = levelRangeControl:GetNamedChild("MinLevelBox")
    self.minLevelEdit:SetHandler("OnTextChanged", OnMinLevelChanged)
    self.minLevelEdit:SetHandler("OnEnter", ApplyLevel)
    self.minLevelEdit:SetHandler("OnFocusLost", ApplyLevel)

    local function OnMaxLevelChanged(maxLevelEdit)
        self.maxLevel = tonumber(maxLevelEdit:GetText())
    end
    self.maxLevelEdit = levelRangeControl:GetNamedChild("MaxLevelBox")
    self.maxLevelEdit:SetHandler("OnTextChanged", OnMaxLevelChanged)
    self.maxLevelEdit:SetHandler("OnEnter", ApplyLevel)
    self.maxLevelEdit:SetHandler("OnFocusLost", ApplyLevel)

    self.levelRangeLabel = levelRangeControl:GetNamedChild("LevelTypeName")

    local function OnToggleClicked()
        self.isChampionRank = not self.isChampionRank
        self:Refresh()
        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end
    self.levelRangeToggle = levelRangeControl:GetNamedChild("LevelTypeToggle")
    self.levelRangeToggle:SetHandler("OnClicked", OnToggleClicked)

    local editControlGroup = ZO_EditControlGroup:New()
    editControlGroup:AddEditControl(self.minLevelEdit)
    editControlGroup:AddEditControl(self.maxLevelEdit)

    self.control = levelRangeControl
end

function ZO_TradingHouseLevelRangeFeature_Keyboard:CreateControl(parentControl, anchorControl)
    local levelRangeControl = CreateControlFromVirtual("$(parent)"..self.featureKey, parentControl, "TradingHouseLevelRangeFeatureControl")
    self:AttachToControl(levelRangeControl)
end

function ZO_TradingHouseLevelRangeFeature_Keyboard:GetControl()
    return self.control
end

function ZO_TradingHouseLevelRangeFeature_Keyboard:Hide()
    self.control:SetHidden(true)
end

function ZO_TradingHouseLevelRangeFeature_Keyboard:Show()
    self.control:SetHidden(false)
end

local function InterpretLevelRange(valMin, valMax, isChampionRank)
    if isChampionRank then
        local maxChampionPoints = GetChampionPointsPlayerProgressionCap()
        valMin = valMin and zo_clamp(zo_floor(valMin / 10) * 10, 0, maxChampionPoints)
        valMax = valMax and zo_clamp(zo_floor(valMax / 10) * 10, 0, maxChampionPoints)
    else
        local maxPlayerLevel = GetMaxLevel()
        valMin = valMin and zo_clamp(zo_floor(valMin), 0, maxPlayerLevel)
        valMax = valMax and zo_clamp(zo_floor(valMax), 0, maxPlayerLevel)
    end

    return valMin, valMax
end

function ZO_TradingHouseLevelRangeFeature_Keyboard:Refresh()
    self.minLevel, self.maxLevel = InterpretLevelRange(self.minLevel, self.maxLevel, self.isChampionRank)
    self.minLevelEdit:SetText(self.minLevel or "")
    self.maxLevelEdit:SetText(self.maxLevel or "")

    if self.isChampionRank then
        self.levelRangeToggle:SetState(BSTATE_PRESSED, true)
        self.levelRangeLabel:SetText(GetString(SI_TRADING_HOUSE_BROWSE_CHAMPION_POINTS_RANGE_LABEL))
    else
        self.levelRangeToggle:SetState(BSTATE_NORMAL, false)
        self.levelRangeLabel:SetText(GetString(SI_TRADING_HOUSE_BROWSE_LEVEL_RANGE_LABEL))
    end
end

-----------------
-- Price Range --
-----------------
ZO_TradingHousePriceRangeFeature_Keyboard = ZO_TradingHousePriceRangeFeature_Shared:Subclass()

function ZO_TradingHousePriceRangeFeature_Keyboard:New(...)
    return ZO_TradingHousePriceRangeFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHousePriceRangeFeature_Keyboard:Initialize()
    self.minPrice, self.maxPrice = nil, nil
end

-- Override
function ZO_TradingHousePriceRangeFeature_Keyboard:GetPriceRange()
    return self.minPrice, self.maxPrice
end

-- Override
function ZO_TradingHousePriceRangeFeature_Keyboard:SetPriceRange(minPrice, maxPrice)
    self.minPrice, self.maxPrice = minPrice, maxPrice
    self:Refresh()
    TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
end

function ZO_TradingHousePriceRangeFeature_Keyboard:AttachToControl(priceRangeControl)
    local function ApplyPrice()
        self:Refresh()
        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end

    local function OnMinPriceChanged(minPriceEdit)
        self.minPrice = tonumber(minPriceEdit:GetText())
    end
    self.minPriceEdit = priceRangeControl:GetNamedChild("MinPriceBox")
    self.minPriceEdit:SetHandler("OnTextChanged", OnMinPriceChanged)
    self.minPriceEdit:SetHandler("OnEnter", ApplyPrice)
    self.minPriceEdit:SetHandler("OnFocusLost", ApplyPrice)

    local function OnMaxPriceChanged(maxPriceEdit)
        self.maxPrice = tonumber(maxPriceEdit:GetText())
    end
    self.maxPriceEdit = priceRangeControl:GetNamedChild("MaxPriceBox")
    self.maxPriceEdit:SetHandler("OnTextChanged", OnMaxPriceChanged)
    self.maxPriceEdit:SetHandler("OnEnter", ApplyPrice)
    self.maxPriceEdit:SetHandler("OnFocusLost", ApplyPrice)

    local editControlGroup = ZO_EditControlGroup:New()
    editControlGroup:AddEditControl(self.minPriceEdit)
    editControlGroup:AddEditControl(self.maxPriceEdit)

    self.control = priceRangeControl
end

function ZO_TradingHousePriceRangeFeature_Keyboard:GetControl()
    return self.control
end

function ZO_TradingHousePriceRangeFeature_Keyboard:Hide()
    self.control:SetHidden(true)
end

function ZO_TradingHousePriceRangeFeature_Keyboard:Show()
    self.control:SetHidden(false)
end

function ZO_TradingHousePriceRangeFeature_Keyboard:Refresh()
    self.minPrice = self.minPrice and zo_clamp(zo_floor(self.minPrice), MIN_TRADING_HOUSE_POST_PRICE, MAX_PLAYER_CURRENCY)
    self.maxPrice = self.maxPrice and zo_clamp(zo_floor(self.maxPrice), MIN_TRADING_HOUSE_POST_PRICE, MAX_PLAYER_CURRENCY)
    self.minPriceEdit:SetText(self.minPrice or "")
    self.maxPriceEdit:SetText(self.maxPrice or "")
end

-- Globals
function ZO_TradingHouse_CreateKeyboardFeature(featureKey)
    local featureType = ZO_TRADING_HOUSE_FEATURE_TYPES[featureKey]

    if featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_DROPDOWN then
        local featureParams = ZO_TRADING_HOUSE_DROPDOWN_FEATURE_PARAMS[featureKey]
        return ZO_TradingHouseDropDownFeature_Keyboard:New(featureParams)
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_LEVELRANGE then
        local searchCallback = ZO_TRADING_HOUSE_LEVELRANGE_FEATURE_CALLBACKS[featureKey]
        return ZO_TradingHouseLevelRangeFeature_Keyboard:New(featureKey, searchCallback)
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_SEARCHCATEGORY then
        return ZO_TradingHouseSearchCategoryFeature_Keyboard:New()
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_PRICERANGE then
        return ZO_TradingHousePriceRangeFeature_Keyboard:New()
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_NAMESEARCH then
        return ZO_TradingHouseNameSearchFeature_Keyboard:New()
    end
end