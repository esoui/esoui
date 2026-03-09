-----------------------------
--Mod Browser Gamepad
-----------------------------
MOD_BROWSER_LIST_ENTRY_SORT_KEYS =
{
    --Sort keys correspond to functions from ZO_ModBrowserListingSearchData
    ["GetTitle"] = { },
    ["GetNumUsers"] = { tiebreaker = "GetTitle" },
    ["GetInstallState"] = { tiebreaker = "GetTitle" },
}

ZO_GAMEPAD_MOD_BROWSER_CATEGORY_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_MOD_BROWSER_MOD_NAME_WIDTH = 600 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_MOD_BROWSER_USERS_WIDTH = 295 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_MOD_BROWSER_INSTALL_STATE_WIDTH = 250 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

local MOD_DATA = 1

local AddOnManager = GetAddOnManager()

local SAVED_VARIABLE_DISK_USAGE_SMALL_THRESHOLD = 0.1

ZO_ModBrowser_Gamepad = ZO_GamepadInteractiveSortFilterList:Subclass()

function ZO_ModBrowser_Gamepad:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)

    self.masterList = {}
    self.imageIndex = 1
    self:RegisterForEvents()
    self:RegisterDialogs()
    self:SetupSort(MOD_BROWSER_LIST_ENTRY_SORT_KEYS, "GetNumUsers", ZO_SORT_ORDER_DOWN)
end

