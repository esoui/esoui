ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH = 36
ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT = 30
ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH_KEYBOARD = ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH + 59
ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT_KEYBOARD = ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT + 63

ZO_BATTLEGROUND_SCOREBOARD_HEADER_WIDTH = 902
ZO_BATTLEGROUND_SCOREBOARD_HEADER_HEIGHT = 90
ZO_BATTLEGROUND_SCOREBOARD_HEADER_PADDING = 5
ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING = ZO_BATTLEGROUND_SCOREBOARD_HEADER_PADDING * 2

ZO_BATTLEGROUND_SCOREBOARD_PANEL_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH * 2
ZO_BATTLEGROUND_SCOREBOARD_PANEL_HEIGHT = 220
ZO_BATTLEGROUND_SCOREBOARD_LARGE_PANEL_HEIGHT_KEYBOARD = 330
ZO_BATTLEGROUND_SCOREBOARD_LARGE_PANEL_HEIGHT_GAMEPAD = 350

ZO_BATTLEGROUND_SCOREBOARD_BACKGROUND_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_PANEL_WIDTH
ZO_BATTLEGROUND_SCOREBOARD_BACKGROUND_HEIGHT = ZO_BATTLEGROUND_SCOREBOARD_PANEL_HEIGHT * 3 + ZO_BATTLEGROUND_SCOREBOARD_HEADER_HEIGHT + ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT * 2

ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_WIDTH = 48
ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_HEIGHT = ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_WIDTH

ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_OFFSET_X = 28
ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_WIDTH = 188 - ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_OFFSET_X
ZO_BATTLEGROUND_SCOREBOARD_HEADER_USER_ID_WIDTH = 280
ZO_BATTLEGROUND_SCOREBOARD_HEADER_MEDALS_WIDTH = 180
ZO_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_WIDTH = 50
ZO_BATTLEGROUND_SCOREBOARD_HEADER_ASSISTS_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_WIDTH
ZO_BATTLEGROUND_SCOREBOARD_HEADER_DEATHS_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_WIDTH

ZO_BATTLEGROUND_SCOREBOARD_PANEL_NAME_OFFSET_Y = 15
ZO_BATTLEGROUND_SCOREBOARD_PANEL_NAME_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING - ZO_BATTLEGROUND_SCOREBOARD_PANEL_ALLIANCE_ICON_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE_OFFSET_X
ZO_BATTLEGROUND_SCOREBOARD_PANEL_SCORE_OFFSET_Y = 0

ZO_BATTLEGROUND_SCOREBOARD_PANEL_OFFSET_Y = 10

ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_INITIAL_OFFSET_Y = 20
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_OFFSET_Y = 10
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_LIVES_WIDTH = 30
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE = 100
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDALS_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_MEDALS_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDALS_OFFSET_X = ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE / 2 + ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_USER_ID_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_HEADER_USER_ID_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDAL_USER_ID_DIFFERENCE / 2
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_LIVES_WIDTH
                                                + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_USER_ID_WIDTH
                                                + ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING
                                                + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDALS_WIDTH
                                                + ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING
                                                + ZO_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_WIDTH
                                                + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_MEDALS_OFFSET_X
                                                + ZO_BATTLEGROUND_SCOREBOARD_HEADER_DEATHS_WIDTH
                                                + ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING
                                                + ZO_BATTLEGROUND_SCOREBOARD_HEADER_ASSISTS_WIDTH
                                                + ZO_BATTLEGROUND_SCOREBOARD_HEADER_DOUBLE_PADDING

ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MIN = 0
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MAX = 1
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_MOUSE_OVER_MAX = 0.5
local TIME_FOR_FULL_HIGHLIGHT_ALPHA_S = 0.255
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HIGHLIGHT_ALPHA_PER_SECOND = 1 / TIME_FOR_FULL_HIGHLIGHT_ALPHA_S
ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_NAVIGATION_THROTTLE_MS = 25

ZO_BATTLEGROUND_SCOREBOARD_PANEL_CONTAINER_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_PANEL_WIDTH + ZO_SCROLL_BAR_WIDTH
ZO_BATTLEGROUND_SCOREBOARD_PANEL_CONTAINER_MAX_HEIGHT = ZO_BATTLEGROUND_SCOREBOARD_PANEL_HEIGHT * 3 + ZO_BATTLEGROUND_SCOREBOARD_PANEL_OFFSET_Y * 2
ZO_BATTLEGROUND_SCOREBOARD_PANEL_CONTAINER_OFFSET_X = -2

ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_PADDING = 20
ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_OFFSET_X = -ZO_BATTLEGROUND_SCOREBOARD_PADDING_WIDTH + ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_PADDING
ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_WIDTH = ZO_BATTLEGROUND_SCOREBOARD_BACKGROUND_WIDTH - ZO_BATTLEGROUND_SCOREBOARD_PANEL_BG_PADDING * 2

local BACKGROUND_DEFAULT_OFFSET_Y = -20
local BACKGROUND_ROUNDS_OFFSET_Y = -117

local ANIMATE_PLAYER_ROW_HIGHLIGHT = true
local DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT = false
local FORCE_REFRESH_PLAYER_SELECTION = true

-----------------------------------
--Battleground Scoreboard Fragment
-----------------------------------

local Battleground_Scoreboard_Fragment = ZO_HUDFadeSceneFragment:Subclass()

function Battleground_Scoreboard_Fragment:New(...)
    return ZO_HUDFadeSceneFragment.New(self, ...)
end

