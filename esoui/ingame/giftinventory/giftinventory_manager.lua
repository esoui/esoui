ZO_Gift_Base = ZO_Object:Subclass()

--Gift Base

function ZO_Gift_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Gift_Base:Initialize(giftId, state, seen, marketProductId, senderName, recipientName, expirationTimeStampS, note, quantity)
    self.giftId = giftId
    self.state = state
    self.seen = seen
    self.marketProductId = marketProductId
    self.quantity = quantity
    self:SetPlayerName(senderName, recipientName)
    self.expirationTimeStampS = expirationTimeStampS
    self.note = note
    local description
    self.name, description, self.icon = GetMarketProductInfo(marketProductId)
    self.stackCount = GetMarketProductStackCount(marketProductId)
    self.qualityColor = GetItemQualityColor(GetMarketProductDisplayQuality(marketProductId))

    local color = GetItemQualityColor(GetMarketProductDisplayQuality(marketProductId))
    local houseId = GetMarketProductHouseId(marketProductId)
    if houseId > 0 then
        local houseCollectibleId = GetCollectibleIdForHouse(houseId)
        local houseDisplayName = GetCollectibleName(houseCollectibleId)
        self.formattedName = self.qualityColor:Colorize(ZO_CachedStrFormat(SI_MARKET_PRODUCT_HOUSE_NAME_FORMATTER, houseDisplayName, self.name))
    else
        self.formattedName = ZO_CachedStrFormat(SI_MARKET_PRODUCT_NAME_FORMATTER, self.qualityColor:Colorize(self.name))
    end
end

function ZO_Gift_Base:GetGiftId()
    return self.giftId
end

function ZO_Gift_Base:GetMarketProductId()
    return self.marketProductId
end

function ZO_Gift_Base:GetQuantity()
    return self.quantity
end

function ZO_Gift_Base:GetClaimQuantity()
    return GetGiftClaimableQuantity(self.giftId)
end

function ZO_Gift_Base:GetQualityColor()
    return self.qualityColor
end

function ZO_Gift_Base:GetName()
    return self.name
end

function ZO_Gift_Base:GetFormattedName()
    return self.formattedName
end

function ZO_Gift_Base:GetIcon()
    return self.icon
end

function ZO_Gift_Base:GetStackCount()
    return self.stackCount
end

function ZO_Gift_Base:SetPlayerName(senderName, recipientName)
    assert(false) -- Must be overriden
end

function ZO_Gift_Base:GetPlayerName()
    return self.playerName
end

function ZO_Gift_Base:GetUserFacingPlayerName()
    return ZO_FormatUserFacingDisplayName(self.playerName)
end

function ZO_Gift_Base:GetState()
    return self.state
end

function ZO_Gift_Base:IsState(state)
    return self.state == state
end

function ZO_Gift_Base:HasBeenSeen()
    return self.seen
end

function ZO_Gift_Base:GetNote()
    return self.note
end

function ZO_Gift_Base:AreGiftIdsEqual(gift)
    return AreId64sEqual(self.giftId, gift.giftId)
end

function ZO_Gift_Base:GetSecondsUntilExpiration()
    return zo_max(0, self.expirationTimeStampS - os.time())
end

function ZO_Gift_Base:View()
    ViewGifts(self.giftId)
end

function ZO_Gift_Base:CanMarkViewedFromList()
    -- Some gifts can be considered viewed simply by seeing/selecting them in a list, without requiring any kind of interaction
    return not self:HasBeenSeen()
end

--Received Gift

ZO_ReceivedGift = ZO_Gift_Base:Subclass()

function ZO_ReceivedGift:New(...)
    return ZO_Gift_Base.New(self, ...)
end

function ZO_ReceivedGift:TakeGift(note)
    TakeGift(self.giftId, note)
end

function ZO_ReceivedGift:ReturnGift(note)
    ReturnGift(self.giftId, note)
end

function ZO_ReceivedGift:GetGiftBoxIcon()
    -- Leaving this as a function in case we add "dynamic" gift icons in the future
    return "EsoUI/Art/Icons/Gift_Box_003.dds"
end

function ZO_ReceivedGift:SetPlayerName(senderName, recipientName)
    self.playerName = senderName
end

function ZO_ReceivedGift:CanMarkViewedFromList()
    return false
end

--Returned Gift

ZO_ReturnedGift = ZO_Gift_Base:Subclass()

function ZO_ReturnedGift:New(...)
    return ZO_Gift_Base.New(self, ...)
end

function ZO_ReturnedGift:RequestResendGift()
    RequestResendGift(self.giftId)
end

function ZO_ReturnedGift:SetPlayerName(senderName, recipientName)
    self.playerName = recipientName
end

--Thanked Gift

ZO_ThankedGift = ZO_Gift_Base:Subclass()

function ZO_ThankedGift:New(...)
    return ZO_Gift_Base.New(self, ...)
end

