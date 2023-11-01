--------------------------------------------------------------
-- ZO_GroupFinder_AdditionalFilters_Gamepad
--------------------------------------------------------------

ZO_GroupFinder_AdditionalFilters_Gamepad = ZO_GroupFinder_AdditionalFilters_Shared:Subclass()

function ZO_GroupFinder_AdditionalFilters_Gamepad:Initialize()
    ZO_GroupFinder_AdditionalFilters_Shared.Initialize(self)
    self:InitializeFiltersDialog()
end

function ZO_GroupFinder_AdditionalFilters_Gamepad:InitializeFiltersDialog()
    local function setupFunction(dialog)
        ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GROUP_FINDER_FILTERS_TITLE))
        if not dialog.dropdowns then
            dialog.dropdowns = {}
        end
        dialog:setupFunc()
    end

    local function OnReleaseDialog(dialog)
        if dialog.dropdowns then
            for _, dropdown in ipairs(dialog.dropdowns) do
                dropdown:Deactivate()
            end
        end
        dialog.dropdowns = nil
    end

    ZO_Dialogs_RegisterCustomDialog("GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = setupFunction,
        finishedCallback = function()
            GROUP_FINDER_SEARCH_RESULTS_LIST_SCREEN_GAMEPAD:RefreshCategory()
        end,
        parametricList = self:BuildFiltersList(),
        blockDialogReleaseOnPress = true,
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
                enabled = function(dialog)
                    local enabled = true
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        if type(targetData.enabled) == "function" then
                            enabled = targetData.enabled(dialog)
                        else
                            enabled = targetData.enabled
                        end
                    end
                    return enabled
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    CancelGroupFinderFilterOptionsChanges()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD")
                    GROUP_FINDER_SEARCH_RESULTS_LIST_SCREEN_GAMEPAD:RefreshFooter()
                    GROUP_FINDER_SEARCH_MANAGER:ExecuteSearch()
                end,
            },
            {
                keybind = "DIALOG_RESET",
                text = SI_GROUP_FINDER_FILTERS_RESET,
                enabled = function(dialog)
                    -- TODO GroupFinder: Check to see if filters are already default
                    return true
                end,
                callback = function(dialog)
                    ResetGroupFinderFilterOptionsToDefault()
                    self:Refresh()
                    -- Re-narrate the selection when the filters are reset
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    dialog.info.setup(dialog)
                end,
            },
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })
end

function ZO_GroupFinder_AdditionalFilters_Gamepad:ShowDialog()
    ZO_Dialogs_ShowGamepadDialog("GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD")
end

function ZO_GroupFinder_AdditionalFilters_Gamepad:OnSecondarySelection(dropdown, selectedDataName, selectedData)
    ZO_GroupFinder_AdditionalFilters_Shared.OnSecondarySelection(self, dropdown, selectedDataName, selectedData)

    dropdown:ClearAllSelections()
    for i = 1, GetGroupFinderFilterNumSecondaryOptions() do
        local _, isSet = GetGroupFinderFilterSecondaryOptionByIndex(i)
        if isSet then
            dropdown:SetItemIndexSelected(i)
        end
    end
    dropdown:RefreshSelections()
end

function ZO_GroupFinder_AdditionalFilters_Gamepad:Refresh()
    local IGNORE_CALLBACK = true
    local category = GetGroupFinderFilterCategory()
    local categoryIndex = category + 1 -- Category Enum starts at 0 so index will always be one greater than value.

    if self.categoryDropdown then
        self.categoryDropdown:SelectItemByIndex(categoryIndex, IGNORE_CALLBACK)
    end

    UpdateGroupFinderFilterOptions()

    -- We can't guarantee these will stay the same when we rebuild the list, so clear them out to avoid
    -- cross-contamination.
    self.categoryDropdown = nil
    self.primaryOptionDropdownSingleSelect = nil
    self.primaryOptionDropdown = nil
    self.secondaryOptionDropdown = nil
    self.sizeDropdown = nil
    self.playstyleDropdown = nil
    self.championCheckbox = nil
    self.voipCheckbox = nil
    self.inviteCodeCheckbox = nil
    self.autoAcceptCheckbox = nil
    self.ownRoleOnlyCheckbox = nil

    local dialog = ZO_Dialogs_FindDialog("GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD")
    if dialog then
        local RESELECT_ENTRY = true
        local DONT_LIMIT_NUM_ENTRIES = nil
        ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, DONT_LIMIT_NUM_ENTRIES, RESELECT_ENTRY)
    end
end