function Battleground_Scoreboard_Fragment:Initialize(control)
    ZO_HUDFadeSceneFragment.Initialize(self, control)
    self.backgroundsContainer = control:GetNamedChild("Backgrounds")
    self.gamepadBackground = self.backgroundsContainer:GetNamedChild("Gamepad")
    self.keyboardBackground = self.backgroundsContainer:GetNamedChild("Keyboard")
    self.headers = control:GetNamedChild("Headers")
    self.headerMainTitleLabel = self.headers:GetNamedChild("MainTitle")
    self.headerExtraTitleLabel = self.headers:GetNamedChild("ExtraTitle")
    self.headerAdditionalInfoLabel = self.headers:GetNamedChild("AdditionalInfo")
    self.livesHeaderControl = self.headers:GetNamedChild("Lives")
    self.userIdHeaderLabel = self.headers:GetNamedChild("UserId")

    self.panelContainer = control:GetNamedChild("PanelContainer")
    self.panelContainerScrollChild = self.panelContainer:GetNamedChild("ScrollChild")

    local anchorRelativeTo = RIGHT
    local offsetX = -3
    local offsetY = 0
    ZO_ScrollContainer_Shared.SetScrollIndicatorAnchor(self.panelContainer, self.gamepadBackground, anchorRelativeTo, offsetX, offsetY)

    self.roundsControl = control:GetNamedChild("Rounds")
    self.roundSummary = ZO_BattlegroundScoreboardRoundIndicator:New(self.roundsControl, self)

    self.currentBattlegroundId = 0
    self.playMatchResultSound = false

    self.teamPanels = {}
    self.playerEntryData = {}

    for i = BATTLEGROUND_TEAM_ITERATION_BEGIN, BATTLEGROUND_TEAM_ITERATION_END do
        local teamPanelControl = CreateControlFromVirtual("$(parent)TeamPanel", self.panelContainerScrollChild, "ZO_Battleground_Scoreboard_Team_Panel", i)
        local teamPanel = ZO_Battleground_Scoreboard_Team_Panel_Object:New(teamPanelControl, i)
        self.teamPanels[i] = teamPanel
    end

    self:InitializePlatformStyle()
    self:InitializeNarrationInfo()

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:UpdateBattlegroundStatus() end)
    control:RegisterForEvent(EVENT_GROUPING_TOOLS_LFG_JOINED, function() self:UpdateBattlegroundStatus() end)
    control:RegisterForEvent(EVENT_BATTLEGROUND_RULESET_CHANGED, function() self:UpdateBattlegroundStatus() end)
    control:RegisterForEvent(EVENT_ZONE_SCORING_CHANGED, function() self:UpdateAll() end)
    control:RegisterForEvent(EVENT_BATTLEGROUND_STATE_CHANGED, function(_, ...) self:OnBattlegroundStateChanged(...) end)
    control:RegisterForEvent(EVENT_BATTLEGROUND_SCOREBOARD_UPDATED, function() self:UpdateAll() end)
    control:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, function(_, ...) self:OnInterfaceSettingChanged(...) end)
    control:AddFilterForEvent(EVENT_INTERFACE_SETTING_CHANGED, REGISTER_FILTER_SETTING_SYSTEM_TYPE, SETTING_TYPE_UI)

    control:SetHandler("OnUpdate", function(...) self:OnUpdate(...) end)

    self:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.viewedRound = GetCurrentBattlegroundRoundIndex()
            self.showAggregateScores = false
            self.dirty = true

            if self.dirty then
                self:UpdateAll()
            end
            local NARRATE_HEADER = true
            SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.customNarrationObjectName, NARRATE_HEADER)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            ClearNarrationQueue(NARRATION_TYPE_HUD)
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
        teamPanel = "ZO_Battleground_Scoreboard_Team_Panel_Keyboard_Template",
        playerRow = "ZO_Battleground_Scoreboard_Player_Row_Keyboard_Template",
        initialPlayerRowOffsetX = 250,
        roundsControlOffsetY = -65,
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
        teamPanel = "ZO_Battleground_Scoreboard_Team_Panel_Gamepad_Template",
        playerRow = "ZO_Battleground_Scoreboard_Player_Row_Gamepad_Template",
        initialPlayerRowOffsetX = 246,
        roundsControlOffsetY = -5,
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

    self.panelContainer:SetScrollIndicatorEnabled(IsInGamepadPreferredMode())

    self.gamepadBackground:SetHidden(not style.useGamepadBackground)
    self.keyboardBackground:SetHidden(not style.useKeyboardBackground)
    for battlegroundTeam, teamPanel in pairs(self.teamPanels) do
        teamPanel:ApplyPlatformStyle(style)
    end

    self.roundsControl:ClearAnchors()
    self.roundsControl:SetAnchor(TOP, self.backgroundsContainer, BOTTOM, 0, style.roundsControlOffsetY)

    self:UpdateAll()
end

