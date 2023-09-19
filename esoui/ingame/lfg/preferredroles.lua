--------------------------------------
--Preferred Roles Manager
--------------------------------------
local PreferredRolesManager = ZO_InitializingCallbackObject:Subclass()

function PreferredRolesManager:Initialize(control)
    self.control = control

    self:InitializeRoles()

    local function OnActivityFinderStatusUpdate()
        self:RefreshRadioButtonGroupEnabledState()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", OnActivityFinderStatusUpdate)
end

function PreferredRolesManager:InitializeRoles()
    self.roleButtons =
    {
        [LFG_ROLE_DPS] = self.control:GetNamedChild("ButtonsDPS"),
        [LFG_ROLE_HEAL] = self.control:GetNamedChild("ButtonsHeal"),
        [LFG_ROLE_TANK] = self.control:GetNamedChild("ButtonsTank"),
    }

    self.radioButtonGroup = ZO_RadioButtonGroup:New()
    for roleType, roleButton in pairs(self.roleButtons) do
        self.radioButtonGroup:Add(roleButton)
    end

    local onClickHandler = function(control, buttonId, ignoreCallback)
        local clickHandled = false
        local selectedRole = GetSelectedLFGRole()
        if selectedRole ~= control.role and DoesGroupFinderUserTypeGroupListingEnforceRoles(GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING) then
            local dialogData =
            {
                title = GetString(SI_GROUP_FINDER_CHANGE_ROLE_WARNING_DIALOG_TITLE),
                mainText = GetString(SI_GROUP_FINDER_CHANGE_ROLE_WARNING_DIALOG_TEXT),
                onConfirmCallback = function()
                    RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_RESCIND)
                    self.radioButtonGroup:HandleClick(control, buttonId, ignoreCallback)
                end,
            }

            ZO_Dialogs_ShowDialog("RADIO_BUTTON_GROUP_CHANGE_SELECTION_CONFIRMATION", dialogData)
            clickHandled = true
        end

        return clickHandled
    end

    self.radioButtonGroup:SetCustomClickHandler(onClickHandler)
    self.radioButtonGroup:SetSelectionChangedCallback(function(_, ...) self:OnRoleButtonSelectionChanged(...) end)

    self:RefreshRoles()
end

function PreferredRolesManager:RefreshRoles()
    local IGNORE_CALLBACK = true
    self.radioButtonGroup:SetClickedButton(self.roleButtons[GetSelectedLFGRole()], IGNORE_CALLBACK)

    self:RefreshRadioButtonGroupEnabledState()
end

function PreferredRolesManager:RefreshRadioButtonGroupEnabledState()
    local isGroupFinderInCreateEdit = GROUP_FINDER_KEYBOARD and GROUP_FINDER_KEYBOARD.mode == ZO_GROUP_FINDER_MODES.CREATE_EDIT or false
    local canUpdateSelectedLFGRole = CanUpdateSelectedLFGRole() and not isGroupFinderInCreateEdit
    self.radioButtonGroup:SetEnabled(canUpdateSelectedLFGRole)
end

function PreferredRolesManager:OnRoleButtonSelectionChanged(newButton, previousButton)
    UpdateSelectedLFGRole(newButton.role)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:UpdateLocationData()
    GROUP_FINDER_KEYBOARD.applicationsManagementContent:RefreshListing()
    self:FireCallbacks("LFGRoleChanged")
end

---- XML Callbacks ----

function ZO_PreferredRolesButton_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    InformationTooltip:AddLine(GetString("SI_LFGROLE", control.role), "", r, g, b)
    InformationTooltip:AddLine(control.tooltipString, "", r, g, b)
    InformationTooltip:AddLine(GetString(SI_GROUP_PREFERRED_ROLE_DESCRIPTION), "", r, g, b)
    local lowestAverage = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetAverageRoleTime(control.role)
    if lowestAverage > 0 then
        local textLowestAverageTime = ZO_GetSimplifiedTimeEstimateText(lowestAverage * 1000)
        InformationTooltip:AddLine(zo_strformat(SI_ACTIVITY_FINDER_DUNGEON_AVERAGE_ROLE_TIME_FORMAT, textLowestAverageTime), "", r, g, b) 
    end

    local currentState = control:GetState()
    if currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED then
        InformationTooltip:AddLine(GetString(SI_GROUP_LIST_PANEL_DISABLED_ROLE_TOOLTIP), "", ZO_ColorDef:New("ff0000"):UnpackRGB())
    end
end

function ZO_PreferredRolesButton_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

do
    local ROLE_NAME_LOOKUP =
    {
        [LFG_ROLE_TANK] = "tank",
        [LFG_ROLE_HEAL] = "healer",
        [LFG_ROLE_DPS] = "dps",
    }

    local TOOLTIP_STRING_LOOKUP =
    {
        [LFG_ROLE_TANK] = GetString(SI_GROUP_PREFERRED_ROLE_TANK_TOOLTIP),
        [LFG_ROLE_HEAL] = GetString(SI_GROUP_PREFERRED_ROLE_HEAL_TOOLTIP),
        [LFG_ROLE_DPS] = GetString(SI_GROUP_PREFERRED_ROLE_DPS_TOOLTIP),
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
        control.tooltipString = TOOLTIP_STRING_LOOKUP[role]
    end
end

function ZO_PreferredRoles_OnInitialized(self)
    PREFERRED_ROLES = PreferredRolesManager:New(self)
end