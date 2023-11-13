local GROUP_LISTING_ENTRY = 1

----------------------------------------
--Group Finder Search Results List Row
----------------------------------------

ZO_GroupFinder_SearchResultsListRow = ZO_InitializingObject:Subclass()

function ZO_GroupFinder_SearchResultsListRow:Initialize(control)
    control.object = self
    self.control = control
end

function ZO_GroupFinder_SearchResultsListRow:AttachToList(list)
    self.list = list
end

function ZO_GroupFinder_SearchResultsListRow:EnterRow()
    self.list:Row_OnMouseEnter(self.control)
end

function ZO_GroupFinder_SearchResultsListRow:ExitRow()
    self.list:Row_OnMouseExit(self.control)
end

function ZO_GroupFinder_SearchResultsListRow:OnMouseUp(control, button, upInside)
    self.list:Row_OnMouseUp(self.control, button, upInside)
end

function ZO_GroupFinder_SearchResultsListRow:OnMouseDoubleClick(control, button)
    self.list:Row_OnMouseDoubleClick(self.control, button)
end

--------------------------------------------------------------
-- ZO_GroupFinder_SearchResultsList_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_SearchResultsList_Keyboard = ZO_SortFilterList:Subclass()

function ZO_GroupFinder_SearchResultsList_Keyboard:Initialize(control, fragment)
    ZO_SortFilterList.Initialize(self, control)
    self.fragment = fragment
    self.roleControlPool = ZO_ControlPool:New("ZO_GroupFinder_RoleIconTemplate_Keyboard", control)
    self:InitializeKeybindDescriptors()
    self:RegisterForEvents()
end

function ZO_GroupFinder_SearchResultsList_Keyboard:RegisterForEvents()
    self.fragment:RegisterCallback("StateChange", function(...) self:OnStateChange(...) end)

    local function OnSearchResultsReady()
        if self.fragment:IsShowing() then
            self:RefreshData()
        end
    end
    GROUP_FINDER_SEARCH_MANAGER:RegisterCallback("OnGroupFinderSearchResultsReady", OnSearchResultsReady)

    local function OnSearchResultsUpdated()
        if self.fragment:IsShowing() then
            self:RefreshVisible()
        end
    end
    GROUP_FINDER_SEARCH_MANAGER:RegisterCallback("OnGroupFinderSearchResultsUpdated", OnSearchResultsUpdated)

    local function OnSearchStateChanged(newState)
        if self.fragment:IsShowing() then
            self:RefreshData()
        end
    end
    GROUP_FINDER_SEARCH_MANAGER:RegisterCallback("OnSearchStateChanged", OnSearchStateChanged)
end

function ZO_GroupFinder_SearchResultsList_Keyboard:InitializeSortFilterList(control)
    ZO_SortFilterList.InitializeSortFilterList(self, control)

    self:SetAutomaticallyColorRows(false)

    self.emptyText = control:GetNamedChild("EmptyText")
    self.loadingIcon = control:GetNamedChild("LoadingIcon")

    self.masterList = {}
    ZO_ScrollList_Initialize(self.list)

    local function SetupEntry(...)
        self:SetupGroupListingEntry(...)
    end

    local function ResetEntry(...) 
        self:ResetGroupListingEntry(...)
    end

    local NO_HIDE_CALLBACK = nil
    local NO_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.list, GROUP_LISTING_ENTRY, "ZO_GroupFinder_SearchResultsListRow_Keyboard", ZO_GROUP_LISTING_KEYBOARD_HEIGHT, SetupEntry, NO_HIDE_CALLBACK, NO_SELECT_SOUND, ResetEntry)

    local function GetHighlightTemplate(control)
        local data = ZO_ScrollList_GetData(control)
        local joinabilityResult = data:GetJoinabilityResult()
        local isListingJoinable = joinabilityResult == GROUP_FINDER_ACTION_RESULT_SUCCESS or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT or joinabilityResult == nil
        if isListingJoinable then
            return "ZO_ListEntryHighlight"
        else
            return "ZO_ListEntryHighlight_Disabled", "HighlightAnimationDisabled"
        end
    end

    ZO_ScrollList_EnableHighlight(self.list, GetHighlightTemplate)
