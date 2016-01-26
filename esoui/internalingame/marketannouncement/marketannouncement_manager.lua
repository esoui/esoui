----
-- MarketAnnouncement_Manager
----

local MarketAnnouncement_Manager = ZO_Object:Subclass()

function MarketAnnouncement_Manager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function MarketAnnouncement_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("MarketAnnouncement_Manager", EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)

    self.scene = ZO_RemoteScene:New("marketAnnouncement", SCENE_MANAGER)
    self.scene:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
end

function MarketAnnouncement_Manager:OnPlayerActivated()
    if HasMarketAnnouncement() then
        local currentTrialVersion, seenTrialVersion = select(4, ZO_TrialAccount_GetInfo())
        if seenTrialVersion < currentTrialVersion then
            FlagMarketAnnouncementSeen() --We only want to show one popup per session if possible, and trial dialog takes priority
        elseif not self.saveAnnouncementForNextSession then
            SCENE_MANAGER:Show("marketAnnouncement")
        end
    end
end

function MarketAnnouncement_Manager:OnStateChanged(oldState, newState)
    if newState == SCENE_HIDING then
        FlagMarketAnnouncementSeen()
    end
end

ZO_MARKET_ANNOUNCEMENT_MANAGER = MarketAnnouncement_Manager:New()