ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT = 50

local EVENT_NAMESPACE = "KeyboardNotifications"

ZO_KEYBOARD_NOTIFICATION_ICONS =
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
    [NOTIFICATION_TYPE_CRAFT_BAG_AUTO_TRANSFER] = "EsoUI/Art/Notifications/notificationIcon_autoTransfer.dds",
    [NOTIFICATION_TYPE_GROUP_ELECTION] = "EsoUI/Art/Notifications/notificationIcon_autoTransfer.dds",
    [NOTIFICATION_TYPE_DUEL] = "EsoUI/Art/Notifications/notificationIcon_duel.dds",
    [NOTIFICATION_TYPE_ESO_PLUS_SUBSCRIPTION] = "EsoUI/Art/Notifications/notificationIcon_ESO+.dds",
    [NOTIFICATION_TYPE_CRAFTED_ABILITY_RESET] = function(data) return data.icon end,
    [NOTIFICATION_TYPE_GIFT_RECEIVED] = "EsoUI/Art/Notifications/notificationIcon_gift.dds",
    [NOTIFICATION_TYPE_GIFT_CLAIMED] = "EsoUI/Art/Notifications/notificationIcon_gift.dds",
    [NOTIFICATION_TYPE_GIFT_RETURNED] = "EsoUI/Art/Notifications/notificationIcon_gift.dds",
    [NOTIFICATION_TYPE_NEW_DAILY_LOGIN_REWARD] = "EsoUI/Art/Notifications/notificationIcon_dailyLoginRewards.dds",
    [NOTIFICATION_TYPE_GUILD_NEW_APPLICATIONS] = "EsoUI/Art/Notifications/notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_PLAYER_APPLICATIONS] = "EsoUI/Art/Notifications/notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_MARKET_PRODUCT_AVAILABLE] = "EsoUI/Art/Notifications/notificationIcon_crownStore.dds",
    [NOTIFICATION_TYPE_EXPIRING_MARKET_CURRENCY] = GetCurrencyKeyboardIcon(CURT_CROWNS),
    [NOTIFICATION_TYPE_OUT_OF_DATE_ADDONS] = "EsoUI/Art/Miscellaneous/ESO_Icon_Warning.dds",
    [NOTIFICATION_TYPE_DISABLED_ADDON] = "EsoUI/Art/Miscellaneous/ESO_Icon_Warning.dds",
    [NOTIFICATION_TYPE_TRIBUTE_INVITE] = "EsoUI/Art/Notifications/notificationIcon_tribute.dds",
    [NOTIFICATION_TYPE_HOUSE_TOURS_HOUSE_RECOMMENDED] = "EsoUI/Art/Notifications/notificationIcon_houseToursHouseRecommended.dds",
    [NOTIFICATION_TYPE_SLOTS_RESET] = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds",
}

-- Provider Overrides
-------------------------

-- Friend Request Provier
-------------------------

ZO_KeyboardFriendRequestProvider = ZO_FriendRequestProvider:Subclass()

function ZO_KeyboardFriendRequestProvider:New(notificationManager)
    local provider = ZO_FriendRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardFriendRequestProvider:Decline(data, button, openedFromKeybind)
    ClearMenu()

    local function IgnorePlayer()
        if not IsIgnored(data.displayName) then
            AddIgnore(data.displayName)
        end
    end

    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_DECLINE), function()
                                                                RejectFriendRequest(data.displayName)
                                                                PlaySound(SOUNDS.DIALOG_DECLINE)
                                                             end)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_IGNORE_PLAYER),  function()
                                                                        IgnorePlayer()
                                                                        PlaySound(SOUNDS.DEFAULT_CLICK)
                                                                    end)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_REPORT_SPAMMING), function()
                                                                        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(data.displayName)
                                                                    end)

    if(openedFromKeybind == NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND) then
        self.notificationManager.sortFilterList:ShowMenu(button, 1)
    else
        self.notificationManager.sortFilterList:ShowMenu(button)
    end
end

-- Guild Invite Request Provier
-------------------------

ZO_KeyboardGuildInviteProvider = ZO_GuildInviteProvider:Subclass()

function ZO_KeyboardGuildInviteProvider:New(notificationManager)
    local provider = ZO_GuildInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardGuildInviteProvider:CreateMessage(guildAlliance, guildName, inviterDisplayName)
    local allianceIcon = zo_iconFormat(ZO_GetAllianceSymbolIcon(guildAlliance), 24, 24)
    return zo_strformat(SI_GUILD_INVITE_MESSAGE, allianceIcon, guildName, inviterDisplayName)
