local CSA_INACTIVE = 0
CSA_EVENT_SMALL_TEXT = 1
CSA_EVENT_LARGE_TEXT = 2
CSA_EVENT_COMBINED_TEXT = 3
CSA_EVENT_NO_TEXT = 4
CSA_EVENT_RAID_COMPLETE_TEXT = 5

CSA_OPTION_SUPPRESS_ICON_FRAME = true

ZO_MAX_CSA_SCROLL_WIDTH = 2184
ZO_MIN_CSA_SCROLL_WIDTH = 512
ZO_MAX_CSA_SCROLL_HEIGHT = 500

local ARG_INDEX_SOUND = 1
local ARG_INDEX_MESSAGE = 2
local ARG_INDEX_COMBINED_MESSAGE = 3
local ARG_INDEX_ICON = 4
local ARG_INDEX_ICON_BG = 5
local ARG_INDEX_EXPIRING_CALLBACK = 6
local ARG_INDEX_BAR_PARAMS = 7
local ARG_INDEX_LIFESPAN = 8
local ARG_INDEX_SUPPRESS_FRAME = 9
local ARG_INDEX_QUEUE_IMMEDIATELY = 10
local ARG_INDEX_SHOW_IMMEDIATELY = 11
local ARG_INDEX_REINSERT_STOMPED_MESSAGE = 12

local ARG_BREAKDOWN_INDEX_SCORE = 1
local ARG_BREAKDOWN_INDEX_TIME = 2
local ARG_BREAKDOWN_INDEX_SHOW_AS_ERROR = 3
local ARG_BREAKDOWN_INDEX_VITALITY_AMOUNT = 4
local ARG_BREAKDOWN_INDEX_VITALITY_PERCENT = 5

local SMALL_TEXT_FONT_KEYBOARD = "ZoFontCenterScreenAnnounceSmall"
local SMALL_TEXT_FONT_GAMEPAD = "ZoFontGamepad42"

local SMALL_TEXT_SPACING_KEYBOARD = 0
local SMALL_TEXT_SPACING_GAMEPAD = 10

local DEFAULT_FADE_OUT_TIME = 3500

local CenterScreenPlayerProgressBarParams = ZO_Object:Subclass()

function CenterScreenPlayerProgressBarParams:New()
    return ZO_Object.New(self)
end

function CenterScreenPlayerProgressBarParams:Reset()
    self.type = nil
    self.startLevel = nil
    self.start = nil
    self.stop = nil
    self.sound = nil
    self.showNoGain = false
end

function CenterScreenPlayerProgressBarParams:Set(barType, startLevel, start, stop, sound)
    self.type = barType
    self.startLevel = startLevel
    self.start = start
    self.stop = stop
    self.sound = sound
end

function CenterScreenPlayerProgressBarParams:GetParams()
    return self.type, self.startLevel, self.start, self.stop, self.sound
end

function CenterScreenPlayerProgressBarParams:SetShowNoGain(showNoGain)
    self.showNoGain = showNoGain
end

function CenterScreenPlayerProgressBarParams:SetSound(sound)
    self.sound = sound
end

local function CallExpiringCallbackTimeline(timeline, offset)
    CENTER_SCREEN_ANNOUNCE:CallExpiringCallback(timeline.m_control)
end

local CenterScreenAnnounce = ZO_Object:Subclass()

function CenterScreenAnnounce:New(...)
    local announce = ZO_Object.New(self)
    announce:Initialize(...)
    return announce
end

function CenterScreenAnnounce:InitializeLineAnimation(line, timelineTemplate, timelineMemberKey, stopHandler, expiringCallbackCheckOffset, expiringCallbackExecutor)
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(timelineTemplate, line)
    line[timelineMemberKey] = timeline
    timeline.m_control = line
    timeline:SetHandler("OnStop", stopHandler)

    if(expiringCallbackCheckOffset and expiringCallbackExecutor) then
        timeline:InsertCallback(expiringCallbackExecutor, expiringCallbackCheckOffset)
    end

end

function CenterScreenAnnounce:InitializeWipeAnimation(container, timelineTemplate, timelineMemberKey, stopHandler, expiringCallbackCheckOffset, expiringCallbackExecutor, wipeIn, wipeOut)
    self:InitializeLineAnimation(container, timelineTemplate, timelineMemberKey, stopHandler, expiringCallbackCheckOffset, expiringCallbackExecutor)

    local timeline = container[timelineMemberKey]
    local wipeInAnim = timeline:GetAnimation(1)
    wipeInAnim:SetHandler("OnPlay", wipeIn)

    local wipeOutAnim = timeline:GetAnimation(2)
    wipeOutAnim:SetHandler("OnPlay", wipeOut)
end

local WAIT_INTERVAL_SECONDS = 0.5
local NO_WAIT_INTERVAL_SECONDS = 0

