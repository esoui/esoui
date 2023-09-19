------------------
-- Guild Finder --
------------------

ZO_GuildBrowser_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_GuildBrowser_Shared)

local IS_GAMEPAD = true

function ZO_GuildBrowser_Gamepad:New(...)
    return ZO_GuildBrowser_Shared.New(self, ...)
end

function ZO_GuildBrowser_Gamepad:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control)
    ZO_GuildBrowser_Shared.Initialize(self, control)

    self.filterManager = ZO_GuildBrowser_ManageFilters_Shared:New()

    self.headerData = 
    {
        titleText = GetString(SI_GUILD_BROWSER_TITLE),
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_FINDER_APPLICATIONS_HEADER),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self.exitHelperPanelFunction = function()
        self:DeactivateCurrentHelperPanel()
        self:ActivateCurrentList()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end

    GAMEPAD_GUILD_BROWSER_SCENE = ZO_Scene:New("guildBrowserGamepad", SCENE_MANAGER)
    self:SetScene(GAMEPAD_GUILD_BROWSER_SCENE)

    GAMEPAD_GUILD_BROWSER_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_GUILD_BROWSER_FRAGMENT:SetHideOnSceneHidden(true)

    local function OnGuildFinderSearchResultsReady()
        self:RefreshKeybinds()
    end

    local function OnGuildFinderSearchStateChanged(newState)
        self:RefreshKeybinds()
    end

    local function OnGuildFinderApplicationsChanged(newState)
        self.headerData.data1Text = zo_strformat(SI_GUILD_BROWSER_APPLICATIONS_QUANTITY_FORMATTER, GetGuildFinderNumAccountApplications(), MAX_GUILD_FINDER_APPLICATIONS_PER_ACCOUNT)
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end

    self:InitializeFiltersDialog()
    self:InitializeApplicationMessageDialog()

    GUILD_BROWSER_MANAGER:RegisterCallback("OnGuildFinderSearchResultsReady", OnGuildFinderSearchResultsReady)
    GUILD_BROWSER_MANAGER:RegisterCallback("OnSearchStateChanged", OnGuildFinderSearchStateChanged)
    GUILD_BROWSER_MANAGER:RegisterCallback("OnApplicationsChanged", OnGuildFinderApplicationsChanged)

    local function OnAreFiltersDefaultChanged()
        local dialog = ZO_Dialogs_FindDialog("GAMEPAD_GUILD_BROWSER_FILTERS")
        ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
    end

    self.filterManager:RegisterCallback("OnGuildBrowserFilterValueIsDefaultChanged", OnAreFiltersDefaultChanged)
end

