local EVENT_NAMESPACE = "GamepadNotifications"
local GAMEPAD_NOTIFICATIONS_CONFIRM_DECLINE_DIALOG_NAME = "GamepadNotificationsConfirmDecline"

ZO_GAMEPAD_NOTIFICATION_ICONS =
{
    [NOTIFICATION_TYPE_FRIEND] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_friend.dds",
    [NOTIFICATION_TYPE_GUILD] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_GUILD_MOTD] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_CAMPAIGN_QUEUE] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_campaignQueue.dds",
    [NOTIFICATION_TYPE_RESURRECT] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_resurrect.dds",
    [NOTIFICATION_TYPE_GROUP] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_group.dds",
    [NOTIFICATION_TYPE_TRADE] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_trade.dds",
    [NOTIFICATION_TYPE_QUEST_SHARE] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_quest.dds",
    [NOTIFICATION_TYPE_PLEDGE_OF_MARA] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_mara.dds",
    [NOTIFICATION_TYPE_CUSTOMER_SERVICE] = "EsoUI/Art/Notifications/Gamepad/gp_notification_cs.dds",
    [NOTIFICATION_TYPE_LEADERBOARD] = "EsoUI/Art/Notifications/Gamepad/gp_notification_leaderboardAccept_down.dds",
    [NOTIFICATION_TYPE_COLLECTIONS] = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_collections.dds",
    [NOTIFICATION_TYPE_LFG] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_group.dds",
    [NOTIFICATION_TYPE_POINTS_RESET] = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds",
    [NOTIFICATION_TYPE_CRAFT_BAG_AUTO_TRANSFER] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_autoTransfer.dds",
    [NOTIFICATION_TYPE_GROUP_ELECTION] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_autoTransfer.dds",
    [NOTIFICATION_TYPE_DUEL] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_duel.dds",
    [NOTIFICATION_TYPE_ESO_PLUS_SUBSCRIPTION] = "EsoUI/Art/Notifications/Gamepad/gp_notification_ESO+.dds",
    [NOTIFICATION_TYPE_CRAFTED_ABILITY_RESET] = function(data) return data.icon end,
    [NOTIFICATION_TYPE_GIFT_RECEIVED] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_gift.dds",
    [NOTIFICATION_TYPE_GIFT_CLAIMED] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_gift.dds",
    [NOTIFICATION_TYPE_GIFT_RETURNED] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_gift.dds",
    [NOTIFICATION_TYPE_NEW_DAILY_LOGIN_REWARD] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_dailyLoginRewards.dds",
    [NOTIFICATION_TYPE_GUILD_NEW_APPLICATIONS] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_PLAYER_APPLICATIONS] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_guild.dds",
    [NOTIFICATION_TYPE_MARKET_PRODUCT_AVAILABLE] = "EsoUI/Art/Notifications/Gamepad/gp_notification_crownStore.dds",
    [NOTIFICATION_TYPE_EXPIRING_MARKET_CURRENCY] = GetCurrencyGamepadIcon(CURT_CROWNS),
    [NOTIFICATION_TYPE_OUT_OF_DATE_ADDONS] = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new_64.dds",
    [NOTIFICATION_TYPE_DISABLED_ADDON] = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new_64.dds",
    [NOTIFICATION_TYPE_TRIBUTE_INVITE] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_tribute.dds",
    [NOTIFICATION_TYPE_HOUSE_TOURS_HOUSE_RECOMMENDED] = "EsoUI/Art/Notifications/Gamepad/gp_notificationIcon_houseToursHouseRecommended.dds",
    [NOTIFICATION_TYPE_SLOTS_RESET] = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds",
}

ZO_NOTIFICATION_TYPE_TO_GAMEPAD_TEMPLATE = 
{
    [NOTIFICATIONS_REQUEST_DATA] = "ZO_GamepadNotificationsRequestRow",
    [NOTIFICATIONS_YES_NO_DATA] = "ZO_GamepadNotificationsYesNoRow",
    [NOTIFICATIONS_WAITING_DATA] = "ZO_GamepadNotificationsWaitingRow",
    [NOTIFICATIONS_LEADERBOARD_DATA] = "ZO_GamepadNotificationsLeaderboardRow",
    [NOTIFICATIONS_ALERT_DATA] = "ZO_GamepadNotificationsAlertRow",
    [NOTIFICATIONS_COLLECTIBLE_DATA] = "ZO_GamepadNotificationsCollectibleRow",
    [NOTIFICATIONS_LFG_READY_CHECK_DATA] = "ZO_GamepadNotificationsLFGReadyCheckRow",
    [NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA] = "ZO_GamepadNotificationsLFGFindReplacementRow",
    [NOTIFICATIONS_ESO_PLUS_SUBSCRIPTION_DATA] = "ZO_GamepadNotificationsEsoPlusSubscriptionRow",
    [NOTIFICATIONS_GIFT_RECEIVED_DATA] = "ZO_GamepadNotificationsGiftReceivedRow",
    [NOTIFICATIONS_GIFT_RETURNED_DATA] = "ZO_GamepadNotificationsGiftReturnedRow",
    [NOTIFICATIONS_GIFT_CLAIMED_DATA] = "ZO_GamepadNotificationsGiftClaimedRow",
    [NOTIFICATIONS_NEW_DAILY_LOGIN_REWARD_DATA] = "ZO_GamepadNotificationsNewDailyLoginRewardRow",
    [NOTIFICATIONS_GUILD_NEW_APPLICATIONS] = "ZO_GamepadNotificationsGuildNewApplicationsRow",
    [NOTIFICATIONS_MARKET_PRODUCT_UNLOCKED_DATA] = "ZO_GamepadNotificationsMarketProductUnlockedRow",
    [NOTIFICATIONS_POINTS_RESET_DATA] = "ZO_GamepadNotificationsPointsResetRow",
    [NOTIFICATIONS_HOUSE_TOURS_HOUSE_RECOMMENDED_DATA] = "ZO_GamepadNotificationsHouseRecommendedRow",
}

-- Provider Overrides
-------------------------

-- Friend Request Provier
-------------------------

ZO_GamepadFriendRequestProvider = ZO_FriendRequestProvider:Subclass()

function ZO_GamepadFriendRequestProvider:New(notificationManager)
    local provider = ZO_FriendRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadFriendRequestProvider:Decline(data, button, openedFromKeybind)
    local function IgnorePlayer()
        ZO_PlatformIgnorePlayer(data.displayName, ZO_ID_REQUEST_TYPE_FRIEND_REQUEST, data.incomingFriendIndex)
    end

    local dialogData = 
    {
        mainText = function()
            return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_FRIEND_REQUEST_DECLINE_HEADER, data.displayName)
        end,

        declineFunction = function()
            RejectFriendRequest(data.displayName)
            PlaySound(SOUNDS.DIALOG_DECLINE)
        end,

        ignoreFunction = function()
            IgnorePlayer()
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end,

        reportFunction = function()
            ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(data.displayName, IgnorePlayer)
        end,
    }
    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_NOTIFICATIONS_CONFIRM_DECLINE_DIALOG_NAME, dialogData)
end

function ZO_GamepadFriendRequestProvider:CanShowGamerCard()
    return true
end

function ZO_GamepadFriendRequestProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromDisplayNameOrFallback(data.displayName, ZO_ID_REQUEST_TYPE_FRIEND_REQUEST, data.incomingFriendIndex)
end

-- Guild Invite Request Provier
-------------------------

ZO_GamepadGuildInviteProvider = ZO_GuildInviteProvider:Subclass()

function ZO_GamepadGuildInviteProvider:New(notificationManager)
    local provider = ZO_GuildInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadGuildInviteProvider:CreateMessage(guildAlliance, guildName, inviterDisplayName)
    local FORCE_GAMEPAD = true
    local guildInfo = ZO_AllianceIconNameFormatter(guildAlliance, guildName, FORCE_GAMEPAD)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_GUILD_INVITE_MESSAGE, guildInfo, inviterDisplayName)
end

function ZO_GamepadGuildInviteProvider:Decline(data, button, openedFromKeybind)
    local function IgnorePlayer()
        ZO_PlatformIgnorePlayer(data.displayName)
    end

    local dialogData =
    {
        mainText = function()
            local FORCE_GAMEPAD = true
            local guildInfo = ZO_AllianceIconNameFormatter(data.guildAlliance, data.guildName, FORCE_GAMEPAD)
            return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_GUILD_INVITE_DECLINE_HEADER, guildInfo, ZO_FormatUserFacingDisplayName(data.displayName))
        end,

        declineFunction = function()
            RejectGuildInvite(data.guildId)
            PlaySound(SOUNDS.DIALOG_DECLINE)
        end,

        ignoreFunction = function()
            IgnorePlayer()
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end,

        reportFunction = function()
            ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(data.displayName)
            RejectGuildInvite(data.guildId)
            PlaySound(SOUNDS.DIALOG_DECLINE)
        end,
    }

    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_NOTIFICATIONS_CONFIRM_DECLINE_DIALOG_NAME, dialogData)
end

function ZO_GamepadGuildInviteProvider:CanShowGamerCard()
    return true
end

function ZO_GamepadGuildInviteProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromDisplayName(data.displayName)
end

