ZO_FishFilletSlot = ZO_CraftingMultiSlotBase:Subclass()

function ZO_FishFilletSlot:Initialize(owner, control, craftingInventory)
    local NO_EMPTY_TEXTURE = ""
    local NO_MULTIPLE_ITEMS_TEXTURE = ""
    ZO_CraftingMultiSlotBase.Initialize(self, owner, control, SLOT_TYPE_PENDING_CRAFTING_COMPONENT, NO_EMPTY_TEXTURE, NO_MULTIPLE_ITEMS_TEXTURE, craftingInventory)

    self.nameLabel = control:GetNamedChild("Name")
end

function ZO_FishFilletSlot:AddItem(bagId, slotIndex)
    if ZO_CraftingMultiSlotBase.AddItem(self, bagId, slotIndex) then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_PLACED)
        return true
    end
    return false
end

function ZO_FishFilletSlot:RemoveItem(bagId, slotIndex)
    if ZO_CraftingMultiSlotBase.RemoveItem(self, bagId, slotIndex) then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_REMOVED)
        return true
    end
    return false
end

function ZO_FishFilletSlot:ClearItems()
    if ZO_CraftingMultiSlotBase.ClearItems(self) then
        PlaySound(SOUNDS.SMITHING_ITEM_TO_EXTRACT_REMOVED)
        return true
    end
    return false
end

function ZO_FishFilletSlot:Refresh()
    ZO_CraftingMultiSlotBase.Refresh(self)

    if self.nameLabel then
        if self:HasOneItem() then
            local bagId, slotIndex = self:GetItemBagAndSlot(1)
            self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex)))

            if not self:HasAnimationRefs() then
                local displayQuality = GetItemDisplayQuality(bagId, slotIndex)
                self.nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality))
            end
        elseif self:HasMultipleItems() then
            self.nameLabel:SetText(zo_strformat(SI_CRAFTING_SLOT_MULTIPLE_SELECTED, ZO_CommaDelimitNumber(self:GetStackCount())))
            self.nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            self.nameLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            self.nameLabel:SetText(zo_strformat(SI_SMITHING_NEED_MORE_TO_EXTRACT, 1))
        end
    end

    if self:HasOneItem() then
        local ALWAYS_SHOW_STACK_COUNT = true
        local minQuantity = 1
        ZO_ItemSlot_SetAlwaysShowStackCount(self.control, ALWAYS_SHOW_STACK_COUNT, minQuantity)
    else
        local AUTO_SHOW_STACK_COUNT = false
        local MIN_QUANTITY = 0
        ZO_ItemSlot_SetAlwaysShowStackCount(self.control, AUTO_SHOW_STACK_COUNT, MIN_QUANTITY)
    end
end

function ZO_FishFilletSlot:ShowDropCallout()
    self.dropCallout:SetHidden(false)
    self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_goodSlot.dds")
end

function ZO_FishFilletSlot:GetNarrationText()
    if self:HasOneItem() then
        local bagId, slotIndex = self:GetItemBagAndSlot(1)
        return zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex))
    elseif self:HasMultipleItems() then
        return zo_strformat(SI_CRAFTING_SLOT_MULTIPLE_SELECTED, ZO_CommaDelimitNumber(self:GetStackCount()))
    else
        return zo_strformat(SI_SMITHING_NEED_MORE_TO_EXTRACT, 1)
    end
end

ZO_FishFillet_Shared = ZO_InitializingObject:Subclass()

function ZO_FishFillet_Shared:Initialize(filletSlotControl, filletLabel, owner)
    self.filletSlotControl = filletSlotControl
    self.filletLabel = filletLabel
    self.owner = owner

    if self.filletLabel then
        self.filletLabel:SetText(GetString("SI_PROVISIONERSPECIALINGREDIENTTYPE", PROVISIONER_SPECIAL_INGREDIENT_TYPE_FILLET))
    end
end

function ZO_FishFillet_Shared:InitFilletSlot(sceneName)
    self.filletSlot = ZO_FishFilletSlot:New(self, self.filletSlotControl, self.inventory)
    self.filletSlot:RegisterCallback("ItemsChanged", function()
        self:OnSlotChanged()
    end)
    self.slotAnimation = ZO_CraftingSmithingExtractSlotAnimation:New(sceneName, function() return not self.filletSlotControl:IsHidden() end)
    self.slotAnimation:AddSlot(self.filletSlot)
end


function ZO_FishFillet_Shared:OnInventoryUpdate(validItems, filterType)
    self.filletSlot:ValidateItemId(validItems, function(bagId, slotIndex)
        return self.inventory:GetStackCount(bagId, slotIndex) >= 1
    end)
end

function ZO_FishFillet_Shared:ShowAppropriateSlotDropCallouts()
    self.filletSlot:ShowDropCallout(true)
end

function ZO_FishFillet_Shared:HideAllSlotDropCallouts()
    self.filletSlot:HideDropCallout()
end

function ZO_FishFillet_Shared:OnSlotChanged()
    self:OnFilterChanged()
    self.inventory:HandleVisibleDirtyEvent()
    self.owner:OnFilletSlotChanged()
end

function ZO_FishFillet_Shared:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    if self:CanItemBeAddedToCraft(bagId, slotIndex) then
        self:AddItemToCraft(bagId, slotIndex)
    end
end

function ZO_FishFillet_Shared:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    return self.filletSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_FishFillet_Shared:CanItemBeAddedToCraft(bagId, slotIndex)
    return self:DoesItemMeetStackRequirement(bagId, slotIndex)
end

