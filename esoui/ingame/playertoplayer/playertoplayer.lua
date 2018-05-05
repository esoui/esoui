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
local INTERACT_TYPE_LFG_FIND_REPLACEMENT = 10
local INTERACT_TYPE_GROUP_ELECTION = 11
local INTERACT_TYPE_DUEL_INVITE = 12
local INTERACT_TYPE_LFG_READY_CHECK = 13
local INTERACT_TYPE_CLAIM_LEVEL_UP_REWARDS = 14
local INTERACT_TYPE_GIFT_RECEIVED = 15

local TIMED_PROMPTS =
{
    [INTERACT_TYPE_LFG_READY_CHECK] = true,
    [INTERACT_TYPE_CAMPAIGN_QUEUE] = true,
    [INTERACT_TYPE_WORLD_EVENT_INVITE] = true,
    [INTERACT_TYPE_GROUP_ELECTION] = true,
}

ZO_PlayerToPlayer = ZO_Object:Subclass()

local function ShouldUseGamepadResponseMenu(data)
    return IsInGamepadPreferredMode() and data.pendingResponse
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

--Gets or creates the radial menu for the current keyboard/gamepad mode
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

--Gets the radial menu that is currently showing
function ZO_PlayerToPlayer:GetCurrentlyShowingRadialMenu()
    if self.gamepadMenu and self.gamepadMenu:IsShown() then
        return self.gamepadMenu
    elseif self.keyboardMenu and self.keyboardMenu:IsShown() then
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
            expiresAtS = GetFrameTimeSeconds() + remainingSeconds,
            dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_CAMPAIGN_QUEUE),
        }

    return campaignData
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
        PlaySound(SOUNDS.MARA_INVITE_RECEIVED)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_RITUAL_OF_MARA)

        local userFacingTargetName = ZO_GetPrimaryPlayerNameWithSecondary(targetDisplayName, targetCharacterName)
        local ritualPromptStringId = isSender and SI_PLAYER_TO_PLAYER_OUTGOING_RITUAL_OF_MARA or SI_PLAYER_TO_PLAYER_INCOMING_RITUAL_OF_MARA
        local ritualPromptText = zo_strformat(ritualPromptStringId, ZO_SELECTED_TEXT:Colorize(userFacingTargetName))

        local function AcceptRitualOfMara()
            ZO_Dialogs_ShowPlatformDialog("RITUAL_OF_MARA_PROMPT", nil,
            {
                mainTextParams =
                {
                    ZO_SELECTED_TEXT:Colorize(ZO_FormatUserFacingDisplayName(targetDisplayName)),
                    zo_floor(GetRingOfMaraExperienceBonus() * 100),
                    ZO_SELECTED_TEXT:Colorize(targetCharacterName),
                }
            })
        end
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE_RITUAL_OF_MARA, targetCharacterName, targetDisplayName, ritualPromptText, AcceptRitualOfMara)
        data.acceptText = GetString(SI_PLEDGE_OF_MARA_BEGIN_RITUAL_PROMPT)
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

            local function DeferDecisionCallback()
                self:RemoveFromIncomingQueue(INTERACT_TYPE_CAMPAIGN_QUEUE, campaignId)
            end

            --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
            local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_CAMPAIGN_QUEUE, campaignId, campaignId, nil,
                function()
                    local campaignBrowser = IsInGamepadPreferredMode() and GAMEPAD_AVA_BROWSER or CAMPAIGN_BROWSER
                    campaignBrowser:GetCampaignBrowser():ShowCampaignQueueReadyDialog(campaignId, isGroup, campaignQueueData.campaignName)
                end,
                function()
                    ConfirmCampaignEntry(campaignId, isGroup, false)
                end,
                DeferDecisionCallback)

            promptData.messageFormat = campaignQueueData.messageFormat
            promptData.messageParams = campaignQueueData.messageParams
            promptData.expiresAtS = campaignQueueData.expiresAtS
            promptData.dialogTitle = campaignQueueData.dialogTitle
            promptData.expirationCallback = DeferDecisionCallback
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

        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE_WORLD_EVENT_INVITE)
        end

        local timeRemainingMS = GetScriptedEventInviteTimeRemainingMS(eventId)
        data.expiresAtS = GetFrameTimeSeconds() + (timeRemainingMS / ZO_ONE_SECOND_IN_MILLISECONDS)
        data.expirationCallback = DeferDecisionCallback
        data.dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_SCRIPTED_WORLD_EVENT)

        if inviterName == "" then
            if questName == "" then
                data.messageFormat = SI_EVENT_INVITE
                data.messageParams = { eventName }
            else
                data.messageFormat = SI_EVENT_INVITE_QUEST
                data.messageParams = { eventName, questName }
            end
        else
            if questName == "" then
                data.messageFormat = SI_EVENT_INVITE_NAMED
                data.messageParams = { inviterName, eventName}
            else
                data.messageFormat = SI_EVENT_INVITE_NAMED_QUEST
                data.messageParams = { inviterName, eventName, questName }
            end
        end

        data.eventId = eventId
        data.questName = questName

        data.uniqueSounds = {
            accept = SOUNDS.SCRIPTED_WORLD_EVENT_ACCEPTED,
            decline = SOUNDS.SCRIPTED_WORLD_EVENT_DECLINED,
        }
    end

    local function OnScriptedWorldEventInviteRemoved(eventCode, eventId)
        self:RemoveScriptedWorldEventFromIncomingQueue(eventId)
    end

    local function OnLevelUpRewardUpdated()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_CLAIM_LEVEL_UP_REWARDS)

        local pendingRewardLevel = GetPendingLevelUpRewardLevel()
        if pendingRewardLevel then
            local data = self:AddPromptToIncomingQueue(INTERACT_TYPE_CLAIM_LEVEL_UP_REWARDS, nil, nil, zo_strformat(SI_LEVEL_UP_REWARDS_AVAILABLE_NOTIFICATION, pendingRewardLevel),
            function()
                if IsInGamepadPreferredMode() then
                    SCENE_MANAGER:Show("LevelUpRewardsClaimGamepad")
                else
                    SYSTEMS:GetObject("mainMenu"):ToggleCategory(MENU_CATEGORY_CHARACTER)
                end
            end)
            data.dontRemoveOnAccept = true
            data.acceptText = GetString(SI_LEVEL_UP_REWARDS_OPEN_CLAIM_SCREEN_TEXT)
            data.declineText = GetString(SI_LEVEL_UP_REWARDS_DISMISS_NOTIFICATION)
        end
    end

    local function OnGiftsUpdated()
        self:RemoveAllFromIncomingQueue(INTERACT_TYPE_GIFT_RECEIVED)

        local giftList = GIFT_INVENTORY_MANAGER:GetGiftList(GIFT_STATE_RECEIVED)
        for _, gift in ipairs(giftList) do
            if not gift:HasBeenSeen() then
                local NO_CHARACTER_NAME = nil
                local data = self:AddPromptToIncomingQueue(INTERACT_TYPE_GIFT_RECEIVED, NO_CHARACTER_NAME, gift:GetPlayerName(), zo_strformat(SI_PLAYER_TO_PLAYER_GIFT_RECEIVED, ZO_SELECTED_TEXT:Colorize(gift:GetUserFacingPlayerName())),
                    function()
                        local giftInventoryView = SYSTEMS:GetObject("giftInventoryView")
                        giftInventoryView:SetupAndShowGift(gift)
                    end,
                    function()
                        gift:View()
                    end)
                data.acceptText = GetString(SI_GIFT_INVENTORY_OPEN_CLAIM_SCREEN_TEXT)
                data.declineText = GetString(SI_GIFT_INVENTORY_DISMISS_NOTIFICATION)
                TriggerTutorial(TUTORIAL_TRIGGER_GIFT_RECEIVED)
            end
        end
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
    self.control:RegisterForEvent(EVENT_LEVEL_UP_REWARD_UPDATED, OnLevelUpRewardUpdated)

    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftListsChanged", OnGiftsUpdated)

    --Find member replacement prompt on a member leaving
    local function OnGroupingToolsFindReplacementNotificationNew()
        local activityId = GetActivityFindReplacementNotificationInfo()

        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT)
        end
        
        local dungeonName = GetActivityName(activityId)
        
        PlaySound(SOUNDS.LFG_FIND_REPLACEMENT)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT)
        
        local text = zo_strformat(SI_LFG_FIND_REPLACEMENT_TEXT, dungeonName)
        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT, nil, nil, text, AcceptActivityFindReplacementNotification, DeclineActivityFindReplacementNotification, DeferDecisionCallback)
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

        promptData.expiresAtS = GetFrameTimeSeconds() + timeRemainingSeconds
        promptData.messageFormat = messageFormat
        promptData.messageParams = messageParams
        promptData.expirationCallback = DeferDecisionCallback
        promptData.dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_GROUP_ELECTION)
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
        if duelState == DUEL_STATE_INVITE_CONSIDERING then
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

        local questShareIds = { GetOfferedQuestShareIds() }
        for _, questId in ipairs(questShareIds) do
            OnQuestShared(EVENT_QUEST_SHARED, questId)
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

        if HasLFGReadyCheckNotification() then
            self:OnGroupingToolsReadyCheckUpdated()
        end

        if HasActivityFindReplacementNotification() then
            OnGroupingToolsFindReplacementNotificationNew()
        end

        if HasPendingGroupElectionVote() then
            OnGroupElectionNotificationAdded()
        end

        if HasPendingLevelUpReward() then
            OnLevelUpRewardUpdated()
        end

        OnGiftsUpdated()
    end

    local function OnPlayerDeactivated()
        self:RemoveFromIncomingQueue(INTERACT_TYPE_DUEL_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_GROUP_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_TRADE_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_RITUAL_OF_MARA)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_QUEST_SHARE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_WORLD_EVENT_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_LFG_FIND_REPLACEMENT)
        self:RemoveFromIncomingQueue(INTERACT_TYPE_QUEST_SHARE)
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

    self.control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() 
        self:StopInteraction()
    end)
