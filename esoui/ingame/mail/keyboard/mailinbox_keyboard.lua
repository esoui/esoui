local MailInbox = ZO_InitializingObject:Subclass()

local MAX_READ_ATTACHMENTS = MAIL_MAX_ATTACHED_ITEMS + 1
ZO_MAIL_INBOX_KEYBOARD_TREE_WIDTH = 386
ZO_MAIL_INBOX_KEYBOARD_NODE_WIDTH = ZO_MAIL_INBOX_KEYBOARD_TREE_WIDTH - ZO_SCROLL_BAR_WIDTH
local TREE_CHILD_INDENT = 33
ZO_MAIL_INBOX_KEYBOARD_NODE_INDENTED_WIDTH = ZO_MAIL_INBOX_KEYBOARD_NODE_WIDTH - TREE_CHILD_INDENT
ZO_MAIL_INBOX_KEYBOARD_NODE_HEIGHT = 50

local ICON_MAIL_EXPIRING = "EsoUI/Art/Miscellaneous/timerRed_32.dds"
local ICON_CATEGORY_FULL = "EsoUI/Art/Mail/mail_category_full.dds"

function MailInbox:Initialize(control)
    self.control = control

    MAIL_INBOX_SCENE = ZO_Scene:New("mailInbox", SCENE_MANAGER)
    MAIL_INBOX_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.selectionKeybindStripDescriptor)
            if self.inboxDirty then
                self:RefreshData()
            end

            if self.attachmentsDirty then
                if self.mailId then
                    self:RefreshAttachmentSlots()
                    self:RefreshAttachmentsHeaderShown()
                    self:RefreshMoneyControls()
                end
                self.attachmentsDirty = false
            end

            ZO_CheckButton_SetCheckState(self.deleteOnClaimCheckButton, MAIL_MANAGER:ShouldDeleteOnClaim())
        elseif newState == SCENE_HIDING then
            CURRENCY_INPUT:Hide()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.selectionKeybindStripDescriptor)
        end
    end)
    
    self.masterList = {}
    self.reportedMailIds = {}
    self.categoryNodeData =
    {
        [MAIL_CATEGORY_PLAYER_MAIL] =
        {
            text = GetString("SI_MAILCATEGORY", MAIL_CATEGORY_PLAYER_MAIL),
            unreadData = {},
        },
        [MAIL_CATEGORY_SYSTEM_MAIL] =
        {
            text = GetString("SI_MAILCATEGORY", MAIL_CATEGORY_SYSTEM_MAIL),
            unreadData = {},
        },
        [MAIL_CATEGORY_INFO_ONLY_SYSTEM_MAIL] =
        {
            text = GetString("SI_MAILCATEGORY", MAIL_CATEGORY_INFO_ONLY_SYSTEM_MAIL),
            unreadData = {},
        },
    }

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
    self.minNumBackgroundControls = zo_ceil(self.navigationContainer:GetHeight() / ZO_MAIL_INBOX_KEYBOARD_NODE_HEIGHT / 2)
    self.loadingIcon = control:GetNamedChild("LoadingIcon")
    self.inventoryUsage = control:GetNamedChild("InventoryUsage")

    --Set up the delete on claim checkbox
    self.deleteOnClaimCheckButton = control:GetNamedChild("DeleteOnClaim")
    ZO_CheckButton_SetLabelText(self.deleteOnClaimCheckButton, GetString(SI_MAIL_INBOX_DELETE_AFTER_CLAIM))

    local function OnDeleteOnClaimChanged()
        MAIL_MANAGER:SetDeleteOnClaim(ZO_CheckButton_IsChecked(self.deleteOnClaimCheckButton))
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)
    end
    ZO_CheckButton_SetToggleFunction(self.deleteOnClaimCheckButton, OnDeleteOnClaimChanged)

    self:SetNumUnread(GetNumUnreadMail())
end

