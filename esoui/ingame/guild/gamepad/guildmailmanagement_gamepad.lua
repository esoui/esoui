ZO_GUILD_MAIL_MANAGEMENT_GAMEPAD_SUBJECT_COLUMN_SIZE = 385
ZO_GUILD_MAIL_MANAGEMENT_GAMEPAD_SENDER_COLUMN_SIZE = 170
ZO_GUILD_MAIL_MANAGEMENT_GAMEPAD_EXPIRES_COLUMN_SIZE = 150

local GUILD_MAIL_CATEGORIES =
{
    SEND = 1,
    MANAGE = 2,
}

ZO_GuildMailManagement_Gamepad = ZO_DeferredInitializingObject:Subclass()

function ZO_GuildMailManagement_Gamepad:Initialize(control)
    self.control = control
    self.manageContainer = self.control:GetNamedChild("ContentContainerManage")

    GUILD_MAIL_MANAGEMENT_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control)

    self.mailList = ZO_GuildMail_Management_List_Gamepad:New(self.manageContainer)
    GUILD_MAIL_MANAGEMENT_MANAGE_GAMEPAD_FRAGMENT = self.mailList:GetListFragment()

    ZO_DeferredInitializingObject.Initialize(self, GUILD_MAIL_MANAGEMENT_GAMEPAD_FRAGMENT)
end

function ZO_GuildMailManagement_Gamepad:OnDeferredInitialize()
    self.headerData =
    {
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

    self.categoryData = {}
    local sendData = ZO_GamepadEntryData:New(GetString(SI_GUILD_RECRUITMENT_GUILD_MAIL_SEND))
    sendData.category = GUILD_MAIL_CATEGORIES.SEND
    sendData:SetEnabled(function() return not self:AreActiveMailsAtMax() end)
    table.insert(self.categoryData, sendData)

    local manageData = ZO_GamepadEntryData:New(GetString(SI_GUILD_RECRUITMENT_GUILD_MAIL_MANAGE))
    manageData.category = GUILD_MAIL_CATEGORIES.MANAGE
    manageData:SetEnabled(true)
    manageData.fragment = GUILD_MAIL_MANAGEMENT_MANAGE_GAMEPAD_FRAGMENT
    manageData.backgroundFragment = GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT
    table.insert(self.categoryData, manageData)

    self:InitializeKeybindDescriptors()
    self:RegisterForEvents()
end

function ZO_GuildMailManagement_Gamepad:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_GUILD_MAIL_UPDATE, function()
        if self:IsShowing() then
            self.categoryList:RefreshVisible()
            self:RefreshKeybinds()
            self:RefreshTooltip()
            GAMEPAD_GUILD_HOME:RefreshHeader()
        end
    end)
end

function ZO_GuildMailManagement_Gamepad:InitializeKeybindDescriptors()
    -- The keybind descriptor for when focus is on the category list.
    self.categoryKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                if self.currentCategory == GUILD_MAIL_CATEGORIES.SEND then
                    return not self:AreActiveMailsAtMax()
                end

                return true
            end,
            callback = function()
                if self.currentCategory == GUILD_MAIL_CATEGORIES.SEND then
                    GUILD_MAIL_MANAGEMENT_SEND_GAMEPAD:Show(self.guildId)
                elseif self.currentCategory == GUILD_MAIL_CATEGORIES.MANAGE then
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                    self:FocusMailList()
                end
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor,
        GAME_NAVIGATION_TYPE_BUTTON, 
        function()
            self.mailList:Deactivate()
            GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
            SCENE_MANAGER:HideCurrentScene()
        end
    )
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor, self.categoryList)
end

function ZO_GuildMailManagement_Gamepad:OnShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)
    self:RefreshCategoryList()
    self:FocusCategoryList()
    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(true)

    --Use a different background fragment than usual for this screen
    --Temporarily remove the background fragment from GAMEPAD_GUILD_HOME_SCENE so we can use a different one here
    GAMEPAD_GUILD_HOME_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)

    if self.currentCategory == GUILD_MAIL_CATEGORIES.MANAGE then
        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    end
end

function ZO_GuildMailManagement_Gamepad:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)
    GAMEPAD_GUILD_HOME_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
end

function ZO_GuildMailManagement_Gamepad:OnHidden()
    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(false)
end

function ZO_GuildMailManagement_Gamepad:RefreshCategoryList()
    if not self.categoryList then
        return
    end

    self.categoryList:Clear()
    for i, data in ipairs(self.categoryData) do
        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", data)
    end

    self.categoryList:Commit()
end

