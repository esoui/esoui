-------------------------------------
-- Gamepad Guild Bank Inventory List
-------------------------------------
ZO_GamepadGuildBankInventoryList = ZO_GamepadBankCommonInventoryList:Subclass()

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

do
    local NO_DEPOSIT_PERMISSIONS_STRING = zo_strformat(SI_GAMEPAD_GUILD_BANK_NO_DEPOSIT_PERMISSIONS, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_BANK_DEPOSIT))
    local NO_WITHDRAW_PERMISSIONS_STRING = GetString(SI_GAMEPAD_GUILD_BANK_NO_WITHDRAW_PERMISSIONS)
    local NO_ITEMS_TO_WITHDRAW_STRING = GetString(SI_GAMEPAD_GUILD_BANK_NO_WITHDRAW_ITEMS)

    local function IsInFilteredCategories(filterCategories, itemData)
        -- No category selected, don't filter out anything.
        if ZO_IsTableEmpty(filterCategories) then
            return true
        end

        for _, filterData in ipairs(itemData.filterData) do
            if filterCategories[filterData] then
                return true
            end
        end

        return false
    end

    function ZO_GamepadGuildBankInventoryList:RefreshList(shouldTriggerRefreshListCallback)
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

        local shouldAddDepositWithdrawEntry = (self:IsInWithdrawMode() and playerCanWithdrawGold) or (self:IsInDepositMode() and guildHasDepositPrivilege)
        if shouldAddDepositWithdrawEntry then
            self.goldTransferEntryData:SetEnabled(CanWithdrawOrDeposit(CURT_MONEY))
            self.list:AddEntry("ZO_GamepadBankCurrencySelectorTemplate", self.goldTransferEntryData)
        end

        if shouldShowList then
            for _, bagId in ipairs(self.inventoryTypes) do
                self.dataByBagAndSlotIndex[bagId] = {}
            end

            local template = self.template
            local currentBestCategoryName = nil
            for _, itemData in ipairs(slots) do
                local passesTextFilter = TEXT_SEARCH_MANAGER:IsItemInSearchTextResults(self.searchContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, itemData.bagId, itemData.slotIndex)
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

        self.list:Commit()

        self.isDirty = false

        if shouldTriggerRefreshListCallback and self.onRefreshListCallback then
            self.onRefreshListCallback(self.list)
        end
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

function ZO_GuildBank_Gamepad:Initialize(control)
    self.withdrawLoadingControlShown = false

    GAMEPAD_GUILD_BANK_SCENE = ZO_InteractScene:New(GAMEPAD_GUILD_BANK_SCENE_NAME, SCENE_MANAGER, GUILD_BANKING_INTERACTION)
    ZO_BankingCommon_Gamepad.Initialize(self, control, GAMEPAD_GUILD_BANK_SCENE)

    self:ClearBankedBags()
    self:AddBankedBag(BAG_GUILDBANK)
    self:SetCarriedBag(BAG_BACKPACK)

    local function OnOpenGuildBank()
        if IsInGamepadPreferredMode() then
            self:ActivateTextSearch()
            SCENE_MANAGER:Show(GAMEPAD_GUILD_BANK_SCENE_NAME)
        end
    end

    self.control:RegisterForEvent(EVENT_OPEN_GUILD_BANK, OnOpenGuildBank)

    self:SetTextSearchContext("guildBankTextSearch")
end

function ZO_GuildBank_Gamepad:ActivateTextSearch()
    if self.searchContext then
        -- Reset the search string to force a search again since the guild bank slots get rebuild each show.
        TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, BAG_GUILDBANK)
        ZO_Gamepad_ParametricList_BagsSearch_Screen.ActivateTextSearch(self)
    end
end

function ZO_GuildBank_Gamepad:OnSceneShowing()
    ZO_SharedInventory_SelectAccessibleGuildBank(self.lastSelectedGuildBankId)
    self:RefreshGuildBank()
    TriggerTutorial(TUTORIAL_TRIGGER_GUILD_BANK_OPENED)
end

function ZO_GuildBank_Gamepad:SetCurrentKeybindDescriptor(descriptor)
    self:RemoveKeybinds()
    ZO_BankingCommon_Gamepad.SetCurrentKeybindDescriptor(self, descriptor)
    self:RefreshKeybinds()
end

function ZO_GuildBank_Gamepad:AddKeybinds()
    if self.currentKeybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindStripDescriptor)
    end
end

