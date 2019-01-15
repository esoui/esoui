
-----------------
--Friends Manager
-----------------

local ZO_KeyboardFriendsListManager = ZO_SocialListKeyboard:Subclass()

function ZO_KeyboardFriendsListManager:New(...)
    return ZO_SocialListKeyboard.New(self, ...)
end

function ZO_KeyboardFriendsListManager:Initialize(control)
    ZO_SocialListKeyboard.Initialize(self, control)
    FRIENDS_LIST_MANAGER:AddList(self)

    control:SetHandler("OnEffectivelyHidden", function() self:OnEffectivelyHidden() end)
    self.lastUpdateTime = 0

    self:SetEmptyText(GetString(SI_FRIENDS_LIST_PANEL_NO_FRIENDS_MESSAGE))
    self.sortHeaderGroup:SelectHeaderByKey("status")

    self.emptyRowMessage = GetControl(self.emptyRow, "Message")

    ZO_ScrollList_AddDataType(self.list, FRIEND_DATA, "ZO_FriendsListRow", 30, function(control, data) self:SetupRow(control, data) end)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

    self.searchBox = GetControl(control, "SearchBox")
    self.searchBox:SetHandler("OnTextChanged", function() self:OnSearchTextChanged() end)

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareFriends(listEntry1, listEntry2) end

    self.hideOfflineCheckBox = GetControl(control, "HideOffline")
        
    FRIENDS_LIST_SCENE = ZO_Scene:New("friendsList", SCENE_MANAGER)
    FRIENDS_LIST_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.staticKeybindStripDescriptor)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self:UpdateHideOfflineCheckBox(self.hideOfflineCheckBox)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.staticKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)

    FRIENDS_LIST_FRAGMENT = ZO_FadeSceneFragment:New(control)
    self:InitializeDirtyLogic(FRIENDS_LIST_FRAGMENT)
end

function ZO_KeyboardFriendsListManager:PerformDeferredInitialization()
    if self.staticKeybindStripDescriptor ~= nil then return end
    self:RefreshData()
    self:InitializeKeybindDescriptors()
end

function ZO_KeyboardFriendsListManager:InitializeKeybindDescriptors()
    self.staticKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Add Friend
        {
            name = GetString(SI_FRIENDS_LIST_PANEL_ADD_FRIEND),
            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                ZO_Dialogs_ShowDialog("REQUEST_FRIEND")
            end,
        },
    }
    
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Whisper
        {
            name = GetString(SI_SOCIAL_LIST_PANEL_WHISPER),
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                StartChatInput("", CHAT_CHANNEL_WHISPER, data.displayName)
            end,

            visible = function()
                if(self.mouseOverRow and IsChatSystemAvailableForCurrentPlatform()) then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    return data.hasCharacter and data.online
                end
                return false
            end
        },

        -- Invite to Group
        {
            name = GetString(SI_FRIENDS_LIST_PANEL_INVITE),
            keybind = "UI_SHORTCUT_TERTIARY",
        
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                local NOT_SENT_FROM_CHAT = false
                local DISPLAY_INVITED_MESSAGE = true
                TryGroupInviteByName(data.characterName, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE)
            end,

            visible = function()
                if IsGroupModificationAvailable() and self.mouseOverRow then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    if data.hasCharacter and data.online then
                        return true
                    end
                end
                return false
            end
        },
    }    
end

function ZO_KeyboardFriendsListManager:OnEffectivelyHidden()
    ZO_Dialogs_ReleaseDialog("REQUEST_FRIEND")
end

function ZO_KeyboardFriendsListManager:OnNumOnlineChanged()
    if(FRIENDS_ONLINE) then
        FRIENDS_ONLINE:Update()
    end
end

function ZO_KeyboardFriendsListManager:OnNumTotalFriendsChanged()
    if(FRIENDS_ONLINE) then
        FRIENDS_ONLINE:Update()
    end
end

--Local XML
--------------

function ZO_KeyboardFriendsListManager:FriendsButton_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)
    SetTooltipText(InformationTooltip, zo_strformat(SI_FRIENDS_ONLINE_TOOLTIP, FRIENDS_LIST_MANAGER:GetNumOnline(), GetNumFriends()))
end

function ZO_KeyboardFriendsListManager:FriendsButton_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_KeyboardFriendsListManager:FriendsButton_OnClicked(control)
    if(not ZO_Dialogs_IsShowingDialog()) then
        MAIN_MENU_KEYBOARD:ShowScene("friendsList")
    end
end

-----------------
-- Overrides from ZO_SortFilterList

function ZO_KeyboardFriendsListManager:BuildMasterList()
    -- The master list lives in the FRIENDS_LIST_MANAGER and is built there
end

function ZO_KeyboardFriendsListManager:FilterScrollList()
  
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)
    
    local searchTerm = self:GetSearchTerm()
	local hideOffline = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE)

    local masterList = FRIENDS_LIST_MANAGER:GetMasterList()
    for i = 1, #masterList do
        local data = masterList[i]
        if(searchTerm == "" or FRIENDS_LIST_MANAGER:IsMatch(searchTerm, data)) then
			if not hideOffline or data.online then
				table.insert(scrollData, ZO_ScrollList_CreateDataEntry(FRIEND_DATA, data))
			end
        end
    end
	
	local emptyText = ""
	if #masterList > 0 then
		if searchTerm ~= "" then
			emptyText = GetString(SI_SORT_FILTER_LIST_NO_RESULTS)
		else
			emptyText = GetString(SI_FRIENDS_LIST_ALL_FRIENDS_OFFLINE)
		end
	else
		emptyText = GetString(SI_FRIENDS_LIST_PANEL_NO_FRIENDS_MESSAGE)
	end
	self.emptyRowMessage:SetText(emptyText) 
