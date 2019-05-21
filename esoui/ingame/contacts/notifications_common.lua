NOTIFICATIONS_REQUEST_DATA = 1
NOTIFICATIONS_WAITING_DATA = 2
NOTIFICATIONS_LEADERBOARD_DATA = 3
NOTIFICATIONS_ALERT_DATA = 4
NOTIFICATIONS_COLLECTIBLE_DATA = 5
NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA = 6
NOTIFICATIONS_YES_NO_DATA = 7
NOTIFICATIONS_LFG_READY_CHECK_DATA = 8
NOTIFICATIONS_ESO_PLUS_SUBSCRIPTION_DATA = 9
NOTIFICATIONS_GIFT_RECEIVED_DATA = 10
NOTIFICATIONS_GIFT_RETURNED_DATA = 11
NOTIFICATIONS_GIFT_CLAIMED_DATA = 12
NOTIFICATIONS_GIFTING_GRACE_PERIOD_STARTED_DATA = 13
NOTIFICATIONS_GIFTING_UNLOCKED_DATA = 14
NOTIFICATIONS_NEW_DAILY_LOGIN_REWARD_DATA = 15
NOTIFICATIONS_GUILD_NEW_APPLICATIONS = 16
NOTIFICATIONS_MARKET_PRODUCT_UNLOCKED_DATA = 17

NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND = 1
NOTIFICATIONS_MENU_OPENED_FROM_MOUSE = 2

-- Notification Provider
-------------------------

ZO_NotificationProvider = ZO_Object:Subclass()

function ZO_NotificationProvider:New(notificationManager)
    local provider = ZO_Object.New(self)
    provider.list = {}
    provider.hasTimer = false
    provider.canShowGamerCard = false
    provider.notificationManager = notificationManager

    provider.pushUpdateCallback = function(eventId)
        provider:PushUpdateToNotificationManager(eventId)
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

function ZO_NotificationProvider:AddDataEntry(i, isHeader)
    self.list[i].provider = self
    self.notificationManager:AddDataEntry(self.list[i].dataType, self.list[i], isHeader)
end

function ZO_NotificationProvider:PushUpdateToNotificationManager(eventId)
    if not self.notificationManager:GetSuppressNotificationsByEvent(eventId) then
        self.notificationManager:RefreshNotificationList()
    end
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

function ZO_NotificationProvider:SetCanShowGamerCard(canShowGamerCard)
    self.canShowGamerCard = canShowGamerCard
end

function ZO_NotificationProvider:CanShowGamerCard()
    return self.canShowGamerCard
end

function ZO_NotificationProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromCharacterName(data.characterNameForGamercard)
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

function ZO_FriendRequestProvider:CreateMessage(displayName)
    return zo_strformat(SI_FRIEND_REQUEST_MESSAGE, displayName)
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
                    secsSinceRequest = ZO_NormalizeSecondsSince(0),
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
    local allianceIcon = zo_iconFormat(GetPlatformAllianceSymbolIcon(guildAlliance), 24, 24)
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
        local campaignRulesetTypeString = GetString("SI_CAMPAIGNRULESETTYPE", GetCampaignRulesetType(GetCampaignRulesetId(campaignId)))
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
                                        messageParams = { campaignRulesetTypeString, campaignName },
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

function ZO_CampaignQueueProvider:Accept(data)
    ConfirmCampaignEntry(data.campaignId, data.isGroup, true)
end

function ZO_CampaignQueueProvider:Decline(data, button, openedFromKeybind)
    ConfirmCampaignEntry(data.campaignId, data.isGroup, false)
end

function ZO_CampaignQueueProvider:CreateMessageFormat(isGroup)
    return SI_CAMPAIGN_QUEUE_MESSAGE
end

function ZO_CampaignQueueProvider:CreateLoadText()
    return GetString(SI_CAMPAIGN_ENTER_MESSAGE)
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
        local nameToShow = ZO_GetPrimaryPlayerName(resurrectRequesterDisplayName, resurrectRequesterCharacterName)
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
            characterNameForGamercard = resurrectRequesterCharacterName,
        })
    end
end

function ZO_ResurrectProvider:Accept(data)
    AcceptResurrect()
end

function ZO_ResurrectProvider:Decline(data, button, openedFromKeybind)
    DeclineResurrect()
end

function ZO_ResurrectProvider:GetMessageFormat()
    return SI_RESURRECT_MESSAGE
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
    if(inviterCharacterName ~= "") then
        local nameToUse = ZO_GetPrimaryPlayerName(inviterDisplayName, inviterCharacterName)
        local formattedPlayerNames = ZO_GetPrimaryPlayerNameWithSecondary(inviterDisplayName, inviterCharacterName)
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_GROUP,
            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
            message = self:CreateMessage(formattedPlayerNames),
            characterNameForGamercard = inviterCharacterName,
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

function ZO_GroupInviteProvider:CreateMessage(inviterName)
    return zo_strformat(SI_GROUP_INVITE_MESSAGE, inviterName)
end

--Group Election Provider
-------------------------

ZO_GroupElectionProvider = ZO_NotificationProvider:Subclass()

