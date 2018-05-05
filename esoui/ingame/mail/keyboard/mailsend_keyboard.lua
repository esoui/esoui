local MailSend = ZO_Object:New()

function MailSend:New(control)
    local manager = ZO_Object.New(self)
    MAIL_SEND = manager
    manager.control = control
    
    local editControlGroup = ZO_EditControlGroup:New()

    manager.sendMoneyMode = true
        
    manager.to = control:GetNamedChild("ToField")
    manager.autoComplete = ZO_AutoComplete:New(manager.to, { AUTO_COMPLETE_FLAG_ALL }, { AUTO_COMPLETE_FLAG_GUILD_NAMES }, AUTO_COMPLETION_ONLINE_OR_OFFLINE, MAX_AUTO_COMPLETION_RESULTS)
    editControlGroup:AddEditControl(manager.to, manager.autoComplete)
    ZO_EditDefaultText_Initialize(manager.to, GetString(SI_REQUEST_NAME_DEFAULT_TEXT))
        
    manager.subject = control:GetNamedChild("SubjectField")
    manager.subject:SetMaxInputChars(MAIL_MAX_SUBJECT_CHARACTERS)
    editControlGroup:AddEditControl(manager.subject)
    ZO_EditDefaultText_Initialize(manager.subject, GetString(SI_MAIL_SUBJECT_DEFAULT_TEXT))
        
    manager.body = control:GetNamedChild("BodyField")
    manager.body:SetMaxInputChars(MAIL_MAX_BODY_CHARACTERS)
    editControlGroup:AddEditControl(manager.body)

    manager.attachMoneyRadioButton = control:GetNamedChild("AttachRadio")
    manager.codRadioButton = control:GetNamedChild("CoDRadio")
    manager.radioButtonGroup = ZO_RadioButtonGroup:New()
    manager.radioButtonGroup:Add(manager.attachMoneyRadioButton)
    manager.radioButtonGroup:Add(manager.codRadioButton)
    manager.radioButtonGroup:SetClickedButton(manager.attachMoneyRadioButton)
        
    manager.postageCurrency = control:GetNamedChild("PostageCurrency")
    manager.sendCurrency = control:GetNamedChild("SendCurrency")
    manager.title = control:GetParent():GetNamedChild("Title")

    local function ChangeMoneyCallback(moneyInput, money)
        manager:AttachMoney(moneyInput, money)
    end
    ZO_DefaultCurrencyInputField_Initialize(manager.sendCurrency, ChangeMoneyCallback)
    ZO_DefaultCurrencyInputField_SetUsePlayerCurrencyAsMax(manager.sendCurrency, true)
        
    manager:InitializeKeybindDescriptors()
    manager:CreateAttachmentSlots()
    manager:ClearFields()

    local MoneyEvents = {
        [EVENT_MAIL_COD_CHANGED] = function() manager:UpdateCOD() end,
        [EVENT_MAIL_ATTACHED_MONEY_CHANGED] = function() manager:UpdateMoneyAttachment() end,
        [EVENT_MONEY_UPDATE] = function() manager:OnMoneyUpdate() end, 
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

    MAIL_SEND_SCENE = ZO_Scene:New("mailSend", SCENE_MANAGER)
    MAIL_SEND_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            ConnectMoneyEvents()
            KEYBIND_STRIP:AddKeybindButtonGroup(manager.staticKeybindStripDescriptor)
            ZO_MailSendShared_RestorePendingMail(manager)
        elseif(newState == SCENE_SHOWN) then
            if(manager.pendingMailChanged) then
                ZO_Dialogs_ShowDialog("MAIL_ATTACHMENTS_CHANGED")
                manager.pendingMailChanged = nil
            end        
        elseif(newState == SCENE_HIDDEN) then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(manager.staticKeybindStripDescriptor)
            ZO_MailSendShared_SavePendingMail()
            DisconnectMoneyEvents()
        end
    end)

    control:RegisterForEvent(EVENT_MAIL_SEND_SUCCESS, function() manager:OnMailSendSuccess() end)
    control:RegisterForEvent(EVENT_MAIL_ATTACHMENT_ADDED, function(_, attachSlot) manager:OnMailAttachmentAdded(attachSlot) end)
    control:RegisterForEvent(EVENT_MAIL_ATTACHMENT_REMOVED, function(_, attachSlot) manager:OnMailAttachmentRemoved(attachSlot) end)

    return manager
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
    if(self.sendMoneyMode) then
        ZO_DefaultCurrencyInputField_SetCurrencyAmount(self.sendCurrency, GetQueuedMoneyAttachment())
        self:UpdatePostageMoney()
    end
end

function MailSend:UpdateCOD()
    if(not self.sendMoneyMode) then
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
        if(sendMoneyMode) then
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
    if(subject and subject ~= "") then
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
    ZO_MailSendShared_AddAttachedItem(attachSlot, self.attachmentSlots[attachSlot])
    self:UpdatePostageMoney()
end

function MailSend:OnMailAttachmentRemoved(attachSlot)
    ZO_MailSendShared_RemoveAttachedItem(attachSlot, self.attachmentSlots[attachSlot])
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
    MAIL_SEND:SetMoneyAttachmentMode()
end

function ZO_MailSend_SetCoDMode()
    MAIL_SEND:SetCoDMode()
end

function ZO_MailSend_OnInitialized(self)
    MailSend:New(self)
end