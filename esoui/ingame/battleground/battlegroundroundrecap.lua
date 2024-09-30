local BATTLEGROUND_ROUND_RECAP_SCENE_NAME = "battleground_round_recap"

local TEAM_IMAGES = 
{
    { 
        imageWin = "EsoUI/Art/Battlegrounds/battleground_banner_orange_win.dds", 
        imageWinGP = "EsoUI/Art/Battlegrounds/battleground_banner_orange_win.dds", 
        imageLoss = "EsoUI/Art/Battlegrounds/battleground_banner_orange_loss.dds", 
        imageLossGP = "EsoUI/Art/Battlegrounds/battleground_banner_orange_loss.dds", 
    },
    { 
        imageWin = "EsoUI/Art/Battlegrounds/battleground_banner_green_win.dds", 
        imageWinGP = "EsoUI/Art/Battlegrounds/battleground_banner_green_win.dds", 
        imageLoss = "EsoUI/Art/Battlegrounds/battleground_banner_green_loss.dds", 
        imageLossGP = "EsoUI/Art/Battlegrounds/battleground_banner_green_loss.dds", 
    },
    { 
        imageWin = "EsoUI/Art/Battlegrounds/battleground_banner_purple_win.dds", 
        imageWinGP = "EsoUI/Art/Battlegrounds/battleground_banner_purple_win.dds", 
        imageLoss = "EsoUI/Art/Battlegrounds/battleground_banner_purple_loss.dds", 
        imageLossGP = "EsoUI/Art/Battlegrounds/battleground_banner_purple_loss.dds", 
    },
}

local PLAYER_WIN_STATUSES = 
{
    SI_BATTLEGROUND_RESULT_TITLE_ROUND_WON,
    SI_BATTLEGROUND_RESULT_TITLE_ROUND_LOST,
    SI_BATTLEGROUND_RESULT_TITLE_ROUND_TIED,
    SI_BATTLEGROUND_RESULT_TITLE_MATCH_WON,
    SI_BATTLEGROUND_RESULT_TITLE_MATCH_LOST,
    SI_BATTLEGROUND_RESULT_TITLE_MATCH_TIED,
}
local PLAYER_STATUS_WIN = 1
local PLAYER_STATUS_LOSS = 2
local PLAYER_STATUS_TIE = 3

local HEADER_IMAGE_WIN = "EsoUI/Art/Battlegrounds/BattlegroundRoundRecapHeader.dds"
local HEADER_IMAGE_LOSS = "EsoUI/Art/Battlegrounds/BattlegroundRoundRecapHeader_loss.dds"

local KEYBIND_BUTTON_SPACING_X = 10

--------------------------------------------
--Battleground Recap Scene
--------------------------------------------

ZO_BattlegroundRoundRecap = ZO_DeferredInitializingObject:Subclass()

function ZO_BattlegroundRoundRecap:Initialize(control)
    self.control = control
    control.owner = self

    BATTLEGROUND_ROUND_RECAP_SCENE = ZO_Scene:New(BATTLEGROUND_ROUND_RECAP_SCENE_NAME, SCENE_MANAGER)
    local actionFragment = ZO_ActionLayerFragment:New("BattlegroundRoundRecap")
    BATTLEGROUND_ROUND_RECAP_SCENE:AddFragment(actionFragment)

    local ALWAYS_ANIMATE = true
    local DURATION = 500
    BATTLEGROUND_ROUND_RECAP_FRAGMENT = ZO_FadeSceneFragment:New(self.control, ALWAYS_ANIMATE, DURATION)
    BATTLEGROUND_ROUND_RECAP_FRAGMENT:SetHideOnSceneHidden(true)
    ZO_DeferredInitializingObject.Initialize(self, BATTLEGROUND_ROUND_RECAP_FRAGMENT)
    BATTLEGROUND_ROUND_RECAP_SCENE:AddFragment(BATTLEGROUND_ROUND_RECAP_FRAGMENT)
end

