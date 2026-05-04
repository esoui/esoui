-- ZO_UISystemManager
----------------------
local ZO_UISystemManager = ZO_InitializingCallbackObject:Subclass()

function ZO_UISystemManager:Initialize()
    self.systems =
    {
        [UI_SYSTEM_ANTIQUITY_JOURNAL_SCRYABLE] =
        {
            displayName = SI_JOURNAL_MENU_ANTIQUITIES,
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
            displayName = SI_GUILD_BROWSER_TITLE,
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "guildBrowserKeyboard")
                GUILD_SELECTOR:SelectGuildFinder()
            end,
            gamepadOpen = function()
                SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepad_guild_hub", "guildBrowserGamepad")
            end,
        },
        [UI_SYSTEM_ALLIANCE_WAR] =
        {
            displayName = SI_MAIN_MENU_ALLIANCE_WAR,
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ShowSceneGroup("allianceWarSceneGroup", "campaignBrowser")
            end,
            gamepadOpen = function()
                SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepad_campaign_root")
            end,
        },
        [UI_SYSTEM_DUNGEON_FINDER] =
        {
            displayName = SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER,
            keyboardOpen = function()
                GROUP_MENU_KEYBOARD:ShowCategory(DUNGEON_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(DUNGEON_FINDER_MANAGER:GetCategoryData())
            end,
        },
        [UI_SYSTEM_BATTLEGROUND_FINDER] =
        {
            displayName = SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS,
            keyboardOpen = function()
                GROUP_MENU_KEYBOARD:ShowCategory(BATTLEGROUND_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(BATTLEGROUND_FINDER_MANAGER:GetCategoryData())
            end,
        },
        [UI_SYSTEM_ZONE_GUIDE] =
        {
            displayName = SI_ACTIVITY_FINDER_CATEGORY_ZONE_STORIES,
            keyboardOpen = function(zoneId)
                ZONE_STORIES_MANAGER:ShowZoneStoriesScene(zoneId)
            end,
            gamepadOpen = function(zoneId)
                ZONE_STORIES_MANAGER:ShowZoneStoriesScene(zoneId)
            end,
        },
        [UI_SYSTEM_TRIBUTE_FINDER] =
        {
            displayName = SI_ACTIVITY_FINDER_CATEGORY_TRIBUTE,
            keyboardOpen = function()
                GROUP_MENU_KEYBOARD:ShowCategory(TRIBUTE_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(TRIBUTE_FINDER_MANAGER:GetCategoryData())
            end,
        },
        [UI_SYSTEM_CHARACTER_STATS] =
        {
            displayName = SI_MAIN_MENU_CHARACTER,
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ShowScene("stats")
            end,
            gamepadOpen = function()
                MAIN_MENU_GAMEPAD:ShowScene("gamepad_stats_root")
            end,
        },
        [UI_SYSTEM_SKILLS] =
        {
            displayName = SI_MAIN_MENU_SKILLS,
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ShowScene("skills")
            end,
            gamepadOpen = function()
                MAIN_MENU_GAMEPAD:ShowScene("gamepad_skills_root")
            end,
        },
        [UI_SYSTEM_GROUP_FINDER] =
        {
            displayName = SI_ACTIVITY_FINDER_CATEGORY_GROUP_FINDER,
            keyboardOpen = function()
                GROUP_MENU_KEYBOARD:ShowCategory(GROUP_FINDER_KEYBOARD_FRAGMENT)
            end,
            gamepadOpen = function()
                ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(GROUP_FINDER_GAMEPAD:GetCategoryData())
            end,
        },
        [UI_SYSTEM_VENGEANCE] =
        {
            displayName = SI_CAMPAIGN_OVERVIEW_CATEGORY_VENGEANCE,
            keyboardOpen = function()
                CAMPAIGN_OVERVIEW:SetCategoryOnShowByData(ZO_CAMPAIGN_OVERVIEW_TYPE_INFO[ZO_CAMPAIGN_OVERVIEW_TYPE.VENGEANCE].children[ZO_CAMPAIGN_OVERVIEW_TYPE_VENGEANCE.LOADOUTS])
                MAIN_MENU_KEYBOARD:ShowScene("campaignOverview")
            end,
            gamepadOpen = function()
                SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepad_campaign_root", "gamepad_vengeance_loadouts")
            end,
        },
        [UI_SYSTEM_TAMRIEL_TOMES] =
        {
            displayName = SI_MAIN_MENU_TAMRIEL_TOMES,
            keyboardOpen = function(tomeId)
                TAMRIEL_TOMES_MANAGER:OpenTamrielTome(tomeId)
            end,
            gamepadOpen = function(tomeId)
                TAMRIEL_TOMES_MANAGER:OpenTamrielTome(tomeId)
            end,
        },
    }

    local function ShowAnnouncement()
        if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:ShouldShowAnnouncementEntry() then
            PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:ShowAnnouncementScreen()
        else
            ShowMarketAnnouncements()
        end
    end

    self.systems[UI_SYSTEM_ANNOUNCEMENT] =
    {
        displayName = function()
            if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:ShouldShowAnnouncementEntry() then
                return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetCampaignDisplayName()
            end
            return GetString(SI_MAIN_MENU_ANNOUNCEMENTS)
        end,
        displayNameColor = function()
            if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:ShouldShowAnnouncementEntry() then
                return ZO_PROMOTIONAL_EVENT_SELECTED_COLOR
            end
            return ZO_WHITE
        end,
        keyboardOpen = ShowAnnouncement,
        gamepadOpen = ShowAnnouncement,
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

        FlagPromotionalEventPersonalCampaignAnnouncementSeen()
        FlagMarketAnnouncementSeen()
    elseif self:TryShowPromotionalEventPersonalCampaignAnnouncement() then
        -- TryShowPromotionalEventPersonalCampaignAnnouncement has handled showing the announcement
    elseif not HasShownMarketAnnouncement() then
        local accountTypeId = GetTrialInfo()
        local isFreeTrial = accountTypeId > 0
        local SHOW_INTRO = true
        if (not isFreeTrial) and TAMRIEL_TOMES_MANAGER:TryOpenNewSeasonTamrielTome(SHOW_INTRO) then
            -- TryOpenNewSeasonTamrielTome has handled showing the Tome

            FlagPromotionalEventPersonalCampaignAnnouncementSeen()
            FlagMarketAnnouncementSeen()
        else
            RequestMarketAnnouncement()
        end
    end

    self.waitingForMarketAnnouncements = not HasShownMarketAnnouncement()

    self:TryOpenQueuedUISystem()
end

-- Returns whether the low level/returning player flow is handling showing the announcement
function ZO_UISystemManager:TryShowPromotionalEventPersonalCampaignAnnouncement()
    local shouldShowAnnouncement = PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:ShouldShowAnnouncementEntry()
    if not shouldShowAnnouncement then
        return false
    end

    if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsIntroCampaignComplete() then
        -- Don't show the rewards announcement if we've already seen it recently
        local REWARDS_ANNOUNCEMENT_SUPPRESSION_TIME_SECONDS = 2 * ZO_ONE_HOUR_IN_SECONDS
        local timestamp = GetTimeStamp()
        local dontShow = false

        if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsLowLevelPlayer() then
            dontShow = timestamp < LOW_LEVEL_PLAYER_MANAGER:GetLastTimeRewardsWereSeen() + REWARDS_ANNOUNCEMENT_SUPPRESSION_TIME_SECONDS
        elseif PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsReturningPlayer() then
            dontShow = not RETURNING_PLAYER_MANAGER:HasClaimableDailyReward() and timestamp < RETURNING_PLAYER_MANAGER:GetLastTimeRewardsWereSeen() + REWARDS_ANNOUNCEMENT_SUPPRESSION_TIME_SECONDS
        end

        if dontShow then
            -- Also mark the announcement as seen so it doesn't pop up later
            FlagPromotionalEventPersonalCampaignAnnouncementSeen()
            return false
        end
    end

    -- If we're in a starter world, we don't want to show an announcement
    -- We do want the announcement to show when we change areas, so don't flag as seen
    if IsActiveWorldStarterWorld() then
        return true
    end

    -- Make sure to update the promotional events manager: due to the timing
    -- of the Lua events it may not have updated even though the data is ready
    PROMOTIONAL_EVENT_MANAGER:RefreshCampaignData()
    PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:ShowAnnouncementScreen()

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

function ZO_UISystemManager:GetPlatformUISystemDisplayName(system)
    if IsInGamepadPreferredMode() then
        return self:GetGamepadUISystemDisplayName(system)
    else
        return self:GetKeyboardUISystemDisplayName(system)
    end
end

do
    local function GetUISystemDisplayName(nameField, system)
        if nameField then
            local nameOrId = ZO_Eval(nameField)
            if type(nameOrId) == "number" then
                return GetString(nameOrId)
            end
            return nameOrId
        end
        return GetString("SI_UISYSTEM", system)
    end

    function ZO_UISystemManager:GetGamepadUISystemDisplayName(system)
        if internalassert(self.systems[system], "That UI system cannot be opened in this manner.") then
            local nameField = self.systems[system].gamepadDisplayName or self.systems[system].displayName
            return GetUISystemDisplayName(nameField, system)
        end
    end

    function ZO_UISystemManager:GetKeyboardUISystemDisplayName(system)
        if internalassert(self.systems[system], "That UI system cannot be opened in this manner.") then
            local nameField = self.systems[system].keyboardDisplayName or self.systems[system].displayName
            return GetUISystemDisplayName(nameField, system)
        end
    end
end

function ZO_UISystemManager:GetColorizedPlatformUISystemDisplayName(system)
    if IsInGamepadPreferredMode() then
        return self:GetColorizedGamepadUISystemDisplayName(system)
    else
        return self:GetColorizedKeyboardUISystemDisplayName(system)
    end
end

do
    local function GetColorizedUISystemDisplayName(displayName, displayNameColorField)
        local color = ZO_WHITE
        if displayNameColorField then
            color = ZO_Eval(displayNameColorField)
        end
        return color:Colorize(displayName)
    end

    function ZO_UISystemManager:GetColorizedGamepadUISystemDisplayName(system)
        local displayName = self:GetGamepadUISystemDisplayName(system)
        return GetColorizedUISystemDisplayName(displayName, self.systems[system].displayNameColor)
    end

    function ZO_UISystemManager:GetColorizedKeyboardUISystemDisplayName(system)
        local displayName = self:GetKeyboardUISystemDisplayName(system)
        return GetColorizedUISystemDisplayName(displayName, self.systems[system].displayNameColor)
    end
end

do
    local KEYBOARD_HELP_ICON = zo_iconFormat("EsoUI/Art/Miscellaneous/help_icon.dds", "140%", "140%")
    local GAMEPAD_HELP_ICON = zo_iconFormat("EsoUI/Art/Miscellaneous/help_icon.dds", "100%", "100%")
    local DEFAULT_PREFER_GAMEPAD_MODE = nil
    local DEFAULT_SHOW_AS_HOLD = nil
    local DEFAULT_SCALE_PERCENT = nil
    local DEFAULT_USE_DISABLED_ICON = nil
    local ADDITIONAL_OPTIONS =
    {
        useWideMarkup = true,
    }
    function ZO_UISystemManager:GetMenuAssistanceDescriptionText(menuAssistanceType, referenceData, keybind)
        if menuAssistanceType ~= MENU_ASSISTANCE_TYPE_NONE then
            local keybindMarkup = ZO_WHITE:Colorize(ZO_Keybindings_GetHighestPriorityBindingStringFromAction(keybind, KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, DEFAULT_PREFER_GAMEPAD_MODE, DEFAULT_SHOW_AS_HOLD, DEFAULT_SCALE_PERCENT, DEFAULT_USE_DISABLED_ICON, ADDITIONAL_OPTIONS))
            local referenceDataParam = ""
            if menuAssistanceType == MENU_ASSISTANCE_TYPE_UI_SYSTEM then
                referenceDataParam = self:GetColorizedPlatformUISystemDisplayName(referenceData)
            end
            local helpIcon = IsInGamepadPreferredMode() and GAMEPAD_HELP_ICON or KEYBOARD_HELP_ICON
            return zo_strformat(GetString("SI_MENUASSISTANCETYPE", menuAssistanceType), helpIcon, keybindMarkup, referenceDataParam)
        end
        return nil
    end
end

function ZO_UISystemManager:GetMenuAssistanceKeybindName(menuAssistanceType, referenceData)
    local keybindName = GetString("SI_MENUASSISTANCETYPE_KEYBIND", menuAssistanceType)
    if menuAssistanceType == MENU_ASSISTANCE_TYPE_UI_SYSTEM then
        local systemName = self:GetColorizedPlatformUISystemDisplayName(referenceData)
        keybindName = zo_strformat(keybindName, systemName)
    end
    return keybindName
end

function ZO_UISystemManager:TriggerMenuAssistance(menuAssistanceType, referenceData)
    if menuAssistanceType == MENU_ASSISTANCE_TYPE_TUTORIAL then
        ForceShowTutorial(referenceData)
    elseif menuAssistanceType == MENU_ASSISTANCE_TYPE_HELP then
        local helpCategoryIndex, helpIndex = GetHelpDefIndicesFromHelpDefId(referenceData)
        if IsInGamepadPreferredMode() then
            HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(helpCategoryIndex, helpIndex)
        else
            HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
        end
    elseif menuAssistanceType == MENU_ASSISTANCE_TYPE_UI_SYSTEM then
        ZO_UI_SYSTEM_MANAGER:RequestOpenUISystem(referenceData)
    elseif menuAssistanceType == MENU_ASSISTANCE_TYPE_GRAVEYARD then
        -- e.g.: RequestJumpToTimedActivityMenuAssistanceInfo
        internalassert(false, "GRAVEYARD must be handled through separate systems")
    end
end

function ZO_UISystemManager:IsShowingAnnouncement()
    return SCENE_MANAGER:IsShowing("marketAnnouncement") or LOW_LEVEL_PLAYER_MANAGER:IsShowingLowLevelPlayerScene() or RETURNING_PLAYER_MANAGER:IsShowingReturningPlayerScene()
end

ZO_UI_SYSTEM_MANAGER = ZO_UISystemManager:New()