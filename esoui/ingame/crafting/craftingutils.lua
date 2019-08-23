--[[ Crafting Create Screen Base ]]--
ZO_CraftingCreateScreenBase = ZO_Object:Subclass()

function ZO_CraftingCreateScreenBase:New()
    return ZO_Object.New(self)
end

function ZO_CraftingCreateScreenBase:Create(numIterations)
    assert(false, "Override me")
end

-- To be used with the C APIs, eg. CreateTradeskillItem(tradeskillObject:GetAllCraftingParameters())
-- Lua limitation:
-- writing tradeskillObject:GetAllCraftingParameters(), numIterations would truncate the crafting
-- parameters to only the first return, so each implementation of
-- GetAllCraftingParameters should manually place that argument at the end themselves
function ZO_CraftingCreateScreenBase:GetAllCraftingParameters(numIterations)
    assert(false, "Override me")
    -- return implementation defined
end

function ZO_CraftingCreateScreenBase:GetResultItemLink()
    assert(false, "Override me")
    -- should return resultItemLink
end

function ZO_CraftingCreateScreenBase:GetMultiCraftNumResults(numIterations)
    assert(false, "Override me")
    -- should return numResults
end

function ZO_CraftingCreateScreenBase:IsCraftable()
    assert(false, "Override me")
    -- should return bool
end

function ZO_CraftingCreateScreenBase:GetMultiCraftMaxIterations()
    -- override me
    return 1
end

function ZO_CraftingCreateScreenBase:ShouldCraftButtonBeEnabled()
    assert(false, "Override me")
    -- should return bool, errorString
end

function ZO_CraftingCreateScreenBase:ShouldMultiCraftButtonBeEnabled()
    local enabled, errorString = self:ShouldCraftButtonBeEnabled()
    if not enabled then
        return enabled, errorString
    end

    return self:GetMultiCraftMaxIterations() > 1
end


--[[ Crafting Multi Slot Base ]]--
ZO_CraftingMultiSlotBase = ZO_CallbackObject:Subclass()

function ZO_CraftingMultiSlotBase:New(...)
    local craftingSlot = ZO_CallbackObject.New(self)
    craftingSlot:Initialize(...)
    return craftingSlot
end

function ZO_CraftingMultiSlotBase:Initialize(owner, control, slotType, emptyTexture, multipleItemsTexture, craftingInventory, emptySlotIconTexture)
    self.owner = owner
    self.control = control
    self.slotType = slotType
    self.emptyTexture = emptyTexture
    self.multipleItemsTexture = multipleItemsTexture
    self.craftingInventory = craftingInventory

    if emptySlotIconTexture then
        self.emptyTexture = emptySlotIconTexture
        self.useEmptySlotIcon = true
        self.emptySlotOverrideIcon = self.control:GetNamedChild("EmptySlotIcon")
        internalassert(self.emptySlotOverrideIcon ~= nil)
    end

    -- required
    self.inventorySlotIcon = self.control:GetNamedChild("Icon")
    self.dropCallout = self.control:GetNamedChild("DropCallout")
    -- optional
    self.iconBg = self.control:GetNamedChild("IconBg")

    self.items = {}
    self:Refresh()
end

function ZO_CraftingMultiSlotBase:ShowDropCallout(isCorrectType)
    self.dropCallout:SetHidden(false)

    if isCorrectType then
        self.dropCallout:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    else
        self.dropCallout:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end
end

function ZO_CraftingMultiSlotBase:HideDropCallout()
    self.dropCallout:SetHidden(true)
end

