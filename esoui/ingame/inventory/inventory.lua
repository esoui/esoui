--Variables
local PlayerInventory = nil
PLAYER_INVENTORY = nil

INVENTORY_BACKPACK = 1
INVENTORY_QUEST_ITEM = 2
INVENTORY_BANK = 3
INVENTORY_GUILD_BANK = 4
INVENTORY_CRAFT_BAG = 5

local SEARCH_TYPE_INVENTORY = 1
local SEARCH_TYPE_QUEST_ITEM = 2
local SEARCH_TYPE_QUEST_TOOL = 3
local CACHE_DATA = true
local DONT_CACHE_DATA = false

local PREVENT_LAYOUT = false

local searchButtonTexture = "EsoUI/Art/Buttons/searchButton_normal.dds"
local searchButtonDownTexture = "EsoUI/Art/Buttons/searchButton_mouseDown.dds"
local cancelButtonTexture = "EsoUI/Art/Buttons/cancelButton_normal.dds"
local cancelButtonDownTexture = "EsoUI/Art/Buttons/cancelButton_mouseDown.dds"

local NEW_ICON_TEXTURE = "EsoUI/Art/Inventory/newItem_icon.dds"
local STOLEN_ICON_TEXTURE = "EsoUI/Art/Inventory/inventory_stolenItem_icon.dds"


BANKING_INTERACTION =
{
    type = "Banking",
    interactTypes = { INTERACTION_BANK },
}


GUILD_BANKING_INTERACTION =
{
    type = "GuildBanking",
    interactTypes = { INTERACTION_GUILDBANK },
}

-----------
--Callbacks
-----------

--tabs 

local function HandleTabSwitch(tabData)
    -- special case inventory list hiding based on selecting quest inventory
    -- bank filters don't mess with the visibility of the regular inventory
    if tabData.descriptor == ITEMFILTERTYPE_QUEST then
        ZO_PlayerInventoryList:SetHidden(true)
        ZO_PlayerInventoryQuest:SetHidden(false)
        PlayerInventory.selectedTabType = INVENTORY_QUEST_ITEM
    end

    if tabData.inventoryType == INVENTORY_BACKPACK then
        ZO_PlayerInventoryList:SetHidden(false)
        ZO_PlayerInventoryQuest:SetHidden(true)
        PlayerInventory.selectedTabType = INVENTORY_BACKPACK
    end

    PlayerInventory:ChangeFilter(tabData)
end

--Search Processors

local function GetInventoryItemInformation(bagId, slotIndex)
    local name = GetItemName(bagId, slotIndex)
    name = name:lower()

    local _, _, _, _, _, equipType, itemStyle = GetItemInfo(bagId, slotIndex)

    return name, equipType, itemStyle
end

local EQUIP_TYPE_NAMES = {}
local ITEM_STYLE_NAME = {}

local function ProcessInventoryItem(stringSearch, data, searchTerm, cache)
    local name, equipType, itemStyle = stringSearch:GetFromCache(data, cache, GetInventoryItemInformation, data.bagId, data.slotIndex)

    if(zo_plainstrfind(name, searchTerm)) then
        return true
    end

    if(equipType ~= EQUIP_TYPE_INVALID) then
        local equipTypeName = EQUIP_TYPE_NAMES[equipType]
        if(not equipTypeName) then
            equipTypeName = GetString("SI_EQUIPTYPE", equipType):lower()
            EQUIP_TYPE_NAMES[equipType] = equipTypeName
        end
        if(zo_plainstrfind(equipTypeName, searchTerm)) then
            return true
        end
    end

    if(itemStyle ~= ITEMSTYLE_NONE) then
        local itemStyleName = ITEM_STYLE_NAME[itemStyle]
        if(not itemStyleName) then
            itemStyleName = GetString("SI_ITEMSTYLE", itemStyle):lower()
            ITEM_STYLE_NAME[itemStyle] = itemStyleName
        end
        if(zo_plainstrfind(itemStyleName, searchTerm)) then
            return true
        end
    end

    return false
end

local function GetQuestItemInformation(questIndex, stepIndex, conditionIndex)
    local _, _, name = GetQuestItemInfo(questIndex, stepIndex, conditionIndex)
    name = name:lower()
    return name
end

local function ProcessQuestItem(stringSearch, data, searchTerm, cache)
    local name = stringSearch:GetFromCache(data, cache, GetQuestItemInformation, data.questIndex, data.stepIndex, data.conditionIndex)
    return zo_plainstrfind(name, searchTerm)
end

local function GetQuestToolInformation(questIndex, toolIndex)
    local _, _, _, name = GetQuestToolInfo(questIndex, toolIndex)
    name = name:lower()
    return name
end

local function ProcessQuestTool(stringSearch, data, searchTerm, cache)
    local name = stringSearch:GetFromCache(data, cache, GetQuestToolInformation, data.questIndex, data.toolIndex)
    return zo_plainstrfind(name, searchTerm)
end

-- Item List Sort management
local sortKeys =
{
    slotIndex = { isNumeric = true },
    stackCount = { tiebreaker = "slotIndex", isNumeric = true },
    name = { tiebreaker = "stackCount" },
    quality = { tiebreaker = "name", isNumeric = true },
    stackSellPrice = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP, isNumeric = true },
    statusSortOrder = { tiebreaker = "age", isNumeric = true},
    age = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP, isNumeric = true},
    statValue = { tiebreaker = "name", isNumeric = true, tieBreakerSortOrder = ZO_SORT_ORDER_UP },
}

function ZO_Inventory_GetDefaultHeaderSortKeys()
    return sortKeys
end

local bankSortTypes =
{
    ZO_ComboBox:CreateItemEntry(GetString(SI_INVENTORY_SORT_TYPE_NAME), function() PlayerInventory:ChangeSort("name", INVENTORY_BANK) end),
    ZO_ComboBox:CreateItemEntry(GetString(SI_INVENTORY_SORT_TYPE_PRICE), function() PlayerInventory:ChangeSort("stackSellPrice", INVENTORY_BANK) end),
    -- NOTE: Bank cannot sort by age...items moved to the bank (or back again) do not have their age persisted yet.
}

local function InitializeHeaderSort(inventoryType, inventory, headerControl)
    local sortHeaders = ZO_SortHeaderGroup:New(headerControl, true)

    local function OnSortHeaderClicked(key, order)
        PlayerInventory:ChangeSort(key, inventoryType, order)
    end

    sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    sortHeaders:AddHeadersFromContainer()
    sortHeaders:SelectHeaderByKey(inventory.currentSortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

    inventory.sortHeaders = sortHeaders
end

-- Item List Display management

local INVENTORY_DATA_TYPE_BACKPACK = 1
local INVENTORY_DATA_TYPE_QUEST = 2

local function InitializeInventoryList(inventory)
    local listView = inventory.listView
    if listView then
        ZO_ScrollList_Initialize(listView)
        ZO_ScrollList_AddDataType(listView, inventory.listDataType, inventory.rowTemplate, 52, inventory.listSetupCallback, inventory.listHiddenCallback, nil, ZO_InventorySlot_OnPoolReset)
        ZO_ScrollList_AddResizeOnScreenResize(listView)
    end
end

local function InitializeInventoryFilters(inventory)
    if(inventory.tabFilters) then
        local menuBar = inventory.filterBar
        for _, data in ipairs(inventory.tabFilters) do
            local filterButton = ZO_MenuBar_AddButton(menuBar, data)

            data.control = filterButton
            ZO_AlphaAnimation:New(GetControl(filterButton, "Flash"))
        end
    end
end

local function OnInventoryItemRowHidden(rowControl, slot)
    slot.slotControl = nil
end

local function UpdateStatusControl(inventorySlot, slotData)
    local statusControl = GetControl(inventorySlot, "StatusTexture")

    statusControl:ClearIcons()

    if slotData.brandNew then
        statusControl:AddIcon(NEW_ICON_TEXTURE)
    end
    if slotData.stolen then
        statusControl:AddIcon(STOLEN_ICON_TEXTURE)
    end
    if slotData.isPlayerLocked then
        statusControl:AddIcon(ZO_KEYBOARD_LOCKED_ICON)
    end
    if slotData.isBoPTradeable then
        statusControl:AddIcon(ZO_TRADE_BOP_ICON)
    end
    if slotData.isGemmable then
        statusControl:AddIcon(ZO_Currency_GetPlatformCurrencyIcon(UI_ONLY_CURRENCY_CROWN_GEMS))
    end

    statusControl:Show()

    if slotData.age ~= 0 then
        slotData.clearAgeOnClose = true
    end
end

local function UpdateStatValueControl(inventorySlot, slot)
    local statControl = GetControl(inventorySlot, "StatValue")

    if(statControl) then
        -- NOT A HACK, stat values can be nil in certain cases...quest items have nil values.
        local showStatColumn = not slot.inventory.hiddenColumns["statValue"]
        statControl:SetText((showStatColumn and (slot.statValue ~= nil) and (slot.statValue > 0)) and tostring(slot.statValue) or "")
    end
end

ITEM_SLOT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

local function GetDefaultSlotSellValue(slot)
    return (FENCE_MANAGER and SYSTEMS:GetObject("fence"):IsLaundering()) and slot.stackLaunderPrice or slot.stackSellPrice
end

local function SetupInventoryItemRow(rowControl, slot, overrideOptions)
    local options = overrideOptions or ITEM_SLOT_CURRENCY_OPTIONS
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, slot.quality)
    local nameControl = GetControl(rowControl, "Name")
    nameControl:SetText(slot.name) -- already formatted
    nameControl:SetColor(r, g, b, 1)

    local itemValue 
    if type(options.overrideSellValue) == "function" then
        itemValue = options.overrideSellValue(slot)
    else
        itemValue = GetDefaultSlotSellValue(slot)
    end

    local sellPriceControl = GetControl(rowControl, "SellPrice")
    sellPriceControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl,
                                         CURT_MONEY,
                                         itemValue,
                                         options)

    local inventorySlot = GetControl(rowControl, "Button")
    ZO_Inventory_BindSlot(inventorySlot, slot.inventory.slotType, slot.slotIndex, slot.bagId)
    ZO_PlayerInventorySlot_SetupSlot(rowControl, slot.stackCount, slot.iconFile, slot.meetsUsageRequirement, slot.locked or IsUnitDead("player"))

    slot.slotControl = rowControl

    UpdateStatusControl(rowControl, slot)
    UpdateStatValueControl(rowControl, slot)
end

local function GetItemSlotSellValueWithBonus(slot)
    if FENCE_MANAGER and SYSTEMS:GetObject("fence"):IsSellingStolenItems() and FENCE_MANAGER:HasBonusToSellingStolenItems() then
        return GetItemSellValueWithBonuses(slot.bagId, slot.slotIndex) * slot.stackCount
    end

    return GetDefaultSlotSellValue(slot)
end

ITEM_BACKPACK_SLOT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
    color = ZO_SetupInventoryItemOptionsCurrencyColor,
    overrideSellValue = GetItemSlotSellValueWithBonus,
}

local function SetupBackpackInventoryItemRow(rowControl, slot)
    SetupInventoryItemRow(rowControl, slot, ITEM_BACKPACK_SLOT_CURRENCY_OPTIONS)
end

local function SetupQuestRow(rowControl, questItem)
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_QUEST_ITEM_NAME)
    local nameControl = GetControl(rowControl, "Name")
    nameControl:SetText(questItem.name) -- already formatted
    nameControl:SetColor(r, g, b, 1)

    GetControl(rowControl, "SellPrice"):SetHidden(true)

    local inventorySlot = GetControl(rowControl, "Button")
    ZO_InventorySlot_SetType(inventorySlot, SLOT_TYPE_QUEST_ITEM)

    questItem.slotControl = rowControl

    ZO_Inventory_SetupSlot(inventorySlot, questItem.stackCount, questItem.iconFile)
    ZO_Inventory_SetupQuestSlot(inventorySlot, questItem.questIndex, questItem.toolIndex, questItem.stepIndex, questItem.conditionIndex)

    UpdateStatusControl(rowControl, questItem)
    UpdateStatValueControl(rowControl, questItem)
end

local function CreateNewTabFilterData(filterType, inventoryType, normal, pressed, highlight, hiddenColumns, filterName, isHidden)
    local isHiddenTab = isHidden == true -- nil means don't hide

    local filterString = filterName
    if filterString == nil and type(filterType) ~= "function" then
        filterString = GetString("SI_ITEMFILTERTYPE", filterType)
    end

    local tabData = 
    {
        -- Custom data
        filterType = filterType,
        inventoryType = inventoryType,
        hiddenColumns = hiddenColumns,
        activeTabText = filterString,
        tooltipText = filterString,

        -- Menu bar data
        hidden = isHiddenTab,
        descriptor = filterType,
        normal = normal,
        pressed = pressed,
        highlight = highlight,
        callback = HandleTabSwitch,
    }

    return tabData
end

