--[[ Crafting Slot Base ]]--
ZO_CraftingSlotBase = ZO_Object:Subclass()

function ZO_CraftingSlotBase:New(...)
    local craftingSlot = ZO_Object.New(self)
    craftingSlot:Initialize(...)
    return craftingSlot
end

function ZO_CraftingSlotBase:Initialize(owner, control, slotType, emptyTexture, craftingInventory, emptySlotIcon)
    self.owner = owner
    self.control = control
    self.slotType = slotType
    self.emptyTexture = emptyTexture
    self.craftingInventory = craftingInventory

    self.emptySlotIcon = emptySlotIcon
    if self.emptySlotIcon then
        self.control:GetNamedChild("EmptySlotIcon"):SetTexture(self.emptySlotIcon)
        self:ShowEmptySlotIcon(true)
    end

    self.iconBg = self.control:GetNamedChild("IconBg")

    self.dropCallout = self.control:GetNamedChild("DropCallout")

    self:SetItem(nil)
end

function ZO_CraftingSlotBase:ShowDropCallout(isCorrectType)
    self.dropCallout:SetHidden(false)

    if isCorrectType then
        self.dropCallout:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    else
        self.dropCallout:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end
end

function ZO_CraftingSlotBase:HideDropCallout()
    self.dropCallout:SetHidden(true)
end

function ZO_CraftingSlotBase:OnPassedValidation()
    -- intended to be overidden
end

function ZO_CraftingSlotBase:OnFailedValidation()
    -- intended to be overidden
end

function ZO_CraftingSlotBase:ValidateItemId(validItemIds)
    if self.bagId and self.slotIndex then
        -- An item might have been used up in a physical stack
        if validItemIds[self.itemInstanceId] then
            -- An item still exists in a physical stack, but might not exist in the virtual stack any more, update the indices
            local itemInfo = validItemIds[self.itemInstanceId]
            if self:IsBagAndSlot(itemInfo.bag, itemInfo.index) then
                self:SetupItem(itemInfo.bag, itemInfo.index)
            else
                self:SetItem(itemInfo.bag, itemInfo.index)
            end

            self:OnPassedValidation()
            return true
        else
            -- Item doesn't exist in a physical stack
            self:SetItem(nil)
            self:OnFailedValidation()
            return false
        end
    end
    return true
end

function ZO_CraftingSlotBase:SetItem(bagId, slotIndex)
    -- can be overriden for custom functionality, but should still call base or SetupItem
    self:SetupItem(bagId, slotIndex)
end

function ZO_CraftingSlotBase:SetupItem(bagId, slotIndex)
    self.bagId = bagId
    self.slotIndex = slotIndex

    self.itemInstanceId = GetItemInstanceId(self.bagId, self.slotIndex)

    if bagId and slotIndex then
        local icon = GetItemInfo(bagId, slotIndex)
        local stack = self:GetStackCount()
        if self:HasAnimationRefs() then
            ZO_ItemSlot_SetupSlotBase(self.control, stack, icon)
        else
            ZO_ItemSlot_SetupSlot(self.control, stack, icon)
        end

        self:ShowEmptySlotIcon(false)
    else
         if self:HasAnimationRefs() then
            ZO_ItemSlot_SetupSlotBase(self.control, 0, self.emptyTexture)
        else
            ZO_ItemSlot_SetupSlot(self.control, 0, self.emptyTexture)
        end

        self:ShowEmptySlotIcon(true)
    end

    if self.iconBg then
        self.iconBg:SetHidden(self:HasItem())
    end

    ZO_Inventory_BindSlot(self.control, self.slotType, self.slotIndex, self.bagId)

    self:UpdateTooltip()
end

function ZO_CraftingSlotBase:AddAnimationRef()
    self.animationRefs = (self.animationRefs or 0) + 1
end

function ZO_CraftingSlotBase:RemoveAnimationRef()
    self.animationRefs = self.animationRefs - 1
    if self.animationRefs == 0 then
        self:SetItem(self.bagId, self.slotIndex)
    end
end

function ZO_CraftingSlotBase:HasAnimationRefs()
    return self.animationRefs ~= nil and self.animationRefs > 0
end

function ZO_CraftingSlotBase:GetStackCount()
    if self:HasItem() then
        if self.craftingInventory then
            return self.craftingInventory:GetStackCount(self:GetBagAndSlot())
        end
        return 1
    end
    return 0
end

function ZO_CraftingSlotBase:GetBagAndSlot()
    return self.bagId, self.slotIndex
end

function ZO_CraftingSlotBase:IsBagAndSlot(bagId, slotIndex)
    return self.bagId == bagId and self.slotIndex == slotIndex
end

function ZO_CraftingSlotBase:HasItem()
    return self.bagId ~= nil and self.slotIndex ~= nil
end

function ZO_CraftingSlotBase:IsItemId(itemId)
    if self.bagId and self.slotIndex then
        return self.itemInstanceId == itemId
    end
    return false
end

function ZO_CraftingSlotBase:GetItemId()
    if self:HasItem() then
        return self.itemInstanceId
    end
end

function ZO_CraftingSlotBase:IsSlotControl(slotControl)
    return self.control == slotControl
end

function ZO_CraftingSlotBase:GetControl()
    return self.control
end

function ZO_CraftingSlotBase:UpdateTooltip()
    if self.control == WINDOW_MANAGER:GetMouseOverControl() then
        ZO_InventorySlot_OnMouseEnter(self.control)
    end
end

function ZO_CraftingSlotBase:SetEmptyTexture(emptyTexture)
    self.emptyTexture = emptyTexture
    if not self:HasItem() then
        self:SetItem(self.bagId, self.slotIndex)
    end
