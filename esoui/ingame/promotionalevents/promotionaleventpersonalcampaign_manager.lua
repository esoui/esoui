ZO_PromotionalEventPersonalCampaign_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_PromotionalEventPersonalCampaign_Manager:Initialize()
    local NO_ARG = nil
    local PRIORITY = 1
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", ZO_GetCallbackForwardingFunction(self, self.RefreshPersonalCampaignType), NO_ARG, PRIORITY)
    self:RefreshPersonalCampaignType()
end

function ZO_PromotionalEventPersonalCampaign_Manager:RefreshPersonalCampaignType()
    -- If we add another personal campaign type, we'll need to determine if it should follow the same kinds of rules or go down a different route
    -- So for now this is still somewhat manual instead of fully dynamic
    internalassert(PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_MAX_VALUE == 1, "Determine behavior for new personal campaign type")

    local personalCampaignType = nil
    if IsLowLevelPlayer() then
        personalCampaignType = PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_LOW_LEVEL_PLAYER
    elseif IsReturningPlayer() then
        personalCampaignType = PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_RETURNING_PLAYER
    end

    if self.personalCampaignType ~= personalCampaignType then
        self.personalCampaignType = personalCampaignType
        self:FireCallbacks("PersonalCampaignTypeChanged", personalCampaignType)
    end
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetPersonalCampaignType()
    return self.personalCampaignType
end

function ZO_PromotionalEventPersonalCampaign_Manager:IsReturningPlayer()
    return self.personalCampaignType == PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_RETURNING_PLAYER
end

function ZO_PromotionalEventPersonalCampaign_Manager:IsLowLevelPlayer()
    return self.personalCampaignType  == PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_LOW_LEVEL_PLAYER
end

function ZO_PromotionalEventPersonalCampaign_Manager:HasPersonalCampaign()
    return self.personalCampaignType
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetIntroGameplayExperienceData()
    if not self.personalCampaignType then
        return nil
    end

    local campaignKey, componentType, index = GetIntroGameplayExperienceData(self.personalCampaignType)
    return campaignKey, componentType, index
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetIntroCampaignRewardableData()
    local campaignKey, componentType, index = self:GetIntroGameplayExperienceData()
    local campaignData = campaignKey and PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey) or nil
    if campaignData then
        local rewardableData = campaignData:GetPromotionalEventRewardableDataByTypeAndIndex(componentType, index)
        return rewardableData
    end
    return nil
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetIntroCampaignRewardData()
    local rewardableData = self:GetIntroCampaignRewardableData()
    if rewardableData then
        return rewardableData:GetRewardData()
    end
    return nil
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetCampaignDisplayName()
    if not self.personalCampaignType then
        return nil
    end

    local campaignDisplayName = GetPromotionalEventPersonalCampaignDisplayName(self.personalCampaignType)
    return campaignDisplayName
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetColorizedCampaignDisplayName()
    local campaignDisplayName = self:GetCampaignDisplayName()
    campaignDisplayName = ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:Colorize(campaignDisplayName)
    return campaignDisplayName
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetCampaignDescription()
    if not self.personalCampaignType then
        return nil
    end

    local campaignDescription = GetPromotionalEventPersonalCampaignDescription(self.personalCampaignType)
    return campaignDescription
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetIntroGameplayDisplayName()
    local gameplayDisplayName = GetIntroGameplayExperienceDisplayName()
    return gameplayDisplayName
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetColorizedIntroGameplayDisplayName()
    local gameplayDisplayName = self:GetIntroGameplayDisplayName()
    gameplayDisplayName = ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:Colorize(gameplayDisplayName)
    return gameplayDisplayName
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetWhiteIntroGameplayDisplayName()
    local gameplayDisplayName = self:GetIntroGameplayDisplayName()
    gameplayDisplayName = ZO_WHITE:Colorize(gameplayDisplayName)
    return gameplayDisplayName
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetCampaignRemainingTimeDisplayText()
    local campaignKey, componentType, index = self:GetIntroGameplayExperienceData()
    local campaignData = campaignKey and PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey) or nil
    if campaignData then
        local secondsRemaining = campaignData:GetSecondsRemaining()
        local timeText = ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE)
        return zo_strformat(SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_SUBHEADER_TIME_FORMATTER, ZO_SELECTED_TEXT:Colorize(timeText))
    end
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetCampaignRewardsDescriptionText()
    local promotionalEventNameText = PROMOTIONAL_EVENT_MANAGER:GetPromotionalEventsColorizedDisplayName()
    return zo_strformat(SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_REWARDS_GENERAL, promotionalEventNameText)
