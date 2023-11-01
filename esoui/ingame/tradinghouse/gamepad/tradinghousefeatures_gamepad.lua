--------------
-- Dropdown --
--------------
ZO_TradingHouseDropDownFeature_Gamepad = ZO_TradingHouseDropDownFeature_Shared:Subclass()

function ZO_TradingHouseDropDownFeature_Gamepad:New(...)
    return ZO_TradingHouseDropDownFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHouseDropDownFeature_Gamepad:Initialize(featureParams)
    ZO_TradingHouseDropDownFeature_Shared.Initialize(self, featureParams)

    self.selectedChoiceIndex = nil
end

-- Override
function ZO_TradingHouseDropDownFeature_Gamepad:GetSelectedChoiceIndex()
    return self.selectedChoiceIndex
end

-- Override
function ZO_TradingHouseDropDownFeature_Gamepad:SelectChoice(newChoiceIndex)
    local selectionChanged = self.selectedChoiceIndex ~= newChoiceIndex
    if selectionChanged then
        self.selectedChoiceIndex = newChoiceIndex
        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end
end

function ZO_TradingHouseDropDownFeature_Gamepad:GetOrCreateEntryData()
    if self.entryData then
        return self.entryData
    end

    local function OnChoiceSelected(_, entryName, entry, _)
        self:SelectChoice(entry.choiceIndex)
    end

    local function SetupFeatureDropdown(comboBox)
        self.comboBox = comboBox

        comboBox:ClearItems()
        for choiceIndex = 1, self.featureParams:GetNumChoices() do
            local choiceDisplayName = self.featureParams:GetChoiceDisplayName(choiceIndex)
            local entry = comboBox:CreateItemEntry(choiceDisplayName, OnChoiceSelected)
            entry.choiceIndex = choiceIndex
            comboBox:AddItem(entry)
        end
        comboBox:SelectItemByIndex(self.selectedChoiceIndex or 1)
    end

    local entryData = ZO_GamepadEntryData:New(string.format("GuildStore%sDropdown", self.featureParams:GetKey()))
    entryData.setupCallback = SetupFeatureDropdown
    entryData.narrationText = function() return self.comboBox:GetNarrationText() end
    self.entryData = entryData
    return entryData
end

function ZO_TradingHouseDropDownFeature_Gamepad:AddEntries(itemList)
    itemList:AddEntry("ZO_GamepadGuildStoreBrowseDropdownTemplate", self:GetOrCreateEntryData())
end

--------------------------------
-- Level/Champion Point Range --
--------------------------------
ZO_TradingHouseLevelRangeFeature_Gamepad = ZO_TradingHouseLevelRangeFeature_Shared:Subclass()

ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_ALL = 1
ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_LEVEL = 2
ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_CHAMPION_RANK = 3

local LEVEL_TYPES = 
{
    {
        name = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_ALL_LEVEL),
        levelType = ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_ALL,
        enableSliders = false,
    },
    {
        name = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_PLAYER_LEVEL),
        levelType = ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_LEVEL,
        enableSliders = true,
    },
    {
        name = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_CHAMPION_POINTS),
        levelType = ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_CHAMPION_RANK,
        enableSliders = true,
    },
}

local MIN_LEVEL_SLIDER_MODE = 1
local MAX_LEVEL_SLIDER_MODE = 2

function ZO_TradingHouseLevelRangeFeature_Gamepad:New(...)
    return ZO_TradingHouseLevelRangeFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHouseLevelRangeFeature_Gamepad:Initialize(featureKey, searchCallback)
    ZO_TradingHouseLevelRangeFeature_Shared.Initialize(self, featureKey, searchCallback)
    self.selectedLevelTypeIndex = 1
    self.minLevel = self:GetMinLevelLimit()
    self.maxLevel = self:GetMaxLevelLimit()
    self.sliderModeToSliderData = {}
end

-- Override
function ZO_TradingHouseLevelRangeFeature_Gamepad:GetLevelRange()
    local levelType = self:GetLevelType()
    if levelType == ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_ALL then
        local NO_MIN_LEVEL, NO_MAX_LEVEL, NOT_CHAMPION_RANK = nil, nil, false
        return NO_MIN_LEVEL, NO_MAX_LEVEL, NOT_CHAMPION_RANK
    else
        local isChampionRank = levelType == ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_CHAMPION_RANK
        return self.minLevel, self.maxLevel, isChampionRank
    end
