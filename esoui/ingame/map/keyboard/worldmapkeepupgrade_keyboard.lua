--Keep Upgrade Window
local SYMBOL_PARAMS = {
    FIRST_SECTION_OFFSET_X = 39,
    FIRST_SECTION_OFFSET_Y = 10,
    SYMBOL_PADDING_X = 0,
    SYMBOL_PADDING_Y = 5,
    SYMBOL_SECTION_OFFSET_X = 0,
    SYMBOL_SECTION_OFFSET_Y = 20,
}

local MapKeepUpgrade = ZO_MapKeepUpgrade_Shared:Subclass()

function MapKeepUpgrade:New(...)
    local object = ZO_MapKeepUpgrade_Shared.New(self, ...)
    return object
end

function MapKeepUpgrade:Initialize(control)
    self.symbolParams = SYMBOL_PARAMS

    self.levelLayout = "ZO_WorldMapKeepUpgradeLevel"
    self.buttonLayout = "ZO_WorldMapKeepUpgradeButton"

    ZO_MapKeepUpgrade_Shared.Initialize(self, control)

    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWN) then
            self:RefreshAll()
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            self.keepUpgradeObject = nil
        end
    end)
end

function MapKeepUpgrade:RefreshAll()
    self:RefreshData()
    self:RefreshLevels()
    self:RefreshBarLabel()
    self:RefreshTimeDependentControls()
end

function MapKeepUpgrade:RefreshData()
    self.keepUpgradeObject = WORLD_MAP_KEEP_INFO:GetKeepUpgradeObject()
end



--Global XML

function ZO_WorldMapKeepUpgradeButton_OnMouseEnter(button)
    WORLD_MAP_KEEP_UPGRADE:Button_OnMouseEnter(button)
end

function ZO_WorldMapKeepUpgradeButton_OnMouseExit(button)
    WORLD_MAP_KEEP_UPGRADE:Button_OnMouseExit(button)
end

function ZO_WorldMapKeepUpgradeTime_OnMouseEnter(self)
    WORLD_MAP_KEEP_UPGRADE:Time_OnMouseEnter(self)
end

function ZO_WorldMapKeepUpgradeTime_OnMouseExit(self)
    WORLD_MAP_KEEP_UPGRADE:Time_OnMouseExit(self)
end

function ZO_WorldMapKeepUpgradeBar_OnMouseEnter(self)
    WORLD_MAP_KEEP_UPGRADE:Bar_OnMouseEnter(self)
end

function ZO_WorldMapKeepUpgradeBar_OnMouseExit(self)
    WORLD_MAP_KEEP_UPGRADE:Bar_OnMouseExit(self)
end

--Globals

function ZO_WorldMapKeepUpgrade_OnInitialized(self)
    WORLD_MAP_KEEP_UPGRADE = MapKeepUpgrade:New(self)
    WORLD_MAP_KEEP_INFO:SetFragment("UPGRADE_FRAGMENT", WORLD_MAP_KEEP_UPGRADE:GetFragment())
end