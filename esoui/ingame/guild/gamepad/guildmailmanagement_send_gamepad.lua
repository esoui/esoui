ZO_GuildMailManagement_Send_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GuildMailManagement_Send_Gamepad:Initialize(control)
    GAMEPAD_GUILD_MAIL_MANAGEMENT_SEND_SCENE = ZO_Scene:New("gamepad_guild_mail_send", SCENE_MANAGER)
    local NO_TAB_BAR = false
    local DONT_ACTIVATE_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, NO_TAB_BAR, DONT_ACTIVATE_ON_SHOW, GAMEPAD_GUILD_MAIL_MANAGEMENT_SEND_SCENE)

    GAMEPAD_GUILD_MAIL_SEND_FRAGMENT = ZO_FadeSceneFragment:New(control)
    self.sendList = self:AddList("SendOptions", function(list) self:SetupSendList(list) end)
end

--Overridden from base
function ZO_GuildMailManagement_Send_Gamepad:OnDeferredInitialize()
    self.headerData =
    {
        titleText = GetString(SI_GUILD_RECRUITMENT_GUILD_MAIL_SEND),
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_RECRUITMENT_HEADER_GUILD_LABEL),
        data1Text = function() return GetGuildName(self.guildId) end,
        data2HeaderText = GetString(SI_GAMEPAD_GUILD_MAIL_ACTIVE_MAIL_HEADER),
        data2Text = function()
            local numActiveMails = GetNumActiveGuildMailsForGuild(self.guildId)

            local formattedMailCount = zo_strformat(SI_GUILD_MAIL_MANAGEMENT_ACTIVE_MAILS_FORMATTER, numActiveMails, MAX_GUILD_MAIL_PER_GUILD)
            if numActiveMails == MAX_GUILD_MAIL_PER_GUILD then
                formattedMailCount = ZO_ERROR_COLOR:Colorize(formattedMailCount)
            end
            return formattedMailCount
        end,
        data2TextNarration = function()
            local numActiveMails = GetNumActiveGuildMailsForGuild(self.guildId)

            local formattedMailCount = zo_strformat(SI_SCREEN_NARRATION_CURRENT_AND_MAX_VALUES_FORMATTER, numActiveMails, MAX_GUILD_MAIL_PER_GUILD)
            return formattedMailCount
        end,
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    local function OnEditBoxFocusLost(editBox)
        ZO_GamepadEditBox_FocusLost(editBox)
        --Re-narrate the edit box when we are done typing in it
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())
    end

    local mailViewContainer = self.control:GetNamedChild("SendRightPaneContainerMailView")
    self.rankDisplay = mailViewContainer:GetNamedChild("Ranks")
    self.rankDisplayLabel = mailViewContainer:GetNamedChild("RanksLabel")
    self.subjectEdit = mailViewContainer:GetNamedChild("Subject")
    self.subjectEdit.edit:SetMaxInputChars(MAIL_MAX_SUBJECT_CHARACTERS)
    self.subjectEdit.edit:SetDefaultText(GetString(SI_MAIL_SUBJECT_DEFAULT_TEXT))
    self.subjectEdit.edit:SetHandler("OnFocusLost", OnEditBoxFocusLost)
    self.subjectLabel = mailViewContainer:GetNamedChild("SubjectLabel")
    self.bodyEdit = mailViewContainer:GetNamedChild("Body")
    self.bodyEdit.edit:SetMaxInputChars(MAIL_MAX_BODY_CHARACTERS)
    self.bodyEdit.edit:SetHandler("OnFocusLost", OnEditBoxFocusLost)
    self.bodyLabel = mailViewContainer:GetNamedChild("BodyLabel")

    self:RegisterForEvents()
end

function ZO_GuildMailManagement_Send_Gamepad:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_GUILD_MAIL_UPDATE, function()
        self.sendList:RefreshVisible()
        self:RefreshKeybinds()
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end)

    self.control:RegisterForEvent(EVENT_CREATE_GUILD_MAIL_RESULT, function(_, result)
        if result == GUILD_MAIL_RESULT_SUCCESS then
            self:ClearSendFields()
        end
    end)
end

