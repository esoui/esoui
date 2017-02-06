local TICKET_STATE_FIELD_ENTRY = 1
local TICKET_STATE_START_SUBMISSION = 2

local TICKET_FIELD_EMAIL = 1
local TICKET_FIELD_CATEGORY = 2
local TICKET_FIELD_SUBCATEGORY = 3
local TICKET_FIELD_REQUIRED_DETAILS = 4
local TICKET_FIELD_ADDITIONAL_DETAILS = 5

local TICKET_VALIDATION_STATUS = 
{
    SUCCESS = 1,
    FAILED_NO_EMAIL = 2,
    FAILED_NO_NAME = 3,
}

local REFRESH_KEYBIND_STRIP = true

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

local VALIDATION_ERROR_STRINGS = 
{
    [TICKET_VALIDATION_STATUS.FAILED_NO_EMAIL] = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_NO_EMAIL),
    [TICKET_VALIDATION_STATUS.FAILED_NO_NAME] = 
    {
        [TICKET_CATEGORY_REPORT_DEFAULT] = zo_strformat(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_DISPLAY_NAME, ZO_GetPlatformAccountLabel())
    }
}

-- The email address (result of GetActiveUserEmailAddress) needs to be kept private, 
-- so it can't be stored in the ZO_Help_Customer_Service_Gamepad object
local g_email = ""

local function GetValidationErrorString(validationStatus, category)
    if validationStatus ~= TICKET_VALIDATION_STATUS.SUCCESS then
        local errorStringContainer = VALIDATION_ERROR_STRINGS[validationStatus]
        if validationStatus == TICKET_VALIDATION_STATUS.FAILED_NO_EMAIL then
            return errorStringContainer
        else
            return errorStringContainer[category]
        end
    end
    return nil
end

local ZO_Help_Customer_Service_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Help_Customer_Service_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_Help_Customer_Service_Gamepad:Initialize(control)
    HELP_CUSTOMER_SERVICE_GAMEPAD_SCENE = ZO_Scene:New("helpCustomerServiceGamepad", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, HELP_CUSTOMER_SERVICE_GAMEPAD_SCENE)
    self.itemList = ZO_Gamepad_ParametricList_Screen.GetMainList(self)

    local helpCustomerServiceFragment = ZO_FadeSceneFragment:New(control)
    HELP_CUSTOMER_SERVICE_GAMEPAD_SCENE:AddFragment(helpCustomerServiceFragment)

    self.savedFields = {}

    self.fieldRegistrationFunctions = 
    {
        [TICKET_FIELD_EMAIL] = SetCustomerServiceTicketContactEmail,
        [TICKET_FIELD_CATEGORY] = SetCustomerServiceTicketCategory,
        [TICKET_FIELD_SUBCATEGORY] = SetCustomerServiceTicketCategory,
        [TICKET_FIELD_REQUIRED_DETAILS] =   function(text)
                                                local categoryId = self:GetCurrentCategory()
                                                if (categoryId == TICKET_CATEGORY_REPORT_DEFAULT) then
                                                    self:SetReportPlayerTargetByDisplayName(ZO_FormatManualNameEntry(text))
                                                end
                                            end,
        [TICKET_FIELD_ADDITIONAL_DETAILS] = function(text)
                                                self:SetBodyText(text)
                                            end,
    }

    local headerMessageControl = self.control:GetNamedChild("Mask"):GetNamedChild("Container"):GetNamedChild("HeaderContainer"):GetNamedChild("Header"):GetNamedChild("Message")
    headerMessageControl:SetFont("ZoFontGamepadCondensed42")

    self.ticketSubmittedFailedHeader = GetString(SI_GAMEPAD_HELP_TICKET_SUBMITTED_DIALOG_HEADER_FAILURE)
    self.ticketSubmittedSuccessHeader = GetString(SI_GAMEPAD_HELP_TICKET_SUBMITTED_DIALOG_HEADER_SUCCESS)
    self.ticketSubmittedFailedMessage = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FAILED_TICKET_SUBMISSION)
    self.knowledgeBaseText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FINAL_HEADER_KNOWLEDGE_BASE)
    self.websiteText = GetString(SI_GAMEPAD_HELP_WEBSITE)

    control:RegisterForEvent(EVENT_CUSTOMER_SERVICE_TICKET_SUBMITTED, function (...) self:OnCustomerServiceTicketSubmitted(...) end)
