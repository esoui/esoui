--------------------------------------------------------------------------------
-- Voice Chat Participants
--  Participants list for a selected voice chat channel. Displays
--  information about the speakers, and allows performing social actions
--  on them.
--------------------------------------------------------------------------------


ZO_VoiceChatParticipantsGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_VoiceChatParticipantsGamepad:Initialize(control)
    GAMEPAD_VOICECHAT_PARTICIPANTS_SCENE = ZO_Scene:New("gamepad_voice_chat_participants", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, GAMEPAD_VOICECHAT_PARTICIPANTS_SCENE)
    self:SetListsUseTriggerKeybinds(true)

    GAMEPAD_VOICECHAT_PARTICIPANTS_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self:InitializeHeader()

    self.channel = nil --the channel set externally that we'll update for

    self:InitializeEvents()
end

function ZO_VoiceChatParticipantsGamepad:InitializeHeader()
    local headerData =
    {
        titleText = GetString(SI_GAMEPAD_VOICECHAT_PARTICIPANT_OPTIONS_TITLE)
    }
    ZO_GamepadGenericHeader_Refresh(self.header, headerData)
end

function ZO_VoiceChatParticipantsGamepad:InitializeEvents()
    VOICE_CHAT_MANAGER:RegisterCallback("MuteUpdate", function() self:Update() end)
end

function ZO_VoiceChatParticipantsGamepad:SetChannel(channel)
    self.channel = channel
end

function ZO_VoiceChatParticipantsGamepad:IsHidden()
    return self.control:IsControlHidden()
end


--ZO_Gamepad_ParametricList_Screen overrides
function ZO_VoiceChatParticipantsGamepad:SetupList(list)
    self.list = list
    list:AddDataTemplate("ZO_VoiceChatParticipantsEntryGamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_VoiceChatParticipantsGamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if selectedData then
        local speakerData = selectedData.speakerData

        local displayName = speakerData.displayName
        local channelName = selectedData.channelName
        local lastTimeSpoken = speakerData.lastTimeSpoken
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_TOOLTIPS:LayoutVoiceChatParticipantHistory(GAMEPAD_LEFT_TOOLTIP, displayName, channelName, lastTimeSpoken)
        VOICE_CHAT_SOCIAL_OPTIONS:SetupOptions({speakerData = speakerData, channel = selectedData.channel})
    end
end

function ZO_VoiceChatParticipantsGamepad:OnShowing()
    self:PerformUpdate()
end

function ZO_VoiceChatParticipantsGamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {} --ZO_VoiceChatSocialOptions_Gamepad will add the social keybinds
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_VoiceChatParticipantsGamepad:PerformUpdate()
    self.dirty = false
    self.list:Clear()

    local channel = self.channel
    if not channel then
        self.list:Commit()
        return
    end

    local participantDataList = VOICE_CHAT_MANAGER:GetParticipantDataList(channel)

    --Populate list
    for i, speakerData in ipairs(participantDataList) do
        local displayName = speakerData.displayName
        if not ZO_VoiceChat_IsNameLocalPlayers(displayName) then
            local newEntry = ZO_GamepadEntryData:New(ZO_FormatUserFacingDisplayName(displayName), speakerData.isMuted and VOICE_CHAT_ICON_MUTED_PLAYER)
            newEntry.speakerData = speakerData
            newEntry.channelName = channel.fullName or channel.name
            newEntry.channel = channel
            self.list:AddEntry("ZO_VoiceChatParticipantsEntryGamepad", newEntry)
        end
    end

    self.list:Commit()
end
