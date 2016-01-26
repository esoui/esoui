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
    local textTitle = GetString(SI_GAMEPAD_GROUP_FIND_MEMBERS)
    local textBody = GetString(SI_GAMEPAD_GROUP_FINDER_TOOLTIP_BODY)
    local textQueueStatus = GetString(SI_LFG_QUEUE_STATUS)
    local textQueued = GetString(SI_LFG_QUEUE_STATUS_QUEUED)
    local textNotQueued = GetString(SI_LFG_QUEUE_STATUS_NOT_QUEUED)
    local textEstimated = GetString(SI_GAMEPAD_LFG_QUEUE_ESTIMATED)
    local textActual = GetString(SI_GAMEPAD_LFG_QUEUE_ACTUAL)
    
    function ZO_Tooltip:LayoutGroupFinder()
        self:LayoutGroupTooltip(textTitle, textBody)
    
        local isSearching = IsCurrentlySearchingForGroup()
    
        local queueSection = self:AcquireSection(self:GetStyle("bodySection"))
        local statValuePair
    
        --Queue status
        statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
        statValuePair:SetStat(textQueueStatus, self:GetStyle("statValuePairStat"))
        statValuePair:SetValue(isSearching and textQueued or textNotQueued, self:GetStyle("statValuePairValue"))
        queueSection:AddStatValuePair(statValuePair)
    
        if isSearching then
            local searchStartTimeMs, searchEstimatedCompletionTimeMs = GetLFGSearchTimes()

            --Estimated time
            local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(searchEstimatedCompletionTimeMs)

            statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
            statValuePair:SetStat(textEstimated, self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(textEstimatedTime, self:GetStyle("statValuePairValue"))
            queueSection:AddStatValuePair(statValuePair)
    
            --Actual time
            local timeSinceSearchStartMs = GetFrameTimeMilliseconds() - searchStartTimeMs
            local textStartTime = ZO_FormatTimeMilliseconds(timeSinceSearchStartMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
    
            statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
            statValuePair:SetStat(textActual, self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(textStartTime, self:GetStyle("statValuePairValue"))
            queueSection:AddStatValuePair(statValuePair)
        end
    
        self:AddSection(queueSection)
    end
end

do
    local textRolesGeneralDescription = GetString(SI_GAMEPAD_GROUP_LIST_PANEL_PREFERRED_ROLE_DESCRIPTION)

    function ZO_Tooltip:LayoutGroupRole(textTitle, textBody)
        self:LayoutGroupTooltip(textTitle, textBody)

        local section = self:AcquireSection(self:GetStyle("bodySection"))
        section:AddLine(textRolesGeneralDescription, self:GetStyle("bodyDescription"))
    
        self:AddSection(section)
    end
end