function ZO_FishFillet_Shared:AddItemToCraft(bagId, slotIndex)
    local newStackCount = self.filletSlot:GetStackCount() + zo_max(1, self.inventory:GetStackCount(bagId, slotIndex)) -- non virtual items will have a stack count of 0, but still count as 1 item
    local stackCountPerIteration = 1
    local maxStackCount = MAX_ITERATIONS_PER_DECONSTRUCTION * stackCountPerIteration

    if self.filletSlot:GetNumItems() >= MAX_ITEM_SLOTS_PER_DECONSTRUCTION then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_MANY_CRAFTING_INPUTS))
    elseif self.filletSlot:HasItems() and newStackCount > maxStackCount then
        -- prevent slotting if it would take us above the iteration limit, but allow it if nothing else has been slotted yet so we can support single stacks that are larger than the limit
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_TOO_MANY_CRAFTING_ITERATIONS))
    else
        self.filletSlot:AddItem(bagId, slotIndex)
    end
end

function ZO_FishFillet_Shared:RemoveItemFromCraft(bagId, slotIndex)
    self.filletSlot:RemoveItem(bagId, slotIndex)
end

function ZO_FishFillet_Shared:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    return self.filletSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_FishFillet_Shared:DoesItemMeetStackRequirement(bagId, slotIndex)
    if ZO_FishFillet_Shared_IsFilletableItem(bagId, slotIndex) then
        return self.inventory:GetStackCount(bagId, slotIndex) >= 1
    end
    return true
end

function ZO_FishFillet_Shared:IsSlotted(bagId, slotIndex)
    return self.filletSlot:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_FishFillet_Shared:FilletSingle()
    PrepareDeconstructMessage()

    local bagId, slotIndex = self.filletSlot:GetItemBagAndSlot(1)
    local quantity = 1
    if AddItemToDeconstructMessage(bagId, slotIndex, quantity) then
        -- TODO Fillet: Verify this is the proper function to call for Filleting
        SendDeconstructMessage()
    end
end

function ZO_FishFillet_Shared:FilletPartialStack(quantity)
    PrepareDeconstructMessage()

    local bagId, slotIndex = self.filletSlot:GetItemBagAndSlot(1)
    if AddItemToDeconstructMessage(bagId, slotIndex, quantity) then
        -- TODO Fillet: Verify this is the proper function to call for Filleting
        SendDeconstructMessage()
    end
end

do
    local function CompareFilletingItems(left, right)
        return left.quantity < right.quantity
    end

    function ZO_FishFillet_Shared:FilletAll()
        PrepareDeconstructMessage()

        local sortedItems = {}
        for index = 1, self.filletSlot:GetNumItems() do
            local bagId, slotIndex = self.filletSlot:GetItemBagAndSlot(index)
            local quantity = self.inventory:GetStackCount(bagId, slotIndex)
            local step = 1
            quantity = zo_floor(quantity / step) * step -- round quantity to next step down
            table.insert(sortedItems, {bagId = bagId, slotIndex = slotIndex, quantity = quantity})
        end
        table.sort(sortedItems, CompareFilletingItems)

        local addedAllItems = true
        for _, item in ipairs(sortedItems) do
            if not AddItemToDeconstructMessage(item.bagId, item.slotIndex, item.quantity) then
                addedAllItems = false
                break
            end
        end

        if addedAllItems then
            SendDeconstructMessage()
        end
    end
end

function ZO_FishFillet_Shared:ConfirmFilletAll()
    if not self:IsMultiFillet() then
        -- single fillets do not need a confirmation dialog
        self:FilletSingle()
    else
        local dialogData =
        {
            deconstructFn = function()
                self:FilletAll()
            end,
            verb = DECONSTRUCT_ACTION_NAME_FILLET,
        }
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_DECONSTRUCT_MULTIPLE_ITEMS", dialogData, { mainTextParams = { ZO_CommaDelimitNumber(self.filletSlot:GetStackCount()) } })
    end
end

function ZO_FishFillet_Shared:IsFilletable()
    return self.filletSlot:HasItems()
end

function ZO_FishFillet_Shared:IsMultiFillet()
    return self.filletSlot:HasMultipleItems()
end

function ZO_FishFillet_Shared:HasSelections()
    return self.filletSlot:HasItems()
end

function ZO_FishFillet_Shared:ClearSelections()
    self.filletSlot:ClearItems()
end

function ZO_FishFillet_Shared:GetFilterType()
    return self.inventory:GetCurrentFilterType()
end

function ZO_FishFillet_Shared:OnFilterChanged()
    -- Can be overridden
end

function ZO_FishFillet_IsSceneShowing()
    if PROVISIONER and not IsInGamepadPreferredMode() then
        return PROVISIONER_SCENE:IsShowing()
    elseif GAMEPAD_PROVISIONER then
        return GAMEPAD_PROVISIONER:IsSceneShowing()
    end
    return false
end

function ZO_FishFillet_GetActiveObject()
    if PROVISIONER and not IsInGamepadPreferredMode() then
        return PROVISIONER.filletPanel
    elseif GAMEPAD_PROVISIONER then
        return GAMEPAD_PROVISIONER.filletPanel
    end
end

function ZO_FishFillet_GetVisibleFishFillet()
    if PROVISIONER and SCENE_MANAGER:IsShowing("provisioner") then
        return PROVISIONER.filletPanel
    else
        return GAMEPAD_PROVISIONER.filletPanel
    end
end

function ZO_FishFillet_Shared_IsFilletableItem(bagId, slotIndex)
    local itemType = GetItemType(bagId, slotIndex)
    return itemType == ITEMTYPE_FISH
end
