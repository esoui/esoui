BANKING_GAMEPAD_MODE_WITHDRAW = 1
BANKING_GAMEPAD_MODE_DEPOSIT = 2

local BANK_SEARCH_SORT_PRIMARY_KEY =
{
    [ITEM_LIST_SORT_TYPE_CATEGORY] = "bestGamepadItemCategoryName",
    [ITEM_LIST_SORT_TYPE_ITEM_NAME] = "name",
    [ITEM_LIST_SORT_TYPE_ITEM_QUALITY] = "displayQuality",
    [ITEM_LIST_SORT_TYPE_STACK_COUNT] = "stackCount",
    [ITEM_LIST_SORT_TYPE_VALUE] = "sellPrice",
}

local BANK_SEARCH_FILTERS =
{
    ITEMFILTERTYPE_WEAPONS,
    ITEMFILTERTYPE_ARMOR,
    ITEMFILTERTYPE_JEWELRY,
    ITEMFILTERTYPE_CONSUMABLE,
    ITEMFILTERTYPE_CRAFTING,
    ITEMFILTERTYPE_FURNISHING,
    ITEMFILTERTYPE_MISCELLANEOUS,
}

ZO_ICON_SORT_ARROW_UP = "EsoUI/Art/Miscellaneous/list_sortUp.dds"
ZO_ICON_SORT_ARROW_DOWN = "EsoUI/Art/Miscellaneous/list_sortDown.dds"

-------------------------------------
-- Gamepad Guild Bank Inventory List
-------------------------------------

ZO_GamepadBankCommonInventoryList = ZO_InitializingObject:MultiSubclass(ZO_GamepadInventoryList)

function ZO_GamepadBankCommonInventoryList:Initialize(control, bankMode, ...)
    self:SetBankMode(bankMode)
    ZO_GamepadInventoryList.Initialize(self, control, ...)

    self.list:AddDataTemplate("ZO_GamepadBankCurrencySelectorTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_GamepadBankCommonInventoryList:SetBankMode(mode)
    self.mode = mode
end

function ZO_GamepadBankCommonInventoryList:GetBankMode()
    return self.mode
end

function ZO_GamepadBankCommonInventoryList:IsInWithdrawMode()
    return self.mode == BANKING_GAMEPAD_MODE_WITHDRAW
end

function ZO_GamepadBankCommonInventoryList:IsInDepositMode()
    return self.mode == BANKING_GAMEPAD_MODE_DEPOSIT
end

function ZO_GamepadBankCommonInventoryList:GetTargetControl()
    return self.list:GetTargetControl()
end

--[[
-- ZO_BankingCommon_Gamepad
--]]

ZO_BankingCommon_Gamepad = ZO_Gamepad_ParametricList_BagsSearch_Screen:Subclass()

function ZO_BankingCommon_Gamepad:Initialize(control, bankScene)
    self.isInitialized = false
    self.mode = BANKING_GAMEPAD_MODE_WITHDRAW

    self:SetCurrencyType(CURT_MONEY) --default to gold until list is initialized

    self:CreateEventTable()

    local DONT_ACTIVATE_LIST_ON_SHOW = false
    ZO_Gamepad_ParametricList_BagsSearch_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, DONT_ACTIVATE_LIST_ON_SHOW, bankScene)

    self:InitializeFiltersDialog()
end

local SORT_OPTIONS =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    displayQuality = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    stackCount = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    sellPrice = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

function ZO_BankingCommon_Gamepad:GetCurrentSortParams()
    return BANK_SEARCH_SORT_PRIMARY_KEY[self.withdrawList.currentSortType], SORT_OPTIONS, self.withdrawList.currentSortOrder
end