function ZO_ModBrowser_Gamepad:RegisterForEvents()
    MOD_BROWSER_SEARCH_MANAGER:RegisterCallback("OnSearchStateChanged", function(newState)
        if self:IsShowing() then
            self:RefreshData()
            local NARRATE_HEADER = true
            self:NarrateSelection(NARRATE_HEADER)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("ModBrowser", EVENT_MOD_INSTALL_STATE_CHANGED, function(_, ...) self:OnModListingInstallStateChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ModBrowser", EVENT_MOD_LISTING_IMAGE_LOAD_COMPLETE, function(_, ...) self:OnModListingImageLoadComplete(...) end)
    EVENT_MANAGER:RegisterForEvent("ModBrowser", EVENT_MOD_LISTING_DEPENDENCIES_LOAD_COMPLETE, function(_, ...) self:OnModListingDependenciesLoadComplete(...) end)
    EVENT_MANAGER:RegisterForEvent("ModBrowser", EVENT_MOD_LISTING_REPORT_SUBMITTED, function(_, ...) self:OnModListingReportSubmitted(...) end)
    EVENT_MANAGER:RegisterForEvent("ModBrowser", EVENT_CONSOLE_ADDONS_DISABLED_STATE_CHANGED, function(_, ...) self:OnConsoleAddOnsDisabledStateChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ModBrowser", EVENT_ADDONS_DISABLED_STATE_CHANGED, function(_, ...) self:OnAddOnsDisabledStateChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ModBrowser", EVENT_MOD_LISTING_RELEASE_NOTE_LOAD_COMPLETE, function(_, ...) self:OnModListingReleaseNoteLoadComplete(...) end)
end

function ZO_ModBrowser_Gamepad:RegisterDialogs()

    --Install and update are mutually exclusive and behave the same, so they are one entry here
    local INSTALL_OR_UPDATE_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = function(dialog)
                local installState = dialog.data:GetInstallState()
                if installState == MOD_INSTALL_STATE_NOT_INSTALLED then
                    return GetString(SI_GAMEPAD_MOD_BROWSER_INSTALL)
                else
                    return GetString(SI_GAMEPAD_MOD_BROWSER_UPDATE)
                end
            end,
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD")
                dialog.data:Install()
            end,
        },
    }

    local UNINSTALL_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_UNINSTALL),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD")
                ZO_Dialogs_ShowPlatformDialog("MOD_BROWSER_LISTING_CONFIRM_UNINSTALL_GAMEPAD", dialog.data)
            end,
        },
    }

    local REINSTALL_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_REINSTALL),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD")
                dialog.data:Reinstall()
            end,
        },
    }

    local DELETE_SAVED_VARIABLES_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_GAMEPAD_ADDON_MANAGER_DELETE_SAVED_VARIABLES),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD")
                local dialogData =
                {
                    onConfirmCallback = function()
                        dialog.data:DeleteSavedVariables()
                    end,
                    addonName = dialog.data:GetTitle(),
                }
                ZO_Dialogs_ShowGamepadDialog("ADDON_DELETE_SAVED_VARIABLES_CONFIRMATION", dialogData)
            end,
            tooltipText = function(dialog)
                local savedVariableDiskUsage = dialog.data:GetSavedVariablesDiskUsageMB()
                local formattedUsageText
                if savedVariableDiskUsage > 0 and savedVariableDiskUsage < SAVED_VARIABLE_DISK_USAGE_SMALL_THRESHOLD then
                    formattedUsageText = GetString(SI_GAMEPAD_ADDON_MANAGER_SAVED_VARIABLES_USAGE_SMALL)
                else
                    formattedUsageText = zo_strformat(SI_GAMEPAD_ADDON_MANAGER_SAVED_VARIABLES_USAGE_FORMATTER, savedVariableDiskUsage)
                end
                return ZO_GenerateParagraphSeparatedList({ GetString(SI_GAMEPAD_ADDON_MANAGER_DELETE_SAVED_VARIABLES_TOOLTIP), formattedUsageText })
            end,
            narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
        },
    }

    local IGNORE_UPDATES_ENTRY =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_GAMEPAD_MOD_BROWSER_IGNORE_UPDATES),
        templateData =
        {
            -- Called when the checkbox is toggled
            setChecked = function(checkBox, checked)
                checkBox.dialog.data:SetIgnoreUpdates(checked)
                self:RefreshVisible()
            end,
            -- Used during setup to determine if the data should be setup checked or unchecked
            checked = function(data)
                return data.dialog.data:GetIgnoreUpdates()
            end,
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.checkBox.dialog = data.dialog
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
            end,
            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
            end,
            tooltipText = function(dialog)
                return GetString(SI_GAMEPAD_MOD_BROWSER_IGNORE_UPDATES_TOOLTIP)
            end,
            narrationText = ZO_GetDefaultParametricListToggleNarrationText,
            narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
        }
    }

    local REPORT_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD")
                ZO_Dialogs_ShowPlatformDialog("MOD_BROWSER_LISTING_REPORT_GAMEPAD", dialog.data)
            end,
        },
    }

    local RELEASE_NOTES_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_RELEASE_NOTES),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD")
                ZO_Dialogs_ShowPlatformDialog("MOD_BROWSER_LISTING_RELEASE_NOTES_GAMEPAD", dialog.data)
            end,
        }
    }

    --Listing options
    ZO_Dialogs_RegisterCustomDialog("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = SI_GAMEPAD_MOD_BROWSER_OPTIONS_HEADER,
        },
        setup = function(dialog, data)
            local parametricListEntries = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)

            if data then
                local installState = data:GetInstallState()
                if installState == MOD_INSTALL_STATE_NOT_INSTALLED or installState == MOD_INSTALL_STATE_UPDATE_AVAILABLE then
                    table.insert(parametricListEntries, INSTALL_OR_UPDATE_ENTRY)
                end
                
                if installState == MOD_INSTALL_STATE_INSTALLED or installState == MOD_INSTALL_STATE_UPDATE_AVAILABLE then
                    table.insert(parametricListEntries, UNINSTALL_ENTRY)
                    table.insert(parametricListEntries, REINSTALL_ENTRY)
                    if data:GetSavedVariablesDiskUsageMB() > 0 then
                        table.insert(parametricListEntries, DELETE_SAVED_VARIABLES_ENTRY)
                    end
                    table.insert(parametricListEntries, IGNORE_UPDATES_ENTRY)
                end

                table.insert(parametricListEntries, REPORT_ENTRY)

                if data:GetNumReleases() > 0 then
                    table.insert(parametricListEntries, RELEASE_NOTES_ENTRY)
                end
            end

            dialog.setupFunc(dialog)
        end,
        parametricList = {}, -- Generated dynamically
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
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD")
                end,
            },
        },
    })

    --Uninstall confirmation
    ZO_Dialogs_RegisterCustomDialog("MOD_BROWSER_LISTING_CONFIRM_UNINSTALL_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = SI_GAMEPAD_MOD_BROWSER_UNINSTALL,
        },
        mainText =
        {
            text = function(dialog)
                local data = dialog.data
                return zo_strformat(SI_GAMEPAD_MOD_BROWSER_UNINSTALL_CONFIRM_TEXT, ZO_SELECTED_TEXT:Colorize(data:GetTitle()))
            end,
        },
        setup = function(dialogControl, dialogData)
            local parametricListEntries = dialogControl.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)

            --Default the saved variables checkbox to false
            dialogControl.deleteSavedVariables = false

            if dialogData:GetSavedVariablesDiskUsageMB() > 0 then
                local deleteSavedVariablesEntry =
                {
                    template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                    text = GetString(SI_GAMEPAD_ADDON_MANAGER_DELETE_SAVED_VARIABLES),
                    templateData =
                    {
                        -- Called when the checkbox is toggled
                        setChecked = function(checkBox, checked)
                            checkBox.dialog.deleteSavedVariables = checked
                        end,
                        -- Used during setup to determine if the data should be setup checked or unchecked
                        checked = function(data)
                            return data.dialog.deleteSavedVariables
                        end,
                        setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                            control.checkBox.dialog = data.dialog
                            ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                        end,
                        callback = function(dialog)
                            local targetControl = dialog.entryList:GetTargetControl()
                            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                            SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                        end,
                        tooltipText = function(dialog)
                            local savedVariableDiskUsage = dialog.data:GetSavedVariablesDiskUsageMB()
                            local formattedUsageText
                            if savedVariableDiskUsage > 0 and savedVariableDiskUsage < SAVED_VARIABLE_DISK_USAGE_SMALL_THRESHOLD then
                                formattedUsageText = GetString(SI_GAMEPAD_ADDON_MANAGER_SAVED_VARIABLES_USAGE_SMALL)
                            else
                                formattedUsageText = zo_strformat(SI_GAMEPAD_ADDON_MANAGER_SAVED_VARIABLES_USAGE_FORMATTER, savedVariableDiskUsage)
                            end
                            return ZO_GenerateParagraphSeparatedList({ GetString(SI_GAMEPAD_ADDON_MANAGER_DELETE_SAVED_VARIABLES_TOOLTIP), formattedUsageText })
                        end,
                        narrationText = ZO_GetDefaultParametricListToggleNarrationText,
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                    }
                }
                table.insert(parametricListEntries, deleteSavedVariablesEntry)
            end

            local confirmUninstallEntry =
            {
                template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
                templateData =
                {
                    text = GetString(SI_DIALOG_CONFIRM),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        dialog.data:Uninstall(dialog.deleteSavedVariables)
                        ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_CONFIRM_UNINSTALL_GAMEPAD")
                    end,
                }
            }
            table.insert(parametricListEntries, confirmUninstallEntry)

            dialogControl.setupFunc(dialogControl)
        end,
        parametricList = {}, -- Generated dynamically
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
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_CONFIRM_UNINSTALL_GAMEPAD")
                end,
            },
        },
    })

    local function OnReleaseReportDialog(dialog)
        --Make sure we deactivate any open dropdowns when the dialog closes
        local targetControl = dialog.entryList:GetTargetControl()
        if targetControl and targetControl.dropdown then
            targetControl.dropdown:Deactivate()
        end
    end

    --Report Dialog
    ZO_Dialogs_RegisterCustomDialog("MOD_BROWSER_LISTING_REPORT_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_TITLE),
        },
        mainText =
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_DESCRIPTION),
        },
        setup = function(dialogControl, dialogData)
            local parametricListEntries = dialogControl.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)
            dialogControl.reportSource = MOD_BROWSER_LISTING_REPORT_SOURCE_NONE
            dialogControl.reportReason = MOD_BROWSER_LISTING_REPORT_REASON_NONE
            dialogControl.reportComment = ""

            local sourceEntry =
            {
                template = "ZO_GamepadDropdownItem",
                headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                header = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_SOURCE_HEADER),
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        local dropdownEntry = control.dropdown

                        dropdownEntry:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdownEntry:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdownEntry:SetSelectedItemTextColor(selected)

                        dropdownEntry:SetSortsItems(false)
                        dropdownEntry:ClearItems()

                        local function OnSelectedCallback(dropdown, entryText, entry)
                            dialog.reportSource = entry.reportSource
                        end

                        local entryToSelect
                        for i = MOD_BROWSER_LISTING_REPORT_SOURCE_ITERATION_BEGIN, MOD_BROWSER_LISTING_REPORT_SOURCE_ITERATION_END do
                            local entryText = GetString("SI_MODBROWSERLISTINGREPORTSOURCE", i)
                            local newEntry = control.dropdown:CreateItemEntry(entryText, OnSelectedCallback)
                            newEntry.reportSource = i
                            if dialog.reportSource == i then
                                entryToSelect = newEntry
                            end
                            control.dropdown:AddItem(newEntry)
                        end

                        dropdownEntry:UpdateItems()

                        local IGNORE_CALLBACK = true
                        dropdownEntry:TrySelectItemByData(entryToSelect, IGNORE_CALLBACK)
                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdownEntry)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.dropdown:Activate()
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                },
            }
            table.insert(parametricListEntries, sourceEntry)

            local reasonEntry =
            {
                template = "ZO_GamepadDropdownItem",
                headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                header = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_REASON_HEADER),
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        local dropdownEntry = control.dropdown

                        dropdownEntry:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdownEntry:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdownEntry:SetSelectedItemTextColor(selected)

                        dropdownEntry:SetSortsItems(false)
                        dropdownEntry:ClearItems()

                        local function OnSelectedCallback(dropdown, entryText, entry)
                            dialog.reportReason = entry.reportReason
                        end

                        local entryToSelect
                        for i = MOD_BROWSER_LISTING_REPORT_REASON_ITERATION_BEGIN, MOD_BROWSER_LISTING_REPORT_REASON_ITERATION_END do
                            local entryText = GetString("SI_MODBROWSERLISTINGREPORTREASON", i)
                            local newEntry = control.dropdown:CreateItemEntry(entryText, OnSelectedCallback)
                            newEntry.reportReason = i
                            if dialog.reportReason == i then
                                entryToSelect = newEntry
                            end
                            control.dropdown:AddItem(newEntry)
                        end

                        dropdownEntry:UpdateItems()

                        local IGNORE_CALLBACK = true
                        dropdownEntry:TrySelectItemByData(entryToSelect, IGNORE_CALLBACK)
                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdownEntry)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.dropdown:Activate()
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                },
            }
            table.insert(parametricListEntries, reasonEntry)

            local commentEntry =
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem_Multiline",
                headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                header = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_COMMENT_HEADER),
                templateData =
                {
                    focusLostCallback = function(control)
                        local comment = control:GetText()
                        local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
                        dialog.reportComment = comment
                        ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        control.editBoxControl:SetMaxInputChars(MOD_BROWSER_REPORT_LISTING_COMMENT_MAX_LENGTH)
                        control.editBoxControl:SetDefaultText(GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_COMMENT_DEFAULT_TEXT))
                        control.editBoxControl.focusLostCallback = data.focusLostCallback
                        control.editBoxControl:SetText(data.dialog.reportComment)
                    end,
                    callback = function(dialog)
                        local editControl = dialog.entryList:GetTargetControl().editBoxControl
                        editControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            }
            table.insert(parametricListEntries, commentEntry)

            local submitEntry =
            {
                template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
                templateData =
                {
                    text = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_SUBMIT),
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        data:SetEnabled(data.dialog.reportSource ~= MOD_BROWSER_LISTING_REPORT_SOURCE_NONE and data.dialog.reportReason ~= MOD_BROWSER_LISTING_REPORT_REASON_NONE)
                        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    end,
                    enabled = function(dialog)
                        --Make sure both the source and the reason have been set before allowing submission
                        return dialog.reportSource ~= MOD_BROWSER_LISTING_REPORT_SOURCE_NONE and dialog.reportReason ~= MOD_BROWSER_LISTING_REPORT_REASON_NONE
                    end,
                    tooltipText = function(dialog)
                        local errors = {}

                        if dialog.reportSource == MOD_BROWSER_LISTING_REPORT_SOURCE_NONE then
                            table.insert(errors, GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_CATEGORY_REQUIRED_TOOLTIP))
                        end

                        if dialog.reportReason == MOD_BROWSER_LISTING_REPORT_REASON_NONE then
                            table.insert(errors, GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_DIALOG_REASON_REQUIRED_TOOLTIP))
                        end

                        if #errors > 0 then
                            return ZO_GenerateParagraphSeparatedList(errors)
                        end
                    end,
                    callback = function(dialog)
                        if dialog.data:Report(dialog.reportSource, dialog.reportReason, dialog.reportComment) then
                            ZO_Dialogs_ShowPlatformDialog("MOD_BROWSER_REPORT_PENDING_DIALOG")
                        else
                            --If submitting the report failed right off the bat, immediately show the result dialog
                            local textParams =
                            {
                                titleParams = { GetString("MODBROWSERLISTINGREPORTRESULT_RESULTDIALOGTITLE", MOD_BROWSER_LISTING_REPORT_RESULT_FAILURE) },
                                mainTextParams = { GetString("MODBROWSERLISTINGREPORTRESULT_RESULTDIALOGMESSAGE", MOD_BROWSER_LISTING_REPORT_RESULT_FAILURE) }
                            }
                            ZO_Dialogs_ShowPlatformDialog("MOD_BROWSER_REPORT_RESPONSE_DIALOG", nil, textParams)
                        end
                        ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_REPORT_GAMEPAD")
                    end,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                }
            }
            table.insert(parametricListEntries, submitEntry)

            dialogControl.setupFunc(dialogControl)
        end,
        parametricList = {}, -- Generated dynamically
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
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        if type(targetData.enabled) == "function" then
                            return targetData.enabled(dialog)
                        else
                            return targetData.enabled
                        end
                    end
                end,
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
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_REPORT_GAMEPAD")
                end,
            },
        },
        onHidingCallback = OnReleaseReportDialog,
        noChoiceCallback = OnReleaseReportDialog,
    })

    --Report pending dialog
    ZO_Dialogs_RegisterCustomDialog("MOD_BROWSER_REPORT_PENDING_DIALOG",
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.COOLDOWN,
            allowShowOnNextScene = true,
        },
        title = 
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_REPORT_PENDING_DIALOG_TITLE),
        },
        mainText =
        {
            align = TEXT_ALIGN_CENTER,
            text = GetString(SI_GAMEPAD_MOD_BROWSER_REPORT_LISTING_REPORT_PENDING_DIALOG_DESCRIPTION),
        },
        showLoadingIcon = true,
        --Since no choices are provided this forces the dialog to remain shown until programmaticly closed
        mustChoose = true,
        buttons = {},
    })

    --Report result dialog
    ZO_Dialogs_RegisterCustomDialog("MOD_BROWSER_REPORT_RESPONSE_DIALOG",
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_GAMEPAD_MOD_BROWSER_REPORT_RESPONSE_DIALOG_TITLE_FORMATTER,
        },
        mainText =
        {
            align = TEXT_ALIGN_CENTER,
            text = SI_GAMEPAD_MOD_BROWSER_REPORT_RESPONSE_DIALOG_BODY_FORMATTER,
        },
        buttons =
        {
            {
                text = SI_OK,
                keybind = "DIALOG_PRIMARY",
                clickSound = SOUNDS.DIALOG_ACCEPT,
            }
        },
    })

    --Release Notes Dialog
    ZO_Dialogs_RegisterCustomDialog("MOD_BROWSER_LISTING_RELEASE_NOTES_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_RELEASE_NOTES),
        },
        setup = function(dialogControl, dialogData)
            local parametricListEntries = dialogControl.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)

            local numReleases = dialogData:GetNumReleases()

            --Add each release to the list. The releases should be in reverse chronological order
            for i = 1, numReleases do
                local releaseNoteEntry =
                {
                    template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
                    templateData =
                    {
                        text = zo_strformat(SI_GAMEPAD_MOD_BROWSER_LISTING_TOOLTIP_VERSION, dialogData:GetReleaseVersion(i)),
                        setup = ZO_SharedGamepadEntry_OnSetup,
                        tooltipFunction = function(dialog)
                            GAMEPAD_TOOLTIPS:LayoutModListingReleaseTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, dialogData, i)
                        end,
                        releaseNoteIndex = i,
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                    }
                }
                table.insert(parametricListEntries, releaseNoteEntry)
            end
            dialogControl.setupFunc(dialogControl)
        end,
        parametricList = {}, -- Generated dynamically
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            self:RefreshReleaseNoteDialogTooltip(dialog)
        end,
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("MOD_BROWSER_LISTING_RELEASE_NOTES_GAMEPAD")
                end,
            },
        },
    })
