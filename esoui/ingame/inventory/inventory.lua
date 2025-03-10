--Variables
local g_playerInventory = nil
PLAYER_INVENTORY = nil

INVENTORY_BACKPACK = 1
INVENTORY_QUEST_ITEM = 2
INVENTORY_BANK = 3
INVENTORY_HOUSE_BANK = 4
INVENTORY_GUILD_BANK = 5
INVENTORY_CRAFT_BAG = 6

local DONT_USE_SHORT_FORMAT = false
local PREVENT_LAYOUT = false
local NOT_IS_GAMEPAD = false

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
    g_playerInventory:ChangeFilter(tabData)
end

-- Item List Sort management
local SORT_KEYS =
{
    slotIndex = { isNumeric = true },
    stackCount = { tiebreaker = "slotIndex", isNumeric = true },
    name = { tiebreaker = "stackCount" },
    displayQuality = { tiebreaker = "quality", isNumeric = true },
    -- quality is deprecated, included here for addon backwards compatibility
    quality = { tiebreaker = "name", isNumeric = true },
    stackSellPrice = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP, isNumeric = true },
    statusSortOrder = { tiebreaker = "age", isNumeric = true},
    age = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP, isNumeric = true},
    traitInformationSortOrder = { tiebreaker = "name", isNumeric = true, tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    sellInformationSortOrder = { tiebreaker = "name", isNumeric = true, tieBreakerSortOrder = ZO_SORT_ORDER_UP },
}

function ZO_Inventory_GetDefaultHeaderSortKeys()
    return SORT_KEYS
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

local function OnInventoryItemRowHidden(rowControl, slot)
    slot.slotControl = nil
end

function ZO_UpdateStatusControlIcons(inventorySlot, slotData)
    local statusControl = inventorySlot:GetNamedChild("StatusTexture")

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
        statusControl:AddIcon(ZO_Currency_GetPlatformCurrencyIcon(CURT_CROWN_GEMS))
    end

    if slotData.bagId == BAG_WORN then
        statusControl:AddIcon(ZO_KEYBOARD_IS_EQUIPPED_ICON)
    end

    if slotData.isInArmory then
        statusControl:AddIcon(ZO_IN_ARMORY_BUILD_ICON)
    end

    if slotData.additionalIcons ~= nil then
        for _, additionalIcon in ipairs(slotData.additionalIcons) do
            statusControl:AddIcon(additionalIcon)
        end
    end

    statusControl:Show()

    if slotData.age ~= 0 then
        slotData.clearAgeOnClose = true
    end
end

function ZO_UpdateTraitInformationControlIcon(inventorySlot, slotData)
    local traitInfoControl = inventorySlot:GetNamedChild("TraitInfo")

    traitInfoControl:ClearIcons()

    if slotData.traitInformation ~= ITEM_TRAIT_INFORMATION_NONE and not ZO_Store_IsShopping() then
        traitInfoControl:AddIcon(ZO_GetPlatformTraitInformationIcon(slotData.traitInformation))
        traitInfoControl:Show()
    end
end

function ZO_UpdateSellInformationControlIcon(inventorySlot, slotData)
    local sellInformationControl = inventorySlot:GetNamedChild("SellInformation")
    local sellInformationTexture = ZO_GetItemSellInformationIcon(slotData.sellInformation)

    if sellInformationTexture then
        sellInformationControl:SetTexture(sellInformationTexture)
        sellInformationControl:SetHidden(not ZO_Store_IsShopping())
    else
        sellInformationControl:SetHidden(true)
    end
end

ITEM_SLOT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

-- When switching fence tabs, this function can be called before the fencing mode switch is done,
-- causing IsLaundering() to return an incorrect result.
local function GetDefaultSlotSellValue(slot)
    return (FENCE_MANAGER and SYSTEMS:GetObject("fence"):IsLaundering()) and slot.stackLaunderPrice or slot.stackSellPrice
end

local function SetupInventoryItemRow(rowControl, slot, overrideOptions)
    local options = overrideOptions or ITEM_SLOT_CURRENCY_OPTIONS
    -- slot.quality is deprecated, included here for addon backwards compatibility
    local displayQuality = slot.displayQuality or slot.quality
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality)
    local nameControl = rowControl:GetNamedChild("Name")
    nameControl:SetText(slot.name) -- already formatted
    nameControl:SetColor(r, g, b, 1)

    local itemValue
    if type(options.overrideSellValue) == "function" then
        itemValue = options.overrideSellValue(slot)
    else
        itemValue = GetDefaultSlotSellValue(slot)
    end

    local sellPriceControl = rowControl:GetNamedChild("SellPriceText")
    sellPriceControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, itemValue, options)

    local inventorySlot = rowControl:GetNamedChild("Button")
    ZO_Inventory_BindSlot(inventorySlot, slot.inventory.slotType, slot.slotIndex, slot.bagId)
    ZO_PlayerInventorySlot_SetupSlot(rowControl, slot.stackCount, slot.iconFile, slot.meetsUsageRequirement, slot.locked or IsUnitDead("player"))

    slot.slotControl = rowControl

    ZO_UpdateStatusControlIcons(rowControl, slot)
    ZO_UpdateTraitInformationControlIcon(rowControl, slot)
    ZO_UpdateSellInformationControlIcon(rowControl, slot)
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
    local nameControl = rowControl:GetNamedChild("Name")
    nameControl:SetText(questItem.name) -- already formatted
    nameControl:SetColor(r, g, b, 1)

    rowControl:GetNamedChild("SellPriceText"):SetHidden(true)

    local inventorySlot = rowControl:GetNamedChild("Button")
    ZO_InventorySlot_SetType(inventorySlot, SLOT_TYPE_QUEST_ITEM)

    questItem.slotControl = rowControl

    ZO_Inventory_SetupSlot(inventorySlot, questItem.stackCount, questItem.iconFile)
    ZO_Inventory_SetupQuestSlot(inventorySlot, questItem.questIndex, questItem.toolIndex, questItem.stepIndex, questItem.conditionIndex)

    ZO_UpdateStatusControlIcons(rowControl, questItem)
end

local function CreateNewTabFilterData(filterType, inventoryType, filterString, normal, pressed, highlight, hiddenColumns, hideTab, isSubFilter)
    local tabData =
    {
        -- Custom data
        filterType = filterType,
        inventoryType = inventoryType,
        isSubFilter = isSubFilter,
        hiddenColumns = hiddenColumns,
        activeTabText = filterString,
        tooltipText = filterString,

        -- Menu bar data
        hidden = hideTab,
        ignoreVisibleCheck = hideTab == true,
        descriptor = filterType,
        normal = normal,
        pressed = pressed,
        highlight = highlight,
        callback = HandleTabSwitch,
    }

    return tabData
end

-------------------
--Inventory Manager
-------------------

ZO_InventoryManager = ZO_InitializingObject:Subclass()

