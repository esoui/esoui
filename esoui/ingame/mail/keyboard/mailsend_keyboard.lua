local MailSend = ZO_InitializingObject:Subclass()

function MailSend:Initialize(control)
    self.control = control

    local editControlGroup = ZO_EditControlGroup:New()

    self.sendMoneyMode = true

    self.to = control:GetNamedChild("ToField")
    self.autoComplete = ZO_AutoComplete:New(self.to, { AUTO_COMPLETE_FLAG_ALL }, { AUTO_COMPLETE_FLAG_GUILD_NAMES }, AUTO_COMPLETION_ONLINE_OR_OFFLINE, MAX_AUTO_COMPLETION_RESULTS)
    editControlGroup:AddEditControl(self.to, self.autoComplete)
    ZO_EditDefaultText_Initialize(self.to, GetString(SI_REQUEST_NAME_DEFAULT_TEXT))

    self.subject = control:GetNamedChild("SubjectField")
    self.subject:SetMaxInputChars(MAIL_MAX_SUBJECT_CHARACTERS)
    editControlGroup:AddEditControl(self.subject)
    ZO_EditDefaultText_Initialize(self.subject, GetString(SI_MAIL_SUBJECT_DEFAULT_TEXT))

    self.body = control:GetNamedChild("BodyField")
    self.body:SetMaxInputChars(MAIL_MAX_BODY_CHARACTERS)
    editControlGroup:AddEditControl(self.body)

    self.attachMoneyRadioButton = control:GetNamedChild("AttachRadio")
    self.codRadioButton = control:GetNamedChild("CoDRadio")
    self.radioButtonGroup = ZO_RadioButtonGroup:New()
    self.radioButtonGroup:Add(self.attachMoneyRadioButton)
    self.radioButtonGroup:Add(self.codRadioButton)
    self.radioButtonGroup:SetClickedButton(self.attachMoneyRadioButton)

    self.postageCurrency = control:GetNamedChild("PostageCurrency")
    self.sendCurrency = control:GetNamedChild("SendCurrency")
    self.title = control:GetParent():GetNamedChild("Title")

    local function ChangeMoneyCallback(moneyInput, money)
        self:AttachMoney(moneyInput, money)
    end
    ZO_DefaultCurrencyInputField_Initialize(self.sendCurrency, ChangeMoneyCallback)
    ZO_DefaultCurrencyInputField_SetUsePlayerCurrencyAsMax(self.sendCurrency, true)

    self:InitializeKeybindDescriptors()
    self:CreateAttachmentSlots()
    self:ClearFields()

    local MoneyEvents =
    {
        [EVENT_MAIL_COD_CHANGED] = function() self:UpdateCOD() end,
        [EVENT_MAIL_ATTACHED_MONEY_CHANGED] = function() self:UpdateMoneyAttachment() end,
        [EVENT_MONEY_UPDATE] = function() self:OnMoneyUpdate() end,
    }

    local function ConnectMoneyEvents()
        for event, callback in pairs(MoneyEvents) do
            control:RegisterForEvent(event, callback)
        end
    end

    local function DisconnectMoneyEvents()
        for event in pairs(MoneyEvents) do
            control:UnregisterForEvent(event)
        end
    end

    local INVENTORY_TYPE_LIST = { INVENTORY_BACKPACK }
    MAIL_SEND_SCENE = ZO_Scene:New("mailSend", SCENE_MANAGER)
    MAIL_SEND_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            PLAYER_INVENTORY:SetContextForInventories("mailTextSearch", INVENTORY_TYPE_LIST)
            TEXT_SEARCH_MANAGER:ActivateTextSearch("mailTextSearch")
            ConnectMoneyEvents()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.staticKeybindStripDescriptor)
            ZO_MailSend_Shared.RestorePendingMail(self)
        elseif newState == SCENE_SHOWN then
            if self.pendingMailChanged then
                ZO_Dialogs_ShowDialog("MAIL_ATTACHMENTS_CHANGED")
                self.pendingMailChanged = nil
            end
        elseif newState == SCENE_HIDDEN then
            TEXT_SEARCH_MANAGER:DeactivateTextSearch("mailTextSearch")
            local REMOVE_CONTEXT = nil
            PLAYER_INVENTORY:SetContextForInventories(REMOVE_CONTEXT, INVENTORY_TYPE_LIST)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.staticKeybindStripDescriptor)
            ZO_MailSend_Shared.SavePendingMail()
            DisconnectMoneyEvents()
        end
    end)

    control:RegisterForEvent(EVENT_MAIL_SEND_SUCCESS, function() self:OnMailSendSuccess() end)
    control:RegisterForEvent(EVENT_MAIL_ATTACHMENT_ADDED, function(_, attachSlot) self:OnMailAttachmentAdded(attachSlot) end)
    control:RegisterForEvent(EVENT_MAIL_ATTACHMENT_REMOVED, function(_, attachSlot) self:OnMailAttachmentRemoved(attachSlot) end)
end

--Global API

function MailSend:ComposeMailTo(address)
    MAIN_MENU_KEYBOARD:ShowScene("mailSend")
    self:ClearFields()
    SCENE_MANAGER:CallWhen("mailSend", SCENE_SHOWN, function() self:SetReply(address) end)
end

--Internal

function MailSend:InitializeKeybindDescriptors()
    self.staticKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Clear
        {
            name = GetString(SI_MAIL_SEND_CLEAR),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                ZO_Dialogs_ShowDialog("CONFIRM_CLEAR_MAIL_COMPOSE", { callback = function() self:ClearFields() end })
            end,
        },

        -- Send
        {
            name = GetString(SI_MAIL_SEND_SEND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                self:Send()
            end,
        },
    }
