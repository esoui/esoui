ZO_GAMEPAD_ADDON_MANAGER_ADDON_NAME_WIDTH = 500 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_AUTHOR_WIDTH = 545 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_EXTRA_INFO_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_ENABLED_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_HEADER_WIDTH = 1000

local ADDON_DATA = 1
local HEADER_DATA = 2

local AddOnManager = GetAddOnManager()

local SAVED_VARIABLE_DISK_USAGE_SMALL_THRESHOLD = 0.1

-----------------------------
--AddOn Menu Console
-----------------------------
ZO_AddOnMenu_Console = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_AddOnMenu_Console:Initialize(control)
    local NO_TAB_BAR = false
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, NO_TAB_BAR, ACTIVATE_ON_SHOW)
    self.headerData =
    {
        titleText = GetString(SI_GAME_MENU_ADDONS),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    --Use a parent fragment instead of a scene here since the SCENE_MANAGER doesn't exist yet
    local ALWAYS_ANIMATE = true
    local parentFragment = ZO_FadeSceneFragment:New(control, ALWAYS_ANIMATE)
    self:SetParentFragment(parentFragment)
    self.categoryList = self:GetMainList()

    EVENT_MANAGER:RegisterForEvent("AddOnMenu_Console", EVENT_CONSOLE_ADDONS_DISABLED_STATE_CHANGED, function()
        if self:IsShowing() then
            self:RefreshList()
        end
    end)

    EVENT_MANAGER:RegisterForEvent("AddOnMenu_Console", EVENT_MOD_INSTALL_STATE_CHANGED, function()
        if self:IsShowing() then
            self:RefreshFooter()
        end
    end)
end

--Overridden from base
function ZO_AddOnMenu_Console:OnDeferredInitialize()
    self:InitializeFooter()
end

function ZO_AddOnMenu_Console:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            visible = function()
                local targetData = self.categoryList:GetTargetData()
                if targetData then
                    return true
                end

                return false
            end,
            enabled = function()
                local targetData = self.categoryList:GetTargetData()
                if targetData then
                    return targetData:IsEnabled()
                end
                return false
            end,
            callback = function()
                local targetData = self.categoryList:GetTargetData()
                if targetData and targetData.callback then
                    targetData.callback()
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() SCENE_MANAGER:HideCurrentScene() end)
end

function ZO_AddOnMenu_Console:InitializeFooter()
    local DISK_USAGE_ALMOST_FULL_THRESHOLD = 0.9

    if DoesPlatformSupportModBrowser() then
        self.footerData =
        {
            data1Text = function()
                local currentDiskUsage = GetTotalModDiskUsageMB()
                local maxDiskUsage = GetTotalModDiskCapacityMB()

                local formattedText = zo_strformat(SI_GAMEPAD_ADDON_MENU_DISK_USAGE_FORMATTER, currentDiskUsage, maxDiskUsage)

                if currentDiskUsage / maxDiskUsage >= DISK_USAGE_ALMOST_FULL_THRESHOLD then
                    formattedText = ZO_ERROR_COLOR:Colorize(formattedText)
                end

                return formattedText
            end,
            data1TextNarration = function()
                local currentDiskUsage = GetTotalModDiskUsageMB()
                local maxDiskUsage = GetTotalModDiskCapacityMB()

                return zo_strformat(SI_SCREEN_NARRATION_ADDON_MENU_DISK_USAGE_FORMATTER, currentDiskUsage, maxDiskUsage)
            end,
        }
    else
        self.footerData = {}
    end
end

function ZO_AddOnMenu_Console:RefreshList()
    local list = self.categoryList
    list:Clear()

    --Add the option for the addon manager
    local managerEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_ADDON_MENU_CATEGORY_ADDON_MANAGER), "EsoUI/Art/Addons/Gamepad/gp_addons_manage.dds")
    managerEntryData:SetIconTintOnSelection(true)
    managerEntryData:SetEnabled(true)
    managerEntryData.callback = function() SCENE_MANAGER:Push("gamepad_addons") end

    list:AddEntry("ZO_GamepadMenuEntryTemplate", managerEntryData)

    --Add the option for the mod browser
    local browseEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_ADDON_MENU_CATEGORY_MOD_BROWSER), "EsoUI/Art/Addons/Gamepad/gp_addons_browse.dds")
    browseEntryData:SetIconTintOnSelection(true)
    local enabled = DoesPlatformSupportModBrowser() and AreUserAddOnsSupported()
    browseEntryData:SetEnabled(enabled)
    browseEntryData.callback = function() SCENE_MANAGER:Push("modBrowserGamepad") end
    browseEntryData.tooltipText = function()
        if enabled then
            return GetString(SI_GAMEPAD_ADDON_MENU_MOD_BROWSER_TOOLTIP) 
        else
            return GetString(SI_GAMEPAD_ADDON_MENU_MOD_BROWSER_UNAVAILABLE_TOOLTIP)
        end
    end

    list:AddEntry("ZO_GamepadMenuEntryTemplate", browseEntryData)

    list:Commit()