function ZO_BankingCommon_Gamepad:InitializeFiltersDialog()
    local function OnReleaseDialog(dialog)
        if dialog.dropdowns then
            for _, dropdown in ipairs(dialog.dropdowns) do
                dropdown:Deactivate()
            end
        end
        dialog.dropdowns = nil
    end

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_BANK_SEARCH_FILTERS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup =  function(dialog, data)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GAMEPAD_GUILD_BROWSER_FILTERS_DIALOG_HEADER))
            dialog.dropdowns = {}
            dialog.selectedSortType = dialog.selectedSortType or ITEM_LIST_SORT_TYPE_ITERATION_BEGIN
            local DONT_LIMIT_NUM_ENTRIES = nil
            dialog:setupFunc(DONT_LIMIT_NUM_ENTRIES, data)
        end,
        parametricList =
        {
            {
                header = GetString(SI_GAMEPAD_BANK_SORT_TYPE_HEADER),
                template = "ZO_GamepadDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialogData = data and data.dialog and data.dialog.data
                        local withdrawList = dialogData.bankObject and dialogData.bankObject.withdrawList

                        local dropdown = control.dropdown
                        table.insert(data.dialog.dropdowns, dropdown)

                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown:SetSortsItems(false)
                        dropdown:ClearItems()

                        local function OnSelectedCallback(dropdown, entryText, entry)
                            withdrawList.currentSortType = entry.sortType
                        end

                        for i = ITEM_LIST_SORT_TYPE_ITERATION_BEGIN, ITEM_LIST_SORT_TYPE_ITERATION_END do
                            local entryText = ZO_CachedStrFormat(SI_GAMEPAD_BANK_FILTER_ENTRY_FORMATTER, GetString("SI_ITEMLISTSORTTYPE", i))
                            local newEntry = control.dropdown:CreateItemEntry(entryText, OnSelectedCallback)
                            newEntry.sortType = i
                            control.dropdown:AddItem(newEntry)
                        end

                        dropdown:UpdateItems()

                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)

                        control.dropdown:SelectItemByIndex(withdrawList.currentSortType)
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.dropdown:Activate()
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                },
            },
            {
                header = GetString(SI_GAMEPAD_BANK_SORT_ORDER_HEADER),
                template = "ZO_GamepadDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        local dialogData = dialog and dialog.data
                        local withdrawList = dialogData.bankObject and dialogData.bankObject.withdrawList
                        local dropdown = control.dropdown
                        table.insert(dialog.dropdowns, dropdown)

                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown:SetSortsItems(false)
                        dropdown:ClearItems()

                        local function OnSelectedCallback(dropdown, entryText, entry)
                            withdrawList.currentSortOrder = entry.sortOrder
                            withdrawList.currentSortOrderIndex = entry.index
                        end

                        local sortUpEntry = control.dropdown:CreateItemEntry(GetString(SI_GAMEPAD_BANK_SORT_ORDER_UP_TEXT), OnSelectedCallback)
                        sortUpEntry.sortOrder = ZO_SORT_ORDER_UP
                        sortUpEntry.index = 1
                        control.dropdown:AddItem(sortUpEntry)

                        local sortDownEntry = control.dropdown:CreateItemEntry(GetString(SI_GAMEPAD_BANK_SORT_ORDER_DOWN_TEXT), OnSelectedCallback)
                        sortDownEntry.sortOrder = ZO_SORT_ORDER_DOWN
                        sortDownEntry.index = 2
                        control.dropdown:AddItem(sortDownEntry)

                        dropdown:UpdateItems()

                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)

                        control.dropdown:SelectItemByIndex(withdrawList.currentSortOrderIndex)
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.dropdown:Activate()
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                },
            },
            {
                header = GetString(SI_GAMEPAD_BANK_FILTER_HEADER),
                template = "ZO_GamepadMultiSelectionDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        local dialogData = dialog and dialog.data
                        local withdrawList = dialogData.bankObject and dialogData.bankObject.withdrawList
                        local dropdown = control.dropdown
                        table.insert(dialog.dropdowns, dropdown)

                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown:SetSortsItems(false)
                        dropdown:SetNoSelectionText(GetString(SI_GAMEPAD_BANK_FILTER_DEFAULT_TEXT))
                        dropdown:SetMultiSelectionTextFormatter(GetString(SI_GAMEPAD_BANK_FILTER_DROPDOWN_TEXT))

                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)

                        local dropdownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                        dropdownData:Clear()

                        for _, filterType in ipairs(BANK_SEARCH_FILTERS) do
                            local newEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GAMEPAD_BANK_FILTER_ENTRY_FORMATTER, GetString("SI_ITEMFILTERTYPE", filterType)))
                            newEntry.category = filterType
                            newEntry.callback = function(control, name, item, isSelected)
                                if isSelected then
                                    withdrawList.filterCategories[item.category] = item.category
                                else
                                    withdrawList.filterCategories[item.category] = nil
                                end
                            end

                            dropdownData:AddItem(newEntry)
                            if withdrawList.filterCategories[filterType] then
                                dropdownData:ToggleItemSelected(newEntry)
                            end
                        end
                        dropdown:LoadData(dropdownData)
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.dropdown:Activate()
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                },
            },
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    local dialogData = dialog.data
                    local withdrawList = dialogData.bankObject and dialogData.bankObject.withdrawList
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_BANK_SEARCH_FILTERS")
                    withdrawList:RefreshList()
                end,
            },
            {
                keybind = "DIALOG_RESET",
                text = SI_GUILD_BROWSER_RESET_FILTERS_KEYBIND,
                enabled = function(dialog)
                    local dialogData = dialog.data
                    return not dialogData.bankObject:AreFiltersSetToDefault()
                end,
                callback = function(dialog)
                    local dialogData = dialog and dialog.data
                    dialogData.bankObject:ResetFilters()
                    dialog.info.setup(dialog)
                end,
            },
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })
end

