local ACTIVATE_SPINNER = true
local DEACTIVATE_SPINNER = false

local GOLD_ICON_24 = zo_iconFormat(ZO_GAMEPAD_CURRENCY_ICON_GOLD_TEXTURE, 24, 24)

-------------------------------------
-- Gamepad Bank Inventory List
-------------------------------------
ZO_GamepadBankInventoryList = ZO_GamepadBankCommonInventoryList:Subclass()

function ZO_GamepadBankInventoryList:New(...)
    return ZO_GamepadBankCommonInventoryList.New(self, ...)
end

function ZO_GamepadBankInventoryList:RefreshList()
    if self.control:IsHidden() then
        self.isDirty = true
        return
    end
    self.isDirty = false

    self.list:Clear()

    local function CanWithdrawOrDeposit(currencyType)
        -- Check if there are funds to withdraw or if the player's wallet isn't full, depending on the mode
        local canUse = true

        if self.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
            canUse = GetBankedCurrencyAmount(currencyType) ~= 0 and GetCarriedCurrencyAmount(currencyType) ~= GetMaxCarriedCurrencyAmount(currencyType)
        elseif self.mode == BANKING_GAMEPAD_MODE_DEPOSIT then
            canUse = GetBankedCurrencyAmount(currencyType) ~= GetMaxBankCurrencyAmount(currencyType) and GetCarriedCurrencyAmount(currencyType) ~= 0
        end

        return canUse
    end

    self:AddDepositWithdrawEntry(CURT_MONEY, CanWithdrawOrDeposit(CURT_MONEY))
    self:AddDepositWithdrawEntry(CURT_TELVAR_STONES, CanWithdrawOrDeposit(CURT_TELVAR_STONES))

    self.dataBySlotIndex = {}

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

        self.dataBySlotIndex[itemData.slotIndex] = entry
    end

    self.list:Commit()
end

-----------------------
-- Gamepad Banking
-----------------------

local GAMEPAD_BANKING_SCENE_NAME = "gamepad_banking"

ZO_GamepadBanking = ZO_BankingCommon_Gamepad:Subclass()

function ZO_GamepadBanking:New(...)
    return ZO_BankingCommon_Gamepad.New(self, ...)
end

local function OnCloseBank()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Hide(GAMEPAD_BANKING_SCENE_NAME)
    end
end

function ZO_GamepadBanking:Initialize(control)
    local function OnOpenBank()
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show(GAMEPAD_BANKING_SCENE_NAME)
        end
    end

    GAMEPAD_BANKING_SCENE = ZO_InteractScene:New(GAMEPAD_BANKING_SCENE_NAME, SCENE_MANAGER, BANKING_INTERACTION)
    ZO_BankingCommon_Gamepad.Initialize(self, control, GAMEPAD_BANKING_SCENE)

    self:SetBankedBag(BAG_BANK)
    self:SetCarriedBag(BAG_BACKPACK)

    self.control:RegisterForEvent(EVENT_OPEN_BANK, OnOpenBank)
    self.control:RegisterForEvent(EVENT_CLOSE_BANK, OnCloseBank)
end

function ZO_GamepadBanking:OnSceneHiding()
    if self.confirmationMode then
        self:UpdateSpinnerConfirmation(DEACTIVATE_SPINNER, self.currentItemList)
    end
end

