-------------------------------
-- Exploration Utilities
-------------------------------

function ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(zoneIndex)
    local zoneId = GetZoneId(zoneIndex)
    return GetZoneStoryZoneIdForZoneId(zoneId)
end