function ZO_GroupElectionProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)
    provider:SetHasTimer(true)

    provider:RegisterUpdateEvent(EVENT_GROUP_ELECTION_NOTIFICATION_ADDED)
    provider:RegisterUpdateEvent(EVENT_GROUP_ELECTION_NOTIFICATION_REMOVED)

    return provider
end

function ZO_GroupElectionProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if HasPendingGroupElectionVote() then
        local electionType, timeRemainingSeconds, descriptor, targetUnitTag = GetGroupElectionInfo()
        local messageFormat
        local messageParams
        local shortText
        if ZO_IsGroupElectionTypeCustom(electionType) then
            if descriptor == ZO_GROUP_ELECTION_DESCRIPTORS.READY_CHECK then
                messageFormat = GetString(SI_GROUP_ELECTION_READY_CHECK_MESSAGE)
                shortText = GetString(SI_GROUP_ELECTION_READY_CHECK_NOTIFICATION_HEADER)
            else
                messageFormat = descriptor
                shortText = GetString(SI_GROUP_ELECTION_NOTIFICATION_HEADER)
            end
            messageParams = {}
        else
            if electionType == GROUP_ELECTION_TYPE_KICK_MEMBER then
                messageFormat = SI_GROUP_ELECTION_KICK_MESSAGE
            elseif electionType == GROUP_ELECTION_TYPE_NEW_LEADER then
                messageFormat = SI_GROUP_ELECTION_PROMOTE_MESSAGE
            end
            local primaryName = ZO_GetPrimaryPlayerNameFromUnitTag(targetUnitTag)
            local secondaryName = ZO_GetSecondaryPlayerNameFromUnitTag(targetUnitTag)
            messageParams = { primaryName, secondaryName }
            shortText = GetString("SI_GROUPELECTIONTYPE", electionType)
        end
        
        table.insert(self.list,
            {
                dataType = NOTIFICATIONS_YES_NO_DATA,
                notificationType = NOTIFICATION_TYPE_GROUP_ELECTION,
                messageFormat = messageFormat,
                messageParams = messageParams,
                shortDisplayText = shortText,
                expiresAt = GetFrameTimeSeconds() + timeRemainingSeconds,
                characterNameForGamercard = GetUnitName(targetUnitTag),
                --For sorting
                displayName = shortText,
                secsSinceRequest = ZO_NormalizeSecondsSince(0),
            })
    end
end

function ZO_GroupElectionProvider:Accept(data)
    CastGroupVote(GROUP_VOTE_CHOICE_FOR)
end

function ZO_GroupElectionProvider:Decline(data, button, openedFromKeybind)
    CastGroupVote(GROUP_VOTE_CHOICE_AGAINST)
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
        local userFacingInviterName = ZO_GetPrimaryPlayerName(inviterDisplayName, inviterCharacterName)
        local formattedPlayerNames = ZO_GetPrimaryPlayerNameWithSecondary(inviterDisplayName, inviterCharacterName)
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_TRADE,
            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
            message = self:CreateMessage(formattedPlayerNames),
            shortDisplayText = zo_strformat(SI_NOTIFICATIONS_LIST_ENTRY, userFacingInviterName),
            characterNameForGamercard = ZO_StripGrammarMarkupFromCharacterName(inviterCharacterName),
        })
    end
end

function ZO_TradeInviteProvider:Accept(data)
    TradeInviteAccept()
end

function ZO_TradeInviteProvider:Decline(data, button, openedFromKeybind)
    TradeInviteDecline()
end

