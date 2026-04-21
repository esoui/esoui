ZO_GUILD_MAIL_MANAGEMENT_KEYBOARD_SUBJECT_COLUMN_SIZE = 400
ZO_GUILD_MAIL_MANAGEMENT_KEYBOARD_SENDER_COLUMN_SIZE = 140
ZO_GUILD_MAIL_MANAGEMENT_KEYBOARD_EXPIRY_COLUMN_SIZE = 70
ZO_GUILD_MAIL_MANAGEMENT_KEYBOARD_COLUMN_OFFSET_X = 5

ZO_GuildMailManagement_Keyboard = ZO_DeferredInitializingObject:Subclass()

function ZO_GuildMailManagement_Keyboard:Initialize(control)
    self.control = control
    self.sendContainer = control:GetNamedChild("Send")
    self.manageContainer = control:GetNamedChild("Manage")

    self.ranksDirty = true
    self.subcategoryValue = ZO_GUILD_RECRUITMENT_GUILD_MAIL_SUBCATEGORY_SEND

    KEYBOARD_GUILD_MAIL_MANAGEMENT_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    KEYBOARD_GUILD_MAIL_MANAGEMENT_SEND_FRAGMENT = ZO_FadeSceneFragment:New(self.sendContainer)
    KEYBOARD_GUILD_MAIL_MANAGEMENT_MANAGE_FRAGMENT = ZO_FadeSceneFragment:New(self.manageContainer)

    self.mailList = ZO_GuildMail_Management_List_Keyboard:New(self.manageContainer, KEYBOARD_GUILD_MAIL_MANAGEMENT_MANAGE_FRAGMENT)
    ZO_DeferredInitializingObject.Initialize(self, KEYBOARD_GUILD_MAIL_MANAGEMENT_FRAGMENT)
end

function ZO_GuildMailManagement_Keyboard:OnDeferredInitialize()
    self.mailCountLabel = self.control:GetNamedChild("MailCount")
    self.sendBody = self.sendContainer:GetNamedChild("BodyField")
    self.sendSubject = self.sendContainer:GetNamedChild("SubjectField")
    self.sendBodyCharacterCountLabel = self.sendContainer:GetNamedChild("BodyLimit")

    self.sendRanksDropdownControl = self.sendContainer:GetNamedChild("RankSelector")
    self.sendRanksDropdown = ZO_ComboBox_ObjectFromContainer(self.sendRanksDropdownControl)
    self.sendRanksDropdown:EnableMultiSelect()
    self.sendRanksDropdown:SetNoSelectionText(GetString(SI_GUILD_MAIL_MANAGEMENT_RANKS_DROPDOWN_NO_SELECTION_TEXT))
    self.sendRanksDropdown:SetMultiSelectionTextFormatter(SI_GUILD_MAIL_MANAGEMENT_RANKS_DROPDOWN_TEXT_FORMATTER)
    self.sendRanksDropdown:SetSortsItems(false)

    self.sendSubject:SetDefaultText(GetString(SI_MAIL_SUBJECT_DEFAULT_TEXT))

    self:RegisterForEvents()
    self:InitializeKeybindStripDescriptors()
end

function ZO_GuildMailManagement_Keyboard:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_GUILD_RANKS_CHANGED, function() self:RefreshRanks() end)
    self.control:RegisterForEvent(EVENT_GUILD_MAIL_UPDATE, function() self:OnGuildMailUpdate() end)
    self.control:RegisterForEvent(EVENT_CREATE_GUILD_MAIL_RESULT, function(_, ...) self:OnCreateGuildMailResult(...) end)
    self.control:RegisterForEvent(EVENT_DELETE_GUILD_MAIL_RESULT, function(_, ...) self:OnDeleteGuildMailResult(...) end)
end

function ZO_GuildMailManagement_Keyboard:InitializeKeybindStripDescriptors()
    self.sendKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        -- Clear
        {
            name = GetString(SI_MAIL_SEND_CLEAR),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                ZO_Dialogs_ShowDialog("CONFIRM_CLEAR_MAIL_COMPOSE", { callback = function() self:ClearSendFields() end })
            end,
        },
        -- Send
        {
            name = GetString(SI_MAIL_SEND_SEND),
            keybind = "UI_SHORTCUT_SECONDARY",
            enabled = function()
                local numActiveMails = GetNumActiveGuildMailsForGuild(self.guildId)
                return numActiveMails < MAX_GUILD_MAIL_PER_GUILD, GetString("SI_GUILDMAILERRESULT", GUILD_MAIL_RESULT_TOO_MANY_GUILD_MAILERS)
            end,
            callback = function()
                self:TrySendMail()
            end,
        },
    }
end

