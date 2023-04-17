
ZO_Armory_Keyboard = ZO_InitializingObject:Subclass()

local DATA_ENTRY_TYPE_COLLAPSED = 1
local DATA_ENTRY_TYPE_EXPANDED = 2
local DATA_ENTRY_TYPE_UNLOCK_BUILD = 3

ZO_ARMORY_KEYBOARD_COLLAPSED_ENTRY_HEIGHT = 96
ZO_ARMORY_KEYBOARD_EXPANDED_ENTRY_HEIGHT = 550
ZO_ARMORY_KEYBOARD_UNLOCK_ENTRY_HEIGHT = 96

ZO_ARMORY_KEYBOARD_MISC_ROW_LABEL_OFFSET_X = 20

local DEFAULT_SELECTED_BUILD_INDEX = 1

function ZO_Armory_Keyboard:Initialize(control)
    self.control = control
    self.buildCountLabel = control:GetNamedChild("TitleSectionBuildCount")
    self.selectedBuildIndex = DEFAULT_SELECTED_BUILD_INDEX

    self:InitializeList()
    self:InitializeKeybindStripDescriptors()

    ARMORY_KEYBOARD_SCENE = ZO_InteractScene:New("armoryKeyboard", SCENE_MANAGER, ZO_ARMORY_MANAGER:GetInteraction())
    ARMORY_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ARMORY_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self:RefreshBuilds()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            TriggerTutorial(TUTORIAL_TRIGGER_ARMORY_OPENED)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)

    ARMORY_KEYBOARD_SCENE:SetHideSceneConfirmationCallback(function(scene, nextSceneName, bypassHideSceneConfirmationReason)
        if ZO_ARMORY_MANAGER:IsBuildOperationInProgress() then
            ARMORY_KEYBOARD_SCENE:RejectHideScene()
            --If we tried to hide the scene because the gamepad preferred mode changed, close the armory when the build operation completes to prevent the user from getting stuck in a bad state
            if bypassHideSceneConfirmationReason == ZO_BHSCR_GAMEPAD_MODE_CHANGED then
                ZO_ARMORY_MANAGER:SetHideOnBuildOperationComplete(true)
            end
        else
            ARMORY_KEYBOARD_SCENE:AcceptHideScene()
        end
    end)

    ZO_ARMORY_MANAGER:RegisterCallback("BuildOperationStarted", function()
        if ARMORY_KEYBOARD_FRAGMENT:IsShowing() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)

    ZO_ARMORY_MANAGER:RegisterCallback("BuildOperationCompleted", function()
        if ARMORY_KEYBOARD_FRAGMENT:IsShowing() then
            self:RefreshBuilds()
        end
    end)

    ZO_ARMORY_MANAGER:RegisterCallback("BuildListUpdated", function()
        if ARMORY_KEYBOARD_FRAGMENT:IsShowing() then
            self:RefreshBuilds()
        end
    end)
end

