-----------------------------
-- Vengeance Perk Tile Keyboard
-----------------------------

ZO_VENGEANCE_PERK_TILE_KEYBOARD_DIMENSIONS_X = 175
ZO_VENGEANCE_PERK_TILE_KEYBOARD_DIMENSIONS_Y = 125
ZO_VENGEANCE_PERK_TILE_KEYBOARD_ICON_DIMENSIONS = 52
ZO_VENGEANCE_PERK_TILE_KEYBOARD_ICON_BORDER_DIMENSIONS = 104

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_VengeancePerkTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_VengeancePerkTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_VengeancePerkTile_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)

    self.framedIconControl = self.control:GetNamedChild("FramedIcon")
    self.framedIcon = self.framedIconControl.object

    self.statusMultiIcon = self.control:GetNamedChild("Status")
end

function ZO_VengeancePerkTile_Keyboard:PostInitializePlatform()
    -- keybindStripDescriptor and canFocus need to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    table.insert(self.keybindStripDescriptor,
    {
        keybind = "UI_SHORTCUT_PRIMARY",
        name = function()
            if self.perkData:IsPerkEquipped() then
                return GetString(SI_CAMPAIGN_VENGEANCE_PERK_DESELECT)
            else
                return GetString(SI_CAMPAIGN_VENGEANCE_PERK_SELECT)
            end
        end,
        callback = function()
            if self.perkData:IsPerkEquipped() then
                ZO_VENGEANCE_MANAGER:ClearEquippedPerk(self.perkData)
            else
                ZO_VENGEANCE_MANAGER:SetEquippedPerk(self.perkData)
            end
            self:UpdateKeybinds()
        end,
        enabled = function()
            local canEquip, result = self.perkData:CanEquipPerk()
            return canEquip or result == VENGEANCE_ACTION_RESULT_PERK_ALREADY_EQUIPPED, GetString(SI_CAMPAIGN_VENGEANCE_PERKS_EDIT_INVALID_SUBZONE)
        end,
        visible = function()
            return self.perkData ~= nil
        end,
    })
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_VengeancePerkTile_Keyboard:LayoutPlatform(data)
    self.perkData = data

    local isDisabled = self.perkData:IsPerkDisabled()

    self:SetTitle(data:GetName())
    self.framedIcon:SetPerkData(self.perkData)
    self.framedIcon:SetPerkDisabled(isDisabled)
    self.framedIconControl:SetHidden(false)

    local desaturation = isDisabled and 1 or 0
    self:GetHighlightControl():SetDesaturation(desaturation)

    -- Status
    local statusMultiIcon = self.statusMultiIcon
    statusMultiIcon:ClearIcons()

    if data:IsPerkEquipped() then
        statusMultiIcon:AddIcon(ZO_CHECK_ICON)
    end

    statusMultiIcon:Show()

    self:RefreshMouseoverVisuals()
end

function ZO_VengeancePerkTile_Keyboard:OnControlHidden()
    self:OnMouseExit()
    ZO_ContextualActionsTile.OnControlHidden(self)
end

function ZO_VengeancePerkTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)

    if self.perkData then
        if not isFocused then
            ClearTooltip(SkillTooltip)
        end

        self:RefreshMouseoverVisuals()
    end
end

-- End ZO_ContextualActionsTile Overrides --

function ZO_VengeancePerkTile_Keyboard:Reset()
    self:SetTitle("")
    self:SetIcon("")
    self.framedIconControl:SetHidden(true)
    self.statusMultiIcon:ClearIcons()
end

function ZO_VengeancePerkTile_Keyboard:RefreshMouseoverVisuals()
    if self.perkData and self:IsMousedOver() then
        -- Tooltip
        ClearTooltip(SkillTooltip)
        local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 5
        InitializeTooltip(SkillTooltip, self.control, RIGHT, offsetX, 0, LEFT)
        local _, disabledReason = self.perkData:IsPerkDisabled()
        SkillTooltip:SetVengeancePerk(self.perkData:GetPerkIndex(), disabledReason)
    end
end

function ZO_VengeancePerkTile_Keyboard:ShowMenu()
    if ZO_VENGEANCE_MANAGER:IsEquippedLoadoutEditableForCurrentZone() and self.perkData then
        ClearMenu()
        self:AddMenuOptions()
        ShowMenu(self.control)
    end
end

