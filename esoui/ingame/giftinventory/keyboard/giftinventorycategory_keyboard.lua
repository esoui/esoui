ZO_GIFT_INVENTORY_KEYBOARD_ROW_HEIGHT = 52

ZO_GiftInventoryCategory_Keyboard = ZO_Object.MultiSubclass(ZO_SortFilterList, ZO_CallbackObject)

function ZO_GiftInventoryCategory_Keyboard:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_GiftInventoryCategory_Keyboard:Initialize(control, tag)
    ZO_SortFilterList.Initialize(self, control)
    self.fragment = ZO_SimpleSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:SetLockedForUpdates(false)
            self:AddKeybinds()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:SetLockedForUpdates(true)
            self:RemoveKeybinds()
            if #self.giftIdsToMarkViewedOnHide > 0 then
                ViewGifts(unpack(self.giftIdsToMarkViewedOnHide))
                ZO_ClearNumericallyIndexedTable(self.giftIdsToMarkViewedOnHide)
            end
        end
    end)

    GIFT_INVENTORY_KEYBOARD:SetCategoryObject(self, control, tag)

    --the gift states that this list shows
    self.listSupportedGiftStates = {}
    self.giftStateToTypeId = {}
    self.giftIdsToMarkViewedOnHide = {}

    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftListsChanged", function(changedLists)
        --find the most extreme change that a state list we are based on experienced
        local highestChangeType = GIFT_INVENTORY_MANAGER:GetHighestChangeType(changedLists, unpack(self.listSupportedGiftStates))
        if highestChangeType == ZO_GIFT_LIST_CHANGE_TYPE_LIST then
            self:RefreshData()
        elseif highestChangeType == ZO_GIFT_LIST_CHANGE_TYPE_SEEN then
            self:RefreshSort()
        end
    end)

    --Only update when visible
    self:SetLockedForUpdates(true)
    self:RefreshData()
end

function ZO_GiftInventoryCategory_Keyboard:AddSupportedGiftState(giftState, typeId, templateName, height, setupCallback)
    table.insert(self.listSupportedGiftStates, giftState)
    self.giftStateToTypeId[giftState] = typeId
    ZO_ScrollList_AddDataType(self.list, typeId, templateName, height, setupCallback)
end

function ZO_GiftInventoryCategory_Keyboard:SetSortFunction(sortFunction)
    self.sortFunction = sortFunction
end

--ZO_SortFilterList Overrides

function ZO_GiftInventoryCategory_Keyboard:BuildMasterList()
    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    for _, giftState in ipairs(self.listSupportedGiftStates) do
        local giftList = GIFT_INVENTORY_MANAGER:GetGiftList(giftState)
        local typeId = self.giftStateToTypeId[giftState]
        for _, gift in ipairs(giftList) do
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(typeId, gift))
        end
    end
end

function ZO_GiftInventoryCategory_Keyboard:SortScrollList()
    if self.sortFunction then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end
end

function ZO_GiftInventoryCategory_Keyboard:SetupRow(control, gift)
    ZO_SortFilterList.SetupRow(self, control, gift)
    control.gift = gift
    if gift:CanMarkViewedFromList() then
        local giftId = gift:GetGiftId()
        if not ZO_IsElementInNumericallyIndexedTable(self.giftIdsToMarkViewedOnHide, giftId) then
            table.insert(self.giftIdsToMarkViewedOnHide, giftId)
        end
    end
end

function ZO_GiftInventoryCategory_Keyboard:SetupStackCount(control, gift)
    local stackCountLabel = control:GetNamedChild("StackCount")
    local unitStackCount = gift:GetStackCount()
    local quantity = gift:GetQuantity()
    local stackCount = unitStackCount * quantity
    if stackCount > 1 then
        stackCountLabel:SetHidden(false)
        stackCountLabel:SetText(stackCount)
    else
        stackCountLabel:SetHidden(true)
    end
end

function ZO_GiftInventoryCategory_Keyboard:EnterRow(row)
    ZO_SortFilterList.EnterRow(self, row)
    if not self.lockedForUpdates then
        local iconTexture = row:GetNamedChild("Icon")
        ZO_InventorySlot_SetControlScaledUp(iconTexture, true)
        ZO_InventorySlot_SetHighlightHidden(row, false)
    end
end

function ZO_GiftInventoryCategory_Keyboard:ExitRow(row)
    ZO_SortFilterList.ExitRow(self, row)
    if not self.lockedForUpdates then
        local iconTexture = row:GetNamedChild("Icon")
        ZO_InventorySlot_SetControlScaledUp(iconTexture, false)
        ZO_InventorySlot_SetHighlightHidden(row, true)
    end
end

--End ZO_SortFilterList Overrides

function ZO_GiftInventoryCategory_Keyboard:Row_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        local gift = control.gift
        local displayName = gift:GetPlayerName()

        ClearMenu()

        if IsChatSystemAvailableForCurrentPlatform() then
            AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE), function() StartChatInput("", CHAT_CHANNEL_WHISPER, displayName) end)
        end
        AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), function() MAIL_SEND:ComposeMailTo(displayName) end)
        if not IsFriend(displayName) then
            AddMenuItem(GetString(SI_SOCIAL_MENU_ADD_FRIEND), function() ZO_Dialogs_ShowDialog("REQUEST_FRIEND", {name = displayName}) end)
        end
        if not IsIgnored(displayName) then
            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(displayName) end)
        end

        self:ShowMenu(control)
    end
end

function ZO_GiftInventoryCategory_Keyboard_NoteTexture_OnMouseEnter(control)
    ZO_PropagateHandler(control:GetParent(), "OnMouseEnter")
    local gift = control:GetParent().gift
    local note = gift:GetNote()
    InitializeTooltip(InformationTooltip, control, RIGHT, -2, 0)
    SetTooltipText(InformationTooltip, note)
end

function ZO_GiftInventoryCategory_Keyboard_NoteTexture_OnMouseExit(control)
    ZO_PropagateHandler(control:GetParent(), "OnMouseExit")
    ClearTooltip(InformationTooltip)
end

function ZO_GiftInventoryCategory_Keyboard_NoteButton_OnMouseEnter(control)
    ZO_PropagateHandler(control:GetParent(), "OnMouseEnter")
    local gift = control:GetParent().gift
    InitializeTooltip(InformationTooltip, control, RIGHT, -2, 0)
    SetTooltipText(InformationTooltip, zo_strformat(SI_GIFT_INVENTORY_KEYBOARD_THANK_YOU_NOTE, gift:GetPlayerName()))
end

function ZO_GiftInventoryCategory_Keyboard_NoteButton_OnMouseExit(control)
    ZO_PropagateHandler(control:GetParent(), "OnMouseExit")
    ClearTooltip(InformationTooltip)
end

function ZO_GiftInventoryCategory_Keyboard_NoteButton_OnClicked(control)
    local gift = control:GetParent().gift
    GIFT_INVENTORY_VIEW_KEYBOARD:SetupAndShowGift(gift)
end

function ZO_GiftInventoryCategory_Keyboard:Show()
    SCENE_MANAGER:AddFragment(self.fragment)
end

function ZO_GiftInventoryCategory_Keyboard:Hide()
    SCENE_MANAGER:RemoveFragment(self.fragment)
end