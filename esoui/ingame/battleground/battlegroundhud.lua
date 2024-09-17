local COUNTDOWN_TIMER_START_MS = 5000
local ROUND_CSA_START_MS = 15000
local COUNTDOWN_TIMER_END_BATTLEGROUND_MS = ZO_ONE_MINUTE_IN_MILLISECONDS

--------------------
--Battleground HUD Fragment
--------------------

local BattlegroundHUDFragment = ZO_HUDFadeSceneFragment:Subclass()

function BattlegroundHUDFragment:New(...)
    return ZO_HUDFadeSceneFragment.New(self, ...)
end

function BattlegroundHUDFragment:Initialize(control)
    ZO_HUDFadeSceneFragment.Initialize(self, control)

    self.currentBattlegroundTimeMS = 0

    self.keybindButton = control:GetNamedChild("KeybindButton")
    ZO_KeybindButtonTemplate_OnInitialized(self.keybindButton)
    self.keybindButton:SetKeybind("SHOW_BATTLEGROUND_SCOREBOARD")
    
    self.headerLabel = control:GetNamedChild("Header")

    self.stateLabel = control:GetNamedChild("State")
    
    self.battlegroundScoreHudControl = control:GetNamedChild("BattlegroundScoreHud")

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_BATTLEGROUND_RULESET_CHANGED, function() self:OnBattlegroundRulesetChanged() end)

    self:InitializePlatformStyle()
end

do
    local KEYBOARD_STYLE = 
    {
        hudTemplate = "ZO_BattlegroundHudTopLevel_Keyboard",
        keybindButtonTemplate = "ZO_KeybindButton_Keyboard_Template",
    }

    local GAMEPAD_STYLE = 
    {
        hudTemplate = "ZO_BattlegroundHudTopLevel_Gamepad",
        keybindButtonTemplate = "ZO_KeybindButton_Gamepad_Template",
    }

    function BattlegroundHUDFragment:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function BattlegroundHUDFragment:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style.hudTemplate)
    ApplyTemplateToControl(self.keybindButton, style.keybindButtonTemplate)
    
    local battlegroundType = GetCurrentBattlegroundGameType()
    if battlegroundType ~= BATTLEGROUND_GAME_TYPE_NONE then
        local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", battlegroundType)
        gameTypeString = ZO_NORMAL_TEXT:Colorize(gameTypeString)
        self.headerLabel:SetText(gameTypeString)
    else
        self.headerLabel:SetText(GetString(SI_BATTLEGROUND_HUD_HEADER))
    end
end

function BattlegroundHUDFragment:OnPlayerActivated()
    self:CheckForBattleground()
end

function BattlegroundHUDFragment:OnBattlegroundRulesetChanged()
    self:CheckForBattleground()
end

function BattlegroundHUDFragment:CheckForBattleground()
    local currentBattlegroundId = GetCurrentBattlegroundId()
    if currentBattlegroundId ~= 0 then
        EVENT_MANAGER:RegisterForUpdate(self.control:GetName(), 10, function() self:OnUpdate() end)
    else
        EVENT_MANAGER:UnregisterForUpdate(self.control:GetName())
        self.currentBattlegroundTimeMS = 0
        self.shutdownTimerMS = nil
    end
end

