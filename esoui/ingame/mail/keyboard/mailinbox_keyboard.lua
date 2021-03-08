local MailInbox = ZO_InitializingObject:Subclass()

local MAX_READ_ATTACHMENTS = MAIL_MAX_ATTACHED_ITEMS + 1
ZO_MAIL_INDBOX_KEYBOARD_TREE_WDITH = 386
ZO_MAIL_INDBOX_KEYBOARD_NODE_WDITH = ZO_MAIL_INDBOX_KEYBOARD_TREE_WDITH - ZO_SCROLL_BAR_WIDTH
local TREE_CHILD_INDENT = 33
ZO_MAIL_INDBOX_KEYBOARD_NODE_INDENTED_WDITH = ZO_MAIL_INDBOX_KEYBOARD_NODE_WDITH - TREE_CHILD_INDENT
ZO_MAIL_INDBOX_KEYBOARD_NODE_HEIGHT = 50

function MailInbox:Initialize(control)
    self.control = control

    MAIL_INBOX_SCENE = ZO_Scene:New("mailInbox", SCENE_MANAGER)
    MAIL_INBOX_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.selectionKeybindStripDescriptor)
            if self.inboxDirty then
                self:RefreshData()
            end
        elseif newState == SCENE_HIDING then
            CURRENCY_INPUT:Hide()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.selectionKeybindStripDescriptor)
        end
    end)
    
    self.masterList = {}
    self.reportedMailIds = {}
    self.playerMailNodeData = { text = GetString(SI_MAIL_NO_PLAYER_MAIL_HEADER), unreadData = {} }
    self.systemMailNodeData = { text = GetString(SI_MAIL_NO_SYSTEM_MAIL_HEADER), unreadData = {} }
    self.playerMailEmptyNodeData = { text = GetString(SI_MAIL_NO_PLAYER_MAIL_ENTRY) }
    self.systemMailEmptyNodeData = { text = GetString(SI_MAIL_NO_SYSTEM_MAIL_ENTRY) }
    self.isFirstTimeOpening = true

    self:InitializeControls()
    self:InitializeList()
    self:InitializeKeybindDescriptors()
    self:CreateAttachmentSlots()
    self:RegisterForEvents()
end

function MailInbox:InitializeControls()
    local control = self.control
    self.messageControl = control:GetNamedChild("Message")
    self.unreadLabel = control:GetNamedChild("UnreadLabel")
    self.messagePaneControl = self.messageControl:GetNamedChild("Pane")
    self.subjectLabel = self.messageControl:GetNamedChild("Subject")
    self.expirationLabel = self.messageControl:GetNamedChild("Expires")
    self.receivedLabel = self.messageControl:GetNamedChild("Received")
    self.bodyLabel = self.messageControl:GetNamedChild("Body")
    self.fromControl = self.messageControl:GetNamedChild("From")
    self.attachmentsControl = self.messageControl:GetNamedChild("Attachments")
    self.attachmentsHeaderControl = self.attachmentsControl:GetNamedChild("Header")
    self.attachmentsDividerControl = self.attachmentsControl:GetNamedChild("Divider")
    self.sentMoneyControl = self.messageControl:GetNamedChild("SentMoney")
    self.sentMoneyCurrencyControl = self.sentMoneyControl:GetNamedChild("Currency")
    self.codControl = self.messageControl:GetNamedChild("COD")
    self.codCurrencyControl = self.codControl:GetNamedChild("Currency")
    self.navigationContainer = control:GetNamedChild("NavigationContainer")
    self.fullLabel = control:GetNamedChild("Full")
    self.nodeBGControlPool = ZO_ControlPool:New("ZO_MailInboxRowBg", self.navigationContainer:GetNamedChild("ScrollChild"))
    self.minNumBackgroundControls = zo_ceil(self.navigationContainer:GetHeight() / ZO_MAIL_INDBOX_KEYBOARD_NODE_HEIGHT / 2)

    self:SetNumUnread(GetNumUnreadMail())
end

