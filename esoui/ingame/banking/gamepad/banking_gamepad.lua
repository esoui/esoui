-------------------------------------
-- Gamepad Bank Inventory List
-------------------------------------
ZO_GamepadBankInventoryList = ZO_GamepadBankCommonInventoryList:Subclass()

function ZO_GamepadBankInventoryList:New(...)
    return ZO_GamepadBankCommonInventoryList.New(self, ...)
end

function ZO_GamepadBankInventoryList:Initialize(...)
    ZO_GamepadBankCommonInventoryList.Initialize(self, ...)

    self.list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local currenciesTransferEntryName = self:IsInWithdrawMode() and GetString(SI_BANK_WITHDRAW_CURRENCY) or GetString(SI_BANK_DEPOSIT_CURRENCY)
    local currenciesTransferEntryIcon = self:IsInWithdrawMode() and "EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_currency_withdraw.dds" or "EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_currency_deposit.dds"
    local entryData = ZO_GamepadEntryData:New(currenciesTransferEntryName, currenciesTransferEntryIcon)
    entryData:SetIconTintOnSelection(true)
    entryData.isCurrenciesMenuEntry = true
    self.currenciesTransferEntry = entryData
end

function ZO_GamepadBankInventoryList:RefreshCurrencyTransferEntryInList()
    if self.isDirty then
        --it will be handled when the full list is rebuilt on show
        return
    end

    local currencyEntryIndex = self.list:GetIndexForData("ZO_GamepadMenuEntryTemplate", self.currenciesTransferEntry)
    local hasCurrencyEntry = currencyEntryIndex ~= nil
    local shouldHaveCurrencyEntry = DoesBankHoldCurrency(GetBankingBag())
    if hasCurrencyEntry ~= shouldHaveCurrencyEntry then
        if shouldHaveCurrencyEntry then
            self.list:AddEntryAtIndex(1, "ZO_GamepadMenuEntryTemplate", self.currenciesTransferEntry)
        else
            self.list:RemoveEntry("ZO_GamepadMenuEntryTemplate", self.currenciesTransferEntry)
        end
        self.list:Commit()
    end
end

function ZO_GamepadBankInventoryList:RefreshList()
    --Getting the slot data can trigger a full inventory update callback which will try to refresh the list in the middle of refreshing the list which duplicates the entries. isRebuildingList protects against this.
    if not self.isRebuildingList then
        if self.control:IsHidden() then
            self.isDirty = true
            return
        end
        self.isDirty = false
        self.isRebuildingList = true

        self.list:Clear()

        if DoesBankHoldCurrency(GetBankingBag()) then
            self.list:AddEntry("ZO_GamepadMenuEntryTemplate", self.currenciesTransferEntry)
        end

        for i, bagId in ipairs(self.inventoryTypes) do
            self.dataByBagAndSlotIndex[bagId] = {}
        end

        local slots = self:GenerateSlotTable()
        local currentBestCategoryName = nil
        for i, itemData in ipairs(slots) do
            local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
            self:SetupItemEntry(entry, itemData)

            if itemData.bestGamepadItemCategoryName ~= currentBestCategoryName then
                currentBestCategoryName = itemData.bestGamepadItemCategoryName
                entry:SetHeader(currentBestCategoryName)
                self.list:AddEntryWithHeader(self.template, entry)
            else
                self.list:AddEntry(self.template, entry)
            end

            self.dataByBagAndSlotIndex[itemData.bagId][itemData.slotIndex] = entry
        end

        self.list:Commit()
        GAMEPAD_BANKING:UpdateKeybinds()
        self.isRebuildingList = false
    end
end

-----------------------
-- Gamepad Banking
-----------------------

local GAMEPAD_BANKING_SCENE_NAME = "gamepad_banking"

ZO_GamepadBanking = ZO_BankingCommon_Gamepad:Subclass()

function ZO_GamepadBanking:New(...)
    return ZO_BankingCommon_Gamepad.New(self, ...)
end