function ZO_InventoryManager:Initialize(control)
    g_playerInventory = self
    self.selectedTabType = INVENTORY_BACKPACK

    self:SetupCategoryFlashAnimation()

    -- Need to define these in reverse order than how you want to display them
    local BACKPACK_FILTER_KEYS =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_JUNK,
        ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
        ITEM_TYPE_DISPLAY_CATEGORY_COMPANION,
        ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING,
        ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING,
        ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
        ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
        ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
        ITEM_TYPE_DISPLAY_CATEGORY_ALL,
    }

    local BACKPACK_FILTERS = {}
    for _, key in ipairs(BACKPACK_FILTER_KEYS) do
        local filterData = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(key)

        local inventoryType = INVENTORY_BACKPACK
        local filter = CreateNewTabFilterData(filterData.filterType, inventoryType, filterData.filterString, filterData.icons.up, filterData.icons.down, filterData.icons.over, filterData.hideColumnTable, filterData.hideTabFunction)
        table.insert(BACKPACK_FILTERS, filter)
    end

    local function GetFiltersForKeys(filterKeys, inventoryType)
        local filters = {}
        for _, key in ipairs(filterKeys) do
            local filterData = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(key)
            local filter = CreateNewTabFilterData(filterData.filterType, inventoryType, filterData.filterString, filterData.icons.up, filterData.icons.down, filterData.icons.over, filterData.hideColumnTable, filterData.hideTabFunction)
            table.insert(filters, filter)
        end

        return filters
    end

    local BANK_FILTER_KEYS =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_JUNK,
        ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
        ITEM_TYPE_DISPLAY_CATEGORY_COMPANION,
        ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING,
        ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING,
        ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
        ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
        ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
        ITEM_TYPE_DISPLAY_CATEGORY_ALL
    }

    local BANK_FILTERS = GetFiltersForKeys(BANK_FILTER_KEYS, INVENTORY_BANK)

    local HOUSE_BANK_FILTERS = GetFiltersForKeys(BANK_FILTER_KEYS, INVENTORY_HOUSE_BANK)

    local GUILD_BANK_FILTER_KEYS =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
        ITEM_TYPE_DISPLAY_CATEGORY_COMPANION,
        ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING,
        ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING,
        ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
        ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
        ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
        ITEM_TYPE_DISPLAY_CATEGORY_ALL
    }

    local GUILD_BANK_FILTERS = GetFiltersForKeys(GUILD_BANK_FILTER_KEYS, INVENTORY_GUILD_BANK)

    local CRAFT_BAG_FILTER_KEYS =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
        ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM,
        ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL,
        ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING,
        ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING,
        ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY,
        ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING,
        ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING,
        ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING,
        ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING,
        ITEM_TYPE_DISPLAY_CATEGORY_ALL
    }

    local CRAFT_BAG_FILTERS = GetFiltersForKeys(CRAFT_BAG_FILTER_KEYS, INVENTORY_CRAFT_BAG)

    local IS_SUB_FILTER = true
    local function GetSearchFilters(searchFilterKeys, inventoryType)
        local searchFilters = {}
        for filterId, subFilters in pairs(searchFilterKeys) do
            searchFilters[filterId] = {}

            local currentInventoryType = inventoryType
            local searchFilterAtId = searchFilters[filterId]
            for _, subfilterKey in ipairs(subFilters) do
                local filterData = ZO_ItemFilterUtils.GetSearchFilterData(filterId, subfilterKey)
                local filter = CreateNewTabFilterData(filterData.filterType, currentInventoryType, filterData.filterString, filterData.icons.up, filterData.icons.down, filterData.icons.over, filterData.hideColumnTable, filterData.hideTabFunction, IS_SUB_FILTER)
                table.insert(searchFilterAtId, filter)
            end
        end

        return searchFilters
    end

    local BACKPACK_SEARCH_FILTER_KEYS =
    {
        [ITEM_TYPE_DISPLAY_CATEGORY_ALL] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] =
        {
            EQUIPMENT_FILTER_TYPE_RESTO_STAFF,
            EQUIPMENT_FILTER_TYPE_DESTRO_STAFF,
            EQUIPMENT_FILTER_TYPE_BOW,
            EQUIPMENT_FILTER_TYPE_TWO_HANDED,
            EQUIPMENT_FILTER_TYPE_ONE_HANDED,
            EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] =
        {
            EQUIPMENT_FILTER_TYPE_SHIELD,
            EQUIPMENT_FILTER_TYPE_HEAVY,
            EQUIPMENT_FILTER_TYPE_MEDIUM,
            EQUIPMENT_FILTER_TYPE_LIGHT,
            EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] =
        {
            EQUIPMENT_FILTER_TYPE_RING,
            EQUIPMENT_FILTER_TYPE_NECK,
            EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
            ITEM_TYPE_DISPLAY_CATEGORY_CROWN_ITEM,
            ITEM_TYPE_DISPLAY_CATEGORY_REPAIR_ITEM,
            ITEM_TYPE_DISPLAY_CATEGORY_CONTAINER,
            ITEM_TYPE_DISPLAY_CATEGORY_MASTER_WRIT,
            ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MOTIF,
            ITEM_TYPE_DISPLAY_CATEGORY_POISON,
            ITEM_TYPE_DISPLAY_CATEGORY_POTION,
            ITEM_TYPE_DISPLAY_CATEGORY_RECIPE,
            ITEM_TYPE_DISPLAY_CATEGORY_DRINK,
            ITEM_TYPE_DISPLAY_CATEGORY_FOOD,
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
            ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL,
            ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM,
            ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL,
            ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING,
            ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING,
            ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY,
            ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING,
            ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING,
            ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING,
            ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING,
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] =
        {
            SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL,
            SPECIALIZED_ITEMTYPE_FURNISHING_SEATING,
            SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT,
            SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY,
            SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION,
            SPECIALIZED_ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_COMPANION] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY,
            ITEM_TYPE_DISPLAY_CATEGORY_ARMOR,
            ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS,
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
            ITEM_TYPE_DISPLAY_CATEGORY_TRASH,
            ITEM_TYPE_DISPLAY_CATEGORY_LURE,
            ITEM_TYPE_DISPLAY_CATEGORY_TROPHY,
            ITEM_TYPE_DISPLAY_CATEGORY_TOOL,
            ITEM_TYPE_DISPLAY_CATEGORY_SIEGE,
            ITEM_TYPE_DISPLAY_CATEGORY_SOUL_GEM,
            ITEM_TYPE_DISPLAY_CATEGORY_GLYPH,
            ITEM_TYPE_DISPLAY_CATEGORY_APPEARANCE,
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
    }

    local BACKPACK_SEARCH_FILTERS = GetSearchFilters(BACKPACK_SEARCH_FILTER_KEYS, INVENTORY_BACKPACK)

    local BANK_SEARCH_FILTER_KEYS =
    {
        [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_ALL],
        [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS],
        [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_ARMOR],
        [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY],
        [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS,
            ITEM_TYPE_DISPLAY_CATEGORY_CROWN_ITEM,
            ITEM_TYPE_DISPLAY_CATEGORY_REPAIR_ITEM,
            ITEM_TYPE_DISPLAY_CATEGORY_MASTER_WRIT,
            ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MOTIF,
            ITEM_TYPE_DISPLAY_CATEGORY_POISON,
            ITEM_TYPE_DISPLAY_CATEGORY_POTION,
            ITEM_TYPE_DISPLAY_CATEGORY_RECIPE,
            ITEM_TYPE_DISPLAY_CATEGORY_DRINK,
            ITEM_TYPE_DISPLAY_CATEGORY_FOOD,
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING],
        [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING],
        [ITEM_TYPE_DISPLAY_CATEGORY_COMPANION] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_COMPANION],
        [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS],
        [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_JUNK],
    }

    local BANK_SEARCH_FILTERS = GetSearchFilters(BANK_SEARCH_FILTER_KEYS, INVENTORY_BANK)
    local HOUSE_BANK_SEARCH_FILTERS = GetSearchFilters(BANK_SEARCH_FILTER_KEYS, INVENTORY_HOUSE_BANK)

    local GUILD_BANK_SEARCH_FILTER_KEYS =
    {
        [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_ALL],
        [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS],
        [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_ARMOR],
        [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY],
        [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE],
        [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING],
        [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING],
        [ITEM_TYPE_DISPLAY_CATEGORY_COMPANION] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_COMPANION],
        [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = BANK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS],
    }

    local GUILD_BANK_SEARCH_FILTERS = GetSearchFilters(GUILD_BANK_SEARCH_FILTER_KEYS, INVENTORY_GUILD_BANK)

    local CRAFT_BAG_SEARCH_FILTER_KEYS =
    {
        [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = BACKPACK_SEARCH_FILTER_KEYS[ITEM_TYPE_DISPLAY_CATEGORY_ALL],
        [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] =
        {
            ITEMTYPE_FURNISHING_MATERIAL,
            ITEMTYPE_BLACKSMITHING_BOOSTER,
            ITEMTYPE_BLACKSMITHING_MATERIAL,
            ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] =
        {
            ITEMTYPE_FURNISHING_MATERIAL,
            ITEMTYPE_CLOTHIER_BOOSTER,
            ITEMTYPE_CLOTHIER_MATERIAL,
            ITEMTYPE_CLOTHIER_RAW_MATERIAL,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] =
        {
            ITEMTYPE_FURNISHING_MATERIAL,
            ITEMTYPE_WOODWORKING_BOOSTER,
            ITEMTYPE_WOODWORKING_MATERIAL,
            ITEMTYPE_WOODWORKING_RAW_MATERIAL,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] =
        {
            ITEMTYPE_FURNISHING_MATERIAL,
            ITEMTYPE_JEWELRYCRAFTING_BOOSTER,
            ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER,
            ITEMTYPE_JEWELRYCRAFTING_MATERIAL,
            ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] =
        {
            ITEMTYPE_FURNISHING_MATERIAL,
            ITEMTYPE_POISON_BASE,
            ITEMTYPE_POTION_BASE,
            ITEMTYPE_REAGENT,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] =
        {
            ITEMTYPE_FURNISHING_MATERIAL,
            ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
            ITEMTYPE_ENCHANTING_RUNE_POTENCY,
            ITEMTYPE_ENCHANTING_RUNE_ASPECT,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL,
            ITEM_TYPE_DISPLAY_CATEGORY_LURE,
            ITEM_TYPE_DISPLAY_CATEGORY_RARE_INGREDIENT,
            ITEM_TYPE_DISPLAY_CATEGORY_DRINK_INGREDIENT,
            ITEM_TYPE_DISPLAY_CATEGORY_FOOD_INGREDIENT,
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] =
        {
            ITEMTYPE_RAW_MATERIAL,
            ITEMTYPE_STYLE_MATERIAL,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] =
        {
            ITEMTYPE_JEWELRY_TRAIT,
            ITEMTYPE_JEWELRY_RAW_TRAIT,
            ITEMTYPE_ARMOR_TRAIT,
            ITEMTYPE_WEAPON_TRAIT,
            ITEMTYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] =
        {
            ITEMTYPE_NONE,
        },
    }

    local CRAFT_BAG_SEARCH_FILTERS = GetSearchFilters(CRAFT_BAG_SEARCH_FILTER_KEYS, INVENTORY_CRAFT_BAG)

    local function BackpackAltFreeSlotType()
        if self:IsBanking() then
            return self:GetBankInventoryType()
        elseif self:IsGuildBanking() then
            return INVENTORY_GUILD_BANK
        else
            return nil  --hide label
        end
    end

    local inventories =
    {
        [INVENTORY_BACKPACK] =
        {
            searchBox = ZO_PlayerInventorySearchFiltersTextSearchBox,
            slotType = SLOT_TYPE_ITEM,
            backingBags = { BAG_BACKPACK },
            slots = { [BAG_BACKPACK] = {} },
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
            currentFilter = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
            tabFilters = BACKPACK_FILTERS,
            subFilters = BACKPACK_SEARCH_FILTERS,
            filterBar = ZO_PlayerInventoryTabs,
            subFilterBar = ZO_PlayerInventorySearchFiltersSubTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            activeTab = ZO_PlayerInventoryTabsActive,
            inventoryEmptyStringId = function(object, inventory)
                if object:IsGuildBanking() then
                    local guildId = GetSelectedGuildBankId()
                    if not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_DEPOSIT) then
                        return GetString(SI_INVENTORY_ERROR_GUILD_BANK_NO_DEPOSIT_PERMISSIONS)
                    elseif not DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_BANK_DEPOSIT) then
                        return zo_strformat(SI_INVENTORY_ERROR_GUILD_BANK_NO_DEPOSIT_PRIVILEGES, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_BANK_DEPOSIT))
                    end
                end
                if inventory.currentFilter == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
                    return GetString(SI_INVENTORY_ERROR_INVENTORY_EMPTY)
                else
                    return GetString(SI_INVENTORY_ERROR_FILTER_EMPTY)
                end
            end,
        },
        [INVENTORY_QUEST_ITEM] =
        {
            slots = {},
            slotType = SLOT_TYPE_QUEST_ITEM,
            listView = ZO_QuestItemsList,
            listDataType = INVENTORY_DATA_TYPE_QUEST,
            listSetupCallback = SetupQuestRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            currentFilter = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
            currentSortKey = "name",
            currentSortOrder = ZO_SORT_ORDER_UP,
            filterBar = ZO_QuestItemsTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            hiddenColumns = ZO_QUEST_ITEMS_HIDDEN_COLUMNS,
        },
        [INVENTORY_BANK] =
        {
            searchBox = ZO_PlayerBankSearchFiltersTextSearchBox,
            slotType = SLOT_TYPE_BANK_ITEM,
            backingBags = { BAG_BANK, BAG_SUBSCRIBER_BANK },
            slots = { [BAG_BANK] = {}, [BAG_SUBSCRIBER_BANK] = {} },
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
            currentFilter = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
            tabFilters = BANK_FILTERS,
            subFilters = BANK_SEARCH_FILTERS,
            filterBar = ZO_PlayerBankTabs,
            subFilterBar = ZO_PlayerBankSearchFiltersSubTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            activeTab = ZO_PlayerBankTabsActive,
        },
        [INVENTORY_HOUSE_BANK] =
        {
            searchBox = ZO_HouseBankSearchFiltersTextSearchBox,
            slotType = SLOT_TYPE_BANK_ITEM,
            --backing bags and slots are dynamically setup
            listView = ZO_HouseBankBackpack,
            listDataType = INVENTORY_DATA_TYPE_BACKPACK,
            listSetupCallback = SetupInventoryItemRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            freeSlotsLabel = ZO_HouseBankInfoBarFreeSlots,
            altFreeSlotsLabel = ZO_HouseBankInfoBarAltFreeSlots,
            freeSlotType = INVENTORY_BACKPACK,
            altFreeSlotType = INVENTORY_HOUSE_BANK,
            freeSlotsStringId = SI_INVENTORY_HOUSE_BANK_REMAINING_SPACES,
            freeSlotsFullStringId = SI_INVENTORY_HOUSE_BANK_COMPLETELY_FULL,
            currentSortKey = "name",
            currentSortOrder = ZO_SORT_ORDER_UP,
            currentFilter = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
            tabFilters = HOUSE_BANK_FILTERS,
            subFilters = HOUSE_BANK_SEARCH_FILTERS,
            filterBar = ZO_HouseBankTabs,
            subFilterBar = ZO_HouseBankSearchFiltersSubTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            activeTab = ZO_HouseBankTabsActive,
        },
        [INVENTORY_GUILD_BANK] =
        {
            searchBox = ZO_GuildBankSearchFiltersTextSearchBox,
            slotType = SLOT_TYPE_GUILD_BANK_ITEM,
            backingBags = { BAG_GUILDBANK },
            slots = { [BAG_GUILDBANK] = {} },
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
            currentFilter = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
            tabFilters = GUILD_BANK_FILTERS,
            subFilters = GUILD_BANK_SEARCH_FILTERS,
            filterBar = ZO_GuildBankTabs,
            subFilterBar = ZO_GuildBankSearchFiltersSubTabs,
            rowTemplate = "ZO_PlayerInventorySlot",
            activeTab = ZO_GuildBankTabsActive,
            inventoryEmptyStringId = function(object, inventory)
               if inventory.currentFilter == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
                    return GetString(SI_INVENTORY_ERROR_GUILD_BANK_EMPTY)
                else
                    return GetString(SI_INVENTORY_ERROR_FILTER_EMPTY)
                end
            end,
        },
        [INVENTORY_CRAFT_BAG] =
        {
            searchBox = ZO_CraftBagSearchFiltersTextSearchBox,
            slotType = SLOT_TYPE_CRAFT_BAG_ITEM,
            backingBags = { BAG_VIRTUAL },
            slots = { [BAG_VIRTUAL] = {} },
            listView = ZO_CraftBagList,
            listDataType = INVENTORY_DATA_TYPE_BACKPACK,
            listSetupCallback = SetupBackpackInventoryItemRow,
            listHiddenCallback = OnInventoryItemRowHidden,
            currentSortKey = "statusSortOrder",
            currentSortOrder = ZO_SORT_ORDER_DOWN,
            currentFilter = ITEM_TYPE_DISPLAY_CATEGORY_ALL,
            tabFilters = CRAFT_BAG_FILTERS,
            subFilters = CRAFT_BAG_SEARCH_FILTERS,
            filterBar = ZO_CraftBagTabs,
            subFilterBar = ZO_CraftBagSearchFiltersSubTabs,
            rowTemplate = "ZO_CraftBagSlot",
            activeTab = ZO_CraftBagTabsActive,
            inventoryEmptyStringId = SI_INVENTORY_ERROR_CRAFT_BAG_EMPTY,
        },
    }

    self.isListDirty = {}

    self:InitializeHeaderSort(INVENTORY_BACKPACK, inventories[INVENTORY_BACKPACK], ZO_PlayerInventorySortBy)
    self:InitializeHeaderSort(INVENTORY_BANK, inventories[INVENTORY_BANK], ZO_PlayerBankSortBy)
    self:InitializeHeaderSort(INVENTORY_HOUSE_BANK, inventories[INVENTORY_HOUSE_BANK], ZO_HouseBankSortBy)
    self:InitializeHeaderSort(INVENTORY_GUILD_BANK, inventories[INVENTORY_GUILD_BANK], ZO_GuildBankSortBy)
    self:InitializeHeaderSort(INVENTORY_CRAFT_BAG, inventories[INVENTORY_CRAFT_BAG], ZO_CraftBagSortBy)
    self:InitializeHeaderSort(INVENTORY_QUEST_ITEM, inventories[INVENTORY_QUEST_ITEM], ZO_QuestItemsSortBy)

    self.inventories = inventories
    self.searchToInventoryType = {}
    self.bagToInventoryType =
    {
        [BAG_BACKPACK] = INVENTORY_BACKPACK,
        [BAG_BANK] = INVENTORY_BANK,
        [BAG_SUBSCRIBER_BANK] = INVENTORY_BANK,
        [BAG_GUILDBANK] = INVENTORY_GUILD_BANK,
        [BAG_VIRTUAL] = INVENTORY_CRAFT_BAG,
    }
    for i = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
        self.bagToInventoryType[i] = INVENTORY_HOUSE_BANK
    end

    for _, inventoryData in pairs(self.inventories) do
        InitializeInventoryList(inventoryData)
        self:InitializeInventoryFilters(inventoryData)
    end

    self.newItemList = {}

    INVENTORY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_PlayerInventory)

    INVENTORY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            -- If no current context is set for inventory then assume the inventory is being opened
            if not self.inventories[INVENTORY_BACKPACK].currentContext then
                self:ActivateInventorySearch()
            else
                self.inventories[INVENTORY_BACKPACK].searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(self.inventories[INVENTORY_BACKPACK].currentContext))
            end

            -- Start tab and subtab flashing for new items
            for _, data in ipairs(self.newItemList) do
                self:PlayItemAddedAlert(data, data.inventory)
            end

            local UPDATE_EVEN_IF_HIDDEN = true
            if self.isListDirty[INVENTORY_BACKPACK] then
                if TEXT_SEARCH_MANAGER:IsFilterTargetInContext(self.inventories[INVENTORY_BACKPACK].currentContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT) then
                    self:UpdateList(INVENTORY_BACKPACK, UPDATE_EVEN_IF_HIDDEN)
                end
            end
            self:RefreshMoney()
            self:UpdateFreeSlots(INVENTORY_BACKPACK)

            self:UpdateApparelSection()
            --Reseting the comparison stats here since its too later when the window is already hidden.
            ZO_CharacterWindowStats_HideComparisonValues()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            if TEXT_SEARCH_MANAGER:IsActiveTextSearch("playerInventoryTextSearch") then
                self:DeactivateInventorySearch()
            end
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            self:ClearNewStatusOnItemsThePlayerHasSeen(INVENTORY_BACKPACK)
            self.newItemList = {}
        end
    end)

    SHARED_INVENTORY:RegisterCallback("SlotAdded", function(bagId, slotIndex, newSlotData, suppressItemAlert)
        local inventory = self.bagToInventoryType[bagId]
        if inventory then
            self:OnInventoryItemAdded(inventory, bagId, slotIndex, newSlotData, suppressItemAlert)
        end
    end)

    SHARED_INVENTORY:RegisterCallback("SlotRemoved", function(bagId, slotIndex, oldSlotData, suppressItemAlert)
        local inventory = self.bagToInventoryType[bagId]
        if inventory then
            self:OnInventoryItemRemoved(inventory, bagId, slotIndex, oldSlotData, suppressItemAlert)
        end
    end)

    self.itemsLockedDueToDeath = IsUnitDead("player")

    self:SetupInitialFilter()

    self:RefreshAllInventorySlots(INVENTORY_BACKPACK)
    self:RefreshAllInventorySlots(INVENTORY_CRAFT_BAG)
    self:RefreshAllInventorySlots(INVENTORY_BANK)
    self:RefreshAllQuests()
    self:RefreshMoney()

    self:CreateBankScene()
    self:CreateHouseBankScene()
    self:CreateGuildBankScene()
    self:CreateCraftBagFragment()
    self:CreateQuestItemsFragment()

    self:RegisterForEvents(control)
end

function ZO_InventoryManager:InitializeInventoryFilters(inventory)
    if inventory.tabFilters then
        local menuBar = inventory.filterBar
        ZO_MenuBar_ClearButtons(menuBar)
        for _, data in ipairs(inventory.tabFilters) do
            data.control = ZO_MenuBar_AddButton(menuBar, data)
        end
    end

    local function OnTextSearchTextChanged(editBox)
        TEXT_SEARCH_MANAGER:SetSearchText(inventory.currentContext, editBox:GetText())
    end

    if inventory.searchBox then
        inventory.searchBox:SetHandler("OnTextChanged", OnTextSearchTextChanged)
    end