end

function MailSend:CreateAttachmentSlots()
    self.attachmentSlots = {}
    local parent = GetControl(self.control, "Attachments")
    local previous

    for i = 1, MAIL_MAX_ATTACHED_ITEMS do
        local slot = CreateControlFromVirtual(parent:GetName().."Slot", parent, "ZO_MailSendAttachmentSlot", i)
        if previous then
            slot:SetAnchor(TOPLEFT, previous, TOPRIGHT, 18, 0)
        else
            slot:SetAnchor(TOPLEFT, parent, TOPLEFT, 0, 0)
        end

        slot.id = i
        slot.icon = slot:GetNamedChild("ItemIcon")

        ZO_Inventory_BindSlot(slot, SLOT_TYPE_MAIL_QUEUED_ATTACHMENT, i)
        ZO_Inventory_SetupSlot(slot, 0, ZO_MAIL_EMPTY_SLOT_TEXTURE)

        self.attachmentSlots[i] = slot

        previous = slot
    end
end

function MailSend:IsHidden()
    return MAIL_SEND_SCENE:GetState() == SCENE_HIDDEN
end

function MailSend:ClearFields()
    ClearQueuedMail()

    self.to:SetText("")
    self.subject:SetText("")
    self.body:SetText("")
    self:UpdateCOD()
    self:UpdateMoneyAttachment()
    self:UpdatePostageMoney()

    self.radioButtonGroup:SetClickedButton(self.attachMoneyRadioButton)
end

function MailSend:UpdateMoneyAttachment()
    if self.sendMoneyMode then
        ZO_DefaultCurrencyInputField_SetCurrencyAmount(self.sendCurrency, GetQueuedMoneyAttachment())
        self:UpdatePostageMoney()
    end
end

function MailSend:UpdateCOD()
    if not self.sendMoneyMode then
        ZO_DefaultCurrencyInputField_SetCurrencyAmount(self.sendCurrency, GetQueuedCOD())
    end
    self:UpdatePostageMoney()
end

function MailSend:UpdatePostageMoney()
    local postageAmount = GetQueuedMailPostage()
    ZO_CurrencyControl_SetSimpleCurrency(self.postageCurrency, CURT_MONEY, postageAmount, nil, CURRENCY_SHOW_ALL, postageAmount > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER))
end

function MailSend:SetSendMoneyMode(sendMoneyMode)
    if self.sendMoneyMode ~= sendMoneyMode then
        self.sendMoneyMode = sendMoneyMode
        ZO_DefaultCurrencyInputField_SetCurrencyAmount(self.sendCurrency, 0)
        ZO_DefaultCurrencyInputField_SetUsePlayerCurrencyAsMax(self.sendCurrency, sendMoneyMode)
        if sendMoneyMode then
            QueueMoneyAttachment(ZO_DefaultCurrencyInputField_GetCurrency(self.sendCurrency))
        else
            QueueCOD(ZO_DefaultCurrencyInputField_GetCurrency(self.sendCurrency))
        end
        self:UpdatePostageMoney()
    end
end

function MailSend:AttachMoney(moneyInput, money)
    if self.sendMoneyMode then
        QueueMoneyAttachment(money)
    else
        QueueCOD(money)
    end
end

function MailSend:Send()
    WINDOW_MANAGER:SetFocusByName("")
    if not self.sendMoneyMode and GetQueuedCOD() == 0 then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_MUST_SET_REQUIRED_MONEY_IN_COD))
    else
        SendMail(self.to:GetText(), self.subject:GetText(), self.body:GetText())
    end
end

function MailSend:SetReply(to, subject)
    self.to:SetText(to or "")
    self.body:SetText("")
    if subject and subject ~= "" then
        self.subject:SetText(zo_strformat(SI_MAIL_REPLY_SUBJECT, subject))
        self.body:TakeFocus()
    else
        self.subject:SetText("")
        self.subject:TakeFocus()
    end
end

--Events

function MailSend:OnMoneyUpdate()
    self:UpdatePostageMoney()
end

function MailSend:OnMailSendSuccess()
    PlaySound(SOUNDS.MAIL_SENT)
    self:ClearFields()
end

function MailSend:OnMailAttachmentAdded(attachSlot)
    ZO_MailSend_Shared.AddAttachedItem(attachSlot, self.attachmentSlots[attachSlot])
    self:UpdatePostageMoney()
end

function MailSend:OnMailAttachmentRemoved(attachSlot)
    ZO_MailSend_Shared.RemoveAttachedItem(attachSlot, self.attachmentSlots[attachSlot])
    self:UpdatePostageMoney()
end

--Local XML

function MailSend:SetCoDMode()
    if self.radioButtonGroup:GetClickedButton() ~= self.codRadioButton then
        self.radioButtonGroup:SetClickedButton(self.codRadioButton)
    end
    self:SetSendMoneyMode(false)
end

function MailSend:SetMoneyAttachmentMode()
    if self.radioButtonGroup:GetClickedButton() ~= self.attachMoneyRadioButton then
        self.radioButtonGroup:SetClickedButton(self.attachMoneyRadioButton)
    end

    self:SetSendMoneyMode(true)
end

--Global XML

function ZO_MailSend_SetMoneyAttachmentMode()
    if MAIL_SEND then
        MAIL_SEND:SetMoneyAttachmentMode()
    end
end

function ZO_MailSend_SetCoDMode()
    if MAIL_SEND then
        MAIL_SEND:SetCoDMode()
    end
end

function ZO_MailSend_OnInitialized(self)
    MAIL_SEND = MailSend:New(self)
end