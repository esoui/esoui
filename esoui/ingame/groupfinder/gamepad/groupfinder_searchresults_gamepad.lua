local GROUP_LISTING_ENTRY = 1

local GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES =
{
    NONE = 1,
    SINGLE_SELECT = 2,
    MULTI_SELECT = 3,
}

---------------------------
-- Search Results Filter --
---------------------------

ZO_GroupFinder_Gamepad_SearchResultsList_Filter = ZO_InitializingObject:Subclass()

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:Initialize(control, isPrimary)
    self.singleSelectDropdownControl = control:GetNamedChild("SingleSelectDropdown")
    self.multiSelectDropdownControl = control:GetNamedChild("MultiSelectDropdown")

    self.singleSelectDropdown = ZO_ComboBox_ObjectFromContainer(self.singleSelectDropdownControl)
    self.singleSelectDropdown:SetSortsItems(false)

    self.multiSelectDropdown = ZO_ComboBox_ObjectFromContainer(self.multiSelectDropdownControl)
    self.multiSelectDropdown:SetSortsItems(false)
    self.multiSelectDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)

    local function IsSelectionBlockedCallback(item)
        if item.value == 1 then
            return true
        end
        return false
    end
    self.multiSelectDropdown:SetIsSelectionBlockedCallback(IsSelectionBlockedCallback)

    local function OnSelectionBlockedCallback(item)
        if item.value == 1 then
            SetGroupFinderFilterSecondaryOptionByIndex(item.value, self.multiSelectDropdown:IsItemSelected(item))
            self.multiSelectDropdown:ClearAllSelections()
            self.multiSelectDropdown:SetItemIndexSelected(item.value)
            self.multiSelectDropdown:RefreshSelections()
            return true
        end
        return false
    end
    self.multiSelectDropdown:SetOnSelectionBlockedCallback(OnSelectionBlockedCallback)

    self.isPrimary = isPrimary
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:GetActiveDropdown()
    if self.dropdownType == GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.SINGLE_SELECT then
        return self.singleSelectDropdown
    elseif self.dropdownType == GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT then
        return self.multiSelectDropdown
    end
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:SetDeactivatedCallback(callback)
    self.singleSelectDropdown:SetDeactivatedCallback(callback)
    self.multiSelectDropdown:SetDeactivatedCallback(callback)
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:SetSelectedColor(color)
    self.singleSelectDropdown:SetSelectedColor(color)
    self.multiSelectDropdown:SetSelectedColor(color)
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:Activate()
    local dropdown = self:GetActiveDropdown()

    if dropdown then
        dropdown:Activate()
    end
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:Deactivate(blockCallback)
    local dropdown = self:GetActiveDropdown()
    if dropdown then
        dropdown:Deactivate(blockCallback)
    end
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:IsActive()
    local dropdown = self:GetActiveDropdown()

    if dropdown then
        return dropdown:IsActive()
    else
        return false
    end
end

