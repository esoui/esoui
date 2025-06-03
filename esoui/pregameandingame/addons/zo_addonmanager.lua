ZO_ADDON_LIST_HEIGHT = 630
ZO_ADDON_ROW_HEIGHT = 30
ZO_ADDON_SECTION_HEADER_ROW_HEIGHT = 50

local ADDON_DATA = 1
local SECTION_HEADER_DATA = 2
local IS_LIBRARY = true
local IS_ADDON = false

local AddOnManager = GetAddOnManager()

ZO_AddOnManager = ZO_SortFilterList:Subclass()

function ZO_AddOnManager:New(...)
    local control = CreateControlFromVirtual("ZO_AddOns", GuiRoot, "ZO_AddOnManagerTemplate")
    return ZO_SortFilterList.New(self, control, ...)
end

function ZO_AddOnManager:Initialize(control, primaryKeybindDescriptor, secondaryKeybindDescriptor)
    ZO_SortFilterList.Initialize(self, control)

    self.primaryKeybindDescriptor = primaryKeybindDescriptor
    self.secondaryKeybindDescriptor = secondaryKeybindDescriptor

    self.control:SetHandler("OnShow", function() self:OnShow() end)

    self.sizerLabel = CreateControlFromVirtual("", self.control, "ZO_AddOn_SizerLabel")
    self.currentSortKey = "strippedAddOnName"
    self.currentSortDirection = ZO_SORT_ORDER_UP
    self.sortKeys =
    {
        addOnFileName = { },
        strippedAddOnName = { tiebreaker = "addOnFileName" },
    }
    self.sortCallback = function(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, self.currentSortKey, self.sortKeys, self.currentSortDirection)
    end

    ZO_ScrollList_SetHeight(self.list, ZO_ADDON_LIST_HEIGHT)
    ZO_ScrollList_AddDataType(self.list, ADDON_DATA, "ZO_AddOnRow", ZO_ADDON_ROW_HEIGHT, self:GetRowSetupFunction())
    ZO_ScrollList_AddDataType(self.list, SECTION_HEADER_DATA, "ZO_AddOnSectionHeaderRow", ZO_ADDON_SECTION_HEADER_ROW_HEIGHT, function(...) self:SetupSectionHeaderRow(...) end)

    self.advancedErrorCheck = self.control:GetNamedChild("AdvancedUIErrors")
    ZO_CheckButton_SetToggleFunction(self.advancedErrorCheck, function(checkButton, isChecked) SetCVar("UIErrorAdvancedView", isChecked and "1" or "0") end)
    ZO_CheckButton_SetCheckState(self.advancedErrorCheck, GetCVar("UIErrorAdvancedView") == "1")
    ZO_CheckButton_SetLabelText(self.advancedErrorCheck, GetString(SI_ADDON_MANAGER_ADVANCED_UI_ERRORS))

    self.characterDropdown = ZO_ComboBox_ObjectFromContainer(self.control:GetNamedChild("CharacterSelectDropdown"))
    self.characterDropdown:SetSortsItems(false)

    local function OnAddOnEulaHidden()
        local hasAgreed = HasAgreedToEULA(EULA_TYPE_ADDON_EULA)
        self.characterDropdown:SetEnabled(hasAgreed)

        self.isDirty = true

        self:RefreshKeybinds()
        self:RefreshData()
    end

    CALLBACK_MANAGER:RegisterCallback("AddOnEULAHidden", OnAddOnEulaHidden)

    ADDONS_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    ADDONS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            PushActionLayerByName("Addons")
        elseif newState == SCENE_FRAGMENT_HIDING then
            RemoveActionLayerByName("Addons")
        end
    end)

    --Uses a namespace event registration because ZO_ReanchorControlForLeftSidePanel registers EVENT_SCREEN_RESIZED on the control
    EVENT_MANAGER:RegisterForEvent("AddOnManager", EVENT_SCREEN_RESIZED, function() self:RefreshData() end)

    local function OnForceDisabledAddonsUpdated()
        if ADDONS_FRAGMENT:IsShowing() then
            self:RefreshData()
        end
    end
    EVENT_MANAGER:RegisterForEvent("AddOnManager", EVENT_FORCE_DISABLED_ADDONS_UPDATED, OnForceDisabledAddonsUpdated)
    ZO_ReanchorControlForLeftSidePanel(self.control)
