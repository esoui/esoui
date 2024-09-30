--Team Section

local BATTLEGROUND_TEAM_SECTION_MOVE_SLOTS_PER_SECOND = 4
local BATTLEGROUND_TEAM_SECTION_SPACING = 10
local BG_SCORE_ROUND_START_X = -10
local BG_SCORE_ROUND_OFFSET_Y = 25
local BG_SCORE_ROUND_WIDTH = 24
local BG_SCORE_ROUND_SIZE = 20
local BG_SCORE_LIVES_SIZE = 32

local LIVES_ICONS = 
{
    "esoui/art/battlegrounds/battleground_life_full.dds",
    "esoui/art/battlegrounds/battleground_life_death.dds",
}

local ICONS_KEYBOARD = 
{
    "EsoUI/Art/Battlegrounds/battleground_round_orange.dds",
    "EsoUI/Art/Battlegrounds/battleground_round_green.dds",
    "EsoUI/Art/Battlegrounds/battleground_round_purple.dds",
}

local ICONS_GAMEPAD = 
{
    "EsoUI/Art/Battlegrounds/battleground_round_orange_gp.dds",
    "EsoUI/Art/Battlegrounds/battleground_round_green_gp.dds",
    "EsoUI/Art/Battlegrounds/battleground_round_purple_gp.dds",
}

ZO_BattlegroundTeamSection = ZO_InitializingObject:Subclass()

do
    local KEYBOARD_STYLE =
    {
        scoreFont = "ZoFontWinH1",
    }

    local GAMEPAD_STYLE =
    {
        scoreFont = "ZoFontGamepad36",
    }    

    function ZO_BattlegroundTeamSection:Initialize(control, battlegroundAlliance, parentHud)
        self.control = control
        self.scoreLabel = control:GetNamedChild("Score")
        self.attributeBarControl = control:GetNamedChild("ScoreDisplay")
        self.statusBar = self.attributeBarControl:GetNamedChild("Bar")
        self.scoreLabel = self.attributeBarControl:GetNamedChild("Value")
        self.iconTexture = control:GetNamedChild("Icon")
        self.roundsControl = control:GetNamedChild("Rounds")
        self.battlegroundAlliance = battlegroundAlliance
        self.parentHud = parentHud

        ZO_StatusBar_SetGradientColor(self.statusBar, ZO_BATTLEGROUND_ALLIANCE_STATUS_BAR_GRADIENTS[battlegroundAlliance])

        ZO_PlatformStyle:New(function(style) self:ApplyStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

        self:UpdateScore()
    end
end

function ZO_BattlegroundTeamSection:GetControl()
    return self.control
end

function ZO_BattlegroundTeamSection:GetBattlegroundAlliance()
    return self.battlegroundAlliance
end

function ZO_BattlegroundTeamSection:SetTargetOrder(order)
    self.targetOrder = order
end

function ZO_BattlegroundTeamSection:SetOrder(order)
    self.order = order
    self.targetOrder = order
    self:UpdateAnchor()
end

function ZO_BattlegroundTeamSection:UpdateOrder(deltaMS)
    local lastOrder = self.order
    if not self.order then
        self.order = self.targetOrder
    else
        if self.targetOrder > self.order then
            self.order = zo_min(self.targetOrder, self.order + deltaMS * BATTLEGROUND_TEAM_SECTION_MOVE_SLOTS_PER_SECOND)
        else
            self.order = zo_max(self.targetOrder, self.order - deltaMS * BATTLEGROUND_TEAM_SECTION_MOVE_SLOTS_PER_SECOND)
        end
    end
    if self.order ~= lastOrder then
        self:UpdateAnchor()
    end
end

function ZO_BattlegroundTeamSection:UpdateAnchor()
    local sectionHeight = self.control:GetHeight()
    local zeroBasedOrder = self.order - 1
    local topLeftY = zeroBasedOrder * (sectionHeight + BATTLEGROUND_TEAM_SECTION_SPACING)
    self.control:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, topLeftY)
end