function ZO_GroupFinder_AdditionalFilters_Gamepad:BuildFiltersList()
    local parametricList = {}

    local textSearch =
    {
        template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
        header = GetString(SI_GROUP_FINDER_FILTERS_SEARCH),

        templateData =
        {
            focusLostCallback = function(control)
                SetGroupFinderGroupFilterSearchString(control:GetText())
            end,
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.highlight:SetHidden(not selected)
                control.editBoxControl:SetMaxInputChars(GROUP_FINDER_GROUP_LISTING_TITLE_MAX_LENGTH)
                control.editBoxControl:SetDefaultText(GetString(SI_GROUP_FINDER_FILTERS_SEARCH))
                control.editBoxControl:SetText(GetGroupFinderGroupFilterSearchString())
                control.editBoxControl.focusLostCallback = data.focusLostCallback
                data.control = control
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                if targetData then
                    local editControl = targetData.control.editBoxControl

                    editControl:TakeFocus()
                end
            end,
            narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
        }
    }
    table.insert(parametricList, textSearch)

    local categoryEntry =
    {
        template = "ZO_GamepadDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
        header = GetString(SI_GAMEPAD_GROUP_FINDER_FILTERS_CATEGORY),

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog
                self.categoryDropdown = control.dropdown
                table.insert(dialog.dropdowns, self.categoryDropdown)

                self:PopulateCategoryDropdown()

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.categoryDropdown)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
    table.insert(parametricList, categoryEntry)

    local primaryOptionSingleSelectEntry =
    {
        template = "ZO_GamepadDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog
                self.primaryOptionDropdownSingleSelect = control.dropdown
                table.insert(dialog.dropdowns, self.primaryOptionDropdownSingleSelect)

                self:PopulatePrimaryDropdownSingleSelect()

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.primaryOptionDropdownSingleSelect)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            visible = function(dialog)
                local category = GetGroupFinderFilterCategory()
                return category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_TRIAL or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_PVP
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
    table.insert(parametricList, primaryOptionSingleSelectEntry)

    local primaryOptionEntry =
    {
        template = "ZO_GamepadMultiSelectionDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog
                self.primaryOptionDropdown = control.dropdown
                table.insert(dialog.dropdowns, self.primaryOptionDropdown)

                self.primaryOptionDropdown:SetSortsItems(false)
                self.primaryOptionDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)

                self.primaryOptionDropdown.dropDownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                self:PopulatePrimaryDropdown()
                self.primaryOptionDropdown:LoadData(self.primaryOptionDropdown.dropDownData)

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.primaryOptionDropdown)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            visible = function(dialog)
                local category = GetGroupFinderFilterCategory()
                return category == GROUP_FINDER_CATEGORY_ZONE
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
    table.insert(parametricList, primaryOptionEntry)

    local secondaryOptionEntry =
    {
        template = "ZO_GamepadMultiSelectionDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog
                self.secondaryOptionDropdown = control.dropdown
                table.insert(dialog.dropdowns, self.secondaryOptionDropdown)

                self.secondaryOptionDropdown:SetSortsItems(false)
                self.secondaryOptionDropdown:SetMaxSelections(GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS)

                self.secondaryOptionDropdown.dropDownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                self:PopulateSecondaryDropdown()

                local function IsSelectionBlockedCallback(item)
                    if item.value == 1 then
                        return true
                    end
                    return false
                end
                self.secondaryOptionDropdown:SetIsSelectionBlockedCallback(IsSelectionBlockedCallback)

                local function OnSelectionBlockedCallback(item)
                    if item.value == 1 then
                        SetGroupFinderFilterSecondaryOptionByIndex(item.value, self.secondaryOptionDropdown:IsItemSelected(item))
                        self.secondaryOptionDropdown:ClearAllSelections()
                        self.secondaryOptionDropdown:SetItemIndexSelected(item.value)
                        self.secondaryOptionDropdown:RefreshSelections()
                        return true
                    end
                    return false
                end
                self.secondaryOptionDropdown:SetOnSelectionBlockedCallback(OnSelectionBlockedCallback)

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.secondaryOptionDropdown)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            visible = function(dialog)
                local category = GetGroupFinderFilterCategory()
                return category ~= GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON and category ~= GROUP_FINDER_CATEGORY_CUSTOM
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
    table.insert(parametricList, secondaryOptionEntry)

    local groupSizeEntry =
    {
        template = "ZO_GamepadMultiSelectionDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog
                self.sizeDropdown = control.dropdown
                table.insert(dialog.dropdowns, self.sizeDropdown)

                -- Currently, the group size enum has fewer entries than our max searchable selections, so we'll just
                -- not set a maxSelectedItems on gamepad to avoid a potentially confusing (current/max) select keybind string.
                -- Groupsize is a flag so the max searchable value is going to be two to the searchable size
                internalassert(GROUP_FINDER_SIZE_MAX_VALUE <= math.pow(2, GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS), "Number of possible options exceeds max, please set a max number of selectable items for this dropdown")
                self.sizeDropdown.dropDownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                self:PopulateSizeDropdown()
                self.sizeDropdown:LoadData(self.sizeDropdown.dropDownData)

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.sizeDropdown)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
    table.insert(parametricList, groupSizeEntry)

    local playstyleEntry =
    {
        template = "ZO_GamepadMultiSelectionDropdownItem",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
        header = GetString(SI_GROUP_FINDER_HEADER_LABEL_PLAYSTYLE),

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dialog = data.dialog
                self.playstyleDropdown = control.dropdown
                table.insert(dialog.dropdowns, self.playstyleDropdown)

                -- Currently, the playstyle enum has fewer entries than our max searchable selections, so we'll just
                -- not set a maxSelectedItems on gamepad to avoid a potentially confusing (current/max) select keybind string.
                -- Playstyle is a flag so the max searchable value is going to be two to the searchable size
                internalassert(GROUP_FINDER_PLAYSTYLE_MAX_VALUE <= math.pow(2, GROUP_FINDER_MAX_SEARCHABLE_SELECTIONS), "Number of possible options exceeds max, please set a max number of selectable items for this dropdown")
                self.playstyleDropdown.dropDownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                self:PopulatePlaystyleDropdown()
                self.playstyleDropdown:LoadData(self.playstyleDropdown.dropDownData)

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.playstyleDropdown)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    targetControl.dropdown:Activate()
                end
            end,
            visible = function(dialog)
                local category = GetGroupFinderFilterCategory()
                return category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_TRIAL or category == GROUP_FINDER_CATEGORY_ARENA
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
    table.insert(parametricList, playstyleEntry)

    local championCheckboxEntry =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = zo_strformat(SI_GROUP_FINDER_CHAMPION_REQUIRED_TEXT, ZO_GetChampionIconMarkupString(ZO_GROUP_LISTING_CHAMPION_ICON_SIZE)),
        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                self.championCheckbox = control.checkBox
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                self:UpdateCheckStateRequireChampion()
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    SetGroupFinderFilterRequiresChampion(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    local RESELECT_ENTRY = true
                    local DONT_LIMIT_NUM_ENTRIES = nil
                    ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, DONT_LIMIT_NUM_ENTRIES, RESELECT_ENTRY)
                end
            end,
            enabled = function(dialog)
                return IsUnitChampion("player")
            end,
            checked = function()
                return DoesGroupFinderFilterRequireChampion()
            end,
            narrationText = ZO_GetDefaultParametricListToggleNarrationText,
        },
    }
    table.insert(parametricList, championCheckboxEntry)

    local championPointsEntry =
    {
        template = "ZO_GroupFinder_ChampionPoint_EditBox_Gamepad",
        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

        templateData =
        {
            focusLostCallback = function(control)
                local newChampionPoints = control:GetText()
                SetGroupFinderFilterChampionPoints(tonumber(newChampionPoints))
            end,
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.highlight:SetHidden(not selected)
                self.championTextBoxControl = control.editBoxControl

                control.editBoxControl.focusLostCallback = data.focusLostCallback

                self:UpdateCheckStateRequireChampion()
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                if targetData then
                    local editControl = dialog.entryList:GetTargetControl().editBoxControl

                    editControl:TakeFocus()
                end
            end,
            visible = function(dialog)
                return DoesGroupFinderFilterRequireChampion()
            end,
            narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
        }
    }
    table.insert(parametricList, championPointsEntry)

    local voipCheckboxEntry =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_GROUP_FINDER_FILTERS_VOIP),
        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                self.voipCheckbox = control.checkBox
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                self:UpdateCheckStateRequireVOIP()
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    SetGroupFinderFilterRequiresVOIP(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end
            end,
            checked = function()
                return DoesGroupFinderFilterRequireVOIP()
            end,
            narrationText = ZO_GetDefaultParametricListToggleNarrationText,
        },
    }
    table.insert(parametricList, voipCheckboxEntry)

    local inviteCodeCheckboxEntry =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_GROUP_FINDER_FILTERS_INVITE_CODE),
        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                self.inviteCodeCheckbox = control.checkBox
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                self:UpdateCheckStateInviteCode()
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    SetGroupFinderFilterRequiresInviteCode(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end
            end,
            checked = function()
                return DoesGroupFinderFilterRequireInviteCode()
            end,
            narrationText = ZO_GetDefaultParametricListToggleNarrationText,
        },
    }
    table.insert(parametricList, inviteCodeCheckboxEntry)

    local autoAcceptCheckboxEntry =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_GROUP_FINDER_FILTERS_AUTO_ACCEPT),
        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                self.autoAcceptCheckbox = control.checkBox
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                self:UpdateCheckStateAutoAcceptRequests()
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    SetGroupFinderFilterAutoAcceptRequests(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end
            end,
            checked = function()
                return DoesGroupFinderFilterAutoAcceptRequests()
            end,
            narrationText = ZO_GetDefaultParametricListToggleNarrationText,
        },
    }
    table.insert(parametricList, autoAcceptCheckboxEntry)

    local ownRoleCheckboxEntry =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_GROUP_FINDER_FILTERS_OWN_ROLE),
        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                self.ownRoleOnlyCheckbox = control.checkBox
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                self:UpdateCheckStateOwnRoles()
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                if targetControl then
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    SetGroupFinderFilterEnforceRoles(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end
            end,
            checked = function()
                return DoesGroupFinderFilterRequireEnforceRoles()
            end,
            narrationText = ZO_GetDefaultParametricListToggleNarrationText,
        },
    }
    table.insert(parametricList, ownRoleCheckboxEntry)

    return parametricList
end

ZO_GROUP_FINDER_ADDITIONAL_FILTERS_GAMEPAD = ZO_GroupFinder_AdditionalFilters_Gamepad:New()