ZO_RESTYLE_SHEET_CONTAINER =
{
    PRIMARY = 1,
    SECONDARY = 2,
}

-----------------------
-- Restyle Slot Base --
-----------------------

ZO_RestyleSlot_Base = ZO_InitializingObject:Subclass()

ZO_RESTYLE_SLOT_WIDTH = 136
ZO_RESTYLE_SLOT_HEIGHT = 63

ZO_RESTYLE_SLOT_ICON_WIDTH  = 63
ZO_RESTYLE_SLOT_ICON_HEIGHT = ZO_RESTYLE_SLOT_ICON_WIDTH

ZO_RESTYLE_SLOT_ICON_INNER_WIDTH = ZO_RESTYLE_SLOT_ICON_WIDTH - 8
ZO_RESTYLE_SLOT_ICON_INNER_HEIGHT = ZO_RESTYLE_SLOT_ICON_INNER_WIDTH

do
    local GRID_PADDING_X = 30
    local GRID_PADDING_Y = 12

    function ZO_RestyleSlot_Base:Initialize(owner, restyleSlotType, gridData, container)
        self.owner = owner
        local offsetX = (ZO_RESTYLE_SLOT_WIDTH + GRID_PADDING_X) * (gridData.column - 1)
        local offsetY = (ZO_RESTYLE_SLOT_HEIGHT + GRID_PADDING_Y) * (gridData.row - 1)
        local controlName = gridData.controlName or string.format("Row%d_Col%d", gridData.row, gridData.column)
        local control = CreateControlFromVirtual("$(parent)" .. controlName, container, self:GetControlTemplate())
        control:SetAnchor(TOPLEFT, container, TOPLEFT, offsetX, offsetY)

        local itemSlotControl = control:GetNamedChild("ItemSlot")
        itemSlotControl:SetHandler("OnMouseUp", function(_, button, upInside)
            self:OnIconMouseUp(button, upInside)
        end)
        itemSlotControl:SetHandler("OnMouseEnter", function()
            self:OnIconMouseEnter()
        end)
        itemSlotControl:SetHandler("OnMouseExit", function()
            self:OnIconMouseExit()
        end)
        itemSlotControl.iconTexture = itemSlotControl:GetNamedChild("Icon")

        self.control = control
        self.itemSlotControl = itemSlotControl
        self.dyeControls = control:GetNamedChild("Dyes").dyeControls
        self.restyleSlotData = ZO_RestyleSlotData:New(owner:GetRestyleMode(), ZO_RESTYLE_DEFAULT_SET_INDEX, restyleSlotType)
    end
end

function ZO_RestyleSlot_Base:GetControlTemplate()
    return "ZO_RestyleSlotsSheet_Slot_Keyboard"
end

function ZO_RestyleSlot_Base:GetControl()
    return self.control
end

function ZO_RestyleSlot_Base:GetItemSlotControl()
    return self.itemSlotControl
end

function ZO_RestyleSlot_Base:GetDyeControls()
    return self.dyeControls
end

function ZO_RestyleSlot_Base:GetRestyleSlotData()
    return self.restyleSlotData
end

function ZO_RestyleSlot_Base:OnIconMouseUp(button, upInside)
    --To be overriden
end

function ZO_RestyleSlot_Base:OnIconMouseEnter()
    --To be overriden
end

function ZO_RestyleSlot_Base:OnIconMouseExit()
    --To be overriden
end

function ZO_RestyleSlot_Base:SetRestyleSetIndex(restyleSetIndex)
    self.restyleSlotData:SetRestyleSetIndex(restyleSetIndex)
end

function ZO_RestyleSlot_Base:RefreshVisible()
    --Can be overriden
end

----------------------------
-- Equipment Restyle Slot --
----------------------------

ZO_RestyleSlot_Equipment = ZO_RestyleSlot_Base:Subclass()

function ZO_RestyleSlot_Equipment:OnIconMouseEnter()
    ZO_InventorySlot_OnMouseEnter(self.itemSlotControl)
end

function ZO_RestyleSlot_Equipment:OnIconMouseExit()
    ZO_InventorySlot_OnMouseExit(self.itemSlotControl)
end

function ZO_RestyleSlot_Equipment:RefreshVisible()
    local restyleSlotType = self.restyleSlotData:GetRestyleSlotType()
    if restyleSlotType == EQUIP_SLOT_OFF_HAND or restyleSlotType == EQUIP_SLOT_BACKUP_OFF then
        local activeEquipSlot = ZO_Restyle_GetActiveOffhandEquipSlotType()
        self.control:SetHidden(restyleSlotType ~= activeEquipSlot)
    end
end

------------------------------
-- Collectible Restyle Slot --
------------------------------

ZO_RestyleSlot_Collectible = ZO_RestyleSlot_Base:Subclass()