function ZO_BattlegroundTeamSection:ApplyStyle(style)
    self.scoreLabel:SetFont(style.scoreFont)
    self.iconTexture:SetTexture(ZO_GetBattlegroundTeamIcon(self.battlegroundAlliance))
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_BattlegroundTeamSection"))
    ApplyTemplateToControl(self.attributeBarControl:GetNamedChild("BgLeft"), ZO_GetPlatformTemplate("ZO_PlayerAttributeBgLeft"))
    ApplyTemplateToControl(self.attributeBarControl:GetNamedChild("BgRight"), ZO_GetPlatformTemplate("ZO_PlayerAttributeBgRightArrow"))
    ApplyTemplateToControl(self.attributeBarControl:GetNamedChild("BgCenter"), ZO_GetPlatformTemplate("ZO_PlayerAttributeBgCenter"))
    ApplyTemplateToControl(self.statusBar, ZO_GetPlatformTemplate("ZO_PlayerAttributeStatusBar"))
    ApplyTemplateToControl(self.statusBar, ZO_GetPlatformTemplate("ZO_PlayerAttributeBarAnchorRight"))
    ApplyTemplateToControl(self.statusBar:GetNamedChild("Gloss"), ZO_GetPlatformTemplate("ZO_PlayerAttributeStatusBarGloss"))
    ApplyTemplateToControl(self.attributeBarControl:GetNamedChild("FrameLeft"), ZO_GetPlatformTemplate("ZO_PlayerAttributeFrameLeft"))
    ApplyTemplateToControl(self.attributeBarControl:GetNamedChild("FrameRight"), ZO_GetPlatformTemplate("ZO_PlayerAttributeFrameRightArrow"))
    ApplyTemplateToControl(self.attributeBarControl:GetNamedChild("FrameCenter"), ZO_GetPlatformTemplate("ZO_PlayerAttributeFrameCenter"))
    ApplyTemplateToControl(self.scoreLabel, ZO_GetPlatformTemplate("ZO_BattlegroundScoreHudScoreLabel"))

    self:UpdateTeamUI()
end

function ZO_BattlegroundTeamSection:GetScore()
    return self.score
end

function ZO_BattlegroundTeamSection:UpdateScore()
    local score = GetCurrentBattlegroundScore(GetCurrentBattlegroundRoundIndex(), self.battlegroundAlliance)
    local scoreToWin = GetScoreToWinCurrentBattlegroundRound()
    local lastScore = self.score
    if lastScore ~= nil and score > lastScore then
        if scoreToWin > 0 then
            local lastScorePercent = lastScore / scoreToWin
            local currentScorePercent = score / scoreToWin
            local nearingVictoryPercent = GetCurrentBattlegroundRoundNearingVictoryPercent()
            --Since we use a float for percent it can be slightly off value. We use float equality for the equals part of these checks.
            if (lastScorePercent < nearingVictoryPercent and not zo_floatsAreEqual(lastScorePercent, nearingVictoryPercent)) and
                (currentScorePercent > nearingVictoryPercent or zo_floatsAreEqual(currentScorePercent, nearingVictoryPercent)) then
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_MAJOR_TEXT, SOUNDS.BATTLEGROUND_NEARING_VICTORY)
                local text
                if self.battlegroundAlliance == GetUnitBattlegroundTeam("player") then
                    text = zo_strformat(SI_BATTLEGROUND_NEARING_VICTORY_OWN_TEAM, GetColoredBattlegroundYourTeamText(self.battlegroundAlliance))
                else
                    text = zo_strformat(SI_BATTLEGROUND_NEARING_VICTORY_OTHER_TEAM, GetColoredBattlegroundTeamName(self.battlegroundAlliance))
                end
                messageParams:SetText(text)
                messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_NEARING_VICTORY)
                CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
            end
        end
    end
    self.score = score
    self.scoreLabel:SetText(score)
    self.statusBar:SetMinMax(0, scoreToWin)
    self.statusBar:SetValue(score)
    self:UpdateTeamUI()
end

function ZO_BattlegroundTeamSection:UpdateTeamUI()
    local isGamepad = IsInGamepadPreferredMode()
    local ICONS = isGamepad and ICONS_GAMEPAD or ICONS_KEYBOARD
    local DEFAULT_ROUND_ICON = isGamepad and "EsoUI/Art/Battlegrounds/battleground_round_empty_gp.dds" or "EsoUI/Art/Battlegrounds/battleground_round_empty.dds"
    
    for index, control in ipairs(self.points or {}) do
        self.parentHud.hudIconsPool:ReleaseObject(control.objectKey)
    end

    local maxRounds = zo_floor(GetBattlegroundNumRounds(GetCurrentBattlegroundId()) / 2 + 1)
    local roundsWonByTeam = GetCurrentBattlegroundRoundsWonByTeam(self.battlegroundAlliance)
    if maxRounds > 1 then
        self.points = {}
        for pipCount = 1, maxRounds do
            local control, objectKey = self.parentHud.hudIconsPool:AcquireObject()
            control.objectKey = objectKey
            control.icon = control:GetNamedChild("Icon")

            if pipCount <= roundsWonByTeam then
                control.icon:SetTexture(ICONS[self.battlegroundAlliance])
            else
                control.icon:SetTexture(DEFAULT_ROUND_ICON)
            end

            table.insert(self.points, control)
            control:SetParent(self.roundsControl)
            control:SetDimensions(BG_SCORE_ROUND_SIZE,BG_SCORE_ROUND_SIZE) -- Lives are bigger than scores, but they use the same pool.
            control:SetAnchor(BOTTOMRIGHT, self.roundsControl, BOTTOMRIGHT, BG_SCORE_ROUND_START_X - (maxRounds - pipCount) * BG_SCORE_ROUND_WIDTH, BG_SCORE_ROUND_OFFSET_Y)
        end
    end
