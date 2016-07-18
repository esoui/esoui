local ITEM_TEMPLATE = "ZO_GamepadItemSubEntryTemplate"
local CATEGORY_HEADER_TEMPLATE = "ZO_GamepadMenuEntryHeaderTemplate"

-------------------------------------
-- Gamepad Guild Bank Inventory List
-------------------------------------
ZO_GamepadGuildBankInventoryList = ZO_GamepadBankCommonInventoryList:Subclass()

function ZO_GamepadGuildBankInventoryList:New(...)
    return ZO_GamepadBankCommonInventoryList.New(self, ...)
end

do
    local NO_DEPOSIT_PERMISSIONS_STRING = zo_strformat(GetString(SI_GAMEPAD_GUILD_BANK_NO_DEPOSIT_PERMISSIONS), GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_BANK_DEPOSIT))
    local NO_WITHDRAW_PERMISSIONS_STRING = GetString(SI_GAMEPAD_GUILD_BANK_NO_WITHDRAW_PERMISSIONS)
    local NO_ITEMS_TO_WITHDRAW_STRING = GetString(SI_GAMEPAD_GUILD_BANK_NO_WITHDRAW_ITEMS)

    function ZO_GamepadGuildBankInventoryList:RefreshList()
        if self.control:IsHidden() then
            self.isDirty = true
            return
        end

        local guildId = GetSelectedGuildBankId()
        local shouldShowList = false

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
            elseif self.mode == BANKING_GAMEPAD_MODE_DEPOSIT then
                if not guildHasDepositPrivilege then
                    self:SetNoItemText(NO_DEPOSIT_PERMISSIONS_STRING)
                else
                    shouldShowList = DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_DEPOSIT)
                end
            elseif self.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
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
            if self.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
                canUse = GetGuildBankedCurrencyAmount(currencyType) ~= 0 and 
                            GetCarriedCurrencyAmount(currencyType) ~= GetMaxCarriedCurrencyAmount(currencyType)
            elseif self.mode == BANKING_GAMEPAD_MODE_DEPOSIT then
                canUse = GetGuildBankedCurrencyAmount(currencyType) ~= GetMaxGuildBankCurrencyAmount(currencyType) and 
                          GetCarriedCurrencyAmount(currencyType) ~= 0
            end

            return canUse
        end

        local shouldAddDepositWithdrawEntry = self.mode == BANKING_GAMEPAD_MODE_WITHDRAW and playerCanWithdrawGold or 
                                              self.mode == BANKING_GAMEPAD_MODE_DEPOSIT and guildHasDepositPrivilege

        if shouldAddDepositWithdrawEntry then
            self:AddDepositWithdrawEntry(CURT_MONEY, CanWithdrawOrDeposit(CURT_MONEY))
        end

        if shouldShowList then
            ZO_ClearTable(self.dataBySlotIndex)

            local slots = self:GenerateSlotTable()

            local template = self.template
            local currentBestCategoryName = nil
            for i, itemData in ipairs(slots) do
                local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
                self:SetupItemEntry(entry, itemData)

                if itemData.bestGamepadItemCategoryName ~= currentBestCategoryName then
                    currentBestCategoryName = itemData.bestGamepadItemCategoryName
                    entry:SetHeader(currentBestCategoryName)

                    self.list:AddEntryWithHeader(template, entry)
                else
                    self.list:AddEntry(template, entry)
                end

                self.dataBySlotIndex[itemData.slotIndex] = entry
            end
        end

        self.list:Commit()

        self.isDirty = false
    end
end

