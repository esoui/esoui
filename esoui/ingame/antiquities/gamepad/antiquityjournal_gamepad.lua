ZO_IN_PROGRESS_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD = 128
ZO_SCRYABLE_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD = 85
ZO_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD = 85
ZO_ANTIQUITY_SET_1_DATA_ROW_HEIGHT_GAMEPAD = 200
ZO_ANTIQUITY_SET_2_DATA_ROW_HEIGHT_GAMEPAD = 260
ZO_ANTIQUITY_SET_3_DATA_ROW_HEIGHT_GAMEPAD = 320
ZO_ANTIQUITY_SET_4_DATA_ROW_HEIGHT_GAMEPAD = 380
ZO_ANTIQUITY_SECTION_DATA_ROW_HEIGHT_GAMEPAD = 50

local MAX_ANTIQUITIES_PER_ROW = 10
local IN_PROGRESS_ANTIQUITY_ROW_DATA = 1
local SCRYABLE_ANTIQUITY_ROW_DATA = 2
local ANTIQUITY_ROW_DATA = 3
local ANTIQUITY_SET_1_ROW_DATA = 4
local ANTIQUITY_SET_2_ROW_DATA = 5
local ANTIQUITY_SET_3_ROW_DATA = 6
local ANTIQUITY_SET_4_ROW_DATA = 7
local ANTIQUITY_SECTION_ROW_DATA = 8
local ANTIQUITY_SET_ROW_DATA_TEMPLATES =
{
    ANTIQUITY_SET_1_ROW_DATA,
    ANTIQUITY_SET_2_ROW_DATA,
    ANTIQUITY_SET_3_ROW_DATA,
    ANTIQUITY_SET_4_ROW_DATA,
}

local function IsScryableCategory(antiquityCategoryData)
    return antiquityCategoryData == ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA
end

-- Categories List

ZO_AntiquityJournalGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_AntiquityJournalGamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_AntiquityJournalGamepad:Initialize(control)
    self:InitializeControl(control)
    self:InitializeControlPools()
    self:InitializeLists()
    self:InitializeEvents()
end

function ZO_AntiquityJournalGamepad:InitializeControl(control)
    ANTIQUITY_JOURNAL_SCENE_GAMEPAD = ZO_Scene:New("gamepad_antiquity_journal", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ZO_ACTIVATE_ON_SHOW, ANTIQUITY_JOURNAL_SCENE_GAMEPAD)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    ZO_ANTIQUITY_JOURNAL_GAMEPAD_FRAGMENT = self.fragment
    self.fragment:SetHideOnSceneHidden(true)
    self.scene:AddFragment(ZO_ANTIQUITY_JOURNAL_GAMEPAD_FRAGMENT)
end

function ZO_AntiquityJournalGamepad:InitializeLists()
    self.categoryList = self:GetMainList()
    self.subcategoryList = self:AddList("subcategories")

    self.categoryList.refreshCallback = function(...)
        self:HideAntiquityListFragment()
        self:RefreshHeader()
    end
    self.categoryList.updateTargetCallback = function(data)
        self:SetCurrentCategoryData(data)
    end

    self.subcategoryList.refreshCallback = function(...)
        self:RefreshSubcategories(...)
        self:ShowAntiquityListFragment()
    end
    self.subcategoryList.updateTargetCallback = function(data)
        self:SetCurrentSubcategoryData(data)
        self:ShowAntiquityListFragment()
        self:RefreshAntiquityList()
    end

    -- Initialize each lists' keybinds.
    self.categoryList.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                self:SetCurrentList(self.subcategoryList)
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
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.subcategoryList.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:SetCurrentList(self.categoryList)
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
    
    self.antiquityIconControlPool = ZO_ControlPool:New("ZO_AntiquityJournalAntiquityIconTexture_Gamepad", self.control, "AntiquityIconGamepad")
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
end

