-- Settings.
local MAX_SEND_ATTACHMENTS = MAIL_MAX_ATTACHED_ITEMS
local EMPTY_ATTACHMENT_ICON = "EsoUI/Art/Mail/Gamepad/gp_mailMenu_attachItem.dds"
local SEND_GOLD_ICON = "EsoUI/Art/Mail/Gamepad/gp_mailMenu_sendGold.dds"
local REQUEST_GOLD_ICON = "EsoUI/Art/Mail/Gamepad/gp_mailMenu_requestGold.dds"
local ATTACHING_GOLD = "attach"
local REQUESTING_GOLD = "request"

-- TODO: This needs to be figured out for localization.
local LETTER_GROUPS =
{
    a = "A-E",
    b = "A-E",
    c = "A-E",
    d = "A-E",
    e = "A-E",
    f = "F-J",
    g = "F-J",
    h = "F-J",
    i = "F-J",
    j = "F-J",
    k = "K-O",
    l = "K-O",
    m = "K-O",
    n = "K-O",
    o = "K-O",
    p = "P-T",
    q = "P-T",
    r = "P-T",
    s = "P-T",
    t = "P-T",
    u = "U-Z",
    v = "U-Z",
    w = "U-Z",
    x = "U-Z",
    y = "U-Z",
    z = "U-Z",
}

-- For a given inventory item, return the attachment slot index, or nil if the item is not attached.
local function GetItemAttachedIndex(bagId, slotIndex)
    for i = 1, MAIL_MAX_ATTACHED_ITEMS do
        local queuedBagId, queuedSlotIndex = GetQueuedItemAttachmentInfo(i)
        if (queuedBagId == bagId) and (queuedSlotIndex == slotIndex) then
            return i
        end
    end
    return nil -- Item not attached.
end

-- Returns whether the specified inventory item is attached.
local function IsItemAttached(bagId, slotIndex)
    if GetItemAttachedIndex(bagId, slotIndex) then
        return true
    else
        return false
    end
end

-- Returns the next open attachment slot index, or nil if all attachment slots are full.
local function GetNextOpenAttachIndex()
    for i = 1, MAIL_MAX_ATTACHED_ITEMS do
        local queuedFromBag = GetQueuedItemAttachmentInfo(i)
        if queuedFromBag == 0 then -- Slot is open.
            return i
        end
    end
    return nil -- No open slots.
end

-- Returns whether there is any item attached.
local function IsAnyItemAttached(bagId, slotIndex)
    for i = 1, MAIL_MAX_ATTACHED_ITEMS do
        local queuedFromBag = GetQueuedItemAttachmentInfo(i)
        if queuedFromBag ~= 0 then -- Slot is filled.
            return true
        end
    end
    return false
end

-- Removes the item attached in the specified slot, behaving as design requested.
local function RemoveQueuedAttachment(attachmentIndex)
    RemoveQueuedItemAttachment(attachmentIndex)
    for i = attachmentIndex+1, MAIL_MAX_ATTACHED_ITEMS do
        local queuedBagId, queuedSlotIndex = GetQueuedItemAttachmentInfo(i)
        if queuedBagId ~= 0 then -- Slot is filled.
            RemoveQueuedItemAttachment(i)
            QueueItemAttachment(queuedBagId, queuedSlotIndex, i-1)
        end 
    end
end

-- Returns the proper platform-dependent text for the "To" field
local function GetDefaultAddresseeText()
    local addresseeText

    if IsConsoleUI() then
        addresseeText = zo_strformat(GetString(SI_GAMEPAD_MAIL_DEFAULT_ADDRESSEE), ZO_GetPlatformAccountLabel())
    else
        addresseeText = GetString(SI_REQUEST_NAME_DEFAULT_TEXT)
    end

    return addresseeText
end

-- The main class.
ZO_MailSend_Gamepad = ZO_Object:Subclass()

function ZO_MailSend_Gamepad:New(...)
    local mailSend = ZO_Object.New(self)
    mailSend:Initialize(...)
    return mailSend
end

function ZO_MailSend_Gamepad:Initialize(control)
    self.control = control
    self.sendControl = self.control:GetNamedChild("Send")
    self:InitializeFragment()
end

