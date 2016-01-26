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
    self:SetupMainInteractScene(GAMEPAD_PROVISIONER_ROOT_SCENE)

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
end

function ZO_GamepadProvisioner:OnSceneShowing()
    self:RefreshRecipeList()
	self.recipeList:Activate()

    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.mainKeybindStripDescriptor)

    ZO_GamepadCraftingUtils_RefreshGenericHeader(self)
end

function ZO_GamepadProvisioner:OnSceneHidden()
    self.recipeList:Deactivate()
    self.ingredientsBar:Clear()

    self.resultTooltip:SetHidden(true)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_GamepadProvisioner:ShouldShowForControlScheme()
    return IsInGamepadPreferredMode()
end

function ZO_GamepadProvisioner:PerformDeferredInitialization()
    self:InitializeRecipeList()
    
    self:InitializeKeybindStripDescriptors()
    self:InitializeDetails()

    local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(CRAFTING_TYPE_PROVISIONING)

    ZO_GamepadCraftingUtils_InitializeGenericHeader(self, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    ZO_GamepadCraftingUtils_SetupGenericHeader(self, titleString)
    ZO_GamepadCraftingUtils_RefreshGenericHeader(self)

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

    self.recipeList:SetNoItemText(GetString(SI_PROVISIONER_NO_MATCHING_RECIPES))

    local function MenuEntryTemplateEquality(left, right)
        return left.recipeListIndex == right.recipeListIndex and left.recipeIndex == right.recipeIndex and left.recipeName == right.recipeName
    end

    self.recipeList:AddDataTemplate("ZO_GamepadSubMenuEntryWithTwoSubLabelsTemplate", ZO_GamepadProvisionRecipeEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
    self.recipeList:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryWithTwoSubLabelsTemplate", ZO_GamepadProvisionRecipeEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality, "ZO_GamepadMenuEntryHeaderTemplate")

    self.recipeList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self:RefreshRecipeDetails(selectedData)
    end)
end

function ZO_GamepadProvisioner:InitializeOptionList()
    self.optionList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("ContainerOptionsList"))

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
    self.ingredientsBar = ZO_GamepadCraftingIngredientBar:New(self.control:GetNamedChild("IngredientsBar"), ZO_GAMEPAD_CRAFTING_UTILS_SLOT_SPACING)

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

function ZO_GamepadProvisioner:RefreshRecipeList()
    self.recipeList:Clear()

	-- first construct the full table of filtered recipes
	local recipeDataTable = {}

    local checkNumCreatable = self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_INGREDIENTS].currentValue
    local checkSkills = self.optionDataList[GAMEPAD_PROVISIONER_OPTION_FILTER_SKILLS].currentValue

    for recipeListIndex = 1, GetNumRecipeLists() do
        local recipeListName, numRecipes, _, _, _, _, createSound = GetRecipeListInfo(recipeListIndex)

        for recipeIndex = 1, numRecipes do
            local known, recipeName, numIngredients, provisionerLevelReq, qualityReq, specialIngredientType = GetRecipeInfo(recipeListIndex, recipeIndex)
            local _, resultIcon = GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
			if known then
                local numCreatable = self:CalculateHowManyCouldBeCreated(recipeListIndex, recipeIndex, numIngredients)
                if self:DoesRecipePassFilter(nil, checkNumCreatable, numCreatable, checkSkills, provisionerLevelReq, qualityReq) then
                    local itemLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)
                    local quality = GetItemLinkQuality(itemLink)
                    local recipeData = {
						recipeListName = recipeListName,
                        recipeListIndex = recipeListIndex,
                        recipeIndex = recipeIndex,
                        provisionerLevelReq = provisionerLevelReq,
                        qualityReq = qualityReq,
                        passesProvisionerLevelReq = self:PassesProvisionerLevelReq(provisionerLevelReq),
                        passesQualityLevelReq = self:PassesQualityLevelReq(qualityReq),
                        specialIngredientType = specialIngredientType,
                        numIngredients = numIngredients,
                        numCreatable = numCreatable,
                        createSound = createSound,
						iconFile = resultIcon,
                        quality = quality,
                    }

                    recipeData.recipeName = zo_strformat(SI_PROVISIONER_RECIPE_NAME_COUNT_NONE, recipeName)

					table.insert(recipeDataTable, recipeData)
                end
            end
        end
    end

	-- now iterate through the table so we can properly identify header breaks
    local lastRecipeListName = ""

	for i, recipeData in ipairs(recipeDataTable) do
        local nextRecipeData = recipeDataTable[i + 1]
        local isNextEntryAHeader = nextRecipeData and nextRecipeData.recipeListName ~= recipeData.recipeListName

        local postSelectedOffsetAdditionalPadding = 0
        if isNextEntryAHeader then
            postSelectedOffsetAdditionalPadding = GAMEPAD_HEADER_SELECTED_PADDING
        end

        -- anticipate the need for additional information text regarding requirements
        if not recipeData.passesProvisionerLevelReq then
            postSelectedOffsetAdditionalPadding = postSelectedOffsetAdditionalPadding + 24
        end
        if not recipeData.passesQualityLevelReq then
            postSelectedOffsetAdditionalPadding = postSelectedOffsetAdditionalPadding + 24
        end

        if recipeData.recipeListName ~= lastRecipeListName then
            lastRecipeListName = recipeData.recipeListName
            recipeData.header = lastRecipeListName

            self.recipeList:AddEntry("ZO_GamepadSubMenuEntryWithTwoSubLabelsTemplateWithHeader", recipeData, nil, isNextEntryAHeader and GAMEPAD_HEADER_DEFAULT_PADDING, GAMEPAD_HEADER_SELECTED_PADDING, postSelectedOffsetAdditionalPadding)
        else
            self.recipeList:AddEntry("ZO_GamepadSubMenuEntryWithTwoSubLabelsTemplate", recipeData, nil, isNextEntryAHeader and GAMEPAD_HEADER_DEFAULT_PADDING, nil, postSelectedOffsetAdditionalPadding)
        end
	end

    self.recipeList:Commit()
