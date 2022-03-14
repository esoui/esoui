ZO_GAMEPAD_SMITHING_HORIZONTAL_LIST_X_PADDING = 20
ZO_GAMEPAD_SMITHING_HORIZONTAL_LIST_Y_PADDING = 4

local g_sceneToManagerMap = {}

local function GetShowingSceneOwner()
    for name, owner in pairs(g_sceneToManagerMap) do
        if SCENE_MANAGER:IsShowing(name) then
            return owner
        end
    end
end

function ZO_Smithing_AddScene(name, owner)
    g_sceneToManagerMap[name] = owner
end

function ZO_Smithing_IsSceneShowing()
    return GetShowingSceneOwner() ~= nil
end

function ZO_Smithing_GetActiveObject()
    local sceneOwner = GetShowingSceneOwner()
    return sceneOwner
end

function ZO_Smithing_IsSmithingStation(craftingType, craftingMode)
    craftingMode = craftingMode or GetCraftingInteractionMode()
    return craftingMode == CRAFTING_INTERACTION_MODE_STANDARD_STATION and IsSmithingCraftingType(craftingType)
end

function ZO_Smithing_IsUniversalDeconstructionCraftingMode(craftingMode)
    craftingMode = craftingMode or GetCraftingInteractionMode()
    return craftingMode == CRAFTING_INTERACTION_MODE_UNIVERSAL_DECONSTRUCTION
end

--
-- ZO_Smithing_Common
--

ZO_Smithing_Common = ZO_InitializingObject:Subclass()

SMITHING_BONUSES = 
{
    [NON_COMBAT_BONUS_BLACKSMITHING_LEVEL] = true,
    [NON_COMBAT_BONUS_BLACKSMITHING_BOOSTER_BONUS] = true,
    [NON_COMBAT_BONUS_BLACKSMITHING_EXTRACT_LEVEL] = true,
    [NON_COMBAT_BONUS_BLACKSMITHING_CRAFT_PERCENT_DISCOUNT] = true,
    [NON_COMBAT_BONUS_BLACKSMITHING_RESEARCH_LEVEL] = true,

    [NON_COMBAT_BONUS_CLOTHIER_LEVEL] = true,
    [NON_COMBAT_BONUS_CLOTHIER_BOOSTER_BONUS] = true,
    [NON_COMBAT_BONUS_CLOTHIER_EXTRACT_LEVEL] = true,
    [NON_COMBAT_BONUS_CLOTHIER_CRAFT_PERCENT_DISCOUNT] = true,
    [NON_COMBAT_BONUS_CLOTHIER_RESEARCH_LEVEL] = true,

    [NON_COMBAT_BONUS_WOODWORKING_LEVEL] = true,
    [NON_COMBAT_BONUS_WOODWORKING_BOOSTER_BONUS] = true,
    [NON_COMBAT_BONUS_WOODWORKING_EXTRACT_LEVEL] = true,
    [NON_COMBAT_BONUS_WOODWORKING_CRAFT_PERCENT_DISCOUNT] = true,
    [NON_COMBAT_BONUS_WOODWORKING_RESEARCH_LEVEL] = true,

    [NON_COMBAT_BONUS_JEWELRYCRAFTING_LEVEL] = true,
    [NON_COMBAT_BONUS_JEWELRYCRAFTING_BOOSTER_BONUS] = true,
    [NON_COMBAT_BONUS_JEWELRYCRAFTING_EXTRACT_LEVEL] = true,
    [NON_COMBAT_BONUS_JEWELRYCRAFTING_CRAFT_PERCENT_DISCOUNT] = true,
    [NON_COMBAT_BONUS_JEWELRYCRAFTING_RESEARCH_LEVEL] = true,
}

