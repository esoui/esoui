local SMITHING_SCENE_NAME = "smithing"

ZO_Smithing = ZO_Smithing_Common:Subclass()

function ZO_Smithing:Initialize(control)
    ZO_Smithing_Common.Initialize(self, control)

    self.refinementPanel = ZO_SmithingRefinement:New(self.control:GetNamedChild("RefinementPanel"), self)
    self.creationPanel = ZO_SmithingCreation:New(self.control:GetNamedChild("CreationPanel"), self)
    self.improvementPanel = ZO_SmithingImprovement:New(self.control:GetNamedChild("ImprovementPanel"), self)
    self.deconstructionPanel = ZO_SmithingExtraction:New(self.control:GetNamedChild("DeconstructionPanel"), self)
    self.researchPanel = ZO_SmithingResearch:New(self.control:GetNamedChild("ResearchPanel"), self)

    self.setContainer = self.control:GetNamedChild("SetContainer")
    self.setCategories = self.setContainer:GetNamedChild("Categories")
    self.unlockedSetsLabel = self.setContainer:GetNamedChild("UnlockedSetsRowValue")

    self.addSetsButton = self.setContainer:GetNamedChild("AddSetButton")
    self.addSetsButton:SetHandler("OnClicked", function(buttonControl, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_ADD_CONSOLIDATED_ITEM_SETS_SHOWN_POINTER_BOX)
            ZO_Dialogs_ShowDialog("CONSOLIDATED_SMITHING_ADD_SETS")
        end
    end)

    self.addSetsButton:SetHandler("OnMouseEnter", function(buttonControl)
        local errorString
        if not HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner() then
            errorString = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_ERROR_HOUSE_OWNERSHIP)
        elseif not CONSOLIDATED_SMITHING_SET_DATA_MANAGER:DoesPlayerHaveValidAttunableCraftingStationToConsume() then
            errorString = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_ERROR_NO_ITEM)
        end

        if errorString then
            InitializeTooltip(InformationTooltip, buttonControl, RIGHT, 0, 0)
            SetTooltipText(InformationTooltip, ZO_ERROR_COLOR:Colorize(errorString))
        end
    end)

    self.addSetsButton:SetHandler("OnMouseExit", function(buttonControl)
        ClearTooltip(InformationTooltip)
    end)

    local function CraftingProcessCallback(shouldEnable)
        self:RefreshAddItemSetButton(shouldEnable)
    end
    ZO_CraftingUtils_ConnectButtonToCraftingProcess(self.addSetsButton, CraftingProcessCallback)

    self.addSetsTutorialAnchor = ZO_Anchor:New(RIGHT, self.addSetsButton, LEFT, -10, 0)

    self:InitializeSetCategories()
    self:InitializeAddSetsDialog()
    self:InitializeKeybindStripDescriptors()
    self:InitializeModeBar()

    SMITHING_SCENE = self:CreateInteractScene(SMITHING_SCENE_NAME)
    SMITHING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_ADD_CONSOLIDATED_ITEM_SETS_SHOWN_POINTER_BOX, self.control, SMITHING_FRAGMENT, self.addSetsTutorialAnchor)

            if ZO_Smithing_IsConsolidatedStationCraftingMode() then
                TriggerTutorial(TUTORIAL_TRIGGER_CONSOLIDATED_STATION_OPENED)
                CONSOLIDATED_SMITHING_SET_DATA_MANAGER:SetSearchString(self.setSearchBox:GetText())
            end

            local craftingType = GetCraftingInteractionType()
            ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.control:GetNamedChild("SkillInfo"), craftingType)

            local isCraftingTypeDifferent = not self.interactingWithSameStation or self.oldCraftingType ~= craftingType
            self.refinementPanel:SetCraftingType(craftingType, self.oldCraftingType, isCraftingTypeDifferent)
            self.creationPanel:SetCraftingType(craftingType, self.oldCraftingType, isCraftingTypeDifferent)
            self.improvementPanel:SetCraftingType(craftingType, self.oldCraftingType, isCraftingTypeDifferent)
            self.deconstructionPanel:SetCraftingType(craftingType, self.oldCraftingType, isCraftingTypeDifferent)
            self.researchPanel:SetCraftingType(craftingType, self.oldCraftingType, isCraftingTypeDifferent)
            self.oldCraftingType = craftingType

            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

           self:AddTabsToMenuBar(craftingType, isCraftingTypeDifferent)
        elseif newState == SCENE_HIDDEN then
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

            self:DirtyAllPanels()

            ZO_Skills_UntieSkillInfoHeaderToCraftingSkill(self.control:GetNamedChild("SkillInfo"))

            CRAFTING_RESULTS:SetCraftingTooltip(nil)
            CRAFTING_RESULTS:SetContextualAnimationControl(CRAFTING_PROCESS_CONTEXT_CONSUME_ATTUNABLE_STATIONS, nil)
        end
    end)

    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, sameStation, craftingMode)
        if ZO_Smithing_IsSmithingStation(craftingType, craftingMode) and not IsInGamepadPreferredMode() then
            self.interactingWithSameStation = sameStation
            SCENE_MANAGER:Show(SMITHING_SCENE_NAME)
        end
    end)

    self.control:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, craftingMode)
        if ZO_Smithing_IsSmithingStation(craftingType, craftingMode) and not IsInGamepadPreferredMode() then
            SCENE_MANAGER:Hide(SMITHING_SCENE_NAME)
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
        if self.mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
            self:RefreshUnlockedSets()
            --If a craft is in progress, wait until it finishes before refreshing
            if ZO_CraftingUtils_IsPerformingCraftProcess() then
                self.setCategoriesDirty = true
            else
                self:RefreshSetCategories()
            end
        end
    end)

    CONSOLIDATED_SMITHING_SET_DATA_MANAGER:RegisterCallback("UpdateSearchResults", function() self:OnUpdateSearchResults() end)

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end
    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    self:InitializeFilters()
