ZO_GAMEPAD_LFG_OPTION_INFO =
{
    [LFG_ROLE_DPS] =
    {
        optionName = GetString("SI_LFGROLE", LFG_ROLE_DPS),
        iconUp = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps_up.dds",
        iconDown = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps_down.dds",
        role = LFG_ROLE_DPS,
        tooltip = GetString(SI_GROUP_PREFERRED_ROLE_DPS_TOOLTIP),
        narrationText = function()
            local selectedRole = GetSelectedLFGRole()
            return ZO_FormatRadioButtonNarrationText(GetString("SI_LFGROLE", LFG_ROLE_DPS), selectedRole == LFG_ROLE_DPS, GetString(SI_GAMEPAD_GROUP_PREFERRED_ROLES_HEADER))
        end,
    },

    [LFG_ROLE_HEAL] =
    {
        optionName = GetString("SI_LFGROLE", LFG_ROLE_HEAL),
        iconUp = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer_up.dds",
        iconDown = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer_down.dds",
        role = LFG_ROLE_HEAL,
        tooltip = GetString(SI_GROUP_PREFERRED_ROLE_HEAL_TOOLTIP),
        narrationText = function()
            local selectedRole = GetSelectedLFGRole()
            return ZO_FormatRadioButtonNarrationText(GetString("SI_LFGROLE", LFG_ROLE_HEAL), selectedRole == LFG_ROLE_HEAL, GetString(SI_GAMEPAD_GROUP_PREFERRED_ROLES_HEADER))
        end,
    },

    [LFG_ROLE_TANK] =
    {
        optionName = GetString("SI_LFGROLE", LFG_ROLE_TANK),
        iconUp = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank_up.dds",
        iconDown = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank_down.dds",
        role = LFG_ROLE_TANK,
        tooltip = GetString(SI_GROUP_PREFERRED_ROLE_TANK_TOOLTIP),
        narrationText = function()
            local selectedRole = GetSelectedLFGRole()
            return ZO_FormatRadioButtonNarrationText(GetString("SI_LFGROLE", LFG_ROLE_TANK), selectedRole == LFG_ROLE_TANK, GetString(SI_GAMEPAD_GROUP_PREFERRED_ROLES_HEADER))
        end,
    },
}

ZO_GAMEPAD_ROLES_BAR_BUTTON_DIMENSIONS = 64
ZO_GAMEPAD_ROLES_BAR_HEADER_BUTTONS_PADDING_Y = 40
local ROLES_HEADER_HEIGHT = 24
ZO_GAMEPAD_ROLES_BAR_ADDITIONAL_HEADER_SPACE = ROLES_HEADER_HEIGHT + ZO_GAMEPAD_ROLES_BAR_HEADER_BUTTONS_PADDING_Y + ZO_GAMEPAD_ROLES_BAR_BUTTON_DIMENSIONS

--------------------------------------------
-- GroupRolesBarGamepad Gamepad
--------------------------------------------

ZO_GroupRolesBar_Gamepad = ZO_GamepadButtonTabBar:Subclass()

