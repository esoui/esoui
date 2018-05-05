local GAME_MENU_PREGAME
local g_pregameMenuControl

local gameEntries = {}

-- Play

local function ShowLogin()
    LOGIN_MANAGER_KEYBOARD:ShowRelevantLoginFragment()
    SCENE_MANAGER:AddFragment(LOGIN_BG_FRAGMENT)
end

local function HideLogin()
    LOGIN_MANAGER_KEYBOARD:HideShowingLoginFragment()
end

local function AddPlayEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_PLAY), callback = ShowLogin, unselectedCallback = HideLogin, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Server Select

local function ShowServerSelect()
    --Makes sure the login stuff is in the background when selecting your server.
    ShowLogin()
    ZO_Dialogs_ShowDialog("SERVER_SELECT_DIALOG", {isIntro = false, onClosed = ZO_GameMenu_PreGame_Reset})
end

local function AddServerEntry(entryTable)
    local currentServer = GetCVar("LastPlatform")

    currentServer = ZO_GetLocalizedServerName(currentServer)

    local data = {name = zo_strformat(SI_GAME_MENU_SERVER, currentServer), callback = ShowServerSelect, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Settings

local function AddSettingsEntries(entryTable)
    local settingsHeaderData = {name = GetString(SI_GAME_MENU_SETTINGS)}
    table.insert(entryTable, settingsHeaderData)
end

-- Credits

local function ShowCredits()
    g_pregameMenuControl:SetHidden(true)
    SCENE_MANAGER:AddFragment(GAME_CREDITS_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(LOGIN_BG_FRAGMENT)
end

local function AddCreditsEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_CREDITS), callback = ShowCredits, unselectedCallback = nil, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Quit

local function AddQuitEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_QUIT), callback = PregameQuit, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Setup

local function RebuildTree(gameMenu)
    gameEntries = {}
    AddPlayEntry(gameEntries)
    if DoesPlatformSelectServer() then
        AddServerEntry(gameEntries)
    end
    AddSettingsEntries(gameEntries)
    AddCreditsEntry(gameEntries)
    AddQuitEntry(gameEntries)
    gameMenu:SubmitLists(gameEntries)
    SCENE_MANAGER:AddFragment(LOGIN_BG_FRAGMENT)
end

local function OnShow(gameMenu)    
    RebuildTree(gameMenu)
end

function ZO_GameMenu_PreGame_Reset()
    g_pregameMenuControl:SetHidden(false)
    SCENE_MANAGER:Show("gameMenuPregame")
    RebuildTree(GAME_MENU_PREGAME)
    --ZO_Login_BeginSlideShow()
end

function ZO_GameMenu_PreGame_Initialize(self)
    g_pregameMenuControl = self
    GAME_MENU_PREGAME = ZO_GameMenu_Initialize(self, OnShow)

    local gameMenuPregameFragment = ZO_FadeSceneFragment:New(self)
    local gameMenuPregameScene = ZO_Scene:New("gameMenuPregame", SCENE_MANAGER)
    gameMenuPregameScene:AddFragment(gameMenuPregameFragment)
    gameMenuPregameScene:AddFragment(PREGAME_SLIDE_SHOW_FRAGMENT)
end
