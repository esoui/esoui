local GUILD_BANK_SEARCH_SORT_PRIMARY_KEY =
{
    [ITEM_LIST_SORT_TYPE_CATEGORY] = "bestGamepadItemCategoryName",
    [ITEM_LIST_SORT_TYPE_ITEM_NAME] = "name",
    [ITEM_LIST_SORT_TYPE_ITEM_QUALITY] = "displayQuality",
    [ITEM_LIST_SORT_TYPE_STACK_COUNT] = "stackCount",
    [ITEM_LIST_SORT_TYPE_VALUE] = "sellPrice",
}

local GUILD_BANK_SEARCH_FILTERS =
{
    ITEMFILTERTYPE_WEAPONS,
    ITEMFILTERTYPE_ARMOR,
    ITEMFILTERTYPE_JEWELRY,
    ITEMFILTERTYPE_CONSUMABLE,
    ITEMFILTERTYPE_CRAFTING,
    ITEMFILTERTYPE_FURNISHING,
    ITEMFILTERTYPE_MISCELLANEOUS,
}

local SORT_ARROW_UP = "EsoUI/Art/Miscellaneous/list_sortUp.dds"
local SORT_ARROW_DOWN = "EsoUI/Art/Miscellaneous/list_sortDown.dds"

-------------------------------------
-- Gamepad Guild Bank Inventory List
-------------------------------------
ZO_GamepadGuildBankInventoryList = ZO_GamepadBankCommonInventoryList:Subclass()

function ZO_GamepadGuildBankInventoryList:New(...)
    return ZO_GamepadBankCommonInventoryList.New(self, ...)
end

function ZO_GamepadGuildBankInventoryList:Initialize(...)
    ZO_GamepadBankCommonInventoryList.Initialize(self, ...)

    self.list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local goldTransferEntryName = self:IsInWithdrawMode() and GetString(SI_GAMEPAD_BANK_WITHDRAW_GOLD_ENTRY_NAME) or GetString(SI_GAMEPAD_BANK_DEPOSIT_GOLD_ENTRY_NAME)
    local goldTransferEntryIcon = self:IsInWithdrawMode() and "EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_gold_withdraw.dds" or "EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_gold_deposit.dds"
    local entryData = ZO_GamepadEntryData:New(goldTransferEntryName, goldTransferEntryIcon)
    entryData:SetIconTintOnSelection(true)
    entryData:SetIconDisabledTintOnSelection(true)
    entryData.currencyType = CURT_MONEY
    self.goldTransferEntryData = entryData
end

function ZO_GamepadGuildBankInventoryList:HasSelectableHeaderEntry()
    return false -- Overridden by classes with selectable headers (ie. Text Search)
end

function ZO_GamepadGuildBankInventoryList:AddPlaceholderEntry()
    -- To be overridden
end

do
    local NO_DEPOSIT_PERMISSIONS_STRING = zo_strformat(SI_GAMEPAD_GUILD_BANK_NO_DEPOSIT_PERMISSIONS, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_BANK_DEPOSIT))
    local NO_WITHDRAW_PERMISSIONS_STRING = GetString(SI_GAMEPAD_GUILD_BANK_NO_WITHDRAW_PERMISSIONS)
    local NO_ITEMS_TO_WITHDRAW_STRING = GetString(SI_GAMEPAD_GUILD_BANK_NO_WITHDRAW_ITEMS)

    local function IsInFilteredCategories(filterCategories, itemData)
        -- No category selected, don't filter out anything.
        if ZO_IsTableEmpty(filterCategories) then
            return true
        end

        for filterDataIndex, filterData in ipairs(itemData.filterData) do
            if filterCategories[filterData] then
                return true
            end
        end

        return false
    end

    function ZO_GamepadGuildBankInventoryList:RefreshList()
        if self.control:IsHidden() then
            self.isDirty = true
            return
        end

        local guildId = GetSelectedGuildBankId()
        local shouldShowList = false
        local hasSelectableHeaderEntry = self:HasSelectableHeaderEntry()

        -- Assume we have all these privileges unless otherwise specified.
        local guildHasDepositPrivilege = true
        local playerCanWithdrawItem = true
        local playerCanWithdrawGold = true

        if guildId then
            guildHasDepositPrivilege = DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_BANK_DEPOSIT)
            playerCanWithdrawItem = DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW)
            playerCanWithdrawGold = DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW_GOLD)

            if GAMEPAD_GUILD_BANK:IsLoadingGuildBank() then
                self:SetNoItemText("")
            elseif self:IsInDepositMode() then
                if not guildHasDepositPrivilege then
                    self:SetNoItemText(NO_DEPOSIT_PERMISSIONS_STRING)
                else
                    shouldShowList = DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_DEPOSIT)
                end
            elseif self:IsInWithdrawMode() then
                if not (playerCanWithdrawItem or playerCanWithdrawGold) then
                    self:SetNoItemText(NO_WITHDRAW_PERMISSIONS_STRING)
                else
                    self:SetNoItemText(NO_ITEMS_TO_WITHDRAW_STRING)
                    shouldShowList = playerCanWithdrawItem
                end
            else
                self:SetNoItemText("")
            end
        else
            self:SetNoItemText("")
        end

        self.list:Clear()

        local function CanWithdrawOrDeposit(currencyType)
            local canUse = true

            -- Check if there are funds to withdraw or if the player's wallet isn't full, depending on the mode
            if self:IsInWithdrawMode() then
                canUse = DoesPlayerHaveGuildPermission(GetSelectedGuildBankId(), GUILD_PERMISSION_BANK_VIEW_GOLD) and GetCurrencyAmount(currencyType, CURRENCY_LOCATION_GUILD_BANK) ~= 0 and 
                            GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER)
            elseif self:IsInDepositMode() then
                canUse = GetCurrencyAmount(currencyType, CURRENCY_LOCATION_GUILD_BANK) ~= GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_GUILD_BANK) and 
                          GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= 0
            end

            return canUse
        end

        local slots = nil
        if shouldShowList then
           slots = self:GenerateSlotTable()
        end

        if not ZO_IsTableEmpty(slots) and hasSelectableHeaderEntry then
            self:AddPlaceholderEntry()
        end

        local shouldAddDepositWithdrawEntry = (self:IsInWithdrawMode() and playerCanWithdrawGold) or (self:IsInDepositMode() and guildHasDepositPrivilege)
        if shouldAddDepositWithdrawEntry then
            self.goldTransferEntryData:SetEnabled(CanWithdrawOrDeposit(CURT_MONEY))
            self.list:AddEntry("ZO_GamepadBankCurrencySelectorTemplate", self.goldTransferEntryData)
        end

        if shouldShowList then
            for i, bagId in ipairs(self.inventoryTypes) do
                self.dataByBagAndSlotIndex[bagId] = {}
            end

            local template = self.template
            local currentBestCategoryName = nil
            for i, itemData in ipairs(slots) do
                local passesTextFilter = itemData.passesTextFilter == nil or itemData.passesTextFilter
                local passesCategoryFilter = IsInFilteredCategories(self.filterCategories, itemData)
                if passesTextFilter and passesCategoryFilter then
                    local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
                    self:SetupItemEntry(entry, itemData)

                    if self.currentSortType == ITEM_LIST_SORT_TYPE_CATEGORY and itemData.bestGamepadItemCategoryName ~= currentBestCategoryName then
                        currentBestCategoryName = itemData.bestGamepadItemCategoryName
                        entry:SetHeader(currentBestCategoryName)
                        self.list:AddEntryWithHeader(template, entry)
                    else
                        self.list:AddEntry(template, entry)
                    end

                    self.dataByBagAndSlotIndex[itemData.bagId][itemData.slotIndex] = entry
                end
            end
        end

        if hasSelectableHeaderEntry then
            self.list:SetDefaultSelectedIndex(2) -- Select withdraw currency rather than placeholder
        end

        self.list:Commit()

        self.isDirty = false
    end
