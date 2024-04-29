-- Some configuration options.
local MAX_READ_ATTACHMENTS = MAIL_MAX_ATTACHED_ITEMS + 1

local SYSTEM_MAIL_ICON = "EsoUI/Art/Mail/Gamepad/gp_mailMenu_mailType_system.dds"
local CUSTOMERSERVICE_MAIL_ICON = "EsoUI/Art/Mail/Gamepad/gp_mailMenu_mailType_CS.dds"
local EXPIRATION_IMMINENT_ICON = "EsoUI/Art/Miscellaneous/timerRed_64.dds"
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

    self.activeLinks = ZO_GamepadLinks:New()
    self.activeLinks:SetUseKeybind("UI_SHORTCUT_LEFT_STICK")
    self.activeLinks:SetKeybindAlignment(KEYBIND_STRIP_ALIGN_RIGHT)
    self.activeLinks:RegisterCallback("CycleLinks", function()
        --Re-narrate when cycling between multiple links
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.mailList)
    end)

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
        -- Suppress link updating as this is initially handled by OnShown.
        local SUPPRESS_LINK_UPDATE = true
        self:ShowMailItem(self.dirtyMail, SUPPRESS_LINK_UPDATE)
    end
end

function ZO_MailInbox_Gamepad:OnShown()
    --Trigger the tutorial if *any* category is full
    for category = MAIL_CATEGORY_ITERATION_BEGIN, MAIL_CATEGORY_ITERATION_END do
        if IsLocalMailboxFull(category) then
            TriggerTutorial(TUTORIAL_TRIGGER_MAIL_OPENED_AND_FULL)
            break
        end
    end

    self:UpdateLinks()
end

function ZO_MailInbox_Gamepad:OnHiding()
    self.activeLinks:ResetLinks()
    self.activeLinks:Hide()
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
    self:InitializeOptionsDialog()
    self:InitializeAttachmentsList()
    self:InitializeKeybindDescriptors()

    self:InitializeEvents()
end

function ZO_MailInbox_Gamepad:InitializeFragment()
    GAMEPAD_MAIL_INBOX_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Mail_Gamepad_TopLevelInbox)
    GAMEPAD_MAIL_INBOX_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
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
    self.inboxRightPane = self.inboxControl:GetNamedChild("RightPane")
    self.inbox = self.inboxRightPane:GetNamedChild("Container"):GetNamedChild("Inbox")

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
    self.attachmentsList = MAIL_GAMEPAD:AddList("Attachments", SetupAttachmentsList)
    self.attachmentsListControl = self.attachmentsList:GetControl()

    self.attachmentsList:SetOnSelectedDataChangedCallback(function(...) self:AttachmentSelectionChanged(...) end)
end