function MailInbox:InitializeList()
    local navigationTree = ZO_Tree:New(self.navigationContainer:GetNamedChild("ScrollChild"), 0, 0, ZO_MAIL_INDBOX_KEYBOARD_NODE_WDITH)

    local function UpdateSize(control)
        control:SetDimensions(ZO_MAIL_INDBOX_KEYBOARD_NODE_WDITH, ZO_MAIL_INDBOX_KEYBOARD_NODE_HEIGHT)
    end

    local function TreeHeaderSetup(node, control, headerData, open, userRequested)
        control:SimpleArrowSetup(headerData.text, open)

        local ENABLED = true
        local DISABLE_SCALING = true
        ZO_IconHeader_Setup(control, open, ENABLED, DISABLE_SCALING, UpdateSize)

        if not control.statusIcon then
            control.statusIcon = control:GetNamedChild("StatusIcon")
        end

        control.statusIcon:ClearIcons()

        if NonContiguousCount(headerData.unreadData) > 0 then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()

        if userRequested then
            if open then
                navigationTree:SelectFirstChild(node)
            else
                local selectedMailNode = navigationTree:GetSelectedNode()
                if selectedMailNode and selectedMailNode:GetParent() == node then
                    navigationTree:ClearSelectedNode()
                end
            end
        end
    end

    local function MailEntryOnSelected(control, mailData, selected, reselectingDuringRebuild)
        if selected then
            control:HighlightControl()
            if not reselectingDuringRebuild then
                self:RequestReadMessage(mailData.mailId)
            end
        elseif not control.isMouseOverTarget then
            control:UnhighlightControl()
            self:EndRead()
        end
    end

    local READ_COLOR = ZO_ColorDef:New(0.6, 0.6, 0.6)

    local function MailEntrySetup(node, control, mailData, open)
        control.subjectLabel:SetText(mailData:GetFormattedSubject())

        local subjectColor = nil
        if control.isMouseOverTarget or node.selected then
            subjectColor = ZO_SELECTED_TEXT
        elseif mailData.unread then
            subjectColor = ZO_SECOND_CONTRAST_TEXT
        else
            subjectColor = READ_COLOR
        end
        local r, g, b = subjectColor:UnpackRGB()
        control.subjectLabel:SetColor(r, g, b, control:GetControlAlpha())

        local iconTexture = control.iconTexture
        iconTexture:ClearIcons()
        if mailData.unread then
            iconTexture:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        if mailData.fromSystem then
            iconTexture:AddIcon("EsoUI/Art/Mail/mail_systemIcon.dds")
        elseif mailData.fromCS then
            iconTexture:AddIcon("EsoUI/Art/Mail/mail_CSIcon.dds")
        end

        if mailData:IsExpirationImminent() then
            iconTexture:AddIcon("EsoUI/Art/Miscellaneous/timerRed_32.dds")
            local expiresText = zo_strformat(SI_MAIL_INBOX_EXPIRES_TEXT, mailData:GetExpiresText())
            control.expirationLabel:SetText(expiresText)
            control.expirationLabel:SetHidden(false)
        else
            control.expirationLabel:SetHidden(true)
        end

        iconTexture:Show()
    end

    local function CategoryEqualityFunction(leftData, rightData)
         return leftData.text == rightData.text
    end

    local function MailEqualityFunction(leftData, rightData)
        return AreId64sEqual(leftData.mailId, rightData.mailId)
    end

    local function MailEmptyEntrySetup(node, control, nodeData, open)
        control.textLabel:SetText(nodeData.text)
    end

    local CHILD_SPACING = 0
    local NO_SELECTED_CALLBACK = nil
    navigationTree:AddTemplate("ZO_MailInboxHeader", TreeHeaderSetup, NO_SELECTED_CALLBACK, CategoryEqualityFunction, TREE_CHILD_INDENT, CHILD_SPACING)
    navigationTree:AddTemplate("ZO_MailInboxRow", MailEntrySetup, MailEntryOnSelected, MailEqualityFunction)
    navigationTree:AddTemplate("ZO_MailInboxEmptyRow", MailEmptyEntrySetup, NO_SELECTED_CALLBACK)
    self.navigationTree = navigationTree