function MailInbox:InitializeList()
    local navigationTree = ZO_Tree:New(self.navigationContainer:GetNamedChild("ScrollChild"), 0, 0, ZO_MAIL_INBOX_KEYBOARD_NODE_WIDTH)

    local function UpdateSize(control)
        control:SetDimensions(ZO_MAIL_INBOX_KEYBOARD_NODE_WIDTH, ZO_MAIL_INBOX_KEYBOARD_NODE_HEIGHT)
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
        
        if headerData.hasExpiringChildren then
            control.statusIcon:AddIcon(ICON_MAIL_EXPIRING)
        end

        if headerData.isFull then
            control.statusIcon:AddIcon(ICON_CATEGORY_FULL)
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

        local subjectColor
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

        if mailData.firstItemIcon ~= ZO_NO_TEXTURE_FILE then
            iconTexture:AddIcon(mailData.firstItemIcon)
        end

        --Only show the system mail icon for system mail in the "System Alerts" category
        if mailData.fromSystem and mailData.category == MAIL_CATEGORY_INFO_ONLY_SYSTEM_MAIL then
            iconTexture:AddIcon("EsoUI/Art/Mail/mail_systemIcon.dds")
        elseif mailData.fromCS then
            iconTexture:AddIcon("EsoUI/Art/Mail/mail_CSIcon.dds")
        end

        if mailData:IsExpirationImminent() then
            iconTexture:AddIcon(ICON_MAIL_EXPIRING)
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
    control:RegisterForEvent(EVENT_MAIL_TAKE_ALL_ATTACHMENTS_IN_CATEGORY_RESPONSE, function(_, ...) self:OnTakeAllComplete(...) end)
    control:RegisterForEvent(EVENT_MAIL_OPEN_MAILBOX, function()
        -- It's possible that the mail that's selected was selected after we closed the mail interaction (for example, deleting the current mail and
        -- rapidly closing the window). In that case we never sent a message to the server to get the mail contents so the details pane is empty.
        -- If we show the window again and the request hasn't be responsed to then self.requestedMailId will still be set so we know we have to query
        -- again now that the interaction is open again. We wait till shown for the interaction to be open.
        if self.pendingRequestMailId then
            self:RequestReadMessage(self.pendingRequestMailId)
        end

        -- These will get reset when RefreshData() is called, since we exit this "loading state" when RefreshData is called
        self.loadingIcon:Show()
        self.unreadLabel:SetHidden(true)
        self.navigationContainer:SetHidden(true)
        self.messageControl:SetHidden(true)
    end)

    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(bagId, slotIndex) self:RefreshInventory() end)
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function(bagId, slotIndex) self:RefreshInventory() end)
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
                if self.mailId then
                    return IsMailReturnable(self.mailId)
                end
                return false
            end
        },

        --Reply
        {
            name = GetString(SI_MAIL_READ_REPLY),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                self:Reply()
            end,

            visible = function()
                if self.mailId then
                    local mailData = self:GetMailData(self.mailId)
                    return mailData and mailData.isFromPlayer or false
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
                if self.mailId then
                    return not IsMailReturnable(self.mailId)
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
                if self.mailId then
                    local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)
                    if numAttachments > 0 or attachedMoney > 0 then
                        return true
                    end
                end
                return false
            end
        },

        --Take All
        {
            name = function()
                if self.mailId then
                    local mailData = self:GetMailData(self.mailId)
                    return GetString("SI_MAILCATEGORY_TAKEALL", mailData.category)
                end
            end,
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                if self.mailId then
                    local mailData = self:GetMailData(self.mailId)
                    ZO_Dialogs_ShowPlatformDialog("MAIL_CONFIRM_TAKE_ALL", { category = mailData.category })
                end
            end,
            visible = function()
                if self.mailId then
                    local mailData = self:GetMailData(self.mailId)
                    if mailData then
                        local canTakeAttachments = CanTryTakeAllMailAttachmentsInCategory(mailData.category, MAIL_MANAGER:ShouldDeleteOnClaim())
                        return canTakeAttachments
                    end
                end
                return false
            end,
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
                if self.mailId then
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

function MailInbox:GetCategoryNodeData(category)
    return self.categoryNodeData[category]
end

function MailInbox:RefreshData()
    if not SCENE_MANAGER:IsShowing("mailInbox") then
        self.inboxDirty = true
        return
    end

    -- Initialize and clear
    self.inboxDirty = false
    self.loadingIcon:Hide()
    self.unreadLabel:SetHidden(false)
    local tree = self.navigationTree
    tree:Reset()
    self.nodeBGControlPool:ReleaseAllObjects()

    local masterList = self.masterList
    ZO_ClearNumericallyIndexedTable(masterList)

    local currentReadMailData = nil
    local numTotalNodes = 0
    local autoSelectNode = nil
    local fullCategoryText

    for category = MAIL_CATEGORY_ITERATION_BEGIN, MAIL_CATEGORY_ITERATION_END do
        local categoryNodeData = self:GetCategoryNodeData(category)
        ZO_ClearTable(categoryNodeData.unreadData)

        local hasExpiringChildren = false
        local numMailItems = GetNumMailItemsByCategory(category)
        local mailList = {}

        for index = 1, numMailItems do
            local mailId = GetMailIdByIndex(category, index)
            local mailData = {}
            ZO_MailInboxShared_PopulateMailData(mailData, mailId)
            if self.mailId and not currentReadMailData and AreId64sEqual(self.mailId, mailId) then
                currentReadMailData = mailData
            end

            table.insert(masterList, mailData)
            table.insert(mailList, mailData)

            if mailData.unread then
                categoryNodeData.unreadData[mailData] = true
            end

            if mailData:IsExpirationImminent() then
                if mailData.numAttachments > 0 or mailData.attachedMoney > 0 then
                    hasExpiringChildren = true
                end
            end
        end

        -- Number of mails (or "empty" node if none), plus header node
        local numNodes = zo_max(numMailItems, 1) + 1
        numTotalNodes = numTotalNodes + numNodes
        categoryNodeData.hasExpiringChildren = hasExpiringChildren
        local isCategoryFull = IsLocalMailboxFull(category)
        categoryNodeData.isFull = isCategoryFull

        if numMailItems > 0 then
            categoryNodeData.text = zo_strformat(SI_MAIL_CATEGORY_COUNT_HEADER, GetString("SI_MAILCATEGORY", category), numMailItems)
        else
            categoryNodeData.text = GetString("SI_MAILCATEGORY", category)
        end
        local categoryNode = tree:AddNode("ZO_MailInboxHeader", categoryNodeData)

        if numMailItems > 0 then
            for index, mailData in ipairs(mailList) do
                mailData.node = tree:AddNode("ZO_MailInboxRow", mailData, categoryNode)
                if not autoSelectNode then
                    if self.selectMailIdOnRefresh then
                        if AreId64sEqual(mailData.mailId, self.selectMailIdOnRefresh) then
                            autoSelectNode = mailData.node
                        end
                    elseif category == self.selectCategoryOnRefresh then
                        autoSelectNode = mailData.node
                    elseif category == MAIL_CATEGORY_SYSTEM_MAIL and self.isFirstTimeOpening then
                        -- Select the first node of the system list if opening for the first time and nothing else is auto selecting
                        autoSelectNode = mailData.node
                    end
                end
            end
        else
            tree:AddNode("ZO_MailInboxEmptyRow", { text = GetString("SI_MAILCATEGORY_EMPTYTEXT", category) }, categoryNode)
        end

        if isCategoryFull then
            --If fullCategoryText has already been set, that means multiple categories are full
            if fullCategoryText ~= nil then
                fullCategoryText = GetString(SI_MAIL_INBOX_CATEGORIES_FULL)
            else
                fullCategoryText = zo_strformat(SI_MAIL_INBOX_CATEGORY_FULL, GetString("SI_MAILCATEGORY", category))
            end
        end
    end

    local numBGControlsToAdd = zo_max(zo_ceil(numTotalNodes / 2), self.minNumBackgroundControls)
    local previousBGControl = nil
    for i = 1, numBGControlsToAdd do
        local bgControl = self.nodeBGControlPool:AcquireObject()
        if previousBGControl then
            bgControl:SetAnchor(TOPLEFT, previousBGControl, BOTTOMLEFT, 0, ZO_MAIL_INBOX_KEYBOARD_NODE_HEIGHT)
        else
            bgControl:SetAnchor(TOPLEFT)
        end
        previousBGControl = bgControl
    end

    self.isFirstTimeOpening = false
    self.selectMailIdOnRefresh = nil
    self.selectCategoryOnRefresh = nil

    local DONT_BRING_PARENT_INTO_VIEW = false
    tree:Commit(autoSelectNode, DONT_BRING_PARENT_INTO_VIEW)

    -- ESO-714031: Edge case where the mail you had been reading when the menu closed may be gone due to expiration when you come back
    -- But the system doesn't end and re-read mail you were already reading when continually opening and closing the menu, for effeciency
    if self.mailId and not currentReadMailData then
        self:EndRead()
    end

    self.navigationContainer:SetHidden(false)
    self.messageControl:SetHidden(self.mailId == nil)
    if fullCategoryText ~= nil then
        self.fullLabel:SetText(fullCategoryText)
        self.fullLabel:SetHidden(false)
    elseif HasUnreceivedMail() then
        self.fullLabel:SetText(GetString(SI_MAIL_INBOX_UNDELIVERED))
        self.fullLabel:SetHidden(false)
    else
        self.fullLabel:SetHidden(true)
    end
    self:RefreshInventory()
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

function MailInbox:Reply()
    if self.mailId then
        local mailData = self:GetMailData(self.mailId)
        if mailData and mailData.isFromPlayer then
            MAIN_MENU_KEYBOARD:ShowSceneGroup("mailSceneGroup", "mailSend")

            MAIL_SEND:ComposeMailTo(mailData.senderDisplayName, mailData:GetFormattedReplySubject())
        end
    end
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
        local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)
        if numAttachments > 0 or attachedMoney > 0 then
            DeleteMail(self.mailId)
        else
            ZO_Dialogs_ShowPlatformDialog(
                "DELETE_MAIL", 
                {
                    confirmationCallback = function(...) 
                        DeleteMail(self.mailId) 
                        PlaySound(SOUNDS.MAIL_ITEM_DELETED) 
                    end, 
                    mailId = self.mailId,
                }
            )
        end
    end