end

--Overridden from base
function ZO_ModBrowser_Gamepad:InitializeHeader(headerData)
    self.contentHeader = self.container:GetNamedChild("ContentHeader")
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)

    if headerData then
        headerData.titleTextAlignment = headerData.titleTextAlignment or TEXT_ALIGN_CENTER
    else
        headerData = { titleTextAlignment = TEXT_ALIGN_CENTER }
    end
    
    local tabBarEntries =
    {
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_BROWSE_HEADER),
            callback = function()
                self:SetSearchType(MOD_BROWSER_SEARCH_TYPE_BROWSE)
            end,
        },
        {
            text = GetString(SI_GAMEPAD_MOD_BROWSER_SUBSCRIBED_HEADER),
            callback = function()
                self:SetSearchType(MOD_BROWSER_SEARCH_TYPE_SUBSCRIBED)
            end,
        }
    }

    headerData.tabBarEntries = tabBarEntries
    self.contentHeaderData = headerData
    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.contentHeader, 1)

    local titleFonts =
    {
        {
            font = "ZoFontGamepadBold48",
        },
        {
            font = "ZoFontGamepadBold34",
        },
        {
            font = "ZoFontGamepadBold27",
        }
    }
    ZO_FontAdjustingWrapLabel_OnInitialized(self.contentHeader:GetNamedChild("TitleContainerTitle"), titleFonts, TEXT_WRAP_MODE_ELLIPSIS)
