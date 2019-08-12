ZO_GamepadEnchanting = ZO_SharedEnchanting:Subclass()

function ZO_GamepadEnchanting:New(...)
    return ZO_SharedEnchanting.New(self, ...)
end

function ZO_GamepadEnchanting:Initialize(control)
    self.slotCreationAnimationName = "gamepad_enchanting_creation"
    self.mainSceneName = "gamepad_enchanting_mode"

    self.containerControl = control:GetNamedChild("Container")

    self.modeList = ZO_GamepadVerticalItemParametricScrollList:New(self.containerControl:GetNamedChild("Mode"))
    self.modeList:SetAlignToScreenCenter(true)
    self.modeList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
    self:InitializeModes()

    ZO_SharedEnchanting.Initialize(self, control)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        if SCENE_MANAGER:IsShowing("gamepad_enchanting_creation") or SCENE_MANAGER:IsShowing("gamepad_enchanting_extraction") then
            self.inventory:Deactivate()
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function() 
        if SCENE_MANAGER:IsShowing("gamepad_enchanting_creation") or SCENE_MANAGER:IsShowing("gamepad_enchanting_extraction") then
            self.inventory:Activate()
            self:UpdateSelection()
        end
    end)

    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
end

function ZO_GamepadEnchanting:InitializeModes()
    self.modeList:Clear()
    local data = ZO_GamepadEntryData:New(GetString(SI_ENCHANTING_CREATION), "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_create.dds")
    data.mode = ENCHANTING_MODE_CREATION
    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    
    data = ZO_GamepadEntryData:New(GetString(SI_ENCHANTING_EXTRACTION), "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_deconstruct.dds")
    data.mode = ENCHANTING_MODE_EXTRACTION
    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", data)

    local recipeCraftingSystem = GetTradeskillRecipeCraftingSystem(CRAFTING_TYPE_ENCHANTING)
    local recipeCraftingSystemName = GetString("SI_RECIPECRAFTINGSYSTEM", recipeCraftingSystem)
    data = ZO_GamepadEntryData:New(recipeCraftingSystemName, GetGamepadRecipeCraftingSystemMenuTextures(CRAFTING_TYPE_ENCHANTING))
    data.mode = ENCHANTING_MODE_RECIPES
    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", data)

    self.modeList:Commit()
end

local GAMEPAD_CRAFTING_ENCHANTING_ITEM_SORT =
{
    customSortData = { tiebreaker = "bestItemCategoryName" },
    bestItemCategoryName = { tiebreaker = "text" },
    text = {},
}

function ZO_GamepadEnchanting:InitializeInventory()
    local inventory = self.containerControl:GetNamedChild("Inventory")

    self.inventory = ZO_GamepadEnchantingInventory:New(self, inventory)

    self.inventory:SetCustomExtraData(function(bagId, slotIndex, data)
            if self.enchantingMode == ENCHANTING_MODE_CREATION then
                local itemName = GetItemName(bagId, slotIndex)
                local itemLink = GetItemLink(bagId, slotIndex)
                local known, name = GetItemLinkEnchantingRuneName(itemLink)
                local _, _, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
                
                data.meetsUsageRequirement = DoesRunePassRequirements(runeType, rankRequirement, rarityRequirement)
                local requirementString = ""
                if known == true then
                    data.name = zo_strformat(SI_GAMEPAD_ENCHANTING_TRANSLATION_KNOWN, itemName, name)
                else
                    data.name = zo_strformat(SI_GAMEPAD_ENCHANTING_TRANSLATION_KNOWN, itemName, GetString(SI_ENCHANTING_TRANSLATION_UNKNOWN))
                end

                local traitSubLabel = name and zo_strformat(name) or zo_strformat(GetString(SI_ENCHANTING_TRANSLATION_UNKNOWN))
                data:AddSubLabel(traitSubLabel)

                if runeType == ENCHANTING_RUNE_POTENCY then
                    requirementString = zo_strformat(SI_ENCHANTING_REQUIRES_POTENCY_IMPROVEMENT, rankRequirement)
                elseif runeType == ENCHANTING_RUNE_ASPECT then
                    requirementString = zo_strformat(SI_ENCHANTING_REQUIRES_ASPECT_IMPROVEMENT, rarityRequirement)
                end

                if(requirementString ~= "") then
                    if data.meetsUsageRequirement then
                        data:AddSubLabel(ZO_SUCCEEDED_TEXT:Colorize(requirementString))
                    else
                        data:AddSubLabel(ZO_ERROR_COLOR:Colorize(requirementString))
                    end
                end
            end
        end
    )

    self.inventory:SetCustomSort(function(bagId, slotIndex)
            local itemType = GetItemType(bagId, slotIndex)
            if self.enchantingMode == ENCHANTING_MODE_CREATION then
                if itemType == ITEMTYPE_ENCHANTING_RUNE_POTENCY then
                    return 0
                elseif itemType == ITEMTYPE_ENCHANTING_RUNE_ESSENCE then
                    return 1
                else
                    return 2
                end
            else
                return itemType
            end
        end
    )

    self.inventory:SetOverrideItemSort(function(left, right)
        return ZO_TableOrderingFunction(left, right, "customSortData", GAMEPAD_CRAFTING_ENCHANTING_ITEM_SORT, ZO_SORT_ORDER_UP)
    end)