function ZO_GuildMailManagement_Send_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            visible = function()
                local targetData = self.sendList:GetTargetData()
                return targetData ~= nil
            end,
            enabled = function()
                local targetData = self.sendList:GetTargetData()
                return targetData:IsEnabled()
            end,
            callback = function()
                local targetData = self.sendList:GetTargetData()
                if targetData.callback then
                    local targetControl = self.sendList:GetTargetControl()
                    targetData.callback(targetData, targetControl)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Clear
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_GAMEPAD_MAIL_SEND_CLEAR),
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("CONFIRM_CLEAR_MAIL_COMPOSE", { callback = function() self:ClearSendFields() end })
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() SCENE_MANAGER:HideCurrentScene() end)
end

function ZO_GuildMailManagement_Send_Gamepad:SetupSendList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)
    local function RanksDropdownEntrySetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        local dropdown = control.dropdown

        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
        dropdown:SetSelectedItemTextColor(selected)
        dropdown:SetDeactivatedCallback(function()
            self:RefreshRankDisplay()
            SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.sendList)
        end)

        dropdown:SetNoSelectionText(GetString(SI_GUILD_MAIL_MANAGEMENT_RANKS_DROPDOWN_NO_SELECTION_TEXT))
        dropdown:SetMultiSelectionTextFormatter(SI_GUILD_MAIL_MANAGEMENT_RANKS_DROPDOWN_TEXT_FORMATTER)
        dropdown:SetSortsItems(false)

        dropdown:LoadData(self.rankDropdownEntries)
    end

    list:AddDataTemplateWithHeader("ZO_Gamepad_MultiSelection_Dropdown_Item_Indented", RanksDropdownEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", nil, "RanksEntry")
end

function ZO_GuildMailManagement_Send_Gamepad:RefreshRanksData()
    self.rankDropdownEntries = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    local numRanks = GetNumGuildRanks(self.guildId)
    for rankIndex = 1, numRanks do
        local rankName = GetFinalGuildRankName(self.guildId, rankIndex)
        local rankEntry = ZO_ComboBox_Base:CreateItemEntry(rankName)
        rankEntry.rankId = GetGuildRankId(self.guildId, rankIndex)

        self.rankDropdownEntries:AddItem(rankEntry)
    end

    self:RefreshRankDisplay()
end

function ZO_GuildMailManagement_Send_Gamepad:RefreshRankDisplay()
    local selectedItems = self.rankDropdownEntries:GetSelectedItems()
    local selectedRankNames = {}
    for _, itemData in ipairs(selectedItems) do
        table.insert(selectedRankNames, itemData.name)
    end

    local rankText
    if #selectedRankNames > 0 then
        rankText = ZO_GenerateCommaSeparatedListWithoutAnd(selectedRankNames)
    else
        rankText = GetString(SI_GUILD_MAIL_MANAGEMENT_RANKS_DROPDOWN_NO_SELECTION_TEXT)
    end

    self.rankDisplay:SetText(rankText)
end

function ZO_GuildMailManagement_Send_Gamepad:ClearSendFields()
    self.subjectEdit.edit:Clear()
    self.bodyEdit.edit:Clear()
    if self.rankDropdownEntries then
        self.rankDropdownEntries:ClearAllSelections()
        self:RefreshRankDisplay()
    end
    self.sendList:RefreshVisible()
end

function ZO_GuildMailManagement_Send_Gamepad:TrySendMail()
    local rankIds = {}
    local subject = self.subjectEdit.edit:GetText()
    local body = self.bodyEdit.edit:GetText()

    local selectedRankData = self.rankDropdownEntries:GetSelectedItems()
    for _, item in ipairs(selectedRankData) do
        table.insert(rankIds, item.rankId)
    end

    RequestSendGuildMail(self.guildId, subject, body, unpack(rankIds))
end

function ZO_GuildMailManagement_Send_Gamepad:RefreshList()
    local list = self.sendList
    list:Clear()

    --Add the option for rank selection
    local rankEntryData = ZO_GamepadEntryData:New("")
    rankEntryData:SetEnabled(true)
    rankEntryData:SetHeader(GetString(SI_GUILD_MAIL_MANAGEMENT_TO_LABEL))
    rankEntryData.callback = function(entryData, entryControl)
        entryControl.dropdown:Activate()
    end
    rankEntryData.narrationText = ZO_GetDefaultParametricListDropdownNarrationText
    rankEntryData.displayLabel = self.rankDisplayLabel

    list:AddEntryWithHeader("ZO_Gamepad_MultiSelection_Dropdown_Item_Indented", rankEntryData)

    --Add the option for the subject
    local subjectEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_MAIL_SUBJECT_LABEL))
    subjectEntryData:SetEnabled(true)
    subjectEntryData.callback = function() self.subjectEdit.edit:TakeFocus() end
    subjectEntryData.displayLabel = self.subjectLabel
    subjectEntryData.displayControl = self.subjectEdit
    subjectEntryData.narrationText = function(entryData, entryControl)
        return ZO_FormatEditBoxNarrationText(self.subjectEdit.edit, entryData.text)
    end

    list:AddEntry("ZO_GamepadMenuEntryTemplate", subjectEntryData)

    --Add the option for the message
    local bodyEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_MAIL_BODY_LABEL))
    bodyEntryData:SetEnabled(true)
    bodyEntryData.callback = function() self.bodyEdit.edit:TakeFocus() end
    bodyEntryData.displayLabel = self.bodyLabel
    bodyEntryData.displayControl = self.bodyEdit
    bodyEntryData.narrationText = function(entryData, entryControl)
        return ZO_FormatEditBoxNarrationText(self.bodyEdit.edit, entryData.text)
    end

    list:AddEntry("ZO_GamepadMenuEntryTemplate", bodyEntryData)

    --Add the option for sending
    local sendEntryData = ZO_GamepadEntryData:New(GetString(SI_GUILD_RECRUITMENT_GUILD_MAIL_SEND), ZO_GAMEPAD_SUBMIT_ENTRY_ICON)
    sendEntryData:SetEnabled(function()
        return GetNumActiveGuildMailsForGuild(self.guildId) < MAX_GUILD_MAIL_PER_GUILD, GetString("SI_GUILDMAILERRESULT", GUILD_MAIL_RESULT_TOO_MANY_GUILD_MAILERS)
    end)
    sendEntryData:SetHeader(GetString(SI_GUILD_RECRUITMENT_GUILD_MAIL_SEND))
    sendEntryData.callback = function() self:TrySendMail() end

    list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", sendEntryData)

    list:Commit()
