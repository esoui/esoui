local LIST_HEIGHT = 660
local ROW_HEIGHT = 30
local ADDON_DATA = 1

local AddOnManager = GetAddOnManager()

ZO_AddOnManager = ZO_SortFilterList:Subclass()

function ZO_AddOnManager:New(...)
    local control = CreateControlFromVirtual("ZO_AddOns", GuiRoot, "ZO_AddOnManagerTemplate")
    return ZO_SortFilterList.New(self, control, ...)
end

function ZO_AddOnManager:Initialize(control, allowReload)
    ZO_SortFilterList.Initialize(self, control, allowReload)
    self.allowReload = allowReload
    self.control:SetHandler("OnShow", function() self:OnShow() end)

    self.sizerLabel = CreateControlFromVirtual("", self.control, "ZO_AddOn_SizerLabel")

    ZO_ScrollList_SetHeight(self.list, LIST_HEIGHT)
    ZO_ScrollList_AddDataType(self.list, ADDON_DATA, "ZO_AddOnRow", ROW_HEIGHT, self:GetRowSetupFunction())

    self.characterDropdown = ZO_ComboBox:New(GetControl(self.control, "CharacterSelectDropdown"))

    local function OnLoadOutOfDateAddonsClicked(checkButton, isChecked)
        AddOnManager:SetLoadOutOfDateAddOns(isChecked)

        self.isDirty = true

        self:RefreshMultiButton()
        self:RefreshData()
    end

    local loadOutOfDateCheck = self.control:GetNamedChild("LoadOutOfDateAddOns")
    ZO_CheckButton_SetToggleFunction(loadOutOfDateCheck, OnLoadOutOfDateAddonsClicked)
    ZO_CheckButton_SetCheckState(loadOutOfDateCheck, AddOnManager:GetLoadOutOfDateAddOns())

    local function OnAddOnEulaHidden()
        local hasAgreed = HasAgreedToEULA(EULA_TYPE_ADDON_EULA)
        self.characterDropdown:SetEnabled(hasAgreed)
        ZO_CheckButton_SetEnableState(loadOutOfDateCheck, hasAgreed)

        self.isDirty = true

        self:RefreshMultiButton()
        self:RefreshData()
    end

    CALLBACK_MANAGER:RegisterCallback("AddOnEULAHidden", OnAddOnEulaHidden)

    ADDONS_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    ADDONS_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                if(newState == SCENE_FRAGMENT_SHOWING) then
                                                    PushActionLayerByName("Addons")
                                                elseif(newState == SCENE_FRAGMENT_HIDING) then
                                                    RemoveActionLayerByName("Addons")
                                                end
                                            end)

    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:RefreshData() end)
    ZO_ReanchorControlForLeftSidePanel(self.control)
end

local function GetCharacterNameFromDatum(datum)
    return zo_strformat(SI_UNIT_NAME, datum.name)
end

