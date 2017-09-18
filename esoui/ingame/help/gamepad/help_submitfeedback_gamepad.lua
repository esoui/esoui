
local ZO_Help_SubmitFeedback_Gamepad = ZO_Help_GenericTicketSubmission_Gamepad:Subclass()

function ZO_Help_SubmitFeedback_Gamepad:New(...)
    return ZO_Help_GenericTicketSubmission_Gamepad.New(self, ...)
end

function ZO_Help_SubmitFeedback_Gamepad:Initialize(control)
    ZO_Help_GenericTicketSubmission_Gamepad.Initialize(self, control)
    HELP_SUBMIT_FEEDBACK_GAMEPAD_SCENE = self:GetScene()
    self.itemList = self:GetMainList()
    self.dropdowns = {}
    self.editBoxes = {}
end

function ZO_Help_SubmitFeedback_Gamepad:GenerateSelectKeybindStripDescriptor()
    local keybindDescriptor =
    {
        name = function()
            local targetData = self.itemList:GetTargetData()
            local fieldType = targetData.fieldType
            if fieldType == ZO_HELP_TICKET_FIELD_TYPE.SUBMIT then
                return GetString(SI_GAMEPAD_HELP_SUBMIT_TICKET)
            else
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end
        end,
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function()
            local targetData = self.itemList:GetTargetData()
            local fieldType = targetData.fieldType
            if fieldType == ZO_HELP_TICKET_FIELD_TYPE.IMPACT or fieldType == ZO_HELP_TICKET_FIELD_TYPE.CATEGORY or fieldType == ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY then
                self.dropdowns[fieldType]:Activate()
            elseif fieldType == ZO_HELP_TICKET_FIELD_TYPE.DETAILS or fieldType == ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION then
                local editBox = self.editBoxes[fieldType]
                if editBox:HasFocus() then
                    editBox:LoseFocus()
                else
                    editBox:TakeFocus()
                end
            elseif fieldType == ZO_HELP_TICKET_FIELD_TYPE.ATTACH_SCREENSHOT then
                local targetControl = self.itemList:GetTargetControl()
                ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
            elseif fieldType == ZO_HELP_TICKET_FIELD_TYPE.SUBMIT then
                self:TrySubmitTicket()
                PlaySound(SOUNDS.DIALOG_ACCEPT)
            end
        end,
    }

    return keybindDescriptor
end

function ZO_Help_SubmitFeedback_Gamepad:GetSceneName()
    return "helpSubmitFeedbackGamepad"
end

function ZO_Help_SubmitFeedback_Gamepad:GetFieldEntryTitle()
    return GetString(SI_CUSTOMER_SERVICE_SUBMIT_FEEDBACK)
end

function ZO_Help_SubmitFeedback_Gamepad:GetFieldEntryMessage()
    return GetString(SI_GAMEPAD_HELP_SUBMIT_FEEDBACK_FIELD_ENTRY_MESSAGE)
end

