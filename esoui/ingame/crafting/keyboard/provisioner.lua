ZO_Provisioner = ZO_SharedProvisioner:Subclass()

ZO_PROVISIONER_SLOT_ROW_WIDTH = 260
ZO_PROVISIONER_SLOT_ROW_HEIGHT = 58
ZO_PROVISIONER_SLOT_ICON_SIZE = 48
ZO_PROVISIONER_SLOT_PADDING_X = 5

function ZO_Provisioner:New(...)
    return ZO_SharedProvisioner.New(self, ...)
end

function ZO_Provisioner:Initialize(control)
    self.mainSceneName = "provisioner"
    ZO_SharedProvisioner.Initialize(self, control)

    self.resultTooltip = self.control:GetNamedChild("Tooltip")
    if IsChatSystemAvailableForCurrentPlatform() then
        local function OnTooltipMouseUp(control, button, upInside)
            if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
                ClearMenu()
                    
                local function AddLink()
                    local recipeListIndex, recipeIndex = self:GetSelectedRecipeListIndex(), self:GetSelectedRecipeIndex()
                    local link = ZO_LinkHandler_CreateChatLink(GetRecipeResultItemLink, recipeListIndex, recipeIndex)
                    ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                end

                AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)

                ShowMenu(self)
            end
        end

        self.resultTooltip:SetHandler("OnMouseUp", OnTooltipMouseUp)
        self.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", OnTooltipMouseUp)
    end

    self.multiCraftContainer = self.control:GetNamedChild("MultiCraftContainer")
    self.multiCraftSpinner = ZO_MultiCraftSpinner:New(self.multiCraftContainer:GetNamedChild("Spinner"))
    self.multiCraftSpinner:RegisterCallback("OnValueChanged", function()
        self:RefreshRecipeDetails()
    end)
    ZO_CraftingUtils_ConnectSpinnerToCraftingProcess(self.multiCraftSpinner)

    self:InitializeTabs()
    self:InitializeSettings()
    self:InitializeFilters()
    self:InitializeKeybindStripDescriptors()
    self:InitializeRecipeTree()
    self:InitializeDetails()

    ZO_InventoryInfoBar_ConnectStandardBar(self.control:GetNamedChild("InfoBar"))
    
    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local defaults = { haveIngredientsChecked = true, haveSkillsChecked = true, }

            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "Provisioner", defaults)

            ZO_CheckButton_SetCheckState(self.haveIngredientsCheckBox, self.savedVars.haveIngredientsChecked)
            ZO_CheckButton_SetCheckState(self.haveSkillsCheckBox, self.savedVars.haveSkillsChecked)
            self:DirtyRecipeList()
            
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end
    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    PROVISIONER_FRAGMENT = ZO_FadeSceneFragment:New(control)
    PROVISIONER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:ResetMultiCraftNumIterations()
            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(self.resultTooltip)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(nil)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)

            -- when we hide this fragment make sure to end the preview and toggle the camera back to normal, 
            -- since we may still be staying in the crafting scene
            if ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
                self:TogglePreviewMode()
            end
        end
    end)

    PROVISIONER_SCENE = self:CreateInteractScene(self.mainSceneName)
    PROVISIONER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:ConfigureFromSettings(ZO_Provisioner.PROVISIONING_SETTINGS)
            TriggerTutorial(TUTORIAL_TRIGGER_PROVISIONING_OPENED)
        end
    end)

    self.skillInfoHeader = self.control:GetNamedChild("SkillInfo")
    ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.skillInfoHeader, CRAFTING_TYPE_PROVISIONING)
end

--Settings
ZO_Provisioner.PROVISIONING_SETTINGS =
{
    tabsOffsetY = 10,
    selectedTabLabelFont = "ZoFontHeader4",
    selectedTabLabelOffsetY = 7,
    showProvisionerSkillLevel = true,
}

ZO_Provisioner.EMBEDDED_SETTINGS =
{
    tabsOffsetY = 58,
    selectedTabLabelFont = "ZoFontHeader2",
    selectedTabLabelOffsetY = 0,
    showProvisionerSkillLevel = false,
}

