local GAMEPAD_UNKNOWN_TRAIT_TEXTURE = "EsoUI/Art/Crafting/Gamepad/crafting_alchemy_trait_unknown.dds"

local INGREDIENT_SORT_ORDER_POTION = 0 
local INGREDIENT_SORT_ORDER_POISON = 1000000
local INGREDIENT_SORT_ORDER_OTHER  = 2000000

ZO_GamepadAlchemyReagentSlot = ZO_AlchemyReagentSlot:Subclass()

do
    -- purposely throwing out the nil passed in from SharedAlchemy as param 1, we don't need it and we're overriding it when we call it back
    function ZO_GamepadAlchemyReagentSlot:SetTraits(_, ...)
        ZO_AlchemyReagentSlot.SetTraits(self, GAMEPAD_UNKNOWN_TRAIT_TEXTURE, ...)
    end

    function ZO_GamepadAlchemyReagentSlot:ClearTraits()
        ZO_AlchemyReagentSlot.ClearTraits(self, GAMEPAD_UNKNOWN_TRAIT_TEXTURE)
    end
end

ZO_GamepadAlchemy = ZO_SharedAlchemy:Subclass()

function ZO_GamepadAlchemy:New(...)
    local alchemy = ZO_SharedAlchemy.New(self)
    alchemy:Initialize(...)
    return alchemy
end

function ZO_GamepadAlchemy:Initialize(control)
    ZO_SharedAlchemy.Initialize(self, control)
    
    local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(CRAFTING_TYPE_ALCHEMY)
    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    ZO_GamepadCraftingUtils_SetupGenericHeader(self, titleString)
    ZO_GamepadCraftingUtils_RefreshGenericHeader(self)

    self:InitializeKeybindStripDescriptors()
    self:InitializeModeList()
end

function ZO_GamepadAlchemy:InitializeScenes()
    local skillLineXPBarFragment = ZO_FadeSceneFragment:New(ZO_GamepadAlchemyTopLevelSkillInfo)
    GAMEPAD_ALCHEMY_ROOT_SCENE = self:CreateInteractScene("gamepad_alchemy_mode")
    GAMEPAD_ALCHEMY_ROOT_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_ALCHEMY_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.modeKeybindStripDescriptor)
            TriggerTutorial(TUTORIAL_TRIGGER_ALCHEMY_OPENED)
            self.modeList:Activate()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.modeKeybindStripDescriptor)
            self.modeList:Deactivate()
        end
    end)

    GAMEPAD_ALCHEMY_CREATION_SCENE = self:CreateInteractScene("gamepad_alchemy_creation")
    GAMEPAD_ALCHEMY_CREATION_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_ALCHEMY_CREATION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)
            self.inventory:Activate()
            self.inventory:OnShow()
            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(self.tooltip)
            GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.ALCHEMY_CREATE_TOOLTIP_GLOW_SUCCESS, SOUNDS.ALCHEMY_CREATE_TOOLTIP_GLOW_FAIL)
            self:UpdateTooltip()
        elseif newState == SCENE_HIDDEN then
            self.inventory:Deactivate()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            self.inventory:HandleDirtyEvent()
            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
            self.tooltip:SetHidden(true)
        end
    end)

    self.control:RegisterForEvent(EVENT_TRAIT_LEARNED, function()
        if SCENE_MANAGER:IsShowing("gamepad_alchemy_creation") then
            self:OnSlotChanged()
        end
    end)
end

function ZO_AlchemyCraftingBarSlotTemplateSetup(control, data)
    data.slot = ZO_GamepadAlchemyReagentSlot:New(data.owner, control, data.icon, data.placedSound, data.removedSound, nil, data.inventory, data.emptySlotIcon)
end

function ZO_AlchemyCraftingBarSolventSlotTemplateSetup(control, data)
    data.slot = ZO_GamepadAlchemyReagentSlot:New(data.owner, control, data.icon, data.placedSound, data.removedSound, nil, data.inventory, data.emptySlotIcon)
end