local function BaseInventoryFilter(currentFilter, slot)
    if(currentFilter ~= ITEMFILTERTYPE_JUNK and slot.isJunk) then return false end
    if(currentFilter == ITEMFILTERTYPE_JUNK and slot.isJunk) then return true end
    if(currentFilter == ITEMFILTERTYPE_ALL) then return true end

    for i = 1, #slot.filterData do
        if(slot.filterData[i] == currentFilter) then
            return true
        end
    end

    return false
end

local function TradingHouseFilter(slot)
    return not IsItemBound(slot.bagId, slot.slotIndex) and not IsItemBoPAndTradeable(slot.bagId, slot.slotIndex)
end

-------------------
--Inventory Manager
-------------------

ZO_InventoryManager = ZO_Object:Subclass()

function ZO_InventoryManager:New()
    local manager = ZO_Object.New(self)

    manager.selectedTabType = INVENTORY_BACKPACK

    local backpackSearch = ZO_StringSearch:New(CACHE_DATA)
    backpackSearch:AddProcessor(SEARCH_TYPE_INVENTORY, ProcessInventoryItem)

    local bankSearch = ZO_StringSearch:New(CACHE_DATA)
    bankSearch:AddProcessor(SEARCH_TYPE_INVENTORY, ProcessInventoryItem)

    local guildBankSearch = ZO_StringSearch:New(CACHE_DATA)
    guildBankSearch:AddProcessor(SEARCH_TYPE_INVENTORY, ProcessInventoryItem)

    local questItemSearch = ZO_StringSearch:New(CACHE_DATA)
    questItemSearch:AddProcessor(SEARCH_TYPE_QUEST_ITEM, ProcessQuestItem)
    questItemSearch:AddProcessor(SEARCH_TYPE_QUEST_TOOL, ProcessQuestTool)

    local craftBagSearch = ZO_StringSearch:New(CACHE_DATA)
    craftBagSearch:AddProcessor(SEARCH_TYPE_INVENTORY, ProcessInventoryItem)

    local typicalHiddenColumns =
    {
        ["statValue"] = true,
    }

    local questHiddenColumns =
    {
        ["statValue"] = true,
        ["statusSortOrder"] = true,
        ["stackSellPrice"] = true,
    }

    local gearHiddenColumns =
    {
        -- Don't hide anything!
    }

    local tradingHouseHiddenColumns =
    {
        ["statValue"] = true,
        ["statusSortOrder"] = true,
    }

    local HIDE_TAB = true
    -- Need to define these in reverse order than how you want to display them
    local backpackFilters =
    {
        CreateNewTabFilterData(ITEMFILTERTYPE_JUNK, INVENTORY_BACKPACK, "EsoUI/Art/Inventory/inventory_tabIcon_junk_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_junk_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_junk_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_QUEST, INVENTORY_QUEST_ITEM, "EsoUI/Art/Inventory/inventory_tabIcon_quest_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_quest_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_quest_over.dds", questHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_MISCELLANEOUS, INVENTORY_BACKPACK, "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_FURNISHING, INVENTORY_BACKPACK, "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CRAFTING, INVENTORY_BACKPACK, "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CONSUMABLE, INVENTORY_BACKPACK, "EsoUI/Art/Inventory/inventory_tabIcon_consumables_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ARMOR, INVENTORY_BACKPACK, "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_WEAPONS, INVENTORY_BACKPACK, "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ALL, INVENTORY_BACKPACK, "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds", typicalHiddenColumns),

        CreateNewTabFilterData(TradingHouseFilter, INVENTORY_BACKPACK, "", "", "", tradingHouseHiddenColumns, "", HIDE_TAB),
    }

    local bankFilters =
    {
        CreateNewTabFilterData(ITEMFILTERTYPE_JUNK, INVENTORY_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_junk_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_junk_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_junk_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_MISCELLANEOUS, INVENTORY_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_FURNISHING, INVENTORY_BANK, "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CRAFTING, INVENTORY_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CONSUMABLE, INVENTORY_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_consumables_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ARMOR, INVENTORY_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_WEAPONS, INVENTORY_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ALL, INVENTORY_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds", typicalHiddenColumns),
    }

    local guildBankFilters =
    {
        CreateNewTabFilterData(ITEMFILTERTYPE_JUNK, INVENTORY_GUILD_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_junk_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_junk_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_junk_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_MISCELLANEOUS, INVENTORY_GUILD_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_misc_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_FURNISHING, INVENTORY_GUILD_BANK, "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CRAFTING, INVENTORY_GUILD_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_crafting_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CONSUMABLE, INVENTORY_GUILD_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_consumables_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_consumables_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ARMOR, INVENTORY_GUILD_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_WEAPONS, INVENTORY_GUILD_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", gearHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ALL, INVENTORY_GUILD_BANK, "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds", typicalHiddenColumns),
    }

    local craftBagFilters =
    {
        CreateNewTabFilterData(ITEMFILTERTYPE_TRAIT_ITEMS, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_STYLE_MATERIALS, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_styleMaterial_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_styleMaterial_down.dds", "EsoUI/Art/Inventoryinventory_tabIcon_Craftbag_styleMaterial_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_PROVISIONING, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ENCHANTING, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ALCHEMY, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_alchemy_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_alchemy_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_alchemy_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_WOODWORKING, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_woodworking_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_woodworking_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_woodworking_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_CLOTHING, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_clothing_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_clothing_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_clothing_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_BLACKSMITHING, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_blacksmithing_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_blacksmithing_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_blacksmithing_over.dds", typicalHiddenColumns),
        CreateNewTabFilterData(ITEMFILTERTYPE_ALL, INVENTORY_CRAFT_BAG, "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_all_over.dds", typicalHiddenColumns),
    }

    local function BackpackAltFreeSlotType()
        if manager:IsBanking() then 
            return INVENTORY_BANK 
        elseif manager:IsGuildBanking() then
            return INVENTORY_GUILD_BANK
        else
            return nil  --hide label
        end
    end

    local inventories =
    {
        [INVENTORY_BACKPACK] =
        {
            slots = {},
            stringSearch = backpackSearch,
            searchBox = ZO_PlayerInventorySearchBox,
            slotType = SLOT_TYPE_ITEM,
            backingBag = BAG_BACKPACK,
            listView = ZO_PlayerInventoryList,
            listDataType = INVENTORY_DATA_TYPE_BACKPACK,
            listSetupCallback = SetupBackpackInventoryItemRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            freeSlotsLabel = ZO_PlayerInventoryInfoBarFreeSlots,
            altFreeSlotsLabel = ZO_PlayerInventoryInfoBarAltFreeSlots,
            freeSlotType = INVENTORY_BACKPACK,
            altFreeSlotType = BackpackAltFreeSlotType,
            freeSlotsStringId = SI_INVENTORY_BACKPACK_REMAINING_SPACES,
            freeSlotsFullStringId = SI_INVENTORY_BACKPACK_COMPLETELY_FULL,
            currentSortKey = "statusSortOrder",
            currentSortOrder = ZO_SORT_ORDER_DOWN,
            currentFilter = ITEMFILTERTYPE_ALL,
            tabFilters = backpackFilters,
            filterBar = ZO_PlayerInventoryTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            activeTab = ZO_PlayerInventoryTabsActive,
            inventoryEmptyStringId = SI_INVENTORY_ERROR_INVENTORY_EMPTY,
        },
        [INVENTORY_QUEST_ITEM] =
        {
            slots = {},
            stringSearch = questItemSearch,
            searchBox = ZO_PlayerInventorySearchBox,
            slotType = SLOT_TYPE_QUEST_ITEM,
            listView = ZO_PlayerInventoryQuest,
            listDataType = INVENTORY_DATA_TYPE_QUEST,
            listSetupCallback = SetupQuestRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            currentFilter = ITEMFILTERTYPE_ALL,
            rowTemplate = "ZO_PlayerInventorySlot",
            hiddenColumns = questHiddenColumns,
        },
        [INVENTORY_BANK] =
        {
            slots = {},
            stringSearch = bankSearch,
            searchBox = ZO_PlayerBankSearchBox,
            slotType = SLOT_TYPE_BANK_ITEM,
            backingBag = BAG_BANK,
            listView = ZO_PlayerBankBackpack,
            listDataType = INVENTORY_DATA_TYPE_BACKPACK,
            listSetupCallback = SetupInventoryItemRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            freeSlotsLabel = ZO_PlayerBankInfoBarFreeSlots,
            altFreeSlotsLabel = ZO_PlayerBankInfoBarAltFreeSlots,
            freeSlotType = INVENTORY_BACKPACK,
            altFreeSlotType = INVENTORY_BANK,
            freeSlotsStringId = SI_INVENTORY_BANK_REMAINING_SPACES,
            freeSlotsFullStringId = SI_INVENTORY_BANK_COMPLETELY_FULL,
            currentSortKey = "name",
            currentSortOrder = ZO_SORT_ORDER_UP,
            currentFilter = ITEMFILTERTYPE_ALL,
            tabFilters = bankFilters,
            filterBar = ZO_PlayerBankTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            activeTab = ZO_PlayerBankTabsActive,
        },
        [INVENTORY_GUILD_BANK] =
        {
            slots = {},
            stringSearch = guildBankSearch,
            searchBox = ZO_GuildBankSearchBox,
            slotType = SLOT_TYPE_GUILD_BANK_ITEM,
            backingBag = BAG_GUILDBANK,
            listView = ZO_GuildBankBackpack,
            listDataType = INVENTORY_DATA_TYPE_BACKPACK,
            listSetupCallback = SetupInventoryItemRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            freeSlotsLabel = ZO_GuildBankInfoBarFreeSlots,
            altFreeSlotsLabel = ZO_GuildBankInfoBarAltFreeSlots,
            freeSlotType = INVENTORY_BACKPACK,
            altFreeSlotType = INVENTORY_GUILD_BANK,
            freeSlotsStringId = SI_INVENTORY_BANK_REMAINING_SPACES,
            freeSlotsFullStringId = SI_INVENTORY_BANK_COMPLETELY_FULL,
            currentSortKey = "name",
            currentSortOrder = ZO_SORT_ORDER_UP,
            currentFilter = ITEMFILTERTYPE_ALL,
            tabFilters = guildBankFilters,
            filterBar = ZO_GuildBankTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            activeTab = ZO_GuildBankTabsActive,
        },
        [INVENTORY_CRAFT_BAG] =
        {
            slots = {},
            stringSearch = craftBagSearch,
            searchBox = ZO_CraftBagSearchBox,
            slotType = SLOT_TYPE_CRAFT_BAG_ITEM,
            backingBag = BAG_VIRTUAL,
            listView = ZO_CraftBagList,
            listDataType = INVENTORY_DATA_TYPE_BACKPACK,
            listSetupCallback = SetupBackpackInventoryItemRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            currentSortKey = "statusSortOrder",
            currentSortOrder = ZO_SORT_ORDER_DOWN,
            currentFilter = ITEMFILTERTYPE_ALL,
            tabFilters = craftBagFilters,
            filterBar = ZO_CraftBagTabs,
            rowTemplate = "ZO_CraftBagSlot",
            activeTab = ZO_CraftBagTabsActive,
            inventoryEmptyStringId = SI_INVENTORY_ERROR_CRAFT_BAG_EMPTY,
        },
    }

    self.isListDirty = {}

    InitializeHeaderSort(INVENTORY_BACKPACK, inventories[INVENTORY_BACKPACK], ZO_PlayerInventorySortBy)
    InitializeHeaderSort(INVENTORY_BANK, inventories[INVENTORY_BANK], ZO_PlayerBankSortBy)
    InitializeHeaderSort(INVENTORY_GUILD_BANK, inventories[INVENTORY_GUILD_BANK], ZO_GuildBankSortBy)
    InitializeHeaderSort(INVENTORY_CRAFT_BAG, inventories[INVENTORY_CRAFT_BAG], ZO_CraftBagSortBy)

    manager.inventories = inventories
    manager.searchToInventoryType = {}
    manager.bagToInventoryType =
    {
        [BAG_BACKPACK] = INVENTORY_BACKPACK,
        [BAG_BANK] = INVENTORY_BANK,
        [BAG_GUILDBANK] = INVENTORY_GUILD_BANK,
        [BAG_VIRTUAL] = INVENTORY_CRAFT_BAG,
    }

    for inventoryType, inventoryData in pairs(manager.inventories) do
        InitializeInventoryList(inventoryData)
        InitializeInventoryFilters(inventoryData)
        manager.searchToInventoryType[inventoryData.stringSearch] = inventoryType
    end

    INVENTORY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_PlayerInventory)

    INVENTORY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWING) then
            local UPDATE_EVEN_IF_HIDDEN = true
            if manager.isListDirty[INVENTORY_BACKPACK] or manager.isListDirty[INVENTORY_QUEST_ITEM] then
                manager:UpdateList(INVENTORY_BACKPACK, UPDATE_EVEN_IF_HIDDEN)
                manager:UpdateList(INVENTORY_QUEST_ITEM, UPDATE_EVEN_IF_HIDDEN)
            end
            manager:RefreshMoney()
            manager:UpdateApparelSection()
            --Reseting the comparison stats here since its too later when the window is already hidden.
            ZO_CharacterWindowStats_HideComparisonValues()
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            ZO_PlayerInventory_EndSearch(ZO_PlayerInventorySearchBox)
            manager:ClearNewStatusOnItemsThePlayerHasSeen(INVENTORY_BACKPACK)
        end
    end)

    SHARED_INVENTORY:RegisterCallback("SlotAdded", function(bagId, slotIndex, newSlotData) 
        local inventory = manager.bagToInventoryType[bagId]
        if inventory then
            manager:OnInventoryItemAdded(inventory, bagId, slotIndex, newSlotData) 
        end
    end)

    SHARED_INVENTORY:RegisterCallback("SlotRemoved", function(bagId, slotIndex, oldSlotData) 
        local inventory = manager.bagToInventoryType[bagId]
        if inventory then
            manager:OnInventoryItemRemoved(inventory, bagId, slotIndex, oldSlotData)
        end
    end)

    self.capacityAnnouncementsInfo = {}

    EVENT_MANAGER:RegisterForEvent("ZO_InventoryManager", EVENT_VISUAL_LAYER_CHANGED, function() self:UpdateApparelSection() end)

    return manager
