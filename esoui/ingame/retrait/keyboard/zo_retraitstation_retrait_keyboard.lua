ZO_RETRAIT_TRAIT_LIST_ROW_HEIGHT = 58

local TRAIT_LIST_TRAIT_ENTRY = 1

ZO_RetraitStation_Retrait_Keyboard = ZO_RetraitStation_Retrait_Base:Subclass()

function ZO_RetraitStation_Retrait_Keyboard:Initialize(control, owner)
    ZO_RetraitStation_Retrait_Base.Initialize(self, control)
    self.owner = owner
    SYSTEMS:RegisterKeyboardObject("retrait", self)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    RETRAIT_STATION_RETRAIT_FRAGMENT = self.fragment
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:HandleDirtyEvent()
            self:RemoveItemFromRetrait()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
        end
    end)

    self:InitializeSlots()
    self.resultTooltip = self.control:GetNamedChild("ResultTooltip")
    self.traitContainer = self.control:GetNamedChild("TraitContainer")
    self.traitList = self.traitContainer:GetNamedChild("List")
    ZO_ScrollList_Initialize(self.traitList)

    local function SetupTraitRow(...)
        self:SetupTraitRow(...)
    end

    local function OnTraitRowReset(...)
        self:OnTraitRowReset(...)
    end

    local NO_ON_HIDDEN_CALLBACK = nil
    local NO_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.traitList, TRAIT_LIST_TRAIT_ENTRY, "ZO_RetraitTraitListRow", ZO_RETRAIT_TRAIT_LIST_ROW_HEIGHT, SetupTraitRow, NO_ON_HIDDEN_CALLBACK, NO_SELECT_SOUND, OnTraitRowReset)
    ZO_ScrollList_AddResizeOnScreenResize(self.traitList)
    ZO_ScrollList_EnableHighlight(self.traitList, "ZO_TallListHighlight")
    ZO_ScrollList_EnableSelection(self.traitList, "ZO_TallListSelectedHighlight", function(...) self:OnTraitSelectionChanged(...) end)
    ZO_ScrollList_SetDeselectOnReselect(self.traitList, false)
    self.traitListData = ZO_ScrollList_GetDataList(self.traitList)
end

function ZO_RetraitStation_Retrait_Keyboard:InitializeInventory()
    self.inventoryControl = self.control:GetNamedChild("Inventory")
    self.inventory = ZO_Retrait_Inventory_Keyboard:New(self, self.inventoryControl, SLOT_TYPE_CRAFTING_COMPONENT)
end

function ZO_RetraitStation_Retrait_Keyboard:InitializeSlots()
    local slotContainer = self.control:GetNamedChild("SlotContainer")
    self.retraitSlot = ZO_RetraitStationRetraitSlot:New(self, slotContainer:GetNamedChild("ItemRetraitSlot"), SLOT_TYPE_PENDING_RETRAIT_ITEM, self.inventory)
    self.retraitSlot:RegisterCallback("ItemsChanged", function()
        self:OnSlotChanged()
    end)

    self.retraitCostSlot = slotContainer:GetNamedChild("RetraitCostSlot")
    local minRetraitCost = 0
    ZO_ItemSlot_SetAlwaysShowStackCount(self.retraitCostSlot, true, minRetraitCost)
    self.awaitingLabel = slotContainer:GetNamedChild("AwaitingLabel")
    self:RefreshCostSlot()

    self.slotAnimation = ZO_CraftingCreateSlotAnimation:New("retrait_keyboard_root", function() return self:IsShowing() end)
    self.slotAnimation:AddSlot(self.retraitSlot)
    self.slotAnimation:AddSlot(self.retraitCostSlot)
end

function ZO_RetraitStation_Retrait_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Clear selections
        {
            name = GetString(SI_CRAFTING_CLEAR_SELECTIONS),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:SetRetraitSlotItem()
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:HasItemSlotted()
            end,
        },

        -- Perform craft
        {
            name = GetString(SI_RETRAIT_STATION_PERFORM_RETRAIT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                self:PerformRetrait()
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:HasValidSelections()
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:HasItemSlotted()
            end,
        },
    }
end

function ZO_RetraitStation_Retrait_Keyboard:IsShowing()
    return self.fragment:IsShowing()
end

function ZO_RetraitStation_Retrait_Keyboard:GetKeybindDescriptor()
    return self.keybindStripDescriptor
end

function ZO_RetraitStation_Retrait_Keyboard:UpdateKeybinds()
    self.owner:UpdateKeybinds()
end

