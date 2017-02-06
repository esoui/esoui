local CATEGORY_DROP_DOWN_MODE = 1
local QUALITY_DROP_DOWN_MODE = 2
local FILTER_DROP_DOWN_MODE = 3
local LEVEL_DROP_DOWN_MODE = 4

local MIN_PRICE_SELECTOR_MODE = 1
local MAX_PRICE_SELECTOR_MODE = 2

local MIN_LEVEL_SLIDER_MODE = 1
local MAX_LEVEL_SLIDER_MODE = 2

local MINIMUM_PLAYER_LEVEL = 0
local MINIMUM_CHAMPION_POINTS = 0
local LEVEL_TYPES = 
{
    { TRADING_HOUSE_FILTER_TYPE_ALL_LEVEL, nil, SI_GAMEPAD_TRADING_HOUSE_BROWSE_ALL_LEVEL },
    { TRADING_HOUSE_FILTER_TYPE_LEVEL, nil, SI_GAMEPAD_TRADING_HOUSE_BROWSE_PLAYER_LEVEL },
    { TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS, nil, SI_GAMEPAD_TRADING_HOUSE_BROWSE_CHAMPION_POINTS },
}

local QUALITY_COLOR_INDEX = 1
local DONT_SELECT_ITEM = false
local IGNORE_CALLBACK = true
local IGNORE_CALL_BACK = true
local MIN_POSTING_AMOUNT = 1
local CLAMP_VALUES = true
local SEARCH_CRITERIA_CHANGED = true
ZO_GAMEPAD_GUILD_STORE_BROWSE_SLIDER_OFFSET_Y = 15

----------------------------------------------------------
-- Gamepad Trading House Dynamic Search Setter
----------------------------------------------------------

--[[
    This class is similar to Combo Box setter but supports values that are updated at runtime and not accessed from a specific control
    When a new instance is created a GetMinMax function is passed in. When ZO_TradingHouseSearchFieldSetter:ApplySearch is called on our subclass,
    it internally calls our overridden GetValues method which in turns calls the passed in GetMinMax.
--]]

ZO_GamepadTradingHouse_DynamicSetter = ZO_TradingHouseSearchFieldSetter:Subclass()

function ZO_GamepadTradingHouse_DynamicSetter:New(...)
    return ZO_TradingHouseSearchFieldSetter.New(self, ...)
end

function ZO_GamepadTradingHouse_DynamicSetter:Initialize(filterType, GetMinMax)
    ZO_TradingHouseSearchFieldSetter.Initialize(self, filterType)
    self.GetMinMax = GetMinMax
end

function ZO_GamepadTradingHouse_DynamicSetter:GetValues()
    self.m_min, self.m_max = self.GetMinMax()
    return self.m_min, self.m_max
end

---------------------------------
-- Gamepad Trading House Browse
---------------------------------

local ZO_GamepadTradingHouse_Browse = ZO_GamepadTradingHouse_ItemList:Subclass()

function ZO_GamepadTradingHouse_Browse:New(...)
    local browseStore = ZO_GamepadTradingHouse_ItemList.New(self, ...)
    return browseStore
end

function ZO_GamepadTradingHouse_Browse:Initialize(control)
	ZO_GamepadTradingHouse_ItemList.Initialize(self, control)

    GAMEPAD_TRADING_HOUSE_BROWSE_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
	self:SetFragment(GAMEPAD_TRADING_HOUSE_BROWSE_FRAGMENT)
end

