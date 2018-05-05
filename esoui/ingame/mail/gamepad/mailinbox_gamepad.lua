-- Some configuration options.
local MAX_READ_ATTACHMENTS = MAIL_MAX_ATTACHED_ITEMS + 1

local SYSTEM_MAIL_ICON = "EsoUI/Art/Mail/Gamepad/gp_mailMenu_mailType_system.dds"
local CUSTOMERSERVICE_MAIL_ICON = "EsoUI/Art/Mail/Gamepad/gp_mailMenu_mailType_CS.dds"

local EMPTY_ATTACHMENT_ICON = nil

local ZO_GAME_REPRESENTATIVE_TEXT_UNSELECTED = ZO_GAME_REPRESENTATIVE_TEXT:Lerp(ZO_DISABLED_TEXT, 0.5)

local function IsMailSystem(mailData)
    return mailData and (mailData.fromCS or mailData.fromSystem)
end

local function IsMailReportable(mailData)
    return mailData and (not IsMailSystem(mailData))
end

local function GetEntryColors(mailData)
    local hasCOD = (mailData.codAmount > 0)
    local hasEnoughMoney = (mailData.codAmount <= GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER))
    if not hasEnoughMoney then
        return ZO_MAIL_COD_MONEY_INSUFFICIENT_COLOR_GAMEPAD, ZO_MAIL_COD_MONEY_INSUFFICIENT_COLOR_GAMEPAD
    end

    if hasCOD then
        return ZO_MAIL_COD_MONEY_COLOR_GAMEPAD, ZO_MAIL_COD_MONEY_COLOR_UNSELECTED_GAMEPAD
    end

    local isSystem = IsMailSystem(mailData)
    if isSystem then
        return ZO_GAME_REPRESENTATIVE_TEXT, ZO_GAME_REPRESENTATIVE_TEXT_UNSELECTED
    end

    return ZO_SELECTED_TEXT, ZO_DISABLED_TEXT
end

-- The main class.
ZO_MailInbox_Gamepad = ZO_Object:Subclass()

function ZO_MailInbox_Gamepad:New(...)
    local mailInbox = ZO_Object.New(self)
    mailInbox:InitializeInbox(...)
    return mailInbox
end

function ZO_MailInbox_Gamepad:InitializeInbox(control)
    self.control = control
    self.mailDataById = {}
    self.dirty = true
    self.dirtyMail = nil
    self:InitializeFragment()
end

function ZO_MailInbox_Gamepad:OnShowing()
    self:PerformDeferredInitialization()

    if self.isLoading then
        self:EnterLoading()
    else
        self:EnterMailList()
    end

    if self.dirty then
        self:RefreshMailList()
    end
    if self.dirtyMail then
        self:ShowMailItem(self.dirtyMail)
    end
end

function ZO_MailInbox_Gamepad:OnShown()
    if IsLocalMailboxFull() then
        TriggerTutorial(TUTORIAL_TRIGGER_MAIL_OPENED_AND_FULL)
    end
end

function ZO_MailInbox_Gamepad:OnHidden()
    self:HideAll()
end

function ZO_MailInbox_Gamepad:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    self:InitializeControls()
    self:InitializeHeader()
    self:InitializeMailList()
    self:InitializeOptionsList()
    self:InitializeAttachmentsList()
    self:InitializeKeybindDescriptors()

    self:InitializeEvents()
end

function ZO_MailInbox_Gamepad:InitializeFragment()
    GAMEPAD_MAIL_INBOX_FRAGMENT = ZO_FadeSceneFragment:New(ZO_MailManager_GamepadInbox)
    GAMEPAD_MAIL_INBOX_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_MailInbox_Gamepad:InitializeControls()
    self.inboxControl = self.control:GetNamedChild("Inbox")

    -- Loading
    self.loadingBox = self.control:GetNamedChild("Loading")
    self.loadingLabel = self.loadingBox:GetNamedChild("ContainerText")

    -- Mail Display
    self.inbox = self.inboxControl:GetNamedChild("RightPane"):GetNamedChild("Container"):GetNamedChild("Inbox")
    local IS_OUTBOX = false
    self.inbox:Initialize(GetString(SI_GAMEPAD_MAIL_INBOX_FROM), EMPTY_ATTACHMENT_ICON, IS_OUTBOX, ZO_MAIL_COD_MONEY_OPTIONS_GAMEPAD, ZO_MAIL_ATTACHED_MONEY_OPTIONS_GAMEPAD, MAX_READ_ATTACHMENTS)