function ZO_GamepadBanking:Initialize(control)
    GAMEPAD_BANKING_SCENE = ZO_InteractScene:New(GAMEPAD_BANKING_SCENE_NAME, SCENE_MANAGER, BANKING_INTERACTION)
    ZO_BankingCommon_Gamepad.Initialize(self, control, GAMEPAD_BANKING_SCENE)
    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT)

    self:SetCarriedBag(BAG_BACKPACK)

    self.control:RegisterForEvent(EVENT_OPEN_BANK, function(_, ...) self:OnOpenBank(...) end)
    self.control:RegisterForEvent(EVENT_CLOSE_BANK, function() self:OnCloseBank() end)
end

function ZO_GamepadBanking:OnOpenBank(bankBag)
    if IsInGamepadPreferredMode() then
        self:ClearBankedBags()
        if bankBag == BAG_BANK then
            self:AddBankedBag(BAG_BANK)
            self:AddBankedBag(BAG_SUBSCRIBER_BANK)
        else
            self:AddBankedBag(bankBag)
        end

        --If we have already initialized then we've built the withdraw list already and need to update its backing bags.
        --If we haven't initialized we will build the withdraw list after this and it will pickup the new banked bags.
        if self.initialized then
            local refreshedListAsAResultOfBankedBagsChanging = self.withdrawList:SetInventoryTypes(self.bankedBags)
            --We also need to update both of the lists because they include the deposit/withdraw entries which only appear on banks and not home storage
            if not refreshedListAsAResultOfBankedBagsChanging then
                self.withdrawList:RefreshCurrencyTransferEntryInList()
            end
            self.depositList:RefreshCurrencyTransferEntryInList()
        end

        SCENE_MANAGER:Show(GAMEPAD_BANKING_SCENE_NAME)
    end
end

function ZO_GamepadBanking:OnCloseBank()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Hide(GAMEPAD_BANKING_SCENE_NAME)
    end
end

function ZO_GamepadBanking:OnCollectibleUpdated(collectibleId)
    if IsBankOpen() and IsHouseBankBag(GetBankingBag()) then
        if GetCollectibleCategoryType(collectibleId) == COLLECTIBLE_CATEGORY_TYPE_HOUSE_BANK then
            self:RefreshWithdrawNoItemText()
        end
    end
end

function ZO_GamepadBanking:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)
    self:UpdateKeybinds()
end

function ZO_GamepadBanking:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
    KEYBIND_STRIP:RemoveKeybindButton(self.withdrawDepositFundsKeybind)
end

function ZO_GamepadBanking:OnDeferredInitialization()
    self.spinner = self.control:GetNamedChild("SpinnerContainer")
    self.spinner:InitializeSpinner()
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
end

function ZO_GamepadBanking:OnSceneShowing()
    local bankingBag = GetBankingBag()
    if bankingBag == BAG_BANK then
        TriggerTutorial(TUTORIAL_TRIGGER_ACCOUNT_BANK_OPENED)
        if IsESOPlusSubscriber() then
            TriggerTutorial(TUTORIAL_TRIGGER_BANK_OPENED_AS_SUBSCRIBER)
        end
    else
        TriggerTutorial(TUTORIAL_TRIGGER_HOME_STORAGE_OPENED)
    end
    self:RefreshWithdrawNoItemText()
end

function ZO_GamepadBanking:RefreshWithdrawNoItemText()
    local bankingBag = GetBankingBag()
    if bankingBag == BAG_BANK then
        if IsESOPlusSubscriber() then
            TriggerTutorial(TUTORIAL_TRIGGER_BANK_OPENED_AS_SUBSCRIBER)
        end
        self.withdrawList:SetNoItemText(GetString(SI_BANK_EMPTY))
    else
        local interactName = GetUnitName("interact")
        local collectibleId = GetCollectibleForHouseBankBag(bankingBag)
        local nickname
        if collectibleId ~= 0 then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            if collectibleData then
                nickname = collectibleData:GetNickname()
            end
        end

        if nickname and nickname ~= "" then
            self.withdrawList:SetNoItemText(zo_strformat(SI_BANK_HOME_STORAGE_EMPTY_WITH_NICKNAME, interactName, nickname))
        else
            self.withdrawList:SetNoItemText(zo_strformat(SI_BANK_HOME_STORAGE_EMPTY, interactName))
        end
    end
end