function ZO_GamepadAlchemy:InitializeSlots()

    local slotContainer = self.control:GetNamedChild("SlotContainer")
    self.craftingBar = ZO_GamepadCraftingIngredientBar:New(slotContainer, ZO_GAMEPAD_CRAFTING_UTILS_SLOT_SPACING)
    self.craftingBar:AddDataTemplate("ZO_GamepadAlchemyCraftingSlotWithTraits", ZO_AlchemyCraftingBarSlotTemplateSetup)
    self.craftingBar:AddDataTemplate("ZO_AlchemySolventSlot_Gamepad", ZO_AlchemyCraftingBarSolventSlotTemplateSetup)

    self.slotAnimation = ZO_CraftingCreateSlotAnimation:New("gamepad_alchemy_creation")

    self.control:RegisterForEvent(EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if nonCombatBonusType == NON_COMBAT_BONUS_ALCHEMY_THIRD_SLOT then
            self:UpdateThirdAlchemySlot()
        elseif nonCombatBonusType == NON_COMBAT_BONUS_ALCHEMY_LEVEL then
            self.inventory:HandleDirtyEvent()
        end
    end)

    self:UpdateThirdAlchemySlot()
end

function ZO_GamepadAlchemy:UpdateThirdAlchemySlot()

    self.craftingBar:Clear()
    local reagents = ZO_Alchemy_IsThirdAlchemySlotUnlocked() and 3 or 2
    local newData = {
        icon = "EsoUI/Art/Crafting/Gamepad/gp_alchemy_emptySlot_solvent.dds",
        placedSound = SOUNDS.ALCHEMY_SOLVENT_PLACED, 
        removedSound = SOUNDS.ALCHEMY_SOLVENT_REMOVED,
        inventory = self.inventory,
        owner = self,
        emptySlotIcon = "EsoUI/Art/Crafting/Gamepad/gp_alchemy_emptySlot_solvent.dds",
    }
    self.craftingBar:AddEntry("ZO_AlchemySolventSlot_Gamepad", newData)
    self.solventSlot = newData.slot

    self.reagentSlots = {}
    for i = 1, reagents
    do
        local newData = {
            icon = "EsoUI/Art/Crafting/Gamepad/gp_alchemy_emptySlot_reagent.dds",
            placedSound = SOUNDS.ALCHEMY_REAGENT_PLACED, 
            removedSound = SOUNDS.ALCHEMY_REAGENT_REMOVED,
            inventory = self.inventory,
            owner = self,
            emptySlotIcon = "EsoUI/Art/Crafting/Gamepad/gp_alchemy_emptySlot_reagent.dds",
        }
        self.craftingBar:AddEntry("ZO_GamepadAlchemyCraftingSlotWithTraits", newData)
        self.reagentSlots[i] = newData.slot
    end

    self.craftingBar:Commit()
end

function ZO_GamepadAlchemy:InitializeModeList()
    self.modeList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("ContainerMode"))
    self.modeList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)

    local data = ZO_GamepadEntryData:New(GetString(SI_ENCHANTING_CREATION), "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_create.dds")
    data.mode = ZO_ALCHEMY_MODE_CREATION
    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    
    local recipeCraftingSystem = GetTradeskillRecipeCraftingSystem(CRAFTING_TYPE_ALCHEMY)
    local recipeCraftingSystemName = GetString("SI_RECIPECRAFTINGSYSTEM", recipeCraftingSystem)
    data = ZO_GamepadEntryData:New(recipeCraftingSystemName, GetGamepadRecipeCraftingSystemMenuTextures(CRAFTING_TYPE_ALCHEMY))
    data.mode = ZO_ALCHEMY_MODE_RECIPES
    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", data)

    self.modeList:Commit()
end

