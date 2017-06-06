local CMapHandlers = ZO_Object:Subclass()

function CMapHandlers:New()
    local object = ZO_Object.New(self)
    object:Initialize()
    return object
end

function CMapHandlers:Initialize()
    self:InitializeRefresh()
    self:InitializeEvents()
end

function CMapHandlers:InitializeRefresh()
    self.refresh = ZO_Refresh:New()

    self.refresh:AddRefreshGroup("keep",
    {
        RefreshAll = function()
            self:RefreshKeeps()
        end,
        RefreshSingle = function(...)
            self:RefreshKeep(...)
        end,
    })
end

function CMapHandlers:InitializeEvents()
    local function RefreshKeep(_, keepId, bgContext)
        self.refresh:RefreshSingle("keep", keepId, bgContext)
    end
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_ALLIANCE_OWNER_CHANGED, RefreshKeep)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_UNDER_ATTACK_CHANGED, RefreshKeep)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_INITIALIZED, RefreshKeep)

    local function RefreshKeeps()
        self.refresh:RefreshAll("keep")
    end
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEP_GATE_STATE_CHANGED, RefreshKeeps)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_KEEPS_INITIALIZED, RefreshKeeps)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_CURRENT_SUBZONE_LIST_CHANGED, RefreshKeeps)
    EVENT_MANAGER:RegisterForEvent("CMapHandler", EVENT_PLAYER_ACTIVATED, RefreshKeeps)

    EVENT_MANAGER:RegisterForUpdate("CMapHandler", 100, function()
        self.refresh:UpdateRefreshGroups()
    end)
end

function CMapHandlers:AddKeep(keepId, bgContext)
    local pinType = GetKeepPinInfo(keepId, bgContext)
    if pinType ~= MAP_PIN_TYPE_INVALID then
        if DoesKeepPassCompassVisibilitySubzoneCheck(keepId, bgContext) then
            self:AddMapPin(pinType, keepId)

            local keepUnderAttack = GetKeepUnderAttack(keepId, bgContext)
            if(keepUnderAttack) then
                local keepUnderAttackPinType = ZO_WorldMap_GetUnderAttackPinForKeepPin(pinType)
                self:AddMapPin(keepUnderAttackPinType, keepId)
            end
        end
    end
end

function CMapHandlers:RefreshKeeps()
    RemoveMapPinsInRange(MAP_PIN_TYPE_KEEP_NEUTRAL, MAP_PIN_TYPE_KEEP_ATTACKED_SMALL)
    local numKeeps = GetNumKeeps()
    for i = 1, numKeeps do
        local keepId, bgContext = GetKeepKeysByIndex(i)
        if(IsLocalBattlegroundContext(bgContext)) then
            self:AddKeep(keepId, bgContext)
        end
    end
end

function CMapHandlers:RefreshKeep(keepId, bgContext)
    RemoveMapPinsInRange(MAP_PIN_TYPE_KEEP_NEUTRAL, MAP_PIN_TYPE_KEEP_ATTACKED_SMALL, keepId)
    if(IsLocalBattlegroundContext(bgContext)) then
        self:AddKeep(keepId, bgContext)
    end
end

function CMapHandlers:AddMapPin(pinType, param1, param2, param3)
    if self:ValidatePvPPinAllowed(pinType) then
        AddMapPin(pinType, param1, param2, param3)
    end
end

function CMapHandlers:ValidatePvPPinAllowed(pinType)
    local isAvARespawn = ZO_MapPin.AVA_RESPAWN_PIN_TYPES[pinType]
    local isForwardCamp = ZO_MapPin.FORWARD_CAMP_PIN_TYPES[pinType]
    local isFastTravelKeep = ZO_MapPin.FAST_TRAVEL_KEEP_PIN_TYPES[pinType]
    local isKeep = ZO_MapPin.KEEP_PIN_TYPES[pinType]
    local isDistrict = ZO_MapPin.DISTRICT_PIN_TYPES[pinType]

    if isAvARespawn or isForwardCamp or isFastTravelKeep or isKeep or isDistrict then
        if IsInCyrodiil() then
            return isAvARespawn or isForwardCamp or isFastTravelKeep or isKeep
        elseif IsInImperialCity() then
            return isDistrict or isAvARespawn
        end
        return false
    end
    return true
end

C_MAP_HANDLERS = CMapHandlers:New()