function ZO_MailSend_Gamepad:OnShowing()
    self:PerformDeferredInitialization()

    self.inventoryList:RefreshList()
    self:PopulateMainList()
    self:ConnectShownEvents()

    self:EnterOutbox()
    self:UpdateMoneyAttachment()
    ZO_MailSendShared_RestorePendingMail(self)

    if self.initialContact then
        self.mailView:Display(nil, nil, self.initialContact)
        self.initialContact = nil
    end

    self:HighlightActiveTextField()
end

function ZO_MailSend_Gamepad:OnHidden()
    self:Reset()
    self:DisconnectShownEvent()
end

function ZO_MailSend_Gamepad:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    self:InitializeControls()
    self:InitializeInventoryList()
    self:InitializeHeader()
    self:InitializeMainList()
    self:InitializeContactsList()
    self:InitializeEvents()
    self:InitializeKeybindDescriptors()
end

function ZO_MailSend_Gamepad:InitializeControls()
    -- Sending Mail
    self.loadingBox = self.control:GetNamedChild("Loading")
    self.loadingLabel = self.loadingBox:GetNamedChild("ContainerText")

    -- Mail View
    self.mailView = self.sendControl:GetNamedChild("RightPane"):GetNamedChild("Container"):GetNamedChild("MailView")
    local IS_OUTBOX = true
    self.mailView:Initialize(GetString(SI_GAMEPAD_MAIL_SEND_TO), EMPTY_ATTACHMENT_ICON, IS_OUTBOX, ZO_MAIL_COD_MONEY_OPTIONS_GAMEPAD, ZO_MAIL_ATTACHED_MONEY_OPTIONS_GAMEPAD, MAX_SEND_ATTACHMENTS)
    self.mailView:Clear()
    self.mailView.subjectEdit.edit:SetMaxInputChars(MAIL_MAX_SUBJECT_CHARACTERS)
    self.mailView.bodyEdit.edit:SetMaxInputChars(MAIL_MAX_BODY_CHARACTERS)

    -- Gold Slider
    self.goldSliderControl = self.sendControl:GetNamedChild("GoldSliderBox")
    self.goldSlider = ZO_CurrencySelector_Gamepad:New(self.goldSliderControl:GetNamedChild("Selector"))
    self.goldSlider:SetClampValues(true)
    self.goldSlider:RegisterCallback("OnValueChanged", function() MAIL_MANAGER_GAMEPAD:RefreshKeybind() end)
end

function ZO_MailSend_Gamepad:InitializeFragment()
    GAMEPAD_MAIL_SEND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_MailManager_GamepadSend)
    GAMEPAD_MAIL_SEND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif(newState == SCENE_SHOWN) then
            if(self.pendingMailChanged) then
                ZO_Dialogs_ShowGamepadDialog("MAIL_ATTACHMENTS_CHANGED")
                self.pendingMailChanged = nil
            end   
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            ZO_MailSendShared_SavePendingMail()
            self:OnHidden()
        end
    end)
end

function ZO_MailSend_Gamepad:ConnectShownEvents()
    self.control:RegisterForEvent(EVENT_MAIL_COD_CHANGED, function() self:UpdateMoneyAttachment() end)
    self.control:RegisterForEvent(EVENT_MAIL_ATTACHED_MONEY_CHANGED, function() self:UpdateMoneyAttachment() end)
    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, function() self:UpdatePostageMoney() end)

    local function HandleInventoryChanged()
        self:PopulateMainList()
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)
end

function ZO_MailSend_Gamepad:DisconnectShownEvent()
    self.control:UnregisterForEvent(EVENT_MAIL_COD_CHANGED)
    self.control:UnregisterForEvent(EVENT_MAIL_ATTACHED_MONEY_CHANGED)
    self.control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function ZO_MailSend_Gamepad:InitializeEvents()
    self.control:RegisterForEvent(EVENT_MAIL_ATTACHMENT_ADDED, function(_, attachSlot) self:OnMailAttachmentAdded(attachSlot) end)
    self.control:RegisterForEvent(EVENT_MAIL_ATTACHMENT_REMOVED, function(_, attachSlot) self:OnMailAttachmentRemoved(attachSlot) end)
    self.control:RegisterForEvent(EVENT_MAIL_SEND_SUCCESS, function() self:OnMailSendSuccess() end)
    self.control:RegisterForEvent(EVENT_MAIL_SEND_FAILED, function(_, ...) self:OnMailSendFailure(...) end)
end

--Global API

