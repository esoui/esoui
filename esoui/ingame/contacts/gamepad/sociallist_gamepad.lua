--Layout consts, defining the widths of the list's columns as provided by design--
ZO_GAMEPAD_SOCIAL_LIST_STATUS_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_SOCIAL_LIST_CLASS_WIDTH = 100 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_SOCIAL_LIST_ALLIANCE_WIDTH = 110 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_SOCIAL_LIST_LEVEL_WIDTH = 140 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_SOCIAL_LIST_CHAMPION_POINTS_ICON_OFFSET_X = 20

-----------------
-- Social List
-----------------

ZO_GamepadSocialListPanel = ZO_Object.MultiSubclass(ZO_GamepadInteractiveSortFilterList, ZO_SocialOptionsDialogGamepad)

function ZO_GamepadSocialListPanel:New(...)
    return ZO_GamepadInteractiveSortFilterList.New(self, ...)
end

function ZO_GamepadSocialListPanel:Initialize(control, socialManager, rowTemplate)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    ZO_SocialOptionsDialogGamepad.Initialize(self)
    self.socialManager = socialManager
    ZO_ScrollList_AddDataType(self.list, ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, rowTemplate, ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(control, data) self:SetupRow(control, data) end)
    self:SetMasterList(socialManager:GetMasterList())
    socialManager:AddList(self)
end

function ZO_GamepadSocialListPanel:InitializeSearchFilter()
    ZO_GamepadInteractiveSortFilterList.InitializeSearchFilter(self)

    ZO_EditDefaultText_Initialize(self.searchEdit, ZO_GetPlatformAccountLabel())
end

function ZO_GamepadSocialListPanel:Deactivate()
    ZO_GamepadInteractiveSortFilterList.Deactivate(self)
    self:ClearTooltip()
end

function ZO_GamepadSocialListPanel:ClearTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:HideBg(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GamepadSocialListPanel:RefreshTooltip()
    local data = self:GetSelectedData()

    if data and (zo_strlen(data.characterName) > 0) then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        GAMEPAD_TOOLTIPS:SetBottomRailHidden(GAMEPAD_RIGHT_TOOLTIP, true)
        self:LayoutTooltip(GAMEPAD_TOOLTIPS, GAMEPAD_RIGHT_TOOLTIP, data)
        GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_RIGHT_TOOLTIP)
    else
        self:ClearTooltip()
    end
end

function ZO_GamepadSocialListPanel:LayoutTooltip(tooltipManager, tooltip, data)
    -- This function is meant to be overridden in subclasses to display the appropriate toolip information
end

function ZO_GamepadSocialListPanel:EntrySelectionCallback(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.EntrySelectionCallback(self, oldData, newData)
    self:SetupOptions(newData)
    self:RefreshTooltip()
end

function ZO_GamepadSocialListPanel:SetupRow(control, data)
    self:ColorRow(control, data)
    self.socialManager:SetupEntry(control, data)
end

function ZO_GamepadSocialListPanel:ColorRow(control, data, selected)
    local textColor, iconColor, textColor2 = self:GetRowColors(data, selected)
    ZO_SocialList_ColorRow(control, data, textColor, iconColor, textColor2)
end

function ZO_GamepadSocialListPanel:GetRowColors(data, selected)
    local textColor = data.online and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT
    local textColor2 = ZO_SELECTED_TEXT
    local iconColor = ZO_SELECTED_TEXT

    return textColor, iconColor, textColor2
end

function ZO_GamepadSocialListPanel:InitializeKeybinds()
    local keybindDescriptor = {}
    self:AddSocialOptionsKeybind(keybindDescriptor)
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(keybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())
    self:SetKeybindStripDescriptor(keybindDescriptor)
    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)
    
    local addKeybind = self:GetAddKeybind()
    if addKeybind then
        self:AddUniversalKeybind(addKeybind)
    end

	local hideOfflineKeybind = 
	{
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		name = function()
			if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE) then
				return GetString(SI_SOCIAL_LIST_SHOW_OFFLINE)
			else
				return GetString(SI_SOCIAL_LIST_HIDE_OFFLINE)
			end
		end,
		keybind = "UI_SHORTCUT_RIGHT_STICK",
		callback = function()
			SetSetting(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE, tostring(not GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE)))
			self:RefreshFilters()
			self:UpdateKeybinds()
		end,
	}
	self:AddUniversalKeybind(hideOfflineKeybind)
