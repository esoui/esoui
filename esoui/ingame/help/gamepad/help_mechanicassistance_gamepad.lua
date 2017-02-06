local TICKET_STATE =
{
    FIELD_ENTRY = 1,
    START_SUBMISSION = 2,
}

local TICKET_VALIDATION_STATUS = 
{
    SUCCESS = true,
    FAILED_NO_DETAILS = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_DETAILS),
    FAILED_NO_CATEGORY = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_CATEGORY),
    FAILED_NO_DESCRIPTION = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_DESCRIPTION),
}

ZO_MECHANIC_ASSISTANCE_TICKET_FIELD =
{
    CATEGORY = 1,
    DETAILS = 2,
    DESCRIPTION = 3,
    SUBMIT = 4,
}

local REFRESH_KEYBIND_STRIP = true

ZO_Help_MechanicAssistance_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Help_MechanicAssistance_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_Help_MechanicAssistance_Gamepad:Initialize(control, mechanicCategoriesData)
    local scene = ZO_Scene:New(self:GetSceneName(), SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, scene)

    local fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(fragment)
    
    self.itemList = ZO_Gamepad_ParametricList_Screen.GetMainList(self)
    self.savedFields = {}
    self.mechanicCategoriesData = mechanicCategoriesData
    self.headerDataFieldEntry = 
    {
        titleText = self:GetTitle(),
        messageText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FIELD_ENTRY_MESSAGE),
    }

    self.headerDataStartSubmission =
    {
        titleText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_SUBMISSION_IN_PROGRESS_TITLE),
        messageText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_SUBMISSION_IN_PROGRESS_MESSAGE),
    }

    local function OnCustomerServiceTicketSubmitted()
        self:ResetTicket()
        self:ChangeTicketState(TICKET_STATE.FIELD_ENTRY)
    end

    control:RegisterForEvent(EVENT_CUSTOMER_SERVICE_TICKET_SUBMITTED, OnCustomerServiceTicketSubmitted)
end

function ZO_Help_MechanicAssistance_Gamepad:BuildList()
    self:AddCategoriesEntry()
    self:AddDetailsEntry()
    self:AddDescriptionEntry()
    self:AddSubmitEntry()

    self.itemList:Commit()
end

function ZO_Help_MechanicAssistance_Gamepad:AddCategoriesEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = GetString(SI_GAMEPAD_HELP_FIELD_TITLE_CATEGORY)
    entryData.fieldType = ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.CATEGORY

    self.itemList:AddEntryWithHeader("ZO_Gamepad_Help_Dropdown_Item", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:AddDetailsEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = self.detailsHeader
    entryData.fieldType = ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DETAILS

    self.itemList:AddEntryWithHeader("ZO_Help_MechanicAssistance_Gamepad_DetailsItem", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:AddDescriptionEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = GetString(SI_CUSTOMER_SERVICE_DESCRIPTION)
    entryData.fieldType = ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DESCRIPTION

    self.itemList:AddEntryWithHeader("ZO_GamepadTextFieldItem_Multiline", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:AddSubmitEntry()
    local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_HELP_SUBMIT_TICKET), ZO_GAMEPAD_SUBMIT_ENTRY_ICON)
    entryData.fieldType = ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.SUBMIT

    self.itemList:AddEntry("ZO_GamepadTextFieldSubmitItem", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:OnShowing()
    self:ChangeTicketState(TICKET_STATE.FIELD_ENTRY)
end

function ZO_Help_MechanicAssistance_Gamepad:OnShow()
    self:AddKeybindsBasedOnState()
end

function ZO_Help_MechanicAssistance_Gamepad:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Help_MechanicAssistance_Gamepad:OnHide()
    if self.currentDropdown ~= nil then
        self.categoryDropdown:Deactivate(true)
    end
    self:ResetTicket()
end

function ZO_Help_MechanicAssistance_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptorsByState = 
    {
        [TICKET_STATE.FIELD_ENTRY] = 
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            -- Back
            KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() SCENE_MANAGER:HideCurrentScene() end, nil, SOUNDS.DIALOG_DECLINE),
            -- Select
            {
                name = function()
                    local targetData = self.itemList:GetTargetData()
                    local fieldType = targetData.fieldType
                    if fieldType == ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DETAILS then
                        return self.goToDetailsSourceKeybindText
                    elseif fieldType == ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.SUBMIT then
                        return GetString(SI_GAMEPAD_HELP_SUBMIT_TICKET)
                    else
                        return GetString(SI_GAMEPAD_SELECT_OPTION)
                    end
                end,
                keybind = "UI_SHORTCUT_PRIMARY",
                callback = function()
                    local targetData = self.itemList:GetTargetData()
                    local fieldType = targetData.fieldType
                    if fieldType == ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.CATEGORY then
                        self.categoryDropdown:Activate()
                    elseif fieldType == ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DETAILS then
                        self:GoToDetailsSourceScene()
                    elseif fieldType == ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DESCRIPTION then
                        local editBox = self.descriptionEditBox
                        if editBox:HasFocus() then
                            editBox:LoseFocus()
                        else
                            editBox:TakeFocus()
                        end
                    elseif fieldType == ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.SUBMIT then
                        self:TrySubmitTicket()
                        PlaySound(SOUNDS.DIALOG_ACCEPT)
                    end
                end,
            },
        },
        [TICKET_STATE.START_SUBMISSION] = 
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
        },
    }