function ZO_Provisioner:InitializeSettings()
    local function GenerateTab(filterType, normal, pressed, highlight, disabled)
        local name = GetString("SI_PROVISIONERSPECIALINGREDIENTTYPE", filterType) 
        return {
            activeTabText = name,
            categoryName = name,

            descriptor = filterType,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            callback = function(tabData) self:OnTabFilterChanged(tabData) end,
        }
    end

    local provisioningSettings = ZO_Provisioner.PROVISIONING_SETTINGS
    local foodTab = GenerateTab(PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES, "EsoUI/Art/Crafting/provisioner_indexIcon_meat_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_meat_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_meat_over.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_meat_disabled.dds")
    local drinkTab = GenerateTab(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING, "EsoUI/Art/Crafting/provisioner_indexIcon_beer_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_beer_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_beer_over.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_beer_disabled.dds")
    local furnishingsTab = GenerateTab(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING, "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_over.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_disabled.dds")

    provisioningSettings.tabs = {}
    table.insert(provisioningSettings.tabs, foodTab)
    table.insert(provisioningSettings.tabs, drinkTab)
    table.insert(provisioningSettings.tabs, furnishingsTab)

    local embeddedSettings = ZO_Provisioner.EMBEDDED_SETTINGS
    embeddedSettings.tabs = {}
    table.insert(embeddedSettings.tabs, furnishingsTab)
end

function ZO_Provisioner:ConfigureFromSettings(settings)
    if self.settings ~= settings then
        self.settings = settings

        self.skillInfoHeader:SetHidden(not settings.showProvisionerSkillLevel)
        self.tabs:SetAnchor(TOPRIGHT, ZO_SharedRightPanelBackground, TOPRIGHT, -33, settings.tabsOffsetY)
        local selectedTabLabel = self.tabs:GetNamedChild("Label")
        selectedTabLabel:SetFont(settings.selectedTabLabelFont)
        selectedTabLabel:SetAnchor(RIGHT, nil, LEFT, -25, settings.selectedTabLabelOffsetY)
        ZO_MenuBar_ClearButtons(self.tabs)
        for _, tab in ipairs(settings.tabs) do
            ZO_MenuBar_AddButton(self.tabs, tab)
        end
        ZO_MenuBar_SelectDescriptor(self.tabs, settings.tabs[1].descriptor)
    end
end

function ZO_Provisioner:EmbedInCraftingScene()
    self:ConfigureFromSettings(ZO_Provisioner.EMBEDDED_SETTINGS)
    SCENE_MANAGER:AddFragment(PROVISIONER_FRAGMENT)
    self:DirtyRecipeList()
end

function ZO_Provisioner:RemoveFromCraftingScene()
    SCENE_MANAGER:RemoveFragment(PROVISIONER_FRAGMENT)
end

function ZO_Provisioner:ShouldShowForControlScheme()
    return not IsInGamepadPreferredMode()
end

function ZO_Provisioner:InitializeTabs()
    self.tabs = self.control:GetNamedChild("Tabs")
    self.activeTab = self.control:GetNamedChild("TabsLabel")
    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.tabs)
end

function ZO_Provisioner:OnTabFilterChanged(filterData)
    -- we are switching from the furnishing tab to another tab, make sure the end the preview if there is one
    if self.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING then
        if SYSTEMS:GetObject("itemPreview"):IsInteractionCameraPreviewEnabled() then
            self:TogglePreviewMode()
        end
    end
    self.activeTab:SetText(filterData.activeTabText)
    self.filterType = filterData.descriptor
    if self.savedVars then
        ZO_CheckButton_SetCheckState(self.haveIngredientsCheckBox, self.savedVars.haveIngredientsChecked)
        ZO_CheckButton_SetCheckState(self.haveSkillsCheckBox, self.savedVars.haveSkillsChecked)
    end
    self:ResetMultiCraftNumIterations()
    self:DirtyRecipeList()
end

function ZO_Provisioner:InitializeFilters()
    self.haveIngredientsCheckBox = self.control:GetNamedChild("HaveIngredients")
    self.haveSkillsCheckBox = self.control:GetNamedChild("HaveSkills")

    local function OnFilterChanged()
        self.savedVars.haveIngredientsChecked = ZO_CheckButton_IsChecked(self.haveIngredientsCheckBox)
        self.savedVars.haveSkillsChecked = ZO_CheckButton_IsChecked(self.haveSkillsCheckBox)
        self:DirtyRecipeList()
    end

    ZO_CheckButton_SetToggleFunction(self.haveIngredientsCheckBox, OnFilterChanged)
    ZO_CheckButton_SetToggleFunction(self.haveSkillsCheckBox, OnFilterChanged)

    ZO_CheckButton_SetLabelText(self.haveIngredientsCheckBox, GetString(SI_PROVISIONER_HAVE_INGREDIENTS))
    ZO_CheckButton_SetLabelText(self.haveSkillsCheckBox, GetString(SI_PROVISIONER_HAVE_SKILLS))

    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.haveIngredientsCheckBox)
    ZO_CraftingUtils_ConnectCheckBoxToCraftingProcess(self.haveSkillsCheckBox)
