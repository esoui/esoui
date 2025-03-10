--[[
---- Lifecycle
--]]

ZO_Fence_Manager = ZO_CallbackObject:Subclass()

function ZO_Fence_Manager:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_Fence_Manager:Initialize()
    -- Initialize data
    self.totalSells, self.sellsUsed = GetFenceSellTransactionInfo()
    self.totalLaunders, self.laundersUsed = GetFenceLaunderTransactionInfo()

    -- Register for events
    EVENT_MANAGER:RegisterForEvent("ZO_Fence_Manager", EVENT_OPEN_FENCE, function(eventCode, enableSell, enableLaunder) self:OnFenceOpened(enableSell, enableLaunder) end)
    EVENT_MANAGER:RegisterForEvent("ZO_Fence_Manager", EVENT_CLOSE_STORE, function(eventCode) self:OnFenceClosed() end)
    EVENT_MANAGER:RegisterForEvent("ZO_Fence_Manager", EVENT_SELL_RECEIPT, function(eventCode, itemName, quantity, money) self:OnSellSuccess() end)
    EVENT_MANAGER:RegisterForEvent("ZO_Fence_Manager", EVENT_ITEM_LAUNDER_RESULT, function(eventCode, result) self:OnLaunderResult(result) end)
    EVENT_MANAGER:RegisterForEvent("ZO_Fence_Manager", EVENT_INVENTORY_FULL_UPDATE, function(eventCode) self:OnInventoryUpdated() end)
    EVENT_MANAGER:RegisterForEvent("ZO_Fence_Manager", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(eventCode) self:OnInventoryUpdated() end)
    EVENT_MANAGER:RegisterForEvent("ZO_Fence_Manager", EVENT_JUSTICE_FENCE_UPDATE, function(eventCode, sellsUsed, laundersUsed) 
        self:OnFenceStateUpdated(sellsUsed, laundersUsed) 
    end)
end

--[[
---- Events
--]]

function ZO_Fence_Manager:OnFenceOpened(enableSell, enableLaunder)
    self.totalSells, self.sellsUsed = GetFenceSellTransactionInfo()
    self.totalLaunders, self.laundersUsed = GetFenceLaunderTransactionInfo()
    self:FireCallbacks("FenceOpened", enableSell, enableLaunder)
end

function ZO_Fence_Manager:OnFenceClosed()
    self:FireCallbacks("FenceClosed")
end

function ZO_Fence_Manager:OnSellSuccess()
    self:FireCallbacks("FenceSellSuccess")
end

function ZO_Fence_Manager:OnLaunderResult(result)
    if result == ITEM_LAUNDER_RESULT_SUCCESS then
        self:FireCallbacks("FenceLaunderSuccess")
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_ITEMLAUNDERRESULT", result)) 
    end
end

function ZO_Fence_Manager:OnInventoryUpdated()
    self:FireCallbacks("FenceInventoryUpdated")
end

function ZO_Fence_Manager:OnFenceStateUpdated(sellsUsed, laundersUsed)
    self.sellsUsed = sellsUsed
    self.laundersUsed = laundersUsed
    self:FireCallbacks("FenceUpdated", self.totalSells, sellsUsed, self.totalLaunders, laundersUsed)
end

function ZO_Fence_Manager:OnEnterSell()
    self:FireCallbacks("FenceEnterSell", self.totalSells, self.sellsUsed)
end

function ZO_Fence_Manager:OnEnterLaunder()
    self:FireCallbacks("FenceEnterLaunder", self.totalLaunders, self.laundersUsed)
end

--[[
---- Helper functions
--]]

function ZO_Fence_Manager:GetNumTotalTransactions(mode)
    if mode == ZO_MODE_STORE_SELL_STOLEN then
        return self.totalSells
    elseif mode == ZO_MODE_STORE_LAUNDER then
        return self.totalLaunders
    else
        return 0
    end
end

function ZO_Fence_Manager:GetNumTransactionsUsed(mode)
    if mode == ZO_MODE_STORE_SELL_STOLEN then
        return self.sellsUsed
    elseif mode == ZO_MODE_STORE_LAUNDER then
        return self.laundersUsed
    else
        return 0
    end
end

function ZO_Fence_Manager:GetNumTransactionsRemaining(mode)
    return self:GetNumTotalTransactions(mode) - self:GetNumTransactionsUsed(mode)
end

function ZO_Fence_Manager:HasBonusToSellingStolenItems()
    local hagglingSkillLevel = self:GetHagglingBonus()
    return hagglingSkillLevel > 0
end

function ZO_Fence_Manager:GetHagglingBonus()
    return GetTotalFenceHagglingBonus()
end

--[[
---- Global functions
--]]

FENCE_MANAGER = ZO_Fence_Manager:New()