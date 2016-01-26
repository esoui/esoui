local PresenceEvents = "PresenceEvents"

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

local platform = GetUIPlatform()
if platform ~= UI_PLATFORM_PC then
    EVENT_MANAGER:RegisterForEvent(PresenceEvents, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent(PresenceEvents, EVENT_LEVEL_UPDATE, UpdateInformation)
    EVENT_MANAGER:RegisterForEvent(PresenceEvents, EVENT_VETERAN_RANK_UPDATE, UpdateInformation)
    EVENT_MANAGER:RegisterForEvent(PresenceEvents, EVENT_ZONE_UPDATE, UpdateInformation)
end