end

function ZO_PromotionalEventPersonalCampaign_Manager:GoToPromotionalEvents()
    local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(1)
    local DONT_SCROLL_TO_REWARD = false
    PROMOTIONAL_EVENT_MANAGER:ShowPromotionalEventScene(DONT_SCROLL_TO_REWARD, campaignData)
end

function ZO_PromotionalEventPersonalCampaign_Manager:IsIntroCampaignComplete()
    local rewardableData = self:GetIntroCampaignRewardableData()
    if rewardableData then
        local isComplete = rewardableData:CanClaimReward() or rewardableData:IsRewardClaimed()
        return isComplete
    end
    return true
end

function ZO_PromotionalEventPersonalCampaign_Manager:GetPrimaryRewards()
    if not self.personalCampaignType then
        return nil
    end

    local numPrimaryRewards = GetNumPromotionalEventPersonalCampaignPrimaryRewards(self.personalCampaignType)
    local rewards = {}
    for rewardIndex = 1, numPrimaryRewards do
        local campaignKey, componentType, index = GetPromotionalEventPersonalCampaignPrimaryRewardData(self.personalCampaignType, rewardIndex)
        local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
        if campaignData then
            local rewardableData = campaignData:GetPromotionalEventRewardableDataByTypeAndIndex(componentType, index)
            if rewardableData then
                local rewardEntry = ZO_EntryData:New(rewardableData:GetRewardData())
                rewardEntry.claimed = rewardableData:IsRewardClaimed()
                table.insert(rewards, rewardEntry)
            end
        end
    end

    return rewards
end

function ZO_PromotionalEventPersonalCampaign_Manager:CanJumpToIntroGameplay()
    return GetExpectedJumpToIntroGameplayExperienceResult() == INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_SUCCESS
end

function ZO_PromotionalEventPersonalCampaign_Manager:HasClaimedAllPrimaryRewards()
    if not self.personalCampaignType then
        return false
    end

    local numPrimaryRewards = GetNumPromotionalEventPersonalCampaignPrimaryRewards(self.personalCampaignType)
    for rewardIndex = 1, numPrimaryRewards do
        local campaignKey, componentType, index = GetPromotionalEventPersonalCampaignPrimaryRewardData(self.personalCampaignType, rewardIndex)
        local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
        if campaignData then
            local rewardableData = campaignData:GetPromotionalEventRewardableDataByTypeAndIndex(componentType, index)
            if rewardableData then
                local claimed = rewardableData:IsRewardClaimed()
                if not claimed then
                    return false
                end
            end
        end
    end

    return true
end

function ZO_PromotionalEventPersonalCampaign_Manager:ShouldShowAnnouncementEntry()
    return LOW_LEVEL_PLAYER_MANAGER:ShouldShowLowLevelPlayerAnnouncementEntry() or RETURNING_PLAYER_MANAGER:ShouldShowReturningPlayerAnnouncementEntry()
end

function ZO_PromotionalEventPersonalCampaign_Manager:ShowAnnouncementScreen()
    if self:IsLowLevelPlayer() then
        LOW_LEVEL_PLAYER_MANAGER:ShowLowLevelPlayerAnnouncementScreen()
    elseif self:IsReturningPlayer() then
        RETURNING_PLAYER_MANAGER:ShowReturningPlayerAnnouncementScreen()
    end
end

PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER = ZO_PromotionalEventPersonalCampaign_Manager:New()

-- This dialog will be used for both Returning Player and New Player,
-- specifically when the New Player hasn't finished the first activity (ostensibly denoting them as a sort of "returning player")
ESO_Dialogs["CONFIRM_LEAVE_PERSONAL_CAMPAIGN_INTRO"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_CONFIRM_LEAVE_INTRO_DIALOG_HEADER,
    },
    mainText =
    {
        -- Expected args are:
        --      colorized intro gameplay display name
        --      colorized intro campaign display name
        text = SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_CONFIRM_LEAVE_INTRO_DIALOG_BODY,
    },
    buttons =
    {
        {
            text = SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_CONFIRM_LEAVE_INTRO_DIALOG_CONFIRM_KEYBIND,
            callback = function(dialog)
                MarkPromotionalEventPersonalCampaignLeaveIntroPromptShown()
                dialog.data.confirmCallback()
            end
        },
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_CONFIRM_LEAVE_INTRO_DIALOG_BACK_KEYBIND,
            callback = function(dialog)
                dialog.data.declineCallback()
            end
        },
    }
}