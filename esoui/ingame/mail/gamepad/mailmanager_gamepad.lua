-- Constants
ZO_MAIL_COD_MONEY_INSUFFICIENT_COLOR_GAMEPAD = ZO_ERROR_COLOR
ZO_MAIL_COD_MONEY_COLOR_GAMEPAD = ZO_ColorDef:New(1, 0.5, 0)
ZO_MAIL_COD_MONEY_COLOR_UNSELECTED_GAMEPAD = ZO_ColorDef:New(0.5, 0.25, 0)

ZO_MAIL_HEADER_MONEY_OPTIONS_GAMEPAD = ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT

ZO_MAIL_ATTACHED_MONEY_OPTIONS_GAMEPAD = ZO_ShallowTableCopy(ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
ZO_MAIL_ATTACHED_MONEY_OPTIONS_GAMEPAD.font = "ZoFontGamepad45"

ZO_MAIL_COD_MONEY_OPTIONS_GAMEPAD = ZO_ShallowTableCopy(ZO_MAIL_ATTACHED_MONEY_OPTIONS_GAMEPAD)
ZO_MAIL_COD_MONEY_OPTIONS_GAMEPAD.color = ZO_MAIL_COD_MONEY_COLOR_GAMEPAD

local COD_NOTICE_OFFSET = 15

-- Internal helper functions
local function ShowCODMessage(control, noticeColor)
    control.codNotice:SetHidden(false)
    control.codNotice:SetColor(noticeColor:UnpackRGBA())

    control.addressLabel:ClearAnchors()
    control.addressLabel:SetAnchor(TOPLEFT, control.codNotice, BOTTOMLEFT, 0, COD_NOTICE_OFFSET)
end

local function HideCODMessage(control)
    control.codNotice:SetHidden(true)
        
    control.addressLabel:ClearAnchors()
    control.addressLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
end

local function SetupMoney(control, codFee, attachedMoney)
    local hasAttachedMoney = (attachedMoney > 0)
    local hasCod = (codFee > 0)

    if hasAttachedMoney then
        HideCODMessage(control)

        control.moneyLabel:SetText(GetString(SI_MAIL_READ_SENT_GOLD_LABEL))
        
        ZO_CurrencyControl_SetSimpleCurrency(control.moneyValue, CURT_MONEY, attachedMoney, control.attachedMoneyOptions)
        control.moneyValue:SetHidden(false)
        control.moneyNone:SetHidden(true)

    elseif hasCod then
        local notEnoughMoney = (not control.outbox) and (codFee > GetCarriedCurrencyAmount(CURT_MONEY))
            
        ZO_CurrencyControl_SetSimpleCurrency(control.moneyValue, CURT_MONEY, codFee, control.codMoneyOptions, nil, notEnoughMoney)

        if control.outbox then
            HideCODMessage(control)
        else
            local noticeColor = notEnoughMoney and ZO_MAIL_COD_MONEY_INSUFFICIENT_COLOR_GAMEPAD or control.codMoneyOptions.color
            ShowCODMessage(control, noticeColor)
        end

        control.moneyLabel:SetText(GetString(SI_MAIL_READ_COD_LABEL))
        control.moneyValue:SetHidden(false)
        control.moneyNone:SetHidden(true)

    else -- No attached money or C.O.D.
        HideCODMessage(control)

        control.moneyLabel:SetText(GetString(SI_MAIL_READ_SENT_GOLD_LABEL))
        control.moneyValue:SetHidden(true)
        control.moneyNone:SetHidden(false)
    end
end

local function SetupEmptyAttachmentIcon(icon)
    if icon then
        local r,g,b = ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR:UnpackRGBA()
        icon:SetColor(r, g, b, icon:GetControlAlpha())
    end
end

local function CreateAttachmentSlot(parent, previous, index, emptyAttachmentSlotIcon)
    local PADDING = 0

    local newControl = CreateControlFromVirtual("$(parent)AttachmentSlot", parent, "ZO_MailAttachmentSlot_Gamepad", index)
    newControl:SetAnchor(TOPLEFT, previous, TOPRIGHT, 0, PADDING)
    newControl:SetAnchor(BOTTOMLEFT, previous, BOTTOMRIGHT, 0, PADDING)

    newControl.index = index
    newControl.icon = newControl:GetNamedChild("Icon")

    newControl:SetNormalTexture()
    newControl:SetPressedTexture()

    ZO_Inventory_BindSlot(newControl, SLOT_TYPE_MAIL_ATTACHMENT, index)
    ZO_Inventory_SetupSlot(newControl, 0, emptyAttachmentSlotIcon)
    if emptyAttachmentSlotIcon then
        SetupEmptyAttachmentIcon(newControl.icon)
        newControl:SetHidden(false)
    end

    return newControl
end

local function InitializeAttachmentSlots(control, maxAttachments, emptyAttachmentSlotIcon)
    control.attachmentSlots = {}
    local previous = control.attachmentsBox:GetNamedChild("AttachmentsBase")
    for i = 1, maxAttachments do
        local slot = CreateAttachmentSlot(control.attachmentsBox, previous, i, emptyAttachmentSlotIcon)
        control.attachmentSlots[i] = slot
        previous = slot
    end
end

-- Begin Public Shared Functions
-- Note that these functions are shared by both MailInbox_Gamepad and MailShared_Gamepad, so do not put code specific to either the inbox
-- or send windows here!

function ZO_MailView_Initialize_Gamepad(control, addressText, emptyAttachmentSlotIcon, outbox, codMoneyOptions, attachedMoneyOptions, maxAttachments)
    control.addressLabel:SetText(addressText)
    control.emptyAttachmentSlotIcon = emptyAttachmentSlotIcon
    control.outbox = outbox
    control.codMoneyOptions = codMoneyOptions
    control.attachedMoneyOptions = attachedMoneyOptions

    InitializeAttachmentSlots(control, maxAttachments, emptyAttachmentSlotIcon)
end

function ZO_MailView_GetAddress_Gamepad(control)
    return ZO_FormatManualNameEntry(control.addressEdit.edit:GetText())
end

function ZO_MailView_GetSubject_Gamepad(control)
    return control.subjectEdit.edit:GetText()
end

function ZO_MailView_GetBody_Gamepad(control)
    return control.bodyEdit.edit:GetText()
end

function ZO_MailView_Display_Gamepad(control, codFee, attachedMoney, address, subject, body, isSystem, noAttachments)
    if codFee or attachedMoney then
        SetupMoney(control, codFee, attachedMoney)
    end

    if address then
        control.addressEdit.edit:SetText(address)
        if isSystem then
            control.addressEdit.edit:SetColor(ZO_GAME_REPRESENTATIVE_TEXT:UnpackRGBA())
        else
            control.addressEdit.edit:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        end
    end

    if subject then
        control.subjectEdit.edit:SetText(subject)
    end

    if body then
        if (not control.outbox) and (body == "") then
            body = GetString(SI_MAIL_READ_NO_BODY)
        end
        control.bodyEdit.edit:SetText(body)
    end

    if control.outbox then
        control.attachmentsNone:SetHidden(true)
    elseif noAttachments ~= nil then -- false is valid here!
        control.attachmentsNone:SetHidden(not noAttachments)
    end
end

function ZO_MailView_Clear_Gamepad(control)
    ZO_MailView_Display_Gamepad(control, 0, 0, "", "", "", false, true)
end

function ZO_MailView_SetupAttachment_Gamepad(control, attachmentIndex, stack, icon)
    local attachmentSlot = control.attachmentSlots[attachmentIndex]
    attachmentSlot:SetHidden(false)
    ZO_Inventory_SetupSlot(attachmentSlot, stack, icon)
end

function ZO_MailView_ClearAttachment_Gamepad(control, attachmentIndex)
    local attachmentSlot = control.attachmentSlots[attachmentIndex]
    if not control.emptyAttachmentSlotIcon then
        attachmentSlot:SetHidden(true)
    else
        ZO_Inventory_SetupSlot(attachmentSlot, 0, control.emptyAttachmentSlotIcon)
        SetupEmptyAttachmentIcon(attachmentSlot.icon)
    end
end

-- End Public Shared Functions

-- Mail Header
INBOX_TAB_INDEX = 1
SEND_TAB_INDEX = 2
local MailManager_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function MailManager_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function MailManager_Gamepad:Initialize(control)
    -- Scene Setup.
    MAIL_MANAGER_GAMEPAD_SCENE = ZO_RemoteScene:New("mailManagerGamepad", SCENE_MANAGER)

    local DONT_ACTIVATE_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, DONT_ACTIVATE_ON_SHOW, MAIL_MANAGER_GAMEPAD_SCENE)

    self.inbox = ZO_MailInbox_Gamepad:New(control)
    self.send = ZO_MailSend_Gamepad:New(control)

    self.deferredKeybindStripDescriptor = false
    CALLBACK_MANAGER:RegisterCallback("OnGamepadDialogHidden", function()
            if self.deferredKeybindStripDescriptor ~= false then
                self:SwitchToKeybind(self.deferredKeybindStripDescriptor)
            end
        end
    )
