local categoryData =
{
    keyboardData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.TRIBUTE,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_TRIBUTE),
        normalIcon = ZO_TRIBUTE_ICONS_KEYBOARD.up,
        pressedIcon = ZO_TRIBUTE_ICONS_KEYBOARD.down,
        mouseoverIcon = ZO_TRIBUTE_ICONS_KEYBOARD.over,
        disabledIcon = ZO_TRIBUTE_ICONS_KEYBOARD.disabled,
        isTribute = true,
    },

    gamepadData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.TRIBUTE,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_TRIBUTE),
        menuIcon = ZO_TRIBUTE_ICONS_GAMEPAD.normal,
        disabledMenuIcon = ZO_TRIBUTE_ICONS_GAMEPAD.disabled,
        sceneName = "gamepadTributeFinder",
        tooltipDescription = GetString(SI_GAMEPAD_ACTIVITY_FINDER_TOOLTIP_TRIBUTE),
        hideGroupRoles = true,
        isTribute = true,
    }
}

ZO_TributeFinder_Manager = ZO_ActivityFinderTemplate_Manager:Subclass()

function ZO_TributeFinder_Manager:New(...)
    return ZO_ActivityFinderTemplate_Manager.New(self, ...)
end

function ZO_TributeFinder_Manager:Initialize()
    local filterModeData = ZO_ActivityFinderFilterModeData:New(LFG_ACTIVITY_TRIBUTE_COMPETITIVE, LFG_ACTIVITY_TRIBUTE_CASUAL)
    -- Tribute will always use random so we only need the "Tales of Tribute" header
    filterModeData:SetSubmenuFilterNames(GetString(SI_ACTIVITY_FINDER_CATEGORY_TRIBUTE), GetString(SI_ACTIVITY_FINDER_CATEGORY_TRIBUTE))
    filterModeData:SetVisibleEntryTypes(ZO_ACTIVITY_FINDER_LOCATION_ENTRY_TYPE.SET)
    ZO_ActivityFinderTemplate_Manager.Initialize(self, "ZO_TributeFinder", categoryData, filterModeData)

    self:SetLockingCooldownTypes(LFG_COOLDOWN_TRIBUTE_DESERTED)

    TRIBUTE_FINDER_KEYBOARD = self:GetKeyboardObject()
    TRIBUTE_FINDER_GAMEPAD = self:GetGamepadObject()
    GAMEPAD_TRIBUTE_FINDER_SCENE = TRIBUTE_FINDER_GAMEPAD:GetScene()
end

function ZO_TributeFinder_Manager:GetCategoryData()
    return categoryData
end

TRIBUTE_FINDER_MANAGER = ZO_TributeFinder_Manager:New()