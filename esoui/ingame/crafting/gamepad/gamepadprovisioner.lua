ZO_GAMEPAD_PROVISIONER_INGREDIENTS_BAR_OFFSET_X = (ZO_GAMEPAD_QUADRANT_1_RIGHT_OFFSET + ZO_GAMEPAD_UI_REFERENCE_WIDTH) / 2

local GAMEPAD_PROVISIONER_OPTIONS_TEMPLATE = "ZO_GamepadLeftCheckboxOptionTemplate"

local GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS = 1
local GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS = 2

local g_filters =
{
    [GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS] =
    {
        header = GetString(SI_GAMEPAD_PROVISIONER_OPTIONS),
        filterName = GetString(SI_PROVISIONER_HAVE_INGREDIENTS),
        filterTooltip = GetString(SI_CRAFTING_HAVE_INGREDIENTS_TOOLTIP),
        checked = false,
    },

    [GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS] =
    {
        filterName = GetString(SI_PROVISIONER_HAVE_SKILLS),
        filterTooltip = GetString(SI_CRAFTING_HAVE_SKILLS_TOOLTIP),
        checked = false,
    },
}

ZO_GamepadProvisioner = ZO_SharedProvisioner:Subclass()

function ZO_GamepadProvisioner:New(...)
    return ZO_SharedProvisioner.New(self, ...)
end

function ZO_GamepadProvisioner:Initialize(control)
    self.mainSceneName = "gamepad_provisioner_root"
    ZO_SharedProvisioner.Initialize(self, control)

    local skillLineXPBarFragment = ZO_FadeSceneFragment:New(ZO_GamepadProvisionerTopLevelSkillInfo)

    GAMEPAD_PROVISIONER_ROOT_SCENE = self:CreateInteractScene(self.mainSceneName)
    GAMEPAD_PROVISIONER_ROOT_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)
    GAMEPAD_PROVISIONER_ROOT_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_PROVISIONER_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.control:GetNamedChild("SkillInfo"), GetCraftingInteractionType())

            if GetCraftingInteractionType() == CRAFTING_TYPE_PROVISIONING then
                TriggerTutorial(TUTORIAL_TRIGGER_PROVISIONING_OPENED)
            end

            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(self.resultTooltip)
            self.recipeList:Activate()

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)

            ZO_GamepadCraftingUtils_RefreshGenericHeader(self)
            ZO_GamepadGenericHeader_Activate(self.header)

            -- refresh the recipe details on show, since they were cleared/hidden when the scene hid
            -- and we may not have had a change in our list to trigger a refresh
            self:RefreshRecipeDetails(self:GetRecipeData())
        elseif newState == SCENE_HIDDEN then
            self:SetDefaultProvisioningSettings()
            ZO_Skills_UntieSkillInfoHeaderToCraftingSkill(self.control:GetNamedChild("SkillInfo"))
            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(nil)
            ZO_GamepadGenericHeader_Deactivate(self.header)
            self.recipeList:Deactivate()

            -- refresh the recipe details passing nil in to appropriately hide/clear the tooltip and ingredient list
            local NO_RECIPE = nil
            self:RefreshRecipeDetails(NO_RECIPE)

            self.control:GetNamedChild("IngredientsBar"):SetHidden(false)

            self:EndRecipePreview()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)

    self:InitializeSettings()

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
        end
    end

    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    self:InitializeRecipeList()
    
    self:InitializeKeybindStripDescriptors()
    self:InitializeDetails()

    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        if SCENE_MANAGER:IsShowing(self.mainSceneName) then
            self.recipeList:SetActive(false)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function() 
        if SCENE_MANAGER:IsShowing(self.mainSceneName) then
            self.recipeList:SetActive(true)
        end
    end)

    self:SetDefaultProvisioningSettings()
end

function ZO_GamepadProvisioner:ShouldShowForControlScheme()
    return IsInGamepadPreferredMode()
end

--Settings

ZO_GamepadProvisioner.PROVISIONING_SETTINGS =
{
}

ZO_GamepadProvisioner.EMBEDDED_SETTINGS =
{
}