end

function ZO_GamepadProvisioner:RefreshRecipeDetails(selectedData)
    if selectedData then
        -- update the tooltip window
        self.resultTooltip:SetHidden(false)
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

    local haveIngredientsOption = {}

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
end

function ZO_GamepadProvisioner:IsCraftable()
    local targetData = self.recipeList:GetTargetData()
    if targetData then
        return targetData.numCreatable > 0
           and targetData.passesProvisionerLevelReq
           and targetData.passesQualityLevelReq
    end
    return false
end

function ZO_GamepadProvisioner:Create()
    local targetData = self.recipeList:GetTargetData()
    CraftProvisionerItem(targetData.recipeListIndex, targetData.recipeIndex)

    ZO_GamepadCraftingUtils_RefreshGenericHeader(self)
end

function ZO_GamepadProvisioner_Initialize(control)
    GAMEPAD_PROVISIONER = ZO_GamepadProvisioner:New(control)
end

--[[ Provision Templates ]]--

local function AddInfoLabelText(control, text, r, g, b, a)
    if control.numInfoLabelsUsed < #control.subLabels then
        local infoLabel = control.subLabels[control.numInfoLabelsUsed + 1]
        infoLabel:SetText(text)
        infoLabel:SetHidden(false)
        infoLabel:SetColor(r, g, b, a)
        control.numInfoLabelsUsed = control.numInfoLabelsUsed + 1
    end
end

local function SetupSharedProvisionRecipeEntry(control, data, selected)
    control.numInfoLabelsUsed = 0

    if selected then
        if not data.passesProvisionerLevelReq then
            AddInfoLabelText(control, zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_IMPROVEMENT, data.provisionerLevelReq), ZO_ERROR_COLOR:UnpackRGBA())
        end
        if not data.passesQualityLevelReq then
            AddInfoLabelText(control, zo_strformat(SI_PROVISIONER_REQUIRES_RECIPE_QUALITY, data.qualityReq), ZO_ERROR_COLOR:UnpackRGBA())
        end
    end

    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality)
    control.label:SetColor(r, g, b, ZO_GamepadMenuEntryTemplate_GetAlpha(selected))

    control.icon:SetColor(1, 1, 1, 1)
    if data.numCreatable > 0 then
        control.stackCountLabel:SetHidden(false)
        control.stackCountLabel:SetText(data.numCreatable)
    else
        control.stackCountLabel:SetHidden(true)
    end

    -- adjust color of label if it can't be crafted, overriding the default set in SharedGamepadEntryTemplateSetup(), but leaving the alpha alone
    if not data.passesProvisionerLevelReq or not data.passesQualityLevelReq or data.numCreatable == 0 then
        local r, g, b = ZO_ERROR_COLOR:UnpackRGB()
        control.icon:SetColor(r, g, b, 1)
    end

    for i = control.numInfoLabelsUsed + 1, #control.subLabels do
        control.subLabels[i]:SetHidden(true)
    end
end

function ZO_GamepadProvisionRecipeEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_GamepadSubMenuEntryTemplate_Setup(control, data.recipeName, data.iconFile, data.iconFile, nil, selected, activated, data.stackCount)
    SetupSharedProvisionRecipeEntry(control, data, selected)
end

function ZO_ProvisionerIngredientBarSlotTemplateSetup(control, data)
    local name, icon, stack, _, quality = GetRecipeIngredientItemInfo(data.recipeListIndex, data.recipeIndex, data.ingredientIndex)
    local ingredientCount = GetCurrentRecipeIngredientCount(data.recipeListIndex, data.recipeIndex, data.ingredientIndex)

    control.iconControl = control:GetNamedChild("Icon")
    control.nameLabel = control:GetNamedChild("IngredientName")
    control.countLabel = control:GetNamedChild("StackCount")

    control.nameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, name))
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
    control.nameLabel:SetColor(r, g, b, 1)

    control.iconControl:SetTexture(icon)

    control.countLabel:SetText(ingredientCount)

    local LOCKED = false
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.countLabel, ingredientCount > 0, LOCKED)
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.iconControl, ingredientCount > 0, LOCKED)
    ZO_ItemSlot_SetupIconUsableAndLockedColor(control.nameLabel, ingredientCount > 0, LOCKED)
end