function ZO_ThankedGift:DeleteGift()
    DeleteGift(self.giftId)
end

function ZO_ThankedGift:SetPlayerName(senderName, recipientName)
    self.playerName = recipientName
end

function ZO_ThankedGift:CanMarkViewedFromList()
    if self:GetNote() == "" then
        return ZO_Gift_Base.CanMarkViewedFromList(self)
    end
    return false
end

--Sent Gift

ZO_SentGift = ZO_Gift_Base:Subclass()

function ZO_SentGift:New(...)
    return ZO_Gift_Base.New(self, ...)
end

function ZO_SentGift:SetPlayerName(senderName, recipientName)
    self.playerName = recipientName
end

function ZO_SentGift:CanMarkViewedFromList()
    -- Sent gifts are never unseen
    return false
end


--Gift Manager

--These change types are ordered. A higher number includes the possibility of a lower number change as well.
--Gifts were added to or removed from a list
ZO_GIFT_LIST_CHANGE_TYPE_LIST = 2
--Gifts in a list changed seen state
ZO_GIFT_LIST_CHANGE_TYPE_SEEN = 1

function ZO_GetNextGiftIdIter(state, var1)
    return GetNextGiftId(var1)
end

ZO_GiftInventory_Manager = ZO_CallbackObject:Subclass()

function ZO_GiftInventory_Manager:New()
    local object = ZO_CallbackObject.New(self)
    object:Initialize()
    return object
end

function ZO_GiftInventory_Manager:Initialize()
    self.giftsByState = {}
    for state = GIFT_STATE_ITERATION_BEGIN, GIFT_STATE_ITERATION_END do
        self.giftsByState[state] = {}
    end

    EVENT_MANAGER:RegisterForEvent("GiftInventoryManager", EVENT_GIFTS_UPDATED, function() self:OnGiftsUpdated() end)
    EVENT_MANAGER:RegisterForEvent("GiftInventoryManager", EVENT_GIFT_ACTION_RESULT, function(eventId, ...) self:OnGiftActionResult(...) end)
    EVENT_MANAGER:RegisterForEvent("GiftInventoryManager", EVENT_REQUEST_SHOW_GIFT_INVENTORY, function(eventId, ...) self.ShowGiftInventory(...) end)

    self:OnGiftsUpdated()
end

-- ... are gift states that you care about
function ZO_GiftInventory_Manager:GetHighestChangeType(changedLists, ...)
    local highestChangeType
    for i = 1, select("#", ...) do
        local state = select(i, ...)
        local changeType = changedLists[state]
        if changeType then
            if not highestChangeType then
                highestChangeType = changeType
            else
                highestChangeType = zo_max(changeType, highestChangeType)
            end
        end
    end
    return highestChangeType
end

function ZO_GiftInventory_Manager:GetGiftList(state)
    return self.giftsByState[state]
end

function ZO_GiftInventory_Manager:CreateGiftObject(giftId)
    local state, seen, marketProductId, senderName, recipientName, expirationTimeStampS, note, quantity = GetGiftInfo(giftId)
    local class
    if state == GIFT_STATE_RECEIVED then
        class = ZO_ReceivedGift
    elseif state == GIFT_STATE_RETURNED then
        class = ZO_ReturnedGift
    elseif state == GIFT_STATE_THANKED then
        class = ZO_ThankedGift
    elseif state == GIFT_STATE_SENT then
        class = ZO_SentGift
    end
    return class:New(giftId, state, seen, marketProductId, senderName, recipientName, expirationTimeStampS, note, quantity)
end

function ZO_GiftInventory_Manager:AddGiftToTemporaryUpdatedGiftList(temporaryUpdatedGiftsByState, giftId)
    local gift = self:CreateGiftObject(giftId)
    local state = gift:GetState()
    local temporaryUpdatedGiftsList = temporaryUpdatedGiftsByState[state]
    table.insert(temporaryUpdatedGiftsList, gift)
end

function ZO_GiftInventory_Manager:UpdateGiftListByState(state, temporaryUpdatedGiftsList)
    local oldGiftsList = self.giftsByState[state]
    local listChangeType

    if #oldGiftsList ~= #temporaryUpdatedGiftsList then
        listChangeType = ZO_GIFT_LIST_CHANGE_TYPE_LIST
    else
        for _, oldGift in ipairs(oldGiftsList) do
            local foundUpdatedGiftInOldGifts = false
            for _, updatedGift in ipairs(temporaryUpdatedGiftsList) do
                if oldGift:AreGiftIdsEqual(updatedGift) then
                    foundUpdatedGiftInOldGifts = true
                    if oldGift:HasBeenSeen() ~= updatedGift:HasBeenSeen() then
                        listChangeType = ZO_GIFT_LIST_CHANGE_TYPE_SEEN
                        oldGift.seen = updatedGift.seen
                    end
                    break
                end
            end
            if not foundUpdatedGiftInOldGifts then
                listChangeType = ZO_GIFT_LIST_CHANGE_TYPE_LIST
                break
            end
        end
    end

    if listChangeType == ZO_GIFT_LIST_CHANGE_TYPE_LIST then
        self.giftsByState[state] = temporaryUpdatedGiftsList
    end
    return listChangeType
