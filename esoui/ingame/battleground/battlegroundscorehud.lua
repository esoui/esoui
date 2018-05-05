--Team Section

local BATTLEGROUND_TEAM_SECTION_MOVE_SLOTS_PER_SECOND = 4
local BATTLEGROUND_TEAM_SECTION_SPACING = 10

ZO_BattlegroundTeamSection = ZO_Object:Subclass()

function ZO_BattlegroundTeamSection:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

do
    local KEYBOARD_STYLE =
    {
        scoreFont = "ZoFontWinH1",
    }

    local GAMEPAD_STYLE =
    {
        scoreFont = "ZoFontGamepad36",
    }    

    function ZO_BattlegroundTeamSection:Initialize(control, battlegroundAlliance)
        self.control = control
        self.scoreLabel = control:GetNamedChild("Score")
        self.attributeBarControl = control:GetNamedChild("ScoreDisplay")
        self.statusBar = self.attributeBarControl:GetNamedChild("Bar")
        self.scoreLabel = self.attributeBarControl:GetNamedChild("Value")
        self.iconTexture = control:GetNamedChild("Icon")
        self.battlegroundAlliance = battlegroundAlliance

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
    self.iconTexture:SetTexture(GetBattlegroundTeamIcon(self.battlegroundAlliance))
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
end

function ZO_BattlegroundTeamSection:GetScore()
    return self.score
end

function ZO_BattlegroundTeamSection:UpdateScore()
    local score = GetCurrentBattlegroundScore(self.battlegroundAlliance)
    local currentBattlegroundId = GetCurrentBattlegroundId()
    local scoreToWin = GetScoreToWinBattleground(currentBattlegroundId)
    local lastScore = self.score
    if lastScore ~= nil and score > lastScore then
        if scoreToWin > 0 then
            local lastScorePercent = lastScore / scoreToWin
            local currentScorePercent = score / scoreToWin
            local nearingVictoryPercent = GetBattlegroundNearingVictoryPercent(currentBattlegroundId)
            --Since we use a float for percent it can be slighltly off value. We use float equality for the equals part of these checks.
            if (lastScorePercent < nearingVictoryPercent and not zo_floatsAreEqual(lastScorePercent, nearingVictoryPercent)) and
                (currentScorePercent > nearingVictoryPercent or zo_floatsAreEqual(currentScorePercent, nearingVictoryPercent)) then
                local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_MAJOR_TEXT, SOUNDS.BATTLEGROUND_NEARING_VICTORY)
                local text
                if self.battlegroundAlliance == GetUnitBattlegroundAlliance("player") then
                    text = zo_strformat(SI_BATTLEGROUND_NEARING_VICTORY_OWN_TEAM, GetColoredBattlegroundYourTeamText(self.battlegroundAlliance))
                else
                    text = zo_strformat(SI_BATTLEGROUND_NEARING_VICTORY_OTHER_TEAM, GetColoredBattlegroundAllianceName(self.battlegroundAlliance))
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
    control:SetHandler("OnUpdate", function(...) self:OnUpdate(...) end)
    self.objectiveStateDisplayControl = control:GetNamedChild("ObjectiveStateDisplay")
    self.teamsControl = control:GetNamedChild("Teams")
    self.playerTeamIndicatorTexture = control:GetNamedChild("PlayerTeamIndicator")
    self.objectiveStateLayout = ZO_BattlegroundObjectiveStateLayout:New(self.objectiveStateDisplayControl)

    self.backgroundTexture = control:GetNamedChild("Background")
    self:CreateTeamSections()
    self:RegisterEvents()
    self.indicatorManager = ZO_BattlegroundObjectiveStateIndicatorManager:New(self)
    self.gameType = BATTLEGROUND_GAME_TYPE_NONE
    self:UpdateGameType()
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
    for bgAlliance = BATTLEGROUND_ALLIANCE_ITERATION_BEGIN, BATTLEGROUND_ALLIANCE_ITERATION_END do
        local control = CreateControlFromVirtual("$(parent)Section", self.teamsControl, "ZO_BattlegroundTeamSection", bgAlliance)
        table.insert(self.teamSections, ZO_BattlegroundTeamSection:New(control, bgAlliance))
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
    local playerBattlegroundAlliance = GetUnitBattlegroundAlliance("player")
    for _, section in ipairs(self.teamSections) do
        if section:GetBattlegroundAlliance() == playerBattlegroundAlliance then
            local sectionControl = section:GetControl()
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
    self.lastUpdateS = timeS
end

function ZO_BattlegroundScoreHud:OnZoneScoringChanged()
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
    self:UpdateGameType()
    self:CallOnTeamSections("UpdateScore")
    local DONT_ANIMATE = false
    self:SortTeamSections(DONT_ANIMATE)
    self:RefreshPlayerTeamIndicator()
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
    local battlegroundId = GetCurrentBattlegroundId()
    local gameType = GetBattlegroundGameType(battlegroundId)
    if self.gameType ~= gameType then
        self.gameType = gameType
        self.indicatorManager:OnBattlegroundGameTypeChanged(gameType)
    end
end

function ZO_BattlegroundScoreHud_OnInitialized(self)
    BATTLEGROUND_SCORE_HUD = ZO_BattlegroundScoreHud:New(self)
end