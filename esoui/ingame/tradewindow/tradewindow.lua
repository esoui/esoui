--Trade Manager Prototype
--This is the public interface to the trading system
ZO_TradeManager = ZO_Object:Subclass()

--
--Trade Manager functions
--

function ZO_TradeManager:Initialize()
    self.target = nil
    self.state = TRADE_STATE_IDLE
end

function ZO_TradeManager:InitiateTrade(displayName)
    --can't invite someone if you're trading
    if(self.state == TRADE_STATE_TRADING) then
        ZO_AlertEvent(EVENT_TRADE_ELEVATION_FAILED, TRADE_ACTION_RESULT_YOU_ARE_BUSY)
        return
    end

    if IsConsoleUI() then
        local function TradeInviteCallback(success)
            if success then
                TradeInviteByName(displayName)
            end
        end

        ZO_ConsoleAttemptInteractOrError(TradeInviteCallback, displayName, ZO_PLAYER_CONSOLE_INFO_REQUEST_DONT_BLOCK, ZO_CONSOLE_CAN_COMMUNICATE_ERROR_ALERT, ZO_ID_REQUEST_TYPE_DISPLAY_NAME, displayName)
    else
        if IsIgnored(displayName) then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_GROUP_ALERT_INVITE_PLAYER_BLOCKED)
            return
        end

        TradeInviteByName(displayName)
    end    
end

function ZO_TradeManager:CancelTradeInvite()
    TradeInviteCancel()
end

function ZO_TradeManager:AddItemToTrade(bagId, slotIndex)
    TradeAddItem(bagId, slotIndex)
end

--status functions
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