end

function ZO_BattlegroundTeamSection:OnUpdate(deltaS)
    self:UpdateOrder(deltaS)
end

--Score Hud

ZO_BattlegroundScoreHud = ZO_Object:Subclass()

function ZO_BattlegroundScoreHud:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_BattlegroundScoreHud:Initialize(control)
    self.control = control
    self.objectiveStateDisplayControl = control:GetNamedChild("ObjectiveStateDisplay")
    self.teamsControl = control:GetNamedChild("Teams")
    self.livesControl = control:GetNamedChild("Lives")
    self.playerTeamIndicatorTexture = control:GetNamedChild("PlayerTeamIndicator")
    self.objectiveStateLayout = ZO_BattlegroundObjectiveStateLayout:New(self.objectiveStateDisplayControl)

    self.hudIconsPool = ZO_ControlPool:New("BattlegroundScoreHudWinCounter", control, "RoundWinner")
    self.hudIconsPool:ReleaseAllObjects()
    self.backgroundTexture = control:GetNamedChild("Background")
    self:CreateTeamSections()
    self:OnZoneScoringChanged()
    self:RegisterEvents()
    self.indicatorManager = ZO_BattlegroundObjectiveStateIndicatorManager:New(self)
    self.gameType = BATTLEGROUND_GAME_TYPE_NONE
    self:UpdateGameType()

    -- Force an initial update.
    self:OnBattlegroundRulesetChanged()

    local KEYBOARD_STYLE =
    {
    }

    local GAMEPAD_STYLE =
    {
    }

    ZO_PlatformStyle:New(function(style) self:ApplyStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
end

function ZO_BattlegroundScoreHud:ApplyStyle(style)
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_BattlegroundScoreHud"))
end

function ZO_BattlegroundScoreHud:GetControl()
    return self.control
end

function ZO_BattlegroundScoreHud:GetObjectiveStateLayout()
    return self.objectiveStateLayout
end

function ZO_BattlegroundScoreHud:CreateTeamSections()
    self.teamSectionSort = function(a, b)
        local aScore = a:GetScore()
        local bScore = b:GetScore()
        if aScore ~= bScore then
            return aScore > bScore
        end
        return a:GetBattlegroundAlliance() < b:GetBattlegroundAlliance()
    end

    self.teamSections = {}
    for bgTeam = BATTLEGROUND_TEAM_ITERATION_BEGIN, BATTLEGROUND_TEAM_ITERATION_END do --TODO Unavailable pre battleground -- GetBattlegroundNumTeams(GetCurrentBattlegroundId()) do
        local control = CreateControlFromVirtual("$(parent)Section", self.teamsControl, "ZO_BattlegroundTeamSection", bgTeam)
        table.insert(self.teamSections, ZO_BattlegroundTeamSection:New(control, bgTeam, self))
    end
    local DONT_ANIMATE = false
    self:SortTeamSections(DONT_ANIMATE)
end

function ZO_BattlegroundScoreHud:SortTeamSections(animate)
    table.sort(self.teamSections, self.teamSectionSort)
    for i, section in ipairs(self.teamSections) do
        if animate then
            section:SetTargetOrder(i)
        else
            section:SetOrder(i)
        end
    end
end

function ZO_BattlegroundScoreHud:RefreshPlayerTeamIndicator()
    local playerBattlegroundAlliance = GetUnitBattlegroundTeam("player")
    for _, section in ipairs(self.teamSections) do
        if section:GetBattlegroundAlliance() == playerBattlegroundAlliance then
            local sectionControl = section.iconTexture
            self.playerTeamIndicatorTexture:SetAnchor(RIGHT, sectionControl, LEFT, -9, 0)
            break
        end
    end
end

function ZO_BattlegroundScoreHud:RegisterEvents()
    self.control:RegisterForEvent(EVENT_ZONE_SCORING_CHANGED, function() self:OnZoneScoringChanged() end)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    self.control:RegisterForEvent(EVENT_BATTLEGROUND_RULESET_CHANGED, function() self:OnBattlegroundRulesetChanged() end)
    self.control:RegisterForEvent(EVENT_OBJECTIVES_UPDATED, function() self:OnObjectivesUpdated() end)
end

function ZO_BattlegroundScoreHud:OnUpdate(control, timeS)
    if self.lastUpdateS then
        local deltaS = timeS - self.lastUpdateS
        for _, section in ipairs(self.teamSections) do
            section:OnUpdate(deltaS)
        end
    end

    for index, iconControl in ipairs(self.lives or {}) do
        self.hudIconsPool:ReleaseObject(iconControl.objectKey)
    end
    local currentBattlegroundId = GetCurrentBattlegroundId()
    if DoesBattlegroundHaveLimitedPlayerLives(currentBattlegroundId) then
        local numPlayerLives = GetLocalPlayerBattlegroundLivesRemaining()
        self.lives= {}
        for lifeIconNumber = 1, GetBattlegroundMaxPlayerLives(currentBattlegroundId) do
            local control, objectKey = self.hudIconsPool:AcquireObject()
            control.objectKey = objectKey
            control.icon = control:GetNamedChild("Icon")

            local isLiving = (lifeIconNumber <= numPlayerLives)
            local lifeIconIndex = isLiving and 1 or 2
            control.icon:SetTexture(LIVES_ICONS[lifeIconIndex])
            local iconColor = isLiving and ZO_WHITE or ZO_WHITE:GetDim()
            control.icon:SetColor(iconColor:UnpackRGBA())
        
            table.insert(self.lives, control)
            control:SetParent(self.livesControl)
            control:SetDimensions(BG_SCORE_LIVES_SIZE,BG_SCORE_LIVES_SIZE) -- Lives are bigger than scores, but they use the same pool.
            control:SetAnchor(TOPLEFT, self.livesControl, TOPLEFT, 0 + (lifeIconNumber - 1) * BG_SCORE_LIVES_SIZE, 0)
        end
    end

    self.lastUpdateS = timeS
end

function ZO_BattlegroundScoreHud:OnZoneScoringChanged()
    -- Figure out which teams are active.
    local numTeams = GetBattlegroundNumTeams(GetCurrentBattlegroundId())
    for bgTeam = BATTLEGROUND_TEAM_ITERATION_BEGIN, BATTLEGROUND_TEAM_ITERATION_END do
        local isHidden = bgTeam > numTeams
        self.teamSections[bgTeam].control:SetHidden(isHidden)
    end
 
    self:CallOnTeamSections("UpdateScore")
    local ANIMATE = true
    self:SortTeamSections(ANIMATE)
end

function ZO_BattlegroundScoreHud:OnPlayerActivated()
    self:UpdateGameType()
    self.indicatorManager:OnObjectivesUpdated()
    self:RefreshPlayerTeamIndicator()
end

function ZO_BattlegroundScoreHud:OnBattlegroundRulesetChanged()
    local currentBattlegroundId = GetCurrentBattlegroundId()
    if currentBattlegroundId ~= 0 then
        EVENT_MANAGER:RegisterForUpdate(self.control:GetName(), 10, function() self:OnUpdate() end)

        self:UpdateGameType()
        self:CallOnTeamSections("UpdateScore")
        local DONT_ANIMATE = false
        self:SortTeamSections(DONT_ANIMATE)
        self:RefreshPlayerTeamIndicator()    
    else
        EVENT_MANAGER:UnregisterForUpdate(self.control:GetName())
    end
end

function ZO_BattlegroundScoreHud:OnObjectivesUpdated()
    self.indicatorManager:OnObjectivesUpdated()
end

function ZO_BattlegroundScoreHud:CallOnTeamSections(functionName, ...)
    for _, section in ipairs(self.teamSections) do
        section[functionName](section, ...)
    end
end

function ZO_BattlegroundScoreHud:UpdateGameType()
    local gameType = GetCurrentBattlegroundGameType()
    if self.gameType ~= gameType then
        self.gameType = gameType
        self.indicatorManager:OnBattlegroundGameTypeChanged(gameType)
    end
end

function ZO_BattlegroundScoreHud_OnInitialized(self)
    BATTLEGROUND_SCORE_HUD = ZO_BattlegroundScoreHud:New(self)
end