function ZO_Tooltip:LayoutDefaultAccessTooltip(defaultAccess)
    local headerSection = self:AcquireSection(self:GetStyle("title"))
    headerSection:AddLine(GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_DEFAULT_ACCESS_TEXT))
    self:AddSection(headerSection)

    local bodySection = self:AcquireSection(self:GetStyle("attributeBody"))
    bodySection:AddLine(GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_DEFAULT_ACCESS_TOOLTIP_TEXT))
    self:AddSection(bodySection)

    local defaultVisitorAccessTitleSection = self:AcquireSection(self:GetStyle("defaultAccessTopSection"))
    local defaultVisitorAccessBodySection = self:AcquireSection(self:GetStyle("defaultAccessBody"))

    defaultVisitorAccessTitleSection:AddLine(GetString("SI_HOUSEPERMISSIONDEFAULTACCESSSETTING",  defaultAccess), self:GetStyle("defaultAccessTitle"))
    defaultVisitorAccessBodySection:AddLine(GetString("SI_HOUSING_PERMISSIONS_DEFAULT_ACCESS_DESCRIPTION", defaultAccess))

    self:AddSection(defaultVisitorAccessTitleSection)
    self:AddSection(defaultVisitorAccessBodySection)
end