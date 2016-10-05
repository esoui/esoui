local USER_REQUESTED = true
local SYSTEM_REQUESTED = false

--------------------------------------
--Preferred Roles Manager
--------------------------------------
local PreferredRolesManager = ZO_Object:Subclass()

function PreferredRolesManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function PreferredRolesManager:Initialize(control)
    self.control = control
    self:InitializeRoles()

    local function OnActivityFinderStatusUpdate(status)
        self:DisableRoleButtons(status == ACTIVITY_FINDER_STATUS_QUEUED)
    end
    
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", OnActivityFinderStatusUpdate)
end

function PreferredRolesManager:InitializeRoles()
    local isDPS, isHeal, isTank = GetPlayerRoles()
    self.roles = {
        [LFG_ROLE_DPS] = {
            button = self.control:GetNamedChild("ButtonsDPS"),
            isSelected = isDPS,
            tooltip = GetString(SI_GROUP_PREFERRED_ROLE_DPS_TOOLTIP),
        },
        [LFG_ROLE_HEAL] = {
            button = self.control:GetNamedChild("ButtonsHeal"),
            isSelected = isHeal,
            tooltip = GetString(SI_GROUP_PREFERRED_ROLE_HEAL_TOOLTIP),
        },
        [LFG_ROLE_TANK] = {
            button = self.control:GetNamedChild("ButtonsTank"),
            isSelected = isTank,
            tooltip = GetString(SI_GROUP_PREFERRED_ROLE_TANK_TOOLTIP),
        },
    }

    for roleType, roleData in pairs(self.roles) do
        if roleData.isSelected then
            ZO_CheckButton_SetChecked(roleData.button)
        end
    end
end

function PreferredRolesManager:RefreshRoles()
    local isDPS, isHeal, isTank = GetPlayerRoles()

    self:SetRoleToggled(LFG_ROLE_TANK, isTank, SYSTEM_REQUESTED)
    self:SetRoleToggled(LFG_ROLE_HEAL, isHeal, SYSTEM_REQUESTED)
    self:SetRoleToggled(LFG_ROLE_DPS, isDPS, SYSTEM_REQUESTED)

    self:DisableRoleButtons(IsCurrentlySearchingForGroup())
end

function PreferredRolesManager:SetRoleToggled(role, selected, userRequested)
    self.roles[role].isSelected = selected
    if userRequested then
        PlaySound(selected and SOUNDS.GROUP_ROLE_SELECTED or SOUNDS.GROUP_ROLE_DESELECTED)
        UpdatePlayerRole(role, selected)
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:UpdateLocationData()
    else
        ZO_CheckButton_SetCheckState(self.roles[role].button, selected)
    end
end

function PreferredRolesManager:DisableRoleButtons(isDisabled)
    for roleType, roleData in pairs(self.roles) do

        --Force buttons only half selected (mouse down only) to be unselected before disabling
        if not roleData.isSelected then
            ZO_CheckButton_SetUnchecked(roleData.button, false)
        end

        ZO_CheckButton_SetEnableState(roleData.button, not isDisabled)

        --Force mouse to be enabled on disabled buttons so tooltips still work
        roleData.button:SetMouseEnabled(true)
    end
end

function PreferredRolesManager:GetSelectedRoleCount()
    local count = 0
    for roleType, roleData in pairs(self.roles) do
        if roleData.isSelected then
            count = count + 1
        end
    end

    return count
end

function PreferredRolesManager:GetRoles()
    local roles = self.roles
    return {
        [LFG_ROLE_DPS] = roles[LFG_ROLE_DPS].isSelected,
        [LFG_ROLE_HEAL] = roles[LFG_ROLE_HEAL].isSelected,
        [LFG_ROLE_TANK] = roles[LFG_ROLE_TANK].isSelected,
    }
end

function PreferredRolesManager:IsRoleSelected()
    local roles = self.roles
    return roles[LFG_ROLE_DPS].isSelected or roles[LFG_ROLE_HEAL].isSelected or roles[LFG_ROLE_TANK].isSelected
end

---- XML Callbacks ----

function ZO_PreferredRolesButton_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    InformationTooltip:AddLine(GetString("SI_LFGROLE", control.role), "", r, g, b)
    InformationTooltip:AddLine(PREFERRED_ROLES.roles[control.role].tooltip, "", r, g, b)
    InformationTooltip:AddLine(GetString(SI_GROUP_PREFERRED_ROLE_DESCRIPTION), "", r, g, b)
    local lowestAverage = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetAverageRoleTime(control.role)
    if lowestAverage > 0 then
        local textLowestAverageTime = ZO_GetSimplifiedTimeEstimateText(lowestAverage * 1000)
        InformationTooltip:AddLine(zo_strformat(SI_ACTIVITY_FINDER_DUNGEON_AVERAGE_ROLE_TIME_FORMAT, textLowestAverageTime), "", r, g, b) 
    end

    local currentState = control:GetState()
    if currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED then
        InformationTooltip:AddLine(zo_strformat(SI_GROUP_LIST_PANEL_DISABLED_ROLE_TOOLTIP, tooltipText), "", ZO_ColorDef:New("ff0000"):UnpackRGB())
    end
end

function ZO_PreferredRolesButton_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_PreferredRolesButton_OnClicked(buttonControl, mouseButton)
    local buttonState = buttonControl:GetState()
    local role = buttonControl.role

    local toggleCheckOn = buttonState == BSTATE_NORMAL
    if toggleCheckOn or PREFERRED_ROLES:GetSelectedRoleCount() > 1 then --enforce having at least one role selected
        ZO_CheckButton_SetCheckState(buttonControl, toggleCheckOn)
        PREFERRED_ROLES:SetRoleToggled(role, toggleCheckOn, USER_REQUESTED)
    end
end

do
    local ROLE_NAME_LOOKUP =
    {
        [LFG_ROLE_TANK] = "tank",
        [LFG_ROLE_HEAL] = "healer",
        [LFG_ROLE_DPS] = "dps",
    }

    function ZO_PreferredRoleButton_OnInitialized(control, role)
        local roleName = ROLE_NAME_LOOKUP[role]
        control:SetNormalTexture(string.format("EsoUI/Art/LFG/LFG_%s_up_64.dds", roleName))
        control:SetPressedTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_64.dds", roleName))
        control:SetMouseOverTexture(string.format("EsoUI/Art/LFG/LFG_%s_over_64.dds", roleName))
        control:SetPressedMouseOverTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_over_64.dds", roleName))
        control:SetDisabledTexture(string.format("EsoUI/Art/LFG/LFG_%s_disabled_64.dds", roleName))
        control:SetDisabledPressedTexture(string.format("EsoUI/Art/LFG/LFG_%s_down_disabled_64.dds", roleName))
        control.role = role
    end
end

function ZO_PreferredRoles_OnInitialized(self)
    PREFERRED_ROLES = PreferredRolesManager:New(self)
end