NOTIFICATIONS_REQUEST_DATA = 1
NOTIFICATIONS_WAITING_DATA = 2
NOTIFICATIONS_LEADERBOARD_DATA = 3
NOTIFICATIONS_ALERT_DATA = 4
NOTIFICATIONS_COLLECTIBLE_DATA = 5
NOTIFICATIONS_LFG_JUMP_DUNGEON_DATA = 6
NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA = 7

NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND = 1
NOTIFICATIONS_MENU_OPENED_FROM_MOUSE = 2

-- Notification Provider
-------------------------

ZO_NotificationProvider = ZO_Object:Subclass()

function ZO_NotificationProvider:New(notificationManager)
    local provider = ZO_Object.New(self)
    provider.list = {}
    provider.hasTimer = false
    provider.notificationManager = notificationManager

    provider.pushUpdateCallback = function()
        provider:PushUpdateToNotificationManager()
    end
    return provider
end

function ZO_NotificationProvider:SetHasTimer(hasTimer)
    self.hasTimer = hasTimer
end

function ZO_NotificationProvider:GetHasTimer()
    return self.hasTimer
end

function ZO_NotificationProvider:GetNumNotifications()
    return #self.list
end

function ZO_NotificationProvider:AddDataEntry(list, i, isHeader)
    self.list[i].provider = self
    self.notificationManager:AddDataEntry(self.list[i].dataType, self.list[i], isHeader)
end

function ZO_NotificationProvider:PushUpdateToNotificationManager()
    self.notificationManager:RefreshNotificationList()
end

function ZO_NotificationProvider:RegisterUpdateEvent(event)
    EVENT_MANAGER:RegisterForEvent(self.notificationManager.eventNamespace, event, self.pushUpdateCallback)
end

function ZO_NotificationProvider:BuildNotificationList()

end

function ZO_NotificationProvider:Accept(data)

end

function ZO_NotificationProvider:Decline(data, button, openedFromKeybind)

end

function ZO_NotificationProvider:ShowMoreInfo(data)
    
end

function ZO_NotificationProvider:CanShowGamerCard()
    return false
end

--Friend Request Provier
-------------------------

ZO_FriendRequestProvider = ZO_NotificationProvider:Subclass()

function ZO_FriendRequestProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_INCOMING_FRIEND_INVITE_ADDED)
    provider:RegisterUpdateEvent(EVENT_INCOMING_FRIEND_INVITE_REMOVED)
    provider:RegisterUpdateEvent(EVENT_INCOMING_FRIEND_INVITE_NOTE_UPDATED)

    return provider
end

function ZO_FriendRequestProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)
    for i = 1, GetNumIncomingFriendRequests() do
        local displayName, secsSinceRequest, note = GetIncomingFriendRequestInfo(i)
		local userFacingDisplayName = ZO_FormatUserFacingDisplayName(displayName)
        local message = self:CreateMessage(userFacingDisplayName)
        self.list[i] =  {
                            dataType = NOTIFICATIONS_REQUEST_DATA,
                            displayName = displayName,
                            notificationType = NOTIFICATION_TYPE_FRIEND,
                            secsSinceRequest = ZO_NormalizeSecondsSince(secsSinceRequest),
                            note = note,
                            message = message,
                            shortDisplayText = userFacingDisplayName,
                            controlsOwnSounds = true,
							incomingFriendIndex = i,
                        }
    end
end

function ZO_FriendRequestProvider:Accept(data)
    AcceptFriendRequest(data.displayName)
    PlaySound(SOUNDS.DIALOG_ACCEPT)
end

--Guild Invite Provider
-------------------------

ZO_GuildInviteProvider = ZO_NotificationProvider:Subclass()

function ZO_GuildInviteProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_GUILD_INVITES_INITIALIZED)
    provider:RegisterUpdateEvent(EVENT_GUILD_INVITE_ADDED)
    provider:RegisterUpdateEvent(EVENT_GUILD_INVITE_REMOVED)

    return provider
end

function ZO_GuildInviteProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    for i = 1, GetNumGuildInvites() do
        local guildId, guildName, guildAlliance, inviterDisplayName, note = GetGuildInviteInfo(i)
        local secsSinceRequest = 0
        local formattedInviterName = ZO_FormatUserFacingDisplayName(inviterDisplayName)
        local message = self:CreateMessage(guildAlliance, guildName, formattedInviterName)
        self.list[i] =  {
                            dataType = NOTIFICATIONS_REQUEST_DATA,
                            guildId = guildId,
                            guildAlliance = guildAlliance,
                            guildName = guildName,
                            displayName = inviterDisplayName,
                            notificationType = NOTIFICATION_TYPE_GUILD,
                            secsSinceRequest = ZO_NormalizeSecondsSince(secsSinceRequest),
                            note = note,
                            message = message,
                            shortDisplayText = formattedInviterName,
                            controlsOwnSounds = true,
                        }
    end
