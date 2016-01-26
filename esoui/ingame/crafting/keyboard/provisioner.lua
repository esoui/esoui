ZO_Provisioner = ZO_SharedProvisioner:Subclass()

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

    self:InitializeTabs()
    self:InitializeFilters()
    self:InitializeKeybindStripDescriptors()
    self:InitializeRecipeTree()
    self:InitializeDetails()

    ZO_InventoryInfoBar_ConnectStandardBar(self.control:GetNamedChild("InfoBar"))

    PROVISIONER_SCENE = self:CreateInteractScene(self.mainSceneName)
    self:SetupMainInteractScene(PROVISIONER_SCENE)

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
end

function ZO_Provisioner:OnSceneShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_Provisioner:OnSceneHidden()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_Provisioner:ShouldShowForControlScheme()
    return not IsInGamepadPreferredMode()
end

function ZO_Provisioner:InitializeTabs()
    local function GenerateTab(name, filterType, normal, pressed, highlight, disabled)
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

    self.tabs = self.control:GetNamedChild("Tabs")
    self.activeTab = self.control:GetNamedChild("TabsLabel")

    ZO_MenuBar_AddButton(self.tabs, GenerateTab(SI_PROVISIONER_FILTER_COOK, PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES, "EsoUI/Art/Crafting/provisioner_indexIcon_meat_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_meat_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_meat_over.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_meat_disabled.dds"))
    ZO_MenuBar_AddButton(self.tabs, GenerateTab(SI_PROVISIONER_FILTER_BREW, PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING, "EsoUI/Art/Crafting/provisioner_indexIcon_beer_up.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_beer_down.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_beer_over.dds", "EsoUI/Art/Crafting/provisioner_indexIcon_beer_disabled.dds"))

    ZO_MenuBar_SelectDescriptor(self.tabs, PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES)

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.tabs)
end

function ZO_Provisioner:OnTabFilterChanged(filterData)
    self.activeTab:SetText(GetString(filterData.activeTabText))
    self.filterType = filterData.descriptor
    if self.savedVars then
        ZO_CheckButton_SetCheckState(self.haveIngredientsCheckBox, self.savedVars.haveIngredientsChecked)
        ZO_CheckButton_SetCheckState(self.haveSkillsCheckBox, self.savedVars.haveSkillsChecked)
    end
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
        
            callback = function() self:Create() end,

            visible = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:IsCraftable() end,
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
            control.icon:SetTexture(data.disabledIcon)
        elseif open then
            control.icon:SetTexture(data.downIcon)
        else
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
        control.meetsLevelReq = self:PassesProvisionerLevelReq(data.provisionerLevelReq)
        control.meetsQualityReq = self:PassesQualityLevelReq(data.qualityReq)
        control.enabled = enabled

        local numEffectivelyCreatable = data.numCreatable
        if numEffectivelyCreatable > 0 and enabled then
            control:SetText(zo_strformat(SI_PROVISIONER_RECIPE_NAME_COUNT, data.name, numEffectivelyCreatable))
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

    self.ingredientRows = {
        ZO_ProvisionerRow:New(self, self.detailsPane:GetNamedChild("IngredientSlot1")),
        ZO_ProvisionerRow:New(self, self.detailsPane:GetNamedChild("IngredientSlot2")),
        ZO_ProvisionerRow:New(self, self.detailsPane:GetNamedChild("IngredientSlot3")),
        ZO_ProvisionerRow:New(self, self.detailsPane:GetNamedChild("IngredientSlot4")),
        ZO_ProvisionerRow:New(self, self.detailsPane:GetNamedChild("IngredientSlot5")),
    }
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
    local checkNumCreatable = ZO_CheckButton_IsChecked(self.haveIngredientsCheckBox)
    local checkSkills = ZO_CheckButton_IsChecked(self.haveSkillsCheckBox)

    for recipeListIndex = 1, GetNumRecipeLists() do
        local recipeListName, numRecipes, upIcon, downIcon, overIcon, disabledIcon, createSound = GetRecipeListInfo(recipeListIndex)
        local parent

        for recipeIndex = 1, numRecipes do
            local known, recipeName, numIngredients, provisionerLevelReq, qualityReq, specialIngredientType = GetRecipeInfo(recipeListIndex, recipeIndex)
            if known and self.filterType == specialIngredientType then
                local numCreatable = self:CalculateHowManyCouldBeCreated(recipeListIndex, recipeIndex, numIngredients)
                if self:DoesRecipePassFilter(specialIngredientType, checkNumCreatable, numCreatable, checkSkills, provisionerLevelReq, qualityReq) then
                    parent = parent or self.recipeTree:AddNode("ZO_IconHeader", { recipeListIndex = recipeListIndex, name = recipeListName, upIcon = upIcon, downIcon = downIcon, overIcon = overIcon, disabledIcon = disabledIcon }, nil, SOUNDS.PROVISIONING_BLADE_SELECTED)
                    local data = { 
                        recipeListIndex = recipeListIndex,
                        recipeIndex = recipeIndex,
                        name = recipeName,
                        provisionerLevelReq = provisionerLevelReq,
                        qualityReq = qualityReq,
                        specialIngredientType = specialIngredientType,
                        numIngredients = numIngredients,
                        numCreatable = numCreatable,
                        createSound = createSound,
                    }
                    self.recipeTree:AddNode("ZO_ProvisionerNavigationEntry", data, parent, SOUNDS.PROVISIONING_ENTRY_SELECTED)

                    hasRecipesWithFilter = true
                end
                knowAnyRecipesInTab = true
            end
        end
    end

    self.recipeTree:Commit()

    self.noRecipesLabel:SetHidden(hasRecipesWithFilter)
    ZO_CheckButton_SetEnableState(self.haveIngredientsCheckBox, knowAnyRecipesInTab)
    ZO_CheckButton_SetEnableState(self.haveSkillsCheckBox, knowAnyRecipesInTab)
    if not hasRecipesWithFilter then
        if knowAnyRecipesInTab then
            self.noRecipesLabel:SetText(GetString(SI_PROVISIONER_NO_MATCHING_RECIPES))
        else
            self.noRecipesLabel:SetText(GetString(self.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES and SI_PROVISIONER_NO_COOKING_RECIPES or SI_PROVISIONER_NO_BREWING_RECIPES))
            ZO_CheckButton_SetChecked(self.haveIngredientsCheckBox)
            ZO_CheckButton_SetChecked(self.haveSkillsCheckBox)
        end
        self:RefreshRecipeDetails()
    end
