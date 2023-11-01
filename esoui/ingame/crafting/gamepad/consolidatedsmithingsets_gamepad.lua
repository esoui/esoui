
-----------------------------------------------
-- Consolidated Smithing Set Selection Gamepad
-----------------------------------------------

local SET_SELECTION_CATEGORY_MODE = 1
local SET_SELECTION_SUBCATEGORY_MODE = 2

ZO_ConsolidatedSmithingSetSelection_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_ConsolidatedSmithingSetSelection_Gamepad:Initialize(control)
    CONSOLIDATED_SMITHING_SET_SELECTION_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW)

    self:InitializeAddSetsDialog()
    self.selectedItems = {}

    local function OnTextSearchTextChanged(editBox)
        CONSOLIDATED_SMITHING_SET_DATA_MANAGER:SetSearchString(editBox:GetText())
    end
    self:AddSearch(self.textSearchKeybindStripDescriptor, OnTextSearchTextChanged)

    self.control:RegisterForEvent(EVENT_CONSOLIDATED_STATION_SETS_UPDATED, function()
        if CONSOLIDATED_SMITHING_SET_SELECTION_GAMEPAD_FRAGMENT:IsShowing() then
            self:RefreshList()
        end
    end)

    local function OnQuestInformationUpdated(updatedQuestInfo)
        self.shouldImproveForQuest = updatedQuestInfo.hasItemToImproveForWrit
        self.consolidatedItemSetIdForQuest = updatedQuestInfo.consolidatedItemSetId
        if CONSOLIDATED_SMITHING_SET_SELECTION_GAMEPAD_FRAGMENT:IsShowing() then
            self:GetCurrentList():RefreshVisible()
        end
    end
    CRAFT_ADVISOR_MANAGER:RegisterCallback("QuestInformationUpdated", OnQuestInformationUpdated)

    ZO_WRIT_ADVISOR_GAMEPAD:RegisterCallback("CycleActiveQuest", function()
        if CONSOLIDATED_SMITHING_SET_SELECTION_GAMEPAD_FRAGMENT:IsShowing() then
            --Re-narrate the current selection when cycling between writs
            SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())
        end
    end)

    CONSOLIDATED_SMITHING_SET_DATA_MANAGER:RegisterCallback("UpdateSearchResults", function() 
        if CONSOLIDATED_SMITHING_SET_SELECTION_GAMEPAD_FRAGMENT:IsShowing() then
            self:RefreshList()
        end
    end)

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end
    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    self.setFilters = {}
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:OnDeferredInitialize()
    self:RefreshHeader()
    self:InitializeLists()
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:PerformUpdate()
   self.dirty = false
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:SetupSavedVars()
    local defaults =
    {
        hideLockedChecked = false,
    }
    self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "GamepadConsolidatedSmithing", defaults)
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:RefreshHeader()
    --First, set up the header data that never changes
    if not self.headerData then
        self.headerData =
        {
            titleText = function()
                if self.selectedCategoryData then
                    return self.selectedCategoryData:GetFormattedName()
                else
                    return ZO_GamepadCraftingUtils_GetLineNameForCraftingType(GetCraftingInteractionType())
                end
            end,
            data1HeaderText = GetString(SI_SMITHING_CONSOLIDATED_STATION_ITEM_SETS_UNLOCKED_HEADER),
            data1Text = function()
                local totalSets = GetNumConsolidatedSmithingSets()
                local unlockedSets = GetNumUnlockedConsolidatedSmithingSets()
                return zo_strformat(SI_SMITHING_CONSOLIDATED_STATION_ITEM_SETS_UNLOCKED_VALUE_FORMATTER, unlockedSets, totalSets)
            end,
        }
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            enabled = function()
                --If we are trying to select set data, make sure the set is actually unlocked first
                if self.mode == SET_SELECTION_SUBCATEGORY_MODE then
                    local targetData = self.setsList:GetTargetData()
                    if targetData then
                        return targetData:IsUnlocked()
                    end
                end
                return true
            end,
            callback = function()
                if self.mode == SET_SELECTION_CATEGORY_MODE then
                    local categoryData = self.categoryList:GetTargetData()
                    if categoryData and categoryData:IsInstanceOf(ZO_ConsolidatedSmithingDefaultCategoryData) then
                        --Default category
                        local NO_ITEM_SET = nil
                        SetActiveConsolidatedSmithingSetByIndex(NO_ITEM_SET)
                        SCENE_MANAGER:HideCurrentScene()
                    else
                        --Standard category
                        self.mode = SET_SELECTION_SUBCATEGORY_MODE
                        self.selectedCategoryData = categoryData
                        self:SetCurrentList(self.setsList)
                        self.setsList:SetFirstIndexSelected()
                        self:RefreshList()
                    end
                else
                    local setData = self.setsList:GetTargetData()
                    if setData then
                        --Standard set
                        SetActiveConsolidatedSmithingSetByIndex(setData:GetSetIndex())
                        SCENE_MANAGER:HideCurrentScene()
                    end
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        --Add Set
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_ITEM_SET),
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
        --Toggle Locked
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                if self.savedVars.hideLockedChecked then
                    return GetString(SI_SMITHING_CONSOLIDATED_STATION_SHOW_LOCKED)
                else
                    return GetString(SI_SMITHING_CONSOLIDATED_STATION_HIDE_LOCKED)
                end
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            callback = function()
                --Re-narrate the current selection when we toggle the locked filter
                --Order matters: Do this before we refresh the list so if we end up getting kicked to the search box this doesn't stomp that narration
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())

                self.savedVars.hideLockedChecked = not self.savedVars.hideLockedChecked
                self:RefreshList()
                self:RefreshKeybinds()
            end,
        },
    }

    -- Back
    local keybindStripBackDescriptor = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
        if self.mode == SET_SELECTION_SUBCATEGORY_MODE then
            self.mode = SET_SELECTION_CATEGORY_MODE
            self.selectedCategoryData = nil
            self:SetCurrentList(self.categoryList)
            self:RefreshList()
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end)
    keybindStripBackDescriptor.visible = function()
        return not ZO_CraftingUtils_IsPerformingCraftProcess()
    end
    table.insert(self.keybindStripDescriptor, keybindStripBackDescriptor)

    self.textSearchKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            callback = function()
                self:SetTextSearchFocused(true)
            end,
        },
        --Add Set
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_ITEM_SET),
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
        --Toggle Locked
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                if self.savedVars.hideLockedChecked then
                    return GetString(SI_SMITHING_CONSOLIDATED_STATION_SHOW_LOCKED)
                else
                    return GetString(SI_SMITHING_CONSOLIDATED_STATION_HIDE_LOCKED)
                end
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            callback = function()
                self.savedVars.hideLockedChecked = not self.savedVars.hideLockedChecked
                self:RefreshList()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.textSearchKeybindStripDescriptor)
                --Re-narrate when we toggle the locked filter from the text search header
                SCREEN_NARRATION_MANAGER:QueueTextSearchHeader(self.textSearchHeaderFocus)
            end,
        },
    }

    -- Back
    local textSearchBackDescriptor = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
        if self.mode == SET_SELECTION_SUBCATEGORY_MODE then
            self.mode = SET_SELECTION_CATEGORY_MODE
            self.selectedCategoryData = nil
            self:SetCurrentList(self.categoryList)
            self:RefreshList()

            --Re-narrate when switching categories from the text search header
            local NARRATE_HEADER = true
            SCREEN_NARRATION_MANAGER:QueueTextSearchHeader(self.textSearchHeaderFocus, NARRATE_HEADER)
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end)
    textSearchBackDescriptor.visible = function()
        return not ZO_CraftingUtils_IsPerformingCraftProcess()
    end
    table.insert(self.textSearchKeybindStripDescriptor, textSearchBackDescriptor)

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.textSearchKeybindStripDescriptor)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:InitializeLists()
    local function SetupCategoryList(list)
        list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_ConsolidatedSmithingSetCategoryData.Equals, "DefaultCategory")
        list:AddDataTemplate("ZO_ConsolidatedSmithingSetCategory_Gamepad_Template", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_ConsolidatedSmithingSetCategoryData.Equals, "Category")
    end

    local function SetupSetsList(list)
        list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ItemSet")
    end

    self.categoryList = self:AddList("Categories", SetupCategoryList)
    self.setsList = self:AddList("Sets", SetupSetsList)
    self.setsList:SetNoItemText(GetString(SI_GAMEPAD_SMITHING_CONSOLIDATED_STATION_ITEM_SETS_LIST_EMPTY_TEXT))

    self.mode = SET_SELECTION_CATEGORY_MODE
