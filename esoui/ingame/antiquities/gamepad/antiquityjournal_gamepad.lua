ZO_IN_PROGRESS_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD = 153
ZO_IN_PROGRESS_ANTIQUITY_NEAR_EXPIRATION_DATA_ROW_HEIGHT_GAMEPAD = 184
ZO_SCRYABLE_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD = 110
ZO_SCRYABLE_ANTIQUITY_NEAR_EXPIRATION_DATA_ROW_HEIGHT_GAMEPAD = 144
ZO_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD = 85
ZO_ANTIQUITY_SET_1_DATA_ROW_HEIGHT_GAMEPAD = 182
ZO_ANTIQUITY_SET_2_DATA_ROW_HEIGHT_GAMEPAD = 242
ZO_ANTIQUITY_SET_3_DATA_ROW_HEIGHT_GAMEPAD = 302
ZO_ANTIQUITY_SET_4_DATA_ROW_HEIGHT_GAMEPAD = 362
ZO_ANTIQUITY_SECTION_DATA_ROW_HEIGHT_GAMEPAD = 50

local MAX_ANTIQUITIES_PER_ROW = 10
local IN_PROGRESS_ANTIQUITY_ROW_DATA = 1
local IN_PROGRESS_ANTIQUITY_NEAR_EXPIRATION_ROW_DATA = 2
local SCRYABLE_ANTIQUITY_ROW_DATA = 3
local SCRYABLE_ANTIQUITY_NEAR_EXPIRATION_ROW_DATA = 4
local ANTIQUITY_ROW_DATA = 5
local ANTIQUITY_SET_1_ROW_DATA = 6
local ANTIQUITY_SET_2_ROW_DATA = 7
local ANTIQUITY_SET_3_ROW_DATA = 8
local ANTIQUITY_SET_4_ROW_DATA = 9
local ANTIQUITY_SECTION_ROW_DATA = 10

local ANTIQUITY_NEAR_EXPIRATION_DATA_TEMPLATE_MAPPING =
{
    [IN_PROGRESS_ANTIQUITY_ROW_DATA] = IN_PROGRESS_ANTIQUITY_NEAR_EXPIRATION_ROW_DATA,
    [SCRYABLE_ANTIQUITY_ROW_DATA] = SCRYABLE_ANTIQUITY_NEAR_EXPIRATION_ROW_DATA,
}

local ANTIQUITY_SET_ROW_DATA_TEMPLATES =
{
    ANTIQUITY_SET_1_ROW_DATA,
    ANTIQUITY_SET_2_ROW_DATA,
    ANTIQUITY_SET_3_ROW_DATA,
    ANTIQUITY_SET_4_ROW_DATA,
}

local function GetMappedAntiquityNearExpirationTemplateId(templateId)
    return ANTIQUITY_NEAR_EXPIRATION_DATA_TEMPLATE_MAPPING[templateId]
end

local function IsScryableCategory(antiquityCategoryData)
    return antiquityCategoryData:GetId() == ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA:GetId()
end

-- Categories List

ZO_AntiquityJournalGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_AntiquityJournalGamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_AntiquityJournalGamepad:Initialize(control)
    self.autoShowScryable = false

    self:InitializeControl(control)
    self:InitializeControlPools()
    self:InitializeLists()
    self:InitializeEvents()
    self:InitializeOptionsDialog()
end

function ZO_AntiquityJournalGamepad:InitializeControl(control)
    ANTIQUITY_JOURNAL_SCENE_GAMEPAD = ZO_Scene:New("gamepad_antiquity_journal", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ZO_ACTIVATE_ON_SHOW, ANTIQUITY_JOURNAL_SCENE_GAMEPAD)

    ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(ZO_AntiquityJournal_FooterBar_Gamepad)
    ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT.footerBarName = ZO_AntiquityJournal_FooterBar_Gamepad:GetNamedChild("Name")
    ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT.footerBarBar = ZO_AntiquityJournal_FooterBar_Gamepad:GetNamedChild("XPBar")

    self.fragment = ZO_SimpleSceneFragment:New(control)
    ZO_ANTIQUITY_JOURNAL_GAMEPAD_FRAGMENT = self.fragment
    self.fragment:SetHideOnSceneHidden(true)
    self.scene:AddFragment(ZO_ANTIQUITY_JOURNAL_GAMEPAD_FRAGMENT)
end

function ZO_AntiquityJournalGamepad:InitializeLists()
    local function CategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        data:SetNew(data:HasNewLead())
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    self.categoryList = self:GetMainList()
    self.categoryList:AddDataTemplate("ZO_GamepadItemEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    local USE_DEFAULT_COMPARISON = nil
    self.categoryList:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_GamepadMenuEntryHeaderTemplate")
    self.categoryList:SetNoItemText(GetString(SI_ANTIQUITY_EMPTY_LIST))

    self.subcategoryList = self:AddList("subcategories")
    self.subcategoryList:AddDataTemplate("ZO_GamepadItemEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_GamepadMenuEntryHeaderTemplate")
    self.subcategoryList:SetNoItemText(GetString(SI_ANTIQUITY_EMPTY_LIST))

    local function CategoryEqualityFunction(left, right)
        return left:GetId() == right:GetId()
    end

    self.categoryList:SetEqualityFunction("ZO_GamepadItemEntryTemplate", CategoryEqualityFunction)
    self.categoryList:SetEqualityFunction("ZO_GamepadItemEntryTemplateWithHeader", CategoryEqualityFunction)
    self.subcategoryList:SetEqualityFunction("ZO_GamepadItemEntryTemplate", CategoryEqualityFunction)
    self.subcategoryList:SetOnTargetDataChangedCallback(function(list, targetData, oldTargetData)
        self:OnSubcategoryTargetChanged(targetData)
    end)

    -- Initialize each lists' keybinds.
    self.categoryList.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                self:ViewCategory()
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.categoryList.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.subcategoryList.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                if IsScryableCategory(self:GetCurrentSubcategoryData()) and not ZO_IsScryingUnlocked() then
                    return GetString(SI_ANTIQUITY_UPGRADE)
                else
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                end
            end,
            callback = function()
                if IsScryableCategory(self:GetCurrentSubcategoryData()) and not ZO_IsAntiquarianGuildUnlocked() then
                    ZO_ShowAntiquityContentUpgrade()
                else
                    if not ZO_ANTIQUITY_JOURNAL_LIST_GAMEPAD_FRAGMENT:IsHidden() then
                        self:DeactivateCurrentList()
                        self:ActivateAntiquityList()
                        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                    end
                end
            end,
            visible = function()
                if IsScryableCategory(self:GetCurrentSubcategoryData()) and not ZO_IsScryingUnlocked() and ZO_IsAntiquarianGuildUnlocked() then
                    return false
                end
                return true
            end,
        },
        {
            order = 30,
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_GAMEPAD_QUEST_JOURNAL_SCRYABLE_OPTIONS),
            callback = function()
               ZO_Dialogs_ShowGamepadDialog("GAMEPAD_ANTIQUITY_CATEGORY_FILTER_OPTIONS")
            end,
            visible = function()
                local categoryData = self:GetCurrentSubcategoryData()
                return not IsScryableCategory(categoryData)
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.subcategoryList.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:ShowCategoryList()
    end)

    self:SetListsUseTriggerKeybinds(true)
    self:RefreshCategories()
end

function ZO_AntiquityJournalGamepad:InitializeControlPools()
    local function ResetIconControl(control)
        control:SetHidden(true)
        control:SetParent(nil)
        control:ClearAnchors()
        control.antiquityData = nil
    end
    
    self.antiquityIconControlPool = ZO_ControlPool:New("ZO_AntiquityJournalAntiquityFragmentIconTexture_Gamepad", self.control, "AntiquityFragmentIconGamepad")
    self.antiquityIconControlPool:SetCustomResetBehavior(ResetIconControl)
end

function ZO_AntiquityJournalGamepad:InitializeEvents()
    local function OnDataUpdated()
        self:RefreshData()
    end
    ANTIQUITY_DATA_MANAGER:RegisterCallback("AntiquitiesUpdated", OnDataUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityUpdated", OnDataUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityDigSitesUpdated", OnDataUpdated)
    ANTIQUITY_MANAGER:RegisterCallback("OnContentLockChanged", OnDataUpdated)
    EVENT_MANAGER:RegisterForEvent("AntiquityJournal_Gamepad", EVENT_PLAYER_ACTIVATED, OnDataUpdated)

    local function OnSingleAntiquityLeadUpdated(antiquityData)
        MAIN_MENU_GAMEPAD:MarkNewnessDirty()
        if self.categoryList and not self.fragment:IsHidden() then
            self.categoryList:RefreshVisible()
            self.subcategoryList:RefreshVisible()
            self:RefreshAntiquity(antiquityData)
        end
    end
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityLeadAcquired", OnSingleAntiquityLeadUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityNewLeadCleared", OnSingleAntiquityLeadUpdated)
end

