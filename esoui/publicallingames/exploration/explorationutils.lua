-------------------------------
-- Exploration Utilities
-------------------------------

function ZO_ExplorationUtils_GetPlayerCurrentZoneId()
    local zoneIndex = GetUnitZoneIndex("player")
    return GetZoneId(zoneIndex)
end

function ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(zoneIndex)
    local zoneId = GetZoneId(zoneIndex)
    return GetZoneStoryZoneIdForZoneId(zoneId)
end

function ZO_ExplorationUtils_GetParentZoneIdByZoneIndex(zoneIndex)
    local zoneId = GetZoneId(zoneIndex)
    return GetParentZoneId(zoneId)
end

function ZO_ExplorationUtils_GetZoneStoryZoneIdForCurrentMap()
    local currentZoneIndex = GetCurrentMapZoneIndex()
    return ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(currentZoneIndex)
end