end

local function GetCharacterNameFromDatum(datum)
    return zo_strformat(SI_UNIT_NAME, datum.name)
end

local g_uniqueNamesByCharacterName = {}

local function CreateAddOnFilter(characterName)
    local uniqueName = g_uniqueNamesByCharacterName[characterName]
    if not uniqueName then
        uniqueName = GetUniqueNameForCharacter(characterName)
        g_uniqueNamesByCharacterName[characterName] = uniqueName
    end
    return uniqueName
end

local COMBINED_STATE_RESULT_NO_DEP_ERRORS = 1
local COMBINED_STATE_RESULT_SOME_DEP_ERRORS = 2
local COMBINED_STATE_RESULT_ALL_DEP_ERRORS = 3

function ZO_AddOnManager:GetRowSetupFunction()
    local function SetSimpleTriStateCheckButton(enabled, data)
        if data.addOnEnabled then
            ZO_TriStateCheckButton_SetState(enabled, TRISTATE_CHECK_BUTTON_CHECKED)
        else
            ZO_TriStateCheckButton_SetState(enabled, TRISTATE_CHECK_BUTTON_UNCHECKED)
        end
    end

    local function SetupNotes(state, data)
        local stateText = ""

        if data.isOutOfDate then
            stateText = GetString("SI_ADDONLOADSTATE", ADDON_STATE_VERSION_MISMATCH)
        end

        if not self.isAllFilterSelected then
            if data.hasDependencyError then
                if stateText == "" then
                    stateText = ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_DEPENDENCIES_DISABLED))
                else
                    stateText = zo_strformat(SI_ADDON_MANAGER_STATE_STRING, stateText, ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_DEPENDENCIES_DISABLED)))
                end
            end
        end

        local color = AddOnManager:AreAddOnsEnabled() and ZO_DEFAULT_ENABLED_COLOR or ZO_DEFAULT_DISABLED_COLOR
        state:SetColor(color:UnpackRGBA())
        state:SetText(stateText)
    end

    local function UpdateNameAndAuthor(control, isEnabled, data)
        local checkboxControl = control:GetNamedChild("Enabled")
        local expandControl = control:GetNamedChild("ExpandButton")
        local checkState = ZO_TriStateCheckButton_GetState(checkboxControl)

        local nameControl = control:GetNamedChild("Name")
        local authorControl = control:GetNamedChild("Author")

        local color
        local stripColorMarkup

        local areAddOnsEnabled = AddOnManager:AreAddOnsEnabled()

        if not isEnabled then
            color = ZO_ERROR_COLOR
            stripColorMarkup = true
        elseif checkState == TRISTATE_CHECK_BUTTON_UNCHECKED or not areAddOnsEnabled then
            color = ZO_DEFAULT_DISABLED_COLOR
            stripColorMarkup = true
        else
            color = ZO_DEFAULT_ENABLED_COLOR
            stripColorMarkup = false
        end

        ZO_CheckButton_SetEnableState(checkboxControl, areAddOnsEnabled)
        ZO_CheckButton_SetEnableState(expandControl, areAddOnsEnabled)

        nameControl:SetColor(color:UnpackRGBA())
        authorControl:SetColor(color:UnpackRGBA())

        nameControl:SetText(stripColorMarkup and data.strippedAddOnName or data.addOnName)
        local authorByLine = stripColorMarkup and data.strippedAddOnAuthorByLine or data.addOnAuthorByLine
        authorControl:SetText(authorByLine)
    end

    return function(control, data)
        control.owner = self
        control.data = data
        local name = control:GetNamedChild("Name")
        local enabledControl = control:GetNamedChild("Enabled")
        local state = control:GetNamedChild("State")
        local description = control:GetNamedChild("Description")
        local dependencies = control:GetNamedChild("Dependencies")
        local expandButton = control:GetNamedChild("ExpandButton")

        control:SetHeight(data.height)

        expandButton:SetHidden(not data.expandable)
        if data.expandable then
            ZO_ToggleButton_SetState(expandButton, data.expanded and TOGGLE_BUTTON_OPEN or TOGGLE_BUTTON_CLOSED)
        end

        local showDescription = data.expanded and data.addOnDescription ~= ""
        description:SetHidden(not showDescription)
        description:ClearAnchors()
        if showDescription then
            description:SetText(data.addOnDescription)
            description:SetAnchor(TOPLEFT, name, BOTTOMLEFT, 20, 18)
        else
            description:SetText("")
            description:SetAnchor(TOPLEFT, name, BOTTOMLEFT, 20, 0)
        end

        local showDependencies = data.expanded and data.addOnDependencyText ~= ""
        dependencies:SetHidden(not showDependencies)
        if showDependencies then
            dependencies:SetText(GetString(SI_ADDON_MANAGER_DEPENDENCIES)..data.addOnDependencyText)
        else
            dependencies:SetText("")
        end

        local isEnabled = HasAgreedToEULA(EULA_TYPE_ADDON_EULA)

        if self.isAllFilterSelected then
            local allEnabled, allDisabled
            allEnabled, allDisabled = self:GetCombinedAddOnStates(data.index)

            if allEnabled then
                ZO_TriStateCheckButton_SetState(enabledControl, TRISTATE_CHECK_BUTTON_CHECKED)
            elseif allDisabled then
                ZO_TriStateCheckButton_SetState(enabledControl, TRISTATE_CHECK_BUTTON_UNCHECKED)
            else
                ZO_TriStateCheckButton_SetState(enabledControl, TRISTATE_CHECK_BUTTON_INDETERMINATE)
            end
            enabledControl:SetHidden(not isEnabled)
        else
            SetSimpleTriStateCheckButton(enabledControl, data)
            isEnabled = isEnabled and not data.hasDependencyError
            enabledControl:SetHidden(not isEnabled)
        end

        UpdateNameAndAuthor(control, isEnabled, data)

        ZO_TriStateCheckButton_SetStateChangeFunction(enabledControl, function(buttonControl, checkState) self:OnEnabledButtonClicked(buttonControl, checkState) end)

        SetupNotes(state, data)
    end
