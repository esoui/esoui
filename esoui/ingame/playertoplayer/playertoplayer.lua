local P2P_UNIT_TAG = "reticleoverplayer"

local INTERACT_TYPE_AGENT_CHAT_REQUEST = 1
local INTERACT_TYPE_RITUAL_OF_MARA = 2
local INTERACT_TYPE_TRADE_INVITE = 3
local INTERACT_TYPE_GROUP_INVITE = 4
local INTERACT_TYPE_QUEST_SHARE = 5
local INTERACT_TYPE_FRIEND_REQUEST = 6
local INTERACT_TYPE_GUILD_INVITE = 7
local INTERACT_TYPE_CAMPAIGN_QUEUE = 8
local INTERACT_TYPE_WORLD_EVENT_INVITE = 9
local INTERACT_TYPE_LFG_JUMP_DUNGEON = 10
local INTERACT_TYPE_LFG_FIND_REPLACEMENT = 11
local INTERACT_TYPE_GROUP_ELECTION = 12
local INTERACT_TYPE_DUEL_INVITE = 13
local INTERACT_TYPE_LFG_READY_CHECK = 14

ZO_PlayerToPlayer = ZO_Object:Subclass()

local function ShouldUseRadialNotificationMenu(data)
	if IsInGamepadPreferredMode() and data.pendingResponse then
		return true
	end
	return false
end

function ZO_PlayerToPlayer:New(...)
    local playerToPlayer = ZO_Object.New(self)
    playerToPlayer:Initialize(...)
    return playerToPlayer
end

do
    local KEYBOARD_STYLE =
    {
        targetFont = "ZoInteractionPrompt",
        additionalInfoFont = "ZoInteractionPrompt",
        pendingResurrectInfoFont = "ZoFontKeybindStripDescription",
        keybindButtonStyle = KEYBIND_STRIP_STANDARD_STYLE,
    }

    local GAMEPAD_STYLE =
    {
        targetFont = "ZoFontGamepad36",
        additionalInfoFont = "ZoFontGamepad36",
        pendingResurrectInfoFont = "ZoFontGamepad27",
        keybindButtonStyle = KEYBIND_STRIP_GAMEPAD_STYLE,
    }

    function ZO_PlayerToPlayer:ApplyPlatformStyle(style)
        self.targetLabel:SetFont(style.targetFont)
        self.additionalInfo:SetFont(style.additionalInfoFont)
        self.pendingResurrectInfo:SetFont(style.pendingResurrectInfoFont)
        self.actionKeybindButton:SetupStyle(style.keybindButtonStyle)
        self.promptKeybindButton1:SetupStyle(style.keybindButtonStyle)
        self.promptKeybindButton2:SetupStyle(style.keybindButtonStyle)
    end

    function ZO_PlayerToPlayer:Initialize(control)
        self.control = control
        control.owner = self

        self.container = control:GetNamedChild("PromptContainer")
        self.targetLabel = self.container:GetNamedChild("Target")
        
        self.actionArea = self.container:GetNamedChild("ActionArea")
        self.actionKeybindButton = self.actionArea:GetNamedChild("ActionKeybindButton")
        self.additionalInfo = self.actionArea:GetNamedChild("AdditionalInfo")
        self.pendingResurrectInfo = self.actionArea:GetNamedChild("PendingResurrectInfo")
        self.gamerID = self.actionArea:GetNamedChild("GamerID")

        self.promptKeybindButton1 = self.actionArea:GetNamedChild("PromptKeybindButton1")
        self.promptKeybindButton1:SetKeybind("PLAYER_TO_PLAYER_INTERACT_ACCEPT")
        self.promptKeybindButton1:SetCallback(function() self:OnPromptAccepted() end)

        self.promptKeybindButton2 = self.actionArea:GetNamedChild("PromptKeybindButton2")
        self.promptKeybindButton2:SetKeybind("PLAYER_TO_PLAYER_INTERACT_DECLINE")
        self.promptKeybindButton2:SetCallback(function() self:OnPromptDeclined() end)

        self.resurrectProgress = ZO_PlayerToPlayerResurrectProgress
        self.resurrectProgressAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("PlayerToPlayerResurrectAnimation", self.resurrectProgress)

        self:InitializeKeybinds()
        self:InitializeSoulGemResurrectionEvents()
        self:InitializeIncomingEvents()

        self.msToDelayToShowPrompt = 500
        self.lastFailedPromptTime = GetFrameTimeMilliseconds()

        EVENT_MANAGER:RegisterForUpdate(control:GetName() .. "OnUpdate", 0, function() self:OnUpdate() end)
        control:RegisterForEvent(EVENT_DUEL_STARTED, function() self:OnDuelStarted() end)

        SHARED_INFORMATION_AREA:AddPlayerToPlayer(self.container)

        ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function ZO_PlayerToPlayer:OnDuelStarted()
    self:StopInteraction()
end

function ZO_PlayerToPlayer:CreateGamepadRadialMenu()
    self.gamepadMenu = ZO_RadialMenu:New(ZO_PlayerToPlayerMenu_Gamepad, "ZO_RadialMenuHUDEntryTemplate_Gamepad", "DefaultRadialMenuAnimation", "DefaultRadialMenuEntryAnimation", "RadialMenu")
    self.gamepadMenu:SetOnClearCallback(function() self:StopInteraction() end)
end

function ZO_PlayerToPlayer:CreateKeyboardRadialMenu()
    self.keyboardMenu = ZO_RadialMenu:New(ZO_PlayerToPlayerMenu_Keyboard, "ZO_PlayerToPlayerMenuEntryTemplate_Keyboard", "DefaultRadialMenuAnimation", "DefaultRadialMenuEntryAnimation", "RadialMenu")
    self.keyboardMenu:SetOnClearCallback(function() self:StopInteraction() end)
end

function ZO_PlayerToPlayer:GetRadialMenu()
    if IsInGamepadPreferredMode() then
        if not self.gamepadMenu then
            self:CreateGamepadRadialMenu()
        end
        return self.gamepadMenu
    else
        if not self.keyboardMenu then
            self:CreateKeyboardRadialMenu()
        end
        return self.keyboardMenu
    end
end

function ZO_PlayerToPlayer:InitializeKeybinds()
    self.actionKeybindButton:SetKeybind("PLAYER_TO_PLAYER_INTERACT")
end

function ZO_PlayerToPlayer:InitializeSoulGemResurrectionEvents()
    self.control:RegisterForEvent(EVENT_START_SOUL_GEM_RESURRECTION, function(eventCode, ...) self:OnStartSoulGemResurrection(...) end)
    self.control:RegisterForEvent(EVENT_END_SOUL_GEM_RESURRECTION, function(eventCode, ...) self:OnEndSoulGemResurrection(...) end)
end

local function GetCampaignQueueData(campaignId, isGroup)
    local campaignName = GetCampaignName(campaignId)
    local remainingSeconds = GetCampaignQueueRemainingConfirmationSeconds(campaignId, isGroup)
    local campaignData = 
        {
            campaignId = campaignId,
            isGroup = isGroup,
            campaignName = campaignName,
            messageFormat = isGroup and SI_NOTIFICATION_CAMPAIGN_QUEUE_MESSAGE_GROUP or SI_NOTIFICATION_CAMPAIGN_QUEUE_MESSAGE_INDIVIDUAL,
            messageParams = { campaignName },
            expiresAt = GetFrameTimeSeconds() + remainingSeconds,
        }

    return campaignData
end

local function ScriptedWorldEventUpdateFunction(data, isActive)
    if isActive and data.messageParams and data.timeParam and type(data.timeParam) == "number" and #data.messageParams >= data.timeParam then
        local timeLeftMS = GetScriptedEventInviteTimeRemainingMS(data.eventId)
        data.messageParams[data.timeParam] = ZO_SELECTED_TEXT:Colorize(ZO_FormatTimeMilliseconds(timeLeftMS, TIME_FORMAT_STYLE_DESCRIPTIVE))
    end
end

