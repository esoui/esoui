MAIN_MENU_CATEGORY_ENABLED = 0
MAIN_MENU_CATEGORY_DISABLED_WHILE_DEAD = 1
MAIN_MENU_CATEGORY_DISABLED_WHILE_IN_COMBAT = 2
MAIN_MENU_CATEGORY_DISABLED_WHILE_REVIVING = 3
MAIN_MENU_CATEGORY_DISABLED_WHILE_SWIMMING = 4
MAIN_MENU_CATEGORY_DISABLED_WHILE_WEREWOLF = 5

--Main Menu Categories

MENU_CATEGORY_MARKET = 1
MENU_CATEGORY_CROWN_CRATES = 2
MENU_CATEGORY_INVENTORY = 3
MENU_CATEGORY_CHARACTER = 4
MENU_CATEGORY_SKILLS = 5
MENU_CATEGORY_CHAMPION = 6
MENU_CATEGORY_JOURNAL = 7
MENU_CATEGORY_COLLECTIONS = 8
MENU_CATEGORY_MAP = 9
MENU_CATEGORY_GROUP = 10
MENU_CATEGORY_CONTACTS = 11
MENU_CATEGORY_GUILDS = 12
MENU_CATEGORY_ALLIANCE_WAR = 13
MENU_CATEGORY_MAIL = 14
MENU_CATEGORY_NOTIFICATIONS = 15
MENU_CATEGORY_HELP = 16
MENU_CATEGORY_ACTIVITY_FINDER = 17

--
--[[ MainMenu Singleton ]]--
--

local MainMenu_Manager = ZO_CallbackObject:Subclass()

function MainMenu_Manager:New(...)
    local mainMenu = ZO_CallbackObject.New(self)
    mainMenu:Initialize(...) -- ZO_CallbackObject does not have an initialize function
    return mainMenu
end

function MainMenu_Manager:Initialize()
    self.playerStateTable =
        {
            isDead = IsUnitDead("player"),
            inCombat = IsUnitInCombat("player"),
            isReviving = IsUnitReincarnating("player"),
            isWerewolf = IsWerewolf(),
        }

    local PLAYER_IS_DEAD = false
    local PLAYER_IS_ALIVE = true
    local PLAYER_IS_SWIMMING = true
    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_PLAYER_DEAD, function() self:OnPlayerAliveStateChanged(PLAYER_IS_DEAD) end)
    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_PLAYER_ALIVE, function() self:OnPlayerAliveStateChanged(PLAYER_IS_ALIVE) end)
    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_PLAYER_COMBAT_STATE, function(eventCode, inCombat) self:OnPlayerCombatStateChanged(inCombat) end)
    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_WEREWOLF_STATE_CHANGED, function(eventCode, isWerewolf) self:OnPlayerWerewolfStateChanged(isWerewolf) end)

    local PLAYER_IS_REVIVING = true
    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_PLAYER_REINCARNATED, function() self:OnPlayerRevivingStateChanged(not PLAYER_IS_REVIVING) end)
    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_PLAYER_SWIMMING, function() self:OnPlayerSwimmingStateChanged(PLAYER_IS_SWIMMING) end)
    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_PLAYER_NOT_SWIMMING, function() self:OnPlayerSwimmingStateChanged(not PLAYER_IS_SWIMMING) end)

    EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_PLAYER_ACTIVATED, function() self:RefreshPlayerState() end)
end

function MainMenu_Manager:OnPlayerAliveStateChanged(isAlive)
    self.playerStateTable.isDead = not isAlive
    self.playerStateTable.isReviving = IsUnitReincarnating("player")

    self:OnPlayerStateUpdate()
end

function MainMenu_Manager:OnPlayerCombatStateChanged(inCombat)
    self.playerStateTable.inCombat = inCombat
    self:OnPlayerStateUpdate()
end

function MainMenu_Manager:OnPlayerRevivingStateChanged(isReviving)
    self.playerStateTable.isReviving = isReviving
    self:OnPlayerStateUpdate()
end

function MainMenu_Manager:OnPlayerSwimmingStateChanged(isSwimming)
    self.playerStateTable.isSwimming = isSwimming
    self:OnPlayerStateUpdate()
end

function MainMenu_Manager:OnPlayerWerewolfStateChanged(isWerewolf)
    self.playerStateTable.isWerewolf = isWerewolf
    self:OnPlayerStateUpdate()
end

function MainMenu_Manager:OnPlayerStateUpdate()
    self:FireCallbacks("OnPlayerStateUpdate")
end

