local EVENT_NAMESPACE = "GamepadNotifications"
local GAMEPAD_NOTIFICATIONS_CONFIRM_DECLINE_DIALOG_NAME = "GamepadNotificationsConfirmDecline"

local GAMEPAD_NOTIFICATION_ICONS =
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
}

local DATA_TYPE_TO_TEMPLATE = 
{
    [NOTIFICATIONS_REQUEST_DATA] = "ZO_GamepadNotificationsRequestRow",
    [NOTIFICATIONS_WAITING_DATA] = "ZO_GamepadNotificationsWaitingRow",
    [NOTIFICATIONS_LEADERBOARD_DATA] = "ZO_GamepadNotificationsLeaderboardRow",
    [NOTIFICATIONS_ALERT_DATA] = "ZO_GamepadNotificationsAlertRow",
    [NOTIFICATIONS_COLLECTIBLE_DATA] = "ZO_GamepadNotificationsCollectibleRow",
    [NOTIFICATIONS_LFG_JUMP_DUNGEON_DATA] = "ZO_GamepadNotificationsLFGJumpDungeonRow",
    [NOTIFICATIONS_LFG_FIND_REPLACEMENT_DATA] = "ZO_GamepadNotificationsLFGFindReplacementRow",
}

-- Provider Overrides
-------------------------

-- Friend Request Provier
-------------------------

local ZO_GamepadFriendRequestProvider = ZO_FriendRequestProvider:Subclass()

function ZO_GamepadFriendRequestProvider:New(notificationManager)
    local provider = ZO_FriendRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadFriendRequestProvider:CreateMessage(displayName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_FRIEND_REQUEST_MESSAGE, displayName)
end

function ZO_GamepadFriendRequestProvider:Decline(data, button, openedFromKeybind)
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
            if not IsConsoleUI() then
                AddIgnore(data.displayName)
            elseif ZO_DoesConsoleSupportTargetedIgnore() then
                ZO_ShowConsoleIgnoreDialogFromDisplayNameOrFallback(data.displayName, ZO_ID_REQUEST_TYPE_FRIEND_REQUEST, data.incomingFriendIndex)
            end
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end,

        reportFunction = function()
            SCENE_MANAGER:Push("helpCustomerServiceGamepad")
            ZO_Help_Customer_Service_Gamepad_SetupReportPlayerTicket(data.displayName)
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

local ZO_GamepadGuildInviteProvider = ZO_GuildInviteProvider:Subclass()

function ZO_GamepadGuildInviteProvider:New(notificationManager)
    local provider = ZO_GuildInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadGuildInviteProvider:CreateMessage(guildAlliance, guildName, inviterDisplayName)
    local guildInfo = ZO_PrefixIconNameFormatter(ZO_GetAllianceIconUserAreaDataName(guildAlliance), guildName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_GUILD_INVITE_MESSAGE, guildInfo, inviterDisplayName)
end

function ZO_GamepadGuildInviteProvider:Decline(data, button, openedFromKeybind)
    local dialogData = 
    {
        mainText = function()
            local guildInfo = ZO_PrefixIconNameFormatter(ZO_GetAllianceIconUserAreaDataName(data.guildAlliance), data.guildName)
            return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_GUILD_INVITE_DECLINE_HEADER, guildInfo, ZO_FormatUserFacingDisplayName(data.displayName))
        end,

        declineFunction = function()
            RejectGuildInvite(data.guildId)
            PlaySound(SOUNDS.DIALOG_DECLINE)
        end,

        ignoreFunction = function()
            if not IsConsoleUI() then
                AddIgnore(data.displayName)
            elseif ZO_DoesConsoleSupportTargetedIgnore() then
                -- Guild invites only have the displayName, so that would be our fallback as well
                ZO_ShowConsoleIgnoreDialogFromDisplayNameOrFallback(data.displayName, ZO_ID_REQUEST_TYPE_DISPLAY_NAME, data.displayName)
            end
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end,

        reportFunction = function()
            ZO_Help_Customer_Service_Gamepad_SubmitReportPlayerSpammingTicket(data.displayName)
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

local ZO_GamepadGuildMotDProvider = ZO_GuildMotDProvider:Subclass()