end

--Overridden from base
function ZO_AddOnMenu_Console:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:RefreshList()
    self:RefreshFooter()
end

--Overridden from base
function ZO_AddOnMenu_Console:PerformUpdate()
   self.dirty = false
end

--Overridden from base
function ZO_AddOnMenu_Console:OnSelectionChanged(list, selectedData, oldSelectedData)
    ZO_Gamepad_ParametricList_Screen.OnSelectionChanged(self, list, selectedData, oldSelectedData)

    local tooltipText
    if selectedData and selectedData.tooltipText then
        tooltipText = selectedData.tooltipText()
    end

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    if tooltipText then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, tooltipText)
    end
end

function ZO_AddOnMenu_Console:GetParentFragment()
    return self.parentFragment
end

function ZO_AddOnMenu_Console:RefreshFooter()
    if self:IsShowing() then
        GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
    end
end

--Overridden from base
function ZO_AddOnMenu_Console:GetFooterNarration()
    if GAMEPAD_GENERIC_FOOTER_FRAGMENT:IsShowing() then
        return GAMEPAD_GENERIC_FOOTER:GetNarrationText(self.footerData)
    end
end

function ZO_AddOnMenu_Console.OnControlInitialized(control)
    ADDON_MENU_CONSOLE = ZO_AddOnMenu_Console:New(control)
end

-----------------------------
--AddOn Manager Gamepad
-----------------------------

ZO_AddOnManager_Gamepad = ZO_DeferredInitializingObject:MultiSubclass(ZO_SortFilterList_Gamepad)

function ZO_AddOnManager_Gamepad:Initialize(control)
    ZO_SortFilterList_Gamepad.Initialize(self, control)

    self.isDirty = false
    self.addonList = {}
    self.libraryList = {}
    ADDON_MANAGER_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    self.filterLabel = control:GetNamedChild("TitleContainerSubTitle")
    self.emptyLabel = control:GetNamedChild("EmptyLabel")

    ZO_DeferredInitializingObject.Initialize(self, ADDON_MANAGER_GAMEPAD_FRAGMENT)
    self:SetAutomaticallyColorRows(false)
    --Only display in the options menu if user addons are supported
    self.shouldShowInOptions = AreUserAddOnsSupported()

    local optionsEntryData = ZO_GamepadEntryData:New(GetString(SI_GAME_MENU_ADDONS), "EsoUI/Art/Options/Gamepad/gp_options_addons.dds")
    optionsEntryData.sortOrder = ZO_GAMEPAD_OPTIONS_CATEGORY_SORT_ORDER[SETTING_PANEL_ACCOUNT] + 1
    optionsEntryData:SetIconTintOnSelection(true)
    optionsEntryData.visible = function()
        if ZO_IsPregameUI() then
            return IsAccountLoggedIn() and AreUserAddOnsSupported()
        else
            return self.shouldShowInOptions
        end
    end
    optionsEntryData.callback = function()
        if DoesPlatformSupportModBrowser() or ZO_IsForceConsoleFlow() then
            SCENE_MANAGER:Push("console_addons")
        else
            SCENE_MANAGER:Push("gamepad_addons")
        end
    end
    GAMEPAD_OPTIONS:RegisterCustomCategory(optionsEntryData)

    --We need to register this function right away as the value is necessary before the deferred initialize gets run
    local function OnConsoleAddOnsDisabledStateChanged(_, consoleAddOnsDisabled)
        if not consoleAddOnsDisabled then
            self.shouldShowInOptions = true
        end
    end
    EVENT_MANAGER:RegisterForEvent("AddOnManager_Gamepad", EVENT_CONSOLE_ADDONS_DISABLED_STATE_CHANGED, OnConsoleAddOnsDisabledStateChanged)
end

function ZO_AddOnManager_Gamepad:OnDeferredInitialize()
    self:RegisterForEvents()
    self:RegisterDialogs()
    self:InitializeKeybinds()
    self:InitializeFooter()
end

function ZO_AddOnManager_Gamepad:RegisterForEvents()
    local function OnForceDisabledAddonsUpdated()
        if self:IsShowing() then
            self:RefreshVisible()
            self:UpdateKeybinds()
            self:UpdateTooltip()
        end
    end
    EVENT_MANAGER:RegisterForEvent("AddOnManager_Gamepad", EVENT_FORCE_DISABLED_ADDONS_UPDATED, OnForceDisabledAddonsUpdated)

    CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", function() self:OnAllDialogsHidden() end)

    -- We only need to do a hide scene confirmation in ingame UI
    if ZO_IsIngameUI() then
        GAMEPAD_ADDON_MANAGER_SCENE:SetHideSceneConfirmationCallback(function(...) self:OnConfirmHideScene(...) end)
    end
