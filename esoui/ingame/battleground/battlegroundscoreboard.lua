ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH = 36
ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT = 30
ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH_KEYBOARD = ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH + 59
ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT_KEYBOARD = ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT + 63

ZO_BATTLEGROUND_SCOREBOARD_OFFSET_Y_KEYBOARD = 40

ZO_BATTLEGROUND_SCOREBOARD_HEADER_WIDTH = 902
ZO_BATTLEGROUND_SCOREBOARD_HEADER_HEIGHT = 40
ZO_BATTLEGROUND_SCOREBOARD_HEADER_PADDING = 5
ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING = ZO_BATTLEGROUND_SCOREBOARD_HEADER_PADDING * 2

ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_WIDTH = 48
ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_HEIGHT = ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_WIDTH

ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_OFFSET_X = 28
ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_WIDTH = 240 - ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_OFFSET_X
ZO_BATTLEGROUND_SCOREBOARD_HEADER_USER_ID_WIDTH = 280
ZO_BATTLEGROUND_SCOREBOARD_HEADER_MEDALS_WIDTH = 180
ZO_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_WIDTH = 50
ZO_BATTLEGROUND_SCOREBOARD_HEADER_ASSISTS_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_WIDTH
ZO_BATTLEGROUND_SCOREBOARD_HEADER_DEATHS_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_WIDTH

ZO_BATTLEGROUND_SCOREBOARD_PANEL_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_WIDTH
ZO_BATTLEGROUND_SCOREBOARD_PANEL_HEIGHT = 234


ZO_BATTLEGROUND_SCOREBOARD_PANEL_NAME_OFFSET_X = -20
ZO_BATTLEGROUND_SCOREBOARD_PANEL_NAME_OFFSET_Y = 15
ZO_BATTLEGROUND_SCOREBOARD_PANEL_NAME_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING - ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_PANEL_NAME_OFFSET_X + ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_OFFSET_X
ZO_BATTLEGROUND_SCOREBOARD_PANEL_SCORE_OFFSET_Y = 0

ZO_BATTLEGROUND_SCOREBOARD_PANEL_OFFSET_Y = 10

ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_INITIAL_OFFSET_X = ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_INITIAL_OFFSET_Y = 20
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_OFFSET_Y = 10
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE = 100
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDALS_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_MEDALS_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDALS_OFFSET_X = ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE/2 + ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_USER_ID_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_USER_ID_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE/2
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MIN = 0
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MAX = 1
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MOUSE_OVER_MAX = .5
local TIME_FOR_FULL_HIGHLIGHT_ALPHA_S = .255
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_PER_SECOND = 1 / TIME_FOR_FULL_HIGHLIGHT_ALPHA_S
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_NAVIGATION_THROTTLE_MS = 25

ZO_BATTLEGROUND_SCOREBOARD_BACKGROUND_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH * 2
ZO_BATTLEGROUND_SCOREBOARD_BACKGROUND_HEIGHT = ZO_BATTLEGROUND_SCOREBOARD_PANEL_HEIGHT * 3 + ZO_BATTLEGROUND_SCOREBOARD_HEADER_HEIGHT + ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT * 2

ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_PADDING = 20
ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_OFFSET_X = -ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_PADDING
ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_BACKGROUND_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_PADDING * 2

local ANIMATE_PLAYER_ROW_HIGHLIGHT = true
local DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT = false
local FORCE_REFRESH_PLAYER_SELECTION = true

-----------------------------------
--Battleground Scoreboard_Manager
-----------------------------------

local Battleground_Scoreboard_Fragment = ZO_HUDFadeSceneFragment:Subclass()

function Battleground_Scoreboard_Fragment:New(...)
    return ZO_HUDFadeSceneFragment.New(self, ...)
end

