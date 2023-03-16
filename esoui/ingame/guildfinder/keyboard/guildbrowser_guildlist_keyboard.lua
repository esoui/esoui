------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_GUILD_LIST_KEYBOARD_ENTRY_HEIGHT = 170

local ALLIANCE_BUTTON_NAME_TABLE =
{
    "AD",
    "EP",
    "DC",
}

ZO_GuildBrowser_GuildList_Keyboard = ZO_GuildBrowser_GuildList_Shared:Subclass()

function ZO_GuildBrowser_GuildList_Keyboard:New(...)
    return ZO_GuildBrowser_GuildList_Shared.New(self, ...)
end

function ZO_GuildBrowser_GuildList_Keyboard:Initialize(control)
    ZO_GuildBrowser_GuildList_Shared.Initialize(self, control)

    self.filterManager = ZO_GuildBrowser_ManageFilters_Shared:New()
    self.traderCheckBox = control:GetNamedChild("TraderCheckBox")

    ZO_CheckButton_SetLabelText(self.traderCheckBox.checkButton, GetString(SI_GUILD_BROWSER_GUILD_LIST_FILTERS_GUILD_TRADER))
    local function OnFilterTraderToggled(checkButton, checked)
        SetGuildFinderHasTradersSearchFilter(checked)
        GUILD_BROWSER_MANAGER:ExecuteSearch()
        self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_KIOSK, not checked)
    end

    ZO_CheckButton_SetToggleFunction(self.traderCheckBox.checkButton, OnFilterTraderToggled)

    self.activitiesControl = control:GetNamedChild("Activites")
    self.activitiesDropdown = ZO_ComboBox_ObjectFromContainer(self.activitiesControl)
    self.activitiesDropdown:SetSortsItems(false)

    self.personalitiesControl = control:GetNamedChild("Personalities")
    self.personalitiesDropdown = ZO_ComboBox_ObjectFromContainer(self.personalitiesControl)
    self.personalitiesDropdown:SetSortsItems(false)

    self.additionalFiltersButton = control:GetNamedChild("AdditionalFilters")

    self:BuildActivitiesDropdown()
    self:BuildPersonalitiesDropdown()
    self:InitializeKeybindStripDescriptor()

    self.onCloseGuildInfoCallback = function()
        SCENE_MANAGER:AddFragment(self.fragment)
    end

    ZO_ScrollList_AddDataType(self.list, ZO_GUILD_BROWSER_GUILD_LIST_ENTRY_TYPE, "ZO_GuildBrowser_GuildList_Row_Keyboard", ZO_GUILD_BROWSER_GUILD_LIST_KEYBOARD_ENTRY_HEIGHT, function(control, data) self:SetupRow(control, data) end)
    local HIGHLIGHT_CALLBACK = nil
    local OVERRIDE_HIGHLIGHT_END_ALPHA = 0.7
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ListEntryHighlight", HIGHLIGHT_CALLBACK, OVERRIDE_HIGHLIGHT_END_ALPHA)

    local function OnAreFiltersDefaultChanged()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end

    self.filterManager:RegisterCallback("OnGuildBrowserFilterValueIsDefaultChanged", OnAreFiltersDefaultChanged)
end

function ZO_GuildBrowser_GuildList_Keyboard:BuildActivitiesDropdown()
    local function OnActivitiesDropdownHidden()
        self:RefreshActivitiesFilter()
        GUILD_BROWSER_MANAGER:ExecuteSearch()
    end

    self.activitiesDropdown:ClearItems()
    self.activitiesDropdown:SetHideDropdownCallback(OnActivitiesDropdownHidden)
    self.activitiesDropdown:SetNoSelectionText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ACTIVITIES))
    self.activitiesDropdown:SetMultiSelectionTextFormatter(SI_GUILD_BROWSER_GUILD_LIST_ACTIVITIES_DROPDOWN_TEXT)

    for i = GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_END do
        local activityEntry = self.activitiesDropdown:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_GUILDACTIVITYATTRIBUTEVALUE", i)))
        activityEntry.activityValue = i
        self.activitiesDropdown:AddItem(activityEntry)
    end
