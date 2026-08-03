ZO_TradeManager = ZO_InitializingObject:Subclass()

function ZO_TradeManager:Initialize()
    self.target = nil
    self.partnerUndecoratedCrossplayDisplayName = nil
    self.state = TRADE_STATE_IDLE

    self:RegisterForEvents()
end

function ZO_TradeManager:RegisterForEvents()
    local function OnPlayerActivated()
        TradeCancel() -- Make sure any trades from reloadui are cancelled
        EVENT_MANAGER:UnregisterForEvent("TradeSystem", EVENT_PLAYER_ACTIVATED)
    end

    EVENT_MANAGER:RegisterForEvent("TradeSystem", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    local function OnTradeInviteConsidering(_, inviterCharacterName, inviterCrossplayDisplayName, inviterPlatformDisplayName)
        self.target = ZO_GetPrimaryPlayerName(inviterCrossplayDisplayName, inviterCharacterName, inviterPlatformDisplayName)
        self.partnerUndecoratedCrossplayDisplayName = UndecorateDisplayName(inviterCrossplayDisplayName)
        self:SetState(TRADE_STATE_INVITE_CONSIDERING)
    end

    EVENT_MANAGER:RegisterForEvent("TradeSystem", EVENT_TRADE_INVITE_CONSIDERING, OnTradeInviteConsidering)

    local function OnTradeInviteWaiting(_, inviteeCharacterName, inviteeCrossplayDisplayName, inviteePlatformDisplayName)
        self.target = ZO_GetPrimaryPlayerName(inviteeCrossplayDisplayName, inviteeCharacterName, inviteePlatformDisplayName)
        self.partnerUndecoratedCrossplayDisplayName = UndecorateDisplayName(inviteeCrossplayDisplayName)
        self:SetState(TRADE_STATE_INVITE_WAITING)
    end

    EVENT_MANAGER:RegisterForEvent("TradeSystem", EVENT_TRADE_INVITE_WAITING, OnTradeInviteWaiting)

    local function OnTradeInviteDeclined()
        self:SetState(TRADE_STATE_IDLE)
    end

    EVENT_MANAGER:RegisterForEvent("TradeSystem", EVENT_TRADE_INVITE_DECLINED, OnTradeInviteDeclined)

    local function OnTradeInviteCanceled()
        self:SetState(TRADE_STATE_IDLE)
    end

    EVENT_MANAGER:RegisterForEvent("TradeSystem", EVENT_TRADE_INVITE_CANCELED, OnTradeInviteCanceled)
end

function ZO_TradeManager:InitiateTrade(crossplayDisplayName)
    --can't invite someone if you're trading
    if self.state == TRADE_STATE_TRADING then
        ZO_AlertEvent(EVENT_TRADE_ELEVATION_FAILED, TRADE_ACTION_RESULT_YOU_ARE_BUSY)
        return
    end

    if ZO_IsConsoleOrGameCoreUI() then
        local function TradeInviteCallback(success)
            if success then
                TradeInviteByName(crossplayDisplayName)
            end
        end

        -- TODO Crossplay: Re-evaluate names used here
        ZO_ConsoleAttemptInteractOrError(TradeInviteCallback, crossplayDisplayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, ZO_CONSOLE_CAN_COMMUNICATE_ERROR_ALERT, ZO_ID_REQUEST_TYPE_DISPLAY_NAME, crossplayDisplayName)
    else
        if IsIgnored(crossplayDisplayName) then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_GROUP_ALERT_INVITE_PLAYER_BLOCKED)
            return
        end

        TradeInviteByName(crossplayDisplayName)
    end
end

function ZO_TradeManager:CancelTradeInvite()
    TradeInviteCancel()
end

function ZO_TradeManager:AddItemToTrade(bagId, slotIndex)
    TradeAddItem(bagId, slotIndex)
end

function ZO_TradeManager:SetState(state)
    self.state = state
end

function ZO_TradeManager:IsTrading()
    return self.state == TRADE_STATE_TRADING
end

function ZO_TradeManager:IsWaiting()
    return self.state == TRADE_STATE_INVITE_WAITING
end

function ZO_TradeManager:IsConsidering()
    return self.state == TRADE_STATE_INVITE_CONSIDERING
end

function ZO_TradeManager:IsIdle()
    return self.state == TRADE_STATE_IDLE
end

function ZO_TradeManager:CanTradeItem(itemData)
    local bagId, slotIndex = itemData.bagId, itemData.slotIndex
    if IsItemBound(bagId, slotIndex) or itemData.stolen or itemData.isPlayerLocked then
        return false
    end

    if IsItemBoPAndTradeable(bagId, slotIndex) and not IsDisplayNameInItemBoPAccountTable(bagId, slotIndex, self.partnerUndecoratedCrossplayDisplayName) then
        return false
    end

    return true
end

TRADE_WINDOW = ZO_TradeManager:New()