end

function ZO_GamepadEnchanting:InitializeEnchantingScenes()
    ZO_SharedEnchanting.InitializeEnchantingScenes(self)

    self.enchantingStationInteraction =
    {
        type = "Enchanting Station",
        End = function()
            SCENE_MANAGER:ShowBaseScene()
        end,
        interactTypes = { INTERACTION_CRAFT },
    }

    local skillLineXPBarFragment = ZO_FadeSceneFragment:New(ZO_GamepadEnchantingTopLevelSkillInfo)

    GAMEPAD_ENCHANTING_MODE_SCENE_ROOT = ZO_InteractScene:New(self.mainSceneName, SCENE_MANAGER, self.enchantingStationInteraction)
    GAMEPAD_ENCHANTING_MODE_SCENE_ROOT:AddFragment(skillLineXPBarFragment)
    GAMEPAD_ENCHANTING_MODE_SCENE_ROOT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindModeStripDescriptor)
            self:SetEnchantingMode(ENCHANTING_MODE_NONE)
            self.modeList:Activate()

            local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(CRAFTING_TYPE_ENCHANTING)
            ZO_GamepadCraftingUtils_SetupGenericHeader(self, titleString)
            ZO_GamepadCraftingUtils_RefreshGenericHeader(self)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindModeStripDescriptor)
            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
            self.modeList:Deactivate()
            if self.enchantingMode ~= ENCHANTING_MODE_NONE then
                self.inventory:Deactivate()
            end
        end
    end)

    self.onSelectedDataChangedCallback = function(list, selectedData)
        self:DataSelectionCallback(list, selectedData) 
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindEnchantingStripDescriptor) 
    end

    local function ShowCraftingScene(mode, containerToShow)
        KEYBIND_STRIP:RemoveDefaultExit()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindEnchantingStripDescriptor)
        self:SetEnchantingMode(mode)
        containerToShow:SetHidden(false)
        self.inventory.list:SetOnSelectedDataChangedCallback(self.onSelectedDataChangedCallback)
        self.inventory:Activate()
        self:DataSelectionCallback(self.inventory:CurrentSelectionBagAndSlot())
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindEnchantingStripDescriptor)
    end

    local function HideCraftingScene()
        self.inventory.list:RemoveOnSelectedDataChangedCallback(self.onSelectedDataChangedCallback)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindEnchantingStripDescriptor)
        KEYBIND_STRIP:RestoreDefaultExit()
        self.inventory:Deactivate()
        GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
    end

    GAMEPAD_ENCHANTING_CREATION_SCENE = ZO_InteractScene:New("gamepad_enchanting_creation", SCENE_MANAGER, self.enchantingStationInteraction)
    GAMEPAD_ENCHANTING_CREATION_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_ENCHANTING_CREATION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            ShowCraftingScene(ENCHANTING_MODE_CREATION, self.runeSlotContainer)
        elseif newState == SCENE_HIDDEN then
            HideCraftingScene()
            self.runeSlotContainer:SetHidden(true)
            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
        end
    end)

    GAMEPAD_ENCHANTING_EXTRACTION_SCENE = ZO_InteractScene:New("gamepad_enchanting_extraction", SCENE_MANAGER, self.enchantingStationInteraction)
    GAMEPAD_ENCHANTING_EXTRACTION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
    GAMEPAD_ENCHANTING_EXTRACTION_SCENE:AddFragment(skillLineXPBarFragment)
        if newState == SCENE_SHOWING then
            ShowCraftingScene(ENCHANTING_MODE_EXTRACTION, self.extractionSlotContainer)
        elseif newState == SCENE_HIDDEN then
            HideCraftingScene()
            self.extractionSlotContainer:SetHidden(true)
        end
    end)