end


--General
---------

function ZO_InventoryManager:ChangeSort(newSortKey, inventoryType, newSortOrder)
    self.inventories[inventoryType].currentSortKey = newSortKey
    self.inventories[inventoryType].currentSortOrder = newSortOrder

    self:ApplySort(inventoryType)

    if inventoryType == INVENTORY_BACKPACK then
        self.inventories[INVENTORY_QUEST_ITEM].currentSortKey = newSortKey
        self.inventories[INVENTORY_QUEST_ITEM].currentSortOrder = newSortOrder
        self:ApplySort(INVENTORY_QUEST_ITEM)
    end
end

local function ForceSortDataOnInventory(inventory, sortKey, sortOrder)
    inventory.currentSortKey = sortKey
    inventory.currentSortOrder = sortOrder
end

function ZO_InventoryManager:ApplySort(inventoryType)
    local inventory
    if inventoryType == INVENTORY_BANK then
        inventory = self.inventories[INVENTORY_BANK]
    elseif inventoryType == INVENTORY_GUILD_BANK then
        inventory = self.inventories[INVENTORY_GUILD_BANK]
    elseif inventoryType == INVENTORY_CRAFT_BAG then
        inventory = self.inventories[INVENTORY_CRAFT_BAG]
    else
        -- Use normal inventory by default (instead of the quest item inventory for example)
        inventory = self.inventories[self.selectedTabType]
    end

    local list = inventory.listView
    local scrollData = ZO_ScrollList_GetDataList(list)

    if inventory.sortFn == nil then
        inventory.sortFn =  function(entry1, entry2)
                                return ZO_TableOrderingFunction(entry1.data, entry2.data, inventory.currentSortKey, sortKeys, inventory.currentSortOrder)
                            end
    end

    table.sort(scrollData, inventory.sortFn)
    ZO_ScrollList_Commit(list)
end

-- Utility function to basically remap quest_item inventory to the backpack inventory because the backpack inventory
-- is what stores all the display-type data.
function ZO_InventoryManager:GetDisplayInventoryTable(inventoryType)
    inventoryType = (inventoryType == INVENTORY_QUEST_ITEM) and INVENTORY_BACKPACK or inventoryType
    return self.inventories[inventoryType]
end

function ZO_InventoryManager:GetTabFilterInfo(inventoryType, tabControl)
    local inventory = self:GetDisplayInventoryTable(inventoryType)
    local filterData = inventory.tabFilters[tabControl] or tabControl -- the or tabControl is for the new style, because the data table is just passed in here

    return filterData.filterType, filterData.activeTabText, filterData.hiddenColumns
end

-- Might need to make this generic...store in filter data?  Probably need a massive refactoring of how to determine which
-- columns are shown and what they are called when they're shown....
local filterTypeToValueColumnName =
{
    [ITEMFILTERTYPE_ARMOR] = SI_INVENTORY_SORT_TYPE_ARMOR,
    [ITEMFILTERTYPE_WEAPONS] = SI_INVENTORY_SORT_TYPE_POWER,
}

function ZO_InventoryManager:UpdateColumnText(inventory)
    local sortHeaders = inventory.sortHeaders
    if(sortHeaders) then
        sortHeaders:SetHeaderNameForKey("statValue", GetString(filterTypeToValueColumnName[inventory.currentFilter]))
    end
end

function ZO_InventoryManager:ChangeFilter(filterTab)
    local inventoryType = filterTab.inventoryType
    local inventory = self.inventories[inventoryType]

    local activeTabText
    inventory.currentFilter, activeTabText, inventory.hiddenColumns = self:GetTabFilterInfo(inventoryType, filterTab)

    local displayInventory = self:GetDisplayInventoryTable(inventoryType)
    local activeTabControl = displayInventory.activeTab
    if(activeTabControl) then
        activeTabControl:SetText(activeTabText)
    end

    self:UpdateColumnText(displayInventory)

    -- Manage hiding columns that show/hide depending on the current filter.  If the sort was on a column that becomes hidden
    -- then the sort needs to pick a new column.
    local sortHeaders = displayInventory.sortHeaders
    if sortHeaders then
        sortHeaders:SetHeadersHiddenFromKeyList(inventory.hiddenColumns, true)

        if inventory.hiddenColumns[inventory.currentSortKey] then
            -- User wanted to sort by a column that's gone!
            -- Fallback to name...the default sort is "statusSortOrder", but there are filters that hide that one, so "name" is the
            -- only safe bet for now...
            sortHeaders:SelectHeaderByKey("name", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

            -- Switch both inventory and displayInventory to the fallback
            ForceSortDataOnInventory(inventory, "name", ZO_SORT_ORDER_UP)
            ForceSortDataOnInventory(displayInventory, "name", ZO_SORT_ORDER_UP)
        end
    end

    ZO_ScrollList_ResetToTop(inventory.listView)
    self:UpdateList(inventoryType)

    if inventoryType == INVENTORY_BACKPACK and INVENTORY_MENU_BAR then
        INVENTORY_MENU_BAR:UpdateInventoryKeybinds()
    end

    local isEmptyList = not ZO_ScrollList_HasVisibleData(inventory.listView)
    self:UpdateEmptyBagLabel(inventoryType, isEmptyList)
end

function ZO_InventoryManager:SlotForInventoryControl(inventorySlotControl)
    local slotIndex = inventorySlotControl.slotIndex
    if slotIndex then
        local slotType = ZO_InventorySlot_GetType(inventorySlotControl)
        if slotType == SLOT_TYPE_ITEM or slotType == SLOT_TYPE_GAMEPAD_INVENTORY_ITEM then
            return self.inventories[INVENTORY_BACKPACK].slots[slotIndex]
        elseif slotType == SLOT_TYPE_BANK_ITEM then
            return self.inventories[INVENTORY_BANK].slots[slotIndex]
        elseif slotType == SLOT_TYPE_CRAFT_BAG_ITEM then
            return self.inventories[INVENTORY_CRAFT_BAG].slots[slotIndex]
        end
    end
end


--Bag Window
------------

function ZO_InventoryManager:UpdateSortOrderButtonTextures(sortButton, inventoryType)
    local inventory = self.inventories[inventoryType]
    if inventory.currentSortOrder == ZO_SORT_ORDER_UP then
        sortButton:SetNormalTexture("EsoUI/Art/WorldMap/mapNav_upArrow_up.dds")
        sortButton:SetMouseOverTexture("EsoUI/Art/Buttons/ESO_buttonLarge_mouseOver.dds")
        sortButton:SetPressedTexture("EsoUI/Art/WorldMap/mapNav_upArrow_down.dds")
    else
        sortButton:SetNormalTexture("EsoUI/Art/WorldMap/mapNav_downArrow_up.dds")
        sortButton:SetMouseOverTexture("EsoUI/Art/Buttons/ESO_buttonLarge_mouseOver.dds")
        sortButton:SetPressedTexture("EsoUI/Art/WorldMap/mapNav_downArrow_down.dds")
    end
end

function ZO_InventoryManager:ToggleSortOrder(sortButton, inventoryType)
    local inventory = self.inventories[inventoryType]
    inventory.currentSortOrder = not inventory.currentSortOrder

    if inventoryType == INVENTORY_BACKPACK then
        self.inventories[INVENTORY_QUEST_ITEM].currentSortOrder = inventory.currentSortOrder
    end

    self:UpdateSortOrderButtonTextures(sortButton, inventoryType)
    self:ApplySort(inventoryType)
end

function ZO_InventoryManager:ShowToggleSortOrderTooltip(anchorControl, inventoryType)
    InitializeTooltip(InformationTooltip, anchorControl, TOPRIGHT, 0, 0)

    -- Show the opposite string of the current sort order because that's what will happen when the button is clicked
    if(self.inventories[inventoryType].currentSortOrder == ZO_SORT_ORDER_UP) then
        SetTooltipText(InformationTooltip, GetString(SI_INVENTORY_SORT_DESCENDING_TOOLTIP))
    else
        SetTooltipText(InformationTooltip, GetString(SI_INVENTORY_SORT_ASCENDING_TOOLTIP))
    end
end

function ZO_InventoryManager:HideToggleSortOrderTooltip()
    ClearTooltip(InformationTooltip)
end

function ZO_InventoryManager:RefreshMoney()
    if self:IsBanking() then
        self:RefreshUpgradePossible()
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerBankInfoBarMoney, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerInventoryInfoBarAltMoney, CURT_MONEY, GetBankedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_BANKED_CURRENCY_OPTIONS)
    elseif self:IsGuildBanking() then
        ZO_CurrencyControl_SetSimpleCurrency(ZO_GuildBankInfoBarMoney, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)
    end
    ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerInventoryInfoBarMoney, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)
end

function ZO_InventoryManager:RefreshTelvarStones()
    if self:IsBanking() then
        self:RefreshUpgradePossible()
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerBankInfoBarTelvarStones, CURT_TELVAR_STONES, GetCarriedCurrencyAmount(CURT_TELVAR_STONES), ZO_KEYBOARD_CARRIED_TELVAR_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerInventoryInfoBarAltTelvarStones, CURT_TELVAR_STONES, GetBankedCurrencyAmount(CURT_TELVAR_STONES), ZO_KEYBOARD_BANKED_TELVAR_OPTIONS)
    end
    ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerInventoryInfoBarTelvarStones, CURT_TELVAR_STONES, GetCarriedCurrencyAmount(CURT_TELVAR_STONES), ZO_KEYBOARD_CARRIED_TELVAR_OPTIONS)
end

function ZO_InventoryManager:UpdateFreeSlots(inventoryType)
    local inventory = self.inventories[inventoryType]
    local freeSlotType
    local altFreeSlotType

    if (type(inventory.freeSlotType) == "function") then
        freeSlotType = inventory.freeSlotType()
    else
        freeSlotType = inventory.freeSlotType
    end

    if (type(inventory.altFreeSlotType) == "function") then
        altFreeSlotType = inventory.altFreeSlotType()
    else
        altFreeSlotType = inventory.altFreeSlotType
    end

    if(inventory.freeSlotsLabel) then
        local freeSlotTypeInventory = self.inventories[freeSlotType]
        local numUsedSlots, numSlots = self:GetNumSlots(freeSlotType)
        if(numUsedSlots < numSlots) then
            inventory.freeSlotsLabel:SetText(zo_strformat(freeSlotTypeInventory.freeSlotsStringId, numUsedSlots, numSlots))
        else
            inventory.freeSlotsLabel:SetText(zo_strformat(freeSlotTypeInventory.freeSlotsFullStringId, numUsedSlots, numSlots))
        end
    end

    if(inventory.altFreeSlotsLabel and altFreeSlotType) then
        local numUsedSlots, numSlots = self:GetNumSlots(altFreeSlotType)
        local altFreeSlotInventory = self.inventories[altFreeSlotType] --grab the alternateInventory to use it's string id's
        if(numUsedSlots < numSlots) then
            inventory.altFreeSlotsLabel:SetText(zo_strformat(altFreeSlotInventory.freeSlotsStringId, numUsedSlots, numSlots))
        else
            inventory.altFreeSlotsLabel:SetText(zo_strformat(altFreeSlotInventory.freeSlotsFullStringId, numUsedSlots, numSlots))
        end
    end
end

function ZO_InventoryManager:SetupInitialFilter()
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_BACKPACK].filterBar, ITEMFILTERTYPE_ALL)
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_BANK].filterBar, ITEMFILTERTYPE_ALL)
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_GUILD_BANK].filterBar, ITEMFILTERTYPE_ALL)
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_CRAFT_BAG].filterBar, ITEMFILTERTYPE_ALL)
end

