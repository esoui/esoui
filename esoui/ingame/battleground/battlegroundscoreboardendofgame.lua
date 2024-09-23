
--------------------------------------------
--Battleground Scoreboard End Of Game Scene
--------------------------------------------

local LEAVE_BATTLEGROUND_KEYBIND_COOLDOWN_MS = 2000

local KEYBIND_BUTTON_SPACING_X = 10

ZO_Battleground_Scoreboard_End_Of_Game = ZO_InitializingObject:Subclass()

function ZO_Battleground_Scoreboard_End_Of_Game:Initialize(control)
    self.control = control
    self.closingTimerLabel = control:GetNamedChild("ClosingTimer")

    self:InitializeKeybinds()
    self:InitializePlatformStyle()

    BATTLEGROUND_SCOREBOARD_END_OF_GAME_OPTIONS = ZO_HUDFadeSceneFragment:New(control)

    BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE = ZO_Scene:New("battleground_scoreboard_end_of_game", SCENE_MANAGER)
    BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        end
    end)

    -- the loot history fragments may not exist depending on the platform
    if GAMEPAD_LOOT_HISTORY_FRAGMENT then
        BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE:AddFragment(GAMEPAD_LOOT_HISTORY_FRAGMENT)
    end
    if KEYBOARD_LOOT_HISTORY_FRAGMENT then
        BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE:AddFragment(KEYBOARD_LOOT_HISTORY_FRAGMENT)
    end

    local function OnGamepadModeChanged()
        self:RefreshMatchInfoFragments()
        -- End game doesn't close the UI when gamepad mode switches, but it shares the same fragment as in game,
        -- so only in end game do we want to make sure that the match info gets refreshed on switching fragments
        BATTLEGROUND_SCOREBOARD_FRAGMENT:RefreshMatchInfoDisplay()
    end

    local function OnBattlegroundStateChanged(eventId, previousState, currentState)
        -- prevent people from accidentally leaving the BG because they are fighting to the bitter end
        if currentState == BATTLEGROUND_STATE_FINISHED and IsInGamepadPreferredMode() then
            self.leaveBattlegroundKeybind:SetCooldown(LEAVE_BATTLEGROUND_KEYBIND_COOLDOWN_MS)
        end
    end

    EVENT_MANAGER:RegisterForEvent("BattlegroundScoreboardEndOfGame", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadModeChanged)
    EVENT_MANAGER:RegisterForEvent("BattlegroundScoreboardEndOfGame", EVENT_BATTLEGROUND_STATE_CHANGED, OnBattlegroundStateChanged)

    SYSTEMS:RegisterKeyboardRootScene("battleground_scoreboard_end_of_game", BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE)
    SYSTEMS:RegisterGamepadRootScene("battleground_scoreboard_end_of_game", BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE)
    self.scene = BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE
    SCENE_MANAGER:SetSceneRestoresBaseSceneOnGameMenuToggle("battleground_scoreboard_end_of_game", true)
end

function ZO_Battleground_Scoreboard_End_Of_Game:InitializeKeybinds()
    local keybindContainer = self.control:GetNamedChild("KeybindContainer")

    self.keybindNameTextMap = {}
    self.keybindActionMap = {}
    local keybindButtonIndex = 1
    local previousKeybindControl
    local function CreateKeybindButton(keybind, callbackFunction, text)
        -- Make and anchor the button
        local keybindControl = CreateControlFromVirtual("$(parent)KeybindButton" .. keybindButtonIndex, keybindContainer, "ZO_KeybindButton")
        ZO_KeybindButtonTemplate_Setup(keybindControl, keybind, callbackFunction, text)
        if previousKeybindControl then
            keybindControl:SetAnchor(LEFT, previousKeybindControl, RIGHT, KEYBIND_BUTTON_SPACING_X, 0)
        else
            keybindControl:SetAnchor(TOPLEFT)
        end

        -- Keep track of the control for gamepad switching
        keybindControl.nameLabel = keybindControl:GetNamedChild("NameLabel")
        self.keybindNameTextMap[keybindControl] = text

        -- Keep track of the keybind mapping to handle the key being pressed
        self.keybindActionMap[keybind] = keybindControl

        keybindButtonIndex = keybindButtonIndex + 1
        previousKeybindControl = keybindControl
        return keybindControl
    end

    self.playerOptionsButton = CreateKeybindButton("BATTLEGROUND_SCOREBOARD_PLAYER_OPTIONS", function() BATTLEGROUND_SCOREBOARD_FRAGMENT:ShowGamepadPlayerMenu() end, GetString(SI_BATTLEGROUND_SCOREBOARD_PLAYER_OPTIONS_KEYBIND))
    self.leaveBattlegroundKeybind = CreateKeybindButton("LEAVE_BATTLEGROUND", function() self:OnLeaveBattlegroundPressed() end, GetString(SI_BATTLEGROUND_SCOREBOARD_END_OF_GAME_LEAVE_KEYBIND))
    self.previousPlayerButton = CreateKeybindButton("BATTLEGROUND_SCOREBOARD_PREVIOUS", function() BATTLEGROUND_SCOREBOARD_FRAGMENT:SelectPreviousPlayerData() end, GetString(SI_BATTLEGROUND_SCOREBOARD_PREVIOUS_PLAYER_KEYBIND))
    self.nextPlayerButton = CreateKeybindButton("BATTLEGROUND_SCOREBOARD_NEXT", function() BATTLEGROUND_SCOREBOARD_FRAGMENT:SelectNextPlayerData() end, GetString(SI_BATTLEGROUND_SCOREBOARD_NEXT_PLAYER_KEYBIND))