end

function ZO_GamepadEnchanting:InitializeCreationSlots()
    self.runeSlotContainer = self.control:GetNamedChild("RuneSlotContainer")

    self.creationCraftingBar = ZO_GamepadCraftingIngredientBar:New(self.runeSlotContainer)
    self.creationCraftingBar:AddDataTemplate("ZO_GamepadEnchantingRuneCraftingSlot", ZO_GamepadEnchantingRuneCraftingSlotTemplateSetup)

    self.creationCraftingBar:Clear()

    self.runeSlots = {}

    local potencyData = {
        owner = self,
        slotIcon = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone01_slot.dds",
        slotIconDrag = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone01_drag.dds",
        slotIconNegative = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone01_negative.dds",
        soundPlaced = SOUNDS.ENCHANTING_POTENCY_RUNE_PLACED,
        soundRemoved = SOUNDS.ENCHANTING_POTENCY_RUNE_REMOVED,
        type = ENCHANTING_RUNE_POTENCY,
        inventory = self.inventory,
        emptySlotIcon = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone01_slot.dds",
    }

    self.creationCraftingBar:AddEntry("ZO_GamepadEnchantingRuneCraftingSlot", potencyData)
    self.runeSlots[ENCHANTING_RUNE_POTENCY] = potencyData.slot

    local essenceData = {
        owner = self,
        slotIcon = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone02_slot.dds",
        slotIconDrag = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone02_drag.dds",
        slotIconNegative = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone02_negative.dds",
        soundPlaced = SOUNDS.ENCHANTING_ESSENCE_RUNE_PLACED,
        soundRemoved = SOUNDS.ENCHANTING_ESSENCE_RUNE_REMOVED,
        type = ENCHANTING_RUNE_ESSENCE,
        inventory = self.inventory,
        emptySlotIcon = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone02_slot.dds",
    }
    self.creationCraftingBar:AddEntry("ZO_GamepadEnchantingRuneCraftingSlot", essenceData)
    self.runeSlots[ENCHANTING_RUNE_ESSENCE] = essenceData.slot

    local aspectData = {
        owner = self,
        slotIcon = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone03_slot.dds",
        slotIconDrag = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone03_drag.dds",
        slotIconNegative = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone03_negative.dds",
        soundPlaced = SOUNDS.ENCHANTING_ASPECT_RUNE_PLACED,
        soundRemoved = SOUNDS.ENCHANTING_ASPECT_RUNE_REMOVED,
        type = ENCHANTING_RUNE_ASPECT,
        inventory = self.inventory,
        emptySlotIcon = "EsoUI/Art/Crafting/Gamepad/gp_crafting_runestone03_slot.dds",
    }
    self.creationCraftingBar:AddEntry("ZO_GamepadEnchantingRuneCraftingSlot", aspectData)
    self.runeSlots[ENCHANTING_RUNE_ASPECT] = aspectData.slot

    self.control:RegisterForEvent(EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if nonCombatBonusType == NON_COMBAT_BONUS_ENCHANTING_LEVEL or nonCombatBonusType == NON_COMBAT_BONUS_ENCHANTING_RARITY_LEVEL then
            self.inventory:HandleDirtyEvent()
        elseif nonCombatBonusType == NON_COMBAT_BONUS_ENCHANTING_CRAFT_PERCENT_DISCOUNT then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)

    self.resultTooltip = self.control:GetNamedChild("Tooltip")

    self.creationSlotAnimation = ZO_SharedEnchantingSlotAnimation:New(self.slotCreationAnimationName, function() return self.enchantingMode == ENCHANTING_MODE_CREATION end)
    self.creationSlotAnimation:AddSlot(self.runeSlots[ENCHANTING_RUNE_POTENCY])
    self.creationSlotAnimation:AddSlot(self.runeSlots[ENCHANTING_RUNE_ESSENCE])
    self.creationSlotAnimation:AddSlot(self.runeSlots[ENCHANTING_RUNE_ASPECT])

    self.creationCraftingBar:Commit()

    self.activeSlot = -1