end

function MailManager_Gamepad:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        if MAIN_MENU_MANAGER:IsPlayerInCombat() then
            SCENE_MANAGER:HideCurrentScene()
        else
            self:PerformDeferredInitialization()
            self:SwitchToHeader(self.baseHeaderData)
            local tabIndex = self.initialTabIndex or INBOX_TAB_INDEX
            self.initialTabIndex = nil
            ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, tabIndex)

            if(tabIndex == INBOX_TAB_INDEX) then
                self.inbox.isLoading = true
                self.inbox:EnterLoading()
            end
        end
    elseif newState == SCENE_HIDDEN then
        self:DisableCurrentList()
        self:SwitchToHeader(nil)
        self:SwitchToKeybind(nil)
        self:SwitchToFragment(nil)
    end
end

function MailManager_Gamepad:SwitchToFragment(fragment)
    if self.activeFragment == fragment then return end

    if self.activeFragment then
        MAIL_MANAGER_GAMEPAD_SCENE:RemoveFragment(self.activeFragment)
    end

    self.activeFragment = fragment
    if fragment then
        MAIL_MANAGER_GAMEPAD_SCENE:AddFragment(fragment)
    end
end

function MailManager_Gamepad:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    -- Header
    self.tabBarEntries = {
                {
                    text = function()
                        local inboxTitle = nil

                        if IsLocalMailboxFull() then
                            inboxTitle = zo_strformat(SI_GAMEPAD_MAIL_INBOX_WINDOW_TITLE, GetString(SI_WINDOW_TITLE_INBOX_MAIL), GetString(SI_GAMEPAD_MAIL_INBOX_FULL))
                        elseif GetNumUnreadMail() > 0 then
                            inboxTitle = zo_strformat(SI_GAMEPAD_MAIL_INBOX_WINDOW_TITLE, GetString(SI_WINDOW_TITLE_INBOX_MAIL), GetNumUnreadMail())
                        else
                            inboxTitle = GetString(SI_WINDOW_TITLE_INBOX_MAIL)
                        end

                        return inboxTitle
                    end,
                    callback = function()
                        self:SwitchToFragment(GAMEPAD_MAIL_INBOX_FRAGMENT)
                    end,
                },
                {
                    text = GetString(SI_WINDOW_TITLE_SEND_MAIL),
                    callback = function()
                        self:SwitchToFragment(GAMEPAD_MAIL_SEND_FRAGMENT)
                    end,
                },
            }

    self.baseHeaderData = {
                tabBarEntries = self.tabBarEntries,
            }

    self:InitializeControls()
