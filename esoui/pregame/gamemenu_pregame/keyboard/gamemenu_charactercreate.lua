local GAME_MENU_CHARACTERCREATE

local gameEntries = {}

-- Preview

local function SelectStartingGear()
    SelectClothing(DRESSING_OPTION_STARTING_GEAR)
    SCENE_MANAGER:AddFragment(CHARACTER_CREATE_FRAGMENT)
end

local function SelectVeteranGear()
    SelectClothing(DRESSING_OPTION_WARDROBE_1)
    SCENE_MANAGER:AddFragment(CHARACTER_CREATE_FRAGMENT)
end

local function SelectNoGear()
    SelectClothing(DRESSING_OPTION_NUDE)
    SCENE_MANAGER:AddFragment(CHARACTER_CREATE_FRAGMENT)
end

local function HideCharacterCreate()
    SCENE_MANAGER:RemoveFragment(CHARACTER_CREATE_FRAGMENT)
end

local function AddPreviewEntries(entryTable)
    local startingGearOption = {name = GetString("SI_CHARACTERCREATEDRESSINGOPTION", DRESSING_OPTION_STARTING_GEAR), categoryName = GetString(SI_GAME_MENU_PREVIEW), callback = SelectStartingGear, unselectedCallback = HideCharacterCreate}
    table.insert(entryTable, startingGearOption)

    local veteranGearOption = {name = GetString("SI_CHARACTERCREATEDRESSINGOPTION", DRESSING_OPTION_WARDROBE_1), categoryName = GetString(SI_GAME_MENU_PREVIEW), callback = SelectVeteranGear, unselectedCallback = HideCharacterCreate}
    table.insert(entryTable, veteranGearOption)

    local nudeOption = {name = GetString("SI_CHARACTERCREATEDRESSINGOPTION", DRESSING_OPTION_NUDE), categoryName = GetString(SI_GAME_MENU_PREVIEW), callback = SelectNoGear, unselectedCallback = HideCharacterCreate}
    table.insert(entryTable, nudeOption)
end

-- Settings

local function AddSettingsEntries(entryTable)
    local settingsHeaderData = {name = GetString(SI_GAME_MENU_SETTINGS)}
    table.insert(entryTable, settingsHeaderData)
end

-- Back

function GoBack()
    if(GetNumCharacters() > 0) then
        PregameStateManager_SetState("CharacterSelect_FromIngame")
    else
        PregameStateManager_SetState("Disconnect")
    end
end

local function AddBackEntry(entryTable)
    local backString
    if(GetNumCharacters() > 0) then
        backString = GetString(SI_GAME_MENU_BACK)
    else
        backString = GetString(SI_GAME_MENU_LOGOUT)
    end

    local data = {name = backString, callback = GoBack}
    table.insert(entryTable, data)
end

-- Setup

local function RebuildTree(gameMenu)
    gameEntries = {}
    AddPreviewEntries(gameEntries)
    AddSettingsEntries(gameEntries)
    AddBackEntry(gameEntries)
    gameMenu:SubmitLists(gameEntries)
end

local function OnShow(gameMenu)
    RebuildTree(gameMenu)
end

function ZO_GameMenu_CharacterCreate_Initialize(self)
    GAME_MENU_CHARACTERCREATE = ZO_GameMenu_Initialize(self, OnShow)

    local gameMenuCharacterCreateFragment = ZO_FadeSceneFragment:New(self)
    local gameMenuCharacterCreateScene = ZO_Scene:New("gameMenuCharacterCreate", SCENE_MANAGER)
    gameMenuCharacterCreateScene:AddFragment(gameMenuCharacterCreateFragment)
 
    gameMenuCharacterCreateScene:RegisterCallback("StateChange",    function(oldState, newState)
                                                                        ZO_UpdatePaperDollManipulationForScene(ZO_CharacterCreateCharacterViewport, newState)
                                                                    end)
end