end

function ZO_AddOnManager:SetupSectionHeaderRow(control, data)
    control.textControl:SetText(data.text)
    if data.isLibrary then
        control.checkboxControl:SetHidden(true)
    else
        control.checkboxControl:SetHidden(false)
        ZO_CheckButton_SetCheckState(control.checkboxControl, AddOnManager:AreAddOnsEnabled())
        ZO_CheckButton_SetToggleFunction(control.checkboxControl, function(checkboxControl, isBoxChecked)
            local scrollData = ZO_ScrollList_GetDataList(control:GetParent():GetParent())

            AddOnManager:SetAddOnsEnabled(isBoxChecked)
            if not isBoxChecked then
                for _, addOn in ipairs(scrollData) do
                    local addOnData = addOn.data
                    if addOnData.addOnFileName and addOnData.expanded then
                        self:ToggleExpandedData(addOnData)
                    end
                end
            end

            self.isDirty = true
            self:RefreshKeybinds()
            self:RefreshData()
        end)
    end
end

function ZO_AddOnManager:GetCombinedAddOnStates(index)
    local allEnabled = true
    local allDisabled = true
    local combinedStateResult = nil

    if self.isAllFilterSelected and self.characterData then
        for i, dataEntry in ipairs(self.characterData) do
            local datum = dataEntry.data
            local filter = CreateAddOnFilter(datum.name)
            AddOnManager:SetAddOnFilter(filter)
            local enabled, state = select(5, AddOnManager:GetAddOnInfo(index))

            if enabled then
                allDisabled = false
            else
                allEnabled = false
            end

            if combinedStateResult == nil then
                if state == ADDON_STATE_DEPENDENCIES_DISABLED then
                    combinedStateResult = COMBINED_STATE_RESULT_ALL_DEP_ERRORS
                else
                    combinedStateResult = COMBINED_STATE_RESULT_NO_DEP_ERRORS
                end
            else
                if state == ADDON_STATE_DEPENDENCIES_DISABLED then
                    if combinedStateResult == COMBINED_STATE_RESULT_NO_DEP_ERRORS then
                        combinedStateResult = COMBINED_STATE_RESULT_SOME_DEP_ERRORS
                    end
                else
                    if combinedStateResult == COMBINED_STATE_RESULT_ALL_DEP_ERRORS then
                        combinedStateResult = COMBINED_STATE_RESULT_SOME_DEP_ERRORS
                    end
                end
            end
        end

        AddOnManager:RemoveAddOnFilter()
    end

    return allEnabled, allDisabled, combinedStateResult or COMBINED_STATE_RESULT_NO_DEP_ERRORS
