ZO_GAMEPAD_GUILD_STORE_BROWSE_SLIDER_OFFSET_Y = 15

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

    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:AddFragmentsToSubscene(self:GetSubscene())

    self:InitializeFeatures()
end

function ZO_GamepadTradingHouse_Browse:InitializeFeatures()
    -- Don't forget to add your new feature to ZO_GamepadTradingHouse_Browse:RefreshList
    self.features = 
    {
        nameSearchFeature = ZO_TradingHouse_CreateGamepadFeature("NameSearch"),
        searchCategoryFeature = ZO_TradingHouse_CreateGamepadFeature("SearchCategory"),
        priceRangeFeature = ZO_TradingHouse_CreateGamepadFeature("PriceRange"),
        qualityFeature = ZO_TradingHouse_CreateGamepadFeature("Quality"),
    }
    self.features.priceRangeFeature:AttachToControl(self.control:GetNamedChild("PriceSelectorContainer"))
    self.features.nameSearchFeature:RegisterCallback("OnNameMatchComplete", function(...) self:OnNameMatchComplete(...) end)

    local function FilterForGamepadEvents(callback)
        return function(...)
            if IsInGamepadPreferredMode() then
                callback(...)
            end
        end
    end

    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchCriteriaChanged", FilterForGamepadEvents(function(...) self:OnSearchCriteriaChanged(...) end))
end

function ZO_GamepadTradingHouse_Browse:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local targetData = self.itemList:GetTargetData()

                if targetData.dropDown then
                    self:FocusDropDown(targetData.dropDown)
                elseif targetData.priceSelector then
                    self:FocusPriceSelector(targetData)
                elseif targetData.editBoxControl then
                    local editBox = targetData.editBoxControl
                    if editBox:HasFocus() then
                        editBox:LoseFocus()
                    else
                        editBox:TakeFocus()
                    end
                elseif targetData.isSelectableEntry then
                    targetData.onSelectedCallback()
                end
            end,
            visible = function()
                local targetData = self.itemList:GetTargetData()

                if targetData then
                    return targetData.isDropDown or targetData.priceSelectorMode or targetData.editBoxControl or targetData.isSelectableEntry
                else
                    return false
                end
            end,
            enabled = function()
                local targetData = self.itemList:GetTargetData()

                if targetData and targetData.isEnabledCallback then
                    return targetData.isEnabledCallback()
                end
                return true
            end
        },
        {
            name = GetString(SI_GAMEPAD_TRADE_SUBMIT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback =  function()
                TRADING_HOUSE_GAMEPAD:EnterBrowseResults()
            end,
        },
        {
            name = GetString(SI_TRADING_HOUSE_RESET_SEARCH),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                self:ResetSearch()
            end
        },
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }
    self:AddGuildChangeKeybindDescriptor(self.keybindStripDescriptor)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)
end

function ZO_GamepadTradingHouse_Browse:InitializeSearchTerms(search)
    self:ResetFilterValuesToDefaults() -- Initialize values needed for search
end

function ZO_GamepadTradingHouse_Browse:ShowAndThenEnterBrowseResults()
    if GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:IsActive() then
        TRADING_HOUSE_GAMEPAD:EnterBrowseResults()
    else
        --Only enter browse results if the show completes within a second
        self.enterBrowseResultsWhenShowingCutoffMS = GetGameTimeMilliseconds() + 1000
        TRADING_HOUSE_GAMEPAD:SelectHeaderTab(ZO_TRADING_HOUSE_MODE_BROWSE)
    end
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

function ZO_GamepadTradingHouse_Browse:FocusPriceSelector(priceSelectorData)
    self.features.priceRangeFeature:FocusPriceSelector(priceSelectorData)
end

function ZO_GamepadTradingHouse_Browse:UnfocusPriceSelector()
    self.features.priceRangeFeature:UnfocusPriceSelector()
end