end

function ZO_GuildInviteProvider:Accept(data)
    PlaySound(SOUNDS.DIALOG_ACCEPT)
    AcceptGuildInvite(data.guildId)
end

function ZO_GuildInviteProvider:Decline(data, button, openedFromKeybind)
    PlaySound(SOUNDS.DIALOG_DECLINE)
    RejectGuildInvite(data.guildId)
end

--Guild MotD Provider
----------------------

ZO_GuildMotDProvider = ZO_NotificationProvider:Subclass()

function ZO_GuildMotDProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)
    EVENT_MANAGER:RegisterForEvent(provider.notificationManager.eventNamespace.."MotDProvider", EVENT_ADD_ON_LOADED, function(_, name) provider:OnAddOnLoaded(name) end)
    return provider
end

function ZO_GuildMotDProvider:BuildNotificationList()
    if self.sv then
        ZO_ClearNumericallyIndexedTable(self.list)

        for i = 1, GetNumGuilds() do
            local guildId = GetGuildId(i)
            local guildName = GetGuildName(guildId)
            local savedMotDHash = self.sv[guildName]
            local currentMotD = GetGuildMotD(guildId)
            local currentMotDHash = HashString(currentMotD)

            if savedMotDHash == nil then
                self.sv[guildName] = currentMotDHash
            elseif savedMotDHash ~= currentMotDHash then
                local guildAlliance = GetGuildAlliance(guildId)
                local message = self:CreateMessage(guildAlliance, guildName)
                table.insert(self.list,
                {
                    dataType = NOTIFICATIONS_ALERT_DATA,
                    notificationType = NOTIFICATION_TYPE_GUILD_MOTD,
                    note = currentMotD,
                    message = message,
                    guildId = guildId,
                    shortDisplayText = guildName,
                })           
            end
        end
    end
end

function ZO_GuildMotDProvider:MarkMotDRead(data)
    local guildId = data.guildId
    local guildName = GetGuildName(guildId)
    local guildMotD = GetGuildMotD(guildId)
    local guildMotDHash = HashString(guildMotD)

    self.sv[guildName] = guildMotDHash
    CALLBACK_MANAGER:FireCallbacks("NotificationsGuildMotDRead", guildId)
end

function ZO_GuildMotDProvider:Decline(data)
    self:MarkMotDRead(data)
end

function ZO_GuildMotDProvider:OnAddOnLoaded(name)
    if name == "ZO_Ingame" then
        self.sv = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "GuildMotD")
        self:RegisterUpdateEvent(EVENT_GUILD_DATA_LOADED)
        self:RegisterUpdateEvent(EVENT_GUILD_MOTD_CHANGED)
        CALLBACK_MANAGER:RegisterCallback("NotificationsGuildMotDRead", self.pushUpdateCallback)
        self:PushUpdateToNotificationManager()
    end
end

function ZO_GuildMotDProvider:CreateMessage(guildAlliance, guildName)
    -- Overridden if necessary
    local allianceIcon = zo_iconFormat(GetAllianceBannerIcon(guildAlliance), 24, 24)
    return zo_strformat(SI_GUILD_MOTD_CHANGED_NOTIFICATION, allianceIcon, guildName)
end

--Campaign Queue Provider
-------------------------

ZO_CampaignQueueProvider = ZO_NotificationProvider:Subclass()

function ZO_CampaignQueueProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)
    provider:SetHasTimer(true)

    provider:RegisterUpdateEvent(EVENT_CAMPAIGN_QUEUE_JOINED)
    provider:RegisterUpdateEvent(EVENT_CAMPAIGN_QUEUE_LEFT)
    provider:RegisterUpdateEvent(EVENT_CAMPAIGN_QUEUE_STATE_CHANGED)

    return provider
end

