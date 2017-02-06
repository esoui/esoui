local GAMEPAD_SMITHING_ROOT_SCENE_NAME = "gamepad_smithing_root"
local GAMEPAD_SMITHING_REFINE_SCENE_NAME = "gamepad_smithing_refine"
local GAMEPAD_SMITHING_CREATION_SCENE_NAME = "gamepad_smithing_creation"
local GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME = "gamepad_smithing_deconstruct"
local GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME = "gamepad_smithing_improvement"
local GAMEPAD_SMITHING_RESEARCH_SCENE_NAME = "gamepad_smithing_research"

local g_modeToSceneName =
{
    [SMITHING_MODE_ROOT] = GAMEPAD_SMITHING_ROOT_SCENE_NAME,
    [SMITHING_MODE_REFINMENT] = GAMEPAD_SMITHING_REFINE_SCENE_NAME,
    [SMITHING_MODE_CREATION] = GAMEPAD_SMITHING_CREATION_SCENE_NAME,
    [SMITHING_MODE_DECONSTRUCTION] = GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME,
    [SMITHING_MODE_IMPROVEMENT] = GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME,
    [SMITHING_MODE_RESEARCH] = GAMEPAD_SMITHING_RESEARCH_SCENE_NAME,
}

ZO_Smithing_Gamepad = ZO_Smithing_Common:Subclass()

function ZO_Smithing_Gamepad:New(...)
    return ZO_Smithing_Common.New(self, ...)
end

function ZO_Smithing_Gamepad:Initialize(control)
    ZO_Smithing_Common.Initialize(self, control)

    self.mainSceneName = GAMEPAD_SMITHING_ROOT_SCENE_NAME
    self.skillInfoBar = ZO_GamepadSmithingTopLevelSkillInfo
    local skillLineXPBarFragment = ZO_FadeSceneFragment:New(self.skillInfoBar)
    local function MakeScene(name, mode)
        local scene = self:CreateInteractScene(name)
        scene:AddFragment(skillLineXPBarFragment)
        scene:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING then
                TriggerTutorial(self.GetTutorialTrigger(self, GetCraftingInteractionType(), mode))
            end
        end)

        return scene
    end

    GAMEPAD_SMITHING_ROOT_SCENE = MakeScene(GAMEPAD_SMITHING_ROOT_SCENE_NAME, SMITHING_MODE_ROOT)
    GAMEPAD_SMITHING_REFINE_SCENE = MakeScene(GAMEPAD_SMITHING_REFINE_SCENE_NAME, SMITHING_MODE_REFINMENT)
    GAMEPAD_SMITHING_CREATION_SCENE = MakeScene(GAMEPAD_SMITHING_CREATION_SCENE_NAME, SMITHING_MODE_CREATION)
    GAMEPAD_SMITHING_DECONSTRUCT_SCENE = MakeScene(GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME, SMITHING_MODE_DECONSTRUCTION)
    GAMEPAD_SMITHING_IMPROVEMENT_SCENE = MakeScene(GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME, SMITHING_MODE_IMPROVEMENT)
    GAMEPAD_SMITHING_RESEARCH_SCENE = MakeScene(GAMEPAD_SMITHING_RESEARCH_SCENE_NAME, SMITHING_MODE_RESEARCH)

    --Scenes that we should hide if the crafting interaction is terminated.
    self.smithingRelatedSceneNames =
    {
        GAMEPAD_SMITHING_ROOT_SCENE_NAME,
        GAMEPAD_SMITHING_REFINE_SCENE_NAME,
        GAMEPAD_SMITHING_CREATION_SCENE_NAME,
        GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME,
        GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME,
        GAMEPAD_SMITHING_RESEARCH_SCENE_NAME,
        "gamepad_provisioner_root", --Recipe based smithing crafting
        "gamepad_provisioner_options",
    }

    local REFINEMENT_ONLY = true
    local maskControl = self.control:GetNamedChild("Mask")
    self.refinementPanel = ZO_GamepadSmithingExtraction:New(maskControl:GetNamedChild("Refinement"), self.control:GetNamedChild("Refinement"), self, REFINEMENT_ONLY, GAMEPAD_SMITHING_REFINE_SCENE)
    self.creationPanel = ZO_GamepadSmithingCreation:New(maskControl:GetNamedChild("Creation"), self.control:GetNamedChild("Creation"), self, GAMEPAD_SMITHING_CREATION_SCENE)
    self.improvementPanel = ZO_GamepadSmithingImprovement:New(maskControl:GetNamedChild("Improvement"), self.control:GetNamedChild("Improvement"), self, GAMEPAD_SMITHING_IMPROVEMENT_SCENE)
    self.deconstructionPanel = ZO_GamepadSmithingExtraction:New(maskControl:GetNamedChild("Deconstruction"), self.control:GetNamedChild("Deconstruction"), self, not REFINEMENT_ONLY, GAMEPAD_SMITHING_DECONSTRUCT_SCENE)
    self.researchPanel = ZO_GamepadSmithingResearch:New(maskControl:GetNamedChild("Research"), self, GAMEPAD_SMITHING_RESEARCH_SCENE)

    self:InitializeModeList()
    self:InitializeKeybindStripDescriptors()

    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    GAMEPAD_SMITHING_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            local craftingType = GetCraftingInteractionType()

            self.creationPanel:PerformDeferredInitialization()
            self.researchPanel:PerformDeferredInitialization()

            self:RefreshModeList(craftingType)

            self.refinementPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.creationPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.improvementPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.deconstructionPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.researchPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.oldCraftingType = craftingType

            self:SetMode(SMITHING_MODE_ROOT)
            if self.resetUIs then
                self.modeList:SetSelectedIndexWithoutAnimation(SMITHING_MODE_REFINMENT)
            end

            self:SetEnableSkillBar(true)

            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.modeList:Activate()

            local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(GetCraftingInteractionType())

            ZO_GamepadCraftingUtils_SetupGenericHeader(self, titleString)
            ZO_GamepadCraftingUtils_RefreshGenericHeader(self)

            self.resetUIs = nil
        elseif newState == SCENE_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.modeList:Deactivate()

            self:DirtyAllPanels()

            self:SetEnableSkillBar(false)
        end
    end)

    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, sameStation)
        if ZO_Smithing_IsSmithingStation(craftingType) and IsInGamepadPreferredMode() then
            self.resetUIs = not sameStation
            SCENE_MANAGER:Show(GAMEPAD_SMITHING_ROOT_SCENE_NAME)
        end
    end)

    self.control:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
        if ZO_Smithing_IsSmithingStation(craftingType) and IsInGamepadPreferredMode() then
            -- make sure that we are, in fact, on a smithing scene before we try to show the base scene
            -- certain times, such as going to the crown store from crafting, can get squashed without this
            for _, smithingSceneName in ipairs(self.smithingRelatedSceneNames) do
                if SCENE_MANAGER:IsShowing(smithingSceneName) then
                    SCENE_MANAGER:ShowBaseScene()
                    break
                end
            end
        end
    end)

    local function HandleDirtyEvent()
        self:DirtyAllPanels()
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleDirtyEvent)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleDirtyEvent)

    self.control:RegisterForEvent(EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if SMITHING_BONUSES[nonCombatBonusType] then
            HandleDirtyEvent()
        end
    end)

    self.control:RegisterForEvent(EVENT_SMITHING_TRAIT_RESEARCH_STARTED, HandleDirtyEvent)
    self.control:RegisterForEvent(EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED, HandleDirtyEvent)