function ZO_MailSend_Gamepad:ComposeMailTo(address)
    self.initialContact = address
    local PUSH_SCENE = true
    MAIL_MANAGER_GAMEPAD:ShowTab(SEND_TAB_INDEX, PUSH_SCENE)
end

function ZO_MailSend_Gamepad:IsMailValid()
    local to = self.mailView:GetAddress()
    if (not to) or (to == "") then
        return false
    end
    local subject = self.mailView:GetSubject()
    local hasSubject = subject and (subject ~= "")
    local body = self.mailView:GetBody()
    local hasBody = body and (body ~= "")
    return hasSubject or hasBody or (GetQueuedMoneyAttachment() > 0) or IsAnyItemAttached()
end

function ZO_MailSend_Gamepad:InitializeKeybindDescriptors()
    -- Main list.
    self.mainKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local targetData = self.mainList:GetTargetData()
                if targetData and targetData.actionFunction then
                    targetData:actionFunction()
                end
            end,
            enabled = function()
                local isEnabled = true

                local targetData = self.mainList:GetTargetData()
                local validEntry = self:IsMailValid()

                if targetData and targetData.text == GetString(SI_MAIL_SEND_SEND) then
                    isEnabled = validEntry
                end

                for i = 1, self.mainList:GetNumItems() do
		            local itemData = self.mainList:GetDataForDataIndex(i)
		            if itemData.text and itemData.text == GetString(SI_MAIL_SEND_SEND) then
			            itemData.disabled = not validEntry
			            break
		            end
                end

                return isEnabled
            end,
        },

        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                local targetData = self.mainList:GetTargetData()
                return targetData.secondaryCallbackName
            end,
            callback = function()
                local targetData = self.mainList:GetTargetData()
                targetData:secondaryCallback()
            end,
            visible = function()
                local targetData = self.mainList:GetTargetData()
                return targetData and targetData.secondaryCallback ~= nil
            end,
        },

        -- Clear
        {
            name = GetString(SI_GAMEPAD_MAIL_SEND_CLEAR),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function() ZO_Dialogs_ShowGamepadDialog("CONFIRM_CLEAR_MAIL_COMPOSE", { callback = function() self:ClearFields() end }) end
        },
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.mainKeybindDescriptor, self.mainList)

    -- Slider Edit
    self.sliderKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Accept
        {
            name = GetString(SI_GAMEPAD_MAIL_SEND_ACCEPT_MONEY),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                            if self.goldMode == ATTACHING_GOLD then
                                QueueCOD(0)
                                QueueMoneyAttachment(self.goldSlider:GetValue())
                            elseif self.goldMode == REQUESTING_GOLD then
                                QueueMoneyAttachment(0)
                                QueueCOD(self.goldSlider:GetValue())
                            end
                            PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
                            self:UpdatePostageMoney()
                            self:EnterOutbox()
                            local targetControl = self.mainList:GetTargetControl()
                            targetControl:SetHidden(false)
                       end,
            visible = function() return self.goldSlider:GetValue() <= self.goldSlider:GetMaxValue() end,
        },

        -- Cancel
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                            self.mainList:WhenInactiveSetTargetControlHidden(true)
                            self:UpdateMoneyAttachment()
                            self:EnterOutbox()
                       end),
    }
    
    -- Contacts List
    self.contactsKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Accept
        {
            name = GetString(SI_GAMEPAD_MAIL_SEND_ACCEPT_MONEY),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                            self:EnterOutbox()
                            local selectedItem = self.contactsList:GetTargetData()
                            if selectedItem.actionFunction then
                                selectedItem.actionFunction(selectedItem)
                            end
                            
                       end,
        },

        -- Cancel
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                            self:UpdateMoneyAttachment()
                            self:EnterOutbox()
                       end),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.contactsKeybindDescriptor, self.contactsList)

    -- Inventory
    self.inventoryKeybindDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Add to Mail/Remove from Mail
        {
            name = function()
                        local selectedItem = self.inventoryList:GetTargetData()
                        if IsItemAttached(selectedItem.bagId, selectedItem.slotIndex) then
                            return GetString(SI_GAMEPAD_MAIL_SEND_DETACH_ITEM)
                        else
                            return GetString(SI_GAMEPAD_MAIL_SEND_ATTACH_ITEM)
                        end
                    end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                        local selectedItem = self.inventoryList:GetTargetData()
                        local bagId = selectedItem.bagId
                        local slotIndex = selectedItem.slotIndex
                        local attachedSlotIndex = GetItemAttachedIndex(bagId, slotIndex)
                        if attachedSlotIndex then -- Item is attached, detach it.
                            RemoveQueuedAttachment(attachedSlotIndex)
                            local soundCategory = GetItemSoundCategory(bagId, slotIndex)
	                        PlayItemSound(soundCategory, ITEM_SOUND_ACTION_UNEQUIP)
                        else -- Item is not attached, attach it.
                            attachedSlotIndex = GetNextOpenAttachIndex()
                            if attachedSlotIndex then
                                QueueItemAttachment(bagId, slotIndex, attachedSlotIndex)
                                local soundCategory = GetItemSoundCategory(bagId, slotIndex)
	                            PlayItemSound(soundCategory, ITEM_SOUND_ACTION_EQUIP)
                            end
                        end
                    end,
            visible = function()
                        local selectedItem = self.inventoryList:GetTargetData()
                        if not selectedItem then
                            return false
                        end
                        local bagId = selectedItem.bagId
                        local slotIndex = selectedItem.slotIndex

                        if IsItemAttached(bagId, slotIndex) then
                            return true -- Can always remove an attached item.
                        end

                        local attachedSlotIndex = GetNextOpenAttachIndex()
                        if not attachedSlotIndex then
                            return false
                        end

                        local canAttach = CanQueueItemAttachment(bagId, slotIndex, attachedSlotIndex)
                        return canAttach
                   end,
        },

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                            self:UpdatePostageMoney()
                            self:EnterOutbox()
                       end),
    }
