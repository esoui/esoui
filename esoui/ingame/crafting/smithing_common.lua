ZO_GAMEPAD_SMITHING_HORIZONTAL_LIST_X_PADDING = 20
ZO_GAMEPAD_SMITHING_HORIZONTAL_LIST_Y_PADDING = 4
ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX = ITEMSTYLE_UNIVERSAL + 1 -- 1 is because it expects a lua index

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

function ZO_Smithing_IsSmithingStation(craftingType)
    return craftingType == CRAFTING_TYPE_BLACKSMITHING 
        or craftingType == CRAFTING_TYPE_CLOTHIER
        or craftingType == CRAFTING_TYPE_WOODWORKING
end

--
-- ZO_Smithing_Common
--

ZO_Smithing_Common = ZO_Object:Subclass()

function ZO_Smithing_Common:New(...)
    local smithing = ZO_Object.New(self)
    smithing:Initialize(...)
    return smithing
end

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
}

function ZO_Smithing_Common:Initialize(control)
    self.control = control
    self.smithingStationInteraction =
    {
        type = "Smithing Station",
        End = function()
            SCENE_MANAGER:ShowBaseScene()
        end,
        interactTypes = { INTERACTION_CRAFT },
    }
end

function ZO_Smithing_Common:CreateInteractScene(sceneName)
    return ZO_InteractScene:New(sceneName, SCENE_MANAGER, self.smithingStationInteraction)
end

SMITHING_MODE_ROOT = 0
SMITHING_MODE_REFINMENT = 1
SMITHING_MODE_CREATION = 2
SMITHING_MODE_DECONSTRUCTION = 3
SMITHING_MODE_IMPROVEMENT = 4
SMITHING_MODE_RESEARCH = 5
SMITHING_MODE_RECIPES = 6

function ZO_Smithing_Common:GetTutorialTrigger(craftingType, mode)
    if craftingType == CRAFTING_TYPE_BLACKSMITHING then
        if mode == SMITHING_MODE_REFINMENT then
            return TUTORIAL_TRIGGER_BLACKSMITHING_REFINEMENT_OPENED
        elseif mode == SMITHING_MODE_CREATION then
            return TUTORIAL_TRIGGER_BLACKSMITHING_CREATION_OPENED
        elseif mode == SMITHING_MODE_DECONSTRUCTION then
            return TUTORIAL_TRIGGER_BLACKSMITHING_DECONSTRUCTION_OPENED
        elseif mode == SMITHING_MODE_IMPROVEMENT then
            return TUTORIAL_TRIGGER_BLACKSMITHING_IMPROVEMENT_OPENED
        elseif mode == SMITHING_MODE_RESEARCH then
            return TUTORIAL_TRIGGER_BLACKSMITHING_RESEARCH_OPENED
        end
    elseif craftingType == CRAFTING_TYPE_CLOTHIER then
        if mode == SMITHING_MODE_REFINMENT then
            return TUTORIAL_TRIGGER_CLOTHIER_REFINEMENT_OPENED
        elseif mode == SMITHING_MODE_CREATION then
            return TUTORIAL_TRIGGER_CLOTHIER_CREATION_OPENED
        elseif mode == SMITHING_MODE_DECONSTRUCTION then
            return TUTORIAL_TRIGGER_CLOTHIER_DECONSTRUCTION_OPENED
        elseif mode == SMITHING_MODE_IMPROVEMENT then
            return TUTORIAL_TRIGGER_CLOTHIER_IMPROVEMENT_OPENED
        elseif mode == SMITHING_MODE_RESEARCH then
            return TUTORIAL_TRIGGER_CLOTHIER_RESEARCH_OPENED
        end
    elseif craftingType == CRAFTING_TYPE_WOODWORKING then
        if mode == SMITHING_MODE_REFINMENT then
            return TUTORIAL_TRIGGER_WOODWORKING_REFINEMENT_OPENED
        elseif mode == SMITHING_MODE_CREATION then
            return TUTORIAL_TRIGGER_WOODWORKING_CREATION_OPENED
        elseif mode == SMITHING_MODE_DECONSTRUCTION then
            return TUTORIAL_TRIGGER_WOODWORKING_DECONSTRUCTION_OPENED
        elseif mode == SMITHING_MODE_IMPROVEMENT then
            return TUTORIAL_TRIGGER_WOODWORKING_IMPROVEMENT_OPENED
        elseif mode == SMITHING_MODE_RESEARCH then
            return TUTORIAL_TRIGGER_WOODWORKING_RESEARCH_OPENED
        end
    end
end

function ZO_Smithing_Common:DirtyAllPanels()
    self.creationPanel:HandleDirtyEvent()
    self.improvementPanel:HandleDirtyEvent()
    self.researchPanel:HandleDirtyEvent()
end

function ZO_Smithing_Common:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINMENT then
        return self.refinementPanel:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        return self.improvementPanel:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        return self.deconstructionPanel:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:CanItemBeAddedToCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINMENT then
        return self.refinementPanel:CanItemBeAddedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        return self.improvementPanel:CanItemBeAddedToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        return self.deconstructionPanel:CanItemBeAddedToCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:AddItemToCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINMENT then
        self.refinementPanel:AddItemToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        self.improvementPanel:AddItemToCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        self.deconstructionPanel:AddItemToCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:RemoveItemFromCraft(bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINMENT then
        self.refinementPanel:RemoveItemFromCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        self.improvementPanel:RemoveItemFromCraft(bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        self.deconstructionPanel:RemoveItemFromCraft(bagId, slotIndex)
    end
end

function ZO_Smithing_Common:DoesCurrentModeHaveSlotAnimations()
    return self.mode == SMITHING_MODE_IMPROVEMENT or self.mode == SMITHING_MODE_REFINMENT or self.mode == SMITHING_MODE_DECONSTRUCTION
end

function ZO_Smithing_Common:IsImproving()
    return self.mode == SMITHING_MODE_IMPROVEMENT
end

function ZO_Smithing_Common:IsExtracting()
    return self.mode == SMITHING_MODE_REFINMENT or self.mode == SMITHING_MODE_DECONSTRUCTION
end

function ZO_Smithing_Common:IsDeconstructing()
    return self.mode == SMITHING_MODE_DECONSTRUCTION
end

-- The following functions to update keybinds are only called on the non-gamepad version of the screens.
function ZO_Smithing_Common:OnSelectedPatternChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Smithing_Common:OnMaterialChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Smithing_Common:OnSelectedStyleChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Smithing_Common:OnSelectedTraitChanged()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

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
    control.highlightTexture = control:GetNamedChild("Highlight")
    control.titleLabel = control:GetNamedChild("Title")
    control.selectedLabel = control:GetNamedChild("SelectedLabel")
    control.extraInfoLabel = control:GetNamedChild("ExtraInfoLabel")
end