do
    local optionsFilterDropdownEntryData
    function ZO_AntiquityJournalGamepad:GetOrCreateFilterOptionsDropdownEntryData()
        if optionsFilterDropdownEntryData == nil then
            optionsFilterDropdownEntryData = ZO_GamepadEntryData:New()
            optionsFilterDropdownEntryData.dropdownEntry = true
            optionsFilterDropdownEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                local entries = {}
                for i = ANTIQUITY_FILTER_MIN_VALUE, ANTIQUITY_FILTER_MAX_VALUE do
                    local function OnItemSelected()
                        self.currentFilter = i
                        self:RefreshAntiquityList()
                    end
                    entries[i] = dropdown:CreateItemEntry(GetString("SI_ANTIQUITYFILTER", i), OnItemSelected)
                    dropdown:AddItem(entries[i])
                end

                dropdown:UpdateItems()

                local IGNORE_CALLBACK = true
                dropdown:TrySelectItemByData(entries[self.currentFilter], IGNORE_CALLBACK)
            end
        end
        return optionsFilterDropdownEntryData
    end
end

function ZO_AntiquityJournalGamepad:InitializeOptionsDialog()
    -- Initialize filter to show all
    self.currentFilter = ANTIQUITY_FILTER_SHOW_ALL

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_ANTIQUITY_CATEGORY_FILTER_OPTIONS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_ANTIQUITY_CATEGORY_OPTIONS_HEADER
        },
        setup = function(dialog)
           local parametricListEntries = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)

            local filterDropdown =
            {
                template = "ZO_GamepadDropdownItem",
                entryData = self:GetOrCreateFilterOptionsDropdownEntryData(),
            }

            table.insert(parametricListEntries, filterDropdown)

            dialog.setupFunc(dialog)
        end,
        parametricList = {}, -- Generated Dynamically
        blockDialogReleaseOnPress = true, -- We need to manually control when we release so we can use the select keybind to activate entries
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.dropdownEntry then
                        local dropdown = targetControl.dropdown
                        dropdown:Activate()
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_ANTIQUITY_CATEGORY_FILTER_OPTIONS")
                end,
            },
        },
        noChoiceCallback = function(dialog)
            local parametricList = dialog.info.parametricList
            for i, entry in ipairs(parametricList) do
                if entry.entryData.action.isDropdown then
                    local control = dialog.entryList:GetControlFromData(entry.entryData)
                    if control then
                        control.dropdown:Deactivate()
                    end
                end
            end
        end
    })
end

function ZO_AntiquityJournalGamepad:GetCurrentFilterSelection()
    return self.currentFilter
end

function ZO_AntiquityJournalGamepad:PerformUpdate()
    self.dirty = false
end

function ZO_AntiquityJournalGamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    local wasJournalScenePreviouslyOnTop = SCENE_MANAGER:WasSceneOnTopOfStack("gamepad_antiquity_journal")
    if wasJournalScenePreviouslyOnTop then
        -- Returning from Antiquity Lore Gamepad scene.
        -- Note that order matters.
        self:ShowSubcategoryList()
        self:DeactivateCurrentList()
        self:ActivateAntiquityList()
    else
        ANTIQUITY_JOURNAL_LIST_GAMEPAD:ClearSelection()
        self:ShowCategoryList()
    end

    if self.autoShowScryable then
        local FOCUS_ANTIQUITY_LIST = true
        self:ViewCategory(ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA, FOCUS_ANTIQUITY_LIST)
        self.autoShowScryable = false
    end

    TriggerTutorial(TUTORIAL_TRIGGER_ANTIQUITY_JOURNAL_OPENED)
end

function ZO_AntiquityJournalGamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)

    ANTIQUITY_JOURNAL_LIST_GAMEPAD:ClearAntiquityTooltip()
    self:DisableCurrentList()
    self:HideAntiquityListFragment()
end

function ZO_AntiquityJournalGamepad:OnSubcategoryTargetChanged(targetData)
    if self.lastSelectedSubcategoryData and self.lastSelectedSubcategoryData.dataSource == targetData.dataSource then
        return
    end

    ANTIQUITY_JOURNAL_LIST_GAMEPAD:OnSubcategoryChanged()
    self:ShowAntiquityListFragment()
    self.lastSelectedSubcategoryData = targetData
end

function ZO_AntiquityJournalGamepad:AddCurrentListKeybinds()
    local currentList = self:GetCurrentList()
    if currentList and currentList.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(currentList.keybindStripDescriptor)
    end
end

function ZO_AntiquityJournalGamepad:RemoveCurrentListKeybinds()
    local currentList = self:GetCurrentList()
    if currentList and currentList.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(currentList.keybindStripDescriptor)
    end
end

function ZO_AntiquityJournalGamepad:ShowCategoryList()
    self:HideAntiquityListFragment()
    self:RefreshHeader()
    self:SetCurrentList(self.categoryList)
    self.categoryList:RefreshVisible()
    SCENE_MANAGER:RemoveFragment(ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT)
end

function ZO_AntiquityJournalGamepad:ShowSubcategoryList(resetSelectionToTop)
    self:RefreshSubcategories(resetSelectionToTop)
    self:ShowAntiquityListFragment(resetSelectionToTop)
    self:SetCurrentList(self.subcategoryList)
    self.subcategoryList:RefreshVisible()
end

function ZO_AntiquityJournalGamepad:ActivateCurrentList(...)
    ZO_Gamepad_ParametricList_Screen.ActivateCurrentList(self, ...)
    self:AddCurrentListKeybinds()
end

function ZO_AntiquityJournalGamepad:DeactivateCurrentList(...)
    self:RemoveCurrentListKeybinds()
    ZO_Gamepad_ParametricList_Screen.DeactivateCurrentList(self, ...)
end

function ZO_AntiquityJournalGamepad:EnableCurrentList(...)
    ZO_Gamepad_ParametricList_Screen.EnableCurrentList(self, ...)
    self:AddCurrentListKeybinds()
end

function ZO_AntiquityJournalGamepad:DisableCurrentList(...)
    self:RemoveCurrentListKeybinds()
    ZO_Gamepad_ParametricList_Screen.DisableCurrentList(self, ...)
end

function ZO_AntiquityJournalGamepad:RefreshKeybinds()
    ZO_Gamepad_ParametricList_Screen.RefreshKeybinds(self)
    local currentList = self:GetCurrentList()
    if currentList and currentList.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(currentList.keybindStripDescriptor)
    end
end

function ZO_AntiquityJournalGamepad:GetAntiquityIconControlPool()
    return self.antiquityIconControlPool
end

function ZO_AntiquityJournalGamepad:RefreshData()
    if self.fragment:IsHidden() then
        self:RefreshCategories()
    else
        local oldCategoryData = self:GetCurrentCategoryData()
        local oldCategoryId = oldCategoryData:GetId()

        self:RefreshCategories()

        if self:IsCurrentList(self.subcategoryList) then
            local newCategoryData = self:GetCurrentCategoryData()
            local newCategoryId = newCategoryData:GetId()

            if newCategoryId == oldCategoryId then
                self:DeactivateAntiquityList()
                self:ShowSubcategoryList()
            else
                self:ShowCategoryList()
            end
        end
    end
end

function ZO_AntiquityJournalGamepad:RefreshHeader(title)
    self.headerData =
    {
        titleText = title or GetString(SI_JOURNAL_MENU_ANTIQUITIES),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_AntiquityJournalGamepad:RefreshCategories(resetSelectionToTop)
    self:RefreshHeader()

    -- Add the category entries.
    self.categoryList:Clear()

    do
        local categoryData = ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA
        local categoryName = categoryData:GetName()
        local gamepadIcon = categoryData:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)

        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
    end

    for categoryIndex, categoryData in ANTIQUITY_DATA_MANAGER:TopLevelAntiquityCategoryIterator() do
        local categoryName = categoryData:GetName()
        local gamepadIcon = categoryData:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)

        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)

        if categoryIndex == 1 then
            entryData:SetHeader(GetString(SI_ANTIQUITY_LOG_BOOK))
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", entryData)
        else
            self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end
    end

    self.categoryList:Commit(resetSelectionToTop)