function ZO_GuildBrowser_Gamepad:SetupList(list)
    local function BrowseGuildsDropdownSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

        local dropdown = control.dropdown
        self.focusDropdown = dropdown

        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
        dropdown:SetSelectedItemTextColor(selected)

        dropdown:SetSortsItems(false)
        dropdown:ClearItems()

        if self.currentGuildListFocus then
            dropdown:SetSelectedItemText(GetString("SI_GUILDFOCUSATTRIBUTEVALUE", self.currentGuildListFocus))
        else
            dropdown:SetSelectedItemText(GetString(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_SELECTOR_DEFAULT))
        end

        local function SelectFocus(dropdown, name, data)
            self.currentGuildListFocus = data.focus
            GUILD_BROWSER_GUILD_LIST_GAMEPAD:SetFocusType(self.currentGuildListFocus)
            GUILD_BROWSER_MANAGER:ExecuteSearch()
            self.dropdownEntrySelected = true
        end

        for i = GUILD_FOCUS_ATTRIBUTE_VALUE_TRADING, GUILD_FOCUS_ATTRIBUTE_VALUE_ITERATION_END do
            local entry = dropdown:CreateItemEntry(GetString("SI_GUILDFOCUSATTRIBUTEVALUE", i), SelectFocus)
            entry.focus = i
            dropdown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
        end

        dropdown:UpdateItems()

        local function OnFocusDropdownDeactivated()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            if self.dropdownEntrySelected then
                self:ActivateHelperPanel(GUILD_BROWSER_GUILD_LIST_GAMEPAD)
            else
                self.categoryList:Activate()
            end
            self.dropdownEntrySelected = false
        end

        dropdown:SetDeactivatedCallback(OnFocusDropdownDeactivated)
    end

    list:AddDataTemplate("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_Gamepad_Dropdown_Item_Indented", BrowseGuildsDropdownSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", nil, "DropdownEntry")
end

function ZO_GuildBrowser_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    { 
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                if self.currentCategoryData then
                    self.currentCategoryData.onPressedFunction()
                end
            end,
            visible = function()
                if self.currentCategoryData and self.currentCategoryData.canBeActivated then
                    return self.currentCategoryData.canBeActivated()
                end
                return true
            end,
        },

        -- view results
        {
            name = GetString(SI_GAMEPAD_GUILD_BROWSER_VIEW_RESULTS),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                self:ActivateHelperPanel(GUILD_BROWSER_GUILD_LIST_GAMEPAD)
            end,
            visible = function()
                if self.currentCategoryData.category == ZO_GUILD_BROWSER_CATEGORY_GUILD_LIST then
                    local isNotSearching = GUILD_BROWSER_MANAGER:GetSearchState() == GUILD_FINDER_SEARCH_STATE_COMPLETE
                    return isNotSearching and GUILD_BROWSER_MANAGER:HasCurrentFoundGuilds()
                end

                return false
            end
        },

        -- filters dialog
        {
            name = GetString(SI_GAMEPAD_GUILD_BROWSER_FILTERS_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local dialogName = "GAMEPAD_GUILD_BROWSER_FILTERS"
                ZO_Dialogs_ShowGamepadDialog(dialogName)
            end,
        },

        -- back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }
end

function ZO_GuildBrowser_Gamepad:OnDeferredInitialize()
    if self.initialized == true then
        return
    end

    self.categoryList = self:GetMainList()
    self.categoryList:Clear()

    -- Active Applications
    local applicationsData = ZO_GamepadEntryData:New(GetString(SI_GUILD_BROWSER_APPLICATIONS_ACTIVE))
    applicationsData.onSelectedFunction = function()
        GUILD_BROWSER_APPLICATIONS_GAMEPAD:ShowCategory()
        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    end
    applicationsData.onUnselectedFunction = function()
        GUILD_BROWSER_APPLICATIONS_GAMEPAD:HideCategory()
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    end
    applicationsData.onPressedFunction = function()
        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
        self:ActivateHelperPanel(GUILD_BROWSER_APPLICATIONS_GAMEPAD)
    end
    applicationsData.canBeActivated = function()
        return GUILD_BROWSER_APPLICATIONS_GAMEPAD:CanBeActivated()
    end
    applicationsData.category = ZO_GUILD_BROWSER_CATEGORY_APPLICATIONS
    self.categoryList:AddEntry("ZO_GamepadSubMenuEntryTemplate", applicationsData)

    -- Application Message
    local applicationMessageData = ZO_GamepadEntryData:New(GetString(SI_GUILD_BROWSER_APPLICATIONS_MESSAGE))
    applicationMessageData.onSelectedFunction = function()
        self:ShowApplicationMessageTooltip()
    end
    applicationMessageData.onUnselectedFunction = function()
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
    applicationMessageData.onPressedFunction = function()
        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_GUILD_BROWSER_APPLICATION_MESSAGE")
    end
    applicationMessageData.category = ZO_GUILD_BROWSER_CATEGORY_APPLICATIONS
    self.categoryList:AddEntry("ZO_GamepadSubMenuEntryTemplate", applicationMessageData)

    -- Guild Listings
    local guildListData = ZO_GamepadEntryData:New()
    guildListData.onSelectedFunction = function()
        GUILD_BROWSER_GUILD_LIST_GAMEPAD:ShowCategory()
        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    end
    guildListData.onUnselectedFunction = function()
        GUILD_BROWSER_GUILD_LIST_GAMEPAD:HideCategory()
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    end
    guildListData.onPressedFunction = function()
        self:ActivateFocusDropdown()
    end
    guildListData:SetHeader(GetString(SI_GUILD_BROWSER_CATEGORY_BROWSE_GUILDS))
    guildListData.category = ZO_GUILD_BROWSER_CATEGORY_GUILD_LIST
    guildListData.narrationText = ZO_GetDefaultParametricListDropdownNarrationText
    self.categoryList:AddEntryWithHeader("ZO_Gamepad_Dropdown_Item_Indented", guildListData)

    self.categoryList:Commit()
    self:SetCurrentList(self.categoryList)

    self.initialized = true
end

function ZO_GuildBrowser_Gamepad:RefreshKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildBrowser_Gamepad:ShowApplicationMessageTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    local defaultMessage = GUILD_BROWSER_MANAGER:GetSavedApplicationMessage()
    if defaultMessage == "" then
        defaultMessage = GetString(SI_GUILD_BROWSER_APPLICATIONS_MESSAGE_DESCRIPTION)
    end
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GUILD_BROWSER_APPLICATIONS_MESSAGE), defaultMessage)
end