end

function MailInbox:RegisterForEvents()
    local control = self.control
    control:RegisterForEvent(EVENT_MAIL_INBOX_UPDATE, function() self:OnInboxUpdate() end)
    control:RegisterForEvent(EVENT_MAIL_READABLE, function(_, mailId) self:OnMailReadable(mailId) end)
    control:RegisterForEvent(EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, function(_, mailId) self:OnTakeAttachedItemSuccess(mailId) end)
    control:RegisterForEvent(EVENT_MAIL_TAKE_ATTACHED_MONEY_SUCCESS, function(_, mailId) self:OnTakeAttachedMoneySuccess(mailId) end)
    control:RegisterForEvent(EVENT_MAIL_REMOVED, function(_, mailId) self:OnMailRemoved(mailId) end)
    control:RegisterForEvent(EVENT_MAIL_NUM_UNREAD_CHANGED, function(_, numUnread) self:OnMailNumUnreadChanged(numUnread) end)
    control:RegisterForEvent(EVENT_MAIL_OPEN_MAILBOX, function()
        --It's possible that the mail that's selected was selected after we closed the mail interaction (for example, deleting the current mail and
        --rapidly closing the window). In that case we never sent a message to the server to get the mail contents so the details pane is empty.
        --If we show the window again and the request hasn't be responsed to then self.requestedMailId will still be set so we know we have to query
        --again now that the interaction is open again. We wait till shown for the interaction to be open.
        if self.pendingRequestMailId then
            self:RequestReadMessage(self.pendingRequestMailId)
        end
    end)
end

function MailInbox:InitializeKeybindDescriptors()
    self.selectionKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        --Return
        {
            name = GetString(SI_MAIL_READ_RETURN),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                self:Return()
            end,

            visible = function()
                if(self.mailId) then
                    return IsMailReturnable(self.mailId)
                end
                return false
            end
        },

        -- Delete
        {
            name = GetString(SI_MAIL_READ_DELETE),
            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                self:Delete()
            end,

            visible = function()
                if(self.mailId) then
                    return not IsMailReturnable(self.mailId) and self:IsMailDeletable()
                end
                return false
            end
        },

        -- Take Attachments
        {
            name = GetString(SI_MAIL_READ_ATTACHMENTS_TAKE),
            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                self:TryTakeAll()
            end,

            visible = function()
                if(self.mailId) then
                    local numAttachments, attachedMoney, codAmount = GetMailAttachmentInfo(self.mailId)
                    if(numAttachments > 0 or attachedMoney > 0) then
                        return true
                    end
                end
                return false
            end
        },

        --Report Player
        {
            name = GetString(SI_MAIL_READ_REPORT_PLAYER),
            keybind = "UI_SHORTCUT_REPORT_PLAYER",

            visible = function()
                if not self:HasAlreadyReportedSelectedMail() then
                    local mailData = self:GetMailData(self.mailId)
                    return mailData and mailData.isFromPlayer
                end
            end,

            callback = function()
                if(self.mailId) then
                    local senderDisplayName = GetMailSender(self.mailId)
                    local function ReportCallback()
                        self:RecordSelectedMailAsReported()
                        if not IsIgnored() then
                            AddIgnore(senderDisplayName)
                        end
                    end
                    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(senderDisplayName, ReportCallback)
                end
            end,
        },
    }
end

function MailInbox:CreateAttachmentSlots()
    self.attachmentSlots = {}
    local parent = self.attachmentsControl
    local previous

    for i = 1, MAX_READ_ATTACHMENTS do
        local slot = CreateControlFromVirtual(parent:GetName().."Slot", parent, "ZO_MailInboxAttachmentSlot", i)
        if previous then
            slot:SetAnchor(TOPLEFT, previous, TOPRIGHT, 5, 0)
        else
            slot:SetAnchor(TOPLEFT, parent, TOPLEFT, 0, 0)
        end
        
        slot.id = i
        
        slot.icon = slot:GetNamedChild("ItemIcon")
        
        slot:SetNormalTexture()
        slot:SetPressedTexture()
        
        ZO_Inventory_BindSlot(slot, SLOT_TYPE_MAIL_ATTACHMENT, i)
        ZO_Inventory_SetupSlot(slot, 0) 

        self.attachmentSlots[i] = slot

        previous = slot
    end