end

do
    local BANK_MODE_INFO =
    {
        [BANKING_GAMEPAD_MODE_DEPOSIT] = { requirement = GUILD_PERMISSION_BANK_DEPOSIT, errorMessage = GetString("SI_GUILDBANKRESULT",  GUILD_BANK_NO_DEPOSIT_PERMISSION)},
        [BANKING_GAMEPAD_MODE_WITHDRAW] = { requirement = GUILD_PERMISSION_BANK_WITHDRAW, errorMessage = GetString("SI_GUILDBANKRESULT", GUILD_BANK_NO_WITHDRAW_PERMISSION)},
    }

    function ZO_GamepadGuildBankInventoryList:SetBankMode(mode)
        local modeInfo = BANK_MODE_INFO[mode]
        if modeInfo then
            self.mode = mode
            self.guildrequirement = modeInfo.requirement
            self.requirementFailMessage = modeInfo.errorMessage
        end
    end
end

-----------------------
-- Gamepad Guild Bank
-----------------------

local GAMEPAD_GUILD_BANK_SCENE_NAME = "gamepad_guild_bank"

ZO_GuildBank_Gamepad = ZO_BankingCommon_Gamepad:Subclass()

function ZO_GuildBank_Gamepad:New(...)
    return ZO_BankingCommon_Gamepad.New(self, ...)
end

function ZO_GuildBank_Gamepad:Initialize(control)
    self.withdrawLoadingControlShown = false

    GAMEPAD_GUILD_BANK_SCENE = ZO_InteractScene:New(GAMEPAD_GUILD_BANK_SCENE_NAME, SCENE_MANAGER, GUILD_BANKING_INTERACTION)
    ZO_BankingCommon_Gamepad.Initialize(self, control, GAMEPAD_GUILD_BANK_SCENE)

    self:ClearBankedBags()
    self:AddBankedBag(BAG_GUILDBANK)
    self:SetCarriedBag(BAG_BACKPACK)

    local function OnOpenGuildBank()
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show(GAMEPAD_GUILD_BANK_SCENE_NAME)
        end
    end

    self.control:RegisterForEvent(EVENT_OPEN_GUILD_BANK, OnOpenGuildBank)
    self.control:RegisterForEvent(EVENT_BACKGROUND_LIST_FILTER_COMPLETE, function(eventId, ...) self:OnBackgroundListFilterComplete(...) end)

    self:InitializeFiltersDialog()
end

function ZO_GuildBank_Gamepad:GetCurrentSortParams()
    local sortKey = GUILD_BANK_SEARCH_SORT_PRIMARY_KEY[self.withdrawList.currentSortType]
    local sortOptions =
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
    local sortOrder = self.withdrawList.currentSortOrder
    return sortKey, sortOptions, sortOrder
end

