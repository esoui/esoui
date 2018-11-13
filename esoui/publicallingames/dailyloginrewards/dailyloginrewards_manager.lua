--
--[[ DailyLoginRewards_Manager ]]--
--

local DailyLoginRewards_Manager = ZO_Object:Subclass()

function DailyLoginRewards_Manager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function DailyLoginRewards_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("DailyLoginRewardsManager", EVENT_SHOW_DAILY_LOGIN_REWARDS_SCENE, function() self:ShowDailyLoginRewardsScene() end)
end

function DailyLoginRewards_Manager:ShowDailyLoginRewardsScene()
    if IsInGamepadPreferredMode() then
        SYSTEMS:GetObject("mainMenu"):ShowDailyLoginRewardsEntry()
    else
        SYSTEMS:GetObject("mainMenu"):ShowSceneGroup("marketSceneGroup", "dailyLoginRewards")
    end
end

function DailyLoginRewards_Manager:GetDailyLoginRewardIndex()
	local dailyRewardIndex = GetDailyLoginClaimableRewardIndex()
    -- Daily reward has been claimed, get index for tomorrows reward if applicable
    if not dailyRewardIndex and self:HasClaimableRewardInMonth() then
        dailyRewardIndex = self:GetNextPotentialReward()
    end
	
	return dailyRewardIndex
end

function DailyLoginRewards_Manager:GetNextPotentialReward()
    local nextPotentialRewardIndex = GetDailyLoginNumRewardsClaimedInMonth() + 1
    if nextPotentialRewardIndex <= GetNumRewardsInCurrentDailyLoginMonth() then
        return nextPotentialRewardIndex
    end

    return nil
end

function DailyLoginRewards_Manager:HasClaimableRewardInMonth()
    local hasRewardsLeftNotOnLastDay = GetDailyLoginNumRewardsClaimedInMonth() < GetNumRewardsInCurrentDailyLoginMonth() and not self:IsLastDay()
    local hasReward = GetDailyLoginClaimableRewardIndex() ~= nil
    return hasRewardsLeftNotOnLastDay or hasReward
end

function DailyLoginRewards_Manager:IsLastDay()
    return GetTimeUntilNextDailyLoginMonthS() <= ZO_ONE_DAY_IN_SECONDS
end

function DailyLoginRewards_Manager:IsDailyRewardsLocked()
    local numRewards = GetNumRewardsInCurrentDailyLoginMonth()
    return numRewards == 0
end

ZO_DAILYLOGINREWARDS_MANAGER = DailyLoginRewards_Manager:New()