do
    local handlers = ZO_CenterScreenAnnounce_GetHandlers()
    local queueableHandlers = ZO_CenterScreenAnnounce_GetQueueableHandlers()

    function CenterScreenAnnounce:OnCenterScreenEvent(eventId, ...)
        if handlers[eventId] then
            if queueableHandlers[eventId] then
                local timeNowSeconds = GetFrameTimeMilliseconds() / 1000 
                local waitingQueueData = CENTER_SCREEN_ANNOUNCE:GetWaitingQueueEventData(eventId)
                if waitingQueueData then
                    local conditions = queueableHandlers[eventId].conditionParameters or {}
                    local passConditions = true
                    for k,condition in ipairs(conditions) do
                        if waitingQueueData.eventData[condition] ~= select(condition, ...) then
                            passConditions = false
                            break
                        end
                    end
                    if passConditions then
                        local updateParametersTable = queueableHandlers[eventId].updateParameters
                        if updateParametersTable then
                            for i,entry in pairs(updateParametersTable) do
                                waitingQueueData.eventData[entry] = select(entry, ...)
                            end
                        end
                        waitingQueueData.nextUpdateTimeSeconds = timeNowSeconds + queueableHandlers[eventId].updateTimeDelaySeconds
                        return
                    end
                end

                local data = 
                {
                    eventId = eventId,
                    eventData = { ... },
                    nextUpdateTimeSeconds = timeNowSeconds + queueableHandlers[eventId].updateTimeDelaySeconds
                }
                table.insert(self.m_waitingQueue, data)
                CENTER_SCREEN_ANNOUNCE.waitingQueueController:SetHandler("OnUpdate", CENTER_SCREEN_ANNOUNCE.m_onWaitingUpdateHandler)
            else
                CENTER_SCREEN_ANNOUNCE:AddMessage(eventId, handlers[eventId](...))
            end
        end
    end

    function CenterScreenAnnounce:Initialize(control)
        self.m_control = control
        control.m_object = self

        self.m_displayQueue = {}
        self.m_waitingQueue = {}
        self.m_activeSmallTextLines = {}
        self.allowedCategories = {}
        self.m_activeLineCount = 0
        self.m_hasActiveBar = false
        self.m_displayMode = CSA_INACTIVE
        self.m_largeTextContainer = control:GetNamedChild("LargeTextContainer")
        self.m_largeText = self.m_largeTextContainer:GetNamedChild("Text")
        self.m_smallCombinedText = self.m_largeText:GetNamedChild("Combined")    
        self.m_smallCombinedIcon = self.m_smallCombinedText:GetNamedChild("Icon")
        self.m_smallCombinedIconBG = self.m_smallCombinedText:GetNamedChild("IconBG")
        self.m_smallCombinedIconFrame = self.m_smallCombinedText:GetNamedChild("IconFrame")
        self.m_nextQueueIndex = 1

        self.longformBreakdownContainer = self.m_largeText:GetNamedChild("RaidCompleteText")
        self.breakdownLabel1 = self.longformBreakdownContainer:GetNamedChild("TimeAmount")
        self.breakdownLabel2 = self.longformBreakdownContainer:GetNamedChild("ScoreAmount")
        self.breakdownLabel3 = self.longformBreakdownContainer:GetNamedChild("VitalityAmount")
        self.breakdownIconLabel = self.longformBreakdownContainer:GetNamedChild("VitalityPercent")
        self.breakdownIcon = self.longformBreakdownContainer:GetNamedChild("VitalityIcon")

        self.waitingQueueController = self.m_largeTextContainer

        -- Recent message handler, using a 250 ms expiry delay
        self.m_recentMessages = ZO_RecentMessages:New(250)

        local function OnFadeOutComplete(timeline, completedPlayback)
            if(not completedPlayback) then return end

            local control = timeline.m_control
			local skipDisplayNext = true
            self:ReleaseLine(control, skipDisplayNext)
            self:UpdateDisplay(control) -- passing in the control whose animation just finished...yes, it's already been released
        end

        local function OnSmallLineTranslateComplete(timeline, completedPlayback)
            if(not completedPlayback) then return end

            local control = timeline.m_control
            if(self:IsTopLine(control)) then
				self:CallExpiringCallback(control)
                local offset = zo_clamp(GetFrameTimeMilliseconds() - control.m_acquisitionTime, 0, 2500)
                control.m_fadeOutTimeline:PlayFromStart(offset)
            end
        end 

        local function OnSmallTextLineCheckNextEvent(timeline, offset)
            self.m_lastSmallLineMovedOutOfTheWay = true
            self:UpdateDisplay(timeline.m_control, true)
        end

        local function SetupWipeIn(animation, container)
            container:ClearAnchors()
            container:SetAnchor(TOPLEFT, control, TOPLEFT, -560, 0)
        end

        local function SetupWipeOut(animation, container)
            container:ClearAnchors()
            container:SetAnchor(TOPRIGHT, control, TOPRIGHT, 560, 0)
        end

        self:InitializeWipeAnimation(self.m_largeTextContainer, "CenterScreenLargeText", "m_timeline", OnFadeOutComplete, DEFAULT_FADE_OUT_TIME, CallExpiringCallbackTimeline, SetupWipeIn, SetupWipeOut)
    
        local function SmallLineFactory(line)
            self:InitializeLineAnimation(line, "CenterScreenSmallTextFadeIn", "m_fadeInTimeline")
            self:InitializeLineAnimation(line, "CenterScreenSmallTextFadeOut", "m_fadeOutTimeline", OnFadeOutComplete)
            self:InitializeLineAnimation(line, "CenterScreenSmallTextTranslate", "m_translateTimeline", OnSmallLineTranslateComplete)

            line.m_translateTimeline:InsertCallback(OnSmallTextLineCheckNextEvent, 500)

            return line
        end

        local function SmallLineReset(line)
            line.m_key = nil
        end

        local function SmallLineAcquire(line)
            line.m_acquisitionTime = GetFrameTimeMilliseconds()
            line:SetFont(IsInGamepadPreferredMode() and SMALL_TEXT_FONT_GAMEPAD or SMALL_TEXT_FONT_KEYBOARD)
        end

        self.m_pool = ZO_ControlPool:New("ZO_CenterScreenAnnounceSmallTextTemplate", control)
        self.m_pool:SetCustomFactoryBehavior(SmallLineFactory)
        self.m_pool:SetCustomResetBehavior(SmallLineReset)
        self.m_pool:SetCustomAcquireBehavior(SmallLineAcquire)
        self.MAX_SMALL_TEXT_LINES = 5

        local testLine, testKey = self.m_pool:AcquireObject()
        testLine:SetFont(SMALL_TEXT_FONT_KEYBOARD)
        self.INITIAL_LINE_OFFSET_KEYBOARD = (testLine:GetFontHeight() + SMALL_TEXT_SPACING_KEYBOARD) * self.MAX_SMALL_TEXT_LINES
        testLine:SetFont(SMALL_TEXT_FONT_GAMEPAD)
        self.INITIAL_LINE_OFFSET_GAMEPAD = (testLine:GetFontHeight() + SMALL_TEXT_SPACING_GAMEPAD) * self.MAX_SMALL_TEXT_LINES
        self.m_pool:ReleaseObject(testKey)

        self.m_nextUpdateTimeSeconds = 0

        local function OnUpdate(control, timeNow)
            if timeNow > self.m_nextUpdateTimeSeconds then
                self.m_nextUpdateTimeSeconds = timeNow + 0.02
                self:TryDisplayingNextQueuedMessage()
            end
        end

        local handlers = ZO_CenterScreenAnnounce_GetHandlers()
        local function OnUpdateWaiting(control, timeNow)
            for i,entry in ipairs(self.m_waitingQueue) do
                if timeNow > entry.nextUpdateTimeSeconds then
                    local eventId = entry.eventId
                    table.remove(self.m_waitingQueue, i)
                    CENTER_SCREEN_ANNOUNCE:AddMessage(eventId, handlers[eventId](unpack(entry.eventData)))
                end
            end

            if #self.m_waitingQueue == 0 then
                self.waitingQueueController:SetHandler("OnUpdate", nil)
            end
        end

        self.m_onUpdateHandler = OnUpdate
        self.m_onWaitingUpdateHandler = OnUpdateWaiting

        PLAYER_PROGRESS_BAR:RegisterCallback("Show", function()
            --if the announcement has begun fading out ("expiring") before the bar even shows, we don't need to hold
            if(PLAYER_PROGRESS_BAR:GetOwner() == CENTER_SCREEN_ANNOUNCE and self.m_displayMode ~= CSA_EVENT_NO_TEXT and self.m_largeTextContainer.m_timeline.beforeExpiring) then
                PLAYER_PROGRESS_BAR:SetHoldBeforeFadeOut(true)
            end
        end)

        PLAYER_PROGRESS_BAR:RegisterCallback("Complete", function()
            self.m_hasActiveBar = false
            self:CheckNowInactive()
        end)

        local function BarParamFactory(pool)
            return CenterScreenPlayerProgressBarParams:New()
        end

        local function BarParamReset(params)
            params:Reset()
            params.key = nil
        end

        self.m_barParamsPool = ZO_ObjectPool:New(BarParamFactory, BarParamReset)

        self:ApplyStyle() -- Setup initial visual style based on current mode.
        control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)

        for event in pairs(handlers) do
            control:RegisterForEvent(event, function(eventId, ...) self:OnCenterScreenEvent(eventId, ...) end)
        end
    end
