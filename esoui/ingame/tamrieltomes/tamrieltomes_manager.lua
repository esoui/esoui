----------
-- ZO_TamrielTomeDirectPurchaseData
----------

ZO_TamrielTomeDirectPurchaseData = ZO_InitializingObject:Subclass()

function ZO_TamrielTomeDirectPurchaseData:Initialize(tomeId, productType)
    self.tomeId = tomeId
    self.productType = productType

    self:Update()
end

function ZO_TamrielTomeDirectPurchaseData:GetTomeId()
    return self.tomeId
end

function ZO_TamrielTomeDirectPurchaseData:GetProductType()
    return self.productType
end

function ZO_TamrielTomeDirectPurchaseData:Update()
    self.skuId = GetTamrielTomeSkuId(self.tomeId, self.productType)
end

function ZO_TamrielTomeDirectPurchaseData:IsAvailableForPurchase()
    return IsSkuAvailableForPurchase(self.skuId)
end

function ZO_TamrielTomeDirectPurchaseData:IsOwned()
    return HasTamrielTomeProductType(self.tomeId, self.productType)
end

function ZO_TamrielTomeDirectPurchaseData:CanPurchase()
    return not self:IsOwned() and self:IsAvailableForPurchase()
end

function ZO_TamrielTomeDirectPurchaseData:GetPricingInfo()
    local currentPrice, basePrice, currency = GetSkuPricingInfo(self.skuId)
    return currentPrice, basePrice, currency
end

function ZO_TamrielTomeDirectPurchaseData:RequestPurchase()
    DIRECT_PURCHASE_MANAGER:RequestPurchase(self.skuId)
end

----------
-- TamrielTomes_Manager
----------

local TamrielTomes_Manager = ZO_InitializingCallbackObject:Subclass()

function TamrielTomes_Manager:Initialize()
    self.selectedTomePurchaseData = {}

    local currentTomeId = self:GetActiveTomeId()
    self:SelectTomeId(currentTomeId)

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            EVENT_MANAGER:UnregisterForEvent("TamrielTomes_Manager", EVENT_ADD_ON_LOADED)
            self:SetupSavedVars()
            self:UpdateTamrielTomesAvailability()
        end
    end

    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    local function UpdateTamrielTomesAvailability()
        self:UpdateTamrielTomesAvailability()
    end

    local function OnRewardTrackStarted(_, rewardTrackType, rewardTrackId)
        if rewardTrackType == REWARD_TRACK_TYPE_TAMRIEL_TOMES then
            UpdateTamrielTomesAvailability()
        end
    end

    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_HOLIDAYS_CHANGED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_UPDATE_RECEIVED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_SETTINGS_UPDATE_RECEIVED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_STARTED, OnRewardTrackStarted)

    function OnCatalogUpdated()
        self:UpdateDirectPurchaseData()
    end

    DIRECT_PURCHASE_MANAGER:RegisterCallback("CatalogUpdated", OnCatalogUpdated)
end

function TamrielTomes_Manager:SetupSavedVars()
    local defaults =
    {
        tomes = {},
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "TamrielTomes_Manager", defaults)
end

function TamrielTomes_Manager:AreSavedVarsInitialized()
    return self.savedVars ~= nil
end

function TamrielTomes_Manager:GetSavedVars()
    if not assert(self:AreSavedVarsInitialized(), "SavedVars are not initialized yet.") then
        return nil
    end
    return self.savedVars
end

function TamrielTomes_Manager:GetSavedVarsForAllTomes()
    local savedVars = self:GetSavedVars()
    if savedVars then
        if not savedVars.tomes then
            savedVars.tomes = {}
        end
        return savedVars.tomes
    end
    return nil
end

function TamrielTomes_Manager:GetSavedVarsForTome(tomeId)
    local tomesSavedVars = self:GetSavedVarsForAllTomes()
    if tomesSavedVars then
        return tomesSavedVars[tomeId]
    end
    return nil
end

function TamrielTomes_Manager:GetOrCreateSavedVarsForTome(tomeId)
    local tomeSavedVars = self:GetSavedVarsForTome(tomeId)
    if not tomeSavedVars and tomeId then
        local savedVars = self:GetSavedVars()
        if savedVars and savedVars.tomes then
            tomeSavedVars =
            {
                --lastSeenTimestamp = nil,
            }
            savedVars.tomes[tomeId] = tomeSavedVars
        end
    end
    return tomeSavedVars
end

function TamrielTomes_Manager:ClearAllTomesSeen()
    local tomesSavedVars = self:GetSavedVarsForAllTomes()
    if tomesSavedVars then
        for tomeId, tomeSavedVars in pairs(tomesSavedVars) do
            tomeSavedVars.lastSeenTimestamp = nil
        end
    end
end

function TamrielTomes_Manager:ClearTomeSeen(tomeId)
    local tomeSavedVars = self:GetSavedVarsForTome(tomeId)
    if tomeSavedVars then
        tomeSavedVars.lastSeenTimestamp = nil
    end
end