end

--Overridden from base
function ZO_ModBrowser_Gamepad:InitializeSortFilterList(...)
    ZO_GamepadInteractiveSortFilterList.InitializeSortFilterList(self, ...)
    ZO_ScrollList_AddDataType(self.list, MOD_DATA, "ZO_ModBrowser_ModRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(entryControl, entryData) self:SetupRow(entryControl, entryData) end)
end

--Overridden from base
function ZO_ModBrowser_Gamepad:InitializeSearchFilter()
    ZO_GamepadInteractiveSortFilterList.InitializeSearchFilter(self)
    
    self.searchEdit:SetDefaultText(GetString(SI_GAMEPAD_MOD_BROWSER_DEFAULT_SEARCH_TEXT))
    self.searchEdit:SetMaxInputChars(MOD_BROWSER_TEXT_SEARCH_MAX_LENGTH)
end

--Overridden from base
function ZO_ModBrowser_Gamepad:InitializeDropdownFilter()
    ZO_GamepadInteractiveSortFilterList.InitializeDropdownFilter(self)

    self.categoryDropdownEntries = ZO_MultiSelection_ComboBox_Data_Gamepad:New()

    local function OnCategoriesDropdownShown()
        local filterData = MOD_BROWSER_SEARCH_MANAGER:GetSearchFilters(self.searchType)
        --Track what the categories were prior to opening the dropdown
        self.oldCategories = {}
        ZO_DeepTableCopy(filterData:GetCategories(), self.oldCategories)
        table.sort(self.oldCategories)
    end

    local function CategorySelectionChanged()
        local newCategories = {}
        local selectedCategoryData = self.categoryDropdownEntries:GetSelectedItems()
        for _, item in ipairs(selectedCategoryData) do
            table.insert(newCategories, item.categoryValue)
        end
        local filterData = MOD_BROWSER_SEARCH_MANAGER:GetSearchFilters(self.searchType)
        filterData:SetCategories(newCategories)
    end

    for i = MOD_BROWSER_CATEGORY_TYPE_ITERATION_BEGIN, MOD_BROWSER_CATEGORY_TYPE_ITERATION_END do
        local categoryEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_MODBROWSERCATEGORYTYPE", i), CategorySelectionChanged)
        categoryEntry.categoryValue = i
        self.categoryDropdownEntries:AddItem(categoryEntry)
    end

    self.filterDropdown:SetSortsItems(true)
    self.filterDropdown:SetMaxSelections(MOD_BROWSER_CATEGORY_TYPE_MAX_VALUE + 1)
    self.filterDropdown:SetNoSelectionText(GetString(SI_GAMEPAD_MOD_BROWSER_CATEGORIES_DROPDOWN_NO_SELECTION_TEXT))
    self.filterDropdown:SetMultiSelectionTextFormatter(SI_GAMEPAD_MOD_BROWSER_CATEGORIES_DROPDOWN_TEXT_FORMATTER)
    self.filterDropdown:SetPreshowDropdownCallback(OnCategoriesDropdownShown)
    self.filterDropdown:LoadData(self.categoryDropdownEntries)
end

--Overridden from base
function ZO_ModBrowser_Gamepad:InitializeFilters()
    self.filterSwitcher = ZO_GamepadFocus:New(self.contentHeader, ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL))
    
    --Order matters; unlike the base class version of this function, we initialize the search filter first
    self:InitializeSearchFilter()
    self:InitializeDropdownFilter()

    local FocusChangedCallback = function()
        self.searchEdit:LoseFocus()
    end
    self.filterSwitcher:SetFocusChangedCallback(FocusChangedCallback)
