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

ZO_BankingCommon_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_BankingCommon_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_BankingCommon_Gamepad:Initialize(control, bankScene)
    self.isInitialized = false
    self.mode = BANKING_GAMEPAD_MODE_WITHDRAW
    
    self:SetCurrencyType(CURT_MONEY) --default to gold until list is initialized

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

        self:SetCurrentList(self:GetMainListForMode())
        self:AddKeybinds()
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
    local currentList = self:GetCurrentList()
    currentList:Deactivate()
    
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
        local currentList = self:GetCurrentList()
        currentList:Activate()
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
        if GetBankingBag() == BAG_BANK then
            headerData.data1HeaderText = GetString(SI_GAMEPAD_BANK_BANK_CAPACITY_LABEL)
        else
            headerData.data1HeaderText = GetString(SI_GAMEPAD_BANK_HOUSE_BANK_CAPACITY_LABEL)
        end
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
    self:SetCurrentKeybindDescriptor(selectedData.keybind)

    self:AddKeybinds()

    self:OnCategoryChangedCallback(selectedData)
end

function ZO_BankingCommon_Gamepad:SetCurrentCarriedAmount(control)
    local moneyAmount = self:GetDepositMoneyAmount()

    self:SetSimpleCurrency(control, moneyAmount, self.currencyType, BANKING_GAMEPAD_MODE_DEPOSIT, ZO_BANKING_CURRENCY_LABEL_OPTIONS)
    -- must return a non-nil value so that the control isn't auto-hidden
    return true
end

function ZO_BankingCommon_Gamepad:SetCurrentBankedAmount(control)
    local moneyAmount = self:GetWithdrawMoneyAmount()
    local currencyOptions = self:GetWithdrawMoneyOptions()
    local obfuscateAmount = self:DoesObfuscateWithdrawAmount()

    self:SetSimpleCurrency(control, moneyAmount, self.currencyType, BANKING_GAMEPAD_MODE_WITHDRAW, currencyOptions, obfuscateAmount)
    -- must return a non-nil value so that the control isn't auto-hidden
    return true
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

function ZO_BankingCommon_Gamepad:OnTargetChanged(list, targetData)
    self:SetCurrencyType(targetData and targetData.currencyType or nil)
    self:LayoutBankingEntryTooltip(targetData)
    self:OnTargetChangedCallback()

    self:RefreshHeaderData()
end

function ZO_BankingCommon_Gamepad:LayoutBankingEntryTooltip(inventoryData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if inventoryData and inventoryData.bagId then
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
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
end

function ZO_BankingCommon_Gamepad:OnTargetChangedCallback()
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