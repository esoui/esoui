function ZO_Tooltip:LayoutNotification(note, messageText)
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))

    if messageText then
        bodySection:AddLine(messageText, self:GetStyle("bodyDescription"))
    end

    if note then
        bodySection:AddLine(note, self:GetStyle("notificationNote"))
    end

    self:AddSection(bodySection)
end