local TICKET_CATEGORIES = 
{
    {
        id = TICKET_CATEGORY_CHARACTER_ISSUE,
        name = GetString(SI_GAMEPAD_HELP_CATEGORY_CHARACTER),
    },
    {
        id = TICKET_CATEGORY_REPORT_DEFAULT,
        name = GetString(SI_GAMEPAD_HELP_CATEGORY_REPORT),
    },
    {
        id = TICKET_CATEGORY_OTHER,
        name = GetString(SI_GAMEPAD_HELP_CATEGORY_OTHER),
    },
}

local TICKET_SUBCATEGORIES = 
{
    [TICKET_CATEGORY_REPORT_DEFAULT] = 
    {
        {
            id = TICKET_CATEGORY_REPORT_BAD_NAME,
            name = GetString(SI_GAMEPAD_HELP_SUBCATEGORY_REPORT_BAD_NAME),
        },
        {
            id = TICKET_CATEGORY_REPORT_HARASSMENT,
            name = GetString(SI_GAMEPAD_HELP_SUBCATEGORY_REPORT_HARASSMENT),
        },
        {
            id = TICKET_CATEGORY_REPORT_CHEATING,
            name = GetString(SI_GAMEPAD_HELP_SUBCATEGORY_REPORT_CHEATING),
        },
        {
            id = TICKET_CATEGORY_REPORT_OTHER,
            name = GetString(SI_GAMEPAD_HELP_CATEGORY_OTHER),
        },
    },
}

local REQUIRED_FIELD_DEFAULT_TEXTS = 
{
    [TICKET_CATEGORY_REPORT_DEFAULT] = zo_strformat(SI_GAMEPAD_HELP_TICKET_EDIT_REQUIRED_NAME_DISPLAY, ZO_GetPlatformAccountLabel()),
}

local ZO_Help_Customer_Service_Gamepad = ZO_Help_GenericTicketSubmission_Gamepad:Subclass()

function ZO_Help_Customer_Service_Gamepad:New(...)
    return ZO_Help_GenericTicketSubmission_Gamepad.New(self, ...)
end

function ZO_Help_Customer_Service_Gamepad:Initialize(control)
    ZO_Help_GenericTicketSubmission_Gamepad.Initialize(self, control)
    HELP_CUSTOMER_SERVICE_GAMEPAD_SCENE = self:GetScene()
    self.itemList = self:GetMainList()

    local headerMessageControl = self.control:GetNamedChild("MaskContainerHeaderContainerHeaderMessage")
    headerMessageControl:SetFont("ZoFontGamepadCondensed42")
end

function ZO_Help_Customer_Service_Gamepad:GenerateSelectKeybindStripDescriptor()
    local keybindDescriptor =
    {
        name = GetString(SI_GAMEPAD_SELECT_OPTION),
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function()
            local targetData = self.itemList:GetTargetData()
            if targetData.isTextField then
                local editBox = self.itemList:GetTargetControl().editBox
                if editBox:HasFocus() then
                    editBox:LoseFocus()
                else
                    editBox:TakeFocus()
                end
            elseif targetData.isDropdown then
                self:ActivateCurrentDropdown(targetData.fieldType)
            elseif targetData.isSubmit then
                self:TrySubmitTicket()
                PlaySound(SOUNDS.DIALOG_ACCEPT)
            end
        end,

        enabled = function()
            if self.itemList then
                local selectedData = self.itemList:GetTargetData()
                if selectedData then
                    return not selectedData.isLocked
                end
            end
            return false
        end
    }
    return keybindDescriptor
end

function ZO_Help_Customer_Service_Gamepad:GetSceneName()
    return "helpCustomerServiceGamepad"
end

function ZO_Help_Customer_Service_Gamepad:GetFieldEntryTitle()
    return GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE)
end

function ZO_Help_Customer_Service_Gamepad:GetFieldEntryMessage()
    return GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FIELD_ENTRY_MESSAGE)
end