function ZO_RetraitStation_Retrait_Keyboard:SetHidden(hidden)
    self.control:SetHidden(hidden)
    if not hidden then
        CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
        -- there's no chance of failure on the craft, so we'll fill out the fail sound with a sound that already exists instead of making a new one
        CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.RETRAITING_RETRAIT_TOOLTIP_GLOW_SUCCESS, SOUNDS.BLACKSMITH_IMPROVE_TOOLTIP_GLOW_FAIL)
        if self.dirty then
            self:Refresh()
        end
    end
end

function ZO_RetraitStation_Retrait_Keyboard:Refresh()
    self.inventory:HandleDirtyEvent()
    ZO_RetraitStation_Retrait_Base.Refresh(self)
end

function ZO_RetraitStation_Retrait_Keyboard:IsItemSlotted(bagId, slotIndex)
    return self.retraitSlot:IsBagAndSlot(bagId, slotIndex)
end

function ZO_RetraitStation_Retrait_Keyboard:HasItemSlotted()
    return self.retraitSlot:HasItem()
end

function ZO_RetraitStation_Retrait_Keyboard:HasValidSelections()
    local hasItemAndTrait = self.retraitSlot:HasItem() and self.selectedTrait ~= nil

    local retraitCost, retraitCurrency, retraitCurrencyLocation = GetItemRetraitCost()
    local hasEnoughCurrency = retraitCost <= GetCurrencyAmount(retraitCurrency, retraitCurrencyLocation)

    local errorString
    if not hasEnoughCurrency then
        errorString = GetString("SI_RETRAITRESPONSE", RETRAIT_RESPONSE_INSUFFICIENT_FUNDS)
    end

    return (hasItemAndTrait and hasEnoughCurrency), errorString
end

function ZO_RetraitStation_Retrait_Keyboard:ShowAppropriateSlotDropCallouts()
    self.retraitSlot:ShowDropCallout()
end

function ZO_RetraitStation_Retrait_Keyboard:HideAllSlotDropCallouts()
    self.retraitSlot:HideDropCallout()
end

function ZO_RetraitStation_Retrait_Keyboard:OnFilterChanged(filterType)
    self.filterType = filterType
    self.awaitingLabel:SetText(GetString("SI_SMITHINGFILTERTYPE_IMPROVEAWAITING", filterType))

    self.retraitSlot:OnFilterChanged(filterType)
    self:SetRetraitSlotItem()
    ClearCursor()
end

function ZO_RetraitStation_Retrait_Keyboard:OnInventoryUpdate(validItems)
    self.retraitSlot:ValidateSlottedItem(validItems)
end

function ZO_RetraitStation_Retrait_Keyboard:SetRetraitSlotItem(bagId, slotIndex)
    self.retraitSlot:SetItem(bagId, slotIndex)
end

function ZO_RetraitStation_Retrait_Keyboard:RefreshCostSlot()
    if self:HasItemSlotted() then
        local retraitCost, retraitCurrency, retraitCurrencyLocation = GetItemRetraitCost()
        local meetsUsageRequirements = retraitCost <= GetCurrencyAmount(retraitCurrency, retraitCurrencyLocation)
        local currencyIcon = ZO_Currency_GetKeyboardCurrencyIcon(retraitCurrency)
        ZO_ItemSlot_SetupSlot(self.retraitCostSlot, retraitCost, currencyIcon, meetsUsageRequirements)
        self.retraitCostSlot.currencyType = retraitCurrency

        -- create the tooltip string for what research is required for this item now,
        -- so we don't have to create it every time we mouse over an unknown trait
        local bag, slot = self.retraitSlot:GetBagAndSlot()
        self:UpdateRequireResearchTooltipString(bag, slot)

        self.awaitingLabel:SetHidden(true)
        self.retraitCostSlot:SetHidden(false)
    else
        self.retraitCostSlot.currencyType = CURT_NONE
        self.requiredResearchTooltipString = nil

        self.awaitingLabel:SetHidden(false)
        self.retraitCostSlot:SetHidden(true)
    end
end

function ZO_RetraitStation_Retrait_Keyboard:OnSlotChanged()
    local hasItem = self:HasItemSlotted()
    self.traitContainer:SetHidden(not hasItem)

    self:RefreshCostSlot()
    self:RefreshTraitList()

    self:UpdateKeybinds()
    self:UpdateResultTooltip()

    self.inventory:HandleVisibleDirtyEvent()
end

function ZO_RetraitStation_Retrait_Keyboard:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
    self:SetRetraitSlotItem(bagId, slotIndex)
end

function ZO_RetraitStation_Retrait_Keyboard:RemoveItemFromRetrait(inventorySlot, bagId, slotIndex)
    self:SetRetraitSlotItem()
end