function ZO_Smithing_Common:Initialize(control)
    self.control = control
    self.smithingStationInteraction =
    {
        type = "Smithing Station",
        OnInteractSwitch = function()
            internalassert(false, "OnInteractSwitch is being called.")
            SCENE_MANAGER:ShowBaseScene()
        end,
        interactTypes = { INTERACTION_CRAFT },
    }

    local function OnQuestInformationUpdated(updatedQuestInfo)
        self.shouldRefineForQuest = updatedQuestInfo.smithingItemId ~= nil
        self.shouldCraftForQuest = updatedQuestInfo.hasPatterns and (not updatedQuestInfo.hasItemToImproveForWrit)
        self.shouldImproveForQuest = updatedQuestInfo.hasItemToImproveForWrit
        self.usesProvisioningForQuest = updatedQuestInfo.hasRecipesForQuest
        self:UpdateQuestPins()
    end
    CRAFT_ADVISOR_MANAGER:RegisterCallback("QuestInformationUpdated", OnQuestInformationUpdated)
end

function ZO_Smithing_Common:CreateInteractScene(sceneName)
    return ZO_InteractScene:New(sceneName, SCENE_MANAGER, self.smithingStationInteraction)
end

SMITHING_MODE_ROOT = 0
SMITHING_MODE_REFINEMENT = 1
SMITHING_MODE_CREATION = 2
SMITHING_MODE_DECONSTRUCTION = 3
SMITHING_MODE_IMPROVEMENT = 4
SMITHING_MODE_RESEARCH = 5
SMITHING_MODE_RECIPES = 6

local g_craftingTypeModeTutorialMap =
{
    [CRAFTING_TYPE_BLACKSMITHING] =
    {
        [SMITHING_MODE_REFINEMENT] = TUTORIAL_TRIGGER_BLACKSMITHING_REFINEMENT_OPENED,
        [SMITHING_MODE_CREATION] = TUTORIAL_TRIGGER_BLACKSMITHING_CREATION_OPENED,
        [SMITHING_MODE_DECONSTRUCTION] = TUTORIAL_TRIGGER_BLACKSMITHING_DECONSTRUCTION_OPENED,
        [SMITHING_MODE_IMPROVEMENT] = TUTORIAL_TRIGGER_BLACKSMITHING_IMPROVEMENT_OPENED,
        [SMITHING_MODE_RESEARCH] = TUTORIAL_TRIGGER_BLACKSMITHING_RESEARCH_OPENED,
    },
    [CRAFTING_TYPE_CLOTHIER] =
    {
        [SMITHING_MODE_REFINEMENT] = TUTORIAL_TRIGGER_CLOTHIER_REFINEMENT_OPENED,
        [SMITHING_MODE_CREATION] = TUTORIAL_TRIGGER_CLOTHIER_CREATION_OPENED,
        [SMITHING_MODE_DECONSTRUCTION] = TUTORIAL_TRIGGER_CLOTHIER_DECONSTRUCTION_OPENED,
        [SMITHING_MODE_IMPROVEMENT] = TUTORIAL_TRIGGER_CLOTHIER_IMPROVEMENT_OPENED,
        [SMITHING_MODE_RESEARCH] = TUTORIAL_TRIGGER_CLOTHIER_RESEARCH_OPENED,
    },
    [CRAFTING_TYPE_JEWELRYCRAFTING] =
    {
        [SMITHING_MODE_REFINEMENT] = TUTORIAL_TRIGGER_JEWELRYCRAFTING_REFINEMENT_OPENED,
        [SMITHING_MODE_CREATION] = TUTORIAL_TRIGGER_JEWELRYCRAFTING_CREATION_OPENED,
        [SMITHING_MODE_DECONSTRUCTION] = TUTORIAL_TRIGGER_JEWELRYCRAFTING_DECONSTRUCTION_OPENED,
        [SMITHING_MODE_IMPROVEMENT] = TUTORIAL_TRIGGER_JEWELRYCRAFTING_IMPROVEMENT_OPENED,
        [SMITHING_MODE_RESEARCH] = TUTORIAL_TRIGGER_JEWELRYCRAFTING_RESEARCH_OPENED,
    },
    [CRAFTING_TYPE_WOODWORKING] =
    {
        [SMITHING_MODE_REFINEMENT] = TUTORIAL_TRIGGER_WOODWORKING_REFINEMENT_OPENED,
        [SMITHING_MODE_CREATION] = TUTORIAL_TRIGGER_WOODWORKING_CREATION_OPENED,
        [SMITHING_MODE_DECONSTRUCTION] = TUTORIAL_TRIGGER_WOODWORKING_DECONSTRUCTION_OPENED,
        [SMITHING_MODE_IMPROVEMENT] = TUTORIAL_TRIGGER_WOODWORKING_IMPROVEMENT_OPENED,
        [SMITHING_MODE_RESEARCH] = TUTORIAL_TRIGGER_WOODWORKING_RESEARCH_OPENED,
    },
}

