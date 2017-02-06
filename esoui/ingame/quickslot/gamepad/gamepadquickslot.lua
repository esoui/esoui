ZO_GamepadQuickslot = ZO_Object:Subclass()

local QUICKSLOT_ASSIGNMENT_TYPE_ITEM = 1
local QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE = 2

function ZO_GamepadQuickslot:New(control)
    local menu = ZO_Object.New(self)
    menu:Initialize(control)
    return menu
end

function ZO_GamepadQuickslot:Initialize(control)
    self.control = control

    local container = control:GetNamedChild("Container")
    self.radialControl = container:GetNamedChild("Radial")
    self.radialMenu = ZO_RadialMenu:New(self.radialControl, "ZO_GamepadQuickslotRadialMenuEntryTemplate", nil, "SelectableItemRadialMenuEntryAnimation", "RadialMenu")
    self.radialMenu.activeIcon = self.radialControl:GetNamedChild("Icon")
    --store entry controls to animate with later
    self.entryControls = {}

    local function SetupEntryControl(entryControl, slotNum)
        local itemCount = GetSlotItemCount(slotNum)
        local slotType = GetSlotType(slotNum)
        self.entryControls[slotNum] = entryControl
        ZO_SetupSelectableItemRadialMenuEntryTemplate(entryControl, nil, slotType ~= ACTION_TYPE_NOTHING and itemCount or nil)

        ZO_GamepadQuickslotCooldownSetup(entryControl, slotNum)
    end

    local function OnSelectionChangedCallback(selectedEntry)
        self:OnSelectionChanged(selectedEntry)
    end

    self.radialMenu:SetCustomControlSetUpFunction(SetupEntryControl)
    self.radialMenu:SetOnSelectionChangedCallback(OnSelectionChangedCallback)
    
    ZO_CreateSparkleAnimation(self.radialControl)

    self.header = container:GetNamedChild("HeaderContainer").header
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    GAMEPAD_QUICKSLOT_SCENE = ZO_Scene:New("gamepad_quickslot", SCENE_MANAGER)
    GAMEPAD_QUICKSLOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            
            if self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_ITEM then
                --Used the item and hit Assign at the same time...
                if SHARED_INVENTORY:GenerateSingleSlotData(self.itemToSlotId, self.itemToSlotIndex) == nil then
                    SCENE_MANAGER:HideCurrentScene()
                    return
                end
            end

            self:RefreshHeader()
            self:ResetActiveIcon()
            self:ShowQuickslotMenu()     
            KEYBIND_STRIP:AddKeybindButtonGroup(self.navigationKeybindDescriptor)
        elseif newState == SCENE_HIDING then
            self.radialMenu:Clear()
        elseif newState == SCENE_HIDDEN then
            self.activeIcon = nil
            self.slotIndexForAnim = nil
            self.enteringMenuUnslottedItem = false
            self.radialMenu.activeIcon:SetHidden(false)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.navigationKeybindDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.assignKeybindDescriptor)
        end
    end)
end

function ZO_GamepadQuickslot:ResetActiveIcon()
    local slotEnabled
    local slotIcon

    if self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE then
        local _, _, icon, _, unlocked = GetCollectibleInfo(self.collectibleToSlotId)
        slotIcon = icon
        slotEnabled = unlocked
    elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_ITEM then
        local icon, stack, _, meetsUsageRequirements = GetItemInfo(self.itemToSlotId, self.itemToSlotIndex)
        slotIcon = icon
        slotEnabled = meetsUsageRequirements
    end

    self.radialMenu.activeIcon:SetTexture(slotIcon)

    local r,g,b = 1, 1, 1
    if not slotEnabled then
        r,g,b = 1, 0, 0
    end
    self.radialMenu.activeIcon:SetColor(r,g,b)
    self.isActiveEmpty = false
end