function ZO_RetraitStation_Retrait_Keyboard:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    return self:IsItemSlotted(bagId, slotIndex)
end

function ZO_RetraitStation_Retrait_Keyboard:AddItemToCraft(bagId, slotIndex)
    self:SetRetraitSlotItem(bagId, slotIndex)
end

function ZO_RetraitStation_Retrait_Keyboard:RemoveItemFromCraft(bagId, slotIndex)
    self:SetRetraitSlotItem()
end

function ZO_RetraitStation_Retrait_Keyboard:PerformRetrait()
    if self:HasValidSelections() then
        local bag, slot = self.retraitSlot:GetBagAndSlot()
        self:ShowRetraitDialog(bag, slot, self.selectedTrait)
    end
end

function ZO_RetraitStation_Retrait_Keyboard:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_RetraitStation_Retrait_Keyboard:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_RetraitStation_Retrait_Keyboard:RefreshTraitList()

    ZO_ScrollList_Clear(self.traitList)
    ZO_ScrollList_ResetToTop(self.traitList)

    self.mouseOverTraitControl = nil

    if self:HasItemSlotted() then
        local bag, slot = self.retraitSlot:GetBagAndSlot()

        local slottedItemTrait = GetItemTrait(bag, slot)
        local traitData = ZO_RETRAIT_STATION_MANAGER:GetTraitInfoForCategory(GetItemTraitCategory(bag, slot))
        internalassert(traitData)

        for index, traitRowData in ipairs(traitData) do
            local trait = traitRowData.traitType

            if slottedItemTrait ~= trait then
                local knownTrait = IsItemTraitKnownForRetraitResult(bag, slot, trait)

                local rowControlData =
                    {
                        trait = trait,
                        name = traitRowData.traitName,
                        icon = traitRowData.traitItemIcon,
                        knownTrait = knownTrait,
                    }
                table.insert(self.traitListData, ZO_ScrollList_CreateDataEntry(TRAIT_LIST_TRAIT_ENTRY, rowControlData))
            end
        end
    end

    ZO_ScrollList_Commit(self.traitList)
end

function ZO_RetraitStation_Retrait_Keyboard:SetupTraitRow(rowControl, data)
    rowControl.data = data
    rowControl.nameControl:SetText(data.name)
    rowControl.iconControl:SetTexture(data.icon)

    local knownTrait = data.knownTrait
    rowControl.lockIconControl:SetHidden(knownTrait)

    if knownTrait then
        rowControl.iconControl:SetAlpha(1)
        rowControl.nameControl:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    else
        rowControl.iconControl:SetAlpha(.3)
        rowControl.nameControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_RetraitStation_Retrait_Keyboard:OnTraitRowReset(rowControl)
    rowControl.data = nil

    ZO_ObjectPool_DefaultResetControl(rowControl)
end

function ZO_RetraitStation_Retrait_Keyboard:UpdateResultTooltip()
    local hasItemSlotted = self:HasItemSlotted()

    self.resultTooltip:SetHidden(not hasItemSlotted)
    self.resultTooltip:ClearLines()

    ClearTooltip(InformationTooltip)

    if hasItemSlotted then
        local layoutSelectedTraitItemTooltip = true
        local bag, slot = self.retraitSlot:GetBagAndSlot()
        if self.mouseOverTraitControl and not ZO_CraftingUtils_IsPerformingCraftProcess() then
            local traitData = self.mouseOverTraitControl.data
            local mouseOverTrait = traitData.trait
            if traitData.knownTrait then
                self.resultTooltip:SetPendingRetraitItem(bag, slot, mouseOverTrait)
            else
                InitializeTooltip(InformationTooltip, self.mouseOverTraitControl, BOTTOM, 0, 0)

                local DEFAULT_FONT = ""
                local r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
                InformationTooltip:AddLine(traitData.name, DEFAULT_FONT, r, g, b)

                r, g, b = ZO_ERROR_COLOR:UnpackRGB()
                InformationTooltip:AddLine(self.requiredResearchTooltipString, DEFAULT_FONT, r, g, b, TOP, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
            end

            layoutSelectedTraitItemTooltip = not traitData.knownTrait
        end

        if layoutSelectedTraitItemTooltip then
            local selectedTraitData = ZO_ScrollList_GetSelectedData(self.traitList)
            if selectedTraitData then
                self.resultTooltip:SetPendingRetraitItem(bag, slot, self.selectedTrait)
            else
                self.resultTooltip:SetBagItem(bag, slot)
            end
        end
    end
end

function ZO_RetraitStation_Retrait_Keyboard:OnTraitSelectionChanged(previouslySelectedData, selectedData, selectingDuringRebuild)
    local hasSelectedData = selectedData ~= nil

    if hasSelectedData then
        self.selectedTrait = selectedData.trait
        CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
        -- there's no chance of failure on the craft, so we'll fill out the fail sound with a sound that already exists instead of making a new one
        CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.RETRAITING_RETRAIT_TOOLTIP_GLOW_SUCCESS, SOUNDS.BLACKSMITH_IMPROVE_TOOLTIP_GLOW_FAIL)
    else
        self.selectedTrait = nil
    end

    self:UpdateKeybinds()
    self:UpdateResultTooltip()
