local DEFAULT_PRIORITY = 1

local CSA_OPTION_SUPPRESS_ICON_FRAME = true
local CSA_OPTION_QUEUE_IMMEDIATELY = true
local CSA_OPTION_SHOW_IMMEDIATELY = true

local CSA_LINE_TYPE_SMALL = 1
local CSA_LINE_TYPE_LARGE = 2
local CSA_LINE_TYPE_MAJOR = 3
local CSA_LINE_TYPE_COUNTDOWN = 4

ZO_MAX_CSA_SCROLL_WIDTH = 2184
ZO_MIN_CSA_SCROLL_WIDTH = 512
ZO_MAX_CSA_SCROLL_HEIGHT = 500

local ARG_BREAKDOWN_INDEX_SCORE = 1
local ARG_BREAKDOWN_INDEX_TIME = 2
local ARG_BREAKDOWN_INDEX_SHOW_AS_ERROR = 3
local ARG_BREAKDOWN_INDEX_VITALITY_AMOUNT = 4
local ARG_BREAKDOWN_INDEX_VITALITY_PERCENT = 5

local SMALL_TEXT_FONT_KEYBOARD = "ZoFontCenterScreenAnnounceSmall"
local SMALL_TEXT_FONT_GAMEPAD = "ZoFontGamepad42"

local COUNTDOWN_TEXT_FONT_KEYBOARD = "ZoFontCallout3"
local COUNTDOWN_TEXT_FONT_GAMEPAD = "ZoFontGamepadBold54"

local ROLLING_METER_TEXT_KEYBOARD = "ZoFontWinH2"
local ROLLING_METER_TEXT_GAMEPAD = "ZoFontGamepad42"

local SMALL_TEXT_SPACING_KEYBOARD = 0
local SMALL_TEXT_SPACING_GAMEPAD = 10

local MAJOR_TEXT_SPACING_KEYBOARD = 5
local MAJOR_TEXT_SPACING_GAMEPAD = 10

local DEFAULT_FADE_OUT_TIME_MS = 3500

local WAIT_INTERVAL_SECONDS = 0.5
local NO_WAIT_INTERVAL_SECONDS = 0

local BAR_PARAMS_WAIT_INTERVAL_MS = 500
local BAR_PARAMS_NO_WAIT_INTERVAL_MS = 0

local INITIAL_SMALL_LINE_OFFSET_KEYBOARD_Y = 100
local INITIAL_SMALL_LINE_OFFSET_GAMEPAD_Y = 110

local MAX_SMALL_LINE_FADE_OUT_TIME = 3400

local MAX_SMALL_TEXT_LINES = 4
local MAX_MAJOR_TEXT_LINES = 2

---------------------------------------------
-- Center Screen Player Progress Bar Params
---------------------------------------------

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
    self.triggeringEvent = nil
end

function CenterScreenPlayerProgressBarParams:Set(barType, startLevel, start, stop, sound, triggeringEvent)
    self.type = barType
    self.startLevel = startLevel
    self.start = start
    self.stop = stop
    self.sound = sound
end

function CenterScreenPlayerProgressBarParams:GetParams()
    return self.type, self.startLevel, self.start, self.stop, self.sound, self.triggeringEvent
end

function CenterScreenPlayerProgressBarParams:SetShowNoGain(showNoGain)
    self.showNoGain = showNoGain
end

function CenterScreenPlayerProgressBarParams:SetSound(sound)
    self.sound = sound
end

function CenterScreenPlayerProgressBarParams:SetTriggeringEvent(triggeringEvent)
    self.triggeringEvent = triggeringEvent
end

function CenterScreenPlayerProgressBarParams:GetTriggeringEvent()
    return self.triggeringEvent
end

---------------------------------------------
-- Center Screen Message Params
---------------------------------------------

ZO_CenterScreenMessageParams = ZO_InitializingObject:Subclass()

function ZO_CenterScreenMessageParams:Initialize()
    self:Reset()
end

function ZO_CenterScreenMessageParams:Reset()
    ZO_ClearTable(self)
    self.lifespanMS = DEFAULT_FADE_OUT_TIME_MS
    self.priority = DEFAULT_PRIORITY
end

function ZO_CenterScreenMessageParams:SetSound(sound)
    self.sound = sound
end

function ZO_CenterScreenMessageParams:GetSound()
    return self.sound
end

function ZO_CenterScreenMessageParams:SetText(mainText, secondaryText)
    self.mainText = mainText
    self.secondaryText = secondaryText
end

function ZO_CenterScreenMessageParams:GetMainText()
    return self.mainText
end

function ZO_CenterScreenMessageParams:GetSecondaryText()
    return self.secondaryText
end

function ZO_CenterScreenMessageParams:SetIconData(icon, iconBg, iconColor)
    self.icon = icon
    self.iconBg = iconBg
    self.iconColor = iconColor
end

function ZO_CenterScreenMessageParams:GetIconData()
    return self.icon, self.iconBg, self.iconColor
end

function ZO_CenterScreenMessageParams:SetLargeInformationIconData(icon)
    self.LargeInformationIcon = icon
end

function ZO_CenterScreenMessageParams:GetLargeInformationIconData()
    return self.LargeInformationIcon
end

function ZO_CenterScreenMessageParams:SetScryingProgressData(lastNumGoalsAchieved, numGoalsAchieved, numGoalsTotal)
    self.lastNumGoalsAchieved = lastNumGoalsAchieved
    self.numGoalsAchieved = numGoalsAchieved
    self.numGoalsTotal = numGoalsTotal
end

function ZO_CenterScreenMessageParams:GetScryingProgressData()
    return self.lastNumGoalsAchieved, self.numGoalsAchieved, self.numGoalsTotal
end

function ZO_CenterScreenMessageParams:SetRollingMeterProgressData(rollingMeterProgressData)
    self.rollingMeterProgressData = rollingMeterProgressData
end

function ZO_CenterScreenMessageParams:GetRollingMeterProgressData()
    return self.rollingMeterProgressData
end

function ZO_CenterScreenMessageParams:GetCustomAnimationTimeline()
    return self.customAnimationTimeline, self.customAnimationSetupCallback
end

function ZO_CenterScreenMessageParams:SetCustomAnimationTimeline(timeline, setupCallback)
    self.customAnimationTimeline = timeline
    self.customAnimationSetupCallback = setupCallback
end

function ZO_CenterScreenMessageParams:SetExpiringCallback(callback)
    self.expiringCallback = callback
end

function ZO_CenterScreenMessageParams:GetExpiringCallback()
    return self.expiringCallback
end

function ZO_CenterScreenMessageParams:SetBarParams(barParams)
    self.barParams = barParams
end

function ZO_CenterScreenMessageParams:GetBarParams()
    return self.barParams
end

function ZO_CenterScreenMessageParams:SetExternalHandleCallback(callback)
    self.externalHandleCallback = callback
end

function ZO_CenterScreenMessageParams:GetExternalHandleCallback()
    return self.externalHandleCallback
end

function ZO_CenterScreenMessageParams:SetLifespanMS(lifespanMS)
    self.lifespanMS = lifespanMS
end

function ZO_CenterScreenMessageParams:GetLifespanMS()
    return self.lifespanMS
end

function ZO_CenterScreenMessageParams:SetOnDisplayCallback(callback)
    self.onDisplayCallback = callback
end

function ZO_CenterScreenMessageParams:GetOnDisplayCallback()
    return self.onDisplayCallback
end

function ZO_CenterScreenMessageParams:MarkShowBackground()
    self.showBackground = true
end

function ZO_CenterScreenMessageParams:GetShowBackground()
    return self.showBackground
end

function ZO_CenterScreenMessageParams:MarkSuppressIconFrame()
    self.suppressIconFrame = CSA_OPTION_SUPPRESS_ICON_FRAME
end

function ZO_CenterScreenMessageParams:GetSuppressIconFrame()
    return self.suppressIconFrame
end

function ZO_CenterScreenMessageParams:MarkQueueImmediately(reinsertStompedMessage)
    self.queueImmediately = CSA_OPTION_QUEUE_IMMEDIATELY
    self.reinsertStompedMessage = reinsertStompedMessage
end

function ZO_CenterScreenMessageParams:GetQueueImmediately()
    return self.queueImmediately, self.reinsertStompedMessage
end

function ZO_CenterScreenMessageParams:MarkShowImmediately()
    self.showImmediately = CSA_OPTION_SHOW_IMMEDIATELY
end

function ZO_CenterScreenMessageParams:GetShowImmediately()
    return self.showImmediately
end

function ZO_CenterScreenMessageParams:GetMostUniqueMessage()
    return self.secondaryText or self.mainText
end

function ZO_CenterScreenMessageParams:SetCategory(category)
    self.category = category
end

function ZO_CenterScreenMessageParams:GetCategory()
    return self.category
end

--Can be used if a CSA needs a special implementation for its screen narration
function ZO_CenterScreenMessageParams:SetNarrationTextFunction(narrationFunction)
    self.narrationTextFunction = narrationFunction
end

function ZO_CenterScreenMessageParams:GetNarrationText()
    --If a narration text function has been set use that, otherwise grab the narration text using the default methods
    if self.narrationTextFunction then
        return self.narrationTextFunction(self)
    else
        local category = self.category
        if category == CSA_CATEGORY_SMALL_TEXT then
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetMostUniqueMessage())
        elseif category == CSA_CATEGORY_LARGE_TEXT then
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetMainText()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetSecondaryText()))
            return narrations
        elseif category == CSA_CATEGORY_NO_TEXT then
            --TODO XAR: Implement
        elseif category == CSA_CATEGORY_RAID_COMPLETE_TEXT then
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetMainText()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetSecondaryText()))
            local raidData = self:GetEndOfRaidData()
            if raidData then
                local finalScore = raidData[ARG_BREAKDOWN_INDEX_SCORE]
                if finalScore then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TRIAL_COMPLETE_FINAL_SCORE)))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(finalScore))
                end

                local totalTime = raidData[ARG_BREAKDOWN_INDEX_TIME]
                if totalTime then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TRIAL_COMPLETE_TOTAL_TIME)))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(totalTime))
                end

                local vitalityBonus = raidData[ARG_BREAKDOWN_INDEX_VITALITY_AMOUNT]
                if vitalityBonus then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TRIAL_COMPLETE_VITALITY_BONUS)))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(vitalityBonus))
                end

                local vitalityPercent = raidData[ARG_BREAKDOWN_INDEX_VITALITY_PERCENT]
                if vitalityPercent then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TRIAL_COMPLETE_REVIVES_USED)))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(vitalityPercent))
                end
            end
            return narrations
        elseif category == CSA_CATEGORY_MAJOR_TEXT then
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetMostUniqueMessage())
        elseif category == CSA_CATEGORY_COUNTDOWN_TEXT then
            --Countdown CSAs are narrated elsewhere so no need to do anything here
            return nil
        elseif category == CSA_CATEGORY_SCRYING_PROGRESS_TEXT then
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetMainText()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetSecondaryText()))
            local lastGoalsAchieved, goalsAchieved, goalsTotal = self:GetScryingProgressData()
            if goalsAchieved and goalsTotal then
                local progressionText = zo_strformat(SI_ANTIQUITIES_SCRYING_PROGRESS_NARRATION, goalsAchieved, goalsTotal)
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(progressionText))
            end
            return narrations
        elseif category == CSA_CATEGORY_ROLLING_METER_PROGRESS_TEXT then
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetMainText()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetSecondaryText()))
            local progressData = self:GetRollingMeterProgressData()
            if progressData then
                for _, progressEntry in ipairs(progressData) do
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(progressEntry.narrationDescription))
                end
            end
            return narrations
        elseif category == CSA_CATEGORY_ANIMATED_CONTROL then
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetMainText()))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self:GetSecondaryText()))
            return narrations
        elseif category == CSA_CATEGORY_EXTERNAL_HANDLE then
            --External handles do not need to narrate anything
            return nil
        else
            internalassert(false, "Unhandled CSA Category type")
        end
    end
end

function ZO_CenterScreenMessageParams:SetObjectPoolKey(key)
    self.key = key
end

function ZO_CenterScreenMessageParams:SetCSAType(csaType)
    self.csaType = csaType
    local priority = CENTER_SCREEN_ANNOUNCE:GetPriority(csaType)
    self:SetPriority(priority)
end

function ZO_CenterScreenMessageParams:GetCSAType()
    return self.csaType
end

function ZO_CenterScreenMessageParams:SetPriority(priority)
    self.priority = priority
end

function ZO_CenterScreenMessageParams:GetPriority()
    return self.priority
end

