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
    }

    -- ... is a series of param1, param2, etc.
    local function OnRequestOpenUISystem(event, system, ...)
        self:RequestOpenUISystem(system, ...)
    end

    EVENT_MANAGER:RegisterForEvent("UISystemManager", EVENT_OPEN_UI_SYSTEM, OnRequestOpenUISystem)

    self.queuedUISystem = nil
    self.queuedParams = {}
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
    return not SCENE_MANAGER:IsShowing("marketAnnouncement")
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

ZO_UI_SYSTEM_MANAGER = ZO_UISystemManager:New()