function ZO_GamepadTradingHouse_Browse:InitializeKeybindStripDescriptors()
    local function NotAwaitingResponse() 
        return not self.awaitingResponse
    end

    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedData = self.itemList:GetTargetData()

                if selectedData.dropDown then
                    self:FocusDropDown(selectedData.dropDown)
                elseif selectedData.priceSelector then
                    self.priceSelectorMode = selectedData.priceSelectorMode
                    self:FocusPriceSelector(selectedData.priceSelector)
                end
            end,
            visible = function()
                local selectedData = self.itemList:GetTargetData()

                if selectedData then
                    return selectedData.dropDownMode or selectedData.priceSelectorMode
                else
                    return false
                end
            end,
            enabled = NotAwaitingResponse
        },
        {
            name = GetString(SI_GAMEPAD_TRADE_SUBMIT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback =  function()
                self:ShowResults()
            end,
            enabled = NotAwaitingResponse,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        {
            name = GetString(SI_TRADING_HOUSE_GUILD_HEADER),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback =  function()
                self:DisplayChangeGuildDialog()
            end,
            visible = function()
                return GetSelectedTradingHouseGuildId() ~= nil and GetNumTradingHouseGuilds() > 1
            end,
            enabled = function() 
                return self:HasNoCooldown() and NotAwaitingResponse()
            end
        },
        {
            name = GetString(SI_TRADING_HOUSE_RESET_SEARCH),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback =  function()
                            self:ResetFilterValuesToDefaults()
                            if self.isInitialized then
                                local DONT_RESELECT = true
                                self:ResetList(nil, DONT_RESELECT)
                            end
                        end,
        },
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)

    self.priceSelectorKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:UnfocusPriceSelector() end),
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.validPrice
            end,
            callback = function()
                self:SetPriceAmount(self.priceSelector:GetValue())
                self:UnfocusPriceSelector()
            end,
        }
    }
end

function ZO_GamepadTradingHouse_Browse:InitializeSearchTerms(search)
    self:ResetFilterValuesToDefaults() -- Initialize values needed for search
    search:AddSetter(ZO_GamepadTradingHouse_DynamicSetter:New(TRADING_HOUSE_FILTER_TYPE_PRICE, function() return self.minPrice, self.maxPrice end))
    search:AddSetter(ZO_GamepadTradingHouse_DynamicSetter:New(function() return self.levelRangeFilterType end, function() return self.minLevel, self.maxLevel end))
    search:AddSetter(ZO_GamepadTradingHouse_DynamicSetter:New(TRADING_HOUSE_FILTER_TYPE_QUALITY, function() return self.qualityMin, self.qualityMax end))
end