function ZO_GamepadQuickslot:OnSelectionChanged(selectedEntry)
    local slotType = GetSlotType(selectedEntry.data)
    
    if slotType == ACTION_TYPE_NOTHING and self.isActiveEmpty then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.assignKeybindDescriptor)
    else
        KEYBIND_STRIP:AddKeybindButtonGroup(self.assignKeybindDescriptor)
    end

    --tooltip update on active item
    local itemLink = GetSlotItemLink(selectedEntry.data)
    if slotType == ACTION_TYPE_COLLECTIBLE then
        GAMEPAD_TOOLTIPS:LayoutCollectibleFromLink(GAMEPAD_LEFT_TOOLTIP, itemLink)
    else
        GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(GAMEPAD_LEFT_TOOLTIP, itemLink, ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT)
    end
end

function ZO_GamepadQuickslot:PerformDeferredInitialization()
    if self.navigationKeybindDescriptor then return end

    local function OnQuickSlotUpdated(eventCode, physicalSlot)
        self:RefreshQuickslotMenu()
    end

    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_ACTION_SLOT_UPDATED, OnQuickSlotUpdated)
    
    self:InitializeHeader()
    self:InitializeKeybindStrip()
end

function ZO_GamepadQuickslot:InitializeKeybindStrip()
    self.navigationKeybindDescriptor = {}

    self.assignKeybindDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
            keybind = "UI_SHORTCUT_PRIMARY",
            order = -500,
            callback = function() self:TryAssignItemToSlot() end,
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.navigationKeybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

local function UpdateAlliancePoints(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_ALLIANCE_POINTS, GetCarriedCurrencyAmount(CURT_ALLIANCE_POINTS), ZO_GAMEPAD_CURRENCY_OPTIONS)
    return true
end

local function UpdateGold(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
    return true
end

local function UpdateCapacityString()
    return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
end

function ZO_GamepadQuickslot:InitializeHeader()
    local function RefreshHeader()
        if not self.control:IsHidden() then
            self:RefreshHeader()
        end
    end

    self:RefreshHeader()

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshHeader)
end

local EMPTY_QUICKSLOT_TEXTURE = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
local EMPTY_QUICKSLOT_STRING = GetString(SI_QUICKSLOTS_EMPTY)

function ZO_GamepadQuickslot:RefreshHeader()
    if self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE then
        self.headerData = 
        { 
            titleText = GetString(SI_MAIN_MENU_COLLECTIONS)
        }
    elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_ITEM then
        self.headerData = 
        {
            data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
            data1Text = UpdateGold,

            data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_ALLIANCE_POINTS),
	        data2Text = UpdateAlliancePoints,

            data3HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
            data3Text = UpdateCapacityString,

            titleText = GetString(SI_GAMEPAD_INVENTORY_CONSUMABLES),
        }
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GamepadQuickslot:RefreshQuickslotMenu()
    --if item was unslotted, show icons and anims when server responds
    if self.enteringMenuUnslottedItem then
        ZO_PlaySparkleAnimation(self.radialControl)
        self.radialMenu.activeIcon:SetHidden(false)
    end

    self.radialMenu:ResetData()
    self:PopulateMenu()
    self.radialMenu:Refresh()
end

function ZO_GamepadQuickslot:ShowQuickslotMenu()    
    self.radialMenu:Clear()
    self:PopulateMenu()
    self.radialMenu:Show()

    --special entrance case, unslot selected item
    local slotNum
    if self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE then
        if self.collectibleToSlotId then
            slotNum = GetCollectibleCurrentActionBarSlot(self.collectibleToSlotId)
        end
    elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_ITEM then
        if self.itemToSlotId and self.itemToSlotIndex then
            slotNum = GetItemCurrentActionBarSlot(self.itemToSlotId, self.itemToSlotIndex)
        end
    end

    if slotNum then
        self.enteringMenuUnslottedItem = true
        ClearSlot(slotNum)
        self.slotIndexForAnim = slotNum
        self.radialMenu.activeIcon:SetHidden(true)
    end