end

function ZO_CraftingSlotBase:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_CraftingSlotBase:ShowEmptySlotIcon(showIcon)
    if self.emptySlotIcon then
        self.control:GetNamedChild("EmptySlotIcon"):SetHidden(not showIcon)
        self.control:GetNamedChild("Icon"):SetHidden(showIcon)
    end
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
        if GetCarriedCurrencyAmount(CURT_MONEY) >= cost then
            return zo_strformat(SI_CRAFTING_PERFORM_CRAFT, ZO_CurrencyControl_FormatCurrency(cost))
        end
        return zo_strformat(SI_CRAFTING_PERFORM_CRAFT, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(cost)))
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

function ZO_CraftingUtils_IsTraitAppliedToWeapons(traitType)
    return traitType == ITEM_TRAIT_TYPE_WEAPON_POWERED
        or traitType == ITEM_TRAIT_TYPE_WEAPON_CHARGED
        or traitType == ITEM_TRAIT_TYPE_WEAPON_PRECISE
        or traitType == ITEM_TRAIT_TYPE_WEAPON_INFUSED
        or traitType == ITEM_TRAIT_TYPE_WEAPON_DEFENDING
        or traitType == ITEM_TRAIT_TYPE_WEAPON_TRAINING
        or traitType == ITEM_TRAIT_TYPE_WEAPON_SHARPENED
        or traitType == ITEM_TRAIT_TYPE_WEAPON_DECISIVE
        or traitType == ITEM_TRAIT_TYPE_WEAPON_INTRICATE
        or traitType == ITEM_TRAIT_TYPE_WEAPON_ORNATE
		or traitType == ITEM_TRAIT_TYPE_WEAPON_NIRNHONED
end

function ZO_CraftingUtils_IsTraitAppliedToArmor(traitType)
    return traitType == ITEM_TRAIT_TYPE_ARMOR_STURDY
        or traitType == ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE
        or traitType == ITEM_TRAIT_TYPE_ARMOR_REINFORCED
        or traitType == ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED
        or traitType == ITEM_TRAIT_TYPE_ARMOR_TRAINING
        or traitType == ITEM_TRAIT_TYPE_ARMOR_INFUSED
        or traitType == ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS
        or traitType == ITEM_TRAIT_TYPE_ARMOR_DIVINES
        or traitType == ITEM_TRAIT_TYPE_ARMOR_ORNATE
        or traitType == ITEM_TRAIT_TYPE_ARMOR_INTRICATE
		or traitType == ITEM_TRAIT_TYPE_ARMOR_NIRNHONED
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
        return g_isCrafting
    end
end

function ZO_CraftingUtils_IsCraftingWindowOpen()
    return SCENE_MANAGER:IsShowing("smithing")
            or SYSTEMS:IsShowing("alchemy")
            or SCENE_MANAGER:IsShowing("enchanting")
            or ZO_Provisioner_IsSceneShowing()
end

--[[ Gamepad Crafting Ingredient Bar ]]--
ZO_GamepadCraftingIngredientBar = ZO_Object:Subclass()

function ZO_GamepadCraftingIngredientBar:New(...)
    local ingredientBar = ZO_Object.New(self)
    ingredientBar:Initialize(...)
    return ingredientBar
end

function ZO_GamepadCraftingIngredientBar:Initialize(control, slotSpacing)
    self.control = control
    self.slotSpacing = slotSpacing

    self.slotCenterControl = self.control:GetNamedChild("SlotCenter")

    self.dataTypes = {}
    self:Clear()
end

function ZO_GamepadCraftingIngredientBar:Clear()
    self.dataList = {}

    if self.dataTypes then
        for key, dataTypeInfo in pairs(self.dataTypes) do
            dataTypeInfo.pool:ReleaseAllObjects()
        end
    end
end

function ZO_GamepadCraftingIngredientBar:AddDataTemplate(templateName, setupFunction)
    if not self.dataTypes[templateName] then
        local dataTypeInfo = {
            pool = ZO_ControlPool:New(templateName, self.slotCenterControl),
            setupFunction = setupFunction,
        }
        self.dataTypes[templateName] = dataTypeInfo
    end
end

function ZO_GamepadCraftingIngredientBar:AddEntry(templateName, data)
    local dataTypeInfo = self.dataTypes[templateName]
    if dataTypeInfo then
        self.dataList[#self.dataList + 1] = data
        
        local control, key = dataTypeInfo.pool:AcquireObject()
        control.key = key
        control.templateName = templateName

        data.control = control

        dataTypeInfo.setupFunction(control, data)
    end
end

function ZO_GamepadCraftingIngredientBar:Commit()
    -- alter x offsets based on number of ingredients (so the slots stay centered relative to parent)
    local numIngredients = #self.dataList  
    local offsetX = (numIngredients - 1) * -self.slotSpacing * 0.5

    for i, data in ipairs(self.dataList) do
        -- adjust the x offset
        data.control:SetAnchor(CENTER, self.slotCenterControl, CENTER, offsetX, 0)
        offsetX = offsetX + self.slotSpacing
    end
end

ZO_CRAFTING_TOOLTIP_STYLES = ZO_DeepTableCopy(ZO_TOOLTIP_STYLES)
for key,value in pairs(ZO_CRAFTING_TOOLTIP_STYLES) do
    value["horizontalAlignment"] = TEXT_ALIGN_CENTER

    if key ~= "topSection" then
        value["layoutPrimaryDirectionCentered"] = true
    end
end