function Battleground_Scoreboard_Fragment:Initialize(control)
    ZO_HUDFadeSceneFragment.Initialize(self, control)
    self.gamepadBackground = control:GetNamedChild("BackgroundsGamepad")
    self.keyboardBackground = control:GetNamedChild("BackgroundsKeyboard")
    self.headers = control:GetNamedChild("Headers")
    self.userIdHeaderLabel = self.headers:GetNamedChild("UserId")

    self.currentBattlegroundId = 0
    self.currentBattlegroundScoreThreshold = 0
    self.playMatchResultSound = false

    self.alliancePanels = {}
    self.playerEntryData = {}

    for i = BATTLEGROUND_ALLIANCE_ITERATION_BEGIN, BATTLEGROUND_ALLIANCE_ITERATION_END do
        local alliancePanelControl = CreateControlFromVirtual("$(parent)AlliancePanel", control, "ZO_Battleground_Scoreboard_Alliance_Panel", i)
        local alliancePanel = Battleground_Scoreboard_Alliance_Panel:New(alliancePanelControl, i)
        self.alliancePanels[i] = alliancePanel
        alliancePanel.scoreboard = self
    end

    self:InitializePlatformStyle()

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:UpdateBattlegroundStatus() end)
    control:RegisterForEvent(EVENT_GROUPING_TOOLS_LFG_JOINED, function() self:UpdateBattlegroundStatus() end)
    control:RegisterForEvent(EVENT_ZONE_SCORING_CHANGED, function() self:UpdateAll() end)
    control:RegisterForEvent(EVENT_BATTLEGROUND_STATE_CHANGED, function(_, ...) self:OnBattlegroundStateChanged(...) end)
    control:RegisterForEvent(EVENT_BATTLEGROUND_SCOREBOARD_UPDATED, function() self:UpdateAll() end)
    control:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, function(_, ...) self:OnInterfaceSettingChanged(...) end)
    control:AddFilterForEvent(EVENT_INTERFACE_SETTING_CHANGED, REGISTER_FILTER_SETTING_SYSTEM_TYPE, SETTING_TYPE_UI)

    control:SetHandler("OnUpdate", function(...) self:OnUpdate(...) end)

    self:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            if self.dirty then
                self:UpdateAll()
            end
        end
    end)

    self:UpdateAll()
end

do
    local KEYBOARD_PLATFORM_STYLE =
    {
        useKeyboardBackground = true,
        topLevel = "ZO_BattlegroundScoreboardTopLevel_Keyboard_Template",
        headers = "ZO_Battleground_Scoreboard_Headers_Keyboard_Template",
        alliancePanel = "ZO_Battleground_Scoreboard_Alliance_Panel_Keyboard_Template",
        playerRow = "ZO_Battleground_Scoreboard_Player_Row_Keyboard_Template",
        teamNameFonts =
        {
            {
                font = "ZoFontHeader3",
            },
            {
                font = "ZoFontHeader4",
            },
        }
    }

    local GAMEPAD_PLATFORM_STYLE =
    {
        useGamepadBackground = true,
        topLevel = "ZO_BattlegroundScoreboardTopLevel_Gamepad_Template",
        headers = "ZO_Battleground_Scoreboard_Headers_Gamepad_Template",
        alliancePanel = "ZO_Battleground_Scoreboard_Alliance_Panel_Gamepad_Template",
        playerRow = "ZO_Battleground_Scoreboard_Player_Row_Gamepad_Template",
        teamNameFonts =
        {
            {
                font = "ZoFontGamepad36",
            },
            {
                font = "ZoFontGamepad27",
            },
        }

    }

    function Battleground_Scoreboard_Fragment:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_PLATFORM_STYLE, GAMEPAD_PLATFORM_STYLE)
    end
end

function Battleground_Scoreboard_Fragment:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style.topLevel)
    ApplyTemplateToControl(self.headers, style.headers)
    self.gamepadBackground:SetHidden(not style.useGamepadBackground)
    self.keyboardBackground:SetHidden(not style.useKeyboardBackground)
    for i = BATTLEGROUND_ALLIANCE_ITERATION_BEGIN, BATTLEGROUND_ALLIANCE_ITERATION_END do
        self.alliancePanels[i]:ApplyPlatformStyle(style)
    end
    self:UpdateAll()
end

function Battleground_Scoreboard_Fragment:OnUpdate(control, timeS)
    if self.lastUpdateS then
        local deltaS = timeS - self.lastUpdateS
        for battlegroundAlliance, alliancePanel in pairs(self.alliancePanels) do
            alliancePanel:OnUpdate(deltaS)
        end
    end
    self.lastUpdateS = timeS
end