end

function ZO_Provisioner:InitializeKeybindStripDescriptors()
    self.mainKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Perform craft
        {
            name = function()
                local cost = GetCostToCraftProvisionerItem(self:GetSelectedRecipeListIndex(), self:GetSelectedRecipeIndex())
                return ZO_CraftingUtils_GetCostToCraftString(cost)
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                ZO_KeyboardCraftingUtils_RequestCraftingCreate(self, self:GetMultiCraftNumIterations())
            end,

            enabled = function()
                return self:ShouldCraftButtonBeEnabled()
            end,
        },

        --Toggle Preview
        {
            name = function()
                if not ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
                    return GetString(SI_CRAFTING_ENTER_PREVIEW_MODE)
                else
                    return GetString(SI_CRAFTING_EXIT_PREVIEW_MODE)
                end
            end,

            keybind = "UI_SHORTCUT_QUATERNARY",

            callback = function()
                self:TogglePreviewMode()
            end,

            visible = function()
                return self:CanPreviewRecipe(self:GetRecipeData())
            end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.mainKeybindStripDescriptor)
end

function ZO_Provisioner:InitializeRecipeTree()
    local navigationContainer = self.control:GetNamedChild("NavigationContainer")
    self.recipeTree = ZO_Tree:New(navigationContainer:GetNamedChild("ScrollChild"), 60, -10, 535)

    local function TreeHeaderSetup(node, control, data, open, userRequested, enabled)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetDimensionConstraints(0, 0, 260, 0)
        control.text:SetText(data.name)

        if not enabled then
            control.icon:SetDesaturation(1)
            control.icon:SetTexture(data.upIcon)
        elseif open then
            control.icon:SetDesaturation(0)
            control.icon:SetTexture(data.downIcon)
        else
            control.icon:SetDesaturation(0)
            control.icon:SetTexture(data.upIcon)
        end

        control.iconHighlight:SetTexture(data.overIcon)

        ZO_IconHeader_Setup(control, open, enabled)
    end
    local function TreeHeaderEquality(left, right)
        return left.recipeListIndex == right.recipeListIndex
    end
    self.recipeTree:AddTemplate("ZO_IconHeader", TreeHeaderSetup, nil, TreeHeaderEquality, nil, 0)

    local function TreeEntrySetup(node, control, data, open, userRequested, enabled)
        control.data = data
        control.meetsLevelReq = self:PassesTradeskillLevelReqs(data.tradeskillsLevelReqs)
        control.meetsQualityReq = self:PassesQualityLevelReq(data.qualityReq)
        control.enabled = enabled

        if data.maxIterationsForIngredients > 0 and enabled then
            control:SetText(zo_strformat(SI_PROVISIONER_RECIPE_NAME_COUNT, data.name, data.maxIterationsForIngredients))
        else
            control:SetText(zo_strformat(SI_PROVISIONER_RECIPE_NAME_COUNT_NONE, data.name))
        end
        
        control:SetEnabled(enabled)
        control:SetSelected(node:IsSelected())

        if WINDOW_MANAGER:GetMouseOverControl() == control then
            zo_callHandler(control, enabled and "OnMouseEnter" or "OnMouseExit")
        end
    end
    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected then
            self:RefreshRecipeDetails()
        end
    end
    local function TreeEntryEquality(left, right)
        return left.recipeListIndex == right.recipeListIndex and left.recipeIndex == right.recipeIndex and left.name == right.name
    end
    self.recipeTree:AddTemplate("ZO_ProvisionerNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.recipeTree:SetExclusive(true)
    self.recipeTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    ZO_CraftingUtils_ConnectTreeToCraftingProcess(self.recipeTree)

    self.noRecipesLabel = navigationContainer:GetNamedChild("NoRecipesLabel")
    
    self:DirtyRecipeList()
end

function ZO_Provisioner:InitializeDetails()
    self.detailsPane = self.control:GetNamedChild("Details")
    self.ingredientRowsContainer = self.detailsPane:GetNamedChild("Ingredients")
    self.ingredientRows = {}
    
    local ingredientAnchor = ZO_Anchor:New(TOPLEFT, self.ingredientRowsContainer, TOPLEFT, 0, 0)
    local NUM_INGREDIENTS_PER_ROW = 2
    local INGREDIENT_PAD_X = 15
    local INGREDIENT_PAD_Y = 15
    local INGREDIENT_INITIAL_OFFSET_X = 0
    local INGREDIENT_INITIAL_OFFSET_Y = 0

    for i = 1, GetMaxRecipeIngredients() do
        local control = CreateControlFromVirtual("$(parent)Slot", self.ingredientRowsContainer, "ZO_ProvisionerSlotRow", i)
        table.insert(self.ingredientRows, ZO_ProvisionerRow:New(self, control))
        ZO_Anchor_BoxLayout(ingredientAnchor, control, i - 1, NUM_INGREDIENTS_PER_ROW,
            INGREDIENT_PAD_X, INGREDIENT_PAD_Y,
            ZO_PROVISIONER_SLOT_ROW_WIDTH, ZO_PROVISIONER_SLOT_ROW_HEIGHT,
            INGREDIENT_INITIAL_OFFSET_X, INGREDIENT_INITIAL_OFFSET_Y)
    end
end

function ZO_Provisioner:ResetSelectedTab()
    self.settings = nil
end

function ZO_Provisioner:SetDetailsEnabled(enabled)
    for ingredientIndex, ingredientSlot in ipairs(self.ingredientRows) do
        ingredientSlot:SetEnabled(enabled)
    end
end

function ZO_Provisioner:RefreshRecipeList()
    self.recipeTree:Reset()

    local knowAnyRecipesInTab = false
    local hasRecipesWithFilter = false
    local requireIngredients = ZO_CheckButton_IsChecked(self.haveIngredientsCheckBox)
    local requireSkills = ZO_CheckButton_IsChecked(self.haveSkillsCheckBox)
    local craftingInteractionType = GetCraftingInteractionType()

    local recipeData = PROVISIONER_MANAGER:GetRecipeData()
    for _, recipeList in pairs(recipeData) do
        local parent
        for _, recipe in ipairs(recipeList.recipes) do
            if self:DoesRecipePassFilter(recipe.specialIngredientType, requireIngredients, recipe.maxIterationsForIngredients, requireSkills, recipe.tradeskillsLevelReqs, recipe.qualityReq, craftingInteractionType, recipe.requiredCraftingStationType) then
                parent = parent or self.recipeTree:AddNode("ZO_IconHeader", {
                    recipeListIndex = recipeList.recipeListIndex,
                    name = recipeList.recipeListName,
                    upIcon = recipeList.upIcon,
                    downIcon = recipeList.downIcon,
                    overIcon = recipeList.overIcon,
                    })
                
                self.recipeTree:AddNode("ZO_ProvisionerNavigationEntry", recipe, parent)
                hasRecipesWithFilter = true
            end
            knowAnyRecipesInTab = true
        end
    end

    self.recipeTree:Commit()

    self.noRecipesLabel:SetHidden(hasRecipesWithFilter)
    if not hasRecipesWithFilter then
        if knowAnyRecipesInTab then
            self.noRecipesLabel:SetText(GetString(SI_PROVISIONER_NONE_MATCHING_FILTER))
        else
            --If there are no recipes all the types show the same message.
            self.noRecipesLabel:SetText(GetString(SI_PROVISIONER_NO_RECIPES))
            ZO_CheckButton_SetChecked(self.haveIngredientsCheckBox)
            ZO_CheckButton_SetChecked(self.haveSkillsCheckBox)
        end
        self:RefreshRecipeDetails()
    end

    ZO_CheckButton_SetEnableState(self.haveIngredientsCheckBox, knowAnyRecipesInTab)
    ZO_CheckButton_SetEnableState(self.haveSkillsCheckBox, knowAnyRecipesInTab)
end

function ZO_Provisioner:GetRecipeData()
    return self.recipeTree:GetSelectedData()
end

function ZO_Provisioner:GetSelectedRecipeListIndex()
    local recipeData = self:GetRecipeData()
    if recipeData then
        return recipeData.recipeListIndex
    end
end

function ZO_Provisioner:GetSelectedRecipeIndex()
    local recipeData = self:GetRecipeData()
    if recipeData then
        return recipeData.recipeIndex
    end
end

function ZO_Provisioner:RefreshRecipeDetails()
    local recipeData = self:GetRecipeData()
    if recipeData then
        if not ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
            self.resultTooltip:SetHidden(false)
        end

        local recipeListIndex, recipeIndex = self:GetSelectedRecipeListIndex(), self:GetSelectedRecipeIndex()

        self.resultTooltip:ClearLines()
        self.resultTooltip:SetProvisionerResultItem(recipeListIndex, recipeIndex)

        local numIngredients = recipeData.numIngredients 
        for ingredientIndex, ingredientSlot in ipairs(self.ingredientRows) do
            if ingredientIndex > numIngredients then
                ingredientSlot:ClearItem()
            else
                local name, icon, requiredQuantity, _, quality = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)

                -- Scale the recipe ingredients to what will actually be used when you hit craft.
                -- If numIterations is 0 we should just show what ingredients you would need to craft once, instead.
                local numIterations = self:GetMultiCraftNumIterations()
                if numIterations > 1 then
                    requiredQuantity = requiredQuantity * numIterations
                end

                local ingredientCount = GetCurrentRecipeIngredientCount(recipeListIndex, recipeIndex, ingredientIndex) 
                ingredientSlot:SetItem(name, icon, ingredientCount, quality, requiredQuantity)
                ingredientSlot:SetItemIndices(recipeListIndex, recipeIndex, ingredientIndex)
            end
        end

        CRAFTING_RESULTS:SetTooltipAnimationSounds(recipeData.createSound)

        if ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() and self:CanPreviewRecipe(recipeData) then
            self:PreviewRecipe(recipeData)
        end
    else
        self.resultTooltip:SetHidden(true)

        for ingredientIndex, ingredientSlot in ipairs(self.ingredientRows) do
            ingredientSlot:ClearItem()
        end
    end

    self:UpdateMultiCraft()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_Provisioner:TogglePreviewMode()
    ITEM_PREVIEW_KEYBOARD:ToggleInteractionCameraPreview(FRAME_TARGET_CRAFTING_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, CRAFTING_PREVIEW_OPTIONS_FRAGMENT)
    if ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
        self.resultTooltip:SetHidden(true)
        self:SetMultiCraftHidden(true)
        self:PreviewRecipe(self:GetRecipeData())
    else
        self.resultTooltip:SetHidden(false)
        self:SetMultiCraftHidden(false)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_Provisioner:SetMultiCraftHidden(shouldBeHidden)
    self.multiCraftContainer:SetHidden(shouldBeHidden)
    self:RefreshRecipeDetails()