end

function ZO_GuildBrowser_GuildList_Keyboard:BuildPersonalitiesDropdown()
    local function OnPersonalitiesDropdownHidden()
        self:RefreshPersonalitiesFilter()
        GUILD_BROWSER_MANAGER:ExecuteSearch()
    end

    self.personalitiesDropdown:ClearItems()
    self.personalitiesDropdown:SetHideDropdownCallback(OnPersonalitiesDropdownHidden)
    self.personalitiesDropdown:SetNoSelectionText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PERSONALITIES))
    self.personalitiesDropdown:SetMultiSelectionTextFormatter(SI_GUILD_BROWSER_GUILD_LIST_PERSONALITIES_DROPDOWN_TEXT)

    for i = GUILD_PERSONALITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_PERSONALITY_ATTRIBUTE_VALUE_ITERATION_END do
        local personalityEntry = self.personalitiesDropdown:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString("SI_GUILDPERSONALITYATTRIBUTEVALUE", i)))
        personalityEntry.personalityValue = i
        self.personalitiesDropdown:AddItem(personalityEntry)
    end
end

function ZO_GuildBrowser_GuildList_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Reset Filters
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_GUILD_BROWSER_RESET_FILTERS_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            enabled = function()
                return not self.filterManager:AreFiltersSetToDefault()
            end,
            callback = function()
                PlaySound(SOUNDS.DIALOG_ACCEPT)
                self:ResetFilters()
                GUILD_BROWSER_MANAGER:ExecuteSearch()
            end,
        },

        -- Report
        {
            name = GetString(SI_GUILD_BROWSER_REPORT_GUILD_KEYBIND),
            keybind = "UI_SHORTCUT_REPORT_PLAYER",
            callback = function()
                local guildToReport = self.currentGuildId
                local function ReportCallback()
                    GUILD_BROWSER_MANAGER:AddReportedGuild(guildToReport)
                end
                local guildData = GUILD_BROWSER_MANAGER:GetGuildData(self.currentGuildId)
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(guildData.guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_LISTING, ReportCallback)
            end,
            visible = function()
                return self.currentGuildId ~= nil
            end
        },

        -- View Guild
        {
            name = GetString(SI_GUILD_BROWSER_GUILD_LIST_VIEW_GUILD_INFO_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ShowGuildInfo(self.currentGuildId)
            end,
            visible = function()
                return self.currentGuildId ~= nil
            end
        },
    }
end

function ZO_GuildBrowser_GuildList_Keyboard:UpdateFilterBar()
    local currentAnchorControl = self.activitiesControl
    self.traderCheckBox:ClearAnchors()
    self.traderCheckBox:SetAnchor(RIGHT, currentAnchorControl, LEFT, -10, 0)
    currentAnchorControl = self.traderCheckBox
    self.traderCheckBox:SetHidden(false)
end

function ZO_GuildBrowser_GuildList_Keyboard:RefreshActivitiesFilter()
    local activityItems = self.activitiesDropdown:GetItems()
    for _, item in ipairs(activityItems) do
        SetGuildFinderActivityFilterValue(item.activityValue, self.activitiesDropdown:IsItemSelected(item))
    end
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_ACTIVITIES, self.activitiesDropdown:GetNumSelectedEntries() <= 0)
end

function ZO_GuildBrowser_GuildList_Keyboard:RefreshPersonalitiesFilter()
    local personalityItems = self.personalitiesDropdown:GetItems()
    for _, item in ipairs(personalityItems) do
        SetGuildFinderPersonalityFilterValue(item.personalityValue, self.personalitiesDropdown:IsItemSelected(item))
    end
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_PERSONALITIES, self.personalitiesDropdown:GetNumSelectedEntries() <= 0)
end