end

function ZO_AntiquityJournalGamepad:RefreshSubcategories(resetSelectionToTop)
    -- Add the subcategory entries.
    self.subcategoryList:Clear()

    local categoryData = self:GetCurrentCategoryData()
    if categoryData then
        self:RefreshHeader(categoryData:GetName())

        if IsScryableCategory(categoryData) or categoryData:GetNumAntiquities() > 0 then
            local categoryName = categoryData:GetName()
            local entryData = ZO_GamepadEntryData:New(categoryName)

            entryData:SetDataSource(categoryData)
            self.subcategoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end

        for _, subcategoryData in categoryData:SubcategoryIterator() do
            local subcategoryName = ZO_CachedStrFormat(SI_ZONE_NAME, subcategoryData:GetName())
            local entryData = ZO_GamepadEntryData:New(subcategoryName)

            entryData:SetDataSource(subcategoryData)
            self.subcategoryList:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end
    end

    self.subcategoryList:Commit(resetSelectionToTop)
end

function ZO_AntiquityJournalGamepad:ShowAntiquityListFragment(resetSelectionToTop)
    if resetSelectionToTop then
        ANTIQUITY_JOURNAL_LIST_GAMEPAD:ClearSelection()
    end
    if IsScryableCategory(self:GetCurrentSubcategoryData()) and not ZO_IsScryingUnlocked() then
        self.scene:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.scene:RemoveFragment(ZO_ANTIQUITY_JOURNAL_LIST_GAMEPAD_FRAGMENT)
        self.scene:AddFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
        self.scene:AddFragment(ZO_ANTIQUITY_JOURNAL_LOCKED_CONTENT_GAMEPAD_FRAGMENT)
    else
        self.scene:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
        self.scene:RemoveFragment(ZO_ANTIQUITY_JOURNAL_LOCKED_CONTENT_GAMEPAD_FRAGMENT)
        self.scene:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.scene:AddFragment(ZO_ANTIQUITY_JOURNAL_LIST_GAMEPAD_FRAGMENT)
        self:RefreshAntiquityList()
    end
end

function ZO_AntiquityJournalGamepad:HideAntiquityListFragment()
    self.scene:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    self.scene:RemoveFragment(ZO_ANTIQUITY_JOURNAL_LIST_GAMEPAD_FRAGMENT)
    self.scene:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
    self.scene:RemoveFragment(ZO_ANTIQUITY_JOURNAL_LOCKED_CONTENT_GAMEPAD_FRAGMENT)
    ANTIQUITY_JOURNAL_LIST_GAMEPAD:ClearAntiquityTooltip()
end

function ZO_AntiquityJournalGamepad:RefreshAntiquity(data)
    ANTIQUITY_JOURNAL_LIST_GAMEPAD:RefreshAntiquity(data)
end

function ZO_AntiquityJournalGamepad:RefreshAntiquityList()
    ANTIQUITY_JOURNAL_LIST_GAMEPAD:RefreshAntiquities()
end

function ZO_AntiquityJournalGamepad:ActivateAntiquityList()
    ANTIQUITY_JOURNAL_LIST_GAMEPAD:Activate()
end

function ZO_AntiquityJournalGamepad:DeactivateAntiquityList()
    ANTIQUITY_JOURNAL_LIST_GAMEPAD:Deactivate()
end

function ZO_AntiquityJournalGamepad:ShowScryable()
    self.autoShowScryable = true
end

function ZO_AntiquityJournalGamepad:GetCurrentCategoryData()
    return self.categoryList:GetTargetData()
end

function ZO_AntiquityJournalGamepad:GetCurrentSubcategoryData()
    return self.subcategoryList:GetTargetData()
end

-- Opens up the provided category, or the current category if no antiquityCategoryData is provided.
function ZO_AntiquityJournalGamepad:ViewCategory(antiquityCategoryData, focusAntiquityList)
    local parentCategoryData = nil
    local subcategoryData = nil
    if antiquityCategoryData then
        parentCategoryData = antiquityCategoryData:GetParentCategoryData()
        if parentCategoryData then
            subcategoryData = antiquityCategoryData
        else
            parentCategoryData = antiquityCategoryData
        end
    end

    if parentCategoryData then
        local ANY_TEMPLATE = nil
        local index = self.categoryList:GetIndexForData(ANY_TEMPLATE, parentCategoryData)
        if index then
            self.categoryList:SetSelectedIndexWithoutAnimation(index)
        else
            return internalassert(false, "Trying to view an invalid parentCategoryData")
        end
    end

    local RESET_SELECTION_TO_TOP = true
    self:ShowSubcategoryList(RESET_SELECTION_TO_TOP)

    if subcategoryData then
        local index = self.subcategoryList:GetIndexForData("ZO_GamepadItemEntryTemplate", subcategoryData)
        if index then
            self.subcategoryList:SetSelectedIndexWithoutAnimation(index)
        else
            return internalassert(false, "Trying to view an invalid subcategoryData")
        end
    end

    if focusAntiquityList then
        self:DeactivateCurrentList()
        self:DeactivateAntiquityList() -- Just in case the list is already active, make sure it's deactivated first so it properly runs activation logic
        self:ActivateAntiquityList()
    end
end

-- Antiquities List

ZO_AntiquityJournalListGamepad = ZO_SortFilterList_Gamepad:Subclass()

function ZO_AntiquityJournalListGamepad:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function ZO_AntiquityJournalListGamepad:Initialize(control)
    self:InitializeControl(control)
    self:InitializeControlPools()
    self:InitializeAntiquitySections()
    self:InitializeLists()
    self:InitializeOptionsDialog()
end

function ZO_AntiquityJournalListGamepad:InitializeControl(control)
    self.control = control
    ZO_SortFilterList_Gamepad.Initialize(self, self.control)
    ZO_SortFilterList_Gamepad.InitializeSortFilterList(self, self.control)

    self.titleLabel = self.control:GetNamedChild("Label")
    self.emptyLabel = self.control:GetNamedChild("EmptyLabel")

    local function OnStateChanged(...)
        self:OnStateChanged(...)
    end

    self.fragment = ZO_SimpleSceneFragment:New(self.control)
    ZO_ANTIQUITY_JOURNAL_LIST_GAMEPAD_FRAGMENT = self.fragment
    self.fragment:RegisterCallback("StateChange", OnStateChanged)
end

function ZO_AntiquityJournalListGamepad:InitializeControlPools()
    local function ResetIconControl(control)
        control:SetHidden(true)
        control:SetParent(nil)
        control:ClearAnchors()
        control.antiquityData = nil
    end

    self.progressIconControlPool = ZO_ControlPool:New("ZO_AntiquityJournalAntiquityProgressIconTexture_Gamepad", self.control, "AntiquityProgressIconGamepad")
    self.progressIconControlPool:SetCustomResetBehavior(ResetIconControl)
end