-- Use to validate a list of virtually stacked items created from EnumerateInventorySlotsAndAddToScrollData
-- validItemFilterFn is optional
function ZO_CraftingMultiSlotBase:ValidateItemId(validItemIds, validItemFilterFn)
    local failed = false
    local itemsChanged = false

    for idx, item in ZO_NumericallyIndexedTableReverseIterator(self.items) do
        local bagId, slotIndex, itemInstanceId = item.bagId, item.slotIndex, item.itemInstanceId
        local itemInfo = validItemIds[itemInstanceId]
        if itemInfo and (validItemFilterFn == nil or validItemFilterFn(itemInfo.bag, itemInfo.index)) then
            itemsChanged = itemsChanged or item.bagId ~= itemInfo.bag or item.slotIndex ~= itemInfo.index
            item.bagId, item.slotIndex = itemInfo.bag, itemInfo.index
        else
            itemsChanged = true
            table.remove(self.items, idx)
            failed = true
        end
    end

    self:Refresh()
    if itemsChanged then
        self:FireCallbacks("ItemsChanged")
    end

    return not failed
end

do
    local function MatchesValidItemSlot(item, validItems)
        for i, validItem in ipairs(validItems) do
            if item.bagId == validItem.bagId and item.slotIndex == validItem.slotIndex then
                return true
            end
        end
        return false
    end

    -- Use to validate a list of slotDatas created from GetIndividualInventorySlotsAndAddToScrollData
    -- validItemFilterFn is optional
    function ZO_CraftingMultiSlotBase:ValidateSlottedItem(validItems, validItemFilterFn)
        local failed = false
        local needsValidation = {}
        for i = 1, #self.items do
            needsValidation[i] = true
        end

        for idx, item in ipairs(self.items) do
            if MatchesValidItemSlot(item, validItems) and (validItemFilterFn == nil or validItemFilterFn(item.bagId, item.slotIndex)) then
                needsValidation[idx] = nil
            end
        end

        if next(needsValidation) then
            -- There are items that were not validated, clear them out
            failed = true
            for i = #self.items, 1, -1 do
                if needsValidation[i] then
                    table.remove(self.items, i)
                end
            end
        end


        self:Refresh()
        if failed then
            self:FireCallbacks("ItemsChanged")
            return false
        else
            return true
        end
    end
end

function ZO_CraftingMultiSlotBase:ClearItemsInternal()
    ZO_ClearNumericallyIndexedTable(self.items)
end

function ZO_CraftingMultiSlotBase:ClearItems()
    if self:HasItems() then
        self:ClearItemsInternal()
        self:Refresh()
        self:FireCallbacks("ItemsChanged")
        return true
    end
    return false
end

-- Crafting slots work off of virtual inventories, so this item is used to represent all items with the instance id that is slotted here, not just this slot
function ZO_CraftingMultiSlotBase:AddItemInternal(bagId, slotIndex)
    if bagId and slotIndex and not self:ContainsBagAndSlot(bagId, slotIndex) then
        local item =
        {
            bagId = bagId,
            slotIndex = slotIndex,
            itemInstanceId = GetItemInstanceId(bagId, slotIndex),
        }
        table.insert(self.items, item)
        return true
    end
    return false
end

function ZO_CraftingMultiSlotBase:AddItem(bagId, slotIndex)
    local addedItem = self:AddItemInternal(bagId, slotIndex)
    self:Refresh()
    if addedItem then
        self:FireCallbacks("ItemSlotted", bagId, slotIndex)
        self:FireCallbacks("ItemsChanged")
    end
    return addedItem
end

function ZO_CraftingMultiSlotBase:RemoveItem(bagId, slotIndex)
    local removedItem = false
    for idx, item in ipairs(self.items) do
        if item.bagId == bagId and item.slotIndex == slotIndex then
            table.remove(self.items, idx)
            removedItem = true
            break
        end
    end
    self:Refresh()
    if removedItem then
        self:FireCallbacks("ItemsChanged")
    end
    return removedItem
end