local function IsLanguageFilterComboBoxSetToDefault(comboBox)
    for _, item in ipairs(comboBox:GetItems()) do
        local isCurrentItemDefault = ZO_GuildBrowser_IsGuildAttributeLanguageFilterDefault(item.value)
        if isCurrentItemDefault ~= comboBox:IsItemSelected(item) then
            return false
        end
    end
    return true
end

function ZO_GuildBrowser_GuildList_Keyboard:RefreshAdditionalFilters()
    local dialog = ZO_GuildFinderAdditionalFiltersDialog

    local languageItems = dialog.languagesComboBox:GetItems()
    for _, item in ipairs(languageItems) do
        SetGuildFinderLanguageFilterValue(item.value, dialog.languagesComboBox:IsItemSelected(item))
    end
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_LANGUAGES, IsLanguageFilterComboBoxSetToDefault(dialog.languagesComboBox))

    local sizeItems = dialog.sizeComboBox:GetItems()
    for _, item in ipairs(sizeItems) do
        SetGuildFinderSizeFilterValue(item.value, dialog.sizeComboBox:IsItemSelected(item))
    end
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_SIZE, dialog.sizeComboBox:GetNumSelectedEntries() <= 0)

    local allianceButtons = dialog.allianceButtons
    local isAnyAllianceChecked = false
    for i, buttonName in pairs(ALLIANCE_BUTTON_NAME_TABLE) do
        local button = allianceButtons:GetNamedChild(buttonName)
        local isButtonChecked = ZO_CheckButton_IsChecked(button)
        SetGuildFinderAllianceFilterValue(i, isButtonChecked)
        isAnyAllianceChecked = isAnyAllianceChecked or isButtonChecked
    end
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_ALLIANCE, not isAnyAllianceChecked)

    local isAnyRoleChecked = false
    local roleButtons = dialog.roleSelector.roleButtons
    for _, button in pairs(roleButtons) do
        local isButtonChecked = ZO_CheckButton_IsChecked(button)
        SetGuildFinderRoleFilterValue(button.role, isButtonChecked)
        isAnyRoleChecked = isAnyRoleChecked or isButtonChecked
    end
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_ROLES, not isAnyRoleChecked)

    local minCP = tonumber(dialog.minCPEditBox:GetText())
    local maxCP = tonumber(dialog.maxCPEditBox:GetText())
    local isMinMaxCPDefault = minCP == self.filterManager:GetMinCPDefault() and maxCP == self.filterManager:GetMaxCPDefault()
    SetGuildFinderChampionPointsFilterValues(minCP, maxCP)
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP, isMinMaxCPDefault)

    local startTimeData = dialog.startTimeComboBox:GetSelectedItemData()
    local startTimeHour = startTimeData.value
    local endTimeData = dialog.endTimeComboBox:GetSelectedItemData()
    local endTimeHour = endTimeData.value
    SetGuildFinderPlayTimeFilters(startTimeHour, endTimeHour)
    local defaultHour = self.filterManager:GetTimeDefault()
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_START_TIME, startTimeHour == defaultHour)
    self.filterManager:SetFilterValueIsDefaultByAttributeType(GUILD_META_DATA_ATTRIBUTE_END_TIME, endTimeHour == defaultHour)

    if ZO_Dialogs_IsShowing("GUILD_BROWSER_ADDITIONAL_FILTERS") then
        ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(dialog)
    end
end

function ZO_GuildBrowser_GuildList_Keyboard:RefreshSearchFilters()
    SetGuildFinderFocusSearchFilter(self.focusType)
    SetGuildFinderHasTradersSearchFilter(ZO_CheckButton_IsChecked(self.traderCheckBox.checkButton))
    self:RefreshPersonalitiesFilter()
    self:RefreshActivitiesFilter()
    self:RefreshAdditionalFilters()