function ZO_PlayerToPlayer:InitializeIncomingEvents()
    self.incomingQueue = {}

    local function OnDuelInviteReceived(eventCode, inviterCharacterName, inviterDisplayName)
        PlaySound(SOUNDS.DUEL_INVITE_RECEIVED)
        local userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(inviterDisplayName, inviterCharacterName)
        self:AddPromptToIncomingQueue(INTERACT_TYPE_DUEL_INVITE, inviterCharacterName, inviterDisplayName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_DUEL, ZO_SELECTED_TEXT:Colorize(userFacingName)),
            function()
                AcceptDuel()
            end,
            function()
                DeclineDuel()
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_DUEL_INVITE)
            end)
    end

    local function OnDuelInviteRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_DUEL_INVITE)
    end

    local function OnGroupInviteReceived(eventCode, inviterCharacterName, inviterDisplayName)
        if not self:ExistsInQueue(INTERACT_TYPE_GROUP_INVITE, inviterCharacterName, inviterDisplayName) then
            local userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(inviterDisplayName, inviterCharacterName)

            PlaySound(SOUNDS.GROUP_INVITE)
            self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_INVITE)
            self:AddPromptToIncomingQueue(INTERACT_TYPE_GROUP_INVITE, inviterCharacterName, inviterDisplayName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_GROUP, ZO_SELECTED_TEXT:Colorize(userFacingName)),
                function()
                    AcceptGroupInvite()
                end,
                function()
                    DeclineGroupInvite()
                end,
                function()
                    self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_INVITE, inviterCharacterName, inviterDisplayName)
                end)
        end
    end

    local function OnGroupInviteRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_INVITE)
    end

    local function OnTradeWindowInviteConsidering(eventCode, inviterCharacterName, inviterDisplayName)
        PlaySound(SOUNDS.TRADE_INVITE_RECEIVED)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_TRADE_INVITE)
        local userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(inviterDisplayName, inviterCharacterName)
        -- There is server message received when trade is cancelled/accepted/declined, which sends a Lua event which will play a sound in AlertHandlers.lua
        self:AddPromptToIncomingQueue(INTERACT_TYPE_TRADE_INVITE, inviterCharacterName, inviterDisplayName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_TRADE, ZO_SELECTED_TEXT:Colorize(userFacingName)),
            function()
                TradeInviteAccept()
            end,
            function()
                TradeInviteDecline()
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_TRADE_INVITE, inviterCharacterName, inviterDisplayName)
            end)
    end

    local function OnTradeWindowInviteRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_TRADE_INVITE)
    end

    local function OnQuestShared(eventCode, questId)
        PlaySound(SOUNDS.QUEST_SHARED)
        local questName, characterName, timeSinceRequestMs, displayName = GetOfferedQuestShareInfo(questId)
        local name = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE_QUEST_SHARE, characterName, displayName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_QUEST_SHARE, ZO_SELECTED_TEXT:Colorize(name), questName),
            function()
                AcceptSharedQuest(questId)
            end,
            function()
                DeclineSharedQuest(questId)
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_QUEST_SHARE, characterName, displayName)
            end)
        data.questId = questId
        data.uniqueSounds = {
            accept = SOUNDS.QUEST_SHARE_ACCEPTED,
            decline = SOUNDS.QUEST_SHARE_DECLINED,
        }
    end

    local function OnQuestShareRemoved(eventCode, questId)
        -- No need to play a sound for this now, the client might automatically remove stale quest shares.
        self:RemoveQuestShareFromIncomingQueue(questId)
    end

    local function OnPledgeOfMaraOffer(eventCode, targetCharacterName, isSender, targetDisplayName)
        local ritualPrompt = isSender and SI_PLAYER_TO_PLAYER_OUTGOING_RITUAL_OF_MARA or SI_PLAYER_TO_PLAYER_INCOMING_RITUAL_OF_MARA
        PlaySound(SOUNDS.MARA_INVITE_RECEIVED)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_RITUAL_OF_MARA)
        local userFacingTargetName = ZO_GetPrimaryPlayerNameWithSecondary(targetDisplayName, targetCharacterName)
        local mainTextParams =
        {
            ZO_SELECTED_TEXT:Colorize(ZO_FormatUserFacingDisplayName(targetDisplayName)),
            zo_floor(GetRingOfMaraExperienceBonus() * 100),
            ZO_SELECTED_TEXT:Colorize(targetCharacterName),
        }
        self:AddDialogToIncomingQueue(INTERACT_TYPE_RITUAL_OF_MARA, targetCharacterName, targetDisplayName, zo_strformat(ritualPrompt, ZO_SELECTED_TEXT:Colorize(userFacingTargetName)), "RITUAL_OF_MARA_PROMPT", mainTextParams)
    end

    local function OnPledgeOfMaraOfferRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_RITUAL_OF_MARA)
    end

    local function OnIncomingFriendInviteAdded(eventCode, inviterName)
        local displayName = ZO_FormatUserFacingDisplayName(inviterName)
        self:AddPromptToIncomingQueue(INTERACT_TYPE_FRIEND_REQUEST, inviterName, nil, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_FRIEND_REQUEST, ZO_SELECTED_TEXT:Colorize(displayName)),
            function()
                AcceptFriendRequest(inviterName)
            end,
            function()
                RejectFriendRequest(inviterName)
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_FRIEND_REQUEST, inviterName)
            end)
    end

    local function OnIncomingFriendRequestRemoved(eventCode, inviterName)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_FRIEND_REQUEST, inviterName)
    end

    local function OnGuildInviteAdded(eventCode, guildId, guildName, guildAlliance, inviterName)
        local allianceIconSize = 24
        if IsInGamepadPreferredMode() then
            allianceIconSize = 36
        end

        local formattedInviterName = ZO_FormatUserFacingDisplayName(inviterName)
        local guildNameAlliance = zo_iconTextFormat(GetAllianceBannerIcon(guildAlliance), allianceIconSize, allianceIconSize, ZO_SELECTED_TEXT:Colorize(guildName))
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE_GUILD_INVITE, nil, formattedInviterName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_GUILD_REQUEST, ZO_SELECTED_TEXT:Colorize(formattedInviterName), guildNameAlliance),
            function()
                AcceptGuildInvite(guildId)
            end,
            function()
                RejectGuildInvite(guildId)
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_GUILD_INVITE, formattedInviterName)
            end)
        data.guildId = guildId
    end

    local function OnGuildInviteRemoved(eventCode, guildId)
        self:RemoveGuildInviteFromIncomingQueue(guildId)
    end

    local function OnAgentChatRequested()
        self:AddPromptToIncomingQueue(INTERACT_TYPE_AGENT_CHAT_REQUEST, nil, nil, GetString(SI_PLAYER_TO_PLAYER_INCOMING_AGENT_CHAT_REQUEST),
            function()
                AcceptAgentChat()
            end,
            function()
                DeclineAgentChat()
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_AGENT_CHAT_REQUEST)
            end)
    end

    local function OnAgentChatAccepted()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_AGENT_CHAT_REQUEST)
    end

    local function OnAgentChatDeclined()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_AGENT_CHAT_REQUEST)
    end

    local function OnCampaignQueueStateChanged( _, campaignId, isGroup, state)
        if state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
            local campaignQueueData = GetCampaignQueueData(campaignId, isGroup)
            --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
            local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_CAMPAIGN_QUEUE, campaignId, campaignId, nil,
                function()
                    local campaignBrowser = IsInGamepadPreferredMode() and GAMEPAD_AVA_BROWSER or CAMPAIGN_BROWSER
                    campaignBrowser:GetCampaignBrowser():ShowCampaignQueueReadyDialog(campaignId, isGroup, campaignQueueData.campaignName)
                end,
                function()
                    ConfirmCampaignEntry(campaignId, isGroup, false)
                end,
                function()
                    self:RemoveFromIncomingQueue(INTERACT_TYPE_CAMPAIGN_QUEUE, campaignId)
                end)

            promptData.messageFormat = campaignQueueData.messageFormat
            promptData.messageParams = campaignQueueData.messageParams
            promptData.expiresAt = campaignQueueData.expiresAt
        else
            --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
            self:RemoveFromIncomingQueue(INTERACT_TYPE_CAMPAIGN_QUEUE, campaignId, campaignId)
        end
    end

    local function OnCampaignQueueLeft(_, campaignId, group)
        --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
        self:RemoveFromIncomingQueue(INTERACT_TYPE_CAMPAIGN_QUEUE, campaignId, campaignId)
	end

    local function OnScriptedWorldEventInvite(eventCode, eventId, eventName, inviterName, questName)
        PlaySound(SOUNDS.SCRIPTED_WORLD_EVENT_INVITED)
        self:RemoveScriptedWorldEventFromIncomingQueue(eventId)
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE_WORLD_EVENT_INVITE, eventId, eventId, nil,
            function()
                AcceptWorldEventInvite(eventId)
            end,
            function()
                DeclineWorldEventInvite(eventId)
            end)

        local timeLeft = SCRIPTED_WORLD_EVENT_TIMEOUT_MS

        if inviterName == "" then
            if questName == "" then
                data.messageFormat = SI_EVENT_INVITE
                data.messageParams = { eventName, timeLeft }
                data.timeParam = 2
            else
                data.messageFormat = SI_EVENT_INVITE_QUEST
                data.messageParams = { eventName, questName, timeLeft }
                data.timeParam = 3
            end
        else
            if questName == "" then
                data.messageFormat = SI_EVENT_INVITE_NAMED
                data.messageParams = { inviterName, eventName, timeLeft}
                data.timeParam = 3
            else
                data.messageFormat = SI_EVENT_INVITE_NAMED_QUEST
                data.messageParams = { inviterName, eventName, questName, timeLeft }
                data.timeParam = 4
            end
        end

        for i = 1, #data.messageParams do
          data.messageParams[i] = ZO_SELECTED_TEXT:Colorize(data.messageParams[i])
        end

        data.eventId = eventId
        data.questName = questName
        data.updateFn = ScriptedWorldEventUpdateFunction

        data.uniqueSounds = {
            accept = SOUNDS.SCRIPTED_WORLD_EVENT_ACCEPTED,
            decline = SOUNDS.SCRIPTED_WORLD_EVENT_DECLINED,
        }
    end

    local function OnScriptedWorldEventInviteRemoved(eventCode, eventId)
        self:RemoveScriptedWorldEventFromIncomingQueue(eventId)
    end

    self.control:RegisterForEvent(EVENT_DUEL_INVITE_RECEIVED, OnDuelInviteReceived)
    self.control:RegisterForEvent(EVENT_DUEL_INVITE_REMOVED, OnDuelInviteRemoved)
    self.control:RegisterForEvent(EVENT_GROUP_INVITE_RECEIVED, OnGroupInviteReceived)
    self.control:RegisterForEvent(EVENT_GROUP_INVITE_REMOVED, OnGroupInviteRemoved)
    self.control:RegisterForEvent(EVENT_TRADE_INVITE_CONSIDERING, OnTradeWindowInviteConsidering)
    self.control:RegisterForEvent(EVENT_TRADE_INVITE_REMOVED, OnTradeWindowInviteRemoved)
    self.control:RegisterForEvent(EVENT_QUEST_SHARED, OnQuestShared)
    self.control:RegisterForEvent(EVENT_QUEST_SHARE_REMOVED, OnQuestShareRemoved)
    self.control:RegisterForEvent(EVENT_PLEDGE_OF_MARA_OFFER, OnPledgeOfMaraOffer)
    self.control:RegisterForEvent(EVENT_PLEDGE_OF_MARA_OFFER_REMOVED, OnPledgeOfMaraOfferRemoved)
    self.control:RegisterForEvent(EVENT_INCOMING_FRIEND_INVITE_ADDED, OnIncomingFriendInviteAdded)
    self.control:RegisterForEvent(EVENT_INCOMING_FRIEND_INVITE_REMOVED, OnIncomingFriendRequestRemoved)
    self.control:RegisterForEvent(EVENT_GUILD_INVITE_ADDED, OnGuildInviteAdded)
    self.control:RegisterForEvent(EVENT_GUILD_INVITE_REMOVED, OnGuildInviteRemoved)
    self.control:RegisterForEvent(EVENT_AGENT_CHAT_REQUESTED, OnAgentChatRequested)
    self.control:RegisterForEvent(EVENT_AGENT_CHAT_ACCEPTED, OnAgentChatAccepted)
    self.control:RegisterForEvent(EVENT_AGENT_CHAT_DECLINED, OnAgentChatDeclined)
    self.control:RegisterForEvent(EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, OnCampaignQueueStateChanged)
    self.control:RegisterForEvent(EVENT_CAMPAIGN_QUEUE_LEFT, OnCampaignQueueLeft)
    self.control:RegisterForEvent(EVENT_SCRIPTED_WORLD_EVENT_INVITE, OnScriptedWorldEventInvite)
    self.control:RegisterForEvent(EVENT_SCRIPTED_WORLD_EVENT_INVITE_REMOVED, OnScriptedWorldEventInviteRemoved)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_READY_CHECK_UPDATED, function(event, ...) self:OnGroupingToolsReadyCheckUpdated(...) end)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_READY_CHECK_CANCELLED, function(event, ...) self:OnGroupingToolsReadyCheckCancelled(...) end)

    local function OnGroupingToolsJumpDungeonNotificationNew()
        local activityType, activityIndex, timeRemainingSeconds = GetLFGJumpNotificationInfo()
        local role = GetGroupMemberAssignedRole("player")

        -- No prompt for AVA types
        -- Also add a null check for an edge case that should someday soon get fixed
        if activityType == LFG_ACTIVITY_AVA or not activityType or not activityIndex or not timeRemainingSeconds then
            return
        end

        local function AcceptCallback()
            AcceptLFGJumpNotification()
        end
        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_JUMP_DUNGEON)
        end
        
        local dungeonName = GetLFGOption(activityType, activityIndex)

        local messageFormat, messageParams
        if role == LFG_ROLE_INVALID then
            messageFormat = SI_LFG_JUMP_TO_DUNGEON_NO_ROLE_TEXT
            messageParams = { dungeonName }
        else
            local roleIconPath = GetRoleIcon(role)
            local roleIconFormat = zo_iconFormat(roleIconPath, "100%", "100%")

            messageFormat = SI_LFG_JUMP_TO_DUNGEON_TEXT
            messageParams = { dungeonName, roleIconFormat, GetString("SI_LFGROLE", role) }
        end
        
        PlaySound(SOUNDS.LFG_JUMP_DUNGEON)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_JUMP_DUNGEON)
        
        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_LFG_JUMP_DUNGEON, nil, nil, nil, AcceptCallback, nil, DeferDecisionCallback)
        promptData.acceptText = GetString(SI_LFG_JUMP_TO_DUNGEON_ACCEPT)
        promptData.declineText = GetString(SI_LFG_JUMP_TO_DUNGEON_HIDE)

        promptData.expiresAt = GetFrameTimeSeconds() + timeRemainingSeconds
        promptData.messageFormat = messageFormat
        promptData.messageParams = messageParams
        promptData.expirationCallback = ClearLFGJumpNotification
    end
    local function OnGroupingToolsJumpDungeonNotificationRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_JUMP_DUNGEON)
    end
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_JUMP_DUNGEON_NOTIFICATION_NEW, function(event, ...) OnGroupingToolsJumpDungeonNotificationNew(...) end)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_JUMP_DUNGEON_NOTIFICATION_REMOVED, function(event, ...) OnGroupingToolsJumpDungeonNotificationRemoved(...) end)

    --Find member replacement prompt on a member leaving
    local function OnGroupingToolsFindReplacementNotificationNew()
        local activityType, activityIndex = GetLFGFindReplacementNotificationInfo()

        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT)
        end
        
        local dungeonName = GetLFGOption(activityType, activityIndex)
        
        PlaySound(SOUNDS.LFG_FIND_REPLACEMENT)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT)
        
        local text = zo_strformat(SI_LFG_FIND_REPLACEMENT_TEXT, dungeonName)
        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT, nil, nil, text, AcceptLFGFindReplacementNotification, DeclineLFGFindReplacementNotification, DeferDecisionCallback)
        promptData.acceptText = GetString(SI_LFG_FIND_REPLACEMENT_ACCEPT)
    end
    local function OnGroupingToolsFindReplacementNotificationRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT)
    end
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_FIND_REPLACEMENT_NOTIFICATION_NEW, OnGroupingToolsFindReplacementNotificationNew)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_FIND_REPLACEMENT_NOTIFICATION_REMOVED, OnGroupingToolsFindReplacementNotificationRemoved)


    local function OnGroupElectionNotificationAdded()
        local electionType, timeRemainingSeconds, descriptor, targetUnitTag = GetGroupElectionInfo()

        local function AcceptCallback()
            CastGroupVote(GROUP_VOTE_CHOICE_FOR)
        end
        local function DeclineCallback()
            CastGroupVote(GROUP_VOTE_CHOICE_AGAINST)
        end
        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_ELECTION)
        end

        local messageFormat, messageParams
        if ZO_IsGroupElectionTypeCustom(electionType) then
            if descriptor == ZO_GROUP_ELECTION_DESCRIPTORS.READY_CHECK then
                messageFormat = GetString(SI_GROUP_ELECTION_READY_CHECK_MESSAGE)
            else
                messageFormat = descriptor
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
        end
        
        PlaySound(SOUNDS.NEW_TIMED_NOTIFICATION)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_ELECTION)
        
        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_GROUP_ELECTION, nil, nil, nil, AcceptCallback, DeclineCallback, DeferDecisionCallback)
        promptData.acceptText = GetString(SI_YES)
        promptData.declineText = GetString(SI_NO)

        promptData.expiresAt = GetFrameTimeSeconds() + timeRemainingSeconds
        promptData.messageFormat = messageFormat
        promptData.messageParams = messageParams
        promptData.expirationCallback = DeferDecisionCallback
        promptData.uniqueSounds = {
            accept = SOUNDS.GROUP_ELECTION_VOTE_SUBMITTED,
            decline = SOUNDS.GROUP_ELECTION_VOTE_SUBMITTED,
        }
    end
    local function OnGroupElectionNotificationRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_ELECTION)
    end
    self.control:RegisterForEvent(EVENT_GROUP_ELECTION_NOTIFICATION_ADDED, function(event, ...) OnGroupElectionNotificationAdded(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_ELECTION_NOTIFICATION_REMOVED, function(event, ...) OnGroupElectionNotificationRemoved(...) end)


    local function OnPlayerActivated()
        local duelState, duelPartnerCharacterName, duelPartnerDisplayName = GetDuelInfo()
        if duelState == DUEL_STATE_CONSIDERING then
            OnDuelInviteReceived(nil, duelPartnerCharacterName, duelPartnerDisplayName)
        end

        local inviterCharaterName, aMillisecondsSinceRequest, inviterDisplayName = GetGroupInviteInfo()

        if inviterCharaterName ~= "" or inviterDisplayName ~= "" then
            OnGroupInviteReceived(nil, inviterCharaterName, inviterDisplayName)
        end

        local tradeInviterCharacterName, _, tradeInviterDisplayName = GetTradeInviteInfo()
        if tradeInviterCharacterName ~= "" and tradeInviterDisplayName ~= "" then
            OnTradeWindowInviteConsidering(nil, tradeInviterCharacterName, tradeInviterDisplayName)
        end

        local sharedQuestName = GetOfferedQuestShareInfo()
        if sharedQuestName ~= "" then
            OnQuestShared()
        end

        local pledgeTargetCharacterName, _, isSender, pledgeTargetDisplayName = GetPledgeOfMaraOfferInfo()
        if pledgeTargetCharacterName ~= "" then
            OnPledgeOfMaraOffer(nil, pledgeTargetCharacterName, isSender, pledgeTargetDisplayName)
        end

        local chatRequested = GetAgentChatRequestInfo()
        if chatRequested then
            OnAgentChatRequested()
        end

        local scriptedEventInviteCount = GetNumScriptedEventInvites()
        for i = 1, scriptedEventInviteCount do
            local eventId = GetScriptedEventInviteIdFromIndex(i)
            local isValid, eventName, inviterName, questName, _ = GetScriptedEventInviteInfo(eventId)
            if isValid then
                OnScriptedWorldEventInvite(nil, eventId, eventName, inviterName, questName)
            end
        end

        if HasLFGJumpNotification() then
            OnGroupingToolsJumpDungeonNotificationNew()
        end

        if HasLFGReadyCheckNotification() then
            self:OnGroupingToolsReadyCheckUpdated()
        end

        if HasLFGFindReplacementNotification() then
            OnGroupingToolsFindReplacementNotificationNew()
        end

        if HasPendingGroupElectionVote() then
            OnGroupElectionNotificationAdded()
        end
    end

    local function OnPlayerDeactivated()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_DUEL_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_TRADE_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_RITUAL_OF_MARA)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_QUEST_SHARE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_WORLD_EVENT_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_JUMP_DUNGEON)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT)
    end

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    self.control:RegisterForEvent(EVENT_PLAYER_DEACTIVATED, OnPlayerDeactivated)

    if IsPlayerActivated() then
        OnPlayerActivated()
    end

    --Close the menu when we enter UI mode
    local function OnGameCameraUIModeChanged()
        self:StopInteraction()
    end

    self.control:RegisterForEvent(EVENT_GAME_CAMERA_UI_MODE_CHANGED, OnGameCameraUIModeChanged)