end

function ZO_AddOnManager:SetCharacterData(characterData)
    self.characterData = characterData
    AddOnManager:ResetRelevantFilters()

    if self.characterData then
        for i, dataEntry in ipairs(self.characterData) do
            local datum = dataEntry.data
            AddOnManager:AddRelevantFilter(CreateAddOnFilter(datum.name))
        end
    end
end

function ZO_AddOnManager:GetNumCharacters()
    if self.characterData then
        return #self.characterData
    end
    return 0
end

function ZO_AddOnManager:GetCharacterInfo(characterIndex)
    if self.characterData then
        local characterDataEntry = self.characterData[characterIndex]
        local characterDatum = characterDataEntry.data
        return characterDatum and GetCharacterNameFromDatum(characterDatum) or nil
    end
end

function ZO_AddOnManager:OnCharacterChanged(name, entry)
    self.selectedCharacterEntry = entry
    self:RefreshData()
end

function ZO_AddOnManager:BuildCharacterDropdown()
    self.characterDropdown:ClearItems()

    local function OnCharacterChanged(comboBox, name, entry)
        self:OnCharacterChanged(name, entry)
    end

    if self.characterData then
        self.characterDropdown:GetContainer():SetHidden(false)

        local allCharactersEntry = self.characterDropdown:CreateItemEntry(GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL), OnCharacterChanged)
        allCharactersEntry.allCharacters = true
        self.characterDropdown:AddItem(allCharactersEntry)

        local characterNames = {}
        for i = 1, self:GetNumCharacters() do
            local name = self:GetCharacterInfo(i)
            table.insert(characterNames, name)
        end
        table.sort(characterNames)
        for _, characterName in ipairs(characterNames) do
            local entry = self.characterDropdown:CreateItemEntry(characterName, OnCharacterChanged)
            entry.allCharacters = false
            self.characterDropdown:AddItem(entry)
        end

        self.characterDropdown:SelectFirstItem()
    else
        self.characterDropdown:GetContainer():SetHidden(true)

        local playerName = GetUnitName("player")
        self.selectedCharacterEntry = { name = playerName ~= "" and playerName or nil, allCharacters = false }
        self.isAllFilterSelected = false
    end
end

function ZO_AddOnManager:LayoutAdvancedErrorCheck()
    --Set this again in case the value changed while the screen was closed
    ZO_CheckButton_SetCheckState(self.advancedErrorCheck, GetCVar("UIErrorAdvancedView") == "1")

    self.advancedErrorCheck:ClearAnchors()
    --Adjust the anchoring of the checkbox depending on if the character dropdown is showing
    if self.characterData then
        self.advancedErrorCheck:SetAnchor(LEFT, self.characterDropdown:GetContainer(), RIGHT, 15)
    else
        self.advancedErrorCheck:SetAnchor(TOPLEFT, self.control:GetNamedChild("Divider"), BOTTOMLEFT, 0, 5)
    end
end

function ZO_AddOnManager:ChangeEnabledState(index, checkState)
    AddOnManager:SetAddOnEnabled(index, checkState == TRISTATE_CHECK_BUTTON_CHECKED)
    self:RefreshData()
end

local expandedAddons = {}
local heightIds = {}

local g_currentTypeId = 2

local function GetHeightTypeId(height)
    if heightIds[height] then
        return heightIds[height]
    else
        heightIds[height] = g_currentTypeId
        g_currentTypeId = g_currentTypeId + 1
        return heightIds[height]
    end
end

function ZO_AddOnManager:SetupTypeId(description, dependencyText)
    local descriptionHeight = 0
    if description ~= "" then
        self.sizerLabel:SetText(description)
        descriptionHeight = self.sizerLabel:GetTextHeight() + 18
    end

    local dependencyHeight = 0
    if dependencyText ~= "" then
        self.sizerLabel:SetText(dependencyText)
        dependencyHeight = self.sizerLabel:GetTextHeight() + 23
    end

    local useHeight = zo_ceil(ZO_ADDON_ROW_HEIGHT + descriptionHeight + dependencyHeight + 31)
    local typeId = GetHeightTypeId(useHeight)

    local existingDataTypeTable = ZO_ScrollList_GetDataTypeTable(self.list, typeId)
    if not existingDataTypeTable then
        ZO_ScrollList_AddDataType(self.list, typeId, "ZO_AddOnRow", useHeight, self:GetRowSetupFunction())
    else
        existingDataTypeTable.height = useHeight
    end

    return useHeight, typeId