end

function ZO_Provisioner:GetMultiCraftNumIterations()
    -- while spinner is hidden, hard cap the iteration count at 1, so the player doesn't accidentally perform a multicraft without a visual cue that it will happen
    if self.multiCraftContainer:IsControlHidden() then
        return 1
    end
    return self.multiCraftSpinner:GetValue()
end

function ZO_Provisioner:ResetMultiCraftNumIterations()
    self.multiCraftSpinner:SetValue(1)
end

function ZO_Provisioner:UpdateMultiCraft()
    self.multiCraftSpinner:SetMinMax(1, self:GetMultiCraftMaxIterations())
    self.multiCraftSpinner:UpdateButtons()
end

ZO_ProvisionerRow = ZO_Object:Subclass()

function ZO_ProvisionerRow:New(...)
    local provisionerSlot = ZO_Object.New(self)
    provisionerSlot:Initialize(...)
    return provisionerSlot
end

function ZO_ProvisionerRow:Initialize(owner, control)
    self.owner = owner
    self.control = control
    self.enabled = true

    self.icon = control:GetNamedChild("Icon")
    self.nameLabel = control:GetNamedChild("Name")
    self.countControl = control:GetNamedChild("Count")
    local DIVIDER_THICKNESS = 2
    self.countFractionDisplay = ZO_FractionDisplay:New(self.countControl, "ZoFontWinH4", DIVIDER_THICKNESS)
    self.countFractionDisplay:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    self.countDividerTexture = self.countControl:GetNamedChild("Divider")