function ZO_MailInbox_Gamepad:InitializeOptionsDialog()
    local SHOW_GAMERCARD_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(ZO_GetGamerCardStringId()),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                local mailData = self:GetActiveMailData()
                if not mailData.fromSystem then
                    ZO_ShowGamerCardFromDisplayNameOrFallback(mailData.senderDisplayName, ZO_ID_REQUEST_TYPE_MAIL_ID, mailData.mailId)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_MAIL_INBOX_OPTIONS")
                end
            end,
        },
    }

    local REPLY_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_MAIL_READ_REPLY),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                self:Reply()
                ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_MAIL_INBOX_OPTIONS")
            end,
        },
    }

    local RETURN_TO_SENDER_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_MAIL_READ_RETURN),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_MAIL_INBOX_OPTIONS")
                ZO_Dialogs_ShowGamepadDialog("MAIL_RETURN_ATTACHMENTS", { callback = function() self:ReturnToSender() end, finishedCallback = function() self:ExitReturnDialog() end }, {mainTextParams = {self:GetActiveMailSender()}})
            end,
        },
    }

    local REPORT_PLAYER_ENTRY =
    {
        template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",
        templateData =
        {
            text = GetString(SI_MAIL_READ_REPORT_PLAYER),
            setup = ZO_SharedGamepadEntry_OnSetup,
            callback = function(dialog)
                self:ReportPlayer()
                ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_MAIL_INBOX_OPTIONS")
            end,
        },
    }

    local DELETE_ON_CLAIM_ENTRY =
    {
        template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
        text = GetString(SI_MAIL_INBOX_DELETE_AFTER_CLAIM),
        templateData =
        {
            -- Called when the checkbox is toggled
            setChecked = function(checkBox, checked)
                checkBox.dialog.deleteOnClaim = checked
            end,

            --Used during setup to determine if the data should be setup checked or unchecked
            checked = function(data)
                return data.dialog.deleteOnClaim
            end,

            setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                control.checkBox.dialog = data.dialog
                ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
            end,

            callback = function(dialog)
                local targetControl = dialog.entryList:GetTargetControl()
                ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
            end,

            narrationText = ZO_GetDefaultParametricListToggleNarrationText,
        }
    }

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_MAIL_INBOX_OPTIONS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_MAIL_INBOX_OPTIONS,
        },
        setup = function(dialog, data)
            local parametricListEntries = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)

            local mailData = self:GetActiveMailData()
            if mailData and not IsMailSystem(mailData) then
                if IsConsoleUI() then
                    table.insert(parametricListEntries, SHOW_GAMERCARD_ENTRY)
                end

                table.insert(parametricListEntries, REPLY_ENTRY)

                if IsMailReturnable(self:GetActiveMailId()) then
                    table.insert(parametricListEntries, RETURN_TO_SENDER_ENTRY)
                end

                --Customer service options are not currently available for PC Gamepad
                if IsConsoleUI() and IsMailReportable(mailData) then
                    table.insert(parametricListEntries, REPORT_PLAYER_ENTRY)
                end
            end

            table.insert(parametricListEntries, DELETE_ON_CLAIM_ENTRY)
            dialog.deleteOnClaim = data.deleteOnClaim

            dialog.setupFunc(dialog)
        end,
        parametricList = {}, -- Generated dynamically
        blockDialogReleaseOnPress = true,
        finishedCallback = function(dialog)
            MAIL_MANAGER:SetDeleteOnClaim(dialog.deleteOnClaim)
            MAIL_GAMEPAD:RefreshHeader()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindDescriptor)
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_MAIL_INBOX_OPTIONS")
                end,
            }
        }
    })
end

