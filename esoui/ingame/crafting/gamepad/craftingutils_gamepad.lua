-- Globals used by multiple crafting files
ZO_GAMEPAD_CRAFTING_UTILS_INGREDIENT_SLOT_AND_MARGIN_WIDTH = 231
ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_PADDING_Y = 50
ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_SLOT_STANDARD_HEIGHT = 190
ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET = ZO_GAMEPAD_QUADRANT_BOTTOM_OFFSET - ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_PADDING_Y

-- Note: call this towards the end of your keybind setup function...if you call this before you do something like self.keybindStripDescriptor = {keybinds} you'll destroy these
function ZO_GamepadCraftingUtils_AddGenericCraftingBackKeybindsToDescriptor(keybindDescriptor)
    if keybindDescriptor == nil then
        keybindDescriptor = {}
    end

    local genericStartButton = {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Crafting Default Exit",
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
    local craftingSkillLineData = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(craftingType)
    if craftingSkillLineData then
        return craftingSkillLineData:GetFormattedName()
    end
    return ""
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

do
    local GAMEPAD_SMITHING_FILTER_TO_ITEM_SLOT_TEXTURE =
    {
       [SMITHING_FILTER_TYPE_RAW_MATERIALS] = "EsoUI/Art/Crafting/Gamepad/gp_smithing_refine_emptySlot.dds",
       [SMITHING_FILTER_TYPE_WEAPONS] = "EsoUI/Art/Crafting/Gamepad/gp_smithing_weaponSlot.dds",
       [SMITHING_FILTER_TYPE_ARMOR] = "EsoUI/Art/Crafting/Gamepad/gp_smithing_apparelSlot.dds",
       [SMITHING_FILTER_TYPE_JEWELRY] = "EsoUI/Art/Crafting/Gamepad/gp_smithing_jewelrySlot.dds",
    }

    function ZO_GamepadCraftingUtils_GetItemSlotTextureFromSmithingFilter(smithingFilter)
        return GAMEPAD_SMITHING_FILTER_TO_ITEM_SLOT_TEXTURE[smithingFilter]
    end

    local GAMEPAD_SMITHING_DECONSTRUCTION_TYPE_TO_MULTIPLE_ITEMS_TEXTURE =
    {
       [SMITHING_DECONSTRUCTION_TYPE_RAW_MATERIALS] = "EsoUI/Art/Crafting/Gamepad/GP_smithing_refine_multiple_emptySlot.dds",
       [SMITHING_DECONSTRUCTION_TYPE_WEAPONS_AND_ARMOR] = "EsoUI/Art/Crafting/Gamepad/GP_smithing_multiple_armorWeaponSlot.dds",
       [SMITHING_DECONSTRUCTION_TYPE_ARMOR] = "EsoUI/Art/Crafting/Gamepad/GP_smithing_multiple_armorSlot.dds",
       [SMITHING_DECONSTRUCTION_TYPE_JEWELRY] = "EsoUI/Art/Crafting/Gamepad/GP_smithing_multiple_jewelrySlot.dds",
    }

    function ZO_GamepadCraftingUtils_GetMultipleItemsTextureFromSmithingDeconstructionType(deconstructionType)
        return internalassert(GAMEPAD_SMITHING_DECONSTRUCTION_TYPE_TO_MULTIPLE_ITEMS_TEXTURE[deconstructionType], "No multiple items texture for deconstruction type")
    end
end

do
    local function DisableSpinner(dialog)
        local selectedControl = dialog.entryList:GetSelectedControl()
        if selectedControl and selectedControl.spinner then
            selectedControl.spinner:SetActive(false)
        end
    end

    ESO_Dialogs["CRAFTING_CREATE_MULTIPLE_GAMEPAD"] =
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        blockDialogReleaseOnPress = true, -- Don't release on Max items pressed
        setup = function(dialog, data)
            data.maxIterations = data.craftingObject:GetMultiCraftMaxIterations()
            data.minIterations = 1
            data.numIterations = data.minIterations
            local headerData =
            {
                data1 =
                {
                    header = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
                    value = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK)),
                }
            }
            local NO_LIMIT_NUM_ENTRIES = nil
            dialog:setupFunc(NO_LIMIT_NUM_ENTRIES, headerData)
        end,
        finishedCallback = function(dialog)
            DisableSpinner(dialog)
        end,
        title =
        {
            text = GetString(SI_GAMEPAD_CRAFT_MULTIPLE),
        },
        mainText = 
        {
            text = GetString(SI_GAMEPAD_CRAFT_MULTIPLE_DESCRIPTION),
        },
        parametricList =
        {
            {
                template = "ZO_GamepadMultiCraftSpinnerTemplate",
                templateData = {
                    text = GetString(SI_GAMEPAD_QUANTITY_SPINNER_TEMPLATE_LABEL),
                    setup = function(control, entryData, selected, selectedDuringRebuild, enabled, active)
                        local dialogData = entryData.dialog.data
                        if control.spinner == nil then
                            control.spinner = ZO_Spinner_Gamepad:New(control:GetNamedChild("Spinner"), 1, 1, GAMEPAD_SPINNER_DIRECTION_HORIZONTAL)
                        end
                        control.spinner:SetActive(selected)
                        control.spinner:SetStep(1)
                        control.spinner:SetMinMax(dialogData.minIterations, dialogData.maxIterations)
                        control.spinner:SetValue(dialogData.numIterations)
                        control.spinner:UnregisterAllCallbacks("OnValueChanged")
                        control.spinner:RegisterCallback("OnValueChanged", function(value)
                            dialogData.numIterations = value
                            ZO_GenericGamepadDialog_RefreshKeybinds(entryData.dialog)
                        end)
                    end,
                },
            }
        },
        buttons =
        {
            -- Craft
            {
                text = SI_DIALOG_CONFIRM,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                    dialog.data.craftingObject:Create(dialog.data.numIterations)
                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialog.name)
                end,
            },
            -- Cancel
            {
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialog.name)
                end,
            },
            -- Min/Max Quantity
            {
                text = function(dialog)
                    if dialog.data.numIterations < dialog.data.maxIterations then
                        return GetString(SI_GAMEPAD_CRAFTING_QUANTITY_MAX)
                    else
                        return GetString(SI_GAMEPAD_CRAFTING_QUANTITY_MIN)
                    end
                end,
                keybind = "DIALOG_TERTIARY",
                callback = function(dialog)
                    if dialog.data.numIterations < dialog.data.maxIterations then
                        dialog.data.numIterations = dialog.data.maxIterations
                    else
                        dialog.data.numIterations = dialog.data.minIterations
                    end
                    ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(dialog)
                end,
            },
        }
    }

    function ZO_GamepadCraftingUtils_ShowMultiCraftDialog(craftingObject, resultItemLink)
        local nameColor = GetItemQualityColor(GetItemLinkQuality(resultItemLink))
        local itemName = nameColor:Colorize(GetItemLinkName(resultItemLink))

        ZO_Dialogs_ShowGamepadDialog("CRAFTING_CREATE_MULTIPLE_GAMEPAD", {craftingObject = craftingObject}, {mainTextParams={itemName}})
    end

    ESO_Dialogs["CRAFTING_DECONSTRUCT_PARTIAL_STACK_GAMEPAD"] =
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        blockDialogReleaseOnPress = true, -- Don't release on Max items pressed
        setup = function(dialog, data)
            data.minIterations = 1
            data.iterations = data.maxIterations
            local headerData =
            {
                data1 =
                {
                    header = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
                    value = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK)),
                }
            }
            local NO_LIMIT_NUM_ENTRIES = nil
            dialog:setupFunc(NO_LIMIT_NUM_ENTRIES, headerData)
        end,
        finishedCallback = function(dialog)
            DisableSpinner(dialog)
        end,
        title =
        {
            text = function(dialog)
                local bagId, slotIndex = dialog.data.bagId, dialog.data.slotIndex
                if CanItemBeRefined(bagId, slotIndex, GetCraftingInteractionType()) then
                    return GetString(SI_GAMEPAD_REFINE_MULTIPLE)
                else
                    return GetString(SI_GAMEPAD_DECONSTRUCT_MULTIPLE)
                end
            end,
        },
        mainText = 
        {
            text = function(dialog)
                local bagId, slotIndex = dialog.data.bagId, dialog.data.slotIndex
                if CanItemBeRefined(bagId, slotIndex, GetCraftingInteractionType()) then
                    return GetString(SI_GAMEPAD_REFINE_MULTIPLE_DESCRIPTION)
                else
                    return GetString(SI_GAMEPAD_DECONSTRUCT_MULTIPLE_DESCRIPTION)
                end
            end,
        },
        parametricList =
        {
            {
                template = "ZO_GamepadMultiDeconstructSpinnerTemplate",
                templateData = {
                    text = GetString(SI_GAMEPAD_QUANTITY_SPINNER_TEMPLATE_LABEL),
                    setup = function(control, entryData, selected, selectedDuringRebuild, enabled, active)
                        local dialogData = entryData.dialog.data
                        if control.spinner == nil then
                            control.spinner = ZO_Spinner_Gamepad:New(control:GetNamedChild("Spinner"), 1, 1, GAMEPAD_SPINNER_DIRECTION_HORIZONTAL)
                        end
                        control.spinner:SetActive(selected)
                        control.spinner:SetMinMax(dialogData.minIterations, dialogData.maxIterations)
                        control.spinner:SetValue(dialogData.iterations)
                        control.spinner:UnregisterAllCallbacks("OnValueChanged")
                        control.spinner:RegisterCallback("OnValueChanged", function(value)
                            dialogData.iterations = value
                            ZO_GenericGamepadDialog_RefreshKeybinds(entryData.dialog)
                        end)
                    end,
                },
            }
        },
        buttons =
        {
            -- Deconstruct
            {
                text = SI_DIALOG_CONFIRM,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                    dialog.data.deconstructFn(dialog.data.iterations)

                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialog.name)
                end,
            },
            -- Cancel
            {
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialog.name)
                end,
            },
            -- Max Quantity
            {
                text = function(dialog)
                    if dialog.data.iterations < dialog.data.maxIterations then
                        return GetString(SI_GAMEPAD_CRAFTING_QUANTITY_MAX)
                    else
                        return GetString(SI_GAMEPAD_CRAFTING_QUANTITY_MIN)
                    end
                end,
                keybind = "DIALOG_TERTIARY",
                callback = function(dialog)
                    if dialog.data.iterations < dialog.data.maxIterations then
                        dialog.data.iterations = dialog.data.maxIterations
                    else
                        dialog.data.iterations = dialog.data.minIterations
                    end
                    ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(dialog)
                end,
            },
        }
    }

    function ZO_GamepadCraftingUtils_ShowDeconstructPartialStackDialog(bagId, slotIndex, maxIterations, deconstructFn)
        local quality = GetItemQuality(bagId, slotIndex)
        local nameColor = GetItemQualityColor(quality)
        local itemName = nameColor:Colorize(GetItemName(bagId, slotIndex))

        ZO_Dialogs_ShowGamepadDialog("CRAFTING_DECONSTRUCT_PARTIAL_STACK_GAMEPAD", {bagId = bagId, slotIndex = slotIndex, maxIterations = maxIterations, deconstructFn = deconstructFn}, {mainTextParams = {itemName}})
    end