end

function ZO_GroupFinder_SearchResultsList_Keyboard:InitializeKeybindDescriptors()
    self.rowKeybindStripDescriptor =
    {
        -- Report Listing
        {
            name = GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND),
            keybind = "UI_SHORTCUT_REPORT_PLAYER",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(data)
                end
            end,
        },
        -- Apply to Listing
        {
            name = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    return data:DoesGroupAutoAcceptRequests() and GetString(SI_GROUP_FINDER_JOIN_KEYBIND) or GetString(SI_GROUP_FINDER_APPLY_KEYBIND)
                end
                return ""
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            enabled = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    local joinabilityResult = data:GetJoinabilityResult()
                    local alertText
                    if joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_QUEUED then
                        alertText = GetString(SI_GROUP_FINDER_APPLY_DISABLED_QUEUED)
                    end
                    return joinabilityResult == GROUP_FINDER_ACTION_RESULT_SUCCESS
                        or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT, alertText
                end
                return false
            end,
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    self:TryShowApplyDialog(data)
                end
            end,
        },
    }
end

function ZO_GroupFinder_SearchResultsList_Keyboard:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWN then
        RequestSetGroupFinderExpectingUpdates(true)
        self:RefreshData()
    elseif newState == SCENE_FRAGMENT_HIDDEN then
        RequestSetGroupFinderExpectingUpdates(false)
    end
end

function ZO_GroupFinder_SearchResultsList_Keyboard:SetupGroupListingEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    control.listingData = data
    ZO_GroupFinder_Shared.SetUpGroupListingFromData(control, self.roleControlPool, data, ZO_GROUP_LISTING_ROLE_CONTROL_PADDING)
    control.object:AttachToList(self)
end

function ZO_GroupFinder_SearchResultsList_Keyboard:ResetGroupListingEntry(control)
    ZO_ObjectPool_DefaultResetControl(control)
    local data = control.listingData
    if data then
        ZO_GroupFinder_Shared.ResetRoleControls(control, self.roleControlPool)
    end
    control.listingData = nil
end

function ZO_GroupFinder_SearchResultsList_Keyboard:RefreshSearchState()
    local currentSearchState = GROUP_FINDER_SEARCH_MANAGER:GetSearchState()
    if currentSearchState == ZO_GROUP_FINDER_SEARCH_STATES.WAITING or currentSearchState == ZO_GROUP_FINDER_SEARCH_STATES.QUEUED then
        self.loadingIcon:Show()
        self.emptyText:SetText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_REFRESHING_RESULTS))
        self.emptyText:SetHidden(false)
    elseif currentSearchState == ZO_GROUP_FINDER_SEARCH_STATES.COMPLETE then
        self.loadingIcon:Hide()
        self.emptyText:SetText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_EMPTY_TEXT))
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        --If the scroll data is empty, show the empty row
        local hasEntries = #scrollData > 0
        self.emptyText:SetHidden(hasEntries)
    else
        self.loadingIcon:Hide()
        self.emptyText:SetHidden(true)
    end
end

function ZO_GroupFinder_SearchResultsList_Keyboard:TryShowApplyDialog(data)
    --If the user is missing a required collectible, show a dialog for that instead
    if data:GetJoinabilityResult() == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT then
        local collectibleId = data:GetFirstLockingCollectibleId()
        if collectibleId ~= 0 then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            local collectibleName = collectibleData:GetName()
            local categoryName = collectibleData:GetCategoryData():GetName()
            local message = zo_strformat(SI_GROUP_FINDER_APPLY_JOIN_DIALOG_COLLECTIBLE_LOCKED_FAILURE, ZO_SELECTED_TEXT:Colorize(data:GetTitle()))
            local marketOperation = MARKET_OPEN_OPERATION_GROUP_FINDER
            ZO_Dialogs_ShowPlatformDialog("COLLECTIBLE_REQUIREMENT_FAILED", { collectibleData = collectibleData, marketOpenOperation = marketOperation }, { mainTextParams = { message, collectibleName, categoryName } })
        end
    else
        ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_APPLICATION_KEYBOARD", data)
    end
end