end

local function SetLanguageFiltersComboBoxToDefault(comboBox)
    comboBox:ClearAllSelections()

    for _, item in ipairs(comboBox:GetItems()) do
        if ZO_GuildBrowser_IsGuildAttributeLanguageFilterDefault(item.value) then
            comboBox:AddItemToSelected(item)
        end
    end

    comboBox:RefreshSelectedItemText()
end

function ZO_GuildBrowser_GuildList_Keyboard:ResetFilters()
    ZO_CheckButton_SetCheckState(self.traderCheckBox.checkButton, false)
    self.personalitiesDropdown:ClearAllSelections()
    self.activitiesDropdown:ClearAllSelections()

    local dialog = ZO_GuildFinderAdditionalFiltersDialog

    SetLanguageFiltersComboBoxToDefault(dialog.languagesComboBox)
    dialog.sizeComboBox:ClearAllSelections()

    local allianceButtons = dialog.allianceButtons
    for i, buttonName in pairs(ALLIANCE_BUTTON_NAME_TABLE) do
        local button = allianceButtons:GetNamedChild(buttonName)
        ZO_CheckButton_SetCheckState(button, false)
    end

    local roleButtons = dialog.roleSelector.roleButtons
    for _, button in pairs(roleButtons) do
        ZO_CheckButton_SetCheckState(button, false)
    end
    dialog.minCPEditBox:SetText(self.filterManager:GetMinCPDefault())
    dialog.maxCPEditBox:SetText(self.filterManager:GetMaxCPDefault())

    local defaultHour = self.filterManager:GetTimeDefault()
    dialog.startTimeComboBox:SelectFirstItem()
    dialog.endTimeComboBox:SelectFirstItem()
    SetGuildFinderPlayTimeFilters(defaultHour, defaultHour)

    self:RefreshSearchFilters()
end

function ZO_GuildBrowser_GuildList_Keyboard:GuildRow_OnMouseUp(control, button, upInside)
    if upInside then
        self:ShowGuildInfo(control.data.guildId)
        PlaySound(SOUNDS.GUILD_FINDER_SELECT_GUILD)
    end
end

function ZO_GuildBrowser_GuildList_Keyboard:ShowGuildInfo(guildId)
    SCENE_MANAGER:RemoveFragment(self.fragment)
    GUILD_BROWSER_KEYBOARD:SetCategoryTreeHidden(true)
    GUILD_BROWSER_GUILD_INFO_KEYBOARD:ShowWithGuild(guildId, self.onCloseGuildInfoCallback)
end

function ZO_GuildBrowser_GuildList_Keyboard:SetupRow(control, data)
    ZO_GuildBrowser_GuildList_Shared.SetupRow(self, control, data)

    control.guildSizeLabel:SetText(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SIZE), ZO_SELECTED_TEXT:Colorize(data.size)))
end

function ZO_GuildBrowser_GuildList_Keyboard:SetupRowContextualInfo(control, data)
    local contextualInfoHeader, contextualInfoValue = self:GetRowContextualInfo(data)
    control.guildContextualInfoLabel:SetText(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, contextualInfoHeader, ZO_SELECTED_TEXT:Colorize(contextualInfoValue)))
end

function ZO_GuildBrowser_GuildList_Keyboard:OnAdditionalFiltersClicked()
    ZO_Dialogs_ShowDialog("GUILD_BROWSER_ADDITIONAL_FILTERS")
end

function ZO_GuildBrowser_GuildList_Keyboard:GetAllianceIcon(alliance)
    return ZO_GetAllianceSymbolIcon(alliance)
end

function ZO_GuildBrowser_GuildList_Keyboard:OnShowing()
    ZO_GuildBrowser_GuildList_Shared.OnShowing(self)
    self:UpdateFilterBar()
    self:RefreshSearchFilters()
    GUILD_BROWSER_KEYBOARD:SetCategoryTreeHidden(false)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildBrowser_GuildList_Keyboard:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildBrowser_GuildList_Keyboard:OnHidden()
    ZO_GuildBrowser_GuildList_Shared.OnHidden(self)
    self.currentGuildId = nil
