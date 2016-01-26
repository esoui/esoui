--Keep Upgrade Type

local KeepUpgrade = ZO_KeepUpgrade_Shared:Subclass()

--Resource Upgrade Type

local ResourceUpgrade = ZO_ResourceUpgrade_Shared:Subclass()

--World Map Keep Info

local WorldMapKeepInfo = ZO_WorldMapKeepInfo_Shared:Subclass()

function WorldMapKeepInfo:New(...)
    local object = ZO_WorldMapKeepInfo_Shared.New(self, ...)
    return object
end

function WorldMapKeepInfo:Initialize(control)
    self.modeBar = ZO_SceneFragmentBar:New(control:GetNamedChild("MenuBar"))

    ZO_WorldMapKeepInfo_Shared.Initialize(self, control)

    self.keepUpgrade = KeepUpgrade:New()
    self.resourceUpgrade = ResourceUpgrade:New()

    self.worldMapKeepInfoBGFragment = ZO_FadeSceneFragment:New(ZO_WorldMapKeepInfoFootPrintBackground)
    self.worldMapKeepInfoFragment = ZO_FadeSceneFragment:New(control)
    self.worldMapKeepInfoFragment:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_HIDDEN) then
            self.keepUpgradeObject = nil
            self.modeBar:Clear()
        end
    end)
end

function WorldMapKeepInfo:PreShowKeep()
    self.modeBar:RemoveAll()
end

function WorldMapKeepInfo:PostShowKeep()
    self.modeBar:SelectFragment(SI_MAP_KEEP_INFO_MODE_SUMMARY)
end

function WorldMapKeepInfo:BeginBar()
end

function WorldMapKeepInfo:AddBar(text, fragments, buttonData)
    self.modeBar:Add(text, fragments, buttonData)
end

function WorldMapKeepInfo:FinishBar()
end

--Global

function ZO_WorldMapKeepInfo_OnInitialize(control)
    WORLD_MAP_KEEP_INFO = WorldMapKeepInfo:New(control)
    SYSTEMS:RegisterKeyboardObject("world_map_keep_info", WORLD_MAP_KEEP_INFO)
end