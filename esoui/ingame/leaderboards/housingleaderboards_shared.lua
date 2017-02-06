---------------
-- Housing Leaderboards
---------------
HOUSING_LEADERBOARD_SYSTEM_NAME = "housingLeaderboards"

local HOME_SHOW_HEADER_ICONS =
{
    up = "EsoUI/Art/Journal/leaderboard_indexIcon_housing_up.dds", 
    down = "EsoUI/Art/Journal/leaderboard_indexIcon_housing_down.dds", 
    over = "EsoUI/Art/Journal/leaderboard_indexIcon_housing_over.dds",
}

ZO_HousingLeaderboardsManager_Shared = ZO_LeaderboardBase_Shared:Subclass()

function ZO_HousingLeaderboardsManager_Shared:New(...)
    return ZO_LeaderboardBase_Shared.New(self, ...)
end

function ZO_HousingLeaderboardsManager_Shared:Initialize(...)
    ZO_LeaderboardBase_Shared.Initialize(self, ...)

    self.homeshowListNodes = {}
end

do
    local function GetSingleHomeShowEntryInfo(entryIndex, categoryData)
        return GetHomeShowLeaderboardEntryInfo(categoryData.voteCategory, categoryData.houseCategory, entryIndex)
    end

    local function GetHousingLeaderboardEntryConsoleIdRequestParams(entryIndex, categoryData)
        return ZO_ID_REQUEST_TYPE_HOME_SHOW_LEADERBOARD, categoryData.voteCategory, categoryData.houseCategory, entryIndex
    end

    function ZO_HousingLeaderboardsManager_Shared:AddCategoriesToParentSystem()
        ZO_ClearNumericallyIndexedTable(self.homeshowListNodes)

        local function GetNumEntries(categoryData)
            self:UpdateAllInfo()
            return GetNumHomeShowLeaderboardEntries(categoryData.voteCategory, categoryData.houseCategory)
        end

        local function AddEntry(parent, name, categoryData)
            local node = self.leaderboardSystem:AddEntry(self, name, nil, parent, categoryData, GetNumEntries, nil, GetSingleHomeShowEntryInfo, nil, GetString(SI_HOUSING_LEADERBOARDS_HEADER_SCORE), GetHousingLeaderboardEntryConsoleIdRequestParams, "EsoUI/Art/Leaderboards/gamepad/gp_leaderBoards_menuIcon_housing.dds", LEADERBOARD_TYPE_HOUSE)
            if node then
                local nodeData = node.GetData and node:GetData() or node
                nodeData.voteCategory = categoryData.voteCategory
                nodeData.houseCategory= categoryData.houseCategory
            end
            table.insert(self.homeshowListNodes, node)
            return node
        end

        local numVoteCategories = GetNumHomeShowVoteCategories()

        --Create the category header
        if numVoteCategories > 0 then
            self.header = self.leaderboardSystem:AddCategory(GetString(SI_HOUSING_LEADERBOARDS_HOME_SHOW), HOME_SHOW_HEADER_ICONS.up, HOME_SHOW_HEADER_ICONS.down, HOME_SHOW_HEADER_ICONS.over)

            for voteCategory = 0, numVoteCategories - 1 do
                local houseEventName = GetHomeShowLeaderboardVoteCategoryName(voteCategory)
                for houseCategory = HOUSE_CATEGORY_TYPE_MIN_VALUE, HOUSE_CATEGORY_TYPE_MAX_VALUE do
                    local houseCategoryDisplayName = houseCategory == HOUSE_CATEGORY_TYPE_NONE and GetString(SI_HOUSING_LEADERBOARDS_ALL_HOMES) or GetString("SI_HOUSECATEGORYTYPE", houseCategory)
                    local homeShowName = zo_strformat(SI_HOUSING_LEADERBOARDS_HOME_SHOW_NAME_AND_CATEGORY, houseEventName, houseCategoryDisplayName)
                    local categoryData = 
                    {
                        voteCategory = voteCategory,
                        houseCategory = houseCategory
                    }
                    AddEntry(self.header, homeShowName, categoryData)
                end
            end
        end
    end
end

function ZO_HousingLeaderboardsManager_Shared:SelectHomeShowByCategory(voteCategory, houseCategory, openLeaderboards)
    local selectedNode
    for _, node in ipairs(self.homeshowListNodes) do
        local nodeData = node.GetData and node:GetData() or node
        if nodeData.voteCategory == voteCategory and nodeData.houseCategory == houseCategory then
            selectedNode = node
            break
        end
    end

    if selectedNode then
        self.leaderboardSystem:SelectNode(selectedNode)
        if openLeaderboards then
            SCENE_MANAGER:Push(self.leaderboardScene:GetName())
        end
    end
end

do
    local timerLabelLastUpdateSecs = 0
    local UPDATE_INTERVAL_SECS = 1

    function ZO_HousingLeaderboardsManager_Shared:TimerLabelOnUpdate(currentTime)
        if currentTime - timerLabelLastUpdateSecs >= UPDATE_INTERVAL_SECS then
            local secsUntilNextUpdate = GetHomeShowLeaderboardTimeInfo()

            if secsUntilNextUpdate > 0 then
                self.timerLabelIdentifier = SI_HOUSING_LEADERBOARDS_HOME_SHOW_UPDATES_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilNextUpdate, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            else
                self.timerLabelIdentifier = nil
                self.timerLabelData = nil
                QueryHomeShowLeaderboardData()
            end

            timerLabelLastUpdateSecs = currentTime

            self:RefreshHeaderTimer()
        end
    end

    function ZO_HousingLeaderboardsManager_Shared:UpdatePlayerInfo()
        if not self.selectedSubType then
            return
        end

        local bestRank, bestScore
        bestRank, bestScore = GetHomeShowLeaderboardLocalPlayerInfo(self.selectedSubType.voteCategory, self.selectedSubType.houseCategory)

        self.currentRankData = bestRank and bestRank > 0 and rank
        self.currentScoreData = bestScore and bestScore > 0 and bestScore

        self.control:SetHandler("OnUpdate", function(_, currentTime) self:TimerLabelOnUpdate(currentTime) end)

        self:RefreshHeaderPlayerInfo()
    end
end

function ZO_HousingLeaderboardsManager_Shared:OnSubtypeSelected(subType)
    ZO_LeaderboardBase_Shared.OnSubtypeSelected(self, subType)

    self:UpdateAllInfo()
end

function ZO_HousingLeaderboardsManager_Shared:UpdateAllInfo()
    self:UpdatePlayerInfo()
end