function Battleground_Scoreboard_Fragment:InitializeNarrationInfo()
    self.customNarrationObjectName = "BattlegroundsScoreboard"

    local narrationInfo =
    {
        narrationType = NARRATION_TYPE_HUD,
        canNarrate = function()
            return self:IsShowing()
        end,
        headerNarrationFunction = function()
            local narrations = {}

            local gameType = GetBattlegroundGameType(self.currentBattlegroundId, self.viewedRound)
            local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", gameType)
            local hasRounds = DoesBattlegroundHaveRounds(self.currentBattlegroundId)
            if self:ShouldShowAggregateScores() then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_SCOREBOARD_HEADER_MATCH_RESULTS_NARRATION)))
                local resultString = SI_BATTLEGROUND_SCOREBOARD_HEADER_DEFEAT_TITLE
                local playerTeam = GetUnitBattlegroundTeam("player")
                local playerTeamBattlegroundResult = GetBattlegroundResultForTeam(playerTeam)
                local playerTeamWon = playerTeamBattlegroundResult == BATTLEGROUND_RESULT_WIN or playerTeamBattlegroundResult == BATTLEGROUND_RESULT_TIE
                if playerTeamWon then
                    resultString = SI_BATTLEGROUND_SCOREBOARD_HEADER_VICTORY_TITLE
                end
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(resultString)))
            elseif hasRounds then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_BATTLEGROUND_SCOREBOARD_HEADER_ROUND_TITLE, self.viewedRound)))
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(gameTypeString))

            local additionalInfoLabelNarrationText = nil
            if self:IsViewingCurrentRound() or self:ShouldShowAggregateScores() then
                if IsCurrentBattlegroundStateTimed() then
                    local currentBattlegroundTimeMS = GetCurrentBattlegroundStateTimeRemaining()
                    local formattedTime = ZO_FormatTime(zo_ceil(currentBattlegroundTimeMS / 1000), TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
                    formattedTime = ZO_SELECTED_TEXT:Colorize(formattedTime)

                    local battlegroundState = GetCurrentBattlegroundState()
                    if battlegroundState == BATTLEGROUND_STATE_PREROUND then
                        additionalInfoLabelNarrationText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_WAITING_FOR_PLAYERS_TIMER_NARRATION_FORMAT, formattedTime)
                    elseif battlegroundState == BATTLEGROUND_STATE_STARTING then
                        additionalInfoLabelNarrationText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_STARTING_TIMER_NARRATION_FORMAT, formattedTime)
                    elseif battlegroundState == BATTLEGROUND_STATE_RUNNING then
                        additionalInfoLabelNarrationText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_IN_PROGRESS_TIMER_NARRATION_FORMAT, formattedTime)
                    elseif battlegroundState == BATTLEGROUND_STATE_POSTROUND then
                        additionalInfoLabelNarrationText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_ROUND_ENDING_TIMER_NARRATION_FORMAT, formattedTime)
                    elseif battlegroundState == BATTLEGROUND_STATE_FINISHED then
                        additionalInfoLabelNarrationText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_MATCH_ENDING_TIMER_NARRATION_FORMAT, formattedTime)
                    else
                        additionalInfoLabelNarrationText = formattedTime
                    end
                end
            else
                local roundResult = GetCurrentBattlegroundRoundResult(self.viewedRound)
                additionalInfoLabelNarrationText = GetString("SI_BATTLEGROUNDROUNDRESULT", roundResult)
            end

            if additionalInfoLabelNarrationText then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(additionalInfoLabelNarrationText))
            end

            return narrations
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            local selectedData = self.selectedPlayerData

            -- Team Info for Selected Row
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_BATTLEGROUNDTEAM", selectedData.battlegroundTeam)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_SCOREBOARD_HEADER_TEAM_SCORE)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.teamPanels[selectedData.battlegroundTeam]:GetScore()))

            -- Selected Row
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_GetPrimaryPlayerNameHeader()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.displayName))
            if selectedData.showLives then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_SCOREBOARD_HEADER_REMAINING_LIVES_NARRATION)))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.lives))
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_SCORETRACKERENTRYTYPE", SCORE_TRACKER_TYPE_SCORE)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.medalScore))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_SCOREBOARD_HEADER_KILLS_NARRATION)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.kills))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_SCOREBOARD_HEADER_DEATHS_NARRATION)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.assists))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_SCOREBOARD_HEADER_ASSISTS_NARRATION)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.deaths))

            -- Selection Side Panel
            local matchInfo = SYSTEMS:GetObject("matchInfo")

            -- Header
            local classId = GetScoreboardEntryClassId(selectedData.entryIndex, selectedData.roundIndex)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_CLASS_NAME, GetClassName(GENDER_MALE, classId))))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.displayName))
            if self:ShouldShowAggregateScores() or not DoesBattlegroundHaveRounds(self.currentBattlegroundId) then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_MATCH_INFO_PANEL_TITLE)))
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_MATCH_INFO_ROUND_PANEL_TITLE)))
            end

            -- Stats
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(matchInfo.damageDealtLabelText))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(matchInfo.scoreRowValueTable[SCORE_TRACKER_TYPE_DAMAGE_DONE]))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(matchInfo.healingLabelText))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(matchInfo.scoreRowValueTable[SCORE_TRACKER_TYPE_HEALING_DONE]))

            -- Medals
            local numMedals = matchInfo.scoreboardEntryRawMedalData and #matchInfo.scoreboardEntryRawMedalData or 0
            if numMedals > 0 then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_MATCH_INFO_PANEL_MEDALS_HEADER)))
                for i = 1, numMedals do
                    local medalData = matchInfo.scoreboardEntryRawMedalData[i]
                    if medalData then
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(medalData.name))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(medalData.count))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_BATTLEGROUND_SCOREBOARD_POINTS_FORMATTER_NARRATION, medalData.count * medalData.scoreReward)))
                    end
                end
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_MATCH_INFO_PANEL_NO_MEDALS_TEXT)))
            end

            return narrations
        end,
        additionalInputNarrationFunction = function()
            local narrations = {}
            if BATTLEGROUND_SCOREBOARD_END_OF_GAME.scene:IsShowing() then
                ZO_CombineNumericallyIndexedTables(narrations, BATTLEGROUND_SCOREBOARD_END_OF_GAME:GetKeybindsNarrationData())
            end
            if self.roundSummary:IsVisible() then
                ZO_CombineNumericallyIndexedTables(narrations, self.roundSummary:GetKeybindsNarrationData())
            end

            return narrations
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject(self.customNarrationObjectName, narrationInfo)
end

function Battleground_Scoreboard_Fragment:OnUpdate(control, timeS)
    if self.lastUpdateS then
        self:UpdateHeaderAdditionalInfo()
        local deltaS = timeS - self.lastUpdateS
        for _, teamPanel in pairs(self.teamPanels) do
            teamPanel:OnUpdate(deltaS)
        end
    end
    self.lastUpdateS = timeS
end