function ZO_AntiquityJournalGamepad:PerformUpdate()
    local wasJournalScenePreviouslyOnTop = SCENE_MANAGER:WasSceneOnTopOfStack("gamepad_antiquity_journal")
    if wasJournalScenePreviouslyOnTop then
        -- Returning from Antiquity Lore Gamepad scene.
        -- Note that order matters.
        self:SetCurrentList(self.subcategoryList)
        self:ShowAntiquityListFragment()
        self:DeactivateCurrentList()
        self:ActivateAntiquityList()
    elseif not self:GetCurrentList() then
        self:SetCurrentList(self.categoryList)
    end
    self.dirty = false
end

function ZO_AntiquityJournalGamepad:OnShowing()
    TriggerTutorial(TUTORIAL_TRIGGER_ANTIQUITY_JOURNAL_OPENED)
end

function ZO_AntiquityJournalGamepad:OnHiding()
    ZO_ClearAntiquityTooltips_Gamepad()
    self:DisableCurrentList()
    self:HideAntiquityListFragment()
    self.dirty = true
end

function ZO_AntiquityJournalGamepad:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    if list.updateTargetCallback and targetData and targetData.dataSource then
        list.updateTargetCallback(targetData.dataSource)
    end
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

function ZO_AntiquityJournalGamepad:SetCurrentList(list, ...)
    if list.refreshCallback then
        list.refreshCallback(...)
    end
    ZO_Gamepad_ParametricList_Screen.SetCurrentList(self, list, ...)
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
    if self.currentCategoryData and not IsScryableCategory(self.currentCategoryData) then
        self.currentCategoryData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquityCategoryData(self.currentCategoryData:GetId())
    end

    if self.currentSubcategoryData then
        self.currentSubcategoryData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquityCategoryData(self.currentSubcategoryData:GetId())
    end

    if not self.fragment:IsHidden() then
        if self:GetCurrentList() == self.subcategoryList then
            self:RefreshSubcategories()
            self:ShowAntiquityListFragment()
        end

        self:DeactivateAntiquityList()
        self:ActivateCurrentList()
    end

    self:RefreshCategories()
end

function ZO_AntiquityJournalGamepad:RefreshHeader(title)
    self.headerData =
    {
        titleText = title or GetString(SI_JOURNAL_MENU_ANTIQUITIES),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_AntiquityJournalGamepad:RefreshCategories()
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
        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    for _, categoryData in ANTIQUITY_DATA_MANAGER:TopLevelAntiquityCategoryIterator() do
        local categoryName = categoryData:GetName()
        local gamepadIcon = categoryData:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)

        entryData:SetDataSource(categoryData)
        entryData:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    self.categoryList:Commit()
end

function ZO_AntiquityJournalGamepad:RefreshSubcategories()
    -- Add the subcategory entries.
    self.subcategoryList:Clear()

    local categoryData = self:GetCurrentCategoryData()
    if categoryData then
        self:RefreshHeader(categoryData:GetName())

        if IsScryableCategory(categoryData) or categoryData:GetNumAntiquities() > 0 then
            local categoryName = categoryData:GetName()
            local entryData = ZO_GamepadEntryData:New(categoryName)

            entryData:SetDataSource(categoryData)
            self.subcategoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end

        for _, subcategoryData in categoryData:SubcategoryIterator() do
            local subcategoryName = subcategoryData:GetName()
            local entryData = ZO_GamepadEntryData:New(subcategoryName)

            entryData:SetDataSource(subcategoryData)
            self.subcategoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end
    end

    self.subcategoryList:Commit()
end

function ZO_AntiquityJournalGamepad:ShowAntiquityListFragment()
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
    self:SetCurrentCategoryData(ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA)
end

function ZO_AntiquityJournalGamepad:GetCurrentCategoryData()
    return self.currentCategoryData
end

function ZO_AntiquityJournalGamepad:SetCurrentCategoryData(categoryData)
    self.currentCategoryData = categoryData
