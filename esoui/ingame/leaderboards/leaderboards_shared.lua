ZO_LEADERBOARD_PLAYER_DATA = 1

-----------------
--Leaderboards Masterlist
-----------------

ZO_LeaderboardsListManager_Shared = ZO_CallbackObject:Subclass()

function ZO_LeaderboardsListManager_Shared:New()
    local listManager = ZO_CallbackObject.New(self)
    listManager:Initialize()
    return listManager
end

function ZO_LeaderboardsListManager_Shared:Initialize()
    self.masterList = {}

    local function OnLeaderboardUpdated()
        self:BuildMasterList()
        self:FireCallbacks("OnLeaderboardMasterListUpdated")
    end

    EVENT_MANAGER:RegisterForEvent("LeaderboardsListManager", EVENT_HOME_SHOW_LEADERBOARD_DATA_CHANGED, OnLeaderboardUpdated)
    EVENT_MANAGER:RegisterForEvent("LeaderboardsListManager", EVENT_RAID_LEADERBOARD_DATA_CHANGED, OnLeaderboardUpdated)
    EVENT_MANAGER:RegisterForEvent("LeaderboardsListManager", EVENT_CAMPAIGN_LEADERBOARD_DATA_CHANGED, OnLeaderboardUpdated)
    EVENT_MANAGER:RegisterForEvent("LeaderboardsListManager", EVENT_BATTLEGROUND_LEADERBOARD_DATA_CHANGED, OnLeaderboardUpdated)
end

function ZO_LeaderboardsListManager_Shared:SetSelectedLeaderboard(data)
    self.subType = data.subType
    self.countFunction = data.countFunction
    self.maxAllowedRankFunction = data.maxRankFunction
    self.infoFunction = data.infoFunction
    self.pointsFormatFunction = data.pointsFormatFunction
    self.consoleIdRequestParamsFunction = data.consoleIdRequestParamsFunction
    if self.leaderboardRankType ~= data.leaderboardRankType then
        self.leaderboardRankType = data.leaderboardRankType
        self:FireCallbacks("LeaderboardRankTypeChanged")
    end
    self:BuildMasterList()
end

function ZO_LeaderboardsListManager_Shared:BuildMasterList()
    ZO_ClearNumericallyIndexedTable(self.masterList)

    if not self.countFunction or not self.infoFunction then
        return
    end

    for i = 1, self.countFunction(self.subType) do
        local data = { index = i }
        self:SetupDataTable(data)
        self.masterList[#self.masterList + 1] = data
    end
    
    if self.maxAllowedRankFunction then
        self.maxAllowedRank = self.maxAllowedRankFunction()
    else
        self.maxAllowedRank = nil
    end
end

function ZO_LeaderboardsListManager_Shared:SetupDataTable(dataTable)
    if dataTable.index then
        local rank, playerDisplayName, characterName, points, class, alliance, houseCollectibleId

        --Get and setup Leaderboard Type specific data
        if self.leaderboardRankType == LEADERBOARD_TYPE_HOUSE then
            rank, playerDisplayName, houseCollectibleId, points = self.infoFunction(dataTable.index, self.subType)
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(houseCollectibleId)
            dataTable.houseName = collectibleData:GetName()
        elseif self.leaderboardRankType == LEADERBOARD_TYPE_BATTLEGROUND then
            rank, playerDisplayName, characterName, points = self.infoFunction(dataTable.index, self.subType)
            dataTable.characterName = characterName
        else
            rank, characterName, points, class, alliance, playerDisplayName = self.infoFunction(dataTable.index, self.subType)

            dataTable.characterName = characterName
            dataTable.class = class
            dataTable.alliance = alliance
            dataTable.formattedAllianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(alliance))
        end

        --Setup common leaderboard data
        dataTable.displayName = playerDisplayName
        dataTable.type = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_SEARCH_TYPE_NAMES
        --This is the overall rank for the specific type of leaderboard you've requested.
        --The rank that is ultimately shown might be reshuffled based on the provided filters.
        dataTable.trueRank = rank
        if points == 0 then
            dataTable.points = ""
        else
            dataTable.points = self.pointsFormatFunction and self.pointsFormatFunction(points) or points
        end
    end
end