end

function ZO_AddOnManager_Gamepad:RegisterDialogs()
    local function OnReleaseDialog(dialog)
        --Make sure we deactivate any open dropdowns when the dialog closes
        local targetControl = dialog.entryList:GetTargetControl()
        if targetControl and targetControl.dropdown then
            targetControl.dropdown:Deactivate()
        end
    end

    ZO_Dialogs_RegisterCustomDialog("ADDON_MANAGER_OPTIONS_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_OPTIONS_MENU,
        },
        setup = function(dialogControl, addOnData)
            local parametricListEntries = dialogControl.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)

            --If we are in pregame, then include the character dropdown filter
            if ZO_IsPregameUI() and self.characterData then
                local filterEntry =
                {
                    template = "ZO_GamepadDropdownItem",
                    templateData =
                    {
                        setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                            local dialog = data.dialog
                            local dropdown = control.dropdown

                            dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                            dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                            dropdown:SetSelectedItemTextColor(selected)

                            dropdown:SetSortsItems(false)
                            dropdown:ClearItems()

                            local function OnSelectedCallback(entryDropdown, entryText, entry)
                                self.selectedCharacterEntry = entry
                                self:RefreshData()
                                self:RefreshHeader()
                            end

                            local entryToSelect

                            local allCharactersEntry = dropdown:CreateItemEntry(GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL), OnSelectedCallback)
                            allCharactersEntry.allCharacters = true
                            dropdown:AddItem(allCharactersEntry)
                            if self.selectedCharacterEntry.allCharacters then
                                entryToSelect = allCharactersEntry
                            end

                            local characterNames = {}
                            for i, characterData in ipairs(self.characterData) do
                                local name = zo_strformat(SI_UNIT_NAME, characterData.name)
                                table.insert(characterNames, name)
                            end
                            table.sort(characterNames)

                            for _, characterName in ipairs(characterNames) do
                                local entry = dropdown:CreateItemEntry(characterName, OnSelectedCallback)
                                entry.allCharacters = false
                                if self.selectedCharacterEntry.name == characterName then
                                    entryToSelect = entry
                                end
                                dropdown:AddItem(entry)
                            end

                            local IGNORE_CALLBACK = true
                            dropdown:TrySelectItemByData(entryToSelect, IGNORE_CALLBACK)

                            SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, dropdown)
                        end,
                        callback = function(dialog)
                            local targetControl = dialog.entryList:GetTargetControl()
                            targetControl.dropdown:Activate()
                        end,
                        narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                    }
                }
                table.insert(parametricListEntries, filterEntry)
            end

            --Toggle all addons
            local toggleAddonsCheckboxEntry =
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                text = GetString(SI_GAMEPAD_ADDON_MANAGER_TOGGLE_ALL_ADDONS),
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        if targetControl then
                            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                            AddOnManager:SetAddOnsEnabled(ZO_GamepadCheckBoxTemplate_IsChecked(targetControl))
                            self:MarkDirty()
                            self:RefreshData()
                            SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                        end
                    end,
                    checked = function()
                        return AddOnManager:AreAddOnsEnabled()
                    end,
                    narrationText = ZO_GetDefaultParametricListToggleNarrationText,
                },
            }
            table.insert(parametricListEntries, toggleAddonsCheckboxEntry)

            --Toggle Advanced UI Errors
            local advancedUIErrorsCheckboxEntry =
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                text = GetString(SI_ADDON_MANAGER_ADVANCED_UI_ERRORS),
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        if targetControl then
                            ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                            SetCVar("UIErrorAdvancedView", ZO_GamepadCheckBoxTemplate_IsChecked(targetControl) and "1" or "0")
                            SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                        end
                    end,
                    checked = function()
                        return GetCVar("UIErrorAdvancedView") == "1"
                    end,
                    narrationText = ZO_GetDefaultParametricListToggleNarrationText,
                },
            }
            table.insert(parametricListEntries, advancedUIErrorsCheckboxEntry)

            --Custom keybinds are an ingame only thing. We also dont need this on consoles as custom keybinds are not currently allowed there
            if ZO_IsIngameUI() and not IsConsoleUI() then
                --Reset custom keybinds
                local resetCustomKeybindsEntry =
                {
                    template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
                    templateData =
                    {
                        text = GetString(SI_CLEAR_UNUSED_KEYBINDS_KEYBIND),
                        setup = ZO_SharedGamepadEntry_OnSetup,
                        callback = function(dialog)
                            ZO_Dialogs_ShowPlatformDialog("CONFIRM_CLEAR_UNUSED_KEYBINDS")
                            ZO_Dialogs_ReleaseDialogOnButtonPress("ADDON_MANAGER_OPTIONS_GAMEPAD")
                        end,
                    },
                }
                table.insert(parametricListEntries, resetCustomKeybindsEntry)
            end

            --If there are unused addon saved variables, show an option to clear them
            local unusedSavedVariableUsage = AddOnManager:GetTotalUnusedAddOnSavedVariablesDiskUsageMB()
            if unusedSavedVariableUsage > 0 then
                --Delete Unused Saved Variables
                local deleteUnusedSavedVariablesEntry =
                {
                    template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
                    templateData =
                    {
                        text = GetString(SI_GAMEPAD_ADDON_MANAGER_DELETE_UNUSED_SAVED_VARIABLES),
                        setup = ZO_SharedGamepadEntry_OnSetup,
                        callback = function(dialog)
                            ZO_Dialogs_ReleaseDialogOnButtonPress("ADDON_MANAGER_OPTIONS_GAMEPAD")
                            local dialogData =
                            {
                                onConfirmCallback = function()
                                    AddOnManager:ClearUnusedAddOnSavedVariables()
                                end,
                            }
                            ZO_Dialogs_ShowGamepadDialog("ADDON_DELETE_UNUSED_SAVED_VARIABLES_CONFIRMATION", dialogData)
                        end,
                        tooltipText = function(dialog)
                            local savedVariableDiskUsage = AddOnManager:GetTotalUnusedAddOnSavedVariablesDiskUsageMB()
                            local formattedUsageText
                            if savedVariableDiskUsage > 0 and savedVariableDiskUsage < SAVED_VARIABLE_DISK_USAGE_SMALL_THRESHOLD then
                                formattedUsageText = GetString(SI_GAMEPAD_ADDON_MANAGER_SAVED_VARIABLES_USAGE_SMALL)
                            else
                                formattedUsageText = zo_strformat(SI_GAMEPAD_ADDON_MANAGER_SAVED_VARIABLES_USAGE_FORMATTER, savedVariableDiskUsage)
                            end
                            return ZO_GenerateParagraphSeparatedList({ GetString(SI_GAMEPAD_ADDON_MANAGER_DELETE_UNUSED_SAVED_VARIABLES_TOOLTIP), formattedUsageText })
                        end,
                        narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                    },
                }
                table.insert(parametricListEntries, deleteUnusedSavedVariablesEntry)
            end

            --If there is a selected addon, include an option to delete saved variables
            if addOnData and addOnData.addOnIndex then
                local savedVariableUsage = AddOnManager:GetUserAddOnSavedVariablesDiskUsageMB(addOnData.addOnIndex)
                if savedVariableUsage > 0 then
                    --Delete Saved Variables
                    local deleteSavedVariablesEntry =
                    {
                        template = "ZO_AddonManagerDeleteSavedVariablesEntryTemplate",
                        headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                        header = function(dialog)
                            return dialog.data.strippedAddOnName
                        end,
                        templateData =
                        {
                            text = GetString(SI_GAMEPAD_ADDON_MANAGER_DELETE_SAVED_VARIABLES),
                            setup = ZO_SharedGamepadEntry_OnSetup,
                            callback = function(dialog)
                                ZO_Dialogs_ReleaseDialogOnButtonPress("ADDON_MANAGER_OPTIONS_GAMEPAD")
                                local dialogData =
                                {
                                    onConfirmCallback = function()
                                        DeleteSavedVariablesForAddonIndex(dialog.data.addOnIndex)
                                    end,
                                    addonName = dialog.data.strippedAddOnName,
                                }
                                ZO_Dialogs_ShowGamepadDialog("ADDON_DELETE_SAVED_VARIABLES_CONFIRMATION", dialogData)
                            end,
                            tooltipText = function(dialog)
                                local savedVariableDiskUsage = AddOnManager:GetUserAddOnSavedVariablesDiskUsageMB(dialog.data.addOnIndex)
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
                    table.insert(parametricListEntries, deleteSavedVariablesEntry)
                end
            end

            dialogControl:setupFunc()
        end,
        parametricList = {}, -- Generated Dynamically
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
                text = SI_DIALOG_CLOSE,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("ADDON_MANAGER_OPTIONS_GAMEPAD")
                end,
            },
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })
end

