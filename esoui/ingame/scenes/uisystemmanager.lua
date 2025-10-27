-- ZO_UISystemManager
----------------------
local ZO_UISystemManager = ZO_InitializingCallbackObject:Subclass()

function ZO_UISystemManager:Initialize()
    self.systems =
    {
        [UI_SYSTEM_ANTIQUITY_JOURNAL_SCRYABLE] =
        {
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ShowSceneGroup("journalSceneGroup", "antiquityJournalKeyboard")
                ANTIQUITY_JOURNAL_KEYBOARD:ShowScryable()
            end,
            gamepadOpen = function()
                SYSTEMS:GetObject("mainMenu"):ShowScryableAntiquities()
            end,
        },
        [UI_SYSTEM_GUILD_FINDER] =
        {
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ShowSceneGroup("journalSceneGroup", "guildBrowserKeyboard")
                GUILD_SELECTOR:SelectGuildFinder()
            end,
            gamepadOpen = function()
                SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepad_guild_hub", "guildBrowserGamepad")
            end,
        },
        [UI_SYSTEM_ALLIANCE_WAR] =
        {
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ShowSceneGroup("allianceWarSceneGroup", "campaignBrowser")
            end,
            gamepadOpen = function()
                SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepad_campaign_root")
            end,
        },
        [UI_SYSTEM_DUNGEON_FINDER] =
        {
            keyboardOpen = function()
                GROUP_MENU_KEYBOARD:ShowCategory(DUNGEON_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(DUNGEON_FINDER_MANAGER:GetCategoryData())
            end,
        },
        [UI_SYSTEM_BATTLEGROUND_FINDER] =
        {
            keyboardOpen = function()
                GROUP_MENU_KEYBOARD:ShowCategory(BATTLEGROUND_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(BATTLEGROUND_FINDER_MANAGER:GetCategoryData())
            end,
        },
        [UI_SYSTEM_ZONE_GUIDE] =
        {
            keyboardOpen = function(zoneId)
                ZONE_STORIES_MANAGER:ShowZoneStoriesScene(zoneId)
            end,
            gamepadOpen = function(zoneId)
                ZONE_STORIES_MANAGER:ShowZoneStoriesScene(zoneId)
            end,
        },
        [UI_SYSTEM_TRIBUTE_FINDER] =
        {
            keyboardOpen = function()
                GROUP_MENU_KEYBOARD:ShowCategory(TRIBUTE_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(TRIBUTE_FINDER_MANAGER:GetCategoryData())
            end,
        },
        [UI_SYSTEM_VENGEANCE] =
        {
            keyboardOpen = function()
                CAMPAIGN_OVERVIEW:SetCategoryOnShowByData(ZO_CAMPAIGN_OVERVIEW_TYPE_INFO[ZO_CAMPAIGN_OVERVIEW_TYPE.VENGEANCE].children[ZO_CAMPAIGN_OVERVIEW_TYPE_VENGEANCE.LOADOUTS])
                MAIN_MENU_KEYBOARD:ShowScene("campaignOverview")
            end,
            gamepadOpen = function()
                SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepad_campaign_root", "gamepad_vengeance_loadouts")
            end,
        },
    }

    -- ... is a series of param1, param2, etc.
    local function OnRequestOpenUISystem(event, system, ...)
        self:RequestOpenUISystem(system, ...)
    end

    EVENT_MANAGER:RegisterForEvent("UISystemManager", EVENT_OPEN_UI_SYSTEM, OnRequestOpenUISystem)

    local function OnPlayerActivated()
        self:OnPlayerActivated()
    end

    EVENT_MANAGER:RegisterForEvent("UISystemManager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    local function OnPromotionalEventCampaignsUpdated()
        self:OnPromotionalEventCampaignsUpdated()
    end

    EVENT_MANAGER:RegisterForEvent("UISystemManager", EVENT_PROMOTIONAL_EVENTS_CAMPAIGNS_UPDATED, OnPromotionalEventCampaignsUpdated)

    local function OnMarketAnnouncementUpdated(eventId, ...)
        self:OnMarketAnnouncementUpdated(...)
    end

    EVENT_MANAGER:RegisterForEvent("UISystemManager", EVENT_MARKET_ANNOUNCEMENT_UPDATED, OnMarketAnnouncementUpdated)

    self.queuedUISystem = nil
    self.queuedParams = {}
    self.waitingForMarketAnnouncements = not HasShownMarketAnnouncement()
    self.waitingForPromotionalEvents = not HasReceivedPromotionalEventUpdate()
end

function ZO_UISystemManager:OnPlayerActivated()
    if not self.waitingForPromotionalEvents then
        self:TryShowInitialScreen()
    end
end

function ZO_UISystemManager:OnPromotionalEventCampaignsUpdated()
    if self.waitingForPromotionalEvents and IsPlayerActivated() then
        self.waitingForPromotionalEvents = false
        self:TryShowInitialScreen()
    end
end

-- This function should only be called once IsPlayerActivated() and self.waitingForPromotionalEvents
-- are both true.
function ZO_UISystemManager:TryShowInitialScreen()
    -- We only want to show one popup, check each one in priority order
    if TRIAL_ACCOUNT_SPLASH_DIALOG:ShouldShowSplash() then
        TRIAL_ACCOUNT_SPLASH_DIALOG:ShowSplash()

        FlagReturningPlayerAnnouncementSeen()
        FlagMarketAnnouncementSeen()
    elseif self:TryShowReturningPlayerAnnouncement() then
        -- TryShowReturningPlayerAnnouncement has handled showing the announcement
    elseif not HasShownMarketAnnouncement() then
        RequestMarketAnnouncement()
    end

    self.waitingForMarketAnnouncements = not HasShownMarketAnnouncement()

    self:TryOpenQueuedUISystem()
end

-- Returns whether the returning player flow is handling showing the announcement
function ZO_UISystemManager:TryShowReturningPlayerAnnouncement()
    local shouldShowAnnouncement = RETURNING_PLAYER_MANAGER:ShouldShowReturningPlayerAnnouncement()
    if not shouldShowAnnouncement then
        return false
    end

    -- Don't show the rewards announcement if we've already seen it recently
    -- Also mark the announcement as seen so it doesn't pop up later
    local REWARDS_ANNOUNCEMENT_SUPPRESSION_TIME_SECONDS = 2 * ZO_ONE_HOUR_IN_SECONDS
    if RETURNING_PLAYER_MANAGER:IsIntroCampaignComplete()
            and not RETURNING_PLAYER_MANAGER:HasClaimableDailyReward()
            and GetTimeStamp() < RETURNING_PLAYER_MANAGER:GetLastTimeRewardsWereSeen() + REWARDS_ANNOUNCEMENT_SUPPRESSION_TIME_SECONDS then
        FlagReturningPlayerAnnouncementSeen()
        return false
    end

    -- If we're in a starter world, we don't want to show an announcement
    -- We do want the announcement to show when we change areas, so don't flag as seen
    if IsActiveWorldStarterWorld() then
        return true
    end

    -- Make sure to update the promotional events manager: due to the timing
    -- of the Lua events it may not have updated even though the data is ready
    PROMOTIONAL_EVENT_MANAGER:RefreshCampaignData()
    RETURNING_PLAYER_MANAGER:ShowReturningPlayerAnnouncementScreen()

    FlagMarketAnnouncementSeen()

    return true
end

function ZO_UISystemManager:OnMarketAnnouncementUpdated(shouldShow, isLocked)
    self.waitingForMarketAnnouncements = false

    if shouldShow and not (HasShownMarketAnnouncement() or SCENE_MANAGER:IsShowing("marketAnnouncement")) then
        SCENE_MANAGER:Show("marketAnnouncement")
    else
        self:TryOpenQueuedUISystem()
    end
end

function ZO_UISystemManager:SetQueuedUISystem(system, ...)
    self.queuedUISystem = system
    self.queuedParams = {...}
end

function ZO_UISystemManager:ClearQueuedUISystem()
    self.queuedUISystem = nil
    self.queuedParams = {}
end

function ZO_UISystemManager:CanOpenUISystem()
    return IsPlayerActivated()
        and not self.waitingForMarketAnnouncements
        and not self.waitingForPromotionalEvents
        and not self:IsShowingAnnouncement()
end

function ZO_UISystemManager:RequestOpenUISystem(system, ...)
    if self:CanOpenUISystem() then
        self:OpenPlatformUISystem(system, ...)
    else
        self:SetQueuedUISystem(system, ...)
    end
end

function ZO_UISystemManager:TryOpenQueuedUISystem()
    if self.queuedUISystem ~= nil then
        self:RequestOpenUISystem(self.queuedUISystem, unpack(self.queuedParams))
    end
end

function ZO_UISystemManager:OpenPlatformUISystem(system, ...)
    if IsInGamepadPreferredMode() then
        self:OpenGamepadUISystem(system, ...)
    else
        self:OpenKeyboardUISystem(system, ...)
    end
end

function ZO_UISystemManager:OpenGamepadUISystem(system, ...)
    self:ClearQueuedUISystem()
    if internalassert(self.systems[system], "That UI system cannot be opened in this manner.") then
        self.systems[system].gamepadOpen(...)
    end
end

function ZO_UISystemManager:OpenKeyboardUISystem(system, ...)
    self:ClearQueuedUISystem()
    if internalassert(self.systems[system], "That UI system cannot be opened in this manner.") then
        self.systems[system].keyboardOpen(...)
    end
end

function ZO_UISystemManager:IsShowingAnnouncement()
    return SCENE_MANAGER:IsShowing("marketAnnouncement") or RETURNING_PLAYER_MANAGER:IsShowingReturningPlayerScene()
end

ZO_UI_SYSTEM_MANAGER = ZO_UISystemManager:New()