function ZO_GuildBank_Gamepad:RemoveKeybinds()
    if self.currentKeybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindStripDescriptor)
    end
end

function ZO_GuildBank_Gamepad:UpdateKeybinds()
    if self.currentKeybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
    end
end

function ZO_GuildBank_Gamepad:RefreshKeybinds()
    if self:GetCurrentList() and self:GetCurrentList():IsActive() and not self:IsHeaderActive() then
        if not KEYBIND_STRIP:HasKeybindButtonGroup(self.currentKeybindStripDescriptor) then
            self:AddKeybinds()
        else
            self:UpdateKeybinds()
        end
    else
        self:RemoveKeybinds()
    end
end

function ZO_GuildBank_Gamepad:OnWithdrawDepositStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        local TRIGGER_CALLBACK = true
        self:UpdateGuildBankList(TRIGGER_CALLBACK)
        self.depositList:RefreshList(TRIGGER_CALLBACK)
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

        if shouldShowWithdrawList and self:CanLeaveHeader() then
            self:RequestLeaveHeader()
        end
    end
end

function ZO_GuildBank_Gamepad:CreateEventTable()
    local function OnCloseGuildBank()
        self:DeactivateTextSearch()
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
        self:MarkDirtyByBagId(bagId)
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
        local UPDATE_SELECTION = true
        self.depositList:RefreshList(UPDATE_SELECTION)
        if GAMEPAD_GUILD_BANK_SCENE:IsShowing() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindStripDescriptor)
        end
        OnGuildBankUpdated()
    end

    local function RefreshHeaderData()
        self:RefreshHeaderData()
    end

    local function RefreshLists()
        local TRIGGER_CALLBACK = true
        self.depositList:RefreshList(TRIGGER_CALLBACK)
        self.withdrawList:RefreshList(TRIGGER_CALLBACK)
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

