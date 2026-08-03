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
            self:FireCallbacks("RewardTrackStarted", rewardTrackId)
        end
    end

    -- Note that these same events must also be handled by GamepadMarket and ZO_Market_Keyboard.
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_HOLIDAYS_CHANGED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_UPDATE_RECEIVED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_SETTINGS_UPDATE_RECEIVED, UpdateTamrielTomesAvailability)
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_REWARD_TRACK_STARTED, OnRewardTrackStarted)

    local function OnCatalogUpdated()
        self:UpdateDirectPurchaseData()
        self:UpdateTamrielTomesAvailability()
    end

    DIRECT_PURCHASE_MANAGER:RegisterCallback("CatalogUpdated", OnCatalogUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCatalogUpdated)

    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_GUI_UNLOADING, function()
        -- make sure to hide any on screen platform store icon in case the UI is reloaded while the icon is showing
        if HidePlatformStoreIcon then
            HidePlatformStoreIcon()
        end
    end)

    local function OnPlayerActivated()
        -- restore the platform store icon if necessary after a UI reload
        if ShowPlatformStoreIcon and SYSTEMS:IsShowing("tamrielTomesPurchase") then
            ShowPlatformStoreIcon(PLATFORM_STORE_ICON_LOCATION_LOWER_RIGHT)
        end
    end
    EVENT_MANAGER:RegisterForEvent("TamrielTomes_Manager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

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
        local wasNew = tomeSavedVars.lastSeenTimestamp == nil
        tomeSavedVars.lastSeenTimestamp = GetTimeStamp()

        if wasNew then
            self:FireCallbacks("NewTomeSeen", tomeId)
        end
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

-- Returns the first active Tome Id, if any, or nil.
function TamrielTomes_Manager:GetActiveTomeId()
    local activeTomeIds = self:GetActiveTomeIds()
    return activeTomeIds[1]
end

-- Returns the active season Tome Id(s).
-- Note that there should typically only be, at most, one.
function TamrielTomes_Manager:GetActiveTomeIds()
    if not IsTamrielTomesEnabled() then
        return {}
    end

    local activeTomeIds = { GetActiveReferenceTrackIdsForRewardTrackType(REWARD_TRACK_TYPE_TAMRIEL_TOMES) }
    return activeTomeIds
end

-- Returns the number of active Tomes.
function TamrielTomes_Manager:GetNumActiveTomes()
    return #self:GetActiveTomeIds()
end

-- Returns true if the specified Tome Id is the currently active season.
function TamrielTomes_Manager:IsTomeActive(tomeId)
    local activeTomeIds = self:GetActiveTomeIds()
    return ZO_IsElementInNumericallyIndexedTable(activeTomeIds, tomeId)
end

-- Indicates whether there are any Tomes currently available.
function TamrielTomes_Manager:AreTomesAvailable()
    return self:GetNumAvailableTomes() > 0
end

-- Returns the number of available Tomes.
function TamrielTomes_Manager:GetNumAvailableTomes()
    local numAvailableTomes = #self:GetAvailableTomeIds()
    return numAvailableTomes
end

-- Returns all accessible Tome Ids that are available to view.
function TamrielTomes_Manager:GetAvailableTomeIds()
    if not IsTamrielTomesEnabled() then
        return {}
    end

    local availableTomeIds = {}
    local numAvailableTomes = GetNumReferenceTracksForType(REWARD_TRACK_TYPE_TAMRIEL_TOMES)
    for tomeIndex = 1, numAvailableTomes do
        local tomeId = GetReferenceTrackIdFromIndex(REWARD_TRACK_TYPE_TAMRIEL_TOMES, tomeIndex)
        table.insert(availableTomeIds, tomeId)
    end
    return availableTomeIds
end

-- Returns true if the specified Tome Id is accessible and available to view.
function TamrielTomes_Manager:IsTomeAvailable(tomeId)
    local availableTomeIds = self:GetAvailableTomeIds()
    return ZO_IsElementInNumericallyIndexedTable(availableTomeIds, tomeId)
end

-- Indicates whether a valid Tome Id is selected.
function TamrielTomes_Manager:HasSelectedTomeId()
    return self.selectedTomeId ~= nil
end

-- Indicates whether the selected Tome Id is the active season Tome Id.
function TamrielTomes_Manager:IsActiveTomeSelected()
    return self.selectedTomeId == self:GetActiveTomeId()
end

-- Returns the selected Tome Id, if any.
function TamrielTomes_Manager:GetSelectedTomeId()
    return self.selectedTomeId
end

-- Returns true if an End of Season recap is available to view.
function TamrielTomes_Manager:HasEndOfSeasonRecap()
    return HasTamrielTomesEndOfSeasonRecap()
end

-- Returns true if an End of Season recap that has not yet been seen by the player is available to view.
function TamrielTomes_Manager:HasNewEndOfSeasonRecap()
    return self:HasEndOfSeasonRecap() and not HasPlayerSeenTamrielTomesEndOfSeasonRecap()
end

-- Returns true if the currently active season Tome has not yet been seen by the player.
function TamrielTomes_Manager:IsCurrentSeasonTamrielTomeNew()
    local currentSeasonTomeId = self:GetActiveTomeId()
    if not (currentSeasonTomeId and currentSeasonTomeId ~= 0) then
        return false
    end

    return not self:HasSeenTome(currentSeasonTomeId)
end

function TamrielTomes_Manager:SelectTomeId(tomeId)
    if not self:AreTomesAvailable() then
        tomeId = nil
    elseif tomeId == nil or tomeId == 0 then
        -- Default to the active season's tome.
        tomeId = self:GetActiveTomeId()

        if tomeId == nil or tomeId == 0 then
            local availableTomeIds = self:GetAvailableTomeIds()
            if #availableTomeIds ~= 0 then
                -- Fallback to the first available season's tome.
                tomeId = availableTomeIds[1]
            end
        end
    end

    if tomeId and not self:IsTomeAvailable(tomeId) then
        -- The specified tome is neither the active season's tome nor an accessible tome from a past season.
        tomeId = nil
    end

    if tomeId ~= self.selectedTomeId then
        -- Order matters
        self.selectedTomeId = tomeId
        self:BuildDirectPurchaseData()
        self:FireCallbacks("SelectedTomeChanged", tomeId)
    end
end

function TamrielTomes_Manager:OpenTamrielTome(tomeId, showIntro)
    if self:AreTomesAvailable() then
        self:SelectTomeId(tomeId)

        SYSTEMS:GetObject("mainMenu"):ToggleCategory(MENU_CATEGORY_TAMRIEL_TOMES)
        return true
    end

    return false
end

function TamrielTomes_Manager:OpenCurrentSeasonTamrielTome(showIntro)
    local currentSeasonTomeId = self:GetActiveTomeId()
    if not (currentSeasonTomeId and currentSeasonTomeId ~= 0) then
        return false
    end

    return self:OpenTamrielTome(currentSeasonTomeId, showIntro)
end

function TamrielTomes_Manager:TryOpenNewSeasonTamrielTome(showIntro)
    if self:IsCurrentSeasonTamrielTomeNew() then
        return self:OpenCurrentSeasonTamrielTome(showIntro)
    end

    return false
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
    self:FireCallbacks("AvailableTomesChanged")
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
    local isFreeTrial = accountTypeId > 0
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
    elseif not self:IsTomeActive(self:GetSelectedTomeId()) then
        message = GetString(SI_TAMRIEL_TOMES_UPGRADE_CANNOT_UPGRADE_PAST_TOME)
    elseif not self:IsAnySelectedTomeProductAvailableForPurchase() then
        message = GetString(SI_TAMRIEL_TOMES_UPGRADE_DISABLED_NO_SKU_DATA)
    end
    return message
end

function TamrielTomes_Manager:GetPurchaseDataForSelectedTomeProductType(productType)
    local purchaseData = self.selectedTomePurchaseData[productType]
    return purchaseData
end

-- The price(s) returned have been processed by grammar.
function TamrielTomes_Manager:GetPricingInfoFormattedForSelectedTomeProductType(productType)
    local purchaseData = self:GetPurchaseDataForSelectedTomeProductType(productType)
    local purchaseSkuData = purchaseData and purchaseData:GetSkuData() or nil
    if not purchaseSkuData then
        return nil
    end

    local currentPriceString, basePriceString = purchaseSkuData:GetPricingInfoFormatted()
    if productType ~= TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM_PLUS_UPGRADE then
        -- Return the prices unabridged for non-Premium Plus Upgrade products.
        return currentPriceString, basePriceString
    end

    -- Look up the price data for the Premium Plus product.
    local premiumPlusPurchaseData = self:GetPurchaseDataForSelectedTomeProductType(TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM_PLUS)
    local premiumPlusPurchaseSkuData = premiumPlusPurchaseData and premiumPlusPurchaseData:GetSkuData() or nil
    if not premiumPlusPurchaseSkuData then
        -- Fall back to the Premium Plus Upgrade pricing.
        return currentPriceString, basePriceString
    end

    local _, premiumPlusBasePriceString = premiumPlusPurchaseSkuData:GetPricingInfoFormatted()
    if not premiumPlusBasePriceString or premiumPlusBasePriceString == "" then
        -- Fall back to the Premium Plus Upgrade pricing.
        return currentPriceString, basePriceString
    end

    -- Override the Premium Plus Upgrade base price with the Premium Plus base price.
    return currentPriceString, premiumPlusBasePriceString
end

-- The price(s) returned have been processed by grammar.
function TamrielTomes_Manager:GetPricingStringFormattedForSelectedTomeProductType(productType)
    local currentPriceString, basePriceString = self:GetPricingInfoFormattedForSelectedTomeProductType(productType)
    if currentPriceString == basePriceString or not basePriceString or basePriceString == "" then
        return currentPriceString
    end

    return string.format("%s %s", zo_strikethroughTextFormat(basePriceString), currentPriceString)
end

TAMRIEL_TOMES_MANAGER = TamrielTomes_Manager:New()