do
    internalassert(GROUP_FINDER_CATEGORY_MAX_VALUE == 6, "A Group Finder category has been added. Please add it to the PRIMARY_FILTER_TYPE_BY_CATEGORY and SECONDARY_FILTER_TYPE_BY_CATEGORY tables")
    local PRIMARY_FILTER_TYPE_BY_CATEGORY =
    {
        [GROUP_FINDER_CATEGORY_DUNGEON] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.SINGLE_SELECT,
        [GROUP_FINDER_CATEGORY_ARENA] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.SINGLE_SELECT,
        [GROUP_FINDER_CATEGORY_TRIAL] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.SINGLE_SELECT,
        [GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.NONE,
        [GROUP_FINDER_CATEGORY_PVP] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.SINGLE_SELECT,
        [GROUP_FINDER_CATEGORY_ZONE] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT,
        [GROUP_FINDER_CATEGORY_CUSTOM] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.NONE,
    }

    local SECONDARY_FILTER_TYPE_BY_CATEGORY =
    {
        [GROUP_FINDER_CATEGORY_DUNGEON] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT,
        [GROUP_FINDER_CATEGORY_ARENA] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT,
        [GROUP_FINDER_CATEGORY_TRIAL] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT,
        [GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.NONE,
        [GROUP_FINDER_CATEGORY_PVP] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT,
        [GROUP_FINDER_CATEGORY_ZONE] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT,
        [GROUP_FINDER_CATEGORY_CUSTOM] = GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.NONE,
    }

    function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:SetCategory(category)
        self.category = category
        self.dropdownType = self.isPrimary and PRIMARY_FILTER_TYPE_BY_CATEGORY[self.category] or SECONDARY_FILTER_TYPE_BY_CATEGORY[self.category]
        self:Refresh()
    end
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:Refresh()
    if self.dropdownType == GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.SINGLE_SELECT then
        self.singleSelectDropdownControl:SetHidden(false)
        self.multiSelectDropdownControl:SetHidden(true)

        local defaultText = ""

        local function OnPrimarySelection(dropdown, selectedDataName, selectedData)
            SetGroupFinderFilterPrimaryOptionByIndex(selectedData.value, true)
        end

        local function GetNumPrimaryOptions()
            return GetGroupFinderFilterNumPrimaryOptions()
        end

        ZO_GroupFinder_PopulateOptionsDropdown(self.singleSelectDropdown, GetNumPrimaryOptions, GetGroupFinderFilterPrimaryOptionByIndex, OnPrimarySelection, defaultText)
    elseif self.dropdownType == GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.MULTI_SELECT then
        self.singleSelectDropdownControl:SetHidden(true)
        self.multiSelectDropdownControl:SetHidden(false)

        local optionDropdown = self.multiSelectDropdown
        optionDropdown.dropDownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()

        if self.isPrimary then
            local function OnPrimarySelection(dropdown, selectedDataName, selectedData)
                SetGroupFinderFilterPrimaryOptionByIndex(selectedData.value, dropdown:IsItemSelected(selectedData))
            end

            ZO_GroupFinder_PopulateFiltersPrimaryOptionsDropdown(optionDropdown, OnPrimarySelection)
        else
            local function OnSecondarySelection(dropdown, selectedDataName, selectedData)
                SetGroupFinderFilterSecondaryOptionByIndex(selectedData.value, dropdown:IsItemSelected(selectedData))

                dropdown:ClearAllSelections()
                for i = 1, GetGroupFinderFilterNumSecondaryOptions() do
                    local _, isSet = GetGroupFinderFilterSecondaryOptionByIndex(i)
                    if isSet then
                         dropdown:SetItemIndexSelected(i)
                    end
                end
                dropdown:RefreshSelections()
            end

            ZO_GroupFinder_PopulateFiltersSecondaryOptionsDropdown(optionDropdown, OnSecondarySelection)
        end

        optionDropdown:LoadData(optionDropdown.dropDownData)
    else
        self.singleSelectDropdownControl:SetHidden(true)
        self.multiSelectDropdownControl:SetHidden(true)
    end
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:GetNarrationText()
    local dropdown = self:GetActiveDropdown()
    if dropdown then
        return dropdown:GetNarrationText()
    end
end

function ZO_GroupFinder_Gamepad_SearchResultsList_Filter:CanFocus()
    return self.dropdownType ~= GROUP_FINDER_SEARCH_RESULTS_DROPDOWN_TYPES.NONE
end

------------------------------------------
-- Search Results List Panel Focus Area --
------------------------------------------

ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Panel = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Panel:HandleMovement(horizontalResult, verticalResult)
    if verticalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self.manager:MoveNext()
        return true
    elseif verticalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self.manager:MovePrevious()
        return true
    end
    return false
end

function ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Panel:HandleMovePrevious()
    local consumed = false
    if ZO_ScrollList_AtTopOfList(self.manager.list) then
        consumed = ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
    end
    return consumed
end

function ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Panel:CanBeSelected()
    return self.manager:HasEntries()
end

-----------------------------------
-- Applied To Listing Focus Area --
-----------------------------------

ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_AppliedToListing = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_AppliedToListing:CanBeSelected()
    return HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING)
end

------------------------
-- Filters Focus Area --
------------------------

ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Filters = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Filters:CanBeSelected()
    return self.manager:HasVisibleFilters()
end

--------------------------------------------------------------
-- ZO_GroupFinder_SearchResultsList_Gamepad
--------------------------------------------------------------

ZO_GroupFinder_SearchResultsList_Gamepad = ZO_GamepadInteractiveSortFilterList:Subclass()

function ZO_GroupFinder_SearchResultsList_Gamepad:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    
    self.masterList = {}

    local NO_HIDE_CALLBACK = nil
    local NO_SELECT_SOUND = nil
    local listControl = self:GetListControl()
    ZO_ScrollList_AddDataType(listControl, GROUP_LISTING_ENTRY, "ZO_GroupFinder_GroupListing_Gamepad", ZO_GROUP_LISTING_GAMEPAD_HEIGHT, function(...) self:SetupRow(...) end, NO_HIDE_CALLBACK, NO_SELECT_SOUND, function(...) self:ResetRow(...) end)

    self.roleControlPool = ZO_ControlPool:New("ZO_GroupFinder_RoleIconTemplate_Gamepad", listControl)
    self.loadingIcon = self.container:GetNamedChild("LoadingIcon")

    self:InitializeAppliedToListing()
    self:RefreshSearchState()
    self:InitializeApplyDialog()
    self:InitializeFooter()
end

function ZO_GroupFinder_SearchResultsList_Gamepad:InitializeAppliedToListing()
    self.appliedToListingControl = self.container:GetNamedChild("AppliedToListingContainerAppliedToListing")
    self.appliedToListingRoleControlPool = ZO_ControlPool:New("ZO_GroupFinder_RoleIconTemplate_Gamepad", self.appliedToListingControl, "Role")

    --Create the data object
    self.appliedToListingData = ZO_GroupListingUserTypeData:New(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING)

    --Use MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL instead of vertical so it doesn't interfere with the directional input for the screen as a whole
    self.appliedToListingFocus = ZO_GamepadFocus:New(self.appliedToListingControl, ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL))
    local appliedToListingFocusEntry = 
    {
        activate = function()
            self:RefreshSelectedTooltip()
            SCREEN_NARRATION_MANAGER:QueueFocus(self.appliedToListingFocus)
        end,
        deactivate = function()
            self:RefreshSelectedTooltip()
        end,
        narrationText = function()
            --TODO GroupFinder: Include any status icons in the narration
            return self:GetEmptyRowNarration()
        end,
        headerNarrationFunction = function()
            return self:GetHeaderNarration()
        end,
        footerNarrationFunction = function()
            return self:GetFooterNarration()
        end,
        canFocus = function() return not self.appliedToListingControl:IsHidden() end,
        highlight = self.appliedToListingControl:GetNamedChild("Highlight")
    }
    self.appliedToListingFocus:AddEntry(appliedToListingFocusEntry)
