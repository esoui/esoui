local categoryData = 
{
    keyboardData =
    {
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_ALLIANCE_WAR),
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_allianceWar_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_allianceWar_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_allianceWar_over.dds",
    },

    gamepadData =
    {
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_ALLIANCE_WAR),
        menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_ava.dds",
        sceneName = "gamepadAvAFinder",
        tooltipDescription = GetString(SI_GAMEPAD_ACTIVITY_FINDER_TOOLTIP_ALLIANCE_WAR),
    }
}

local AllianceWarFinder_Manager = ZO_ActivityFinderTemplate_Manager:Subclass()

function AllianceWarFinder_Manager:New(...)
    return ZO_ActivityFinderTemplate_Manager.New(self, ...)
end

function AllianceWarFinder_Manager:Initialize()
    local filterModeData = ZO_ActivityFinderFilterModeData:New(LFG_ACTIVITY_AVA)
    ZO_ActivityFinderTemplate_Manager.Initialize(self, "ZO_AllianceWarFinder", categoryData, filterModeData)

    ALLIANCE_WAR_FINDER_KEYBOARD = self:GetKeyboardObject()
    ALLIANCE_WAR_FINDER_GAMEPAD = self:GetGamepadObject()
    GAMEPAD_ALLIANCE_WAR_FINDER_SCENE = ALLIANCE_WAR_FINDER_GAMEPAD:GetScene()
end

ALLIANCE_WAR_FINDER_MANAGER = AllianceWarFinder_Manager:New()