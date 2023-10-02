local SUPPRESS_CSA = true

local ENDLESS_DUNGEON_COUNTER_TYPE_STATE_VALUE_KEY =
{
    [ENDLESS_DUNGEON_COUNTER_TYPE_STAGE] = "stage",
    [ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE] = "cycle",
    [ENDLESS_DUNGEON_COUNTER_TYPE_ARC] = "arc",
    [ENDLESS_DUNGEON_COUNTER_TYPE_WIPES_REMAINING] = "attemptsRemaining",
}

local ENDLESS_DUNGEON_CENTER_SCREEN_ANNOUNCEMENT_TYPES =
{
    CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_ATTEMPTS_REMAINING_CHANGED,
    CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_PROGRESS,
}

ZO_ENDLESS_DUNGEON_STATES =
{
    INACTIVE = 1,
    ACTIVE = 2,
    COMPLETED = 3,
}

-- Utilities for managing deferred dirty state value processing

local QueueDirtyStateValueProcessing

do
    local areStateValuesDirty = false

    local function ProcessDirtyStateValues()
        areStateValuesDirty = false
        EVENT_MANAGER:UnregisterForUpdate("EndlessDungeonManagerStateValuesUpdated")
        ENDLESS_DUNGEON_MANAGER:ProcessDirtyStateValues()
    end

    QueueDirtyStateValueProcessing = function()
        if not areStateValuesDirty then
            areStateValuesDirty = true
            EVENT_MANAGER:RegisterForUpdate("EndlessDungeonManagerStateValuesUpdated", 0, ProcessDirtyStateValues)
        end
    end
end

ZO_EndlessDungeonStateValue = ZO_InitializingObject:Subclass()

function ZO_EndlessDungeonStateValue:Initialize(defaultValue)
    -- Order matters:
    self.isDirty = false
    self.defaultValue = defaultValue
    self:Reset()
end

function ZO_EndlessDungeonStateValue:IsDirty()
    return self.isDirty == true
end

function ZO_EndlessDungeonStateValue:IsValueDefaultValue()
    return self.value == self.defaultValue
end

-- Returns the default value that this state will return to when calling Reset.
function ZO_EndlessDungeonStateValue:GetDefaultValue()
    return self.defaultValue
end

-- Returns the value prior to any change(s) made since the dirty flag was last cleared.
function ZO_EndlessDungeonStateValue:GetPreviousValue()
    return self.previousValue
end

-- Returns the current value.
function ZO_EndlessDungeonStateValue:GetValue()
    return self.value
end

-- Returns the current and previous values.
function ZO_EndlessDungeonStateValue:GetValues()
    return self.value, self.previousValue
end

-- Returns the current value and previous value and resets the dirty flag.
function ZO_EndlessDungeonStateValue:GetValuesAndClearDirty()
    local wasDirty = self:IsDirty()
    self:SetDirty(false)
    return self.value, self.previousValue, wasDirty
end

-- Sets or clears the dirty flag and notifies the Endless Dungeon Manager singleton.
function ZO_EndlessDungeonStateValue:SetDirty(dirty)
    if dirty ~= self.isDirty then
        self.isDirty = dirty

        if dirty then
            -- Register for deferred processing of state values changed during this frame.
            QueueDirtyStateValueProcessing()
        end
    end
end

-- Sets the current value; if changed and not dirty, updates the previous value; sets the dirty flag.
-- Returns true if the current value changed.
function ZO_EndlessDungeonStateValue:SetValue(value)
    if value == self.value then
        return false
    end

    if self.previousValue == nil then
        -- Initialize previous value to the current value if it was not yet set.
        self.previousValue = value
        self:SetDirty(true)
    elseif not self:IsDirty() then
        -- Update the previous value and set the dirty flag if not already dirty.
        self.previousValue = self.value
        self:SetDirty(true)
    end

    self.value = value
    return true
end

-- Resets the value and previous value to the default value and clears the dirty flag.
function ZO_EndlessDungeonStateValue:Reset()
    self:SetDirty(false)
    self.previousValue = nil
    self.value = nil
end

ZO_EndlessDungeonManager = ZO_InitializingCallbackObject:Subclass()