do
    local BATTLEGROUND_ALLIANCE_SORT_ORDER =
    {
        BATTLEGROUND_ALLIANCE_PIT_DAEMONS,
        BATTLEGROUND_ALLIANCE_STORM_LORDS,
        BATTLEGROUND_ALLIANCE_FIRE_DRAKES
    }

    local KEYED_BATTLEGROUND_ALLIANCE_SORT_ORDER = {}
    for index, alliance in ipairs(BATTLEGROUND_ALLIANCE_SORT_ORDER) do
        KEYED_BATTLEGROUND_ALLIANCE_SORT_ORDER[alliance] = index
    end

    local function SortPlayerData(leftData, rightData)
        local leftAllianceSortOrder = KEYED_BATTLEGROUND_ALLIANCE_SORT_ORDER[leftData.battlegroundAlliance]
        local rightAllianceSortOrder = KEYED_BATTLEGROUND_ALLIANCE_SORT_ORDER[rightData.battlegroundAlliance]
        if leftAllianceSortOrder == rightAllianceSortOrder then
            if leftData.medalScore == rightData.medalScore then
                if leftData.deaths == rightData.deaths then
                    return leftData.kills > rightData.kills
                else
                    return leftData.deaths < rightData.deaths
                end
            else
                return leftData.medalScore > rightData.medalScore
            end
        else
            return leftAllianceSortOrder < rightAllianceSortOrder
        end
    end

    function Battleground_Scoreboard_Fragment:UpdateAll()
        if not self:IsShowing() then
            self.dirty = true
            return 
        end

        self.userIdHeaderLabel:SetText(ZO_GetPrimaryPlayerNameHeader())

        self:PreUpdatePanels()
        self:RebuildPlayerData()
        self:AddPlayerRows()
        self:PostUpdatePanels()
        self:UpdateAnchors()

        if self.playMatchResultSound then
            local playerAlliance = GetUnitBattlegroundAlliance("player")

            alliancePanel = self.alliancePanels[playerAlliance]
            local playerTeamWon = alliancePanel:GetScore() == self.highestPanelScore
            if playerTeamWon then
                PlaySound(SOUNDS.BATTLEGROUND_MATCH_WON)
            else
                PlaySound(SOUNDS.BATTLEGROUND_MATCH_LOST)
            end

            self.playMatchResultSound = false
        end

        self.dirty = false
    end

    function Battleground_Scoreboard_Fragment:PreUpdatePanels()
        self.highestPanelScore = 0

        for battlegroundAlliance, alliancePanel in pairs(self.alliancePanels) do
            alliancePanel:PreUpdatePanel()
            local panelScore = alliancePanel:GetScore()
            if panelScore > self.highestPanelScore then
                self.highestPanelScore = panelScore
            end
        end
    end

    function Battleground_Scoreboard_Fragment:RebuildPlayerData()
        ZO_ClearNumericallyIndexedTable(self.playerEntryData)

        local numScoreboardEntries = GetNumScoreboardEntries()
        for entryIndex = 1, numScoreboardEntries do
            local characterName, displayName, battlegroundAlliance, isLocalPlayer = GetScoreboardEntryInfo(entryIndex)
            local playerEntry =
            {
                entryIndex = entryIndex,
                battlegroundAlliance = battlegroundAlliance,
                medalScore = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_SCORE),
                kills = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_KILL),
                deaths = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_DEATH),
                assists = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_ASSISTS),
                characterName = characterName,
                displayName = displayName,
                isLocalPlayer = isLocalPlayer,
                isSelected = false,
                currentHighlightAlpha = 0,
                targetHighlightAlpha = 0,
                mustFinishHighlightAnimation = false
            }
            table.insert(self.playerEntryData, playerEntry)
        end

        table.sort(self.playerEntryData, SortPlayerData)

        if numScoreboardEntries > 1 then
            -- Used for ease of navigation through the list
            for i, data in ipairs(self.playerEntryData) do
                data.previousData = self.playerEntryData[i - 1]
                data.nextData = self.playerEntryData[i % numScoreboardEntries + 1]
            end
            self.playerEntryData[1].previousData = self.playerEntryData[numScoreboardEntries]
        end
    end

    function Battleground_Scoreboard_Fragment:AddPlayerRows()
        local wasPlayerRowReselected = false

        for i, data in ipairs(self.playerEntryData) do
            self.alliancePanels[data.battlegroundAlliance]:AddPlayer(data)
            
            local selectedPlayerData = self.selectedPlayerData
            if selectedPlayerData and selectedPlayerData.characterName == data.characterName then
                data.currentHighlightAlpha = selectedPlayerData.currentHighlightAlpha
                data.targetHighlightAlpha = selectedPlayerData.targetHighlightAlpha
                data.mustFinishHighlightAnimation = selectedPlayerData.mustFinishHighlightAnimation
                self:SetSelectedPlayerData(data, DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT, FORCE_REFRESH_PLAYER_SELECTION)
                wasPlayerRowReselected = true
            end
        end

        if not wasPlayerRowReselected then
            self:SelectDefaultPlayerRow(DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT, FORCE_REFRESH_PLAYER_SELECTION)
        end
    end

    function Battleground_Scoreboard_Fragment:PostUpdatePanels()
        for battlegroundAlliance, alliancePanel in pairs(self.alliancePanels) do
            alliancePanel:PostUpdatePanel(self.highestPanelScore)
        end
    end

    function Battleground_Scoreboard_Fragment:UpdateAnchors()
        local previousControl = self.headers
        for _, bgOrder in ipairs(BATTLEGROUND_ALLIANCE_SORT_ORDER) do
            local currentPanel = self.alliancePanels[bgOrder]
            local control = currentPanel.control
            control:ClearAnchors()
            control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, ZO_BATTLEGROUND_SCOREBOARD_PANEL_OFFSET_Y)

            previousControl = control
        end
    end
