ZO_ChampionSkillData = ZO_InitializingObject:Subclass()

function ZO_ChampionSkillData:Initialize(disciplineData, championSkillIndex)
    self.championDisciplineData = disciplineData
    self.championSkillIndex = championSkillIndex
    self.championSkillId = GetChampionSkillId(disciplineData:GetDisciplineIndex(), championSkillIndex)
    self.pendingPoints = self:GetNumSavedPoints()
end

function ZO_ChampionSkillData:LinkData()
    local links = {}
    local skillIds = { GetChampionSkillLinkIds(self.championSkillId) }
    for _, skillId in ipairs(skillIds) do
        local championSkillData = CHAMPION_DATA_MANAGER:GetChampionSkillData(skillId)
        internalassert(championSkillData, "skill data missing; can be caused by calling ZO_ChampionSkillData:LinkData() before instantiating all skills")
        table.insert(links, championSkillData)
    end
    self.linkedChampionSkillDatas = links
end

function ZO_ChampionSkillData:GetId()
    return self.championSkillId
end

function ZO_ChampionSkillData:GetSkillIndices()
    return self.championDisciplineData:GetDisciplineIndex(), self.championSkillIndex
end

function ZO_ChampionSkillData:GetAbilityId()
    return GetChampionAbilityId(self.championSkillId)
end

function ZO_ChampionSkillData:GetPosition()
    if self:IsClusterRoot() then
        local positionX, positionY = GetChampionSkillPosition(self.championSkillId)
        local offsetX, offsetY = GetChampionClusterRootOffset(self.championSkillId)
        return positionX + offsetX, positionY + offsetY
    else
        return GetChampionSkillPosition(self.championSkillId)
    end
end

function ZO_ChampionSkillData:GetPositionNoClusterOffset()
    return GetChampionSkillPosition(self.championSkillId)
end

function ZO_ChampionSkillData:IsRootNode()
    return IsChampionSkillRootNode(self.championSkillId)
end

function ZO_ChampionSkillData:GetRawName()
    return GetChampionSkillName(self.championSkillId)
end

function ZO_ChampionSkillData:GetFormattedName()
    return ZO_CachedStrFormat(SI_CHAMPION_STAR_NAME, self:GetRawName())
end

function ZO_ChampionSkillData:GetDescription()
    return GetChampionSkillDescription(self.championSkillId, self:GetNumPendingPoints())
end

function ZO_ChampionSkillData:GetCurrentBonusText()
    local bonusText = GetChampionSkillCurrentBonusText(self.championSkillId, self:GetNumPendingPoints())
    if bonusText ~= "" then
        return bonusText
    end
    return nil
end

function ZO_ChampionSkillData:GetType()
    return GetChampionSkillType(self.championSkillId)
end

function ZO_ChampionSkillData:IsClusterRoot()
    return IsChampionSkillClusterRoot(self.championSkillId)
end

function ZO_ChampionSkillData:GetNumPendingPoints()
    return self.pendingPoints
end

function ZO_ChampionSkillData:SetNumPendingPointsInternal(numPoints)
    if numPoints ~= self.pendingPoints then
        self.pendingPoints = numPoints
        return true
    end
    return false
end

function ZO_ChampionSkillData:CollectUnsavedChanges()
    if self:HasUnsavedChanges() then
        AddSkillToChampionPurchaseRequest(self.championSkillId, self.pendingPoints)
    end
end

function ZO_ChampionSkillData:SetNumPendingPoints(numPoints)
    local wasUnlocked = self:WouldBeUnlockedNode()
    if self:SetNumPendingPointsInternal(numPoints) then
        local isUnlocked = self:WouldBeUnlockedNode()
        if isUnlocked == false and wasUnlocked == true then
            -- skill has been re-locked, refund any points that are no longer attached to a root skill as a result
            if self.championDisciplineData:RefundOrphanedSkillsInternal() then
                self:GetChampionDisciplineData():DirtyNumPendingPointsInternal()
                CHAMPION_DATA_MANAGER:FireCallbacks("AllPointsChanged")
                return
            end
        end
        self:GetChampionDisciplineData():DirtyNumPendingPointsInternal()
        CHAMPION_DATA_MANAGER:FireCallbacks("ChampionSkillPendingPointsChanged", self, wasUnlocked, isUnlocked)
    end
end

function ZO_ChampionSkillData:LinkedChampionSkillDataIterator()
    return ipairs(self.linkedChampionSkillDatas)
end

function ZO_ChampionSkillData:GetNumSavedPoints()
    return GetNumPointsSpentOnChampionSkill(self.championSkillId)
