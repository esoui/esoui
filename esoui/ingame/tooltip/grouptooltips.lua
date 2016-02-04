function ZO_Tooltip:LayoutGroupTooltip(title, bodyText, errorText)
    local titleSection = self:AcquireSection(self:GetStyle("groupTitleSection"))
    titleSection:AddLine(title, self:GetStyle("title"))
    self:AddSection(titleSection)

    local bodySection = self:AcquireSection(self:GetStyle("groupBodySection"), self:GetStyle("bodySection"))
    if errorText then
        bodySection:AddLine(errorText, self:GetStyle("groupDescription"), self:GetStyle("groupDescriptionError"))
    end
    bodySection:AddLine(bodyText, self:GetStyle("groupDescription"))
    self:AddSection(bodySection)
end

do
    local textRolesGeneralDescription = GetString(SI_GROUP_PREFERRED_ROLE_DESCRIPTION)

    function ZO_Tooltip:LayoutGroupRole(textTitle, textBody)
        self:LayoutGroupTooltip(textTitle, textBody)

        local section = self:AcquireSection(self:GetStyle("bodySection"))
        section:AddLine(textRolesGeneralDescription, self:GetStyle("bodyDescription"))
    
        self:AddSection(section)
    end
end