function ZO_Smithing_Common:GetTutorialTrigger(craftingType, mode)
    local modeTriggerMap = g_craftingTypeModeTutorialMap[craftingType]
    return modeTriggerMap and modeTriggerMap[mode] or nil
end

function ZO_Smithing_Common:DirtyAllPanels()
    if self.creationPanel then
        self.creationPanel:DirtyAllLists()
    end
    if self.improvementPanel then
        self.improvementPanel:HandleDirtyEvent()
    end
    if self.researchPanel then
        self.researchPanel:HandleDirtyEvent()
    end
end

function ZO_Smithing_Common:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINEMENT then
        return self.refinementPanel:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        return self.improvementPanel:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        return self.deconstructionPanel:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:CanItemBeAddedToCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINEMENT then
        return self.refinementPanel:CanItemBeAddedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        return self.improvementPanel:CanItemBeAddedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        return self.deconstructionPanel:CanItemBeAddedToCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:AddItemToCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINEMENT then
        self.refinementPanel:AddItemToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        self.improvementPanel:AddItemToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        self.deconstructionPanel:AddItemToCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:RemoveItemFromCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINEMENT then
        self.refinementPanel:RemoveItemFromCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        self.improvementPanel:RemoveItemFromCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        self.deconstructionPanel:RemoveItemFromCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:ClearSelections()
    if self.mode == SMITHING_MODE_REFINEMENT then
        self.refinementPanel:ClearSelections()
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        self.improvementPanel:ClearSelections()
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        self.deconstructionPanel:ClearSelections()
    end
end

function ZO_Smithing_Common:DoesCurrentModeHaveSlotAnimations()
    return self.mode == SMITHING_MODE_IMPROVEMENT or self.mode == SMITHING_MODE_REFINEMENT or self.mode == SMITHING_MODE_DECONSTRUCTION
end

function ZO_Smithing_Common:IsCreating()
    return self.mode == SMITHING_MODE_CREATION
end

function ZO_Smithing_Common:IsImproving()
    return self.mode == SMITHING_MODE_IMPROVEMENT
end

function ZO_Smithing_Common:IsExtracting()
    return self.mode == SMITHING_MODE_REFINEMENT or self.mode == SMITHING_MODE_DECONSTRUCTION
end

function ZO_Smithing_Common:IsDeconstructing()
    return self.mode == SMITHING_MODE_DECONSTRUCTION
end

-- The following functions to update keybinds are called by both
-- gamepad/keyboard, but only affect the shared keybind strip on keyboard. Where
-- possible, refactor away from these functions and toward calling UpdateSharedKeybinds directly
-- on the keyboard side of things
function ZO_Smithing_Common:OnImprovementSlotChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Smithing_Common:OnExtractionSlotChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Smithing_Common:OnResearchSlotChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SmithingHorizontalListTemplate_OnInitialized(control)
    control.listControl = control:GetNamedChild("List")
    control.titleLabel = control:GetNamedChild("Title")
    control.extraInfoLabel = control:GetNamedChild("ExtraInfoLabel")

    --Center the selected label text in the whole control but limit its width such that it doesn't run into title text which is on the left side of it
    local selectedLabel = control:GetNamedChild("SelectedLabel")
    control.selectedLabel = selectedLabel
    control.titleLabel:SetHandler("OnTextChanged", function(titleLabel)
        local titleWidth = titleLabel:GetTextWidth()
        local totalWidth = control:GetWidth()
        local TITLE_SELECTED_LABEL_PADDING_X = 10
        local selectedLabelWidth = (totalWidth - titleWidth * 2) - TITLE_SELECTED_LABEL_PADDING_X * 2
        selectedLabel:SetWidth(selectedLabelWidth)
    end)
end

function ZO_Smithing_Common:GetMode()
	return self.mode
end

function ZO_Smithing_Common:UpdateQuestPins()
    -- Can be overridden
end