------------------
-- Medal Object --
------------------

ZO_BattlegroundMatchInfo_MedalObject = ZO_InitializingObject:Subclass()

function ZO_BattlegroundMatchInfo_MedalObject:Initialize(control)
    self.control = control
    self.iconTexture = control:GetNamedChild("Icon")
    self.countLabel = self.iconTexture:GetNamedChild("Count")
    local textContainer = control:GetNamedChild("Text")
    self.nameLabel = textContainer:GetNamedChild("Name")
    self.pointsLabel = textContainer:GetNamedChild("Points")
end

function ZO_BattlegroundMatchInfo_MedalObject:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_BattlegroundMatchInfo_MedalObject:SetupMedalInfo(medalId, count)
    local name, icon, _, scoreReward = GetMedalInfo(medalId)
    self.nameLabel:SetText(name)
    self.countLabel:SetText(count)
    self.iconTexture:SetTexture(icon)
    local points = count * scoreReward
    if IsInGamepadPreferredMode() then
        self.pointsLabel:SetText(points)
    else
        self.pointsLabel:SetText(zo_strformat(SI_BATTLEGROUND_MATCH_INFO_POINTS_FORMATTER_KEYBOARD, points))
    end
    
end

----------------------
-- Match Info Panel --
----------------------

local MAX_NUM_MEDALS_DISPLAYED = 5

ZO_BattlegroundMatchInfo_Shared = ZO_InitializingObject:Subclass()

function ZO_BattlegroundMatchInfo_Shared:Initialize(control, medalControlTemplate, medalControlPadding)
    self.control = control
    local container = control:GetNamedChild("Container")
    self.playerNameLabel = container:GetNamedChild("PlayerName")
    self.playerClassTexture = container:GetNamedChild("PlayerClass")
    self.titleLabel = container:GetNamedChild("Title")

    local statsControl = container:GetNamedChild("Stats")
    local damageControl = statsControl:GetNamedChild("DamageDealt")
    local damageDealtHeaderLabel = damageControl:GetNamedChild("Header")
    -- Save off text for narration
    self.damageDealtLabelText = GetString("SI_SCORETRACKERENTRYTYPE", SCORE_TRACKER_TYPE_DAMAGE_DONE)
    damageDealtHeaderLabel:SetText(self.damageDealtLabelText)
    self.damageDealtValueLabel =  damageControl:GetNamedChild("Value")
    local healingControl = statsControl:GetNamedChild("HealingDone")
    local healingDoneHeaderLabel = healingControl:GetNamedChild("Header")
    -- Save off text for narration
    self.healingLabelText = GetString("SI_SCORETRACKERENTRYTYPE", SCORE_TRACKER_TYPE_HEALING_DONE)
    healingDoneHeaderLabel:SetText(self.healingLabelText)
    self.healingDoneValueLabel =  healingControl:GetNamedChild("Value")

    local medalsContainer = container:GetNamedChild("Medals")
    self.medalObjects = {}
    local previousMedalControl
    for i = 1, MAX_NUM_MEDALS_DISPLAYED do
        local medalControl = CreateControlFromVirtual("$(parent)Medal" .. i, medalsContainer, medalControlTemplate)
        if previousMedalControl then
            medalControl:SetAnchor(TOPLEFT, previousMedalControl, BOTTOMLEFT, 0, medalControlPadding)
        else
            medalControl:SetAnchor(TOPLEFT)
        end
        medalControl:SetAnchor(RIGHT, medalsContainer, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X)
        local medalObject = ZO_BattlegroundMatchInfo_MedalObject:New(medalControl)
        table.insert(self.medalObjects, medalObject)
        previousMedalControl = medalControl
    end

    self.scoreboardEntryRawMedalData = {}

    self.noMedalsLabel = container:GetNamedChild("NoMedalsText")

    self.fragment = ZO_FadeSceneFragment:New(control)
end

function ZO_BattlegroundMatchInfo_Shared:GetFragment()
    return self.fragment
end

