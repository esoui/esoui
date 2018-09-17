-------------------------------
-- Exploration Utilities
-------------------------------

function ZO_ExplorationUtils_GetParentZoneIdByZoneIndex(zoneIndex)
    local zoneId = GetZoneId(zoneIndex)
    return GetParentZoneId(zoneId)
end