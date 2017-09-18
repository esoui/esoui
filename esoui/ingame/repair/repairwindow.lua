ZO_Repair = ZO_Object:Subclass()

local DATA_TYPE_REPAIR_ITEM = 1

function ZO_Repair:New(...)
    local repair = ZO_Object.New(self)
    repair:Initialize(...)
    return repair
end

function ZO_Repair:Initialize(control)
    self.control = control
    control.owner = self

    REPAIR_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self.list = self.control:GetNamedChild("List")
    self.activeTab = self.control:GetNamedChild("TabsActive")
    self.tabs = self.control:GetNamedChild("Tabs")

    self.freeSlotsLabel = self.control:GetNamedChild("InfoBarFreeSlots")
    self.money = self.control:GetNamedChild("InfoBarMoney")

    self:InitializeList()
    self:InitializeFilterBar()
    self:InitializeSortHeader()
    self:InitializeEvents()
end

function ZO_Repair:InitializeList()
    ZO_ScrollList_AddDataType(self.list, DATA_TYPE_REPAIR_ITEM, "ZO_PlayerInventorySlot", 52, function(control, data) self:SetupRepairItem(control, data) end, nil, nil, ZO_InventorySlot_OnPoolReset)
end

function ZO_Repair:InitializeFilterBar()
    local menuBarData =
    {
        initialButtonAnchorPoint = RIGHT, 
        buttonTemplate = "ZO_StoreTab", 
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    ZO_MenuBar_SetData(self.tabs, menuBarData)

    local repairFilter =
    {
        tooltipText = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_DAMAGED),
        filterType = ITEMFILTERTYPE_DAMAGED,

        descriptor = ITEMFILTERTYPE_DAMAGED,
        normal = "EsoUI/Art/Repair/inventory_tabIcon_repair_up.dds", 
        pressed = "EsoUI/Art/Repair/inventory_tabIcon_repair_down.dds",
        highlight = "EsoUI/Art/Repair/inventory_tabIcon_repair_over.dds",
    }

    ZO_MenuBar_AddButton(self.tabs, repairFilter)
    ZO_MenuBar_SelectDescriptor(self.tabs, ITEMFILTERTYPE_DAMAGED)

    self.activeTab:SetText(GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_DAMAGED))
end

function ZO_Repair:InitializeSortHeader()
    self.sortHeaders = ZO_SortHeaderGroup:New(self.control:GetNamedChild("SortBy"), true)

    self.sortOrder = ZO_SORT_ORDER_UP
    self.sortKey = "name"

    local function OnSortHeaderClicked(key, order)
        self.sortKey = key
        self.sortOrder = order
        self:ApplySort()
    end

    self.sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    self.sortHeaders:AddHeadersFromContainer()
    self.sortHeaders:SelectHeaderByKey("name", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)
end

function ZO_Repair:InitializeEvents()
    local function RefreshAll()
        if not self.control:IsControlHidden() then
            self:RefreshAll()
        end
    end
    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, function() self:UpdateMoney() end)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshAll)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshAll)
end

function ZO_Repair:RefreshAll()
    self:UpdateList()
    self:UpdateFreeSlots()
end

function ZO_Repair:UpdateMoney()
    if not self.control:IsControlHidden() then
        ZO_CurrencyControl_SetSimpleCurrency(self.money, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_KEYBOARD_CURRENCY_OPTIONS)
    end
end

function ZO_Repair:UpdateFreeSlots()
    if not self.control:IsControlHidden() then
        local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
        if numUsedSlots < numSlots then
            self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
        else
            self.freeSlotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
        end
    end
end

do
    local function GatherDamagedEquipmentFromBag(bagId, dataTable)
        local bagSlots = GetBagSize(bagId)
        for slotIndex=0, bagSlots - 1 do
            local condition = GetItemCondition(bagId, slotIndex)
            if condition < 100 and not IsItemStolen(bagId, slotIndex) then
                local icon, stackCount, _, _, _, _, _, quality = GetItemInfo(bagId, slotIndex)
                if stackCount > 0 then
                    local repairCost = GetItemRepairCost(bagId, slotIndex)
                    if repairCost > 0 then
                        local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex))
                        local data = { bagId = bagId, slotIndex = slotIndex, name = name, icon = icon, stackCount = stackCount, quality = quality, condition = condition, repairCost = repairCost }
                        dataTable[#dataTable + 1] = ZO_ScrollList_CreateDataEntry(DATA_TYPE_REPAIR_ITEM, data)
                    end
                end
            end
        end
    end

    function ZO_Repair:UpdateList()
        ZO_ScrollList_Clear(self.list)
        ZO_ScrollList_ResetToTop(self.list)

        local scrollData = ZO_ScrollList_GetDataList(self.list)

        GatherDamagedEquipmentFromBag(BAG_WORN, scrollData)
        GatherDamagedEquipmentFromBag(BAG_BACKPACK, scrollData)

        self:ApplySort()
    end
end

local REPAIR_COST_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

function ZO_Repair:SetupRepairItem(control, data)
    local statusControl = GetControl(control, "Status")
    local slotControl = GetControl(control, "Button")
    local nameControl = GetControl(control, "Name")
    local repairCostControl = GetControl(control, "SellPrice")
    local itemConditionControl = GetControl(control, "ItemCondition")

    statusControl:SetHidden(true)

    ZO_Inventory_BindSlot(slotControl, SLOT_TYPE_REPAIR, data.slotIndex, data.bagId)
    ZO_Inventory_BindSlot(control, SLOT_TYPE_REPAIR, data.slotIndex, data.bagId)
    ZO_Inventory_SetupSlot(slotControl, data.stackCount, data.icon)

    nameControl:SetText(data.name) -- already formatted
    nameControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality))

    repairCostControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(repairCostControl, CURT_MONEY, data.repairCost, REPAIR_COST_CURRENCY_OPTIONS)

    itemConditionControl:SetText(zo_strformat(SI_ITEM_CONDITION_PERCENT, data.condition))
end

do
    local sortKeys =
    {
        name = { },
        condition = { tiebreaker = "name", isNumeric = true },
        repairCost = { tiebreaker = "name", isNumeric = true },
    }
    function ZO_Repair:ApplySort()
        local function Comparator(left, right)
            return ZO_TableOrderingFunction(left.data, right.data, self.sortKey, sortKeys, self.sortOrder)
        end

        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, Comparator)
        ZO_ScrollList_Commit(self.list)
    end
end

function ZO_Repair:OnShown()
    self:UpdateList()
    self:UpdateMoney()
    self:UpdateFreeSlots()
end

function ZO_Repair_OnInitialize(control)
    REPAIR_WINDOW = ZO_Repair:New(control)
end