end

--Overridden from base
function ZO_ModBrowser_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor = 
    {
        -- Addon Options
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            enabled = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local installState = selectedData:GetInstallState()
                    return installState ~= MOD_INSTALL_STATE_UNINSTALLING and installState ~= MOD_INSTALL_STATE_INSTALLING
                end

                return false
            end,
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return true
                end

                return false
            end,
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    ZO_Dialogs_ShowPlatformDialog("MOD_BROWSER_LISTING_OPTIONS_GAMEPAD", selectedData)
                end
            end,
        },
        -- Cycle Image Right
        {
            name = GetString(SI_GAMEPAD_MOD_BROWSER_CYCLE_IMAGE),
            keybind = "UI_SHORTCUT_INPUT_RIGHT",
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local numImages = selectedData:GetNumImages()
                    if numImages and numImages > 1 then
                        return true
                    end
                end
                return false
            end,
            callback = function()
                self:ShowNextImage()
            end,
        },
        -- Cycle Image Left
        {
            --This keybind intentionally does not have a name field, as the name field for UI_SHORTCUT_INPUT_RIGHT is sufficient for both
            keybind = "UI_SHORTCUT_INPUT_LEFT",
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local numImages = selectedData:GetNumImages()
                    if numImages and numImages > 1 then
                        return true
                    end
                end
                return false
            end,
            callback = function()
                self:ShowPreviousImage()
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() SCENE_MANAGER:HideCurrentScene() end)

    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)

    local eulaAndReloadKeybind =
    {
        name = function()
            if ZO_IsPregameUI() then
                return GetString(SI_ADDON_MANAGER_VIEW_EULA)
            else
                return HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and GetString(SI_ADDON_MANAGER_RELOAD) or GetString(SI_ADDON_MANAGER_VIEW_EULA)
            end
        end,
        keybind = "UI_SHORTCUT_SECONDARY",
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        visible = function()
            if ZO_IsPregameUI() then
                return not HasAgreedToEULA(EULA_TYPE_ADDON_EULA)
            else
                return true
            end
        end,
        enabled = function()
            if ZO_IsIngameUI() and HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                return ADDON_MANAGER_GAMEPAD:IsDirty()
            else
                return true
            end
        end,
        callback = function()
            if ZO_IsPregameUI() then
                self:ShowEula()
            else
                if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                    ReloadUI("ingame")
                else
                    self:ShowEula()
                end
            end
        end,
    }
    self:AddUniversalKeybind(eulaAndReloadKeybind)

    local updateAllKeybind =
    {
        name = function()
            local SKIP_IGNORE_UPDATES = true
            local numUpdates = GetNumModsWithUpdateAvailable(SKIP_IGNORE_UPDATES)
            return zo_strformat(SI_GAMEPAD_MOD_BROWSER_UPDATE_ALL, numUpdates)
        end,
        keybind = "UI_SHORTCUT_TERTIARY",
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        visible = function()
            local SKIP_IGNORE_UPDATES = true
            local numUpdates = GetNumModsWithUpdateAvailable(SKIP_IGNORE_UPDATES)
            return numUpdates > 0
        end,
        callback = function()
            UpdateAllInstalledMods()
        end,
    }
    self:AddUniversalKeybind(updateAllKeybind)
end

function ZO_ModBrowser_Gamepad:OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if ADDON_MANAGER_GAMEPAD:IsDirty() and bypassHideSceneConfirmationReason == nil then
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CONFIRM_LEAVE_ADDON_MANAGER",
        {
            confirmCallback = function()
                ReloadUI("ingame")
            end,
            declineCallback = function()
                scene:AcceptHideScene()
            end,
        })
    else
        scene:AcceptHideScene()
    end