function ZO_BankingCommon_Gamepad:ResetFilters()
    self.withdrawList.filterCategories = {}
    self.withdrawList.currentSortType = ITEM_LIST_SORT_TYPE_CATEGORY
    self.withdrawList.currentSortOrder = ZO_SORT_ORDER_UP
    self.withdrawList.currentSortOrderIndex = 1
end

function ZO_BankingCommon_Gamepad:AreFiltersSetToDefault()
    return ZO_IsTableEmpty(self.withdrawList.filterCategories) and
        self.withdrawList.currentSortType == ITEM_LIST_SORT_TYPE_CATEGORY and
        self.withdrawList.currentSortOrder == ZO_SORT_ORDER_UP and
        self.withdrawList.currentSortOrderIndex == 1
end

function ZO_BankingCommon_Gamepad:OnStateChanged(oldState, newState)
    ZO_Gamepad_ParametricList_BagsSearch_Screen.OnStateChanged(self, oldState, newState)

    if newState == SCENE_SHOWING then
        self:PerformDeferredInitialize()
        self:RegisterForEvents()

        self:RefreshHeaderData()
        ZO_GamepadGenericHeader_Activate(self.header)
        self.header:SetHidden(false)

        local currentList = self:GetMainListForMode()
        self:SetCurrentList(currentList)

        self:RefreshKeybinds()
        self:OnSceneShowing()
    elseif newState == SCENE_SHOWN then
        self:OnSceneShown()
    elseif newState == SCENE_HIDING then
        self:HideSelector()
        self:OnTargetChanged(nil)
        self:OnSceneHiding()
    elseif newState == SCENE_HIDDEN then
        self:UnregisterForEvents()

        self:DisableCurrentList()

        ZO_GamepadGenericHeader_Deactivate(self.header)
        self.header:SetHidden(true)

        self:RemoveKeybinds()
        self:OnSceneHidden()
    end
end

do
    local ENTRY_ORDER_CURRENCY = 1
    local ENTRY_ORDER_OTHER = 2
    function ZO_BankingCommon_Gamepad:OnDeferredInitialize()
        self:InitializeLists()

        self:ResetFilters()

        self.withdrawList.list:SetSortFunction(function(left, right)
            local leftOrder = ENTRY_ORDER_OTHER
            if left.isCurrenciesMenuEntry or left.currencyType then
                leftOrder = ENTRY_ORDER_CURRENCY
            end

            local rightOrder = ENTRY_ORDER_OTHER
            if right.isCurrenciesMenuEntry or right.currencyType then
                rightOrder = ENTRY_ORDER_CURRENCY
            end

            if leftOrder < rightOrder then
                return true
            elseif leftOrder > rightOrder then
                return false
            elseif leftOrder == ENTRY_ORDER_OTHER then
                return ZO_TableOrderingFunction(left, right, self:GetCurrentSortParams())
            else
                return false
            end
        end)

        self:InitializeHeader()

        self:InitializeWithdrawDepositKeybindDescriptor()
        self:InitializeWithdrawDepositSelector()

        self:OnDeferredInitialization()

        self:SetMode(self.mode)
    end
end