end

function ZO_PlayerToPlayer:SetHidden(hidden)
    SHARED_INFORMATION_AREA:SetHidden(self.container, hidden)
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
    if not data.dontRemoveOnAccept then
        data.pendingResponse = false
    end
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
    if not data.dontRemoveOnDecline then
        data.pendingResponse = false
    end
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

function ZO_PlayerToPlayer:ShowGamepadResponseMenu(data)
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

    self.showingGamepadResponseMenu = true
end

do
    local function IncomingEntryComparator(leftData, rightData)
        -- leftData is the entry we're trying to add, rightData is the iterated existing entry to compare against
        local isAddingTimedPrompt = TIMED_PROMPTS[leftData.incomingType]
        local isComparingTimedPrompt = TIMED_PROMPTS[rightData.incomingType]
        if isAddingTimedPrompt ~= isComparingTimedPrompt then
            if isAddingTimedPrompt then
                return -1 -- Time prompts trump non-timed prompts, move to front of queue
            else
                return 1 -- Non-timed prompt, move to after all timed prompts
            end
        else
            -- Timed and Non-timed prompts are last in first out, most recent should go to the front of the queue
            return -1
        end
    end
    
    -- inviter name is the decorated name that is choosen based on player preferences
    -- where display and character name are descrete strings that are used to determine the creator of the entry
    function ZO_PlayerToPlayer:AddIncomingEntry(incomingType, inviterName, targetLabel, displayName, characterName)
        local data = { incomingType = incomingType, targetLabel = targetLabel, inviterName = inviterName, pendingResponse = true, displayName = displayName, characterName = characterName}
        zo_binaryinsert(data, data, self.incomingQueue, IncomingEntryComparator)
        return data
    end
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
                local incomingEntry = self:RemoveEntryFromIncomingQueueTable(i)

                if i == 1 and (self.responding or self.showingGamepadResponseMenu) then
                    self:StopInteraction()
                end
                break
            end
        end
    end

    function ZO_PlayerToPlayer:RemoveAllFromIncomingQueue(incomingType, characterName, displayName)
        for i, incomingEntry in ipairs(self.incomingQueue) do
            if DoesDataMatch(incomingEntry, incomingType, characterName, displayName) then
                local incomingEntry = self:RemoveEntryFromIncomingQueueTable(i)

                if i == 1 and (self.responding or self.showingGamepadResponseMenu) then
                    self:StopInteraction()
                end
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
            self:RemoveEntryFromIncomingQueueTable(i)
            break
        end
    end