function ZO_CampaignQueueProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local numConfirmingQueues = 0
    local confirmDuration = GetCampaignQueueConfirmationDuration()

    for i = 1, GetNumCampaignQueueEntries() do
        local campaignId, isGroup = GetCampaignQueueEntry(i)
        local currentState = GetCampaignQueueState(campaignId, isGroup)
        local campaignName = GetCampaignName(campaignId)
        if(currentState == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
            local remainingSeconds = GetCampaignQueueRemainingConfirmationSeconds(campaignId, isGroup)
            local secsSinceRequest = confirmDuration - remainingSeconds
            numConfirmingQueues = numConfirmingQueues + 1
            table.insert(self.list, {
                                        dataType = NOTIFICATIONS_REQUEST_DATA,
                                        campaignId = campaignId,
                                        isGroup = isGroup,
                                        notificationType = NOTIFICATION_TYPE_CAMPAIGN_QUEUE,
                                        secsSinceRequest = ZO_NormalizeSecondsSince(secsSinceRequest),
                                        campaignName = campaignName,
                                        messageFormat = self:CreateMessageFormat(isGroup),
                                        messageParams = { campaignName },
                                        expiresAt = GetFrameTimeSeconds() + remainingSeconds,
                                        shortDisplayText = campaignName,
                                    })
        elseif(currentState == CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_ACCEPT) then
            table.insert(self.list, {
                                        dataType = NOTIFICATIONS_WAITING_DATA,
                                        notificationType = NOTIFICATION_TYPE_CAMPAIGN_QUEUE,
                                        secsSinceRequest = ZO_NormalizeSecondsSince(0),
                                        loadText = self:CreateLoadText(),
                                        shortDisplayText = campaignName,
                                    })
        end
    end
end

function ZO_CampaignQueueProvider:Decline(data, button, openedFromKeybind)
    ConfirmCampaignEntry(data.campaignId, data.isGroup, false)
end

--Resurrect Provider
-------------------------

ZO_ResurrectProvider = ZO_NotificationProvider:Subclass()

function ZO_ResurrectProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)
    provider:SetHasTimer(true)

    provider:RegisterUpdateEvent(EVENT_RESURRECT_REQUEST)
    provider:RegisterUpdateEvent(EVENT_RESURRECT_REQUEST_REMOVED)
    provider:RegisterUpdateEvent(EVENT_PLAYER_ALIVE)

    return provider
end

function ZO_ResurrectProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if(IsResurrectPending()) then
        local resurrectRequesterCharacterName, timeLeftToAcceptMs, resurrectRequesterDisplayName = GetPendingResurrectInfo()
        local timeLeftToAcceptS = timeLeftToAcceptMs / 1000
        local nameToShow = self:GetNameToShow(resurrectRequesterCharacterName, resurrectRequesterDisplayName)
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_RESURRECT,
            secsSinceRequest = ZO_NormalizeSecondsUntil(timeLeftToAcceptS),
            messageFormat = self:GetMessageFormat(),
            messageParams = { nameToShow },
            expiresAt = timeLeftToAcceptS + GetFrameTimeSeconds(),
            shortDisplayText = nameToShow,
            resurrectRequesterCharacterName = resurrectRequesterCharacterName,
            resurrectRequesterDisplayName = resurrectRequesterDisplayName,
        })
    end
end

function ZO_ResurrectProvider:Accept(data)
    AcceptResurrect()
end

function ZO_ResurrectProvider:Decline(data, button, openedFromKeybind)
    DeclineResurrect()
end

--Group Invite Provider
-------------------------

ZO_GroupInviteProvider = ZO_NotificationProvider:Subclass()

function ZO_GroupInviteProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_GROUP_INVITE_RECEIVED)
    provider:RegisterUpdateEvent(EVENT_GROUP_INVITE_REMOVED)

    return provider
end

function ZO_GroupInviteProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local inviterCharacterName, aMillisecondsSinceRequest, inviterDisplayName = GetGroupInviteInfo()
    local nameToUse = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(inviterDisplayName) or inviterCharacterName
    if(nameToUse ~= "") then
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_GROUP,
            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
            message = self:CreateMessage(nameToUse),
            inviterCharacterName = inviterCharacterName,
            shortDisplayText = zo_strformat(SI_NOTIFICATIONS_LIST_ENTRY, nameToUse)
        })
    end
end

function ZO_GroupInviteProvider:Accept(data)
    AcceptGroupInvite()
end

function ZO_GroupInviteProvider:Decline(data, button, openedFromKeybind)
    DeclineGroupInvite()
end

--Trade Invite Provider
-------------------------

ZO_TradeInviteProvider = ZO_NotificationProvider:Subclass()

function ZO_TradeInviteProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_TRADE_INVITE_CONSIDERING)
    provider:RegisterUpdateEvent(EVENT_TRADE_INVITE_REMOVED)

    return provider
end

function ZO_TradeInviteProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local inviterCharacterName, aMillisecondsSinceRequest, inviterDisplayName = GetTradeInviteInfo()
    if(inviterCharacterName ~= "") then
        local userFacingInviterName = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(inviterDisplayName) or inviterCharacterName
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_TRADE,
            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
            message = self:CreateMessage(userFacingInviterName),
            shortDisplayText = zo_strformat(SI_NOTIFICATIONS_LIST_ENTRY, userFacingInviterName),
            inviterCharacterName = ZO_StripGrammarMarkupFromCharacterName(inviterCharacterName),
        })
    end
end

function ZO_TradeInviteProvider:Accept(data)
    TradeInviteAccept()
end

function ZO_TradeInviteProvider:Decline(data, button, openedFromKeybind)
    TradeInviteDecline()
end

--Quest Share Provider
-------------------------

ZO_QuestShareProvider = ZO_NotificationProvider:Subclass()

function ZO_QuestShareProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_QUEST_SHARED)
    provider:RegisterUpdateEvent(EVENT_QUEST_SHARE_REMOVED)

    return provider
end