function ZO_GamepadTradingHouse_Browse:ValidatePriceSelectorValue(value)
    if value > 0 then
        if self.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
            self.validPrice = (value <= self.maxPrice)
        else
            self.validPrice = (value >= self.minPrice)
        end
    else
        self.validPrice = false
    end

    self.priceSelector:SetTextColor(self.validPrice and ZO_SELECTED_TEXT or ZO_ERROR_COLOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
end

function ZO_GamepadTradingHouse_Browse:FocusDropDown(dropDown)
    if not self.dropDown then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        dropDown:Activate()
        self.dropDown = dropDown
    end
end

function ZO_GamepadTradingHouse_Browse:UnfocusDropDown()
    if self.dropDown then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self.dropDown = nil
    end
end

function ZO_GamepadTradingHouse_Browse:FocusPriceSelector(selectedPriceAmountControl)
    if not self.selectedPriceAmountControl then
        self.priceSelector:SetClampValues(CLAMP_VALUES)
        self.priceSelector:SetMaxValue(MAX_PLAYER_MONEY)

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
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
        self.selectedPriceAmountControl = selectedPriceAmountControl
    end
end

function ZO_GamepadTradingHouse_Browse:UnfocusPriceSelector()
    if self.selectedPriceAmountControl then
        self.priceSelectorControl:SetHidden(true)
        self.selectedPriceAmountControl:SetHidden(false)
        if self.selectedPriceAmountControl.header then
            self.selectedPriceAmountControl.header:SetHidden(false)
        end
        self.priceSelector:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self.selectedPriceAmountControl = false
    end
end

function ZO_GamepadTradingHouse_Browse:SetMinPriceAmount(priceAmount)
    self.minPrice = priceAmount

    if self.minPriceAmount then
        ZO_CurrencyControl_SetSimpleCurrency(self.minPriceAmount, CURT_MONEY, priceAmount, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    end

    ZO_TradingHouse_SearchCriteriaChanged(SEARCH_CRITERIA_CHANGED)
end

function ZO_GamepadTradingHouse_Browse:SetMaxPriceAmount(priceAmount)
    self.maxPrice = priceAmount

    if self.maxPriceAmount then
        ZO_CurrencyControl_SetSimpleCurrency(self.maxPriceAmount, CURT_MONEY, priceAmount, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    end

    ZO_TradingHouse_SearchCriteriaChanged(SEARCH_CRITERIA_CHANGED)
end

function ZO_GamepadTradingHouse_Browse:SetPriceAmount(amount)
    if self.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
        self:SetMinPriceAmount(amount)
    else
        self:SetMaxPriceAmount(amount)
    end
end

function ZO_GamepadTradingHouse_Browse:SetMinLevel(minLevel)
    self.minLevel = minLevel

    if self.minLevelValueLabel then
        self.minLevelValueLabel:SetText(minLevel)
    end

    ZO_TradingHouse_SearchCriteriaChanged(SEARCH_CRITERIA_CHANGED)
end

function ZO_GamepadTradingHouse_Browse:SetMaxLevel(maxLevel)
    self.maxLevel = maxLevel

    if self.maxLevelValueLabel then
        self.maxLevelValueLabel:SetText(maxLevel)
    end

    ZO_TradingHouse_SearchCriteriaChanged(SEARCH_CRITERIA_CHANGED)
end

function ZO_GamepadTradingHouse_Browse:GetLevelStep()
    if self.levelRangeFilterType == TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS then
        return 10
    else
        return 1
    end
end

function ZO_GamepadTradingHouse_Browse:GetMinLevelCap()
    if self.levelRangeFilterType == TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS then
        return MINIMUM_CHAMPION_POINTS
    else
        return MINIMUM_PLAYER_LEVEL
    end
end 

function ZO_GamepadTradingHouse_Browse:GetMaxLevelCap()
    if self.levelRangeFilterType == TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS then
        return GetChampionPointsPlayerProgressionCap()
    else
        return GetMaxLevel()
    end
end

function ZO_GamepadTradingHouse_Browse:UpdateSliderMinMax(slider, min, max)
    if slider then
        slider:SetMinMax(min, max)
    end
end

function ZO_GamepadTradingHouse_Browse:UpdateLevelSlidersMinMax()
    local minLevelCap = self:GetMinLevelCap()
    local maxLevelCap = self:GetMaxLevelCap()
    self:UpdateSliderMinMax(self.minSlider, minLevelCap, maxLevelCap)
    self:UpdateSliderMinMax(self.maxSlider, minLevelCap, maxLevelCap)

    if self.minSlider then
        self.minSlider:SetValue(minLevelCap)
    end

    if self.maxSlider then
        self.maxSlider:SetValue(maxLevelCap)
    end
end

function ZO_GamepadTradingHouse_Browse:OnTargetChanged(list, selectedData, oldSelectedData)
    if self.focusedSlider then
        self.focusedSlider:Deactivate()
        self.focusedSlider = nil
    end

    if selectedData then
        if selectedData.slider then
            self.focusedSlider = selectedData.slider
            if self.focusedSlider:GetEnabled() then
                self.focusedSlider:Activate()
            end
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadTradingHouse_Browse:PopulateCategoryDropDown(dropDown)
    dropDown:ClearItems()
    dropDown:SetSortsItems(false)

    ZO_TradingHouse_InitializeCategoryComboBox(dropDown, self.OnCategorySelectionChanged, DONT_SELECT_ITEM)
    
    -- Make sure the highlighted item is correct (this is changed by Parametric scroll list during control reuse). 
    dropDown:SetHighlightedItem(self.lastCategoryIndex)

    if self.lastCategoryEntryName then
        -- Set selected item without invoking the item's callback, otherwise we would get infinite recursion
        dropDown:SelectItemByIndex(self.lastCategoryIndex, IGNORE_CALLBACK)
    else
        -- This will invoke the call back for the first item if no lastCategoryEntry exists. This can only happen once so it is safe
        -- We still need to select the first item on the first initialzation call otherwise the combobox display is blank
        dropDown:SelectFirstItem()
    end
end

function ZO_GamepadTradingHouse_Browse:PopulateQualityDropDown(dropDown)
    dropDown:ClearItems()
    dropDown:SetSortsItems(false)

    ZO_TradingHouse_InitializeColoredComboBox(dropDown, ZO_TRADING_HOUSE_QUALITIES, self.OnQualitySelectionChanged, INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, QUALITY_COLOR_INDEX, DONT_SELECT_ITEM)

    if self.lastQualityEntryName then
        dropDown:SelectItemByIndex(self.lastQualityIndex, IGNORE_CALLBACK)
        dropDown:SetHighlightedItem(self.lastQualityIndex)
    else
        dropDown:SelectFirstItem()
    end
end

function ZO_GamepadTradingHouse_Browse:PopulateLevelDropDown(dropDown)
    dropDown:ClearItems()
    dropDown:SetSortsItems(false)

    for _, data in ipairs(LEVEL_TYPES) do
        local entry = dropDown:CreateItemEntry(GetString(data[ZO_RANGE_COMBO_INDEX_TEXT]), self.OnLevelSelectionChanged)
        entry.value = data[ZO_RANGE_COMBO_INDEX_MIN_VALUE]

        dropDown:AddItem(entry)
    end

    if self.lastLevelEntryName then
        dropDown:SelectItemByIndex(self.lastLevelIndex, IGNORE_CALLBACK)
        dropDown:SetHighlightedItem(self.lastLevelIndex)
    else
        dropDown:SelectFirstItem()
    end
end

function ZO_GamepadTradingHouse_Browse:GetFilterDropDowns()
    return self.filterDropDowns
end

do
    local DROP_DOWN_MODE_HEADER_LABELS =
    {
        [CATEGORY_DROP_DOWN_MODE] = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_CATEGORY),
        [QUALITY_DROP_DOWN_MODE]  = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_QUALITY),
        [LEVEL_DROP_DOWN_MODE]    = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_LEVEL_TYPE),
    }

    function ZO_GamepadTradingHouse_Browse:AddDropDownEntry(name, mode)
        local dropDownData = ZO_GamepadEntryData:New(name)
        dropDownData.dropDownMode = mode
        dropDownData:SetHeader(DROP_DOWN_MODE_HEADER_LABELS[mode])
        self.itemList:AddEntryWithHeader("ZO_GamepadGuildStoreBrowseComboboxTemplate", dropDownData)
    end
