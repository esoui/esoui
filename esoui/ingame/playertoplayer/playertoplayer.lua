local P2P_UNIT_TAG = "reticleoverplayer"
local P2C_UNIT_TAG = "reticleovercompanion"

-- For use inside this file, to aleviate the need for global table lookups
local INTERACT_TYPE =
{
    AGENT_CHAT_REQUEST = 1,
    RITUAL_OF_MARA = 2,
    TRADE_INVITE = 3,
    GROUP_INVITE = 4,
    QUEST_SHARE = 5,
    FRIEND_REQUEST = 6,
    GUILD_INVITE = 7,
    CAMPAIGN_QUEUE = 8,
    WORLD_EVENT_INVITE = 9,
    LFG_FIND_REPLACEMENT = 10,
    GROUP_ELECTION = 11,
    DUEL_INVITE = 12,
    LFG_READY_CHECK = 13,
    CLAIM_LEVEL_UP_REWARDS = 14,
    GIFT_RECEIVED = 15,
    TRACK_ZONE_STORY = 16,
    CAMPAIGN_QUEUE_JOINED = 17,
    CAMPAIGN_LOCK_PENDING = 18,
    TRAVEL_TO_LEADER = 19,
    TRIBUTE_INVITE = 20,
    GROUP_FINDER_APPLICATION = 21,
    PROMOTIONAL_EVENT_REWARD = 22,
}

-- For use outside of this file (e.g. InGameDialogs)
ZO_INTERACT_TYPE = INTERACT_TYPE

local TIMED_PROMPTS =
{
    [INTERACT_TYPE.LFG_READY_CHECK] = true,
    [INTERACT_TYPE.CAMPAIGN_QUEUE] = true,
    [INTERACT_TYPE.WORLD_EVENT_INVITE] = true,
    [INTERACT_TYPE.GROUP_ELECTION] = true,
    [INTERACT_TYPE.CAMPAIGN_LOCK_PENDING] = true,
    [INTERACT_TYPE.DUEL_INVITE] = true,
    [INTERACT_TYPE.TRIBUTE_INVITE] = true,
    -- Campaign Queue is the only timed prompt without a fixed expiration time; instead it's manually removed when the queue it's a part of pops.
    -- This means it does not define expiresAtS or expirationCallback, and it refreshes every second without necessarily needing to; it doesn't show a timer.
    [INTERACT_TYPE.CAMPAIGN_QUEUE_JOINED] = true,
}

-- Prompts that are NOT in the TIMED_PROMPTS table but we still want to have flashing behavior on the task bar.
local FLASHING_PROMPTS =
{
    [INTERACT_TYPE.GROUP_FINDER_APPLICATION] = true,
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

        self.hotkeyBeginHolds = {}

        EVENT_MANAGER:RegisterForUpdate(control:GetName() .. "OnUpdate", 0, function() self:OnUpdate() end)
        control:RegisterForEvent(EVENT_DUEL_STARTED, function() self:OnDuelStarted() end)

        SHARED_INFORMATION_AREA:AddPlayerToPlayer(self.container)

        ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

        --Set up narration for the player to player prompts
        local narrationInfo =
        {
            canNarrate = function()
                return not self:IsHidden() and not SHARED_INFORMATION_AREA:IsSuppressed()
            end,
            selectedNarrationFunction = function()
                local narrations = {}
                if not self.targetLabel:IsHidden() then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.targetTextNarration))
                end

                if not self.pendingResurrectInfo:IsHidden() then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.pendingResurrectText))
                end
                return narrations
            end,
            additionalInputNarrationFunction = function()
                local narrationData =  {}
                if not self.actionKeybindButton:IsHidden() then
                    table.insert(narrationData, self.actionKeybindButton:GetKeybindButtonNarrationData())
                end
                return narrationData
            end,
            narrationType = NARRATION_TYPE_HUD,
        }
        SCREEN_NARRATION_MANAGER:RegisterCustomObject("PlayerToPlayerPrompt", narrationInfo)
    end
end

function ZO_PlayerToPlayer:OnDuelStarted()
    self:StopInteraction()
end

function ZO_PlayerToPlayer:OnTributeStarted()
    self:StopInteraction()
end

function ZO_PlayerToPlayer:CreateGamepadRadialMenu()
    local USE_DEFAULT_DIRECTIONAL_INPUTS = nil
    local DEFAULT_ENABLE_MOUSE = nil
    local DEFAULT_SELECT_IF_CENTERED = nil
    self.gamepadMenu = ZO_RadialMenu:New(ZO_PlayerToPlayerMenu_Gamepad, "ZO_RadialMenuHUDEntryTemplate_Gamepad", "DefaultRadialMenuAnimation", "DefaultRadialMenuEntryAnimation", "RadialMenu", USE_DEFAULT_DIRECTIONAL_INPUTS, DEFAULT_ENABLE_MOUSE, DEFAULT_SELECT_IF_CENTERED, ZO_AreTogglableWheelsEnabled)
    self.gamepadMenu:SetOnClearCallback(function()
        self:StopInteraction()
    end)

    self.gamepadMenu:SetOnSelectionChangedCallback(function(selectedEntry)
        --Re-narrate when the selection changes
        if selectedEntry then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("PlayerToPlayerWheel")
        end
    end)

    self.gamepadMenu:SetKeybindActionLayer("PlayerToPlayerAccessibleLayer")

    --Set up narration for the player interact wheels
    local narrationInfo =
    {
        canNarrate = function()
            return self.showingPlayerInteractMenu or self.showingGamepadResponseMenu
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            local selectedEntry = self.gamepadMenu.selectedEntry
            if selectedEntry then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedEntry.name))
            end
            return narrations
        end,
        headerNarrationFunction = function()
            if self.showingPlayerInteractMenu then
                return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_PLAYER_TO_PLAYER_INTERACT_WHEEL_NARRATION))
            elseif self.showingGamepadResponseMenu then
                return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_PLAYER_TO_PLAYER_RESPONSE_WHEEL_NARRATION))
            end
        end,
        additionalInputNarrationFunction = function()
            local narrationData = {}
            if self.gamepadMenu:ShouldShowKeybinds() then
                self.gamepadMenu:ForEachOrdinalEntry(function(ordinalIndex, entry)
                    local actionName = ZO_GetRadialMenuActionNameForOrdinalIndex(ordinalIndex)
                    local entryNarrationData =
                    {
                        name = entry.name,
                        keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(actionName) or GetString(SI_ACTION_IS_NOT_BOUND),
                        enabled = true,
                    }

                    table.insert(narrationData, entryNarrationData)
                end)
            end
            return narrationData
        end,
        narrationType = NARRATION_TYPE_HUD,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("PlayerToPlayerWheel", narrationInfo)
end

function ZO_PlayerToPlayer:CreateKeyboardRadialMenu()
    local USE_DEFAULT_DIRECTIONAL_INPUTS = nil
    local DEFAULT_ENABLE_MOUSE = nil
    local DEFAULT_SELECT_IF_CENTERED = nil
    self.keyboardMenu = ZO_RadialMenu:New(ZO_PlayerToPlayerMenu_Keyboard, "ZO_PlayerToPlayerMenuEntryTemplate_Keyboard", "DefaultRadialMenuAnimation", "DefaultRadialMenuEntryAnimation", "RadialMenu", USE_DEFAULT_DIRECTIONAL_INPUTS, DEFAULT_ENABLE_MOUSE, DEFAULT_SELECT_IF_CENTERED, ZO_AreTogglableWheelsEnabled)
    self.keyboardMenu:SetOnClearCallback(function()
        self:StopInteraction()
    end)
    self.keyboardMenu:SetKeybindActionLayer("PlayerToPlayerAccessibleLayer")
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

--Gets the radial menu that was most recently interacted with. This resolves issues where switching platform type during an interaction sent the close events to the wrong menu
function ZO_PlayerToPlayer:GetLastActiveRadialMenu()
    internalassert(self.isLastRadialMenuGamepad ~= nil, "GetLastActiveRadialMenu() called without a previous active menu")
    if self.isLastRadialMenuGamepad then
        return internalassert(self.gamepadMenu)
    else
        return internalassert(self.keyboardMenu)
    end
end

function ZO_PlayerToPlayer:InitializeKeybinds()
    self.actionKeybindButton:SetKeybind("PLAYER_TO_PLAYER_INTERACT")
end

function ZO_PlayerToPlayer:InitializeSoulGemResurrectionEvents()
    self.control:RegisterForEvent(EVENT_START_SOUL_GEM_RESURRECTION, function(eventCode, ...) self:OnStartSoulGemResurrection(...) end)
    self.control:RegisterForEvent(EVENT_END_SOUL_GEM_RESURRECTION, function(eventCode, ...) self:OnEndSoulGemResurrection(...) end)
end

local function GetCampaignConfirmQueueData(campaignId, isGroup)
    local campaignRulesetTypeString = GetString("SI_CAMPAIGNRULESETTYPE", GetCampaignRulesetType(GetCampaignRulesetId(campaignId)))
    local campaignName = GetCampaignName(campaignId)
    local remainingSeconds = GetCampaignQueueRemainingConfirmationSeconds(campaignId, isGroup)
    local campaignData =
    {
        campaignId = campaignId,
        isGroup = isGroup,
        campaignName = campaignName,
        messageFormat = SI_CAMPAIGN_QUEUE_MESSAGE,
        messageParams = { campaignRulesetTypeString, campaignName },
        expiresAtS = GetFrameTimeSeconds() + remainingSeconds,
        dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_CAMPAIGN_QUEUE),
    }

    return campaignData