end

function ZO_Help_Customer_Service_Gamepad:OnShowing()
    self:ChangeTicketState(TICKET_STATE_FIELD_ENTRY)
    self:PrefillContactEmail()
    self:UpdateFields()
end

function ZO_Help_Customer_Service_Gamepad:OnShow()
    self:AddKeybindsBasedOnState()
end

function ZO_Help_Customer_Service_Gamepad:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Help_Customer_Service_Gamepad:OnHide()
    if(self.currentDropdown ~= nil) then
        self.currentDropdown:Deactivate(true)
    end
    self:ResetTicket()
end

function ZO_Help_Customer_Service_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptorsByState = 
    {
        [TICKET_STATE_FIELD_ENTRY] = 
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            -- Back
            KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() SCENE_MANAGER:HideCurrentScene() end, nil, SOUNDS.DIALOG_DECLINE),
            -- Select
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
            },
        },
        [TICKET_STATE_START_SUBMISSION] = 
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
        },
    }

    for _, keybindStripDescriptor in ipairs(self.keybindStripDescriptorsByState) do
        ZO_Gamepad_AddListTriggerKeybindDescriptors(keybindStripDescriptor, function() return self.itemList end )
    end
end

function ZO_Help_Customer_Service_Gamepad:AddKeybindsBasedOnState()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    self.keybindStripDescriptor = self.keybindStripDescriptorsByState[self.ticketState]
    
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

do
    local HEADER_DATA_FIELD_ENTRY = 
    {
        titleText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE),
        messageText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FIELD_ENTRY_MESSAGE),
    }

    local HEADER_DATA_START_SUBMISSION = 
    {
        titleText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_SUBMISSION_IN_PROGRESS_TITLE),
        messageText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_SUBMISSION_IN_PROGRESS_MESSAGE),
    }

    -- refreshKeybindStrip should only be used for internal state changes
    function ZO_Help_Customer_Service_Gamepad:ChangeTicketState(ticketState, refreshKeybindStrip)
        self.ticketState = ticketState

        if refreshKeybindStrip then
            self:AddKeybindsBasedOnState()
        end

        -- field entry
        if (self.ticketState == TICKET_STATE_FIELD_ENTRY) then
            self.headerData = HEADER_DATA_FIELD_ENTRY

        -- start submission
        elseif (self.ticketState == TICKET_STATE_START_SUBMISSION) then
            self.itemList:Clear()
            self.itemList:Commit()

            self.headerData = HEADER_DATA_START_SUBMISSION

            self:SubmitTicket()
        end

        self:PerformUpdate()
    end
end

function ZO_Help_Customer_Service_Gamepad:TrySubmitTicket()
    local result = self:ValidateTicketFields()
    if (result == TICKET_VALIDATION_STATUS.SUCCESS) then
        self:ChangeTicketState(TICKET_STATE_START_SUBMISSION, REFRESH_KEYBIND_STRIP)
    else
        ZO_Dialogs_ShowGamepadDialog("HELP_CUSTOMER_SERVICE_TICKET_FAILED_REASON", nil, {mainTextParams = { GetValidationErrorString(result, self:GetCurrentCategory()) }})
    end
end

function ZO_Help_Customer_Service_Gamepad:ValidateTicketFields()
    local result = TICKET_VALIDATION_STATUS.SUCCESS
    local email = g_email
    if (email == nil) or (email == "") then
        result = TICKET_VALIDATION_STATUS.FAILED_NO_EMAIL
    else
        local details = self.savedFields[TICKET_FIELD_REQUIRED_DETAILS]
        if (details == nil) or (details == "") then
            local categoryId = self:GetCurrentCategory()
            --"Character" required information is inferred, so nothing is required
            if (categoryId ~= TICKET_CATEGORY_CHARACTER_ISSUE and categoryId ~= TICKET_CATEGORY_OTHER) then
                result = TICKET_VALIDATION_STATUS.FAILED_NO_NAME
            end
        end
    end
    return result