end

function ZO_GamepadSocialListPanel:InitializeDropdownFilter()
    ZO_GamepadInteractiveSortFilterList.InitializeDropdownFilter(self)

    for i = 1, GetNumPlayerStatuses() do
        local function StatusSelect()
            self:AttemptStatusUpdate(i, GetFrameTimeSeconds())
        end

        local statusTexture = GetGamepadPlayerStatusIcon(i)
        local text = zo_strformat(SI_GAMEPAD_GUILD_STATUS_SELECTOR_FORMAT, statusTexture, GetString("SI_PLAYERSTATUS", i))
        local entry = ZO_ComboBox:CreateItemEntry(text, StatusSelect)
        self.filterDropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
    end

    local function CachedStatusUpdate(_, currentFrameTimeSeconds)
        if self.cachedUpdateStatus then
            self:AttemptStatusUpdate(self.cachedUpdateStatus, currentFrameTimeSeconds)
        end
    end
    self.control:SetHandler("OnUpdate", CachedStatusUpdate)

    self.control:RegisterForEvent(EVENT_PLAYER_STATUS_CHANGED, function(_, oldStatus, newStatus) self:UpdateStatusDropdownSelection(newStatus) end)
end

function ZO_GamepadSocialListPanel:GetAddKeybind()
    -- this function is meant be overridden in a subclass
end

function ZO_GamepadSocialListPanel:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local searchTerm = self:GetCurrentSearch()
	local hideOffline = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE)
    
    for _, data in ipairs(self.masterList) do
        if(searchTerm == "" or self:IsMatch(searchTerm, data)) then
			if not hideOffline or data.online then
				table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, data))
			end
        end
    end
end

function ZO_GamepadSocialListPanel:OnFilterDeactivated()
    --Do nothing
end

function ZO_GamepadSocialListPanel:OnShowing()
    self:UpdateStatusDropdownSelection()
end

function ZO_GamepadSocialListPanel:OnHidden()
    self:ForceStatusUpdate()
end

do
    local STATUS_UPDATE_DELAY = 1

    function ZO_GamepadSocialListPanel:AttemptStatusUpdate(status, currentTime)
        if not self.lastStatusUpdateTime then
            self.lastStatusUpdateTime = -STATUS_UPDATE_DELAY
        end

        self.cachedUpdateStatus = status

        if self.lastStatusUpdateTime + STATUS_UPDATE_DELAY <= currentTime then
            self:ForceStatusUpdate()
            self.lastStatusUpdateTime = currentTime
        end
    end
end

function ZO_GamepadSocialListPanel:ForceStatusUpdate()
    if self.cachedUpdateStatus then
        SelectPlayerStatus(self.cachedUpdateStatus)
        self.cachedUpdateStatus = nil
    end
end

function ZO_GamepadSocialListPanel:UpdateStatusDropdownSelection(status)
    local IGNORE_CALLBACK = true
    status = status or GetPlayerStatus()
    self.filterDropdown:SelectItemByIndex(status, IGNORE_CALLBACK)
end

function ZO_GamepadSocialListPanel:BuildGuildInviteOption(header, guildId)
    local inviteFunction = function()
            ZO_TryGuildInvite(guildId, self.socialData.displayName)
        end

    return self:BuildOptionEntry(header, GetGuildName(guildId), inviteFunction, nil, GetLargeAllianceSymbolIcon(GetGuildAlliance(guildId)))
end

function ZO_GamepadSocialListPanel:AddInviteToGuildOptionTemplates()
    local guildCount = GetNumGuilds()

    if guildCount > 0 then
        local guildInviteGroupingId = self:AddOptionTemplateGroup(function() return GetString(SI_GAMEPAD_CONTACTS_INVITE_TO_GUILD_HEADER) end)

        for i = 1, guildCount do
            local guildId = GetGuildId(i)

            local buildFunction = function() return self:BuildGuildInviteOption(nil, guildId) end
            local visibleFunction = function() return not self.socialData.isPlayer and DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_INVITE) end

            self:AddOptionTemplate(guildInviteGroupingId, buildFunction, visibleFunction)
        end
    end
end