function ZO_GuildBrowser_Gamepad:ActivateFocusDropdown()
    self.categoryList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.focusDropdown:Activate()
end

function ZO_GuildBrowser_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if oldSelectedData then
        oldSelectedData.onUnselectedFunction()
    end
    
    self.currentCategoryData = selectedData

    if selectedData then
        selectedData.onSelectedFunction()
    end
end

function ZO_GuildBrowser_Gamepad:ActivateHelperPanel(helperPanel)
    if GAMEPAD_GUILD_BROWSER_SCENE:IsShowing() then
        if self.currentHelperPanel then
            self:DeactivateCurrentHelperPanel()
        end
        self.currentHelperPanel = helperPanel
        helperPanel:RegisterCallback("PanelSelectionEnd", self.exitHelperPanelFunction)
        self:DeactivateCurrentList()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        helperPanel:Activate()
    end
end

function ZO_GuildBrowser_Gamepad:DeactivateCurrentHelperPanel()
    if self.currentHelperPanel then
        self.currentHelperPanel:UnregisterCallback("PanelSelectionEnd", self.exitHelperPanelFunction)
        self.currentHelperPanel:Deactivate()
    end
end

function ZO_GuildBrowser_Gamepad:ShowGuildInfo(guildId)
    self:DeactivateCurrentHelperPanel()
    self.showingGuildInfo = true
    GUILD_BROWSER_GUILD_INFO_GAMEPAD:ShowWithGuild(guildId)
end

function ZO_GuildBrowser_Gamepad:ReturnWithAppliedGuild()
    self.returnWithAppliedGuild = true
end

function ZO_GuildBrowser_Gamepad:PerformUpdate()
    -- list is static, nothing to do here
end

function ZO_GuildBrowser_Gamepad:RefreshSearchFilters()
    SetGuildFinderHasTradersSearchFilter(self.hasGuildTrader)
    SetGuildFinderChampionPointsFilterValues(self.minCP, self.maxCP)

    local allActivities = self.activityData:GetAllItems()
    for _, item in ipairs(allActivities) do
        SetGuildFinderActivityFilterValue(item.activity, self.activityData:IsItemSelected(item))
    end

    local allPersonalities = self.personalityData:GetAllItems()
    for _, item in ipairs(allPersonalities) do
        SetGuildFinderPersonalityFilterValue(item.personality, self.personalityData:IsItemSelected(item))
    end

    local allAlliances = self.allianceData:GetAllItems()
    for _, item in ipairs(allAlliances) do
        SetGuildFinderAllianceFilterValue(item.alliance, self.allianceData:IsItemSelected(item))
    end

    local allLanguages = self.languageData:GetAllItems()
    for _, item in ipairs(allLanguages) do
        SetGuildFinderLanguageFilterValue(item.language, self.languageData:IsItemSelected(item))
    end

    local allSizes = self.sizeData:GetAllItems()
    for _, item in ipairs(allSizes) do
        SetGuildFinderSizeFilterValue(item.size, self.sizeData:IsItemSelected(item))
    end

    local allRoles = self.roleData:GetAllItems()
    for _, item in ipairs(allRoles) do
        SetGuildFinderRoleFilterValue(item.role, self.roleData:IsItemSelected(item))
    end

    local allTimesByHour = ZO_GetHoursSinceMidnightPerHourTable()
    local startTime = allTimesByHour[self.startEndTimePair[GUILD_META_DATA_ATTRIBUTE_START_TIME]].value
    local endTime = allTimesByHour[self.startEndTimePair[GUILD_META_DATA_ATTRIBUTE_END_TIME]].value
    SetGuildFinderPlayTimeFilters(startTime, endTime)