function ZO_CraftingMultiSlotBase:Refresh()
    local numItems = #self.items

    local isEmpty = numItems == 0

    local icon
    local quantity
    if isEmpty then
        icon = self.emptyTexture
        quantity = 0
        ZO_Inventory_BindSlot(self.control, self.slotType, nil, nil)
    elseif numItems == 1 then
        local bagId, slotIndex = self:GetItemBagAndSlot(1)
        icon = GetItemInfo(bagId, slotIndex)
        quantity = self:GetStackCount()
        ZO_Inventory_BindSlot(self.control, self.slotType, slotIndex, bagId)
    else
        icon = self.multipleItemsTexture
        quantity = 0 -- hide quantity label
        ZO_Inventory_BindSlot(self.control, SLOT_TYPE_MULTIPLE_PENDING_CRAFTING_COMPONENTS, nil, nil)
    end

    local MEETS_REQUIREMENTS = nil
    local LOCKED = nil
    if self:HasAnimationRefs() then
        ZO_ItemSlot_SetupSlotBase(self.control, quantity, icon, MEETS_REQUIREMENTS, LOCKED, self:ShouldBeVisible())
    else
        ZO_ItemSlot_SetupSlot(self.control, quantity, icon, MEETS_REQUIREMENTS, LOCKED, self:ShouldBeVisible())
    end

    if self.iconBg then
        self.iconBg:SetHidden(not isEmpty)
    end

    if self.useEmptySlotIcon then
        if icon == "" then
            -- Empty string represents no icon, in this case we should just hide both inventory slot icon and our empty slot override
            self.emptySlotOverrideIcon:SetHidden(true)
            self.inventorySlotIcon:SetHidden(true)
        else
            self.emptySlotOverrideIcon:SetTexture(icon)
            self.emptySlotOverrideIcon:SetHidden(not isEmpty)
            self.inventorySlotIcon:SetHidden(isEmpty)
        end
    end

    self:UpdateTooltip()
end

function ZO_CraftingMultiSlotBase:GetStackCount()
    local quantity = 0
    if self.craftingInventory then
        for index = 1, self:GetNumItems() do
            -- non virtual items will have a stack count of 0, but we know that they represent exactly one in quantity
            quantity = quantity + zo_max(1, self.craftingInventory:GetStackCount(self:GetItemBagAndSlot(index)))
        end
    end
    return quantity
end

function ZO_CraftingMultiSlotBase:AddAnimationRef()
    self.animationRefs = (self.animationRefs or 0) + 1
end

function ZO_CraftingMultiSlotBase:RemoveAnimationRef()
    self.animationRefs = self.animationRefs - 1
    if self.animationRefs == 0 then
        self:Refresh()
    end
end

function ZO_CraftingMultiSlotBase:HasAnimationRefs()
    return self.animationRefs ~= nil and self.animationRefs > 0
end

function ZO_CraftingMultiSlotBase:HasItems()
    return #self.items > 0
end

function ZO_CraftingMultiSlotBase:HasOneItem()
    return #self.items == 1
end

function ZO_CraftingMultiSlotBase:HasMultipleItems()
    return #self.items > 1
end

function ZO_CraftingMultiSlotBase:GetNumItems()
    return #self.items
end

function ZO_CraftingMultiSlotBase:GetItemBagAndSlot(itemIndex)
    local item = itemIndex and self.items[itemIndex]
    if item then
        return item.bagId, item.slotIndex
    end
    return nil
end

function ZO_CraftingMultiSlotBase:GetItemInstanceId(itemIndex)
    local item = itemIndex and self.items[itemIndex]
    if item then
        return item.itemInstanceId
    end
    return nil
end

function ZO_CraftingMultiSlotBase:ContainsItemId(itemId)
    for _, item in ipairs(self.items) do
        if item.itemInstanceId == itemId then
            return true
        end
    end
    return false
end

function ZO_CraftingMultiSlotBase:ContainsBagAndSlot(bagId, slotIndex)
    for _, item in ipairs(self.items) do
        if item.bagId == bagId and item.slotIndex == slotIndex then
            return true
        end
    end
    return false
end

function ZO_CraftingMultiSlotBase:IsSlotControl(slotControl)
    return self.control == slotControl
end

function ZO_CraftingMultiSlotBase:GetControl()
    return self.control
end

function ZO_CraftingMultiSlotBase:UpdateTooltip()
    if self.control == WINDOW_MANAGER:GetMouseOverControl() then
        ZO_InventorySlot_OnMouseEnter(self.control)
    end
end

function ZO_CraftingMultiSlotBase:SetEmptyTexture(emptyTexture)
    self.emptyTexture = emptyTexture
    self:Refresh()