function ZO_GamepadProvisioner:InitializeSettings()
    local function GenerateTab(filterType)
        return {
            text = GetString("SI_PROVISIONERSPECIALINGREDIENTTYPE", filterType),
            callback = function()
                self:OnTabFilterChanged(filterType)
            end,
        }
    end

    local foodTab = GenerateTab(PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES)
    local drinkTab = GenerateTab(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING)
    local furnishingsTab = GenerateTab(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING)

    local provisioningSettings = ZO_GamepadProvisioner.PROVISIONING_SETTINGS
    provisioningSettings.tabs = {foodTab, drinkTab, furnishingsTab}

    local embeddedSettings = ZO_GamepadProvisioner.EMBEDDED_SETTINGS
    embeddedSettings.tabs = { furnishingsTab }
end

function ZO_GamepadProvisioner:ConfigureFromSettings(settings)
    if self.settings ~= settings then
        self.settings = settings
        
        ZO_GamepadCraftingUtils_SetupGenericHeader(self, nil, settings.tabs)
        ZO_GamepadCraftingUtils_RefreshGenericHeader(self)

        self:DirtyRecipeList()
    end
end

function ZO_GamepadProvisioner:SetDefaultProvisioningSettings()
    self:ConfigureFromSettings(ZO_GamepadProvisioner.PROVISIONING_SETTINGS)
    GAMEPAD_PROVISIONER_ROOT_SCENE:SetInteractionInfo(self.provisionerStationInteraction)
end

function ZO_GamepadProvisioner:EmbedInCraftingScene(interactionInfo)
    --Set the provisioner interact scenes to have the interaction of the current crafting station so it doesn't terminate the crafting interaction
    --when we go into the provisioning UI
    GAMEPAD_PROVISIONER_ROOT_SCENE:SetInteractionInfo(interactionInfo)
    SCENE_MANAGER:Push(self.mainSceneName)

    self:ConfigureFromSettings(ZO_GamepadProvisioner.EMBEDDED_SETTINGS)
end

function ZO_GamepadProvisioner:InitializeKeybindStripDescriptors()
    -- back descriptors for screen / options screen
    local startButton = {
        --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = "Gamepad Provisioner Default Exit",
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_EXIT",
        order = -10000,
        callback = function()
            SCENE_MANAGER:ShowBaseScene()
        end,
        visible = function()
            return not ZO_CraftingUtils_IsPerformingCraftProcess()
        end,
        ethereal = true,
    }

    local backButton = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_BACK_OPTION),
        keybind = "UI_SHORTCUT_NEGATIVE",
        order = -10000,
        callback = function()
            SCENE_MANAGER:HideCurrentScene()
        end,
        visible = function()
            return not ZO_CraftingUtils_IsPerformingCraftProcess()
        end
    }

    local optionsBackButton = KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()

    -- recipe list keybinds
    self.mainKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Perform craft
        {
            name = function()
                local cost = 0
                local recipeData = self:GetRecipeData()
                if recipeData then
                    cost = GetCostToCraftProvisionerItem(recipeData.recipeListIndex, recipeData.recipeIndex)
                end
                return ZO_CraftingUtils_GetCostToCraftString(cost)
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            gamepadOrder = 1000,
            callback = function()
                self:Create(1)
            end,
            enabled = function()
                return self:ShouldCraftButtonBeEnabled()
            end,
        },

        -- Craft multiple
        {
            name = GetString(SI_GAMEPAD_CRAFT_MULTIPLE),
            keybind = "UI_SHORTCUT_QUATERNARY",
            gamepadOrder = 1010,
            callback = function()
                local itemLink = GetRecipeResultItemLink(self:GetRecipeIndices())
                ZO_GamepadCraftingUtils_ShowMultiCraftDialog(self, itemLink)
            end,
            enabled = function()
                return self:ShouldMultiCraftButtonBeEnabled()
            end,
        },

        -- Options (filtering)
        {
            name = GetString(SI_GAMEPAD_CRAFTING_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            gamepadOrder = 1020,
            callback = function()
                self:ShowOptionsMenu()
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
        },

        --Toggle Preview
        {
            name = function()
                if not ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled() then
                    return GetString(SI_CRAFTING_ENTER_PREVIEW_MODE)
                else
                    return GetString(SI_CRAFTING_EXIT_PREVIEW_MODE)
                end
            end,

            keybind = "UI_SHORTCUT_RIGHT_STICK",
            gamepadOrder = 1030,

            callback = function()
                self:TogglePreviewMode()
            end,

            visible = function()
                local recipeData = self:GetRecipeData()
                if recipeData then
                    return self:CanPreviewRecipe(recipeData)
                else
                    return false
                end
            end,
        },
    }

    ZO_GamepadCraftingUtils_AddListTriggerKeybindDescriptors(self.mainKeybindStripDescriptor, self.recipeList)
    table.insert(self.mainKeybindStripDescriptor, startButton)
    table.insert(self.mainKeybindStripDescriptor, backButton)

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.mainKeybindStripDescriptor)
end

