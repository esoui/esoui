ZO_VOICE_CHAT_TRANSCRIPT_GAMEPAD_LOG_MAX_SIZE = 200

------------------
--Initialization--
------------------

ZO_VoiceChatTranscript_Gamepad = ZO_InteractiveChatLog_Gamepad:Subclass()

function ZO_VoiceChatTranscript_Gamepad:Initialize(control)
    VOICE_CHAT_TRANSCRIPT_GAMEPAD_SCENE = ZO_Scene:New("gamepadVoiceChatTranscript", SCENE_MANAGER)

    ZO_InteractiveChatLog_Gamepad.Initialize(self, control, VOICE_CHAT_TRANSCRIPT_GAMEPAD_SCENE)
    
    self.textInputLabel = control:GetNamedChild("MaskTextInputChannel")
    self.textInputField = control:GetNamedChild("MaskTextInputText")
    self.inputChannelName = nil
    self.isTextFieldVisible = true

    self:SetTextFieldVisibility(VOICE_CHAT_MANAGER:HasActiveTransmitChannel())

    self:InitializeNarrationInfo()
end

-- ZO_InteractiveChatLog_Gamepad Overrides

function ZO_VoiceChatTranscript_Gamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_GAMEPAD_VOICECHAT_TRANSCRIPT_HEADER),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_VoiceChatTranscript_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return VOICE_CHAT_TRANSCRIPT_GAMEPAD_SCENE:IsShowing() and self.textInputAreaFocalArea:IsFocused()
        end,
        selectedNarrationFunction = function()
            -- the text field can be focused, but not visible
            -- we don't want to narrat eth field, but still want to narrate the keybinds
            if self.isTextFieldVisible then
                return ZO_FormatEditBoxNarrationText(self.textEdit, self.inputChannelName)
            end
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("voiceChatTranscriptTextEdit", narrationInfo)
end

function ZO_VoiceChatTranscript_Gamepad:RegisterForEvents()
    ZO_InteractiveChatLog_Gamepad.RegisterForEvents(self)

    local function AddMessage(...)
        self:AddMessage(...)
    end

    VOICE_CHAT_MANAGER:RegisterCallback("VoiceChatTranscript", AddMessage)

    local function OnVoiceTransmitChannelUpdate()
        local hasActiveTransmitChannel = VOICE_CHAT_MANAGER:HasActiveTransmitChannel()
        self:SetTextFieldVisibility(hasActiveTransmitChannel)
        if hasActiveTransmitChannel then
            local channel = VOICE_CHAT_MANAGER:GetActiveChannel()
            self.inputChannelName = zo_strformat(SI_GAMEPAD_VOICECHAT_FORMAT_CHANNEL, channel.name)
            self.textInputLabel:SetText(self.inputChannelName)
        end
    end

    VOICE_CHAT_MANAGER:RegisterCallback("ChannelsUpdate", OnVoiceTransmitChannelUpdate)
    EVENT_MANAGER:RegisterForEvent("ZO_VoiceChatTranscript_Gamepad", EVENT_FORWARD_TRANSCRIPT_TO_TEXT_CHAT_ACCESSIBILITY_SETTING_CHANGED, function() self:UpdateKeybinds() end)
end

function ZO_VoiceChatTranscript_Gamepad:InitializeFocusKeybinds()
    self.chatEntryListKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back to text input
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                self:FocusTextInput()
            end,

            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },

    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.chatEntryListKeybindDescriptor, self.list)

    local function AreOptionsAvailable()
        local targetData = self.list:GetTargetData()
        if targetData then
            local data = targetData.data
            if data then
                if data.fromDisplayName and data.fromDisplayName ~= "" and self:HasAnyShownOptions() then
                    return true
                end
            end
        end
        return false
    end

    local DEFAULT_CALLBACK = nil
    local DEFAULT_KEYBIND = nil
    local DEFAULT_NAME = nil
    local DEFAULT_SOUND = nil
    self:AddSocialOptionsKeybind(self.chatEntryListKeybindDescriptor, DEFAULT_CALLBACK, DEFAULT_KEYBIND, DEFAULT_NAME, DEFAULT_SOUND, AreOptionsAvailable)
    self.chatEntryPanelFocalArea:SetKeybindDescriptor(self.chatEntryListKeybindDescriptor)

    self.textInputAreaKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self.textEdit:TakeFocus()
            end,

            visible = function()
                return VOICE_CHAT_MANAGER:HasActiveTransmitChannel()
            end,
        },

        {
            name = GetString(SI_GAMEPAD_CHAT_MENU_SEND_KEYBIND),

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                RequestReadTextOverVoiceChat(self.textEdit:GetText())
                self.textEdit:Clear()
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("voiceChatTranscriptTextEdit")
            end,

            enabled = function()
                local text = self.textEdit:GetText()
                return text and text ~= "" 
            end,

            visible = function()
                return VOICE_CHAT_MANAGER:HasActiveTransmitChannel()
            end,
        },

        {
            name = function()
                if GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SEND_TRANSCRIPT_TO_TEXT_CHAT) then
                    return GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_HIDE_FROM_HUD_CHAT)
                else
                    return GetString(SI_GAMEPAD_VOICECHAT_KEYBIND_SEND_TO_HUD_CHAT)
                end
            end,

            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                local isSendingTranscriptToTextChat = GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SEND_TRANSCRIPT_TO_TEXT_CHAT)
                SetSetting(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_SEND_TRANSCRIPT_TO_TEXT_CHAT, tostring(not isSendingTranscriptToTextChat))
            end,
        }
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.textInputAreaKeybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    self.textInputAreaFocalArea:SetKeybindDescriptor(self.textInputAreaKeybindDescriptor)
end