local function SetupList(list)
    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplate("ZO_GamepadMenuEntryNoCapitalization", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryNoCapitalization", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_MailInbox_Gamepad:InitializeMailList()
    self.mailList = MAIL_GAMEPAD:AddList("Mail", SetupList)
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

local function GetDeleteOnClaimText()
    local deleteOnClaim = MAIL_MANAGER:ShouldDeleteOnClaim()
    return deleteOnClaim and GetString(SI_GAMEPAD_MAIL_INBOX_DELETE_ON_CLAIM_ENABLED) or GetString(SI_GAMEPAD_MAIL_INBOX_DELETE_ON_CLAIM_DISABLED)
end

function ZO_MailInbox_Gamepad:InitializeHeader()
    self.mainHeaderData = {
        data1HeaderText = GetString(SI_GAMEPAD_MAIL_INBOX_PLAYER_GOLD),
        data1Text = UpdatePlayerGold,
        data1TextNarration = ZO_Currency_GetPlayerCarriedGoldCurrencyNameNarration,

        data2HeaderText = GetString(SI_GAMEPAD_MAIL_INBOX_INVENTORY),
        data2Text = GetInventoryString,

        data3HeaderText = GetString(SI_MAIL_INBOX_DELETE_AFTER_CLAIM),
        data3Text = GetDeleteOnClaimText,

        tabBarEntries = MAIL_GAMEPAD.tabBarEntries,
    }

    local function UpdateCODAmount(control)
        local mailData = self:GetActiveMailData()
        if mailData then
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, mailData.codAmount, ZO_MAIL_HEADER_MONEY_OPTIONS_GAMEPAD)
        end
        return true
    end

    local function GetCODAmountNarration()
        local mailData = self:GetActiveMailData()
        if mailData then
            return ZO_Currency_FormatGamepad(CURT_MONEY, mailData.codAmount, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
        end
    end

    self.confirmCODDialogData = 
    {
        data1 = 
        {
            header = GetString(SI_GAMEPAD_MAIL_INBOX_PLAYER_GOLD),
            value = UpdatePlayerGold,
            valueNarration = ZO_Currency_GetPlayerCarriedGoldNarration,
        },
        data2 = 
        {
            header = GetString(SI_MAIL_READ_COD_LABEL),
            value = UpdateCODAmount,
            valueNarration = GetCODAmountNarration,
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
                    self:HideAll()
                    MAIL_GAMEPAD:SwitchToKeybind(nil)
                    
                    self:Delete()
                end,
            visible = function() 
                local mailId = self:GetActiveMailId()
                return mailId ~= nil and not IsMailReturnable(mailId) 
            end,
        },
        
        -- Options
        {
            name = GetString(SI_GAMEPAD_MAIL_INBOX_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_MAIL_INBOX_OPTIONS", { deleteOnClaim = MAIL_MANAGER:ShouldDeleteOnClaim() })
            end,
        },

        -- Claim All
        {
            name = function()
                return GetString("SI_MAILCATEGORY_TAKEALL", self:GetActiveMailCategory())
            end,
            keybind = "UI_SHORTCUT_QUINARY",
            callback = function()
                ZO_Dialogs_ShowPlatformDialog("MAIL_CONFIRM_TAKE_ALL", { category = self:GetActiveMailCategory() })
            end,
            visible = function()
                local activeMailCategory = self:GetActiveMailCategory()
                if activeMailCategory then
                    return CanTryTakeAllMailAttachmentsInCategory(activeMailCategory, MAIL_MANAGER:ShouldDeleteOnClaim())
                end
                return false
            end,
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
            MAIL_GAMEPAD:RefreshKeybind()
        end
    end
    
    local function TakeAttachment(_, mailId)
        self:ShowMailItem(mailId)
        MAIL_GAMEPAD:RefreshKeybind()
        MAIL_GAMEPAD:RefreshHeader()
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.mailList)
    end

    local function OnMoneyUpdated()
        local mailId = self:GetActiveMailId()
        if mailId then
            self:ShowMailItem(mailId)
        end
        self:UpdateMailColors()
        self.mailList:RefreshVisible()
        MAIL_GAMEPAD:RefreshHeader()
    end

    local function OnMailRemoved(evt, mailId)
        MAIL_GAMEPAD:RefreshHeader()
        self:RefreshMailList()
    end

    local function OnTakeAllComplete(_, result, category, headersRemoved)
        if result == MAIL_TAKE_ATTACHMENT_RESULT_SUCCESS then
            MAIL_GAMEPAD:RefreshHeader()
            self:RefreshMailList(headersRemoved)
        end
    end

    self.control:RegisterForEvent(EVENT_MAIL_INBOX_UPDATE, function() self:MailboxUpdated() end)
    self.control:RegisterForEvent(EVENT_MAIL_READABLE, OnMailReadable)
    self.control:RegisterForEvent(EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, TakeAttachment)
    self.control:RegisterForEvent(EVENT_MAIL_TAKE_ATTACHED_MONEY_SUCCESS, TakeAttachment)
    self.control:RegisterForEvent(EVENT_MAIL_REMOVED, OnMailRemoved)
    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnMoneyUpdated)
    self.control:RegisterForEvent(EVENT_MAIL_NUM_UNREAD_CHANGED, function(...) MAIL_GAMEPAD:RefreshHeader() end)
    self.control:RegisterForEvent(EVENT_MAIL_TAKE_ALL_ATTACHMENTS_IN_CATEGORY_RESPONSE, OnTakeAllComplete)

    self.control:RegisterForEvent(EVENT_DELETE_MAIL_RESPONSE, function(eventCode, mailId, result)
        if GAMEPAD_MAIL_INBOX_FRAGMENT:IsShowing() then
            self:EnterMailList()
        end
    end)

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

    MAIL_GAMEPAD:DisableCurrentList()

    MAIL_GAMEPAD:SwitchToHeader(self.mainHeaderData)
end

function ZO_MailInbox_Gamepad:Delete()
    local mailId = self:GetActiveMailId()
    if mailId then
        local numAttachments, attachedMoney = GetMailAttachmentInfo(mailId)
        if numAttachments > 0 or attachedMoney > 0 then
            DeleteMail(mailId)
        else
            ZO_Dialogs_ShowPlatformDialog(
                "DELETE_MAIL", 
                {
                    confirmationCallback = function(...) 
                        DeleteMail(mailId) 
                        PlaySound(SOUNDS.MAIL_ITEM_DELETED) 
                    end, 
                    mailId = mailId,
                }
            )
            self:EnterMailList()
        end
    end

end

function ZO_MailInbox_Gamepad:EnterLoading()
    self:HideAll()

    MAIL_GAMEPAD:SwitchToKeybind(self.loadingKeybindDescriptor)
    self.loadingLabel:SetText(GetString(SI_GAMEPAD_MAIL_INBOX_LOADING))
    self.loadingBox:SetHidden(false)
    self.inbox:SetHidden(true)
end

function ZO_MailInbox_Gamepad:EnterMailList()
    self:HideAll()

    MAIL_GAMEPAD:SwitchToKeybind(self.mainKeybindDescriptor)
    MAIL_GAMEPAD:SetCurrentList(self.mailList)
end

function ZO_MailInbox_Gamepad:Reply()
    MAIL_GAMEPAD:GetSend():ComposeMailTo(self:GetActiveMailSender(), self:GetActiveMailData():GetFormattedReplySubject())
    MAIL_GAMEPAD:GetSend():SwitchToSendTab()

    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_MailInbox_Gamepad:InsertBodyText(text)
    MAIL_GAMEPAD:GetSend():InsertBodyText(text)
    MAIL_GAMEPAD:GetSend():SwitchToSendTab()

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
            local icon, stack, creator, sellPrice, meetsUsageRequirement, equipType, itemStyle, displayQuality = GetAttachedItemInfo(mailId, i)

            itemName = zo_strformat(SI_LINK_FORMAT_ITEM_NAME, itemName)

            local itemData =
            {
                text = itemName,
                icon = icon,
                displayQuality = displayQuality,
                -- quality is deprecated, included here for addon backwards compatibility
                quality = displayQuality,
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
    MAIL_GAMEPAD:SwitchToKeybind(self.viewAttachmentsKeybindDescriptor)
    MAIL_GAMEPAD:SwitchToHeader(nil)
    GAMEPAD_TOOLTIPS:SetBgType(GAMEPAD_LEFT_TOOLTIP, GAMEPAD_TOOLTIP_DARK_BG)
    GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_LEFT_TOOLTIP)
    MAIL_GAMEPAD:SetCurrentList(self.attachmentsList)
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

function ZO_MailInbox_Gamepad:GetActiveMailCategory()
    local mailData = self:GetActiveMailData()
    if mailData then
        return mailData.category
    end
    return nil
end

function ZO_MailInbox_Gamepad:ReportPlayer()
    if IsMailReportable(self:GetActiveMailData()) then
        local displayName = self:GetActiveMailSender()
        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(displayName)
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

function ZO_MailInbox_Gamepad:GetActiveMailHasAttachedGold()
    local mailId = self:GetActiveMailId()
    if mailId then
        local _, attachedMoney = GetMailAttachmentInfo(mailId)
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
        local _, _, codAmount = GetMailAttachmentInfo(mailId)

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

    if mailData.firstItemIcon ~= ZO_NO_TEXTURE_FILE then
        entryData:AddIcon(mailData.firstItemIcon)
    end

    --Only show the system mail icon for system mail in the "System Alerts" category
    if mailData.fromSystem and mailData.category == MAIL_CATEGORY_INFO_ONLY_SYSTEM_MAIL then
        entryData:AddIcon(SYSTEM_MAIL_ICON)
    elseif mailData.fromCS then
        entryData:AddIcon(CUSTOMERSERVICE_MAIL_ICON)
    end
    if mailData:IsExpirationImminent() then
        entryData:AddIcon(EXPIRATION_IMMINENT_ICON)
    end
end

function ZO_MailInbox_Gamepad:UpdateMailColors()
    if self.inboxControl:IsHidden() then
        self.dirty = true
        return
    end

    for mailId in ZO_GetNextMailIdIter do
        local mailData = self.mailDataById[zo_getSafeId64Key(mailId)]

        if mailData then
            local selectedColor, unselectedColor = GetEntryColors(mailData)
            local entryData = self.mailEntryDataById[zo_getSafeId64Key(mailId)]

            entryData:SetNameColors(selectedColor, unselectedColor)
            entryData:SetSubLabelColors(selectedColor, unselectedColor)
        end
    end
end

local function GetMailNarrationText(entryData, entryControl)
    local narrations = {}
    ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

    local moneyHeader
    local moneyText
    local hasAttachedMoney = entryData.attachedMoney > 0
    local hasCod = entryData.codAmount > 0

    --Generate the COD Fee/Sent Gold text
    if hasAttachedMoney then
        moneyHeader = GetString(SI_MAIL_READ_SENT_GOLD_LABEL)
        moneyText = ZO_Currency_FormatGamepad(CURT_MONEY, entryData.attachedMoney, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
    elseif hasCod then
        moneyHeader = GetString(SI_MAIL_READ_COD_LABEL)
        moneyText = ZO_Currency_FormatGamepad(CURT_MONEY, entryData.codAmount, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
        --If this mail has a COD Fee, include the narration for the COD notice
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MAIL_INBOX_COD_NOTICE)))
    else
        moneyHeader = GetString(SI_MAIL_READ_SENT_GOLD_LABEL)
        moneyText = GetString(SI_GAMEPAD_MAIL_INBOX_NO_ATTACHED_GOLD)
    end

    --Generate the narration for the From section
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MAIL_INBOX_FROM)))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.senderDisplayName))

    --Generate the narration for the Subject section
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MAIL_SUBJECT_LABEL)))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedSubject()))

    --Generate the narration for the Message section
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MAIL_BODY_LABEL)))
    local body = ReadMail(entryData.mailId)
    if body == "" then
        body = GetString(SI_MAIL_READ_NO_BODY)
    end
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(body))

    --Generate the narration for the attached money/cod fee
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(moneyHeader))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(moneyText))

    --Generate the narration for the attachments
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_MAIL_ATTACHMENTS_HEADER)))
    if entryData.numAttachments > 0 then
        local totalAttachments = 0
        for i = 1, entryData.numAttachments do
            local _, stack = GetAttachedItemInfo(entryData.mailId, i)
            totalAttachments = totalAttachments + stack
        end
        --Narrate the total stack count of all the attachments, not just the number of unique attachments
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(totalAttachments))
    else
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MAIL_INBOX_NO_ATTACHMENTS)))
    end
    return narrations