do
    local BATTLEGROUND_TEAM_SORT_ORDER =
    {
        BATTLEGROUND_TEAM_PIT_DAEMONS,
        BATTLEGROUND_TEAM_STORM_LORDS,
        BATTLEGROUND_TEAM_FIRE_DRAKES
    }

    local KEYED_BATTLEGROUND_TEAM_SORT_ORDER = {}
    for index, team in ipairs(BATTLEGROUND_TEAM_SORT_ORDER) do
        KEYED_BATTLEGROUND_TEAM_SORT_ORDER[team] = index
    end

    local function SortPlayerData(leftData, rightData)
        local leftTeamSortOrder = KEYED_BATTLEGROUND_TEAM_SORT_ORDER[leftData.battlegroundTeam]
        local rightTeamSortOrder = KEYED_BATTLEGROUND_TEAM_SORT_ORDER[rightData.battlegroundTeam]
        if leftTeamSortOrder == rightTeamSortOrder then
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
            return leftTeamSortOrder < rightTeamSortOrder
        end
    end

    function Battleground_Scoreboard_Fragment:UpdateHeaderAdditionalInfo()
        if self:IsViewingCurrentRound() or self:ShouldShowAggregateScores() then
            if IsCurrentBattlegroundStateTimed() then
                local currentBattlegroundTimeMS = GetCurrentBattlegroundStateTimeRemaining()
                local formattedTime = ZO_FormatTime(zo_ceil(currentBattlegroundTimeMS / 1000), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
                formattedTime = ZO_SELECTED_TEXT:Colorize(formattedTime)

                local headerText = formattedTime
                local battlegroundState = GetCurrentBattlegroundState()
                if battlegroundState == BATTLEGROUND_STATE_PREROUND then
                    headerText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_WAITING_FOR_PLAYERS_TIMER_FORMAT, formattedTime)
                elseif battlegroundState == BATTLEGROUND_STATE_STARTING then
                    headerText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_STARTING_TIMER_FORMAT, formattedTime)
                elseif battlegroundState == BATTLEGROUND_STATE_RUNNING then
                    -- No additional text/formatting, just timer
                elseif battlegroundState == BATTLEGROUND_STATE_POSTROUND then
                    headerText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_ROUND_ENDING_TIMER_FORMAT, formattedTime)
                elseif battlegroundState == BATTLEGROUND_STATE_FINISHED then
                    headerText = zo_strformat(SI_BATTLEGROUND_SCOREBOARD_MATCH_ENDING_TIMER_FORMAT, formattedTime)
                end

                self.headerAdditionalInfoLabel:SetHidden(false)
                self.headerAdditionalInfoLabel:SetText(headerText)
                self.headerAdditionalInfoLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            else
                self.headerAdditionalInfoLabel:SetHidden(true)
            end
        else
            local roundResult = GetCurrentBattlegroundRoundResult(self.viewedRound)
            local roundResultText = GetString("SI_BATTLEGROUNDROUNDRESULT", roundResult)
            self.headerAdditionalInfoLabel:SetHidden(false)
            self.headerAdditionalInfoLabel:SetText(roundResultText)
            self.headerAdditionalInfoLabel:SetColor(ZO_BATTLEGROUND_WINNER_TEXT:UnpackRGBA())
        end
    end

    function Battleground_Scoreboard_Fragment:UpdateAll()
        if not self:IsShowing() then
            self.dirty = true
            return
        end

        local gameType = GetBattlegroundGameType(self.currentBattlegroundId, self.viewedRound)
        local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", gameType)
        local hasRounds = DoesBattlegroundHaveRounds(self.currentBattlegroundId)

        self.headerExtraTitleLabel:SetHidden(not hasRounds)
        if hasRounds then
            self.headerExtraTitleLabel:SetText(zo_strformat(SI_BATTLEGROUND_SCOREBOARD_HEADER_EXTRA_TITLE_FORMATTER, gameTypeString))
        end

        local playerTeam = GetUnitBattlegroundTeam("player")
        local playerTeamBattlegroundResult = GetBattlegroundResultForTeam(playerTeam)
        local playerTeamWon = playerTeamBattlegroundResult == BATTLEGROUND_RESULT_WIN or playerTeamBattlegroundResult == BATTLEGROUND_RESULT_TIE

        if self:ShouldShowAggregateScores() then
            local resultString = SI_BATTLEGROUND_SCOREBOARD_HEADER_DEFEAT_TITLE
            if playerTeamWon then
                resultString = SI_BATTLEGROUND_SCOREBOARD_HEADER_VICTORY_TITLE
            end
            self.headerMainTitleLabel:SetText(GetString(resultString))
        elseif hasRounds then
            self.headerMainTitleLabel:SetText(zo_strformat(SI_BATTLEGROUND_SCOREBOARD_HEADER_ROUND_TITLE, self.viewedRound))
        else
            self.headerMainTitleLabel:SetText(gameTypeString)
        end
        self:UpdateHeaderAdditionalInfo()

        local numBattlegroundTeams = GetBattlegroundNumTeams(self.currentBattlegroundId)
        local teamSize = GetBattlegroundTeamSize(self.currentBattlegroundId)
        local teamPanelHeight = ZO_Battleground_Scoreboard_Team_Panel_Object.GetPanelHeight(teamSize)
        local totalTeamPanelsHeight = teamPanelHeight * numBattlegroundTeams + ZO_BATTLEGROUND_SCOREBOARD_PANEL_OFFSET_Y * (numBattlegroundTeams - 1)
        -- add some padding so we're not right against the scroll limits
        totalTeamPanelsHeight = totalTeamPanelsHeight + 5
        local containerHeight = zo_min(totalTeamPanelsHeight, ZO_BATTLEGROUND_SCOREBOARD_PANEL_CONTAINER_MAX_HEIGHT)
        self.panelContainer:SetHeight(containerHeight)

        local backgroundsHeight = containerHeight + ZO_BATTLEGROUND_SCOREBOARD_HEADER_HEIGHT + ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT * 2
        self.backgroundsContainer:SetHeight(backgroundsHeight)
        self.backgroundsContainer:ClearAnchors()
        local backgroundsContainerOffsetY = BACKGROUND_DEFAULT_OFFSET_Y
        if hasRounds and containerHeight >= ZO_BATTLEGROUND_SCOREBOARD_PANEL_CONTAINER_MAX_HEIGHT then
            backgroundsContainerOffsetY = BACKGROUND_ROUNDS_OFFSET_Y
        end
        self.backgroundsContainer:SetAnchor(CENTER, nil, CENTER, 0, backgroundsContainerOffsetY)

        local hasLimitedLives = DoesBattlegroundHaveLimitedPlayerLives(self.currentBattlegroundId)
        self.livesHeaderControl:SetHidden(not hasLimitedLives)

        self.userIdHeaderLabel:SetText(ZO_GetPrimaryPlayerNameHeader())

        self:PreUpdatePanels()
        self:RebuildPlayerData()
        self:AddPlayerRows()
        self:PostUpdatePanels()
        self:UpdateAnchors()

        self.roundSummary:SetDetails(GetBattlegroundNumRounds(self.currentBattlegroundId), self.viewedRound, self:ShouldShowAggregateScores())

        if self.playMatchResultSound then
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
        local teamSize = GetBattlegroundTeamSize(self.currentBattlegroundId)
        local useSmallEntries = self:ShouldScoreboardUseSmallPlayerEntries()

        for battlegroundTeam, teamPanel in pairs(self.teamPanels) do
            teamPanel:RemoveAllPlayers()
            if DoesBattlegroundHaveTeam(self.currentBattlegroundId, battlegroundTeam) then
                teamPanel:UpdateScore()
                teamPanel:SetTeamSize(teamSize)
                teamPanel:UseSmallPlayerEntries(useSmallEntries)
            end
        end
    end

    function Battleground_Scoreboard_Fragment:RebuildPlayerData()
        ZO_ClearNumericallyIndexedTable(self.playerEntryData)
        local showAggregate = self:ShouldShowAggregateScores()
        local roundIndex = showAggregate and GetCurrentBattlegroundRoundIndex() or self.viewedRound
        local hasLimitedLives = DoesBattlegroundHaveLimitedPlayerLives(self.currentBattlegroundId)
        local numScoreboardEntries = GetNumScoreboardEntries(roundIndex)
        for entryIndex = 1, numScoreboardEntries do
            local characterName, displayName, battlegroundTeam, isLocalPlayer = GetScoreboardEntryInfo(entryIndex, roundIndex)

            local showLives = hasLimitedLives
            local lives
            local medalScore
            local kills
            local deaths
            local assists
            if not showAggregate then
                lives = GetScoreboardEntryNumLivesRemaining(entryIndex, roundIndex)
                medalScore = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_SCORE, roundIndex)
                kills = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_KILL, roundIndex)
                deaths = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_DEATH, roundIndex)
                assists = GetScoreboardEntryScoreByType(entryIndex, SCORE_TRACKER_TYPE_ASSISTS, roundIndex)
            else
                showLives = false
                lives = 0
                medalScore = GetBattlegroundCumulativeScoreForScoreboardEntryByType(entryIndex, SCORE_TRACKER_TYPE_SCORE, roundIndex)
                kills = GetBattlegroundCumulativeScoreForScoreboardEntryByType(entryIndex, SCORE_TRACKER_TYPE_KILL, roundIndex)
                deaths = GetBattlegroundCumulativeScoreForScoreboardEntryByType(entryIndex, SCORE_TRACKER_TYPE_DEATH, roundIndex)
                assists = GetBattlegroundCumulativeScoreForScoreboardEntryByType(entryIndex, SCORE_TRACKER_TYPE_ASSISTS, roundIndex)
            end

            local playerEntry =
            {
                roundIndex = roundIndex,
                entryIndex = entryIndex,
                battlegroundTeam = battlegroundTeam,
                showLives = showLives,
                lives = lives,
                medalScore = medalScore,
                kills = kills,
                deaths = deaths,
                assists = assists,
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

    function Battleground_Scoreboard_Fragment:ShouldTryToAddPlaceholderRows()
        local battlegroundState = GetCurrentBattlegroundState()
        return self:IsViewingCurrentRound() and battlegroundState ~= BATTLEGROUND_STATE_FINISHED and not HasTeamWonBattlegroundEarly()
    end

    function Battleground_Scoreboard_Fragment:AddPlayerRows()
        local wasPlayerRowReselected = false

        for i, data in ipairs(self.playerEntryData) do
            self.teamPanels[data.battlegroundTeam]:AddPlayer(data)

            local selectedPlayerData = self.selectedPlayerData
            if selectedPlayerData and selectedPlayerData.characterName == data.characterName then
                data.currentHighlightAlpha = selectedPlayerData.currentHighlightAlpha
                data.targetHighlightAlpha = selectedPlayerData.targetHighlightAlpha
                data.mustFinishHighlightAnimation = selectedPlayerData.mustFinishHighlightAnimation
                self:SetSelectedPlayerData(data, DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT, FORCE_REFRESH_PLAYER_SELECTION)
                wasPlayerRowReselected = true
            end
        end

        -- Add entries to inidicate we're looking for replacements if necessary
        if self:ShouldTryToAddPlaceholderRows() then
            for battlegroundTeam, teamPanel in pairs(self.teamPanels) do
                if teamPanel:GetNumPlayers() < teamPanel:GetTeamSize() then
                    local placeholderEntry =
                    {
                        isPlaceholderEntry = true,
                    }
                    self.teamPanels[battlegroundTeam]:AddPlayer(placeholderEntry)
                end
            end
        end

        if not wasPlayerRowReselected then
            self:SelectDefaultPlayerRow(DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT, FORCE_REFRESH_PLAYER_SELECTION)
        end
    end

    function Battleground_Scoreboard_Fragment:PostUpdatePanels()
        for battlegroundTeam, teamPanel in pairs(self.teamPanels) do
            if DoesBattlegroundHaveTeam(self.currentBattlegroundId, battlegroundTeam) then
                teamPanel:PostUpdatePanel()
            end
        end
    end

    function Battleground_Scoreboard_Fragment:UpdateAnchors()
        local previousControl = nil -- default to the parent
        for _, battlegroundTeam in ipairs(BATTLEGROUND_TEAM_SORT_ORDER) do
            local teamPanel = self.teamPanels[battlegroundTeam]
            local control = teamPanel.control
            local battlegroundHasTeam = DoesBattlegroundHaveTeam(self.currentBattlegroundId, battlegroundTeam)
            control:SetHidden(not battlegroundHasTeam)
            if battlegroundHasTeam then
                control:ClearAnchors()
                if previousControl then
                    control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, ZO_BATTLEGROUND_SCOREBOARD_PANEL_OFFSET_Y)
                else
                    control:SetAnchor(TOPLEFT, previousControl, TOPLEFT, 0, 0)
                end

                previousControl = control
            end
        end
    end
