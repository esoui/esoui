ZO_MapLocations_Shared = ZO_InitializingObject:Subclass()

function ZO_MapLocations_Shared:Initialize(control)
    self.control = control
    self:InitializeList(control)

    self.data = ZO_MapLocationsData_Singleton_Initialize(control)

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
        self:UpdateSelectedMap()
    end)
    self:UpdateSelectedMap()

    self:BuildLocationList()

    local function UpdateForModeChange(modeData)
        self:SetListDisabled(not WORLD_MAP_MANAGER:IsMapChangingAllowed())
    end

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", UpdateForModeChange)
end

function ZO_MapLocations_Shared:InitializeList()
    -- Stub
end

function ZO_MapLocations_Shared:UpdateSelectedMap()
    -- Stub
end

function ZO_MapLocations_Shared:BuildLocationList()
    -- Stub
end

function ZO_MapLocations_Shared:GetDisabled()
    return self.listDisabled
end

-- Singleton shared data
ZO_MapLocationsData_Singleton = ZO_InitializingObject:Subclass()

function ZO_MapLocationsData_Singleton:GetLocationList()
    if not self.mapData then
        self:RefreshLocationList()
    end

    return self.mapData
end

function ZO_MapLocationsData_Singleton:RefreshLocationList()
    local mapData = {}
    for i = 1, GetNumMaps() do
        local mapName, mapType, mapContentType, zoneIndex, description = GetMapInfoByIndex(i)
        mapData[#mapData + 1] = { locationName = ZO_CachedStrFormat(SI_ZONE_NAME, mapName), description = description, index = i }
    end

    table.sort(mapData, function(a,b)
        return a.locationName < b.locationName
    end)

    self.mapData = mapData
end

function ZO_MapLocationsData_Singleton_Initialize(control)
    if not WORLD_MAP_LOCATIONS_DATA then
        WORLD_MAP_LOCATIONS_DATA = ZO_MapLocationsData_Singleton:New(control)
    end
    return WORLD_MAP_LOCATIONS_DATA
end