end

function ZO_GuildBrowser_Gamepad:ResetFilters()
    local defaultSelectionValue = self.filterManager:GetComboBoxEntrySelectionDefault()

    self.hasGuildTrader = self.filterManager:GetHasGuildTraderDefault()
    self.minCP = self.filterManager:GetMinCPDefault()
    self.maxCP = self.filterManager:GetMaxCPDefault()

    local allActivities = self.activityData:GetAllItems()
    for _, item in ipairs(allActivities) do
        self.activityData:SetItemSelected(item, defaultSelectionValue)
    end

    local allPersonalities = self.personalityData:GetAllItems()
    for _, item in ipairs(allPersonalities) do
        self.personalityData:SetItemSelected(item, defaultSelectionValue)
    end

    local allAlliances = self.allianceData:GetAllItems()
    for _, item in ipairs(allAlliances) do
        self.allianceData:SetItemSelected(item, defaultSelectionValue)
    end

    self:SetLanguageDataToDefault()

    local allSizes = self.sizeData:GetAllItems()
    for _, item in ipairs(allSizes) do
        self.sizeData:SetItemSelected(item, defaultSelectionValue)
    end

    local allRoles = self.roleData:GetAllItems()
    for _, item in ipairs(allRoles) do
        self.roleData:SetItemSelected(item, defaultSelectionValue)
    end

    local defaultTimeIndex = self.filterManager:GetTimeDefault(IS_GAMEPAD)
    self.startEndTimePair[GUILD_META_DATA_ATTRIBUTE_START_TIME] = defaultTimeIndex
    self.startEndTimePair[GUILD_META_DATA_ATTRIBUTE_END_TIME] = defaultTimeIndex
    SetGuildFinderPlayTimeFilters(defaultTimeIndex, defaultTimeIndex)

    self.filterManager:ResetFiltersToDefault()
end

function ZO_GuildBrowser_Gamepad:OnShowing()
    if self.currentCategoryData then
        self.currentCategoryData.onSelectedFunction()
    end
    ZO_GuildBrowser_Shared.OnShowing(self)
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self.categoryList:RefreshVisible()

    if self.returnWithAppliedGuild then
        self.categoryList:SetSelectedIndexWithoutAnimation(1)
        self:ActivateHelperPanel(GUILD_BROWSER_APPLICATIONS_GAMEPAD)
    elseif self.showingGuildInfo then
        self:ActivateHelperPanel(GUILD_BROWSER_GUILD_LIST_GAMEPAD)
    else
        GUILD_BROWSER_GUILD_LIST_GAMEPAD:RefreshList()
    end
    self.showingGuildInfo = false
    self.returnWithAppliedGuild = false
end

function ZO_GuildBrowser_Gamepad:OnHide()
    self:DeactivateCurrentHelperPanel()
    self.focusDropdown:Deactivate(true)
    ZO_GuildBrowser_Shared.OnHidden(self)
    ZO_Gamepad_ParametricList_Screen.OnHide(self)
    if not self.showingGuildInfo then
        self:ClearCurrentListFocus()
    end
end

function ZO_GuildBrowser_Gamepad:ClearCurrentListFocus()
    self.currentGuildListFocus = nil
    GUILD_BROWSER_GUILD_LIST_GAMEPAD:SetFocusType(self.currentGuildListFocus)
    GUILD_BROWSER_MANAGER:ClearCurrentFoundGuilds()
end

function ZO_GuildBrowser_Gamepad:OnReportingGuild()
    self:ClearCurrentListFocus()
    self.showingGuildInfo = false
    self.returnWithAppliedGuild = false
end