end

function ZO_PlayerToPlayer:RemoveQuestShareFromIncomingQueue(questId)
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.incomingType == INTERACT_TYPE_QUEST_SHARE and incomingEntry.questId == questId then
            self:RemoveEntryFromIncomingQueueTable(i)
            break
        end
    end
end

function ZO_PlayerToPlayer:RemoveScriptedWorldEventFromIncomingQueue(eventId, questName)
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.incomingType == INTERACT_TYPE_WORLD_EVENT_INVITE and (incomingEntry.eventId == eventId or incomingEntry.questName == questName) then
            self:RemoveEntryFromIncomingQueueTable(i)

            if i == 1 and self.responding then
                self:StopInteraction()
            end
            break
        end
    end
end

function ZO_PlayerToPlayer:GetIndexFromIncomingQueue(incomingEntryToMatch)
    if incomingEntryToMatch then
        for i, incomingEntry in ipairs(self.incomingQueue) do
            if incomingEntryToMatch == incomingEntry then
                return i
            end
        end
    end
    return nil
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
            local activityTypeText = GetString("SI_LFGACTIVITY", activityType)
            local generalActivityText = ZO_ACTIVITY_FINDER_GENERALIZED_ACTIVITY_DESCRIPTORS[activityType]
            if role == LFG_ROLE_INVALID then
                messageFormat = SI_LFG_READY_CHECK_NO_ROLE_TEXT
                messageParams = { activityTypeText, generalActivityText }
            else
                local roleIconPath = GetRoleIcon(role)
                local roleIconFormat = zo_iconFormat(roleIconPath, "100%", "100%")

                messageFormat = SI_LFG_READY_CHECK_TEXT
                messageParams = { activityTypeText, generalActivityText, roleIconFormat, GetString("SI_LFGROLE", role) }
            end

            promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE_LFG_READY_CHECK, nil, nil, nil, AcceptLFGReadyCheckNotification, DeclineLFGReadyCheckNotification, DeferDecisionCallback)
            promptData.acceptText = GetString(SI_LFG_READY_CHECK_ACCEPT)
            promptData.expiresAtS = GetFrameTimeSeconds() + timeRemainingSeconds
            promptData.messageFormat = messageFormat
            promptData.messageParams = messageParams
            promptData.expirationCallback = DeferDecisionCallback
            promptData.dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_LFG)

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
end