--ZO_SortFilterList overrides
function ZO_GroupFinder_SearchResultsList_Keyboard:BuildMasterList()
    self.masterList = GROUP_FINDER_SEARCH_MANAGER:GetSearchResults()
end

function ZO_GroupFinder_SearchResultsList_Keyboard:FilterScrollList()
    -- No real filtering...just show everything in the master list
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.masterList) do
        if not data:IsActiveApplication() then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GROUP_LISTING_ENTRY, ZO_EntryData:New(data)))
        end
    end

    self:RefreshSearchState()
end

function ZO_GroupFinder_SearchResultsList_Keyboard:RefreshData()
    if self.fragment:IsShowing() then
        ZO_SortFilterList.RefreshData(self)
    end
end

function ZO_GroupFinder_SearchResultsList_Keyboard:Row_OnMouseEnter(control)
    ZO_SortFilterList.Row_OnMouseEnter(self, control)
    local data = ZO_ScrollList_GetData(control)
    if data then
        InitializeTooltip(GroupFinderGroupListingTooltip, control, RIGHT, -15, 0, LEFT)
        ZO_GroupFinderGroupListingTooltip_SetGroupFinderListing(GroupFinderGroupListingTooltip, data)
    end
    KEYBIND_STRIP:AddKeybindButtonGroup(self.rowKeybindStripDescriptor)
end

function ZO_GroupFinder_SearchResultsList_Keyboard:Row_OnMouseExit(control)
    ZO_SortFilterList.Row_OnMouseExit(self, control)
    ClearTooltip(GroupFinderGroupListingTooltip)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rowKeybindStripDescriptor)
end

function ZO_GroupFinder_SearchResultsList_Keyboard:Row_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()
        local data = ZO_ScrollList_GetData(control)
        if data then
            local joinabilityResult = data:GetJoinabilityResult()
            if joinabilityResult == GROUP_FINDER_ACTION_RESULT_SUCCESS or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT then
                local optionText = data:DoesGroupAutoAcceptRequests() and GetString(SI_GROUP_FINDER_JOIN_KEYBIND) or GetString(SI_GROUP_FINDER_APPLY_KEYBIND)
                AddMenuItem(optionText, function() self:TryShowApplyDialog(data) end)
            end
            if joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ALREADY_JOINED_GROUP then
                AddMenuItem(GetString(SI_GROUP_LEAVE), function()ZO_Dialogs_ShowDialog("GROUP_LEAVE_DIALOG") end)
            end
            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(data:GetOwnerDisplayName()) end)
            AddMenuItem(GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND), function() ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(data) end)
            self:ShowMenu(control)
        end
    end
end