function ZO_EndlessDungeonManager:Initialize()
    self.activeBuffStackCounts =
    {
        [ENDLESS_DUNGEON_BUFF_TYPE_VERSE] = {},
        [ENDLESS_DUNGEON_BUFF_TYPE_VISION] = {},
    }
    self.areStateValuesDirty = false
    self.counters = {}
    self.state = ZO_ENDLESS_DUNGEON_STATES.INACTIVE

    self:InitializeStateValues()
    self:InitializeEvents()
    self:Reset()
end

function ZO_EndlessDungeonManager:InitializeEvents()
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_BUFF_SELECTOR_CHOICES_RECEIVED, ZO_GetEventForwardingFunction(self, self.OnBuffSelectorChoicesReceived))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_BUFF_STACK_COUNT_UPDATED, ZO_GetEventForwardingFunction(self, self.OnDungeonBuffStackCountUpdated))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_COMPLETED, ZO_GetEventForwardingFunction(self, self.OnDungeonCompleted))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_CONFIRM_COMPANION_SUMMONING, ZO_GetEventForwardingFunction(self, self.OnConfirmCompanionSummoning))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_COUNTER_VALUE_CHANGED, ZO_GetEventForwardingFunction(self, self.OnDungeonCounterValueChanged))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_INITIALIZED, ZO_GetEventForwardingFunction(self, self.OnDungeonInitialized))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_STARTED, ZO_GetEventForwardingFunction(self, self.OnDungeonStarted))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_ENDLESS_DUNGEON_SCORE_UPDATED, ZO_GetEventForwardingFunction(self, self.OnDungeonScoreUpdated))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonManager", EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.OnPlayerActivated))
end

function ZO_EndlessDungeonManager:InitializeStateValues()
    -- Initialize the state values table and define the default value for each key.
    self.stateValues =
    {
        attemptsRemaining = ZO_EndlessDungeonStateValue:New(0),
        stage = ZO_EndlessDungeonStateValue:New(0),
        cycle = ZO_EndlessDungeonStateValue:New(0),
        arc = ZO_EndlessDungeonStateValue:New(0),
        isDungeonCompleted = ZO_EndlessDungeonStateValue:New(false),
        isDungeonStarted = ZO_EndlessDungeonStateValue:New(false),
        score = ZO_EndlessDungeonStateValue:New(0),
    }
end

-- State Management

function ZO_EndlessDungeonManager:IsPlayerInEndlessDungeon()
    return IsInstanceEndlessDungeon()
end

function ZO_EndlessDungeonManager:IsEndlessDungeonStarted()
    return self:IsPlayerInEndlessDungeon() and IsEndlessDungeonStarted()
end

function ZO_EndlessDungeonManager:IsEndlessDungeonCompleted()
    return self:IsPlayerInEndlessDungeon() and IsEndlessDungeonCompleted()
end

function ZO_EndlessDungeonManager:GetAbilityStackCountTable(buffType)
    return self.activeBuffStackCounts[buffType]
end

function ZO_EndlessDungeonManager:GetCounterValue(counterType)
    return GetEndlessDungeonCounterValue(counterType)
end

function ZO_EndlessDungeonManager:GetAttemptsRemaining()
    return self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_WIPES_REMAINING)
end

function ZO_EndlessDungeonManager:GetProgression()
    local stage = self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_STAGE)
    local cycle = self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE)
    local arc = self:GetCounterValue(ENDLESS_DUNGEON_COUNTER_TYPE_ARC)
    return stage, cycle, arc
end