function ZO_VoiceChatTranscript_Gamepad:UpdateKeybinds()
    if not VOICE_CHAT_TRANSCRIPT_GAMEPAD_SCENE:IsShowing() then
        return
    end

    if self.textInputAreaFocalArea:IsFocused() then
        self.textInputAreaFocalArea:UpdateKeybinds()
    end
end

function ZO_VoiceChatTranscript_Gamepad:SetupLogMessage(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    local entryData = data.data
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_VOICE_CHAT_COLORS, ZO_VOICE_CHAT_CHANNEL_TO_COLOR[entryData.channelType])
    local useSelectedColor = selected and self.chatEntryPanelFocalArea:IsFocused()
    local colorSelectedModifier = useSelectedColor and 1 or 0.7
    control.label:SetColor(r * colorSelectedModifier, g * colorSelectedModifier, b * colorSelectedModifier, 1)
    control.label:SetDesaturation(useSelectedColor and 0 or 0.1)
end

function ZO_VoiceChatTranscript_Gamepad:AddMessage(message, fromDisplayName, rawMessageText, channelType)
    if message ~= nil then
        local targetIndex = self.list:GetTargetIndex()
        local selectingMostRecent = targetIndex == #self.messageEntries

        local messageEntry = ZO_GamepadEntryData:New(message)
        messageEntry:SetFontScaleOnSelection(false)
        messageEntry.data =
        {
            id = self.nextMessageId,
            fromDisplayName = fromDisplayName,
            rawMessageText = rawMessageText,
            channelType = channelType,
        }

        self.nextMessageId = self.nextMessageId + 1
        table.insert(self.messageEntries, messageEntry)

        if #self.messageEntries > ZO_VOICE_CHAT_TRANSCRIPT_GAMEPAD_LOG_MAX_SIZE then
            table.remove(self.messageEntries, 1)
            self:BuildChatList()
        else
            self.list:AddEntry("ZO_InteractiveChatLog_Gamepad_LogLine", messageEntry)
            self.list:Commit()
        end

        if selectingMostRecent then
            self.list:SetSelectedIndex(#self.messageEntries)
        end
    end
end

function ZO_VoiceChatTranscript_Gamepad:SetupOptions(entryData)
    local data = entryData.data

    local socialData =
    {
        displayName = data.fromDisplayName,
        category = data.category,
        targetChannel = data.targetChannel,
    }

    ZO_InteractiveChatLog_Gamepad.SetupOptions(self, socialData)
end

function ZO_VoiceChatTranscript_Gamepad:SetTextFieldVisibility(visible)
    self.isTextFieldVisible = visible
    self.textInputField:SetHidden(not visible)
    self.textInputLabel:SetHidden(not visible)
end

function ZO_VoiceChatTranscript_Gamepad:BuildOptionsList()
    -- TODO XAR which options do we want?
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)

    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildInviteToGroupOption, ZO_SocialOptionsDialogGamepad.ShouldAddInviteToGroupOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption, ZO_SocialOptionsDialogGamepad.ShouldAddSendMailOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsNotPlayer)
end

function ZO_VoiceChatTranscript_Gamepad:OnTextInputAreaActivated()
    ZO_InteractiveChatLog_Gamepad.OnTextInputAreaActivated(self)

    self.textControlHighlight:SetHidden(false)

    SCREEN_NARRATION_MANAGER:QueueCustomEntry("voiceChatTranscriptTextEdit")
end

function ZO_VoiceChatTranscript_Gamepad:OnTextInputAreaDeactivated()
    ZO_InteractiveChatLog_Gamepad.OnTextInputAreaDeactivated(self)

    self.textControlHighlight:SetHidden(true)
end

-- End ZO_InteractiveChatLog_Gamepad Overrides

-------------
-- Global XML
-------------

function ZO_VoiceChatTranscript_Gamepad_OnInitialized(control)
    VOICE_CHAT_TRANSCRIPT_GAMEPAD = ZO_VoiceChatTranscript_Gamepad:New(control)
end
