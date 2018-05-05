local LIST_REFRESH_VISIBLE = true

ZO_Help_MechanicAssistance_Gamepad = ZO_Help_GenericTicketSubmission_Gamepad:Subclass()

function ZO_Help_MechanicAssistance_Gamepad:New(...)
    return ZO_Help_GenericTicketSubmission_Gamepad.New(self, ...)
end

function ZO_Help_MechanicAssistance_Gamepad:Initialize(control, mechanicCategoriesData)
    ZO_Help_GenericTicketSubmission_Gamepad.Initialize(self, control)
    
    self.itemList = self:GetMainList()
    self.mechanicCategoriesData = mechanicCategoriesData
end

function ZO_Help_MechanicAssistance_Gamepad:GetFieldEntryMessage()
    return GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FIELD_ENTRY_MESSAGE)
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
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.CATEGORY

    self.itemList:AddEntryWithHeader("ZO_Gamepad_Help_Dropdown_Item", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:AddDetailsEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = self.detailsHeader
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.DETAILS

    self.itemList:AddEntryWithHeader("ZO_Help_MechanicAssistance_Gamepad_DetailsItem", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:AddDescriptionEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = GetString(SI_CUSTOMER_SERVICE_DESCRIPTION)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION

    self.itemList:AddEntryWithHeader("ZO_GamepadTextFieldItem_Multiline", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:AddSubmitEntry()
    local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_HELP_SUBMIT_TICKET), ZO_GAMEPAD_SUBMIT_ENTRY_ICON)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.SUBMIT

    self.itemList:AddEntry("ZO_GamepadTextFieldSubmitItem", entryData)
end

function ZO_Help_MechanicAssistance_Gamepad:GenerateSelectKeybindStripDescriptor()
    local keybindDescriptor =
    {
        name = function()
            local targetData = self.itemList:GetTargetData()
            local fieldType = targetData.fieldType
            if fieldType == ZO_HELP_TICKET_FIELD_TYPE.DETAILS then
                return self.goToDetailsSourceKeybindText
            elseif fieldType == ZO_HELP_TICKET_FIELD_TYPE.SUBMIT then
                return GetString(SI_GAMEPAD_HELP_SUBMIT_TICKET)
            else
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end
        end,
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function()
            local targetData = self.itemList:GetTargetData()
            local fieldType = targetData.fieldType
            if fieldType == ZO_HELP_TICKET_FIELD_TYPE.CATEGORY then
                self.categoryDropdown:Activate()
            elseif fieldType == ZO_HELP_TICKET_FIELD_TYPE.DETAILS then
                self:GoToDetailsSourceScene()
            elseif fieldType == ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION then
                local editBox = self.descriptionEditBox
                if editBox:HasFocus() then
                    editBox:LoseFocus()
                else
                    editBox:TakeFocus()
                end
            elseif fieldType == ZO_HELP_TICKET_FIELD_TYPE.SUBMIT then
                self:TrySubmitTicket()
                PlaySound(SOUNDS.DIALOG_ACCEPT)
            end
        end,
    }

    return keybindDescriptor
end

function ZO_Help_MechanicAssistance_Gamepad:DetailsRequired()
    return false
end

function ZO_Help_MechanicAssistance_Gamepad:ValidateTicketFields()
    local selectedCategoryData = self.categoryDropdown:GetSelectedItemData()
    local savedDetails = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    local savedCategoryValue = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)
    local savedDescription = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION)
    if savedCategoryValue == self.mechanicCategoriesData.invalidCategory then
        return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_CATEGORY
    elseif self:DetailsRequired() and (not savedDetails or savedDetails == "") then
        return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_DETAILS
    elseif self.descriptionEditBox and (not savedDescription or savedDescription == "") then
        return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_DESCRIPTION
    end
    return ZO_HELP_TICKET_VALIDATION_STATUS.SUCCESS
end

function ZO_Help_MechanicAssistance_Gamepad:SubmitTicket()
    ResetCustomerServiceTicket()
    SetCustomerServiceTicketContactEmail(GetActiveUserEmailAddress())
    SetCustomerServiceTicketCategory(self:GetCurrentTicketCategory())
    self:RegisterDetails()
    local savedDescription = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION)
    if savedDescription then
        SetCustomerServiceTicketBody(savedDescription)
    end
    SubmitCustomerServiceTicket()
end

function ZO_Help_MechanicAssistance_Gamepad:GetCurrentTicketCategory()
    local categoryIndex = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)
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
        self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY, entry.categoryEnumValue)
    end

    local function SetupCategoryListEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

        local dropdown = control.dropdown
        dropdown:SetSortsItems(false)
        dropdown:ClearItems()
        local savedCategoryValue = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)
        local savedDropdownIndex = 1
        local currentDropdownIndex = 1
        local mechanicCategoriesData = self.mechanicCategoriesData
        for _, enumValue in ipairs(mechanicCategoriesData.categoryEnumOrderedValues) do
            local name = GetString(mechanicCategoriesData.categoryEnumStringPrefix, enumValue)
            if name ~= nil then
                local entry = ZO_ComboBox:CreateItemEntry(name, OnCategorySelectionChanged)
                entry.categoryEnumValue = enumValue
                dropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
                if savedCategoryValue == enumValue then
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

        self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION, control:GetText())
    end

    local function SetupDescriptionFieldListEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local editContainer = control:GetNamedChild("TextField")
        local editBox = editContainer:GetNamedChild("Edit")

        editBox:SetHandler("OnTextChanged", OnDescriptionTextChanged)

        local savedText = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION)
        editBox:SetText(savedText or "")

        ZO_EditDefaultText_Initialize(editBox, GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_GENERIC))
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
    local savedDetails = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    return savedDetails or self.detailsInstructions
end

function ZO_Help_MechanicAssistance_Gamepad:InitWithDetails(detailsData)
    self:ResetTicket()
    self:SetDetailsData(detailsData)
    self:ChangeTicketState(ZO_HELP_TICKET_STATE.FIELD_ENTRY)
end

function ZO_Help_MechanicAssistance_Gamepad:SetDetailsData(detailsData)
    self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS, detailsData, LIST_REFRESH_VISIBLE)
end