function ZO_Armory_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        --Equip build
        {
            name = GetString(SI_ARMORY_RESTORE_BUILD_ACTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            onShowCooldown = function()
                return GetArmoryOperationsCooldownRemaining() / 1000
            end,
            callback = function()
                ZO_ARMORY_MANAGER:ShowBuildOperationConfirmationDialog(ARMORY_BUILD_OPERATION_TYPE_RESTORE, self.selectedBuildIndex)
            end,
            visible = function()
                return self.selectedBuildIndex
            end,
            enabled = function()
                local function disabledAlertText()
                    return zo_strformat(SI_ARMORY_BUILD_OPERATION_COOLDOWN_ALERT, ZO_FormatTimeMilliseconds(GetArmoryOperationsCooldownDurationMs(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
                end
                return not ZO_ARMORY_MANAGER:IsBuildOperationInProgress(), disabledAlertText
            end,
        },
        --Save build
        {
            name = GetString(SI_ARMORY_SAVE_BUILD_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",
            onShowCooldown = function()
                return GetArmoryOperationsCooldownRemaining() / 1000
            end,
            callback = function()
                ZO_ARMORY_MANAGER:ShowBuildOperationConfirmationDialog(ARMORY_BUILD_OPERATION_TYPE_SAVE, self.selectedBuildIndex)
            end,
            visible = function()
                return self.selectedBuildIndex
            end,
            enabled = function()
                local function disabledAlertText()
                    return zo_strformat(SI_ARMORY_BUILD_OPERATION_COOLDOWN_ALERT, ZO_FormatTimeMilliseconds(GetArmoryOperationsCooldownDurationMs(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
                end
                return not ZO_ARMORY_MANAGER:IsBuildOperationInProgress(), disabledAlertText
            end,
        },
        {
            name = GetString(SI_ARMORY_OPEN_BUILD_DIALOG_ACTION),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ZO_Dialogs_ShowDialog("ArmorySettingsDialog", { selectedBuildData = ZO_ARMORY_MANAGER:GetBuildDataByIndex(self.selectedBuildIndex), confirmCallback = function() self:RefreshBuilds() end })
            end,
            visible = function()
                return self.selectedBuildIndex
            end,
            enabled = function()
                return not ZO_ARMORY_MANAGER:IsBuildOperationInProgress()
            end,
        },
    }
end

function ZO_Armory_Keyboard:InitializeList()
    self.list = self.control:GetNamedChild("List")

    local function SetupCollapsedBuildEntry(control, data)
        control.nameLabel:SetText(data:GetName())
        control.iconTexture:SetTexture(data:GetIcon())
    end

    local function SetupExpandedBuildEntry(control, data)
        --Setup the header
        control.nameLabel:SetText(data:GetName())
        control.iconTexture:SetTexture(data:GetIcon())

        --Set the attribute values
        control.magickaAttribute.attributeValue:SetText(data:GetAttributeSpentPoints(ATTRIBUTE_MAGICKA))
        control.healthAttribute.attributeValue:SetText(data:GetAttributeSpentPoints(ATTRIBUTE_HEALTH))
        control.staminaAttribute.attributeValue:SetText(data:GetAttributeSpentPoints(ATTRIBUTE_STAMINA))

        --Setup the champion bar data
        control.championBar:AssignArmoryBuildData(data)

        --Setup the weapon and skills row data
        control.weaponSetRow1:AssignArmoryBuildData(data)
        control.weaponSetRow2:AssignArmoryBuildData(data)

        --Setup the equipment row data
        control.equipmentRow.buildData = data
        for _, slotControl in ipairs(control.equipmentSlots) do
            local slotState, itemLink = data:GetEquipSlotItemLinkInfo(slotControl.equipType)
            if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID then
                slotControl.icon:SetTexture(GetItemLinkIcon(itemLink))
            else
                slotControl.icon:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(slotControl.equipType))
            end

            if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_MISSING or slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE then
                slotControl.icon:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
            else
                slotControl.icon:SetColor(ZO_WHITE:UnpackRGBA())
            end
        end

        --Set the mundus stones
        local mundusStoneList = ZO_GenerateCommaSeparatedListWithoutAnd(data:GetEquippedMundusStoneNames())
        control.mundusLabel:SetText(zo_strformat(SI_ARMORY_MUNDUS_STONE_LABEL, ZO_SELECTED_TEXT:Colorize(mundusStoneList)))

        --Set the curse type
        local curseType = GetString("SI_CURSETYPE", data:GetCurseType())
        control.curseTypeLabel:SetText(zo_strformat(SI_ARMORY_CURSE_TYPE_LABEL, ZO_SELECTED_TEXT:Colorize(curseType)))

        --Set the outfit name
        control.outfitNameLabel:SetText(zo_strformat(SI_ARMORY_OUTFIT_LABEL, ZO_SELECTED_TEXT:Colorize(data:GetEquippedOutfitName())))
    end

    ZO_ScrollList_AddDataType(self.list, DATA_ENTRY_TYPE_COLLAPSED, "ZO_Armory_CollapsedBuildEntry", ZO_ARMORY_KEYBOARD_COLLAPSED_ENTRY_HEIGHT, SetupCollapsedBuildEntry)
    ZO_ScrollList_AddDataType(self.list, DATA_ENTRY_TYPE_EXPANDED, "ZO_Armory_ExpandedBuildEntry", ZO_ARMORY_KEYBOARD_EXPANDED_ENTRY_HEIGHT, SetupExpandedBuildEntry)
    ZO_ScrollList_AddDataType(self.list, DATA_ENTRY_TYPE_UNLOCK_BUILD, "ZO_Armory_UnlockBuildEntry", ZO_ARMORY_KEYBOARD_UNLOCK_ENTRY_HEIGHT)
end

function ZO_Armory_Keyboard:RefreshBuilds(scrollToSelected)
    local numBuilds = GetNumUnlockedArmoryBuilds()
    self.buildCountLabel:SetText(zo_strformat(SI_ARMORY_UNLOCKED_BUILD_COUNT, numBuilds))

    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    for _, buildData in ZO_ARMORY_MANAGER:BuildDataIterator() do
        local entryData = ZO_EntryData:New(buildData)

        if buildData:GetBuildIndex() == self.selectedBuildIndex then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_ENTRY_TYPE_EXPANDED, entryData))
        else
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_ENTRY_TYPE_COLLAPSED, entryData))
        end
    end

    if numBuilds < MAX_NUM_ARMORY_BUILDS then
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_ENTRY_TYPE_UNLOCK_BUILD, {}))
    end

    ZO_ScrollList_Commit(self.list)

    --Order matters. We want to do this after ZO_ScrollList_Commit so the controls can be positioned properly before we attempt to scroll to them 
    if scrollToSelected and self.selectedBuildIndex then
        local NO_CALLBACK = nil
        local ANIMATE_INSTANTLY = true
        ZO_ScrollList_ScrollDataToCenter(self.list, self.selectedBuildIndex, NO_CALLBACK, ANIMATE_INSTANTLY)
    end

    self:UpdateKeybinds()