end

local function UpdatePlayerGold(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_MAIL_HEADER_MONEY_OPTIONS_GAMEPAD)
    return true
end

local function UpdatePostage(control)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetQueuedMailPostage(), ZO_MAIL_HEADER_MONEY_OPTIONS_GAMEPAD)
    return true
end

function ZO_MailSend_Gamepad:InitializeHeader()
    self.mainHeaderData = {
            data1HeaderText = GetString(SI_GAMEPAD_MAIL_INBOX_PLAYER_GOLD),
            data1Text = UpdatePlayerGold,

            data2HeaderText = GetString(SI_GAMEPAD_MAIL_SEND_POSTAGE_LABEL),
            data2Text = UpdatePostage,

            tabBarEntries = MAIL_MANAGER_GAMEPAD.tabBarEntries,
        }

    self.setFieldHeaderData = {
            data1HeaderText = GetString(SI_GAMEPAD_MAIL_INBOX_PLAYER_GOLD),
            data1Text = UpdatePlayerGold,

            data2HeaderText = GetString(SI_GAMEPAD_MAIL_SEND_POSTAGE_LABEL),
            data2Text = UpdatePostage,
        }
end

local function InventorySetupFunction(entryData)
    entryData.isMailAttached = IsItemAttached(entryData.bagId, entryData.slotIndex)
    entryData:SetIgnoreTraitInformation(true)
end

local function ItemFilterFunction(entryData)
    local bagId = entryData.bagId
    local slotIndex = entryData.slotIndex
    return (CanQueueItemAttachment(bagId, slotIndex) or IsItemAttached(bagId, slotIndex)) and not entryData.isPlayerLocked
end

local SETUP_LOCALLY = true
function ZO_MailSend_Gamepad:InitializeInventoryList()
    self.inventoryList = MAIL_MANAGER_GAMEPAD:AddList("Inventory", SETUP_LOCALLY, ZO_GamepadInventoryList, BAG_BACKPACK, SLOT_TYPE_ITEM, function(...) self:InventorySelectionChanged(...) end, InventorySetupFunction)
    self.inventoryList:SetItemFilterFunction(ItemFilterFunction)

    self.inventoryListControl = self.inventoryList:GetControl()
end

function ZO_MailSend_Gamepad:AddMainListEntry(text, header, icon, callback, secondaryCallbackName, secondaryCallback)
    local newEntry = ZO_GamepadEntryData:New(text, icon)
    newEntry.actionFunction = callback
    newEntry.secondaryCallbackName = secondaryCallbackName
    newEntry.secondaryCallback = secondaryCallback

    local template
    if header then
        newEntry:SetHeader(header)
        template = "ZO_GamepadMenuEntryTemplateWithHeader"
    else
        template = "ZO_GamepadMenuEntryTemplate"
    end

    newEntry:SetIconTintOnSelection(true)
    self.mainList:AddEntry(template, newEntry)
