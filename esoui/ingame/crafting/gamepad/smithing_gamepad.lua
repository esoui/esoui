local GAMEPAD_SMITHING_ROOT_SCENE_NAME = "gamepad_smithing_root"
local GAMEPAD_SMITHING_REFINE_SCENE_NAME = "gamepad_smithing_refine"
local GAMEPAD_SMITHING_CREATION_SCENE_NAME = "gamepad_smithing_creation"
local GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME = "gamepad_smithing_deconstruct"
local GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME = "gamepad_smithing_improvement"
local GAMEPAD_SMITHING_RESEARCH_SCENE_NAME = "gamepad_smithing_research"
local GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE_NAME = "gamepad_smithing_consolidatedSetSelection"

local g_modeToSceneName =
{
    [SMITHING_MODE_ROOT] = GAMEPAD_SMITHING_ROOT_SCENE_NAME,
    [SMITHING_MODE_REFINEMENT] = GAMEPAD_SMITHING_REFINE_SCENE_NAME,
    [SMITHING_MODE_CREATION] = GAMEPAD_SMITHING_CREATION_SCENE_NAME,
    [SMITHING_MODE_DECONSTRUCTION] = GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME,
    [SMITHING_MODE_IMPROVEMENT] = GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME,
    [SMITHING_MODE_RESEARCH] = GAMEPAD_SMITHING_RESEARCH_SCENE_NAME,
    [SMITHING_MODE_CONSOLIDATED_SET_SELECTION] = GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE_NAME,
}

ZO_Smithing_Gamepad = ZO_Smithing_Common:Subclass()

function ZO_Smithing_Gamepad:New(...)
    return ZO_Smithing_Common.New(self, ...)
end