function ZO_GuildBank_Gamepad:InitializeFiltersDialog()
    local function OnReleaseDialog(dialog)
        if dialog.dropdowns then
            for i, dropdown in pairs(dialog.dropdowns) do
                dropdown:Deactivate()
            end
        end
        dialog.dropdowns = nil
    end

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_GUILD_BANK_SEARCH_FILTERS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup =  function(dialog)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GAMEPAD_GUILD_BROWSER_FILTERS_DIALOG_HEADER))
            dialog.dropdowns = {}
            dialog.selectedSortType = dialog.selectedSortType or ITEM_LIST_SORT_TYPE_ITERATION_BEGIN
            dialog:setupFunc()
        end,
        parametricList =
        {
            {
                header = GetString(SI_GAMEPAD_BANK_SORT_TYPE_HEADER),
                template = "ZO_GamepadDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dropdown = control.dropdown
                        table.insert(data.dialog.dropdowns, dropdown)

                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown:SetSortsItems(false)
                        dropdown:ClearItems()

                        local function OnSelectedCallback(dropdown, entryText, entry)
                            self.withdrawList.currentSortType = entry.sortType
                        end

                        for i = ITEM_LIST_SORT_TYPE_ITERATION_BEGIN, ITEM_LIST_SORT_TYPE_ITERATION_END do
                            local entryText = ZO_CachedStrFormat(SI_GAMEPAD_BANK_FILTER_ENTRY_FORMATTER, GetString("SI_ITEMLISTSORTTYPE", i))
                            local newEntry = control.dropdown:CreateItemEntry(entryText, OnSelectedCallback)
                            newEntry.sortType = i
                            control.dropdown:AddItem(newEntry)
                        end

                        dropdown:UpdateItems()

                        control.dropdown:SelectItemByIndex(self.withdrawList.currentSortType)
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.dropdown:Activate()
                    end,
                },
            },
            {
                header = GetString(SI_GAMEPAD_BANK_SORT_ORDER_HEADER),
                template = "ZO_GamepadDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dropdown = control.dropdown
                        table.insert(data.dialog.dropdowns, dropdown)

                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown:SetSortsItems(false)
                        dropdown:ClearItems()

                        local function OnSelectedCallback(dropdown, entryText, entry)
                            self.withdrawList.currentSortOrder = entry.sortOrder
                            self.withdrawList.currentSortOrderIndex = entry.index
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

                        control.dropdown:SelectItemByIndex(self.withdrawList.currentSortOrderIndex)
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.dropdown:Activate()
                    end,
                },
            },
            {
                header = GetString(SI_GAMEPAD_BANK_FILTER_HEADER),
                template = "ZO_GamepadMultiSelectionDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dropdown = control.dropdown
                        table.insert(data.dialog.dropdowns, dropdown)

                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown:SetSortsItems(false)
                        dropdown:SetNoSelectionText(GetString(SI_GAMEPAD_BANK_FILTER_DEFAULT_TEXT))
                        dropdown:SetMultiSelectionTextFormatter(GetString(SI_GAMEPAD_BANK_FILTER_DROPDOWN_TEXT))

                        local dropdownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                        dropdownData:Clear()

                        for i, filterType in pairs(GUILD_BANK_SEARCH_FILTERS) do
                            local newEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GAMEPAD_BANK_FILTER_ENTRY_FORMATTER, GetString("SI_ITEMFILTERTYPE", filterType)))
                            newEntry.category = filterType
                            newEntry.callback = function(control, name, item, isSelected)
                                if isSelected then
                                    self.withdrawList.filterCategories[item.category] = item.category
                                else
                                    self.withdrawList.filterCategories[item.category] = nil
                                end
                            end

                            dropdownData:AddItem(newEntry)
                            if self.withdrawList.filterCategories[filterType] then
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
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_GUILD_BANK_SEARCH_FILTERS")
                    self.withdrawList:RefreshList()
                end,
            },
            {
                keybind = "DIALOG_RESET",
                text = SI_GUILD_BROWSER_RESET_FILTERS_KEYBIND,
                enabled = function(dialog)
                    return not self:AreFiltersSetToDefault()
                end,
                callback = function(dialog)
                    self:ResetFilters()
                    dialog.info.setup(dialog)
                end,
            },
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })
end

function ZO_GuildBank_Gamepad:ResetFilters()
    self.withdrawList.filterCategories = {}
    self.withdrawList.currentSortType = ITEM_LIST_SORT_TYPE_CATEGORY
    self.withdrawList.currentSortOrder = ZO_SORT_ORDER_UP
    self.withdrawList.currentSortOrderIndex = 1
end

function ZO_GuildBank_Gamepad:AreFiltersSetToDefault()
    return ZO_IsTableEmpty(filterCategories) and
        self.withdrawList.currentSortType == ITEM_LIST_SORT_TYPE_CATEGORY and
        self.withdrawList.currentSortOrder == ZO_SORT_ORDER_UP and
        self.withdrawList.currentSortOrderIndex == 1
end

function ZO_GuildBank_Gamepad:OnSceneShowing()
    ZO_SharedInventory_SelectAccessibleGuildBank(self.lastSelectedGuildBankId)
    self:RefreshGuildBank()
    TriggerTutorial(TUTORIAL_TRIGGER_GUILD_BANK_OPENED)
end

function ZO_GuildBank_Gamepad:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindStripDescriptor)
end

function ZO_GuildBank_Gamepad:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
end

function ZO_GuildBank_Gamepad:OnTargetChangedCallback(targetData, oldTargetData)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)

    if oldTargetData and oldTargetData.isTextSearchEntry then
        if self.headerTextFilterEditBox:HasFocus() then
            self.headerTextFilterEditBox:LoseFocus()
        end
        self:UnhighlightSearch()
    end

    if targetData and targetData.isTextSearchEntry then
        self:HighlightSearch()
    end
end