local function CreateAddOnFilter(characterName)
    return GetUniqueNameForCharacter(characterName)
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

        if self.isAllFilterSelected then
            if data.isOutOfDate then
                if AddOnManager:GetLoadOutOfDateAddOns() then
                    stateText = GetString("SI_ADDONLOADSTATE", ADDON_STATE_VERSION_MISMATCH)
                else
                    stateText = ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_VERSION_MISMATCH))
                end
            end
        else
            if data.isOutOfDate then
                if AddOnManager:GetLoadOutOfDateAddOns() then
                    stateText = GetString("SI_ADDONLOADSTATE", ADDON_STATE_VERSION_MISMATCH)
                else
                    stateText = ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_VERSION_MISMATCH))
                end
            end

            if data.hasDependencyError then
                if stateText == "" then
                    stateText = ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_DEPENDENCIES_DISABLED))
                else
                    stateText = zo_strformat(SI_ADDON_MANAGER_STATE_STRING, stateText, ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_DEPENDENCIES_DISABLED)))
                end
            end
        end

        state:SetText(stateText)
    end

    local function UpdateNameAndAuthor(control, isEnabled, data)
        local checkboxControl = GetControl(control, "Enabled")
        local checkState = ZO_TriStateCheckButton_GetState(checkboxControl)

        local nameControl = GetControl(control, "Name")
        local authorControl = GetControl(control, "Author")

        local color
        local stripColorMarkup

        if not isEnabled then
            color = ZO_ERROR_COLOR
            stripColorMarkup = true
        elseif checkState == TRISTATE_CHECK_BUTTON_UNCHECKED then
            color = ZO_DEFAULT_DISABLED_COLOR
            stripColorMarkup = true
        else
            color = ZO_DEFAULT_ENABLED_COLOR
            stripColorMarkup = false
        end

        nameControl:SetColor(color:UnpackRGBA())
        authorControl:SetColor(color:UnpackRGBA())

        nameControl:SetText(stripColorMarkup and data.strippedAddOnName or data.addOnName)
        local author = stripColorMarkup and data.strippedAddOnAuthor or data.addOnAuthor
        if author ~= "" then
            authorControl:SetText(zo_strformat(SI_ADD_ON_AUTHOR_LINE, author))
        else
            authorControl:SetText("")
        end
    end

    return function(control, data)
        control.owner = self
        control.data = data
        local name = control:GetNamedChild("Name")
        local author = control:GetNamedChild("Author")
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

        local showDependencies = data.expanded and data.addonDependencyText ~= ""
        dependencies:SetHidden(not showDependencies)
        if showDependencies then
            dependencies:SetText(zo_strformat(SI_ADDON_MANAGER_DEPENDENCIES, data.addonDependencyText))
        else
            dependencies:SetText("")
        end

        local isEnabled = HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and (not data.isOutOfDate or AddOnManager:GetLoadOutOfDateAddOns())

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

        ZO_TriStateCheckButton_SetStateChangeFunction(enabledControl, function(control, checkState) self:OnEnabledButtonClicked(control, checkState) end)

        SetupNotes(state, data)
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

do
    local ENTRY_SORT_KEYS =
    {
        addOnFileName = { },
        strippedAddOnName = { tiebreaker = "addOnFileName" },
    }

    function ZO_AddOnManager:SortScrollList()
        local scrollData = ZO_ScrollList_GetDataList(self.list)

        local function SortEntries(entry1, entry2)
            return ZO_TableOrderingFunction(entry1.data, entry2.data, "strippedAddOnName", ENTRY_SORT_KEYS, ZO_SORT_ORDER_UP)
        end
        table.sort(scrollData, SortEntries)
    end
end

function ZO_AddOnManager:OnCharacterChanged(name)
    self.selectedCharacter = name
    self:RefreshData()
end

function ZO_AddOnManager:BuildCharacterDropdown()
    self.characterDropdown:ClearItems()

    local function OnCharacterChanged(comboBox, name, entry)
        self:OnCharacterChanged(name)
    end

    if self.characterData then
        self.characterDropdown:GetContainer():SetHidden(false)

        local all = GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL)
        local entry = self.characterDropdown:CreateItemEntry(all, OnCharacterChanged)
        self.characterDropdown:AddItem(entry)
        self.characterDropdown:SetSelectedItemText(all)

        self.selectedCharacter = nil
        self.isAllFilterSelected = true

        for i=1, self:GetNumCharacters() do
            local entry = self.characterDropdown:CreateItemEntry(self:GetCharacterInfo(i), OnCharacterChanged)
            self.characterDropdown:AddItem(entry)
        end
    else
        self.characterDropdown:GetContainer():SetHidden(true)

        local playerName = GetUnitName("player")
        self.selectedCharacter = playerName ~= "" and playerName or nil
        self.isAllFilterSelected = false
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

    local useHeight = zo_ceil(ROW_HEIGHT + descriptionHeight + dependencyHeight + 31)
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
    g_currentTypeId = 2
    heightIds = {}
end

local function StripText(text)
    return text:gsub("|c%x%x%x%x%x%x", "")
end

