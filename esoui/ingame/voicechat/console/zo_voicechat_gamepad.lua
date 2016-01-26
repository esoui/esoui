--------------------------------------------
-- VoiceChat Gamepad
--------------------------------------------

ZO_VoiceChat_Gamepad = ZO_SocialOptionsDialogGamepad:Subclass()

function ZO_VoiceChat_Gamepad:New(...)
	local voiceChatGamepad = ZO_Object.New(self)
	voiceChatGamepad:Initialize(...)
	return voiceChatGamepad
end

function ZO_VoiceChat_Gamepad:Initialize(control)
    self.control = control
    ZO_SocialOptionsDialogGamepad.Initialize(self)

    GAMEPAD_VOICECHAT_SCENE = ZO_Scene:New("gamepad_voice_chat", SCENE_MANAGER)
    GAMEPAD_VOICECHAT_PARTICIPANT_OPTIONS_SCENE = ZO_Scene:New("gamepad_voice_chat_participant_options", SCENE_MANAGER)

    VOICE_CHAT_CHANNELS_GAMEPAD = ZO_VoiceChatChannelsGamepad:New(self.control:GetNamedChild("Channels"))
    self:AddSocialOptionsKeybind(VOICE_CHAT_CHANNELS_GAMEPAD.historyKeybinds)
    VOICE_CHAT_PARTICIPANT_OPTIONS_GAMEPAD = ZO_VoiceChatParticipantOptionsGamepad:New(self.control:GetNamedChild("ParticipantOptions"))
    self:AddSocialOptionsKeybind(VOICE_CHAT_PARTICIPANT_OPTIONS_GAMEPAD.keybindStripDescriptor)

    self:InitializeEvents()
end

function ZO_VoiceChat_Gamepad:InitializeEvents()
    local function OnVoiceTransmitChannelChanged(channelName)
        --Special case: Area is rejoined when zoning, and we don't want to play the alert for this situation
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)

        if not VOICE_CHAT_MANAGER:DoesChannelExist(channelData) then
            return
        end

        local channelType = channelData.channelType
        if channelType == VOICE_CHANNEL_AREA and self.desiredAreaBecameUnavailable then
            self.desiredAreaBecameUnavailable = nil
            return
        end

        --Display an alert if not on a Voice Chat menu
        if VOICE_CHAT_CHANNELS_GAMEPAD:IsHidden() and VOICE_CHAT_PARTICIPANT_OPTIONS_GAMEPAD:IsHidden() then
            local channel = VOICE_CHAT_MANAGER:GetChannel(channelData)

            local soundId = SOUNDS.VOICE_CHAT_ALERT_CHANNEL_MADE_ACTIVE
            local text = zo_strformat(SI_GAMEPAD_VOICECHAT_ALERT_CHANNEL_ACTIVE, channel.name)
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, soundId, text)
        end

        self.desiredAreaBecameUnavailable = nil
    end
    local function OnVoiceChannelUnavailable(channelName)
        local channelData = ZO_VoiceChat_GetChannelDataFromName(channelName)

        --Special case: Area is rejoined when zoning, and we don't want to play the alert for this situation
        if channelData.channelType == VOICE_CHANNEL_AREA and VOICE_CHAT_MANAGER:GetDesiredActiveChannelType() == VOICE_CHANNEL_AREA then
            self.desiredAreaBecameUnavailable = true
        end
    end
    self.control:RegisterForEvent(EVENT_VOICE_TRANSMIT_CHANNEL_CHANGED, function(eventCode, ...) OnVoiceTransmitChannelChanged(...) end)
    self.control:RegisterForEvent(EVENT_VOICE_CHANNEL_UNAVAILABLE, function(eventCode, ...) OnVoiceChannelUnavailable(...) end)
end

function ZO_VoiceChat_Gamepad:BuildInviteToGuildOption(guildIndex)
    local guildId = GetGuildId(guildIndex)
    if guildId == 0 or not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_INVITE) then
        return
    end

    local callback = function()
        ZO_TryGuildInvite(guildId, self.socialData.displayName)
    end

    local guildName = GetGuildName(guildId)
    local entry = self:BuildOptionEntry(nil, nil, callback)
    entry.templateData.text = zo_strformat(SI_SOCIAL_MENU_GUILD_INVITE, guildName)
    return entry
end


-- ZO_SocialOptionsDialogGamepad Overrides
function ZO_VoiceChat_Gamepad:SetupOptions(data)
    local channelType = data.channel.channelType

    self.playerAlliance = GetUnitAlliance("player")
    
    local displayName = data.speakerData.displayName

    local alliance = nil
    if channelType == VOICE_CHANNEL_GUILD then
        local guildId = data.channel.guildId
        local memberIndex = GetGuildMemberIndexFromDisplayName(guildId, displayName)
        if memberIndex then
            alliance = select(5, GetGuildMemberCharacterInfo(guildId, memberIndex))
        end
    else
        --Channel is Area or Group, so the alliance for this character must be the same
        alliance = self.playerAlliance
    end

    local socialData = {
        displayName = displayName,
        alliance = alliance,
        voiceChannelType = channelType,
    }
    ZO_SocialOptionsDialogGamepad.SetupOptions(self, socialData)
end

function ZO_VoiceChat_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup()
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToGroupOption, function() return self.socialData.voiceChannelType ~= VOICE_CHANNEL_GROUP end)

    local function BuildTravelToGuildPlayerOption()
        return self:BuildTravelToPlayerOption(JumpToGuildMember)
    end

    local function BuildTravelToGroupPlayerOption()
        return self:BuildTravelToPlayerOption(JumpToGroupMember)
    end
    self:AddOptionTemplate(groupId, BuildTravelToGuildPlayerOption, function() return self.socialData.voiceChannelType == VOICE_CHANNEL_GUILD end)
    self:AddOptionTemplate(groupId, BuildTravelToGroupPlayerOption, function() return self.socialData.voiceChannelType == VOICE_CHANNEL_GROUP end)

    local function ShouldAddInviteToGuildOption(guildIndex)
        local guildId = GetGuildId(guildIndex)
        return guildId ~= 0
    end

    for i = 1, MAX_GUILDS do
        self:AddOptionTemplate(groupId, function() return self:BuildInviteToGuildOption(i) end, function() return ShouldAddInviteToGuildOption(i) end)
    end

    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption)
end

-- XML Calls
function ZO_VoiceChatGamepad_OnInitialize(control)
	VOICE_CHAT_GAMEPAD = ZO_VoiceChat_Gamepad:New(control)
end