end

local function GetCampaignQueueJoinedData(campaignId, isAboutToAllianceLock)
    local campaignRulesetTypeString = GetString("SI_CAMPAIGNRULESETTYPE", GetCampaignRulesetType(GetCampaignRulesetId(campaignId)))
    local campaignName = GetCampaignName(campaignId)
    local campaignData =
    {
        campaignId = campaignId,
        campaignName = campaignName,
        messageFormat = isAboutToAllianceLock and SI_CAMPAIGN_QUEUE_JOINED_AS_GROUP_WITH_ALLIANCE_LOCK_MESSAGE or SI_CAMPAIGN_QUEUE_JOINED_AS_GROUP_MESSAGE,
        messageParams = { campaignRulesetTypeString, ZO_SELECTED_TEXT:Colorize(campaignName) },
        dialogTitle = SI_CAMPAIGN_QUEUE_JOINED_AS_GROUP_TITLE,
    }

    return campaignData
end

function ZO_PlayerToPlayer:InitializeIncomingEvents()
    self.incomingQueue = {}

    local function OnDuelInviteReceived(eventCode, inviterCharacterName, inviterDisplayName, timeRemainingMS)
        PlaySound(SOUNDS.DUEL_INVITE_RECEIVED)

        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE.DUEL_INVITE)
        end

        local NO_TARGET_LABEL = nil
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.DUEL_INVITE, inviterCharacterName, inviterDisplayName, NO_TARGET_LABEL, AcceptDuel, DeclineDuel, DeferDecisionCallback)

        data.messageFormat = GetString(SI_PLAYER_TO_PLAYER_INCOMING_DUEL)
        -- the time left is added automatically to messageParams in position <<2>>
        data.messageParams = { ZO_SELECTED_TEXT:Colorize(data.inviterName) }
        data.dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_DUEL)
        data.expiresAtS = GetFrameTimeSeconds() + (timeRemainingMS / ZO_ONE_SECOND_IN_MILLISECONDS)
        data.expirationCallback = DeferDecisionCallback
    end

    local function OnDuelInviteRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.DUEL_INVITE)
    end
    
    local function OnTributeInviteReceived(eventCode, inviterCharacterName, inviterDisplayName, timeRemainingMS)
        PlaySound(SOUNDS.TRIBUTE_INVITE_RECEIVED)

        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE.TRIBUTE_INVITE)
        end

        local NO_TARGET_LABEL = nil
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.TRIBUTE_INVITE, inviterCharacterName, inviterDisplayName, NO_TARGET_LABEL, AcceptTribute, DeclineTribute, DeferDecisionCallback)

        data.messageFormat = GetString(SI_PLAYER_TO_PLAYER_INCOMING_TRIBUTE)
        -- the time left is added automatically to messageParams in position <<2>>
        data.messageParams = { ZO_SELECTED_TEXT:Colorize(data.inviterName) }
        data.dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_TRIBUTE_INVITE)
        data.expiresAtS = GetFrameTimeSeconds() + (timeRemainingMS / ZO_ONE_SECOND_IN_MILLISECONDS)
        data.expirationCallback = DeferDecisionCallback
    end

    local function OnTributeInviteRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRIBUTE_INVITE)
    end

    local function OnGroupInviteReceived(eventCode, inviterCharacterName, inviterDisplayName)
        if not self:ExistsInQueue(INTERACT_TYPE.GROUP_INVITE, inviterCharacterName, inviterDisplayName) then
            local userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(inviterDisplayName, inviterCharacterName)

            PlaySound(SOUNDS.GROUP_INVITE)
            self:RemoveFromIncomingQueue(INTERACT_TYPE.GROUP_INVITE)
            self:AddPromptToIncomingQueue(INTERACT_TYPE.GROUP_INVITE, inviterCharacterName, inviterDisplayName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_GROUP, ZO_SELECTED_TEXT:Colorize(userFacingName)),
                function()
                    AcceptGroupInvite()
                end,
                function()
                    DeclineGroupInvite()
                end,
                function()
                    self:RemoveFromIncomingQueue(INTERACT_TYPE.GROUP_INVITE, inviterCharacterName, inviterDisplayName)
                end)
        end
    end

    local function OnGroupInviteRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.GROUP_INVITE)
    end

    local function OnTradeWindowInviteConsidering(eventCode, inviterCharacterName, inviterDisplayName)
        PlaySound(SOUNDS.TRADE_INVITE_RECEIVED)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRADE_INVITE)
        local userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(inviterDisplayName, inviterCharacterName)
        -- There is server message received when trade is cancelled/accepted/declined, which sends a Lua event which will play a sound in AlertHandlers.lua
        self:AddPromptToIncomingQueue(INTERACT_TYPE.TRADE_INVITE, inviterCharacterName, inviterDisplayName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_TRADE, ZO_SELECTED_TEXT:Colorize(userFacingName)),
            function()
                TradeInviteAccept()
            end,
            function()
                TradeInviteDecline()
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE.TRADE_INVITE, inviterCharacterName, inviterDisplayName)
            end)
    end

    local function OnTradeWindowInviteRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRADE_INVITE)
    end

    local function OnQuestShared(eventCode, questId)
        PlaySound(SOUNDS.QUEST_SHARED)
        local questName, characterName, _, displayName = GetOfferedQuestShareInfo(questId)
        local name = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.QUEST_SHARE, characterName, displayName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_QUEST_SHARE, ZO_SELECTED_TEXT:Colorize(name), ZO_SELECTED_TEXT:Colorize(questName)),
            function()
                AcceptSharedQuest(questId)
            end,
            function()
                DeclineSharedQuest(questId)
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE.QUEST_SHARE, characterName, displayName)
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
        self:RemoveFromIncomingQueue(INTERACT_TYPE.RITUAL_OF_MARA)

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
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.RITUAL_OF_MARA, targetCharacterName, targetDisplayName, ritualPromptText, AcceptRitualOfMara)
        data.acceptText = GetString(SI_PLEDGE_OF_MARA_BEGIN_RITUAL_PROMPT)
    end

    local function OnPledgeOfMaraOfferRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.RITUAL_OF_MARA)
    end

    local function OnIncomingFriendInviteAdded(eventCode, inviterName)
        PlaySound(SOUNDS.FRIEND_INVITE_RECEIVED)
        local displayName = ZO_FormatUserFacingDisplayName(inviterName)
        self:AddPromptToIncomingQueue(INTERACT_TYPE.FRIEND_REQUEST, inviterName, nil, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_FRIEND_REQUEST, ZO_SELECTED_TEXT:Colorize(displayName)),
            function()
                AcceptFriendRequest(inviterName)
            end,
            function()
                RejectFriendRequest(inviterName)
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE.FRIEND_REQUEST, inviterName)
            end)
    end

    local function OnIncomingFriendRequestRemoved(eventCode, inviterName)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.FRIEND_REQUEST, inviterName)
    end

    local function OnGuildInviteAdded(eventCode, guildId, guildName, guildAlliance, inviterName)
        local allianceIconSize = 24
        if IsInGamepadPreferredMode() then
            allianceIconSize = 36
        end

        local formattedInviterName = ZO_FormatUserFacingDisplayName(inviterName)
        local guildNameAlliance = zo_iconTextFormat(ZO_GetPlatformAllianceSymbolIcon(guildAlliance), allianceIconSize, allianceIconSize, ZO_SELECTED_TEXT:Colorize(guildName))
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.GUILD_INVITE, nil, formattedInviterName, zo_strformat(SI_PLAYER_TO_PLAYER_INCOMING_GUILD_REQUEST, ZO_SELECTED_TEXT:Colorize(formattedInviterName), guildNameAlliance),
            function()
                AcceptGuildInvite(guildId)
            end,
            function()
                RejectGuildInvite(guildId)
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE.GUILD_INVITE, formattedInviterName)
            end)
        data.guildId = guildId
    end

    local function OnGuildInviteRemoved(eventCode, guildId)
        self:RemoveGuildInviteFromIncomingQueue(guildId)
    end

    local function OnAgentChatRequested()
        self:AddPromptToIncomingQueue(INTERACT_TYPE.AGENT_CHAT_REQUEST, nil, nil, GetString(SI_PLAYER_TO_PLAYER_INCOMING_AGENT_CHAT_REQUEST),
            function()
                AcceptAgentChat()
            end,
            function()
                DeclineAgentChat()
            end,
            function()
                self:RemoveFromIncomingQueue(INTERACT_TYPE.AGENT_CHAT_REQUEST)
            end)
    end

    local function OnAgentChatAccepted()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.AGENT_CHAT_REQUEST)
    end

    local function OnAgentChatDeclined()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.AGENT_CHAT_REQUEST)
    end

    local function OnCampaignQueueStateChanged(_, campaignId, isGroup, state)
        if state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
            local campaignQueueData = GetCampaignConfirmQueueData(campaignId, isGroup)

            local function AcceptCampaignEntry()
                ConfirmCampaignEntry(campaignId, isGroup, true)
            end

            local function DeclineCampaignEntry()
                ConfirmCampaignEntry(campaignId, isGroup, false)
            end

            local function DeferDecisionCallback()
                self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_QUEUE, campaignId)
            end

            --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
            local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.CAMPAIGN_QUEUE, campaignId, campaignId, nil, AcceptCampaignEntry, DeclineCampaignEntry, DeferDecisionCallback)

            promptData.messageFormat = campaignQueueData.messageFormat
            promptData.messageParams = campaignQueueData.messageParams
            promptData.expiresAtS = campaignQueueData.expiresAtS
            promptData.dialogTitle = campaignQueueData.dialogTitle
            promptData.expirationCallback = DeferDecisionCallback

            PlaySound(SOUNDS.CAMPAIGN_READY_CHECK)
        else
            --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
            self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_QUEUE, campaignId, campaignId)
        end
    end

    local function OnCampaignQueueJoined(_, campaignId, isMemberOfGroup, willBeLockedToAlliance)
        if not isMemberOfGroup then
            return
        end

        local showAllianceLockWarning = willBeLockedToAlliance ~= ALLIANCE_NONE
        local campaignQueueData = GetCampaignQueueJoinedData(campaignId, showAllianceLockWarning)

        local function AcceptCampaignEntry()
            if IsInGamepadPreferredMode() then
                SCENE_MANAGER:Show(GAMEPAD_AVA_ROOT_SCENE:GetName())
            else
                SCENE_MANAGER:Show(CAMPAIGN_BROWSER_SCENE:GetName())
            end
        end

        local function DeclineCampaignEntry()
            -- Dismiss prompt automatically
        end

        --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
        local NO_TARGET_LABEL = nil

        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.CAMPAIGN_QUEUE_JOINED, campaignId, campaignId, NO_TARGET_LABEL, AcceptCampaignEntry, DeclineCampaignEntry)

        promptData.messageFormat = campaignQueueData.messageFormat
        promptData.messageParams = campaignQueueData.messageParams
        promptData.dialogTitle = campaignQueueData.dialogTitle
        promptData.acceptText = GetString(SI_CAMPAIGN_QUEUE_JOINED_AS_GROUP_OPEN_CAMPAIGNS_BUTTON)
        promptData.declineText = GetString(SI_CAMPAIGN_QUEUE_JOINED_AS_GROUP_DISMISS_BUTTON)
    end

    local function OnCampaignQueueLeft(_, campaignId, group)
        --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
        self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_QUEUE, campaignId, campaignId)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_QUEUE_JOINED, campaignId, campaignId)
    end

    local function OnCampaignLockPending(_, campaignId, alliance, timeLeftS)
        local colorizedCampaignName = ZO_SELECTED_TEXT:Colorize(GetCampaignName(campaignId))
        local allianceString = ZO_SELECTED_TEXT:Colorize(ZO_CampaignBrowser_FormatPlatformAllianceIconAndName(alliance))

        local function AcceptCallback()
            MarkAllianceLockPendingNotificationSeen()
        end

        local function NotificationExpiredCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_LOCK_PENDING)
            MarkAllianceLockPendingNotificationSeen()
        end

        --Campaign is super hacky and uses the campaignId in the name field. It works because it only uses that field to do comparisons for removing the entry.
        local NO_TARGET_LABEL = nil
        local NO_DECLINE_CALLBACK = nil
        self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_LOCK_PENDING)
        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.CAMPAIGN_LOCK_PENDING, campaignId, campaignId, NO_TARGET_LABEL, AcceptCallback, NO_DECLINE_CALLBACK)

        promptData.messageFormat = GetString(SI_CAMPAIGN_ALLIANCE_LOCK_PENDING_MESSAGE)
        -- the time left is added automatically to messageParams in position <<3>>
        promptData.messageParams = {colorizedCampaignName, allianceString}
        promptData.dialogTitle = GetString(SI_CAMPAIGN_ALLIANCE_LOCK_PENDING_TITLE)
        promptData.expiresAtS = GetFrameTimeSeconds() + timeLeftS
        promptData.expirationCallback = NotificationExpiredCallback
        promptData.acceptText = GetString(SI_CAMPAIGN_ALLIANCE_LOCK_PENDING_DISMISS_BUTTON)
    end

    local function OnCampaignLockActivated(_, campaignId)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_LOCK_PENDING)
        MarkAllianceLockPendingNotificationSeen()
    end

    local function OnCurrentCampaignChanged(_)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.CAMPAIGN_LOCK_PENDING)
        MarkAllianceLockPendingNotificationSeen()
    end

    local function OnScriptedWorldEventInvite(eventCode, eventId, eventName, inviterName, questName)
        PlaySound(SOUNDS.SCRIPTED_WORLD_EVENT_INVITED)
        self:RemoveScriptedWorldEventFromIncomingQueue(eventId)
        local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.WORLD_EVENT_INVITE, eventId, eventId, nil,
            function()
                AcceptWorldEventInvite(eventId)
            end,
            function()
                DeclineWorldEventInvite(eventId)
            end)

        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE.WORLD_EVENT_INVITE)
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
        self:RemoveFromIncomingQueue(INTERACT_TYPE.CLAIM_LEVEL_UP_REWARDS)

        local pendingRewardLevel = GetPendingLevelUpRewardLevel()
        if pendingRewardLevel then
            local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.CLAIM_LEVEL_UP_REWARDS, nil, nil, zo_strformat(SI_LEVEL_UP_REWARDS_AVAILABLE_NOTIFICATION, pendingRewardLevel),
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
        self:RemoveAllFromIncomingQueue(INTERACT_TYPE.GIFT_RECEIVED)

        local giftList = GIFT_INVENTORY_MANAGER:GetGiftList(GIFT_STATE_RECEIVED)
        for _, gift in ipairs(giftList) do
            if not gift:HasBeenSeen() then
                local NO_CHARACTER_NAME = nil
                local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.GIFT_RECEIVED, NO_CHARACTER_NAME, gift:GetPlayerName(), zo_strformat(SI_PLAYER_TO_PLAYER_GIFT_RECEIVED, ZO_SELECTED_TEXT:Colorize(gift:GetUserFacingPlayerName())),
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

    local function CompareGroupFinderApplications(entry1, entry2)
        --Sort by oldest to newest
        return ZO_TableOrderingFunction(entry1, entry2, "GetEndTimeSeconds", GROUP_FINDER_APPLICATIONS_LIST_ENTRY_SORT_KEYS, ZO_SORT_ORDER_UP)
    end

    local function OnGroupFinderApplicationsUpdated()
        self:RemoveAllFromIncomingQueue(INTERACT_TYPE.GROUP_FINDER_APPLICATION)
        local applicationsData = GROUP_FINDER_APPLICATIONS_LIST_MANAGER:GetApplicationsData(CompareGroupFinderApplications)
        if #applicationsData > 0 then
            --Find the current oldest application and add that one to the queue
            local oldestApplication = applicationsData[1]

            local function AcceptCallback()
                RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_APPROVE, oldestApplication:GetCharacterId())
            end

            local function DeclineCallback()
                RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_REJECT, oldestApplication:GetCharacterId())
            end

            PlaySound(SOUNDS.GROUP_FINDER_APPLICATION_NOTIFICATION)

            local characterName = oldestApplication:GetCharacterName()
            local displayName = oldestApplication:GetDisplayName()

            local NO_TARGET_LABEL = nil
            local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.GROUP_FINDER_APPLICATION, characterName, displayName, NO_TARGET_LABEL, AcceptCallback, DeclineCallback)

            local championPoints = oldestApplication:GetChampionPoints()
            data.messageFormat = championPoints > 0 and SI_PLAYER_TO_PLAYER_INCOMING_GROUP_FINDER_APPLICATION_CHAMPION or SI_PLAYER_TO_PLAYER_INCOMING_GROUP_FINDER_APPLICATION

            local userFacingName = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)

            local role = oldestApplication:GetRole()
            local roleText = GetString("SI_LFGROLE", role)
            local roleIconFormat = zo_iconFormat(ZO_GetRoleIcon(role), "100%", "100%")

            local ICON_SIZE = 24
            local level = oldestApplication:GetLevel()
            local levelText = ZO_GetLevelOrChampionPointsString(level, championPoints, ICON_SIZE)
            --Use a special string for narrating the level text, so it narrates the champion icon properly
            local levelTextNarration = ZO_GetLevelOrChampionPointsNarrationString(level, championPoints)
            data.messageParams = { userFacingName, levelText, roleIconFormat, roleText }

            --The return value of this function will be narrated instead of the normal target text
            data.targetTextNarrationFunction = function(incomingEntry)
                return zo_strformat(incomingEntry.messageFormat, userFacingName, levelTextNarration, roleIconFormat, roleText)
            end
        end
    end

    local function OnPromotionalEventRewardsUpdated()
        if PROMOTIONAL_EVENT_MANAGER:IsAnyRewardClaimable() then
            if not self:ExistsInQueue(INTERACT_TYPE.PROMOTIONAL_EVENT_REWARD) then
                PlaySound(SOUNDS.PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT)

                local claimRewardDescriptionText = GetString(SI_PLAYER_TO_PLAYER_PROMOTIONAL_EVENT_CLAIMABLE_REWARD)

                local function AcceptClaimReward()
                    local SCROLL_TO_FIRST_CLAIMABLE_REWARD = true
                    PROMOTIONAL_EVENT_MANAGER:ShowPromotionalEventScene(SCROLL_TO_FIRST_CLAIMABLE_REWARD)
                end
                local data = self:AddPromptToIncomingQueue(INTERACT_TYPE.PROMOTIONAL_EVENT_REWARD, nil, nil, claimRewardDescriptionText, AcceptClaimReward)
                data.dontRemoveOnAccept = true
                data.acceptText = GetString(SI_PLAYER_TO_PLAYER_PROMOTIONAL_EVENT_CLAIM_PROMPT)
                TriggerTutorial(TUTORIAL_TRIGGER_PROMOTIONAL_EVENTS_HUD_REWARD_TO_CLAIM)
            end
        else
            self:RemoveFromIncomingQueue(INTERACT_TYPE.PROMOTIONAL_EVENT_REWARD)
        end
    end

    self.control:RegisterForEvent(EVENT_DUEL_INVITE_RECEIVED, OnDuelInviteReceived)
    self.control:RegisterForEvent(EVENT_DUEL_INVITE_REMOVED, OnDuelInviteRemoved)
    self.control:RegisterForEvent(EVENT_TRIBUTE_INVITE_RECEIVED, OnTributeInviteReceived)
    self.control:RegisterForEvent(EVENT_TRIBUTE_INVITE_REMOVED, OnTributeInviteRemoved)
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
    self.control:RegisterForEvent(EVENT_CAMPAIGN_QUEUE_JOINED, OnCampaignQueueJoined)
    self.control:RegisterForEvent(EVENT_CAMPAIGN_QUEUE_LEFT, OnCampaignQueueLeft)
    self.control:RegisterForEvent(EVENT_CAMPAIGN_ALLIANCE_LOCK_PENDING, OnCampaignLockPending)
    self.control:RegisterForEvent(EVENT_CAMPAIGN_ALLIANCE_LOCK_ACTIVATED, OnCampaignLockActivated)
    self.control:RegisterForEvent(EVENT_CURRENT_CAMPAIGN_CHANGED, OnCurrentCampaignChanged)
    self.control:RegisterForEvent(EVENT_SCRIPTED_WORLD_EVENT_INVITE, OnScriptedWorldEventInvite)
    self.control:RegisterForEvent(EVENT_SCRIPTED_WORLD_EVENT_INVITE_REMOVED, OnScriptedWorldEventInviteRemoved)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_READY_CHECK_UPDATED, function(event, ...) self:OnGroupingToolsReadyCheckUpdated(...) end)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_READY_CHECK_CANCELLED, function(event, ...) self:OnGroupingToolsReadyCheckCancelled(...) end)
    self.control:RegisterForEvent(EVENT_LEVEL_UP_REWARD_UPDATED, OnLevelUpRewardUpdated)
    self.control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_PROGRESS_UPDATED, OnPromotionalEventRewardsUpdated)

    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftListsChanged", OnGiftsUpdated)
    GROUP_FINDER_APPLICATIONS_LIST_MANAGER:RegisterCallback("ApplicationsListUpdated", OnGroupFinderApplicationsUpdated)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", OnPromotionalEventRewardsUpdated)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", OnPromotionalEventRewardsUpdated)

    --Find member replacement prompt on a member leaving
    local function OnGroupingToolsFindReplacementNotificationNew()
        local activityId = GetActivityFindReplacementNotificationInfo()

        local function DeferDecisionCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_FIND_REPLACEMENT)
        end

        local dungeonName = GetActivityName(activityId)

        PlaySound(SOUNDS.LFG_FIND_REPLACEMENT)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_FIND_REPLACEMENT)

        local text = zo_strformat(SI_LFG_FIND_REPLACEMENT_TEXT, dungeonName)
        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.LFG_FIND_REPLACEMENT, nil, nil, text, AcceptActivityFindReplacementNotification, DeclineActivityFindReplacementNotification, DeferDecisionCallback)
        promptData.acceptText = GetString(SI_LFG_FIND_REPLACEMENT_ACCEPT)
    end
    local function OnGroupingToolsFindReplacementNotificationRemoved()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_FIND_REPLACEMENT)
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
            self:RemoveFromIncomingQueue(INTERACT_TYPE.GROUP_ELECTION)
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
        self:RemoveFromIncomingQueue(INTERACT_TYPE.GROUP_ELECTION)

        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.GROUP_ELECTION, nil, nil, nil, AcceptCallback, DeclineCallback, DeferDecisionCallback)
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
        self:RemoveFromIncomingQueue(INTERACT_TYPE.GROUP_ELECTION)
    end
    self.control:RegisterForEvent(EVENT_GROUP_ELECTION_NOTIFICATION_ADDED, function(event, ...) OnGroupElectionNotificationAdded(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_ELECTION_NOTIFICATION_REMOVED, function(event, ...) OnGroupElectionNotificationRemoved(...) end)

    local function OnTrackedZoneStoryActivityCompleted(zoneId, zoneCompletionType, activityId)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRACK_ZONE_STORY)

        local numCompletedActivities, totalActivities, _, _, progressText = ZO_ZoneStories_Manager.GetActivityCompletionProgressValuesAndText(zoneId, zoneCompletionType)

        if numCompletedActivities == totalActivities and not CanZoneStoryContinueTrackingActivities(zoneId) then
            return
        end

        local function AcceptCallback()
            local SET_AUTO_MAP_NAVIGATION_TARGET = true
            local COMPLETION_TYPE_ALL = nil
            TrackNextActivityForZoneStory(zoneId, COMPLETION_TYPE_ALL, SET_AUTO_MAP_NAVIGATION_TARGET)
        end

        local function DeclineCallback()
            self:RemoveFromIncomingQueue(INTERACT_TYPE.TRACK_ZONE_STORY)
        end

        PlaySound(SOUNDS.NEW_TIMED_NOTIFICATION)

        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.TRACK_ZONE_STORY, nil, nil, nil, AcceptCallback, DeclineCallback)
        promptData.acceptText = GetString(SI_ZONE_STORY_CONTINUE_EXPLORING_ACTION)
        promptData.declineText = GetString(SI_DIALOG_DISMISS)

        promptData.messageFormat = GetString("SI_ZONECOMPLETIONTYPE_PROGRESSDESCRIPTION", zoneCompletionType)
        promptData.messageParams = { ZO_SELECTED_TEXT:Colorize(progressText), ZO_SELECTED_TEXT:Colorize(GetZoneNameById(zoneId)) }
        promptData.dialogTitle = GetString("SI_ZONE_STORY_INFO_HEADER")
        promptData.uniqueSounds =
        {
            accept = SOUNDS.ZONE_STORIES_TRACK_ACTIVITY,
        }
    end
    self.control:RegisterForEvent(EVENT_TRACKED_ZONE_STORY_ACTIVITY_COMPLETED, function(event, ...) OnTrackedZoneStoryActivityCompleted(...) end)

    local function OnZoneStoryActivityTracked()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRACK_ZONE_STORY)
    end
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKED, function(event, ...) OnZoneStoryActivityTracked(...) end)

    local pendingJumpToGroupLeaderPrompt = nil

    local function OnTravelToLeaderPromptReceived()
        -- LFG groups use their own jump notification
        if IsInLFGGroup() then
            return
        end

        -- The location of the group leader may not be available immediately
        if pendingJumpToGroupLeaderPrompt then
            local groupLeaderUnitTag = GetGroupLeaderUnitTag()
            local groupLeaderZoneName = GetUnitZone(groupLeaderUnitTag)
            if groupLeaderZoneName ~= "" then
                pendingJumpToGroupLeaderPrompt = nil
                if IsGroupMemberInRemoteRegion(groupLeaderUnitTag) then
                    local canJump, result = CanJumpToGroupMember(groupLeaderUnitTag)
                    if canJump then
                        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRAVEL_TO_LEADER)

                        local function AcceptCallback()
                            local leaderUnitTag = GetGroupLeaderUnitTag()
                            JumpToGroupMember(GetUnitName(leaderUnitTag))
                            self:RemoveFromIncomingQueue(INTERACT_TYPE.TRAVEL_TO_LEADER)
                        end

                        local function DeclineCallback()
                            self:RemoveFromIncomingQueue(INTERACT_TYPE.TRAVEL_TO_LEADER)
                        end

                        local promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.TRAVEL_TO_LEADER, nil, nil, nil, AcceptCallback, DeclineCallback)
                        promptData.acceptText = GetString(SI_DIALOG_ACCEPT)
                        promptData.declineText = GetString(SI_DIALOG_DECLINE)

                        promptData.messageFormat = GetString(GetUnitZone("player") == groupLeaderZoneName and SI_JUMP_TO_GROUP_LEADER_OCCURANCE_PROMPT or SI_JUMP_TO_GROUP_LEADER_WORLD_PROMPT)
                        promptData.messageParams = { groupLeaderZoneName }
                        promptData.dialogTitle = GetString("SI_JUMP_TO_GROUP_LEADER_TITLE")
                    elseif result == JUMP_TO_PLAYER_RESULT_ZONE_COLLECTIBLE_LOCKED then
                        local zoneIndex = GetUnitZoneIndex(groupLeaderUnitTag)
                        local collectibleId = GetCollectibleIdForZone(zoneIndex)
                        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                        local message = zo_strformat(SI_COLLECTIBLE_LOCKED_FAILURE_CAUSED_BY_JUMP_TO_GROUP_LEADER, groupLeaderZoneName)
                        local marketOperation = MARKET_OPEN_OPERATION_DLC_FAILURE_TELEPORT_TO_GROUP
                        ZO_Dialogs_ShowCollectibleRequirementFailedPlatformDialog(collectibleData, message, marketOperation)
                    end
                end
            end
        end
    end

    local function OnUnitCreated(unitTag)
        if ZO_Group_IsGroupUnitTag(unitTag) then
            OnTravelToLeaderPromptReceived()
        end
    end
        local function OnZoneUpdate(unitTag, newZone)
        if ZO_Group_IsGroupUnitTag(unitTag) then
            OnTravelToLeaderPromptReceived()
        end
    end
    local function OnGroupMemberJoined(characterName, displayName, isLocalPlayer)
        if isLocalPlayer then
            local groupLeaderUnitTag = GetGroupLeaderUnitTag()
            if not AreUnitsEqual(groupLeaderUnitTag, "player") then
                pendingJumpToGroupLeaderPrompt = true
                OnTravelToLeaderPromptReceived()
            end
        end
    end
    local function OnPlayerActivateOrLeaderUpdate()
        if pendingJumpToGroupLeaderPrompt then
            OnTravelToLeaderPromptReceived()
        end
    end
    local function OnGroupMemberLeft(eventCode, characterName, reason, isLocalPlayer, amLeader)
        if isLocalPlayer then
            self:RemoveFromIncomingQueue(INTERACT_TYPE.TRAVEL_TO_LEADER)
        end
    end
    self.control:RegisterForEvent(EVENT_UNIT_CREATED, function(event, ...) OnUnitCreated(...) end)
    self.control:RegisterForEvent(EVENT_ZONE_UPDATE, function(event, ...) OnZoneUpdate(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, function(event, ...) OnGroupMemberJoined(...) end)
    self.control:RegisterForEvent(EVENT_LEADER_UPDATE, function(event, ...) OnGroupMemberJoined(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, function(event, ...) OnGroupMemberLeft(...) end)

    local function OnPlayerActivated()
        local duelState, duelPartnerCharacterName, duelPartnerDisplayName, timeRemainingMS = GetDuelInfo()
        if duelState == DUEL_STATE_INVITE_CONSIDERING then
            OnDuelInviteReceived(nil, duelPartnerCharacterName, duelPartnerDisplayName, timeRemainingMS)
        end
        
        local tributeInviteState, tributePartnerCharacterName, tributePartnerDisplayName, tributeInviteTimeRemainingMS = GetTributeInviteInfo()
        if tributeInviteState == TRIBUTE_INVITE_STATE_INVITE_CONSIDERING then
            OnTributeInviteReceived(nil, tributePartnerCharacterName, tributePartnerDisplayName, tributeInviteTimeRemainingMS)
        end

        local inviterCharaterName, _, inviterDisplayName = GetGroupInviteInfo()

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

        if HasAllianceLockPendingNotification() then
            local NO_EVENT_ID = nil
            OnCampaignLockPending(NO_EVENT_ID, GetAllianceLockPendingNotificationInfo())
        end

        OnGiftsUpdated()
        OnPlayerActivateOrLeaderUpdate()
        OnPromotionalEventRewardsUpdated()
    end

    local function OnPlayerDeactivated()
        self:RemoveFromIncomingQueue(INTERACT_TYPE.DUEL_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRIBUTE_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.GROUP_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRADE_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.RITUAL_OF_MARA)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.QUEST_SHARE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.WORLD_EVENT_INVITE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_READY_CHECK)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_FIND_REPLACEMENT)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.QUEST_SHARE)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.TRAVEL_TO_LEADER)
        self:RemoveFromIncomingQueue(INTERACT_TYPE.PROMOTIONAL_EVENT_REWARD)
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
        local CLEAR_SELECTION = true
        self:StopInteraction(CLEAR_SELECTION)
    end)

    self.control:RegisterForEvent(EVENT_GUI_UNLOADING, function()
        local CLEAR_SELECTION = true
        self:StopInteraction(CLEAR_SELECTION)
    end)

    local function OnLogoutDeferred()
        -- If we're logging out and we have a time sensistive decision, just opt out. Not only does this
        -- make sure that any other players waiting on a response get it, but it eliminates any dialogs in the way (ESO-635856)
        for i, incomingEntry in ipairs(self.incomingQueue) do
            if TIMED_PROMPTS[incomingEntry.incomingType] then
                if incomingEntry.declineCallback then
                    incomingEntry.declineCallback()
                elseif incomingEntry.deferDecisionCallback then
                    incomingEntry.deferDecisionCallback()
                end
            end
        end
    end

    self.control:RegisterForEvent(EVENT_LOGOUT_DEFERRED, OnLogoutDeferred)