end

function ZO_PlayerToPlayer:SetHidden(hidden)
    SHARED_INFORMATION_AREA:SetHidden(self.container, hidden)
end

function ZO_PlayerToPlayer:IsHidden()
    return SHARED_INFORMATION_AREA:IsHidden(self.container)
end

local INCOMING_MESSAGE_TEXT = {
    [INTERACT_TYPE_GROUP_INVITE] = GetString(SI_NOTIFICATION_GROUP_INVITE),
    [INTERACT_TYPE_QUEST_SHARE] = GetString(SI_NOTIFICATION_SHARE_QUEST_INVITE),
    [INTERACT_TYPE_FRIEND_REQUEST] = GetString(SI_NOTIFICATION_FRIEND_INVITE),
    [INTERACT_TYPE_GUILD_INVITE] = GetString(SI_NOTIFICATION_GUILD_INVITE)
}

local function DisplayNotificationMessage(message, data)
    local typeString = INCOMING_MESSAGE_TEXT[data.incomingType]
    if typeString then
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(message, typeString))
    end
end

local function NotificationDeferred(data)
    data.pendingResponse = false
    if data.deferDecisionCallback then
        data.deferDecisionCallback()
        PlaySound(SOUNDS.DEFER_NOTIFICATION)
    end
end

local function NotificationAccepted(data)
    data.pendingResponse = false
    if data.acceptCallback then
        data.acceptCallback()
        if data.uniqueSounds then
            PlaySound(data.uniqueSounds.accept)
        else
            PlaySound(SOUNDS.DIALOG_ACCEPT)
        end
        DisplayNotificationMessage(GetString(SI_NOTIFICATION_ACCEPTED), data)
    end