function ZO_BankingCommon_Gamepad:InitializeHeader()
    -- create tabs
    local withdrawTabData = self:CreateModeData(SI_BANK_WITHDRAW, BANKING_GAMEPAD_MODE_WITHDRAW, self.withdrawList, self.withdrawKeybindStripDescriptor)
    local depositTabData = self:CreateModeData(SI_BANK_DEPOSIT, BANKING_GAMEPAD_MODE_DEPOSIT, self.depositList, self.depositKeybindStripDescriptor)

    self.tabsTable =
    {
        {
            text = GetString(SI_BANK_WITHDRAW),
            callback = function() self:OnCategoryChanged(withdrawTabData) end,
        },
        {
            text = GetString(SI_BANK_DEPOSIT),
            callback = function() self:OnCategoryChanged(depositTabData) end,
        },
    }

    -- create header
    self.headerData =
    {
        data1HeaderText = GetString(SI_GAMEPAD_BANK_BANK_FUNDS_LABEL),
        data1Text = function(...) return self:SetCurrentBankedAmount(...) end,
        data1TextNarration = function(...) return self:GetCurrentBankedAmountNarration(...) end,

        data2HeaderText = GetString(SI_GAMEPAD_BANK_PLAYER_FUNDS_LABEL),
        data2Text = function(...) return self:SetCurrentCarriedAmount(...) end,
        data2TextNarration = function(...) return self:GetCurrentCarriedAmountNarration(...) end,

        tabBarEntries = self.tabsTable
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_BankingCommon_Gamepad:InitializeWithdrawDepositSelector()
    local function OnUpdateEvent()
        if not self.selectorContainer:IsControlHidden() then
            self:UpdateInput()
        end
    end

    local selectorContainer = self.control:GetNamedChild("SelectorContainer")
    self.selector = ZO_CurrencySelector_Gamepad:New(selectorContainer:GetNamedChild("Selector"))
    self.selector:SetClampValues(true)
    self.selectorCurrency = selectorContainer:GetNamedChild("CurrencyTexture")

    selectorContainer:RegisterForEvent(EVENT_CARRIED_CURRENCY_UPDATE, OnUpdateEvent)
    selectorContainer:RegisterForEvent(EVENT_BANKED_CURRENCY_UPDATE, OnUpdateEvent)
    selectorContainer:RegisterForEvent(EVENT_GUILD_BANKED_MONEY_UPDATE, OnUpdateEvent)
    selectorContainer:RegisterForEvent(EVENT_GUILD_BANK_ITEMS_READY, OnUpdateEvent)
    self.selector:RegisterCallback("OnValueChanged", function() self:UpdateInput(self.selector:GetValue()) end)

    self.selectorContainer = selectorContainer
end

function ZO_BankingCommon_Gamepad:InitializeWithdrawDepositKeybindDescriptor()
    self.selectorKeybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = function()
                if self:IsInWithdrawMode() then
                    return GetString(SI_BANK_WITHDRAW_BIND)
                elseif self:IsInDepositMode() then
                    return GetString(SI_BANK_DEPOSIT_BIND)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                return self.hasEnough
            end,
            callback = function()
                local amount = self.selector:GetValue()
                local data = self:GetTargetData()

                if self:IsInWithdrawMode() then
                    self:WithdrawFunds(data.currencyType, amount)
                elseif self:IsInDepositMode() then
                    self:DepositFunds(data.currencyType, amount)
                end
                self:HideSelector()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:HideSelector()
            end,
        },
    }
end

function ZO_BankingCommon_Gamepad:SetSelectorCurrency(currencyType)
    self.selectorCurrency:SetTexture(ZO_Currency_GetGamepadCurrencyIcon(currencyType))
    self.selector:SetCurrencyType(currencyType)
end

function ZO_BankingCommon_Gamepad:UpdateInput()
    local currentFunds = self.maxInputFunction(self.currencyType)

    self.selector:SetMaxValue(currentFunds)
    self:SetSelectorCurrency(self.currencyType)

    local hasEnough = currentFunds >= self.selector:GetValue()
    self.hasEnough = hasEnough
    self.selector:SetTextColor(hasEnough and ZO_SELECTED_TEXT or ZO_ERROR_COLOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectorKeybindStripDescriptor) -- The keybindings need visible to check for self.hasEnough
end

local function OnSelectedDataChanged(list, selectedData)
    local selector = selectedData.selectorContainer
    if selector then
        list:GetTargetControl():SetHidden(true)
        selectedData.selectorContainer = nil
        list:RemoveOnSelectedDataChangedCallback(OnSelectedDataChanged)
    end
