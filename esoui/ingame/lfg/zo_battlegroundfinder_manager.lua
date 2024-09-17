local categoryData = 
{
    keyboardData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.BATTLEGROUNDS,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_battlegrounds_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_battlegrounds_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_battlegrounds_over.dds",
        disabledIcon = "EsoUI/Art/LFG/LFG_indexIcon_battlegrounds_disabled.dds",
    },
    gamepadData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.BATTLEGROUNDS,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
        menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_battlegrounds.dds",
        disabledMenuIcon = "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_battlegrounds_disabled.dds",
        sceneName = "gamepadBattlegroundFinder",
        tooltipDescription = GetString(SI_GAMEPAD_ACTIVITY_FINDER_TOOLTIP_BATTLEGROUNDS),
    },
}

local BattlegroundFinder_Manager = ZO_ActivityFinderTemplate_Manager:Subclass()

function BattlegroundFinder_Manager:New(...)
    return ZO_ActivityFinderTemplate_Manager.New(self, ...)
end

function BattlegroundFinder_Manager:Initialize()
    local filterModeData = ZO_ActivityFinderFilterModeData:New(LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL, LFG_ACTIVITY_BATTLE_GROUND_CHAMPION, LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION)
    filterModeData:SetSubmenuFilterNames(GetString(SI_BATTLEGROUND_FINDER_SPECIFIC_FILTER_TEXT), GetString(SI_BATTLEGROUND_FINDER_RANDOM_FILTER_TEXT))
    filterModeData:SetVisibleEntryTypes(ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SET)
    ZO_ActivityFinderTemplate_Manager.Initialize(self, "ZO_BattlegroundFinder", categoryData, filterModeData)

    self:SetLockingCooldownTypes(LFG_COOLDOWN_BATTLEGROUND_DESERTED_QUEUE)

    BATTLEGROUND_FINDER_KEYBOARD = self:GetKeyboardObject()
    BATTLEGROUND_FINDER_GAMEPAD = self:GetGamepadObject()
    GAMEPAD_BATTLEGROUND_FINDER_SCENE = BATTLEGROUND_FINDER_GAMEPAD:GetScene()
end

function BattlegroundFinder_Manager:GetCategoryData()
    return categoryData
end

BATTLEGROUND_FINDER_MANAGER = BattlegroundFinder_Manager:New()