function TamrielTomes_Manager:MarkTomeSeen(tomeId)
    local tomeSavedVars = self:GetOrCreateSavedVarsForTome(tomeId)
    if tomeSavedVars then
        tomeSavedVars.lastSeenTimestamp = GetTimeStamp()
    end
end

function TamrielTomes_Manager:GetTomeLastSeenTimestamp(tomeId)
    local tomeSavedVars = self:GetSavedVarsForTome(tomeId)
    if tomeSavedVars then
        return tomeSavedVars.lastSeenTimestamp
    end

    return nil
end

function TamrielTomes_Manager:HasSeenTome(tomeId)
    local lastSeenTimestamp = self:GetTomeLastSeenTimestamp(tomeId)
    if lastSeenTimestamp == nil then
        return false
    end

    return lastSeenTimestamp <= GetTimeStamp()
end

-- Returns the first active Tome Id, if any, or nil.
function TamrielTomes_Manager:GetActiveTomeId()
    local activeTomeIds = self:GetActiveTomeIds()
    return activeTomeIds[1]
end

-- Returns all active Tome Ids.
function TamrielTomes_Manager:GetActiveTomeIds()
    local activeTomeIds = { GetActiveReferenceTrackIdsForRewardTrackType(REWARD_TRACK_TYPE_TAMRIEL_TOMES) }
    return activeTomeIds
end

-- Returns the number of active Tomes.
function TamrielTomes_Manager:GetNumActiveTomes()
    return #self:GetActiveTomeIds()
end

-- Indicates whether a valid Tome Id is selected.
function TamrielTomes_Manager:HasSelectedTomeId()
    return self.selectedTomeId ~= nil
end

-- Returns the selected Tome Id, if any.
function TamrielTomes_Manager:GetSelectedTomeId()
    return self.selectedTomeId
end

function TamrielTomes_Manager:SelectTomeId(tomeId)
    if tomeId == nil or tomeId == 0 then
        -- Default to the active season's tome.
        tomeId = self:GetActiveTomeId()
    end

    if tomeId ~= self.selectedTomeId then
        -- Order matters
        self.selectedTomeId = tomeId
        self:BuildDirectPurchaseData()
        self:FireCallbacks("SelectedTomeChanged", tomeId)
    end
end

function TamrielTomes_Manager:OpenTamrielTome(tomeId)
    self:SelectTomeId(tomeId)
    SYSTEMS:ShowScene("tamrielTomes")
end

function TamrielTomes_Manager:GetFeaturedTomeRewards(tomeId)
    local numRewards = GetNumTamrielTomeFeaturedRewards(tomeId)
    if numRewards == 0 then
        return {}
    end

    local rewardTrackId = GetRewardTrackIdFromReferenceTrackId(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tomeId)
    local rewards = {}
    for rewardIndex = 1, numRewards do
        local rewardTierIndex, rewardComponent, rewardIndex = GetTamrielTomeFeaturedRewardInfo()
        local rewardId, rewardQuantity, rewardCost, rewardDisplayQuality = GetTamrielTomesRewardInfo(rewardTrackId, rewardTierIndex, rewardComponent, rewardIndex)
        local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)
        if rewardData then
            local rewardEntry = ZO_EntryData:New(rewardData)
            table.insert(rewards, rewardEntry)
        end
    end

    return rewards
end

function TamrielTomes_Manager:UpdateTamrielTomesAvailability()
    self:RefreshMainMenus()
end

function TamrielTomes_Manager:RefreshMainMenus()
    MAIN_MENU_GAMEPAD:UpdateEntryEnabledStates()

    if MAIN_MENU_KEYBOARD then
        MAIN_MENU_KEYBOARD:UpdateCategories()
    end
end

function TamrielTomes_Manager:BuildDirectPurchaseData()
    ZO_ClearTable(self.selectedTomePurchaseData)

    local tomeId = self.selectedTomeId

    for productType = TAMRIEL_TOME_PRODUCT_TYPE_ITERATION_BEGIN, TAMRIEL_TOME_PRODUCT_TYPE_ITERATION_END do
        local purchaseData = ZO_TamrielTomeDirectPurchaseData:New(tomeId, productType)
        self.selectedTomePurchaseData[productType] = purchaseData
    end
end

function TamrielTomes_Manager:UpdateDirectPurchaseData()
    for productType, purchaseData in pairs(self.selectedTomePurchaseData) do
        purchaseData:Update()
    end

    self:FireCallbacks("DirectPurchaseDataUpdated")
end

function TamrielTomes_Manager:IsAnySelectedTomeProductAvailableForPurchase()
    for productType, purchaseData in pairs(self.selectedTomePurchaseData) do
        if purchaseData:IsAvailableForPurchase() then
            return true
        end
    end

    return false
end

function TamrielTomes_Manager:CanPurchaseAnySelectedTomeProduct()
    for productType, purchaseData in pairs(self.selectedTomePurchaseData) do
        if purchaseData:CanPurchase() then
            return true
        end
    end

    return false
end

function TamrielTomes_Manager:GetPurchaseDataForSelectedTomeProductType(productType)
    local purchaseData = self.selectedTomePurchaseData[productType]
    return purchaseData
end

TAMRIEL_TOMES_MANAGER = TamrielTomes_Manager:New()