end

function ZO_AntiquityJournalGamepad:GetCurrentSubcategoryData()
    return self.currentSubcategoryData
end

function ZO_AntiquityJournalGamepad:SetCurrentSubcategoryData(subcategoryData)
    self.currentSubcategoryData = subcategoryData
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
    ZO_ScrollList_AddDataType(listControl, IN_PROGRESS_ANTIQUITY_ROW_DATA, "ZO_AntiquityJournalInProgressAntiquityRow_Gamepad", ZO_IN_PROGRESS_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupInProgressAntiquityRow(control, data) end)
    ZO_ScrollList_AddDataType(listControl, SCRYABLE_ANTIQUITY_ROW_DATA, "ZO_AntiquityJournalScryableAntiquityRow_Gamepad", ZO_SCRYABLE_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupScryableAntiquityRow(control, data) end)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_ROW_DATA, "ZO_AntiquityJournalAntiquityRow_Gamepad", ZO_ANTIQUITY_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupAntiquityRow(control, data) end)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_1_ROW_DATA, "ZO_AntiquityJournalAntiquitySet1Row_Gamepad", ZO_ANTIQUITY_SET_1_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupAntiquitySetRow(control, data) end)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_2_ROW_DATA, "ZO_AntiquityJournalAntiquitySet2Row_Gamepad", ZO_ANTIQUITY_SET_2_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupAntiquitySetRow(control, data) end)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_3_ROW_DATA, "ZO_AntiquityJournalAntiquitySet3Row_Gamepad", ZO_ANTIQUITY_SET_3_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupAntiquitySetRow(control, data) end)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SET_4_ROW_DATA, "ZO_AntiquityJournalAntiquitySet4Row_Gamepad", ZO_ANTIQUITY_SET_4_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupAntiquitySetRow(control, data) end)
    ZO_ScrollList_AddDataType(listControl, ANTIQUITY_SECTION_ROW_DATA, "ZO_AntiquityJournalAntiquitySectionRow_Gamepad", ZO_ANTIQUITY_SECTION_DATA_ROW_HEIGHT_GAMEPAD, function(control, data) self:SetupAntiquitySectionRow(control, data) end)
    ZO_ScrollList_SetTypeSelectable(listControl, ANTIQUITY_SECTION_ROW_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(listControl, ANTIQUITY_SECTION_ROW_DATA, true)

    local function ShowSubcategories()
        self:Deactivate()
        ANTIQUITY_JOURNAL_GAMEPAD:SetCurrentList("subcategories")
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
            name = function()
                local categoryData = self:GetCurrentSubcategoryData()
                if IsScryableCategory(categoryData) then
                    return GetString(SI_ANTIQUITY_ABANDON)
                else
                    return GetString(SI_ANTIQUITY_FRAGMENTS)
                end
            end,
            callback = function()
                local categoryData = self:GetCurrentSubcategoryData()
                if IsScryableCategory(categoryData) then
                    local antiquityData = self:GetCurrentAntiquityData()
                    if antiquityData then
                        ZO_Dialogs_ShowGamepadDialog("CONFIRM_ABANDON_ANTIQUITY_SCRYING_PROGRESS", { antiquityId = antiquityData:GetId() })
                    end
                else
                    self:ToggleAntiquityFragmentFocus()
                end
            end,
            visible = function()
                local antiquityData = self:GetCurrentAntiquityData()
                if antiquityData and antiquityData:HasDiscovered() then
                    local categoryData = self:GetCurrentSubcategoryData()
                    if IsScryableCategory(categoryData) then
                        return antiquityData:HasDiscoveredDigSites()
                    else
                        return antiquityData:GetType() == ZO_ANTIQUITY_TYPE_SET
                    end
                end
                return false
            end
        },
        {
            order = 30,
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
            callback = function()
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
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ShowSubcategories)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, listControl)

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
    ZO_ClearAntiquityTooltips_Gamepad()
    self:Deactivate()