end

function ZO_GuildBrowser_GuildList_Keyboard:ShowCategory()
    ZO_GuildBrowser_GuildList_Shared.ShowCategory(self)
end

function ZO_GuildBrowser_GuildList_Keyboard:HideCategory()
    GUILD_BROWSER_GUILD_INFO_KEYBOARD:Close()
    ZO_GuildBrowser_GuildList_Shared.HideCategory(self)
    self.focusType = nil
end

function ZO_GuildBrowser_GuildList_Keyboard:SetSubcategoryValue(newValue)
    if self.focusType ~= newValue then
        self.focusType = newValue
        SetGuildFinderFocusSearchFilter(self.focusType)
        self:UpdateFilterBar()
        GUILD_BROWSER_MANAGER:ExecuteSearch()
    end
end

function ZO_GuildBrowser_GuildList_Keyboard:Row_OnMouseEnter(control)
    ZO_ScrollList_MouseEnter(self.list, control)
    self.currentGuildId = control.data.guildId
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildBrowser_GuildList_Keyboard:Row_OnMouseExit(control)
    ZO_ScrollList_MouseExit(self.list, control)
    self.currentGuildId = nil
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildBrowser_GuildList_Keyboard:OnAdditionalFiltersDialogClose()
    self:RefreshAdditionalFilters()
    GUILD_BROWSER_MANAGER:ExecuteSearch()
end

-- XML Functions
-----------------

function ZO_GuildBrowser_GuildList_AdditionalFilters_OnClicked(control)
    GUILD_BROWSER_GUILD_LIST_KEYBOARD:OnAdditionalFiltersClicked()
end

function ZO_GuildBrowser_GuildList_AdditionalFilters_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, GetString(SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS))
end

function ZO_GuildBrowser_GuildList_AdditionalFilters_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_GuildBrowser_GuildList_Row_OnMouseEnter(control)
    GUILD_BROWSER_GUILD_LIST_KEYBOARD:Row_OnMouseEnter(control)
end

function ZO_GuildBrowser_GuildList_Row_OnMouseExit(control)
    GUILD_BROWSER_GUILD_LIST_KEYBOARD:Row_OnMouseExit(control)
end

function ZO_GuildBrowser_GuildList_Row_OnMouseUp(control, button, upInside)
    GUILD_BROWSER_GUILD_LIST_KEYBOARD:GuildRow_OnMouseUp(control, button, upInside)
end

function ZO_GuildBrowser_GuildList_Alliance_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)

    if data.alliance then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, data.formattedAllianceName)
    end
end

function ZO_GuildBrowser_GuildList_Alliance_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_GuildBrowser_GuildList_Keyboard_OnInitialized(control)
    GUILD_BROWSER_GUILD_LIST_KEYBOARD = ZO_GuildBrowser_GuildList_Keyboard:New(control)
end

-- Additional Filters Dialog XML Functions
------------------------------------------

function ZO_AllianceFilterButton_OnMouseEnter(control)
    if control.alliance then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(control.alliance)))
    end
end

function ZO_AllianceFilterButton_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

