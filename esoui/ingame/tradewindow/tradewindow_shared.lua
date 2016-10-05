--Shared Trade Window Prototype
ZO_SharedTradeWindow = ZO_Object:Subclass()

--
--Event Handlers and Helpers
--

--You just got invited to trade.
local function OnTradeWindowInviteConsidering(self, eventCode, inviterCharacterName, inviterDisplayName)
    TRADE_WINDOW.state = TRADE_STATE_INVITE_CONSIDERING
    TRADE_WINDOW.target = ZO_GetPrimaryPlayerName(inviterDisplayName, inviterCharacterName)
    TRADE_WINDOW.partnerUndecoratedDisplayName = UndecorateDisplayName(inviterDisplayName)
end

--You were notified that your target is considering your trade offer.
local function OnTradeWindowInviteWaiting(self, eventCode, inviteeCharacterName, inviteeDisplayName)
    TRADE_WINDOW.target = ZO_GetPrimaryPlayerName(inviteeDisplayName, inviteeCharacterName)
    TRADE_WINDOW.state = TRADE_STATE_INVITE_WAITING
    TRADE_WINDOW.partnerUndecoratedDisplayName = UndecorateDisplayName(inviteeDisplayName)
end

--Either you or they declined an offer
local function OnTradeWindowInviteDeclined(self, eventCode)
    --reset
    TRADE_WINDOW.state = TRADE_STATE_IDLE    
end

--Either you or they canceled the invite
local function OnTradeWindowInviteCanceled(self, eventCode)
    --You canceled your trade invite
    TRADE_WINDOW.state = TRADE_STATE_IDLE    
end

local function ShowTradeWindow(self)
    self:PrepareWindowForNewTrade()
    --reset state info
    TRADE_WINDOW.state = TRADE_STATE_TRADING
    self.confirm[TRADE_ME] = TRADE_CONFIRM_EDIT
    self.confirm[TRADE_THEM] = TRADE_CONFIRM_EDIT

    SYSTEMS:ShowScene("trade")
end

--Either we accepted their offer or they accepted ours
local function OnTradeWindowInviteAccepted(self, eventCode)
    if(not IsLooting()) then
        ShowTradeWindow(self)
    else
        self.waitingForLootWindow = true;
    end
end

--Debug function to show trade window because having two players isn't always convenient
function TradeWindowDebugShow()
    local self = SYSTEMS:GetGamepadObject("trade")
    local scene = SYSTEMS:GetGamepadRootScene("trade"):GetName()

    self:PrepareWindowForNewTrade()
    --reset state info
    TRADE_WINDOW.state = TRADE_STATE_TRADING
    self.confirm[TRADE_ME] = TRADE_CONFIRM_EDIT
    self.confirm[TRADE_THEM] = TRADE_CONFIRM_EDIT

    SCENE_MANAGER:Show(scene)
end

function ZO_IsItemCurrentlyOfferedForTrade(bagId, slotIndex)
    if bagId and slotIndex then
        for i = 1, TRADE_NUM_SLOTS do
            local bag, slot = GetTradeItemBagAndSlot(TRADE_ME, i)
            if bagId == bag and slotIndex == slot then
                return true
            end
        end
    end
    return false
end

--region promotion of money change event
local function OnTradeWindowMoneyChanged(self, eventCode, who, money)
    if TRADE_WINDOW:IsTrading() then
        self:OnTradeWindowMoneyChanged(eventCode, who, money)
    end
end

--an existing trade was canceled by myself or the other
local function OnTradeWindowCanceled(self, eventCode, who)
    if TRADE_WINDOW:IsTrading() then
        SYSTEMS:HideScene("trade")
        TRADE_WINDOW.state = TRADE_STATE_IDLE
    end
end

-- Cancel a trade when the player dies
local function OnPlayerDead(self, eventCode, who)
    if TRADE_WINDOW:IsTrading() then
        SYSTEMS:HideScene("trade")
        TRADE_WINDOW.state = TRADE_STATE_IDLE
    end