function ZO_InventoryManager:SetTradingHouseModeEnabled(enabled)
    local inventory = self.inventories[INVENTORY_BACKPACK]

    if enabled then
        inventory.previousFilter = inventory.currentFilter
        inventory.currentFilter = TradingHouseFilter
    else
        inventory.currentFilter = inventory.previousFilter or ITEMFILTERTYPE_ALL
        inventory.previousFilter = nil
    end

    ZO_PlayerInventorySearchBox:SetHidden(not enabled)
    ZO_PlayerInventoryTabs:SetHidden(enabled)
    ZO_MenuBar_SelectDescriptor(inventory.filterBar, inventory.currentFilter)
end

function ZO_InventoryManager:PlayItemAddedAlert(filterData, tabFilters)
    if(self.suppressItemAddedAlert) then return end

    for filterKey, tabFilter in pairs(tabFilters) do
        for filterIndex = 1, #filterData do
            if(filterData[filterIndex] == tabFilter.filterType or tabFilter.filterType == ITEMFILTERTYPE_ALL) then
                local anim = ZO_AlphaAnimation_GetAnimation(GetControl(tabFilter.control, "Flash"))
                if(not anim:IsPlaying()) then
                    anim:PingPong(0, .5, 700, 11)
                end
                break
            end
        end
    end
end

function ZO_InventoryManager:UpdateApparelSection()
	if ZO_CharacterApparelHidden then
		ZO_CharacterApparelHidden:SetHidden(not IsEquipSlotVisualCategoryHidden(EQUIP_SLOT_VISUAL_CATEGORY_APPAREL))
	end
end

--Inventory Item
----------------

function ZO_InventoryManager:AddInventoryItem(inventoryType, slotIndex)
    local inventory = self.inventories[inventoryType]
    local bagId = inventory.backingBag

    inventory.slots[slotIndex] = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
end

function ZO_InventoryManager:UpdateNewStatus(inventoryType, slotIndex)
    local inventory = self.inventories[inventoryType]
    -- might not have the slot data yet depending on who is calling this and when, this will ensure we have the correct data
    -- if the slot data was already created this will essentially be a no-op (some table lookups)
    self:AddInventoryItem(inventoryType, slotIndex)
    local slot = inventory.slots[slotIndex]
    if slot and slot.age ~= 0 then
        slot.clearAgeOnClose = true
    end
end

function ZO_InventoryManager:GetNumSlots(inventoryType)
    local inventory = self.inventories[inventoryType]
    return GetNumBagUsedSlots(inventory.backingBag), GetBagSize(inventory.backingBag)
end

function ZO_InventoryManager:OnInventoryItemRemoved(inventoryType, bagId, slotIndex, oldSlotData)
    local inventory = self.inventories[inventoryType]

    if(oldSlotData) then
        inventory.stringSearch:Remove(oldSlotData.searchData)
    end
end

function ZO_InventoryManager:OnInventoryItemAdded(inventoryType, bagId, slotIndex, newSlotData)
    local inventory = self.inventories[inventoryType]
    newSlotData.searchData = {type = SEARCH_TYPE_INVENTORY, bagId = bagId, slotIndex = slotIndex}

    newSlotData.inventory = inventory

    inventory.stringSearch:Insert(newSlotData.searchData)

    -- play a brief flash animation on all the filter tabs that match this item's filterTypes
    if newSlotData.brandNew then
        self:PlayItemAddedAlert(newSlotData.filterData, inventory.tabFilters)
    end
end

function ZO_InventoryManager:DoesBagHaveEmptySlot(bagId)
    local inventoryType = self.bagToInventoryType[bagId]
    if inventoryType then
        local numUsedSlots, numSlots = self:GetNumSlots(inventoryType)

        return numUsedSlots < numSlots
    end
    return false
end

do
    local function HasAnyQuickSlottableItems(slots)
        for slotIndex, slotData in pairs(slots) do
            if slotData.filterData then
                for i = 1, #slotData.filterData do
                    if slotData.filterData[i] == ITEMFILTERTYPE_QUICKSLOT then
                        return true
                    end
                end
            end
        end
        return false
    end

    function ZO_InventoryManager:HasAnyQuickSlottableItems(inventoryType)
        local inventory = self.inventories[inventoryType]
        if inventory.hasAnyQuickSlottableItems == nil then
            inventory.hasAnyQuickSlottableItems = HasAnyQuickSlottableItems(inventory.slots)
        end
        return inventory.hasAnyQuickSlottableItems
    end
end

function ZO_InventoryManager:ShouldAddSlotToList(inventory, slot)
    if(not slot or slot.stackCount <= 0) then return false end

    if(not inventory.stringSearch:IsMatch(self.cachedSearchText, slot.searchData)) then return false end

    local currentFilter = inventory.currentFilter
    local additionalFilterPasses = true
    local additionalFilter = inventory.additionalFilter

    if(type(additionalFilter) == "function") then
        additionalFilterPasses = additionalFilter(slot)
    end

    if(type(currentFilter) ~= "function") then
        return additionalFilterPasses and BaseInventoryFilter(currentFilter, slot)
    else
        return additionalFilterPasses and currentFilter(slot)
    end

    return false
end

function ZO_InventoryManager:UpdateList(inventoryType, updateEvenIfHidden)
    local inventory = self.inventories[inventoryType]
    local list = inventory.listView
    if (list and not list:IsHidden()) or updateEvenIfHidden then
        local scrollData = ZO_ScrollList_GetDataList(list)
        ZO_ScrollList_Clear(list)

        -- TODO: possibly change the quest item implementation to just be a list of slots instead of being indexed by questIndex/slot
        -- For now just write two different iteration functions for quest/real inventories.

        self.cachedSearchText = inventory.searchBox:GetText()

        if inventoryType == INVENTORY_QUEST_ITEM then
            local questItems = inventory.slots
            for questIndex, questItemTable in pairs(questItems) do
                for questItemIndex = 1, #questItemTable do
                    local slotData = questItemTable[questItemIndex]

                    if(self:ShouldAddSlotToList(inventory, slotData)) then
                        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(inventory.listDataType, slotData)
                    end
                end
            end
        else
            local slots = inventory.slots
            for slotIndex, slotData in pairs(slots) do
                if self:ShouldAddSlotToList(inventory, slotData) then
                    scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(inventory.listDataType, slotData)
                end
            end
        end

        self.cachedSearchText = nil

        self:ApplySort(inventoryType)

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.bankWithdrawTabKeybindButtonGroup)

        local isEmptyList = not ZO_ScrollList_HasVisibleData(list)
        if inventory.sortHeaders then
            inventory.sortHeaders.headerContainer:SetHidden(isEmptyList)
        end
        self:UpdateEmptyBagLabel(inventoryType, isEmptyList)

        self.isListDirty[inventoryType] = false      
    else
        self.isListDirty[inventoryType] = true
    end
end

function ZO_InventoryManager:RefreshAllInventorySlots(inventoryType)
    local inventory = self.inventories[inventoryType]

    --Reset
    inventory.slots = {}
    inventory.hasAnyQuickSlottableItems = nil

    local search = inventory.stringSearch
    if search then
        search:RemoveAll()
    end

    self.suppressItemAddedAlert = true

    local bagId = inventory.backingBag

    --Add items
    local slotIndex = ZO_GetNextBagSlotIndex(bagId)
    while slotIndex do
        self:AddInventoryItem(inventoryType, slotIndex)
        slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
    end

    if inventoryType == INVENTORY_BACKPACK then
        CALLBACK_MANAGER:FireCallbacks("BackpackFullUpdate")
    end

    self:LayoutInventoryItems(inventoryType)

    self.suppressItemAddedAlert = nil
end

function ZO_InventoryManager:RefreshInventorySlot(inventoryType, slotIndex)
    local inventory = self.inventories[inventoryType]
    inventory.hasAnyQuickSlottableItems = nil
    self:AddInventoryItem(inventoryType, slotIndex)

    if inventoryType == INVENTORY_BACKPACK then
        CALLBACK_MANAGER:FireCallbacks("BackpackSlotUpdate", slotIndex)
    end

    -- Rebuild the entire list, refilter, and resort every time a single item is updated...sadness.
    self:LayoutInventoryItems(inventoryType)

    local slot = inventory.slots[slotIndex]

    if slot and slot.slotControl then
        CALLBACK_MANAGER:FireCallbacks("InventorySlotUpdate", GetControl(slot.slotControl, "Button"))
    end
end

function ZO_InventoryManager:LayoutInventoryItems(inventoryType)
    self:UpdateList(inventoryType)
    self:UpdateFreeSlots(inventoryType)
end

function ZO_InventoryManager:RefreshAllInventoryOverlays(inventoryType)
    local numSlots = GetBagSize(self.inventories[inventoryType].backingBag)
    for slotIndex = 0, numSlots - 1 do
        self:RefreshInventorySlotOverlay(inventoryType, slotIndex)
    end
end

do
    local function ShouldClearAgeOnClose(slot, inventoryManager)
        if slot and slot.clearAgeOnClose then
            local layout = inventoryManager.appliedLayout
            if layout and layout.waitUntilInventoryOpensToClearNewStatus then
                return false
            end

            return true
        end

        return false
    end

    local function TryClearNewStatus(inventory, slotIndex, inventoryManager)
        local slot = inventory.slots[slotIndex]
        if ShouldClearAgeOnClose(slot, inventoryManager) then
            slot.clearAgeOnClose = nil
            SHARED_INVENTORY:ClearNewStatus(inventory.backingBag, slotIndex)
        end
    end

    function ZO_InventoryManager:ClearNewStatusOnItemsThePlayerHasSeen(inventoryType)
        local inventory = self.inventories[inventoryType]
        local bagId = inventory.backingBag

        local slotIndex = ZO_GetNextBagSlotIndex(bagId)
        while slotIndex do
            TryClearNewStatus(inventory, slotIndex, self)
            slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
        end

        self:ApplySort(inventoryType)

        if inventory.listView then
            ZO_ScrollList_RefreshVisible(inventory.listView, slot, UpdateStatusControl)
        end

        if MAIN_MENU_KEYBOARD then
            MAIN_MENU_KEYBOARD:RefreshCategoryBar()
        end
    end
end

function ZO_InventoryManager:RefreshInventorySlotLocked(inventoryType, slotIndex, locked)
    local inventory = self.inventories[inventoryType]
    local slot = inventory.slots[slotIndex]

    if(slot and slot.locked ~= locked) then
        slot.locked = locked
        if(inventory.listView and slot.slotControl) then
            ZO_PlayerInventorySlot_SetupUsableAndLockedColor(slot.slotControl, slot.meetsUsageRequirement, slot.locked)
            CALLBACK_MANAGER:FireCallbacks("InventorySlotUpdate", button)
        end
    end
end

function ZO_InventoryManager:RefreshInventorySlotOverlay(inventoryType, slotIndex)
    local inventory = self.inventories[inventoryType]
    local slot = inventory.slots[slotIndex]
    if slot then
        local _, _, _, meetsUsageRequirement, _ = GetItemInfo(inventory.backingBag, slotIndex)
        local isLocalPlayerDead = IsUnitDead("player")
        local isLocked = slot.locked or isLocalPlayerDead

        if meetsUsageRequirement ~= slot.meetsUsageRequirement or isLocalPlayerDead ~= self.itemsLockedDueToDeath then
            slot.meetsUsageRequirement = meetsUsageRequirement
            if slot.slotControl then
                ZO_PlayerInventorySlot_SetupUsableAndLockedColor(slot.slotControl, slot.meetsUsageRequirement, isLocked)
                CALLBACK_MANAGER:FireCallbacks("InventorySlotUpdate", button)
            end
        end
    end
end

function ZO_InventoryManager:UpdateItemCooldowns(inventoryType)
    local inventory = self.inventories[inventoryType]
    if(inventory.listView) then
        ZO_ScrollList_RefreshVisible(inventory.listView, nil, ZO_InventorySlot_UpdateCooldowns)
    end
end

function ZO_InventoryManager:IsSlotOccupied(bagId, slotIndex)
    local inventoryType = self.bagToInventoryType[bagId]
    local slot = self.inventories[inventoryType].slots[slotIndex]

    return ((slot ~= nil) and (slot.stackCount > 0))
end