function ZO_TradeInviteProvider:CreateMessage(inviterName)
    return zo_strformat(SI_TRADE_INVITE_MESSAGE, inviterName)
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
        local displayText = ZO_GetPrimaryPlayerName(displayName, characterName)
        local formattedPlayerNames = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
        self.list[i] =  {
                            dataType = NOTIFICATIONS_REQUEST_DATA,
                            notificationType = NOTIFICATION_TYPE_QUEST_SHARE,
                            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
                            message = self:CreateMessage(formattedPlayerNames, questName),
                            questId = questId,
                            shortDisplayText = displayText,
                            controlsOwnSounds = true,
                            characterNameForGamercard = characterName,
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

function ZO_QuestShareProvider:CreateMessage(inviterName, questName)
    return zo_strformat(SI_QUEST_SHARE_MESSAGE, inviterName, questName)
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
                                pointType = POINT_TYPE_SKILL,
                                secsSinceRequest = ZO_NormalizeSecondsSince(0),
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
                                pointType = POINT_TYPE_ATTRIBUTE,
                                secsSinceRequest = ZO_NormalizeSecondsSince(0),
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

function ZO_PledgeOfMaraProvider:CreateMessage(targetName)
    return zo_strformat(SI_PLEDGE_OF_MARA_MESSAGE, targetName)
end

function ZO_PledgeOfMaraProvider:CreateSenderMessage(targetName)
    return zo_strformat(SI_PLEDGE_OF_MARA_SENDER_MESSAGE, targetName)
end

function ZO_PledgeOfMaraProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local targetCharacterName, aMillisecondsSinceRequest, isSender, targetDisplayName = GetPledgeOfMaraOfferInfo() 
    if(targetCharacterName ~= "") then
        local userFacingDisplayName = ZO_GetPrimaryPlayerName(targetDisplayName, targetCharacterName)
        local formattedPlayerNames = ZO_GetPrimaryPlayerNameWithSecondary(targetDisplayName, targetCharacterName)
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_PLEDGE_OF_MARA,
            secsSinceRequest = ZO_NormalizeSecondsSince(aMillisecondsSinceRequest / 1000),
            message = self:CreateParticipantMessage(formattedPlayerNames, isSender),
            shortDisplayText = userFacingDisplayName,
            characterNameForGamercard = targetCharacterName,
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
            local numKnownMembers = 0
            local hasFriend = false
            local hasGuildMember = false
            local hasPlayer = false
            for memberIndex = 1, numMembers do
                local displayName, characterName, isFriend, isGuildMember, isPlayer = GetRaidScoreNotificationMemberInfo(notificationId, memberIndex)

                hasFriend = hasFriend or isFriend
                hasGuildMember = hasGuildMember or isGuildMember
                hasPlayer = hasPlayer or isPlayer

                if isFriend or isGuildMember then
                    numKnownMembers = numKnownMembers + 1
                end
            end

            if hasPlayer then
                -- Player just received a notification about themselves, so filter it out
                self:Decline({ notificationId = notificationId, })
            elseif hasFriend or hasGuildMember then
                local raidName = GetRaidName(raidId)

                table.insert(self.list,
                {
                    dataType = NOTIFICATIONS_LEADERBOARD_DATA,
                    notificationId = notificationId,
                    raidId = raidId,
                    notificationType = NOTIFICATION_TYPE_LEADERBOARD,
                    secsSinceRequest = ZO_NormalizeSecondsSince(millisecondsSinceRequest / 1000),
                    message = self:CreateMessage(raidName, raidScore, numKnownMembers, hasFriend, hasGuildMember, notificationId),
                    shortDisplayText = zo_strformat(SI_NOTIFICATIONS_LEADERBOARD_RAID_NOTIFICATION_SHORT_TEXT_FORMATTER, raidName),
                })
            end
        end
    end
end

function ZO_LeaderboardRaidProvider:CreateMessage(raidName, raidScore, numMembers, hasFriend, hasGuildMember, notificationId)
    if hasFriend and hasGuildMember and numMembers > 1 then
        return zo_strformat(SI_NOTIFICATIONS_LEADERBOARD_RAID_MESSAGE_FRIENDS_AND_GUILD_MEMBERS, raidName, raidScore)
    elseif hasFriend then
        return zo_strformat(SI_NOTIFICATIONS_LEADERBOARD_RAID_MESSAGE_FRIENDS, raidName, raidScore, numMembers)
    else
        return zo_strformat(SI_NOTIFICATIONS_LEADERBOARD_RAID_MESSAGE_GUILD_MEMBERS, raidName, raidScore, numMembers)
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

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
        -- Typical unlock changes go through a direct notification event flow
        if collectionUpdateType ~= ZO_COLLECTION_UPDATE_TYPE.UNLOCK_STATE_CHANGES then
            provider.pushUpdateCallback(EVENT_COLLECTIBLE_NOTIFICATION_NEW)
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNotificationNew", function() provider.pushUpdateCallback(EVENT_COLLECTIBLE_NOTIFICATION_NEW) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleNotificationRemoved", function() provider.pushUpdateCallback(EVENT_COLLECTIBLE_NOTIFICATION_REMOVED) end)

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
    return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
end

function ZO_CollectionsUpdateProvider:AddCollectibleNotification(data)
    local categoryData = data:GetCategoryData()

    --use a formatter for when there's more information?
    local hasMoreInfo = GetCollectibleHelpIndices(data:GetId()) ~= nil
    local message = self:GetMessage(hasMoreInfo, ZO_SELECTED_TEXT:Colorize(categoryData:GetName()), ZO_SELECTED_TEXT:Colorize(data:GetName()))
    self:AddNotification(message, data, hasMoreInfo)
end

function ZO_CollectionsUpdateProvider:AddNotification(message, data, hasMoreInfo)
    local categoryData = data:GetCategoryData()

    local newListEntry = {
        dataType = NOTIFICATIONS_COLLECTIBLE_DATA,
        notificationType = NOTIFICATION_TYPE_COLLECTIONS,
        shortDisplayText = categoryData:GetName(),

        message = message,
        data = data,
        moreInfo = hasMoreInfo,

        --For sorting
        displayName = message,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }

    table.insert(self.list, newListEntry)
end

function ZO_CollectionsUpdateProvider:Accept(entryData)
    RemoveCollectibleNotification(entryData.data:GetNotificationId())
    --this function should be overriden to open the right scene
end

function ZO_CollectionsUpdateProvider:Decline(entryData)
    RemoveCollectibleNotification(entryData.data:GetNotificationId())
end

--LFG Update Provider
-------------------------

ZO_LFGUpdateProvider = ZO_NotificationProvider:Subclass()

