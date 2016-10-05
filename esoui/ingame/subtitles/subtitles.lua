----
-- ZO_Subtitle
----

local ZO_Subtitle = ZO_Object:Subclass()

function ZO_Subtitle:New(...)
    local subtitle = ZO_Object.New(self)
    subtitle:Initialize(...)
    return subtitle
end

do
    local CHARACTERS_PER_SECOND = 10
    local MIN_DISPLAY_LENGTH_SECONDS = 3
    local MAX_DISPLAY_LENGTH_SECONDS = 12
    function ZO_Subtitle:Initialize(messageType, speaker, message)
        self.messageType = messageType
        self.speakerName = speaker
        self.messageText = message

        self.startTimeSeconds = 0

        local messageLength = ZoUTF8StringLength(message)
        self.displayLengthSeconds = zo_clamp(messageLength / CHARACTERS_PER_SECOND, MIN_DISPLAY_LENGTH_SECONDS, MAX_DISPLAY_LENGTH_SECONDS)
    end
end

function ZO_Subtitle:GetMessageType()
    return self.messageType
end

function ZO_Subtitle:GetMessage()
    return self.messageText
end

function ZO_Subtitle:GetSpeakerName()
    return self.speakerName
end

function ZO_Subtitle:GetFormattedMessage(showSpeakerName)
    if showSpeakerName then
        return zo_strformat(SI_SUBTITLE_FORMAT, self.speakerName, self.messageText)
    else
        return zo_strformat(SI_SUBTITLE_FORMAT_WITHOUT_SPEAKER, self.messageText)
    end
end

function ZO_Subtitle:GetDisplayLength()
    return self.displayLengthSeconds
end

function ZO_Subtitle:GetStartTime()
    return self.startTimeSeconds
end

function ZO_Subtitle:SetStartTime(startTimeSeconds)
    self.startTimeSeconds = startTimeSeconds
end

function ZO_Subtitle:HasExpired(currentTimeSeconds)
    return self.startTimeSeconds + self.displayLengthSeconds <= currentTimeSeconds
end

----
-- ZO_SubtitleManager
----

ZO_SubtitleManager = ZO_Object:Subclass()

function ZO_SubtitleManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SubtitleManager:Initialize(control)
    SUBTITLE_HUD_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
    self.control = control
    self.messageText = control:GetNamedChild("Text")
    self.messageBackground = self.messageText:GetNamedChild("Background")

    self:InitializePlatformStyles()

    self.fadeInAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_Subtitles_TextFadeIn", self.messageText)

    self.control:RegisterForEvent(EVENT_SHOW_SUBTITLE, function(event, ...) self:OnShowSubtitle(...) end)
    EVENT_MANAGER:RegisterForUpdate("ZO_SubtitleManager", 1000, function(...) self:OnUpdate(...) end)
end

--platform style

local KEYBOARD_STYLES = {
                            textTemplate = "ZO_Subtitles_Text_Keyboard_Template",
                            textWidth = 1200,
                        }

local GAMEPAD_STYLES =  {
                            textTemplate = "ZO_Subtitles_Text_Gamepad_Template",
                            textWidth = 890,
                        }

function ZO_SubtitleManager:UpdatePlatformStyles(styleTable)
    ApplyTemplateToControl(self.messageText, styleTable.textTemplate)
    self.messageText:SetWidth(styleTable.textWidth)
end

function ZO_SubtitleManager:InitializePlatformStyles()
    ZO_PlatformStyle:New(function(...) self:UpdatePlatformStyles(...) end, KEYBOARD_STYLES, GAMEPAD_STYLES)
end

function ZO_SubtitleManager:FadeInSubtitle()
    if self.fadeInAnimation:IsPlaying() then
        self.fadeInAnimation:PlayForward()
    else
        -- if we are already fully faded in, then do a bit of a "flash"
        -- to help transition to the new text that is being displayed
        if self.messageText:GetAlpha() >= 0.8 then
            self.fadeInAnimation:SetProgress(0.6)
            self.fadeInAnimation:PlayForward()
        else
            self.fadeInAnimation:PlayFromStart()
        end
    end
end

function ZO_SubtitleManager:FadeOutSubtitle()
    if self.fadeInAnimation:IsPlaying() then
        self.fadeInAnimation:PlayBackward()
    else
        -- if we are already faded out, don't do anything
        local alpha = self.messageText:GetAlpha()
        if alpha ~= 0 then
            self.fadeInAnimation:PlayFromEnd()
        end
    end
end

do
    local HIDE_SAME_SPEAKER_NAME_TIME_WINDOW_SECONDS = 5
    function ZO_SubtitleManager:OnShowSubtitle(messageType, speaker, message)
        self.previousSubtitle = self.currentSubtitle or self.previousSubtitle
        subtitle = ZO_Subtitle:New(messageType, speaker, message)

        local showSpeakerName = true
        local currentTime = GetFrameTimeSeconds()
        local previousSubtitle = self.previousSubtitle
        if previousSubtitle and previousSubtitle:GetSpeakerName() == speaker then
            -- if the same person says something within 5 seconds of when the last subtitle would end
            -- then hide the speaker name
            if previousSubtitle:GetStartTime() + previousSubtitle:GetDisplayLength() + HIDE_SAME_SPEAKER_NAME_TIME_WINDOW_SECONDS >= currentTime then
                showSpeakerName = false
            end
        end

        local messageControl = self.messageText
        messageControl:SetText(subtitle:GetFormattedMessage(showSpeakerName))
        local r, g, b
        if showSpeakerName then
            r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
        else
            r, g, b = ZO_SELECTED_TEXT:UnpackRGB()
        end

        messageControl:SetColor(r, g, b, self.messageText:GetAlpha())

        --resize the background to match the size of the text not the size of the label
        local width = messageControl:GetTextWidth()
        self.messageBackground:SetWidth(width)

        subtitle:SetStartTime(currentTime)
        self.currentSubtitle = subtitle

        self:FadeInSubtitle()
    end
end

function ZO_SubtitleManager:OnUpdate(currentMS)
    if self.currentSubtitle then
        local currentSeconds = currentMS / 1000.0
        if self.currentSubtitle:HasExpired(currentSeconds) then
            self.previousSubtitle = self.currentSubtitle
            self.currentSubtitle = nil
            self:FadeOutSubtitle()
        end
    end
end

function ZO_Subtitles_OnInitialize(control)
    ZO_SUBTITLE_MANAGER = ZO_SubtitleManager:New(control)
end