function ZO_GamepadTradingHouse_Browse:OnTargetChanged(list, targetData, oldTargetData)
    local newSlider = targetData and targetData.slider

    if self.focusedSlider and self.focusedSlider ~= newSlider then
        self.focusedSlider:Deactivate()
        self.focusedSlider = nil
    end

    if newSlider then
        self.focusedSlider = newSlider
        if self.focusedSlider:GetEnabled() then
            self.focusedSlider:Activate()
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadTradingHouse_Browse:MarkListDirty()
    if not self.listDirty then
        self.listDirty = true
        EVENT_MANAGER:RegisterForUpdate("ZO_GamepadTradingHouse_Browse_ListDirty", 0, function()
            EVENT_MANAGER:UnregisterForUpdate("ZO_GamepadTradingHouse_Browse_ListDirty")
            if self.listDirty then
                self:RefreshList()
            end
        end)
    end
end

function ZO_GamepadTradingHouse_Browse:OnSearchCriteriaChanged(changedByFeature)
    if changedByFeature == self.features.searchCategoryFeature then
        -- Search categories can show/hide extra dropdowns and features depending on which category is selected, so we need to dirty the list to add/remove them
        self:MarkListDirty()
    else
        self:RefreshVisible()
    end
end

function ZO_GamepadTradingHouse_Browse:OnNameMatchComplete()
    self:RefreshVisible()
end

do
    local ENTER_SEARCH_HISTORY_ENTRY_DATA =
    {
        labelText = GetString(SI_TRADING_HOUSE_SEARCH_HISTORY_TITLE),
        isSelectableEntry = true,
        onSelectedCallback = function()
            TRADING_HOUSE_GAMEPAD:EnterSearchHistory()
        end,
    }

    function ZO_GamepadTradingHouse_Browse:AddEnterSearchHistoryEntry(itemList)
        itemList:AddEntry("ZO_GamepadGuildStoreBrowseSelectableEntryTemplate", ENTER_SEARCH_HISTORY_ENTRY_DATA)
    end
end

function ZO_GamepadTradingHouse_Browse:RefreshList()
    self.listDirty = false

    self.itemList:Clear()

    self:AddEnterSearchHistoryEntry(self.itemList)
    self.features.nameSearchFeature:AddEntries(self.itemList)
    self.features.searchCategoryFeature:AddEntries(self.itemList)
    self.features.priceRangeFeature:AddEntries(self.itemList)
    self.features.qualityFeature:AddEntries(self.itemList)

    self.itemList:Commit()
end

function ZO_GamepadTradingHouse_Browse:RefreshVisible()
    self.itemList:RefreshVisible()
end

function ZO_GamepadTradingHouse_Browse:GetFeatures()
    return self.features
end

function ZO_GamepadTradingHouse_Browse:GetNameSearchFeature()
    return self.features.nameSearchFeature
end

-- Overriden functions
function ZO_GamepadTradingHouse_Browse:PerformDeferredInitialization()
    if self.isInitialized then return end
    self:RefreshList()
    self.isInitialized = true
end

function ZO_GamepadTradingHouse_Browse:GetTradingHouseMode()
    return ZO_TRADING_HOUSE_MODE_BROWSE
end

