local function DetermineButtonState(pressed, enabled)
    if pressed then
        if enabled then
            return BSTATE_PRESSED
        else
            return BSTATE_DISABLED_PRESSED
        end
    else
        if enabled then
            return BSTATE_NORMAL
        else
            return BSTATE_DISABLED
        end
    end
end

local function UpdateVeteranStateVisuals(self, isVeteranDifficulty)
    self.hasControlOfDifficulty, self.difficultyControlReason = CanPlayerChangeGroupDifficulty()

    if self.hasControlOfDifficulty then
        self.normalModeButton:SetHidden(false)
        self.veteranModeButton:SetHidden(false)
        self.difficultyLabel:SetHidden(true)

        local isChampion = CanUnitGainChampionPoints("player")

        --Normal mode button
        local normalButtonPressed = not isVeteranDifficulty
        local normalButtonEnabled = true
        local normalButtonState = DetermineButtonState(normalButtonPressed, normalButtonEnabled)
        local normalButtonLocked = normalButtonPressed --enforce a button always being selected by locking down the pressed one
        self.normalModeButton:SetState(normalButtonState, normalButtonLocked)

        --Veteran mode button
        local veteranButtonPressed = isVeteranDifficulty
        local veteranButtonEnabled = isChampion
        local veteranButtonState = DetermineButtonState(veteranButtonPressed, veteranButtonEnabled)
        local veteranButtonLocked = veteranButtonPressed --enforce a button always being selected by locking down the pressed one
        self.veteranModeButton:SetState(veteranButtonState, veteranButtonLocked)
    else
        self.normalModeButton:SetHidden(true)
        self.veteranModeButton:SetHidden(true)
        self.difficultyLabel:SetHidden(false)

        local dungeonDifficulty = ZO_GetEffectiveDungeonDifficulty()
        local icon = GetKeyboardDungeonDifficultyIcon(dungeonDifficulty)
        local text = GetString("SI_DUNGEONDIFFICULTY", dungeonDifficulty)
        self.difficultyLabel:SetText(zo_iconTextFormat(icon, 32, 32, text))
    end
end

local function UpdateVeteranState(self, isVeteranDifficulty)
    if isVeteranDifficulty == nil then
        isVeteranDifficulty = ZO_GetEffectiveDungeonDifficulty() == DUNGEON_DIFFICULTY_VETERAN
    end

    UpdateVeteranStateVisuals(self, isVeteranDifficulty)
end

function ZO_VeteranDifficultySettings_OnInitialized(self)
    self.normalModeButton = self:GetNamedChild("NormalDifficulty")
    self.veteranModeButton = self:GetNamedChild("VeteranDifficulty")
    self.difficultyLabel = self:GetNamedChild("DifficultyLabel")

    local function Refresh(unitTag)
        if(unitTag == nil or unitTag == "player") then
            UpdateVeteranState(self)
        end
    end

    -- NOTE: There appears to be a bug in the event manager code that is preventing the same function to be registered from the same control for different events...
    -- until that's fixed, split up the handlers.

    local function OnGroupVeteranDifficultyChanged()
        Refresh()
    end

    local function OnChampionPointsChanged(eventId, unitTag, championPoints)
        Refresh(unitTag)
    end

    local function OnPlayerActivated()
        Refresh()
    end

    local function OnLeaderUpdate()
        Refresh()
    end

    local function OnGroupUpdate()
        Refresh()
    end

    local function OnGroupMemberJoined()
        Refresh()
    end

    local function OnGroupMemberLeft()
        Refresh()
    end

    local function OnGroupUpdate()
        Refresh()
    end

    local function OnZoneUpdate(evt, unitTag, newZone)
        if ZO_Group_IsGroupUnitTag(unitTag) or unitTag == "player" then
            Refresh()
        end
    end

    self:RegisterForEvent(EVENT_GROUP_VETERAN_DIFFICULTY_CHANGED, OnGroupVeteranDifficultyChanged)
    self:RegisterForEvent(EVENT_CHAMPION_POINT_UPDATE, OnChampionPointsChanged)
    self:RegisterForEvent(EVENT_LEADER_UPDATE, OnLeaderUpdate)
    self:RegisterForEvent(EVENT_GROUP_UPDATE, OnGroupUpdate)
    self:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    self:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
    self:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    self:RegisterForEvent(EVENT_ZONE_UPDATE, OnZoneUpdate)

    Refresh()
end

function ZO_VeteranDifficultyButton_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, GetString("SI_DUNGEONDIFFICULTY", self.dungeonDifficulty))
end

function ZO_VeteranDifficultyButton_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end

function ZO_VeteranDifficultyButton_OnClicked(self)
    local isVeteranDifficulty = ZO_ConvertToIsVeteranDifficulty(self.dungeonDifficulty)
    SetVeteranDifficulty(isVeteranDifficulty)

    -- Pre-emptive update based on mostly current state, and the desired difficulty setting.
    UpdateVeteranState(self:GetParent(), isVeteranDifficulty)
end

function ZO_VeteranDifficultyHelp_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self, RIGHT, -5, 0)
    local difficultyContainer = self:GetParent()
    local r, g, b
    local SET_TO_FULL_SIZE = true

    if not difficultyContainer.hasControlOfDifficulty then
        r, g, b = ZO_ERROR_COLOR:UnpackRGB()
    else
        r, g, b = ZO_SUCCEEDED_TEXT:UnpackRGB()
    end
    InformationTooltip:AddLine(GetString("SI_GROUPDIFFICULTYCHANGEREASON", difficultyContainer.difficultyControlReason), "", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)

    r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
    InformationTooltip:AddLine(GetString(SI_DUNGEON_DIFFICULTY_HELP_TOOLTIP), "", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)
end

function ZO_VeteranDifficultyHelp_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end