end


function ZO_KeyboardGuildInviteProvider:Decline(data, button, openedFromKeybind)
    ClearMenu()

    local function IgnorePlayer()
        if not IsIgnored(data.displayName) then
            AddIgnore(data.displayName)
        end
    end

    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_DECLINE), function() RejectGuildInvite(data.guildId) end)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_IGNORE_PLAYER), IgnorePlayer)
    AddMenuItem(GetString(SI_NOTIFICATIONS_REQUEST_REPORT_SPAMMING), function()
                                                                        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(data.displayName)
                                                                        RejectGuildInvite(data.guildId)
                                                                    end)

    if(openedFromKeybind == NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND) then
        self.notificationManager.sortFilterList:ShowMenu(button, 1)
    else
        self.notificationManager.sortFilterList:ShowMenu(button)
    end
end

-- CS Chat Request Provider
-------------------------

ZO_KeyboardAgentChatRequestProvider = ZO_AgentChatRequestProvider:Subclass()

function ZO_KeyboardAgentChatRequestProvider:New(notificationManager)
    local provider = ZO_AgentChatRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_KeyboardAgentChatRequestProvider:CreateMessage()
    return GetString(SI_AGENT_CHAT_REQUEST_MESSAGE)
end

-- Leaderboard Score Provider
-------------------------

ZO_KeyboardLeaderboardScoreProvider = ZO_LeaderboardScoreProvider:Subclass()

function ZO_KeyboardLeaderboardScoreProvider:New(notificationManager)
    -- Override leaderboard update callback to support audio
    local function notificationEventCallback(eventId)
        if eventId == EVENT_LEADERBOARD_SCORE_NOTIFICATION_ADDED and GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_LEADERBOARD_NOTIFICATIONS) then
            PlaySound(SOUNDS.NEW_NOTIFICATION)
        end
    end

    local provider = ZO_LeaderboardScoreProvider.New(self, notificationManager, notificationEventCallback)
    return provider
end