function ZO_GuildBrowser_Gamepad:CreateTimeBasedDropdown(attributeType, dataKey)
    return
    {
        template = "ZO_GamepadDropdownItem",

        templateData =
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                self.dialogDropdowns[attributeType] = dropdown

                dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                dropdown:SetSelectedItemTextColor(selected)

                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                local function OnSelectedCallback(dropdown, entryText, entry)
                    self.startEndTimePair[attributeType] = entry.value
                    self.filterManager:SetFilterValueIsDefaultByAttributeType(attributeType, entry.value == self.filterManager:GetTimeDefault(IS_GAMEPAD))
                end

                local allTimesByHour = ZO_GetHoursSinceMidnightPerHourTable()

                for i, timeData in ipairs(allTimesByHour) do
                    local entry = dropdown:CreateItemEntry(timeData.name, OnSelectedCallback)
                    entry.value = i
                    entry.timeValue = timeData.value
                    dropdown:AddItem(entry)
                end

                dropdown:UpdateItems()

                control.dropdown:SelectItemByIndex(self.startEndTimePair[attributeType])
                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                local targetControl = dialog.entryList:GetTargetControl()
                targetControl.dropdown:Activate()
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
end

function ZO_GuildBrowser_Gamepad:BuildActivitiesData()
    self.activityData:Clear()

    for i = GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_END do
        local newEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_GUILDACTIVITYATTRIBUTEVALUE", i)))
        newEntry.activity = i
        self.activityData:AddItem(newEntry)
    end
end

function ZO_GuildBrowser_Gamepad:BuildSizeData()
    self.sizeData:Clear()

    for i = GUILD_SIZE_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_SIZE_ATTRIBUTE_VALUE_ITERATION_END do
        local min, max = GetGuildSizeAttributeRangeValues(i)
        local newEntry = ZO_ComboBox_Base:CreateItemEntry(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_SIZE_DROPDOWN_ENTRY_TEXT, min, max))
        newEntry.size = i
        self.sizeData:AddItem(newEntry)
    end
end

function ZO_GuildBrowser_Gamepad:BuildPersonalityData()
    self.personalityData:Clear()

    for i = GUILD_PERSONALITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_PERSONALITY_ATTRIBUTE_VALUE_ITERATION_END do
        local newEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_GUILDPERSONALITYATTRIBUTEVALUE", i)))
        newEntry.personality = i
        self.personalityData:AddItem(newEntry)
    end
end

function ZO_GuildBrowser_Gamepad:BuildAllianceData()
    self.allianceData:Clear()

    for i = ALLIANCE_ITERATION_BEGIN, ALLIANCE_ITERATION_END do
        local newEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetAllianceName(i)))
        newEntry.alliance = i
        self.allianceData:AddItem(newEntry)
    end
end

function ZO_GuildBrowser_Gamepad:SetLanguageDataToDefault()
    for _, item in ipairs(self.languageData:GetAllItems()) do
        self.languageData:SetItemSelected(item, ZO_GuildBrowser_IsGuildAttributeLanguageFilterDefault(item.language))
    end
end

function ZO_GuildBrowser_Gamepad:IsLanguageDataSetToDefault()
    for _, item in ipairs(self.languageData:GetAllItems()) do
        local isCurrentItemDefault = ZO_GuildBrowser_IsGuildAttributeLanguageFilterDefault(item.language)
        if isCurrentItemDefault ~= self.languageData:IsItemSelected(item) then
            return false
        end
    end
    return true
end

function ZO_GuildBrowser_Gamepad:BuildLanguageData()
    self.languageData:Clear()
    local function AddEntry(language)
        local newEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_GUILDLANGUAGEATTRIBUTEVALUE", language)))
        newEntry.language = language
        self.languageData:AddItem(newEntry)
        self.languageData:SetItemSelected(newEntry, ZO_GuildBrowser_IsGuildAttributeLanguageFilterDefault(language))
    end

    for language = GUILD_LANGUAGE_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_LANGUAGE_ATTRIBUTE_VALUE_ITERATION_END do
        AddEntry(language)
    end
    AddEntry(GUILD_LANGUAGE_ATTRIBUTE_VALUE_OTHER)
end