function ZO_AddOnManager_Gamepad:InitializeFooter()
    --Custom keybinds are not supported on consoles
    if not IsConsoleUI() then
        self.footerData =
        {
            data1Text = function()
                local maxCustomBinds = GetMaxNumSavedKeybindings()
                local currentNumSavedBindings = GetNumSavedKeybindings()

                local bindText = zo_strformat(SI_KEYBINDINGS_CURRENT_SAVED_BIND_COUNT, currentNumSavedBindings, maxCustomBinds)
                local color = ZO_NORMAL_TEXT
                if currentNumSavedBindings >= maxCustomBinds then
                    color = ZO_ERROR_COLOR
                end
                return color:Colorize(bindText)
            end,
        }
    else
        self.footerData = {}
    end
end

function ZO_AddOnManager_Gamepad:OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if ZO_IsIngameUI() and self:IsDirty() and bypassHideSceneConfirmationReason == nil then
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

--Overridden from base
function ZO_AddOnManager_Gamepad:InitializeSortFilterList(...)
    ZO_SortFilterList_Gamepad.InitializeSortFilterList(self, ...)
    ZO_ScrollList_AddDataType(self.list, ADDON_DATA, "ZO_AddonManager_AddonRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(entryControl, entryData) self:SetupRow(entryControl, entryData) end)

    local function SetupHeader(entryControl, entryData)
        entryControl.nameLabel:SetText(entryData.name)
    end
    ZO_ScrollList_AddDataType(self.list, HEADER_DATA, "ZO_AddonManager_HeaderRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, SetupHeader)
    ZO_ScrollList_SetTypeSelectable(self.list, HEADER_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(self.list, HEADER_DATA, true)
end

function ZO_AddOnManager_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Previous Section
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Addon Manager Previous Section",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollUp(self.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.list, ZO_SCROLL_SELECT_CATEGORY_PREVIOUS)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS])
                end
            end
        },
        -- Next Section
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Addon Manager Next Section",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollDown(self.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.list, ZO_SCROLL_SELECT_CATEGORY_NEXT)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT])
                end
            end
        },
        -- Toggle Addon
        {
            name = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local enabled
                    if self:IsSpecificCharacterSelected() then
                        enabled = select(5, AddOnManager:GetAddOnInfo(selectedData.addOnIndex))
                    else
                        local allEnabled = self:GetCombinedAddOnStates(selectedData.addOnIndex)
                        enabled = allEnabled
                    end

                    if enabled then
                        return GetString(SI_GAMEPAD_ADDON_MANAGER_DISABLE_ADDON)
                    else
                        return GetString(SI_GAMEPAD_ADDON_MANAGER_ENABLE_ADDON)
                    end
                end
                return ""
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                return AddOnManager:AreAddOnsEnabled()
            end,
            visible = function()
                local shouldShow = false
                local selectedData = self:GetSelectedData()
                if selectedData then
                    --Only do the dependency error check if the "all characters" filter is not selected
                    shouldShow = HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and (not self:IsSpecificCharacterSelected() or not selectedData.hasDependencyError)
                end
                return shouldShow
            end,
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local enabled
                    if self:IsSpecificCharacterSelected() then
                        enabled = select(5, AddOnManager:GetAddOnInfo(selectedData.addOnIndex))
                    else
                        local allEnabled = self:GetCombinedAddOnStates(selectedData.addOnIndex)
                        enabled = allEnabled
                    end
                    AddOnManager:SetAddOnEnabled(selectedData.addOnIndex, not enabled)
                    self:MarkDirty()
                    self:RefreshVisible()
                    self:UpdateTooltip()
                    self:UpdateKeybinds()
                    -- The enabled state has changed, so re-narrate
                    SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self)
                end
            end,
        },
        -- Reload UI / EULA
        {
            name = function()
                if ZO_IsPregameUI() then
                    return GetString(SI_ADDON_MANAGER_VIEW_EULA)
                else
                    return HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and GetString(SI_ADDON_MANAGER_RELOAD) or GetString(SI_ADDON_MANAGER_VIEW_EULA)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                if ZO_IsPregameUI() then
                    return not HasAgreedToEULA(EULA_TYPE_ADDON_EULA)
                else
                    return true
                end
            end,
            enabled = function()
                if ZO_IsIngameUI() and HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                    return self:IsDirty()
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
        },
        -- Options
        {
            name = GetString(SI_GAMEPAD_OPTIONS_MENU),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ZO_Dialogs_ShowPlatformDialog("ADDON_MANAGER_OPTIONS_GAMEPAD", self:GetSelectedData())
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())
end