function ZO_GamepadBanking:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_GamepadBanking:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_GamepadBanking:OnDeferredInitialization()
    self.spinner = self.control:GetNamedChild("SpinnerContainer")
    self.spinner:InitializeSpinner()

    local selectorContainer = self.selectorContainer
    self.selectorFirstLabel = selectorContainer:GetNamedChild("FirstLabel")
    self.selectorFirstValue = selectorContainer:GetNamedChild("FirstValue")

    self.selectorSecondLabel = selectorContainer:GetNamedChild("SecondLabel")
    self.selectorSecondValue = selectorContainer:GetNamedChild("SecondValue")

    self.firstSelectorLabelUsed = false
    if self:SetTelvarStoneBankFeeValue(self.selectorFirstValue) then
        self.selectorFirstLabel:SetText(self:GetTelvarStoneBankFeeLabel())
        self.firstSelectorLabelUsed = true
    end
    
    local minDepositLabel = self.firstSelectorLabelUsed and self.selectorSecondLabel or self.selectorFirstLabel
    local minDepositValue = self.firstSelectorLabelUsed and self.selectorSecondValue or self.selectorFirstValue
    if self:SetTelvarStoneMinimumDepositValue(minDepositValue) then
        minDepositLabel:SetText(self:GetTelvarStoneMinimumDepositLabel())
        if not self.firstSelectorLabelUsed then
            self.firstSelectorLabelUsed = true
        else
            self.secondSelectorLabelUsed = true
        end
    end

end

function ZO_GamepadBanking:InitializeLists()
    local function OnSelectedDataCallback(...)
        self:OnSelectionChanged(...)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
    end

    local function ItemSetupTemplate(...)
        self:SetupItem(...)
    end

    local SETUP_LIST_LOCALLY = true
    local withdrawList = self:AddList("withdraw", SETUP_LIST_LOCALLY, ZO_GamepadBankInventoryList, BANKING_GAMEPAD_MODE_WITHDRAW, self.bankedBag, SLOT_TYPE_BANK_ITEM, OnSelectedDataCallback, nil, nil, nil, nil, nil, ItemSetupTemplate)
    self:SetWithdrawList(withdrawList)

    local depositList = self:AddList("deposit", SETUP_LIST_LOCALLY, ZO_GamepadBankInventoryList, BANKING_GAMEPAD_MODE_DEPOSIT, self.carriedBag, SLOT_TYPE_ITEM, OnSelectedDataCallback, nil, nil, nil, nil, nil, ItemSetupTemplate)
    depositList:SetItemFilterFunction(function(slot) return not slot.stolen end)
    self:SetDepositList(depositList)
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

function ZO_GamepadBanking:GetTelvarStoneMinimumDepositLabel()
    return GetString(SI_GAMEPAD_TELVAR_STONES_MINIMUM_DEPOSIT)
end

function ZO_GamepadBanking:GetTelvarStoneBankFeeLabel()
    return GetString(SI_GAMEPAD_TELVAR_STONES_BANK_FEE)
end

function ZO_GamepadBanking:SetTelvarStoneMinimumDepositValue(control)
    if self.telvarStoneMinDeposit > 0 then
        self:SetSimpleCurrency(control, self.telvarStoneMinDeposit, CURT_TELVAR_STONES)
        return true
    end
    return false
end

function ZO_GamepadBanking:SetTelvarStoneBankFeeValue(control)
    if self.telvarStoneBankFee > 0 then
        self:SetSimpleCurrency(control, self.telvarStoneBankFee, CURT_TELVAR_STONES)
        return true
    end
    return false
end

function ZO_GamepadBanking:ShowSelector()
    if self.mode == BANKING_GAMEPAD_MODE_DEPOSIT and self.currencyType == CURT_TELVAR_STONES then
        self.selectorFirstLabel:SetHidden(not self.firstSelectorLabelUsed)
        self.selectorFirstValue:SetHidden(not self.firstSelectorLabelUsed)
        self.selectorSecondLabel:SetHidden(not self.secondSelectorLabelUsed)
        self.selectorSecondValue:SetHidden(not self.secondSelectorLabelUsed)
    else
        self.selectorFirstLabel:SetHidden(true)
        self.selectorFirstValue:SetHidden(true)
        self.selectorSecondLabel:SetHidden(true)
        self.selectorSecondValue:SetHidden(true)
    end

    ZO_BankingCommon_Gamepad.ShowSelector(self)
end

-- spinner functions