do
    local ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES =
    {
        THIN_OUTLINE =
        {
            [ENDLESS_DUNGEON_COUNTER_TYPE_STAGE] = "EsoUI/Art/EndlessDungeon/icon_progression_stage.dds",
            [ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE] = "EsoUI/Art/EndlessDungeon/icon_progression_cycle.dds",
            [ENDLESS_DUNGEON_COUNTER_TYPE_ARC] = "EsoUI/Art/EndlessDungeon/icon_progression_arc.dds",
        },
        THICK_OUTLINE =
        {
            [ENDLESS_DUNGEON_COUNTER_TYPE_STAGE] = "EsoUI/Art/EndlessDungeon/thick_outline_icon_progression_stage.dds",
            [ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE] = "EsoUI/Art/EndlessDungeon/thick_outline_icon_progression_cycle.dds",
            [ENDLESS_DUNGEON_COUNTER_TYPE_ARC] = "EsoUI/Art/EndlessDungeon/thick_outline_icon_progression_arc.dds",
        },
    }

    function ZO_EndlessDungeonManager.GetProgressionIcon(counterType, useThickOutlineIcons)
        local icons = useThickOutlineIcons and ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THICK_OUTLINE or ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THIN_OUTLINE
        local icon = icons[counterType]
        assert(icon, "Invalid counter type")
        return icon
    end

    function ZO_EndlessDungeonManager.GetProgressionIcons(useThickOutlineIcons)
        local icons = useThickOutlineIcons and ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THICK_OUTLINE or ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THIN_OUTLINE
        local stageIcon = icons[ENDLESS_DUNGEON_COUNTER_TYPE_STAGE]
        local cycleIcon = icons[ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE]
        local arcIcon = icons[ENDLESS_DUNGEON_COUNTER_TYPE_ARC]
        return stageIcon, cycleIcon, arcIcon
    end

    local ICON_SIZE = "80%"
    local ENDLESS_DUNGEON_PROGRESSION_ICON_STRINGS =
    {
        THIN_OUTLINE =
        {
            zo_iconFormat(ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THIN_OUTLINE[ENDLESS_DUNGEON_COUNTER_TYPE_STAGE], ICON_SIZE, ICON_SIZE),
            zo_iconFormat(ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THIN_OUTLINE[ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE], ICON_SIZE, ICON_SIZE),
            zo_iconFormat(ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THIN_OUTLINE[ENDLESS_DUNGEON_COUNTER_TYPE_ARC], ICON_SIZE, ICON_SIZE),
        },
        THICK_OUTLINE =
        {
            zo_iconFormat(ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THICK_OUTLINE[ENDLESS_DUNGEON_COUNTER_TYPE_STAGE], ICON_SIZE, ICON_SIZE),
            zo_iconFormat(ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THICK_OUTLINE[ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE], ICON_SIZE, ICON_SIZE),
            zo_iconFormat(ENDLESS_DUNGEON_PROGRESSION_ICON_TEXTURES.THICK_OUTLINE[ENDLESS_DUNGEON_COUNTER_TYPE_ARC], ICON_SIZE, ICON_SIZE),
        },
    }

    function ZO_EndlessDungeonManager.GetProgressionIconStrings(useThickOutlineIcons)
        local icons = useThickOutlineIcons and ENDLESS_DUNGEON_PROGRESSION_ICON_STRINGS.THICK_OUTLINE or ENDLESS_DUNGEON_PROGRESSION_ICON_STRINGS.THIN_OUTLINE
        return unpack(icons)
    end
end

function ZO_EndlessDungeonManager.GetProgressionText(stage, cycle, arc, useThickOutlineIcons)
    local stageIcon, cycleIcon, arcIcon = ZO_EndlessDungeonManager.GetProgressionIconStrings(useThickOutlineIcons)
    local output = string.format("%s%d %s%d %s%d", arcIcon, arc, cycleIcon, cycle, stageIcon, stage)
    return output
end

function ZO_EndlessDungeonManager:GetCurrentProgressionText(useThickOutlineIcons)
    local stage, cycle, arc = self:GetProgression()
    return ZO_EndlessDungeonManager.GetProgressionText(stage, cycle, arc, useThickOutlineIcons)
end

function ZO_EndlessDungeonManager.GetProgressionNarrationDescriptions(stage, cycle, arc)
    local stageNarration = zo_strformat(SI_ENDLESS_DUNGEON_PROGRESSION_NARRATION, GetString("SI_ENDLESSDUNGEONCOUNTERTYPE", ENDLESS_DUNGEON_COUNTER_TYPE_STAGE), stage)
    local cycleNarration = zo_strformat(SI_ENDLESS_DUNGEON_PROGRESSION_NARRATION, GetString("SI_ENDLESSDUNGEONCOUNTERTYPE", ENDLESS_DUNGEON_COUNTER_TYPE_CYCLE), cycle)
    local arcNarration = zo_strformat(SI_ENDLESS_DUNGEON_PROGRESSION_NARRATION, GetString("SI_ENDLESSDUNGEONCOUNTERTYPE", ENDLESS_DUNGEON_COUNTER_TYPE_ARC), arc)
    return stageNarration, cycleNarration, arcNarration
end