function ZO_AddOnManager_Gamepad:GetBackKeybindCallback()
    return function() SCENE_MANAGER:HideCurrentScene() end
end

do
    local g_uniqueNamesByCharacterName = {}

    local function CreateAddOnFilter(characterName)
        local uniqueName = g_uniqueNamesByCharacterName[characterName]
        if not uniqueName then
            uniqueName = GetUniqueNameForCharacter(characterName)
            g_uniqueNamesByCharacterName[characterName] = uniqueName
        end
        return uniqueName
    end

    local function StripText(text)
        return text:gsub("|c%x%x%x%x%x%x", "")
    end

    --Overridden from base
    function ZO_AddOnManager_Gamepad:BuildMasterList()
        ZO_ClearNumericallyIndexedTable(self.libraryList)
        ZO_ClearNumericallyIndexedTable(self.addonList)

        if self:IsSpecificCharacterSelected() then
            AddOnManager:SetAddOnFilter(CreateAddOnFilter(self.selectedCharacterEntry.name))
        else
            AddOnManager:RemoveAddOnFilter()
        end

        local numAddons = AddOnManager:GetNumAddOns()
        for i = 1, numAddons do
            local name, title, author, _, _, _, _, isLibrary = AddOnManager:GetAddOnInfo(i)
            local entryData =
            {
                addOnIndex = i,
                addOnFileName = name,
                addOnName = title,
                strippedAddOnName = StripText(title),
                isLibrary = isLibrary,
            }

            if author ~= "" then
                local strippedAuthor = StripText(author)
                entryData.addOnAuthor = author
                entryData.addOnAuthorByLine = zo_strformat(SI_ADD_ON_AUTHOR_LINE, author)
                entryData.strippedAddOnAuthorByLine = zo_strformat(SI_ADD_ON_AUTHOR_LINE, strippedAuthor)
            else
                entryData.addOnAuthor = ""
                entryData.addOnAuthorByLine = ""
                entryData.strippedAddOnAuthorByLine = ""
            end

            local areAddOnsEnabled = AddOnManager:AreAddOnsEnabled()
            local dependencyText = ""
            for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
                local dependencyName, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion = AddOnManager:GetAddOnDependencyInfo(i, j)
                local dependencyTooLowVersion = dependencyVersion < dependencyMinVersion
                local dependencyInfoLine = dependencyName
                if self:IsSpecificCharacterSelected() and (not dependencyActive or not dependencyExists or dependencyTooLowVersion) then
                    entryData.hasDependencyError = true
                    if not dependencyExists then
                        dependencyInfoLine = zo_strformat(SI_ADDON_MANAGER_DEPENDENCY_MISSING, dependencyName)
                    elseif not dependencyActive or not areAddOnsEnabled then
                        dependencyInfoLine = zo_strformat(SI_ADDON_MANAGER_DEPENDENCY_DISABLED, dependencyName)
                    elseif dependencyTooLowVersion then
                        dependencyInfoLine = zo_strformat(SI_ADDON_MANAGER_DEPENDENCY_TOO_LOW_VERSION, dependencyName)
                    end
                    dependencyInfoLine = ZO_ERROR_COLOR:Colorize(dependencyInfoLine)
                end

                if dependencyText == "" then
                    dependencyText = string.format("%s  %s", GetString(SI_BULLET), dependencyInfoLine)
                else
                    dependencyText = string.format("%s\n%s  %s", dependencyText, GetString(SI_BULLET), dependencyInfoLine)
                end
            end
            entryData.addOnDependencyText = dependencyText

            if isLibrary then
                table.insert(self.libraryList, entryData)
            else
                table.insert(self.addonList, entryData)
            end
        end
    end

    function ZO_AddOnManager_Gamepad:SetCharacterData(characterData)
        self.characterData = characterData
        AddOnManager:ResetRelevantFilters()
        if self.characterData then
            for i, data in ipairs(self.characterData) do
                AddOnManager:AddRelevantFilter(CreateAddOnFilter(data.name))
            end
        end
    end

    function ZO_AddOnManager_Gamepad:RefreshCharacterData()
        if ZO_IsPregameUI() then
            self:SetCharacterData(CHARACTER_SELECT_MANAGER:GetCharacterDataList())
            self.selectedCharacterEntry =
            {
                name = GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL),
                allCharacters = true,
            }
        else
            local playerName = GetUnitName("player")
            self.selectedCharacterEntry =
            {
                name = playerName ~= "" and playerName or nil,
                allCharacters = false,
            }
        end
    end

    function ZO_AddOnManager_Gamepad:GetCombinedAddOnStates(index)
        local allEnabled = true
        local allDisabled = true

        if not self:IsSpecificCharacterSelected() and self.characterData then
            for i, data in ipairs(self.characterData) do
                local filter = CreateAddOnFilter(data.name)
                AddOnManager:SetAddOnFilter(filter)
                local enabled = select(5, AddOnManager:GetAddOnInfo(index))
                if enabled then
                    allDisabled = false
                else
                    allEnabled = false
                end
            end
            
            AddOnManager:RemoveAddOnFilter()
        end

        return allEnabled, allDisabled
    end