function ZO_GamepadAlchemy:InitializeInventory()
    self.inventory = ZO_GamepadAlchemyInventory:New(self.control:GetNamedChild("ContainerInventory"), self)
   
    self.activeSlotIndex = 0

    self.inventory:SetOnTargetDataChangedCallback(function(list, selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)

        self:UpdateActiveSlot()
    end)

    -- Override the default parametric offset calculation
    self.inventory:GetList().CalculateParametricOffset = function(self, startAdditionalPadding, endAdditionalPadding, distanceFromCenter, continuousParametricOffset)
        local additionalPaddingEasingFunc

        -- Use linear easing during transition between rows with small and large padding.
        -- This helps minimize the perceived "bounce" effect during the transition as the extra space collapses.
        if startAdditionalPadding < endAdditionalPadding then
            additionalPaddingEasingFunc = ZO_LinearEase
        end

        return ZO_ParametricScrollList.CalculateParametricOffset(self, startAdditionalPadding, endAdditionalPadding, distanceFromCenter, continuousParametricOffset, additionalPaddingEasingFunc)
    end

    self.inventory:SetCustomExtraData(
        function(bagId, slotIndex, data)
            self:UpdateItemOnWorkbench(data)
        end
    )
end

function ZO_GamepadAlchemy:InitializeKeybindStripDescriptors()
    -- Mode keybind strip
    self.modeKeybindStripDescriptor =
    {
    }
    
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.modeKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:SelectMode() end)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.modeKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    -- Main keybind strip
    self.mainKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Add / remove
        {
            name = function()
                if self:IsSelectionOnWorkbench() then
                    return GetString(SI_ITEM_ACTION_REMOVE_FROM_CRAFT)
                else
                    return GetString(SI_ITEM_ACTION_ADD_TO_CRAFT)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self.inventory:GetTargetData() ~= nil
            end,
            enabled = function()
                return self.inventory:GetTargetData() ~= nil and self.inventory:GetTargetData().meetsUsageRequirement
            end,
            callback = function()
                local targetData = self.inventory:GetTargetData()
                local adding = not self:IsSelectionOnWorkbench()

                if adding then
                    self:AddItemToCraft(targetData.bagId, targetData.slotIndex)

                    local activeSlot = self:GetActiveSlot()

                    ZO_GamepadCraftingUtils_PlaySlotBounceAnimation(activeSlot)
                else
                    self:RemoveItemFromCraft(targetData.bagId, targetData.slotIndex)
                end

                self:OnWorkbenchUpdated()
            end,
        },

        -- Perform craft
        {
            name = function()
                local cost = GetCostToCraftAlchemyItem(self.solventSlot:GetBagAndSlot())
                return ZO_CraftingUtils_GetCostToCraftString(cost)
            end,
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                PlaySound(SOUNDS.GAMEPAD_ALCHEMY_BEGIN)
                self:Create()
            end,

            visible = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:IsCraftable() end,
        },

        -- Clear selections
        {
            name = GetString(SI_CRAFTING_CLEAR_SELECTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                self:ClearSelections()
                self:OnWorkbenchUpdated()
            end,

            visible = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:HasSelections() end,
        },
    }

    ZO_GamepadCraftingUtils_AddGenericCraftingBackKeybindsToDescriptor(self.mainKeybindStripDescriptor)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.mainKeybindStripDescriptor)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.mainKeybindStripDescriptor, self.inventory:GetList())
end

function ZO_GamepadAlchemy:SelectMode()
    local data = self.modeList:GetTargetData()

    if data then
        if data.mode == ZO_ALCHEMY_MODE_CREATION then
            SCENE_MANAGER:Push("gamepad_alchemy_creation")
        elseif data.mode == ZO_ALCHEMY_MODE_RECIPES then
            GAMEPAD_PROVISIONER:EmbedInCraftingScene(self.alchemyStationInteraction)
        end
    end
end

function ZO_GamepadAlchemy:InitializeTooltip()
    self.tooltip = self.control:GetNamedChild("Tooltip")
end

-- Checks whether the currently selected item has been added to the crafting workbench
function ZO_GamepadAlchemy:IsSelectionOnWorkbench()
    local selectedBagId, selectedSlotIndex = self.inventory:CurrentSelectionBagAndSlot()
    return self:IsItemOnWorkbench(selectedBagId, selectedSlotIndex)