end

function ZO_Smithing_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        -- Select mode.
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
        
            callback = function()
                local targetData = self.modeList:GetTargetData()
                self:SetMode(targetData.mode)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.modeList)
end

function ZO_Smithing_Gamepad:CreateModeEntry(name, mode, icon)
    local data = ZO_GamepadEntryData:New(GetString(name), icon)
    data:SetIconTintOnSelection(true)
    data.mode = mode
    return data
end

function ZO_Smithing_Gamepad:AddModeEntry(entry)
    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", entry)
end

function ZO_Smithing_Gamepad:InitializeModeList()
    self.modeList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("Mask"):GetNamedChild("Container"):GetNamedChild("List"))
    self.modeList:SetAlignToScreenCenter(true)
    self.modeList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    
    self.refinementModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_REFINMENT, SMITHING_MODE_REFINMENT, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_refine.dds")
    self.creationModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_CREATION, SMITHING_MODE_CREATION, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_create.dds")
    self.deconstructionModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_DECONSTRUCTION, SMITHING_MODE_DECONSTRUCTION, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_deconstruct.dds")
    self.improvementModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_IMPROVEMENT, SMITHING_MODE_IMPROVEMENT, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_improve.dds")
    self.researchModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_RESEARCH, SMITHING_MODE_RESEARCH, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_research.dds")
end

function ZO_Smithing_Gamepad:RefreshModeList(craftingType)
    self.modeList:Clear()
    self:AddModeEntry(self.refinementModeEntry)
    self:AddModeEntry(self.creationModeEntry)
    self:AddModeEntry(self.deconstructionModeEntry)
    self:AddModeEntry(self.improvementModeEntry)
    self:AddModeEntry(self.researchModeEntry)
    
    local recipeCraftingSystem = GetTradeskillRecipeCraftingSystem(craftingType)
    local recipeCraftingSystemNameStringId = _G["SI_RECIPECRAFTINGSYSTEM"..recipeCraftingSystem]
    local recipeModeEntry = self:CreateModeEntry(recipeCraftingSystemNameStringId, SMITHING_MODE_RECIPES, GetGamepadRecipeCraftingSystemMenuTextures(recipeCraftingSystem))
    self:AddModeEntry(recipeModeEntry)
    self.modeList:Commit()
end

function ZO_Smithing_Gamepad:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode
        if mode == SMITHING_MODE_RECIPES then
            GAMEPAD_PROVISIONER:EmbedInCraftingScene(self.smithingStationInteraction)
        else
            SCENE_MANAGER:Push(g_modeToSceneName[mode])
        end
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Smithing_Gamepad:SetEnableSkillBar(enable)
	if enable then
		local craftingType = GetCraftingInteractionType()
		ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.skillInfoBar, craftingType)
	else
		ZO_Skills_UntieSkillInfoHeaderToCraftingSkill(self.skillInfoBar)
	end
end

function ZO_Smithing_Gamepad_Initialize(control)
    SMITHING_GAMEPAD = ZO_Smithing_Gamepad:New(control)

    ZO_Smithing_AddScene(GAMEPAD_SMITHING_ROOT_SCENE_NAME, SMITHING_GAMEPAD)
    ZO_Smithing_AddScene(GAMEPAD_SMITHING_REFINE_SCENE_NAME, SMITHING_GAMEPAD)
    ZO_Smithing_AddScene(GAMEPAD_SMITHING_CREATION_SCENE_NAME, SMITHING_GAMEPAD)
    ZO_Smithing_AddScene(GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME, SMITHING_GAMEPAD)
    ZO_Smithing_AddScene(GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME, SMITHING_GAMEPAD)
    ZO_Smithing_AddScene(GAMEPAD_SMITHING_RESEARCH_SCENE_NAME, SMITHING_GAMEPAD)
end
