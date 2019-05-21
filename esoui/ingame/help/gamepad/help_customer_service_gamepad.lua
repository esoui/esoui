local TICKET_CATEGORIES =
{
    {
        id = TICKET_CATEGORY_CHARACTER_ISSUE,
        value = CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_CHARACTER_ISSUE,
        name = GetString("SI_CUSTOMERSERVICEASKFORHELPCATEGORIES", CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_CHARACTER_ISSUE),
    },
    {
        id = TICKET_CATEGORY_REPORT_DEFAULT,
        value = CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER,
        name = GetString("SI_CUSTOMERSERVICEASKFORHELPCATEGORIES", CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER),
    },
    {
        id = TICKET_CATEGORY_REPORT_DEFAULT,
        value = CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_GUILD,
        name = GetString("SI_CUSTOMERSERVICEASKFORHELPCATEGORIES", CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_GUILD),
    },
    {
        id = TICKET_CATEGORY_OTHER,
        value = CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_SUBMIT_FEEDBACK,
        name = GetString("SI_CUSTOMERSERVICEASKFORHELPCATEGORIES", CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_SUBMIT_FEEDBACK),
    },
}

local TICKET_SUBCATEGORIES =
{
    [CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER] =
    {
        {
            id = TICKET_CATEGORY_REPORT_BAD_NAME,
            value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_INAPPROPRIATE_NAME,
            name = GetString("SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY", CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_INAPPROPRIATE_NAME),
        },
        {
            id = TICKET_CATEGORY_REPORT_HARASSMENT,
            value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HARASSMENT,
            name = GetString("SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY", CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_HARASSMENT),
        },
        {
            id = TICKET_CATEGORY_REPORT_CHEATING,
            value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_CHEATING,
            name = GetString("SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY", CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_CHEATING),
        },
        {
            id = TICKET_CATEGORY_REPORT_OTHER,
            value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_CHEATING,
            name = GetString("SI_CUSTOMERSERVICEASKFORHELPREPORTPLAYERSUBCATEGORY", CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_OTHER),
        },
    },
    [CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_GUILD] =
    {
        {
            id = TICKET_CATEGORY_REPORT_GUILD_NAME,
            value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_SUBCATEGORY_INAPPROPRIATE_NAME,
            name = GetString("SI_CUSTOMERSERVICEASKFORHELPREPORTGUILDSUBCATEGORY", CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_SUBCATEGORY_INAPPROPRIATE_NAME),
        },
        {
            id = TICKET_CATEGORY_REPORT_GUILD_LISTING,
            value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_SUBCATEGORY_INAPPROPRIATE_LISTING,
            name = GetString("SI_CUSTOMERSERVICEASKFORHELPREPORTGUILDSUBCATEGORY", CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_SUBCATEGORY_INAPPROPRIATE_LISTING),
        },
        {
            id = TICKET_CATEGORY_REPORT_GUILD_DECLINE_MESSAGE,
            value = CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_SUBCATEGORY_INAPPROPRIATE_DECLINE,
            name = GetString("SI_CUSTOMERSERVICEASKFORHELPREPORTGUILDSUBCATEGORY", CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_SUBCATEGORY_INAPPROPRIATE_DECLINE),
        },
    },
}

local REQUIRED_FIELD_DEFAULT_TEXTS =
{
    [CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER] = zo_strformat(SI_GAMEPAD_HELP_TICKET_EDIT_REQUIRED_NAME_DISPLAY, ZO_GetPlatformAccountLabel()),
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
    local categoryValue = self:GetCurrentCategoryValue()
    local categoryTicketId = self:GetTicketIdByValue(categoryValue)
    local subcategoryIndex = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY)
    if subcategoryIndex then
        local subcategoryInfo = TICKET_SUBCATEGORIES[categoryValue]
        if subcategoryInfo then
            categoryTicketId = subcategoryInfo[subcategoryIndex].id
        end
    end

    return categoryTicketId
end

function ZO_Help_Customer_Service_Gamepad:GetCurrentCategoryValue()
    local categoryIndex = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY)
    if categoryIndex then
        return self:GetCategoryValueFromIndex(categoryIndex)
    end
end

