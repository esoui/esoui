ZO_SoulGemItemCharger = ZO_Object:Subclass()

function ZO_SoulGemItemCharger:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SoulGemItemCharger:Initialize(control)
    self.control = control
    self:SetupPreviewControls()

    local function ChargeItem()
        local selectedData = ZO_InventorySlot_GetItemListDialog():GetSelectedItem()
        if selectedData then
            ChargeItemWithSoulGem(self.currentBag, self.currentIndex, selectedData.bag, selectedData.index)
        end
    end

    ZO_Dialogs_RegisterCustomDialog("CHARGE_ITEM",
    {
        customControl = function() return ZO_InventorySlot_GetItemListDialog():GetControl() end,
        setup = function(dialog, data) self:SetupDialog(data.bag, data.index) end,

        title =
        {
            text = SI_CHARGE_WEAPON_TITLE,
        },        
        buttons =
        {
            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(1),
                text = SI_CHARGE_WEAPON_CONFIRM,
                clickSound = SOUNDS.INVENTORY_ITEM_APPLY_CHARGE,
                callback = ChargeItem,
            },

            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(2),
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

function ZO_SoulGemItemCharger:SetupPreviewControls()
    local previewContainer = self.control:GetNamedChild("ImprovementPreviewContainer")
    self.inventorySlot = previewContainer:GetNamedChild("Slot")
    local improvementContainer = previewContainer:GetNamedChild("ImprovementContainer")
    self.chargesBar = improvementContainer:GetNamedChild("Bar")
    self.chargesUnderlayBar = improvementContainer:GetNamedChild("Underlay")

    ZO_StatusBar_SetGradientColor(self.chargesBar, ZO_CONDITION_GRADIENT_COLORS)
    self.previewControlsInitialized = true
end


function ZO_SoulGemItemCharger:SetItemInfo(bag, index)
    self.control:SetHidden(false)
    local icon, stackCount = GetItemInfo(bag, index)

    ZO_Inventory_BindSlot(self.inventorySlot, SLOT_TYPE_PENDING_CHARGE, index, bag)
    ZO_Inventory_SetupSlot(self.inventorySlot, stackCount, icon)

    local charges, maxCharges = GetChargeInfoForItem(bag, index)
    self.chargesBar:SetMinMax(0, maxCharges)
    self.chargesBar:SetValue(charges)

    local FORCE = true
    ZO_StatusBar_SmoothTransition(self.chargesUnderlayBar, charges, maxCharges, FORCE)
end

function ZO_SoulGemItemCharger:OnSoulGemSelected(itemBagId, itemSlotIndex, soulGemBagId, soulGemSlotIndex)
    local chargesToAdd = GetAmountSoulGemWouldChargeItem(itemBagId, itemSlotIndex, soulGemBagId, soulGemSlotIndex)
    local _, max = self.chargesUnderlayBar:GetMinMax()
    local newCharges = zo_clamp(self.chargesBar:GetValue() + chargesToAdd, 0, max)
    ZO_StatusBar_SmoothTransition(self.chargesUnderlayBar, newCharges, max)
end

local function SortComparator(left, right)
    return GetSoulGemItemInfo(left.data.bag, left.data.index) < GetSoulGemItemInfo(right.data.bag, right.data.index)
end

local function IsFilledSoulGem(bagId, slotIndex)
    return IsItemSoulGem(SOUL_GEM_TYPE_FILLED, bagId, slotIndex)
end

function ZO_SoulGemItemCharger:SetupDialog(bag, index)
    local listDialog = ZO_InventorySlot_GetItemListDialog()

    listDialog:SetAboveText(GetString(SI_CHARGE_WEAPON_SELECT))
    listDialog:SetBelowText(GetString(SI_CHARGE_WEAPON_CONSUME))
    listDialog:SetEmptyListText(GetString(SI_CHARGE_WEAPON_NONE_FOUND))

    listDialog:ClearList()

    local itemList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, IsFilledSoulGem)
    for itemId, itemInfo in pairs(itemList) do
        listDialog:AddListItem(itemInfo)
    end

    listDialog:CommitList(SortComparator)

    listDialog:AddCustomControl(self.control, LIST_DIALOG_CUSTOM_CONTROL_LOCATION_TOP)
    self:SetItemInfo(bag, index)

    listDialog:SetOnSelectedCallback(function(selectedData) self:OnSoulGemSelected(bag, index, selectedData.bag, selectedData.index) end)

    self.currentBag = bag
    self.currentIndex = index
end

function ZO_SoulGemItemCharger:BeginItemImprovement(bag, index)
    ZO_Dialogs_ShowDialog("CHARGE_ITEM", {bag = bag, index = index})
end

function ZO_SoulGemItemCharger_OnInitialize(control)
    SOUL_GEM_ITEM_CHARGER = ZO_SoulGemItemCharger:New(control)
    SYSTEMS:RegisterKeyboardObject("soulgem", SOUL_GEM_ITEM_CHARGER)
end