end

-- Checks whether the specified item has been added to the crafting workbench
function ZO_GamepadAlchemy:IsItemOnWorkbench(selectedBagId, selectedSlotIndex)
    local function SlotHasSelection(slot)
        if slot:HasItem() then
            if slot:IsBagAndSlot(selectedBagId, selectedSlotIndex) then
                return true
            end
        end
        return false
    end

    for i, slot in ipairs(self.reagentSlots) do
        if SlotHasSelection(slot) then
            return true
        end
    end

    return SlotHasSelection(self.solventSlot)
end

function ZO_GamepadAlchemy:GetReagentSlotOffset(thirdSlotUnlocked)
    if thirdSlotUnlocked then
        return 120
    else
        return 60
    end
end

function ZO_GamepadAlchemy:OnWorkbenchUpdated()
    for _, data in pairs(self.inventory:GetList().dataList) do
        self:UpdateItemOnWorkbench(data)
    end

    self:UpdateActiveSlot()
    self.inventory:GetList():RefreshVisible()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_GamepadAlchemy:UpdateActiveSlot()
    local targetData = self.inventory:GetTargetData()
    if targetData then
        local oldActiveSlotIndex = self.activeSlotIndex
        local newActiveSlotIndex

        -- Determine which slot should be active
        local _, craftingSubItemType, _ = GetItemCraftingInfo(targetData.bagId, targetData.slotIndex)
        if IsAlchemySolvent(craftingSubItemType) or IsAlchemySolvent(targetData.itemType) then
            newActiveSlotIndex = 1
        elseif craftingSubItemType == ITEMTYPE_REAGENT or targetData.itemType == ITEMTYPE_REAGENT then
            local existingSlot = self:FindAlreadySlottedReagent(targetData.bagId, targetData.slotIndex)
            newActiveSlotIndex = (existingSlot or self:FindNextSlotToInsertReagent()) + 1
        else
            -- our target data is invalid...what happened?  This will die soon - asserting here to track the issue more easily
            assert(false)
        end

        local oldActiveSlot = self:GetSlot(oldActiveSlotIndex)
        local newActiveSlot = self:GetSlot(newActiveSlotIndex)

        -- Active slot has changed
        if oldActiveSlot ~= newActiveSlot then
            -- Remember which slot is active
            self.activeSlotIndex = newActiveSlotIndex
        end
    elseif self.activeSlotIndex > 0 then
        local oldActiveSlot = select(self.activeSlotIndex, self:GetAllSlots())
        if oldActiveSlot then
            oldActiveSlot.control.animation:PlayInstantlyToStart()
        end
    end
end

function ZO_GamepadAlchemy:UpdateItemOnWorkbench(data)
    data.isOnWorkbench = self:IsItemOnWorkbench(data.bagId, data.slotIndex)
    data.isEquippedInCurrentCategory = data.isOnWorkbench
end

function ZO_GamepadAlchemy:UpdateTooltip()
    if self:IsCraftable() then
        self.tooltip:SetHidden(false)
        self.tooltip.tip:ClearLines()
        self:UpdateTooltipLayout()
    else
        self.tooltip:SetHidden(true)
    end
end

function ZO_GamepadAlchemy:UpdateTooltipLayout()
    self.tooltip.tip:LayoutAlchemyPreview(self:GetAllCraftingBagAndSlots())
end

function ZO_GamepadAlchemy:GetAllSlots()
    local SOLVENT_SLOT = 1
    local FIRST_REAGENT_SLOT = 2
    local SECOND_REAGENT_SLOT = 3
    local THIRD_REAGENT_SLOT = 4

    return self:GetSlot(SOLVENT_SLOT), self:GetSlot(FIRST_REAGENT_SLOT), self:GetSlot(SECOND_REAGENT_SLOT), self:GetSlot(THIRD_REAGENT_SLOT)
end

function ZO_GamepadAlchemy:GetSlot(index)
    if index == 1 then
        return self.solventSlot
    else
        return self.reagentSlots[index - 1]
    end