function ZO_BattlegroundRoundRecap:OnDeferredInitialize()

    self.winTitle = self.control:GetNamedChild("WinTitle")
    self.winSubtitle = self.control:GetNamedChild("WinSubtitle")
    self.countdown = self.control:GetNamedChild("Countdown")
    self.titleBanner = self.control:GetNamedChild("TitleHeader")

    self.sceneTimeLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("BattlegroundRoundRecap", self.control)
    self.control:SetHandler("OnUpdate", function() self:UpdateTimer() end)

    self.flags = 
    {
        ZO_BattlegroundsRoundRecapFlag:New(self.control:GetNamedChild("Flag1")),
        ZO_BattlegroundsRoundRecapFlag:New(self.control:GetNamedChild("Flag2")),
        ZO_BattlegroundsRoundRecapFlag:New(self.control:GetNamedChild("Flag3")),
    }
    
    self:InitializeKeybinds()
    self:InitializeNarrationInfo()
    self:InitializePlatformStyle()
end

function ZO_BattlegroundRoundRecap:InitializeKeybinds()
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

    self.leaveBattlegroundButton = CreateKeybindButton("BATTLEGROUND_RECAP_LEAVE", 
        function()
            if self:IsBattlegroundFinished() then
                PlaySound(SOUNDS.BATTLEGROUND_LEAVE_MATCH)
                LeaveBattleground()
            end
        end, 
        GetString(SI_BATTLEGROUND_SCOREBOARD_LEAVE_BATTLEGROUND))
        
    self.showScoreboardButton = CreateKeybindButton("BATTLEGROUND_RECAP_SHOW_SCOREBOARD", 
        function() 
            self.HideScene()
        end, 
        GetString(SI_BATTLEGROUND_HUD_FRAGMENT_SCOREBOARD_KEYBIND))

end

function ZO_BattlegroundRoundRecap.ShowScene()
    if BATTLEGROUND_ROUND_RECAP_SCENE:IsShowing() then
        return
    end

    SCENE_MANAGER:SetHUDScene("battleground_round_recap")
    SCENE_MANAGER:SetHUDUIScene("battleground_round_recap", true)
end

-- This function must be called instead of ShowScene directly because SCENE_MANAGER:Restore* 
-- functions can't be called from OnHiding or OnHidden. 
function ZO_BattlegroundRoundRecap.HideScene()
    if not BATTLEGROUND_ROUND_RECAP_SCENE:IsShowing() then
        return
    end

    SCENE_MANAGER:RestoreHUDScene()
    SCENE_MANAGER:RestoreHUDUIScene()
end