end

function ZO_GamepadEnchanting:DataSelectionCallback(list, selectedData) 
    local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
    local _, _, runeType, _, _ = GetItemCraftingInfo(bagId, slotIndex)
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        if self.activeSlot ~= runeType then
            if self.activeSlot > 0 then
                local slot = self.runeSlots[self.activeSlot]
            end
            if runeType ~= nil then
                self.activeSlot = runeType
            else
                self.activeSlot = -1
            end
        end
    elseif self.enchantingMode == ENCHANTING_MODE_EXTRACTION then
        if self.activeSlot > 0 then
            local slot = self.runeSlots[self.activeSlot]
            slot.control.animation:PlayBackward()
            self.activeSlot = -1
        end
    end
end

function ZO_GamepadEnchantingRuneCraftingSlotTemplateSetup(control, data)
    data.slot = ZO_SharedEnchantRuneSlot:New(data.owner, control, data.slotIcon, data.slotIconDrag, data.slotIconNegative, data.soundPlaced, data.soundRemoved, data.type, data.inventory, data.emptySlotIcon)
    data.slot:RegisterCallback("ItemsChanged", function()
        data.owner:OnSlotChanged()
    end)
end

function ZO_GamepadEnchantingRuneExtractionSlotTemplateSetup(control, data)
    local MULTIPLE_ITEMS_TEXTURE = "EsoUI/Art/Crafting/Gamepad/GP_smithing_multiple_enchantingSlot.dds"
    data.slot = ZO_EnchantExtractionSlot_Gamepad:New(data.owner, control, MULTIPLE_ITEMS_TEXTURE, data.inventory)
    data.slot:RegisterCallback("ItemsChanged", function()
        data.owner:OnSlotChanged()
    end)
end

function ZO_GamepadEnchanting:InitializeExtractionSlots()
    self.extractionSlotContainer = self.control:GetNamedChild("ExtractionSlotContainer")

    self.extractionCraftingBar = ZO_GamepadCraftingIngredientBar:New(self.extractionSlotContainer)
    self.extractionCraftingBar:AddDataTemplate("ZO_GamepadEnchantingRuneExtractionSlot", ZO_GamepadEnchantingRuneExtractionSlotTemplateSetup)

    self.slotAnimation = ZO_CraftingCreateSlotAnimation:New(self.sceneName)

    self.extractionCraftingBar:Clear()

    local newData = {
        inventory = self.inventory,
        owner = self,
    }
    self.extractionCraftingBar:AddEntry("ZO_GamepadEnchantingRuneExtractionSlot", newData)
    self.extractionSlot = newData.slot

    self.extractionSlotAnimation = ZO_CraftingEnchantExtractSlotAnimation_Gamepad:New("gamepad_enchanting_extraction", function() return self.enchantingMode == ENCHANTING_MODE_EXTRACTION end)
    self.extractionSlotAnimation:AddSlot(self.extractionSlot)

    self.extractionCraftingBar:Commit()
end