end

function ZO_CraftingMultiSlotBase:SetMultipleItemsTexture(multipleItemsTexture)
    self.multipleItemsTexture = multipleItemsTexture
    self:Refresh()
end

function ZO_CraftingMultiSlotBase:ShouldBeVisible()
    -- To be overridden if managing the visibility of the slot
    return true
end

--[[ Crafting Slot Base ]]--
-- This is a multislot that only permits single items. The multislot API can
-- be used, but the old single-slot api has been implemented on top.
-- Attempting to add multiple items using AddItem() will instead replace the
-- current item.
ZO_CraftingSlotBase = ZO_CraftingMultiSlotBase:Subclass()

function ZO_CraftingSlotBase:New(...)
    return ZO_CraftingMultiSlotBase.New(self, ...)
end

function ZO_CraftingSlotBase:Initialize(owner, control, slotType, emptyTexture, craftingInventory, emptySlotIcon)
    return ZO_CraftingMultiSlotBase.Initialize(self, owner, control, slotType, emptyTexture, "", craftingInventory, emptySlotIcon)
end

function ZO_CraftingSlotBase:SetItem(bagId, slotIndex)
    -- can be overriden for custom functionality, but should still call base or SetupItem
    self:SetupItem(bagId, slotIndex)
end

function ZO_CraftingSlotBase:SetupItem(bagId, slotIndex)
    local oldBagId, oldSlotIndex = self:GetBagAndSlot()
    self:ClearItemsInternal()
    self:AddItemInternal(bagId, slotIndex)
    self:Refresh()

    if oldBagId ~= bagId or oldSlotIndex ~= slotIndex then
        self:FireCallbacks("ItemsChanged")
    end
end

function ZO_CraftingSlotBase:AddItem(bagId, slotIndex)
    -- instead of adding, replace existing items
    self:SetItem(bagId, slotIndex)
end

function ZO_CraftingSlotBase:GetBagAndSlot()
    return self:GetItemBagAndSlot(1)
end

function ZO_CraftingSlotBase:IsBagAndSlot(bagId, slotIndex)
    return self:ContainsBagAndSlot(bagId, slotIndex)
end

function ZO_CraftingSlotBase:HasItem()
    return self:HasItems()
end

function ZO_CraftingSlotBase:IsItemId(itemId)
    return self:ContainsItemId(itemId)
end

function ZO_CraftingSlotBase:GetItemId()
    return self:GetItemInstanceId(1)
end

function ZO_CraftingSlot_OnInitialized(self)
    self.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingGlowAlphaAnimation", self:GetNamedChild("Glow"))
    local icon = self:GetNamedChild("Icon")
    icon:ClearAnchors()
    icon:SetAnchor(CENTER, self, CENTER)
    icon:SetDimensions(self:GetDimensions())
end

--[[ Crafting Slot Animation Base ]]--
ZO_CraftingSlotAnimationBase = ZO_Object:Subclass()

function ZO_CraftingSlotAnimationBase:New(...)
    local craftingSlotAnimationBase = ZO_Object.New(self)
    craftingSlotAnimationBase:Initialize(...)
    return craftingSlotAnimationBase
end

function ZO_CraftingSlotAnimationBase:Initialize(sceneName, visibilityPredicate)
    self.slots = {}

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function()
        if SCENE_MANAGER:IsShowing(sceneName) and (not visibilityPredicate or visibilityPredicate()) then
            self:Play(sceneName)
        end
    end)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function() self:Stop() end)
end