do
    local BANK_MODE_INFO = {
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
    GAMEPAD_GUILD_BANK_SCENE = ZO_InteractScene:New(GAMEPAD_GUILD_BANK_SCENE_NAME, SCENE_MANAGER, GUILD_BANKING_INTERACTION)
    ZO_BankingCommon_Gamepad.Initialize(self, control, GAMEPAD_GUILD_BANK_SCENE)

    self:SetBankedBag(BAG_GUILDBANK)
    self:SetCarriedBag(BAG_BACKPACK)

    local function OnOpenGuildBank()
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show(GAMEPAD_GUILD_BANK_SCENE_NAME)
        end
    end

    self.control:RegisterForEvent(EVENT_OPEN_GUILD_BANK, OnOpenGuildBank)
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

function ZO_GuildBank_Gamepad:OnSelectionChangedCallback()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
end

function ZO_GuildBank_Gamepad:OnWithdrawDepositStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:UpdateGuildBankList()
        self.depositList:RefreshList()
    elseif newState == SCENE_SHOWN then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GuildBank_Gamepad:SetWithdrawLoadingControlShown(shouldShow)
    self.withdrawLoadingControl:SetHidden(not shouldShow)
    self.withdrawList:GetControl():SetHidden(shouldShow)
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
        self:LayoutInventoryItemTooltip(self.currentItemList:GetTargetData())
    end

    local function OnGuildBankTransferError(_, reason)
        if reason == GUILD_BANK_ITEM_NOT_FOUND or reason == GUILD_BANK_NOT_IN_A_GUILD then
            GAMEPAD_GUILD_BANK_ERROR:Show(reason)
        end
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
    end

    local function AlertAndRefreshHeader(currencyType, currentCurrency, oldCurrency, reason)       
        local alertString
        local amount
        local IS_GAMEPAD = true

        if reason == CURRENCY_CHANGE_REASON_GUILD_BANK_DEPOSIT then
            amount = oldCurrency - currentCurrency
            alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_DEPOSITED, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, useShortFormat, currencyType, IS_GAMEPAD))
        elseif CURRENCY_CHANGE_REASON_GUILD_BANK_WITHDRAWAL then
            amount = currentCurrency - oldCurrency
            alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_WITHDRAWN, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, useShortFormat, currencyType, IS_GAMEPAD)) 
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

    local function UpdateGuildBankedMoney()
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

    self.eventTable =   {
        [EVENT_CLOSE_GUILD_BANK] = OnCloseGuildBank,
        [EVENT_GUILD_BANK_OPEN_ERROR] = OnGuildBankOpenError,

        [EVENT_GUILD_BANK_SELECTED] = OnGuildBankSelected,
        [EVENT_GUILD_BANK_DESELECTED] = OnGuildBankDeselected,
        [EVENT_GUILD_BANK_ITEMS_READY] = OnGuildBankReady,
        [EVENT_GUILD_BANK_ITEM_ADDED] = OnGuildBankUpdated,
        [EVENT_GUILD_BANK_ITEM_REMOVED] = OnGuildBankUpdated,
        [EVENT_GUILD_BANK_UPDATED_QUANTITY] = OnGuildBankUpdated,
        [EVENT_GUILD_BANK_TRANSFER_ERROR] = OnGuildBankTransferError,

        [EVENT_MONEY_UPDATE] = UpdateMoney,
        [EVENT_GUILD_BANKED_MONEY_UPDATE] = UpdateGuildBankedMoney,

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

function ZO_GuildBank_Gamepad:OnDeferredInitialization()
    ZO_SharedInventory_SelectAccessibleGuildBank()

    self.withdrawLoadingControl = self.control:GetNamedChild("Loading")

    if self.loadingGuildBank then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        self:SetWithdrawLoadingControlShown(true)
    end
end

do
    local function DepositItemFilter(itemData)
        return not itemData.stolen and 
               not IsItemBound(itemData.bagId, itemData.slotIndex) and
               not IsItemBoPAndTradeable(itemData.bagId, itemData.slotIndex) and
               not (itemData.itemType == ITEMTYPE_TROPHY) and
               not itemData.isPlayerLocked
    end

    function ZO_GuildBank_Gamepad:InitializeLists()
        local function OnSelectedDataCallback(...)
            self:OnSelectionChanged(...)
        end

        local SETUP_LIST_LOCALLY = true
        local withdrawList = self:AddList("withdraw", SETUP_LIST_LOCALLY, ZO_GamepadGuildBankInventoryList, BANKING_GAMEPAD_MODE_WITHDRAW, self.bankedBag, SLOT_TYPE_GUILD_BANK_ITEM, OnSelectedDataCallback, nil, nil, nil, nil, nil, ZO_SharedGamepadEntry_OnSetup)
        self:SetWithdrawList(withdrawList)

        local depositList = self:AddList("deposit", SETUP_LIST_LOCALLY, ZO_GamepadGuildBankInventoryList, BANKING_GAMEPAD_MODE_DEPOSIT, self.carriedBag, SLOT_TYPE_ITEM, OnSelectedDataCallback, nil, nil, nil, nil, nil, ZO_SharedGamepadEntry_OnSetup)
        depositList:SetItemFilterFunction(DepositItemFilter)
        self:SetDepositList(depositList)
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
    local switchActiveGuildKeybind = {
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
            name =  function()
                            local currentDataType = GetCurrentDataType(self.withdrawList)
                            if currentDataType == CURRENT_DATA_TYPE_GOLD_SELECTOR then
                                return GetString(SI_BANK_WITHDRAW_GOLD_BIND)
                            elseif currentDataType == CURRENT_DATA_TYPE_ITEM_DATA then
                                return GetString(SI_BANK_WITHDRAW)
                            end
                        end,
            enabled = function() return self:CanWithdraw() end,
            visible =   function()
                            local currentDataType = GetCurrentDataType(self.withdrawList)
                            if currentDataType == CURRENT_DATA_TYPE_GOLD_SELECTOR then
                                return CanUseBank(GUILD_PERMISSION_BANK_WITHDRAW_GOLD)
                            elseif currentDataType == CURRENT_DATA_TYPE_ITEM_DATA then
                                return CanUseBank(GUILD_PERMISSION_BANK_WITHDRAW) and GetNumBagUsedSlots(BAG_GUILDBANK) > 0
                            end
                            return false
                        end,
            callback =  function() self:ConfirmWithdrawal() end
        },
        switchActiveGuildKeybind,
    })

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.withdrawKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self:SetDepositKeybindDescriptor(
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name =  function()
                            local currentDataType = GetCurrentDataType(self.depositList)
                            if currentDataType == CURRENT_DATA_TYPE_GOLD_SELECTOR then
                                return GetString(SI_BANK_DEPOSIT_GOLD_BIND)
                            elseif currentDataType == CURRENT_DATA_TYPE_ITEM_DATA then
                                return GetString(SI_BANK_DEPOSIT)
                            end
                        end,
            enabled = function() return self:CanDeposit() end,
            visible =   function()
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

local function CreateModeData(name, mode, itemList, keybind)
    return {
        text = GetString(name),
        mode = mode,
        itemList = itemList,
        keybind = keybind,
    }
end

function ZO_GuildBank_Gamepad:CanDeposit()
    local inventoryData = self.currentItemList:GetTargetData()
    if not inventoryData then
        return false
    end

    local currencyType = inventoryData.currencyType
    if currencyType then
        if self:GetMaxBankedFunds(currencyType) ~= GetGuildBankedMoney() and GetCarriedCurrencyAmount(currencyType) ~= 0 then
            return true
        else
            if self:GetMaxBankedFunds(currencyType) == GetGuildBankedMoney() then
                return false, GetString("SI_GUILDBANKRESULT", GUILD_BANK_NO_SPACE_LEFT) -- "Your guild bank is full"
            elseif GetCarriedCurrencyAmount(currencyType) == 0 then
                return false, GetString(SI_INVENTORY_ERROR_NO_PLAYER_FUNDS) -- "No player funds"
            end
        end
    elseif GetNumBagFreeSlots(BAG_GUILDBANK) > 0 then
        return true
    else
        return false, GetString(SI_INVENTORY_ERROR_BANK_FULL) -- "Your guild bank is full"
    end
end

function ZO_GuildBank_Gamepad:CanWithdraw()
    local inventoryData = self.currentItemList:GetTargetData()
    if not inventoryData then
        return false
    end

    local currencyType = inventoryData.currencyType
    if currencyType then
        if GetGuildBankedMoney() ~= 0 and GetCarriedCurrencyAmount(currencyType) ~= GetMaxCarriedCurrencyAmount(currencyType) then
            return true
        else
            if GetCarriedCurrencyAmount(currencyType) == GetMaxCarriedCurrencyAmount(currencyType) then
                return false, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL) -- "Your inventory is full"
            elseif GetGuildBankedMoney() == 0 then
                return false, GetString(SI_INVENTORY_ERROR_NO_BANK_FUNDS) -- "No bank funds"
            end
        end
    elseif GetNumBagFreeSlots(BAG_BACKPACK) > 0 then
        return true
    else
        return false, GetString(SI_INVENTORY_ERROR_INVENTORY_FULL) -- "Your inventory is full"
    end
