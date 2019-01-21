local categoryData = 
{
    keyboardData =
    {
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_dungeon_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_dungeon_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_dungeon_over.dds",
    },

    gamepadData =
    {
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
        menuIcon = "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_Dungeon.dds",
        sceneName = "gamepadDungeonFinder",
        tooltipDescription = GetString(SI_GAMEPAD_ACTIVITY_FINDER_TOOLTIP_DUNGEON_FINDER),
    },
    priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.DUNGEONS
}

local DungeonFinder_Manager = ZO_ActivityFinderTemplate_Manager:Subclass()

function DungeonFinder_Manager:New(...)
    return ZO_ActivityFinderTemplate_Manager.New(self, ...)
end

function DungeonFinder_Manager:Initialize()
    local filterModeData = ZO_ActivityFinderFilterModeData:New(LFG_ACTIVITY_DUNGEON, LFG_ACTIVITY_MASTER_DUNGEON)
    filterModeData:SetSubmenuFilterNames(GetString(SI_DUNGEON_FINDER_SPECIFIC_FILTER_TEXT), GetString(SI_DUNGEON_FINDER_RANDOM_FILTER_TEXT))
    ZO_ActivityFinderTemplate_Manager.Initialize(self, "ZO_DungeonFinder", categoryData, filterModeData)

    self:SetLockingCooldownTypes(LFG_COOLDOWN_ACTIVITY_STARTED)

    DUNGEON_FINDER_KEYBOARD = self:GetKeyboardObject()
    DUNGEON_FINDER_GAMEPAD = self:GetGamepadObject()
    GAMEPAD_DUNGEON_FINDER_SCENE = DUNGEON_FINDER_GAMEPAD:GetScene()
end

DUNGEON_FINDER_MANAGER = DungeonFinder_Manager:New()