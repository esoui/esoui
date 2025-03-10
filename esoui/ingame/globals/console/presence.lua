local function UpdateInformation()
    UpdatePlayerPresenceInformation()
end

local function UpdateName()
    UpdatePlayerPresenceName()
end

local function OnPlayerActivated()
    UpdateInformation()
    UpdateName()
end

EVENT_MANAGER:RegisterForEvent("PresenceEvents", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
EVENT_MANAGER:RegisterForEvent("PresenceEvents", EVENT_LEVEL_UPDATE, UpdateInformation)
EVENT_MANAGER:RegisterForEvent("PresenceEvents", EVENT_CHAMPION_POINT_UPDATE, UpdateInformation)
EVENT_MANAGER:RegisterForEvent("PresenceEvents", EVENT_ZONE_UPDATE, UpdateInformation)