function ZO_Smithing_Gamepad:Initialize(control)
    ZO_Smithing_Common.Initialize(self, control)

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
    GAMEPAD_SMITHING_ROOT_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    GAMEPAD_SMITHING_REFINE_SCENE = MakeScene(GAMEPAD_SMITHING_REFINE_SCENE_NAME, SMITHING_MODE_REFINEMENT)
    GAMEPAD_SMITHING_REFINE_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    GAMEPAD_SMITHING_CREATION_SCENE = MakeScene(GAMEPAD_SMITHING_CREATION_SCENE_NAME, SMITHING_MODE_CREATION)
    GAMEPAD_SMITHING_CREATION_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    GAMEPAD_SMITHING_DECONSTRUCT_SCENE = MakeScene(GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME, SMITHING_MODE_DECONSTRUCTION)
    GAMEPAD_SMITHING_DECONSTRUCT_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    GAMEPAD_SMITHING_IMPROVEMENT_SCENE = MakeScene(GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME, SMITHING_MODE_IMPROVEMENT)
    GAMEPAD_SMITHING_IMPROVEMENT_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    GAMEPAD_SMITHING_RESEARCH_SCENE = MakeScene(GAMEPAD_SMITHING_RESEARCH_SCENE_NAME, SMITHING_MODE_RESEARCH)
    GAMEPAD_SMITHING_RESEARCH_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE = MakeScene(GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE_NAME, SMITHING_MODE_CONSOLIDATED_SET_SELECTION)
    GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)

    --Scenes that we should hide if the crafting interaction is terminated.
    self.smithingRelatedSceneNames =
    {
        GAMEPAD_SMITHING_ROOT_SCENE_NAME,
        GAMEPAD_SMITHING_REFINE_SCENE_NAME,
        GAMEPAD_SMITHING_CREATION_SCENE_NAME,
        GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME,
        GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME,
        GAMEPAD_SMITHING_RESEARCH_SCENE_NAME,
        GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE_NAME,
        "gamepad_provisioner_root", --Recipe based smithing crafting
        "gamepad_provisioner_options",
    }

    local REFINEMENT_ONLY = true
    local maskControl = control:GetNamedChild("Mask")
    self.refinementPanel = ZO_GamepadSmithingExtraction:New(maskControl:GetNamedChild("Refinement"), control:GetNamedChild("Refinement"), self, REFINEMENT_ONLY, GAMEPAD_SMITHING_REFINE_SCENE)
    self.creationPanel = ZO_GamepadSmithingCreation:New(maskControl:GetNamedChild("Creation"), control:GetNamedChild("Creation"), self, GAMEPAD_SMITHING_CREATION_SCENE)
    self.improvementPanel = ZO_GamepadSmithingImprovement:New(maskControl:GetNamedChild("Improvement"), control:GetNamedChild("Improvement"), self, GAMEPAD_SMITHING_IMPROVEMENT_SCENE)
    self.deconstructionPanel = ZO_GamepadSmithingExtraction:New(maskControl:GetNamedChild("Deconstruction"), control:GetNamedChild("Deconstruction"), self, not REFINEMENT_ONLY, GAMEPAD_SMITHING_DECONSTRUCT_SCENE)
    self.researchPanel = ZO_GamepadSmithingResearch:New(maskControl:GetNamedChild("Research"), self, GAMEPAD_SMITHING_RESEARCH_SCENE)
    CONSOLIDATED_SMITHING_SET_SELECTION_GAMEPAD:SetScene(GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE)

    --Whenever we leave a specific mode scene (either through back or pressing start) reset to the root mode
    local specificModeSceneGroup = ZO_SceneGroup:New(GAMEPAD_SMITHING_REFINE_SCENE_NAME, GAMEPAD_SMITHING_CREATION_SCENE_NAME, GAMEPAD_SMITHING_DECONSTRUCT_SCENE_NAME, GAMEPAD_SMITHING_IMPROVEMENT_SCENE_NAME, GAMEPAD_SMITHING_RESEARCH_SCENE_NAME, GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE_NAME)
    specificModeSceneGroup:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_GROUP_HIDDEN then
            self:ResetMode()
        end
    end)

    self:InitializeModeList()
    self:InitializeKeybindStripDescriptors()

    -- We need to initialize with a tabbar because some modes will make use of it
    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    self:InitializeSetSelector()

    GAMEPAD_SMITHING_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            local craftingType = GetCraftingInteractionType()

            self.creationPanel:PerformDeferredInitialization()
            self.researchPanel:PerformDeferredInitialization()

            --The default index is different depending on whether or not we are at a consolidated station
            if ZO_Smithing_IsConsolidatedStationCraftingMode() then
                if HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner() and CONSOLIDATED_SMITHING_SET_DATA_MANAGER:DoesPlayerHaveValidAttunableCraftingStationToConsume() then
                    TriggerTutorial(TUTORIAL_TRIGGER_ADD_CONSOLIDATED_ITEM_SETS_SHOWN_GAMEPAD)
                end

                TriggerTutorial(TUTORIAL_TRIGGER_CONSOLIDATED_STATION_OPENED)

                -- Don't select item sets by default
                self.modeList:SetDefaultSelectedIndex(2)
                GAMEPAD_CRAFTING_RESULTS:SetContextualAnimationControl(CRAFTING_PROCESS_CONTEXT_CONSUME_ATTUNABLE_STATIONS, self.control)
            else
                self.modeList:SetDefaultSelectedIndex(1)
            end

            self:RefreshModeList(craftingType)

            self.resetUIs = self.resetUIs or self.oldCraftingType ~= craftingType

            self.refinementPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.creationPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.improvementPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.deconstructionPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.researchPanel:SetCraftingType(craftingType, self.oldCraftingType, self.resetUIs)
            self.oldCraftingType = craftingType

            self:ResetMode()
            if self.resetUIs then
                local DONT_ANIMATE = false
                local ALLOW_EVEN_IF_DISABLED = true
                self.modeList:SetDefaultIndexSelected(DONT_ANIMATE, ALLOW_EVEN_IF_DISABLED)
                self:RefreshSetSelector()
            end

            self:SetEnableSkillBar(true)

            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.modeList:Activate()

            local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(craftingType)

            --Capacity and item sets in the header are mutually exclusive. We will only show one
            local NO_TAB_BAR_ENTRIES = nil
            local showCapacity = not ZO_Smithing_IsConsolidatedStationCraftingMode()
            local showItemSets = ZO_Smithing_IsConsolidatedStationCraftingMode()
            ZO_GamepadCraftingUtils_SetupGenericHeader(self, titleString, NO_TAB_BAR_ENTRIES, showCapacity, showItemSets)
            ZO_GamepadCraftingUtils_RefreshGenericHeader(self)

            self.resetUIs = nil
        elseif newState == SCENE_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.modeList:Deactivate()
            self.setSelectorControl:SetHidden(true)

            self:DirtyAllPanels()

            self:SetEnableSkillBar(false)
            GAMEPAD_CRAFTING_RESULTS:SetContextualAnimationControl(CRAFTING_PROCESS_CONTEXT_CONSUME_ATTUNABLE_STATIONS, nil)
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
            local nextScene = SCENE_MANAGER:GetNextScene()
            for _, smithingSceneName in ipairs(self.smithingRelatedSceneNames) do
                if SCENE_MANAGER:IsShowing(smithingSceneName) or (nextScene ~= nil and nextScene:GetName() == smithingSceneName) then
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

    self.control:RegisterForEvent(EVENT_CONSOLIDATED_STATION_SETS_UPDATED, function()
        --Refresh and re-narrate the header if the unlocked sets change
        if GAMEPAD_SMITHING_ROOT_SCENE:IsShowing() and ZO_Smithing_IsConsolidatedStationCraftingMode() then
            ZO_GamepadCraftingUtils_RefreshGenericHeader(self)
            local NARRATE_HEADER = true
            SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.modeList, NARRATE_HEADER)
        end
    end)

    ZO_WRIT_ADVISOR_GAMEPAD:RegisterCallback("CycleActiveQuest", function()
        if GAMEPAD_SMITHING_ROOT_SCENE:IsShowing() then
            SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.modeList)
        end
    end)
