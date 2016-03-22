local GAMEPAD_SMITHING_CREATION_OPTIONS_SCENE_NAME = "gamepad_smithing_creation_options"

local GAMEPAD_SMITHING_CREATION_OPTIONS_TEMPLATE = "ZO_CheckBoxTemplate_Gamepad"

local GAMEPAD_SMITHING_CREATION_OPTION_FILTER_MATERIALS = 1
local GAMEPAD_SMITHING_CREATION_OPTION_FILTER_KNOWLEDGE = 2

local GAMEPAD_SMITHING_TOGGLE_TYPE_STYLE = 1

local g_options =
{
    [GAMEPAD_SMITHING_CREATION_OPTION_FILTER_MATERIALS] =
    {
        header = SI_GAMEPAD_SMITHING_CREATION_OPTIONS,
        optionName = GetString(SI_SMITHING_HAVE_MATERIALS),
    },

    [GAMEPAD_SMITHING_CREATION_OPTION_FILTER_KNOWLEDGE] =
    {
        optionName = GetString(SI_SMITHING_HAVE_KNOWLEDGE),
    },
}

ZO_GAMEPAD_SMITHING_CONTAINER_ITEM_PADDING_Y = 3

--[[ SmithingHorizontalScrollList ]]--
ZO_SmithingHorizontalScrollList_Gamepad = ZO_HorizontalScrollList_Gamepad:Subclass()

function ZO_SmithingHorizontalScrollList_Gamepad:New(...)
    return ZO_HorizontalScrollList_Gamepad.New(self, ...)
end

function ZO_SmithingHorizontalScrollList_Gamepad:SetToggleType(type)
    self.toggleType = type
end

function ZO_SmithingHorizontalScrollList_Gamepad:GetToggleType()
    return self.toggleType
end

--[[ ZO_GamepadSmithingCreation ]]--

ZO_GamepadSmithingCreation = ZO_SharedSmithingCreation:Subclass()

function ZO_GamepadSmithingCreation:New(...)
    return ZO_SharedSmithingCreation.New(self, ...)
end

function ZO_GamepadSmithingCreation:Initialize(panelControl, floatingControl, owner, scene)
    local createListControl = panelControl:GetNamedChild("Create")
    ZO_SharedSmithingCreation.Initialize(self, createListControl, owner)

    self.panelControl = panelControl
    self.floatingControl = floatingControl
    self.currentFocus = nil

    self.scrollContainer = panelControl:GetNamedChild("ScrollContainer")
    self.scrollChild = self.scrollContainer:GetNamedChild("ScrollChild")

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
			KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            local tabBarEntries = self:GenerateTabBarEntries()
            self.focus:Activate()
			self.focus:SetFocusByIndex(self.focus:GetFocus()) -- somehow this fixes the "move focus by 2 the first time" issue when entering the screen...remove when lower-level system fixed

			self.owner:SetEnableSkillBar(true)

            local savedFilter = self.typeFilter

            local titleString = ZO_GamepadCraftingUtils_GetLineNameForCraftingType(GetCraftingInteractionType())
            
            local DONT_SHOW_CAPACITY = false
            ZO_GamepadCraftingUtils_SetupGenericHeader(self.owner, titleString, tabBarEntries, DONT_SHOW_CAPACITY)
            ZO_GamepadCraftingUtils_RefreshGenericHeader(self.owner)

            self:SetupTabBar(tabBarEntries, savedFilter)

            self:RefreshAllLists()

            self.inOptionsMenu = false
            self.isCrafting = false

            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
            GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(self:GetCreateTooltipSound())

            self:RefreshScrollPanel()

            self:TriggerUSITutorial()
        elseif newState == SCENE_HIDDEN then
            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
            ZO_InventorySlot_RemoveMouseOverKeybinds()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
			KEYBIND_STRIP:RestoreDefaultExit()

            self.focus:Deactivate()
            self.resultTooltip:SetHidden(true)
            self.interactingWithSameStation = true

			self.owner:SetEnableSkillBar(false)

			ZO_GamepadGenericHeader_Deactivate(self.owner.header)
        end
    end)

    GAMEPAD_SMITHING_CREATION_OPTIONS_SCENE = self.owner:CreateInteractScene(GAMEPAD_SMITHING_CREATION_OPTIONS_SCENE_NAME)
    GAMEPAD_SMITHING_CREATION_OPTIONS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:SetupOptionData()
            self:RefreshOptionList()
            self.optionList:Activate()

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.optionsKeybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            self.optionList:Deactivate()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.optionsKeybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()

            self:RefreshFilters()
            ZO_SavePlayerConsoleProfile()
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", function() 
        if SCENE_MANAGER:IsShowing(scene.name) then
            self.materialQuantitySpinner:Deactivate()
            ZO_GamepadGenericHeader_Deactivate(self.owner.header)
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", function() 
        if SCENE_MANAGER:IsShowing(scene.name) then
            -- only reactivate this right away if it's focused - selecting it will activate it otherwise
            if self.focus:IsFocused(self.materialQuantitySpinner) then 
                self:ActivateMaterialQuantitySpinner()
            end

            if self.shouldActivateTabBar then
                ZO_GamepadGenericHeader_Activate(self.owner.header)
            end

            self.isCrafting = false

            self:RefreshTooltips()
        end
    end)