end

function ZO_InventoryManager:InitializeHeaderSort(inventoryType, inventory, headerControl)
    local sortHeaders = ZO_SortHeaderGroup:New(headerControl, true)

    local function OnSortHeaderClicked(key, order)
        self:ChangeSort(key, inventoryType, order)
    end

    sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    sortHeaders:AddHeadersFromContainer()
    sortHeaders:SelectHeaderByKey(inventory.currentSortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

    inventory.sortHeaders = sortHeaders
end

function ZO_InventoryManager:RefreshPlayerInventorySearchContext()
    if not INVENTORY_FRAGMENT:IsHidden() then
        -- If the inventory fragment is shown then shown was called before the previous context screen
        -- was closed and the search context was not properly updated at that time, so update it now.
        self:ActivateInventorySearch()

        local UPDATE_EVEN_IF_HIDDEN = true
        if TEXT_SEARCH_MANAGER:IsFilterTargetInContext(self.inventories[INVENTORY_BACKPACK].currentContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT) then
            self:UpdateList(INVENTORY_BACKPACK, UPDATE_EVEN_IF_HIDDEN)
        end
    end
end

function ZO_InventoryManager:SetContextForInventories(context, inventoryTypeList)
    if not TEXT_SEARCH_MANAGER:IsActiveTextSearch(context) then
        TEXT_SEARCH_MANAGER:ActivateTextSearch(context)

        for _, inventoryType in ipairs(inventoryTypeList) do
            self.inventories[inventoryType].currentContext = context
        end

        if context then
            local SUPPRESS_TEXT_CHANGED_CALLBACK = true
            local function OnListTextFilterComplete()
                for _, inventoryType in ipairs(inventoryTypeList) do
                    if self.inventories[inventoryType].searchBox then
                        self.inventories[inventoryType].searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(context), SUPPRESS_TEXT_CHANGED_CALLBACK)
                    end
                    self:UpdateList(inventoryType)
                end
            end
            self.onListTextFilterCompleteCallback = OnListTextFilterComplete

            TEXT_SEARCH_MANAGER:RegisterCallback("UpdateSearchResults", self.onListTextFilterCompleteCallback)
        else
            TEXT_SEARCH_MANAGER:UnregisterCallback("UpdateSearchResults", self.onListTextFilterCompleteCallback)
        end
    end
end

function ZO_InventoryManager:ActivateInventorySearch()
    self:SetContextForInventories("playerInventoryTextSearch", { INVENTORY_BACKPACK, INVENTORY_CRAFT_BAG })

    local inventorySearchText = TEXT_SEARCH_MANAGER:GetSearchText("playerInventoryTextSearch")
    self.inventories[INVENTORY_BACKPACK].searchBox:SetText(inventorySearchText)
    self.inventories[INVENTORY_CRAFT_BAG].searchBox:SetText(inventorySearchText)
end

function ZO_InventoryManager:DeactivateInventorySearch()
    if TEXT_SEARCH_MANAGER:IsActiveTextSearch("playerInventoryTextSearch") then
        TEXT_SEARCH_MANAGER:DeactivateTextSearch("playerInventoryTextSearch")

        local REMOVE_CONTEXT = nil
        self:SetContextForInventories(REMOVE_CONTEXT, { INVENTORY_BACKPACK })
    end
end

function ZO_InventoryManager:ActivateBankSearch()
    self:SetContextForInventories("playerBankTextSearch", { INVENTORY_BACKPACK, INVENTORY_BANK })

    local bankSearchText = TEXT_SEARCH_MANAGER:GetSearchText("playerBankTextSearch")
    self.inventories[INVENTORY_BACKPACK].searchBox:SetText(bankSearchText)
    self.inventories[INVENTORY_BANK].searchBox:SetText(bankSearchText)
end

function ZO_InventoryManager:DeactivateBankSearch()
    if TEXT_SEARCH_MANAGER:IsActiveTextSearch("playerBankTextSearch") then
        TEXT_SEARCH_MANAGER:DeactivateTextSearch("playerBankTextSearch")

        local REMOVE_CONTEXT = nil
        self:SetContextForInventories(REMOVE_CONTEXT, { INVENTORY_BACKPACK, INVENTORY_BANK })
    end
end

function ZO_InventoryManager:ActivateHouseBankSearch()
    self:SetContextForInventories("houseBankTextSearch", { INVENTORY_BACKPACK, INVENTORY_HOUSE_BANK })

    local SUPPRESS_TEXT_CHANGED_CALLBACK = true
    local houseBankSearchText = TEXT_SEARCH_MANAGER:GetSearchText("houseBankTextSearch")
    self.inventories[INVENTORY_BACKPACK].searchBox:SetText(houseBankSearchText)
    self.inventories[INVENTORY_HOUSE_BANK].searchBox:SetText(houseBankSearchText)
end

function ZO_InventoryManager:DeactivateHouseBankSearch()
    if TEXT_SEARCH_MANAGER:IsActiveTextSearch("houseBankTextSearch") then
        TEXT_SEARCH_MANAGER:DeactivateTextSearch("houseBankTextSearch")

        local REMOVE_CONTEXT = nil
        self:SetContextForInventories(REMOVE_CONTEXT, { INVENTORY_BACKPACK, INVENTORY_HOUSE_BANK })
    end
end

function ZO_InventoryManager:ActivateGuildBankSearch()
    -- Reset the search string to force a search again since the guild bank slots get rebuild each show.
    TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, BAG_GUILDBANK)
    self:SetContextForInventories("guildBankTextSearch", { INVENTORY_BACKPACK, INVENTORY_GUILD_BANK })

    local guildBankSearchText = TEXT_SEARCH_MANAGER:GetSearchText("guildBankTextSearch")
    self.inventories[INVENTORY_BACKPACK].searchBox:SetText(guildBankSearchText)
    self.inventories[INVENTORY_GUILD_BANK].searchBox:SetText(guildBankSearchText)
end

function ZO_InventoryManager:DeactivateGuildBankSearch()
    if TEXT_SEARCH_MANAGER:IsActiveTextSearch("guildBankTextSearch") then
        TEXT_SEARCH_MANAGER:DeactivateTextSearch("guildBankTextSearch")

        local REMOVE_CONTEXT = nil
        self:SetContextForInventories(REMOVE_CONTEXT, { INVENTORY_BACKPACK, INVENTORY_GUILD_BANK })
    end
end

do
    local function OnRequestDestroyItem(eventCode, bag, slot, itemCount, name, needsConfirm)
        local _, actualItemCount = GetItemInfo(bag, slot)
        if itemCount == 0 and actualItemCount > 1 then
            itemCount = actualItemCount
        end

        local displayQuality = GetItemDisplayQuality(bag, slot)
        local coloredItemName = GetItemQualityColor(displayQuality):Colorize(name)
        if needsConfirm then
            local armoryBuildListNames = { GetItemArmoryBuildList(bag, slot) }
            if #armoryBuildListNames == 0 then
                local dialogName = "CONFIRM_DESTROY_ITEM_PROMPT"
                if IsInGamepadPreferredMode() then
                    dialogName = ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG
                end
                ZO_Dialogs_ShowPlatformDialog(dialogName, nil, { mainTextParams = { coloredItemName, itemCount, GetString(SI_DESTROY_ITEM_CONFIRMATION) } })
            else
                local dialogName = "CONFIRM_DESTROY_ARMORY_ITEM_PROMPT"
                if IsInGamepadPreferredMode() then
                    dialogName = ZO_GAMEPAD_CONFIRM_DESTROY_ARMORY_ITEM_DIALOG
                end
                local armoryBuildList = ZO_GenerateCommaSeparatedListWithAnd(armoryBuildListNames)
                ZO_Dialogs_ShowPlatformDialog(dialogName, nil, { mainTextParams = { ZO_SELECTED_TEXT:Colorize(armoryBuildList), #armoryBuildListNames, coloredItemName, itemCount, GetString(SI_DESTROY_ITEM_CONFIRMATION) } })
            end
        else
            ZO_Dialogs_ShowPlatformDialog("DESTROY_ITEM_PROMPT", nil, { mainTextParams = { coloredItemName, itemCount } })
        end
    end

    local function OnCancelRequestDestroyItem()
        ZO_Dialogs_ReleaseDialog("DESTROY_ITEM_PROMPT")
        ZO_Dialogs_ReleaseDialog("CONFIRM_DESTROY_ITEM_PROMPT")
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
            if not ZO_Dialogs_FindDialog("BUY_BAG_SPACE") then
                ZO_Dialogs_ShowDialog("BUY_BAG_SPACE", { cost = cost })
                INTERACT_WINDOW:OnBeginInteraction(BUY_BAG_SPACE_INTERACTION)
            end
        end
    end

    local function OnBuyBankSpace(eventCode, cost)
         if IsInGamepadPreferredMode() then
            BUY_BANK_SPACE_GAMEPAD:Show(cost)
        else
            if not ZO_Dialogs_FindDialog("BUY_BANK_SPACE") then
                ZO_Dialogs_ShowDialog("BUY_BANK_SPACE", { cost = cost })
            end
        end
    end

    local function OnCloseBuySpace()
        ZO_Dialogs_ReleaseDialog("BUY_BAG_SPACE")
        ZO_Dialogs_ReleaseDialog("BUY_BANK_SPACE")

        BUY_BAG_SPACE_GAMEPAD:Hide()
    end

    local function HandleCursorPickup(eventCode, cursorType, unused1, unused2, unused3, unused4, unused5, unused6, itemSoundCategory)
        if cursorType == MOUSE_CONTENT_INVENTORY_ITEM or cursorType == MOUSE_CONTENT_EQUIPPED_ITEM or cursorType == MOUSE_CONTENT_QUEST_ITEM then
            ZO_InventoryLandingArea_SetHidden(ZO_PlayerBankBackpackLandingArea, false)
            ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, false)
        elseif cursorType == MOUSE_CONTENT_STORE_ITEM then
            ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, false)
        elseif cursorType == MOUSE_CONTENT_STORE_BUYBACK_ITEM then
            ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, false)
        end

        PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_PICKUP)
    end

    local function HandleCursorCleared(eventCode, oldCursorType)
        ZO_InventoryLandingArea_SetHidden(ZO_PlayerBankBackpackLandingArea, true)
        ZO_InventoryLandingArea_SetHidden(ZO_PlayerInventoryListLandingArea, true)
    end

    function ZO_InventoryManager:RegisterForEvents(control)
        control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, function() self:UpdateApparelSection() end)
    
        --inventory events
        local function OnFullInventoryUpdated(bagId)
            if bagId == BAG_BANK then
                self:RefreshBankUpgradeKeybind()
            end

            for inventoryType, inventory in pairs(self.inventories) do
                if inventory.backingBags then
                    for _, searchBagId in ipairs(inventory.backingBags) do
                        if searchBagId == bagId then
                            self:RefreshAllInventorySlots(inventoryType)

                            -- Guild Bank is re-fetched from the server each time the guild bank is open so the search needs to be re-run since the slot numbers have changed.
                            if self.inventories[INVENTORY_GUILD_BANK].currentContext then
                                self.inventories[INVENTORY_GUILD_BANK].searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(self.inventories[INVENTORY_GUILD_BANK].currentContext))
                            end
                            break
                        end
                    end
                end
            end
        end
    
        local function OnPlayerActivated()
            self:RefreshAllInventorySlots(INVENTORY_BACKPACK)
            self:RefreshAllInventorySlots(INVENTORY_CRAFT_BAG)
        end
    
        local function RefreshMoney()
            self:RefreshMoney()
        end

        SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnFullInventoryUpdated)
        SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(bagId, slotIndex) self:OnInventorySlotUpdated(bagId, slotIndex) end)

        control:RegisterForEvent(EVENT_INVENTORY_SLOT_LOCKED, function(event, bagId, slotIndex) self:OnInventorySlotLocked(bagId, slotIndex) end)
        control:RegisterForEvent(EVENT_INVENTORY_SLOT_UNLOCKED, function(event, bagId, slotIndex) self:OnInventorySlotUnlocked(bagId, slotIndex) end)
        control:RegisterForEvent(EVENT_MOUSE_REQUEST_DESTROY_ITEM, OnRequestDestroyItem)
        control:RegisterForEvent(EVENT_CANCEL_MOUSE_REQUEST_DESTROY_ITEM, OnCancelRequestDestroyItem)
        control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
        control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
        control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
        control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshMoney)
        control:RegisterForEvent(EVENT_BANKED_MONEY_UPDATE, RefreshMoney)
        control:RegisterForEvent(EVENT_GUILD_BANKED_MONEY_UPDATE, RefreshMoney)

        --quest item events
        local function OnQuestsUpdated()
            --the quest we were planning to abandon may be gone, kill the prompt
            ZO_Dialogs_ReleaseDialog("ABANDON_QUEST")
            self:RefreshAllQuests()
            CALLBACK_MANAGER:FireCallbacks("QuestUpdate")
        end

        local function OnSingleQuestUpdated(journalIndex)
            self:RefreshQuest(journalIndex)
            CALLBACK_MANAGER:FireCallbacks("QuestUpdate")
        end

        local function OnUpdateCooldowns()
            self:UpdateItemCooldowns(INVENTORY_BACKPACK)
            self:UpdateItemCooldowns(INVENTORY_QUEST_ITEM)
        end

        SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", OnQuestsUpdated)
        SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", OnSingleQuestUpdated)

        control:RegisterForEvent(EVENT_ACTION_UPDATE_COOLDOWNS, OnUpdateCooldowns)

        --bank events
        local function OnOpenBank()
            if not IsInGamepadPreferredMode() then
                local inventoryType = self:GetBankInventoryType()
                if inventoryType == INVENTORY_BANK then
                    self:ActivateBankSearch()
                    SCENE_MANAGER:Show("bank")
                elseif inventoryType == INVENTORY_HOUSE_BANK then
                    self:ActivateHouseBankSearch()
                    SCENE_MANAGER:Show("houseBank")
                end
            end
        end

        local function OnCloseBank()
            if not IsInGamepadPreferredMode() then
                --The banking bag has already been cleared by this point so just close both of the possible scenes instead of trying to figure out which one was open
                self:DeactivateBankSearch()
                self:DeactivateHouseBankSearch()
                SCENE_MANAGER:Hide("bank")
                SCENE_MANAGER:Hide("houseBank")
                if ZO_Dialogs_IsShowingDialog() then
                    ZO_Dialogs_ReleaseAllDialogs()
                end

                self:RefreshPlayerInventorySearchContext()
            end
        end

        control:RegisterForEvent(EVENT_OPEN_BANK, OnOpenBank)
        control:RegisterForEvent(EVENT_CLOSE_BANK, OnCloseBank)

        --guild bank events
        local function OnOpenGuildBank()
            if not IsInGamepadPreferredMode() then
                self:OpenGuildBank()
            end
        end

        local function OnCloseGuildBank()
            if not IsInGamepadPreferredMode() then
                self:CloseGuildBank()
            end
        end

        local function OnGuildBankSelected(eventCode, guildId)
            self:SetGuildBankLoading(guildId)
        end

        local function OnGuildBankDeselected()
            self:OnGuildBankDeselected()
        end

        local function OnGuildBankItemsReady()
            self:SetGuildBankLoaded()
        end

        local function OnGuildBankOpenError(eventCode, error)
            self:OnGuildBankOpenError(error)
        end

        local function OnGuildSizeChanged()
            self:GuildSizeChanged()
        end

        local function OnGuildRanksChanged(eventCode, guildId)
            self:RefreshGuildBankPermissions(guildId)
        end

        local function OnGuildRankChanged(eventCode, guildId)
            self:RefreshGuildBankPermissions(guildId)
        end

        local function OnGuildMemberRankChanged(eventCode, guildId, displayName)
            if(displayName == GetDisplayName()) then
                self:RefreshGuildBankPermissions(guildId)
            end
        end

        control:RegisterForEvent(EVENT_OPEN_GUILD_BANK, OnOpenGuildBank)
        control:RegisterForEvent(EVENT_CLOSE_GUILD_BANK, OnCloseGuildBank)
        control:RegisterForEvent(EVENT_GUILD_BANK_SELECTED, OnGuildBankSelected)
        control:RegisterForEvent(EVENT_GUILD_BANK_DESELECTED, OnGuildBankDeselected)
        control:RegisterForEvent(EVENT_GUILD_BANK_ITEMS_READY, OnGuildBankItemsReady)
        control:RegisterForEvent(EVENT_GUILD_BANK_OPEN_ERROR, OnGuildBankOpenError)
        control:RegisterForEvent(EVENT_GUILD_RANKS_CHANGED, OnGuildRanksChanged)
        control:RegisterForEvent(EVENT_GUILD_RANK_CHANGED, OnGuildRankChanged)
        control:RegisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED, OnGuildMemberRankChanged)
        control:RegisterForEvent(EVENT_GUILD_MEMBER_ADDED, OnGuildSizeChanged)
        control:RegisterForEvent(EVENT_GUILD_MEMBER_REMOVED, OnGuildSizeChanged)

        --inventory upgrade events

        local function UpdateFreeSlotsBackpack()
            self:UpdateFreeSlots(INVENTORY_BACKPACK)
        end

        local function UpdateFreeSlotsBank()
            self:UpdateFreeSlots(INVENTORY_BANK)
        end

        control:RegisterForEvent(EVENT_INVENTORY_BUY_BAG_SPACE, OnBuyBagSpace)
        control:RegisterForEvent(EVENT_INVENTORY_BOUGHT_BAG_SPACE, UpdateFreeSlotsBackpack)
        control:RegisterForEvent(EVENT_MOUNT_INFO_UPDATED, UpdateFreeSlotsBackpack)
        control:RegisterForEvent(EVENT_INVENTORY_BUY_BANK_SPACE, OnBuyBankSpace)
        control:RegisterForEvent(EVENT_INVENTORY_BOUGHT_BANK_SPACE, UpdateFreeSlotsBank)
        control:RegisterForEvent(EVENT_INVENTORY_CLOSE_BUY_SPACE, OnCloseBuySpace)

        --player events

        local function RefreshAllInventoryOverlays()
            self:RefreshAllInventoryOverlays(INVENTORY_BACKPACK)
        end

        local function OnPlayerDead()
            RefreshAllInventoryOverlays()
            self.itemsLockedDueToDeath = true
        end

        local function OnPlayerAlive()
            RefreshAllInventoryOverlays()
            self.itemsLockedDueToDeath = false
        end

        control:RegisterForEvent(EVENT_PLAYER_DEAD, OnPlayerDead)
        control:RegisterForEvent(EVENT_PLAYER_ALIVE, OnPlayerAlive)
        control:RegisterForEvent(EVENT_LEVEL_UPDATE, RefreshAllInventoryOverlays)
        control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        control:RegisterForEvent(EVENT_CHAMPION_POINT_GAINED, RefreshAllInventoryOverlays)
        -- This is not ideal, but currently event filters only allow for 1 unit tag
        EVENT_MANAGER:RegisterForEvent("InventoryCompanionLevelUpdate", EVENT_LEVEL_UPDATE, RefreshAllInventoryOverlays)
        EVENT_MANAGER:AddFilterForEvent("InventoryCompanionLevelUpdate", EVENT_LEVEL_UPDATE, "companion")
        control:RegisterForEvent(EVENT_COMPANION_ACTIVATED, RefreshAllInventoryOverlays)
        control:RegisterForEvent(EVENT_COMPANION_DEACTIVATED, RefreshAllInventoryOverlays)
    end
