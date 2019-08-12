--Keep Upgrade Window
ZO_WORLD_MAP_KEEP_UPGRADE_KEYBOARD_BUTTON_SIZE = 40

local SYMBOL_PARAMS = {
    GRID_DEFAULT_SPACING_Y = 0,
    SYMBOL_PADDING_Y = 15,
    SYMBOL_ICON_SIZE = ZO_WORLD_MAP_KEEP_UPGRADE_KEYBOARD_BUTTON_SIZE,
}

local MapKeepUpgrade = ZO_MapKeepUpgrade_Shared:Subclass()

function MapKeepUpgrade:New(...)
    return ZO_MapKeepUpgrade_Shared.New(self, ...)
end

function MapKeepUpgrade:Initialize(control)
    self.symbolParams = SYMBOL_PARAMS

    self.gridListClass = ZO_SingleTemplateGridScrollList_Keyboard
    self.labelLayout = "ZO_WorldMapKeepUpgradeHeader_Keyboard"
    self.buttonLayout = "ZO_WorldMapKeepUpgradeButton_Keyboard"

    ZO_MapKeepUpgrade_Shared.Initialize(self, control)
end

function MapKeepUpgrade:RefreshData()
    self.keepUpgradeObject = WORLD_MAP_KEEP_INFO:GetKeepUpgradeObject()
end

function MapKeepUpgrade:Button_OnMouseEnter(control)
    InitializeTooltip(KeepUpgradeTooltip, control, TOPLEFT, 5, 0)

    local data = control.dataEntry.data:GetDataSource()
    self.keepUpgradeObject:SetUpgradeTooltip(data.level, data.index)
end

function MapKeepUpgrade:Button_OnMouseExit(button)
    ClearTooltip(KeepUpgradeTooltip)
end

function MapKeepUpgrade:Time_OnMouseEnter(label)
    InitializeTooltip(InformationTooltip, label, TOPLEFT, 10, 0)
    self.keepUpgradeObject:SetRateTooltip()
end

function MapKeepUpgrade:Time_OnMouseExit(label)
    ClearTooltip(InformationTooltip)
end

function ZO_MapKeepUpgrade_Shared:Bar_OnMouseEnter(bar)
    if not self.timeContainer:IsHidden() then
        self:Time_OnMouseEnter(self.timeContainer)
    end
end

function ZO_MapKeepUpgrade_Shared:Bar_OnMouseExit(bar)
    self:Time_OnMouseExit(self.timeContainer)
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