ZO_TimerBar = ZO_InitializingObject:Subclass()

TIMER_BAR_COUNTS_UP = 1
TIMER_BAR_COUNTS_DOWN = 2

local TIMER_BAR_DEFAULT_FADE_DURATION = 0.25
local TIMER_BAR_DEFAULT_UPDATE_INTERVAL = 0.25

function ZO_TimerBar:Initialize(control)
    control:SetHidden(true)
    
    self.updateFunction = function(barControl, time)
        self:Update(time)
    end
    self.control = control
    self.status = control:GetNamedChild("Status")
    self.time = control:GetNamedChild("Time")
    self.running = false
    
    --defaults
    self.direction = TIMER_BAR_COUNTS_UP
    self.fades = false  
    
    self.timeFormatStyle = TIME_FORMAT_STYLE_COLONS
    self.timePrecision = TIME_FORMAT_PRECISION_SECONDS  
end

function ZO_TimerBar:SetLabel(text)
    self.control:GetNamedChild("Label"):SetText(text)
end

function ZO_TimerBar:SetDirection(direction)
    if self.direction ~= direction then
        self.direction = direction
        if self.running then
            self:Update(GetFrameTimeSeconds())
        end
    end
end

function ZO_TimerBar:SetTimeFormatParameters(timeFormatStyle, timePrecision)
    self.timeFormatStyle = timeFormatStyle
    self.timePrecision = timePrecision
end

function ZO_TimerBar:SetFades(fades, duration)
    if self.fades ~= fades then
        self.fades = fades
        if fades then
            if not self.animation then
                self.animation = ZO_AlphaAnimation:New(self.control)
                self.fadeDuration = duration or TIMER_BAR_DEFAULT_FADE_DURATION
            end
        else
            if self.animation then
                self.animation:Stop()
            end
        end
    end
end

function ZO_TimerBar:IsStarted()
    return self.running
end

function ZO_TimerBar:IsPaused()
    return self.paused
end

function ZO_TimerBar:GetTimeLeft()
    if self:IsStarted() then
        return zo_max(0, self.ends - GetFrameTimeSeconds())
    end
    return 0
end

function ZO_TimerBar:Start(starts, ends)
    if self.fades then
        self.animation:Stop()
    end

    local control = self.control
    control:SetHandler("OnUpdate", self.updateFunction)
    control:SetHidden(false)

    local status = self.status
    status:SetMinMax(0, ends - starts)
    self.starts = starts
    self.ends = ends
    self.running = true
    self.paused = false
    self.nextBarUpdate = 0
    self.nextLabelUpdate = 0
    self.pauseElapsed = 0

    --Find out how much time it takes for the bar to move one UI unit. This isn't anything super precise, it just gives a servicable estimate of how often we should update
    local width, _ = self.control:GetDimensions()
    if width > 0 then
        self.barUpdateInterval = (ends - starts) / width
    else
        self.barUpdateInterval = TIMER_BAR_DEFAULT_UPDATE_INTERVAL
    end
    self:Update(GetFrameTimeSeconds())
end

function ZO_TimerBar:SetPaused(paused)
    if paused ~= self.paused then
        self.paused = paused
        if paused then
            self.control:SetHandler("OnUpdate", nil)
            self.pauseTime = GetFrameTimeSeconds()
        else
            local frameTime = GetFrameTimeSeconds()
            local timeSpentInPause = frameTime - self.pauseTime
            self.pauseElapsed = self.pauseElapsed + timeSpentInPause
            self.ends = self.ends + timeSpentInPause
            self.pauseTime = nil
            self.nextBarUpdate = 0
            self.nextLabelUpdate = 0
            self.control:SetHandler("OnUpdate", self.updateFunction)
            self:Update(frameTime)
        end
    end
end

do
    local function FadeOutDone(control)
        control:SetAlpha(1)
        control:SetHidden(true)
    end

    function ZO_TimerBar:Stop()
        if not self:IsStarted() then
            return
        end

        local control = self.control
        control:SetHandler("OnUpdate", nil)

        if self.fades then
            self.animation:FadeOut(0, self.fadeDuration, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA, FadeOutDone)
        else
            control:SetHidden(true)
        end

        self.running = false
        self.starts = nil
        self.ends = nil
        self.paused = nil
        self.pauseElapsed = nil
        self.pauseTime = nil
    end
end

