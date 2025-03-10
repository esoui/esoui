local gameEntries = {}

-- Resume Game

local function HideGameMenu()
    SCENE_MANAGER:Hide("gameMenuInGame")
end

local function AddResumeEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_RESUME), callback = HideGameMenu}
    table.insert(entryTable, data)
end

-- Settings

local function AddSettingsEntries(entryTable)
    local settingsHeaderData = {name = GetString(SI_GAME_MENU_SETTINGS)}
    table.insert(entryTable, settingsHeaderData)
end

-- Controls

local function ShowKeybindings()
    SCENE_MANAGER:AddFragment(KEYBINDINGS_FRAGMENT)
end

local function HideKeybindings()
    SCENE_MANAGER:RemoveFragment(KEYBINDINGS_FRAGMENT)
end

local function AddControlsEntries(entryTable)
    local keybindingsData = {name = GetString(SI_GAME_MENU_KEYBINDINGS), categoryName = GetString(SI_GAME_MENU_CONTROLS), callback = ShowKeybindings, unselectedCallback = HideKeybindings}
    table.insert(entryTable, keybindingsData)
end

-- Addons

local function ShowAddons()
    SCENE_MANAGER:AddFragment(ADDONS_FRAGMENT)
end

local function HideAddons()
    SCENE_MANAGER:RemoveFragment(ADDONS_FRAGMENT)
end

local function AddAddonsEntry(entryTable)
    if not AreUserAddOnsSupported() then
        return
    end

    local function ShouldShowNewIcon()
        return not HasViewedEULA(EULA_TYPE_ADDON_EULA)
    end

    local data = {name = GetString(SI_GAME_MENU_ADDONS), callback = ShowAddons, unselectedCallback = HideAddons, showNewIconCallback = ShouldShowNewIcon, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Login Announcements

local function ShowLoginAnnouncements()
    SCENE_MANAGER:Show("marketAnnouncement")
    RequestMarketAnnouncement()
end

local function AddLoginAnnouncementsEntry(entryTable)
    local data = {name = GetString(SI_MAIN_MENU_ANNOUNCEMENTS), callback = ShowLoginAnnouncements}
    table.insert(entryTable, data)
end

-- Logout

local function ShowLogoutDialog()
    if IsInGamepadPreferredMode() then
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_LOG_OUT", { quit = false })
    else
        ZO_Dialogs_ShowDialog("LOG_OUT")
    end
end

local function AddLogoutEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_LOGOUT), callback = ShowLogoutDialog}
    table.insert(entryTable, data)
end

-- Exit Game

local function ShowQuitDialog()
    ZO_Dialogs_ShowDialog("QUIT")
end

local function AddQuitEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_QUIT), callback = ShowQuitDialog}
    table.insert(entryTable, data)
end

-- Setup

local function RebuildTree(gameMenu)
    gameEntries = {}
    AddResumeEntry(gameEntries)
    AddSettingsEntries(gameEntries)
    AddControlsEntries(gameEntries)
    AddAddonsEntry(gameEntries)
    AddLoginAnnouncementsEntry(gameEntries)
    AddLogoutEntry(gameEntries)
    AddQuitEntry(gameEntries)
    gameMenu:SubmitLists(gameEntries)
end

function ZO_GameMenu_InGame_Initialize(self)
    local function OnShow(gameMenu)
        RebuildTree(gameMenu)
    end

    local function OnHide(gameMenu)
        -- do nothing
    end
    local GAME_MENU_INGAME = ZO_GameMenu_Initialize(self, OnShow, OnHide)

    local gameMenuIngameFragment = ZO_FadeSceneFragment:New(self)
    gameMenuIngameFragment:RegisterCallback("StateChange",   function(oldState, newState)
                                            if(newState == SCENE_FRAGMENT_SHOWING) then
                                                PushActionLayerByName("GameMenu")
                                            elseif(newState == SCENE_FRAGMENT_HIDING) then
                                                RemoveActionLayerByName("GameMenu")
                                            end
                                        end)

    GAME_MENU_SCENE = ZO_Scene:New("gameMenuInGame", SCENE_MANAGER)
    GAME_MENU_SCENE:AddFragment(gameMenuIngameFragment)

    local function UpdateNewStates()
        GAME_MENU_INGAME:RefreshNewStates()
    end

    CALLBACK_MANAGER:RegisterCallback("AddOnEULAHidden", UpdateNewStates)
end