end

function ZO_PlayerToPlayer:SetTopLevelHidden(hidden)
    local isTopLevelHidden = self.control:IsHidden()
    if isTopLevelHidden ~= hidden then
        if not self:IsHidden() then
            if hidden then
                --Clear out any in progress HUD narration when hiding
                ClearNarrationQueue(NARRATION_TYPE_HUD)
            else
                --Re-narrate the prompt when showing
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("PlayerToPlayerPrompt")
            end
        end
        self.control:SetHidden(hidden)
    end
end

function ZO_PlayerToPlayer:SetHidden(hidden)
    SHARED_INFORMATION_AREA:SetHidden(self.container, hidden)
end

function ZO_PlayerToPlayer:IsHidden()
    return SHARED_INFORMATION_AREA:IsHidden(self.container)
end

local INCOMING_MESSAGE_TEXT = {
    [INTERACT_TYPE.GROUP_INVITE] = GetString(SI_NOTIFICATION_GROUP_INVITE),
    [INTERACT_TYPE.QUEST_SHARE] = GetString(SI_NOTIFICATION_SHARE_QUEST_INVITE),
    [INTERACT_TYPE.FRIEND_REQUEST] = GetString(SI_NOTIFICATION_FRIEND_INVITE),
    [INTERACT_TYPE.GUILD_INVITE] = GetString(SI_NOTIFICATION_GUILD_INVITE)
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

    menu:Clear()
    if self:ShouldShowDeferDecision(data) then
        local deferDecisionText = data.deferDecisionText or GetString(SI_GAMEPAD_NOTIFICATIONS_DEFER_OPTION)
        menu:AddEntry( deferDecisionText,
                        "EsoUI/Art/HUD/Gamepad/gp_radialIcon_defer_down.dds",
                        "EsoUI/Art/HUD/Gamepad/gp_radialIcon_defer_down.dds",
                        function()
                            NotificationDeferred(data)
                        end)
    end

    if self:ShouldShowAccept(data) then
        local acceptText = data.acceptText or GetString(SI_GAMEPAD_NOTIFICATIONS_ACCEPT_OPTION)
        menu:AddEntry( acceptText,
                        "EsoUI/Art/HUD/Gamepad/gp_radialIcon_accept_down.dds",
                        "EsoUI/Art/HUD/Gamepad/gp_radialIcon_accept_down.dds",
                        function()
                            NotificationAccepted(data)
                        end)
    end

    if self:ShouldShowDecline(data) then
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
    self.isLastRadialMenuGamepad = true
    --Narrate the wheel when first showing it
    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("PlayerToPlayerWheel", NARRATE_HEADER)
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
            -- ESO-640756: with the exception of Ready Check since it has a confirmation dialog that pauses all other dialogs until resolved
            if rightData.incomingType == INTERACT_TYPE.LFG_READY_CHECK then
                return 1
            else
                return -1
            end
        end
    end

    function ZO_PlayerToPlayer:AddIncomingEntry(incomingType, targetLabel, displayName, characterName, dontRemoveOnDecline)
        local formattedInviterName = nil
        if displayName and characterName then
            -- displayName and characterName don't always actually correspond with with the display name/character name of another player, but if both are defined they should.
            -- in that case, inviterName will be defined and should be used to describe the player that caused the event: eg. if we're invited to a group it should represent the inviter.
            formattedInviterName = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
        end

        local data =
        {
            incomingType = incomingType,
            targetLabel = targetLabel,
            inviterName = formattedInviterName,
            pendingResponse = true,
            displayName = displayName,
            characterName = characterName,
            dontRemoveOnDecline = dontRemoveOnDecline,
        }
        zo_binaryinsert(data, data, self.incomingQueue, IncomingEntryComparator)
        return data
    end
end

function ZO_PlayerToPlayer:AddPromptToIncomingQueue(interactType, characterName, displayName, targetLabel, acceptCallback, declineCallback, deferDecisionCallback, dontRemoveOnDecline)
    local data = self:AddIncomingEntry(interactType, targetLabel, displayName, characterName, dontRemoveOnDecline)
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
                self:RemoveEntryFromIncomingQueueTable(i)
                break
            end
        end
    end

    function ZO_PlayerToPlayer:RemoveAllFromIncomingQueue(incomingType, characterName, displayName)
        for i, incomingEntry in ipairs(self.incomingQueue) do
            if DoesDataMatch(incomingEntry, incomingType, characterName, displayName) then
                self:RemoveEntryFromIncomingQueueTable(i)
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
        if incomingEntry.incomingType == INTERACT_TYPE.GUILD_INVITE and incomingEntry.guildId == guildId then
            self:RemoveEntryFromIncomingQueueTable(i)
            break
        end
    end
end

function ZO_PlayerToPlayer:RemoveQuestShareFromIncomingQueue(questId)
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.incomingType == INTERACT_TYPE.QUEST_SHARE and incomingEntry.questId == questId then
            self:RemoveEntryFromIncomingQueueTable(i)
            break
        end
    end
end

function ZO_PlayerToPlayer:RemoveScriptedWorldEventFromIncomingQueue(eventId, questName)
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.incomingType == INTERACT_TYPE.WORLD_EVENT_INVITE and (incomingEntry.eventId == eventId or incomingEntry.questName == questName) then
            self:RemoveEntryFromIncomingQueueTable(i)
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

        local promptData = self:GetFromIncomingQueue(INTERACT_TYPE.LFG_READY_CHECK)
        if not promptData then
            local function DeferDecisionCallback()
                self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_READY_CHECK)
            end

            local messageFormat, messageParams
            local activityTypeText = GetString("SI_LFGACTIVITY", activityType)
            local generalActivityText = ZO_ACTIVITY_FINDER_GENERALIZED_ACTIVITY_DESCRIPTORS[activityType]
            if role == LFG_ROLE_INVALID then
                messageFormat = SI_LFG_READY_CHECK_NO_ROLE_TEXT
                messageParams = { activityTypeText, generalActivityText }
            else
                local roleIconPath = ZO_GetRoleIcon(role)
                local roleIconFormat = zo_iconFormat(roleIconPath, "100%", "100%")

                messageFormat = SI_LFG_READY_CHECK_TEXT
                messageParams = { activityTypeText, generalActivityText, roleIconFormat, GetString("SI_LFGROLE", role) }
            end

            local function DeclineReadyCheckConfirmation()
                local readyCheckData = self:GetFromIncomingQueue(INTERACT_TYPE.LFG_READY_CHECK)
                if readyCheckData and readyCheckData.dontRemoveOnDecline then
                    ZO_Dialogs_ShowPlatformDialog("LFG_DECLINE_READY_CHECK_CONFIRMATION")
                end
            end

            local DONT_REMOVE_ON_DECLINE = true
            promptData = self:AddPromptToIncomingQueue(INTERACT_TYPE.LFG_READY_CHECK, nil, nil, nil, AcceptLFGReadyCheckNotification, DeclineReadyCheckConfirmation, DeferDecisionCallback, DONT_REMOVE_ON_DECLINE)
            promptData.acceptText = GetString(SI_LFG_READY_CHECK_ACCEPT)
            promptData.expiresAtS = GetFrameTimeSeconds() + timeRemainingSeconds
            promptData.messageFormat = messageFormat
            promptData.messageParams = messageParams
            promptData.expirationCallback = DeferDecisionCallback
            promptData.dialogTitle = GetString("SI_NOTIFICATIONTYPE", NOTIFICATION_TYPE_LFG)

            PlaySound(SOUNDS.LFG_READY_CHECK)
        else
            promptData.dontRemoveOnDecline = true
        end
    else
        self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_READY_CHECK)
    end
