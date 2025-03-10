-- TODO GroupFinder: Screen narration

ZO_GROUP_LISTING_GAMEPAD_HEIGHT = 120
ZO_GROUP_LISTING_ROLE_CONTROL_PADDING_GAMEPAD = 10

ZO_GroupFinder_Gamepad = ZO_Object.MultiSubclass(ZO_GroupFinder_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_GroupFinder_Gamepad:Initialize(control)
    local DONT_ACTIVATE_ON_SHOW = false
    GROUP_FINDER_SCENE_GAMEPAD = ZO_Scene:New("GroupFinderGamepad", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, DONT_ACTIVATE_ON_SHOW, GROUP_FINDER_SCENE_GAMEPAD)
    ZO_GroupFinder_Shared.Initialize(self, control)

    self.headerData =
    {
        titleText = function()
            if self.mode == ZO_GROUP_FINDER_MODES.MANAGE then
                return GetString(SI_GROUP_FINDER_MY_GROUP_LISTING)
            elseif self.mode == ZO_GROUP_FINDER_MODES.SEARCH then
                return GetString(SI_GAMEPAD_GROUP_FINDER_FIND_GROUP)
            else
                return GetString(SI_ACTIVITY_FINDER_CATEGORY_GROUP_FINDER)
            end
        end,
    }
end

-- Begin ZO_GroupFinder_Shared overrides
function ZO_GroupFinder_Gamepad:InitializeControls()
    self.categoryList = self:GetMainList()
    self.categoryList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.subcategoryList = self:AddList("Subcategory")
    self.subcategoryList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Primary
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local entryData = self:GetCurrentList():GetTargetData()
                if entryData.isRoleSelector then
                    GAMEPAD_GROUP_ROLES_BAR:ToggleSelected()
                elseif self:IsCurrentList(self.categoryList) then
                    local data = self.categoryList:GetTargetData()
                    if data.mode == ZO_GROUP_FINDER_MODES.CREATE_EDIT then
                        if HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING) then
                            ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_CREATE_RESCIND_APPLICATION")
                        else
                            self.createEditDialogObject:ShowDialog()
                        end
                    else
                        self:SetMode(data.mode)
                    end
                else
                    --If the subcategory list is already active, try to select the currently targeted entry
                    local subCategoryData = self.subcategoryList:GetTargetData()
                    if subCategoryData.selectCallback ~= nil then
                        subCategoryData.selectCallback(subCategoryData)
                    end
                end
            end,
            enabled = function()
                if self:IsCurrentList(self.categoryList) then
                    local data = self.categoryList:GetTargetData()
                    return data and data.enabled
                else
                    local subCategoryData = self.subcategoryList:GetTargetData()
                    if subCategoryData then
                        local enabled = subCategoryData.enabled
                        if type(subCategoryData.enabled) == "function" then
                            enabled = subCategoryData.enabled()
                        end
                        return enabled
                    end
                end
                return true
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Open Group Menu
        {
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = GetString(SI_PLAYER_MENU_GROUP),
            callback = function()
                SYSTEMS:GetObject("mainMenu"):ShowGroupMenu()
            end,
            visible = function()
                return self.mode == ZO_GROUP_FINDER_MODES.MANAGE
            end,
        },
        -- Back
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                if self:GetCurrentList() == self.categoryList then
                    SCENE_MANAGER:HideCurrentScene()
                else
                    self:SetMode(ZO_GROUP_FINDER_MODES.OVERVIEW)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
    }
    self:SetListsUseTriggerKeybinds(true)
end

