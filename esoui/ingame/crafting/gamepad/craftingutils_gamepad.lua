-- Globals used by multiple crafting files
ZO_GAMEPAD_CRAFTING_UTILS_SLOT_SPACING = 231
ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_PADDING_Y = 50
ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_SLOT_STANDARD_HEIGHT = 190
ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET = ZO_GAMEPAD_QUADRANT_BOTTOM_OFFSET - ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_PADDING_Y

-- Note: call this towards the end of your keybind setup function...if you call this before you do something like self.keybindStripDescriptor = {keybinds} you'll destroy these
function ZO_GamepadCraftingUtils_AddGenericCraftingBackKeybindsToDescriptor(keybindDescriptor)
	if keybindDescriptor == nil then
		keybindDescriptor = {}
	end

	local genericStartButton = {
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			keybind = "UI_SHORTCUT_EXIT",
			order = -10000,
			callback = function()
				SCENE_MANAGER:ShowBaseScene()
			end,
			visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            ethereal = true,
		}

	local genericBackButton = {
			alignment = KEYBIND_STRIP_ALIGN_LEFT,
			name = GetString(SI_GAMEPAD_BACK_OPTION),
			keybind = "UI_SHORTCUT_NEGATIVE",
			order = -10000,
			callback = function()
				SCENE_MANAGER:HideCurrentScene()
			end,
			visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end
        }

	table.insert(keybindDescriptor, genericStartButton)
	table.insert(keybindDescriptor, genericBackButton)
end

function ZO_GamepadCraftingUtils_AddListTriggerKeybindDescriptors(descriptor, list, optionalHeaderComparator)
    local leftTrigger, rightTrigger = ZO_Gamepad_CreateListTriggerKeybindDescriptors(list, optionalHeaderComparator)

    local enabledFn = function()
        return not ZO_CraftingUtils_IsPerformingCraftProcess()
    end

    leftTrigger.enabled = enabledFn
    rightTrigger.enabled = enabledFn

    table.insert(descriptor, leftTrigger)
	table.insert(descriptor, rightTrigger)
end

-- Generic crafting header functions
function ZO_GamepadCraftingUtils_GetLineNameForCraftingType(craftingType)
    local skillType, skillIndex = GetCraftingSkillLineIndices(craftingType)
    local lineName, _ = GetSkillLineInfo(skillType, skillIndex)
    local text = zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, lineName)

    return text
end

function ZO_GamepadCraftingUtils_InitializeGenericHeader(craftingObject, createTabBar)
    craftingObject.header = craftingObject.control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(craftingObject.header, createTabBar)

    local function UpdateCapacity()
        if not craftingObject.control:IsHidden() then
            ZO_GamepadCraftingUtils_RefreshGenericHeader(craftingObject)
        end
    end
    
    craftingObject.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, UpdateCapacity)
    craftingObject.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, UpdateCapacity)
end

function ZO_GamepadCraftingUtils_SetupGenericHeader(craftingObject, titleString, tabBarEntries, showCapacity)
    if tabBarEntries and #tabBarEntries == 1 then
        local tabBarFirstEntry = tabBarEntries[1]
        if tabBarFirstEntry.text then
            titleString = tabBarFirstEntry.text
        end
        if tabBarFirstEntry.callback then
            tabBarFirstEntry:callback()
        end
    end

    local function GetCapacity()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    craftingObject.headerData = { }

    if showCapacity or showCapacity == nil then        
        craftingObject.headerData.data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY)
        craftingObject.headerData.data1Text = GetCapacity
    end

    if tabBarEntries and #tabBarEntries > 1 then 
        craftingObject.headerData.tabBarEntries = ZO_ShallowTableCopy(tabBarEntries)
        craftingObject.headerData.titleText = nil
    else
        craftingObject.headerData.tabBarEntries = nil
        craftingObject.headerData.titleText = titleString
    end
end

function ZO_GamepadCraftingUtils_SetGenericHeaderData2(craftingObject, headerText, text)
    craftingObject.headerData.data2HeaderText = headerText
    craftingObject.headerData.data2Text = text
end

function ZO_GamepadCraftingUtils_RefreshGenericHeader(craftingObject)
    ZO_GamepadGenericHeader_Refresh(craftingObject.header, craftingObject.headerData)
end

