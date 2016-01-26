local EVENT_NAMESPACE = "KeyboardNotifications"

local KEYBOARD_NOTIFICATION_ICONS =
{
    [NOTIFICATION_TYPE_FRIEND] = "EsoUI/Art/Notifications/notificationIcon_friend.dds",
    [NOTIFICATION_TYPE_GUILD] = "EsoUI/Art/Notifications/notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_GUILD_MOTD] = "EsoUI/Art/Notifications/notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_CAMPAIGN_QUEUE] = "EsoUI/Art/Notifications/notificationIcon_campaignQueue.dds",
    [NOTIFICATION_TYPE_RESURRECT] = "EsoUI/Art/Notifications/notificationIcon_resurrect.dds",
    [NOTIFICATION_TYPE_GROUP] = "EsoUI/Art/Notifications/notificationIcon_group.dds",
    [NOTIFICATION_TYPE_TRADE] = "EsoUI/Art/Notifications/notificationIcon_trade.dds",
    [NOTIFICATION_TYPE_QUEST_SHARE] = "EsoUI/Art/Notifications/notificationIcon_quest.dds",
    [NOTIFICATION_TYPE_PLEDGE_OF_MARA] = "EsoUI/Art/Notifications/notificationIcon_mara.dds",
    [NOTIFICATION_TYPE_CUSTOMER_SERVICE] = "EsoUI/Art/Notifications/notification_cs.dds",
    [NOTIFICATION_TYPE_LEADERBOARD] = "EsoUI/Art/Notifications/notificationIcon_leaderboard.dds",
    [NOTIFICATION_TYPE_COLLECTIONS] = "EsoUI/Art/Notifications/notificationIcon_collections.dds",
    [NOTIFICATION_TYPE_LFG] = "EsoUI/Art/Notifications/notificationIcon_group.dds",
    [NOTIFICATION_TYPE_POINTS_RESET] = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds",
}

-- Provider Overrides
-------------------------

-- Friend Request Provier
-------------------------

local ZO_KeyboardFriendRequestProvider = ZO_FriendRequestProvider:Subclass()

function ZO_KeyboardFriendRequestProvider:New(notificationManager)
    local provider = ZO_FriendRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardFriendRequestProvider:CreateMessage(displayName)
    return zo_strformat(SI_FRIEND_REQUEST_MESSAGE, displayName)
end

function ZO_KeyboardFriendRequestProvider:Decline(data, button, openedFromKeybind)
    ClearMenu()

    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_DECLINE), function()
                                                                RejectFriendRequest(data.displayName)
                                                                PlaySound(SOUNDS.DIALOG_DECLINE)
                                                             end)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_IGNORE_PLAYER), function()
                                                                    AddIgnore(data.displayName)
                                                                    PlaySound(SOUNDS.DEFAULT_CLICK)
                                                                   end)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_REPORT_SPAMMING), function() ZO_FEEDBACK:ReportPlayer(data.displayName, REPORT_PLAYER_REASON_FRIEND_REQUEST_SPAM) end)

    if(openedFromKeybind == NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND) then
        self.notificationManager.sortFilterList:ShowMenu(button, 1)
    else
        self.notificationManager.sortFilterList:ShowMenu(button)
    end
end

-- Guild Invite Request Provier
-------------------------

local ZO_KeyboardGuildInviteProvider = ZO_GuildInviteProvider:Subclass()

function ZO_KeyboardGuildInviteProvider:New(notificationManager)
    local provider = ZO_GuildInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardGuildInviteProvider:CreateMessage(guildAlliance, guildName, inviterDisplayName)
    local allianceIcon = zo_iconFormat(GetAllianceBannerIcon(guildAlliance), 24, 24)
    return zo_strformat(SI_GUILD_INVITE_MESSAGE, allianceIcon, guildName, inviterDisplayName)
end


function ZO_KeyboardGuildInviteProvider:Decline(data, button, openedFromKeybind)
    ClearMenu()

    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_DECLINE), function() RejectGuildInvite(data.guildId) end)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_IGNORE_PLAYER), function() AddIgnore(data.displayName) end)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_REPORT_SPAMMING), function() ZO_FEEDBACK:ReportPlayer(data.displayName, REPORT_PLAYER_REASON_GUILD_REQUEST_SPAM) end)

    if(openedFromKeybind == NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND) then
        self.notificationManager.sortFilterList:ShowMenu(button, 1)
    else
        self.notificationManager.sortFilterList:ShowMenu(button)
    end