function ZO_GamepadProvisioner:ShowOptionsMenu()
    local dialogData = 
    {
        targetData = self.recipeList:GetTargetData(),
        filters = g_filters,
        finishedCallback =  function()
            self:SaveFilters()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    }
    if not self.craftingOptionsDialogGamepad then
        self.craftingOptionsDialogGamepad = ZO_CraftingOptionsDialogGamepad:New()
    end
    self.craftingOptionsDialogGamepad:ShowOptionsDialog(dialogData)
end

function ZO_GamepadProvisioner:SetupSavedVars()
    local defaults = 
    { 
        haveIngredientsChecked = false, 
        haveSkillsChecked = false, 
    }
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 2, "GamepadProvisioner", defaults)
    
    g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].checked = self.savedVars.haveIngredientsChecked
    g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].checked = self.savedVars.haveSkillsChecked
    
    self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
end

function ZO_GamepadProvisioner:InitializeRecipeList()
    local listContainer = self.control:GetNamedChild("ContainerRecipe")
    self.recipeList = ZO_GamepadVerticalItemParametricScrollList:New(listContainer:GetNamedChild("List"))
    self.recipeList:SetAlignToScreenCenter(true)

    self.recipeList:SetNoItemText(GetString(SI_PROVISIONER_NO_RECIPES))

    local function MenuEntryTemplateEquality(left, right)
        return left.recipeListIndex == right.recipeListIndex and left.recipeIndex == right.recipeIndex and left.name == right.name
    end

    self.recipeList:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
    self.recipeList:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality, "ZO_GamepadMenuEntryHeaderTemplate")

    self.recipeList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self:RefreshRecipeDetails(selectedData)
    end)
end

function ZO_GamepadProvisioner:SaveFilters()
    local filterChanged = self.savedVars.haveIngredientsChecked ~= g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].checked or
                          self.savedVars.haveSkillsChecked ~= g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].checked
    if filterChanged then
        self.savedVars.haveIngredientsChecked = g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].checked
        self.savedVars.haveSkillsChecked = g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].checked
        self:DirtyRecipeList()
    end
end

function ZO_GamepadProvisioner:InitializeDetails()
    local PROVISIONER_INGREDIENT_SLOT_SPACING = 211
    self.ingredientsBar = ZO_GamepadCraftingIngredientBar:New(self.control:GetNamedChild("IngredientsBar"), PROVISIONER_INGREDIENT_SLOT_SPACING)

    self.ingredientsBar:AddDataTemplate("ZO_ProvisionerIngredientBarSlotTemplate", ZO_ProvisionerIngredientBarSlotTemplateSetup)
end

function ZO_GamepadProvisioner:SetDetailsEnabled(enabled)
    for i, data in ipairs(self.ingredientsBar.dataList) do
        local control = data.control
        ZO_ItemSlot_SetupTextUsableAndLockedColor(control.nameLabel, true, not enabled)
        ZO_ItemSlot_SetupTextUsableAndLockedColor(control.countLabel, true, not enabled)
        ZO_ItemSlot_SetupIconUsableAndLockedColor(control.iconControl, true, not enabled)
    end
end

function ZO_GamepadProvisioner:OnTabFilterChanged(filterType)
    if self.filterType ~= filterType then
        if self.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING then
            if SYSTEMS:GetObject("itemPreview"):IsInteractionCameraPreviewEnabled() then
                self:TogglePreviewMode()
            end
        end
        self.filterType = filterType
        self:DirtyRecipeList()
    end