do
    local SHOW_NICKNAME = true
    local SHOW_PURCHASABLE_HINT = true
    local SHOW_BLOCK_REASON = true

    function ZO_RestyleSlot_Collectible:OnIconMouseEnter()
        local collectibleId = self.restyleSlotData:GetId()
        if collectibleId > 0 then
            InitializeTooltip(ItemTooltip, self.itemSlotControl, LEFT, 5, 0, RIGHT)

            local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(self:GetRestyleSlotData().restyleMode)
            ItemTooltip:SetCollectible(collectibleId, SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON, actorCategory)
        else
            InitializeTooltip(InformationTooltip, self.itemSlotControl, LEFT, 5, 0, RIGHT)
            SetTooltipText(InformationTooltip, zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_COLLECTIBLECATEGORYTYPE", self.restyleSlotData:GetRestyleSlotType())))
        end
    end
end

function ZO_RestyleSlot_Collectible:OnIconMouseExit()
    ClearTooltip(ItemTooltip)
    ClearTooltip(InformationTooltip)
end

-------------------------------
-- Outfit Style Restyle Slot --
-------------------------------

ZO_RestyleSlot_OutfitStyle = ZO_RestyleSlot_Base:Subclass()

function ZO_RestyleSlot_OutfitStyle:Initialize(...)
    ZO_RestyleSlot_Base.Initialize(self, ...)

    self.itemSlotControl:SetHandler("OnDragStart", function(_, button)
        self:OnIconDragStart(button)
    end)

    self.itemSlotControl:SetHandler("OnReceiveDrag", function(_, button)
        self:OnIconReceiveDrag(button)
    end)

    self.itemSlotControl:SetHandler("OnMouseDoubleClick", function(_, button)
        self:OnMouseDoubleClick(button)
    end)

    self.itemSlotControl.equippedGlow = self.itemSlotControl:GetNamedChild("EquippedGlow")
    self.itemSlotControl.dragCallout = self.itemSlotControl:GetNamedChild("DragCallout")

    self.hiddenCollectibleId = GetOutfitSlotDataHiddenOutfitStyleCollectibleId(self.restyleSlotData:GetRestyleSlotType())
end

function ZO_RestyleSlot_OutfitStyle:GetControlTemplate()
    return "ZO_RestyleOutfitStyleSlotsSheet_Slot_Keyboard"
end

do
    local SHOW_NICKNAME = true
    local SHOW_PURCHASABLE_HINT = true
    local SHOW_BLOCK_REASON = true

    function ZO_RestyleSlot_OutfitStyle:OnIconMouseEnter()
        local collectibleData = self.restyleSlotData:GetPendingCollectibleData()
        if collectibleData then
            InitializeTooltip(ItemTooltip, self.itemSlotControl, LEFT, 5, 0, RIGHT)

            local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(self:GetRestyleSlotData().restyleMode)
            ItemTooltip:SetCollectible(collectibleData:GetId(), SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON, actorCategory)
        else
            InitializeTooltip(InformationTooltip, self.itemSlotControl, LEFT, 5, 0, RIGHT)
            SetTooltipText(InformationTooltip, zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_OUTFITSLOT", self.restyleSlotData:GetRestyleSlotType())))
        end
        self.owner:SetMouseOverData(self.restyleSlotData)
    end
end

function ZO_RestyleSlot_OutfitStyle:OnIconMouseExit()
    ClearTooltip(ItemTooltip)
    ClearTooltip(InformationTooltip)
    self.owner:SetMouseOverData(nil)
end

function ZO_RestyleSlot_OutfitStyle:OnIconMouseUp(button, upInside)
    if upInside then
        if button == MOUSE_BUTTON_INDEX_LEFT then
            if not self:HandlePlaceCursorCollectible() then
                ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:NavigateToCollectibleCategoryFromRestyleSlotData(self.restyleSlotData)
            end
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            ClearMenu()
            
            local collectibleData = self.restyleSlotData:GetPendingCollectibleData()
            if collectibleData then
                if IsChatSystemAvailableForCurrentPlatform() then
                    --Link in chat
                    AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(GetCollectibleLink(collectibleData:GetId(), LINK_STYLE_BRACKETS)) end)
                end

                if collectibleData:IsLocked() and collectibleData:IsPurchasable() then
                    AddMenuItem(GetString(SI_OUTFIT_COLLECTIBLE_SHOW_IN_MARKET), function()
                        local function GoToCrownStore()
                            local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                            ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_COLLECTIONS_OUTFITS)
                        end

                        if self.owner:AreChangesPending() then
                            ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:ShowRevertRestyleChangesDialog("CONFIRM_REVERT_CHANGES", GoToCrownStore)
                        else
                            GoToCrownStore()
                        end
                    end)
                end

                if ZO_RestyleCanApplyChanges() then
                    AddMenuItem(GetString(SI_OUTFIT_SLOT_CLEAR_ACTION), function()
                        self:ClearOufitStyleFromSlot()
                     end)
                 end
            end

            if ZO_RestyleCanApplyChanges() then
                local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(self.restyleSlotData)

                if slotManipulator:IsSlotDataChangePending() then 
                    AddMenuItem(GetString(SI_OUTFIT_SLOT_UNDO_ACTION), function()
                        slotManipulator:ClearPendingChanges()
                    end)
                end

                if self.hiddenCollectibleId > 0 and slotManipulator:GetPendingCollectibleId() ~= self.hiddenCollectibleId then
                    AddMenuItem(GetString(SI_OUTFIT_SLOT_HIDE_ACTION), function()
                        slotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(self.hiddenCollectibleId, ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX)
                    end)
                end
            end

            ShowMenu(self.control)
        end
    end
    self.isDragOrigin = nil