end

--General
---------

--Selects a filter tab in this inventory type and then sorts by a key that appears under that filter tab
function ZO_InventoryManager:SelectAndChangeSort(inventoryType, tabFilterType, newSortKey, newSortOrder)
    local inventoryInfo = self.inventories[inventoryType]
    if inventoryInfo then
        local tabFilter
        for _, searchTabFilter in ipairs(inventoryInfo.tabFilters) do
            if searchTabFilter.filterType == tabFilterType then
                tabFilter = searchTabFilter
                break
            end
        end

        if tabFilter then
            self:ChangeFilter(tabFilter)
            --The sort headers change based on the selected tab filter
            inventoryInfo.sortHeaders:SelectHeaderByKey(newSortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, not ZO_SortHeaderGroup.FORCE_RESELECT, newSortOrder)
            self:ChangeSort(newSortKey, inventoryType, newSortOrder)
        end
    end
end

function ZO_InventoryManager:ChangeSort(newSortKey, inventoryType, newSortOrder)
    if self.selectedTabType == INVENTORY_QUEST_ITEM then
        inventoryType = INVENTORY_QUEST_ITEM
    end

    local inventory = self.inventories[inventoryType]
    inventory.currentSortKey = newSortKey
    inventory.currentSortOrder = newSortOrder
    inventory.lastSavedSortKey = nil
    inventory.lastSavedSortOrder = nil

    self:ApplySort(inventoryType)
end

function ZO_InventoryManager:ApplySort(inventoryType)
    local inventory
    if inventoryType == INVENTORY_BANK then
        inventory = self.inventories[INVENTORY_BANK]
    elseif inventoryType == INVENTORY_HOUSE_BANK then
        inventory = self.inventories[INVENTORY_HOUSE_BANK]
    elseif inventoryType == INVENTORY_GUILD_BANK then
        inventory = self.inventories[INVENTORY_GUILD_BANK]
    elseif inventoryType == INVENTORY_CRAFT_BAG then
        inventory = self.inventories[INVENTORY_CRAFT_BAG]
    elseif inventoryType == INVENTORY_QUEST_ITEM then
        inventory = self.inventories[INVENTORY_QUEST_ITEM]
    else
        -- Use normal inventory by default (instead of the quest item inventory for example)
        inventory = self.inventories[self.selectedTabType]
    end

    local list = inventory.listView
    local scrollData = ZO_ScrollList_GetDataList(list)

    if inventory.sortFn == nil then
        inventory.sortFn = function(entry1, entry2)
            return ZO_TableOrderingFunction(entry1.data, entry2.data, inventory.currentSortKey, SORT_KEYS, inventory.currentSortOrder)
        end
    end

    table.sort(scrollData, inventory.sortFn)
    ZO_ScrollList_Commit(list)
end

-- Deprecated function remaining for addon support.
function ZO_InventoryManager:GetDisplayInventoryTable(inventoryType)
    return self.inventories[inventoryType]
end

function ZO_InventoryManager:GetTabFilterInfo(inventoryType, tabControl)
    local inventory = self.inventories[inventoryType]
    local filterData = inventory.tabFilters[tabControl] or tabControl -- the or tabControl is for the new style, because the data table is just passed in here

    return filterData.filterType, filterData.activeTabText, filterData.hiddenColumns
end

do
    local function ForceSortDataOnInventory(inventory, sortKey, sortOrder)
        inventory.currentSortKey = sortKey
        inventory.currentSortOrder = sortOrder
    end

    function ZO_InventoryManager:ChangeFilter(filterTab)
        local inventoryType = filterTab.inventoryType
        local inventory = self.inventories[inventoryType]

        local activeTabText
        local activeSubTabText
        local formattedTabText
        if filterTab.isSubFilter then
            local currentFilter

            for _, filter in pairs(inventory.tabFilters) do
                if filter.filterType == inventory.currentFilter then
                    currentFilter = filter
                    break
                end
            end
            inventory.currentFilter, activeTabText, inventory.hiddenColumns = self:GetTabFilterInfo(inventoryType, currentFilter)
            inventory.subFilter, activeSubTabText = self:GetTabFilterInfo(inventoryType, filterTab)

            if inventory.subFilter == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
                if inventory.currentFilter == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
                    formattedTabText = zo_strformat(SI_INVENTORY_FILTER_SUB_TAB, activeTabText)
                else
                    formattedTabText = zo_strformat(SI_INVENTORY_FILTER_ALL_TAB, activeTabText)
                end
            else
                formattedTabText = zo_strformat(SI_INVENTORY_FILTER_SUB_TAB, activeSubTabText)
            end
        else
            inventory.currentFilter, activeTabText, inventory.hiddenColumns = self:GetTabFilterInfo(inventoryType, filterTab)

            formattedTabText = activeTabText
        end

        local displayInventory = self.inventories[inventoryType]
        local activeTabControl = displayInventory.activeTab
        if activeTabControl then
            activeTabControl:SetText(formattedTabText)
        end

        local currentFilterType = inventory.currentFilter
        if not filterTab.isSubFilter then
            local menuBar = inventory.subFilterBar
            if menuBar then
                for _, button in ZO_MenuBar_ButtonControlIterator(menuBar) do
                    local flash = button:GetNamedChild("Flash")
                    flash:SetAlpha(0)
                    self:RemoveCategoryFlashAnimationControl(flash)
                end

                ZO_MenuBar_ClearButtons(menuBar)

                if inventory.subFilters then
                    if inventory.subFilters[currentFilterType] then
                       for _, data in ipairs(inventory.subFilters[currentFilterType]) do
                            data.control = ZO_MenuBar_AddButton(menuBar, data)
                        end

                        ZO_MenuBar_SelectDescriptor(menuBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
                    end
                end
            end
        elseif #self.flashingSlots > 0 then
            for _, flashingSlot in ipairs(self.flashingSlots) do
                for _, subFilter in pairs(inventory.subFilters[currentFilterType]) do
                    if currentFilterType == ITEM_TYPE_DISPLAY_CATEGORY_COMPANION then
                        if ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(flashingSlot, currentFilterType, subFilter.filterType) and ZO_IndexOfElementInNumericallyIndexedTable(inventory.backingBags, flashingSlot.bagId) then
                            self:AddCategoryFlashAnimationControl(subFilter.control:GetNamedChild("Flash"))
                        end
                    elseif ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory(flashingSlot, currentFilterType, subFilter.filterType) and ZO_IndexOfElementInNumericallyIndexedTable(inventory.backingBags, flashingSlot.bagId) then
                        self:AddCategoryFlashAnimationControl(subFilter.control:GetNamedChild("Flash"))
                    end
                end
            end
        end

        -- Manage hiding columns that show/hide depending on the current filter.  If the sort was on a column that becomes hidden
        -- then the sort needs to pick a new column.
        local sortHeaders = displayInventory.sortHeaders
        if sortHeaders then
            sortHeaders:SetHeadersHiddenFromKeyList(inventory.hiddenColumns, true)

            local canUseLastSavedSortKey = inventory.lastSavedSortKey and inventory.hiddenColumns[inventory.lastSavedSortKey]
            if type(canUseLastSavedSortKey) == "function" then
                canUseLastSavedSortKey = canUseLastSavedSortKey()
            end

            local canUseCurrentSortKey = inventory.hiddenColumns[inventory.currentSortKey]
            if canUseCurrentSortKey and type(canUseCurrentSortKey) == "function" then
                canUseCurrentSortKey = canUseCurrentSortKey()
            end

            if inventory.lastSavedSortKey and not canUseLastSavedSortKey then
                -- Restore the last saved value if the header exists again
                local lastSavedSortKey = inventory.lastSavedSortKey
                local lastSavedSortOrder = inventory.lastSavedSortOrder
                sortHeaders:SelectHeaderByKey(lastSavedSortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, ZO_SortHeaderGroup.FORCE_RESELECT, lastSavedSortOrder)
                ForceSortDataOnInventory(inventory, lastSavedSortKey, lastSavedSortOrder)
                ForceSortDataOnInventory(displayInventory, lastSavedSortKey, lastSavedSortOrder)
                inventory.lastSavedSortKey = nil
                inventory.lastSavedSortOrder = nil
            elseif canUseCurrentSortKey then
                inventory.lastSavedSortKey = inventory.currentSortKey
                inventory.lastSavedSortOrder = inventory.currentSortOrder
                -- User wanted to sort by a column that's gone!
                -- Fallback to name...the default sort is "statusSortOrder", but there are filters that hide that one, so "name" is the
                -- only safe bet for now...
                sortHeaders:SelectHeaderByKey("name", ZO_SortHeaderGroup.SUPPRESS_CALLBACKS)

                -- Switch both inventory and displayInventory to the fallback
                ForceSortDataOnInventory(inventory, "name", ZO_SORT_ORDER_UP)
                ForceSortDataOnInventory(displayInventory, "name", ZO_SORT_ORDER_UP)
            else
                -- This is mostly for when in backpack inventory and we select on/off the quest item filter
                -- since the sort header object only knows of backpack but inventories have different sort values
                sortHeaders:SelectHeaderByKey(inventory.currentSortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, ZO_SortHeaderGroup.FORCE_RESELECT, inventory.currentSortOrder)
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

    self:UpdateSortOrderButtonTextures(sortButton, inventoryType)
    self:ApplySort(inventoryType)
end

function ZO_InventoryManager:ShowToggleSortOrderTooltip(anchorControl, inventoryType)
    InitializeTooltip(InformationTooltip, anchorControl, TOPRIGHT, 0, 0)

    -- Show the opposite string of the current sort order because that's what will happen when the button is clicked
    if self.inventories[inventoryType].currentSortOrder == ZO_SORT_ORDER_UP then
        SetTooltipText(InformationTooltip, GetString(SI_INVENTORY_SORT_DESCENDING_TOOLTIP))
    else
        SetTooltipText(InformationTooltip, GetString(SI_INVENTORY_SORT_ASCENDING_TOOLTIP))
    end
end

function ZO_InventoryManager:HideToggleSortOrderTooltip()
    ClearTooltip(InformationTooltip)
end

do
    local DONT_SHOW_ALL = false
    local HAS_ENOUGH = false
    function ZO_InventoryManager:RefreshMoney()
        local moneyBar, altMoneyBar = self:GetContextualMoneyControls()
        if self:IsBanking() then
            self:RefreshBankUpgradeKeybind()
            ZO_CurrencyControl_SetSimpleCurrency(moneyBar, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_KEYBOARD_CURRENCY_BANK_TOOLTIP_OPTIONS)
            if self:GetBankInventoryType() == INVENTORY_BANK then
                ZO_CurrencyControl_SetSimpleCurrency(altMoneyBar, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_BANK), ZO_KEYBOARD_CURRENCY_BANK_TOOLTIP_OPTIONS)
            end
        elseif self:IsGuildBanking() then
            ZO_CurrencyControl_SetSimpleCurrency(moneyBar, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_KEYBOARD_CURRENCY_GUILD_BANK_TOOLTIP_OPTIONS)
            local displayOptions =
            {
                obfuscateAmount = not DoesPlayerHaveGuildPermission(GetSelectedGuildBankId(), GUILD_PERMISSION_BANK_VIEW_GOLD),
            }
            ZO_CurrencyControl_SetSimpleCurrency(altMoneyBar, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_GUILD_BANK), ZO_KEYBOARD_CURRENCY_GUILD_BANK_TOOLTIP_OPTIONS, DONT_SHOW_ALL, HAS_ENOUGH, displayOptions)
        else
            ZO_CurrencyControl_SetSimpleCurrency(moneyBar, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_KEYBOARD_CURRENCY_OPTIONS)
        end
    end