end

function ZO_GamepadProvisioner:RefreshRecipeList()
    -- This function is called from inventory update events, which is when we need to update the header with the player's current and total inventory slots
    ZO_GamepadCraftingUtils_RefreshGenericHeaderData(self)
    self.recipeList:Clear()

    -- first construct the full table of filtered recipes
    local recipeDataEntries = {}

    local requireIngredients = g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].checked
    local requireSkills = g_filters[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].checked
    local craftingInteractionType = GetCraftingInteractionType()
    local hasKnownRecipesInCurrentFilter = false

    local recipeLists = PROVISIONER_MANAGER:GetRecipeListData(craftingInteractionType)
    for _, recipeList in pairs(recipeLists) do
        for _, recipe in ipairs(recipeList.recipes) do
            if recipe.requiredCraftingStationType == craftingInteractionType and self.filterType == recipe.specialIngredientType then
                hasKnownRecipesInCurrentFilter = true
                if self:DoesRecipePassFilter(recipe.specialIngredientType, requireIngredients, recipe.maxIterationsForIngredients, requireSkills, recipe.tradeskillsLevelReqs, recipe.qualityReq, craftingInteractionType, recipe.requiredCraftingStationType) then
                    local dataEntry = ZO_GamepadEntryData:New(zo_strformat(SI_PROVISIONER_RECIPE_NAME_COUNT_NONE, recipe.name), recipe.iconFile, recipe.iconFile)
                    dataEntry:SetDataSource(recipe)
                    -- recipe.quality is deprecated, included here for addon backwards compatibility
                    dataEntry:SetNameColors(dataEntry:GetColorsBasedOnQuality(recipe.displayQuality or recipe.quality))
                    dataEntry:SetSubLabelColors(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
                    dataEntry:SetStackCount(recipe.maxIterationsForIngredients)
                    dataEntry:SetSubLabelTemplate("ZO_ProvisioningSubLabelTemplate")

                    if not recipe.passesTradeskillLevelReqs or not recipe.passesQualityLevelReq or recipe.maxIterationsForIngredients == 0 then
                        dataEntry:SetIconTint(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
                    end

                    if not recipe.passesTradeskillLevelReqs then
                        for tradeskill, levelReq in pairs(recipe.tradeskillsLevelReqs) do
                            local level = GetNonCombatBonus(GetNonCombatBonusLevelTypeForTradeskillType(tradeskill))
                            if level < levelReq then
                                local levelPassiveAbilityId = GetTradeskillLevelPassiveAbilityId(tradeskill)
                                local levelPassiveAbilityName = GetAbilityName(levelPassiveAbilityId)
                                dataEntry:AddSubLabel(zo_strformat(SI_RECIPE_REQUIRES_LEVEL_PASSIVE, levelPassiveAbilityName, levelReq))
                            end
                        end
                    end
                    --Only items that require only provisioning have a quality check
                    if not recipe.passesQualityLevelReq then
                        dataEntry:AddSubLabel(zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_QUALITY, recipe.qualityReq))
                    end

                    table.insert(recipeDataEntries, dataEntry)
                end
            end
        end
    end

    -- now iterate through the table so we can properly identify header breaks
    local lastRecipeListName = ""

    if hasKnownRecipesInCurrentFilter then
        self.recipeList:SetNoItemText(GetString(SI_PROVISIONER_NONE_MATCHING_FILTER))
    else
        self.recipeList:SetNoItemText(GetString(SI_PROVISIONER_NO_RECIPES))
    end

    for i, recipeData in ipairs(recipeDataEntries) do
        local nextRecipeData = recipeDataEntries[i + 1]
        local isNextEntryAHeader = nextRecipeData and nextRecipeData.recipeListName ~= recipeData.recipeListName

        local postSelectedOffsetAdditionalPadding = 0
        if isNextEntryAHeader then
            postSelectedOffsetAdditionalPadding = GAMEPAD_HEADER_SELECTED_PADDING
        end

        if recipeData.recipeListName ~= lastRecipeListName then
            lastRecipeListName = recipeData.recipeListName
            recipeData.header = lastRecipeListName

            self.recipeList:AddEntry("ZO_GamepadItemSubEntryTemplateWithHeader", recipeData, nil, isNextEntryAHeader and GAMEPAD_HEADER_DEFAULT_PADDING, GAMEPAD_HEADER_SELECTED_PADDING, postSelectedOffsetAdditionalPadding)
        else
            self.recipeList:AddEntry("ZO_GamepadItemSubEntryTemplate", recipeData, nil, isNextEntryAHeader and GAMEPAD_HEADER_DEFAULT_PADDING, nil, postSelectedOffsetAdditionalPadding)
        end
    end

    self.recipeList:Commit()
end

function ZO_GamepadProvisioner:TogglePreviewMode()
    ITEM_PREVIEW_GAMEPAD:ToggleInteractionCameraPreview(FRAME_TARGET_CRAFTING_GAMEPAD_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, GAMEPAD_NAV_QUADRANT_2_3_4_FURNITURE_ITEM_PREVIEW_OPTIONS_FRAGMENT)
    if ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled() then
        self.control:GetNamedChild("IngredientsBar"):SetHidden(true)
    else
        self.control:GetNamedChild("IngredientsBar"):SetHidden(false)
    end
    self:RefreshRecipeDetails(self:GetRecipeData())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_GamepadProvisioner:RefreshRecipeDetails(selectedData)
    if selectedData then
        if ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled() then
            if self:CanPreviewRecipe(selectedData) then
                self:PreviewRecipe(selectedData)
            end
            self.resultTooltip:SetHidden(true)
        else
            self.resultTooltip:SetHidden(false)
        end

        --update recipe tooltip
        local recipeListIndex, recipeIndex = selectedData.recipeListIndex, selectedData.recipeIndex
        self.resultTooltip.tip:ClearLines()
        self.resultTooltip.tip:SetProvisionerResultItem(recipeListIndex, recipeIndex)

        -- populate ingredients bar
        local numIngredients = selectedData.numIngredients

        self.ingredientsBar:Clear()
        for i = 1, numIngredients do
            local newData = {
                recipeListIndex = recipeListIndex,
                recipeIndex = recipeIndex,
                ingredientIndex = i,
            }
            self.ingredientsBar:AddEntry("ZO_ProvisionerIngredientBarSlotTemplate", newData)
        end

        self.ingredientsBar:Commit()

        GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(selectedData.createSound)
    else
        self.resultTooltip:SetHidden(true)

        self.ingredientsBar:Clear()
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindStripDescriptor)
end