function ZO_PlayerToPlayer:SetDelayPromptTime(timeMs)
    self.msToDelayToShowPrompt = timeMs
end

function ZO_PlayerToPlayer:TryDisplayingIncomingRequests()
    if self.responding then
        local incomingEntryToRespondTo = self.incomingQueue[1]
        if ShouldUseGamepadResponseMenu(incomingEntryToRespondTo) then
            --if there is only one option just accept it instead of showing a radial with one option
            if not incomingEntryToRespondTo.declineCallback and not incomingEntryToRespondTo.deferDecisionCallback then
                NotificationAccepted(incomingEntryToRespondTo)
            else
                LockCameraRotation(true)
                RETICLE:RequestHidden(true)
                self.targetLabel:SetHidden(true)
                self:ShowGamepadResponseMenu(incomingEntryToRespondTo)
            end

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
        -- Keyboard only requires a target to start interaction, self.responding is only used by Gamepad and does not require a target 
        local isInteractionPossible = self:HasTarget() or (IsInGamepadPreferredMode() and self.responding)
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
    local currentlyShowingRadialMenu = self:GetCurrentlyShowingRadialMenu()
    
    if self.isInteracting then
        self.isInteracting = false
        RETICLE:RequestHidden(false)
        LockCameraRotation(false)

        CancelSoulGemResurrection()

        if currentlyShowingRadialMenu then
            currentlyShowingRadialMenu:SelectCurrentEntry()
        end

        self.lastFailedPromptTime = GetFrameTimeMilliseconds() - self.msToDelayToShowPrompt
    elseif self.responding then
        self.responding = false
        if self.showingGamepadResponseMenu and currentlyShowingRadialMenu then
            currentlyShowingRadialMenu:SelectCurrentEntry()
        end
    end

    if self.showingGamepadResponseMenu then
        self.showingGamepadResponseMenu = false
        RETICLE:RequestHidden(false)
        LockCameraRotation(false)
        if currentlyShowingRadialMenu then
            currentlyShowingRadialMenu:Clear()
        end
    end
end

function ZO_PlayerToPlayer:Accept(incomingEntry)
    local index = self:GetIndexFromIncomingQueue(incomingEntry)
    if index then
        if not incomingEntry.dontRemoveOnAccept then
            self:RemoveEntryFromIncomingQueueTable(index)
        end
        NotificationAccepted(incomingEntry)
    else
        self:OnPromptAccepted()
    end