end

local function NotificationDeclined(data)
    data.pendingResponse = false
    if data.declineCallback then
        data.declineCallback()
        if data.uniqueSounds then
            PlaySound(data.uniqueSounds.decline)
        else
            PlaySound(SOUNDS.DIALOG_DECLINE)
        end
        DisplayNotificationMessage(GetString(SI_NOTIFICATION_DECLINED), data)
    end
end

function ZO_PlayerToPlayer:ShowRadialNotificationMenu(data)
    local menu = self:GetRadialMenu()

    if data.deferDecisionCallback then
        local deferDecisionText = data.deferDecisionText or GetString(SI_GAMEPAD_NOTIFICATIONS_DEFER_OPTION)
	    menu:AddEntry( deferDecisionText, 
					    "EsoUI/Art/HUD/Gamepad/gp_radialIcon_defer_down.dds",
					    "EsoUI/Art/HUD/Gamepad/gp_radialIcon_defer_down.dds",
					    function()
						    NotificationDeferred(data)
					    end)
    end
    
    local acceptText = data.acceptText or GetString(SI_GAMEPAD_NOTIFICATIONS_ACCEPT_OPTION)
    menu:AddEntry( acceptText,
                    "EsoUI/Art/HUD/Gamepad/gp_radialIcon_accept_down.dds", 
                    "EsoUI/Art/HUD/Gamepad/gp_radialIcon_accept_down.dds",
                    function()
                        NotificationAccepted(data)
                    end)

    if data.declineCallback then
        local declineText = data.declineText or GetString(SI_GAMEPAD_NOTIFICATIONS_DECLINE_OPTION)
        menu:AddEntry( declineText,
                        "EsoUI/Art/HUD/Gamepad/gp_radialIcon_cancel_down.dds", 
                        "EsoUI/Art/HUD/Gamepad/gp_radialIcon_cancel_down.dds", 
                        function()
                            NotificationDeclined(data)
                        end)
    end

    menu:Show()

    self.showingNotificationMenu = true
