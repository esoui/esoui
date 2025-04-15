ZO_RETURNING_PLAYER_REWARD_TYPE =
{
    DAILY_REWARD = "DailyReward",
    PRIMARY_REWARD = "PrimaryReward",
}

local ReturningPlayer_Manager = ZO_InitializingCallbackObject:Subclass()

function ReturningPlayer_Manager:Initialize()
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("ActivityProgressUpdated", ZO_GetCallbackForwardingFunction(self, self.OnPromotionalActivityProgressUpdated))
    EVENT_MANAGER:RegisterForEvent("ReturningPlayer_Manager", EVENT_RETURNING_PLAYER_DAILY_LOGIN_REWARD_CLAIMED, ZO_GetEventForwardingFunction(self, self.OnReturningPlayerDailyRewardClaimed))
end

function ReturningPlayer_Manager:OnPromotionalActivityProgressUpdated(activityData, ...)
    if not IsReturningPlayer() or not activityData:IsComplete() then
        return
    end

    -- don't pop up the rewards screen if the player completes the intro activity in the tutorial
    if not IsInReturningPlayerIntroWorld() then
        return
    end

    local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
    if componentType ~= PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
        return
    end

    if activityData:MatchesCampaignKey(campaignKey) and activityData:GetActivityIndex() == index then
        self.isCampaignCompletedButUnseen = true
        SYSTEMS:ShowScene("returningPlayerRewards")
    end
end

function ReturningPlayer_Manager:IsCampaignCompletedButUnseen()
    return self.isCampaignCompletedButUnseen
end

function ReturningPlayer_Manager:OnReturningPlayerDailyRewardClaimed()
    self:FireCallbacks("DailyRewardClaimed")
end

function ReturningPlayer_Manager:GetIntroCampaignRewardableData()
    local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
    local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
    if campaignData then
        local rewardableData = campaignData:GetPromotionalEventRewardableDataByTypeAndIndex(componentType, index)
        return rewardableData
    end
    return nil
end

function ReturningPlayer_Manager:GetIntroCampaignRewardData()
    local rewardableData = self:GetIntroCampaignRewardableData()
    if rewardableData then
        return rewardableData:GetRewardData()
    end
    return nil
end

function ReturningPlayer_Manager:GetIntroCampaignDisplayName()
    local campaignDisplayName = GetReturningPlayerCampaignDisplayName()
    return campaignDisplayName
end

function ReturningPlayer_Manager:GetColorizedIntroCampaignDisplayName()
    local campaignDisplayName = self:GetIntroCampaignDisplayName()
    campaignDisplayName = ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:Colorize(campaignDisplayName)
    return campaignDisplayName
end

function ReturningPlayer_Manager:GetIntroGameplayDisplayName()
    local gameplayDisplayName = GetReturningPlayerIntroGameplayDisplayName()
    return gameplayDisplayName
end

function ReturningPlayer_Manager:GetColorizedIntroGameplayDisplayName()
    local gameplayDisplayName = self:GetIntroGameplayDisplayName()
    gameplayDisplayName = ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:Colorize(gameplayDisplayName)
    return gameplayDisplayName
end

function ReturningPlayer_Manager:GetCampaignRemainingTimeDisplayText()
    local campaignKey, componentType, index = GetReturningPlayerIntroGameplayData()
    local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
    if campaignData then
        local secondsRemaining = campaignData:GetSecondsRemaining()
        local timeText = ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE)
        return zo_strformat(SI_RETURNING_PLAYER_SUBHEADER_TIME_FORMATTER, ZO_SELECTED_TEXT:Colorize(timeText))
    end
end

function ReturningPlayer_Manager:GetCampaignRewardsDescriptionText()
    local promotionalEventNameText = PROMOTIONAL_EVENT_MANAGER:GetPromotionalEventsColorizedDisplayName()
    if self:IsCampaignCompletedButUnseen() then
        self.isCampaignCompletedButUnseen = nil
        return zo_strformat(SI_RETURNING_PLAYER_REWARDS_COMPLETED, promotionalEventNameText)
    else
        return zo_strformat(SI_RETURNING_PLAYER_REWARDS_GENERAL, promotionalEventNameText)
    end
end

function ReturningPlayer_Manager:GoToPromotionalEvents()
    local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(1)
    local DONT_SCROLL_TO_REWARD = false
    PROMOTIONAL_EVENT_MANAGER:ShowPromotionalEventScene(DONT_SCROLL_TO_REWARD, campaignData)