function ZO_GroupFinder_Gamepad:InitializeGroupFinderCategories()
    GROUP_FINDER_GAMEPAD_FRAGMENT = self.sceneFragment
    self.scene:AddFragment(self.sceneFragment)

    self.categoryData =
    {
        gamepadData =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.GROUP_FINDER,
            name = GetString(SI_ACTIVITY_FINDER_CATEGORY_GROUP_FINDER),
            menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_groupFinder.dds",
            disabledMenuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_groupFinder_disabled.dds",
            sceneName = "GroupFinderGamepad",
            tooltipDescription = GetString(SI_GROUP_FINDER_DESCRIPTION),
            isGroupFinder = true,
        },
    }

    local gamepadData = self.categoryData.gamepadData
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(gamepadData, gamepadData.priority)

    local findGroupCategoryData = {}
    for index = GROUP_FINDER_CATEGORY_ITERATION_BEGIN, GROUP_FINDER_CATEGORY_ITERATION_END do
        local data =
        {
            name = GetString("SI_GROUPFINDERCATEGORY", index),
            --TODO GroupFinder: Do we need subcategoryType?
            subcategoryType = index,
            selectCallback = function(entryData)
                SetGroupFinderFilterCategory(index)
                GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
                SCENE_MANAGER:Push("group_finder_gamepad_list")
            end,
        }
        table.insert(findGroupCategoryData, data)
    end

    self.subcategoryData =
    {
        [ZO_GROUP_FINDER_MODES.CREATE_EDIT] =
        {
            --TODO GroupFinder: Do we need any subcategory data for this mode?
        },
        [ZO_GROUP_FINDER_MODES.SEARCH] = findGroupCategoryData,
        [ZO_GROUP_FINDER_MODES.MANAGE] =
        {
            {
                name = GetString(SI_GAMEPAD_GROUP_FINDER_MANAGE_LISTING),
                menuIcon = "EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_manageGroup.dds",
                selectCallback = function(entryData)
                    self:EnterApplicationList()
                end,
            },
            {
                name = GetString(SI_GROUP_FINDER_EDIT_GROUP),
                menuIcon = "EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_editListing.dds",
                enabled = function()
                    return not HasPendingAcceptedGroupFinderApplication()
                end,
                selectCallback = function()
                    self.createEditDialogObject:ShowDialog()
                end,
            },
            {
                name = GetString(SI_GROUP_FINDER_REMOVE_GROUP),
                menuIcon = "EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_removeListing.dds",
                selectCallback = function()
                    --TODO GroupFinder: Add a confirmation popup here
                    RequestRemoveGroupListing()
                end,
            },
        },
    }
end

function ZO_GroupFinder_Gamepad:GetSystemName()
    return "GroupFinder_Gamepad"
end

function ZO_GroupFinder_Gamepad:OnGroupListingRequestCreateResult(result)
    if self:IsShowing() then
        if result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
            local RESET_SELECTION_TO_TOP = true
            self:SetMode(ZO_GROUP_FINDER_MODES.MANAGE, RESET_SELECTION_TO_TOP)
        else
            local NO_DATA = nil
            ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_CREATE_EDIT_FAILED", NO_DATA, { mainTextParams = { result } })
        end
    end
end

function ZO_GroupFinder_Gamepad:OnGroupListingRequestEditResult(result)
    if self:IsShowing() then
        if result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
            local RESET_SELECTION_TO_TOP = true
            self:SetMode(ZO_GROUP_FINDER_MODES.MANAGE, RESET_SELECTION_TO_TOP)
        else
            ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_CREATE_EDIT_FAILED", { isEdit = true }, { mainTextParams = { result } })
        end
    end
end

function ZO_GroupFinder_Gamepad:OnGroupListingRemoved(result)
    if self:IsShowing() then
        --If the group listing was removed while we were in manage mode, we need to switch back to overview
        if self.mode == ZO_GROUP_FINDER_MODES.MANAGE then
            if GROUP_FINDER_APPLICATION_LIST_SCREEN_GAMEPAD:HasActiveFocus() then
                self:ExitApplicationList()
            end
            self:SetMode(ZO_GROUP_FINDER_MODES.OVERVIEW)
        else
            self:RefreshList()
        end
    end
end