end

function ZO_RetraitStation_Retrait_Keyboard:OnTraitRowMouseEnter(control)
    ZO_ScrollList_MouseEnter(self.traitList, control)

    self.mouseOverTraitControl = control
    self:UpdateResultTooltip()
end

function ZO_RetraitStation_Retrait_Keyboard:OnTraitRowMouseExit(control)
    ZO_ScrollList_MouseExit(self.traitList, control)

    self.mouseOverTraitControl = nil
    self:UpdateResultTooltip()
end

function ZO_RetraitStation_Retrait_Keyboard:OnTraitRowMouseUp(control, button, upInside)
    if upInside then
        if control.data.knownTrait then -- Can only select known traits
            ZO_ScrollList_MouseClick(self.traitList, control)
        end
    end
end

function ZO_RetraitStation_Retrait_Keyboard:OnRetraitAnimationsStopped()
    if self:IsShowing() then
        self:SetRetraitSlotItem()
    end
end

-----
--  ZO_Retrait_Inventory_Keyboard
-----

ZO_Retrait_Inventory_Keyboard = ZO_CraftingInventory:Subclass()

function ZO_Retrait_Inventory_Keyboard:New(...)
    return ZO_CraftingInventory.New(self, ...)
end

do
    local function UpdateInventorySlots(infoBar)
        local slotsLabel = infoBar:GetNamedChild("FreeSlots")
        local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
        if numUsedSlots < numSlots then
            slotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
        else
            slotsLabel:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
        end
    end

    local function ZO_Retrait_Inventory_Keyboard_ConnectInfoBar(infoBar)
        if infoBar.isConnected then return end

        -- setup the currency label, which will manage its own dirty state
        ZO_SharedInventory_ConnectPlayerCurrencyLabel(infoBar:GetNamedChild("Money"), CURT_MONEY, CURRENCY_LOCATION_CHARACTER, ZO_KEYBOARD_CURRENCY_OPTIONS)
        local SHOW_CURRENCY_CAP = true
        ZO_SharedInventory_ConnectPlayerCurrencyLabel(infoBar:GetNamedChild("RetraitCurrency"), CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT, ZO_KEYBOARD_CURRENCY_OPTIONS, SHOW_CURRENCY_CAP)

        -- Setup handling for slot counts changing
        local slotsDirty = true

        local function OnInventoryUpdated()
            if infoBar:IsHidden() then
                slotsDirty = true
            else
                UpdateInventorySlots(infoBar)
                slotsDirty = false
            end
        end

        infoBar:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdated)
        infoBar:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdated)

        local function CleanDirty()
            if slotsDirty then
                slotsDirty = false
                UpdateInventorySlots(infoBar)
            end
        end

        infoBar:SetHandler("OnEffectivelyShown", CleanDirty)

        if not infoBar:IsHidden() then
            CleanDirty()
        end

        infoBar.isConnected = true
    end

    function ZO_Retrait_Inventory_Keyboard:Initialize(owner, control, slotType, noDragging)
        ZO_CraftingInventory.Initialize(self, control, slotType, noDragging, ZO_Retrait_Inventory_Keyboard_ConnectInfoBar)
        self.owner = owner
        self.filterType = ZO_RETRAIT_FILTER_TYPE_WEAPONS

        self:SetFilters({
            self:CreateNewTabFilterData(SMITHING_FILTER_TYPE_JEWELRY, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_JEWELRY), "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds", "EsoUI/Art/Crafting/jewelry_tabIcon_icon_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_jewelry_disabled.dds"),
            self:CreateNewTabFilterData(SMITHING_FILTER_TYPE_ARMOR, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_ARMOR), "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_armor_disabled.dds"),
            self:CreateNewTabFilterData(SMITHING_FILTER_TYPE_WEAPONS, GetString("SI_SMITHINGFILTERTYPE", SMITHING_FILTER_TYPE_WEAPONS), "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_over.dds", "EsoUI/Art/Inventory/inventory_tabIcon_weapons_disabled.dds"),
        })

        self:SetSortColumnHidden({ sellInformationSortOrder = true }, true)
    end