function ZO_BattlegroundRoundRecap:SetDetails(roundResult, numTeams, playerTeam, scores)
    local roundResultText = GetString("SI_BATTLEGROUNDROUNDRESULT", roundResult)

    self.winSubtitle:SetText(roundResultText)

    -- Position flags based on number of active teams.
    local TWO_TEAM_POSITIONS = { -300, 300, false, }
    local THREE_TEAM_POSITIONS = { -400, 0, 400, }
    local flagPositions = numTeams == 2 and TWO_TEAM_POSITIONS or THREE_TEAM_POSITIONS
    for index, positionX in ipairs(flagPositions) do
        if positionX ~= false then
            self.flags[index].control:SetHidden(false)
            self.flags[index].control:SetAnchor(TOP, nil, CENTER, positionX, -150)
        else
            self.flags[index].control:SetHidden(true)
        end
    end

    local teamScores = 
    {
        -- rank will be updated below.
        { 
            score = scores[1],
            rank = 1,
        },
        { 
            score = scores[2],
            rank = 1,
        },
        { 
            score = scores[3],
            rank = 1,
        },
    }

    local function GetFlagImage(teamData, isWinner, isGamepad)
        if isWinner then
            if isGamepad then
                return teamData.imageWinGP
            else
                return teamData.imageWin
            end
        else
            if isGamepad then
                return teamData.imageLossGP
            else
                return teamData.imageLoss
            end
        end
    end

    -- Animation doesn't work if this is 1000.
    local PLAY_OFFSETS_PER_RANK = { 700, 500, 300, }

    -- We're determining three effects here:
    -- 1. Player's team flags is positioned first, and the other teams follow in canonical order.
    -- 2. The team with the highest score gets a little glow starburst.
    -- 3. Scores are converted to team ranks and the team flags drop in rank order.

    -- Convert team scores into ranks and insert rank values into TEAMS.
    do
        -- Sort teams by score and use sorted scores to determine rank order.
        local teamToRankData = {}
        for teamIndex = 1, numTeams do
            table.insert(teamToRankData, {teamIndex = teamIndex, score = scores[teamIndex], })
        end
        table.sort(teamToRankData, function(a, b) return a.score > b.score end);
        
        -- Update the TEAMS data with the correct ranks.
        for rankIndex = 1, numTeams do
            teamScores[teamToRankData[rankIndex].teamIndex].rank = rankIndex
        end
    end

    -- Determine the highest score
    local highestScore = 0
    local highestCount = 0
    for teamIndex = 1, numTeams do
        if highestScore < teamScores[teamIndex].score then
            highestScore = teamScores[teamIndex].score
            highestCount = 1
        elseif highestScore == teamScores[teamIndex].score then
            highestCount = highestCount + 1
        end
    end

    local roundResultIndex
    local playerScore = teamScores[playerTeam] and teamScores[playerTeam].score or 0
    if playerScore == highestScore then
        if highestCount == 1 then
            roundResultIndex = PLAYER_STATUS_WIN
        else
            roundResultIndex = PLAYER_STATUS_TIE
        end
    else
        roundResultIndex = PLAYER_STATUS_LOSS
    end
    
    if roundResultIndex ~= PLAYER_STATUS_LOSS then
        self.titleBanner:SetTexture(HEADER_IMAGE_WIN)
    else
        self.titleBanner:SetTexture(HEADER_IMAGE_LOSS)
    end

    local playerWinLoss = PLAYER_WIN_STATUSES[roundResultIndex]
    if not DoesBattlegroundHaveRounds(GetCurrentBattlegroundId()) then
        -- Shift a round result into a match result.
        playerWinLoss = PLAYER_WIN_STATUSES[roundResultIndex + 3]
    end
    self.winTitleText = GetString(playerWinLoss)
    self.winTitle:SetText(self.winTitleText)

    -- Create a list with the player's team first and the other teams following in canonical order.
    local positionedTeams = self:GetPositionedTeamOrder(playerTeam)

    local isGamepad = IsInGamepadPreferredMode()

    for positionedTeamIndex = 1, numTeams do
        local teamIndex = positionedTeams[positionedTeamIndex]
        local teamImages = TEAM_IMAGES[teamIndex] or TEAM_IMAGES[1]
        local teamScore = teamScores[teamIndex] or teamScores[1]
        local isWinner = DidCurrentBattlegroundTeamWinOrTieRound(teamIndex) -- Multiple teams might tie for first.
        local roundsWonByTeam = GetCurrentBattlegroundRoundsWonByTeam(teamIndex)
        local flagImage = GetFlagImage(teamImages, isWinner, isGamepad)

        self.flags[positionedTeamIndex]:SetDetails(teamIndex, flagImage, teamScore.score, PLAY_OFFSETS_PER_RANK[teamScore.rank], isWinner, roundsWonByTeam)
    end

    local battlegroundFinished = self:IsBattlegroundFinished()
    self.countdown:SetHidden(battlegroundFinished)

    self.leaveBattlegroundButton:SetHidden(not battlegroundFinished)
    -- Reanchor buttons to accomodate leaveBattleground button showing/hiding.
    self.showScoreboardButton:ClearAnchors()
    if battlegroundFinished then
        self.showScoreboardButton:SetAnchor(LEFT, self.leaveBattlegroundButton, RIGHT, KEYBIND_BUTTON_SPACING_X, 0)
    else
        self.showScoreboardButton:SetAnchor(TOP, self.control:GetNamedChild("KeybindContainer"))
    end
    
    if roundResultIndex ~= PLAYER_STATUS_LOSS then
        if battlegroundFinished then
            PlaySound(SOUNDS.BATTLEGROUND_ROUND_RECAP_SCREEN_FINAL_WIN)
        else
            PlaySound(SOUNDS.BATTLEGROUND_ROUND_RECAP_SCREEN_WIN)
        end
    else
        PlaySound(SOUNDS.BATTLEGROUND_ROUND_RECAP_SCREEN_LOSE)
    end
end