function ZO_GroupFinder_Gamepad:OnGroupListingAttainedRolesChanged()
    -- createEditDialogObject is created in the deferred initialize
    if self.createEditDialogObject then
        self.createEditDialogObject:OnGroupMemberRoleChanged()
    end
end

-- End ZO_GroupFinder_Shared overrides

function ZO_GroupFinder_Gamepad:EnterApplicationList()
    self:DeactivateCurrentList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    GROUP_FINDER_APPLICATION_LIST_SCREEN_GAMEPAD:Activate()
end

function ZO_GroupFinder_Gamepad:ExitApplicationList()
    GROUP_FINDER_APPLICATION_LIST_SCREEN_GAMEPAD:Deactivate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:ActivateCurrentList()
end

function ZO_GroupFinder_Gamepad:SetMode(newMode, resetToTop)
    if self:IsShowing() then
        if self.mode ~= newMode then
            local previousMode = self.mode
            if previousMode then
                SCENE_MANAGER:RemoveFragmentGroup(self.modeFragmentGroups[previousMode])
            end

            SCENE_MANAGER:AddFragmentGroup(self.modeFragmentGroups[newMode])
            self.mode = newMode
            self:SetCurrentListForMode(self.mode, resetToTop)
        end
    else
        self.pendingMode = newMode
    end
end

function ZO_GroupFinder_Gamepad:SetCurrentListForMode(mode, resetToTop)
    if mode == ZO_GROUP_FINDER_MODES.OVERVIEW then
        self:SetCurrentList(self.categoryList)
    else
        self:SetCurrentList(self.subcategoryList)
    end
    self:RefreshList(resetToTop)
end

function ZO_GroupFinder_Gamepad:RefreshHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GroupFinder_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)

    local function OnSelectedEntry(_, selectedData)
        if selectedData.isRoleSelector then
            GAMEPAD_GROUP_ROLES_BAR:Activate()
        else
            GAMEPAD_GROUP_ROLES_BAR:Deactivate()
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end

    GAMEPAD_GROUP_ROLES_BAR:SetupListAnchorsBelowGroupBar(list.control)

    list:SetOnSelectedDataChangedCallback(OnSelectedEntry)
    list:SetDefaultSelectedIndex(2) --Don't select roles by default
end

function ZO_GroupFinder_Gamepad:RefreshList(resetToTop)
    if self.mode == ZO_GROUP_FINDER_MODES.OVERVIEW then
        self:RefreshCategoryList(resetToTop)
    else
        self:RefreshSubcategoryList(resetToTop)
    end
    self:RefreshHeader()
end

function ZO_GroupFinder_Gamepad:RefreshCategoryList(resetToTop)
    local list = self.categoryList
    if not list then
        return
    end
    list:Clear()

    do
        local entryData = ZO_GamepadEntryData:New("")
        entryData.isRoleSelector = true

        local list = self:GetMainList()
        list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    if HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING) then
        do
            local entryData = ZO_GamepadEntryData:New(GetString(SI_GROUP_FINDER_MY_GROUP_LISTING))
            entryData.mode = ZO_GROUP_FINDER_MODES.MANAGE
            entryData:AddIcon("EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_myGroup.dds")
            entryData.selectedIconTint = ZO_WHITE
            entryData.unselectedIconTint = ZO_GAMEPAD_UNSELECTED_COLOR

            if GROUP_FINDER_APPLICATIONS_LIST_MANAGER:HasNewApplication() then
                entryData:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
            end
            list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end
    else
        do
            local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GROUP_FINDER_FIND_GROUP))
            entryData.mode = ZO_GROUP_FINDER_MODES.SEARCH
            entryData:AddIcon("EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_findGroup.dds")
            entryData.selectedIconTint = ZO_WHITE
            entryData.unselectedIconTint = ZO_GAMEPAD_UNSELECTED_COLOR

            list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end

        do
            local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_GROUP_FINDER_CREATE_GROUP))
            entryData.mode = ZO_GROUP_FINDER_MODES.CREATE_EDIT
            entryData:AddIcon("EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_createGroup.dds")
            entryData.selectedIconTint = ZO_WHITE
            entryData.unselectedIconTint = ZO_GAMEPAD_UNSELECTED_COLOR

            local canDoCreateEdit, disabledString = ZO_GroupFinder_CanDoCreateEdit()
            entryData:SetEnabled(canDoCreateEdit)
            entryData.disabledTooltipText = disabledString
            list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end
    end

    list:Commit(resetToTop)
