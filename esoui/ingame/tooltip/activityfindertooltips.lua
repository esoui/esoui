function ZO_Tooltip:LayoutZoneStoryActivityCompletion(zoneData, completionType)
    local headerSection = self:AcquireSection(self:GetStyle("topSection"))
    headerSection:AddLine(GetString("SI_ZONECOMPLETIONTYPE", completionType), self:GetStyle("title"))
    headerSection:AddLine(zoneData.name)
    self:AddSection(headerSection)

    local statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    statValuePair:SetStat(GetString("SI_ZONECOMPLETIONTYPE_PROGRESSHEADER", completionType), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(ZO_ZoneStories_Manager.GetActivityCompletionProgressText(zoneData.id, completionType), self:GetStyle("statValuePairValue"))
    self:AddStatValuePair(statValuePair)

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(GetString("SI_ZONECOMPLETIONTYPE_DESCRIPTION", completionType), self:GetStyle("flavorText"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutZoneStoryActivityCompletionTypeList(zoneData, completionType)
    -- Title
    local titleTextSection = self:AcquireSection(self:GetStyle("topSection"))
    titleTextSection:AddLine(zo_strformat(SI_ZONE_STORY_LIST_TOOLTIP_TITLE_FORMATTER, zoneData.name, GetString("SI_ZONECOMPLETIONTYPE", completionType)), self:GetStyle("title"))
    self:AddSection(titleTextSection)

    -- Checkboxes
    local numUnblockedActivities, blockingBranchErrorStringId = select(3, ZO_ZoneStories_Manager.GetActivityCompletionProgressValues(zoneData.id, completionType))
    local activityListSection = self:AcquireSection(self:GetStyle("achievementCriteriaSection"))

    for i = 1, numUnblockedActivities do
        local name = GetZoneStoryActivityNameByActivityIndex(zoneData.id, completionType, i)
        local isComplete = IsZoneStoryActivityComplete(zoneData.id, completionType, i)
        activityListSection:AddSection(self:GetCheckboxSection(zo_strformat(SI_ZONE_STORY_LIST_TOOLTIP_ACTIVITY_NAME_FORMATTER, name), isComplete))
    end

    self:AddSection(activityListSection)

    if blockingBranchErrorStringId ~= 0 then
        local blockingBranchRequirementSection = self:AcquireSection(self:GetStyle("bodySection"))
        local errorStringText = GetErrorString(blockingBranchErrorStringId)
        blockingBranchRequirementSection:AddLine(errorStringText, self:GetStyle("flavorText"))
        self:AddSection(blockingBranchRequirementSection)
    end
end