end

--Campaign Queue Provider
-------------------------

local ZO_KeyboardCampaignQueueProvider = ZO_CampaignQueueProvider:Subclass()

function ZO_KeyboardCampaignQueueProvider:New(notificationManager)
    local provider = ZO_CampaignQueueProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardCampaignQueueProvider:CreateMessageFormat(isGroup)
    return isGroup and SI_CAMPAIGN_QUEUE_MESSAGE_GROUP or SI_CAMPAIGN_QUEUE_MESSAGE_INDIVIDUAL
end

function ZO_KeyboardCampaignQueueProvider:CreateLoadText()
    return GetString(SI_CAMPAIGN_ENTER_MESSAGE)
end

function ZO_KeyboardCampaignQueueProvider:Accept(data)
    ZO_Dialogs_ShowPlatformDialog("CAMPAIGN_QUEUE_READY", {campaignId = data.campaignId, isGroup = data.isGroup}, {mainTextParams = {data.campaignName}})
end

--Resurrect Provider
-------------------------
local ZO_KeyboardResurrectProvider = ZO_ResurrectProvider:Subclass()

function ZO_KeyboardResurrectProvider:New(notificationManager)
    local provider = ZO_ResurrectProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardResurrectProvider:GetMessageFormat()
    return SI_RESURRECT_MESSAGE
end

function ZO_KeyboardResurrectProvider:GetNameToShow(resurrectRequesterCharacterName, resurrectRequesterDisplayName)
    return resurrectRequesterCharacterName
end

--Group Invite Provider
-------------------------
local ZO_KeyboardGroupInviteProvider = ZO_GroupInviteProvider:Subclass()

function ZO_KeyboardGroupInviteProvider:New(notificationManager)
    local provider = ZO_GroupInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardGroupInviteProvider:CreateMessage(inviterName)
    return zo_strformat(SI_GROUP_INVITE_MESSAGE, inviterName)
end


--Trade Invite Provider
-------------------------

local ZO_KeyboardTradeInviteProvider = ZO_TradeInviteProvider:Subclass()

function ZO_KeyboardTradeInviteProvider:New(notificationManager)
    local provider = ZO_TradeInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardTradeInviteProvider:CreateMessage(inviterName)
    return zo_strformat(SI_TRADE_INVITE_MESSAGE, inviterName)
end



--Quest Share Provider
-------------------------

local ZO_KeyboardQuestShareProvider = ZO_QuestShareProvider:Subclass()

function ZO_KeyboardQuestShareProvider:New(notificationManager)
    local provider = ZO_QuestShareProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardQuestShareProvider:CreateMessage(characterName, displayName, questName)
    return zo_strformat(SI_QUEST_SHARE_MESSAGE, characterName, questName)
end



--Pledge of Mara Provider
-------------------------

local ZO_KeyboardPledgeOfMaraProvider = ZO_PledgeOfMaraProvider:Subclass()

function ZO_KeyboardPledgeOfMaraProvider:New(notificationManager)
    local provider = ZO_PledgeOfMaraProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardPledgeOfMaraProvider:CreateMessage(targetName)
    return zo_strformat(SI_PLEDGE_OF_MARA_MESSAGE, targetName)
end

function ZO_KeyboardPledgeOfMaraProvider:CreateSenderMessage(targetName)
    return zo_strformat(SI_PLEDGE_OF_MARA_SENDER_MESSAGE, targetName)
end

-- CS Chat Request Provider
-------------------------

local ZO_KeyboardAgentChatRequestProvider = ZO_AgentChatRequestProvider:Subclass()

function ZO_KeyboardAgentChatRequestProvider:New(notificationManager)
    local provider = ZO_AgentChatRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardAgentChatRequestProvider:CreateMessage()
    return GetString(SI_AGENT_CHAT_REQUEST_MESSAGE)
end

-- Leaderboard Raid Provider
-------------------------

local ZO_KeyboardLeaderboardRaidProvider = ZO_LeaderboardRaidProvider:Subclass()