end

function ZO_GiftInventory_Manager:OnGiftsUpdated()
    local temporaryUpdatedGiftsByState = {}
    for state = GIFT_STATE_ITERATION_BEGIN, GIFT_STATE_ITERATION_END do
        temporaryUpdatedGiftsByState[state] = {}
    end

    for giftId in ZO_GetNextGiftIdIter do
        self:AddGiftToTemporaryUpdatedGiftList(temporaryUpdatedGiftsByState, giftId)
    end

    local changedLists = {}
    local hasAtLeastOneChangedList = false
    for state, temporaryUpdatedGiftsList in pairs(temporaryUpdatedGiftsByState) do
        local listChangeType = self:UpdateGiftListByState(state, temporaryUpdatedGiftsList)
        if listChangeType then
            hasAtLeastOneChangedList = true
            changedLists[state] = listChangeType
        end
    end

    if hasAtLeastOneChangedList then
        self:FireCallbacks("GiftListsChanged", changedLists)
    end
end

function ZO_GiftInventory_Manager:OnGiftActionResult(giftAction, result, giftId)
    self:FireCallbacks("GiftActionResult", giftAction, result, giftId)
end

function ZO_GiftInventory_Manager:HasAnyUnseenGiftsByState(state)
    local gifts = self.giftsByState[state]
    if gifts then
        for _, gift in ipairs(gifts) do
            if not gift:HasBeenSeen() then
                return true
            end
        end
    end
    return false
end

function ZO_GiftInventory_Manager:HasAnyUnseenGifts()
    for state = GIFT_STATE_ITERATION_BEGIN, GIFT_STATE_ITERATION_END do
        if self:HasAnyUnseenGiftsByState(state) then
            return true
        end
    end
    return false
end

--Comparators

do
    local SORTS =
    {
        ["seen"] =
        {
            ["seen"] = { tiebreaker = "expirationTimeStampS" },
            ["expirationTimeStampS"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["playerName"] =
        {
            ["playerName"] = { tiebreaker = "seen", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            ["seen"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["expirationTimeStampS"] =
        {
            ["expirationTimeStampS"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
    }

    function ZO_GiftInventory_Manager.CompareReceived(leftGift, rightGift, sortKey, sortOrder)
        return ZO_TableOrderingFunction(leftGift, rightGift, sortKey, SORTS[sortKey], sortOrder)
    end
end

do
    local SORTS =
    {
        ["seen"] =
        {
            ["seen"] = { tiebreaker = "expirationTimeStampS" },
            ["expirationTimeStampS"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["playerName"] =
        {
            ["playerName"] = { tiebreaker = "seen", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            ["seen"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["name"] =
        {
            ["name"] = { tiebreaker = "seen", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            ["seen"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["expirationTimeStampS"] =
        {
            ["expirationTimeStampS"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["state"] =
        {
            ["state"] = { tiebreaker = "expirationTimeStampS" },
            ["expirationTimeStampS"] = { tiebreaker = "giftId", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            ["giftId"] = { isId64 = true },
        },
    }

    function ZO_GiftInventory_Manager.CompareSent(leftGift, rightGift, sortKey, sortOrder)
        return ZO_TableOrderingFunction(leftGift, rightGift, sortKey, SORTS[sortKey], sortOrder)
    end
end

do
    local SORTS =
    {
        ["seen"] =
        {
            ["seen"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["playerName"] =
        {
            ["playerName"] = { tiebreaker = "seen", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            ["seen"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
        ["name"] =
        {
            ["name"] = { tiebreaker = "seen", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            ["seen"] = { tiebreaker = "giftId" },
            ["giftId"] = { isId64 = true },
        },
    }

    function ZO_GiftInventory_Manager.CompareReturned(leftGift, rightGift, sortKey, sortOrder)
        return ZO_TableOrderingFunction(leftGift, rightGift, sortKey, SORTS[sortKey], sortOrder)
    end
end

function ZO_GiftInventory_Manager.ShowGiftInventory(giftState)
    local mainMenu = SYSTEMS:GetObject("mainMenu")
    if IsInGamepadPreferredMode() then
        GIFT_INVENTORY_GAMEPAD:SetSelectedCategoryByGiftState(giftState)
        mainMenu:ShowCategory(MENU_CATEGORY_GIFT_INVENTORY)
    else
        GIFT_INVENTORY_KEYBOARD:SetSelectedCategoryByGiftState(giftState)
        mainMenu:ShowSceneGroup("marketSceneGroup", "giftInventoryKeyboard")
    end
end

GIFT_INVENTORY_MANAGER = ZO_GiftInventory_Manager:New()