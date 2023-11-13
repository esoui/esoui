--------------------------------------------
-- Group Finder Create Edit Group Listing --
--------------------------------------------

ZO_GroupFinder_CreateEditGroupListing_Gamepad = ZO_GroupFinder_CreateEditGroupListing_Shared:Subclass()

function ZO_GroupFinder_CreateEditGroupListing_Gamepad:Initialize()
    ZO_GroupFinder_CreateEditGroupListing_Shared.Initialize(self)
    self:InitializeCreateEditDialog()
end

function ZO_GroupFinder_CreateEditGroupListing_Gamepad:InitializeCreateEditDialog()
    local function GetDialogText()
        if self.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING then
            return GetString(SI_GROUP_FINDER_CONFIRM_EDIT_GROUP)
        else
            return GetString(SI_GAMEPAD_GROUP_FINDER_CREATE_GROUP)
        end
    end

    local function setupFunction(dialog)
        self:UpdateUserType()

        self.showInviteCode = true
        local titleText = GetDialogText()
        ZO_GenericGamepadDialog_RefreshText(dialog, titleText)
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
        CancelEditGroupListing()
    end

    ZO_Dialogs_RegisterCustomDialog("GROUP_FINDER_CREATE_EDIT_GROUP_LISTING_GAMEPAD",
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        setup = setupFunction,
        parametricList = self:BuildCreateEditList(),
        blockDialogReleaseOnPress = true,
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            if newSelectedData and newSelectedData.isTitle then
                self:UpdateTitleTooltip(dialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(dialog)
            end
        end,
        parametricListOnActivatedChangedCallback = function(list, isActive)
            if not isActive then
                local selectedControl = list:GetSelectedControl()
                if selectedControl and selectedControl.roleSpinner then
                    selectedControl.roleSpinner:SetActive(false)
                end
            end
        end,
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
                visible = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.roleType then
                        return false
                    end
                    return true
                end,
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        if type(targetData.enabled) == "function" then
                            return targetData.enabled()
                        else
                            return targetData.enabled
                        end
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GROUP_FINDER_CREATE_EDIT_GROUP_LISTING_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = GetDialogText,
                enabled = function(dialog)
                    local IS_EDITING = true
                    return ZO_GroupFinder_CanDoCreateEdit(self.userTypeData, self.groupTitleEditControl, IS_EDITING)
                end,
                callback = function(dialog)
                    self:DoCreateEdit()
                    -- TODO GroupFinder: Put up waiting dialog while create request is sent to server
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GROUP_FINDER_CREATE_EDIT_GROUP_LISTING_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_TERTIARY",
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
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })
end

function ZO_GroupFinder_CreateEditGroupListing_Gamepad:ShowDialog()
    self:Refresh()
    ZO_Dialogs_ShowGamepadDialog("GROUP_FINDER_CREATE_EDIT_GROUP_LISTING_GAMEPAD")
end

function ZO_GroupFinder_CreateEditGroupListing_Gamepad:Refresh()
    -- Clear entry control references before refresh because rebuilding the dialog will recycle the control
    self.categoryDropdown = nil
    self.primaryOptionDropdown = nil
    self.secondaryOptionDropdown = nil
    self.sizeDropdown = nil
    self.groupTitleEditControl = nil
    self.descriptionEditControl = nil
    self.playstyleDropdown = nil
    self.championCheckbox = nil
    self.championPointsEditBoxControl = nil
    self.voipCheckbox = nil
    self.inviteCodeCheckbox = nil
    self.inviteCodeEditBoxControl = nil
    self.autoAcceptCheckbox = nil
    self.enforceRolesCheckbox = nil

    ZO_GroupFinder_CreateEditGroupListing_Shared.Refresh(self)

    local dialog = ZO_Dialogs_FindDialog("GROUP_FINDER_CREATE_EDIT_GROUP_LISTING_GAMEPAD")
    if dialog then
        local RESELECT_ENTRY = true
        local DONT_LIMIT_NUM_ENTRIES = nil
        ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, DONT_LIMIT_NUM_ENTRIES, RESELECT_ENTRY)
    end