function ZO_Help_SubmitFeedback_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)
    
    local function OnDropdownSelectionChanged(control, name, entry, selectionChanged)
        if self:GetSavedField(entry.fieldType) ~= entry.categoryEnumValue then
            self:SetSavedField(entry.fieldType, entry.categoryEnumValue)

            if entry.fieldType == ZO_HELP_TICKET_FIELD_TYPE.CATEGORY then
                self:BuildList()
            end
        end
    end

    local function SetupDropdownListEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

        local dropdown = control.dropdown
        local fieldType = data.fieldType
        dropdown:SetSortsItems(false)
        dropdown:ClearItems()
        local savedValue = self:GetSavedField(fieldType)
        local savedDropdownIndex = 1
        local currentDropdownIndex = 1
        local enumIterationBegin
        local enumIterationEnd
        local fieldData = ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[fieldType]
        if fieldData.categoryContextualData then
            local contextualData = fieldData.categoryContextualData[self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)]
            enumIterationBegin = contextualData.iterationBegin
            enumIterationEnd = contextualData.iterationEnd
        else
            enumIterationBegin = fieldData.iterationBegin
            enumIterationEnd = fieldData.iterationEnd
        end

        local function AddEntry(enumValue)
            local name = GetString(fieldData.enumStringPrefix, enumValue)
            if name ~= nil then
                local entry = ZO_ComboBox:CreateItemEntry(name, OnDropdownSelectionChanged)
                entry.categoryEnumValue = enumValue
                entry.fieldType = fieldType
                dropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
                if savedValue == enumValue then
                    savedDropdownIndex = currentDropdownIndex
                end
                currentDropdownIndex = currentDropdownIndex + 1
            end
        end

        if fieldData.universallyAddEnum then
            AddEntry(fieldData.universallyAddEnum)
        end

        for enumValue = enumIterationBegin, enumIterationEnd do
            AddEntry(enumValue)
        end

        dropdown:UpdateItems()
        dropdown:SelectItemByIndex(savedDropdownIndex)

        self.dropdowns[fieldType] = dropdown
    end

    local function OnTextChanged(control)
        ZO_EditDefaultText_OnTextChanged(control)

        self:SetSavedField(control.fieldType, control:GetText())
    end

    local function SetupTextBoxListEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        local fieldType = data.fieldType
        data.text = self:GetSavedField(fieldType) or ""
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local editContainer = control:GetNamedChild("TextField")
        local editBox = editContainer:GetNamedChild("Edit")
        editBox.fieldType = fieldType
        editBox:SetHandler("OnTextChanged", OnTextChanged)

        editBox:SetText(self:GetSavedField(fieldType) or "")

        ZO_EditDefaultText_Initialize(editBox, data.defaultText)
        control.highlight:SetHidden(not selected)

        self.editBoxes[fieldType] = editBox
    end

    local function OnCheckBoxToggled(control, checked)
        self:SetSavedField(control.fieldType, checked)
    end

    local function SetupCheckBoxEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        data.checked = self:GetSavedField(data.fieldType) == true
        data.setChecked = OnCheckBoxToggled
        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.checkBox.fieldType = data.fieldType
    end

    list:AddDataTemplateWithHeader("ZO_Gamepad_Help_Dropdown_Item", SetupDropdownListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, "Categories")
    list:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem", SetupTextBoxListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, "Details")
    list:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem_Multiline", SetupTextBoxListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, "Desc")
    list:AddDataTemplate("ZO_CheckBoxTemplate_WithoutIndent_Gamepad", SetupCheckBoxEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, "Attach")
    list:AddDataTemplate("ZO_GamepadTextFieldSubmitItem", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

-- Feedback has dynamic categories, which means it's not always enough to just refresh what's visible.
-- We need to rebuild the list when we reset in case the controls have changed.
function ZO_Help_SubmitFeedback_Gamepad:ResetTicket()
    ZO_ClearTable(self.savedFields)
    self:BuildList()
end

function ZO_Help_SubmitFeedback_Gamepad:ValidateTicketFields()
    local selectedImpact = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.IMPACT)
    local selectedCategory = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)
    local selectedSubcategory = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY)
    if selectedImpact == ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.IMPACT].invalidEntry then
        return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_IMPACT
    elseif selectedCategory == ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.CATEGORY].invalidEntry then
        return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_CATEGORY
    else
        local subcategoryData = ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY]
        if selectedSubcategory == subcategoryData.invalidEntry then
            return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_CATEGORY
        else
            if subcategoryData.categoryContextualData[selectedCategory].detailsTitle then
                local providedDetailsText = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
                if providedDetailsText ==  nil or providedDetailsText == "" then
                    return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_DETAILS
                end
            end

            local providedDescriptionText = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION)
            if providedDescriptionText ==  nil or providedDescriptionText == "" then
                return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_DESCRIPTION
            end

            if self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.ATTACH_SCREENSHOT) and not ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:CanSubmitFeedbackWithScreenshot() then
                return ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_ATTACHED_SCREENSHOT_RECENTLY
            end
        end
    end

    return ZO_HELP_TICKET_VALIDATION_STATUS.SUCCESS