function ZO_Help_Customer_Service_Gamepad:GetTicketCategoryForSubmission()
    local categoryTicketId = self:GetCurrentCategory()
    local subcategoryIndex = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY)
    if subcategoryIndex then
        local subcategoryInfo = TICKET_SUBCATEGORIES[categoryTicketId]
        if subcategoryInfo then
            categoryTicketId = subcategoryInfo[subcategoryIndex].id
        end
    end

    return categoryTicketId
end

function ZO_Help_Customer_Service_Gamepad:GetCurrentCategory()
    local categoryIndex = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)
    if categoryIndex then
        return self:GetCategoryIdFromIndex(categoryIndex)
    end
end

function ZO_Help_Customer_Service_Gamepad:GetCategoryIdFromIndex(categoryIndex)
    local categoryInfo = TICKET_CATEGORIES[categoryIndex]
    if categoryInfo then
        return categoryInfo.id
    end
end

function ZO_Help_Customer_Service_Gamepad:ValidateTicketFields()
    local result = ZO_HELP_TICKET_VALIDATION_STATUS.SUCCESS
    local details = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    if details == nil or details == "" then
        local categoryId = self:GetCurrentCategory()
        --"Character" required information is inferred, so nothing is required
        if categoryId ~= TICKET_CATEGORY_CHARACTER_ISSUE and categoryId ~= TICKET_CATEGORY_OTHER then
            result = ZO_HELP_TICKET_VALIDATION_STATUS.FAILED_NO_DISPLAY_NAME
        end
    end
    return result
end

function ZO_Help_Customer_Service_Gamepad:SubmitTicket()
    ResetCustomerServiceTicket()
    SetCustomerServiceTicketContactEmail(GetActiveUserEmailAddress())
    SetCustomerServiceTicketCategory(self:GetTicketCategoryForSubmission())
    SetCustomerServiceTicketBody(self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION))
    local categoryId = self:GetCurrentCategory()
    if categoryId == TICKET_CATEGORY_REPORT_DEFAULT then
        SetCustomerServiceTicketPlayerTarget(self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS))
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:MarkAttemptingToSubmitReportPlayerTicket()
    end
    SubmitCustomerServiceTicket()
end

function ZO_Help_Customer_Service_Gamepad:SetReportPlayerTargetByDisplayName(displayName)
    self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS, ZO_FormatUserFacingDisplayName(displayName))
end

function ZO_Help_Customer_Service_Gamepad:SetCategory(categoryId)
    for categoryIndex, categoryInfo in ipairs(TICKET_CATEGORIES) do
        if (categoryInfo.id == categoryId) then
            self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY, categoryIndex)
            break
        end
    end
end

function ZO_Help_Customer_Service_Gamepad:SetSubcategory(subcategoryId)
    for categoryIndex, categoryInfo in ipairs(TICKET_CATEGORIES) do
        local subcategories = TICKET_SUBCATEGORIES[categoryInfo.id]
        if (subcategories) then
            for subcategoryIndex, subcategoryInfo in ipairs(subcategories) do
                if (subcategoryInfo.id == subcategoryId) then
                    self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY, categoryIndex)
                    self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY, subcategoryIndex)
                    break
                end
            end
        end
    end
end

function ZO_Help_Customer_Service_Gamepad:SetRequiredInfoProvidedInternally(isProvidedInternally)
    self.requiredInfoProvidedInternally = isProvidedInternally
end

function ZO_Help_Customer_Service_Gamepad:OnTextFieldFocusLost(control, fieldType)
    if control then
        ZO_EditDefaultText_OnTextChanged(control)
        self:SetSavedField(fieldType, control:GetText())
    end
end