end

function ZO_MailInbox_Gamepad:AttachmentSelectionChanged(list, selectedData, oldSelectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if selectedData then
        local EQUIPPED = false
        GAMEPAD_TOOLTIPS:LayoutItem(GAMEPAD_LEFT_TOOLTIP, selectedData.itemLink, EQUIPPED, selectedData.creator)
    end
end

local function SetupAttachmentsList(attachmentsList)
    attachmentsList:AddDataTemplate("ZO_GamepadMenuEntryTemplateLowercase34", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_MailInbox_Gamepad:InitializeAttachmentsList()
    self.attachmentsList = MAIL_MANAGER_GAMEPAD:AddList("Attachments", SetupAttachmentsList)
    self.attachmentsListControl = self.attachmentsList:GetControl()

    self.attachmentsList:SetOnSelectedDataChangedCallback(function(...) self:AttachmentSelectionChanged(...) end)
end

function ZO_MailInbox_Gamepad:InitializeOptionsList()
    self.optionsList = MAIL_MANAGER_GAMEPAD:AddList("Options")
    self.optionsListControl = self.optionsList:GetControl()
    
    if IsConsoleUI() then
        local gamercardOption = ZO_GamepadEntryData:New(GetString(GetGamerCardStringId()))
        gamercardOption.selectedCallback =  function()
                                                local mailData = self:GetActiveMailData()
                                                if not mailData.fromSystem then
                                                    ZO_ShowGamerCardFromDisplayNameOrFallback(mailData.senderDisplayName, ZO_ID_REQUEST_TYPE_MAIL_ID, mailData.mailId)
                                                end
                                            end
        self.optionsList:AddEntry("ZO_GamepadMenuEntryTemplate", gamercardOption)
    end

    local returnToSenderOption = ZO_GamepadEntryData:New(GetString(SI_MAIL_READ_RETURN))
    returnToSenderOption.selectedCallback = function()
                                                if not IsMailReturnable(self:GetActiveMailId()) then
                                                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GAMEPAD_MAIL_INBOX_CANNOT_RETURN))
                                                else
                                                    ZO_Dialogs_ShowGamepadDialog("MAIL_RETURN_ATTACHMENTS", { callback = function() self:ReturnToSender() end, finishedCallback = function() self:ExitReturnDialog() end }, {mainTextParams = {self:GetActiveMailSender()}})
                                                end
                                            end
    returnToSenderOption.selectedNameColor = function() return IsMailReturnable(self:GetActiveMailId()) and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT end
    self.optionsList:AddEntry("ZO_GamepadMenuEntryTemplate", returnToSenderOption)

    --Customer service options are not currently available for PC Gamepad
    if IsConsoleUI() then
        local reportOption = ZO_GamepadEntryData:New(GetString(SI_MAIL_READ_REPORT_PLAYER))
        reportOption.selectedCallback = function() 
                                            self:ReportPlayer()
                                        end
        reportOption.selectedNameColor = function() return IsMailReportable(self:GetActiveMailData()) and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT end
        self.optionsList:AddEntry("ZO_GamepadMenuEntryTemplate", reportOption)
    end

    self.optionsList:Commit()
end