end

function ZO_Battleground_Scoreboard_End_Of_Game:GetKeybindsNarrationData()
    local narrationData = {}

    local playerOptionsNarrationData = self.playerOptionsButton:GetKeybindButtonNarrationData()
    if playerOptionsNarrationData then
        table.insert(narrationData, playerOptionsNarrationData)
    end

    local leaveBattlegroundNarrationData = self.leaveBattlegroundKeybind:GetKeybindButtonNarrationData() 
    if leaveBattlegroundNarrationData then
        table.insert(narrationData, leaveBattlegroundNarrationData)
    end

    local previousPlayerNarrationData = self.previousPlayerButton:GetKeybindButtonNarrationData()
    if previousPlayerNarrationData then
        table.insert(narrationData, previousPlayerNarrationData)
    end

    local nextPlayerNarrationData = self.nextPlayerButton:GetKeybindButtonNarrationData()
    if nextPlayerNarrationData then
        table.insert(narrationData, nextPlayerNarrationData)
    end

    return narrationData
end

do
    local KEYBOARD_PLATFORM_STYLE = 
    {
        timerFont = "ZoFontWinH2",
        keybindButtonTemplate = "ZO_KeybindButton_Keyboard_Template",
        hasPlayerOptionsButton = false,
    }

    local GAMEPAD_PLATFORM_STYLE = 
    {
        timerFont = "ZoFontGamepad42",
        keybindButtonTemplate = "ZO_KeybindButton_Gamepad_Template",
        hasPlayerOptionsButton = true,
    }

    function ZO_Battleground_Scoreboard_End_Of_Game:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_PLATFORM_STYLE, GAMEPAD_PLATFORM_STYLE)
    end
end

function ZO_Battleground_Scoreboard_End_Of_Game:ApplyPlatformStyle(style)
    self.closingTimerLabel:SetFont(style.timerFont)
    for keybindButton, nameText in pairs(self.keybindNameTextMap) do
        ApplyTemplateToControl(keybindButton, style.keybindButtonTemplate)
        -- We need this because of modifyTextType
        keybindButton.nameLabel:SetText(nameText)
    end

    self.playerOptionsButton:SetHidden(not style.hasPlayerOptionsButton)
    self.playerOptionsButton:SetEnabled(style.hasPlayerOptionsButton)

    self.leaveBattlegroundKeybind:ClearAnchors()
    if style.hasPlayerOptionsButton then
        self.leaveBattlegroundKeybind:SetAnchor(LEFT, self.playerOptionsButton, RIGHT, KEYBIND_BUTTON_SPACING_X, 0)
    else
        self.leaveBattlegroundKeybind:SetAnchor(TOPLEFT)
    end
end

function ZO_Battleground_Scoreboard_End_Of_Game:OnShowing()
    self:RefreshMatchInfoFragments()
end

function ZO_Battleground_Scoreboard_End_Of_Game:RefreshMatchInfoFragments()
    local groupToAdd, groupToRemove
    if IsInGamepadPreferredMode() then
        groupToAdd = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_GAMEPAD_GROUP
        groupToRemove = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_KEYBOARD_GROUP
    else
        groupToAdd = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_KEYBOARD_GROUP
        groupToRemove = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_GAMEPAD_GROUP
    end

    BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE:RemoveFragmentGroup(groupToRemove)
    BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE:AddFragmentGroup(groupToAdd)
end

function ZO_Battleground_Scoreboard_End_Of_Game:OnLeaveBattlegroundPressed()
    if self.scene:IsShowing() then
        PlaySound(SOUNDS.BATTLEGROUND_LEAVE_MATCH)
        LeaveBattleground()
    end
end

function ZO_Battleground_Scoreboard_End_Of_Game:OnKeybindDown(keybind)
    if self.scene:IsShowing() then
        local keybindButton = self.keybindActionMap[keybind]
        if keybindButton and keybindButton:IsEnabled() then
            keybindButton:OnClicked()
            return true
        end
    end
    return false
end

--[[ xml functions ]]--

function ZO_BattlegroundScoreboardEndOfGameTopLevel_Initialize(control)
    BATTLEGROUND_SCOREBOARD_END_OF_GAME = ZO_Battleground_Scoreboard_End_Of_Game:New(control)
end