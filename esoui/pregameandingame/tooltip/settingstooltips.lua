---------------------------------------
-- Settings Tooltip Functions
---------------------------------------

function ZO_Tooltip:LayoutSettingAccountResendActivation(hasActivatedEmail, accountEmail)
    self:AddLine(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_RESEND_ACTIVATION_TOOLTIP_LABEL), self:GetStyle("statValuePairStat"))

    local emailText = accountEmail
    if emailText == "" then
        emailText = GetString(SI_INTERFACE_OPTIONS_ACCOUNT_NO_EMAIL_TEXT)
    end
    local statValueSection = self:AcquireSection(self:GetStyle("accountValueStatsSection"))
    statValueSection:AddLine(emailText)
    self:AddSection(statValueSection)

    if not hasActivatedEmail then
        local warningSection = self:AcquireSection(self:GetStyle("bodySection"), self:GetStyle("bodyDescription"))
        warningSection:AddLine(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_NEED_ACTIVE_ACCOUNT_WARNING), self:GetStyle("failed"))
        self:AddSection(warningSection)

        local bodySection = self:AcquireSection(self:GetStyle("bodySection"), self:GetStyle("bodyDescription"))
        local resendActivationOptionText = ZO_SELECTED_TEXT:Colorize(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_RESEND_ACTIVATION))
        local changeEmailOptionText = ZO_SELECTED_TEXT:Colorize(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_CHANGE_EMAIL))
        bodySection:AddLine(zo_strformat(SI_INTERFACE_OPTIONS_ACCOUNT_RESEND_ACTIVATION_TOOLTIP_TEXT, resendActivationOptionText, changeEmailOptionText))
        self:AddSection(bodySection)
    end
end

function ZO_Tooltip:LayoutSettingAccountGetUpdates(hasActivatedEmail)
    self:AddLine(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_GET_UPDATES_TOOLTIP_TITLE), self:GetStyle("title"))

    if not hasActivatedEmail then
        local warningSection = self:AcquireSection(self:GetStyle("bodySection"), self:GetStyle("bodyDescription"))
        warningSection:AddLine(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_NEED_ACTIVE_ACCOUNT_WARNING), self:GetStyle("failed"))
        self:AddSection(warningSection)
    end

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"), self:GetStyle("bodyDescription"))
    bodySection:AddLine(GetString(SI_INTERFACE_OPTIONS_ACCOUNT_GET_UPDATES_TOOLTIP_TEXT))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutSettingTooltip(tooltipText, warningText)
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(tooltipText, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)

    if warningText then
        local warningSection = self:AcquireSection(self:GetStyle("bodySection"))
        warningSection:AddLine(warningText, self:GetStyle("bodyDescription"), self:GetStyle("failed"))
        self:AddSection(warningSection)
    end
end