function ZO_LFGUpdateProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)
    provider:SetHasTimer(true)

    provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_READY_CHECK_UPDATED)
    provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_READY_CHECK_CANCELLED)
    provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_FIND_REPLACEMENT_NOTIFICATION_NEW)
    provider:RegisterUpdateEvent(EVENT_GROUPING_TOOLS_FIND_REPLACEMENT_NOTIFICATION_REMOVED)

    provider:BuildNotificationList()
    
    return provider
end

function ZO_LFGUpdateProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if HasLFGReadyCheckNotification() then
        local activityType, role, timeRemainingSeconds = GetLFGReadyCheckNotificationInfo()
        
        self:AddReadyCheckNotification(
            {
                activityType = activityType,
                role = role,
                timeRemainingSeconds = timeRemainingSeconds,
            }
        )
    end

    if HasActivityFindReplacementNotification() then
        local activityId = GetActivityFindReplacementNotificationInfo()
        local activityName = GetActivityName(activityId)
        self:AddFindReplacementNotification(
            {
                activityId = activityId,
                activityName = activityName,
            }
        )
    end
end

function ZO_LFGUpdateProvider:AddReadyCheckNotification(data)
    local role = data.role
    local activityTypeText = GetString("SI_LFGACTIVITY", data.activityType)
    local generalActivityText = ZO_ACTIVITY_FINDER_GENERALIZED_ACTIVITY_DESCRIPTORS[data.activityType]

    local messageFormat, messageParams
    if role == LFG_ROLE_INVALID then
        messageFormat = SI_LFG_READY_CHECK_NO_ROLE_TEXT
        messageParams = { activityTypeText, generalActivityText }
    else
        messageFormat = SI_LFG_READY_CHECK_TEXT
        messageParams = { activityTypeText, generalActivityText, zo_iconFormat(GetRoleIcon(role), "100%", "100%"), GetString("SI_LFGROLE", role) }
    end

    local newListEntry =
    {
        notificationType = NOTIFICATION_TYPE_LFG,
        dataType = NOTIFICATIONS_LFG_READY_CHECK_DATA,
        shortDisplayText = generalActivityText,
        data = data,

        expiresAt = GetFrameTimeSeconds() + data.timeRemainingSeconds,
        expirationCallback = ClearLFGReadyCheckNotification,
        messageFormat = messageFormat,
        messageParams = messageParams,

        --For sorting
        displayName = generalActivityText,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }

    table.insert(self.list, newListEntry)
end

function ZO_LFGUpdateProvider:AddFindReplacementNotification(data)
    local newListEntry = {
        notificationType = NOTIFICATION_TYPE_LFG,
        dataType = NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA,
        shortDisplayText = data.activityName,
        data = data,

        message = zo_strformat(SI_LFG_FIND_REPLACEMENT_TEXT, data.activityName),

        --For sorting
        displayName = data.activityName,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }

    table.insert(self.list, newListEntry)
end

function ZO_LFGUpdateProvider:Accept(entryData)
    if entryData.dataType == NOTIFICATIONS_LFG_READY_CHECK_DATA then
        AcceptLFGReadyCheckNotification()
    elseif entryData.dataType == NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA then
        AcceptActivityFindReplacementNotification()
    end
end

function ZO_LFGUpdateProvider:Decline(entryData)
    if entryData.dataType == NOTIFICATIONS_LFG_READY_CHECK_DATA then
        DeclineLFGReadyCheckNotification()
    elseif entryData.dataType == NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA then
        DeclineAcceptFindReplacementNotification()
    end
end

-- Craft Bag Auto Transfer Provider
-------------------------

ZO_CraftBagAutoTransferProvider = ZO_NotificationProvider:Subclass()

function ZO_CraftBagAutoTransferProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_INVENTORY_ITEMS_AUTO_TRANSFERRED_TO_CRAFT_BAG)
    provider:RegisterUpdateEvent(EVENT_CRAFT_BAG_AUTO_TRANSFER_NOTIFICATION_CLEARED)

    return provider
end

function ZO_CraftBagAutoTransferProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if HasCraftBagAutoTransferNotification() then
        self:AddNotification()
    end
end

function ZO_CraftBagAutoTransferProvider:AddNotification()
    local notificationTypeString = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_CRAFT_BAG_AUTO_TRANSFER)
    local newListEntry = {
        notificationType = NOTIFICATION_TYPE_CRAFT_BAG_AUTO_TRANSFER,
        dataType = NOTIFICATIONS_ALERT_DATA,
        shortDisplayText = notificationTypeString,
        message = GetString(SI_NOTIFICATIONS_ITEMS_AUTO_TRANSFERRED_TO_CRAFT_BAG),

        --For sorting
        displayName = notificationTypeString,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_CraftBagAutoTransferProvider:Decline()
    ClearCraftBagAutoTransferNotification()
end

--Duel Invite Provider
-------------------------

ZO_DuelInviteProvider = ZO_NotificationProvider:Subclass()

function ZO_DuelInviteProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_DUEL_INVITE_RECEIVED)
    provider:RegisterUpdateEvent(EVENT_DUEL_INVITE_REMOVED)

    return provider
end