end

function ZO_GamepadSmithingCreation:PerformDeferredInitialization()
    if self.keybindStripDescriptor then return end

    local scrollListControl = ZO_SmithingHorizontalScrollList_Gamepad
    local traitUnknownFont = "ZoFontGamepadCondensed34"
    local notEnoughInInventoryFont = "ZoFontGamepadCondensed34"
    local listSlotTemplate = "ZO_GamepadSmithingListSlot"

    self:InitializeTraitList(scrollListControl, traitUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    self:InitializeStyleList(scrollListControl, traitUnknownFont, notEnoughInInventoryFont, listSlotTemplate)
    self:InitializePatternList(scrollListControl, listSlotTemplate)

    local HIDE_SPINNER_WHEN_RANK_REQUIREMENT_NOT_MET = true
    self:InitializeMaterialList(scrollListControl, ZO_Spinner_Gamepad, HIDE_SPINNER_WHEN_RANK_REQUIREMENT_NOT_MET, listSlotTemplate)

    self:InitializeKeybindStripDescriptors()

    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self.resultTooltip = self.floatingControl:GetNamedChild("ResultTooltip")

    self:InitializeOptionList()
    self:SetupSavedVars()

    self:SetupListActivationFunctions()

    self:SetupScrollPanel()
    self:InitializeFocusItems()

    self.styleList:SetToggleType(GAMEPAD_SMITHING_TOGGLE_TYPE_STYLE)
end

do
    local selectedColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
    local disabledColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

    local COLOR_TABLE = {
        [true] = selectedColor,
        [false] = disabledColor,
    }

    local function ActivationChangedFn(list, activated)
        local parentControl = list:GetControl():GetParent()

        parentControl.selectedLabel:SetColor(COLOR_TABLE[activated]:UnpackRGBA())
    end

    function ZO_GamepadSmithingCreation:SetupListActivationFunctions()
        local lists = {self.patternList, self.materialList, self.styleList, self.traitList}

        for _, entry in pairs(lists) do
            entry:SetOnActivatedChangedFunction(ActivationChangedFn)
            ActivationChangedFn(entry, false)
        end
    end
end

function ZO_GamepadSmithingCreation:GenerateTabBarEntries()
    local tabBarEntries = {}

    local function AddEntry(name, mode, allowed)
        if allowed then
            local entry = {}
            entry.text = name
            entry.callback = function()
                self.typeFilter = mode
                self:HandleDirtyEvent()
            end
            entry.mode = mode

            table.insert(tabBarEntries, entry)
        end
    end

    local weaponsAllowed = CanSmithingWeaponPatternsBeCraftedHere()
    local apparelAllowed = CanSmithingApparelPatternsBeCraftedHere()

	local setsAllowed = CanSmithingSetPatternsBeCraftedHere()
	local setWeaponsAllowed = weaponsAllowed and setsAllowed
	local setApparelAllowed = apparelAllowed and setsAllowed

    AddEntry(GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_WEAPONS), ZO_SMITHING_CREATION_FILTER_TYPE_WEAPONS, weaponsAllowed)
    AddEntry(GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_ARMOR), ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR, apparelAllowed)
    AddEntry(GetString(SI_SMITHING_CREATION_FILTER_SET_WEAPONS), ZO_SMITHING_CREATION_FILTER_TYPE_SET_WEAPONS, setWeaponsAllowed)
    AddEntry(GetString(SI_SMITHING_CREATION_FILTER_SET_ARMOR), ZO_SMITHING_CREATION_FILTER_TYPE_SET_ARMOR, setApparelAllowed)

    return tabBarEntries