end

function ZO_Help_SubmitFeedback_Gamepad:SubmitTicket()
    local impactId = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.IMPACT)
    local categoryId = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)
    local subcategoryId = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY)
    local detailsText = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    local descriptionText = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION)
    local attachScreenshot = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.ATTACH_SCREENSHOT)

    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:AttemptToSendFeedback(impactId, categoryId, subcategoryId, detailsText, descriptionText, attachScreenshot)
end

function ZO_Help_SubmitFeedback_Gamepad:BuildList()
    self.itemList:Clear()

    self:AddImpactEntry()
    self:AddCategoriesEntry()
    local subcategoriesData = ZO_HELP_SUBMIT_FEEDBACK_FIELD_DATA[ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY]
    local contextualSubcategoryData = subcategoriesData.categoryContextualData[self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)]
    if contextualSubcategoryData then
        self:AddSubcategoriesEntry()
        if contextualSubcategoryData.detailsTitle then
            self:AddDetailsEntry(contextualSubcategoryData.detailsTitle)
        end
    end
    self:AddDescriptionEntry()
    self:AddAttachScreenshotEntry()
    self:AddSubmitEntry()

    self.itemList:Commit()
end

function ZO_Help_SubmitFeedback_Gamepad:AddImpactEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = GetString(SI_CUSTOMER_SERVICE_FEEDBACK_IMPACT)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.IMPACT

    self.itemList:AddEntryWithHeader("ZO_Gamepad_Help_Dropdown_Item", entryData)
end

function ZO_Help_SubmitFeedback_Gamepad:AddCategoriesEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = GetString(SI_GAMEPAD_HELP_FIELD_TITLE_CATEGORY)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.CATEGORY

    self.itemList:AddEntryWithHeader("ZO_Gamepad_Help_Dropdown_Item", entryData)
end

function ZO_Help_SubmitFeedback_Gamepad:AddSubcategoriesEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = GetString(SI_GAMEPAD_HELP_FIELD_TITLE_SUBCATEGORY)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY

    self.itemList:AddEntryWithHeader("ZO_Gamepad_Help_Dropdown_Item", entryData)
end

function ZO_Help_SubmitFeedback_Gamepad:AddDetailsEntry(headerText)
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = headerText
    entryData.defaultText = GetString(SI_CUSTOMER_SERVICE_ENTER_NAME)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.DETAILS

    self.itemList:AddEntryWithHeader("ZO_GamepadTextFieldItem", entryData)
end

function ZO_Help_SubmitFeedback_Gamepad:AddDescriptionEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.header = GetString(SI_CUSTOMER_SERVICE_DESCRIPTION)
    entryData.defaultText = GetString(SI_CUSTOMER_SERVICE_DEFAULT_DESCRIPTION_TEXT_GENERIC)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION

    self.itemList:AddEntryWithHeader("ZO_GamepadTextFieldItem_Multiline", entryData)
end

function ZO_Help_SubmitFeedback_Gamepad:AddAttachScreenshotEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.text = GetString(SI_CUSTOMER_SERVICE_ATTACH_SCREENSHOT)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.ATTACH_SCREENSHOT

    self.itemList:AddEntry("ZO_CheckBoxTemplate_WithoutIndent_Gamepad", entryData)
end

function ZO_Help_SubmitFeedback_Gamepad:AddSubmitEntry()
    local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_HELP_SUBMIT_TICKET), ZO_GAMEPAD_SUBMIT_ENTRY_ICON)
    entryData.fieldType = ZO_HELP_TICKET_FIELD_TYPE.SUBMIT

    self.itemList:AddEntry("ZO_GamepadTextFieldSubmitItem", entryData)
end

function ZO_Help_SubmitFeedback_Gamepad_OnInitialize(control)
    HELP_SUBMIT_FEEDBACK_GAMEPAD = ZO_Help_SubmitFeedback_Gamepad:New(control)
end