function ZO_CenterScreenMessageParams:SetQueuedOrder(queuedOrder)
    self.queuedOrder = queuedOrder
end

function ZO_CenterScreenMessageParams:GetQueuedOrder()
    return self.queuedOrder
end

function ZO_CenterScreenMessageParams:SetEndOfRaidData(endOfRaidData)
    self.endOfRaidData = endOfRaidData
end

function ZO_CenterScreenMessageParams:GetEndOfRaidData()
    return self.endOfRaidData
end

function ZO_CenterScreenMessageParams:MarkIsAvAEvent()
    self.avaEvent = true
end

function ZO_CenterScreenMessageParams:IsAvAEvent()
    return self.avaEvent
end

function ZO_CenterScreenMessageParams:CallExpiringCallback()
    local expiringCallback = self:GetExpiringCallback()
    if expiringCallback then
        expiringCallback()
    end
end

function ZO_CenterScreenMessageParams:PlaySound()
    local soundId = self:GetSound()
    if soundId then 
        PlaySound(soundId) 
    end
end

function ZO_CenterScreenMessageParams:ConvertOldParams(sound, message, combinedMessage, icon, iconBg, expiringCallback, barParams, lifespan, suppressFrame, queueImmediately, showImmediately, reinsertStompedMessage)
    self:SetSound(sound)
    self:SetText(message, combinedMessage)
    self:SetIconData(icon, iconBg)
    self:SetExpiringCallback(expiringCallback)
    self:SetBarParams(barParams)
    self:SetLifespanMS(lifespan)
    if suppressFrame then
        self:MarkSuppressIconFrame()
    end
    if queueImmediately then
        self:MarkQueueImmediately(reinsertStompedMessage)
    end
    if showImmediately then
        self:MarkShowImmediately()
    end
end

------------------------------------
-- Center Screen Announcement Line
------------------------------------

ZO_CenterScreenAnnouncementLine = ZO_InitializingCallbackObject:Subclass()

function ZO_CenterScreenAnnouncementLine:Initialize(control)
    self.control = control
    self:CreateTimelines()
    self.shouldCleanupMessageParams = true
end

function ZO_CenterScreenAnnouncementLine:Reset()
    -- only clean up message params if they are not being reinserted into the queue
    -- because the current message asked to resinsert stomped message
    if self.shouldCleanupMessageParams and self.messageParams then
        CENTER_SCREEN_ANNOUNCE:ReleaseMessageParams(self.messageParams)
    end
    self.messageParams = nil
    self.shouldCleanupMessageParams = true
    self.control:SetHandler("OnUpdate", nil)

    self.control:SetHidden(true)
    self.control:ClearAnchors()

    self.key = nil
end

function ZO_CenterScreenAnnouncementLine:OnAcquire()
    self.control:SetHidden(false)
    self:ApplyPlatformStyle()
end

function ZO_CenterScreenAnnouncementLine:SetMessageParams(messageParams)
    self.messageParams = messageParams
end

function ZO_CenterScreenAnnouncementLine:GetMessageParams()
    return self.messageParams
end

function ZO_CenterScreenAnnouncementLine:SetShouldCleanupMessageParams(cleanup)
    self.shouldCleanupMessageParams = cleanup
end

function ZO_CenterScreenAnnouncementLine:GetCleanupMessageParams()
    return self.shouldCleanupMessageParams
end

function ZO_CenterScreenAnnouncementLine:GetControl()
    return self.control
end

function ZO_CenterScreenAnnouncementLine:SetKey(key)
    self.key = key
end

function ZO_CenterScreenAnnouncementLine:GetKey()
    return self.key
end

function ZO_CenterScreenAnnouncementLine:TrySettingDynamicText(label, textOrFunction)
    if type(textOrFunction) == "function" then
        label.dynamicTextFunction = textOrFunction
        label:SetHandler("OnUpdate", function(label) label:SetText(label.dynamicTextFunction()) end)
    else
        label:SetText(textOrFunction)
        label:SetHandler("OnUpdate", nil)
    end
end

function ZO_CenterScreenAnnouncementLine:CreateAnimationWithExpiringCallback(timelineTemplate, stopHandler, expiringCallbackCheckOffset, expiringCallbackExecutor)
    local lineControl = self:GetControl()
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(timelineTemplate, lineControl)
    timeline.announcementLine = self
    timeline:SetHandler("OnStop", stopHandler)

    if expiringCallbackCheckOffset and expiringCallbackExecutor then
        timeline:InsertCallback(expiringCallbackExecutor, expiringCallbackCheckOffset)
    end

    return timeline
end

function ZO_CenterScreenAnnouncementLine:CreateWipeAnimation(timelineTemplate, stopHandler, expiringCallbackCheckOffset, expiringCallbackExecutor, wipeInBegin, wipeOutBegin, wipeInEnd)
    local timeline = self:CreateAnimationWithExpiringCallback(timelineTemplate, stopHandler, expiringCallbackCheckOffset, expiringCallbackExecutor)

    local wipeInAnim = timeline:GetAnimation(1)
    wipeInAnim:SetHandler("OnPlay", wipeInBegin)
    wipeInAnim:SetHandler("OnStop", wipeInEnd)

    local wipeOutAnim = timeline:GetAnimation(2)
    wipeOutAnim:SetHandler("OnPlay", wipeOutBegin)

    return timeline
end

function ZO_CenterScreenAnnouncementLine:OnLineComplete(completedPlayback)
    if not completedPlayback then return end

    self:FireCallbacks("OnLineComplete", self)
end

function ZO_CenterScreenAnnouncementLine:GetLineType()
    assert(false) -- override in derived classes
end 

function ZO_CenterScreenAnnouncementLine:ApplyPlatformStyle()
    assert(false) -- override in derived classes
end

function ZO_CenterScreenAnnouncementLine:CreateTimelines(...)
    assert(false) -- override in derived classes
end

------------------------------------------
-- Center Screen Announcement Small Line
------------------------------------------

ZO_CenterScreenAnnouncementSmallLine = ZO_CenterScreenAnnouncementLine:Subclass()

function ZO_CenterScreenAnnouncementSmallLine:Reset()
    ZO_CenterScreenAnnouncementLine.Reset(self)

    self.fadeInTimeline:Stop()
    self.fadeOutTimeline:Stop()
    self.translationTimeline:Stop()
end

function ZO_CenterScreenAnnouncementSmallLine:SetText(text)
    self:TrySettingDynamicText(self.control, text)
end

function ZO_CenterScreenAnnouncementSmallLine:OnAcquire()
    ZO_CenterScreenAnnouncementLine.OnAcquire(self)
    self.acquisitionTimeMS = GetFrameTimeMilliseconds()
end

function ZO_CenterScreenAnnouncementSmallLine:GetAcquisitionTimeMS()
    return self.acquisitionTimeMS
end

function ZO_CenterScreenAnnouncementSmallLine:BecomeTopSmallLine(container)
    local smallLineControl = self:GetControl()
    local distanceFromDestination = smallLineControl:GetTop() - container:GetTop()
    smallLineControl:SetAnchor(TOP, container, TOP, 0, distanceFromDestination)
    self:SetAndPlayTranslationAnimation(-distanceFromDestination)
end

function ZO_CenterScreenAnnouncementSmallLine:SetWipeOutLifespan(lifespan)
    local fadeOutTimeline = self.fadeOutTimeline
    local fadeOutAnimation = fadeOutTimeline:GetAnimation(1)
    fadeOutTimeline:SetAnimationOffset(fadeOutAnimation, lifespan)
end

function ZO_CenterScreenAnnouncementSmallLine:SetAndPlayStartingAnimation(translationDetlaY)
    self:SetAndPlayTranslationAnimation(translationDetlaY)
    self.fadeInTimeline:PlayFromStart()
end

function ZO_CenterScreenAnnouncementSmallLine:SetAndPlayTranslationAnimation(translationDetlaY)
    local translateTimeline = self.translationTimeline
    translateTimeline:GetAnimation(1):SetTranslateDeltas(0, translationDetlaY)
    translateTimeline:PlayFromStart()
end

function ZO_CenterScreenAnnouncementSmallLine:PlayFadeOutAnimation(offset)
    self.fadeOutTimeline:PlayFromStart(offset)
end

function ZO_CenterScreenAnnouncementSmallLine:ApplyPlatformStyle()
    local isGamepad = IsInGamepadPreferredMode()
    self.control:SetFont(isGamepad and SMALL_TEXT_FONT_GAMEPAD or SMALL_TEXT_FONT_KEYBOARD)
end

function ZO_CenterScreenAnnouncementSmallLine:OnSmallLineTranslateComplete(completedPlayback)
    if not completedPlayback then return end

    local centerScreenAnnounceManager = CENTER_SCREEN_ANNOUNCE
    if centerScreenAnnounceManager:IsTopSmallLine(self) then
        centerScreenAnnounceManager:CallExpiringCallback(self)
        local offset = zo_clamp(GetFrameTimeMilliseconds() - self:GetAcquisitionTimeMS(), 0, MAX_SMALL_LINE_FADE_OUT_TIME)
        self:PlayFadeOutAnimation(offset)
    end
end

function ZO_CenterScreenAnnouncementSmallLine.OnSmallLineTranslatePartialComplete()
    CENTER_SCREEN_ANNOUNCE:TryDisplayingNextQueuedMessage()
end

function ZO_CenterScreenAnnouncementSmallLine:CreateTimelines(translationCompleteCallback, translationDisplayNextMessageCallback)
    self.fadeInTimeline = self:CreateAnimationWithExpiringCallback("CenterScreenSmallTextFadeIn")
    self.fadeOutTimeline = self:CreateAnimationWithExpiringCallback("CenterScreenSmallTextFadeOut", function(_,completedPlayback) self:OnLineComplete(completedPlayback) end)

    local translateTimeline = self:CreateAnimationWithExpiringCallback("CenterScreenSmallTextTranslate", function(_,completedPlayback) self:OnSmallLineTranslateComplete(completedPlayback) end)
    translateTimeline:InsertCallback(self.OnSmallLineTranslatePartialComplete, 500)
    self.translationTimeline = translateTimeline
end

function ZO_CenterScreenAnnouncementSmallLine:GetLineType()
    return CSA_LINE_TYPE_SMALL
end

------------------------------------------
-- Center Screen Announcement Large Line
------------------------------------------
local function AnchorIconToLabelControl(iconControl, textControl)
    -- Dynamically anchor the icon to the start of the text
    local textWidth = textControl:GetTextWidth()
    local lineWidth = textControl:GetWidth()
    local centeringOffset = (lineWidth - textWidth) / 2

    iconControl:ClearAnchors()
    iconControl:SetAnchor(RIGHT, textControl, LEFT, centeringOffset - 10, 0)
end

ZO_CenterScreenAnnouncementLargeLine = ZO_CenterScreenAnnouncementLine:Subclass()

function ZO_CenterScreenAnnouncementLargeLine:Initialize(control)
    ZO_CenterScreenAnnouncementLine.Initialize(self, control)

    self.largeText = control:GetNamedChild("Text")
    self.smallCombinedText = self.largeText:GetNamedChild("Combined")
    self.smallCombinedIcon = self.smallCombinedText:GetNamedChild("Icon")
    self.smallCombinedIconBG = self.smallCombinedText:GetNamedChild("IconBG")
    self.smallCombinedIconFrame = self.smallCombinedText:GetNamedChild("IconFrame")

    self.largeInformationIcon = self.largeText:GetNamedChild("LargeInformationIcon")

    self.raidCompleteContainer = self.largeText:GetNamedChild("RaidCompleteText")
    self.raidTimeAmountLabel = self.raidCompleteContainer:GetNamedChild("TimeAmount")
    self.raidScoreAmountLabel = self.raidCompleteContainer:GetNamedChild("ScoreAmount")
    self.raidVitalityAmountLabel = self.raidCompleteContainer:GetNamedChild("VitalityAmount")
    self.raidVitalityPercentLabel = self.raidCompleteContainer:GetNamedChild("VitalityPercent")
    self.raidVitalityIcon = self.raidCompleteContainer:GetNamedChild("VitalityIcon")

    self.smallCombinedIcon:SetHidden(true)
    self.largeInformationIcon:SetHidden(true)
    self.raidCompleteContainer:SetHidden(true)
end