end

function ZO_PlayerToPlayer:OnGroupingToolsReadyCheckCancelled()
    self:RemoveFromIncomingQueue(INTERACT_TYPE.LFG_READY_CHECK)
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
    if self.showingResponsePrompt then
        local incomingEntryToRespondTo = self.incomingQueue[1]
        if ShouldUseGamepadResponseMenu(incomingEntryToRespondTo) then
            --if there is only one option just accept it instead of showing a radial with one option
            if self:ShouldShowExactlyOneOption(incomingEntryToRespondTo) then
                if self:ShouldShowAccept(incomingEntryToRespondTo) then
                    NotificationAccepted(incomingEntryToRespondTo)
                elseif self:ShouldShowDecline(incomingEntryToRespondTo) then
                    NotificationDeclined(incomingEntryToRespondTo)
                elseif self:ShouldShowDeferDecision(incomingEntryToRespondTo) then
                    NotificationDeferred(incomingEntryToRespondTo)
                end
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
        -- most interactions require a target, but on gamepad, response prompts don't. Response prompts on keyboard do.
        local doesInteractionHaveTarget = self:HasTarget() or (IsInGamepadPreferredMode() and self.showingResponsePrompt)

        if not doesInteractionHaveTarget then
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

function ZO_PlayerToPlayer:StopInteraction(clearSelection)
    self.targetLabel:SetHidden(false)

    ZO_ClearTable(self.hotkeyBeginHolds)

    if self.isInteracting then
        self.isInteracting = false
        RETICLE:RequestHidden(false)
        LockCameraRotation(false)

        CancelSoulGemResurrection()
        self.lastFailedPromptTime = GetFrameTimeMilliseconds() - self.msToDelayToShowPrompt

        if self.showingPlayerInteractMenu then
            self.showingPlayerInteractMenu = false
            local radialMenu = self:GetLastActiveRadialMenu()
            if radialMenu then
                if clearSelection then
                    radialMenu:ClearSelection()
                end
                radialMenu:SelectCurrentEntry()
            end

            if not self:IsHidden() then
                --Re-narrate the prompt when closing the wheel
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("PlayerToPlayerPrompt")
            elseif self.isLastRadialMenuGamepad then
                --Clear out any in progress HUD narration when exiting the wheel
                ClearNarrationQueue(NARRATION_TYPE_HUD)
            end
        end
    elseif self.showingGamepadResponseMenu then
        self.showingGamepadResponseMenu = false
        RETICLE:RequestHidden(false)
        LockCameraRotation(false)

        local radialMenu = self:GetLastActiveRadialMenu()
        if radialMenu then
            if clearSelection then
                radialMenu:ClearSelection()
            end
            radialMenu:SelectCurrentEntry()
        end

        if not self:IsHidden() then
            --Re-narrate the prompt when closing the wheel
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("PlayerToPlayerPrompt")
        elseif self.isLastRadialMenuGamepad then
            --Clear out any in progress HUD narration when exiting the wheel
            ClearNarrationQueue(NARRATION_TYPE_HUD)
        end
    end

    if self.showingResponsePrompt then
        self.showingResponsePrompt = false
    end