function ZO_GroupFinder_SearchResultsList_Keyboard:Row_OnMouseDoubleClick(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local data = ZO_ScrollList_GetData(control)
        if data then
            local joinabilityResult = data:GetJoinabilityResult()
            if joinabilityResult == GROUP_FINDER_ACTION_RESULT_SUCCESS or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT then
                self:TryShowApplyDialog(data)
            end
        end
    end
end

--------------------------------------------------------------
-- ZO_GroupFinder_SearchPanel_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_SearchPanel_Keyboard = ZO_GroupFinder_BasePanel_Keyboard:Subclass()

function ZO_GroupFinder_SearchPanel_Keyboard:Initialize(control)
    ZO_GroupFinder_BasePanel_Keyboard.Initialize(self, control)
    self.appliedToListingData = ZO_GroupListingUserTypeData:New(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING)
    self.roleControlPool = ZO_ControlPool:New("ZO_GroupFinder_RoleIconTemplate_Keyboard", control)
    self:RegisterForEvents()
    self:InitializeKeybindStripDescriptors()
    self.createGroupListingButton = self.control:GetNamedChild("CreateGroupButton")
end

function ZO_GroupFinder_SearchPanel_Keyboard:InitializeControls()
    self.list = ZO_GroupFinder_SearchResultsList_Keyboard:New(self.control:GetNamedChild("List"), self:GetFragment())
    self.currentRoleLabel = self.control:GetNamedChild("CurrentRoleLabel")
    local SEARCH_IS_DIRTY = true
    PREFERRED_ROLES:RegisterCallback("LFGRoleChanged", function() self:RefreshCurrentRoleLabel(SEARCH_IS_DIRTY) end)

    self.difficultyContainer = self.control:GetNamedChild("DifficultyContainer")
    self.difficultyButtons =
    {
        [DUNGEON_DIFFICULTY_NORMAL] = self.difficultyContainer:GetNamedChild("NormalDifficulty"),
        [DUNGEON_DIFFICULTY_VETERAN] = self.difficultyContainer:GetNamedChild("VeteranDifficulty"),
    }

    self.difficultyRadioButtonGroup = ZO_RadioButtonGroup:New()
    for index, difficultyButton in ipairs(self.difficultyButtons) do
        self.difficultyRadioButtonGroup:Add(difficultyButton)
    end

    local function OnDifficultySelection(newButton, previousButton)
        local value
        for key, buttonControl in ipairs(self.difficultyButtons) do
            if buttonControl == newButton.m_clickedButton then
                value = key

                if newButton ~= previousButton then
                    if key == DUNGEON_DIFFICULTY_NORMAL then
                        PlaySound(SOUNDS.DUNGEON_DIFFICULTY_NORMAL)
                    else
                        PlaySound(SOUNDS.DUNGEON_DIFFICULTY_VETERAN)
                    end
                end
            end
        end
        if value then
            SetGroupFinderFilterPrimaryOptionByIndex(value, true)
            self:PopulateSecondaryDropdown()
            GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
        else
            internalassert(false, "No Difficulty button found to match button that was clicked.")
        end
    end

    self.difficultyRadioButtonGroup:SetSelectionChangedCallback(OnDifficultySelection)

    local function OnDropdownHidden()
        if self:GetFragment():IsShowing() then
            GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
        else
            self.isSearchDirty = true
        end
    end

    self.primaryOptionDropdownControl = self.control:GetNamedChild("PrimaryFilterSelector")
    self.primaryOptionDropdown = ZO_ComboBox_ObjectFromContainer(self.primaryOptionDropdownControl)
    self.primaryOptionDropdown:SetSortsItems(false)
    self.primaryOptionDropdown:EnableMultiSelect()
    self.primaryOptionDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)
    self.primaryOptionDropdown:SetFont("ZoFontWinT1")
    self.primaryOptionDropdown:SetSpacing(4)
    self.primaryOptionDropdown:SetHideDropdownCallback(OnDropdownHidden)
    self.primaryOptionDropdown:SetHeight(400)

    self.primaryOptionDropdownSingleSelectControl = self.control:GetNamedChild("PrimaryFilterSelectorSingleSelect")
    self.primaryOptionDropdownSingleSelect = ZO_ComboBox_ObjectFromContainer(self.primaryOptionDropdownSingleSelectControl)
    self.primaryOptionDropdownSingleSelect:SetSortsItems(false)
    self.primaryOptionDropdownSingleSelect:SetFont("ZoFontWinT1")
    self.primaryOptionDropdownSingleSelect:SetSpacing(4)
    self.primaryOptionDropdownSingleSelect:SetHideDropdownCallback(OnDropdownHidden)
    self.primaryOptionDropdown:SetHeight(400)

    self.secondaryOptionDropdownControl = self.control:GetNamedChild("SecondaryFilterSelector")
    self.secondaryOptionDropdown = ZO_ComboBox_ObjectFromContainer(self.secondaryOptionDropdownControl)
    self.secondaryOptionDropdown:SetSortsItems(false)
    self.secondaryOptionDropdown:EnableMultiSelect()
    self.secondaryOptionDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)
    self.secondaryOptionDropdown:SetFont("ZoFontWinT1")
    self.secondaryOptionDropdown:SetSpacing(4)
    self.secondaryOptionDropdown:SetHideDropdownCallback(OnDropdownHidden)
    self.secondaryOptionDropdown:SetHeight(400)

    local function OnSelectionBlockedCallback(item)
        if item.value == 1 then
            SetGroupFinderFilterSecondaryOptionByIndex(item.value, self.secondaryOptionDropdown:IsItemSelected(item))
            self.secondaryOptionDropdown:ClearAllSelections()
            self.secondaryOptionDropdown:SetSelected(item.value, IGNORE_CALLBACK)
            return true
        end
        return false
    end
    self.secondaryOptionDropdown:SetOnSelectionBlockedCallback(OnSelectionBlockedCallback)

    self:RefreshFilterOptions()
    self.appliedToListingControl = self.control:GetNamedChild("AppliedToGroupListing")

    local function AppliedToListingOnMouseEnter(listingControl)
        InitializeTooltip(GroupFinderGroupListingTooltip, self.appliedToListingControl, RIGHT, -15, 0, LEFT)
        ZO_GroupFinderGroupListingTooltip_SetGroupFinderListing(GroupFinderGroupListingTooltip, self.appliedToListingData)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.appliedToListingKeybindStripDescriptor)
    end

    local function AppliedToListingOnMouseExit(listingControl)
        ClearTooltip(GroupFinderGroupListingTooltip)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.appliedToListingKeybindStripDescriptor)
    end

    local function AppliedToListingOnMouseUp(listingControl, button, upInside)
        if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
            ClearMenu()
            AddMenuItem(GetString(SI_GROUP_FINDER_RESCIND_KEYBIND), function() RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_RESCIND) end)
            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(self.appliedToListingData:GetOwnerDisplayName()) end)
            AddMenuItem(GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND), function() ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(self.appliedToListingData) end)
            ShowMenu(listingControl)
        end
    end

    self.appliedToListingControl:SetHandler("OnMouseEnter", AppliedToListingOnMouseEnter)
    self.appliedToListingControl:SetHandler("OnMouseExit", AppliedToListingOnMouseExit)
    self.appliedToListingControl:SetHandler("OnMouseUp", AppliedToListingOnMouseUp)