end

function ZO_ChampionSkillData:WouldBeUnlockedNode()
    return WouldChampionSkillNodeBeUnlocked(self.championSkillId, self:GetNumPendingPoints())
end

function ZO_ChampionSkillData:WouldBeUnlockedNodeAtValue(pendingPoints)
    return WouldChampionSkillNodeBeUnlocked(self.championSkillId, pendingPoints)
end

function ZO_ChampionSkillData:CanBePurchased()
    if self:IsRootNode() or self:WouldBeUnlockedNode() then
        return true
    end

    for _, linkedSkillData in self:LinkedChampionSkillDataIterator() do
        if linkedSkillData:WouldBeUnlockedNode() then
            return true
        end
    end

    return false
end

function ZO_ChampionSkillData:ClearChangesInternal()
    local pendingPoints = self:GetNumSavedPoints()
    self:SetNumPendingPointsInternal(pendingPoints)
end

function ZO_ChampionSkillData:ClearAllPointsInternal()
    return self:SetNumPendingPointsInternal(self:GetMinPendingPoints())
end

function ZO_ChampionSkillData:HasUnsavedChanges()
    return self:GetNumPendingPoints() ~= self:GetNumSavedPoints()
end

function ZO_ChampionSkillData:IsRespecNeeded()
    return self:GetNumPendingPoints() < self:GetNumSavedPoints()
end

function ZO_ChampionSkillData:GetMinPendingPoints()
    if CHAMPION_PERKS:IsInRespecMode() then
        return 0
    else
        return self:GetNumSavedPoints()
    end
end

function ZO_ChampionSkillData:GetMaxPossiblePoints()
    return GetChampionSkillMaxPoints(self.championSkillId)
end

function ZO_ChampionSkillData:GetMaxPendingPoints()
    local pointsInPool = self.championDisciplineData:GetNumAvailablePoints()
    local pointsInSkill = self:GetNumPendingPoints()
    local maxPossiblePointsInSkill = self:GetMaxPossiblePoints()

    return zo_min(pointsInPool + pointsInSkill, maxPossiblePointsInSkill)
end

function ZO_ChampionSkillData:IsPurchased()
    return WouldChampionSkillNodeBeUnlocked(self.championSkillId, self:GetMinPendingPoints())
end

function ZO_ChampionSkillData:WouldBePurchased()
    return self:WouldBeUnlockedNode()
end

function ZO_ChampionSkillData:HasJumpPoints()
    return DoesChampionSkillHaveJumpPoints(self.championSkillId)
end

function ZO_ChampionSkillData:GetJumpPoints()
    if not self.jumpPoints then
        self.jumpPoints = {GetChampionSkillJumpPoints(self.championSkillId)}
    end
    return self.jumpPoints
end

function ZO_ChampionSkillData:GetNextJumpPoint(pointValue)
    local max = self:GetMaxPossiblePoints()
    if self:HasJumpPoints() then
        local jumpPoints = self:GetJumpPoints()
        local lastJumpPoint = 0
        for _, jumpPoint in ipairs(jumpPoints) do
            if jumpPoint > pointValue then
                return zo_min(max, jumpPoint)
            end
            lastJumpPoint = jumpPoint
        end
        return zo_min(max, lastJumpPoint)
    end

    return zo_min(max, pointValue + 1)
end

function ZO_ChampionSkillData:GetPreviousJumpPoint(pointValue)
    local min = 0

    if self:HasJumpPoints() then
        local jumpPoints = self:GetJumpPoints()
        local lastJumpPoint = 0
        for _, jumpPoint in ZO_NumericallyIndexedTableReverseIterator(jumpPoints) do
            if jumpPoint < pointValue then
                return zo_max(min, jumpPoint)
            end
            lastJumpPoint = jumpPoint
        end
        return zo_max(min, lastJumpPoint)
    end

    return zo_max(min, pointValue - 1)
end

function ZO_ChampionSkillData:GetJumpPointForValue(pointValue)
    if self:HasJumpPoints() then
        local jumpPoints = self:GetJumpPoints()
        local lastJumpPoint = 0
        for _, jumpPoint in ipairs(jumpPoints) do
            if jumpPoint > pointValue then
                return lastJumpPoint
            end
            lastJumpPoint = jumpPoint
        end
        return lastJumpPoint
    end

    return pointValue
end

function ZO_ChampionSkillData:SetClusterDataInternal(championClusterData)
    self.championClusterData = championClusterData
end

function ZO_ChampionSkillData:IsPartOfCluster()
    return self.championClusterData ~= nil
end

