--Keep Upgrade Type

local KeepUpgrade_Gamepad = ZO_KeepUpgrade_Shared:Subclass()

--Resource Upgrade Type

local ResourceUpgrade_Gamepad = ZO_ResourceUpgrade_Shared:Subclass()

--World Map Keep Info

local WorldMapKeepInfo_Gamepad = ZO_WorldMapKeepInfo_Shared:Subclass()

function WorldMapKeepInfo_Gamepad:New(...)
    local object = ZO_WorldMapKeepInfo_Shared.New(self, ...)
    return object
end

function WorldMapKeepInfo_Gamepad:Initialize(control)
    self.header = control:GetNamedChild("Container"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    ZO_WorldMapKeepInfo_Shared.Initialize(self, control)

    self.keepUpgrade = KeepUpgrade_Gamepad:New()
    self.resourceUpgrade = ResourceUpgrade_Gamepad:New()

    self.worldMapKeepInfoBGFragment = ZO_FadeSceneFragment:New(ZO_WorldMapKeepInfoFootPrintBackground_Gamepad)
    self.worldMapKeepInfoFragment = ZO_FadeSceneFragment:New(control)
    GAMEPAD_WORLD_MAP_KEEP_INFO_FRAGMENT = self.worldMapKeepInfoFragment
    self.worldMapKeepInfoFragment:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWING) then
            ZO_WorldMap_SetKeepMode(true)
            ZO_GamepadGenericHeader_Activate(self.header)
            if self.fragments then
                SCENE_MANAGER:AddFragmentGroup(self.fragments)
            end
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            self.keepUpgradeObject = nil
            ZO_GamepadGenericHeader_Deactivate(self.header)
            if self.fragments then
                SCENE_MANAGER:RemoveFragmentGroup(self.fragments)
            end
            ZO_WorldMap_SetKeepMode(false)
        end
    end)
end

function WorldMapKeepInfo_Gamepad:SwitchToFragments(fragments)
    if(self.fragments) then
        SCENE_MANAGER:RemoveFragmentGroup(self.fragments)
    end

    self.fragments = fragments

    if SCENE_MANAGER:IsShowing("gamepad_worldMap") then
        SCENE_MANAGER:AddFragmentGroup(self.fragments)
    end
end

function WorldMapKeepInfo_Gamepad:BeginBar()
    self.tabBarEntries = {}
end

function WorldMapKeepInfo_Gamepad:AddBar(text, fragments, buttonData)
    self.tabBarEntries[#self.tabBarEntries + 1] = {
        text = GetString(text),
        callback = function() self:SwitchToFragments(fragments) end,
    }
end

function WorldMapKeepInfo_Gamepad:FinishBar()
    self.baseHeaderData = {
        tabBarEntries = self.tabBarEntries,
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.baseHeaderData)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, 1)
end

--Global

function ZO_WorldMapKeepInfo_Gamepad_OnInitialize(control)
    GAMEPAD_WORLD_MAP_KEEP_INFO = WorldMapKeepInfo_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("world_map_keep_info", GAMEPAD_WORLD_MAP_KEEP_INFO)
end