end

function ZO_Help_MechanicAssistance_Gamepad:AddKeybindsBasedOnState()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    self.keybindStripDescriptor = self.keybindStripDescriptorsByState[self.ticketState]
    
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

-- refreshKeybindStrip should only be used for internal state changes
function ZO_Help_MechanicAssistance_Gamepad:ChangeTicketState(ticketState, refreshKeybindStrip)
    if self.ticketState ~= ticketState then
        self.ticketState = ticketState

        if refreshKeybindStrip then
            self:AddKeybindsBasedOnState()
        end

        -- field entry
        if self.ticketState == TICKET_STATE.FIELD_ENTRY then
            self.headerData = self.headerDataFieldEntry

            self:BuildList()

        -- start submission
        elseif self.ticketState == TICKET_STATE.START_SUBMISSION then
            self.headerData = self.headerDataStartSubmission

            self.itemList:Clear()
            self.itemList:Commit()

            self:SubmitTicket()
        end

        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end
end

function ZO_Help_MechanicAssistance_Gamepad:TrySubmitTicket()
    local result = self:ValidateTicketFields()
    if result == TICKET_VALIDATION_STATUS.SUCCESS then
        self:ChangeTicketState(TICKET_STATE.START_SUBMISSION, REFRESH_KEYBIND_STRIP)
    else
        ZO_Dialogs_ShowGamepadDialog("HELP_CUSTOMER_SERVICE_TICKET_FAILED_REASON", nil, {mainTextParams = { result }})
    end
end

function ZO_Help_MechanicAssistance_Gamepad:DetailsRequired()
    return false
end

function ZO_Help_MechanicAssistance_Gamepad:ValidateTicketFields()
    local selectedCategoryData = self.categoryDropdown:GetSelectedItemData()
    local savedDetails = self:GetSavedField(ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DETAILS)
    local savedCategoryIndex = self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.CATEGORY]
    local savedDescription = self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DESCRIPTION]
    if savedCategoryIndex == self.mechanicCategoriesData.invalidCategory then
        return TICKET_VALIDATION_STATUS.FAILED_NO_CATEGORY
    elseif self:DetailsRequired() and (not savedDetails or savedDetails == "") then
        return TICKET_VALIDATION_STATUS.FAILED_NO_DETAILS
    elseif self.descriptionEditBox and (not savedDescription or savedDescription == "") then
        return TICKET_VALIDATION_STATUS.FAILED_NO_DESCRIPTION
    end
    return TICKET_VALIDATION_STATUS.SUCCESS
end

function ZO_Help_MechanicAssistance_Gamepad:SubmitTicket()
    ResetCustomerServiceTicket()
    SetCustomerServiceTicketContactEmail(GetActiveUserEmailAddress())
    SetCustomerServiceTicketCategory(self:GetCurrentTicketCategory())
    self:RegisterDetails()
    local savedDescription = self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DESCRIPTION]
    if savedDescription then
        SetCustomerServiceTicketBody(savedDescription)
    end
    SubmitCustomerServiceTicket()
end

function ZO_Help_MechanicAssistance_Gamepad:ResetTicket()
    ZO_ClearTable(self.savedFields)
    self.itemList:RefreshVisible()
end

function ZO_Help_MechanicAssistance_Gamepad:GetCurrentTicketCategory()
    local categoryIndex = self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.CATEGORY]
    if categoryIndex then
        local categoryData = self.mechanicCategoriesData.ticketCategoryMap[categoryIndex]
        if categoryData then
            return categoryData.ticketCategory
        end
    end
end