function ZO_GuildBank_Gamepad:OnWithdrawDepositStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:UpdateGuildBankList()
        self.depositList:RefreshList()
    elseif newState == SCENE_SHOWN then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GuildBank_Gamepad:SetWithdrawLoadingControlShown(shouldShowLoading)
    if self.withdrawLoadingControlShown ~= shouldShowLoading then
        self.withdrawLoadingControlShown = shouldShowLoading
        self.withdrawLoadingControl:SetHidden(not shouldShowLoading)
        local shouldShowWithdrawList = not shouldShowLoading
        if not (self:GetListFragment("withdraw"):GetState() == SCENE_FRAGMENT_HIDING and shouldShowWithdrawList) then
            --Because we change the active lists by adding and removing fragments, everytime we change tabs we are in a state where two list fragments are showing at the same. This causes problems
            --when the bank info becomes avaiable as the withdraw fragment is hiding because it will try to activate and adds its list bindings when the deposit list is also active and has added its
            --binds. The best way to fix this is to have these lists be scenes on a sub-scene manager so they don't overlap times when they are active. However, that means significant changes to the
            --parametric list screen. So we handle the problem by not showing the withdraw list if the fragment is hiding. We wait until it is hidden to do that in the fragment's state change callback. 
            self.withdrawList:GetControl():SetHidden(not shouldShowWithdrawList)
        end
    end
end

function ZO_GuildBank_Gamepad:CreateEventTable()
    local function OnCloseGuildBank()
        SCENE_MANAGER:Hide(GAMEPAD_GUILD_BANK_SCENE_NAME)

        self.loadingGuildBank = false
        self:SetWithdrawLoadingControlShown(false)
        self:ClearAllGuildBankItems()
    end

    local function OnGuildBankOpenError()
        if self.loadingGuildBank then
            self.loadingGuildBank = false
            self:SetWithdrawLoadingControlShown(false)
            self:ClearAllGuildBankItems()
        end
    end

    local function OnGuildBankUpdated()
        self:UpdateGuildBankList()
        self:RefreshHeaderData()
    end

    local function OnInventoryUpdated(eventId, bagId, slotIndex, _, itemSoundCategory)
        self:RefreshHeaderData()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
        self:LayoutBankingEntryTooltip(self:GetTargetData())
    end

    local function OnGuildBankSelected()
        self.loadingGuildBank = true
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        self:SetWithdrawLoadingControlShown(true)
        self:ClearAllGuildBankItems()
    end

    local function OnGuildBankDeselected()
        self:ClearAllGuildBankItems()
    end

    local function OnGuildBankReady()
        self.loadingGuildBank = false
        self:SetWithdrawLoadingControlShown(false)
        self.depositList:RefreshList()
        if GAMEPAD_GUILD_BANK_SCENE:IsShowing() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
        end
        OnGuildBankUpdated()
    end

    local function RefreshHeaderData()
        self:RefreshHeaderData()
    end

    local function RefreshLists()
        self.depositList:RefreshList()
        self.withdrawList:RefreshList()
        self:UpdateTextSearchEntry()
    end

    local function AlertAndRefreshHeader(currencyType, currentCurrency, oldCurrency, reason)
        local alertString
        local amount
        local IS_GAMEPAD = true
        local DONT_USE_SHORT_FORMAT = nil

        if reason == CURRENCY_CHANGE_REASON_GUILD_BANK_DEPOSIT then
            amount = oldCurrency - currentCurrency
            alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_DEPOSITED, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, DONT_USE_SHORT_FORMAT, currencyType, IS_GAMEPAD))
        elseif CURRENCY_CHANGE_REASON_GUILD_BANK_WITHDRAWAL then
            amount = currentCurrency - oldCurrency
            alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_WITHDRAWN, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, DONT_USE_SHORT_FORMAT, currencyType, IS_GAMEPAD)) 
        end

        if alertString then
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, alertString)
        end
        RefreshHeaderData()
    end

    local function UpdateMoney(event, currentMoney, oldMoney, reason)
        RefreshLists()
        AlertAndRefreshHeader(CURT_MONEY, currentMoney, oldMoney, reason)
    end

    local function UpdateGuildBankedCurrency()
        RefreshLists()
        RefreshHeaderData()
    end

    local function OnGuildRanksChanged(_, guildId)
        if guildId == GetSelectedGuildBankId() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
            RefreshLists()
        end
    end

    local function OnGuildMemberRankChanged(_, guildId, displayName)
        if guildId == GetSelectedGuildBankId() and displayName == GetDisplayName() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
            RefreshLists()
        end
    end

    local function OnGuildSizeChanged()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
    end

    local function OnGuildLeft(event, guildId, guildName)
        ZO_Dialogs_ReleaseAllDialogsOfName("GUILD_BANK_GAMEPAD_CHANGE_ACTIVE_GUILD")
    end

    self.eventTable =
    {
        [EVENT_CLOSE_GUILD_BANK] = OnCloseGuildBank,
        [EVENT_GUILD_BANK_OPEN_ERROR] = OnGuildBankOpenError,

        [EVENT_GUILD_BANK_SELECTED] = OnGuildBankSelected,
        [EVENT_GUILD_BANK_DESELECTED] = OnGuildBankDeselected,
        [EVENT_GUILD_BANK_ITEMS_READY] = OnGuildBankReady,
        [EVENT_GUILD_BANK_ITEM_ADDED] = OnGuildBankUpdated,
        [EVENT_GUILD_BANK_ITEM_REMOVED] = OnGuildBankUpdated,
        [EVENT_GUILD_BANK_UPDATED_QUANTITY] = OnGuildBankUpdated,

        [EVENT_MONEY_UPDATE] = UpdateMoney,
        [EVENT_GUILD_BANKED_MONEY_UPDATE] = UpdateGuildBankedCurrency,

        [EVENT_GUILD_RANKS_CHANGED] = OnGuildRanksChanged,
        [EVENT_GUILD_RANK_CHANGED] = OnGuildRanksChanged,
        [EVENT_GUILD_MEMBER_RANK_CHANGED] = OnGuildMemberRankChanged,
        [EVENT_GUILD_MEMBER_ADDED] = OnGuildSizeChanged,
        [EVENT_GUILD_MEMBER_REMOVED] = OnGuildSizeChanged,

        [EVENT_GUILD_SELF_LEFT_GUILD] = OnGuildLeft,

        [EVENT_INVENTORY_FULL_UPDATE] = OnInventoryUpdated,
        [EVENT_INVENTORY_SINGLE_SLOT_UPDATE] = OnInventoryUpdated,
    }