end

function ZO_GroupFinder_SearchResultsList_Gamepad:InitializeApplyDialog()
    ZO_Dialogs_RegisterCustomDialog("GROUP_FINDER_APPLICATION_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
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
                return descriptionText
            end,
        },
        warning =
        {
            text = function(dialog)
                local autoAccept = dialog.data:DoesGroupAutoAcceptRequests()
                if IsUnitGrouped("player") then
                    local currentGroupText = autoAccept and GetString(SI_GROUP_FINDER_JOIN_DIALOG_CURRENT_GROUP_TEXT) or GetString(SI_GROUP_FINDER_APPLY_DIALOG_CURRENT_GROUP_TEXT)
                    return currentGroupText
                elseif HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING) then
                    return GetString(SI_GROUP_FINDER_APPLY_JOIN_DIALOG_PENDING_APPLICATION_TEXT)
                else
                    return ""
                end
            end
        },
        setup = function(dialog)
            --Reset the invite code and optional message when opening the dialog
            self.inviteCodeText = ""
            self.showInviteCode = true
            self.optionalMessage = ""
            dialog:setupFunc()
        end,
        parametricList =
        {
            {
                template = "ZO_GroupFinder_InviteCode_EditBox_Gamepad",
                templateData =
                {
                    textChangedCallback = function(control)
                        local inviteCodeText = control:GetText()
                        self.inviteCodeText = inviteCodeText
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        data.control = control

                        control.editBoxControl:SetText(self.inviteCodeText)
                        control.editBoxControl:SetAsPassword(not self.showInviteCode)
                        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                    end,
                    visible = function(dialog)
                        local listingData = dialog.data
                        if listingData then
                            return listingData:DoesGroupRequireInviteCode()
                        end
                        return false
                    end,
                    tooltipText = function(dialog)
                        local listingData = dialog.data
                        if listingData then
                            return listingData:DoesGroupAutoAcceptRequests() and GetString(SI_GROUP_FINDER_JOIN_DIALOG_INVITE_CODE_DESCRIPTION_TEXT) or GetString(SI_GROUP_FINDER_APPLY_DIALOG_INVITE_CODE_DESCRIPTION_TEXT)
                        end
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    togglePasswordCallback = function(dialog)
                        self.showInviteCode = not self.showInviteCode
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:SetAsPassword(not self.showInviteCode)
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                },
            },
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                templateData = 
                {
                    textChangedCallback = function(control)
                        local optionalMessage = control:GetText()
                        self.optionalMessage = optionalMessage
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        data.control = control

                        control.editBoxControl:SetDefaultText(GetString(SI_GROUP_FINDER_APPLY_DIALOG_OPTIONAL_MESSAGE_DEFAULT_TEXT))
                        control.editBoxControl:SetMaxInputChars(GROUP_FINDER_GROUP_LISTING_APPLICATION_MESSAGE_MAX_LENGTH)

                        control.editBoxControl:SetText(self.optionalMessage)
                    end,
                    visible = function(dialog)
                        local listingData = dialog.data
                        if listingData then
                            return not listingData:DoesGroupAutoAcceptRequests()
                        end
                        return false
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData =
                {
                    finishedSelector = true,
                    text = GetString(SI_DIALOG_CONFIRM),
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local isValid = enabled
                        if data.validInput then
                            isValid = data.validInput(data.dialog)
                            data.disabled = not isValid
                            data:SetEnabled(isValid)
                        end

                        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, isValid, active)
                    end,
                    validInput = function(dialog)
                        local listingData = dialog.data
                        --If the listing requires an invite code, make sure the field has been filled out
                        if listingData and listingData:DoesGroupRequireInviteCode() then
                            return self.inviteCodeText ~= ""
                        end
                        return true
                    end,
                    tooltipText = function(dialog)
                        local listingData = dialog.data
                        if listingData and listingData:DoesGroupRequireInviteCode() and self.inviteCodeText == "" then
                            return ZO_ERROR_COLOR:Colorize(GetString(SI_GAMEPAD_GROUP_FINDER_APPLY_JOIN_DIALOG_INVITE_CODE_REQUIRED_TOOLTIP))
                        end
                    end,
                    callback = function(dialog)
                        local data = dialog.data
                        local listingIndex = data:GetListingIndex()
                        
                        local result
                        if data:DoesGroupRequireInviteCode() then
                            result = RequestApplyToGroupListing(listingIndex, self.optionalMessage, tonumber(self.inviteCodeText))
                        else
                            result = RequestApplyToGroupListing(listingIndex, self.optionalMessage)
                        end

                        --If we failed to send the request, fire an alert
                        if result ~= GROUP_FINDER_ACTION_RESULT_SUCCESS then
                            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, GetString("SI_GROUPFINDERACTIONRESULT", result))
                        end

                        --If the invite code was wrong, leave the dialog open, otherwise close it
                        if result ~= GROUP_FINDER_ACTION_RESULT_FAILED_INCORRECT_INVITE_CODE then
                            ZO_Dialogs_ReleaseDialogOnButtonPress("GROUP_FINDER_APPLICATION_GAMEPAD")
                        end
                    end,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                },
            },
        },
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            local tooltipText
            if newSelectedData and newSelectedData.tooltipText then
                tooltipText = newSelectedData.tooltipText(dialog)
            end

            if tooltipText then
                GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, tooltipText)
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(dialog)
            end
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    data.callback(dialog)
                end,
                enabled = function(dialog)
                    local selectedData = dialog.entryList:GetTargetData()
                    local enabled = true
                    if selectedData.finishedSelector then
                        local listingData = dialog.data
                        if listingData and listingData:DoesGroupRequireInviteCode() then
                            enabled = self.inviteCodeText ~= ""
                        end
                    end
                    return enabled
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = function()
                    return self.showInviteCode and GetString(SI_EDIT_BOX_HIDE_PASSWORD) or GetString(SI_EDIT_BOX_SHOW_PASSWORD)
                end,
                callback = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    data.togglePasswordCallback(dialog)
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    --Re-narrate since keybind will have changed
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end,
                visible = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    if data and data.togglePasswordCallback then
                        return true
                    end

                    return false
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GROUP_FINDER_APPLICATION_GAMEPAD")
                end,
            },
        }
    })
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:SetupFilterFocusArea()
    --Setup the focus area for the dropdown filters
    local function FiltersActivateCallback()
        self.filterSwitcher:Activate()
    end

    local function FiltersDeactivateCallback()
        self.filterSwitcher:Deactivate()
    end
    self.filtersFocalArea = ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Filters:New(self, FiltersActivateCallback, FiltersDeactivateCallback)
    self:AddNextFocusArea(self.filtersFocalArea)
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:SetupPanelFocusArea()
    --Setup the focus area for the results list
    local function PanelActivateCallback()
        local ANIMATE_INSTANTLY = true
        ZO_ScrollList_AutoSelectData(self.list, ANIMATE_INSTANTLY)
        SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self)
    end

    local function PanelDeactivateCallback()
        self:DeselectListData()
    end
    self.panelFocalArea = ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_Panel:New(self, PanelActivateCallback, PanelDeactivateCallback)

    self:AddNextFocusArea(self.panelFocalArea)
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:SetupFoci()
    --Order matters. These are called in the order we want them to be navigated in
    self:SetupFilterFocusArea()
    self:SetupAppliedToListingFocusArea()
    self:SetupPanelFocusArea()
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:InitializeHeader()
    local contentHeaderData =
    {
        titleTextAlignment = TEXT_ALIGN_CENTER,
        titleText = function()
            local category = GetGroupFinderFilterCategory()
            return zo_strformat(SI_GAMEPAD_GROUP_FINDER_LISTINGS_TITLE, GetString("SI_GROUPFINDERCATEGORY", category))
        end,
    }
    ZO_GamepadInteractiveSortFilterList.InitializeHeader(self, contentHeaderData)