do
    local allianceFileNamePrefix =
    {
        [ALLIANCE_ALDMERI_DOMINION] = "aldmeri",
        [ALLIANCE_EBONHEART_PACT] = "ebonheart",
        [ALLIANCE_DAGGERFALL_COVENANT] = "daggerfall",
    }

    function ZO_FilterAllianceButton_OnInitialized(control, alliance)
        local allianceFileName = allianceFileNamePrefix[alliance]
        control:SetNormalTexture(string.format("EsoUI/Art/CharacterCreate/CharacterCreate_%sIcon_up.dds", allianceFileName))
        control:SetPressedTexture(string.format("EsoUI/Art/CharacterCreate/CharacterCreate_%sIcon_down.dds", allianceFileName))
        control:SetMouseOverTexture(string.format("EsoUI/Art/CharacterCreate/CharacterCreate_%sIcon_over.dds", allianceFileName))
        control:SetPressedMouseOverTexture(string.format("EsoUI/Art/CharacterCreate/CharacterCreate_%sIcon_over.dds", allianceFileName))
        control.alliance = alliance

        local function OnAllianceFilterToggled(checkButton, checked)
            SetGuildFinderAllianceFilterValue(checkButton.alliance, checked)
        end

        ZO_CheckButton_SetToggleFunction(control, OnAllianceFilterToggled)
    end
end

local function SetupLanguageFiltersComboBox(comboBox, iterBegin, iterEnd, extraValues, stringBase, defaultText, multiSelectText)
    comboBox:ClearItems()

    comboBox:SetNoSelectionText(defaultText)
    comboBox:SetMultiSelectionTextFormatter(multiSelectText)

    local function AddEntry(value)
        local entry = comboBox:CreateItemEntry(ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString(stringBase, value)))
        entry.value = value
        comboBox:AddItem(entry)
    end

    for i = iterBegin, iterEnd do
        AddEntry(i)
    end

    if extraValues then
        for _, value in ipairs(extraValues) do
            AddEntry(value)
        end
    end
    SetLanguageFiltersComboBoxToDefault(comboBox)
end

local function SetupSizeFilterComboBox(comboBox)
    comboBox:ClearItems()

    comboBox:SetNoSelectionText(GetString(SI_GUILD_BROWSER_GUILD_LIST_FILTERS_DEFAULT_SIZE))
    comboBox:SetMultiSelectionTextFormatter(SI_GUILD_BROWSER_GUILD_LIST_SIZE_DROPDOWN_TEXT)

    for i = GUILD_SIZE_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_SIZE_ATTRIBUTE_VALUE_ITERATION_END do
        local min, max = GetGuildSizeAttributeRangeValues(i)
        local entry = comboBox:CreateItemEntry(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_SIZE_DROPDOWN_ENTRY_TEXT, min, max))
        entry.value = i
        comboBox:AddItem(entry)
    end
end

local function SetupTimeBasedComboBox(comboBox)
    local function OnSelectedCallback(_, entryText, entry)
        comboBox:SetSelectedItemText(entry.name)
    end

    ZO_PopulateHoursSinceMidnightPerHourComboBox(comboBox, OnSelectedCallback)

    local IGNORE_CALLBACK = true
    comboBox:SelectItemByIndex(1, IGNORE_CALLBACK)
end