end

function ZO_AddOnManager_Gamepad:UpdateTooltip()
    if self:IsShowing() then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        local selectedData = self:GetSelectedData()
        if selectedData then
            GAMEPAD_TOOLTIPS:LayoutAddOnTooltip(GAMEPAD_RIGHT_TOOLTIP, selectedData, self:IsSpecificCharacterSelected())
        end
    end
end

do
    local ADDON_ACTIVE_TEXTURE = "EsoUI/Art/Addons/Gamepad/gp_addon_active.dds"
    local ADDON_ACTIVE_PARTIAL_TEXTURE = "EsoUI/Art/Addons/Gamepad/gp_addon_active_partial.dds"

    function ZO_AddOnManager_Gamepad:SetupRow(control, data)
        local addOnIndex = data.addOnIndex
        local hasDependencyError = data.hasDependencyError

        local canEnable = HasAgreedToEULA(EULA_TYPE_ADDON_EULA)

        local enabled = select(5, AddOnManager:GetAddOnInfo(addOnIndex))
        local showDisabled = not enabled

        if self:IsSpecificCharacterSelected() then
            control.enabledControl:SetHidden(not enabled or hasDependencyError)
            control.enabledIcon:SetTexture(ADDON_ACTIVE_TEXTURE)
            canEnable = canEnable and not hasDependencyError
        else
            local allEnabled, allDisabled = self:GetCombinedAddOnStates(addOnIndex)
            if allEnabled then
                control.enabledControl:SetHidden(false)
                control.enabledIcon:SetTexture(ADDON_ACTIVE_TEXTURE)
            elseif allDisabled then
                control.enabledControl:SetHidden(true)
            else
                control.enabledControl:SetHidden(false)
                control.enabledIcon:SetTexture(ADDON_ACTIVE_PARTIAL_TEXTURE)
            end
            showDisabled = allDisabled

            data.allEnabled = allEnabled
            data.allDisabled = allDisabled
        end

        local color
        local stripColorMarkup
        if not canEnable then
            color = ZO_ERROR_COLOR
            stripColorMarkup = true
        elseif showDisabled or not AddOnManager:AreAddOnsEnabled() then
            color = ZO_DEFAULT_DISABLED_COLOR
            stripColorMarkup = true
        else
            color = ZO_DEFAULT_ENABLED_COLOR
            stripColorMarkup = false
        end

        control.addonNameLabel:SetColor(color:UnpackRGBA())
        control.authorNameLabel:SetColor(color:UnpackRGBA())

        control.addonNameLabel:SetText(stripColorMarkup and data.strippedAddOnName or data.addOnName)
        control.authorNameLabel:SetText(stripColorMarkup and data.strippedAddOnAuthorByLine or data.addOnAuthorByLine)

        control.dependencyIcon:SetHidden(not hasDependencyError)
    end