function ZO_GuildMailManagement_Keyboard:OnShowing()
    if self.subcategoryValue == ZO_GUILD_RECRUITMENT_GUILD_MAIL_SUBCATEGORY_SEND then
        self:RefreshBodyCount()
        if self.ranksDirty then
            self:RefreshRanks()
            self.ranksDirty = false
        end
        KEYBIND_STRIP:AddKeybindButtonGroup(self.sendKeybindStripDescriptor)
    end

    self:RefreshMailCount()
end

function ZO_GuildMailManagement_Keyboard:OnHidden()
    if self.subcategoryValue == ZO_GUILD_RECRUITMENT_GUILD_MAIL_SUBCATEGORY_SEND then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.sendKeybindStripDescriptor)
    end
end

function ZO_GuildMailManagement_Keyboard:SetGuildId(guildId)
    if self.guildId ~= guildId then
        self.guildId = guildId
        if self.initialized then
            self:ClearSendFields()
            self:RefreshRanks()
            self:RefreshMailCount()
        end
        self.mailList:SetGuildId(guildId)
    end
end

function ZO_GuildMailManagement_Keyboard:SetSubcategoryValue(newValue)
    if self.subcategoryValue ~= newValue then
        self:HideCategory()

        self.subcategoryValue = newValue

        self:ShowCategory()
    end
end

function ZO_GuildMailManagement_Keyboard:ShowCategory()
    if self.subcategoryValue == ZO_GUILD_RECRUITMENT_GUILD_MAIL_SUBCATEGORY_SEND then
        SCENE_MANAGER:AddFragment(KEYBOARD_GUILD_MAIL_MANAGEMENT_SEND_FRAGMENT)
    elseif self.subcategoryValue == ZO_GUILD_RECRUITMENT_GUILD_MAIL_SUBCATEGORY_MANAGE then
        SCENE_MANAGER:AddFragment(KEYBOARD_GUILD_MAIL_MANAGEMENT_MANAGE_FRAGMENT)
    end

    SCENE_MANAGER:AddFragment(KEYBOARD_GUILD_MAIL_MANAGEMENT_FRAGMENT)
end

function ZO_GuildMailManagement_Keyboard:HideCategory()
    if self.subcategoryValue == ZO_GUILD_RECRUITMENT_GUILD_MAIL_SUBCATEGORY_SEND then
        SCENE_MANAGER:RemoveFragment(KEYBOARD_GUILD_MAIL_MANAGEMENT_SEND_FRAGMENT)
    elseif self.subcategoryValue == ZO_GUILD_RECRUITMENT_GUILD_MAIL_SUBCATEGORY_MANAGE then
        SCENE_MANAGER:RemoveFragment(KEYBOARD_GUILD_MAIL_MANAGEMENT_MANAGE_FRAGMENT)
    end
    SCENE_MANAGER:RemoveFragment(KEYBOARD_GUILD_MAIL_MANAGEMENT_FRAGMENT)
end

function ZO_GuildMailManagement_Keyboard:RefreshBodyCount()
    local numCharacters = self.sendBody:GetTextLength()
    local maxCharacters = self.sendBody:GetMaxInputChars()

    self.sendBodyCharacterCountLabel:SetText(zo_strformat(SI_GUILD_MAIL_SEND_BODY_CHARACTER_COUNT_FORMATTER_KEYBOARD, numCharacters, maxCharacters))
end

function ZO_GuildMailManagement_Keyboard:RefreshRanks()
    if not KEYBOARD_GUILD_MAIL_MANAGEMENT_SEND_FRAGMENT:IsShowing() then
        self.ranksDirty = true
        return
    end

    local numRanks = GetNumGuildRanks(self.guildId)
    self.sendRanksDropdown:ClearItems()
    for rankIndex = 1, numRanks do
        local rankName = GetFinalGuildRankName(self.guildId, rankIndex)
        local rankIconIndex = GetGuildRankIconIndex(self.guildId, rankIndex)
        local rankText = zo_iconTextFormat(GetGuildRankSmallIcon(rankIconIndex), 32, 32, rankName)
        local rankEntry = self.sendRanksDropdown:CreateItemEntry(rankText)
        rankEntry.rankId = GetGuildRankId(self.guildId, rankIndex)
        self.sendRanksDropdown:AddItem(rankEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end
    self.sendRanksDropdown:UpdateItems()
end

function ZO_GuildMailManagement_Keyboard:RefreshMailCount()
    local numActiveMails = GetNumActiveGuildMailsForGuild(self.guildId)

    local formattedMailCount = zo_strformat(SI_GUILD_MAIL_MANAGEMENT_ACTIVE_MAILS_FORMATTER, numActiveMails, MAX_GUILD_MAIL_PER_GUILD)
    if numActiveMails == MAX_GUILD_MAIL_PER_GUILD then
        formattedMailCount = ZO_ERROR_COLOR:Colorize(formattedMailCount)
    end
    self.mailCountLabel:SetText(formattedMailCount)
end

function ZO_GuildMailManagement_Keyboard:ClearSendFields()
    self.sendSubject:Clear()
    self.sendBody:Clear()

    if self.sendRanksDropdown then
        self.sendRanksDropdown:ClearAllSelections()
    end
end

function ZO_GuildMailManagement_Keyboard:TrySendMail()
    local rankIds = {}
    local subject = self.sendSubject:GetText()
    local body = self.sendBody:GetText()
    
    local selectedRankData = self.sendRanksDropdown:GetSelectedItemData()
    for _, item in ipairs(selectedRankData) do
        table.insert(rankIds, item.rankId)
    end

    RequestSendGuildMail(self.guildId, subject, body, unpack(rankIds))
end

function ZO_GuildMailManagement_Keyboard:OnCreateGuildMailResult(result)
    if result == GUILD_MAIL_RESULT_SUCCESS then
        self:RefreshMailCount()
        self:ClearSendFields()
        if KEYBOARD_GUILD_MAIL_MANAGEMENT_SEND_FRAGMENT:IsShowing() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sendKeybindStripDescriptor)
        end
    end