end

function Battleground_Scoreboard_Fragment:OnBattlegroundStateChanged(previousState, currentState)
    if currentState == BATTLEGROUND_STATE_POSTGAME then
        SCENE_MANAGER:SetHUDScene("battleground_scoreboard_end_of_game")
        SCENE_MANAGER:SetHUDUIScene("battleground_scoreboard_end_of_game", true)
        self.playMatchResultSound = true
    elseif previousState == BATTLEGROUND_STATE_POSTGAME then
        SCENE_MANAGER:RestoreHUDScene()
        SCENE_MANAGER:RestoreHUDUIScene()
        self.playMatchResultSound = false
    end
end

function Battleground_Scoreboard_Fragment:OnInterfaceSettingChanged(settingSystemType, settingId)
    if settingId == UI_SETTING_PRIMARY_PLAYER_NAME_KEYBOARD or settingId == UI_SETTING_PRIMARY_PLAYER_NAME_GAMEPAD then
        self:UpdateAll()
    end
end

function Battleground_Scoreboard_Fragment:UpdateBattlegroundStatus()
    if IsActiveWorldBattleground() then
        if GetCurrentBattlegroundState() == BATTLEGROUND_STATE_POSTGAME and GetCurrentBattlegroundStateTimeRemaining() > 0 then
            -- in case someone reloads their UI while in postgame, 
            -- we want to continue showing the postgame scoreboard when they load back in
            SCENE_MANAGER:SetHUDScene("battleground_scoreboard_end_of_game")
            SCENE_MANAGER:SetHUDUIScene("battleground_scoreboard_end_of_game", true)
        end
        self.currentBattlegroundId = GetCurrentBattlegroundId()
        self.currentBattlegroundScoreThreshold = GetScoreToWinBattleground(self.currentBattlegroundId)

        self:UpdateAll()
    else
        self.currentBattlegroundId = 0
        self.currentBattlegroundScoreThreshold = 0
    end
end

function Battleground_Scoreboard_Fragment:OnHUDButtonPressedDown()
    if GetCurrentBattlegroundState() ~= BATTLEGROUND_STATE_POSTGAME then
        SCENE_MANAGER:SetHUDScene("battleground_scoreboard_in_game")
        local HIDES_AUTOMATICALLY = true
        SCENE_MANAGER:SetHUDUIScene("battleground_scoreboard_in_game_ui", HIDES_AUTOMATICALLY)
    end
end

function Battleground_Scoreboard_Fragment:HideInGameScoreboard()
    SCENE_MANAGER:RestoreHUDScene()
    SCENE_MANAGER:RestoreHUDUIScene()
end

function Battleground_Scoreboard_Fragment:GetCurrentBattlegroundId()
    return self.currentBattlegroundId
end

function Battleground_Scoreboard_Fragment:GetCurrentBattlegroundScoreThreshold()
    return self.currentBattlegroundScoreThreshold