end

function ZO_PlayerToPlayer:HandleUpAction()
    if ZO_AreTogglableWheelsEnabled() then
        --This also handles behaviors just as soul gem resurrection, so we need to make sure we behave normally if we aren't using any wheels
        if not (self.showingPlayerInteractMenu or self.showingGamepadResponseMenu) then
            self:StopInteraction()
        end
    else
        --Just behave normally if the togglable wheels are not enabled
        self:StopInteraction()
    end
end

function ZO_PlayerToPlayer:HandleHotkeyDownAction(ordinalIndex)
    --First check to see if there's a radial menu currently up
    if self.showingPlayerInteractMenu or self.showingGamepadResponseMenu then
        local radialMenu = self:GetLastActiveRadialMenu()
        if radialMenu then
            --Select the corresponding entry and store off when we began the hold
            if radialMenu:SelectOrdinalEntry(ordinalIndex) then
                self.hotkeyBeginHolds[ordinalIndex] = GetFrameTimeMilliseconds()
                return true
            end
        end
    end

    return false
end

do
    local TIME_TO_HOLD_KEY_MS = 250
    function ZO_PlayerToPlayer:HandleHotkeyUpAction(ordinalIndex)
        local beginHoldMs = self.hotkeyBeginHolds[ordinalIndex]
        if beginHoldMs then
            self.hotkeyBeginHolds[ordinalIndex] = nil
            --If we were not holding the hotkey long enough to leave the wheel open, we need to close it
            if GetFrameTimeMilliseconds() < beginHoldMs + TIME_TO_HOLD_KEY_MS then
                local radialMenu = self:GetLastActiveRadialMenu()
                --Re-select the correct ordinal entry here in case it happened to change after we initially pressed the keybind
                if radialMenu and radialMenu:SelectOrdinalEntry(ordinalIndex) then
                    self:StopInteraction()
                    return true
                end
            end
        end

        return false
    end