end

function Battleground_Scoreboard_Fragment:OnBattlegroundStateChanged(previousState, currentState)
    if currentState == BATTLEGROUND_STATE_FINISHED then
        SCENE_MANAGER:SetHUDScene("battleground_scoreboard_end_of_game")
        SCENE_MANAGER:SetHUDUIScene("battleground_scoreboard_end_of_game", true)
        self.playMatchResultSound = true
    elseif previousState == BATTLEGROUND_STATE_FINISHED then
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
        if GetCurrentBattlegroundState() == BATTLEGROUND_STATE_FINISHED and GetCurrentBattlegroundStateTimeRemaining() > 0 then
            -- in case someone reloads their UI while at the end of game,
            -- we want to continue showing the end of game scoreboard when they load back in
            SCENE_MANAGER:SetHUDScene("battleground_scoreboard_end_of_game")
            local HIDES_AUTOMATICALLY = true
            SCENE_MANAGER:SetHUDUIScene("battleground_scoreboard_end_of_game", HIDES_AUTOMATICALLY)
        end
        self.currentBattlegroundId = GetCurrentBattlegroundId()

        self:UpdateAll()
    else
        self.currentBattlegroundId = 0
    end
end

function Battleground_Scoreboard_Fragment:OnHUDButtonPressedDown()
    if GetCurrentBattlegroundState() ~= BATTLEGROUND_STATE_FINISHED then
        SCENE_MANAGER:SetHUDScene("battleground_scoreboard_in_game")
        local HIDES_AUTOMATICALLY = true
        SCENE_MANAGER:SetHUDUIScene("battleground_scoreboard_in_game_ui", HIDES_AUTOMATICALLY)
        PlaySound(SOUNDS.BATTLEGROUND_SCOREBOARD_OPEN)
    end