end

function ZO_InventoryManager:UpdateFreeSlots(inventoryType)
    local inventory = self.inventories[inventoryType]
    local freeSlotType
    local altFreeSlotType

    if type(inventory.freeSlotType) == "function" then
        freeSlotType = inventory.freeSlotType()
    else
        freeSlotType = inventory.freeSlotType
    end

    if type(inventory.altFreeSlotType) == "function" then
        altFreeSlotType = inventory.altFreeSlotType()
    else
        altFreeSlotType = inventory.altFreeSlotType
    end

    if inventory.freeSlotsLabel then
        local freeSlotTypeInventory = self.inventories[freeSlotType]
        local numUsedSlots, numSlots = self:GetNumSlots(freeSlotType)
        if numUsedSlots < numSlots then
            inventory.freeSlotsLabel:SetText(zo_strformat(freeSlotTypeInventory.freeSlotsStringId, numUsedSlots, numSlots))
        else
            inventory.freeSlotsLabel:SetText(zo_strformat(freeSlotTypeInventory.freeSlotsFullStringId, numUsedSlots, numSlots))
        end
    end

    if inventory.altFreeSlotsLabel and altFreeSlotType then
        local numUsedSlots, numSlots = self:GetNumSlots(altFreeSlotType)
        local altFreeSlotInventory = self.inventories[altFreeSlotType] --grab the alternateInventory to use it's string id's
        if numUsedSlots < numSlots then
            inventory.altFreeSlotsLabel:SetText(zo_strformat(altFreeSlotInventory.freeSlotsStringId, numUsedSlots, numSlots))
        else
            inventory.altFreeSlotsLabel:SetText(zo_strformat(altFreeSlotInventory.freeSlotsFullStringId, numUsedSlots, numSlots))
        end
    end
end

function ZO_InventoryManager:SetupInitialFilter()
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_BACKPACK].filterBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_BANK].filterBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_HOUSE_BANK].filterBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_GUILD_BANK].filterBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_CRAFT_BAG].filterBar, ITEM_TYPE_DISPLAY_CATEGORY_ALL)
end

function ZO_InventoryManager:SetupCategoryFlashAnimation()
    self.categoryFlashAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_Inventory_NewItemCategory_FlashAnimation")
    self.flashingSlots = {}
    self.listeningControls = {}

    local function OnStop()
        self.flashingSlots = {}
        self.listeningControls = {}
    end
    self.categoryFlashAnimationTimeline:SetHandler("OnStop", OnStop)
end

function ZO_InventoryManager:AddCategoryFlashAnimationControl(control)
    local controlName = control:GetName()
    self.listeningControls[controlName] = control
end

function ZO_InventoryManager:RemoveCategoryFlashAnimationControl(control)
    local controlName = control:GetName()
    self.listeningControls[controlName] = nil
end

do
    local FLASH_ANIMATION_MIN_ALPHA = 0
    local FLASH_ANIMATION_MAX_ALPHA = 0.5
    function ZO_InventoryManager:UpdateCategoryFlashAnimation(timeline, progress)
        local remainingPlaybackLoops = self.categoryFlashAnimationTimeline:GetPlaybackLoopsRemaining()
        local currentAlpha
        local alphaDelta = progress * (FLASH_ANIMATION_MAX_ALPHA - FLASH_ANIMATION_MIN_ALPHA)
        if remainingPlaybackLoops % 2 then
            -- Fading out
            currentAlpha = alphaDelta + FLASH_ANIMATION_MIN_ALPHA
        else
            -- Fading in
            currentAlpha = FLASH_ANIMATION_MAX_ALPHA - alphaDelta
        end

        for _, control in pairs(self.listeningControls) do
            control:SetAlpha(currentAlpha)
        end
    end
end

function ZO_InventoryManager:PlayItemAddedAlert(slot, inventory)
    if self.suppressItemAddedAlert then
        return
    end

    local isSlotAdded = false
    for _, tabFilter in pairs(inventory.tabFilters) do
        if slot.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            if tabFilter.filterType == ITEM_TYPE_DISPLAY_CATEGORY_COMPANION then
                self:AddCategoryFlashAnimationControl(tabFilter.control:GetNamedChild("Flash"))
                if not self.categoryFlashAnimationTimeline:IsPlaying() then
                    self.categoryFlashAnimationTimeline:PlayFromStart()
                end
                if not isSlotAdded then
                    table.insert(self.flashingSlots, slot)
                    slotAdded = true
                end
            end
        else
            for _, data in ipairs(slot.filterData) do
                local filterItemTypeDisplayCategory = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryByItemFilterType(data)
                if filterItemTypeDisplayCategory == tabFilter.filterType or tabFilter.filterType == ITEM_TYPE_DISPLAY_CATEGORY_ALL then
                    self:AddCategoryFlashAnimationControl(tabFilter.control:GetNamedChild("Flash"))
                    if not self.categoryFlashAnimationTimeline:IsPlaying() then
                        self.categoryFlashAnimationTimeline:PlayFromStart()
                    end
                    if not isSlotAdded then
                        table.insert(self.flashingSlots, slot)
                        slotAdded = true
                    end
                    break
                end
            end
        end
    end

    local currentFilter = inventory.currentFilter
    for _, subFilter in pairs(inventory.subFilters[currentFilter]) do
        if currentFilter == ITEM_TYPE_DISPLAY_CATEGORY_COMPANION then
            if ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(slot, currentFilter, subFilter.filterType) then
                self:AddCategoryFlashAnimationControl(subFilter.control:GetNamedChild("Flash"))
            end
            if not isSlotAdded then
                table.insert(self.flashingSlots, slot)
                slotAdded = true
            end
        elseif ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory(slot, currentFilter, subFilter.filterType) then
            self:AddCategoryFlashAnimationControl(subFilter.control:GetNamedChild("Flash"))
            if not self.categoryFlashAnimationTimeline:IsPlaying() then
                self.categoryFlashAnimationTimeline:PlayFromStart()
            end
            if not isSlotAdded then
                table.insert(self.flashingSlots, slot)
                slotAdded = true
            end
        end
    end
end

function ZO_InventoryManager:UpdateApparelSection()
    if ZO_CharacterApparelSectionText then
        local isApparelHidden = IsEquipSlotVisualCategoryHidden(EQUIP_SLOT_VISUAL_CATEGORY_APPAREL, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        local apparelString = isApparelHidden and GetString(SI_CHARACTER_EQUIP_APPAREL_HIDDEN) or GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_APPAREL)
        ZO_CharacterApparelSectionText:SetText(apparelString)
    end
end

--Inventory Item
----------------

function ZO_InventoryManager:AddInventoryItem(inventoryType, slotIndex, bagId)
    local inventory = self.inventories[inventoryType]
    if inventory.backingBags then
        -- Default bagId to backingBags[1] for addon backwards-compatibility
        bagId = bagId or inventory.backingBags[1]
        inventory.slots[bagId][slotIndex] = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
    end
end

function ZO_InventoryManager:UpdateNewStatus(inventoryType, slotIndex, bagId)
    local inventory = self.inventories[inventoryType]
    if inventory.backingBags then
        -- Default bagId to backingBags[1] for addon backwards-compatibility
        bagId = bagId or inventory.backingBags[1]

        -- might not have the slot data yet depending on who is calling this and when, this will ensure we have the correct data
        -- if the slot data was already created this will essentially be a no-op (some table lookups)
        self:AddInventoryItem(inventoryType, slotIndex, bagId)
        local slot = inventory.slots[bagId][slotIndex]
        if slot and slot.age ~= 0 then
            slot.clearAgeOnClose = true
        end
    end
end

function ZO_InventoryManager:GetNumSlots(inventoryType, excludeUnavailable)
    local inventory = self.inventories[inventoryType]
    local usedSlots = 0
    local bagSize = 0

    if inventory.backingBags then
        for _, bagId in ipairs(inventory.backingBags) do
            usedSlots = usedSlots + GetNumBagUsedSlots(bagId)
            bagSize = bagSize + GetBagUseableSize(bagId)
        end
    end

    return usedSlots, bagSize
end

function ZO_InventoryManager:OnInventoryItemRemoved(inventoryType, bagId, slotIndex, oldSlotData, suppressItemAlert)
    TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, suppressItemAlert)
end

function ZO_InventoryManager:OnInventoryItemAdded(inventoryType, bagId, slotIndex, newSlotData, suppressItemAlert)
    local inventory = self.inventories[inventoryType]
    newSlotData.searchData =
    {
        type = ZO_TEXT_SEARCH_TYPE_INVENTORY,
        bagId = bagId,
        slotIndex = slotIndex,
    }

    newSlotData.inventory = inventory

    TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, suppressItemAlert or self.suppressItemAddedAlert)

    -- play a brief flash animation on all the filter tabs that match this item's filterTypes
    if newSlotData.brandNew then
        if INVENTORY_FRAGMENT:IsShowing() then
            self:PlayItemAddedAlert(newSlotData, inventory)
        else
            table.insert(self.newItemList, newSlotData)
        end
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
        for _, slotData in pairs(slots) do
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
        if inventory.backingBags then
            if inventory.hasAnyQuickSlottableItems == nil then
                for _, bagId in ipairs(inventory.backingBags) do
                    inventory.hasAnyQuickSlottableItems = HasAnyQuickSlottableItems(inventory.slots[bagId])
                end
            end
            return inventory.hasAnyQuickSlottableItems
        else
            return false
        end
    end
end

local function DoesSlotPassAdditionalFilter(slot, currentFilter, additionalFilter)
    if type(additionalFilter) == "function" then
        return additionalFilter(slot)
    elseif type(additionalFilter) == "number" then
        return ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory(slot, currentFilter, additionalFilter)
    end

    return true
end

function ZO_InventoryManager:ShouldAddSlotToList(inventory, slot)
    if not slot or slot.stackCount <= 0 then
        return false
    end

    if slot.questItemId then
        if not TEXT_SEARCH_MANAGER:IsDataInSearchTextResults(inventory.currentContext, BACKGROUND_LIST_FILTER_TARGET_QUEST_ITEM_ID, slot.questItemId) then
            return false
        end
    elseif not TEXT_SEARCH_MANAGER:IsDataInSearchTextResults(inventory.currentContext, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, slot.bagId, slot.slotIndex) then
        return false
    end

    local currentFilter = inventory.currentFilter

    if not DoesSlotPassAdditionalFilter(slot, currentFilter, inventory.subFilter) then
        return false
    end

    if not DoesSlotPassAdditionalFilter(slot, currentFilter, inventory.additionalFilter) then
        return false
    end

    if self.appliedLayout and self.appliedLayout.additionalFilter and not DoesSlotPassAdditionalFilter(slot,  currentFilter, self.appliedLayout.additionalFilter) then
        return false
    end

    if type(currentFilter) == "function" then
        return currentFilter(slot)
    else
        return ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, currentFilter)
    end
end

function ZO_InventoryManager:UpdateList(inventoryType, updateEvenIfHidden)
    local inventory = self.inventories[inventoryType]
    --Only need slots to update the list, not a backing bag (quest items have no backing bag but create slots)
    if inventory.slots then
        local list = inventory.listView
        if (list and not list:IsHidden()) or updateEvenIfHidden then
            local scrollData = ZO_ScrollList_GetDataList(list)
            ZO_ScrollList_Clear(list)

            -- TODO: possibly change the quest item implementation to just be a list of slots instead of being indexed by questIndex/slot
            -- For now just write two different iteration functions for quest/real inventories.

            if inventoryType == INVENTORY_QUEST_ITEM then
                local questItems = inventory.slots
                for _, questItemTable in pairs(questItems) do
                    for _, slotData in ipairs(questItemTable) do
                        if self:ShouldAddSlotToList(inventory, slotData) then
                            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(inventory.listDataType, slotData))
                        end
                    end
                end
            else
                if self:ShouldAddEntries(inventoryType) then
                    local slots = inventory.slots
                    for _, bagId in ipairs(inventory.backingBags) do
                        if slots[bagId] then
                            for _, slotData in pairs(slots[bagId]) do
                                if self:ShouldAddSlotToList(inventory, slotData) then
                                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(inventory.listDataType, slotData))
                                end
                            end
                        end
                    end
                end
            end

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
end

function ZO_InventoryManager:ShouldAddEntries(inventoryType)
    local guildId = GetSelectedGuildBankId()
    return inventoryType ~= INVENTORY_BACKPACK or not self:IsGuildBanking() or (DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_DEPOSIT) and DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_BANK_DEPOSIT))  
end

function ZO_InventoryManager:EmptyInventory(inventory)
    if inventory then
        if inventory.backingBags then
            for _, bagId in ipairs(inventory.backingBags) do
                if inventory.slots[bagId] then
                    ZO_ClearTable(inventory.slots[bagId])
                end
            end
            inventory.hasAnyQuickSlottableItems = nil
        end
    end
end