do
    local function MedalSort(left, right)
        local leftTotalValue = left.scoreReward * left.count
        local rightTotalValue = right.scoreReward * right.count

        if leftTotalValue == rightTotalValue then
            if left.scoreReward == right.scoreReward then
                return left.name > right.name
            end

            return left.scoreReward > right.scoreReward
        end

        return leftTotalValue > rightTotalValue
    end

    function ZO_BattlegroundMatchInfo_Shared:SetupScoreTypeRow(roundIndex, entryIndex, scoreType, rowValueLabel, showAggregateScores)
        local score
        if showAggregateScores then
            score = GetBattlegroundCumulativeScoreForScoreboardEntryByType(entryIndex, scoreType, roundIndex)
        else
            score = GetScoreboardEntryScoreByType(entryIndex, scoreType, roundIndex)
        end
        local USE_LOWERCASE_NUMBER_SUFFIXES = false
        self.scoreRowValueTable[scoreType] = ZO_AbbreviateAndLocalizeNumber(score, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
        rowValueLabel:SetText(self.scoreRowValueTable[scoreType])
    end

    function ZO_BattlegroundMatchInfo_Shared:SetupForScoreboardEntry(roundIndex, entryIndex, showAggregateScores)
        self.scoreRowValueTable = {}
        self:SetupScoreTypeRow(roundIndex, entryIndex, SCORE_TRACKER_TYPE_DAMAGE_DONE, self.damageDealtValueLabel, showAggregateScores)
        self:SetupScoreTypeRow(roundIndex, entryIndex, SCORE_TRACKER_TYPE_HEALING_DONE, self.healingDoneValueLabel, showAggregateScores)

        local classId = GetScoreboardEntryClassId(entryIndex, roundIndex)
        self.playerClassTexture:SetTexture(ZO_GetPlatformClassIcon(classId))

        local characterName, displayName = GetScoreboardEntryInfo(entryIndex, roundIndex)
        local primaryName = ZO_GetPrimaryPlayerName(ZO_FormatUserFacingDisplayName(displayName), characterName)
        local formattedName = zo_strformat(SI_PLAYER_NAME, primaryName)
        self.playerNameLabel:SetText(formattedName)

        if showAggregateScores or not DoesBattlegroundHaveRounds(GetCurrentBattlegroundId()) then
            self.titleLabel:SetText(GetString(SI_BATTLEGROUND_MATCH_INFO_PANEL_TITLE))
        else
            self.titleLabel:SetText(zo_strformat(SI_BATTLEGROUND_MATCH_INFO_ROUND_PANEL_TITLE, roundIndex))
        end

        ZO_ClearNumericallyIndexedTable(self.scoreboardEntryRawMedalData)

        local GetNextScoreboardEntryMedalIdIter
        local GetNumEarnedMedalsById

        if showAggregateScores then
            GenerateCumulativeMedalInfoForScoreboardEntry(entryIndex, roundIndex)
            GetNextScoreboardEntryMedalIdIter = function(state, lastMedalId)
                return GetNextBattlegroundCumulativeMedalId(lastMedalId)
            end
            GetNumEarnedMedalsById = function(medalId)
                return GetBattlegroundCumulativeNumEarnedMedalsById(medalId)
            end
        else
            GetNextScoreboardEntryMedalIdIter = function(state, lastMedalId)
                return GetNextScoreboardEntryMedalId(entryIndex, roundIndex, lastMedalId)
            end
            GetNumEarnedMedalsById = function(medalId)
                return GetScoreboardEntryNumEarnedMedalsById(entryIndex, medalId, roundIndex)
            end
        end

        for medalId in GetNextScoreboardEntryMedalIdIter do
            local name, _, _, scoreReward = GetMedalInfo(medalId)
            local rawMedalInfo = 
            {
                medalId = medalId,
                name = name,
                scoreReward = scoreReward,
                count = GetNumEarnedMedalsById(medalId),
            }
            table.insert(self.scoreboardEntryRawMedalData, rawMedalInfo)
        end

        table.sort(self.scoreboardEntryRawMedalData, MedalSort)

        for i = 1, MAX_NUM_MEDALS_DISPLAYED do
            local rawData = self.scoreboardEntryRawMedalData[i]
            local medalObject = self.medalObjects[i]
            if rawData then
                medalObject:SetupMedalInfo(rawData.medalId, rawData.count)
                medalObject:SetHidden(false)
            else
                medalObject:SetHidden(true)
            end
        end

        self.noMedalsLabel:SetHidden(#self.scoreboardEntryRawMedalData > 0)
    end
end