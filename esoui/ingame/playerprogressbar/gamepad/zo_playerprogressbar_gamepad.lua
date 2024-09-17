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

function ZO_GamepadPlayerProgressBarNameLocation:GetNarration()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject( zo_strformat(SI_GAMEPAD_CHARACTER_FOOTER_NARRATION_NAME_FORMATTER, self.username:GetText())))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject( zo_strformat(SI_GAMEPAD_CHARACTER_FOOTER_NARRATION_LOCATION_FORMATTER, self.location:GetText())))

    local levelTitleText = PLAYER_PROGRESS_BAR.levelTypeLabel:GetText() or PLAYER_PROGRESS_BAR.championPointsLabel:GetText()
    local level, current, levelSize = PLAYER_PROGRESS_BAR:GetMostRecentlyShownInfo()

    local showLevel = level
    -- We are showing the reward for the next level, so advance by one.
    if GetNumChampionXPInChampionPoint(showLevel) ~= nil then
        showLevel = showLevel + 1
    end
    local nextPointPoolType = GetChampionPointPoolForRank(showLevel)
    local swappedSkillLines = GetChampionDisciplineId(nextPointPoolType + 1)
    local discipline = GetChampionDisciplineName(swappedSkillLines)

    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_CHARACTER_FOOTER_NARRATION_PROGRESSION_FORMATTER, levelTitleText, level, discipline, math.floor(current / levelSize * 100))))

    return narrations
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