function MainMenu_Manager:RefreshPlayerState()
    local stateTable = self.playerStateTable
    stateTable.isDead = IsUnitDead("player")
    stateTable.inCombat = IsUnitInCombat("player")
    stateTable.isReviving = IsUnitReincarnating("player")
    self:OnPlayerStateUpdate()
end

function MainMenu_Manager:IsPlayerDead()
    return self.playerStateTable.isDead
end

function MainMenu_Manager:IsPlayerInCombat()
    return self.playerStateTable.inCombat
end

function MainMenu_Manager:IsPlayerReviving()
    return self.playerStateTable.isReviving
end

function MainMenu_Manager:IsPlayerSwimming()
    return self.playerStateTable.isSwimming
end

function MainMenu_Manager:IsPlayerWerewolf()
    return self.playerStateTable.isWerewolf
end

--[[
    Blocking Scenes prevent the menu from showing other scenes while the blocking scene is activated. If
    the player attempts to change the scene while the blocking scene is active, the requested scene is
    stored and then only shown once the blocking scene has been cleared.

    Blocking scenes should call SetBlockingScene and specify a callback when shown, and call ClearBlockingScene when hidden.
    Only one blocking scene should be active at any given time.

    Note: nextSceneData is a table that can contain the following information:
        category: Integer ID for the menu category. Must be specified if sceneName is not.
        sceneName: The name of the scene. Must be specified if category is not.
        sceneGroup: The scene group that the scene is a part of. category and sceneName must both be specified if this is used
]]--

local function MainMenu_Manager_BlockingSceneCallback(self)
    self:FireCallbacks("OnBlockingSceneActivated", self.activatedByMouseClick, self.nextSceneData.sceneGroup ~= nil)
end

-- Call this when the blocking scene is shown
function MainMenu_Manager:SetBlockingScene(sceneName, callback, arg)
    assert(self.blockingSceneName == nil and sceneName)     -- Can't set more than one blocking scene at a time, or can't set one without a name

    self.blockingSceneName = sceneName
    self:RegisterCallback("OnBlockingSceneActivated", callback, arg)
end

-- Call this when the blocking scene is hidden
function MainMenu_Manager:ClearBlockingScene(callback)
    local nextSceneData = self.nextSceneData
    local showBaseScene = self.showBaseScene

    self:CancelBlockingSceneNextScene()
    self:UnregisterCallback("OnBlockingSceneActivated", callback)
    self.blockingSceneName = nil

    self:FireCallbacks("OnBlockingSceneCleared", nextSceneData, showBaseScene) 
end

function MainMenu_Manager:ForceClearBlockingScenes()
    self:CancelBlockingSceneNextScene()
    self:UnregisterAllCallbacks("OnBlockingSceneActivated")
    self.blockingSceneName = nil
end

-- Call this if you want to cancel the scene to show when the blocking scene is cleared.
function MainMenu_Manager:CancelBlockingSceneNextScene()
    self.nextSceneData = nil
    self.showBaseScene = nil
    self.activatedByMouseClick = nil
end

-- Don't call this directly; intended to be a private method
function MainMenu_Manager:ClearBlockingSceneOnGamepadModeChange()
    if self.blockingSceneName then
        self:UnregisterAllCallbacks("OnBlockingSceneActivated")
        self:CancelBlockingSceneNextScene()
        self.blockingSceneName = nil
    end
end

local function MainMenu_Manager_ActivatedBlockingScene_Internal(self, sceneData, isBaseScene, activatedByMouseClick)
    self.nextSceneData = sceneData or {}
    self.showBaseScene = isBaseScene
    self.activatedByMouseClick = activatedByMouseClick

    MainMenu_Manager_BlockingSceneCallback(self)
end

function MainMenu_Manager:ActivatedBlockingScene_Scene(nextSceneData, activatedByMouseClick)
    MainMenu_Manager_ActivatedBlockingScene_Internal(self, nextSceneData, nil, activatedByMouseClick)
end

function MainMenu_Manager:ActivatedBlockingScene_BaseScene(activatedByMouseClick)
    MainMenu_Manager_ActivatedBlockingScene_Internal(self, nil, true, activatedByMouseClick)
end

function MainMenu_Manager:HasBlockingScene()
    return self.blockingSceneName ~= nil
end

function MainMenu_Manager:HasBlockingSceneNextScene()
    local data = self.nextSceneData
    return data and (data.category or data.sceneName)
end

function MainMenu_Manager:GetBlockingSceneName()
    return self.blockingSceneName
end

MAIN_MENU_MANAGER = MainMenu_Manager:New()

local function OnGamepadPreferredModeChanged()
    MAIN_MENU_MANAGER:ClearBlockingSceneOnGamepadModeChange()
end

EVENT_MANAGER:RegisterForEvent("MainMenu_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadPreferredModeChanged)