--
--Event Handlers and Helpers
--

local function OnMoneyChanged(moneyInput, money, eventType)
    if(eventType == "confirm") then
        TradeSetMoney(money)
        ZO_TradeMyControlsMoney:SetHidden(false)
    elseif(eventType == "cancel") then
        ZO_TradeMyControlsMoney:SetHidden(false)
    end
end


--These functions handle updating the UI as we go between confimation states.
--An entry [A][B] holds the function that can move the UI from confirm state A to confirm state B.
local ConfirmChangeFunctions =
{
    [TRADE_ME] = {
        [TRADE_CONFIRM_EDIT] = {
            [TRADE_CONFIRM_ACCEPT] = function()
                ZO_TradeMyControlsAcceptOverlay:SetHidden(false)
                ZO_TradeMyControlsReadyText:SetHidden(false)
                KEYBIND_STRIP:UpdateKeybindButtonGroup(TRADE.keybindStripDescriptor)
                TRADE:HideEmptySlots(TRADE_ME)
                PlaySound(SOUNDS.TRADE_PARTICIPANT_READY)
            end
        },
        [TRADE_CONFIRM_ACCEPT] = {
            [TRADE_CONFIRM_EDIT] = function()
                ZO_TradeMyControlsAcceptOverlay:SetHidden(true)
                ZO_TradeMyControlsReadyText:SetHidden(true)
                TRADE:ShowAllSlots(TRADE_ME)
                TRADE:SetConfirmationDelay(TRADE_DELAY_TIME)
                PlaySound(SOUNDS.TRADE_PARTICIPANT_RECONSIDER)
            end,
        }
    },
    [TRADE_THEM] = {
        [TRADE_CONFIRM_EDIT] = {
            [TRADE_CONFIRM_ACCEPT] = function()
                ZO_TradeTheirControlsAcceptOverlay:SetHidden(false)
                ZO_TradeTheirControlsReadyText:SetHidden(false)
                PlaySound(SOUNDS.TRADE_PARTICIPANT_READY)
            end
        },
        [TRADE_CONFIRM_ACCEPT] = {
            [TRADE_CONFIRM_EDIT] = function()
                ZO_TradeTheirControlsAcceptOverlay:SetHidden(true)
                ZO_TradeTheirControlsReadyText:SetHidden(true)
                TRADE:SetConfirmationDelay(TRADE_DELAY_TIME)
                PlaySound(SOUNDS.TRADE_PARTICIPANT_RECONSIDER)
            end,
        }
    },
}

-- Trade Window

ZO_TradeWindow = ZO_SharedTradeWindow:Subclass()

function ZO_TradeWindow:New(control)
    return ZO_SharedTradeWindow.New(self, control)
end

function ZO_TradeWindow:Initialize(control)
    self.control = control
    self.sceneName = "trade"
    self.Columns = {}
    self.confirmChangeFunctions = ConfirmChangeFunctions

    self:CreateSlots(TRADE_ME, control:GetNamedChild("MyControls"), "MyTradeWindowSlot", SLOT_TYPE_MY_TRADE)
    self:CreateSlots(TRADE_THEM, control:GetNamedChild("TheirControls"), "TheirTradeWindowSlot", SLOT_TYPE_THEIR_TRADE)

    ZO_SharedTradeWindow.Initialize(self, control)
end

function ZO_TradeWindow:InitializeScene(name)
    local tradeScene = ZO_Scene:New(name, SCENE_MANAGER)
    tradeScene:RegisterCallback("StateChange",  function(oldState, newState)
                                                    if(newState == SCENE_SHOWING) then
                                                        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
                                                    elseif newState == SCENE_HIDING then
                                                        --The trade is often over as the scene starts hiding. If we don't remover the Submit Offer keybind here
                                                        --we can run into a case where it collides with the enchant keyind on an item since that is only gated
                                                        --from showing when we are actually in the trade (ESO-489071).
                                                        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                    elseif(newState == SCENE_HIDDEN) then
                                                        TradeCancel()
                                                        CURRENCY_INPUT:Hide()
                                                        TradeSetMoney(0)
                                                        self.myOfferedMoney = 0
                                                    end
                                                end)