function ZO_CenterScreenAnnouncementLargeLine:Reset()
    self.largeText:SetHandler("OnUpdate", nil)
    self.smallCombinedText:SetHandler("OnUpdate", nil)

    self.smallCombinedIcon:SetHidden(true)
    self.largeInformationIcon:SetHidden(true)
    self.raidCompleteContainer:SetHidden(true)
    self.wipeAnimationTimeline:Stop()
    self.wipeFadeAnimationTimeline:Stop()

    self.control:SetAlpha(1)

    if self.scryingIcons then
        for _, iconTexture in ipairs(self.scryingIcons) do
            self.scryingUpdatedIconPool:ReleaseObject(iconTexture.controlKey)
        end
        self.scryingIcons = nil
    end

    if self.rollingMeterProgressControls then
        for _, progressControl in ipairs(self.rollingMeterProgressControls) do
            self.rollingMeterProgressPool:ReleaseObject(progressControl.controlKey)
        end
        self.rollingMeterProgressControls = nil
    end

    if self.customAnimationTimeline then
        self.customAnimationTimeline = nil
        self.customAnimationSetupCallback = nil
    end

    ZO_CenterScreenAnnouncementLine.Reset(self)
end

function ZO_CenterScreenAnnouncementLargeLine:SetLargeText(text)
    self:TrySettingDynamicText(self.largeText, text)
end

function ZO_CenterScreenAnnouncementLargeLine:SetSmallCombinedText(text)
    self:TrySettingDynamicText(self.smallCombinedText, text)
end

function ZO_CenterScreenAnnouncementLargeLine:SetIcon(icon, iconBg, suppressIconFrame, iconColor)
    self.smallCombinedIcon:SetHidden(icon == nil)
    self.smallCombinedIconBG:SetHidden(iconBg == nil)
    self.smallCombinedIconFrame:SetHidden(suppressIconFrame)

    if icon then
        self.smallCombinedIcon:SetTexture(icon)
        AnchorIconToLabelControl(self.smallCombinedIcon, self.smallCombinedText)
    end

    if iconBg then
        self.smallCombinedIconBG:SetTexture(iconBg)
    end

    if iconColor then 
        self.smallCombinedIcon:SetColor(iconColor.r, iconColor.g, iconColor.b, iconColor.a)
    end
end

function ZO_CenterScreenAnnouncementLargeLine:SetLargeInformationIcon(icon)
    self.largeInformationIcon:SetHidden(icon == nil)

    if icon then
        self.largeInformationIcon:SetTexture(icon)
    end
end

function ZO_CenterScreenAnnouncementLargeLine:SetRaidBreakdownText(raidArgumentTable)
    self.raidCompleteContainer:SetHidden(false)
    self:TrySettingDynamicText(self.raidTimeAmountLabel, raidArgumentTable[ARG_BREAKDOWN_INDEX_TIME])
    self:TrySettingDynamicText(self.raidScoreAmountLabel, raidArgumentTable[ARG_BREAKDOWN_INDEX_SCORE])
    self:TrySettingDynamicText(self.raidVitalityAmountLabel, raidArgumentTable[ARG_BREAKDOWN_INDEX_VITALITY_AMOUNT])
    self:TrySettingDynamicText(self.raidVitalityPercentLabel, raidArgumentTable[ARG_BREAKDOWN_INDEX_VITALITY_PERCENT])

    if raidArgumentTable[ARG_BREAKDOWN_INDEX_VITALITY_AMOUNT] == 0 then
        self.raidVitalityPercentLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        self.raidVitalityIcon:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
    else
        self.raidVitalityPercentLabel:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        self.raidVitalityIcon:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    end

    if raidArgumentTable[ARG_BREAKDOWN_INDEX_SHOW_AS_ERROR] then
        self.raidTimeAmountLabel:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    else
        self.raidTimeAmountLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
    end
end

function ZO_CenterScreenAnnouncementLargeLine:SetScryingUpdatedIconData(iconPool, lastGoalsAchieved, goalsAchieved, goalsTotal)
    self.scryingUpdatedIconPool = iconPool
    self.scryingIcons = {}

    local parentControl = self.control:GetNamedChild("TextScryingUpdatedSection")
    local lastControl = nil
    local SCRYING_ICON_FADE_IN_OFFSET_MS = 200
    for goalIndex = 1, goalsTotal do
        local iconTexture, key = iconPool:AcquireObject()
        iconTexture.controlKey = key
        table.insert(self.scryingIcons, iconTexture)

        iconTexture:SetParent(parentControl)
        if lastControl then
            iconTexture:SetAnchor(LEFT, lastControl, RIGHT, 0, 0)
        else
            iconTexture:SetAnchor(LEFT, parentControl, LEFT, 0, 0)
        end
        lastControl = iconTexture

        local wasAlreadyAchieved = goalIndex <= lastGoalsAchieved
        iconTexture.achievedIcon:SetAlpha(wasAlreadyAchieved and 1 or 0)
        iconTexture.shouldFadeIn = not wasAlreadyAchieved and goalIndex <= goalsAchieved
        iconTexture.isLastGoal = goalIndex == goalsTotal
        local fadeAnimation = iconTexture.fadeInTimeline:GetFirstAnimation()
        iconTexture.fadeInTimeline:SetAnimationOffset(fadeAnimation, (goalIndex - lastGoalsAchieved - 1) * SCRYING_ICON_FADE_IN_OFFSET_MS)
    end
end

function ZO_CenterScreenAnnouncementLargeLine:SetRollingMeterProgressData(rollingMeterProgressPool, rollingMeterProgressData)
    self.rollingMeterProgressPool = rollingMeterProgressPool
    self.rollingMeterProgressControls = {}

    local parentControl = self.control:GetNamedChild("TextRollingMeterProgressSection")
    local previousControl = nil
    local numAnimatedControls = 0
    local ROLLING_METER_ANIMATION_BASE_DURATION_MS = 1000
    local ROLLING_METER_ANIMATION_OFFSET_DURATION_MS = 125
    for index, progressEntry in ipairs(rollingMeterProgressData) do
        local progressControl, key = rollingMeterProgressPool:AcquireObject()
        progressControl.controlKey = key
        table.insert(self.rollingMeterProgressControls, progressControl)

        progressControl:SetParent(parentControl)
        if previousControl then
            progressControl:SetAnchor(TOPLEFT, previousControl, TOPRIGHT, 16, 0)
        else
            progressControl:SetAnchor(TOPLEFT, parentControl)
        end
        previousControl = progressControl

        progressControl.icon:SetTexture(progressEntry.iconTexture)
        progressControl.narrationDescription = progressEntry.narrationDescription
        local initialValue = progressEntry.initialValue or 0
        progressControl.finalValue = progressEntry.finalValue or 0
        progressControl.labelTransitionManager:SetValueImmediately(initialValue)
        progressControl.transitionTimeline:PlayInstantlyToStart()

        if initialValue ~= progressControl.finalValue then
            -- Guarantee that the final value always animates in
            -- from the top regardless of which value is larger.
            local animationDirection = initialValue < progressControl.finalValue and ZO_ROLLING_METER_LABEL_DIRECTION.DOWN or ZO_ROLLING_METER_LABEL_DIRECTION.UP
            progressControl.label:SetAnimationIncrementDirection(animationDirection)

            -- Order matters:
            local animationDurationMS = ROLLING_METER_ANIMATION_BASE_DURATION_MS + (numAnimatedControls * ROLLING_METER_ANIMATION_OFFSET_DURATION_MS)
            progressControl.transitionAnimation:SetDuration(animationDurationMS)
            progressControl.transitionTimeline:PlayForward()
            numAnimatedControls = numAnimatedControls + 1
        end
    end
end

function ZO_CenterScreenAnnouncementLargeLine:SetCustomAnimationTimeline(timeline, setupCallback)
    self.customAnimationTimeline = timeline
    self.customAnimationSetupCallback = setupCallback
end

function ZO_CenterScreenAnnouncementLargeLine:ApplyPlatformStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_CenterScreenAnnounce_LargeTextContainer"))
    if not self.smallCombinedIcon:IsHidden() then
        AnchorIconToLabelControl(self.smallCombinedIcon, self.smallCombinedText)
    end

    local isGamepad = IsInGamepadPreferredMode()
    self.smallCombinedIconFrame:SetTexture(isGamepad and "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame64.dds" or "EsoUI/Art/ActionBar/abilityFrame64_up.dds")
end

function ZO_CenterScreenAnnouncementLargeLine.SetupWipeIn(animation, control)
    control:ClearAnchors()
    control:SetAnchor(TOPLEFT, control:GetParent(), TOPLEFT, -560, 0)
end

function ZO_CenterScreenAnnouncementLargeLine:OnWipeInComplete()
    if self.scryingIcons then
        for _, iconTexture in ipairs(self.scryingIcons) do
            if iconTexture.shouldFadeIn then
                iconTexture.fadeInTimeline:GetFirstAnimation():SetHandler("OnPlay", function()
                    if iconTexture.isLastGoal then
                        PlaySound(SOUNDS.SCRYING_PROGRESS_LAST_GOAL_FADEIN)
                    else
                        PlaySound(SOUNDS.SCRYING_PROGRESS_GOAL_FADEIN)
                    end
                end)
                iconTexture.fadeInTimeline:PlayFromStart()
            end
        end
    end
end

function ZO_CenterScreenAnnouncementLargeLine.SetupWipeOut(animation, control)
    control:ClearAnchors()
    control:SetAnchor(TOPRIGHT, control:GetParent(), TOPRIGHT, 560, 0)
end

function ZO_CenterScreenAnnouncementLargeLine.ExpiringCallback(timeline) 
    CENTER_SCREEN_ANNOUNCE:CallExpiringCallback(timeline.announcementLine) 
end

function ZO_CenterScreenAnnouncementLargeLine:CreateTimelines()
    local onTimelineStopped = function(_,completedPlayback) self:OnLineComplete(completedPlayback) end
    local expiringCallback = ZO_CenterScreenAnnouncementLargeLine.ExpiringCallback
    local onWipeInBegin = ZO_CenterScreenAnnouncementLargeLine.SetupWipeIn
    local onWipeInEnd = function() self:OnWipeInComplete() end
    local onWipeOutBegin = ZO_CenterScreenAnnouncementLargeLine.SetupWipeOut
    self.wipeAnimationTimeline = self:CreateWipeAnimation("CenterScreenLargeTextWipe", onTimelineStopped, DEFAULT_FADE_OUT_TIME_MS, expiringCallback, onWipeInBegin, onWipeOutBegin, onWipeInEnd)
    self.wipeFadeAnimationTimeline = self:CreateWipeAnimation("CenterScreenLargeTextFade", onTimelineStopped, DEFAULT_FADE_OUT_TIME_MS, expiringCallback, onWipeInBegin, onWipeOutBegin, onWipeInEnd)
end

function ZO_CenterScreenAnnouncementLargeLine:SetWipeTimelineLifespan(lifespan)
    local wipeOutAnimation = self.wipeAnimationTimeline:GetAnimation(2)
    self.wipeAnimationTimeline:SetAnimationOffset(wipeOutAnimation, lifespan)
    self.wipeAnimationTimeline:SetCallbackOffset(ZO_CenterScreenAnnouncementLargeLine.ExpiringCallback, lifespan)

    local fadeOutAnimation = self.wipeFadeAnimationTimeline:GetAnimation(2)
    self.wipeFadeAnimationTimeline:SetAnimationOffset(fadeOutAnimation, lifespan)
    self.wipeFadeAnimationTimeline:SetCallbackOffset(ZO_CenterScreenAnnouncementLargeLine.ExpiringCallback, lifespan)
end

function ZO_CenterScreenAnnouncementLargeLine:PlayWipeAnimation()
    self.wipeAnimationTimeline:PlayFromStart()

    if self.customAnimationTimeline then
        if self.customAnimationSetupCallback then
            self.customAnimationSetupCallback(self.control:GetParent():GetNamedChild("SmallLineContainer"))
        end
        self.customAnimationTimeline:PlayFromStart()
    end
end

function ZO_CenterScreenAnnouncementLargeLine:PlayWipeFadeAnimation()
    self.wipeFadeAnimationTimeline:PlayFromStart()
end

function ZO_CenterScreenAnnouncementLargeLine:GetLineType()
    return CSA_LINE_TYPE_LARGE
end

------------------------------------------
-- Center Screen Announcement Major Line
------------------------------------------

ZO_CenterScreenAnnouncementMajorLine = ZO_CenterScreenAnnouncementLine:Subclass()

function ZO_CenterScreenAnnouncementMajorLine:Initialize(control)
    ZO_CenterScreenAnnouncementLine.Initialize(self, control)

    self.iconControl = control:GetNamedChild("Icon")
    self.iconControlBG = control:GetNamedChild("IconBG")
    self.iconControlFrame = control:GetNamedChild("IconFrame")
end

function ZO_CenterScreenAnnouncementMajorLine:Reset()
    ZO_CenterScreenAnnouncementLine.Reset(self)

    self.popInAnimationTimeline:Stop()
end

function ZO_CenterScreenAnnouncementMajorLine:SetText(text)
    self:TrySettingDynamicText(self.control, text)
end

function ZO_CenterScreenAnnouncementMajorLine:SetIcon(icon, iconBg, suppressIconFrame)
    self.iconControl:SetHidden(icon == nil)
    self.iconControlBG:SetHidden(iconBg == nil)
    self.iconControlFrame:SetHidden(suppressIconFrame)

    if icon then
        self.iconControl:SetTexture(icon)
        AnchorIconToLabelControl(self.iconControl, self.control)
    end

    if iconBg then
        self.iconControlBG:SetTexture(iconBg)
    end
end

function ZO_CenterScreenAnnouncementMajorLine:SetPopInLifespan(lifespan)
    local popInAnimationTimeline = self.popInAnimationTimeline
    local alphaOutAnimation = popInAnimationTimeline:GetAnimation(3)
    local scaleOutAnimation = popInAnimationTimeline:GetAnimation(4)
    popInAnimationTimeline:SetAnimationOffset(alphaOutAnimation, lifespan)
    popInAnimationTimeline:SetAnimationOffset(scaleOutAnimation, lifespan)
end

function ZO_CenterScreenAnnouncementMajorLine:SetAndPlayStartingAnimation(lifespan)
    self:SetPopInLifespan(lifespan)
    self.popInAnimationTimeline:PlayFromStart()
end

function ZO_CenterScreenAnnouncementMajorLine:CreateTimelines()
    self.popInAnimationTimeline = self:CreateAnimationWithExpiringCallback("CenterScreenMajorTextPopIn", function(_,completedPlayback) self:OnLineComplete(completedPlayback) end)
end

function ZO_CenterScreenAnnouncementMajorLine:ApplyPlatformStyle()
    local isGamepad = IsInGamepadPreferredMode()
    self.control:SetFont(isGamepad and SMALL_TEXT_FONT_GAMEPAD or SMALL_TEXT_FONT_KEYBOARD)
    self.iconControlFrame:SetTexture(isGamepad and "EsoUI/Art/ActionBar/Gamepad/gp_abilityFrame64.dds" or "EsoUI/Art/ActionBar/abilityFrame64_up.dds")
end

function ZO_CenterScreenAnnouncementMajorLine:GetLineType()
    return CSA_LINE_TYPE_MAJOR
end

-----------------------------------------------
-- Center Screen Announcement Countdown Line
-----------------------------------------------

ZO_CenterScreenAnnouncementCountdownLine = ZO_CenterScreenAnnouncementLine:Subclass()

function ZO_CenterScreenAnnouncementCountdownLine:Initialize(control)
    ZO_CenterScreenAnnouncementLine.Initialize(self, control)

    self.countdownControl = self.control:GetNamedChild("Countdown")
    self.endImageControl = self.control:GetNamedChild("EndImage")
    self.endImageControl:SetHidden(true)
end

function ZO_CenterScreenAnnouncementCountdownLine:Reset()
    ZO_CenterScreenAnnouncementLine.Reset(self)
    self.endImageControl:SetTexture(nil)
    self.endImageControl:SetHidden(true)
    self.countdownControl:SetText("")
    self.endImageTexture = nil

    self.countdownLoopAnimationTimeline:Stop()
    self.countdownEndImageAnimationTimeline:Stop()
    self.countdownBufferAnimationTimeline:Stop()
end

function ZO_CenterScreenAnnouncementCountdownLine:SetAndPlayStartingAnimation(lifespanMS)
    self.finalFrameTimeMS = GetFrameTimeMilliseconds() + lifespanMS
    local lifespanS = lifespanMS / 1000
    self.countdownTimeS = zo_floor(lifespanS)
    self.currentCountdownTimeS = self.countdownTimeS
    local runOverTimeMS = (lifespanS - self.countdownTimeS) * 1000
    if runOverTimeMS > 0 then
        local bufferAnimation = self.countdownBufferAnimationTimeline:GetAnimation(1)
        bufferAnimation:SetDuration(runOverTimeMS)
        self.countdownBufferAnimationTimeline:PlayFromStart()
    else
        self:PlayCountdownLoopAnimation()
    end
end

function ZO_CenterScreenAnnouncementCountdownLine:SetEndImageTexture(texture)
    self.endImageTexture = texture
    self.endImageControl:SetTexture(texture)
end

function ZO_CenterScreenAnnouncementCountdownLine:CreateTimelines()
    self.countdownLoopAnimationTimeline = self:CreateAnimationWithExpiringCallback("CenterScreenCountdownLoop", function(_,completedPlayback) self:OnCountDownAnimationEnd(completedPlayback) end)
    self.countdownEndImageAnimationTimeline = self:CreateAnimationWithExpiringCallback("CenterScreenCountdownEndImage", function(_,completedPlayback) self:OnLineComplete(completedPlayback) end)
    self.countdownBufferAnimationTimeline = self:CreateAnimationWithExpiringCallback("CenterScreenCountdownBuffer", function(_,completedPlayback) self:OnBufferComplete(completedPlayback) end)
end

function ZO_CenterScreenAnnouncementCountdownLine:PlayCountdownLoopAnimation()
    self.countdownControl:SetText(self.currentCountdownTimeS)
    SCREEN_NARRATION_MANAGER:QueueCountdownCSA(self.currentCountdownTimeS)
    PlaySound(SOUNDS.COUNTDOWN_TICK)
    self.countdownLoopAnimationTimeline:PlayFromStart()
end

function ZO_CenterScreenAnnouncementCountdownLine:OnBufferComplete(completedPlayback)
    if not completedPlayback then return end

    self:PlayCountdownLoopAnimation()
end

function ZO_CenterScreenAnnouncementCountdownLine:OnCountDownAnimationEnd(completedPlayback)
    if not completedPlayback then return end

    self.currentCountdownTimeS = self.currentCountdownTimeS - 1
    
    if self.currentCountdownTimeS > 0 then
        self:PlayCountdownLoopAnimation()
    elseif self.endImageControl:IsHidden() and self.endImageTexture then
        self.messageParams:PlaySound()
        self.endImageControl:SetHidden(false)
        self.countdownControl:SetText("")
        self.countdownEndImageAnimationTimeline:PlayFromStart()
    else
        self.messageParams:PlaySound()
        self:OnLineComplete(completedPlayback)
    end
end

function ZO_CenterScreenAnnouncementCountdownLine:ApplyPlatformStyle()
    local isGamepad = IsInGamepadPreferredMode()
    self.countdownControl:SetFont(isGamepad and COUNTDOWN_TEXT_FONT_GAMEPAD or COUNTDOWN_TEXT_FONT_KEYBOARD)
end

function ZO_CenterScreenAnnouncementCountdownLine:GetLineType()
    return CSA_LINE_TYPE_COUNTDOWN
end

-----------------------------------
-- Center Screen Announce Manager
-----------------------------------

local CenterScreenAnnounce = ZO_InitializingObject:Subclass()

do
    local eventHandlers = ZO_CenterScreenAnnounce_GetEventHandlers()
    local queueableEventHandlers = ZO_CenterScreenAnnounce_GetQueueableEventHandlers()
    local callbackHandlers = ZO_CenterScreenAnnounce_GetCallbackHandlers()

    function CenterScreenAnnounce:OnCenterScreenEvent(eventId, ...)
        if eventHandlers[eventId] then
            if queueableEventHandlers[eventId] then
                local timeNowSeconds = GetFrameTimeSeconds()
                local waitingQueueData = CENTER_SCREEN_ANNOUNCE:GetWaitingQueueEventData(eventId)
                if waitingQueueData then
                    local conditions = queueableEventHandlers[eventId].conditionParameters or {}
                    local passConditions = true
                    for k,condition in ipairs(conditions) do
                        if waitingQueueData.eventData[condition] ~= select(condition, ...) then
                            passConditions = false
                            break
                        end
                    end
                    if passConditions then
                        local updateParametersTable = queueableEventHandlers[eventId].updateParameters
                        if updateParametersTable then
                            for i,entry in pairs(updateParametersTable) do
                                waitingQueueData.eventData[entry] = select(entry, ...)
                            end
                        end
                        waitingQueueData.nextUpdateTimeSeconds = timeNowSeconds + queueableEventHandlers[eventId].updateTimeDelaySeconds
                        return
                    end
                end

                local data = 
                {
                    eventId = eventId,
                    eventData = { ... },
                    nextUpdateTimeSeconds = timeNowSeconds + queueableEventHandlers[eventId].updateTimeDelaySeconds
                }
                table.insert(self.waitingQueue, data)
            else
                local eventHandler = eventHandlers[eventId]
                self:AddMessageWithParams(eventHandler(...))
            end
        end
    end

    function CenterScreenAnnounce:Initialize(control)
        self.control = control
        control.object = self

        self.displayQueue = {}
        self.waitingQueue = {}
        self.allowedCategories = {}
        self.pendingMajorMessages = {}
        self.activeLines = 
        {
            [CSA_LINE_TYPE_SMALL] = {},
            [CSA_LINE_TYPE_LARGE] = {},
            [CSA_LINE_TYPE_MAJOR] = {},
            [CSA_LINE_TYPE_COUNTDOWN] = {},
        }
        self.hasActiveLevelBar = false
        self.isWaitingOnExternalHandle = false

        self.smallLineContainer = control:GetNamedChild("SmallLineContainer")
        self.majorLineContainer = control:GetNamedChild("MajorLineContainer")
        self.countdownLineContainer = control:GetNamedChild("CountdownLineContainer")
        self.backgroundContainer = control:GetNamedChild("BackgroundContainer")

        local backgroundContainerFadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CenterScreenBackgroundFadeIn", self.backgroundContainer)
        backgroundContainerFadeInTimeline:SetHandler("OnPlay", function()
            self.isBackgroundAnimating = true
            self.backgroundContainer:SetHidden(false) 
        end)
        self.backgroundContainerFadeInTimeline = backgroundContainerFadeInTimeline

        local backgroundContainerFadeOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CenterScreenBackgroundFadeOut", self.backgroundContainer)
        backgroundContainerFadeOutTimeline:SetHandler("OnStop", function(timeline, completedPlayback)
            self.isBackgroundAnimating = false
            self.backgroundContainer:SetHidden(true) 
        end)
        self.backgroundContainerFadeOutTimeline = backgroundContainerFadeOutTimeline

        local majorContainerTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CenterScreenMajorTextContainerExpand", self.majorLineContainer)
        local containerHeightAnimation = majorContainerTimeline:GetFirstAnimation()
        containerHeightAnimation:SetUpdateFunction(function(animation, progress) self:SetMajorLineContainerHeight(progress) end)
        majorContainerTimeline:SetHandler("OnStop", function(timeline, completedPlayback) self:OnMajorLineContainerAnimationComplete(completedPlayback) end)
        self.majorLineContainerTimeline = majorContainerTimeline

        self.nextQueueIndex = 1

        -- Recent message handler, using a 250 ms expiry delay
        self.recentMessages = ZO_RecentMessages:New(250)

        self.nextUpdateTimeSeconds = 0

        local function OnCenterScreenAnnounceUpdate(control, timeNow)
            -- Check if we can show the next message
            if #self.displayQueue > 0 and timeNow > self.nextUpdateTimeSeconds then
                self.nextUpdateTimeSeconds = timeNow + 0.02
                self:TryDisplayingNextQueuedMessage()
            end

            -- Check the waiting Queue for any lingering events that need to be pushed
            local indicesToRemove = {}
            for i, entry in ipairs(self.waitingQueue) do
                if timeNow > entry.nextUpdateTimeSeconds then
                    local eventId = entry.eventId
                    table.insert(indicesToRemove, i)
                    local handler = eventHandlers[eventId]
                    self:AddMessageWithParams(handler(unpack(entry.eventData)))
                end
            end

            --Wait until the end to remove the newly queued entries, so we don't accidentally skip anything
            for _, index in ZO_NumericallyIndexedTableReverseIterator(indicesToRemove) do
                table.remove(self.waitingQueue, index)
            end
        end

        self.control:SetHandler("OnUpdate", OnCenterScreenAnnounceUpdate)

        self.platformStyle = ZO_PlatformStyle:New(function() self:ApplyPlatformStyle() end)

        -- Events
        local function OnCenterScreenEvent(eventId, ...)
            self:OnCenterScreenEvent(eventId, ...)
        end

        for event, data in pairs(eventHandlers) do
            control:RegisterForEvent(event, OnCenterScreenEvent)
        end

        -- Callbacks
        for _, data in ipairs(callbackHandlers) do
            local function Callback(...)
                local paramsObjects = { data.callbackFunction(...) }
                for _, params in ipairs(paramsObjects) do
                    self:AddMessageWithParams(params)
                end
            end
            
            data.callbackManager:RegisterCallback(data.callbackRegistration, Callback)
        end

        self:InitializeMessagePools()
        self:InitializeLinePools()
    end
