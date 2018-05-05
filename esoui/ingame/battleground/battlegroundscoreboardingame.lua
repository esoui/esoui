
--------------------------------------------
--Battleground Scoreboard In Game Scene
--------------------------------------------

ZO_Battleground_Scoreboard_In_Game = ZO_Object:Subclass()

function ZO_Battleground_Scoreboard_In_Game:New(...)
    local scoreboard = ZO_Object.New(self)
    scoreboard:Initialize(...)
    return scoreboard
end

function ZO_Battleground_Scoreboard_In_Game:Initialize(control)
    self.inGameTimer = control
    self.inGameTimerLabel = control:GetNamedChild("Timer")
    BATTLEGROUND_SCOREBOARD_IN_GAME_TIMER_FRAGMENT = ZO_SimpleSceneFragment:New(self.inGameTimer)

    BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE = ZO_Scene:New("battleground_scoreboard_in_game", SCENE_MANAGER)
    BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)
    BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:SetSceneRestoreHUDSceneToggleUIMode(true)
    BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:SetSceneRestoreHUDSceneToggleGameMenu(true)

    BATTLEGROUND_SCOREBOARD_IN_GAME_UI_SCENE = ZO_Scene:New("battleground_scoreboard_in_game_ui", SCENE_MANAGER)

    SYSTEMS:RegisterKeyboardRootScene("battleground_scoreboard_in_game", BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE)
    SYSTEMS:RegisterGamepadRootScene("battleground_scoreboard_in_game", BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE)

    local function OnGamepadModeChanged(eventId, isGamepadPreferred)
        self:CloseScoreboard()
    end

    EVENT_MANAGER:RegisterForEvent("BattlegroundScoreboardInGame", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadModeChanged)
    
    self:InitializeKeybindStrip()
    self:InitializePlatformStyle()
end

function ZO_Battleground_Scoreboard_In_Game:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Close
        {
            name = GetString(SI_BATTLEGROUND_SCOREBOARD_CLOSE),
            keybind = "HIDE_BATTLEGROUND_SCOREBOARD",
        
            callback = function()
                self:CloseScoreboard()
            end,
        },

        -- Leave Battleground
        {
            name = GetString(SI_BATTLEGROUND_SCOREBOARD_LEAVE_BATTLEGROUND),
            keybind = "LEAVE_BATTLEGROUND",
        
            callback = function()
                self:OnLeaveBattlegroundPressed()
            end,
        },
    }

    self.listNavigationKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        --Player Options
        {
            name = GetString(SI_BATTLEGROUND_SCOREBOARD_PLAYER_OPTIONS_KEYBIND),
            keybind = "BATTLEGROUND_SCOREBOARD_PLAYER_OPTIONS",
            visible = function()
                return IsInGamepadPreferredMode()
            end,
            callback = function()
                BATTLEGROUND_SCOREBOARD_FRAGMENT:ShowGamepadPlayerMenu()
            end,
        },

        -- Previous Entry Select
        {
            name = GetString(SI_BATTLEGROUND_SCOREBOARD_PREVIOUS_PLAYER_KEYBIND),
            keybind = "BATTLEGROUND_SCOREBOARD_PREVIOUS",
            callback = function()
                BATTLEGROUND_SCOREBOARD_FRAGMENT:SelectPreviousPlayerData()
            end,
        },

        -- Next Entry Select
        {
            name = GetString(SI_BATTLEGROUND_SCOREBOARD_NEXT_PLAYER_KEYBIND),
            keybind = "BATTLEGROUND_SCOREBOARD_NEXT",
            callback = function()
                BATTLEGROUND_SCOREBOARD_FRAGMENT:SelectNextPlayerData()
            end,
        },
    }
end

function ZO_Battleground_Scoreboard_In_Game:InitializePlatformStyle()
    self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end)
end

function ZO_Battleground_Scoreboard_In_Game:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.inGameTimer, ZO_GetPlatformTemplate("ZO_BattlegroundScoreboard_Timer"))
end

function ZO_Battleground_Scoreboard_In_Game:CloseScoreboard()
    if SCENE_MANAGER:IsShowing("battleground_scoreboard_in_game") or SCENE_MANAGER:IsShowing("battleground_scoreboard_in_game_ui") then
        BATTLEGROUND_SCOREBOARD_FRAGMENT:HideInGameScoreboard()
    end
end

function ZO_Battleground_Scoreboard_In_Game:OnLeaveBattlegroundPressed()
    ZO_Dialogs_ShowPlatformDialog("CONFIRM_LEAVE_BATTLEGROUND")
end

function ZO_Battleground_Scoreboard_In_Game:UpdateTimer()
    self.inGameTimerLabel:SetText(BATTLEGROUND_HUD_FRAGMENT:GetStateText())
end

function ZO_Battleground_Scoreboard_In_Game:OnShowing()
    self:SetupPreferredKeybindFragments()
    self:SetupKeybindStripDescriptorAlignment()
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.listNavigationKeybindStripDescriptor)
    self:UpdateTimer()
    self.inGameTimer:SetHandler("OnUpdate", function() self:UpdateTimer() end)
    self:RefreshMatchInfoFragments()
end

function ZO_Battleground_Scoreboard_In_Game:OnHidden()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.listNavigationKeybindStripDescriptor)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
    self.inGameTimer:SetHandler("OnUpdate", function() self:UpdateTimer() end)
end

function ZO_Battleground_Scoreboard_In_Game:SetupKeybindStripDescriptorAlignment()
    if IsInGamepadPreferredMode() then
        self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_LEFT
        self.listNavigationKeybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_LEFT
    else
        self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_RIGHT
        self.listNavigationKeybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
    end
end

function ZO_Battleground_Scoreboard_In_Game:SetupPreferredKeybindFragments()
    if IsInGamepadPreferredMode() then
        BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_KEYBIND_STRIP_GROUP)
        BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.KEYBOARD_KEYBIND_STRIP_GROUP)
    else
        BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:AddFragmentGroup(FRAGMENT_GROUP.KEYBOARD_KEYBIND_STRIP_GROUP)
        BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_KEYBIND_STRIP_GROUP)
    end
end

function ZO_Battleground_Scoreboard_In_Game:RefreshMatchInfoFragments()
    local groupToAdd, groupToRemove
    if IsInGamepadPreferredMode() then
        groupToAdd = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_GAMEPAD_GROUP
        groupToRemove = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_KEYBOARD_GROUP
    else
        groupToAdd = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_KEYBOARD_GROUP
        groupToRemove = FRAGMENT_GROUP.BATTLEGROUND_MATCH_INFO_GAMEPAD_GROUP
    end

    BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:RemoveFragmentGroup(groupToRemove)
    BATTLEGROUND_SCOREBOARD_IN_GAME_UI_SCENE:RemoveFragmentGroup(groupToRemove)
    BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE:AddFragmentGroup(groupToAdd)
    BATTLEGROUND_SCOREBOARD_IN_GAME_UI_SCENE:AddFragmentGroup(groupToAdd)
end

------------------
-- XML Functions
------------------

function ZO_Battleground_Scoreboard_In_Game_Timer_OnInitialize(control)
    ZO_BATTLEGROUND_SCOREBOARD_IN_GAME = ZO_Battleground_Scoreboard_In_Game:New(control)
end