local function SetupList(list)
    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplate("ZO_GamepadMenuEntryNoCapitalization", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_MailInbox_Gamepad:InitializeMailList()
    self.mailList = MAIL_MANAGER_GAMEPAD:AddList("Mail", SetupList)
    self.mailListControl = self.mailList:GetControl()
    
    self.mailList:SetOnTargetDataChangedCallback(function(...) self:OnMailTargetChanged(...) end)
    self.mailList:SetNoItemText(GetString(SI_GAMEPAD_MAIL_INBOX_EMPTY))
end

local function GetInventoryString()
    return zo_strformat(SI_GAMEPAD_MAIL_INBOX_INVENTORY_SPACES, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
end

local function UpdatePlayerGold(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_MAIL_HEADER_MONEY_OPTIONS_GAMEPAD)
    return true
end

function ZO_MailInbox_Gamepad:InitializeHeader()
    self.mainHeaderData = {
        data1HeaderText = GetString(SI_GAMEPAD_MAIL_INBOX_PLAYER_GOLD),
        data1Text = UpdatePlayerGold,

        data2HeaderText = GetString(SI_GAMEPAD_MAIL_INBOX_INVENTORY),
        data2Text = GetInventoryString,

        tabBarEntries = MAIL_MANAGER_GAMEPAD.tabBarEntries,
    }

    local function UpdateCODAmount(control)
        local mailData = self:GetActiveMailData()
        if mailData then
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, mailData.codAmount, ZO_MAIL_HEADER_MONEY_OPTIONS_GAMEPAD)
        end
        return true
    end

    self.confirmCODDialogData = {
        data1 = {
            header = GetString(SI_GAMEPAD_MAIL_INBOX_PLAYER_GOLD),
            value = UpdatePlayerGold,
        },
        data2 = {
            header = GetString(SI_MAIL_READ_COD_LABEL),
            value = UpdateCODAmount,
        },
        callback = function() self:TakeAll() end,
    }
end

function ZO_MailInbox_Gamepad:InitializeKeybindDescriptors()
    local function IsReadInfoReady()
        local mailData = self:GetActiveMailData()
        return mailData and mailData.isReadInfoReady
    end
    local function CanTakeAttachments()
        local mailData = self:GetActiveMailData()
        local hasEnoughCOD = mailData and mailData.codAmount <= GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)

        return IsReadInfoReady() and (self:GetActiveMailHasAttachedItems() or self:GetActiveMailHasAttachedGold()) and hasEnoughCOD
    end
    local takeAttachmentsBind = {
            name = GetString(SI_MAIL_READ_ATTACHMENTS_TAKE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback =  function()
                            if CanTakeAttachments() then
                                self:TryTakeAll()
                            end
                        end,
            visible = CanTakeAttachments,
        }

    local backToMailListBind = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:EnterMailList() end)
    local backToOptionsBind = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:EnterOptionsList() end)

    -- Loading.
    self.loadingKeybindDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }

    -- Main list.
    local function CanViewAttachments()
        return IsReadInfoReady() and self:GetActiveMailHasAttachedItems()
    end
    self.mainKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),

        -- Take Attachments
        takeAttachmentsBind,

        -- Delete
        {
            name = GetString(SI_MAIL_READ_DELETE),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                            ZO_Dialogs_ShowGamepadDialog("DELETE_MAIL", { callback = function() self:Delete() end })
                        end,
            visible = function() return self:CanDeleteActiveMail() end,
        },

        -- Options
        {
            name = GetString(SI_GAMEPAD_MAIL_INBOX_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                            local mailData = self:GetActiveMailData()
                            -- Options only has "Report" and "Return to Sender", neither of which is valid on system messages.
                            return mailData and (not IsMailSystem(mailData))
                      end,
            callback = function() self:EnterOptionsList() end,
        },

        -- View Attachments
        {
            name = GetString(SI_GAMEPAD_MAIL_INBOX_VIEW_ATTACHMENTS),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            visible = CanViewAttachments,
            callback = function()
                            if CanViewAttachments() then
                                self:EnterViewAttachments()
                            end
                        end,
        },
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.mainKeybindDescriptor, self.mailList)

    -- Options List
    self.optionsKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function() self.optionsList:GetTargetData().selectedCallback() end,
        },

        -- Cancel
        backToMailListBind,
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.optionsKeybindDescriptor, self.optionsList)
    
    -- View Attachments
    self.viewAttachmentsKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        backToMailListBind,
        takeAttachmentsBind,
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.viewAttachmentsKeybindDescriptor, self.attachmentsList)
end

function ZO_MailInbox_Gamepad:InitializeEvents()

    local function OnMailReadable(_, mailId)
        if not self.inboxControl:IsControlHidden() then
            self:ShowMailItem(mailId)
            MAIL_MANAGER_GAMEPAD:RefreshKeybind()
        end
    end
    
    local function TakeAttachment(_, mailId)
        self:ShowMailItem(mailId)
        MAIL_MANAGER_GAMEPAD:RefreshKeybind()
        MAIL_MANAGER_GAMEPAD:RefreshHeader()
    end

    local function OnMoneyUpdated()
        local mailId = self:GetActiveMailId()
        if mailId then
            self:ShowMailItem(mailId)
        end
        self:UpdateMailColors()
        self.mailList:RefreshVisible()
        MAIL_MANAGER_GAMEPAD:RefreshHeader()
    end

    local function OnMailRemoved(evt, mailId)
        MAIL_MANAGER_GAMEPAD:RefreshHeader()
        self:RefreshMailList()
    end

    self.control:RegisterForEvent(EVENT_MAIL_INBOX_UPDATE, function() self:MailboxUpdated() end)
    self.control:RegisterForEvent(EVENT_MAIL_READABLE, OnMailReadable)
    self.control:RegisterForEvent(EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, TakeAttachment)
    self.control:RegisterForEvent(EVENT_MAIL_TAKE_ATTACHED_MONEY_SUCCESS, TakeAttachment)
    self.control:RegisterForEvent(EVENT_MAIL_REMOVED, OnMailRemoved)
    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnMoneyUpdated)
    self.control:RegisterForEvent(EVENT_MAIL_NUM_UNREAD_CHANGED, function(...) MAIL_MANAGER_GAMEPAD:RefreshHeader() end)