end

function ZO_GroupFinder_SearchResultsList_Gamepad:InitializeFooter()
    local function GetRoleIcon()
        if DoesGroupFinderFilterRequireEnforceRoles() then
            local currentRole = GetSelectedLFGRole()
            return zo_iconFormat(ZO_GetGamepadRoleIcon(currentRole))
        else
            return zo_iconFormat("EsoUI/Art/LFG/LFG_any_down_no_glow_64.dds", "100%", "100%")
        end
    end

    local function GetRoleNarration()
        if DoesGroupFinderFilterRequireEnforceRoles() then
            local currentRole = GetSelectedLFGRole()
            return GetString("SI_LFGROLE", currentRole)
        else
            return GetString(SI_GROUP_FINDER_ROLE_ANY)
        end
    end

    self.footerData =
    {
        data1HeaderText = GetString(SI_GROUP_FINDER_SEARCH_RESULTS_CURRENT_ROLE_TEXT),
        data1Text = GetRoleIcon,
        data1TextNarration = GetRoleNarration
    }
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:InitializeFilters()
    self.filterSwitcher = ZO_GamepadFocus:New(self.contentHeader, ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL))

    local function LeftDropdownDeactivatedCallback()
        self.filterSwitcher:Activate()
        self.filterRight:Refresh()
        GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
    end

    local function RightDropdownDeactivatedCallback()
        self.filterSwitcher:Activate()
        GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
    end

    --Setup the focus for the left dropdown
    local IS_PRIMARY = true
    self.filterLeftControl = self.contentHeader:GetNamedChild("FilterLeft")
    self.filterLeft = ZO_GroupFinder_Gamepad_SearchResultsList_Filter:New(self.filterLeftControl, IS_PRIMARY)
    self.filterLeft:SetDeactivatedCallback(LeftDropdownDeactivatedCallback)
    self.filterLeft:SetSelectedColor(ZO_DISABLED_TEXT)

    local leftFilterData =
    {
        callback = function()
            self.filterSwitcher:Deactivate()
            self.filterLeft:Activate()
        end,
        activate = function()
            self.filterLeft:SetSelectedColor(ZO_SELECTED_TEXT)
            SCREEN_NARRATION_MANAGER:QueueFocus(self.filterSwitcher)
        end,
        deactivate = function()
            self.filterLeft:SetSelectedColor(ZO_DISABLED_TEXT)
        end,
        narrationText = function()
            local narrations = {}
            ZO_AppendNarration(narrations, self.filterLeft:GetNarrationText())
            ZO_AppendNarration(narrations, self:GetEmptyRowNarration())
            return narrations
        end,
        headerNarrationFunction = function()
            return self:GetHeaderNarration()
        end,
        footerNarrationFunction = function()
            return self:GetFooterNarration()
        end,
        highlight = self.filterLeftControl:GetNamedChild("Highlight"),
        canFocus = function() return self.filterLeft:CanFocus() end,
    }
    self.filterSwitcher:AddEntry(leftFilterData)

    --Setup the focus for the right dropdown
    local IS_SECONDARY = false
    self.filterRightControl = self.contentHeader:GetNamedChild("FilterRight")
    self.filterRight = ZO_GroupFinder_Gamepad_SearchResultsList_Filter:New(self.filterRightControl, IS_SECONDARY)
    self.filterRight:SetDeactivatedCallback(RightDropdownDeactivatedCallback)
    self.filterRight:SetSelectedColor(ZO_DISABLED_TEXT)

    local rightFilterData =
    {
        callback = function()
            self.filterSwitcher:Deactivate()
            self.filterRight:Activate()
        end,
        activate = function()
            self.filterRight:SetSelectedColor(ZO_SELECTED_TEXT)
            SCREEN_NARRATION_MANAGER:QueueFocus(self.filterSwitcher)
        end,
        deactivate = function()
            self.filterRight:SetSelectedColor(ZO_DISABLED_TEXT)
        end,
        narrationText = function()
            local narrations = {}
            ZO_AppendNarration(narrations, self.filterRight:GetNarrationText())
            ZO_AppendNarration(narrations, self:GetEmptyRowNarration())
            return narrations
        end,
        headerNarrationFunction = function()
            return self:GetHeaderNarration()
        end,
        footerNarrationFunction = function()
            return self:GetFooterNarration()
        end,
        highlight = self.filterRightControl:GetNamedChild("Highlight"),
        canFocus = function() return self.filterRight:CanFocus() end,
    }
    self.filterSwitcher:AddEntry(rightFilterData)
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Apply to Listing
        {
            name = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return selectedData:DoesGroupAutoAcceptRequests() and GetString(SI_GROUP_FINDER_JOIN_KEYBIND) or GetString(SI_GROUP_FINDER_APPLY_KEYBIND)
                end
                return ""
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self:GetSelectedData() ~= nil
            end,
            enabled = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local joinabilityResult = selectedData:GetJoinabilityResult()
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
                local selectedData = self:GetSelectedData()
                if selectedData then
                    --If the user is missing a required collectible, show a dialog for that instead
                    if selectedData:GetJoinabilityResult() == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT then
                        local collectibleId = selectedData:GetFirstLockingCollectibleId()
                        if collectibleId ~= 0 then
                            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                            local collectibleName = collectibleData:GetName()
                            local categoryName = collectibleData:GetCategoryData():GetName()
                            local message = zo_strformat(SI_GROUP_FINDER_APPLY_JOIN_DIALOG_COLLECTIBLE_LOCKED_FAILURE, ZO_SELECTED_TEXT:Colorize(selectedData:GetTitle()))
                            local marketOperation = MARKET_OPEN_OPERATION_GROUP_FINDER
                            ZO_Dialogs_ShowPlatformDialog("COLLECTIBLE_REQUIREMENT_FAILED", { collectibleData = collectibleData, marketOpenOperation = marketOperation }, { mainTextParams = { message, collectibleName, categoryName } })
                        end
                    else
                        ZO_Dialogs_ShowPlatformDialog("GROUP_FINDER_APPLICATION_GAMEPAD", selectedData)
                    end
                end
            end,
        },
        -- Ignore
        {
            name = GetString(SI_FRIEND_MENU_IGNORE),
            keybind = "UI_SHORTCUT_QUATERNARY",
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return not IsIgnored(selectedData:GetOwnerDisplayName())
                end
                return false
            end,
            callback = function()
                local selectedData = self:GetSelectedData()
                ZO_PlatformIgnorePlayer(selectedData:GetOwnerDisplayName())
            end,
        },
        -- Report Listing
        {
            name = GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            visible = function()
                return self:GetSelectedData() ~= nil
            end,
            callback = function()
                local selectedData = self:GetSelectedData()
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(selectedData)
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())

    local appliedToListingKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Rescind
        {
            name = GetString(SI_GROUP_FINDER_RESCIND_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_RESCIND)
            end,
        },
        -- Ignore
        {
            name = GetString(SI_FRIEND_MENU_IGNORE),
            keybind = "UI_SHORTCUT_QUATERNARY",
            visible = function()
                return not IsIgnored(self.appliedToListingData:GetOwnerDisplayName())
            end,
            callback = function()
                ZO_PlatformIgnorePlayer(self.appliedToListingData:GetOwnerDisplayName())
            end,
        },
        -- Report Listing
        {
            name = GetString(SI_GROUP_FINDER_REPORT_GROUP_LISTING_KEYBIND),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGroupFinderListingTicketScene(self.appliedToListingData)
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(appliedToListingKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())
    self.appliedToListingArea:SetKeybindDescriptor(appliedToListingKeybindStripDescriptor)

    --Order matters: We need to do this before we add the universal keybinds below, but after we have defined self.keybindStripDescriptor
    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)

    --Add keybinds that are not focus area dependent

    --Refresh Search
    local refreshKeybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_GROUP_FINDER_SEARCH_RESULTS_REFRESH_KEYBIND),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
        end,
        sound = SOUNDS.GROUP_FINDER_REFRESH_SEARCH
    }
    self:AddUniversalKeybind(refreshKeybind)

    --Filters dialog
    local filtersKeybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_GROUP_FINDER_FILTERS_KEYBIND),
        keybind = "UI_SHORTCUT_TERTIARY",
        callback = function()
            ZO_GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD:ShowDialog()
        end,
    }
    self:AddUniversalKeybind(filtersKeybind)