do
    local function UpdateItemTable(bagId, slotIndex, predicate, dataTable)
        if not predicate or predicate(bagId, slotIndex) then
            local _, stackCount = GetItemInfo(bagId, slotIndex)
            if not dataTable then
                return { bag = bagId, index = slotIndex, stack = stackCount }
            else
                dataTable.stack = dataTable.stack + stackCount
            end
        end
        return dataTable
    end

    --where ... are inventory types
    function ZO_InventoryManager:GenerateVirtualStackedItem(predicate, specificItemInstanceId, ...)
        local data
        for i = 1, select("#", ...) do
            local inventoryType = select(i, ...)
            local inventory = self.inventories[inventoryType]
            local bagId = inventory.backingBag

            local slotIndex = ZO_GetNextBagSlotIndex(bagId)
            while slotIndex do
                local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
                if itemInstanceId == specificItemInstanceId then
                    data = UpdateItemTable(bagId, slotIndex, predicate, data)
                end
                slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
            end
        end
        return data
    end

    function ZO_InventoryManager:GenerateListOfVirtualStackedItems(inventoryType, predicate, itemIds)
        local inventory = self.inventories[inventoryType]
        local bagId = inventory.backingBag

        itemIds = itemIds or {}

        local slotIndex = ZO_GetNextBagSlotIndex(bagId)
        local itemData
        while slotIndex do
            local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
            if itemInstanceId then
                itemData = itemIds[itemInstanceId]
                itemIds[itemInstanceId] = UpdateItemTable(bagId, slotIndex, predicate, itemData)
            end
            slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
        end

        return itemIds
    end
end

--Backpack
----------

function ZO_InventoryManager:GetNumBackpackSlots()
    local inventory = self.inventories[INVENTORY_BACKPACK]
    return GetBagSize(inventory.backingBag)
end

function ZO_InventoryManager:GetBackpackItem(slotIndex)
    local inventory = self.inventories[INVENTORY_BACKPACK]
    return inventory.slots[slotIndex]
end

function ZO_InventoryManager:IsShowingBackpack()
    return not ZO_PlayerInventory:IsHidden()
end

function ZO_InventoryManager:ApplyBackpackLayout(layoutData)
    if(layoutData == self.appliedLayout and not layoutData.alwaysReapplyLayout) then
        return
    end
    
    self.appliedLayout = layoutData

    self:ApplySharedBagLayout(ZO_PlayerInventory, layoutData)
    self:ApplySharedBagLayout(ZO_CraftBag, layoutData)

    local inventory = self.inventories[INVENTORY_BACKPACK]
    inventory.additionalFilter = layoutData.additionalFilter
    local menuBar = inventory.filterBar
    ZO_MenuBar_ClearButtons(menuBar)
    for _, filterData in ipairs(inventory.tabFilters) do
        if(not layoutData.hiddenFilters or not layoutData.hiddenFilters[filterData.filterType]) then
            ZO_MenuBar_AddButton(menuBar, filterData)
        end
    end
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_BACKPACK].filterBar, ITEMFILTERTYPE_ALL)

    local visibilityOption = layoutData.bankInfoBarVisibilityOption
    local hideTelvarInfo = visibilityOption == ZO_BACKPACK_LAYOUT_HIDE_ALL_BANK_INFO_BARS or visibilityOption == ZO_BACKPACK_LAYOUT_HIDE_ONLY_TELVAR_BANK_INFO_BARS
    local hideMoneyInfo = visibilityOption == ZO_BACKPACK_LAYOUT_HIDE_ALL_BANK_INFO_BARS
    local hideSlotInfo = visibilityOption == ZO_BACKPACK_LAYOUT_HIDE_ALL_BANK_INFO_BARS

    ZO_PlayerInventoryInfoBarAltMoney:SetHidden(hideMoneyInfo)
    ZO_PlayerInventoryInfoBarAltFreeSlots:SetHidden(hideSlotInfo)
    ZO_PlayerInventoryInfoBarTelvarStones:SetHidden(hideTelvarInfo)
    ZO_PlayerInventoryInfoBarAltTelvarStones:SetHidden(hideTelvarInfo)

    ZO_CraftBagInfoBarAltMoney:SetHidden(hideMoneyInfo)
    ZO_CraftBagInfoBarAltFreeSlots:SetHidden(hideSlotInfo)
    ZO_CraftBagInfoBarTelvarStones:SetHidden(hideTelvarInfo)
    ZO_CraftBagInfoBarAltTelvarStones:SetHidden(hideTelvarInfo)
end

function ZO_InventoryManager:ApplySharedBagLayout(inventoryControl, layoutData)
    inventoryControl:ClearAnchors()
    inventoryControl:SetAnchor(TOPLEFT, ZO_SharedRightPanelBackground, TOPLEFT, 0, layoutData.inventoryTopOffsetY)
    inventoryControl:SetAnchor(BOTTOMLEFT, ZO_SharedRightPanelBackground, BOTTOMLEFT, 0, layoutData.inventoryBottomOffsetY)

    local inventoryContainer = inventoryControl:GetNamedChild("List")
    inventoryContainer:SetWidth(layoutData.width)
    inventoryContainer:ClearAnchors()
    inventoryContainer:SetAnchor(TOPRIGHT, inventoryControl, TOPRIGHT, 0, layoutData.backpackOffsetY)
    inventoryContainer:SetAnchor(BOTTOMRIGHT)

    ZO_ScrollList_SetHeight(inventoryContainer, inventoryContainer:GetHeight())
    ZO_ScrollList_Commit(inventoryContainer)

    local sortHeaders = inventoryControl:GetNamedChild("SortBy")
    sortHeaders:ClearAnchors()
    sortHeaders:SetAnchor(TOPRIGHT, inventoryControl, TOPRIGHT, 0, layoutData.sortByOffsetY)
    sortHeaders:SetWidth(layoutData.width)

    local emptyLabel = inventoryControl:GetNamedChild("Empty")
    emptyLabel:ClearAnchors()
    emptyLabel:SetAnchor(TOP, inventoryControl, TOP, 0, layoutData.emptyLabelOffsetY)

    local sortByName = sortHeaders:GetNamedChild("Name")
    sortByName:SetWidth(layoutData.sortByNameWidth)

    local filterDivider = inventoryControl:GetNamedChild("FilterDivider")
    filterDivider:ClearAnchors()
    filterDivider:SetAnchor(TOP, ZO_SharedRightPanelBackground, TOP, 0, layoutData.inventoryFilterDividerTopOffsetY)
end

--Quest Items
-------------

function ZO_InventoryManager:AddQuestItem(questItem, searchType)
    local inventory = self.inventories[INVENTORY_QUEST_ITEM]

    questItem.inventory = inventory
    --store all tools and items in a subtable under the questIndex for faster access
    local questIndex = questItem.questIndex
    if not inventory.slots[questIndex] then
        inventory.slots[questIndex] = {}
    end
    table.insert(inventory.slots[questIndex], questItem)

    local index = #inventory.slots[questIndex]

    if(searchType == SEARCH_TYPE_QUEST_ITEM) then
        questItem.searchData = {type = SEARCH_TYPE_QUEST_ITEM, questIndex = questIndex, stepIndex = questItem.stepIndex, conditionIndex = questItem.conditionIndex, index = index }
    else
        questItem.searchData = {type = SEARCH_TYPE_QUEST_TOOL, questIndex = questIndex, toolIndex = questItem.toolIndex, index = index }
    end

    inventory.stringSearch:Insert(questItem.searchData)
end

function ZO_InventoryManager:RefreshAllQuests()
    for questIndex = 1, MAX_JOURNAL_QUESTS do
        self:RefreshQuest(questIndex, PREVENT_LAYOUT)
    end
    self:UpdateList(INVENTORY_QUEST_ITEM)
end

function ZO_InventoryManager:RefreshQuest(questIndex, doLayout)
    if doLayout == nil then
        doLayout = true
    end

    self:ResetQuest(questIndex)

    local questCache = SHARED_INVENTORY:GenerateSingleQuestCache(questIndex)

    if questCache then
        for _, questItem in pairs(questCache) do
            local searchType = questItem.toolIndex and SEARCH_TYPE_QUEST_TOOL or SEARCH_TYPE_QUEST_ITEM
            self:AddQuestItem(questItem, searchType)
        end
    end

    if doLayout then
        self:UpdateList(INVENTORY_QUEST_ITEM)
    end
end

function ZO_InventoryManager:ResetQuest(questIndex)
    local inventory = self.inventories[INVENTORY_QUEST_ITEM]
    local itemTable = inventory.slots[questIndex]
    if itemTable then
        --remove all quest items from search
        for i = 1, #itemTable do
            inventory.stringSearch:Remove(itemTable.searchData)
        end
    end

    inventory.slots[questIndex] = nil
end

--Launder
---------

function ZO_InventoryManager:RefreshBackpackWithFenceData(callback)
    -- If no callback is specified, ZO_ScrollList will attempt to use the default callback specified for each list element's data type
    ZO_ScrollList_RefreshVisible(self.inventories[BAG_BACKPACK].listView, nil, callback)
end

--Bank
------

--Bank Deposit/Withdraw Dialog
local ZO_BankGenericCurrencyDepositWithdrawDialog = ZO_Object:Subclass()

