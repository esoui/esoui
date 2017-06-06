local GAME_MENU_CHARACTERSELECT

local gameEntries = {}

-- Characters

local function ShowCharacterSelect()
    if(IsConsoleUI()) then  -- TODO integrate this with PC gamepad
        if(IsInGamepadPreferredMode()) then
            if(CHARACTER_SELECT_GAMEPAD_FRAGMENT ~= nil) then
                SCENE_MANAGER:AddFragment(CHARACTER_SELECT_GAMEPAD_FRAGMENT)
                return
            end
        end
    end

    if(CHARACTER_SELECT_FRAGMENT ~= nil) then
        SCENE_MANAGER:AddFragment(CHARACTER_SELECT_FRAGMENT)
    end
end

local function HideCharacterSelect()
    if(IsConsoleUI()) then  -- TODO integrate this with PC gamepad
        if(IsInGamepadPreferredMode()) then
            if(CHARACTER_SELECT_GAMEPAD_FRAGMENT ~= nil) then
                SCENE_MANAGER:RemoveFragment(CHARACTER_SELECT_GAMEPAD_FRAGMENT)
                return
            end
        end
    end

    if(CHARACTER_SELECT_FRAGMENT ~= nil) then
        SCENE_MANAGER:RemoveFragment(CHARACTER_SELECT_FRAGMENT)
    end
end

local function AddCharactersEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_CHARACTERS), callback = ShowCharacterSelect, unselectedCallback = HideCharacterSelect, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Settings

local function AddSettingsEntries(entryTable)
    local settingsHeaderData = {name = GetString(SI_GAME_MENU_SETTINGS)}
    table.insert(entryTable, settingsHeaderData)
end

-- Controls

local function AddControlsEntries(entryTable)
    -- Nothing for now
end

-- Addons

local function ShowAddons()
    ZO_CharacterSelect_SetupAddonManager()
    SCENE_MANAGER:AddFragment(ADDONS_FRAGMENT)
end

local function HideAddons()
    SCENE_MANAGER:RemoveFragment(ADDONS_FRAGMENT)
end

local function AddAddonsEntry(entryTable)
    local function ShouldShowNewIcon()
        return not HasViewedEULA(EULA_TYPE_ADDON_EULA)
    end

    local data = {name = GetString(SI_GAME_MENU_ADDONS), callback = ShowAddons, unselectedCallback = HideAddons, showNewIconCallback = ShouldShowNewIcon, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Play Cinematic

local function PlayCinematic()
    PregameStateManager_SetState("CharacterSelect_PlayCinematic")
end

local function AddCinematicEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_PLAY_CINEMATIC), callback = PlayCinematic }
    table.insert(entryTable, data)
end

-- Back

local function AddBackEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_BACK), callback = ZO_Disconnect}
    table.insert(entryTable, data)
end

-- Setup

local function RebuildTree(gameMenu)
    gameEntries = {}
    AddCharactersEntry(gameEntries)
    AddSettingsEntries(gameEntries)
    AddControlsEntries(gameEntries)
    AddAddonsEntry(gameEntries)
    AddCinematicEntry(gameEntries)
    AddBackEntry(gameEntries)
    gameMenu:SubmitLists(gameEntries)
end

local function OnShow(gameMenu)
    RebuildTree(gameMenu)
end

function ZO_GameMenu_CharacterSelect_Reset()
    SCENE_MANAGER:Show("gameMenuCharacterSelect")
    RebuildTree(GAME_MENU_CHARACTERSELECT)
end

function ZO_GameMenu_CharacterSelect_Initialize(self)
    GAME_MENU_CHARACTERSELECT = ZO_GameMenu_Initialize(self, OnShow)

    local gameMenuCharacterSelectFragment = ZO_FadeSceneFragment:New(self)
    local gameMenuCharacterSelectScene = ZO_Scene:New("gameMenuCharacterSelect", SCENE_MANAGER)
    gameMenuCharacterSelectScene:AddFragment(gameMenuCharacterSelectFragment)
 
    gameMenuCharacterSelectScene:RegisterCallback("StateChange",    function(oldState, newState)
                                                                        ZO_UpdatePaperDollManipulationForScene(ZO_CharacterSelectCharacterViewport, newState)
                                                                        if newState == SCENE_SHOWING then
                                                                            RebuildTree(GAME_MENU_CHARACTERSELECT)
                                                                        end
                                                                    end)

    local function UpdateNewStates()
        GAME_MENU_CHARACTERSELECT:RefreshNewStates()
    end

    CALLBACK_MANAGER:RegisterCallback("AddOnEULAHidden", UpdateNewStates)
end