end

function ZO_BankingCommon_Gamepad:ShowSelector()
    self:UpdateInput()
    self.selectorContainer:SetHidden(false)
    self:DeactivateCurrentList()

    local currentList = self:GetCurrentList()
    local targetControl = currentList:GetTargetControl()
    if targetControl then
        targetControl:SetHidden(true)
    else
        --if the targetControl doesn't exist because of trigger scrolling, wait til selection changed to hide control
        currentList:SetOnSelectedDataChangedCallback(OnSelectedDataChanged)
        local targetData = currentList:GetTargetData()
        if targetData then
            targetData.selectorContainer = self.selectorContainer
        end
    end
    
    self.selector:Activate()
    self:RemoveKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.selectorKeybindStripDescriptor)

    self.selectorActive = true
end

function ZO_BankingCommon_Gamepad:SetMaxInputFunction(maxInputFunction)
    self.maxInputFunction = maxInputFunction
end

function ZO_BankingCommon_Gamepad:HideSelector()
    if self.selectorActive then
        self.selectorContainer:SetHidden(true)
        self.selector:Clear()
        self.selector:Deactivate()
        self:ActivateCurrentList()

        local currentList = self:GetCurrentList()
        currentList:GetTargetControl():SetHidden(false)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.selectorKeybindStripDescriptor)
        self:AddKeybinds()
        self.selectorActive = false
    end
end

function ZO_BankingCommon_Gamepad:RegisterForEvents()
    local control = self.control
    for event, callback in pairs(self.eventTable) do
        control:RegisterForEvent(event, callback)
    end
end

function ZO_BankingCommon_Gamepad:UnregisterForEvents()
    local control = self.control
    for event, callback in pairs(self.eventTable) do
        control:UnregisterForEvent(event)
    end
end

function ZO_BankingCommon_Gamepad:SetWithdrawList(list)
    self.withdrawList = list
end

function ZO_BankingCommon_Gamepad:SetDepositList(list)
    self.depositList = list
end

function ZO_BankingCommon_Gamepad:ClearBankedBags()
    self.bankedBags = {}
end

-- set the bag(s) that will be banked from, banked is a word.
function ZO_BankingCommon_Gamepad:AddBankedBag(bag)
    if self.bankedBags then
        table.insert(self.bankedBags, bag)
    else
        self.bankedBags = {bag}
    end
end

-- set the bag that the player is carrying, probably always backpack
function ZO_BankingCommon_Gamepad:SetCarriedBag(bag)
    self.carriedBag = bag
end

function ZO_BankingCommon_Gamepad:SetCurrencyType(type)
    self.currencyType = type
end

function ZO_BankingCommon_Gamepad:SetDepositKeybindDescriptor(descriptor)
    self.depositKeybindStripDescriptor = descriptor
end

function ZO_BankingCommon_Gamepad:SetWithdrawKeybindDescriptor(descriptor)
    self.withdrawKeybindStripDescriptor = descriptor
end

function ZO_BankingCommon_Gamepad:SetCurrentKeybindDescriptor(descriptor)
    self.currentKeybindStripDescriptor = descriptor
end

function ZO_BankingCommon_Gamepad:SetMode(mode)
    self.mode = mode
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, mode)
end

function ZO_BankingCommon_Gamepad:CreateModeData(name, mode, itemList, keybind)
    return {
        text = GetString(name),
        mode = mode,
        itemList = itemList,
        keybind = keybind,
    }
end

function ZO_BankingCommon_Gamepad:RefreshHeaderData()
    local headerData = self.headerData

    if self.currencyType then
        headerData.data1HeaderText = GetString(SI_GAMEPAD_BANK_BANK_FUNDS_LABEL)
        headerData.data1Text = function(...) return self:SetCurrentBankedAmount(...) end
        headerData.data1TextNarration = function(...) return self:GetCurrentBankedAmountNarration(...) end

        headerData.data2HeaderText = GetString(SI_GAMEPAD_BANK_PLAYER_FUNDS_LABEL)
        headerData.data2Text = function(...) return self:SetCurrentCarriedAmount(...) end
        headerData.data2TextNarration = function(...) return self:GetCurrentCarriedAmountNarration(...) end
    else
        if GetBankingBag() == BAG_BANK then
            headerData.data1HeaderText = GetString(SI_GAMEPAD_BANK_BANK_CAPACITY_LABEL)
        else
            headerData.data1HeaderText = GetString(SI_GAMEPAD_BANK_HOUSE_BANK_CAPACITY_LABEL)
        end
        headerData.data1Text = function(...) return self:SetBankCapacityHeaderText(...) end
        headerData.data1TextNarration = nil

        headerData.data2HeaderText = GetString(SI_GAMEPAD_BANK_PLAYER_CAPACITY_LABEL)
        headerData.data2Text = function(...) return self:SetPlayerCapacityHeaderText(...) end
        headerData.data2TextNarration = nil
    end

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
    self:OnRefreshHeaderData()