function ZO_GamepadBanking:InitializeLists()
    local function OnWithdrawEntryDataCreatedCallback(data)
        ZO_Inventory_BindSlot(data, SLOT_TYPE_BANK_ITEM, data.itemData.slotIndex, data.itemData.bagId)
    end

    local function OnDepositEntryDataCreatedCallback(data)
        ZO_Inventory_BindSlot(data, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM, data.itemData.slotIndex, data.itemData.bagId)
    end

    local function ItemSetupTemplate(...)
        self:SetupItem(...)
    end

    local SETUP_LIST_LOCALLY = true
    local NO_ON_SELECTED_DATA_CHANGED_CALLBACK = nil
    local withdrawList = self:AddList("withdraw", SETUP_LIST_LOCALLY, ZO_GamepadBankInventoryList, BANKING_GAMEPAD_MODE_WITHDRAW, self.bankedBags, SLOT_TYPE_BANK_ITEM, NO_ON_SELECTED_DATA_CHANGED_CALLBACK, OnWithdrawEntryDataCreatedCallback, nil, nil, nil, nil, ItemSetupTemplate)

    self:SetWithdrawList(withdrawList)
    local withdrawListFragment = self:GetListFragment("withdraw")
    withdrawListFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            --The parametric list screen does not call OnTargetChanged when changing the current list which means anything that updates off of the current
            --selection is out of date. So we run OnTargetChanged when a list shows to remedy this.
            self:OnTargetChanged(self:GetCurrentList(), self:GetTargetData())
        end
    end)

    local depositList = self:AddList("deposit", SETUP_LIST_LOCALLY, ZO_GamepadBankInventoryList, BANKING_GAMEPAD_MODE_DEPOSIT, self.carriedBag, SLOT_TYPE_ITEM, NO_ON_SELECTED_DATA_CHANGED_CALLBACK, OnDepositEntryDataCreatedCallback, nil, nil, nil, nil, ItemSetupTemplate)
    depositList:SetNoItemText(GetString(SI_GAMEPAD_INVENTORY_EMPTY))
    depositList:SetItemFilterFunction(function(slot) return not slot.stolen end)
    self:SetDepositList(depositList)
    local depositListFragment = self:GetListFragment("deposit")
    depositListFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            --The parametric list screen does not call OnTargetChanged when changing the current list which means anything that updates off of the current
            --selection is out of date. So we run OnTargetChanged when a list shows to remedy this.
            self:OnTargetChanged(self:GetCurrentList(), self:GetTargetData())
        end
    end)

    local function SetupCurrenciesList(list)
        list:AddDataTemplate("ZO_GamepadBankCurrencySelectorTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end

    self.currenciesList = self:AddList("currencies", SetupCurrenciesList)
    local currenciesFragment = self:GetListFragment("currencies")
    currenciesFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            --The parametric list screen does not call OnTargetChanged when changing the current list which means anything that updates off of the current
            --selection is out of date. So we run OnTargetChanged when a list shows to remedy this.
            self:OnTargetChanged(self:GetCurrentList(), self:GetTargetData())
            self:RefreshCurrenciesList()
        end
    end)

    for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
        if CanCurrencyBeStoredInLocation(currencyType, CURRENCY_LOCATION_BANK) then
            local IS_PLURAL = false
            local IS_UPPER = false
            local entryData = ZO_GamepadEntryData:New(GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER), ZO_Currency_GetGamepadCurrencyIcon(currencyType))
            entryData:SetIconTintOnSelection(true)
            entryData:SetIconDisabledTintOnSelection(true)
            entryData.currencyType = currencyType
            self.currenciesList:AddEntry("ZO_GamepadBankCurrencySelectorTemplate", entryData)
        end
    end

    local DEFAULT_RESELECT = nil
    local BLOCK_SELECTION_CHANGED_CALLBACK = true
    self.currenciesList:Commit(DEFAULT_RESELECT, BLOCK_SELECTION_CHANGED_CALLBACK)
end

function ZO_GamepadBanking:RefreshCurrenciesList()
    local list = self.currenciesList
    if self:IsCurrentList(list) then
        for i = 1, list:GetNumEntries() do
            local entryData = list:GetEntryData(i)
            local currencyType = entryData.currencyType
            local enabled = false

            if self:IsInWithdrawMode() then
                enabled = GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER) and GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK) ~= 0
            elseif self:IsInDepositMode() then
                enabled = GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK) ~= GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_BANK) and GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= 0
            end

            entryData:SetEnabled(enabled)
        end
        list:RefreshVisible()
    end