function ZO_VengeancePerkTile_Keyboard:AddMenuOptions()
    local perkData = self.perkData
    if perkData:IsPerkEquipped() then
        local function UnequipPerk()
            ZO_VENGEANCE_MANAGER:ClearEquippedPerk(perkData)
        end
        AddMenuItem(GetString(SI_CAMPAIGN_VENGEANCE_PERK_DESELECT), UnequipPerk)
    elseif not perkData:IsPerkDisabled() then
        local function EquipPerk()
            ZO_VENGEANCE_MANAGER:SetEquippedPerk(perkData)
        end
        AddMenuItem(GetString(SI_CAMPAIGN_VENGEANCE_PERK_SELECT), EquipPerk)
    end
end

function ZO_VengeancePerkTile_Keyboard:OnMouseUp(button, upInside)
    if upInside then
        if button == MOUSE_BUTTON_INDEX_RIGHT then
            self:ShowMenu()
        end
    end
end

function ZO_VengeancePerkTile_Keyboard:OnMouseDoubleClick(button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        if self.perkData and self.perkData:CanEquipPerk() and self:IsMousedOver() then
            if self.perkData:IsPerkEquipped() then
                ZO_VENGEANCE_MANAGER:ClearEquippedPerk(self.perkData)
            else
                ZO_VENGEANCE_MANAGER:SetEquippedPerk(self.perkData)
            end
            self:UpdateKeybinds()
        end
    end
end

function ZO_VengeancePerkTile_Keyboard:TryPickupPerkFromList(control)
    if ZO_VENGEANCE_MANAGER:IsEquippedLoadoutEditableForCurrentZone()
        and not ZO_VENGEANCE_MANAGER:IsPerkEquippedInDifferentSlot(self.perkData) then
        PickupVengeancePerk(self.perkData:GetPerkIndex(), self.perkData:GetSlot())
    end
end

-- Begin Global XML Functions --

function ZO_VengeancePerkTile_Keyboard.OnControlInitialized(control)
    ZO_VengeancePerkTile_Keyboard:New(control)
end

function ZO_VengeancePerkTile_Keyboard.VengeancePerk_OnStartDrag(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        control.object:TryPickupPerkFromList(control)
    end
end

-- End Global XML Functions --

-----------------------------
-- Vengeance Perks Keyboard
-----------------------------

local VENGEANCE_PERK_TILE_GRID_PADDING = 10

ZO_Vengeance_Perks_Keyboard = ZO_DeferredInitializingObject:Subclass()

function ZO_Vengeance_Perks_Keyboard:Initialize(control)
    self.control = control
    self.instructionLabel = control:GetNamedChild("InstructionText")
    self.equippedPerksContainer = control:GetNamedChild("EquippedPerksContainer")
    self.loadoutHeader = self.equippedPerksContainer:GetNamedChild("LoadoutHeader")
    self.equippedPerkControls =
    {
        [VENGEANCE_PERK_SLOT_RED] = self.equippedPerksContainer:GetNamedChild("RedPerk"),
        [VENGEANCE_PERK_SLOT_YELLOW] = self.equippedPerksContainer:GetNamedChild("YellowPerk"),
        [VENGEANCE_PERK_SLOT_BLUE] = self.equippedPerksContainer:GetNamedChild("BluePerk"),
    }

    for slot, equippedControl in pairs(self.equippedPerkControls) do
        equippedControl.icon:SetPerkSlot(slot)
        equippedControl.icon:SetTooltipAnchors(LEFT, 159, 0, RIGHT)
    end

    VENGEANCE_PERKS_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ZO_DeferredInitializingObject.Initialize(self, VENGEANCE_PERKS_KEYBOARD_FRAGMENT)
end

function ZO_Vengeance_Perks_Keyboard:OnDeferredInitialize()
    self:InitializeGridList()
    self:InitializeEvents()
end

function ZO_Vengeance_Perks_Keyboard:InitializeGridList()
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_GridSquareEntryData_Shared)

    self.gridListControl = self.control:GetNamedChild("List")
    self.gridList = ZO_GridScrollList_Keyboard:New(self.gridListControl, ZO_GRID_SCROLL_LIST_AUTOFILL)

    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true
    local HEADER_HEIGHT = 30
    self.gridList:AddEntryTemplate("ZO_VengeancePerkTile_Keyboard_Control", ZO_VENGEANCE_PERK_TILE_KEYBOARD_DIMENSIONS_X, ZO_VENGEANCE_PERK_TILE_KEYBOARD_DIMENSIONS_Y, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, VENGEANCE_PERK_TILE_GRID_PADDING, VENGEANCE_PERK_TILE_GRID_PADDING, CENTER_ENTRIES)
    self.gridList:SetAutoFillEntryTemplate("ZO_VengeancePerkTile_Keyboard_Control")
    self.gridList:AddHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridList:SetHeaderPrePadding(VENGEANCE_PERK_TILE_GRID_PADDING * 3)

    ZO_VENGEANCE_MANAGER:RegisterCallback("OnPerkSelectionChanged", function() self:RefreshGridList() end)
end

function ZO_Vengeance_Perks_Keyboard:InitializeEvents()
    local function HandleCursorPickup(eventCode, cursorType, ...)
        if not self:IsShowing() then
            return
        end

        if cursorType == MOUSE_CONTENT_VENGEANCE_PERK then
            local perkIndex = ...
            self:ShowSlotDropCalloutsForEquippedPerks(perkIndex)
            PlaySound(SOUNDS.VENGEANCE_PERK_PICKUP)
        end
    end

    local function HandleCursorCleared()
        if self:IsShowing() then
            self:HideAllSlotDropCallouts()
            PlaySound(SOUNDS.VENGEANCE_PERK_DROP)
            self.isEquippedPerkOnCursor = nil
        end
    end

    self.control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    self.control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
end

function ZO_Vengeance_Perks_Keyboard:UpdateInstructionText()
    local isErrorText = false
    if not ZO_VENGEANCE_MANAGER:IsEquippedLoadoutEditableForCurrentZone() then
        self.instructionLabel:SetText(GetString(SI_CAMPAIGN_VENGEANCE_PERKS_EDIT_INVALID_SUBZONE))
        self.instructionLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        isErrorText = true
    end

    if not isErrorText then
        local loadout = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
        self.instructionLabel:SetText(zo_strformat(SI_CAMPAIGN_VENGEANCE_PERKS_LOADOUT_HEADER, loadout:GetName()))
        self.instructionLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_Vengeance_Perks_Keyboard:OnShowing()
    TriggerTutorial(TUTORIAL_TRIGGER_VENGEANCE_PERKS_OPENED)
    SCENE_MANAGER:AddFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
    self:BuildGridList()
    self:RefreshLoadoutHeader()
    self:RefreshEquippedPerks()
end

function ZO_Vengeance_Perks_Keyboard:OnHiding()
    SCENE_MANAGER:RemoveFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
    ZO_VENGEANCE_MANAGER:ApplyEquippedPerks()
end

function ZO_Vengeance_Perks_Keyboard:BuildGridList()
    self.gridList:ClearGridList()
    self.entryDataObjectPool:ReleaseAllObjects()

    for _, perkData in ZO_VENGEANCE_MANAGER:PerkDataIterator() do
        local entryData = self.entryDataObjectPool:AcquireObject()
        entryData:SetDataSource(perkData)
        entryData.gridHeaderTemplate = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD
        entryData.gridHeaderName = ZO_VENGEANCE_MANAGER:GetPerkSlotName(perkData:GetSlot())
        self.gridList:AddEntry(entryData, "ZO_VengeancePerkTile_Keyboard_Control")
    end

    self.gridList:CommitGridList()

    self:UpdateInstructionText()
end

function ZO_Vengeance_Perks_Keyboard:RefreshLoadoutHeader()
    local loadoutData = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
    if loadoutData then
        self.loadoutHeader:SetText(zo_strformat(SI_CAMPAIGN_VENGEANCE_PERKS_LOADOUT_HEADER, loadoutData:GetName()))
    else
        internalassert(false, "No Loadout is Equipped, this shound never happen!")
    end
end

function ZO_Vengeance_Perks_Keyboard:RefreshEquippedPerks()
    for slot, control in pairs(self.equippedPerkControls) do
        local perkData = ZO_VENGEANCE_MANAGER:GetEquippedPerkDataBySlot(slot)
        control.icon:SetPerkData(perkData)
        if perkData then
            control.name:SetText(perkData:GetName())
        else
            control.name:SetText(ZO_VENGEANCE_MANAGER:GetEmptyPerkName())
        end
    end
end

function ZO_Vengeance_Perks_Keyboard:RefreshGridList()
    self.gridList:RefreshGridList()
    self:RefreshEquippedPerks()
    self:UpdateInstructionText()
end

function ZO_Vengeance_Perks_Keyboard:ShowSlotDropCalloutsForEquippedPerks(perkIndex)
    for slot, control in pairs(self.equippedPerkControls) do
        local perkData = ZO_VENGEANCE_MANAGER:GetPerkByIndex(perkIndex, slot)
        local isSlotDisabled = perkData == nil
        control.icon:SetPerkDisabled(isSlotDisabled)
        control.highlight:SetHidden(isSlotDisabled)
    end
end

function ZO_Vengeance_Perks_Keyboard:HideAllSlotDropCallouts()
    for slot, control in pairs(self.equippedPerkControls) do
        local SLOT_ENABLED = false
        control.icon:SetPerkDisabled(SLOT_ENABLED)
        control.highlight:SetHidden(true)
    end
end

function ZO_Vengeance_Perks_Keyboard:TryEquipPerkFromMouse(targetControl)
    local perkIndex, sourceSlot = GetCursorVengeancePerkData()
    if not self.isEquippedPerkOnCursor then
        ClearCursor()
    end
    for slot, control in pairs(self.equippedPerkControls) do
        if targetControl == control then
            if not self.isEquippedPerkOnCursor or slot ~= sourceSlot then
                local perkData = ZO_VENGEANCE_MANAGER:GetPerkByIndex(perkIndex, slot)
                if perkData and perkData:CanEquipPerk() then
                    ZO_VENGEANCE_MANAGER:SetEquippedPerk(perkData)
                end
                if self.isEquippedPerkOnCursor then
                    ClearCursor()
                    self.isEquippedPerkOnCursor = nil
                end
            end
            return
        end
    end
end

function ZO_Vengeance_Perks_Keyboard:TryPickupPerkFromEquippedSlot(targetControl)
    if ZO_VENGEANCE_MANAGER:IsEquippedLoadoutEditableForCurrentZone() then
        for slot, control in pairs(self.equippedPerkControls) do
            if targetControl == control then
                local perkIndex = ZO_VENGEANCE_MANAGER:GetEquippedPerkIndexBySlot(slot)
                PickupVengeancePerk(perkIndex, slot)
                ZO_VENGEANCE_MANAGER:ClearEquippedPerkBySlot(slot)
                self.isEquippedPerkOnCursor = true
                return
            end
        end
    end
end

function ZO_Vengeance_Perks_Keyboard:ShowEquippedSlotControlContextMenu(targetControl)
    if ZO_VENGEANCE_MANAGER:IsEquippedLoadoutEditableForCurrentZone() then
        for slot, control in pairs(self.equippedPerkControls) do
            if targetControl == control then
                local perkIndex = ZO_VENGEANCE_MANAGER:GetEquippedPerkIndexBySlot(slot)
                local perkData = ZO_VENGEANCE_MANAGER:GetPerkByIndex(perkIndex, slot)
                if perkData then
                    ClearMenu()
                    local function UnequipPerk()
                        ZO_VENGEANCE_MANAGER:ClearEquippedPerk(perkData)
                    end
                    AddMenuItem(GetString(SI_CAMPAIGN_VENGEANCE_PERK_DESELECT), UnequipPerk)
                    ShowMenu(targetControl)
                end
                return
            end
        end
    end
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Vengeance_Perks_Keyboard.OnControlInitialized(control)
    VENGEANCE_PERKS_KEYBOARD = ZO_Vengeance_Perks_Keyboard:New(control)
end

function ZO_Vengeance_Perks_Keyboard.EquippedPerk_OnMouseEnter(control)
    control.icon:ShowTooltip()
end

function ZO_Vengeance_Perks_Keyboard.EquippedPerk_OnMouseExit(control)
    ClearTooltip(SkillTooltip)
end

function ZO_Vengeance_Perks_Keyboard.EquippedPerk_OnMouseUp(control, button)
    if not VENGEANCE_PERKS_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        VENGEANCE_PERKS_KEYBOARD:TryEquipPerkFromMouse(control)
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        VENGEANCE_PERKS_KEYBOARD:ShowEquippedSlotControlContextMenu(control)
    end
end

function ZO_Vengeance_Perks_Keyboard.EquippedPerk_OnStartDrag(control, button)
    if not VENGEANCE_PERKS_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        VENGEANCE_PERKS_KEYBOARD:TryPickupPerkFromEquippedSlot(control)
    end
end

function ZO_Vengeance_Perks_Keyboard.EquippedPerk_OnReceiveDrag(control, button)
    if not VENGEANCE_PERKS_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        VENGEANCE_PERKS_KEYBOARD:TryEquipPerkFromMouse(control)
    end
end