function ZO_QuestShareProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local questShareIds = { GetOfferedQuestShareIds() }
    for i, questId in ipairs(questShareIds) do
        local questName, characterName, aMillisecondsSinceRequest, displayName = GetOfferedQuestShareInfo(questId)
        local displayText = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(displayName) or characterName
        self.list[i] =  {
                            dataType = NOTIFICATIONS_REQUEST_DATA,
                            notificationType = NOTIFICATION_TYPE_QUEST_SHARE,
                            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
                            message = self:CreateMessage(characterName, displayName, questName),
                            questId = questId,
                            shortDisplayText = displayText,
                            controlsOwnSounds = true,
                            playerName = characterName,
                        }
    end
end

function ZO_QuestShareProvider:Accept(data)
    PlaySound(SOUNDS.QUEST_SHARE_ACCEPTED)
    AcceptSharedQuest(data.questId)
end

function ZO_QuestShareProvider:Decline(data, button, openedFromKeybind)
    PlaySound(SOUNDS.QUEST_SHARE_DECLINED)
    DeclineSharedQuest(data.questId)
end

--Point Reset Provider
-------------------------

ZO_PointsResetProvider = ZO_NotificationProvider:Subclass()
-- callback object so that keyboard and gamepad can be updated in tandum when the user accepts the notification
ZO_PointsResetProvider_CallbackObject = ZO_CallbackObject:Subclass()

do
    local CALLBACK_POINT_RESET_ATTRIBUTE_FORCE_RESPEC = "EventPointResetAttributeForceRespec"
    local CALLBACK_POINT_RESET_SKILL_FORCE_RESPEC = "EventPointResetSkillForceRespec"
    local CALLBACK_POINT_RESET_ATTRIBUTE_DECLINED = "EventPointResetAttributeDeclined"
    local CALLBACK_POINT_RESET_SKILL_DECLINED = "EventPointResetSkillDeclined"

    local POINT_TYPE_ATTRIBUTE = 1
    local POINT_TYPE_SKILL = 2

    -- ZO_PointsResetProvider_CallbackObject functions --
    -----------------------------------------------------
    function ZO_PointsResetProvider_CallbackObject:New()
        local newObject = ZO_CallbackObject.New(self)
        newObject:Initialize()
        return newObject
    end

    function ZO_PointsResetProvider_CallbackObject:Initialize()
        self.showAttributesReset = false
        self.showSkillsReset = false

        local ZO_POINT_RESET_PROVIDER_NAME = "points reset provider"

        EVENT_MANAGER:RegisterForEvent(ZO_POINT_RESET_PROVIDER_NAME, EVENT_ATTRIBUTE_FORCE_RESPEC, function() 
                                                                                                            self.showAttributesReset = true
                                                                                                            self:FireCallbacks(CALLBACK_POINT_RESET_ATTRIBUTE_FORCE_RESPEC)
                                                                                                        end
                                                                                                        )
        EVENT_MANAGER:RegisterForEvent(ZO_POINT_RESET_PROVIDER_NAME, EVENT_SKILL_FORCE_RESPEC, function() 
                                                                                                        self.showSkillsReset = true
                                                                                                        self:FireCallbacks(CALLBACK_POINT_RESET_SKILL_FORCE_RESPEC)
                                                                                                    end
                                                                                                    )
    end

    function ZO_PointsResetProvider_CallbackObject:GetAttributesReset()
        return self.showAttributesReset
    end

    function ZO_PointsResetProvider_CallbackObject:GetSkillsReset()
        return self.showSkillsReset
    end

    function ZO_PointsResetProvider_CallbackObject:DeclineAttributesReset()
        self.showAttributesReset = false
        self:FireCallbacks(CALLBACK_POINT_RESET_ATTRIBUTE_DECLINED)
    end

    function ZO_PointsResetProvider_CallbackObject:DeclineSkillsReset()
        self.showSkillsReset = false
        self:FireCallbacks(CALLBACK_POINT_RESET_SKILL_DECLINED)
    end


    local pointResetCallbackObject = ZO_PointsResetProvider_CallbackObject:New()


    -- ZO_PointsResetProvider functions --
    --------------------------------------
    function ZO_PointsResetProvider:New(notificationManager, name)
        local provider = ZO_NotificationProvider.New(self, notificationManager)

        local function updatePointsResetList() 
            provider:PushUpdateToNotificationManager() 
        end

        pointResetCallbackObject:RegisterCallback(CALLBACK_POINT_RESET_ATTRIBUTE_DECLINED, updatePointsResetList)
        pointResetCallbackObject:RegisterCallback(CALLBACK_POINT_RESET_ATTRIBUTE_FORCE_RESPEC, updatePointsResetList)

        pointResetCallbackObject:RegisterCallback(CALLBACK_POINT_RESET_SKILL_FORCE_RESPEC, updatePointsResetList)
        pointResetCallbackObject:RegisterCallback(CALLBACK_POINT_RESET_SKILL_DECLINED, updatePointsResetList)

        return provider
    end

    function ZO_PointsResetProvider:BuildNotificationList()
        ZO_ClearNumericallyIndexedTable(self.list)
    
        if pointResetCallbackObject:GetSkillsReset() then
            table.insert(self.list,
                            {
                                dataType = NOTIFICATIONS_ALERT_DATA,
                                notificationType = NOTIFICATION_TYPE_POINTS_RESET,
                                message = GetString(SI_NOTIFICATIONS_POINTS_RESET_SKILLS),
                                shortDisplayText = GetString(SI_SKILLS_FORCE_RESPEC_TITLE),
                                pointType = POINT_TYPE_SKILL
                            }
                        )
        end

        if pointResetCallbackObject:GetAttributesReset() then
            table.insert(self.list,  
                            {
                                dataType = NOTIFICATIONS_ALERT_DATA,
                                notificationType = NOTIFICATION_TYPE_POINTS_RESET,
                                message = GetString(SI_NOTIFICATIONS_POINTS_RESET_ATTRIBUTES),
                                shortDisplayText = GetString(SI_ATTRIBUTE_FORCE_RESPEC_TITLE),
                                pointType = POINT_TYPE_ATTRIBUTE
                            }
                        )
        end
    end

    function ZO_PointsResetProvider:Decline(data)
        if data.pointType == POINT_TYPE_ATTRIBUTE then
            pointResetCallbackObject:DeclineAttributesReset()
        elseif data.pointType == POINT_TYPE_SKILL then
            pointResetCallbackObject:DeclineSkillsReset()
        end
    end

