-- ZO_UISystemManager
----------------------
local ZO_UISystemManager = ZO_CallbackObject:Subclass()

function ZO_UISystemManager:New()
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize()
    return manager
end

function ZO_UISystemManager:Initialize()
    self.systems = 
    {
        [UI_SYSTEM_ANTIQUITY_JOURNAL_SCRYABLE] =
        {
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ToggleSceneGroup("journalSceneGroup", "antiquityJournalKeyboard")
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
                MAIN_MENU_KEYBOARD:ToggleScene("groupMenuKeyboard")
                GROUP_MENU_KEYBOARD:SetCurrentCategory(DUNGEON_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                local isLocked = BATTLEGROUND_FINDER_GAMEPAD:GetLevelLockInfo()
                if not isLocked then
                    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME, GAMEPAD_DUNGEON_FINDER_SCENE:GetName())
                else
                    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME)
                    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:SelectCategory(DUNGEON_FINDER_MANAGER:GetCategoryData())
                end
            end,
        },
        [UI_SYSTEM_BATTLEGROUND_FINDER] =
        {
            keyboardOpen = function()
                MAIN_MENU_KEYBOARD:ToggleScene("groupMenuKeyboard")
                GROUP_MENU_KEYBOARD:SetCurrentCategory(BATTLEGROUND_FINDER_KEYBOARD:GetFragment())
            end,
            gamepadOpen = function()
                local isLocked = BATTLEGROUND_FINDER_GAMEPAD:GetLevelLockInfo()
                if not isLocked then
                    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME, GAMEPAD_BATTLEGROUND_FINDER_SCENE:GetName())
                else
                    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME)
                    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:SelectCategory(BATTLEGROUND_FINDER_MANAGER:GetCategoryData())
                end
            end,
        },
    }
    
    local function OnRequestOpenUISystem(event, system)
        self:RequestOpenUISystem(system)
    end

    EVENT_MANAGER:RegisterForEvent("UISystemManager", EVENT_OPEN_UI_SYSTEM, OnRequestOpenUISystem)
end

function ZO_UISystemManager:RequestOpenUISystem(system)
    SCENE_MANAGER:HideCurrentScene()
    if IsInGamepadPreferredMode() then
        self:OpenGamepadUISystem(system)
    else
        self:OpenKeyboardUISystem(system)
    end
end

function ZO_UISystemManager:OpenGamepadUISystem(system)
    if internalassert(self.systems[system], "That UI system cannot be opened in this manner.") then
        self.systems[system].gamepadOpen()
    end
end

function ZO_UISystemManager:OpenKeyboardUISystem(system)
    if internalassert(self.systems[system], "That UI system cannot be opened in this manner.") then
        self.systems[system].keyboardOpen()
    end
end

ZO_UI_SYSTEM_MANAGER = ZO_UISystemManager:New()