function ZO_GamepadProvisioner:GetRecipeData()
    return self.recipeList:GetTargetData()
end

function ZO_GamepadProvisioner_Initialize(control)
    GAMEPAD_PROVISIONER = ZO_GamepadProvisioner:New(control)
end

--[[ Provision Templates ]]--

function ZO_ProvisionerIngredientBarSlotTemplate_OnInitialized(control)
    control.iconControl = control:GetNamedChild("Icon")
    control.nameLabel = control:GetNamedChild("IngredientName")
    control.countControl = control:GetNamedChild("Count")
    local DIVIDER_THICKNESS = 2
    control.countFractionDisplay = ZO_FractionDisplay:New(control.countControl, "ZoFontGamepad27", DIVIDER_THICKNESS)
    control.countFractionDisplay:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
end

function ZO_ProvisionerIngredientBarSlotTemplateSetup(control, data)
    local name, icon, requiredQuantity, _, displayQuality = GetRecipeIngredientItemInfo(data.recipeListIndex, data.recipeIndex, data.ingredientIndex)
    local ingredientCount = GetCurrentRecipeIngredientCount(data.recipeListIndex, data.recipeIndex, data.ingredientIndex)

    control.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, name))
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality)
    control.nameLabel:SetColor(r, g, b, 1)

    control.iconControl:SetTexture(icon)

    control.countFractionDisplay:SetValues(ingredientCount, requiredQuantity)

    local NOT_LOCKED = false
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.countLabel, ingredientCount >= requiredQuantity, NOT_LOCKED)
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.iconControl, ingredientCount >= requiredQuantity, NOT_LOCKED)
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.nameLabel, ingredientCount >= requiredQuantity, NOT_LOCKED)
end