end

--Pledge of Mara Provider
-------------------------

ZO_PledgeOfMaraProvider = ZO_NotificationProvider:Subclass()

function ZO_PledgeOfMaraProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_PLEDGE_OF_MARA_OFFER)
    provider:RegisterUpdateEvent(EVENT_PLEDGE_OF_MARA_OFFER_REMOVED)

    return provider
end

function ZO_PledgeOfMaraProvider:CreateParticipantMessage(targetName, isSender)
    if isSender then
        return self:CreateSenderMessage(targetName)
    else
        return self:CreateMessage(targetName)
    end
end

function ZO_PledgeOfMaraProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local targetCharacterName, aMillisecondsSinceRequest, isSender, targetDisplayName = GetPledgeOfMaraOfferInfo() 
    if(targetCharacterName ~= "") then
		local userFacingDisplayName = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(targetDisplayName) or targetCharacterName
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_PLEDGE_OF_MARA,
            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
            message = self:CreateParticipantMessage(userFacingDisplayName, isSender),
            shortDisplayText = userFacingDisplayName,
            targetCharacterName = targetCharacterName,
        })
    end
end

function ZO_PledgeOfMaraProvider:Accept(data)
    SendPledgeOfMaraResponse(PLEDGE_OF_MARA_RESPONSE_ACCEPT)
end

function ZO_PledgeOfMaraProvider:Decline(data, button, openedFromKeybind)
    SendPledgeOfMaraResponse(PLEDGE_OF_MARA_RESPONSE_DECLINE)
end

-- CS Chat Request Provider
-------------------------

ZO_AgentChatRequestProvider = ZO_NotificationProvider:Subclass()

function ZO_AgentChatRequestProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_AGENT_CHAT_REQUESTED)
    provider:RegisterUpdateEvent(EVENT_AGENT_CHAT_ACCEPTED)
    provider:RegisterUpdateEvent(EVENT_AGENT_CHAT_DECLINED)

    return provider
end

function ZO_AgentChatRequestProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local isRequested, millisecondsSinceRequest = GetAgentChatRequestInfo()

    if(isRequested) then
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_CUSTOMER_SERVICE,
            secsSinceRequest = ZO_NormalizeSecondsSince(millisecondsSinceRequest / 1000),
            message = self:CreateMessage(),
            shortDisplayText = GetString(SI_CHAT_TAB_GENERAL),
        })
    end
end

function ZO_AgentChatRequestProvider:CreateMessage()
    return GetString(SI_AGENT_CHAT_REQUEST_MESSAGE)
end

function ZO_AgentChatRequestProvider:Accept(data)
    AcceptAgentChat()
end

function ZO_AgentChatRequestProvider:Decline(data, button, openedFromKeybind)
    DeclineAgentChat()
end

--Leaderboard Raid Provider
-------------------------

ZO_LeaderboardRaidProvider = ZO_NotificationProvider:Subclass()

function ZO_LeaderboardRaidProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_RAID_SCORE_NOTIFICATION_ADDED)
    provider:RegisterUpdateEvent(EVENT_RAID_SCORE_NOTIFICATION_REMOVED)

    local function ShowLeaderBoardNotifications_SettingsChanged()
        provider:PushUpdateToNotificationManager()
    end

    CALLBACK_MANAGER:RegisterCallback("LeaderboardNotifications_On", ShowLeaderBoardNotifications_SettingsChanged)
    CALLBACK_MANAGER:RegisterCallback("LeaderboardNotifications_Off", ShowLeaderBoardNotifications_SettingsChanged)

    provider:BuildNotificationList()
    
    return provider
