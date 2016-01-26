----------------------------------------
-- Backpack Layout Fragment
----------------------------------------

ZO_BACKPACK_LAYOUT_HIDE_ALL_BANK_INFO_BARS = 1
ZO_BACKPACK_LAYOUT_SHOW_ALL_BANK_INFO_BARS = 2
ZO_BACKPACK_LAYOUT_HIDE_ONLY_TELVAR_BANK_INFO_BARS = 3

ZO_BackpackLayoutFragment = ZO_SceneFragment:Subclass()
local DEFAULT_BACKPACK_LAYOUT_DATA =
{
    width = 565,
    backpackOffsetY = 96,
    inventoryTopOffsetY = -20,
    inventoryBottomOffsetY = -30,
    sortByOffsetY = 63,
    sortByHeaderWidth = 576,
    sortByNameWidth = 241,
    bankInfoBarVisibilityOption = ZO_BACKPACK_LAYOUT_HIDE_ALL_BANK_INFO_BARS,
}

function ZO_BackpackLayoutFragment:New(...)
    local fragment = ZO_SceneFragment.New(self)
    fragment:Initialize(...)
    return fragment
end

function ZO_BackpackLayoutFragment:Initialize(layoutData)
    if(layoutData) then
        for k,v in pairs(DEFAULT_BACKPACK_LAYOUT_DATA) do
            if layoutData[k] == nil then
                layoutData[k] = v
            end
        end
        self.layoutData = layoutData
    else
        self.layoutData = DEFAULT_BACKPACK_LAYOUT_DATA
    end
end

function ZO_BackpackLayoutFragment:Show()
    PLAYER_INVENTORY:ApplyBackpackLayout(self.layoutData)
    self:OnShown()
end

function ZO_BackpackLayoutFragment:Hide()
    self:OnHidden()
end

----------------------------------------
-- Fragment Declarations
----------------------------------------
local DEFAULT_INVENTORY_TOP_OFFSET_Y = 45

BACKPACK_DEFAULT_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New()

BACKPACK_MENU_BAR_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = DEFAULT_INVENTORY_TOP_OFFSET_Y,
    })

BACKPACK_BANK_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = DEFAULT_INVENTORY_TOP_OFFSET_Y,
        hiddenFilters = { [ITEMFILTERTYPE_QUEST] = true },
        additionalFilter = function (slot)
            return (not slot.stolen)
        end,
        bankInfoBarVisibilityOption = ZO_BACKPACK_LAYOUT_SHOW_ALL_BANK_INFO_BARS,
    })

BACKPACK_GUILD_BANK_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = DEFAULT_INVENTORY_TOP_OFFSET_Y,
        hiddenFilters = { [ITEMFILTERTYPE_QUEST] = true },
        additionalFilter = function (slot)
            return (not slot.stolen)
        end,
        bankInfoBarVisibilityOption = ZO_BACKPACK_LAYOUT_HIDE_ONLY_TELVAR_BANK_INFO_BARS,
    })

BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        width = 670,
        backpackOffsetY = 128,
        sortByOffsetY = 96,
        sortByHeaderWidth = 690,
        sortByNameWidth = 341,
        additionalFilter = function (slot)
            return (slot.quality ~= ITEM_QUALITY_TRASH) and (not slot.stolen)
        end,
    })

BACKPACK_MAIL_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = 50,
        inventoryBottomOffsetY = -60,
        hiddenFilters = { [ITEMFILTERTYPE_QUEST] = true },
        additionalFilter = function (slot)
            return (not IsItemBound(slot.bagId, slot.slotIndex)) and (not slot.stolen)
        end,
    })

BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = 50,
        inventoryBottomOffsetY = -60,
        hiddenFilters = { [ITEMFILTERTYPE_QUEST] = true },
        additionalFilter = function (slot)
            return (not IsItemBound(slot.bagId, slot.slotIndex)) and (not slot.stolen)
        end,
        waitUntilInventoryOpensToClearNewStatus = true,
    })

BACKPACK_STORE_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = DEFAULT_INVENTORY_TOP_OFFSET_Y,
        inventoryBottomOffsetY = -30,
        hiddenFilters = { [ITEMFILTERTYPE_QUEST] = true },
        additionalFilter = function (slot)
            return (not slot.stolen)
        end,
        alwaysReapplyLayout = true,
    })
BACKPACK_FENCE_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = DEFAULT_INVENTORY_TOP_OFFSET_Y,
        inventoryBottomOffsetY = -30,
        hiddenFilters = { [ITEMFILTERTYPE_QUEST] = true },
        additionalFilter = function (slot)
            return slot.stolen and slot.stackSellPrice > 0
        end,
        alwaysReapplyLayout = true,
    })
BACKPACK_LAUNDER_LAYOUT_FRAGMENT = ZO_BackpackLayoutFragment:New(
    {
        inventoryTopOffsetY = DEFAULT_INVENTORY_TOP_OFFSET_Y,
        inventoryBottomOffsetY = -30,
        hiddenFilters = { [ITEMFILTERTYPE_QUEST] = true },
        additionalFilter = function (slot)
            return slot.stolen
        end,
        alwaysReapplyLayout = true,
    })