end

-- Override
function ZO_TradingHouseLevelRangeFeature_Gamepad:SetLevelRange(minLevel, maxLevel, isChampionRank)
    if minLevel == nil then
        self:SetLevelType(ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_ALL)
    else
        self:SetLevelType(isChampionRank and ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_CHAMPION_RANK or ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_LEVEL)

        minLevel = minLevel or self:GetMinLevelLimit()
        if self.minSlider then
            self.minSlider:SetValue(minLevel)
        else
            self:SetMinLevel(minLevel)
        end

        maxLevel = maxLevel or self:GetMaxLevelLimit()
        if self.maxSlider then
            self.maxSlider:SetValue(maxLevel)
        else
            self:SetMaxLevel(maxLevel)
        end
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:SetMinLevel(minLevel)
    if self.minLevel ~= minLevel then
        self.minLevel = minLevel

        if self.minLevelValueLabel then
            self.minLevelValueLabel:SetText(minLevel)
        end

        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:SetMaxLevel(maxLevel)
    if self.maxLevel ~= maxLevel then
        self.maxLevel = maxLevel

        if self.maxLevelValueLabel then
            self.maxLevelValueLabel:SetText(maxLevel)
        end

        TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetLevelStep()
    if self:GetLevelType() == ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_CHAMPION_RANK then
        return 10
    else
        return 1
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetMinLevelLimit()
    -- Min level is 0 for both levels and CP
    return 0
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetMaxLevelLimit()
    if self:GetLevelType() == ZO_GAMEPAD_TRADING_HOUSE_LEVEL_RANGE_TYPE_CHAMPION_RANK then
        return GetChampionPointsPlayerProgressionCap()
    else
        return GetMaxLevel()
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:ResetSliderState()
    local minLevelCap = self:GetMinLevelLimit()
    local maxLevelCap = self:GetMaxLevelLimit()

    if self.minSlider then
        self.minSlider:SetMinMax(minLevelCap, maxLevelCap)
        self.minSlider:SetValue(minLevelCap)
    end

    if self.maxSlider then
        self.maxSlider:SetMinMax(minLevelCap, maxLevelCap)
        self.maxSlider:SetValue(maxLevelCap)
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetLevelType()
    return LEVEL_TYPES[self.selectedLevelTypeIndex].levelType
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:ShouldEnableSliders()
    return LEVEL_TYPES[self.selectedLevelTypeIndex].enableSliders
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:SetLevelType(levelType)
    local newLevelTypeIndex = nil
    for levelIndex, levelTypeData in ipairs(LEVEL_TYPES) do
        if levelTypeData.levelType == levelType then
            newLevelTypeIndex = levelIndex
            break
        end
    end

    if newLevelTypeIndex then
        if self.levelTypeDropdown then
            self.levelTypeDropdown:SelectItemByIndex(newLevelTypeIndex)
        else
            self.selectedLevelTypeIndex = newLevelTypeIndex
            TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
        end
    end
end