function ZO_LeaderboardsListManager_Shared:FilterScrollList(list, filteredClass, preAddCallback, searchCallback)
    local scrollData = ZO_ScrollList_GetDataList(list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local maxAllowedRank = self.maxAllowedRank

    local lastTrueRank = 0
    local currentRank = 0
    local filteredIndex = 1

    for _, data in ipairs(self:GetMasterList()) do
        if not filteredClass or data.class == filteredClass then
            --Re-rank based on class filtering
            if data.trueRank > lastTrueRank then
                lastTrueRank = data.trueRank
                currentRank = filteredIndex
            end

            --The list comes pre-sorted by rank, so all later entries don't matter
            if maxAllowedRank and currentRank > maxAllowedRank then
                break
            end

            data.rank = currentRank

            if not searchCallback or searchCallback(data) then
                if preAddCallback then
                    preAddCallback(data)
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_LEADERBOARD_PLAYER_DATA, data))
                end
            end

            filteredIndex = filteredIndex + 1
        end
    end
end

function ZO_LeaderboardsListManager_Shared:GetConsoleIdRequestParams(index)
    return self.consoleIdRequestParamsFunction(index, self.subType)
end

function ZO_LeaderboardsListManager_Shared:GetMasterList()
    return self.masterList
end

LEADERBOARD_LIST_MANAGER = ZO_LeaderboardsListManager_Shared:New()

-----------------
--Leaderboards Shared
-----------------

ZO_LeaderboardsManager_Shared = ZO_Object:Subclass()

function ZO_LeaderboardsManager_Shared:New(control, leaderboardControl)
    leaderboardControl = leaderboardControl or control

    local manager = ZO_Object.New(self)
    manager:Initialize(control, leaderboardControl)
    return manager
end

function ZO_LeaderboardsManager_Shared:Initialize(control, leaderboardControl)
    self:InitializeScenes()

    self.leaderboardDataMetatable = {__index = function(dataTable, key) self:IndexFunction(dataTable, key) end}
    LEADERBOARD_LIST_MANAGER:RegisterCallback("LeaderboardRankTypeChanged", function() self:RepopulateFilterDropdown() end)
    LEADERBOARD_LIST_MANAGER:RegisterCallback("OnLeaderboardMasterListUpdated", function()
        if self.scene:IsShowing() then
            self:OnLeaderboardDataChanged(self.leaderboardObject)
        end
    end)
end

function ZO_LeaderboardsManager_Shared:InitializeScenes(sceneName)
    self.scene = ZO_Scene:New(sceneName, SCENE_MANAGER)
end

function ZO_LeaderboardsManager_Shared:GetScene()
    return self.scene
end

function ZO_LeaderboardsManager_Shared:SetSelectedLeaderboardObject(leaderboardObject, subType)
    -- Should be overridden
end

function ZO_LeaderboardsManager_Shared:RefreshLeaderboardType(leaderboardType)
    -- Should be overridden
end

function ZO_LeaderboardsManager_Shared:RepopulateFilterDropdown()
    -- Should be overridden
end

function ZO_LeaderboardsManager_Shared:QueryData()
    QueryCampaignLeaderboardData()
    QueryRaidLeaderboardData()
    QueryBattlegroundLeaderboardData()
end

function ZO_LeaderboardsManager_Shared:GetLeaderboardTitleName(titleName, subType)
    return type(titleName) == "function" and titleName(subType) or titleName
end

function ZO_LeaderboardsManager_Shared:OnLeaderboardSelected(data)
    self:SetSelectedLeaderboardObject(data.leaderboardObject, data.subType)

    if self:GetScene():IsShowing() then
        LEADERBOARD_LIST_MANAGER:SetSelectedLeaderboard(data)
    end

    local titleName = self:GetLeaderboardTitleName(data.titleName, data.subType)
    self:SetActiveLeaderboardTitle(titleName)
    self:RefreshLeaderboardType(data.leaderboardRankType)

    self.pointsHeaderLabel:SetText(data.pointsHeaderString or GetString(SI_LEADERBOARDS_HEADER_POINTS))

    self:RefreshData()
end

function ZO_LeaderboardsManager_Shared:OnLeaderboardDataChanged(leaderboardObject)
    if self.leaderboardObject == leaderboardObject then
        local data = self:GetSelectedLeaderboardData()
        if data then
            self:OnLeaderboardSelected(data)
        else
            self:RefreshData()
        end
    end