end

function ZO_GroupFinder_SearchPanel_Keyboard:RegisterForEvents()
    local function OnRefreshSearch()
        GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
    end

    local function OnRefreshApplication()
        if self:GetFragment():IsShowing() then
            -- Cancel application if pending application was accepted and player is now grouped
            if IsUnitGrouped("player") then
                ZO_Dialogs_ReleaseDialog("GROUP_FINDER_APPLICATION_KEYBOARD")
            end
            self.list:RefreshFilters()
            self:RefreshAppliedToListing()
            self:UpdateCreateEditButton()
        end
    end

    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Keyboard", EVENT_GROUP_FINDER_REFRESH_SEARCH, OnRefreshSearch)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Keyboard", EVENT_GROUP_FINDER_APPLY_TO_GROUP_LISTING_RESULT, OnRefreshApplication)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Keyboard", EVENT_GROUP_FINDER_RESOLVE_GROUP_LISTING_APPLICATION_RESULT, OnRefreshApplication)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Keyboard", EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_APPLICATION, OnRefreshApplication)

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", function() self:UpdateCreateEditButton() end)
    GROUP_FINDER_SEARCH_MANAGER:RegisterCallback("OnGroupFinderSearchResultsUpdated", function() self:RefreshAppliedToListing() end)
end

function ZO_GroupFinder_SearchPanel_Keyboard:InitializeKeybindStripDescriptors()
    self.appliedToListingKeybindStripDescriptor =
    {
        -- Rescind
        {
            name = GetString(SI_GROUP_FINDER_RESCIND_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_RESCIND)
            end,
        },
        -- Report Listing
        {
            name = GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND),
            keybind = "UI_SHORTCUT_REPORT_PLAYER",
            callback = function()
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(self.appliedToListingData)
            end,
        },
    }
end

function ZO_GroupFinder_SearchPanel_Keyboard:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWING then
        self:RefreshFilterOptions()
        self:RefreshCurrentRoleLabel()
        self:RefreshAppliedToListing()
        self:UpdateCreateEditButton()

        if self.isSearchDirty then
            GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
            self.isSearchDirty = nil
        end
    end
end

function ZO_GroupFinder_SearchPanel_Keyboard:UpdateCreateEditButton()
    if self:GetFragment():IsShowing() then
        self.createGroupListingButton:SetEnabled(ZO_GroupFinder_CanDoCreateEdit())
    end