end

function ZO_GuildMailManagement_Keyboard:OnDeleteGuildMailResult(result)
    if result == GUILD_MAIL_RESULT_SUCCESS then
        self:RefreshMailCount()
        if KEYBOARD_GUILD_MAIL_MANAGEMENT_SEND_FRAGMENT:IsShowing() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sendKeybindStripDescriptor)
        end
    end
end

function ZO_GuildMailManagement_Keyboard:OnGuildMailUpdate()
    if self:IsShowing() then
        self:RefreshMailCount()
        if KEYBOARD_GUILD_MAIL_MANAGEMENT_SEND_FRAGMENT:IsShowing() then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.sendKeybindStripDescriptor)
        end
    end
end

function ZO_GuildMailManagement_Keyboard.OnInitialized(control)
    GUILD_MAIL_MANAGEMENT_KEYBOARD = ZO_GuildMailManagement_Keyboard:New(control)
end

--------------------------------------------------------------
-- ZO_GuildMail_Management_List_Keyboard
--------------------------------------------------------------

local MAIL_DATA = 1
local GUILD_MAIL_MANAGEMENT_SORT_KEYS =
{
    senderDisplayName = { tiebreaker = "guildMailId", tieBreakerSortOrder = ZO_SORT_ORDER_UP},
    subject = { tiebreaker = "guildMailId", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    expiresInSeconds = { isNumeric = true, tiebreaker = "guildMailId", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
    guildMailId = { isNumeric = true }
}

ZO_GuildMail_Management_List_Keyboard = ZO_SortFilterList:Subclass()

function ZO_GuildMail_Management_List_Keyboard:Initialize(control, fragment)
    ZO_SortFilterList.Initialize(self, control)
    self.fragment = fragment

    self:InitializeKeybindDescriptors()
    self:RegisterForEvents()
end

function ZO_GuildMail_Management_List_Keyboard:RegisterForEvents()
    self.fragment:RegisterCallback("StateChange", function(...) self:OnStateChange(...) end)
    self.control:RegisterForEvent(EVENT_GUILD_MAIL_UPDATE, function() self:RefreshData() end)
end

function ZO_GuildMail_Management_List_Keyboard:InitializeSortFilterList(control)
    ZO_SortFilterList.InitializeSortFilterList(self, control)

    self:SetAlternateRowBackgrounds(true)

    self.noMailRow = control:GetNamedChild("NoMailRow")
    self.noMailRowMessage = self.noMailRow:GetNamedChild("Message")

    self.masterList = {}
    ZO_ScrollList_Initialize(self.list)
    local ROW_HEIGHT = 32
    ZO_ScrollList_AddDataType(self.list, MAIL_DATA, "ZO_GuildMailManagement_MailRow_Keyboard", ROW_HEIGHT, function(...) self:SetupRow(...) end)

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareMail(listEntry1, listEntry2) end
    self.sortHeaderGroup:SelectHeaderByKey("expiresInSeconds")

    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
end

function ZO_GuildMail_Management_List_Keyboard:InitializeKeybindDescriptors()
    --TODO Guild Mailer: Add a report button
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        -- Delete
        {
            name = GetString(SI_MAIL_READ_DELETE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function()
                if self.mouseOverRow then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    return data and data.guildMailId ~= nil
                end

                return false
            end,
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                local dialogData =
                {
                    confirmationCallback = function(...)
                        RequestDeleteGuildMail(data.guildMailId)
                    end, 
                    guildMailId = data.guildMailId,
                }

                ZO_Dialogs_ShowPlatformDialog("DELETE_GUILD_MAIL", dialogData)
            end,
        },
         -- Report
        {
            name = GetString(SI_MAIL_READ_REPORT_GUILD),
            keybind = "UI_SHORTCUT_HELP",
            visible = function()
                if self.mouseOverRow then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    return data and data.guildMailId ~= nil and not data.isFromLocalPlayer
                end

                return false
            end,
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                local guildName = GetGuildName(data.guildId)
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_MAIL)
            end,
        },
    }
end

function ZO_GuildMail_Management_List_Keyboard:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWING then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    elseif newState == SCENE_FRAGMENT_SHOWN then
        self:RefreshData()
    elseif newState == SCENE_FRAGMENT_HIDDEN then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GuildMail_Management_List_Keyboard:SetGuildId(guildId)
    self.guildId = guildId
    self:RefreshData()
end

function ZO_GuildMail_Management_List_Keyboard:CompareMail(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, GUILD_MAIL_MANAGEMENT_SORT_KEYS, self.currentSortOrder)
end

function ZO_GuildMail_Management_List_Keyboard:SetupRow(entryControl, data)
    ZO_SortFilterList.SetupRow(self, entryControl, data)

    entryControl.listObject = self

    local subject = data.subject
    if subject == "" then
        subject = GetString(SI_MAIL_READ_NO_SUBJECT)
    end

    entryControl:GetNamedChild("Subject"):SetText(subject)
    entryControl:GetNamedChild("Sender"):SetText(data.senderDisplayName)

    local expiresInSeconds = data.expiresInSeconds
    local formattedExpiresText

    if expiresInSeconds <= ZO_ONE_MINUTE_IN_SECONDS then
        formattedExpiresText = GetString(SI_STR_TIME_LESS_THAN_MINUTE)
    elseif expiresInSeconds < ZO_ONE_HOUR_IN_SECONDS then
        formattedExpiresText = ZO_FormatTime(expiresInSeconds, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
    else
        formattedExpiresText = ZO_FormatTimeLargestTwo(expiresInSeconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES)
    end

    entryControl:GetNamedChild("Expires"):SetText(formattedExpiresText)
end

do
    local function GetValidMailIter(guildId)
        return function(_, previousMailId)
            return GetNextValidGuildMailIdForGuild(guildId, previousMailId)
        end
    end

    --ZO_SortFilterList overrides
    function ZO_GuildMail_Management_List_Keyboard:BuildMasterList()
        self.masterList = {}

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
                    isFromLocalPlayer = senderDisplayName == GetDisplayName()
                }

                table.insert(self.masterList, mailData)
            end
        end

        --If the master list is empty, show the empty row
        local hasEntries = #self.masterList > 0
        self.noMailRow:SetHidden(hasEntries)

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GuildMail_Management_List_Keyboard:FilterScrollList()
    -- No real filtering...just show everything in the master list
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.masterList) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(MAIL_DATA, ZO_EntryData:New(data)))
    end
