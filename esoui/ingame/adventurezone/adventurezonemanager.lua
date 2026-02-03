ZO_AdventureZoneManager = ZO_InitializingObject:Subclass()

ZO_ADVENTURE_ZONE_PANELS =
{
    BOSS_TREE = 1,
    OVERVIEW = 2,
}

function ZO_AdventureZoneManager:Initialize()
    self.panelToOpen = ZO_ADVENTURE_ZONE_PANELS.BOSS_TREE
end

function ZO_AdventureZoneManager:SetPanelToOpen(panelToOpen)
    self.panelToOpen = panelToOpen
end

function ZO_AdventureZoneManager:ToggleAdventureZonePanel()
    if (ADVENTURE_ZONE_BOSS_TREE_KEYBOARD and ADVENTURE_ZONE_BOSS_TREE_KEYBOARD:IsShowing()) or
        ADVENTURE_ZONE_BOSS_TREE_GAMEPAD:IsShowing() or
        (ADVENTURE_ZONE_OVERVIEW_KEYBOARD and ADVENTURE_ZONE_OVERVIEW_KEYBOARD:IsShowing()) or
        ADVENTURE_ZONE_OVERVIEW_GAMEPAD:IsShowing() then
            SCENE_MANAGER:HideCurrentScene()
    elseif self.panelToOpen == ZO_ADVENTURE_ZONE_PANELS.BOSS_TREE then
        SYSTEMS:ShowScene("adventureZoneBossTree")
    elseif self.panelToOpen == ZO_ADVENTURE_ZONE_PANELS.OVERVIEW then
        SYSTEMS:ShowScene("adventureZoneOverview")
    end
end

ADVENTURE_ZONE_MANAGER = ZO_AdventureZoneManager:New()