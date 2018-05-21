----
-- ZO_DailyRewardsLogoutTile
----

ZO_DailyRewardsLogoutTile = ZO_Object:MultiSubclass(ZO_ActionTile, ZO_DailyRewards_TileInfo)

function ZO_DailyRewardsLogoutTile:New(...)
    return ZO_ActionTile.New(self, ...)
end

function ZO_DailyRewardsLogoutTile:Initialize(control)
    ZO_ActionTile.Initialize(self, control)

    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_UPDATED, function() self:RefreshLayout() end)
    control:RegisterForEvent(EVENT_NEW_DAILY_LOGIN_REWARD_AVAILABLE, function() self:RefreshLayout() end)
end

function ZO_DailyRewardsLogoutTile:PostInitialize()
    ZO_ActionTile.PostInitialize(self, control)

    self:SetActionCallback(function() self:ViewReward() end)
    self:SetActionText(GetString(SI_DAILY_LOGIN_REWARDS_TILE_VIEW_REWARDS))
end

function ZO_DailyRewardsLogoutTile:OnControlShown()
    ZO_Tile.OnControlShown(self)
    self.control:SetHandler("OnUpdate", function(_, currentTimeS) self:OnCountDownLabelUpdate(currentTimeS) end)
end

function ZO_DailyRewardsLogoutTile:OnControlHidden()
    ZO_Tile.OnControlHidden(self)
    self.control:SetHandler("OnUpdate", nil)
end

function ZO_DailyRewardsLogoutTile:OnCountDownLabelUpdate()
    -- if action is not available, it means we are waiting for the next daily reward
    if not self:IsActionAvailable() then
        self:RefreshHeaderText()
    end
end

function ZO_DailyRewardsLogoutTile:RefreshLayoutInternal()
    local dailyRewardIndex = ZO_DAILYLOGINREWARDS_MANAGER:GetDailyLoginRewardIndex()
    self:Layout(dailyRewardIndex)
end

function ZO_DailyRewardsLogoutTile:RefreshHeaderText()
    if GetDailyLoginClaimableRewardIndex() then
        self:SetHeaderText(self:GetUnclaimedHeaderText())
    else
        self:SetHeaderText(self:GetClaimedHeaderText())
    end
end

function ZO_DailyRewardsLogoutTile:Layout(dailyRewardIndex)
    ZO_Tile.Layout(self, dailyRewardIndex)

	local showingCurrentReward = dailyRewardIndex == GetDailyLoginClaimableRewardIndex()
    self:SetActionAvailable(showingCurrentReward)
	
    self:RefreshHeaderText()

    local title, background = self:GetTitleAndBackground(dailyRewardIndex)
    self:SetTitle(title)
    self:SetBackground(background)
end

function ZO_DailyRewardsLogoutTile:ViewReward()
    ZO_Dialogs_ReleaseAllDialogs()
    ZO_DAILYLOGINREWARDS_MANAGER:ShowDailyLoginRewardsScene()
end