function ZO_Help_Customer_Service_Gamepad:GetCategoryValueFromIndex(categoryIndex)
    local categoryInfo = TICKET_CATEGORIES[categoryIndex]
    if categoryInfo then
        return categoryInfo.value
    end
end

function ZO_Help_Customer_Service_Gamepad:GetTicketIdByValue(value)
    for i, info in ipairs(TICKET_CATEGORIES) do
        if info.value == value then
            return info.id
        end
    end
end

function ZO_Help_Customer_Service_Gamepad:ValidateTicketFields()
    local result = ZO_HELP_TICKET_VALIDATION_STATUS.SUCCESS
    local details = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    if details == nil or details == "" then
        local categoryValue = self:GetCurrentCategoryValue()
        local ticketId = self:GetTicketIdByValue(categoryValue)
        --"Character" required information is inferred, so nothing is required
        if ticketId ~= TICKET_CATEGORY_CHARACTER_ISSUE and ticketId ~= TICKET_CATEGORY_OTHER then
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
    local categoryValue = self:GetCurrentCategoryValue()
    local ticketId = self:GetTicketIdByValue(categoryValue)
    if ticketId == TICKET_CATEGORY_REPORT_DEFAULT then
        SetCustomerServiceTicketPlayerTarget(self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS))
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:MarkAttemptingToSubmitReportPlayerTicket()
    end
    SubmitCustomerServiceTicket()
end

function ZO_Help_Customer_Service_Gamepad:SetReportPlayerTargetByDisplayName(displayName)
    self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS, ZO_FormatUserFacingDisplayName(displayName))
end

function ZO_Help_Customer_Service_Gamepad:SetReportGuildTargetByName(guildName)
    self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS, guildName)
end

function ZO_Help_Customer_Service_Gamepad:SetCategory(categoryValue)
    for categoryIndex, categoryInfo in ipairs(TICKET_CATEGORIES) do
        if categoryInfo.value == categoryValue then
            self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.CATEGORY, categoryIndex)
            break
        end
    end
end

function ZO_Help_Customer_Service_Gamepad:SetReportGuildSubcategory(subCategoryValue)
    for subCategoryIndex, subCategoryInfo in ipairs(TICKET_SUBCATEGORIES[CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_GUILD]) do
        if subCategoryInfo.value == subCategoryValue then
            self:SetSavedField(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY, subCategoryIndex)
            break
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
            local defaultText = REQUIRED_FIELD_DEFAULT_TEXTS[self:GetCurrentCategoryValue()]
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

    local categoryValue = self:GetCurrentCategoryValue()
    if categoryValue then
        -- contextual subcategories
        local subcategories = TICKET_SUBCATEGORIES[categoryValue]
        if subcategories then
            self:AddDropdownEntry(ZO_HELP_TICKET_FIELD_TYPE.SUBCATEGORY, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_SUBCATEGORY), subcategories)
        end

        -- required fields
        local ticketId = self:GetTicketIdByValue(categoryValue)
        if ticketId ~= TICKET_CATEGORY_CHARACTER_ISSUE and ticketId ~= TICKET_CATEGORY_OTHER then
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

function ZO_Help_Customer_Service_Gamepad:SetupTicketByCategoryValue(value, autoFillFieldsFunction)
    self:ResetTicket()
    self:SetCategory(value)
    if autoFillFieldsFunction ~= nil then
        autoFillFieldsFunction()
    end
    self:SetRequiredInfoProvidedInternally(true)
    self:ChangeTicketState(ZO_HELP_TICKET_STATE.FIELD_ENTRY)
    self:BuildList()
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
    local function SetDisplayName()
        HELP_CUSTOMER_SERVICE_GAMEPAD:SetReportPlayerTargetByDisplayName(displayName)
    end
    HELP_CUSTOMER_SERVICE_GAMEPAD:SetupTicketByCategoryValue(CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER, SetDisplayName)
end

function ZO_Help_Customer_Service_Gamepad_SetupReportGuildTicket(guildName, subCategory)
    local function SetGuildName()
        HELP_CUSTOMER_SERVICE_GAMEPAD:SetReportGuildTargetByName(guildName)
        HELP_CUSTOMER_SERVICE_GAMEPAD:SetReportGuildSubcategory(subCategory)
    end
    HELP_CUSTOMER_SERVICE_GAMEPAD:SetupTicketByCategoryValue(CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_GUILD, SetGuildName)
end