function ZO_CraftingSlotAnimationBase:AddSlot(slot)
    self.slots[#self.slots + 1] = slot
end

function ZO_CraftingSlotAnimationBase:Clear()
    if #self.slots > 0 then
        self.slots = {}
    end
end

function ZO_CraftingSlotAnimationBase:Play(sceneName)
    -- intended to be overridden
end

function ZO_CraftingSlotAnimationBase:Stop(sceneName)
    -- intended to be overridden
end

--[[ Global Utils ]]--
function ZO_CraftingUtils_GetCostToCraftString(cost)
    if cost > 0 then
        if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= cost then
            return zo_strformat(SI_CRAFTING_PERFORM_CRAFT, ZO_Currency_FormatKeyboard(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_AMOUNT_ICON))
        end
        return zo_strformat(SI_CRAFTING_PERFORM_CRAFT, ZO_Currency_FormatKeyboard(CURT_MONEY, cost, ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON))
    end

    return GetString(SI_CRAFTING_PERFORM_FREE_CRAFT)
end

function ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(menuBar)
    local function OnCraftStarted()
        if not menuBar:IsHidden() then
            ZO_MenuBar_SetAllButtonsEnabled(menuBar, false)
        end
    end

    local function OnCraftCompleted()
        ZO_MenuBar_SetAllButtonsEnabled(menuBar, true)
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", OnCraftStarted)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftCompleted)
end

function ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(keybindStripDescriptor)
    local function UpdateKeyBindDescriptorGroup()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(keybindStripDescriptor)
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", UpdateKeyBindDescriptorGroup)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", UpdateKeyBindDescriptorGroup)
end

local function ConnectStandardObjectToCraftingProcess(object)
    local function OnCraftStarted()
        if not object:GetControl():IsHidden() then
            object:SetEnabled(false)
        end
    end

    local function OnCraftCompleted()
        object:SetEnabled(true)
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", OnCraftStarted)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftCompleted)
end

function ZO_CraftingUtils_ConnectHorizontalScrollListToCraftingProcess(horizontalScrollList)
    ConnectStandardObjectToCraftingProcess(horizontalScrollList)
end

function ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(checkBox)
    local function OnCraftStarted()
        if not checkBox:IsHidden() then
            ZO_CheckButton_SetEnableState(checkBox, false)
        end
    end

    local function OnCraftCompleted()
        ZO_CheckButton_SetEnableState(checkBox, true)
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", OnCraftStarted)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftCompleted)
end

function ZO_CraftingUtils_ConnectSpinnerToCraftingProcess(spinner)
    ConnectStandardObjectToCraftingProcess(spinner)
end

function ZO_CraftingUtils_ConnectTreeToCraftingProcess(tree)
    ConnectStandardObjectToCraftingProcess(tree)
end

do
    internalassert(GetNumSmithingTraitItems() == 34, "Update when a new craftable trait type is made")
    local CRAFTABLE_TRAIT_TYPES = 
    {
        ITEM_TRAIT_TYPE_NONE,

        ITEM_TRAIT_TYPE_WEAPON_POWERED,
        ITEM_TRAIT_TYPE_WEAPON_CHARGED,
        ITEM_TRAIT_TYPE_WEAPON_PRECISE,
        ITEM_TRAIT_TYPE_WEAPON_INFUSED,
        ITEM_TRAIT_TYPE_WEAPON_DEFENDING,
        ITEM_TRAIT_TYPE_WEAPON_TRAINING,
        ITEM_TRAIT_TYPE_WEAPON_SHARPENED,
        ITEM_TRAIT_TYPE_WEAPON_DECISIVE,
        ITEM_TRAIT_TYPE_WEAPON_NIRNHONED,

        ITEM_TRAIT_TYPE_ARMOR_STURDY,
        ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE,
        ITEM_TRAIT_TYPE_ARMOR_REINFORCED,
        ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED,
        ITEM_TRAIT_TYPE_ARMOR_TRAINING,
        ITEM_TRAIT_TYPE_ARMOR_INFUSED,
        ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS,
        ITEM_TRAIT_TYPE_ARMOR_DIVINES,
        ITEM_TRAIT_TYPE_ARMOR_NIRNHONED,

        ITEM_TRAIT_TYPE_JEWELRY_ARCANE,
        ITEM_TRAIT_TYPE_JEWELRY_HEALTHY,
        ITEM_TRAIT_TYPE_JEWELRY_ROBUST,
        ITEM_TRAIT_TYPE_JEWELRY_TRIUNE,
        ITEM_TRAIT_TYPE_JEWELRY_INFUSED,
        ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE,
        ITEM_TRAIT_TYPE_JEWELRY_SWIFT,
        ITEM_TRAIT_TYPE_JEWELRY_HARMONY,
        ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY,
    }

    function ZO_CraftingUtils_GetSmithingTraitItemInfo()
        local traits = {}
        for _, traitType in ipairs(CRAFTABLE_TRAIT_TYPES) do
            local traitIndex = traitType + 1
            local _, name, icon, sellPrice, meetsUsageRequirement, itemStyle, quality = GetSmithingTraitItemInfo(traitIndex)
            table.insert(traits, {
                type = traitType,
                index = traitIndex,
                name = name,
                icon = icon,
                sellPrice = sellPrice,
                meetsUsageRequirement = meetsUsageRequirement,
                itemStyle = itemStyle,
                quality = quality,
            })
        end
        return traits
    end
