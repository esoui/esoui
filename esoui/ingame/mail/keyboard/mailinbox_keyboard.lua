local MailInbox = ZO_SortFilterList:Subclass()

local MAX_READ_ATTACHMENTS = MAIL_MAX_ATTACHED_ITEMS + 1
local MONEY_ICON_PATH = "EsoUI/Art/Loot/Icon_GoldCoin_Pressed.dds"
local MAIL_INBOX_ROW_HEIGHT = 50

local MAIL_DATA = 1
local EMPTY_MAIL_DATA = 2

function MailInbox:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function MailInbox:Initialize(control)
    ZO_SortFilterList.Initialize(self, control)

    self.messageControl = control:GetNamedChild("Message")
    self.unreadLabel = control:GetNamedChild("UnreadLabel")
    self.fromControl = self.messageControl:GetNamedChild("From")
    self.sentMoneyControl = self.messageControl:GetNamedChild("SentMoney")
    self.codControl = self.messageControl:GetNamedChild("COD")
    self:SetAlternateRowBackgrounds(true)

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareInboxEntries(listEntry1, listEntry2) end
    self.reportedMailIds = {}

    ZO_ScrollList_AddDataType(self.list, MAIL_DATA, "ZO_MailInboxRow", MAIL_INBOX_ROW_HEIGHT, function(control, data) self:SetupInboxEntry(control, data) end, nil, SOUNDS.MAIL_ITEM_SELECTED)
    ZO_ScrollList_SetEqualityFunction(self.list, MAIL_DATA, function(data1, data2) return AreId64sEqual(data1.mailId, data2.mailId) end)   
    ZO_ScrollList_AddDataType(self.list, EMPTY_MAIL_DATA, "ZO_MailEmptyInboxRow", MAIL_INBOX_ROW_HEIGHT, function(control, data) self:SetupRow(control, data) end)
    ZO_ScrollList_SetTypeSelectable(self.list, EMPTY_MAIL_DATA, false)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
    ZO_ScrollList_EnableSelection(self.list, "ZO_ThinListHighlight", function(previouslySelected, selected, reselectingDuringRebuild) self:OnSelectionChanged(previouslySelected, selected, reselectingDuringRebuild) end)
    ZO_ScrollList_SetDeselectOnReselect(self.list, false)
    ZO_ScrollList_SetAutoSelect(self.list, true)

    MAIL_INBOX_SCENE = ZO_Scene:New("mailInbox", SCENE_MANAGER)
    MAIL_INBOX_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.selectionKeybindStripDescriptor)
            if(self.inboxDirty) then
                self:RefreshData()
            end
        elseif newState == SCENE_HIDING then
            CURRENCY_INPUT:Hide()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.selectionKeybindStripDescriptor)
        end
    end)

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

    self:SetNumUnread(GetNumUnreadMail())

    self:InitializeKeybindDescriptors()
    self:CreateAttachmentSlots()
end

function MailInbox:InitializeKeybindDescriptors()
    local function ReportAndDeleteCallback()
        self:RecordSelectedMailAsReported()
        self:Delete()
    end

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
                if(not self:HasAlreadyReportedSelectedMail()) then
                    local mailData = self:GetMailData(self.mailId)
                    if(mailData) then
                        return not (mailData.fromCS or mailData.fromSystem)
                    end
                end
            end,

            callback = function()
                if(self.mailId) then
                    local senderDisplayName = GetMailSender(self.mailId)
                    ZO_ReportPlayerDialog_Show(senderDisplayName, REPORT_PLAYER_REASON_MAIL_SPAM, nil, ReportAndDeleteCallback)
                end
            end,
        },
    }
end

function MailInbox:CreateAttachmentSlots()
    self.attachmentSlots = {}
    local parent = GetControl(self.messageControl, "Attachments")
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
    if(self.masterList) then
        for i = 1, #self.masterList do
            local data = self.masterList[i]
            if(AreId64sEqual(data.mailId, mailId)) then
                return data
            end
        end
    end
end

local READ_COLOR = ZO_ColorDef:New(0.6, 0.6, 0.6)

function MailInbox:GetRowColors(data, mouseIsOver, control)
    local textColor
    if(mouseIsOver or data == self.selectedData) then
        textColor = ZO_SELECTED_TEXT
    else
        if(data.unread) then
            textColor = ZO_SECOND_CONTRAST_TEXT
        else
            textColor = READ_COLOR
        end
    end    
    return textColor
