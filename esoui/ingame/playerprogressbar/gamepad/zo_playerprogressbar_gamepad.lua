--[[ Gamepad Player Process Bar Name Location Hide on HUD Fragment ]]--

ZO_GamepadPlayerProgressBarHideNameLocationFragment = ZO_SceneFragment:Subclass()

function ZO_GamepadPlayerProgressBarHideNameLocationFragment:New(...)
    local fragment = ZO_SceneFragment.New(self)
    return fragment
end

function ZO_GamepadPlayerProgressBarHideNameLocationFragment:Show()
    GAMEPAD_PLAYER_PROGRESS_BAR_NAME_LOCATION.control:SetHidden(true)
    self:OnShown()
end

function ZO_GamepadPlayerProgressBarHideNameLocationFragment:Hide()
    if IsInGamepadPreferredMode() then
        GAMEPAD_PLAYER_PROGRESS_BAR_NAME_LOCATION.control:SetHidden(false)
        GAMEPAD_PLAYER_PROGRESS_BAR_NAME_LOCATION:Refresh()
    end
    self:OnHidden()
end

ZO_GamepadPlayerProgressBarNameLocation = ZO_Object:Subclass()

function ZO_GamepadPlayerProgressBarNameLocation:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadPlayerProgressBarNameLocation:Initialize(control)
    self.control = control
    
    self.location = control:GetNamedChild("Location")
    self.locationHeader = control:GetNamedChild("LocationHeader")
    self.username = control:GetNamedChild("UserName")
    self.usernameHeader = control:GetNamedChild("UserNameHeader")
end

function ZO_GamepadPlayerProgressBarNameLocation:Refresh()
    self.username:SetText(GetUnitName("player"))

    local zoneName = GetPlayerLocationName()
    if(zoneName == "") then
        zoneName = GetString(SI_GAMEPAD_PLAYER_PROGERSS_BAR_UNKNOWN_ZONE)
    else
        zoneName = zo_strformat(SI_WINDOW_TITLE_WORLD_MAP, zoneName)
    end
    self.location:SetText(zoneName)
end

function ZO_GamepadPlayerProgressBarNameLocation_OnInitialized(control)
    GAMEPAD_PLAYER_PROGRESS_BAR_NAME_LOCATION = ZO_GamepadPlayerProgressBarNameLocation:New(control)
end

function ZO_GamepadPlayerProgressBarNameLocationAnchor_Initialize(nameLocation, progressBar)
    local anchor = ZO_Anchor:New(BOTTOMRIGHT, progressBar.championIcon, BOTTOMLEFT, 8, 0)

    local control = nameLocation.control
    local fragment = ZO_AnchorSceneFragment:New(control, anchor)

    nameLocation.control:SetParent(progressBar.control)

    return fragment
end