end

do
    internalassert(SMITHING_FILTER_TYPE_MAX_VALUE == 7, "Update for new smithing filters")

    local ITEM_FILTER_TO_SMITHING_FILTER =
    {
       [ITEMFILTERTYPE_WEAPONS] = SMITHING_FILTER_TYPE_WEAPONS,
       [ITEMFILTERTYPE_ARMOR] = SMITHING_FILTER_TYPE_ARMOR,
       [ITEMFILTERTYPE_JEWELRY] = SMITHING_FILTER_TYPE_JEWELRY,
    }

    function ZO_CraftingUtils_GetSmithingFilterFromItem(bagId, slotIndex)
        local itemFilters = {GetItemFilterTypeInfo(bagId, slotIndex)}
        for _, itemFilter in ipairs(itemFilters) do
            local smithingFilter = ITEM_FILTER_TO_SMITHING_FILTER[itemFilter] 
            if smithingFilter then
                return smithingFilter
            end
        end
        return SMITHING_FILTER_TYPE_RAW_MATERIALS
    end

    function ZO_CraftingUtils_GetSmithingFilterFromItemFilter(itemFilter)
        return ITEM_FILTER_TO_SMITHING_FILTER[itemFilter] 
    end

    local SMITHING_FILTER_TO_ITEM_FILTER =
    {
        [SMITHING_FILTER_TYPE_WEAPONS] = ITEMFILTERTYPE_WEAPONS,
        [SMITHING_FILTER_TYPE_SET_WEAPONS] = ITEMFILTERTYPE_WEAPONS,
        [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_ARMOR,
        [SMITHING_FILTER_TYPE_SET_ARMOR] = ITEMFILTERTYPE_ARMOR,
        [SMITHING_FILTER_TYPE_JEWELRY] = ITEMFILTERTYPE_JEWELRY,
        [SMITHING_FILTER_TYPE_SET_JEWELRY] = ITEMFILTERTYPE_JEWELRY,
    }

    function ZO_CraftingUtils_GetItemFilterFromSmithingFilter(smithingFilter)
        return SMITHING_FILTER_TO_ITEM_FILTER[smithingFilter]
    end

    local TRAIT_CATEGORY_TO_SMITHING_FILTER =
    {
       [ITEM_TRAIT_TYPE_CATEGORY_WEAPON] = SMITHING_FILTER_TYPE_WEAPONS,
       [ITEM_TRAIT_TYPE_CATEGORY_ARMOR] = SMITHING_FILTER_TYPE_ARMOR,
       [ITEM_TRAIT_TYPE_CATEGORY_JEWELRY] = SMITHING_FILTER_TYPE_JEWELRY,
    }

    function ZO_CraftingUtils_GetSmithingFilterFromTrait(traitType)
        return TRAIT_CATEGORY_TO_SMITHING_FILTER[GetItemTraitTypeCategory(traitType)]
    end

    local SMITHING_FILTER_TO_BASE_FILTER =
    {
        [SMITHING_FILTER_TYPE_WEAPONS] = SMITHING_FILTER_TYPE_WEAPONS,
        [SMITHING_FILTER_TYPE_SET_WEAPONS] = SMITHING_FILTER_TYPE_WEAPONS,
        [SMITHING_FILTER_TYPE_ARMOR] = SMITHING_FILTER_TYPE_ARMOR,
        [SMITHING_FILTER_TYPE_SET_ARMOR] = SMITHING_FILTER_TYPE_ARMOR,
        [SMITHING_FILTER_TYPE_JEWELRY] = SMITHING_FILTER_TYPE_JEWELRY,
        [SMITHING_FILTER_TYPE_SET_JEWELRY] = SMITHING_FILTER_TYPE_JEWELRY,
    }

    function ZO_CraftingUtils_GetBaseSmithingFilter(smithingFilter)
        return SMITHING_FILTER_TO_BASE_FILTER[smithingFilter]
    end

    function ZO_CraftingUtils_IsBaseSmithingFilter(smithingFilter)
        if SMITHING_FILTER_TO_BASE_FILTER[smithingFilter] == nil then
            return true
        end
        return SMITHING_FILTER_TO_BASE_FILTER[smithingFilter] == smithingFilter
    end

    function ZO_CraftingUtils_CanSmithingFilterBeCraftedHere(smithingFilter)
        local baseFilter = ZO_CraftingUtils_GetBaseSmithingFilter(smithingFilter)
        if smithingFilter ~= baseFilter and not CanSmithingSetPatternsBeCraftedHere() then
            return false
        end
        if baseFilter == SMITHING_FILTER_TYPE_WEAPONS then
            return CanSmithingWeaponPatternsBeCraftedHere()
        elseif baseFilter == SMITHING_FILTER_TYPE_ARMOR then
            return CanSmithingApparelPatternsBeCraftedHere()
        elseif baseFilter == SMITHING_FILTER_TYPE_JEWELRY then
            return CanSmithingJewelryPatternsBeCraftedHere()
        end
    end
end

do
    local g_isCrafting = false

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function()
        g_isCrafting = true
    end)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        g_isCrafting = false
    end)

    function ZO_CraftingUtils_IsPerformingCraftProcess()
        return g_isCrafting or IsAwaitingCraftingProcessResponse()
    end