function ZO_KeyboardLeaderboardScoreProvider:ShowMessageTooltip(data, control)
    InitializeTooltip(InformationTooltip, control, TOP, 0, 0)

    local numMembers = data.numMembers
    local guildMembersSection = {}
    local friendsSection = {}

    for memberIndex = 1, numMembers do
        local displayName, characterName, isFriend, isGuildMember, isPlayer = GetLeaderboardScoreNotificationMemberInfo(data.notificationId, memberIndex)
        
        if not isPlayer then
            if isFriend then
                table.insert(friendsSection, displayName)
            elseif isGuildMember then
                table.insert(guildMembersSection, displayName)
            end
        end
    end

    if #friendsSection > 0 then
        InformationTooltip:AddLine(zo_strformat(GetString(SI_NOTIFICATIONS_LEADERBOARD_SCORE_NOTIFICATION_HEADER_FRIENDS), #friendsSection))
        for _, friendName in ipairs(friendsSection) do
            InformationTooltip:AddVerticalPadding(-9)
            InformationTooltip:AddLine(friendName, "", ZO_NORMAL_TEXT:UnpackRGB())
        end
    end
    
    if #guildMembersSection > 0 then
        InformationTooltip:AddLine(zo_strformat(GetString(SI_NOTIFICATIONS_LEADERBOARD_SCORE_NOTIFICATION_HEADER_GUILD_MEMBERS), #guildMembersSection))
        for _, guildMemberName in ipairs(guildMembersSection) do
            InformationTooltip:AddVerticalPadding(-9)
            InformationTooltip:AddLine(guildMemberName, "", ZO_NORMAL_TEXT:UnpackRGB())
        end
    end
end

function ZO_KeyboardLeaderboardScoreProvider:HideMessageTooltip()
    ClearTooltip(InformationTooltip)
end


--Collections Update Provider
-------------------------

ZO_KeyboardCollectionsUpdateProvider = ZO_CollectionsUpdateProvider:Subclass()

function ZO_KeyboardCollectionsUpdateProvider:New(notificationManager)
    return ZO_CollectionsUpdateProvider.New(self, notificationManager)
end

function ZO_KeyboardCollectionsUpdateProvider:Accept(entryData)
    ZO_CollectionsUpdateProvider.Accept(self, entryData)

    COLLECTIONS_BOOK:BrowseToCollectible(entryData.data:GetId())
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
    local helpCategoryIndex, helpIndex = GetCollectibleHelpIndices(entryData.data:GetId())
    if helpCategoryIndex ~= nil then
        HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
    end
end

-- ZO_KeyboardEsoPlusSubscriptionStatusProvider
-------------------------

ZO_KeyboardEsoPlusSubscriptionStatusProvider = ZO_EsoPlusSubscriptionStatusProvider:Subclass()

function ZO_KeyboardEsoPlusSubscriptionStatusProvider:New(notificationManager)
    return ZO_EsoPlusSubscriptionStatusProvider.New(self, notificationManager)
end

function ZO_KeyboardEsoPlusSubscriptionStatusProvider:ShowMoreInfo(entryData)
    if entryData.moreInfo then
        HELP:ShowSpecificHelp(entryData.helpCategoryIndex, entryData.helpIndex)
    end
end

-- ZO_KeyboardGuildNewApplicationsProvider
-------------------------------------------

ZO_KeyboardGuildNewApplicationsProvider = ZO_GuildNewApplicationsProvider:Subclass()

function ZO_KeyboardGuildNewApplicationsProvider:New(notificationManager)
    return ZO_GuildNewApplicationsProvider.New(self, notificationManager)
end

function ZO_KeyboardGuildNewApplicationsProvider:Accept(entryData)
    ZO_GuildNewApplicationsProvider.Accept(self, entryData)

    GUILD_SELECTOR:SelectGuildByIndex(entryData.guildIndex)
    MAIN_MENU_KEYBOARD:ToggleSceneGroup("guildsSceneGroup", "guildRecruitmentKeyboard")
    GUILD_RECRUITMENT_KEYBOARD:ShowApplicationsList()
end

-- ZO_KeyboardMarketProductUnlockedProvider
-------------------------

ZO_KeyboardMarketProductUnlockedProvider = ZO_MarketProductUnlockedProvider:Subclass()

function ZO_KeyboardMarketProductUnlockedProvider:New(notificationManager)
    return ZO_MarketProductUnlockedProvider.New(self, notificationManager)
end

function ZO_KeyboardMarketProductUnlockedProvider:ShowMoreInfo(entryData)
    if entryData.moreInfo then
        HELP:ShowSpecificHelp(entryData.helpCategoryIndex, entryData.helpIndex)
    end
end

function ZO_KeyboardMarketProductUnlockedProvider:ShowMessageTooltip(entryData, control)
    ZO_TooltipIfTruncatedLabel_OnMouseEnter(control)
end

function ZO_KeyboardMarketProductUnlockedProvider:HideMessageTooltip(entryData, control)
    ZO_TooltipIfTruncatedLabel_OnMouseExit(control)
end

-- ZO_KeyboardPointsResetProvider
-------------------------------------------

ZO_KeyboardPointsResetProvider = ZO_PointsResetProvider:Subclass()

function ZO_KeyboardPointsResetProvider:Accept(data)
    ZO_PointsResetProvider.Accept(self, data)
    if data.respecType == RESPEC_TYPE_ATTRIBUTES then
        MAIN_MENU_KEYBOARD:ShowScene("stats")
    elseif data.respecType == RESPEC_TYPE_SKILLS then
        MAIN_MENU_KEYBOARD:ShowScene("skills")
    elseif data.respecType == RESPEC_TYPE_CHAMPION or data.respecType == RESPEC_TYPE_CHAMPION_SLOTS then
        MAIN_MENU_KEYBOARD:ShowScene("championPerks")
    end
end

--Notification Manager
-------------------------

ZO_KeyboardNotificationManager = ZO_NotificationManager:Subclass()

function ZO_KeyboardNotificationManager:New(control)
    return ZO_NotificationManager.New(self, control)
end

function ZO_KeyboardNotificationManager:InitializeNotificationList(control)
    self.sortFilterList = ZO_NotificationList:New(control)
    local function SetupRequest(...)
        self:SetupRequest(...)
    end

    local function SetupRequestWithMoreInfoRow(...)
        self:SetupRequestWithMoreInfoRow(...)
    end

    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_REQUEST_DATA, "ZO_NotificationsRequestRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_YES_NO_DATA, "ZO_NotificationsYesNoRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_WAITING_DATA, "ZO_NotificationsWaitingRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, function(...) self:SetupWaiting(...) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_LEADERBOARD_DATA, "ZO_NotificationsLeaderboardRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, function(...) self:SetupTwoButtonRow(...) end)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_ALERT_DATA, "ZO_NotificationsAlertRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_COLLECTIBLE_DATA, "ZO_NotificationsCollectibleRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequestWithMoreInfoRow)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_LFG_READY_CHECK_DATA, "ZO_NotificationsLFGReadyCheckRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA, "ZO_NotificationsLFGFindReplacementRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_ESO_PLUS_SUBSCRIPTION_DATA, "ZO_NotificationsEsoPlusSubscriptionRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequestWithMoreInfoRow)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_GIFT_RECEIVED_DATA, "ZO_NotificationsGiftReceivedRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_GIFT_RETURNED_DATA, "ZO_NotificationsGiftReturnedRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_GIFT_CLAIMED_DATA, "ZO_NotificationsGiftClaimedRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_NEW_DAILY_LOGIN_REWARD_DATA, "ZO_NotificationsNewDailyLoginRewardRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_GUILD_NEW_APPLICATIONS, "ZO_NotificationsGuildNewApplicationsRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_MARKET_PRODUCT_UNLOCKED_DATA, "ZO_NotificationsMarketProductUnlockedRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequestWithMoreInfoRow)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_POINTS_RESET_DATA, "ZO_NotificationsPointsResetRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_AddDataType(self.sortFilterList.list, NOTIFICATIONS_HOUSE_TOURS_HOUSE_RECOMMENDED_DATA, "ZO_NotificationsHouseToursHouseRecommendedRow", ZO_NOTIFICATIONS_KEYBOARD_BASE_ROW_HEIGHT, SetupRequest)
    ZO_ScrollList_EnableHighlight(self.sortFilterList.list, "ZO_ThinListHighlight")

    self.totalNumNotifications = 0

    self.eventNamespace = EVENT_NAMESPACE

    self.providers =
    {
        ZO_KeyboardFriendRequestProvider:New(self),
        ZO_KeyboardGuildInviteProvider:New(self),
        ZO_GuildMotDProvider:New(self),
        ZO_CampaignQueueProvider:New(self),
        ZO_ResurrectProvider:New(self),
        ZO_GroupInviteProvider:New(self),
        ZO_GroupElectionProvider:New(self),
        ZO_TradeInviteProvider:New(self),
        ZO_QuestShareProvider:New(self),
        ZO_KeyboardPointsResetProvider:New(self),
        ZO_CraftedAbilityResetProvider:New(self),
        ZO_PledgeOfMaraProvider:New(self),
        ZO_KeyboardAgentChatRequestProvider:New(self),
        ZO_KeyboardLeaderboardScoreProvider:New(self),
        ZO_KeyboardCollectionsUpdateProvider:New(self),
        ZO_LFGUpdateProvider:New(self),
        ZO_CraftBagAutoTransferProvider:New(self),
        ZO_DuelInviteProvider:New(self),
        ZO_KeyboardEsoPlusSubscriptionStatusProvider:New(self),
        ZO_GiftInventoryProvider:New(self),
        ZO_DailyLoginRewardsClaimProvider:New(self),
        ZO_KeyboardGuildNewApplicationsProvider:New(self),
        ZO_PlayerApplicationsProvider:New(self),
        ZO_KeyboardMarketProductUnlockedProvider:New(self),
        ZO_ExpiringMarketCurrencyProvider:New(self),
        ZO_OutOfDateAddonsProvider:New(self),
        ZO_DisabledAddonsProvider:New(self),
        ZO_TributeInviteProvider:New(self),
        ZO_HouseToursHouseRecommendedProvider:New(self),
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
                    if data.dataType == NOTIFICATIONS_LFG_READY_CHECK_DATA then
                        local dialogData =
                        {
                            data = data,
                            control = nil,
                            openedFromKeybind = NOTIFICATIONS_MENU_OPENED_FROM_MOUSE,
                        }
                        ZO_Dialogs_ShowPlatformDialog("LFG_DECLINE_READY_CHECK_CONFIRMATION", dialogData)
                    else
                        self:DeclineRequest(data, control, NOTIFICATIONS_MENU_OPENED_FROM_MOUSE)
                    end
                end
            end,

            visible = function()
                local data = self:GetSelectedData()
                if data and data.declineText then
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
                if data and data.acceptText then
                    return true
                end
                return false
            end
        },

        -- Report Request
        {
            name = GetString(SI_GUILD_BROWSER_REPORT_GUILD_KEYBIND),

            keybind = "UI_SHORTCUT_REPORT_PLAYER",

            callback = function()
                local selectedRow = self:GetSelectedData()
                if selectedRow then
                    local data = ZO_ScrollList_GetData(selectedRow)
                    local function ReportCallback()
                        -- TODO: Not sure if we need this
                    end
                    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(data.guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_DECLINE, ReportCallback)
                end
            end,

            visible = function()
                local selectedRow = self:GetSelectedData()
                if selectedRow then
                    local data = ZO_ScrollList_GetData(selectedRow)
                    return data.showReportKeybind
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
    KEYBOARD_CHAT_SYSTEM:OnNumNotificationsChanged(totalNumNotifications)
end

function ZO_KeyboardNotificationManager:BuildEmptyList()
end

function ZO_KeyboardNotificationManager:SetupNote(control, data)
    local note = control:GetNamedChild("Note")
    if note then
        if data.note and data.note ~= "" then
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

    if data.acceptText == nil then
        data.acceptText = control.acceptText
    end

    if data.declineText == nil then
        data.declineText = control.declineText
    end

    control.data = data

    local icon = ZO_KEYBOARD_NOTIFICATION_ICONS[notificationType]
    if type(icon) == "function" then
        icon = icon(data)
    end
    control:GetNamedChild("Icon"):SetTexture(icon)
    control:GetNamedChild("Type"):SetText(zo_strformat(SI_NOTIFICATIONS_TYPE_FORMATTER, GetString("SI_NOTIFICATIONTYPE", notificationType)))
end

function ZO_KeyboardNotificationManager:SetupTwoButtonRow(control, data)
    self:SetupBaseRow(control, data)
    self:SetupMessage(control:GetNamedChild("Message"), data)
end

function ZO_KeyboardNotificationManager:SetupRequest(control, data)
    self:SetupTwoButtonRow(control, data)
    self:SetupNote(control, data)
end

function ZO_KeyboardNotificationManager:SetupWaiting(control, data)
    self:SetupBaseRow(control, data)

    local loading = GetControl(control, "Loading")
    loading:SetText(data.loadText)
    loading:Show()
end

function ZO_KeyboardNotificationManager:SetupRequestWithMoreInfoRow(control, data)
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
    if data then
        self:AcceptRequest(data)
    end
end

function ZO_KeyboardNotificationManager:Decline_OnClicked(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    if data then
        if data.dataType == NOTIFICATIONS_LFG_READY_CHECK_DATA then
            local dialogData =
            {
                data = data,
                control = control,
                openedFromKeybind = NOTIFICATIONS_MENU_OPENED_FROM_MOUSE,
            }
            ZO_Dialogs_ShowPlatformDialog("LFG_DECLINE_READY_CHECK_CONFIRMATION", dialogData)
        else
            self:DeclineRequest(data, control, NOTIFICATIONS_MENU_OPENED_FROM_MOUSE)
        end
    end
end

function ZO_KeyboardNotificationManager:Message_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    if data and data.provider.ShowMessageTooltip then
        data.provider:ShowMessageTooltip(data, control)
    end
end

function ZO_KeyboardNotificationManager:Message_OnMouseExit(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    if data and data.provider.HideMessageTooltip then
        data.provider:HideMessageTooltip(data, control)
    end
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
    if data then
        self:ShowMoreInfo(data)
    end
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

function ZO_NotificationsTwoButtonAccept_OnMouseEnter(control)
    local rowControl = control:GetParent()
    ZO_Tooltips_ShowTextTooltip(control, TOP, rowControl.data.acceptText)
    ZO_NotificationsBaseRow_OnMouseEnter(rowControl)
end

function ZO_NotificationsTwoButtonAccept_OnMouseExit(control)
    ZO_Tooltips_HideTextTooltip()
    ZO_NotificationsBaseRow_OnMouseExit(control:GetParent())
end

function ZO_NotificationsTwoButtonAccept_OnClicked(control)
    NOTIFICATIONS:Accept_OnClicked(control)
end

function ZO_NotificationsTwoButtonDecline_OnMouseEnter(control)
    local rowControl = control:GetParent()
    ZO_Tooltips_ShowTextTooltip(control, TOP, rowControl.data.declineText)
    ZO_NotificationsBaseRow_OnMouseEnter(rowControl)
end

function ZO_NotificationsTwoButtonDecline_OnMouseExit(control)
    ZO_Tooltips_HideTextTooltip()
    ZO_NotificationsBaseRow_OnMouseExit(control:GetParent())
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