end

local function AnchorIconToText(iconControl, textControl)
    -- Dynamically anchor the icon to the start of the text
    local textWidth = textControl:GetTextWidth()
    local lineWidth = textControl:GetWidth()
    local centeringOffset = (lineWidth - textWidth) / 2

    iconControl:ClearAnchors()
    iconControl:SetAnchor(RIGHT, textControl, LEFT, centeringOffset - 10, 0)            
end

function CenterScreenAnnounce:ApplyStyle()
    ApplyTemplateToControl(self.m_control, ZO_GetPlatformTemplate("ZO_CenterScreenAnnounce"))
    ApplyTemplateToControl(self.m_largeTextContainer, ZO_GetPlatformTemplate("ZO_CenterScreenAnnounce_LargeTextContainer"))

    local isGamepad = IsInGamepadPreferredMode()
    local smallFont = isGamepad and SMALL_TEXT_FONT_GAMEPAD or SMALL_TEXT_FONT_KEYBOARD
    local smallLines = self.m_pool:GetActiveObjects()
    for _, smallLine in pairs(smallLines) do
        smallLine:SetFont(smallFont)
    end

    local iconControl = self.m_smallCombinedIcon
    if not iconControl:IsHidden() then
        AnchorIconToText(iconControl, self.m_smallCombinedText)
    end

    self.m_smallCombinedIconFrame:SetTexture(isGamepad and "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame64.dds" or "EsoUI/Art/ActionBar/abilityFrame64_up.dds")