function ZO_GuildBrowser_Gamepad:BuildRolesData()
    self.roleData:Clear()

    local dpsEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_LFGROLE", LFG_ROLE_DPS)))
    dpsEntry.role = LFG_ROLE_DPS
    self.roleData:AddItem(dpsEntry)
    local tankEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_LFGROLE", LFG_ROLE_TANK)))
    tankEntry.role = LFG_ROLE_TANK
    self.roleData:AddItem(tankEntry)
    local healEntry = ZO_ComboBox_Base:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_LFGROLE", LFG_ROLE_HEAL)))
    healEntry.role = LFG_ROLE_HEAL
    self.roleData:AddItem(healEntry)
end

function ZO_GuildBrowser_Gamepad:CreateMultiSelectionBasedDropdown(attributeType, multiSelectionText, dropdownData, isDropdownSetToDefaultFn)
    local function OnComboboxSelectionChanged()
        local isDefault = false
        if isDropdownSetToDefaultFn then
            isDefault = isDropdownSetToDefaultFn()
        else
            isDefault = #dropdownData.selectedItems <= 0
        end
        self.filterManager:SetFilterValueIsDefaultByAttributeType(attributeType, isDefault)
    end

    return
    {
        template = "ZO_GamepadMultiSelectionDropdownItem",

        templateData = 
        {
            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                self.dialogDropdowns[attributeType] = dropdown

                dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                dropdown:SetSelectedItemTextColor(selected)

                dropdown:SetSortsItems(false)
                dropdown:SetNoSelectionText(GetString("SI_GUILDMETADATAATTRIBUTE", attributeType))
                dropdown:SetMultiSelectionTextFormatter(multiSelectionText)
                dropdown:RegisterCallback("OnHideDropdown", OnComboboxSelectionChanged)
                dropdown:LoadData(dropdownData)
                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
            end,
            callback = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                local targetControl = dialog.entryList:GetTargetControl()
                targetControl.dropdown:Activate()
            end,
            narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
        },
    }
end