end

function MailInbox:SetNumUnread(numUnread)
    self.unreadLabel:SetText(numUnread)
end

function MailInbox:GetMailData(mailId)
    if self.masterList then
        for i = 1, #self.masterList do
            local data = self.masterList[i]
            if AreId64sEqual(data.mailId, mailId) then
                return data
            end
        end
    end
end

do
    local function MailComparator(mailData1, mailData2)
        return ZO_TableOrderingFunction(mailData1, mailData2, MAIL_ENTRY_FIRST_SORT_KEY, MAIL_ENTRY_SORT_KEYS, ZO_SORT_ORDER_UP)
    end

    function MailInbox:RefreshData()
        if not SCENE_MANAGER:IsShowing("mailInbox") then
            self.inboxDirty = true
            return
        end

        -- Initialize and clear
        self.inboxDirty = false
        local tree = self.navigationTree
        tree:Reset()
        self.nodeBGControlPool:ReleaseAllObjects()

        local nodeTemplate = nil

        local masterList = self.masterList
        ZO_ClearNumericallyIndexedTable(masterList)
        local playerList = {}
        local systemList = {}

        local playerMailNodeData = self.playerMailNodeData
        local systemMailNodeData = self.systemMailNodeData
        ZO_ClearTable(playerMailNodeData.unreadData)
        ZO_ClearTable(systemMailNodeData.unreadData)

        -- Accumulate data
        for mailId in ZO_GetNextMailIdIter do
            local mailData = {}
            ZO_MailInboxShared_PopulateMailData(mailData, mailId)
            table.insert(masterList, mailData)

            if mailData.isFromPlayer then
                table.insert(playerList, mailData)
                if mailData.unread then
                    playerMailNodeData.unreadData[mailData] = true
                end
            else
                table.insert(systemList, mailData)
                if mailData.unread then
                    systemMailNodeData.unreadData[mailData] = true
                end
            end
        end

        table.sort(playerList, MailComparator)
        table.sort(systemList, MailComparator)

        local numPlayerMails = #playerList
        local numSystemMails = #systemList

        -- Add BGs
        -- Number of player mails (or "empty" node if none), plus header node
        local numPlayerNodes = zo_max(numPlayerMails, 1) + 1
        -- Number of system mails (or "empty" node if none), plus header node
        local numSystemNodes = zo_max(numSystemMails, 1) + 1
        local numTotalNodes = numPlayerNodes + numSystemNodes
        -- Every other node gets a background
        local numBGControlsToAdd = zo_max(zo_ceil(numTotalNodes / 2), self.minNumBackgroundControls)

        local previousBGControl = nil
        for i = 1, numBGControlsToAdd do
            local bgControl = self.nodeBGControlPool:AcquireObject()
            if previousBGControl then
                bgControl:SetAnchor(TOPLEFT, previousBGControl, BOTTOMLEFT, 0, ZO_MAIL_INDBOX_KEYBOARD_NODE_HEIGHT)
            else
                bgControl:SetAnchor(TOPLEFT)
            end
            previousBGControl = bgControl
        end

        -- Add header nodes
        playerMailNodeData.text = (numPlayerMails > 0) and zo_strformat(SI_MAIL_PLAYER_MAIL_HEADER, numPlayerMails) or GetString(SI_MAIL_NO_PLAYER_MAIL_HEADER)
        local playerMailNode = tree:AddNode("ZO_MailInboxHeader", playerMailNodeData)
        systemMailNodeData.text = (numSystemMails > 0) and zo_strformat(SI_MAIL_SYSTEM_MAIL_HEADER, numSystemMails) or GetString(SI_MAIL_NO_SYSTEM_MAIL_HEADER)
        local systemMailNode = tree:AddNode("ZO_MailInboxHeader", systemMailNodeData)
        
        local autoSelectNode = nil

        -- Add player nodes
        if numPlayerMails > 0 then
            for index, mailData in ipairs(playerList) do
                mailData.node = tree:AddNode("ZO_MailInboxRow", mailData, playerMailNode)
                if self.selectMailIdOnRefresh and not autoSelectNode and AreId64sEqual(mailData.mailId, self.selectMailIdOnRefresh) then
                    autoSelectNode = mailData.node
                end
            end
        else
            tree:AddNode("ZO_MailInboxEmptyRow", self.playerMailEmptyNodeData, playerMailNode)
        end

        -- Add system nodes
        if numSystemMails > 0 then
            for index, mailData in ipairs(systemList) do
                mailData.node = tree:AddNode("ZO_MailInboxRow", mailData, systemMailNode)
                if not autoSelectNode then
                    if self.selectMailIdOnRefresh then
                        if AreId64sEqual(mailData.mailId, self.selectMailIdOnRefresh) then
                            autoSelectNode = mailData.node
                        end
                    elseif self.isFirstTimeOpening then
                        -- Select the first node of the system list if opening for the first time and nothing else is auto selecting
                        autoSelectNode = mailData.node
                    end
                end
            end
        else
            tree:AddNode("ZO_MailInboxEmptyRow", self.systemMailEmptyNodeData, systemMailNode)
        end

        self.isFirstTimeOpening = false
        self.selectMailIdOnRefresh = nil

        local DONT_BRING_PARENT_INTO_VIEW = false
        tree:Commit(autoSelectNode, DONT_BRING_PARENT_INTO_VIEW)

        self.fullLabel:SetHidden(not IsLocalMailboxFull())
    end