-- Create a list with the player's team first and the other teams following in canonical order.
function ZO_BattlegroundRoundRecap:GetPositionedTeamOrder(playerTeam)
    local positionedTeams = { }
    local positionedTeamCount = 0
    
    positionedTeamCount = positionedTeamCount + 1
    positionedTeams[positionedTeamCount] = playerTeam
    
    local currentBattlegroundId = GetCurrentBattlegroundId()
    for teamId = BATTLEGROUND_TEAM_ITERATION_BEGIN, BATTLEGROUND_TEAM_ITERATION_END do
        if teamId ~= playerTeam then
            if DoesBattlegroundHaveTeam(currentBattlegroundId, teamId) then
                positionedTeamCount = positionedTeamCount + 1
                positionedTeams[positionedTeamCount] = teamId
            end
        end
    end
    return positionedTeams
end

-- The data comes out as a list of order-agnostic team:score pairs.  Convert to a canonical ordered list.
function ZO_BattlegroundRoundRecap:GetCurrentBattlegroundRoundScoreList()
    local currentRound = GetCurrentBattlegroundRoundIndex()
    local scores = {}
    for teamId = BATTLEGROUND_TEAM_ITERATION_BEGIN, BATTLEGROUND_TEAM_ITERATION_END do
        scores[teamId] = GetCurrentBattlegroundScore(currentRound, teamId)
    end

    return scores
end

function ZO_BattlegroundRoundRecap:OnShowing()
    self.sceneTimeLoopTimeline:PlayFromStart()
    SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.customNarrationObjectName)
end

function ZO_BattlegroundRoundRecap:OnHiding()
    PlaySound(SOUNDS.BATTLEGROUND_ROUND_RECAP_SCREEN_END)

    for index, flag in ipairs(self.flags) do
        self.flags[index]:Stop()
    end

    self.sceneTimeLoopTimeline:Stop()
end

function ZO_BattlegroundRoundRecap:IsBattlegroundFinished()
    return not DoesBattlegroundHaveRounds(GetCurrentBattlegroundId()) or GetCurrentBattlegroundRoundIndex() == GetBattlegroundNumRounds(GetCurrentBattlegroundId()) or HasTeamWonBattlegroundEarly()
end

do
    local KEYBOARD_STYLE = 
    {
        roundRecapTemplate = "ZO_BattlegroundRoundRecapTopLevel_Keyboard",
        keybindButtonTemplate = "ZO_KeybindButton_Keyboard_Template",
    }

    local GAMEPAD_STYLE = 
    {
        roundRecapTemplate = "ZO_BattlegroundRoundRecapTopLevel_Gamepad",
        keybindButtonTemplate = "ZO_KeybindButton_Gamepad_Template",
    }

    function ZO_BattlegroundRoundRecap:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function ZO_BattlegroundRoundRecap:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style.roundRecapTemplate)
    ApplyTemplateToControl(self.leaveBattlegroundButton, style.keybindButtonTemplate)
    ApplyTemplateToControl(self.showScoreboardButton, style.keybindButtonTemplate)

    -- Re-apply the title and button text so the text is updated with the new modify text type
    self.winTitle:SetText(self.winTitleText)
    self.leaveBattlegroundButton.nameLabel:SetText(GetString(SI_BATTLEGROUND_SCOREBOARD_LEAVE_BATTLEGROUND))
    self.showScoreboardButton.nameLabel:SetText(GetString(SI_BATTLEGROUND_HUD_FRAGMENT_SCOREBOARD_KEYBIND))

    for index, flag in ipairs(self.flags) do
        self.flags[index]:ApplyPlatformStyle()
    end
end

function ZO_BattlegroundRoundRecap:InitializeNarrationInfo()
    self.customNarrationObjectName = "BattlegroundRoundRecap"

    local narrationInfo =
    {
        canNarrate = function()
            return self:IsShowing()
        end,
        selectedNarrationFunction = function()
            local narrations = {}

            -- Title Area
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.winTitle:GetText()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.winSubtitle:GetText()))
            
            local scores = self:GetCurrentBattlegroundRoundScoreList()
            local playerTeam = GetUnitBattlegroundTeam("player")
            -- Create a list with the player's team first and the other teams following in canonical order.
            local positionedTeams = self:GetPositionedTeamOrder(playerTeam)

            -- The screen is ordered with the player first, so we need to extract the scores in that order.
            local numTeams = GetBattlegroundNumTeams(GetCurrentBattlegroundId())
            for positionedTeamIndex = 1, numTeams do
                local teamIndex = positionedTeams[positionedTeamIndex]
                local teamScore = scores[teamIndex]

                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_BATTLEGROUND_RESULT_TEAM_NAME_FORMAT, GetBattlegroundTeamName(teamIndex))))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(teamScore))
            end

            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_RESULT_NEXT_ROUND_TITLE)))
            local currentBattlegroundTimeMS = GetCurrentBattlegroundStateTimeRemaining()
            local formattedTimer = zo_strformat(SI_TIME_FORMAT_SECONDS_DESC, zo_ceil(currentBattlegroundTimeMS / 1000))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(formattedTimer))

            return narrations
        end,
        additionalInputNarrationFunction = function()
            return self:GetKeybindsNarrationData()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject(self.customNarrationObjectName, narrationInfo)