--Guild MotD Provider
-------------------------

ZO_GamepadGuildMotDProvider = ZO_GuildMotDProvider:Subclass()

function ZO_GamepadGuildMotDProvider:New(notificationManager)
    local provider = ZO_GuildMotDProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadGuildMotDProvider:CreateMessage(guildAlliance, guildName)
    local FORCE_GAMEPAD = true
    local guildInfo = ZO_AllianceIconNameFormatter(guildAlliance, guildName, FORCE_GAMEPAD)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_GUILD_MOTD_CHANGED, guildInfo)
end


--Resurrect Provider
-------------------------
ZO_GamepadResurrectProvider = ZO_ResurrectProvider:Subclass()

function ZO_GamepadResurrectProvider:New(notificationManager)
    local provider = ZO_ResurrectProvider.New(self, notificationManager)
    provider:SetCanShowGamerCard(true)
    return provider
end

--Group Invite Provider
-------------------------
ZO_GamepadGroupInviteProvider = ZO_GroupInviteProvider:Subclass()

function ZO_GamepadGroupInviteProvider:New(notificationManager)
    local provider = ZO_GroupInviteProvider.New(self, notificationManager)
    provider:SetCanShowGamerCard(true)
    return provider
end

--Trade Invite Provider
-------------------------

ZO_GamepadTradeInviteProvider = ZO_TradeInviteProvider:Subclass()

function ZO_GamepadTradeInviteProvider:New(notificationManager)
    local provider = ZO_TradeInviteProvider.New(self, notificationManager)
    provider:SetCanShowGamerCard(true)
    return provider
end


--Quest Share Provider
-------------------------

ZO_GamepadQuestShareProvider = ZO_QuestShareProvider:Subclass()

function ZO_GamepadQuestShareProvider:New(notificationManager)
    local provider = ZO_QuestShareProvider.New(self, notificationManager)
    provider:SetCanShowGamerCard(true)
    return provider
end

--Pledge of Mara Provider
-------------------------

ZO_GamepadPledgeOfMaraProvider = ZO_PledgeOfMaraProvider:Subclass()

function ZO_GamepadPledgeOfMaraProvider:New(notificationManager)
    local provider = ZO_PledgeOfMaraProvider.New(self, notificationManager)
    provider:SetCanShowGamerCard(true)
    return provider
end

-- CS Chat Request Provider
-------------------------

ZO_GamepadAgentChatRequestProvider = ZO_AgentChatRequestProvider:Subclass()

function ZO_GamepadAgentChatRequestProvider:New(notificationManager)
    local provider = ZO_AgentChatRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_AgentChatRequestProvider:CreateMessage()
    return GetString(SI_GAMEPAD_NOTIFICATIONS_AGENT_CHAT_REQUEST_MESSAGE)
end

-- Leaderboard Score Provider
-------------------------

ZO_GamepadLeaderboardScoreProvider = ZO_LeaderboardScoreProvider:Subclass()

function ZO_GamepadLeaderboardScoreProvider:New(notificationManager)
    return ZO_LeaderboardScoreProvider.New(self, notificationManager)
end

function ZO_GamepadLeaderboardScoreProvider:CreateMessage(contentName, score, numMembers, hasFriend, hasGuildMember, notificationId)
    local message = ZO_LeaderboardScoreProvider.CreateMessage(self, contentName, score, numMembers, hasFriend, hasGuildMember)

    return self:AppendMembers(message, numMembers, notificationId)
end

function ZO_GamepadLeaderboardScoreProvider:AppendMemberHeaderText(messageText, headerText)
    return messageText.."\n\n"..headerText
end

function ZO_GamepadLeaderboardScoreProvider:AppendMemberName(messageText, memberName)
    return messageText.."\n"..ZO_SELECTED_TEXT:Colorize(memberName)
end