end

function ZO_GamepadTradingHouse_Browse:AddFilterDropDownEntry(name)
    local dropDownData = ZO_GamepadEntryData:New(name)
    dropDownData.dropDownMode = FILTER_DROP_DOWN_MODE
    self.itemList:AddEntry("ZO_Gamepad_Dropdown_Item_FullWidth", dropDownData)
    return dropDownData
end

do
    local PRICE_SELECTOR_LABEL_STRINGS =
    {
        [MIN_PRICE_SELECTOR_MODE] = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MIN_PRICE),
        [MAX_PRICE_SELECTOR_MODE] = GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MAX_PRICE),
    }
     
    function ZO_GamepadTradingHouse_Browse:AddPriceSelectorEntry(name, mode)
        local priceData = ZO_GamepadEntryData:New(name)
        priceData:SetFontScaleOnSelection(false)
        priceData.priceSelectorMode = mode

        if mode == MIN_PRICE_SELECTOR_MODE then
            priceData:SetHeader(GetString(SI_GAMEPAD_TRADING_HOUSE_ITEM_PRICE_RANGE_HEADER))
            self.itemList:AddEntryWithHeader("ZO_GamepadPriceSelectorTemplate", priceData)
        else
            self.itemList:AddEntry("ZO_GamepadPriceSelectorTemplate", priceData)
        end
    end