end

do
    local MAX_CP_ALLOWED = GetMaxSpendableChampionPointsInAttribute() * GetNumChampionDisciplines()

    function ZO_GroupFinder_CreateEditGroupListing_Gamepad:BuildCreateEditList(category)
        -- TODO GroupFinder: Populate the dropdowns from the client
        local parametricList = {}

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
                    targetControl.dropdown:Activate()
                end,
                visible = function(dialog)
                    return self.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT
                end,
                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
        table.insert(parametricList, categoryEntry)

        local primaryOptionEntry =
        {
            template = "ZO_GamepadDropdownItem",
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    local dialog = data.dialog
                    self.primaryOptionDropdown = control.dropdown
                    table.insert(dialog.dropdowns, self.primaryOptionDropdown)
                    self:PopulatePrimaryDropdown()
                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.primaryOptionDropdown)
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    targetControl.dropdown:Activate()
                end,
                visible = function(dialog)
                    local groupFinderCategory = self.userTypeData:GetCategory()
                    return self.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT
                        and groupFinderCategory ~= GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON
                        and groupFinderCategory ~= GROUP_FINDER_CATEGORY_CUSTOM
                end,
                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
        table.insert(parametricList, primaryOptionEntry)

        local secondaryOptionEntry =
        {
            template = "ZO_GamepadDropdownItem",
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    local dialog = data.dialog
                    self.secondaryOptionDropdown = control.dropdown
                    table.insert(dialog.dropdowns, self.secondaryOptionDropdown)
                    self:PopulateSecondaryDropdown()
                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.secondaryOptionDropdown)
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    targetControl.dropdown:Activate()
                end,
                visible = function(dialog)
                    local groupFinderCategory = self.userTypeData:GetCategory()
                    return self.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT
                        and groupFinderCategory ~= GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON
                        and groupFinderCategory ~= GROUP_FINDER_CATEGORY_CUSTOM
                end,
                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
        table.insert(parametricList, secondaryOptionEntry)

        local groupSizeEntry =
        {
            template = "ZO_GamepadDropdownItem",
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    local dialog = data.dialog
                    self.sizeDropdown = control.dropdown
                    table.insert(dialog.dropdowns, self.sizeDropdown)
                    self:PopulateSizeDropdown()
                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.sizeDropdown)
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    targetControl.dropdown:Activate()
                end,
                visible = function(dialog)
                    return self.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT
                end,
                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
        table.insert(parametricList, groupSizeEntry)

        local groupListingTitle =
        {
            template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

            templateData =
            {
                isTitle = true,
                focusLostCallback = function(control)
                    local newTitle = control:GetText()
                    self.userTypeData:SetTitle(newTitle)
                    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                end,
                textChangedCallback = function(control)
                    local newTitle = control:GetText()
                    if newTitle ~= self.userTypeData:GetTitle() then
                        self.userTypeData:SetTitle(newTitle)
                        local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
                        self:UpdateTitleTooltip(dialog)
                    end
                end,
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    control.highlight:SetHidden(not selected)
                    self.groupTitleEditControl = control.editBoxControl
                    control.editBoxControl:SetMaxInputChars(GROUP_FINDER_GROUP_LISTING_TITLE_MAX_LENGTH)
                    control.editBoxControl:SetDefaultText(GetString(SI_GROUP_FINDER_CREATE_TITLE_DEFAULT_TEXT))
                    control.editBoxControl.focusLostCallback = data.focusLostCallback
                    control.editBoxControl.textChangedCallback = data.textChangedCallback
                    self:UpdateEditBoxGroupListingTitle()
                end,
                callback = function(dialog)
                    local editControl = dialog.entryList:GetTargetControl().editBoxControl
                    editControl:TakeFocus()
                end,
                narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
            }
        }
        table.insert(parametricList, groupListingTitle)

        local groupListingDescription =
        {
            template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
            templateData =
            {
                focusLostCallback = function(control)
                    local description = control:GetText()
                    self.userTypeData:SetDescription(description)
                    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                end,
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    control.highlight:SetHidden(not selected)
                    self.descriptionEditControl = control.editBoxControl
                    control.editBoxControl:SetMaxInputChars(GROUP_FINDER_GROUP_LISTING_DESCRIPTION_MAX_LENGTH)
                    control.editBoxControl:SetDefaultText(GetString(SI_GROUP_FINDER_CREATE_DESCRIPTION_DEFAULT_TEXT))
                    control.editBoxControl.focusLostCallback = data.focusLostCallback
                    self:UpdateEditBoxGroupListingDescription()
                end,
                callback = function(dialog)
                    local editControl = dialog.entryList:GetTargetControl().editBoxControl
                    editControl:TakeFocus()
                end,
                narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
            }
        }
        table.insert(parametricList, groupListingDescription)

        local playstyleEntry =
        {
            template = "ZO_GamepadDropdownItem",
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
            header = GetString(SI_GROUP_FINDER_HEADER_LABEL_PLAYSTYLE),

            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    local dialog = data.dialog
                    self.playstyleDropdown = control.dropdown
                    table.insert(dialog.dropdowns, self.playstyleDropdown)
                    self:PopulatePlaystyleDropdown()
                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, self.playstyleDropdown)
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    targetControl.dropdown:Activate()
                end,
                visible = function(dialog)
                    local groupFinderCategory = self.userTypeData:GetCategory()
                    return groupFinderCategory == GROUP_FINDER_CATEGORY_DUNGEON
                        or groupFinderCategory == GROUP_FINDER_CATEGORY_ARENA
                        or groupFinderCategory == GROUP_FINDER_CATEGORY_TRIAL
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
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    self.userTypeData:SetGroupRequiresChampion(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    local RESELECT_ENTRY = true
                    local DONT_LIMIT_NUM_ENTRIES = nil
                    ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, DONT_LIMIT_NUM_ENTRIES, RESELECT_ENTRY)
                end,
                checked = function()
                    return self.userTypeData:DoesGroupRequireChampion()
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
                    local championPointsText = control:GetText()
                    if championPointsText ~= "" then
                        local championPoints = tonumber(championPointsText)
                        if championPoints > MAX_CP_ALLOWED then
                            championPoints = MAX_CP_ALLOWED
                            control:SetText(championPoints)
                        end
                        if championPoints ~= 0 then
                            self.userTypeData:SetChampionPoints(championPoints)
                        end
                    end
                    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                end,
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    control.highlight:SetHidden(not selected)
                    self.championPointsEditBoxControl = control.editBoxControl

                    control.editBoxControl.focusLostCallback = data.focusLostCallback

                    self:UpdateChampionPointsEditBox()
                end,
                callback = function(dialog)
                    local editControl = dialog.entryList:GetTargetControl().editBoxControl
                    editControl:TakeFocus()
                end,
                visible = function(dialog)
                    return self.userTypeData:DoesGroupRequireChampion()
                end,
                narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
            }
        }
        table.insert(parametricList, championPointsEntry)

        local voipCheckboxEntry =
        {
            template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
            text = GetString(SI_GROUP_FINDER_CREATE_VOIP_REQUIRED_TEXT),
            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self.voipCheckbox = control.checkBox
                    ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self:UpdateCheckStateRequireVOIP()
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    self.userTypeData:SetGroupRequiresVOIP(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end,
                checked = function()
                    return self.userTypeData:DoesGroupRequireVOIP()
                end,
                narrationText = ZO_GetDefaultParametricListToggleNarrationText,
            },
        }
        table.insert(parametricList, voipCheckboxEntry)

        local inviteCodeCheckboxEntry =
        {
            template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
            text = GetString(SI_GROUP_FINDER_CREATE_INVITE_CODE_TEXT),
            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self.inviteCodeCheckbox = control.checkBox
                    ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self:UpdateCheckStateInviteCode()
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    self.userTypeData:SetGroupRequiresInviteCode(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    local RESELECT_ENTRY = true
                    local DONT_LIMIT_NUM_ENTRIES = nil
                    ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, DONT_LIMIT_NUM_ENTRIES, RESELECT_ENTRY)
                end,
                checked = function()
                    return self.userTypeData:DoesGroupRequireInviteCode()
                end,
                narrationText = ZO_GetDefaultParametricListToggleNarrationText,
            },
        }
        table.insert(parametricList, inviteCodeCheckboxEntry)

        local inviteCodeEditBoxEntry =
        {
            template = "ZO_GroupFinder_InviteCode_EditBox_Gamepad",
            headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",

            templateData =
            {
                focusLostCallback = function(control)
                    local newInviteCode = control:GetText()
                    self.userTypeData:SetInviteCode(tonumber(newInviteCode))
                    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                end,
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    control.highlight:SetHidden(not selected)
                    self.inviteCodeEditBoxControl = control.editBoxControl

                    control.editBoxControl.focusLostCallback = data.focusLostCallback

                    self.inviteCodeEditBoxControl:SetAsPassword(not self.showInviteCode)
                    self:UpdateInviteCodeEditBox()
                    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                end,
                callback = function(dialog)
                    local editControl = dialog.entryList:GetTargetControl().editBoxControl
                    editControl:TakeFocus()
                end,
                togglePasswordCallback = function(dialog)
                    self.showInviteCode = not self.showInviteCode
                    local targetControl = dialog.entryList:GetTargetControl()
                    targetControl.editBoxControl:SetAsPassword(not self.showInviteCode)
                end,
                visible = function(dialog)
                    return self.userTypeData:DoesGroupRequireInviteCode()
                end,
                narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
            }
        }
        table.insert(parametricList, inviteCodeEditBoxEntry)

        local autoAcceptCheckboxEntry =
        {
            template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
            text = GetString(SI_GROUP_FINDER_CREATE_AUTO_ACCEPT_TEXT),
            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self.autoAcceptCheckbox = control.checkBox
                    ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self:UpdateCheckStateAutoAcceptRequests()
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    self.userTypeData:SetGroupAutoAcceptRequests(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end,
                checked = function()
                    return self.userTypeData:DoesGroupAutoAcceptRequests()
                end,
                narrationText = ZO_GetDefaultParametricListToggleNarrationText,
            },
        }
        table.insert(parametricList, autoAcceptCheckboxEntry)

        local enforceRolesCheckboxEntry =
        {
            template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
            text = GetString(SI_GROUP_FINDER_CREATE_ENFORCE_ROLES_TEXT),
            templateData =
            {
                setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self.enforceRolesCheckbox = control.checkBox
                    ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    self:UpdateCheckStateEnforceRoles()
                end,
                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    self.userTypeData:SetGroupEnforceRoles(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    local RESELECT_ENTRY = true
                    local DONT_LIMIT_NUM_ENTRIES = nil
                    ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, DONT_LIMIT_NUM_ENTRIES, RESELECT_ENTRY)
                end,
                checked = function()
                    return self.userTypeData:DoesGroupEnforceRoles()
                end,
                narrationText = ZO_GetDefaultParametricListToggleNarrationText,
            },
        }
        table.insert(parametricList, enforceRolesCheckboxEntry)

        local spinnerRoles =
        {
            LFG_ROLE_TANK,
            LFG_ROLE_HEAL,
            LFG_ROLE_DPS,
            LFG_ROLE_INVALID,
        }

        self.roleSpinnerTable = {}

        for i, roleType in ipairs(spinnerRoles) do
            local enforceRoleSpinnerEntry =
            {
                template = "ZO_SpinnerEntry_Indented_Gamepad",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local function GetRoleMin(spinner)
                            if spinner.roleType == LFG_ROLE_INVALID then
                                return self.userTypeData:GetDesiredRoleCountAtEdit(LFG_ROLE_INVALID)
                            else
                                return self.userTypeData:GetAttainedRoleCountAtEdit(spinner.roleType)
                            end
                        end

                        local function GetRoleMax(spinner)
                            if spinner.roleType == LFG_ROLE_INVALID then
                                return self.userTypeData:GetDesiredRoleCountAtEdit(LFG_ROLE_INVALID)
                            else
                                return self.userTypeData:GetDesiredRoleCountAtEdit(spinner.roleType) + self.userTypeData:GetDesiredRoleCountAtEdit(LFG_ROLE_INVALID)
                            end
                        end

                        local function OnValueChanged(value, spinner)
                            self.userTypeData:SetDesiredRoleCountAtEdit(spinner.roleType, value)
                            self:UpdateRoles()
                            local dialog = data.dialog
                            ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                            --Re-narrate when the value changes
                            SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                        end

                        data.roleType = roleType
                        self.roleSpinnerTable[roleType] = control
                        local roleName = self:GetRoleLabelText(roleType)
                        control:GetNamedChild("Label"):SetText(roleName)
                        if control.roleSpinner == nil then
                            control.roleSpinner = ZO_Spinner_Gamepad:New(control:GetNamedChild("Spinner"))
                        end

                        control.roleSpinner.roleType = roleType
                        control.roleSpinner:SetMinMax(GetRoleMin, GetRoleMax)
                        control.roleSpinner:UnregisterAllCallbacks("OnValueChanged")
                        -- set value before registering the callback because we're just setting up, not making changes
                        control.roleSpinner:SetValue(self.userTypeData:GetDesiredRoleCountAtEdit(roleType))
                        control.roleSpinner:RegisterCallback("OnValueChanged", OnValueChanged)
                        control.roleSpinner:SetName(roleName)
                        control.roleSpinner:SetButtonsHidden(roleType == LFG_ROLE_INVALID)
                        control.roleSpinner:SetActive(selected)

                        local function GetDirectionalInputNarrationData()
                            --Only narrate directional input if there is more than one possible value
                            if control.roleSpinner:GetMin() ~= control.roleSpinner:GetMax() then
                                local decreaseEnabled = control.roleSpinner:IsDecreaseEnabled()
                                local increaseEnabled = control.roleSpinner:IsIncreaseEnabled()
                                return ZO_GetNumericHorizontalDirectionalInputNarrationData(decreaseEnabled, increaseEnabled)
                            else
                                return {}
                            end
                        end
                        data.additionalInputNarrationFunction = GetDirectionalInputNarrationData
                    end,
                    visible = function(dialog)
                        return self.userTypeData:DoesGroupEnforceRoles()
                    end,
                    narrationText = function(entryData, entryControl)
                        return entryControl.roleSpinner:GetNarrationText()
                    end,
                },
            }
            table.insert(parametricList, enforceRoleSpinnerEntry)
        end

        return parametricList
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Gamepad:UpdateTitleTooltip(dialog)
    local tooltipText = self:GetTitleTooltipText()
    if tooltipText ~= "" then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, tooltipText)
        ZO_GenericGamepadDialog_ShowTooltip(dialog)
    else
        ZO_GenericGamepadDialog_HideTooltip(dialog)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Gamepad:UpdateRoles()
    for roleType, control in pairs(self.roleSpinnerTable) do
        if control and control.roleSpinner and not control.roleSpinner:SetValue(self.userTypeData:GetDesiredRoleCountAtEdit(roleType)) then
            control.roleSpinner:UpdateButtons()
        end
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Gamepad:OnGroupMemberRoleChanged()
    if ZO_Dialogs_IsShowing("GROUP_FINDER_CREATE_EDIT_GROUP_LISTING_GAMEPAD") then
        local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
        ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
    end
end