function ZO_GamepadLeaderboardScoreProvider:AppendMembers(messageText, numMembers, notificationId)
    local guildMembersSection = {}
    local friendsSection = {}

    for memberIndex = 1, numMembers do
        local displayName, characterName, isFriend, isGuildMember, isPlayer = GetLeaderboardScoreNotificationMemberInfo(notificationId, memberIndex)
        local userFacingName = ZO_GetPlatformUserFacingName(characterName, displayName)

        if not isPlayer then
            if isFriend then
                table.insert(friendsSection, userFacingName)
            elseif isGuildMember then
                table.insert(guildMembersSection, userFacingName)
            end
        end
    end

    if #friendsSection > 0 then
        messageText = self:AppendMemberHeaderText(messageText, zo_strformat(GetString(SI_NOTIFICATIONS_LEADERBOARD_SCORE_NOTIFICATION_HEADER_FRIENDS), #friendsSection))

        for _, friendName in ipairs(friendsSection) do
            messageText = self:AppendMemberName(messageText, friendName)
        end
    end

    if #guildMembersSection > 0 then
        messageText = self:AppendMemberHeaderText(messageText, zo_strformat(GetString(SI_NOTIFICATIONS_LEADERBOARD_SCORE_NOTIFICATION_HEADER_GUILD_MEMBERS), #guildMembersSection))

        for _, guildMemberName in ipairs(guildMembersSection) do
            messageText = self:AppendMemberName(messageText, guildMemberName)
        end
    end

    return messageText
end

--Collections Update Provider
-------------------------

ZO_GamepadCollectionsUpdateProvider = ZO_CollectionsUpdateProvider:Subclass()

function ZO_GamepadCollectionsUpdateProvider:New(notificationManager)
    return ZO_CollectionsUpdateProvider.New(self, notificationManager)
end

function ZO_GamepadCollectionsUpdateProvider:AddCollectibleNotification(data, notificationId)
    --use a formatter for when there's more information?
    local hasMoreInfo = GetCollectibleHelpIndices(data:GetId()) ~= nil
    local message = self:GetMessage(hasMoreInfo, ZO_SELECTED_TEXT:Colorize(data:GetCategoryName()), ZO_SELECTED_TEXT:Colorize(data:GetName()))
    self:AddNotification(message, data, hasMoreInfo, notificationId)
end

function ZO_GamepadCollectionsUpdateProvider:AddNotification(message, data, hasMoreInfo, notificationId)
    local customLayoutFunction = nil
    if hasMoreInfo then
        customLayoutFunction = function(tooltip, entryData)
            GAMEPAD_TOOLTIPS:LayoutKeybindNotification(tooltip, entryData)
        end
    end

    local newListEntry = {
        dataType = NOTIFICATIONS_COLLECTIBLE_DATA,
        notificationType = NOTIFICATION_TYPE_COLLECTIONS,
        shortDisplayText = data:GetCategoryName(),

        message = message,
        data = data,
        moreInfo = hasMoreInfo,
        notificationId = notificationId,
        customLayoutFunction = customLayoutFunction,

        --For sorting
        displayName = message,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }

    table.insert(self.list, newListEntry)
end

function ZO_GamepadCollectionsUpdateProvider:Accept(entryData)
    ZO_CollectionsUpdateProvider.Accept(self, entryData)

    -- The Tribute Patron book is a different scene than the standard collections menu, so we need to handle it uniquely.
    if entryData.data:GetCategorySpecialization() == COLLECTIBLE_CATEGORY_SPECIALIZATION_TRIBUTE_PATRONS then
        GAMEPAD_TRIBUTE_PATRON_BOOK:BrowseToPatron(entryData.data:GetReferenceId())
    else
        GAMEPAD_COLLECTIONS_BOOK:BrowseToCollectible(entryData.data:GetId())
    end
end

function ZO_GamepadCollectionsUpdateProvider:GetMessage(hasMoreInfo, categoryName, collectibleName)
    if hasMoreInfo then
        local buttonText = ZO_WHITE:Colorize(ZO_Keybindings_GetHighestPriorityBindingStringFromAction("UI_SHORTCUT_RIGHT_STICK", KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP))
        return zo_strformat(SI_COLLECTIONS_UPDATED_NOTIFICATION_MESSAGE_MORE_INFO_GAMEPAD, categoryName, collectibleName, buttonText)
    else
        return zo_strformat(SI_COLLECTIONS_UPDATED_NOTIFICATION_MESSAGE, categoryName, collectibleName)
    end
end

function ZO_GamepadCollectionsUpdateProvider:ShowMoreInfo(entryData)
    local helpCategoryIndex, helpIndex = GetCollectibleHelpIndices(entryData.data:GetId())
    if helpCategoryIndex ~= nil then
        HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(helpCategoryIndex, helpIndex)
    end
end


--LFG Update Provider
-------------------------

ZO_GamepadLFGUpdateProvider = ZO_LFGUpdateProvider:Subclass()

function ZO_GamepadLFGUpdateProvider:New(notificationManager)
    return ZO_LFGUpdateProvider.New(self, notificationManager)
end


--Duel Invite Provider
-------------------------

ZO_GamepadDuelInviteProvider = ZO_DuelInviteProvider:Subclass()

function ZO_GamepadDuelInviteProvider:New(notificationManager)
    local provider = ZO_DuelInviteProvider.New(self, notificationManager)
    provider:SetCanShowGamerCard(true)
    return provider
end

-- ZO_GamepadEsoPlusSubscriptionStatusProvider
-------------------------

ZO_GamepadEsoPlusSubscriptionStatusProvider = ZO_EsoPlusSubscriptionStatusProvider:Subclass()

function ZO_GamepadEsoPlusSubscriptionStatusProvider:New(notificationManager)
    return ZO_EsoPlusSubscriptionStatusProvider.New(self, notificationManager)
end

function ZO_GamepadEsoPlusSubscriptionStatusProvider:ShowMoreInfo(entryData)
    if entryData.moreInfo then
        HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(entryData.helpCategoryIndex, entryData.helpIndex)
    end
end

-- ZO_GamepadGuildNewApplicationsProvider
------------------------------------------

ZO_GamepadGuildNewApplicationsProvider = ZO_GuildNewApplicationsProvider:Subclass()

function ZO_GamepadGuildNewApplicationsProvider:New(notificationManager)
    return ZO_GuildNewApplicationsProvider.New(self, notificationManager)
end

function ZO_GamepadGuildNewApplicationsProvider:GetAllianceIconNameText(guildAlliance, guildName)
    local FORCE_GAMEPAD = true
    return ZO_AllianceIconNameFormatter(guildAlliance, guildName, FORCE_GAMEPAD)
end

function ZO_GamepadGuildNewApplicationsProvider:Accept(entryData)
    ZO_GuildNewApplicationsProvider.Accept(self, entryData)

    GAMEPAD_GUILD_HOME:SetGuildId(entryData.guildId)
    GAMEPAD_GUILD_HOME:SetActivateScreenInfo(function() GAMEPAD_GUILD_HOME:ShowRecruitment() end, GetString(SI_WINDOW_TITLE_GUILD_RECRUITMENT))
    SCENE_MANAGER:Push("gamepad_guild_home")
    GUILD_RECRUITMENT_GAMEPAD:ShowApplicationsList()
end

-- ZO_GamepadMarketProductUnlockedProvider
-------------------------

ZO_GamepadMarketProductUnlockedProvider = ZO_MarketProductUnlockedProvider:Subclass()

function ZO_GamepadMarketProductUnlockedProvider:New(notificationManager)
    return ZO_MarketProductUnlockedProvider.New(self, notificationManager)
end

function ZO_GamepadMarketProductUnlockedProvider:ShowMoreInfo(entryData)
    if entryData.moreInfo then
        HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(entryData.helpCategoryIndex, entryData.helpIndex)
    end
end

-- ZO_GamepadPointsResetProvider
------------------------------------------

ZO_GamepadPointsResetProvider = ZO_PointsResetProvider:Subclass()

function ZO_GamepadPointsResetProvider:Accept(data)
    ZO_PointsResetProvider.Accept(self, data)
    if data.respecType == RESPEC_TYPE_ATTRIBUTES then
        MAIN_MENU_GAMEPAD:ShowScene("gamepad_stats_root")
    elseif data.respecType == RESPEC_TYPE_SKILLS then
        MAIN_MENU_GAMEPAD:ShowScene("gamepad_skills_root")
    elseif data.respecType == RESPEC_TYPE_CHAMPION or data.respecType == RESPEC_TYPE_CHAMPION_SLOTS then
        MAIN_MENU_GAMEPAD:ShowScene("gamepad_championPerks_root")
    end
end

-- ---------------------------------
--ZO_GamepadTributeInviteProvider --
------------------------------------

ZO_GamepadTributeInviteProvider = ZO_TributeInviteProvider:Subclass()

function ZO_GamepadTributeInviteProvider:New(notificationManager)
    local provider = ZO_TributeInviteProvider.New(self, notificationManager)
    provider:SetCanShowGamerCard(true)
    return provider
end

--Notification Manager
-------------------------

ZO_GamepadNotificationManager = ZO_Object:MultiSubclass(ZO_NotificationManager, ZO_Gamepad_ParametricList_Screen)

function ZO_GamepadNotificationManager:New(control)
    local notificationManager = ZO_Object.New(self)
    notificationManager:Initialize(control)
    return notificationManager
end

function ZO_GamepadNotificationManager:Initialize(control)
    
    GAMEPAD_NOTIFICATIONS_SCENE = ZO_Scene:New("gamepad_notifications_root", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true

    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_NOTIFICATIONS_SCENE)
    ZO_NotificationManager.Initialize(self, control)

    GAMEPAD_NOTIFICATIONS_SCENE:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_HIDDEN then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                ZO_SavePlayerConsoleProfile()
            end
        end)

    self:InitializeHeader()
    self:InitializeConfirmDeclineDialog()
end

function ZO_GamepadNotificationManager:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:RefreshTooltip(self.list:GetTargetData())
end

function ZO_GamepadNotificationManager:PerformUpdate()
    -- This function is required but unused
end

function ZO_GamepadNotificationManager:SetupList(list)
    local function SetupRequest(...)
        self:SetupRequest(...)
    end

    local TEMPLATE_TO_SETUP = 
    {
        ["ZO_GamepadNotificationsRequestRow"] = SetupRequest,
        ["ZO_GamepadNotificationsWaitingRow"] = function(...) self:SetupWaiting(...) end,
        ["ZO_GamepadNotificationsLeaderboardRow"] = SetupRequest,
        ["ZO_GamepadNotificationsAlertRow"] = function(...) self:SetupAlert(...) end,
        ["ZO_GamepadNotificationsCollectibleRow"] = SetupRequest,
        ["ZO_GamepadNotificationsLFGReadyCheckRow"] = SetupRequest,
        ["ZO_GamepadNotificationsLFGFindReplacementRow"] = SetupRequest,
        ["ZO_GamepadNotificationsYesNoRow"] = SetupRequest,
        ["ZO_GamepadNotificationsEsoPlusSubscriptionRow"] = SetupRequest,
        ["ZO_GamepadNotificationsGiftReceivedRow"] = SetupRequest,
        ["ZO_GamepadNotificationsGiftReturnedRow"] = SetupRequest,
        ["ZO_GamepadNotificationsGiftClaimedRow"] = SetupRequest,
        ["ZO_GamepadNotificationsOpenCrownStoreRow"] = SetupRequest,
        ["ZO_GamepadNotificationsNewDailyLoginRewardRow"] = SetupRequest,
        ["ZO_GamepadNotificationsGuildNewApplicationsRow"] = SetupRequest,
        ["ZO_GamepadNotificationsMarketProductUnlockedRow"] = SetupRequest,
        ["ZO_GamepadNotificationsPointsResetRow"] = SetupRequest,
        ["ZO_GamepadNotificationsHouseRecommendedRow"] = SetupRequest,
    }

    for template, setupCallback in pairs(TEMPLATE_TO_SETUP) do
        list:AddDataTemplate(template, setupCallback, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader(template, setupCallback, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    end

    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_GamepadNotificationManager:InitializeNotificationList(control)
    self.list = self:GetMainList()

    self.list:SetNoItemText(GetString(SI_GAMEPAD_NOTIFICATIONS_NO_NOTIFICATIONS_MESSAGE))

    self.eventNamespace = EVENT_NAMESPACE

    self.providers =
    {
        ZO_GamepadFriendRequestProvider:New(self),
        ZO_GamepadGuildInviteProvider:New(self),
        ZO_GamepadGuildMotDProvider:New(self),
        ZO_CampaignQueueProvider:New(self),
        ZO_GamepadResurrectProvider:New(self),
        ZO_GamepadGroupInviteProvider:New(self),
        ZO_GroupElectionProvider:New(self),
        ZO_GamepadTradeInviteProvider:New(self),
        ZO_GamepadQuestShareProvider:New(self),
        ZO_GamepadPointsResetProvider:New(self),
        ZO_CraftedAbilityResetProvider:New(self),
        ZO_GamepadPledgeOfMaraProvider:New(self),
        ZO_GamepadAgentChatRequestProvider:New(self),
        ZO_GamepadLeaderboardScoreProvider:New(self),
        ZO_GamepadCollectionsUpdateProvider:New(self),
        ZO_GamepadLFGUpdateProvider:New(self),
        ZO_CraftBagAutoTransferProvider:New(self),
        ZO_GamepadDuelInviteProvider:New(self),
        ZO_GamepadEsoPlusSubscriptionStatusProvider:New(self),
        ZO_GiftInventoryProvider:New(self),
        ZO_DailyLoginRewardsClaimProvider:New(self),
        ZO_GamepadGuildNewApplicationsProvider:New(self),
        ZO_PlayerApplicationsProvider:New(self),
        ZO_GamepadMarketProductUnlockedProvider:New(self),
        ZO_ExpiringMarketCurrencyProvider:New(self),
        ZO_OutOfDateAddonsProvider:New(self),
        ZO_DisabledAddonsProvider:New(self),
        ZO_GamepadTributeInviteProvider:New(self),
        ZO_HouseToursHouseRecommendedProvider:New(self),
    }
end

function ZO_GamepadNotificationManager:InitializeKeybindStripDescriptors()
    --ESO-807711: In some cases, accepting or declining can trigger an alert.
    --If the re-narration has already started by the time the alert comes in, the alert will stomp it (since alerts take priority) and can occasionally make it seem like no re-narration occurred at all
    --In order to help mitigate this, we let the narration of the parametric list sit in the queue a bit longer than usual before sending it into the API. This will not solve all cases, but will significantly reduce the likelihood of hitting it.
    local OVERRIDE_NARRATION_DELAY_MS = 350

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Accept Request
        {
            name = function()
                local data = self:GetTargetData()
                if data and data.acceptText then
                    return data.acceptText
                else
                    return ""
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local data = self:GetTargetData()
                if data ~= nil then
                    self:AcceptRequest(data)
                    --Re-narrate when a request is accepted
                    local DEFAULT_NARRATE_HEADER = nil
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list, DEFAULT_NARRATE_HEADER, OVERRIDE_NARRATION_DELAY_MS)
                end
            end,

            visible = function()
                local data = self:GetTargetData()
                return data and data.acceptText ~= nil
            end
        },

        -- Decline Request
        {
            name = function()
                local data = self:GetTargetData()
                if data and data.declineText then
                    return data.declineText
                else
                    return ""
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local data = self:GetTargetData()
                if data ~= nil then
                    if data.dataType == NOTIFICATIONS_LFG_READY_CHECK_DATA then
                        local dialogData =
                        {
                            data = data,
                            control = nil,
                            openedFromKeybind = NOTIFICATIONS_MENU_OPENED_FROM_MOUSE,
                        }
                        ZO_Dialogs_ShowPlatformDialog("LFG_DECLINE_READY_CHECK_CONFIRMATION", dialogData)
                    else
                        self:DeclineRequest(data, nil, NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND)
                        --Re-narrate when a request is declined
                        local DEFAULT_NARRATE_HEADER = nil
                        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list, DEFAULT_NARRATE_HEADER, OVERRIDE_NARRATION_DELAY_MS)
                    end
                end
            end,

            visible = function()
                local data = self:GetTargetData()
                return data and data.declineText ~= nil
            end
        },

        -- More Information or Report Guild
        {
            name = function()
                local data = self:GetTargetData()
                if data ~= nil and data.notificationType == NOTIFICATION_TYPE_PLAYER_APPLICATIONS then
                    return GetString(SI_GUILD_BROWSER_REPORT_GUILD_KEYBIND)
                else
                    return GetString(SI_NOTIFICATIONS_MORE_INFO)
                end
            end,

            keybind = "UI_SHORTCUT_RIGHT_STICK",

            callback = function()
                local data = self:GetTargetData()
                if data then
                    if data.notificationType == NOTIFICATION_TYPE_PLAYER_APPLICATIONS then
                        local function ReportCallback()
                            -- TODO: Not sure if we need this
                        end
                        ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(data.guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_DECLINE, ReportCallback)
                    else
                        self:ShowMoreInfo(data)
                    end
                end
            end,

            visible = function()
                local data = self:GetTargetData()
                if data then
                    if data.notificationType == NOTIFICATION_TYPE_PLAYER_APPLICATIONS then
                        return data.showReportKeybind
                    elseif data.moreInfo then
                        return true
                    end
                end
                return false
            end,
        },

        --View Gamercard
        {
            name = GetString(ZO_GetGamerCardStringId()),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local data = self:GetTargetData()
                if data ~= nil then
                    data.provider:ShowGamerCard(data)
                end
            end,
            visible = function()
                if IsConsoleUI() then
                    local data = self:GetTargetData()
                    if data ~= nil then
                        return data.provider:CanShowGamerCard()
                    end
                end
            end
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function ZO_GamepadNotificationManager:RefreshTooltip(entryData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if entryData and entryData.data then
        if entryData.data.customLayoutFunction then
            entryData.data.customLayoutFunction(GAMEPAD_LEFT_TOOLTIP, entryData.data)
        else
            local messageText = self:BuildMessageText(entryData.data)
            GAMEPAD_TOOLTIPS:LayoutNotification(GAMEPAD_LEFT_TOOLTIP, entryData.data.note, messageText)
        end
        GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_LEFT_TOOLTIP)
    else
        GAMEPAD_TOOLTIPS:HideBg(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GamepadNotificationManager:InitializeHeader()
    self.headerData = {
        titleText = GetString(SI_GAMEPAD_NOTIFICATIONS_CATEGORY_HEADER),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GamepadNotificationManager:InitializeConfirmDeclineDialog()
    local dialogName = GAMEPAD_NOTIFICATIONS_CONFIRM_DECLINE_DIALOG_NAME

    local declineOption =
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData = {
                text = GetString(SI_GAMEPAD_NOTIFICATIONS_DECLINE_OPTION),
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function(dialog)
                    dialog.data.declineFunction()
                end
            },
        }
    local ignoreOption =
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData = {
                text = GetString(IsConsoleUI() and SI_GAMEPAD_NOTIFICATIONS_REQUEST_BLOCK_PLAYER or SI_GAMEPAD_NOTIFICATIONS_REQUEST_IGNORE_PLAYER),
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function(dialog)
                    dialog.data.ignoreFunction()
                end
            },
        }
    local reportOption = 
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData = {
                text = GetString(SI_GAMEPAD_NOTIFICATIONS_REQUEST_REPORT_SPAMMING),
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function(dialog)
                    dialog.data.reportFunction()
                end
            },
        }

    local parametricListOptions = {}
    table.insert(parametricListOptions, declineOption)
    if not IsConsoleUI() or ZO_DoesConsoleSupportTargetedIgnore() then
        table.insert(parametricListOptions, ignoreOption)
    end
    table.insert(parametricListOptions, reportOption)

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_GAMEPAD_NOTIFICATIONS_DECLINE_INVITE,
        },

        mainText =
        {
            text = function(dialog)
                return dialog.data.mainText()
            end,
        },
        parametricList = parametricListOptions,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_OK,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                     data.callback(dialog)
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end

function ZO_GamepadNotificationManager:ClearNotificationList()
    self.list:Clear() 
end

function ZO_GamepadNotificationManager:RefreshVisible()
    self.list:RefreshVisible()
    local entryData = self.list:GetTargetData()
    self:RefreshTooltip(entryData)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadNotificationManager:AddDataEntry(dataType, data, isHeader)
    local icon = ZO_GAMEPAD_NOTIFICATION_ICONS[data.notificationType]
    if type(icon) == "function" then
        icon = icon(data)
    end
    local entryData = ZO_GamepadEntryData:New(data.shortDisplayText, icon)
    entryData.data = data
    entryData:SetIconTintOnSelection(true)
    entryData:SetIconDisabledTintOnSelection(true)

    if isHeader then
        entryData:SetHeader(zo_strformat(SI_NOTIFICATIONS_TYPE_FORMATTER, GetString("SI_NOTIFICATIONTYPE", data.notificationType)))
        self.list:AddEntryWithHeader(ZO_NOTIFICATION_TYPE_TO_GAMEPAD_TEMPLATE[dataType], entryData)
    else
        self.list:AddEntry(ZO_NOTIFICATION_TYPE_TO_GAMEPAD_TEMPLATE[dataType], entryData)
    end
end

function ZO_GamepadNotificationManager:GetTargetData()  
    local entryData = self.list:GetTargetData()
    if entryData then
        return entryData.data
    else
        return nil
    end
end

function ZO_GamepadNotificationManager:FinishNotificationList()
    self.list:Commit()
    self.list:RefreshVisible()
end

function ZO_GamepadNotificationManager:BuildEmptyList()
end

function ZO_GamepadNotificationManager:OnSelectionChanged(_, selected)
    if not self.control:IsControlHidden() then
        self:RefreshTooltip(selected)
    end
end

function ZO_GamepadNotificationManager:OnNumNotificationsChanged(totalNumNotifications)
     MAIN_MENU_GAMEPAD:OnNumNotificationsChanged(totalNumNotifications)
     KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

     if(NOTIFICATION_ICONS_CONSOLE) then
        NOTIFICATION_ICONS_CONSOLE:OnNumNotificationsChanged(totalNumNotifications)
     end
end

function ZO_GamepadNotificationManager:SetupRequest(control, entryData, selected)
    ZO_SharedGamepadEntry_OnSetup(control, entryData, selected)
    local data = entryData.data
    self:SetupBaseRow(control, data, selected)
end

function ZO_GamepadNotificationManager:SetupAlert(control, entryData, selected)
    ZO_SharedGamepadEntry_OnSetup(control, entryData, selected)
    local data = entryData.data
    self:SetupBaseRow(control, data, selected)
end

function ZO_GamepadNotificationManager:SetupWaiting(control, entryData, selected)
    ZO_SharedGamepadEntry_OnSetup(control, entryData, selected)
    local data = entryData.data
    self:SetupBaseRow(control, data, selected)
    local loadingText = control:GetNamedChild("Text")
    loadingText:SetText(data.loadText)
end

function ZO_GamepadNotificationManager:SetupBaseRow(control, data, selected)
    if data.acceptText == nil then
        data.acceptText = control.acceptText
    end

    if data.declineText == nil then
        data.declineText = control.declineText
    end
end

--Global XML

function ZO_GamepadNotifications_OnInitialized(self)
    GAMEPAD_NOTIFICATIONS = ZO_GamepadNotificationManager:New(self)
end
