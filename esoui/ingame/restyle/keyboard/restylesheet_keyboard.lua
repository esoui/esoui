ZO_RESTYLE_SHEET_CONTAINER =
{
    PRIMARY = 1,
    SECONDARY = 2,
}

-----------------------
-- Restyle Slot Base --
-----------------------

ZO_RestyleSlot_Base = ZO_Object:Subclass()

function ZO_RestyleSlot_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

do
    local SLOT_WIDTH = 134
    local SLOT_HEIGHT = 64
    local GRID_PADDING_X = 30
    local GRID_PADDING_Y = 15

    function ZO_RestyleSlot_Base:Initialize(owner, restyleSlotType, gridData, container)
        self.owner = owner
        local offsetX = (SLOT_WIDTH + GRID_PADDING_X) * (gridData.column - 1)
        local offsetY = (SLOT_HEIGHT + GRID_PADDING_Y) * (gridData.row - 1)
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

----------------------------
-- Equipment Restyle Slot --
----------------------------

ZO_RestyleSlot_Equipment = ZO_RestyleSlot_Base:Subclass()

function ZO_RestyleSlot_Equipment:New(...)
    return ZO_RestyleSlot_Base.New(self, ...)
end

function ZO_RestyleSlot_Equipment:OnIconMouseEnter()
    ZO_InventorySlot_OnMouseEnter(self.itemSlotControl)
end

function ZO_RestyleSlot_Equipment:OnIconMouseExit()
    ZO_InventorySlot_OnMouseExit(self.itemSlotControl)
end

------------------------------
-- Collectible Restyle Slot --
------------------------------

ZO_RestyleSlot_Collectible = ZO_RestyleSlot_Base:Subclass()

function ZO_RestyleSlot_Collectible:New(...)
    return ZO_RestyleSlot_Base.New(self, ...)
end

do
    local SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON = true, true, true

    function ZO_RestyleSlot_Collectible:OnIconMouseEnter()
        local collectibleId = self.restyleSlotData:GetId()
        if collectibleId > 0 then
            InitializeTooltip(ItemTooltip, self.itemSlotControl, LEFT, 5, 0, RIGHT)
            ItemTooltip:SetCollectible(collectibleId, SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON)
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

-------------------------
-- Restyle Slots Sheet --
-------------------------

ZO_RestyleSlotsSheet = ZO_Object:Subclass()

function ZO_RestyleSlotsSheet:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_RestyleSlotsSheet:Initialize(parentContainer, slotGridData)
    local control = CreateControlFromVirtual("$(parent)" .. self:GetControlShortName(), parentContainer, self:GetTemplate())

    control.object = self

    self.slotContainers = 
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = control:GetNamedChild("PrimaryContainerSlots"),
        [ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = control:GetNamedChild("SecondaryContainerSlots"),
    }
    self.slots = {}
    self:SetupSlotGrid(slotGridData)

    control:GetNamedChild("Title"):SetText(self:GetTitleText())

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

function ZO_RestyleSlotsSheet:GetTitleText()
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

function ZO_RestyleSlotsSheet:MarkViewDirty()
    if SCENE_MANAGER:IsShowing("restyle_keyboard") then
        self:RefreshView()
    else
        self.isViewDirty = true
    end
end

function ZO_RestyleSlotsSheet:RefreshView()
    self.isViewDirty = false
    for _, slotObject in pairs(self.slots) do
        local restyleSlotData = slotObject:GetRestyleSlotData()
        ZO_Restyle_SetupSlotControl(slotObject:GetItemSlotControl(), restyleSlotData)
        self:RefreshDyeableSlotDyes(restyleSlotData)
    end
end

function ZO_RestyleSlotsSheet:RefreshDyeableSlotDyes(restyleSlotData)
    if self:GetRestyleMode() == restyleSlotData:GetRestyleMode() then
        local restyleSlotType = restyleSlotData:GetRestyleSlotType()
        local slotObject = self.slots[restyleSlotType]
        local slotControl = slotObject:GetControl()
        ZO_Dyeing_RefreshDyeableSlotControlDyes(slotObject:GetDyeControls(), restyleSlotData)

        --TODO: Generalize
        if restyleSlotData:IsEquipment() then
            if restyleSlotType == EQUIP_SLOT_OFF_HAND or restyleSlotType == EQUIP_SLOT_BACKUP_OFF then
                local activeEquipSlot = ZO_Restyle_GetActiveOffhandEquipSlotType()
                slotControl:SetHidden(restyleSlotType ~= activeEquipSlot)
            end
        end
    end
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

-----------------------------
-- Equipment Restyle Sheet --
-----------------------------

ZO_RestyleEquipmentSlotsSheet = ZO_RestyleSlotsSheet:Subclass()

function ZO_RestyleEquipmentSlotsSheet:New(...)
    return ZO_RestyleSlotsSheet.New(self, ...)
end

function ZO_RestyleEquipmentSlotsSheet:RegisterForEvents()
    local function OnFullInventoryUpdated()
        self:MarkViewDirty()
    end

    --Filtered on bagId == BAG_WORN
    local function OnInventorySlotUpdated(eventCode, bagId, slotIndex)
        self:MarkViewDirty()
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnFullInventoryUpdated)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySlotUpdated)
    self.control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)
end

function ZO_RestyleEquipmentSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_EQUIPMENT
end

function ZO_RestyleEquipmentSlotsSheet:GetSlotObjectClass()
    return ZO_RestyleSlot_Equipment
end

function ZO_RestyleEquipmentSlotsSheet:GetTitleText()
    return GetString(SI_CHARACTER_EQUIP_TITLE)
end

function ZO_RestyleEquipmentSlotsSheet:GetControlShortName()
    return "EquipmentSheet"
end

------------------------------
-- Collectible Restyle Sheet--
------------------------------

ZO_RestyleCollectibleSlotsSheet = ZO_RestyleSlotsSheet:Subclass()

function ZO_RestyleCollectibleSlotsSheet:RegisterForEvents()
    local function OnCollectibleUpdated(eventCode, collectibleId)
        local updatedCollectibleCategoryType = GetCollectibleCategoryType(collectibleId)
        for slotCollectibleCategoryType, slotData in pairs(self:GetSlots()) do
            if updatedCollectibleCategoryType == slotCollectibleCategoryType then
                self:MarkViewDirty()
                break
            end
        end
    end

    self.control:RegisterForEvent(EVENT_COLLECTIBLE_UPDATED, OnCollectibleUpdated)
    self.control:RegisterForEvent(EVENT_COLLECTION_UPDATED, function() self:MarkViewDirty() end)
end

function ZO_RestyleCollectibleSlotsSheet:New(...)
    return ZO_RestyleSlotsSheet.New(self, ...)
end

function ZO_RestyleCollectibleSlotsSheet:GetRestyleMode()
    return RESTYLE_MODE_COLLECTIBLE
end

function ZO_RestyleCollectibleSlotsSheet:GetSlotObjectClass()
    return ZO_RestyleSlot_Collectible
end

function ZO_RestyleCollectibleSlotsSheet:GetTitleText()
    return GetString(SI_DYEING_COLLECTIBLE_SHEET_HEADER)
end

function ZO_RestyleCollectibleSlotsSheet:GetControlShortName()
    return "CollectibleSheet"
end