end

function ZO_GamepadBanking:SetupItem(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    if selected then
        local currentList = self:GetCurrentList()
        if currentList and control == currentList.list:GetTargetControl() then
            control:SetHidden(self.confirmationMode)
        end
    end
end

function ZO_GamepadBanking.IsEntryDataCurrencyRelated(entryData)
    return entryData and (entryData.isCurrenciesMenuEntry or entryData.currencyType)
end

function ZO_GamepadBanking:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)

    local targetData = self:GetTargetData()
    -- since SetInventorySlot also adds/removes keybinds, the order which we call these 2 functions is important
    -- based on whether we are looking at an item or a faux-item
    if ZO_GamepadBanking.IsEntryDataCurrencyRelated(targetData) then
        self.itemActions:SetInventorySlot(nil)
        if KEYBIND_STRIP:HasKeybindButton(self.withdrawDepositFundsKeybind) then
            KEYBIND_STRIP:UpdateKeybindButton(self.withdrawDepositFundsKeybind)
        else
            KEYBIND_STRIP:AddKeybindButton(self.withdrawDepositFundsKeybind)
        end
    else
        KEYBIND_STRIP:RemoveKeybindButton(self.withdrawDepositFundsKeybind)
        self.itemActions:SetInventorySlot(targetData)
    end
end

function ZO_GamepadBanking:LayoutBankingEntryTooltip(inventoryData)
    ZO_BankingCommon_Gamepad.LayoutBankingEntryTooltip(self, inventoryData)
    if self:IsCurrentList("withdraw") or self:IsCurrentList("deposit") then
        if inventoryData and inventoryData.isCurrenciesMenuEntry then
            GAMEPAD_TOOLTIPS:LayoutBankCurrencies(GAMEPAD_LEFT_TOOLTIP)
        end
    end
end

function ZO_GamepadBanking:OnTargetChangedCallback()
    self:UpdateKeybinds()
end

function ZO_GamepadBanking:ClearSelectedData()
    self.itemActions:SetInventorySlot(nil)
end

function ZO_GamepadBanking:InitializeKeybindStripDescriptors()
    self.withdrawDepositFundsKeybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_PRIMARY",
        name = function()
            local targetData = self:GetTargetData()
            if targetData.isCurrenciesMenuEntry then
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            else
                return self:IsInWithdrawMode() and GetString(SI_BANK_WITHDRAW_BIND) or GetString(SI_BANK_DEPOSIT_BIND)
            end
        end,
        enabled = function()
            local targetData = self:GetTargetData()
            if targetData then
                return targetData.isCurrenciesMenuEntry or self:CanTransferSelectedFunds()
            end
            return false
        end,
        visible = function()
            return self:GetTargetData() ~= nil
        end,
        callback = function()
            local targetData = self:GetTargetData()
            if targetData.isCurrenciesMenuEntry then
                self:SetCurrentList(self.currenciesList)
            else
                self:PerformWithdrawDepositFunds()
            end
        end
    }

    self.mainKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = function()
                local cost = GetNextBankUpgradePrice()
                if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= cost then
                    return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_Currency_FormatGamepad(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_AMOUNT_ICON))
                end
                return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_Currency_FormatGamepad(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON))
            end,
            visible = function()
                return IsBankUpgradeAvailable() and GetBankingBag() == BAG_BANK
            end,
            enabled = function()
                return GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= GetNextBankUpgradePrice()
            end,
            callback = function()
                if GetNextBankUpgradePrice() > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) then
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_BUY_BANK_SPACE_CANNOT_AFFORD))
                else
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
                    DisplayBankUpgrade()
                end
            end
        },
        {
            name = GetString(SI_COLLECTIBLE_ACTION_RENAME),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                return IsHouseBankBag(GetBankingBag())
            end,
            callback = function()
                local collectibleId = GetCollectibleForHouseBankBag(GetBankingBag())
                if collectibleId ~= 0 then
                    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                    if collectibleData then
                        local nickname = collectibleData:GetNickname()
                        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = collectibleId, name = nickname })
                    end
                end
            end
        },
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                local data = self:GetTargetData()
                return data and not ZO_GamepadBanking.IsEntryDataCurrencyRelated(data)
            end,

            callback = function()
                self:ShowActions()
            end,
        },
        {
            keybind = "UI_SHORTCUT_LEFT_STICK",
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            visible = function()
                return self:IsInDepositMode()
            end,
            callback = function()
                StackBag(BAG_BACKPACK)
            end
        },
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                if self:IsCurrentList(self.currenciesList) then
                    self:SetCurrentList(self:GetMainListForMode())
                else
                    SCENE_MANAGER:HideCurrentScene()
                end
            end,
        },
    }

    self:SetDepositKeybindDescriptor(self.mainKeybindStripDescriptor)
    self:SetWithdrawKeybindDescriptor(self.mainKeybindStripDescriptor)