end

function CenterScreenAnnounce:InitializeMessagePools()
    PLAYER_PROGRESS_BAR:RegisterCallback("Show", function()
        --if the announcement has begun fading out ("expiring") before the bar even shows, we don't need to hold
        if PLAYER_PROGRESS_BAR:GetOwner() == CENTER_SCREEN_ANNOUNCE and self:HasAnyActiveLines() and self.isBeforeMessageExpiring then
            PLAYER_PROGRESS_BAR:SetHoldBeforeFadeOut(true)
        end
    end)

    PLAYER_PROGRESS_BAR:RegisterCallback("Complete", function()
        self.hasActiveLevelBar = false
        self:CheckNowInactive()
    end)

    local function BarParamFactory(pool)
        return CenterScreenPlayerProgressBarParams:New()
    end

    local function BarParamReset(params)
        params:Reset()
        params.key = nil
    end

    self.barParamsPool = ZO_ObjectPool:New(BarParamFactory, BarParamReset)

    local function MessageParamFactory(pool)
        return ZO_CenterScreenMessageParams:New()
    end

    local function MessageParamReset(params)
        local barParams = params:GetBarParams()
        if barParams then
            self.barParamsPool:ReleaseObject(barParams.key)
        end
        params:Reset()
    end

    self.messageParamsPool = ZO_ObjectPool:New(MessageParamFactory, MessageParamReset)
end

function CenterScreenAnnounce:InitializeLinePools()
    -- Large Line Pool
    self.largeLinePool = self:CreateLinePool("$(parent)LargeLine", "ZO_CenterScreenAnnounceLargeTextLineTemplate", self.control, ZO_CenterScreenAnnouncementLargeLine)

    -- Small Line Pool
    self.smallLinePool = self:CreateLinePool("$(parent)SmallLine", "ZO_CenterScreenAnnounceSmallTextTemplate", self.smallLineContainer, ZO_CenterScreenAnnouncementSmallLine)

    -- Major Line Pool
    self.majorLinePool = self:CreateLinePool("$(parent)MajorLine", "ZO_CenterScreenAnnounceSmallTextTemplate", self.majorLineContainer, ZO_CenterScreenAnnouncementMajorLine)

    -- get the height of the control for when we animate the container of a major event line
    local testLine, testKey = self.majorLinePool:AcquireObject()
    local testLineControl = testLine:GetControl()
    testLineControl:SetFont(SMALL_TEXT_FONT_KEYBOARD)
    local fontHeight = testLineControl:GetFontHeight()
    local iconHeight = testLine.iconControl:GetHeight()
    self.MAJOR_LINE_HEIGHT_KEYBOARD = fontHeight > iconHeight and fontHeight or iconHeight
    testLineControl:SetFont(SMALL_TEXT_FONT_GAMEPAD)
    fontHeight = testLineControl:GetFontHeight()
    self.MAJOR_LINE_HEIGHT_GAMEPAD = fontHeight > iconHeight and fontHeight or iconHeight
    self.majorLinePool:ReleaseObject(testKey)

    -- Countdown Line Pool
    self.countdownLinePool = self:CreateLinePool("$(parent)CountdownLine", "ZO_CenterScreenAnnounceCountdownTextTemplate", self.control, ZO_CenterScreenAnnouncementCountdownLine)

    self.allLinePools =
    {
        [CSA_LINE_TYPE_SMALL] = self.smallLinePool,
        [CSA_LINE_TYPE_LARGE] = self.largeLinePool,
        [CSA_LINE_TYPE_MAJOR] = self.majorLinePool,
        [CSA_LINE_TYPE_COUNTDOWN] = self.countdownLinePool,
    }

    self.scryingUpdatedIconPool = ZO_ControlPool:New("ZO_CenterScreenAnnounce_ScryingUpdated_Icon", self.control, "ScryingIcon")

    self.rollingMeterProgressPool = ZO_ControlPool:New("ZO_CenterScreenAnnounce_RollingMeterProgressTemplate", self.control, "CSARollingMeterProgress")

    local function ApplyRollingMeterPlatformStyle()
        local isGamepad = IsInGamepadPreferredMode()
        local rollingMeterFont = isGamepad and ROLLING_METER_TEXT_GAMEPAD or ROLLING_METER_TEXT_KEYBOARD
        for _, rollingMeterControl in self.rollingMeterProgressPool:ActiveAndFreeObjectIterator() do
            rollingMeterControl.label:SetFont(rollingMeterFont)
        end
    end

    self.rollingMeterPlatformStyle = ZO_PlatformStyle:New(ApplyRollingMeterPlatformStyle)
end

function CenterScreenAnnounce:CreateLinePool(controlName, controlTemplate, parentControl, lineType)
    local function OnLineComplete(completedLine)
        local SKIP_DISPLAY_NEXT = true
        local lineType = completedLine:GetLineType()
        self:ReleaseLine(completedLine, SKIP_DISPLAY_NEXT)
        if lineType == CSA_LINE_TYPE_SMALL and self:HasActiveLines(CSA_LINE_TYPE_SMALL) then
            self:MoveSmallLinesUp()
        elseif lineType == CSA_LINE_TYPE_MAJOR then
            self:StartMajorLineContainerAnimation()
            completedLine.control:SetScale(1)
        end
        self:TryDisplayingNextQueuedMessage()
    end

    local function LineFactory(pool)
        local lineControl = ZO_ObjectPool_CreateNamedControl(controlName, controlTemplate, pool, parentControl)
        local line = lineType:New(lineControl)
        line:RegisterCallback("OnLineComplete", OnLineComplete)
        return line
    end

    local linePool = ZO_ObjectPool:New(LineFactory, ZO_ObjectPool_DefaultResetObject)
    linePool:SetCustomAcquireBehavior(function(newLine) newLine:OnAcquire() end)

    return linePool
end

function CenterScreenAnnounce:ApplyPlatformStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_CenterScreenAnnounce"))

    for _, lineStyleTable in pairs(self.activeLines) do
        for _, line in ipairs(lineStyleTable) do
            line:ApplyPlatformStyle()
        end
    end
end

function CenterScreenAnnounce:CreateBarParams(...)
    local barParams, key = self.barParamsPool:AcquireObject()
    barParams.key = key
    barParams:Set(...)
    return barParams
end

function CenterScreenAnnounce:CreateMessageParams(category, sound)
    local messageParams, key = self.messageParamsPool:AcquireObject()
    messageParams:SetSound(sound)
    messageParams:SetObjectPoolKey(key)
    messageParams:SetCategory(category)
    return messageParams
end

function CenterScreenAnnounce:ReleaseMessageParams(messageParams)
    self.messageParamsPool:ReleaseObject(messageParams.key)
end

do
    local ALLOWED_TYPES_DURING_SCRYING =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST] = true,
    }

    local ALLOWED_TYPES_DURING_ANTIQUITIES_DIGGING =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIGGING_GAME_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST] = true,
    }

    local ALLOWED_TYPES_DURING_TRIBUTE =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_GAME_STATE_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST] = true,
    }

    local DEFERRED_TYPES_WHILE_DEAD =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_ENDLESS_DUNGEON_ATTEMPTS_REMAINING_CHANGED] = true,
    }

    -- Per Design, Announcement screen trumps all CSAs... but that could change.
    local ALLOWED_TYPES_DURING_MARKET_ANNOUNCEMENT =
    {
    }

    function CenterScreenAnnounce:CanDisplayMessage(category, csaType)
        -- Early out if category is not of scrying category while showing scrying or map mode dig sites
        if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_DIG_SITES) and category ~= CSA_CATEGORY_SCRYING_PROGRESS_TEXT then
            return false
        end

        -- Leave the CSA in the queue if the type should be deferred while the player is dead.
        if DEFERRED_TYPES_WHILE_DEAD[csaType] and IsUnitDead("player") then
            return false
        end

        if SCRYING_SCENE:IsShowing() and not ALLOWED_TYPES_DURING_SCRYING[csaType] then
            return false
        end

        -- Early out if the message type can't be shown during antiquity digging
        if ANTIQUITY_DIGGING_FRAGMENT:IsShowing() and not ALLOWED_TYPES_DURING_ANTIQUITIES_DIGGING[csaType] then
            return false
        end

        -- Early out if the message type can't be shown during tribute
        if TRIBUTE_FRAGMENT:IsShowing() and not ALLOWED_TYPES_DURING_TRIBUTE[csaType] then
            return false
        end

        if SCENE_MANAGER:IsShowing("marketAnnouncement") and not ALLOWED_TYPES_DURING_MARKET_ANNOUNCEMENT[csaType] then
            return false
        end

        if self.isWaitingOnExternalHandle then
            return false
        end

        if self.isBackgroundAnimating then
            return false
        end

        if self:HasActiveLines(CSA_LINE_TYPE_COUNTDOWN) then
            return false -- nothing can show during a countdown (for now)
        elseif category == CSA_CATEGORY_COUNTDOWN_TEXT or category == CSA_CATEGORY_MAJOR_TEXT then
            return true -- these events must always show as soon as possible
        elseif self.hasActiveLevelBar then
             -- we can only show one bar increase on the player progress bar at a time
             -- attempting to show a second before the first has completed will cause errors
            return false
        elseif self:HasActiveLines(CSA_LINE_TYPE_SMALL) then
            if category == CSA_CATEGORY_SMALL_TEXT then
                return #self.activeLines[CSA_LINE_TYPE_SMALL] < MAX_SMALL_TEXT_LINES
            else
                return false
            end
        elseif self:HasActiveLines(CSA_LINE_TYPE_LARGE) then
            return false
        end
    
        return true
    end
end

function CenterScreenAnnounce:GetWaitingQueueEventData(eventId)
    for i,entry in ipairs(self.waitingQueue) do
        if entry.eventId == eventId then
            return entry
        end
    end

    return nil
end

function CenterScreenAnnounce:AddActiveLine(line)
    local lineType = line:GetLineType()
    table.insert(self.activeLines[lineType], line)
end

function CenterScreenAnnounce:RemoveActiveLine(line)
    local lineType = line:GetLineType()
    local activeLinesForType = self.activeLines[lineType]
    for i, activeLine in ipairs(activeLinesForType) do
        if line == activeLine then
            local lineType = line:GetLineType()
            local linePool = self.allLinePools[lineType]
            linePool:ReleaseObject(line:GetKey())
            table.remove(activeLinesForType, i)
            return
        end
    end
end

function CenterScreenAnnounce:RemoveAllActiveLines()
    for lineType, activeLinesByType in ipairs(self.activeLines) do
        local linePool = self.allLinePools[lineType]
        linePool:ReleaseAllObjects()
        ZO_ClearNumericallyIndexedTable(activeLinesByType)
    end
end

function CenterScreenAnnounce:HasActiveLines(lineType)
    return #self.activeLines[lineType] > 0
end

function CenterScreenAnnounce:HasAnyActiveLines()
    for _, lines in pairs(self.activeLines) do
        if #lines > 0 then
            return true
        end
    end

    return false
end

