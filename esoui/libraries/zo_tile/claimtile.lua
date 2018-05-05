----
-- ZO_ClaimTile
----

------
-- For order of instantiation to happen in the intended order the base class must be inherited before it's platform counterpart
-- (IMPLEMENTS OF THESE FUNCTIONS IN THIS CLASS WILL BE COMPETELY OVERRIDDEN BY PLATFORM SPECIFIC IMPLEMENTATIONS)
--    SetActionAvailable
--    SetActionText
--    SetActionCallback
------

ZO_ClaimTile = ZO_ActionTile:Subclass()

ZO_CLAIM_TILE_STATE = {
    UNCLAIMED = 1,
    CLAIMED = 2
}

function ZO_ClaimTile:New(...)
    return ZO_ActionTile.New(self, ...)
end

function ZO_ClaimTile:Initialize(control)
    ZO_ActionTile.Initialize(self, control)

    -- Platform specific implementation
    self:SetActionCallback(function() self:RequestClaim() end)
end

function ZO_ClaimTile:PostInitialize()
    ZO_ActionTile.PostInitialize(self)

    self:RefreshHeaderText()
    self:RefreshActionText()
end

function ZO_ClaimTile:RefreshHeaderText()
    -- To be overridden  
end

function ZO_ClaimTile:RefreshActionText()
    local locString
    if self.claimState == ZO_CLAIM_TILE_STATE.UNCLAIMED then
        locString = self:GetUnclaimedString()
    else
        locString = self:GetClaimedString()
    end

    -- Platform specific implementation
    self:SetActionText(locString)
end

function ZO_ClaimTile:GetUnclaimedString()
    return GetString(SI_CLAIM_TILE_CLAIM)
end

function ZO_ClaimTile:GetClaimedString()
    return GetString(SI_CLAIM_TILE_VIEW_ALL)
end

function ZO_ClaimTile:SetClaimState(claimState)
    self.claimState = claimState
end

function ZO_ClaimTile:RequestClaim()
    self:SetClaimState(ZO_CLAIM_TILE_STATE.CLAIMED)

    if self.onClaimCallback then
        self.onClaimCallback()
    end

    if self.animationTimeline then
        local animationTransitionCallback = function()
            self.animationTimeline:SetHandler("OnStop", nil)
    
            self:OnAnimationTransitionCompleted()
        end

        self.animationTimeline:SetHandler("OnStop", animationTransitionCallback)
    end

    self:PlayAnimation()
end

function ZO_ClaimTile:SetClaimCallback(onClaimCallback)
    self.onClaimCallback = onClaimCallback
end

function ZO_ClaimTile:SetAnimation(animation)
    self.animationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(animation, self.container)
end

function ZO_ClaimTile:PlayAnimation()
    if self.animationTimeline then
        self.animationTimeline:PlayForward()
    else
        self:OnAnimationTransitionCompleted()
    end
end

function ZO_ClaimTile:OnAnimationTransitionCompleted()
    self:OnClaimCompleted()
end

function ZO_ClaimTile:OnClaimCompleted()
    self:RefreshLayout()

    if self.animationTimeline then
        self.animationTimeline:PlayBackward()
    end
end