end

-- inviter name is the decorated name that is choosen based on player preferences
-- where display and character name are descrete strings that are used to determine the creator of the entry
function ZO_PlayerToPlayer:AddIncomingEntry(incomingType, inviterName, targetLabel, displayName, characterName)
    local data = { incomingType = incomingType, targetLabel = targetLabel, inviterName = inviterName, pendingResponse = true, displayName = displayName, characterName = characterName}
    zo_binaryinsert(data, incomingType, self.incomingQueue)
    return data
end

function ZO_PlayerToPlayer:AddPromptToIncomingQueue(interactType, characterName, displayName, targetLabel, acceptCallback, declineCallback, deferDecisionCallback)
    local name = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
    local data = self:AddIncomingEntry(interactType, name, targetLabel, displayName, characterName)
    data.acceptCallback = acceptCallback
    data.declineCallback = declineCallback
    data.deferDecisionCallback = deferDecisionCallback

    TriggerTutorial(TUTORIAL_TRIGGER_INCOMING_PLAYER_TO_PLAYER_NOTIFICATION)

    return data
end

function ZO_PlayerToPlayer:AddDialogToIncomingQueue(incomingType, characterName, displayName, targetLabel, dialogName, mainTextParams)
    local name = ZO_GetPrimaryPlayerNameWithSecondary(characterName, displayName)
    local data = self:AddIncomingEntry(incomingType, name, targetLabel)
    data.dialogName = dialogName
    data.mainTextParams = mainTextParams

    TriggerTutorial(TUTORIAL_TRIGGER_INCOMING_PLAYER_TO_PLAYER_NOTIFICATION)

    return data
end

do
    local function DoesDataMatch(firstEntry, secondEntryType, secondCharacterName, secondDisplayName)
        if firstEntry.incomingType == secondEntryType then
            local doesCharacterNameMatch = not secondCharacterName or firstEntry.characterName == secondCharacterName
            local doesDisplayNameMatch = not secondDisplayName or firstEntry.displayName == secondDisplayName
            return doesCharacterNameMatch and doesDisplayNameMatch
        end
        return false
    end

    function ZO_PlayerToPlayer:ExistsInQueue(incomingType, characterName, displayName)
        local name = ZO_GetPrimaryPlayerNameWithSecondary(characterName, displayName)
        for i, incomingEntry in ipairs(self.incomingQueue) do
            if DoesDataMatch(incomingEntry, incomingType, characterName, displayName) then
                return true
            end
        end

        return false
    end

    function ZO_PlayerToPlayer:RemoveFromIncomingQueue(incomingType, characterName, displayName)
        for i, incomingEntry in ipairs(self.incomingQueue) do
            if DoesDataMatch(incomingEntry, incomingType, characterName, displayName) then
                table.remove(self.incomingQueue, i)
                if i == 1 and self.responding then
                    self:StopInteraction()
                end
                break
            end
        end
    end

    function ZO_PlayerToPlayer:GetFromIncomingQueue(incomingType, characterName, displayName)
        for i, incomingEntry in ipairs(self.incomingQueue) do
            if DoesDataMatch(incomingEntry, incomingType, characterName, displayName) then
                return incomingEntry
            end
        end
        return nil
    end
end

function ZO_PlayerToPlayer:RemoveGuildInviteFromIncomingQueue(guildId)
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.incomingType == INTERACT_TYPE_GUILD_INVITE and incomingEntry.guildId == guildId then
            table.remove(self.incomingQueue, i)
            break
        end
    end
end

function ZO_PlayerToPlayer:RemoveQuestShareFromIncomingQueue(questId)
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.incomingType == INTERACT_TYPE_QUEST_SHARE and incomingEntry.questId == questId then
            table.remove(self.incomingQueue, i)
            break
        end
    end
end

function ZO_PlayerToPlayer:RemoveScriptedWorldEventFromIncomingQueue(eventId, questName)
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.incomingType == INTERACT_TYPE_WORLD_EVENT_INVITE and (incomingEntry.eventId == eventId or incomingEntry.questName == questName) then
            table.remove(self.incomingQueue, i)
            if i == 1 and self.responding then
                self:StopInteraction()
            end
            break
        end
    end
end

function ZO_PlayerToPlayer:OnGroupingToolsReadyCheckUpdated()
    if HasLFGReadyCheckNotification() then
        local activityType, role, timeRemainingSeconds = GetLFGReadyCheckNotificationInfo()

        local promptData = self:GetFromIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK)
        if not promptData then
            local function DeferDecisionCallback()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK)
            end

            local messageFormat, messageParams
            if role == LFG_ROLE_INVALID then
                messageFormat = SI_LFG_READY_CHECK_NO_ROLE_TEXT
                messageParams = { GetString("SI_LFGACTIVITY", activityType) }
            else
                local roleIconPath = GetRoleIcon(role)
                local roleIconFormat = zo_iconFormat(roleIconPath, "100%", "100%")

                messageFormat = SI_LFG_READY_CHECK_TEXT
                local timeText = ZO_FormatTime(timeRemainingSeconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
                messageParams = { GetString("SI_LFGACTIVITY", activityType), roleIconFormat, GetString("SI_LFGROLE", role), timeText }
            end

            promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK, nil, nil, nil, AcceptLFGReadyCheckNotification, DeclineLFGReadyCheckNotification, DeferDecisionCallback)
            promptData.acceptText = GetString(SI_LFG_READY_CHECK_ACCEPT)
            promptData.messageFormat = messageFormat
            promptData.messageParams = messageParams
            local function UpdateTimeLeft(incomingEntry, isActive)
                if isActive then
                    local timeRemainingSeconds = select(3, GetLFGReadyCheckNotificationInfo())
                    local timeText = ZO_FormatTime(timeRemainingSeconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
                    incomingEntry.messageParams[4] = timeText
                    self:SetupTargetLabel(incomingEntry)
                end
            end
            promptData.updateFn = UpdateTimeLeft

            PlaySound(SOUNDS.LFG_READY_CHECK)
        end
    else
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK)
    end
end

function ZO_PlayerToPlayer:OnGroupingToolsReadyCheckCancelled()
    self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK)
end

local NO_LEADING_EDGE = false
function ZO_PlayerToPlayer:OnStartSoulGemResurrection(duration)
    self.resurrectProgressAnimation:PlayForward()
    self.resurrectProgress:StartCooldown(duration, duration, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_REMAINING, NO_LEADING_EDGE)
end

function ZO_PlayerToPlayer:OnEndSoulGemResurrection()
    self.resurrectProgressAnimation:PlayBackward()
    self.targetLabel:SetHidden(true)
end

function ZO_PlayerToPlayer:SetDelayPromptTime(timeMs)
    self.msToDelayToShowPrompt = timeMs
end

function ZO_PlayerToPlayer:TryDisplayingIncomingRequests()
    if self.responding then
        local incomingEntryToRespondTo = self.incomingQueue[1]
        if(incomingEntryToRespondTo.dialogName) then
            ZO_Dialogs_ShowPlatformDialog(incomingEntryToRespondTo.dialogName, nil, {mainTextParams = incomingEntryToRespondTo.mainTextParams})
            table.remove(self.incomingQueue, 1)
            self.responding = false
            self:StopInteraction()
            return true
        elseif ShouldUseRadialNotificationMenu(incomingEntryToRespondTo) then
            LockCameraRotation(true)
            RETICLE:RequestHidden(true)
            self.targetLabel:SetHidden(true)
            self:ShowRadialNotificationMenu(incomingEntryToRespondTo)
            return true
        end
    end
    return false
