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

    local function OnCurrencyUpdated(_, currencyType, currencyLocation, newAmount, oldAmount, reason, reasonSupplementaryInfo)
        self:OnCurrencyUpdated(currencyType, currencyLocation, newAmount, oldAmount, reason, reasonSupplementaryInfo)
    end

    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_CURRENCY_UPDATE, OnCurrencyUpdated)

    local function OnRewardTrackProgressGained(_, rewardTrackType, referenceTrackId, newTier, newProgress)
        self:OnRewardTrackProgressGained(rewardTrackType, referenceTrackId, newTier, newProgress)
    end

    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_PROGRESS_GAINED, OnRewardTrackProgressGained)

    local function UpdateTamrielTomesAvailability()
        self:UpdateTamrielTomesAvailability()
    end

    local function OnRewardTrackStarted(_, rewardTrackType, rewardTrackId)
        if rewardTrackType == REWARD_TRACK_TYPE_TAMRIEL_TOMES then
            self:UpdateTamrielTomesAvailability()
        end
    end

    -- Note that these same events must also be handled by GamepadMarket and ZO_Market_Keyboard.
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_HOLIDAYS_CHANGED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_UPDATE_RECEIVED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_SETTINGS_UPDATE_RECEIVED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_STARTED, OnRewardTrackStarted)

    function OnCatalogUpdated()
        self:UpdateDirectPurchaseData()
    end

    DIRECT_PURCHASE_MANAGER:RegisterCallback("CatalogUpdated", OnCatalogUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCatalogUpdated)
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
    if not self:AreSavedVarsInitialized() then
        return nil
    end

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

function TamrielTomes_Manager:HasNewTomes()
    local tomeIds = self:GetActiveTomeIds()
    for _, tomeId in ipairs(tomeIds) do
        if not self:HasSeenTome(tomeId) then
            return true
        end
    end

    return false
end

-- Indicates whether there are any Tomes currently available.
function TamrielTomes_Manager:AreTomesAvailable()
    return self:GetNumActiveTomes() > 0
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
    if TAMRIEL_TOMES_MANAGER and not TAMRIEL_TOMES_MANAGER:AreTomesAvailable() then
        tomeId = nil
    elseif tomeId == nil or tomeId == 0 then
        -- Default to the active season's tome.
        tomeId = self:GetActiveTomeId()
    end

    -- TODO Tamriel Tomes: Verify that 'tomeId' is a valid, accessible Tome Id.

    if tomeId ~= self.selectedTomeId then
        -- Order matters
        self.selectedTomeId = tomeId
        self:BuildDirectPurchaseData()
        self:FireCallbacks("SelectedTomeChanged", tomeId)
    end
end

function TamrielTomes_Manager:OpenTamrielTome(tomeId)
    if self:AreTomesAvailable() then
        self:SelectTomeId(tomeId)
        SYSTEMS:ShowScene("tamrielTomes")
        return true
    end
end

function TamrielTomes_Manager:GetFeaturedTomeRewards(tomeId)
    local numRewards = GetNumTamrielTomeFeaturedRewards(tomeId)
    if numRewards == 0 then
        return {}
    end

    local rewardTrackId = GetRewardTrackIdFromReferenceTrackId(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tomeId)
    local rewards = {}
    for rewardIndex = 1, numRewards do
        local rewardTierIndex, rewardComponent, rewardIndex = GetTamrielTomeFeaturedRewardInfo(tomeId, rewardIndex)
        local rewardId, rewardQuantity, rewardCost, rewardDisplayQuality = GetTamrielTomesRewardInfo(rewardTrackId, rewardTierIndex, rewardComponent, rewardIndex)
        local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)
        if rewardData then
            local rewardEntry = ZO_EntryData:New(rewardData)
            table.insert(rewards, rewardEntry)
        end
    end

    return rewards
end

function TamrielTomes_Manager:GetTomePremiumPlusBonusRewardInfo(tomeId)
    local bonusRewardId, bonusRewardQuantity = GetTamrielTomePremiumPlusBonusRewardInfo(tomeId)
    return bonusRewardId, bonusRewardQuantity
end

function TamrielTomes_Manager:GetTomePremiumPlusRewardDescription(tomeId)
    local description = GetTamrielTomePremiumPlusRewardDescription(tomeId)
    return description
end

function TamrielTomes_Manager:UpdateTamrielTomesAvailability()
    -- Refresh the selected Tome to validate the selection now that the Tomes have changed.
    self:SelectTomeId(self.selectedTomeId)

    self:RefreshMainMenus()
end

function TamrielTomes_Manager:RefreshMainMenus()
    MAIN_MENU_GAMEPAD:UpdateEntryEnabledStates()

    if MAIN_MENU_KEYBOARD then
        MAIN_MENU_KEYBOARD:UpdateCategories()
    end
end

function TamrielTomes_Manager:OnCurrencyUpdated(currencyType, currencyLocation, newAmount, oldAmount, reason, reasonSupplementaryInfo)
    if currencyType == CURT_TOME_POINTS then
        self:FireCallbacks("RewardsUpdated")
    end
end

function TamrielTomes_Manager:OnRewardTrackProgressGained(rewardTrackType, referenceTrackId, newTier, newProgress)
    if rewardTrackType == REWARD_TRACK_TYPE_TAMRIEL_TOMES then
        self:FireCallbacks("ProgressUpdated")
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

function TamrielTomes_Manager:IsDirectPurchaseEnabled()
    if not DIRECT_PURCHASE_MANAGER:IsSystemEnabled() then
        return false
    end

    local accountTypeId = GetTrialInfo()
    local isFreeTrial = accountTypeId and accountTypeId ~= 0
    return not isFreeTrial
end

function TamrielTomes_Manager:IsAnySelectedTomeProductAvailableForPurchase()
    for productType, purchaseData in pairs(self.selectedTomePurchaseData) do
        if purchaseData:IsAvailableForPurchase() then
            return true
        end
    end

    return false
end

function TamrielTomes_Manager:AreAllSelectedTomeProductsOwned()
    for productType, purchaseData in pairs(self.selectedTomePurchaseData) do
        if not purchaseData:IsOwned() then
            return false
        end
    end

    return true
end

function TamrielTomes_Manager:CanPurchaseAnySelectedTomeProduct()
    for productType, purchaseData in pairs(self.selectedTomePurchaseData) do
        if purchaseData:CanPurchase() then
            return true
        end
    end

    return false
end

function TamrielTomes_Manager:GetPurchaseDisabledMessage()
    local message = nil
    if self:AreAllSelectedTomeProductsOwned() then
        message = GetString(SI_TAMRIEL_TOMES_UPGRADE_DISABLED_FULLY_UPGRADED)
    elseif not self:IsDirectPurchaseEnabled() then
        message = ZO_ERROR_COLOR:Colorize(GetString(SI_TAMRIEL_TOMES_UPGRADE_DISABLED))
    elseif not self:IsAnySelectedTomeProductAvailableForPurchase() then
        message = GetString(SI_TAMRIEL_TOMES_UPGRADE_DISABLED_NO_SKU_DATA)
    end
    return message
end

function TamrielTomes_Manager:GetPurchaseDataForSelectedTomeProductType(productType)
    local purchaseData = self.selectedTomePurchaseData[productType]
    return purchaseData
end

TAMRIEL_TOMES_MANAGER = TamrielTomes_Manager:New()