end

function ZO_LeaderboardRaidProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_LEADERBOARD_NOTIFICATIONS) then
        for notificationIndex = 1, GetNumRaidScoreNotifications() do
            local notificationId = GetRaidScoreNotificationId(notificationIndex)
            local raidId, raidScore, millisecondsSinceRequest = GetRaidScoreNotificationInfo(notificationId)
            local numMembers = GetNumRaidScoreNotificationMembers(notificationId)
            local hasFriend = false
            local hasGuildMember = false
            for memberIndex = 1, numMembers do
                local displayName, characterName, isFriend, isGuildMember = GetRaidScoreNotificationMemberInfo(notificationId, memberIndex)
                hasFriend = hasFriend or isFriend
                hasGuildMember = hasGuildMember or isGuildMember
           
            end

            if(hasFriend or hasGuildMember) then
                local raidName = GetRaidName(raidId)
     
                table.insert(self.list,
                {
                    dataType = NOTIFICATIONS_LEADERBOARD_DATA,
                    notificationId = notificationId,
                    raidId = raidId,
                    notificationType = NOTIFICATION_TYPE_LEADERBOARD,
                    secsSinceRequest = ZO_NormalizeSecondsSince(millisecondsSinceRequest / 1000),
                    message = self:CreateMessage(raidName, raidScore, hasFriend, hasGuildMember),
                    shortDisplayText = zo_strformat(SI_NOTIFICATIONS_LEADERBOARD_RAID_NOTIFICATION_SHORT_TEXT_FORMATTER, raidName),
                })
            end
        end
    end
end

local OPEN_LEADERBOARDS = true

function ZO_LeaderboardRaidProvider:Accept(data)
    local raidLeaderboardsObject = SYSTEMS:GetObject("raidLeaderboards")
    raidLeaderboardsObject:SelectRaidById(data.raidId, RAID_LEADERBOARD_SELECT_OPTION_SKIP_WEEKLY, OPEN_LEADERBOARDS)
    RemoveRaidScoreNotification(data.notificationId)
end

function ZO_LeaderboardRaidProvider:Decline(data, button, openedFromKeybind)
    RemoveRaidScoreNotification(data.notificationId)
end

--Collections Update Provider
-------------------------

ZO_CollectionsUpdateProvider = ZO_NotificationProvider:Subclass()

function ZO_CollectionsUpdateProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_COLLECTIBLE_NOTIFICATION_NEW)
    provider:RegisterUpdateEvent(EVENT_COLLECTIBLE_NOTIFICATION_REMOVED)

    provider:BuildNotificationList()
    
    return provider
end

function ZO_CollectionsUpdateProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    for index = 1, GetNumCollectibleNotifications() do
        local notificationId, collectibleId = GetCollectibleNotificationInfo(index)
        local data = self:CreateCollectibleNotificationData(notificationId, collectibleId)
        
        if data then
            self:AddCollectibleNotification(data)
        end
    end
end

function ZO_CollectionsUpdateProvider:CreateCollectibleNotificationData(notificationId, collectibleId)
    if not IsCollectiblePlaceholder(collectibleId) then
        local collectibleName = GetCollectibleName(collectibleId)
        local categoryIndex, subcategoryIndex = GetCategoryInfoFromCollectibleId(collectibleId)

        local categoryName = GetCollectibleCategoryInfo(categoryIndex)
        local subcategoryName = subcategoryIndex and GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex) or nil

        return {
            notificationId = notificationId,
            collectibleId = collectibleId,
            collectibleName = collectibleName,

            categoryIndex = categoryIndex,
            categoryName = categoryName,

            subcategoryIndex = subcategoryIndex,
            subcategoryName = subcategoryName,
        }
    end
end

function ZO_CollectionsUpdateProvider:AddCollectibleNotification(data)
    local collectibleName = data.collectibleName
    local categoryName = data.categoryName
    local subcategoryName = data.subcategoryName
    local displayedCategoryName = subcategoryName and subcategoryName or categoryName

    --use a formatter for when there's more information?
    local hasMoreInfo = GetCollectibleHelpIndices(data.collectibleId) ~= nil
    local message = self:GetMessage(hasMoreInfo, ZO_SELECTED_TEXT:Colorize(displayedCategoryName), ZO_SELECTED_TEXT:Colorize(collectibleName))
    self:AddNotification(message, data, hasMoreInfo)
end

