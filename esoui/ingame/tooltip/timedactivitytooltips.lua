function ZO_Tooltip:LayoutTimedActivityTooltip(activityIndex)
    local activityData = ZO_TimedActivityData:New(activityIndex)
    if activityData then
        local topSection = self:AcquireSection(self:GetStyle("topSection"))
        topSection:AddLine(GetString("SI_TIMEDACTIVITYTYPE", activityData:GetType()))
        self:AddSection(topSection)

        self:AddLine(activityData:GetName(), self:GetStyle("title"))

        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        bodySection:AddLine(ZO_NORMAL_TEXT:Colorize(activityData:GetDescription()), self:GetStyle("bodyDescription"))
        self:AddSection(bodySection)
    end
end