function ZO_AntiquityJournalListGamepad:InitializeLists()
    local listControl = self:GetListControl()

    local function SetupInProgressAntiquityRow(control, data)
        self:SetupInProgressAntiquityRow(control, data)
    end
    ZO_ScrollList_AddDataType(listControl, IN_PROGRESS_ANTIQUITY_ROW_DATA, "ZO_AntiquityJournalInProgressAntiquityRow_Gamepad", ZO_IN_PROGRESS_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD, SetupInProgressAntiquityRow)
    local function SetupInProgressAntiquityNearExpirationRow(control, data)
        self:SetupInProgressAntiquityNearExpirationRow(control, data)
    end
    ZO_ScrollList_AddDataType(listControl, IN_PROGRESS_ANTIQUITY_NEAR_EXPIRATION_ROW_DATA, "ZO_AntiquityJournalInProgressAntiquityNearExpirationRow_Gamepad", ZO_IN_PROGRESS_ANTIQUITY_NEAR_EXPIRATION_DATA_ROW_HEIGHT_GAMEPAD, SetupInProgressAntiquityNearExpirationRow)

    local function SetupScryableAntiquityRow(control, data)
        self:SetupScryableAntiquityRow(control, data)
    end
    ZO_ScrollList_AddDataType(listControl, SCRYABLE_ANTIQUITY_ROW_DATA, "ZO_AntiquityJournalScryableAntiquityRow_Gamepad", ZO_SCRYABLE_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD, SetupScryableAntiquityRow)
    local function SetupScryableAntiquityNearExpirationRow(control, data)
        self:SetupScryableAntiquityNearExpirationRow(control, data)
    end
    ZO_ScrollList_AddDataType(listControl, SCRYABLE_ANTIQUITY_NEAR_EXPIRATION_ROW_DATA, "ZO_AntiquityJournalScryableAntiquityNearExpirationRow_Gamepad", ZO_SCRYABLE_ANTIQUITY_NEAR_EXPIRATION_DATA_ROW_HEIGHT_GAMEPAD, SetupScryableAntiquityNearExpirationRow)

    local function SetupAntiquityRow(control, data)
        self:SetupAntiquityRow(control, data)
    end
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_ROW_DATA, "ZO_AntiquityJournalAntiquityRow_Gamepad", ZO_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD, SetupAntiquityRow)

    local function SetupAntiquitySetRow(control, data)
        self:SetupAntiquitySetRow(control, data)
    end
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_1_ROW_DATA, "ZO_AntiquityJournalAntiquitySet1Row_Gamepad", ZO_ANTIQUITY_SET_1_DATA_ROW_HEIGHT_GAMEPAD, SetupAntiquitySetRow)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_2_ROW_DATA, "ZO_AntiquityJournalAntiquitySet2Row_Gamepad", ZO_ANTIQUITY_SET_2_DATA_ROW_HEIGHT_GAMEPAD, SetupAntiquitySetRow)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_3_ROW_DATA, "ZO_AntiquityJournalAntiquitySet3Row_Gamepad", ZO_ANTIQUITY_SET_3_DATA_ROW_HEIGHT_GAMEPAD, SetupAntiquitySetRow)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_4_ROW_DATA, "ZO_AntiquityJournalAntiquitySet4Row_Gamepad", ZO_ANTIQUITY_SET_4_DATA_ROW_HEIGHT_GAMEPAD, SetupAntiquitySetRow)

    local function SetupAntiquitySectionRow(control, data)
        self:SetupAntiquitySectionRow(control, data)
    end
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SECTION_ROW_DATA, "ZO_AntiquityJournalAntiquitySectionRow_Gamepad", ZO_ANTIQUITY_SECTION_DATA_ROW_HEIGHT_GAMEPAD, SetupAntiquitySectionRow)
    ZO_ScrollList_SetTypeSelectable(listControl, ANTIQUITY_SECTION_ROW_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(listControl, ANTIQUITY_SECTION_ROW_DATA, true)

    local function ShowSubcategories()
        self:ClearActiveFragmentList()
        self:Deactivate()
        ANTIQUITY_JOURNAL_GAMEPAD:ActivateCurrentList()
    end

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            order = 10,
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                local categoryData = self:GetCurrentSubcategoryData()
                if IsScryableCategory(categoryData) then
                    return GetString(SI_ANTIQUITY_SCRY)
                else
                    return GetString(SI_ANTIQUITY_LOG_BOOK)
                end
            end,
            callback = function()
                local antiquityData = self:GetCurrentAntiquityData()
                if antiquityData then
                    local categoryData = self:GetCurrentSubcategoryData()
                    if IsScryableCategory(categoryData) then
                        ScryForAntiquity(antiquityData:GetId())
                    else
                        ANTIQUITY_LORE_GAMEPAD:ShowAntiquityOrSet(antiquityData, true)
                    end
                end
            end,
            enabled = function()
                if self:GetCurrentAntiquityData() then
                    local categoryData = self:GetCurrentSubcategoryData()
                    if IsScryableCategory(categoryData) then
                        local antiquityData = self:GetCurrentAntiquityData()
                        if antiquityData then
                            local canScry, scryResultMessage = antiquityData:CanScry()
                            return canScry, scryResultMessage
                        end
                    end
                    return true
                end
            end,
            visible = function()
                local antiquityData = self:GetCurrentAntiquityData()
                if antiquityData and antiquityData:HasDiscovered() then
                    local categoryData = self:GetCurrentSubcategoryData()
                    if not IsScryableCategory(categoryData) then
                        return antiquityData:GetNumLoreEntries() > 0
                    end
                    return true
                end
            end
        },
        {
            order = 20,
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_ANTIQUITY_FRAGMENTS),
            callback = function(dialog)
                self:ToggleAntiquityFragmentFocus()
            end,
            visible = function()
                local categoryData = self:GetCurrentSubcategoryData()
                local antiquityData = self:GetCurrentAntiquityData()
                if antiquityData and antiquityData:HasDiscovered() then
                    return not IsScryableCategory(categoryData) and antiquityData:GetType() == ZO_ANTIQUITY_TYPE_SET
                end
                return false
            end,
        },
        {
            order = 30,
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_GAMEPAD_QUEST_JOURNAL_SCRYABLE_OPTIONS),
            callback = function()
               ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SCRYABLE_ANTIQUITY_OPTIONS", self:CreateOptionsDialogActions())
            end,
            visible = function()
                local categoryData = self:GetCurrentSubcategoryData()
                return IsScryableCategory(categoryData)
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Antiquity Journal Top of List",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollUp(self.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.list, ZO_SCROLL_SELECT_CATEGORY_PREVIOUS)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS])
                end
            end
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Antiquity Journal Bottom of List",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollDown(self.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.list, ZO_SCROLL_SELECT_CATEGORY_NEXT)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT])
                end
            end
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ShowSubcategories)

    self.fragmentListKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                self:ToggleAntiquityFragmentFocus()
            end,
        },
    }
end

function ZO_AntiquityJournalListGamepad:CreateOptionActionDataAbandonFragments()
    return
    {
        template = "ZO_GamepadItemEntryTemplate",
        text = GetString(SI_ANTIQUITY_ABANDON),
        callback = function(dialog)
            local categoryData = self:GetCurrentSubcategoryData()
            if IsScryableCategory(categoryData) then
                local antiquityData = self:GetCurrentAntiquityData()
                if antiquityData then
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_SCRYABLE_ANTIQUITY_OPTIONS")
                    ZO_Dialogs_ShowGamepadDialog("CONFIRM_ABANDON_ANTIQUITY_SCRYING_PROGRESS", { antiquityId = antiquityData:GetId() })
                end
            end
        end,
        visible = function()
            local antiquityData = self:GetCurrentAntiquityData()
            if antiquityData and antiquityData:HasDiscovered() then
                local categoryData = self:GetCurrentSubcategoryData()
                if IsScryableCategory(categoryData) then
                    return antiquityData:HasDiscoveredDigSites()
                end
            end
            return false
        end,
    }
end

function ZO_AntiquityJournalListGamepad:CreateOptionActionDataShowOnMap()
    return
    {
        template = "ZO_GamepadItemEntryTemplate",
        text = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
        callback = function(dialog)
                local antiquityData = self:GetCurrentAntiquityData()
                if antiquityData then
                    local antiquityId = antiquityData:GetId()
                    SetTrackedAntiquityId(antiquityId)
                    WORLD_MAP_MANAGER:ShowAntiquityOnMap(antiquityId)
                end
        end,
        visible = function()
            local categoryData = self:GetCurrentSubcategoryData()
            if IsScryableCategory(categoryData) then
                local antiquityData = self:GetCurrentAntiquityData()
                if antiquityData then
                    return antiquityData:HasDiscoveredDigSites()
                end
            end
            return false
        end,
    }
end

function ZO_AntiquityJournalListGamepad:CreateOptionActionDataViewInCodex()
    return
    {
        template = "ZO_GamepadItemEntryTemplate",
        text = GetString(SI_ANTIQUITY_VIEW_IN_CODEX),
        callback = function(dialog)
            ZO_Dialogs_ReleaseDialog("GAMEPAD_SCRYABLE_ANTIQUITY_OPTIONS")
            local scryableAntiquityData = self:GetCurrentAntiquityData()
            local antiquityCategoryData = scryableAntiquityData:GetAntiquityCategoryData()
            local FOCUS_ANTIQUITY_LIST = true
            ANTIQUITY_JOURNAL_GAMEPAD:ViewCategory(antiquityCategoryData, FOCUS_ANTIQUITY_LIST)
        end,
        visible = function()
            local categoryData = self:GetCurrentSubcategoryData()
            return IsScryableCategory(categoryData)
        end,
    }