end

function ZO_GuildBank_Gamepad:RegisterForEvents()
    ZO_BankingCommon_Gamepad.RegisterForEvents(self)

    self:GetListFragment(self.withdrawList):RegisterCallback("StateChange", self.OnWithdrawDepositStateChanged)
    self:GetListFragment(self.depositList):RegisterCallback("StateChange", self.OnWithdrawDepositStateChanged)
end

function ZO_GuildBank_Gamepad:UnregisterForEvents()
    ZO_BankingCommon_Gamepad.UnregisterForEvents(self)

    self:GetListFragment(self.withdrawList):UnregisterCallback("StateChange", self.OnWithdrawDepositStateChanged)
    self:GetListFragment(self.depositList):UnregisterCallback("StateChange", self.OnWithdrawDepositStateChanged)
end

do
    local ENTRY_ORDER_TEXT_SEARCH = 1
    local ENTRY_ORDER_CURRENCY = 2
    local ENTRY_ORDER_OTHER = 3
    function ZO_GuildBank_Gamepad:OnDeferredInitialization()
        ZO_SharedInventory_SelectAccessibleGuildBank()

        SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function()
            self:RequestApplySearchTextFilterToData()
            self:RefreshGuildBank()
        end)

        self:ResetFilters()

        self.withdrawList.list:SetSortFunction(function(left, right)
            local leftOrder = ENTRY_ORDER_OTHER
            if left.isTextSearchEntry then
                leftOrder = ENTRY_ORDER_TEXT_SEARCH
            elseif left.currencyType then
                leftOrder = ENTRY_ORDER_CURRENCY
            end

            local rightOrder = ENTRY_ORDER_OTHER
            if right.isTextSearchEntry then
                rightOrder = ENTRY_ORDER_TEXT_SEARCH
            elseif right.currencyType then
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

        if self.loadingGuildBank then
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            self:SetWithdrawLoadingControlShown(true)
        end
    end
end

do
    local function DepositItemFilter(itemData)
        return not itemData.stolen and 
               not IsItemBound(itemData.bagId, itemData.slotIndex) and
               not IsItemBoPAndTradeable(itemData.bagId, itemData.slotIndex) and
               not itemData.isPlayerLocked
    end

    function ZO_GuildBank_Gamepad:InitializeLists()
        local function OnTargetDataChangedCallback(...)
            self:OnTargetChanged(...)
        end

        local SETUP_LIST_LOCALLY = true
        local NO_ON_SELECTED_DATA_CHANGED_CALLBACK = nil
        local withdrawList = self:AddList("withdraw", SETUP_LIST_LOCALLY, ZO_GamepadGuildBankInventoryList, BANKING_GAMEPAD_MODE_WITHDRAW, self.bankedBags, SLOT_TYPE_GUILD_BANK_ITEM, NO_ON_SELECTED_DATA_CHANGED_CALLBACK, nil, nil, nil, nil, nil, ZO_SharedGamepadEntry_OnSetup)
        withdrawList:SetOnTargetDataChangedCallback(OnTargetDataChangedCallback)
        self:SetWithdrawList(withdrawList)
        local withdrawListFragment = self:GetListFragment("withdraw")
        withdrawListFragment:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                --The parametric list screen does not call OnTargetChanged when changing the current list which means anything that updates off of the current
                --selection is out of date. So we run OnTargetChanged when a list shows to remedy this.
                self:OnTargetChanged(self:GetCurrentList(), self:GetTargetData())
                self:RequestApplySearchTextFilterToData()
            end
            --See SetWithdrawLoadingControlShown for more info
            if newState ~= SCENE_FRAGMENT_HIDING then
                self.withdrawList:GetControl():SetHidden(self.withdrawLoadingControlShown)
            end
        end)

        withdrawList.HasSelectableHeaderEntry = function()
            return self.headerTextFilterEditBox ~= nil
        end

        withdrawList.AddPlaceholderEntry = function()
            local entryData = ZO_GamepadEntryData:New("")
            entryData.isTextSearchEntry = true

            withdrawList.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end

        local withdrawListControl = withdrawList:GetControl()
        local withdrawContainerControl = withdrawListControl:GetParent()
        self.withdrawLoadingControl = CreateControlFromVirtual("$(parent)Loading", withdrawContainerControl, "ZO_GamepadCenteredLoadingIconAndLabelTemplate")
        self.withdrawLoadingControl:GetNamedChild("ContainerText"):SetText(GetString(SI_INVENTORY_RETRIEVING_ITEMS))

        withdrawList.list:SetOnHitBeginningOfListCallback(function()
            local selectedData = withdrawList:GetTargetData()
            if self:IsInWithdrawMode() and selectedData.currencyType ~= nil then
                self.headerTextFilterEditBox:TakeFocus()
            end
        end)

        local depositList = self:AddList("deposit", SETUP_LIST_LOCALLY, ZO_GamepadGuildBankInventoryList, BANKING_GAMEPAD_MODE_DEPOSIT, self.carriedBag, SLOT_TYPE_ITEM, NO_ON_SELECTED_DATA_CHANGED_CALLBACK, nil, nil, nil, nil, nil, ZO_SharedGamepadEntry_OnSetup)
        depositList:SetOnTargetDataChangedCallback(OnTargetDataChangedCallback)
        depositList:SetItemFilterFunction(DepositItemFilter)
        self:SetDepositList(depositList)
        local depositListFragment = self:GetListFragment("deposit")
        depositListFragment:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                --The parametric list screen does not call OnTargetChanged when changing the current list which means anything that updates off of the current
                --selection is out of date. So we run OnTargetChanged when a list shows to remedy this.
                self:OnTargetChanged(self:GetCurrentList(), self:GetTargetData())
            end
        end)
    end
