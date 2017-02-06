local DATA_TYPE_CURRENCY_ITEM = 1
local LIST_ENTRY_HEIGHT = 52

-------------------
--InventoryWallet Manager
-------------------

local InventoryWalletManager = ZO_Object:Subclass()

function InventoryWalletManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function InventoryWalletManager:Initialize(container)
    self.container = container
    self.money = GetControl(container, "InfoBarMoney")

    self.freeSlotsLabel = GetControl(container, "InfoBarFreeSlots")

    self.list = GetControl(container, "List")
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE_CURRENCY_ITEM, "ZO_InventoryWalletSlot", LIST_ENTRY_HEIGHT, function(control, data) self:SetUpEntry(control, data) end, nil, nil, ZO_InventorySlot_OnPoolReset)

    self.sortHeadersControl = container:GetNamedChild("SortBy")
    self.sortHeaders = ZO_SortHeaderGroup:New(self.sortHeadersControl, true)

    local function OnSortHeaderClicked(key, order)
        self.sortKey = key
        self.sortOrder = order
        self:ApplySort()
    end

    self.sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    self.sortHeaders:AddHeadersFromContainer()
    self.sortHeaders:SelectHeaderByKey("name")

    self:RegisterEvents()
    self:RefreshCurrency()

    WALLET_FRAGMENT = ZO_FadeSceneFragment:New(ZO_InventoryWallet)
    WALLET_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
                                                            if(newState == SCENE_FRAGMENT_SHOWN) then
                                                                self:UpdateList()
                                                                self:UpdateFreeSlots()
																self:RefreshCurrency()
                                                            end
                                                        end)

end

--Adding a new currency entry here should handle all updating unless GetCarriedCurrencyAmount does not accept that type like Crowns
ZO_CURRENCY_INFO_TABLE =
{
    [CURT_MONEY] = { name = GetString(SI_CURRENCY_GOLD), event = EVENT_MONEY_UPDATE },
    [CURT_ALLIANCE_POINTS] = { name = GetString(SI_CURRENCY_ALLIANCE_POINTS), event = EVENT_ALLIANCE_POINT_UPDATE, },
    [CURT_TELVAR_STONES] = { name = GetString(SI_CURRENCY_TELVAR_STONES), event = EVENT_TELVAR_STONE_UPDATE }, 
	[CURT_WRIT_VOUCHERS] = { name = GetString(SI_CURRENCY_WRIT_VOUCHERS), event = EVENT_WRIT_VOUCHER_UPDATE }, 
}

function InventoryWalletManager:RegisterEvents()

    local function OnCurrencyUpdated(eventCode, newMoney, oldMoney, reason)
        if not self.container:IsHidden() then
            self:RefreshCurrency()
            self:UpdateList()
        end
    end

    local function UpdateFreeSlots()
         self:UpdateFreeSlots()
    end

    for type, info in pairs(ZO_CURRENCY_INFO_TABLE) do
        ZO_InventoryWallet:RegisterForEvent(info.event, OnCurrencyUpdated)
    end

    ZO_InventoryWallet:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, UpdateFreeSlots)
    ZO_InventoryWallet:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, UpdateFreeSlots)
end

function InventoryWalletManager:SetUpEntry(control, data)
    local nameControl = GetControl(control, "Name")
    nameControl:SetText(data.name)

    local amountControl = GetControl(control, "Amount")
    ZO_CurrencyControl_SetSimpleCurrency(amountControl, data.currencyType, data.amount, ITEM_SLOT_CURRENCY_OPTIONS)
end

local sortKeys =
{
    name = { },
    amount = { tiebreaker = "name", isNumeric = true },
}

function InventoryWalletManager:SortData()
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    self.sortFunction = self.sortFunction or function(entry1, entry2)
        local sortKey = self.sortKey
        local sortOrder = self.sortOrder

        return ZO_TableOrderingFunction(entry1.data, entry2.data, sortKey, sortKeys, sortOrder)
    end
    table.sort(scrollData, self.sortFunction)
end

function InventoryWalletManager:ApplySort()
    self:SortData()
    ZO_ScrollList_Commit(self.list)
end

function InventoryWalletManager:RefreshCurrency()
    ZO_CurrencyControl_SetSimpleCurrency(self.money, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)
end

function InventoryWalletManager:UpdateFreeSlots()
    local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
    if(numUsedSlots < numSlots) then
        self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
    else
        self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
    end
end

function InventoryWalletManager:UpdateList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)
    ZO_ScrollList_ResetToTop(self.list)

    for type, info in pairs(ZO_CURRENCY_INFO_TABLE) do
        self:CreateAndAddCurrencyEntry(scrollData, type)
    end

    self:ApplySort()

    self.sortHeadersControl:SetHidden(#scrollData == 0)
end

function InventoryWalletManager:CreateAndAddCurrencyEntry(scrollData, currencyType)
    local entryData =
    {
        name = ZO_CURRENCY_INFO_TABLE[currencyType].name,
        currencyType = currencyType,
        amount = GetCarriedCurrencyAmount(currencyType)
    }

    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_CURRENCY_ITEM, entryData))
end

function ZO_InventoryWallet_OnInitialize(control)
    INVENTORY_WALLET = InventoryWalletManager:New(control)
end