end

function ZO_MailInbox_Gamepad:MailboxUpdated()
    if self.isLoading then
        self.isLoading = false
        
        if not self.inboxControl:IsHidden() then
            self:EnterMailList()
        end
    end

    self:RefreshMailList()
end

function ZO_MailInbox_Gamepad:HideAll()
    if not self.attachmentsListControl:IsHidden() then
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    end

    GAMEPAD_TOOLTIPS:HideBg(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    self.loadingBox:SetHidden(true)

    MAIL_MANAGER_GAMEPAD:DisableCurrentList()

    MAIL_MANAGER_GAMEPAD:SwitchToHeader(self.mainHeaderData)
end

function ZO_MailInbox_Gamepad:Delete()
    local mailId = self:GetActiveMailId()
    if mailId then
        DeleteMail(mailId, true)
        PlaySound(SOUNDS.MAIL_ITEM_DELETED)
    end

    self:EnterMailList()
end

function ZO_MailInbox_Gamepad:EnterLoading()
    self:HideAll()

    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.loadingKeybindDescriptor)
    self.loadingLabel:SetText(GetString(SI_GAMEPAD_MAIL_INBOX_LOADING))
    self.loadingBox:SetHidden(false)
end

function ZO_MailInbox_Gamepad:EnterMailList()
    self:HideAll()

    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.mainKeybindDescriptor)
    MAIL_MANAGER_GAMEPAD:SetCurrentList(self.mailList)
end

function ZO_MailInbox_Gamepad:EnterOptionsList()
    self:HideAll()

    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.optionsKeybindDescriptor)
    MAIL_MANAGER_GAMEPAD:SwitchToHeader(nil)
    MAIL_MANAGER_GAMEPAD:SetCurrentList(self.optionsList)
    self.optionsList:RefreshVisible()

    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_MailInbox_Gamepad:EnterViewAttachments()
    -- Populate the list.
    self.attachmentsList:Clear()
    local mailData = self:GetActiveMailData()
    if mailData then
        local mailId = mailData.mailId
        for i = 1, mailData.numAttachments do
            local itemLink = GetAttachedItemLink(mailId, i, LINK_STYLE_DEFAULT)
            local itemName = GetItemLinkName(itemLink)
            local icon, stack, creator, sellPrice, meetsUsageRequirement, equipType, itemStyle, quality = GetAttachedItemInfo(mailId, i)

            itemName = zo_strformat(SI_LINK_FORMAT_ITEM_NAME, itemName)

            local itemData = {
                        text = itemName,
                        icon = icon,
                        quality = quality,
                        stackCount = stack,
                        sellPrice = sellPrice,
                        meetsUsageRequirement = meetsUsageRequirement,
                        equipType = equipType,
                        itemStyle = itemStyle,
                        creator = creator,
                        itemLink = itemLink,
                    }

            local attachmentEntry = ZO_GamepadEntryData:New(itemName)
            attachmentEntry:InitializeInventoryVisualData(itemData)
            self.attachmentsList:AddEntry("ZO_GamepadMenuEntryTemplateLowercase34", attachmentEntry)
        end
    end
    self.attachmentsList:Commit()

    -- Swap controls and keybinds.
    self:HideAll()
    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.viewAttachmentsKeybindDescriptor)
    MAIL_MANAGER_GAMEPAD:SwitchToHeader(nil)
    GAMEPAD_TOOLTIPS:SetBgType(GAMEPAD_LEFT_TOOLTIP, GAMEPAD_TOOLTIP_DARK_BG)
    GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_LEFT_TOOLTIP)
    MAIL_MANAGER_GAMEPAD:SetCurrentList(self.attachmentsList)
    self:AttachmentSelectionChanged(self.attachmentsList, self.attachmentsList:GetTargetData(), nil)

    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_MailInbox_Gamepad:GetActiveMailId()
    local selectedData = self.mailList:GetTargetData()
    if selectedData then
        return selectedData.mailId
    end
    return nil