function ZO_ChampionSkillData:GetChampionClusterData()
    return self.championClusterData
end

function ZO_ChampionSkillData:GetChampionDisciplineData()
    return self.championDisciplineData
end

function ZO_ChampionSkillData:IsTypeSlottable()
    return CanChampionSkillTypeBeSlotted(self:GetType())
end

function ZO_ChampionSkillData:CanBeSlotted()
    return self:IsTypeSlottable() and self:WouldBePurchased()
end

function ZO_ChampionSkillData:TryCursorPickup()
    if self:CanBeSlotted() then
        PickupChampionSkillById(self.championSkillId)
        return true
    end
    return false
end

ZO_ChampionClusterData = ZO_InitializingObject:Subclass()

function ZO_ChampionClusterData:Initialize(rootChampionSkillData)
    self.rootChampionSkillData = rootChampionSkillData
    self.rootDisciplineIndex, self.rootChampionSkillIndex = rootChampionSkillData:GetSkillIndices()
end

function ZO_ChampionClusterData:LinkData()
    local clusterChildren = { self.rootChampionSkillData }
    self.rootChampionSkillData:SetClusterDataInternal(self)

    local skillIds = { GetChampionClusterSkillIds(self.rootChampionSkillData:GetId()) }
    for _, skillId in ipairs(skillIds) do
        local championSkillData = CHAMPION_DATA_MANAGER:GetChampionSkillData(skillId)
        if not championSkillData then
            internalassert(false, string.format("Missing data for skill %d; used in the cluster group with root id %d. Is this skill connected to the cluster root?", skillId, self.rootChampionSkillData:GetId()))
        end
        table.insert(clusterChildren, championSkillData)
        championSkillData:SetClusterDataInternal(self)
    end
    self.clusterChildren = clusterChildren
end

function ZO_ChampionClusterData:GetClusterChildren()
    return self.clusterChildren
end

function ZO_ChampionClusterData:GetRootChampionSkillData()
    return self.rootChampionSkillData
end

function ZO_ChampionClusterData:GetFormattedName()
    return ZO_CachedStrFormat(SI_CHAMPION_CLUSTER_NAME, GetChampionClusterName(self.rootChampionSkillData:GetId()))
end

function ZO_ChampionClusterData:GetBackgroundTexture()
    return GetChampionClusterBackgroundTexture(self.rootChampionSkillData:GetId())
end

function ZO_ChampionClusterData:DoChildrenHaveUnsavedChanges()
    for _, childSkillData in ipairs(self.clusterChildren) do
        if childSkillData:HasUnsavedChanges() then
            return true
        end
    end
    return false
end

function ZO_ChampionClusterData:CalculateTotalPendingPoints()
    local totalPendingPoints = 0
    for _, childSkillData in ipairs(self.clusterChildren) do
        totalPendingPoints = totalPendingPoints + childSkillData:GetNumPendingPoints()
    end
    return totalPendingPoints
end

ZO_ChampionDisciplineData = ZO_InitializingObject:Subclass()

function ZO_ChampionDisciplineData:Initialize(disciplineIndex)
    self.disciplineIndex = disciplineIndex
    self.disciplineId = GetChampionDisciplineId(disciplineIndex)

    self.championSkillDatas = {}
    self.championClusterDatas = {}
    for skillIndex = 1, GetNumChampionDisciplineSkills(disciplineIndex) do
        local championSkillData = ZO_ChampionSkillData:New(self, skillIndex)
        if championSkillData:IsClusterRoot() then
            table.insert(self.championClusterDatas, ZO_ChampionClusterData:New(championSkillData))
        end
        self.championSkillDatas[skillIndex] = championSkillData
    end
end

function ZO_ChampionDisciplineData:LinkData()
    for _, championSkillData in ipairs(self.championSkillDatas) do
        championSkillData:LinkData()
    end
    for _, championClusterData in ipairs(self.championClusterDatas) do
        championClusterData:LinkData()
    end
end

function ZO_ChampionDisciplineData:GetDisciplineIndex()
    return self.disciplineIndex
end

function ZO_ChampionDisciplineData:GetId()
    return self.disciplineId
end

function ZO_ChampionDisciplineData:ChampionSkillDataIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.championSkillDatas, filterFunctions)
end

function ZO_ChampionDisciplineData:ChampionClusterDataIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.championClusterDatas, filterFunctions)
end

function ZO_ChampionDisciplineData:GetRawName()
    return GetChampionDisciplineName(self.disciplineId)
end

function ZO_ChampionDisciplineData:GetFormattedName()
    return ZO_CachedStrFormat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, self:GetRawName())