end

function ZO_GamepadTradingHouse_Browse:AddLevelSelectorEntry(name, mode)
    local levelData = ZO_GamepadEntryData:New(name)
    levelData.sliderMode = mode
    self.itemList:AddEntry("ZO_GamepadGuildStoreBrowseSliderTemplate", levelData)
end

function ZO_GamepadTradingHouse_Browse:InitializeFilterData(filters)
    if filters then
        ZO_ClearTable(self.filterDropDowns)
        for _, filter in ipairs(filters) do
            if filter.visible then
                local dropDownEntry = self:AddFilterDropDownEntry(filter.name)
                dropDownEntry.initCallback = filter.initCallback
                table.insert(self.filterDropDowns, dropDownEntry)
            end
        end
    end
end

function ZO_GamepadTradingHouse_Browse:ResetList(filters, dontReselect)
    self.itemList:Clear()

    -- Category
    self:AddDropDownEntry("GuildStoreBrowseCategory", CATEGORY_DROP_DOWN_MODE)

    -- Filters
    self:InitializeFilterData(filters)
    
    -- Min Price
    self:AddPriceSelectorEntry(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MIN_PRICE), MIN_PRICE_SELECTOR_MODE)

    -- Max Price
    self:AddPriceSelectorEntry(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MAX_PRICE), MAX_PRICE_SELECTOR_MODE)

    -- Level Type
    self:AddDropDownEntry("GuildStoreBrowseLevelType", LEVEL_DROP_DOWN_MODE)

    -- Min Level
    self:AddLevelSelectorEntry("GuildStoreBrowseMinLevel", MIN_LEVEL_SLIDER_MODE)

    -- Max Level
    self:AddLevelSelectorEntry("GuildStoreBrowseMaxLevel", MAX_LEVEL_SLIDER_MODE)

    -- Quality
    self:AddDropDownEntry("GuildStoreBrowseQuality", QUALITY_DROP_DOWN_MODE)

    self.itemList:Commit(dontReselect)
end

-- Overriden functions
function ZO_GamepadTradingHouse_Browse:PerformDeferredInitialization()
    if self.isInitialized then return end

    self.minPrice = MIN_POSTING_AMOUNT
    self.maxPrice = MAX_PLAYER_MONEY
    self.minLevel = MINIMUM_PLAYER_LEVEL
    self.maxLevel = GetMaxLevel()

    self.priceSelectorControl = self.control:GetNamedChild("PriceSelectorContainer")
    self.priceSelector = ZO_CurrencySelector_Gamepad:New(self.priceSelectorControl:GetNamedChild("Selector"))
    self.priceSelector:RegisterCallback("OnValueChanged", function() self:ValidatePriceSelectorValue(self.priceSelector:GetValue()) end)

    self:IntializeComboBoxCallBacks()
    self.filterDropDowns = {}
    self:ResetList()
    self.isInitialized = true
end