end

function ZO_RestyleSlot_OutfitStyle:OnIconDragStart(button)
    if ZO_RestyleCanApplyChanges() and button == MOUSE_BUTTON_INDEX_LEFT then
        local collectibleData = self.restyleSlotData:GetPendingCollectibleData()
        if collectibleData then
            PickupCollectible(collectibleData:GetId())
            self:ClearOufitStyleFromSlot()
            self.isDragOrigin = true
        end
    end
end

function ZO_RestyleSlot_OutfitStyle:OnIconReceiveDrag(button)
    -- If we were the origin and final destination of the drag, on mouse up will handle things
    if ZO_RestyleCanApplyChanges() and button == MOUSE_BUTTON_INDEX_LEFT and not self.isDragOrigin then
        self:HandlePlaceCursorCollectible()
    end
end

do
    local INITIAL_CONTEXT_MENU_REF_COUNT = 1

    function ZO_RestyleSlot_OutfitStyle:OnMouseDoubleClick(button)
        if ZO_RestyleCanApplyChanges() and button == MOUSE_BUTTON_INDEX_LEFT then
            local collectibleData = self.restyleSlotData:GetPendingCollectibleData()
            if collectibleData then
                local entryData =
                {
                    control = self.control,
                    data = collectibleData,
                    preferredOutfitSlot = self.restyleSlotData:GetRestyleSlotType(),
                }
                ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnRestyleOutfitStyleEntrySelected(entryData, INITIAL_CONTEXT_MENU_REF_COUNT)
            end
        end
    end
end

function ZO_RestyleSlot_OutfitStyle:HandlePlaceCursorCollectible()
    local handled = false
    if not self.itemSlotControl.dragCallout:IsHidden() then
        local collectibleId = GetCursorCollectibleId()
        if collectibleId then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            if collectibleData then
                local entryData =
                {
                    control = self.control,
                    data = collectibleData,
                    preferredOutfitSlot = self.restyleSlotData:GetRestyleSlotType(),
                }
                ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnRestyleOutfitStyleEntrySelected(entryData)
            end
            ClearCursor()
            handled = true
        end
    end
    return handled
end

function ZO_RestyleSlot_OutfitStyle:ClearOufitStyleFromSlot()
    local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(self.restyleSlotData)
    slotManipulator:Clear()
end

function ZO_RestyleSlot_OutfitStyle:RefreshVisible()
    local restyleSlotType = self.restyleSlotData:GetRestyleSlotType()

    if ZO_OUTFIT_MANAGER:IsOutfitSlotWeapon(restyleSlotType) then
        local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(self.restyleSlotData.restyleMode)
        local isEquipped = ZO_OUTFIT_MANAGER:IsWeaponOutfitSlotCurrentlyHeld(restyleSlotType, actorCategory)
        self.control:SetHidden(not isEquipped)
    end
end

-------------------------
-- Restyle Slots Sheet --
-------------------------

ZO_RestyleSlotsSheet = ZO_InitializingObject:Subclass()

function ZO_RestyleSlotsSheet:Initialize(parentContainer, slotGridData)
    local control = CreateControlFromVirtual("$(grandparent)" .. self:GetControlShortName(), parentContainer, self:GetTemplate())

    control.object = self

    self.headers =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = control:GetNamedChild("PrimaryHeader"),
        [ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = control:GetNamedChild("SecondaryHeader"),
    }

    self.slotContainers =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = control:GetNamedChild("PrimarySlots"),
        [ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = control:GetNamedChild("SecondarySlots"),
    }

    self.slots = {}
    self.slotSetupFunction = ZO_Restyle_SetupSlotControl
    self:SetupSlotGrid(slotGridData)
    self.pendingLoopAnimationPool = ZO_MetaPool:New(ZO_Pending_LoopAnimation_Pool)

    self.control = control

    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    self:RegisterForEvents()
    self:MarkViewDirty()
end

function ZO_RestyleSlotsSheet:RegisterForEvents()
    -- Can be overridden
end

function ZO_RestyleSlotsSheet:SetupSlotGrid(slotGridData)
    ZO_ClearTable(self.slots)

    local slotObjectClass = self:GetSlotObjectClass()
    for containerKey, slotsData in pairs(slotGridData) do
        local container = self.slotContainers[containerKey]
        for restyleSlotType, gridData in pairs(slotsData) do
            self.slots[restyleSlotType] = slotObjectClass:New(self, restyleSlotType, gridData, container)
        end
    end
end

function ZO_RestyleSlotsSheet:GetPendingLoopAnimationPool()
    return self.pendingLoopAnimationPool
