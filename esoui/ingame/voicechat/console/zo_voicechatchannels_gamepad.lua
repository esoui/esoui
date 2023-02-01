--------------------------------------------------------------------------------
-- Voice Chat Channels
--  Consists of a list of channels the user can join, and a history
--  list of previous users heard for each channel.
--------------------------------------------------------------------------------

local LIST_CHANNELS = 1
local LIST_HISTORY = 2

local function GuildRoomEntriesComparator(entry1, entry2)
    if entry1.guildId ~= entry2.guildId then
        return entry1.guildId < entry2.guildId
    end

    --We want the officer's room to always be placed at the bottom.
    if entry1.guildRoomNumber == VOICE_CHAT_OFFICERS_ROOM_NUMBER then
        return false
    elseif entry2.guildRoomNumber == VOICE_CHAT_OFFICERS_ROOM_NUMBER then
        return true
    end

    return entry1.guildRoomNumber < entry2.guildRoomNumber
end


ZO_VoiceChatChannelsGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_VoiceChatChannelsGamepad:Initialize(control)
    GAMEPAD_VOICECHAT_CHANNELS_SCENE = ZO_Scene:New("gamepad_voice_chat", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_VOICECHAT_CHANNELS_SCENE)
    self:SetListsUseTriggerKeybinds(true)

    GAMEPAD_VOICECHAT_CHANNELS_FRAGMENT = ZO_FadeSceneFragment:New(control)

    self:InitializeHeaders()
    self:InitializeEvents()
end

function ZO_VoiceChatChannelsGamepad:InitializeHeaders()
    local function OnTabChangedToChannels()
        if self:IsHidden() then
            return
        end

        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.historyKeybinds)
        self.currentList = LIST_CHANNELS
        self:Update()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.channelKeybinds)

        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list, NARRATE_HEADER)
    end
    local function OnTabChangedToHistory()
        if self:IsHidden() then
            return
        end

        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.channelKeybinds)
        self.currentList = LIST_HISTORY
        self:Update()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.historyKeybinds)

        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list, NARRATE_HEADER)
    end

    local channelsHeader =
    {
        text = GetString(SI_GAMEPAD_VOICECHAT_CHANNELS_TITLE),
        callback = OnTabChangedToChannels,
    }
    local historyHeader =
    {
        text = GetString(SI_GAMEPAD_VOICECHAT_HISTORY_TITLE),
        callback = OnTabChangedToHistory,
    }
    self.headerData =
    {
        tabBarEntries =
        {
            channelsHeader,
            historyHeader,
        },
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_VoiceChatChannelsGamepad:InitializeEvents()
    --Manager callbacks
    VOICE_CHAT_MANAGER:RegisterCallback("ChannelsUpdate", function() self:Update() end)
    VOICE_CHAT_MANAGER:RegisterCallback("ParticipantsUpdate", function()
        self:UpdateParticipantsPanel()
        self:UpdateKeybinds()
    end)
    VOICE_CHAT_MANAGER:RegisterCallback("MuteUpdate", function() self:Update() end)

    --Event callbacks for playing sounds specifically while on this scene
    local function OnVoiceChannelJoined()
        if not self:IsHidden() then
            PlaySound(SOUNDS.VOICE_CHAT_MENU_CHANNEL_JOINED)
        end
    end
    local function OnVoiceChannelLeft()
        if not self:IsHidden() then
            PlaySound(SOUNDS.VOICE_CHAT_MENU_CHANNEL_LEFT)
        end
    end
    local function OnVoiceTransmitChannelChanged()
        if not self:IsHidden() then
            PlaySound(SOUNDS.VOICE_CHAT_MENU_CHANNEL_MADE_ACTIVE)
        end
    end

    self.control:RegisterForEvent(EVENT_VOICE_CHANNEL_JOINED, function(eventCode, ...) OnVoiceChannelJoined(...) end)
    self.control:RegisterForEvent(EVENT_VOICE_CHANNEL_LEFT, function(eventCode, ...) OnVoiceChannelLeft(...) end)
    self.control:RegisterForEvent(EVENT_VOICE_TRANSMIT_CHANNEL_CHANGED, function(eventCode, ...) OnVoiceTransmitChannelChanged(...) end)
end

do
    local function AddChannelToList(list, channel, headerText)
        local icon = channel.isJoined and VOICE_CHAT_ICON_LISTENING_CHANNEL or nil
        local newEntry = ZO_GamepadEntryData:New(channel.name, icon)
        newEntry.channel = channel
        newEntry:SetChannelActive(channel.isTransmitting)

        newEntry.narrationText = function(entryData, entryControl)
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.text))
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl))
            if channel.isJoined then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_NARRATION_JOINED_CHANNEL_ICON_NARRATION)))
            end
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryStatusIndicatorNarrationText(entryData, entryControl))
            return narrations
        end

        if headerText then
            newEntry:SetHeader(headerText)
            list:AddEntryWithHeader("ZO_VoiceChatChannelsEntryGamepad", newEntry)
        else
            list:AddEntry("ZO_VoiceChatChannelsEntryGamepad", newEntry)
        end
    end

    function ZO_VoiceChatChannelsGamepad:PopulateChannels()
        local areaData, groupData, guildData = VOICE_CHAT_MANAGER:GetChannelData()
        local mainHeaderAdded = false

        --Area
        if areaData then
            AddChannelToList(self.list, areaData, GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_MAIN_HEADER))
            mainHeaderAdded = true
        end

        --Group
        if groupData then
            local header = not mainHeaderAdded and GetString(SI_GAMEPAD_VOICECHAT_CHANNEL_MAIN_HEADER)
            AddChannelToList(self.list, groupData, header)
        end

        --Guild Channels
        local guildRooms = {}
        for guildId, guildChannelData in pairs(guildData) do
            for guildRoomNumber, roomData in pairs(guildChannelData.rooms) do
                table.insert(guildRooms, roomData)
            end
        end

        table.sort(guildRooms, GuildRoomEntriesComparator)

        local lastGuildHeader = nil
        for i, roomData in ipairs(guildRooms) do
            local header = guildData[roomData.guildId].header
            if header ~= lastGuildHeader then
                lastGuildHeader = header
            else
                header = nil
            end
            AddChannelToList(self.list, roomData, header)
        end
    end