end

function Battleground_Scoreboard_Fragment:HideInGameScoreboard()
    SCENE_MANAGER:RestoreHUDScene()
    SCENE_MANAGER:RestoreHUDUIScene()
end

function Battleground_Scoreboard_Fragment:GetCurrentBattlegroundId()
    return self.currentBattlegroundId
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

        if self.selectedPlayerData then
            self.panelContainer:ScrollControlIntoCentralView(self.selectedPlayerData.rowObject:GetControl())
        end

        self:RefreshMatchInfoDisplay()
    end
end

function Battleground_Scoreboard_Fragment:SelectDefaultPlayerRow(animate, forceRefreshPlayerSelection)
    local playerIndex = GetScoreboardLocalPlayerEntryIndex()
    local data = self:GetPlayerDataByEntryIndex(playerIndex)
    self:SetSelectedPlayerData(data, animate, forceRefreshPlayerSelection)
end

function Battleground_Scoreboard_Fragment:CanCyclePlayerSelection()
    local nowMs = GetFrameTimeMilliseconds()
    if not self.playerNavigationThrottleNextUpdateMs or self.playerNavigationThrottleNextUpdateMs < nowMs then
        self.playerNavigationThrottleNextUpdateMs = nowMs + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_NAVIGATION_THROTTLE_MS
        return true
    end
    return false
end

function Battleground_Scoreboard_Fragment:SelectPreviousPlayerData()
    if self.selectedPlayerData and self.selectedPlayerData.previousData and self:CanCyclePlayerSelection() then
        self:SetSelectedPlayerData(self.selectedPlayerData.previousData, ANIMATE_PLAYER_ROW_HIGHLIGHT)
        SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.customNarrationObjectName)
    end
end

function Battleground_Scoreboard_Fragment:SelectNextPlayerData()
    if self.selectedPlayerData and self.selectedPlayerData.nextData and self:CanCyclePlayerSelection() then
        self:SetSelectedPlayerData(self.selectedPlayerData.nextData, ANIMATE_PLAYER_ROW_HIGHLIGHT)
        SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.customNarrationObjectName)
    end
end

function Battleground_Scoreboard_Fragment:OnPlayerRowMouseDown(control, button)
    local data = control.owner:GetData()
    if data.isPlaceholderEntry then
        return
    end

    self:SetSelectedPlayerData(data, ANIMATE_PLAYER_ROW_HIGHLIGHT)
    if button == MOUSE_BUTTON_INDEX_RIGHT then
        self:ShowKeyboardPlayerMenu(control)
    end
end

function Battleground_Scoreboard_Fragment:ShouldScoreboardUseSmallPlayerEntries()
    local teamSize = GetBattlegroundTeamSize(self.currentBattlegroundId)
    local numTeams = GetBattlegroundNumTeams(self.currentBattlegroundId)
    local maxPlayerCount = teamSize * numTeams
    local DEFAULT_ENTRY_SIZE_PLAYER_THRESHOLD = 12
    return maxPlayerCount > DEFAULT_ENTRY_SIZE_PLAYER_THRESHOLD
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
        SYSTEMS:GetObject("matchInfo"):SetupForScoreboardEntry(self.selectedPlayerData.roundIndex, self.selectedPlayerData.entryIndex, self:ShouldShowAggregateScores())
    end
end

function Battleground_Scoreboard_Fragment:Show(...)
    self:SelectDefaultPlayerRow(DONT_ANIMATE_PLAYER_ROW_HIGHLIGHT, FORCE_REFRESH_PLAYER_SELECTION)

    ZO_HUDFadeSceneFragment.Show(self, ...)

    self:RefreshMatchInfoDisplay()
end

function Battleground_Scoreboard_Fragment:SetViewedRound(roundIndex, clampRound)
    local currentRoundIndex = GetCurrentBattlegroundRoundIndex()

    local clampedRoundIndex
    if clampRound then
        clampedRoundIndex = zo_clamp(roundIndex, 1, currentRoundIndex)
    else
        clampedRoundIndex = roundIndex
    end

    if self.showAggregateScores then
        self.viewedRound = clampedRoundIndex
        self:ShowAggregateScores(false)
        return
    end

    if clampedRoundIndex ~= self.viewedRound and clampedRoundIndex <= currentRoundIndex then
        if clampedRoundIndex < self.viewedRound then
            PlaySound(SOUNDS.BATTLEGROUND_SCOREBOARD_PREVIOUS_ROUND)
        else
            PlaySound(SOUNDS.BATTLEGROUND_SCOREBOARD_NEXT_ROUND)
        end
        self.viewedRound = clampedRoundIndex

        self:UpdateAll()
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.customNarrationObjectName, NARRATE_HEADER)
    end
end

function Battleground_Scoreboard_Fragment:GetViewedRound()
    return self.viewedRound
end

function Battleground_Scoreboard_Fragment:IsViewingCurrentRound()
    return self.viewedRound == GetCurrentBattlegroundRoundIndex()
end

function Battleground_Scoreboard_Fragment:ShowAggregateScores(showAggregate)
    if showAggregate ~= self.showAggregateScores then
        self.showAggregateScores = showAggregate ~= false

        if self.showAggregateScores then
            PlaySound(SOUNDS.BATTLEGROUND_SCOREBOARD_NEXT_ROUND)
        else
            PlaySound(SOUNDS.BATTLEGROUND_SCOREBOARD_PREVIOUS_ROUND)
        end

        self:UpdateAll()
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.customNarrationObjectName, NARRATE_HEADER)
    end
end

function Battleground_Scoreboard_Fragment:ShouldShowAggregateScores()
    return self.showAggregateScores == true
end

function Battleground_Scoreboard_Fragment:OnKeybindDown(keybind)
    if self:IsShowing() then
        self.roundSummary:OnKeybindDown(keybind)
    end
end

------------------------------
-- Scoreboard Team Panel
------------------------------

ZO_Battleground_Scoreboard_Team_Panel_Object = ZO_InitializingObject:Subclass()