end

function ZO_AntiquityJournalListGamepad:CreateOptionsDialogActions()
    local actionsTable = {}

    table.insert(actionsTable, self:CreateOptionActionDataAbandonFragments())
    table.insert(actionsTable, self:CreateOptionActionDataShowOnMap())
    table.insert(actionsTable, self:CreateOptionActionDataViewInCodex())

    return actionsTable
end

function ZO_AntiquityJournalListGamepad:InitializeOptionsDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SCRYABLE_ANTIQUITY_OPTIONS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_SCRYABLE_ANTIQUITY_OPTIONS_HEADER
        },
        setup = function(dialog, allActions)
            local parametricList = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricList)

            for i, action in ipairs(allActions) do
                local entryData = ZO_GamepadEntryData:New(action.text)
                entryData.action = action
                entryData.setup = action.setup or ZO_SharedGamepadEntry_OnSetup
                entryData.callback = action.callback

                local listItem =
                {
                    template = action.template or "ZO_GamepadItemEntryTemplate",
                    entryData = entryData,
                    header = action.header,
                }

                table.insert(parametricList, listItem)
            end

            dialog:setupFunc()
        end,
        parametricList = {}, -- Generated Dynamically
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_SCRYABLE_ANTIQUITY_OPTIONS")
                end,
            },
        },
        noChoiceCallback = function(dialog)
            local parametricList = dialog.info.parametricList
            for i, entry in ipairs(parametricList) do
                if entry.entryData.action.isDropdown then
                    local control = dialog.entryList:GetControlFromData(entry.entryData)
                    if control then
                        control.dropdown:Deactivate()
                    end
                end
            end
        end
    })
end

function ZO_AntiquityJournalListGamepad:GetActiveFragmentList()
    return self.activeFragmentList
end

function ZO_AntiquityJournalListGamepad:SetActiveFragmentList(list)
    self:Deactivate()
    self.activeFragmentList = list
    self.activeFragmentList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.fragmentListKeybindStripDescriptor)
end

function ZO_AntiquityJournalListGamepad:ClearActiveFragmentList()
    if self.activeFragmentList then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.fragmentListKeybindStripDescriptor)
        self.activeFragmentList:Deactivate()
        self.activeFragmentList = nil
    end
end

function ZO_AntiquityJournalListGamepad:ToggleAntiquityFragmentFocus()
    local activeFragmentList = self:GetActiveFragmentList()
    if activeFragmentList then
        self:Activate()
    else
        local control = ZO_ScrollList_GetSelectedControl(self.list)
        if control and control.antiquitiesScrollList then
            self:SetActiveFragmentList(control.antiquitiesScrollList)
        end
    end
end

function ZO_AntiquityJournalListGamepad:UpdateKeybinds()
    if self.isActive then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    elseif self:GetActiveFragmentList() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self:GetActiveFragmentList().keybindStripDescriptor)
    end
end

function ZO_AntiquityJournalListGamepad:Activate(...)
    self:ClearActiveFragmentList()
    ZO_SortFilterList_Gamepad.Activate(self, ...)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AntiquityJournalListGamepad:Deactivate(...)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_SortFilterList_Gamepad.Deactivate(self, ...)
    self:ClearActiveFragmentList()
end

function ZO_AntiquityJournalListGamepad:OnStateChanged(state)
    if state == SCENE_FRAGMENT_HIDING then
        self:OnHiding()
    end
end

function ZO_AntiquityJournalListGamepad:OnHiding()
    self:ClearAntiquityTooltip()
    self:Deactivate()
end

function ZO_AntiquityJournalListGamepad:ClearSelection()
    self.lastSelectedData = nil
    ZO_ScrollList_ResetToTop(self.list)
end

function ZO_AntiquityJournalListGamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList.OnSelectionChanged(self, oldData, newData)

    self:UpdateKeybinds()
    if newData then
        self.lastSelectedData = newData

        if not newData:HasDiscovered() then
            self:ClearAntiquityTooltip()
            return
        end

        if newData:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
            if newData:HasNewLead() then
                newData:ClearNewLead()
            end

            if newData:GetAntiquitySetData() then
                GAMEPAD_TOOLTIPS:LayoutAntiquitySetFragment(GAMEPAD_RIGHT_TOOLTIP, newData:GetId())
            else
                if newData:HasReward() and newData:HasDiscovered() then
                    GAMEPAD_TOOLTIPS:LayoutAntiquityReward(GAMEPAD_RIGHT_TOOLTIP, newData:GetId())
                end
            end
        elseif newData:HasReward() and newData:HasDiscovered() then
            GAMEPAD_TOOLTIPS:LayoutAntiquitySetReward(GAMEPAD_RIGHT_TOOLTIP, newData:GetId())
        end
    else
        self:ClearAntiquityTooltip()
    end
end

function ZO_AntiquityJournalListGamepad:GetCurrentAntiquityData()
    return ZO_ScrollList_GetSelectedData(self.list)
end

