local WorldMapInfo_Gamepad = ZO_WorldMapInfo_Shared:Subclass()

function WorldMapInfo_Gamepad:New(...)
    local object = ZO_WorldMapInfo_Shared.New(self, ...)
    return object
end

function WorldMapInfo_Gamepad:Initialize(control)
    ZO_WorldMapInfo_Shared.Initialize(self, control)

    GAMEPAD_WORLD_MAP_INFO_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_WORLD_MAP_INFO_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWING) then
            ZO_GamepadGenericHeader_Activate(self.header)
            ZO_WorldMap_SetGamepadKeybindsShown(false)
            self:ShowCurrentFragments()
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            ZO_GamepadGenericHeader_Deactivate(self.header)
            self:RemoveCurrentFragments()
        end
    end)
end

function WorldMapInfo_Gamepad:Show()
    SCENE_MANAGER:AddFragment(GAMEPAD_WORLD_MAP_INFO_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
end

function WorldMapInfo_Gamepad:Hide()
    SCENE_MANAGER:RemoveFragment(GAMEPAD_WORLD_MAP_INFO_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)

    ZO_WorldMap_SetGamepadKeybindsShown(true)
    ZO_WorldMap_UpdateInteractKeybind_Gamepad()
end

function WorldMapInfo_Gamepad:ShowCurrentFragments()
    if self.fragment then
        SCENE_MANAGER:AddFragment(self.fragment)
        if self.usesRightSideContent then
            SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
        end
    end
end

function WorldMapInfo_Gamepad:RemoveCurrentFragments()
    if self.fragment then
        SCENE_MANAGER:RemoveFragment(self.fragment)
        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
    end
end

function WorldMapInfo_Gamepad:SwitchToFragment(fragment, usesRightSideContent)
    if self.fragment == fragment then
        return
    end

    self:RemoveCurrentFragments()

    self.fragment = fragment
    self.usesRightSideContent = usesRightSideContent

    if SCENE_MANAGER:IsShowing("gamepad_worldMap") then
        self:ShowCurrentFragments()
    end
end

function WorldMapInfo_Gamepad:InitializeTabs()
    self.header = self.control:GetNamedChild("Container"):GetNamedChild("Header")

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    local USES_RIGHT_SIDE_CONTENT = true
    local DOESNT_USE_RIGHT_SIDE_CONTENT = false
    -- Table for the Window data. Each entry is a tab in the UI.
    self.tabBarEntries = {
        {
            text = GetString(SI_MAP_INFO_MODE_QUESTS), 
            callback = function() self:SwitchToFragment(GAMEPAD_WORLD_MAP_QUESTS_FRAGMENT, USES_RIGHT_SIDE_CONTENT) end
        },
        {
            text = GetString(SI_MAP_INFO_MODE_LOCATIONS), 
            callback = function() self:SwitchToFragment(GAMEPAD_WORLD_MAP_LOCATIONS_FRAGMENT, USES_RIGHT_SIDE_CONTENT) end
        },
        {
            text = GetString(SI_MAP_INFO_MODE_FILTERS), 
            callback = function() self:SwitchToFragment(GAMEPAD_WORLD_MAP_FILTERS_FRAGMENT, DOESNT_USE_RIGHT_SIDE_CONTENT) end
        },
        {
            text = GetString(SI_MAP_INFO_MODE_HOUSES), 
            callback = function() self:SwitchToFragment(GAMEPAD_WORLD_MAP_HOUSES:GetFragment(), DOESNT_USE_RIGHT_SIDE_CONTENT) end
        },
    }

    self.baseHeaderData = {
        tabBarEntries = self.tabBarEntries,
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.baseHeaderData)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, 1)
end

--Global

function ZO_WorldMapInfo_Gamepad_Initialize()
    GAMEPAD_WORLD_MAP_INFO = WorldMapInfo_Gamepad:New(ZO_WorldMapInfo_Gamepad)
end

function ZO_WorldMapInfo_OnBackPressed()
    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    GAMEPAD_WORLD_MAP_INFO:Hide()
end
