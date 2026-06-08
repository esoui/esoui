ZO_RETURNING_PLAYER_REWARD_TYPE =
{
    DAILY_REWARD = "DailyReward",
    PRIMARY_REWARD = "PrimaryReward",
}

local ReturningPlayer_Manager = ZO_InitializingCallbackObject:Subclass()

function ReturningPlayer_Manager:Initialize()
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("ActivityProgressUpdated", ZO_GetCallbackForwardingFunction(self, self.OnPromotionalActivityProgressUpdated))
    EVENT_MANAGER:RegisterForEvent("ReturningPlayer_Manager", EVENT_RETURNING_PLAYER_DAILY_LOGIN_REWARD_CLAIMED, ZO_GetEventForwardingFunction(self, self.OnReturningPlayerDailyRewardClaimed))

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            EVENT_MANAGER:UnregisterForEvent("ReturningPlayer_Manager", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ReturningPlayer_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ReturningPlayer_Manager:SetupSavedVars()
    local defaults =
    {
        lastSeenRewardsTimestamp = 0,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "ReturningPlayer_Manager", defaults)
end

function ReturningPlayer_Manager:OnPromotionalActivityProgressUpdated(activityData, ...)
    if not PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsReturningPlayer() or not activityData:IsComplete() then
        return
    end

    -- don't pop up the rewards screen if the player completes the intro activity in the tutorial
    if not IsInIntroGameplayExperienceWorld() then
        return
    end

    local campaignKey, componentType, index = PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetIntroGameplayExperienceData()
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

function ReturningPlayer_Manager:GetCampaignRewardsDescriptionText()
    if self:IsCampaignCompletedButUnseen() then
        self.isCampaignCompletedButUnseen = nil
        local promotionalEventNameText = PROMOTIONAL_EVENT_MANAGER:GetPromotionalEventsColorizedDisplayName()
        return zo_strformat(SI_RETURNING_PLAYER_REWARDS_COMPLETED, promotionalEventNameText)
    else
        return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetCampaignRewardsDescriptionText()
    end
end

function ReturningPlayer_Manager:ShowReturningPlayerAnnouncementScreen()
    if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsIntroCampaignComplete() or IsActiveWorldStarterWorld() then
        SYSTEMS:ShowScene("returningPlayerRewards")
    else
        SYSTEMS:ShowScene("returningPlayerIntro")
    end
end

function ReturningPlayer_Manager:IsShowingReturningPlayerScene()
    return SYSTEMS:IsShowing("returningPlayerIntro") or SYSTEMS:IsShowing("returningPlayerRewards")
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

function ReturningPlayer_Manager:AreAnyDailyLoginRewardsUnclaimed()
    local numDailyLoginRewards = GetNumReturningPlayerDailyLoginRewards()
    local numClaimedRewards = GetNumReturningPlayerDailyLoginRewardsClaimed()
    return numClaimedRewards < numDailyLoginRewards
end

function ReturningPlayer_Manager:HasClaimableDailyReward()
    return GetReturningPlayerDailyLoginClaimableRewardIndex() ~= nil
end

function ReturningPlayer_Manager:HasClaimedAllPrimaryAndDailyRewards()
    local numDailyLoginRewards = GetNumReturningPlayerDailyLoginRewards()
    local numClaimedRewards = GetNumReturningPlayerDailyLoginRewardsClaimed()

    if numClaimedRewards < numDailyLoginRewards then
        return false
    end

    return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:HasClaimedAllPrimaryRewards()
end

function ReturningPlayer_Manager:ShouldShowReturningPlayerAnnouncement()
    if not PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsReturningPlayer() or HasShownPromotionalEventPersonalCampaignAnnouncement() then
        return false
    end

    -- Always show if we haven't completed the intro
    if not PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsIntroCampaignComplete() then
        return true
    end

    -- Don't show if there aren't any unclaimed rewards
    if self:HasClaimedAllPrimaryAndDailyRewards() then
        return false
    end

    return true
end

function ReturningPlayer_Manager:ShouldShowReturningPlayerAnnouncementEntry()
    return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsReturningPlayer() and not self:HasClaimedAllPrimaryAndDailyRewards()
end

function ReturningPlayer_Manager:MarkRewardsAsSeen()
    self.savedVars.lastSeenRewardsTimestamp = GetTimeStamp()
end

function ReturningPlayer_Manager:GetLastTimeRewardsWereSeen()
    return self.savedVars.lastSeenRewardsTimestamp
end

RETURNING_PLAYER_MANAGER = ReturningPlayer_Manager:New()