end

function ZO_Smithing_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select mode
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            callback = function()
                local targetData = self.modeList:GetTargetData()
                self:SetMode(targetData.mode)
            end,
        },
        -- Add Set
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_ITEM_SET),
            visible = function()
                return ZO_Smithing_IsConsolidatedStationCraftingMode()
            end,
            enabled = function()
                if ZO_CraftingUtils_IsPerformingCraftProcess() then
                    return false
                end

                if not HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner() then
                    return false, GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_ERROR_HOUSE_OWNERSHIP)
                end

                if not CONSOLIDATED_SMITHING_SET_DATA_MANAGER:DoesPlayerHaveValidAttunableCraftingStationToConsume() then
                    return false, GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_ERROR_NO_ITEM)
                end

                return true
            end,
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("CONSOLIDATED_SMITHING_ADD_SETS_GAMEPAD")
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.modeList)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_Smithing_Gamepad:CreateModeEntry(name, mode, icon, shouldShowQuestPin)
    local data = ZO_GamepadEntryData:New(GetString(name), icon)
    data:SetIconTintOnSelection(true)
    data.mode = mode
    data.hasCraftingQuestPin = shouldShowQuestPin
    return data
end

function ZO_Smithing_Gamepad:AddModeEntry(entry)
    self.modeList:AddEntry("ZO_GamepadItemEntryTemplate", entry)
end