function ZO_GamepadCraftingUtils_RefreshGenericHeaderData(craftingObject)
    ZO_GamepadGenericHeader_RefreshData(craftingObject.header, craftingObject.headerData)
end

-- Crafting slot manipulation functions
-- Note: These amounts are scaled on both sides of the slot, so the slot will actually be scaled by twice the amount
local SELECTED_SLOT_X_SCALE_AMOUNT = 20
local SELECTED_SLOT_Y_SCALE_AMOUNT = 36

function ZO_GamepadCraftingUtils_ScaleSlotBackground(slot)
    if slot then
        local bg = slot:GetControl():GetNamedChild("Bg")
        local X_OFFSET_INDEX = 4
        local Y_OFFSET_INDEX = 5

        local _, point, relTo, relPoint, offsX, offsY = bg:GetAnchor(0)
        bg.savedAnchor1 = {point, relTo, relPoint, offsX, offsY}

        _, point, relTo, relPoint, offsX, offsY = bg:GetAnchor(1)
        bg.savedAnchor2 = {point, relTo, relPoint, offsX, offsY}

        bg:ClearAnchors()

        local newAnchor = ZO_Anchor:New(unpack(bg.savedAnchor1))
        newAnchor:SetOffsets(bg.savedAnchor1[X_OFFSET_INDEX] - SELECTED_SLOT_X_SCALE_AMOUNT, bg.savedAnchor1[Y_OFFSET_INDEX] - SELECTED_SLOT_Y_SCALE_AMOUNT)
        newAnchor:AddToControl(bg)

        newAnchor = ZO_Anchor:New(unpack(bg.savedAnchor2))
        newAnchor:SetOffsets(bg.savedAnchor2[X_OFFSET_INDEX] + SELECTED_SLOT_X_SCALE_AMOUNT, bg.savedAnchor2[Y_OFFSET_INDEX] + SELECTED_SLOT_Y_SCALE_AMOUNT)
        newAnchor:AddToControl(bg)
    end
end

function ZO_GamepadCraftingUtils_RestoreSlotBackground(slot)
    if slot then
        local bg = slot:GetControl():GetNamedChild("Bg")

	    bg:ClearAnchors()

	    local restoredAnchor = ZO_Anchor:New(unpack(bg.savedAnchor1))
	    restoredAnchor:AddToControl(bg)

        restoredAnchor = ZO_Anchor:New(unpack(bg.savedAnchor2))
	    restoredAnchor:AddToControl(bg)
    end
end

function ZO_GamepadCraftingUtils_PlaySlotBounceAnimation(slot)
    if slot then
        if not slot.control.bounceAnimation then
            slot.control.bounceAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_CraftingSlot_Gamepad_Bounce", slot.control)
        end

        slot.control.bounceAnimation:PlayFromStart()
    end
end

function ZO_GamepadCraftingUtils_SelectOptionFromOptionList(craftingObject)
    if craftingObject.optionList then
        local targetOptionData = craftingObject.optionList:GetTargetData()
        if targetOptionData then
            targetOptionData.currentValue = not targetOptionData.currentValue
            craftingObject:RefreshOptionList()
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
    end
end

function ZO_GamepadCraftingUtils_CraftingTooltip_StandardFloatingBottomScreenResizeHandler(control)
    local maxHeight = control:GetBottom() - ZO_GAMEPAD_FLOATING_SCROLL_SAFE_TOOLTIP_TOP_OFFSET
    control:SetDimensionConstraints(0, 0, 0, maxHeight)
end

function ZO_GamepadCraftingUtils_CraftingTooltip_StandardFloatingCenterScreenResizeHandler(control)
    local maxHeight = GuiRoot:GetHeight() - ZO_GAMEPAD_PANEL_FLOATING_HEIGHT_DISCOUNT - (ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_PADDING_Y * 2)
    control:SetDimensionConstraints(0, 0, 0, maxHeight)
end

function ZO_GamepadCraftingUtils_CraftingTooltip_Gamepad_Initialize(control, resizeHandler)
    local CRAFTING_TOOLTIP_OFFSET_X = -3
    ZO_ResizingFloatingScrollTooltip_Gamepad_OnInitialized(control, ZO_CRAFTING_TOOLTIP_STYLES, resizeHandler, RIGHT, CRAFTING_TOOLTIP_OFFSET_X)
end