function ZO_GamepadTradingHouse_Browse:IntializeComboBoxCallBacks()
    self.OnCategorySelectionChanged = function(_, entryName, _, _)
        -- This is used in ZO_TradingHouse_InitializeCategoryComboBox to not trip selection changed when the box is rebuilt on refresh even though the categories are the same
        local selectionChanged = self.lastCategoryEntryName ~= entryName
        if self.lastCategoryEntryName then
            self.lastCategoryIndex = self.categoryDropDown:GetHighlightedIndex()
        end

        self.lastCategoryEntryName = entryName
        return selectionChanged
    end

    self.OnQualitySelectionChanged = function(comboBox, entryName, entry)
        local selectionChanged = self.lastQualityEntryName ~= entryName
        if self.lastQualityEntryName then
            self.lastQualityIndex = self.qualityDropDown:GetHighlightedIndex()
        end

        self.lastQualityEntryName = entryName
        self.qualityMin = entry.minValue
        self.qualityMax = entry.maxValue
        ZO_TradingHouse_ComboBoxSelectionChanged(comboBox, entryName, entry, selectionChanged)
    end

    self.OnLevelSelectionChanged = function(comboBox, entryName, entry)
        local selectionChanged = self.lastLevelEntryName ~= entryName
        if self.lastLevelEntryName then
            self.lastLevelIndex = self.levelDropDown:GetHighlightedIndex()
        end

        self.lastLevelEntryName = entryName
        self.levelRangeFilterType = entry.value
        ZO_TradingHouse_ComboBoxSelectionChanged(comboBox, entryName, entry, selectionChanged)

        if selectionChanged then
            self:UpdateLevelSlidersMinMax()
            self.itemList:RefreshVisible()
        end
    end
end

function ZO_GamepadTradingHouse_Browse:GetFragmentGroup()
	return {GAMEPAD_TRADING_HOUSE_BROWSE_FRAGMENT}
end

function ZO_GamepadTradingHouse_Browse:SetupDropDown(control, data, selected, reselectingDuringRebuild, enabled, active)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))
        
    local dropDown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Dropdown"))
    dropDown:SetDeactivatedCallback(function() self:UnfocusDropDown() end)

    if data.dropDownMode == CATEGORY_DROP_DOWN_MODE then
        self.categoryDropDown = dropDown
        self:PopulateCategoryDropDown(dropDown)
    elseif data.dropDownMode == QUALITY_DROP_DOWN_MODE then
        self:PopulateQualityDropDown(dropDown)
        self.qualityDropDown = dropDown
    elseif data.dropDownMode == LEVEL_DROP_DOWN_MODE then
        self:PopulateLevelDropDown(dropDown)
        self.levelDropDown = dropDown
    end
        
    data.dropDown = dropDown
end

function ZO_GamepadTradingHouse_Browse:SetupFilterDropDown(control, data, selected, reselectingDuringRebuild, enabled, active)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))
        
    local dropDown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Dropdown"))

    dropDown:SetSortsItems(false)
    local DONT_RESELECT = false
    dropDown:SetHighlightedItem(1, DONT_RESELECT)
    dropDown:SetDeactivatedCallback(function() self:UnfocusDropDown() end)
    data.initCallback(dropDown)

    data.dropDown = dropDown
end

function ZO_GamepadTradingHouse_Browse:SetupPriceSelector(control, data, selected, reselectingDuringRebuild, enabled, active)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))

    if data.priceSelectorMode == MIN_PRICE_SELECTOR_MODE then
        self.minPriceAmount = control:GetNamedChild("PriceAmount")
        ZO_CurrencyControl_SetSimpleCurrency(self.minPriceAmount, CURT_MONEY, self.minPrice, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    else
        self.maxPriceAmount = control:GetNamedChild("PriceAmount")
        ZO_CurrencyControl_SetSimpleCurrency(self.maxPriceAmount, CURT_MONEY, self.maxPrice, ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    end

    data.priceSelector = control
    data.priceSelector.header = control:GetNamedChild("Header")
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
end

function ZO_GamepadTradingHouse_Browse:SetupSlider(control, data, selected, reselectingDuringRebuild, enabled, active)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))

    local slider = control:GetNamedChild("Slider")
    slider:SetValueStep(self:GetLevelStep())
    self:UpdateSliderMinMax(slider, self:GetMinLevelCap(), self:GetMaxLevelCap())
    slider.sliderMode = data.sliderMode
    slider.entry = data

    local valueLabel = control:GetNamedChild("SliderValue")

    if data.sliderMode == MIN_LEVEL_SLIDER_MODE then
        self.minSlider = slider
        self.minSlider:SetValue(self.minLevel)
        self.minLevelValueLabel = valueLabel
        self.minLevelValueLabel:SetText(self.minLevel)
        control:GetNamedChild("SliderLabel"):SetText(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MIN_LEVEL))
    else
        self.maxSlider = slider
        self.maxSlider:SetValue(self.maxLevel)
        self.maxLevelValueLabel = valueLabel
        self.maxLevelValueLabel:SetText(self.maxLevel)
        control:GetNamedChild("SliderLabel"):SetText(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_MAX_LEVEL))
    end

    local disableLevelSliders = self.levelRangeFilterType == TRADING_HOUSE_FILTER_TYPE_ALL_LEVEL
    slider:SetEnabled(not disableLevelSliders)
    data.disabled = disableLevelSliders
    valueLabel:SetHidden(disableLevelSliders)

    data.slider = slider

    if self.maxSlider and self.minSlider then
        self.maxSlider:SetMinPair(self.minSlider)
        self.minSlider:SetMaxPair(self.maxSlider)
    end
