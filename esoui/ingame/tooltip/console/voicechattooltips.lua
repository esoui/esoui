function ZO_Tooltip:LayoutVoiceChatChannel(channelData)
    local name = channelData.name
    local description = channelData.description

    --Title
    local headerSection = self:AcquireSection(self:GetStyle("voiceChatBodyHeader"))
    headerSection:AddLine(channelData.name, self:GetStyle("title"))
    self:AddSection(headerSection)

    --Body
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(description, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutVoiceChatParticipantHistory(displayName, channelName, lastTimeSpoken)
    local timeText = ""
    if lastTimeSpoken then
        local timeDifference = GetFrameTimeMilliseconds() - lastTimeSpoken
        timeText = ZO_FormatTimeMilliseconds(timeDifference, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
    end

    --Title
    local headerSection = self:AcquireSection(self:GetStyle("voiceChatBodyHeader"))
    headerSection:AddLine(ZO_FormatUserFacingDisplayName(displayName), self:GetStyle("voiceChatGamepadSpeakerTitle"))
    self:AddSection(headerSection)

    --Body
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    
    local statValuePair1 = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    local statValuePair2 = self:AcquireStatValuePair(self:GetStyle("voiceChatGamepadStatValuePair"))
    
    statValuePair1:SetStat(GetString(SI_GAMEPAD_VOICECHAT_HISTORY_TIP_LAST_HEARD), self:GetStyle("statValuePairStat"))
    statValuePair1:SetValue(timeText, self:GetStyle("statValuePairValue"))

    statValuePair2:SetStat(GetString(SI_GAMEPAD_VOICECHAT_HISTORY_TIP_CHANNEL), self:GetStyle("statValuePairStat"))
    statValuePair2:SetValue(channelName, self:GetStyle("statValuePairValue"))
    
    bodySection:AddStatValuePair(statValuePair1)
    bodySection:AddStatValuePair(statValuePair2)

    self:AddSection(bodySection)
end


local SPEAK_STATUS_TO_ICON = {
    [VOICE_CHAT_SPEAK_STATE_SPEAKING] = "EsoUI/Art/VOIP/Gamepad/gp_VOIP_speaking.dds",
    [VOICE_CHAT_SPEAK_STATE_MUTED] = "EsoUI/Art/VOIP/Gamepad/gp_VOIP_muted.dds",
}

function ZO_Tooltip:LayoutVoiceChatParticipant(displayName, speakStatus, isMuted)
    if isMuted and speakStatus ~= VOICE_CHAT_SPEAK_STATE_NONE then
        speakStatus = VOICE_CHAT_SPEAK_STATE_MUTED
    end

    local row = self:AcquireSection(self:GetStyle("voiceChatGamepadSpeaker"))
    row:AddLine(ZO_FormatUserFacingDisplayName(displayName), self:GetStyle("voiceChatGamepadSpeakerText"))
    local icon = SPEAK_STATUS_TO_ICON[speakStatus]
    if icon then
        row:AddTexture(icon, self:GetStyle("voiceChatGamepadSpeakerIcon"))
    end

    self:AddSection(row)
end

function ZO_Tooltip:LayoutVoiceChatParticipants(channelData, participantDataList)
    --Header
    local channelType = channelData.channelType
    local titleText
    if channelType == VOICE_CHANNEL_GUILD then
        titleText = zo_strformat(SI_GAMEPAD_VOICECHAT_PARTICIPANTS_GUILD_HEADER, channelData.guildName, channelData.name)
    else
        titleText = channelData.name
    end

    local headerSection = self:AcquireSection(self:GetStyle("voiceChatBodyHeader"))
    headerSection:AddLine(titleText, self:GetStyle("title"))

    local statValuePair = self:AcquireStatValuePair(self:GetStyle("voiceChatPair"))
    statValuePair:SetStat(GetString(SI_GAMEPAD_VOICECHAT_PARTICIPANTS_HEADER), self:GetStyle("voiceChatPairLabel"))
    statValuePair:SetValue(#participantDataList, self:GetStyle("voiceChatPairText"))
    headerSection:AddStatValuePair(statValuePair)
    self:AddSection(headerSection)

    --Reputation
    if channelData.hasBadReputation then
        local reputationSection = self:AcquireSection(self:GetStyle("bodySection"))

        local badRepText
        local platform = GetUIPlatform()
        if platform == UI_PLATFORM_PS4 then
            badRepText = GetString(SI_GAMEPAD_VOICECHAT_PARTICIPANTS_REPUTATION_RESTRICTION_PS4)
        elseif platform == UI_PLATFORM_XBOX then
            badRepText = GetString(SI_GAMEPAD_VOICECHAT_PARTICIPANTS_REPUTATION_RESTRICTION_XB1)
        end
        reputationSection:AddLine(badRepText, self:GetStyle("voiceChatGamepadReputation"))

        self:AddSection(reputationSection)
    end

    --Participants
    for i = 1, #participantDataList do
        local speakerData = participantDataList[i]
        local displayName = speakerData.displayName
        local speakStatus = speakerData.speakStatus

        if speakerData.isMuted then
            speakStatus = VOICE_CHAT_SPEAK_STATE_IDLE
        end

        self:LayoutVoiceChatParticipant(displayName, speakStatus, speakerData.isMuted)
    end
end