end

function ZO_RestyleSlotsSheet:GetSlotsContainer(containerKey)
    return self.slotContainers[containerKey]
end

function ZO_RestyleSlotsSheet:GetRestyleMode()
    assert(false) -- Must be overriden
end

function ZO_RestyleSlotsSheet:GetTemplate()
    return "ZO_RestyleSlotsSheet_Keyboard"
end

function ZO_RestyleSlotsSheet:GetSlotObjectClass()
    assert(false) -- Must be overriden
end

function ZO_RestyleSlotsSheet:GetControlShortName()
    assert(false) -- Must be overriden
end

function ZO_RestyleSlotsSheet:GetFragment()
    return self.fragment
end

function ZO_RestyleSlotsSheet:InitializeOnDyeSlotCallbacks(onSlotClickedCallback, onSlotEnterCallback, onSlotExitCallback)
    for restyleSlotType, slotObject in pairs(self.slots) do
        for i, dyeControl in ipairs(slotObject:GetDyeControls()) do
            dyeControl:SetHandler("OnMouseUp", function(dyeControl, button, upInside)
                if upInside then
                    onSlotClickedCallback(slotObject:GetRestyleSlotData(), i, button)
                end
            end)

            dyeControl:SetHandler("OnMouseEnter", function(dyeControl)
                self.mousedOverDyeableSlotData = slotObject:GetRestyleSlotData()
                self.mousedOverDyeChannel = i
                onSlotEnterCallback(slotObject:GetRestyleSlotData(), i, dyeControl)
            end)

            dyeControl:SetHandler("OnMouseExit", function(dyeControl)
                self.mousedOverDyeableSlotData = nil
                self.mousedOverDyeChannel = nil
                onSlotExitCallback(slotObject:GetRestyleSlotData(), i)
            end)
        end
    end
end

function ZO_RestyleSlotsSheet:GetMousedOverDyeableSlotInfo()
    return self.mousedOverDyeableSlotData, self.mousedOverDyeChannel
end

function ZO_RestyleSlotsSheet:MarkViewDirty(restyleSlotData)
    if self.fragment:IsShowing() then
        if restyleSlotData then
            self:RefreshSlot(restyleSlotData)
        else
            self:RefreshView()
        end
    else
        self.isViewDirty = true
    end
end

do
    local SUPPRESS_CALLBACKS = true

    function ZO_RestyleSlotsSheet:RefreshView()
        self.pendingLoopAnimationPool:ReleaseAllObjects()

        self.isViewDirty = false
        for _, slotObject in pairs(self.slots) do
            local restyleSlotData = slotObject:GetRestyleSlotData()
            self:RefreshSlot(restyleSlotData, SUPPRESS_CALLBACKS)
        end

        self:OnSheetSlotRefreshed()
    end
end

function ZO_RestyleSlotsSheet:RefreshSlot(restyleSlotData, suppressCallbacks)
    if self:GetRestyleMode() == restyleSlotData:GetRestyleMode() then
        local restyleSlotType = restyleSlotData:GetRestyleSlotType()
        local slotObject = self.slots[restyleSlotType]
        local slotControl = slotObject:GetItemSlotControl()
        if slotControl.pendingLoop then
            slotControl.pendingLoop:ReleaseObject()
        end

        self.slotSetupFunction(slotControl, restyleSlotData)

        local dyeControls = slotObject:GetDyeControls()
        ZO_Dyeing_RefreshDyeableSlotControlDyes(dyeControls, restyleSlotData)

        slotObject:RefreshVisible()

        local changedDyeChannels = restyleSlotData:GetDyeChannelChangedStates()
        for i, hasChanged in ipairs(changedDyeChannels) do
            local dyeControl = dyeControls[i]
            if hasChanged and not dyeControl.dyeChangedControlKey then
                ZO_Restyle_ApplyDyeSlotChangedToControl(dyeControl)
            elseif not hasChanged and dyeControl.dyeChangedControlKey then
                ZO_Pending_Outfit_DyeChanged_Pool:ReleaseObject(dyeControl.dyeChangedControlKey)
                dyeControl.dyeChangedControlKey = nil
            end
        end

        if not suppressCallbacks then
            self:OnSheetSlotRefreshed(restyleSlotData)
        end
    end
end

function ZO_RestyleSlotsSheet:OnSheetSlotRefreshed(restyleSlotData)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:OnSheetSlotRefreshed(restyleSlotData)
end

function ZO_RestyleSlotsSheet:ToggleDyeControlsHightlight(dyeableSlotControls, isHighlighted, dyeChannel)
    if dyeChannel ~= nil then
        dyeableSlotControls[dyeChannel].highlightTexture:SetHidden(not isHighlighted)
    else
        for dyeChannel, dyeControl in ipairs(dyeableSlotControls) do
            dyeControl.highlightTexture:SetHidden(not isHighlighted)
        end
    end
end