end

function ZO_GamepadSmithingCreation:SetupTabBar(tabBarEntries, savedFilter)
    if #tabBarEntries == 1 then
        self.typeFilter = ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR
        self.shouldActivateTabBar = false
    else
        ZO_GamepadGenericHeader_Activate(self.owner.header)
        self.shouldActivateTabBar = true

        local filterFound = false

        for index, entry in pairs(tabBarEntries) do
            if savedFilter == entry.mode then
                self.typeFilter = savedFilter
                ZO_GamepadGenericHeader_SetActiveTabIndex(self.owner.header, index)
                filterFound = true
                break
            end
        end

        if not filterFound then
            self.typeFilter = tabBarEntries[1].mode
            ZO_GamepadGenericHeader_SetActiveTabIndex(self.owner.header, 1)
        end
    end
end

function ZO_GamepadSmithingCreation:RefreshAvailableFilters(dontReselect)
    self:HandleDirtyEvent()
end

function ZO_GamepadSmithingCreation:InitializeKeybindStripDescriptors()
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

    -- Perform craft
    local craftButton =
    {
        keybind = "UI_SHORTCUT_SECONDARY",
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        name = function()
            local cost = GetCostToCraftSmithingItem(self:GetAllCraftingParameters())
            return ZO_CraftingUtils_GetCostToCraftString(cost)
        end,

        callback = function()
            if not self.inOptionsMenu then
                self.isCrafting = true
                self:Create()
            end
        end,

        visible = function()
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                return self:IsCraftable()
            end
        end
    }

    local function ShowUniversalItemKeybind()
        if self.selectedList and self.selectedList:GetToggleType() then
            if self.selectedList:GetToggleType() == GAMEPAD_SMITHING_TOGGLE_TYPE_STYLE then
                return true
            end
        else
            return false
        end
    end

    local toggleTypeButton =
    {
        keybind = "UI_SHORTCUT_PRIMARY",
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        name =  function()
                    local universalStyleItemCount = GetCurrentSmithingStyleItemCount(ZO_ADJUSTED_UNIVERSAL_STYLE_ITEM_INDEX)
                    local universalStyleItemCountString = zo_strformat(GetString(SI_GAMEPAD_SMITHING_UNIVERSAL_STYLE_ITEM_COUNT), universalStyleItemCount)

                    if universalStyleItemCount == 0 then
                        universalStyleItemCountString = ZO_ERROR_COLOR:Colorize(universalStyleItemCountString)
                    end

                    return zo_strformat(GetString(SI_GAMEPAD_SMITHING_TOGGLE_UNIVERSAL_STYLE), universalStyleItemCountString)
                end,

        callback = function()
            local haveMaterialChecked = self.optionDataList[GAMEPAD_SMITHING_CREATION_OPTION_FILTER_MATERIALS].checked
            local haveKnowledgeChecked = self.optionDataList[GAMEPAD_SMITHING_CREATION_OPTION_FILTER_KNOWLEDGE].checked
            self:OnFilterChanged(haveMaterialChecked, haveKnowledgeChecked, not  self:GetIsUsingUniversalStyleItem())
            self:RefreshStyleList()
            self:RefreshTooltips()
        end,

        visible = ShowUniversalItemKeybind
    }

    local purchaseButton = 
    {
        keybind= "UI_SHORTCUT_RIGHT_STICK",
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        name = GetString(SI_GAMEPAD_SMITHING_PURCHASE_MORE),

        callback = function()
            ShowMarketAndSearch("", MARKET_OPEN_OPERATION_UNIVERSAL_STYLE_ITEM)
        end,

        visible = ShowUniversalItemKeybind
    }

    self.keybindStripDescriptor =
    {
        -- Options (filtering)
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
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
            end
        },
    }

	table.insert(self.keybindStripDescriptor, craftButton)
	table.insert(self.keybindStripDescriptor, startButton)
	table.insert(self.keybindStripDescriptor, backButton)
    table.insert(self.keybindStripDescriptor, toggleTypeButton)
    table.insert(self.keybindStripDescriptor, purchaseButton)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)

    -- options list keybinds
    self.optionsKeybindStripDescriptor = {}
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.optionsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:SelectOption() end)
    table.insert(self.optionsKeybindStripDescriptor, startButton)
	table.insert(self.optionsKeybindStripDescriptor, optionsBackButton)