do
    local function AddAntiquitySectionList(scrollDataList, headingText, antiquitySection, lastSelectedAntiquityData)
        if #antiquitySection.list > 0 then
            table.sort(antiquitySection.list, antiquitySection.sortFunction)
            table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(ANTIQUITY_SECTION_ROW_DATA, {label = headingText}))
            local rowTemplate = antiquitySection.rowTemplate
            local reselectData

            for _, antiquityData in ipairs(antiquitySection.list) do
                if lastSelectedAntiquityData and antiquityData:GetId() == lastSelectedAntiquityData:GetId() then
                    reselectData = antiquityData
                end

                local antiquityRowTemplate = rowTemplate
                local isLeadNearExpiration = antiquityData:GetLeadExpirationStatus()
                if isLeadNearExpiration then
                    antiquityRowTemplate = GetMappedAntiquityNearExpirationTemplateId(antiquityRowTemplate)
                end

                -- Add this scryable antiquity as a tile.
                if antiquityRowTemplate then
                    table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(antiquityRowTemplate, antiquityData))
                else
                    internalassert(false, string.format("Row template '%s' has no 'Near Expiration' template mapped.", tostring(rowTemplate) or "nil"))
                end
            end

            return reselectData
        end
    end

    function ZO_AntiquityJournalListGamepad:InitializeAntiquitySections()
        -- Note that the order of these sections matters: lower-indexed sections are prioritized above subsequent sections.
        self.scryableAntiquitySections =
        {
            {
                sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_IN_PROGRESS),
                filterFunctions = {ZO_Antiquity.IsInProgress},
                sortFunction = ZO_DefaultAntiquitySortComparison,
                rowTemplate = IN_PROGRESS_ANTIQUITY_ROW_DATA,
                list = {}
            },
            {
                sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_AVAILABLE),
                filterFunctions = {ZO_Antiquity.IsScryable},
                sortFunction = ZO_DefaultAntiquitySortComparison,
                rowTemplate = SCRYABLE_ANTIQUITY_ROW_DATA,
                list = {}
            },
            {
                sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_REQUIRES_LEAD),
                filterFunctions = {function(antiquityData) return antiquityData:HasDiscovered() and antiquityData:IsInCurrentPlayerZone() and not antiquityData:MeetsLeadRequirements() and (antiquityData:IsRepeatable() or not antiquityData:HasRecovered()) end},
                sortFunction = ZO_DefaultAntiquitySortComparison,
                rowTemplate = SCRYABLE_ANTIQUITY_ROW_DATA,
                list = {}
            },
        }

        for antiquityDifficulty = 1, ANTIQUITY_DIFFICULTY_MAX_VALUE do
            local skillName, requiredRank, maximumRank = ZO_GetAntiquityScryingPassiveSkillInfo(antiquityDifficulty)
            local antiquitySection =
            {
                sectionHeading = zo_strformat(SI_ANTIQUITY_SUBHEADING_REQUIRES_SKILL, skillName, requiredRank, maximumRank),
                filterFunctions =
                {
                    function(antiquityData)
                        local isMatch = antiquityData:IsInCurrentPlayerZone() and antiquityData:HasDiscovered() and not antiquityData:MeetsScryingSkillRequirements()
                        return isMatch and antiquityData:GetDifficulty() == antiquityDifficulty
                    end,
                },
                sortFunction = ZO_DefaultAntiquitySortComparison,
                rowTemplate = SCRYABLE_ANTIQUITY_ROW_DATA,
                list = {}
            }
            table.insert(self.scryableAntiquitySections, antiquitySection)
        end
    end

    function ZO_AntiquityJournalListGamepad:RefreshAntiquities()
        local currentSubcategoryData = self:GetCurrentSubcategoryData()
        local listControl = self:GetListControl()
        local lastAntiquityData = self.lastSelectedData
        local reselectAntiquityData = nil
        ZO_ScrollList_Clear(listControl)
        local scrollDataList = ZO_ScrollList_GetDataList(listControl)

        if not currentSubcategoryData then
            self.titleLabel:SetText("")
            SCENE_MANAGER:RemoveFragment(ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT)
        else
            -- Refresh the header.
            self.titleLabel:SetText(ZO_CachedStrFormat(SI_ZONE_NAME, currentSubcategoryData:GetName()))

            if IsScryableCategory(currentSubcategoryData) then
                for _, antiquitySection in ipairs(self.scryableAntiquitySections) do
                    ZO_ClearNumericallyIndexedTable(antiquitySection.list)
                end

                -- Iterate over all antiquities, adding each antiquity to the section whose criteria it meets (if any).
                for _, antiquityData in ANTIQUITY_DATA_MANAGER:AntiquityIterator({ ZO_Antiquity.IsVisible }) do
                    for _, antiquitySection in ipairs(self.scryableAntiquitySections) do
                        local passesFilter = true
                        for _, filterFunction in ipairs(antiquitySection.filterFunctions) do
                            if not filterFunction(antiquityData) then
                                passesFilter = false
                                break
                            end
                        end

                        if passesFilter then
                            table.insert(antiquitySection.list, antiquityData)
                            break
                        end
                    end
                end

                -- Sort each sections' list by the associated sort function.
                for _, antiquitySection in ipairs(self.scryableAntiquitySections) do
                    -- Only add headings for lists that have at least one antiquity.
                    if #antiquitySection.list ~= 0 then
                        local reselectData = AddAntiquitySectionList(scrollDataList, antiquitySection.sectionHeading, antiquitySection, lastAntiquityData)
                        if not reselectAntiquityData and reselectData then
                            reselectAntiquityData = reselectData
                        end
                    end
                end
            else
                -- Add the antiquity/antiquity set entries.
                local maxLoreEntries = 0
                local unlockedLoreEntries = 0
                local antiquitySets = {}

                for _, antiquityData in currentSubcategoryData:AntiquityIterator({ ZO_Antiquity.IsVisible }) do
                    local antiquitySetData = antiquityData:GetAntiquitySetData()
                    local entryTemplate = ANTIQUITY_ROW_DATA
                    local filterFunction = ANTIQUITY_DATA_MANAGER:GetAntiquityFilterFunction(ANTIQUITY_JOURNAL_GAMEPAD:GetCurrentFilterSelection())
                    local entryData

                    if not filterFunction or filterFunction(antiquityData, antiquitySetData) then
                        if antiquitySetData then
                            if not antiquitySets[antiquitySetData] then
                                entryData = antiquitySetData

                                if antiquitySetData:HasDiscovered() then
                                    antiquitySets[antiquitySetData] = true

                                    local numAntiquities = antiquitySetData:GetNumAntiquities()
                                    local rowTemplateIndex = math.ceil(numAntiquities / MAX_ANTIQUITIES_PER_ROW)
                                    local rowTemplate = ANTIQUITY_SET_ROW_DATA_TEMPLATES[rowTemplateIndex]
                                    if not rowTemplate then
                                        internalassert(false, string.format("Antiquity set '%s' has exceeded the maximum number of supported antiquity fragments.", antiquitySetData:GetName()))
                                    end

                                    entryTemplate = rowTemplate
                                end

                                for _, antiquitySetAntiquityData in antiquitySetData:AntiquityIterator({ ZO_Antiquity.IsVisible }) do
                                    maxLoreEntries = maxLoreEntries + antiquitySetAntiquityData:GetNumLoreEntries()
                                    unlockedLoreEntries = unlockedLoreEntries + antiquitySetAntiquityData:GetNumUnlockedLoreEntries()
                                end
                            end
                        else
                            entryData = antiquityData
                            maxLoreEntries = maxLoreEntries + antiquityData:GetNumLoreEntries()
                            unlockedLoreEntries = unlockedLoreEntries + antiquityData:GetNumUnlockedLoreEntries()
                        end

                        if entryData then
                            if not reselectAntiquityData and lastAntiquityData and entryData:GetId() == lastAntiquityData:GetId() then
                                reselectAntiquityData = entryData
                            end
                            table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(entryTemplate, entryData))
                        end
                    end
                end

                ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT.footerBarName:SetText(zo_strformat(SI_GAMEPAD_ANTIQUITY_JOURNAL_PROGRESS_SUBCATEGORY, currentSubcategoryData:GetName()))
                if maxLoreEntries > 0 then
                    ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT.footerBarBar:SetValue(unlockedLoreEntries / maxLoreEntries)
                else
                    ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT.footerBarBar:SetValue(0)
                end
                SCENE_MANAGER:AddFragment(ZO_ANTIQUITY_JOURNAL_FOOTER_GAMEPAD_FRAGMENT)
            end
        end

        self:CommitScrollList()
        if reselectAntiquityData then
            ZO_ScrollList_SelectDataAndScrollIntoView(self.list, reselectAntiquityData)
        end
        local hasData = ZO_ScrollList_HasVisibleData(listControl)
        listControl:SetHidden(not hasData)
        self.emptyLabel:SetHidden(hasData)
    end
end

function ZO_AntiquityJournalListGamepad:RefreshAntiquity()
    local lastSelectedFragmentData
    local lastSelectedData = self.lastSelectedData
    local activeFragmentList = self:GetActiveFragmentList()
    if activeFragmentList and activeFragmentList:IsActive() then
        lastSelectedFragmentData = ZO_ScrollList_GetSelectedData(activeFragmentList.list)
    end

    self:RefreshVisible()
    if lastSelectedData then
        ZO_ScrollList_SelectData(self.list, lastSelectedData)
        if activeFragmentList and lastSelectedFragmentData then
            ZO_ScrollList_SelectData(activeFragmentList.list, lastSelectedFragmentData)
        end
    end
end

function ZO_AntiquityJournalListGamepad:SetupAntiquitySectionRow(control, data)
    control.label:SetText(data.label)
end

function ZO_AntiquityJournalListGamepad:SetupBaseRow(control, data)
    local colorizeLabels = self.colorizeLabels
    local hasDiscovered = data:HasDiscovered()
    local hasRecovered = data:HasRecovered()
    local labelColor = (not colorizeLabels or hasRecovered) and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT

    control.status:ClearIcons()
    if data:HasNewLead() then
        control.status:AddIcon(ZO_GAMEPAD_NEW_ICON_32)
    end
    control.status:Show()

    control.titleLabel:ClearAnchors()
    if hasDiscovered then
        control.titleLabel:SetText(data:GetColorizedFormattedName())
        control.titleLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
        control.titleLabel:SetAnchor(TOPLEFT)
    else
        control.titleLabel:SetText(GetString(SI_ANTIQUITY_NAME_HIDDEN))
        local titleColor = colorizeLabels and ZO_DISABLED_TEXT or ZO_NORMAL_TEXT
        control.titleLabel:SetColor(titleColor:UnpackRGB())
        control.titleLabel:SetAnchor(LEFT)
    end

    local hasReward = data:HasReward()
    control.numRecoveredLabel:ClearAnchors()
    if hasDiscovered and hasReward then
        local rewardContextualTypeString = REWARDS_MANAGER:GetRewardContextualTypeString(data:GetRewardId()) or GetString(SI_ANTIQUITY_TYPE_FALLBACK)
        if not colorizeLabels or hasRecovered then
            rewardContextualTypeString = ZO_SELECTED_TEXT:Colorize(rewardContextualTypeString)
        end
        control.antiquityTypeLabel:SetText(zo_strformat(SI_ANTIQUITY_TYPE, rewardContextualTypeString))
        control.antiquityTypeLabel:SetColor(labelColor:UnpackRGB())
        control.antiquityTypeLabel:SetHidden(false)
        control.numRecoveredLabel:SetAnchor(LEFT, control.antiquityTypeLabel, RIGHT, 15)
    else
        control.antiquityTypeLabel:SetHidden(true)
        control.numRecoveredLabel:SetAnchor(TOPLEFT, control.titleLabel, BOTTOMLEFT, 0, -7)
    end

    if hasDiscovered and data:IsRepeatable() then
        local numRecovered = data:GetNumRecovered()
        if not colorizeLabels or hasRecovered then
            numRecovered = ZO_SELECTED_TEXT:Colorize(numRecovered)
        end
        control.numRecoveredLabel:ClearAnchors()
        if hasReward then
            control.numRecoveredLabel:SetAnchor(LEFT, control.antiquityTypeLabel, RIGHT, 15)
        else
            control.numRecoveredLabel:SetAnchor(TOPLEFT, control.titleLabel, BOTTOMLEFT, 0, -7)
        end
        control.numRecoveredLabel:SetText(zo_strformat(SI_ANTIQUITY_TIMES_ACQUIRED, numRecovered))
        control.numRecoveredLabel:SetColor(labelColor:UnpackRGB())
        control.numRecoveredLabel:SetHidden(false)
    else
        control.numRecoveredLabel:SetHidden(true)
    end

    local iconTextureFile = hasDiscovered and data:GetIcon() or ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE
    local iconTexture = control.iconTexture
    if hasDiscovered and not hasRecovered then
        iconTexture:SetDesaturation(1)
        iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 0.7)
        iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0.3)
    else
        local desaturation = data:IsComplete() and 0 or 1
        iconTexture:SetDesaturation(desaturation)
        iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1)
        iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0)
    end
    iconTexture:SetTexture(iconTextureFile)