do
    local NO_MIN = nil
    local NO_MAX = nil
    function ZO_TradingHouseLevelRangeFeature_Gamepad:SetupSlider(control, data, selected)
        local slider = control:GetNamedChild("Slider")
        data.slider = slider
        local sliderNameLabel = control:GetNamedChild("SliderLabel")
        local sliderValueLabel = control:GetNamedChild("SliderValue")

        slider:SetValueStep(self:GetLevelStep())
        slider:SetMinMax(self:GetMinLevelLimit(), self:GetMaxLevelLimit())

        if data.sliderMode == MIN_LEVEL_SLIDER_MODE then
            self.minSlider = slider
            self.minSlider:SetHandler("OnValueChanged", function(minSliderControl, value)
                self:SetMinLevel(value)
                if data.onValueChangedCallback then
                    data.onValueChangedCallback(minSliderControl, value)
                end
            end)
            self.minSlider:SetValueConstraints(NO_MIN, function()
                return self.maxLevel
            end)
            self.minSlider:SetValue(self.minLevel)
            self.minLevelValueLabel = sliderValueLabel
            self.minLevelValueLabel:SetText(self.minLevel)
            sliderNameLabel:SetText(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MIN_LEVEL))
        elseif data.sliderMode == MAX_LEVEL_SLIDER_MODE then
            self.maxSlider = slider
            self.maxSlider:SetHandler("OnValueChanged", function(maxSliderControl, value)
                self:SetMaxLevel(value)
                if data.onValueChangedCallback then
                    data.onValueChangedCallback(maxSliderControl, value)
                end
            end)
            self.maxSlider:SetValueConstraints(function()
                return self.minLevel
            end, NO_MAX)
            self.maxSlider:SetValue(self.maxLevel)
            self.maxLevelValueLabel = sliderValueLabel
            self.maxLevelValueLabel:SetText(self.maxLevel)
            sliderNameLabel:SetText(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MAX_LEVEL))
        end

        local shouldEnableSliders = self:ShouldEnableSliders()
        slider:SetEnabled(shouldEnableSliders)
        sliderValueLabel:SetHidden(not shouldEnableSliders)
        control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, not shouldEnableSliders))
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetOrCreateLevelTypeData()
    if self.levelTypeData then
        return self.levelTypeData
    end

    local function OnLevelTypeSelected(comboBox, entryName, entry)
        local selectionChanged = self.selectedLevelTypeIndex ~= entry.index

        if selectionChanged then
            self.selectedLevelTypeIndex = entry.index
            self:ResetSliderState()
            TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
        end
    end

    local function SetupLevelTypeDropdown(dropDown)
        dropDown:ClearItems()
        dropDown:SetSortsItems(false)

        for levelIndex, levelTypeData in ipairs(LEVEL_TYPES) do
            local entry = dropDown:CreateItemEntry(levelTypeData.name, OnLevelTypeSelected)
            entry.levelType = levelTypeData.levelType
            entry.index = levelIndex

            dropDown:AddItem(entry)
        end

        self.levelTypeDropdown = dropDown
        if self.selectedLevelTypeIndex then
            dropDown:SelectItemByIndex(self.selectedLevelTypeIndex)
        else
            dropDown:SelectFirstItem()
        end
    end

    local levelTypeData = ZO_GamepadEntryData:New("GuildStoreLevelTypeDropdown")
    levelTypeData.setupCallback = SetupLevelTypeDropdown
    levelTypeData.narrationText = function() return self.levelTypeDropdown:GetNarrationText() end
    self.levelTypeData = levelTypeData
    return levelTypeData
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetOrCreateSliderData(sliderMode)
    if self.sliderModeToSliderData[sliderMode] then
        return self.sliderModeToSliderData[sliderMode]
    end

    local sliderData = ZO_GamepadEntryData:New(string.format("GuildStoreLevelRangeSlider%d", sliderMode))
    sliderData.sliderMode = sliderMode
    sliderData.feature = self
    sliderData.narrationText = function(...) return self:GetNarrationText(...) end
    sliderData.additionalInputNarrationFunction = function() return self:GetDirectionalInputNarrationData() end
    self.sliderModeToSliderData[sliderMode] = sliderData
    return sliderData
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetNarrationText(entryData, entryControl)
    if entryData.sliderMode == MIN_LEVEL_SLIDER_MODE then
        return ZO_FormatSliderNarrationText(self.minSlider, GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MIN_LEVEL))
    elseif entryData.sliderMode == MAX_LEVEL_SLIDER_MODE then
        return ZO_FormatSliderNarrationText(self.maxSlider, GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MAX_LEVEL))
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:GetDirectionalInputNarrationData()
    --Only include directional input if the sliders are actually enabled
    if self:ShouldEnableSliders() then
        return ZO_GetNumericHorizontalDirectionalInputNarrationData()
    else
        return {}
    end
end

function ZO_TradingHouseLevelRangeFeature_Gamepad:AddEntries(itemList)
    itemList:AddEntry("ZO_GamepadGuildStoreBrowseDropdownTemplate", self:GetOrCreateLevelTypeData())

    itemList:AddEntry("ZO_GamepadGuildStoreBrowseSliderTemplate", self:GetOrCreateSliderData(MIN_LEVEL_SLIDER_MODE))
    itemList:AddEntry("ZO_GamepadGuildStoreBrowseSliderTemplate", self:GetOrCreateSliderData(MAX_LEVEL_SLIDER_MODE))
end