end

function ZO_PlayerToPlayer:ShouldShowAccept(incomingEntry)
    return incomingEntry.acceptCallback ~= nil
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

function ZO_PlayerToPlayer:ShouldShowDecline(incomingEntry)
    return incomingEntry.declineCallback ~= nil
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

function ZO_PlayerToPlayer:ShouldShowDeferDecision(incomingEntry)
    return incomingEntry.deferDecisionCallback ~= nil
end

do
    local function DoesOnlyOneExist(...)
        local oneExists = false
        for i = 1, select('#', ...) do
            local value = select(i, ...)
            if value then
                if oneExists then
                    return false
                else
                    oneExists = true
                end
            end
        end
        return oneExists
    end

    function ZO_PlayerToPlayer:ShouldShowExactlyOneOption(incomingEntry)
        return DoesOnlyOneExist(incomingEntry.acceptCallback, incomingEntry.declineCallback, incomingEntry.deferDecisionCallback)
    end
end

function ZO_PlayerToPlayer:OnPromptAccepted()
    if self.showingResponsePrompt then
        local incomingEntryToRespondTo = self.incomingQueue[1]
        if not incomingEntryToRespondTo.dontRemoveOnAccept then
            self:RemoveEntryFromIncomingQueueTable(1)
        end
        NotificationAccepted(incomingEntryToRespondTo)
    end
end

function ZO_PlayerToPlayer:OnPromptDeclined()
    if self.showingResponsePrompt then
        local incomingEntryToRespondTo = self.incomingQueue[1]
        if not incomingEntryToRespondTo.dontRemoveOnDecline then
            self:RemoveEntryFromIncomingQueueTable(1)
        end
        NotificationDeclined(incomingEntryToRespondTo)
    end
end

function ZO_PlayerToPlayer:RemoveEntryFromIncomingQueueTable(index)
    local incomingEntry = table.remove(self.incomingQueue, index)
    if TIMED_PROMPTS[incomingEntry.incomingType] then
        ZO_Dialogs_ReleaseAllDialogsOfName("PTP_TIMED_RESPONSE_PROMPT", function(dialogData) return dialogData == incomingEntry end)
        CancelTaskbarWindowFlash("PTP_TIMED_RESPONSE_PROMPT")
    elseif FLASHING_PROMPTS[incomingEntry.incomingType] then
        CancelTaskbarWindowFlash("PTP_FLASHING_PROMPT")
    end

    if index == 1 and (self.showingResponsePrompt or self.showingGamepadResponseMenu) then
        self:StopInteraction()
    end

    return incomingEntry
end