end

do
    local function AddHistoryDataToList(list, historyData, channelName, channel)
        local dataList = historyData.list
        local shouldAddHeader = true -- only add the header to the first entry
        for i, userData in ZO_NumericallyIndexedTableReverseIterator(dataList) do --we want newer entries added first, and the list is in order from old to new
            local newEntry = ZO_GamepadEntryData:New(ZO_FormatUserFacingDisplayName(userData.displayName), userData.isMuted and VOICE_CHAT_ICON_MUTED_PLAYER)
            newEntry.historyData = userData
            newEntry.channelName = channelName
            newEntry.channel = channel
            if shouldAddHeader then
                newEntry:SetHeader(channelName)
                list:AddEntryWithHeader("ZO_VoiceChatHistoryEntryGamepad", newEntry)
                shouldAddHeader = false
            else
                list:AddEntry("ZO_VoiceChatHistoryEntryGamepad", newEntry)
            end
        end
    end

    function ZO_VoiceChatChannelsGamepad:PopulateHistory()
        local areaData, groupData, guildData = VOICE_CHAT_MANAGER:GetChannelData()

        if areaData then
            AddHistoryDataToList(self.list, areaData.historyData, areaData.name, areaData)
        end

        if groupData then
            AddHistoryDataToList(self.list, groupData.historyData, groupData.name, groupData)
        end

        -- Guild Channels
        local guildRooms = {}
        for guildId, guildChannelData in pairs(guildData) do
            for guildRoomNumber, roomData in pairs(guildChannelData.rooms) do
                table.insert(guildRooms, roomData)
            end
        end

        table.sort(guildRooms, GuildRoomEntriesComparator)

        for i, roomData in ipairs(guildRooms) do
            AddHistoryDataToList(self.list, roomData.historyData, roomData.fullName, roomData)
        end
    end
