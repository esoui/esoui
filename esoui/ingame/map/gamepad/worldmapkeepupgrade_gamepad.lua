--Keep Upgrade Window Gamepad
ZO_WORLD_MAP_KEEP_UPGRADE_GAMEPAD_BUTTON_SIZE = 64

local SYMBOL_PARAMS = {
    GRID_DEFAULT_SPACING_Y = ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD,
    SYMBOL_PADDING_Y = 15,
    SYMBOL_ICON_SIZE = ZO_WORLD_MAP_KEEP_UPGRADE_GAMEPAD_BUTTON_SIZE,
}

local MapKeepUpgrade_Gamepad = ZO_MapKeepUpgrade_Shared:Subclass()

function MapKeepUpgrade_Gamepad:New(...)
    return ZO_MapKeepUpgrade_Shared.New(self, ...)
end

function MapKeepUpgrade_Gamepad:Initialize(control)
    self.symbolParams = SYMBOL_PARAMS
    self.sideContent = control:GetNamedChild("SideContent")

    self.gridListClass = ZO_SingleTemplateGridScrollList_Gamepad
    self.labelLayout = "ZO_WorldMapKeepUpgradeHeader_Gamepad"
    self.buttonLayout = "ZO_WorldMapKeepUpgradeButton_Gamepad"

    self.scrollTooltip = control:GetNamedChild("SideContent"):GetNamedChild("Tooltip")
    ZO_ScrollTooltip_Gamepad:Initialize(self.scrollTooltip, ZO_TOOLTIP_STYLES, "worldMapTooltip")
    zo_mixin(self.scrollTooltip, ZO_MapInformationTooltip_Gamepad_Mixin)
    ZO_Scroll_Gamepad_SetScrollIndicatorSide(self.scrollTooltip.scrollIndicator, ZO_SharedGamepadNavQuadrant_4_Background, LEFT)

    ZO_MapKeepUpgrade_Shared.Initialize(self, control)

    self.levelsGridList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnGridListSelectedDataChanged(previousData, newData) end)
end

function MapKeepUpgrade_Gamepad:Activate()
    self.levelsGridList:Activate()
end

function MapKeepUpgrade_Gamepad:Deactivate()
    self.levelsGridList:Deactivate()
end

function MapKeepUpgrade_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
    self.scrollTooltip:ClearLines()

    if newData and newData.description and newData.description ~= "" then
        self.scrollTooltip:LayoutKeepUpgrade(newData.name, newData.description)
    end
end

function MapKeepUpgrade_Gamepad:OnFragmentShown()
    ZO_MapKeepUpgrade_Shared.OnFragmentShown(self)
    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
    ZO_WorldMap_UpdateMap()
end

function MapKeepUpgrade_Gamepad:OnFragmentHidden()
    ZO_MapKeepUpgrade_Shared.OnFragmentHidden(self)
    self.scrollTooltip:ClearLines()
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
    ZO_WorldMap_UpdateMap()
end

function MapKeepUpgrade_Gamepad:RefreshData()
    self.keepUpgradeObject = GAMEPAD_WORLD_MAP_KEEP_INFO:GetKeepUpgradeObject()
end

--Globals

function ZO_WorldMapKeepUpgrade_Gamepad_OnInitialized(self)
    GAMEPAD_WORLD_MAP_KEEP_UPGRADE = MapKeepUpgrade_Gamepad:New(self)
    GAMEPAD_WORLD_MAP_KEEP_INFO:SetFragment("UPGRADE_FRAGMENT", GAMEPAD_WORLD_MAP_KEEP_UPGRADE:GetFragment())
end