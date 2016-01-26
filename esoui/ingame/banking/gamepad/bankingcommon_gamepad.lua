BANKING_GAMEPAD_MODE_WITHDRAW = 1
BANKING_GAMEPAD_MODE_DEPOSIT = 2

-------------------------------------
-- Gamepad Guild Bank Inventory List
-------------------------------------

ZO_GamepadBankCommonInventoryList = ZO_GamepadInventoryList:Subclass()

function ZO_GamepadBankCommonInventoryList:New(...)
    return ZO_GamepadInventoryList.New(self, ...)
end

function ZO_GamepadBankCommonInventoryList:Initialize(control, bankMode, ...)
    self:SetBankMode(bankMode)
    ZO_GamepadInventoryList.Initialize(self, control, ...)

    self.list:AddDataTemplate("ZO_GamepadBankCurrencySelectorTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

do 
    local BANK_DEPOSIT_ENTRY_MONEY = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_BANK_DEPOSIT_GOLD_ENTRY_NAME),"EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_gold_deposit.dds")
    BANK_DEPOSIT_ENTRY_MONEY:SetIconTintOnSelection(true)
    BANK_DEPOSIT_ENTRY_MONEY:SetIconDisabledTintOnSelection(true)
    BANK_DEPOSIT_ENTRY_MONEY.currencyType = CURT_MONEY

    local BANK_WITHDRAW_ENTRY_MONEY = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_BANK_WITHDRAW_GOLD_ENTRY_NAME),"EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_gold_withdraw.dds")
    BANK_WITHDRAW_ENTRY_MONEY:SetIconTintOnSelection(true)
    BANK_WITHDRAW_ENTRY_MONEY:SetIconDisabledTintOnSelection(true)
    BANK_WITHDRAW_ENTRY_MONEY.currencyType = CURT_MONEY

    local BANK_DEPOSIT_ENTRY_TELVAR_STONES = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_BANK_DEPOSIT_STONES_ENTRY_NAME),"EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_telvar_deposit.dds")
    BANK_DEPOSIT_ENTRY_TELVAR_STONES:SetIconTintOnSelection(true)
    BANK_DEPOSIT_ENTRY_TELVAR_STONES:SetIconDisabledTintOnSelection(true)
    BANK_DEPOSIT_ENTRY_TELVAR_STONES.currencyType = CURT_TELVAR_STONES

    local BANK_WITHDRAW_ENTRY_TELVAR_STONES = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_BANK_WITHDRAW_STONES_ENTRY_NAME),"EsoUI/Art/Bank/Gamepad/gp_bank_menuIcon_telvar_withdraw.dds")
    BANK_WITHDRAW_ENTRY_TELVAR_STONES:SetIconTintOnSelection(true)
    BANK_WITHDRAW_ENTRY_TELVAR_STONES:SetIconDisabledTintOnSelection(true)
    BANK_WITHDRAW_ENTRY_TELVAR_STONES.currencyType = CURT_TELVAR_STONES
    
    local CURRENCY_TYPE_DEPOSIT_WITHDRAW_ENTRY_INFO =
    {
        [CURT_MONEY] = 
        { 
            [BANKING_GAMEPAD_MODE_WITHDRAW] = BANK_WITHDRAW_ENTRY_MONEY,
            [BANKING_GAMEPAD_MODE_DEPOSIT] = BANK_DEPOSIT_ENTRY_MONEY,
        },
        [CURT_TELVAR_STONES] = 
        { 
            [BANKING_GAMEPAD_MODE_WITHDRAW] = BANK_WITHDRAW_ENTRY_TELVAR_STONES,
            [BANKING_GAMEPAD_MODE_DEPOSIT] = BANK_DEPOSIT_ENTRY_TELVAR_STONES,
        },
    }

    function ZO_GamepadBankCommonInventoryList:AddDepositWithdrawEntry(currencyType, isEnabled)
        local entryData = CURRENCY_TYPE_DEPOSIT_WITHDRAW_ENTRY_INFO[currencyType][self.mode]
        entryData:SetEnabled(isEnabled)

        self.list:AddEntry("ZO_GamepadBankCurrencySelectorTemplate", entryData)
    end
end

function ZO_GamepadBankCommonInventoryList:SetBankMode(mode)
    self.mode = mode
end

--[[
-- ZO_BankingCommon_Gamepad
--]]

ZO_BankingCommon_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_BankingCommon_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_BankingCommon_Gamepad:Initialize(control, bankScene)
    self.isInitialized = false
    self.mode = BANKING_GAMEPAD_MODE_WITHDRAW
    
    self:SetCurrencyType(CURT_MONEY) --default to gold until list is initialized
    self.telvarStoneBankFee = GetTelvarStoneBankingFee()    --cache these guys cause they're static and referenced a lot
    self.telvarStoneMinDeposit = GetTelvarStoneMinimumDeposit()

    self:CreateEventTable()

    local DONT_ACTIVATE_LIST_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, DONT_ACTIVATE_LIST_ON_SHOW, bankScene)
