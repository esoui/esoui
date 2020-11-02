----
-- MarketAnnouncement_Manager
----

local MarketAnnouncement_Manager = ZO_CallbackObject:Subclass()

function MarketAnnouncement_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function MarketAnnouncement_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("MarketAnnouncement_Manager", EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)

    self.scene = ZO_RemoteScene:New("marketAnnouncement", SCENE_MANAGER)
    self.scene:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)

    self.productInfoTable = {}

    local MARKET_PRODUCT_SORT_KEYS =
    {
        isDeprioritized = { tiebreaker = "announceSortOrder", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        announceSortOrder = { tiebreaker = "isPromo", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        isPromo = { tiebreaker = "isLimitedTime", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        isLimitedTime = {tiebreaker = "timeLeft", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        timeLeft = { isNumeric = true, tiebreaker = "hasActivationRequirement", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        hasActivationRequirement = { tiebreaker = "containsDLC", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        containsDLC = { tiebreaker = "isNew", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        isNew = { tiebreaker = "isOnSale", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        isOnSale = { tiebreaker = "onSaleTimeLeft", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        onSaleTimeLeft = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        name = { tiebreaker = "stackCount", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        stackCount = {}
    }

    function CompareMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "isDeprioritized", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_UP)
    end

    function OnMarketAnnouncementDataUpdated(eventId, aShouldShow, aIsLocked)
        self.isLocked = aIsLocked
        self.productInfoTable = {}

        local numAnnouncementProducts = GetNumMarketAnnouncementProducts()
        if numAnnouncementProducts > 0 then -- future proofing for possible addition of non-market product announcements or just no announcements
            for i = 1, numAnnouncementProducts do
                local productId = GetMarketAnnouncementProductDefId(i)
                local productData = ZO_MarketProductData:New(productId, ZO_FEATURED_PRESENTATION_INDEX)

                -- need to check if the products should show as limited time first instead of just getting the time left
                local isLimitedTime = productData:IsLimitedTimeProduct()
                local isSaleTime = productData:IsLimitedSaleTimeProduct()
                local isDeprioritized = productData:IsDeprioritizeInAnnouncements()
                local discountPercent = select(4, productData:GetMarketProductPricingByPresentation())
                local hasDiscount = discountPercent > 0 or self:HasHouseDiscount(productData)
                local hasActivationRequirement = productData:HasActivationRequirement()
                local announceSortOrder = productData:GetAnnounceSortOrder()
                local productInfo =
                {
                    productData = productData,
                    -- for sorting
                    isLimitedTime = isLimitedTime,
                    timeLeft = isLimitedTime and productData:GetLTOTimeLeftInSeconds() or 0,
                    isNew = productData:IsNew(),
                    name = productData:GetDisplayName(),
                    containsDLC = productData:ContainsDLC(),
                    isPromo = productData:IsPromo(),
                    isOnSale = hasDiscount,
                    onSaleTimeLeft = isSaleTime and productData:GetSaleTimeLeftInSeconds() or 0,
                    stackCount = productData:GetStackCount(),
                    isDeprioritized = isDeprioritized,
                    hasActivationRequirement = hasActivationRequirement,
                    announceSortOrder = announceSortOrder,
                }

                table.insert(self.productInfoTable, productInfo)
            end

            table.sort(self.productInfoTable, CompareMarketProducts)
        end

        self:FireCallbacks("OnMarketAnnouncementDataUpdated")
        if aShouldShow then
            if not self.scene:IsShowing() and not HasShownMarketAnnouncement() then
                SCENE_MANAGER:Show("marketAnnouncement")
            end
        end
    end

    function OnEventAnnouncementsUpdated()
        self:PopulateEventAnnouncements()
        self:FireCallbacks("EventAnnouncementExpired")
    end

    EVENT_MANAGER:RegisterForEvent("EVENT_MARKET_ANNOUNCEMENT_UPDATED", EVENT_MARKET_ANNOUNCEMENT_UPDATED, OnMarketAnnouncementDataUpdated)
    EVENT_MANAGER:RegisterForEvent("EVENT_EVENT_ANNOUNCEMENTS_UPDATED", EVENT_EVENT_ANNOUNCEMENTS_UPDATED, OnEventAnnouncementsUpdated)
    EVENT_MANAGER:RegisterForEvent("EVENT_EVENT_ANNOUNCEMENTS_RECEIVED", EVENT_EVENT_ANNOUNCEMENTS_RECEIVED, OnEventAnnouncementsUpdated)
end

function MarketAnnouncement_Manager:GetProductInfoTable()
    return self.productInfoTable
end

function MarketAnnouncement_Manager:GetMarketProductListingsForHouseTemplate(houseTemplateId, displayGroup)
    return { GetActiveAnnouncementMarketProductListingsForHouseTemplate(houseTemplateId) }
end

function MarketAnnouncement_Manager:HasHouseDiscount(productData)
    if productData:IsHouseCollectible() then
        local houseDiscountPercent = select(4, ZO_MarketProduct_GetDefaultHousingTemplatePricingInfo(productData:GetId(), function(...) return self:GetMarketProductListingsForHouseTemplate(...) end))
        -- houseDiscountPercent could come back as nil if there is no market listing currently available for the market product
        return houseDiscountPercent and houseDiscountPercent > 0 or false
    end
    return false
end

function MarketAnnouncement_Manager:OnPlayerActivated()
    self:PopulateEventAnnouncements()

    -- Attempt to show on region change if announcement has not yet been shown today for this character
    if not HasShownMarketAnnouncement() then
        local currentTrialVersion, seenTrialVersion = select(4, ZO_TrialAccount_GetInfo())
        if seenTrialVersion < currentTrialVersion then
            FlagMarketAnnouncementSeen() --We only want to show one popup per session if possible, and trial dialog takes priority
        else
            RequestMarketAnnouncement()
        end
    end
end

function MarketAnnouncement_Manager:OnStateChanged(oldState, newState)
    if newState == SCENE_HIDING then
        FlagMarketAnnouncementSeen()
    end
end

function MarketAnnouncement_Manager:PopulateEventAnnouncements()
    self.eventAnnouncements = {}
    local numEventAnnouncements = GetNumEventAnnouncements()
    for i = 1, numEventAnnouncements do
        local data =
        {
            index = i,
            name = GetEventAnnouncementNameByIndex(i),
            description = GetEventAnnouncementDescriptionByIndex(i),
            tileImage = GetEventAnnouncementIngameTileImageByIndex(i),
            startTime = GetEventAnnouncementStartTimeByIndex(i),
            remainingTime = GetEventAnnouncementRemainingTimeByIndex(i),
            marketProductId = GetEventAnnouncementIngameTileMarketProductIdByIndex(i),
        }
        table.insert(self.eventAnnouncements, data)
    end
end

function MarketAnnouncement_Manager:GetNumEventAnnouncements()
    return self.eventAnnouncements and #self.eventAnnouncements or 0
end

function MarketAnnouncement_Manager:GetEventAnnouncementDataByIndex(index)
    return self.eventAnnouncements and self.eventAnnouncements[index]
end

function MarketAnnouncement_Manager:GetEventAnnouncementRemainingTimeByIndex(index)
    local eventAnnouncementData = self.eventAnnouncements and self.eventAnnouncements[index]
    local remainingTime = GetEventAnnouncementRemainingTimeByIndex(index)
    if eventAnnouncementData then
        eventAnnouncementData.remainingTime = remainingTime
    end

    return remainingTime
end

ZO_MARKET_ANNOUNCEMENT_MANAGER = MarketAnnouncement_Manager:New()