local GAME_MENU_CHARACTERSELECT

local gameEntries = {}

-- Characters

local function ShowCharacterSelect()
    if PregameIsFullyLoaded() then
        SCENE_MANAGER:AddFragment(CHARACTER_SELECT_FRAGMENT)
    else
        CALLBACK_MANAGER:RegisterCallback("PregameFullyLoaded", function() SCENE_MANAGER:AddFragment(CHARACTER_SELECT_FRAGMENT) end)
    end
    local esoPlus = GAME_MENU_CHARACTERSELECT:GetControl():GetNamedChild("ESOPlus")
    esoPlus:SetHidden(IsESOPlusSubscriber())
end

local function HideCharacterSelect()
    SCENE_MANAGER:RemoveFragment(CHARACTER_SELECT_FRAGMENT)
    local esoPlus = GAME_MENU_CHARACTERSELECT:GetControl():GetNamedChild("ESOPlus")
    esoPlus:SetHidden(true)
end

local function AddCharactersEntry(entryTable)
    local data =
    {
        name = GetString(SI_GAME_MENU_CHARACTERS),
        callback = ShowCharacterSelect,
        unselectedCallback = HideCharacterSelect,
        hasSelectedState = true
    }
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
    if not AreUserAddOnsSupported() then
        return
    end

    local function ShouldShowNewIcon()
        return not HasViewedEULA(EULA_TYPE_ADDON_EULA)
    end

    local data = {name = GetString(SI_GAME_MENU_ADDONS), callback = ShowAddons, unselectedCallback = HideAddons, showNewIconCallback = ShouldShowNewIcon, hasSelectedState = true}
    table.insert(entryTable, data)
end

-- Play Cinematic

local function AddCinematicEntry(entryTable)
    local data = {name = GetString(SI_GAME_MENU_PLAY_CINEMATIC), callback = ZO_PlayIntroCinematicAndReturn }
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

function ZO_GameMenu_CharacterSelect_Initialize(control)
    GAME_MENU_CHARACTERSELECT = ZO_GameMenu_Initialize(control, OnShow)

    local gameMenuCharacterSelectFragment = ZO_FadeSceneFragment:New(control)
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