end

function ZO_BankingCommon_Gamepad:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:PerformDeferredInitialize()
        self:RegisterForEvents()

        self:RefreshHeaderData()
        ZO_GamepadGenericHeader_Activate(self.header)
        self.header:SetHidden(false)

        self:SetCurrentList(self.currentItemList)
        self:AddKeybinds()
        self:OnSceneShowing()
    elseif newState == SCENE_SHOWN then
        self:OnSceneShown()
    elseif newState == SCENE_HIDING then
        self:OnSelectionChanged(nil)
        self:HideSelector()
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

function ZO_BankingCommon_Gamepad:OnDeferredInitialize()
    self:InitializeLists()

    self:InitializeHeader()

    self:InitializeWithdrawDepositKeybindDescriptor()
    self:InitializeWithdrawDepositSelector()

    self:OnDeferredInitialization()

    self:SetMode(self.mode)
end

function ZO_BankingCommon_Gamepad:InitializeHeader()

    -- create tabs
    local withdrawTabData = self:CreateModeData(SI_BANK_WITHDRAW, BANKING_GAMEPAD_MODE_WITHDRAW, self.withdrawList, self.withdrawKeybindStripDescriptor)
    local depositTabData = self:CreateModeData(SI_BANK_DEPOSIT, BANKING_GAMEPAD_MODE_DEPOSIT, self.depositList, self.depositKeybindStripDescriptor)

    self.tabsTable = {
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
    self.headerData = {
        data1HeaderText = GetString(SI_GAMEPAD_BANK_BANK_FUNDS_LABEL),
        data1Text = function(...) return self:SetCurrentBankedAmount(...) end,

        data2HeaderText = GetString(SI_GAMEPAD_BANK_PLAYER_FUNDS_LABEL),
        data2Text = function(...) return self:SetCurrentCarriedAmount(...) end,

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
         
    selectorContainer:RegisterForEvent(EVENT_MONEY_UPDATE, OnUpdateEvent)
    selectorContainer:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, OnUpdateEvent)
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
                if self.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
                    return GetString(SI_BANK_WITHDRAW_GOLD_BIND)
                else
                    return GetString(SI_BANK_DEPOSIT_GOLD_BIND)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                return self.hasEnough
            end,
            callback = function()
                local amount = self.selector:GetValue()
                local data = self.currentItemList:GetTargetData()

                if self.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
                    self:WithdrawFunds(data.currencyType, amount)
                elseif self.mode == BANKING_GAMEPAD_MODE_DEPOSIT then
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

local CURRENCY_TYPE_TO_TEXTURE =
{
    [CURT_MONEY] = "EsoUI/Art/currency/gamepad/gp_gold.dds",
    [CURT_TELVAR_STONES] = "EsoUI/Art/currency/gamepad/gp_telvar.dds",
}

function ZO_BankingCommon_Gamepad:SetSelectorCurrency(currencyType)
    self.selectorCurrency:SetTexture(CURRENCY_TYPE_TO_TEXTURE[currencyType])
end

function ZO_BankingCommon_Gamepad:UpdateInput()
    local currentFunds = self.maxInputFunction(self.currencyType)
    local meetsMinDeposit = true
    local meetsBankFee = true
    
    if self.mode == BANKING_GAMEPAD_MODE_DEPOSIT then
        if self.currencyType == CURT_TELVAR_STONES then
            local selectorValue = self.selector:GetValue()
            meetsMinDeposit = selectorValue >= self.telvarStoneMinDeposit
            meetsBankFee = self.telvarStoneBankFee == 0 or selectorValue > self.telvarStoneBankFee
        end
    end

    self.selector:SetMaxValue(currentFunds)
    self:SetSelectorCurrency(self.currencyType)

    local hasEnough = (currentFunds >= self.selector:GetValue()) and meetsMinDeposit and meetsBankFee
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
    self.currentItemList:Deactivate()
    
    local list = self.currentItemList.list
    local targetControl = list:GetTargetControl()
    if targetControl then
        targetControl:SetHidden(true)
    else
        --if the targetControl doesn't exist because of trigger scrolling, wait til selection changed to hide control
        list:SetOnSelectedDataChangedCallback(OnSelectedDataChanged)
        local targetData = list:GetTargetData()
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
        self.currentItemList:Activate()
        self.currentItemList.list:GetTargetControl():SetHidden(false)
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

-- set the bag that will be banked from, banked is a word.
function ZO_BankingCommon_Gamepad:SetBankedBag(bag)
    self.bankedBag = bag
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
    return  {
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

        headerData.data2HeaderText = GetString(SI_GAMEPAD_BANK_PLAYER_FUNDS_LABEL)
        headerData.data2Text = function(...) return self:SetCurrentCarriedAmount(...) end
    else
        headerData.data1HeaderText = GetString(SI_GAMEPAD_BANK_BANK_CAPACITY_LABEL)
        headerData.data1Text = function(...) return self:SetBankCapacityHeaderText(...) end

        headerData.data2HeaderText = GetString(SI_GAMEPAD_BANK_PLAYER_CAPACITY_LABEL)
        headerData.data2Text = function(...) return self:SetPlayerCapacityHeaderText(...) end
    end

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
    self:OnRefreshHeaderData()
end

function ZO_BankingCommon_Gamepad:OnCategoryChanged(selectedData)
    self.mode = selectedData.mode
    self:HideSelector()

    self:RemoveKeybinds()

    self:SetCurrentList(selectedData.itemList)
    self.currentItemList = selectedData.itemList
    self:SetCurrentKeybindDescriptor(selectedData.keybind)

    self:AddKeybinds()

    self:OnCategoryChangedCallback(selectedData)
end

function ZO_BankingCommon_Gamepad:SetCurrentCarriedAmount(control)
    local moneyAmount = self:GetDepositMoneyAmount()

    self:SetSimpleCurrency(control, moneyAmount, self.currencyType, BANKING_GAMEPAD_MODE_DEPOSIT)
    -- must return a non-nil value so that the control isn't auto-hidden
    return true
end

function ZO_BankingCommon_Gamepad:SetCurrentBankedAmount(control)
    local moneyAmount = self:GetWithdrawMoneyAmount()

    self:SetSimpleCurrency(control, moneyAmount, self.currencyType, BANKING_GAMEPAD_MODE_WITHDRAW)
    -- must return a non-nil value so that the control isn't auto-hidden
    return true
end

function ZO_BankingCommon_Gamepad:GetCurrencyType()
    return self.currencyType
end 

-- private functions

local BANKING_CURRENCY_LABEL_OPTIONS = ZO_ShallowTableCopy(ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)

function ZO_BankingCommon_Gamepad:SetSimpleCurrency(control, amount, currencyType, colorMinValueForMode)
    BANKING_CURRENCY_LABEL_OPTIONS.color = nil        -- Reset the color
    
    if self.mode == BANKING_GAMEPAD_MODE_WITHDRAW then
        if (colorMinValueForMode == self.mode and amount == 0) or (colorMinValueForMode ~= self.mode and amount == self:GetMaxBankedFunds(currencyType)) then
            BANKING_CURRENCY_LABEL_OPTIONS.color = ZO_ERROR_COLOR
        end
    elseif self.mode == BANKING_GAMEPAD_MODE_DEPOSIT then
        if (colorMinValueForMode == self.mode and amount == 0) or (colorMinValueForMode ~= self.mode and amount == GetMaxCarriedCurrencyAmount(currencyType)) then
            BANKING_CURRENCY_LABEL_OPTIONS.color = ZO_ERROR_COLOR
        end
    end

    ZO_CurrencyControl_SetSimpleCurrency(control, currencyType, amount, BANKING_CURRENCY_LABEL_OPTIONS)
end

function ZO_BankingCommon_Gamepad:RecolorCapacityHeader(control, usedSlots, bagSize, recolorMode)
    local color = ZO_SELECTED_TEXT

    if recolorMode == self.mode and usedSlots == bagSize then
        color = ZO_ERROR_COLOR
    end

    control:SetColor(color:UnpackRGBA())
end

function ZO_BankingCommon_Gamepad:SetBankCapacityHeaderText(control)
    local usedSlots = GetNumBagUsedSlots(self.bankedBag)
    local bagSize = GetBagSize(self.bankedBag)

    self:RecolorCapacityHeader(control, usedSlots, bagSize, BANKING_GAMEPAD_MODE_DEPOSIT)

    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, usedSlots, bagSize)
end

function ZO_BankingCommon_Gamepad:SetPlayerCapacityHeaderText(control)
    local usedSlots = GetNumBagUsedSlots(self.carriedBag)
    local bagSize = GetBagSize(self.carriedBag)

    self:RecolorCapacityHeader(control, usedSlots, bagSize, BANKING_GAMEPAD_MODE_WITHDRAW)

    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, usedSlots, bagSize)
end

function ZO_BankingCommon_Gamepad:OnSelectionChanged(_, selectedData)
    self:SetCurrencyType(selectedData and selectedData.currencyType or nil)
    self:LayoutInventoryItemTooltip(selectedData)
    self:OnSelectionChangedCallback()

    self:RefreshHeaderData()
end

function ZO_BankingCommon_Gamepad:LayoutInventoryItemTooltip(inventoryData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)

    if inventoryData and inventoryData.bagId then
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
    end
end

-- functions that should be overwritten

function ZO_BankingCommon_Gamepad:GetWithdrawMoneyAmount()
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
end

function ZO_BankingCommon_Gamepad:OnSelectionChangedCallback()
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