ZO_RepairKits = ZO_Object:Subclass()

function ZO_RepairKits:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_RepairKits:Initialize(control)
    self.control = control
    self:SetupPreviewControls()

    local function RepairItem()
        local selectedData = ZO_InventorySlot_GetItemListDialog():GetSelectedItem()
        if selectedData then
            RepairItemWithRepairKit(self.currentBag, self.currentIndex, selectedData.bag, selectedData.index)
        end
    end

    ZO_Dialogs_RegisterCustomDialog("REPAIR_ITEM",
    {
        customControl = function() return ZO_InventorySlot_GetItemListDialog():GetControl() end,
        setup = function(dialog, data) self:SetupDialog(data.bag, data.index) end,

        title =
        {
            text = SI_REPAIR_KIT_TITLE,
        },        
        buttons =
        {
            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(1),
                text = SI_REPAIR_KIT_CONFIRM,
                clickSound = SOUNDS.INVENTORY_ITEM_REPAIR,
                callback = RepairItem,
            },

            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(2),
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

function ZO_RepairKits:SetupPreviewControls()
    local previewContainer = self.control:GetNamedChild("ImprovementPreviewContainer")
    self.inventorySlot = previewContainer:GetNamedChild("Slot")
    local conditionContainer = previewContainer:GetNamedChild("ImprovementContainer")
    self.conditionBar = conditionContainer:GetNamedChild("Bar")
    self.conditionUnderlayBar = conditionContainer:GetNamedChild("Underlay")

    ZO_StatusBar_SetGradientColor(self.conditionBar, ZO_CONDITION_GRADIENT_COLORS)
end

function ZO_RepairKits:SetItemInfo(bag, index)
    self.control:SetHidden(false)
    local icon, stackCount = GetItemInfo(bag, index)

    ZO_Inventory_BindSlot(self.inventorySlot, SLOT_TYPE_PENDING_REPAIR, index, bag)
    ZO_Inventory_SetupSlot(self.inventorySlot, stackCount, icon)

    local condition = GetItemCondition(bag, index)
    self.conditionBar:SetMinMax(0, 100)
    self.conditionBar:SetValue(condition)

    local FORCE = true
    ZO_StatusBar_SmoothTransition(self.conditionUnderlayBar, condition, 100, FORCE)
end

function ZO_RepairKits:OnRepairKitSelected(itemBagId, itemSlotIndex, repairKitBagId, repairKitSlotIndex, playSound)
    local conditionToAdd = GetAmountRepairKitWouldRepairItem(itemBagId, itemSlotIndex, repairKitBagId, repairKitSlotIndex)
    local newCondition = zo_clamp(self.conditionBar:GetValue() + conditionToAdd, 0, 100)
    ZO_StatusBar_SmoothTransition(self.conditionUnderlayBar, newCondition, 100)

    if playSound then
        local soundCategory = GetItemSoundCategory(itemBagId, itemSlotIndex)
        PlayItemSound(soundCategory, ITEM_SOUND_ACTION_PICKUP)
    end
end

local function SortComparator(left, right)
    return GetRepairKitTier(left.data.bag, left.data.index) < GetRepairKitTier(right.data.bag, right.data.index)
end

function ZO_RepairKits:SetupDialog(bag, index)
    local listDialog = ZO_InventorySlot_GetItemListDialog()

    listDialog:SetAboveText(GetString(SI_REPAIR_KIT_SELECT))
    listDialog:SetBelowText(GetString(SI_REPAIR_KIT_CONSUME))
    listDialog:SetEmptyListText(GetString(SI_REPAIR_KIT_NONE_FOUND))

    listDialog:ClearList()

    local itemList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, IsItemNonCrownRepairKit)
    for itemId, itemInfo in pairs(itemList) do
        listDialog:AddListItem(itemInfo)
    end

    listDialog:CommitList(SortComparator)

    listDialog:AddCustomControl(self.control, LIST_DIALOG_CUSTOM_CONTROL_LOCATION_TOP)
    self:SetItemInfo(bag, index)

    local PLAY_SOUND = true
    listDialog:SetOnSelectedCallback(function(selectedData) self:OnRepairKitSelected(bag, index, selectedData.bag, selectedData.index, PLAY_SOUND) end)

    self.currentBag = bag
    self.currentIndex = index
end

function ZO_RepairKits:BeginItemImprovement(bag, index)
    ZO_Dialogs_ShowDialog("REPAIR_ITEM", {bag = bag, index = index})
end

function ZO_RepairKits_OnInitialize(control)
    REPAIR_KITS = ZO_RepairKits:New(control)
    SYSTEMS:RegisterKeyboardObject("repair", REPAIR_KITS)
end