end

function ZO_BankingCommon_Gamepad:OnCategoryChanged(selectedData)
    self.mode = selectedData.mode
    self:HideSelector()

    self:SetCurrentList(selectedData.itemList)
    self:SetCurrentKeybindDescriptor(selectedData.keybind)

    self:OnCategoryChangedCallback(selectedData)
end

function ZO_BankingCommon_Gamepad:SetCurrentCarriedAmount(control)
    local moneyAmount = self:GetDepositMoneyAmount()

    self:SetSimpleCurrency(control, moneyAmount, self.currencyType, BANKING_GAMEPAD_MODE_DEPOSIT, ZO_BANKING_CURRENCY_LABEL_OPTIONS)
    -- must return a non-nil value so that the control isn't auto-hidden
    return true
end

function ZO_BankingCommon_Gamepad:GetCurrentCarriedAmountNarration(control)
    return ZO_Currency_FormatGamepad(self.currencyType, self:GetDepositMoneyAmount(), ZO_CURRENCY_FORMAT_AMOUNT_NAME)
end

function ZO_BankingCommon_Gamepad:SetCurrentBankedAmount(control)
    local moneyAmount = self:GetWithdrawMoneyAmount()
    local currencyOptions = self:GetWithdrawMoneyOptions()
    local obfuscateAmount = self:DoesObfuscateWithdrawAmount()

    self:SetSimpleCurrency(control, moneyAmount, self.currencyType, BANKING_GAMEPAD_MODE_WITHDRAW, currencyOptions, obfuscateAmount)
    -- must return a non-nil value so that the control isn't auto-hidden
    return true
end

function ZO_BankingCommon_Gamepad:GetCurrentBankedAmountNarration(control)
    local displayOptions =
    {
        obfuscateAmount = self:DoesObfuscateWithdrawAmount(),
    }
    return ZO_Currency_FormatGamepad(self.currencyType, self:GetWithdrawMoneyAmount(), ZO_CURRENCY_FORMAT_AMOUNT_NAME, displayOptions)
end

function ZO_BankingCommon_Gamepad:GetCurrencyType()
    return self.currencyType
end 

-- private functions

function ZO_BankingCommon_Gamepad:SetSimpleCurrency(control, amount, currencyType, colorMinValueForMode, options, obfuscateAmount)
    options.color = nil -- Reset the color

    if self:IsInWithdrawMode() then
        if (colorMinValueForMode == self.mode and amount == 0) or (colorMinValueForMode ~= self.mode and amount == self:GetMaxBankedFunds(currencyType)) then
            options.color = ZO_ERROR_COLOR
        end
    elseif self:IsInDepositMode() then
        if (colorMinValueForMode == self.mode and amount == 0) or (colorMinValueForMode ~= self.mode and amount == GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER)) then
            options.color = ZO_ERROR_COLOR
        end
    end

    local displayOptions =
    {
        obfuscateAmount = obfuscateAmount,
    }
    ZO_CurrencyControl_SetSimpleCurrency(control, currencyType, amount, options, CURRENCY_SHOW_ALL, CURRENCY_IGNORE_HAS_ENOUGH, displayOptions)
end

function ZO_BankingCommon_Gamepad:RecolorCapacityHeader(control, usedSlots, bagSize, recolorMode)
    local color = ZO_SELECTED_TEXT

    if recolorMode == self.mode and usedSlots >= bagSize then
        color = ZO_ERROR_COLOR
    end

    control:SetColor(color:UnpackRGBA())
end