end

function ZO_GroupFinder_SearchPanel_Keyboard:SetSearchCategory(searchCategory)
    SetGroupFinderFilterCategory(searchCategory)
    GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
end

function ZO_GroupFinder_SearchPanel_Keyboard:GetSearchCategory()
    return GetGroupFinderFilterCategory()
end

function ZO_GroupFinder_SearchPanel_Keyboard:PopulatePrimaryDropdown()
    local category = self:GetSearchCategory()
    if self.primaryOptionDropdown and (category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_ZONE or category == GROUP_FINDER_CATEGORY_CUSTOM) then
        local function OnPrimarySelection(dropdown, selectedDataName, selectedData)
            SetGroupFinderFilterPrimaryOptionByIndex(selectedData.value, dropdown:IsItemSelected(selectedData))
            self:PopulateSecondaryDropdown()
        end

        ZO_GroupFinder_PopulateFiltersPrimaryOptionsDropdown(self.primaryOptionDropdown, OnPrimarySelection)
    end
end

function ZO_GroupFinder_SearchPanel_Keyboard:PopulatePrimaryDropdownSingleSelect()
    local category = self:GetSearchCategory()
    if self.primaryOptionDropdownSingleSelect and not (category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_ZONE or category == GROUP_FINDER_CATEGORY_CUSTOM) then
        local defaultText = ""

        local function OnPrimarySelection(dropdown, selectedDataName, selectedData)
            SetGroupFinderFilterPrimaryOptionByIndex(selectedData.value, true)
            self:PopulateSecondaryDropdown()
        end

        local function GetNumPrimaryOptions()
            return GetGroupFinderFilterNumPrimaryOptions()
        end

        ZO_GroupFinder_PopulateOptionsDropdown(self.primaryOptionDropdownSingleSelect, GetNumPrimaryOptions, GetGroupFinderFilterPrimaryOptionByIndex, OnPrimarySelection, defaultText)
    end
end

function ZO_GroupFinder_SearchPanel_Keyboard:PopulateSecondaryDropdown()
    if self.secondaryOptionDropdown then
        local function OnSecondarySelection(dropdown, selectedDataName, selectedData)
            SetGroupFinderFilterSecondaryOptionByIndex(selectedData.value, dropdown:IsItemSelected(selectedData))

            local IGNORE_CALLBACK = true
            dropdown:ClearAllSelections()
            for i = 1, GetGroupFinderFilterNumSecondaryOptions() do
                local _, isSet = GetGroupFinderFilterSecondaryOptionByIndex(i)
                if isSet then
                     dropdown:SetSelected(i, IGNORE_CALLBACK)
                end
            end
        end

        ZO_GroupFinder_PopulateFiltersSecondaryOptionsDropdown(self.secondaryOptionDropdown, OnSecondarySelection)
    end
end