function ZO_GuildFinderAdditionalFiltersDialog_OnInitialized(self)
    self.confirmButton = self:GetNamedChild("Confirm")
    self.resetButton = self:GetNamedChild("Reset")

    ZO_Dialogs_RegisterCustomDialog("GUILD_BROWSER_ADDITIONAL_FILTERS",
    {
        customControl = self,
        canQueue = true,
        title =
        {
            text = SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS,
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                control = self.confirmButton,
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    GUILD_BROWSER_GUILD_LIST_KEYBOARD:OnAdditionalFiltersDialogClose()
                end
            },
            {
                keybind = "DIALOG_RESET",
                control = self.resetButton,
                text = SI_GUILD_BROWSER_RESET_FILTERS_KEYBIND,
                noReleaseOnClick = true,
                enabled = function(dialog)
                    return not GUILD_BROWSER_GUILD_LIST_KEYBOARD.filterManager:AreFiltersSetToDefault()
                end,
                callback = function(dialog)
                    GUILD_BROWSER_GUILD_LIST_KEYBOARD:ResetFilters()
                end
            },
        },
    })

    self.allianceButtons = self:GetNamedChild("AllianceButtons")
    self.allianceHeaderLabel = self:GetNamedChild("AllianceHeader")
    self.allianceHeaderLabel:SetText(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ALLIANCE)))

    local function OnAllianceButtonToggled(button, isSelected)
        GUILD_BROWSER_GUILD_LIST_KEYBOARD:RefreshAdditionalFilters()
    end

    for i, buttonName in pairs(ALLIANCE_BUTTON_NAME_TABLE) do
        local button = self.allianceButtons:GetNamedChild(buttonName)
        ZO_CheckButton_SetToggleFunction(button, OnAllianceButtonToggled)
    end

    self.roleSelectorControl = self:GetNamedChild("RoleSelector")
    self.roleSelector = ZO_RoleMultiSelector_GetObjectFromControl(self.roleSelectorControl)
    self.rolesHeaderLabel = self:GetNamedChild("RolesHeader")
    self.rolesHeaderLabel:SetText(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES)))

    local function OnRoleSelectorToggled(button, isSelected)
        SetGuildFinderRoleFilterValue(button.role, isSelected)
        GUILD_BROWSER_GUILD_LIST_KEYBOARD:RefreshAdditionalFilters()
    end
    self.roleSelector:SetToggleFunction(OnRoleSelectorToggled)

    self.languageHeaderLabel = self:GetNamedChild("LanguageHeader")
    self.languageHeaderLabel:SetText(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_LANGUAGES)))

    self.sizeHeaderLabel = self:GetNamedChild("SizeHeader")
    self.sizeHeaderLabel:SetText(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SIZE)))

    self.timeHeaderLabel = self:GetNamedChild("TimeHeader")
    self.timeHeaderLabel:SetText(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS_HEADER_FORMATTER, GetString(SI_GUILD_FINDER_CORE_HOURS_LABEL)))

    local function OnComboboxSelectionChanged()
        GUILD_BROWSER_GUILD_LIST_KEYBOARD:RefreshAdditionalFilters()
    end

    self.languagesComboBox = ZO_ComboBox_ObjectFromContainer(self:GetNamedChild("LanguageSelector"))
    self.languagesComboBox:SetSortsItems(false)
    self.languagesComboBox:SetHideDropdownCallback(OnComboboxSelectionChanged)
    SetupLanguageFiltersComboBox(self.languagesComboBox, GUILD_LANGUAGE_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_LANGUAGE_ATTRIBUTE_VALUE_ITERATION_END, { GUILD_LANGUAGE_ATTRIBUTE_VALUE_OTHER }, "SI_GUILDLANGUAGEATTRIBUTEVALUE", GetString(SI_GUILD_BROWSER_GUILD_LIST_FILTERS_DEFAULT_LANGUAGE), SI_GUILD_BROWSER_GUILD_LIST_LANGUAGES_DROPDOWN_TEXT)

    self.sizeComboBox = ZO_ComboBox_ObjectFromContainer(self:GetNamedChild("SizeSelector"))
    self.sizeComboBox:SetSortsItems(false)
    self.sizeComboBox:SetHideDropdownCallback(OnComboboxSelectionChanged)
    SetupSizeFilterComboBox(self.sizeComboBox)

    self.startTimeComboBox = ZO_ComboBox_ObjectFromContainer(self:GetNamedChild("StartTimeSelector"))
    self.startTimeComboBox:SetSortsItems(false)
    self.startTimeComboBox:SetHideDropdownCallback(OnComboboxSelectionChanged)
    SetupTimeBasedComboBox(self.startTimeComboBox)

    self.endTimeComboBox = ZO_ComboBox_ObjectFromContainer(self:GetNamedChild("EndTimeSelector"))
    self.endTimeComboBox:SetSortsItems(false)
    self.endTimeComboBox:SetHideDropdownCallback(OnComboboxSelectionChanged)
    SetupTimeBasedComboBox(self.endTimeComboBox)

    self.minCPHeaderLabel = self:GetNamedChild("CPHeader")
    self.minCPHeaderLabel:SetText(zo_strformat(SI_GUILD_BROWSER_GUILD_LIST_ADDITIONAL_FILTERS_HEADER_FORMATTER, GetString(SI_GUILD_BROWSER_CHAMPION_POINT_RANGE_HEADER)))

    self.minCPControl = self:GetNamedChild("MinCP")
    self.minCPEditBox = self.minCPControl:GetNamedChild("BackdropEdit")
    self.minCPEditBox:SetText(GUILD_BROWSER_GUILD_LIST_KEYBOARD.filterManager:GetMinCPDefault())

    self.maxCPControl = self:GetNamedChild("MaxCP")
    self.maxCPEditBox = self.maxCPControl:GetNamedChild("BackdropEdit")
    self.maxCPEditBox:SetText(GUILD_BROWSER_GUILD_LIST_KEYBOARD.filterManager:GetMaxCPDefault())

    local function OnMinCPTextEditFocusLost(...)
        local maxAllowedValue = ZO_GuildFinder_Manager.GetMaxCPAllowedForInput()
        local minCP = tonumber(self.minCPEditBox:GetText())
        local maxCP = tonumber(self.maxCPEditBox:GetText())
        if minCP == nil then
            local defaultMin = GUILD_BROWSER_GUILD_LIST_KEYBOARD.filterManager:GetMinCPDefault()
            self.minCPEditBox:SetText(defaultMin)
            SetGuildFinderChampionPointsFilterValues(defaultMin, maxCP)
        elseif minCP > maxCP then
            minCP = maxCP
            self.minCPEditBox:SetText(minCP)
            SetGuildFinderChampionPointsFilterValues(minCP, maxCP)
        elseif minCP > maxAllowedValue then
            minCP = maxAllowedValue
            self.minCPEditBox:SetText(minCP)
            SetGuildFinderChampionPointsFilterValues(minCP, maxCP)
        end
        GUILD_BROWSER_GUILD_LIST_KEYBOARD:RefreshAdditionalFilters()
    end

    local function OnMaxCPTextEditFocusLost(...)
        local maxAllowedValue = ZO_GuildFinder_Manager.GetMaxCPAllowedForInput()
        local minCP = tonumber(self.minCPEditBox:GetText())
        local maxCP = tonumber(self.maxCPEditBox:GetText())
        if maxCP == nil then
            local defaultMax = GUILD_BROWSER_GUILD_LIST_KEYBOARD.filterManager:GetMaxCPDefault()
            self.maxCPEditBox:SetText(defaultMax)
            SetGuildFinderChampionPointsFilterValues(minCP, defaultMax)
        elseif maxCP < minCP then
            maxCP = minCP
            self.maxCPEditBox:SetText(maxCP)
            SetGuildFinderChampionPointsFilterValues(minCP, maxCP)
        elseif maxCP > maxAllowedValue then
            maxCP = maxAllowedValue
            self.maxCPEditBox:SetText(maxCP)
            SetGuildFinderChampionPointsFilterValues(minCP, maxCP)
        end
        GUILD_BROWSER_GUILD_LIST_KEYBOARD:RefreshAdditionalFilters()
    end

    local function OnTextChanged(...)
        local minCP = tonumber(self.minCPEditBox:GetText())
        local maxCP = tonumber(self.maxCPEditBox:GetText())
        SetGuildFinderChampionPointsFilterValues(minCP, maxCP)
    end

    self.minCPEditBox:SetHandler("OnFocusLost", OnMinCPTextEditFocusLost)
    self.minCPEditBox:SetHandler("OnTextChanged", OnTextChanged)

    self.maxCPEditBox:SetHandler("OnFocusLost", OnMaxCPTextEditFocusLost)
    self.maxCPEditBox:SetHandler("OnTextChanged", OnTextChanged)
end