function ZO_DuelInviteProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local duelState, duelPartnerCharacterName, duelPartnerDisplayName = GetDuelInfo()
    if duelState == DUEL_STATE_INVITE_CONSIDERING then
        local userFacingInviterName = ZO_GetPrimaryPlayerName(duelPartnerDisplayName, duelPartnerCharacterName)
        local formattedInviterNames = ZO_GetPrimaryPlayerNameWithSecondary(duelPartnerDisplayName, duelPartnerCharacterName)
        table.insert(self.list,
        {
            dataType = NOTIFICATIONS_REQUEST_DATA,
            notificationType = NOTIFICATION_TYPE_DUEL,
            message = zo_strformat(SI_DUEL_INVITE_MESSAGE, formattedInviterNames),
            shortDisplayText = zo_strformat(SI_NOTIFICATIONS_LIST_ENTRY, userFacingInviterName),
            characterNameForGamercard = ZO_StripGrammarMarkupFromCharacterName(duelPartnerCharacterName),
            secsSinceRequest = ZO_NormalizeSecondsSince(0),
        })
    end
end

function ZO_DuelInviteProvider:Accept(data)
    AcceptDuel()
end

function ZO_DuelInviteProvider:Decline(data, button, openedFromKeybind)
    DeclineDuel()
end

-- ZO_EsoPlusSubscriptionStatusProvider
-------------------------

ZO_EsoPlusSubscriptionStatusProvider = ZO_NotificationProvider:Subclass()

function ZO_EsoPlusSubscriptionStatusProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED)
    provider:RegisterUpdateEvent(EVENT_ESO_PLUS_FREE_TRIAL_NOTIFICATION_CLEARED)

    return provider
end

function ZO_EsoPlusSubscriptionStatusProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if HasEsoPlusFreeTrialNotification() then
        self:AddNotification()
    end
end

function ZO_EsoPlusSubscriptionStatusProvider:AddNotification()
    local notificationTypeString = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_ESO_PLUS_SUBSCRIPTION)

    local isSubscriber = IsESOPlusSubscriber()
    local message
    local helpCategoryIndex
    local helpIndex
    if isSubscriber then
        message = GetString(SI_NOTIFICATIONS_ESO_PLUS_TRIAL_STARTED)
        helpCategoryIndex, helpIndex = GetEsoPlusSubscriptionBenefitsInfoHelpIndices()
    else
        message = GetString(SI_NOTIFICATIONS_ESO_PLUS_TRIAL_ENDED)
        helpCategoryIndex, helpIndex = GetEsoPlusSubscriptionLapsedBenefitsInfoHelpIndices()
    end

    local hasMoreInfo = helpCategoryIndex ~= nil

    local newListEntry = {
        notificationType = NOTIFICATION_TYPE_ESO_PLUS_SUBSCRIPTION,
        dataType = NOTIFICATIONS_ESO_PLUS_SUBSCRIPTION_DATA,
        shortDisplayText = notificationTypeString,
        message = message,
        moreInfo = hasMoreInfo,

        helpCategoryIndex = helpCategoryIndex,
        helpIndex = helpIndex,

        --For sorting
        displayName = notificationTypeString,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_EsoPlusSubscriptionStatusProvider:Accept()
    ShowEsoPlusPage(MARKET_OPEN_OPERATION_NOTIFICATION)
    ClearEsoPlusFreeTrialNotification()
end

function ZO_EsoPlusSubscriptionStatusProvider:Decline()
    ClearEsoPlusFreeTrialNotification()
end

-- Gift Inventory Provider
-------------------------

ZO_GiftInventoryProvider = ZO_NotificationProvider:Subclass()

function ZO_GiftInventoryProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_GIFTS_UPDATED)

    provider:BuildNotificationList()

    return provider
end

function ZO_GiftInventoryProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local function AddGiftNotifications(giftState, notificationType, messageStringFormatterId, dataType)
        local giftList = GIFT_INVENTORY_MANAGER:GetGiftList(giftState)
        for _, gift in ipairs(giftList) do
            if not gift:HasBeenSeen() then
                local message = zo_strformat(messageStringFormatterId, ZO_SELECTED_TEXT:Colorize(gift:GetUserFacingPlayerName()))
                self:AddGiftNotification(gift, notificationType, dataType, message)
            end
        end
    end

    AddGiftNotifications(GIFT_STATE_RECEIVED, NOTIFICATION_TYPE_GIFT_RECEIVED, SI_NOTIFICATIONS_GIFT_RECEIVED, NOTIFICATIONS_GIFT_RECEIVED_DATA)
    AddGiftNotifications(GIFT_STATE_RETURNED, NOTIFICATION_TYPE_GIFT_RETURNED, SI_NOTIFICATIONS_GIFT_RETURNED, NOTIFICATIONS_GIFT_RETURNED_DATA)
    AddGiftNotifications(GIFT_STATE_THANKED, NOTIFICATION_TYPE_GIFT_CLAIMED, SI_NOTIFICATIONS_GIFT_CLAIMED, NOTIFICATIONS_GIFT_CLAIMED_DATA)
end