do
    local NO_EQUALITY_FUNCTION = nil
    local NO_HEADER_SETUP_FUNCTION = nil
    function ZO_GamepadTradingHouse_Browse:InitializeList()
        ZO_GamepadTradingHouse_ItemList.InitializeList(self)

        function OnTargetChanged(...)
            self:OnTargetChanged(...)
        end
        
        self.itemList:SetOnTargetDataChangedCallback(OnTargetChanged)
        self.itemList:SetAlignToScreenCenter(true)
        local NAME_SEARCH_INDEX = 2 -- skip search history (index 1)
        self.itemList:SetDefaultSelectedIndex(NAME_SEARCH_INDEX)

        -- Dropdown Templates
        local function OnDropdownDeactivated()
            self:UnfocusDropDown()
        end

        local function SetupDropdownTemplate(control, data, selected, reselectingDuringRebuild, enabled, active)
            control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))

            local dropDown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Dropdown"))
            dropDown:SetSortsItems(false)
            dropDown:SetDeactivatedCallback(OnDropdownDeactivated)
            data.setupCallback(dropDown)
            data.isDropDown = true
            data.dropDown = dropDown
        end

        -- Dropdown templates
        local dropdownTemplateName = "ZO_GamepadGuildStoreBrowseDropdownTemplate"
        local dropdownHeaderTemplateName = "ZO_GamepadGuildStoreBrowseHeaderTemplate"
        -- We're defining a ControlPoolPrefix to get around the limit on control name length. The header variant of this template is just a hair too big.
        local dropdownControlPrefix = "Dropdown"
        self.itemList:AddDataTemplateWithHeader(dropdownTemplateName, SetupDropdownTemplate, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, dropdownHeaderTemplateName, NO_HEADER_SETUP_FUNCTION, dropdownControlPrefix)
        self.itemList:AddDataTemplate(dropdownTemplateName, SetupDropdownTemplate, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, dropdownControlPrefix)

        -- Level Range Templates
        local function SetupSlider(control, data, selected, reselectingDuringRebuild, enabled, active)
            data.feature:SetupSlider(control, data, selected)
        end

        self.itemList:AddDataTemplate("ZO_GamepadGuildStoreBrowseSliderTemplate", SetupSlider)

        -- Price Selector Template
        local function SetupPriceSelector(control, data, selected, reselectingDuringRebuild, enabled, active)
            data.feature:SetupPriceSelector(control, data, selected, reselectingDuringRebuild, enabled, active)
        end

        self.itemList:AddDataTemplateWithHeader("ZO_GamepadPriceSelectorTemplate", SetupPriceSelector, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, "ZO_GamepadGuildStoreBrowseHeaderTemplate")
        self.itemList:AddDataTemplate("ZO_GamepadPriceSelectorTemplate", SetupPriceSelector)

        -- Name Search Template
        local function SetupNameSearchField(control, data, selected, reselectingDuringRebuild, enabled, active)
            data.feature:SetupNameSearchField(control, data, selected, reselectingDuringRebuild, enabled, active)
        end
        self.itemList:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem", SetupNameSearchField, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, "ZO_GamepadGuildStoreBrowseHeaderTemplate")

        -- Selectable Entry Template
        local function SetupSelectableEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
            if data.isEnabledCallback then
                enabled = data.isEnabledCallback()
            end

            control.label:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
            control.label:SetColor(ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, not enabled):UnpackRGBA())

            if type(data.labelText) == 'function' then
                control.label:SetText(data.labelText())
            else
                control.label:SetText(data.labelText)
            end
        end

        self.itemList:AddDataTemplate("ZO_GamepadGuildStoreBrowseSelectableEntryTemplate", SetupSelectableEntry)
    end
end

function ZO_GamepadTradingHouse_Browse:ResetFilterValuesToDefaults()
    for _, feature in pairs(self.features) do
        feature:ResetSearch()
    end
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
    if self.enterBrowseResultsWhenShowingCutoffMS then
        if GetGameTimeMilliseconds() < self.enterBrowseResultsWhenShowingCutoffMS then
            TRADING_HOUSE_GAMEPAD:EnterBrowseResults()
        end
        self.enterBrowseResultsWhenShowingCutoffMS = nil
    end
end

function ZO_GamepadTradingHouse_Browse:ResetSearch()
    self:ResetFilterValuesToDefaults()
    if self.isInitialized then
        self:RefreshList()
        local DONT_ANIMATE = false
        self.itemList:SetDefaultIndexSelected(DONT_ANIMATE)
    end
    TRADING_HOUSE_SEARCH:ResetAllSearchData()
    TRADING_HOUSE_SEARCH:CancelPendingSearch()
end

-- Globals

function ZO_TradingHouse_Browse_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_BROWSE = ZO_GamepadTradingHouse_Browse:New(control)
end