end

function ZO_AntiquityJournalListGamepad:SetupBaseLogbookRow(control, data)
    self.colorizeLabels = true
    self:SetupBaseRow(control, data)

    local numLoreEntries = data:GetNumLoreEntries()
    if numLoreEntries > 0 and data:HasDiscovered() then
        control.progressLabel:SetText(string.format("%d / %d", data:GetNumUnlockedLoreEntries(), numLoreEntries))
        control.progressContainer:SetHidden(false)
    else
        control.progressContainer:SetHidden(true)
    end
end

function ZO_AntiquityJournalListGamepad:SetupAntiquityRow(control, data)
    self:SetupBaseLogbookRow(control, data)
end

function ZO_AntiquityJournalListGamepad:OnAntiquitySetFragmentSelectionChanged(oldData, newData)
    if newData then
        if newData:HasNewLead() then
            -- Immediately clear the fragment's new status icon.
            local activeFragmentList = self:GetActiveFragmentList()
            if activeFragmentList then
                local selectedControl = ZO_ScrollList_GetSelectedControl(activeFragmentList.list)
                if selectedControl then
                    selectedControl.status:ClearIcons()
                    selectedControl.status:Show()
                end
            end

            newData:ClearNewLead()
        end

        GAMEPAD_TOOLTIPS:LayoutAntiquitySetFragment(GAMEPAD_RIGHT_TOOLTIP, newData:GetId())
    else
        self:ClearAntiquityTooltip()
    end
end

function ZO_AntiquityJournalListGamepad:OnSubcategoryChanged()
    self.lastSelectedData = nil
    ZO_ScrollList_ResetAutoSelectIndex(self.list)
    ZO_ScrollList_ResetToTop(self.list)
end

function ZO_AntiquityJournalListGamepad:SetupAntiquitySetFragmentIcon(control, antiquityData)
    control.antiquityData = antiquityData
    local textureIcon = antiquityData:HasDiscovered() and antiquityData:GetIcon() or ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE
    local showSilhouette = textureIcon ~= ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE and not antiquityData:HasRecovered()

    control:SetTexture(textureIcon)
    if showSilhouette then
        control:SetDesaturation(1)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 0.7)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0.3)
    else
        local desaturation = antiquityData:IsComplete() and 0 or 1
        control:SetDesaturation(desaturation)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0)
    end
    control:SetHidden(false)

    if not control.status then
        control.status = control:GetNamedChild("Status")
    end
    control.status:ClearIcons()
    if antiquityData:HasNewLead() then
        control.status:AddIcon(ZO_GAMEPAD_NEW_ICON_32)
    end
    control.status:Show()
end


function ZO_AntiquityJournalListGamepad:SetupAntiquitySetRow(control, data)
    self:SetupBaseLogbookRow(control, data)

    local TEMPLATE_DIMENSIONS = 50
    local NUM_COLUMNS = 10
    local selectedAntiquity
    local hasRecovered = data:HasRecovered()

    if hasRecovered then
        control.antiquitiesRecoveredLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        control.antiquitiesRecoveredLabel:SetText(zo_strformat(SI_ANTIQUITY_PIECES_FOUND, data:GetNumAntiquitiesRecovered(), data:GetNumAntiquities()))
    else
        control.antiquitiesRecoveredLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        control.antiquitiesRecoveredLabel:SetText(zo_strformat(SI_ANTIQUITY_PIECES_FOUND, ZO_DISABLED_TEXT:Colorize(data:GetNumAntiquitiesRecovered()), ZO_DISABLED_TEXT:Colorize(data:GetNumAntiquities())))
    end

    if control.antiquitiesScrollList then
        selectedAntiquity = ZO_ScrollList_GetSelectedData(control.antiquitiesScrollList)
        control.antiquitiesScrollList:ClearGridList()
    else
        control.antiquitiesScrollList = ZO_GridScrollList_Gamepad:New(control.antiquitiesListControl)
        local NO_HIDE_CALLBACK = nil
        local DO_NOT_CENTER_ENTRIES = false
        local function OnSetupAntiquitySetFragment(...)
            self:SetupAntiquitySetFragmentIcon(...)
        end
        control.antiquitiesScrollList:AddEntryTemplate("ZO_AntiquityJournalAntiquityFragmentIconTexture_Gamepad", TEMPLATE_DIMENSIONS, TEMPLATE_DIMENSIONS, OnSetupAntiquitySetFragment, NO_HIDE_CALLBACK, ZO_ObjectPool_DefaultResetControl, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD, DO_NOT_CENTER_ENTRIES)
        control.antiquitiesScrollList:RegisterCallback("SelectedDataChanged", function(...) self:OnAntiquitySetFragmentSelectionChanged(...) end )
    end

    for _, antiquityData in data:AntiquityIterator() do
        control.antiquitiesScrollList:AddEntry(antiquityData, "ZO_AntiquityJournalAntiquityFragmentIconTexture_Gamepad")
    end

    local numAntiquities = data:GetNumAntiquities()
    local numRows = math.ceil(numAntiquities / NUM_COLUMNS)
    local gridHeight = TEMPLATE_DIMENSIONS * numRows + ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD * (numRows - 1)

    control.antiquitiesListControl:SetHeight(gridHeight)
    control.antiquitiesScrollList:CommitGridList()
    ZO_ScrollList_SetHeight(control.antiquitiesScrollList.list, gridHeight)

    if selectedAntiquity then
        ZO_ScrollList_SelectData(control.antiquitiesScrollList, selectedAntiquity)
    end
end

function ZO_AntiquityJournalListGamepad:SetupScryableAntiquityRow(control, data)
    self.colorizeLabels = false
    self:SetupBaseRow(control, data)

    if data:HasDiscovered() then
        local difficulty = data:GetDifficulty()
        control.difficultyLabel:SetText(zo_strformat(SI_ANTIQUITY_DIFFICULTY_FORMATTER, ZO_SELECTED_TEXT:Colorize(GetString("SI_ANTIQUITYDIFFICULTY", difficulty))))
        control.difficultyLabel:ClearAnchors()
        if control.numRecoveredLabel:IsControlHidden() then
            if control.antiquityTypeLabel:IsControlHidden() then
                control.difficultyLabel:SetAnchor(TOPLEFT, control.titleLabel, BOTTOMLEFT, 0, -7)
            else
                control.difficultyLabel:SetAnchor(LEFT, control.antiquityTypeLabel, RIGHT, 15)
            end
        else
            control.difficultyLabel:SetAnchor(LEFT, control.numRecoveredLabel, RIGHT, 15)
        end
        control.difficultyLabel:SetHidden(false)

        local zoneName = GetZoneNameById(data:GetZoneId())
        control.zoneLabel:SetText(zo_strformat(SI_ANTIQUITY_ZONE, ZO_SELECTED_TEXT:Colorize(zoneName)))
        control.zoneLabel:SetHidden(false)
    else
        control.difficultyLabel:SetHidden(true)
        control.zoneLabel:SetHidden(true)
    end
end