end

function MailInbox:TryTakeAll()
    if self.mailId then
        local mailId = self.mailId
        local _, attachedMoney, codAmount = GetMailAttachmentInfo(mailId)
        
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

--Events

function MailInbox:OnInboxUpdate()
    if SCENE_MANAGER:IsShowing("mailInbox") then
        self:RefreshData()
        self:RefreshMailFrom()
        self:RefreshInventory()
    else
        self.inboxDirty = true
    end
end

local MAIL_COD_ATTACHED_MONEY_OPTIONS =
{
    showTooltips = true,
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
        local icon, stack = GetAttachedItemInfo(self.mailId, i)
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
    if mailData.attachedMoney > 0 then
        self.sentMoneyControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(self.sentMoneyCurrencyControl, CURT_MONEY, mailData.attachedMoney, MAIL_COD_ATTACHED_MONEY_OPTIONS)
    elseif mailData.codAmount > 0 then
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

function MailInbox:RefreshInventory()
    if SCENE_MANAGER:IsShowing("mailInbox") then
        local numUsedSlots, numSlots = PLAYER_INVENTORY:GetNumSlots(INVENTORY_BACKPACK)
        if numUsedSlots < numSlots then
            self.inventoryUsage:SetText(zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots))
        else
            self.inventoryUsage:SetText(zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots))
        end
    end