end

function Battleground_Scoreboard_Fragment:GetPlayerDataByEntryIndex(entryIndex)
    for _, data in ipairs(self.playerEntryData) do
        if data.entryIndex == entryIndex then
            return data
        end
    end
end

function Battleground_Scoreboard_Fragment:SetSelectedPlayerData(newPlayerData, animate, forceRefresh)
    local oldPlayerData = self.selectedPlayerData
    if oldPlayerData ~= newPlayerData or forceRefresh then
        if not animate then
            if oldPlayerData then
                oldPlayerData.rowObject:ForceHighlightAlpha(ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MIN)
            end
            if newPlayerData then
                newPlayerData.rowObject:ForceHighlightAlpha(ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MAX)
            end
        end
        if oldPlayerData then
            oldPlayerData.isSelected = false
        end
        if newPlayerData then
            newPlayerData.isSelected = true
        end

        self.selectedPlayerData = newPlayerData

        self:RefreshMatchInfoDisplay()
    end
end

function Battleground_Scoreboard_Fragment:SelectDefaultPlayerRow(animate, forceRefreshPlayerSelection)
    local playerIndex = GetScoreboardPlayerEntryIndex()
    local data = self:GetPlayerDataByEntryIndex(playerIndex)
    self:SetSelectedPlayerData(data, animate, forceRefreshPlayerSelection)
end

function Battleground_Scoreboard_Fragment:CanCyclePlayerSelection()
    local now = GetFrameTimeMilliseconds()
    if not self.playerNavigationThrottleNextUpdateMs or self.playerNavigationThrottleNextUpdateMs < now then
        self.playerNavigationThrottleNextUpdateMs = now + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_NAVIGATION_THROTTLE_MS
        return true
    end
    return false
end

function Battleground_Scoreboard_Fragment:SelectPreviousPlayerData()
    if self.selectedPlayerData and self.selectedPlayerData.previousData and self:CanCyclePlayerSelection() then
        self:SetSelectedPlayerData(self.selectedPlayerData.previousData, ANIMATE_PLAYER_ROW_HIGHLIGHT)
    end
end

function Battleground_Scoreboard_Fragment:SelectNextPlayerData()
    if self.selectedPlayerData and self.selectedPlayerData.nextData and self:CanCyclePlayerSelection() then
        self:SetSelectedPlayerData(self.selectedPlayerData.nextData, ANIMATE_PLAYER_ROW_HIGHLIGHT)
    end
end

do
    local Battleground_Scoreboard_SocialOptionsDialogGamepad = ZO_SocialOptionsDialogGamepad:Subclass()

    function Battleground_Scoreboard_SocialOptionsDialogGamepad:New(control)
        local object = ZO_SocialOptionsDialogGamepad.New(self)
        object:Initialize(control)
        return object
    end

    function Battleground_Scoreboard_SocialOptionsDialogGamepad:BuildOptionsList()
        local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    
        self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
        self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption)
        self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
        self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption, ZO_SocialOptionsDialogGamepad.ShouldAddSendMailOption)
        self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsNotPlayer)
    end

    function Battleground_Scoreboard_Fragment:ShowGamepadPlayerMenu()
        if self.selectedPlayerData then
            if not self.socialOptionsDialogGamepad then
                self.socialOptionsDialogGamepad = Battleground_Scoreboard_SocialOptionsDialogGamepad:New(self.control)
            end
            self.socialOptionsDialogGamepad:SetupOptions(self.selectedPlayerData)
            self.socialOptionsDialogGamepad:ShowOptionsDialog()
        end
    end
end

function Battleground_Scoreboard_Fragment:ShowKeyboardPlayerMenu(anchorToControl)
    ClearMenu()

    if self.selectedPlayerData then
        local data = self.selectedPlayerData
        if IsChatSystemAvailableForCurrentPlatform() then
            AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE), function() StartChatInput("", CHAT_CHANNEL_WHISPER, data.displayName) end)
        end

        if not data.isLocalPlayer then
            if not IsFriend(data.displayName) then
                AddMenuItem(GetString(SI_SOCIAL_MENU_ADD_FRIEND), function() ZO_Dialogs_ShowDialog("REQUEST_FRIEND", {name = data.displayName}) end)
            end

            local function SendMailCallback()
                if not IsUnitDead("player") then
                    MAIL_SEND:ComposeMailTo(data.displayName)
                else
                    ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
                end
            end
            AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), SendMailCallback)

            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(data.displayName) end)
        end

        ShowMenu(anchorToControl)
    end