function ZO_GiftInventoryProvider:AddGiftNotification(gift, notificationType, dataType, message)
    local newListEntry = {
        notificationType = notificationType,
        dataType = dataType,
        shortDisplayText = GetString("SI_NOTIFICATIONTYPE", notificationType),
        message = message,

        gift = gift,

        --For sorting
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_GiftInventoryProvider:Accept(entryData)
    local gift = entryData.gift
    if gift:IsState(GIFT_STATE_RETURNED) or (gift:IsState(GIFT_STATE_THANKED) and gift:GetNote() == "") then
        gift:View()
        GIFT_INVENTORY_MANAGER.ShowGiftInventory(gift:GetState())
    else
        local giftInventoryView = SYSTEMS:GetObject("giftInventoryView")
        giftInventoryView:SetupAndShowGift(gift)
    end
end

function ZO_GiftInventoryProvider:Decline(entryData)
    entryData.gift:View()
end

-- Gifting Grace Period Started Provider
-------------------------

ZO_GiftingGracePeriodStartedProvider = ZO_NotificationProvider:Subclass()

function ZO_GiftingGracePeriodStartedProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_GIFTING_GRACE_PERIOD_STARTED)
    provider:RegisterUpdateEvent(EVENT_GIFTING_GRACE_PERIOD_STARTED_NOTIFICATION_CLEARED)

    return provider
end

function ZO_GiftingGracePeriodStartedProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if HasGiftingGracePeriodStartedNotification() then
        self:AddNotification()
    end
end

function ZO_GiftingGracePeriodStartedProvider:AddNotification()
    local timeLeftS = GetGiftingGracePeriodTime()
    local timeLeftString
    if timeLeftS >= ZO_ONE_DAY_IN_SECONDS then
        timeLeftString = ZO_FormatTime(timeLeftS, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)
    else
        timeLeftString = GetString(SI_NOTIFICATIONS_GIFTING_GRACE_PERIOD_ENDS_LESS_THAN_A_DAY)
    end
    local message = zo_strformat(GetString(SI_NOTIFICATIONS_GIFTING_GRACE_PERIOD_STARTED), timeLeftString)

    local helpCategoryIndex, helpIndex = GetGiftingGraceStartedHelpIndices()
    local hasMoreInfo = helpCategoryIndex ~= nil
    local newListEntry = {
        notificationType = NOTIFICATION_TYPE_GIFT_GRACE_STARTED,
        dataType = NOTIFICATIONS_GIFTING_GRACE_PERIOD_STARTED_DATA,
        shortDisplayText = GetString(SI_NOTIFICATIONS_GIFTING_GRACE_PERIOD_UNLOCK_PERIOD),
        message = message,

        moreInfo = hasMoreInfo,
        helpCategoryIndex = helpCategoryIndex,
        helpIndex = helpIndex,

        --For sorting
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_GiftingGracePeriodStartedProvider:Accept(entryData)
    ShowMarketAndSearch("", MARKET_OPEN_OPERATION_NOTIFICATION)
    ClearGiftingGracePeriodStartedNotification()
end

function ZO_GiftingGracePeriodStartedProvider:Decline(entryData)
    ClearGiftingGracePeriodStartedNotification()
end

-- Gifting Unlocked Provider
-------------------------

ZO_GiftingUnlockedProvider = ZO_NotificationProvider:Subclass()

function ZO_GiftingUnlockedProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_GIFTING_UNLOCKED_STATUS_CHANGED)
    provider:RegisterUpdateEvent(EVENT_GIFTING_UNLOCKED_NOTIFICATION_CLEARED)

    return provider
end

function ZO_GiftingUnlockedProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if HasGiftingUnlockedNotification() then
        self:AddNotification()
    end
end

function ZO_GiftingUnlockedProvider:AddNotification()
    local helpCategoryIndex, helpIndex = GetGiftingUnlockedHelpIndices()
    local hasMoreInfo = helpCategoryIndex ~= nil
    local newListEntry = {
        notificationType = NOTIFICATION_TYPE_GIFTING_UNLOCKED,
        dataType = NOTIFICATIONS_GIFTING_UNLOCKED_DATA,
        shortDisplayText = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_GIFTING_UNLOCKED),
        message = GetString(SI_NOTIFICATIONS_GIFTING_UNLOCKED_MESSAGE),

        moreInfo = hasMoreInfo,
        helpCategoryIndex = helpCategoryIndex,
        helpIndex = helpIndex,

        --For sorting
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_GiftingUnlockedProvider:Accept(entryData)
    ShowMarketAndSearch("", MARKET_OPEN_OPERATION_NOTIFICATION)
    ClearGiftingUnlockedNotification()
end

function ZO_GiftingUnlockedProvider:Decline(entryData)
    ClearGiftingUnlockedNotification()
end

-- Daily Login Rewards Claim Provider
--------------------------------------

ZO_DailyLoginRewardsClaimProvider = ZO_NotificationProvider:Subclass()

function ZO_DailyLoginRewardsClaimProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_NEW_DAILY_LOGIN_REWARD_AVAILABLE)
    provider:RegisterUpdateEvent(EVENT_DAILY_LOGIN_REWARDS_CLAIMED)

    return provider
end

function ZO_DailyLoginRewardsClaimProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    if GetDailyLoginClaimableRewardIndex() then
        self:AddNotification()
    end
end