function ZO_PlayerToPlayer:SetTargetIdentification(unitTag)
    self.currentTargetCharacterNameRaw = GetRawUnitName(unitTag)
    self.currentTargetCharacterName = zo_strformat(SI_PLAYER_TO_PLAYER_TARGET, self.currentTargetCharacterNameRaw)
    self.currentTargetDisplayName = GetUnitDisplayName(unitTag)
end

local RAID_LIFE_ICON_MARKUP = "|t32:32:EsoUI/Art/Trials/VitalityDepletion.dds|t"
function ZO_PlayerToPlayer:TryShowingResurrectLabel(unitTag)
    local wasResurrectInfoHidden = self.pendingResurrectInfo:IsHidden()
    if IsUnitResurrectableByPlayer(unitTag) then
        self:SetTargetIdentification(unitTag)

        self.resurrectable = true

        self.targetLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        if unitTag == P2C_UNIT_TAG then
            self.targetText = GetUnitName(unitTag)
            self.targetLabel:SetText(self.targetText)
        else
            self.targetText = ZO_GetPrimaryPlayerNameWithSecondary(self.currentTargetDisplayName, self.currentTargetCharacterName)
            self.targetLabel:SetText(self.targetText)
        end
        self.targetTextNarration = self.targetText

        self.isBeingResurrected = IsUnitBeingResurrected(unitTag)
        self.hasResurrectPending = DoesUnitHaveResurrectPending(unitTag)
        if self.isBeingResurrected or self.hasResurrectPending then
            if wasResurrectInfoHidden then
                self.pendingResurrectInfoChanged = true
            end

            self.pendingResurrectInfo:SetHidden(false)
            local pendingResurrectText
            if self.isBeingResurrected then
                pendingResurrectText = GetString(SI_PLAYER_TO_PLAYER_RESURRECT_BEING_RESURRECTED)
            else
                pendingResurrectText = GetString(SI_PLAYER_TO_PLAYER_RESURRECT_HAS_RESURRECT_PENDING)
            end

            if pendingResurrectText ~= self.pendingResurrectText then 
                self.pendingResurrectInfoChanged = true
                self.pendingResurrectText = pendingResurrectText
                self.pendingResurrectInfo:SetText(self.pendingResurrectText)
            end
        else
            self.pendingResurrectInfo:SetHidden(true)
            self.actionKeybindButton:SetHidden(false)

            if not wasResurrectInfoHidden then
                self.pendingResurrectInfoChanged = true
            end

            local targetLevel = GetUnitEffectiveLevel(unitTag)
            local _, _, stackCount = GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, targetLevel)
            local soulGemSuccess, coloredFilledText, coloredSoulGemIconMarkup = ZO_Death_GetResurrectSoulGemText(targetLevel)

            self.hasRequiredSoulGem = stackCount > 0
            self.failedRaidRevives = IsPlayerInRaid() and not ZO_Death_IsRaidReviveAllowed()
            self.actionKeybindButton:SetEnabled(self.hasRequiredSoulGem and not self.failedRaidRevives)

            local finalText
            local narrationText
            if ZO_Death_DoesReviveCostRaidLife() then
                finalText = zo_strformat(soulGemSuccess and SI_PLAYER_TO_PLAYER_RESURRECT_GEM_LIFE or SI_PLAYER_TO_PLAYER_RESURRECT_GEM_LIFE_FAILED, coloredFilledText, coloredSoulGemIconMarkup, RAID_LIFE_ICON_MARKUP)
                narrationText = GetString(SI_PLAYER_TO_PLAYER_RESURRECT_GEM_LIFE_NARRATION)
            else
                finalText = zo_strformat(soulGemSuccess and SI_PLAYER_TO_PLAYER_RESURRECT_GEM or SI_PLAYER_TO_PLAYER_RESURRECT_GEM_FAILED, coloredFilledText, coloredSoulGemIconMarkup)
                narrationText = GetString(SI_PLAYER_TO_PLAYER_RESURRECT_GEM_NARRATION)
            end

            self.actionKeybindButton:SetText(finalText, narrationText)
        end

        return true
    end

    if not wasResurrectInfoHidden then
        self.pendingResurrectInfoChanged = true
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
        self:SetTargetIdentification(P2P_UNIT_TAG)

        local isIgnored = IsUnitIgnored(P2P_UNIT_TAG)
        local interactLabel = isIgnored and GetPlatformIgnoredString() or SI_PLAYER_TO_PLAYER_TARGET

        self.actionKeybindButton:SetHidden(false)
        self.targetLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        self.targetText = zo_strformat(interactLabel, ZO_GetPrimaryPlayerNameWithSecondary(self.currentTargetDisplayName, self.currentTargetCharacterName))
        self.targetTextNarration = self.targetText
        self.targetLabel:SetText(self.targetText)
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
            self.targetText = displayText
            --If a target text narration function was defined, use the result for the target text narration, otherwise just set it to the regular target text
            if incomingEntry.targetTextNarrationFunction then
                self.targetTextNarration = incomingEntry.targetTextNarrationFunction(incomingEntry)
            else
                self.targetTextNarration = self.targetText
            end
            self.targetLabel:SetText(self.targetText)
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
                    local responseString = GetString(SI_GAMEPAD_PLAYER_TO_PLAYER_ACTION_RESPOND)
                    if self:ShouldShowExactlyOneOption(incomingEntry) then
                        if self:ShouldShowAccept(incomingEntry) then
                            responseString = incomingEntry.acceptText
                        elseif self:ShouldShowDecline(incomingEntry) then
                            responseString = incomingEntry.declineText
                        elseif self:ShouldShowDeferDecision(incomingEntry) then
                            responseString = incomingEntry.deferDecisionText
                        end
                    end

                    self:ShowResponseActionKeybind(responseString)
                end
            else
                if self:ShouldShowAccept(incomingEntry) then
                    local acceptText = incomingEntry.acceptText or GetString(SI_DIALOG_ACCEPT)
                    self.promptKeybindButton1:SetText(acceptText)
                    self.promptKeybindButton1.shouldHide = false
                end
                if self:ShouldShowDecline(incomingEntry) then
                    local declineText = incomingEntry.declineText or GetString(SI_DIALOG_DECLINE)
                    self.promptKeybindButton2:SetText(declineText)
                    self.promptKeybindButton2.shouldHide = false
                end
                self.shouldShowNotificationKeybindLayer = true
            end

            self.showingResponsePrompt = true
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

function ZO_PlayerToPlayer:IsReticleTargetCompanionInteractable()
    return DoesUnitExist(P2C_UNIT_TAG)
       and IsUnitOnline(P2C_UNIT_TAG)
       and AreUnitsCurrentlyAllied("player", P2C_UNIT_TAG)
end

local notificationsKeybindLayerName = GetString(SI_KEYBINDINGS_LAYER_NOTIFICATIONS)

