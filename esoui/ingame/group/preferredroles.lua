--------------------------------------
--Preferred Roles Manager
--------------------------------------
PREFERRED_ROLES = nil


local PreferredRolesManager = ZO_Object:Subclass()

function PreferredRolesManager:New(control)
    local manager = ZO_Object.New(self)
    
    manager.control = control
    manager:InitializeRoles()

    return manager
end

function PreferredRolesManager:InitializeRoles()
    local isDPS, isHeal, isTank = GetPlayerRoles()
    self.roles = {
        [LFG_ROLE_DPS] = {
            button = self.control:GetNamedChild("ButtonsDPS"),
            isSelected = isDPS,
        },
        [LFG_ROLE_HEAL] = {
            button = self.control:GetNamedChild("ButtonsHeal"),
            isSelected = isHeal,
        },
        [LFG_ROLE_TANK] = {
            button = self.control:GetNamedChild("ButtonsTank"),
            isSelected = isTank,
        },
    }

    for roleType, roleData in pairs(self.roles) do
        if roleData.isSelected then
            ZO_CheckButton_SetChecked(roleData.button)
        end
    end
end

function PreferredRolesManager:SetRoleToggled(role, selected)
    self.roles[role].isSelected = selected
    PlaySound(selected and SOUNDS.GROUP_ROLE_SELECTED or SOUNDS.GROUP_ROLE_DESELECTED)
    UpdatePlayerRole(role, selected)
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


---- XML Callbacks ----
function ZO_PreferredRolesHelp_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0)
    SetTooltipText(InformationTooltip, GetString(SI_GROUP_LIST_PANEL_PREFERRED_ROLE_TOOLTIP))
end

function ZO_PreferredRolesHelp_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_PreferredRolesButton_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, GetString("SI_LFGROLE", control.role))
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

    if buttonState == BSTATE_NORMAL then
        ZO_CheckButton_SetChecked(buttonControl)
        PREFERRED_ROLES:SetRoleToggled(role, true)

    elseif buttonState == BSTATE_PRESSED and PREFERRED_ROLES:GetSelectedRoleCount() > 1 then --enforce having at least one role selected
        ZO_CheckButton_SetUnchecked(buttonControl)
        PREFERRED_ROLES:SetRoleToggled(role, false)
    end
end

function ZO_PreferredRoles_OnInitialized(self)
    PREFERRED_ROLES = PreferredRolesManager:New(self)
end