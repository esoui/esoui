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
    EVENT_MANAGER:RegisterForEvent("RumorManager", EVENT_RUMOR_STARTED, OnSingleRumorUpdated)
    EVENT_MANAGER:RegisterForEvent("RumorManager", EVENT_RUMOR_COMPLETED, OnSingleRumorUpdated)

    if EVENT_RUMOR_DATA_CHANGED then
        EVENT_MANAGER:RegisterForEvent("RumorManager", EVENT_RUMOR_DATA_CHANGED, function() self:RebuildRumors() end)
    end

    function OnEndingInitiated(eventId, rumorId, rumorEnding)
        local dialogData =
        {
            rumorId = rumorId,
            rumorEnding = rumorEnding,
        }
        if IsInGamepadPreferredMode() then
            ZO_Dialogs_ShowGamepadDialog("RUMOR_REWARDS_CLAIM_GAMEPAD", dialogData)
        else
            ZO_Dialogs_ShowDialog("RUMOR_REWARDS_CLAIM_KEYBOARD", dialogData)
        end
    end
    EVENT_MANAGER:RegisterForEvent("RumorManager", EVENT_RUMOR_ENDING_INITIATED, OnEndingInitiated)
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
        self:FireCallbacks("SingleRumorUpdated", rumorData)
    else
        internalassert(false, string.format("Invalid rumorId (%s)", tostring(rumorId) or "nil"))
    end
end

function ZO_RumorManager:RefreshAll()
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

function ZO_RumorManager:GetActiveRumorListForRumorType(rumorType)
    local rumorList = {}

    for index, rumorData in RUMOR_MANAGER:RumorTypeRumorIterator(rumorType, {ZO_RumorData.IsNotComplete}) do
        table.insert(rumorList, rumorData)
    end

    local function RumorSortFunction(left, right)
        -- Pending rumors first
        local leftPending = left:IsPending()
        local rightPending = right:IsPending()
        if leftPending ~= rightPending then
            return leftPending
        end

        -- If they're both pending, alphabetically sort
        -- Rumors that aren't pending all have the same display name
        if leftPending then
            local leftDisplayName = left:GetDisplayName()
            local rightDisplayName = right:GetDisplayName()
            if leftDisplayName ~= rightDisplayName then
                return leftDisplayName < rightDisplayName
            end
        end

        -- fallback to the rumorId
        return left:GetId() < right:GetId()
    end

    table.sort(rumorList, RumorSortFunction)

    return rumorList
end

function ZO_RumorManager:GetCompletedRumorListForRumorType(rumorType)
    local rumorList = {}

    for index, rumorData in RUMOR_MANAGER:RumorTypeRumorIterator(rumorType, {ZO_RumorData.IsComplete}) do
        table.insert(rumorList, rumorData)
    end

    local function RumorSortFunction(left, right)
        local leftDisplayName = left:GetDisplayName()
        local rightDisplayName = right:GetDisplayName()
        if leftDisplayName ~= rightDisplayName then
            return leftDisplayName < rightDisplayName
        end

        -- fallback to the rumorId
        return left:GetId() < right:GetId()
    end

    table.sort(rumorList, RumorSortFunction)

    return rumorList
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