end

function MailManager_Gamepad:InitializeControls()
    -- Loading
    self.loadingBox = self.control:GetNamedChild("Loading")
    self.loadingLabel = self.loadingBox:GetNamedChild("ContainerText")
end

function MailManager_Gamepad:RefreshHeader()
    if self.activeHeader then
        ZO_GamepadGenericHeader_Refresh(self.header, self.activeHeader)
    end
end

function MailManager_Gamepad:SetupInitialTab(tabIndex)
    self.initialTabIndex = tabIndex
end

function MailManager_Gamepad:ShowTab(tabIndex, pushScene)
    self:SetupInitialTab(tabIndex)
    if pushScene then
        SCENE_MANAGER:Push("mailManagerGamepad")
    else
        SCENE_MANAGER:Show("mailManagerGamepad")
    end
end

function MailManager_Gamepad:SwitchToHeader(headerData, tabIndex)
    self.activeHeader = headerData
    if headerData then
        ZO_GamepadGenericHeader_Refresh(self.header, headerData)

        if tabIndex ~= nil then
            ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, tabIndex)
        end

        if headerData.tabBarEntries then
            ZO_GamepadGenericHeader_Activate(self.header)
        else
            ZO_GamepadGenericHeader_Deactivate(self.header)
        end
        self.header:SetHidden(false)
    else
        ZO_GamepadGenericHeader_Deactivate(self.header)
        self.header:SetHidden(true)
    end
end

function MailManager_Gamepad:RefreshKeybind()
    if self.keybindStripDescriptor and not ZO_GenericGamepadDialog_IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function MailManager_Gamepad:SwitchToKeybind(keybindDescriptor)
    if ZO_GenericGamepadDialog_IsShowing() then
        self.deferredKeybindStripDescriptor = keybindDescriptor
        return
    else
        self.deferredKeybindStripDescriptor = false
    end

    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
    self.keybindStripDescriptor = keybindDescriptor
    if keybindDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(keybindDescriptor)
    end
end

function MailManager_Gamepad:GetSend()
    return self.send
end

function ZO_MailManager_Gamepad_OnInitialized(control)
    MAIL_MANAGER_GAMEPAD = MailManager_Gamepad:New(control)
end
