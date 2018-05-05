ZO_GAMEPAD_LFG_OPTION_INFO =
{
    [LFG_ROLE_DPS] =
    {
        optionName = GetString("SI_LFGROLE", LFG_ROLE_DPS),
        iconUp = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps_up.dds",
        iconDown = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps_down.dds",
        role = LFG_ROLE_DPS,
        tooltip = GetString(SI_GROUP_PREFERRED_ROLE_DPS_TOOLTIP),
    },

    [LFG_ROLE_HEAL] =
    {
        optionName = GetString("SI_LFGROLE", LFG_ROLE_HEAL),
        iconUp = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer_up.dds",
        iconDown = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer_down.dds",
        role = LFG_ROLE_HEAL,
        tooltip = GetString(SI_GROUP_PREFERRED_ROLE_HEAL_TOOLTIP),
    },

    [LFG_ROLE_TANK] =
    {
        optionName = GetString("SI_LFGROLE", LFG_ROLE_TANK),
        iconUp = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank_up.dds",
        iconDown = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank_down.dds",
        role = LFG_ROLE_TANK,
        tooltip = GetString(SI_GROUP_PREFERRED_ROLE_TANK_TOOLTIP),
    },
}

ZO_GAMEPAD_ROLES_BAR_BUTTON_DIMENSIONS = 64
ZO_GAMEPAD_ROLES_BAR_HEADER_BUTTONS_PADDING_Y = 40
local ROLES_HEADER_HEIGHT = 24
ZO_GAMEPAD_ROLES_BAR_ADDITIONAL_HEADER_SPACE = ROLES_HEADER_HEIGHT + ZO_GAMEPAD_ROLES_BAR_HEADER_BUTTONS_PADDING_Y + ZO_GAMEPAD_ROLES_BAR_BUTTON_DIMENSIONS

--------------------------------------------
-- GroupRolesBarGamepad Gamepad
--------------------------------------------

local ZO_GroupRolesBar_Gamepad = ZO_GamepadButtonTabBar:Subclass()

function ZO_GroupRolesBar_Gamepad:New(...)
    return ZO_GamepadButtonTabBar.New(self, ...)
end

function ZO_GroupRolesBar_Gamepad:Initialize(control)
    local function OnSelected(control)
        control.selectedFrame:SetHidden(false)
        
        local roleType = control.data.role
        local roleData = ZO_GAMEPAD_LFG_OPTION_INFO[roleType]
        local lowestAverage = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetAverageRoleTime(roleType)
        GAMEPAD_TOOLTIPS:LayoutGroupRole(GAMEPAD_LEFT_TOOLTIP, roleData.optionName, roleData.tooltip, lowestAverage)
    end
    local function OnUnselected(control)
        control.selectedFrame:SetHidden(true)
    end
    local function OnPressed(control)
        local roleType = control.data.role
        local isSelected = not self.roles[roleType].isSelected
        UpdatePlayerRole(roleType, isSelected)
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:UpdateLocationData()
        self:RefreshRoles()
    end

    ZO_GamepadButtonTabBar.Initialize(self, control, OnSelected, OnUnselected, OnPressed)

    local tankControl = control:GetNamedChild("Tank")
    local healerControl = control:GetNamedChild("Healer")
    local dpsControl = control:GetNamedChild("DPS")
    self.roles = {
        [LFG_ROLE_TANK] = {button = tankControl},
        [LFG_ROLE_HEAL] = {button = healerControl},
        [LFG_ROLE_DPS] = {button = dpsControl},
    }
    self:AddButton(tankControl, ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_TANK])
    self:AddButton(healerControl, ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_HEAL])
    self:AddButton(dpsControl, ZO_GAMEPAD_LFG_OPTION_INFO[LFG_ROLE_DPS])

    self:RefreshRoles()

    --The fragment needs to be manually added and removed for the animation to work between the two group scenes
    GAMEPAD_GROUP_ROLES_FRAGMENT = ZO_ConveyorSceneFragment:New(ZO_GroupRolesBarGamepadMaskContainer, ZO_Anchor:New(TOPLEFT, nil, TOPLEFT))
    GAMEPAD_GROUP_ROLES_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
	    if newState == SCENE_FRAGMENT_SHOWING then
	 	    self:RefreshRoles()
        elseif(newState == SCENE_HIDDEN) then
            self:Deactivate()
	    end
    end)
    GAMEPAD_GROUP_ROLES_FRAGMENT:SetForceRefresh(true)

    self.isManuallyDimmed = false

    self:InitializeEvents()
end

function ZO_GroupRolesBar_Gamepad:InitializeEvents()
    local function OnActivityFinderStatusUpdate(status)
        self.isLockedFromSearch = status == ACTIVITY_FINDER_STATUS_QUEUED
        self:UpdateDimming()
    end
    
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", OnActivityFinderStatusUpdate)
end

function ZO_GroupRolesBar_Gamepad:ToggleSelected()
    if self.selectedIndex and not self.isLockedFromSearch then
        local selectedButton = self.buttons[self.selectedIndex]
        self.onPressedCallback(selectedButton)
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_GroupRolesBar_Gamepad:SetRoleSelected(roleType, isSelected)
    local role = self.roles[roleType]
    local button = role.button

    role.isSelected = isSelected
    local roleData = ZO_GAMEPAD_LFG_OPTION_INFO[roleType]
    button.icon:SetTexture(isSelected and roleData.iconDown or roleData.iconUp)
    button.pressedFrame:SetHidden(not isSelected)
end

function ZO_GroupRolesBar_Gamepad:RefreshRoles()
    local isDPS, isHeal, isTank = GetPlayerRoles()

    self:SetRoleSelected(LFG_ROLE_DPS, isDPS)
    self:SetRoleSelected(LFG_ROLE_HEAL, isHeal)
    self:SetRoleSelected(LFG_ROLE_TANK, isTank)
end

function ZO_GroupRolesBar_Gamepad:SetIsManuallyDimmed(isDimmed)
    self.isManuallyDimmed = isDimmed
    self:UpdateDimming()
end

function ZO_GroupRolesBar_Gamepad:UpdateDimming()
    local isDimmed = self.isLockedFromSearch or self.isManuallyDimmed
    local alpha = isDimmed and ZO_GAMEPAD_ICON_UNSELECTED_ALPHA or ZO_GAMEPAD_ICON_SELECTED_ALPHA

    for roleType, data in pairs(self.roles) do
        data.button:SetAlpha(alpha)
    end
end

function ZO_GroupRolesBar_Gamepad:GetRoles()
    local roles = self.roles
    return {
        [LFG_ROLE_DPS] = roles[LFG_ROLE_DPS].isSelected,
        [LFG_ROLE_HEAL] = roles[LFG_ROLE_HEAL].isSelected,
        [LFG_ROLE_TANK] = roles[LFG_ROLE_TANK].isSelected,
    }
end

function ZO_GroupRolesBar_Gamepad:IsRoleSelected()
    local roles = self.roles
    return roles[LFG_ROLE_DPS].isSelected or roles[LFG_ROLE_HEAL].isSelected or roles[LFG_ROLE_TANK].isSelected
end

--ZO_GamepadButtonTabBar Overrides
function ZO_GroupRolesBar_Gamepad:Activate()
    ZO_GamepadButtonTabBar.Activate(self)
end

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