end

do
    local function CreateCategoryEntry(categoryData, shouldShowQuestPin)
        local categoryName = categoryData:GetFormattedName()
        local gamepadIcon = categoryData:GetGamepadIcon()

        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)

        local numSets = categoryData:GetNumSets()
        if numSets > 0 then
            local MIN_SETS = 0
            local numUnlockedSets = categoryData:GetNumUnlockedSets()
            entryData:SetBarValues(MIN_SETS, numSets, numUnlockedSets)
        end

        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)
        entryData.hasCraftingQuestPin = shouldShowQuestPin

        return entryData
    end

    function ZO_ConsolidatedSmithingSetSelection_Gamepad:RefreshCategoryList()
        local list = self.categoryList
        list:Clear()

        --Add the special default category first
        list:AddEntry("ZO_GamepadItemEntryTemplate", CreateCategoryEntry(CONSOLIDATED_SMITHING_DEFAULT_CATEGORY_DATA))

        local categoryList = CONSOLIDATED_SMITHING_SET_DATA_MANAGER:GetSortedCategories()
        for _, categoryData in ipairs(categoryList) do
            --Only add categories with at least one child that passes the current filters
            if categoryData:AnyChildPassesFilters(self.setFilters) then
                local function ShouldShowQuestPin()
                    if not self.shouldImproveForQuest and self.consolidatedItemSetIdForQuest then
                        --If the category contains the item set for the currently tracked quest, include a quest pin
                        local setDataForQuest = categoryData:GetSetDataByItemSetId(self.consolidatedItemSetIdForQuest)
                        if setDataForQuest then
                            return true
                        end
                    end
                    return false
                end
                list:AddEntry("ZO_ConsolidatedSmithingSetCategory_Gamepad_Template", CreateCategoryEntry(categoryData, ShouldShowQuestPin))
            end
        end

        list:Commit()
    end