end

function ZO_Provisioner:GetSelectedRecipeListIndex()
    local selectedData = self.recipeTree:GetSelectedData()
    if selectedData then
        return selectedData.recipeListIndex
    end
end

function ZO_Provisioner:GetSelectedRecipeIndex()
    local selectedData = self.recipeTree:GetSelectedData()
    if selectedData then
        return selectedData.recipeIndex
    end
end

function ZO_Provisioner:RefreshRecipeDetails()
    local selectedData = self.recipeTree:GetSelectedData()
    if selectedData then
        self.resultTooltip:SetHidden(false)
        local recipeListIndex, recipeIndex = self:GetSelectedRecipeListIndex(), self:GetSelectedRecipeIndex()

        self.resultTooltip:ClearLines()
        self.resultTooltip:SetProvisionerResultItem(recipeListIndex, recipeIndex)

        local numIngredients = selectedData.numIngredients
        for ingredientIndex, ingredientSlot in ipairs(self.ingredientRows) do
            if ingredientIndex > numIngredients then
                ingredientSlot:ClearItem()
            else
                local name, icon, stack, _, quality = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
                local ingredientCount = GetCurrentRecipeIngredientCount(recipeListIndex, recipeIndex, ingredientIndex)
                ingredientSlot:SetItem(name, icon, stack, quality, ingredientCount)
                ingredientSlot:SetItemIndices(recipeListIndex, recipeIndex, ingredientIndex)
            end
        end

        CRAFTING_RESULTS:SetTooltipAnimationSounds(selectedData.createSound)
    else
        self.resultTooltip:SetHidden(true)

        for ingredientIndex, ingredientSlot in ipairs(self.ingredientRows) do
            ingredientSlot:ClearItem()
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_Provisioner:IsCraftable()
    local selectedData = self.recipeTree:GetSelectedData()
    if selectedData then
        return selectedData.numCreatable > 0 
           and self:PassesProvisionerLevelReq(selectedData.provisionerLevelReq) 
           and self:PassesQualityLevelReq(selectedData.qualityReq)
    end
    return false
end

function ZO_Provisioner:Create()
    CraftProvisionerItem(self:GetSelectedRecipeListIndex(), self:GetSelectedRecipeIndex())
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
    self.countLabel = control:GetNamedChild("Count")
end

function ZO_ProvisionerRow:SetItemIndices(recipeListIndex, recipeIndex, ingredientIndex)
    self.control.recipeListIndex = recipeListIndex
    self.control.recipeIndex = recipeIndex
    self.control.ingredientIndex = ingredientIndex
end

function ZO_ProvisionerRow:SetItem(name, icon, quantity, quality, ingredientCount)
    self.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, name))
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
    self.nameLabel:SetColor(r, g, b, 1)

    self.icon:SetTexture(icon)

    self.countLabel:SetText(ingredientCount)

    if ingredientCount > 0 then
        self.countLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    else
        self.countLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end

    self:UpdateEnabledState()
    self:SetHidden(false)
end

function ZO_ProvisionerRow:ClearItem()
    self.control.recipeListIndex = nil
    self.control.recipeIndex = nil
    self.control.ingredientIndex = nil
    self:SetHidden(true)
end

function ZO_ProvisionerRow:SetHidden(hidden)
    self.nameLabel:SetHidden(hidden)
    self.countLabel:SetHidden(hidden)
    self.icon:SetHidden(hidden)
end

function ZO_ProvisionerRow:SetEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled
        self:UpdateEnabledState()
    end
end

function ZO_ProvisionerRow:UpdateEnabledState()
    local MEETS_USAGE_REQUIREMENTS = true
    ZO_ItemSlot_SetupTextUsableAndLockedColor(self.nameLabel, MEETS_USAGE_REQUIREMENTS, not self.enabled)
    ZO_ItemSlot_SetupTextUsableAndLockedColor(self.countLabel, MEETS_USAGE_REQUIREMENTS, not self.enabled)
    ZO_ItemSlot_SetupIconUsableAndLockedColor(self.icon, MEETS_USAGE_REQUIREMENTS, not self.enabled)
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