end

function MailInbox:EndRead()
    for i=1, MAX_READ_ATTACHMENTS do
        self.attachmentSlots[i].money = nil
        ZO_Inventory_SetupSlot(self.attachmentSlots[i], 0)
    end

    self.messageControl:SetHidden(true)
    self.mailId = nil
    self.pendingAcceptCOD = nil

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)
end

function MailInbox:RequestReadMessage(mailId)
    if not AreId64sEqual(self.mailId, mailId) then
        self.pendingRequestMailId = mailId
        RequestReadMail(mailId)
    end
end

function MailInbox:ShowTakeAttachmentsWithCODDialog(codAmount)
    ZO_Dialogs_ShowDialog("MAIL_TAKE_ATTACHMENT_COD", {codAmount = codAmount})
end

function MailInbox:Return()
    if self.mailId then
        if IsMailReturnable(self.mailId) then
            local mailData = self:GetMailData(self.mailId)
            if mailData.numAttachments > 0 or mailData.attachedMoney > 0 then
                ZO_Dialogs_ShowDialog("MAIL_RETURN_ATTACHMENTS", {callback = ReturnMail, mailId = self.mailId}, {mainTextParams = {mailData.senderDisplayName}})
            else
                ReturnMail(self.mailId)
            end
        end
    end
end

function MailInbox:Delete()
    if self.mailId then
        if self:IsMailDeletable() then
            local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)

            if numAttachments > 0 and attachedMoney > 0 then
                ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS_AND_MONEY", self.mailId)
            elseif numAttachments > 0 then
                ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS", self.mailId)
            elseif attachedMoney > 0 then
                ZO_Dialogs_ShowDialog("DELETE_MAIL_MONEY", self.mailId)
            else
                ZO_Dialogs_ShowDialog("DELETE_MAIL", {callback = function(...) self:ConfirmDelete(...) end, mailId = self.mailId})
            end
        end
    end
end

