local categoryData = 
{
    keyboardData =
    {
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_HOME_SHOW),
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_homeShow_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_homeShow_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_homeShow_over.dds",
    },

    gamepadData =
    {
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_HOME_SHOW),
        menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_homeShow.dds",
        sceneName = "gamepadHomeShow",
        tooltipDescription = GetString(SI_GAMEPAD_ACTIVITY_FINDER_TOOLTIP_HOME_SHOW),
    }
}

local HomeShow_Manager = ZO_ActivityFinderTemplate_Manager:Subclass()

function HomeShow_Manager:New(...)
    return ZO_ActivityFinderTemplate_Manager.New(self, ...)
end

function HomeShow_Manager:Initialize()
    local filterModeData = ZO_ActivityFinderFilterModeData:New(LFG_ACTIVITY_HOME_SHOW)
    ZO_ActivityFinderTemplate_Manager.Initialize(self, "ZO_HomeShow", categoryData, filterModeData)

    HOME_SHOW_KEYBOARD = self:GetKeyboardObject()
    HOME_SHOW_GAMEPAD = self:GetGamepadObject()
    GAMEPAD_HOME_SHOW_SCENE = HOME_SHOW_GAMEPAD:GetScene()
end

HOME_SHOW_FINDER_MANAGER = HomeShow_Manager:New()