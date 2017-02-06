ZO_HousingPreview_Manager = ZO_CallbackObject:Subclass()

function ZO_HousingPreview_Manager:New(...)
    local singleton = ZO_CallbackObject.New(self)
    singleton:Initialize(...)
    return singleton
end

function ZO_HousingPreview_Manager:Initialize()
    self.houseStoreData = {}
    self.houseMarketData = {}
    self.fullDataKeyed = {}
    self.fullDataSorted = {}
    self.displayInfo = {}
    self:RegisterForEvents()
end

function ZO_HousingPreview_Manager:RegisterForEvents()
    local function OnPlayerActivated()
        local zoneHouseId = GetCurrentZoneHouseId()
        if zoneHouseId > 0 then
            local collectibleId = GetCollectibleIdForHouse(zoneHouseId)
            local displayInfo = self.displayInfo
            local houseName = GetCollectibleName(collectibleId)
            displayInfo.houseName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, houseName)
            local foundInZoneId = GetHouseFoundInZoneId(zoneHouseId)
            displayInfo.houseFoundInLocation = GetZoneNameById(foundInZoneId)
            local houseCategory = GetHouseCategoryType(zoneHouseId)
            displayInfo.houseCategory = GetString("SI_HOUSECATEGORYTYPE", houseCategory)
            displayInfo.backgroundImage = GetHousePreviewBackgroundImage(zoneHouseId)
            self:FireCallbacks("OnPlayerActivated")
        else
            ZO_ClearTable(self.displayInfo)
        end
    end

    local function OnOpenHouseStore()
        if SYSTEMS:GetObject("HOUSING_PREVIEW"):IsShowing() then
            self:UpdateHouseStoreData()
            EndInteraction(INTERACTION_VENDOR)
        end
    end

    local function OnMarketStateUpdated(eventCode, displayGroup, marketState)
        if displayGroup == MARKET_DISPLAY_GROUP_HOUSE_PREVIEW then
            self:UpdateHouseMarketData(marketState)
        end
    end

    EVENT_MANAGER:RegisterForEvent("ZO_HousingPreview_Manager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    EVENT_MANAGER:RegisterForEvent("ZO_HousingPreview_Manager", EVENT_OPEN_HOUSE_STORE, OnOpenHouseStore)
    EVENT_MANAGER:RegisterForEvent("ZO_HousingPreview_Manager", EVENT_MARKET_STATE_UPDATED, OnMarketStateUpdated)
    EVENT_MANAGER:RegisterForEvent("ZO_HousingPreview_Manager", EVENT_CLOSE_STORE, function(eventCode) self:FireCallbacks("HouseStoreInteractEnd") end)
end

function ZO_HousingPreview_Manager:UpdateHouseStoreData()
    ZO_ClearNumericallyIndexedTable(self.houseStoreData)
    for entryIndex = 1, GetNumStoreItems() do
        local _, name, _, price, _, meetsRequirementsToBuy, _, _, _, _, _, _, _, entryType = GetStoreEntryInfo(entryIndex)

        if entryType == STORE_ENTRY_TYPE_HOUSE_WITH_TEMPLATE then
            local houseTemplateId = GetStoreEntryHouseTemplateId(entryIndex)
            local requirementsToBuyErrorId = not meetsRequirementsToBuy and GetStoreEntryBuyRequirementErrorId(entryIndex) or nil
            local houseTemplateData =
            {
                goldStoreEntryIndex = entryIndex,
                houseTemplateId = houseTemplateId,
                name = name,
                goldPrice = price,
                requirementsToBuyErrorId = requirementsToBuyErrorId,
            }

            table.insert(self.houseStoreData, houseTemplateData)
        end
    end

    self:RefreshFullHouseTemplateData()
end

local PRODUCT_LISTINGS_STRIDE = 2
function ZO_HousingPreview_Manager:UpdateHouseMarketData(marketState)
    if not marketState then
        marketState = GetMarketState(MARKET_DISPLAY_GROUP_HOUSE_PREVIEW)
    end

    ZO_ClearNumericallyIndexedTable(self.houseMarketData)

    if marketState == MARKET_STATE_OPEN then
        local zoneHouseId = GetCurrentZoneHouseId()
        if zoneHouseId > 0 then
            for index = 1, GetNumHouseTemplatesForHouse(zoneHouseId) do
                local houseTemplateId = GetHouseTemplateIdByIndexForHouse(zoneHouseId, index)
                local marketProductListings = { GetActiveMarketProductListingsForHouseTemplate(houseTemplateId, MARKET_DISPLAY_GROUP_HOUSE_PREVIEW) }

                if #marketProductListings > 0 then
                    local houseTemplateData =
                    {
                        houseTemplateId = houseTemplateId,
                        marketPurchaseOptions = { }
                    }

                    --There could be multiple listings per template, one for each currency type.
                    for i = 1, #marketProductListings, PRODUCT_LISTINGS_STRIDE do
                        local marketProductId = marketProductListings[i]
                        local presentationIndex = marketProductListings[i + 1]

                        local currencyType, _, _, costAfterDiscount = GetMarketProductPricingByPresentation(marketProductId, presentationIndex)

                        --Don't allow the same currency twice.  This is a nonsense scenario but technically possible.
                        if not houseTemplateData.marketPurchaseOptions[currencyType] then
                            local marketPurchaseData =
                            {
                                marketProductId = marketProductId,
                                presentationIndex = presentationIndex,
                                cost = costAfterDiscount,
                            }
                            houseTemplateData.marketPurchaseOptions[currencyType] = marketPurchaseData
                            houseTemplateData.name = houseTemplateData.name or GetMarketProductDisplayName(marketProductId)
                        end
                    end

                    table.insert(self.houseMarketData, houseTemplateData)
                end
            end
        end
    end

    self:RefreshFullHouseTemplateData()
end

function ZO_HousingPreview_Manager:AddTemplateDataToFullLists(templateData)
    local copiedTemplateData = ZO_ShallowTableCopy(templateData)
    self.fullDataKeyed[templateData.houseTemplateId] = copiedTemplateData
    table.insert(self.fullDataSorted, copiedTemplateData)
end

function ZO_HousingPreview_Manager:RefreshFullHouseTemplateData()
    ZO_ClearTable(self.fullDataKeyed)
    ZO_ClearNumericallyIndexedTable(self.fullDataSorted)

    for i, templateData in ipairs(self.houseStoreData) do
        self:AddTemplateDataToFullLists(templateData)
    end

    for i, templateData in ipairs(self.houseMarketData) do
        local existingData = self.fullDataKeyed[templateData.houseTemplateId]
        if existingData then
            existingData.marketPurchaseOptions = templateData.marketPurchaseOptions
        else
            self:AddTemplateDataToFullLists(templateData)
        end
    end

    self:FireCallbacks("OnHouseTemplateDataUpdated")
end

function ZO_HousingPreview_Manager:GetDisplayInfo()
    return self.displayInfo
end

function ZO_HousingPreview_Manager:GetFullHouseTemplateData()
    return self.fullDataSorted
end

function ZO_HousingPreview_Manager:RequestOpenMarket()
    OpenMarket(MARKET_DISPLAY_GROUP_HOUSE_PREVIEW)
    local marketState = GetMarketState(MARKET_DISPLAY_GROUP_HOUSE_PREVIEW)
    if marketState == MARKET_STATE_OPEN then
        self:UpdateHouseMarketData(marketState)
    end
end

HOUSE_PREVIEW_MANAGER = ZO_HousingPreview_Manager:New()