end

function ZO_LeaderboardsManager_Shared:SetupLeaderboardPlayerEntry(control, data)
    local leaderboardData = self:GetSelectedLeaderboardData()

    --Rank
    control.rankLabel:SetHidden(data.rank == 0)
    control.rankLabel:SetText(data.rank)
        
    --Name
    local safeDisplayName = data.displayName ~= "" and data.displayName or GetString(SI_LEADERBOARDS_STAT_NOT_AVAILABLE)
    local nameToUse = ZO_GetPlatformUserFacingName(data.characterName, safeDisplayName)
    control.nameLabel:SetText(nameToUse)
        
    --House
    if leaderboardData.leaderboardRankType == LEADERBOARD_TYPE_HOUSE then
        control.classIcon:SetHidden(true)
        control.allianceIcon:SetHidden(true)

        control.houseLabel:SetHidden(false)
        control.houseLabel:SetText(data.houseName)
    --Battleground
    elseif leaderboardData.leaderboardRankType == LEADERBOARD_TYPE_BATTLEGROUND then
        control.houseLabel:SetHidden(true)
        control.classIcon:SetHidden(true)
        control.allianceIcon:SetHidden(true)
    --Class/Alliance
    else
        control.houseLabel:SetHidden(true)

        local classTexture = GetPlatformClassIcon(data.class)
        if(classTexture) then
            control.classIcon:SetHidden(false)
            control.classIcon:SetTexture(classTexture)
        else
            control.classIcon:SetHidden(true)
        end

        local allianceTexture = GetPlatformAllianceSymbolIcon(data.alliance)
        if(allianceTexture) then
            control.allianceIcon:SetHidden(false)
            control.allianceIcon:SetTexture(allianceTexture)
        else
            control.allianceIcon:SetHidden(true)
        end
    end

    --Points
    control.pointsLabel:SetText(data.points)
        
    --Background
    local bg = GetControl(control, "BG")
    if bg then
        local hidden = (data.index % 2) == 0
        bg:SetHidden(hidden)
    end
end

function ZO_LeaderboardsManager_Shared:CommitScrollList()
    ZO_Scroll_ResetToTop(self.list)
    ZO_SortFilterList.CommitScrollList(self)
end

do
    local INCLUDE_ALL_FILTER =
    {
        [LEADERBOARD_TYPE_OVERALL] = true,
        [LEADERBOARD_TYPE_ALLIANCE] = true,
        [LEADERBOARD_TYPE_HOUSE] = true,
        [LEADERBOARD_TYPE_BATTLEGROUND] = true,
    }

    local INCLUDE_CLASS_FILTERS =
    {
        [LEADERBOARD_TYPE_OVERALL] = true,
        [LEADERBOARD_TYPE_ALLIANCE] = true,
        [LEADERBOARD_TYPE_CLASS] = true,
    }

    function ZO_Leaderboards_PopulateDropdownFilter(dropdown, changedCallback, leaderboardType)
        dropdown:ClearItems()

        local defaultIndex = 1
        local currentIndex = 0

        local includeAllFilter = INCLUDE_ALL_FILTER[leaderboardType]
        if includeAllFilter then
            local entry = ZO_ComboBox:CreateItemEntry(GetString(SI_LEADERBOARDS_FILTER_ALL_CLASSES), changedCallback)
            dropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
            currentIndex = currentIndex + 1
        end

        if INCLUDE_CLASS_FILTERS[leaderboardType] then
            local desiredClass = not includeAllFilter and GetUnitClassId("player")

            for i = 1, GetNumClasses() do
                local classId = GetClassInfo(i)
                local className = zo_strformat(SI_CLASS_NAME, GetClassName(GENDER_MALE, classId))
                local entry = ZO_ComboBox:CreateItemEntry(className, changedCallback)
                entry.classId = classId
                dropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
                currentIndex = currentIndex + 1
                if desiredClass and desiredClass == classId then
                    defaultIndex = currentIndex
                end
            end
        end

        local IGNORE_CALLBACK = true
        dropdown:SelectItemByIndex(defaultIndex, IGNORE_CALLBACK)
        dropdown:GetContainer():SetHidden(currentIndex == 1)
    end
end