end

--terminate the trade window
local function FinishTrade()    
    TRADE_WINDOW.state = TRADE_STATE_IDLE
    SYSTEMS:HideScene("trade")
end

local function FailTrade()
    TRADE_WINDOW.state = TRADE_STATE_IDLE
    SYSTEMS:HideScene("trade")
end

local function OnTradeFailed(self, eventCode)
    FailTrade()
end

local function OnTradeSucceeded(self, eventCode)
    FinishTrade()
end

--either of us changed states
local function OnTradeWindowConfirmationChanged(self, eventCode, who, level)
    if TRADE_WINDOW:IsTrading() then
        self:UpdateConfirmationView(who, level)
    end
end

--Either player added an item to the trade
local function OnTradeWindowItemAdded(self, eventCode, who, tradeSlot, itemSoundCategory)
    if TRADE_WINDOW:IsTrading() then
        self:OnTradeWindowItemAdded(eventCode, who, tradeSlot, itemSoundCategory)
    end
end

--Either player removed an item from the trade
local function OnTradeWindowItemRemoved(self, eventCode, who, tradeSlot, itemSoundCategory)
    if TRADE_WINDOW:IsTrading() then
        self:OnTradeWindowItemRemoved(eventCode, who, tradeSlot, itemSoundCategory)
    end
end

--An existing item changed quantity
local function OnTradeWindowItemUpdated(self, eventCode, who, tradeSlot)
    if TRADE_WINDOW:IsTrading() then
        local _, _, quantity = GetTradeItemInfo(who, tradeSlot)
        self:UpdateSlotQuantity(who, tradeSlot, quantity)
    end
end

local function OnTradeAcceptFailedNotEnoughMoney(self)
    self:OnTradeAcceptFailedNotEnoughMoney()
end

local function OnLootClosed(self)
    if self.waitingForLootWindow then
        self.waitingForLootWindow = false
        ShowTradeWindow(self)
    end
end

--
--Trade Manager functions
--

--Shared Trade Window Constructor
function ZO_SharedTradeWindow:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SharedTradeWindow:Initialize(control)
    self.confirm = 
    {
        [TRADE_ME] = TRADE_CONFIRM_EDIT,
        [TRADE_THEM] = TRADE_CONFIRM_EDIT,
    }

    self.control = control
    control.object = self

    self:InitializeKeybindDescriptor()

    --Setup events
    self:InitializeSharedEvents()

    self.waitingForLootWindow = false
end

local EventCallbacks = {
    [EVENT_TRADE_INVITE_CONSIDERING] = OnTradeWindowInviteConsidering,
    [EVENT_TRADE_INVITE_WAITING] = OnTradeWindowInviteWaiting,
    [EVENT_TRADE_INVITE_DECLINED] = OnTradeWindowInviteDeclined,
    [EVENT_TRADE_INVITE_CANCELED] = OnTradeWindowInviteCanceled,
    [EVENT_TRADE_INVITE_ACCEPTED] = OnTradeWindowInviteAccepted,
    [EVENT_TRADE_MONEY_CHANGED] = OnTradeWindowMoneyChanged,
    [EVENT_TRADE_CANCELED] = OnTradeWindowCanceled,
    [EVENT_TRADE_CONFIRMATION_CHANGED] = OnTradeWindowConfirmationChanged,
    [EVENT_TRADE_ITEM_ADDED] = OnTradeWindowItemAdded,
    [EVENT_TRADE_ITEM_REMOVED] = OnTradeWindowItemRemoved,
    [EVENT_TRADE_ITEM_UPDATED] = OnTradeWindowItemUpdated,
    [EVENT_TRADE_FAILED] = OnTradeFailed,
    [EVENT_TRADE_SUCCEEDED] = OnTradeSucceeded,
    [EVENT_TRADE_ACCEPT_FAILED_NOT_ENOUGH_MONEY] = OnTradeAcceptFailedNotEnoughMoney,
    [EVENT_PLAYER_DEAD] = OnPlayerDead,
    [EVENT_LOOT_CLOSED] = OnLootClosed,
}