end

function ZO_GroupFinder_SearchResultsList_Gamepad:HasVisibleFilters()
    return self.filterLeft:CanFocus() or self.filterRight:CanFocus()
end

function ZO_GroupFinder_SearchResultsList_Gamepad:SetupAppliedToListingFocusArea()
    --Setup the focus area for the applied to listing
    local function AppliedToListingActivateCallback()
        self.appliedToListingFocus:Activate()
    end

    local function AppliedToListingDeactivateCallback()
        self.appliedToListingFocus:Deactivate()
    end
   
   self.appliedToListingArea = ZO_GroupFinder_SearchResultsList_Gamepad_FocusArea_AppliedToListing:New(self, AppliedToListingActivateCallback, AppliedToListingDeactivateCallback)

    self:AddNextFocusArea(self.appliedToListingArea)
end

function ZO_GroupFinder_SearchResultsList_Gamepad:RefreshAppliedToListing(autoSelectApplication)
    self.appliedToListingRoleControlPool:ReleaseAllObjects()
    if self.appliedToListingData:IsUserTypeActive() then
        ZO_GroupFinder_Shared.SetUpGroupListingFromData(self.appliedToListingControl, self.appliedToListingRoleControlPool, self.appliedToListingData, ZO_GROUP_LISTING_ROLE_CONTROL_PADDING_GAMEPAD)
        self.appliedToListingControl:SetHidden(false)
        if autoSelectApplication then
            self:ActivateFocusArea(self.appliedToListingArea)
        end
    else
        self.appliedToListingControl:SetHidden(true)
        if self:IsAppliedToListingFocused() and self.isActive then
            --If the applied to listing is currently focused, we need to change focus to something else when it hides
            self:ActivateFocusArea(self:GetHighestPriorityFocusArea())
        end
    end