end

function ZO_ChampionDisciplineData:GetBackgroundZoomedOutTexture()
    return GetChampionDisciplineZoomedOutBackground(self.disciplineId)
end

function ZO_ChampionDisciplineData:GetBackgroundZoomedInTexture()
    return GetChampionDisciplineZoomedInBackground(self.disciplineId)
end

function ZO_ChampionDisciplineData:GetBackgroundSelectedZoomedOutTexture()
    return GetChampionDisciplineSelectedZoomedOutOverlay(self.disciplineId)
end

function ZO_ChampionDisciplineData:GetType()
    return GetChampionDisciplineType(self.disciplineId)
end

do
    local POINTS_ATTRIBUTE_ICON =
    {
        [CHAMPION_DISCIPLINE_TYPE_WORLD] = "EsoUI/Art/Champion/champion_points_stamina_icon.dds",
        [CHAMPION_DISCIPLINE_TYPE_COMBAT] = "EsoUI/Art/Champion/champion_points_magicka_icon.dds",
        [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = "EsoUI/Art/Champion/champion_points_health_icon.dds",
    }

    function ZO_ChampionDisciplineData:GetPointPoolIcon()
        return POINTS_ATTRIBUTE_ICON[self:GetType()]
    end
end

do
    local POINTS_ATTRIBUTE_HUD_ICON =
    {
        [CHAMPION_DISCIPLINE_TYPE_WORLD] = "EsoUI/Art/Champion/champion_points_stamina_icon-HUD.dds",
        [CHAMPION_DISCIPLINE_TYPE_COMBAT] = "EsoUI/Art/Champion/champion_points_magicka_icon-HUD.dds",
        [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = "EsoUI/Art/Champion/champion_points_health_icon-HUD.dds",
    }
    function ZO_ChampionDisciplineData:GetHUDIcon()
        return POINTS_ATTRIBUTE_HUD_ICON[self:GetType()]
    end
end

function ZO_ChampionDisciplineData:GetNumSavedUnspentPoints()
    return GetNumUnspentChampionPoints(self.disciplineId)
end

function ZO_ChampionDisciplineData:GetNumSavedSpentPoints()
    return GetNumSpentChampionPoints(self.disciplineId)
end

function ZO_ChampionDisciplineData:GetNumSavedPointsTotal()
    return self:GetNumSavedUnspentPoints() + self:GetNumSavedSpentPoints()
end

function ZO_ChampionDisciplineData:DirtyNumPendingPointsInternal()
    self.cachedPendingPoints = nil
end

function ZO_ChampionDisciplineData:GetOrCalculateNumPendingPoints()
    if self.cachedPendingPoints then
        return self.cachedPendingPoints
    end

    local numPendingPoints = 0
    for _, championSkillData in self:ChampionSkillDataIterator() do
        numPendingPoints = numPendingPoints + championSkillData:GetNumPendingPoints()
    end

    self.cachedPendingPoints = numPendingPoints
    return numPendingPoints
end

function ZO_ChampionDisciplineData:GetNumAvailablePoints()
    return self:GetNumSavedPointsTotal() - self:GetOrCalculateNumPendingPoints()
end

function ZO_ChampionDisciplineData:HasAnySavedUnspentPoints()
    return self:GetNumSavedUnspentPoints() > 0
end

function ZO_ChampionDisciplineData:HasUnsavedChanges()
    for _, championSkillData in self:ChampionSkillDataIterator() do
        if championSkillData:HasUnsavedChanges() then
            return true
        end
    end
    return false
end

function ZO_ChampionDisciplineData:IsRespecNeeded()
    for _, championSkillData in self:ChampionSkillDataIterator() do
        if championSkillData:IsRespecNeeded() then
            return true
        end
    end
    return false
end

function ZO_ChampionDisciplineData:ClearChangesInternal()
    for _, championSkillData in self:ChampionSkillDataIterator() do
        championSkillData:ClearChangesInternal()
    end
end

function ZO_ChampionDisciplineData:ClearAllPointsInternal()
    for _, championSkillData in self:ChampionSkillDataIterator() do
        championSkillData:ClearAllPointsInternal()
    end
end

function ZO_ChampionDisciplineData:RefundOrphanedSkillsInternal()
    -- This is very similar to the traditional mark-sweep algorithm used in garbage collectors.
    local unvisitedNodeSet = {}
    local visitQueue = {}

    -- first, mark all non-root nodes as potential orphans
    for _, championSkillData in self:ChampionSkillDataIterator() do
        if championSkillData:IsRootNode() then
            table.insert(visitQueue, championSkillData)
        else
            unvisitedNodeSet[championSkillData] = true
        end
    end

    -- then sweep through every node linked to a root skill, using a graph search
    while not ZO_IsTableEmpty(visitQueue) do
        local championSkillData = table.remove(visitQueue)
        -- only traverse unlocked nodes. This means that if there isn't a path
        -- from the root to a given node only using the unlocked nodes, then it
        -- will never be visited
        if championSkillData:WouldBeUnlockedNode() then
            for _, linkedSkillData in championSkillData:LinkedChampionSkillDataIterator() do
                if unvisitedNodeSet[linkedSkillData] then
                    unvisitedNodeSet[linkedSkillData] = nil
                    table.insert(visitQueue, linkedSkillData)
                end
            end
        end
    end

    -- everything left over is an orphan and should be cleaned up
    local anySkillsChanged = false
    for orphanSkillData in pairs(unvisitedNodeSet) do
        if orphanSkillData:ClearAllPointsInternal() then
            anySkillsChanged = true
        end
    end

    return anySkillsChanged
end

function ZO_ChampionDisciplineData:CollectUnsavedChanges()
    for _, championSkillData in self:ChampionSkillDataIterator() do
        championSkillData:CollectUnsavedChanges()
    end
end

ZO_ChampionDataManager = ZO_InitializingCallbackObject:Subclass()

function ZO_ChampionDataManager:Initialize()
    CHAMPION_DATA_MANAGER = self
    self:RebuildData()
end

function ZO_ChampionDataManager:RebuildData()
    self.disciplineDatas = {}
    self.championSkillDataById = {}

    for disciplineIndex = 1, GetNumChampionDisciplines() do
        local disciplineData = ZO_ChampionDisciplineData:New(disciplineIndex)
        self.disciplineDatas[disciplineIndex] = disciplineData
        for _, championSkillData in disciplineData:ChampionSkillDataIterator() do
            internalassert(self.championSkillDataById[championSkillData:GetId()] == nil, "Duplicate champion skill")
            self.championSkillDataById[championSkillData:GetId()] = championSkillData
        end
        disciplineData:LinkData()
    end
    self:FireCallbacks("DataChanged")
end

function ZO_ChampionDataManager:ChampionDisciplineDataIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.disciplineDatas, filterFunctions)
end

function ZO_ChampionDataManager:FindChampionDisciplineDataById(disciplineId)
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        if disciplineData:GetId() == disciplineId then
            return disciplineData
        end
    end
    return nil
end

function ZO_ChampionDataManager:FindChampionDisciplineDataByType(disciplineType)
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        if disciplineData:GetType() == disciplineType then
            return disciplineData
        end
    end
    return nil
end

function ZO_ChampionDataManager:GetChampionSkillData(championSkillId)
    return self.championSkillDataById[championSkillId]
end

function ZO_ChampionDataManager:HasPointsToClear()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        for _, championSkillData in disciplineData:ChampionSkillDataIterator() do
            if championSkillData:GetNumPendingPoints() > championSkillData:GetMinPendingPoints() then
                return true
            end
        end
    end
    return false
end

function ZO_ChampionDataManager:HasAnySavedSpentPoints()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        for _, championSkillData in disciplineData:ChampionSkillDataIterator() do
            if championSkillData:GetNumSavedPoints() > 0 then
                return true
            end
        end
    end
    return false
end

function ZO_ChampionDataManager:HasAnySavedUnspentPoints()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        if disciplineData:HasAnySavedUnspentPoints() then
            return true
        end
    end
    return false
end

function ZO_ChampionDataManager:HasUnsavedChanges()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        if disciplineData:HasUnsavedChanges() then
            return true
        end
    end
    return false
end

function ZO_ChampionDataManager:IsRespecNeeded()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        if disciplineData:IsRespecNeeded() then
            return true
        end
    end
    return false
end

function ZO_ChampionDataManager:ClearChanges()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        disciplineData:ClearChangesInternal()
        disciplineData:DirtyNumPendingPointsInternal()
    end
    self:FireCallbacks("AllPointsChanged")
end

function ZO_ChampionDataManager:ClearAllPoints()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        disciplineData:ClearAllPointsInternal()
        disciplineData:DirtyNumPendingPointsInternal()
    end
    self:FireCallbacks("AllPointsChanged")
end

function ZO_ChampionDataManager:CollectUnsavedChanges()
    for _, disciplineData in self:ChampionDisciplineDataIterator() do
        disciplineData:CollectUnsavedChanges()
    end
end

ZO_ChampionDataManager:New()
