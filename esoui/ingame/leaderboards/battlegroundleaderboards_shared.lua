---------------
-- Battleground Leaderboards
---------------
ZO_BATTLEGROUND_LEADERBOARD_SYSTEM_NAME = "battlegroundLeaderboards"

local BATTLEGROUND_SHOW_HEADER_ICONS =
{
    up = "EsoUI/Art/Battlegrounds/battlegrounds_tabIcon_battlegrounds_up.dds", 
    down = "EsoUI/Art/Battlegrounds/battlegrounds_tabIcon_battlegrounds_down.dds", 
    over = "EsoUI/Art/Battlegrounds/battlegrounds_tabIcon_battlegrounds_over.dds",
}

ZO_BattlegroundLeaderboardsManager_Shared = ZO_LeaderboardBase_Shared:Subclass()

function ZO_BattlegroundLeaderboardsManager_Shared:Initialize(...)
    ZO_LeaderboardBase_Shared.Initialize(self, ...)

    self.battlegroundListNodes = {}
    self.control:SetHandler("OnUpdate", function(_, currentTime) self:TimerLabelOnUpdate(currentTime) end)
end

do
    local function GetSingleBattlegroundEntryInfo(entryIndex, battlegroundLeaderboardType)
        return GetBattlegroundLeaderboardEntryInfo(battlegroundLeaderboardType, entryIndex)
    end

    local function GetBattlegroundLeaderboardEntryConsoleIdRequestParams(entryIndex, battlegroundLeaderboardType)
        return ZO_ID_REQUEST_TYPE_BATTLEGROUND_LEADERBOARD, battlegroundLeaderboardType, entryIndex
    end

    local function GetNextBattlegroundLeaderboardTypeIter(state, lastBattlegroundLeaderboardType)
        return GetNextBattlegroundLeaderboardType(lastBattlegroundLeaderboardType)
    end

    local GAMEPAD_CATEGORY_ICON_MAP =
    {
        [BATTLEGROUND_LEADERBOARD_TYPE_DEATHMATCH] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_tabIcon_deathmatch.dds",
        [BATTLEGROUND_LEADERBOARD_TYPE_LAND_GRAB] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_tabIcon_landgrab.dds",
        [BATTLEGROUND_LEADERBOARD_TYPE_FLAG_GAMES] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_tabIcon_flaggames.dds",
        [BATTLEGROUND_LEADERBOARD_TYPE_COMPETITIVE] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_tabIcon_competitive.dds"
    }

    function ZO_BattlegroundLeaderboardsManager_Shared:AddCategoriesToParentSystem()
        ZO_ClearNumericallyIndexedTable(self.battlegroundListNodes)

        local function UpdatePlayerInfo()
            self:UpdatePlayerInfo()
        end

        local function GetNumEntries(battlegroundLeaderboardType)
            return GetNumBattlegroundLeaderboardEntries(battlegroundLeaderboardType)
        end

        local function AddEntry(parent, name, battlegroundLeaderboardType)
            local gamepadIcon = GAMEPAD_CATEGORY_ICON_MAP[battlegroundLeaderboardType] or ZO_NO_TEXTURE_FILE
            local NO_TITLE_NAME = nil
            local NO_POINTS_FORMAT_FUNCTION = nil
            local NO_POINTS_HEADER_STRING = nil
            local node = self.leaderboardSystem:AddEntry(self, name, NO_TITLE_NAME, parent, battlegroundLeaderboardType, GetNumEntries, NO_POINTS_FORMAT_FUNCTION, GetSingleBattlegroundEntryInfo, NO_POINTS_HEADER_STRING, GetString(SI_LEADERBOARDS_HEADER_POINTS), GetBattlegroundLeaderboardEntryConsoleIdRequestParams, gamepadIcon, LEADERBOARD_TYPE_BATTLEGROUND, UpdatePlayerInfo)
            if node then
                local nodeData = node.GetData and node:GetData() or node
                nodeData.battlegroundLeaderboardType = battlegroundLeaderboardType
            end
            table.insert(self.battlegroundListNodes, node)
            return node
        end

        local createHeader = true
        for battlegroundLeaderboardType in GetNextBattlegroundLeaderboardTypeIter do
            if ShouldShowLeaderboardForBattlegroundLeaderboardType(battlegroundLeaderboardType) then
                if createHeader then
                    self.header = self.leaderboardSystem:AddCategory(GetString(SI_BATTLEGROUND_LEADERBOARDS_CATEGORIES_HEADER), BATTLEGROUND_SHOW_HEADER_ICONS.up, BATTLEGROUND_SHOW_HEADER_ICONS.down, BATTLEGROUND_SHOW_HEADER_ICONS.over)
                    createHeader = false
                end

                AddEntry(self.header, GetString("SI_BATTLEGROUNDLEADERBOARDTYPE", battlegroundLeaderboardType), battlegroundLeaderboardType)
            end
        end
    end
end

function ZO_BattlegroundLeaderboardsManager_Shared:SelectByBattlegroundLeaderboardType(battlegroundLeaderboardType, openLeaderboards)
    local selectedNode
    for _, node in ipairs(self.battlegroundListNodes) do
        local nodeData = node.GetData and node:GetData() or node
        if nodeData.battlegroundLeaderboardType == battlegroundLeaderboardType then
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

    function ZO_BattlegroundLeaderboardsManager_Shared:TimerLabelOnUpdate(currentTime)
        if currentTime - timerLabelLastUpdateSecs >= UPDATE_INTERVAL_SECS then
            local secsUntilEnd, secsUntilNextStart = GetBattlegroundLeaderboardsSchedule(self.selectedSubType)

            if secsUntilEnd > 0 then
                self.timerLabelIdentifier = SI_LEADERBOARDS_CLOSES_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilEnd, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            elseif secsUntilNextStart > 0 then
                self.timerLabelIdentifier = SI_LEADERBOARDS_REOPENS_IN_TIMER
                self.timerLabelData = ZO_FormatTime(secsUntilNextStart, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            else
                self.timerLabelIdentifier = nil
                self.timerLabelData = nil
            end

            timerLabelLastUpdateSecs = currentTime

            self:RefreshHeaderTimer()
        end
    end
end

function ZO_BattlegroundLeaderboardsManager_Shared:UpdatePlayerInfo()
    if not self.selectedSubType then
        return
    end

    local currentRank, currentScore = GetBattlegroundLeaderboardLocalPlayerInfo(self.selectedSubType)
    local hasRank = currentRank > 0
    local hasScore = currentScore > 0

    self.currentRankData = hasRank and currentRank or nil
    self.currentScoreData = hasScore and currentScore or nil

    self:RefreshHeaderPlayerInfo()
end

function ZO_BattlegroundLeaderboardsManager_Shared:OnSubtypeSelected(subType)
    ZO_LeaderboardBase_Shared.OnSubtypeSelected(self, subType)

    self:UpdatePlayerInfo()
end

function ZO_BattlegroundLeaderboardsManager_Shared:SendLeaderboardQuery()
    if not self.selectedSubType then
        return
    end

    self.requestedBattlegroundType = self.selectedSubType
    LEADERBOARD_LIST_MANAGER:QueryLeaderboardData(LEADERBOARD_DATA_TYPE.BATTLEGROUND, self:GenerateRequestData())
end

function ZO_BattlegroundLeaderboardsManager_Shared:GenerateRequestData()
    local data =
    { 
        battlegroundType = self.requestedBattlegroundType,
    }
    return data
end

function ZO_BattlegroundLeaderboardsManager_Shared:HandleFilterDropdownChanged()
    -- Returning false to signify no special handling required
    return false
end