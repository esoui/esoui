ZO_TimerBar = ZO_Object:Subclass()

TIMER_BAR_COUNTS_UP = 1
TIMER_BAR_COUNTS_DOWN = 2

local TIMER_BAR_DEFAULT_FADE_DURATION = 0.25
local TIMER_BAR_DEFAULT_UPDATE_INTERVAL = 0.25

function ZO_TimerBar:New(control)
    local bar = ZO_Object.New(self)
    
    control:SetHidden(true)
    
    bar.updateFunction = function(control, time)	bar:Update(time) end
    bar.control = control
    bar.status = GetControl(control, "Status")
    bar.time = GetControl(control, "Time")
    bar.running = false
    
    --defaults
    bar.direction = TIMER_BAR_COUNTS_UP
    bar.fades = false  
    
    bar.timeFormatStyle = TIME_FORMAT_STYLE_COLONS
    bar.timePrecision = TIME_FORMAT_PRECISION_SECONDS  
    
    return bar
end

function ZO_TimerBar:SetLabel(text)
	GetControl(self.control, "Label"):SetText(text)
end

function ZO_TimerBar:SetDirection(direction)
	if(self.direction ~= direction) then
		self.direction = direction
		if(self.running) then
			self:Update(GetFrameTimeSeconds())
		end
	end
end

function ZO_TimerBar:SetTimeFormatParameters(timeFormatStyle, timePrecision)
    self.timeFormatStyle = timeFormatStyle
    self.timePrecision = timePrecision
end

function ZO_TimerBar:SetFades(fades, duration)
	if(self.fades ~= fades) then
		self.fades = fades
		if(fades) then
			if(not self.animation) then
				self.animation = ZO_AlphaAnimation:New(self.control)
				self.fadeDuration = duration or TIMER_BAR_DEFAULT_FADE_DURATION
			end
		else
			if(self.animation) then
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
	if(self.fades) then
		self.animation:Stop()
	end

	local control = self.control	
	control:SetHandler("OnUpdate", self.updateFunction)
	control:SetHidden(false)
	
	local status = self.status	
	status:SetMinMax(0, ends-starts)	
	self.starts = starts
	self.ends = ends
	self.running = true
	self.paused = false
	self.nextBarUpdate = 0
	self.nextLabelUpdate = 0
	self.pauseElapsed = 0
	
	--Find out how much time it takes for the bar to move one UI unit. This isn't anything super precise, it just gives a servicable estimate of how often we should update
	local width, _ = self.control:GetDimensions()
	if(width > 0) then
		self.barUpdateInterval = (ends-starts)/width
	else
		self.barUpdateInterval = TIMER_BAR_DEFAULT_UPDATE_INTERVAL
	end
	
	self:Update(GetFrameTimeSeconds())
end

function ZO_TimerBar:SetPaused(paused)
	if(paused ~= self.paused) then
		self.paused = paused
		if(paused) then
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

local function FadeOutDone(control)
	control:SetAlpha(1)
	control:SetHidden(true)
end

function ZO_TimerBar:Stop()
	if(not self:IsStarted()) then
		return
	end

	local control = self.control	
	control:SetHandler("OnUpdate", nil)
	
	if(self.fades) then
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

function ZO_TimerBar:Update(time)
	if(time > self.ends) then
		self:Stop()
		return
	end
	
	local barReady = time > self.nextBarUpdate
	local labelReady = self.time and time > self.nextLabelUpdate
	
	if(not (barReady or labelReady)) then
		return
	end
	
	local timeString = ""
	local remainingUntilUpdate
		
	if(self.direction == TIMER_BAR_COUNTS_UP) then
		local totalElapsed = time - self.starts - self.pauseElapsed
		
		if(barReady) then
			self.status:SetValue(totalElapsed)	
		end
		
		if(labelReady) then
			timeString, remainingUntilUpdate = ZO_FormatTime(totalElapsed, self.timeFormatStyle, self.timePrecision, TIME_FORMAT_DIRECTION_ASCENDING)
			self.time:SetText(timeString)
		end
	else
		local totalRemaining = self.ends - time
		
		if(barReady) then
			self.status:SetValue(totalRemaining)
		end
		
		if(labelReady) then
			timeString, remainingUntilUpdate = ZO_FormatTime(totalRemaining, self.timeFormatStyle, self.timePrecision, TIME_FORMAT_DIRECTION_DESCENDING)
			self.time:SetText(timeString)
		end
	end
	
	if(barReady) then
		self.nextBarUpdate = time + self.barUpdateInterval
	end
	
	if(labelReady) then
		self.nextLabelUpdate = time + remainingUntilUpdate
	end
end