end

function ZO_Retrait_Inventory_Keyboard:ChangeFilter(filterData)
    ZO_CraftingInventory.ChangeFilter(self, filterData)

    self.filterType = filterData.descriptor

    self:SetNoItemLabelText(GetString("SI_SMITHINGFILTERTYPE_IMPROVENONE", self.filterType))


    self.owner:OnFilterChanged(self.filterType)
    self:HandleDirtyEvent()
end

function ZO_Retrait_Inventory_Keyboard:IsLocked(bagId, slotIndex)
    return ZO_CraftingInventory.IsLocked(self, bagId, slotIndex) or self.owner:IsItemSlotted(bagId, slotIndex)
end

function ZO_Retrait_Inventory_Keyboard:Refresh(data)
    local USE_WORN_BAG = true
    local validItemIds = self:GetIndividualInventorySlotsAndAddToScrollData(ZO_RetraitStation_CanItemBeRetraited, ZO_RetraitStation_DoesItemPassFilter, self.filterType, data, USE_WORN_BAG)
    self.owner:OnInventoryUpdate(validItemIds)

    self:SetNoItemLabelHidden(#data > 0)
end

function ZO_Retrait_Inventory_Keyboard:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts()
end

function ZO_Retrait_Inventory_Keyboard:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end

-----
-- ZO_RetraitStationRetraitSlot
-----

ZO_RetraitStationRetraitSlot = ZO_CraftingSlotBase:Subclass()

function ZO_RetraitStationRetraitSlot:New(...)
    return ZO_CraftingSlotBase.New(self, ...)
end

function ZO_RetraitStationRetraitSlot:Initialize(owner, control, slotType, craftingInventory)
    ZO_CraftingSlotBase.Initialize(self, owner, control, slotType, "", craftingInventory)

    self.nameLabel = control:GetNamedChild("Name")
end

function ZO_RetraitStationRetraitSlot:SetItem(bagId, slotIndex)
    local hadItem = self:HasItem()
    local oldItemInstanceId = self:GetItemId()

    self:SetupItem(bagId, slotIndex)

    if not self.control:IsHidden() then
        if self:HasItem() then
            if oldItemInstanceId ~= self:GetItemId() then
                PlaySound(SOUNDS.RETRAITING_ITEM_TO_RETRAIT_PLACED)
            end
        elseif hadItem then
            PlaySound(SOUNDS.RETRAITING_ITEM_TO_RETRAIT_REMOVED)
        end
    end

    if self.nameLabel then
        if self:HasItem() then
            self.nameLabel:SetHidden(false)
            self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bagId, slotIndex)))

            local displayQuality = GetItemDisplayQuality(bagId, slotIndex)
            self.nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality))
        else
            self.nameLabel:SetHidden(true)
        end
    end
end

function ZO_RetraitStationRetraitSlot:OnFilterChanged(filterType)
    self:SetEmptyTexture(ZO_CraftingUtils_GetItemSlotTextureFromSmithingFilter(filterType))
end

function ZO_RetraitStationRetraitSlot:ShowDropCallout()
    self.dropCallout:SetHidden(false)
    self.dropCallout:SetTexture("EsoUI/Art/Crafting/crafting_alchemy_goodSlot.dds")
end

-- Global XML functions

function ZO_RetraitStation_Retrait_Keyboard_OnTraitRowMouseEnter(control)
    ZO_RETRAIT_KEYBOARD:OnTraitRowMouseEnter(control)
end

function ZO_RetraitStation_Retrait_Keyboard_OnTraitRowMouseExit(control)
    ZO_RETRAIT_KEYBOARD:OnTraitRowMouseExit(control)
end

function ZO_RetraitStation_Retrait_Keyboard_OnTraitRowMouseUp(control, button, upInside)
    ZO_RETRAIT_KEYBOARD:OnTraitRowMouseUp(control, button, upInside)
end

function ZO_RetraitStation_Retrait_Keyboard_OnRetraitCostSlotMouseEnter(control)
    if control.currencyType ~= CURT_NONE then
        local offsetX = 0
        local offsetY = -5
        InitializeTooltip(InformationTooltip, control, BOTTOM, offsetX, offsetY)
        local DEFAULT_FONT = ""
        local r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
        local currencyName = ZO_Currency_GetAmountLabel(control.currencyType)
        InformationTooltip:AddLine(currencyName, DEFAULT_FONT, r, g, b)
    end
end

function ZO_RetraitStation_Retrait_Keyboard_OnRetraitCostSlotMouseExit(control)
    ClearTooltip(InformationTooltip)
end