function ZO_KeyboardLeaderboardRaidProvider:New(notificationManager)
    local provider = ZO_LeaderboardRaidProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardLeaderboardRaidProvider:CreateMessage(raidName, raidScore, hasFriend, hasGuildMember)
    local messageStringId
    if(hasFriend and hasGuildMember) then
        messageStringId = SI_NOTIFICATIONS_LEADERBOARD_RAID_MESSAGE_FRIENDS_AND_GUILD_MEMBERS
    elseif(hasFriend) then
        messageStringId = SI_NOTIFICATIONS_LEADERBOARD_RAID_MESSAGE_FRIENDS
    else
        messageStringId = SI_NOTIFICATIONS_LEADERBOARD_RAID_MESSAGE_GUILD_MEMBERS
    end
    return zo_strformat(messageStringId, raidName, raidScore)
end

function ZO_KeyboardLeaderboardRaidProvider:ShowMessageTooltip(data, control)
    InitializeTooltip(InformationTooltip, control, TOP, 0, 0)
    
    local numMembers = GetNumRaidScoreNotificationMembers(data.notificationId)
    local guildMembersSection = {}
    local friendsSection = {}

    for memberIndex = 1, numMembers do
        local displayName, characterName, isFriend, isGuildMember = GetRaidScoreNotificationMemberInfo(data.notificationId, memberIndex)
        if(isGuildMember) then
            table.insert(guildMembersSection, displayName)
        elseif(isFriend) then
            table.insert(friendsSection, displayName)
        end
    end

    if(#guildMembersSection > 0) then
        InformationTooltip:AddLine(GetString(SI_NOTIFICATIONS_LEADERBOARD_RAID_NOTIFICATION_HEADER_GUILD_MEMBERS))
        for _, guildMemberName in ipairs(guildMembersSection) do
            InformationTooltip:AddVerticalPadding(-9)
            InformationTooltip:AddLine(guildMemberName, "", ZO_NORMAL_TEXT:UnpackRGB())
        end
    end

    if(#friendsSection > 0) then
        InformationTooltip:AddLine(GetString(SI_NOTIFICATIONS_LEADERBOARD_RAID_NOTIFICATION_HEADER_FRIENDS))
        for _, friendName in ipairs(friendsSection) do
            InformationTooltip:AddVerticalPadding(-9)
            InformationTooltip:AddLine(friendName, "", ZO_NORMAL_TEXT:UnpackRGB())
        end
    end
end

function ZO_KeyboardLeaderboardRaidProvider:HideMessageTooltip()
    ClearTooltip(InformationTooltip)
end


--Collections Update Provider
-------------------------

local ZO_KeyboardCollectionsUpdateProvider = ZO_CollectionsUpdateProvider:Subclass()

function ZO_KeyboardCollectionsUpdateProvider:New(notificationManager)
    local provider = ZO_CollectionsUpdateProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardCollectionsUpdateProvider:Accept(entryData)
    ZO_CollectionsUpdateProvider.Accept(self, entryData)

    local data = entryData.data
    COLLECTIONS_BOOK:BrowseToCollectible(data.collectibleIndex, data.categoryIndex, data.subcategoryIndex)
end

function ZO_KeyboardCollectionsUpdateProvider:GetMessage(hasMoreInfo, categoryName, collectibleName)
    if hasMoreInfo then
        local moreInfoIconMarkup = zo_iconFormat("EsoUI/Art/Notifications/notification_help_up.dds", 24, 24)
        return zo_strformat(SI_COLLECTIONS_UPDATED_NOTIFICATION_MESSAGE_MORE_INFO_KEYBOARD, categoryName, collectibleName, moreInfoIconMarkup)
    else
        return zo_strformat(SI_COLLECTIONS_UPDATED_NOTIFICATION_MESSAGE, categoryName, collectibleName)
    end
end

function ZO_KeyboardCollectionsUpdateProvider:ShowMoreInfo(entryData)
    local helpCategoryIndex, helpIndex = GetCollectibleHelpIndices(entryData.data.collectibleId)
    if helpCategoryIndex ~= nil then
        HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
    end
end


--LFG Update Provider
-------------------------

local ZO_KeyboardLFGUpdateProvider = ZO_LFGUpdateProvider:Subclass()

function ZO_KeyboardLFGUpdateProvider:New(notificationManager)
    return ZO_LFGUpdateProvider.New(self, notificationManager)
end

function ZO_KeyboardLFGUpdateProvider:GetMessageFormat()
    return SI_LFG_JUMP_TO_DUNGEON_TEXT
end

do
    local ROLE_TO_ICON = {
        [LFG_ROLE_DPS] = "EsoUI/Art/LFG/LFG_dps_up.dds",
        [LFG_ROLE_HEAL] = "EsoUI/Art/LFG/LFG_healer_up.dds",
        [LFG_ROLE_TANK] = "EsoUI/Art/LFG/LFG_tank_up.dds",
    }
    
    function ZO_KeyboardLFGUpdateProvider:GetRoleIcon(role)
        return ROLE_TO_ICON[role]
    end
end


--Notification Manager
-------------------------

local ZO_KeyboardNotificationManager = ZO_NotificationManager:Subclass()

function ZO_KeyboardNotificationManager:New(control)
    return ZO_NotificationManager.New(self, control)
end

function ZO_KeyboardNotificationManager:InitializeNotificationList(control)
    self.sortFilterList = ZO_NotificationList:New(control)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_REQUEST_DATA, "ZO_NotificationsRequestRow", 50, function(control, data) self:SetupRequest(control, data) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_WAITING_DATA, "ZO_NotificationsWaitingRow", 50, function(control, data) self:SetupWaiting(control, data) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_LEADERBOARD_DATA, "ZO_NotificationsLeaderboardRow", 50, function(control, data) self:SetupTwoButtonRow(control, data) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_ALERT_DATA, "ZO_NotificationsAlertRow", 50, function(control, data) self:SetupAlert(control, data) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_COLLECTIBLE_DATA, "ZO_NotificationsCollectibleRow", 50, function(control, data) self:SetupCollectibleRow(control, data) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_LFG_JUMP_DUNGEON_DATA, "ZO_NotificationsLFGJumpDungeonRow", 50, function(control, data) self:SetupRequest(control, data) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA, "ZO_NotificationsLFGFindReplacementRow", 50, function(control, data) self:SetupRequest(control, data) end)
    ZO_ScrollList_EnableHighlight(self.sortFilterList.list, "ZO_ThinListHighlight")

    self.totalNumNotifications = 0

    self.eventNamespace = EVENT_NAMESPACE

    local collectionsProvider = ZO_KeyboardCollectionsUpdateProvider:New(self)
    self.collectionsProvider = collectionsProvider

    self.providers =
    {
        ZO_KeyboardFriendRequestProvider:New(self),
        ZO_KeyboardGuildInviteProvider:New(self),
        ZO_GuildMotDProvider:New(self),
        ZO_KeyboardCampaignQueueProvider:New(self),
        ZO_KeyboardResurrectProvider:New(self),
        ZO_KeyboardGroupInviteProvider:New(self),
        ZO_KeyboardTradeInviteProvider:New(self),
        ZO_KeyboardQuestShareProvider:New(self),
        ZO_PointsResetProvider:New(self, "keyboard"),
        ZO_KeyboardPledgeOfMaraProvider:New(self),
        ZO_KeyboardAgentChatRequestProvider:New(self),
        ZO_KeyboardLeaderboardRaidProvider:New(self),
        collectionsProvider,
        ZO_KeyboardLFGUpdateProvider:New(self),
    }

    self.sortFilterList:SetEmptyText(GetString(SI_NO_NOTIFICATIONS_MESSAGE))
    self.sortFilterList:SetAlternateRowBackgrounds(true)
    self.sortFilterList:RefreshData()
    self.sortFilterList:SetKeybindStripDescriptor({
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- More Information Request
        {
            name = GetString(SI_NOTIFICATIONS_MORE_INFO),

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                local selectedRow = self:GetSelectedData()
                if selectedRow then
                    local data = ZO_ScrollList_GetData(selectedRow)
                    self:ShowMoreInfo(data)
                end
            end,

            visible = function()
                local selectedRow = self:GetSelectedData()
                if selectedRow then
                    local data = ZO_ScrollList_GetData(selectedRow)
                    return data.moreInfo == true
                end
                return false
            end
        },

        -- Decline Request
        {
            name = function()
                local data = self:GetSelectedData()
                return data.declineText
            end,

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                local selectedRow = self:GetSelectedData()
                if selectedRow then
                    local data = ZO_ScrollList_GetData(selectedRow)
                    self:DeclineRequest(data, nil, NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND)
                end
            end,

            visible = function()
                local data = self:GetSelectedData()
                if(data and data.declineText) then
                    return true
                end
                return false
            end
        },

        -- Accept Request
        {
            name = function()
                local data = self:GetSelectedData()
                return data.acceptText
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local selectedRow = self:GetSelectedData()
                if selectedRow then
                    local data = ZO_ScrollList_GetData(selectedRow)
                    self:AcceptRequest(data)
                end
            end,

            visible = function()
                local data = self:GetSelectedData()
                if(data and data.acceptText) then
                    return true
                end
                return false
            end
        },
    })

    NOTIFICATIONS_SCENE = ZO_Scene:New("notifications", SCENE_MANAGER)
    NOTIFICATIONS_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            self.sortFilterList:AddKeybinds()
        elseif(newState == SCENE_HIDING) then
            ClearMenu()
        elseif(newState == SCENE_HIDDEN) then
            self.sortFilterList:RemoveKeybinds()
        end
    end)