end

function MailInbox:OnTakeAttachedItemSuccess(mailId)
    if AreId64sEqual(self.mailId, mailId) then
        ZO_MailInboxShared_PopulateMailData(self:GetMailData(self.mailId), mailId)
        self:RefreshAttachmentSlots()
        self:RefreshAttachmentsHeaderShown()
        self:RefreshMoneyControls()
        local NOT_USER_REQUESTED = false
        self.navigationTree:RefreshVisible(NOT_USER_REQUESTED)
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

function MailInbox:OnTakeAllComplete(result, category, headersRemoved)
    if result == MAIL_TAKE_ATTACHMENT_RESULT_SUCCESS then
        if headersRemoved then
            --If headers were removed, we cannot guarantee that the current selection still exists, so select the top entry of the category
            self.selectCategoryOnRefresh = category
            self:RefreshData()
        else
            --If no headers were removed, maintain the current selection
            self.selectMailIdOnRefresh = self.mailId
            self:RefreshData()
            if SCENE_MANAGER:IsShowing("mailInbox") then
                self:RefreshAttachmentSlots()
                self:RefreshAttachmentsHeaderShown()
                self:RefreshMoneyControls()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)
            else
                self.attachmentsDirty = true
            end
        end
    end
end

function MailInbox:OnMailNumUnreadChanged(numUnread)
    self:SetNumUnread(numUnread)
end

function MailInbox:HasAlreadyReportedSelectedMail()
    return self.reportedMailIds[zo_getSafeId64Key(self.mailId)]
end

function MailInbox:RecordSelectedMailAsReported()
    if self.mailId then
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
    if numUnreadMail == 0 then
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