end

function ZO_AntiquityJournalListGamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList.OnSelectionChanged(self, oldData, newData)
    self:UpdateKeybinds()

    if newData then
        if newData:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
            ZO_ShowAntiquityTooltip_Gamepad(newData:GetId())
        else
            ZO_ShowAntiquitySetTooltip_Gamepad(newData:GetId())
        end
    else
        ZO_ClearAntiquityTooltips_Gamepad()
    end
end

function ZO_AntiquityJournalListGamepad:GetCurrentAntiquityData()
    return ZO_ScrollList_GetSelectedData(self.list)
end

do
    local function CompareInProgress(left, right)
        local leftProgress = left:GetNumDigSites()
        local rightProgress = right:GetNumDigSites()
        if leftProgress < rightProgress then
            return false
        elseif leftProgress == rightProgress then
            return ZO_Antiquity.CompareNameTo(left, right)
        end
        return true
    end

    local function CompareName(left, right)
        return ZO_Antiquity.CompareNameTo(left, right)
    end

    local function AddAntiquitySectionList(scrollDataList, headingText, antiquitySection)
        if #antiquitySection.list > 0 then
            table.sort(antiquitySection.list, antiquitySection.sortFunction)
            table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(ANTIQUITY_SECTION_ROW_DATA, {label = headingText}))
            local rowTemplate = antiquitySection.rowTemplate

            for _, antiquityData in ipairs(antiquitySection.list) do
                -- Add this scryable antiquity as a tile.
                table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(rowTemplate, antiquityData))
            end
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
                filterFunctions = {function(antiquityData) return antiquityData:HasDiscovered() and antiquityData:IsInCurrentPlayerZone() and not antiquityData:MeetsLeadRequirements() end},
                sortFunction = ZO_DefaultAntiquitySortComparison,
                rowTemplate = SCRYABLE_ANTIQUITY_ROW_DATA,
                list = {}
            },
            {
                sectionHeading = GetString(SI_ANTIQUITY_SUBHEADING_REQUIRES_SKILL),
                filterFunctions = {function(antiquityData) return antiquityData:HasDiscovered() and antiquityData:IsInCurrentPlayerZone() and not antiquityData:MeetsScryingSkillRequirements() end},
                sortFunction = ZO_DefaultAntiquitySortComparison,
                rowTemplate = SCRYABLE_ANTIQUITY_ROW_DATA,
                list = {}
            },
        }
    end

    function ZO_AntiquityJournalListGamepad:RefreshAntiquities()
        local currentSubcategoryData = self:GetCurrentSubcategoryData()
        local listControl = self:GetListControl()
        ZO_ScrollList_Clear(listControl)
        local scrollDataList = ZO_ScrollList_GetDataList(listControl)

        if not currentSubcategoryData then
            self.titleLabel:SetText("")
        else
            -- Refresh the header.
            self.titleLabel:SetText(currentSubcategoryData:GetName())

            if IsScryableCategory(currentSubcategoryData) then
                for _, antiquitySection in ipairs(self.scryableAntiquitySections) do
                    ZO_ClearNumericallyIndexedTable(antiquitySection.list)
                end

                -- Iterate over all antiquities, adding each antiquity to the section whose criteria it meets (if any).
                for _, antiquityData in ANTIQUITY_DATA_MANAGER:AntiquityIterator({ZO_Antiquity.IsVisible}) do
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
                        AddAntiquitySectionList(scrollDataList, antiquitySection.sectionHeading, antiquitySection)
                    end
                end
            else
                -- Add the antiquity/antiquity set entries.
                local antiquitySets = {}

                for _, antiquityData in currentSubcategoryData:AntiquityIterator({ZO_Antiquity.IsVisible}) do
                    local antiquitySetData = antiquityData:GetAntiquitySetData()
                    local entryData, entryTemplate

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
                            else
                                entryTemplate = ANTIQUITY_ROW_DATA
                            end
                        end
                    else
                        entryData = antiquityData
                        entryTemplate = ANTIQUITY_ROW_DATA
                    end

                    if entryData then
                        table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(entryTemplate, entryData))
                    end
                end
            end
        end

        self:CommitScrollList()
        local hasData = ZO_ScrollList_HasVisibleData(listControl)
        listControl:SetHidden(not hasData)
        self.emptyLabel:SetHidden(hasData)
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
        control.numRecoveredLabel:SetAnchor(BOTTOMLEFT)
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
            control.numRecoveredLabel:SetAnchor(BOTTOMLEFT)
        end
        control.numRecoveredLabel:SetText(zo_strformat(SI_ANTIQUITY_TIMES_ACQUIRED, numRecovered))
        control.numRecoveredLabel:SetColor(labelColor:UnpackRGB())
        control.numRecoveredLabel:SetHidden(false)
    else
        control.numRecoveredLabel:SetHidden(true)
    end

    local iconTextureFile = hasDiscovered and data:GetIcon() or ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE
    control.iconTexture:SetTexture(iconTextureFile)
    if hasDiscovered and not hasRecovered then
        control.iconTexture:SetDesaturation(1)
        control.iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 0.7)
        control.iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0.3)
    else
        local desaturation = data:IsComplete() and 0 or 1
        control.iconTexture:SetDesaturation(desaturation)
        control.iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1)
        control.iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0)
    end
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