end


function ZO_KeyboardNotificationManager:ClearNotificationList()
    local scrollData = ZO_ScrollList_GetDataList(self.sortFilterList.list)
    ZO_ClearNumericallyIndexedTable(scrollData)
end

function ZO_KeyboardNotificationManager:AddDataEntry(dataType, data)
    local dataEntry = ZO_ScrollList_CreateDataEntry(dataType or REQUEST_DATA, data)
    local scrollData = ZO_ScrollList_GetDataList(self.sortFilterList.list)
    table.insert(scrollData, dataEntry)
end

function ZO_KeyboardNotificationManager:GetSelectedData()
    return self.sortFilterList.mouseOverRow
end

function ZO_KeyboardNotificationManager:FinishNotificationList()
    self.sortFilterList:RefreshFilters()
end

function ZO_KeyboardNotificationManager:RefreshVisible()
    self.sortFilterList:RefreshVisible()
end

function ZO_KeyboardNotificationManager:OnNumNotificationsChanged(totalNumNotifications)
    CHAT_SYSTEM:OnNumNotificationsChanged(totalNumNotifications)
end

function ZO_KeyboardNotificationManager:BuildEmptyList()
end

function ZO_KeyboardNotificationManager:SetupNote(control, data)
    local note = GetControl(control, "Note")
    if note then
        if(data.note and data.note ~= "") then
            note:SetHidden(false)
        else
            note:SetHidden(true)
        end
    end