end

function ZO_MailInbox_Gamepad:GetActiveMailData()
    local mailId = self:GetActiveMailId()
    if mailId then
        return self.mailDataById[zo_getSafeId64Key(mailId)]
    end
    return nil
end

function ZO_MailInbox_Gamepad:GetActiveMailSender()
    local mailData = self:GetActiveMailData()
    if mailData then
        return ZO_FormatUserFacingDisplayName(mailData.senderDisplayName)
    end
    return nil
end

function ZO_MailInbox_Gamepad:ReportPlayer()
    if IsMailReportable(self:GetActiveMailData()) then
        local displayName = self:GetActiveMailSender()
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(displayName, function() ZO_PlatformIgnorePlayer(displayName) end)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GAMEPAD_MAIL_INBOX_CANNOT_REPORT))
    end
end

function ZO_MailInbox_Gamepad:ReturnToSender()
    local mailId = self:GetActiveMailId()

    if mailId then
        if IsMailReturnable(mailId) then
            ReturnMail(mailId)
        end
    end

    self.justReturnedMail = true
end

function ZO_MailInbox_Gamepad:ExitReturnDialog()
    if self.justReturnedMail then
        self:EnterMailList()
        self.justReturnedMail = false
    end
end

function ZO_MailInbox_Gamepad:CanDeleteActiveMail()
    local mailData = self:GetActiveMailData()
    if mailData then
        return (mailData.numAttachments == 0) and (mailData.attachedMoney == 0)
    end
    return false
end

function ZO_MailInbox_Gamepad:GetActiveMailHasAttachedGold()
    local mailId = self:GetActiveMailId()
    if mailId then
        local numAttachments, attachedMoney = GetMailAttachmentInfo(mailId)
        return attachedMoney > 0
    end
    return false
end

function ZO_MailInbox_Gamepad:GetActiveMailHasAttachedItems()
    local mailId = self:GetActiveMailId()
    if mailId then
        local numAttachments = GetMailAttachmentInfo(mailId)
        return numAttachments > 0
    end
    return false
end

function ZO_MailInbox_Gamepad:TryTakeAll()
    local mailId = self:GetActiveMailId()
    if mailId then
        local numAttachments, attachedMoney, codAmount = GetMailAttachmentInfo(mailId)

        if codAmount > 0 then
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MAIL_TAKE_ATTACHMENT_COD", self.confirmCODDialogData)
        else
            self:TakeAll()
        end
    end
end

function ZO_MailInbox_Gamepad:TakeAll()
    local mailId = self:GetActiveMailId()
    if mailId then
        ZO_MailInboxShared_TakeAll(mailId)        
    end
end

function ZO_MailInbox_Gamepad:OnMailTargetChanged(list, targetData)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindDescriptor)

    if targetData and targetData.mailId then
        RequestReadMail(targetData.mailId)
    else
        self.inbox:SetHidden(true)
    end
end

local function UpdateMailIcons(mailData, entryData)
    entryData:ClearIcons()
    if mailData.unread then
       entryData:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
    end
    if mailData.fromSystem then
        entryData:AddIcon(SYSTEM_MAIL_ICON)
    elseif mailData.fromCS then
        entryData:AddIcon(CUSTOMERSERVICE_MAIL_ICON)
    end
end

function ZO_MailInbox_Gamepad:UpdateMailColors()
    if self.inboxControl:IsHidden() then
        self.dirty = true
        return
    end

    for mailId in ZO_GetNextMailIdIter do
        local mailData = self.mailDataById[zo_getSafeId64Key(mailId)]

        local selectedColor, unselectedColor = GetEntryColors(mailData)
        local entryData = self.mailEntryDataById[zo_getSafeId64Key(mailId)]

        entryData:SetNameColors(selectedColor, unselectedColor)
        entryData:SetSubLabelColors(selectedColor, unselectedColor)
    end
end

local function SortFunction(left, right)
    return ZO_TableOrderingFunction(left, right, MAIL_ENTRY_FIRST_SORT_KEY, MAIL_ENTRY_SORT_KEYS, ZO_SORT_ORDER_UP)
end