function ZO_GamepadBanking:SetSpinnerValue(max, value)
    self.spinner:SetMinMax(1, max)
    self.spinner:SetValue(value)
end

local function CanWithdrawDeposit(inventoryData, bagType)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventoryData)

    if not DoesBagHaveSpaceFor(bagType, bag, index) then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, bagType == BAG_BANK and SI_INVENTORY_ERROR_BANK_FULL or SI_INVENTORY_ERROR_INVENTORY_FULL)
    else
        return true
    end
end

function ZO_GamepadBanking:ConfirmWithdrawDeposit(list, bagType)
    local inventoryData = list:GetTargetData()

    if CanWithdrawDeposit(inventoryData, bagType) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventoryData)
        if self.confirmationMode then
            local quantity = self.spinner:GetValue()
            if quantity > 0 then
                PickupInventoryItem(bag, index, quantity)
                PlaceInTransfer()
                self:UpdateSpinnerConfirmation(DEACTIVATE_SPINNER, list)
            end
        elseif inventoryData.stackCount > 1 then
            self:UpdateSpinnerConfirmation(ACTIVATE_SPINNER, list)
            self:SetSpinnerValue(inventoryData.stackCount, inventoryData.stackCount)
        else
            PickupInventoryItem(bag, index)
            PlaceInTransfer()
        end
    end
end

function ZO_GamepadBanking:UpdateSpinnerConfirmation(activateSpinner, list)
    self.confirmationMode = activateSpinner
    if activateSpinner then
        self.spinner:AttachToTargetListEntry(list:GetParametricList())
        ZO_GamepadGenericHeader_Deactivate(self.header)

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
    else
        self.spinner:DetachFromListEntry()
        ZO_GamepadGenericHeader_Activate(self.header)

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)
    end

    list:RefreshVisible()
    list:SetUseTriggers(not activateSpinner)
    list:SetDirectionalInputEnabled(not activateSpinner)
end

function ZO_GamepadBanking:CancelWithdrawDeposit(list)
    if self.confirmationMode then
        self:UpdateSpinnerConfirmation(DEACTIVATE_SPINNER, list)
    else
        SCENE_MANAGER:HideCurrentScene()
    end
end

--end spinner functions

function ZO_GamepadBanking:InitializeKeybindStripDescriptors()
    local withdrawDepositKeybind =
    {
        keybind = "UI_SHORTCUT_PRIMARY",
        name = function()
                 local isWithdraw = self.mode == BANKING_GAMEPAD_MODE_WITHDRAW
                 local list = isWithdraw and self.withdrawList or self.depositList
                 local data = list:GetTargetData()
                 if data then
                    if data.currencyType then
                        return isWithdraw and GetString(SI_BANK_WITHDRAW_GOLD_BIND) or GetString(SI_BANK_DEPOSIT_GOLD_BIND)
                    else
                        return isWithdraw and GetString(SI_BANK_WITHDRAW) or GetString(SI_BANK_DEPOSIT)
                    end
                end
        end,
        enabled = function()
            local data = self.currentItemList:GetTargetData()
            if data then
                return data.enabled
            end
            return true
        end,
        callback = function()
            local data = self.currentItemList:GetTargetData()
            if data and data.currencyType then
                self:SetMaxInputFunction(self.mode == BANKING_GAMEPAD_MODE_WITHDRAW and GetMaxBankWithdrawal or GetMaxBankDeposit)
                self:ShowSelector()
            else
                if self.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
                    self:ConfirmWithdrawDeposit(self.withdrawList, BAG_BACKPACK)
                else
                    self:ConfirmWithdrawDeposit(self.depositList, BAG_BANK)
                end
            end
        end,
    }

    self.mainKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        withdrawDepositKeybind,
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                local cost = GetNextBankUpgradePrice()
                if GetCarriedCurrencyAmount(CURT_MONEY) >= cost then
                    return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_CurrencyControl_FormatCurrency(cost), GOLD_ICON_24)
                end
                return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(cost)), GOLD_ICON_24)
            end,
            visible = function()
                return IsBankUpgradeAvailable()
            end,
            enabled = function()
                return GetCarriedCurrencyAmount(CURT_MONEY) >= GetNextBankUpgradePrice()
            end,
            callback = function()
                if GetNextBankUpgradePrice() > GetCarriedCurrencyAmount(CURT_MONEY) then
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_BUY_BANK_SPACE_CANNOT_AFFORD))
                else
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
                    DisplayBankUpgrade()
                end
            end
        },
        {
            keybind = "UI_SHORTCUT_LEFT_STICK",
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            visible = function()
                return self.mode == BANKING_GAMEPAD_MODE_DEPOSIT
            end,
            callback = function()
                StackBag(BAG_BACKPACK)
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.mainKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self:SetDepositKeybindDescriptor(self.mainKeybindStripDescriptor)
    self:SetWithdrawKeybindDescriptor(self.mainKeybindStripDescriptor)

    self.spinnerKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        withdrawDepositKeybind,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.spinnerKeybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function()
                                                        local list = self.mode == BANKING_GAMEPAD_MODE_WITHDRAW and self.withdrawList or self.depositList
                                                        self:CancelWithdrawDeposit(list)
                                                    end)
