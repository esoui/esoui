ZO_GAMEPAD_ADDON_MANAGER_ADDON_NAME_WIDTH = 500 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_AUTHOR_WIDTH = 545 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_EXTRA_INFO_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_ENABLED_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_ADDON_MANAGER_HEADER_WIDTH = 1000

local ADDON_DATA = 1
local HEADER_DATA = 2

local AddOnManager = GetAddOnManager()

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
    if AreUserAddOnsSupported() then
        local optionsEntryData = ZO_GamepadEntryData:New(GetString(SI_GAME_MENU_ADDONS), "EsoUI/Art/Options/Gamepad/gp_options_addons.dds")
        optionsEntryData.sortOrder = ZO_GAMEPAD_OPTIONS_CATEGORY_SORT_ORDER[SETTING_PANEL_ACCOUNT] + 1
        optionsEntryData:SetIconTintOnSelection(true)
        optionsEntryData.visible = function()
            if ZO_IsPregameUI() then
                return IsAccountLoggedIn()
            else
                return true
            end
        end
        optionsEntryData.callback = function()
            SCENE_MANAGER:Push("gamepad_addons")
        end
        GAMEPAD_OPTIONS:RegisterCustomCategory(optionsEntryData)
    end
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
        setup = function(dialogControl)
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

            dialogControl:setupFunc()
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
    if ZO_IsIngameUI() and self.isDirty and bypassHideSceneConfirmationReason == nil then
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
                    return self.isDirty
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
                ZO_Dialogs_ShowPlatformDialog("ADDON_MANAGER_OPTIONS_GAMEPAD")
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
                entryData.addOnAuthorByLine = zo_strformat(SI_ADD_ON_AUTHOR_LINE, author)
                entryData.strippedAddOnAuthorByLine = zo_strformat(SI_ADD_ON_AUTHOR_LINE, strippedAuthor)
            else
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
    self:MarkDirty()
    self:RefreshData()
    self:UpdateKeybinds()
end

function ZO_AddOnManager_Gamepad:MarkDirty()
    self.isDirty = true
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