function ZO_Battleground_Scoreboard_Team_Panel_Object:Initialize(control, battlegroundTeam)
    self.control = control
    self.bgControl = control:GetNamedChild("Bg")
    self.nameControl = control:GetNamedChild("Name")
    self.iconControl = control:GetNamedChild("NameIcon")
    self.scoreControl = control:GetNamedChild("Score")
    self.battlegroundTeam = battlegroundTeam
    self.teamSize = 0
    self.score = 0

    self.iconControl:SetTexture(ZO_GetLargeBattlegroundTeamSymbolIcon(battlegroundTeam))
    self.nameControl:SetText(zo_strformat(SI_ALLIANCE_NAME, GetString("SI_BATTLEGROUNDTEAM", battlegroundTeam)))

    local function PlayerRowFactory(pool)
        local playerRowControl = ZO_ObjectPool_CreateNamedControl("$(parent)PlayerRow", "ZO_Battleground_Scoreboard_Player_Row", pool, self.control)
        return ZO_Battleground_Scoreboard_Player_Row_Object:New(playerRowControl)
    end

    self.playerRowPool = ZO_ObjectPool:New(PlayerRowFactory, ZO_ObjectPool_DefaultResetObject)
    self.sortedPlayerRows = {}

    self.initialPlayerRowOffsetX = 0
end