end

function ZO_TradeWindow:PrepareWindowForNewTrade()
    ZO_TradeMyControlsAcceptOverlay:SetHidden(true)
    ZO_TradeMyControlsReadyText:SetHidden(true)
    
    ZO_TradeTheirControlsAcceptOverlay:SetHidden(true)
    ZO_TradeTheirControlsReadyText:SetHidden(true)

    self:ResetAllSlots(TRADE_THEM)
    self:ResetAllSlots(TRADE_ME)

    self:ShowAllSlots(TRADE_ME)
    self:HideAllSlots(TRADE_THEM)

    ZO_TradeTheirControlsName:SetText(zo_strformat(SI_TRADE_THEIR_OFFER, TRADE_WINDOW.target))
    
    ZO_CurrencyControl_SetSimpleCurrency(ZO_TradeTheirControlsMoney, CURT_MONEY, 0)
    ZO_CurrencyControl_SetSimpleCurrency(ZO_TradeMyControlsMoney, CURT_MONEY, 0)
    ZO_CurrencyControl_SetClickHandler(ZO_TradeMyControlsMoney, ZO_Trade_BeginChangeMoney)
end

function ZO_TradeWindow:InitializeKeybindDescriptor()

    local function AcceptOrCancel()
        if(TRADE_WINDOW.state ~= TRADE_STATE_TRADING) then
            return
        end

        if(self.confirm[TRADE_ME] == TRADE_CONFIRM_EDIT) then
            TradeAccept()
        else
            TradeEdit()
        end
    end

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Confirm/Cancel Trade
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            
            name = function()
                if(self:IsReady()) then
                    return GetString(SI_TRADE_CANCEL)
                else
                    return GetString(SI_TRADE_ACCEPT)
                end
            end,

            enabled = function()
                return self:IsModifyConfirmationLevelEnabled()
            end,

            callback = AcceptOrCancel,
        },
    }    
end

--
-- Slot management functions
--

local function UpdateMouseoverForUpdatedSlot(slotControl)
    local inventorySlot = slotControl:GetParent()
    if(MouseIsOver(inventorySlot)) then
        ZO_InventorySlot_OnMouseExit(inventorySlot)
        ZO_InventorySlot_OnMouseEnter(inventorySlot)
    end
end

function ZO_TradeWindow:HideEmptySlots(who)
    local col = self.Columns[who]
    for i = 1, TRADE_NUM_SLOTS do
        local row = col[i]
        if row.Available then
            row.SlotControl:SetHidden(true)
        end
    end
end

function ZO_TradeWindow:ShowAllSlots(who)
    local col = self.Columns[who]
    for i = 1, TRADE_NUM_SLOTS do
        local row = col[i]
        row.SlotControl:SetHidden(false)
    end    
end

function ZO_TradeWindow:HideAllSlots(who)
    local col = self.Columns[who]
    for i = 1, TRADE_NUM_SLOTS do
        local row = col[i]
        if row.Available then
            row.SlotControl:SetHidden(true)
        end
    end    
end

function ZO_TradeWindow:InitializeSlot(who, index, name, icon, quantity, quality)
    local row = self.Columns[who][index]
    local slotControl = row.SlotControl
    row.Available = false

    row.NameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, name))
    row.NameControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))

    ZO_Inventory_SetupSlot(slotControl, quantity, icon)
    UpdateMouseoverForUpdatedSlot(slotControl)
end

function ZO_TradeWindow:ResetAllSlots(who)
    for i = 1, TRADE_NUM_SLOTS do
        self:ResetSlot(who, i)
    end
end