end

function ZO_MailSend_Gamepad:PopulateMainList()
    local function RefreshKeybind()
		MAIL_MANAGER_GAMEPAD:RefreshKeybind()
	end

	self.mainList:Clear()

    self.onUserListDialogIdSelectedForMailTo = function(hasResult, displayName, consoleId)
        local editControl = self.mailView.addressEdit.edit
        if hasResult then
            editControl:SetText(displayName)
        end
    end

    do
        local userListCallback = function()
            local INCLUDE_ONLINE_FRIENDS = true
            local INCLUDE_OFFLINE_FRIENDS = true
            PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestIdFromUserListDialog(self.onUserListDialogIdSelectedForMailTo, GetString(SI_GAMEPAD_CONSOLE_SELECT_FOR_MAIL), INCLUDE_ONLINE_FRIENDS, INCLUDE_OFFLINE_FRIENDS)
        end

        local editBoxCallback = function()
            self.mailView.addressEdit.edit:TakeFocus()
        end

        local platform = GetUIPlatform()
        if platform == UI_PLATFORM_PS4 then
            self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_SEND_TO), nil, nil, userListCallback)
        elseif platform == UI_PLATFORM_XBOX then
            if(GetNumberConsoleFriends() > 0) then
                self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_SEND_TO), nil, nil, editBoxCallback, GetString(SI_GAMEPAD_CONSOLE_CHOOSE_FRIEND), userListCallback)
            else
                self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_SEND_TO), nil, nil, editBoxCallback, GetString(SI_GAMEPAD_CONSOLE_CHOOSE_FRIEND), nil)
            end
        else
            self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_SEND_TO), nil, nil, editBoxCallback)
        end
    end

    self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_SUBJECT_LABEL), nil, nil, function() self.mailView.subjectEdit.edit:TakeFocus() end)
    self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_BODY_LABEL), nil, nil, function() self.mailView.bodyEdit.edit:TakeFocus() end)
    self:AddMainListEntry(GetString(SI_MAIL_SEND_ATTACH_MONEY), GetString(SI_GAMEPAD_MAIL_SEND_GOLD_HEADER), SEND_GOLD_ICON, function() self:ShowSliderControl(ATTACHING_GOLD, GetQueuedMoneyAttachment(), GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)) end)
    self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_SEND_COD), nil, REQUEST_GOLD_ICON, function() self:ShowSliderControl(REQUESTING_GOLD, GetQueuedCOD(), MAX_PLAYER_CURRENCY) end)

	self.mailView.subjectEdit.edit:SetHandler("OnFocusLost", function(editBox) 
                                                                    RefreshKeybind()
                                                                    ZO_GamepadEditBox_FocusLost(editBox) 
                                                             end)
	self.mailView.addressEdit.edit:SetHandler("OnFocusLost", function(editBox) 
                                                                    RefreshKeybind()
                                                                    ZO_GamepadEditBox_FocusLost(editBox) 
                                                             end)
    self.mailView.bodyEdit.edit:SetHandler("OnFocusLost", function(editBox) 
                                                                    RefreshKeybind()
                                                                    ZO_GamepadEditBox_FocusLost(editBox) 
                                                             end)

    if not self.inventoryList:IsEmpty() then
        self:AddMainListEntry(GetString(SI_GAMEPAD_MAIL_SEND_ATTACH), GetString(SI_GAMEPAD_MAIL_SEND_ITEMS_HEADER), EMPTY_ATTACHMENT_ICON, function() self:EnterInventoryList() end)
    end

    local function AttemptSendMail()
        local to = self.mailView:GetAddress()
        local subject = self.mailView:GetSubject()
        local body = self.mailView:GetBody()
        if IsConsoleUI() then
            ZO_ConsoleAttemptCommunicateOrError(function(success)
                if success then
                    SendMail(to, subject, body)
                    self:EnterSending()
                end
            end, to, ZO_PLAYER_CONSOLE_INFO_REQUEST_BLOCK, ZO_CONSOLE_CAN_COMMUNICATE_ERROR_DIALOG, ZO_ID_REQUEST_TYPE_DISPLAY_NAME, to)
        else
            SendMail(to, subject, body)
            self:EnterSending()
        end
    end
    self:AddMainListEntry(GetString(SI_MAIL_SEND_SEND), GetString(SI_MAIL_SEND_SEND), ZO_GAMEPAD_SUBMIT_ENTRY_ICON, AttemptSendMail)

    self.mainList:Commit()