end

function ZO_ProvisionerRow:SetItemIndices(recipeListIndex, recipeIndex, ingredientIndex)
    self.control.recipeListIndex = recipeListIndex
    self.control.recipeIndex = recipeIndex
    self.control.ingredientIndex = ingredientIndex
end

function ZO_ProvisionerRow:SetItem(name, icon, ingredientCount, quality, requiredQuantity)
    self.ingredientCount = ingredientCount
    self.requiredQuantity = requiredQuantity
    self.quality = quality
    
    self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, name))
    self.icon:SetTexture(icon)
    self.countFractionDisplay:SetValues(ingredientCount, requiredQuantity)
        
    --The name label takes the remaining width which is the full row minus padding, icon, padding, padding, count, padding.
    self.nameLabel:SetWidth(ZO_PROVISIONER_SLOT_ROW_WIDTH - ZO_PROVISIONER_SLOT_ICON_SIZE - ZO_PROVISIONER_SLOT_PADDING_X * 4 - self.countControl:GetWidth())
    
    self:UpdateColors()
    self:SetHidden(false)

    self.hasItem = true
end

function ZO_ProvisionerRow:ClearItem()
    self.control.recipeListIndex = nil
    self.control.recipeIndex = nil
    self.control.ingredientIndex = nil
    self:SetHidden(true)

    self.hasItem = false