end

function ZO_MailInbox_Gamepad:RefreshMailList(resetToTop)
    if not GAMEPAD_MAIL_INBOX_FRAGMENT:IsShowing() then
        self.dirty = true
        return
    end
    self.dirty = false

    -- Update the inbox list.
    self.mailDataById = {}
    self.mailEntryDataById = {}
    self.mailList:Clear()

    for category = MAIL_CATEGORY_ITERATION_BEGIN, MAIL_CATEGORY_ITERATION_END do
        local numMailItems = GetNumMailItemsByCategory(category)
        for index = 1, numMailItems do
            local mailId = GetMailIdByIndex(category, index)
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
            entryData.narrationText = GetMailNarrationText

            local expiresText = zo_strformat(SI_MAIL_INBOX_EXPIRES_TEXT, mailData:GetExpiresText())
            if mailData:IsExpirationImminent() then
                expiresText = ZO_ERROR_COLOR:Colorize(expiresText)
            end
            entryData:AddSubLabel(expiresText)

            local safeIdKey = zo_getSafeId64Key(mailId)
            self.mailDataById[safeIdKey] = mailData
            self.mailEntryDataById[safeIdKey] = entryData

            -- Setup icons.
            UpdateMailIcons(mailData, entryData)

            if index == 1 then
                entryData:SetHeader(GetString("SI_MAILCATEGORY", category))
                self.mailList:AddEntryWithHeader("ZO_GamepadMenuEntryNoCapitalization", entryData)
            else
                self.mailList:AddEntry("ZO_GamepadMenuEntryNoCapitalization", entryData)
            end
        end
    end

    self.mailList:Commit(resetToTop)

    -- If we have a queued message update, update it.
    if self.dirtyMail then
        self:ShowMailItem(self.dirtyMail)
    end

    MAIL_GAMEPAD:RefreshKeybind()

    self.inbox:SetHidden(not self.mailList:HasEntries())
