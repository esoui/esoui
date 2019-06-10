------------------
-- Guild Finder --
------------------

ZO_GuildRecruitment_ApplicationsDefaultMessage_Keyboard = ZO_GuildRecruitment_Panel_Shared:Subclass()

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Keyboard:New(...)
    return ZO_GuildRecruitment_Panel_Shared.New(self, ...)
end

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Keyboard:Initialize(control)
    ZO_GuildRecruitment_Panel_Shared.Initialize(self, control)

    self.messageBox = ZO_ScrollingSavingEditBox:New(control:GetNamedChild("DefaultMessage"))
    self.messageBox:SetDefaultText(GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_DEFAULT_TEXT))
    self.messageBox:SetEmptyText(GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_EMPTY_TEXT))
    local editControl = self.messageBox:GetEditControl()
    editControl:SetMaxInputChars(MAX_GUILD_APPLICATION_DECLINE_MESSAGE_LENGTH)
    self.messageBox:RegisterCallback("Save", function(text) GUILD_RECRUITMENT_MANAGER:SetSavedApplicationsDefaultMessage(self.guildId, text) end)

    self:InitializeDefaultMessageDefaults()
end

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Keyboard:OnShowing()
    local messageBoxText = type(self.savedMessageFunction) == "function" and self.savedMessageFunction() or ""
    self.messageBox:SetText(messageBoxText)
end

-- XML Functions
-----------------

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Keyboard_OnInitialized(control)
    GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD:SetSubcategoryManager(ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_MESSAGE, ZO_GuildRecruitment_ApplicationsDefaultMessage_Keyboard:New(control))
end