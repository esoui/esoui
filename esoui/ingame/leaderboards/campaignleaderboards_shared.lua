-----------------
-- Leaderboard Campaign Selector Shared
-----------------
CAMPAIGN_LEADERBOARD_SYSTEM_NAME = "campaignLeaderboards"

ZO_LeaderboardCampaignSelector_Shared = ZO_CampaignSelector_Shared:Subclass()

function ZO_LeaderboardCampaignSelector_Shared:New(control)
    local selector = ZO_CampaignSelector_Shared.New(self, control)
    return selector
end

function ZO_LeaderboardCampaignSelector_Shared:Initialize(control)
    ZO_CampaignSelector_Shared.Initialize(self, control)

    self.control = control
    self.tabs = GetControl(control, "Tabs")

    self:SetCampaignWindows()

    control:RegisterForEvent(EVENT_CURRENT_CAMPAIGN_CHANGED, function() self:OnCurrentCampaignChanged() end)
    control:RegisterForEvent(EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:OnAssignedCampaignChanged() end)
end

function ZO_LeaderboardCampaignSelector_Shared:SetCampaignWindows()
    -- Should be overridden
end

function ZO_LeaderboardCampaignSelector_Shared:NeedsData()
    -- Should be overridden
end

function ZO_LeaderboardCampaignSelector_Shared:RefreshQueryTypes()
    -- Should be overridden
end

function ZO_LeaderboardCampaignSelector_Shared:OnQueryTypeChanged(tabData)
    local selectedQueryType = tabData.queryType
    if(selectedQueryType ~= self.selectedQueryType) then
        self.selectedQueryType = selectedQueryType
        self:UpdateCampaignWindows()
        self.dataRegistration:Refresh()
    end
end

-----------------
-- Campaign Leaderboards Shared
-----------------

ZO_CampaignLeaderboardsManager_Shared = ZO_LeaderboardBase_Shared:Subclass()

function ZO_CampaignLeaderboardsManager_Shared:New(...)
    return ZO_LeaderboardBase_Shared.New(self, ...)
end

function ZO_CampaignLeaderboardsManager_Shared:Initialize(...)
    ZO_LeaderboardBase_Shared.Initialize(self, ...)
end

function ZO_CampaignLeaderboardsManager_Shared:InitializeTimer()
    local UPDATE_INTERVAL_SECS = 1

    self.lastUpdateSecs = 0

    local function TimerLabelOnUpdate(control, currentTime)
        if currentTime - self.lastUpdateSecs >= UPDATE_INTERVAL_SECS then
            local secsUntilStart = GetSecondsUntilCampaignStart(self.campaignId)
            local secsUntilEnd = GetSecondsUntilCampaignEnd(self.campaignId)

            if secsUntilStart > 0 then
                self.timerLabelIdentifier = SI_LEADERBOARDS_REOPENS_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilStart, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                self.scoringInfoData = GetString(SI_CAMPAIGN_LEADERBOARDS_SCORING_CLOSED)
            elseif secsUntilEnd > 0 then
                self.timerLabelIdentifier = SI_LEADERBOARDS_CLOSES_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilEnd, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                self.scoringInfoText = GetString(SI_CAMPAIGN_LEADERBOARDS_SCORING_OPEN)
            else
                self.timerLabelIdentifier = nil
                self.timerLabelData = nil
                self.scoringInfoText = GetString(SI_CAMPAIGN_LEADERBOARDS_SCORING_NOT_AVAILABLE)
            end

            self.lastUpdateSecs = currentTime
        end

        self:RefreshHeaderTimer()
    end

    self.control:SetHandler("OnUpdate", TimerLabelOnUpdate)
end

function ZO_CampaignLeaderboardsManager_Shared:UpdatePlayerInfo(points, rank)
    self.currentScoreData = points
    self.currentRankData = rank

    self:RefreshHeaderPlayerInfo()
end