function CenterScreenAnnounce:GetMostRecentLine(lineType)
    local lineTable = self.activeLines[lineType]
    return lineTable[#lineTable]
end

function CenterScreenAnnounce:GetOldestLine(lineType)
    return self.activeLines[lineType][1]
end

local messagePriorities = {}

function CenterScreenAnnounce:GetPriority(eventId)
    return messagePriorities[eventId] or DEFAULT_PRIORITY
end

local function SortMessageParams(left, right)
    if left:GetPriority() ~= right:GetPriority() then
        return left:GetPriority() > right:GetPriority()
    else
        local leftBarParams = left:GetBarParams()
        local rightBarParams = right:GetBarParams()
        if leftBarParams ~= nil and rightBarParams ~= nil then
            if leftBarParams.startLevel ~= rightBarParams.startLevel then
                return leftBarParams.startLevel < rightBarParams.startLevel
            else
                if leftBarParams.start ~= rightBarParams.start then
                    return leftBarParams.start < rightBarParams.start
                else
                    if leftBarParams.stop ~= rightBarParams.stop then
                        return leftBarParams.stop < rightBarParams.stop
                    else
                        return false
                    end
                end
            end
        elseif left:GetQueuedOrder() ~= right:GetQueuedOrder() then
            return left:GetQueuedOrder() < right:GetQueuedOrder()
        else
            return false
        end
    end
end

function CenterScreenAnnounce:SortQueue()
    local maxBarTypePriorities = {}
    for _, messageParams in ipairs(self.displayQueue) do
        local barParams = messageParams:GetBarParams()
        if barParams then
            local barType = barParams:GetParams()
            local currentMaxPriority = maxBarTypePriorities[barType]
            if currentMaxPriority == nil or messageParams:GetPriority() > currentMaxPriority then
                maxBarTypePriorities[barType] = messageParams:GetPriority()
            end
        end
    end

    for _, messageParams in ipairs(self.displayQueue) do
        local barParams = messageParams:GetBarParams()
        if barParams then
            local barType = barParams:GetParams()
            messageParams:SetPriority(maxBarTypePriorities[barType])
        end
    end

    table.sort(self.displayQueue, SortMessageParams)
end

function CenterScreenAnnounce:DoesNextMessageHaveBarParams()
    local nextMessage = self:GetNextShowableMessage()
    if nextMessage then
        local params = nextMessage:GetBarParams()
        return params ~= nil
    end
    return false
end

function CenterScreenAnnounce:DoesNextMessageHaveBarType(barType)
    local nextMessage = self:GetNextShowableMessage()
    if nextMessage then
        local params = nextMessage:GetBarParams()
        if params and barType == params.type then
            return true
        end
    end
    return false
end

function CenterScreenAnnounce:HasBarTypeInQueue(barType)
    for _, messageParams in ipairs(self.displayQueue) do
        local currentParams = messageParams:GetBarParams()
        if currentParams and barType == currentParams.type then
            return true
        end
    end
    return false
end

function CenterScreenAnnounce:MoveSmallLinesUp()
    local oldestSmallLine = self:GetOldestLine(CSA_LINE_TYPE_SMALL)
    if oldestSmallLine then
        oldestSmallLine:BecomeTopSmallLine(self.smallLineContainer)
    end
end

function CenterScreenAnnounce:EndAllSmallLines()
    for index, line in ipairs(self.activeLines[CSA_LINE_TYPE_SMALL]) do
        self:RemoveActiveLine(line)
    end
end

function CenterScreenAnnounce:IsTopSmallLine(line)
    return self.activeLines[CSA_LINE_TYPE_SMALL][1] == line
end

function CenterScreenAnnounce:SetMajorLineContainerHeight(animationProgress)
    local allMajorLines = self.activeLines[CSA_LINE_TYPE_MAJOR]
    local numCurrentMajorLines = zo_clamp(#allMajorLines + #self.pendingMajorMessages, 0, MAX_MAJOR_TEXT_LINES)
    local isGamepad = IsInGamepadPreferredMode()
    local lineSpacing = isGamepad and SMALL_TEXT_SPACING_GAMEPAD or SMALL_TEXT_SPACING_KEYBOARD
    local textHeight = isGamepad and self.MAJOR_LINE_HEIGHT_GAMEPAD or self.MAJOR_LINE_HEIGHT_KEYBOARD

    local calculatedContainerHeight = (lineSpacing + textHeight) * numCurrentMajorLines

    self.majorLineContainer:SetHeight(zo_lerp(self.startingMajorContainerHeight, calculatedContainerHeight, animationProgress))
end

function CenterScreenAnnounce:OnMajorLineContainerAnimationComplete(completedPlayback)
    if completedPlayback then
        -- add pending messages from newest to oldest, with any older ones being discarded
        for i = #self.pendingMajorMessages, 1, -1 do
            if #self.activeLines[CSA_LINE_TYPE_MAJOR] == MAX_MAJOR_TEXT_LINES then
                self:ReleaseMessageParams(self.pendingMajorMessages[i])
            else
                if not self:DisplayMessage(self.pendingMajorMessages[i]) then
                    self:ReleaseMessageParams(self.pendingMajorMessages[i])
                end
            end
        end
        ZO_ClearNumericallyIndexedTable(self.pendingMajorMessages)
    end
end

function CenterScreenAnnounce:StartMajorLineContainerAnimation(message)
    self.startingMajorContainerHeight = self.majorLineContainer:GetHeight()
    table.insert(self.pendingMajorMessages, message)
    self.majorLineContainerTimeline:PlayFromStart()
end

function CenterScreenAnnounce:GetNextShowableMessage(removeEntry)
    for i, messageParams in ipairs(self.displayQueue) do
        if self:CanDisplayMessage(messageParams:GetCategory(), messageParams:GetCSAType()) then
            if removeEntry then
                table.remove(self.displayQueue, i)
            end
            return messageParams
        end
    end
end

function CenterScreenAnnounce:TryDisplayingNextQueuedMessage()
    if self.isQueueDirty then
        self:SortQueue()
        self.isQueueDirty = false
    end

    local REMOVE_FROM_TABLE = true
    local nextMessage = self:GetNextShowableMessage(REMOVE_FROM_TABLE)
    if nextMessage then
        if nextMessage:GetCategory() == CSA_CATEGORY_MAJOR_TEXT and #self.activeLines[CSA_LINE_TYPE_MAJOR] < MAX_MAJOR_TEXT_LINES then
            self:StartMajorLineContainerAnimation(nextMessage)
        else
            self:DisplayMessage(nextMessage)
        end
    end
end

function CenterScreenAnnounce:ReleaseLine(completedLine, skipDisplayNext)
    self:RemoveActiveLine(completedLine)
    self:CheckNowInactive(skipDisplayNext)
end

function CenterScreenAnnounce:CheckNowInactive(skipDisplayNext)
    if not self:HasAnyActiveLines() and self.hasActiveLevelBar == false then
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

local setupFunctions =
{
    [CSA_CATEGORY_SMALL_TEXT] = function(self, messageParams)
        local announcementSmallLine, poolKey = self.smallLinePool:AcquireObject()
        announcementSmallLine:SetKey(poolKey)
        local lineControl = announcementSmallLine:GetControl()

        announcementSmallLine:SetText(messageParams:GetMostUniqueMessage())

        announcementSmallLine:SetWipeOutLifespan(messageParams:GetLifespanMS())

        local isGamepad = IsInGamepadPreferredMode()
        local initialLineOffset = isGamepad and INITIAL_SMALL_LINE_OFFSET_GAMEPAD_Y or INITIAL_SMALL_LINE_OFFSET_KEYBOARD_Y
        local lineSpacing = isGamepad and SMALL_TEXT_SPACING_GAMEPAD or SMALL_TEXT_SPACING_KEYBOARD

        local mostRecentSmallLine = self:GetMostRecentLine(CSA_LINE_TYPE_SMALL)
        if mostRecentSmallLine then
            initialLineOffset = (initialLineOffset + lineSpacing) / (#self.activeLines[CSA_LINE_TYPE_SMALL])
            local recentLineControl = mostRecentSmallLine:GetControl()
            lineControl:SetAnchor(TOP, recentLineControl, BOTTOM, 0, initialLineOffset)
        else
            lineControl:SetAnchor(TOP, self.smallLineContainer, TOP, 0, initialLineOffset)
        end

        announcementSmallLine:SetAndPlayStartingAnimation(-initialLineOffset)

        SCREEN_NARRATION_MANAGER:QueueCSA(messageParams)

        return announcementSmallLine
    end,

    [CSA_CATEGORY_LARGE_TEXT] = function(self, messageParams)
        local showImmediately = messageParams:GetShowImmediately()
        -- if we acquire our object before we call RemoveAllActiveLines, we will reset everything we setup for it
        if showImmediately then
            self:RemoveAllActiveLines()
        end

        local largeMessageLine, poolKey = self.largeLinePool:AcquireObject()
        largeMessageLine:SetKey(poolKey)

        largeMessageLine:SetLargeText(messageParams:GetMainText())
        largeMessageLine:SetSmallCombinedText(messageParams:GetSecondaryText())

        -- check for an overriding lifespan coming from the handlers, if not stick with the default        
        local lifespanMS = messageParams:GetLifespanMS()

        --We always want to make sure the fadeout happens at the end of the lifespan of the current
        --message even if that message shows immediately.
        largeMessageLine:SetWipeTimelineLifespan(lifespanMS)

        local largeMessageControl = largeMessageLine:GetControl()
        if showImmediately then
            local endTime = lifespanMS + GetFrameTimeMilliseconds()
            local function UpdateShowAnnouncementTime(control, timeS)
                local timeLeftMS = endTime - (timeS * 1000)
                if timeLeftMS <= 0 then
                    self:CallExpiringCallback(largeMessageLine)
                    largeMessageControl:SetDimensions(ZO_MIN_CSA_SCROLL_WIDTH, ZO_MAX_CSA_SCROLL_HEIGHT)
                    self:ReleaseLine(largeMessageLine)
                end
            end

            largeMessageControl:SetHandler("OnUpdate", UpdateShowAnnouncementTime)
            largeMessageControl:SetDimensions(ZO_MAX_CSA_SCROLL_WIDTH, ZO_MAX_CSA_SCROLL_HEIGHT)
            local ANIMATION = nil
            largeMessageLine.SetupWipeIn(ANIMATION, largeMessageControl)
        else
            if messageParams:GetShowBackground() then
                local backgroundControl = self.backgroundContainer:GetNamedChild("BG")
                backgroundControl:ClearAnchors()
                backgroundControl:SetAnchor(TOP, largeMessageLine.largeText, TOP, 0, -70)
                if messageParams:GetSecondaryText() then
                    if messageParams:GetLargeInformationIconData() then
                        backgroundControl:SetAnchor(BOTTOM, largeMessageLine.largeInformationIcon, BOTTOM, 0, 100)
                    else
                        backgroundControl:SetAnchor(BOTTOM, largeMessageLine.smallCombinedText, BOTTOM, 0, 80)
                    end
                else
                    backgroundControl:SetAnchor(BOTTOM, largeMessageLine.largeText, BOTTOM, 0, 70)
                end
                self.backgroundContainerFadeInTimeline:PlayFromStart()
                largeMessageLine:PlayWipeFadeAnimation()
            else
                largeMessageLine:PlayWipeAnimation()
            end
            self.isBeforeMessageExpiring = true
        end

        local icon, iconBg, iconColor = messageParams:GetIconData()
        largeMessageLine:SetIcon(icon, iconBg, messageParams:GetSuppressIconFrame() == CSA_OPTION_SUPPRESS_ICON_FRAME, iconColor)

        local largeInformationIcon = messageParams:GetLargeInformationIconData()
        largeMessageLine:SetLargeInformationIcon(largeInformationIcon)

        SCREEN_NARRATION_MANAGER:QueueCSA(messageParams)

        return largeMessageLine
    end,

    [CSA_CATEGORY_RAID_COMPLETE_TEXT] = function(self, messageParams)
        local largeMessageLine, poolKey = self.largeLinePool:AcquireObject()
        largeMessageLine:SetKey(poolKey)

        largeMessageLine:SetLargeText(messageParams:GetMainText())
        largeMessageLine:SetSmallCombinedText(messageParams:GetSecondaryText())
        largeMessageLine:SetRaidBreakdownText(messageParams:GetEndOfRaidData())

        largeMessageLine:SetWipeTimelineLifespan(messageParams:GetLifespanMS())
        largeMessageLine:PlayWipeAnimation()
        self.isBeforeMessageExpiring = true
        SCREEN_NARRATION_MANAGER:QueueCSA(messageParams)
        return largeMessageLine
    end,

    [CSA_CATEGORY_NO_TEXT] = function(self, messageParams)
        return nil
    end,

    [CSA_CATEGORY_MAJOR_TEXT] = function(self, messageParams)
        local announcementMajorLine, poolKey = self.majorLinePool:AcquireObject()
        announcementMajorLine:SetKey(poolKey)
        local lineControl = announcementMajorLine:GetControl()
        announcementMajorLine:SetText(messageParams:GetMostUniqueMessage())

        local icon, iconBg = messageParams:GetIconData()
        announcementMajorLine:SetIcon(icon, iconBg, messageParams:GetSuppressIconFrame() == CSA_OPTION_SUPPRESS_ICON_FRAME)

        local isGamepad = IsInGamepadPreferredMode()
        local lineSpacing = isGamepad and MAJOR_TEXT_SPACING_GAMEPAD or MAJOR_TEXT_SPACING_KEYBOARD

        local textHeight = announcementMajorLine.iconControl:GetHeight()
        local allMajorLines = self.activeLines[CSA_LINE_TYPE_MAJOR]
        local numCurrentMajorLines = #allMajorLines

        -- We do not wait for older lines to be removed if we want to add
        -- a new major event. Instead just forcefully remove the oldest one
        if numCurrentMajorLines == MAX_MAJOR_TEXT_LINES then
            self:RemoveActiveLine(allMajorLines[1])
            numCurrentMajorLines = #allMajorLines
        end

        for i, line in ipairs(allMajorLines) do
            local otherLineControl = line:GetControl()
            otherLineControl:ClearAnchors()
            otherLineControl:SetAnchor(TOP, self.majorLineContainer, TOP, 0, (lineSpacing + textHeight) * (numCurrentMajorLines - i + 1))
        end

        lineControl:SetAnchor(TOP, self.majorLineContainer, TOP, 0, 0)

        announcementMajorLine:SetAndPlayStartingAnimation(messageParams:GetLifespanMS())
        SCREEN_NARRATION_MANAGER:QueueCSA(messageParams)
        return announcementMajorLine
    end,

    [CSA_CATEGORY_COUNTDOWN_TEXT] = function(self, messageParams)
        -- Nothing can show while countdowns are showing
        self:RemoveAllActiveLines()

        local announcementCountdownLine, poolKey = self.countdownLinePool:AcquireObject()
        announcementCountdownLine:SetKey(poolKey)
        local lineControl = announcementCountdownLine:GetControl()

        announcementCountdownLine:SetEndImageTexture(messageParams:GetIconData())
        announcementCountdownLine:SetAndPlayStartingAnimation(messageParams:GetLifespanMS())

        lineControl:SetAnchor(TOP, self.countdownLineContainer)

        return announcementCountdownLine
    end,

    [CSA_CATEGORY_SCRYING_PROGRESS_TEXT] = function(self, messageParams)
        local largeMessageLine, poolKey = self.largeLinePool:AcquireObject()
        largeMessageLine:SetKey(poolKey)

        largeMessageLine:SetLargeText(messageParams:GetMainText())
        largeMessageLine:SetSmallCombinedText(messageParams:GetSecondaryText())
        largeMessageLine:SetScryingUpdatedIconData(self.scryingUpdatedIconPool, messageParams:GetScryingProgressData())
        largeMessageLine:SetWipeTimelineLifespan(messageParams:GetLifespanMS())
        largeMessageLine:PlayWipeAnimation()
        self.isBeforeMessageExpiring = true
        SCREEN_NARRATION_MANAGER:QueueCSA(messageParams)
        return largeMessageLine
    end,

    [CSA_CATEGORY_EXTERNAL_HANDLE] = function(self, messageParams)
        return nil
    end,

    [CSA_CATEGORY_ROLLING_METER_PROGRESS_TEXT] = function(self, messageParams)
        local largeMessageLine, poolKey = self.largeLinePool:AcquireObject()
        largeMessageLine:SetKey(poolKey)

        largeMessageLine:SetLargeText(messageParams:GetMainText())
        largeMessageLine:SetSmallCombinedText(messageParams:GetSecondaryText())
        largeMessageLine:SetRollingMeterProgressData(self.rollingMeterProgressPool, messageParams:GetRollingMeterProgressData())
        largeMessageLine:SetWipeTimelineLifespan(messageParams:GetLifespanMS())
        largeMessageLine:PlayWipeAnimation()

        self.isBeforeMessageExpiring = true
        SCREEN_NARRATION_MANAGER:QueueCSA(messageParams)
        return largeMessageLine
    end,

    [CSA_CATEGORY_ANIMATED_CONTROL] = function(self, messageParams)
        local largeMessageLine, poolKey = self.largeLinePool:AcquireObject()
        largeMessageLine:SetKey(poolKey)

        -- Order matters:
        largeMessageLine:SetLargeText(messageParams:GetMainText())
        largeMessageLine:SetSmallCombinedText(messageParams:GetSecondaryText())
        largeMessageLine:SetCustomAnimationTimeline(messageParams:GetCustomAnimationTimeline())
        largeMessageLine:SetWipeTimelineLifespan(messageParams:GetLifespanMS())
        largeMessageLine:PlayWipeAnimation()

        self.isBeforeMessageExpiring = true
        SCREEN_NARRATION_MANAGER:QueueCSA(messageParams)
        return largeMessageLine
    end,
}

function CenterScreenAnnounce:CallExpiringCallback(announcementLine)
    local messageParams = announcementLine:GetMessageParams()
    messageParams:CallExpiringCallback()

    self.isBeforeMessageExpiring = false

    if messageParams:GetCategory() == CSA_CATEGORY_LARGE_TEXT and messageParams:GetShowBackground() then
        self.backgroundContainerFadeOutTimeline:PlayFromStart()
    end

    if PLAYER_PROGRESS_BAR:GetOwner() == self then
        PLAYER_PROGRESS_BAR:SetHoldBeforeFadeOut(false)
    end
end

function CenterScreenAnnounce:RemoveAllCSAsOfAnnounceType(announceType)
    --First, go through anything in the display queue that matches the type, and remove it
    for i, entry in ZO_NumericallyIndexedTableReverseIterator(self.displayQueue) do
        if entry.csaType == announceType then
            table.remove(self.displayQueue, i)
        end
    end

    --Loop through each active line
    for lineStyle, lineStyleTable in pairs(self.activeLines) do
        for _, line in ipairs(lineStyleTable) do
            if line.messageParams and line.messageParams.csaType == announceType then
                --The animations for each of the line types are stored in different locations, so we need a separate implementation for each type
                if lineStyle == CSA_LINE_TYPE_LARGE then
                    if line.messageParams:GetShowBackground() then
                        line.wipeFadeAnimationTimeline:PlayInstantlyToEnd()
                    else
                        line.wipeAnimationTimeline:PlayInstantlyToEnd()
                    end
                elseif lineStyle == CSA_LINE_TYPE_SMALL then
                    line.translateTimeline:PlayInstantlyToEnd(true)
                    line.fadeInTimeline:PlayInstantlyToEnd(true)
                    line.fadeOutTimeline:PlayInstantlyToEnd()
                elseif lineStyle == CSA_LINE_TYPE_COUNTDOWN then
                    line.countdownLoopAnimationTimeline:PlayInstantlyToEnd(true)
                    line.countdownBufferAnimationTimeline:PlayInstantlyToEnd(true)
                    line.countdownEndImageAnimationTimeline:PlayInstantlyToEnd()
                end
            end
        end
    end
end

-- Legacy support for addons
function CenterScreenAnnounce:AddMessage(eventId, category, ...)
    local messageParams = self:CreateMessageParams(category)
    messageParams:ConvertOldParams(...)
    self:AddMessageWithParams(messageParams)
end

do
    local ALLOWED_QUEUE_TYPES_WHILE_CRAFTING =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_ADDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_CONDITION_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_OBJECTIVE_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_INFAMY_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NOW_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NO_LONGER_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_TRIBUTE_CARD_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_CRAFTING_RESULTS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_CLUB_RANK_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_CONSOLIDATED_STATION_SETS_UPDATED] = true,
    }

    -- Types that if they were to happen while scrying for an antiquity
    -- will be stored and shown after the scrying game is over
    local ALLOWED_QUEUE_TYPES_WHILE_SCRYING =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIG_SITES_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_SCRYING_RESULT] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_INFAMY_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NO_LONGER_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NOW_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_OBJECTIVE_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_ADDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_CONDITION_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_TRIBUTE_CARD_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_RANK_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_XP_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TIMED_ACTIVITY_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_CLUB_RANK_CHANGED] = true,
    }

    -- Types that if they were to happen while digging for an antiquity
    -- will be stored and shown after the digging game is over
    local ALLOWED_QUEUE_TYPES_WHILE_ANTIQUITIES_DIGGING =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIGGING_GAME_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_LEAD_ACQUIRED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_INFAMY_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NO_LONGER_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NOW_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_OBJECTIVE_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_ADDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_CONDITION_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_TRIBUTE_CARD_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_RANK_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_XP_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TIMED_ACTIVITY_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_CLUB_RANK_CHANGED] = true,
    }

    -- Types that if they were to happen while showing tribute
    -- will be stored and shown after the tribute is over
    local ALLOWED_QUEUE_TYPES_WHILE_IN_TRIBUTE =
    {
        [CENTER_SCREEN_ANNOUNCE_TYPE_ACHIEVEMENT_AWARDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_GAME_STATE_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_DIGGING_GAME_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_ANTIQUITY_LEAD_ACQUIRED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_INFAMY_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NO_LONGER_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_JUSTICE_NOW_KOS] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_OBJECTIVE_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_ADDED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_CONDITION_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_QUEST_PROGRESSION_CHANGED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_TRIBUTE_CARD_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SINGLE_COLLECTIBLE_UPDATED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_RANK_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_XP_UPDATE] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TIMED_ACTIVITY_COMPLETED] = true,
        [CENTER_SCREEN_ANNOUNCE_TYPE_TRIBUTE_CLUB_RANK_CHANGED] = true,
    }
    
    -- Per Design, MarketAnnouncment defaults to queuing everything.
    -- Types that if they were to happen while showing Announcements
    -- will be discarded and not queued.
    local BLOCKED_QUEUE_TYPES_WHILE_IN_MARKET_ANNOUNCEMENT =
    {
    }
    
    function CenterScreenAnnounce:AddMessageWithParams(messageParams)
        if not messageParams then
            return
        end

        local category = messageParams:GetCategory()
        if category ~= nil then
            local csaType = messageParams:GetCSAType()
            local isAvAEvent = messageParams:IsAvAEvent()
            local barParams = messageParams:GetBarParams()
            local externalHandleCallback = messageParams:GetExternalHandleCallback()

            if category == CSA_CATEGORY_NO_TEXT and barParams == nil then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            if category == CSA_CATEGORY_EXTERNAL_HANDLE and externalHandleCallback == nil then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            -- prevent unwanted announcements from queuing when the user is crafting
            if ZO_CraftingUtils_IsCraftingWindowOpen() and not ALLOWED_QUEUE_TYPES_WHILE_CRAFTING[csaType] then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            -- prevent unwanted announcements from queuing when the user is scrying
            if (SCRYING_SCENE:IsShowing() or WORLD_MAP_MANAGER:IsInMode(MAP_MODE_DIG_SITES)) and not ALLOWED_QUEUE_TYPES_WHILE_SCRYING[csaType] then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            -- prevent unwanted announcements from queuing when the user is digging for antiquities
            if ANTIQUITY_DIGGING_FRAGMENT:IsShowing() and not ALLOWED_QUEUE_TYPES_WHILE_ANTIQUITIES_DIGGING[csaType] then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            -- prevent unwanted announcements from queuing when the user is in tribute
            if TRIBUTE_FRAGMENT:IsShowing() and not ALLOWED_QUEUE_TYPES_WHILE_IN_TRIBUTE[csaType] then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            if SCENE_MANAGER:IsShowing("marketAnnouncement") then
                -- Market announcement defaults to queueing everything and blocking only named items.
                if BLOCKED_QUEUE_TYPES_WHILE_IN_MARKET_ANNOUNCEMENT[csaType] then
                    self.messageParamsPool:ReleaseObject(messageParams.key)
                    return
                end
            end

            -- prevent unwanted announcements that have been specified as supressed
            if self:GetSupressAnnouncementByType(csaType) then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            if isAvAEvent and not self:CanShowAvAEvent() then
                self.messageParamsPool:ReleaseObject(messageParams.key)
                return
            end

            -- Checking the recency of the message should be sufficient for duplicate messages
            -- Otherwise, this needs to combine the full message text into a single string and check the recency of that.
            -- MLR: Changing to use the Combined message when available because when multiple similar messages come in on the same frame,
            -- the recency sees them as the same message and only the first will display.
            local message = messageParams:GetMostUniqueMessage()

            if message == nil or self.recentMessages:ShouldDisplayMessage(message) then
                self:QueueMessage(messageParams)
            else
                messageParams:CallExpiringCallback()
                self.messageParamsPool:ReleaseObject(messageParams.key)
            end
        end
    end