end

function ZO_ModBrowser_Gamepad:ShowNextImage()
    local selectedData = self:GetSelectedData()
    if selectedData then
        local numImages = selectedData:GetNumImages()
        if numImages and numImages > 1 then
            local nextIndex = self.imageIndex + 1
            if nextIndex > numImages then
                nextIndex = 1
            end
            self.imageIndex = nextIndex
            self:UpdateTooltip()
            --The contents of the tooltip may have changed so we need to re-narrate
            self:NarrateSelection()
        end
    end
end

function ZO_ModBrowser_Gamepad:ShowPreviousImage()
    local selectedData = self:GetSelectedData()
    if selectedData then
        local numImages = selectedData:GetNumImages()
        if numImages and numImages > 1 then
            local nextIndex = self.imageIndex - 1
            if nextIndex < 1 then
                nextIndex = numImages
            end
            self.imageIndex = nextIndex
            self:UpdateTooltip()
            --The contents of the tooltip may have changed so we need to re-narrate
            self:NarrateSelection()
        end
    end
end

function ZO_ModBrowser_Gamepad:UpdateTooltip(resetImage, resetToTop)
    if self:IsShowing() then
        GAMEPAD_TOOLTIPS:SetTooltipResetScrollOnClear(GAMEPAD_RIGHT_TOOLTIP, resetToTop or false)
        if resetImage then
            self.imageIndex = 1
        end

        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        local selectedData = self:GetSelectedData()
        if selectedData then
            GAMEPAD_TOOLTIPS:LayoutModTooltip(GAMEPAD_RIGHT_TOOLTIP, selectedData, self.imageIndex)
        end
        GAMEPAD_TOOLTIPS:SetTooltipResetScrollOnClear(GAMEPAD_RIGHT_TOOLTIP, true)
    end
end

function ZO_ModBrowser_Gamepad:SetupRow(control, data)
    ZO_GamepadInteractiveSortFilterList.SetupRow(self, control, data)
    local modTitle = data:GetTitle()
    local USE_UPPERCASE_NUMBER_SUFFIXES = true
    local users = ZO_AbbreviateNumber(data:GetNumUsers(), NUMBER_ABBREVIATION_PRECISION_HUNDREDTHS, USE_UPPERCASE_NUMBER_SUFFIXES)

    control.modNameLabel:SetText(modTitle)
    control.usersLabel:SetText(users)
    control.categoryIcon:SetTexture(data:GetCategoryIcon())

    local installState = data:GetInstallState()
    local showLoadingIcon = false
    local showStateText = false

    if installState == MOD_INSTALL_STATE_UNINSTALLING or installState == MOD_INSTALL_STATE_INSTALLING then
        showLoadingIcon = true
    elseif installState ~= MOD_INSTALL_STATE_NOT_INSTALLED then
        showStateText = true
    end

    local installStateText
    --If updates are ignored show that instead of the install state text
    if data:IsInstalled() and data:GetIgnoreUpdates() then
        installStateText = GetString(SI_GAMEPAD_MOD_BROWSER_STATUS_UPDATES_IGNORED)
    else
        installStateText = data:GetInstallStateText()
        if installState == MOD_INSTALL_STATE_UPDATE_AVAILABLE then
            installStateText = ZO_SUCCEEDED_TEXT:Colorize(installStateText)
        end
    end

    control.installStateLabel:SetText(installStateText)
    control.installStateLabel:SetHidden(not showStateText)
    control.installStateLoadingIcon:SetHidden(not showLoadingIcon)
end

function ZO_ModBrowser_Gamepad:SetSearchType(searchType)
    self.searchType = searchType

    local DONT_SUPPRESS_CALLBACKS = nil
    local DONT_FORCE_RESELECT = nil
    if searchType == MOD_BROWSER_SEARCH_TYPE_BROWSE then
        self.sortHeaderGroup:SelectHeaderByKey("GetNumUsers", DONT_SUPPRESS_CALLBACKS, DONT_FORCE_RESELECT, ZO_SORT_ORDER_DOWN)
    else
        self.sortHeaderGroup:SelectHeaderByKey("GetTitle", DONT_SUPPRESS_CALLBACKS, DONT_FORCE_RESELECT, ZO_SORT_ORDER_UP)
    end

    if self:IsShowing() then
        self:RefreshSearchFilters()
        if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
            MOD_BROWSER_SEARCH_MANAGER:ExecuteSearch(self.searchType)
        end
    end
end

function ZO_ModBrowser_Gamepad:RefreshSearchFilters()
    local filterData = MOD_BROWSER_SEARCH_MANAGER:GetSearchFilters(self.searchType)
    if filterData then
        --Clear out the category dropdown and set it to match the current filters
        self.categoryDropdownEntries:ClearAllSelections()
        local categories = filterData:GetCategories()
        for _, item in ipairs(self.categoryDropdownEntries:GetAllItems()) do
            if ZO_IsElementInNumericallyIndexedTable(categories, item.categoryValue) then
                self.categoryDropdownEntries:SetItemSelected(item, true)
            end
        end
        self.filterDropdown:LoadData(self.categoryDropdownEntries)

        --Set the search box to match the current filters
        self.searchEdit:SetText(filterData:GetSearchText())
    end
end

function ZO_ModBrowser_Gamepad:OnModListingInstallStateChanged(installState)
    --If the install state of a listing has changed, a reload is necessary, so mark ourselves dirty
    --A reload is not necessary if the new state is UPDATE_AVAILABLE, as nothing has changed about the installed files
    if installState ~= MOD_INSTALL_STATE_UPDATE_AVAILABLE then
        ADDON_MANAGER_GAMEPAD:MarkDirty()
    end

    if self:IsShowing() then
        if self.searchType == MOD_BROWSER_SEARCH_TYPE_SUBSCRIBED then
            --If the search type is subscribed, a change of an install state could have caused the visible entries to change, so call RefreshFilters instead of RefreshVisible
            self:RefreshFilters()
        else
            self:RefreshVisible()
        end
        self:UpdateKeybinds()
        self:UpdateTooltip()
        if self:IsActivated() then
            self:NarrateSelection()
        end
    end