function ZO_Smithing_Gamepad:InitializeModeList()
    self.modeList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("MaskContainerList"))
    self.modeList:SetAlignToScreenCenter(true)
    self.modeList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    --This is an invisible entry in the list that is used to represent the set selector.
    self.setSelectionModeEntry = ZO_GamepadEntryData:New("")
    self.setSelectionModeEntry.mode = SMITHING_MODE_CONSOLIDATED_SET_SELECTION
    self.setSelectionModeEntry.narrationText = function(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_SMITHING_CONSOLIDATED_STATION_ITEM_SET_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.activeConsolidatedSetText))
        --Include the quest pin in the narration if one is supposed to be showing
        if not self.shouldImproveForQuest and self.consolidatedItemSetIdForQuest ~= nil then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_NARRATION_CRAFTING_QUEST_PIN_ICON_NARRATION)))
        end
        return narrations
    end

    self.refinementModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_REFINEMENT, SMITHING_MODE_REFINEMENT, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_refine.dds", function() return self.shouldRefineForQuest end)
    self.creationModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_CREATION, SMITHING_MODE_CREATION, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_create.dds", function() return self.shouldCraftForQuest end)
    self.deconstructionModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_DECONSTRUCTION, SMITHING_MODE_DECONSTRUCTION, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_deconstruct.dds")
    self.improvementModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_IMPROVEMENT, SMITHING_MODE_IMPROVEMENT, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_improve.dds", function() return self.shouldImproveForQuest end)
    self.researchModeEntry = self:CreateModeEntry(SI_SMITHING_TAB_RESEARCH, SMITHING_MODE_RESEARCH, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_research.dds")

    local narrationInfo =
    {
        canNarrate = function()
            return GAMEPAD_SMITHING_ROOT_SCENE:IsShowing()
        end,
        headerNarrationFunction = function()
            return ZO_GamepadGenericHeader_GetNarrationText(self.header, self.headerData)
        end,
        footerNarrationFunction = function()
            return self:GetFooterNarration()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.modeList, narrationInfo)

    self.modeList:SetOnSelectedDataChangedCallback(function(list)
        if list:IsActive() then
            self:RefreshSetSelector()
        end
    end)
end

function ZO_Smithing_Gamepad:InitializeSetSelector()
    self.setSelectorControl = self.header:GetNamedChild("SetSelector")
    self.setSelectorNameLabel = self.setSelectorControl:GetNamedChild("SetName")
    self.setSelectorQuestPin = self.setSelectorControl:GetNamedChild("QuestPin")
end

function ZO_Smithing_Gamepad:GetFooterNarration()
    local narrations = {}
    local skillInfoNarration = ZO_Skills_GetSkillInfoHeaderNarrationText(self.skillInfoBar)
    ZO_AppendNarration(narrations, skillInfoNarration)
    ZO_AppendNarration(narrations, ZO_WRIT_ADVISOR_GAMEPAD:GetNarrationText())
    return narrations
end

function ZO_Smithing_Gamepad:RefreshSetSelector()
    --Refresh the visual state of the set selector
    if ZO_Smithing_IsConsolidatedStationCraftingMode() then
        --If there is no active set id, assume we are using the default category
        local activeSetId = GetActiveConsolidatedSmithingItemSetId()
        local activeSetName = activeSetId ~= 0 and GetItemSetName(activeSetId) or GetString(SI_SMITHING_CONSOLIDATED_STATION_DEFAULT_CATEGORY_NAME)

        --Store off the set text for narration to use
        self.activeConsolidatedSetText = zo_strformat(SI_ITEM_SET_NAME_FORMATTER, activeSetName)
        self.setSelectorNameLabel:SetText(self.activeConsolidatedSetText)

        --Make it so the selector looks visibly selected or deselected base upon whether the invisible set selection entry is selected
        local targetData = self.modeList:GetTargetData()
        if targetData and targetData.mode == SMITHING_MODE_CONSOLIDATED_SET_SELECTION then
            self.setSelectorNameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            self.setSelectorNameLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        end

        --If we don't need to improve for the quest and we have a valid item set, show the quest pin on the selector
        if not self.shouldImproveForQuest and self.consolidatedItemSetIdForQuest ~= nil then
            self.setSelectorQuestPin:SetHidden(false)
        else
            self.setSelectorQuestPin:SetHidden(true)
        end

        self.setSelectorControl:SetHidden(false)
    else
        self.setSelectorControl:SetHidden(true)
    end
end

function ZO_Smithing_Gamepad:RefreshModeList(craftingType)
    self.modeList:Clear()
    if ZO_Smithing_IsConsolidatedStationCraftingMode() then
        self:AddModeEntry(self.setSelectionModeEntry)
    end
    self:AddModeEntry(self.refinementModeEntry)
    self:AddModeEntry(self.creationModeEntry)
    self:AddModeEntry(self.deconstructionModeEntry)
    self:AddModeEntry(self.improvementModeEntry)
    self:AddModeEntry(self.researchModeEntry)

    local recipeCraftingSystem = GetTradeskillRecipeCraftingSystem(craftingType)
    local recipeCraftingSystemNameStringId = _G["SI_RECIPECRAFTINGSYSTEM"..recipeCraftingSystem]
    local recipeModeEntry = self:CreateModeEntry(recipeCraftingSystemNameStringId, SMITHING_MODE_RECIPES, ZO_GetGamepadRecipeCraftingSystemMenuTextures(recipeCraftingSystem), function() return self.usesProvisioningForQuest end)
    self:AddModeEntry(recipeModeEntry)
    self.modeList:Commit()

    --Order matters: Do this after the mode list has been committed
    self:RefreshSetSelector()
end

function ZO_Smithing_Gamepad:ResetMode()
    self.mode = SMITHING_MODE_ROOT
end

function ZO_Smithing_Gamepad:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode
        if mode == SMITHING_MODE_RECIPES then
            GAMEPAD_PROVISIONER:EmbedInCraftingScene(self.smithingStationInteraction)
        else
            SCENE_MANAGER:Push(g_modeToSceneName[mode])
        end
        self:UpdateKeybindStrip()
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

function ZO_Smithing_Gamepad:UpdateKeybindStrip()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Smithing_Gamepad:UpdateQuestPins()
    if GAMEPAD_SMITHING_ROOT_SCENE:IsShowing() then
        self:RefreshModeList(GetCraftingInteractionType())
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
    ZO_Smithing_AddScene(GAMEPAD_SMITHING_CONSOLIDATED_SET_SELECTION_SCENE_NAME, SMITHING_GAMEPAD)
end
