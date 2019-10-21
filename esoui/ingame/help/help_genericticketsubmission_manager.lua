local SCREENSHOT_SUBMISSION_COOLDOWN = 30000

local ZO_Help_GenericTicketSubmission_Manager = ZO_CallbackObject:Subclass()

function ZO_Help_GenericTicketSubmission_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...) -- ZO_CallbackObject does not have an initialize function
    return manager
end

function ZO_Help_GenericTicketSubmission_Manager:Initialize()
    self.lastSubmitWithScreenshotTime = 0
    self.ticketSubmittedFailedHeader = GetString(SI_GAMEPAD_HELP_TICKET_SUBMITTED_DIALOG_HEADER_FAILURE)
    self.ticketSubmittedSuccessHeader = GetString(SI_GAMEPAD_HELP_TICKET_SUBMITTED_DIALOG_HEADER_SUCCESS)
    self.ticketSubmittedFailedMessage = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FAILED_TICKET_SUBMISSION)
    self.knowledgeBaseText = GetString(SI_GAMEPAD_HELP_CUSTOMER_SERVICE_FINAL_HEADER_KNOWLEDGE_BASE)
    self.websiteText = GetString(SI_GAMEPAD_HELP_WEBSITE)
    self.reportPlayerTicketSubmittedCallback = nil
    self.reportGuildTicketSubmittedCallback = nil
    self.isAttemptingToSubmitReportPlayerTicket = false

    EVENT_MANAGER:RegisterForEvent("ZO_Help_GenericTicketSubmission_Manager", EVENT_CUSTOMER_SERVICE_TICKET_SUBMITTED, function(...) self:OnCustomerServiceTicketSubmitted(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_Help_GenericTicketSubmission_Manager", EVENT_CUSTOMER_SERVICE_FEEDBACK_SUBMITTED, function(...) self:OnCustomerServiceFeedbackSubmitted(...) end)
end

function ZO_Help_GenericTicketSubmission_Manager:OnCustomerServiceTicketSubmitted(eventCode, response, success)
    if success and self.isAttemptingToSubmitReportPlayerTicket and self.reportPlayerTicketSubmittedCallback then
        self.reportPlayerTicketSubmittedCallback()
    end

    if success and self.reportGuildTicketSubmittedCallback then
        self.reportGuildTicketSubmittedCallback()
    end

    self:FireCallbacks("CustomerServiceTicketSubmitted", response, success)

    ZO_Dialogs_ReleaseDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")
    ZO_Dialogs_ReleaseDialog("HELP_CUSTOMER_SERVICE_GAMEPAD_SUBMITTING_TICKET")

    self.isAttemptingToSubmitReportPlayerTicket = false
    self.reportPlayerTicketSubmittedCallback = nil
    self.reportGuildTicketSubmittedCallback = nil

    if IsInGamepadPreferredMode() then
        local dialogParams = {}

        if success == true and response ~= nil then
            dialogParams.titleParams = { self.ticketSubmittedSuccessHeader }
            dialogParams.mainTextParams =
            {
                response,
                self.knowledgeBaseText,
                self.websiteText,
            }
        else
            dialogParams.titleParams = { self.ticketSubmittedFailedHeader }
            dialogParams.mainTextParams =
            {
                self.ticketSubmittedFailedMessage,
                self.knowledgeBaseText,
                self.websiteText,
            }
        end

        ZO_Dialogs_ShowGamepadDialog("HELP_CUSTOMER_SERVICE_GAMEPAD_TICKET_SUBMITTED", nil, dialogParams)
    else
        if success then
            ZO_Dialogs_ShowDialog("HELP_ASK_FOR_HELP_SUBMIT_TICKET_SUCCESSFUL_DIALOG", nil, {mainTextParams = {response}})
        else
            ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMIT_TICKET_ERROR_DIALOG", nil, {mainTextParams = {response}})
        end
    end
end

function ZO_Help_GenericTicketSubmission_Manager:OnCustomerServiceFeedbackSubmitted(eventCode, response, success)
    self:FireCallbacks("CustomerServiceFeedbackSubmitted", response, success)

    ZO_Dialogs_ReleaseDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")
    ZO_Dialogs_ReleaseDialog("HELP_CUSTOMER_SERVICE_GAMEPAD_SUBMITTING_TICKET")

    if success then
        ZO_Dialogs_ShowPlatformDialog("HELP_SUBMIT_FEEDBACK_SUBMIT_TICKET_SUCCESSFUL_DIALOG", nil, {mainTextParams = {response}})
    else
        ZO_Dialogs_ShowPlatformDialog("HELP_CUSTOMER_SERVICE_SUBMIT_TICKET_ERROR_DIALOG", nil, {mainTextParams = {response}})
    end
end

function ZO_Help_GenericTicketSubmission_Manager:AttemptToSendFeedback(impactId, categoryId, subcategoryId, detailsText, descriptionText, attachScreenshot)
    if attachScreenshot and not self:CanSubmitFeedbackWithScreenshot() then
        ZO_Dialogs_ShowPlatformDialog("TOO_FREQUENT_BUG_SCREENSHOT")
    else
        SCENE_MANAGER:ShowBaseScene()
        ReportFeedback(impactId, categoryId, subcategoryId, detailsText, descriptionText, attachScreenshot)

        if attachScreenshot then
            self.lastSubmitWithScreenshotTime = GetFrameTimeMilliseconds()
        end

        if IsInGamepadPreferredMode() then
            ZO_Dialogs_ShowGamepadDialog("HELP_CUSTOMER_SERVICE_GAMEPAD_SUBMITTING_TICKET")
        else
            ZO_Dialogs_ShowDialog("HELP_CUSTOMER_SERVICE_SUBMITTING_TICKET_DIALOG")
        end
    end
end

function ZO_Help_GenericTicketSubmission_Manager:CanSubmitFeedbackWithScreenshot()
    return GetFrameTimeMilliseconds() > (self.lastSubmitWithScreenshotTime + SCREENSHOT_SUBMISSION_COOLDOWN)
end

function ZO_Help_GenericTicketSubmission_Manager:OpenReportPlayerTicketScene(name, ticketSubmittedCallback)
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Push("helpCustomerServiceGamepad")
        ZO_Help_Customer_Service_Gamepad_SetupReportPlayerTicket(name)
    else
        HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:OpenAskForHelp(CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_PLAYER, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_PLAYER_SUBCATEGORY_NONE, name)
    end

    self:SetReportPlayerTicketSubmittedCallback(ticketSubmittedCallback)
end

function ZO_Help_GenericTicketSubmission_Manager:OpenReportGuildTicketScene(name, subCategory, ticketSubmittedCallback)
    subCategory = subCategory or CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_SUBCATEGORY_NONE
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Push("helpCustomerServiceGamepad")
        ZO_Help_Customer_Service_Gamepad_SetupReportGuildTicket(name, subCategory)
    else
        HELP_CUSTOMER_SERVICE_ASK_FOR_HELP_KEYBOARD:OpenAskForHelp(CUSTOMER_SERVICE_ASK_FOR_HELP_CATEGORY_REPORT_GUILD, subCategory, name)
    end

    self:SetReportGuildTicketSubmittedCallback(ticketSubmittedCallback)
end

function ZO_Help_GenericTicketSubmission_Manager:MarkAttemptingToSubmitReportPlayerTicket()
    self.isAttemptingToSubmitReportPlayerTicket = true
end

function ZO_Help_GenericTicketSubmission_Manager:SetReportPlayerTicketSubmittedCallback(reportSubmittedCallback)
    self.reportPlayerTicketSubmittedCallback = reportSubmittedCallback
end

function ZO_Help_GenericTicketSubmission_Manager:SetReportGuildTicketSubmittedCallback(reportSubmittedCallback)
    self.reportGuildTicketSubmittedCallback = reportSubmittedCallback
end

ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER = ZO_Help_GenericTicketSubmission_Manager:New()