function ZO_BankingCommon_Gamepad:SetBankCapacityHeaderText(control)
    local usedSlots = 0
    local bagSize = 0

    if self.bankedBags then
        for index, bagId in ipairs(self.bankedBags) do  
            usedSlots = usedSlots + GetNumBagUsedSlots(bagId)
            bagSize = bagSize + GetBagUseableSize(bagId)
        end
    end

    self:RecolorCapacityHeader(control, usedSlots, bagSize, BANKING_GAMEPAD_MODE_DEPOSIT)

    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, usedSlots, bagSize)
end

function ZO_BankingCommon_Gamepad:SetPlayerCapacityHeaderText(control)
    local usedSlots = GetNumBagUsedSlots(self.carriedBag)
    local bagSize = GetBagSize(self.carriedBag)

    self:RecolorCapacityHeader(control, usedSlots, bagSize, BANKING_GAMEPAD_MODE_WITHDRAW)

    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, usedSlots, bagSize)
end

function ZO_BankingCommon_Gamepad:OnTargetChanged(list, targetData, oldTargetData)
    self:SetCurrencyType(targetData and targetData.currencyType or nil)
    self:LayoutBankingEntryTooltip(targetData)
    self:OnTargetChangedCallback(targetData, oldTargetData)

    self:RefreshHeaderData()
end

function ZO_BankingCommon_Gamepad:LayoutBankingEntryTooltip(inventoryData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
    if inventoryData and inventoryData.bagId then
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
        ZO_LayoutBagItemEquippedComparison(GAMEPAD_RIGHT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
    end
end

function ZO_BankingCommon_Gamepad:GetTargetData()
    local currentList = self:GetCurrentList()
    if currentList then
        return currentList:GetTargetData()
    end
end

function ZO_BankingCommon_Gamepad:GetMode()
    return self.mode
end

function ZO_BankingCommon_Gamepad:IsInWithdrawMode()
    return self.mode == BANKING_GAMEPAD_MODE_WITHDRAW
end

function ZO_BankingCommon_Gamepad:IsInDepositMode()
    return self.mode == BANKING_GAMEPAD_MODE_DEPOSIT
end

function ZO_BankingCommon_Gamepad:GetMainListForMode()
    return self:IsInWithdrawMode() and self.withdrawList or self.depositList
end

-- functions that must be overwritten

function ZO_BankingCommon_Gamepad:GetWithdrawMoneyAmount()
    assert(false)
end

function ZO_BankingCommon_Gamepad:GetWithdrawMoneyOptions()
    assert(false)
end

function ZO_BankingCommon_Gamepad:DoesObfuscateWithdrawAmount()
    assert(false)
end

function ZO_BankingCommon_Gamepad:GetMaxedBankedFunds(currencyType)
    assert(false)
end

function ZO_BankingCommon_Gamepad:GetDepositMoneyAmount()
    assert(false)
end

function ZO_BankingCommon_Gamepad:DepositFunds(currencyType, amount)
    assert(false)
end

function ZO_BankingCommon_Gamepad:WithdrawFunds(currencyType, amount)
    assert(false)
end

function ZO_BankingCommon_Gamepad:AddKeybinds()
    assert(false)
end

function ZO_BankingCommon_Gamepad:RemoveKeybinds()
    assert(false)
end

function ZO_BankingCommon_Gamepad:UpdateKeybinds()
    assert(false)
end

-- optional functions for subclasses

function ZO_BankingCommon_Gamepad:OnSceneShowing()
end

function ZO_BankingCommon_Gamepad:OnSceneShown()
end

function ZO_BankingCommon_Gamepad:OnSceneHiding()
end

function ZO_BankingCommon_Gamepad:OnSceneHidden()
end

function ZO_BankingCommon_Gamepad:OnCategoryChangedCallback(selectedData)
    local list = self:GetCurrentList()
    if list then
        local TRIGGER_CALLBACK = true
        list:RefreshList(TRIGGER_CALLBACK)
    end
end

function ZO_BankingCommon_Gamepad:OnTargetChangedCallback(targetData, oldTargetData)
    self:UpdateKeybinds()
end

function ZO_BankingCommon_Gamepad:OnDeferredInitialization()
end

function ZO_BankingCommon_Gamepad:CreateEventTable()
    self.eventTable = {}
end

function ZO_BankingCommon_Gamepad:InitializeLists()
end

function ZO_BankingCommon_Gamepad:OnRefreshHeaderData()
end