end

function ZO_GamepadAlchemy:GetActiveSlot()
    return self:GetSlot(self.activeSlotIndex)
end

ZO_GamepadAlchemyInventory = ZO_GamepadCraftingInventory:Subclass()

function ZO_GamepadAlchemyInventory:New(control, owner,...)
    return ZO_GamepadCraftingInventory.New(self, owner, control, ...)
end

function ZO_GamepadAlchemyInventory:Initialize(owner, control, ...)
    ZO_GamepadCraftingInventory.Initialize(self, control, ...)

    self.owner = owner
    self.filterType = NO_FILTER

    self.list:SetNoItemText(GetString(SI_ALCHEMY_NO_SOLVENTS_OR_REAGENTS))

    self:SetCustomSort(function(bagId, slotIndex)
        local _, craftingSubItemType, _, requiredLevel, requiredChampionPoints = GetItemCraftingInfo(bagId, slotIndex)
        local subSortOrder = (requiredChampionPoints and requiredLevel + requiredChampionPoints or requiredLevel or 0)

        if craftingSubItemType == ITEMTYPE_POTION_BASE then
            return INGREDIENT_SORT_ORDER_POTION + subSortOrder
        elseif craftingSubItemType == ITEMTYPE_POISON_BASE then
            return INGREDIENT_SORT_ORDER_POISON + subSortOrder
        else
            return INGREDIENT_SORT_ORDER_OTHER + subSortOrder
        end
    end)
end

function ZO_GamepadAlchemyInventory:GetList()
    return self.list
end

function ZO_GamepadAlchemyInventory:IsLocked(bagId, slotIndex)
    return ZO_GamepadCraftingInventory.IsLocked(self, bagId, slotIndex) or self.owner:IsSlotted(bagId, slotIndex)
end

