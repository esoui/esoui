local function AddLine(tooltip, text, color, alignment)
    local r, g, b = color:UnpackRGB()
    tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment)
end

local function AddCenterLine(tooltip, text, color)
    AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
end

local function AddLeftLine(tooltip, text, color)
    AddLine(tooltip, text, color, TEXT_ALIGN_LEFT)
end

local function FormatNormalTooltip(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_NORMAL_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
end

local function FormatVeteranTooltip(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
end

local function FormatNormalLeaderMustChange(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_NORMAL_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddLeftLine(tooltip, zo_strformat(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_LEADER_MUST_CHANGE, GetRawUnitName(GetGroupLeaderUnitTag())), ZO_ERROR_COLOR)
end

local function FormatVeteranLeaderMustChange(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddLeftLine(tooltip, zo_strformat(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_LEADER_MUST_CHANGE, GetRawUnitName(GetGroupLeaderUnitTag())), ZO_ERROR_COLOR)
end

local function FormatNormalLeaderHasSetThis(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_NORMAL_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddLeftLine(tooltip, zo_strformat(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_LEADER_CHOSEN_SETTING, GetRawUnitName(GetGroupLeaderUnitTag())), ZO_HIGHLIGHT_TEXT)
end

local function FormatVeteranLeaderHasSetThis(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddLeftLine(tooltip, zo_strformat(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_LEADER_CHOSEN_SETTING, GetRawUnitName(GetGroupLeaderUnitTag())), ZO_HIGHLIGHT_TEXT)
end

local function FormatVeteranDifficultyNonVeteranRankTooltip(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddLeftLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_FAILED_REQUIREMENT), ZO_ERROR_COLOR)
end

local function FormatNormalInDungeonTooltip(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_NORMAL_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_IN_DUNGEON), ZO_ERROR_COLOR)
end

local function FormatVeteranInDungeonTooltip(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_IN_DUNGEON), ZO_ERROR_COLOR)
end

local function FormatNormalInLFGGroupTooltip(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_NORMAL_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_IN_LFG_GROUP), ZO_ERROR_COLOR)
end

local function FormatVeteranInLFGGroupTooltip(tooltip)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_HEADER), ZO_NORMAL_TEXT)
    AddCenterLine(tooltip, GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_IN_LFG_GROUP), ZO_ERROR_COLOR)
end

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
    local isVeteran = GetUnitVeteranRank("player") > 0

    --Hide dungeon mode buttons when not a veteran
    if(not isVeteran) then
        self:SetHidden(true)
        return
    end
    self:SetHidden(false)

    local isGrouped = IsUnitGrouped("player")
    local isLeader = isGrouped and IsUnitGroupLeader("player")
    local isAnyGroupMemberInDungeon = IsAnyGroupMemberInDungeon()
    local isLFGGroup = IsInLFGGroup()

    --Normal mode button
    local normalButtonPressed = not isVeteranDifficulty
    local normalButtonEnabled = not isLFGGroup and not isAnyGroupMemberInDungeon and (not isGrouped or isLeader)
    local normalButtonState = DetermineButtonState(normalButtonPressed, normalButtonEnabled)
    local normalButtonLocked = normalButtonPressed --enforce a button always being selected by locking down the pressed one
    self.normalModeButton:SetState(normalButtonState, normalButtonLocked)

    --Veteran mode button
    local veteranButtonPressed = isVeteranDifficulty
    local veteranButtonEnabled = not isLFGGroup and isVeteran and not isAnyGroupMemberInDungeon and (not isGrouped or isLeader)
    local veteranButtonState = DetermineButtonState(veteranButtonPressed, veteranButtonEnabled)
    local veteranButtonLocked = veteranButtonPressed --enforce a button always being selected by locking down the pressed one
    self.veteranModeButton:SetState(veteranButtonState, veteranButtonLocked)

    --Tooltips
    if isGrouped and not isLeader then
        self.normalModeButtonTooltipFn = isVeteranDifficulty and FormatNormalLeaderMustChange or FormatNormalLeaderHasSetThis
        self.veteranModeButtonTooltipFn = isVeteranDifficulty and FormatVeteranLeaderHasSetThis or FormatVeteranLeaderMustChange
    else
        if isLFGGroup then
            self.normalModeButtonTooltipFn = FormatNormalInLFGGroupTooltip
            self.veteranModeButtonTooltipFn = FormatVeteranInLFGGroupTooltip
        elseif isAnyGroupMemberInDungeon then
            self.normalModeButtonTooltipFn = FormatNormalInDungeonTooltip
            self.veteranModeButtonTooltipFn = FormatVeteranInDungeonTooltip
        else
            self.normalModeButtonTooltipFn = FormatNormalTooltip
            self.veteranModeButtonTooltipFn = isVeteran and FormatVeteranTooltip or FormatVeteranDifficultyNonVeteranRankTooltip
        end
    end
end

local function UpdateVeteranState(self, isVeteranDifficulty)
    if(isVeteranDifficulty == nil) then
        isVeteranDifficulty = IsUnitUsingVeteranDifficulty("player")
    end

    UpdateVeteranStateVisuals(self, isVeteranDifficulty)
end

function ZO_VeteranDifficultySettings_OnInitialized(self)
    self.normalModeButton = self:GetNamedChild("NormalDifficulty")
    self.veteranModeButton = self:GetNamedChild("VeteranDifficulty")

    local function Refresh(unitTag)
        if(unitTag == nil or unitTag == "player") then
            UpdateVeteranState(self)
        end
    end

    -- NOTE: There appears to be a bug in the event manager code that is preventing the same function to be registered from the same control for different events...
    -- until that's fixed, split up the handlers.

    local function OnVeteranDifficultyChanged(eventId, unitTag, isDifficult)
        Refresh(unitTag)
    end

    local function OnVeteranRankChanged(eventId, unitTag, veteranRank)
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

    self:RegisterForEvent(EVENT_VETERAN_DIFFICULTY_CHANGED, OnVeteranDifficultyChanged)
    self:RegisterForEvent(EVENT_VETERAN_RANK_UPDATE, OnVeteranRankChanged)
    self:RegisterForEvent(EVENT_LEADER_UPDATE, OnLeaderUpdate)
    self:RegisterForEvent(EVENT_GROUP_UPDATE, OnGroupUpdate)
    self:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    self:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
    self:RegisterForEvent(EVENT_GROUP_UPDATE, OnGroupUpdate)
    self:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    self:RegisterForEvent(EVENT_ZONE_UPDATE, OnZoneUpdate)

    Refresh()
end

function ZO_VeteranDifficultyButton_OnMouseEnter(self)
    local tooltipFn
    if(self.isVeteranDifficulty) then
        tooltipFn = self:GetParent().veteranModeButtonTooltipFn
    else
        tooltipFn = self:GetParent().normalModeButtonTooltipFn
    end

    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, 0)
    tooltipFn(InformationTooltip)
end

function ZO_VeteranDifficultyButton_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end

function ZO_VeteranDifficultyButton_OnClicked(self)
    SetVeteranDifficulty(self.isVeteranDifficulty)

    -- Pre-emptive update based on mostly current state, and the desired difficulty setting.
    UpdateVeteranState(self:GetParent(), self.isVeteranDifficulty)
end