end

function ZO_GamepadBanking:OnCategoryChangedCallback(selectedData)
    self:UpdateKeybinds()
end

function ZO_GamepadBanking:GetWithdrawMoneyAmount()
    if self:GetCurrencyType() then  --returns nil if on an item
        return GetCurrencyAmount(self:GetCurrencyType(), CURRENCY_LOCATION_BANK)
    end
end

function ZO_GamepadBanking:GetWithdrawMoneyOptions()
    return ZO_BANKING_CURRENCY_LABEL_OPTIONS
end

function ZO_GamepadBanking:DoesObfuscateWithdrawAmount()
    return false
end

function ZO_GamepadBanking:GetMaxBankedFunds(currencyType)
    return GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_BANK)
end

function ZO_GamepadBanking:GetDepositMoneyAmount()
    if self:GetCurrencyType() then  
        return GetCurrencyAmount(self:GetCurrencyType(), CURRENCY_LOCATION_CHARACTER)
    end
end

function ZO_GamepadBanking:DepositFunds(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_BANK)
end

function ZO_GamepadBanking:WithdrawFunds(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_BANK, CURRENCY_LOCATION_CHARACTER)
end

function ZO_GamepadBanking:CreateEventTable()

    local function RefreshHeaderData()
        self:RefreshHeaderData()
    end

    local function RefreshLists()
        self:ClearSelectedData()
        self.depositList:RefreshList()
        self.withdrawList:RefreshList()
        self:RefreshCurrenciesList()
        self:UpdateKeybinds()
    end

    local function AlertAndRefreshHeader(currencyType, currentCurrency, oldCurrency, reason)
        local alertString
        local amount
        local IS_GAMEPAD = true
        local DONT_USE_SHORT_FORMAT = false

        if reason == CURRENCY_CHANGE_REASON_BANK_DEPOSIT then
            amount = oldCurrency - currentCurrency
            alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_DEPOSITED, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, DONT_USE_SHORT_FORMAT, currencyType, IS_GAMEPAD))
        elseif reason == CURRENCY_CHANGE_REASON_BANK_WITHDRAWAL then
            amount = currentCurrency - oldCurrency
            alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_WITHDRAWN, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, DONT_USE_SHORT_FORMAT, currencyType, IS_GAMEPAD)) 
        end
       
        if alertString then
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, alertString)
        end
        RefreshHeaderData()
    end

    local function UpdateCarriedCurrency(event, currencyType, currentAmount, oldAmount, reason)
        RefreshLists()
        AlertAndRefreshHeader(currencyType, currentAmount, oldAmount, reason)
    end

    local function UpdateBankedCurrency()
        RefreshLists()
        RefreshHeaderData()
    end

    local function OnInventoryUpdate()
        self:RefreshHeaderData()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
        self:LayoutBankingEntryTooltip(self:GetTargetData())
    end
    
    self.eventTable =
    {
        [EVENT_CARRIED_CURRENCY_UPDATE] = UpdateCarriedCurrency,
        [EVENT_BANKED_CURRENCY_UPDATE] = UpdateBankedCurrency,

        [EVENT_INVENTORY_FULL_UPDATE] = OnInventoryUpdate,
        [EVENT_INVENTORY_SINGLE_SLOT_UPDATE] = OnInventoryUpdate,
    }
end

