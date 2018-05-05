ZO_HELP_TICKET_STATE =
{
    FIELD_ENTRY = 1,
    START_SUBMISSION = 2,
}

ZO_HELP_TICKET_VALIDATION_STATUS = 
{
    SUCCESS = true,
    FAILED_NO_DETAILS = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_DETAILS),
    FAILED_NO_CATEGORY = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_CATEGORY),
    FAILED_NO_DESCRIPTION = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_DESCRIPTION),
    FAILED_NO_DISPLAY_NAME = zo_strformat(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_DISPLAY_NAME, ZO_GetPlatformAccountLabel()),
    FAILED_NO_IMPACT = GetString(SI_GAMEPAD_HELP_TICKET_FAILED_REPORT_WITHOUT_IMPACT),
    FAILED_ATTACHED_SCREENSHOT_RECENTLY = GetString(SI_TOO_FREQUENT_BUG_SCREENSHOT),
}

local REFRESH_KEYBIND_STRIP = true

ZO_Help_GenericTicketSubmission_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Help_GenericTicketSubmission_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

-- Initialization --

function ZO_Help_GenericTicketSubmission_Gamepad:Initialize(control)
    self.scene = ZO_Scene:New(self:GetSceneName(), SCENE_MANAGER)
    self.fragment = ZO_FadeSceneFragment:New(control)
    self.scene:AddFragment(self.fragment)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, self.scene)

    self.savedFields = {}

    self.headerDataFieldEntry = 
    {
        titleText = self:GetFieldEntryTitle(),
        messageText = self:GetFieldEntryMessage(),
    }

    self.headerDataStartSubmission =
    {
        titleText = self:GetSubmissionTitle(),
        messageText = self:GetSubmissionMessage(),
    }

    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:RegisterCallback("CustomerServiceTicketSubmitted", function (...) self:OnCustomerServiceTicketSubmitted(...) end)
    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:RegisterCallback("CustomerServiceFeedbackSubmitted", function (...) self:OnCustomerServiceFeedbackSubmitted(...) end)
end

function ZO_Help_GenericTicketSubmission_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptorsByState = 
    {
        [ZO_HELP_TICKET_STATE.FIELD_ENTRY] = 
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            -- Back
            KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() SCENE_MANAGER:HideCurrentScene() end, nil, SOUNDS.DIALOG_DECLINE),
            -- Select
            self:GenerateSelectKeybindStripDescriptor(),
        },
        [ZO_HELP_TICKET_STATE.START_SUBMISSION] = 
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
        },
    }
    for _, keybindStripDescriptor in ipairs(self.keybindStripDescriptorsByState) do
        ZO_Gamepad_AddListTriggerKeybindDescriptors(keybindStripDescriptor, function() return self:GetMainList() end)
    end
end

function ZO_Help_GenericTicketSubmission_Gamepad:GenerateSelectKeybindStripDescriptor()
    --Can be overriden
end

-- Accessors --

function ZO_Help_GenericTicketSubmission_Gamepad:GetScene()
    return self.scene
end

function ZO_Help_GenericTicketSubmission_Gamepad:GetFragment()
    return self.fragment
end

function ZO_Help_GenericTicketSubmission_Gamepad:GetSceneName()
    assert(false) --Must be overriden
end

function ZO_Help_GenericTicketSubmission_Gamepad:GetFieldEntryTitle()
    assert(false) --Must be overriden
end

function ZO_Help_GenericTicketSubmission_Gamepad:GetFieldEntryMessage()
    assert(false) --Must be overriden
end

function ZO_Help_GenericTicketSubmission_Gamepad:GetSubmissionTitle()
    return GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_SUBMISSION_IN_PROGRESS_TITLE)
end

function ZO_Help_GenericTicketSubmission_Gamepad:GetSubmissionMessage()
    return GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_SUBMISSION_IN_PROGRESS_MESSAGE)
end

function ZO_Help_GenericTicketSubmission_Gamepad:GetSavedField(fieldType)
    return self.savedFields[fieldType]
end

function ZO_Help_GenericTicketSubmission_Gamepad:SetSavedField(fieldType, fieldValue, refreshVisible)
    self.savedFields[fieldType] = fieldValue
    if refreshVisible then
        self:GetMainList():RefreshVisible()
    end
end

-- Functionality --

function ZO_Help_GenericTicketSubmission_Gamepad:ResetTicket()
    ZO_ClearTable(self.savedFields)
    self:GetMainList():RefreshVisible()
end

function ZO_Help_GenericTicketSubmission_Gamepad:ChangeTicketState(ticketState, refreshKeybindStrip)
    if self.ticketState ~= ticketState then
        self.ticketState = ticketState

        if refreshKeybindStrip then
            self:AddKeybindsBasedOnState()
        end

        -- field entry
        if self.ticketState == ZO_HELP_TICKET_STATE.FIELD_ENTRY then
            self.headerData = self.headerDataFieldEntry

            self:BuildList()

        -- start submission
        elseif self.ticketState == ZO_HELP_TICKET_STATE.START_SUBMISSION then
            self.headerData = self.headerDataStartSubmission

            self:GetMainList():Clear()
            self:GetMainList():Commit()

            self:SubmitTicket()
        end

        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end
end

function ZO_Help_GenericTicketSubmission_Gamepad:BuildList()
    assert(false) --Must be overriden
end

function ZO_Help_GenericTicketSubmission_Gamepad:SubmitTicket()
    assert(false) --Must be overriden
end

function ZO_Help_GenericTicketSubmission_Gamepad:AddKeybindsBasedOnState()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    self.keybindStripDescriptor = self.keybindStripDescriptorsByState[self.ticketState]
    
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Help_GenericTicketSubmission_Gamepad:TrySubmitTicket()
    local result = self:ValidateTicketFields()
    if result == ZO_HELP_TICKET_VALIDATION_STATUS.SUCCESS then
        self:ChangeTicketState(ZO_HELP_TICKET_STATE.START_SUBMISSION, REFRESH_KEYBIND_STRIP)
    else
        ZO_Dialogs_ShowGamepadDialog("HELP_CUSTOMER_SERVICE_TICKET_FAILED_REASON", nil, {mainTextParams = { result }})
    end
end

function ZO_Help_GenericTicketSubmission_Gamepad:ValidateTicketFields()
    return ZO_HELP_TICKET_VALIDATION_STATUS.SUCCESS
end

-- Events --

function ZO_Help_GenericTicketSubmission_Gamepad:OnCustomerServiceTicketSubmitted()
    self:ResetTicket()
    self:ChangeTicketState(ZO_HELP_TICKET_STATE.FIELD_ENTRY)
end

function ZO_Help_GenericTicketSubmission_Gamepad:OnCustomerServiceFeedbackSubmitted()
    self:ResetTicket()
    self:ChangeTicketState(ZO_HELP_TICKET_STATE.FIELD_ENTRY)
end

function ZO_Help_GenericTicketSubmission_Gamepad:OnShowing()
    self:ChangeTicketState(ZO_HELP_TICKET_STATE.FIELD_ENTRY)
end

function ZO_Help_GenericTicketSubmission_Gamepad:OnShow()
    self:AddKeybindsBasedOnState()
end

function ZO_Help_GenericTicketSubmission_Gamepad:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Help_GenericTicketSubmission_Gamepad:OnHide()
    self:ResetTicket()
end