end

function ZO_GamepadBanking:GetWithdrawMoneyAmount()
    if self:GetCurrencyType() then  --returns nil if on an item
        return GetBankedCurrencyAmount(self:GetCurrencyType())
    end
end

function ZO_GamepadBanking:GetMaxBankedFunds(currencyType)
    return GetMaxBankCurrencyAmount(currencyType)
end

function ZO_GamepadBanking:GetDepositMoneyAmount()
    if self:GetCurrencyType() then  
        return GetCarriedCurrencyAmount(self:GetCurrencyType())
    end
end

function ZO_GamepadBanking:DepositFunds(currencyType, amount)
    DepositCurrencyIntoBank(currencyType, amount)
end

function ZO_GamepadBanking:WithdrawFunds(currencyType, amount)
    WithdrawCurrencyFromBank(currencyType, amount)
end

function ZO_GamepadBanking:CreateEventTable()

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

        if reason == CURRENCY_CHANGE_REASON_BANK_DEPOSIT then
            amount = oldCurrency - currentCurrency
            alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_DEPOSITED, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(amount, useShortFormat, currencyType, IS_GAMEPAD))
        elseif reason == CURRENCY_CHANGE_REASON_BANK_WITHDRAWAL then
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

    local function UpdateTelvarStones(event, currentStones, oldStones, reason)
        RefreshLists()
        AlertAndRefreshHeader(CURT_TELVAR_STONES, currentStones, oldStones, reason)
    end

    local function UpdateBankedTelvarStones()
        RefreshLists()
        RefreshHeaderData()
    end

    local function UpdateBankedMoney()
        RefreshLists()
        RefreshHeaderData()
    end

    local function OnInventoryUpdate()
        self:RefreshHeaderData()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
        self:LayoutInventoryItemTooltip(self.currentItemList:GetTargetData())
    end
    
    self.eventTable =   {
        [EVENT_MONEY_UPDATE] = UpdateMoney,
        [EVENT_TELVAR_STONE_UPDATE] = UpdateTelvarStones,
        [EVENT_BANKED_TELVAR_STONES_UPDATE] = UpdateBankedTelvarStones,
        [EVENT_BANKED_MONEY_UPDATE] = UpdateBankedMoney,

        [EVENT_INVENTORY_FULL_UPDATE] = OnInventoryUpdate,
        [EVENT_INVENTORY_SINGLE_SLOT_UPDATE] = OnInventoryUpdate,
    }
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
                    return zo_strformat(SI_GAMEPAD_BANK_UPGRADE_ACCEPT, costString, GOLD_ICON_24)
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