end

function ZO_ProvisionerRow:SetHidden(hidden)
    self.nameLabel:SetHidden(hidden)
    self.icon:SetHidden(hidden)
    self.countControl:SetHidden(hidden)
end

function ZO_ProvisionerRow:SetEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled
        self:UpdateEnabledState()
    end
end

function ZO_ProvisionerRow:UpdateColors()
    local ingredientCount = self.ingredientCount
    local requiredQuantity = self.requiredQuantity
    local quality = self.quality

    if ingredientCount >= requiredQuantity then
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
        self.nameLabel:SetColor(r, g, b, 1)
    else
        self.nameLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end

    if self.enabled then
        if ingredientCount >= requiredQuantity then
            self.icon:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            self.icon:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        end
    else
        local DISABLED = true
        ZO_ItemSlot_SetupIconUsableAndLockedColor(self.icon, MEETS_USAGE_REQUIREMENTS, DISABLED)
    end

    --Despite the name these only touch the label alpha
    local MEETS_USAGE_REQUIREMENTS = true
    ZO_ItemSlot_SetupTextUsableAndLockedColor(self.nameLabel, MEETS_USAGE_REQUIREMENTS, not self.enabled)
    ZO_ItemSlot_SetupTextUsableAndLockedColor(self.haveLabel, MEETS_USAGE_REQUIREMENTS, not self.enabled)
    ZO_ItemSlot_SetupTextUsableAndLockedColor(self.countControl, MEETS_USAGE_REQUIREMENTS, not self.enabled)
end

function ZO_ProvisionerRow:UpdateEnabledState()
    if self.hasItem then
        self:UpdateColors()
    end
end

function ZO_Provisioner_Initialize(control)
    PROVISIONER = ZO_Provisioner:New(control)
end

function ZO_ProvisionerRow_GetTextColor(self)
    if not self.enabled then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED)
    elseif self.selected then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)
    elseif self.mouseover then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
    elseif self.meetsLevelReq and self.meetsQualityReq then
        return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL)
    end

    return ZO_ERROR_COLOR:UnpackRGBA()
end

function ZO_ProvisionerNavigationEntry_OnMouseEnter(self)
    ZO_SelectableLabel_OnMouseEnter(self)
    if self.enabled and (not self.meetsLevelReq or not self.meetsQualityReq) then
        InitializeTooltip(InformationTooltip, self, RIGHT, -15, 0)
        --loop over tradeskills
        if not self.meetsLevelReq then
             for tradeskill, levelReq in pairs(self.data.tradeskillsLevelReqs) do
                local level = GetNonCombatBonus(GetNonCombatBonusLevelTypeForTradeskillType(tradeskill))
                if level < levelReq then
                    local levelPassiveAbilityId = GetTradeskillLevelPassiveAbilityId(tradeskill)
                    local levelPassiveAbilityName = GetAbilityName(levelPassiveAbilityId)
                    InformationTooltip:AddLine(zo_strformat(SI_RECIPE_REQUIRES_LEVEL_PASSIVE, levelPassiveAbilityName, levelReq), "", ZO_ERROR_COLOR:UnpackRGBA())
                end
            end
        end
        if not self.meetsQualityReq then
            InformationTooltip:AddLine(zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_QUALITY, self.data.qualityReq), "", ZO_ERROR_COLOR:UnpackRGBA())
        end
    end
end

function ZO_ProvisionerNavigationEntry_OnMouseExit(self)
    ZO_SelectableLabel_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end