end

do
    local function CreateSetEntry(setData, shouldShowQuestPin)
        local setName = setData:GetFormattedName()
        local entryData = ZO_GamepadEntryData:New(setName)
        entryData:SetDataSource(setData)
        entryData:SetIconTintOnSelection(true)
        entryData.hasCraftingQuestPin = shouldShowQuestPin
        entryData.isLocked = not setData:IsUnlocked()

        return entryData
    end

    function ZO_ConsolidatedSmithingSetSelection_Gamepad:RefreshSetsList()
        local list = self.setsList
        list:Clear()

        if self.selectedCategoryData then
            for _, setData in self.selectedCategoryData:SetIterator(self.setFilters) do
                local function ShouldShowQuestPin()
                    return not self.shouldImproveForQuest and self.consolidatedItemSetIdForQuest == setData:GetItemSetId()
                end

                list:AddEntry("ZO_GamepadItemEntryTemplate", CreateSetEntry(setData, ShouldShowQuestPin))
            end
        end

        list:Commit()
    end
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:RefreshList()
    self:RefreshSetFilters()
    if self.mode == SET_SELECTION_CATEGORY_MODE then
        self:RefreshCategoryList()
    elseif self.mode == SET_SELECTION_SUBCATEGORY_MODE then
        self:RefreshSetsList()
    end

    --If the current list is now empty, enter the header
    local list = self:GetCurrentList()
    if list:IsEmpty() then
        self:RequestEnterHeader()
    end

    self:RefreshHeader()
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:OnTargetChanged(list, selectedData)
    self:RefreshTargetTooltip(list, selectedData)
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:ResetTooltips()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:RefreshTargetTooltip(list, selectedData)
    self:ResetTooltips()
    if selectedData and self.mode == SET_SELECTION_SUBCATEGORY_MODE and not self:IsHeaderActive() then
        GAMEPAD_TOOLTIPS:LayoutGenericItemSet(GAMEPAD_LEFT_TOOLTIP, selectedData:GetItemSetId())
    end
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:RefreshSetFilters()
    ZO_ClearNumericallyIndexedTable(self.setFilters)
    if CONSOLIDATED_SMITHING_SET_DATA_MANAGER:HasSearchFilter() then
        table.insert(self.setFilters, ZO_ConsolidatedSmithingSetData.IsSearchResult)
    end

    if self.savedVars.hideLockedChecked then
        table.insert(self.setFilters, ZO_ConsolidatedSmithingSetData.IsUnlocked)
    end
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad:InitializeAddSetsDialog()
    --Refresh the selected state of each entry in the list
    local function RefreshSelected(dialog)
        local parametricListEntries = dialog.info.parametricList
        for _, entryInfo in ipairs(parametricListEntries) do
            local entryData = entryInfo.entryData
            entryData:SetSelected(ZO_IsElementInNumericallyIndexedTable(self.selectedItems, entryData.itemInfo))
        end

        ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(dialog)
    end

    ZO_Dialogs_RegisterCustomDialog("CONSOLIDATED_SMITHING_ADD_SETS_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_TITLE),
        },
        mainText =
        {
            text = GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_DESCRIPTION),
        },
        setup = function(dialog, data)
            local parametricListEntries = dialog.info.parametricList

            ZO_ClearNumericallyIndexedTable(self.selectedItems)
            ZO_ClearNumericallyIndexedTable(parametricListEntries)

            --Generate the initial list of consumable items.
            local virtualInventoryList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, CanItemBeConsumedByConsolidatedStation)

            local listedSets = {}
            for itemId, itemInfo in pairs(virtualInventoryList) do
                local itemSetId = GetSmithingStationItemSetIdFromItem(itemInfo.bag, itemInfo.index)
                --Filter out any stations with the same set as a station we have already added to the list
                if not listedSets[itemSetId] then
                    local itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(itemInfo.bag, itemInfo.index))
                    local icon, _, _, _, _, _, _, _, displayQuality = GetItemInfo(itemInfo.bag, itemInfo.index)
                    local entryData = ZO_GamepadEntryData:New(itemName, icon)
                    entryData:SetNameColors(entryData:GetColorsBasedOnQuality(displayQuality))
                    entryData.setup = ZO_SharedGamepadEntry_OnSetup
                    entryData.tooltipFunction = function() GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_DIALOG_TOOLTIP, itemInfo.bag, itemInfo.index) end
                    entryData.itemInfo = itemInfo
                    entryData.narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP

                    local listItem =
                    {
                        template = "ZO_GamepadItemSubEntryTemplate",
                        entryData = entryData,
                    }

                    table.insert(parametricListEntries, listItem)
                    listedSets[itemSetId] = true
                end
            end

            --Sort the entries alphabetically
            local function SortComparator(left, right)
                return left.entryData:GetText() < right.entryData:GetText()
            end
            table.sort(parametricListEntries, SortComparator)

            dialog.setupFunc(dialog)
        end,
        parametricList = {}, -- Generated Dynamically
        blockDialogReleaseOnPress = true, -- We need to manually control when we release so we can use the select/deselect keybind to select entries
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            if newSelectedData and newSelectedData.tooltipFunction then
                newSelectedData.tooltipFunction()
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(dialog)
            end
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    local isSelected = ZO_IsElementInNumericallyIndexedTable(self.selectedItems, data.itemInfo)
                    return isSelected and GetString(SI_GAMEPAD_DESELECT_OPTION) or GetString(SI_GAMEPAD_SELECT_OPTION)
                end,
                callback = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    local itemInfo = data.itemInfo
                    if itemInfo then
                        if ZO_IsElementInNumericallyIndexedTable(self.selectedItems, itemInfo) then
                            ZO_RemoveFirstElementFromNumericallyIndexedTable(self.selectedItems, itemInfo)
                        else
                            table.insert(self.selectedItems, itemInfo)
                        end
                        RefreshSelected(dialog)
                        ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("CONSOLIDATED_SMITHING_ADD_SETS_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_DIALOG_CONFIRM,
                enabled = function()
                    return #self.selectedItems > 0
                end,
                callback = function(dialog)
                    ZO_Dialogs_ShowGamepadDialog("CONSOLIDATED_SMITHING_CONFIRM_ADD_SETS_GAMEPAD", { selectedItems = self.selectedItems })
                    ZO_Dialogs_ReleaseDialogOnButtonPress("CONSOLIDATED_SMITHING_ADD_SETS_GAMEPAD")
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
            {
                keybind = "DIALOG_TERTIARY",
                text = SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_SELECT_ALL,
                callback = function(dialog)
                    --Clear out the selected items table and then go through and add every entry
                    ZO_ClearNumericallyIndexedTable(self.selectedItems)
                    local parametricListEntries = dialog.info.parametricList
                    for _, entryInfo in ipairs(parametricListEntries) do
                        local entryData = entryInfo.entryData
                        table.insert(self.selectedItems, entryData.itemInfo)
                    end

                    RefreshSelected(dialog)
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
        },
    })

    --Confirmation dialog
    ZO_Dialogs_RegisterCustomDialog("CONSOLIDATED_SMITHING_CONFIRM_ADD_SETS_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        canQueue = true,
        title =
        {
            text = SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_TITLE,
        },
        mainText =
        {
            text = function(dialog)
                local selectedItems = dialog.data.selectedItems
                if #selectedItems > 1 then
                    return zo_strformat(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_MULTIPLE_SELECTED_TEXT, #selectedItems)
                else
                    return GetString(SI_SMITHING_CONSOLIDATED_STATION_ADD_SET_DIALOG_SELECTED_TEXT)
                end
            end,
        },
        buttons =
        {
            {
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local itemsToAdd = dialog.data.selectedItems
                    PrepareConsumeAttunableStationsMessage()

                    --Add each item to the consume message
                    local addedAllItems = true
                    for _, item in ipairs(itemsToAdd) do
                        if not AddItemToConsumeAttunableStationsMessage(item.bag, item.index) then
                            addedAllItems = false
                            break
                        end
                    end

                    --If all items were added successfully, proceed with the consume
                    if addedAllItems then
                        SendConsumeAttunableStationsMessage()
                    end
                end,
            },
            {
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

--Overridden from base
function ZO_ConsolidatedSmithingSetSelection_Gamepad:GetFooterNarration()
    return SMITHING_GAMEPAD:GetFooterNarration()
end

--Overridden from base
function ZO_ConsolidatedSmithingSetSelection_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self.mode = SET_SELECTION_CATEGORY_MODE
    self.selectedCategoryData = nil
    CONSOLIDATED_SMITHING_SET_DATA_MANAGER:SetSearchString(self.textSearchHeaderFocus:GetText())

    SMITHING_GAMEPAD:SetEnableSkillBar(true)

    self:SetCurrentList(self.categoryList)
    self:RefreshList()

    -- Since always defaulting to the category mode, refresh the list before getting the target data.
    local targetData = self.categoryList:GetTargetData()
    self:RefreshTargetTooltip(self.categoryList, targetData)

    GAMEPAD_CRAFTING_RESULTS:SetContextualAnimationControl(CRAFTING_PROCESS_CONTEXT_CONSUME_ATTUNABLE_STATIONS, self.control)
end

--Overridden from base
function ZO_ConsolidatedSmithingSetSelection_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)
    self:ResetTooltips()
    SMITHING_GAMEPAD:SetEnableSkillBar(false)
    GAMEPAD_CRAFTING_RESULTS:SetContextualAnimationControl(CRAFTING_PROCESS_CONTEXT_CONSUME_ATTUNABLE_STATIONS, nil)
end

--Overridden from base
function ZO_ConsolidatedSmithingSetSelection_Gamepad:OnEnterHeader()
    ZO_Gamepad_ParametricList_Screen.OnEnterHeader(self)
    self:ResetTooltips()
end

--Overridden from base
function ZO_ConsolidatedSmithingSetSelection_Gamepad:OnLeaveHeader()
    ZO_Gamepad_ParametricList_Screen.OnLeaveHeader(self)
    local currentList = self:GetCurrentList()
    if currentList then
        self:RefreshTargetTooltip(currentList, currentList:GetTargetData())
    end
end

function ZO_ConsolidatedSmithingSetSelection_Gamepad.OnControlInitialized(control)
    CONSOLIDATED_SMITHING_SET_SELECTION_GAMEPAD = ZO_ConsolidatedSmithingSetSelection_Gamepad:New(control)
end