do
    local BATTLEGROUND_TEAM_TO_BG_TEXTURE =
    {
        [BATTLEGROUND_TEAM_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_orange.dds",
        [BATTLEGROUND_TEAM_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_green.dds",
        [BATTLEGROUND_TEAM_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_purple.dds",
    }

    function ZO_Battleground_Scoreboard_Team_Panel_Object:ApplyPlatformStyle(style)
        ApplyTemplateToControl(self.control, style.teamPanel)
        if IsInGamepadPreferredMode() then
            self.bgControl:SetColor(GetBattlegroundTeamColor(self.battlegroundTeam):UnpackRGBA())
            self.bgControl:SetTexture("")
        else
            self.bgControl:SetTexture(BATTLEGROUND_TEAM_TO_BG_TEXTURE[self.battlegroundTeam])
        end

        self:UpdatePanelHeight()

        for _, playerRow in ipairs(self.sortedPlayerRows) do
            playerRow:ApplyPlatformStyle(style.playerRow)
        end

        ZO_FontAdjustingWrapLabel_OnInitialized(self.nameControl, style.teamNameFonts, TEXT_WRAP_MODE_ELLIPSIS)

        self.initialPlayerRowOffsetX = style.initialPlayerRowOffsetX
    end
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:OnUpdate(deltaS)
    for _, playerRow in ipairs(self.sortedPlayerRows) do
        playerRow:OnUpdate(deltaS)
    end
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:UpdateAnchors()
    local previousControl
    for _, playerRow in ipairs(self.sortedPlayerRows) do
        local control = playerRow.control
        control:ClearAnchors()
        if previousControl then
            control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_OFFSET_Y)
        else
            control:SetAnchor(TOPLEFT, self.control, TOPLEFT, self.initialPlayerRowOffsetX, ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_INITIAL_OFFSET_Y)
        end

        previousControl = control
    end
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:PostUpdatePanel()
    self:UpdateScoreColor()
    self:UpdateAnchors()

    for _, playerRow in ipairs(self.sortedPlayerRows) do
        playerRow:UpdateRow()
    end
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:UpdateScore()
    if BATTLEGROUND_SCOREBOARD_FRAGMENT:ShouldShowAggregateScores() then
        self.score = GetCurrentBattlegroundRoundsWonByTeam(self.battlegroundTeam)
    else
        local roundIndex = BATTLEGROUND_SCOREBOARD_FRAGMENT:GetViewedRound()
        self.score = GetCurrentBattlegroundScore(roundIndex, self.battlegroundTeam)
    end

    self.scoreControl:SetText(self.score)
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:UpdateScoreColor()
    local scoreColor = ZO_WHITE

    if BATTLEGROUND_SCOREBOARD_FRAGMENT:ShouldShowAggregateScores() then
        local teamBattlegroundResult = GetBattlegroundResultForTeam(self.battlegroundTeam)
        local teamWon = teamBattlegroundResult == BATTLEGROUND_RESULT_WIN or teamBattlegroundResult == BATTLEGROUND_RESULT_TIE
        if teamWon then
            scoreColor = ZO_BATTLEGROUND_WINNER_TEXT
        end
    elseif not BATTLEGROUND_SCOREBOARD_FRAGMENT:IsViewingCurrentRound() or GetCurrentBattlegroundState() >= BATTLEGROUND_STATE_POSTROUND then
        local roundIndex = BATTLEGROUND_SCOREBOARD_FRAGMENT:GetViewedRound()
        local teamWon = DidCurrentBattlegroundTeamWinOrTieRound(self.battlegroundTeam, roundIndex)
        if teamWon then
            scoreColor = ZO_BATTLEGROUND_WINNER_TEXT
        end
    end

    self.scoreControl:SetColor(scoreColor:UnpackRGB())
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:AddPlayer(data)
    local playerRow, key = self.playerRowPool:AcquireObject()
    playerRow:SetupOnAcquire(self, key, data)
    table.insert(self.sortedPlayerRows, playerRow)
    return playerRow
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:RemoveAllPlayers()
    self.playerRowPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.sortedPlayerRows)
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:GetScore()
    return self.score
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:GetBattlegroundTeam()
    return self.battlegroundTeam
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:SetTeamSize(teamSize)
    self.teamSize = teamSize
    self:UpdatePanelHeight()
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:UseSmallPlayerEntries(useSmallEntries)
    self.useSmallPlayerEntries = useSmallEntries
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:ShouldUseSmallPlayerEntries()
    return self.useSmallPlayerEntries
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:UpdatePanelHeight()
    local panelHeight = self.GetPanelHeight(self.teamSize)
    self.control:SetHeight(panelHeight)
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:GetTeamSize()
    return self.teamSize
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:GetNumPlayers()
    return #self.sortedPlayerRows
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:GetTopPlayerRow()
    return self.sortedPlayerRows[1]
end

function ZO_Battleground_Scoreboard_Team_Panel_Object:GetBottomPlayerRow()
    return self.sortedPlayerRows[#self.sortedPlayerRows]
end

function ZO_Battleground_Scoreboard_Team_Panel_Object.GetPanelHeight(teamSize)
    local DEFAULT_TEAM_SIZE = 4
    if teamSize <= DEFAULT_TEAM_SIZE then
        return ZO_BATTLEGROUND_SCOREBOARD_PANEL_HEIGHT
    else
        if IsInGamepadPreferredMode() then
            return ZO_BATTLEGROUND_SCOREBOARD_LARGE_PANEL_HEIGHT_GAMEPAD
        else
            return ZO_BATTLEGROUND_SCOREBOARD_LARGE_PANEL_HEIGHT_KEYBOARD
        end
    end
end

------------------------------
-- Scoreboard Player Row
------------------------------

ZO_Battleground_Scoreboard_Player_Row_Object = ZO_InitializingObject:Subclass()

function ZO_Battleground_Scoreboard_Player_Row_Object:Initialize(control)
    self.control = control
    self.control.owner = self
    self.livesLabel = control:GetNamedChild("Lives")
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
        [BATTLEGROUND_TEAM_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboard_highlightStrip_orange.dds",
        [BATTLEGROUND_TEAM_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboard_highlightStrip_purple.dds",
        [BATTLEGROUND_TEAM_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegrounds_scoreboard_highlightStrip_green.dds",
    }

    function ZO_Battleground_Scoreboard_Player_Row_Object:SetupOnAcquire(panel, poolKey, data)
        self.control:SetHidden(false)
        self.key = poolKey
        self.panel = panel
        self.data = data

        if panel:ShouldUseSmallPlayerEntries() then
            self:ApplyPlatformStyle(ZO_GetPlatformTemplate("ZO_Battleground_Scoreboard_Small_Player_Row"))
        else
            self:ApplyPlatformStyle(ZO_GetPlatformTemplate("ZO_Battleground_Scoreboard_Player_Row"))
        end

        local battlegroundTeam = panel:GetBattlegroundTeam()
        self.highlight.keyboardTexture:SetTexture(HIGHLIGHT_KEYBOARD_TEXTURES[battlegroundTeam])
        self.highlight.gamepadBackdrop:SetEdgeColor(GetBattlegroundTeamColor(battlegroundTeam):UnpackRGB())
        self.isMouseOver = false
        self.highlight:SetAlpha(0)
        data.rowObject = self
    end
end

function ZO_Battleground_Scoreboard_Player_Row_Object:Reset()
    local playerRowControl = self.control
    playerRowControl:ClearAnchors()
    playerRowControl:SetHidden(true)
end

function ZO_Battleground_Scoreboard_Player_Row_Object:GetData()
    return self.data
end

function ZO_Battleground_Scoreboard_Player_Row_Object:GetPanel()
    return self.panel
end

function ZO_Battleground_Scoreboard_Player_Row_Object:GetControl()
    return self.control
end

function ZO_Battleground_Scoreboard_Player_Row_Object:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style)
end

function ZO_Battleground_Scoreboard_Player_Row_Object:OnUpdate(deltaS)
    local data = self.data
    if data.isPlaceholderEntry then
        return
    end

    -- Update the highlight alpha
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

function ZO_Battleground_Scoreboard_Player_Row_Object:UpdateRow()
    local data = self.data

    local showLives = data.showLives
    self.livesLabel:SetHidden(not showLives)

    local anchorHighlightToControl = self.nameLabel
    if showLives then
        self.livesLabel:SetText(data.lives)
        anchorHighlightToControl = self.livesLabel
    end

    self.highlight.keyboardTexture:SetAnchor(TOPLEFT, anchorHighlightToControl, TOPLEFT, -30, 0)
    self.highlight.gamepadBackdrop:SetAnchor(TOPLEFT, anchorHighlightToControl, TOPLEFT, -15, -4)

    local isPlaceholderEntry = data.isPlaceholderEntry
    self.medalScoreLabel:SetHidden(isPlaceholderEntry)
    self.killsLabel:SetHidden(isPlaceholderEntry)
    self.deathsLabel:SetHidden(isPlaceholderEntry)
    self.assistsLabel:SetHidden(isPlaceholderEntry)

    local r, g, b
    if isPlaceholderEntry then
        r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
    elseif showLives and data.lives == 0 then
        if data.isLocalPlayer then
            r, g, b = ZO_DEFAULT_TEXT:UnpackRGB()
        else
            r, g, b = ZO_DISABLED_TEXT:UnpackRGB()
        end
    else
        if data.isLocalPlayer then
            r, g, b = ZO_SELECTED_TEXT:UnpackRGB()
        else
            r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
        end
    end

    self.nameLabel:SetColor(r, g, b)

    if not isPlaceholderEntry then
        local primaryName = ZO_GetPrimaryPlayerName(data.displayName, data.characterName)
        local formattedName = zo_strformat(SI_PLAYER_NAME, primaryName)
        self.nameLabel:SetText(formattedName)
        self.medalScoreLabel:SetText(data.medalScore)
        self.killsLabel:SetText(data.kills)
        self.deathsLabel:SetText(data.deaths)
        self.assistsLabel:SetText(data.assists)

        self.livesLabel:SetColor(r, g, b)
        self.medalScoreLabel:SetColor(r, g, b)
        self.killsLabel:SetColor(r, g, b)
        self.deathsLabel:SetColor(r, g, b)
        self.assistsLabel:SetColor(r, g, b)
    else
        self.nameLabel:SetText(GetString(SI_BATTLEGROUND_SCOREBOARD_LOOKING_FOR_PLAYER))
    end
end

function ZO_Battleground_Scoreboard_Player_Row_Object:GetCharacterName()
    return self.characterName
end

function ZO_Battleground_Scoreboard_Player_Row_Object:GetHighlight()
    return self.highlight
end

function ZO_Battleground_Scoreboard_Player_Row_Object:ForceHighlightAlpha(alpha)
    self.highlight:SetAlpha(alpha)
    self.data.currentHighlightAlpha = alpha
    self.data.targetHighlightAlpha = alpha
end

function ZO_Battleground_Scoreboard_Player_Row_Object:SetMouseOver(isMouseOver)
    self.isMouseOver = isMouseOver
end

--[[ xml functions ]]--

function ZO_Battleground_Scoreboard_Player_Row_OnMouseDown(control, button)
    BATTLEGROUND_SCOREBOARD_FRAGMENT:OnPlayerRowMouseDown(control, button)
end

function ZO_BattlegroundScoreboardTopLevel_Initialize(control)
    BATTLEGROUND_SCOREBOARD_FRAGMENT = Battleground_Scoreboard_Fragment:New(control)
end