function ZO_GamepadEnchanting:InitializeKeybindStripDescriptors()
    self.keybindModeStripDescriptor = {}

    self.keybindEnchantingStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Slot/Unslot
        {
            name = function()
                self:UpdateExtractionSlotTexture()
                if self:IsCurrentSelected() then
                    return GetString(SI_ITEM_ACTION_REMOVE_FROM_CRAFT)
                else
                    return GetString(SI_ITEM_ACTION_ADD_TO_CRAFT)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function() 
                if self:IsCurrentSelected() then
                    self:Remove()
                else
                    self:Select()
                end

                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindEnchantingStripDescriptor)
            end,
            enabled = function() 
                if ZO_CraftingUtils_IsPerformingCraftProcess() then
                    return false
                end
                local selectedData = self.inventory:CurrentSelection() 
                local canSlotItem = selectedData and selectedData.meetsUsageRequirement
                return canSlotItem
            end,
        },

        -- Craft/Deconstruct
        {
            name = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    local cost = GetCostToCraftEnchantingItem(self:GetAllCraftingBagAndSlots())
                    return ZO_CraftingUtils_GetCostToCraftString(cost)
                else
                    return GetString(SI_CRAFTING_PERFORM_EXTRACTION)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            gamepadOrder = 1000,
            callback = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    self:Create(1)
                else
                    self:ExtractSingle()
                end
            end,
            enabled = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    return self:ShouldCraftButtonBeEnabled()
                else
                    return self:ShouldDeconstructButtonBeEnabled() and self.extractionSlot:HasOneItem()
                end
            end,
        },

        -- Craft/Deconstruct multiple
        {
            name = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    return GetString(SI_GAMEPAD_CRAFT_MULTIPLE)
                else
                    return GetString(SI_CRAFTING_EXTRACT_MULTIPLE)
                end
            end,
            keybind = "UI_SHORTCUT_QUATERNARY",
            gamepadOrder = 1010,
            callback = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    local itemLink = GetEnchantingResultingItemLink(self:GetAllCraftingBagAndSlots())
                    ZO_GamepadCraftingUtils_ShowMultiCraftDialog(self, itemLink)
                else
                    if self.extractionSlot:HasOneItem() then
                        -- This is one virtual slot, but because enchanting glyphs do not stack it represents multiple real slots
                        -- Limit the max quantity to match the max number of real slots
                        local virtualBagId, virtualSlotIndex = self.extractionSlot:GetItemBagAndSlot(1)
                        local maxIterations = zo_min(self.inventory:GetStackCount(virtualBagId, virtualSlotIndex), MAX_ITEM_SLOTS_PER_DECONSTRUCTION)
                        local function PerformDeconstructPartial(iterations)
                            self:ExtractPartialStack(iterations)
                        end

                        ZO_GamepadCraftingUtils_ShowDeconstructPartialStackDialog(virtualBagId, virtualSlotIndex, maxIterations, PerformDeconstructPartial)
                    else
                        self:ConfirmExtractAll()
                    end
                end
            end,
            enabled = function()
                if self.enchantingMode == ENCHANTING_MODE_CREATION then
                    return self:ShouldMultiCraftButtonBeEnabled()
                else
                    return self:ShouldDeconstructButtonBeEnabled() and self.extractionSlot:GetStackCount() > 1
                end
            end,
        },

        -- Clear selections
        {
            name = GetString(SI_CRAFTING_CLEAR_SELECTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            gamepadOrder = 1020,
            callback = function()
                self:ClearSelections()
                self:UpdateSelection()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindEnchantingStripDescriptor)
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            enabled = function()
                return self:HasSelections()
            end,
        },
    }

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindModeStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:SelectMode() end)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindModeStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindEnchantingStripDescriptor)

    ZO_GamepadCraftingUtils_AddGenericCraftingBackKeybindsToDescriptor(self.keybindEnchantingStripDescriptor)
    ZO_GamepadCraftingUtils_AddListTriggerKeybindDescriptors(self.keybindEnchantingStripDescriptor, self.inventory.list)
end

function ZO_GamepadEnchanting:UpdateExtractionSlotTexture()
    if self.enchantingMode == ENCHANTING_MODE_EXTRACTION and not self.extractionSlot:HasItems() then
        local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
        self.extractionSlot:SetBackdrop(bagId, slotIndex)
    end
end

function ZO_GamepadEnchanting:SelectMode()
    local data = self.modeList:GetTargetData()

    if data then
        if data.mode == ENCHANTING_MODE_EXTRACTION then
            SCENE_MANAGER:Push("gamepad_enchanting_extraction")
        elseif data.mode == ENCHANTING_MODE_CREATION then
            SCENE_MANAGER:Push("gamepad_enchanting_creation")
        elseif data.mode == ENCHANTING_MODE_RECIPES then
            GAMEPAD_PROVISIONER:EmbedInCraftingScene(self.enchantingStationInteraction)
        end
    end
end

function ZO_GamepadEnchanting:CanShowScene()
    return IsInGamepadPreferredMode()
end

function ZO_GamepadEnchanting:IsSceneShowing()
    return SCENE_MANAGER:IsShowing(self.mainSceneName) or SCENE_MANAGER:IsShowing("gamepad_enchanting_creation") or SCENE_MANAGER:IsShowing("gamepad_enchanting_extraction")
end