function ZO_GroupFinder_SearchPanel_Keyboard:RefreshFilterOptions()
    local category = self:GetSearchCategory()

    local secondaryOptionParent
    self.secondaryOptionDropdownControl:ClearAnchors()

    -- TODO GroupFinder: Consider using a single dropdown that switches between multi-select and single select
    if category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_TRIAL then
        self.difficultyContainer:SetHidden(false)
        self.primaryOptionDropdownControl:SetHidden(true)
        self.primaryOptionDropdownSingleSelectControl:SetHidden(true)
        self.secondaryOptionDropdownControl:SetHidden(false)
        secondaryOptionParent = self.difficultyContainer

        local totalDifficulties = #self.difficultyButtons
        local availableDifficulties = GetGroupFinderFilterNumPrimaryOptions()
        for i = 1, totalDifficulties do
            if i <= availableDifficulties then
                local _, isSet = GetGroupFinderFilterPrimaryOptionByIndex(i)
                self.difficultyRadioButtonGroup:SetButtonIsValidOption(self.difficultyButtons[i], true)
                if isSet then
                    self.difficultyRadioButtonGroup:SetClickedButton(self.difficultyButtons[i], true)
                end
            else
                self.difficultyRadioButtonGroup:SetButtonIsValidOption(self.difficultyButtons[i], false)
            end
            self.difficultyButtons[i]:SetHidden(false)
        end
    elseif category == GROUP_FINDER_CATEGORY_PVP then
        self.difficultyContainer:SetHidden(true)
        self.primaryOptionDropdownControl:SetHidden(true)
        self.primaryOptionDropdownSingleSelectControl:SetHidden(false)
        self.secondaryOptionDropdownControl:SetHidden(false)
        secondaryOptionParent = self.primaryOptionDropdownSingleSelectControl
    elseif category == GROUP_FINDER_CATEGORY_ZONE then
        self.difficultyContainer:SetHidden(true)
        self.primaryOptionDropdownControl:SetHidden(false)
        self.primaryOptionDropdownSingleSelectControl:SetHidden(true)
        self.secondaryOptionDropdownControl:SetHidden(false)
        secondaryOptionParent = self.primaryOptionDropdownControl
    else
        self.difficultyContainer:SetHidden(true)
        self.primaryOptionDropdownControl:SetHidden(true)
        self.primaryOptionDropdownSingleSelectControl:SetHidden(true)
        self.secondaryOptionDropdownControl:SetHidden(true)
    end

    self.secondaryOptionDropdownControl:SetAnchor(LEFT, secondaryOptionParent, RIGHT, 15, 0)

    self:PopulatePrimaryDropdown()
    self:PopulatePrimaryDropdownSingleSelect()
    self:PopulateSecondaryDropdown()
end

function ZO_GroupFinder_SearchPanel_Keyboard:RefreshCurrentRoleLabel(isSearchDirty)
    if self.fragment:IsShowing() then
        if DoesGroupFinderFilterRequireEnforceRoles() then
            local currentRole = GetSelectedLFGRole()
            local roleIcon = zo_iconFormat(ZO_GetKeyboardRoleIcon(currentRole), 26, 26)
            self.currentRoleLabel:SetText(zo_strformat(SI_GROUP_FINDER_SEARCH_RESULTS_CURRENT_ROLE_FORMATTER, GetString(SI_GROUP_FINDER_SEARCH_RESULTS_CURRENT_ROLE_TEXT), roleIcon))
            self.currentRoleLabel:SetHidden(false)

            if isSearchDirty then
                GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
            end
        else
            self.currentRoleLabel:SetHidden(true)
        end
    end
end

function ZO_GroupFinder_SearchPanel_Keyboard:RefreshAppliedToListing()
    if self.appliedToListingData:IsUserTypeActive() then
        self.roleControlPool:ReleaseAllObjects()
        ZO_GroupFinder_Shared.SetUpGroupListingFromData(self.appliedToListingControl, self.roleControlPool, self.appliedToListingData, ZO_GROUP_LISTING_ROLE_CONTROL_PADDING)

        self.appliedToListingControl:SetHidden(false)
    else
        self.appliedToListingControl:SetHidden(true)
    end
end

-- Global XML

function ZO_GroupFinder_SearchResultsListRow_Keyboard_OnInitialized(control)
    ZO_GroupFinder_SearchResultsListRow:New(control)
end

function ZO_GroupFinder_AdditionalFilters_OnClicked(control)
    ZO_Dialogs_ShowDialog("GROUP_FINDER_ADDITIONAL_FILTERS_KEYBOARD")
end

function ZO_GroupFinder_Refresh_OnClicked(control)
    GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
    PlaySound(SOUNDS.GROUP_FINDER_REFRESH_SEARCH)
end