end

function CenterScreenAnnounce:QueueMessage(messageParams)
    --Delay choosing the next message to show by WAIT_INTERVAL_SECONDS each time a new message comes in to stabilize a bit
    local shouldQueueImmediately, reinsertStompedMsg = messageParams:GetQueueImmediately()
    local category = messageParams:GetCategory()

    -- events that should QueueImmediately and the countdown event both need to display their message immediately
    if shouldQueueImmediately or category == CSA_CATEGORY_COUNTDOWN_TEXT then
        local oldestLine = self:GetOldestLine(CSA_LINE_TYPE_LARGE)
        if oldestLine then
            if reinsertStompedMsg then
                --If we are interrupting a message, lets put the current message back in the queue so it can come back 
                --up when were done with the immediate message that is interrupting.
                local oldestMessageParams = oldestLine:GetMessageParams()
                oldestMessageParams:SetQueuedOrder(self.nextQueueIndex)
                table.insert(self.displayQueue, 1, oldestMessageParams)
                oldestLine:SetShouldCleanupMessageParams(false)
            end
            self:ReleaseLine(oldestLine)
        end

        -- this has to be called after we check on the current message
        self:DisplayMessage(messageParams)

        return
    end
    
    local waitOffset = shouldQueueImmediately and NO_WAIT_INTERVAL_SECONDS or WAIT_INTERVAL_SECONDS
    local timeNowSeconds = GetFrameTimeSeconds()
    self.nextUpdateTimeSeconds = timeNowSeconds + waitOffset

    messageParams:SetQueuedOrder(self.nextQueueIndex)
    table.insert(self.displayQueue, messageParams)
    self.nextQueueIndex = self.nextQueueIndex + 1
    self.isQueueDirty = true