end

--[[ Gamepad Crafting Ingredient Bar ]]--
ZO_GamepadCraftingIngredientBar = ZO_Object:Subclass()

function ZO_GamepadCraftingIngredientBar:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadCraftingIngredientBar:Initialize(control)
    self.control = control

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
        local dataTypeInfo =
        {
            pool = ZO_ControlPool:New(templateName, self.slotCenterControl),
            setupFunction = setupFunction,
        }
        self.dataTypes[templateName] = dataTypeInfo
    end
end

function ZO_GamepadCraftingIngredientBar:AddEntry(templateName, data)
    local dataTypeInfo = self.dataTypes[templateName]
    if dataTypeInfo then
        table.insert(self.dataList, data)
        
        local control, key = dataTypeInfo.pool:AcquireObject()
        control.key = key
        control.templateName = templateName

        data.control = control

        dataTypeInfo.setupFunction(control, data)
    end
end

function ZO_GamepadCraftingIngredientBar:Commit()
    local numIngredients = #self.dataList  
    -- Start the leftmost slot at the width of all slots halved. This way the collection of slots will be visually centered
    local offsetX = (numIngredients - 1) * -ZO_GAMEPAD_CRAFTING_UTILS_INGREDIENT_SLOT_AND_MARGIN_WIDTH * 0.5

    for i, data in ipairs(self.dataList) do
        data.control:SetAnchor(CENTER, self.slotCenterControl, CENTER, offsetX, 0)
        -- Anchor the next slot to the right of this one
        offsetX = offsetX + ZO_GAMEPAD_CRAFTING_UTILS_INGREDIENT_SLOT_AND_MARGIN_WIDTH
    end
end

do
    local IS_SLOTTED_STATUS_ICON_OVERRIDE = {"EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"} -- check mark
    function ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, isSlotted)
        -- data should be used with ZO_SharedGamepadEntry_OnSetup
        if isSlotted then
            data.overrideStatusIndicatorIcons = IS_SLOTTED_STATUS_ICON_OVERRIDE
        else
            data.overrideStatusIndicatorIcons = nil
        end
    end
end