function ZO_GamepadEnchanting:SetEnchantingMode(enchantingMode)
    if self.enchantingMode ~= enchantingMode then

        self.enchantingMode = enchantingMode

        if enchantingMode == ENCHANTING_MODE_CREATION then
            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
            self.inventory:SetNoItemLabelText(GetString(SI_ENCHANTING_NO_RUNES))

            GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.ENCHANTING_CREATE_TOOLTIP_GLOW)

            TriggerTutorial(TUTORIAL_TRIGGER_ENCHANTING_CREATION_OPENED)
        elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
            self.inventory:SetNoItemLabelText(GetString(SI_ENCHANTING_NO_GLYPHS))
            self:ClearSelections()

            TriggerTutorial(TUTORIAL_TRIGGER_ENCHANTING_EXTRACTION_OPENED)
        end

        self.inventory:HandleDirtyEvent()

        ClearCursor()
        self:OnSlotChanged()

        self:UpdateSelection()
    end
end

function ZO_GamepadEnchanting:UpdateSelection()
    if self.enchantingMode == ENCHANTING_MODE_CREATION then
        local rune1BagId, rune1SlotIndex, rune2BagId, rune2SlotIndex, rune3BagId, rune3SlotIndex = self:GetAllCraftingBagAndSlots()
        for _, data in pairs(self.inventory.list.dataList) do
            local isSlotted = false
            if data.bagId == rune1BagId and data.slotIndex == rune1SlotIndex then
                isSlotted = true
            elseif data.bagId == rune2BagId and data.slotIndex == rune2SlotIndex then
                isSlotted = true
            elseif data.bagId == rune3BagId and data.slotIndex == rune3SlotIndex then
                isSlotted = true
            end
            ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, isSlotted)
        end
    else
        for _, data in pairs(self.inventory.list.dataList) do
            ZO_GamepadCraftingUtils_SetEntryDataSlotted(data, self.extractionSlot:ContainsBagAndSlot(data.bagId, data.slotIndex))
        end
    end
    self.inventory.list:RefreshVisible()
end

function ZO_GamepadEnchanting:Select()
    local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
    local changedSlot = self:AddItemToCraft(bagId, slotIndex)
    if changedSlot then
        ZO_GamepadCraftingUtils_PlaySlotBounceAnimation(changedSlot)
    end
    self:UpdateSelection()
end

function ZO_GamepadEnchanting:Remove()
    local bagId, slotIndex = self.inventory:CurrentSelectionBagAndSlot()
    self:RemoveItemFromCraft(bagId, slotIndex)
    self:UpdateSelection()
end

function ZO_GamepadEnchanting:UpdateTooltip()
    if self:IsCraftable() then
        self.resultTooltip:SetHidden(false)
        self.resultTooltip.tip:ClearLines()
        self.resultTooltip.tip:LayoutEnchantingPreview(self:GetAllCraftingBagAndSlots())
    elseif self:IsExtractable() and self.extractionSlot:HasOneItem() then
        self.resultTooltip:SetHidden(false)

        self.resultTooltip.tip:ClearLines()

        local bagId, slotIndex = self.extractionSlot:GetItemBagAndSlot(1)
        local icon = GetItemInfo(bagId, slotIndex)

        local itemLink = GetItemLink(bagId, slotIndex)
        self.resultTooltip.tip:LayoutEnchantingCraftingItem(itemLink, icon, GetItemCreatorName(bagId, slotIndex))
    else
        self.resultTooltip:SetHidden(true)
    end
end

ZO_GamepadEnchantingInventory = ZO_GamepadCraftingInventory:Subclass()

function ZO_GamepadEnchantingInventory:New(...)
    return ZO_GamepadCraftingInventory.New(self, ...)
end

function ZO_GamepadEnchantingInventory:Initialize(owner, control, ...)
    local inventory = ZO_GamepadCraftingInventory.Initialize(self, control, ...)
    self.owner = owner
    self.filterType = NO_FILTER
    self.runeSlots = self.owner.runeSlots
end

function ZO_GamepadEnchantingInventory:IsLocked(bagId, slotIndex)
    return ZO_GamepadCraftingInventory.IsLocked(self, bagId, slotIndex) or self.owner:IsSlotted(bagId, slotIndex)
end

