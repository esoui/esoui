local GAMEPAD_PROVISIONER_OPTIONS_TEMPLATE = "ZO_GamepadLeftCheckboxOptionTemplate"

local GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS = 1
local GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS = 2

local GAMEPAD_PROVISIONER_OPTION_INFO =
{
    [GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS] =
    {
        header = GetString(SI_GAMEPAD_PROVISIONER_OPTIONS),
        optionName = GetString(SI_PROVISIONER_HAVE_INGREDIENTS),
    },

    [GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS] =
    {
        optionName = GetString(SI_PROVISIONER_HAVE_SKILLS),
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
    GAMEPAD_PROVISIONER_ROOT_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_PROVISIONER_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            if GetCraftingInteractionType() == CRAFTING_TYPE_PROVISIONING then
                TriggerTutorial(TUTORIAL_TRIGGER_PROVISIONING_OPENED)
            end

            if self.optionsChanged then
                self:DirtyRecipeList()
                self.optionsChanged = false
            end

            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(self.resultTooltip)
            self.recipeList:Activate()

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)

            ZO_GamepadCraftingUtils_RefreshGenericHeader(self)
            ZO_GamepadGenericHeader_Activate(self.header)

            -- refresh the recipe details on show, since they were cleared/hidden when the scene hid
            -- and we may not have had a change in our list to trigger a refresh
            local targetData = self.recipeList:GetTargetData()
            self:RefreshRecipeDetails(targetData)
        elseif newState == SCENE_HIDDEN then
            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(nil)
            ZO_GamepadGenericHeader_Deactivate(self.header)
            self.recipeList:Deactivate()

            -- refresh the recipe details passing nil in to appropriately hide/clear the tooltip and ingredient list
            local NO_SELECTED_DATA = nil
            self:RefreshRecipeDetails(NO_SELECTED_DATA)

            self.control:GetNamedChild("IngredientsBar"):SetHidden(false)

            self:EndRecipePreview()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)

    GAMEPAD_PROVISIONER_OPTIONS_SCENE = self:CreateInteractScene("gamepad_provisioner_options")
    GAMEPAD_PROVISIONER_OPTIONS_SCENE:AddFragment(skillLineXPBarFragment)
    GAMEPAD_PROVISIONER_OPTIONS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.recipeList:RefreshVisible()
            self:RefreshOptionList()
            self.optionList:Activate()

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.optionsKeybindStripDescriptor)
            
            self.inOptionsMenu = false
            self.isCrafting = false
        elseif newState == SCENE_HIDDEN then
            self.optionList:Deactivate()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.optionsKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()

            self:SaveFilters()
            ZO_SavePlayerConsoleProfile()
        end
    end)

    local sceneGroup = ZO_SceneGroup:New(GAMEPAD_PROVISIONER_ROOT_SCENE:GetName(), GAMEPAD_PROVISIONER_OPTIONS_SCENE:GetName())
    sceneGroup:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_GROUP_SHOWING then
            ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.control:GetNamedChild("SkillInfo"), GetCraftingInteractionType())
        elseif newState == SCENE_GROUP_HIDDEN then
            self:SetDefaultProvisioningSettings()
            ZO_Skills_UntieSkillInfoHeaderToCraftingSkill(self.control:GetNamedChild("SkillInfo"))
        end
    end)

    self:InitializeSettings()
    self:InitializeOptionList()

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local defaults = { haveIngredientsChecked = false, haveSkillsChecked = false, }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 2, "GamepadProvisioner", defaults)

            self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].currentValue = self.savedVars.haveIngredientsChecked
            self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].currentValue = self.savedVars.haveSkillsChecked
            
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    self:InitializeRecipeList()
    
    self:InitializeKeybindStripDescriptors()
    self:InitializeDetails()

    local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(CRAFTING_TYPE_PROVISIONING)

    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        if SCENE_MANAGER:IsShowing(self.mainSceneName) then
            self.recipeList:SetActive(false)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function() 
        if SCENE_MANAGER:IsShowing(self.mainSceneName) then
            self.recipeList:SetActive(true)

            self.isCrafting = false
        end
    end)

    self.control:RegisterForEvent(EVENT_INVENTORY_IS_FULL, function()
        self.isCrafting = false
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
    local function GenerateTab(nameStringId, filterType)
        return {
            text = GetString(nameStringId),
            callback = function()
                self:OnTabFilterChanged(filterType)
            end,
        }
    end

    local foodTab = GenerateTab(SI_PROVISIONER_FILTER_COOK, PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES)
    local drinkTab = GenerateTab(SI_PROVISIONER_FILTER_BREW, PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING)
    local furnishingsTab = GenerateTab(SI_PROVISIONER_FILTER_FURNISHINGS, PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING)

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
    GAMEPAD_PROVISIONER_OPTIONS_SCENE:SetInteractionInfo(self.provisionerStationInteraction)
end

function ZO_GamepadProvisioner:EmbedInCraftingScene(interactionInfo)
    --Set the provisioner interact scenes to have the interaction of the current crafting station so it doesn't terminate the crafting interaction
    --when we go into the provisioning UI
    GAMEPAD_PROVISIONER_ROOT_SCENE:SetInteractionInfo(interactionInfo)
    GAMEPAD_PROVISIONER_OPTIONS_SCENE:SetInteractionInfo(interactionInfo)
    
    SCENE_MANAGER:Push(self.mainSceneName)

    self:ConfigureFromSettings(ZO_GamepadProvisioner.EMBEDDED_SETTINGS)
end

function ZO_GamepadProvisioner:InitializeKeybindStripDescriptors()
    -- back descriptors for screen / options screen
    local startButton = {
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

    local optionsBackButton = ZO_ShallowTableCopy(backButton)
    optionsBackButton.callback = function()
        self.inOptionsMenu = false
        SCENE_MANAGER:HideCurrentScene()
    end

    -- recipe list keybinds
    self.mainKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Perform craft
        {
            name = function()
                local cost = 0
                local targetData = self.recipeList:GetTargetData()
                if targetData then
                    cost = GetCostToCraftProvisionerItem(targetData.recipeListIndex, targetData.recipeIndex)
                end
                return ZO_CraftingUtils_GetCostToCraftString(cost)
            end,

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                if not self.inOptionsMenu then
                    self.isCrafting = true
                    self:Create()
                end
            end,

            visible = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self:IsCraftable() end,
        },

        -- Options (filtering)
        {
            name = GetString(SI_CHAT_CONFIG_OPTIONS),

            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                if not self.isCrafting then
                    self.inOptionsMenu = true
                    self:ShowOptions()
                end
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

            callback = function()
                self:TogglePreviewMode()
            end,

            visible = function()
                local targetData = self.recipeList:GetTargetData()
                if targetData then
                    return self:CanPreviewRecipe(targetData)
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

    -- options list keybinds
    self.optionsKeybindStripDescriptor = {}
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.optionsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:SelectOption() end)
    table.insert(self.optionsKeybindStripDescriptor, startButton)
    table.insert(self.optionsKeybindStripDescriptor, optionsBackButton)
end

function ZO_GamepadProvisioner:ShowOptions()
    SCENE_MANAGER:Push("gamepad_provisioner_options")
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

function ZO_GamepadProvisioner:InitializeOptionList()
    self.optionList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("ContainerOptionsList"))
    self.optionList:SetAlignToScreenCenter(true)

    self.optionList:AddDataTemplate(GAMEPAD_PROVISIONER_OPTIONS_TEMPLATE, ZO_GamepadCheckboxOptionTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.optionList:AddDataTemplateWithHeader(GAMEPAD_PROVISIONER_OPTIONS_TEMPLATE, ZO_GamepadCheckboxOptionTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsMenuEntryHeaderTemplate")
    -- populate option data
    self.optionDataList = {}
    self:BuildOptionList()
end

function ZO_GamepadProvisioner:SaveFilters()
    self.savedVars.haveIngredientsChecked = self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].currentValue
    self.savedVars.haveSkillsChecked = self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].currentValue
end

function ZO_GamepadProvisioner:BuildOptionList()
    if self.optionDataList == nil then return end

    for key, optionInfo in pairs(GAMEPAD_PROVISIONER_OPTION_INFO) do
        local newOptionData = ZO_GamepadEntryData:New(optionInfo.optionName)
        newOptionData:SetDataSource(optionInfo)

        self.optionDataList[key] = newOptionData
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

    local checkNumCreatable = self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].currentValue
    local checkSkills = self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].currentValue
    local craftingInteractionType = GetCraftingInteractionType()
    
    local recipeData = PROVISIONER_MANAGER:GetRecipeData()
    for _, recipeList in pairs(recipeData) do
        for _, recipe in ipairs(recipeList.recipes) do
            if self:DoesRecipePassFilter(recipe.specialIngredientType, checkNumCreatable, recipe.numCreatable, checkSkills, recipe.tradeskillsLevelReqs, recipe.qualityReq, craftingInteractionType, recipe.requiredCraftingStationType) then
                local dataEntry = ZO_GamepadEntryData:New(zo_strformat(SI_PROVISIONER_RECIPE_NAME_COUNT_NONE, recipe.name), recipe.iconFile, recipe.iconFile)
                dataEntry:SetDataSource(recipe)
                dataEntry:SetNameColors(dataEntry:GetColorsBasedOnQuality(recipe.quality))
                dataEntry:SetSubLabelColors(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
                dataEntry:SetStackCount(recipe.numCreatable)
                dataEntry:SetSubLabelTemplate("ZO_ProvisioningSubLabelTemplate")

                if not recipe.passesTradeskillLevelReqs or not recipe.passesQualityLevelReq or recipe.numCreatable == 0 then
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

    -- now iterate through the table so we can properly identify header breaks
    local lastRecipeListName = ""

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
    ITEM_PREVIEW_GAMEPAD:ToggleInteractionCameraPreview(FRAME_TARGET_CRAFTING_GAMEPAD_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, FURNITURE_BROWSER_GAMEPAD_ITEM_PREVIEW_OPTIONS_FRAGMENT)
    if ITEM_PREVIEW_GAMEPAD:IsInteractionCameraPreviewEnabled() then
        self.control:GetNamedChild("IngredientsBar"):SetHidden(true)
    else
        self.control:GetNamedChild("IngredientsBar"):SetHidden(false)
    end
    local targetData = self.recipeList:GetTargetData()
    self:RefreshRecipeDetails(targetData)
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

function ZO_GamepadProvisioner:RefreshOptionList()
    self.optionList:Clear()

    local i = 1
    for key, optionData in pairs(self.optionDataList) do
        if i == 1 then
            self.optionList:AddEntryWithHeader(GAMEPAD_PROVISIONER_OPTIONS_TEMPLATE, optionData)
        else
            self.optionList:AddEntry(GAMEPAD_PROVISIONER_OPTIONS_TEMPLATE, optionData)
        end

        i = i + 1
    end

    self.optionList:Commit()
end

function ZO_GamepadProvisioner:SelectOption()
    ZO_GamepadCraftingUtils_SelectOptionFromOptionList(self)
    self.optionsChanged = true
end

function ZO_GamepadProvisioner:IsCraftable()
    local targetData = self.recipeList:GetTargetData()
    if targetData then
        return targetData.numCreatable > 0
           and targetData.passesTradeskillLevelReqs
           and targetData.passesQualityLevelReq
    end
    return false
end

function ZO_GamepadProvisioner:Create()
    local targetData = self.recipeList:GetTargetData()
    CraftProvisionerItem(targetData.recipeListIndex, targetData.recipeIndex)
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
    local name, icon, requiredQuantity, _, quality = GetRecipeIngredientItemInfo(data.recipeListIndex, data.recipeIndex, data.ingredientIndex)
    local ingredientCount = GetCurrentRecipeIngredientCount(data.recipeListIndex, data.recipeIndex, data.ingredientIndex)

    control.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, name))
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
    control.nameLabel:SetColor(r, g, b, 1)

    control.iconControl:SetTexture(icon)

    control.countFractionDisplay:SetValues(ingredientCount, requiredQuantity)

    local NOT_LOCKED = false
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.countLabel, ingredientCount >= requiredQuantity, NOT_LOCKED)
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.iconControl, ingredientCount >= requiredQuantity, NOT_LOCKED)
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.nameLabel, ingredientCount >= requiredQuantity, NOT_LOCKED)
end