-----------------
-- Price Range --
-----------------
ZO_TradingHousePriceRangeFeature_Gamepad = ZO_TradingHousePriceRangeFeature_Shared:Subclass()

local MIN_PRICE_SELECTOR_MODE = 1
local MAX_PRICE_SELECTOR_MODE = 2

function ZO_TradingHousePriceRangeFeature_Gamepad:New(...)
    return ZO_TradingHousePriceRangeFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHousePriceRangeFeature_Gamepad:Initialize()
    self.priceSelectorKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:UnfocusPriceSelector() end),
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                if self.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
                    return self.isPriceValid, GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_INVALID_MIN_PRICE_ERROR)
                else
                    return self.isPriceValid, GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_INVALID_MAX_PRICE_ERROR)
                end
            end,
            callback = function()
                local minPrice, maxPrice = self:GetPriceRange()
                local newPrice = self.priceSelector:GetValue()
                if self.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
                    minPrice = newPrice
                else
                    maxPrice = newPrice
                end
                self:SetPriceRange(minPrice, maxPrice)
                self:UnfocusPriceSelector()
            end,
        }
    }

    self.minPrice = MIN_TRADING_HOUSE_POST_PRICE
    self.maxPrice = MAX_PLAYER_CURRENCY
end

function ZO_TradingHousePriceRangeFeature_Gamepad:AttachToControl(priceSelectorControl, focusLostCallback)
    self.priceSelectorControl = priceSelectorControl
    self.priceSelector = ZO_CurrencySelector_Gamepad:New(priceSelectorControl:GetNamedChild("Selector"))
    self.priceSelector:SetCurrencyType(CURT_MONEY)
    self.priceSelector:RegisterCallback("OnValueChanged", function()
        self:ValidatePriceSelectorValue(self.priceSelector:GetValue())
    end)

    self.priceSelector:RegisterCallback("OnDeactivated", function()
        if focusLostCallback then
            focusLostCallback()
        end
    end)
end

-- Override
function ZO_TradingHousePriceRangeFeature_Gamepad:GetPriceRange()
    -- If the player hasn't adjusted the price selector then treat it as an unbounded range in that direction
    -- This means that viewing gamepad search results in keyboard mode will leave those edit boxes blank as you'd expect
    local minPrice, maxPrice = nil, nil
    if self.minPrice ~= MIN_TRADING_HOUSE_POST_PRICE then
        minPrice = self.minPrice
    end
    if self.maxPrice ~= MAX_PLAYER_CURRENCY then
        maxPrice = self.maxPrice
    end

    return minPrice, maxPrice
end