function ZO_GroupRolesBar_Gamepad:Initialize(control)
    local function OnSelected(buttonControl)
        buttonControl.selectedFrame:SetHidden(false)
        
        local roleData = buttonControl.data
        local roleType = roleData.role
        local lowestAverage = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetAverageRoleTime(roleType)
        GAMEPAD_TOOLTIPS:LayoutGroupRole(GAMEPAD_LEFT_TOOLTIP, roleData.optionName, roleData.tooltip, lowestAverage)
    end

    local function OnUnselected(buttonControl)
        buttonControl.selectedFrame:SetHidden(true)
    end

    local function OnPressed(buttonControl)
        UpdateSelectedLFGRole(buttonControl.data.role)
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:UpdateLocationData()
        self:RefreshRoles()
        SCREEN_NARRATION_MANAGER:QueueGamepadButtonTabBar(self)
    end

    ZO_GamepadButtonTabBar.Initialize(self, control, OnSelected, OnUnselected, OnPressed)

    self.roleControls =
    {
        [LFG_ROLE_TANK] = control:GetNamedChild("Tank"),
        [LFG_ROLE_HEAL] = control:GetNamedChild("Healer"),
        [LFG_ROLE_DPS] = control:GetNamedChild("DPS"),
    }

    self:AddButton(self.roleControls[LFG_ROLE_TANK], ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_TANK])
    self:AddButton(self.roleControls[LFG_ROLE_HEAL], ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_HEAL])
    self:AddButton(self.roleControls[LFG_ROLE_DPS], ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_DPS])

    self:RefreshRoles()

    --The fragment needs to be manually added and removed for the animation to work between the two group scenes
    GAMEPAD_GROUP_ROLES_FRAGMENT = ZO_ConveyorSceneFragment:New(ZO_GroupRolesBarGamepadMaskContainer, ZO_Anchor:New(TOPLEFT, nil, TOPLEFT))
    GAMEPAD_GROUP_ROLES_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshRoles()
        elseif newState == SCENE_HIDDEN then
            self:Deactivate()
        end
    end)
    GAMEPAD_GROUP_ROLES_FRAGMENT:SetForceRefresh(true)

    self.isManuallyDimmed = false

    self:InitializeEvents()
end

function ZO_GroupRolesBar_Gamepad:InitializeEvents()
    local function OnActivityFinderStatusUpdate(status)
        self:UpdateEnabledState()
    end
    
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", OnActivityFinderStatusUpdate)
end

function ZO_GroupRolesBar_Gamepad:ToggleSelected()
    if self.selectedIndex and self.canUpdateSelectedLFGRole then
        local selectedButton = self.buttons[self.selectedIndex]
        self.onPressedCallback(selectedButton)
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_GroupRolesBar_Gamepad:SetRoleSelected(roleType, isSelected)
    local roleControl = self.roleControls[roleType]
    local roleData = roleControl.data
    roleControl.icon:SetTexture(isSelected and roleData.iconDown or roleData.iconUp)
    roleControl.pressedFrame:SetHidden(not isSelected)
end

function ZO_GroupRolesBar_Gamepad:RefreshRoles()
    local selectedRole = GetSelectedLFGRole()
    for roleType, _ in pairs(self.roleControls) do
        self:SetRoleSelected(roleType, roleType == selectedRole)
    end
    self:UpdateEnabledState()
end

function ZO_GroupRolesBar_Gamepad:UpdateEnabledState()
    self.canUpdateSelectedLFGRole = CanUpdateSelectedLFGRole()
    self:UpdateDimming()
end

function ZO_GroupRolesBar_Gamepad:SetIsManuallyDimmed(isDimmed)
    self.isManuallyDimmed = isDimmed
    self:UpdateDimming()
end

function ZO_GroupRolesBar_Gamepad:UpdateDimming()
    local isDimmed = not self.canUpdateSelectedLFGRole or self.isManuallyDimmed
    local alpha = isDimmed and ZO_GAMEPAD_ICON_UNSELECTED_ALPHA or ZO_GAMEPAD_ICON_SELECTED_ALPHA

    for _, roleControl in pairs(self.roleControls) do
        roleControl:SetAlpha(alpha)
    end
end

-- Static function to be used by list screens that show the group roles bar
function ZO_GroupRolesBar_Gamepad:SetupListAnchorsBelowGroupBar(listControl)
    local _, point1, relativeTo1, relativePoint1, offsetX1, offsetY1 = listControl:GetAnchor(0)
    listControl:SetAnchor(point1, relativeTo1, relativePoint1, offsetX1, offsetY1 + ZO_GAMEPAD_ROLES_BAR_ADDITIONAL_HEADER_SPACE)
end

--ZO_GamepadButtonTabBar Overrides
function ZO_GroupRolesBar_Gamepad:Deactivate()
    if self:IsActivated() then
        ZO_GamepadButtonTabBar.Deactivate(self)
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    end
end

--XML Calls
function ZO_GroupRolesBar_Gamepad_OnInitialized(control)
    GAMEPAD_GROUP_ROLES_BAR = ZO_GroupRolesBar_Gamepad:New(control)
end