function ZO_GuildBrowser_Gamepad:InitializeFiltersDialog()
    self.dialogDropdowns = {}
    self.hasGuildTrader = self.filterManager:GetHasGuildTraderDefault()
    self.minCP = self.filterManager:GetMinCPDefault()
    self.maxCP = self.filterManager:GetMaxCPDefault()

    local defaultTime = self.filterManager:GetTimeDefault(IS_GAMEPAD)
    self.startEndTimePair =
    {
        [GUILD_META_DATA_ATTRIBUTE_START_TIME] = defaultTime,
        [GUILD_META_DATA_ATTRIBUTE_END_TIME] = defaultTime,
    }

    self.activityData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    self:BuildActivitiesData()

    self.sizeData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    self:BuildSizeData()

    self.personalityData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    self:BuildPersonalityData()

    self.allianceData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    self:BuildAllianceData()

    self.languageData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    self:BuildLanguageData()

    self.roleData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    self:BuildRolesData()

    local setupFunction = function(dialog)
        ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GAMEPAD_GUILD_BROWSER_FILTERS_DIALOG_HEADER))
        if not dialog.dropdowns then
            dialog.dropdowns = {}
        end
        dialog:setupFunc()
    end

    local OnHidingCallback = function()
        self:RefreshSearchFilters()
        if self.currentGuildListFocus then
            GUILD_BROWSER_MANAGER:ExecuteSearch()
        end
    end

    local NoChoiceCallback = function(dialog)
        for i, dropdown in pairs(self.dialogDropdowns) do
            dropdown:Deactivate()
        end
    end

    local primaryButton =
    {
        keybind = "DIALOG_PRIMARY",
        text = SI_GAMEPAD_SELECT_OPTION,
        callback = function(dialog)
            local targetData = dialog.entryList:GetTargetData()
            if targetData and targetData.callback then
                targetData.callback(dialog)
            end
        end,
    }

    -- Activites
    local activitiesDropdownEntry = self:CreateMultiSelectionBasedDropdown(GUILD_META_DATA_ATTRIBUTE_ACTIVITIES, GetString(SI_GUILD_BROWSER_GUILD_LIST_ACTIVITIES_DROPDOWN_TEXT), self.activityData)

    -- Personalities
    local personalitiesDropdownEntry = self:CreateMultiSelectionBasedDropdown(GUILD_META_DATA_ATTRIBUTE_PERSONALITIES, GetString(SI_GUILD_BROWSER_GUILD_LIST_PERSONALITIES_DROPDOWN_TEXT), self.personalityData)

    -- Language
    local function IsLanguageDataSetToDefault()
        return self:IsLanguageDataSetToDefault()
    end
    local languageDropdownEntry = self:CreateMultiSelectionBasedDropdown(GUILD_META_DATA_ATTRIBUTE_LANGUAGES, GetString(SI_GUILD_BROWSER_GUILD_LIST_LANGUAGES_DROPDOWN_TEXT), self.languageData, IsLanguageDataSetToDefault)

    -- Alliance
    local allianceDropdownEntry = self:CreateMultiSelectionBasedDropdown(GUILD_META_DATA_ATTRIBUTE_ALLIANCE, GetString(SI_GUILD_BROWSER_GUILD_LIST_ALLIANCES_DROPDOWN_TEXT), self.allianceData)

    -- Size
    local sizeDropdownEntry = self:CreateMultiSelectionBasedDropdown(GUILD_META_DATA_ATTRIBUTE_SIZE, GetString(SI_GUILD_BROWSER_GUILD_LIST_SIZE_DROPDOWN_TEXT), self.sizeData)

    -- Roles
    local roleDropdownEntry = self:CreateMultiSelectionBasedDropdown(GUILD_META_DATA_ATTRIBUTE_ROLES, GetString(SI_GUILD_BROWSER_GUILD_LIST_ROLES_DROPDOWN_TEXT), self.roleData)

    -- Start Time
    local startTimeDropdownEntry = self:CreateTimeBasedDropdown(GUILD_META_DATA_ATTRIBUTE_START_TIME)
    startTimeDropdownEntry.header = GetString(SI_GUILD_FINDER_CORE_HOURS_LABEL)
            
    -- End Time
    local endTimeDropdownEntry = self:CreateTimeBasedDropdown(GUILD_META_DATA_ATTRIBUTE_END_TIME)
    endTimeDropdownEntry.header = GetString(SI_GAMEPAD_GUILD_BROWSER_END_TIME_FILTER_HEADER)

    -- Reset Filters
    local resetFilterButton =
    {
        keybind = "DIALOG_RESET",
        text = SI_GUILD_BROWSER_RESET_FILTERS_KEYBIND,
        enabled = function(dialog)
            return not self.filterManager:AreFiltersSetToDefault()
        end,
        callback = function(dialog)
            self:ResetFilters()
            --Re-narrate the selection when the filters are reset
            SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
            dialog.info.setup(dialog)
        end,
    }

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_GUILD_BROWSER_FILTERS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = setupFunction,
        parametricList =
        {
            -- Has Trader
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                text = GetString(SI_GAMEPAD_GUILD_BROWSER_FILTERS_HAS_GUILD_TRADER),

                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                        if self.hasGuildTrader then
                            ZO_CheckButton_SetChecked(control.checkBox)
                        else
                            ZO_CheckButton_SetUnchecked(control.checkBox)
                        end
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        local targetControl = dialog.entryList:GetTargetControl()
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                        self.hasGuildTrader = ZO_GamepadCheckBoxTemplate_IsChecked(targetControl)
                        self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_KIOSK, self.hasGuildTrader == self.filterManager:GetHasGuildTraderDefault())
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    end,
                    narrationText = ZO_GetDefaultParametricListToggleNarrationText,
                },
            },

            -- Activities
            activitiesDropdownEntry,

            -- Personalities
            personalitiesDropdownEntry,

            -- Roles
            roleDropdownEntry,

            -- Min Champion Points
            {
                template = "ZO_GuildBrowser_ChampionPoint_EditBox_Gamepad",
                headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                header = GetString(SI_GUILD_BROWSER_CHAMPION_POINT_RANGE_HEADER),

                templateData =
                {
                    textChangedCallback = function(control)
                        local newCP = tonumber(control:GetText())
                        if self.minCP ~= newCP then
                            self.minCP = newCP

                            local maxAllowedValue = ZO_GuildFinder_Manager.GetMaxCPAllowedForInput()
                            if self.minCP == nil then
                                self.minCP = self.filterManager:GetMinCPDefault()
                            elseif self.minCP > self.maxCP then
                                self.minCP = self.maxCP
                            elseif self.minCP > maxAllowedValue then
                                self.minCP = maxAllowedValue
                            end
                            self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP, self.minCP == self.filterManager:GetMinCPDefault())
                        end
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        data.control = control
                        control.editBoxControl:SetText(self.minCP)
                    end,
                    callback = function(dialog)
                        local data = dialog.entryList:GetTargetData()
                        local edit = data.control.editBoxControl

                        edit:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },

            -- Max Champion Points
            {
                template = "ZO_GuildBrowser_ChampionPoint_EditBox_Gamepad",
                headerTemplate = "ZO_GamepadMenuEntryFullWidthHeaderTemplate",
                header = GetString(SI_GAMEPAD_GUILD_BROWSER_MAX_CHAMPION_POINTS_FILTER),

                templateData =
                {
                    textChangedCallback = function(control)
                        local newCP = tonumber(control:GetText())
                        if self.maxCP ~= newCP then
                            self.maxCP = newCP

                            local maxAllowedValue = ZO_GuildFinder_Manager.GetMaxCPAllowedForInput()
                            if self.maxCP == nil then
                                self.maxCP = self.filterManager:GetMaxCPDefault()
                            elseif self.minCP > self.maxCP then
                                self.maxCP = self.minCP
                            elseif self.maxCP > maxAllowedValue then
                                self.maxCP = maxAllowedValue
                            end
                            self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP, self.maxCP == self.filterManager:GetMaxCPDefault())
                        end
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        data.control = control
                        control.editBoxControl:SetText(self.maxCP)
                    end,
                    callback = function(dialog)
                        local data = dialog.entryList:GetTargetData()
                        local edit = data.control.editBoxControl

                        edit:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },

            -- Language
            languageDropdownEntry,

            -- Alliance
            allianceDropdownEntry,

            -- Size
            sizeDropdownEntry,

            -- Start Time
            startTimeDropdownEntry,
            
            -- End Time
            endTimeDropdownEntry,
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            primaryButton,

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_GUILD_BROWSER_FILTERS")
                end,
            },

            resetFilterButton,
        },
        onHidingCallback = OnHidingCallback,
        noChoiceCallback = NoChoiceCallback,
    })
