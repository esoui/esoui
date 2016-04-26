local SUPPRESS_LAYOUT = true

local QuestTimer = ZO_Object:Subclass()

function QuestTimer:New(...)
    local questTimer = ZO_Object.New(self)
    questTimer:Initialize(...)
    
    return questTimer
end

function QuestTimer:Initialize(control)
    self.timers = {}

    self.control = control

    self:InitializePooling()
	self:InitializeEvents()

    self:StartExistingTimers()
end

function QuestTimer:InitializeEvents()
    local function OnQuestTimerUpdated(eventCode, ...)
        self:OnQuestTimerUpdated(...)
    end

    local function OnQuestTimerPaused(eventCode, ...)
        self:OnQuestTimerPaused(...)
    end

    local function OnQuestRemoved(eventCode, isCompleted, index)
        self:RemoveTimerByIndex(index)
    end

    local function OnGamepadPreferredModeChanged()
        self:PerformLayout()
    end

    self.control:RegisterForEvent(EVENT_QUEST_TIMER_UPDATED, OnQuestTimerUpdated)
	self.control:RegisterForEvent(EVENT_QUEST_TIMER_PAUSED, OnQuestTimerPaused)
	self.control:RegisterForEvent(EVENT_QUEST_REMOVED, OnQuestRemoved)
    self.control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadPreferredModeChanged)
end

function QuestTimer:InitializePooling()
    self.timerPool = ZO_ControlPool:New("ZO_QuestTimerTemplate", self.control)
    self.timerPool:SetCustomFactoryBehavior(function(control)
                                                control.label = control:GetNamedChild("Label")
                                                control.time = control:GetNamedChild("Time")
                                            end)
end

function QuestTimer:OnQuestTimerUpdated(index)
    local visible = select(3, GetJournalQuestTimerInfo(index))

    if visible then
        self:CreateTimerFromIndex(index)
    else
    	self:RemoveTimerByIndex(index)
	end
end

function QuestTimer:OnQuestTimerPaused(index, isPaused)
    if self.timers[index] then
        self.timers[index].paused = isPaused
		if not isPaused then
			local starts, ends = GetJournalQuestTimerInfo(index)
			self.timers[index].start = starts
			self.timers[index].ends = ends
		end
    end
end

function QuestTimer:AcquireTimer(index)
    if self.timers[index] then
        return self.timers[index]
    end

    local timer, key = self.timerPool:AcquireObject()
    timer.key = key
    timer.owner = self
    timer:SetHidden(false)
    self.timers[index] = timer
    return timer
end

function QuestTimer:RemoveTimerByIndex(index, suppressLayout)
    if self.timers[index] then
        self.timerPool:ReleaseObject(self.timers[index].key)
        self.timers[index] = nil
        if not suppressLayout then
            self:PerformLayout()
        end
    end
end

function QuestTimer:UpdateTimer(timer, now)
    if not timer.paused and timer.nextUpdate <= now then
        local remainingTime = timer.ends - now
        if remainingTime > 0 then
            local timeText, nextUpdateDelta = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
            timer.time:SetText(timeText)
            timer.nextUpdate = now + nextUpdateDelta
        else
            self:RemoveTimerByIndex(timer.index)
        end
    end
end

function QuestTimer:CreateTimerFromIndex(index, suppressLayout)
    local starts, ends, visible, paused = GetJournalQuestTimerInfo(index)
    if visible then
	    local caption = GetJournalQuestTimerCaption(index)

        local timer = self:AcquireTimer(index)
        timer.label:SetText(caption)

        timer.start = starts
        timer.ends = ends
        timer.index = index
        timer.paused = paused

        local now = GetFrameTimeSeconds()
        timer.nextUpdate = now

        self:UpdateTimer(timer, now)

        if not suppressLayout then
            self:PerformLayout()
        end
    end
end

function QuestTimer:StartExistingTimers()
	for i=1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(i) then
            self:CreateTimerFromIndex(i, SUPPRESS_LAYOUT)
        end
    end

    self:PerformLayout()
end

do
    local function GetTimeLeft(timer)
        return timer.ends - GetFrameTimeSeconds()
    end

    local function TimerComparer(left, right)
        
        return GetTimeLeft(left) > GetTimeLeft(right)
    end

    local GAMEPAD_CONSTANTS = {
        anchorPoint = TOPRIGHT,
        anchorRelativePoint = BOTTOMRIGHT,
        anchorRelativePointFirstEntry = TOPRIGHT,

        offsetX = -40,
        offsetFirstY = 9,
        offsetY = 10,
    }

    local KEYBOARD_CONSTANTS = {
        anchorPoint = TOPLEFT,
        anchorRelativePoint = BOTTOMLEFT,
        anchorRelativePointFirstEntry = TOPLEFT,

        offsetY = 5,
    }

    local function GetPlatformConstants()
        return IsInGamepadPreferredMode() and GAMEPAD_CONSTANTS or KEYBOARD_CONSTANTS
    end

    function QuestTimer:PerformLayout()
        local sortedTimers = {}
        for index, timer in pairs(self.timers) do
            timer:ClearAnchors()
            sortedTimers[#sortedTimers + 1] = timer
        end

        table.sort(sortedTimers, TimerComparer)

        local constants = GetPlatformConstants()
        local template = ZO_GetPlatformTemplate("ZO_QuestTimer")

        for i, timer in ipairs(sortedTimers) do
            ApplyTemplateToControl(timer, template)
			
			-- Reapply caption so the text is updated with the new modify text type
			local caption = GetJournalQuestTimerCaption(timer.index)
			timer.label:SetText(caption)

            if i == 1 then
                timer:SetAnchor(constants.anchorPoint, nil, constants.anchorRelativePointFirstEntry, constants.offsetX, constants.offsetFirstY)
            else
                timer:SetAnchor(constants.anchorPoint, sortedTimers[i - 1], constants.anchorRelativePoint, constants.offsetX, constants.offsetY)
            end
        end
    end
end

--[[ XML Handlers ]]--
function ZO_QuestTimer_OnMouseUp(control)
    SYSTEMS:GetObject("questJournal"):FocusQuestWithIndex(control.index) 
end

function ZO_QuestTimer_OnUpdate(control, time)
    control.owner:UpdateTimer(control, time)
end

function ZO_QuestTimer_CreateInContainer(control)
    return QuestTimer:New(control)
end