end

function ZO_Help_Customer_Service_Gamepad:SubmitTicket()
    SubmitCustomerServiceTicket()
end

function ZO_Help_Customer_Service_Gamepad:ResetTicket()
    ResetCustomerServiceTicket()
    self:SetCategory(TICKET_CATEGORY_CHARACTER_ISSUE)
    self.savedFields[TICKET_FIELD_REQUIRED_DETAILS] = nil
    self.savedFields[TICKET_FIELD_ADDITIONAL_DETAILS] = nil
    self.savedFields[TICKET_FIELD_SUBCATEGORY] = nil
    self.requiredInfoProvidedInternally = false
    
    self:PrefillContactEmail()
    self:UpdateFields()
end

function ZO_Help_Customer_Service_Gamepad:OnCustomerServiceTicketSubmitted(eventCode, response, success)
    --TODO: Split everything out and refactor
    local customerServiceShowing = SCENE_MANAGER:IsShowing("helpCustomerServiceGamepad")
    local questAssistanceShowing = SCENE_MANAGER:IsShowing("helpQuestAssistanceGamepad")
    local itemAssistanceShowing = SCENE_MANAGER:IsShowing("helpItemAssistanceGamepad")
    if customerServiceShowing or questAssistanceShowing or itemAssistanceShowing then
        local dialogParams = {}
        local email = customerServiceShowing and g_email or GetActiveUserEmailAddress()

        if ((success == true) and (response ~= nil)) then
            dialogParams.titleParams = { self.ticketSubmittedSuccessHeader }
            dialogParams.mainTextParams =   {
                                                response .. zo_strformat(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_SUBMITTED_EMAIL, email),
                                                self.knowledgeBaseText, 
                                                self.websiteText,
                                            }
        else
            dialogParams.titleParams = { self.ticketSubmittedFailedHeader }
            dialogParams.mainTextParams =   {
                                                self.ticketSubmittedFailedMessage,
                                                self.knowledgeBaseText,
                                                self.websiteText,
                                            }
        end

        ZO_Dialogs_ShowGamepadDialog("HELP_CUSTOMER_SERVICE_GAMEPAD_TICKET_SUBMITTED", nil, dialogParams)
    end

    self:ResetTicket()
end

function ZO_Help_Customer_Service_Gamepad:SetReportPlayerTargetByDisplayName(displayName)
    SetCustomerServiceTicketPlayerTarget(displayName) -- this function only works on Console builds
    self.savedFields[TICKET_FIELD_REQUIRED_DETAILS] = ZO_FormatUserFacingDisplayName(displayName)
end

function ZO_Help_Customer_Service_Gamepad:SetBodyText(bodyText)
    SetCustomerServiceTicketBody(bodyText)
    self.savedFields[TICKET_FIELD_ADDITIONAL_DETAILS] = bodyText
end

function ZO_Help_Customer_Service_Gamepad:SetCategory(categoryId)
    for categoryIndex, categoryInfo in ipairs(TICKET_CATEGORIES) do
        if (categoryInfo.id == categoryId) then
            self.savedFields[TICKET_FIELD_CATEGORY] = categoryIndex
            break
        end
    end
    SetCustomerServiceTicketCategory(categoryId)
end

function ZO_Help_Customer_Service_Gamepad:SetSubcategory(subcategoryId)
    for categoryIndex, categoryInfo in ipairs(TICKET_CATEGORIES) do
        local subcategories = TICKET_SUBCATEGORIES[categoryInfo.id]
        if (subcategories) then
            for subcategoryIndex, subcategoryInfo in ipairs(subcategories) do
                if (subcategoryInfo.id == subcategoryId) then
                    self.savedFields[TICKET_FIELD_CATEGORY] = categoryIndex
                    self.savedFields[TICKET_FIELD_SUBCATEGORY] = subcategoryIndex
                    break
                end
            end
        end
    end
    SetCustomerServiceTicketCategory(subcategoryId)
end