local function IsEnchantingItem(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

    if usedInCraftingType == CRAFTING_TYPE_ENCHANTING then
        if runeType == ENCHANTING_RUNE_ASPECT or runeType == ENCHANTING_RUNE_ESSENCE or runeType == ENCHANTING_RUNE_POTENCY then
            return true
        end
        if craftingSubItemType == ITEMTYPE_GLYPH_WEAPON or craftingSubItemType == ITEMTYPE_GLYPH_ARMOR or craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY then
            return true
        end
    end

    return false
end

local function DoesEnchantingItemPassFilter(bagId, slotIndex, filterType)
    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

    if filterType == EXTRACTION_FILTER then
        return craftingSubItemType == ITEMTYPE_GLYPH_WEAPON or craftingSubItemType == ITEMTYPE_GLYPH_ARMOR or craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY
    elseif filterType == NO_FILTER or filterType == runeType then
        return runeType == ENCHANTING_RUNE_ASPECT or runeType == ENCHANTING_RUNE_ESSENCE or runeType == ENCHANTING_RUNE_POTENCY
    end

    return false
end

function ZO_GamepadEnchantingInventory:Refresh(data)
    local filterType
    local titleString = nil
    local enchantingMode = self.owner:GetEnchantingMode()

    if enchantingMode == ENCHANTING_MODE_CREATION then
        filterType = self.filterType
        titleString = GetString(SI_ENCHANTING_CREATION)
    elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
        filterType = EXTRACTION_FILTER
        titleString = GetString(SI_ENCHANTING_EXTRACTION)
    end
    local validItemIds = self:EnumerateInventorySlotsAndAddToScrollData(IsEnchantingItem, DoesEnchantingItemPassFilter, filterType, data)
    self.owner:OnInventoryUpdate(validItemIds)

    if titleString then
        ZO_GamepadCraftingUtils_SetupGenericHeader(self.owner, titleString)
        ZO_GamepadCraftingUtils_RefreshGenericHeader(self.owner)
    end
end

function ZO_GamepadEnchantingInventory:ShowAppropriateSlotDropCallouts(bagId, slotIndex)
    local _, craftingSubItemType, runeType, rankRequirement, rarityRequirement = GetItemCraftingInfo(bagId, slotIndex)
    self.owner:ShowAppropriateSlotDropCallouts(craftingSubItemType, runeType, rankRequirement, rarityRequirement)
end

function ZO_GamepadEnchantingInventory:HideAllSlotDropCallouts()
    self.owner:HideAllSlotDropCallouts()
end

function ZO_GamepadEnchanting_Initialize(control)
    GAMEPAD_ENCHANTING = ZO_GamepadEnchanting:New(control)
end

ZO_EnchantExtractionSlot_Gamepad = ZO_SharedEnchantExtractionSlot:Subclass()

function ZO_EnchantExtractionSlot_Gamepad:New(...)
    return ZO_SharedEnchantExtractionSlot.New(self, ...)
end

function ZO_EnchantExtractionSlot_Gamepad:Initialize(owner, control, multipleItemsTexture, craftingInventory)
    ZO_SharedEnchantExtractionSlot.Initialize(self, owner, control, multipleItemsTexture, craftingInventory)
end

function ZO_EnchantExtractionSlot_Gamepad:ClearDropCalloutTexture()
    local NO_TEXTURE = ""
    self:SetEmptyTexture(NO_TEXTURE)
    self.previousGlyph = ITEMTYPE_NONE
end

function ZO_EnchantExtractionSlot_Gamepad:SetBackdrop(bagId, slotIndex)
    local usedInCraftingType, craftingSubItemType, runeType = GetItemCraftingInfo(bagId, slotIndex)

    if self.previousGlyph ~= craftingSubItemType then
        if craftingSubItemType == ITEMTYPE_GLYPH_WEAPON then
            self:SetEmptyTexture("EsoUI/Art/Crafting/Gamepad/gp_crafting_enchanting_glyphSlot_pentagon.dds")
        elseif craftingSubItemType == ITEMTYPE_GLYPH_ARMOR then
            self:SetEmptyTexture("EsoUI/Art/Crafting/Gamepad/gp_crafting_enchanting_glyphSlot_shield.dds")
        elseif craftingSubItemType == ITEMTYPE_GLYPH_JEWELRY then
            self:SetEmptyTexture("EsoUI/Art/Crafting/Gamepad/gp_crafting_enchanting_glyphSlot_round.dds")
        else
            craftingSubItemType = ITEMTYPE_NONE
        end

        self.previousGlyph = craftingSubItemType
    end
end