local WorldMapInfo = ZO_WorldMapInfo_Shared:Subclass()

function WorldMapInfo:New(...)
    local object = ZO_WorldMapInfo_Shared.New(self, ...)
    return object
end

function WorldMapInfo:Initialize(control)
    ZO_WorldMapInfo_Shared.Initialize(self, control)

    WORLD_MAP_INFO_FRAGMENT = ZO_FadeSceneFragment:New(control)
    WORLD_MAP_INFO_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWING) then
            self.modeBar:ShowLastFragment()
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            self.modeBar:Clear()
        end
    end)
end

function WorldMapInfo:InitializeTabs()
    local function CreateButtonData(normal, pressed, highlight)
        return {
            normal = normal,
            pressed = pressed,
            highlight = highlight,
        }
    end
    
    self.modeBar = ZO_SceneFragmentBar:New(self.control:GetNamedChild("MenuBar"))
    self.modeBar:SetStartingFragment(SI_MAP_INFO_MODE_QUESTS)

    --Quests Button
    local questButtonData = CreateButtonData("EsoUI/Art/WorldMap/map_indexIcon_quests_up.dds",
                                             "EsoUI/Art/WorldMap/map_indexIcon_quests_down.dds",
                                             "EsoUI/Art/WorldMap/map_indexIcon_quests_over.dds")
    self.modeBar:Add(SI_MAP_INFO_MODE_QUESTS, { WORLD_MAP_QUESTS_FRAGMENT }, questButtonData)  

    --Key Button
    local keyButtonData = CreateButtonData("EsoUI/Art/WorldMap/map_indexIcon_key_up.dds",
                                           "EsoUI/Art/WorldMap/map_indexIcon_key_down.dds",
                                           "EsoUI/Art/WorldMap/map_indexIcon_key_over.dds")
    self.modeBar:Add(SI_MAP_INFO_MODE_KEY, { WORLD_MAP_KEY_FRAGMENT }, keyButtonData)

    --Filters Button
    local filtersButtonData = CreateButtonData("EsoUI/Art/WorldMap/map_indexIcon_filters_up.dds",
                                           "EsoUI/Art/WorldMap/map_indexIcon_filters_down.dds",
                                           "EsoUI/Art/WorldMap/map_indexIcon_filters_over.dds")
    self.modeBar:Add(SI_MAP_INFO_MODE_FILTERS, { WORLD_MAP_KEY_FILTERS_FRAGMENT }, filtersButtonData) 

    --Locations Button
    local locationButtonData = CreateButtonData("EsoUI/Art/WorldMap/map_indexIcon_locations_up.dds",
                                                "EsoUI/Art/WorldMap/map_indexIcon_locations_down.dds",
                                                "EsoUI/Art/WorldMap/map_indexIcon_locations_over.dds")
    self.modeBar:Add(SI_MAP_INFO_MODE_LOCATIONS, { WORLD_MAP_LOCATIONS_FRAGMENT }, locationButtonData)

	--Houses Button
    local housesButtonData = CreateButtonData("EsoUI/Art/WorldMap/map_indexIcon_housing_up.dds",
                                                "EsoUI/Art/WorldMap/map_indexIcon_housing_down.dds",
                                                "EsoUI/Art/WorldMap/map_indexIcon_housing_over.dds")
    self.modeBar:Add(SI_MAP_INFO_MODE_HOUSES, { WORLD_MAP_HOUSES:GetFragment() }, housesButtonData)

end

function WorldMapInfo:SelectTab(name)
    if(WORLD_MAP_INFO_FRAGMENT:IsShowing()) then
        self.modeBar:SelectFragment(name)
    else
        self.modeBar:SetStartingFragment(name)
    end
end

--Global

function ZO_WorldMapInfo_Initialize()
    WORLD_MAP_INFO = WorldMapInfo:New(ZO_WorldMapInfo)
end