function ZO_EndlessDungeonManager:GetCurrentProgressionNarrationDescriptions()
    local stage, cycle, arc = self:GetProgression()
    return ZO_EndlessDungeonManager.GetProgressionNarrationDescriptions(stage, cycle, arc)
end

function ZO_EndlessDungeonManager:GetScore()
    return GetEndlessDungeonScore()
end

function ZO_EndlessDungeonManager:GetState()
    return self.state
end

-- Gets the current and previous value for the specified state key and resets its dirty flag.
function ZO_EndlessDungeonManager:GetCurrentAndPreviousStateValueAndClearDirty(key)
    local stateValue = self.stateValues[key]
    local currentValue, previousValue, wasDirty = stateValue:GetValuesAndClearDirty()
    return currentValue, previousValue, wasDirty
end

-- Returns true if any of the specified state value key(s) is/are dirty.
function ZO_EndlessDungeonManager:IsAnyStateValueDirty(...)
    local numStateKeys = select("#", ...)
    for stateKeyIndex = 1, numStateKeys do
        local stateKey = select(stateKeyIndex, ...)
        local stateValue = self.stateValues[stateKey]
        if stateValue:IsDirty() then
            return true
        end
    end
    return false
end

function ZO_EndlessDungeonManager:GetNumLifetimeVerseAndVisionStackCounts()
    local numVerses, numNonAvatarVisions, numAvatarVisions = GetNumEndlessDungeonLifetimeVerseAndVisionStackCounts()
    return numVerses, numNonAvatarVisions, numAvatarVisions
end

function ZO_EndlessDungeonManager:Reset()
    -- Acquire the current state.
    -- Order matters:
    ZO_ClearTable(self.counters)
    self:ResetStateValues()
    self:UpdateDungeonCounters()
end

-- Resets each state value to represent the current dungeon state
-- and clears all dirty flags.
function ZO_EndlessDungeonManager:ResetStateValues()
    self.areStateValuesDirty = false

    for counterType, stateKey in pairs(ENDLESS_DUNGEON_COUNTER_TYPE_STATE_VALUE_KEY) do
        local stateValue = self.stateValues[stateKey]
        local value = self.counters[counterType]
        stateValue:Reset()
    end
end

function ZO_EndlessDungeonManager:SetCachedCounterValue(counterType, value)
    local previousValue = self.counters[counterType]
    if previousValue == value then
        return false
    end

    -- Update the counter value.
    self.counters[counterType] = value

    -- Update the associated state value, if any.
    local stateKey = ENDLESS_DUNGEON_COUNTER_TYPE_STATE_VALUE_KEY[counterType]
    if stateKey then
        self:SetStateValue(stateKey, value)
    end

    return true
end

function ZO_EndlessDungeonManager:SetScore(score)
    if score == self.score then
        return false
    end

    -- Update the current score and associated state value.
    self.score = score
    self:SetStateValue("score", score)
    return true
end

function ZO_EndlessDungeonManager:SetState(state)
    local previousState = self.state
    if previousState == state then
        return false
    end

    if state == ZO_ENDLESS_DUNGEON_STATES.INACTIVE then
        -- Suppress Endless Dungeon CSAs while not in an active Endless Dungeon.
        for _, csaType in ipairs(ENDLESS_DUNGEON_CENTER_SCREEN_ANNOUNCEMENT_TYPES) do
            CENTER_SCREEN_ANNOUNCE:SupressAnnouncementByType(csaType)
        end
    else
        -- Resume Endless Dungeon CSAs while in an active Endless Dungeon.
        for _, csaType in ipairs(ENDLESS_DUNGEON_CENTER_SCREEN_ANNOUNCEMENT_TYPES) do
            CENTER_SCREEN_ANNOUNCE:ResumeAnnouncementByType(csaType)
        end
    end

    -- Update the current dungeon state and counters.
    -- Order matters:
    self.state = state
    self:UpdateDungeonCounters()
    self:FireCallbacks("StateChanged", state, previousState)
    self:UpdateDungeonBuffs()

    return true
end