function ZO_CollectionsUpdateProvider:AddNotification(message, data, hasMoreInfo)
    local newListEntry = {
        dataType = NOTIFICATIONS_COLLECTIBLE_DATA,
        notificationType = NOTIFICATION_TYPE_COLLECTIONS,
        shortDisplayText = data.subcategoryIndex and data.subcategoryName or data.categoryName,

        message = message,
        data = data,
        moreInfo = hasMoreInfo,

        --For sorting
        displayName = message,
        secsSinceRequest = 0,
    }

    table.insert(self.list, newListEntry)
end

function ZO_CollectionsUpdateProvider:Accept(entryData)
    RemoveCollectibleNotification(entryData.data.notificationId)
end

function ZO_CollectionsUpdateProvider:Decline(entryData)
    RemoveCollectibleNotification(entryData.data.notificationId)
end

function ZO_CollectionsUpdateProvider:ClearNotificationsForCategory(categoryIndex, subcategoryIndex)
    for i = 1, #self.list do
        local entryData = self.list[i].data

        local isEntryInCategory = entryData.categoryIndex == categoryIndex and entryData.subcategoryIndex == subcategoryIndex
        if isEntryInCategory then
            RemoveCollectibleNotification(entryData.notificationId)
        end
    end
end

--LFG Update Provider
-------------------------

ZO_LFGUpdateProvider = ZO_NotificationProvider:Subclass()

function ZO_LFGUpdateProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)
    provider:SetHasTimer(true)

    provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_JUMP_DUNGEON_NOTIFICATION_NEW)
    provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_JUMP_DUNGEON_NOTIFICATION_REMOVED)
	provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_FIND_REPLACEMENT_NOTIFICATION_NEW)
    provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_FIND_REPLACEMENT_NOTIFICATION_REMOVED)

    provider:BuildNotificationList()
    
    return provider
end

function ZO_LFGUpdateProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if HasLFGJumpNotification() then
        local activityType, activityIndex, role, expirationTimeSeconds = GetLFGJumpNotificationInfo()

        --No notification for AVA types
        if activityType == LFG_ACTIVITY_CYRODIIL or activityType == LFG_ACTIVITY_IMPERIAL_CITY then
            return
        end

        local dungeonName = GetLFGOption(activityType, activityIndex)

        self:AddJumpNotification(
            {
                activityType = activityType,
                activityIndex = activityIndex,
                role = role,
                expirationTimeSeconds = expirationTimeSeconds,
                dungeonName = dungeonName,
            }
        )
    end

	if HasLFGFindReplacementNotification() then
        local activityType, activityIndex = GetLFGFindReplacementNotificationInfo()
        local dungeonName = GetLFGOption(activityType, activityIndex)
        self:AddFindReplacementNotification(
            {
                activityType = activityType,
                activityIndex = activityIndex,
                dungeonName = dungeonName,
            }
        )
    end
end

function ZO_LFGUpdateProvider:AddJumpNotification(data)
    local role = data.role
    local newListEntry = {
        notificationType = NOTIFICATION_TYPE_LFG,
        dataType = NOTIFICATIONS_LFG_JUMP_DUNGEON_DATA,
        shortDisplayText = data.dungeonName,
        data = data,

        expiresAt = GetFrameTimeSeconds() + data.expirationTimeSeconds,
        messageFormat = self:GetMessageFormat(),
        messageParams = {data.dungeonName, self:GetRoleIcon(role), GetString("SI_LFGROLE", role)},

        --For sorting
        displayName = data.dungeonName,
        secsSinceRequest = 0,
    }

    table.insert(self.list, newListEntry)
end

function ZO_LFGUpdateProvider:AddFindReplacementNotification(data)
    local newListEntry = {
        notificationType = NOTIFICATION_TYPE_LFG,
        dataType = NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA,
        shortDisplayText = data.dungeonName,
        data = data,

        message = zo_strformat(SI_LFG_FIND_REPLACEMENT_TEXT, data.dungeonName),

        --For sorting
        displayName = data.dungeonName,
        secsSinceRequest = 0,
    }

    table.insert(self.list, newListEntry)
end

function ZO_LFGUpdateProvider:GetMessageFormat(role)
    assert(false) --this function must be overridden in a sub-class
end

function ZO_LFGUpdateProvider:GetRoleIcon(role)
    assert(false) --this function must be overridden in a sub-class
end

function ZO_LFGUpdateProvider:Accept(entryData)
    if entryData.dataType == NOTIFICATIONS_LFG_JUMP_DUNGEON_DATA then
        AcceptLFGJumpNotification()
	elseif entryData.dataType == NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA then
        AcceptLFGFindReplacementNotification()
    end
end

function ZO_LFGUpdateProvider:Decline(entryData)
    if entryData.dataType == NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA then
        DeclineLFGFindReplacementNotification()
    end
end


-- Sort List
-------------------------
local ENTRY_SORT_KEYS =
{
    ["displayName"] = { },
    ["secsSinceRequest"] = { isNumeric = true, tiebreaker = "displayName" },
}

ZO_NotificationList = ZO_SortFilterList:Subclass()