end

function ZO_MailSend_Gamepad:InitializeMainList()
    self.mainList = MAIL_MANAGER_GAMEPAD:GetMainList()
    self.mainList:SetOnSelectedDataChangedCallback(function(...) self:OnListMovement(...) end)
    self:PopulateMainList()
end

function ZO_MailSend_Gamepad:OnListMovement(list, isMoving)
    self.mailView.addressEdit.edit:LoseFocus()
    self.mailView.subjectEdit.edit:LoseFocus()
    self.mailView.bodyEdit.edit:LoseFocus()

    self:HighlightActiveTextField()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindDescriptor)
end

function ZO_MailSend_Gamepad:HighlightActiveTextField()
    local textFieldToControl =
    {
        [GetString(SI_GAMEPAD_MAIL_SEND_TO)] = self.mailView.addressEdit,
        [GetString(SI_GAMEPAD_MAIL_SUBJECT_LABEL)] = self.mailView.subjectEdit,
        [GetString(SI_GAMEPAD_MAIL_BODY_LABEL)] = self.mailView.bodyEdit
    }

    for _, control in pairs(textFieldToControl) do
        control.highlight:SetHidden(true)
    end

    local currentEditControl = textFieldToControl[self.mainList:GetTargetData().text]
    if currentEditControl then
        currentEditControl.highlight:SetHidden(false)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.mainKeybindDescriptor)
end

function ZO_MailSend_Gamepad:InitializeContactsList()
    self.contactsList = MAIL_MANAGER_GAMEPAD:AddList("Contacts")
    self.contactsListControl = self.contactsList:GetControl()
end

function ZO_MailSend_Gamepad:ClearFields()
    self:Clear()
    self:EnterOutbox()
end

function ZO_MailSend_Gamepad:Reset()
    if (not self.inventoryListControl:IsHidden()) or (not self.goldSliderControl:IsHidden()) or (not self.contactsListControl:IsHidden()) then
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    end
        
    self.goldSliderControl:SetHidden(true)
    self.mainList:WhenInactiveSetTargetControlHidden(false)

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    self.loadingBox:SetHidden(true)

    self.goldSlider:Deactivate()

    self.goldMode = nil
    self.inSendMode = false
end

function ZO_MailSend_Gamepad:SwitchToSendTab()
    MAIL_MANAGER_GAMEPAD:SwitchToHeader(self.mainHeaderData, SEND_TAB_INDEX)
end

function ZO_MailSend_Gamepad:EnterSending()
    self.inSendMode = true
    self:Reset()

    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(nil) -- Remove keybinds as they are invaild when sending.
    self.loadingLabel:SetText(GetString(SI_GAMEPAD_MAIL_SEND_SENDING))
    self.loadingBox:SetHidden(false)
    MAIL_MANAGER_GAMEPAD:SetCurrentList(nil)
end

function ZO_MailSend_Gamepad:EnterOutbox()
    self:Reset()

    if self.inSendMode then
        self:EnterSending()
    else
        self:SwitchToSendTab()
        MAIL_MANAGER_GAMEPAD:SetCurrentList(self.mainList)
        MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.mainKeybindDescriptor)
    end
end

function ZO_MailSend_Gamepad:AddContact(text, header, callback)
    local newEntry = ZO_GamepadEntryData:New(text)
    newEntry.actionFunction = callback

    local template
    if header then
        newEntry:SetHeader(header)
        template = "ZO_GamepadMenuEntryTemplateWithHeader"
    else
        template = "ZO_GamepadMenuEntryTemplate"
    end

    self.contactsList:AddEntry(template, newEntry)
end

local function GetHeaderForName(name)
    for i=1, #name do
        local letter = zo_strlower(string.sub(name, i, i))
        local header = LETTER_GROUPS[letter]
        if header then
            return header
        end
    end
end

local function FriendSort(a,b)
    return a < b
end

local RECIPIENT_HEADER_TEXT = GetString(SI_GAMEPAD_MAIL_SEND_RECIPIENT)