end

function ZO_GuildBank_Gamepad:ConfirmDeposit()
    local inventoryData = self.currentItemList:GetTargetData()
    if inventoryData.currencyType then
        self:SetMaxAndShowSelector(GetMaxGuildBankDeposit)
    else
        DepositItem(self.depositList)
    end
end

function ZO_GuildBank_Gamepad:ConfirmWithdrawal()
    local inventoryData = self.currentItemList:GetTargetData()
    if inventoryData.currencyType then
        self:SetMaxAndShowSelector(GetMaxGuildBankWithdrawal)
    else
        WithdrawItem(self.withdrawList)
    end
end

function ZO_GuildBank_Gamepad:SetMaxAndShowSelector(maxInputFunction)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
    self:SetMaxInputFunction(maxInputFunction)
    self:ShowSelector()
end

function ZO_GuildBank_Gamepad:GetWithdrawMoneyAmount()
    return GetGuildBankedMoney()
end

function ZO_GuildBank_Gamepad:GetMaxBankedFunds(currencyType)
    return GetMaxGuildBankCurrencyAmount(currencyType)
end

function ZO_GuildBank_Gamepad:GetDepositMoneyAmount()
    return GetCarriedCurrencyAmount(CURT_MONEY)
end

function ZO_GuildBank_Gamepad:DepositFunds(currencyType, amount)
    DepositCurrencyIntoGuildBank(currencyType, amount)