function ZO_Help_Customer_Service_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)

    local function SetupTextFieldListEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local editContainer = control:GetNamedChild("TextField")
        control.editBox = editContainer:GetNamedChild("Edit")
        control.editBox:SetHandler("OnFocusGained", function(editControl)
                                                        editControl:SetVirtualKeyboardType(VIRTUAL_KEYBOARD_TYPE_EMAIL)
                                                        self.activeEditBox = editControl
                                                    end)
        
        control.editBox:SetHandler("OnFocusLost", function(editControl)
                                                        self:OnTextFieldFocusLost(editControl, data.fieldType)
                                                        self.activeEditBox = nil
                                                        list:RefreshVisible()
                                                    end)
        control.editBox:SetHandler("OnTextChanged", ZO_EditDefaultText_OnTextChanged)

        local savedText = self:GetSavedField(data.fieldType)
        if savedText then
            control.editBox:SetText(savedText)
        else
            control.editBox:SetText("")
        end

        if data.isRequired and not self.requiredInfoProvidedInternally then
            local defaultText = REQUIRED_FIELD_DEFAULT_TEXTS[self:GetCurrentCategory()]
            ZO_EditDefaultText_Initialize(control.editBox, defaultText)
        else
            ZO_EditDefaultText_Disable(control.editBox)
        end

        control.highlight:SetHidden(not selected)
    end

    local function SetupLockedTextFieldListEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local labelContainer = control:GetNamedChild("TextField")
        control.lockedLabel = labelContainer:GetNamedChild("Label")

        local savedText = self:GetSavedField(data.fieldType)
        if savedText then
            control.lockedLabel:SetText(savedText)
        else
            control.lockedLabel:SetText("")
        end

        control.highlight:SetHidden(not selected)
    end

    local function SetupDropdownListEntry(control, data, selected, selectedDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)
        control.dropdown:SetSortsItems(false)

        self:BuildDropdownList(control.dropdown, data)
        if selected then
            self:SetCurrentDropdown(control.dropdown)
        end
    end

    list:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem_Multiline", SetupTextFieldListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate")
    list:AddDataTemplateWithHeader("ZO_Gamepad_Help_EditLockedEntry_MultiLine", SetupLockedTextFieldListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderWithLockTemplate")
    list:AddDataTemplateWithHeader("ZO_Gamepad_Help_Dropdown_Item", SetupDropdownListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate")
    list:AddDataTemplate("ZO_GamepadTextFieldSubmitItem", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_Help_Customer_Service_Gamepad:DropdownItemCallback(selectionIndex, fieldType, ticketCategoryId)
    if self:GetSavedField(fieldType) ~= selectionIndex then
        self:SetSavedField(fieldType, selectionIndex)
        if fieldType == ZO_HELP_TICKET_FIELD_TYPE.CATEGORY then
            if self.requiredInfoProvidedInternally then
                self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS, nil)
            end
            self.requiredInfoProvidedInternally = false
            ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:SetReportPlayerTicketSubmittedCallback(nil)
        end
        self:BuildList()
    end
end

function ZO_Help_Customer_Service_Gamepad:BuildDropdownList(dropdown, data)
    dropdown:ClearItems()

    for index, item in ipairs(data.list) do
        dropdown:AddItem(ZO_ComboBox:CreateItemEntry(item.name, function() self:DropdownItemCallback(index, data.fieldType, item.id) end), ZO_COMBOBOX_SUPRESS_UPDATE)
    end

    dropdown:UpdateItems()
    self:UpdateDropdownSelection(dropdown, data.fieldType)
end

function ZO_Help_Customer_Service_Gamepad:UpdateDropdownSelection(dropdown, fieldType)
    local savedField = self:GetSavedField(fieldType)
    if savedField then
        dropdown:SelectItemByIndex(savedField)
    else
        dropdown:SelectFirstItem()
    end
end

function ZO_Help_Customer_Service_Gamepad:SetCurrentDropdown(dropdown)
    self.currentDropdown = dropdown
end

function ZO_Help_Customer_Service_Gamepad:ActivateCurrentDropdown(fieldType)
    if(self.currentDropdown ~= nil) then
        self.currentDropdown:Activate()
        local savedField = self:GetSavedField(fieldType)
        if savedField then
            self.currentDropdown:SetHighlightedItem(savedField)
        else
            self.currentDropdown:SetHighlightedItem(1)
        end
    end
end

function ZO_Help_Customer_Service_Gamepad:AddTextFieldEntry(fieldType, header, required, locked)
    local entryData = ZO_GamepadEntryData:New(header)
    entryData.fieldType = fieldType
    entryData.header = header
    entryData.isTextField = true
    entryData.isRequired = required
    entryData.isLocked = locked

    if locked then
        self.itemList:AddEntryWithHeader("ZO_Gamepad_Help_EditLockedEntry_MultiLine", entryData)
    else
        self.itemList:AddEntryWithHeader("ZO_GamepadTextFieldItem_Multiline", entryData)
    end
end

function ZO_Help_Customer_Service_Gamepad:AddDropdownEntry(fieldType, header, list)
    local entryData = ZO_GamepadEntryData:New("Dropdown")
    entryData.list = list
    entryData.fieldType = fieldType
    entryData.header = header
    entryData.isDropdown = true

    self.itemList:AddEntryWithHeader("ZO_Gamepad_Help_Dropdown_Item", entryData)
end

function ZO_Help_Customer_Service_Gamepad:AddSubmitEntry()
    local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_HELP_SUBMIT_TICKET), ZO_GAMEPAD_SUBMIT_ENTRY_ICON)
    entryData.isSubmit = true

    self.itemList:AddEntry("ZO_GamepadTextFieldSubmitItem", entryData)