end

function ZO_AddOnManager_Gamepad:IsSpecificCharacterSelected()
    return self.selectedCharacterEntry and not self.selectedCharacterEntry.allCharacters
end

function ZO_AddOnManager_Gamepad:ShowEula()
    MarkEULAAsViewed(EULA_TYPE_ADDON_EULA)
    ZO_Dialogs_ShowPlatformDialog("ADDON_EULA_GAMEPAD", { finishedCallback = function() self:OnEulaHidden() end })
end

function ZO_AddOnManager_Gamepad:OnEulaHidden()
    --There's no need to mark anything dirty if the user has no addons or didn't actually agree to the EULA
    if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and AddOnManager:GetNumAddOns() > 0 then
        self:MarkDirty()
    end
    self:RefreshData()
    self:UpdateKeybinds()
end

function ZO_AddOnManager_Gamepad:MarkDirty()
    self.isDirty = true
end

function ZO_AddOnManager_Gamepad:IsDirty()
    return self.isDirty
end

function ZO_AddOnManager_Gamepad:RefreshHeader()
    if ZO_IsPregameUI() then
        if self.selectedCharacterEntry then
            self.filterLabel:SetText(self.selectedCharacterEntry.name)
        end
        self.filterLabel:SetHidden(false)
    else
        self.filterLabel:SetHidden(true)
    end
end

function ZO_AddOnManager_Gamepad:RefreshFooter()
    if ZO_IsIngameUI() and self:IsShowing() then
        GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
    end
end

function ZO_AddOnManager_Gamepad:OnAllDialogsHidden()
    if self:IsActivated() then
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueSortFilterListEntry(self, NARRATE_HEADER)
    end
end