end

local function CanUseBank(requestPermission)
    local guildId = GetSelectedGuildBankId()
    if guildId then
        return DoesPlayerHaveGuildPermission(guildId, requestPermission)
    else
        return false
    end
end

local function NotEnoughSpace(reason)
    local message = zo_strformat(reason)
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, message)
    PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
end

local function DepositItem(list)
    local targetData = list:GetTargetData()
    if targetData then
        if GetNumBagUsedSlots(BAG_GUILDBANK) < GetBagSize(BAG_GUILDBANK) then
            local soundCategory = GetItemSoundCategory(targetData.itemData.bagId, targetData.itemData.slotIndex)
            PlayItemSound(soundCategory, ITEM_SOUND_ACTION_PICKUP)

            TransferToGuildBank(targetData.itemData.bagId, targetData.itemData.slotIndex)
        else
            NotEnoughSpace(SI_GUILDBANKRESULT5)
        end
    end
end

local function WithdrawItem(list)
    local targetData = list:GetTargetData()
    if targetData then
        if GetNumBagFreeSlots(BAG_BACKPACK) > 0 then
            local soundCategory = GetItemSoundCategory(targetData.itemData.bagId, targetData.itemData.slotIndex)
            PlayItemSound(soundCategory, ITEM_SOUND_ACTION_PICKUP)

            TransferFromGuildBank(targetData.itemData.slotIndex)
        else
            NotEnoughSpace(SI_INVENTORY_ERROR_INVENTORY_FULL)
        end
    end
end

local CURRENT_DATA_TYPE_NONE = 0
local CURRENT_DATA_TYPE_GOLD_SELECTOR = 1
local CURRENT_DATA_TYPE_ITEM_DATA = 2
local function GetCurrentDataType(list)
    local targetData = list:GetTargetData()
    if targetData then
        if targetData.currencyType == CURT_MONEY then
            return CURRENT_DATA_TYPE_GOLD_SELECTOR
        else
            return CURRENT_DATA_TYPE_ITEM_DATA
        end
    end

    return CURRENT_DATA_TYPE_NONE
end

function ZO_GuildBank_Gamepad:InitializeKeybindStripDescriptors()
    local switchActiveGuildKeybind =
    {
        keybind = "UI_SHORTCUT_TERTIARY",
        name = GetString(SI_TRADING_HOUSE_GUILD_LABEL),
        callback = function()
            ZO_Dialogs_ShowGamepadDialog("GUILD_BANK_GAMEPAD_CHANGE_ACTIVE_GUILD")
        end,
        visible = function()
            return GetNumGuilds() > 1
        end,
    }

    self:SetWithdrawKeybindDescriptor(
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                local targetData = self:GetTargetData()
                if targetData and targetData.isTextSearchEntry then
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                else
                    return GetString(SI_BANK_WITHDRAW_BIND)
                end
            end,
            enabled = function()
                local targetData = self:GetTargetData()
                return self:CanWithdraw() or (targetData and targetData.isTextSearchEntry)
            end,
            visible = function()
                local currentDataType = GetCurrentDataType(self.withdrawList)
                if currentDataType == CURRENT_DATA_TYPE_GOLD_SELECTOR then
                    return CanUseBank(GUILD_PERMISSION_BANK_WITHDRAW_GOLD)
                elseif currentDataType == CURRENT_DATA_TYPE_ITEM_DATA then
                    return CanUseBank(GUILD_PERMISSION_BANK_WITHDRAW) and GetNumBagUsedSlots(BAG_GUILDBANK) > 0
                end

                local targetData = self:GetTargetData()
                return targetData and targetData.isTextSearchEntry
            end,
            callback = function()
                local targetData = self:GetTargetData()
                if targetData.isTextSearchEntry then
                    self.headerTextFilterEditBox:TakeFocus()
                else
                    self:ConfirmWithdrawal()
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_LEFT_STICK",
            name = function()
                local sortIconPath = self.withdrawList.currentSortOrder == ZO_SORT_ORDER_UP and SORT_ARROW_UP or SORT_ARROW_DOWN
                local sortIconText = zo_iconFormat(sortIconPath, 16, 16)
                if ZO_IsTableEmpty(self.withdrawList.filterCategories) then
                    return zo_strformat(GetString(SI_GAMEPAD_BANK_FILTER_KEYBIND), GetString("SI_ITEMLISTSORTTYPE", self.withdrawList.currentSortType), sortIconText)
                else
                    return zo_strformat(GetString(SI_GAMEPAD_BANK_FILTER_SORT_DROPDOWN_TEXT), NonContiguousCount(self.withdrawList.filterCategories), GetString("SI_ITEMLISTSORTTYPE", self.withdrawList.currentSortType), sortIconText)
                end
            end,
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_GUILD_BANK_SEARCH_FILTERS")
            end
        },
        switchActiveGuildKeybind,
    })

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.withdrawKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        local targetData = self:GetTargetData()
        if targetData.isTextSearchEntry then
            self:UnhighlightSearch()
            self.withdrawList:MoveNext()
        end
        SCENE_MANAGER:HideCurrentScene()
    end)

    self:SetDepositKeybindDescriptor(
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name =  GetString(SI_BANK_DEPOSIT_BIND),
            enabled = function()
                return self:CanDeposit()
            end,
            visible = function()
                local currentDataType = GetCurrentDataType(self.depositList)
                if currentDataType == CURRENT_DATA_TYPE_GOLD_SELECTOR then
                    return DoesGuildHavePrivilege(GetSelectedGuildBankId(), GUILD_PRIVILEGE_BANK_DEPOSIT)
                elseif currentDataType == CURRENT_DATA_TYPE_ITEM_DATA then
                    return not self.loadingGuildBank and CanUseBank(GUILD_PERMISSION_BANK_DEPOSIT) and GetNumBagUsedSlots(BAG_BACKPACK) > 0 and DoesGuildHavePrivilege(GetSelectedGuildBankId(), GUILD_PRIVILEGE_BANK_DEPOSIT)
                end
                return false
            end,
            callback =  function() self:ConfirmDeposit() end
        },
        switchActiveGuildKeybind,
    })

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.depositKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GuildBank_Gamepad:CanDeposit()
    local inventoryData = self:GetTargetData()
    if not inventoryData then
        return false
    end

    local currencyType = inventoryData.currencyType
    if currencyType then
        if self:GetMaxBankedFunds(currencyType) ~= GetCurrencyAmount(currencyType, CURRENCY_LOCATION_GUILD_BANK) and GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= 0 then
            return true
        else
            if self:GetMaxBankedFunds(currencyType) == GetCurrencyAmount(currencyType, CURRENCY_LOCATION_GUILD_BANK) then
                return false, GetString("SI_GUILDBANKRESULT", GUILD_BANK_NO_SPACE_LEFT) -- "Your guild bank is full"
            elseif GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) == 0 then
                return false, GetString(SI_GAMEPAD_INVENTORY_ERROR_NO_PLAYER_FUNDS) -- "No player funds"
            end
        end
    elseif GetNumBagFreeSlots(BAG_GUILDBANK) > 0 then
        return true
    else
        return false, GetString(SI_INVENTORY_ERROR_BANK_FULL) -- "Your guild bank is full"
    end