function ZO_RestyleSlotsSheet:ToggleDyeableSlotHightlight(dyeableSlot, isHighlighted, dyeChannel)
    if dyeableSlot ~= nil then
        self:ToggleDyeControlsHightlight(self.slots[dyeableSlot]:GetDyeControls(), isHighlighted, dyeChannel)
    else
        for _, slotObject in pairs(self.slots) do
            self:ToggleDyeControlsHightlight(slotObject:GetDyeControls(), isHighlighted, dyeChannel)
        end
    end
end

function ZO_RestyleSlotsSheet:GetRestyleSetIndex()
    local _, slot = next(self.slots)
    return slot:GetRestyleSlotData():GetRestyleSetIndex()
end

function ZO_RestyleSlotsSheet:SetRestyleSetIndex(restyleSetIndex)
    for _, slotObject in pairs(self.slots) do
        slotObject:SetRestyleSetIndex(restyleSetIndex)
    end
    self:MarkViewDirty()
end

function ZO_RestyleSlotsSheet:GetSlots()
    return self.slots
end

function ZO_RestyleSlotsSheet:OnShowing()
    if self.isViewDirty then
        self:RefreshView()
    end
end

function ZO_RestyleSlotsSheet:OnShown()
    -- Can be overridden
end

function ZO_RestyleSlotsSheet:OnHiding()
    -- Can be overridden
end

function ZO_RestyleSlotsSheet:OnHidden()
    -- Can be overridden
end

function ZO_RestyleSlotsSheet:AreChangesPending()
    for _, slotObject in pairs(self.slots) do
        local restyleSlotData = slotObject:GetRestyleSlotData()
        if restyleSlotData:AreTherePendingDyeChanges() then
            return true
        end
    end
    return false
end

function ZO_RestyleSlotsSheet:CanApplyChanges()
    return ZO_RestyleCanApplyChanges() -- Can be overriden
end

function ZO_RestyleSlotsSheet:UndoPendingChanges()
    InitializePendingDyes()
    ZO_RESTYLE_STATION_KEYBOARD:OnPendingDyesChanged()
    PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
end

function ZO_RestyleSlotsSheet:HandleCommitSelection()
    return false -- To be overriden with custom behavior.  Return true if handled, false to let restyle do default behavior.
end

function ZO_RestyleSlotsSheet:GetMouseOverData()
    return self.mouseOverData
end

function ZO_RestyleSlotsSheet:SetMouseOverData(data)
    if self.mouseOverData ~= data then
        self.mouseOverData = data
        ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:OnSheetMouseoverDataChanged(data)
    end
end

function ZO_RestyleSlotsSheet:GetRandomizeKeybindText()
    if KEYBOARD_DYEING_FRAGMENT:IsShowing() then
        return GetString(SI_DYEING_RANDOMIZE)
    end
    return nil
end

function ZO_RestyleSlotsSheet:UniformRandomize()
    if KEYBOARD_DYEING_FRAGMENT:IsShowing() then
        ZO_Dyeing_UniformRandomize(self:GetRestyleMode(), self:GetRestyleSetIndex(), function() return ZO_DYEING_MANAGER:GetRandomUnlockedDyeId() end)
        ZO_RESTYLE_STATION_KEYBOARD:OnPendingDyesChanged()
    end
end

-----------------------------
-- Equipment Restyle Sheet --
-----------------------------

ZO_RestyleEquipmentSlotsSheet = ZO_RestyleSlotsSheet:Subclass()

function ZO_RestyleEquipmentSlotsSheet:RegisterForEvents()
    local function MarkViewDirty()
        self:MarkViewDirty()
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, MarkViewDirty)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, MarkViewDirty)
    self.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
    self.control:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, MarkViewDirty)
end

function ZO_RestyleEquipmentSlotsSheet:GetTemplate()
    return "ZO_RestyleEquipmentSlotsSheet_Keyboard"
end

function ZO_RestyleEquipmentSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_EQUIPMENT
end

function ZO_RestyleEquipmentSlotsSheet:GetSlotObjectClass()
    return ZO_RestyleSlot_Equipment
end

function ZO_RestyleEquipmentSlotsSheet:GetControlShortName()
    return "EquipmentSheet"
end

function ZO_RestyleEquipmentSlotsSheet:RefreshView()
    ZO_RestyleSlotsSheet.RefreshView(self)

    local activeWeaponPair = GetActiveWeaponPairInfo()
    local weaponSectionHeaderStringId = activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN and SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_1 or SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_2
    self.headers[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY]:SetText(GetString(weaponSectionHeaderStringId))
end

------------------------------
-- Collectible Restyle Sheet--
------------------------------

ZO_RestyleCollectibleSlotsSheet = ZO_RestyleSlotsSheet:Subclass()

