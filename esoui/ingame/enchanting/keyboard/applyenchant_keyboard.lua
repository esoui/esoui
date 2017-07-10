ZO_ApplyEnchant = ZO_Object:Subclass()

function ZO_ApplyEnchant:New(...)
    local enchanting = ZO_Object.New(self)
    enchanting:Initialize(...)
    return enchanting
end

function ZO_ApplyEnchant:Initialize(control)
    self.control = control

    self.beforeSlot = self.control:GetNamedChild("Before")
    self.afterSlot = self.control:GetNamedChild("After")
    self.afterSlotGlow1 = self.afterSlot:GetNamedChild("Glow1")
    self.afterSlotGlow2 = self.afterSlot:GetNamedChild("Glow2")

    local animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("EnchantedResultAnimation")
    animation:GetFirstAnimation():SetAnimatedControl(self.afterSlotGlow1)
    animation:GetLastAnimation():SetAnimatedControl(self.afterSlotGlow2)

    local rotationTimeline = animation:GetFirstAnimationTimeline()
    rotationTimeline:GetFirstAnimation():SetAnimatedControl(self.afterSlotGlow1)
    rotationTimeline:GetLastAnimation():SetAnimatedControl(self.afterSlotGlow1)

    self.enchantedAnimation = animation

    local function PerformEnchant()
        local selectedData = ZO_InventorySlot_GetItemListDialog():GetSelectedItem()
        if selectedData then
            local function DoEnchant()
                EnchantItem(self.currentBag, self.currentIndex, selectedData.bag, selectedData.index)
            end

            if IsItemPlayerLocked(self.currentBag, self.currentIndex) then
                ZO_Dialogs_ShowPlatformDialog("CONFIRM_ENCHANT_LOCKED_ITEM", { onAcceptCallback = DoEnchant }, { mainTextParams = { GetString(SI_PERFORM_ACTION_CONFIRMATION) } })
            else
                DoEnchant()
            end
        end
    end

    ZO_Dialogs_RegisterCustomDialog("ENCHANTING",
    {
        customControl = function() return ZO_InventorySlot_GetItemListDialog():GetControl() end,
        setup = function(dialog, data) self:SetupDialog(data.bag, data.index) end,
        canQueue = true,

        title =
        {
            text = SI_ENCHANT_TITLE,
        },        
        buttons =
        {
            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(1),
                text = SI_ENCHANT_CONFIRM,
                clickSound = SOUNDS.INVENTORY_ITEM_APPLY_ENCHANT,
                callback = PerformEnchant,
            },

            {
                control = ZO_InventorySlot_GetItemListDialog():GetButton(2),
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

local function SortComparator(left, right)
    return left.data.name < right.data.name
end

function ZO_ApplyEnchant:SetupDialog(bag, index)
    local listDialog = ZO_InventorySlot_GetItemListDialog()

    listDialog:SetAboveText(GetString(SI_ENCHANT_SELECT))
    listDialog:SetBelowText(GetString(SI_ENCHANT_CONSUME))
    listDialog:SetEmptyListText(GetString(SI_ENCHANT_NONE_FOUND))

    listDialog:ClearList()

    local itemList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, function(enchantBag, enchantSlotIndex) return CanItemTakeEnchantment(bag, index, enchantBag, enchantSlotIndex) end)
    for itemId, itemInfo in pairs(itemList) do
        itemInfo.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(itemInfo.bag, itemInfo.index))
        listDialog:AddListItem(itemInfo)
    end

    listDialog:CommitList(SortComparator)

    listDialog:AddCustomControl(self.control, LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM)
    self:SetItemInfo(bag, index)

    listDialog:SetOnSelectedCallback(function(selectedData) self:OnEnchantSelected(bag, index, selectedData.bag, selectedData.index) end)
    self.afterSlotGlow1:SetHidden(true)
    self.afterSlotGlow2:SetHidden(true)
    self.enchantedAnimation:Stop()

    self.currentBag = bag
    self.currentIndex = index
end

function ZO_ApplyEnchant:SetItemInfo(bag, index)
    self.control:SetHidden(false)
    local icon, stackCount = GetItemInfo(bag, index)

    ZO_Inventory_BindSlot(self.beforeSlot, SLOT_TYPE_ENCHANTMENT, index, bag)
    ZO_Inventory_SetupSlot(self.beforeSlot, stackCount, icon)

    ZO_Inventory_BindSlot(self.afterSlot, SLOT_TYPE_ENCHANTMENT, index, bag)
    ZO_Inventory_SetupSlot(self.afterSlot, stackCount, icon)
end

function ZO_ApplyEnchant:OnEnchantSelected(itemBagId, itemSlotIndex, enchantmentBagId, enchantmentSlotIndex)
    if not self.enchantedAnimation:IsPlaying() then
        self.afterSlotGlow1:SetHidden(false)
        self.afterSlotGlow2:SetHidden(false)
        self.enchantedAnimation:PlayFromStart()
    end

    local icon, stackCount = GetItemInfo(itemBagId, itemSlotIndex)

    self.afterSlot.enchantmentBagId = enchantmentBagId
    self.afterSlot.enchantmentSlotIndex = enchantmentSlotIndex

    ZO_Inventory_BindSlot(self.afterSlot, SLOT_TYPE_ENCHANTMENT_RESULT, itemSlotIndex, itemBagId)
    ZO_Inventory_SetupSlot(self.afterSlot, stackCount, icon)
end

function ZO_ApplyEnchant:BeginItemImprovement(bag, index)
    ZO_Dialogs_ShowDialog("ENCHANTING", {bag = bag, index = index})
end

function ZO_ApplyEnchant_OnInitialize(control)
    APPLY_ENCHANT = ZO_ApplyEnchant:New(control)
    SYSTEMS:RegisterKeyboardObject("enchant", APPLY_ENCHANT)
end