end

function MailInbox:SetupInboxEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    GetControl(control, "Subject"):SetText(data:GetFormattedSubject())

    local iconControl = GetControl(control, "Icon")
    iconControl:ClearIcons()
    if(data.unread) then
        iconControl:AddIcon(ZO_KEYBOARD_NEW_ICON)
    end
    if(data.fromSystem) then
        iconControl:AddIcon("EsoUI/Art/Mail/mail_systemIcon.dds")
    elseif(data.fromCS) then
        iconControl:AddIcon("EsoUI/Art/Mail/mail_CSIcon.dds")
    end

    iconControl:Show()
end

function MailInbox:BuildMasterList()
    self.inboxDirty = false
    self.masterList = {}
    self.numEmptyRows = 0

    for mailId in ZO_GetNextMailIdIter do
        local mailData = {}
        ZO_MailInboxShared_PopulateMailData(mailData, mailId)
        table.insert(self.masterList, mailData)
    end

    local listHeight = self.list:GetHeight()
    local currentHeight = #self.masterList * MAIL_INBOX_ROW_HEIGHT
    if(currentHeight < listHeight) then
        self.numEmptyRows = zo_floor((listHeight - currentHeight) / MAIL_INBOX_ROW_HEIGHT)
    end

    GetControl(self.control, "Empty"):SetHidden(#self.masterList > 0)
    GetControl(self.control, "Full"):SetHidden(not IsLocalMailboxFull())
end

function MailInbox:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)
        
    for i = 1, #self.masterList do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(MAIL_DATA, self.masterList[i]))
    end

    for i = 1, self.numEmptyRows do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(EMPTY_MAIL_DATA, { priority = 3 }))
    end
end

function MailInbox:CompareInboxEntries(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, MAIL_ENTRY_FIRST_SORT_KEY, MAIL_ENTRY_SORT_KEYS, ZO_SORT_ORDER_UP)
end

function MailInbox:SortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    table.sort(scrollData, self.sortFunction)
end

function MailInbox:OnSelectionChanged(previouslySelected, selected, reselectingDuringRebuild)
    ZO_SortFilterList.OnSelectionChanged(self, previouslySelected, selected)
    if(not reselectingDuringRebuild) then
        if(selected) then
            self:RequestReadMessage(selected.mailId)
        else
            self:EndRead()
        end
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
    if(not AreId64sEqual(self.mailId, mailId)) then
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
                if ((GetCarriedCurrencyAmount(CURT_MONEY) + attachedMoney) > MAX_PLAYER_MONEY) then
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
    ZO_ScrollList_RefreshVisible(self.list, mailData)

    ZO_MailInboxShared_UpdateInbox(mailData, self.fromControl, GetControl(self.messageControl, "Subject"), GetControl(self.messageControl, "Expires"), GetControl(self.messageControl, "Received"), GetControl(self.messageControl, "Body"))
    self:RefreshMailFrom()
    ZO_Scroll_ResetToTop(GetControl(self.messageControl, "Pane"))

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
        ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.sentMoneyControl, "Currency"), CURT_MONEY, mailData.attachedMoney, MAIL_COD_ATTACHED_MONEY_OPTIONS)
    elseif(mailData.codAmount > 0) then
        self.codControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.codControl, "Currency"), CURT_MONEY, mailData.codAmount, MAIL_COD_ATTACHED_MONEY_OPTIONS)
    end
end

function MailInbox:RefreshAttachmentsHeaderShown()
    local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)
    local noAttachments = numAttachments == 0 and attachedMoney == 0
    GetControl(self.messageControl, "AttachmentsHeader"):SetHidden(noAttachments)
    GetControl(self.messageControl, "AttachmentsDivider"):SetHidden(noAttachments)
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
    self:EnterRow(control)
end

function MailInbox:Row_OnMouseExit(control)
    self:ExitRow(control)
end

function MailInbox:Row_OnMouseUp(control)
    self:SelectRow(control)
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

function ZO_MailInboxRow_OnMouseEnter(control)
    MAIL_INBOX:Row_OnMouseEnter(control)
end

function ZO_MailInboxRow_OnMouseExit(control)
    MAIL_INBOX:Row_OnMouseExit(control)
end

function ZO_MailInboxRow_OnMouseUp(control)
    MAIL_INBOX:Row_OnMouseUp(control)
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