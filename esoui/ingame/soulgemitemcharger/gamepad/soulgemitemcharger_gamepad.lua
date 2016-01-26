local ZO_SoulGemItemCharger_Gamepad = ZO_InventoryItemImprovement_Gamepad:Subclass()

function ZO_SoulGemItemCharger_Gamepad:New(...)
    return ZO_InventoryItemImprovement_Gamepad.New(self, ...)
end

function ZO_SoulGemItemCharger_Gamepad:Initialize(control)
    local function IsFilledSoulGem(bagId, slotIndex)
        return IsItemSoulGem(SOUL_GEM_TYPE_FILLED, bagId, slotIndex)
    end

    local function SortComparator(left, right)
        return GetSoulGemItemInfo(left.bag, left.index) < GetSoulGemItemInfo(right.bag, right.index)
    end

    ZO_InventoryItemImprovement_Gamepad.Initialize(
        self, 
        control, 
        GetString(SI_CHARGE_WEAPON_TITLE),
        "soulGemItemChargerGamepad",
        GetString(SI_CHARGE_WEAPON_SELECT),
        GetString(SI_CHARGE_WEAPON_NONE_FOUND),
        GetString(SI_CHARGE_WEAPON_CONFIRM),
        SOUNDS.INVENTORY_ITEM_APPLY_CHARGE,
        IsFilledSoulGem,
        SortComparator)
end

function ZO_SoulGemItemCharger_Gamepad:SetupScene()
    SOUL_GEM_ITEM_CHARGER_SCENE_GAMEPAD = ZO_Scene:New(self.sceneName, SCENE_MANAGER)
    SYSTEMS:RegisterGamepadRootScene("soulgem", SOUL_GEM_ITEM_CHARGER_SCENE_GAMEPAD)
end

function ZO_SoulGemItemCharger_Gamepad:UpdateTooltipOnSelectionChanged()
    GAMEPAD_TOOLTIPS:LayoutPendingItemCharge(GAMEPAD_LEFT_TOOLTIP, self.itemBag, self.itemIndex, self.improvementKitBag, self.improvementKitIndex)
end

function ZO_SoulGemItemCharger_Gamepad:PerformItemImprovement()
    ChargeItemWithSoulGem(self.itemBag, self.itemIndex, self.improvementKitBag, self.improvementKitIndex)
end

--[[ Globals ]]--
function ZO_Gamepad_SoulGemItemCharger_OnInitialize(control)
    SOUL_GEM_ITEM_CHARGER_GAMEPAD = ZO_SoulGemItemCharger_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("soulgem", SOUL_GEM_ITEM_CHARGER_GAMEPAD)
end