end

function ZO_VoiceChatChannelsGamepad:RefreshHeaderData()
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_VoiceChatChannelsGamepad:UpdateKeybinds()
    if not GAMEPAD_VOICECHAT_CHANNELS_SCENE:IsShowing() then
        return
    end

    if self.currentList == LIST_CHANNELS then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.channelKeybinds)
    elseif self.currentList == LIST_HISTORY then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.historyKeybinds)
    end
end

function ZO_VoiceChatChannelsGamepad:UpdateParticipantsPanel()
    if self:IsHidden() then
        return
    end

    if self.currentList ~= LIST_CHANNELS then
        return
    end

    local selectedData = self.list:GetTargetData()
    if selectedData then
        local channel = selectedData.channel
        if channel.isJoined then
            local participantDataList = VOICE_CHAT_MANAGER:GetParticipantDataList(channel)        
            GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_TOOLTIPS:SetTooltipResetScrollOnClear(GAMEPAD_LEFT_TOOLTIP, false)
            GAMEPAD_TOOLTIPS:LayoutVoiceChatParticipants(GAMEPAD_LEFT_TOOLTIP, channel, participantDataList)
        end
    end
end

function ZO_VoiceChatChannelsGamepad:IsHidden()
    return self.control:IsControlHidden()
end

--ZO_Gamepad_ParametricList_Screen overrides
function ZO_VoiceChatChannelsGamepad:SetupList(list)
    self.list = list
    list:AddDataTemplate("ZO_VoiceChatChannelsEntryGamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_VoiceChatChannelsEntryGamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    list:AddDataTemplate("ZO_VoiceChatHistoryEntryGamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_VoiceChatHistoryEntryGamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    self.currentList = LIST_CHANNELS
end

function ZO_VoiceChatChannelsGamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if selectedData then
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)

        if self.currentList == LIST_CHANNELS then
            local channel = selectedData.channel

            if channel.isJoined then
                local participantDataList = VOICE_CHAT_MANAGER:GetParticipantDataList(channel)
                GAMEPAD_TOOLTIPS:LayoutVoiceChatParticipants(GAMEPAD_LEFT_TOOLTIP, channel, participantDataList)
            else
                GAMEPAD_TOOLTIPS:LayoutVoiceChatChannel(GAMEPAD_LEFT_TOOLTIP, channel)
            end

        elseif self.currentList == LIST_HISTORY then
            local historyData = selectedData.historyData

            local displayName = historyData.displayName
            local channelName = selectedData.channelName
            local lastTimeSpoken = historyData.lastTimeSpoken
            GAMEPAD_TOOLTIPS:LayoutVoiceChatParticipantHistory(GAMEPAD_LEFT_TOOLTIP, displayName, channelName, lastTimeSpoken)
            VOICE_CHAT_SOCIAL_OPTIONS:SetupOptions({speakerData = historyData, channel = selectedData.channel})
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end

        self:UpdateKeybinds()
    end
end