end

function ZO_PlayerToPlayer:HasTarget()
    return self.currentTargetCharacterName ~= nil
end

function ZO_PlayerToPlayer:StartInteraction()
    if not SCENE_MANAGER:IsInUIMode() then
        local isInteractionPossible = self:HasTarget() or self.responding
        if not isInteractionPossible then
            PlaySound(SOUNDS.NO_INTERACT_TARGET)
        elseif not self.isInteracting and not SHARED_INFORMATION_AREA:IsSuppressed() then
            self:SetHidden(false)
            if not self:TryDisplayingIncomingRequests() then
                if self.resurrectable then
                    if self.hasRequiredSoulGem and not self.failedRaidRevives and not self.isBeingResurrected and not self.hasResurrectPending then
                        StartSoulGemResurrection()
                    else
                        return
                    end
                else
                    local isIgnored = IsUnitIgnored(P2P_UNIT_TAG)
                    
                    self.targetLabel:SetHidden(true)
                    self:ShowPlayerInteractMenu(isIgnored)
                    LockCameraRotation(true)
                end

                RETICLE:RequestHidden(true)
                self.isInteracting = true
            end
        end
    end
end

function ZO_PlayerToPlayer:StopInteraction()
    self.targetLabel:SetHidden(false)
    
    if self.isInteracting then
        self.isInteracting = false
        RETICLE:RequestHidden(false)
        LockCameraRotation(false)

        CancelSoulGemResurrection()

        self:GetRadialMenu():SelectCurrentEntry()

        self.lastFailedPromptTime = GetFrameTimeMilliseconds() - self.msToDelayToShowPrompt
    elseif self.responding then
        self.responding = false
        if self.showingNotificationMenu then
            RETICLE:RequestHidden(false)
            LockCameraRotation(false)
            self:GetRadialMenu():SelectCurrentEntry()
            self.showingNotificationMenu = false
        end
    end
end

function ZO_PlayerToPlayer:Accept()
    self:OnPromptAccepted()
end

function ZO_PlayerToPlayer:Decline()
    self:OnPromptDeclined()
end

--With proper timing, both of these events can fire in the same frame, making it possible to be responding but having already cleared the incoming queue
function ZO_PlayerToPlayer:OnPromptAccepted()
    if(self.responding and #self.incomingQueue > 0) then
        local incomingEntryToRespondTo = table.remove(self.incomingQueue, 1)
        NotificationAccepted(incomingEntryToRespondTo)
    end
end

function ZO_PlayerToPlayer:OnPromptDeclined()
    if(self.responding and #self.incomingQueue > 0) then
        local incomingEntryToRespondTo = table.remove(self.incomingQueue, 1)
        NotificationDeclined(incomingEntryToRespondTo)
    end
end

function ZO_PlayerToPlayer:SetTargetIdentification()
    self.currentTargetCharacterNameRaw = GetRawUnitName(P2P_UNIT_TAG)
    self.currentTargetCharacterName = zo_strformat(SI_PLAYER_TO_PLAYER_TARGET, self.currentTargetCharacterNameRaw)
    self.currentTargetDisplayName = GetUnitDisplayName(P2P_UNIT_TAG)
end

local RAID_LIFE_ICON_MARKUP = "|t32:32:EsoUI/Art/Trials/VitalityDepletion.dds|t"
function ZO_PlayerToPlayer:TryShowingResurrectLabel()
    if IsUnitResurrectableByPlayer(P2P_UNIT_TAG) then
        self:SetTargetIdentification()

        self.resurrectable = true

        self.targetLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        self.targetLabel:SetText(ZO_GetPrimaryPlayerNameWithSecondary(self.currentTargetDisplayName, self.currentTargetCharacterName))

        self.isBeingResurrected = IsUnitBeingResurrected(P2P_UNIT_TAG)
        self.hasResurrectPending = DoesUnitHaveResurrectPending(P2P_UNIT_TAG)
        if self.isBeingResurrected or self.hasResurrectPending then
            self.pendingResurrectInfo:SetHidden(false)
            if(self.isBeingResurrected) then
                self.pendingResurrectInfo:SetText(GetString(SI_PLAYER_TO_PLAYER_RESURRECT_BEING_RESURRECTED))
            else
                self.pendingResurrectInfo:SetText(GetString(SI_PLAYER_TO_PLAYER_RESURRECT_HAS_RESURRECT_PENDING))
            end
        else
            self.pendingResurrectInfo:SetHidden(true)
            self.actionKeybindButton:SetHidden(false)

            local targetLevel = GetUnitEffectiveLevel(P2P_UNIT_TAG)
            local _, _, stackCount = GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, targetLevel)
            local soulGemSuccess, coloredFilledText, coloredSoulGemIconMarkup = ZO_Death_GetResurrectSoulGemText(targetLevel)

            self.hasRequiredSoulGem = stackCount > 0
            self.failedRaidRevives = IsPlayerInRaid() and not ZO_Death_IsRaidReviveAllowed()
            self.actionKeybindButton:SetEnabled(self.hasRequiredSoulGem and not self.failedRaidRevives)

            local finalText
            if(ZO_Death_DoesReviveCostRaidLife()) then
                finalText = zo_strformat(soulGemSuccess and SI_PLAYER_TO_PLAYER_RESURRECT_GEM_LIFE or SI_PLAYER_TO_PLAYER_RESURRECT_GEM_LIFE_FAILED, coloredFilledText, coloredSoulGemIconMarkup, RAID_LIFE_ICON_MARKUP)           
            else
                finalText = zo_strformat(soulGemSuccess and SI_PLAYER_TO_PLAYER_RESURRECT_GEM or SI_PLAYER_TO_PLAYER_RESURRECT_GEM_FAILED, coloredFilledText, coloredSoulGemIconMarkup)
            end

            self.actionKeybindButton:SetText(finalText) 
        end        

        return true
    end
    self.pendingResurrectInfo:SetHidden(true)
    return false
end

function ZO_PlayerToPlayer:TryShowingStandardInteractLabel()
    local function GetPlatformIgnoredString()
        return IsConsoleUI() and SI_PLAYER_TO_PLAYER_TARGET_BLOCKED or SI_PLAYER_TO_PLAYER_TARGET_IGNORED
    end

    if CanUnitTrade(P2P_UNIT_TAG) then
        self.resurrectable = false
        self:SetTargetIdentification()

        local isIgnored = IsUnitIgnored(P2P_UNIT_TAG)
        local interactLabel = isIgnored and GetPlatformIgnoredString() or SI_PLAYER_TO_PLAYER_TARGET

        self.actionKeybindButton:SetHidden(false)
        self.targetLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        self.targetLabel:SetText(zo_strformat(interactLabel, ZO_GetPrimaryPlayerNameWithSecondary(self.currentTargetDisplayName, self.currentTargetCharacterName)))
        self.actionKeybindButton:SetText(GetString(SI_PLAYER_TO_PLAYER_ACTION_MENU))

        return true
    end
    return false
end

function ZO_PlayerToPlayer:ShouldShowPromptAfterDelay()
    local now = GetFrameTimeMilliseconds()
    if IsPlayerMoving() then
        self.lastFailedPromptTime = now
    else
        if now - self.lastFailedPromptTime >= self.msToDelayToShowPrompt then
            return true
        end
    end
    return false
end

function ZO_PlayerToPlayer:ShowResponseActionKeybind(keybindText)
    self.actionKeybindButton:SetHidden(false)
    self.actionKeybindButton:SetText(keybindText)
end

function ZO_PlayerToPlayer:SetupTargetLabel(incomingEntry)
    self.targetLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())

    if incomingEntry.targetLabel then
        self.targetLabel:SetText(incomingEntry.targetLabel)
    elseif incomingEntry.messageFormat then
        if(incomingEntry.expiresAt) then
            local remainingTime = zo_max(incomingEntry.expiresAt - GetFrameTimeSeconds(), 0)
            local formattedTime = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            local params = {unpack(incomingEntry.messageParams)}
            table.insert(params, formattedTime)
            self.targetLabel:SetText(zo_strformat(incomingEntry.messageFormat, unpack(params)))
            if incomingEntry.expirationCallback and remainingTime == 0 then
                incomingEntry.expirationCallback()
            end
        else
            self.targetLabel:SetText(zo_strformat(incomingEntry.messageFormat, unpack(incomingEntry.messageParams)))
        end		
    end
    
    local font = IsInGamepadPreferredMode() and "ZoFontGamepad42" or "ZoInteractionPrompt"
    self.targetLabel:SetFont(font)