-- Override
function ZO_TradingHousePriceRangeFeature_Gamepad:SetPriceRange(minPrice, maxPrice)
    self.minPrice = minPrice or MIN_TRADING_HOUSE_POST_PRICE
    self.minPrice = zo_clamp(self.minPrice, MIN_TRADING_HOUSE_POST_PRICE, MAX_PLAYER_CURRENCY)
    if self.minPriceAmountLabel then
        ZO_CurrencyControl_SetSimpleCurrency(self.minPriceAmountLabel, CURT_MONEY, self.minPrice, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    end

    self.maxPrice = maxPrice or MAX_PLAYER_CURRENCY
    self.maxPrice = zo_clamp(self.maxPrice, MIN_TRADING_HOUSE_POST_PRICE, MAX_PLAYER_CURRENCY)
    if self.maxPriceAmountLabel then
        ZO_CurrencyControl_SetSimpleCurrency(self.maxPriceAmountLabel, CURT_MONEY, self.maxPrice, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    end

    TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
end

function ZO_TradingHousePriceRangeFeature_Gamepad:FocusPriceSelector(priceSelectorData)
    self.priceSelectorMode = priceSelectorData.priceSelectorMode
    local selectedPriceAmountControl = priceSelectorData.priceSelector
    if not self.selectedPriceAmountControl then
        self.priceSelector:SetClampValues(true)
        self.priceSelector:SetMaxValue(MAX_PLAYER_CURRENCY)

        if self.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
            self.priceSelector:SetValue(self.minPrice)
        else
            self.priceSelector:SetValue(self.maxPrice)
        end
    
        selectedPriceAmountControl:SetHidden(true)
        if selectedPriceAmountControl.header then
            selectedPriceAmountControl.header:SetHidden(true)
        end
        self.priceSelectorControl:SetHidden(false)
        self.priceSelector:Activate()
        self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor, self.keybindStripId)
        self.selectedPriceAmountControl = selectedPriceAmountControl
    end
end

function ZO_TradingHousePriceRangeFeature_Gamepad:UnfocusPriceSelector()
    if self.selectedPriceAmountControl then
        self.priceSelectorControl:SetHidden(true)
        self.selectedPriceAmountControl:SetHidden(false)
        if self.selectedPriceAmountControl.header then
            self.selectedPriceAmountControl.header:SetHidden(false)
        end
        self.priceSelector:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
        KEYBIND_STRIP:PopKeybindGroupState()
        self.keybindStripId = nil
        self.selectedPriceAmountControl = false
    end
end

function ZO_TradingHousePriceRangeFeature_Gamepad:ValidatePriceSelectorValue(value)
    if self.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
        self.isPriceValid = (value <= self.maxPrice)
    else
        self.isPriceValid = (value >= self.minPrice)
    end

    self.priceSelector:SetTextColor(self.isPriceValid and ZO_SELECTED_TEXT or ZO_ERROR_COLOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
end

function ZO_TradingHousePriceRangeFeature_Gamepad:SetupPriceSelector(control, data, selected, reselectingDuringRebuild, enabled, active)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))

    if data.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
        self.minPriceAmountLabel = control:GetNamedChild("PriceAmount")
        ZO_CurrencyControl_SetSimpleCurrency(self.minPriceAmountLabel, CURT_MONEY, self.minPrice, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    else
        self.maxPriceAmountLabel = control:GetNamedChild("PriceAmount")
        ZO_CurrencyControl_SetSimpleCurrency(self.maxPriceAmountLabel, CURT_MONEY, self.maxPrice, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    end

    data.priceSelector = control
    data.priceSelector.header = control:GetNamedChild("Header")
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
end

function ZO_TradingHousePriceRangeFeature_Gamepad:AddEntries(itemList)
    local minPriceData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MIN_PRICE))
    minPriceData:SetFontScaleOnSelection(false)
    minPriceData.priceSelectorMode = MIN_PRICE_SELECTOR_MODE
    minPriceData.feature = self
    minPriceData:SetHeader(GetString(SI_GAMEPAD_TRADING_HOUSE_ITEM_PRICE_RANGE_HEADER))
    minPriceData.narrationText = function(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_Currency_FormatGamepad(CURT_MONEY, self.minPrice, ZO_CURRENCY_FORMAT_AMOUNT_NAME)))
        return narrations
    end
    itemList:AddEntryWithHeader("ZO_GamepadPriceSelectorTemplate", minPriceData)

    local maxPriceData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MAX_PRICE))
    maxPriceData:SetFontScaleOnSelection(false)
    maxPriceData.priceSelectorMode = MAX_PRICE_SELECTOR_MODE
    maxPriceData.feature = self
    maxPriceData.narrationText = function(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_Currency_FormatGamepad(CURT_MONEY, self.maxPrice, ZO_CURRENCY_FORMAT_AMOUNT_NAME)))
        return narrations
    end
    itemList:AddEntry("ZO_GamepadPriceSelectorTemplate", maxPriceData)
end

-- Globals
function ZO_TradingHouse_CreateGamepadFeature(featureKey)
    local featureType = ZO_TRADING_HOUSE_FEATURE_TYPES[featureKey]

    if featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_DROPDOWN then
        local featureParams = ZO_TRADING_HOUSE_DROPDOWN_FEATURE_PARAMS[featureKey]
        return ZO_TradingHouseDropDownFeature_Gamepad:New(featureParams)
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_LEVELRANGE then
        local searchCallback = ZO_TRADING_HOUSE_LEVELRANGE_FEATURE_CALLBACKS[featureKey]
        return ZO_TradingHouseLevelRangeFeature_Gamepad:New(featureKey, searchCallback)
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_SEARCHCATEGORY then
        return ZO_TradingHouseSearchCategoryFeature_Gamepad:New()
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_PRICERANGE then
        return ZO_TradingHousePriceRangeFeature_Gamepad:New()
    elseif featureType == ZO_TRADING_HOUSE_FEATURE_TYPE_NAMESEARCH then
        return ZO_TradingHouseNameSearchFeature_Gamepad:New()
    end
end