end

--Overridden from base
function ZO_GuildMailManagement_Send_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:SetCurrentList(self.sendList)
    self:RefreshRanksData()
    self:ClearSendFields()
    self:RefreshList()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

--Overridden from base
function ZO_GuildMailManagement_Send_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)
    local currentList = self:GetCurrentList()
    local targetControl = currentList:GetTargetControl()
    --Make sure dropdowns are deactivated when the screen hides
    if targetControl and targetControl.dropdown then
        targetControl.dropdown:Deactivate()
    end
end

--Overridden from base
function ZO_GuildMailManagement_Send_Gamepad:PerformUpdate()
   self.dirty = false
end

--Overridden from base
function ZO_GuildMailManagement_Send_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    ZO_Gamepad_ParametricList_Screen.OnSelectionChanged(self, list, selectedData, oldSelectedData)

    if oldSelectedData then
        if oldSelectedData.displayControl and oldSelectedData.displayControl.highlight then
            oldSelectedData.displayControl.highlight:SetHidden(true)
        end

        if oldSelectedData.displayLabel then
            oldSelectedData.displayLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        end
    end

    if selectedData then
        if selectedData.displayControl and selectedData.displayControl.highlight then
            selectedData.displayControl.highlight:SetHidden(false)
        end

        if selectedData.displayLabel then
            selectedData.displayLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        end
    end
end

function ZO_GuildMailManagement_Send_Gamepad:Show(guildId)
    if guildId ~= self.guildId then
        self.guildId = guildId
        if self.initialized then
            self:ClearSendFields()
        end
    end
    SCENE_MANAGER:Push("gamepad_guild_mail_send")
end

function ZO_GuildMailManagement_Send_Gamepad.OnControlInitialized(control)
    GUILD_MAIL_MANAGEMENT_SEND_GAMEPAD = ZO_GuildMailManagement_Send_Gamepad:New(control)
end