end

function ZO_Help_Customer_Service_Gamepad:BuildList()
    self.itemList:Clear()

    local FIELD_IS_REQUIRED = true

    -- categories
    self:AddDropdownEntry(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_CATEGORY), TICKET_CATEGORIES)
        
    local categoryId = self:GetCurrentCategory()
    if (categoryId) then
        -- contextual subcategories
        local subcategories = TICKET_SUBCATEGORIES[categoryId]
        if (subcategories) then
            self:AddDropdownEntry(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_SUBCATEGORY), subcategories)
        end

        -- required fields
        if categoryId ~= TICKET_CATEGORY_CHARACTER_ISSUE and categoryId ~= TICKET_CATEGORY_OTHER then
            self:AddTextFieldEntry(ZO_HELP_TICKET_FIELD_TYPE.DETAILS, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_REQUIRED_DETAILS), FIELD_IS_REQUIRED, self.requiredInfoProvidedInternally)
        end
    end

    -- additional details
    self:AddTextFieldEntry(ZO_HELP_TICKET_FIELD_TYPE.DESCRIPTION, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_ADDITIONAL_DETAILS))
    
    self:AddSubmitEntry()

    self.itemList:Commit()
    self.dirty = false
end

-- Customer Service has dynamic categories, which means it's not always enough to just refresh what's visible.
-- We need to rebuild the list when we reset in case the controls have changed.
function ZO_Help_Customer_Service_Gamepad:ResetTicket()
    ZO_ClearTable(self.savedFields)
    self:BuildList()
    self.requiredInfoProvidedInternally = false
    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:SetReportPlayerTicketSubmittedCallback(nil)
end

function ZO_Help_Customer_Service_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if self.activeEditBox then
        self.activeEditBox:LoseFocus()
    end
end

function ZO_Help_Customer_Service_Gamepad_OnInitialize(control)
    HELP_CUSTOMER_SERVICE_GAMEPAD = ZO_Help_Customer_Service_Gamepad:New(control)
end

function ZO_Help_Customer_Service_Gamepad_SetupReportPlayerTicket(displayName)
    HELP_CUSTOMER_SERVICE_GAMEPAD:ResetTicket()
    HELP_CUSTOMER_SERVICE_GAMEPAD:SetCategory(TICKET_CATEGORY_REPORT_DEFAULT)
    HELP_CUSTOMER_SERVICE_GAMEPAD:SetReportPlayerTargetByDisplayName(displayName)
    HELP_CUSTOMER_SERVICE_GAMEPAD:SetRequiredInfoProvidedInternally(true)
    HELP_CUSTOMER_SERVICE_GAMEPAD:ChangeTicketState(ZO_HELP_TICKET_STATE.FIELD_ENTRY)
    HELP_CUSTOMER_SERVICE_GAMEPAD:BuildList()
end