end

function ZO_GamepadSmithingCreation:RefreshTooltips()
    if self.selectedList and self.selectedList:GetToggleType() then
        if self.selectedList:GetToggleType() == GAMEPAD_SMITHING_TOGGLE_TYPE_STYLE then
            if self.savedVars.useUniversalStyleItemChecked then
                GAMEPAD_TOOLTIPS:LayoutUniversalStyleItem(GAMEPAD_LEFT_TOOLTIP, self:GetUniversalStyleItemLink())
            else
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            end
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

do
    local ACTIVE = true

    function ZO_GamepadSmithingCreation:InitializeFocusItems()
        self.activateFn = function(focus, data)
            self.selectedList = focus
            focus:Activate()
            self:UpdateScrollPanel(focus)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            self:UpdateBorderHighlight(focus, ACTIVE)
            self:RefreshTooltips()
        end

        self.deactivateFn = function(focus, data)
            focus:Deactivate()
            self:UpdateBorderHighlight(focus, not ACTIVE)
        end

        local entries =
        {
            {
                control = self.patternList,
            },
            {
                control = self.materialList,
            },
            {
                control = self.materialQuantitySpinner,
                canFocus = function(item) return not item:GetControl():IsHidden() end,
                activate = function(focus, data)
                    self.selectedList = nil
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                    self:ActivateMaterialQuantitySpinner()
                    self:UpdateScrollPanel(focus)
                    self:UpdateBorderHighlight(focus, ACTIVE)
                    self:RefreshTooltips()
                end,
            },
            {
                control = self.styleList,
            },
            {
                control = self.traitList,
            },
        }

        self.focus = ZO_GamepadFocus:New(self.control)
        for _, v in pairs(entries) do
            if not v.activate then
                v.activate = self.activateFn
            end
            v.deactivate = self.deactivateFn
            self.focus:AddEntry(v)
        end
    end

    function ZO_GamepadSmithingCreation:SetupScrollPanel()
        local create = self.panelControl:GetNamedChild("Create")
        create:SetParent(self.scrollChild)
        create:ClearAnchors()
        create:SetAnchor(TOPLEFT, self.scrollChild, TOPLEFT)
        create:SetAnchor(TOPRIGHT, self.scrollChild, TOPRIGHT)

        self.panelControl:GetNamedChild("ScrollContainerScroll"):SetHandler("OnScrollExtentsChanged", function(...) self:OnScrollExtentsChanged(...) end)

        local lists = {self.patternList, self.materialList, self.styleList, self.traitList}

        for _, entry in pairs(lists) do
            self:UpdateBorderHighlight(entry, not ACTIVE)
        end
    end
end

function ZO_GamepadSmithingCreation:OnScrollExtentsChanged(scroll, horizontalExtents, verticalExtents)
    -- rescroll visible area if necessary
    if verticalExtents > 0 then
        self:UpdateScrollPanel(self.currentFocus)
    end
end

function ZO_GamepadSmithingCreation:RefreshScrollPanel()
    -- fix list icons
    self:RefreshAllLists()
end

do
    local SCROLL_PADDING_OFFSET = ZO_GAMEPAD_SMITHING_CONTAINER_ITEM_PADDING_Y * 2

    function ZO_GamepadSmithingCreation:UpdateScrollPanel(focus)
        self.currentFocus = focus
        local focusControlParent = focus:GetControl():GetParent()

        local scrollTop = self.scrollContainer:GetTop() + SCROLL_PADDING_OFFSET
        local scrollBottom = self.scrollContainer:GetBottom() - SCROLL_PADDING_OFFSET
        local controlTop = focusControlParent:GetTop()
        local controlBottom = focusControlParent:GetBottom()
        local controlHeight = focusControlParent:GetHeight() + ZO_GAMEPAD_SMITHING_CONTAINER_ITEM_PADDING_Y

        if controlTop <= scrollTop then
            while(controlTop <= scrollTop) do
                ZO_ScrollRelative(self.scrollContainer, -controlHeight)
                controlTop = controlTop + controlHeight
            end
        elseif controlBottom >= scrollBottom then
            while(controlBottom >= scrollBottom) do
                ZO_ScrollRelative(self.scrollContainer, controlHeight)
                controlBottom = controlBottom - controlHeight
            end
        end
    end
