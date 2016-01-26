function ZO_Tooltip:LayoutGuildKioskInfo(title, body)
    self:AddLine(title, self:GetStyle("title"))

    local bodyStyle = self:GetStyle("bodySection")

    local descriptionSection = self:AcquireSection(bodyStyle)

    descriptionSection:AddLine(body, self:GetStyle("bodyDescription"))
    self:AddSection(descriptionSection)   
end