end

function ZO_GroupFinder_SearchResultsList_Gamepad:RefreshCategory()
    --Update the filter categories
    local category = GetGroupFinderFilterCategory()
    self.filterLeft:SetCategory(category)
    self.filterRight:SetCategory(category)

    --Refresh the header
    self:RefreshHeader()

    --If the filters are currently focused we need to change focus to something else if our new category hides them
    if not self:HasVisibleFilters() and self:AreFiltersFocused() and self.isActive then
        self:ActivateFocusArea(self:GetHighestPriorityFocusArea())
    end
end

function ZO_GroupFinder_SearchResultsList_Gamepad:RefreshFooter()
    if DoesGroupFinderFilterRequireEnforceRoles() then
        SCENE_MANAGER:AddFragment(GAMEPAD_GENERIC_FOOTER_FRAGMENT)
        GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
    else
        SCENE_MANAGER:RemoveFragment(GAMEPAD_GENERIC_FOOTER_FRAGMENT)
    end
end

function ZO_GroupFinder_SearchResultsList_Gamepad:RefreshSelectedTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    local selectedData
    if self:IsPanelFocused() then
        selectedData = self:GetSelectedData()
    elseif self:IsAppliedToListingFocused() then
        selectedData = self.appliedToListingData
    end

    if selectedData then
        GAMEPAD_TOOLTIPS:LayoutGroupFinderGroupListingTooltip(GAMEPAD_RIGHT_TOOLTIP, selectedData)
    end
end

function ZO_GroupFinder_SearchResultsList_Gamepad:SetupRow(control, data)
    ZO_GroupFinder_Shared.SetUpGroupListingFromData(control, self.roleControlPool, data, ZO_GROUP_LISTING_ROLE_CONTROL_PADDING_GAMEPAD)
end

function ZO_GroupFinder_SearchResultsList_Gamepad:ResetRow(control)
    ZO_ObjectPool_DefaultResetControl(control)
    ZO_GroupFinder_Shared.ResetRoleControls(control, self.roleControlPool)
end