end

function ZO_KeyboardNotificationManager:SetupBaseRow(control, data)
    ZO_SortFilterList.SetupRow(self.sortFilterList, control, data)

    local notificationType = data.notificationType

    control.notificationType = notificationType
    control.index = data.index

    GetControl(control, "Icon"):SetTexture(KEYBOARD_NOTIFICATION_ICONS[notificationType])
    GetControl(control, "Type"):SetText(zo_strformat(SI_NOTIFICATIONS_TYPE_FORMATTER, GetString("SI_NOTIFICATIONTYPE", notificationType)))
end

function ZO_KeyboardNotificationManager:SetupTwoButtonRow(control, data)
    self:SetupBaseRow(control, data)
    self:SetupMessage(control:GetNamedChild("Message"), data)
end

function ZO_KeyboardNotificationManager:SetupRequest(control, data)
    self:SetupBaseRow(control, data)
    self:SetupMessage(control:GetNamedChild("Message"), data)
    self:SetupNote(control, data)
end

function ZO_KeyboardNotificationManager:SetupWaiting(control, data)
    self:SetupBaseRow(control, data)

    local loading = GetControl(control, "Loading")
    loading:SetText(data.loadText)
    loading:Show()
end

function ZO_KeyboardNotificationManager:SetupAlert(control, data)
    self:SetupBaseRow(control, data)
    self:SetupMessage(control:GetNamedChild("Message"), data)
    self:SetupNote(control, data)
end

function ZO_KeyboardNotificationManager:SetupCollectibleRow(control, data)
    self:SetupRequest(control, data)
    local moreInfoButton = control:GetNamedChild("MoreInfo")
    moreInfoButton:SetHidden(data.moreInfo ~= true)
end

--Local XML