end

function ZO_GuildBank_Gamepad:WithdrawFunds(currencyType, amount)
    WithdrawCurrencyFromGuildBank(currencyType, amount)
end

function ZO_GuildBank_Gamepad:OnCategoryChangedCallback(selectedData)
    if self.loadingGuildBank and selectedData.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
        self:SetSelectedInventoryData(nil)
    end
end

function ZO_GuildBank_Gamepad:InitializeHeader()
    ZO_BankingCommon_Gamepad.InitializeHeader(self)
    ZO_GUILD_NAME_FOOTER_FRAGMENT:SetGuildName(GetGuildName(GetSelectedGuildBankId()))
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

local function GuildBankEntryHeaderTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control:SetText(data.bestGamepadItemCategoryName)
end

local SORT_KEYS =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

local function ItemSort(item1, item2)
    return ZO_TableOrderingFunction(item1, item2, "bestGamepadItemCategoryName", SORT_KEYS, ZO_SORT_ORDER_UP)
end

function ZO_GuildBank_Gamepad:UpdateGuildBankList()
    self.withdrawList:RefreshList()
end

function ZO_GuildBank_Gamepad:SetSelectedInventoryData(_, inventoryData)
    self:LayoutInventoryItemTooltip(inventoryData)
end

function ZO_GuildBank_Gamepad:ClearAllGuildBankItems()
    self.withdrawList:ClearList()
end

function ZO_GuildBank_Gamepad_Initialize(control)
    GAMEPAD_GUILD_BANK = ZO_GuildBank_Gamepad:New(control)
end