end

function ZO_Smithing:InitializeFilters()
    self.setSearchBox = self.setContainer:GetNamedChild("SearchBox")
    ZO_CraftingUtils_ConnectEditBoxToCraftingProcess(self.setSearchBox)

    local function OnFilterChanged()
        self.savedVars.hideLockedChecked = ZO_CheckButton_IsChecked(self.hideLockedCheckBox)
        if SMITHING_FRAGMENT:IsShowing() and self.mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
            self:RefreshSetFilters()
            self:RefreshSetCategories()
        end
    end

    self.hideLockedCheckBox = self.setContainer:GetNamedChild("HideLocked")
    ZO_CheckButton_SetToggleFunction(self.hideLockedCheckBox, OnFilterChanged)
    ZO_CheckButton_SetLabelText(self.hideLockedCheckBox, GetString(SI_SMITHING_CONSOLIDATED_STATION_HIDE_LOCKED))

    -- crappy hack to make sure no one gets in a bad state because we have connected the checkbuttons to the smithing process,
    -- which means we are going to logically set the state of the check buttons without user input, which will interfere with
    -- the player that tries to mouse down on a checkbutton and then start the craft, resulting in a bad state of being stuck in PRESSED
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        ZO_CheckButton_SetCheckState(self.hideLockedCheckBox, self.savedVars.hideLockedChecked)
    end)

    --This needs to happen AFTER the above CraftingAnimationsStarted callback is registered, so the disabled state doesn't get clobbered by setting the check state for the button
    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.hideLockedCheckBox)

    self.setFilters = {}
end

