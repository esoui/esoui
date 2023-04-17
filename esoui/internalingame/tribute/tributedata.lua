--These are piles we want to sort so the user does not know the order of the cards
local PILES_WITH_SECRET_ORDER =
{
    [TRIBUTE_BOARD_LOCATION_PLAYER_DECK] = true,
    [TRIBUTE_BOARD_LOCATION_OPPONENT_DECK] = true,
    [TRIBUTE_BOARD_LOCATION_OPPONENT_HAND] = true,
    [TRIBUTE_BOARD_LOCATION_DOCKS_DECK] = true,
}

local function CompareSecretOrderedEntries(left, right)
    -- Compare patrons
    if left.patronId == right.patronId then
        -- If the patron ids are the same, compare the name
        if left.name == right.name then
            -- If the names are the same, compare the card id
            if left.cardId == right.cardId then
                --If the card ids are the same, compare the card instance ids
                return left.cardInstanceId < right.cardInstanceId
            else
                return left.cardId < right.cardId
            end
        else
            return left.name < right.name
        end
    else
        local leftIsNeutral = IsTributePatronNeutral(left.patronId)
        local rightIsNeutral = IsTributePatronNeutral(right.patronId)
        if leftIsNeutral == rightIsNeutral then
            -- Just group the patrons
            return left.patronId < right.patronId
        else
            -- Neutral cards first
            return leftIsNeutral
        end
    end
end

-- Tribute Pile Data --

ZO_TributePileData = ZO_InitializingObject:Subclass()

function ZO_TributePileData:Initialize(boardLocation, family)
    self.boardLocation = boardLocation
    self.family = family
    self.cardDataList = {}
    self:MarkDirty()
end

function ZO_TributePileData:MarkDirty()
    self.dirty = true
end

function ZO_TributePileData:GetBoardLocation()
    return self.boardLocation
end

function ZO_TributePileData:GetFamilyInfo()
    return self.family
end

function ZO_TributePileData:GetNumCards()
    return #self:GetCardList()
end

function ZO_TributePileData:GetName()
    return GetString("SI_TRIBUTEBOARDLOCATION", self.boardLocation)
end

function ZO_TributePileData:RefreshCardList()
    ZO_ClearNumericallyIndexedTable(self.cardDataList)

    local numCards = GetNumTributeCardsAtBoardLocation(self.boardLocation)
    for index = 1, numCards do
        local instanceId = GetTributeCardInstanceIdAtBoardLocation(self.boardLocation, index)
        local cardId, patronId = GetTributeCardInstanceDefIds(instanceId)
        local data = 
        {
            index = index,
            cardId = cardId,
            patronId = patronId,
            cardInstanceId = instanceId,
            name = GetTributeCardName(cardId),
        }
        table.insert(self.cardDataList, data)
    end

    if PILES_WITH_SECRET_ORDER[self.boardLocation] then
        table.sort(self.cardDataList, CompareSecretOrderedEntries)
    end

    self.dirty = false
end

function ZO_TributePileData:GetCardList(optionalSortFunction)
    if self.dirty then
        self:RefreshCardList()
    end

    if optionalSortFunction then
        local sortedCardDataList = ZO_ShallowTableCopy(self.cardDataList)
        table.sort(sortedCardDataList, optionalSortFunction)
        return sortedCardDataList
    else
        return self.cardDataList
    end
end

function ZO_TributePileData:GetNumCardsPerPatronId()
    local numPatronIdCards = {}
    local cardList = self:GetCardList()

    for _, cardData in ipairs(cardList) do
        local patronId = cardData.patronId
        local numCards = numPatronIdCards[patronId] or 0
        numPatronIdCards[patronId] = numCards + 1
    end

    return numPatronIdCards
end

function ZO_TributePileData:GetPatronCardCountList()
    local numPatronIdCards = self:GetNumCardsPerPatronId()
    local patronCardCountList = {}

    for patronId, numCards in pairs(numPatronIdCards) do
        local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(patronId)
        local patronCardCountData =
        {
            patronData = patronData,
            numCards = numCards,
        }
        table.insert(patronCardCountList, patronCardCountData)
    end

    table.sort(patronCardCountList, ZO_TributePileData.PatronCardCountListSortFunction)
    return patronCardCountList
end

function ZO_TributePileData.PatronCardCountListSortFunction(left, right)
    return left.patronData:GetName() < right.patronData:GetName()
end

