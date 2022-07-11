ZO_UniversalDeconstruction_Keyboard = ZO_Smithing_Common:Subclass()

function ZO_UniversalDeconstruction_Keyboard:Initialize(control)
    ZO_Smithing_Common.Initialize(self, control)

    self.mode = SMITHING_MODE_DECONSTRUCTION
    self.craftingTypes = ZO_UNIVERSAL_DECONSTRUCTION_CRAFTING_TYPES
    self.deconstructionPanelControl = self.control:GetNamedChild("Panel")
    self.deconstructionPanel = ZO_UniversalDeconstructionPanel_Keyboard:New(self.deconstructionPanelControl, self)
    self.skillInfoControl = self.control:GetNamedChild("SkillInfo")

    self.modeBar = self.control:GetNamedChild("ModeMenuBar")
    self.modeBarLabel = self.modeBar:GetNamedChild("Label")
    self.modeBarLabel:SetText(GetString(SI_SMITHING_TAB_DECONSTRUCTION))
    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)

    self.deconstructionTab =
    {
        categoryName = SI_SMITHING_TAB_DECONSTRUCTION,
        descriptor = SMITHING_MODE_DECONSTRUCTION,
        normal = "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_up.dds",
        pressed = "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_down.dds",
        highlight = "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_over.dds",
        disabled = "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_disabled.dds",
    }

    self:InitializeKeybindStripDescriptors()

    self.scene = self:CreateInteractScene("universalDeconstructionSceneKeyboard")
    UNIVERSAL_DECONSTRUCTION_KEYBOARD_SCENE = self.scene

    local function OnSceneStateChanged(oldState, newState)
        if newState == SCENE_SHOWN then
            CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.UNIVERSAL_DECONSTRUCTION_SUCCESS, SOUNDS.UNIVERSAL_DECONSTRUCTION_FAIL)
            TriggerTutorial(TUTORIAL_TRIGGER_UNIVERSAL_DECONSTRUCTION_OPENED)
        elseif newState == SCENE_SHOWING then
            ZO_MultipleCraftingSkillsXpBar_TieSkillInfoHeaderToCraftingTypes(self.skillInfoControl, self.craftingTypes)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            ZO_MenuBar_ClearButtons(self.modeBar)
            ZO_MenuBar_AddButton(self.modeBar, self.deconstructionTab)
            local SKIP_ANIMATION = true
            local RESELECT_IF_SELECTED = false
            ZO_MenuBar_SelectDescriptor(self.modeBar, SMITHING_MODE_DECONSTRUCTION, SKIP_ANIMATION, RESELECT_IF_SELECTED)
        elseif newState == SCENE_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self:DirtyAllPanels()

            ZO_MultipleCraftingSkillsXpBar_UntieSkillInfoHeaderToCraftingTypes(self.skillInfoControl)
            CRAFTING_RESULTS:SetCraftingTooltip(nil)
        end
    end
    self.scene:RegisterCallback("StateChange", OnSceneStateChanged)

    local OnCraftingInteractStarted = function(eventCode, craftingType, sameStation, craftingMode)
        if self.CanSceneShowForCraftingMode(craftingMode) then
            self.interactingWithSameStation = sameStation
            SCENE_MANAGER:Show("universalDeconstructionSceneKeyboard")
        end
    end
    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, OnCraftingInteractStarted)

    local OnCraftingInteractEnded = function(eventCode, craftingType, craftingMode)
        if self.CanSceneShowForCraftingMode(craftingMode) then
            SCENE_MANAGER:Hide("universalDeconstructionSceneKeyboard")
        end
    end
    self.control:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, OnCraftingInteractEnded)

    local OnInventoryUpdated = function()
        self:DirtyAllPanels()
    end
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdated)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdated)
end

function ZO_UniversalDeconstruction_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Perform craft/extract/improve
        {
            keybind = "UI_SHORTCUT_SECONDARY",

            name = function()
                if self.mode == SMITHING_MODE_DECONSTRUCTION then
                    local action = self.deconstructionPanel:IsMultiExtract() and "SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE" or "SI_DECONSTRUCTACTIONNAME"
                    return GetString(action, DECONSTRUCT_ACTION_NAME_DECONSTRUCT)
                end
            end,

            callback = function()
                if self.mode == SMITHING_MODE_DECONSTRUCTION then
                    self.deconstructionPanel:ConfirmExtractAll()
                end
            end,

            enabled = function()
                if ZO_CraftingUtils_IsPerformingCraftProcess() then
                    return false
                end

                if self.mode == SMITHING_MODE_DECONSTRUCTION then
                    return self.deconstructionPanel:IsExtractable()
                end
            end,
        },

        -- Clear selections
        {
            keybind = "UI_SHORTCUT_NEGATIVE",

            name = function()
                return GetString(SI_CRAFTING_CLEAR_SELECTIONS)
            end,

            callback = function()
                if self.mode == SMITHING_MODE_DECONSTRUCTION then
                    self.deconstructionPanel:ClearSelections()
                end 
            end,

            visible = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then 
                    if self.mode == SMITHING_MODE_DECONSTRUCTION then
                        return self.deconstructionPanel:HasSelections() 
                    end 
                end
            end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_UniversalDeconstruction_Keyboard:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    if self.mode == SMITHING_MODE_DECONSTRUCTION then
        self.deconstructionPanel:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    end
end

function ZO_UniversalDeconstruction_Keyboard:UpdateKeybindStrip()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_UniversalDeconstruction_Keyboard.CanSceneShowForCraftingMode(craftingMode)
    return not IsInGamepadPreferredMode() and ZO_Smithing_IsUniversalDeconstructionCraftingMode(craftingMode)
end

function ZO_UniversalDeconstruction_Keyboard_Initialize(control)
    UNIVERSAL_DECONSTRUCTION = ZO_UniversalDeconstruction_Keyboard:New(control)

    ZO_Smithing_AddScene("universalDeconstructionSceneKeyboard", UNIVERSAL_DECONSTRUCTION)
end