end

function ZO_MailInbox_Gamepad:ShowMailItem(mailId, suppressLinkUpdate)
    self.activeLinks:ResetLinks()

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
    MAIL_GAMEPAD:RefreshKeybind()

    -- Get the data.
    local safeIdKey = zo_getSafeId64Key(mailId)
    local mailData = self.mailDataById[safeIdKey]
    local entryData = self.mailEntryDataById[safeIdKey]
    local wasUnread = mailData.unread
    local oldFirstItemIcon = mailData.firstItemIcon
    ZO_MailInboxShared_PopulateMailData(mailData, mailId)

    if mailData.unread ~= wasUnread or mailData.firstItemIcon ~= oldFirstItemIcon then
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
        local icon, stack = GetAttachedItemInfo(mailId, i)
        self.inbox:SetAttachment(i, stack, icon)
    end

    for i = mailData.numAttachments + 1, MAX_READ_ATTACHMENTS do
        self.inbox:ClearAttachment(i)
    end

    if noAttachments and MAIL_GAMEPAD:IsCurrentList(self.attachmentsList) then
        self:EnterMailList()
    end

    -- Update the mail list (mostly for unread icon update).
    self.mailList:RefreshVisible()

    if not suppressLinkUpdate then
        self:UpdateLinks()
    end
end

------------------
-- Active Links --
------------------

function ZO_MailInbox_Gamepad:UpdateLinks()
    if self.inboxControl:IsHidden() then
        self.activeLinks:Hide()
        return
    end

    -- Extract and register any links found in the Guild's
    -- Message of the Day and Description (About Us) text.
    self.activeLinks:ResetLinks()

    local bodyText = self.inbox.bodyEdit.edit:GetText()
    if bodyText ~= "" then
        self.activeLinks:AddLinksFromText(bodyText)
    end

    if self.activeLinks:HasLinks() then
        self.inboxRightPane:SetWidth(ZO_GAMEPAD_QUADRANT_2_3_WIDTH)
        self.activeLinks:Show()
    else
        self.inboxRightPane:SetWidth(ZO_GAMEPAD_QUADRANT_2_3_4_WIDTH)
        self.activeLinks:Hide()
    end
end