function ZO_EndlessDungeonManager:UpdateDungeonBuffs()
    -- Remove existing Verses and Visions.
    local ZERO_STACKS = 0
    for previousBuffType, previousBuffStackCounts in pairs(self.activeBuffStackCounts) do
        for previousAbilityId, previousStackCount in pairs(previousBuffStackCounts) do
            previousBuffStackCounts[previousAbilityId] = nil
            self:FireCallbacks("BuffStackCountChanged", previousBuffType, previousAbilityId, ZERO_STACKS, previousStackCount)
        end
    end

    local state = self.state
    if state == ZO_ENDLESS_DUNGEON_STATES.INACTIVE then
        -- The local player is not in an Endless Dungeon
        -- or the instance has not started.
        return
    end

    if state == ZO_ENDLESS_DUNGEON_STATES.COMPLETED then
        -- Acquire lifetime Verses.
        local activeVerseAbilityId, numActiveVerseStacks = GetNextEndlessDungeonLifetimeVerseAbilityAndStackCount()
        while activeVerseAbilityId do
            self:OnDungeonBuffStackCountUpdated(ENDLESS_DUNGEON_BUFF_TYPE_VERSE, activeVerseAbilityId, numActiveVerseStacks, SUPPRESS_CSA)
            activeVerseAbilityId, numActiveVerseStacks = GetNextEndlessDungeonLifetimeVerseAbilityAndStackCount(activeVerseAbilityId)
        end
    else
        -- Acquire active Verses.
        local SINGLE_STACK = 1 -- Active verses cannot stack.
        local numActiveVerses = GetNumEndlessDungeonActiveVerses()
        for activeVerseIndex = 1, numActiveVerses do
            local activeVerseAbilityId = GetEndlessDungeonActiveVerseAbility(activeVerseIndex)
            self:OnDungeonBuffStackCountUpdated(ENDLESS_DUNGEON_BUFF_TYPE_VERSE, activeVerseAbilityId, SINGLE_STACK, SUPPRESS_CSA)
        end
    end

    -- Acquire active/lifetime Visions.
    local activeVisionAbilityId, numActiveVisionStacks = GetNextEndlessDungeonVisionAbilityAndStackCount()
    while activeVisionAbilityId do
        self:OnDungeonBuffStackCountUpdated(ENDLESS_DUNGEON_BUFF_TYPE_VISION, activeVisionAbilityId, numActiveVisionStacks, SUPPRESS_CSA)
        activeVisionAbilityId, numActiveVisionStacks = GetNextEndlessDungeonVisionAbilityAndStackCount(activeVisionAbilityId)
    end
end

function ZO_EndlessDungeonManager:UpdateDungeonCounters()
    -- Cache all Endless Dungeon counter values and process any changes.
    for counterType = ENDLESS_DUNGEON_COUNTER_TYPE_ITERATION_BEGIN, ENDLESS_DUNGEON_COUNTER_TYPE_ITERATION_END do
        local value = self:GetCounterValue(counterType)
        self:SetCachedCounterValue(counterType, value)
    end
end

function ZO_EndlessDungeonManager:UpdateState()
    -- Refresh the current dungeon state from the instance data.
    if self:IsEndlessDungeonCompleted() then
        self:SetState(ZO_ENDLESS_DUNGEON_STATES.COMPLETED)
    elseif self:IsEndlessDungeonStarted() then
        self:SetState(ZO_ENDLESS_DUNGEON_STATES.ACTIVE)
    else
        self:SetState(ZO_ENDLESS_DUNGEON_STATES.INACTIVE)
    end
    self:UpdateDungeonCounters()
end

-- User Interface