do
    local function OnSelectedDataChanged(oldData, newData)
        if newData then
            ZO_ShowAntiquitySetFragmentTooltip_Gamepad(newData:GetId())
        else
            ZO_ClearAntiquityTooltips_Gamepad()
        end
    end

    function ZO_AntiquityJournalListGamepad:SetupAntiquitySetRow(control, data)
        self:SetupBaseLogbookRow(control, data)

        control.antiquitiesRecoveredLabel:SetText(zo_strformat(SI_ANTIQUITY_PIECES_FOUND, data:GetNumAntiquitiesRecovered(), data:GetNumAntiquities()))

        local TEMPLATE_DIMENSIONS = 50
        local NUM_COLUMNS = 10

        if control.antiquitiesScrollList then
            control.antiquitiesScrollList:ClearGridList()
        else
            control.antiquitiesScrollList = ZO_GridScrollList_Gamepad:New(control.antiquitiesListControl)
            local NO_HIDE_CALLBACK = nil
            local DO_NOT_CENTER_ENTRIES = false
            control.antiquitiesScrollList:AddEntryTemplate("ZO_AntiquityJournalAntiquityIconTexture_Gamepad", TEMPLATE_DIMENSIONS, TEMPLATE_DIMENSIONS, ZO_AntiquityJournalAntiquityIcon_Setup, NO_HIDE_CALLBACK, ZO_ObjectPool_DefaultResetControl, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD, DO_NOT_CENTER_ENTRIES)
            control.antiquitiesScrollList:RegisterCallback("SelectedDataChanged", OnSelectedDataChanged)
        end

        for _, antiquityData in data:AntiquityIterator() do
            control.antiquitiesScrollList:AddEntry(antiquityData, "ZO_AntiquityJournalAntiquityIconTexture_Gamepad")
        end

        local numAntiquities = data:GetNumAntiquities()
        local numRows = math.ceil(numAntiquities / NUM_COLUMNS)
        local gridHeight = TEMPLATE_DIMENSIONS * numRows + ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD * (numRows - 1)

        control.antiquitiesListControl:SetHeight(gridHeight)
        control.antiquitiesScrollList:CommitGridList()
        ZO_ScrollList_SetHeight(control.antiquitiesScrollList.list, gridHeight)
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
                control.difficultyLabel:SetAnchor(BOTTOMLEFT)
            else
                control.difficultyLabel:SetAnchor(LEFT, control.antiquityTypeLabel, RIGHT, 15)
            end
        else
            control.difficultyLabel:SetAnchor(LEFT, control.numRecoveredLabel, RIGHT, 15)
        end
        control.difficultyLabel:SetHidden(false)
    else
        control.difficultyLabel:SetHidden(true)
    end
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

