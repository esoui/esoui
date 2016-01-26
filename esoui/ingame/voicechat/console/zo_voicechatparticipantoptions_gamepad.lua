--------------------------------------------
-- VoiceChat Participant Options
--------------------------------------------

local ICON_MUTED_PLAYER = "EsoUI/Art/VOIP/Gamepad/gp_VOIP_muted.dds"


local function IsNameLocalPlayer(displayName)
    return displayName == GetDisplayName()
end


ZO_VoiceChatParticipantOptionsGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_VoiceChatParticipantOptionsGamepad:New(...)
	local object = ZO_Object.New(self)
	object:Initialize(...)
	return object
end

function ZO_VoiceChatParticipantOptionsGamepad:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control)
    self:SetListsUseTriggerKeybinds(true)

    self:InitializeHeader()

    self.control = control
    self:InitializeFragment(control)

    self.channel = nil

    self:InitializeEvents()
end

function ZO_VoiceChatParticipantOptionsGamepad:InitializeHeader()
    local headerData = {titleText = GetString(SI_GAMEPAD_VOICECHAT_PARTICIPANT_OPTIONS_TITLE)}
    ZO_GamepadGenericHeader_Refresh(self.header, headerData)
end

function ZO_VoiceChatParticipantOptionsGamepad:InitializeFragment(control)
    GAMEPAD_VOICECHAT_PARTICIPANT_OPTIONS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    self.fragment = GAMEPAD_VOICECHAT_PARTICIPANT_OPTIONS_FRAGMENT
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    end)
end

function ZO_VoiceChatParticipantOptionsGamepad:InitializeEvents()
    VOICE_CHAT_MANAGER:RegisterCallback("MuteUpdate", function() self:Update() end)
end

function ZO_VoiceChatParticipantOptionsGamepad:SetChannel(channel)
    self.channel = channel
end

function ZO_VoiceChatParticipantOptionsGamepad:IsHidden()
    return self.control:IsControlHidden()
end


--ZO_Gamepad_ParametricList_Screen overrides
function ZO_VoiceChatParticipantOptionsGamepad:SetupList(list)
    self.list = list
    list:AddDataTemplate("ZO_VoiceChatParticipantOptionsEntryGamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_VoiceChatParticipantOptionsGamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if selectedData then
        local speakerData = selectedData.speakerData

        local displayName = speakerData.displayName
        local channelName = selectedData.channelName
        local lastTimeSpoken = speakerData.lastTimeSpoken
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_TOOLTIPS:LayoutVoiceChatParticipantHistory(GAMEPAD_LEFT_TOOLTIP, displayName, channelName, lastTimeSpoken)
        VOICE_CHAT_GAMEPAD:SetupOptions({speakerData = speakerData, channel = selectedData.channel})
    end
end

function ZO_VoiceChatParticipantOptionsGamepad:OnShowing()
    self:PerformUpdate()
end

do
    local function RequestDelayEnabled()
        return VOICE_CHAT_MANAGER:AreRequestsAllowed()
    end
    function ZO_VoiceChatParticipantOptionsGamepad:InitializeKeybindStripDescriptors()
        self.keybindStripDescriptor = {}
        ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    end
end

function ZO_VoiceChatParticipantOptionsGamepad:PerformUpdate()
    self.dirty = false
    self.list:Clear()

    local channel = self.channel
    if not channel then
        return
    end

    local participantDataList = VOICE_CHAT_MANAGER:GetParticipantDataList(channel)

    --Populate list
    for i = 1, #participantDataList do
        local speakerData = participantDataList[i]
        local displayName = speakerData.displayName
        if not IsNameLocalPlayer(displayName) then
            local newEntry = ZO_GamepadEntryData:New(ZO_FormatUserFacingDisplayName(displayName), speakerData.isMuted and ICON_MUTED_PLAYER)
            newEntry.speakerData = speakerData
            newEntry.channelName = channel.fullName or channel.name
            newEntry.channel = channel
            self.list:AddEntry("ZO_VoiceChatParticipantOptionsEntryGamepad", newEntry)
        end
    end
    

    self.list:Commit()
end