function ZO_GamepadGuildMotDProvider:New(notificationManager)
    local provider = ZO_GuildMotDProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadGuildMotDProvider:CreateMessage(guildAlliance, guildName)
    local guildInfo = ZO_PrefixIconNameFormatter(ZO_GetAllianceIconUserAreaDataName(guildAlliance), guildName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_GUILD_MOTD_CHANGED, guildInfo)
end


--Campaign Queue Provider
-------------------------

local ZO_GamepadCampaignQueueProvider = ZO_CampaignQueueProvider:Subclass()

function ZO_GamepadCampaignQueueProvider:New(notificationManager)
    local provider = ZO_CampaignQueueProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadCampaignQueueProvider:CreateMessageFormat(isGroup)
    return isGroup and SI_GAMEPAD_NOTIFICATIONS_CAMPAIGN_QUEUE_MESSAGE_GROUP or SI_GAMEPAD_NOTIFICATIONS_CAMPAIGN_QUEUE_MESSAGE_INDIVIDUAL
end

function ZO_GamepadCampaignQueueProvider:CreateLoadText()
    return GetString(SI_GAMEPAD_NOTIFICATIONS_CAMPAIGN_ENTER_MESSAGE)
end

function ZO_GamepadCampaignQueueProvider:Accept(data)
    ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_QUEUE_READY_DIALOG, data, {mainTextParams = {data.campaignName}})
end

--Resurrect Provider
-------------------------
local ZO_GamepadResurrectProvider = ZO_ResurrectProvider:Subclass()

function ZO_GamepadResurrectProvider:New(notificationManager)
    local provider = ZO_ResurrectProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadResurrectProvider:GetMessageFormat()
    return SI_GAMEPAD_NOTIFICATIONS_RESURRECT_MESSAGE
end

function ZO_GamepadResurrectProvider:GetNameToShow(resurrectRequesterCharacterName, resurrectRequesterDisplayName)
    return ZO_FormatUserFacingDisplayName(resurrectRequesterDisplayName)
end

function ZO_GamepadResurrectProvider:CanShowGamerCard()
    return true
end

function ZO_GamepadResurrectProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromCharacterName(data.resurrectRequesterCharacterName)
end

--Group Invite Provider
-------------------------
local ZO_GamepadGroupInviteProvider = ZO_GroupInviteProvider:Subclass()

function ZO_GamepadGroupInviteProvider:New(notificationManager)
    local provider = ZO_GroupInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadGroupInviteProvider:CreateMessage(inviterName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_GROUP_INVITE_MESSAGE, inviterName)
end

function ZO_GamepadGroupInviteProvider:CanShowGamerCard()
    return true
end

function ZO_GamepadGroupInviteProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromCharacterName(data.inviterCharacterName)
end


--Trade Invite Provider
-------------------------

local ZO_GamepadTradeInviteProvider = ZO_TradeInviteProvider:Subclass()

function ZO_GamepadTradeInviteProvider:New(notificationManager)
    local provider = ZO_TradeInviteProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadTradeInviteProvider:CreateMessage(inviterName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_TRADE_INVITE_MESSAGE, inviterName)
end

function ZO_GamepadTradeInviteProvider:CanShowGamerCard()
    return true
end

function ZO_GamepadTradeInviteProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromCharacterName(data.inviterCharacterName)
end


--Quest Share Provider
-------------------------

local ZO_GamepadQuestShareProvider = ZO_QuestShareProvider:Subclass()

function ZO_GamepadQuestShareProvider:New(notificationManager)
    local provider = ZO_QuestShareProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadQuestShareProvider:CreateMessage(playerName, displayName, questName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_QUEST_SHARE_MESSAGE, ZO_FormatUserFacingDisplayName(displayName), questName)
end

function ZO_GamepadQuestShareProvider:CanShowGamerCard()
    return true
end

function ZO_GamepadQuestShareProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromCharacterName(data.playerName)
end

--Pledge of Mara Provider
-------------------------

local ZO_GamepadPledgeOfMaraProvider = ZO_PledgeOfMaraProvider:Subclass()

function ZO_GamepadPledgeOfMaraProvider:New(notificationManager)
    local provider = ZO_PledgeOfMaraProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadPledgeOfMaraProvider:CreateMessage(targetName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_PLEDGE_OF_MARA_MESSAGE, targetName)