function ZO_AntiquityJournalListGamepad:GetCurrentCategoryData()
    return ANTIQUITY_JOURNAL_GAMEPAD:GetCurrentCategoryData()
end

function ZO_AntiquityJournalListGamepad:GetCurrentSubcategoryData()
    return ANTIQUITY_JOURNAL_GAMEPAD:GetCurrentSubcategoryData()
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
    control.header = control:GetNamedChild("Header")
    control.titleLabel = control.header:GetNamedChild("TitleLabel")
    control.antiquityTypeLabel = control.header:GetNamedChild("AntiquityTypeLabel")
    control.numRecoveredLabel = control.header:GetNamedChild("NumRecoveredLabel")
end

function ZO_AntiquityJournalInProgressAntiquityRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalBaseRowGamepad_OnInitialized(control)

    control.difficultyLabel = control.header:GetNamedChild("DifficultyLabel")
    control.progressIcons = control:GetNamedChild("ProgressIcons")
end

function ZO_AntiquityJournalScryableAntiquityRowGamepad_OnInitialized(control)
    ZO_AntiquityJournalBaseRowGamepad_OnInitialized(control)

    control.difficultyLabel = control.header:GetNamedChild("DifficultyLabel")
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

function ZO_AntiquityJournalAntiquityIcon_Setup(control, data)
    local iconTextureFile = data:HasDiscovered() and data:GetIcon() or ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE
    local showSilhouette = textureIcon ~= ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE and not data:HasRecovered()

    control.antiquityData = data
    control:SetTexture(iconTextureFile)
    if showSilhouette then
        control:SetDesaturation(1)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 0.7)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0.3)
    else
        local desaturation = data:IsComplete() and 0 or 1
        control:SetDesaturation(desaturation)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, 1)
        control:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, 0)
    end
    control:SetHidden(false)
end

function ZO_ShowAntiquityLeadTooltip_Gamepad(antiquityId)
    GAMEPAD_TOOLTIPS:LayoutAntiquityLead(GAMEPAD_RIGHT_TOOLTIP, antiquityId)
end

function ZO_ShowAntiquityTooltip_Gamepad(antiquityId)
    local antiquityData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquityData(antiquityId)
    if antiquityData and antiquityData:HasReward() and antiquityData:HasDiscovered() then
        local rewardId = antiquityData:GetRewardId()
        GAMEPAD_TOOLTIPS:LayoutReward(GAMEPAD_RIGHT_TOOLTIP, rewardId)
    else
        ZO_ClearAntiquityTooltips_Gamepad()
    end
end

function ZO_ShowAntiquitySetTooltip_Gamepad(antiquitySetId)
    local antiquitySetData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquitySetData(antiquitySetId)
    if antiquitySetData and antiquitySetData:HasReward() and antiquitySetData:HasDiscovered() then
        local rewardId = antiquitySetData:GetRewardId()
        GAMEPAD_TOOLTIPS:LayoutReward(GAMEPAD_RIGHT_TOOLTIP, rewardId)
    else
        ZO_ClearAntiquityTooltips_Gamepad()
    end
end

function ZO_ShowAntiquitySetFragmentTooltip_Gamepad(antiquityId)
    GAMEPAD_TOOLTIPS:LayoutAntiquitySetFragment(GAMEPAD_RIGHT_TOOLTIP, antiquityId)
end

function ZO_ClearAntiquityTooltips_Gamepad()
    local DO_NOT_RETAIN_FRAGMENT = false
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, DO_NOT_RETAIN_FRAGMENT)
end