function ZO_BankGenericCurrencyDepositWithdrawDialog:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:Initialize(prefix, control, queryFunction, depositFunction, withdrawFunction, maxDepositFunction, maxWithdrawalFunction)
    self.control = control
    self.depositWithdrawCurrency = control:GetNamedChild("DepositWithdrawCurrency")
    self.queryFunction = queryFunction
    self.maxDepositFunction = maxDepositFunction
    self.maxWithdrawalFunction = maxWithdrawalFunction

    self.depositWithdrawButton = self.control:GetNamedChild("DepositWithdraw")
    self.currencyType = CURT_MONEY  --default to gold

    self.goldButton = control:GetNamedChild("GoldButton")
    self.telvarButton = control:GetNamedChild("TelvarButton")

    if self.goldButton and self.telvarButton then   --radio button logic for switching between gold/telvar
        self.usesTelvarStones = true
        self.bankingFeeLabel = self.control:GetNamedChild("BankingFee")
        self.minDepositLabel = self.control:GetNamedChild("MinDeposit")

        local function OnCurrencySelectionClicked(button)
            if self.currencyType ~= button.currencyType then
                self.currencyType = button.currencyType
                self:ChangeCurrencyType()
            end
        end

        self.goldButton.currencyType = CURT_MONEY
        self.goldButton:SetHandler("OnClicked", OnCurrencySelectionClicked)

        self.telvarButton.currencyType = CURT_TELVAR_STONES
        self.telvarButton:SetHandler("OnClicked", OnCurrencySelectionClicked)

        self.currencyTypeRadioGroup = ZO_RadioButtonGroup:New()
        self.currencyTypeRadioGroup:Add(self.goldButton)
        self.currencyTypeRadioGroup:Add(self.telvarButton)

        local function IsButtonClicked(button)
            return button.currencyType == self.currencyType
        end
        self.currencyTypeRadioGroup:UpdateFromData(IsButtonClicked)
    end

    ZO_Dialogs_RegisterCustomDialog(prefix.."_WITHDRAW_GOLD",
    {
        customControl = control,
        title =
        {
            text = SI_BANK_WITHDRAW_GOLD_TITLE,
        },
        setup = function(dialog)
            self.withdrawMode = true
            self:SetupWithdraw(dialog)
        end,
        buttons =
        {
            {
                control = self.depositWithdrawButton,
                text = SI_BANK_WITHDRAW_GOLD,
                callback = function(dialog)
                                local amount = ZO_DefaultCurrencyInputField_GetCurrency(self.depositWithdrawCurrency)
                                if amount > 0 then
                                    withdrawFunction(self.currencyType, amount)
                                end
                            end,
            },
            {
                control = self.control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            }
        }
    })

    ZO_Dialogs_RegisterCustomDialog(prefix.."_DEPOSIT_GOLD",
    {
        customControl = control,
        title =
        {
            text = SI_BANK_DEPOSIT_GOLD_TITLE,
        },
        setup = function(dialog)
            self.withdrawMode = false
            self:SetupDeposit(dialog)
        end,
        buttons =
        {
            {
                control = self.depositWithdrawButton,
                text = SI_BANK_DEPOSIT_GOLD,
                callback = function(dialog)
                                local amount = ZO_DefaultCurrencyInputField_GetCurrency(self.depositWithdrawCurrency)
                                if (self.currencyType == CURT_TELVAR_STONES and amount >= GetTelvarStoneMinimumDeposit() and amount > GetTelvarStoneBankingFee()) 
                                    or (self.currencyType == CURT_MONEY and amount > 0) then
                                    depositFunction(self.currencyType, amount)
                                end
                            end,
            },
            {
                control = self.control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:UpdateDepositWithdrawCurrency()
    self.control:GetNamedChild("CarriedCurrency"):SetText(zo_strformat(SI_BANK_GOLD_AMOUNT_CARRIED, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(GetCarriedCurrencyAmount(self.currencyType), useShortFormat, self.currencyType)))
    self.control:GetNamedChild("BankedCurrency"):SetText(zo_strformat(SI_BANK_GOLD_AMOUNT_BANKED, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(self.queryFunction(self.currencyType), useShortFormat, self.currencyType)))
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:OnCurrencyInputAmountChanged(currencyAmount)
    --Disable deposit button if you aren't meeting the minimum telvar fee or are depositing zero gold
    if (self.currencyType == CURT_TELVAR_STONES and currencyAmount >= GetTelvarStoneMinimumDeposit() and currencyAmount > GetTelvarStoneBankingFee()) 
        or (self.currencyType == CURT_MONEY and currencyAmount > 0) then
        self.depositWithdrawButton:SetState(BSTATE_NORMAL, false)
    else
        self.depositWithdrawButton:SetState(BSTATE_DISABLED, true)
    end
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:SetupDeposit(dialog)
    --Init Currency Input field
    ZO_DefaultCurrencyInputField_Initialize(self.depositWithdrawCurrency, function(_, amount) self:OnCurrencyInputAmountChanged(amount) end, self.currencyType)

    if self.usesTelvarStones then
        if self.currencyType == CURT_TELVAR_STONES then
            local bankFee = GetTelvarStoneBankingFee()
            if bankFee > 0 then -- if telvar and fee setup labels and use total telvar
                self.bankingFeeLabel:SetText(zo_strformat(SI_BANK_TELVAR_STONE_BANK_FEE, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(bankFee, useShortFormat, self.currencyType)))
                self.bankingFeeLabel:SetHidden(false)
                ZO_DefaultCurrencyInputField_SetCurrencyMax(self.depositWithdrawCurrency, GetCarriedCurrencyAmount(self.currencyType))
            else
                self.bankingFeeLabel:SetHidden(true)
                ZO_DefaultCurrencyInputField_SetCurrencyMax(self.depositWithdrawCurrency, self.maxDepositFunction(self.currencyType))
            end

            local minDeposit = GetTelvarStoneMinimumDeposit()
            if minDeposit > 0 then
                self.minDepositLabel:SetText(zo_strformat(SI_BANK_TELVAR_STONE_MIN_DEPOSIT, ZO_CurrencyControl_FormatCurrencyAndAppendIcon(minDeposit, useShortFormat, self.currencyType)))
                self.minDepositLabel:SetHidden(false)
            else
               self.minDepositLabel:SetHidden(true)
            end
        else    --if gold hide both labels and use total gold as input max
            self.bankingFeeLabel:SetHidden(true)
            self.minDepositLabel:SetHidden(true)

            ZO_DefaultCurrencyInputField_SetCurrencyMax(self.depositWithdrawCurrency, self.maxDepositFunction(self.currencyType))
        end
    else    --if gold only dialog just use total gold as max
        ZO_DefaultCurrencyInputField_SetCurrencyMax(self.depositWithdrawCurrency, self.maxDepositFunction(self.currencyType))
    end

    self:UpdateDepositWithdrawCurrency()

    self.depositWithdrawCurrency.OnBeginInput()
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:SetupWithdraw()
    self.depositWithdrawButton:SetState(BSTATE_NORMAL, false) --reenable in case deposit disabled it and the user cancelled

    if self.usesTelvarStones then
        self.bankingFeeLabel:SetHidden(true)
        self.minDepositLabel:SetHidden(true)
    end

    ZO_DefaultCurrencyInputField_Initialize(self.depositWithdrawCurrency, ON_CURRENCY_CHANGED, self.currencyType)
    ZO_DefaultCurrencyInputField_SetCurrencyMax(self.depositWithdrawCurrency, self.maxWithdrawalFunction(self.currencyType))

    self:UpdateDepositWithdrawCurrency()

    self.depositWithdrawCurrency.OnBeginInput()
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:ChangeCurrencyType()
    self:UpdateDepositWithdrawCurrency()

    if self.withdrawMode then
        self:SetupWithdraw()
    else
        self:SetupDeposit()
    end
end

function ZO_InventoryManager:CreateBankScene()
    BANK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_PlayerBank)
    BANK_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                        if(newState == SCENE_SHOWING) then
                                                            if self.isListDirty[INVENTORY_BANK] then
                                                                local UPDATE_EVEN_IF_HIDDEN = true
                                                                self:UpdateList(INVENTORY_BANK, UPDATE_EVEN_IF_HIDDEN)
                                                            end
                                                        end
                                                    end)

    ZO_BankGenericCurrencyDepositWithdrawDialog:New("BANK", ZO_PlayerBankDepositWithdrawCurrency, GetBankedCurrencyAmount, DepositCurrencyIntoBank, WithdrawCurrencyFromBank, GetMaxBankDeposit, GetMaxBankWithdrawal)

    --Bank Second Row set visible and first row Telvar stones
    ZO_PlayerBankInfoBarTelvarStones:SetHidden(false)
    ZO_PlayerBankInfoBarAltMoney:SetHidden(false)
    ZO_PlayerBankInfoBarAltTelvarStones:SetHidden(false)
    ZO_PlayerBankInfoBarAltFreeSlots:SetHidden(false)

    self.bankWithdrawTabKeybindButtonGroup = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local iconTexture = "EsoUI/Art/currency/currency_gold.dds"
                local iconMarkup = zo_iconFormat(iconTexture, 24, 24)
                local cost = GetNextBankUpgradePrice()
                if GetCarriedCurrencyAmount(CURT_MONEY) >= cost then
                    return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_CurrencyControl_FormatCurrency(cost), iconMarkup)
                end
                return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(cost)), iconMarkup)
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = IsBankUpgradeAvailable,
            callback = DisplayBankUpgrade,
        },
        {
            name = GetString(SI_BANK_WITHDRAW_GOLD_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() ZO_Dialogs_ShowDialog("BANK_WITHDRAW_GOLD") end,
        },
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_STACK_ALL",
            callback = function()
                StackBag(BAG_BANK)
            end,
        }
    }

    self.bankDepositTabKeybindButtonGroup = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_BANK_DEPOSIT_GOLD_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() ZO_Dialogs_ShowDialog("BANK_DEPOSIT_GOLD") end,
        },
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_STACK_ALL",
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        }
    }

    local function CreateButtonData(normal, pressed, highlight)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
        }
    end

    local bankFragmentBar = ZO_SceneFragmentBar:New(ZO_PlayerBankMenuBar)

    --Withdraw Button
    local withdrawButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_withdraw_up.dds",
                                               "EsoUI/Art/Bank/bank_tabIcon_withdraw_down.dds",
                                               "EsoUI/Art/Bank/bank_tabIcon_withdraw_over.dds")
    bankFragmentBar:Add(SI_BANK_WITHDRAW, { BANK_FRAGMENT }, withdrawButtonData, self.bankWithdrawTabKeybindButtonGroup)

    --Deposit Button
    local depositButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_deposit_up.dds",
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_down.dds", 
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_over.dds")
    bankFragmentBar:Add(SI_BANK_DEPOSIT, { INVENTORY_FRAGMENT, BACKPACK_BANK_LAYOUT_FRAGMENT }, depositButtonData, self.bankDepositTabKeybindButtonGroup)
    
    local bankScene = ZO_InteractScene:New("bank", SCENE_MANAGER, BANKING_INTERACTION)
    bankScene:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if(newState == SCENE_SHOWING) then
                                                        self:RefreshAllInventorySlots(INVENTORY_BANK)
                                                        self:UpdateFreeSlots(INVENTORY_BACKPACK)
                                                        self:RefreshMoney()
                                                        self:RefreshBankedGold()
                                                        self:RefreshTelvarStones()
                                                        self:RefreshBankedTelvarStones()
                                                        bankFragmentBar:SelectFragment(SI_BANK_WITHDRAW)
                                                    elseif(newState == SCENE_HIDDEN) then
                                                        ZO_InventorySlot_RemoveMouseOverKeybinds()
                                                        ZO_PlayerInventory_EndSearch(ZO_PlayerBankSearchBox)
                                                        bankFragmentBar:Clear()
                                                    end
                                                end)
end

function ZO_InventoryManager:IsBanking()
    return GetInteractionType() == INTERACTION_BANK
end

function ZO_InventoryManager:RefreshUpgradePossible()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.bankDepositTabKeybindButtonGroup)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.bankWithdrawTabKeybindButtonGroup)
end

function ZO_InventoryManager:GetBankItem(slotIndex)
    return self.inventories[INVENTORY_BANK].slots[slotIndex]
end

function ZO_InventoryManager:RefreshBankedGold()
    if self:IsBanking() then
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerBankInfoBarMoney, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerBankInfoBarAltMoney, CURT_MONEY, GetBankedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_BANKED_CURRENCY_OPTIONS)
    end
end

function ZO_InventoryManager:RefreshBankedTelvarStones()
    if self:IsBanking() then
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerBankInfoBarTelvarStones, CURT_TELVAR_STONES, GetCarriedCurrencyAmount(CURT_TELVAR_STONES), ZO_KEYBOARD_CARRIED_TELVAR_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerBankInfoBarAltTelvarStones, CURT_TELVAR_STONES, GetBankedCurrencyAmount(CURT_TELVAR_STONES), ZO_KEYBOARD_BANKED_TELVAR_OPTIONS)
    end
end

--Guild Bank
--------------

function ZO_InventoryManager:CreateGuildBankScene()
    GUILD_BANK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildBank)
    GUILD_BANK_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                            if(newState == SCENE_SHOWING) then
                                                                if self.isListDirty[INVENTORY_GUILD_BANK] then
                                                                    local UPDATE_EVEN_IF_HIDDEN = true
                                                                    self:UpdateList(INVENTORY_GUILD_BANK, UPDATE_EVEN_IF_HIDDEN)
                                                                end
                                                            end
                                                        end)

    ZO_BankGenericCurrencyDepositWithdrawDialog:New("GUILD_BANK", ZO_PlayerBankDepositWithdrawGold, GetGuildBankedCurrencyAmount, DepositCurrencyIntoGuildBank, WithdrawCurrencyFromGuildBank, GetMaxGuildBankDeposit, GetMaxGuildBankWithdrawal)

    --Bank Second Row Infobar set visible
    ZO_GuildBankInfoBarAltMoney:SetHidden(false)
    ZO_GuildBankInfoBarAltFreeSlots:SetHidden(false)

    self.guildBankWithdrawTabKeybindButtonGroup = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local selectedGuildId = GetSelectedGuildBankId()
                if(selectedGuildId) then
                    return GetGuildName(selectedGuildId)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible =   function()
                            return GetSelectedGuildBankId() ~= nil
                        end,
            callback =  function()
                            ZO_Dialogs_ShowDialog("SELECT_GUILD_BANK")
                        end,
        },
        {
            name = GetString(SI_BANK_WITHDRAW_GOLD_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() ZO_Dialogs_ShowDialog("GUILD_BANK_WITHDRAW_GOLD") end,
            visible =   function()
                            local guildId = GetSelectedGuildBankId()
                            return guildId ~= nil and DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW_GOLD)
                        end,
        }
    }

    self.guildBankDepositTabKeybindButtonGroup = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local selectedGuild = GetSelectedGuildBankId()
                if(selectedGuild) then
                    return GetGuildName(selectedGuild)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible =   function()
                            return GetSelectedGuildBankId() ~= nil
                        end,
            callback =  function()
                            ZO_Dialogs_ShowDialog("SELECT_GUILD_BANK")
                        end,
        },
        {
            name = GetString(SI_BANK_DEPOSIT_GOLD_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() ZO_Dialogs_ShowDialog("GUILD_BANK_DEPOSIT_GOLD") end,
            visible =   function()
                            return DoesGuildHavePrivilege(GetSelectedGuildBankId(), GUILD_PRIVILEGE_BANK_DEPOSIT)
                        end,
        }
    }

    local function CreateButtonData(normal, pressed, highlight)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
        }
    end

    local guildBankFragmentBar = ZO_SceneFragmentBar:New(ZO_GuildBankMenuBar)

    --Withdraw Button
    local withdrawButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_withdraw_up.dds",
                                               "EsoUI/Art/Bank/bank_tabIcon_withdraw_down.dds",
                                               "EsoUI/Art/Bank/bank_tabIcon_withdraw_over.dds")
    guildBankFragmentBar:Add(SI_BANK_WITHDRAW, { GUILD_BANK_FRAGMENT }, withdrawButtonData, self.guildBankWithdrawTabKeybindButtonGroup)

    --Deposit Button
    local depositButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_deposit_up.dds",
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_down.dds", 
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_over.dds")
    guildBankFragmentBar:Add(SI_BANK_DEPOSIT, { INVENTORY_FRAGMENT, BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT }, depositButtonData, self.guildBankDepositTabKeybindButtonGroup)

    local guildBankScene = ZO_InteractScene:New("guildBank", SCENE_MANAGER, GUILD_BANKING_INTERACTION)
    guildBankScene:RegisterCallback("StateChange",  function(oldState, newState)
                                                        if(newState == SCENE_SHOWING) then
                                                            self:RefreshMoney()
                                                            self:UpdateFreeSlots(INVENTORY_BACKPACK)
                                                            guildBankFragmentBar:SelectFragment(SI_BANK_WITHDRAW)
                                                            ZO_SharedInventory_SelectAccessibleGuildBank(self.lastSuccessfulGuildBankId)
                                                        elseif(newState == SCENE_HIDDEN) then
                                                            guildBankFragmentBar:Clear()
                                                            ZO_InventorySlot_RemoveMouseOverKeybinds()
                                                            ZO_PlayerInventory_EndSearch(ZO_PlayerBankSearchBox)
                                                        end
                                                    end)