end

function ZO_GamepadTradingHouse_Browse:InitializeList()
    ZO_GamepadTradingHouse_ItemList.InitializeList(self)

    function OnTargetChanged(...)
        self:OnTargetChanged(...)
    end
    
    self.itemList:SetOnTargetDataChangedCallback(OnTargetChanged)
    self.itemList:SetAlignToScreenCenter(true)
    self.itemList:AddDataTemplateWithHeader("ZO_GamepadGuildStoreBrowseComboboxTemplate", function(...) self:SetupDropDown(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadGuildStoreBrowseHeaderTemplate")
    self.itemList:AddDataTemplate("ZO_Gamepad_Dropdown_Item_FullWidth", function(...) self:SetupFilterDropDown(...) end)
    self.itemList:AddDataTemplateWithHeader("ZO_GamepadPriceSelectorTemplate", function(...) self:SetupPriceSelector(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadGuildStoreBrowseHeaderTemplate")
    self.itemList:AddDataTemplate("ZO_GamepadPriceSelectorTemplate", function(...) self:SetupPriceSelector(...) end)
    self.itemList:AddDataTemplate("ZO_GamepadGuildStoreBrowseSliderTemplate", function(...) self:SetupSlider(...) end)
end

function ZO_GamepadTradingHouse_Browse:ResetFilterValuesToDefaults()
    self:SetMinPriceAmount(MIN_POSTING_AMOUNT)
    self:SetMaxPriceAmount(MAX_PLAYER_MONEY)
    self.validPrice = true

    -- If the slider control exists we update it directly which will in turn call ZO_GuildStoreBrowse_SliderOnValueChanged
    -- otherwise directly set the internal values and when they're created the slider will be set at the correct starting position
    if self.minSlider then
        self.minSlider:SetValue(MINIMUM_PLAYER_LEVEL)
    else
        self:SetMinLevel(MINIMUM_PLAYER_LEVEL)
    end

    if self.maxSlider then
        self.maxSlider:SetValue(GetMaxLevel())
    else
        self:SetMaxLevel(GetMaxLevel())
    end

    self.lastCategoryEntryName = nil
    self.lastQualityEntryName = nil
    self.lastCategoryIndex = 1
    self.lastQualityIndex = 1
    self.qualityMin = ITEM_QUALITY_TRASH
    self.qualityMax = ITEM_QUALITY_LEGENDARY
    self.levelRangeFilterType = TRADING_HOUSE_FILTER_TYPE_LEVEL
    self.lastLevelEntryName = nil
    self.lastLevelIndex = 1
end

function ZO_GamepadTradingHouse_Browse:OnHiding()
    if self.dropDown then
        self.dropDown:Deactivate()
    end

    self:UnfocusPriceSelector()
end

function ZO_GamepadTradingHouse_Browse:OnHidden()
    if self.focusedSlider then
        self.focusedSlider:Deactivate()
        self.focusedSlider = nil
    end
end

function ZO_GamepadTradingHouse_Browse:OnShowing()
    self:PerformDeferredInitialization()
    self:OnTargetChanged(self.itemList, self.itemList:GetTargetData())
end

function ZO_GamepadTradingHouse_Browse:ShowResults()
    GAMEPAD_TRADING_HOUSE_BROWSE_MANAGER:NewFilteredSearch()
end

function ZO_GamepadTradingHouse_Browse:UpdateForGuildChange()
   ZO_TradingHouse_SearchCriteriaChanged(SEARCH_CRITERIA_CHANGED)
end

-- Globals

function ZO_GuildStoreBrowse_SliderOnValueChanged(control, value)
    local sliderMode = control.sliderMode
    if sliderMode == MIN_LEVEL_SLIDER_MODE then
        GAMEPAD_TRADING_HOUSE_BROWSE:SetMinLevel(value)    
    elseif sliderMode == MAX_LEVEL_SLIDER_MODE then
        GAMEPAD_TRADING_HOUSE_BROWSE:SetMaxLevel(value)
    end
end

function ZO_TradingHouse_Browse_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_BROWSE = ZO_GamepadTradingHouse_Browse:New(control)
end

----------------------------------------------------------
-- Gamepad Trading House Browse Manager
----------------------------------------------------------

-- Manages switching back and forth between the browse filters and the browse results and communication between the filters screen and the results screen

ZO_GamepadTradingHouse_BrowseManager = ZO_Object:Subclass()

function ZO_GamepadTradingHouse_BrowseManager:New()
    return ZO_Object.New(self)
end

function ZO_GamepadTradingHouse_BrowseManager:RegisterForEvents(...)
    GAMEPAD_TRADING_HOUSE_BROWSE:RegisterForEvents(...)
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:RegisterForEvents(...)
end

function ZO_GamepadTradingHouse_BrowseManager:OnInitialInteraction()
    self.activeTabContents = GAMEPAD_TRADING_HOUSE_BROWSE
    self.inactiveTabContents = GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS
    self.activeTabContents:OnInitialInteraction()
    self.inactiveTabContents:OnInitialInteraction()
end

function ZO_GamepadTradingHouse_BrowseManager:OnEndInteraction()
    self.activeTabContents:OnEndInteraction()
    self.inactiveTabContents:OnEndInteraction()
    self.activeTabContents = GAMEPAD_TRADING_HOUSE_BROWSE
    self.inactiveTabContents = GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS
end

function ZO_GamepadTradingHouse_BrowseManager:UpdateForGuildChange()
    self.activeTabContents:UpdateForGuildChange()
end

function ZO_GamepadTradingHouse_BrowseManager:UpdateKeybind()
    if self.activeTabContents then
        self.activeTabContents:UpdateKeybind()
    end
end

function ZO_GamepadTradingHouse_BrowseManager:Show()
    self.activeTabContents:Show()
end

function ZO_GamepadTradingHouse_BrowseManager:Hide()
    self.activeTabContents:Hide()
    self.inactiveTabContents:Hide()
end

function ZO_GamepadTradingHouse_BrowseManager:Toggle()
    self.activeTabContents, self.inactiveTabContents = self.inactiveTabContents, self.activeTabContents
    self.inactiveTabContents:Hide()
    self.activeTabContents:Show()
end

function ZO_GamepadTradingHouse_BrowseManager:NewFilteredSearch()
    if TRADING_HOUSE_GAMEPAD:GetSearchAllowed() and GetTradingHouseCooldownRemaining() > 0 then
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_PROCESSING_PRIOR))
    else
        self:Toggle()
    end
end

function ZO_GamepadTradingHouse_BrowseManager:SetAwaitingResponse(...)
    self.activeTabContents:SetAwaitingResponse(...)
    self.inactiveTabContents:SetAwaitingResponse(...)
end

GAMEPAD_TRADING_HOUSE_BROWSE_MANAGER = ZO_GamepadTradingHouse_BrowseManager:New()