do
    local SORT_KEYS =
    {
        addOnFileName = {},
        strippedAddOnName = { tiebreaker = "addOnFileName" },
    }

    local function SortAddons(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "strippedAddOnName", SORT_KEYS, ZO_SORT_ORDER_UP)
    end

    --Overridden from base
    function ZO_AddOnManager_Gamepad:FilterScrollList()
        -- No real filtering...just show everything in the lists
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        ZO_ClearNumericallyIndexedTable(scrollData)
        local hasEntries = false

        if #self.addonList > 0 then
            hasEntries = true
            local addonHeaderData =
            {
                name = GetString(SI_WINDOW_TITLE_ADDON_MANAGER),
            }
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(HEADER_DATA, ZO_EntryData:New(addonHeaderData)))

            table.sort(self.addonList, SortAddons)
            for i, data in ipairs(self.addonList) do
                local entryData = ZO_EntryData:New(data)
                local headerText = nil
                if i == 1 then
                    headerText = addonHeaderData.name
                end
                entryData.headerText = headerText
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ADDON_DATA, entryData))
            end
        end

        if #self.libraryList > 0 then
            hasEntries = true
            local libraryHeaderData =
            {
                name = GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES),
            }
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(HEADER_DATA, ZO_EntryData:New(libraryHeaderData)))

            table.sort(self.libraryList, SortAddons)
            for i, data in ipairs(self.libraryList) do
                local entryData = ZO_EntryData:New(data)
                local headerText = nil
                if i == 1 then
                    headerText = libraryHeaderData.name
                end
                entryData.headerText = headerText
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ADDON_DATA, entryData))
            end
        end

        self.emptyLabel:SetHidden(hasEntries)
    end
end

--Overridden from base
function ZO_AddOnManager_Gamepad:CommitScrollList()
    ZO_SortFilterList_Gamepad.CommitScrollList(self)
    if self:IsActivated() then
        local ANIMATE_INSTANTLY = true
        local selectedData = self:GetSelectedData()
        if selectedData then
            -- Make sure our selection is in view
            local NO_CALLBACK = nil
            ZO_ScrollList_ScrollDataIntoView(self.list, ZO_ScrollList_GetSelectedDataIndex(self.list), NO_CALLBACK, ANIMATE_INSTANTLY)
        else
            -- If we've lost our selection, then we want to AutoSelect the next appropriate entry
            ZO_ScrollList_AutoSelectData(self.list, ANIMATE_INSTANTLY)
        end
    end
end

--Overridden from base
function ZO_AddOnManager_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)
    self:UpdateTooltip()
end

--Overridden from base
function ZO_AddOnManager_Gamepad:UpdateKeybinds()
    ZO_SortFilterList_Gamepad.UpdateKeybinds(self)
    self:RefreshFooter()
end

--Overridden from base
function ZO_AddOnManager_Gamepad:OnShowing()
    self:RefreshCharacterData()
    self:RefreshData()
    self:Activate()
    self:AddKeybinds()
    self:RefreshHeader()
    self:RefreshFooter()
end

--Overridden from base
function ZO_AddOnManager_Gamepad:OnShown()
    if not HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
        self:ShowEula()
    end
end

--Overridden from base
function ZO_AddOnManager_Gamepad:OnHiding()
    self:RemoveKeybinds()
    self:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

--Overridden from base
function ZO_AddOnManager_Gamepad:GetFooterNarration()
    if GAMEPAD_GENERIC_FOOTER_FRAGMENT and GAMEPAD_GENERIC_FOOTER_FRAGMENT:IsShowing() then
        return GAMEPAD_GENERIC_FOOTER:GetNarrationText(self.footerData)
    end
end

--Overridden from base
function ZO_AddOnManager_Gamepad:GetHeaderNarration()
    local narrations = {}

    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_WINDOW_TITLE_ADDON_MANAGER)))

    if ZO_IsPregameUI() and self.selectedCharacterEntry then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.selectedCharacterEntry.name))
    end

    return narrations
end

--Overridden from base
function ZO_AddOnManager_Gamepad:GetNarrationText()
    local selectedData = self:GetSelectedData()
    if selectedData then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.headerText)
    elseif #self.libraryList == 0 and #self.addonList == 0 then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ADDON_MANAGER_EMPTY_TEXT))
    end
end

function ZO_AddOnManager_Gamepad.OnControlInitialized(control)
    ADDON_MANAGER_GAMEPAD = ZO_AddOnManager_Gamepad:New(control)
end

function ZO_AddOnManager_Gamepad.OnRowControlInitialized(control)
    control.addonNameLabel = control:GetNamedChild("AddonName")
    control.authorNameLabel = control:GetNamedChild("AuthorName")
    control.dependencyIcon = control:GetNamedChild("Dependency")
    control.enabledControl = control:GetNamedChild("Enabled")
    control.enabledIcon = control:GetNamedChild("EnabledIcon")
end

function ZO_AddOnManager_Gamepad.OnHeaderRowControlInitialized(control)
    control.nameLabel = control:GetNamedChild("HeaderName")
end