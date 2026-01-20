local DirectPurchase_Manager = ZO_InitializingCallbackObject:Subclass()

function DirectPurchase_Manager:Initialize()
    local function OnQueryComplete(_, result, queryId)
        if queryId == self.queryId then
            self.queryId = nil
        end

        self:FireCallbacks("CatalogUpdated")
    end

    EVENT_MANAGER:RegisterForEvent("DirectPurchase_Manager", EVENT_DIRECT_PURCHASE_QUERY_CATALOG_COMPLETE, OnQueryComplete)

    local function OnPurchaseSkuResult(_, result)
        self:FireCallbacks("PurchaseSkuResult", result)
    end

    EVENT_MANAGER:RegisterForEvent("DirectPurchase_Manager", EVENT_DIRECT_PURCHASE_PURCHASE_SKU_RESULT, OnPurchaseSkuResult)

    local function OnRewardTrackSettingsUpdateReceived(_)
        self:FireCallbacks("SettingsUpdated")
    end

    EVENT_MANAGER:RegisterForEvent("DirectPurchase_Manager", EVENT_REWARD_TRACK_SETTINGS_UPDATE_RECEIVED, OnRewardTrackSettingsUpdateReceived)
end

function DirectPurchase_Manager:IsSystemEnabled()
    return IsDirectPurchaseEnabled()
end

function DirectPurchase_Manager:RequestCatalog()
    if self.queryId ~= nil then
        return
    end

    local queryId = QuerySkuCatalog()
    if queryId and queryId > 0 then
        self.queryId = queryId
    end
end

function DirectPurchase_Manager:RequestPurchase(skuId)
    local purchaseRequestId = RequestPurchaseSku(skuId)
end

DIRECT_PURCHASE_MANAGER = DirectPurchase_Manager:New()