function ZO_DailyLoginRewardsClaimProvider:AddNotification()
    local notificationTypeString = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_NEW_DAILY_LOGIN_REWARD)

    local newListEntry =
    {
        notificationType = NOTIFICATION_TYPE_NEW_DAILY_LOGIN_REWARD,
        dataType = NOTIFICATIONS_NEW_DAILY_LOGIN_REWARD_DATA,
        shortDisplayText = GetString(SI_NOTIFICATIONS_NEW_DAILY_LOGIN_REWARDS),
        message = GetString(SI_NOTIFICATIONS_NEW_DAILY_LOGIN_REWARDS_MESSAGE),

        --For sorting
        displayName = notificationTypeString,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_DailyLoginRewardsClaimProvider:Accept(entryData)
    ZO_DAILYLOGINREWARDS_MANAGER:ShowDailyLoginRewardsScene()
end

function ZO_DailyLoginRewardsClaimProvider:Decline(entryData)
    
end

-- Guild Finder Guild New Applications Provider
------------------------------------------------

ZO_GuildNewApplicationsProvider = ZO_NotificationProvider:Subclass()

function ZO_GuildNewApplicationsProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_GUILD_FINDER_GUILD_APPLICATIONS_VIEWED)
    provider:RegisterUpdateEvent(EVENT_GUILD_FINDER_GUILD_NEW_APPLICATIONS)

    return provider
end

function ZO_GuildNewApplicationsProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        if DoesGuildHaveNewApplicationsNotification(guildId) then
            self:AddNotification(guildId, i)
        end
    end
end

function ZO_GuildNewApplicationsProvider:GetAllianceIconNameText(guildAlliance, guildName)
    return ZO_AllianceIconNameFormatter(guildAlliance, guildName)
end

function ZO_GuildNewApplicationsProvider:AddNotification(guildId, guildIndex)
    local notificationTypeString = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_GUILD_NEW_APPLICATIONS)
    local numGuildApplications = GetGuildFinderNumGuildApplications(guildId)
    local guildName = GetGuildName(guildId)
    local guildAlliance = GetGuildAlliance(guildId)
    local guildInfo = self:GetAllianceIconNameText(guildAlliance, guildName)

    local newListEntry =
    {
        notificationType = NOTIFICATION_TYPE_GUILD_NEW_APPLICATIONS,
        dataType = NOTIFICATIONS_GUILD_NEW_APPLICATIONS,
        shortDisplayText = GetString(SI_NOTIFICATIONS_GUILD_NEW_APPLICATIONS),
        message = zo_strformat(SI_NOTIFICATIONS_GUILD_NEW_APPLICATIONS_MESSAGE, numGuildApplications, ZO_WHITE:Colorize(guildInfo)),
        guildId = guildId,
        guildIndex = guildIndex,

        --For sorting
        displayName = notificationTypeString,
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_GuildNewApplicationsProvider:Accept(entryData)
    ClearGuildHasNewApplicationsNotification(entryData.guildId)
    -- Show the guild's application page in overridden function
end

function ZO_GuildNewApplicationsProvider:Decline(entryData)
    ClearGuildHasNewApplicationsNotification(entryData.guildId)
end

-- Guild Finder Player Applications Provider
------------------------------------------------

ZO_PlayerApplicationsProvider = ZO_NotificationProvider:Subclass()

function ZO_PlayerApplicationsProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_GUILD_FINDER_PLAYER_APPLICATIONS_CHANGED)

    return provider
end

function ZO_PlayerApplicationsProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    for i = 1, GetNumPlayerApplicationNotifications() do
        self:AddNotification(i)
    end
end

do
    -- These application states should never generate a notification
    local noNotificationStatusList =
    {
        [GUILD_APPLICATION_STATUS_NONE] = true,
        [GUILD_APPLICATION_STATUS_PENDING] = true,
        [GUILD_APPLICATION_STATUS_RESCINDED] = true,
    }

    function ZO_PlayerApplicationsProvider:AddNotification(index)
        local notificationTypeString = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_PLAYER_APPLICATIONS)
        local declineText, guildName, guildAlliance, reason = GetPlayerApplicationNotificationInfo(index)
        local guildInfo = ZO_AllianceIconNameFormatter(guildAlliance, guildName)

        if noNotificationStatusList[reason] == true then
            return
        end

        local newListEntry =
        {
            notificationType = NOTIFICATION_TYPE_PLAYER_APPLICATIONS,
            dataType = NOTIFICATIONS_ALERT_DATA,
            shortDisplayText = GetString(SI_NOTIFICATIONS_PLAYER_APPLICATIONS),
            message = zo_strformat(GetString("SI_GUILDAPPLICATIONSTATUS", reason), ZO_WHITE:Colorize(guildInfo)),
            index = index,
            note = declineText,
            guildName = guildName,
            showReportKeybind = reason == GUILD_APPLICATION_STATUS_DECLINED and declineText ~= "",

            --For sorting
            displayName = notificationTypeString,
            secsSinceRequest = ZO_NormalizeSecondsSince(0),
        }
        table.insert(self.list, newListEntry)
    end
end

function ZO_PlayerApplicationsProvider:Decline(entryData)
    ClearPlayerApplicationNotification(entryData.index)
end

-- Market Product Unlocked Provider
-------------------------