end

function ZO_ModBrowser_Gamepad:OnModListingImageLoadComplete(listingIndex, imageIndex, result)
    if self:IsShowing() then
        local selectedData = self:GetSelectedData()
        if selectedData and selectedData:GetListingIndex() == listingIndex and self.imageIndex == imageIndex then
            self:UpdateKeybinds()
            self:UpdateTooltip()
            --The contents of the tooltip may have changed so we need to re-narrate
            self:NarrateSelection()
        end
    end
end

function ZO_ModBrowser_Gamepad:OnModListingDependenciesLoadComplete(listingIndex, result)
    if self:IsShowing() then
        local selectedData = self:GetSelectedData()
        if selectedData and selectedData:GetListingIndex() == listingIndex then
            self:UpdateKeybinds()
            self:UpdateTooltip()
            --The contents of the tooltip may have changed so we need to re-narrate
            self:NarrateSelection()
        end
    end
end

function ZO_ModBrowser_Gamepad:RefreshReleaseNoteDialogTooltip(dialog)
    local targetData = dialog.entryList:GetTargetData()
    if targetData and targetData.tooltipFunction then
        targetData.tooltipFunction(dialog)
        ZO_GenericGamepadDialog_ShowTooltip(dialog)
    else
        ZO_GenericGamepadDialog_HideTooltip(dialog)
    end
end

function ZO_ModBrowser_Gamepad:OnModListingReleaseNoteLoadComplete(listingIndex, releaseIndex, result)
    if self:IsShowing() then
        local dialog = ZO_Dialogs_FindDialog("MOD_BROWSER_LISTING_RELEASE_NOTES_GAMEPAD")
        if dialog and dialog.data and dialog.data:GetListingIndex() == listingIndex then
            local targetData = dialog.entryList:GetTargetData()
            if targetData and targetData.releaseNoteIndex == releaseIndex then
                --If the release note dialog is showing and the listing/release index match, refresh the tooltip as the contents have changed
                self:RefreshReleaseNoteDialogTooltip(dialog)
            end
        end
    end
end

function ZO_ModBrowser_Gamepad:OnModListingReportSubmitted(result)
    --Use ZO_Dialogs_ReleaseAllDialogsOfName instead of ZO_Dialogs_ReleaseDialog in case the pending dialog hasn't started showing yet
    ZO_Dialogs_ReleaseAllDialogsOfName("MOD_BROWSER_REPORT_PENDING_DIALOG")

    local textParams =
    {
        titleParams = { GetString("SI_MODBROWSERLISTINGREPORTRESULT_RESULTDIALOGTITLE", result) },
        mainTextParams = { GetString("SI_MODBROWSERLISTINGREPORTRESULT_RESULTDIALOGMESSAGE", result) }
    }
    ZO_Dialogs_ShowPlatformDialog("MOD_BROWSER_REPORT_RESPONSE_DIALOG", nil, textParams)
end

function ZO_ModBrowser_Gamepad:OnConsoleAddOnsDisabledStateChanged(consoleAddOnsDisabled)
    if self:IsShowing() and consoleAddOnsDisabled then
        --If console addons were disabled, close all open dialogs and kick the player out of the screen
        local FORCE_CLOSE_DIALOGS = true
        ZO_Dialogs_ReleaseAllDialogs(FORCE_CLOSE_DIALOGS)
        SCENE_MANAGER:HideCurrentScene(ZO_BHSCR_ACCESS_FORBIDDEN)
    end
end

function ZO_ModBrowser_Gamepad:OnAddOnsDisabledStateChanged(addOnsDisabled)
    if self:IsShowing() and addOnsDisabled then
        --If addons were disabled, close all open dialogs and kick the player out of the screen
        local FORCE_CLOSE_DIALOGS = true
        ZO_Dialogs_ReleaseAllDialogs(FORCE_CLOSE_DIALOGS)
        SCENE_MANAGER:HideCurrentScene(ZO_BHSCR_ACCESS_FORBIDDEN)
    end
end

function ZO_ModBrowser_Gamepad:RefreshSearchState()
    local currentSearchState = MOD_BROWSER_SEARCH_MANAGER:GetSearchState()
    if currentSearchState == ZO_MOD_BROWSER_SEARCH_STATES.WAITING then
        self:SetEmptyText(GetString(SI_GAMEPAD_MOD_BROWSER_REFRESHING_RESULTS))
    elseif currentSearchState == ZO_MOD_BROWSER_SEARCH_STATES.COMPLETE or currentSearchState == ZO_MOD_BROWSER_SEARCH_STATES.NONE then
        self:SetEmptyText(GetString(SI_GAMEPAD_MOD_BROWSER_NO_RESULTS))
    elseif currentSearchState == ZO_MOD_BROWSER_SEARCH_STATES.FAILED then
        self:SetEmptyText(GetString(SI_GAMEPAD_MOD_BROWSER_SEARCH_FAILED))
    end
    self:UpdateKeybinds()
end

function ZO_ModBrowser_Gamepad:ShowEula()
    MarkEULAAsViewed(EULA_TYPE_ADDON_EULA)
    ZO_Dialogs_ShowPlatformDialog("ADDON_EULA_GAMEPAD", { finishedCallback = function() self:OnEulaHidden() end })
end

function ZO_ModBrowser_Gamepad:OnEulaHidden()
    if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
        --No need to mark ourselves dirty if the user doesn't have any addons
        if AddOnManager:GetNumAddOns() > 0 then
            ADDON_MANAGER_GAMEPAD:MarkDirty()
        end
        MOD_BROWSER_SEARCH_MANAGER:ExecuteSearch(self.searchType)
        --Fire this if the EULA was just accepted, as it would have failed upon first entering the screen
        OnModBrowserOpened()
    end
    self:UpdateKeybinds()
end