function ZO_TradeWindow:ResetSlot(who, index)
    local row = self.Columns[who][index]
    row.NameControl:SetText("")
    row.Available = true

    local iconFile = nil
    if(who == TRADE_ME) then
        iconFile = "EsoUI/Art/TradeWindow/trade_addItem.dds"
    end

    ZO_Inventory_SetupSlot(row.SlotControl, 0, iconFile)
    UpdateMouseoverForUpdatedSlot(row.SlotControl)
end

function ZO_TradeWindow:UpdateSlotQuantity(who, index, quantity)
    local row = self.Columns[who][index]    
    row.SlotControl:SetText(quantity)
end

function ZO_TradeWindow:CreateSlots(tradeOwner, slotsParent, slotPrefix, slotType)
    self.Columns[tradeOwner] = {}
    local rowList = self.Columns[tradeOwner]    

    local lastControl
    for i = 1, TRADE_NUM_SLOTS do
        local control = CreateControlFromVirtual(slotPrefix, slotsParent, "ZO_TradeSlot", i)
        local slotControl = control:GetNamedChild("Button")
        local iconControl = slotControl:GetNamedChild("Icon")

        rowList[i] = {
            Available = true,
            Control = control,
            SlotControl = slotControl,
            NameControl = control:GetNamedChild("Name"),
            IconControl = iconControl,
        }

        if(not lastControl) then
            control:SetAnchor(TOPLEFT)
        else
            control:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 2)
        end

        ZO_Inventory_BindSlot(slotControl, slotType, i)

        lastControl = control
    end
end

--Either player added an item to the trade
function ZO_TradeWindow:OnTradeWindowItemAdded(eventCode, who, tradeSlot, itemSoundCategory)
    local itemName, icon, quantity, quality = GetTradeItemInfo(who, tradeSlot)
    self:InitializeSlot(who, tradeSlot, itemName, icon, quantity, quality)

    --if this on their side, show the slot now that it has an item
    if(who == TRADE_THEM) then
        local row = self.Columns[TRADE_THEM][tradeSlot]
        row.SlotControl:SetHidden(false)
    end

    PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_SLOT)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

--Either player removed an item from the trade
function ZO_TradeWindow:OnTradeWindowItemRemoved(eventCode, who, tradeSlot, itemSoundCategory)
    self:ResetSlot(who, tradeSlot)

    --if this on their side, hide the slot now that it doesn't have an item
    if(who == TRADE_THEM) then
        local row = self.Columns[TRADE_THEM][tradeSlot]
        row.SlotControl:SetHidden(true)

        -- Do not play the sound for my items, cursor pickup handles that.
        PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_PICKUP)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

--region promotion of money change event
function ZO_TradeWindow:OnTradeWindowMoneyChanged(eventCode, who, money)
    if(who == TRADE_THEM) then
        ZO_CurrencyControl_SetSimpleCurrency(ZO_TradeTheirControlsMoney, CURT_MONEY, money)
    else
        self.myOfferedMoney = money
        ZO_CurrencyControl_SetSimpleCurrency(ZO_TradeMyControlsMoney, CURT_MONEY, money)
    end

    PlaySound(SOUNDS.ITEM_MONEY_CHANGED)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

--
--XML handlers
--

--handlers for your half of the window not including the slots
function ZO_Trade_OnReceiveDrag()
    PlaceInTradeWindow()
end

function ZO_Trade_OnMouseDown()
    PlaceInTradeWindow()
end

function ZO_Trade_BeginChangeMoney(anchorTo)
    CURRENCY_INPUT:Show(OnMoneyChanged, true, nil, CURT_MONEY, anchorTo, -5)
    ZO_TradeMyControlsMoney:SetHidden(true)
end

function ZO_Trade_OnInitialize(control)
    TRADE = ZO_TradeWindow:New(control)
    TRADE:InitializeScene("trade")

    SYSTEMS:RegisterKeyboardObject("trade", TRADE)
end