function ZO_MailInbox_Gamepad:RefreshMailList()
    if not GAMEPAD_MAIL_INBOX_FRAGMENT:IsShowing() then
        self.dirty = true
        return
    end
    self.dirty = false

    -- Update the inbox list.
    self.mailDataById = {}
    self.mailEntryDataById = {}
    self.mailList:Clear()

    local entries = {}
    for mailId in ZO_GetNextMailIdIter do
        -- Get mail data.
        local mailData = {}
        ZO_MailInboxShared_PopulateMailData(mailData, mailId)

        local selectedColor, unselectedColor = GetEntryColors(mailData)

        local subject = mailData.subject
        if (not subject) or (subject == "") then
            subject = GetString(SI_MAIL_READ_NO_SUBJECT)
        end

        -- Basic setup.
        local entryData = ZO_GamepadEntryData:New(subject)
        entryData:SetDataSource(mailData)
        entryData:SetNameColors(selectedColor, unselectedColor)
        entryData:SetSubLabelColors(selectedColor, unselectedColor)
        entryData:AddSubLabel(zo_strformat(SI_GAMEPAD_MAIL_INBOX_RECEIVED_TEXT, mailData:GetReceivedText()))
        entryData:AddSubLabel(zo_strformat(SI_GAMEPAD_MAIL_INBOX_EXPIRES_TEXT, mailData:GetExpiresText()))

        local safeIdKey = zo_getSafeId64Key(mailId)
        self.mailDataById[safeIdKey] = mailData
        self.mailEntryDataById[safeIdKey] = entryData

        -- Setup icons.
        UpdateMailIcons(mailData, entryData)

        table.insert(entries, entryData)
    end

    table.sort(entries, SortFunction)

    for i=1, #entries do
        local entryData = entries[i]
        self.mailList:AddEntry("ZO_GamepadMenuEntryNoCapitalization", entryData)
    end

    self.mailList:Commit()

    -- If we have a queued message update, update it.
    if self.dirtyMail then
        self:ShowMailItem(self.dirtyMail)
    end

    MAIL_MANAGER_GAMEPAD:RefreshKeybind()

    if #entries == 0 then
        self.inbox:SetHidden(true)
    end
end

function ZO_MailInbox_Gamepad:ShowMailItem(mailId)
    -- If the mail Id does not match the current selection, ignore the update. This could happen if the user
    --  changes active messages and the messages are still loading.
    if (not AreId64sEqual(mailId, self:GetActiveMailId())) then
        return
    end

    -- If we have a queued message list refresh, or the control is hidden, queue a refresh of the mail message.
    if self.dirty or self.inboxControl:IsHidden() then
        self.dirtyMail = mailId
        return
    end
    self.dirtyMail = nil

    -- Basic display setup.
    self.inbox:SetHidden(false)
    MAIL_MANAGER_GAMEPAD:RefreshKeybind()

    -- Get the data.
    local safeIdKey = zo_getSafeId64Key(mailId)
    local mailData = self.mailDataById[safeIdKey]
    local entryData = self.mailEntryDataById[safeIdKey]
    local wasUnread = mailData.unread
    ZO_MailInboxShared_PopulateMailData(mailData, mailId)

    if mailData.unread ~= wasUnread then
        UpdateMailIcons(mailData, entryData)
    end

    local body = ReadMail(mailData.mailId)
    if body == "" then
        body = GetString(SI_MAIL_READ_NO_BODY)
    end

    local isSystem = (mailData.fromCS or mailData.fromSystem)
    local noAttachments = (mailData.numAttachments == 0)

    -- System mail should not add platform ID icon formatting, the name is already undecorated and ready to display if from the system
    local displayName = isSystem and mailData.senderDisplayName or ZO_FormatUserFacingDisplayName(mailData.senderDisplayName)

    self.inbox:Display(mailData.codAmount, mailData.attachedMoney, displayName, mailData:GetFormattedSubject(), body, isSystem, noAttachments)

    -- Attachments.
    for i = 1, mailData.numAttachments do
        local icon, stack, creator = GetAttachedItemInfo(mailId, i)
        self.inbox:SetAttachment(i, stack, icon)
    end

    for i = mailData.numAttachments + 1, MAX_READ_ATTACHMENTS do
        self.inbox:ClearAttachment(i)
    end

    if noAttachments and MAIL_MANAGER_GAMEPAD:IsCurrentList(self.attachmentsList) then
        self:EnterMailList()
    end

    -- Update the mail list (mostly for unread icon update).
    self.mailList:RefreshVisible()
end