function ZO_AntiquityJournalListGamepad:SetupScryableAntiquityNearExpirationRow(control, data)
    self:SetupScryableAntiquityRow(control, data)

    local isLeadNearingExpiration, leadTimeRemaining = data:GetLeadExpirationStatus()
    if isLeadNearingExpiration then
        control.leadExpirationLabel:SetText(zo_strformat(SI_ANTIQUITY_TOOLTIP_LEAD_EXPIRATION, ZO_SELECTED_TEXT:Colorize(leadTimeRemaining)))
    end
    control.leadExpirationLabel:SetHidden(not isLeadNearingExpiration)
end

function ZO_AntiquityJournalListGamepad:SetupInProgressAntiquityRow(control, data)
    self.colorizeLabels = false
    self:SetupScryableAntiquityRow(control, data)

    if control.progressIconMetaPool then
        control.progressIconMetaPool:ReleaseAllObjects()
    else
        control.progressIconMetaPool = ZO_MetaPool:New(self.progressIconControlPool)
    end

    local numGoalsAchieved = data:GetNumGoalsAchieved()
    if numGoalsAchieved > 0 then
        local previousIcon
        local totalNumGoals = data:GetTotalNumGoals()

        for progressIndex = 1, totalNumGoals do
            local progressIcon = control.progressIconMetaPool:AcquireObject()
            progressIcon:SetParent(control.progressIcons)
            progressIcon:ClearAnchors()

            if numGoalsAchieved >= progressIndex then
                progressIcon:SetTexture(ZO_DIGSITE_COMPLETE_ICON_TEXTURE)
            else
                progressIcon:SetTexture(ZO_DIGSITE_UNKNOWN_ICON_TEXTURE)
            end

            if previousIcon then
                progressIcon:SetAnchor(TOPLEFT, previousIcon, TOPRIGHT, 4)
            else
                progressIcon:SetAnchor(TOPLEFT)
            end

            previousIcon = progressIcon
        end
    end
end

function ZO_AntiquityJournalListGamepad:SetupInProgressAntiquityNearExpirationRow(control, data)
    self:SetupInProgressAntiquityRow(control, data)

    local isLeadNearingExpiration, leadTimeRemaining = data:GetLeadExpirationStatus()
    if isLeadNearingExpiration then
        control.leadExpirationLabel:SetText(zo_strformat(SI_ANTIQUITY_TOOLTIP_LEAD_EXPIRATION, ZO_SELECTED_TEXT:Colorize(leadTimeRemaining)))
    end
    control.leadExpirationLabel:SetHidden(not isLeadNearingExpiration)
end

function ZO_AntiquityJournalListGamepad:GetCurrentCategoryData()
    return ANTIQUITY_JOURNAL_GAMEPAD:GetCurrentCategoryData()
end

function ZO_AntiquityJournalListGamepad:GetCurrentSubcategoryData()
    return ANTIQUITY_JOURNAL_GAMEPAD:GetCurrentSubcategoryData()
end

function ZO_AntiquityJournalListGamepad:ClearAntiquityTooltip()
    local DO_NOT_RETAIN_FRAGMENT = false
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, DO_NOT_RETAIN_FRAGMENT)
end

-- Antiquity Journal Locked Content

ZO_AntiquityJournalLockedContentGamepad = ZO_Object:Subclass()

function ZO_AntiquityJournalLockedContentGamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityJournalLockedContentGamepad:Initialize(control)
    self.control = control
    self.lockedContentPanel = control:GetNamedChild("ContainerContent")
    self.antiquarianGuildZoneLockedLabel = self.lockedContentPanel:GetNamedChild("AntiquarianGuildZoneLockedLabel")
    self.scryingToolLockedLabel = self.lockedContentPanel:GetNamedChild("ScryingToolLockedLabel")

    local function OnStateChanged(state)
        if state == SCENE_FRAGMENT_SHOWING then
            self:Refresh()
        end
    end

    self.fragment = ZO_SimpleSceneFragment:New(control)
    ZO_ANTIQUITY_JOURNAL_LOCKED_CONTENT_GAMEPAD_FRAGMENT = self.fragment
    self.fragment:RegisterCallback("StateChange", OnStateChanged)

    ANTIQUITY_MANAGER:RegisterCallback("OnContentLockChanged", function() self:Refresh() end)
end

function ZO_AntiquityJournalLockedContentGamepad:Refresh()
    local isAntiquarianGuildZoneUnlocked = ZO_IsAntiquarianGuildUnlocked()
    local isScryingToolUnlocked = ZO_IsScryingToolUnlocked()
    local areSkillLinesDiscovered = AreAntiquitySkillLinesDiscovered()
    local isScryingUnlocked = isScryingToolUnlocked and areSkillLinesDiscovered

    if not isAntiquarianGuildZoneUnlocked then
        self.antiquarianGuildZoneLockedLabel:SetText(ANTIQUITY_MANAGER:GetAntiquarianGuildZoneLockedMessage())
    end
    self.antiquarianGuildZoneLockedLabel:SetHidden(isAntiquarianGuildZoneUnlocked)
    if not isScryingUnlocked then
        self.scryingToolLockedLabel:SetText(ANTIQUITY_MANAGER:GetScryingLockedMessage())
    end
    self.scryingToolLockedLabel:SetHidden(isScryingUnlocked)
end

-- Global UI

function ZO_AntiquityJournalGamepad_OnInitialized(control)
    ANTIQUITY_JOURNAL_GAMEPAD = ZO_AntiquityJournalGamepad:New(control)
end

function ZO_AntiquityJournalListGamepad_OnInitialized(control)
    ANTIQUITY_JOURNAL_LIST_GAMEPAD = ZO_AntiquityJournalListGamepad:New(control)
end

function ZO_AntiquityJournalLockedContent_Gamepad_OnInitialized(control)
    ANTIQUITY_JOURNAL_LOCKED_CONTENT_GAMEPAD = ZO_AntiquityJournalLockedContentGamepad:New(control)
end

function ZO_AntiquityJournalAntiquitySectionRowGamepad_OnInitialized(control)
    control.label = control:GetNamedChild("Label")
end

function ZO_AntiquityJournalBaseRowGamepad_OnInitialized(control)
    control.iconTexture = control:GetNamedChild("IconContainerIconTexture")
    control.status = control:GetNamedChild("Status")
    control.header = control:GetNamedChild("Header")
    control.titleLabel = control.header:GetNamedChild("TitleLabel")
    control.antiquityTypeLabel = control.header:GetNamedChild("AntiquityTypeLabel")
    control.numRecoveredLabel = control.header:GetNamedChild("NumRecoveredLabel")
end

function ZO_AntiquityJournalInProgressAntiquityRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalBaseRowGamepad_OnInitialized(control)

    control.difficultyLabel = control.header:GetNamedChild("DifficultyLabel")
    control.zoneLabel = control.header:GetNamedChild("Zone")
    control.progressIcons = control:GetNamedChild("ProgressIcons")
end

function ZO_AntiquityJournalInProgressAntiquityNearExpirationRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalInProgressAntiquityRowGamepad_OnInitialized(control)

    control.leadExpirationLabel = control:GetNamedChild("LeadExpirationLabel")
end

function ZO_AntiquityJournalScryableAntiquityRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalBaseRowGamepad_OnInitialized(control)

    control.difficultyLabel = control.header:GetNamedChild("DifficultyLabel")
    control.zoneLabel = control.header:GetNamedChild("Zone")
end

function ZO_AntiquityJournalScryableAntiquityNearExpirationRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalScryableAntiquityRowGamepad_OnInitialized(control)

    control.leadExpirationLabel = control:GetNamedChild("LeadExpirationLabel")
end

function ZO_AntiquityJournalAntiquityRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalBaseRowGamepad_OnInitialized(control)

    control.progressContainer = control.header:GetNamedChild("ProgressContainer")
    control.progressLabel = control.progressContainer:GetNamedChild("Progress")
end

function ZO_AntiquityJournalAntiquitySetRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalBaseRowGamepad_OnInitialized(control)

    control.progressContainer = control.header:GetNamedChild("ProgressContainer")
    control.progressLabel = control.progressContainer:GetNamedChild("Progress")
    control.contentContainer = control:GetNamedChild("ContentContainer")
    control.antiquitiesRecoveredLabel = control.contentContainer:GetNamedChild("AntiquitiesRecoveredLabel")
    control.antiquitiesListControl = control.contentContainer:GetNamedChild("AntiquitiesGridList")
end