function ZO_MailSend_Gamepad:EnterContactsList()
    local function FillWithName(selectedData)
        self.mailView:Display(nil, nil, selectedData.text)
    end

    self.contactsList:Clear()

    -- Text edit
    self:AddContact(GetString(SI_GAMEPAD_MAIL_SEND_ENTER_NAME), nil, function() self.mailView.addressEdit.edit:TakeFocus() end)
    self.contactsList:Commit()

    self.setFieldHeaderData.titleText = RECIPIENT_HEADER_TEXT
    MAIL_MANAGER_GAMEPAD:SwitchToHeader(self.setFieldHeaderData)
    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.contactsKeybindDescriptor)
    MAIL_MANAGER_GAMEPAD:SetCurrentList(self.contactsList)

    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_MailSend_Gamepad:ShowSliderControl(mode, value, maxValue)
    self.mainList:Deactivate()
    self.mainList:WhenInactiveSetTargetControlHidden(true)

    self.goldSlider:SetMaxValue(maxValue)
    self.goldSlider:SetValue(value)

    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.sliderKeybindDescriptor)
    self.goldSlider:Activate()
    self.goldMode = mode
    self.goldSliderControl:SetHidden(false)

    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

local ATTACHMENT_HEADER_TEXT = GetString(SI_GAMEPAD_MAIL_SEND_ATTACH)

function ZO_MailSend_Gamepad:EnterInventoryList()
    self:Reset()

    self.setFieldHeaderData.titleText = ATTACHMENT_HEADER_TEXT
    MAIL_MANAGER_GAMEPAD:SwitchToHeader(self.setFieldHeaderData)

    MAIL_MANAGER_GAMEPAD:SwitchToKeybind(self.inventoryKeybindDescriptor)
    MAIL_MANAGER_GAMEPAD:SetCurrentList(self.inventoryList)

    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
end

function ZO_MailSend_Gamepad:InventorySelectionChanged(list, inventoryData)
    if MAIL_MANAGER_GAMEPAD:GetCurrentList() == self.inventoryList then
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
        if inventoryData then
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, inventoryData.bagId, inventoryData.slotIndex)
        end
        MAIL_MANAGER_GAMEPAD:RefreshKeybind()
    end
end

function ZO_MailSend_Gamepad:Clear()
    ClearQueuedMail()

    self.mailView:Clear()

    self:UpdateMoneyAttachment()
end

function ZO_MailSend_Gamepad:UpdateMoneyAttachment()
    local queuedCOD = GetQueuedCOD()
    local queuedMoney = GetQueuedMoneyAttachment()
    self.mailView:Display(queuedCOD, queuedMoney)

    self:UpdatePostageMoney()
end

function ZO_MailSend_Gamepad:IsAttachingItems()
    return (not self.sendControl:IsHidden())
end

function ZO_MailSend_Gamepad:UpdatePostageMoney()
    MAIL_MANAGER_GAMEPAD:RefreshHeader()
end

function ZO_MailSend_Gamepad:OnMailAttachmentAdded(attachSlot)
    local bagId, slotIndex, icon, stack = GetQueuedItemAttachmentInfo(attachSlot)
    self.mailView:SetAttachment(attachSlot, stack, icon)
    self:UpdatePostageMoney()
    MAIL_MANAGER_GAMEPAD:RefreshKeybind()
    self.inventoryList:RefreshList()
end

function ZO_MailSend_Gamepad:OnMailAttachmentRemoved(attachSlot)
    self.mailView:ClearAttachment(attachSlot)
    self:UpdatePostageMoney()
    MAIL_MANAGER_GAMEPAD:RefreshKeybind()
    self.inventoryList:RefreshList()
end

function ZO_MailSend_Gamepad:OnMailSendSuccess()
    PlaySound(SOUNDS.MAIL_SENT)
    self.inSendMode = false
    self:Clear()
    if not self.sendControl:IsHidden() then
        self:EnterOutbox()
    end
end

function ZO_MailSend_Gamepad:OnMailSendFailure(failureReason)
    self.inSendMode = false
    if not self.sendControl:IsHidden() then
        self:EnterOutbox()
    end
end

-- XML Handlers

function ZO_MailView_Initialize_Send_Fields_Gamepad(control)
    ZO_EditDefaultText_Initialize(control.addressEdit.edit, GetDefaultAddresseeText())
    ZO_EditDefaultText_Initialize(control.subjectEdit.edit, GetString(SI_MAIL_SUBJECT_DEFAULT_TEXT))
end
