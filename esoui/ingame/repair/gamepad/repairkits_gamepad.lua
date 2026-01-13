local ZO_RepairKits_Gamepad = ZO_InventoryItemImprovement_Gamepad:Subclass()

function ZO_RepairKits_Gamepad:New(...)
    return ZO_InventoryItemImprovement_Gamepad.New(self, ...)
end

function ZO_RepairKits_Gamepad:Initialize(control)
    local function SortComparator(left, right)
        return GetRepairKitTier(left.bag, left.index) < GetRepairKitTier(right.bag, right.index)
    end

    ZO_InventoryItemImprovement_Gamepad.Initialize(
        self, 
        control, 
        GetString(SI_REPAIR_KIT_TITLE),
        "repairGamepad",
        GetString(SI_REPAIR_KIT_SELECT),
        GetString(SI_REPAIR_KIT_NONE_FOUND),
        GetString(SI_REPAIR_KIT_CONFIRM),
        SOUNDS.INVENTORY_ITEM_REPAIR,
        IsItemNonCrownRepairKit,
        SortComparator)
end

function ZO_RepairKits_Gamepad:SetupScene()
    local repairKitsSceneGamepad = ZO_Scene:New(self.sceneName, SCENE_MANAGER)
    SYSTEMS:RegisterGamepadRootScene("repair", repairKitsSceneGamepad)
end

function ZO_RepairKits_Gamepad:UpdateTooltipOnSelectionChanged()
    GAMEPAD_TOOLTIPS:LayoutPendingItemRepair(GAMEPAD_LEFT_TOOLTIP, self.itemBag, self.itemIndex, self.improvementKitBag, self.improvementKitIndex)
end

function ZO_RepairKits_Gamepad:PerformItemImprovement()
    RepairItemWithRepairKit(self.itemBag, self.itemIndex, self.improvementKitBag, self.improvementKitIndex)
end

--[[ Global Handlers ]]--
function ZO_Gamepad_RepairKits_OnInitialize(control)
    REPAIR_KITS_GAMEPAD = ZO_RepairKits_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("repair", REPAIR_KITS_GAMEPAD)
end
