function ZO_Tooltip:LayoutTimedActivityTooltip(activityIndex)
    local activityData = TIMED_ACTIVITIES_MANAGER:GetActivityDataByIndex(activityIndex)
    if activityData then
        local topSection = self:AcquireSection(self:GetStyle("topSection"))
        topSection:AddLine(GetString("SI_TIMEDACTIVITYTYPE", activityData:GetType()))
        self:AddSection(topSection)

        self:AddLine(activityData:GetName(), self:GetStyle("title"))

        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        bodySection:AddLine(ZO_NORMAL_TEXT:Colorize(activityData:GetDescription()), self:GetStyle("bodyDescription"))
        self:AddSection(bodySection)

        local rewardsSection = self:AcquireSection(self:GetStyle("bodySection"))
        local rewardList = activityData:GetRewardList()
        rewardsSection:AddLine(GetString(SI_TIMED_ACTIVITIES_REWARD_HEADER), self:GetStyle("timedActivityRewardHeader"))
        for _, rewardData in ipairs(rewardList) do
            rewardsSection:AddLine(zo_iconTextFormat(rewardData:GetGamepadIcon(), "100%", "100%", rewardData:GetFormattedNameWithStackGamepad()), self:GetStyle("timedActivityReward"))
        end
        self:AddSection(rewardsSection)

        local function GetProgressNarration()
            if activityData:IsCompleted() then
                return GetString(SI_GAMEPAD_TIMED_ACTIVTY_COMPLETED_NARRATION)
            else
                local maxProgress = activityData:GetMaxProgress()
                local progress = activityData:GetProgress()
                return zo_strformat(SI_SCREEN_NARRATION_PROGRESS_BAR_FRACTION_FORMATTER, progress, maxProgress)
            end
        end
        self:AddNarrationLine(GetProgressNarration)
    end
end