ZO_MarketProductUnlockedProvider = ZO_NotificationProvider:Subclass()

function ZO_MarketProductUnlockedProvider:New(notificationManager)
    local provider = ZO_NotificationProvider.New(self, notificationManager)

    provider:RegisterUpdateEvent(EVENT_MARKET_PRODUCTS_UNLOCKED)
    provider:RegisterUpdateEvent(EVENT_MARKET_PRODUCTS_UNLOCKED_NOTIFICATIONS_CLEARED)

    return provider
end

function ZO_MarketProductUnlockedProvider:BuildNotificationList()
    ZO_ClearNumericallyIndexedTable(self.list)

    local numNotifications = GetNumMarketProductUnlockNotifications()
    if numNotifications > 0 then
        local multipleProductsUnlocked = numNotifications > 1
        local firstMarketProductId = GetMarketProductUnlockNotificationProductId(1)
        self:AddNotification(firstMarketProductId, multipleProductsUnlocked)
    end
end

function ZO_MarketProductUnlockedProvider:AddNotification(firstMarketProductId, multipleProductsUnlocked)
    local message
    -- in the case of multiple market products getting unlocked, we will use the help info off the first one in the list for simplicity
    local achievementId, completedAchievement, helpCategoryIndex, helpIndex = GetMarketProductUnlockedByAchievementInfo(firstMarketProductId)
    if multipleProductsUnlocked then
        message = GetString(SI_NOTIFICATIONS_MULTIPLE_MARKET_PRODUCTS_UNLOCKED_MESSAGE)
    else
        local marketProductName = GetMarketProductDisplayName(firstMarketProductId)
        message = zo_strformat(SI_NOTIFICATIONS_MARKET_PRODUCT_UNLOCKED_BY_ACHIEVEMENT_MESSAGE, ZO_WHITE:Colorize(marketProductName))
    end

    local hasMoreInfo = helpCategoryIndex ~= nil

    local newListEntry =
    {
        notificationType = NOTIFICATION_TYPE_MARKET_PRODUCT_AVAILABLE,
        dataType = NOTIFICATIONS_MARKET_PRODUCT_UNLOCKED_DATA,
        shortDisplayText = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_MARKET_PRODUCT_AVAILABLE),
        message = message,
        moreInfo = hasMoreInfo,

        marketProductId = marketProductId,
        helpCategoryIndex = helpCategoryIndex,
        helpIndex = helpIndex,

        --For sorting
        secsSinceRequest = ZO_NormalizeSecondsSince(0),
    }
    table.insert(self.list, newListEntry)
end

function ZO_MarketProductUnlockedProvider:Accept(entryData)
    if IsInGamepadPreferredMode() then
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_LOG_OUT")
    else
        ZO_Dialogs_ShowDialog("LOG_OUT")
    end

    ClearMarketProductUnlockNotifications()
end

function ZO_MarketProductUnlockedProvider:Decline(entryData)
    ClearMarketProductUnlockNotifications()
end

-- Sort List
-------------------------
local ENTRY_SORT_KEYS =
{
    ["secsSinceRequest"] = { isNumeric = true, tiebreaker = "dataType" },
    ["dataType"] = { isNumeric = true },
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

    local function OnUpdate(updateControl, currentFrameTimeSeconds)
        if(self.allowUpdate and (self.nextUpdateTimeSeconds == nil or currentFrameTimeSeconds >= self.nextUpdateTimeSeconds)) then
            self:RefreshVisible()
            self.nextUpdateTimeSeconds = currentFrameTimeSeconds + 1
        end
    end
    control:SetHandler("OnUpdate", OnUpdate)

    EVENT_MANAGER:RegisterForEvent(self.eventNamespace, EVENT_PLAYER_ACTIVATED, function() self:RefreshNotificationList() end)
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

        local lastNotificationType = nil
        for listIndex = 1, numNotifications do
            local isHeader = provider.list[listIndex].notificationType ~= lastNotificationType
            provider:AddDataEntry(listIndex, isHeader)
            lastNotificationType = provider.list[listIndex].notificationType
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
            if data.expirationCallback and remainingTime == 0 then
                data.expirationCallback()
            end
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

function ZO_NotificationManager:SuppressNotificationsByEvent(eventId)
    if not self.suppressNotifications then
        self.suppressNotifications = {}
    end

    if not self.suppressNotifications[eventId] then
        self.suppressNotifications[eventId] = 0
    end

    self.suppressNotifications[eventId] = self.suppressNotifications[eventId] + 1
end

function ZO_NotificationManager:GetSuppressNotificationsByEvent(eventId)
    if self.suppressNotifications and self.suppressNotifications[eventId] then
        return self.suppressNotifications[eventId] > 0
    end

    return false
end

function ZO_NotificationManager:ResumeNotificationsByEvent(eventId)
    if self.suppressNotifications and self.suppressNotifications[eventId] then
        self.suppressNotifications[eventId] = self.suppressNotifications[eventId] - 1
        self:RefreshNotificationList()
    end
end

-- Override
-------------------------
function ZO_NotificationManager:InitializeNotificationList(control)
end

function ZO_NotificationManager:AddDataEntry(template, data, headerText)
end