end

function ZO_GuildMail_Management_List_Keyboard:SortScrollList()
    if self.currentSortKey ~= nil and self.currentSortOrder ~= nil then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end

    self:RefreshVisible()
end

function ZO_GuildMail_Management_List_Keyboard:RefreshData()
    if self.fragment:IsShowing() then
        ZO_SortFilterList.RefreshData(self)
    end
end

function ZO_GuildMail_Management_List_Keyboard:Row_OnMouseEnter(control)
    ZO_SortFilterList.Row_OnMouseEnter(self, control)
    local data = ZO_ScrollList_GetData(control)
    if data and data.guildMailId then
        InitializeTooltip(InformationTooltip, control, RIGHT, -15, 0, LEFT)
        InformationTooltip:SetGuildMailId(data.guildMailId)
    end
end

function ZO_GuildMail_Management_List_Keyboard:Row_OnMouseExit(control)
    ZO_SortFilterList.Row_OnMouseExit(self, control)
    ClearTooltip(InformationTooltip)
end

function ZO_GuildMail_Management_List_Keyboard:Row_OnMouseUp(control, button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
        ClearMenu()

        local data = ZO_ScrollList_GetData(control)
        if data and data.guildMailId then
            local function DeleteMail()
                local dialogData =
                {
                    confirmationCallback = function(...)
                        RequestDeleteGuildMail(data.guildMailId)
                    end, 
                    guildMailId = data.guildMailId,
                }
                ZO_Dialogs_ShowPlatformDialog("DELETE_GUILD_MAIL", dialogData)
            end

            AddMenuItem(GetString(SI_MAIL_READ_DELETE), DeleteMail)

            if not data.isFromLocalPlayer then
                local function ReportMail()
                    local guildName = GetGuildName(data.guildId)
                    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_MAIL)
                end

                AddMenuItem(GetString(SI_MAIL_READ_REPORT_GUILD), ReportMail)
            end

            ShowMenu(control)
        end
    end
end