--Overridden from base
function ZO_ModBrowser_Gamepad:BuildMasterList()
    ZO_ClearNumericallyIndexedTable(self.masterList)

    local searchResults = MOD_BROWSER_SEARCH_MANAGER:GetSearchResults()
    for _, modListingData in ipairs(searchResults) do
        table.insert(self.masterList, modListingData)
    end
end

--Overridden from base
function ZO_ModBrowser_Gamepad:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for i, data in ipairs(self.masterList) do
        if self.searchType == MOD_BROWSER_SEARCH_TYPE_SUBSCRIBED then
            --Filter out not installed entries from the installed tab
            if data:GetInstallState() ~= MOD_INSTALL_STATE_NOT_INSTALLED then
                local entryData = ZO_EntryData:New(data)
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(MOD_DATA, entryData))
            end
        else
            local entryData = ZO_EntryData:New(data)
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(MOD_DATA, entryData))
        end
    end

    self:RefreshSearchState()
end

--Overridden from base
function ZO_ModBrowser_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.OnSelectionChanged(self, oldData, newData)
    --Order matters: Reset the image index to 1 when the selection changes
    local RESET_SELECTED_IMAGE = true
    local RESET_TO_TOP = true
    self:UpdateTooltip(RESET_SELECTED_IMAGE, RESET_TO_TOP)
    self:UpdateKeybinds()
end

--Overridden from base
function ZO_ModBrowser_Gamepad:OnFilterDeactivated()
    if self:IsShowing() then
        --Execute a search when the dropdown is closed if filters have changed
        local filterData = MOD_BROWSER_SEARCH_MANAGER:GetSearchFilters(self.searchType)
        local categories = filterData:GetCategories()
        table.sort(categories)
        if not ZO_AreNumericallyIndexedTablesEqual(categories, self.oldCategories) and HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
            MOD_BROWSER_SEARCH_MANAGER:ExecuteSearch(self.searchType)
        end
    end
end

--Overridden from base
function ZO_ModBrowser_Gamepad:OnSearchEditFocusLost()
    if self:IsShowing() then
        --Execute a search when leaving the search box if the text has changed
        local filterData = MOD_BROWSER_SEARCH_MANAGER:GetSearchFilters(self.searchType)
        local previousSearchText = filterData:GetSearchText()
        local newSearchText = self:GetCurrentSearch()
        if previousSearchText ~= newSearchText then
            filterData:SetSearchText(newSearchText)
            if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                MOD_BROWSER_SEARCH_MANAGER:ExecuteSearch(self.searchType)
            end
        end
    end
end

--Overridden from base
function ZO_ModBrowser_Gamepad:OnShowing()
    ZO_GamepadInteractiveSortFilterList.OnShowing(self)
    ZO_GamepadGenericHeader_Activate(self.contentHeader)
    self:RefreshData()
    self:Activate()
    self:RefreshHeader()
    if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
        OnModBrowserOpened()
    end
end

--Overridden from base
function ZO_ModBrowser_Gamepad:OnShown()
    if not HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
        self:ShowEula()
    end
end

--Overridden from base
function ZO_ModBrowser_Gamepad:OnHiding()
    ZO_GamepadInteractiveSortFilterList.OnHiding(self)
    ZO_GamepadGenericHeader_Deactivate(self.contentHeader)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
        OnModBrowserClosed()
    end
end

--Overridden from base
function ZO_ModBrowser_Gamepad:GetNarrationText()
    local narrations = {}
    local entryData = self:GetSelectedData()
    if entryData then
        --Get the narration for the category column
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MOD_BROWSER_CATEGORY_HEADER_NARRATION)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_MODBROWSERCATEGORYTYPE", entryData:GetCategory())))

        --Get the narration for the name column
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MOD_BROWSER_NAME_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetTitle()))

        --Get the narration for the users column
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MOD_BROWSER_USERS_HEADER)))
        local USE_UPPERCASE_NUMBER_SUFFIXES = true
        local users = ZO_AbbreviateNumber(entryData:GetNumUsers(), NUMBER_ABBREVIATION_PRECISION_HUNDREDTHS, USE_UPPERCASE_NUMBER_SUFFIXES)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(users))

        --Get the narration for the status column
        local installState = entryData:GetInstallState()
        --Dont narrate anything for the not installed case
        if installState ~= MOD_INSTALL_STATE_NOT_INSTALLED then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MOD_BROWSER_STATUS_HEADER)))
            if entryData:IsInstalled() and entryData:GetIgnoreUpdates() then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MOD_BROWSER_STATUS_UPDATES_IGNORED)))
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetInstallStateText()))
            end
        end
    end
    ZO_AppendNarration(narrations, self:GetEmptyRowNarration())
    return narrations
end

--Overridden from base
function ZO_ModBrowser_Gamepad:GetEmptyRowNarration()
    --Intentionally use the ZO_SortFilterList_Gamepad's version instead of the ZO_GamepadInteractiveSortFilterList's version
    return ZO_SortFilterList_Gamepad.GetEmptyRowNarration(self)
end

--Overridden from base
function ZO_ModBrowser_Gamepad:GetDropdownFilterControl()
    return self.contentHeader:GetNamedChild("CategoryFilter")
end

function ZO_ModBrowser_Gamepad:IsShowing()
    local listFragment = self:GetListFragment()
    if listFragment then
        return listFragment:IsShowing()
    end

    return false
end

function ZO_ModBrowser_Gamepad.OnControlInitialized(control)
    MOD_BROWSER_GAMEPAD = ZO_ModBrowser_Gamepad:New(control)
end

function ZO_ModBrowser_Gamepad.OnRowControlInitialized(control)
    control.modNameLabel = control:GetNamedChild("ModName")
    control.usersLabel = control:GetNamedChild("Users")
    control.categoryIcon = control:GetNamedChild("CategoryIcon")
    control.installStateLabel = control:GetNamedChild("InstallStateText")
    control.installStateLoadingIcon = control:GetNamedChild("InstallStateLoadingIcon")
end