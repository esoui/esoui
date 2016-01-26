--Filter Panel

ZO_WorldMapFilterPanel_Shared = ZO_Object:Subclass()

function ZO_WorldMapFilterPanel_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapFilterPanel_Shared:Initialize(control, mapFilterType, savedVars)
    self.control = control
    self.savedVars = savedVars
    self.mapFilterType = mapFilterType
    self.pinFilterCheckBoxes = {}
    self.pinFilterOptionComboBoxes = {} 
end

function ZO_WorldMapFilterPanel_Shared:AnchorControl(control, offsetX)
    if(offsetX == nil) then
        offsetX  = 0
    end

    if(self.lastControl) then
        control:SetAnchor(TOPLEFT, self.lastControl, BOTTOMLEFT, offsetX - self.lastOffsetX, 8)
    else
        control:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, offsetX)
    end

    self.lastControl = control
    self.lastOffsetX = offsetX
end

function ZO_WorldMapFilterPanel_Shared:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_WorldMapFilterPanel_Shared:GetPinFilter(mapPinGroup)
    if self.modeVars then
        local filter = self.modeVars.filters[self.mapFilterType]
        if filter then
            return filter[mapPinGroup]
        end
    end
    return nil
end

function ZO_WorldMapFilterPanel_Shared:SetPinFilter(mapPinGroup, shown)
    self.modeVars.filters[self.mapFilterType][mapPinGroup] = shown
end

function ZO_WorldMapFilterPanel_Shared:FindCheckBox(mapPinGroup)
    for _, checkBox in ipairs(self.pinFilterCheckBoxes) do
        if(checkBox.mapPinGroup == mapPinGroup) then
            return checkBox
        end
    end
    return nil
end

function ZO_WorldMapFilterPanel_Shared:FindComboBox(mapPinGroup)
    for _, comboBox in ipairs(self.pinFilterOptionComboBoxes) do
        if(comboBox.mapPinGroup == mapPinGroup) then
            return comboBox
        end
    end
    return nil
end

function ZO_WorldMapFilterPanel_Shared:ComboBoxDependsOn(childPinGroup, parentPinGroup)
    local checkBox = self:FindCheckBox(parentPinGroup)
    checkBox.dependentComboBox = childPinGroup
end

function ZO_WorldMapFilterPanel_Shared:FindDependentCheckBox(mapPinGroup)
    for _, checkBox in ipairs(self.pinFilterCheckBoxes) do
        if(checkBox.dependentComboBox == mapPinGroup) then
            return checkBox
        end
    end
    return nil
end

function ZO_WorldMapFilterPanel_Shared:PreBuildControls()
    
end

function ZO_WorldMapFilterPanel_Shared:BuildControls()
    
end

function ZO_WorldMapFilterPanel_Shared:PostBuildControls()
    
end

--Filters

ZO_WorldMapFilters_Shared = ZO_Object:Subclass()

function ZO_WorldMapFilters_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapFilters_Shared:Initialize(control)
    self.control = control

    local function OnMapChanged()
        local mapFilterType = GetMapFilterType()
        local mode = ZO_WorldMap_GetMode()
        local newCurrentPanel
        if(mapFilterType == MAP_FILTER_TYPE_STANDARD) then
            newCurrentPanel = self.pvePanel
            self.pvePanel:SetMapMode(mode)
        elseif(mapFilterType == MAP_FILTER_TYPE_AVA_CYRODIIL) then
            newCurrentPanel = self.pvpPanel
            self.pvpPanel:SetMapMode(mode)
        elseif(mapFilterType == MAP_FILTER_TYPE_AVA_IMPERIAL) then
            newCurrentPanel = self.imperialPvPPanel
            self.imperialPvPPanel:SetMapMode(mode)
        end
        if self.currentPanel and self.currentPanel ~= newCurrentPanel then
            self.currentPanel:SetHidden(true)
        end
        newCurrentPanel:SetHidden(false)
        self.currentPanel = newCurrentPanel
    end
    
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnMapChanged)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", OnMapChanged)
end

-- Shared PVP and PVE panel code

ZO_PvEWorldMapFilterPanel_Shared = ZO_Object:Subclass()

function ZO_PvEWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    self:AddPinFilterCheckBox(MAP_FILTER_OBJECTIVES, ZO_WorldMap_RefreshAllPOIs, GetString(SI_WORLD_MAP_FILTERS_SHOW_DETAILS))
    self:AddPinFilterCheckBox(MAP_FILTER_WAYSHRINES, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, ZO_WorldMap_RefreshGroupPins)

    self:PostBuildControls()
end

ZO_PvPWorldMapFilterPanel_Shared = ZO_Object:Subclass()

function ZO_PvPWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    self:AddPinFilterCheckBox(MAP_FILTER_OBJECTIVES, ZO_WorldMap_RefreshAllPOIs, GetString(SI_WORLD_MAP_FILTERS_SHOW_DETAILS))
    self:AddPinFilterCheckBox(MAP_FILTER_WAYSHRINES, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, ZO_WorldMap_RefreshGroupPins)
    self:AddPinFilterCheckBox(MAP_FILTER_KILL_LOCATIONS, ZO_WorldMap_RefreshKillLocations)
    self:AddPinFilterCheckBox(MAP_FILTER_RESOURCE_KEEPS, ZO_WorldMap_RefreshKeeps)
    self:AddPinFilterCheckBox(MAP_FILTER_IMPERIAL_CITY_ENTRANCES, ZO_WorldMap_RefreshImperialCity)
    self:AddPinFilterCheckBox(MAP_FILTER_AVA_GRAVEYARDS, function() 
        ZO_WorldMap_RefreshForwardCamps()
        ZO_WorldMap_RefreshAccessibleAvAGraveyards()
    end)
    self:AddPinFilterCheckBox(MAP_FILTER_AVA_GRAVEYARD_AREAS, ZO_WorldMap_RefreshForwardCamps)
    self:AddPinFilterCheckBox(MAP_FILTER_TRANSIT_LINES, ZO_WorldMap_RefreshKeepNetwork)
    self:ComboBoxDependsOn(MAP_FILTER_TRANSIT_LINES_ALLIANCE, MAP_FILTER_TRANSIT_LINES)
    self:AddPinFilterComboBox(MAP_FILTER_TRANSIT_LINES_ALLIANCE, ZO_WorldMap_RefreshKeepNetwork, GetString(SI_WORLD_MAP_FILTERS_SHOW_ALLIANCE), "SI_MAPTRANSITLINEALLIANCE", MAP_TRANSIT_LINE_ALLIANCE_ALL, MAP_TRANSIT_LINE_ALLIANCE_MINE)

    self:PostBuildControls()
end

ZO_ImperialPvPWorldMapFilterPanel_Shared = ZO_Object:Subclass()

function ZO_ImperialPvPWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    self:AddPinFilterCheckBox(MAP_FILTER_OBJECTIVES, ZO_WorldMap_RefreshAllPOIs, GetString(SI_WORLD_MAP_FILTERS_SHOW_DETAILS))
    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, ZO_WorldMap_RefreshGroupPins)
    self:AddPinFilterCheckBox(MAP_FILTER_KILL_LOCATIONS, ZO_WorldMap_RefreshKillLocations)

    self:PostBuildControls()
end