end

function ZO_GroupFinder_Gamepad:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    if targetData and targetData.disabledTooltipText and not targetData.enabled then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, targetData.disabledTooltipText)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GroupFinder_Gamepad:RefreshSubcategoryList(resetToTop)
    local list = self.subcategoryList
    if not list then
        return
    end
    list:Clear()

    do
        local entryData = ZO_GamepadEntryData:New("")
        entryData.isRoleSelector = true

        list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    local selectedIndex = 1
    if self.subcategoryData[self.mode] then
        local selectedCategory = GetGroupFinderFilterCategory()
        --Build the list using the subcategory data for the current mode
        for i, subcategoryData in ipairs(self.subcategoryData[self.mode]) do
            local entryData = ZO_GamepadEntryData:New(subcategoryData.name, subcategoryData.menuIcon)
            entryData.selectCallback = subcategoryData.selectCallback
            entryData.enabled = subcategoryData.enabled or entryData.enabled

            if self.mode == ZO_GROUP_FINDER_MODES.SEARCH and subcategoryData.subcategoryType == selectedCategory then
                selectedIndex = i
            end

            list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)

            if self.mode == ZO_GROUP_FINDER_MODES.MANAGE then
                GROUP_FINDER_APPLICATIONS_LIST_MANAGER:SetHasNewApplication(false)
            end
        end
    end

    -- Add one to the index to skip the role position
    list:SetSelectedIndex(selectedIndex + 1)
    list:Commit(resetToTop)
end

function ZO_GroupFinder_Gamepad:GetCategoryData()
    return self.categoryData
end

-- Begin ZO_Gamepad_ParametricList_Screen overrides

function ZO_GroupFinder_Gamepad:OnDeferredInitialize()
    self.createEditDialogObject = ZO_GroupFinder_CreateEditGroupListing_Gamepad:New()

    self.modeFragmentGroups =
    {
        [ZO_GROUP_FINDER_MODES.OVERVIEW] = {},
        [ZO_GROUP_FINDER_MODES.SEARCH] = {},
        [ZO_GROUP_FINDER_MODES.CREATE_EDIT] = {},
        [ZO_GROUP_FINDER_MODES.MANAGE] = { GROUP_FINDER_APPLICATION_LIST_SCREEN_GAMEPAD:GetFragment(), GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT },
    }
    self:RefreshHeader()
end

function ZO_GroupFinder_Gamepad:PerformUpdate()
    -- TODO GroupFinder
end

function ZO_GroupFinder_Gamepad:OnShowing()
    local RESET_DIFFICULTY = true
    UpdateGroupFinderFilterOptions(RESET_DIFFICULTY)

    if self.pendingMode then
        self:SetMode(self.pendingMode)
        self.pendingMode = nil
    else
        self:SetMode(ZO_GROUP_FINDER_MODES.OVERVIEW)
    end
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    TriggerTutorial(TUTORIAL_TRIGGER_GROUP_FINDER_OPENED)
end

function ZO_GroupFinder_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)
    --Calling self:SetMode at this point would set self.pendingMode instead, so we need to set self.mode manually here
    self.mode = nil
end

-- End ZO_Gamepad_ParametricList_Screen overrides

-- Global XML

function ZO_GroupFinder_Gamepad_OnInitialized(control)
    GROUP_FINDER_GAMEPAD = ZO_GroupFinder_Gamepad:New(control)
end