end

function CenterScreenAnnounce:DisplayMessage(messageParams)
    local category = messageParams:GetCategory()
    if self:ShouldRejectCategory(category) then
        self.messageParamsPool:ReleaseObject(messageParams.key)
        return false
    end

    local setupFunction = setupFunctions[category]
    if setupFunction then
        local displayLine = setupFunction(self, messageParams)
        if displayLine then
            self:AddActiveLine(displayLine)
            displayLine:SetMessageParams(messageParams)
        end

        -- Countdown events play their sound at the end of the countdown
        if category ~= CSA_CATEGORY_COUNTDOWN_TEXT then
            messageParams:PlaySound()
        end

        local externalHandleCallback = messageParams:GetExternalHandleCallback()
        if category == CSA_CATEGORY_EXTERNAL_HANDLE and externalHandleCallback then
            --The external handle callback should return true if we need to wait to be notified before moving on
            --It will return false if we want to continue immediately
            self.isWaitingOnExternalHandle = externalHandleCallback()
        end

        local barParams = messageParams:GetBarParams()
        if barParams then
            if category == CSA_CATEGORY_LARGE_TEXT or category == CSA_CATEGORY_NO_TEXT then
                local barType, startLevel, start, stop, sound = barParams:GetParams()
                if stop - start > 0 or barParams.showNoGain then
                    self.hasActiveLevelBar = true
                    PLAYER_PROGRESS_BAR:ShowIncrease(barType, startLevel, start, stop, sound, category == CSA_CATEGORY_NO_TEXT and BAR_PARAMS_NO_WAIT_INTERVAL_MS or BAR_PARAMS_WAIT_INTERVAL_MS, self)
                    if not (barType and PLAYER_PROGRESS_BAR:GetBarTypeInfoByBarType(barType)) then
                        local INVALID_VALUE = -1
                        internalassert(false, string.format("CSA Bad Bar Params; barType: %d. Triggering Event: %d", barType or INVALID_VALUE, barParams:GetTriggeringEvent() or INVALID_VALUE))
                    end
                end
            end
        end

        local onDisplayCallback = messageParams:GetOnDisplayCallback()
        if onDisplayCallback then
            onDisplayCallback(messageParams)
        end

        if not displayLine then
            self.messageParamsPool:ReleaseObject(messageParams.key)
        end

        return true
    end

    return false
end

function CenterScreenAnnounce:SupressAnnouncementByType(csaType)
    if not self.suppressAnnouncements then
        self.suppressAnnouncements = {}
    end

    if not self.suppressAnnouncements[csaType] then
        self.suppressAnnouncements[csaType] = 0
    end

    self.suppressAnnouncements[csaType] = self.suppressAnnouncements[csaType] + 1
end

function CenterScreenAnnounce:GetSupressAnnouncementByType(csaType)
    if self.suppressAnnouncements and self.suppressAnnouncements[csaType] then
        return self.suppressAnnouncements[csaType] > 0
    end

    return false
end

function CenterScreenAnnounce:ResumeAnnouncementByType(csaType)
    if self.suppressAnnouncements and self.suppressAnnouncements[csaType] then
        self.suppressAnnouncements[csaType] = self.suppressAnnouncements[csaType] - 1
    end
end

function CenterScreenAnnounce:ReleaseExternalHandle()
    self.isWaitingOnExternalHandle = false
end

function CenterScreenAnnounce:CanShowAvAEvent()
    local setting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_AVA_NOTIFICATIONS))
    if setting == ACTION_BAR_SETTING_CHOICE_ON then
        return true
    elseif setting == ACTION_BAR_SETTING_CHOICE_AUTOMATIC then
        return IsPlayerInAvAWorld()
    end

    return false
end

-- Gets or creates and returns the singleton animation timeline for Endless Dungeon buff acquisition CSAs.
function CenterScreenAnnounce:GetEndlessDungeonBuffAddedAnimationTimeline()
    if not self.endlessDungeonBuffAddedAnimationTimeline then
        self.endlessDungeonBuffAddedAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CenterScreenEndDunBuffAddedAnimation", ZO_CenterScreenEndDunBuffAddedIcon)

        self.endlessDungeonBuffAddedAnimationTimeline:SetHandler("OnPlay", function(timeline, completed)
            local control = timeline:GetFirstAnimation():GetAnimatedControl()
            control:SetHidden(false)
        end)

        self.endlessDungeonBuffAddedAnimationTimeline:SetHandler("OnStop", function(timeline, completed)
            local control = timeline:GetFirstAnimation():GetAnimatedControl()
            control:SetHidden(true)
        end)
    end

    return self.endlessDungeonBuffAddedAnimationTimeline
end

-- Exposed so that external code can add custom events with appropriate priorities
local nextAutoPriority = 1
function ZO_CenterScreenAnnounce_SetPriority(csaType, priority)
    if priority == nil then
        priority = nextAutoPriority
        nextAutoPriority = nextAutoPriority + 1
    end
    
    messagePriorities[csaType] = priority
end

function ZO_CenterScreenAnnounce_Initialize(self)
    CENTER_SCREEN_ANNOUNCE = CenterScreenAnnounce:New(self)

    ZO_CenterScreenAnnounce_InitializePriorities()
end

function ZO_CenterScreenAnnounce_ScryingUpdated_Icon_OnInitialized(iconTexture)
    iconTexture.fadeInTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CenterScreenScryingUpdatedIconFadeIn", iconTexture)
    iconTexture.achievedIcon = iconTexture:GetNamedChild("AchievedIcon")
end

function ZO_CenterScreenAnnounce_RollingMeterProgress_OnInitialized(control)
    control.icon = control:GetNamedChild("Icon")

    control.label = control:GetNamedChild("Label")
    -- The audio should always sound like the counter is rolling up even when
    -- the digits are rolling back to "1" at the end of a cycle or arc.
    control.label:SetAnimationSoundIds(SOUNDS.ENDLESS_DUNGEON_COUNTER_UP, SOUNDS.ENDLESS_DUNGEON_COUNTER_UP)
    control.label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    local isGamepad = IsInGamepadPreferredMode()
    control.label:SetFont(isGamepad and ROLLING_METER_TEXT_GAMEPAD or ROLLING_METER_TEXT_KEYBOARD)
    control.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    control.label:SetResizeToFitLabels(true)

    control.labelTransitionManager = control.label:GetOrCreateTransitionManager()
    -- Guarantee that each transition will use no more than one rollover
    -- animation and therefore execute in left-to-right order:
    control.labelTransitionManager:SetMaxTransitionSteps(1)
    control.labelTransitionManager:SetTransitionAccelerationFactor(0)
    control.labelTransitionManager:SetTransitionSpeedFactor(1.5)

    control.transitionTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CenterScreenRollingMeterProgressTransition", control)
    control.transitionAnimation = control.transitionTimeline:GetAnimation(1)
end

function ZO_CenterScreenEndlessDungeonBuffAddedAnimation_OnUpdate(animation, progress)
    local control = animation:GetAnimatedControl()
    if control.targetControl then
        local easedProgress = progress * progress * progress
        local quinticEasedProgress = easedProgress * progress * progress
        local progressInverse = 1 - progress
        local easedProgressInverse = progressInverse * progressInverse * progressInverse
        local currentX = zo_lerp(control.animationStartX, control.animationEndX, 1 - easedProgressInverse)
        local currentY = zo_lerp(control.animationStartY, control.animationEndY, easedProgress)
        -- Translate the icon from beneath the CSA to inside of the
        -- Endless Dungeon HUD Tracker's keybind label.
        control:SetAnchor(CENTER, GuiRoot, TOPLEFT, currentX, currentY)

        -- Scale starts at double size; interpolates to half size
        -- aggressively at the very end of the animation interval.
        local scale = 2 - quinticEasedProgress * 1.5
        control:SetScale(scale)

        -- The arc tangent of the slope of the translation yields the
        -- angular direction of the control animation's forward vector
        -- in two dimensional space.
        local blurTangentRadians = math.atan2(easedProgressInverse, easedProgress)
        -- Offset the direction vector by the control origin in UV space.
        local blurOriginX = 0.5 + zo_sin(blurTangentRadians) * 0.75
        local blurOriginY = 0.5 - zo_cos(blurTangentRadians) * 0.75
        local blurStrength = 1
        if progress < 0.1 then
            -- Ease into maximum blur strength over the first 10%
            -- of the animation interval.
            local segmentProgress = progress * 9
            blurStrength = segmentProgress * segmentProgress
        elseif progress >= 0.2 then
            -- Ease out of maximum blur strength over the remaining
            -- 90% of the animation interval.
            local segmentProgress = (progress - 0.1) * 1.111
            blurStrength = 1 - (segmentProgress * segmentProgress)
        end
        blurStrength = blurStrength * 0.1
        local numSamples = blurStrength * control:GetWidth()
        local BLUR_OFFSET_NORMALIZED = 0.0
        control:SetShaderEffectType(SHADER_EFFECT_TYPE_RADIAL_BLUR)
        control:SetRadialBlur(blurOriginX, blurOriginY, numSamples, blurStrength, BLUR_OFFSET_NORMALIZED)

        if progress >= 0.4 and progress < 0.6 then
            -- Eased scaling of the target control to enlarge during
            -- the second quarter of the animation interval.
            local segmentProgress = (progress - 0.4) * 5
            local offsetY = ZO_BezierInEase(segmentProgress) * -20
            control.targetControl:SetTransformOffsetY(offsetY)
        elseif progress >= 0.8 then
            -- Eased scaling of the target control to return to its
            -- original scale during the last fifth of the animation
            -- interval.
            local segmentProgress = (progress - 0.8) * 5
            local offsetY = ZO_BezierInEase(1 - segmentProgress) * -20
            control.targetControl:SetTransformOffsetY(offsetY)
        end
    end
end

function ZO_CenterScreenEndlessDungeonBuffAdded_Setup(abilityId, startBeneathControl, endCenteredOnControl)
    local control = ZO_CenterScreenEndDunBuffAddedIcon
    local startVerticalOffset = 5 + control:GetHeight() * 2
    if IsInGamepadPreferredMode() then
        control:SetDimensions(ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_GAMEPAD_X, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_GAMEPAD_Y)
        startVerticalOffset = 5 + ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_GAMEPAD_Y * 2
    else
        control:SetDimensions(ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_KEYBOARD_X, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_KEYBOARD_Y)
        startVerticalOffset = 5 + ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_KEYBOARD_Y * 2
    end
    control:SetScale(2)
    control:SetShaderEffectType(SHADER_EFFECT_TYPE_NONE)

    local iconTextureFile = GetAbilityIcon(abilityId)
    control:SetTexture(iconTextureFile)

    local startX, startY = startBeneathControl:GetCenter()
    -- Offset the vertical center to account for the animated control height.
    startY = startY + startBeneathControl:GetHeight() * 0.5 + startVerticalOffset
    control:SetAnchor(CENTER, GuiRoot, TOPLEFT, startX, startY)

    local endX, endY = nil, nil
    if endCenteredOnControl then
        endX, endY = endCenteredOnControl:GetCenter()
        -- Offset the horizontal center by one quarter of the control width
        -- to account for the timed scaling of the target control.
        local END_CONTROL_HORIZONTAL_OFFSET_PERCENT = 0.2
        endX = endX - endCenteredOnControl:GetWidth() * END_CONTROL_HORIZONTAL_OFFSET_PERCENT
    end

    control.animationStartX = startX
    control.animationStartY = startY
    control.animationEndX = endX
    control.animationEndY = endY
    control.targetControl = endCenteredOnControl
    control:SetHidden(false)
end