function ZO_InventoryManager:RefreshAllInventorySlots(inventoryType)
    local inventory = self.inventories[inventoryType]
    if inventory.backingBags then
        self:EmptyInventory(inventory)

        self.suppressItemAddedAlert = true

        for _, bagId in ipairs(inventory.backingBags) do
            for slotIndex in ZO_IterateBagSlots(bagId) do
                self:AddInventoryItem(inventoryType, slotIndex, bagId)
            end
        end

        if inventoryType == INVENTORY_BACKPACK then
            CALLBACK_MANAGER:FireCallbacks("BackpackFullUpdate")
        end

        self:LayoutInventoryItems(inventoryType)

        self.suppressItemAddedAlert = nil
        TEXT_SEARCH_MANAGER:ExecutePendingContextSearches()
    end
end

function ZO_InventoryManager:RefreshInventorySlot(inventoryType, slotIndex, bagId)
    local inventory = self.inventories[inventoryType]

    if inventory.backingBags then       
        -- Default bagId to backingBags[1] for addon backwards-compatibility
        bagId = bagId or inventory.backingBags[1]

        inventory.hasAnyQuickSlottableItems = nil
        self:AddInventoryItem(inventoryType, slotIndex, bagId)

        if inventoryType == INVENTORY_BACKPACK then
            CALLBACK_MANAGER:FireCallbacks("BackpackSlotUpdate", slotIndex)
        end

        -- Rebuild the entire list, refilter, and resort every time a single item is updated...sadness.
        self:LayoutInventoryItems(inventoryType)

        local slot = inventory.slots[bagId][slotIndex]

        if slot and slot.slotControl then
            CALLBACK_MANAGER:FireCallbacks("InventorySlotUpdate", slot.slotControl:GetNamedChild("Button"))
        end
    end
end

function ZO_InventoryManager:LayoutInventoryItems(inventoryType)
    self:UpdateList(inventoryType)
    self:UpdateFreeSlots(inventoryType)
end

-- This function only refreshes the 'traditional' slotted bags: backpack and bank
function ZO_InventoryManager:RefreshAllInventoryOverlays(inventoryType)
    local inventory = self.inventories[inventoryType]
    if inventory.backingBags then
        for _, bagId in ipairs(inventory.backingBags) do
            local numSlots = GetBagSize(bagId)
            for slotIndex = 0, numSlots - 1 do
                self:RefreshInventorySlotOverlay(inventoryType, slotIndex, bagId)
            end
        end
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

    local function TryClearNewStatus(inventory, bagId, slotIndex, inventoryManager)
        local slot = inventory.slots[bagId][slotIndex]
        if ShouldClearAgeOnClose(slot, inventoryManager) then
            slot.clearAgeOnClose = nil
            SHARED_INVENTORY:ClearNewStatus(bagId, slotIndex)
            return true
        else
            return false
        end
    end

    function ZO_InventoryManager:ClearNewStatusOnItemsThePlayerHasSeen(inventoryType)
        local inventory = self.inventories[inventoryType]
        if inventory.backingBags then
            local anyNewStatusCleared = false
            for _, bagId in ipairs(inventory.backingBags) do
                for slotIndex in ZO_IterateBagSlots(bagId) do
                    local newStatusCleared = TryClearNewStatus(inventory, bagId, slotIndex, self)
                    anyNewStatusCleared = anyNewStatusCleared or newStatusCleared
                end
            end

            if anyNewStatusCleared then
                if inventory.currentSortKey == "statusSortOrder" then
                    self:ApplySort(inventoryType)
                end

                if inventory.listView then
                    local REFRESH_ALL_DATA = nil
                    ZO_ScrollList_RefreshVisible(inventory.listView, REFRESH_ALL_DATA, ZO_UpdateStatusControlIcons)
                end

                if MAIN_MENU_KEYBOARD then
                    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
                end
            end
        end
    end
end

function ZO_InventoryManager:RefreshInventorySlotLocked(inventoryType, slotIndex, locked, bagId)
    local inventory = self.inventories[inventoryType]
    if inventory.backingBags then
        -- Default bagId to backingBags[1] for addon backwards-compatibility
        bagId = bagId or inventory.backingBags[1]

        if inventory.slots then
            local bag = inventory.slots[bagId]
            if bag then
                local slot = bag[slotIndex]
                if slot and slot.locked ~= locked then
                    slot.locked = locked
                    if inventory.listView and slot.slotControl then
                        ZO_PlayerInventorySlot_SetupUsableAndLockedColor(slot.slotControl, slot.meetsUsageRequirement, slot.locked)
                        CALLBACK_MANAGER:FireCallbacks("InventorySlotUpdate", slot.slotControl:GetNamedChild("Button"))
                    end
                end
            end
        end
    end
end

function ZO_InventoryManager:RefreshInventorySlotOverlay(inventoryType, slotIndex, bagId)
    local inventory = self.inventories[inventoryType]
    if inventory.backingBags then
        -- Default bagId to backingBags[1] for addon backwards-compatibility
        bagId = bagId or inventory.backingBags[1]

        local slot = inventory.slots[bagId][slotIndex]
        if slot then
            local _, _, _, meetsUsageRequirement = GetItemInfo(bagId, slotIndex)
            local isLocalPlayerDead = IsUnitDead("player")
            local isLocked = slot.locked or isLocalPlayerDead

            if meetsUsageRequirement ~= slot.meetsUsageRequirement or isLocalPlayerDead ~= self.itemsLockedDueToDeath then
                slot.meetsUsageRequirement = meetsUsageRequirement
                if slot.slotControl then
                    ZO_PlayerInventorySlot_SetupUsableAndLockedColor(slot.slotControl, slot.meetsUsageRequirement, isLocked)
                    CALLBACK_MANAGER:FireCallbacks("InventorySlotUpdate", slot.slotControl:GetNamedChild("Button"))
                end
            end
        end
    end
end

function ZO_InventoryManager:UpdateItemCooldowns(inventoryType)
    local inventory = self.inventories[inventoryType]
    if inventory.listView then
        ZO_ScrollList_RefreshVisible(inventory.listView, nil, ZO_InventorySlot_UpdateCooldowns)
    end
end

function ZO_InventoryManager:IsSlotOccupied(bagId, slotIndex)
    local inventoryType = self.bagToInventoryType[bagId]
    local slot = self.inventories[inventoryType].slots[bagId][slotIndex]

    return slot ~= nil and slot.stackCount > 0
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
            if inventory.backingBags then
                for _, bagId in ipairs(inventory.backingBags) do
                    for slotIndex in ZO_IterateBagSlots(bagId) do
                        local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
                        if itemInstanceId == specificItemInstanceId then
                            data = UpdateItemTable(bagId, slotIndex, predicate, data)
                        end
                    end
                end
            end
        end
        return data
    end

    --where ... are inventory types
    function ZO_InventoryManager:GenerateAllSlotsInVirtualStackedItem(predicate, specificItemInstanceId, ...)
        local matchingSlots = {}
        for i = 1, select("#", ...) do
            local inventoryType = select(i, ...)
            local inventory = self.inventories[inventoryType]
            if inventory.backingBags then
                for _, bagId in ipairs(inventory.backingBags) do
                    for slotIndex in ZO_IterateBagSlots(bagId) do
                        local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
                        if itemInstanceId == specificItemInstanceId and (predicate == nil or predicate(bagId, slotIndex)) then
                            local _, stackCount = GetItemInfo(bagId, slotIndex)
                            table.insert(matchingSlots, {bagId = bagId, slotIndex = slotIndex, stackCount = stackCount})
                        end
                    end
                end
            end
        end
        return matchingSlots
    end

    function ZO_InventoryManager:GenerateListOfVirtualStackedItems(inventoryType, predicate, itemIds)
        local inventory = self.inventories[inventoryType]
        itemIds = itemIds or {}

        if inventory.backingBags then
            for _, bagId in ipairs(inventory.backingBags) do
                self:GenerateListOfVirtualStackedItemsFromBag(bagId, predicate, itemIds)
            end
        end

        return itemIds
    end

    function ZO_InventoryManager:GenerateListOfVirtualStackedItemsFromBag(bagId, predicate, itemIds)
        local itemData
        for slotIndex in ZO_IterateBagSlots(bagId) do
            local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
            if itemInstanceId then
                itemData = itemIds[itemInstanceId]
                itemIds[itemInstanceId] = UpdateItemTable(bagId, slotIndex, predicate, itemData)
            end
        end
    end
end

--Backpack
----------

function ZO_InventoryManager:GetNumBackpackSlots()
    local inventory = self.inventories[INVENTORY_BACKPACK]
    local backpackSize = 0
    if inventory.backingBags then
        for _, bagId in ipairs(inventory.backingBags) do
            backpackSize = backpackSize + GetBagSize(bagId)
        end
    end
    return backpackSize
end

function ZO_InventoryManager:GetBackpackItem(slotIndex, bagId)
    local inventory = self.inventories[INVENTORY_BACKPACK]

    -- Default bagId to backingBags[1] for addon backwards-compatibility
    bagId = bagId or inventory.backingBags[1]
    return inventory.slots[bagId][slotIndex]
end

function ZO_InventoryManager:IsShowingBackpack()
    return not ZO_PlayerInventory:IsHidden()
end

function ZO_InventoryManager:ApplyBackpackLayout(layoutData)
    if layoutData == self.appliedLayout and not layoutData.alwaysReapplyLayout then
        return
    end

    self.appliedLayout = layoutData

    self:ApplySharedBagLayout(ZO_PlayerInventory, layoutData)
    self:ApplySharedBagLayout(ZO_CraftBag, layoutData)

    local inventory = self.inventories[INVENTORY_BACKPACK]
    inventory.additionalFilter = layoutData.additionalFilter

    local craftBag = self.inventories[INVENTORY_CRAFT_BAG]
    craftBag.additionalFilter = layoutData.additionalCraftBagFilter

    local menuBar = inventory.filterBar

    ZO_MenuBar_ClearButtons(menuBar)
    for _, filterData in ipairs(inventory.tabFilters) do
        if not layoutData.hiddenFilters or not layoutData.hiddenFilters[filterData.filterType] then
            ZO_MenuBar_AddButton(menuBar, filterData)
        end
    end

    local selectedTab = layoutData.selectedTab or ITEM_TYPE_DISPLAY_CATEGORY_ALL
    ZO_MenuBar_SelectDescriptor(self.inventories[INVENTORY_BACKPACK].filterBar, selectedTab)

    local hideBankInfo = layoutData.hideBankInfo
    local hideCurrencyInfo = layoutData.hideCurrencyInfo

    ZO_PlayerInventoryInfoBarMoney:SetHidden(hideCurrencyInfo)
    ZO_PlayerInventoryInfoBarAltMoney:SetHidden(hideBankInfo or hideCurrencyInfo)
    ZO_PlayerInventoryInfoBarAltFreeSlots:SetHidden(hideBankInfo)

    ZO_CraftBagInfoBarMoney:SetHidden(hideCurrencyInfo)
    ZO_CraftBagInfoBarAltMoney:SetHidden(hideBankInfo or hideCurrencyInfo)
    ZO_CraftBagInfoBarAltFreeSlots:SetHidden(hideBankInfo)

    local useSearchBar = layoutData.useSearchBar
    ZO_PlayerInventorySearchFilters:SetHidden(not useSearchBar)

    local hideTabBar = layoutData.hideTabBar
    ZO_PlayerInventoryTabs:SetHidden(hideTabBar)
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
    emptyLabel:SetAnchor(TOPLEFT, inventoryControl, TOPLEFT, 50, layoutData.emptyLabelOffsetY)
    emptyLabel:SetAnchor(TOPRIGHT, inventoryControl, TOPRIGHT, -50, layoutData.emptyLabelOffsetY)

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
    questItem.slotIndex = questIndex
    table.insert(inventory.slots[questIndex], questItem)
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
            local searchType = questItem.toolIndex and ZO_TEXT_SEARCH_TYPE_QUEST_TOOL or ZO_TEXT_SEARCH_TYPE_QUEST_ITEM
            self:AddQuestItem(questItem, searchType)
        end
    end

    if doLayout then
        self:UpdateList(INVENTORY_QUEST_ITEM)
    end
end

function ZO_InventoryManager:ResetQuest(questIndex)
    local inventory = self.inventories[INVENTORY_QUEST_ITEM]
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
ZO_WITHDRAW_DEPOSIT_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT = 50

local ZO_BankGenericCurrencyDepositWithdrawDialog = ZO_InitializingObject:Subclass()

