ZO_Help_QuestAssistance_Gamepad = ZO_Help_MechanicAssistance_Gamepad:Subclass()

function ZO_Help_QuestAssistance_Gamepad:New(...)
    return ZO_Help_MechanicAssistance_Gamepad.New(self, ...)
end

function ZO_Help_QuestAssistance_Gamepad:Initialize(control)
    ZO_Help_MechanicAssistance_Gamepad.Initialize(self, control, ZO_QUEST_ASSISTANCE_CATEGORIES_DATA)
    self:SetGoToDetailsSourceKeybindText(GetString(SI_GAMEPAD_HELP_GO_TO_JOURNAL_KEYBIND))
    self:SetDetailsHeader(GetString(SI_CUSTOMER_SERVICE_QUEST_NAME))
    self:SetDetailsInstructions(GetString(SI_CUSTOMER_SERVICE_QUEST_ASSISTANCE_NAME_INSTRUCTIONS))
end

function ZO_Help_QuestAssistance_Gamepad:GetSceneName()
   return "helpQuestAssistanceGamepad"
end

function ZO_Help_QuestAssistance_Gamepad:GoToDetailsSourceScene()
    SCENE_MANAGER:Push("gamepad_quest_journal")
end

function ZO_Help_QuestAssistance_Gamepad:GetFieldEntryTitle()
   return GetString(SI_CUSTOMER_SERVICE_QUEST_ASSISTANCE)
end

function ZO_Help_QuestAssistance_Gamepad:RegisterDetails()
    local savedDetails = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    if savedDetails then
        SetCustomerServiceTicketQuestTarget(savedDetails)
    end
end

function ZO_Help_QuestAssistance_Gamepad:DetailsRequired()
    return true
end

function ZO_Help_QuestAssistance_Gamepad_OnInitialize(control)
    HELP_QUEST_ASSISTANCE_GAMEPAD = ZO_Help_QuestAssistance_Gamepad:New(control)
end