end

function ZO_Armory_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    for _, keybindDesc in ipairs(self.keybindStripDescriptor) do
        local onShowCooldown = keybindDesc.onShowCooldown
        if onShowCooldown then
            KEYBIND_STRIP:TriggerCooldown(keybindDesc, onShowCooldown)
        end
    end
end

function ZO_Armory_Keyboard:SetSelectedBuildIndex(buildIndex)
    if self.selectedBuildIndex ~= buildIndex then
        if buildIndex == nil then
            PlaySound(SOUNDS.ARMORY_BUILD_SLOT_COLLAPSED)
        else
            PlaySound(SOUNDS.ARMORY_BUILD_SLOT_EXPANDED)
        end
        self.selectedBuildIndex = buildIndex
        local SCROLL_TO_SELECTED = true
        self:RefreshBuilds(SCROLL_TO_SELECTED)
    end
end

-----------------------------
-- ZO_ArmoryWeaponSetRow_Keyboard
-----------------------------

ZO_ArmoryWeaponSetRow_Keyboard = ZO_InitializingCallbackObject:Subclass()

function ZO_ArmoryWeaponSetRow_Keyboard:Initialize(control)
    control.object = self
    self.control = control
    self.mainHandControl = control:GetNamedChild("MainHand")
    self.offHandControl = control:GetNamedChild("OffHand")
    self.poisonControl = control:GetNamedChild("Poison")
    self.skills = control:GetNamedChild("Skills").object

    local function EquipSlotOnMouseEnter(control)
        if not self:GetLocked() and self.buildData then
            ZO_ArmoryEquipSlot_OnMouseEnter(control, self.buildData)
        end
    end

    local function EquipSlotOnMouseExit(control)
        ClearTooltip(ItemTooltip)
        if not self:GetLocked() then
            ClearTooltip(InformationTooltip)
        end
    end

    self.mainHandControl:SetHandler("OnMouseEnter", EquipSlotOnMouseEnter)
    self.offHandControl:SetHandler("OnMouseEnter", EquipSlotOnMouseEnter)
    self.poisonControl:SetHandler("OnMouseEnter", EquipSlotOnMouseEnter)

    self.mainHandControl:SetHandler("OnMouseExit", EquipSlotOnMouseExit)
    self.offHandControl:SetHandler("OnMouseExit", EquipSlotOnMouseExit)
    self.poisonControl:SetHandler("OnMouseExit", EquipSlotOnMouseExit)

    --Set up the shared input group
    self.inputGroup = ZO_MouseInputGroup:New(control)
    self.inputGroup:Add(self.mainHandControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    self.inputGroup:Add(self.offHandControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    self.inputGroup:Add(self.poisonControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    self.skills:AddSlotsToMouseInputGroup(self.inputGroup, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
end

function ZO_ArmoryWeaponSetRow_Keyboard:SetHotbarCategory(hotbarCategory)
    --The equip types depend on whether or not this is the backbar or primary bar
    local isPrimary = hotbarCategory == HOTBAR_CATEGORY_PRIMARY
    self.mainHandControl.equipType = isPrimary and EQUIP_SLOT_MAIN_HAND or EQUIP_SLOT_BACKUP_MAIN
    self.offHandControl.equipType = isPrimary and EQUIP_SLOT_OFF_HAND or EQUIP_SLOT_BACKUP_OFF
    self.poisonControl.equipType = isPrimary and EQUIP_SLOT_POISON or EQUIP_SLOT_BACKUP_POISON
    
    --Set the hotbar category for the skills bar
    self.skills:SetHotbarCategory(hotbarCategory)
end

function ZO_ArmoryWeaponSetRow_Keyboard:AssignArmoryBuildData(data)
    self.skills:AssignArmoryBuildData(data)
    self:AssignArmoryBuildDataToEquipSlots(data)
    self.buildData = data
end

function ZO_ArmoryWeaponSetRow_Keyboard:SetupEquipSlotIcon(equipSlotControl, itemLink, slotState)
    if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID then
        equipSlotControl.icon:SetTexture(GetItemLinkIcon(itemLink))
    else
        equipSlotControl.icon:SetTexture(ZO_Character_GetEmptyEquipSlotTexture(equipSlotControl.equipType))
    end

    if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_MISSING or slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE then
        equipSlotControl.icon:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    else
        equipSlotControl.icon:SetColor(ZO_WHITE:UnpackRGBA())
    end
end

do
    local LOCKED_EQUIP_SLOT_TEXTURE = "EsoUI/Art/CharacterWindow/weaponSwap_locked.dds"
    function ZO_ArmoryWeaponSetRow_Keyboard:AssignArmoryBuildDataToEquipSlots(data)
        if self:GetLocked() then
            --If this bar is locked, there can't be anything in the equip slots, so just set them locked and move on
            self.mainHandControl.icon:SetTexture(LOCKED_EQUIP_SLOT_TEXTURE)
            self.offHandControl.icon:SetTexture(LOCKED_EQUIP_SLOT_TEXTURE)
            self.poisonControl.icon:SetTexture(LOCKED_EQUIP_SLOT_TEXTURE)
        else
            --First, grab the slot data for each equip slot
            local mainHandSlotState, mainHandItemLink = data:GetEquipSlotItemLinkInfo(self.mainHandControl.equipType)
            local offHandSlotState, offHandItemLink = data:GetEquipSlotItemLinkInfo(self.offHandControl.equipType)
            local poisonSlotState, poisonItemLink = data:GetEquipSlotItemLinkInfo(self.poisonControl.equipType)

            --Setup the main hand slot
            self:SetupEquipSlotIcon(self.mainHandControl, mainHandItemLink, mainHandSlotState)

            --If the main hand has a two handed weapon in it, we need to do special logic
            if mainHandSlotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID and GetItemLinkEquipType(mainHandItemLink) == EQUIP_TYPE_TWO_HAND then
                --In this case, we want to show the main hand item icon, so pass the main hand item link and slot state instead of the offhand one
                self:SetupEquipSlotIcon(self.offHandControl, mainHandItemLink, mainHandSlotState)
                local r, g, b = ZO_ERROR_COLOR:UnpackRGB()
                self.offHandControl.icon:SetColor(r, g, b, 0.5)
            else
                self:SetupEquipSlotIcon(self.offHandControl, offHandItemLink, offHandSlotState)
            end

            --Setup the poison slot
            self:SetupEquipSlotIcon(self.poisonControl, poisonItemLink, poisonSlotState)
        end
    end
end

function ZO_ArmoryWeaponSetRow_Keyboard:GetLocked()
    return self.skills:GetLocked()
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Armory_Keyboard_TopLevel_OnInitialized(control)
    ARMORY_KEYBOARD = ZO_Armory_Keyboard:New(control)
end

function ZO_Armory_Keyboard_CollapsedEntry_OnMouseUp(control, button, upInside)
    if upInside then
        ARMORY_KEYBOARD:SetSelectedBuildIndex(control:GetParent().dataEntry.data:GetBuildIndex())
    end
end

function ZO_Armory_Keyboard_ExpandedEntry_OnMouseUp(control, button, upInside)
    if upInside then
        ARMORY_KEYBOARD:SetSelectedBuildIndex(nil)
    end
end

function ZO_Armory_Keyboard_UnlockBuildEntry_OnMouseUp(control, button, upInside)
    if upInside then
        ShowMarketAndSearch(GetString(SI_CROWN_STORE_SEARCH_ADDITIONAL_ARMORY_SLOTS), MARKET_OPEN_OPERATION_UNLOCK_ARMORY_BUILD_SLOT)
    end
end

do
    local ATTRIBUTE_BAR_TEXTURES =
    {
        [ATTRIBUTE_HEALTH] = "EsoUI/Art/Stats/stats_healthBar.dds",
        [ATTRIBUTE_MAGICKA] = "EsoUI/Art/Stats/stats_magickaBar.dds",
        [ATTRIBUTE_STAMINA] = "EsoUI/Art/Stats/stats_staminaBar.dds",
    }

    local EQUIPMENT_ROW_SLOT_PADDING_X = 14

    local function InitializeArmoryAttributeControl(control)
        control.bar:SetTexture(ATTRIBUTE_BAR_TEXTURES[control.attributeType])
        control.nameLabel:SetText(GetString("SI_ATTRIBUTES", control.attributeType))
    end

    function ZO_Armory_ExpandedEntry_OnInitialized(control)
        control.nameLabel = control:GetNamedChild("ContainerHeaderName")
        control.iconTexture = control:GetNamedChild("ContainerHeaderIcon")

        --Set up the attribute bars
        control.magickaAttribute = control:GetNamedChild("ContainerAttributesMagicka")
        control.healthAttribute = control:GetNamedChild("ContainerAttributesHealth")
        control.staminaAttribute = control:GetNamedChild("ContainerAttributesStamina")

        InitializeArmoryAttributeControl(control.magickaAttribute)
        InitializeArmoryAttributeControl(control.healthAttribute)
        InitializeArmoryAttributeControl(control.staminaAttribute)

        --Set up the champion bar
        control.championBar = ZO_ArmoryChampionActionBar:New(control:GetNamedChild("ContainerChampionBar"))

        --Set up the skill and weapon rows
        control.weaponSetRow1 = control:GetNamedChild("ContainerWeaponRow1").object
        control.weaponSetRow2 = control:GetNamedChild("ContainerWeaponRow2").object
        control.weaponSetRow1:SetHotbarCategory(HOTBAR_CATEGORY_PRIMARY)
        control.weaponSetRow2:SetHotbarCategory(HOTBAR_CATEGORY_BACKUP)

        local curseOutfitRow = control:GetNamedChild("ContainerCurseOutfitRow")
        control.mundusLabel = control:GetNamedChild("ContainerMundus")
        control.curseTypeLabel = curseOutfitRow:GetNamedChild("CurseType")
        control.outfitNameLabel = curseOutfitRow:GetNamedChild("Outfit")

        --Setup the equipment slots
        control.equipmentRow = control:GetNamedChild("ContainerEquipmentRow")
        local equipmentSlots = {}
        local lastSlotControl = nil
        local equipmentSlotTypes = ZO_ARMORY_MANAGER:GetEquipmentSlotTypes()
        for index, equipType in ipairs(equipmentSlotTypes) do
            local slotControl = CreateControlFromVirtual("$(parent)Slot", control.equipmentRow, "ZO_ArmoryEquippedSlot", index)
            slotControl.equipType = equipType

            if lastSlotControl then
                slotControl:SetAnchor(LEFT, lastSlotControl, RIGHT, EQUIPMENT_ROW_SLOT_PADDING_X, 0)
            else
                slotControl:SetAnchor(LEFT, control.equipmentRow, LEFT, 0, 0)
            end

            slotControl:SetHandler("OnMouseEnter", function(control)
                ZO_ArmoryEquipSlot_OnMouseEnter(control, control:GetParent().buildData)
            end)

            slotControl:SetHandler("OnMouseExit", function(control)
                ClearTooltip(ItemTooltip)
                ClearTooltip(InformationTooltip)
            end)

            table.insert(equipmentSlots, slotControl)
            lastSlotControl = slotControl
        end

        control.equipmentSlots = equipmentSlots
    end

    local ATTRIBUTE_DESCRIPTIONS =
    {
        [ATTRIBUTE_HEALTH] = SI_ATTRIBUTE_TOOLTIP_HEALTH,
        [ATTRIBUTE_MAGICKA] = SI_ATTRIBUTE_TOOLTIP_MAGICKA,
        [ATTRIBUTE_STAMINA] = SI_ATTRIBUTE_TOOLTIP_STAMINA,
    }

    function ZO_ArmoryAttribute_OnMouseEnter(control)
        local attributeType = control.attributeType
        local attributeName = GetString("SI_ATTRIBUTES", attributeType)

        InitializeTooltip(InformationTooltip, control, RIGHT, -5)
        InformationTooltip:AddLine(attributeName, "", ZO_NORMAL_TEXT:UnpackRGBA())
        InformationTooltip:AddLine(GetString(ATTRIBUTE_DESCRIPTIONS[attributeType]))
    end

    function ZO_ArmoryAttribute_OnMouseExit()
        ClearTooltip(InformationTooltip)
    end
end

function ZO_ArmoryWeaponSetRow_Keyboard_OnMouseEnter(control)
    if control.object and control.object:GetLocked() then
        local unlockLevel = GetWeaponSwapUnlockedLevel()
        InitializeTooltip(InformationTooltip, control, RIGHT, -30)
        InformationTooltip:AddLine(zo_strformat(SI_ARMORY_BACKBAR_LOCKED_TOOLTIP, unlockLevel), "", ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_ArmoryWeaponSetRow_Keyboard_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_ArmoryEquipSlot_OnMouseEnter(control, buildData)
    ClearTooltip(ItemTooltip)
    ClearTooltip(InformationTooltip)
    local slotState, bagId, slotIndex = buildData:GetEquipSlotInfo(control.equipType)
    if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID then
        InitializeTooltip(ItemTooltip, control, RIGHT, -5, 0, LEFT)
        ItemTooltip:SetBagItem(bagId, slotIndex)
    elseif slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE then
        local tooltipString
        if bagId == BAG_BANK then
            tooltipString = GetString(SI_ARMORY_BUILD_EQUIPMENT_IN_BANK_TOOLTIP)
        elseif IsHouseBankBag(bagId) then
            local collectibleId = GetCollectibleForHouseBankBag(bagId)
            local nameWithNickname
            if collectibleId ~= 0 then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                if collectibleData then
                    nameWithNickname = collectibleData:GetNameWithNickname()
                end
            end

            if nameWithNickname and nameWithNickname ~= "" then
                tooltipString = zo_strformat(SI_ARMORY_BUILD_EQUIPMENT_IN_HOUSE_BANK_TOOLTIP, ZO_SELECTED_TEXT:Colorize(nameWithNickname))
            end
        end

        if not tooltipString or tooltipString == "" then
            -- If we somehow get here, just default to the standard missing tooltip
            tooltipString = GetString(SI_ARMORY_BUILD_EQUIPMENT_MISSING_TOOLTIP)
        end

        local DEFAULT_FONT = ""
        InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
        InformationTooltip:AddLine(tooltipString, DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
    elseif slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_MISSING then
        local DEFAULT_FONT = ""
        InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
        InformationTooltip:AddLine(GetString(SI_ARMORY_BUILD_EQUIPMENT_MISSING_TOOLTIP), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
    else
        local DEFAULT_FONT = ""
        InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
        InformationTooltip:AddLine(zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", control.equipType)), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
    end
end