function ZO_TimerBar:Update(time)
    if time > self.ends then
        self:Stop()
        return
    end

    local barReady = time > self.nextBarUpdate
    local labelReady = self.time and time > self.nextLabelUpdate

    if not (barReady or labelReady) then
        return
    end

    local timeString = ""
    local remainingUntilUpdate
    if self.direction == TIMER_BAR_COUNTS_UP then
        local totalElapsed = time - self.starts - self.pauseElapsed
        if barReady then
            self.status:SetValue(totalElapsed)
        end

        if labelReady then
            timeString, remainingUntilUpdate = ZO_FormatTime(totalElapsed, self.timeFormatStyle, self.timePrecision, TIME_FORMAT_DIRECTION_ASCENDING)
            if self.timeStringDecoratorFunction then
                timeString = self.timeStringDecoratorFunction(timeString)
            end
            self.time:SetText(timeString)
        end
    else
        local totalRemaining = self.ends - time

        if barReady then
            self.status:SetValue(totalRemaining)
        end

        if labelReady then
            timeString, remainingUntilUpdate = ZO_FormatTime(totalRemaining, self.timeFormatStyle, self.timePrecision, TIME_FORMAT_DIRECTION_DESCENDING)
            if self.timeStringDecoratorFunction then
                timeString = self.timeStringDecoratorFunction(timeString)
            end
            self.time:SetText(timeString)
        end
    end

    self.timeString = timeString

    if barReady then
        self.nextBarUpdate = time + self.barUpdateInterval
    end

    if labelReady then
        self.nextLabelUpdate = time + remainingUntilUpdate
    end
end

-- This function should accept a time string as its argument and return a decorated time string, for timer bars where we want to
-- add some special accoutrements to the time display on the timer bar.
function ZO_TimerBar:SetTimeStringDecoratorFunction(timeStringDecoratorFunction)
    self.timeStringDecoratorFunction = timeStringDecoratorFunction
end

function ZO_TimerBar:GetNarrationText()
    if self.direction == TIMER_BAR_COUNTS_DOWN then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_TIMER_BAR_DESCENDING_FORMATTER, self.timeString))
    else
        --TODO XAR: Do we want to use a special formatter for when the timer is counting up as well?
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.timeString)
    end
end

--[[ Timer Bar Segment ]]--
ZO_TimerBarSegment = ZO_InitializingObject:Subclass()

-- Color is expected to be a ZO_ColorDef
function ZO_TimerBarSegment:Initialize(duration, startColor, endColor)
    self.duration = duration
    self.startColor = startColor
    self.endColor = endColor
end

function ZO_TimerBarSegment:GetDuration()
    return self.duration
end

function ZO_TimerBarSegment:GetStartColor()
    return self.startColor
end

function ZO_TimerBarSegment:GetEndColor()
    return self.endColor
end

--[[ Multi Segment Timer Bar ]]--

ZO_MultiSegmentTimerBar = ZO_TimerBar:Subclass()

-- Currently, this only supports bar templates with children but no grandchildren;
-- Ensure that any template used only has one layer of inheritance.
function ZO_MultiSegmentTimerBar:Initialize(control, barTemplate)
    control:SetHidden(true)

    self.updateFunction = function(barControl, time)
        self:Update(time)
    end
    self.control = control

    barTemplate = barTemplate or "TimerBarStatus"
    self.barPool = ZO_ControlPool:New(barTemplate, control)
    self.segments = { }
    self.barData = { }
    self.time = control:GetNamedChild("Time")
    self.running = false

    --defaults
    self.direction = TIMER_BAR_COUNTS_UP
    self.fades = false

    self.timeFormatStyle = TIME_FORMAT_STYLE_COLONS
    self.timePrecision = TIME_FORMAT_PRECISION_SECONDS
end