function ZO_Help_Customer_Service_Gamepad:SetRequiredInfoProvidedInternally(isProvidedInternally)
    self.requiredInfoProvidedInternally = isProvidedInternally
end

function ZO_Help_Customer_Service_Gamepad:PrefillContactEmail()
    local email = GetActiveUserEmailAddress()
    if (email and (email ~= "")) then
        g_email = email
        SetCustomerServiceTicketContactEmail(email)
    end
end

function ZO_Help_Customer_Service_Gamepad:GetCurrentCategory()
    local categoryIndex = self.savedFields[TICKET_FIELD_CATEGORY]
    if categoryIndex then
        return self:GetCategoryIdFromIndex(categoryIndex)
    end
end

function ZO_Help_Customer_Service_Gamepad:GetCategoryIdFromIndex(categoryIndex)
    local categoryInfo = TICKET_CATEGORIES[categoryIndex]
    if (categoryInfo) then
        return categoryInfo.id
    end
end

function ZO_Help_Customer_Service_Gamepad:OnTextFieldFocusLost(control, fieldType)
    if (control) then
        ZO_EditDefaultText_OnTextChanged(control)
        local registerFunction = self.fieldRegistrationFunctions[fieldType]
        if (registerFunction) then
            local text = control:GetText()
            if (fieldType == TICKET_FIELD_EMAIL) then
                g_email = text
            else
                self.savedFields[fieldType] = text
            end
            registerFunction(text)
        end
    end
end