end

function Battleground_Scoreboard_Fragment:RefreshMatchInfoDisplay()
    if self:IsShowing() and self.selectedPlayerData then
        SYSTEMS:GetObject("matchInfo"):SetupForScoreboardEntry(self.selectedPlayerData.entryIndex)
    end
end

function Battleground_Scoreboard_Fragment:Show(...)
    self:SelectDefaultPlayerRow(DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT, FORCE_REFRESH_PLAYER_SELECTION)

    ZO_HUDFadeSceneFragment.Show(self, ...)

    self:RefreshMatchInfoDisplay()
end

------------------------------
-- Scoreboard Alliance Panel
------------------------------

Battleground_Scoreboard_Alliance_Panel = ZO_Object:Subclass()

function Battleground_Scoreboard_Alliance_Panel:New(...)
    local alliancePanel = ZO_Object.New(self)
    alliancePanel:Initialize(...)
    return alliancePanel
end


function Battleground_Scoreboard_Alliance_Panel:Initialize(control, battlegroundAlliance)
    self.control = control
    self.bgControl = control:GetNamedChild("Bg")
    self.nameControl = control:GetNamedChild("Name")
    self.iconControl = control:GetNamedChild("NameIcon")
    self.scoreControl = control:GetNamedChild("Score")
    self.battlegroundAlliance = battlegroundAlliance
    self.score = 0

    self.iconControl:SetTexture(GetLargeBattlegroundAllianceSymbolIcon(battlegroundAlliance))
    self.nameControl:SetText(zo_strformat(SI_ALLIANCE_NAME, GetString("SI_BATTLEGROUNDALLIANCE", battlegroundAlliance)))

    local function PlayerRowFactory(pool)
        local playerRowControl = ZO_ObjectPool_CreateNamedControl("$(parent)PlayerRow", "ZO_Battleground_Scoreboard_Player_Row", pool, self.control)
        return Battleground_Scoreboard_Player_Row:New(playerRowControl)
    end

    local function PlayerRowReset(playerRow)
        playerRow:Reset()
    end

    self.playerRowPool = ZO_ObjectPool:New(PlayerRowFactory, PlayerRowReset)
    self.sortedPlayerRows = {}
end
    