function ZO_BankGenericCurrencyDepositWithdrawDialog:Initialize(prefix, currencyBankLocation, canWithdrawFunction)
    local control = CreateControlFromVirtual(prefix .. "CurrencyTransferDialog", GuiRoot, "ZO_PlayerBankDepositWithdrawCurrency")

    self.control = control
    self.depositWithdrawButton = control:GetNamedChild("DepositWithdraw")
    local container = control:GetNamedChild("Container")
    local headersContainer = container:GetNamedChild("Headers")
    self.withdrawDepositCurrencyHeaderLabel = headersContainer:GetNamedChild("WithdrawDeposit")
    local amountsContainer = container:GetNamedChild("Amounts")
    self.carriedCurrencyLabel = amountsContainer:GetNamedChild("Carried")
    self.bankedCurrencyLabel = amountsContainer:GetNamedChild("Banked")
    local currenciesComboBoxControl = amountsContainer:GetNamedChild("ComboBox")
    self.depositWithdrawCurrency = container:GetNamedChild("DepositWithdrawCurrency")

    self.currencyBankLocation = currencyBankLocation
    self.canWithdrawFunction = canWithdrawFunction

    for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
        if CanCurrencyBeStoredInLocation(currencyType, currencyBankLocation) then
            if not self.currencyType then
                self.currencyType = currencyType
            end
            if self.singularCurrency == nil then
                self.singularCurrency = true
            elseif self.singularCurrency == true then
                self.singularCurrency = false
            end
        end
    end

    if self.singularCurrency then
        self.carriedCurrencyLabel:SetHidden(false)
        self.bankedCurrencyLabel:SetHidden(false)
    else
        local comboBox = ZO_ComboBox_ObjectFromContainer(currenciesComboBoxControl)
        comboBox:SetSortsItems(false)
        comboBox:SetFont("ZoFontWinT1")
        comboBox:SetSpacing(15)
        comboBox:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
        comboBox:SetHeight(300)

        local function SetupScrollableEntry(control, data, ...)
            data.m_dropdownObject:SetupEntry(control, data, ...)
        end
        comboBox:AddCustomEntryTemplate("ZO_DepositWithdrawComboBoxEntry", ZO_WITHDRAW_DEPOSIT_COMBO_BOX_ENTRY_TEMPLATE_HEIGHT, SetupScrollableEntry)

        self.currenciesComboBox = comboBox
        currenciesComboBoxControl:SetHidden(false)

        local function OnMouseEnter()
            comboBox.m_selectedItemText.type = self.currencyType
            ZO_CurrencyTemplate_OnMouseEnter(comboBox.m_selectedItemText)
        end
        local function OnMouseExit()
            ZO_CurrencyTemplate_OnMouseExit(comboBox.m_selectedItemText)
        end
        comboBox:SetMouseOverCallbacks(OnMouseEnter, OnMouseExit)
    end

    self.withdrawDialogName = prefix.."_WITHDRAW_GOLD"
    ZO_Dialogs_RegisterCustomDialog(self.withdrawDialogName,
    {
        customControl = control,
        title =
        {
            text = SI_BANK_WITHDRAW_CURRENCY,
        },
        setup = function(dialog)
            self.withdrawMode = true
            self.depositWithdrawButton:SetState(BSTATE_NORMAL, false) --reenable in case deposit disabled it and the user cancelled
            local ON_CURRENCY_CHANGED_CALLBACK = nil
            ZO_DefaultCurrencyInputField_Initialize(self.depositWithdrawCurrency, ON_CURRENCY_CHANGED_CALLBACK, self.currencyType)
            self.withdrawDepositCurrencyHeaderLabel:SetText(GetString(SI_BANK_CURRENCY_VALUE_ENTRY_WITHDRAW_HEADER))
            self:UpdateMoneyInputAndDisplay()
            self:FocusInput()
        end,
        buttons =
        {
            {
                control = self.depositWithdrawButton,
                text = SI_BANK_WITHDRAW_BIND,
                callback = function(dialog)
                                local amount = ZO_DefaultCurrencyInputField_GetCurrency(self.depositWithdrawCurrency)
                                if amount > 0 then
                                    TransferCurrency(self.currencyType, amount, self.currencyBankLocation, GetCurrencyPlayerStoredLocation(self.currencyType))
                                end
                            end,
            },
            {
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            }
        }
    })

    self.depositDialogName = prefix.."_DEPOSIT_GOLD"
    ZO_Dialogs_RegisterCustomDialog(self.depositDialogName,
    {
        customControl = control,
        title =
        {
            text = SI_BANK_DEPOSIT_CURRENCY,
        },
        setup = function(dialog)
            self.withdrawMode = false
            ZO_DefaultCurrencyInputField_Initialize(self.depositWithdrawCurrency, function(_, amount) self:OnCurrencyInputAmountChanged(amount) end, self.currencyType)
            self.withdrawDepositCurrencyHeaderLabel:SetText(GetString(SI_BANK_CURRENCY_VALUE_ENTRY_DEPOSIT_HEADER))
            self:UpdateMoneyInputAndDisplay()
            self:FocusInput()
        end,
        buttons =
        {
            {
                control = self.depositWithdrawButton,
                text = SI_BANK_DEPOSIT_BIND,
                callback = function(dialog)
                                local amount = ZO_DefaultCurrencyInputField_GetCurrency(self.depositWithdrawCurrency)
                                if amount > 0 then
                                    TransferCurrency(self.currencyType, amount, GetCurrencyPlayerStoredLocation(self.currencyType), self.currencyBankLocation)
                                end
                            end,
            },
            {
                control = self.control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            }
        }
    })

    control:RegisterForEvent(EVENT_CURRENCY_UPDATE, function(_, ...) self:OnCurrencyUpdate(...) end)
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:IsShowing()
    return ZO_Dialogs_IsShowing(self.withdrawDialogName) or ZO_Dialogs_IsShowing(self.depositDialogName)
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:OnCurrencyUpdate(currencyType, currencyLocation, newAmount, oldAmount, reason)
    if self:IsShowing() then
        if currencyType == self.currencyType then
            if currencyLocation == self.currencyBankLocation or currencyLocation == GetCurrencyPlayerStoredLocation(self.currencyType) then
                self:UpdateMoneyInputAndDisplay()
            end
        end
    end
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:UpdateMoneyInputAndDisplay()
    local currentCurrencyType = self.currencyType
    local obfuscateAmount = self.canWithdrawFunction and not self.canWithdrawFunction() or false
    if self.singularCurrency then
        local bankedAmount = GetCurrencyAmount(currentCurrencyType, self.currencyBankLocation)
        local carriedAmount = GetCurrencyAmount(currentCurrencyType, GetCurrencyPlayerStoredLocation(self.currencyType))
        ZO_CurrencyControl_SetSimpleCurrency(self.bankedCurrencyLabel, CURT_MONEY, bankedAmount)
        ZO_CurrencyControl_SetSimpleCurrency(self.carriedCurrencyLabel, CURT_MONEY, carriedAmount)
    else
        local comboBox = self.currenciesComboBox
        comboBox:ClearItems()

        local function OnFilterChanged(control, entryText, entry)
            self:ChangeCurrencyType(entry.currencyType)
        end

        local currentlySelectedItemEntryIndex
        local entryIndex = 1
        for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
            if CanCurrencyBeStoredInLocation(currencyType, self.currencyBankLocation) then
                local bankedAmount = GetCurrencyAmount(currencyType, self.currencyBankLocation)
                local carriedAmount = GetCurrencyAmount(currencyType, GetCurrencyPlayerStoredLocation(currencyType))
                local bankedText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(bankedAmount, DONT_USE_SHORT_FORMAT, currencyType, NOT_IS_GAMEPAD, obfuscateAmount)
                local carriedText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(carriedAmount, DONT_USE_SHORT_FORMAT, currencyType)
                local combinedText = zo_strformat(SI_BANK_CURRENCY_TRANSFER_CURRENCY_PAIR_FORMAT, bankedText, carriedText)
                local entry = comboBox:CreateItemEntry(combinedText, OnFilterChanged)
                ZO_ComboBox.SetItemEntryCustomTemplate(entry, "ZO_DepositWithdrawComboBoxEntry")
                local function onMouseEnter(comboBox, control)
                    control.type = control.m_data.dataSource.currencyType
                    ZO_CurrencyTemplate_OnMouseEnter(control)
                end
                local function onMouseExit(comboBox, control)
                    ZO_CurrencyTemplate_OnMouseExit(control)
                end
                comboBox:SetEntryMouseOverCallbacks(onMouseEnter, onMouseExit)
                entry.currencyType = currencyType
                comboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
                if currencyType == currentCurrencyType then
                    currentlySelectedItemEntryIndex = entryIndex
                end
                entryIndex = entryIndex + 1
            end
        end

        if currentlySelectedItemEntryIndex then
            comboBox:SelectItemByIndex(currentlySelectedItemEntryIndex)
        else
            comboBox:SelectFirstItem()
        end
    end
    if self.withdrawMode then
        ZO_DefaultCurrencyInputField_SetCurrencyMax(self.depositWithdrawCurrency, GetMaxCurrencyTransfer(self.currencyType, self.currencyBankLocation, GetCurrencyPlayerStoredLocation(self.currencyType)))
    else
        ZO_DefaultCurrencyInputField_SetCurrencyMax(self.depositWithdrawCurrency, GetMaxCurrencyTransfer(self.currencyType, GetCurrencyPlayerStoredLocation(self.currencyType), self.currencyBankLocation))
    end

    ZO_DefaultCurrencyInputField_SetCurrencyType(self.depositWithdrawCurrency, self.currencyType)
    self:FocusInput()
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:OnCurrencyInputAmountChanged(currencyAmount)
    if currencyAmount > 0 then
        self.depositWithdrawButton:SetState(BSTATE_NORMAL, false)
    else
        self.depositWithdrawButton:SetState(BSTATE_DISABLED, true)
    end
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:FocusInput()
    self.depositWithdrawCurrency.OnBeginInput()
end

function ZO_BankGenericCurrencyDepositWithdrawDialog:ChangeCurrencyType(currencyType)
    if self.currencyType ~= currencyType then
        self.currencyType = currencyType
        self:UpdateMoneyInputAndDisplay()
    end
end

function ZO_InventoryManager:CreateBankScene()
    BANK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_PlayerBank)
    BANK_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                        if newState == SCENE_SHOWING then
                                                            if self.inventories[INVENTORY_BANK].searchBox then
                                                                self.inventories[INVENTORY_BANK].searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(self.inventories[INVENTORY_BANK].currentContext))
                                                            end

                                                            self:RefreshMoney()
                                                            self:UpdateFreeSlots(INVENTORY_BANK)

                                                            if self.isListDirty[INVENTORY_BANK] then
                                                                local UPDATE_EVEN_IF_HIDDEN = true
                                                                self:UpdateList(INVENTORY_BANK, UPDATE_EVEN_IF_HIDDEN)
                                                            end
                                                        end
                                                    end)

    ZO_BankGenericCurrencyDepositWithdrawDialog:New("BANK", CURRENCY_LOCATION_BANK)

    ZO_PlayerBankInfoBarAltMoney:SetHidden(false)
    ZO_PlayerBankInfoBarAltFreeSlots:SetHidden(false)

    self.bankWithdrawTabKeybindButtonGroup =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local cost = GetNextBankUpgradePrice()
                if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= cost then
                    return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_Currency_FormatKeyboard(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON))
                end
                return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_Currency_FormatKeyboard(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON))
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = IsBankUpgradeAvailable,
            callback = DisplayBankUpgrade,
        },
        {
            name = GetString(SI_BANK_WITHDRAW_CURRENCY_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() ZO_Dialogs_ShowDialog("BANK_WITHDRAW_GOLD") end,
        },
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_QUINARY",
            callback = function()
                StackBag(BAG_BANK)
            end,
        }
    }

    self.bankDepositTabKeybindButtonGroup =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_BANK_DEPOSIT_CURRENCY_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() ZO_Dialogs_ShowDialog("BANK_DEPOSIT_GOLD") end,
        },
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_QUINARY",
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
    bankFragmentBar:Add(SI_BANK_WITHDRAW, { BANK_FRAGMENT, BACKPACK_BANK_LAYOUT_FRAGMENT }, withdrawButtonData, self.bankWithdrawTabKeybindButtonGroup)

    --Deposit Button
    local depositButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_deposit_up.dds",
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_down.dds",
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_over.dds")
    bankFragmentBar:Add(SI_BANK_DEPOSIT, { INVENTORY_FRAGMENT, BACKPACK_BANK_LAYOUT_FRAGMENT }, depositButtonData, self.bankDepositTabKeybindButtonGroup)

    local bankScene = ZO_InteractScene:New("bank", SCENE_MANAGER, BANKING_INTERACTION)
    bankScene:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if newState == SCENE_SHOWING then
                                                        bankFragmentBar:SelectFragment(SI_BANK_WITHDRAW)
                                                        self:RefreshAllInventorySlots(INVENTORY_BANK)

                                                        TriggerTutorial(TUTORIAL_TRIGGER_ACCOUNT_BANK_OPENED)
                                                        if IsESOPlusSubscriber() then
                                                            TriggerTutorial(TUTORIAL_TRIGGER_BANK_OPENED_AS_SUBSCRIBER)
                                                        end
                                                    elseif newState == SCENE_HIDDEN then
                                                        ZO_InventorySlot_RemoveMouseOverKeybinds()
                                                        bankFragmentBar:Clear()
                                                    end
                                                end)
end

function ZO_InventoryManager:IsBanking()
    return IsBankOpen()
end

function ZO_InventoryManager:GetBankInventoryType()
    local bankingBag = GetBankingBag()
    if bankingBag == BAG_BANK then
        return INVENTORY_BANK
    elseif IsHouseBankBag(bankingBag) then
        return INVENTORY_HOUSE_BANK
    end
end

function ZO_InventoryManager:RefreshBankUpgradeKeybind()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.bankWithdrawTabKeybindButtonGroup)
end

function ZO_InventoryManager:GetBankItem(slotIndex, bagId)
    local inventory = self.inventories[INVENTORY_BANK]

    -- Default bagId to backingBags[1] for addon backwards-compatibility
    bagId = bagId or inventory.backingBags[1]
    return inventory.slots[bagId][slotIndex]
end

function ZO_InventoryManager:GetContextualInfoBar()
    if self:IsBanking() then
        if BANK_FRAGMENT:IsShowing() then
            return ZO_PlayerBankInfoBar
        end
    elseif self:IsGuildBanking() then
        if GUILD_BANK_FRAGMENT:IsShowing() then
            return ZO_GuildBankInfoBar
        end
    end
    
    -- default info bar
    return ZO_PlayerInventoryInfoBar
end

function ZO_InventoryManager:GetContextualMoneyControls()
    local infoBar = self:GetContextualInfoBar()
    local moneyBar = infoBar:GetNamedChild("Money")
    local altMoneyBar = infoBar:GetNamedChild("AltMoney")
    return moneyBar, altMoneyBar
end

--House Bank
-------------

function ZO_InventoryManager:CreateHouseBankScene()
    HOUSE_BANK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_HouseBank)
    HOUSE_BANK_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                        if newState == SCENE_FRAGMENT_SHOWING then
                                                            if self.inventories[INVENTORY_HOUSE_BANK].searchBox then
                                                                self.inventories[INVENTORY_HOUSE_BANK].searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(self.inventories[INVENTORY_HOUSE_BANK].currentContext))
                                                            end

                                                            self:UpdateFreeSlots(INVENTORY_HOUSE_BANK)

                                                            if self.isListDirty[INVENTORY_HOUSE_BANK] then
                                                                local UPDATE_EVEN_IF_HIDDEN = true
                                                                self:UpdateList(INVENTORY_HOUSE_BANK, UPDATE_EVEN_IF_HIDDEN)
                                                            end
                                                        end
                                                    end)

    ZO_HouseBankInfoBarAltMoney:SetHidden(true)
    ZO_HouseBankInfoBarAltFreeSlots:SetHidden(false)

    local renameCollectibleKeybind =
    {
        name = GetString(SI_COLLECTIBLE_ACTION_RENAME),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            local collectibleId = GetCollectibleForHouseBankBag(GetBankingBag())
            if collectibleId ~= 0 then
                ZO_CollectionsBook.ShowRenameDialog(collectibleId)
            end
        end
    }

    self.houseBankWithdrawTabKeybindButtonGroup =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_QUINARY",
            callback = function()
                StackBag(GetBankingBag())
            end,
        },
        renameCollectibleKeybind,
    }

    self.houseBankDepositTabKeybindButtonGroup =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_QUINARY",
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
        renameCollectibleKeybind,
    }

    local function CreateButtonData(normal, pressed, highlight)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
        }
    end

    local houseBankFragmentBar = ZO_SceneFragmentBar:New(ZO_HouseBankMenuBar)

    --Withdraw Button
    local withdrawButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_withdraw_up.dds",
                                               "EsoUI/Art/Bank/bank_tabIcon_withdraw_down.dds",
                                               "EsoUI/Art/Bank/bank_tabIcon_withdraw_over.dds")
    houseBankFragmentBar:Add(SI_BANK_WITHDRAW, { HOUSE_BANK_FRAGMENT, BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT }, withdrawButtonData, self.houseBankWithdrawTabKeybindButtonGroup)

    --Deposit Button
    local depositButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_deposit_up.dds",
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_down.dds", 
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_over.dds")
    houseBankFragmentBar:Add(SI_BANK_DEPOSIT, { INVENTORY_FRAGMENT, BACKPACK_HOUSE_BANK_LAYOUT_FRAGMENT }, depositButtonData, self.houseBankDepositTabKeybindButtonGroup)

    local houseBankScene = ZO_InteractScene:New("houseBank", SCENE_MANAGER, BANKING_INTERACTION)
    houseBankScene:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if newState == SCENE_SHOWING then
                                                        --initialize the slots and banking bag fresh here since there are many different house bank bags and only one is active at a time
                                                        local inventory = self.inventories[INVENTORY_HOUSE_BANK]
                                                        local bankingBag = GetBankingBag()
                                                        inventory.slots = { [bankingBag] = {} }
                                                        inventory.backingBags = { bankingBag }
                                                        houseBankFragmentBar:SelectFragment(SI_BANK_WITHDRAW)
                                                        self:RefreshAllInventorySlots(INVENTORY_HOUSE_BANK)
                                                        self:UpdateFreeSlots(INVENTORY_HOUSE_BANK)
                                                        self:UpdateFreeSlots(INVENTORY_BACKPACK)
                                                        TriggerTutorial(TUTORIAL_TRIGGER_HOME_STORAGE_OPENED)
                                                    elseif newState == SCENE_HIDDEN then
                                                        ZO_InventorySlot_RemoveMouseOverKeybinds()
                                                        houseBankFragmentBar:Clear()
                                                        --Wipe out the inventory slot data and connection to a bag
                                                        local inventory = self.inventories[INVENTORY_HOUSE_BANK]
                                                        inventory.slots = nil
                                                        inventory.backingBags = nil
                                                        inventory.hasAnyQuickSlottableItems = nil
                                                    end
                                                end)