end

function ZO_GamepadPledgeOfMaraProvider:CreateSenderMessage(targetName)
    return zo_strformat(SI_GAMEPAD_NOTIFICATIONS_PLEDGE_OF_MARA_SENDER_MESSAGE, targetName)
end

function ZO_GamepadPledgeOfMaraProvider:CanShowGamerCard()
    return true
end

function ZO_GamepadPledgeOfMaraProvider:ShowGamerCard(data)
    ZO_ShowGamerCardFromCharacterName(data.targetCharacterName)
end

-- CS Chat Request Provider
-------------------------

local ZO_GamepadAgentChatRequestProvider = ZO_AgentChatRequestProvider:Subclass()

function ZO_GamepadAgentChatRequestProvider:New(notificationManager)
    local provider = ZO_AgentChatRequestProvider.New(self, notificationManager)
    return provider
end

function ZO_AgentChatRequestProvider:CreateMessage()
    return GetString(SI_GAMEPAD_NOTIFICATIONS_AGENT_CHAT_REQUEST_MESSAGE)
end

-- Leaderboard Raid Provider
-------------------------

local ZO_GamepadLeaderboardRaidProvider = ZO_LeaderboardRaidProvider:Subclass()

function ZO_GamepadLeaderboardRaidProvider:New(notificationManager)
    local provider = ZO_LeaderboardRaidProvider.New(self, notificationManager)
    return provider
end


function ZO_GamepadLeaderboardRaidProvider:CreateMessage(raidName, raidScore, hasFriend, hasGuildMember)
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


--Collections Update Provider
-------------------------

local ZO_GamepadCollectionsUpdateProvider = ZO_CollectionsUpdateProvider:Subclass()

function ZO_GamepadCollectionsUpdateProvider:New(notificationManager)
    local provider = ZO_CollectionsUpdateProvider.New(self, notificationManager)
    return provider
end

function ZO_GamepadCollectionsUpdateProvider:Accept(entryData)
    ZO_CollectionsUpdateProvider.Accept(self, entryData)

    local data = entryData.data
    GAMEPAD_COLLECTIONS_BOOK:BrowseToCollectible(data.collectibleIndex, data.categoryIndex, data.subcategoryIndex)
end

function ZO_GamepadCollectionsUpdateProvider:GetMessage(hasMoreInfo, categoryName, collectibleName)
    if hasMoreInfo then
        local icon = GetGamepadIconPathForKeyCode(KEY_GAMEPAD_RIGHT_STICK)
        local iconMarkup = zo_iconFormat(icon, 48, 48)
        return zo_strformat(SI_COLLECTIONS_UPDATED_NOTIFICATION_MESSAGE_MORE_INFO_GAMEPAD, categoryName, collectibleName, iconMarkup)
    else
        return zo_strformat(SI_COLLECTIONS_UPDATED_NOTIFICATION_MESSAGE, categoryName, collectibleName)
    end
end

function ZO_GamepadCollectionsUpdateProvider:ShowMoreInfo(data)
    local helpCategoryIndex, helpIndex = GetCollectibleHelpIndices(data.data.collectibleId)
    if helpCategoryIndex ~= nil then
        HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(helpCategoryIndex, helpIndex)
    end
end


--LFG Update Provider
-------------------------

local ZO_GamepadLFGUpdateProvider = ZO_LFGUpdateProvider:Subclass()

function ZO_GamepadLFGUpdateProvider:New(notificationManager)
    return ZO_LFGUpdateProvider.New(self, notificationManager)
end

function ZO_GamepadLFGUpdateProvider:GetMessageFormat()
    return SI_GAMEPAD_LFG_JUMP_TO_DUNGEON_TEXT
end


do
    local ROLE_TO_ICON = {
        [LFG_ROLE_DPS] = "EsoUI/Art/LFG/Gamepad/gp_LFG_roleIcon_dps_down.dds",
        [LFG_ROLE_HEAL] = "EsoUI/Art/LFG/Gamepad/gp_LFG_roleIcon_healer_down.dds",
        [LFG_ROLE_TANK] = "EsoUI/Art/LFG/Gamepad/gp_LFG_roleIcon_tank_down.dds",
    }
    
    function ZO_GamepadLFGUpdateProvider:GetRoleIcon(role)
        return ROLE_TO_ICON[role]
    end