function MailInbox:TryTakeAll()
    if self.mailId then
        local mailId = self.mailId
        local numAttachments, attachedMoney, codAmount = GetMailAttachmentInfo(mailId)
        
        if codAmount > 0 then
            self:ShowTakeAttachmentsWithCODDialog(codAmount)
            self.pendingAcceptCOD = true
        else
            if attachedMoney > 0 then
                if ((GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) + attachedMoney) > MAX_PLAYER_CURRENCY) then
                    ZO_AlertEvent(EVENT_UI_ERROR, SI_MONEY_ATTACHMENT_WILL_EXCEED_MAXIMUM)
                    return
                end
            end
            ZO_MailInboxShared_TakeAll(mailId)
        end
    end
end

function MailInbox:IsMailDeletable()
    local mailData = self:GetMailData(self.mailId)
    if(mailData) then
        return mailData.attachedMoney == 0 and mailData.numAttachments == 0
    end
end

--Global API

function MailInbox:GetOpenMailId()
    return self.mailId
end

function MailInbox:ConfirmAcceptCOD()
    if self.mailId then
        local mailId = self.mailId
        if self.pendingAcceptCOD then
            ZO_MailInboxShared_TakeAll(mailId)
            PlaySound(SOUNDS.MAIL_ACCEPT_COD)
            self.pendingAcceptCOD = nil
        end
    end
end

function MailInbox:ConfirmDelete(mailId)
    if not IsMailReturnable(mailId) then
        DeleteMail(mailId, true)
        PlaySound(SOUNDS.MAIL_ITEM_DELETED)
    end
end

--Events

function MailInbox:OnInboxUpdate()
    if(SCENE_MANAGER:IsShowing("mailInbox")) then
        self:RefreshData()
        self:RefreshMailFrom()
    else
        self.inboxDirty = true
    end
end

local MAIL_COD_ATTACHED_MONEY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontWinH4",
    iconSide = RIGHT,
}

function MailInbox:OnMailReadable(mailId)
    if not AreId64sEqual(mailId, self.pendingRequestMailId) then
        return
    end

    self:EndRead()

    self.pendingRequestMailId = nil
    self.mailId = mailId
    self.messageControl:SetHidden(false)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)

    local mailData = self:GetMailData(mailId)
    ZO_MailInboxShared_PopulateMailData(mailData, mailId)
    if not mailData.unread then
        mailData.node.parentNode.data.unreadData[mailData] = nil
    end
    local NOT_USER_REQUESTED = false
    self.navigationTree:RefreshVisible(NOT_USER_REQUESTED)

    ZO_MailInboxShared_UpdateInbox(mailData, self.fromControl, self.subjectLabel, self.expirationLabel, self.receivedLabel, self.bodyLabel)
    self:RefreshMailFrom()
    ZO_Scroll_ResetToTop(self.messagePaneControl)

    self:RefreshMoneyControls()
    self:RefreshAttachmentsHeaderShown()
    self:RefreshAttachmentSlots()
end

function MailInbox:RefreshMailFrom()
    if self.mailId then
        local mailData = self:GetMailData(self.mailId)
        if mailData.senderCharacterName ~= "" then
            local fromName = ZO_GetPrimaryPlayerName(mailData.senderDisplayName, mailData.senderCharacterName)
            self.fromControl:SetText(fromName)
            mailData.senderTooltipName = ZO_GetSecondaryPlayerName(mailData.senderDisplayName, mailData.senderCharacterName)
        end
    end
end

function MailInbox:RefreshAttachmentSlots()
    local mailData = self:GetMailData(self.mailId)
    local numAttachments = mailData.numAttachments
    for i = 1, numAttachments do
        self.attachmentSlots[i]:SetHidden(false)
        local icon, stack, creator = GetAttachedItemInfo(self.mailId, i)
        ZO_Inventory_SetupSlot(self.attachmentSlots[i], stack, icon)
    end
    
    for i = numAttachments + 1, MAX_READ_ATTACHMENTS do
        self.attachmentSlots[i]:SetHidden(true)
    end
end

