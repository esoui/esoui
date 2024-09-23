-- Battleground Scoreboard round winners summary.

local LIGHT_GRAY = ZO_ColorDef:New("CCCCCC")
local KEYBOARD_BG_IMAGE_SMALL_WIDTH = 512

local GAMEPAD_AGGREGATE_TEXTURES =
{
    normal = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_leaderBoards.dds",
}

local KEYBOARD_AGGREGATE_TEXTURES =
{
    normal = "EsoUI/Art/Journal/journal_tabIcon_leaderboard_up.dds",
    mouseOver = "EsoUI/Art/Journal/journal_tabIcon_leaderboard_over.dds",
    pressed = "EsoUI/Art/Journal/journal_tabIcon_leaderboard_down.dds",
    disabled = "EsoUI/Art/Journal/journal_tabIcon_leaderboard_disabled.dds",
}

-- Single round with a round number and the winner's flag.
ZO_BattlegroundScoreboardRoundIndicatorRound = ZO_InitializingObject:Subclass()

function ZO_BattlegroundScoreboardRoundIndicatorRound:Initialize(control, parent)
    self.control = control
    control.owner = self
    control.parent = parent

    self.title = self.control:GetNamedChild("Number")

    self.winnerIcon = self.control:GetNamedChild("Icon")
    self:InitializePlatformStyle()
end

function ZO_BattlegroundScoreboardRoundIndicatorRound:SetDetails(roundNumber, color, winnerIcon, tintIcon)
    self.title:SetText(roundNumber)
    self.title:SetColor(color:UnpackRGBA())
    self.control.value = roundNumber

    if winnerIcon ~= nil then
        self.winnerIcon:SetHidden(false)
        self.winnerIcon:SetTexture(winnerIcon)
        if tintIcon == true then
            self.winnerIcon:SetColor(color:UnpackRGBA())
        end
    else
        self.winnerIcon:SetHidden(true)
    end
end

do
    local KEYBOARD_STYLE = 
    {
        indicatorTemplate = "ZO_BattlegroundScoreboardRoundIndicatorRound_Keyboard_Template",
    }

    local GAMEPAD_STYLE = 
    {
        indicatorTemplate = "ZO_BattlegroundScoreboardRoundIndicatorRound_Gamepad_Template",
    }

    function ZO_BattlegroundScoreboardRoundIndicatorRound:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function ZO_BattlegroundScoreboardRoundIndicatorRound:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style.indicatorTemplate)
end

-- Round winners summary widget for Battleground Scoreboard.
ZO_BattlegroundScoreboardRoundIndicator = ZO_InitializingObject:Subclass()