--Returns the highest priority focus area that can be selected.
function ZO_GroupFinder_SearchResultsList_Gamepad:GetHighestPriorityFocusArea()
    if self:HasVisibleFilters() then
        --If the filters can be focused, return that
        return self.filtersFocalArea
    elseif self.appliedToListingData:IsUserTypeActive() then
        --If the applied to listing can be focused, return that
        return self.appliedToListingArea
    end

    --If none of the higher priority focus areas were able to be focused, just default to the list
    return self.panelFocalArea
end

function ZO_GroupFinder_SearchResultsList_Gamepad:IsAppliedToListingFocused()
    return self:IsCurrentFocusArea(self.appliedToListingArea)
end

function ZO_GroupFinder_SearchResultsList_Gamepad:RefreshSearchState()
    local currentSearchState = GROUP_FINDER_SEARCH_MANAGER:GetSearchState()
    if currentSearchState == ZO_GROUP_FINDER_SEARCH_STATES.WAITING or currentSearchState == ZO_GROUP_FINDER_SEARCH_STATES.QUEUED then
        self:SetEmptyText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_REFRESHING_RESULTS))
        self.loadingIcon:SetHidden(false)
    else
        self:SetEmptyText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_EMPTY_TEXT))
        self.loadingIcon:SetHidden(true)
    end
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:AddUniversalKeybind(keybind)
    self.panelFocalArea:AppendKeybind(keybind)
    self.filtersFocalArea:AppendKeybind(keybind)
    self.appliedToListingArea:AppendKeybind(keybind)
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:GetBackKeybindCallback()
    return function() 
        GROUP_FINDER_GAMEPAD:SetMode(ZO_GROUP_FINDER_MODES.SEARCH)
        SCENE_MANAGER:HideCurrentScene()
    end
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:OnAllDialogsHidden()
    --Re-narrate the current focus upon closing dialogs
    if self:IsActivated() then
        local NARRATE_HEADER = true
        --Determine if we need to narrate the filter switcher, applied to listing, or list entry
        if self:AreFiltersFocused() then
            SCREEN_NARRATION_MANAGER:QueueFocus(self.filterSwitcher, NARRATE_HEADER)
        elseif self:IsAppliedToListingFocused() then
            SCREEN_NARRATION_MANAGER:QueueFocus(self.appliedToListingFocus, NARRATE_HEADER)
        elseif self:IsPanelFocused() then
            SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self, NARRATE_HEADER)
        end
    end
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:OnShowing()
    --Refresh the category, list, and applied to listing
    self:RefreshCategory()
    self:RefreshData()
    self:RefreshAppliedToListing()
    self:RefreshFooter()

    self:Activate()

    RequestSetGroupFinderExpectingUpdates(true)
end

function ZO_GroupFinder_SearchResultsList_Gamepad:OnHiding()
    ZO_GamepadInteractiveSortFilterList.OnHiding(self)

    RequestSetGroupFinderExpectingUpdates(false)
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:Activate()
    self:SetDirectionalInputEnabled(true)

    --Activate the highest priority focus area
    local activeFocus = self:GetHighestPriorityFocusArea()
    if not activeFocus then
        self:Deactivate()
    else
        self:ActivateFocusArea(activeFocus)
        self.isActive = true
        ZO_GamepadOnDefaultActivatedChanged(self.list, self.isActive)

        --Determine what we need to narrate
        local NARRATE_HEADER = true
        if self:IsPanelFocused() then
            SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self, NARRATE_HEADER)
        elseif self:IsAppliedToListingFocused() then
            SCREEN_NARRATION_MANAGER:QueueFocus(self.appliedToListingFocus, NARRATE_HEADER)
        elseif self:AreFiltersFocused() then
            SCREEN_NARRATION_MANAGER:QueueFocus(self.filterSwitcher, NARRATE_HEADER)
        end
    end
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:Deactivate()
    self:SetDirectionalInputEnabled(false)

    --If any of the filters were active, deactivate them
    if self.filterLeft:IsActive() then
        local SUPPRESS_CALLBACK = true
        self.filterLeft:Deactivate(SUPPRESS_CALLBACK)
    end

    if self.filterRight:IsActive() then
        local SUPPRESS_CALLBACK = true
        self.filterRight:Deactivate(SUPPRESS_CALLBACK)
    end

    self:ActivateFocusArea(nil)
    self.isActive = false
    ZO_GamepadOnDefaultActivatedChanged(self.list, self.isActive)
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:BuildMasterList()
    self.masterList = GROUP_FINDER_SEARCH_MANAGER:GetSearchResults()
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.masterList) do
        --Filter out listings that you are currently applied to
        if not data:IsActiveApplication() then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GROUP_LISTING_ENTRY, ZO_EntryData:New(data)))
        end
    end

    self:RefreshSearchState()
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:CommitScrollList()
    ZO_SortFilterList.CommitScrollList(self)

    if self:IsPanelFocused() and self.isActive then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        if #scrollData == 0 then
            --If the cursor is in the list, but the list is empty because of a filter, attempt to select something else
            self:ActivateFocusArea(self:GetHighestPriorityFocusArea())
        else
            local ANIMATE_INSTANTLY = true
            local selectedData = ZO_ScrollList_GetSelectedData(self.list)
            if selectedData then
                -- Make sure our selection is in view
                local NO_CALLBACK = nil
                ZO_ScrollList_ScrollDataIntoView(self.list, ZO_ScrollList_GetSelectedDataIndex(self.list), NO_CALLBACK, ANIMATE_INSTANTLY)
            else
                -- If we've lost our selection and the panelFocalArea is active, then we want to
                -- AutoSelect the next appropriate entry
                ZO_ScrollList_AutoSelectData(self.list, ANIMATE_INSTANTLY)
            end
        end
    end
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.OnSelectionChanged(self, oldData, newData)
    self:RefreshSelectedTooltip()
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:GetNarrationText()
    --TODO GroupFinder: Include disabled state + any status icons in the narration
    return self:GetEmptyRowNarration()
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:GetEmptyRowNarration()
    --Intentionally use the ZO_SortFilterList_Gamepad's version instead of the ZO_GamepadInteractiveSortFilterList's version
    return ZO_SortFilterList_Gamepad.GetEmptyRowNarration(self)