end

function ZO_GuildBank_Gamepad:CanWithdraw()
    local inventoryData = self:GetTargetData()
    if not inventoryData then
        return false
    end

    local currencyType = inventoryData.currencyType
    if currencyType then
        if not DoesPlayerHaveGuildPermission(GetSelectedGuildBankId(), GUILD_PERMISSION_BANK_VIEW_GOLD) then
            return false
        elseif GetCurrencyAmount(currencyType, CURRENCY_LOCATION_GUILD_BANK) ~= 0 and GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER) then
            return true
        else
            if GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) == GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER) then
                return false, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL) -- "Your inventory is full"
            elseif GetCurrencyAmount(currencyType, CURRENCY_LOCATION_GUILD_BANK) == 0 then
                return false, GetString(SI_GAMEPAD_INVENTORY_ERROR_NO_BANK_FUNDS) -- "No bank funds"
            end
        end
    elseif GetNumBagFreeSlots(BAG_BACKPACK) > 0 then
        return true
    else
        return false, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL) -- "Your inventory is full"
    end
end

function ZO_GuildBank_Gamepad:ConfirmDeposit()
    local inventoryData = self:GetTargetData()
    if inventoryData.currencyType then
        self:SetMaxAndShowSelector(function(currencyType) return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_GUILD_BANK) end)
    else
        DepositItem(self.depositList)
    end
end

function ZO_GuildBank_Gamepad:ConfirmWithdrawal()
    local inventoryData = self:GetTargetData()
    if inventoryData.currencyType then
        self:SetMaxAndShowSelector(function(currencyType) return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_GUILD_BANK, CURRENCY_LOCATION_CHARACTER) end)
    else
        WithdrawItem(self.withdrawList)
    end
end

function ZO_GuildBank_Gamepad:SetMaxAndShowSelector(maxInputFunction)
    self:SetMaxInputFunction(maxInputFunction)
    self:ShowSelector()
end

function ZO_GuildBank_Gamepad:GetWithdrawMoneyAmount()
    return GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_GUILD_BANK)
end

function ZO_GuildBank_Gamepad:GetWithdrawMoneyOptions()
    return ZO_BANKING_CURRENCY_LABEL_OPTIONS
end

function ZO_GuildBank_Gamepad:DoesObfuscateWithdrawAmount()
    return not DoesPlayerHaveGuildPermission(GetSelectedGuildBankId(), GUILD_PERMISSION_BANK_VIEW_GOLD)
end

function ZO_GuildBank_Gamepad:GetMaxBankedFunds(currencyType)
    return GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_GUILD_BANK)
end

function ZO_GuildBank_Gamepad:GetDepositMoneyAmount()
    return GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
end

function ZO_GuildBank_Gamepad:DepositFunds(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_GUILD_BANK)
end

function ZO_GuildBank_Gamepad:WithdrawFunds(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_GUILD_BANK, CURRENCY_LOCATION_CHARACTER)
end

function ZO_GuildBank_Gamepad:OnCategoryChangedCallback(selectedData)
    if self.loadingGuildBank and selectedData.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
        self:SetSelectedInventoryData(nil)
    end

    self:UpdateTextSearchEntry()
end

function ZO_GuildBank_Gamepad:InitializeHeader()
    ZO_BankingCommon_Gamepad.InitializeHeader(self)

    local headerContainer = self:GetHeaderContainer()
    self.headerTextFilterControl = headerContainer:GetNamedChild("Filter")
    self.headerTextFilterEditBox = self.headerTextFilterControl:GetNamedChild("SearchEdit")
    self.headerTextFilterHighlight = self.headerTextFilterControl:GetNamedChild("Highlight")
    self.headerTextFilterIcon = self.headerTextFilterControl:GetNamedChild("Icon")
    self.headerBGTexture = self.headerTextFilterControl:GetNamedChild("BG")

    self.headerTextFilterEditBox:SetHandler("OnTextChanged", function(editBox)
        ZO_EditDefaultText_OnTextChanged(editBox)
        local text = editBox:GetText()
        if text ~= self.searchTextFilter then
            self.searchTextFilter = text
            self:RequestApplySearchTextFilterToData()
        end
    end)

    ZO_GUILD_NAME_FOOTER_FRAGMENT:SetGuildName(GetGuildName(GetSelectedGuildBankId()))