function ZO_TributePileData:TryTriggerHandAndDocksTutorials()
    local cardList = self:GetCardList()
    local hasContractAgent = false
    local hasTaunt = false
    local hasContract = false
    local hasAgent = false
    local hasChoice = false
    local hasTrigger = false
    local hasConfine = false
    local hasDonate = false

    -- Loop through the cards in this pile and determine which tutorials we should try to trigger
    for _, cardData in ipairs(cardList) do
        local cardDefId = cardData.cardId

        local isContract = IsTributeCardContract(cardDefId)
        local isAgent = GetTributeCardType(cardDefId) == TRIBUTE_CARD_TYPE_AGENT

        -- If the card is a contract or an agent
        if isContract or isAgent then
            hasContract = hasContract or isContract
            hasAgent = hasAgent or isAgent
            -- If the card is a contract agent
            if isAgent and isContract then
                hasContractAgent = true
            end
        end

        -- If the card has taunt
        if DoesTributeCardTaunt(cardDefId) then
            hasTaunt = true
        end

        -- If the card is a choice card
        if DoesTributeCardChooseOneMechanic(cardDefId) then
            hasChoice = true
        end

        -- If the card has a trigger mechanic
        if DoesTributeCardHaveTriggerMechanic(cardDefId) then
            hasTrigger = true
        end

        --The confine mechanic is only on agents so we can skip the check if this card isn't an agent
        if isAgent and DoesTributeCardHaveMechanicType(cardDefId, TRIBUTE_MECHANIC_CONFINE_CARDS) then
            hasConfine = true
        end

        if DoesTributeCardHaveMechanicType(cardDefId, TRIBUTE_MECHANIC_DONATE_CARDS) then
            hasDonate = true
        end
    end

    -- Trigger the tutorials in the order of the priority we want them to show in
    if hasContractAgent then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_CONTRACT_AGENT_CARD_SEEN)
    end

    if hasTaunt then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_TAUNT_AGENT_CARD_SEEN)
    end

    if hasContract then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_CONTRACT_CARD_SEEN)
    end

    if hasAgent then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_AGENT_CARD_SEEN)
    end

    if hasChoice then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_CHOICE_CARD_SEEN)
    end

    if hasTrigger then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_TRIGGER_CARD_SEEN)
    end

    if hasConfine then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_CONFINE_CARD_SEEN)
    end

    if hasDonate then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_DONATE_CARD_SEEN)
    end
end

function ZO_TributePileData:TryTriggerDeckAndCooldownTutorials()
    local cardList = self:GetCardList()
    local hasCurse = false

    -- Loop through the cards in this pile and determine which tutorials we should try to trigger
    for _, cardData in ipairs(cardList) do
        local cardDefId = cardData.cardId

        -- If the card is a curse card
        if IsTributeCardCurse(cardDefId) then
            hasCurse = true
            -- This is only doable because hasCurse is the only thing we are checking for right now.
            -- We should remove this line if we add more tutorial triggers to this function in the future
            break
        end
    end

    -- Trigger the tutorials in the order of the priority we want them to show in
    if hasCurse then
        TUTORIAL_MANAGER:ShowTutorial(TUTORIAL_TRIGGER_TRIBUTE_CURSE_CARD_SEEN)
    end
end

-- Combine the contents of multiple piles into one object
ZO_TributeCompositePileData = ZO_TributePileData:Subclass()

function ZO_TributeCompositePileData:Initialize(boardLocations, family)
    ZO_TributePileData.Initialize(self, boardLocations[1], family)

    self.boardLocations = boardLocations
end

function ZO_TributeCompositePileData:GetBoardLocations()
    return self.boardLocations
end

function ZO_TributeCompositePileData:SetOverrideName(overrideName)
    self.overrideName = overrideName
end

function ZO_TributeCompositePileData:GetName()
    return self.overrideName or ZO_TributePileData.GetName(self)
end

do
    local function CompareEntries(left, right)
        if not (left.isSecretOrder and right.isSecretOrder) then
            -- One has a non-secret order
            if left.locationSortIndex == right.locationSortIndex then
                 -- If the board locations are the same, maintain the index sort
                 return left.index < right.index
            else
                -- If the locations are not the same, sort by locationSortIndex
                return left.locationSortIndex < right.locationSortIndex
            end
        end

        -- Both have secret order
        return CompareSecretOrderedEntries(left, right)
    end

    function ZO_TributeCompositePileData:RefreshCardList()
        ZO_ClearNumericallyIndexedTable(self.cardDataList)

        local anyLocationHasSecretOrder = false
        for locationSortIndex, boardLocation in ipairs(self.boardLocations) do
            local numCards = GetNumTributeCardsAtBoardLocation(boardLocation)
            local isSecretOrder = PILES_WITH_SECRET_ORDER[boardLocation]
            for index = 1, numCards do
                local instanceId = GetTributeCardInstanceIdAtBoardLocation(boardLocation, index)
                local cardId, patronId = GetTributeCardInstanceDefIds(instanceId)
                local data = 
                {
                    locationSortIndex = locationSortIndex,
                    index = index,
                    cardId = cardId,
                    patronId = patronId,
                    cardInstanceId = instanceId,
                    name = GetTributeCardName(cardId),
                    isSecretOrder = isSecretOrder,
                }
                table.insert(self.cardDataList, data)
            end
            if numCards > 0 and isSecretOrder then
                anyLocationHasSecretOrder = true
            end
        end

        if anyLocationHasSecretOrder then
            table.sort(self.cardDataList, CompareEntries)
        end

        self.dirty = false
    end
end