end

function ZO_InventoryManager:OpenGuildBank()
    SCENE_MANAGER:Show("guildBank")
end

function ZO_InventoryManager:IsGuildBanking()
    return IsGuildBankOpen()
end

function ZO_InventoryManager:CloseGuildBank()
    SCENE_MANAGER:Hide("guildBank")
    ZO_GuildBankBackpackLoading:SetHidden(true)
    self:ClearAllGuildBankItems()
end

function ZO_InventoryManager:RefreshAllGuildBankItems()
    local inventory = self.inventories[INVENTORY_GUILD_BANK]

    --Reset
    inventory.slots = {}
    inventory.hasAnyQuickSlottableItems = nil

    local search = inventory.stringSearch
    if(search) then
        search:RemoveAll()
    end

    self.suppressItemAddedAlert = true

    --Add items
    local slotId = GetNextGuildBankSlotId()
    while slotId do
        self:AddInventoryItem(INVENTORY_GUILD_BANK, slotId)
        slotId = GetNextGuildBankSlotId(slotId)
    end 

    self:LayoutInventoryItems(INVENTORY_GUILD_BANK)

    self:UpdateFreeSlots(INVENTORY_BACKPACK)

    self.suppressItemAddedAlert = nil   
end

function ZO_InventoryManager:ClearAllGuildBankItems()
    local inventory = self.inventories[INVENTORY_GUILD_BANK]
    
    --Reset
    inventory.slots = {}

    local search = inventory.stringSearch
    if(search) then
        search:RemoveAll()
    end

    self:LayoutInventoryItems(INVENTORY_GUILD_BANK)
end

function ZO_InventoryManager:SetGuildBankLoading(guildId)
    self.loadingGuildBank = true
    self:ClearAllGuildBankItems()
    ZO_GuildBankBackpackLoading:Show()
    if GUILD_BANK_FRAGMENT:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.guildBankWithdrawTabKeybindButtonGroup)
    else
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.guildBankDepositTabKeybindButtonGroup)
    end
end

function ZO_InventoryManager:SetGuildBankLoaded()
    self.loadingGuildBank = false
    self.lastSuccessfulGuildBankId = GetSelectedGuildBankId()
    ZO_GuildBankBackpackLoading:Hide()
    self:RefreshAllGuildBankItems()
    self:RefreshGuildBankedMoney()
end

function ZO_InventoryManager:OnGuildBankOpenError(error)
    if(self.loadingGuildBank) then
        self.loadingGuildBank = false
        ZO_GuildBankBackpackLoading:Hide()
    end
    self:ClearAllGuildBankItems()
    ZO_SharedInventory_SelectAccessibleGuildBank(self.lastSuccessfulGuildBankId)
end

function ZO_InventoryManager:OnGuildBankDeselected()
    self:ClearAllGuildBankItems()
    ZO_SharedInventory_SelectAccessibleGuildBank(self.lastSuccessfulGuildBankId)
    self:RefreshGuildBankedMoney()
    ZO_Dialogs_ReleaseDialog("GUILD_BANK_WITHDRAW_GOLD")
    ZO_Dialogs_ReleaseDialog("GUILD_BANK_DEPOSIT_GOLD")
end

function ZO_InventoryManager:RefreshGuildBankedMoney()
    if self:IsGuildBanking() then
        ZO_CurrencyControl_SetSimpleCurrency(ZO_GuildBankInfoBarMoney, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_CARRIED_CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(ZO_GuildBankInfoBarAltMoney, CURT_MONEY, GetGuildBankedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_BANKED_CURRENCY_OPTIONS)
        --refresh deposit window's guild bank label, RefreshMoney handles it's top info bar, but the guild info hasn't updated when MoneyUpdate fires
        ZO_CurrencyControl_SetSimpleCurrency(ZO_PlayerInventoryInfoBarAltMoney, CURT_MONEY, GetGuildBankedCurrencyAmount(CURT_MONEY), ZO_KEYBOARD_BANKED_CURRENCY_OPTIONS)
    end
end

function ZO_InventoryManager:RefreshGuildBankMoneyOperationsPossible(guildId)
    if(GetSelectedGuildBankId() == guildId) then
        if(not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW_GOLD)) then
            ZO_Dialogs_ReleaseDialog("GUILD_BANK_WITHDRAW_GOLD")
        end
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.guildBankWithdrawTabKeybindButtonGroup)
    end
end

function ZO_InventoryManager:GuildSizeChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.guildBankDepositTabKeybindButtonGroup)
end

function ZO_InventoryManager:UpdateEmptyBagLabel(inventoryType, isEmptyList)
    local inventory = self.inventories[inventoryType]
    if inventory then
        -- Quest items are both an inventory list and a backpack tab, we only want to update their label now if we are looking at that tab
        local label
        if inventoryType == INVENTORY_BACKPACK or (inventoryType == INVENTORY_QUEST_ITEM and self.selectedTabType == INVENTORY_QUEST_ITEM) then
            label = ZO_PlayerInventory:GetNamedChild("Empty")
        elseif inventoryType == INVENTORY_CRAFT_BAG then
            label = ZO_CraftBag:GetNamedChild("Empty")
        end

        if label then 
            label:SetHidden(not isEmptyList)
            if inventory.currentFilter == ITEMFILTERTYPE_ALL then
                -- Quest items are only accessed through the ITEMFILTERTYPE_QUEST filter and do not need a unique string here
                label:SetText(GetString(inventory.inventoryEmptyStringId))
            else
                label:SetText(GetString(SI_INVENTORY_ERROR_FILTER_EMPTY))
            end
        end
    end
end

--Craft Bag
--------------

function ZO_InventoryManager:CreateCraftBagFragment()
    CRAFT_BAG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CraftBag)

    local UPDATE_EVEN_IF_HIDDEN = true
    local function OnStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            if self.isListDirty[INVENTORY_CRAFT_BAG] then
                self:UpdateList(INVENTORY_CRAFT_BAG, UPDATE_EVEN_IF_HIDDEN)
            end
            TriggerTutorial(TUTORIAL_TRIGGER_CRAFT_BAG_OPENED)
            self:UpdateApparelSection()
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            self:ClearNewStatusOnItemsThePlayerHasSeen(INVENTORY_CRAFT_BAG)
        end
    end

    CRAFT_BAG_FRAGMENT:RegisterCallback("StateChange", OnStateChange)
end

------------
--Global API
------------

function ZO_InventoryManager_SetQuestToolData(slotControl, questIndex, toolIndex)
    local questItems = PlayerInventory.inventories[INVENTORY_QUEST_ITEM].slots[questIndex]

    if questItems then
        for i = 1, #questItems do
            if questItems[i].toolIndex == toolIndex then
                local questItem = questItems[i]
                ZO_Inventory_SetupQuestSlot(slotControl, questItem.questIndex, questItem.toolIndex, questItem.stepIndex, questItem.conditionIndex)
                ZO_InventorySlot_SetType(slotControl, SLOT_TYPE_QUEST_ITEM)
                ZO_InventorySlot_UpdateCooldowns(slotControl)
            end
        end
    end
end

----------------
--Event Handlers
----------------

local function OnPlayerActivated()
    PlayerInventory:RefreshAllInventorySlots(INVENTORY_BACKPACK)
    PlayerInventory:RefreshAllInventorySlots(INVENTORY_CRAFT_BAG)
end

local function OnFullInventoryUpdated(bagId)
    if bagId == BAG_BACKPACK then
        PlayerInventory:RefreshAllInventorySlots(INVENTORY_BACKPACK)
    elseif bagId == BAG_BANK then
        PlayerInventory:RefreshAllInventorySlots(INVENTORY_BANK)
        PlayerInventory:RefreshUpgradePossible()
    elseif bagId == BAG_VIRTUAL then
        PlayerInventory:RefreshAllInventorySlots(INVENTORY_CRAFT_BAG)
    end

    INVENTORY_MENU_BAR:UpdateInventoryKeybinds()
end

local function OnInventorySlotUpdated(bagId, slotIndex)
    if bagId == PlayerInventory.inventories[INVENTORY_BACKPACK].backingBag then
        PlayerInventory:RefreshInventorySlot(INVENTORY_BACKPACK, slotIndex)
    elseif PlayerInventory:IsBanking() and bagId == PlayerInventory.inventories[INVENTORY_BANK].backingBag then
        PlayerInventory:RefreshInventorySlot(INVENTORY_BANK, slotIndex)
    elseif bagId == PlayerInventory.inventories[INVENTORY_GUILD_BANK].backingBag then
        PlayerInventory:RefreshInventorySlot(INVENTORY_GUILD_BANK, slotIndex)
        --For the deposit window while guild banking, the guild info isn't available when INVENTORY_BACKPACK updates.
        PlayerInventory:RefreshInventorySlot(INVENTORY_BACKPACK, slotIndex)
    elseif bagId == PlayerInventory.inventories[INVENTORY_CRAFT_BAG].backingBag then
        PlayerInventory:RefreshInventorySlot(INVENTORY_CRAFT_BAG, slotIndex)
    end

    INVENTORY_MENU_BAR:UpdateInventoryKeybinds()
end

local function OnInventorySlotLocked(eventCode, bagId, slotIndex)
    if(bagId == PlayerInventory.inventories[INVENTORY_BACKPACK].backingBag) then
        PlayerInventory:RefreshInventorySlotLocked(INVENTORY_BACKPACK, slotIndex, true)
    elseif(PlayerInventory:IsBanking() and bagId == PlayerInventory.inventories[INVENTORY_BANK].backingBag) then
        PlayerInventory:RefreshInventorySlotLocked(INVENTORY_BANK, slotIndex, true)
    end
end

local function OnInventorySlotUnlocked(eventCode, bagId, slotIndex)
    if(bagId == PlayerInventory.inventories[INVENTORY_BACKPACK].backingBag) then
        PlayerInventory:RefreshInventorySlotLocked(INVENTORY_BACKPACK, slotIndex, false)
    elseif(PlayerInventory:IsBanking() and bagId == PlayerInventory.inventories[INVENTORY_BANK].backingBag) then
        PlayerInventory:RefreshInventorySlotLocked(INVENTORY_BANK, slotIndex, false)
    end
end

local function OnRequestDestroyItem(eventCode, bag, slot, itemCount, name, needsConfirm)
    local _, actualItemCount = GetItemInfo(bag, slot)
    if itemCount == 0 and actualItemCount > 1 then
        itemCount = actualItemCount
    end

    local itemLink = GetItemLink(bag, slot)
    if(needsConfirm) then
        local dialogName = "CONFIRM_DESTROY_ITEM_PROMPT"
        if IsInGamepadPreferredMode() then
            dialogName = ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG
        end
        ZO_Dialogs_ShowPlatformDialog(dialogName, nil, {mainTextParams = {itemLink, itemCount, GetString(SI_DESTROY_ITEM_CONFIRMATION)}})
    else
        ZO_Dialogs_ShowPlatformDialog("DESTROY_ITEM_PROMPT", nil, {mainTextParams = {itemLink, itemCount}})
    end
end

local function OnCancelRequestDestroyItem()
    ZO_Dialogs_ReleaseDialog("DESTROY_ITEM_PROMPT")
    ZO_Dialogs_ReleaseDialog("CONFIRM_DESTROY_ITEM_PROMPT")
end

local function OnLevelUpdate(eventCode, tag, level)
    if tag == "player" then
        PlayerInventory:RefreshAllInventoryOverlays(INVENTORY_BACKPACK)
    end
end

local function OnChampionPointsGained()
    PlayerInventory:RefreshAllInventoryOverlays(INVENTORY_BACKPACK)
end

local function OnQuestsUpdated()
    --the quest we were planning to abandon may be gone, kill the prompt
    ZO_Dialogs_ReleaseDialog("ABANDON_QUEST")
    PlayerInventory:RefreshAllQuests()
    CALLBACK_MANAGER:FireCallbacks("QuestUpdate")
end

local function OnSingleQuestUpdated(journalIndex)
    PlayerInventory:RefreshQuest(journalIndex)
    CALLBACK_MANAGER:FireCallbacks("QuestUpdate")
end

local function OnUpdateCooldowns(eventCode)
    PlayerInventory:UpdateItemCooldowns(INVENTORY_BACKPACK)
    PlayerInventory:UpdateItemCooldowns(INVENTORY_QUEST_ITEM)
end

local function OnOpenBank()
    if not IsInGamepadPreferredMode() then
        SCENE_MANAGER:Show("bank")
    end
end

