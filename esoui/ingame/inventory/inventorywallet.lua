local DATA_TYPE_CURRENCY_ITEM = 1
local LIST_ENTRY_HEIGHT = 52
local CURRENCY_LOCATION_ALL = CURRENCY_LOCATION_MAX_VALUE + 1

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

    self:InitializeFilterBar()

    self:RegisterEvents()
    self:RefreshCurrency()

    WALLET_FRAGMENT = ZO_FadeSceneFragment:New(ZO_InventoryWallet)
    WALLET_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
                                                            if newState == SCENE_FRAGMENT_SHOWING then
                                                                self:UpdateList()
                                                                self:UpdateFreeSlots()
																self:RefreshCurrency()
                                                            end
                                                        end)

end

function InventoryWalletManager:AddFilterBarButton(currencyLocation, normal, pressed, highlight)
    local button =
    {
        descriptor = currencyLocation,
        normal = normal,
        pressed = pressed, 
        highlight = highlight, 
        callback = function()
            self:OnFilterSelected(currencyLocation)
        end,
        tooltipText = self:GetCurrencyLocationName(currencyLocation),
    }
    ZO_MenuBar_AddButton(self.filterBarControl, button)
end

function InventoryWalletManager:InitializeFilterBar()
    self.filterBarControl = self.container:GetNamedChild("Tabs")
    self.filterBarLabel = self.filterBarControl:GetNamedChild("Active")
    self:AddFilterBarButton(CURRENCY_LOCATION_ACCOUNT, "EsoUI/Art/Inventory/inventory_currencyTab_accountWide_up.dds", "EsoUI/Art/Inventory/inventory_currencyTab_accountWide_down.dds", "EsoUI/Art/Inventory/inventory_currencyTab_accountWide_over.dds")
    self:AddFilterBarButton(CURRENCY_LOCATION_CHARACTER, "EsoUI/Art/Inventory/inventory_currencyTab_onCharacter_up.dds", "EsoUI/Art/Inventory/inventory_currencyTab_onCharacter_down.dds", "EsoUI/Art/Inventory/inventory_currencyTab_onCharacter_over.dds")
    self:AddFilterBarButton(CURRENCY_LOCATION_ALL, "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds")
    local SKIP_ANIMATION = true
    ZO_MenuBar_SelectDescriptor(self.filterBarControl, CURRENCY_LOCATION_ALL, SKIP_ANIMATION)
end

function InventoryWalletManager:GetCurrencyLocationName(currencyLocation)
    return currencyLocation == CURRENCY_LOCATION_ALL and GetString(SI_INVENTORY_WALLET_ALL_FILTER) or GetString("SI_CURRENCYLOCATION", currencyLocation)
end

function InventoryWalletManager:OnFilterSelected(currencyLocation)
    if self.currencyLocationFilter ~= currencyLocation then
        self.currencyLocationFilter = currencyLocation
        self.filterBarLabel:SetText(self:GetCurrencyLocationName(currencyLocation))
        self:UpdateList()
    end
end

function InventoryWalletManager:RegisterEvents()
    local function RefreshCurrencies()
        if not self.container:IsHidden() then
            self:RefreshCurrency()
            self:UpdateList()
        end
    end

    ZO_InventoryWallet:RegisterForEvent(EVENT_CURRENCY_UPDATE, RefreshCurrencies)
    ZO_InventoryWallet:RegisterForEvent(EVENT_CURRENCY_CAPS_CHANGED, RefreshCurrencies)

    local function UpdateFreeSlots()
         self:UpdateFreeSlots()
    end

    ZO_InventoryWallet:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, UpdateFreeSlots)
    ZO_InventoryWallet:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, UpdateFreeSlots)
end

do
    local FORMAT_EXTRA_OPTIONS =
    {
        showCap = true,
    }

    function InventoryWalletManager:SetUpEntry(control, data)
        local nameControl = GetControl(control, "Name")
        nameControl:SetText(zo_strformat(SI_CURRENCY_NAME_FORMAT, data.name))

        local amountControl = GetControl(control, "Amount")
        FORMAT_EXTRA_OPTIONS.currencyLocation = GetCurrencyPlayerStoredLocation(data.currencyType)
        amountControl:SetText(zo_strformat(SI_NUMBER_FORMAT, ZO_Currency_FormatKeyboard(data.currencyType, data.amount, ZO_CURRENCY_FORMAT_AMOUNT_ICON, FORMAT_EXTRA_OPTIONS)))
    end
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
    ZO_CurrencyControl_SetSimpleCurrency(self.money, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_KEYBOARD_CURRENCY_OPTIONS)
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

    local IS_PLURAL = false
    local IS_UPPER = false
    for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
        if IsCurrencyValid(currencyType) then
            local currencyPlayerStoredLocation = GetCurrencyPlayerStoredLocation(currencyType)
            if self.currencyLocationFilter == CURRENCY_LOCATION_ALL or currencyPlayerStoredLocation == self.currencyLocationFilter then
                local entryData =
                {
                    name = GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER),
                    currencyType = currencyType,
                    amount = GetCurrencyAmount(currencyType, currencyPlayerStoredLocation)
                }
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_TYPE_CURRENCY_ITEM, entryData))
            end
        end
    end

    self:ApplySort()

    self.sortHeadersControl:SetHidden(#scrollData == 0)
end

function ZO_InventoryWallet_OnInitialize(control)
    INVENTORY_WALLET = InventoryWalletManager:New(control)
end
