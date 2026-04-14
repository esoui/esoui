ZO_RumorManager = ZO_InitializingCallbackObject:Subclass()

function ZO_RumorManager:Initialize()
    RUMOR_MANAGER = self

    self.rumorData = {}

    self:RegisterForEvents()

    self:RebuildRumors()
end

function ZO_RumorManager:RegisterForEvents()
    local function OnRumorsUpdated()
        self:RefreshAll()
    end

    EVENT_MANAGER:RegisterForEvent("RumorManager", EVENT_RUMORS_UPDATED, OnRumorsUpdated)

    local function OnSingleRumorUpdated(event, rumorId)
        self:RefreshRumor(rumorId)
    end

    EVENT_MANAGER:RegisterForEvent("RumorManager", EVENT_RUMOR_UPDATED, OnSingleRumorUpdated)

    if EVENT_RUMOR_DATA_CHANGED then
        EVENT_MANAGER:RegisterForEvent("RumorManager", EVENT_RUMOR_DATA_CHANGED, function() self:RebuildRumors() end)
    end
end

function ZO_RumorManager:RumorIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.rumorData, filterFunctions)
end

function ZO_RumorManager:RumorTypeRumorIterator(rumorType, filterFunctions)
    local function IsRumorType(rumorData)
        return rumorData:IsRumorType(rumorType)
    end

    local combinedFilterFunctions = {IsRumorType}
    if filterFunctions then
        ZO_CombineNumericallyIndexedTables(combinedFilterFunctions, filterFunctions)
    end

    return self:RumorIterator(combinedFilterFunctions)
end

function ZO_RumorManager:HasMatchingRumor(matchingFunctions)
    for index, rumorData in RUMOR_MANAGER:RumorIterator(matchingFunctions) do
        return true
    end

    return false
end

function ZO_RumorManager:DoesRumorTypeHaveMatchingRumor(rumorType, matchingFunctions)
    for index, rumorData in RUMOR_MANAGER:RumorTypeRumorIterator(rumorType, matchingFunctions) do
        return true
    end

    return false
end

function ZO_RumorManager:ClearRumors()
    ZO_ClearTable(self.rumorData)
end

function ZO_RumorManager:GetRumorData(rumorId)
    return self.rumorData[rumorId]
end

function ZO_RumorManager:GetOrCreateRumorData(rumorId)
    if rumorId and rumorId ~= 0 then
        local rumorData = self:GetRumorData(rumorId)
        if not rumorData then
            rumorData = ZO_RumorData:New(rumorId)
            self.rumorData[rumorId] = rumorData
        end
        return rumorData
    end
end

function ZO_RumorManager:RefreshRumor(rumorId)
    local rumorData = self:GetRumorData(rumorId)
    if rumorData then
        -- TODO Rumors: Refresh rumorData
        self:FireCallbacks("SingleRumorUpdated", rumorData)
    else
        internalassert(false, string.format("Invalid rumorId (%s)", tostring(rumorId) or "nil"))
    end
end

function ZO_RumorManager:RefreshAll()
    for _, rumorData in self:RumorIterator() do
        -- TODO Rumors: Refresh rumorData
    end
    self:FireCallbacks("RumorsUpdated")
end

function ZO_RumorManager:RebuildRumors()
    self:ClearRumors()

    local numRumors = GetNumRumors()
    for rumorIndex = 1, numRumors do
        local rumorId = GetRumorIdAtIndex(rumorIndex)
        self:GetOrCreateRumorData(rumorIndex)
    end

    self:FireCallbacks("RumorsUpdated")
end

function ZO_RumorManager:ConfirmAbandonRumor(rumorId)
    local rumorData = self:GetRumorData(rumorId)
    if not rumorData then
        return
    end

    local rumorName = rumorData:GetDisplayName()
    rumorName = ZO_WHITE:Colorize(rumorName)
    ZO_Dialogs_ShowPlatformDialog("ABANDON_RUMOR", {rumorId = rumorId}, {mainTextParams = {rumorName}})
end

ZO_RumorManager:New()