end

function ReturningPlayer_Manager:IsIntroCampaignComplete()
    local rewardableData = self:GetIntroCampaignRewardableData()
    if rewardableData then
        local isComplete = rewardableData:CanClaimReward() or rewardableData:IsRewardClaimed()
        return isComplete
    end
    return true
end

function ReturningPlayer_Manager:ShowReturningPlayerAnnouncementScreen()
    if self:IsIntroCampaignComplete() or IsActiveWorldStarterWorld() then
        SYSTEMS:ShowScene("returningPlayerRewards")
    else
        SYSTEMS:ShowScene("returningPlayerIntro")
    end
end

function ReturningPlayer_Manager:IsShowingReturningPlayerScene()
    local introScene = SYSTEMS:GetRootScene("returningPlayerIntro")
    local sceneGroup = introScene:GetSceneGroup()
    return sceneGroup:IsShowing()
end

function ReturningPlayer_Manager:GetDailyLoginRewards()
    local numDailyLoginRewards = GetNumReturningPlayerDailyLoginRewards()
    local numClaimedRewards = GetNumReturningPlayerDailyLoginRewardsClaimed()
    local rewards = {}
    for rewardIndex = 1, numDailyLoginRewards do
        local rewardId, quantity = GetReturningPlayerDailyLoginRewardInfo(rewardIndex)
        local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, quantity)
        if rewardData then
            local rewardEntry = ZO_EntryData:New(rewardData)
            rewardEntry.type = ZO_RETURNING_PLAYER_REWARD_TYPE.DAILY_REWARD
            rewardEntry.index = rewardIndex
            rewardEntry.claimed = rewardIndex <= numClaimedRewards
            rewardEntry.narrationText = zo_strformat(SI_RETURNING_PLAYER_DAILY_LOGIN_DAY_LABEL, rewardIndex)
            table.insert(rewards, rewardEntry)
        end
    end

    return rewards
end

function ReturningPlayer_Manager:GetPrimaryRewards()
    local numPrimaryRewards = GetNumReturningPlayerPrimaryRewards()
    local rewards = {}
    for rewardIndex = 1, numPrimaryRewards do
        local campaignKey, componentType, index = GetReturningPlayerPrimaryRewardData(rewardIndex)
        local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
        if campaignData then
            local rewardableData = campaignData:GetPromotionalEventRewardableDataByTypeAndIndex(componentType, index)
            if rewardableData then
                local rewardEntry = ZO_EntryData:New(rewardableData:GetRewardData())
                rewardEntry.type = ZO_RETURNING_PLAYER_REWARD_TYPE.PRIMARY_REWARD
                rewardEntry.claimed = rewardableData:IsRewardClaimed()
                table.insert(rewards, rewardEntry)
            end
        end
    end

    return rewards
end

function ReturningPlayer_Manager:CanJumpToIntroGameplay()
    return GetExpectedJumpToReturningPlayerIntroGameplayResult() == RETURNING_PLAYER_INSTANCE_JUMP_RESULT_SUCCESS
end

RETURNING_PLAYER_MANAGER = ReturningPlayer_Manager:New()

ESO_Dialogs["CONFIRM_LEAVE_RETURNING_PLAYER_INTRO"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_RETURNING_PLAYER_CONFIRM_LEAVE_INTRO_DIALOG_HEADER,
    },
    mainText =
    {
        text = function()
            local activityName = GetReturningPlayerIntroGameplayDisplayName()
            local colorizedActivityName = ZO_WHITE:Colorize(activityName)

            local campaignDisplayName = RETURNING_PLAYER_MANAGER:GetColorizedIntroCampaignDisplayName()
            return zo_strformat(SI_RETURNING_PLAYER_CONFIRM_LEAVE_INTRO_DIALOG_BODY, colorizedActivityName, campaignDisplayName)
        end,
    },
    buttons =
    {
        {
            text = SI_RETURNING_PLAYER_CONFIRM_LEAVE_INTRO_DIALOG_CONFIRM_KEYBIND,
            callback = function(dialog)
                MarkReturningPlayerLeaveIntroPromptShown()
                SYSTEMS:ShowScene("returningPlayerRewards")
            end
        },
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_RETURNING_PLAYER_CONFIRM_LEAVE_INTRO_DIALOG_BACK_KEYBIND,
        },
    }
}