end

function ZO_PlayerToPlayer:GetKeyboardStringFromInteractionType(interactionType)
    if interactionType == INTERACT_TYPE_RITUAL_OF_MARA then
        return GetString(SI_PLEDGE_OF_MARA_BEGIN_RITUAL_PROMPT)
    else
        return GetString(SI_PLAYER_TO_PLAYER_ACTION_RESPOND)
    end
end

function ZO_PlayerToPlayer:GetGamepadStringFromInteractionType(interactionType)
    if interactionType and interactionType == INTERACT_TYPE_RITUAL_OF_MARA then
        return GetString(SI_GAMEPAD_NOTIFICATIONS_PLEDGE_OF_MARA_BEGIN_RITUAL_PROMPT)
    else
        return GetString(SI_GAMEPAD_PLAYER_TO_PLAYER_ACTION_RESPOND)
    end
end

function ZO_PlayerToPlayer:TryShowingResponseLabel()
    if #self.incomingQueue > 0 then
        local incomingEntry = self.incomingQueue[1]
        if incomingEntry.pendingResponse then
            self:SetupTargetLabel(incomingEntry)

            if(incomingEntry.dialogName) then
                self:ShowResponseActionKeybind(self:GetKeyboardStringFromInteractionType(incomingEntry.incomingType))
            elseif ShouldUseRadialNotificationMenu(incomingEntry) then
                if not self.showingNotificationMenu then
                    self:ShowResponseActionKeybind(self:GetGamepadStringFromInteractionType(incomingEntry.incomingType))
                end
            else
                local acceptText = incomingEntry.acceptText or GetString(SI_DIALOG_ACCEPT)
                local declineText = incomingEntry.declineText or GetString(SI_DIALOG_DECLINE)
                self.promptKeybindButton1:SetText(acceptText)
                self.promptKeybindButton2:SetText(declineText)
                self.shouldShowNotificationKeybindLayer = true
            end

            self.responding = true
            return true
        end
    end
    return false
end

function ZO_PlayerToPlayer:IsReticleTargetInteractable()
    return DoesUnitExist(P2P_UNIT_TAG)
       and IsUnitOnline(P2P_UNIT_TAG)
       and AreUnitsCurrentlyAllied("player", P2P_UNIT_TAG)
end

local notificationsKeybindLayerName = GetString(SI_KEYBINDINGS_LAYER_NOTIFICATIONS)

function ZO_PlayerToPlayer:OnUpdate()
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.updateFn then
            local isActive = i == 1 and (self.responding or self.isInteracting)
            incomingEntry.updateFn(incomingEntry, isActive)
        end
    end

    if not self.control:IsHidden() then
        self.currentTargetCharacterName = nil
        self.currentTargetCharacterNameRaw = nil
        self.currentTargetDisplayName = nil
        self.resurrectable = false
        self.hasRequiredSoulGem = false
        self.failedRaidRevives = false
        self.responding = false
        self.actionKeybindButton:SetHidden(true)
        self.actionKeybindButton:SetEnabled(true)
        self.additionalInfo:SetHidden(true)

        if (not self.isInteracting) or (not IsConsoleUI()) then
            self.gamerID:SetHidden(true)
        end

        self.shouldShowNotificationKeybindLayer = false

        local hideSelf = not self.isInteracting

        local isReticleTargetInteractable = self:IsReticleTargetInteractable()
        if isReticleTargetInteractable and self:TryShowingResurrectLabel() then
            hideSelf = false
        elseif not self.isInteracting and (self.showingNotificationMenu or not IsUnitInCombat("player")) and self:TryShowingResponseLabel() then
            hideSelf = false
        elseif not self.isInteracting and isReticleTargetInteractable and self:TryShowingStandardInteractLabel() then
            hideSelf = not self:ShouldShowPromptAfterDelay()
        end
        
        self:SetHidden(hideSelf)
        self.promptKeybindButton1:SetHidden(not self.shouldShowNotificationKeybindLayer)
        self.promptKeybindButton2:SetHidden(not self.shouldShowNotificationKeybindLayer)

        local isNotificationLayerShown = IsActionLayerActiveByName(notificationsKeybindLayerName)

        if self.shouldShowNotificationKeybindLayer ~= isNotificationLayerShown then
            if(self.shouldShowNotificationKeybindLayer) then
                PushActionLayerByName(notificationsKeybindLayerName)
            else
                RemoveActionLayerByName(notificationsKeybindLayerName)
            end
        end
    else
        if(IsActionLayerActiveByName(notificationsKeybindLayerName)) then
            RemoveActionLayerByName(notificationsKeybindLayerName)
        end
    end
end

local KEYBOARD_INTERACT_ICONS =
{
    [SI_PLAYER_TO_PLAYER_WHISPER] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_whisper_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_whisper_over.dds",
        disabledNormal =  "EsoUI/Art/HUD/radialIcon_whisper_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_whisper_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_ADD_GROUP] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_inviteGroup_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_inviteGroup_over.dds",
        disabledNormal =  "EsoUI/Art/HUD/radialIcon_inviteGroup_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_inviteGroup_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_REMOVE_GROUP] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_removeFromGroup_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_removeFromGroup_over.dds",
        disabledNormal =  "EsoUI/Art/HUD/radialIcon_removeFromGroup_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_removeFromGroup_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_ADD_FRIEND] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_addFriend_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_addFriend_over.dds",
        disabledNormal = "EsoUI/Art/HUD/radialIcon_addFriend_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_addFriend_disabled.dds",
    },
    [SI_CHAT_PLAYER_CONTEXT_REPORT] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_reportPlayer_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_reportPlayer_over.dds",
    },
    [SI_PLAYER_TO_PLAYER_INVITE_DUEL] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_duel_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_duel_over.dds",
        disabledNormal = "EsoUI/Art/HUD/radialIcon_duel_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_duel_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_INVITE_TRADE] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_trade_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_trade_over.dds",
        disabledNormal = "EsoUI/Art/HUD/radialIcon_trade_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_trade_disabled.dds",
    },
    [SI_RADIAL_MENU_CANCEL_BUTTON] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_cancel_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_cancel_over.dds",
    },
}

local GAMEPAD_INTERACT_ICONS =
{
    [SI_PLAYER_TO_PLAYER_WHISPER] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_whisper_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_whisper_down.dds",
        disabledNormal =  "EsoUI/Art/HUD/Gamepad/gp_radialIcon_whisper_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_whisper_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_ADD_GROUP] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_inviteGroup_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_inviteGroup_down.dds",
        disabledNormal =  "EsoUI/Art/HUD/Gamepad/gp_radialIcon_inviteGroup_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_inviteGroup_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_REMOVE_GROUP] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_removeFromGroup_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_removeFromGroup_down.dds",
    },
    [SI_PLAYER_TO_PLAYER_ADD_FRIEND] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_addFriend_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_addFriend_down.dds",
        disabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_addFriend_disabled.dds", 
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_addFriend_disabled.dds",
    },
    [SI_CHAT_PLAYER_CONTEXT_REPORT] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_reportPlayer_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_reportPlayer_down.dds",
    },
    [SI_PLAYER_TO_PLAYER_INVITE_DUEL] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_duel_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_duel_down.dds",
        disabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_duel_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_duel_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_INVITE_TRADE] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_trade_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_trade_down.dds",
        disabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_trade_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_trade_disabled.dds",
    },
    [SI_RADIAL_MENU_CANCEL_BUTTON] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_cancel_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_cancel_down.dds",
    },
}