function ZO_GamepadAlchemyInventory:AddListDataTypes()
    local function SetupSolventListEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

        local descriptionLabel = control.descriptionLabel
        descriptionLabel:SetHidden(not selected)

        if selected then
            local usedInCraftingType, craftingSubItemType, tradeskillRankRequirement, resultingItemLevel, requiredChampionPoints = GetItemCraftingInfo(data.bagId, data.slotIndex)

            if not tradeskillRankRequirement or tradeskillRankRequirement <= GetNonCombatBonus(NON_COMBAT_BONUS_ALCHEMY_LEVEL) then
                local descriptionText
                local itemTypeString = GetString((craftingSubItemType == ITEMTYPE_POTION_BASE) and SI_ITEM_FORMAT_STR_POTION or SI_ITEM_FORMAT_STR_POISON)

                if requiredChampionPoints and requiredChampionPoints > 0 then
                    descriptionText = zo_strformat(SI_ALCHEMY_CREATES_ITEM_OF_CHAMPION_POINTS, requiredChampionPoints, itemTypeString)
                else
                    descriptionText = zo_strformat(SI_ALCHEMY_CREATES_ITEM_OF_LEVEL, resultingItemLevel, itemTypeString)
                end

                descriptionLabel:SetText(descriptionText)
                descriptionLabel:SetColor(1, 1, 1, 1)
            else
                descriptionLabel:SetText(zo_strformat(SI_REQUIRES_ALCHEMY_SOLVENT_PURIFICATION, tradeskillRankRequirement))
                descriptionLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
            end
        else
            descriptionLabel:SetText(nil)
        end
    end

    local function SetupTrait(traits, locked, isOnWorkbench, ...)
        local numTraits = select("#", ...) / ALCHEMY_TRAIT_STRIDE
        for i, traitControl in ipairs(traits) do
            if i > numTraits then
                traitControl:SetHidden(true)
            else
                traitControl:SetHidden(false)

                local label = traitControl.label
                local iconControl = traitControl.icon or traitControl  -- For unlabeled trait controls, the control is the icon

                local traitName, traitIcon, traitMatchIcon, _, traitConflictIcon = ZO_Alchemy_GetTraitInfo(i, ...)
                if traitName then
                    if label then
                        label:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_ACCENT))
                        label:SetText(traitName)
                    end

                   GAMEPAD_ALCHEMY:SetupTraitIcon(iconControl, traitName, traitIcon, traitMatchIcon, traitConflictIcon, GAMEPAD_UNKNOWN_TRAIT_TEXTURE)
                else
                    if label then
                        label:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_INACTIVE_BONUS))
                        label:SetText(GetString(SI_CRAFTING_UNKNOWN_NAME))
                    end

                    iconControl:SetTexture(GAMEPAD_UNKNOWN_TRAIT_TEXTURE)
                end

                if label then
                    ZO_ItemSlot_SetupTextUsableAndLockedColor(label, true, false)
                end
            end
        end
    end

    local function SetupReagentListEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

        control.selectedItems:SetHidden(not selected)

        local locked = self:IsLocked(data.bagId, data.slotIndex)
        local isOnWorkbench = data.isOnWorkbench

        if selected then
            SetupTrait(control.selectedItems.traits, locked, isOnWorkbench, GetAlchemyItemTraits(data.bagId, data.slotIndex))
        end

        SetupTrait(control.unselectedItems.traits, locked, isOnWorkbench, GetAlchemyItemTraits(data.bagId, data.slotIndex))
    end

    self.list:AddDataTemplate("ZO_GamepadAlchemyInventorySolventRow", SetupSolventListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.list:AddDataTemplate("ZO_GamepadAlchemyInventoryReagentRow", SetupReagentListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction)    
    self.list:AddDataTemplateWithHeader("ZO_GamepadAlchemyInventorySolventRow", SetupSolventListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    self.list:AddDataTemplateWithHeader("ZO_GamepadAlchemyInventoryReagentRow", SetupReagentListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GamepadAlchemyInventory:GetListEntryTemplate(data)
    local _, craftingSubItemType = GetItemCraftingInfo(data.bagId, data.slotIndex)
    if IsAlchemySolvent(craftingSubItemType) then
        return data.header and "ZO_GamepadAlchemyInventorySolventRowWithHeader" or "ZO_GamepadAlchemyInventorySolventRow"
    elseif craftingSubItemType == ITEMTYPE_REAGENT then
        return data.header and "ZO_GamepadAlchemyInventoryReagentRowWithHeader" or "ZO_GamepadAlchemyInventoryReagentRow"
    end
end

function ZO_GamepadAlchemyInventory:Refresh(data)
    local validItemIds = self:EnumerateInventorySlotsAndAddToScrollData(ZO_Alchemy_IsAlchemyItem, ZO_Alchemy_DoesAlchemyItemPassFilter, self.filterType, data)
    self.owner:OnInventoryUpdate(validItemIds)

    ZO_GamepadCraftingUtils_RefreshGenericHeader(self.owner)
end

function ZO_GamepadAlchemyInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    local _, craftingSubItemType, requiredChampionPoints = GetItemCraftingInfo(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts(craftingSubItemType, requiredChampionPoints)
end

function ZO_GamepadAlchemyInventory:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end

function ZO_GamepadAlchemyInventory:SetAlignToScreenCenter(alignToScreenCenter, expectedEntryHeight)
    self.list:SetAlignToScreenCenter(alignToScreenCenter, expectedEntryHeight)
end

function ZO_GamepadAlchemyInventory:GetControl()
    return self.list:GetControl()
end

function ZO_GamepadAlchemyInventory:IsActive()
    return self.list:IsActive()
end

function ZO_GamepadAlchemyInventory:GetTargetData()
    return self.list:GetTargetData()
end

function ZO_GamepadAlchemyInventory:SetOnTargetDataChangedCallback(selectedDataCallback)
    self.list:SetOnTargetDataChangedCallback(selectedDataCallback)
end

function ZO_GamepadAlchemy_OnInitialized(control)
    GAMEPAD_ALCHEMY = ZO_GamepadAlchemy:New(control)
end