end

function ZO_PlayerToPlayer:Decline(incomingEntry)
    local index = self:GetIndexFromIncomingQueue(incomingEntry)
    if index then
        if not incomingEntry.dontRemoveOnDecline then
            self:RemoveEntryFromIncomingQueueTable(index)
        end
        NotificationDeclined(incomingEntry)
    else
        self:OnPromptDeclined()
    end
end

--With proper timing, both of these events can fire in the same frame, making it possible to be responding but having already cleared the incoming queue
function ZO_PlayerToPlayer:OnPromptAccepted()
    if self.responding and #self.incomingQueue > 0 then
        local incomingEntryToRespondTo = self.incomingQueue[1]
        if not incomingEntryToRespondTo.dontRemoveOnAccept then
            self:RemoveEntryFromIncomingQueueTable(1)
        end
        NotificationAccepted(incomingEntryToRespondTo)
    end
end

function ZO_PlayerToPlayer:OnPromptDeclined()
    if self.responding and #self.incomingQueue > 0 then
        local incomingEntryToRespondTo = self.incomingQueue[1]
        if not incomingEntryToRespondTo.dontRemoveOnDecline then
            self:RemoveEntryFromIncomingQueueTable(1)
        end
        NotificationDeclined(incomingEntryToRespondTo)
    end
end

function ZO_PlayerToPlayer:RemoveEntryFromIncomingQueueTable(index)
    local incomingEntry = table.remove(self.incomingQueue, index)
    if incomingEntry.expiresAtS then
        ZO_Dialogs_ReleaseAllDialogsOfName("PTP_TIMED_RESPONSE_PROMPT", function(dialogData) return dialogData == incomingEntry end)
    end
    return incomingEntry
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