end

--Guild Bank
--------------

function ZO_InventoryManager:CreateGuildBankScene()
    GUILD_BANK_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GuildBank)
    GUILD_BANK_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                            if newState == SCENE_SHOWING then
                                                                if self.inventories[INVENTORY_GUILD_BANK].searchBox then
                                                                    self.inventories[INVENTORY_GUILD_BANK].searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(self.inventories[INVENTORY_GUILD_BANK].currentContext))
                                                                end

                                                                self:RefreshMoney()
                                                                self:UpdateFreeSlots(INVENTORY_GUILD_BANK)

                                                                if self.isListDirty[INVENTORY_GUILD_BANK] then
                                                                    local UPDATE_EVEN_IF_HIDDEN = true
                                                                    self:UpdateList(INVENTORY_GUILD_BANK, UPDATE_EVEN_IF_HIDDEN)
                                                                end
                                                            end
                                                        end)

    local function CanWithdrawFunction()
        return DoesPlayerHaveGuildPermission(GetSelectedGuildBankId(), GUILD_PERMISSION_BANK_VIEW_GOLD)
    end

    ZO_BankGenericCurrencyDepositWithdrawDialog:New("GUILD_BANK", CURRENCY_LOCATION_GUILD_BANK, CanWithdrawFunction)

    --Bank Second Row Infobar set visible
    ZO_GuildBankInfoBarAltMoney:SetHidden(false)
    ZO_GuildBankInfoBarAltFreeSlots:SetHidden(false)

    self.guildBankWithdrawTabKeybindButtonGroup =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local selectedGuildId = GetSelectedGuildBankId()
                if selectedGuildId then
                    return GetGuildName(selectedGuildId)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                return GetSelectedGuildBankId() ~= nil
            end,
            callback = function()
                ZO_Dialogs_ShowDialog("SELECT_GUILD_BANK")
            end,
        },
        {
            name = GetString(SI_BANK_WITHDRAW_CURRENCY_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                ZO_Dialogs_ShowDialog("GUILD_BANK_WITHDRAW_GOLD")
            end,
            visible = function()
                local guildId = GetSelectedGuildBankId()
                return guildId ~= nil and DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW_GOLD)
            end,
        }
    }

    self.guildBankDepositTabKeybindButtonGroup =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                local selectedGuild = GetSelectedGuildBankId()
                if(selectedGuild) then
                    return GetGuildName(selectedGuild)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                return GetSelectedGuildBankId() ~= nil
            end,
            callback = function()
                ZO_Dialogs_ShowDialog("SELECT_GUILD_BANK")
            end,
        },
        {
            name = GetString(SI_BANK_DEPOSIT_CURRENCY_BIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                ZO_Dialogs_ShowDialog("GUILD_BANK_DEPOSIT_GOLD")
            end,
            visible = function()
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
    guildBankFragmentBar:Add(SI_BANK_WITHDRAW, { GUILD_BANK_FRAGMENT, BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT }, withdrawButtonData, self.guildBankWithdrawTabKeybindButtonGroup)

    --Deposit Button
    local depositButtonData = CreateButtonData("EsoUI/Art/Bank/bank_tabIcon_deposit_up.dds",
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_down.dds", 
                                                "EsoUI/Art/Bank/bank_tabIcon_deposit_over.dds")
    guildBankFragmentBar:Add(SI_BANK_DEPOSIT, { INVENTORY_FRAGMENT, BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT }, depositButtonData, self.guildBankDepositTabKeybindButtonGroup)

    local guildBankScene = ZO_InteractScene:New("guildBank", SCENE_MANAGER, GUILD_BANKING_INTERACTION)
    guildBankScene:RegisterCallback("StateChange",  function(oldState, newState)
                                                        if newState == SCENE_SHOWING then
                                                            guildBankFragmentBar:SelectFragment(SI_BANK_WITHDRAW)
                                                            self:UpdateFreeSlots(INVENTORY_BACKPACK)
                                                            ZO_SharedInventory_SelectAccessibleGuildBank(ZO_GUILD_SELECTOR_MANAGER:GetSelectedGuildBankId())
                                                        elseif newState == SCENE_HIDDEN then
                                                            ZO_InventorySlot_RemoveMouseOverKeybinds()
                                                            guildBankFragmentBar:Clear()
                                                        end
                                                    end)
end

function ZO_InventoryManager:OpenGuildBank()
    self:ActivateGuildBankSearch()
    SCENE_MANAGER:Show("guildBank")
end

function ZO_InventoryManager:IsGuildBanking()
    return IsGuildBankOpen()
end

function ZO_InventoryManager:CloseGuildBank()
    self:DeactivateGuildBankSearch()
    SCENE_MANAGER:Hide("guildBank")
    ZO_GuildBankBackpackLoading:SetHidden(true)
    self:ClearAllGuildBankItems()

    self:RefreshPlayerInventorySearchContext()
end

function ZO_InventoryManager:RefreshAllGuildBankItems()
    local inventory = self.inventories[INVENTORY_GUILD_BANK]
    self:EmptyInventory(inventory)

    self.suppressItemAddedAlert = true

    --Add items
    for _, bagId in ipairs(inventory.backingBags) do
        for slotIndex in ZO_IterateBagSlots(bagId) do
            self:AddInventoryItem(INVENTORY_GUILD_BANK, slotIndex, bagId)
        end
    end

    self:LayoutInventoryItems(INVENTORY_GUILD_BANK)

    self:UpdateFreeSlots(INVENTORY_BACKPACK)

    self.suppressItemAddedAlert = nil
    TEXT_SEARCH_MANAGER:ExecutePendingContextSearches()
end

function ZO_InventoryManager:ClearAllGuildBankItems()
    local inventory = self.inventories[INVENTORY_GUILD_BANK]
    self:EmptyInventory(inventory)
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
    -- A race condition of multiple load requests can cause the selected guild bank returned to be invalid, 
    -- which will result in it being reset to the first in the list. This check prevents that. This case occurs
    -- when the user in promoted or demoted multiple times in rapid succession.
    local guildBankId = GetSelectedGuildBankId()
    if guildBankId then
        self.lastSuccessfulGuildBankId = guildBankId
    end
    ZO_GuildBankBackpackLoading:Hide()
    self:RefreshAllGuildBankItems()
    self:UpdateList(INVENTORY_BACKPACK)
    self:RefreshMoney()
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
    self:RefreshMoney()
    ZO_Dialogs_ReleaseDialog("GUILD_BANK_WITHDRAW_GOLD")
    ZO_Dialogs_ReleaseDialog("GUILD_BANK_DEPOSIT_GOLD")
end

function ZO_InventoryManager:RefreshGuildBankPermissions(guildId)
    if self:IsGuildBanking() then
        self:RefreshGuildBankMoneyOperationsPossible(guildId)
        if not self.loadingGuildBank then
            self:RefreshAllGuildBankItems()
            self:UpdateList(INVENTORY_BACKPACK)
        end
    end
end

function ZO_InventoryManager:RefreshGuildBankMoneyOperationsPossible(guildId)
    if GetSelectedGuildBankId() == guildId then
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
        if inventoryType == INVENTORY_BACKPACK then
            label = ZO_PlayerInventory:GetNamedChild("Empty")
        elseif inventoryType == INVENTORY_CRAFT_BAG then
            label = ZO_CraftBag:GetNamedChild("Empty")
        elseif inventoryType == INVENTORY_GUILD_BANK then
            label = ZO_GuildBank:GetNamedChild("Empty")
        elseif inventoryType == INVENTORY_QUEST_ITEM then
            label = ZO_QuestItems:GetNamedChild("Empty")
        end

        if label then
            label:SetHidden(not isEmptyList)

            local emptyListDisplayString
            if ZO_TextSearchManager.CanFilterByText(TEXT_SEARCH_MANAGER:GetSearchText(inventory.currentContext)) then
                -- String is empty because there are no search results
                emptyListDisplayString = GetString(SI_INVENTORY_ERROR_FILTER_EMPTY)
            elseif type(inventory.inventoryEmptyStringId) == "function" then
                emptyListDisplayString = inventory.inventoryEmptyStringId(self, inventory)
            else
                emptyListDisplayString = GetString(inventory.inventoryEmptyStringId)
            end

            if emptyListDisplayString ~= nil then
                label:SetText(emptyListDisplayString)
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
            self:ActivateInventorySearch()

            if self.inventories[INVENTORY_CRAFT_BAG].searchBox then
                self.inventories[INVENTORY_CRAFT_BAG].searchBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(self.inventories[INVENTORY_CRAFT_BAG].currentContext))
            end
            TriggerTutorial(TUTORIAL_TRIGGER_CRAFT_BAG_OPENED)
            self:UpdateApparelSection()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            -- ESO-750278: This update must occur after ApplyBackpackLayout is called so the list is filtered properly
            if self.isListDirty[INVENTORY_CRAFT_BAG] then
                self:UpdateList(INVENTORY_CRAFT_BAG, UPDATE_EVEN_IF_HIDDEN)
            end
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:DeactivateInventorySearch()
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            self:ClearNewStatusOnItemsThePlayerHasSeen(INVENTORY_CRAFT_BAG)
        end
    end

    CRAFT_BAG_FRAGMENT:RegisterCallback("StateChange", OnStateChange)
end

function ZO_InventoryManager:CreateQuestItemsFragment()
    QUEST_ITEMS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_QuestItems)

    local UPDATE_EVEN_IF_HIDDEN = true
    local function OnStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            if self.isListDirty[INVENTORY_QUEST_ITEM] then
                self:UpdateList(INVENTORY_QUEST_ITEM, UPDATE_EVEN_IF_HIDDEN)
            end
            self:UpdateApparelSection()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            self:ClearNewStatusOnItemsThePlayerHasSeen(INVENTORY_QUEST_ITEM)
        end
    end

    QUEST_ITEMS_FRAGMENT:RegisterCallback("StateChange", OnStateChange)
end

------------
--Global API
------------

function ZO_InventoryManager_SetQuestToolData(slotControl, questIndex, toolIndex)
    local questItems = g_playerInventory.inventories[INVENTORY_QUEST_ITEM].slots[questIndex]

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

function ZO_InventoryManager:OnInventorySlotUpdated(bagId, slotIndex)
    local inventory = self.bagToInventoryType[bagId]

    if inventory then
        self:RefreshInventorySlot(inventory, slotIndex, bagId)
        if inventory == INVENTORY_GUILD_BANK then
            -- For the deposit window while guild banking, the guild info isn't available when INVENTORY_BACKPACK updates.
            self:RefreshInventorySlot(INVENTORY_BACKPACK, slotIndex, BAG_BACKPACK)
        end
    end

    INVENTORY_MENU_BAR:UpdateInventoryKeybinds()
end

function ZO_InventoryManager:OnInventorySlotLocked(bagId, slotIndex)
    local inventory = self.bagToInventoryType[bagId]
    if inventory then
        self:RefreshInventorySlotLocked(inventory, slotIndex, true, bagId)
    end
end

function ZO_InventoryManager:OnInventorySlotUnlocked(bagId, slotIndex)
    local inventory = self.bagToInventoryType[bagId]
    if inventory then
        self:RefreshInventorySlotLocked(inventory, slotIndex, false, bagId)
    end
end

--------------
--XML Handlers
--------------

function ZO_Inventory_NewItemCategory_FlashAnimation_OnUpdate(self, progress)
    g_playerInventory:UpdateCategoryFlashAnimation(self, progress)
end

-----------
--Inventory
-----------

function ZO_PlayerInventory_OnSearchEnterKeyPressed(editBox)
    -- Do not clear the search, just unfocus the box, the appropriate items are now highlighted and should stay that way
    editBox:LoseFocus()
end

function ZO_PlayerInventory_FilterButtonOnMouseEnter(self)
    ZO_MenuBarButtonTemplate_OnMouseEnter(self)

    local data = ZO_MenuBarButtonTemplate_GetData(self)
    local tooltipText = data.tooltipText
    if type(tooltipText) == "function" then
        tooltipText = tooltipText(data)
    end

    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -10)
    SetTooltipText(InformationTooltip, tooltipText)
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
    -- ZO_PlayerInventory is used for event registration only. There are multiple inventory controls, but only one manager is needed.
    PLAYER_INVENTORY = ZO_InventoryManager:New(ZO_PlayerInventory)
end

--Select Guild Bank Dialog
----------------------

function ZO_SelectGuildBankDialog_OnInitialized(self)
    local function SetSelectedGuildBank(guildBankId)
        ZO_GUILD_SELECTOR_MANAGER:SetSelectedGuildBankId(guildBankId)
    end
    local dialog = ZO_SelectGuildDialog:New(self, "SELECT_GUILD_BANK", SetSelectedGuildBank)
    dialog:SetTitle(GetString(SI_PROMPT_TITLE_SELECT_GUILD_BANK))
    dialog:SetPrompt(GetString(SI_SELECT_GUILD_BANK_INSTRUCTIONS))
    dialog:SetCurrentStateSource(GetSelectedGuildBankId) 
end