function MailInbox:RefreshMoneyControls()
    local mailData = self:GetMailData(self.mailId)
    self.sentMoneyControl:SetHidden(true)
    self.codControl:SetHidden(true)
    if(mailData.attachedMoney > 0) then
        self.sentMoneyControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(self.sentMoneyCurrencyControl, CURT_MONEY, mailData.attachedMoney, MAIL_COD_ATTACHED_MONEY_OPTIONS)
    elseif(mailData.codAmount > 0) then
        self.codControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(self.codCurrencyControl, CURT_MONEY, mailData.codAmount, MAIL_COD_ATTACHED_MONEY_OPTIONS)
    end
end

function MailInbox:RefreshAttachmentsHeaderShown()
    local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)
    local noAttachments = numAttachments == 0 and attachedMoney == 0
    self.attachmentsHeaderControl:SetHidden(noAttachments)
    self.attachmentsDividerControl:SetHidden(noAttachments)
end

function MailInbox:OnTakeAttachedItemSuccess(mailId)
    if AreId64sEqual(self.mailId, mailId) then
        ZO_MailInboxShared_PopulateMailData(self:GetMailData(self.mailId), mailId)
        self:RefreshAttachmentSlots()
        self:RefreshAttachmentsHeaderShown()
        self:RefreshMoneyControls()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)
    end
end

function MailInbox:OnTakeAttachedMoneySuccess(mailId)
    if AreId64sEqual(self.mailId, mailId) then
        self.sentMoneyControl:SetHidden(true)
        ZO_MailInboxShared_PopulateMailData(self:GetMailData(self.mailId), mailId)
        self:RefreshAttachmentsHeaderShown()
        self:RefreshMoneyControls()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)
    end
end

function MailInbox:OnMailRemoved(mailId)
    self.reportedMailIds[zo_getSafeId64Key(mailId)] = nil
    if AreId64sEqual(self.mailId, mailId) then
        self:EndRead()
    end
    local selectedMailNode = self.navigationTree:GetSelectedNode()
    if selectedMailNode then
        local nextOrPreviousNode = selectedMailNode:GetNextOrPreviousSiblingNode()
        if nextOrPreviousNode then
            self.selectMailIdOnRefresh = nextOrPreviousNode.data.mailId
        end
    end
    self:RefreshData()
end

function MailInbox:OnMailNumUnreadChanged(numUnread)
    self:SetNumUnread(numUnread)
end

function MailInbox:HasAlreadyReportedSelectedMail()
    return self.reportedMailIds[zo_getSafeId64Key(self.mailId)]
end

function MailInbox:RecordSelectedMailAsReported()
    if(self.mailId) then
        self.reportedMailIds[zo_getSafeId64Key(self.mailId)] = true
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)
    end
end

--Local XML

function MailInbox:MessageFrom_OnMouseEnter(control)
    local mailData = self:GetMailData(self.mailId)
    if mailData and mailData.senderTooltipName then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -5)
        SetTooltipText(InformationTooltip, mailData.senderTooltipName)
    end
end

function MailInbox:MessageFrom_OnMouseExit()
    ClearTooltip(InformationTooltip)
end

function MailInbox:Row_OnMouseEnter(control)
    control.isMouseOverTarget = true
    control.node:RefreshControl()
    control:HighlightControl()
end

function MailInbox:Row_OnMouseExit(control)
    control.isMouseOverTarget = false
    control.node:RefreshControl()
    if not control.node.selected then
        control:UnhighlightControl()
    end
end

function MailInbox:Row_OnMouseUp(control, button, upInside)
    ZO_TreeEntry_OnMouseUp(control, upInside)
end

function MailInbox:Unread_OnMouseEnter(control)
    local numUnreadMail = GetNumUnreadMail()
    InitializeTooltip(InformationTooltip, control, RIGHT, 0, 0)
    if(numUnreadMail == 0) then
        SetTooltipText(InformationTooltip, GetString(SI_MAIL_NO_UNREAD_MAIL))
    else
        SetTooltipText(InformationTooltip, zo_strformat(SI_MAIL_UNREAD_MAIL, numUnreadMail))
    end
end

function MailInbox:Unread_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

--Global XML

function ZO_MailInboxMessageFrom_OnMouseEnter(control)
    MAIL_INBOX:MessageFrom_OnMouseEnter(control)