function ZO_PlayerToPlayer_GetIncomingEntryDisplayText(incomingEntry)
    if incomingEntry.targetLabel then
        return incomingEntry.targetLabel
    elseif incomingEntry.messageFormat then
        if incomingEntry.expiresAtS then
            local remainingTime = zo_max(incomingEntry.expiresAtS - GetFrameTimeSeconds(), 0)
            local formattedTime = ZO_FormatTime(remainingTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            local params = {unpack(incomingEntry.messageParams)}
            table.insert(params, formattedTime)
            return zo_strformat(incomingEntry.messageFormat, unpack(params))
        else
            return zo_strformat(incomingEntry.messageFormat, unpack(incomingEntry.messageParams))
        end
    end
end

function ZO_PlayerToPlayer:TryShowingResponseLabel()
    if #self.incomingQueue > 0 then
        local incomingEntry = self.incomingQueue[1]
        if incomingEntry.pendingResponse then
            -- Set text on the label
            local displayText = ZO_PlayerToPlayer_GetIncomingEntryDisplayText(incomingEntry)
            local font = IsInGamepadPreferredMode() and "ZoFontGamepad42" or "ZoInteractionPrompt"
            self.targetLabel:SetText(displayText)
            self.targetLabel:SetFont(font)
            self.targetLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())

            --Check for expiration
            if incomingEntry.messageFormat and incomingEntry.expiresAtS and incomingEntry.expirationCallback then
                if GetFrameTimeSeconds() > incomingEntry.expiresAtS then
                    incomingEntry.expirationCallback()
                end
            end

            if ShouldUseGamepadResponseMenu(incomingEntry) then
                if not self.showingGamepadResponseMenu then
                    self:ShowResponseActionKeybind(GetString(SI_GAMEPAD_PLAYER_TO_PLAYER_ACTION_RESPOND))
                end
            else
                if incomingEntry.acceptCallback then
                    local acceptText = incomingEntry.acceptText or GetString(SI_DIALOG_ACCEPT)
                    self.promptKeybindButton1:SetText(acceptText)
                    self.promptKeybindButton1.shouldHide = false
                end
                if incomingEntry.declineCallback then
                    local declineText = incomingEntry.declineText or GetString(SI_DIALOG_DECLINE)
                    self.promptKeybindButton2:SetText(declineText)
                    self.promptKeybindButton2.shouldHide = false
                end
                self.shouldShowNotificationKeybindLayer = true
            end

            self.responding = true
            incomingEntry.seen = true
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

        if incomingEntry.expiresAtS and not incomingEntry.seen and SCENE_MANAGER:IsInUIMode() then
            -- For time sensitive prompts, if the player can't see them, throw up a dialog before it's too late to respond
            ZO_Dialogs_ShowPlatformDialog("PTP_TIMED_RESPONSE_PROMPT", incomingEntry)
            incomingEntry.seen = true
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
        self.promptKeybindButton1.shouldHide = true
        self.promptKeybindButton2.shouldHide = true

        if (not self.isInteracting) or (not IsConsoleUI()) then
            self.gamerID:SetHidden(true)
        end

        self.shouldShowNotificationKeybindLayer = false

        local hideSelf, hideTargetLabel
        local isReticleTargetInteractable = self:IsReticleTargetInteractable()
        if isReticleTargetInteractable and self:TryShowingResurrectLabel() then
            hideSelf = false
            hideTargetLabel = false
        elseif not self.isInteracting and (self.showingGamepadResponseMenu or not IsUnitInCombat("player")) and self:TryShowingResponseLabel() then
            hideSelf = false
            hideTargetLabel = self.showingGamepadResponseMenu
        elseif not self.isInteracting and isReticleTargetInteractable and self:TryShowingStandardInteractLabel() then
            hideSelf = not self:ShouldShowPromptAfterDelay()
            hideTargetLabel = hideSelf
        elseif self.isInteracting then
            hideSelf = false
            hideTargetLabel = true
        else
            hideSelf = true
            hideTargetLabel = true
        end
        
        -- These must be called after we've determined what state they should be in
        -- Because if we simply hide and re-show them, the Chroma behavior will not function correctly
        self:SetHidden(hideSelf)
        self.targetLabel:SetHidden(hideTargetLabel)
        self.promptKeybindButton1:SetHidden(self.promptKeybindButton1.shouldHide)
        self.promptKeybindButton2:SetHidden(self.promptKeybindButton2.shouldHide)

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
        disabledNormal =  "EsoUI/Art/HUD/Gamepad/gp_radialIcon_removeFromGroup_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_removeFromGroup_disabled.dds",
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
        local isGroupModificationAvailable = IsGroupModificationAvailable()
        local groupModicationRequiresVoting = DoesGroupModificationRequireVote()
        local isSoloOrLeader = IsUnitSoloOrGroupLeader("player")

        local function AlertGroupDisabled()
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_PLAYER_TO_PLAYER_GROUP_DISABLED))
        end

        if IsPlayerInGroup(currentTargetCharacterNameRaw) then
            local groupKickEnabled = isGroupModificationAvailable and isSoloOrLeader and not groupModicationRequiresVoting
            local groupKickFunction = nil
            if groupKickEnabled then
                groupKickFunction = function() GroupKickByName(currentTargetCharacterNameRaw) end
            else
                groupKickFunction = AlertGroupDisabled
            end
            
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_REMOVE_GROUP), platformIcons[SI_PLAYER_TO_PLAYER_REMOVE_GROUP], groupKickEnabled, groupKickFunction)
        else
            local groupInviteEnabled = ENABLED_IF_NOT_IGNORED and isGroupModificationAvailable and isSoloOrLeader
            local groupInviteFunction = nil
            if groupInviteEnabled then
                groupInviteFunction = function()
                    local NOT_SENT_FROM_CHAT = false
                    local DISPLAY_INVITED_MESSAGE = true
                    TryGroupInviteByName(primaryNameInternal, NOT_SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE)
                end
            else
                if ENABLED_IF_NOT_IGNORED then
                    groupInviteFunction = AlertGroupDisabled
                else
                    groupInviteFunction = AlertIgnored
                end
            end

            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_ADD_GROUP), platformIcons[SI_PLAYER_TO_PLAYER_ADD_GROUP], groupInviteEnabled, groupInviteFunction)
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
        local function ReportCallback()
            local nameToReport = IsInGamepadPreferredMode() and currentTargetDisplayName or primaryName
            ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(nameToReport)
        end
        self:AddMenuEntry(GetString(SI_CHAT_PLAYER_CONTEXT_REPORT), platformIcons[SI_CHAT_PLAYER_CONTEXT_REPORT], ENABLED, ReportCallback)
        
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

function ZO_PlayerToPlayer_Initialize(control)
    PLAYER_TO_PLAYER = ZO_PlayerToPlayer:New(control)
end