function ZO_CampaignLeaderboardsManager_Shared:GetScoreAndRankTexts()
    local playerCanHaveRank
    if not self.selectedSubType then
        playerCanHaveRank = true
    else
        playerCanHaveRank = self.selectedSubType == GetUnitAlliance("player")
    end

    local displayedScore
    if self.currentScoreData then
        displayedScore = self.currentScoreData
    else
        displayedScore = playerCanHaveRank and 0 or GetString(SI_LEADERBOARDS_STAT_NOT_AVAILABLE)
    end

    local displayedRank
    if self.currentRankData then
        displayedRank = self.currentRankData
    else
        displayedRank = playerCanHaveRank and GetString(SI_LEADERBOARDS_NOT_RANKED) or GetString(SI_LEADERBOARDS_STAT_NOT_AVAILABLE)
    end

    return displayedScore, displayedRank
end

function ZO_CampaignLeaderboardsManager_Shared:AddCategoriesToParentSystem()
    local isInCampaign = GetCurrentCampaignId() ~= 0
    local homeCampaignAssigned = GetAssignedCampaignId() ~= 0
    if not (isInCampaign or homeCampaignAssigned) then
        return
    end

    local header = self.leaderboardSystem:AddCategory(GetString(SI_CAMPAIGN_LEADERBOARDS_CATEGORIES_HEADER), "EsoUI/Art/Journal/leaderboard_indexIcon_ava_up.dds", "EsoUI/Art/Journal/leaderboard_indexIcon_ava_down.dds", "EsoUI/Art/Journal/leaderboard_indexIcon_ava_over.dds")

    local function GetMaxRank()
        return GetCampaignLeaderboardMaxRank(self.campaignId)
    end

    local function GetOverallCount()
        self:UpdatePlayerInfo()
        return GetNumCampaignLeaderboardEntries(self.campaignId)
    end

    local function GetOverallInfo(entryIndex)
        local isPlayer, rank, name, points, class, alliance, displayName = GetCampaignLeaderboardEntryInfo(self.campaignId, entryIndex)
        if isPlayer then
            self:UpdatePlayerInfo(points, rank)
        end

        return rank, name, points, class, alliance, displayName
    end

    local function GetOverallConsoleIdRequestParams(index)
        return ZO_ID_REQUEST_TYPE_CAMPAIGN_LEADERBOARD, self.campaignId, index
    end

    self.leaderboardSystem:AddEntry(self, GetString(SI_CAMPAIGN_LEADERBOARDS_OVERALL), nil, header, nil, GetOverallCount, GetMaxRank, GetOverallInfo, nil, nil, GetOverallConsoleIdRequestParams, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_overall.dds", LEADERBOARD_TYPE_OVERALL)

    local function GetSingleAllianceCount(alliance)
        self:UpdatePlayerInfo()
        return GetNumCampaignAllianceLeaderboardEntries(self.campaignId, alliance)
    end

    local function GetSingleAllianceInfo(entryIndex, alliance)
        local isPlayer, rank, name, points, class, displayName = GetCampaignAllianceLeaderboardEntryInfo(self.campaignId, alliance, entryIndex)
        if isPlayer then
            self:UpdatePlayerInfo(points, rank)
        end

        return rank, name, points, class, alliance, displayName
    end

    local function GetSingleAllianceConsoleIdRequestParams(index, alliance)
        return ZO_ID_REQUEST_TYPE_CAMPAIGN_ALLIANCE_LEADERBOARD, self.campaignId, index, alliance
    end

    local function AddAllianceEntryToLeaderboard(alliance, iconPath)
        self.leaderboardSystem:AddEntry(self, zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(alliance)), nil, header, alliance, GetSingleAllianceCount, GetMaxRank, GetSingleAllianceInfo, nil, nil, GetSingleAllianceConsoleIdRequestParams, iconPath, LEADERBOARD_TYPE_ALLIANCE)
    end

    AddAllianceEntryToLeaderboard(ALLIANCE_ALDMERI_DOMINION, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_aldmeri.dds")
    AddAllianceEntryToLeaderboard(ALLIANCE_DAGGERFALL_COVENANT, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_daggerfall.dds")
    AddAllianceEntryToLeaderboard(ALLIANCE_EBONHEART_PACT, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_ebonheart.dds")
end

function ZO_CampaignLeaderboardsManager_Shared:SetCampaignAndQueryType(campaignId, queryType)
    self.campaignId = campaignId
    self:OnDataChanged()
end