end

function ZO_KeyboardFriendsListManager:SortScrollList()
    if(self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end

    self:RefreshVisible()
end

function ZO_KeyboardFriendsListManager:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    FRIENDS_LIST_MANAGER:SetupEntry(control, data) 
end

function ZO_KeyboardFriendsListManager:GetSearchTerm()
    return self.searchBox:GetText()
end

function ZO_KeyboardFriendsListManager:CompareFriends(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, FRIENDS_LIST_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_KeyboardFriendsListManager:FriendsListRow_OnMouseUp(control, button, upInside)
    if(button == MOUSE_BUTTON_INDEX_RIGHT and upInside) then
        ClearMenu()

        local data = ZO_ScrollList_GetData(control)
        if data then
            if(data.hasCharacter and data.online) then
                if IsChatSystemAvailableForCurrentPlatform() then
                    AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE), function() StartChatInput("", CHAT_CHANNEL_WHISPER, data.displayName) end)
                end
                if IsGroupModificationAvailable() then
                    AddMenuItem(GetString(SI_SOCIAL_MENU_INVITE), function() 
                        local NOT_SENT_FROM_CHAT = false
                        local DISPLAY_INVITED_MESSAGE = true
                        TryGroupInviteByName(data.characterName, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE) 
                    end)
                end
                AddMenuItem(GetString(SI_SOCIAL_MENU_JUMP_TO_PLAYER), function() JumpToFriend(data.displayName) end)
            end

            AddMenuItem(GetString(SI_SOCIAL_MENU_VISIT_HOUSE), function() JumpToHouse(data.displayName) end)

            AddMenuItem(GetString(SI_SOCIAL_MENU_EDIT_NOTE),    function()
                                                                    ZO_Dialogs_ShowDialog("EDIT_NOTE", {displayName = data.displayName, note = data.note, changedCallback = FRIENDS_LIST_MANAGER:GetNoteEditedFunction()})
                                                                end)
            local function SendMailCallback()
                if not IsUnitDead("player") then
                    MAIL_SEND:ComposeMailTo(data.displayName)
                else
                    ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
                end
            end
            AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), SendMailCallback)
            
            AddMenuItem(GetString(SI_FRIEND_MENU_REMOVE_FRIEND), function() ZO_Dialogs_ShowDialog("CONFIRM_REMOVE_FRIEND", {displayName = data.displayName}, {mainTextParams = {data.displayName}}) end)
            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(data.displayName) end)
        
            self:ShowMenu(control)
        end
    end
end

function ZO_KeyboardFriendsListManager:OnSearchTextChanged()
    ZO_EditDefaultText_OnTextChanged(self.searchBox)
    self:RefreshFilters()
end

function ZO_KeyboardFriendsListManager:UnlockSelection()
    ZO_SortFilterList.UnlockSelection(self)
    self:RefreshVisible()
end



--Global XML
---------------

function ZO_FriendsListRow_OnMouseEnter(control)
    FRIENDS_LIST:Row_OnMouseEnter(control)
end

function ZO_FriendsListRow_OnMouseExit(control)
    FRIENDS_LIST:Row_OnMouseExit(control)
end

function ZO_FriendsListRow_OnMouseUp(control, button, upInside)
    FRIENDS_LIST:FriendsListRow_OnMouseUp(control, button, upInside)
end

function ZO_FriendsListRowNote_OnMouseEnter(control)
    FRIENDS_LIST:Note_OnMouseEnter(control)
end

function ZO_FriendsListRowNote_OnMouseExit(control)
    FRIENDS_LIST:Note_OnMouseExit(control)
end

function ZO_FriendsListRowNote_OnClicked(control)
    FRIENDS_LIST:Note_OnClicked(control, FRIENDS_LIST_MANAGER:GetNoteEditedFunction())
end

function ZO_FriendsListRowDisplayName_OnMouseEnter(control)
    FRIENDS_LIST:DisplayName_OnMouseEnter(control)
end

function ZO_FriendsListRowDisplayName_OnMouseExit(control)
    FRIENDS_LIST:DisplayName_OnMouseExit(control)
end

function ZO_FriendsListRowAlliance_OnMouseEnter(control)
    FRIENDS_LIST:Alliance_OnMouseEnter(control)
end

function ZO_FriendsListRowAlliance_OnMouseExit(control)
    FRIENDS_LIST:Alliance_OnMouseExit(control)
end

function ZO_FriendsListRowStatus_OnMouseEnter(control)
    FRIENDS_LIST:Status_OnMouseEnter(control)
end

function ZO_FriendsListRowStatus_OnMouseExit(control)
    FRIENDS_LIST:Status_OnMouseExit(control)
end

function ZO_FriendsListRowClass_OnMouseEnter(control)
    FRIENDS_LIST:Class_OnMouseEnter(control)
end

function ZO_FriendsListRowClass_OnMouseExit(control)
    FRIENDS_LIST:Class_OnMouseExit(control)
end

function ZO_FriendsListRowChampion_OnMouseEnter(control)
    FRIENDS_LIST:Champion_OnMouseEnter(control)
end

function ZO_FriendsListRowChampion_OnMouseExit(control)
    FRIENDS_LIST:Champion_OnMouseExit(control)
end

function ZO_FriendsList_OnInitialized(self)
    FRIENDS_LIST = ZO_KeyboardFriendsListManager:New(self)
end

function ZO_FriendsList_ToggleHideOffline(self)
    FRIENDS_LIST:HideOffline_OnClicked()
end