function ZO_BattlegroundScoreboardRoundIndicator:Initialize(control, parent)
    self.control = control
    control.owner = self
    self.parent = parent

    self.numberPool = ZO_ControlPool:New("ZO_BattlegroundScoreboardRoundIndicatorRound", control)
    self.currentIndicator = self.control:GetNamedChild("CurrentIndicator")
    self.keyboardBackground = self.control:GetNamedChild("BG_Keyboard")
    self.gamepadBackground = self.control:GetNamedChild("BG_Gamepad")
    self.buttonNextRound = self.control:GetNamedChild("NextRound")
    self.buttonNextRound.parent = self
    self.buttonPreviousRound = self.control:GetNamedChild("PreviousRound")
    self.buttonPreviousRound.parent = self
    self.buttonNextRoundGP = self.control:GetNamedChild("NextButton")
    self.buttonPreviousRoundGP = self.control:GetNamedChild("PreviousButton")
    self.buttonAggregate = self.control:GetNamedChild("Aggregate")
    self.buttonAggregate.parent = self

    local KEYBOARD_STYLE =
    {
        roundMarker = "EsoUI/Art/Battlegrounds/battleground_roundselector.dds",
        isKeyboard = true,
    }

    local GAMEPAD_STYLE =
    {
        roundMarker = "EsoUI/Art/Battlegrounds/battleground_roundselector_gp.dds",
        isKeyboard = false,
    }

    local function UpdatePlatformStyle(style)
        self.currentIndicator:SetTexture(style.roundMarker)
        self.keyboardBackground:SetHidden(not style.isKeyboard)
        self.gamepadBackground:SetHidden(style.isKeyboard)
        self.buttonNextRound:SetHidden(not style.isKeyboard)
        self.buttonPreviousRound:SetHidden(not style.isKeyboard)
        self.buttonNextRoundGP:SetHidden(style.isKeyboard)
        self.buttonPreviousRoundGP:SetHidden(style.isKeyboard)

        local buttonTextures = IsInGamepadPreferredMode() and GAMEPAD_AGGREGATE_TEXTURES or KEYBOARD_AGGREGATE_TEXTURES
        self.buttonAggregate:SetNormalTexture(buttonTextures.normal)
        self.buttonAggregate:SetMouseOverTexture(buttonTextures.mouseOver)
        self.buttonAggregate:SetPressedTexture(buttonTextures.pressed)
        self.buttonAggregate:SetDisabledTexture(buttonTextures.disabled)
    end
    self.platformStyle = ZO_PlatformStyle:New(UpdatePlatformStyle, KEYBOARD_STYLE, GAMEPAD_STYLE)
end

