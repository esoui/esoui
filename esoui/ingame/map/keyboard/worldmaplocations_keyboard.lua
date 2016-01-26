local MapLocations = ZO_MapLocations_Shared:Subclass()

local LOCATION_DATA = 1

function MapLocations:New(...)
    local object = ZO_MapLocations_Shared.New(self,...)
    return object
end

function MapLocations:Initialize(control)
    ZO_MapLocations_Shared.Initialize(self, control)
    WORLD_MAP_LOCATIONS_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function MapLocations:InitializeList(control)
    self.list = control:GetNamedChild("List")
end

function MapLocations:UpdateSelectedMap()
    self.selectedMapIndex = GetCurrentMapIndex()
    ZO_ScrollList_RefreshVisible(self.list)
end

function MapLocations:SetListDisabled(disabled)
    self.listDisabled = disabled
    ZO_ScrollList_RefreshVisible(self.list)
end

function MapLocations:BuildLocationList()
    ZO_ScrollList_AddDataType(self.list, LOCATION_DATA, "ZO_WorldMapLocationRow", 23, function(control, data) self:SetupLocation(control, data) end)

    local scrollData = ZO_ScrollList_GetDataList(self.list)

    local mapData = self.data:GetLocationList()

    for i,entry in ipairs(mapData) do
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(LOCATION_DATA, entry)
    end

    ZO_ScrollList_Commit(self.list)
end

function MapLocations:SetupLocation(control, data)
    local listDisabled = self:GetDisabled()
    local locationLabel = control:GetNamedChild("Location")
    locationLabel:SetText(data.locationName)
    locationLabel:SetSelected(self.selectedMapIndex == data.index)    
    locationLabel:SetEnabled(not listDisabled)
    locationLabel:SetMouseEnabled(not listDisabled)
end

--Local XML

function MapLocations:RowLocation_OnMouseDown(label, button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        label:SetAnchor(LEFT, nil, LEFT, 0, 1)
    end
end

function MapLocations:RowLocation_OnMouseUp(label, button, upInside)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        label:SetAnchor(LEFT, nil, LEFT, 0, 0)
        if(upInside) then
            local data = ZO_ScrollList_GetData(label:GetParent())
            ZO_WorldMap_SetMapByIndex(data.index)
            PlaySound(SOUNDS.MAP_LOCATION_CLICKED)
        end
    end
end

--Global XML

function ZO_WorldMapLocationRowLocation_OnMouseDown(label, button)
    WORLD_MAP_LOCATIONS:RowLocation_OnMouseDown(label, button)
end

function ZO_WorldMapLocationRowLocation_OnMouseUp(label, button, upInside)
    WORLD_MAP_LOCATIONS:RowLocation_OnMouseUp(label, button, upInside)
end

function ZO_WorldMapLocations_OnInitialized(self)
    WORLD_MAP_LOCATIONS = MapLocations:New(self)
end