end

function ZO_GuildBank_Gamepad:HighlightSearch()
    self.headerTextFilterHighlight:SetHidden(false)
    self.headerTextFilterIcon:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    self.headerBGTexture:SetHidden(false)
end

function ZO_GuildBank_Gamepad:UnhighlightSearch()
    self.headerTextFilterHighlight:SetHidden(true)
    self.headerTextFilterIcon:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
    self.headerBGTexture:SetHidden(true)
end

function ZO_GuildBank_Gamepad:CanFilterByText(text)
    -- Very broad searches have bad performance implications: The search itself is asynchronous (and snappy), but updating UI to reflect the search is not
    return ZoUTF8StringLength(text) >= 2
end

function ZO_GuildBank_Gamepad:RequestApplySearchTextFilterToData()
    --Cancel any in progress filtering so we can do a new one
    if self.inProgressSearchTextFilterTaskId then
        DestroyBackgroundListFilter(self.inProgressSearchTextFilterTaskId)
    end

    --If we have filter text than create the tasks
    if self:CanFilterByText(self.searchTextFilter) then
        self.isSearchFiltered = true

        --Inventory Items
        local itemTaskId = CreateBackgroundListFilter(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, self.searchTextFilter)
        self.inProgressSearchTextFilterTaskId = itemTaskId
        AddBackgroundListFilterType(itemTaskId, BACKGROUND_LIST_FILTER_TYPE_NAME)
        local slots = self.withdrawList:GenerateSlotTable()
        for i, itemData in ipairs(slots) do
            itemData.passesTextFilter = false
            AddBackgroundListFilterEntry(itemTaskId, itemData.bagId, itemData.slotIndex)
        end

        StartBackgroundListFilter(itemTaskId)
    else
        self.isSearchFiltered = false

        local slots = self.withdrawList:GenerateSlotTable()
        for i, itemData in ipairs(slots) do
            itemData.passesTextFilter = true
        end

        self.withdrawList:RefreshList()
        self:UpdateTextSearchEntry()
    end
end

function ZO_GuildBank_Gamepad:UpdateTextSearchEntry()
    if self.headerTextFilterControl then
        if self:IsInWithdrawMode() then
            -- Don't show search if there is not search placeholder entry
            local showSearch = false
            for index = 1, self.withdrawList.list:GetNumEntries() do
                local data = self.withdrawList.list:GetEntryData(index)
                if data.isTextSearchEntry then
                    showSearch = true
                    break
                end
            end

            self.headerTextFilterControl:SetHidden(not showSearch)
        else
            self.headerTextFilterControl:SetHidden(true)
        end
    end
end

function ZO_GuildBank_Gamepad:TryMarkSearchBackgroundListFilterComplete(taskId)
    if self.inProgressSearchTextFilterTaskId == taskId then
        self.inProgressSearchTextFilterTaskId = nil
        self.completeSearchTextFilterTaskId = taskId
        return true
    end
    return false
end

function ZO_GuildBank_Gamepad:OnBackgroundListFilterComplete(taskId)
    if self.inProgressSearchTextFilterTaskId == taskId then
        --Mark that it was completed.
        self:TryMarkSearchBackgroundListFilterComplete(taskId)

        local itemTaskId = self.completeSearchTextFilterTaskId
        local slots = self.withdrawList:GenerateSlotTable()
        for i, itemData in ipairs(slots) do
            for i = 1, GetNumBackgroundListFilterResults(itemTaskId) do
                local bagId, slotIndex = GetBackgroundListFilterResult(itemTaskId, i)
                if itemData.bagId == bagId and itemData.slotIndex == slotIndex then
                    itemData.passesTextFilter = true
                end
            end
        end

        DestroyBackgroundListFilter(itemTaskId)

        self.withdrawList:RefreshList()
        self:UpdateTextSearchEntry()
    end
end

function ZO_GuildBank_Gamepad:RefreshGuildBank()
    self.depositList:RefreshList()
    self:UpdateGuildBankList()
    self:RefreshHeaderData()
end

function ZO_GuildBank_Gamepad:ChangeGuildBank(guildBankId)
    if guildBankId ~= GetSelectedGuildBankId() then
        self.loadingGuildBank = true
        SelectGuildBank(guildBankId)
        self.lastSelectedGuildBankId = guildBankId
    end
end

function ZO_GuildBank_Gamepad:IsLoadingGuildBank()
    return self.loadingGuildBank
end

function ZO_GuildBank_Gamepad:OnRefreshHeaderData()
    ZO_GUILD_NAME_FOOTER_FRAGMENT:SetGuildName(GetGuildName(GetSelectedGuildBankId()))
end

function ZO_GuildBank_Gamepad:UpdateGuildBankList()
    self.withdrawList:RefreshList()
    self:UpdateTextSearchEntry()
end

function ZO_GuildBank_Gamepad:SetSelectedInventoryData(_, inventoryData)
    self:LayoutBankingEntryTooltip(inventoryData)
end

function ZO_GuildBank_Gamepad:ClearAllGuildBankItems()
    self.withdrawList:ClearList()
end

function ZO_GuildBank_Gamepad_Initialize(control)
    GAMEPAD_GUILD_BANK = ZO_GuildBank_Gamepad:New(control)
end