function ZO_RestyleCollectibleSlotsSheet:RegisterForEvents()
    local function OnCollectibleUpdated(collectibleId)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        local updatedCollectibleCategoryType = collectibleData:GetCategoryType()
        for slotCollectibleCategoryType, slotData in pairs(self:GetSlots()) do
            if updatedCollectibleCategoryType == slotCollectibleCategoryType then
                self:MarkViewDirty()
                break
            end
        end
    end

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
            self:MarkViewDirty()
        else
            for _, unlockStateTable in pairs(collectiblesByNewUnlockState) do
                for _, collectibleData in ipairs(unlockStateTable) do
                    local updatedCollectibleCategoryType = collectibleData:GetCategoryType()
                    for slotCollectibleCategoryType, slotData in pairs(self:GetSlots()) do
                        if updatedCollectibleCategoryType == slotCollectibleCategoryType then
                            self:MarkViewDirty()
                            return
                        end
                    end
                end
            end
        end
    end

    local function MarkViewDirty()
        self:MarkViewDirty()
    end

    self.control:RegisterForEvent(EVENT_COLLECTIBLE_DYE_DATA_UPDATED, MarkViewDirty)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)
end

function ZO_RestyleCollectibleSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_COLLECTIBLE
end

function ZO_RestyleCollectibleSlotsSheet:GetSlotObjectClass()
    return ZO_RestyleSlot_Collectible
end

function ZO_RestyleCollectibleSlotsSheet:GetControlShortName()
    return "CollectibleSheet"
end

-------------------------------------
-- Outfit Style Restyle Slot Sheet --
-------------------------------------

ZO_RestyleOutfitSlotsSheet = ZO_RestyleSlotsSheet:Subclass()

do
    local STACK_COUNT = 1
    local PENDING_ANIMATION_INSET = 0

    function ZO_RestyleOutfitSlotsSheet:Initialize(...)
        ZO_RestyleSlotsSheet.Initialize(self, ...)

        self.slotSetupFunction = function(control, restyleSlotData)
            local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
            local icon = slotManipulator:GetSlotAppropriateIcon()

            control.restyleSlotData = restyleSlotData

            control.iconTexture:SetTexture(icon)

            local pendingCollectibleId = slotManipulator and slotManipulator:GetPendingCollectibleId() or 0
            local shownCollectibleIsNotCurrentlyEquipped = pendingCollectibleId == 0 or pendingCollectibleId ~= slotManipulator:GetCurrentCollectibleId()
            control.equippedGlow:SetHidden(shownCollectibleIsNotCurrentlyEquipped)

            local hideDraggableSlotCallout = true
            if self.eligibleDragSlots then
                local restyleSlotType = restyleSlotData:GetRestyleSlotType()
                for _, outfitSlot in ipairs(self.eligibleDragSlots) do
                    if outfitSlot == restyleSlotType then
                        hideDraggableSlotCallout = false
                        break
                    end
                end
            end
            control.dragCallout:SetHidden(hideDraggableSlotCallout)

            if slotManipulator and slotManipulator:IsSlotDataChangePending() then
                local pendingCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(pendingCollectibleId)
                local isLocked = pendingCollectibleData and pendingCollectibleData:IsLocked()
                ZO_PendingLoop.ApplyToControl(control, self:GetPendingLoopAnimationPool(), PENDING_ANIMATION_INSET, isLocked)
            end
        end

        self.noWeaponsLabel = self.control:GetNamedChild("SecondaryNoWeaponsLabel")
        self.costContainer = self.control:GetNamedChild("CostContainer")
        self.currency1Label = self.costContainer:GetNamedChild("Currency1")
        self.currency2Label = self.costContainer:GetNamedChild("Currency2")

        self.refreshCostFunction = function()
            self:RefreshCost()
        end
    end
end

function ZO_RestyleOutfitSlotsSheet:OnShowing()
    ZO_RestyleSlotsSheet.OnShowing(self)

    self.costContainer:SetHidden(not ZO_RestyleCanApplyChanges())
    self:RefreshCost()
end

function ZO_RestyleOutfitSlotsSheet:RegisterForEvents()
    local function MarkViewDirty()
        self:MarkViewDirty()
    end

    local function HandleCursorPickup(eventCode, cursorType, ...)
        if cursorType == MOUSE_CONTENT_COLLECTIBLE and ZO_RESTYLE_SCENE:IsShowing() then
            local collectibleId = GetCursorCollectibleId()
            if collectibleId then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                if collectibleData:IsOutfitStyle() then
                    self.eligibleDragSlots = { GetEligibleOutfitSlotsForCollectible(collectibleId) }
                    self:MarkViewDirty()
                end
            end
        end
    end

    local function HandleCursorDropped()
        self.eligibleDragSlots = nil
        self:MarkViewDirty()
    end

    local function OnPendingDataChanged(actorCategory, outfitIndex, slotIndex)
        local outfitManipulator = outfitIndex and ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, outfitIndex)
        local outfitSlotManipulator = outfitManipulator and slotIndex and outfitManipulator:GetSlotManipulator(slotIndex)
        local restyleSlotData = outfitSlotManipulator and outfitSlotManipulator:GetRestyleSlotData()
        self:MarkViewDirty(restyleSlotData)
    end

    ZO_OUTFIT_MANAGER:RegisterCallback("PendingDataChanged", OnPendingDataChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, MarkViewDirty)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, MarkViewDirty)
    self.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
    self.control:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, MarkViewDirty)
    self.control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    self.control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorDropped)
