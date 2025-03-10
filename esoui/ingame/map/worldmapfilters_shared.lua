--Filter Panel

ZO_WorldMapFilterPanel_Shared = ZO_InitializingObject:Subclass()

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

ZO_WorldMapFilters_Shared = ZO_InitializingObject:Subclass()

function ZO_WorldMapFilters_Shared:Initialize(control)
    self.control = control

    local function OnMapChanged()
        local mapFilterType = GetMapFilterType()
        local mode = WORLD_MAP_MANAGER:GetMode()
        local newCurrentPanel
        if mapFilterType == MAP_FILTER_TYPE_STANDARD then
            newCurrentPanel = self.pvePanel
            self.pvePanel:SetMapMode(mode)
        elseif mapFilterType == MAP_FILTER_TYPE_AVA_CYRODIIL then
            newCurrentPanel = self.pvpPanel
            self.pvpPanel:SetMapMode(mode)
        elseif mapFilterType == MAP_FILTER_TYPE_AVA_IMPERIAL then
            newCurrentPanel = self.imperialPvPPanel
            self.imperialPvPPanel:SetMapMode(mode)
        elseif mapFilterType == MAP_FILTER_TYPE_BATTLEGROUND then
            newCurrentPanel = self.battlegroundPanel
            self.battlegroundPanel:SetMapMode(mode)
        elseif mapFilterType == MAP_FILTER_TYPE_GLOBAL then
            newCurrentPanel = self.globalPanel
            self.globalPanel:SetMapMode(mode)
        end
        if self.currentPanel and self.currentPanel ~= newCurrentPanel then
            self.currentPanel:SetHidden(true)
        end
        if internalassert(newCurrentPanel, "Invalid mapFilterType returned from GetMapFilterType, was this called during a load screen?") then
            newCurrentPanel:SetHidden(false)
        end
        self.currentPanel = newCurrentPanel
    end

    internalassert(MAP_FILTER_TYPE_MAX_VALUE == 5, "New MapFilterType, account for it in OnMapChanged")

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnMapChanged)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", OnMapChanged)
end

-- Cosmic and World maps

ZO_GlobalWorldMapFilterPanel_Shared = ZO_InitializingObject:Subclass()

function ZO_GlobalWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    self:AddPinFilterCheckBox(MAP_FILTER_WAYSHRINES, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_DUNGEONS, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_TRIALS, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_HOUSES, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, function() ZO_WorldMap_GetPinManager():RefreshGroupPins() end)

    self:PostBuildControls()
end

-- Shared PVP and PVE panel code

ZO_PvEWorldMapFilterPanel_Shared = ZO_InitializingObject:Subclass()

function ZO_PvEWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    local function RefreshObjectives()
        ZO_WorldMap_RefreshAllPOIs()
        WORLD_MAP_MANAGER:RefreshSkyshardPins()
    end

    self:AddPinFilterCheckBox(MAP_FILTER_OBJECTIVES, RefreshObjectives, GetString(SI_WORLD_MAP_FILTERS_SHOW_DETAILS))
    self:AddPinFilterCheckBox(MAP_FILTER_WAYSHRINES, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_DUNGEONS, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_TRIALS, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_HOUSES, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, function() ZO_WorldMap_GetPinManager():RefreshGroupPins() end)
    self:AddPinFilterCheckBox(MAP_FILTER_DIG_SITES, function() WORLD_MAP_MANAGER:RefreshAllAntiquityDigSites() end)
    self:AddPinFilterCheckBox(MAP_FILTER_COMPANIONS, function() WORLD_MAP_MANAGER:RefreshCompanionPins() end)
    self:AddPinFilterCheckBox(MAP_FILTER_ACQUIRED_SKYSHARDS, function() WORLD_MAP_MANAGER:RefreshSkyshardPins() end)

    self:PostBuildControls()
end

ZO_PvPWorldMapFilterPanel_Shared = ZO_InitializingObject:Subclass()

function ZO_PvPWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    self:AddPinFilterCheckBox(MAP_FILTER_OBJECTIVES, ZO_WorldMap_RefreshAllPOIs, GetString(SI_WORLD_MAP_FILTERS_SHOW_DETAILS))
    self:AddPinFilterCheckBox(MAP_FILTER_WAYSHRINES, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_DUNGEONS, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_TRIALS, ZO_WorldMap_RefreshWayshrines)
    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, function() ZO_WorldMap_GetPinManager():RefreshGroupPins() end)
    self:AddPinFilterCheckBox(MAP_FILTER_KILL_LOCATIONS, ZO_WorldMap_RefreshKillLocations)
    self:AddPinFilterCheckBox(MAP_FILTER_RESOURCE_KEEPS, ZO_WorldMap_RefreshKeeps)
    self:AddPinFilterCheckBox(MAP_FILTER_AVA_GRAVEYARDS, function() 
        ZO_WorldMap_RefreshForwardCamps()
        ZO_WorldMap_RefreshAccessibleAvAGraveyards()
    end)
    self:AddPinFilterCheckBox(MAP_FILTER_AVA_GRAVEYARD_AREAS, ZO_WorldMap_RefreshForwardCamps)
    self:AddPinFilterCheckBox(MAP_FILTER_TRANSIT_LINES, ZO_WorldMap_RefreshKeepNetwork)
    self:ComboBoxDependsOn(MAP_FILTER_TRANSIT_LINES_ALLIANCE, MAP_FILTER_TRANSIT_LINES)
    self:AddPinFilterComboBox(MAP_FILTER_TRANSIT_LINES_ALLIANCE, ZO_WorldMap_RefreshKeepNetwork, GetString(SI_WORLD_MAP_FILTERS_SHOW_ALLIANCE), "SI_MAPTRANSITLINEALLIANCE", MAP_TRANSIT_LINE_ALLIANCE_ALL, MAP_TRANSIT_LINE_ALLIANCE_MINE)
    self:AddPinFilterCheckBox(MAP_FILTER_ACQUIRED_SKYSHARDS, function() WORLD_MAP_MANAGER:RefreshSkyshardPins() end)

    self:PostBuildControls()
end

ZO_ImperialPvPWorldMapFilterPanel_Shared = ZO_InitializingObject:Subclass()

function ZO_ImperialPvPWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    self:AddPinFilterCheckBox(MAP_FILTER_OBJECTIVES, ZO_WorldMap_RefreshAllPOIs, GetString(SI_WORLD_MAP_FILTERS_SHOW_DETAILS))
    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, function() ZO_WorldMap_GetPinManager():RefreshGroupPins() end)
    self:AddPinFilterCheckBox(MAP_FILTER_KILL_LOCATIONS, ZO_WorldMap_RefreshKillLocations)
    self:AddPinFilterCheckBox(MAP_FILTER_ACQUIRED_SKYSHARDS, function() WORLD_MAP_MANAGER:RefreshSkyshardPins() end)

    self:PostBuildControls()
end

ZO_BattlegroundWorldMapFilterPanel_Shared = ZO_InitializingObject:Subclass()

function ZO_BattlegroundWorldMapFilterPanel_Shared:BuildControls()
    self:PreBuildControls()

    self:AddPinFilterCheckBox(MAP_FILTER_GROUP_MEMBERS, function() ZO_WorldMap_GetPinManager():RefreshGroupPins() end)

    self:PostBuildControls()
end