function ZO_GroupFinder_Application_Dialog_Keyboard_OnInitialized(control)
    control.requiredTextFields = ZO_RequiredTextFields:New()
    control.requiredTextFields:AddTextField(control:GetNamedChild("InviteCodeEditBox"))

    ZO_Dialogs_RegisterCustomDialog("GROUP_FINDER_APPLICATION_KEYBOARD",
    {
        title =
        {
            text = function(dialog)
                return dialog.data:DoesGroupAutoAcceptRequests() and SI_GROUP_FINDER_JOIN_DIALOG_TITLE or SI_GROUP_FINDER_APPLY_DIALOG_TITLE
            end,
        },
        mainText =
        {
            text = function(dialog)
                local autoAccept = dialog.data:DoesGroupAutoAcceptRequests()
                local descriptionFormatter = autoAccept and SI_GROUP_FINDER_JOIN_DIALOG_DESCRIPTION_FORMATTER or SI_GROUP_FINDER_APPLY_DIALOG_DESCRIPTION_FORMATTER
                local descriptionText = zo_strformat(descriptionFormatter, ZO_SELECTED_TEXT:Colorize(dialog.data:GetTitle()))

                if IsUnitGrouped("player") then
                    local currentGroupText = autoAccept and GetString(SI_GROUP_FINDER_JOIN_DIALOG_CURRENT_GROUP_TEXT) or GetString(SI_GROUP_FINDER_APPLY_DIALOG_CURRENT_GROUP_TEXT)
                    return ZO_GenerateParagraphSeparatedList({ descriptionText, currentGroupText })
                elseif HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING) then
                    return ZO_GenerateParagraphSeparatedList({ descriptionText, GetString(SI_GROUP_FINDER_APPLY_JOIN_DIALOG_PENDING_APPLICATION_TEXT) })
                else
                    return descriptionText
                end
            end,
        },
        customControl = control,
        setup = function(dialog)
            dialog.requiredTextFields:ClearButtons()

            local inviteCodeHeader = dialog:GetNamedChild("InviteCodeHeader")
            local inviteCodeControl = dialog:GetNamedChild("InviteCodeEdit")
            local inviteCodeEdit = inviteCodeControl:GetNamedChild("Box")

            local optionalMessageControl = dialog:GetNamedChild("OptionalMessage")
            local optionalMessageEdit = optionalMessageControl:GetNamedChild("Edit")

            local requiresInviteCode = dialog.data:DoesGroupRequireInviteCode()
            local isAutoAccept = dialog.data:DoesGroupAutoAcceptRequests()

            --If the listing requires an invite code, do not let the player confirm unless the field has been filled out
            if requiresInviteCode then
                dialog.requiredTextFields:AddButton(dialog:GetNamedChild("Confirm"))
            end

            inviteCodeHeader:SetText(isAutoAccept and GetString(SI_GROUP_FINDER_JOIN_DIALOG_INVITE_CODE_DESCRIPTION_TEXT) or GetString(SI_GROUP_FINDER_APPLY_DIALOG_INVITE_CODE_DESCRIPTION_TEXT))
            inviteCodeEdit:SetText("")
            local SHOW_PASSWORD = false
            ZO_EditBoxKeyboard_SetAsPassword(inviteCodeEdit, SHOW_PASSWORD, inviteCodeEdit:GetNamedChild("TogglePasswordButton"))
            inviteCodeHeader:SetHidden(not requiresInviteCode)
            inviteCodeControl:SetHidden(not requiresInviteCode)
            optionalMessageEdit:SetText("")
            optionalMessageControl:SetHidden(isAutoAccept)
        end,
        buttons =
        {
            -- Confirm Button
            {
                noReleaseOnClick = true,
                control = control:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local data = dialog.data

                    local listingIndex = data:GetListingIndex()
                    local optionalMessage = dialog:GetNamedChild("OptionalMessageEdit"):GetText()
                    
                    local result
                    if data:DoesGroupRequireInviteCode() then
                        local inviteCodeText = dialog:GetNamedChild("InviteCodeEditBox"):GetText()
                        result = RequestApplyToGroupListing(listingIndex, optionalMessage, tonumber(inviteCodeText))
                    else
                        result = RequestApplyToGroupListing(listingIndex, optionalMessage)
                    end

                    --If we failed to send the request, fire an alert
                    if result ~= GROUP_FINDER_ACTION_RESULT_SUCCESS then
                        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, GetString("SI_GROUPFINDERACTIONRESULT", result))
                    end

                    --If the invite code was wrong, leave the dialog open, otherwise close it
                    if result ~= GROUP_FINDER_ACTION_RESULT_FAILED_INCORRECT_INVITE_CODE then
                        ZO_Dialogs_ReleaseDialog("GROUP_FINDER_APPLICATION_KEYBOARD")
                    end
                end,
            },
            -- Cancel Button
            {
                control = control:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end