end


--Notification Manager
-------------------------

local ZO_GamepadNotificationManager = ZO_Object:MultiSubclass(ZO_NotificationManager, ZO_Gamepad_ParametricList_Screen)

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
        ["ZO_GamepadNotificationsLFGJumpDungeonRow"] = SetupRequest,
        ["ZO_GamepadNotificationsLFGFindReplacementRow"] = SetupRequest,
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

    local collectionsProvider = ZO_GamepadCollectionsUpdateProvider:New(self)
    self.collectionsProvider = collectionsProvider

    self.providers =
    {
        ZO_GamepadFriendRequestProvider:New(self),
        ZO_GamepadGuildInviteProvider:New(self),
        ZO_GamepadGuildMotDProvider:New(self),
        ZO_GamepadCampaignQueueProvider:New(self),
        ZO_GamepadResurrectProvider:New(self),
        ZO_GamepadGroupInviteProvider:New(self),
        ZO_GamepadTradeInviteProvider:New(self),
        ZO_GamepadQuestShareProvider:New(self),
        ZO_PointsResetProvider:New(self, "gamepad"),
        ZO_GamepadPledgeOfMaraProvider:New(self),
        ZO_GamepadAgentChatRequestProvider:New(self),
        ZO_GamepadLeaderboardRaidProvider:New(self),
        collectionsProvider,
        ZO_GamepadLFGUpdateProvider:New(self),
    }
end

function ZO_GamepadNotificationManager:InitializeKeybindStripDescriptors()
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
                    self:DeclineRequest(data, nil, NOTIFICATIONS_MENU_OPENED_FROM_KEYBIND)
                end
            end,

            visible = function()
                local data = self:GetTargetData()
                return data and data.declineText ~= nil
            end
        },

        -- More Information
        {
            name = GetString(SI_NOTIFICATIONS_MORE_INFO),

            keybind = "UI_SHORTCUT_RIGHT_STICK",

            callback = function()
                local data = self:GetTargetData()
                if data then
                    self:ShowMoreInfo(data)
                end
            end,

            visible = function()
                local data = self:GetTargetData()
                if(data and data.moreInfo) then
                    return true
                end
                return false
            end
        },

        --View Gamercard
        {
            name = GetString(GetGamerCardStringId()),
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
        local messageText = self:BuildMessageText(entryData.data)
        GAMEPAD_TOOLTIPS:LayoutNotification(GAMEPAD_LEFT_TOOLTIP, entryData.data.note, messageText)
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
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local declineOption =
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData = {
                text = GetString(SI_GAMEPAD_NOTIFICATIONS_DECLINE_OPTION),
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function()
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
                callback = function()
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
                callback = function()
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

        setup = function()
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_GAMEPAD_NOTIFICATIONS_DECLINE_INVITE,
        },

        mainText =
        {
            text = function()  
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
                     data.callback()
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

    local entryData = ZO_GamepadEntryData:New(data.shortDisplayText, GAMEPAD_NOTIFICATION_ICONS[data.notificationType])
    entryData.data = data
    entryData:SetIconTintOnSelection(true)
    entryData:SetIconDisabledTintOnSelection(true)

    if isHeader then
        entryData:SetHeader(zo_strformat(SI_GAMEPAD_NOTIFICATIONS_TYPE_FORMATTER, GetString("SI_NOTIFICATIONTYPE", data.notificationType)))
        self.list:AddEntryWithHeader(DATA_TYPE_TO_TEMPLATE[dataType], entryData)
    else
        self.list:AddEntry(DATA_TYPE_TO_TEMPLATE[dataType], entryData)     
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
    local loadingText = GetControl(control, "Text")
    loadingText:SetText(data.loadText)
end

function ZO_GamepadNotificationManager:SetupBaseRow(control, data, selected)
    data.acceptText = control.acceptText
    data.declineText = control.declineText
end

--Global XML

function ZO_GamepadNotifications_OnInitialized(self)
    GAMEPAD_NOTIFICATIONS = ZO_GamepadNotificationManager:New(self)
end