function ZO_EndlessDungeonManager:ProcessDirtyStateValues()
    -- Changes to state values that trigger UI updates are processed in bulk in order to provide callback
    -- subscribers with consolidated callbacks that may be comprise several disparate trigger events.
    -- State value changes should be processed in the order in which associated UI updates should appear.

    -- Order matters:

    local isDungeonStarted, wasDungeonStarted, isDungeonStartedDirty = self:GetCurrentAndPreviousStateValueAndClearDirty("isDungeonStarted")
    if isDungeonStartedDirty and isDungeonStarted then
        self:FireCallbacks("DungeonStarted")
    end

    local attemptsRemaining, previousAttemptsRemaining, isAttemptsRemainingDirty = self:GetCurrentAndPreviousStateValueAndClearDirty("attemptsRemaining")
    if isAttemptsRemainingDirty then
        self:FireCallbacks("AttemptsRemainingChanged", attemptsRemaining, previousAttemptsRemaining)
    end

    local score, previousScore, isScoreDirty = self:GetCurrentAndPreviousStateValueAndClearDirty("score")
    if isScoreDirty then
        self:FireCallbacks("ScoreChanged", score, previousScore)
    end

    if self:IsAnyStateValueDirty("stage", "cycle", "arc") then
        local stage, previousStage = self:GetCurrentAndPreviousStateValueAndClearDirty("stage")
        local cycle, previousCycle = self:GetCurrentAndPreviousStateValueAndClearDirty("cycle")
        local arc, previousArc = self:GetCurrentAndPreviousStateValueAndClearDirty("arc")
        self:FireCallbacks("ProgressionChanged", stage, cycle, arc, previousStage, previousCycle, previousArc)
    end

    local isDungeonCompleted, wasDungeonCompleted, isDungeonCompletedDirty = self:GetCurrentAndPreviousStateValueAndClearDirty("isDungeonCompleted")
    if isDungeonCompletedDirty and isDungeonCompleted then
        self:FireCallbacks("DungeonCompleted")
    end
end

-- Sets the current value for the specified state key.
function ZO_EndlessDungeonManager:SetStateValue(key, value)
    local stateValue = self.stateValues[key]
    stateValue:SetValue(value)
end

-- Event Handlers

function ZO_EndlessDungeonManager:OnBuffSelectorChoicesReceived()
    SYSTEMS:ShowScene("endlessDungeonBuffSelector")
end

function ZO_EndlessDungeonManager:OnConfirmCompanionSummoning(collectibleId)
    ZO_Dialogs_ShowPlatformDialog("CONFIRM_ENDLESS_DUNGEON_COMPANION_SUMMONING", {collectibleId = collectibleId})
end

function ZO_EndlessDungeonManager:OnDungeonBuffStackCountUpdated(buffType, abilityId, stackCount, suppressCSA)
    local buffStackCountTable = self.activeBuffStackCounts[buffType]
    if not internalassert(buffStackCountTable, string.format("Invalid buffType: %s", tostring(buffType) or "(nil)")) then
        return
    end

    local previousStackCount = buffStackCountTable[abilityId] or 0
    if previousStackCount == stackCount then
        return
    end

    if stackCount > 0 then
        buffStackCountTable[abilityId] = stackCount
    else
        -- Remove the buff from the active table if the stack count falls below one.
        buffStackCountTable[abilityId] = nil
    end

    self:FireCallbacks("BuffStackCountChanged", buffType, abilityId, stackCount, previousStackCount, suppressCSA)
end

function ZO_EndlessDungeonManager:OnDungeonCompleted(currentScore, flags)
    -- Update the current score and dungeon state and queue the relevant UI updates.
    self:SetScore(currentScore)
    if self:SetState(ZO_ENDLESS_DUNGEON_STATES.COMPLETED) then
        self:SetStateValue("isDungeonCompleted", true)
    end
end

function ZO_EndlessDungeonManager:OnDungeonCounterValueChanged(counterType, value)
    -- Update the counter value and queue the relevant UI update.
    self:SetCachedCounterValue(counterType, value)
end

function ZO_EndlessDungeonManager:OnDungeonInitialized(dungeonId, currentScore, currentBonusPoints, flags, completed)
    -- Order matters:
    self:Reset()
    self:SetScore(currentScore)
    self:FireCallbacks("DungeonInitialized")
    if completed then
        -- The dungeon has already been completed.
        self:OnDungeonCompleted(currentScore, flags)
    else
        -- The dungeon is active.
        self:OnDungeonStarted()
    end
end

function ZO_EndlessDungeonManager:OnDungeonStarted()
    -- Update the dungeon state and queue the relevant UI update.
    if self:SetState(ZO_ENDLESS_DUNGEON_STATES.ACTIVE) then
        self:SetStateValue("isDungeonStarted", true)
    end
end

function ZO_EndlessDungeonManager:OnDungeonScoreUpdated(currentScore, reason)
    -- Update the current score and queue the relevant UI update.
    self:SetScore(currentScore)
end

function ZO_EndlessDungeonManager:OnPlayerActivated()
    -- Force an update of the current dungeon state.
    self:UpdateState()
end

-- Global Singleton

ENDLESS_DUNGEON_MANAGER = ZO_EndlessDungeonManager:New()