function ZO_AddOnManager:BuildMasterList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    self:ResetDataTypes()

    if not self.selectedCharacter or self.selectedCharacter == GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL) then
        self.isAllFilterSelected = true
        AddOnManager:RemoveAddOnFilter()
    else
        AddOnManager:SetAddOnFilter(CreateAddOnFilter(self.selectedCharacter))
        self.isAllFilterSelected = false
    end

    for i = 1, AddOnManager:GetNumAddOns() do
        local name, title, author, description, enabled, state, isOutOfDate = AddOnManager:GetAddOnInfo(i)
        local entryData = {
            index = i,
            addOnFileName = name,
            addOnName = title,
            strippedAddOnName = StripText(title),
            addOnAuthor = author,
            strippedAddOnAuthor = StripText(author),
            addOnDescription = description,
            addOnEnabled = enabled,
            addOnState = state,
            addOnSortName = addOnSortName,
            isOutOfDate = isOutOfDate
        }

        local dependencyText = ""
        for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
            local dependencyName, dependencyActive = AddOnManager:GetAddOnDependencyInfo(i, j)
            if not self.isAllFilterSelected and not dependencyActive then
                entryData.hasDependencyError = true
                dependencyName = ZO_ERROR_COLOR:Colorize(dependencyName)
            end
            dependencyText = dependencyText.."\n"..dependencyName
        end
        entryData.addonDependencyText = dependencyText

        entryData.expandable = (description ~= "") or (dependencyText ~= "")

        if entryData.expandable and expandedAddons[i] then
            entryData.expanded = true

            local useHeight, typeId = self:SetupTypeId(description, dependencyText)

            entryData.height = useHeight
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(typeId, entryData)
        else
            entryData.height = ROW_HEIGHT
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ADDON_DATA, entryData)
        end
    end
end

function ZO_AddOnManager:OnShow()
    self:BuildCharacterDropdown()
    self:RefreshData()
    self:RefreshMultiButton()
    CALLBACK_MANAGER:FireCallbacks("ShowAddOnEULAIfNecessary")
end

function ZO_AddOnManager:RefreshMultiButton()
    local multiButton = self.control:GetNamedChild("MultiButton")

    if(HasAgreedToEULA(EULA_TYPE_ADDON_EULA)) then
        local isShown = self:AllowReload()
        multiButton:SetHidden(not isShown)
        multiButton:SetText(GetString(SI_ADDON_MANAGER_RELOAD))
    else
        multiButton:SetHidden(false)
        multiButton:SetText(GetString(SI_ADDON_MANAGER_VIEW_EULA))
    end
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
    self:RefreshMultiButton()
end

function ZO_AddOnManager:OnExpandButtonClicked(row)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    local data = ZO_ScrollList_GetData(row)

    if expandedAddons[data.index] then
        expandedAddons[data.index] = false

        data.expanded = false
        data.height = ROW_HEIGHT
        scrollData[data.sortIndex] = ZO_ScrollList_CreateDataEntry(ADDON_DATA, data)
    else
        expandedAddons[data.index] = true

        local useHeight, typeId = self:SetupTypeId(data.addOnDescription, data.addonDependencyText)

        data.expanded = true
        data.height = useHeight
        scrollData[data.sortIndex] = ZO_ScrollList_CreateDataEntry(typeId, data)
    end

    self:CommitScrollList()
end

function ZO_AddOnManager:AllowReload()
    return (self.allowReload and self.isDirty)
end

function ZO_AddOnManager_OnExpandButtonClicked(control)
    local row = control:GetParent()
    row.owner:OnExpandButtonClicked(row)
end

function ZO_AddOnManager_OnEnabledButtonMouseEnter(control)
    local row = control:GetParent()
    row.owner:OnMouseEnter(control)
end

function ZO_AddOnManagerMultiButton_Callback()
    if(HasAgreedToEULA(EULA_TYPE_ADDON_EULA)) then
        if ADD_ON_MANAGER:AllowReload() then
            ReloadUI("ingame")
        end
    else
        CALLBACK_MANAGER:FireCallbacks("ShowAddOnEULAIfNecessary")
    end
end