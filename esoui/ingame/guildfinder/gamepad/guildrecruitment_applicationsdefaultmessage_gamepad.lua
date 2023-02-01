------------------
-- Guild Finder --
------------------

ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad = ZO_Object.MultiSubclass(ZO_GuildRecruitment_Panel_Shared, ZO_GuildFinder_Panel_GamepadBehavior)

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad:New(...)
    return ZO_GuildFinder_Panel_GamepadBehavior.New(self, ...)
end

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad:Initialize(control)
    ZO_GuildRecruitment_Panel_Shared.Initialize(self, control)
    ZO_GuildFinder_Panel_GamepadBehavior.Initialize(self, control)

    self.messageLabel = control:GetNamedChild("PanelMessage")

    self:InitializeDefaultMessageDefaults()
end

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad:GetDefaultMessageText()
    return self.savedMessageFunction()
end

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad:UpdateText(savedMessage, messageLabel)
    if type(savedMessage) == "function" then
        savedMessage = savedMessage()
    end

    if savedMessage == "" then
        messageLabel:SetText(GetString(SI_GUILD_RECRUITMENT_DEFAULT_RESPONSE_DEFAULT_TEXT))
    else
        messageLabel:SetText(savedMessage)
    end
end

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad:OnShowing()
    self:UpdateText(self.savedMessageFunction, self.messageLabel)
end

-- XML functions
----------------

function ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad_OnInitialized(control)
    GUILD_RECRUITMENT_RESPONSE_MESSAGE_GAMEPAD = ZO_GuildRecruitment_ApplicationsDefaultMessage_Gamepad:New(control)
end