end

function ZO_CraftingUtils_IsCraftingWindowOpen()
    return ZO_Smithing_IsSceneShowing()
            or SYSTEMS:IsShowing("alchemy")
            or ZO_Enchanting_IsSceneShowing()
            or ZO_Provisioner_IsSceneShowing()
end

-- Crafting screens virtualize each item into stacks, but only refining items
-- can properly support deconstruction by virtual stack. In all other cases, eg.
-- enchanting, we need to send a message with each slot represented by the
-- virtual stack, which is what this function prepares for us.
function ZO_CraftingUtils_AddVirtualStackToDeconstructMessageAsRealStacks(virtualBagId, virtualSlotIndex, quantityToAdd)
    local instanceId = GetItemInstanceId(virtualBagId, virtualSlotIndex)
    local ALL_MATCHING_ITEMS = nil
    -- When there are more slots than items to add, we want to prioritize
    -- backpack items over bank items. Since the loop that adds these items pops
    -- from the end, we should generate our slots list so that the end of the list holds all the backpack items
    local slots = PLAYER_INVENTORY:GenerateAllSlotsInVirtualStackedItem(ALL_MATCHING_ITEMS, instanceId, INVENTORY_BANK, INVENTORY_BACKPACK)
    while quantityToAdd > 0 and slots[1] do
        local slot = table.remove(slots)
        local stackCount = zo_min(slot.stackCount, quantityToAdd)
        if not AddItemToDeconstructMessage(slot.bagId, slot.slotIndex, stackCount) then
            return false
        end
        quantityToAdd = quantityToAdd - stackCount
    end
    return quantityToAdd == 0 -- did we add as many items as we requested?
end

ZO_CRAFTING_TOOLTIP_STYLES = ZO_DeepTableCopy(ZO_TOOLTIP_STYLES)
for key,value in pairs(ZO_CRAFTING_TOOLTIP_STYLES) do
    value["horizontalAlignment"] = TEXT_ALIGN_CENTER

    if key ~= "topSection" then
        value["layoutPrimaryDirectionCentered"] = true
    end
end