function ZO_KeyboardNotificationManager:OnNotificationsChatButtonEnter(control)
    InitializeTooltip(InformationTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)
    local bindingText = ZO_Keybindings_GetHighestPriorityBindingStringFromAction("TOGGLE_NOTIFICATIONS", KEYBIND_TEXT_OPTIONS_FULL_NAME)
    SetTooltipText(InformationTooltip, zo_strformat(SI_NOTIFICATIONS_TOOLTIP_HEADER, bindingText or GetString(SI_ACTION_IS_NOT_BOUND)))
    InformationTooltip:AddVerticalPadding(10)

    if(self.totalNumNotifications > 0) then
        InformationTooltip:AddLine(zo_strformat(SI_NOTIFICATIONS_TOOLTIP_HAS_NOTIFICATIONS, self.totalNumNotifications), "", ZO_NORMAL_TEXT:UnpackRGB())
    else
        InformationTooltip:AddLine(GetString(SI_NOTIFICATIONS_TOOLTIP_NO_NOTIFICATIONS), "", ZO_NORMAL_TEXT:UnpackRGB())
    end
end

function ZO_KeyboardNotificationManager:OnNotificationsChatButtonExit()
    ClearTooltip(InformationTooltip)
end

function ZO_KeyboardNotificationManager:RowNote_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, data.note)

    self.sortFilterList:EnterRow(control:GetParent())
end

function ZO_KeyboardNotificationManager:RowNote_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self.sortFilterList:ExitRow(control:GetParent())
end

function ZO_KeyboardNotificationManager:Accept_OnClicked(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    self:AcceptRequest(data)
end

function ZO_KeyboardNotificationManager:Decline_OnClicked(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    self:DeclineRequest(data, button, MENU_OPENED_FROM_MOUSE)
end

function ZO_KeyboardNotificationManager:Message_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    data.provider:ShowMessageTooltip(data, control)
end

function ZO_KeyboardNotificationManager:Message_OnMouseExit(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    data.provider:HideMessageTooltip(control)
end

function ZO_KeyboardNotificationManager:RowMoreInfo_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, GetString(SI_NOTIFICATIONS_MORE_INFO_TOOLTIP))
end

function ZO_KeyboardNotificationManager:RowMoreInfo_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_KeyboardNotificationManager:RowMoreInfo_OnClicked(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    self:ShowMoreInfo(data)
end

--Global XML

function ZO_NotificationsRowNote_OnMouseEnter(control)
    NOTIFICATIONS:RowNote_OnMouseEnter(control)
end

function ZO_NotificationsRowNote_OnMouseExit(control)
    NOTIFICATIONS:RowNote_OnMouseExit(control)
end

function ZO_NotificationsBaseRow_OnMouseEnter(control)
    NOTIFICATIONS.sortFilterList:Row_OnMouseEnter(control)
end

function ZO_NotificationsBaseRow_OnMouseExit(control)
    NOTIFICATIONS.sortFilterList:Row_OnMouseExit(control)
end

function ZO_NotificationsTwoButtonAccept_OnClicked(control)
    NOTIFICATIONS:Accept_OnClicked(control)
end

function ZO_NotificationsTwoButtonDecline_OnClicked(control)
    NOTIFICATIONS:Decline_OnClicked(control)
end

function ZO_NotificationsMessage_OnMouseEnter(control)
    ZO_NotificationsBaseRow_OnMouseEnter(control:GetParent())
    NOTIFICATIONS:Message_OnMouseEnter(control)
end

function ZO_NotificationsMessage_OnMouseExit(control)
    ZO_NotificationsBaseRow_OnMouseExit(control:GetParent())
    NOTIFICATIONS:Message_OnMouseExit(control)
end

function ZO_NotificationsRowMoreInfo_OnMouseEnter(control)
    ZO_NotificationsBaseRow_OnMouseEnter(control:GetParent())
    NOTIFICATIONS:RowMoreInfo_OnMouseEnter(control)
end

function ZO_NotificationsRowMoreInfo_OnMouseExit(control)
    ZO_NotificationsBaseRow_OnMouseExit(control:GetParent())
    NOTIFICATIONS:RowMoreInfo_OnMouseExit(control)
end

function ZO_NotificationsRowMoreInfo_OnClicked(control)
    NOTIFICATIONS:RowMoreInfo_OnClicked(control)
end

function ZO_Notifications_OnInitialized(self)
    NOTIFICATIONS = ZO_KeyboardNotificationManager:New(self)
end