end

function ZO_GamepadQuickslot:PopulateMenu()
    for i = ACTION_BAR_FIRST_UTILITY_BAR_SLOT + 1, ACTION_BAR_FIRST_UTILITY_BAR_SLOT + ACTION_BAR_UTILITY_BAR_SIZE do
        if not ZO_QuickslotRadialManager:ValidateOrClearQuickslot(i) then
            self.radialMenu:AddEntry(EMPTY_QUICKSLOT_STRING, EMPTY_QUICKSLOT_TEXTURE, EMPTY_QUICKSLOT_TEXTURE, function() SetCurrentQuickslot(i) end, i)
        else
            local slotType = GetSlotType(i)
            local slotIcon = GetSlotTexture(i)
            local slotName = GetSlotName(i)
            slotName = zo_strformat(SI_TOOLTIP_ITEM_NAME, slotName)
            local slotItemQuality = GetSlotItemQuality(i)

            local slotNameData
            if slotItemQuality then
                local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, slotItemQuality)
                local colorTable = { r = r, g = g, b = b }
                slotNameData = {slotName, colorTable}
            else
                slotNameData = slotName
            end

            self.radialMenu:AddEntry(slotNameData, slotIcon, slotIcon, function() SetCurrentQuickslot(i) end, i)
        end
    end

    if self.activeIcon then
        self.radialMenu.activeIcon:SetTexture(self.activeIcon)
    end

    --sparkle animation on item switch (never on empty)
    if self.slotIndexForAnim then
        ZO_PlaySparkleAnimation(self.entryControls[self.slotIndexForAnim])
    elseif not self.itemToSlotId and not self.itemToSlotIndex then
        ZO_PlaySparkleAnimation(self.radialControl)
    end
end

function ZO_GamepadQuickslot:SetItemToQuickslot(bagId, slotIndex)
    self.assignmentType = QUICKSLOT_ASSIGNMENT_TYPE_ITEM
    self.itemToSlotId = bagId
    self.itemToSlotIndex = slotIndex
end

function ZO_GamepadQuickslot:SetCollectibleToQuickslot(collectibleId)
    self.assignmentType = QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE
    self.collectibleToSlotId = collectibleId
end

function ZO_GamepadQuickslot:TryAssignItemToSlot()
    local selectedData = self.radialMenu.selectedEntry
    if selectedData then
        if self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_COLLECTIBLE then
            if self.collectibleToSlotId then
                SelectSlotCollectible(self.collectibleToSlotId, selectedData.data)
                self.collectibleToSlotId = nil
            end
        elseif self.assignmentType == QUICKSLOT_ASSIGNMENT_TYPE_ITEM then
            if self.itemToSlotId and self.itemToSlotIndex then
                SelectSlotItem(self.itemToSlotId, self.itemToSlotIndex, selectedData.data)
                self.itemToSlotId = nil
                self.itemToSlotIndex = nil
            end
        end

        self.radialMenu.activeIcon:SetHidden(true)
        self.activeIcon = nil
        self.slotIndexForAnim = selectedData.data
    end
    self.enteringMenuUnslottedItem = false  --in case the player tries to assign the slotted item that is currently being unassigned so that the scene will properly hide
end

function ZO_GamepadQuickslot:HideScene()
    if not self.enteringMenuUnslottedItem then  --if trying to assign an item that is already assigned we unslot the item and show
        SCENE_MANAGER:Hide("gamepad_quickslot") --a sparkle to indicate this, we don't want that animation to hide the menu, just all subsequents.
    end
    self.enteringMenuUnslottedItem = false
end

function ZO_GamepadQuickslot_HideScene()
    GAMEPAD_QUICKSLOT:HideScene()
end

function ZO_GamepadQuickslot_Initialize(control)
    GAMEPAD_QUICKSLOT = ZO_GamepadQuickslot:New(control)
end