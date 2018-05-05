local CUSTOMER_SERVICE_CATEGORY_DATA =
{
    name = GetString(SI_CUSTOMER_SERVICE_QUEST_ASSISTANCE),
    up = "EsoUI/Art/Help/help_tabIcon_questAssistance_up.dds",
    down = "EsoUI/Art/Help/help_tabIcon_questAssistance_down.dds",
    over = "EsoUI/Art/Help/help_tabIcon_questAssistance_over.dds",
}

ZO_HelpQuestAssistance_Keyboard = ZO_HelpMechanicAssistanceTemplate_Keyboard:Subclass()

function ZO_HelpQuestAssistance_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function ZO_HelpQuestAssistance_Keyboard:Initialize(control)
    ZO_HelpMechanicAssistanceTemplate_Keyboard.Initialize(self, control, CUSTOMER_SERVICE_CATEGORY_DATA, ZO_QUEST_ASSISTANCE_CATEGORIES_DATA)
end

function ZO_HelpQuestAssistance_Keyboard:GetExtraInfoText()
    return zo_strformat(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_NO_QUEST_HINT, ZO_LinkHandler_CreateURLLink("", GetURLTextByType(APPROVED_URL_ESO_FORUMS)))
end

function ZO_HelpQuestAssistance_Keyboard:GetDetailsInstructions()
    return GetString(SI_CUSTOMER_SERVICE_QUEST_ASSISTANCE_NAME_INSTRUCTIONS)
end

function ZO_HelpQuestAssistance_Keyboard:RegisterDetails()
    SetCustomerServiceTicketQuestTarget(self:GetDetailsText())
end

function ZO_HelpQuestAssistance_Keyboard:DetailsRequired()
    return true
end

--Global XML

function ZO_HelpQuestAssistance_Keyboard_OnInitialized(self)
    HELP_CUSTOMER_SERVICE_QUEST_ASSISTANCE_KEYBOARD = ZO_HelpQuestAssistance_Keyboard:New(self)
end

function ZO_HelpQuestAssistance_Keyboard_AttemptToSendTicket()
    HELP_CUSTOMER_SERVICE_QUEST_ASSISTANCE_KEYBOARD:AttemptToSendTicket()
end