end

--Overridden from base
function ZO_GroupFinder_SearchResultsList_Gamepad:GetFooterNarration()
    if GAMEPAD_GENERIC_FOOTER_FRAGMENT:IsShowing() then
        return GAMEPAD_GENERIC_FOOTER:GetNarrationText(self.footerData)
    end
end

---------------------------------
-- Search Results List Screen ---
---------------------------------

ZO_GroupFinder_SearchResultsListScreen_Gamepad = ZO_InitializingObject:Subclass()

function ZO_GroupFinder_SearchResultsListScreen_Gamepad:Initialize(control)
    self.control = control
    self:InitializeScene()
    self:RegisterForEvents()
    self.resultsList = ZO_GroupFinder_SearchResultsList_Gamepad:New(self.control)
    self.scene:AddFragment(self.resultsList:GetListFragment())
end

function ZO_GroupFinder_SearchResultsListScreen_Gamepad:InitializeScene()
    self.scene = ZO_Scene:New("group_finder_gamepad_list", SCENE_MANAGER)
    GROUP_FINDER_GAMEPAD_LIST_SCENE = self.scene
end

function ZO_GroupFinder_SearchResultsListScreen_Gamepad:RegisterForEvents()
    --If we got new search results, rebuild the list
    GROUP_FINDER_SEARCH_MANAGER:RegisterCallback("OnGroupFinderSearchResultsReady", function()
        if self.scene:IsShowing() then
            self.resultsList:RefreshData()
            self.resultsList:UpdateKeybinds()
        end
    end)

    --If the current search results updated, refresh the visible entries and update the tooltip
    GROUP_FINDER_SEARCH_MANAGER:RegisterCallback("OnGroupFinderSearchResultsUpdated", function()
        if self.scene:IsShowing() then
            self.resultsList:RefreshVisible()
            self.resultsList:RefreshAppliedToListing()
            self.resultsList:RefreshSelectedTooltip()
            self.resultsList:UpdateKeybinds()
        end
    end)

    --If the search state changed, rebuild the list
    GROUP_FINDER_SEARCH_MANAGER:RegisterCallback("OnSearchStateChanged", function(newState)
        if self.scene:IsShowing() then
            self.resultsList:RefreshData()
            self.resultsList:UpdateKeybinds()
        end
    end)

    local function OnRefreshApplication(autoSelectApplication)
        if self.scene:IsShowing() then
            -- Cancel application if pending application was accepted and player is now grouped
            if IsUnitGrouped("player") then
                ZO_Dialogs_ReleaseDialog("GROUP_FINDER_APPLICATION_GAMEPAD")
            end
            self.resultsList:RefreshFilters()
            self.resultsList:RefreshAppliedToListing(autoSelectApplication)
            self.resultsList:RefreshSelectedTooltip()
            self.resultsList:UpdateKeybinds()
        end
    end

    local function OnRefreshNewApplication()
        local AUTO_SELECT_APPLICATION = true
        OnRefreshApplication(AUTO_SELECT_APPLICATION)
    end

    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Gamepad", EVENT_GROUP_FINDER_APPLY_TO_GROUP_LISTING_RESULT, OnRefreshNewApplication)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Gamepad", EVENT_GROUP_FINDER_RESOLVE_GROUP_LISTING_APPLICATION_RESULT, OnRefreshApplication)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Gamepad", EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_APPLICATION, OnRefreshApplication)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_SearchResults_Gamepad", EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_APPLICATION, OnRefreshApplication)
end

function ZO_GroupFinder_SearchResultsListScreen_Gamepad:RefreshCategory()
    if self.scene:IsShowing() then
        self.resultsList:RefreshCategory()
    end
end

function ZO_GroupFinder_SearchResultsListScreen_Gamepad:RefreshFooter()
    if self.scene:IsShowing() then
        self.resultsList:RefreshFooter()
    end
end

function ZO_GroupFinder_SearchResultsListScreen_Gamepad.OnControlInitialized(control)
    GROUP_FINDER_SEARCH_RESULTS_LIST_SCREEN_GAMEPAD = ZO_GroupFinder_SearchResultsListScreen_Gamepad:New(control)
end