--- TODO - This should be generalized in SYSTEMS:RegisterForEvent
local function ContextFilter(object, callback)
    -- This will wrap the callback so that it gets called with the control
    return function(...)
        local target = SYSTEMS:GetObject("trade")

        if (target == object) then
            callback(object, ...)
        end
    end
end

function ZO_SharedTradeWindow:InitializeSharedEvents()
    for event, callback in pairs(EventCallbacks) do
        self.control:RegisterForEvent(event, ContextFilter(self, callback))
    end
end

function ZO_SharedTradeWindow:IsTrading()
    return TRADE_WINDOW:IsTrading()
end

function ZO_SharedTradeWindow:IsReady()
    if(self:IsTrading()) then
        return (self.confirm[TRADE_ME] == TRADE_CONFIRM_ACCEPT)
    end

    return false
end

function ZO_SharedTradeWindow:FindMyNextAvailableSlot()
    for i = 1, TRADE_NUM_SLOTS do
        local _, _, stackCount, _ = GetTradeItemInfo(TRADE_ME, i)

        if(stackCount == 0) then
            return i
        end
    end
end

function ZO_SharedTradeWindow:CanTradeItem(bagId, slot)
    if(self:IsTrading()) then
        return not IsItemBound(bagId, slot) and self:FindMyNextAvailableSlot() ~= nil
    end
end

function ZO_SharedTradeWindow:HasItemsOrGoldInTradeWindow(who)
    if GetTradeMoneyOffer(who) ~= 0 then
        return true
    end
    
    for i = 1, TRADE_NUM_SLOTS do
        local _, _, stackCount = GetTradeItemInfo(who, i)
        if stackCount ~= 0 then
            return true
        end
    end

    return false
end

function ZO_SharedTradeWindow:IsModifyConfirmationLevelEnabled()
    if self.m_reenableTime == nil or GetFrameTimeMilliseconds() >= self.m_reenableTime then
        if self.confirm[TRADE_ME] == TRADE_CONFIRM_EDIT then
            --There needs to be something in the trade (on either side) to accept it
            return self:HasItemsOrGoldInTradeWindow(TRADE_ME) or self:HasItemsOrGoldInTradeWindow(TRADE_THEM)
        else
            return true
        end
    else
        return false
    end
end

local function OnConfirmationDelayUpdate(control)
    local self = control.object
    if(self:IsModifyConfirmationLevelEnabled()) then
        self:SetConfirmationDelay(0)
    end
end

function ZO_SharedTradeWindow:SetConfirmationDelay(delay)
    if(delay > 0) then
        self.m_reenableTime = GetFrameTimeMilliseconds() + TRADE_DELAY_TIME
        self.control:SetHandler("OnUpdate", OnConfirmationDelayUpdate)
    else
        self.m_reenableTime = nil
        self.control:SetHandler("OnUpdate", nil)
    end
    
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_SharedTradeWindow:OnTradeAcceptFailedNotEnoughMoney()
    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_TRADE_NOT_ENOUGH_MONEY)
end

--Adjust the confirmation UI elements for the new level
function ZO_SharedTradeWindow:UpdateConfirmationView(whoID, newLevel)
    local currentLevel = self.confirm[whoID]
    self.confirm[whoID] = newLevel

    --call each transfer function between the states
    --ascending
    if(newLevel > currentLevel) then
        for i = currentLevel, newLevel-1 do
            local changeFunc = self.confirmChangeFunctions[whoID][i][i+1]
            if(changeFunc) then
                changeFunc()
            end
        end
    --descending
    elseif(newLevel < currentLevel) then
        for i = currentLevel,newLevel+1, -1  do
            local changeFunc = self.confirmChangeFunctions[whoID][i][i-1]
            if(changeFunc) then
                changeFunc()
            end
        end
    end
end