function ZO_Help_Customer_Service_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)

    local function GetSavedFieldText(data)
        if (data.fieldType == TICKET_FIELD_EMAIL) then
            return g_email
        else
            return data.customerServiceObject.savedFields[data.fieldType]
        end
    end

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

        local savedText = GetSavedFieldText(data)
        if (savedText) then
            control.editBox:SetText(savedText)
        else
            control.editBox:SetText("")
        end

        if data.isRequired and not self.requiredInfoProvidedInternally then
            local defaultText = data.fieldType == TICKET_FIELD_EMAIL and GetString(SI_GAMEPAD_HELP_EMAIL_ADDRESS_REQUIRED) or REQUIRED_FIELD_DEFAULT_TEXTS[self:GetCurrentCategory()]
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

        local savedText = GetSavedFieldText(data)
        if (savedText) then
            control.lockedLabel:SetText(savedText)
        else
            control.lockedLabel:SetText("")
        end

        control.highlight:SetHidden(not selected)
    end

    local function SetupDropdownListEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)
        control.dropdown:SetSortsItems(false)

        data.customerServiceObject:BuildDropdownList(control.dropdown, data)
        if (selected) then
            data.customerServiceObject:SetCurrentDropdown(control.dropdown)
        end
    end

    list:AddDataTemplateWithHeader("ZO_GamepadTextFieldItem_Multiline", SetupTextFieldListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate")
    list:AddDataTemplateWithHeader("ZO_Gamepad_Help_EditLockedEntry_MultiLine", SetupLockedTextFieldListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderWithLockTemplate")
    list:AddDataTemplateWithHeader("ZO_Gamepad_Help_Dropdown_Item", SetupDropdownListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate")
    list:AddDataTemplate("ZO_GamepadTextFieldSubmitItem", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

local function OnDropdownDeactivated(object)
    ZO_Help_Customer_Service_Gamepad.ActivateItemList(object)
end

function ZO_Help_Customer_Service_Gamepad:DropdownItemCallback(selectionIndex, fieldType, ticketCategoryId)
    if (self.savedFields[fieldType] ~= selectionIndex) then
        self.savedFields[fieldType] = selectionIndex
        local registerFunction = self.fieldRegistrationFunctions[fieldType]
        if (registerFunction) and (ticketCategoryId) then
            registerFunction(ticketCategoryId)
        end
        if fieldType == TICKET_FIELD_CATEGORY then
            if self.requiredInfoProvidedInternally then
                self.savedFields[TICKET_FIELD_REQUIRED_DETAILS] = nil
            end
            self.requiredInfoProvidedInternally = false
        end
        self:PerformUpdate()
    end
end

function ZO_Help_Customer_Service_Gamepad:BuildDropdownList(dropdown, data)
    dropdown:SetDeactivatedCallback(OnDropdownDeactivated, data.customerServiceObject)

    dropdown:ClearItems()

    for index, item in ipairs(data.list) do
        dropdown:AddItem(ZO_ComboBox:CreateItemEntry(item.name, function() self:DropdownItemCallback(index, data.fieldType, item.id) end), ZO_COMBOBOX_SUPRESS_UPDATE)
    end

    dropdown:UpdateItems()
    data.customerServiceObject:UpdateDropdownSelection(dropdown, data.fieldType)
end

function ZO_Help_Customer_Service_Gamepad:UpdateDropdownSelection(dropdown, fieldType)
    local savedField = self.savedFields[fieldType]
    if (savedField) then
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
        self:DeactivateItemList()
        self.currentDropdown:Activate()
        local savedField = self.savedFields[fieldType]
        if (savedField) then
            self.currentDropdown:SetHighlightedItem(savedField)
        else
            self.currentDropdown:SetHighlightedItem(1)
        end
    end
end

function ZO_Help_Customer_Service_Gamepad:DeactivateItemList()
    if(self.itemList:IsActive()) then
        self.itemList:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Help_Customer_Service_Gamepad:ActivateItemList()
    if(not self.itemList:IsActive()) then
        self.itemList:Activate()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Help_Customer_Service_Gamepad:AddTextFieldEntry(fieldType, header, required, locked)
    local entryData = ZO_GamepadEntryData:New(header)
    entryData.customerServiceObject = self
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
    entryData.customerServiceObject = self
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

function ZO_Help_Customer_Service_Gamepad:PerformUpdate()
    if (self.ticketState == TICKET_STATE_FIELD_ENTRY) then
        self:UpdateFields()
    end
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Help_Customer_Service_Gamepad:UpdateFields()
    self.dirty = false

    self.itemList:Clear()

    local FIELD_IS_REQUIRED = true

    -- email address
    self:AddTextFieldEntry(TICKET_FIELD_EMAIL, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_EMAIL), FIELD_IS_REQUIRED)

    -- categories
    self:AddDropdownEntry(TICKET_FIELD_CATEGORY, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_CATEGORY), TICKET_CATEGORIES)
        
    local categoryId = self:GetCurrentCategory()
    if (categoryId) then
        -- contextual subcategories
        local subcategories = TICKET_SUBCATEGORIES[categoryId]
        if (subcategories) then
            self:AddDropdownEntry(TICKET_FIELD_SUBCATEGORY, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_SUBCATEGORY), subcategories)
        end

        -- required fields
        if categoryId ~= TICKET_CATEGORY_CHARACTER_ISSUE and categoryId ~= TICKET_CATEGORY_OTHER then
            self:AddTextFieldEntry(TICKET_FIELD_REQUIRED_DETAILS, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_REQUIRED_DETAILS), FIELD_IS_REQUIRED, self.requiredInfoProvidedInternally)
        end
    end

    -- additional details
    self:AddTextFieldEntry(TICKET_FIELD_ADDITIONAL_DETAILS, GetString(SI_GAMEPAD_HELP_FIELD_TITLE_ADDITIONAL_DETAILS))
    
    self:AddSubmitEntry()

    self.itemList:Commit()
end

function ZO_Help_Customer_Service_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if (self.activeEditBox) then
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
    HELP_CUSTOMER_SERVICE_GAMEPAD:ChangeTicketState(TICKET_STATE_FIELD_ENTRY)
end

function ZO_Help_Customer_Service_Gamepad_SubmitReportPlayerSpammingTicket(displayName)
    HELP_CUSTOMER_SERVICE_GAMEPAD:ResetTicket()
    HELP_CUSTOMER_SERVICE_GAMEPAD:SetSubcategory(TICKET_CATEGORY_REPORT_SPAM)
    HELP_CUSTOMER_SERVICE_GAMEPAD:SetReportPlayerTargetByDisplayName(displayName)
    HELP_CUSTOMER_SERVICE_GAMEPAD:SubmitTicket()
end