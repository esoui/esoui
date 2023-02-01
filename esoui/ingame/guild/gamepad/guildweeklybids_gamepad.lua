ZO_GuildWeeklyBids_Gamepad = ZO_Object.MultiSubclass(ZO_GuildWeeklyBids_Shared, ZO_GamepadInteractiveSortFilterList, ZO_SocialOptionsDialogGamepad)

function ZO_GuildWeeklyBids_Gamepad:New(...)
    return ZO_GamepadInteractiveSortFilterList.New(self, ...)
end

function ZO_GuildWeeklyBids_Gamepad:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    ZO_SocialOptionsDialogGamepad.Initialize(self)
    ZO_GuildWeeklyBids_Shared.Initialize(self, "ZO_GuildWeeklyBidsRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT)

    self:SetAutomaticallyColorRows(false)
end

function ZO_GuildWeeklyBids_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption, ZO_SocialOptionsDialogGamepad.ShouldAddWhisperOption)
end

function ZO_GuildWeeklyBids_Gamepad:InitializeHeader()
    local contentHeaderData = 
    {
        titleText = GetString(SI_GUILD_WEEKLY_BIDS_TITLE),
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_KIOSK_WEEKLY_BIDS),
        data2HeaderText = "",
        data3HeaderText = "",
    }
    ZO_GamepadInteractiveSortFilterList.InitializeHeader(self, contentHeaderData)
end

function ZO_GuildWeeklyBids_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor = {}
    self:AddSocialOptionsKeybind(self.keybindStripDescriptor)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())

    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)
end

function ZO_GuildWeeklyBids_Gamepad:GetBackKeybindCallback()
    return function()
        GAMEPAD_GUILD_HUB:SetEnterInSingleGuildList(true)
        SCENE_MANAGER:HideCurrentScene()
    end
end

function ZO_GuildWeeklyBids_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.OnSelectionChanged(self, oldData, newData)
    self:UpdateKeybinds()
    self:SetupOptions(newData)
end

function ZO_GuildWeeklyBids_Gamepad:OnShowing()
    ZO_GamepadInteractiveSortFilterList.OnShowing(self)
    GAMEPAD_GUILD_HOME:SetHeaderHidden(true)
    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(true)
    self:Activate()
    self:TryQueryNewInformation()
    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GUILD_WEEKLY_BIDS_INSTRUCTIONS))

    self.onPermissionChanged = function(event, guildId)
        if guildId == self.guildId then
            if not DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_GUILD_KIOSK_BID) then
                local exitScreenCallback = self:GetBackKeybindCallback()
                exitScreenCallback()
            end
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_GuildWeeklyBids_Gamepad", EVENT_GUILD_PLAYER_RANK_CHANGED, self.onPermissionChanged)
end

function ZO_GuildWeeklyBids_Gamepad:OnHidden()
    ZO_GamepadInteractiveSortFilterList.OnHidden(self)
    GAMEPAD_GUILD_HOME:SetHeaderHidden(false)
    GAMEPAD_GUILD_HOME:SetContentHeaderHidden(false)
    self:Deactivate()
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
    EVENT_MANAGER:UnregisterForEvent("ZO_GuildWeeklyBids_Gamepad", EVENT_GUILD_PLAYER_RANK_CHANGED, self.onPermissionChanged)
end

function ZO_GuildWeeklyBids_Gamepad:SetGuildId(guildId)
    self.guildId = guildId
end

function ZO_GuildWeeklyBids_Gamepad:SetWeeklyBidLimitText(text)
    local contentHeaderData = self:GetContentHeaderData()
    contentHeaderData.data1Text = text
    self:RefreshHeader()
end

function ZO_GuildWeeklyBids_Gamepad:GetNarrationText()
    local narrations = {}
    local entryData = self:GetSelectedData()
    if entryData then
        if entryData.order then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_WEEKLY_BIDS_HEADER_ORDER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.order))
        end

        if entryData.kioskName then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_WEEKLY_BIDS_HEADER_TRADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.kioskName))
        end

        if entryData.displayName then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_WEEKLY_BIDS_HEADER_PLACED_BY)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_FormatUserFacingDisplayName(entryData.displayName)))
        end

        if entryData.bidAmount then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_WEEKLY_BIDS_HEADER_BID_AMOUNT)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_Currency_FormatGamepad(CURT_MONEY, entryData.bidAmount, ZO_CURRENCY_FORMAT_AMOUNT_NAME)))
        end
    end

    return narrations
end

function ZO_GuildWeeklyBids_Gamepad:GetFooterNarration()
    return GAMEPAD_GUILD_HOME:GetFooterNarrationText()
end

function ZO_GuildWeeklyBidsTopLevel_Gamepad_OnInitialized(self)
    GUILD_WEEKLY_BIDS_GAMEPAD = ZO_GuildWeeklyBids_Gamepad:New(self)
end