do
    local BATTLEGROUND_ALLIANCE_TO_BG_TEXTURE =
    {
        [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_orange.dds",
        [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_green.dds",
        [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_purple.dds",
    }

    function Battleground_Scoreboard_Alliance_Panel:ApplyPlatformStyle(style)
        ApplyTemplateToControl(self.control, style.alliancePanel)
        if IsInGamepadPreferredMode() then
            self.bgControl:SetColor(GetBattlegroundAllianceColor(self.battlegroundAlliance):UnpackRGBA())
            self.bgControl:SetTexture("")
        else
            self.bgControl:SetTexture(BATTLEGROUND_ALLIANCE_TO_BG_TEXTURE[self.battlegroundAlliance])
        end

        for _, playerRow in ipairs(self.sortedPlayerRows) do
            playerRow:ApplyPlatformStyle(style.playerRow)
        end

        ZO_FontAdjustingWrapLabel_OnInitialized(self.nameControl, style.teamNameFonts, TEXT_WRAP_MODE_ELLIPSIS)
    end
end

function Battleground_Scoreboard_Alliance_Panel:OnUpdate(deltaS)
    for _, playerRow in ipairs(self.sortedPlayerRows) do
        playerRow:OnUpdate(deltaS)
    end
end

function Battleground_Scoreboard_Alliance_Panel:UpdateAnchors()
    local previousControl
    for _, playerRow in ipairs(self.sortedPlayerRows) do
        local control = playerRow.control
        control:ClearAnchors()
        if previousControl then
            control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_OFFSET_Y)
        else
            control:SetAnchor(TOPLEFT, self.control, TOPLEFT, ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_INITIAL_OFFSET_X, ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_INITIAL_OFFSET_Y)
        end

        previousControl = control
    end
end

function Battleground_Scoreboard_Alliance_Panel:PreUpdatePanel()
    self:UpdateScore()

    -- prep for new entries after panel update
    self:RemoveAllPlayers()
end

function Battleground_Scoreboard_Alliance_Panel:PostUpdatePanel(highestScore)
    self:UpdateScoreColor(highestScore)
    self:UpdateAnchors()

    for _, playerRow in ipairs(self.sortedPlayerRows) do
        playerRow:UpdateRow()
    end
end

function Battleground_Scoreboard_Alliance_Panel:UpdateScore()
    self.score = GetCurrentBattlegroundScore(self.battlegroundAlliance)
    
    self.scoreControl:SetText(self.score)
end

function Battleground_Scoreboard_Alliance_Panel:UpdateScoreColor(highestScore)
    if GetCurrentBattlegroundState() == BATTLEGROUND_STATE_POSTGAME and self.score ~= 0 and self.score >= highestScore then
        self.scoreControl:SetColor(ZO_BATTLEGROUND_WINNER_TEXT:UnpackRGB())
    else
        self.scoreControl:SetColor(ZO_WHITE:UnpackRGB())
    end
end

function Battleground_Scoreboard_Alliance_Panel:AddPlayer(data)
    local playerRow, key = self.playerRowPool:AcquireObject()
    playerRow:SetupOnAcquire(self, key, data)
    table.insert(self.sortedPlayerRows, playerRow)
    return playerRow
end

function Battleground_Scoreboard_Alliance_Panel:RemoveAllPlayers()
    self.playerRowPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.sortedPlayerRows)
end

function Battleground_Scoreboard_Alliance_Panel:GetScore()
    return self.score
end

function Battleground_Scoreboard_Alliance_Panel:GetBattlegroundAlliance()
    return self.battlegroundAlliance
end

function Battleground_Scoreboard_Alliance_Panel:GetTopPlayerRow()
    return self.sortedPlayerRows[1]
end

function Battleground_Scoreboard_Alliance_Panel:GetBottomPlayerRow()
    return self.sortedPlayerRows[#self.sortedPlayerRows]
end

------------------------------
-- Scoreboard Player Row
------------------------------

Battleground_Scoreboard_Player_Row = ZO_Object:Subclass()

function Battleground_Scoreboard_Player_Row:New(...)
    local playerRow = ZO_Object.New(self)
    playerRow:Initialize(...)
    return playerRow
end

function Battleground_Scoreboard_Player_Row:Initialize(control)
    self.control = control
    self.control.owner = self
    self.nameLabel = control:GetNamedChild("Name")
    self.medalScoreLabel = control:GetNamedChild("MedalScore")
    self.killsLabel = control:GetNamedChild("Kills")
    self.assistsLabel = control:GetNamedChild("Assists")
    self.deathsLabel = control:GetNamedChild("Deaths")
    self.highlight = control:GetNamedChild("Highlight")
    self.highlight.keyboardTexture = self.highlight:GetNamedChild("Keyboard")
    self.highlight.gamepadBackdrop = self.highlight:GetNamedChild("Gamepad")
end

do
    local HIGHLIGHT_KEYBOARD_TEXTURES =
    {
        [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboard_highlightStrip_orange.dds",
        [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboard_highlightStrip_purple.dds",
        [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboard_highlightStrip_green.dds",
    }

    function Battleground_Scoreboard_Player_Row:SetupOnAcquire(panel, poolKey, data)
        self.control:SetHidden(false)
        self.key = poolKey
        self.panel = panel
        self.data = data
        self:ApplyPlatformStyle(ZO_GetPlatformTemplate("ZO_Battleground_Scoreboard_Player_Row"))
        local battlegroundAlliance = self.panel:GetBattlegroundAlliance()
        self.highlight.keyboardTexture:SetTexture(HIGHLIGHT_KEYBOARD_TEXTURES[battlegroundAlliance])
        self.highlight.gamepadBackdrop:SetEdgeColor(GetBattlegroundAllianceColor(battlegroundAlliance):UnpackRGB())
        self.isMouseOver = false
        self.highlight:SetAlpha(0)
        data.rowObject = self
    end
end

function Battleground_Scoreboard_Player_Row:Reset()
    local playerRowControl = self.control
    playerRowControl:ClearAnchors()
    playerRowControl:SetHidden(true)
end

function Battleground_Scoreboard_Player_Row:GetData()
    return self.data
end

function Battleground_Scoreboard_Player_Row:GetPanel()
    return self.panel
end

function Battleground_Scoreboard_Player_Row:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style)
end

function Battleground_Scoreboard_Player_Row:OnUpdate(deltaS)
    -- Update the highlight alpha
    local data = self.data
    local targetHighlightAlpha = data.targetHighlightAlpha
    local currentHighlightAlpha = data.currentHighlightAlpha
    local mustFinishHighlightAnimation = data.mustFinishHighlightAnimation

    local canSetNewTargetAlpha = true
    if mustFinishHighlightAnimation then
        if zo_floatsAreEqual(targetHighlightAlpha, currentHighlightAlpha) then
            mustFinishHighlightAnimation = false
        else
            canSetNewTargetAlpha = false
        end
    end

    if canSetNewTargetAlpha then
        -- Determine the target alpha
        if data.isSelected then
            targetHighlightAlpha = ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MAX
        elseif self.isMouseOver then
            --Once the highlight has reached its target, determine the next target
            targetHighlightAlpha = ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MOUSE_OVER_MAX
            mustFinishHighlightAnimation = true
        else
            targetHighlightAlpha = ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MIN
        end
    end

    if not zo_floatsAreEqual(targetHighlightAlpha, currentHighlightAlpha) then
        local nextHighlightAlpha = currentHighlightAlpha
        if targetHighlightAlpha > currentHighlightAlpha then
            nextHighlightAlpha = zo_min(targetHighlightAlpha, currentHighlightAlpha + deltaS * ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_PER_SECOND)
        else
            nextHighlightAlpha = zo_max(targetHighlightAlpha, currentHighlightAlpha - deltaS * ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_PER_SECOND)
        end
        self.highlight:SetAlpha(nextHighlightAlpha)
        data.currentHighlightAlpha = nextHighlightAlpha
    end

    data.targetHighlightAlpha = targetHighlightAlpha
    data.mustFinishHighlightAnimation = mustFinishHighlightAnimation
end

function Battleground_Scoreboard_Player_Row:UpdateRow()
    local data = self.data

    local primaryName = ZO_GetPrimaryPlayerName(data.displayName, data.characterName)
    local formattedName = zo_strformat(SI_PLAYER_NAME, primaryName)
    self.nameLabel:SetText(formattedName)
    self.medalScoreLabel:SetText(data.medalScore)
    self.killsLabel:SetText(data.kills)
    self.deathsLabel:SetText(data.deaths)
    self.assistsLabel:SetText(data.assists)

    local r, g, b
    if data.isLocalPlayer then
        r, g, b = ZO_SELECTED_TEXT:UnpackRGB()
    else
        r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
    end
    self.nameLabel:SetColor(r, g, b)
    self.medalScoreLabel:SetColor(r, g, b)
    self.killsLabel:SetColor(r, g, b)
    self.deathsLabel:SetColor(r, g, b)
    self.assistsLabel:SetColor(r, g, b)
end

function Battleground_Scoreboard_Player_Row:GetCharacterName()
    return self.characterName
end

function Battleground_Scoreboard_Player_Row:GetHighlight()
    return self.highlight
end

function Battleground_Scoreboard_Player_Row:ForceHighlightAlpha(alpha)
    self.highlight:SetAlpha(alpha)
    self.data.currentHighlightAlpha = alpha
    self.data.targetHighlightAlpha = alpha
end

function Battleground_Scoreboard_Player_Row:SetMouseOver(isMouseOver)
    self.isMouseOver = isMouseOver
end

function ZO_Battleground_Scoreboard_Player_Row_OnMouseDown(control, button)
    BATTLEGROUND_SCOREBOARD_FRAGMENT:SetSelectedPlayerData(control.owner:GetData(), ANIMATE_PLAYER_ROW_HIGHLIGHT)
    if button == MOUSE_BUTTON_INDEX_RIGHT then
        BATTLEGROUND_SCOREBOARD_FRAGMENT:ShowKeyboardPlayerMenu(control)
    end
end

--[[ xml functions ]]--

function ZO_BattlegroundScoreboardTopLevel_Initialize(control)
    BATTLEGROUND_SCOREBOARD_FRAGMENT = Battleground_Scoreboard_Fragment:New(control)
end