-- Params:
--   numRounds:     (number) Total rounds in this match.
--   viewedRound:  (number) Current round number.
function ZO_BattlegroundScoreboardRoundIndicator:SetDetails(numRounds, viewedRound, showAggregatedScores)
    if numRounds <= 1 or viewedRound == nil then
        self.control:SetHidden(true)
        return
    else
        self.control:SetHidden(false)
    end

    self.currentRound = GetCurrentBattlegroundRoundIndex()
    self.showAggregateButton = DoesBattlegroundHaveRounds(GetCurrentBattlegroundId()) and (GetCurrentBattlegroundRoundIndex() == GetBattlegroundNumRounds(GetCurrentBattlegroundId()) or HasTeamWonBattlegroundEarly()) and GetCurrentBattlegroundState() > BATTLEGROUND_STATE_RUNNING
    local canMoveNext = viewedRound < self.currentRound or (not showAggregatedScores and self.showAggregateButton)  -- Moving next from the last valid round will enter the Aggregate.
    local canMovePrevious = viewedRound > 1
    local currentRound = self.currentRound

    self.buttonNextRound:SetEnabled(canMoveNext)
    self.buttonNextRoundGP:SetEnabled(canMoveNext)
    self.buttonPreviousRound:SetEnabled(canMovePrevious)
    self.buttonPreviousRoundGP:SetEnabled(canMovePrevious)


    local currentBattlegroundId = GetCurrentBattlegroundId()
    -- From various team scores, calculate the single winner of each round.
    local roundWinners = {}
    for roundIndex = 1, numRounds do
        local bestScore = 0
        local bestTeams = {} -- Maybe tied
        if roundIndex <= currentRound then
            for teamId = BATTLEGROUND_TEAM_ITERATION_BEGIN, BATTLEGROUND_TEAM_ITERATION_END do
                if DoesBattlegroundHaveTeam(currentBattlegroundId, teamId) and DidCurrentBattlegroundTeamWinOrTieRound(teamId, roundIndex) then
                    table.insert(bestTeams, teamId)
                end
            end
        end
        roundWinners[roundIndex] = bestTeams
    end

    self.numberPool:ReleaseAllObjects()

    local previousControl = nil
    for roundNumber = 1, numRounds do
        local roundControl = self.numberPool:AcquireObject()
        local round = ZO_BattlegroundScoreboardRoundIndicatorRound:New(roundControl, self)
        if #roundWinners[roundNumber] > 0 and (roundNumber < currentRound or (roundNumber == currentRound and GetCurrentBattlegroundState() > BATTLEGROUND_STATE_RUNNING)) then
            -- If there was a tie, then roundWinners[idx] have more than 1 entry.
            if #roundWinners[roundNumber] == 1  then
                local winnningTeam = roundWinners[roundNumber][1]
                local icon = ZO_GetBattlegroundTeamIcon(winnningTeam)
                local color = roundNumber == viewedRound and ZO_WHITE or GetBattlegroundTeamColor(winnningTeam)
                round:SetDetails(roundNumber, color, icon)
            else
                local tie_image
                local tiedTeams = roundWinners[roundNumber]
                if #tiedTeams == 3  then
                    tie_image = "EsoUI/Art/Battlegrounds/battlegrounds_scoreIcon_tie_three_way.dds"
                else
                    internalassert(#tiedTeams == 2)
                    -- Sort ties in canonical team order.
                    table.sort(tiedTeams, function(a,b) return a < b end)
                    if tiedTeams[1] == BATTLEGROUND_TEAM_FIRE_DRAKES then
                        if tiedTeams[2] == BATTLEGROUND_TEAM_PIT_DAEMONS then
                            tie_image = "EsoUI/Art/Battlegrounds/battlegrounds_scoreIcon_tie_orange_green.dds"
                        else
                            internalassert(tiedTeams[2] == BATTLEGROUND_TEAM_STORM_LORDS)
                            tie_image = "EsoUI/Art/Battlegrounds/battlegrounds_scoreIcon_tie_orange_purple.dds"
                        end
                    else
                        internalassert(tiedTeams[1] == BATTLEGROUND_TEAM_PIT_DAEMONS)
                        internalassert(tiedTeams[2] == BATTLEGROUND_TEAM_STORM_LORDS)
                        tie_image = "EsoUI/Art/Battlegrounds/battlegrounds_scoreIcon_tie_green_purple.dds"
                    end
                end

                local TINT_IMAGE = true
                round:SetDetails(roundNumber, LIGHT_GRAY, tie_image, TINT_IMAGE)
            end
        elseif roundNumber == currentRound then
            local NO_ICON = nil
            local color = roundNumber == viewedRound and ZO_WHITE or ZO_HIGHLIGHT_TEXT
            round:SetDetails(roundNumber, color, NO_ICON)
        else
            -- Future rounds.
            local NO_ICON = nil
            round:SetDetails(roundNumber, ZO_DISABLED_TEXT, NO_ICON)
        end

        if roundNumber == 1 then
            roundControl:SetAnchor(TOPLEFT, nil, nil, 0, 20)
        else
            roundControl:SetAnchor(TOPLEFT, previousControl, TOPRIGHT, 20)
        end

        if roundNumber == viewedRound then
            self.currentIndicator:SetAnchor(TOP, roundControl, BOTTOM, 0, 10)
        end

        if self.keyboardBackground:GetWidth() < KEYBOARD_BG_IMAGE_SMALL_WIDTH then
            self.keyboardBackground:SetTexture("EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_rounds.dds")
        else
            self.keyboardBackground:SetTexture("EsoUI/Art/Battlegrounds/battlegrounds_scoreboardBG_roundsLarge.dds")
        end

        previousControl = roundControl
    end

    if self.showAggregateButton then
        self.buttonAggregate:SetHidden(false)
        self.buttonAggregate:ClearAnchors()
        if previousControl then
            self.buttonAggregate:SetAnchor(TOPLEFT, previousControl, TOPRIGHT, 20, 25)
        else
            self.buttonAggregate:SetAnchor(TOPLEFT, self.control)
        end
        if showAggregatedScores then
            self.currentIndicator:ClearAnchors()
            self.currentIndicator:SetAnchor(TOP, self.buttonAggregate, BOTTOM, 0, -5)
        end
    else
        self.buttonAggregate:SetHidden(true)
    end
end

function ZO_BattlegroundScoreboardRoundIndicator:IsVisible()
    return not self.control:IsHidden()
end

function ZO_BattlegroundScoreboardRoundIndicator:GetKeybindsNarrationData()
    local narrations = {}

    table.insert(narrations,
    {
        name = GetString(SI_BATTLEGROUND_SCOREBOARD_PREVIOUS_ROUND),
        keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(self.buttonPreviousRoundGP:GetKeybind()),
        enabled = self.buttonPreviousRoundGP:IsEnabled(),
    })

    table.insert(narrations,
    {
        name = GetString(SI_BATTLEGROUND_SCOREBOARD_NEXT_ROUND),
        keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(self.buttonNextRoundGP:GetKeybind()),
        enabled = self.buttonNextRoundGP:IsEnabled(),
    })

    return narrations
end

function ZO_BattlegroundScoreboardRoundIndicator:MoveViewedRound(deltaIndex)
    local CLAMP_ROUND = true
    if self.showAggregateButton then
        if not self.parent:ShouldShowAggregateScores() and self.parent:GetViewedRound() == self.currentRound and deltaIndex > 0 then
            self:ShowAggregateScores(true)
            return
        elseif self.parent:ShouldShowAggregateScores() and deltaIndex < 0 then
            self.parent:SetViewedRound(self.currentRound, CLAMP_ROUND)
            return
        end
    end

    self.parent:SetViewedRound(self.parent:GetViewedRound() + deltaIndex, CLAMP_ROUND)
end

function ZO_BattlegroundScoreboardRoundIndicator:ShowAggregateScores()
    if self.showAggregateButton then
        self.parent:ShowAggregateScores(true)
    end
end

function ZO_BattlegroundScoreboardRoundIndicator:OnRoundNumberClick(roundIndex)
    local DONT_CLAMP_ROUND = false
    self.parent:SetViewedRound(roundIndex, DONT_CLAMP_ROUND)
end

function ZO_BattlegroundScoreboardRoundIndicator:OnKeybindDown(keybind)
    if keybind == "BATTLEGROUND_SCOREBOARD_NEXT_ROUND" then
        self:MoveViewedRound(1)
    elseif keybind == "BATTLEGROUND_SCOREBOARD_PREVIOUS_ROUND" then
        self:MoveViewedRound(-1)
    end
end

--[[ xml functions ]]--

function ZO_BattlegroundScoreboard_NextPage_OnMouseClicked(control)
    control.parent:MoveViewedRound(1)
end

function ZO_BattlegroundScoreboard_NextPage_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, RIGHT)
    SetTooltipText(InformationTooltip, GetString(SI_BATTLEGROUND_SCOREBOARD_NEXT_ROUND))
end

function ZO_BattlegroundScoreboard_NextPage_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_BattlegroundScoreboard_PreviousPage_OnMouseClicked(control)
    control.parent:MoveViewedRound(-1)
end

function ZO_BattlegroundScoreboard_PreviousPage_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, RIGHT, 0, 0, LEFT)
    SetTooltipText(InformationTooltip, GetString(SI_BATTLEGROUND_SCOREBOARD_PREVIOUS_ROUND))
end

function ZO_BattlegroundScoreboard_PreviousPage_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_BattlegroundScoreboard_RoundNumber_OnMouseClicked(control, upInside)
    if upInside then
        control.parent:OnRoundNumberClick(control.value)
    end
end

function ZO_BattlegroundScoreboard_Aggregate_OnMouseClicked(control)
    control.parent:ShowAggregateScores()
end

function ZO_BattlegroundScoreboard_Aggregate_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, RIGHT, 0, 0, LEFT)
    SetTooltipText(InformationTooltip, GetString(SI_BATTLEGROUND_SCOREBOARD_SHOW_AGGREGATE))
end

function ZO_BattlegroundScoreboard_Aggregate_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end