end

function ZO_BattlegroundRoundRecap:GetKeybindsNarrationData()
    local narrationData = {}

    local leaveRecapNarrationData = self.leaveBattlegroundButton:GetKeybindButtonNarrationData()
    if leaveRecapNarrationData then
        table.insert(narrationData, leaveRecapNarrationData)
    end

    local showScoreboardNarrationData = self.showScoreboardButton:GetKeybindButtonNarrationData()
    if showScoreboardNarrationData then
        table.insert(narrationData, showScoreboardNarrationData)
    end

    return narrationData
end

function ZO_BattlegroundRoundRecap:OnKeybindDown(keybind)
    if BATTLEGROUND_ROUND_RECAP_SCENE:IsShowing() then
        local keybindButton = self.keybindActionMap[keybind]
        if keybindButton and keybindButton:IsEnabled() then
            keybindButton:OnClicked()
            return true
        end
    end
    return false
end

function ZO_BattlegroundRoundRecap:OnAnimationPlay(animation, targetControl)
    local roundResult = GetCurrentBattlegroundRoundResult()
    local numTeams = GetBattlegroundNumTeams(GetCurrentBattlegroundId())
    local playerTeam = GetUnitBattlegroundTeam("player")
    local scores = self:GetCurrentBattlegroundRoundScoreList()

    self:SetDetails( roundResult, numTeams, playerTeam, scores)

    for index, flag in ipairs(self.flags) do
        self.flags[index]:Start()
    end
end

function ZO_BattlegroundRoundRecap:OnAnimationStop(animation, targetControl)
    for index, flag in ipairs(self.flags) do
        self.flags[index]:Stop()
    end
end

function ZO_BattlegroundRoundRecap:OnAnimationFlipScores(animation, targetControl)
    PlaySound(SOUNDS.BATTLEGROUND_ROUND_RECAP_FLAG_SCORE_FADE)
    for index, flag in ipairs(self.flags) do
        self.flags[index]:FlipScore()
    end
end

function ZO_BattlegroundRoundRecap:UpdateTimer()
    local currentBattlegroundTimeMS = GetCurrentBattlegroundStateTimeRemaining()
    local coloredTitle = ZO_NORMAL_TEXT:Colorize(GetString(SI_BATTLEGROUND_RESULT_NEXT_ROUND_TITLE))
    local coloredTime = ZO_SELECTED_TEXT:Colorize(ZO_FormatCountdownTimer(zo_ceil(currentBattlegroundTimeMS / 1000)))
    self.countdown:SetText(zo_strformat(SI_BATTLEGROUND_RESULT_NEXT_ROUND_FORMAT, coloredTitle, coloredTime))
end

--[[ xml functions ]]--

function ZO_BattlegroundRoundRecap.InitializeFromControl(control)
    BATTLEGROUND_ROUND_RECAP = ZO_BattlegroundRoundRecap:New(control)
end

function ZO_BattlegroundRoundRecap.OnPlay(animation, targetControl)
    local owner = animation:GetAnimatedControl().owner
    owner:OnAnimationPlay(animation, targetControl)
end

function ZO_BattlegroundRoundRecap.OnStop(animation, targetControl)
    local owner = animation:GetAnimatedControl().owner
    owner:OnAnimationStop(animation, targetControl)
end

function ZO_BattlegroundRoundRecap.OnFlipScores(animation, progressPct)
    local owner = animation:GetAnimatedControl().owner
    owner:OnAnimationFlipScores(animation, progressPct)
end