function ZO_NotificationList:New(control, notificationManager)
     local list = ZO_SortFilterList.New(self, control)
     list.notificationManager = notificationManager
     list.sortFunction = function(listEntry1, listEntry2) return list:CompareNotifications(listEntry1, listEntry2) end
     return list
end

function ZO_NotificationList:BuildMasterList()
    
end

function ZO_NotificationList:FilterScrollList()
    
end

function ZO_NotificationList:CompareNotifications(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, "secsSinceRequest", ENTRY_SORT_KEYS, ZO_SORT_ORDER_DOWN)
end

function ZO_NotificationList:SortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    table.sort(scrollData, self.sortFunction)
end


--Notification Manager
-------------------------

ZO_NotificationManager = ZO_Object:Subclass()

function ZO_NotificationManager:New(control)
    
    local notificationManager = ZO_Object.New(self)
    notificationManager:Initialize(control)
    return notificationManager
end

function ZO_NotificationManager:Initialize(control)

    self.totalNumNotifications = 0


    self:InitializeNotificationList(control)
    self:BuildEmptyList()
    self:RefreshNotificationList()

    local function OnUpdate(updateControl, currentFrameTimeSeconds)
        if(self.allowUpdate and (self.nextUpdateTimeSeconds == nil or currentFrameTimeSeconds >= self.nextUpdateTimeSeconds)) then
            self:RefreshVisible()
            self.nextUpdateTimeSeconds = currentFrameTimeSeconds + 1
        end
    end
    control:SetHandler("OnUpdate", OnUpdate)
end

function ZO_NotificationManager:RefreshNotificationList()
    self:ClearNotificationList()
    self:BuildNotificationList()
    self:FinishNotificationList()
end

function ZO_NotificationManager:RefreshVisible()
    -- This is meant to be overridden in a subclass
end

function ZO_NotificationManager:BuildNotificationList()
    for i = 1, #self.providers do
        self.providers[i]:BuildNotificationList()
    end

    local totalNumNotifications = 0
    local hasTimer = false
    for providerIndex = 1, #self.providers do
        local provider = self.providers[providerIndex]
        local numNotifications = provider:GetNumNotifications()
        if(numNotifications > 0) then
            hasTimer = hasTimer or provider:GetHasTimer()
            totalNumNotifications = totalNumNotifications + numNotifications
        end

        self.allowUpdate = hasTimer

        for listIndex = 1, numNotifications do
            local isHeader = listIndex == 1
            provider:AddDataEntry(self.list, listIndex, isHeader)
        end
    end

    self.totalNumNotifications = totalNumNotifications

    CHAT_SYSTEM:OnNumNotificationsChanged(totalNumNotifications)
    self:OnNumNotificationsChanged(totalNumNotifications)
end

function ZO_NotificationManager:OnNumNotificationsChanged(totalNumNotifications)
    -- Meant to be overridden
end

function ZO_NotificationManager:CompareNotifications(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1, listEntry2, "secsSinceRequest", ENTRY_SORT_KEYS, ZO_SORT_ORDER_DOWN)
end

function ZO_NotificationManager:SortNotificationList()
    table.sort(self.list.dataList, function(listEntry1, listEntry2) return self:CompareNotifications(listEntry1, listEntry2) end)
end

function ZO_NotificationManager:AcceptRequest(data)
    if not data.controlsOwnSounds then
        PlaySound(SOUNDS.DIALOG_ACCEPT)
    end
    data.provider:Accept(data)
end

function ZO_NotificationManager:DeclineRequest(data, button, openedFromKeybind)
    if not data.controlsOwnSounds then
        PlaySound(SOUNDS.DIALOG_DECLINE)
    end
    data.provider:Decline(data, button, openedFromKeybind)
end

function ZO_NotificationManager:ShowMoreInfo(data)
    data.provider:ShowMoreInfo(data)
end

function ZO_NotificationManager:BuildMessageText(data)
    if(data.message) then
        return data.message
    elseif(data.messageFormat) then
        if(data.expiresAt) then
            local remainingTime = zo_max(data.expiresAt - GetFrameTimeSeconds(), 0)
            local formattedTime = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            local params = {unpack(data.messageParams)}
            table.insert(params, formattedTime)
            return zo_strformat(data.messageFormat, unpack(params))
        else
            return zo_strformat(data.messageFormat, unpack(data.messageParams))
        end
    end
    return nil
end

function ZO_NotificationManager:SetupMessage(message, data)
    local messageText = self:BuildMessageText(data)
    if messageText then
        message:SetText(messageText)
    end
end

function ZO_NotificationManager:GetNumNotifications()
    return self.totalNumNotifications
end

function ZO_NotificationManager:GetNumCollectionsNotifications()
    return self.collectionsProvider:GetNumNotifications()
end

-- Override
-------------------------
function ZO_NotificationManager:InitializeNotificationList(control)
end

function ZO_NotificationManager:AddDataEntry(template, data, headerText)
end