function ZO_PlayerToPlayer:OnUpdate()
    for i, incomingEntry in ipairs(self.incomingQueue) do
        if incomingEntry.updateFn then
            local isActive = i == 1 and (self.showingResponsePrompt or self.isInteracting)
            incomingEntry.updateFn(incomingEntry, isActive)
        end

        local isTimed = TIMED_PROMPTS[incomingEntry.incomingType]
        local isFlashing = FLASHING_PROMPTS[incomingEntry.incomingType]
        if (isTimed or isFlashing) and not incomingEntry.seen and SCENE_MANAGER:IsInUIMode() then
            if isTimed then
                -- For time sensitive prompts, the player probably won't see them if they are currently in a UI menu. Let's throw up a dialog before it's too late to respond
                ZO_Dialogs_ShowPlatformDialog("PTP_TIMED_RESPONSE_PROMPT", incomingEntry)
                FlashTaskbarWindow("PTP_TIMED_RESPONSE_PROMPT")
            else
                FlashTaskbarWindow("PTP_FLASHING_PROMPT")
            end
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
        self.showingResponsePrompt = false
        self.actionKeybindButton:SetHidden(true)
        self.actionKeybindButton:SetEnabled(true)
        self.additionalInfo:SetHidden(true)
        self.promptKeybindButton1.shouldHide = true
        self.promptKeybindButton2.shouldHide = true
        self.pendingResurrectInfoChanged = false

        if (not self.isInteracting) or (not IsConsoleUI()) then
            self.gamerID:SetHidden(true)
        end

        self.shouldShowNotificationKeybindLayer = false

        local hideSelf
        local hideTargetLabel
        local isReticleTargetInteractable = self:IsReticleTargetInteractable()
        local isReticleTargetCompanionInteractable = self:IsReticleTargetCompanionInteractable()
        if ZO_Dialogs_IsShowing("PTP_TIMED_RESPONSE_PROMPT") then
            -- Dialogs are prioritized above interact labels, so we don't accidentally show the same p2p notification that a dialog is currently showing
            hideSelf = true
            hideTargetLabel = true
        elseif INTERACTIVE_WHEEL_MANAGER:IsInteracting() then
            --We should not be showing this if any wheels are in use
            hideSelf = true
            hideTargetLabel = true
        elseif self:TryShowingResurrectLabel(P2P_UNIT_TAG) and isReticleTargetInteractable then
            -- TryShowingResurrectLabel has to be checked first to set the state of the pendingResurrectInfo label
            hideSelf = false
            hideTargetLabel = false
        elseif not self.isInteracting and (self.showingGamepadResponseMenu or not IsUnitInCombat("player")) and self:TryShowingResponseLabel() then
            hideSelf = false
            hideTargetLabel = self.showingGamepadResponseMenu
        elseif not self.isInteracting and isReticleTargetInteractable and self:TryShowingStandardInteractLabel() then
            hideSelf = not self:ShouldShowPromptAfterDelay()
            hideTargetLabel = hideSelf
        elseif self:TryShowingResurrectLabel(P2C_UNIT_TAG) and isReticleTargetCompanionInteractable then
            hideSelf = false
            hideTargetLabel = false
        elseif self.isInteracting then
            hideSelf = false
            hideTargetLabel = true
        else
            hideSelf = true
            hideTargetLabel = true
        end

        local wasSelfHidden = self:IsHidden()
        -- These must be called after we've determined what state they should be in
        -- Because if we simply hide and re-show them, the Chroma behavior will not function correctly
        self:SetHidden(hideSelf)
        self.targetLabel:SetHidden(hideTargetLabel)
        self.promptKeybindButton1:SetHidden(self.promptKeybindButton1.shouldHide)
        self.promptKeybindButton2:SetHidden(self.promptKeybindButton2.shouldHide)

        if wasSelfHidden ~= hideSelf or self.pendingResurrectInfoChanged then
            if hideSelf then
                --Clear out any in progress HUD narration when hiding the target prompt
                ClearNarrationQueue(NARRATION_TYPE_HUD)
            else
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("PlayerToPlayerPrompt")
            end
        end

        -- SetHidden isn't guaranteed to unhide us, so if something else is showing in the shared information
        -- area, we shouldn't push our keybind layer
        if self:IsHidden() then
            self.shouldShowNotificationKeybindLayer = false
        end

        local isNotificationLayerShown = IsActionLayerActiveByName(notificationsKeybindLayerName)

        if self.shouldShowNotificationKeybindLayer ~= isNotificationLayerShown then
            if self.shouldShowNotificationKeybindLayer then
                PushActionLayerByName(notificationsKeybindLayerName)
            else
                RemoveActionLayerByName(notificationsKeybindLayerName)
            end
        end
    else
        if IsActionLayerActiveByName(notificationsKeybindLayerName) then
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
    [SI_PLAYER_TO_PLAYER_INVITE_TRIBUTE] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_tribute_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_tribute_over.dds",
        disabledNormal = "EsoUI/Art/HUD/radialIcon_tribute_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_tribute_disabled.dds",
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
    [SI_PLAYER_TO_PLAYER_RIDE_MOUNT] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_joinMount_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_joinMount_over.dds",
        disabledNormal = "EsoUI/Art/HUD/radialIcon_joinMount_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_joinMount_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_DISMOUNT] =
    {
        enabledNormal = "EsoUI/Art/HUD/radialIcon_dismount_up.dds",
        enabledSelected = "EsoUI/Art/HUD/radialIcon_dismount_over.dds",
        disabledNormal = "EsoUI/Art/HUD/radialIcon_dismount_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/radialIcon_dismount_disabled.dds",
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
    [SI_PLAYER_TO_PLAYER_INVITE_TRIBUTE] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_tribute_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_tribute_down.dds",
        disabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_tribute_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_tribute_disabled.dds",
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
    [SI_PLAYER_TO_PLAYER_RIDE_MOUNT] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_joinMount_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_joinMount_down.dds",
        disabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_joinMount_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_joinMount_disabled.dds",
    },
    [SI_PLAYER_TO_PLAYER_DISMOUNT] =
    {
        enabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_dismount_down.dds",
        enabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_dismount_down.dds",
        disabledNormal = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_dismount_disabled.dds",
        disabledSelected = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_dismount_disabled.dds",
    },
}

function ZO_PlayerToPlayer:AddShowGamerCard(targetDisplayName, targetCharacterName)
    self:GetRadialMenu():AddEntry(GetString(ZO_GetGamerCardStringId()), "EsoUI/Art/HUD/Gamepad/gp_radialIcon_gamercard_down.dds", "EsoUI/Art/HUD/Gamepad/gp_radialIcon_gamercard_down.dds",
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
        local primaryName = ZO_GetPrimaryPlayerName(currentTargetDisplayName, currentTargetCharacterName)
        local primaryNameInternal = ZO_GetPrimaryPlayerName(currentTargetDisplayName, currentTargetCharacterName, USE_INTERNAL_FORMAT)
        local platformIcons = IsInGamepadPreferredMode() and GAMEPAD_INTERACT_ICONS or KEYBOARD_INTERACT_ICONS
        local ENABLED = true
        local DISABLED = false
        local ENABLED_IF_NOT_IGNORED = not isIgnored

        self:GetRadialMenu():Clear()
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

        local isInGroup = IsPlayerInGroup(currentTargetCharacterNameRaw)

        if isInGroup then
            local groupKickEnabled = isGroupModificationAvailable and isSoloOrLeader and not groupModicationRequiresVoting
            local groupKickFunction
            if groupKickEnabled then
                groupKickFunction = function() GroupKickByName(currentTargetCharacterNameRaw) end
            else
                groupKickFunction = AlertGroupDisabled
            end

            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_REMOVE_GROUP), platformIcons[SI_PLAYER_TO_PLAYER_REMOVE_GROUP], groupKickEnabled, groupKickFunction)
        else
            local groupInviteEnabled = ENABLED_IF_NOT_IGNORED and isGroupModificationAvailable and isSoloOrLeader
            local groupInviteFunction
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

        if isInGroup then
            local mountedState, isRidingGroupMount = GetTargetMountedStateInfo(currentTargetCharacterNameRaw)
            local isPassengerForTarget = IsGroupMountPassengerForTarget(currentTargetCharacterNameRaw)
            local groupMountEnabled = (mountedState == MOUNTED_STATE_MOUNT_RIDER and isRidingGroupMount and (not IsMounted() or isPassengerForTarget))
            local function MountOption() UseMountAsPassenger(currentTargetCharacterNameRaw) end
            local optionToShow = isPassengerForTarget and SI_PLAYER_TO_PLAYER_DISMOUNT or SI_PLAYER_TO_PLAYER_RIDE_MOUNT
            self:AddMenuEntry(GetString(optionToShow), platformIcons[optionToShow], groupMountEnabled, MountOption)  
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
            local function AlreadyDuelingWarning(state, characterName, displayName)
                return function()
                    local userFacingPartnerName = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
                    local statusString = GetString("SI_DUELSTATE", state)
                    statusString = zo_strformat(statusString, userFacingPartnerName)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, statusString)
                end
            end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_DUEL), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_DUEL], DISABLED, AlreadyDuelingWarning(duelState, partnerCharacterName, partnerDisplayName))
        else
            local function DuelInviteOption()
                ChallengeTargetToDuel(currentTargetCharacterName)
            end
            local isEnabled = ENABLED_IF_NOT_IGNORED and (not IsConsoleUI() or not IsConsoleCommunicationRestricted())
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_DUEL), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_DUEL], isEnabled, isEnabled and DuelInviteOption or AlertIgnored)
        end

       -- Play Tribute --
        local tributeInviteState, tributePartnerCharacterName, tributePartnerDisplayName = GetTributeInviteInfo()
        if tributeInviteState ~= TRIBUTE_INVITE_STATE_NONE then
            local function TributeInviteFailWarning(inviteState, characterName, displayName)
                return function()
                    local userFacingPartnerName = ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName)
                    local statusString = GetString("SI_TRIBUTEINVITESTATE", inviteState)
                    statusString = zo_strformat(statusString, userFacingPartnerName)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, statusString)
                end
            end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_TRIBUTE), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_TRIBUTE], DISABLED, TributeInviteFailWarning(tributeInviteState, tributePartnerCharacterName, tributePartnerDisplayName))
        else
            local function TributeInviteOption()
                ChallengeTargetToTribute(currentTargetCharacterName)
            end
            local function TributeLockedAlert()
                ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_PLAYER_TO_PLAYER_TRIBUTE_LOCKED)
            end
            local isEnabled = ENABLED_IF_NOT_IGNORED and not ZO_IsTributeLocked() and (not IsConsoleUI() or not IsConsoleCommunicationRestricted())
            local entryFunction
            if isEnabled then
                entryFunction = TributeInviteOption
            elseif ZO_IsTributeLocked() then
                entryFunction = TributeLockedAlert
            else
                entryFunction = AlertIgnored
            end
            self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_TRIBUTE), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_TRIBUTE], isEnabled, entryFunction)
        end

        --Trade--
        local function TradeInviteOption() TRADE_WINDOW:InitiateTrade(primaryNameInternal) end
        local isEnabled = ENABLED_IF_NOT_IGNORED and (not IsConsoleUI() or not IsConsoleCommunicationRestricted())
        local tradeInviteFunction = isEnabled and TradeInviteOption or AlertIgnored
        self:AddMenuEntry(GetString(SI_PLAYER_TO_PLAYER_INVITE_TRADE), platformIcons[SI_PLAYER_TO_PLAYER_INVITE_TRADE], isEnabled, tradeInviteFunction)

        --Cancel--
        self:AddMenuEntry(GetString(SI_RADIAL_MENU_CANCEL_BUTTON), platformIcons[SI_RADIAL_MENU_CANCEL_BUTTON], ENABLED)

        self:GetRadialMenu():Show()
        self.showingPlayerInteractMenu = true
        self.isLastRadialMenuGamepad = IsInGamepadPreferredMode()
        if self.isLastRadialMenuGamepad then
            local NARRATE_HEADER = true
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("PlayerToPlayerWheel", NARRATE_HEADER)
        end
    end
end

function ZO_PlayerToPlayer_Initialize(control)
    PLAYER_TO_PLAYER = ZO_PlayerToPlayer:New(control)
end