function ZO_GuildMailManagement_Gamepad:FocusCategoryList()
    self.mailList:Deactivate()

    KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryKeybindStripDescriptor)

    self.categoryList:Activate()
end

function ZO_GuildMailManagement_Gamepad:FocusMailList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.categoryKeybindStripDescriptor)

    self.categoryList:Deactivate()
    self.mailList:Activate()
end

-- functions needed to be part of the Gamepad Guild Home

function ZO_GuildMailManagement_Gamepad:SetGuildId(guildId)
    self.guildId = guildId
    self.mailList:SetGuildId(guildId)
end

function ZO_GuildMailManagement_Gamepad:SetMainList(list)
    self.categoryList = list
end

function ZO_GuildMailManagement_Gamepad:GetHeaderData()
    return self.headerData
end

-- Called from GuildHome when category changes
function ZO_GuildMailManagement_Gamepad:OnTargetChanged(list, newSelectedData, oldSelectedData)
    if newSelectedData ~= oldSelectedData then
        if oldSelectedData and oldSelectedData.fragment then
            SCENE_MANAGER:RemoveFragment(oldSelectedData.fragment)
        end

        if oldSelectedData and oldSelectedData.backgroundFragment then
            SCENE_MANAGER:RemoveFragment(oldSelectedData.backgroundFragment)
        end

        if newSelectedData then
            if newSelectedData.fragment then
                SCENE_MANAGER:AddFragment(newSelectedData.fragment)
            end

            if newSelectedData.backgroundFragment then
                SCENE_MANAGER:AddFragment(newSelectedData.backgroundFragment)
            end

            self.currentCategory = newSelectedData.category
        else
            self.currentCategory = nil
        end

        self:RefreshKeybinds()
        self:RefreshTooltip()
    end
end

function ZO_GuildMailManagement_Gamepad:RefreshKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryKeybindStripDescriptor)
end

function ZO_GuildMailManagement_Gamepad:RefreshTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if self.currentCategory == GUILD_MAIL_CATEGORIES.SEND and self:AreActiveMailsAtMax() then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, GetString("SI_GUILDMAILERRESULT", GUILD_MAIL_RESULT_TOO_MANY_GUILD_MAILERS))
    end
end

function ZO_GuildMailManagement_Gamepad:AreActiveMailsAtMax()
    local numActiveMails = GetNumActiveGuildMailsForGuild(self.guildId)
    return numActiveMails == MAX_GUILD_MAIL_PER_GUILD
end

function ZO_GuildMailManagement_Gamepad.OnControlInitialized(control)
    GUILD_MAIL_MANAGEMENT_GAMEPAD = ZO_GuildMailManagement_Gamepad:New(control)
end