end

function ZO_RestyleOutfitSlotsSheet:SetOutfitManipulator(newManipulator)
    if self.currentOutfitManipulator ~= newManipulator then
        if self.currentOutfitManipulator then
            self.currentOutfitManipulator:ClearPendingChanges()
        end

        self.currentOutfitManipulator = newManipulator

        self:SetRestyleSetIndex(newManipulator:GetOutfitIndex())
    end
end

function ZO_RestyleOutfitSlotsSheet:GetCurrentOutfitManipulator()
    return self.currentOutfitManipulator
end

function ZO_RestyleOutfitSlotsSheet:GetTemplate()
    return "ZO_RestyleOutfitStylesSlotsSheet_Keyboard"
end

function ZO_RestyleOutfitSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_OUTFIT
end

function ZO_RestyleOutfitSlotsSheet:GetSlotObjectClass()
    return ZO_RestyleSlot_OutfitStyle
end

function ZO_RestyleOutfitSlotsSheet:GetControlShortName()
    return "OutfitStylesSheet"
end

function ZO_RestyleOutfitSlotsSheet:AreChangesPending()
    return self.currentOutfitManipulator and self.currentOutfitManipulator:IsAnyChangePending()
end

function ZO_RestyleOutfitSlotsSheet:CanApplyChanges()
    if self.currentOutfitManipulator then
        return self.currentOutfitManipulator:CanApplyChanges()
    end
    return false
end

function ZO_RestyleOutfitSlotsSheet:UndoPendingChanges()
    if self.currentOutfitManipulator then
        self.currentOutfitManipulator:ClearPendingChanges()
    end
    ZO_RestyleSlotsSheet.UndoPendingChanges(self)
end

function ZO_RestyleOutfitSlotsSheet:HandleCommitSelection()
    local currentOutfitManipulator = self.currentOutfitManipulator
    if currentOutfitManipulator and currentOutfitManipulator:IsAnyChangePending() then
        ZO_Dialogs_ShowDialog("OUTFIT_CONFIRM_COST_KEYBOARD", { outfitManipulator = currentOutfitManipulator } )
        return true
    end
    return false
end

function ZO_RestyleOutfitSlotsSheet:RefreshView()
    ZO_RestyleSlotsSheet.RefreshView(self)

    local activeWeaponPair = GetActiveWeaponPairInfo()
    local weaponSectionHeaderStringId = activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN and SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_1 or SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_2
    self.headers[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY]:SetText(GetString(weaponSectionHeaderStringId))

    self.noWeaponsLabel:SetHidden(ZO_OUTFIT_MANAGER:HasWeaponsCurrentlyHeldToOverride())
end

function ZO_RestyleOutfitSlotsSheet:OnSheetSlotRefreshed()
    ZO_RestyleSlotsSheet.OnSheetSlotRefreshed(self)

    self:RefreshCost()
end

do
    local OPTIONS = { font = "ZoFontHeader" }
    local SHOW_ALL = true
    local function SetCostText(control, currencyType, cost)
        local currentBalance = GetCurrencyAmount(currencyType, GetCurrencyPlayerStoredLocation(currencyType))
        ZO_CurrencyControl_SetSimpleCurrency(control, currencyType, cost, OPTIONS, SHOW_ALL, cost > currentBalance)
    end

    function ZO_RestyleOutfitSlotsSheet:RefreshCost()
        local slotsCost, flatCost = self.currentOutfitManipulator:GetAllCostsForPendingChanges()

        -- Slot based cost
        SetCostText(self.currency1Label, CURT_MONEY, slotsCost)

        --Flat cost
        SetCostText(self.currency2Label, CURT_STYLE_STONES, flatCost)
    end
end

function ZO_RestyleOutfitSlotsSheet:GetRandomizeKeybindText()
    if KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:IsShowing() then
        return GetString(SI_OUTFIT_STYLES_RANDOMIZE)
    else
        return ZO_RestyleSlotsSheet.GetRandomizeKeybindText(self)
    end
end

function ZO_RestyleOutfitSlotsSheet:UniformRandomize()
    if KEYBOARD_OUTFIT_STYLES_PANEL_FRAGMENT:IsShowing() then
        self.currentOutfitManipulator:RandomizeStyleData()
    else
        ZO_RestyleSlotsSheet.UniformRandomize(self)
    end
end

-----------------------------
-- Companion Equipment Restyle Sheet --
-----------------------------

ZO_RestyleCompanionEquipmentSlotsSheet = ZO_RestyleEquipmentSlotsSheet:Subclass()

function ZO_RestyleCompanionEquipmentSlotsSheet:Initialize(...)
    ZO_RestyleEquipmentSlotsSheet.Initialize(self, ...)

    local ALWAYS_HIDE = true
    ZO_WeaponSwap_SetPermanentlyHidden(self.control:GetNamedChild("SecondaryWeaponSwap"), ALWAYS_HIDE)
end