function ZO_MultiSegmentTimerBar:Start(startTimeS)
    if self.fades then
        self.animation:Stop()
    end

    local control = self.control
    control:SetHandler("OnUpdate", self.updateFunction)
    control:SetHidden(false)

    self.barPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.barData)

    local totalDurationS = self:GetTotalDuration()
    for index, segment in ipairs(self.segments) do
        local bar = self.barPool:AcquireObject()
        bar:SetParent(control)
        bar:SetMinMax(0, totalDurationS)
        local startR, startG, startB, startA = segment:GetStartColor():UnpackRGBA()
        local endR, endG, endB, endA = segment:GetEndColor():UnpackRGBA()
        bar:SetGradientColors(startR, startG, startB, startA, endR, endG, endB, endA)
        bar:SetAnchorFill()
        bar:SetDrawLevel(index)
        for childIndex = 1, bar:GetNumChildren() do
            bar:GetChild(childIndex):SetDrawLevel(index)
        end

        local previousSumDuration = index == 1 and 0 or self.barData[index - 1].sumDuration
        self.barData[index] =
        {
            bar = bar,
            sumDuration = segment:GetDuration() + previousSumDuration,
        }
    end

    self.starts = startTimeS
    self.ends = startTimeS + totalDurationS
    self.running = true
    self.paused = false
    self.nextBarUpdate = 0
    self.nextLabelUpdate = 0
    self.pauseElapsed = 0

    --Find out how much time it takes for the bar to move one UI unit. This isn't anything super precise, it just gives a servicable estimate of how often we should update
    local width = self.control:GetWidth()
    if width > 0 then
        self.barUpdateInterval = (totalDurationS) / width
    else
        self.barUpdateInterval = TIMER_BAR_DEFAULT_UPDATE_INTERVAL
    end

    if self.customOnStartBehavior and type(customOnStartBehavior) == "function" then
        self.customOnStartBehavior(self.barData)
    end

    self:Update(GetFrameTimeSeconds())
end

function ZO_MultiSegmentTimerBar:Update(timeS)
    if timeS > self.ends then
        self:Stop()
        return
    end

    local barReady = timeS > self.nextBarUpdate
    local labelReady = self.time and timeS > self.nextLabelUpdate

    if not (barReady or labelReady) then
        return
    end

    local timeString = ""
    local remainingUntilUpdate
    if self.direction == TIMER_BAR_COUNTS_UP then
        local totalElapsed = timeS - self.starts - self.pauseElapsed
        if barReady then
            for i, barData in ipairs(self.barData) do
                local currentValue = zo_min(totalElapsed, self:GetSumDurationForSegment(i))
                self.barData[i].bar:SetValue(currentValue)
            end
        end

        if labelReady then
            timeString, remainingUntilUpdate = ZO_FormatTime(totalElapsed, self.timeFormatStyle, self.timePrecision, TIME_FORMAT_DIRECTION_ASCENDING)
            if self.timeStringDecoratorFunction then
                timeString = self.timeStringDecoratorFunction(timeString)
            end
            self.time:SetText(timeString)
        end
    else
        local totalRemaining = self.ends - timeS

        if barReady then
            for i, barData in ipairs(self.barData) do
                local currentValue = zo_min(totalRemaining, self:GetSumDurationForSegment(i))
                self.barData[i].bar:SetValue(currentValue)
            end
        end

        if labelReady then
            timeString, remainingUntilUpdate = ZO_FormatTime(totalRemaining, self.timeFormatStyle, self.timePrecision, TIME_FORMAT_DIRECTION_DESCENDING)
            if self.timeStringDecoratorFunction then
                timeString = self.timeStringDecoratorFunction(timeString)
            end
            self.time:SetText(timeString)
        end
    end

    self.timeString = timeString

    if barReady then
        self.nextBarUpdate = timeS + self.barUpdateInterval
    end

    if labelReady then
        self.nextLabelUpdate = timeS + remainingUntilUpdate
    end
end

function ZO_MultiSegmentTimerBar:AddSegment(duration, startColor, endColor)
    internalassert(not self.running, "TimerBars do not support adding segments while the timer is running")

    local segmentData = ZO_TimerBarSegment:New(duration, startColor, endColor)
    table.insert(self.segments, segmentData)
end

function ZO_MultiSegmentTimerBar:ClearSegments()
    ZO_ClearNumericallyIndexedTable(self.segments)
end

function ZO_MultiSegmentTimerBar:GetSumDurationForSegment(segmentIndex)
    local sumDuration = 0
    local numSegments = #self.segments
    for index = segmentIndex, numSegments do
        sumDuration = sumDuration + self.segments[index]:GetDuration()
    end

    return sumDuration
end

function ZO_MultiSegmentTimerBar:GetTotalDuration()
    return self:GetSumDurationForSegment(1)
end

-- If a specific MultiSegmentTimerBar implementation has anything that requires special handling,
-- that should be accounted for here.
function ZO_MultiSegmentTimerBar:SetCustomOnStartBehavior(customOnStartBehavior)
    self.customOnStartBehavior = customOnStartBehavior
end