function ZO_VoiceChatChannelsGamepad:InitializeKeybindStripDescriptors()
    local joinOrActivateChannelKeybind =
    {
        name = function()
            local channel = self.list:GetTargetData().channel
            if not channel.isJoined then
                return GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_JOIN_CHANNEL)
            elseif not channel.isTransmitting then
                return GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_ENABLE_MIC)
            else
                return GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_DISABLE_MIC)
            end
        end,
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function()
            local channel = self.list:GetTargetData().channel
            if not channel.isJoined then
                VOICE_CHAT_MANAGER:JoinChannel(channel)
            elseif not channel.isTransmitting then
                VOICE_CHAT_MANAGER:TransmitChannel(channel)
            else
                VOICE_CHAT_MANAGER:StopTransmitting()
            end
        end,
        visible = function()
            if self.currentList ~= LIST_CHANNELS then
                return false
            end
    
            local entry = self.list:GetTargetData()
            if not entry then
                return false
            end
    
            return true
        end,
    }

    local leaveChannelKeybind =
    {
        name = GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_LEAVE_CHANNEL),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            local channel = self.list:GetTargetData().channel
            VOICE_CHAT_MANAGER:LeaveChannel(channel)
        end,
        visible = function()
            if self.currentList ~= LIST_CHANNELS then
                return false
            end
    
            local entry = self.list:GetTargetData()
            if not entry then
                return false
            end
    
            local channel = entry.channel
            return channel.isJoined
        end,
    }

    local showParticipantsKeybind =
    {
        name = GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_PARTICIPANT_OPTIONS),
        keybind = "UI_SHORTCUT_TERTIARY",
        callback = function()
            local channel = self.list:GetTargetData().channel
            VOICE_CHAT_PARTICIPANTS_GAMEPAD:SetChannel(channel)
            SCENE_MANAGER:Push("gamepad_voice_chat_participants")
        end,
        visible = function()
            if self.currentList ~= LIST_CHANNELS then
                return false
            end
    
            local entry = self.list:GetTargetData()
            if not entry then
                return false
            end

            local channel = entry.channel
            if not channel.isJoined then
                return false
            end
    
            local participantDataList = VOICE_CHAT_MANAGER:GetParticipantDataList(channel)
            return #participantDataList > 1 --we don't show the local player, so we need at least 1 other player
        end,
    }

    local viewTranscriptKeybind =
    {
        name = GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_VIEW_TRANSCRIPT),
        keybind = "UI_SHORTCUT_RIGHT_STICK",
        callback = function()
            SCENE_MANAGER:Push("gamepadVoiceChatTranscript")
        end,
        visible = function()
            return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_VOICE_CHAT_ACCESSIBILITY)
        end,
    }

    self.channelKeybinds =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        --These are inserted as numerically indiced entries
        joinOrActivateChannelKeybind,
        leaveChannelKeybind,
        showParticipantsKeybind,
        viewTranscriptKeybind,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.channelKeybinds, GAME_NAVIGATION_TYPE_BUTTON)

    self.historyKeybinds = {} --ZO_VoiceChatSocialOptions_Gamepad will add the social keybinds
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.historyKeybinds, GAME_NAVIGATION_TYPE_BUTTON)

    --Save these off so we can register cooldown delays on them later
    self.joinOrActivateChannelKeybind = joinOrActivateChannelKeybind
    self.leaveChannelKeybind = leaveChannelKeybind
end

function ZO_VoiceChatChannelsGamepad:OnShowing()
    ZO_GamepadGenericHeader_Activate(self.header)

    self:PerformUpdate()

    if self.currentList == LIST_CHANNELS then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.channelKeybinds)
    elseif self.currentList == LIST_HISTORY then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.historyKeybinds)
    end
end

function ZO_VoiceChatChannelsGamepad:OnHiding()
    ZO_GamepadGenericHeader_Deactivate(self.header)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.historyKeybinds)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.channelKeybinds)

    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)

    ZO_Gamepad_ParametricList_Screen.OnHiding(self)
end

do
    local function ShowUnavailableMessage(self)
        self.headerData.messageText = zo_strformat(GetString(SI_GAMEPAD_VOICECHAT_UNAVAILABLE), GetString(SI_GAMEPAD_HELP_WEBSITE))
    end
    local function HideUnavailableMessage(self)
        self.headerData.messageText = nil
    end
    
    function ZO_VoiceChatChannelsGamepad:PerformUpdate()
        self.dirty = false
        self.list:Clear()
    
        if VOICE_CHAT_MANAGER:HasChannelData() then
            HideUnavailableMessage(self)
            
            if self.currentList == LIST_CHANNELS then
                self:PopulateChannels()
                TriggerTutorial(TUTORIAL_TRIGGER_VOICE_CHAT_OPEN_CHANNELS)
            elseif self.currentList == LIST_HISTORY then
                self:PopulateHistory()
                TriggerTutorial(TUTORIAL_TRIGGER_VOICE_CHAT_OPEN_HISTORY)
            end
        else
            ShowUnavailableMessage(self)
        end
        self:RefreshHeaderData()
    
        self.list:Commit()
    end
end