function ZO_RestyleCompanionEquipmentSlotsSheet:RegisterForEvents()
    local function MarkViewDirty()
        self:MarkViewDirty()
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, MarkViewDirty)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, MarkViewDirty)
    self.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_COMPANION_WORN)
    self.control:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, MarkViewDirty)
end

function ZO_RestyleCompanionEquipmentSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_COMPANION_EQUIPMENT
end

function ZO_RestyleCompanionEquipmentSlotsSheet:GetControlShortName()
    return "CompanionEquipmentSheet"
end

function ZO_RestyleCompanionEquipmentSlotsSheet:RefreshView()
    ZO_RestyleSlotsSheet.RefreshView(self)

    self.headers[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY]:SetText(GetString(SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_1))
end

-------------------------------------
-- Companion Outfit Style Restyle Slot Sheet --
-------------------------------------

ZO_RestyleCompanionOutfitSlotsSheet = ZO_RestyleOutfitSlotsSheet:Subclass()

function ZO_RestyleCompanionOutfitSlotsSheet:Initialize(...)
    ZO_RestyleOutfitSlotsSheet.Initialize(self, ...)

    local ALWAYS_HIDE = true
    ZO_WeaponSwap_SetPermanentlyHidden(self.control:GetNamedChild("SecondaryWeaponSwap"), ALWAYS_HIDE)
    self.noWeaponsLabel:SetText(GetString(SI_OUTFIT_STYLE_SHEET_NO_WEAPONS_COMPANION_WARNING))
end

function ZO_RestyleCompanionOutfitSlotsSheet:RegisterForEvents()
    local function MarkViewDirty()
        self:MarkViewDirty()
    end

    local function HandleCursorPickup(eventCode, cursorType, ...)
        if cursorType == MOUSE_CONTENT_COLLECTIBLE and ZO_RESTYLE_SCENE:IsShowing() then
            local collectibleId = GetCursorCollectibleId()
            if collectibleId then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                if collectibleData:IsOutfitStyle() then
                    self.eligibleDragSlots = { GetEligibleOutfitSlotsForCollectible(collectibleId) }
                    self:MarkViewDirty()
                end
            end
        end
    end

    local function HandleCursorDropped()
        self.eligibleDragSlots = nil
        self:MarkViewDirty()
    end

    local function OnPendingDataChanged(actorCategory, outfitIndex, slotIndex)
        local outfitManipulator = outfitIndex and ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, outfitIndex)
        local outfitSlotManipulator = outfitManipulator and slotIndex and outfitManipulator:GetSlotManipulator(slotIndex)
        local restyleSlotData = outfitSlotManipulator and outfitSlotManipulator:GetRestyleSlotData()
        self:MarkViewDirty(restyleSlotData)
    end

    ZO_OUTFIT_MANAGER:RegisterCallback("PendingDataChanged", OnPendingDataChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, MarkViewDirty)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, MarkViewDirty)
    self.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_COMPANION_WORN)
    self.control:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, MarkViewDirty)
    self.control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    self.control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorDropped)
end

function ZO_RestyleCompanionOutfitSlotsSheet:GetTemplate()
    return "ZO_RestyleOutfitStylesSlotsSheet_Keyboard"
end

function ZO_RestyleCompanionOutfitSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_COMPANION_OUTFIT
end

function ZO_RestyleCompanionOutfitSlotsSheet:GetControlShortName()
    return "CompanionOutfitStylesSheet"
end

function ZO_RestyleCompanionOutfitSlotsSheet:RefreshView()
    ZO_RestyleSlotsSheet.RefreshView(self)

    self.headers[ZO_RESTYLE_SHEET_CONTAINER.SECONDARY]:SetText(GetString(SI_RESTYLE_SHEET_EQUIPMENT_WEAPONS_SET_1))

    self.noWeaponsLabel:SetHidden(ZO_OUTFIT_MANAGER:HasWeaponsCurrentlyHeldToOverride(GAMEPLAY_ACTOR_CATEGORY_COMPANION))
end

-------------------------------------
-- Companion Collectible Style Restyle Slot Sheet --
-------------------------------------

ZO_RestyleCompanionCollectibleSlotsSheet = ZO_RestyleCollectibleSlotsSheet:Subclass()

function ZO_RestyleCompanionCollectibleSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_COMPANION_COLLECTIBLE
end

function ZO_RestyleCompanionCollectibleSlotsSheet:GetControlShortName()
    return "CompanionCollectibleStylesSheet"
end

do
    ZO_Pending_Outfit_DyeChanged_Pool = ZO_ControlPool:New("ZO_Dyeing_SlotChanged", GuiRoot, "DyeSlotChanged")

    function ZO_Restyle_ApplyDyeSlotChangedToControl(control)
        local pool = ZO_Pending_Outfit_DyeChanged_Pool
        local dyeChangedControl, key = pool:AcquireObject()
        dyeChangedControl:SetAnchor(CENTER, control, CENTER)
        dyeChangedControl:SetParent(control)
        dyeChangedControl:SetHidden(false)
        control.dyeChangedControlKey = key
    end
end