function ZO_Help_MechanicAssistance_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)
    
    local function OnCategorySelectionChanged(control, name, entry, selectionChanged)
        self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.CATEGORY] = entry.index
    end

    local function SetupCategoryListEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

        local dropdown = control.dropdown
        dropdown:SetSortsItems(false)
        dropdown:ClearItems()
        local savedCategoryIndex = self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.CATEGORY]
        local savedDropdownIndex = 1
        local currentDropdownIndex = 1
        local mechanicCategoriesData = self.mechanicCategoriesData
        for i = mechanicCategoriesData.categoryEnumMin, mechanicCategoriesData.categoryEnumMax do
            local name = GetString(mechanicCategoriesData.categoryEnumStringPrefix, i)
            if name ~= nil then
                local entry = ZO_ComboBox:CreateItemEntry(name, OnCategorySelectionChanged)
                entry.index = i
                dropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
                if savedCategoryIndex == i then
                    savedDropdownIndex = currentDropdownIndex
                end
                currentDropdownIndex = currentDropdownIndex + 1
            end
        end

        dropdown:UpdateItems()
        dropdown:SelectItemByIndex(savedDropdownIndex)

        self.categoryDropdown = dropdown
    end

    local function SetupDetailsListEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        data.text = self:GetDisplayedDetails()
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    local function OnDescriptionTextChanged(control)
        ZO_EditDefaultText_OnTextChanged(control)

        self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DESCRIPTION] = control:GetText()
    end

    local function SetupDescriptionFieldListEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local editContainer = control:GetNamedChild("TextField")
        local editBox = editContainer:GetNamedChild("Edit")

        editBox:SetHandler("OnTextChanged", OnDescriptionTextChanged)

        local savedText = self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DESCRIPTION]
        editBox:SetText(savedText or "")

        ZO_EditDefaultText_Initialize(editBox, GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_ASK_FOR_HELP))
        control.highlight:SetHidden(not selected)

        self.descriptionEditBox = editBox
    end

    list:AddDataTemplateWithHeader("ZO_Gamepad_Help_Dropdown_Item", SetupCategoryListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, "Categories")
    list:AddDataTemplateWithHeader("ZO_Help_MechanicAssistance_Gamepad_DetailsItem", SetupDetailsListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, "Details")
    list:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem_Multiline", SetupDescriptionFieldListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, "Desc")
    list:AddDataTemplate("ZO_GamepadTextFieldSubmitItem", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_Help_MechanicAssistance_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if self.descriptionEditBox then
        self.descriptionEditBox:LoseFocus()
    end
end

function ZO_Help_MechanicAssistance_Gamepad:GetSceneName()
    assert(false) --Must be overriden
end

function ZO_Help_MechanicAssistance_Gamepad:GetTitle()
    assert(false) --Must be overriden
end

function ZO_Help_MechanicAssistance_Gamepad:SetGoToDetailsSourceKeybindText(keybindText)
    self.goToDetailsSourceKeybindText = keybindText
end

function ZO_Help_MechanicAssistance_Gamepad:SetDetailsHeader(detailsHeader)
    self.detailsHeader = detailsHeader
end

function ZO_Help_MechanicAssistance_Gamepad:GetDetailsInstructions()
    return self.detailsInstructions
end

function ZO_Help_MechanicAssistance_Gamepad:SetDetailsInstructions(detailsInstructions)
    self.detailsInstructions = detailsInstructions
end

function ZO_Help_MechanicAssistance_Gamepad:GoToDetailsSourceScene()
    assert(false) --Must be overriden
end

function ZO_Help_MechanicAssistance_Gamepad:RegisterDetails()
    assert(false) -- Must be overriden
end

function ZO_Help_MechanicAssistance_Gamepad:GetDisplayedDetails()
    local savedDetails = self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DETAILS]
    return savedDetails or self.detailsInstructions
end

function ZO_Help_MechanicAssistance_Gamepad:InitWithDetails(detailsData)
    self:ResetTicket()
    self:SetDetailsData(detailsData)
    self:ChangeTicketState(TICKET_STATE.FIELD_ENTRY)
end

function ZO_Help_MechanicAssistance_Gamepad:SetDetailsData(detailsData)
    self.savedFields[ZO_MECHANIC_ASSISTANCE_TICKET_FIELD.DETAILS] = detailsData
    self.itemList:RefreshVisible()
end

function ZO_Help_MechanicAssistance_Gamepad:GetSavedField(ticketField)
    return self.savedFields[ticketField]
end

function ZO_Help_MechanicAssistance_Gamepad:SetSavedField(ticketField, fieldData, refreshVisible)
    self.savedFields[ticketField] = fieldData
    if refreshVisible then
        self.itemList:RefreshVisible()
    end
end