function ZO_GuildBank_Gamepad:OnDeferredInitialization()
    ZO_SharedInventory_SelectAccessibleGuildBank()

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function()
        self:MarkDirtyByBagId(BAG_BACKPACK)
        self:MarkDirtyByBagId(BAG_GUILDBANK)
        self:RefreshGuildBank()
    end)

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
               not itemData.isPlayerLocked
    end

    function ZO_GuildBank_Gamepad:InitializeLists()
        local function OnTargetDataChangedCallback(...)
            self:OnTargetChanged(...)
        end

        local function OnRefreshList(list)
            if list:GetNumItems() == 0 then
                self:RequestEnterHeader()
            else
                self:RequestLeaveHeader()
                if not list:IsActive() then
                    list:Activate()
                end
            end
        end

        local SETUP_LIST_LOCALLY = true
        local NO_ON_SELECTED_DATA_CHANGED_CALLBACK = nil
        local withdrawList = self:AddList("withdraw", SETUP_LIST_LOCALLY, ZO_GamepadGuildBankInventoryList, BANKING_GAMEPAD_MODE_WITHDRAW, self.bankedBags, SLOT_TYPE_GUILD_BANK_ITEM, NO_ON_SELECTED_DATA_CHANGED_CALLBACK, nil, nil, nil, nil, nil, ZO_SharedGamepadEntry_OnSetup)
        withdrawList:SetOnRefreshListCallback(OnRefreshList)
        withdrawList:SetSearchContext(self.searchContext)
        withdrawList:SetOnTargetDataChangedCallback(OnTargetDataChangedCallback)
        self:SetWithdrawList(withdrawList)
        local withdrawListFragment = self:GetListFragment("withdraw")
        withdrawListFragment:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                --The parametric list screen does not call OnTargetChanged when changing the current list which means anything that updates off of the current
                --selection is out of date. So we run OnTargetChanged when a list shows to remedy this.
                self:OnTargetChanged(self:GetCurrentList(), self:GetTargetData())
            end
            --See SetWithdrawLoadingControlShown for more info
            if newState ~= SCENE_FRAGMENT_HIDING then
                self.withdrawList:GetControl():SetHidden(self.withdrawLoadingControlShown)
            end
        end)

        local withdrawListControl = withdrawList:GetControl()
        local withdrawContainerControl = withdrawListControl:GetParent()
        self.withdrawLoadingControl = CreateControlFromVirtual("$(parent)Loading", withdrawContainerControl, "ZO_GamepadCenteredLoadingIconAndLabelTemplate")
        self.withdrawLoadingControl:GetNamedChild("ContainerText"):SetText(GetString(SI_INVENTORY_RETRIEVING_ITEMS))

        local depositList = self:AddList("deposit", SETUP_LIST_LOCALLY, ZO_GamepadGuildBankInventoryList, BANKING_GAMEPAD_MODE_DEPOSIT, self.carriedBag, SLOT_TYPE_ITEM, NO_ON_SELECTED_DATA_CHANGED_CALLBACK, nil, nil, nil, nil, nil, ZO_SharedGamepadEntry_OnSetup)
        depositList:SetOnRefreshListCallback(OnRefreshList)
        depositList:SetSearchContext(self.searchContext)
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
    ZO_BankingCommon_Gamepad.InitializeKeybindStripDescriptors(self)

    self.switchActiveGuildKeybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
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
                return GetString(SI_BANK_WITHDRAW_BIND)
            end,
            enabled = function()
                return self:CanWithdraw()
            end,
            visible = function()
                local currentDataType = GetCurrentDataType(self.withdrawList)
                if currentDataType == CURRENT_DATA_TYPE_GOLD_SELECTOR then
                    return CanUseBank(GUILD_PERMISSION_BANK_WITHDRAW_GOLD)
                elseif currentDataType == CURRENT_DATA_TYPE_ITEM_DATA then
                    return CanUseBank(GUILD_PERMISSION_BANK_WITHDRAW) and GetNumBagUsedSlots(BAG_GUILDBANK) > 0
                end
            end,
            callback = function()
                self:ConfirmWithdrawal()
            end,
        },
        {
            keybind = "UI_SHORTCUT_LEFT_STICK",
            name = function()
                local sortIconPath = self.withdrawList.currentSortOrder == ZO_ICON_SORT_ARROW_UP and SORT_ARROW_UP or ZO_ICON_SORT_ARROW_DOWN
                local sortIconText = zo_iconFormat(sortIconPath, 16, 16)
                if ZO_IsTableEmpty(self.withdrawList.filterCategories) then
                    return zo_strformat(GetString(SI_GAMEPAD_BANK_FILTER_KEYBIND), GetString("SI_ITEMLISTSORTTYPE", self.withdrawList.currentSortType), sortIconText)
                else
                    return zo_strformat(GetString(SI_GAMEPAD_BANK_FILTER_SORT_DROPDOWN_TEXT), NonContiguousCount(self.withdrawList.filterCategories), GetString("SI_ITEMLISTSORTTYPE", self.withdrawList.currentSortType), sortIconText)
                end
            end,
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_BANK_SEARCH_FILTERS", { bankObject = self })
            end
        },
        self.switchActiveGuildKeybind,
    })

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.withdrawKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        SCENE_MANAGER:HideCurrentScene()
    end)

    self:SetDepositKeybindDescriptor(
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                return GetString(SI_BANK_DEPOSIT_BIND)
            end,
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
            end,
            callback = function()
                self:ConfirmDeposit()
            end
        },
        self.switchActiveGuildKeybind,
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
    ZO_BankingCommon_Gamepad.OnCategoryChangedCallback(self, selectedData)

    if self.loadingGuildBank and selectedData.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
        self:SetSelectedInventoryData(nil)
    end
end

function ZO_GuildBank_Gamepad:InitializeHeader()
    ZO_BankingCommon_Gamepad.InitializeHeader(self)

    ZO_GUILD_NAME_FOOTER_FRAGMENT:SetGuildName(GetGuildName(GetSelectedGuildBankId()))
end

function ZO_GuildBank_Gamepad:OnEnterHeader()
    ZO_Gamepad_ParametricList_Screen.OnEnterHeader(self)

    if self.textSearchHeaderFocus then
        KEYBIND_STRIP:AddKeybindButton(self.switchActiveGuildKeybind)
    end
end

function ZO_GuildBank_Gamepad:OnLeaveHeader()
    ZO_Gamepad_ParametricList_Screen.OnLeaveHeader(self)

    if self.textSearchHeaderFocus then
        KEYBIND_STRIP:RemoveKeybindButton(self.switchActiveGuildKeybind)
    end
end

function ZO_GuildBank_Gamepad:ExitHeader()
    ZO_Gamepad_ParametricList_Screen.ExitHeader(self)

    if self.textSearchHeaderFocus then
        KEYBIND_STRIP:RemoveKeybindButton(self.switchActiveGuildKeybind)
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

function ZO_GuildBank_Gamepad:UpdateGuildBankList(shouldTriggerRefreshCallback)
    self.withdrawList:RefreshList(shouldTriggerRefreshCallback)
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