--------------------------------------------------------------
-- ZO_GuildMail_Management_List_Gamepad
--------------------------------------------------------------
local MAIL_DATA = 1
local GUILD_MAIL_MANAGEMENT_SORT_KEYS =
{
    senderDisplayName = { tiebreaker = "guildMailId", tieBreakerSortOrder = ZO_SORT_ORDER_UP},
    subject = { tiebreaker = "guildMailId", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    expiresInSeconds = { isNumeric = true, tiebreaker = "guildMailId", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    guildMailId = { isNumeric = true }
}


ZO_GuildMail_Management_List_Gamepad = ZO_GamepadInteractiveSortFilterList:Subclass()

function ZO_GuildMail_Management_List_Gamepad:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)

    self:SetEmptyText(GetString(SI_GUILD_MAIL_MANAGEMENT_MAIL_LIST_EMPTY_TEXT))
    self:SetupSort(GUILD_MAIL_MANAGEMENT_SORT_KEYS, "expiresInSeconds", ZO_SORT_ORDER_UP)

    self:RegisterForEvents()
end

function ZO_GuildMail_Management_List_Gamepad:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_GUILD_MAIL_UPDATE, function() self:RefreshData() end)
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:InitializeSortFilterList(...)
    ZO_GamepadInteractiveSortFilterList.InitializeSortFilterList(self, ...)
    ZO_ScrollList_AddDataType(self.list, MAIL_DATA, "ZO_GuildMailManagement_Mail_Row_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(entryControl, entryData) self:SetupRow(entryControl, entryData) end)
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:SetupRow(control, data)
    ZO_GamepadInteractiveSortFilterList.SetupRow(self, control, data)

    local subject = data.subject
    if subject == "" then
        subject = GetString(SI_MAIL_READ_NO_SUBJECT)
    end

    control.subjectLabel:SetText(subject)
    control.senderLabel:SetText(data.senderDisplayName)

    local expiresInSeconds = data.expiresInSeconds
    local formattedExpiresText

    if expiresInSeconds <= ZO_ONE_MINUTE_IN_SECONDS then
        formattedExpiresText = GetString(SI_STR_TIME_LESS_THAN_MINUTE)
    elseif expiresInSeconds < ZO_ONE_HOUR_IN_SECONDS then
        formattedExpiresText = ZO_FormatTime(expiresInSeconds, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
    else
        formattedExpiresText = ZO_FormatTimeLargestTwo(expiresInSeconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES)
    end
    control.expiresLabel:SetText(formattedExpiresText)
end

function ZO_GuildMail_Management_List_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Delete
        {
            name = GetString(SI_MAIL_READ_DELETE),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                local selectedData = self:GetSelectedData()
                return selectedData ~= nil
            end,
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData.guildMailId then
                    local dialogData =
                    {
                        confirmationCallback = function(...)
                            RequestDeleteGuildMail(selectedData.guildMailId)
                        end, 
                        guildMailId = selectedData.guildMailId,
                    }

                    ZO_Dialogs_ShowPlatformDialog("DELETE_GUILD_MAIL", dialogData)
                end
            end,
        },
        -- Report
        {
            name = GetString(SI_MAIL_READ_REPORT_GUILD),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            visible = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    return selectedData.senderDisplayName ~= GetDisplayName()
                end

                return false
            end,
            callback = function()
                local selectedData = self:GetSelectedData()
                local guildName = GetGuildName(selectedData.guildId)
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_MAIL)
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())

    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:GetBackKeybindCallback()
    return function() GUILD_MAIL_MANAGEMENT_GAMEPAD:FocusCategoryList() end
end

do
    local function GetValidMailIter(guildId)
        return function(_, previousMailId)
            return GetNextValidGuildMailIdForGuild(guildId, previousMailId)
        end
    end

    --Overridden from base
    function ZO_GuildMail_Management_List_Gamepad:BuildMasterList()
        ZO_ClearNumericallyIndexedTable(self.masterList)
        if self.guildId then
            for guildMailId in GetValidMailIter(self.guildId) do
                local guildId, subject, body, _, expiresInSeconds, _, senderDisplayName = GetGuildMailItemInfo(guildMailId)

                if senderDisplayName == "" then
                    senderDisplayName = GetString(SI_GUILD_MAIL_MANAGEMENT_UNKNOWN_SENDER)
                else
                    senderDisplayName = ZO_FormatUserFacingDisplayName(senderDisplayName)
                end

                local mailData =
                {
                    guildId = guildId,
                    guildMailId = guildMailId,
                    subject = subject,
                    body = body,
                    expiresInSeconds = expiresInSeconds,
                    senderDisplayName = senderDisplayName,
                }

                table.insert(self.masterList, mailData)
            end
        end
    end
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:FilterScrollList()
    -- No real filtering...just show everything in the master list
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.masterList) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(MAIL_DATA, ZO_EntryData:New(data)))
    end
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.OnSelectionChanged(self, oldData, newData)

    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
    if newData and newData.guildMailId then
        GAMEPAD_TOOLTIPS:LayoutGuildMail(GAMEPAD_RIGHT_TOOLTIP, newData.guildMailId)
    end

    self:UpdateKeybinds()
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:OnShowing()
    ZO_GamepadInteractiveSortFilterList.OnShowing(self)
    self:RefreshData()
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:GetNarrationText()
    local narrations = {}
    --The tooltip handles most of the narration for these entries
    ZO_AppendNarration(narrations, self:GetEmptyRowNarration())
    return narrations
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_RECRUITMENT_GUILD_MAIL_MANAGE))
end

--Overridden from base
function ZO_GuildMail_Management_List_Gamepad:GetFooterNarration()
    return GAMEPAD_GUILD_HOME:GetFooterNarrationText()
end

function ZO_GuildMail_Management_List_Gamepad:SetGuildId(guildId)
    if self.guildId ~= guildId then
        self.guildId = guildId
        if self:IsShowing() then
            self:RefreshData()
        end
    end
end

function ZO_GuildMail_Management_List_Gamepad:IsShowing()
    local listFragment = self:GetListFragment()
    if listFragment then
        return listFragment:IsShowing()
    end

    return false
end

function ZO_GuildMail_Management_List_Gamepad.OnRowControlInitialized(control)
    control.subjectLabel = control:GetNamedChild("Subject")
    control.senderLabel = control:GetNamedChild("Sender")
    control.expiresLabel = control:GetNamedChild("Expires")
end