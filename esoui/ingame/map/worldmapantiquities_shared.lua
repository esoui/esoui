ZO_MAP_ANTIQUITY_CATEGORY_NONE = 0
ZO_MAP_ANTIQUITY_CATEGORY_IN_PROGRESS = 1
ZO_MAP_ANTIQUITY_CATEGORY_AVAILABLE = 2

ZO_MAP_ANTIQUITY_CATEGORY_TO_HEADER_STRING =
{
    [ZO_MAP_ANTIQUITY_CATEGORY_IN_PROGRESS] = SI_WORLD_MAP_ANTIQUITIES_IN_PROGRESS,
    [ZO_MAP_ANTIQUITY_CATEGORY_AVAILABLE] = SI_WORLD_MAP_ANTIQUITIES_AVAILABLE,
}

ZO_MapAntiquities_Shared = ZO_Object:Subclass()

function ZO_MapAntiquities_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_MapAntiquities_Shared:Initialize(control, fragmentClass)
    self.control = control

    local function ResetIconControl(iconControl)
        iconControl:SetParent(nil)
    end

    self.progressIconControlPool = ZO_ControlPool:New("ZO_AntiquityMapProgressIcon", self.control, "AntiquityMapProgressIcon")
    self.progressIconControlPool:SetCustomResetBehavior(ResetIconControl)

    self:InitializeList(control)

    self.fragment = fragmentClass:New(control)
    self.fragment:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    local function UpdateForModeChange(modeData)
        self:SetListEnabled(WORLD_MAP_MANAGER:IsMapChangingAllowed())
    end

    local function RefreshList()
        self:RefreshList()
    end

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", UpdateForModeChange)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", RefreshList)
    self.control:RegisterForEvent(EVENT_ANTIQUITY_TRACKING_INITIALIZED, RefreshList)
    self.control:RegisterForEvent(EVENT_ANTIQUITY_TRACKING_UPDATE, RefreshList)
    self.control:RegisterForEvent(EVENT_ANTIQUITY_UPDATED, RefreshList)
    self.control:RegisterForEvent(EVENT_ANTIQUITIES_UPDATED, RefreshList)
    self.control:RegisterForEvent(EVENT_ANTIQUITY_DIG_SITES_UPDATED, RefreshList)
end

function ZO_MapAntiquities_Shared:InitializeList()
    -- To be overriden
end

function ZO_MapAntiquities_Shared:RefreshList()
    -- To be overriden
end

function ZO_MapAntiquities_Shared:SetListEnabled(enabled)
    self.listEnabled = enabled
end

function ZO_MapAntiquities_Shared:IsListEnabled()
    return self.listEnabled
end

function ZO_MapAntiquities_Shared:GetFragment()
    return self.fragment
end

function ZO_MapAntiquities_Shared:SetNoItemsLabelControl(control)
    self.noItemsLabel = control
end

function ZO_MapAntiquities_Shared:OnShowing()
    self:RefreshList()
end

function ZO_MapAntiquities_Shared:OnHidden()
    --To be overriden
end

function ZO_MapAntiquities_Shared:GetAntiquityCategory(antiquityData)
    if antiquityData:IsInProgress() then
        return ZO_MAP_ANTIQUITY_CATEGORY_IN_PROGRESS
    elseif MeetsAntiquityRequirementsForScrying(antiquityData:GetId(), GetZoneId(GetCurrentMapZoneIndex())) == ANTIQUITY_SCRYING_RESULT_SUCCESS then
        return ZO_MAP_ANTIQUITY_CATEGORY_AVAILABLE
    end

    return ZO_MAP_ANTIQUITY_CATEGORY_NONE
end

do
    local sortKeys =
    {
        antiquityCategory = { tiebreaker = "antiquityName", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        antiquityName = { },
    }

    local function AntiquitySort(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "antiquityCategory", sortKeys, ZO_SORT_ORDER_UP)
    end

    function ZO_MapAntiquities_Shared:SortAntiquityEntries(antiquityEntries)
        table.sort(antiquityEntries, AntiquitySort)
    end
end

function ZO_MapAntiquities_Shared:GetSortedAntiquityEntries()
    local antiquityEntries = {}

    local trackedAntiquityId = GetTrackedAntiquityId()

    for antiquityId, antiquityData in ANTIQUITY_DATA_MANAGER:AntiquityIterator() do
        local antiquityCategory = self:GetAntiquityCategory(antiquityData)
        if antiquityCategory ~= ZO_MAP_ANTIQUITY_CATEGORY_NONE then
            local entryData = 
            {
                antiquityData = antiquityData,
                antiquityCategory = antiquityCategory,
                antiquityName = antiquityData:GetName(),
                isTracked = antiquityData:GetId() == trackedAntiquityId,
            }
            table.insert(antiquityEntries, entryData)
        end
    end

    self:SortAntiquityEntries(antiquityEntries)

    return antiquityEntries
end