end

function ZO_AddOnManager:ResetDataTypes()
    g_currentTypeId = 3
    heightIds = {}
end

local function StripText(text)
    return text:gsub("|c%x%x%x%x%x%x", "")
end

function ZO_AddOnManager:BuildMasterList()
    self.addonTypes = {}
    self.addonTypes[IS_LIBRARY] = {}
    self.addonTypes[IS_ADDON] = {}
    local areAddOnsEnabled = AddOnManager:AreAddOnsEnabled()

    if self.selectedCharacterEntry and not self.selectedCharacterEntry.allCharacters then
        self.isAllFilterSelected = false
        AddOnManager:SetAddOnFilter(CreateAddOnFilter(self.selectedCharacterEntry.name))
    else
        self.isAllFilterSelected = true
        AddOnManager:RemoveAddOnFilter()
    end

    for i = 1, AddOnManager:GetNumAddOns() do
        local name, title, author, description, enabled, state, isOutOfDate, isLibrary = AddOnManager:GetAddOnInfo(i)
        local entryData = {
            index = i,
            addOnFileName = name,
            addOnName = title,
            strippedAddOnName = StripText(title),
            addOnDescription = description,
            addOnEnabled = enabled,
            addOnState = state,
            isOutOfDate = isOutOfDate,
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

        local dependencyText = ""
        for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
            local dependencyName, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion = AddOnManager:GetAddOnDependencyInfo(i, j)
            local dependencyTooLowVersion = dependencyVersion < dependencyMinVersion
            local dependencyInfoLine = dependencyName
            if not self.isAllFilterSelected and (not dependencyActive or not dependencyExists or dependencyTooLowVersion) then
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
            dependencyText = string.format("%s\n    %s  %s", dependencyText, GetString(SI_BULLET), dependencyInfoLine)
        end
        entryData.addOnDependencyText = dependencyText

        entryData.expandable = (description ~= "") or (dependencyText ~= "")
        
        table.insert(self.addonTypes[isLibrary], entryData)
    end
end

function ZO_AddOnManager:AddAddonTypeSection(isLibrary, sectionTitleText)
    local addonEntries = self.addonTypes[isLibrary]
    table.sort(addonEntries, self.sortCallback)

    local scrollData = ZO_ScrollList_GetDataList(self.list)
    scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(SECTION_HEADER_DATA, { isLibrary = isLibrary, text = sectionTitleText })
    for _, entryData in ipairs(addonEntries) do
        if entryData.expandable and expandedAddons[entryData.index] then
            entryData.expanded = true

            local useHeight, typeId = self:SetupTypeId(entryData.addOnDescription, entryData.addOnDependencyText)

            entryData.height = useHeight
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(typeId, entryData)
        else
            entryData.height = ZO_ADDON_ROW_HEIGHT
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ADDON_DATA, entryData)
        end
    end
end

function ZO_AddOnManager:SortScrollList()
    self:ResetDataTypes()
    local scrollData = ZO_ScrollList_GetDataList(self.list)        
    ZO_ClearNumericallyIndexedTable(scrollData)

    self:AddAddonTypeSection(IS_ADDON, GetString(SI_WINDOW_TITLE_ADDON_MANAGER))
    self:AddAddonTypeSection(IS_LIBRARY, GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES))
end

function ZO_AddOnManager:OnShow()
    self:BuildCharacterDropdown()
    self:LayoutAdvancedErrorCheck()
    self:RefreshData()
    self:RefreshKeybinds()
    CALLBACK_MANAGER:FireCallbacks("ShowAddOnEULAIfNecessary")
end

function ZO_AddOnManager:UpdateKeybindButton(keybindButton, descriptor)
    local visible = descriptor.visible or true
    if type(visible) == "function" then
        visible = visible()
    end

    keybindButton:SetHidden(not visible)

    local enabled = descriptor.enabled or true
    if type(enabled) == "function" then
        enabled = enabled()
    end

    keybindButton:SetEnabled(enabled)