function ZO_PlayerToPlayer:AddShowGamerCard(targetDisplayName, targetCharacterName)
    self:GetRadialMenu():AddEntry(GetString(GetGamerCardStringId()), "EsoUI/Art/HUD/Gamepad/gp_radialIcon_gamercard_down.dds", "EsoUI/Art/HUD/Gamepad/gp_radialIcon_gamercard_down.dds",
        function()
            ZO_ShowGamerCardFromDisplayNameOrFallback(targetDisplayName, ZO_ID_REQUEST_TYPE_CHARACTER_NAME, targetCharacterName)
        end)
end

function ZO_PlayerToPlayer:AddMenuEntry(text, icons, enabled, selectedFunction, errorReason)
    local normalIcon = enabled and icons.enabledNormal or icons.disabledNormal
    local selectedIcon = enabled and icons.enabledSelected or icons.disabledSelected 
    self:GetRadialMenu():AddEntry(text, normalIcon, selectedIcon, selectedFunction, errorReason)
end

do
    local ALERT_IGNORED_STRING = IsConsoleUI() and SI_PLAYER_TO_PLAYER_BLOCKED or SI_PLAYER_TO_PLAYER_IGNORED

    local function AlertIgnored()
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, ALERT_IGNORED_STRING)
    end

    function ZO_PlayerToPlayer:ShowPlayerInteractMenu(isIgnored)
        local currentTargetCharacterName = self.currentTargetCharacterName
        local currentTargetCharacterNameRaw = self.currentTargetCharacterNameRaw
        local currentTargetDisplayName = self.currentTargetDisplayName
        local primaryName = ZO_GetPrimaryPlayerName(currentTargetDisplayName, currentTargetCharacterName);
        local primaryNameInternal = ZO_GetPrimaryPlayerName(currentTargetDisplayName, currentTargetCharacterName, USE_INTERNAL_FORMAT);
        local formattedPlayerNames = ZO_GetPrimaryPlayerNameWithSecondary(currentTargetDisplayName, currentTargetCharacterName);
        local platformIcons = IsInGamepadPreferredMode() and GAMEPAD_INTERACT_ICONS or KEYBOARD_INTERACT_ICONS
        local ENABLED = true
        local DISABLED = false
        local ENABLED_IF_NOT_IGNORED = not isIgnored
    
        --Gamecard--
        if IsConsoleUI() then
            self:AddShowGamerCard(currentTargetDisplayName, currentTargetCharacterName)
        end

        --Whisper--
        if IsChatSystemAvailableForCurrentPlatform() then
            local nameToUse = IsConsoleUI() and currentTargetDisplayName or primaryNameInternal
            local function WhisperOption() StartChatInput(nil, CHAT_CHANNEL_WHISPER, nameToUse) end
            local whisperFunction = ENABLED_IF_NOT_IGNORED and WhisperOption or AlertIgnored
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_WHISPER), platformIcons[SI_PLAYER_TO_PLAYER_WHISPER], ENABLED_IF_NOT_IGNORED, whisperFunction)
        end

        --Group--
        local playerHasGroupPermissions = IsUnitSoloOrGroupLeader("player")
        local errorReason = not playerHasGroupPermissions and GetString(SI_PLAYER_TO_PLAYER_GROUP_NOT_LEADER) or nil
        if IsPlayerInGroup(currentTargetCharacterNameRaw) then
            local function GroupKickOption()
                GroupKickByName(currentTargetCharacterNameRaw) 
            end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_REMOVE_GROUP), platformIcons[SI_PLAYER_TO_PLAYER_REMOVE_GROUP], ENABLED, GroupKickOption, errorReason)
        else
            local function InviteOption()
                local NOT_SENT_FROM_CHAT = false
                local DISPLAY_INVITED_MESSAGE = true
                TryGroupInviteByName(primaryNameInternal, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE)
            end
            local groupInviteFunction = ENABLED_IF_NOT_IGNORED and InviteOption or AlertIgnored
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_ADD_GROUP), platformIcons[SI_PLAYER_TO_PLAYER_ADD_GROUP], ENABLED_IF_NOT_IGNORED and playerHasGroupPermissions, groupInviteFunction, errorReason)
        end
        
        --Friend--
        if IsFriend(currentTargetCharacterNameRaw) then
            local function AlreadyFriendsWarning() ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_PLAYER_TO_PLAYER_ALREADY_FRIEND) end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_ADD_FRIEND), platformIcons[SI_PLAYER_TO_PLAYER_ADD_FRIEND], DISABLED, AlreadyFriendsWarning)
        else
            local function RequestFriendOption()
                if IsConsoleUI() then
                    ZO_ShowConsoleAddFriendDialog(currentTargetCharacterName)
                else
                    RequestFriend(currentTargetDisplayName)
                end
            end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_ADD_FRIEND), platformIcons[SI_PLAYER_TO_PLAYER_ADD_FRIEND], ENABLED_IF_NOT_IGNORED, ENABLED_IF_NOT_IGNORED and RequestFriendOption or AlertIgnored)
        end

        --Report--
        local reportCallback
        if IsInGamepadPreferredMode() then
            local dialogData = { characterName = currentTargetCharacterName, displayName = currentTargetDisplayName,}
            reportCallback = function() ZO_Dialogs_ShowGamepadDialog("GAMEPAD_REPORT_PLAYER_DIALOG", dialogData, {mainTextParams = {formattedPlayerNames}}) end              
        else
            reportCallback = function() ZO_ReportPlayerDialog_Show(primaryName, REPORT_PLAYER_REASON_BOTTING, formattedPlayerNames) end
        end
		self:AddMenuEntry(GetString(SI_CHAT_PLAYER_CONTEXT_REPORT), platformIcons[SI_CHAT_PLAYER_CONTEXT_REPORT], ENABLED, reportCallback)
        
        --Duel--
        local duelState, partnerCharacterName, partnerDisplayName = GetDuelInfo()
        if duelState ~= DUEL_STATE_IDLE then
            local function AlreadyDuelingWarning(duelState, characterName, displayName)
                return function()
                    local userFacingPartnerName = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
                    local statusString = GetString("SI_DUELSTATE", duelState)
                    statusString = zo_strformat(statusString, userFacingPartnerName)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, statusString)    
                end
            end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_DUEL), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_DUEL], DISABLED, AlreadyDuelingWarning(duelState, partnerCharacterName, partnerDisplayName))
        else
            local function DuelInviteOption()
                ChallengeTargetToDuel(currentTargetCharacterName)
            end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_DUEL), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_DUEL], ENABLED_IF_NOT_IGNORED, ENABLED_IF_NOT_IGNORED and DuelInviteOption or AlertIgnored)
        end

        --Trade--
        local function TradeInviteOption() TRADE_WINDOW:InitiateTrade(primaryNameInternal) end
        local tradeInviteFunction = ENABLED_IF_NOT_IGNORED and TradeInviteOption or AlertIgnored
        self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_TRADE), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_TRADE], ENABLED_IF_NOT_IGNORED, tradeInviteFunction)

        --Cancel--
        self:AddMenuEntry(GetString(SI_RADIAL_MENU_CANCEL_BUTTON), platformIcons[SI_RADIAL_MENU_CANCEL_BUTTON], ENABLED)

        self:GetRadialMenu():Show()
    end
end

function ZO_PlayerToPlayer_OnKeybindEffectivelyShown(control)
    if ZO_RZCHROMA_EFFECTS then
        local keybindAction = control:GetKeyboardKeybind()
        ZO_RZCHROMA_EFFECTS:AddKeybindActionEffect(keybindAction)
    end
end

function ZO_PlayerToPlayer_OnKeybindEffectivelyHidden(control)
    if ZO_RZCHROMA_EFFECTS then
        local keybindAction = control:GetKeyboardKeybind()
        ZO_RZCHROMA_EFFECTS:RemoveKeybindActionEffect(keybindAction)
    end
end

function ZO_PlayerToPlayer_Initialize(control)
    PLAYER_TO_PLAYER = ZO_PlayerToPlayer:New(control)
end