function ZO_Smithing:InitializeSetCategories()
    local categoryTree = ZO_Tree:New(self.setCategories:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function BaseTreeHeaderIconSetup(control, categoryData, open, enabled)
        local normalIcon, pressedIcon, mouseoverIcon = categoryData:GetKeyboardIcons()
        --We do not have a disabled icon, so  manually desaturate the icon when disabled
        if not enabled then
            control.icon:SetDesaturation(1)
            control.icon:SetTexture(normalIcon)
        else
            control.icon:SetDesaturation(0)
            control.icon:SetTexture(open and pressedIcon or normalIcon)
        end
        control.iconHighlight:SetTexture(mouseoverIcon)
        ZO_IconHeader_Setup(control, open, enabled)
    end

    local function BaseTreeHeaderSetup(node, control, categoryData, open, enabled)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(categoryData:GetFormattedName())
        BaseTreeHeaderIconSetup(control, categoryData, open, enabled)
    end

    local function TreeHeaderSetup_Child(node, control, categoryData, open, userRequested, enabled)
        BaseTreeHeaderSetup(node, control, categoryData, open, enabled)
        if not control.statusIcon then
            control.statusIcon = control:GetNamedChild("StatusIcon")
        end

        control.statusIcon:ClearIcons()

        if not self.shouldImproveForQuest and self.consolidatedItemSetIdForQuest then
            --If the category contains the item set for the currently tracked quest, include a quest pin
            local setDataForQuest = categoryData:GetSetDataByItemSetId(self.consolidatedItemSetIdForQuest)
            if setDataForQuest then
                control.statusIcon:AddIcon("EsoUI/Art/WritAdvisor/advisor_trackedPin_icon.dds")
            end
        end

        control.statusIcon:Show()
    end

    local function TreeHeaderSetup_Childless(node, control, categoryData, open, userRequested, enabled)
        --Leaf nodes are never open, so use node.selected instead
        BaseTreeHeaderSetup(node, control, categoryData, node.selected, enabled)
    end

    --When a set or the default category has been selected
    local function TreeEntryOnSelected(control, setOrCategoryData, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected then
            self.selectedConsolidatedSetData = setOrCategoryData
            self:RefreshActiveConsolidatedSmithingSet()
        end
    end

    --When the default category has been selected
    local function TreeEntryOnSelected_Childless(control, categoryData, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, categoryData, selected, reselectingDuringRebuild)
        --If we were able to select the tree entry it must be enabled
        local ENABLED = true
        BaseTreeHeaderIconSetup(control, categoryData, selected, ENABLED)
    end

    local function TreeEntrySetup(node, control, setData, open, userRequested, enabled)
        local isUnlocked = setData:IsUnlocked()
        node:SetEnabled(isUnlocked)
        --The enabled parameter here is the enabled state of the tree as a whole, so we need to check both that and the unlocked state
        control:SetEnabled(isUnlocked and enabled)
        control:SetSelected(node.selected)
        control:SetText(setData:GetFormattedName())

        if not control.statusIcon then
            control.statusIcon = control:GetNamedChild("StatusIcon")
        end

        control.statusIcon:ClearIcons()

        if not isUnlocked then
            control.statusIcon:AddIcon(ZO_KEYBOARD_LOCKED_ICON)
        end

        if not self.shouldImproveForQuest and self.consolidatedItemSetIdForQuest == setData:GetItemSetId() then
            control.statusIcon:AddIcon("EsoUI/Art/WritAdvisor/advisor_trackedPin_icon.dds")
        end

        control.statusIcon:Show()
    end

    local function CategoryEqualityFunction(leftData, rightData)
        return leftData:GetId() == rightData:GetId()
    end

    local function SetEqualityFunction(leftData, rightData)
        return leftData:GetItemSetId() == rightData:GetItemSetId()
    end

    local CHILD_INDENT = 76
    local CHILD_SPACING = 0
    local NO_SELECTED_CALLBACK = nil
    categoryTree:AddTemplate("ZO_StatusIconHeader", TreeHeaderSetup_Child, NO_SELECTED_CALLBACK, CategoryEqualityFunction, CHILD_INDENT, CHILD_SPACING)
    categoryTree:AddTemplate("ZO_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless, CategoryEqualityFunction)
    categoryTree:AddTemplate("ZO_ConsolidatedSmithingSetNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, SetEqualityFunction)

    categoryTree:SetExclusive(true)
    categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    self.categoryTree = categoryTree

    ZO_CraftingUtils_ConnectTreeToCraftingProcess(self.categoryTree)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function()
        if self.setCategoriesDirty then
            self:RefreshSetCategories()
        end
    end)

    self.setNodeLookupData = {}
end

function ZO_Smithing:InitializeAddSetsDialog()
    ZO_Dialogs_RegisterCustomDialog("CONSOLIDATED_SMITHING_ADD_SETS",
    {
        customControl = function() return ZO_InventorySlot_GetMultiSelectItemListDialog():GetControl() end,
        setup = function(dialog, data) self:SetupAddSetsDialog(data) end,
        title =
        {
            text = SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_TITLE,
        },
        buttons =
        {
            {
                control = ZO_InventorySlot_GetMultiSelectItemListDialog():GetButton(1),
                text = SI_DIALOG_CONFIRM,
                callback = function()
                    local itemsToAdd = self.consolidatedSetsListDialog:GetSelectedItems()
                    PrepareConsumeAttunableStationsMessage()
                    
                    --Add each item to the consume message
                    local addedAllItems = true
                    for _, item in ipairs(itemsToAdd) do
                        if not AddItemToConsumeAttunableStationsMessage(item.bag, item.index) then
                            addedAllItems = false
                            break
                        end
                    end

                    --If all items were added sucessfully, proceed with the consume
                    if addedAllItems then
                        SendConsumeAttunableStationsMessage()
                    end
                end,
            },
            {
                control = ZO_InventorySlot_GetMultiSelectItemListDialog():GetButton(2),
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

function ZO_Smithing:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Perform craft/extract/improve
        {
            name = function()
                if self.mode == SMITHING_MODE_CREATION then
                    local cost = GetCostToCraftSmithingItem(self.creationPanel:GetAllCraftingParameters())
                    return ZO_CraftingUtils_GetCostToCraftString(cost)
                elseif self.mode == SMITHING_MODE_REFINEMENT then
                    local action = self.refinementPanel:IsMultiExtract() and "SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE" or "SI_DECONSTRUCTACTIONNAME"
                    return GetString(action, DECONSTRUCT_ACTION_NAME_REFINE)
                elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
                    local action = self.deconstructionPanel:IsMultiExtract() and "SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE" or "SI_DECONSTRUCTACTIONNAME"
                    return GetString(action, DECONSTRUCT_ACTION_NAME_DECONSTRUCT)
                elseif self.mode == SMITHING_MODE_IMPROVEMENT then
                    return GetString(SI_SMITHING_IMPROVE)
                elseif self.mode == SMITHING_MODE_RESEARCH then
                    return GetString(SI_ITEM_ACTION_RESEARCH)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                if self.mode == SMITHING_MODE_REFINEMENT then
                    self.refinementPanel:ConfirmRefine()
                elseif self.mode == SMITHING_MODE_CREATION then
                    self.creationPanel:ConfirmCreate()
                elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
                    self.deconstructionPanel:ConfirmExtractAll()
                elseif self.mode == SMITHING_MODE_IMPROVEMENT then
                    self.improvementPanel:Improve()
                elseif self.mode == SMITHING_MODE_RESEARCH then
                    self.researchPanel:Research()
                end
            end,

            enabled = function()
                if ZO_CraftingUtils_IsPerformingCraftProcess() then
                    return false
                end
                if self.mode == SMITHING_MODE_REFINEMENT then
                    return self.refinementPanel:IsExtractable()
                elseif self.mode == SMITHING_MODE_CREATION then
                    return self.creationPanel:ShouldCraftButtonBeEnabled()
                elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
                    return self.deconstructionPanel:IsExtractable()
                elseif self.mode == SMITHING_MODE_IMPROVEMENT then
                    return self.improvementPanel:IsImprovable()
                elseif self.mode == SMITHING_MODE_RESEARCH then
                    return self.researchPanel:IsResearchable()
                end
            end,
        },

        -- Clear selections / Cancel Research
        {
            name = function()
                if self.mode == SMITHING_MODE_RESEARCH then
                    return GetString(SI_CRAFTING_CANCEL_RESEARCH)
                else
                    return GetString(SI_CRAFTING_CLEAR_SELECTIONS)
                end
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                if self.mode == SMITHING_MODE_REFINEMENT then
                    self.refinementPanel:ClearSelections()
                elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
                    self.deconstructionPanel:ClearSelections()
                elseif self.mode == SMITHING_MODE_IMPROVEMENT then
                    self.improvementPanel:ClearSelections()
                elseif self.mode == SMITHING_MODE_RESEARCH then
                    return self.researchPanel:CancelResearch()
                end 
            end,

            visible = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then 
                    if self.mode == SMITHING_MODE_REFINEMENT then
                        return self.refinementPanel:HasSelections() 
                    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
                        return self.deconstructionPanel:HasSelections() 
                    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
                        return self.improvementPanel:HasSelections() 
                    elseif self.mode == SMITHING_MODE_RESEARCH then
                        return self.researchPanel:CanCancelResearch()
                    end 
                end
            end,
        },

        -- Crown Store opening action
        {
            name = function()
                if self.mode == SMITHING_MODE_CREATION then
                    return GetString(SI_SMITHING_BUY_CRAFTING_ITEMS)
                end
            end,

            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                if self.mode == SMITHING_MODE_CREATION then
                    self.creationPanel:BuyCraftingItems()
                end
            end,

            visible = function()
                if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                    if self.mode == SMITHING_MODE_CREATION and not self.creationPanel:ShouldIgnoreStyleItems() then
                        return true
                    end
                    return false
                end
            end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_Smithing:InitializeModeBar()
    self.modeMenu = self.control:GetNamedChild("ModeMenu")
    self.modeBar = self.modeMenu:GetNamedChild("Bar")
    self.modeBarLabel = self.modeBar:GetNamedChild("Label")

    local function CreateModeData(name, mode, normal, pressed, highlight, disabled)
        return {
            categoryName = name,

            descriptor = mode,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            callback = function(tabData)
                self.modeBarLabel:SetText(GetString(name))
                self:SetMode(mode)
            end,
        }
    end

    self.refinementTab = CreateModeData(SI_SMITHING_TAB_REFINEMENT, SMITHING_MODE_REFINEMENT, "EsoUI/Art/Crafting/smithing_tabIcon_refine_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_refine_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_refine_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_refine_disabled.dds")
    self.creationTab = CreateModeData(SI_SMITHING_TAB_CREATION, SMITHING_MODE_CREATION, "EsoUI/Art/Crafting/smithing_tabIcon_creation_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_creation_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_creation_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_creation_disabled.dds")
    self.deconstructionTab = CreateModeData(SI_SMITHING_TAB_DECONSTRUCTION, SMITHING_MODE_DECONSTRUCTION, "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_up.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_down.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_over.dds", "EsoUI/Art/Crafting/enchantment_tabIcon_deconstruction_disabled.dds")
    self.improvementTab = CreateModeData(SI_SMITHING_TAB_IMPROVEMENT, SMITHING_MODE_IMPROVEMENT, "EsoUI/Art/Crafting/smithing_tabIcon_improve_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_improve_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_improve_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_improve_disabled.dds")
    self.researchTab = CreateModeData(SI_SMITHING_TAB_RESEARCH, SMITHING_MODE_RESEARCH, "EsoUI/Art/Crafting/smithing_tabIcon_research_up.dds", "EsoUI/Art/Crafting/smithing_tabIcon_research_down.dds", "EsoUI/Art/Crafting/smithing_tabIcon_research_over.dds", "EsoUI/Art/Crafting/smithing_tabIcon_research_disabled.dds")

    self.recipeTab =
    {
        descriptor = SMITHING_MODE_RECIPES,
        callback = function(tabData)
            self.modeBarLabel:SetText(GetString(tabData.categoryName))
            self:SetMode(SMITHING_MODE_RECIPES)
        end,
    }

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)
end

function ZO_Smithing:AddTabsToMenuBar(craftingType, isCraftingTypeDifferent)
    local oldMode = self.mode
    self.mode = nil
    
    local recipeCraftingSystem = GetTradeskillRecipeCraftingSystem(craftingType)
    local recipeCraftingSystemNameStringId = _G["SI_RECIPECRAFTINGSYSTEM"..recipeCraftingSystem]
    local normal, pressed, highlight, disabled = ZO_GetKeyboardRecipeCraftingSystemButtonTextures(recipeCraftingSystem)

    local recipeTab = self.recipeTab
    recipeTab.categoryName = recipeCraftingSystemNameStringId
    recipeTab.normal = normal
    recipeTab.pressed = pressed
    recipeTab.highlight = highlight
    recipeTab.disabled = disabled

    ZO_MenuBar_ClearButtons(self.modeBar)
    self.refinementButton = ZO_MenuBar_AddButton(self.modeBar, self.refinementTab)
    self.creationButton = ZO_MenuBar_AddButton(self.modeBar, self.creationTab)
    ZO_MenuBar_AddButton(self.modeBar, self.deconstructionTab)
    self.improvementButton = ZO_MenuBar_AddButton(self.modeBar, self.improvementTab)
    ZO_MenuBar_AddButton(self.modeBar, self.researchTab)
    self.recipeButton = ZO_MenuBar_AddButton(self.modeBar, self.recipeTab)

    if isCraftingTypeDifferent or not oldMode then
        self.selectedConsolidatedSetData = nil
        if ZO_Smithing_IsConsolidatedStationCraftingMode() then
            ZO_MenuBar_SelectDescriptor(self.modeBar, SMITHING_MODE_CREATION)
        else
            ZO_MenuBar_SelectDescriptor(self.modeBar, SMITHING_MODE_REFINEMENT)
        end
    else
        ZO_MenuBar_SelectDescriptor(self.modeBar, oldMode)
    end
end

function ZO_Smithing:AddInventoryAdditionalFilterByMode(smithingMode, additionalFilterFunction)
    if smithingMode == SMITHING_MODE_REFINEMENT then
        if self.refinementPanel.inventory then
            self.refinementPanel.inventory.additionalFilter = additionalFilterFunction
        end
    elseif smithingMode == SMITHING_MODE_DECONSTRUCTION then
        if self.deconstructionPanel.inventory then
            self.deconstructionPanel.inventory.additionalFilter = additionalFilterFunction
        end
    elseif smithingMode == SMITHING_MODE_IMPROVEMENT then
        if self.improvementPanel.inventory then
            self.improvementPanel.inventory.additionalFilter = additionalFilterFunction
        end
    end
end

function ZO_Smithing:SetupSavedVars()
    local defaults =
    {
        hideLockedChecked = false,
    }
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "ConsolidatedSmithing", defaults)

    ZO_CheckButton_SetCheckState(self.hideLockedCheckBox, self.savedVars.hideLockedChecked)
end

function ZO_Smithing:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    if self.mode == SMITHING_MODE_REFINEMENT then
        self.refinementPanel:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_IMPROVEMENT then
        self.improvementPanel:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    elseif self.mode == SMITHING_MODE_DECONSTRUCTION then
        self.deconstructionPanel:OnItemReceiveDrag(slotControl, bagId, slotIndex)
    end
end

function ZO_Smithing:GetBackgroundFragmentGroupForMode(mode)
    if mode then
        --Creation uses a different background fragment group at consolidated stations
        if mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
            return { RIGHT_BG_FRAGMENT, TREE_UNDERLAY_FRAGMENT }
        else
            return { RIGHT_PANEL_BG_FRAGMENT }
        end
    end
end

function ZO_Smithing:RefreshModeMenuAnchors()
    local modeBackground
    if self.mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
        modeBackground = ZO_SharedRightBackground
    else
        modeBackground = ZO_SharedRightPanelBackground
    end

    --The mode menu anchors slightly differently depending on the background
    self.modeMenu:ClearAnchors()
    local DIVIDER_OFFSET_X = 40
    self.modeMenu:SetAnchor(TOPLEFT, modeBackground, nil, DIVIDER_OFFSET_X)
    self.modeMenu:SetAnchor(TOPRIGHT, modeBackground, nil, -DIVIDER_OFFSET_X)
end

function ZO_Smithing:AddSetCategory(categoryData, filters)
    local tree = self.categoryTree
    local nodeTemplate

    if categoryData:GetNumSets() > 0 then
        nodeTemplate = "ZO_StatusIconHeader"
    else
        nodeTemplate = "ZO_StatusIconChildlessHeader"
    end

    local entryData = ZO_EntryData:New(categoryData)
    --First add the category node
    entryData.node = tree:AddNode(nodeTemplate, entryData)

    --Loop through each set in the category and add each one as a child
    for _, setData in categoryData:SetIterator(filters) do
        local setEntryData = ZO_EntryData:New(setData)
        setEntryData.node = tree:AddNode("ZO_ConsolidatedSmithingSetNavigationEntry", setEntryData, entryData.node)
        self.setNodeLookupData[setEntryData:GetItemSetId()] = setEntryData.node
    end
end

function ZO_Smithing:RefreshUnlockedSets()
    if self.mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
        local totalSets = GetNumConsolidatedSmithingSets()
        local unlockedSets = GetNumUnlockedConsolidatedSmithingSets()
        self.unlockedSetsLabel:SetText(zo_strformat(SI_SMITHING_CONSOLIDATED_STATION_ITEM_SETS_UNLOCKED_VALUE_FORMATTER, unlockedSets, totalSets))
        self:RefreshAddItemSetButton()
    end
end

function ZO_Smithing:RefreshSetCategories()
    self.categoryTree:Reset()
    ZO_ClearTable(self.setNodeLookupData)

    if self.mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
        self.setContainer:SetHidden(false)

        --Add the special default category first
        self:AddSetCategory(CONSOLIDATED_SMITHING_DEFAULT_CATEGORY_DATA)

        local categoryList = CONSOLIDATED_SMITHING_SET_DATA_MANAGER:GetSortedCategories()
        for _, categoryData in ipairs(categoryList) do
            --Only add categories that have at least one child that passes the current filters
            if categoryData:AnyChildPassesFilters(self.setFilters) then
                self:AddSetCategory(categoryData, self.setFilters)
            end
        end

        local nodeToSelect = nil
        if self.selectedConsolidatedSetData and not self.selectedConsolidatedSetData:IsInstanceOf(ZO_ConsolidatedSmithingDefaultCategoryData) then
            nodeToSelect = self.setNodeLookupData[self.selectedConsolidatedSetData:GetItemSetId()]
        end

        self.categoryTree:Commit(nodeToSelect)
        CRAFTING_RESULTS:SetContextualAnimationControl(CRAFTING_PROCESS_CONTEXT_CONSUME_ATTUNABLE_STATIONS, self.setContainer)

        self.setCategoriesDirty = false
    else
        self.setContainer:SetHidden(true)
    end
end

function ZO_Smithing:RefreshActiveConsolidatedSmithingSet()
    --If this is a consolidated crafting station, make sure the active set matches the current selection
    if ZO_Smithing_IsConsolidatedStationCraftingMode() then
        local selectedData = self.categoryTree:GetSelectedData()
        if selectedData then
            --The default category is handled slightly differently
            if selectedData:IsInstanceOf(ZO_ConsolidatedSmithingDefaultCategoryData) then
                --Default category
                local NO_ITEM_SET = nil
                SetActiveConsolidatedSmithingSetByIndex(NO_ITEM_SET)
            else
                --Standard set
                SetActiveConsolidatedSmithingSetByIndex(selectedData:GetSetIndex())
            end

            self.creationPanel:DirtyAllLists()
            self.creationPanel:RefreshAvailableFilters()
        end
    end
end

do
    --Sort the items alphabetically
    local function SortComparator(left, right)
        return left.data.name < right.data.name
    end

    function ZO_Smithing:SetupAddSetsDialog(data)
        self.consolidatedSetsListDialog = ZO_InventorySlot_GetMultiSelectItemListDialog()

        self.consolidatedSetsListDialog:SetAboveText(GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_DESCRIPTION))
        self:RefreshAddSetsDialogBelowText()
        self.consolidatedSetsListDialog:SetEmptyListText("")

        self.consolidatedSetsListDialog:ClearList()

        --Generate the initial list of consumable items.
        local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, CanItemBeConsumedByConsolidatedStation)

        local listedSets = {}
        for itemId, itemInfo in pairs(virtualInventoryList) do
            local itemSetId = GetSmithingStationItemSetIdFromItem(itemInfo.bag, itemInfo.index)
            --Filter out any stations with the same set as a station we have already added to the list
            if not listedSets[itemSetId] then
                itemInfo.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(itemInfo.bag, itemInfo.index))
                --Force the stack count to 1 so we dont show the number in the dialog
                itemInfo.stack = 1
                self.consolidatedSetsListDialog:AddListItem(itemInfo)
                listedSets[itemSetId] = true
            end
        end

        self.consolidatedSetsListDialog:CommitList(SortComparator)

        if not self.selectAllButton then
            self.selectAllButton = self.control:GetNamedChild("AddSetsDialogSelectAllButton")
            self.selectAllButton:SetHandler("OnClicked", function()
                self.consolidatedSetsListDialog:SelectAll()
                self:RefreshAddSetsDialogBelowText()
            end)
        end

        self.consolidatedSetsListDialog:AddCustomControl(self.selectAllButton, LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM)
        self.selectAllButton:SetHidden(false)
        self.consolidatedSetsListDialog:SetOnSelectedCallback(function(selectedData)
            PlaySound(SOUNDS.DEFAULT_CLICK)
            self:RefreshAddSetsDialogBelowText()
        end)
    end
end

function ZO_Smithing:RefreshAddSetsDialogBelowText()
    if self.consolidatedSetsListDialog then
        local belowText
        local numSelected = #self.consolidatedSetsListDialog:GetSelectedItems()
        if numSelected > 1 then
            belowText = zo_strformat(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_MULTIPLE_SELECTED_TEXT, numSelected)
        else
            belowText = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_SELECTED_TEXT)
        end
        self.consolidatedSetsListDialog:SetBelowText(belowText)
    end
end

function ZO_Smithing:RefreshAddItemSetButton(shouldEnable)
    if shouldEnable == nil then
        shouldEnable = not ZO_CraftingUtils_IsPerformingCraftProcess()
    end

    if self.mode == SMITHING_MODE_CREATION then
        local hasConsumableItems = CONSOLIDATED_SMITHING_SET_DATA_MANAGER:DoesPlayerHaveValidAttunableCraftingStationToConsume()
        local ownsStation = HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()

        local enabled = shouldEnable and hasConsumableItems and ownsStation
        self.addSetsButton:SetEnabled(enabled)

        if enabled then
            TriggerTutorial(TUTORIAL_TRIGGER_ADD_CONSOLIDATED_ITEM_SETS_SHOWN_POINTER_BOX)
        end
    end
end

function ZO_Smithing:SetMode(mode)
    if self.mode ~= mode then
        local oldMode = self.mode
        self.mode = mode

        if oldMode == SMITHING_MODE_DECONSTRUCTION then
            self.deconstructionPanel:ClearSelections()
        end

        if oldMode == SMITHING_MODE_CREATION then
            TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_ADD_CONSOLIDATED_ITEM_SETS_SHOWN_POINTER_BOX)
        end

        CRAFTING_RESULTS:SetCraftingTooltip(nil)
        CRAFTING_RESULTS:SetContextualAnimationControl(CRAFTING_PROCESS_CONTEXT_CONSUME_ATTUNABLE_STATIONS, nil)

        if mode == SMITHING_MODE_RECIPES then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            PROVISIONER:EmbedInCraftingScene()
        else
            if oldMode == SMITHING_MODE_RECIPES then
                PROVISIONER:RemoveFromCraftingScene()
                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            end
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            TriggerTutorial(self.GetTutorialTrigger(self, GetCraftingInteractionType(), mode))
        end

        --Order matters. Remove the old background fragment group before adding the new one
        local oldModeBackgroundFragmentGroup = self:GetBackgroundFragmentGroupForMode(oldMode)
        if oldModeBackgroundFragmentGroup then
            SCENE_MANAGER:RemoveFragmentGroup(oldModeBackgroundFragmentGroup)
        end

        local newModeBackgroundFragmentGroup = self:GetBackgroundFragmentGroupForMode(mode)
        if newModeBackgroundFragmentGroup then
            SCENE_MANAGER:AddFragmentGroup(newModeBackgroundFragmentGroup)
        end

        self.refinementPanel:SetHidden(mode ~= SMITHING_MODE_REFINEMENT)
        self.creationPanel:SetHidden(mode ~= SMITHING_MODE_CREATION)
        self.improvementPanel:SetHidden(mode ~= SMITHING_MODE_IMPROVEMENT)
        self.deconstructionPanel:SetHidden(mode ~= SMITHING_MODE_DECONSTRUCTION)
        self.researchPanel:SetHidden(mode ~= SMITHING_MODE_RESEARCH)

        self:RefreshModeMenuAnchors()
        self:RefreshUnlockedSets()
        self:RefreshSetFilters()
        self:RefreshSetCategories()
    end
end

function ZO_Smithing:UpdateSharedKeybindStrip()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Smithing:GetResearchPanel()
    return self.researchPanel
end

function ZO_Smithing:UpdateQuestPins()
    if self.refinementButton then
        self.refinementButton.questPin:SetHidden(not self.shouldRefineForQuest)
    end

    if self.creationButton then
        local shouldShowQuestPin = self.shouldCraftForQuest or (not self.shouldImproveForQuest and self.consolidatedItemSetIdForQuest ~= nil)
        self.creationButton.questPin:SetHidden(not shouldShowQuestPin)
    end

    if self.improvementButton then
        self.improvementButton.questPin:SetHidden(not self.shouldImproveForQuest)
    end

    if self.recipeButton then
        self.recipeButton.questPin:SetHidden(not self.usesProvisioningForQuest)
    end

    if self.mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
        self.categoryTree:RefreshVisible()
    end
end

function ZO_Smithing:RefreshSetFilters()
    ZO_ClearNumericallyIndexedTable(self.setFilters)
    if CONSOLIDATED_SMITHING_SET_DATA_MANAGER:HasSearchFilter() then
        table.insert(self.setFilters, ZO_ConsolidatedSmithingSetData.IsSearchResult)
    end

    if self.savedVars.hideLockedChecked then
        table.insert(self.setFilters, ZO_ConsolidatedSmithingSetData.IsUnlocked)
    end
end

function ZO_Smithing:OnUpdateSearchResults()
    if SMITHING_FRAGMENT:IsShowing() and self.mode == SMITHING_MODE_CREATION and ZO_Smithing_IsConsolidatedStationCraftingMode() then
        self:RefreshSetFilters()
        self:RefreshSetCategories()
    end
end

function ZO_Smithing_Initialize(control)
    SMITHING = ZO_Smithing:New(control)

    ZO_Smithing_AddScene(SMITHING_SCENE_NAME, SMITHING)
end

function ZO_ConsolidatedSmithingSetNavigationEntry_OnMouseEnter(control)
    ZO_SelectableLabel_OnMouseEnter(control)
    ClearTooltip(ItemTooltip)
    local setData = control.node.data
    if setData then
        InitializeTooltip(ItemTooltip, control, RIGHT, -25, 0)
        ItemTooltip:SetGenericItemSet(setData:GetItemSetId())
    end
end

function ZO_ConsolidatedSmithingSetNavigationEntry_OnMouseExit(control)
    ZO_SelectableLabel_OnMouseExit(control)
    ClearTooltip(ItemTooltip)
end

function ZO_ConsolidatedSmithingSets_Keyboard_OnSearchTextChanged(editBox)
    CONSOLIDATED_SMITHING_SET_DATA_MANAGER:SetSearchString(editBox:GetText())
end