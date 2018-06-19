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
        isPromo = { tiebreaker = "isLimitedTime", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        isLimitedTime = {tiebreaker = "timeLeft", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        timeLeft = {isNumeric = true, tiebreaker = "containsDLC", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        containsDLC = { tiebreaker = "isNew", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        isNew = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        name = {},
    }

    function CompareMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "isPromo", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_DOWN)
    end

    OnMarketAnnouncementDataUpdated = function(eventId, aShouldShow, aIsLocked)
        self.isLocked = aIsLocked
        self.productInfoTable = {}

        local numAnnouncementProducts = GetNumMarketAnnouncementProducts()
        if numAnnouncementProducts > 0 then --future proofing for likely addition of text-only announcements
            for i = 1, numAnnouncementProducts do
                local productId = GetMarketAnnouncementProductDefId(i)

                local name, _, _, isNew, _ = GetMarketProductInfo(productId)
                local timeLeft = GetMarketProductTimeLeftInSeconds(productId)
                local containsDLC = DoesMarketProductContainDLC(productId)
                -- durations longer than 1 month aren't represented to the user, so it's effectively not limited time
                local isLimitedTime = timeLeft > 0 and timeLeft <= ZO_ONE_MONTH_IN_SECONDS
                local isPromo = GetMarketProductType(productId) == MARKET_PRODUCT_TYPE_PROMO
                local productInfo = {
                                        productId = productId,
                                        isLimitedTime = isLimitedTime,
                                        timeLeft = isLimitedTime and timeLeft or 0,
                                        isNew = isNew,
                                        name = name,
                                        containsDLC = containsDLC,
                                        isPromo = isPromo,
                                    }

                table.insert(self.productInfoTable, productInfo)
            end

            table.sort(self.productInfoTable, CompareMarketProducts)
        end
    
        self:FireCallbacks("OnMarketAnnouncementDataUpdated")
        if aShouldShow or GetDailyLoginClaimableRewardIndex() ~= nil then
            if not self.scene:IsShowing() and not HasShownMarketAnnouncement() then
                SCENE_MANAGER:Show("marketAnnouncement")
            end
        end
    end

    EVENT_MANAGER:RegisterForEvent("EVENT_MARKET_ANNOUNCEMENT_UPDATED", EVENT_MARKET_ANNOUNCEMENT_UPDATED, OnMarketAnnouncementDataUpdated) 
end

function MarketAnnouncement_Manager:OnPlayerActivated()
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

ZO_MARKET_ANNOUNCEMENT_MANAGER = MarketAnnouncement_Manager:New()