end

function ZO_GuildBrowser_Gamepad:InitializeApplicationMessageDialog()
    local dialogName = "GAMEPAD_GUILD_BROWSER_APPLICATION_MESSAGE"

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end    

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = function(dialog)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GAMEPAD_GUILD_BROWSER_APPLICATION_MESSAGE_DIALOG_HEADER))
            dialog.currentText = GUILD_BROWSER_MANAGER:GetSavedApplicationMessage()
            dialog:setupFunc()
        end,
        finishedCallback = function(dialog)
            self:ShowApplicationMessageTooltip()
        end,
        parametricList =
        {
            -- Edit Box
            {
                template = "ZO_Gamepad_GenericDialog_TextFieldItem_Multiline_Large",
                templateData = 
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)
                        local dialog = data.dialog

                        control.editBoxControl.textChangedCallback = function(control)
                                                                        dialog.currentText = control:GetText()
                                                                     end
                        data.control = control
                        control.editBoxControl:SetDefaultText(GetString(SI_GUILD_BROWSER_APPLICATIONS_MESSAGE_EMPTY_TEXT))
                        control.editBoxControl:SetMaxInputChars(MAX_GUILD_APPLICATION_MESSAGE_LENGTH)
                        control.editBoxControl:SetText(dialog.currentText)
                    end,
                    callback = function(dialog)
                        local data = dialog.entryList:GetTargetData()
                        local edit = data.control.editBoxControl

                        edit:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                }
            },

            -- Accept
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = 
                {
                    text = GetString(SI_DIALOG_ACCEPT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        GUILD_BROWSER_MANAGER:SetSavedApplicationMessage(dialog.currentText)
                        ReleaseDialog()
                    end
                }
            },
        },
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
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    ReleaseDialog()
                end,
            },
        },
    })
end

-- XML Functions
------------------

function ZO_GuildBrowser_Gamepad_OnInitialized(control)
    GUILD_BROWSER_GAMEPAD = ZO_GuildBrowser_Gamepad:New(control)
end