end

function ZO_MailInboxMessageFrom_OnMouseExit()
    MAIL_INBOX:MessageFrom_OnMouseExit()
end

do
    local function HighlightControl(control, animateInstantly)
        if not control.highlight then
            control.highlight = CreateControlFromVirtual("$(parent)Highlight", control, "ZO_ThinListHighlight")
            control.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", control.highlight)
        end
    
        if animateInstantly then
            control.highlightAnimation:PlayInstantlyToEnd()
        else
            control.highlightAnimation:PlayForward()
        end
    end

    local function UnhighlightControl(control, animateInstantly)
        if control.highlight then
            if animateInstantly then
                control.highlightAnimation:PlayInstantlyToStart()
            else
                control.highlightAnimation:PlayBackward()
            end
        end
    end

    function ZO_MailInboxRow_OnInitialized(control)
        control.iconTexture = control:GetNamedChild("Icon")
        local textContainer = control:GetNamedChild("TextContainer")
        control.subjectLabel = textContainer:GetNamedChild("Subject")
        control.expirationLabel = textContainer:GetNamedChild("Expiration")
        control.HighlightControl = HighlightControl
        control.UnhighlightControl = UnhighlightControl
    end
end

function ZO_MailInboxRow_OnMouseEnter(control)
    MAIL_INBOX:Row_OnMouseEnter(control)
end

function ZO_MailInboxRow_OnMouseExit(control)
    MAIL_INBOX:Row_OnMouseExit(control)
end

function ZO_MailInboxRow_OnMouseUp(control, ...)
    MAIL_INBOX:Row_OnMouseUp(control, ...)
end

function ZO_MailInboxUnread_OnMouseEnter(control)
    MAIL_INBOX:Unread_OnMouseEnter(control)
end

function ZO_MailInboxUnread_OnMouseExit(control)
    MAIL_INBOX:Unread_OnMouseExit(control)
end

function ZO_MailInbox_OnInitialized(self)
    MAIL_INBOX = MailInbox:New(self)
end

function ZO_TakeAttachmentCODDialog_OnInitialized(self)
    self.confirmTextLabel = self:GetNamedChild("ConfirmText")
    self.currentGoldContainer = self:GetNamedChild("CurrentGoldContainer")
    self.codFeeContainer = self:GetNamedChild("CODFeeContainer")

    ZO_Dialogs_RegisterCustomDialog("MAIL_TAKE_ATTACHMENT_COD",
    {
        customControl = self,
        setup = function(dialog, data)
            local currentGoldLabel = self.currentGoldContainer.currencyAmount
            local codFeeLabel = self.codFeeContainer.currencyAmount
            local currentGold = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
            local canAffordCODFee = data.codAmount <= currentGold
            local confirmStringId = canAffordCODFee and SI_MAIL_CONFIRM_TAKE_ATTACHMENT_COD or SI_MAIL_COD_NOT_ENOUGH_MONEY
            local CURRENCY_OPTIONS =
            {
                showTooltips = true,
            }

            self.confirmTextLabel:SetText(GetString(confirmStringId))
            ZO_CurrencyControl_SetSimpleCurrency(currentGoldLabel, CURT_MONEY, currentGold, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL)
            ZO_CurrencyControl_SetSimpleCurrency(codFeeLabel, CURT_MONEY, data.codAmount, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, not canAffordCODFee)
        end,
        title =
        {
            text = SI_PROMPT_TITLE_MAIL_TAKE_ATTACHMENT_COD,
        },
        buttons =
        {
            [1] =
            {
                control = self:GetNamedChild("Accept"),
                text = SI_DIALOG_ACCEPT,
                enabled = function(dialog)
                    local codAmount = dialog.data.codAmount
                    return codAmount <= GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
                end,
                callback = function()
                    MAIL_INBOX:ConfirmAcceptCOD()
                end,
            },
            [2] =
            {
                control = self:GetNamedChild("Decline"),
                text = SI_DIALOG_DECLINE,
            }
        },
    })
end