end

function ZO_GamepadSmithingCreation:UpdateBorderHighlight(focus, active)
    local focusControlParent = focus:GetControl():GetParent()
    focusControlParent.inactiveBG:SetHidden(active)
    focusControlParent.activeBG:SetHidden(not active)
end

function ZO_GamepadSmithingCreation:UpdateUniversalStyleItemInfo()
    self:RefreshFilters()
    self:RefreshStyleList()
end

function ZO_GamepadSmithingCreation:InitializeOptionList()
    self.optionList = ZO_GamepadVerticalItemParametricScrollList:New(self.panelControl:GetNamedChild("OptionsList"))
    self.optionList:SetAlignToScreenCenter(true)

    self.optionList:AddDataTemplate(GAMEPAD_SMITHING_CREATION_OPTIONS_TEMPLATE, ZO_GamepadCheckBoxTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.optionList:AddDataTemplateWithHeader(GAMEPAD_SMITHING_CREATION_OPTIONS_TEMPLATE, ZO_GamepadCheckBoxTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsMenuEntryHeaderTemplate")

    local function HandleInventoryChanged()
        self:UpdateUniversalStyleItemInfo()
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)

    self.optionDataList = {}
    self:SetupOptionData()

    self.optionList:SetOnSelectedDataChangedCallback(
        function(list, selectedData)
            self.currentlySelectedOptionData = selectedData
            self:UpdateOptionLeftTooltip(selectedData)
        end
    )
end

function ZO_GamepadSmithingCreation:UpdateOptionLeftTooltip(selectedData)
    if selectedData then
        if selectedData.optionType == GAMEPAD_SMITHING_CREATION_OPTION_FILTER_KNOWLEDGE then
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, selectedData.text, GetString(SI_CRAFTING_HAVE_KNOWLEDGE_TOOLTIP))
        elseif selectedData.optionType == GAMEPAD_SMITHING_CREATION_OPTION_FILTER_MATERIALS then
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, selectedData.text, GetString(SI_CRAFTING_HAVE_MATERIALS_TOOLTIP))
        end
    end
end

function ZO_GamepadSmithingCreation:SetupSavedVars()
    local defaults = { haveMaterialChecked = false, haveKnowledgeChecked = false, useUniversalStyleItemChecked = false}
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 2, "GamepadSmithingCreation", defaults)

    self:AddCheckedStateToOption(GAMEPAD_SMITHING_CREATION_OPTION_FILTER_MATERIALS, self.savedVars.haveMaterialChecked)
    self:AddCheckedStateToOption(GAMEPAD_SMITHING_CREATION_OPTION_FILTER_KNOWLEDGE, self.savedVars.haveKnowledgeChecked)

   	if self.savedVars.haveKnowledgeChecked then
		self:SelectValidKnowledgeIndices()
	end
    self:HandleDirtyEvent()
end

function ZO_GamepadSmithingCreation:AddCheckedStateToOption(option, checkedState)
    if self.optionDataList[option] then
        self.optionDataList[option].checked = checkedState
    end
end

function ZO_GamepadSmithingCreation:ShowOptions()
    SCENE_MANAGER:Push(GAMEPAD_SMITHING_CREATION_OPTIONS_SCENE_NAME)
end

function ZO_GamepadSmithingCreation:SetupOptionData()
    if self.optionDataList == nil then return end

    local skillType, skillIndex = GetCraftingSkillLineIndices(GetCraftingInteractionType())
    local lineName = GetSkillLineInfo(skillType, skillIndex)
    for key, optionInfo in pairs(g_options) do
        local headerText = nil
        if optionInfo.header then
            headerText = zo_strformat(optionInfo.header, lineName)
        end

        local newOptionData = ZO_GamepadEntryData:New(optionInfo.optionName)
        local savedVarTarget = optionInfo.toggleFunctionTarget
        newOptionData.setChecked = function(control,checked) 
                                        self.optionDataList[key].checked = checked
                                   end
        newOptionData:SetHeader(headerText)
        newOptionData.optionType = key

        self.optionDataList[key] = newOptionData
    end

	if self.savedVars then
		self.optionDataList[GAMEPAD_SMITHING_CREATION_OPTION_FILTER_MATERIALS].checked = self.savedVars.haveMaterialChecked
		self.optionDataList[GAMEPAD_SMITHING_CREATION_OPTION_FILTER_KNOWLEDGE].checked = self.savedVars.haveKnowledgeChecked
	end