local function OnCloseBank()
    if not IsInGamepadPreferredMode() then
        SCENE_MANAGER:Hide("bank")
    end
end

local function OnOpenGuildBank()
    if not IsInGamepadPreferredMode() then
        PlayerInventory:OpenGuildBank()
    end
end

local function OnCloseGuildBank()
    if not IsInGamepadPreferredMode() then
        PlayerInventory:CloseGuildBank()
    end
end

local function OnGuildBankSelected(eventCode, guildId)
    PlayerInventory:SetGuildBankLoading(guildId)
end

local function OnGuildBankDeselected()
    PlayerInventory:OnGuildBankDeselected()
end

local function OnGuildBankItemsReady()
    PlayerInventory:SetGuildBankLoaded()
end

local function OnGuildBankOpenError(eventCode, error)
    PlayerInventory:OnGuildBankOpenError(error)
end

local function OnMoneyUpdated(eventCode, newMoney, oldMoney, reason)
    PlayerInventory:RefreshMoney()
end

local function OnBankedGoldUpdated(eventCode, newGold, oldGold)
    PlayerInventory:RefreshBankedGold()
end

local function OnBankedTelvarStonesUpdated(eventCode, newStones, oldStones)
    PlayerInventory:RefreshBankedTelvarStones()
end

local function OnGuildSizeChanged()
    PlayerInventory:GuildSizeChanged()
end

local function OnGuildBankedMoneyUpdated(eventCode, newMoney, oldMoney)
    PlayerInventory:RefreshGuildBankedMoney()
end

local function OnTelvarStonesUpdated(eventCode, newTelvarStones, oldTelvarStones, changeReason)
    PlayerInventory:RefreshTelvarStones()
end

BUY_BAG_SPACE_INTERACTION =
{
    type = "Buy Bag Space",
    interactTypes = { INTERACTION_BUY_BAG_SPACE },
}

local function OnBuyBagSpace(eventCode, cost)
    if IsInGamepadPreferredMode() then
        BUY_BAG_SPACE_GAMEPAD:Show(cost)
    else
        if(not ZO_Dialogs_FindDialog("BUY_BAG_SPACE")) then
            ZO_Dialogs_ShowDialog("BUY_BAG_SPACE", {cost = cost})
            INTERACT_WINDOW:OnBeginInteraction(BUY_BAG_SPACE_INTERACTION)
        end
    end
end

local function OnBoughtBagSpace()
    PLAYER_INVENTORY:UpdateFreeSlots(INVENTORY_BACKPACK)
end

local function OnMountInfoUpdate()
    PLAYER_INVENTORY:UpdateFreeSlots(INVENTORY_BACKPACK)
end

local function OnBuyBankSpace(eventCode, cost)
     if IsInGamepadPreferredMode() then
        BUY_BANK_SPACE_GAMEPAD:Show(cost)
    else
        if(not ZO_Dialogs_FindDialog("BUY_BANK_SPACE")) then
            ZO_Dialogs_ShowDialog("BUY_BANK_SPACE", {cost = cost})
        end
    end
end

local function OnBoughtBankSpace()
    PLAYER_INVENTORY:UpdateFreeSlots(INVENTORY_BANK)
end

local function OnCloseBuySpace()
    ZO_Dialogs_ReleaseDialog("BUY_BAG_SPACE")
    ZO_Dialogs_ReleaseDialog("BUY_BANK_SPACE")

    BUY_BAG_SPACE_GAMEPAD:Hide()
end

local function OnPlayerDead()
    PlayerInventory:RefreshAllInventoryOverlays(INVENTORY_BACKPACK)
    PlayerInventory.itemsLockedDueToDeath = true
end

local function OnPlayerAlive()
    PlayerInventory:RefreshAllInventoryOverlays(INVENTORY_BACKPACK)
    PlayerInventory.itemsLockedDueToDeath = false
end

local function HandleCursorPickup(eventCode, cursorType, unused1, unused2, unused3, unused4, unused5, unused6, itemSoundCategory)
    if cursorType == MOUSE_CONTENT_INVENTORY_ITEM or cursorType == MOUSE_CONTENT_EQUIPPED_ITEM or cursorType == MOUSE_CONTENT_QUEST_ITEM then
        ZO_InventoryLandingArea_SetHidden(ZO_PlayerBankBackpackLandingArea, false, SI_INVENTORY_LANDING_AREA_MOVE_TO_BANK)
        ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, false, SI_INVENTORY_LANDING_AREA_MOVE_TO_BACKPACK)
    elseif cursorType == MOUSE_CONTENT_STORE_ITEM then
        ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, false, SI_INVENTORY_LANDING_AREA_BUY_ITEM)
    elseif cursorType == MOUSE_CONTENT_STORE_BUYBACK_ITEM then
        ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, false, SI_INVENTORY_LANDING_AREA_BUYBACK_ITEM)
    end

    PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_PICKUP)
end

local function HandleCursorCleared(eventCode, oldCursorType)
    ZO_InventoryLandingArea_SetHidden(ZO_PlayerBankBackpackLandingArea, true)
    ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, true)
end

local function OnGuildRanksChanged(_, guildId)
    PlayerInventory:RefreshGuildBankMoneyOperationsPossible(guildId)
end

local function OnGuildRankChanged(_, guildId)
    PlayerInventory:RefreshGuildBankMoneyOperationsPossible(guildId)
end

local function OnGuildMemberRankChanged(_, guildId, displayName)
    if(displayName == GetDisplayName()) then
        PlayerInventory:RefreshGuildBankMoneyOperationsPossible(guildId)
    end
end

--------------
--XML Handlers
--------------

--Inventory
-----------

function ZO_PlayerInventory_OnSearchTextChanged(editBox)
    if editBox == ZO_PlayerInventorySearchBox then
        PlayerInventory:UpdateList(PlayerInventory.selectedTabType)
    elseif editBox == ZO_CraftBagSearchBox then
        PlayerInventory:UpdateList(INVENTORY_CRAFT_BAG)
    else
        PlayerInventory:UpdateList(INVENTORY_BANK)
    end
end

function ZO_PlayerInventory_EndSearch(editBox)
    if editBox:GetText() ~= "" then
        editBox:SetText("")
    end
    editBox:LoseFocus()
end

function ZO_PlayerInventory_OnSearchEnterKeyPressed(editBox)
    -- Do not clear the search, just unfocus the box, the appropriate items are now highlighted and should stay that way
    editBox:LoseFocus()
end

function ZO_PlayerInventory_FilterButtonOnMouseEnter(self)
    ZO_MenuBarButtonTemplate_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, ZO_MenuBarButtonTemplate_GetData(self).tooltipText)
end

function ZO_PlayerInventory_FilterButtonOnMouseExit(self)
    ClearTooltip(InformationTooltip)
    ZO_MenuBarButtonTemplate_OnMouseExit(self)
end

--Bank
------
function ZO_PlayerInventory_InitSortHeader(header, stringId, textAlignment, sortKey, sortOrder)
    if sortOrder == nil then
        sortOrder = ZO_SORT_ORDER_UP
    end
    ZO_SortHeader_Initialize(header, GetString(stringId), sortKey, sortOrder, textAlignment or TEXT_ALIGN_LEFT, "ZoFontHeader")
end

function ZO_PlayerInventory_InitSortHeaderIcon(header, icon, sortUpIcon, sortDownIcon, mouseoverIcon, sortKey, sortOrder)
    if sortOrder == nil then
        sortOrder = ZO_SORT_ORDER_UP
    end
    ZO_SortHeader_InitializeIconHeader(header, icon, sortUpIcon, sortDownIcon, mouseoverIcon, sortKey, sortOrder)
end

function ZO_PlayerInventory_Initialize()
    PlayerInventory = ZO_InventoryManager:New()
    PLAYER_INVENTORY = PlayerInventory

    PlayerInventory.itemsLockedDueToDeath = IsUnitDead("player")

    PlayerInventory:SetupInitialFilter()

    --inventory events
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnFullInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventorySlotUpdated)

    ZO_PlayerInventory:RegisterForEvent(EVENT_INVENTORY_SLOT_LOCKED, OnInventorySlotLocked)
    ZO_PlayerInventory:RegisterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, OnInventorySlotUnlocked)
    ZO_PlayerInventory:RegisterForEvent(EVENT_MOUSE_REQUEST_DESTROY_ITEM, OnRequestDestroyItem)
    ZO_PlayerInventory:RegisterForEvent(EVENT_CANCEL_MOUSE_REQUEST_DESTROY_ITEM, OnCancelRequestDestroyItem)
    ZO_PlayerInventory:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    ZO_PlayerInventory:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
    ZO_PlayerInventory:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    ZO_PlayerInventory:RegisterForEvent(EVENT_MONEY_UPDATE, OnMoneyUpdated)
    ZO_PlayerInventory:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, OnTelvarStonesUpdated)

    --quest item events
    SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", OnQuestsUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", OnSingleQuestUpdated)
    ZO_PlayerInventory:RegisterForEvent(EVENT_ACTION_UPDATE_COOLDOWNS, OnUpdateCooldowns)

    --bank events
    ZO_PlayerInventory:RegisterForEvent(EVENT_OPEN_BANK, OnOpenBank)
    ZO_PlayerInventory:RegisterForEvent(EVENT_CLOSE_BANK, OnCloseBank)
    ZO_PlayerInventory:RegisterForEvent(EVENT_BANKED_MONEY_UPDATE, OnBankedGoldUpdated)
    ZO_PlayerInventory:RegisterForEvent(EVENT_BANKED_TELVAR_STONES_UPDATE, OnBankedTelvarStonesUpdated)

    --guild bank events
    ZO_PlayerInventory:RegisterForEvent(EVENT_OPEN_GUILD_BANK, OnOpenGuildBank)
    ZO_PlayerInventory:RegisterForEvent(EVENT_CLOSE_GUILD_BANK, OnCloseGuildBank)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_BANK_SELECTED, OnGuildBankSelected)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_BANK_DESELECTED, OnGuildBankDeselected)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_BANK_ITEMS_READY, OnGuildBankItemsReady)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_BANK_OPEN_ERROR, OnGuildBankOpenError)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_BANKED_MONEY_UPDATE, OnGuildBankedMoneyUpdated)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_RANKS_CHANGED, OnGuildRanksChanged)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_RANK_CHANGED, OnGuildRankChanged)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED, OnGuildMemberRankChanged)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_MEMBER_ADDED, OnGuildSizeChanged)
    ZO_PlayerInventory:RegisterForEvent(EVENT_GUILD_MEMBER_REMOVED, OnGuildSizeChanged)

    --inventory upgrade events
    ZO_PlayerInventory:RegisterForEvent(EVENT_INVENTORY_BUY_BAG_SPACE, OnBuyBagSpace)
    ZO_PlayerInventory:RegisterForEvent(EVENT_INVENTORY_BOUGHT_BAG_SPACE, OnBoughtBagSpace)
    ZO_PlayerInventory:RegisterForEvent(EVENT_MOUNT_INFO_UPDATED, OnMountInfoUpdate)
    ZO_PlayerInventory:RegisterForEvent(EVENT_INVENTORY_BUY_BANK_SPACE, OnBuyBankSpace)
    ZO_PlayerInventory:RegisterForEvent(EVENT_INVENTORY_BOUGHT_BANK_SPACE, OnBoughtBankSpace)
    ZO_PlayerInventory:RegisterForEvent(EVENT_INVENTORY_CLOSE_BUY_SPACE, OnCloseBuySpace)

    --player events
    ZO_PlayerInventory:RegisterForEvent(EVENT_PLAYER_DEAD, OnPlayerDead)
    ZO_PlayerInventory:RegisterForEvent(EVENT_PLAYER_ALIVE, OnPlayerAlive)
    ZO_PlayerInventory:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)
    ZO_PlayerInventory:RegisterForEvent(EVENT_CHAMPION_POINT_GAINED, OnChampionPointsGained)

    PlayerInventory:RefreshAllInventorySlots(INVENTORY_BACKPACK)
    PlayerInventory:RefreshAllInventorySlots(INVENTORY_CRAFT_BAG)
    PlayerInventory:RefreshAllQuests()
    PlayerInventory:RefreshMoney()
    PlayerInventory:RefreshTelvarStones()

    PlayerInventory:CreateBankScene()
    PlayerInventory:CreateGuildBankScene()
    PlayerInventory:CreateCraftBagFragment()
end

--Select Guild Bank Dialog
----------------------

function ZO_SelectGuildBankDialog_OnInitialized(self)
    local dialog = ZO_SelectGuildDialog:New(self, "SELECT_GUILD_BANK", SelectGuildBank)
    dialog:SetTitle(GetString(SI_PROMPT_TITLE_SELECT_GUILD_BANK))
    dialog:SetPrompt(GetString(SI_SELECT_GUILD_BANK_INSTRUCTIONS))
    dialog:SetCurrentStateSource(GetSelectedGuildBankId) 
end