function BattlegroundHUDFragment:GetFormattedTimer()
    return ZO_FormatTime(zo_ceil(self.currentBattlegroundTimeMS / 1000), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
end

do
    local PRE_SHUTDOWN_WARNING_TIME_MS = 10000
    local PRE_SHUTDOWN_WARNING_TIME_S = zo_round(PRE_SHUTDOWN_WARNING_TIME_MS / 1000)
    local previousBattlegroundState = 0

    function BattlegroundHUDFragment:OnUpdate()
        local battlegroundState = GetCurrentBattlegroundState()
        local previousBattlegroundTimeMS = self.currentBattlegroundTimeMS
        self.currentBattlegroundTimeMS = GetCurrentBattlegroundStateTimeRemaining()
        local previousShutdownTimerMS = self.shutdownTimerMS
        self.shutdownTimerMS = GetCurrentBattlegroundShutdownTimer()
        local battlegroundId = GetCurrentBattlegroundId()

        local text
        if battlegroundState == BATTLEGROUND_STATE_PREROUND then
            ZO_BattlegroundRoundRecap.HideScene()

            local gameType = GetCurrentBattlegroundGameType()
            local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", gameType)
            gameTypeString = ZO_NORMAL_TEXT:Colorize(gameTypeString)
            self.headerLabel:SetText(gameTypeString)
            text = ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_BATTLEGROUND_STATE_PREGAME, ZO_SELECTED_TEXT:Colorize(self:GetFormattedTimer())))
            if previousShutdownTimerMS and self.shutdownTimerMS then
                if previousShutdownTimerMS >= PRE_SHUTDOWN_WARNING_TIME_MS and self.shutdownTimerMS < PRE_SHUTDOWN_WARNING_TIME_MS then
                    local shutdownImminentMessage = zo_strformat(SI_BATTLEGROUND_SHUTDOWN_IMMINENT, PRE_SHUTDOWN_WARNING_TIME_S)
                    CHAT_ROUTER:AddSystemMessage(shutdownImminentMessage)
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, shutdownImminentMessage)
                end
            end
        elseif battlegroundState == BATTLEGROUND_STATE_STARTING then
            ZO_BattlegroundRoundRecap.HideScene()

            local gameType = GetCurrentBattlegroundGameType()
            local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", gameType)
            gameTypeString = ZO_NORMAL_TEXT:Colorize(gameTypeString)
            self.headerLabel:SetText(gameTypeString)

            if IsCurrentBattlegroundStateTimed() then
                local currentRound = GetCurrentBattlegroundRoundIndex(battlegroundId)
                local numRounds = GetBattlegroundNumRounds(battlegroundId)
                text = self:GetRoundAndTimeText(SI_BATTLEGROUND_STATE_STARTING_ROUND, SI_BATTLEGROUND_STATE_STARTING_MATCH, currentRound, numRounds, self:GetFormattedTimer())
                if DoesBattlegroundHaveRounds(battlegroundId) and self.currentBattlegroundTimeMS <= ROUND_CSA_START_MS then
                    if previousBattlegroundTimeMS > ROUND_CSA_START_MS then
                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT)
                        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_ROUND_STARTING)

                        --Check if this is the final round
                        if currentRound == numRounds then
                            local numTeams = GetBattlegroundNumTeams(battlegroundId)
                            local isTied = true
                            local previousRoundsWon

                            --Determine if the teams are tied
                            for i = 1, numTeams do
                                local team = GetBattlegroundTeamByIndex(battlegroundId, i)
                                local roundsWon = GetCurrentBattlegroundRoundsWonByTeam(team)
                                if previousRoundsWon and previousRoundsWon ~= roundsWon then
                                    isTied = false
                                    break
                                end
                                previousRoundsWon = roundsWon
                            end

                            if isTied then
                                messageParams:SetText(GetString(SI_BATTLEGROUND_ROUND_CSA_FINAL_ROUND), GetString(SI_BATTLEGROUND_ROUND_CSA_TIEBREAKER))
                            else
                                messageParams:SetText(GetString(SI_BATTLEGROUND_ROUND_CSA_FINAL_ROUND), zo_strformat(SI_BATTLEGROUND_ROUND_CSA_TOTAL_ROUNDS, numRounds))
                            end
                            messageParams:SetSound(SOUNDS.BATTLEGROUND_FINAL_ROUND_STARTING)
                        else
                            messageParams:SetText(zo_strformat(SI_BATTLEGROUND_ROUND_CSA_CURRENT_ROUND, currentRound), zo_strformat(SI_BATTLEGROUND_ROUND_CSA_TOTAL_ROUNDS, numRounds))
                            messageParams:SetSound(SOUNDS.BATTLEGROUND_ROUND_STARTING)
                        end
                        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
                    end
                end

                if self.currentBattlegroundTimeMS <= COUNTDOWN_TIMER_START_MS then
                    if previousBattlegroundTimeMS > COUNTDOWN_TIMER_START_MS then
                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_COUNTDOWN_TEXT, SOUNDS.BATTLEGROUND_COUNTDOWN_FINISH )
                        messageParams:SetLifespanMS(COUNTDOWN_TIMER_START_MS)
                        messageParams:SetIconData(ZO_GetCountdownBattlegroundTeamSymbolIcon(GetUnitBattlegroundTeam("player")))
                        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN)
                        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
                    end
                end
            end
        elseif battlegroundState == BATTLEGROUND_STATE_RUNNING then
            local gameType = GetCurrentBattlegroundGameType()
            local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", gameType)
            gameTypeString = ZO_NORMAL_TEXT:Colorize(gameTypeString)
            self.headerLabel:SetText(gameTypeString)

            if IsCurrentBattlegroundStateTimed() then
                text = self:GetRoundAndTimeText(SI_BATTLEGROUND_STATE_RUNNING_ROUND, SI_BATTLEGROUND_STATE_RUNNING_MATCH, GetCurrentBattlegroundRoundIndex(), GetBattlegroundNumRounds(battlegroundId), self:GetFormattedTimer())

                if self.currentBattlegroundTimeMS <= COUNTDOWN_TIMER_END_BATTLEGROUND_MS and previousBattlegroundTimeMS > COUNTDOWN_TIMER_END_BATTLEGROUND_MS then
                    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_MAJOR_TEXT, SOUNDS.BATTLEGROUND_ONE_MINUTE_WARNING)
                    messageParams:SetText(GetString(SI_BATTLEGROUND_WARNING_ONE_MINUTE_REMAINING))
                    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_MINUTE_WARNING)
                    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
                end
            end
            if previousShutdownTimerMS and self.shutdownTimerMS then
                if previousShutdownTimerMS >= PRE_SHUTDOWN_WARNING_TIME_MS and self.shutdownTimerMS < PRE_SHUTDOWN_WARNING_TIME_MS then
                    local shutdownImminentMessage = zo_strformat(SI_BATTLEGROUND_SHUTDOWN_IMMINENT, PRE_SHUTDOWN_WARNING_TIME_S)
                    CHAT_ROUTER:AddSystemMessage(shutdownImminentMessage)
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, shutdownImminentMessage)
                end
            end
        elseif battlegroundState == BATTLEGROUND_STATE_POSTROUND then
            if previousBattlegroundState ~= battlegroundState then
                if DoesBattlegroundHaveRounds(GetCurrentBattlegroundId()) then
                    ZO_BattlegroundRoundRecap.ShowScene()
                end
            end

        elseif battlegroundState == BATTLEGROUND_STATE_FINISHED then
            ZO_BattlegroundRoundRecap.HideScene()

            if IsCurrentBattlegroundStateTimed() then
                text = zo_strformat(SI_BATTLEGROUND_STATE_FINISHED, self:GetFormattedTimer())
            end
        end

        if text then
            self.stateLabel:SetHidden(false)
            self.stateLabel:SetText(text)
        else
            self.stateLabel:SetHidden(true)
        end
        
        previousBattlegroundState = battlegroundState
    end
end

-- textForRounds: (string) Text for a match with multiple rounds. "Round One: 3:57"
-- textForMatch:  (string) Text for a match with only one round. "Match: 3:57"
-- currentRound:  (number) Round number to display, if multiple rounds.
-- numRounds:     (number) Number of rounds.  We display round match text when this is > 1.
-- timerText:     (string) Current timer.
function BattlegroundHUDFragment:GetRoundAndTimeText(textForRounds, textForMatch, currentRound, numRounds, timerText)
    local text
    if numRounds > 1 then
        text = ZO_NORMAL_TEXT:Colorize(zo_strformat(textForRounds, currentRound, ZO_SELECTED_TEXT:Colorize(timerText)))
    else
        text = ZO_NORMAL_TEXT:Colorize(zo_strformat(textForMatch, ZO_SELECTED_TEXT:Colorize(timerText)))
    end

    return text
end

function BattlegroundHUDFragment:GetStateText()
    return self.stateLabel:GetText()
end

--[[ xml functions ]]--

function ZO_BattlegroundHUDFragmentTopLevel_Initialize(control)
    BATTLEGROUND_HUD_FRAGMENT = BattlegroundHUDFragment:New(control)
end
