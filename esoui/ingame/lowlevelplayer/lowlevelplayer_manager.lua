ZO_LowLevelPlayer_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_LowLevelPlayer_Manager:Initialize()
    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            EVENT_MANAGER:UnregisterForEvent("LowLevelPlayer_Manager", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("LowLevelPlayer_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_LowLevelPlayer_Manager:SetupSavedVars()
    local defaults =
    {
        lastSeenRewardsTimestamp = 0,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "LowLevelPlayer_Manager", defaults)
end

function ZO_LowLevelPlayer_Manager:ShowLowLevelPlayerAnnouncementScreen()
    SYSTEMS:ShowScene("lowLevelPlayer")
end

function ZO_LowLevelPlayer_Manager:IsShowingLowLevelPlayerScene()
    return SYSTEMS:IsShowing("lowLevelPlayer")
end

function ZO_LowLevelPlayer_Manager:ShouldShowLowLevelPlayerAnnouncement()
    if not PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsLowLevelPlayer() or HasShownPromotionalEventPersonalCampaignAnnouncement() then
        return false
    end

    -- Always show if we haven't completed the intro
    if not PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsIntroCampaignComplete() then
        return true
    end

    -- Don't show if there aren't any unclaimed rewards
    if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:HasClaimedAllPrimaryRewards() then
        return false
    end

    return true
end

function ZO_LowLevelPlayer_Manager:ShouldShowLowLevelPlayerAnnouncementEntry()
    return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsLowLevelPlayer() and not PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:HasClaimedAllPrimaryRewards()
end

function ZO_LowLevelPlayer_Manager:MarkRewardsAsSeen()
    self.savedVars.lastSeenRewardsTimestamp = GetTimeStamp()
end

function ZO_LowLevelPlayer_Manager:GetLastTimeRewardsWereSeen()
    return self.savedVars.lastSeenRewardsTimestamp
end

LOW_LEVEL_PLAYER_MANAGER = ZO_LowLevelPlayer_Manager:New()