end

function ZO_AddOnManager:RefreshKeybinds()
    local primaryButton = self.control:GetNamedChild("PrimaryButton")
    primaryButton:SetKeybindButtonDescriptor(self.primaryKeybindDescriptor)
    self:UpdateKeybindButton(primaryButton, self.primaryKeybindDescriptor)

    if self.secondaryKeybindDescriptor then
        local secondaryButton = self.control:GetNamedChild("SecondaryButton")
        secondaryButton:SetKeybindButtonDescriptor(self.secondaryKeybindDescriptor)
        self:UpdateKeybindButton(secondaryButton, self.secondaryKeybindDescriptor)
    end

    self:RefreshSavedKeybindsLabel()
end

function ZO_AddOnManager:OnMouseEnter(control)
    if self.isAllFilterSelected then
        InitializeTooltip(InformationTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)

        local state = ZO_TriStateCheckButton_GetState(control)
        if state == TRISTATE_CHECK_BUTTON_CHECKED then
            SetTooltipText(InformationTooltip, GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_ALL))
        elseif state == TRISTATE_CHECK_BUTTON_UNCHECKED then
            SetTooltipText(InformationTooltip, GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_NONE))
        elseif state == TRISTATE_CHECK_BUTTON_INDETERMINATE then
            SetTooltipText(InformationTooltip, GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_SOME))
        end
    end
end

function ZO_AddOnManager:OnEnabledButtonClicked(control, checkState)
    local row = control:GetParent()
    self:ChangeEnabledState(row.data.index, checkState)
    self.isDirty = true
    self:RefreshKeybinds()
end

function ZO_AddOnManager:OnExpandButtonClicked(row)
    local data = ZO_ScrollList_GetData(row)
    self:ToggleExpandedData(data)
    row.owner:CommitScrollList()
end

function ZO_AddOnManager:ToggleExpandedData(data)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    if expandedAddons[data.index] then
        expandedAddons[data.index] = false

        data.expanded = false
        data.height = ZO_ADDON_ROW_HEIGHT
        scrollData[data.sortIndex] = ZO_ScrollList_CreateDataEntry(ADDON_DATA, data)
    else
        expandedAddons[data.index] = true

        local useHeight, typeId = self:SetupTypeId(data.addOnDescription, data.addOnDependencyText)

        data.expanded = true
        data.height = useHeight
        scrollData[data.sortIndex] = ZO_ScrollList_CreateDataEntry(typeId, data)
    end
end

function ZO_AddOnManager:AllowReload()
    return self.isDirty
end

function ZO_AddOnManager:OnPrimaryButtonPressed()
    local primaryButton = self.control:GetNamedChild("PrimaryButton")
    primaryButton:OnClicked()
end

function ZO_AddOnManager:OnSecondaryButtonPressed()
    local secondaryButton = self.control:GetNamedChild("SecondaryButton")
    if self.secondaryKeybindDescriptor then
        secondaryButton:OnClicked()
    end
end

function ZO_AddOnManager:SetRefreshSavedKeybindsLabelFunction(refreshFunction)
    self.refreshSavedKeybindsLabelFunction = refreshFunction
end

function ZO_AddOnManager:RefreshSavedKeybindsLabel()
    local keybindsLabel = self.control:GetNamedChild("CurrentBindingsSaved")
    if not self.refreshSavedKeybindsLabelFunction then
        keybindsLabel:SetHidden(true)
        return
    end

    self.refreshSavedKeybindsLabelFunction(keybindsLabel)
end

---
-- Global Functions
---

function ZO_AddOnManager_OnExpandButtonClicked(control)
    local row = control:GetParent()
    row.owner:OnExpandButtonClicked(row)
end

function ZO_AddOnManager_OnEnabledButtonMouseEnter(control)
    local row = control:GetParent()
    row.owner:OnMouseEnter(control)
end

function ZO_AddOnManagerPrimaryButton_Callback()
    ADD_ON_MANAGER:OnPrimaryButtonPressed()
end

function ZO_AddOnManagerSecondaryButton_Callback()
    ADD_ON_MANAGER:OnSecondaryButtonPressed()
end
