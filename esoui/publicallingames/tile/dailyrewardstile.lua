----
-- ZO_DailyRewardsTile
----

------
-- For order of instantiation to happen in the intended order the base class must be inherited before it's platform counterpart
-- (IMPLEMENTS OF THESE FUNCTIONS IN THIS CLASS WILL BE COMPETELY OVERRIDDEN BY PLATFORM SPECIFIC IMPLEMENTATIONS)
--    SetActionAvailable
--    SetActionText
--    SetActionCallback
------

------
-- This is used to track the claiming process. When a claim is requested an animation and 
-- a call to the server will both happen. Both must complete before the claim process is
-- considered complete. These states track which parts of the process have completed so that
-- it can be determined when OnClaimCompleted can be called
------

ZO_DailyRewardsTile = ZO_Object:MultiSubclass(ZO_ClaimTile, ZO_DailyRewards_TileInfo)

function ZO_DailyRewardsTile:New(...)
    return ZO_ClaimTile.New(self, ...)
end

function ZO_DailyRewardsTile:Initialize(control)
    ZO_ClaimTile.Initialize(self, control)

    local blastParticleSystem = ZO_BlastParticleSystem:New()
    blastParticleSystem:SetParticlesPerSecond(1000)
    blastParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(0.7, 1.2))
    blastParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(1000, 1500))
    blastParticleSystem:SetParticleParameter("DrawTier", DT_MEDIUM)
    blastParticleSystem:SetParticleParameter("DrawLayer", DL_CONTROLS)
    blastParticleSystem:SetParticleParameter("DrawLevel", 0)
    blastParticleSystem:SetParticleParameter("PrimeS", 0.2)
    blastParticleSystem:SetSound(SOUNDS.DAILY_LOGIN_REWARDS_CLAIM_FANFARE)
    blastParticleSystem:SetParentControl(control:GetNamedChild("ParticleContainer"))
    self.blastParticleSystem = blastParticleSystem
    
    local OnClaimRequested = function()
        self.blastParticleSystem:Start()
        ClaimCurrentDailyLoginReward()
    end

    self:SetClaimCallback(OnClaimRequested)

    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_UPDATED, function() self:RefreshLayout() end)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_CLAIMED, function() self:OnClaimResultReceived() end)
    control:RegisterForEvent(EVENT_NEW_DAILY_LOGIN_REWARD_AVAILABLE, function() self:RefreshLayout() end)
end

function ZO_DailyRewardsTile:PostInitialize()
    ZO_Tile.PostInitialize(self)

    self:SetActionSound(SOUNDS.DAILY_LOGIN_REWARDS_ACTION_CLAIM)
end

function ZO_DailyRewardsTile:OnControlShown()
    ZO_Tile.OnControlShown(self)
    self.control:SetHandler("OnUpdate", function(_, currentTime) self:OnCountDownLabelUpdate(currentTime) end)
end

function ZO_DailyRewardsTile:OnControlHidden()
    ZO_Tile.OnControlHidden(self)
    self.control:SetHandler("OnUpdate", nil)
end

function ZO_DailyRewardsTile:OnClaimResultReceived()
    self:RefreshLayout()
end

function ZO_DailyRewardsTile:OnCountDownLabelUpdate()
    if self.claimState == ZO_CLAIM_TILE_STATE.CLAIMED then
        self:RefreshHeaderText()
    end
end

function ZO_DailyRewardsTile:GetClaimedString()
    return GetString(SI_DAILY_LOGIN_REWARDS_TILE_VIEW_REWARDS)
end

function ZO_DailyRewardsTile:RefreshHeaderText()
    if self.claimState == ZO_CLAIM_TILE_STATE.UNCLAIMED then
        self:SetHeaderText(self:GetUnclaimedHeaderText())
    else
        self:SetHeaderText(self:GetClaimedHeaderText(self:ShouldUseSelectedHeaderColor()))
    end
end

function ZO_DailyRewardsTile:ShouldUseSelectedHeaderColor()
    assert(false) -- must be overridden in derived classes
end

function ZO_DailyRewardsTile:Reset()
    self.control:ClearAnchors()
end

function ZO_DailyRewardsTile:RefreshLayoutInternal()
    local data =
    {
        dailyRewardIndex = ZO_DAILYLOGINREWARDS_MANAGER:GetDailyLoginRewardIndex()
    }

    self:Layout(data)
end

function ZO_DailyRewardsTile:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = data

    local dailyRewardIndex = data.dailyRewardIndex
    if dailyRewardIndex and dailyRewardIndex == GetDailyLoginClaimableRewardIndex() then
        self:SetClaimState(ZO_CLAIM_TILE_STATE.UNCLAIMED)
        self:SetActionCallback(function() self:RequestClaim() end)
    else
        self:SetClaimState(ZO_CLAIM_TILE_STATE.CLAIMED)
        self:SetActionCallback(function()
                                   if ShowDailyLoginScene then -- called from the announcement panel (internal ingame)
                                       ShowDailyLoginScene()
                                   else -- called from the logout/quit dialog (ingame)
                                       ZO_Dialogs_ReleaseAllDialogs()
                                       ZO_DAILYLOGINREWARDS_MANAGER:ShowDailyLoginRewardsScene()
                                   end
                               end)
    end
    self:RefreshHeaderText()
    self:RefreshActionText()
    self:SetActionAvailable(ZO_DAILYLOGINREWARDS_MANAGER:HasClaimableRewardInMonth())

    local title, background = self:GetTitleAndBackground(dailyRewardIndex)
    self:SetTitle(title)
    self:SetBackground(background)
end