end

function ZO_GamepadSmithingCreation:RefreshOptionList()
    self.optionList:Clear()

    local i = 1
    for key, optionData in pairs(self.optionDataList) do
        if i == 1 then
            self.optionList:AddEntryWithHeader(GAMEPAD_SMITHING_CREATION_OPTIONS_TEMPLATE, optionData)
        else
            self.optionList:AddEntry(GAMEPAD_SMITHING_CREATION_OPTIONS_TEMPLATE, optionData)
        end
        i = i + 1
    end

    self.optionList:Commit()
end

function ZO_GamepadSmithingCreation:SelectOption()
    local targetControl = self.optionList:GetTargetControl()
    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
    self:RefreshFilters()
end

function ZO_GamepadSmithingCreation:RefreshFilters()
    local haveMaterialChecked = self.optionDataList[GAMEPAD_SMITHING_CREATION_OPTION_FILTER_MATERIALS].checked
    local haveKnowledgeChecked = self.optionDataList[GAMEPAD_SMITHING_CREATION_OPTION_FILTER_KNOWLEDGE].checked

    local filterChanged = (haveMaterialChecked ~= self.savedVars.haveMaterialChecked) or
                          (haveKnowledgeChecked ~= self.savedVars.haveKnowledgeChecked)
    if filterChanged then
        self:OnFilterChanged(haveMaterialChecked, haveKnowledgeChecked,  self:GetIsUsingUniversalStyleItem())
    end
end

function ZO_GamepadSmithingCreation:UpdateTooltipInternal()
    if self:AreSelectionsValid() then
        self.resultTooltip:SetHidden(false)
        self.resultTooltip.tip:ClearLines()
        self:SetupResultTooltip(self:GetAllCraftingParameters())
    else
        self.resultTooltip:SetHidden(true)
    end
end

function ZO_GamepadSmithingCreation:SetupResultTooltip(selectedPatternIndex, selectedMaterialIndex, selectedMaterialQuantity, selectedStyleIndex, selectedTraitIndex)
    -- The smithing style list starts at index 2, but the itemstyle enum starts at 1...kick this down to be in sync for proper tooltip style display
    selectedStyleIndex = selectedStyleIndex - 1
        
    self.resultTooltip.tip:LayoutPendingSmithingItem(selectedPatternIndex, selectedMaterialIndex, selectedMaterialQuantity, selectedStyleIndex, selectedTraitIndex)
end

function ZO_GamepadSmithingCreation:ActivateMaterialQuantitySpinner()
    if not ZO_CraftingUtils_IsPerformingCraftProcess() then
        self.materialQuantitySpinner:Activate()
    end
end

do
    local KEYBOARD_TO_GAMEPAD_LOOKUP = {
        [SI_SMITHING_SELECTED_PATTERN] = SI_GAMEPAD_SMITHING_SELECTED_PATTERN,
        [SI_SMITHING_MATERIAL_QUANTITY] = SI_GAMEPAD_SMITHING_MATERIAL_QUANTITY,
        [SI_SMITHING_STYLE_DESCRIPTION] = SI_GAMEPAD_SMITHING_STYLE_DESCRIPTION,
        [SI_SMITHING_TRAIT_DESCRIPTION] = SI_GAMEPAD_SMITHING_TRAIT_DESCRIPTION,
        [SI_CRAFTING_UNIVERSAL_STYLE_DESCRIPTION] = SI_GAMEPAD_SMITHING_UNIVERSAL_STYLE_DESCRIPTION,
    }

    function ZO_GamepadSmithingCreation:GetPlatformFormattedTextString(stringId, ...)
        return zo_strformat(KEYBOARD_TO_GAMEPAD_LOOKUP[stringId], ...)
    end
end

function ZO_GamepadSmithingCreation:SetLabelHidden(label, hidden)
    if hidden then
        label:SetText("")
    end
end

function ZO_GamepadSmithingCreation:OnStyleChanged(selectedData)
    ZO_SharedSmithingCreation.OnStyleChanged(selectedData)

    self.patternList:RefreshVisible()    
end