end

function CenterScreenAnnounce:OnGamepadPreferredModeChanged()
    self:ApplyStyle()
end

function CenterScreenAnnounce:IsInactive()
    return self.m_displayMode == CSA_INACTIVE
end

function CenterScreenAnnounce:CreateBarParams(...)
    local barParams, key = self.m_barParamsPool:AcquireObject()
    barParams.key = key
    barParams:Set(...)
    return barParams
end

function CenterScreenAnnounce:CanDisplayMessage(category)
    if SYSTEMS:GetObject("craftingResults"):HasEntries() then
        return false
    end
    if self.m_displayMode == CSA_INACTIVE then return true end
    if category == CSA_EVENT_SMALL_TEXT and self.m_displayMode == category then
        return self.m_lastSmallLineMovedOutOfTheWay and (#self.m_activeSmallTextLines < self.MAX_SMALL_TEXT_LINES)
    end
    
    return false
end

function CenterScreenAnnounce:GetWaitingQueueEventData(eventId)
    for i,entry in pairs(self.m_waitingQueue) do
        if entry.eventId == eventId then
            return entry
        end
    end

    return nil
end

local messagePriorities = {}

function CenterScreenAnnounce:GetPriority(eventId)
    return messagePriorities[eventId] or 1
end

function CenterScreenAnnounce:CreateMessagePayload(eventId, category, queuedOrder, ...)
    local priority = self:GetPriority(eventId)
    local eventData = { ... }
    eventData.priority = priority
    eventData.category = category
    eventData.length = select("#", ...)
    eventData.queuedOrder = queuedOrder

    return priority, eventData
end

function CenterScreenAnnounce:QueueMessage(eventId, category, ...)
    --Delay choosing the next message to show by WAIT_INTERVAL_SECONDS each time a new message comes in to stabilize a bit
    local timeNowSeconds = GetFrameTimeMilliseconds() / 1000
    local shouldQueueImmediately = select(ARG_INDEX_QUEUE_IMMEDIATELY, ...)

    if shouldQueueImmediately then
        self:DisplayMessage(category, ...)

        if self.m_currentMsg ~= nil then
            local reinsertStompedMsg = select(ARG_INDEX_REINSERT_STOMPED_MESSAGE, ...)
            if reinsertStompedMsg then
                --If we are interrupting a message, lets put the current message back in the queue so it can come back 
                --up when were done with the immediate message that is interrupting.
                table.insert(self.m_displayQueue, 1, self.m_currentMsg)
            end
            self.m_currentMsg = nil
        end

        return
    end

    self.m_control:SetHandler("OnUpdate", self.m_onUpdateHandler)
    
    local waitOffset = shouldQueueImmediately and NO_WAIT_INTERVAL_SECONDS or WAIT_INTERVAL_SECONDS
    self.m_nextUpdateTimeSeconds = timeNowSeconds + waitOffset

    local priority, data = self:CreateMessagePayload(eventId, category, self.m_nextQueueIndex, ...)
    table.insert(self.m_displayQueue, data)
    self.m_nextQueueIndex = self.m_nextQueueIndex + 1
    self.m_isQueueDirty = true
end

local function SortEventData(left, right)
    if(left.priority ~= right.priority) then
        return left.priority > right.priority
    else
        local leftBarParams = left[ARG_INDEX_BAR_PARAMS]
        local rightBarParams = right[ARG_INDEX_BAR_PARAMS]
        if(leftBarParams ~= nil and rightBarParams ~= nil) then
            if(leftBarParams.startLevel ~= rightBarParams.startLevel) then
                return leftBarParams.startLevel < rightBarParams.startLevel
            else
                if(leftBarParams.start ~= rightBarParams.start) then
                    return leftBarParams.start < rightBarParams.start
                else
                    if(leftBarParams.stop ~= rightBarParams.stop) then
                        return leftBarParams.stop < rightBarParams.stop
                    else
                        return false
                    end
                end
            end
        elseif (left.queuedOrder ~= right.queuedOrder) then
            return left.queuedOrder < right.queuedOrder
        else
            return false
        end
    end
end

function CenterScreenAnnounce:SortQueue()
    local maxBarTypePriorities = {}
    for _, eventData in ipairs(self.m_displayQueue) do
        local barParams = eventData[ARG_INDEX_BAR_PARAMS]
        if(barParams) then
            local barType = barParams:GetParams()
            local currentMaxPriority = maxBarTypePriorities[barType]
            if(currentMaxPriority == nil or eventData.priority > currentMaxPriority) then
                maxBarTypePriorities[barType] = eventData.priority
            end
        end
    end

    for _, eventData in ipairs(self.m_displayQueue) do
        local barParams = eventData[ARG_INDEX_BAR_PARAMS]
        if(barParams) then
            local barType = barParams:GetParams()
            eventData.priority = maxBarTypePriorities[barType]
        end
    end

    table.sort(self.m_displayQueue, SortEventData)
end

function CenterScreenAnnounce:GetNumQueuedEvents()
    return #self.m_displayQueue
end

function CenterScreenAnnounce:PeekNextEvent()
    return self.m_displayQueue[1]
end

function CenterScreenAnnounce:DoesNextEventHaveBar()
    local nextEvent = self:PeekNextEvent()
    if(nextEvent) then
        local params = nextEvent[ARG_INDEX_BAR_PARAMS]
        return params ~= nil
    end
    return false
end

function CenterScreenAnnounce:DoesNextEventHaveBarType(barType)
    local nextEvent = self:PeekNextEvent()
    if(nextEvent) then
        local params = nextEvent[ARG_INDEX_BAR_PARAMS]
        if(params and barType == params.type) then
            return true
        end
    end
    return false
end

function CenterScreenAnnounce:HasBarTypeInQueue(barType)
    for _, event in ipairs(self.m_displayQueue) do
        local currentParams = event[ARG_INDEX_BAR_PARAMS]
        if(currentParams and barType == currentParams.type) then
            return true
        end
    end
    return false
end

function CenterScreenAnnounce:RemoveNextEvent()
    return table.remove(self.m_displayQueue, 1)
end

function CenterScreenAnnounce:DisplayNextQueuedEvent()
    local nextEvent = self:RemoveNextEvent()
    self.m_currentMsg = nextEvent
    self:DisplayMessage(nextEvent.category, unpack(nextEvent, 1, nextEvent.length))
    self.m_control:SetHandler("OnUpdate", nil)
end

function CenterScreenAnnounce:MoveSmallTextLinesUp(completedLine)
    self.m_lastSmallLineMovedOutOfTheWay = (#self.m_activeSmallTextLines == 0)

    local nextTop = completedLine:GetTop()
    for index, line in ipairs(self.m_activeSmallTextLines) do
		local distanceFromDestination = line:GetTop() - nextTop
		nextTop = nextTop + line.m_lineHeight

		local timeline = line.m_translateTimeline
		timeline:Stop()
		timeline:GetAnimation(1):SetTranslateDeltas(0, -distanceFromDestination)
		timeline:PlayFromStart()
    end
end

function CenterScreenAnnounce:EndAllSmallLines()
    for index, line in ipairs(self.m_activeSmallTextLines) do
        self.m_activeLineCount = self.m_activeLineCount - 1
		line.m_translateTimeline:Stop()
        line.m_fadeOutTimeline:Stop()
        line:SetHandler("OnUpdate", nil)
        self.m_pool:ReleaseObject(line.m_key)
    end
    ZO_ClearNumericallyIndexedTable(self.m_activeSmallTextLines)
end

function CenterScreenAnnounce:IsTopLine(line)
    return (self.m_activeSmallTextLines[1] == line)
end

function CenterScreenAnnounce:TryDisplayingNextQueuedMessage()
    if(self.m_isQueueDirty) then
        self:SortQueue()
        self.m_isQueueDirty = false
    end

    local nextEvent = self:PeekNextEvent()
    if(nextEvent and self:CanDisplayMessage(nextEvent.category)) then
        self:DisplayNextQueuedEvent()
    end
end

function CenterScreenAnnounce:UpdateDisplay(completedLine, skipSmallBlockMove)
    if(self.m_displayMode == CSA_EVENT_SMALL_TEXT and not skipSmallBlockMove) then
        self:MoveSmallTextLinesUp(completedLine)
    end

    self:TryDisplayingNextQueuedMessage()
end

function CenterScreenAnnounce:ReleaseLine(completedLine, skipDisplayNext)
    self.m_activeLineCount = self.m_activeLineCount - 1
    if(completedLine.m_key) then
        completedLine:SetHandler("OnUpdate", nil)

        self.m_pool:ReleaseObject(completedLine.m_key)

        assert(self.m_activeSmallTextLines[1] == completedLine)
        table.remove(self.m_activeSmallTextLines, 1)
    elseif completedLine == self.m_largeTextContainer then
        self.m_largeText:SetHandler("OnUpdate", nil)
        self.m_smallCombinedText:SetHandler("OnUpdate", nil)
    end

    self:CheckNowInactive(skipDisplayNext)
end

function CenterScreenAnnounce:CheckNowInactive(skipDisplayNext)
    if(self.m_activeLineCount == 0 and self.m_hasActiveBar == false) then
        self.m_displayMode = CSA_INACTIVE
		if not skipDisplayNext then
			self:TryDisplayingNextQueuedMessage()
		end
    end
end

function CenterScreenAnnounce:ShouldRejectCategory(category)
    return self.allowedCategories[category] == false
end

function CenterScreenAnnounce:SetRejectCategory(category, reject)
    self.allowedCategories[category] = not reject
end

local TrySettingDynamicText
do
    local function SetDynamicTextHelper(label)
        label:SetText(label.dynamicTextFunction())
    end

    function TrySettingDynamicText(label, textOrFunction)
        if type(textOrFunction) == "function" then
            label.dynamicTextFunction = textOrFunction
            label:SetHandler("OnUpdate", SetDynamicTextHelper)
        else
            label:SetText(textOrFunction)
            label:SetHandler("OnUpdate", nil)
        end
    end
end

local setupFunctions =
{
    [CSA_EVENT_SMALL_TEXT] = function(self, ...)
        self.m_lastSmallLineMovedOutOfTheWay = false
        local line, poolKey = self.m_pool:AcquireObject()
        line.m_key = poolKey

        TrySettingDynamicText(line, select(ARG_INDEX_MESSAGE, ...))
        line.m_lineHeight = line:GetTextHeight() + (IsInGamepadPreferredMode() and SMALL_TEXT_SPACING_GAMEPAD or SMALL_TEXT_SPACING_KEYBOARD)

        -- check for an overriding lifespan coming from the handlers, if not stick with the default        
        local fadeOutAnimation = line.m_fadeOutTimeline:GetAnimation(1)
        local lifespan = select(ARG_INDEX_LIFESPAN, ...)

        if(lifespan) then
            line.m_fadeOutTimeline:SetAnimationOffset(fadeOutAnimation, lifespan)
            line.m_fadeOutTimeline:SetCallbackOffset(CallExpiringCallbackTimeline, lifespan)
        else
            line.m_fadeOutTimeline:SetAnimationOffset(fadeOutAnimation, DEFAULT_FADE_OUT_TIME)
            line.m_fadeOutTimeline:SetCallbackOffset(CallExpiringCallbackTimeline, DEFAULT_FADE_OUT_TIME)
        end

        line.m_fadeInTimeline:PlayFromStart()
        line:ClearAnchors()
        
        local numSmallText = #self.m_activeSmallTextLines + 1
        self.m_activeSmallTextLines[numSmallText] = line

        local initialLineOffset = IsInGamepadPreferredMode() and self.INITIAL_LINE_OFFSET_GAMEPAD or self.INITIAL_LINE_OFFSET_KEYBOARD
        local initialAnchorOffset = initialLineOffset
        local translateAnimationOffset = -initialLineOffset
        local translateTimeline = line.m_translateTimeline

        if(numSmallText > 1) then
            local totalLinesHeight = 0
            for i = 1, numSmallText - 1 do -- don't include the latest line, we don't care about its height
                totalLinesHeight = totalLinesHeight + self.m_activeSmallTextLines[i].m_lineHeight
            end

            if(totalLinesHeight >= initialAnchorOffset) then
                translateAnimationOffset = nil
                initialAnchorOffset = totalLinesHeight
            else
                translateAnimationOffset = -(initialLineOffset - totalLinesHeight)
            end
        end

        line:SetAnchor(TOP, nil, TOP, 0, initialAnchorOffset) -- lines always appear at the bottom and scroll up

        if(translateAnimationOffset ~= nil) then
            translateTimeline:GetAnimation(1):SetTranslateDeltas(0, translateAnimationOffset)
            translateTimeline:PlayFromStart()
        end

        self.longformBreakdownContainer:SetHidden(true)

        return line
    end,

    [CSA_EVENT_LARGE_TEXT] = function(self, ...)
        TrySettingDynamicText(self.m_largeText, select(ARG_INDEX_MESSAGE, ...))
        TrySettingDynamicText(self.m_smallCombinedText, "")
        
        local showImmediately = select(ARG_INDEX_SHOW_IMMEDIATELY, ...)
        -- check for an overriding lifespan coming from the handlers, if not stick with the default        
        local lifespan = select(ARG_INDEX_LIFESPAN, ...)
        lifespan = lifespan or DEFAULT_FADE_OUT_TIME

        --We always want to make sure the fadeout happens at the end of the lifespan of the current
        --message even if that message shows immediately.
        local fadeOutAnimation = self.m_largeTextContainer.m_timeline:GetAnimation(2)
        self.m_largeTextContainer.m_timeline:SetAnimationOffset(fadeOutAnimation, lifespan)
        self.m_largeTextContainer.m_timeline:SetCallbackOffset(CallExpiringCallbackTimeline, lifespan)

        if not showImmediately then
            self.m_largeTextContainer.m_timeline:PlayFromStart()
            self.m_largeTextContainer.m_timeline.beforeExpiring = true
        else
            self:EndAllSmallLines()
            local endTime = lifespan + GetFrameTimeMilliseconds()
            local function UpdateShowAnnouncementTime(control, timeS)
                local timeLeftMS = endTime - (timeS * 1000)
                if timeLeftMS <= 0 then
                    self:CallExpiringCallback(control)
                    control:SetDimensions(ZO_MIN_CSA_SCROLL_WIDTH, ZO_MAX_CSA_SCROLL_HEIGHT)
                    self:ReleaseLine(control)
                    control:SetHandler("OnUpdate", nil)
                end
            end

            self.m_largeTextContainer:SetHandler("OnUpdate", UpdateShowAnnouncementTime)
            self.m_largeTextContainer:SetDimensions(ZO_MAX_CSA_SCROLL_WIDTH, ZO_MAX_CSA_SCROLL_HEIGHT)
        end

        self.m_smallCombinedIcon:SetHidden(true)
        self.longformBreakdownContainer:SetHidden(true)

        return self.m_largeTextContainer
    end,

    [CSA_EVENT_COMBINED_TEXT] = function(self, ...)
        local smallText = self.m_smallCombinedText
        TrySettingDynamicText(self.m_largeText, select(ARG_INDEX_MESSAGE, ...))
        TrySettingDynamicText(smallText, select(ARG_INDEX_COMBINED_MESSAGE, ...))

        -- check for an overriding lifespan coming from the handlers, if not stick with the default        
        local fadeOutAnimation = self.m_largeTextContainer.m_timeline:GetAnimation(2)
        local lifespan = select(ARG_INDEX_LIFESPAN, ...)

        if(lifespan) then
            self.m_largeTextContainer.m_timeline:SetAnimationOffset(fadeOutAnimation, lifespan)
            self.m_largeTextContainer.m_timeline:SetCallbackOffset(CallExpiringCallbackTimeline, lifespan)
        else
            self.m_largeTextContainer.m_timeline:SetAnimationOffset(fadeOutAnimation, DEFAULT_FADE_OUT_TIME)
            self.m_largeTextContainer.m_timeline:SetCallbackOffset(CallExpiringCallbackTimeline, DEFAULT_FADE_OUT_TIME)
        end

        self.m_largeTextContainer.m_timeline:PlayFromStart()
        self.m_largeTextContainer.m_timeline.beforeExpiring = true

        -- NOTE: Combined text is the only thing that uses icons for now...and only on the small text label.
        local icon = select(ARG_INDEX_ICON, ...)
        local iconControl = self.m_smallCombinedIcon
        iconControl:SetHidden(icon == nil)
        iconControl:GetNamedChild("Frame"):SetHidden(select(ARG_INDEX_SUPPRESS_FRAME, ...) == CSA_OPTION_SUPPRESS_ICON_FRAME)
        
        if(icon) then
            iconControl:SetTexture(icon)
            AnchorIconToText(iconControl, smallText)
        end

        local iconBG = select(ARG_INDEX_ICON_BG, ...)
        self.m_smallCombinedIconBG:SetHidden(iconBG == nil)

        if(iconBG) then
            self.m_smallCombinedIconBG:SetTexture(iconBG)
        end

        self.longformBreakdownContainer:SetHidden(true)

        return self.m_largeTextContainer
    end,

    [CSA_EVENT_NO_TEXT] = function(self, ...)
        return nil
    end,

    [CSA_EVENT_RAID_COMPLETE_TEXT] = function(self,...)
        TrySettingDynamicText(self.m_largeText, select(ARG_INDEX_MESSAGE, ...))
        TrySettingDynamicText(self.m_smallCombinedText, "")
        local raidArgumentTable = select(ARG_INDEX_COMBINED_MESSAGE, ...)
        TrySettingDynamicText(self.breakdownLabel1, raidArgumentTable[ARG_BREAKDOWN_INDEX_TIME])
        TrySettingDynamicText(self.breakdownLabel2, raidArgumentTable[ARG_BREAKDOWN_INDEX_SCORE])
        TrySettingDynamicText(self.breakdownLabel3, raidArgumentTable[ARG_BREAKDOWN_INDEX_VITALITY_AMOUNT])
        TrySettingDynamicText(self.breakdownIconLabel, raidArgumentTable[ARG_BREAKDOWN_INDEX_VITALITY_PERCENT])

        if raidArgumentTable[ARG_BREAKDOWN_INDEX_VITALITY_AMOUNT] == 0 then
            self.breakdownIconLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
            self.breakdownIcon:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        else
            self.breakdownIconLabel:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
            self.breakdownIcon:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        end

        if raidArgumentTable[ARG_BREAKDOWN_INDEX_SHOW_AS_ERROR] then
            self.breakdownLabel1:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            self.breakdownLabel1:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        end

        local fadeOutAnimation = self.m_largeTextContainer.m_timeline:GetAnimation(2)
        local lifespan = select(ARG_INDEX_LIFESPAN, ...)

        if lifespan then
            self.m_largeTextContainer.m_timeline:SetAnimationOffset(fadeOutAnimation, lifespan)
            self.m_largeTextContainer.m_timeline:SetCallbackOffset(CallExpiringCallbackTimeline, lifespan)
        else
            self.m_largeTextContainer.m_timeline:SetAnimationOffset(fadeOutAnimation, DEFAULT_FADE_OUT_TIME)
            self.m_largeTextContainer.m_timeline:SetCallbackOffset(CallExpiringCallbackTimeline, DEFAULT_FADE_OUT_TIME)
        end

        self.m_largeTextContainer.m_timeline:PlayFromStart()
        self.m_largeTextContainer.m_timeline.beforeExpiring = true

        self.m_smallCombinedIcon:SetHidden(true)
        self.longformBreakdownContainer:SetHidden(false)

        return self.m_largeTextContainer
    end,
}

function CenterScreenAnnounce:SetExpiringCallback(line, callback)
    line.m_expiringCallback = callback
end

function CenterScreenAnnounce:CallExpiringCallback(control)
    if(control.m_expiringCallback) then
        control.m_expiringCallback()
        control.m_expiringCallback = nil
    end
    if(control.m_timeline) then
        control.m_timeline.beforeExpiring = false
    end
    if(PLAYER_PROGRESS_BAR:GetOwner() == self) then
        PLAYER_PROGRESS_BAR:SetHoldBeforeFadeOut(false)
    end
end

function CenterScreenAnnounce:DisplayMessage(category, ...)
    if self:ShouldRejectCategory(category) then
        return
    end

    local setupFunction = setupFunctions[category]
    if(setupFunction) then
        self.m_displayMode = category

        local displayLine = setupFunction(self, ...)
        if(displayLine) then
            self:SetExpiringCallback(displayLine, select(ARG_INDEX_EXPIRING_CALLBACK, ...))
            self.m_activeLineCount = self.m_activeLineCount + 1
        end

        local soundId = select(ARG_INDEX_SOUND, ...)
        if(soundId) then PlaySound(soundId) end

        local barParams = select(ARG_INDEX_BAR_PARAMS, ...)
        if(barParams and (category == CSA_EVENT_LARGE_TEXT or category == CSA_EVENT_COMBINED_TEXT or category == CSA_EVENT_NO_TEXT)) then
            local barType, startLevel, start, stop, sound = barParams:GetParams()
            if stop - start > 0 or barParams.showNoGain then
                self.m_hasActiveBar = true
                PLAYER_PROGRESS_BAR:ShowIncrease(barType, startLevel, start, stop, sound, category == CSA_EVENT_NO_TEXT and 0 or 500, self)
            end
            self.m_barParamsPool:ReleaseObject(barParams.key)
        end
    end
end

local ALLOWED_EVENTS_WHILE_CRAFTING = 
{
    [EVENT_QUEST_ADDED] = true,
    [EVENT_QUEST_CONDITION_COUNTER_CHANGED] = true,
    [EVENT_QUEST_ADVANCED] = true,
    [EVENT_QUEST_COMPLETE] = true,
    [EVENT_OBJECTIVE_COMPLETED] = true,
    [EVENT_QUEST_OPTIONAL_STEP_ADVANCED] = true,
    [EVENT_ACHIEVEMENT_AWARDED] = true,
    [EVENT_BROADCAST] = true,
}

function CenterScreenAnnounce:AddMessage(eventId, category, ...)
    if(category ~= nil) then
        local barParams = select(ARG_INDEX_BAR_PARAMS, ...)
        if(category == CSA_EVENT_NO_TEXT and barParams == nil) then
            return
        end

        -- prevent unwanted announcements from appearing when the user is crafting
        if ZO_CraftingUtils_IsCraftingWindowOpen() and not ALLOWED_EVENTS_WHILE_CRAFTING[eventId] then
            return
        end

        -- prevent unwanted announcements that have been specified as supressed
        if self:GetSupressAnnouncementByEvent(eventId) then
            return
        end

        -- Checking the recency of the message should be sufficient for duplicate messages
        -- Otherwise, this needs to combine the full message text into a single string and check the recency of that.
        -- MLR: Changing to use the Combined message when available because when multiple similar messages come in on the same frame,
        -- the recency sees them as the same message and only the first will display.
        local message = select(ARG_INDEX_COMBINED_MESSAGE, ...) or select(ARG_INDEX_MESSAGE, ...)

        if(message == nil or self.m_recentMessages:ShouldDisplayMessage(message)) then
            self:QueueMessage(eventId, category, ...)
        else
            local expiringCallback = select(ARG_INDEX_EXPIRING_CALLBACK, ...)
            if expiringCallback then
                expiringCallback()
            end
        end
    end
end

function CenterScreenAnnounce:SupressAnnouncementByEvent(eventId)
    if not self.suppressAnnouncements then
        self.suppressAnnouncements = {}
    end

    if not self.suppressAnnouncements[eventId] then
        self.suppressAnnouncements[eventId] = 0
    end

    self.suppressAnnouncements[eventId] = self.suppressAnnouncements[eventId] + 1
end

function CenterScreenAnnounce:GetSupressAnnouncementByEvent(eventId)
    if self.suppressAnnouncements and self.suppressAnnouncements[eventId] then
        return self.suppressAnnouncements[eventId] > 0
    end

    return false
end

function CenterScreenAnnounce:ResumeAnnouncementByEvent(eventId)
    if self.suppressAnnouncements and self.suppressAnnouncements[eventId] then
        self.suppressAnnouncements[eventId] = self.suppressAnnouncements[eventId] - 1
    end
end

-- Exposed so that external code can add custom events with appropriate priorities
local nextAutoPriority = 1
function ZO_CenterScreenAnnounce_SetEventPriority(eventId, priority)
    if(priority == nil) then
        priority = nextAutoPriority
        nextAutoPriority = nextAutoPriority + 1
    end
    
    messagePriorities[eventId] = priority
end

function ZO_CenterScreenAnnounce_Initialize(self)
    CENTER_SCREEN_ANNOUNCE = CenterScreenAnnounce:New(self)

    ZO_CenterScreenAnnounce_InitializePriorities()
end