function ZO_GamepadBanking:CanTransferSelectedFunds()
    local inventoryData = self:GetTargetData()
    if inventoryData then
        local currencyType = inventoryData.currencyType
        if currencyType then
            if self:IsInWithdrawMode() then
                if GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK) ~= 0 and GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER) then
                     return true
                else
                    if GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) == GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER) then
                        return false, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL) -- "Your inventory is full"
                    elseif GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK) == 0 then
                        return false, GetString(SI_GAMEPAD_INVENTORY_ERROR_NO_BANK_FUNDS) -- "No bank funds"
                    end
                end
            elseif self:IsInDepositMode() then
                if GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK) ~= GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_BANK) and GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) ~= 0 then
                    return true
                else
                    if GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK) == GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_BANK) then
                        return false, GetString(SI_INVENTORY_ERROR_BANK_FULL) -- "Your bank is full"
                    elseif GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER) == 0 then
                        return false, GetString(SI_GAMEPAD_INVENTORY_ERROR_NO_PLAYER_FUNDS) -- "No player funds"
                    end
                end
            end
        end
    end
    return false
end

function ZO_GamepadBanking:PerformWithdrawDepositFunds()
    local inventoryData = self:GetTargetData()
    if inventoryData.currencyType then
        if self:IsInWithdrawMode() then
            self:SetMaxInputFunction(function(currencyType) return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_BANK, CURRENCY_LOCATION_CHARACTER) end)
        elseif self:IsInDepositMode() then
            self:SetMaxInputFunction(function(currencyType) return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_BANK) end) 
        end
        self:ShowSelector()
    end
end

function ZO_GamepadBanking:ShowActions()
    local dialogData = 
    {
        targetData = self:GetTargetData(),
        itemActions = self.itemActions,
        -- make sure to update the item actions after we close the dialog
        -- since the underlying data may have changed (lock state for instance)
        finishedCallback = function() self.itemActions:RebuildActions() end
    }

    ZO_Dialogs_ShowPlatformDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG, dialogData)
end

function ZO_GamepadBanking:OnSceneHidden()
    self:ClearSelectedData()
end

-- XML Handlers

function ZO_Banking_Gamepad_Initialize(control)
    GAMEPAD_BANKING = ZO_GamepadBanking:New(control)
end

-----------------------
-- Buy Bank Space
-----------------------

GAMEPAD_BUY_BANK_SPACE_SCENE_NAME = "gamepad_buy_bank_space"

ZO_BuyBankSpace_Gamepad = ZO_Object:Subclass()

function ZO_BuyBankSpace_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_BuyBankSpace_Gamepad:Initialize(control)

    ZO_Dialogs_RegisterCustomDialog("BUY_BANK_SPACE_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_PROMPT_TITLE_BUY_BANK_SPACE,
        },
        mainText =
        {
            text = zo_strformat(SI_BUY_BANK_SPACE, NUM_BANK_SLOTS_PER_UPGRADE),
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_DECLINE,
                callback = function() self:Hide() end
            },
            {
                keybind = "DIALOG_PRIMARY",
                text = function()
                    local costString = ZO_CurrencyControl_FormatCurrency(self.cost)
                    return zo_strformat(SI_GAMEPAD_BANK_UPGRADE_ACCEPT, costString, ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY))
                end,
                callback =  function(dialog)
                    BuyBankSpace()
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GAMEPAD_BANK_UPGRADED_ALERT))
                    self:Hide()
                end,
            }
        }
    })

    GAMEPAD_BUY_BANK_SPACE_SCENE = ZO_InteractScene:New(GAMEPAD_BUY_BANK_SPACE_SCENE_NAME, SCENE_MANAGER, BANKING_INTERACTION)

    local StateChanged = function(oldState, newState)
        if newState == SCENE_SHOWN then
            ZO_Dialogs_ShowGamepadDialog("BUY_BANK_SPACE_GAMEPAD", { cost = self.cost })
        end
    end

    GAMEPAD_BUY_BANK_SPACE_SCENE:RegisterCallback("StateChange", StateChanged)
end

function ZO_BuyBankSpace_Gamepad:Show(cost)
    self.cost = cost
    SCENE_MANAGER:Push(GAMEPAD_BUY_BANK_SPACE_SCENE_NAME)
end

function ZO_BuyBankSpace_Gamepad:Hide()
    SCENE_MANAGER:Hide(GAMEPAD_BUY_BANK_SPACE_SCENE_NAME)
end
function ZO_GamepadBankingBuyBankSpaceTopLevel_Initialize(control)
    BUY_BANK_SPACE_GAMEPAD = ZO_BuyBankSpace_Gamepad:New(control)
end